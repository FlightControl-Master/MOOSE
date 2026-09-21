---
title: AIRBOSS / NAVYGROUP migration
parent: Advanced
nav_order: 02
---

# AIRBOSS / NAVYGROUP migration

This guide describes AIRBOSS **2.0.0** and NAVYGROUP **1.1.0** on branch `FF/AirbossNavy`, as of 21 September 2026. These are the versions implemented on this branch; they do not imply these changes are available in every MOOSE release.

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

`RecoveryStop()` ends recovery operations while AIRBOSS remains running. `CarrierResumeRoute()` is a navigation command and does not itself close the recovery window. It suppresses automatic wind navigation for that recovery window, so the next status check does not immediately recreate the maneuver.

`Idle()` also finishes the active recovery and its own wind maneuver. Future windows remain scheduled.

## Public API migration

| Previous interface | Current interface / action |
| --- | --- |
| `CarrierDetour(coord, speed, uturn, uspeed, tcoord)` | `airboss.navygroup:Detour(coord, speed, depth, resumeRoute)`. Speed is knots, depth is feet (normally `nil` for carriers; defaults to 0). `AddWaypoint` converts depth to meters internally. Pass `true` to resume the route after arrival; false/nil holds at the destination. Separate return speed, U-turn and smoothing coordinate have no direct equivalent. |
| `SetCollisionDistance(distance)` | Remove the call. NAVYGROUP owns collision checks. Its `SetPathfinding(...)` and `SetPathfindingMinDepth(...)` configure route planning, but are not equivalents of the old collision-distance setting. |
| `SetBeaconRefresh(interval)` | Remove the call. Automatic periodic TACAN/ICLS refresh has been removed. |
| `GetHeadingIntoWind_old(...)` / `GetHeadingIntoWind_new(...)` | Use `GetHeadingIntoWind(vdeck, magnetic)` and select the algorithm with `SetIntoWindLegacy(true/false)`. |
| Third coordinate argument to AIRBOSS `GetHeadingIntoWind` | Removed. Calculation uses the selected carrier unit's wind data. |
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

`AddRecoveryWindow` returns a recovery record when accepted, but returns the AIRBOSS object for rejected timing. `AddTurnIntoWind` returns a NAVYGROUP time-window record or `nil` for rejected timing. `CarrierTurnIntoWind` returns AIRBOSS even when ignored because AIRBOSS is stopped or already owns a wind request.

AIRBOSS owns the recovery schedule and decides opening, closing and extensions. It controls a NAVYGROUP wind maneuver directly, without creating a second time window in NAVYGROUP. Extending a recovery changes only the AIRBOSS deadline; the existing maneuver continues. The provisional `ExternallyManaged` option has been removed.

The lead time for preparing an AIRBOSS recovery maneuver is set by `SetRecoveryTurnTime`, initially 300 seconds. Recovery windows open on schedule. New approach clearances wait while their required wind maneuver is unavailable or not ready. `IsRecovering()` still describes the AIRBOSS flight-operations state, not navigation readiness. Aircraft already in the pattern keep their current approach.

`RecoveryPause` holds the into-wind course while the window clock continues. Navigation readiness cannot automatically undo a user pause. When a requested resumption is at or after the currently known window end, the pause call announces "until further notice". This changes only the announcement; pause timers and possible pattern-related extensions retain their existing behavior. Pattern-related extension is still considered at the planned end. Marshal flights are reconciled to the current recovery case before new clearances, including CASE II/III transitions.

For recovery windows, U-turn defaults to enabled. NAVYGROUP records a significant departure when the required heading change exceeds 5 degrees and wind is at least 0.1 m/s. Only then does an enabled U-turn return to the original route departure point. Consecutive compatible windows preserve that point, and the final window's U-turn flag decides the final return. Disabling U-turn continues directly to the next route waypoint.

Desired deck wind is a target, not a ship-speed command or a guarantee: heading and speed depend on ambient wind, runway angle and ship limits. `GetHeading()` and `GetFinalBearing()` also return true degrees by default; pass `true` for magnetic degrees.

### Direct NAVYGROUP wind maneuvers

The immediate maneuver API has no start or stop times. Use it when another controller, such as AIRBOSS, determines the duration:

```lua
local maneuver, reason = navygroup:BeginIntoWind({
  DeckWind = 27,       -- knots
  DeckAngle = -9.1,    -- degrees
  ReferenceUnit = carrierUnit,
  OnEnded = function(completed, endReason)
    env.info("Wind maneuver ended: " .. tostring(endReason))
  end,
})

if maneuver then
  -- Later, when a new course/speed is required:
  navygroup:UpdateIntoWind(maneuver, { DeckWind = 30 })

  -- At the end, the caller supplies the final return policy:
  local ended, endReason = navygroup:EndIntoWind(maneuver, { Uturn = true })
end
```

