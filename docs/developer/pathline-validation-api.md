---
title: PATHLINE R1a validation API
parent: Developer
nav_exclude: true
---

# PATHLINE R1a validation API

Status: R1a-V1 and R1a-V2 approved and implemented on 2026-10-10 with LuaDoc
and Lua 5.1.5 regressions: job lifecycle, connection evaluator, incremental
depth/corridor evaluation, limits and reports. The
[rolling pathfinding plan](rolling-pathfinding-plan.md) tracks the next approval
gates. The [pure geometry API](pathline-geometry-api.md) is also implemented.

## Scope and existing constraints

PATHLINE validates an immutable geometry snapshot through an explicit job.
The caller advances it; PATHLINE owns no timer, scheduler, FSM or movement
command. Geometry creation, report queries and cancellation perform no terrain
queries. No new class or module registration is needed.

Two evaluators have deliberately different work guarantees:

- A connection evaluator invokes a supplied rule once for each original
  connection. This supports `ASTAR:EvaluateConnection()`, including its cost.
  The callback is atomic and its internal work is opaque.
- The depth evaluator samples straight connections and parallel corridor profiles.
  It can yield between native profile queries, point checks and profile processing
  operations. It checks clearance only; it introduces no competing depth cost.

Today `ASTAR:EvaluateConnection()` and `PATHLINE.CheckDepth()` synchronously
evaluate complete connections. One such call can contain many terrain queries
and sorting/integration work. Wrapping it in a one-connection budget does not
make that internal work resumable. Existing methods and defaults remain intact.

Native `land.profile` itself cannot be interrupted. CPU limits are cooperative,
even for the depth evaluator. This API bounds admitted operations and retained
data; it cannot bound the duration or engine-side allocation of a native call.

## Public functions

All functions use static `PATHLINE.Function(...)` syntax.
All six functions and both evaluator kinds below are implemented.

| Function | Return and purpose |
| --- | --- |
| `CreateConnectionEvaluator(Callback, Options)` | Opaque evaluator descriptor; copies options and retains the callback |
| `CreateDepthEvaluator(Options)` | Opaque evaluator descriptor, or `nil, Reason, Detail` if the requested offset layout exceeds its cap or cannot be represented |
| `StartValidation(Geometry, Evaluator, Options)` | Opaque `Job, Report`; validates arguments and creates independent state, without evaluating a connection |
| `StepValidation(Job, Budget, CurrentContextId)` | Independent report after bounded work or an existing terminal result |
| `GetValidationReport(Job)` | Independent current report, without work or state changes |
| `CancelValidation(Job, Reason)` | Independent terminal report; default reason `cancelled` |

`Geometry` must be a snapshot from `CreateGeometry`. It is retained read-only,
not exported or recopied on every step. Descriptor options are copied on creation;
job options are copied on start. Neither descriptor nor job is caller-editable.
Two jobs may share geometry and an evaluator but never share mutable cursors,
profile buffers, counters or reports. Changing route points requires new geometry.

Unknown option fields, malformed handles, non-finite numbers, invalid enum values
and invalid callback results are programming errors. Reject them descriptively;
do not turn them into terrain failures. Omitted options use the specified defaults;
`false` is not an alias for omission. Count limits are finite non-negative integers
unless a structural limit is explicitly required to be positive.

No mutable continuation cursor is exported. A report's cursor is diagnostic;
continuation always uses the original job. Jobs cannot be serialized and restored.

### Connection evaluator contract

`CreateConnectionEvaluator(Callback, Options)` accepts optional `CostUnits`, a
non-empty string naming the callback's cost units. Omit it for validation only.

The callback receives independently owned Vec3 endpoints and a small context:

```lua
local result = Callback(Start, Goal, Context)
-- Context: ContextId, SegmentIndex, StartDistance, EndDistance, Length
-- Point-only geometry: PointIndex = 1; SegmentIndex = nil; Start == Goal by value.
-- Result: Status, Reason, Cost, Evidence
```

- `Status` must be `clear`, `blocked` or `unavailable`. A failed result requires
  a non-empty `Reason`; `clear` has no failure reason.
