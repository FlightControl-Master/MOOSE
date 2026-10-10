---
title: Rolling pathfinding development plan
parent: Developer
nav_exclude: true
---

# Rolling pathfinding development plan

## Current decision: remove the naval LOCAL integration (2026-10-09)

The developer approved a clean removal of the experimental local pathfinding
implementation from NAVYGROUP, followed by a staged rebuild. The shared
ASTAR, GRID and PATHLINE implementation remains in place. The existing
full-waypoint naval search remains available; its redesign is a separate task.

The preceding implementation and regression cases are recoverable at commit
`8ba49eb1b`. Detailed design decisions and test history are retained in the
[archived development history](rolling-pathfinding-history.md). Historical
methods and milestone completion statements there are not current API promises.

### Evidence and reason for the reset

Standalone ASTAR tests demonstrated useful geometric paths and virtual point
following. The recorded M2.4 baseline passed T1, T2 at depth weight 1 and all
eight T3 checks; the weight-10 baseline reached its request budget. Later
iterations and observations are described in the archived history. These tests
do not establish physical ship movement or controller safety.

The naval integration added candidate steering, circular turn allowances,
minimum leg lengths, route reserves, speculative continuations, moving-start
reattachment and release back to ordinary routing. These interacting policies
made it difficult to explain why an available ASTAR path did not become a
submitted, usable ship route.

The final recorded run, `navy-case55-20261009133751193`, illustrates the gap.
A second local activation
began with about 2098 m clear ahead at 26 knots. Eight requests returned
`path_found`; a ninth was in progress when route preparation exhausted the
available approach reserve after 88 simulation seconds. The worker recorded
4.835 CPU seconds. NAVYGROUP explicitly commanded `FullStop` with
`local_planning_reserve`; a collision or grounding was not established by that
log. The detailed candidate rejection reasons were not available.

Virtual progress waits for planning and follows checked points exactly. A
moving ship consumes the approach while planning and rounds waypoint turns.
The old virtual and naval tests also used different search settings. These
differences must be tested separately during the rebuild. Increasing depth
weights, search horizons or arbitrary limits is not a substitute for identifying
the responsible decision.

### Removal contract

- Retain `NAVYGROUP.PathfindingMode.LOCAL` as a recognized constant.
- `SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL)` raises
  `NAVYGROUP: LOCAL pathfinding mode has been removed; local navigation is unavailable pending a rebuild`.
  Reject the request before mutating the mode, route, movement state or drawings.
- `WAYPOINT` remains the default. There is no silent conversion of a LOCAL
  request to the global planner.
- Remove the local session, coroutine jobs, work-budget API, steering and
  reserve policies, local progress/completion handling, continuation logic,
  speculative search ownership and LOCAL drawing/diagnostic hooks.
- Remove `SetPathfindingWorkBudget()` and `LastLocalPlanningReport`; do not keep
  no-op methods, compatibility adapters or dormant local implementations.
- Retain shared waypoint targeting, depth/corridor checks, hull/heading checks,
  global search diagnostics and the global grid display.
- Retain the single navigation timer for two-second hull/heading checks and
  ten-second waypoint checks. Remove the 0.1-second planning cadence.
- Preserve shared Core sources and their standalone regression suites.

A script that selects LOCAL now intentionally fails at configuration. Choosing
WAYPOINT is an explicit different behavior, not an equivalent migration.
Existing LOCAL mission scripts must wait for the rebuild or be deliberately
changed by their author. New includes require a fresh mission to take effect.

### Removal work and validation

- [x] Save the previous implementation and identify its Git baseline.
- [x] Remove NAVYGROUP local implementation and lifecycle hooks.
- [x] Replace active LOCAL documentation with its removal contract.
- [x] Replace the retired naval LOCAL suite with `tests/navy-pathfinding.lua`,
  preserving global routing, common safety and diagnostic regression coverage.
- [x] Run Lua 5.1 compilation and the affected naval/waypoint regressions.
- [x] Confirm shared ASTAR/GRID behavior, review the diff and check whitespace.

The LOCAL rejection regression failed against the preceding implementation:
the old setter accepted LOCAL instead of raising an error.

Validation on 2026-10-09: all changed Lua files compile with Lua 5.1.5.
The independent suites pass 428 cases: NAVYGROUP 25, WAYPOINTS 16,
ASTAR 280 and GRID 107. The global planner and hull-check implementations
are unchanged; no removed naval methods remain referenced by source/tests.
The final diff and whitespace check pass. Simulator validation of the
remaining WAYPOINT mode after removal has not been performed.

## Rebuild concept and implementation proposal (2026-10-09)

The removal and the R1 -> R2 -> R3 validation order were agreed. The detailed
architecture below is a proposal for the next implementation, not a claim that
it already exists or that simulator behavior is established. This planning step
does not change production code. LOCAL continues to raise the removal error.

**Confirmed operating policy:** if the next checked section is not ready in
time, stop and wait for a new movement command. Do not resume automatically.
The user explicitly chose this policy on 2026-10-09. It supersedes the earlier
open question about a planning wait with automatic continuation.

