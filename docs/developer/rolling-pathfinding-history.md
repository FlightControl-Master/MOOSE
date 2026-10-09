---
title: Rolling pathfinding development history
parent: Developer
nav_exclude: true
---

# Rolling pathfinding development history

> Archived on 2026-10-09 when the NAVYGROUP LOCAL integration was removed.
> The milestones, method names, test commands and claims below describe the
> retired implementation, not current NAVYGROUP behavior. The current decision,
> remaining shared capabilities and rebuild gates are in the
> [development plan](rolling-pathfinding-plan.md).
> Source and the former naval suite are preserved at commit `8ba49eb1b`.


Rolling planning should provide a checked local path towards a distant goal,
then plan another section as the caller moves. First establish this capability
in ASTAR and GRID independently of ships. Then simplify and optimize both naval
planning modes using the shared infrastructure.

Status as of 2026-10-09: M1 design and the approved M2.1/M2.2/M2.3 implementation are
complete. GRID windows and resumable local ASTAR requests now return checked
partial or exact-goal paths, reuse compatible windows, and report bounded actual
movement history and missing depth data. M2.4 standalone validation is complete:
T1, T2 at depth weight 1 and all eight T3 checks passed in DCS on the current
stable-cell implementation. The weight-10 T2 trial reached its request budget;
global completion and physical ship safety are not established. M3.1 shared
evaluation and naval baseline capture are complete; the DCS baseline ended its
navigation attempt with a protective stop. M3.2 local naval integration is now
implemented and validated with controlled Lua 5.1 regressions. A fresh DCS naval
run remains required; complete-route integration remains M3.4. The API status
below includes the historical design and milestone decisions. Existing LAZY
searches retain their full-goal contract.

## NAVYGROUP development status (2026-10-09)

The user confirms that both local and global NAVYGROUP pathfinding are still
in development. Neither mode needs compatibility with old mission scripts.
Their public methods, options and internal structure may be redesigned around
the agreed responsibilities, with affected callers, examples, documentation and
tests updated together.

Remove superseded methods, duplicate search logic and obsolete state as each
mode is replaced. Do not retain compatibility aliases, adapter layers or a
legacy planner fallback solely to support earlier development versions.
Reuse existing helpers only where they fit the new design. Depth and hull
safety, steering feasibility and mission/FSM lifecycle remain requirements to
validate; their current implementation is not a design constraint. This decision
does not change the release status of unrelated shared MOOSE APIs.

## Existing implementation

Baseline inspected: `ed0b0b225` with no tracked working-tree changes.

| Area | Existing behavior | Consequence for the design |
| --- | --- | --- |
| `GRID:CreateSparse`, `GetOrCreateCell` | Fixed lattice frame; accepted and filtered positions are cached; all samples count against MaxCells. | Reuse this foundation inside bounded windows. A growing sparse grid is not yet a rolling cache. |
| `ASTAR:StartSearch`, `StepSearch`, `CancelSearch` | Resumable full-goal LAZY search with a heap, node and cooperative CPU budgets, cancellation and configuration checks. | Share the search machinery and work budgeting; add explicit local outcomes. |
| `ASTAR:_SyncGrid` | Imports appended cells; existing node IDs and cached connections remain stable. | Removing cells from a shared grid would invalidate current assumptions. Avoid silent pruning. |
| `NAVYGROUP:_GetLocalNavigationWindow` | Builds a heading-aligned finite hex grid; reuses it under movement, heading and configuration conditions. | Window geometry belongs in GRID; movement and speed policy belongs in the caller. |
| `NAVYGROUP:_GetLocalNavigationCandidates`, `_PlanLocalPath` | Chooses up to eight goal/front/side candidates, then runs separate searches using private `_SearchPath`. | Provide general local candidates without repeated source exploration or private calls. |
| `NAVYGROUP:_SimplifyLocalPath` | Checks depth, weighted shortcut costs, leg lengths, turns and adjusted corners; uses private `_TravelCost`. | Preserve the naval constraints. Expose an appropriate connection-evaluation API instead of copying its internals. |
| `NAVYGROUP:_PrepareLocalRoute`, `_CompleteLocalRoute` | Compares prepared alternatives and can add up to two continuation windows per candidate. | This multiplies search work; measure it separately from route submissions. |
| `NAVYGROUP:_LocalRouteProgress`, `_CheckLocalNavigation` | Tracks adjacent route segments and actual movement; extends or replaces a checked route while respecting holds and tasks. | This is navigation/execution behavior, not a GRID responsibility. |
| `NAVYGROUP:_FindPathToNextWaypoint` | Builds a finite grid, then uses expansion to obtain a complete route. | Rework full-route planning in its own stage; the existing method is not a compatibility requirement. |
| `PATHLINE.CheckDepth`, ASTAR depth helpers | Already provide shared depth/profile checks and costs. | Extend these abstractions where useful rather than adding another naval depth implementation. |

In current local naval planning, the window starts at least 3 km ahead, 1 km
behind and 1 km on either side, with approximately 50 m spacing. Speed can
increase the forward extent to 5.5 km. These are naval defaults, not universal
ASTAR defaults. Boundary candidates follow the geometric window, not a shoreline.

Depth helpers already distinguish some unavailable-data causes. The ASTAR
validity/cost caches currently retain booleans and costs but discard these
reasons. Preserving diagnostic information is needed before a generic local
report can reliably distinguish unavailable depth data from a blocked edge.

Relevant sources: `Moose Development/Moose/Core/{Grid,Astar,Pathline,Vector,Point}.lua`,
`Moose Development/Moose/Ops/NavyGroup.lua`, `tests/{grid,astar,navy-local}.lua`,
and [Local naval navigation](../advanced/navy-local-navigation.md).

## Responsibility boundaries

| Component | Responsibility |
| --- | --- |
| GRID | Lattice geometry, geometric window membership, neighbour indices, surface samples and bounded window lifetime. No target ranking, ship state or movement commands. |
| ASTAR | Bounded local exploration, validated paths to candidate exits, costs, selection diagnostics, work budgets and limited planning history. No owned timer or unit controller. |
| PATHLINE and existing geometry helpers | Reusable polyline measurements or connection checks where these remove duplication. Do not move ship-specific heuristics into a generic geometry class. |
| NAVYGROUP | Actual position/course, speed-dependent horizons, steering feasibility, hull checks, route reserve, when to extend, final candidate selection and DCS submission. Preserve mission tasks and FSM authority. |

The initial local planner remains inside ASTAR with a distinct private session
and shared search helpers. Do not create a second independent A* implementation.
A new public planner class is not required for the first implementation; revisit
that choice only if the implementation demonstrates that ASTAR becomes unwieldy.

## Proposed planning contract

1. The caller supplies a planning start, the overall goal and optionally an
   initial heading. A planning start may be the current position or a future
   anchor at the end of an already checked route.
2. The local request snapshots its window, endpoints and rule configuration.
   The overall goal supplies direction; when it lies outside the window it is
   not sampled as a distant endpoint or assumed reachable.
3. One bounded search explores valid connections inside the window and retains
   alternatives towards geometric boundary sectors. The goal is an exact
   candidate when it lies inside. Every returned connection must pass the
   configured hard rule, including exact endpoint attachments.
4. Return a checked partial path or a checked path all the way to the goal.
   Keep a bounded list of candidate alternatives for callers whose movement
   constraints can reject the preferred raw path.
5. The caller validates movement feasibility and decides which route to install.
   A proposed or rejected candidate does not count as travelled progress.
6. While following that route, the caller reports actual positions and requests
   a continuation sufficiently early. A future planning anchor must never be
   mistaken for the object's actual position or arrival.

Local planning does not guarantee a globally optimal route or escape from every
dead end. A failure confined to one window does not prove global unreachability.
There is no automatic global fallback or automatic reversal in the first version.
Those are caller policies to discuss separately if needed.

## Public interface and remaining proposals

