---
title: PATHLINE R1a geometry API
parent: Developer
nav_exclude: true
---

# PATHLINE R1a geometry API

Status: approved and implemented on 2026-10-10, with LuaDoc and deterministic
Lua 5.1.5 regressions. This specifies the completed pure geometry part of
[R1a](rolling-pathfinding-plan.md). Bounded connection/depth validation and
the NAVYGROUP LOCAL integration remain separate, unimplemented steps.

## Responsibility and ownership

The static functions are called with `PATHLINE.Function(...)`.
Use an explicit geometry snapshot, not a new class or a terrain-aware PATHLINE
constructor. Create it once for each candidate/prepared/installed route whose
points differ. Reuse it while that exact route remains current.

- Copy only finite Vec3 components `x`, `y`, `z`; retain no ASTAR nodes, GRID,
  COORDINATE, controller, terrain metadata or caller-owned point tables.
- Distances, projections and courses use horizontal `x/z`, in meters/degrees.
  Interpolate `y` from the supplied endpoints; never query or infer altitude.
- Preserve point order and every original segment, including exact duplicates.
  No simplification, snapping, resampling, shortcut or clearance check occurs.
- Snapshot tables and their nested arrays are read-only **by contract**. Lua 5.1
  tables are not physically frozen. Editing a snapshot is unsupported; build a
  new one when points change. All exported positions and query-result tables
  are independent copies, including alternative projection matches.
- No registration, drawing, timer, logging loop, mutable progress state or
  external cache. NAVYGROUP owns route generations and progress acceptance.

Existing PATHLINE constructors and `CheckDepth` retain their contracts.
Positions can come from `candidate.Positions` or `pathline:GetPoints3D()`.
Creating the latter PATHLINE may previously have queried terrain; exporting
and snapshotting its positions must not introduce another query.

## Public functions

| Signature | Success | Ordinary unsuccessful result |
| --- | --- | --- |
| `PATHLINE.CreateGeometry(Positions, Options)` | `Geometry` | `nil, Reason, Detail` |
| `PATHLINE.GetGeometryPositions(Geometry)` | New ordered array of Vec3 copies | None for a valid snapshot |
| `PATHLINE.GetPositionAtDistance(Geometry, Distance)` | `PathLocation` | `nil, Reason, Detail` |
| `PATHLINE.ProjectPosition(Geometry, Position, Options)` | `Projection` | `nil, Reason, Detail` |
| `PATHLINE.GetTurnAtPoint(Geometry, PointIndex)` | `Turn` | `nil, "no_turn", Detail` |

On success there is no failure reason/detail. Malformed arguments are
programming errors and raise descriptive errors naming the argument/index:
wrong types, non-finite numbers, invalid indices, reversed ranges, unknown
options or a snapshot not created by `CreateGeometry`. Do not catch these
with a blanket `pcall` or convert them into a successful/default geometry.

Expected domain/resource failures return the listed reason strings. `Detail`
contains relevant evidence, not a partially usable geometry. Diagnostics and
LuaDoc are in English. All functions are synchronous pure geometry operations.

## Snapshot construction

`Positions` is a dense, one-based array of Vec3 tables. Reject holes and
non-sequence keys in this outer array rather than relying on `#Positions` for
sparse input. Extra fields on individual points are ignored. Read numeric
components directly; do not invoke point methods or metatable conversions.
Vec2 input requires an explicit caller conversion with a chosen altitude.

`Options` is optional. Its only field is `MaxPoints`, a positive integer with
default **4096**. This is a configurable resource bound, not a
measured frame-time guarantee or a GRID cell limit. Never truncate input.

| Condition | Result |
| --- | --- |
| Empty array | `nil, "empty_path", {PointCount=0}` |
| More points than the limit | `nil, "point_limit", {MaxPoints=limit}` |
| One point | Valid point-only snapshot, length 0, no segments/course |
| Consecutive equal x/y/z | Keep the zero-length segment with no heading |
| Same x/z but different y | `nil, "vertical_segment", {SegmentIndex=i}`; a horizontal-distance API cannot select a unique altitude along this leg |
| Distinct horizontal points, including very short legs | Keep the segment; do not merge using a proximity tolerance |
| Non-finite computed length/total, or positive length unable to advance the cumulative distance | `nil, "numeric_range", {SegmentIndex=i}` |

An axis-aligned north/south leg is valid; `vertical_segment` means altitude-only
movement, not a vertical line on a map. Mixed horizontal/vertical submarine
maneuvers would require a separate explicit 3D contract.