### Design goals and boundaries

1. Reuse the demonstrated standalone local search with identical, explicit
   inputs before adding ship execution.
2. Separate geometric search, preparation of a ship route, submission, and
   observation. A success at one boundary is not success at the next.
3. Keep hard depth/clearance constraints separate from depth preference,
   performance limits and movement authority.
4. Explain each rejected candidate using measured geometry and a concrete
   reason. Avoid a final `no_steering_path` without its underlying evidence.
5. Bound work and retained state. No recursive speculative continuation tree,
   automatic global fallback, blind reverse recovery or endless retries.
6. Preserve ordinary mission destinations, their actions, FSM guards and user
   callbacks. Internal local anchors are not original mission waypoints.

The first executable scope is one vessel per NAVYGROUP, static terrain and one
original destination at a time. Multiple original waypoints, explicit retargeting
and their tasks are integration gates. Formation maneuvering and dynamic traffic
avoidance are later features, not implied by a clear leader path. Initially,
unsupported multi-vessel LOCAL operation must fail clearly rather than silently
apply single-vessel clearance to a formation. This restriction is a proposal.

## What the existing classes already provide

This assessment comes from the current class sources and regression fixtures.
Existing tests establish their stated scope, not physical ship safety.

| Component | Verified current capability | Rebuild decision |
| --- | --- | --- |
| ASTAR | `SetLocalWindow`, `StartLocalSearch`, `StepSearch`, `CancelSearch`; up to eight ranked frontier candidates, exact-goal preference, copied positions and structured results | Reuse initially; no replacement search algorithm. |
| ASTAR | Stable lattice learning, bounded memory, explicit cache invalidation and separately observed movement | Reuse; do not create a second NAVYGROUP history/learning system. |
| ASTAR | `EvaluateConnection` freshly checks arbitrary positions and prices them with the configured rule/cost without changing the pending search | Use for every changed connection and prepared-route cost. |
| GRID | Bounded sparse hex/rectangle windows, stable indices, resolution/cell limits, reuse and separately owned batched drawings | No mandatory functional extension identified. |
| PATHLINE | `CheckDepth` supplies blocked/unavailable evidence and an estimated clear prefix; existing length, point and drawing operations | Reuse depth checks; add small geometry and route-validation helpers described below. |
| VECTOR | Horizontal coordinates/headings and shared point-depth validation | Reuse; no required new geometry abstraction. |
| NAVYGROUP | Destination ownership, movement guards, diagnostics, global search, live hull/heading checks and normal route submission | Add a small local orchestration layer around these boundaries. Reassess the forward safety projection before declaring LOCAL operational. |
| OPSGROUP | Original waypoint/task progression and existing FSM authority | Reuse; make a narrowly scoped arrival hook only if needed to defer an early native callback. |
| TIMER | One native callback per TIMER and generation-aware rescheduling | Reuse for one owned planning pump; no new scheduler infrastructure. |

The relevant implementations are `Core/Astar.lua`, `Core/Grid.lua`,
`Core/Pathline.lua`, `Core/Vector.lua`, `Ops/NavyGroup.lua`,
`Ops/OpsGroup.lua` and `Core/Timer.lua` under `Moose Development/Moose/`.

### ASTAR: retain the algorithm; identify limits explicitly

A current LOCAL request explores costs to the window boundary. It reports one
candidate per geometric sector, not every possible path. Learning is updated
on completed partial exploration; it is not a statement that the ship followed
a candidate. Feed only observed positions to `UpdateLocalProgress`. Future
planning anchors and successful route submissions are not movement.

NAVYGROUP should consume `Candidates[].Positions` and retain copied reports,
not mutable nodes or old GRID graphs. Reacquire `GetGrid()` after each request.
Use one persistent local search per destination/session so compatible learning
survives. Keep any global search instance separate.

No new ASTAR public API is required for R1. NAVYGROUP currently has no LOCAL
consumer; its replacement remains a separate implementation step.

ASTAR review follow-up approved on 2026-10-10:

- [x] Reject malformed node positions before conversion or terrain sampling.
- [x] Apply coincident-endpoint validity consistently in all search modes.
- [x] Count immediate grid neighbours without building full marker adjacency.
- [x] Resolve equal fixed-search scores deterministically.
- [x] Reconstruct LAZY paths cooperatively, including cancellation and limits.
- [x] Clean up affected control flow/documentation and run Lua 5.1 regressions.

Each behavioral regression must expose its original failure. Preserve public
signatures and node ownership; keep search geometry, costs and LOCAL learning
unchanged. Re-run ASTAR, GRID and NAVYGROUP suites after the fixes. This work
does not implement the replacement naval controller or validate DCS behavior.

Completed on 2026-10-10. Initial regressions exposed all five findings: 12
failures with the unchanged ASTAR implementation. The final suite adds 15
cases, including preservation of LOCAL behavior and output-copy cancellation.
Lua 5.1.5 compilation and ASTAR (295), GRID (109), NAVYGROUP (25) regressions
pass. The former first-label graph build required 77,564 index lookups for
4,900 rectangular cells; the regression now permits at most 24 per first
label, for both grid types and with or without a CPU clock. Manual attachment
counts remain proportional to the number of manual nodes, as documented.

