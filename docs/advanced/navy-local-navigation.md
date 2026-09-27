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
water until it reaches the original destination. A distant waypoint provides a
preferred direction, not a requirement to get closer on every section. After
arrival, the ship resumes its ordinary route and waits for the next obstacle
before starting another local search.

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
ship is not left with only the old short route.

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
- Every connection and every simplified shortcut uses the configured minimum
  depth and corridor width. Without an explicit width, the widest ship plus
  10 m on each side determines that corridor.
- During an active local detour, only the validated local remainder is sent to
  DCS. Distant original waypoints are never appended behind a local exit.
  Original waypoints and their task queues remain stored in NAVYGROUP. Clear
  water on an intermediate leg does not end avoidance prematurely.
- Changing the destination discards the old local detour. The new leg starts
  with ordinary route following and collision checks again. Speed and depth
  commands for the same destination retain the active detour.
- Replanning preserves approximately 1 km of the installed approach, where
  available. It starts before the remaining route falls below approximately
  2 km, increased as necessary for the commanded speed. Another continuation
  requires actual progress, so a stationary ship does not repeatedly submit
  the same short route.
- Local steering points do not generate normal mission waypoint events. The
  original waypoint is processed through OPSGROUP when the actual ship is close
  to it (50–150 m, depending on speed). Early or obsolete native notifications
  do not advance the mission. Queued waypoint tasks retain control while their
  native startup callback is pending, and the ordinary route resumes after
  those tasks finish.
- During turns on an active local detour, depth monitoring continues. A
  continuation can be prepared but normal route replacement waits for the
  heading to stabilize. Explicit speed and depth changes also remain pending
  until they can be submitted.

## Failure and limits

A failed local search, unavailable depth data, excessive route deviation or
exhausted route reserve causes `FullStop()`. Navigation stays stopped until an
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
window was reused. Trace output reports the original target UID, number of
native route points, remaining validated distance and whether the original
goal is included. With the existing verbose grid drawing enabled, the overlay
shows the latest local search and its raw path, not an entire canal route.

## Suggested DCS test

1. Start with one ship in open water, using a modest mission speed. Confirm that
   `LOCAL` follows the normal route without creating a search grid.
2. Place a bend or obstacle on the route, with the original destination well
   beyond the first local window. Confirm that the collision check activates
   local avoidance when it detects the obstruction within its 5 km lookahead.
3. Confirm that the active route extends before the ship reaches its local
   endpoint and stays active until the original destination. Watch for bank
   contact, abrupt steering and unwanted replanning during turns.
4. At the original destination, confirm that normal navigation resumes. Test
   another obstacle on a later leg and verify a fresh local activation.
5. Test a dead end and confirm a single persistent stop, including after later
   timer ticks and after an obsolete waypoint callback.
6. Test an original waypoint with a task, a manual stop/resume, a changed
   destination and switching back to `WAYPOINT` mode.

Standalone regressions run from the repository root with
`lua tests/navy-local.lua`. They use synthetic terrain and route/task spies;
they do not establish how the DCS ship controller will steer a real hull.
