---
title: Local naval navigation
parent: Advanced
nav_order: 7
---

# Local naval navigation

`NAVYGROUP.PathfindingMode.LOCAL` is an experimental alternative to searching
all the way to the next original waypoint. Both modes initially follow the
ordinary mission route. Only an obstacle detected by the regular collision
check and close enough to the local planning horizon activates a search;
selecting `LOCAL` does not create a grid. More distant obstacles still raise
the normal collision warning while the ship follows its ordinary route.

Once activated, local navigation plans short sections through nearby navigable
water. A distant waypoint provides a preferred direction, not a requirement to
get closer on every section. As soon as the normal collision horizon towards
that waypoint is clear, the ship leaves local avoidance and resumes its ordinary
route. Regular collision checks can activate local navigation again if another
obstacle comes into range.

```lua
local navy = NAVYGROUP:New("Canal ship")

navy:SetPathfindingMinDepth(20) -- meters; choose an appropriate depth for this ship and terrain
navy:SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL)
navy:SetPathfindingOn()
```

Both local and global naval pathfinding are under development. The default
mode is `NAVYGROUP.PathfindingMode.WAYPOINT`, which currently uses the full
waypoint search. The cooperative ASTAR integration described here applies to
`LOCAL`; the global planner is a separate development step. Mode selection does not release `Holding` or
`Waiting`. `SetPathfindingOff()` disables automatic planning in either mode.
Switching away from a running local route requests a normal route update so the
ship is not left with only the old short route. Both modes retain an explicit
`GotoWaypoint()` destination across mode, speed and depth changes. A newer
`Detour()` or an inserted next waypoint replaces that destination.

## Search and route handling

### Optional preference for deeper water

Both `LOCAL` and `WAYPOINT` searches can trade a longer route for greater depth:

```lua
navy:SetPathfindingMinDepth(20)          -- hard limit for every depth check
navy:SetPathfindingPreferredDepth(30, 2) -- preferred depth in meters, penalty strength
```

This setting is optional and disabled by default. The weight defaults to `2`.
At 30 m and deeper, a route section costs its horizontal length. Between 20 m
and 30 m, a quadratic penalty increases that cost: at 25 m the multiplier is
1.5, at 21 m it is 2.62, and at 20 m it is 3. Water below 20 m remains blocked.
If a permitted shallow passage is the only route, A* can still use it.

Costs integrate the penalty over the actual distances between terrain profile
points, assuming linear depth between them. With a corridor, the shallowest
interpolated center/edge profile determines the penalty at each distance.
Irregular sample density therefore does not bias the result. A* caches validity
and cost from the same profile evaluation and keeps the straight-line heuristic.
The local planner also uses these costs when choosing an exit and simplifying
its route. The first smoothing pass rejects shortcuts that cost more than the
raw A* section they replace, preserving the depth preference when possible.
If that pass fails and encountered such cost rejections, one bounded fallback
pass allows more expensive connections. Minimum depth, valid terrain data,
leg lengths, turn angles and the turn allowance remain mandatory. Successful
first passes are retained; unweighted searches and failures without any cost
rejections do not trigger another pass. Cached depth and turn checks are shared,
but the second pass starts with fresh steering states. The actual weighted
cost of the resulting steering route still participates in exit selection.
A fallback is therefore no promise that a physically usable route exists.

A required outward corner correction can add length and cost; its actual weighted costs
are included in the final candidate score. The cheapest safe tested correction
is retained, rather than rejecting manoeuvring room because it costs more than
the original grid path.

**Normal collision checks, direct target approaches and the return to the
ordinary route still require only the minimum depth.** The preferred depth
does not cause an additional collision warning, stop, or continued local search
after the target horizon has cleared.

`navy:SetPathfindingPreferredDepth()` disables the preference. Weight `0`, or
a preferred depth at/below the minimum, adds no penalty. Changes discard unused
local plans and apply to new searches; the installed route remains active.
These weights are planning preferences, not a model of DCS turning behavior.

For a standalone search, configure the neighbour rule before selecting the cost:

```lua
astar:SetValidNeighbourDepth(20, 50) -- minimum depth and total corridor width
astar:SetCostDepth(30, 2)
```

`astar:SetCostDepth()` restores distance costs. Changing the depth rule updates
its dependent costs; choosing a different neighbour rule restores distance costs
if the depth preference was active.

### Independent connection checks

`ASTAR:EvaluateConnection(start, goal)` checks arbitrary positions using that
search's neighbour rule and cost function. It returns `valid, cost, report`:

```lua
astar:SetValidNeighbourDepth(3.5, 50)
astar:SetCostDepth(15, 10)
local valid, cost, report = astar:EvaluateConnection(start, goal)
-- report.Status: "clear", "blocked", or "unavailable"
-- report.Reason / report.Stage explain a rejection; cost is then math.huge.
```

Inputs may be VECTOR, COORDINATE, Vec2 or Vec3. They need not be grid cells or
lie inside the current window. The call uses fresh terrain queries and does not
alter a running search, its endpoints, counters, caches or completed reports.
Compatible depth validity and costs share their profile queries. Returned
positions and rejection evidence are caller-owned copies.

Built-in depth checks distinguish an observed obstacle from unavailable data.
`report.Depth` includes the required depth and corridor width; a failed check
also records the rejected sample, measured depth, surface, cause and profile
offset where available. Endpoint names and signed offsets follow the original
input direction. The evidence is the first sample rejected by the evaluator,
not the first obstruction along the route. Use `PATHLINE.CheckDepth()` when a
usable prefix and obstruction localization are required.

Cell filters and grid adjacency are separate from this connection rule.
`SetValidNeighbourSurface()` still applies its explicit surface rule. Custom
callbacks receive temporary nodes with copied vectors and surface metadata;
their extra arguments and exceptions are preserved. Callbacks must not rely on
cell membership, persistent node identity or mutation of the search. Neither
this check nor the grid route verifies a ship's turning clearance.

### Optional measurements

Measurements are disabled by default and apply to navigation in both modes.
Enable them explicitly on a NAVYGROUP before the test:

```lua
navy:SetPathfindingDiagnostics(true)

-- After the chosen test interval, from mission code or an existing test menu:
navy:SetPathfindingDiagnostics(false)
navy:LogPathfindingDiagnostics()
local metrics = navy:GetPathfindingDiagnostics()
```

Disabling freezes the interval; enabling again starts a fresh one. Repeated
`true` keeps the active interval. Change this setting between navigation updates.
The getter returns an independent snapshot. Aggregate metrics are logged only
by `LogPathfindingDiagnostics()`. While enabled, LOCAL also logs one compact
outcome for each submitted, failed or cancelled planning job. It does not log
every slice or add a navigation timer.

The snapshot contains:

- `SearchAttempts`: completed ASTAR requests, including no-path results. A local
  request explores one window and can produce several exits; it is not a new
  search for every exit. Speculative continuation requests count separately.
  Lookup deltas are accumulated across slices, including work completed before
  cancellation. Cancelled unfinished requests do not count as completed attempts.
  `WAYPOINT` continues to count its completed expansion searches.
- `ValidityRequests` / `ValidityCacheHits` and `CostRequests` / `CostCacheHits`:
  existing ASTAR lookups during searching and steering preparation. A combined
  depth check can populate the cost cache while validating an edge, so a cost
  cache hit does not mean that the underlying depth evaluation was free.
- `ProfileQueries`: actual native profile calls made by ASTAR/PATHLINE depth
  checks in measured scopes, including unavailable results and failed calls.
  Direct seabed/surface samples and other uses of `land.profile` are excluded.
- `RouteSubmissions`: issued route commands, including full stops. This counts
  commands, not controller acceptance, ship movement or arrival.
- `PeakRetainedCells`: maximum sampled sum of distinct grids referenced by the
  measured search, retained plans and debug views. This counts accepted cells,
  not bytes, rejected candidates or an exact instantaneous memory peak.