LAZY reconstruction and output copying share the expansion budget and check
CPU time between work items. Coincident plans validate the neighbour rule in
every mode, while retaining zero travel cost and existing endpoint exclusions.
Fixed-score ties now select the lowest node ID. These changes do not establish
ship safety; DCS terrain/controller validation remains outstanding. The next
proposed subtask is a PATHLINE review against AGENTS.md before R1a changes,
subject to the user's approval.

A geometric search does not include arrival heading in its state. If R1/R2
prove that the sole retained path to a cell consistently has an unusable turn
while a different arrival direction works, downstream smoothing cannot solve
that generally. Then propose a separate, bounded extension with search state
(cell, incoming heading), suitable transition checks and deterministic tests.
Do not bolt heading-dependent rejection onto a position-only node and assume
it preserves valid alternatives. This extension is conditional, not part of
the initial rebuild.

Likewise, increase alternatives per sector only after a recorded case shows
that the retained sector winner masks a usable alternative. Keep the current
cost/learning logic unchanged until a standalone regression identifies a defect.

### GRID: use existing capabilities

Start with explicit spacing/window/cell limits, not hidden speed-dependent
changes. The current sparse window and drawing lifecycle suffice. Search
resolution and display density must remain independent.

A cell limit is a resource outcome; it proves neither terrain blockage nor
global unreachability. Any later window widening/refinement must be a bounded,
reported policy, preserve compatible sampling where supported, and respect the
same total cell/work budget. No silent increase to make a test pass.

Do not move ship dimensions, turn models, speed, route ownership or stopping
decisions into GRID. Center-depth coloring remains a visual aid only.

GRID review follow-up completed on 2026-10-10: raw position components are
validated before VECTOR conversion can substitute zero defaults. Single-cell
neighbour counts now inspect only adjacent indices and rectangular flanks;
marking no longer builds a complete adjacency graph for the first label.
Resolution and drawing-default expressions were simplified. The user confirmed
that GRID and the associated ASTAR drawing APIs are still in development, so
their compatibility aliases and positional drawing overload were removed.
Repository callers, tests and API documentation use the unified methods; the
GRID class documentation contains the migration mapping for mission scripts.

Both new regression cases failed against the previous implementation. Lua 5.1.5
syntax checks and the updated GRID (109), ASTAR (280), and NAVYGROUP pathfinding
(25) suites pass. These are controlled fixtures; no DCS validation was performed
for this cleanup. The LOCAL reconstruction remains a separate implementation step.

### PATHLINE: small, reusable additions are justified

PATHLINE review completed on 2026-10-10 against AGENTS.md. No production code
or regression-suite changes were made during this review. Lua 5.1.5 syntax
compilation and the existing PATHLINE (11), profile (15), and depth (27)
regressions pass. Additional disposable probes exercised production methods
with controlled terrain/drawing dependencies and confirmed these gaps:

| Finding | Evidence and consequence | Proposed correction before R1a |
| --- | --- | --- |
| P1: Equal profile distances can overstate `ClearDistance` | At 500 m, two native samples with depths 40 m and 10 m produce 333.33 m or 500 m of clearance when their input order is swapped (minimum depth 20 m, previous depth 40 m at 0 m). Two blocked samples at the same distance likewise yield 333.33 m or 400 m. `_CheckDepthLine` returns before reducing the complete equal-distance group. NAVYGROUP consumes this distance for collision warnings and hull/lookahead diagnostics. | Evaluate coincident samples together before interpolation, retaining the conservative bound and deterministic evidence; test both query directions, reversed input order, endpoints and unavailable data. |
| P2: Route updates lose drawing ownership and can leave partial geometry | Both `UpdateFromVec2Array` and `UpdateFromVec3Array` replace `self.points` without removing old IDs. A three-point route leaves all five original drawings after update and explicit cleanup. An injected terrain error on the second new point leaves a one-point replacement instead of the original route. | Build the replacement first, then release the old route's drawings and install the complete points; test both update methods, failure and delayed removals. |
| P2: Missing terrain values break point marking | `MarkPoints` formats surface, height and depth directly as numbers. A missing value in any of these fields raises a formatting error although point creation preserves missing terrain and depth helpers explicitly support unavailable data. | Show unavailable metadata explicitly without fabricated numeric values; keep marker ownership correct and test missing/non-finite values. |
| P2: Point creation accepts malformed positions | `_CreatePoint` selects dimensions by truthiness of `Vec.z`. `{x=7,y=9,z=false}` becomes `{x=7,y=16,z=9}` in the fixture; missing x and NaN x are stored by the Vec3 adder. | Validate raw position components before dimension selection, terrain access or mutation; preserve valid zero coordinates, input-copy ownership and documented nil handling. |

These probes establish deterministic code behavior, not a claim that the
observed naval DCS failures had these causes. No mission log was inspected
and no simulator validation was performed for this review.

