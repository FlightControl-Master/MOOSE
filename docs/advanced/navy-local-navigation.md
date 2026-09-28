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

The default mode is `NAVYGROUP.PathfindingMode.WAYPOINT`, which retains the
existing island-detour behavior. Mode selection does not release `Holding` or
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
cost of the resulting route still participates in the candidate comparison.
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

### Short hull and heading check

With pathfinding enabled, both modes inspect every live ship every **two
simulation seconds**, including during turns and before normal route planning
or target release. The separate route check still runs every ten seconds.

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

### Planning and execution

- While local avoidance is inactive, the regular collision check examines up to
  5 km towards the next native waypoint every ten seconds. It skips turns. An
  explicit `GotoWaypoint()` destination is respected even before a waypoint
  callback advances mission progress. Missing depth data stops navigation
  without starting a search.
- In `LOCAL` mode, a distant obstruction only warns. A* starts when the measured
  clear distance falls to the activation distance, calculated as
  `min(5000, max(2000, max(400, speed * 60) + 1000) + speed * 10)` meters.
  Speed is the greater of actual and commanded speed in m/s. This combines the
  existing manoeuvring allowance with one regular check interval. At 27 knots,
  LOCAL therefore starts at about 2.14 km; at 50 knots, about 2.80 km. A warning
  already active from an earlier tick does not prevent activation as the ship
  approaches. Until then, native waypoints, tasks and speed are retained, and
  no grid or A* search is allocated. `WAYPOINT` mode still searches immediately
  after a blocked lookahead.
- Each hex window extends at least 3 km ahead, 1 km behind and 1 km to each side
  of its planning origin. The front grows in 500 m steps to cover the activation
  distance plus at least 500 m, up to 5.5 km ahead. At 27 knots it remains 3 km;
  at 50 knots it is 3.5 km. Candidate exits follow this front. Small speed
  changes or slowing down retain an already sufficient window. The same
  allowance applies when planning a continuation from a future route anchor.
  `GRID.Resolution.FINE` retains approximately 50 m center spacing. These
  distances are planning allowances, not measured DCS stopping or turning radii.
- The existing `SetPathfindingGrid()` cell limit applies (5,000 by default).
  Local mode does not use its expansion factor or attempt limit; it never
  expands into a global search. An insufficient cell budget stops planning.
- Up to eight original-goal or front/side exit candidates are tried using one
  ASTAR instance. Depth-edge caches are reused within that window. A new window
  is built after sufficient movement, heading, target or configuration changes,
  or when higher speed needs a longer window.
- Candidate selection first keeps all usable alternatives. The provisional
  score includes weighted depth costs, target direction, course changes and
  missing route length; sufficient length does not override depth costs.
  The preparation target is the usual extension horizon (at least 2 km, or the
  stopping reserve plus 1 km), with up to one additional stopping reserve for
  an initial turn of 90 degrees. This allowance scales with speed; it is not
  a measured turning-radius model.
- Before final selection, each short candidate receives up to two checked local
  continuations if its endpoint cannot already connect towards the target.
  Each starts at the previous endpoint with its incoming course, retains every
  existing steering point, and uses the same depth/corridor rules. These
  continuations use the provisional cost-ranked choice without recursively
  preparing all its alternatives: at most 16 additional window searches for
  eight original candidates, not an unbounded search tree.
- Only sufficiently long prepared routes compete in the final comparison,
  using costs and turns for the complete avoidance route, including retained
  approach points and added local continuations. A free direct target approach
  needs minimum depth only. It supplies route reserve, but its arbitrary 5 km
  horizon does not buy additional progress in the candidate score. If a short
  deep candidate cannot be extended, other usable candidates remain available.
  Candidate trials issue no movement commands; only the selected route's window
  is retained for the next tick.
- This also applies to replacement routes and routine extensions. The combined
  remainder is rechecked before submission. If every candidate fails preparation
  or remains too short, no partial movement route is sent. With no usable
  installed remainder, the ship stops; a failed routine extension can retain its
  still-clear route as described below. A route reaching the original destination
  does not need this non-goal length allowance.
- With trace enabled, `Local candidate available` records the original exit,
  length, required length, weighted cost and provisional score. `Local candidate
  prepared` records the complete length, cost, depth penalty, final score and
  extension count. `Local candidate rejected` gives the failed stage and reason;
  `Local candidate selected` identifies the winner and active depth settings.
  Lower scores win among prepared alternatives. Costs are planning units, not
  physical distances; only the selected target approach emits the usual
  `Local route target approach` notice.