- `Scopes`, `Errors`, `CPUSeconds`, `MaxScopeCPUSeconds` and `Operations`:
  navigation updates, individual planning slices and route-update measurements.
  `CPUSeconds` accumulates active work across slices; time spent waiting between
  updates is excluded. `MaxScopeCPUSeconds` measures the longest individual
  outer scope, not the duration of an entire asynchronous job. Nested scopes
  contribute once to aggregate CPU/profile counts; per-operation CPU is
  inclusive and must not be summed. User callbacks in these scopes are included.
  Errors are propagated after recording, never converted to navigation success.

CPU fields remain unavailable (`nil`) without a usable `os.clock`; simulation
or wall time is not substituted. Measurements add some overhead, including a
small shared profile-call counter when naval measurement is disabled. Compare
identical terrain, starts, targets, headings, ship speed/geometry, safety and
cost settings, loaded source versions and debug options. Simulation acceleration
and elapsed mission time are separate observations; these counters do not
measure FPS or validate DCS ship physics.

### Short hull and heading check

With pathfinding enabled, both modes inspect every live ship every **two
simulation seconds**, including during turns and before normal route planning
or target release. Ordinary waypoint collision checks retain their ten-second
cadence; an active local detour also rechecks its installed remainder every two
seconds. All these checks share the navigation timer.

The short check uses each ship's actual position, heading and speed, together
with its cached DCS bounding box. The box retains the model's reference-point
offset: its forward extent need not equal half the total length. Without a box,
cached length/beam are used; missing sizes fall back to 100 m length and 30 m
beam. Each live formation member is checked at its own position and heading.

Parallel depth profiles, at most 10 m apart, cover the hull from 10 m behind
the stern to **`max(50, actual_speed * 10)` meters beyond the bow**, with 10 m
lateral clearance on each side. This footprint is independent of the A*
corridor setting, including an explicit zero-width corridor. It uses only
the hard minimum depth, never the preferred-depth penalty.

A blocked sample or unavailable depth triggers `FullStop()` without waiting
for a turn to finish or starting another search. An existing hold, waiting
state, externally owned movement task, disabled pathfinding or a warning
callback that takes control remains authoritative. Clear nearfield samples do
not clear a warning about a more distant obstacle. `LastNearfieldCheck` stores
the latest short-check result separately from normal route diagnostics.

The ten-second forward distance is a short straight projection of current
motion, not a predicted turn or calibrated stopping distance. It can stop a
ship before a bend that DCS might otherwise negotiate. Small features between
profiles or between timer samples can still be missed. This protection does
not change the ship's speed or guarantee that a collision can always be avoided.

### Cooperative planning

NAVYGROUP owns one navigation timer, running every **0.1 simulation seconds**.
It advances local planning and observes actual route progress. Hull checks run
every two simulation seconds; ordinary waypoint lookahead runs every ten.
ASTAR owns no timer and never issues movement commands.

```lua
-- Optional LOCAL planning limits: work items, CPU seconds, slices per job.
navy:SetPathfindingWorkBudget(512, 0.005, 2000)
```

These are the defaults. Work items and slices must be positive integers; the
CPU budget must be finite and positive. Calling the setter cancels unpublished
work but does not start navigation or change the installed route. The work-item
budget remains effective without a usable CPU clock. Budgets are cooperative:
searching, path copying, steering preparation, turn checks and final route
pricing yield between operations. A terrain query or custom callback is atomic
and can exceed the requested time budget. Fresh safety checks and route
submission are separate work; this setting is not a hard bound on the whole
navigation callback.

Each planning job snapshots its destination, configuration, movement authority
and installed route. It progresses through window exploration, steering
preparation, bounded continuation planning and final pricing. Incomplete work
publishes no route. A completed proposal stays separate from the installed
route while the ship turns. Before submission, NAVYGROUP checks the job's
identity again, reattaches it to actual progress and checks the current heading,
connector and remaining route. Retargeting, disabling pathfinding, changing
planning inputs, replacing the installed route or losing movement authority
cancels stale work. A late result cannot overwrite a newer command. Clearance
callbacks are checked against a snapshot of movement authority, route,
configuration and all target coordinates before completing a waypoint or
publishing a route. A callback can therefore retarget or change depth settings
without an older clearance result authorizing further action. Proposed route
geometry remains separate from installed state until these checks succeed.