PATHLINE follow-up approved and completed on 2026-10-10:

- [x] Reduce complete equal-distance sample groups before prefix interpolation.
- [x] Build replacement points before releasing old geometry/drawings.
- [x] Display unavailable terrain metadata without numeric-format failures.
- [x] Validate raw positions before terrain queries or path mutation.
- [x] Clean up affected comments/control flow and validate under Lua 5.1.5.

The first 15 new regressions all failed against the unchanged implementation
(10 PATHLINE, 5 depth). The completed suites add 16 cases, including a further
check for stable tied evidence and independent report copies. Profile-order
permutations are exercised in both query directions. Unavailable data at a
distance takes precedence over non-water, followed by the shallowest depth;
equivalent evidence is selected by cause, location and coordinates. The
existing endpoint preflight and the synchronous three-profile corridor
contract remain intact. Report positions omit unavailable sample heights.

Both update methods now prepare the full replacement before removing old
point/line IDs; malformed input or construction-time terrain errors retain
the previous route and drawings. Previously scheduled line removal still owns
only the captured old IDs. Inputs are copied, nil point additions remain
no-ops, and valid zero components/measurements are retained. Vec2 conversion
requires a finite sampled altitude rather than inventing one. Point labels
show invalid or unavailable metadata explicitly. The drawing fixture now uses
positive water depth, matching the terrain API contract.

Lua 5.1.5 syntax compilation and PATHLINE (21), profile (15), depth (33),
ASTAR (295), and NAVYGROUP (25) regressions pass: 389 cases in total.
The final diff was reviewed and passes `git diff --check`. These controlled
fixtures do not validate DCS terrain, physics, drawing or controller behavior;
no mission/include was loaded or observed during this implementation step.

The update methods still accept `Name` without renaming the object or its
DATABASE registration; this existing behavior is now documented and tested.
There are no repository callers of either update method. Resolve rename
versus point-replacement-only semantics and registration implications before
changing this public parameter. The vague TODO was removed and the affected
lifecycle/missing-data documentation and nested control flow were cleaned up.

Existing independent point copies, ordered exports, isolated constructor
state and delayed drawing-ID capture remain covered by regressions.
The concrete [R1a geometry API](pathline-geometry-api.md) was approved and
implemented on 2026-10-10. Its five static functions create copied snapshots,
export positions, locate cumulative distances, project within segment/distance
bounds, and report signed turn geometry. LuaDoc defines ownership, units,
failures and edge cases. Geometry has no terrain or controller dependencies.

The 26 new deterministic regression cases initially failed against the missing
API while the existing 21 PATHLINE cases passed. Lua 5.1.5 syntax checks and
PATHLINE (47), profile (15), depth (33), ASTAR (295), and NAVYGROUP (25)
regressions now pass: 415 cases. The final diff passes `git diff --check`.
No DCS validation or log observation occurred. ASTAR, GRID, NAVYGROUP and the
existing PATHLINE terrain/drawing methods required no production changes.

The [bounded connection/depth-validation API](pathline-validation-api.md) was
specified on 2026-10-10 at the user's request. It defines caller-stepped jobs,
an atomic connection adapter, incremental depth/corridor sampling, independent
slice/total limits, cancellation/context ownership and unavailable-data evidence.
R1a-V1 was subsequently approved and implemented: the five connection/job functions
include LuaDoc, copied reports, separate evaluation/commit phases and terminal
cleanup. Thirty-six new regressions and the existing five affected suites pass
under Lua 5.1.5 (451 cases total). Syntax and final diff checks pass. No simulator
test was performed, and no other production class required changes.

R1a-V2 was then approved and implemented: incremental depth/corridor sampling,
raw profile collection, stable merge/group processing, point/profile/work budgets
and conservative missing-data results. Thirty-seven new cases and all six
previous affected suites pass under Lua 5.1.5: 488 total. A new regression exposed
a rounded-away lateral offset, now rejected as `numeric_range`. LuaDoc, syntax
and final diff checks are complete. No other production class changed.
The R1a helper implementation is complete; DCS validation remains pending.
`CheckDepth` is unchanged and NAVYGROUP LOCAL navigation remains disabled.

Capability status; geometry and validation contracts are specified in the linked
documents. Connection/job and incremental depth validation are implemented:

| Capability | Contract | Status / needed |
| --- | --- | --- |
| Geometry snapshot from Vec3 positions | Copy points; compute segment lengths, cumulative distance and headings in the horizontal plane; no terrain queries or controller objects | Implemented; R1 |
| Projection / position at distance / turn geometry | Return original segment, fraction, along-route distance, lateral distance and interpolated position; accept segment and distance bounds; expose tied projection ambiguity, duplicate handling and signed corner angles | Implemented; R1 preparation and R3 progress |
| Bounded route validation | Walk original connections with an atomic evaluator; report evidence/cost, work limits and owned continuation/context; opaque callbacks have no internal native-work guarantee | R1a-V1 implemented and regression-tested |
| Sampled corridor/area validation | Incrementally check interior profiles, not just center/edges; distinguish blocked/unavailable/limited; report spacing and work counts. Straight strips do not certify a turning hull. | R1a-V2 straight-corridor validation implemented and regression-tested; R2 maneuver envelope validation pending |

