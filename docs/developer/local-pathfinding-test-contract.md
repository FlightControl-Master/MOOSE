---
title: Local pathfinding P0 test and replay contract
parent: Developer
nav_exclude: true
---

# Local pathfinding P0 test and replay contract

Status: P0 design elaborated on 2026-10-10 at the developer's request.
This document specifies the proposed fixture, driver and report contracts;
their implementation is a separate approval step. The R1a geometry and
validation APIs already exist. No production behavior, test runner, mission
or NAVYGROUP LOCAL availability changes in this documentation step.

See the [rebuild plan](rolling-pathfinding-plan.md),
[geometry API](pathline-geometry-api.md) and
[validation API](pathline-validation-api.md).

## 1. What the comparison must establish

Given identical resolved search inputs, terrain responses and prior request
history, virtual search and fixed-pose preparation must receive identical
ordered raw candidates. Preparation may then reject or modify a candidate,
but must identify the stage, input geometry and evidence responsible.

Use three separately reported experiments:

| Experiment | Input and advancement | What success means |
| --- | --- | --- |
| `request_parity` | One cold request, or a scripted sequence reconstructed from a cold start, run through both consumers | Equal raw search outcomes and candidate records |
| `virtual_follow` | Follow every point of the selected raw candidate exactly; observe those virtual positions before the next request | The virtual position reached the exact goal under its bounded request policy |
| `fixed_pose_prepare` | Freeze one explicit pose and one raw-candidate set; evaluate preparation without moving that pose | Every candidate has a stage result; a selected proposal is traceable to its checks and assumptions |

Do not compare later requests from independently evolving virtual and prepared
routes as if they had identical inputs. Once their selected endpoints differ,
their starts, progress histories, windows and learning can differ legitimately.
For a paired comparison, feed both sides the same explicit action sequence.
For an isolated preparation comparison, replay the same copied candidate set.

P0 does not submit native routes, call `Cruise`/`FullStop`, change waypoints,
create an autonomous monitor or enable LOCAL. Fixed-pose means an immutable
input sample, not a command that stops a live vessel. A live capture may include
a nonzero measured speed; the test driver never advances the captured pose.
The agreed future stop policy remains: stop and require a new movement command.

## 2. One resolved case, with explicit units and provenance

Proposed `SchemaVersion = 1`. These names describe test data, not new public
methods on MOOSE classes. Use plain bounded tables with independently copied
records; no class instances, nodes, closures, metatables or controller handles.
Reject unknown settings, sparse position sequences, invalid enums and invalid
numbers before invoking a search. Preserve zero and false; omission is not zero.

| Record | Required content |
| --- | --- |
| `Case` | `SchemaVersion`, stable `CaseId`, `Revision`, `Experiment`, `VariantId`, explicit expected assertions and their evidence basis |
| `Environment` | `TerrainId`, terrain-data revision if known, DCS build/map for native captures, Lua version, source manifest and provenance status |
| `Route` | Copied `Start` and `Goal` Vec3, `OriginalTargetId`; coordinates resolved before execution |
| `Search` | Grid type/spacing/cell filter, window extents and heading policy, neighbour/depth/cost rules, learning and progress settings |
| `Validation` | Geometry point cap, connection-evaluator configuration and explicit dense-depth options, including structural caps |
| `Pose` | Copied `Position`, `HeadingDeg`, `ActualSpeedMps`, per-field origin and capture time/clock when measured; `RequestedSpeedMps` and hull/model data when supplied |
| `Actions` | Ordered start/observe/step/cancel/retarget/invalidate actions and request boundaries, or a named deterministic virtual-follow policy |
| `Execution` | Slice/total limits by stage, clock mode, output/capture limits and debug settings |
| `Provenance` | Each externally obtained field classified as `measured`, `configured`, `reconstructed` or `unknown`, with its source reference |

The shared parameter block has this concrete shape; Route, Pose, Environment,
Actions and Execution are separate required case records. Enum strings below
are resolved against the current MOOSE/DCS enums by the test adapter.