Expose these read-only snapshot fields:

| Field | Meaning |
| --- | --- |
| `Positions` | Copied original Vec3 sequence |
| `PointCount` | Number of points, at least 1 |
| `SegmentCount` | `PointCount - 1`, including duplicate segments |
| `Distances` | Horizontal distance from the start at each original point; first value 0 |
| `TotalLength` | Last cumulative distance, in meters; not ASTAR cost |
| `Segments[i].Index` | Original segment index; connects points i and i+1 |
| `Segments[i].Length` | Horizontal length, including valid zero |
| `Segments[i].StartDistance`, `.EndDistance` | Cumulative horizontal bounds |
| `Segments[i].Heading` | Course in [0,360), absent for zero length |

Headings follow MOOSE/DCS: positive x is 0 degrees, positive z is 90 degrees.
Private lookup indices are implementation details, not new public APIs.

## Positions at a distance

`GetPositionAtDistance` takes finite `Distance` in meters along the route.
Outside `[0, TotalLength]`, return `nil, "distance_out_of_range"` with
`{Distance=..., TotalLength=...}`. Do not silently clamp or extrapolate.

`PathLocation` has:

| Field | Meaning |
| --- | --- |
| `Position` | Independent Vec3 at this location |
| `DistanceFromStart` | Cumulative horizontal distance |
| `SegmentIndex`, `Fraction` | Original positive-length segment and fraction in [0,1] |
| `Heading` | Course of that segment, in degrees |
| `PointIndex` | Only for a point-only result; segment/fraction/heading then absent |

Between points, linearly interpolate x/y/z by horizontal fraction. At endpoints,
copy the original position exactly. At an interior vertex, select the incoming
positive-length segment with fraction 1; this preserves the incoming course
needed when preparing a continuation. At distance 0, use the first positive
segment with fraction 0. At the final distance, use the last positive segment
with fraction 1. Skip consecutive duplicate segments for direction selection,
without renumbering them. A zero-total-length snapshot returns point 1 at
distance 0 and no fabricated heading. To inspect both vertex directions, use
`GetTurnAtPoint` rather than interpreting the one location heading as a turn.

Guard computed interpolation/projection values against numeric overflow;
return `nil, "numeric_range"` instead of NaN/infinity, with `SegmentIndex`
in `Detail` or `PointIndex` for a point-only projection. Finite extreme inputs
do not authorize invalid successful results.

## Projection onto a constrained part of the route

`ProjectPosition` accepts a finite Vec3 query. Its y is validated but does not
affect the horizontal nearest-point decision; result altitude comes from the
route. This is not a 3D nearest point or an overpass/underpass discriminator.

Optional projection bounds:

| Option | Default | Contract |
| --- | --- | --- |
| `FirstSegment` | 1 | Inclusive original segment index |
| `LastSegment` | `SegmentCount` | Inclusive original segment index |
| `MinDistanceFromStart` | 0 | Inclusive lower cumulative distance, in meters |
| `MaxDistanceFromStart` | `TotalLength` | Inclusive upper cumulative distance, in meters |

Explicit segment indices must exist; distance bounds must lie within the
snapshot. A single supplied bound leaves the other at its default. Equal
bounds are allowed; reversed bounds are invalid arguments. Intersect the
segment range with the cumulative-distance interval **before** projecting:
clip each allowed segment to that interval, then clamp its perpendicular foot
to the permitted portion. A valid pair of ranges with no intersection returns
`nil, "empty_search_range"` with the effective bounds in `Detail`.

A snapshot without segments allows omitted segment bounds only and projects
onto point 1. A selected range containing only zero-length segments projects
onto their common point, provided its cumulative distance is allowed. Return
the lowest point index in that selected range with no heading/fraction/segment.
Zero-length segments in a mixed range can contribute their point, but an
equivalent positive-segment match takes precedence.

The unrestricted default is useful for general geometry queries. **NAVYGROUP
progress must always supply a contiguous segment range and a plausible distance
interval derived from its installed route and actual observations.** A global
nearest point alone cannot identify progress around a hairpin or crossing.

`Projection` extends `PathLocation` with:

| Field | Meaning |
| --- | --- |
| `DistanceToPath` | Horizontal Euclidean distance from query to the selected, clamped position |
| `SignedLateralDistance` | Signed perpendicular distance from query to the selected segment's supporting line; positive right of travel, absent without a direction |
| `Ambiguous` | True when a numerically tied match exists at a different route distance |
| `Alternative` | Independent alternative match if ambiguous; same location/distance fields, without recursive ambiguity fields |