- With `CostUnits`, every clear connection must supply a finite non-negative
  `Cost`. Zero is valid. Without `CostUnits`, omit `Cost`. Failed results have no
  cost; an ASTAR adapter drops ASTAR's rejected-cost value `math.huge`.
- Optional `Evidence` uses only the bounded failure-evidence fields below.
  Reject unsupported fields instead of retaining arbitrary report graphs.
- Invoke the callback for each original segment, including duplicate endpoints.
  For single-point geometry invoke it once with identical endpoint values.
  Never silently split a custom rule or cost into shorter connections: callbacks
  need not be additive, and native profile inputs can affect their results.
- A callback may retain or mutate its argument copies without changing job state.
  Its external configuration must remain stable while the job runs.

A thin ASTAR adapter maps `ConnectionReport.Status` and `Reason`, the valid
connection cost and selected scalar depth evidence into this result. It does not
pass ASTAR nodes or the full ASTAR report to the job. ASTAR's in-call configuration
check is useful but does not freeze configuration between job steps. The owner
must invalidate the context when evaluator rules, costs or captured settings change.

### Depth evaluator options (R1a-V2)

Distances, widths and depths use meters. Values are finite; required spacings and
`MinDepth` are strictly positive. No vessel-specific defaults are implied.

| Option | Contract / initial default |
| --- | --- |
| `MinDepth` | Required hard minimum; depth equal to the minimum passes |
| `LongitudinalSpacing` | Required maximum gap between generated direct samples |
| `CorridorWidth` | Full width, default `0`; must be non-negative |
| `LateralSpacing` | Required when width is positive; maximum gap between parallel profiles. If supplied with zero width, it must still be positive but creates no extra profiles. |
| `MaxSectionLength` | Maximum length of one native profile query, default `1000` |
| `MaxOffsets` | Positive count cap including the center profile, default `65` |
| `MaxProfilePoints` | Positive cap on native records in one returned profile, default `4096` |
| `MaxDirectPoints` | Positive cap on generated points for one section/profile, default `4097` |

These defaults are resource policies, not measured performance guarantees.
There is no `Weight`, `PreferredDepth`, implicit ship draft or permissive missing-data
switch. Soft depth preferences remain ASTAR's responsibility. The T2 settings are
test inputs, not defaults for this API.

With half-width `H > 0`, use `m = ceil(H / LateralSpacing)` and spacing `H / m`.
The deterministic offset order is `0, +H/m, -H/m, ..., +H, -H`; positive means
right of the directed connection. Zero width uses only offset zero.
For width 50 and lateral spacing 10, this produces seven profiles with a gap of
about 8.33 m. Check `1 + 2*m` against `MaxOffsets` before allocating the layout.
Factory failure is `offset_limit` or `numeric_range`, with required count/limit
where representable. No offset array is allocated: each offset is calculated as
its profile is prepared. Never coarsen the caller's requested spacing to fit a cap.
Unrepresentable derived counts or collapsed section/direct/offset coordinates
end a job with `limited`, `numeric_range`; repeated coincident lines cannot certify
a corridor whose lateral displacement disappeared through floating-point rounding.

## Job state, continuation and ownership

`StartValidation` initially returns `running`, with zero counters and no completed
segments. Even a point-only geometry needs evaluation; it is not automatically clear.

`StepValidation` consumes work until completion, failure, cancellation or a budget
boundary. A slice limit leaves the job `running`; the next step resumes exactly
where it stopped. Total or structural limits produce terminal `limited`. A new
job is required for a deliberate retry; raising a slice budget cannot revive one.

In V1, a callback is one work unit. A successful result is copied and retained in
phase `commit`; committing its cost/prefix and advancing the cursor is a separate
work unit. A blocked/unavailable callback terminates in the callback unit. Thus a
clear route with N original segments takes 2*N units; a single-point route takes
two. Cancellation between these phases discards the uncommitted result. A pending
commit may proceed with `MaxEvaluatorCalls = 0`, without repeating the callback.

| Status | Meaning |
| --- | --- |
| `running` | Pending or yielded work; not a usable validation result |
| `clear` | All required checks completed successfully under the reported coverage |
| `blocked` | A measured violation or a connection rule rejects the route |
| `unavailable` | Required evidence could not be obtained or interpreted |
| `limited` | A resource cap prevents completing the check |
| `cancelled` | Explicit cancellation or context mismatch |
| `error` | A programming/native exception ended evaluation; the exception is also propagated |

