---
title: Rolling pathfinding development plan
parent: Developer
nav_exclude: true
---

# Rolling pathfinding development plan

Rolling planning should provide a checked local path towards a distant goal,
then plan another section as the caller moves. First establish this capability
in ASTAR and GRID independently of ships. Then simplify and optimize both naval
planning modes using the shared infrastructure.

Status as of 2026-10-05: M1 design and the approved M2.1/M2.2 implementation are
complete. GRID windows and resumable local ASTAR requests now return checked
partial or exact-goal paths. M2.3 progress/history, reuse and extended lifetime
validation, M2.4 DCS trials, and naval migration remain pending. The API status
below distinguishes implemented methods from remaining proposals. Existing LAZY
searches retain their full-goal contract.

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
| `NAVYGROUP:_FindPathToNextWaypoint` | Builds a finite grid, then uses expansion to obtain a complete route. | Keep this behavior during local migration; evaluate full-route optimizations separately. |
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

The first four calls below are implemented in M2.2. UpdateLocalProgress and
EvaluateConnection remain proposals for later milestones.

| Call | Parameters and purpose |
| --- | --- |
| `ASTAR:SetLocalWindow(Ahead, Width, Behind)` | Three distances in meters. Ahead and total Width are positive; Behind is non-negative. Configure the local extent explicitly for the first release. |
| `ASTAR:StartLocalSearch(Start, Goal, Heading)` | Start one local planning job. Heading is optional degrees; default towards Goal. Coincident endpoints are handled before choosing an orientation. Copy positions. Starting a job cancels a pending one. |
| `ASTAR:StepSearch(MaxNodes, MaxSeconds)` | Reuse the existing two work limits for full LAZY and local jobs. Return `path, report`; a pending nil path is not a failure. Do not change existing full-search results. |
| `ASTAR:CancelSearch()` | Cancel pending work without touching the caller's installed route. Reuse existing behavior. |
| `ASTAR:UpdateLocalProgress(Position)` | Record actual movement independently of the planning start. Needed for rolling-history checks; unnecessary for an isolated local request. No searching, scheduling or route commands. |
| `ASTAR:EvaluateConnection(Start, Goal)` | Proposed shared rule/cost evaluation for arbitrary positions, returning validity, cost and available diagnostics. It checks the connection rule, not membership of a complete graph path or turning feasibility. Required before removing naval private-method calls. |

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

For built-in distance/depth costs, compare validated travel cost plus the existing
compatible lower-bound estimate towards the overall goal. This is a local choice,
not a proof of cheapest total-route cost. Keep length and cost separate. Do not
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
2. Feed candidate paths into existing steering and route-preparation checks.
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
- [ ] M2.3 Bound generations and result lifetime, add actual-progress observations,
  and test several window transitions, long journeys, detours away from the goal,
  loop detection, missing data and memory limits. Confirm inactive results remain stable.
- [ ] M2.4 Provide small DCS scripts for standalone local planning. First move a
  simulated planning position along validated points; then check real terrain
  without changing ship behavior. Log each request and transition directly.

Acceptance: checked sections lead through deterministic multi-window scenarios;
limits and lack of local continuation have honest outcomes; no timer/controller
side effects; old FIXED/EXPAND/LAZY behavior remains covered. A point-following
test is not validation of DCS ship physics.

### M3 Naval integration and optimization

- [ ] M3.1 Expose shared connection evaluation with preserved failure evidence.
  Establish a naval baseline of searches, profile calls, cache hits, submitted
  routes, peak retained cells and total/worst-update CPU time.
- [ ] M3.2 Integrate local planning behind the existing navigation mode, preserve
  steering/safety/task behavior, and remove superseded private-method calls.
- [ ] M3.3 Test continuation, replacement and asynchronous ownership under turns,
  speed changes, retargeting, holds, patrol returns and failed candidate preparation.
- [ ] M3.4 Benchmark and improve complete-route planning separately. Consider
  overlap caching or shared polyline helpers only where measurements justify them.
- [ ] M3.5 Run DCS sea/canal/turn/dead-end trials, including return journeys;
  compare planned points with actual course and movement. Update user documentation.

Acceptance: no loss of the existing safety and mission lifecycle checks; fewer
repeated operations or lower measured work on comparable cases; no claim that
profiler percentages equal FPS gains. Public compatibility changes to released
APIs require an individual decision; intermediate unreleased APIs may be revised.

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
or DCS controller is owned by the planner. Each request currently builds a fresh
owned window and clears old owned drawings; supplied shared/prebuilt non-local
grids and manual nodes are rejected before replacing pending work. Full-goal LAZY
uses a separate ASTAR instance. Progress observation and compatible-window reuse
remain M2.3 work; diagnostic preservation for missing depth data remains pending.

Validation on 2026-10-05: Lua 5.1 compilation and separate-process suites passed:
GRID 104, ASTAR 243, navy-local 134 (481 total). The 18 new ASTAR cases and one GRID
case cover both lattices, rotated geometry, sector boundaries versus filtered
terrain, exact/3D/coincident endpoints, custom/zero/infinite costs, fixed-search
cost comparisons, depth rules, hard budgets, CPU slices, no-clock execution,
cancellation/reentrant callbacks, configuration changes, result ownership,
drawing cleanup and deterministic ordering across slice sizes. Existing
FIXED/EXPAND/LAZY and naval regressions remain green. No DCS mission or performance
benchmark has been run for M2.2; stubbed terrain tests do not validate ship motion.

## Validation and next implementation approval

Use Lua 5.1 syntax checks and separate processes for the affected suites. The
initial implementation touches GRID/ASTAR and their focused tests. Naval stages
also run `navy-local` and relevant depth/pathline/waypoint suites when their
dependencies change. Keep measured performance and DCS run snapshots outside the
source tree. Do not rerun unrelated tests for a documentation-only plan.

The next proposed code change is **M2.3**: compatible-window reuse, actual-progress
observations and bounded history, explicit missing-data diagnostics, and extended
multi-window/lifetime tests. Review that scope before starting it. M2.2 supports
individual local requests but does not yet diagnose repeated planning without
movement or migrate NAVYGROUP. Update this checklist after each stage.