Current PATHLINE constructors sample terrain when adding points. Pure geometry
helpers use explicit copied snapshots without hidden terrain queries. Existing
constructors and their contracts remain intact.

Keep `CheckDepth` defaults unchanged: its three profiles do not cover the
interior of a corridor. A new explicit dense-validation operation can reuse
its primitive profile checks. A curved/rotating footprint needs both bounded
longitudinal and lateral sampling, with reported spacing; finite samples still
do not establish continuous terrain coverage.

PATHLINE owns geometry and generic sampling, not a Harbor Tug turn model.
NAVYGROUP supplies any vessel-dependent footprint/trajectory hypothesis.
Avoid broad ASTAR/PATHLINE depth-cost consolidation at the same time; their
current boolean/cost and clear-prefix reports have different contracts. Only
share further internals after equivalence tests and a demonstrated benefit.

### NAVYGROUP and possible additional classes

Keep ship policy in NAVYGROUP, but make preparation callable with a copied
input snapshot and injected connection evaluator, without a live DCS group.
Keep submission and FSM changes outside that function. This permits the same
preparation tests to run with virtual movement and a real ship.

Initially no new NAVIGATOR, generic vehicle planner or steering framework is
needed. Once fixed-pose preparation is stable, an Ops helper class can be
extracted if the local and global integrations actually share a substantial
implementation. That would be an explicit later step with module inclusion
and its own tests, not another required layer before the first useful result.

No mandatory change to UNIT/COORDINATE, TIMER or the FSM framework is identified.
Use cached descriptor bounds and existing heading/velocity/waypoint conversion.
Do not infer a calibrated turning radius or braking distance from hull length.
Any OPSGROUP change must be limited to the verified arrival/task boundary and
tested against the other group types.

## Proposed runtime workflow

### 1. Establish ownership and a complete input snapshot

`SetPathfindingMode(LOCAL)` configures the strategy; selecting a mode does not
issue movement. An accepted movement command owns a session identified by a
generation number and the original target UID/position. Record the actual
position/heading/speed, requested speed, hull bounds, depth/corridor/cost rules,
search settings and geometry/validation tolerances.

Proposal: while LOCAL controls an original waypoint leg, all commanded geometry
for that leg passes through this pipeline. Do not release back to an unchecked
ordinary route merely because the next 5000 m are clear. End local ownership
when the original destination is physically reached or movement authority
changes. A direct exact-goal connection can bypass grid exploration only when
its entire geometry, maneuver entry and cost policy have been checked.

For the first trials, configure LOCAL before starting a stationary vessel.
Enabling or switching mode during an existing voyage is a separate integration
case, not an assumption that an already submitted native route becomes checked.

### 2. Obtain geometric candidates

Run one bounded ASTAR local request with the explicit test configuration.
Initially orient windows towards the overall goal as in the successful virtual
baseline; do not change orientation, resolution and depth weight together.
Only a completed successful request supplies candidates.

Handle `running`, `cancelled`, `search_changed`, `cell_limit`,
`no_local_exit` and `data_unavailable` separately. An advisory
`repeated_planning` or `loop_detected` report is evidence to log and evaluate,
not an automatic geometric failure. An incomplete-data report can contain a
fully checked candidate; uncertainty elsewhere must remain visible.

### 3. Prepare a route from a fixed pose

For each published candidate, in deterministic order:

1. Copy the position list. Remove duplicate/collinear points only when geometry
   and fresh connection checks permit it; preserve exact endpoints.
2. Start with conservative, bounded simplification. Every shortcut must pass
   `EvaluateConnection`; retain the original section when a shortcut fails or
   unnecessarily defeats the depth preference.
3. Evaluate the entry heading, each change in travel direction, hull clearance
   and stopping/terminal area using explicit assumptions. The turn angle is
   the wrapped difference between incoming and outgoing course, including the
   vessel's initial heading at entry. It is not the ship's current heading
   change per timer tick.
4. Validate the prepared connections and the modeled maneuver footprint.
   Record the first concrete failure and bounded aggregate reasons per candidate.
   A full disk around every corner, arbitrary maximum leg length and a single
   universal turn-angle cutoff are not the new default.
5. Recompute the actual prepared cost. For an unchanged candidate endpoint,
   compare `candidate.Score + preparedCost - candidate.Cost`, preserving
   exact-goal priority. Necessary maneuvering may increase cost; a soft depth
   preference must not become a hard rejection of an otherwise usable passage.
6. Return one immutable proposal or a structured failure. Do not submit routes,
   start timers, modify mission waypoints or report movement in this phase.

The initial unmodified polyline is retained as a diagnostic reference.
Simplification is an optimization, not a reason to lose every raw alternative.
If the raw geometry itself cannot be executed, report that limitation; do not
claim that disabling a validation check makes it safe.

