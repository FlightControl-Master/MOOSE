---
title: AIRBOSS / NAVYGROUP migration
parent: Advanced
nav_order: 02
---

# AIRBOSS / NAVYGROUP migration

This guide describes the integration on branch `FF/AirbossNavy`, as of 20 September 2026. It documents that branch's API; it does not imply these changes are available in every MOOSE release.

## Responsibilities and object access

AIRBOSS remains an FSM for flight operations. It holds a separate NAVYGROUP in `airboss.navygroup`; it does not inherit NAVYGROUP or OPSGROUP.

| Object | Responsibility |
| --- | --- |
| AIRBOSS | Recovery windows and extensions, marshal, pattern, players, LSO grading and flight radio calls |
| NAVYGROUP | Route, waypoints, detours, pathfinding, turning and into-wind movement |
| OPSGROUP, through NAVYGROUP | Shared group management and navigation beacons |

`airboss:GetState()` reports flight operations; `airboss.navygroup:GetState()` reports navigation. The carrier can be cruising while AIRBOSS is recovering aircraft or stopped.

```lua
local airboss = AIRBOSS:New("CVN-73", "Washington")
airboss:SetTACAN(74, "X", "WAS")
airboss:SetICLS(1, "WAS")
airboss:SetPatrolAdInfinitum(true)
airboss:AddRecoveryWindow("08:45", "09:45", 1, nil, true, 25, true)
airboss:Start()

-- Access navigation through the existing object.
local navygroup = airboss.navygroup
local navigationState = navygroup:GetState()
```

Use one AIRBOSS per naval group and separate groups for multiple managed carriers. The constructor can reuse an existing NAVYGROUP for the group. Repeated construction and conflicting owners are not fully guarded: create AIRBOSS once and reuse it. A restart rejects a NAVYGROUP currently linked to another AIRBOSS. The selected carrier unit supplies AIRBOSS position, deck geometry and beacon activation, including in groups with escorts.

## Start, Stop and restart

NAVYGROUP has its own timers and event handling from construction. `AIRBOSS:Start()` starts flight management on that object.

`AIRBOSS:Stop()`:

- Closes the active recovery window and cancels the wind maneuver requested by this AIRBOSS, including preparation for a future window.
- Clears AIRBOSS timers, delayed work, queued radio calls, event handlers and its F10 menus; detaches its NAVYGROUP callback reference.
- Keeps future recovery windows, player preferences and completed scores.
- Leaves NAVYGROUP, its beacons and existing DCS aircraft tasks running. Already playing audio may finish.

On `Start()` again, AIRBOSS requires a living carrier, restores its callbacks and menus, reconciles tracked flights and checks the retained windows against current mission time. Dead flights and completed AI recoveries are removed from tracking as appropriate; surviving AI marshal tasks are updated. Players must request their approach again. Landing events missed while stopped do not produce retrospective grades.

```lua
airboss:Stop()  -- NAVYGROUP continues navigating.
-- Later, while the selected carrier is alive:
airboss:Start()
```

`RecoveryStop()` ends recovery operations while AIRBOSS remains running. `CarrierResumeRoute()` is a navigation command and does not itself close the recovery window.

## Public API migration