Each job uses a fixed conservative planning speed: the greater of commanded and
observed speed, plus the greater of 0.5 m/s and 5% of that speed. Steering geometry, useful continuation
and final preparation reserves cover that bound. Small observed-speed changes
inside it retain the job, including a completed proposal waiting to be submitted.
Exceeding it cancels unpublished work with `speed_exceeded`; a later job uses a
new bound. Command/configuration changes still invalidate work immediately.
This does not change the commanded vessel speed. Live stopping checks continue
to use the greater of actual and commanded speed, and final route reattachment
still checks current position, heading and depth.

### Search ownership and route preparation

- With local avoidance inactive, the ordinary collision check examines up to
  5 km towards the next native waypoint. It skips turns. An explicit
  `GotoWaypoint()` destination is respected even before a waypoint callback
  advances mission progress. Missing depth data stops navigation.
- In `LOCAL`, a distant obstruction first raises a warning. Planning starts at
  `min(5000, max(2000, max(400, speed * 60) + 1000) + speed * 10)` meters of
  remaining clear approach. Speed is the greater of actual and commanded speed
  in m/s. At 27 knots this is about 2.14 km; at 50 knots, about 2.80 km. Until
  activation, the ordinary route is retained and no local search is allocated.
  During initial asynchronous planning, the ship can follow only a freshly
  checked native approach with sufficient stopping reserve.
- The first job can retain a forward section of this native approach as its
  prefix when the ship is not turning and its heading differs by at most
  5 degrees from the original target bearing. The lead distance is
  `min(1000, max(400, speed * 75))` meters, using the greater of actual and
  commanded speed in m/s; the target must be farther away than twice that
  distance. Search then starts from the future prefix endpoint, reducing the
  chance that a sideways exit falls behind the ship while the job runs. The
  complete approach, including its endpoints, receives fresh depth checks
  during preparation and again before publication. If the optional approach
  is known to be blocked, the worker discards that prefix and starts the public
  local search from the job's original actual-position snapshot. Unavailable
  depth data remains a failure. Live approach and stopping-reserve checks
  continue throughout. Useful suffix length is checked independently, so the
  prefix cannot disguise a short continuation.
  These distances and the 75-second factor are implementation allowances,
  not DCS physics measurements or a promise that planning finishes in time.
  If the ship passes the anchor, current heading, connector checks and stopping
  reserve still determine whether the proposal can be used.
- The leg owns an ASTAR configured through `SetLocalWindow`, `StartLocalSearch`,
  `StepSearch` and `EvaluateConnection`. Each request explores one bounded
  sparse hex window for all frontier exits together. The window extends at
  least 3 km ahead, 1 km behind and 1 km to each side, with 50 m center spacing.
  Its forward extent grows in 500 m steps to cover the activation distance plus
  500 m, up to 5.5 km. `SetPathfindingGrid()` supplies the cell limit (5,000 by
  default); its expansion factor and attempt limit apply only to `WAYPOINT`.
- Successful ASTAR requests supply copied position lists and scalar diagnostics.
  NAVYGROUP does not retain previous node graphs or reach into ASTAR's search
  internals. A checked exact goal takes priority; otherwise up to eight ranked
  frontier exits are considered. A cell limit or unfinished request publishes
  no provisional exits.
- Compatible requests retain ASTAR's bounded learned continuation costs. The
  ship's actual position is supplied through `UpdateLocalProgress`; a planned
  future anchor is never reported as movement. Learning can discourage repeated
  poor local choices, but it permits retreats and does not guarantee escape
  from a dead end. Changed goal, grid or depth/cost settings invalidate the
  corresponding planner state.