Keep positional inputs short and reuse the existing rule/cost setters. Input
positions accept the established VECTOR/COORDINATE/Vec2/Vec3 forms; units and
copying behavior must be documented. Returned reports may contain named records
because they carry many distinct results.

The request lifecycle was implemented in M2.2; observation and invalidation
methods were added in M2.3. EvaluateConnection was added in M3.1.

| Call | Parameters and purpose |
| --- | --- |
| `ASTAR:SetLocalWindow(Ahead, Width, Behind)` | Three distances in meters. Ahead and total Width are positive; Behind is non-negative. Configure the local extent explicitly for the first release. |
| `ASTAR:StartLocalSearch(Start, Goal, Heading)` | Start one local planning job. Heading is optional degrees; default towards Goal. Coincident endpoints are handled before choosing an orientation. Copy positions. Starting a job cancels a pending one. |
| `ASTAR:StepSearch(MaxNodes, MaxSeconds)` | Reuse the existing two work limits for full LAZY and local jobs. Return `path, report`; a pending nil path is not a failure. Do not change existing full-search results. |
| `ASTAR:CancelSearch()` | Cancel pending work without touching the caller's installed route. Reuse existing behavior. |
| `ASTAR:UpdateLocalProgress(Position)` | Record actual movement independently of the planning start. Needed for rolling-history checks; unnecessary for an isolated local request. No searching, scheduling or route commands. |
| `ASTAR:SetLocalProgress(MinDistance, HistorySize, RepeatLimit)` | Configure observation thresholds with three optional scalars (defaults 10 m, 32 positions, 3 repetitions); resets observations. HistorySize is 4..256, RepeatLimit is 2..HistorySize-1. |
| `ASTAR:ResetLocalProgress()` | Clear actual-position history and diagnostics without changing current search/results. |
| `ASTAR:InvalidateLocalCache()` | Clear learned continuation costs and mark external terrain/callback input changes. Pending work cancels on its next step; the next request uses a fresh window. Completed results stay intact. |
| `ASTAR:EvaluateConnection(Start, Goal)` | Fresh shared rule/cost evaluation for arbitrary positions, returning validity, cost and caller-owned diagnostics. Leaves search state and caches unchanged; distinguishes blocked from unavailable depth data. Checks connection rules, not cell adjacency or turning feasibility. |

Normal usage repeats StartLocalSearch only when a new section is needed, then
calls StepSearch until that job completes. Calling StartLocalSearch on every
tick would discard pending work and is not the intended update loop.

Use the existing GRID resolution, surface filter and cell-limit settings.
Keep window calculations in GRID helpers; add a public GRID method only if it
has a useful standalone contract. Do not expose a large new options table simply
to forward internal state.

An advanced custom candidate-ranking hook may be added if required by a real
caller. Its signature and score units must be reviewed before implementation;
do not introduce it speculatively in the first geometry step.

## Results and ownership

- Preserve `Status = running / complete / cancelled` as the work lifecycle.
  Add a separate local outcome such as `partial_path` or `goal_path`.
- `goal_path` means the returned plan reaches the exact goal. It never means
  the moving object has arrived. Arrival remains the caller's responsibility.
- Distinguish `no_local_exit`, `cell_limit`, `data_unavailable`, cancellation,
  configuration changes and detected repeated planning without progress.
  Only report unavailable data when the rule supplies that evidence; a generic
  boolean callback cannot reveal why it rejected an edge.
- During work, provisional candidates remain internal. Do not silently present
  an unfinished candidate comparison as a completed successful plan at a limit.
  The initial version returns a limit result when the planning budget is exhausted.
- Return bounded candidate records with path, checked cost, length, remaining
  straight-line goal distance, goal inclusion and rejection/limit diagnostics.
  Preserve raw path costs when the navigator evaluates a simplified route.
- Include request/window IDs, configuration revision, expansions, sampled and
  retained cells, cache hits, candidate count and CPU work time. Count future
  route submissions separately in NAVYGROUP.
- Completed results must remain stable when later jobs run. Planning history
  stores compact coordinates/keys, not chains of old ASTAR instances.
- Keep the established node-path representation for search consumers, but offer
  copied position data in local result records for a navigator retaining an older
  route. Node/cell identities are only meaningful in their owning window.
- Document that the active local GRID may change between window generations;
  reacquire it rather than mutating an old reference. Drawing uses the current
  window's path ownership. Old installed route positions survive that change.
  Cancel old drawing jobs before releasing their window.
- Use private local window ownership. Do not prune, rotate or reset a GRID shared
  with another search. Reject unsupported attached-grid configurations explicitly.

## Search and candidate selection

Reuse the heap and resumable work loop for one source exploration rather than
running a complete independent A* search for every exit. The first correctness
baseline may use a zero heuristic to settle costs to all eligible exits in the
bounded reachable window. Benchmark a directed variant later; do not assume
one traversal is automatically faster on every map.

Separate candidate eligibility from ranking. Candidates need a checked connector
and useful movement within the window; boundary membership alone is insufficient.
Retain distinct front/side alternatives, and rear alternatives when geometry
requires them. Heading biases the request but is not a ship-turn constraint.
Choose a small deterministic set, initially up to eight, after evaluating the
window; do not select exits by filtered shoreline shape.

Prefer a checked exact-goal path when one exists within the window. Compare
boundary exits when the goal cannot be connected locally; a blocked in-window
goal does not by itself rule out an exit and a later approach from another side.

For built-in distance/depth costs, BaseScore compares validated travel cost plus
the compatible lower-bound estimate towards the overall goal. Score adds a learned
continuation increase from nearby earlier planning anchors (M2.4 correction below).
This approximate local ranking is not a global lower bound or proof of cheapest total-route cost. Keep length and cost separate. Do not
reuse NAVYGROUP's numeric turn/forward penalties as universal weights.

Custom cost functions have no implied conversion to meters. Their default
heuristic remains zero. Any directional ranking beyond that requires an explicit
contract; do not add Euclidean meters to arbitrary custom-cost units. Validate
this case before exposing a generic ranking callback.

The search budget covers cell sampling, edge checks, candidate processing and
path reconstruction, not only heap pops. Individual external calls remain
non-interruptible. A lack of os.clock leaves the deterministic count limit active;
it must not substitute simulation time for CPU time. No core scheduler is added.

## Window reuse and memory

Use bounded window generations first. Reuse a compatible current window and its
connection caches; replace it when movement, extent or configuration requires a
new one. Keep at most the working window and any still-needed previous result
window internally. Count rejected samples as well as accepted cells.

MaxCells remains the limit for each concrete GRID, as today. Add explicit local
reporting of total retained data so a succession of windows cannot hide unbounded
memory growth. Long-distance travel must not consume a lifetime sample budget and
then stop solely because the object travelled far.

Cross-window sample reuse is a subsequent measured optimization, not a prerequisite
for the first working local planner. Reuse only under identical lattice transforms
and compatible geometry/filter revisions; identical index numbers in rotated
windows do not denote identical world positions. Never copy whole old cell/node
objects into a new owner. A bounded overlap cache needs an explicit eviction rule.

Depth/rule changes invalidate affected edge results. Dynamic external state inside
a callback requires explicit invalidation or a new request. Missing-data failures
must not become permanent terrain blocks. Live naval safety checks remain fresh
even when a planning cache can be reused.

## Progress and dead ends

Store a bounded history of actual positions and coarse directed transitions.
Use tolerances to ignore position noise and record only meaningful movement.
Planning from a future anchor or choosing a candidate must not advance history.
Separate lack of observed movement from repeated movement through the same loop.

Increasing distance from the goal is permitted: U-shaped obstacles and side exits
can require it. Do not define progress solely as decreasing Euclidean goal
distance. Use history to diagnose repeated exits/loops without new useful progress;
do not convert a visited cell into an impassable terrain cell.