| Previous interface | Current interface / action |
| --- | --- |
| `CarrierDetour(coord, speed, uturn, uspeed, tcoord)` | `airboss.navygroup:Detour(coord, speed, depth, resumeRoute)`. Speed is knots, depth is meters (normally `nil` for carriers). Pass `true` to resume the route after arrival; false/nil holds at the destination. Separate return speed, U-turn and smoothing coordinate have no direct equivalent. |
| `SetCollisionDistance(distance)` | Remove the call. NAVYGROUP owns collision checks. Its `SetPathfinding(...)` and `SetPathfindingMinDepth(...)` configure route planning, but are not equivalents of the old collision-distance setting. |
| `SetBeaconRefresh(interval)` | Remove the call. Automatic periodic TACAN/ICLS refresh has been removed. |
| `GetHeadingIntoWind_old(...)` / `GetHeadingIntoWind_new(...)` | Use `GetHeadingIntoWind(vdeck, magnetic)` and select the algorithm with `SetIntoWindLegacy(true/false)`. |
| Third coordinate argument to `GetHeadingIntoWind` | Removed. Calculation uses the NAVYGROUP's current wind data. |
| `OnAfterPassingWaypoint(..., waypointNumber)` | Receives an `OPSGROUP.Waypoint` record. Use `Waypoint.uid` for identity; do not treat it as a mission-editor index. |
| Internal `_GetETAatNextWP()` | Removed. For an estimate use `airboss.navygroup:GetTimeToWaypoint(index)`: duration in seconds based on current velocity, default next waypoint. The argument is a route index, not a UID. Handle a stopped ship before presenting an ETA. |
| Temporary integration name `GetCarrierCoordinate()` | Use `GetCoordinate()`; `GetVector()` provides a lightweight position snapshot. |

The former AIRBOSS routing, pathfinding and turning helpers were removed. Scripts should use public NAVYGROUP methods instead of calling those private helpers or reading removed AIRBOSS fields such as `waypoints`, `currentwp`, `detour` and `Creturnto`.

Retained AIRBOSS forwarding setters such as `SetPatrolAdInfinitum` and `SetIntoWindLegacy` return AIRBOSS for chaining. Direct calls on `airboss.navygroup` follow NAVYGROUP's own return contracts.

### Detour example

```lua
-- destination is a COORDINATE. Execute outside an AIRBOSS-owned recovery maneuver.
airboss.navygroup:Detour(destination, 20, nil, true)
```

The new call resumes the normal route after the detour point. It does not recreate the old AIRBOSS return leg. Coordinate direct navigation commands with the recovery schedule so they do not compete with its into-wind maneuver.

### Waypoint callback

```lua
function airboss:OnAfterPassingWaypoint(From, Event, To, Waypoint)
  self:I(string.format("Passed waypoint UID=%d", Waypoint.uid))
end
```

Regular dynamically added route waypoints are reported as well as mission-editor waypoints. OPSGROUP handles its internal temporary, pathfinding and detour points separately. Route indices can change when waypoints are inserted or removed; a waypoint's UID identifies its record within that NAVYGROUP.

## Recovery and wind contracts

| Method | Time arguments | Wind and heading units |
| --- | --- | --- |
| `AIRBOSS:AddRecoveryWindow(start, stop, case, holdingoffset, turnintowind, speed, uturn)` | Clock strings, including `+1` for next day, or numeric offsets **both from now**. Default stop: 90 minutes after start. | Desired wind over deck in **knots**, default 20; holding offset in degrees. |
| `NAVYGROUP:AddTurnIntoWind(start, stop, speed, uturn, offset, options)` | Start: clock string or seconds from now. Stop: clock string or numeric **duration from start**. Default duration: 90 minutes. | Desired deck wind in **knots**; runway offset in degrees. |
| `AIRBOSS:CarrierTurnIntoWind(time, vdeck, uturn)` | Duration in seconds, starting now. | Desired deck wind in **m/s**. Navigation only; does not open recovery. Default U-turn false. |
| `AIRBOSS:GetHeadingIntoWind(vdeck, magnetic)` | No time arguments. | Input wind in **knots**; returns heading in degrees and carrier speed in knots. True heading by default; magnetic if `magnetic=true`. |
| `AIRBOSS:GetBRCintoWind(vdeck)` | No time arguments. | Input wind in **knots**; returns magnetic heading in degrees **and** carrier speed in knots. |

For example, `airboss:AddRecoveryWindow(600, 1800, ...)` opens in 10 minutes and closes in 30 minutes, giving a 20-minute window. A NAVYGROUP maneuver with the same two numeric arguments would start in 10 minutes and last 30 minutes. Prefer clock strings when matching schedules across APIs.