- First, all primary exits are converted to steering routes and checked for
  actual geometry cost, useful suffix length and reserve after turns. Routes
  that are already complete and usable take priority over exits that still
  need extension. Within each group, ranking uses actual geometry costs,
  ASTAR's goal estimate and learned penalty; equal scores use the original
  candidate order. Steering rejection eliminates an exit before continuation
  work starts.
- The first usable primary route that passes fresh final validation is
  accepted. Only if no complete primary route succeeds does the planner extend
  short exits in their rank order, using at most two additional local requests
  per exit. It accepts the first usable extended route, without preparing all
  extended alternatives to compare their final scores. A cheap short exit
  therefore cannot demand speculative searches ahead of an already usable
  primary route. Probe requests use isolated planners with learning disabled,
  so speculative futures cannot teach the leg-owned planner that the ship
  visited them. One job remains bounded to 17 requests: one primary request and
  at most two continuations for each of eight exits. The per-job slice limit
  applies across all phases.
- Continuation preserves every unpassed point of the installed approach. Its
  preparation checks the newly added suffix independently of that approach,
  then checks reserve after each future turn. A long incoming leg cannot hide
  a short unusable exit beyond the last corner. A candidate with insufficient
  reserve is rejected before publication; checked routes to the actual goal
  are exempt from the non-goal length allowance.
- The completed proposal records the cost of its complete steering geometry,
  terminal goal estimate and primary learned penalty separately from its
  primary ranking score. Planning candidates issue no movement commands.
  Distant original waypoints are never appended behind an unchecked local
  exit. Original waypoints and their task queues remain stored in NAVYGROUP.

### Steering and execution

Every connection and simplified shortcut uses the configured minimum depth
and corridor width. Without an explicit width, the widest ship plus 10 m on
each side determines the corridor. Straight legs, turn angles and the space
around a corner must all pass their checks.

For turns greater than 5 degrees, planning samples a circular allowance around
the corner. Its radius is half the corridor width plus
`ceil(max(50, min(speed * 10, 150)) * min(1, turn / 30) / 25) * 25` meters.
Parallel terrain profiles at most 25 m apart sample the interior as well as its
edge, using only the minimum depth. This is a conservative planning allowance,
not a measured DCS turning radius.

If this area is blocked, steering preparation can move a proposed corner
outwards along the angle bisector in 25 m steps up to 150 m. It rechecks both
adjacent legs and turns. The ship's actual position, original mission waypoints
and commanded speed stay unchanged. Earlier steering choices can be revisited;
each pass is bounded to 128 states. Only a failed pass with depth-cost rejections
can use the second pass described above, giving at most 256 states per
candidate. `steering_budget_exceeded` does not prove that no physical passage
exists.

During execution:

- The installed route remains authoritative while a continuation is prepared.
  Extension begins below approximately `max(3000, stopReserve + 2000)` meters
  remaining and requires actual progress. Pending geometry cannot replace an
  installed route until preparation and fresh submission checks succeed.
- An initial search or an actual-position replacement may finish after the
  ship has passed some proposed points. Submission advances only through
  consecutive reached legs whose forward projection remains near the line.
  It never jumps to an arbitrary nearby point farther along a winding route.
  The connector from the actual position, its initial turn and the first
  retained corner receive fresh checks. A short remainder of a straight
  approach can keep its waypoint when neither it nor the following leg needs
  a new turn; it need not become an overlong shortcut. If rounded ship movement
  makes the new connector longer than 1 km, publication may insert one collinear
  midpoint, keeping both submitted segments at most 1 km. This is bounded to a
  2 km connector; a more distant anchor is still rejected. The actual initial
  turn and original first retained corner (including its onward reserve) are
  checked before subdivision, so the midpoint cannot hide an unsafe corner.
  Both new segments receive fresh corridor/depth checks and cost evaluation;
  no retained corner is skipped and the pending proposal remains unchanged.
- The stopping threshold is `max(400, speed * 60) + speed * 10` meters, using
  the greater of actual and commanded speed in m/s. These are planning margins,
  not measured braking distances. Reaching the reserve without a usable
  completed continuation stops the ship; there is no synchronous last-chance
  search that consumes the reserve while waiting.