On a detected cycle or exhausted local alternatives, return an explicit report
for the caller. Avoid repeated identical planning on every tick. The first
version neither commands reverse movement nor silently escalates to a full search.
The navigator may keep its still-checked route while preparing a replacement and
must decide when its usable reserve requires stopping.

## Naval integration sequence

1. Configure ASTAR with the current naval depth/corridor rules and speed-based
   window extent. Replace candidate generation/search through the new public API.
2. Feed candidate paths into naval steering and route-preparation checks,
   revising their structure where needed rather than retaining obsolete methods.
   A raw ASTAR path may be rejected; keep other alternatives available. Reprice
   changed geometry and revalidate the route from the actual ship before submission.
3. Preserve the common installed prefix, pending continuation and original target.
   Future planning anchors and actual movement observations remain distinct.
4. Keep the two-second hull/lookahead check, ten-second navigation behavior,
   turn handling, route reserve, Holding/Waiting, explicit GotoWaypoint commands,
   patrol wrap and queued task semantics. Early DCS callbacks do not prove arrival.
5. Define a planning-job generation before making naval searches asynchronous.
   Stop, retarget, mode switch, destruction and configuration changes cancel stale
   results. Choose tick interval/reserve together so work budgeting does not cause
   the checked route to run out while the ship is moving.
6. Optimize complete WAYPOINT planning as a separate step. Compare the existing
   expanding corridor with full-goal LAZY on identical inputs. Keep the strategy
   that meets correctness and measured cost for the case; do not switch defaults
   based only on screenshots or fewer allocated cells.

## Milestones and acceptance

### M1 Concept review

- [x] Inspect existing local, full and LAZY planning and downstream callers.
- [x] Separate reusable search work from ship execution and safety rules.
- [x] Record the API draft, ownership, limits, risks and migration sequence.
- [x] User approves the first implementation scope below.

### M2 General local planner

- [x] M2.1 Add bounded window geometry in GRID, using sparse generation and
  preserving existing modes. Test rotated rectangles, hexagons, front/side/rear
  boundaries, outside-window samples and budget accounting. Specify window
  ownership and configuration copying before adding a rolling lifecycle.
- [x] M2.2 Add StartLocalSearch and shared StepSearch dispatch, candidate exploration,
  exact-goal and partial-path results. Cover endpoint validity, independent paths,
  deterministic ordering, custom costs, cancellation and configuration changes.
- [x] M2.3 Bound generations and result lifetime, add actual-progress observations,
  and test several window transitions, long journeys, detours away from the goal,
  loop detection, missing data and memory limits. Confirm inactive results remain stable.
- [x] M2.4 Provide small DCS scripts for standalone local planning. First move a
  simulated planning position along validated points; then check real terrain
  without changing ship behavior. Log each request and transition directly.

Acceptance: checked sections lead through deterministic multi-window scenarios;
limits and lack of local continuation have honest outcomes; no timer/controller
side effects; old FIXED/EXPAND/LAZY behavior remains covered. A point-following
test is not validation of DCS ship physics.

### M3 Naval integration and optimization

- [x] M3.1 Expose shared connection evaluation with preserved failure evidence.
  Establish a naval baseline of searches, profile calls, cache hits, submitted
  routes, peak retained cells and total/worst-update CPU time.
- [x] M3.2 Integrate shared local planning with a coherent NAVYGROUP interface
  and lifecycle. Validate steering/safety/task requirements; remove superseded
  methods, state and private-method calls without compatibility scaffolding.
- [ ] M3.3 Test continuation, replacement and asynchronous ownership under turns,
  speed changes, retargeting, holds, patrol returns and failed candidate preparation.
- [ ] M3.4 Benchmark and rework complete-route planning separately, removing
  superseded global-search code. Consider overlap caching or shared polyline
  helpers only where measurements justify them.
- [ ] M3.5 Run DCS sea/canal/turn/dead-end trials, including return journeys;
  compare planned points with actual course and movement. Update user documentation.

Acceptance: no loss of the existing safety and mission lifecycle checks; fewer
repeated operations or lower measured work on comparable cases; no claim that
profiler percentages equal FPS gains. Both NAVYGROUP search modes are unreleased
and may be redesigned without old-script compatibility. Changes to unrelated
released APIs still require an individual decision.

## M2.1 implementation and validation

The internal factory `GRID:_NewSparseWindow(Origin, Heading, Ahead, Width, Behind)`
returns a new GRID with copied configuration and surface filters. The source may
be unbuilt, a regular built grid or an older window. No cells, rejected samples,
drawings or mutable ownership state are shared. Origin is copied; Heading is
normalized in degrees. Ahead and full Width must be positive meters; Behind may
be zero. Each frame remains fixed for that instance.

`GRID:_IsInsideWindow(Position)` checks the oriented horizontal rectangle,
including boundaries. `GetOrCreateCell` rejects outside centers with
`nil, "outside_window"` before sampling, budget checks or cache changes. Cell
outlines can cross the boundary; membership is not a traversability check.
Filtered inside samples still consume MaxCells. Automatic resolution uses the
shorter of Ahead+Behind and Width; manual spacing and rectangular cross spacing
are copied. Corridor settings do not determine window dimensions.

The helpers remain private pending the ASTAR local lifecycle. `CreateSparse`
still creates an unbounded lattice. No public configuration table, planner
lifecycle, timer, cache eviction or NAVYGROUP behavior was added in M2.1.

Validation on 2026-10-05: Lua 5.1 compilation of the changed production/test
files and separate-process suites passed: GRID 103, ASTAR 225, navy-local 134
(462 total). Nine new GRID cases cover rotated boundaries, rectangle/hex sampling,
outside and filtered budget accounting, copied settings and ownership, automatic
resolution, invalid inputs, surface-filter distinctions and unbounded compatibility.
A long/narrow-window tolerance case failed before its correction and passed
afterwards. Existing suites cover FIXED, EXPAND and LAZY behavior. These are
controlled dependency tests; no new DCS mission validation has been performed.

## M2.2 implementation and validation

`SetLocalWindow(Ahead, Width, Behind)` and `StartLocalSearch(Start, Goal, Heading)`
are implemented. `StepSearch` and `CancelSearch` handle both LOCAL and LAZY jobs.
LOCAL reuses the existing heap, sparse neighbour generation, validity/cost caches
and relaxation loop. A zero exploration heuristic settles costs once per request.
Geometric frontier cells are classified by GRID into eight heading-relative
sectors. Each sector retains the best candidate by checked cost plus the existing
compatible goal heuristic, with node-ID ties. Custom and road costs add zero;
there is no implicit conversion between meters and custom cost units.

Reaching an exact in-window goal takes priority and returns one `goal_path`
candidate. Otherwise the request completes with up to eight `partial_path`
candidates, or `no_local_exit`. Surface-rejected or unattached in-window goals
can still produce a partial exit. Distant goals are never sampled as endpoints.
Cell limits return no provisional path or candidate list, with no claim of global
unreachability. Each published candidate has Path, copied Vec3 Positions, Cost,
Score, horizontal Length/RemainingDistance, ReachesGoal and an optional Sector.

LOCAL counts initialization, neighbour batches, edge processing, selection and
incremental path reconstruction/copying against StepSearch's work limit as well
as its cooperative CPU budget. Reports include request/window IDs, window geometry,
sample/retention counts, expanded nodes, work items and cache-hit counts. No timer
or DCS controller is owned by the planner. At the M2.2 milestone, each request built a fresh
owned window and clears old owned drawings; supplied shared/prebuilt non-local
grids and manual nodes are rejected before replacing pending work. Full-goal LAZY
uses a separate ASTAR instance. Progress observation and compatible-window reuse
were deferred to M2.3, together with diagnostic preservation for missing depth data.