- Every connection and every simplified shortcut uses the configured minimum
  depth and corridor width. Without an explicit width, the widest ship plus
  10 m on each side determines that corridor.
- For turns greater than 5 degrees, planning also samples a local circular
  allowance around the corner. Its radius is half the corridor width plus
  `ceil(max(50, min(speed * 10, 150)) * min(1, turn / 30) / 25) * 25` meters.
  Speed is the greater of actual and commanded speed in m/s. Parallel terrain
  profiles at most 25 m apart sample the interior as well as its edge, using
  only the hard minimum depth. Straight legs keep the original corridor width.
  The allowance is a conservative heuristic, not a measured turning radius.
- If this area is blocked, the simplifier tries moving the corner outwards along
  the angle bisector, in 25 m steps up to 150 m. It rechecks both adjacent legs,
  their length/angle limits, the preceding turn and the moved turn. The ship's
  actual position, original mission waypoints and commanded speed are retained.
  Only proposed local steering points can move. If a greedy waypoint leaves no
  usable continuation, earlier choices can be revisited. The search is bounded
  to 128 steering states per pass. Only a failed pass with depth-cost rejections
  may start the second pass described above, giving at most 256 states per A*
  candidate. An exhausted final budget produces `steering_budget_exceeded`,
  not a claim that no physical passage exists. Trace message `Local steering
  fallback` identifies the candidate, planning origin, first-pass failure,
  raw/actual cost, result and both state counts. Failure details identify the
  last pass; the report also retains `FirstPass` diagnostics.
- During an active local detour, only the validated local remainder is sent to
  DCS. Distant original waypoints are never appended behind a local exit.
  Original waypoints and their task queues remain stored in NAVYGROUP.
- Every regular navigation tick outside a turn also checks up to 5 km directly
  towards the original target, or the whole distance if it is closer. A clear
  corridor and a clear allowance for the new initial turn end local avoidance
  before further local checks or extensions. A blocked turn retains local
  guidance; unavailable turn-depth data stops navigation.
  The search window, prepared continuation and drawing are discarded; target,
  commanded speed/depth and waypoint tasks are retained. This is a return to
  ordinary routing, not an arrival event or proof that the entire remaining
  route is clear. Normal collision monitoring continues and can start a new
  local detour once another obstacle reaches the activation distance. Missing
  depth data causes a stop. The activation threshold does not shorten the
  5 km target-clearance check used to leave an already active local detour.
- Changing the destination discards the old local detour. The new leg starts
  with ordinary route following and collision checks again. Speed and depth
  commands for the same destination retain the active detour.
- Routine extension preserves approximately 1 km of the installed approach, where
  available, if another local search is needed. Before trimming to this anchor,
  the planner checks the target horizon from the **last point of the full
  installed route**. If that corridor is clear and the course change is at most
  90 degrees, and the corner allowance is clear, it keeps every remaining
  corner and appends up to 5 km towards the
  target in legs of at most 1 km. This needs no new grid or A* search. A shorter
  connection ends exactly at the original target. The same check is made before
  extending a short route during departure preparation.
- An appended target approach remains part of the local route until the actual
  ship's target horizon is clear outside a turn. It does not authorize a shortcut
  from the current position across the obstacle. All appended segments are
  rechecked at submission, and a continuation prepared during a turn waits for
  the heading to stabilize. Beyond the checked horizon, later obstacles can
  still require another local search.
- Extension starts before the remaining route falls below approximately
  2 km, increased as necessary for the commanded speed. Another continuation
  requires actual progress, so a stationary ship does not repeatedly submit
  the same short route.
- A failed routine extension does not immediately stop a ship whose current
  position and entire installed remainder still pass their depth checks. Outside
  a turn, the planner tries a replacement from the **actual position and course**,
  using a fresh window instead of the failed future anchor. A complete, checked
  replacement is installed only after preparation succeeds.
- If this attempt also fails, the existing native route remains in place while
  its remaining length exceeds the stopping threshold. Another extension and,
  if needed, replacement attempt is allowed after 250 m of projected route
  progress. Depth checks and target-release checks continue on every regular
  tick; a stationary ship does not repeatedly search the same area.
- During a turn, a failed extension retains the checked route without replacing
  it. Once the course stabilizes, the actual-position replacement is tried even
  without another 250 m of progress. A successfully prepared continuation still
  waits for the end of the turn before submission.