Do not require a second full ASTAR continuation for each candidate before
allowing the first section. Require a checked usable terminal area instead.
This removes the previous candidate-by-continuation explosion without asserting
that a local exit cannot lead to a dead end.

### 4. Submit only from a current, checked starting condition

Before issuing a native route, verify the session/command generation, target,
settings, active route generation and movement authority. Use a fresh live pose.
If the ship moved while planning, validate the connection through the remaining
old checked prefix and the join to the new proposal. Never jump directly to a
distant retained anchor, skip an intervening island, or assume the planning
start is still the actual position.

If preparation is no longer applicable, discard it with a specific reason.
Continue only on a still-valid old route while adequate stopping room remains.
Once stopped for this command, no late result may resume the ship.

Preserve commanded altitude/depth and speed units at the native waypoint
boundary. Do not silently change the user's cruise speed to make preparation
succeed; report the validated speed range or recommended test speed.

### 5. Observe route following and prepare one continuation

Use actual positions projected onto a contiguous part of the installed route.
A nearest point anywhere on a crossing/hairpin path must not skip earlier
segments. Segment ranges and plausibility checks belong to NAVYGROUP; PATHLINE
provides the geometric result. Progress can tolerate limited lateral deviation
without silently accepting an unsafe rejoin.

A native waypoint callback is an observation, not proof of arrival or turn
completion. Internal anchors do not advance original waypoint tasks. Complete
an original leg once, through existing OPSGROUP/FSM behavior, after the actual
arrival criteria are satisfied. No direct writes that bypass FSM events.

Plan at most one continuation from a stable point ahead on the checked route,
using its incoming heading. Keep the unconsumed prefix in the replacement
native route and validate the junction. Track current installed route and one
pending proposal separately. Do not repeatedly replace the route while turning
or merely because another planning slice has completed.

A large deviation, stale proposal, changed speed envelope or endangered hull
has its own explicit outcome; it is not repaired by resetting a progress index.

### 6. Stop policy and time budgets

When the next route is not ready before the safe stopping threshold, issue
`FullStop`, invalidate/cancel pending work, retain the failure report and wait
for a new movement command. This applies equally to a late result, exhausted
budget and unavailable route evidence. A timer, grid drawing, cache update,
`TurningStopped` or callback cannot implicitly issue `Cruise`.

The new movement command creates a new ownership generation and plans from the
then-current observed pose. Compatible terrain/learning may be reused; an old
proposal is never blindly reinstated. Manual stops and external tasks always win.

Start continuation early enough to leave both planning and stopping room.
Use distance along the checked route, not straight-line distance to the goal.

A design estimate for the minimum remaining route reserve is:

```text
reserve = measured/modelled stopping distance at actual speed
        + speed bound * worst allowed observation/submission delay
        + explicit uncertainty margin
```

An earlier planning trigger additionally includes a measured allowance for
planning duration in simulation seconds. CPU seconds and elapsed wall time are
not interchangeable with this duration. No numerical stopping guarantee exists
until R2 measures the vessel/controller behavior. The current `speed * 10`
nearfield lookahead is a heuristic, not that calibration.

Reuse the normal navigation/safety timer. Add at most one dedicated, owned
planning TIMER while a job is pending, with explicit bounded phases for search,
connection validation and route preparation. ASTAR itself owns no timer.
Prefer explicit resumable state over a coroutine spanning search, drawing and
native timer calls. Each tick checks generation and authority before work and
before publishing a result. Drawing is separate and cannot advance navigation.

Bound work items, CPU per tick, total job duration/work, requests per movement
command, retained candidates and report history. Native terrain/controller calls
remain non-interruptible. Start budget trials with known standalone settings,
then measure aggregate load across groups and simulation acceleration.

## Maneuver and safety validation

The existing nearfield check mixes current hull occupancy with a straight
projection ten seconds beyond the bow. The actual hull check is valuable, but
the forward projection can see land that a checked turn would avoid. Keeping
that projection unchanged can reproduce the earlier unnecessary stops.

Separate these meanings during R2:

- Current hull occupancy: actual pose, heading and asymmetric model bounds;
  hard minimum depth, including interior samples.
- Planned upcoming maneuver: sampled corridor/footprint along the proposed
  executed geometry, including uncertainty around observed corner rounding.
- Emergency/stopping envelope: based on measured response to a stop at the
  current speed; checked before consuming the remaining usable route.

Do not remove the current protection before the replacement is evidenced.
Log which check requests a stop. Compare old and proposed forward checks in a
non-commanding diagnostic mode first. The global WAYPOINT safety policy remains
unchanged unless a shared change is explicitly agreed.

A complete route requires clear straight sections, feasible transitions and
enough terminal room to stop if the next section is unavailable. The path's
centerline, three depth profiles and even a dense color overlay do not establish
all three. DCS observations calibrate the execution assumptions; the preparation
report must distinguish assumptions from measured vessel/speed coverage.

## Parameters and depth weighting

The first parity fixture uses the known T2 geometry: hex grid, 400 m spacing,
6000/4000/1500 m ahead/width/behind, minimum 3.5 m, 50 m corridor, preferred depth
15 m and MaxCells 3000. Start with weight 1 as the successful comparison; run
weight 10 separately with every other input held fixed. Record the effective
request/slice limits rather than inheriting an old test-script default.