Only `running` is non-terminal. Calling step or cancel on a terminal job returns
its unchanged result, without callbacks, retries or counter changes. The first
terminal result is retained. Cancellation does not rewrite an already clear
result; the consumer must still check its context before using it.

`CancelValidation` may be called from an evaluator callback. Check cancellation
after every atomic operation and discard that operation's uncommitted result if
cancelled. Native work already in progress cannot be stopped; the consumed unit
and its measured CPU are accounted for when it returns. Recursive stepping of
the same job is an error before recursive work begins.

Terminal transitions release active native arrays, scratch buffers and job-owned
geometry/evaluator references. Keep only a bounded final report, not all per-sample
or per-segment reports. A caller-retained descriptor can still retain its callback.
There are no global job registries or automatic retries.

Argument errors before stepping leave the job unchanged. An exception during
evaluation marks a still-running job `error`, clears active resources, then rethrows
the original error. A narrow protected boundary may perform this cleanup; it must
not conceal the error as `blocked`, `unavailable` or a successful default. If a
callback cancels and then raises, retain cancellation and still propagate the error.

### Context and stale results

Start options accept optional `ContextId`, a non-empty string or finite integer.
If supplied, every step must pass the matching `CurrentContextId`; absence or a
mismatch cancels with `context_changed` before admitting work. Without a context
at start, omit the third argument. This supports standalone deterministic use.

NAVYGROUP must use a fresh context for each movement command and relevant route,
pose-preparation or rule change. Cancel obsolete jobs and compare the context again
immediately before publishing/using a result. PATHLINE cannot detect mutated closure
state or external world changes. A context argument is checked at step entry, not
continuously read from the owner during an opaque callback.

A manual stop, command replacement, death/respawn or owner-defined deadline calls
cancel explicitly. Deadlines use their declared wall/mission clock in the owner;
they are not PATHLINE CPU limits. In the agreed navigation policy, a missing
continuation causes a stop and requires a **new movement command**. Completion
of an old or late job must never resume the ship.

## Work budgets and timing

`Budget` controls one step. Start options set immutable total caps with the same
field names. Only fields applicable to the selected evaluator are accepted.

| Field | Per-step default | Job-total default | Applies to |
| --- | --- | --- | --- |
| `MaxWorkUnits` | 64 | 200000 | Both |
| `MaxCPUSeconds` | Omitted | Omitted | Both; optional finite non-negative seconds |
| `MaxEvaluatorCalls` | 1 | 4096 | Connection evaluator only |
| `MaxPointChecks` | 8 | 50000 | Depth evaluator only |
| `MaxProfileQueries` | 1 | 4096 | Depth evaluator only |

One admitted work unit is one callback, one native profile query, one point check,
one profile-record inspection/copy/merge operation, or one bounded cursor/section
finalization. A point check reuses `VECTOR._CheckDepthPoint` and invokes at most
two native queries: surface type and, where appropriate, surface/seabed heights.
`PointChecks` is not a claim to count individual native calls.

Every operation consumes a work unit and its applicable specific counter. Reserve
all applicable counts before execution; a denied operation runs zero times. Internal
loops, sorting and duplicate reduction must also yield, rather than hiding unlimited
processing behind one profile call. Reusing the synchronous `CheckDepth` or calling
`table.sort` on the entire profile would violate this contract.

The next operation determines whether a specific budget is exhausted: no profile
budget is needed merely to process an already returned profile. `MaxWorkUnits = 0`
always performs no evaluation work. A zero specific slice limit only prohibits that
operation kind. A zero total limit permits other work until that kind is required.

At a boundary, check cancellation/context first, then total availability, then slice
availability. An exhausted total produces `limited`; an exhausted slice yields
`running` and `LastSlice.YieldReason`. If the last admitted unit completes evaluation,
retain its clear/failure result even if its non-preemptible duration crosses a CPU
limit. Otherwise check CPU again before admitting the next unit. Record any CPU
overrun; never claim the requested seconds were a hard execution deadline.