Validation on 2026-10-05: Lua 5.1 compilation and separate-process suites passed:
GRID 104, ASTAR 243, navy-local 134 (481 total). The 18 new ASTAR cases and one GRID
case cover both lattices, rotated geometry, sector boundaries versus filtered
terrain, exact/3D/coincident endpoints, custom/zero/infinite costs, fixed-search
cost comparisons, depth rules, hard budgets, CPU slices, no-clock execution,
cancellation/reentrant callbacks, configuration changes, result ownership,
drawing cleanup and deterministic ordering across slice sizes. Existing
FIXED/EXPAND/LAZY and naval regressions remain green. No DCS mission or performance
benchmark has been run for M2.2; stubbed terrain tests do not validate ship motion.

## M2.3 implementation and validation

Compatible requests now retain the fixed GRID frame, sampled cells and rejected
surface samples. Reuse requires unchanged configuration/rules, a heading within
10 degrees of the original window, and an anchor in the conservative inner core:
along `[-Behind/4, Ahead/4]`, across `[-Width/8, Width/8]`. WindowID changes only
on replacement; PlanningStart and Window.Origin are reported separately. The
full geometric membership rule is unchanged. No shared grid is moved or pruned.

Each request owns a new node/cache view. Known built-in validity/cost pairs copy
cell-to-cell results; exact endpoint results and custom callback results are
rechecked. Custom callbacks may depend on node identity, which changes between
requests. Reapply setters when changing rule/cost arguments, and call
InvalidateLocalCache for changes in external terrain or hidden callback state.
Its revision also prevents resuming outdated pending work.

Restoration proceeds one node or cache entry at a time under StepSearch budgets.
Public synchronous drawing/query calls between steps may import the remaining
nodes directly; they advance the restoration state without duplicate nodes or
spurious cancellation. ClearDrawing performs no unnecessary node import.
Internally at most one window and the current plus temporary previous node view
are retained. Endpoint nodes do not accumulate. Completing/cancelling restoration
releases its source. Caller-held results deliberately keep their own nodes/window
alive; dropping these references permits collection. Reports and copied route
positions remain stable. MaxCells bounds samples including filtered cells.

UpdateLocalProgress copies actual horizontal positions and ignores displacement
below MinDistance relative to the last accepted point. At most HistorySize
positions are retained. Accepted movement resets repeated-planning counts, even
when moving away from the goal. Repeated directed transitions within MinDistance/2
of prior endpoints diagnose a possible loop. Longer loops need sufficient history;
this is a heuristic, not a completeness or dead-end escape guarantee. A changed
overall goal resets goal-specific diagnostics and retains only the latest actual
position. Future planning anchors never add observations or travelled distance.

Repeated-planning counts apply only to completed partial requests near the last
actual observation, without accepted movement during the request. Cancelled jobs,
future anchors and goal paths do not increase the count. Diagnostics appear as
Progress.Status (`unobserved`, `observed`, `repeated_planning`, `loop_detected`).
The default chosen for M2.3 is advisory; it does not block subsequent requests or
infer a physical standstill from elapsed time. Actual arrival remains a caller decision.

Built-in depth evaluation now preserves `clear`, `blocked` and `unavailable`.
Unavailable edges are never cached as permanent obstructions or infinite costs.
Reports count distinct undirected unavailable edges by cause and copy the first
affected connection. With no checked exit, this yields `data_unavailable` with no
proven FailureReason. Checked alternatives may still produce a valid path with
DataIncomplete=true. Limits/cancellation keep their own termination reason;
generic boolean callbacks cannot supply missing-depth evidence.

Validation on 2026-10-06: Lua 5.1.5 compilation and separate-process suites passed:
GRID 105, ASTAR 260, navy-local 134, depth 27 (526 total). Coverage includes
warm/cold windows, off-lattice endpoint cache remapping, custom node-dependent
callbacks, cancellation during restoration, external invalidation, missing-data
recovery, repeated planning, actual loops, away-from-goal motion, goal changes,
35 window replacements per geometry, weak-reference collection of inactive
windows, and consecutive selected paths to an exact distant goal. A focused
missing-data regression fails against the pre-M2.3 source and passes after the fix.

A small comparable stub benchmark used three identical hex-window depth requests:
before reuse, each request made 113 new cell samples and 296 profile queries;
afterward only the first did, with zero new samples/profile queries on requests
two and three. Observed coarse CPU times were about 6 ms each before, and 7/3/3 ms
after. These timings include synthetic terrain and do not establish simulator
performance or FPS. Benchmark/probe files remain in the task-specific temporary
directory outside the patch. No M2.3 DCS validation has been performed.

## Validation and next implementation approval

M2.4 preparation on 2026-10-08: three pasteable mission examples are ready outside
the source patch. T1 follows local rectangular paths with a virtual position and
no terrain rules. T2 follows depth-checked hex paths, with center-depth coloring.
T3 checks eight deterministic lifecycle/cache/progress cases without terrain rules.
All three compile under Lua 5.1.5 and finish in a controlled timer/terrain harness;
T2 also completes with a synthetic shoal forcing a detour. Map rendering and real
DCS behavior are not validated by that harness. Subsequent DCS runs passed T1
and reproduced a T2 request-limit stop twice, the second with candidate diagnostics.
Checkpoints, source hashes and byte-preserving logs remain outside the repository.
The recurring monitor was deleted; inspection now starts on the user's signal.
Keep M2.4 open for the corrected T2 rerun and T3. Preparation itself did not change
production classes; the approved T2 correction is described below.

Use Lua 5.1 syntax checks and separate processes for the affected suites. The
initial implementation touches GRID/ASTAR and their focused tests. Naval stages
also run `navy-local` and relevant depth/pathline/waypoint suites when their
dependencies change. Keep measured performance and DCS run snapshots outside the
source tree. Do not rerun unrelated tests for a documentation-only plan.

M2.4 standalone validation is complete for T1, T2 at weight 1 and T3 on the
current sources. The weight-10 request-budget result remains a documented
limitation. **M3.1** was approved and its connection API and opt-in measurement
implementation are complete, and the DCS naval baseline has been captured before
M3.2 integration. Its protective stop is a reproduction case for route management,
not a successful voyage. No naval production code was changed in M2.3/M2.4.

## M2.4 rolling-selection correction (2026-10-08)

User approved a deterministic reproduction of the drifting T2 cycle and a
general ASTAR selection correction. T1 passed in DCS; both T2 runs stopped at
80 requests without reaching the goal; T3 remains pending. The diagnostic T2
run had a valid forward candidate in every window, but depth-weighted local
cost plus straight-line remainder repeatedly preferred rear/side exits. One
three-request cycle travelled 5200 m and returned within 38 m of its start,
36 m farther from the goal. Raw evidence is retained outside the source tree.

Approach: retain bounded local continuation-cost estimates across compatible
requests. Match nearby positions at the lattice scale to tolerate window drift.
Keep physical edge/path costs, hard validity rules, and exact-goal preference
unchanged. Learned scores remain a local policy, not a global optimality claim;
rear detours must remain available. Reset estimates on goal, rule, geometry or
external-data changes. Cancelled, limited or incomplete-data requests must not
commit estimates. Keep observation diagnostics separate from planning history.

- [x] Reproduce the depth-weighted rolling failure against the saved pre-fix source.
- [x] Implement bounded continuation learning with explicit score diagnostics.
- [x] Verify drift, necessary retreat, units, invalidation, budgets and ownership.
- [x] Run Lua 5.1 compilation and affected suites; review the incremental diff.
- [ ] Repeat T2 in DCS after the user starts the updated mission; then run T3.

The heartbeat monitor was deleted at the user's request. Inspect the log only
after a mission-start notification or a direct request; do not recreate automation.

Initial implementation (superseded by stable-cell learning below): retain at most
128 copied planning-anchor positions and cost
estimates. An exit uses the maximum compatible base estimate and nearby learned
estimates within half the smaller grid spacing (3D matching for Dist3D, horizontal
otherwise). A successful, complete-data partial request backs up its best Score to
its planning anchor, taking the maximum of the existing estimate and the new one.
Nearby anchors merge; least recently updated entries are evicted when full. No
node, path or old window is retained. The search's Dijkstra costs remain physical
connection costs. Reports expose BaseScore/LearnedPenalty and learning count,
matching radius and update status. Movement observations are independent.