```lua
-- Proposed fixture data, not a mission script or new MOOSE constructor.
local parameters = {
  Search = {
    Grid = {Type = "hexagonal", Spacing = 400, MaxCells = 3000,
      SurfaceTypes = {"WATER", "SHALLOW_WATER"}, ZoneRestriction = "none"},
    GridNeighboursOnly = true,
    Window = {Ahead = 6000, Width = 4000, Behind = 1500},
    HeadingPolicy = "towards_goal",
    Depth = {MinDepth = 3.5, CorridorWidth = 50},
    Cost = {Kind = "depth", PreferredDepth = 15, Weight = 1},
    LearningLimit = 4096,
    Progress = {MinDistance = 10, HistorySize = 32, RepeatLimit = 3},
  },
  Validation = {
    Geometry = {MaxPoints = 10000},
    Connection = {RuleSource = "search", CostUnits = "depth_weighted_meters"},
    Depth = {MinDepth = 3.5, CorridorWidth = 50, LongitudinalSpacing = 25,
      LateralSpacing = 10, MaxSectionLength = 1000, MaxOffsets = 65,
      MaxProfilePoints = 4096, MaxDirectPoints = 4097},
    Maneuver = {Status = "unverified"},
  },
}
```

The resolver derives Validation.Depth.MinDepth/CorridorWidth from Search.Depth
and rejects conflicting duplicates in a paired baseline. A requested intentional
override requires a named variant and explicit mismatch evidence. Persist both
effective values; neither consumer may silently choose a different default.

Positions use DCS Vec3: horizontal x/z and altitude y, in meters. Keep supplied
y values in snapshots; neither route altitude nor native profile y is water
depth. Horizontal headings are degrees clockwise from +x towards +z, normalized
to [0, 360). Speeds are m/s internally; any knots conversion records both the
original value/unit and the resolved m/s value. Length, remaining distance and
depth are meters. Depth cost uses `depth_weighted_meters`, a named cost unit;
never label that value as physical route length.

A mission adapter may resolve `ASTAR Start 1` and `ASTAR Goal 1` once and store
their exact Vec3 values. Zone/group names alone are not replay inputs. Every
later request uses the frozen coordinates or explicit action data, not another
live zone lookup. No positions are extracted from screenshots as measured data.
The case55 observations are a scenario reference: missing candidate/rejection
records cannot be reconstructed as an exact replay.

For the first paired fixed-pose case require `Pose.Position == Route.Start`
component by component. A mismatch is `input_mismatch`, before preparation.
Moving-start reconnection is a later integration case. Record observed and
requested speed separately; one must never fill in the other. Missing hull
bounds, speed or maneuver calibration prevents the corresponding maneuver claim,
but need not prevent a standalone geometry/depth comparison.

Hull data, when available, retains the model reference point and asymmetric
forward/aft/left/right extents, units, model identity and descriptor provenance.
No default Harbor Tug dimensions, turning radius or braking distance are inferred.

### Source identity

The source manifest lists logical paths and SHA-256 values for the actually
loaded bundle, or each loaded source in a dynamic include, plus the driver,
fixture and terrain-provider definitions. Include loader identity and order.
Git revision and a dirty-tree/diff identifier are useful context but do not
replace byte identity. A junction or matching file currently on disk does not
prove what a running mission loaded.

The capture process must bind a run's BEGIN marker to its prepared include/source
manifest, and establish that the identified bytes were loaded unchanged. If that
cannot be established, record `SourceVerification = "unverified"`; do not award
a strict source-verified parity/replay pass. Keep measured results usable as
observations with that limitation. Compute hashes in tooling outside mission
code; production classes gain no machine-specific paths or hashing dependency.

## 3. Shared parameter sets and actual API mapping

The baseline derives from the recorded T2 configuration. These are explicit
test values, not new production defaults or a maneuver-safety prescription.