CPU measurement uses `os.clock` when available, includes active step/evaluator work,
and excludes idle time between steps. Do not substitute simulation or wall time.
If no CPU cap was requested, a missing clock leaves `CPUSeconds = nil` and count
budgets still work. If either applicable CPU cap is requested without a usable
clock, finish `limited` with `cpu_clock_unavailable` before evaluation work.

In V1, CPU fields are absent before the first step. Losing a usable observation
makes cumulative CPU unavailable for the rest of that job; later measurable slices
can still report their own CPU. Invalid/non-finite/backward readings are unavailable;
clock exceptions propagate as errors. Final accounting also records overruns for
failed callbacks. `CPUOverrunSeconds` is the largest excess over the requested
slice and total caps, zero if neither was exceeded, absent without a usable
measurement/cap. CPU accounting is not a frame-time guarantee.

Yield reasons are `slice_work_limit`, `slice_cpu_limit`,
`slice_evaluator_limit`, `slice_point_limit`, and `slice_profile_query_limit`.
Total failure reasons use `work_limit`, `cpu_limit`, `evaluator_limit`,
`point_limit` and `profile_query_limit`. Structural failures use `profile_point_limit`
or `direct_point_limit`. Numeric overflow is `numeric_range`; no NaN success.

The connection evaluator accepts neither native point nor profile budgets. Its
callback may invoke arbitrarily many native operations. Reports leave those counts
`nil`, not zero. A CPU cap can observe an overrun but cannot interrupt that callback.
If full ASTAR connection/cost calls prove too expensive, a separately designed
resumable ASTAR evaluator is needed; splitting or undercounting calls is not a fix.

## Incremental depth algorithm (R1a-V2)

For each positive-length original segment, divide its horizontal length `L` into
`ceil(L / MaxSectionLength)` equal sections, keeping the original endpoints exact.
Visit sections in route order and profiles in the offset order above. A query uses
canonical lexicographic x/z endpoint order, while route distances and lateral offsets
in results always refer to the original travel direction.

Within each section/profile:

1. Compute the direct layout before native work. Use
   `max(2, ceil(sectionLength / LongitudinalSpacing))` intervals, including both
   endpoints and at least one interior point. Enforce `MaxDirectPoints` before
   generation. Generate individual records as budget permits.
2. Invoke `land.profile` once. A nil/non-table response is `unavailable`; a valid
   empty or one-point array uses the explicit direct-sampling fallback. Record
   this in `FallbackProfiles`. Direct samples are required even for longer native
   profiles; native point density alone does not meet the requested spacing.
3. Inspect and copy native records incrementally. Validate a dense 1-based sequence
   of finite x/y/z records, without trusting `#table` for sparse data. Incremental
   raw traversal can track entry count and greatest valid index; require equality
   before accepting the sequence. Invalid records/keys/gaps are `invalid_profile`.
   Stop on the record cap without retaining an unbounded copy.
4. Project support points onto the query line, clamp their along-line position to
   its ends, and order them in the original route direction. Query native support
   points at their supplied x/z coordinates, not moved projected coordinates.
   An incremental stable merge, bounded by work units, orders native and generated
   records; preserve native index/direct sample index as deterministic tie keys.
5. Check generated points with `VECTOR._CheckDepthPoint(..., false)` and native
   points with `VECTOR._CheckDepthPoint(..., true)`. The latter conservatively
   combines direct depth and native seabed evidence. Route-position y is never
   interpreted as water depth.
6. Complete each equal-distance group before classifying it: unavailable evidence
   takes priority within that group, followed by non-water and insufficient depth.
   Retain the shallowest measured depth and deterministic first tied evidence.
   Stop on the first failing group in processing order; unvisited profiles are not
   claimed checked. This is not necessarily the earliest obstruction in space.
7. Release each finished profile buffer. Commit a section to the checked prefix
   only after every required offset in it passes. Then advance to the next section.

The diagnostic phase sequence is `segment`, `section`, `profile_setup`, `query`,
`collect`, `generate`, `sort`, `check`/`group`, `next_profile`, `commit_section`.
An isolated position uses `point_setup` and `point`; all-duplicate routes then
account for their original zero-length segments individually. Each phase advance
is bounded and charged, including merge-range setup, single-record merge output
and merge-pass advancement. Specific point/profile budgets apply only to their
native operations. No complete-array sort or unbudgeted sampling loop is used.