The analytic canal regression uses 400 m hex spacing, a 6000/4000/1500 m window,
3.5 m minimum/15 m preferred depth and weight 10. A navigable 11 m shoal creates
cheaper rear/side choices. The saved source fails to reach the exact goal within
80 requests; the correction reaches it in 20. This is a synthetic reproduction
of the decision failure, not a replay of DCS bathymetry. A stronger 8 m synthetic
barrier still did not complete within 80 requests during exploration; bounded
local learning does not guarantee global escape or completion within that limit.

Validation: Lua 5.1.5 compiles the changed source, test suite and mission driver.
Separate-process suites pass: ASTAR 266, GRID 105, navy-local 134, depth 27
(532 total). The six new tests fail against the saved pre-fix source, including
the 80-request cycle regression; all 260 earlier ASTAR tests still pass there.
Coverage includes a shifted penalized rear exit with work slices 1/7/1000,
custom cost units, actual-observation separation, goal/rule/configuration/cache
reset, cancellation during path copying, cell limits, incomplete depth data,
immutable old reports and 132 requests retaining at most 128 estimates without
retaining old grids. T2 diagnostics now include the score decomposition and
learning state under marker `diagnostics=candidates-v2`; normal/shoal T2 and all
eight T3 checks pass in the controlled example harness. `git diff --check` passes
for the MOOSE checkout. Subsequent DCS evidence and the approved replacement are recorded below.


## M2.4 stable-cell continuation learning (2026-10-08)

The point-anchor implementation was tested in DCS with identical production
sources. Weight 10 stopped at 200 requests (396.8 km virtual path, 56.8 km
remaining, 14.773 s reported search CPU); weight 1 reached the exact goal in
35 requests (119.1 km virtual path, 1.583 s reported search CPU). All 200 weight-10
planning anchors were more than the 200 m matching radius apart. This supports
replacing spatial point matching; it does not establish simulator safety or a
universal failure threshold for depth weights. Raw evidence stays in temporary
run archives. T3 and current-source T1 remain pending.

Approved scope: decouple the moving/rotating window mask from a fixed session
lattice in GRID, then propagate continuation costs across the explored local
graph in ASTAR. Retain compact per-cell scalar estimates only. Use every reachable
geometric frontier cell as a seed and checked directed connections for reverse
Dijkstra propagation. This is a bounded local-learning policy inspired by local
search-space heuristic learning, not a global completeness/optimality guarantee.
Keep hard depth/corridor validity and physical path cost unchanged. No NAVYGROUP
controller integration or simulator control is included.

- [x] Preserve fixed lattice indices/world centers across compatible window moves.
- [x] Implement cooperative clone/seed/propagation/storage phases and atomic commit.
- [x] Add a separate cell-memory bound: SetLocalLearningLimit, default 4096,
      zero disables learning, FIFO eviction on capacity; reset on changed inputs.
- [x] Validate shallow valid passage at weights 1/10, directed edges, real dead end,
      cancellation in every learning phase, memory limits and old-result ownership.
- [x] Update T2 diagnostics and remove the hardcoded weight from its BEGIN marker.
- [x] Run Lua 5.1 compilation, affected suites and final diff review.
- [x] Test the new sources in DCS at weight 10 and compare weight 1.
- [x] Run all eight T3 checks in DCS on the current sources.
- [x] Repeat T1 in DCS on the current sources.

Cancelled, limited and incomplete-data requests cannot commit memory. Each clone,
seed, relaxation and stored cell counts against StepSearch work and CPU budgets.
The final swap publishes memory together with copied results. Memory stores no old
cell, node or window references. Learned cells remain tied to the stable lattice;
goal, cost, rule, grid configuration or explicit cache invalidation resets them.


Validation completed with Lua 5.1.5: ASTAR 270, GRID 106, navy-local 134,
depth 27 and pathline 11 (548 passing checks, separate processes). Changed
sources/tests and the mission driver compile. The controlled T1, T2 (weights 1
and 10), T2 with an impassable shoal and T3 example harnesses pass. These harnesses
use stubs and do not validate DCS terrain or controllers.

The stronger analytic 8 m shoal completes in 4 requests at weight 1 and 64 at
weight 10. The saved point-learning ASTAR source does not finish within 80 requests
at weight 10. The new directed-corridor test checks numerical estimates for every
explored cell; the dead-end regression requires retreat through a side passage.
Cancellation after partial clone/seed/propagation/storage and before publication
preserves the preceding memory, including with no CPU clock and one work item per
slice. FIFO memory/index bounds and old-window collection also pass. The saved
GRID source fails the new moved/rotated-window geometry regression.

T2 is prepared with depthWeight=10, learning limit 4096 and the existing 200-request
budget. BEGIN now logs the actual parameter, with diagnostics=candidates-v3;
learning count, update count, work and slices are logged for comparison. Source
hashes and pre-change backups are recorded in the temporary checkpoint. The subsequent DCS result is recorded below. Further log inspection follows the
user's mission-start notification or direct request; no recurring monitor is installed.


DCS validation of the stable-cell implementation: T2 at depth weight 10 stopped
at the existing 200-request limit, with no exact-goal marker. Dynamic loader
messages, the verified source junction, prepared SHA256 values and pre-load file
modification times identify the new sources. All 200 results were partial paths;
376.0 km of virtual route ended 90.426 km from the goal. The best selected endpoint
was 55.126 km away at request 19, followed by repeated retreats. The previous
point-learning weight-10 run ended 56.757 km away at the same request budget.

The stable lattice is consistent across all 1455 logged candidate endpoints
within log rounding precision. Learning is active: 978 candidates carry a positive
learned penalty; it changes the winner among published alternatives in 174
requests, 94 of them selecting a backward endpoint. The 3247/4096 memory usage
excludes eviction as the cause. No missing-depth edges, Lua errors, cell-limit or
slice-limit stop was logged (45..219 sampled cells, at most 77 slices/request).
Reported search CPU totals 16.031 s, maximum 0.196 s/request; this includes sliced
learning and is not a single-frame duration. Simulation acceleration is not
quantified by these logs.

Outcome: the implementation passes controlled regressions but has not solved
the DCS weight-10 case. Investigate the local continuation policy and the retreat
sequence before another implementation change. No additional code change was
made during observation. New-source T1/T3 and the weight-1 comparison are still
pending. Raw logs, mission/script/source snapshots and detailed analysis remain
in the task-specific temporary checkpoint.


Assessment refined after the user's visual observation: the user saw exploration
of distinct alternatives at the shallow passage, without the former pointless
back-and-forth motion. Logged planning endpoints support this distinction:
191 distinct cells among 201 anchors/endpoints, 10 revisits, only two repeated
directed endpoint transitions, and no immediate A-B-A endpoint reversal. The
interior points of each selected route are not logged, so this is not proof that
all physical/virtual path segments were unique.

The exact-goal criterion still was not met within 200 requests; that budget result
alone is not an algorithm-defect diagnosis. With minimum depth 3.5 m, preferred
15 m and weight 10, a uniformly 8 m deep checked corridor costs about 4.705 times
its distance, reaching factor 11 at the minimum depth. Unseen alternatives can
therefore remain attractive to a local planner. The 94 backward winner changes
reflect learned total continuation costs, not isolated proof of a depth-cost bug.
Recommend a weight-1 comparison using the same stable-cell sources and otherwise
identical settings before further algorithm changes. This recommendation has not
changed the mission script or production code.


DCS weight-1 comparison on the same stable-cell sources completed successfully:
`PASS: virtual position reached the exact goal` after 32 requests (31 partial,
one goal path), 119.811 km virtual route and 0 m remaining. Reported search CPU
was 1.692 s in total, maximum 0.109 s/request. There were no missing-depth edges,
Lua errors or cell/slice/request-limit stops. Sampled cells were 119..219 per
request, at most 70 slices; retained learning memory reached 3379/4096 cells.