`BeginIntoWind` accepts at most one active wind maneuver per NAVYGROUP. A returned record means that the request was accepted; it does not mean that the ship has already reached its heading and speed. `GetIntoWindManeuver()` returns the active record, whose `Ready` flag reflects the achievable target and navigation conditions. The reference unit supplies wind, heading and speed measurements; the return point belongs to the naval group's route.

Readiness requires a submitted, checked route, no active obstacle or competing task, a heading within 2 degrees and speed within 1 knot of the command, and no ongoing turn. A checked straight pathfinding segment can be ready; an obstacle detour cannot. A competing active task or engagement rejects a new wind request with `busy`. The legacy algorithm's requested ship speed is also capped at the group's maximum for maneuver execution.

Updates preserve the maneuver identity and the first significant route departure point. `EndIntoWind` and `AbortIntoWind` return success and a reason; an optional `ReturnCoordinate` supplies an explicit intermediate destination. Ending means relinquishing the wind maneuver and arranging continued navigation, not physically arriving back on the original route. `AbortIntoWind` provides unconditional cleanup of that particular owned request, including during AIRBOSS shutdown. Neither method stops NAVYGROUP itself. Repeated completion of the same completed maneuver cannot stop a later maneuver.

The existing scheduled API is an adapter over this same movement implementation:

- `AddTurnIntoWind` puts a time window in `Qintowind`; its `Maneuver` reference is set when it starts.
- `ExtendTurnIntoWind` changes the scheduled end time.
- `GetTurnIntoWindCurrent` continues to return the active **time window**. Use `GetIntoWindManeuver` for the active physical maneuver, including one started directly by AIRBOSS.
- An occupied NAVYGROUP does not silently replace another wind request. Waiting scheduled windows expire if their end time passes before they can start.

Changing wind does not continually reissue a new carrier course. Maneuver updates are explicit; readiness is assessed against the last commanded, achievable course and speed. Pathfinding may temporarily make the ship unavailable for recovery while avoiding an obstacle.

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

## Loading and direct FLIGHTGROUP calls

The dynamic loader and static include generator both use `Modules.lua` as their source list. AIRBOSS appears before NAVYGROUP and OPSGROUP in that list, but its NAVYGROUP construction occurs when mission code calls `AIRBOSS:New()`. Construct mission objects after the complete MOOSE include has loaded. A source review found no additional load-order change required by this integration; no generated static include was executed for this review.

`FLIGHTGROUP:SetAirboss()` still assigns the AIRBOSS object. Its direct calls to `IsRecovering()`, `GetCoordinate()` and `GetHeading()` remain available. This API cross-check does not establish support-flight behavior or navigation-readiness handling in DCS.

## Validation

DCS tests on 21 September 2026 covered ten runs: eight CASE-I AI Hornet runs, one CASE-III AI Hornet run, and one scheduled NAVYGROUP wind test without AIRBOSS.