| Setting | Proposed `t2-parity-v1` value | Existing API / interpretation |
| --- | --- | --- |
| Grid | `GRID.Type.HEXAGON` | `ASTAR:New(GridType)` creates its owned, unbuilt grid |
| Spacing | 400 m | `search:GetGrid():SetResolution(400)`; no automatic resolution or CrossSpacing |
| Candidate-cell cap | 3000 | `GetGrid():SetMaxCells(3000)`; counts candidates before filtering |
| Cell filter | WATER and SHALLOW_WATER; no zone restriction | `GetGrid():SetValidSurfaceTypes(...)`; record resolved enum values |
| Graph adjacency | Enabled | `SetGridNeighboursOnly(true)`; no manual nodes |
| Window | Ahead 6000 m, full Width 4000 m, Behind 1500 m | `SetLocalWindow(6000, 4000, 1500)` |
| Heading policy | `towards_goal` | Resolve once per request; pass the numeric heading to `StartLocalSearch`; coincident horizontal points use 0 |
| Hard depth | 3.5 m, full corridor 50 m | `SetValidNeighbourDepth(3.5, 50)` |
| Soft preference | 15 m, weight 1 | Apply `SetCostDepth(15, 1)` after the neighbour rule |
| Learning | 4096 cells | `SetLocalLearningLimit(4096)`; separate from the grid cap |
| Progress | 10 m, history 32, repeat limit 3 | Explicit `SetLocalProgress(10, 32, 3)` |

The weight-10 variant changes only `Weight`, receives a different variant/config
identity, and starts from its own cold state. It need not produce the weight-1
route or complete the global passage. Require bounded, explained behavior;
do not turn a resource limit into a claim that no route exists. Changing spacing,
window heading or hard clearance creates a separate named experiment.

Window heading is a search orientation. It does not constrain the vessel's
entry heading or certify a feasible turn. Varying only `Pose.HeadingDeg` or
`RequestedSpeedMps` must leave a paired raw search unchanged; it may change
preparation results. Record the effective returned window origin/heading as
well as the requested heading, because compatible requests can retain a window.

### Additional validation settings

Both consumers use the same resolved validation settings when running route
checks. Dense validation is an additional stage: it does not silently replace
ASTAR's existing center/edge depth rule or its cost integration.

| Setting | Proposed diagnostic baseline |
| --- | --- |
| `CreateGeometry` | `MaxPoints = 10000`, explicit rather than an inherited default |
| Connection evaluator | Adapter over fresh `ASTAR:EvaluateConnection` with the identical hard rule and soft cost; `CostUnits = "depth_weighted_meters"` |
| Dense depth | `MinDepth = 3.5`, `CorridorWidth = 50`, `LongitudinalSpacing = 25`, `LateralSpacing = 10` meters |
| Profile sections/caps | `MaxSectionLength = 1000`, `MaxOffsets = 65`, `MaxProfilePoints = 4096`, `MaxDirectPoints = 4097` |
| Maneuver model | Explicit identity, revision, parameters and calibration evidence if supplied; otherwise `unverified` |

The 25/10-m spacings are proposed P0 diagnostic choices, not measurements from
the old T2 run or proof of hull clearance. Width 50/spacing 10 produces seven
profiles with an actual lateral gap of 25/3 m. Reports retain the evaluator's
effective coverage. No weight is passed to `CreateDepthEvaluator`.

The connection adapter drops ASTAR's rejected `math.huge` cost, maps its
clear/blocked/unavailable status, and copies only the allowed scalar/position
evidence into PATHLINE. Retain ASTAR's original `Stage`, `Location` and depth
configuration in a bounded adjacent stage record where the PATHLINE evidence
schema does not accept them. Do not invent profile height from route altitude.

### Work and clock policies

| Stage | Slice settings | Total/structural policy |
| --- | --- | --- |
| LOCAL search | `StepSearch(100, 0.005)` | At most 4000 slices and 400000 LOCAL work items per request; at most 200 requests per virtual run; grid cap remains 3000 |
| Connection validation | Work 64, evaluator calls 1 | Work 200000, evaluator calls 4096 per job |
| Dense validation | Work 64, point checks 8, profile queries 1 | Work 200000, point checks 50000, profile queries 4096 per job, plus evaluator structural caps |
| PATHLINE CPU | Optional cap omitted in deterministic cases; proposed 0.005 s per slice in a separately identified native timing trial | No implicit total CPU deadline; an explicitly requested cap requires a usable clock |
| Preparation | Sequential candidate processing, at most the eight published alternatives | New geometry/simplification/maneuver work caps must be explicit in R1b; P0 cannot claim they already exist |