These are test parameters, not new production defaults. A coarse grid can be
adequate for a virtual route and still miss a feasible ship approach. Change
resolution only after recording the cause, then repeat virtual and ship tests
with the same new configuration.

Weight 10 can legitimately choose longer/deeper routes, including temporary
retreat, and a local search can spend its finite budget before finding the
global route. It must not weaken the minimum depth, conceal a loop or be blamed
for an unexplained steering failure. Require explained, bounded behavior at
weight 10; do not promise the hand-drawn globally attractive route from a finite
local window. Keep weight-1 passage completion as the first executable gate.

## Data ownership and diagnostics

Use three distinct records rather than one large mutable navigation table:

| Record | Contents and owner |
| --- | --- |
| Command/session | NAVYGROUP-owned generation, original target, settings revision, observed progress and movement authority; one persistent ASTAR instance |
| Planning job/proposal | Copied input pose/settings, request and candidate IDs, phase/work counters, copied prepared points, cost, assumptions, rejection evidence; no controller mutation |
| Installed route | Route generation, copied submitted points, cumulative distances, active segment, validated speed/clearance assumptions and terminal stopping area |

Cancellation destroys job ownership. A successful search report remains data,
not a command. Old grids/nodes must not be retained by installed route records.
Only the current display/search and a bounded diagnostic history remain alive.

Record activation, each completed request, candidate acceptance/rejection,
submission, handover, stop and original-goal arrival. Include source/test ID,
command/request/route generations, actual and planning pose, raw versus prepared
cost/length, actual speed, turn-angle/envelope evidence, depth failure location,
work/CPU/simulation time and progress.

Use explicit reasons such as `connection_blocked`, `depth_unavailable`,
`entry_maneuver_unverified`, `turn_envelope_blocked`, `proposal_stale`,
`route_deviation`, `continuation_not_ready` and `movement_authority_lost`.
Log bounded summaries and the first evidence for each reason, not every sample.
Programmer exceptions remain errors and are never converted to a successful route.

Display raw candidate, submitted route, checked maneuver corridor and actual
track with a documented legend. Distinguish the search window and center-depth
colors from the area validated for execution. Navigation outcomes must be the
same with drawings enabled or disabled.

## P0 test and replay contract (2026-10-10)

The developer requested the concrete P0 design after R1a-V2. The
[P0 test and replay contract](local-pathfinding-test-contract.md) now defines
shared resolved test parameters, source/terrain provenance, frozen poses,
cold and scripted warm inputs, copied raw candidates, stage reports and
comparison criteria. It distinguishes request parity, virtual following and
fixed-pose preparation. An unchanged search must not be influenced by a
consumer's pose-heading/speed checks. Different evolving routes cease to be
identical-input comparisons.

The weight-1 T2 search settings remain the baseline; weight 10 changes only
that named parameter. Additional dense sampling uses proposed explicit
25-m longitudinal and 10-m lateral spacings, with no new production default
or implied turning clearance. Native-repeat, analytic and exact-transcript
replay have distinct evidence requirements. Incomplete historical captures
cannot be described as exact reproductions.

P0 design is complete for review; executable fixtures, comparison tooling
and transcript capture/replay are not implemented. The next proposed step
is P0-I1, the standalone fixture/comparison driver; P0-I2 adds bounded terrain
transcripts before R1b preparation integration. This documentation step
changes no production code or simulator behavior.

## Implementation plan and gates

Proceed in small steps. R1 and R2 precede moving local continuation.
R1a geometry, connection/job and incremental depth helpers are implemented.
P0 contracts are documented; their test tooling and the other milestones below
remain proposed and unimplemented.

| Step | Deliverable | Exit criterion |
| --- | --- | --- |
| P0: common inputs and replay | [Contract documented](local-pathfinding-test-contract.md); shared resolved inputs, source/terrain identity, frozen poses and stage reports. P0-I1 fixture/comparison driver and P0-I2 transcripts pending | Identical search input produces identical raw candidates regardless of consumer; old failure evidence is reproducible where sufficient data exists. |
| R1a: PATHLINE geometry and validation | Pure geometry/projection, V1 connection/job and V2 incremental depth validation implemented with Lua 5.1 regressions; simulator validation pending | Deterministic tests for vertical/rotated paths, duplicates, hairpins, self-crossings, missing data and cancellation; no hidden terrain access in geometry. |
| R1b: fixed-pose naval preparation | Bounded candidate preparation using existing ASTAR and new shared helpers; no moving vessel or route submission | Every raw candidate is accepted or rejected with evidence. Known island/shoal cases retain hard depth/corridor rules; feasible reference passages survive preparation. |
| R2a: movement measurements | Small DCS experiments with one precomputed straight route, turn and stop; use the Harbor Tug at explicitly chosen test speeds | Measured actual tracks, turning deviation and stopping distance; documented uncertainty and supported speed range. No rolling search yet. |
| R2b: one prepared passage | Submit one prepared passage, then extend to the known shallow/insular section; compare actual track to assumptions and legacy lookahead | No grounding, unexplained stop or route replacement; preserve original waypoint actions. Only a validated replacement may alter the LOCAL forward safety policy. |
| R3a: integration contracts | Generation/authority lifecycle, actual progress, task/arrival boundary, one continuation and native-route handover | Deterministic moving-ship replay covers late results, turns, retargeting, callback races and missing continuation. Stops never auto-resume. |
| R3b: rolling DCS passage | Full known route with explicit initial and continuation planning | Repeated successful weight-1 passages, explained weight-10 outcomes, accurate arrival and bounded memory/work, debug on/off parity. |
| R4: wider supported scope | More vessels/speeds, multiple original waypoints, mission tasks, formations only with explicit clearance design | Expand documented support only for cases actually validated; consider reuse by global search in a separate change. |