- A window opened at 08:45 while navigation was not yet ready. The AI stayed in marshal until readiness, then landed and left the pattern queue. At 09:00, recovery and the wind maneuver ended and the ship continued its regular route without a U-turn.
- Adjacent windows (08:45–09:00 at 27 knots deck wind, then 09:00–09:15 at 30 knots) changed navigation without an intermediate return leg. With Uturn=false in the first window and true in the last, the final return waypoint was reached at approximately 09:46:30, followed by the regular route. The user visually confirmed return to the first departure marker.
- With those U-turn settings reversed (true in the first window, false in the last), the ship completed the same window transition and continued directly to regular waypoint UID=2 at 09:15. No return waypoint was added. This was confirmed in the log and by the user's observation.
- A single 08:45–09:00 window paused at 08:55 after the AI had landed and left the pattern queue. The carrier held 318 degrees and 18.7 knots during the pause. Recovery and wind navigation ended at 09:00:01 despite the pause; the old 09:05 resume timer did not reopen recovery, verified beyond 09:06. With Uturn=true, the return waypoint was reached and removed at approximately 09:15:30, followed by the regular route.
- A single 08:45–08:48 window paused at 08:47 with one aircraft still in the pattern. At 08:48:01, AIRBOSS extended the deadline to 08:53:01; the same wind waypoint and the carrier's course and speed remained in effect. The AI landed during the pause at approximately 08:51 and left the pattern queue. Recovery stayed paused until the extended deadline, then ended with its wind maneuver. The old 08:57 resume timer did not reopen recovery, verified beyond 08:58. The enabled return leg subsequently completed.
- Stop at 08:55 during an active 08:45–09:00 recovery, after the AI had landed, removed the owned wind waypoint while NAVYGROUP continued its regular route. Restart at 08:57 left AIRBOSS Idle and did not reopen that first window. A retained 09:05–09:10 window opened and closed normally with a new wind maneuver. AIRBOSS status updates stopped during shutdown and resumed at a single 30-second cadence. No beacon-off calls were found; configured TACAN/ICLS were activated again on restart. Continuous reception and player-menu cleanup were not verified in the cockpit.
- With a five-minute preparation lead, wind navigation began at 08:40:01 while AIRBOSS remained Idle and the AI stayed in marshal. Stop at 08:41 removed that maneuver and restored the regular route, preserving the unopened 08:45–09:00 window. Restart at 08:43 prepared that window again; recovery and AI clearance began at 08:45:01, after readiness. The AI landed, left the pattern queue, and recovery/wind navigation ended normally at 09:00:01. No duplicate status timestamps or beacon-off calls were found.
- After the AI had landed, `CarrierResumeRoute()` without an argument at 08:55 removed the wind waypoint and resumed the regular route at 21 knots. AIRBOSS stayed Recovering and the 08:45–09:00 window remained open. No wind waypoint was recreated. Recovery ended at 09:00:01 without another navigation command; the ship continued its route, verified beyond 09:01.
- A CASE-III window at 08:45–09:15 assigned the AI to stack 1 at 6,000 ft and updated its marshal task as the carrier moved and turned. Wind preparation began at 08:40:01; navigation was ready before recovery opened and the AI received its landing task at 08:45:01. Actual landing occurred at approximately 08:52, followed by recovered=true and an empty pattern queue. Recovery and wind navigation ended at 09:15:01, restoring the regular route at 21 knots without an extension. This checks AI marshal/task/queue integration, not player CASE-III guidance or LSO grading.
- Without AIRBOSS, NAVYGROUP opened a scheduled 08:10–08:15 wind window at 27 knots deck wind, offset -9.1 degrees and Uturn=false. Extending it by 300 seconds at 08:13 changed its deadline to 08:20 while preserving window ID=1 and wind waypoint UID=4. The maneuver continued through the original 08:15 deadline, then ended automatically at 08:20. Its waypoint was removed and the regular route to UID=2 resumed at 21 knots, observed beyond 08:21.

No Lua script errors were found in the ten reviewed runs. Both pause tests respected the closed windows, but the pause call announced resumption after closure. The branch now uses the existing "until further notice" announcement when the known window end is at or before the requested resumption. Delayed NAVYGROUP wind-route updates also retain their revision checks while allowing the latest update to be scheduled independently of obsolete callbacks. These final fixes postdate the ten DCS runs and are not additional DCS test results.

Run the isolated recovery and navigation regression suites from the repository root:

```text
lua54/lua54.exe tests/airboss-recovery.lua
lua54/lua54.exe tests/navy-into-wind.lua
```

The final fixes pass 43 AIRBOSS and 27 NAVYGROUP regression scenarios (70 total). The six new NAVYGROUP scheduling scenarios use the production FSM delay registration and callback dispatcher; four reproduced lost route updates before the correction. The two revision-bearing internal route calls now use positive delays, so an obsolete pending event cannot suppress the newer request. Existing revision guards reject obsolete callbacks, and NAVYGROUP Stop still clears the same call scheduler.

These suites execute production methods with simulated DCS telemetry and tasks; most scenarios also simulate event dispatch. They do not verify how DCS physically steers or lands aircraft. The agreed minimal DCS test program for the main AI features is complete; the final fixes have not yet been retested in DCS.

### Deferred work and coverage

- Constructor ownership, repeated construction, mission-script reloads and concurrent owners of one naval group require further implementation work. Multiple independent carrier groups and a selected carrier outside the first group position still need dedicated DCS coverage.
- Carrier loss and respawn remain separate implementation work, including loss of the selected carrier while escorts survive.
- Player approaches, grading, CASE II and VTOL remain outside the completed AI test scope; the user is handling player tests separately. Further Stop/Start combinations during pause or an ongoing approach, persistence and user callbacks remain unverified.
- Recovery tankers, rescue helicopters, Relay/SRS and other support flights have not been validated by these integration tests. The direct FLIGHTGROUP API cross-check above does not replace those tests.
- TACAN and ICLS were accepted in an earlier mission test. Continuous beacon reception across Stop/Start and player-menu cleanup still need cockpit checks.
- Obstruction pathfinding, shallow water and competing navigation orders remain unvalidated in DCS. If pathfinding is used, check a real obstruction: no premature approach clearance while the wind route is blocked, followed by correct continuation once navigation becomes ready.

Completion of the agreed AI test program does not mark these deferred items as passed or establish release availability outside this branch.