- A failed future-anchor request can retain a freshly checked installed route
  above this reserve. Outside a turn, NAVYGROUP starts one asynchronous
  replacement from the actual ship position and course. During a turn it waits
  for a stable heading. A failed replacement requires another 250 m of route
  progress before a retry; an unfinished or failed proposal never licenses
  travel beyond the installed remainder.
- An installed remainder that becomes blocked, or whose depth data becomes
  unavailable, causes an immediate protective stop. Asynchronous replacement
  cannot justify continuing along a route that has failed its safety check.
- Outside a turn, a clear 5 km horizon towards the original target and a clear
  initial turn allowance allow a return to ordinary routing. This cancels
  local work and releases the local planner while retaining the destination,
  commanded speed/depth and waypoint tasks. It is neither an arrival event nor
  proof that the entire distant route is clear. Normal collision checks can
  activate local planning again later.
- A changed destination discards the old local detour. Its new leg begins with
  ordinary routing and collision checks. Configuration changes for the same
  destination cancel unpublished work; the installed route must still pass
  fresh checks under the new settings.
- Local steering points have no native waypoint callbacks. OPSGROUP processes
  the original waypoint when the actual ship is within 50–150 m, depending on
  speed. Queued waypoint tasks retain control while their startup callback is
  pending; ordinary routing resumes after those tasks finish.
- DCS controls turns between submitted waypoints. Line deviation alone causes
  neither a stop nor a new search. The two-second hull check follows actual
  position and heading. Route checks during turns use the stored segments;
  outside a turn they also check the actual-position connector to the next
  point. A blocked connector stops navigation.
- Segment progress stays on contiguous legs. Near a corner it can advance to
  its outgoing leg when that leg is closer, or when the observed heading and
  bearing to its next point both match the outgoing course. The latter can
  happen before the ship crosses the outgoing leg's endpoint plane. The first
  retained point must already lie substantially off the forward course, with
  bounded distance from the corner and outgoing line.
  Consecutive straight subdivisions within the same corner neighborhood are
  treated as one incoming leg: every subdivision must advance along the original
  incoming line and remain within one meter of it. Looking ahead stops at the
  first real bend or the neighborhood boundary; it cannot select a distant
  return leg of a hairpin. Straight legs still use the endpoint-plane rule.
  Submission refreshes this installed-route progress before mapping a retained
  approach into its completed continuation. All remaining corners and fresh
  connector, turn, depth and reserve checks remain mandatory. This geometric
  progress recognition neither advances a mission waypoint nor claims that
  an uninstalled proposal was followed by the ship.

## Failure and limits

A failed initial search, an invalid ship position, a blocked or unavailable
nearfield, a blocked or unavailable installed remainder, or an exhausted route
reserve causes `FullStop()`. A failed routine extension can retain a freshly
checked installed remainder above the reserve and retry after progress. Limits
such as `cell_limit`, `local_request_limit` and `local_slice_limit` fail the
current planning job; they do not publish an incomplete route or prove that
the destination is unreachable.

Navigation stays stopped until an explicit movement command such as `Cruise()`
is issued. There is no automatic retry from `Holding`, reverse recovery or
guaranteed escape from a dead end.

This prototype may miss a passage because of grid spacing, bounded candidate
selection or its steering filters. It checks straight center and edge profiles
and samples a local allowance at planned turns. Features between sampled
profiles can still be missed. The short check covers the current hull and heading
of each live formation member, but route planning still uses the group route
and its corridor. Neither approach models the complete swept hull area of a
future curve, other moving ships or the actual DCS turning radius.
The circular allowance may conservatively reject an otherwise passable bend;
a safe alternative can also lie beyond the bounded corner adjustments. The
stopping reserve is a prototype margin, not a measured braking model. A
geometrically valid route therefore still needs validation with the intended ship and mission speed in DCS.

With trace enabled, `Local route point` lists the actual waypoints submitted to
DCS, identified by route number. `Local route segment` records changes to the
tracked segment, their reason, actual heading, next point and bearing. These
describe the submitted steering geometry and its observed progress.