The native table must remain stable during incremental collection; after collection
its records have been copied and the native table is released. Endpoint arguments
passed to the native query are copies. Checked native records retain their original
x/z, with projected/clamped distances used only for ordering and route evidence.

Every traversal, copy, merge, group reduction and state advance must have bounded
progress per admitted work unit. Scratch storage is bounded by the offset cap and
one profile's native/direct records plus merge buffers; there is no route-length
sample history. The native response exists before its cap can be inspected:
`MaxProfilePoints` limits accepted/retained processing, not DCS allocation.

For an isolated point or wholly zero-length route, zero width checks that position
once, without a profile or invented heading. Positive width returns `unavailable`
with `corridor_direction_unavailable`; one point cannot orient a corridor. Duplicate
zero-length segments within a route containing positive legs add no separate depth
strip; their common positions are checked through incident endpoints. Retain original
segment indices and count skipped duplicates in `SkippedDegenerateSegments`.

Sectioning and added profiles can change native query results compared with the
existing three-profile checks. Record the layout in coverage; do not promise identical
ASTAR acceptance or cost. At corners the union of straight strips is not a swept
turning hull. This operation checks discrete samples with declared spacing, not every
point of a continuous area, a ship's stopping region or DCS controller behavior.

## Missing depth and result evidence

Use the shared point predicate's meanings:

| Observation | Result |
| --- | --- |
| Valid water/shallow-water surface and finite depth at least `MinDepth` | Sample clear |
| Valid surface identified as land/non-water | `blocked`, `non_water` |
| Finite non-negative water depth below the minimum, including zero | `blocked`, `insufficient_depth` |
| Native profile above water surface produces a negative effective depth | `blocked`, `insufficient_depth`; preserve the signed evidence |
| Missing/invalid surface type | `unavailable`, `invalid_surface_type` |
| Missing, non-finite or inconsistent height/depth | `unavailable`, `invalid_depth` |
| Missing native profile / malformed returned profile | `unavailable`, `profile_unavailable` / `invalid_profile` |
| Work or data-size cap | `limited`; no terrain conclusion |
| Native/programming exception | Propagated error; no fabricated depth |

Only the explicitly documented short-array fallback is allowed. Unknown depth is
never replaced by zero, infinity, a remembered neighbor or a previous mission's
value. There is no automatic retry on missing data. A caller may later start a new
job under an explicit bounded retry policy, with the previous failure kept separately.

Reports contain bounded scalar fields and independent small tables:

| Field | Meaning |
| --- | --- |
| `Status`, `Reason`, `ContextId`, `EvaluatorKind` | State, failure reason when terminal failure, original context, `connection` or `depth` |
| `CompletedSegments` | Number of original segments fully processed; a point-only route remains zero even after passing |
| `CheckedPrefixDistance` | Route distance through consecutively completed connections, or fully checked depth sections; starts at zero |
| `CompletedCost`, `TotalCost`, `CostUnits` | Cost of completed original connections; total only when clear. All absent for depth/validation-only evaluators. |
| `Failure` | Optional original `SegmentIndex` or `PointIndex`, `SectionIndex`, `ProfileOffset`, `RouteDistance`, `Position`, `Depth`, `SurfaceType`, `Source`, `Cause`, `Limit`, `Required` where known |
| `Cursor` | Diagnostic `Phase`, `SegmentIndex`/`PointIndex`, `SectionIndex`, `OffsetIndex`, `SampleIndex`; absent after termination |
| `Counters` | Admitted `WorkUnits`, applicable `EvaluatorCalls`, `PointChecks`, `ProfileQueries`, `FallbackProfiles`, `SkippedDegenerateSegments`, and active `CPUSeconds` when measurable |
| `LastSlice` | Work/native/callback counter deltas and CPU seconds for the last actual step; optional yield reason and non-negative `CPUOverrunSeconds` |
| `Coverage` | Evaluator kind and copied depth options/caps plus `OffsetCount` and `ActualLateralSpacing` (zero at width zero), or callback cost units; no implied hull or continuous-area certification |