For unit horizontal direction `(ux, uz)` and query offset `(qx, qz)` from the
segment start, signed lateral distance is `ux*qz - uz*qx`. At a point beyond
the endpoint along the segment, lateral distance can be zero while
`DistanceToPath` is positive. Neither value alone proves endpoint arrival.

Tie/ambiguity contract:

1. Find the true minimum `DistanceToPath` over all allowed candidates.
2. Treat candidates within **0.000001 m** of that minimum as numerical ties.
   Compare with the minimum, not successive candidates; avoid chained,
   traversal-order-dependent ties. This tolerance is not a safety margin,
   point-merging tolerance or arrival radius.
3. Select the smallest `DistanceFromStart` among ties. For identical route
   distances, prefer a positive segment, then its lowest original index
   (incoming at a shared vertex), then the lowest point index. Never select an
   excluded segment merely to recover an incoming heading.
4. Matches with exactly the same cumulative distance represent one location:
   adjacent legs sharing a vertex and duplicate points are not ambiguous.
   Distinct tied route distances are ambiguous, including self-crossings,
   retraced segments and a closed route's coincident start/end.
5. `Alternative` is the earliest distinct tied route distance, using the same
   tie rules within that location. Report distances for the chosen matches;
   the chosen match can be up to the numerical tolerance farther than the
   absolute nearest match. No progress update follows from either selection.

This flags tied alternatives, not all possible navigation uncertainty.
An unequal-distance hairpin can still give an inappropriate global nearest
match. Range restriction, route identity, plausible travel, lateral limits
and accepted progress history remain NAVYGROUP responsibilities. It may obtain
a narrower projection from independent evidence; PATHLINE does not invent it.

## Turn geometry at an original point

`GetTurnAtPoint` requires an integer `PointIndex` within the original points.
Find the nearest incoming and outgoing positive-length segments across any
consecutive duplicate points. All points in one duplicate run describe the
same geometric corner. Do not bridge a nonzero leg or skip an actual corner.

Return `Turn` with independent `Position`, original `PointIndex`,
`DistanceFromStart`, `IncomingSegment`, `OutgoingSegment`, `IncomingHeading`,
`OutgoingHeading`, and `SignedAngle` in degrees. Wrap the heading change into
**(-180,180]**: positive is right, negative left, straight is 0. Thus 350 to
10 degrees gives +20, 10 to 350 gives -20. Exactly reversing direction returns
+180 as a deterministic representation, not a recommendation to turn right.

Without both directions, return `nil, "no_turn"` and
`{PointIndex=..., MissingIncoming=boolean, MissingOutgoing=boolean}`. This
includes endpoints and point-only paths; do not invent an initial heading.
NAVYGROUP separately compares the measured ship heading with the entry leg.

The angle describes two geometric courses. It provides no minimum radius,
allowable speed, swept hull, turn time, braking distance or navigability result.
Existing `VECTOR:GetHeadingDelta` returns an unwrapped difference and
`UTILS.HdgDiff` an unsigned difference; neither has this signed contract.
Reuse the established x/z heading convention; implement the small signed wrap
locally without changing those existing APIs.

## Integration boundary and bounded work

Integration sketch; movement-policy bounds remain caller-owned:

```lua
local geometry, reason, detail = PATHLINE.CreateGeometry(candidate.Positions)
if not geometry then
  return nil, reason, detail
end

-- Bounds below are supplied by NAVYGROUP, not inferred by PATHLINE.
local projection, projectionReason = PATHLINE.ProjectPosition(geometry, observedPosition, {
  FirstSegment = firstPlausibleSegment,
  LastSegment = lastPlausibleSegment,
  MinDistanceFromStart = earliestPlausibleDistance,
  MaxDistanceFromStart = latestPlausibleDistance,
})
-- A result still needs route-generation and movement-plausibility checks.
-- Ambiguous matches must not automatically advance accepted progress.
```

Construction/export are O(n); projection is O(k) in the selected segment count,
with at most two linear passes and no retained list of all candidates. Build
positive-segment lookup data once for O(log n) distance queries and O(1) turn
lookups. There are no asynchronous callbacks or cancellation races in this
substep. The point limit bounds default synchronous work, but actual mission
timing must still be measured. Do not rebuild/export all points on every tick.

