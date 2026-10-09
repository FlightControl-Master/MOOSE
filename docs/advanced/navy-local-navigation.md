---
title: Naval pathfinding
parent: Advanced
nav_order: 7
---

# Naval pathfinding

## LOCAL has been removed

The experimental local pathfinding integration was removed from NAVYGROUP on
2026-10-09 for a staged rebuild. Shared local-search functionality in ASTAR and
GRID remains available. The [development plan](../developer/rolling-pathfinding-plan.md)
records the reasons, retained components and validation gates for the rebuild.

The constant `NAVYGROUP.PathfindingMode.LOCAL` remains recognized, but this call
now raises a Lua error before changing the mode, route, movement state or drawings:

```lua
navy:SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL)
```

The error is:

```text
NAVYGROUP: LOCAL pathfinding mode has been removed; local navigation is unavailable pending a rebuild
```

There is no silent fallback to global search. `SetPathfindingWorkBudget()`,
`LastLocalPlanningReport` and local planning, steering, continuation and drawing
state have been removed. Old LOCAL mission scripts require an intentional
change or must wait for the rebuild. Selecting WAYPOINT requests different
behavior; it is not an equivalent replacement for rolling local navigation.

## Full-waypoint search

`NAVYGROUP.PathfindingMode.WAYPOINT` remains the default and the only available
naval search mode. Both naval search designs are still under development.

```lua
local navy = NAVYGROUP:New("Canal ship")

navy:SetPathfindingMinDepth(20) -- meters; choose for the vessel and terrain
navy:SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
navy:SetPathfindingOn()
```

Selecting the mode does not enable pathfinding, create a grid or release
`Holding` / `Waiting`. Calling `SetPathfindingMode()` without an argument selects
WAYPOINT. `SetPathfindingOff()` disables automatic planning and stops due to
pathfinding, while ordinary collision warnings remain active.

The group initially follows its mission route. Every ten simulation seconds,
when movement is allowed and the group is not turning, it checks the direct
connection towards its commanded waypoint, up to 5000 m ahead. An obstruction
triggers a search all the way to the original destination beyond any pending
ASTAR detour points. Missing depth data is a failure, not an obstacle to work
around by enlarging the grid.

The planner uses a hexagonal GRID with `GRID.Resolution.FINE`,
`GRID.Width.NORMAL` and `GRID.Margin.NORMAL`. Optional bounds are configured with:

```lua
navy:SetPathfindingGrid(5000, 1.5, 5) -- candidate cells, growth factor, attempts
```

Short connections retain a minimum search width of twice the safety corridor
(at least 2000 m), and a margin of one safety corridor (at least 1000 m).
Grid spacing remains fixed during expansion.

Only a successful search replaces outstanding detour points. The destination's
altitude/depth and the commanded speed are preserved. Explicit `GotoWaypoint()`
targets survive speed/depth changes; later detours or mission progression can
replace them. A failed search records `LastPathfindingResult` and commands
`FullStop()`; a new movement command is needed to resume. There are no automatic
planning retries.

The search checks sampled straight connections. It does not predict the
ship's rounded turns or prove that the DCS controller can execute the path.

## Depth rules and costs

`SetPathfindingMinDepth()` defaults to 20 m and applies to searches and collision
checks. The optional total corridor width is supplied to `SetPathfindingOn(width)`.
Its default is the widest ship plus 10 m on each side, or 50 m if dimensions are
unavailable. Width zero checks only the center line. Center and edge profiles
are sampled checks, not complete coverage of the intervening area.

An optional preference can trade a longer route for greater depth:

```lua
navy:SetPathfindingMinDepth(20)          -- hard minimum, inclusive
navy:SetPathfindingPreferredDepth(30, 2) -- preferred depth and penalty strength
```

The preference is disabled by default. Its weight defaults to 2 when enabled.
At 30 m and deeper, a route section costs its horizontal length. Between 20 m
and 30 m, a quadratic penalty increases the cost: at 25 m the multiplier is
1.5, at 21 m it is 2.62, and at 20 m it is 3. Water below 20 m remains blocked.

Costs integrate over terrain profile distances, assuming linear depth between
samples. With a corridor, the shallowest interpolated center/edge profile
determines the penalty at each distance. A* shares depth validity/cost queries
and retains the straight-line heuristic.

Collision checks use only the hard minimum. Changing the preference affects
new searches and leaves the installed route active. `SetPathfindingPreferredDepth()`
without arguments disables it; weight zero or a preferred depth at/below the
minimum adds no penalty.

For standalone ASTAR searches, configure the neighbour rule before the cost:

```lua
astar:SetValidNeighbourDepth(20, 50)
astar:SetCostDepth(30, 2)
```

`SetCostDepth()` restores distance costs. Changing the depth rule updates its
dependent costs; choosing a different neighbour rule restores distance costs
when the depth preference was active.

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

### Short hull and heading check

With pathfinding enabled, the navigation timer inspects every live ship every
**two simulation seconds**, including during turns and before normal route
planning. Ordinary waypoint collision checks retain their ten-second cadence.
Both checks share the same timer.

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

## Measurements and display

Measurements are disabled by default:

```lua
navy:SetPathfindingDiagnostics(true)
-- Later, between navigation updates:
navy:SetPathfindingDiagnostics(false)
navy:LogPathfindingDiagnostics()
local metrics = navy:GetPathfindingDiagnostics()
```

Disabling freezes the interval; enabling again starts a fresh one. Repeated
`true` keeps the active interval. The getter returns an independent snapshot.
Aggregate metrics are logged only by `LogPathfindingDiagnostics()`.

- `SearchAttempts` counts completed waypoint expansion searches, including
  no-path results.
- `ValidityRequests` / `ValidityCacheHits` and `CostRequests` / `CostCacheHits`
  count ASTAR lookups. A combined depth evaluation can populate both caches.
- `ProfileQueries` counts actual ASTAR/PATHLINE native profile calls in measured
  scopes, including unavailable results and errors. Direct surface/seabed
  samples and unrelated profile users are excluded.
- `RouteSubmissions` counts issued commands, including full stops, rather than
  controller acceptance, physical movement or arrival.
- `PeakRetainedCells` is the maximum sampled sum of distinct measured/displayed
  grids' accepted cells, not bytes or an exact instantaneous memory peak.
- `Scopes`, `Errors`, `CPUSeconds`, `MaxScopeCPUSeconds` and `Operations`
  describe navigation, planning and route-update scopes. Nested work contributes
  once to aggregate CPU/profile counts. Per-operation CPU is inclusive and must
  not be summed. Exceptions are recorded and then propagated.

CPU fields remain `nil` without a usable `os.clock`; simulation and wall time
are not substitutes. Comparisons require the same source, terrain, route,
vessel, speed, safety/cost settings and debug options. Simulation acceleration
is separate from CPU time, and these measurements do not measure FPS.

At `navy.verbose >= 10`, a successful WAYPOINT search draws its grid and path
using ASTAR's existing display. The next search, pathfinding disable, failure
or group stop clears the group's retained overlay. Other groups' marks remain.
There is no separate LOCAL steering overlay.

## Validation

Run `tests/navy-pathfinding.lua` and the affected WAYPOINTS, ASTAR and GRID
suites in separate Lua 5.1 processes. The naval suite covers the removal error,
normal waypoint planning, target ownership, common safety and diagnostics.
Standalone ASTAR local-search regressions remain in `tests/astar.lua`.

Stubbed regressions do not validate DCS controllers, terrain or ship physics.
Use a fresh mission with the updated source/include for simulator validation.
The removed LOCAL mode cannot be tested as a working navigation mode.