Failure position is a copied x/z pair; optional `ProfileY` is separately identified
as native profile height. Do not invent an altitude to return a Vec3. Omit unknown
values. Effective depth evidence must be finite, but may be negative for a native
profile above the water surface; negative direct depth data remains unavailable.
Callback evidence accepts the location/depth/source/cause fields only;
the job supplies original indices and its own limit details. Reasons/source/cause
and cost-unit strings are limited to 128 bytes; reject oversized callback metadata.

`CheckedPrefixDistance` is neither an interpolated first-obstacle distance nor a
guaranteed stopping distance. One finished center profile cannot advance it over
unchecked side profiles. If a later section becomes unavailable, keep earlier checked
sections in the report but classify the whole job `unavailable`. No controller may
treat that partial report as a clear route. The existing `CheckDepth.ClearDistance`
contract is unchanged.

`CompletedCost` never includes half an opaque callback or an unverified segment.
Report creation copies only the bounded summary, not raw samples or route arrays.
Mutating an old report cannot alter the job or future reports. CPU/counter bookkeeping
after cancellation inside a callback is finalized when that admitted operation returns.

## Use by later naval preparation

R1b first evaluates complete prepared connections under the intended ASTAR rules
and cost configuration, then runs the depth evaluator at its explicit sampling
resolution. Both jobs must match the current preparation context. A route becomes
eligible only if every required stage is clear. Rejection at either stage rejects
the candidate; sampled clearance does not invent a replacement cost.

Keep ASTAR's prepared-route repricing in the existing plan. Do not add depth weight
again here. NAVYGROUP separately owns actual pose/progress, turning and stopping
envelopes, movement authority, deadlines and the single scheduling pump. GRID remains
a search representation; this validator works on route coordinates independently
of grid shape or cell spacing. No production ASTAR, GRID, VECTOR, NAVYGROUP or loader
change is required for the first implementation steps. Reuse VECTOR's point predicate.

## Deterministic acceptance cases

Run production methods with controlled dependencies in separate Lua 5.1 processes.
The connection/job cases are covered by the V1 suite. Native incremental sampling,
merge/group continuation and dense-corridor cases are covered by the V2 suite.

| Case | Required result |
| --- | --- |
| Create/query/cancel before first step | No terrain or evaluator calls |
| One large step versus many small steps, stable inputs | Same final state, evidence, prefix and cost; no repeated native query at resume boundaries |
| Yield after query, during copy/merge, within tied group and before section commit | Correct exact continuation; no premature prefix advance |
| Zero budgets and exact last-unit completion | No denied operation runs; final admitted completion is retained |
| Independent work/point/profile/callback caps | Every operation reserves all relevant counters; inapplicable budget fields rejected |
| Native/callback CPU overrun and idle time between steps | Actual overrun reported; no preemption claim or idle/simulation time charged |
| Missing CPU clock | Count-only work succeeds; requested CPU cap stops before evaluation |
| Total cap versus slice cap | Terminal limited versus resumable running; no resurrection by larger slice budget |
| Cancel before work, in callback, while profile is partially processed | Resources released; uncommitted result discarded; admitted work still counted |
| Repeated cancel/step after every terminal state | Stable report, no work, no new timers or callbacks |
| Missing/mismatched context and late old result | Cancel before work; consumer rejects stale completed result |
| Exception, malformed callback result, recursive step | Error propagated, no fabricated route, no repeated failing evaluation |
| Cost zero, non-additive callback, duplicate connections | Zero preserved; original whole connections evaluated; only completed costs included |
| Water depth equal/below minimum, non-water, invalid depth/type | Clear, blocked and unavailable remain distinct |
| Empty/one-point native array versus nil/malformed/sparse array | Explicit direct fallback only for valid short arrays |
| Excess native records, direct layout or offsets | Explicit limit; no silent truncation or coarser sampling |
| Center/edges clear but interior lateral profile blocked | Interior obstacle detected at its sampled coordinates |
| Reverse endpoints, rotated legs, exact section seams | Canonical queries and correct original-direction indices/distances/offsets |
| Coincident native/direct samples with conflicting evidence | Group completed; unknown/non-water/shallowest precedence deterministic |
| Later missing data or blocked side profile | Earlier committed prefix retained; current section never partially committed |
| Point-only, all duplicates, duplicates between positive legs | Defined point/strip behavior, no fabricated heading or skipped endpoint checks |
| Mutated input options/endpoint arguments/returned reports; concurrent jobs | Independent job state and immutable configuration |
| Terminal cleanup and long route | No retained growing sample history or cancelled-job terrain arrays |