NAVYGROUP retains the measured/accepted progress separately. Geometry does not
make it monotonic, authorize forward movement, mark an original waypoint
complete or resume a stopped ship. A late continuation still requires a new
movement command under the agreed stop policy.

This substep requires additions only in PATHLINE, its LuaDoc and regression
fixtures. No necessary ASTAR, GRID, VECTOR, UTILS, PROFILE, module-order or
NAVYGROUP production change is identified. `ASTAR.LocalCandidate.Positions`
already supplies independent positions. Existing `Length`/`Cost` fields keep
their meanings. Bounded connection validation, dense depth/corridor sampling,
their evaluator interfaces and cancellation lifecycles are specified in the
[R1a validation API](pathline-validation-api.md). Its V1 job/connection layer and
V2 incremental depth validation are implemented with LuaDoc and Lua 5.1 regressions. `CheckDepth` is not repurposed.

## Deterministic acceptance cases

| Case | Required result |
| --- | --- |
| Axis-aligned and rotated legs | Correct x/z length, fraction and all four cardinal headings |
| `(0,2,0)` to `(3,8,4)` | Length 5 m; at 2.5 m return `(1.5,5,2)`; y never sampled |
| Leading/interior/trailing duplicates | Original indices retained; no fabricated direction or division by zero |
| Empty, single point, all points identical | Explicit empty failure; valid point-only queries at distance 0 |
| Altitude-only leg | `vertical_segment` with the original segment index |
| Near but distinct points | Retained positive segment; explicit numeric failure if not representable |
| Negative/over-end distance, exact endpoints | Out-of-range failure; exact supplied endpoint components |
| Vertex query and duplicate corner | Incoming heading for distance lookup; both directions for turn lookup |
| Northbound line, query east/west | Positive/negative signed lateral distance respectively |
| Query beyond endpoint on its supporting line | Zero lateral but positive distance to the clamped path |
| Restricted portion of a long segment | Foot clipped to distance window before nearest selection |
| Disjoint valid ranges; reversed/invalid bounds | `empty_search_range`; descriptive argument error respectively |
| Selected range containing only duplicate legs | Point result at its own cumulative distance, no heading |
| Hairpin with spatially nearer later leg | Restricted projection stays in the supplied range; global query has no progress authority |
| Crossing, overlapping/retraced legs, closed route | Earliest tied location plus independent alternative; ambiguity explicit |
| Two adjacent legs sharing one vertex | One route distance; not ambiguous; respect incoming-segment exclusion |
| Numerical ties and reordered candidate evaluation | Same minimum-based selection; no chained tie dependence |
| Turns 350 to 10, 10 to 350, straight, reversal | +20, -20, 0, +180; endpoints return `no_turn` |
| Malformed, sparse, false, NaN/infinite inputs/options | Argument error; zero remains valid |
| Point cap and computed numeric overflow | Structured failure; no truncation, partial result or NaN success |
| Mutation of inputs, exported points or query results | Snapshot and other results remain unchanged |
| Terrain/coordinate constructors stubbed to raise | All new functions still work without invoking them |

Implementation validation on 2026-10-10:

- 26 new PATHLINE regression cases exercise the production functions with
  controlled external dependencies. All 26 initially failed against the source
  without the new API; the existing 21 cases continued to pass.
- Lua 5.1.5 syntax compilation succeeds for production PATHLINE and its suite.
- Separate Lua 5.1.5 processes pass PATHLINE (47), profile (15), depth (33),
  ASTAR (295), and NAVYGROUP (25): 415 cases in total.
- Source, tests and documentation were reviewed; `git diff --check` passes.

The fixture supplies an atan2 equivalent only for newer Lua versions that
lack the Lua 5.1 function; validation above used the native Lua 5.1.5 function.
These checks establish geometry/ownership behavior only; ship motion, DCS
terrain and controller execution remain later simulator validation gates.
No simulator or mission log was accessed. The subsequent
[bounded validation API](pathline-validation-api.md) was documented and its V1
job lifecycle, connection evaluator and work budgets implemented on 2026-10-10,
with Lua 5.1 regressions. R1a-V2 depth/corridor validation is now implemented
with incremental profile processing and explicit sampling/work caps; the seven
affected suites pass 488 cases under Lua 5.1.5. The next proposed subtask is P0:
common test-input, replay and result contracts before fixed-pose preparation.
Wait for user approval/comments before starting it.