Source hashes match the preceding weight-10 run. A byte comparison of the mission
script confirms that only `local depthWeight = 10` changed to `1`; the edited file
predates loading and BEGIN correctly reports weight 1. The same scenario at
weight 10 reached its 200-request budget with 376 km travelled and 90.426 km left.
This comparison supports the cost-preference/local-exploration interpretation.
It validates T2 virtual point following for this source/configuration, not physical
ship motion or safety. T1 on the current sources and T3 remain pending. Current
mission end has not been observed; the previous weight-10 mission was explicitly
ended and its raw log has been archived through the end marker.


DCS T3 on the same stable-cell sources passed all eight cases: cold, reuse,
repeated_planning, cancel, retarget, invalidate, cell_limit and loop. The final
`PASS: all 8 checks` marker confirms completion. Cancellation, the deliberate
cell limit, repeated planning and synthetic loop detection produced their
expected results. Each case also checked that the earlier report stayed intact.
No Lua error was logged. T3 does not report per-case CPU or slice counts.

Dynamic-load messages, resolved source paths, matching prepared hashes and
pre-load modification times identify the current ASTAR/GRID version. The mission
references the external driver with testcase=3; its T3 body matches the reference
script apart from line endings. Raw logs and mission/script/source snapshots are
saved outside the repository. The preceding weight-1 T2 mission explicitly ended
and was archived through its end marker; no T3 mission end has been observed.
T2 at weight 1 and T3 are now validated on this version; current-source T1 remains
the next simulator check. No production code or mission settings were changed.


DCS T1 on the same stable-cell sources reached the exact virtual goal after
32 requests (31 partial paths and one goal path), confirmed by
`PASS: virtual position reached the exact goal`. Each request used a new window;
sampled cells ranged from 122 to 144. Reported search CPU totals 0.631 s, with a
maximum of 0.050 s/request over its slices, not a single-frame measurement.
No Lua errors or cell/slice/request-limit stops were logged. T1 exercises rectangle
geometry and virtual point following without terrain or depth rules.

The loaded source paths, hashes and pre-load timestamps match the successful T2
weight-1 and T3 runs. The mission selected testcase=1 with unchanged T1 parameters;
its only reference-script adaptation uses the same pre-resolved start/goal zones.
Both the preceding T3 mission and this T1 mission explicitly ended. Their raw logs
are archived through the end markers; source/script/mission evidence and the
checkpoint remain outside the repository.

All three standalone tests now have their required success markers on the current
version. M2.4 is complete for this tested scope, with T2 weight 1 as the successful
terrain configuration and the weight-10 request-limit outcome retained. This does
not establish global route completeness or DCS vessel motion/safety. M3 remains
separate work requiring an agreed scope; no recurring monitor is active.


## M3.1 shared evaluation and naval baseline (2026-10-09)

Approved scope: add ASTAR:EvaluateConnection(Start, Goal) and opt-in NAVYGROUP
measurement without changing candidate selection, steering, safety or task behavior.
The connection API returns validity, cost and an independent report. It evaluates
fresh position snapshots without touching search nodes, caches or pending jobs.
Depth checks retain blocked versus unavailable status and first-rejection evidence;
custom rules/costs preserve callback arguments and errors.

Naval diagnostics measure synchronous navigation/planning/route-update scopes.
Collect actual depth-profile calls through a shared PATHLINE query counter, search
attempts, validity/cost cache requests and hits, route submissions and observed
retained grid cells. Timing is coarse CPU, unavailable without os.clock; nested
scopes must not double-count the aggregate. Retained-cell counts are sampled
ownership counts, not heap measurements. Diagnostics are disabled by default.

- [x] Implement and test fresh connection evaluation and depth evidence.
- [x] Add opt-in naval counters, isolated snapshots and coarse scoped timing.
- [x] Run controlled naval baseline with diagnostics on/off and unchanged routes.
- [x] Compile with Lua 5.1.5, run affected regressions and review the final diff.
- [x] Capture a DCS naval baseline after the user's mission-start signal.

At baseline capture M3.2 was not yet integrated. Source identity, raw bytes,
mission configuration and measurements are saved outside the repository; no
simulator control or recurring monitor was added.

Offline comparison uses a controlled 20 km LOCAL target, uniform 10 m water,
minimum depth 3.5 m, corridor 50 m, preferred depth 15 m and weight 10, ship
speed 10 m/s. The original three production files from commit 985012356 and
new diagnostics off/on produce identical submitted route tables and terrain
work: 8 candidate attempts, 35,047 profiles, 196,268 direct seabed queries,
and one route command. Diagnostics observe 3,783 accepted cells, 109,930 of
120,918 validity requests served from cache, and 61,397 of 61,397 cost requests
served from cache. Combined validity/cost evaluation explains the latter;
it is not evidence of zero depth-cost computation. One isolated comparison
measured 0.613 / 0.606 / 0.656 CPU seconds (original / off / on); this single
sample is not a performance improvement claim or a DCS frame-time result.

The deterministic additions cover independent connection reports, searches
between slices, shared depth queries, unavailable/malformed samples, original
travel-direction evidence, custom callback arguments/errors, invalid/overflow
costs and callback reconfiguration. Naval coverage compares route and query
identity, waypoint and local counters, frozen/caller-owned intervals, nested
CPU accounting, unavailable clocks, exception cleanup and retained-grid
identity. The original ASTAR passes its 270 older cases and fails all 10 new
API cases; the original NAVYGROUP fails all 7 new diagnostics cases.
Final Lua 5.1.5 results: ASTAR 280, GRID 106, depth 27, PATHLINE 11 and
navy-local 141 passed (565 total, zero failures). Changed production/test Lua
files compile; git diff --check is clean.

Temporary source snapshots, hashes, raw baseline output and harnesses stay
outside the source tree. The DCS baseline loaded the changed sources and enabled
SetPathfindingDiagnostics(true); its explicit diagnostic snapshot was captured.
No ship behavior or full-route planning optimization is inferred from the
controlled terrain comparison above.

## M3.2 preparation: continuation and route ownership (2026-10-09)

The DCS baseline reached a protective stop after continuation searches failed
steering constraints. A Lua 5.1.5 policy replay using the logged final route,
rounded-corner position and heading reproduces the stop with production route
preparation, progress and failure methods. The failed continuation is supplied
as an observed input; terrain and DCS motion are not reproduced. Both controlled
depth-weight variants pass the replay assertions. This does not explain the
original path choice or prove that depth weighting was irrelevant to it.

The replay exposes a preparation gap to address during integration: total route
length includes a retained approach, so it does not establish a usable continuation
beyond a later turn. Do not simply relax steering limits or remove the stop reserve.

- Replace naval window/candidate search with the public ASTAR local request API;
  keep generic exploration and learning in ASTAR and window geometry in GRID.
- Separate actual ship progress, the installed route, future planning anchors and
  pending results. Validate manoeuvrability and useful continuation beyond retained
  segments before committing a replacement, with bounded work and explicit failure.
- Give planning jobs an owner/generation and work budget. Retargeting, holds,
  destruction and configuration changes must prevent stale results from submitting
  routes; live hull/depth checks and safe stopping continue during planning.
- Replace naval private ASTAR calls with EvaluateConnection, price the submitted
  geometry, remove superseded local methods/state, and update callers and tests.
- Add deterministic coverage for retained approaches followed by a short turning
  exit, alongside successful continuations and mission/task lifecycle cases.

Complete-route planning remains M3.4. Both naval modes may be redesigned without
compatibility with earlier scripts; the sequencing is for bounded implementation
and validation, not a requirement to retain the old architecture.


## M3.2 local integration and validation (2026-10-09)