Search slice/request caps are test-driver policies, not extra parameters to
`StartLocalSearch`. Admit at most the remaining LOCAL work allowance in the
next `StepSearch` call and never call it with zero: its MaxNodes must be positive.
When a driver cap prevents more work, cancel and record both the native cancelled
report and the independent driver reason, such as `driver_request_work_limit`.
Do not overwrite native StopReason with a driver-invented ASTAR status. A result
completed on the last admitted step remains completed.
If multiple driver caps are exhausted together, use work, then slice, then
request-count precedence and record all exhausted caps. These checks run only
when another operation/request is needed; cancellation/context checks take priority.

ASTAR MaxNodes also bounds LOCAL work items. It does not bound individual native
depth/profile calls inside an edge evaluation. `StepSearch` always has a positive
CPU argument; nil selects its default and does not disable timing. Strict offline
fixtures therefore use a controlled, nonadvancing test clock and count limits.
Label its CPU observations `synthetic`; never report zero as measured CPU cost.
Native timing trials use actual `os.clock`, retain all slice budgets, and do not
require equal slice counts across machines or simulation acceleration settings.

The PATHLINE count/CPU contracts differ from ASTAR's and remain unchanged.
Record driver CPU, ASTAR inclusive CPU and PATHLINE inclusive CPU separately;
do not sum overlapping scopes. Record simulation elapsed time, wall elapsed
time and acceleration separately. Missing clocks produce missing measurements.
Native calls remain atomic; no budget is a hard frame-duration guarantee.

## 4. Reconstruct state through public actions

`InitialState = "cold"` means a new ASTAR instance, fresh owned grid, configured
rules and no previous observations/requests. InvalidateLocalCache is not a cold
reset: it does not reset every diagnostic or request identity. Do not serialize,
patch or restore ASTAR's private cache/learning/node tables.

For warm cases retain the instance and replay this bounded action vocabulary:

| Action | Payload / effect |
| --- | --- |
| `observe` | Explicit position and provenance; call `UpdateLocalProgress` |
| `start` | Copied start, goal and resolved heading; new stable driver RequestId, retain native RequestID |
| `step` | Stage and exact slice budgets; for count-driven search, CPU clock policy is part of the case |
| `cancel` | Current job and explicit test reason; do not resume it |
| `invalidate_terrain` | New terrain revision, call `InvalidateLocalCache`, cancel obsolete validation/preparation contexts |
| `retarget` | New explicit goal and context; cancel current work, then start a new request |

Changing rules/settings creates a new resolved variant and context, with explicit
setter actions if the case tests invalidation. No mutation hidden in a callback.
Each case records observations before requests: a planning anchor is not a
progress observation. In `virtual_follow`, label observations `virtual`; follow
each copied raw point from index 2, then request again from that endpoint if
ReachesGoal is false. Do not call UpdateLocalProgress with a future anchor.
In a stationary preparation case, no candidate point advances observed progress.

One pairing runs two independent ASTAR instances through identical actions and
compares their raw reports. A second test fans one completed, deep-copied candidate
set into both consumers to isolate consumer mutation/preparation defects. Do not
share nodes, a live SearchReport or mutable candidate arrays between consumers.
Reports update in place while ASTAR is running; capture only copied snapshots.

## 5. Reproducible terrain, serialization and capture limits

Distinguish three replay capabilities in every artifact:

| Capability | Evidence | Allowed claim |
| --- | --- | --- |
| `analytic` | Versioned deterministic terrain-provider code and explicit parameters, with no uncontrolled random/global state | Repeatable offline scenario for arbitrary queried coordinates |
| `recorded_exact` | Complete ordered native-call transcript with exact inputs/outputs, source identity and cold action history | Replay of that same query sequence; fail at the first mismatch |
| `native_repeat` | Frozen mission inputs plus map/build/source metadata, using live native terrain again | A repeat test, not guaranteed bitwise reproduction of terrain responses |