R1a helper implementation is complete: the [pure geometry API](pathline-geometry-api.md)
and both stages of the [connection/depth-validation API](pathline-validation-api.md)
are implemented and regression-tested. V1 preserves an evaluator's unavailable
result and owns cancellation; V2 adds resumable native terrain checks. Geometry
itself has no terrain queries or asynchronous work. These helpers do not enable
LOCAL or establish simulator/controller safety.

P0 must distinguish measured data from reconstructed positions. The last case55
log lacks detailed candidate-rejection evidence; do not claim an exact replay
of the unknown rejection chain. Use its observed pose/parameters as a scenario
and capture the missing evidence in R1.

For R2, begin at a deliberately modest, explicitly approved test speed. Increase
speed one variable at a time and include 26 knots only after validating the
preceding speed/geometry. A low-speed success does not certify the same route
at the earlier requested cruise speed.

Suggested implementation commits, after approval:
1. P0 test configuration/report contracts (documented), then separately approved P0-I1 fixture/comparison driver and P0-I2 terrain transcripts.
2. R1a pure geometry, V1 job/connection validation and V2 incremental depth validation with tests (completed).
3. R1b preparation with stationary/virtual tests.
4. R2 diagnostics/driver and resulting measured maneuver policy.
5. R3a/R3b LOCAL orchestration and simulator validation.

Do not re-enable the public LOCAL mode as a working feature during the first
helper-only commits. Use a dedicated preparation/execution test driver. Expose
LOCAL only once the single-vessel execution and integration gates are met,
documenting the tested limitations.

### Required regression matrix

- Open water; coast/island on both sides; narrow valid passage; shallow passage
  with no deeper local alternative; asymmetric hull and a small interior islet.
- Initial heading aligned/across/away from the route; several consecutive bends;
  changed speed; a long clear connection; zero-length/duplicate points.
- A feasible rearward detour, dead end, repeated planning without movement and
  repeated directed transitions; distinguish retreat from unproductive cycling.
- Future anchors do not count as motion; early callbacks and self-crossings
  cannot skip route segments or original tasks.
- Stop, wait, external task, target/speed/rule change, group death/respawn, old
  generation callbacks and a proposal completing after FullStop.
- Missing depth on a selected path versus on rejected alternatives; no false
  terrain failure on a resource limit.
- At most one pending continuation; no loss of the retained checked prefix;
  stale connectors rechecked; adequate terminal stopping room.
- Every limit terminates predictably; no-clock work limits still work; actual
  CPU, simulation duration and wall duration remain separate.
- Existing WAYPOINT, task/FSM and standalone ASTAR behavior remain covered;
  no drawing ownership leaks or timer resurrection.

### Validation and review

For each implementation step, compile changed Lua with Lua 5.1.5 and run affected
suites in separate processes. Add deterministic regressions for the new contracts.

```text
lua tests/navy-pathfinding.lua
lua tests/waypoints.lua
lua tests/astar.lua
lua tests/grid.lua
lua tests/pathline.lua
lua tests/pathline-validation.lua
lua tests/pathline-depth-validation.lua
```

Include depth/vector/timer or other downstream suites when their behavior is
changed. Stubbed checks do not replace R2/R3 DCS observations. Record loaded
source/include identity and explicit mission starts; read the log only for an
announced test, preserve raw bytes, and do not create recurring monitors.

Review the actual submitted route and observed positions, not just grid colors
or `path_found`. Completion requires the original goal's observed arrival.
When an assumption fails, return to its responsible stage rather than adding
another cross-cutting guard.

### Immediate next step

Next approval request: **P0-I1 shared standalone fixtures and comparison driver**
from the [P0 contract](local-pathfinding-test-contract.md). Implement resolved
parameter validation, analytic terrain cases, scripted search histories, copied
candidate reports, an identity consumer and strict comparison/serialization tests
under Lua 5.1. Actual maneuver preparation and NAVYGROUP control remain later work.

The R1a APIs and their regressions are complete; P0 design is documented for
review. P0-I2 bounded terrain transcript capture/replay follows the first driver.
No DCS validation is claimed. Wait for approval or comments before P0-I1.
A missing continuation stops the ship until a new movement command.