## Implementation sequence and approval gates

1. **R1a-V1: job and connection evaluator (completed).** Implement the connection factory,
   start/step/report/cancel functions, state and report contracts, context handling,
   work/callback/CPU budgets and deterministic regressions with LuaDoc. An ASTAR
   adapter in tests verifies the integration without changing production ASTAR.
2. **R1a-V2: incremental depth evaluator (completed).** Factory, bounded sampling
   and profile processing, specific budgets/caps and missing-data evidence are
   implemented with depth/corridor regressions; existing synchronous APIs are unchanged.
3. **P0/R1b: fixed-pose preparation.** Integrate separately after shared test input
   and report contracts. R2/R3 simulator gates still precede working LOCAL navigation.

For each approved implementation substep, compile changed Lua under Lua 5.1.5,
run focused PATHLINE/profile/depth tests and downstream ASTAR/NAVYGROUP suites where
affected, inspect the final diff and run `git diff --check`. Stubbed tests do not
validate DCS native profile behavior, frame timing or ship motion. Record those
separately during later explicitly announced simulator tests.

### V1 implementation validation, 2026-10-10

- The first 30 new cases failed against the absent API before implementation.
  Six review cases were added; three exposed CPU-error reporting and negative
  ASTAR profile-evidence defects in the first implementation, then passed after
  the targeted fixes.
- Lua 5.1.5 compiles production PATHLINE and `tests/pathline-validation.lua`.
- Separate processes pass validation jobs (36), existing PATHLINE (47), profile
  (15), depth (33), ASTAR (295) and NAVYGROUP (25): 451 cases total.
- The new suite checks actual ASTAR connection/depth-cost behavior with controlled
  terrain, including unavailable data, weighted corridor costs and signed profile
  evidence. It also verifies cancelled/completed-job cleanup and collection of
  abandoned callback/handle cycles under Lua 5.1.
- No production ASTAR, GRID, VECTOR, NAVYGROUP or loader changes were needed.
  The code/diff and documentation were reviewed; `git diff --check` passes.
  No DCS test or log observation occurred.

Run the focused suite from the repository root:

```text
lua tests/pathline-validation.lua
```

### V2 implementation validation, 2026-10-10

- The initial 29 regression cases failed at the absent depth factory before
  implementation. Eight review cases were added. One exposed rounded-away lateral
  offsets in the first implementation; it passes after explicit numeric rejection.
- Lua 5.1.5 compiles production PATHLINE and the new depth-validation suite.
- Separate processes pass depth validation (37), connection validation (36),
  PATHLINE (47), profile (15), depth (33), ASTAR (295) and NAVYGROUP (25):
  **488 cases total**.
- Coverage includes independent count limits, resumable raw collection and stable
  merging, tied-sample priority, missing/invalid terrain data, intermediate corridor
  lanes, original-direction evidence, exact seams, duplicate/point-only geometry,
  native cancellation/exceptions, CPU overruns, buffer release and a 1000-point
  native profile processed in small slices without requerying.
- Only production PATHLINE changed. Existing synchronous depth methods and the
  ASTAR adapter retain their contracts. No DCS test, log observation, navigation
  change or LOCAL reactivation occurred. Simulator behavior and timing remain
  unvalidated. Final source/documentation review and `git diff --check` pass.

Run the additional focused suite from the repository root:

```text
lua tests/pathline-depth-validation.lua
```

The [P0 test and replay contract](local-pathfinding-test-contract.md) now defines
shared inputs, source identity and stage reports for virtual search and fixed-pose
preparation. Its design is documented; the next proposed subtask is **P0-I1**:
shared standalone fixtures and comparison driver with Lua 5.1 regressions.
Wait for user approval/comments before implementation.