NAVYGROUP LOCAL now owns a persistent public ASTAR local planner and a cooperative
job with copied route geometry. Superseded naval window/candidate/search/preflight
methods and private ASTAR calls are removed. The complete-route mode remains a
separate M3.4 step; no legacy local implementation is retained as a fallback.

The caller advances work every 0.1 simulation seconds. Default per-update limits
are 512 work items and 0.005 CPU seconds, with 2000 updates per job. These are
cooperative limits, not an atomic-query or whole-frame time guarantee. Fresh hull
and local-route safety checks retain their two-second cadence; ordinary route
checks retain ten seconds. Only complete proposals can issue route commands.

All primary exits are steered, repriced and checked for useful suffix length and
reserve after future turns. Already usable primary routes have priority; within
that group the actual steering cost and ASTAR learned ranking select the route.
Only when none survives fresh final validation are short exits extended in rank
order, with at most two isolated, learning-disabled probes per exit and 17 total
requests. The first fully usable preparation is accepted; this does not promise
the cheapest route among every possible extended alternative. Final submitted
geometry is checked and repriced from the actual position.

Initial planning may retain a straight native approach to a future anchor, so
movement during calculation does not immediately invalidate a short side exit.
Its entire geometry is checked before graph exploration. A known blocked optional
approach is discarded and the same public local pipeline starts at the job's
actual start snapshot; missing data remains an explicit failure. The retained
approach never contributes to the required new suffix. Contiguous passed initial
points can be trimmed; new connectors, corners and turn-exit reserves are checked
again. These allowances are not a DCS braking or turning model.

Generation/command/route/configuration/destination snapshots prevent publication
or arrival callbacks after holds, task changes, retargeting, in-place waypoint
edits or cancellation. Speculative future anchors never count as actual progress.
A failed continuation retains a freshly checked installed route, permits a bounded
actual-position replacement and waits for progress before another attempt. An
exhausted reserve or unavailable/blocked installed route still causes FullStop.

Validation:

- Lua 5.1.5: ASTAR 280, GRID 106, depth 27, PATHLINE 11 and waypoints 16 passed.
- NAVYGROUP: 117 distinct cases passed: one full 116-case run followed by the
  newly added continuation-failure case and three existing failure cases after
  final diagnostic wiring. Obsolete private-planner fixtures were replaced by
  public-planner, geometry and lifecycle checks.
- New regressions include the logged short turning suffix, a new short turn exit
  caused by live reattachment, stale callbacks/results, unchanged manual/task
  authority, bounded limits, actual versus speculative movement, isolated result
  geometry, safe failed-continuation handling and moving initial/continuation jobs.
- All changed Lua production/test files compile; git diff --check is clean.

The fixed-work, uniform-10-m comparison uses the same 20-km goal, 10 m/s ship,
3.5-m minimum, 50-m corridor, preferred 15 m and weight 10 as M3.1. It now uses
one local request, 34,136 profiles and 186,978 direct seabed queries, versus eight
old candidate attempts, 35,047 profiles and 196,268 queries. These request counters
have different meanings; profile/sample counts measure the comparable terrain
work. Diagnostics enabled/disabled produce identical routes and query counts.
One final sample measured 0.604 CPU seconds; this is not an FPS claim.

With the default work and CPU budgets and a continuously moved test position,
the initial route was published after 175 slices / 17.5 simulation seconds, with
3575 m still available. A continuation needed 211 slices and was published at
96.1 simulated seconds overall, with 5789 m available. Both used one request;
no protective stop occurred. Separate runs vary with CPU scheduling. Earlier
integration drafts that explored every speculative continuation or ranked short
unusable exits before usable primary routes were substantially slower; they are
not the implementation being submitted for DCS testing.

Controlled tests do not validate DCS physics, bathymetry or controller acceptance.
M3.3 broader stress coverage and M3.5 simulator trials remain separate. The next
simulator check is the same Qeshm testcase 55, loading the new sources in a fresh
mission with unchanged baseline depth settings. Inspect its log only after the
user announces mission start. Source snapshots, hashes, detailed output and run
history remain in the task-specific temporary directory; no recurring monitor
or simulator control was added.


## M3.2 follow-up: planning continuity (2026-10-09)

The first integrated Qeshm testcase 55 run loaded the prepared sources and used
minimum depth 3.5 m, preferred depth 15 m, weight 10 and 26 knots. Three local
routes were submitted, then a second activation stopped with
`local_planning_reserve`. Seven completed ASTAR requests did not produce another
submitted naval route. No Lua error was logged. The exact aborted job phase and
restart reasons were not recorded; CPU metrics were not requested in that run.
Raw mission and source evidence remain outside the repository.

The user approved improving this regression. A strict comparison against the
job's instantaneous initial velocity can discard work on every small speed rise.
This is a reproducible code defect, but its contribution to this DCS failure
remains a hypothesis until lifecycle diagnostics are available.

- [x] Reproduce velocity fluctuation starvation with production planning methods.
- [x] Plan against one conservative speed bound; retain jobs within that bound,
      invalidate larger speed increases, and keep final safety checks.
- [x] Record bounded job outcomes, phases, rejection reasons and distinct
      simulation/CPU timings before cancellation or protective stopping.
- [x] Assess activation lead time without weakening depth or stopping reserves.
- [x] Validate focused Lua 5.1 regressions and update the simulator test guidance.

No automatic speed reduction, simulator control or recurring log monitor is
part of this change. The next DCS run must load the changed sources anew.

Implemented a fixed job speed bound of `max(commanded, actual) + max(0.5 m/s,
5%)`. Preparation and final steering/turn checks use this bound; actual-speed
safety checks and the requested route speed remain intact. Acceleration beyond
the bound invalidates running and ready work with `speed_exceeded`. A completed
plan carries its `PlanningSpeed` through final preparation.

Opt-in LOCAL diagnostics now emit one outcome (three short lines) when a job is
submitted, cancelled or fails. The scalar report retains its ID, phase,
request/candidate/extension counts, work/slices, last rejection and planned/actual
speeds. Elapsed simulation time includes waiting; CPU time counts worker resumes
through the outcome, including an interrupted active resume and excluding final
synchronous submission checks. Missing clock or velocity remains unavailable.
Protective stops retain the job report before FullStop disposes of the coroutine.

The deterministic regression uses a moving ship at 13.375 m/s, a sub-0.05 m/s
settling velocity increase, 3.5 m minimum/15 m preferred depth with weight 10,
and a synthetic 2.43 m shallow obstruction at 2087 m. The previous implementation
starts 801 jobs in 80 simulation seconds without publishing a route. The fixed
implementation uses one job, publishes after 371 fixed-work slices / 37.1
simulation seconds, and retains about 1589 m clear approach before the unchanged
stopping reserve. Commanded speed, fresh depth checks and larger-acceleration
invalidation are verified. This synthetic bathymetry is not a replay of DCS.

Keep the existing activation horizon and grid dimensions for the next comparison:
the controlled failure is corrected without enlarging the search, which could
itself add work. There is still no guarantee that every terrain problem completes
before reserve exhaustion; the new phase/outcome evidence will distinguish further
preflight cost, rejected geometry and legitimate input changes in DCS.

Validation: Lua 5.1.5 NAVYGROUP 121 cases and waypoints 16 cases passed. The new
regressions fail against the saved pre-change NAVYGROUP. The four focused regressions pass again after final diagnostic refinements.
Production/test Lua compilation and `git diff --check` pass.
DCS validation remains pending: restart testcase 55 with unchanged 3.5/15/10
depth settings, automatic corridor, 26 knots and diagnostics enabled. Capture
new load identity and inspect only after the user's mission-start notification.


## M3.2 follow-up: rounded-corner progress (2026-10-09)

The next Qeshm run submitted one route and rejected two prepared successors
with `submission_turn_angle`, then stopped at the installed route reserve.
No `speed_exceeded` outcome or Lua error was observed. The first rejection is
reproducible with production methods and logged coordinates: a short collinear
subdivision before the corner leaves progress on the incoming leg after DCS
adopts the outgoing course. The requested reconnect then turns back about
117 degrees. The second rejected proposal's geometry was not logged.

