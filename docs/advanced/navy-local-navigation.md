---
title: Local naval navigation
parent: Advanced
nav_order: 7
---

# Local naval navigation

`NAVYGROUP.PathfindingMode.LOCAL` is an experimental alternative to searching
all the way to the next original waypoint. Both modes initially follow the
ordinary mission route. Only an obstacle detected by the regular collision
check activates a search; selecting `LOCAL` does not create a grid.

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

- While local avoidance is inactive, the regular collision check examines up to
  5 km towards the next native waypoint every ten seconds. It skips turns. An
  explicit `GotoWaypoint()` destination is respected even before a waypoint
  callback advances mission progress. Missing depth data stops navigation
  without starting a search.
- Each fixed hex window extends 3 km ahead, 1 km behind and 1 km to each side of
  its planning origin. `GRID.Resolution.FINE` gives approximately 50 m center
  spacing. Planning a continuation moves the origin to a future route anchor.
- The existing `SetPathfindingGrid()` cell limit applies (5,000 by default).
  Local mode does not use its expansion factor or attempt limit; it never
  expands into a global search. An insufficient cell budget stops planning.
- Up to eight original-goal or front/side exit candidates are tried using one
  ASTAR instance. Depth-edge caches are reused within that window. A new window
  is built after sufficient movement, heading, target or configuration changes.
- Candidate selection prefers enough usable route length over a short side exit.
  Initial course changes and missing route length also increase the candidate's
  cost. The preparation target is the usual extension horizon (at least 2 km,
  or the stopping reserve plus 1 km), with up to one additional stopping reserve
  for an initial turn of 90 degrees. This allowance scales with speed; it is not
  a measured turning-radius model.
- Before departure, a short selected route receives up to two checked local
  continuations if its endpoint cannot already connect towards the target.
  Each starts at the previous endpoint with its incoming course,
  retains every existing steering point, and uses the same depth/corridor rules.
  This also applies to replacement routes and routine extensions. The combined
  remainder is rechecked before submission. If preparation fails or remains too
  short, no partial movement route is sent and the ship stops. A route reaching
  the original destination does not need this non-goal length allowance.
- Every connection and every simplified shortcut uses the configured minimum
  depth and corridor width. Without an explicit width, the widest ship plus
  10 m on each side determines that corridor.
- During an active local detour, only the validated local remainder is sent to
  DCS. Distant original waypoints are never appended behind a local exit.
  Original waypoints and their task queues remain stored in NAVYGROUP.
- Every regular navigation tick outside a turn also checks up to 5 km directly
  towards the original target, or the whole distance if it is closer. A clear
  corridor ends local avoidance before further local checks or extensions.
  The search window, prepared continuation and drawing are discarded; target,
  commanded speed/depth and waypoint tasks are retained. This is a return to
  ordinary routing, not an arrival event or proof that the entire remaining
  route is clear. Normal collision monitoring continues and can start a new
  local detour for another obstacle. Missing depth data causes a stop.
- Changing the destination discards the old local detour. The new leg starts
  with ordinary route following and collision checks again. Speed and depth
  commands for the same destination retain the active detour.
- Routine extension preserves approximately 1 km of the installed approach, where
  available, if another local search is needed. Before trimming to this anchor,
  the planner checks the target horizon from the **last point of the full
  installed route**. If that corridor is clear and the course change is at most
  90 degrees, it keeps every remaining corner and appends up to 5 km towards the
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
- Local steering points do not generate normal mission waypoint events. The
  original waypoint is processed through OPSGROUP when the actual ship is close
  to it (50–150 m, depending on speed). The native local route contains no
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
  During a turn, checks cover the actual ship position and stored route; after
  the turn they also validate the connection from the actual position to the
  next local point. A clear connection keeps the route in place, while a blocked
  connection can trigger a replacement as described below.
- If the ship position is valid but the remaining route becomes blocked, local
  navigation attempts a replacement from the current position and heading.
  It discards the prepared continuation and rebuilds the search window, so the
  blocked approach and its cached checks are not reused. The replacement must
  pass route validation before submission. This response does not run during
  a turn or when depth data is unavailable.

## Failure and limits

A failed local search, an invalid ship position, unavailable depth data
or exhausted route reserve causes `FullStop()`.
A blocked remainder during a turn or a rejected replacement route also stops
navigation. Navigation stays stopped until an
explicit movement command such as `Cruise()` is issued. There is no automatic
retry, reverse recovery or guaranteed escape from a dead end.

This prototype may miss a passage because of grid spacing, bounded candidate
selection or its steering filters. It checks straight center and edge profiles;
it does not model the full swept hull area, formation offsets, other moving
ships or the actual DCS turning radius. The stopping reserve is a prototype
margin, not a measured braking model. A geometrically valid route therefore
still needs validation with the intended ship and mission speed in DCS.

`LastPathfindingResult` records the latest local plan or failure. Local plans
include candidate attempts, spacing, candidate-cell count and whether the
window was reused. Prepared plans also record `Length`, `InitialTurn`,
`RequiredLength` and `PreflightExtensions`; `Attempts` includes the searches
for appended sections. `Points` contains the combined steering route, while
`Window` and the raw `Path` refer to the last contributing search window.
`RejoinPoint` and `TargetApproachDistance` identify an appended target approach;
that approach has no additional grid and is not included in the raw A* overlay.
Trace output reports the original target UID, number of
native route points, remaining validated distance and whether the original
goal is included, as well as the initial turn, required length and number of
preflight extensions. `Local route prepared` records an appended continuation.
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
No extra terrain queries are made for logging. A clear endpoint requiring more
than a 90-degree corner is rejected separately in trace output.
A successful replacement retains
its triggering report in `LastPathfindingResult.ReplanDepthCheck`; a failure
with a depth report records it in `LastPathfindingResult.DepthCheck`.

## Suggested DCS test

1. Start with one ship in open water, using a modest mission speed. Confirm that
   `LOCAL` follows the normal route without creating a search grid.
2. Place a bend or obstacle on the route, with the original destination well
   beyond the first local window. Confirm that the collision check activates
   local avoidance when it detects the obstruction within its 5 km lookahead.
3. Confirm that the active route extends while the target direction remains
   blocked, then returns to ordinary routing once its collision horizon clears.
   No further local searches should run in clear water. Watch for bank contact,
   abrupt steering and unwanted route replacement during turns.
4. Test a second obstacle on the same leg and verify a fresh local activation
   when it enters the collision horizon. Confirm that the original destination
   and its tasks are processed only when actually reached.
5. Test a dead end and confirm a single persistent stop, including after later
   timer ticks.
6. Test an original waypoint with a task, a manual stop/resume, an explicit
   `GotoWaypoint()` followed by `Detour()`, and switching between both modes.
   Confirm that the route and collision check follow the same destination.

Standalone regressions run from the repository root with
`lua tests/navy-local.lua`. They use synthetic terrain and route/task spies;
they do not establish how the DCS ship controller will steer a real hull.