- The stopping threshold is `max(400, speed * 60) + speed * 10` meters, using the
  greater of actual and commanded speed in m/s. The final term accounts for the
  next regular check. At this threshold, a straight-running ship gets one last
  planning attempt regardless of the progress gate; failure stops it. A turning
  ship stops there without attempting an abrupt replacement. The same threshold
  applies to route submission. There are no repeated searches from `Holding`.
- Local steering points do not generate normal mission waypoint events. The
  original waypoint is processed through OPSGROUP when the actual ship is close
  to it (50â€“150 m, depending on speed). The native local route contains no
  waypoint callbacks; early DCS notifications cannot advance the mission.
  Queued waypoint tasks retain control while their
  native startup callback is pending, and the ordinary route resumes after
  those tasks finish.
- During turns on an active local detour, depth monitoring continues. A
  continuation can be prepared but normal route replacement waits for the
  heading to stabilize. Explicit speed and depth changes also remain pending
  until they can be submitted.
- DCS controls the turning radius between waypoints. Departing from the straight
  planned segments does not itself stop the ship or trigger another search.
  The two-second nearfield check always covers the live hull and heading.
  During a turn, the ten-second route check uses the ship position and stored
  route; after the turn it also validates the connection from the actual position to the
  next local point. A clear connection keeps the route in place, while a blocked
  connection can trigger a replacement as described below.
- Segment progress stays on contiguous route legs. Near a corner it can advance
  to the immediately following leg when that leg is closer. It also recognizes
  an already adopted outgoing course: positive projection onto the next leg,
  heading within 20 degrees of that leg, at least 75 degrees back towards the
  old corner, and lateral distance no greater than `max(150, speed * 20)` meters.
  This extra rule applies only within the existing corner neighborhood (at least
  500 m). It cannot jump to a nonadjacent return leg or advance a mission waypoint.
- If the ship position is valid but the remaining route becomes blocked, local
  navigation attempts a replacement from the current position and heading.
  It discards the prepared continuation and rebuilds the search window, so the
  blocked approach and its cached checks are not reused. The replacement must
  pass route validation before submission. This response does not run during
  a turn or when depth data is unavailable.

## Failure and limits

A failed initial search, an invalid ship position, a blocked or unavailable
nearfield, unavailable depth data on the checked route or an exhausted route
reserve causes `FullStop()`. A failed routine
extension can retain a still-clear installed remainder and retry after progress,
but it cannot authorize travel beyond that remainder or consume the stopping
reserve. If the installed remainder itself becomes blocked, a failed replacement
still stops immediately. A blocked remainder during a turn or a replacement
rejected at submission also stops navigation.

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
a safe alternative can also lie beyond the bounded corner adjustments. The stopping reserve is a prototype
margin, not a measured braking model. A geometrically valid route therefore
still needs validation with the intended ship and mission speed in DCS.

With trace enabled, `Local route point` lists the actual waypoints submitted to
DCS, identified by route number. `Local route segment` records changes to the
tracked segment, their reason, actual heading, next point and bearing. These
are the steering points, not the green raw A* path shown by the debug overlay.
Depth evidence is split into `Naval depth check`, `Naval depth position` and,
when available, `Naval depth segment` lines so DCS does not truncate coordinates.
Nearfield failures additionally report `Naval nearfield` with the affected unit,
hull dimensions, speed, lookahead and clear distance measured from the bow.
Stages `ship_hull`, `ship_lookahead` and `nearfield` distinguish an occupied-hull
obstruction, an obstruction ahead and unavailable short-check depth data.