With `navygroup.verbose=10` or higher, LOCAL navigation also draws two F10 overlays:

- A depth-colored grid of the latest completed local request, including speculative
  extensions. Only one search window is shown; it need not belong to the chosen
  route. A new request on the same search clears the previous window until the
  next result is ready. No raw A* candidate is highlighted as a commanded route.
- A magenta line through the exact waypoints last submitted to DCS, starting at
  the ship's position at submission. It remains while the next search is prepared
  and is replaced on the next submission. It is not the observed ship track.

The depth scale runs from the configured minimum depth to the preferred depth;
if no preference is set it spans another 20 m. The upper bound is always at least
one meter above the minimum. Below-minimum water is red, then the scale runs from
orange through cyan to blue; deeper water stays blue, land is brown and missing
data is gray. These colors sample **cell centers only**. They do not certify the
clearance of the edges, route corridor or swept hull. The display changes no
minimum-depth rule, cost weight or steering decision.

GRID draws in its existing batches (up to 25 cells and a 5 ms CPU budget per
batch, with a 0.1 s simulation-time interval). Debug rendering has overhead and
can appear gradually, especially with simulation acceleration. Stopping,
disabling/resetting navigation or changing mode removes this group's overlays
and cancels pending grid batches. Cancellation invalidates the drawing job
immediately and removes existing marks. A callback already queued in DCS wakes
at most once more, performs no drawing or depth queries, and does not reschedule.
It cannot touch a replacement job. This avoids relying on a native timer handle
remaining removable across successive search workers. GRID polygon and label
jobs share this lifecycle. Other groups and unrelated map marks remain.
The existing WAYPOINT grid/path appearance is unchanged. Below verbosity 10 these
LOCAL drawing calls and their extra cell-center depth queries are skipped.

Depth evidence is split into `Naval depth check`, `Naval depth position` and,
when available, `Naval depth segment` lines so DCS does not truncate coordinates.
Nearfield failures additionally report `Naval nearfield` with the affected unit,
hull dimensions, speed, lookahead and clear distance measured from the bow.
Stages `ship_hull`, `ship_lookahead` and `nearfield` distinguish an occupied-hull
obstruction, an obstruction ahead and unavailable short-check depth data.

`LastPathfindingResult` records the latest installed plan or stop. A plan includes
`RequestID` and its scalar `Request` summary, selected `Candidate`, `Attempts`
(completed job requests), `Slices` and `WorkItems`. `Length`, `SuffixLength`,
`RequiredLength`, `StopReserve` and `PreflightExtensions` describe preparation.
`PlanningSpeed` is the fixed speed bound used for that geometry, in m/s.
`Points` contains copied steering positions. `PrimaryScore` records the cost
ranking after steering, within the already-usable or needs-extension group;
`Score` records the completed route's cost and
terminal estimate, including the retained learned penalty. They need not be
equal, and `Score` does not claim a minimum across all possible extended
alternatives. `Cost` is the freshly priced submitted geometry; `PlannedCost`
preserves its earlier price before adjustment to actual position.
`LearnedPenalty` is the primary exit's retained penalty. All costs and scores
are planning units. `Steering` describes simplification states, backtracks,
constraint counts and corner adjustments. A `goal_path` outcome describes the
plan, not observed arrival.

With trace enabled, `Local route prepared` records the chosen request and exit,
request count, complete/suffix lengths and final cost. `Local navigation
activated` records clear distance, activation threshold and window extent;
`Local navigation finished` records the return to ordinary routing. Stops at
the reserve use `local_route_exhausted` or `local_route_exhausted_in_turn` and
include `Remaining`, `Reserve` and the latest `ExtensionFailure` where available.
A failure can record its reason, remaining distance, reserve and whether it
awaited a straight course or came from an actual-position replacement.

