---
title: NAVYGROUP R1b route preparation
parent: Developer
nav_exclude: true
---

# NAVYGROUP R1b fixed-pose route preparation

Status: implementation approved and completed on 2026-10-11 in NAVYGROUP,
with LuaDoc and Lua 5.1.5 regressions. This step follows the
[rebuild plan](rolling-pathfinding-plan.md). It does not enable LOCAL or send
routes to DCS. Native capture acceptance and vessel measurements remain pending.

## API and ownership

These are static `NAVYGROUP.Function(...)` functions. No live NAVYGROUP instance,
group, controller, timer or FSM is used.

| Function | Result |
| --- | --- |
| `CreateRouteConnectionEvaluator(Search, CostUnits)` | PATHLINE connection descriptor using fresh `ASTAR:EvaluateConnection`; failed infinite costs are omitted and depth evidence is mapped |
| `StartRoutePreparation(Input, Evaluators, Options)` | Opaque job and independent initial report; copies input/options without terrain queries |
| `StepRoutePreparation(Job, Budget, CurrentContextId)` | Independent report after bounded cooperative work |
| `GetRoutePreparationReport(Job)` | Independent report, without work |
| `CancelRoutePreparation(Job, Reason)` | Idempotent cancellation, releasing active validation and callback references |

Input contains `Start`, `Goal`, `Pose` and ordered `Candidates`. Positions are
finite DCS Vec3 values: horizontal x/z and altitude y, in meters. Pose position
must equal Start exactly. A candidate's first point must equal Start and an
exact-goal candidate's last point must equal Goal; no arrival tolerance applies.
Candidate Cost/Score are finite non-negative values in the connection evaluator's
units; Score must include at least Cost. ASTAR node/Path fields are not retained.
Published candidate order is preserved; optional raw diagnostic scalars are copied.
Preparation evaluates this supplied set, not search completeness. Keep the
original ASTAR request's DataIncomplete/progress reports alongside it.

Pose has Position and optional HeadingDeg, ActualSpeedMps, RequestedSpeedMps,
and Hull = {Forward, Aft, Left, Right}. Headings are degrees clockwise from +x
towards +z, normalized to [0,360); speeds are meters/second and hull extents
are non-negative meters from the same reference point. Missing fields prevent
a modeled proposal. No hull, cruise speed, radius or braking distance is inferred.

Evaluators.Connection is a PATHLINE connection descriptor with CostUnits.
Evaluators.Maneuver is an optional atomic callback. If supplied, Evaluators.Model
is required: Id, Revision, Calibration (`assumed` or `measured`), and a bounded
flat Parameters table with explicit model assumptions. An optional Evidence
string identifies calibration evidence. External rule/terrain/model changes
require cancellation or a new ContextId; closures are not frozen automatically.
All callback inputs and returned reports are independent copies.

## Stages and selection

1. Build the raw PATHLINE geometry and check exact endpoints.
2. Freshly validate and price every connection, followed by dense depth/corridor
   sampling with the explicit Options.Depth configuration.
3. Optionally try successive three-point shortcuts, one removal at a time.
   Validate the entire trial route again, including dense depth. Accept a trial
   only when its total connection cost is no greater than the currently checked
   route's cost. No soft depth threshold is turned into a hard failure.
4. Check entry, every distinct geometric corner, and the terminal/stopping area
   under the explicit maneuver callback. The raw variant remains a fallback
   even when a shortcut or its maneuver fails.
5. Select from ready variants by exact-goal priority, then minimum
   `Raw.Score + PreparedCost - Raw.Cost`, then original candidate index, then raw
   before simplified. Endpoints never change. Every score term and cost unit is
   reported; footprint samples are not a claim to price a native vessel track.
   Evaluate the equivalent expression `PreparedCost + (Raw.Score - Raw.Cost)`
   to retain small prepared costs beside large original costs/scores.

Only one final simplified variant is retained beside raw. Shortcut failures
retain a bounded first failure and counts, not every trial geometry. A limited
optional trial preserves the checked fallback; a shared job limit stops the
whole job and prevents a partially evaluated set from publishing a proposal.
Candidates remain individually rejected/unavailable/limited/unverified rather
than being called blocked whenever evidence is missing.

## Maneuver adapter

`Maneuver(Event, Pose, Model)` receives copied data for one `entry`, `turn` or
`terminal` event. Event includes candidate/variant identity, ContextId, position,
incident segment indices/endpoints/lengths/headings and signed angle where a
direction exists. Positive angle is right, negative left, wrapped to (-180,180].
The entry compares the pose heading with the first positive leg; a turn compares
two courses. It is not heading change between timer ticks. Duplicate runs do not
produce repeated corner events; a point-only route still needs entry and terminal
model decisions.

Return `Status = modeled`, `rejected`, `unavailable`, or `unverified`. Failed
results require a short Reason. A modeled result requires at least one strip:
`{Positions = {...}, CorridorWidth = meters}`. Each strip is a sampled piece of
the model's swept hull/entry/stopping envelope. The callback is responsible for
covering the complete event under its explicit assumptions; geometry alone
cannot establish that coverage or DCS fidelity. NAVYGROUP checks every supplied
strip through PATHLINE with the same hard minimum depth and at least the route's
configured corridor width. It never replaces missing terrain data with success.
Strips may contain sampled arcs; no universal corner disk or turn-angle cutoff
is imposed. A malformed callback result is an error and propagates.
Supply Depth.LateralSpacing when the model can return positive strip widths,
including when the baseline route width is zero. An altitude-only footprint is
unavailable horizontal coverage, not a blocked route or an exhausted work cap.