`LastPathfindingResult` records the latest local plan or failure. Local plans
include candidate attempts, spacing, candidate-cell count and whether the
window was reused. `Steering` records simplification states, backtracks,
constraint counts and `CornerAdjustments` (original and adjusted positions) for
the selected candidate. `SteeringFailures` retains rejected candidates from the
latest search, including on a final stop. Prepared plans also record `Length`, `InitialTurn`,
`RequiredLength` and `PreflightExtensions`; `Attempts` includes the searches
for appended sections. `Points` contains the combined steering route, while
`Window` and the raw `Path` refer to the last contributing search window.
`RejoinPoint` and `TargetApproachDistance` identify an appended target approach;
that approach has no additional grid and is not included in the raw A* overlay.
Trace output reports the original target UID, number of
native route points, remaining validated distance and whether the original
goal is included, as well as the initial turn, required length and number of
preflight extensions. `Local route prepared` records an appended continuation.
`Local extension failed: ... ==> replan from ship` identifies recovery from a
failed future-anchor search. `Local extension deferred: ... ==> keep route`
records continuation/replacement failure reasons and the checked remaining
length versus the stopping threshold, independently of trace settings.
`LastPathfindingResult.ExtensionFailure` retains `Reason`, `ReplacementReason`,
`Remaining`, `Reserve` and `AwaitingStraight`. A successful replacement retains
its triggering extension failure in this field as well. A stop at the threshold
reports `local_route_exhausted` (or `local_route_exhausted_in_turn`) and includes
`Remaining`, `Reserve` and the last extension failure when available.
`Local navigation activated` records the measured clear distance, activation
threshold and forward window extent at the start of avoidance. While waiting
after a distant warning, `LastNavigationCheck.LocalSearchDistance` and
`LocalSearchAhead` contain these planning distances without allocating a grid.
`Local route target approach: ... ==> keep detour and append checked approach`
records the checked connection from a future local endpoint towards the target.
With the existing verbose grid drawing enabled, the overlay
shows the latest local search and its raw path, not an entire canal route.
`Local navigation finished: ... ==> ordinary route` marks the handover after
a clear target horizon; it does not mean the ship has reached the waypoint.
`Local route deviation` records departures greater than 150 m (or the corridor
width, if wider) for diagnosis only. It includes the assigned segment endpoints,
actual ship position, heading and turn state. An unchanged segment/turn state is
not logged repeatedly; the notice resets when the ship rejoins the line or a
replacement route is installed. Local depth reports also retain `RouteDeviation`.

Before a depth-related stop or replacement search, `Naval depth check` logs the
action, check stage, segment, cause, measured and required depth, surface type,
profile offset, failing point and current ship position/heading/turn state.
This diagnostic is emitted independently of trace settings and uses the
existing check result without further terrain queries. `ship_position` means
the ship center itself failed; `actual_position_to_next`, `stored_segment` and
`submission_connector` identify route checks. `target_lookahead` identifies the
normal collision horizon used to decide whether to leave avoidance.
Rejected target checks are also logged: `action=continue_local` with
`stage=target_lookahead` explains why the current ship position cannot yet return
to ordinary routing. `action=local_extension` with `stage=route_end_lookahead`
explains why another local search is needed from the proposed endpoint.
These messages include the target UID and checked start/end positions as well
as the failing profile point. Unchanged failure causes are logged at most once
per 60 simulation seconds for each stage, independently of trace settings.
No extra terrain queries are made for these target-check logs. `target_turn`
and `route_end_turn` identify blocked manoeuvring allowances despite a clear
straight target profile. The actual-position check is retained in local state
as `TargetTurnCheck`; a rejected appended approach records it in the proposed
plan. A clear endpoint requiring more than a 90-degree corner is rejected
separately in trace output.

When no candidate yields a usable steering route, `Local steering rejected`
and `Local steering constraint` explain each candidate independently of trace.
Rejection counts distinguish short/long legs, short residual sections, excessive
course changes, failed depth checks, higher-cost shortcuts and blocked corner
allowances. They count shortcut attempts, not new A* searches. Each constraint
includes a representative pair of node indices and position, measured distance
and angle, and the relevant limit, cost or allowance radius. A separate
`Local steering depth` line records unavailable data or the concrete failed
surface/depth sample. A weighted edge rejected as impassable is queried once
more for this detailed evidence; repeated alternatives reuse it. Trace output
`Local steering adjusted` identifies selected routes with moved corners.
A successful replacement retains
its triggering report in `LastPathfindingResult.ReplanDepthCheck`; a failure
with a depth report records it in `LastPathfindingResult.DepthCheck`.

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
   still clear. Look for a replacement from the actual ship position, or a
   deferred-extension message with remaining distance and stopping threshold.
   Confirm that failed retries require progress, turns do not receive abrupt
   replacements, and the ship stops by the reserve if no continuation succeeds.
   A dead end must still cause a single persistent stop without retries from
   `Holding`, including after later timer ticks.
6. Test an original waypoint with a task, a manual stop/resume, an explicit
   `GotoWaypoint()` followed by `Detour()`, and switching between both modes.
   Confirm that the route and collision check follow the same destination.

Standalone regressions run from the repository root with
`lua tests/navy-local.lua`. They use synthetic terrain and route/task spies;
they do not establish how the DCS ship controller will steer a real hull.