The user approved correcting progress and route reattachment.

- [x] Reproduce the logged outgoing-course case and continuation publication.
- [x] Recognise contiguous straight subdivisions at one rounded corner; retain
      all later real corners and fresh connector/turn/depth/reserve checks.
- [x] Cover unentered corners, opposite headings, distant/hairpin routes and
      an unsafe actual-position connector.
- [x] Validate Lua 5.1, review the scoped diff and prepare a fresh DCS baseline.

Raw logs, source identities and replay details remain in the task temporary
directory. This step changes no DCS controls, speed or recurring monitoring.

The installed-route tracker now looks through consecutive forward collinear
subdivisions only within the existing corner neighborhood. Collinearity is
measured against the original incoming line (one-meter tolerance), so a chain
of small bends cannot accumulate into a skipped real corner. It identifies the
first outgoing leg. Course-based rounding requires both the observed heading
and the bearing to that leg's next point to align, with the first retained
point already off the forward course and bounded lateral distance. This also
covers adoption of the outgoing course just before its endpoint plane. Plain
straight legs still require their normal endpoint-plane progress.

Submission refreshes actual progress on the installed route before mapping the
unpassed approach into the ready continuation. No angle limit, depth rule,
stop reserve, requested speed or proposal ownership check was weakened. The
recognition does not claim movement along an uninstalled replacement proposal.

Five new regression groups cover the recorded ship pose and successful forward
publication, earlier/later observations, additional straight subdivisions,
rotated/mirrored geometry, unentered/real corners, distant return legs, ordinary
straight progress, and a shallow new connector beside a clear retained line.
The previous source fails four of these groups. The replay uses production
methods and controlled terrain; it does not reproduce DCS bathymetry or physics.

Full validation: Lua 5.1.5 NAVYGROUP 126 cases and waypoints 16 cases pass;
changed Lua files compile and `git diff --check` passes. The first full run
exposed a pre-existing test timing boundary: decimal time subtraction can
produce slightly less than two seconds. Reproduced against the saved old
source; the test now advances one extra navigation tick before asserting the
same depth-triggered stop. No production timer semantics changed.

Next simulator check: restart Qeshm testcase 55 at the unchanged 26 knots,
minimum depth 3.5 m, preferred depth 15 m and weight 10. Verify the new loaded
source identity and continuation submissions after rounded corners. The second
rejected proposal from the preceding DCS run remains geometrically unconfirmed;
a full successful voyage is not established by these controlled regressions.

## M3.2 follow-up: LOCAL search and steering display (2026-10-09)

The user approved restoring the missing LOCAL grid display and distinguishing
submitted steering geometry from speculative search results. Keep testcase 55,
weight 10, speed and clearance settings unchanged for the first comparison.

- [x] Reuse ASTAR/GRID depth-colored, batched snapshots for the latest completed
      local request; preserve only one primary/probe window at a time.
- [x] Reuse PATHLINE for a magenta copy of the exact submitted DCS waypoints,
      independent of grid replacement; clean up both overlays on reset/stop.
- [x] Verify output geometry, depth colors, batching, cancellation and group
      ownership with production methods and controlled DCS drawing endpoints.
- [x] Run Lua 5.1 checks, review the scoped diff and refresh the prepared sources.
- [ ] Validate visually in a fresh mission after the user's start notification.

Verbosity >=10 enables the overlays. Drawing a search window does not select a
candidate or change navigation settings. The window may be an exploratory
extension; the magenta line is a command, not the observed vessel trajectory.
Cell-center colors do not establish corridor or hull clearance. No recurring
monitor, simulator control or mission driver edit is part of this step.

Validation: Lua 5.1.5 compilation and 246 cases pass (NAVYGROUP 129, GRID 106,
PATHLINE 11), each suite in a separate process. All three new display regression
groups fail against the saved previous NAVYGROUP source due to missing route
marks and pass with this change. They cover the real completed-request hook,
unchanged planned coordinates/speed with verbosity disabled/enabled, fresh
cell-center depth coloring in batches of at most 25, exact submitted waypoint
geometry, replacement, a stop callback during submission, separate primary/probe
ownership, two groups, stale drawing callbacks and unrelated marks.

The initial focused run found two fixture errors (the palette's deep-blue RGB
value and a recursively reentered simulated stop callback); both fixtures were
corrected before the successful focused and full runs. Production GRID and
PATHLINE were reused without edits in this step. Testcase 55 already enables
verbosity 11, so no driver modification was needed. Fresh source snapshots and
hashes are saved in the temporary test record; loaded-source verification and
visual DCS validation remain pending the user's next mission-start notification.

## M3.2 follow-up: drawing cancellation and bounded reattachment (2026-10-09)

The user approved correcting the two failures observed in the latest Qeshm
case 55 run. Source hashes/mtimes, dynamic include markers and the junction
agreed with the prepared display revision. The run and screenshot are archived
as raw bytes outside the source tree.

Evidence: the rounded-corner tracker advanced segment 2 to 4 correctly. At
publication, the logged actual position to retained point 5 was about 1,029 m,
exceeding the old 1,000 m connector limit. The continuation was rejected with
`submission_leg_length`. The next worker threw at GRID's
`timer.removeFunction(job.timerID)` with an invalid-reference error, which
propagated out of the navigation timer. No later navigation diagnostics were
logged although regular ship status continued. The cause of DCS considering
that timer ID invalid is not yet independently established.

- [x] Reproduce the native removal failure boundary in controlled GRID/ASTAR
      and NAVYGROUP drawing tests, including different planning coroutines.
- [x] Cancel GRID polygons and labels by job identity. Remove owned marks
      immediately; queued stale callbacks exit once without drawing, querying
      depth, rescheduling or affecting replacement/other-group jobs. Native
      timer IDs are no longer stored or removed; errors are not swallowed.
- [x] Replay the 1,029 m connector, including rotations and mirroring. Permit
      one midpoint for connectors up to 2 km, retaining at most 1 km per
      submitted leg and rejecting more distant anchors.
- [x] Check initial turn, original retained corner and onward reserve before
      subdivision, then freshly validate and price both segments through the
      existing installation boundary. Preserve every retained corner, speed,
      task ownership and the pending proposal.
- [x] Complete Lua 5.1 validation, review the scoped diff and refresh the source
      snapshot for testcase 55 with unchanged weight 10 and debug verbosity 11.
- [ ] Validate continued navigation, drawing replacement and the corrected
      reattachment in a fresh user-started DCS mission.

The new invalid-handle tests inject the exact native failure at the external
API boundary, rather than inventing DCS's internal registry behavior. Before
changes, GRID's new test and four of five new NAVYGROUP groups fail; the
excessively distant-anchor rejection already passes. Existing ASTAR drawing
fixtures now assert cancellation/no resurrection after draining a queued
callback instead of requiring immediate native-timer deletion. This changes
no navigation timer cadence, search budget, depth preference or safety margin.

Validation completed: Lua 5.1.5 compilation and 537 cases pass (NAVYGROUP 134,
GRID 107, ASTAR 280, waypoints 16), each suite in its own process. The GRID
invalid-handle case and five NAVYGROUP groups now pass, including the prior
negative bound check. The full NAVYGROUP run covers navigation authority,
protective stops, continuation, progress and drawing lifecycle together. One
ASTAR fixture additionally needed to preserve unrelated existing drawing counts
rather than assume an empty map. `git diff --check` passes. No production
API exception is caught or converted into a fabricated successful result.

Prepared fresh source hashes and snapshots include both GRID and NAVYGROUP.
The mission driver, weight 10, requested 26 knots, clearance settings and debug
verbosity 11 are unchanged. The current simulator run cannot validate edited
files retrospectively; a fresh user-started testcase 55 remains required.