`LastLocalPlanningReport` is a group-owned, read-only scalar snapshot of the
latest job outcome. A stop that interrupts an active or pending job also retains
it as `LastPathfindingResult.Planning`. With diagnostics enabled, the three
`Local planning outcome/work/inputs` lines record the job ID, outcome reason,
phase, request count, candidate index, extension count, slices, work items, last rejection,
planned speed bound and actual speed. Cleanup does not duplicate an outcome.
`SimulationSeconds` is elapsed mission time including time between slices;
`CPUSeconds` covers worker resumes through the outcome, excluding those waits
and synchronous final submission checks. It is `nil` without a usable clock.
The phase distinguishes graph exploration, steering, reserve checks, final
pricing and a ready proposal; `path_found` alone is not a submitted naval route.

Before a depth-related stop, `Naval depth check` records the check stage,
segment, cause, measured and required depth, surface, profile offset and
current position/heading/turn state. Separate position and segment lines avoid
DCS truncation. Stages distinguish the hull, lookahead, actual-position
connector, stored route and submission connector. This uses existing evidence
without additional terrain queries. Rejected target-horizon and target-turn
checks explain why ordinary routing cannot yet resume; repeated unchanged
causes are throttled to once per 60 simulation seconds per stage.

Steering diagnostics distinguish short/long legs, excessive course changes,
failed depth checks, higher-cost shortcuts and blocked corner allowances.
These count steering alternatives, not ASTAR requests. Neither diagnostic
success nor a green route overlay establishes that the DCS controller has
followed the route safely.

## Suggested DCS test

1. Start with one ship in open water, using a modest mission speed. Confirm that
   `LOCAL` follows the normal route without creating a search grid.
2. Place a bend or obstacle on the route, with the original destination well
   beyond the first local window. Confirm that the 5 km lookahead warns first,
   while the ship retains its native route. Local avoidance should activate
   only near the speed-based threshold (about 2.14 km at 27 knots). Repeat with
   a higher speed and confirm that activation and the forward grid extent grow.
3. Confirm that the active route extends while the target direction remains
   blocked, then returns to ordinary routing once its collision horizon clears.
   No further local searches should run in clear water. Watch for bank contact,
   abrupt steering and unwanted route replacement during turns. Include a
   small island beside a corner whose two straight legs are individually clear;
   inspect the adjusted corner and compare the actual turn with the planned
   allowance. Repeat at the same depth, weight and speed for a useful comparison.
4. Test a second obstacle on the same leg and verify a fresh local activation
   after its early warning, once it enters the activation distance. Confirm that
   the original destination and its tasks are processed only when actually reached.
5. Repeat a case with a blocked continuation while the installed remainder is
   still clear. Inspect replacement from the actual ship position, remaining
   route distance, stopping threshold and the recorded extension failure.
   Confirm that failed retries require progress, turns do not receive abrupt
   replacements, and the ship stops by the reserve if no continuation succeeds.
   A dead end must still cause a single persistent stop without retries from
   `Holding`, including after later timer ticks. Also block the installed
   remainder and verify an immediate stop rather than continued movement while
   a replacement search is pending.
6. Use a small work budget to keep a request active over several updates. Change
   the target, depth rule, commanded speed or mode and verify cancellation of
   stale work. Small observed-speed fluctuations within the planning bound must
   retain the same job; an increase beyond it must cancel the job. With diagnostics
   enabled, inspect the outcome before a hold or reserve stop discards the worker.
   No incomplete route should be sent; retained route checks must continue.
   Include a long approach followed by a short turning exit, so approach length
   cannot hide inadequate reserve beyond the corner. Let the ship move past
   consecutive initial proposal points before search completion and verify the
   freshly checked connector. Include a clearance callback that changes the
   target or depth rule before arrival or route submission.
7. Test an original waypoint with a task, a manual stop/resume, an explicit
   `GotoWaypoint()` followed by `Detour()`, and switching between both modes.
   Confirm that the route and collision check follow the same destination.

Standalone regressions run from the repository root with
`lua tests/navy-local.lua`. They use synthetic terrain and route/task spies;
they do not establish how the DCS ship controller will steer a real hull.