`AddRecoveryWindow` returns a recovery record when accepted, but returns the AIRBOSS object for rejected timing. `AddTurnIntoWind` returns a maneuver record or `nil` for rejected timing. `CarrierTurnIntoWind` returns AIRBOSS even when ignored because AIRBOSS is stopped or already owns a maneuver.

AIRBOSS retains the recovery schedule and decides opening, closing and extensions. Its recovery maneuvers are externally managed NAVYGROUP windows: their deadline is informational until AIRBOSS explicitly ends them. Direct NAVYGROUP users normally leave `ExternallyManaged` false; if enabled, the caller must end or remove the maneuver. `ExtendTurnIntoWind` can update its planned end, but does not restore automatic termination for externally managed windows.

The lead time for preparing an AIRBOSS recovery maneuver is set by `SetRecoveryTurnTime`, initially 300 seconds. `RecoveryPause` holds the into-wind course while the window clock continues. Pattern-related extension is still considered at the planned end.

For recovery windows, U-turn defaults to enabled. NAVYGROUP records a significant departure when the required heading change exceeds 5 degrees and wind is at least 0.1 m/s. Only then does an enabled U-turn return to the original route departure point. Consecutive compatible windows preserve that point, and the final window's U-turn flag decides the final return. Disabling U-turn continues directly to the next route waypoint.

Desired deck wind is a target, not a ship-speed command or a guarantee: heading and speed depend on ambient wind, runway angle and ship limits. `GetHeading()` and `GetFinalBearing()` also return true degrees by default; pass `true` for magnetic degrees.

## TACAN and ICLS

The existing `SetTACAN`, `SetICLS`, `SetTACANoff` and `SetICLSoff` methods delegate beacon management to NAVYGROUP/OPSGROUP using the selected carrier unit. TACAN defaults to 74X/STN; ICLS defaults to channel 1/STN.

- Before Start or after Stop, the on-setters store the AIRBOSS configuration for the next Start. While running, they switch the beacon immediately.
- The off-setters disable startup activation and switch off the beacon immediately only while AIRBOSS is running.
- Stop leaves active beacons running. Calling an off-setter after Stop does not turn an already active beacon off, and disabled startup activation does not itself send a turn-off command on restart.
- There is no automatic periodic refresh. Start activates enabled beacons again.

For immediate shutdown after AIRBOSS has stopped:

```lua
airboss:SetTACANoff()             -- Disable activation by the next AIRBOSS Start.
airboss.navygroup:TurnOffTACAN()  -- Turn off the currently active beacon.
airboss:SetICLSoff()
airboss.navygroup:TurnOffICLS()
```

## Position objects

All three getters refer to the selected carrier unit and may return `nil` when its position is unavailable.

| Getter | Result and ownership |
| --- | --- |
| `GetVector()` | New, independent VECTOR position snapshot for geometry calculations. |
| `GetCoordinate()` | New, independent COORDINATE snapshot for APIs requiring COORDINATE. The original AIRBOSS implementation reused the carrier cache. |
| `GetCoord()` | Shared carrier COORDINATE cache, updated on access. Retaining or modifying it can affect other users of that object. |

VECTOR is mutable: `vector:Translate(distance, heading)` changes it in place; pass a third argument of `true` to obtain a translated copy. Geometry uses VECTOR internally where practical. COORDINATE remains at interfaces that require it, such as SRS, day/night calculations and route boundaries. Zone reuse was left at the original behavior.

## Remaining validation

The CASE-I AI Hornet test confirmed landing and removal from the pattern queue after the deck obstruction was removed. TACAN and ICLS were accepted in the mission test. The new Start/Stop cleanup has isolated checks, but its DCS Stop/Start test is still pending. Player approaches, CASE II/III, VTOL and carrier loss/respawn need dedicated coverage. Constructor ownership and carrier loss with surviving escorts remain separate implementation work.