Pure preparation replay may instead start from an exported candidate snapshot.
It reconstructs preparation only and cannot claim to replay the preceding search.
The artifact says which stages are present. Re-running search after an algorithm
change often changes queries; use analytic terrain or capture a new native run.
Never answer an unmatched replay query using the nearest recorded sample or zero.

Offline transcript wrappers cover `land.getSurfaceType`,
`land.getSurfaceHeightWithSeabed`, `land.profile`, and any other native terrain
function actually called by the selected code path. An unrecognized call is a
capture/replay gap. Separate transcripts by stage and consumer so additional
preparation queries cannot consume the search tape. Each entry has a sequence
number, function, exact arguments and all returned values with explicit arity.
Preserve trailing nil, false, zero, array order, duplicate profile points and
malformed/sparse profile data used by negative tests. Exceptions remain errors.
Arbitrary Lua error objects are retained only inside a controlled fixture;
unsupported external objects make a capture non-replayable, not successful.

Use UTF-8 structured artifacts (JSON is the proposed interchange format) and
schema-checked decoding, never executable Lua loaded from a captured file.
Finite numbers require round-trip binary64 serialization; test the serializer
under Lua 5.1 and reject locale-dependent/comma decimals. Failure-test values
such as nil, NaN and infinity need explicit tagged values, not JSON numeric
approximations. Tables with invalid/sparse keys use tagged ordered entry records;
never silently normalize them into a valid profile. Ordinary valid case/candidate
positions remain dense arrays. Do not serialize engine objects or callback graphs.

Canonical configuration bytes use a fixed field order, deterministic enum/set
order and explicit representation of optional values. Tooling hashes them and
the raw artifact bytes. Keep separate identities for resolved search inputs,
validation inputs, source/terrain identity and the action-prefix history, so
changing only depth weight or preparation pose is visible. Capture the whole
resolved document as well: a hash alone cannot explain a difference.

Proposed capture caps: 200 requests/run, eight candidates/request, 10000 positions/
candidate, 10000 retained structured events/run, 100000 terrain calls/stage,
1000000 encoded profile records/stage and 64 MiB per transcript artifact.
The complete manifest/cap values are explicit run inputs. Exceeding a cap ends
strict recording as `capture_limit` before another operation is admitted where
possible; an oversized native response can be detected only after it returns.
Mark the capture incomplete and cancel the controlled test jobs. Do not silently
truncate and award a replay pass. Native allocation/time cannot be bounded here.

Keep live memory to the current search/preparation, its at most eight candidates,
bounded active evaluator buffers and a bounded event buffer; stream completed artifacts to the
test-output directory where the host permits writing. Raw native responses may
already exceed a capture cap. No growing session-wide node/sample registry.
Fixtures deliberately added for regression belong in tests; native logs, hashes
of local missions, profiler files and large captures stay outside source patches.

Do not install global terrain wrappers into an ordinary mission. P0-I1 uses
controlled standalone fixtures in separate Lua processes. Any native capture
adapter must run in an explicitly isolated test environment and restore its
owned hooks on completion/error. Without suitable capture access, record
`native_repeat` or incomplete evidence; do not weaken DCS sandbox settings.

## 6. Fixed-pose preparation boundary

The future R1b entry takes the resolved case, an immutable pose, copied ordered
candidates and injected connection/depth evaluators. It never reads a live group
while processing and does not retain ASTAR nodes. Context identifies the run,
request, pose/settings revision and candidate; cancellation/context mismatch
discards pending work. Completion grants no movement authority.

For each candidate, preserve the raw reference and report these distinct stages:

1. Geometry creation and exact endpoint checks.
2. Fresh connection validity and repricing with the configured ASTAR rules.
3. Dense depth/corridor validation, with its full bounded PATHLINE report.
4. Proposed geometry transformations and their fresh validation/repricing, if
   enabled by the later preparation contract; identity transformation is the
   first diagnostic reference.
5. Entry, turns and terminal/stopping footprint under an explicit maneuver model.

Every transformed point sequence has its own geometry identity and links to the
raw candidate. Record indices and endpoint mapping for its evidence. A transformed
connection cannot inherit an earlier geometry's clear report. Width/MinDepth are
shared by the connection and dense validators; a deliberate difference is a
separate test variant. Additional hull/turn margins belong to the maneuver stage.

