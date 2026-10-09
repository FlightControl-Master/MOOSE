---
title: Rolling pathfinding development plan
parent: Developer
nav_exclude: true
---

# Rolling pathfinding development plan

## Current decision: remove the naval LOCAL integration (2026-10-09)

The developer approved a clean removal of the experimental local pathfinding
implementation from NAVYGROUP, followed by a staged rebuild. The shared
ASTAR, GRID and PATHLINE implementation remains in place. The existing
full-waypoint naval search remains available; its redesign is a separate task.

The preceding implementation and regression cases are recoverable at commit
`8ba49eb1b`. Detailed design decisions and test history are retained in the
[archived development history](rolling-pathfinding-history.md). Historical
methods and milestone completion statements there are not current API promises.

### Evidence and reason for the reset

Standalone ASTAR tests demonstrated useful geometric paths and virtual point
following. The recorded M2.4 baseline passed T1, T2 at depth weight 1 and all
eight T3 checks; the weight-10 baseline reached its request budget. Later
iterations and observations are described in the archived history. These tests
do not establish physical ship movement or controller safety.

The naval integration added candidate steering, circular turn allowances,
minimum leg lengths, route reserves, speculative continuations, moving-start
reattachment and release back to ordinary routing. These interacting policies
made it difficult to explain why an available ASTAR path did not become a
submitted, usable ship route.

The final recorded run, `navy-case55-20261009133751193`, illustrates the gap.
A second local activation
began with about 2098 m clear ahead at 26 knots. Eight requests returned
`path_found`; a ninth was in progress when route preparation exhausted the
available approach reserve after 88 simulation seconds. The worker recorded
4.835 CPU seconds. NAVYGROUP explicitly commanded `FullStop` with
`local_planning_reserve`; a collision or grounding was not established by that
log. The detailed candidate rejection reasons were not available.

Virtual progress waits for planning and follows checked points exactly. A
moving ship consumes the approach while planning and rounds waypoint turns.
The old virtual and naval tests also used different search settings. These
differences must be tested separately during the rebuild. Increasing depth
weights, search horizons or arbitrary limits is not a substitute for identifying
the responsible decision.

### Removal contract

- Retain `NAVYGROUP.PathfindingMode.LOCAL` as a recognized constant.
- `SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL)` raises
  `NAVYGROUP: LOCAL pathfinding mode has been removed; local navigation is unavailable pending a rebuild`.
  Reject the request before mutating the mode, route, movement state or drawings.
- `WAYPOINT` remains the default. There is no silent conversion of a LOCAL
  request to the global planner.
- Remove the local session, coroutine jobs, work-budget API, steering and
  reserve policies, local progress/completion handling, continuation logic,
  speculative search ownership and LOCAL drawing/diagnostic hooks.
- Remove `SetPathfindingWorkBudget()` and `LastLocalPlanningReport`; do not keep
  no-op methods, compatibility adapters or dormant local implementations.
- Retain shared waypoint targeting, depth/corridor checks, hull/heading checks,
  global search diagnostics and the global grid display.
- Retain the single navigation timer for two-second hull/heading checks and
  ten-second waypoint checks. Remove the 0.1-second planning cadence.
- Preserve shared Core sources and their standalone regression suites.

A script that selects LOCAL now intentionally fails at configuration. Choosing
WAYPOINT is an explicit different behavior, not an equivalent migration.
Existing LOCAL mission scripts must wait for the rebuild or be deliberately
changed by their author. New includes require a fresh mission to take effect.

### Removal work and validation

- [x] Save the previous implementation and identify its Git baseline.
- [x] Remove NAVYGROUP local implementation and lifecycle hooks.
- [x] Replace active LOCAL documentation with its removal contract.
- [x] Replace the retired naval LOCAL suite with `tests/navy-pathfinding.lua`,
  preserving global routing, common safety and diagnostic regression coverage.
- [x] Run Lua 5.1 compilation and the affected naval/waypoint regressions.
- [x] Confirm shared ASTAR/GRID behavior, review the diff and check whitespace.

The LOCAL rejection regression failed against the preceding implementation:
the old setter accepted LOCAL instead of raising an error.

Validation on 2026-10-09: all changed Lua files compile with Lua 5.1.5.
The independent suites pass 428 cases: NAVYGROUP 25, WAYPOINTS 16,
ASTAR 280 and GRID 107. The global planner and hull-check implementations
are unchanged; no removed naval methods remain referenced by source/tests.
The final diff and whitespace check pass. Simulator validation of the
remaining WAYPOINT mode after removal has not been performed.

## Agreed rebuild sequence

No replacement local implementation is part of the removal change.

### R1: explainable route preparation without a moving ship

Use the preserved ASTAR API to obtain paths with explicitly identical search
parameters. Prepare a ship route from a fixed position, heading and planned
speed without a moving deadline. Record why each relevant candidate or
connection is accepted, changed or rejected.

Acceptance: deterministic terrain cases include the known island/shallow
passage; each rejected result has a concrete reason; accepted route geometry
passes the hard depth/corridor rules. Keep only justified steering constraints.
Do not recreate all old policies merely to satisfy their former tests.

### R2: execute a prepared passage in DCS

Submit a prepared route for one passage, with the intended vessel and speed.
Compare the commanded geometry with observed positions and rounded turns.
Use these observations to justify maneuvering clearances; distinguish measured
behavior from conservative assumptions.

Acceptance: the passage is completed without a collision, unplanned stop or
unexplained route change. Source identity and reproduction settings are recorded.
A geometric or stubbed test alone cannot satisfy this gate.

### R3: add rolling continuation and explicit waiting behavior

Only after R1 and R2 pass, add planning during movement, timely continuation
handover and cancellation when destination, rules or movement authority change.
Agree on what happens when a continuation is not yet ready, including whether
and how a controlled wait may resume. Do not silently introduce automatic
retries or a global fallback.

Acceptance: moving deadlines and route handovers have deterministic tests;
the island passage succeeds repeatedly in DCS; manual holds, tasks and
retargeting remain authoritative. Report simulation, wall and CPU time separately.

## Responsibility boundaries

| Component | Responsibility |
| --- | --- |
| GRID | Lattice geometry, sampling and bounded window lifetime; no ship commands. |
| ASTAR | Local exploration, checked candidates, costs, work limits and planning history; no controller or owned timer. |
| PATHLINE / geometry helpers | Shared connection and profile checks; no ship-specific steering policy. |
| NAVYGROUP rebuild | Explainable route preparation, observed movement, route submission and continuation lifecycle. |

Both naval search modes remain in development. The user explicitly permits
clean redesigns without compatibility with intermediate mission scripts.
This does not change the release status of unrelated shared MOOSE APIs.

## Validation commands

Run each suite in a separate Lua 5.1 process from the repository root:

```text
lua tests/navy-pathfinding.lua
lua tests/waypoints.lua
lua tests/astar.lua
lua tests/grid.lua
```

The naval suite also accepts `NAVY_TEST_FILTER` for focused name patterns.
Simulator work starts only after the user announces a running mission.
Read the log directly during an agreed test; do not create recurring monitors.