A ready proposal means `ready_under_model`, retains Model/Pose/coverage and all
event results, and always has `ExecutionValidated = false`. Missing model or pose
data produces `unverified`, with no selected proposal. Assumed models may be
tested deterministically but cannot certify ship safety; measured models also
need subsequent simulator execution validation.

## Limits and lifecycle

Options.Depth is required and uses PATHLINE.CreateDepthEvaluator's existing
settings. Simplify defaults true. Immutable defaults are MaxCandidates=8,
MaxPoints=4096, MaxShortcutAttempts=32 per candidate, MaxFootprintPaths=8 per
event, MaxFootprintPoints=4096 per event, MaxManeuverEvents=4096 per variant,
MaxWorkUnits=400000, MaxEvaluatorCalls=4096, MaxManeuverCalls=8192,
MaxPointChecks=50000 and MaxProfileQueries=4096. Count budgets preserve zero;
structural point/path/candidate caps must be positive. CPU caps are optional.

Step defaults are work=64, connection callbacks=1, maneuver callbacks=1,
point checks=8 and profile queries=1. PATHLINE work/counters consume the same
remaining slice and job budgets as preparation state advances. Pending commits
can proceed without another callback allowance; yielded samples are not queried
twice. Atomic callbacks, geometry construction, bounded input/result copies and
native terrain calls are not preemptible. Counts bound admission and retained
data, not frame duration or engine allocation. CPU is active os.clock time,
includes subordinate checks, excludes idle time and is not simulation time.
Do not sum the nested PATHLINE CPU fields with the inclusive preparation CPU.

Jobs own no scheduler. A configured ContextId must match on every step. Explicit
cancellation may occur inside a callback; its result is discarded. Stale context
is checked before admitting work. Terminal jobs retain their first result and
never restart; the consumer must check identity again before using a proposal.
Reentrant stepping is an error. Evaluation exceptions release pending state and
propagate unchanged, including non-string error objects. No broad fallback pcall
converts programming errors into obstacles.

Reports include the resolved Limits and baseline DepthCoverage; individual
strips retain their effective width, sampling coverage and native failure.
MaxCandidates/MaxPoints admission failures retain required/allowed counts instead
of truncated candidate/point data. Terminal outputs are detached, editable Lua
tables, but a checked proposal is read-only by contract: changed geometry needs
a new preparation.

Example using an already configured ASTAR and its completed candidate set:

```lua
local job = NAVYGROUP.StartRoutePreparation({
  Start = start, Goal = goal, Pose = frozenPose,
  Candidates = completedRequest.Candidates,
}, {
  Connection = NAVYGROUP.CreateRouteConnectionEvaluator(search, "depth_weighted_meters"),
  Maneuver = explicitModelCallback, Model = explicitModelDescription,
}, {
  ContextId = "request-1-pose-1-rules-1", Simplify = true,
  Depth = {MinDepth = 3.5, CorridorWidth = 50,
    LongitudinalSpacing = 25, LateralSpacing = 10},
})

-- Advance only while this frozen request/pose/rule context remains current.
local report = NAVYGROUP.StepRoutePreparation(job, {
  MaxWorkUnits = 64, MaxEvaluatorCalls = 1, MaxManeuverCalls = 1,
  MaxPointChecks = 8, MaxProfileQueries = 1,
}, "request-1-pose-1-rules-1")
-- No route is installed here, including after ready_under_model.
```

The explicit model callback is application/test supplied until R2 measures an
appropriate vessel policy. The analytic strip callback in the regression suite
tests the interface and checks; it is not a calibrated DCS navigation model.

## Validation and next gate

Exercise production NAVYGROUP/ASTAR/PATHLINE with analytic terrain under Lua
5.1, including shortcuts across islands, an only-shallow passage, cost preference,
raw fallback after maneuver rejection, entry/turn/stop footprints, missing data,
exact-goal and tie selection, sparse/malformed input, ownership, tiny slices,
shared limits, cancellation, clock failures and no movement/timer/drawing effects.
Run the existing naval and shared-Core dependencies separately.

Validation: 48 new production preparation cases and the existing naval (25),
ASTAR (295), PATHLINE geometry/drawing (57), connection validation (36) and depth
validation (42) cases pass in separate Lua 5.1.5 processes: 503 cases total.
The unsupported-footprint classification test exposed the initial error before
its correction; a large-score/small-cost case likewise exposed arithmetic
cancellation and now preserves the prepared cost. Production syntax and the
final diff are checked. No new native
DCS acceptance, terrain measurement, vessel movement or controller safety result
is claimed.

After this implementation and validation, propose a stationary DCS preparation
test using explicitly configured model inputs and displayed copied geometry.
Wait for approval/comments before that test or R2 measurements. LOCAL integration
and automatic movement remain later milestones.