Preserve candidate order and exact-goal priority. For unchanged endpoints,
prepared score is `Raw.Score + PreparedCost - Raw.Cost`, retaining learned
penalty and compatible goal heuristic. Record all terms and cost units. Do not
reuse this formula after changing the candidate endpoint. A failed optional
shortcut retains the original alternative; it is not by itself rejection of
the whole candidate. R1b must report its actual selection rule and stable tie key.

A clear sampled route can coexist with `Maneuver.Status = "unverified"`.
Without the necessary pose/model data, do not claim `ready_under_model` or ship
safety. Even a proposal ready under a supplied model retains that model's
assumptions and calibration status; `ExecutionValidated` remains false in P0/R1b.
No arbitrary turn-angle cutoff, stopping distance or implicit cruise speed is
introduced by this data contract.

Preparation statuses are `not_run`, `running`, `ready_under_model`, `rejected`,
`unavailable`, `limited`, `cancelled`, `error` and `unverified`. Each published
candidate has a result entry, including `not_run` with a reason if selection or
a shared cap stops evaluation before that candidate. Resource/data limits do
not become `rejected` geometry. The P0 identity consumer reports actual geometry/
route checks separately and always leaves maneuver preparation `not_run` or
`unverified`; it cannot publish a ready naval proposal.

## 7. Result records and comparison rules

All records carry SchemaVersion, RunId, CaseId/Revision, VariantId and monotonic
EventSequence. Candidate identity is `(RunId, RequestIndex, CandidateIndex)`;
never use a request-local ASTAR node ID as a durable identifier. Native RequestID
and WindowID are retained separately. Resolve each artifact reference relative
to the run output directory and record its checksum/completeness.

| Record | Essential fields |
| --- | --- |
| Run manifest | Resolved inputs/identities, provenance, source verification, replay capability, clock policy and capture limits |
| Request result | Requested start/goal/heading; native Status, StopReason, FailureReason, Outcome; effective Window, WindowReused, GoalInside/GoalFailure; candidate count; cells/work/cache/learning counters; Progress and DataIncomplete evidence |
| Raw candidate | Copied Positions, Cost, BaseScore, LearnedPenalty, Score, Length, RemainingDistance, ReachesGoal, optional Sector; original ordered index and geometry identity |
| Candidate preparation | Stage sequence; raw/prepared geometry references, cost/score terms; connection and depth reports; maneuver inputs/results; explicit acceptance/rejection/unverified reason and selected flag |
| Stage result | Native status/reason unchanged, driver stage status, context, original/prepared segment mapping, first failure evidence, effective limits/coverage and counters |
| Comparison | Compared identities, comparison kind, pass/fail/inconclusive, first differing field and both values; differences in diagnostics/timing reported separately |
| Run end | Driver Status, Verdict, stop reason, completed request/candidate counts, selected proposal or virtual goal result, capture completeness and outstanding limitations |

Do not flatten all status vocabularies into `PASS`. ASTAR `complete` can mean a
failed search or a limit; PATHLINE `clear` concerns only its reported coverage.
`DataIncomplete = true` does not invalidate an otherwise checked candidate,
but uncertainty on unvisited/alternative edges remains visible. `repeated_planning`
and `loop_detected` are advisory Progress statuses, not automatic rejection.

Driver Status is `running`, `complete`, `limited`, `cancelled` or `error`.
Verdict is independently `not_run`, `passed`, `failed` or `inconclusive`, evaluated
against explicit assertions. An expected cell limit can pass its negative case;
the same limit in a virtual-arrival case is no arrival. Invalid fixture arguments
raise errors. Missing capture/source evidence makes strict replay inconclusive;
an actual mismatch on complete comparable data fails. Preserve native exceptions
after bounded error reporting and cleanup; never convert them into terrain data.

For strict offline parity compare enums, order, booleans, optional-field presence,
all candidate coordinates/costs and stable logical counters exactly. Runtime IDs
map through the corresponding action sequence. Exclude clocks, display IDs and
host output paths. Canonical semantic input identities also exclude per-run IDs,
timestamps and output destinations. Expect equal final outcomes under small versus large slices;
slice count and intermediate yield boundaries are not equality requirements.
Strict transcript replay uses the recorded slice schedule and query arguments.

For native repeats report exact differences and optional approximate comparisons
separately. Proposed diagnostic tolerances are 0.001 m for positions/length and
`max(1e-6, 1e-9 * max(abs(a), abs(b)))` for cost. They do not relax minimum depth,
reinterpret a failed sample, merge a different candidate order, or turn a
near-goal endpoint into an exact-goal success. Inputs/replay query keys are never
rounded to these tolerances. Changed source versions compare behavior, not
necessarily work counts or an unchanged native-call sequence.

Log only BEGIN, completed request/candidate stages, meaningful failure/cancel
and END summaries, with artifact references. No line per sample or heartbeat.
Drawings consume copied results after capture and cannot alter search progress.
Colors show sample-center depth only. Debug-on/off parity is a dedicated case;
drawing CPU and additional native calls are outside the search transcript.

## 8. Acceptance matrix and implementation handoff

| Case | Required assertion |
| --- | --- |
| Cold paired open-water request | Identical ordered raw candidates, exact endpoints and costs; independent consumer ownership |
| One-unit versus normal slices | Same final semantic report and no duplicated native calls; timing/slice counts treated separately |
| Warm compatible requests, window replacement, learning | Replaying the public action prefix reconstructs the same outcomes; cold and warm runs are identified differently |
| Pose heading/speed variant | Identical raw search; preparation records its different input/decision or unverified model |
| Weight 1 versus weight 10 | Only the declared weight changes; cost/detour differences explained, hard clearance unchanged |
| Interior shallow spot / island / only shallow feasible passage | Raw, connection, dense and maneuver stages retain separate evidence; no safety claim from grid colors |
| Missing depth on candidate versus elsewhere | Candidate-stage unavailable distinguished from search DataIncomplete on alternatives |
| Cancel, retarget, invalidation and stale result | Context ownership preserved; no subsequent work, route command or automatic resume |
| Cell/work/slice/request/capture cap | Correct native versus driver reason; terminal state, no silent coarsening/truncation |
| Sparse/invalid terrain data, trailing nil, zero, false | Round-trip exact negative-test input; blocked/unavailable/error remain distinct |
| Truncated transcript or unmatched query | Stop at the first gap; no fallback to live/nearby data in strict replay |
| Mutation of candidate/report/options | Other consumer and original snapshot remain unchanged |
| Debug on/off | Same search semantics; graphics queries/timing do not contaminate core evidence |
| Historical case55 without full evidence | Explicit reconstructed scenario only; no invented exact rejection chain |

The next proposed implementation subtask is **P0-I1: shared standalone fixtures
and comparison driver**. Add a test-only helper, analytic water/shoal/island/
missing-data fixtures, resolved-case validation, count-driven search sequences,
copied raw-candidate reports and strict comparison/serialization regressions
under Lua 5.1. Use an identity preparation consumer to verify the handoff;
label maneuver preparation not implemented. Do not implement NAVYGROUP control.

Then **P0-I2: bounded terrain transcript capture/replay** can add the exact
response codec, size limits and mismatch reporting, plus an isolated mission
adapter only after its environment/source capture has been specified. R1b's
actual geometry/maneuver preparation follows with a separately approved API.

Existing ASTAR, GRID, PATHLINE and VECTOR APIs suffice for the proposed P0
fixtures. No required production extension has been identified. Reuse the
existing Lua 5.1 test conventions and separate processes; do not add a loader
entry or a public compatibility API for test helpers. Any implementation gap
found later must be tied to a failing acceptance case before extending Core.

Design validation: cross-checked against current ASTAR local request/report,
progress, cache invalidation and StepSearch contracts; PATHLINE R1a geometry,
connection/depth validation and the recorded T2 weight-1 script. The repository
was clean at the beginning of this task. This change is documentation only;
no behavior tests or DCS runs are claimed. Relative links, code fences, CRLF
and the final documentation diff were checked; `git diff --check` passes.
Wait for approval/comments before P0-I1.
