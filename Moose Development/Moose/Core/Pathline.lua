--- **Core** - Path from A to B.
--
-- **Main Features:**
--
--    * Path from A to B
--    * Arbitrary number of points
--    * Automatically from lines drawtool
--
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Core.Pathline
-- @image CORE_Pathline.png


--- PATHLINE class.
-- @type PATHLINE
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string name Name of the path line.
-- @field #table points List of 3D points defining the path.
-- @extends Core.Base#BASE

--- *The shortest distance between two points is a straight line.* -- Archimedes
--
-- ===
--
-- # The PATHLINE Concept
-- 
-- List of points defining a path from A to B. The pathline can consist of multiple points. Each point holds the information of its position, the surface type, the land height
-- and the water depth (if over sea).
-- 
-- Line drawings created in the mission editor are automatically registered as pathlines and stored in the MOOSE database.
-- They can be accessed with the @{#PATHLINE.FindByName} function.
-- 
-- # Constructor
-- 
-- The @{#PATHLINE.New} function creates a new PATHLINE object. This does not hold any points. Points can be added with the @{#PATHLINE.AddPointFromVec2} and @{#PATHLINE.AddPointFromVec3}
-- 
-- For a given table of 2D or 3D positions, a new PATHLINE object can be created with the @{#PATHLINE.NewFromVec2Array} or @{#PATHLINE.NewFromVec3Array}, respectively.
-- 
-- # Line Drawings
-- 
-- The most convenient way to create a pathline is the draw panel feature in the DCS mission editor. You can select "Line" and then "Segments", "Segment" or "Free" to draw your lines.
-- These line drawings are then automatically added to the MOOSE database as PATHLINE objects and can be retrieved with the @{#PATHLINE.FindByName} function, where the name is the one
-- you specify in the draw panel.
-- 
-- # Mark on F10 map
-- 
-- The points of the PATHLINE can be marked on the F10 map with the @{#PATHLINE.MarkPoints}(`true`) function. The mark points contain information of the surface type, land height and 
-- water depth.
-- 
-- To remove the marks, use @{#PATHLINE.MarkPoints}(`false`).
-- DrawLine() replaces the existing line segments; UnDrawLine() removes them independently of point markers.
-- Successful UpdateFromVec2Array()/UpdateFromVec3Array() calls remove the previous points and lines without redrawing.
-- Invalid input or terrain-query errors during replacement leave the original route and drawings intact.
-- Point labels show unavailable terrain metadata explicitly.
--
-- # Pure Horizontal Geometry
--
-- Static CreateGeometry(), GetGeometryPositions(), GetPositionAtDistance(), ProjectPosition() and GetTurnAtPoint()
-- operate on copied Vec3 snapshots without terrain queries. Distances use x/z in meters; y is retained/interpolated.
-- Snapshots are read-only by contract. Query/export results are independent copies. Rebuild a snapshot when points change.
-- Projection bounds and ambiguity reports support consumers tracking route progress; they do not certify ship movement or safety.
--
-- # Caller-Stepped Connection Validation
--
-- CreateConnectionEvaluator(), StartValidation(), StepValidation(), GetValidationReport() and CancelValidation()
-- validate original geometry connections with explicit work/callback/CPU budgets and independent reports.
-- The caller owns scheduling and movement authority. Callbacks are atomic; CPU caps cannot interrupt them.
-- Only a current "clear" result completes validation. Partial prefixes and late results never authorize movement.
--
-- # Point Access
--
-- GetPoints(), GetPoints2D(), GetPoints3D() and the indexed getters return independent copies in path order.
-- Modifying these results does not change the stored route. GetCoordinates() creates fresh COORDINATE objects.
--
-- @field #PATHLINE
PATHLINE = {
  ClassName      = "PATHLINE",
  lid            =   nil,
  points         =    {},
}

--- Point of line.
-- @type PATHLINE.Point
-- @field DCS#Vec3 vec3 3D position.
-- @field DCS#Vec2 vec2 2D position.
-- @field #number surfaceType Sampled surface type; may be unavailable.
-- @field #number landHeight Sampled surface height in meters; may be unavailable.
-- @field #number depth Sampled water depth in meters; may be unavailable.
-- @field #number markerID Marker ID.
-- @field #number lineID Line marker ID.

--- Result of a detailed water-depth check between two positions.
-- @type PATHLINE.DepthReport
-- @field #string Status "clear", "blocked", or "unavailable". Missing terrain values are not a confirmed obstacle.
-- @field #string Reason Rejection reason, or nil when clear.
-- @field #string Cause Underlying cause, such as "insufficient_depth", "non_water", or invalid terrain data.
-- @field #number Distance Horizontal distance from the original start to the goal, in meters.
-- @field #number ClearDistance Usable prefix from the original start, in meters, assuming linear depth between samples. Zero when data is unavailable.
-- @field #number RequiredDepth Requested minimum water depth, in meters.
-- @field DCS#Vec3 Point Limiting rejected sample, when known; y is omitted when unavailable. This is not the interpolated threshold position.
-- @field #number Depth Water depth at Point, when known; the shallower of direct and profile depth.
-- @field #number SurfaceType DCS surface type at Point, when known.
-- @field #number ProfileOffset Signed distance from the route center line, in meters; positive is right of travel in DCS x/z coordinates.
-- @field #string Location "start", "goal", "profile", or "profile_fallback" relative to the original input direction.


-- Validate raw inputs before terrain queries or formatting can turn bad data into a usable position/label.
local function isFiniteNumber(Value)
  return type(Value)=="number" and math.abs(Value)<math.huge
end

-- Count actual profile calls shared by the two depth evaluators. No terrain hooks are installed.
local depthProfileQueries=0

--- Query one native depth profile and count the call, including unavailable results.
-- Internal measurement boundary used by PATHLINE and ASTAR; API errors still propagate.
function PATHLINE._QueryDepthProfile(Start, Goal)

  depthProfileQueries=depthProfileQueries+1
  return land.profile(Start,Goal)

end

--- Read the monotonic depth-profile counter for synchronous measurement scopes.
-- Does not include unrelated terrain/road/profile APIs or reset another caller's baseline.
function PATHLINE._GetDepthProfileCount()

  return depthProfileQueries

end

--- PATHLINE class version.
-- @field #string version
PATHLINE.version="0.2.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Pure horizontal geometry
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Options for a pure geometry snapshot.
-- @type PATHLINE.GeometryOptions
-- @field #number MaxPoints Maximum input point count, a positive integer. Default 4096; excess points are rejected, never truncated.

--- Copied horizontal route geometry. All fields and nested tables are read-only by contract.
-- Create a new snapshot after changing positions. No terrain, drawing, registration or controller access occurs.
-- @type PATHLINE.Geometry
-- @field #list<DCS#Vec3> Positions Independent copies of the original points, including duplicates.
-- @field #number PointCount Number of original points, at least one.
-- @field #number SegmentCount Number of original connections, including zero-length segments.
-- @field #list<#number> Distances Horizontal distance from the start at each point, in meters.
-- @field #number TotalLength Total horizontal length in meters, not a pathfinding cost.
-- @field #list<PATHLINE.GeometrySegment> Segments Original connections in route order.

--- One original connection in a geometry snapshot.
-- @type PATHLINE.GeometrySegment
-- @field #number Index Connects Positions[Index] and Positions[Index+1].
-- @field #number Length Horizontal length in meters, including valid zero.
-- @field #number StartDistance Cumulative horizontal start distance in meters.
-- @field #number EndDistance Cumulative horizontal end distance in meters.
-- @field #number Heading Course in degrees [0,360), or nil for zero length. Positive x is 0, positive z is 90.

--- Independent location on a horizontal route.
-- @type PATHLINE.PathLocation
-- @field DCS#Vec3 Position Copied/interpolated position; y comes from route endpoints, not terrain.
-- @field #number DistanceFromStart Cumulative horizontal distance in meters.
-- @field #number SegmentIndex Original positive-length segment index, or nil for a point-only result.
-- @field #number Fraction Fraction in [0,1] on SegmentIndex, or nil without a segment.
-- @field #number Heading Segment course in degrees [0,360), or nil without a direction.
-- @field #number PointIndex Original point index for a point-only result; otherwise nil.

--- Inclusive bounds for a projection. Indices refer to original segments, including duplicates.
-- @type PATHLINE.ProjectionOptions
-- @field #number FirstSegment First permitted segment; default 1. Explicit indices must exist.
-- @field #number LastSegment Last permitted segment; default SegmentCount. Omit both indices for a single-point snapshot.
-- @field #number MinDistanceFromStart Lower permitted route distance in meters; default 0.
-- @field #number MaxDistanceFromStart Upper permitted route distance in meters; default TotalLength.

--- Independent match for one projected route location.
-- @type PATHLINE.ProjectionMatch
-- @extends #PATHLINE.PathLocation
-- @field #number DistanceToPath Horizontal distance to the clamped route position in meters, including endpoint overrun.
-- @field #number SignedLateralDistance Perpendicular distance to the supporting line in meters; positive right, nil without direction.

--- A projection result. This is geometry, not accepted movement progress or an arrival decision.
-- @type PATHLINE.Projection
-- @extends #PATHLINE.ProjectionMatch
-- @field #boolean Ambiguous True if a numerically tied match exists at a distinct route distance.
-- @field #PATHLINE.ProjectionMatch Alternative Independent earliest distinct tied match, or nil. No recursive ambiguity fields.

--- Independent geometric corner information; not a ship turning-radius or speed constraint.
-- @type PATHLINE.Turn
-- @field DCS#Vec3 Position Copied original corner position.
-- @field #number PointIndex Original requested point index.
-- @field #number DistanceFromStart Cumulative horizontal distance in meters.
-- @field #number IncomingSegment Nearest positive-length segment before the point, across consecutive duplicates only.
-- @field #number OutgoingSegment Nearest positive-length segment after the point, across consecutive duplicates only.
-- @field #number IncomingHeading Incoming course in degrees [0,360).
-- @field #number OutgoingHeading Outgoing course in degrees [0,360).
-- @field #number SignedAngle Course change in degrees (-180,180]; positive right. Exact reversal is +180 without prescribing a turn side.

local geometryTag={}
local geometryOptionNames={MaxPoints=true}
local projectionOptionNames={FirstSegment=true, LastSegment=true, MinDistanceFromStart=true, MaxDistanceFromStart=true}
local projectionTieTolerance=0.000001

local function checkGeometry(Geometry)
  assert(type(Geometry)=="table" and rawget(Geometry, "_GeometryTag")==geometryTag,
    "Geometry must be a snapshot returned by PATHLINE.CreateGeometry")
end

local function checkGeometryPosition(Position, Name)
  assert(type(Position)=="table", Name.." must be a Vec3 table")
  assert(isFiniteNumber(rawget(Position, "x")), Name..".x must be finite")
  assert(isFiniteNumber(rawget(Position, "y")), Name..".y must be finite")
  assert(isFiniteNumber(rawget(Position, "z")), Name..".z must be finite")
end

local function copyGeometryPosition(Position)
  return {x=Position.x, y=Position.y, z=Position.z}
end

local function checkGeometryOptions(Options, AllowedNames)
  if Options==nil then
    return {}
  end
  assert(type(Options)=="table", "Options must be a table")
  for name in next,Options do
    assert(AllowedNames[name], "Unknown Options field: "..tostring(name))
  end
  return Options
end

local function geometryOption(Options, Name, Default)
  local value=rawget(Options, Name)
  if value==nil then
    return Default
  end
  return value
end

local function checkGeometryIndex(Index, Maximum, Name)
  assert(isFiniteNumber(Index) and Index%1==0 and Index>=1 and Index<=Maximum,
    Name.." must be an integer within the geometry")
end

-- Scaling avoids squared-length overflow/underflow for finite coordinate differences.
local function horizontalLength(X, Z)
  if not isFiniteNumber(X) or not isFiniteNumber(Z) then
    return nil
  end
  local scale=math.max(math.abs(X), math.abs(Z))
  if scale==0 then
    return 0
  end
  local length=scale*math.sqrt((X/scale)^2+(Z/scale)^2)
  if isFiniteNumber(length) then
    return length
  end
  return nil
end

local function geometryPointLocation(Geometry, PointIndex)
  return {
    Position=copyGeometryPosition(Geometry.Positions[PointIndex]),
    DistanceFromStart=Geometry.Distances[PointIndex],
    PointIndex=PointIndex,
  }
end

local function geometrySegmentLocation(Geometry, SegmentIndex, Distance)
  local segment=Geometry.Segments[SegmentIndex]
  local start=Geometry.Positions[SegmentIndex]
  local goal=Geometry.Positions[SegmentIndex+1]
  local fraction,position

  -- Exact vertices share a canonical distance and retain the original endpoint components.
  if Distance==segment.StartDistance then
    fraction=0
    position=copyGeometryPosition(start)
  elseif Distance==segment.EndDistance then
    fraction=1
    position=copyGeometryPosition(goal)
  else
    fraction=math.max(0, math.min(1, (Distance-segment.StartDistance)/segment.Length))
    local complement=1-fraction
    position={
      x=complement*start.x+fraction*goal.x,
      y=complement*start.y+fraction*goal.y,
      z=complement*start.z+fraction*goal.z,
    }
    if not isFiniteNumber(position.x) or not isFiniteNumber(position.y) or not isFiniteNumber(position.z) then
      return nil, "numeric_range", {SegmentIndex=SegmentIndex}
    end
  end

  return {
    Position=position,
    DistanceFromStart=Distance,
    SegmentIndex=SegmentIndex,
    Fraction=fraction,
    Heading=segment.Heading,
  }
end

--- Create a pure horizontal geometry snapshot from a dense, one-based Vec3 array.
-- Copies only raw finite x/y/z components and preserves original indices, including duplicate points.
-- Distances/courses use x/z; y is retained for interpolation. No terrain, wrappers or mission side effects.
-- All snapshot tables are read-only by contract; use GetGeometryPositions() for editable copies.
-- Empty input returns "empty_path"; excess points "point_limit"; altitude-only legs "vertical_segment";
-- unrepresentable lengths/cumulative distances "numeric_range". No partial snapshot is returned.
-- Malformed/sparse input, non-finite components and invalid/unknown options raise argument errors.
-- @param #list<DCS#Vec3> Positions Ordered input points. One point or exact duplicates are valid.
-- @param #PATHLINE.GeometryOptions Options (Optional) Resource limit; MaxPoints defaults to 4096.
-- @return #PATHLINE.Geometry Snapshot on success, otherwise nil.
-- @return #string Failure reason on an ordinary unsuccessful result; nil on success.
-- @return #table Failure evidence: PointCount for empty input, MaxPoints for the limit, SegmentIndex for a failed leg.
function PATHLINE.CreateGeometry(Positions, Options)
  assert(type(Positions)=="table", "Positions must be a dense Vec3 array")
  Options=checkGeometryOptions(Options, geometryOptionNames)
  local maxPoints=geometryOption(Options, "MaxPoints", 4096)
  assert(isFiniteNumber(maxPoints) and maxPoints>=1 and maxPoints%1==0,
    "Options.MaxPoints must be a positive integer")

  -- Count actual keys, not an undefined sparse-array length. Stop at the resource limit.
  local pointCount,maxIndex=0,0
  for index in next,Positions do
    assert(isFiniteNumber(index) and index>=1 and index%1==0,
      "Positions must contain only positive integer indices")
    pointCount=pointCount+1
    maxIndex=math.max(maxIndex, index)
    if pointCount>maxPoints then
      return nil, "point_limit", {MaxPoints=maxPoints}
    end
  end
  assert(maxIndex==pointCount, "Positions must be dense without missing indices")
  if pointCount==0 then
    return nil, "empty_path", {PointCount=0}
  end

  local geometry={
    Positions={}, PointCount=pointCount, SegmentCount=pointCount-1,
    Distances={0}, TotalLength=0, Segments={},
    _GeometryTag=geometryTag, _PositiveSegments={}, _IncomingSegments={}, _OutgoingSegments={},
  }
  for index=1,pointCount do
    local position=rawget(Positions, index)
    checkGeometryPosition(position, "Positions["..index.."]")
    geometry.Positions[index]=copyGeometryPosition(position)
  end

  local incoming
  for index=1,geometry.SegmentCount do
    geometry._IncomingSegments[index]=incoming
    local start=geometry.Positions[index]
    local goal=geometry.Positions[index+1]
    local dx,dz=goal.x-start.x,goal.z-start.z
    local length=horizontalLength(dx, dz)
    if not length then
      return nil, "numeric_range", {SegmentIndex=index}
    end
    if length==0 and start.y~=goal.y then
      return nil, "vertical_segment", {SegmentIndex=index}
    end
    local endDistance=geometry.TotalLength+length
    if not isFiniteNumber(endDistance) or (length>0 and endDistance<=geometry.TotalLength) then
      return nil, "numeric_range", {SegmentIndex=index}
    end

    local segment={Index=index, Length=length, StartDistance=geometry.TotalLength, EndDistance=endDistance}
    if length>0 then
      segment.Heading=math.deg(math.atan2(dz, dx))%360
      segment._UX=dx/length
      segment._UZ=dz/length
      geometry._PositiveSegments[#geometry._PositiveSegments+1]=index
      incoming=index
    end
    geometry.Segments[index]=segment
    geometry.Distances[index+1]=endDistance
    geometry.TotalLength=endDistance
  end
  geometry._IncomingSegments[pointCount]=incoming

  -- Each point caches the first outgoing direction across its duplicate run only.
  local outgoing
  for index=geometry.SegmentCount,1,-1 do
    if geometry.Segments[index].Length>0 then
      outgoing=index
    end
    geometry._OutgoingSegments[index]=outgoing
  end
  return geometry
end

--- Export independent Vec3 copies in original route order, including duplicate points.
-- Editing the result does not change the snapshot. No terrain or wrapper construction occurs.
-- @param #PATHLINE.Geometry Geometry Read-only snapshot returned by CreateGeometry().
-- @return #list<DCS#Vec3> New ordered array and new point tables.
function PATHLINE.GetGeometryPositions(Geometry)
  checkGeometry(Geometry)
  local positions={}
  for index=1,Geometry.PointCount do
    positions[index]=copyGeometryPosition(Geometry.Positions[index])
  end
  return positions
end

--- Locate a cumulative horizontal distance on a geometry snapshot.
-- At interior vertices use the incoming positive segment, across duplicates; the start uses the first outgoing segment.
-- A zero-length route returns point 1 with no heading, fraction or segment. y is interpolated from supplied points.
-- Does not clamp/extrapolate. Malformed arguments raise errors; result tables never alias the snapshot.
-- @param #PATHLINE.Geometry Geometry Read-only snapshot returned by CreateGeometry().
-- @param #number Distance Finite horizontal distance from the start in meters.
-- @return #PATHLINE.PathLocation Independent location, or nil on failure.
-- @return #string "distance_out_of_range" or "numeric_range" on failure.
-- @return #table Distance/TotalLength for a range failure; SegmentIndex for a numeric failure.
function PATHLINE.GetPositionAtDistance(Geometry, Distance)
  checkGeometry(Geometry)
  assert(isFiniteNumber(Distance), "Distance must be finite")
  if Distance<0 or Distance>Geometry.TotalLength then
    return nil, "distance_out_of_range", {Distance=Distance, TotalLength=Geometry.TotalLength}
  end
  if Geometry.TotalLength==0 then
    return geometryPointLocation(Geometry, 1)
  end

  -- Lower bound on positive-segment ends preserves the incoming leg at a vertex.
  local positive=Geometry._PositiveSegments
  local first,last=1,#positive
  while first<last do
    local middle=math.floor((first+last)/2)
    if Geometry.Segments[positive[middle]].EndDistance<Distance then
      first=middle+1
    else
      last=middle
    end
  end
  return geometrySegmentLocation(Geometry, positive[first], Distance)
end

local function finishGeometryProjection(Location, Position, LateralDistance)
  local distance=horizontalLength(Position.x-Location.Position.x, Position.z-Location.Position.z)
  if not distance or (LateralDistance~=nil and not isFiniteNumber(LateralDistance)) then
    return nil, "numeric_range", {SegmentIndex=Location.SegmentIndex, PointIndex=Location.PointIndex}
  end
  Location.DistanceToPath=distance
  Location.SignedLateralDistance=LateralDistance
  return Location
end

local function projectGeometrySegment(Geometry, Position, Index, Minimum, Maximum)
  local segment=Geometry.Segments[Index]
  local lower=math.max(segment.StartDistance, Minimum)
  local upper=math.min(segment.EndDistance, Maximum)
  if lower>upper then
    return nil
  end
  if segment.Length==0 then
    return finishGeometryProjection(geometryPointLocation(Geometry, Index), Position)
  end

  local start=Geometry.Positions[Index]
  local goal=Geometry.Positions[Index+1]
  local qx,qz=Position.x-start.x,Position.z-start.z
  local along=qx*segment._UX+qz*segment._UZ
  local lateral=segment._UX*qz-segment._UZ*qx
  if not isFiniteNumber(along) or not isFiniteNumber(lateral) then
    return nil, "numeric_range", {SegmentIndex=Index}
  end

  local distance
  if (Position.x==start.x and Position.z==start.z) or along<=0 then
    distance=segment.StartDistance
  elseif (Position.x==goal.x and Position.z==goal.z) or along>=segment.Length then
    distance=segment.EndDistance
  else
    distance=segment.StartDistance+along
  end
  -- Apply both bounds before comparing candidates; a full-segment foot is not a permitted result.
  distance=math.max(lower, math.min(upper, distance))
  local location,reason,detail=geometrySegmentLocation(Geometry, Index, distance)
  if not location then
    return nil, reason, detail
  end
  return finishGeometryProjection(location, Position, lateral)
end

local function geometryMatchPrecedes(First, Second)
  if First.DistanceFromStart~=Second.DistanceFromStart then
    return First.DistanceFromStart<Second.DistanceFromStart
  end
  local firstHasSegment=First.SegmentIndex~=nil
  local secondHasSegment=Second.SegmentIndex~=nil
  if firstHasSegment~=secondHasSegment then
    return firstHasSegment
  end
  return (First.SegmentIndex or First.PointIndex)<(Second.SegmentIndex or Second.PointIndex)
end

--- Project a position onto the intersection of segment and cumulative-distance bounds.
-- Each permitted segment is clipped before its nearest point is considered. Defaults search the whole route.
-- Navigation progress must supply a contiguous segment range and plausible distance interval; this function has no progress authority.
-- Query y is validated but ignored by the horizontal projection. Returned y is interpolated from the route.
-- Among matches within 0.000001 m of the true minimum distance, choose the earliest route distance, then a positive
-- segment before a point-only match, then the lowest original index. Distinct tied route distances set Ambiguous=true.
-- A shared vertex/duplicate run at one distance is not ambiguous. Excluded incoming segments are never selected.
-- All result tables, including Alternative, are independent copies. A zero-length range has no direction.
-- Malformed positions/options, invalid indices and out-of-snapshot or reversed bounds raise argument errors.
-- @param #PATHLINE.Geometry Geometry Read-only snapshot returned by CreateGeometry().
-- @param DCS#Vec3 Position Finite query position. No terrain or COORDINATE queries occur.
-- @param #PATHLINE.ProjectionOptions Options (Optional) Inclusive segment and distance bounds.
-- @return #PATHLINE.Projection Independent projection, or nil on failure.
-- @return #string "empty_search_range" for disjoint bounds, or "numeric_range" for unrepresentable computed values.
-- @return #table Effective bounds for an empty intersection; SegmentIndex or PointIndex for a numeric failure.
function PATHLINE.ProjectPosition(Geometry, Position, Options)
  checkGeometry(Geometry)
  checkGeometryPosition(Position, "Position")
  Options=checkGeometryOptions(Options, projectionOptionNames)
  local first=geometryOption(Options, "FirstSegment", 1)
  local last=geometryOption(Options, "LastSegment", Geometry.SegmentCount)
  if Geometry.SegmentCount>0 then
    checkGeometryIndex(first, Geometry.SegmentCount, "Options.FirstSegment")
    checkGeometryIndex(last, Geometry.SegmentCount, "Options.LastSegment")
    assert(first<=last, "Options.FirstSegment must not exceed Options.LastSegment")
  else
    assert(rawget(Options, "FirstSegment")==nil, "Options.FirstSegment cannot select a segment of a single-point geometry")
    assert(rawget(Options, "LastSegment")==nil, "Options.LastSegment cannot select a segment of a single-point geometry")
  end
  local minimum=geometryOption(Options, "MinDistanceFromStart", 0)
  local maximum=geometryOption(Options, "MaxDistanceFromStart", Geometry.TotalLength)
  assert(isFiniteNumber(minimum) and minimum>=0 and minimum<=Geometry.TotalLength,
    "Options.MinDistanceFromStart must lie within the geometry")
  assert(isFiniteNumber(maximum) and maximum>=0 and maximum<=Geometry.TotalLength,
    "Options.MaxDistanceFromStart must lie within the geometry")
  assert(minimum<=maximum, "Options.MinDistanceFromStart must not exceed Options.MaxDistanceFromStart")

  if Geometry.SegmentCount==0 then
    local match,reason,detail=finishGeometryProjection(geometryPointLocation(Geometry, 1), Position)
    if not match then
      return nil, reason, detail
    end
    match.Ambiguous=false
    return match
  end

  -- First establish the true minimum. Comparing successive ties would accumulate the tolerance.
  local nearest
  for index=first,last do
    local match,reason,detail=projectGeometrySegment(Geometry, Position, index, minimum, maximum)
    if reason then
      return nil, reason, detail
    end
    if match and (nearest==nil or match.DistanceToPath<nearest) then
      nearest=match.DistanceToPath
    end
  end
  if nearest==nil then
    return nil, "empty_search_range", {
      FirstSegment=first, LastSegment=last, MinDistanceFromStart=minimum, MaxDistanceFromStart=maximum,
    }
  end

  -- Retain only the earliest two distinct tied stations, not an unbounded candidate list.
  local selected,alternative
  for index=first,last do
    local match,reason,detail=projectGeometrySegment(Geometry, Position, index, minimum, maximum)
    if reason then
      return nil, reason, detail
    end
    if match and match.DistanceToPath-nearest<=projectionTieTolerance then
      if selected==nil or geometryMatchPrecedes(match, selected) then
        if selected and match.DistanceFromStart~=selected.DistanceFromStart then
          alternative=selected
        end
        selected=match
      elseif match.DistanceFromStart~=selected.DistanceFromStart then
        if alternative==nil or geometryMatchPrecedes(match, alternative) then
          alternative=match
        end
      end
    end
  end
  selected.Ambiguous=alternative~=nil
  selected.Alternative=alternative
  return selected
end

--- Get signed turn geometry at an original point, skipping only consecutive duplicate legs.
-- Returns courses and their shortest signed change in (-180,180] degrees; positive right, negative left.
-- Exactly reversing direction is represented as +180 without prescribing a physical turn side.
-- No ship speed, turn radius, terrain or corridor policy is applied. Result tables are independent copies.
-- @param #PATHLINE.Geometry Geometry Read-only snapshot returned by CreateGeometry().
-- @param #number PointIndex Original point index, an integer in [1,PointCount]. Invalid arguments raise errors.
-- @return #PATHLINE.Turn Independent corner result, or nil when one or both directions are absent.
-- @return #string "no_turn" when there is no pair of directions, including endpoints and point-only routes.
-- @return #table On failure: PointIndex, MissingIncoming and MissingOutgoing booleans.
function PATHLINE.GetTurnAtPoint(Geometry, PointIndex)
  checkGeometry(Geometry)
  checkGeometryIndex(PointIndex, Geometry.PointCount, "PointIndex")
  local incoming=Geometry._IncomingSegments[PointIndex]
  local outgoing=Geometry._OutgoingSegments[PointIndex]
  if incoming==nil or outgoing==nil then
    return nil, "no_turn", {PointIndex=PointIndex, MissingIncoming=incoming==nil, MissingOutgoing=outgoing==nil}
  end

  local incomingHeading=Geometry.Segments[incoming].Heading
  local outgoingHeading=Geometry.Segments[outgoing].Heading
  local angle=(outgoingHeading-incomingHeading+180)%360-180
  if angle==-180 then
    angle=180
  end
  return {
    Position=copyGeometryPosition(Geometry.Positions[PointIndex]),
    PointIndex=PointIndex,
    DistanceFromStart=Geometry.Distances[PointIndex],
    IncomingSegment=incoming,
    OutgoingSegment=outgoing,
    IncomingHeading=incomingHeading,
    OutgoingHeading=outgoingHeading,
    SignedAngle=angle,
  }
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Caller-stepped connection and depth validation
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Opaque, read-only connection evaluator. Jobs share configuration, not mutable work state.
-- The retained callback must have stable external rules/costs while its jobs run.
-- @type PATHLINE.ConnectionEvaluator

--- Options for an atomic connection evaluator.
-- @type PATHLINE.ConnectionEvaluatorOptions
-- @field #string CostUnits Optional non-empty cost-unit name, at most 128 bytes. Omit for validation without cost.

--- Opaque, read-only depth evaluator. Jobs own independent sampling/processing state.
-- @type PATHLINE.DepthEvaluator

--- Depth evaluator configuration; distances and depths are in meters.
-- All numeric values must be finite. Structural count caps must be positive integers.
-- No Weight, PreferredDepth or missing-data override is accepted.
-- @type PATHLINE.DepthEvaluatorOptions
-- @field #number MinDepth Required positive hard minimum. Equality passes.
-- @field #number LongitudinalSpacing Required positive maximum generated sample spacing.
-- @field #number CorridorWidth Full horizontal width, default 0; non-negative.
-- @field #number LateralSpacing Positive maximum profile spacing; required for positive width, optional otherwise.
-- @field #number MaxSectionLength Positive maximum longitudinal section length, default 1000.
-- @field #number MaxOffsets Maximum profiles per section including center/interior/edges, default 65.
-- @field #number MaxProfilePoints Maximum accepted native records per profile, default 4096; cannot bound engine-side allocation.
-- @field #number MaxDirectPoints Maximum generated direct records per profile, default 4097; at least three are needed per positive section.

--- Bounded depth coverage summary, extending the effective options with the actual lateral layout.
-- Checks discrete samples along straight strips, not every point in an area, turning hull or stopping envelope.
-- Native profile points supplement generated points; route altitude never supplies seabed evidence.
-- @type PATHLINE.DepthCoverage
-- @extends #PATHLINE.DepthEvaluatorOptions
-- @field #string EvaluatorKind "depth".
-- @field #number OffsetCount Number of parallel profiles per section, including the center; 1 at zero width.
-- @field #number ActualLateralSpacing Equal lateral gap in meters, at most LateralSpacing; 0 at zero width.

--- Independent context passed to a connection callback with copied Vec3 endpoints.
-- @type PATHLINE.ConnectionContext
-- @field #string ContextId Original job context; alternatively a finite integer, including zero, or nil.
-- @field #number SegmentIndex Original segment index, including duplicate endpoints; nil for single-point geometry.
-- @field #number PointIndex 1 for single-point geometry; otherwise nil.
-- @field #number StartDistance Horizontal distance from the route start in meters.
-- @field #number EndDistance Horizontal distance from the route start in meters.
-- @field #number Length Horizontal connection length in meters, including zero.

--- Bounded independent failure evidence. Omit unknown fields; never invent missing depth or altitude.
-- Callback evidence accepts Position, ProfileY, ProfileOffset, RouteDistance, Depth, SurfaceType, Source and Cause only.
-- Original indices and limit details are assigned by the job, not the callback.
-- @type PATHLINE.ValidationFailure
-- @field #number SegmentIndex Original failed/pending segment index, or nil for a single point.
-- @field #number PointIndex Single-point index, when applicable.
-- @field #number SectionIndex Depth section index within the original segment, when applicable.
-- @field #table Position Copied horizontal {x,z} coordinates; not a DCS Vec2 or Vec3.
-- @field #number ProfileY Native profile height in meters, when supplied; not route altitude or water depth.
-- @field #number ProfileOffset Signed lateral distance in meters; positive right of travel.
-- @field #number RouteDistance Non-negative distance from route start in meters, when known.
-- @field #number Depth Finite effective depth in meters; may be negative when a native profile rises above the water surface.
-- @field #number SurfaceType Finite DCS surface type, when known.
-- @field #string Source Evidence source, at most 128 bytes.
-- @field #string Cause Underlying cause, at most 128 bytes.
-- @field #number Limit Resource cap that prevented further work, when known.
-- @field #number Required Count required for the next operation, when known and representable.

--- Result returned by an atomic callback(Start, Goal, Context).
-- The job checks/copies this record; callers may retain or modify their original result afterward.
-- @type PATHLINE.ConnectionResult
-- @field #string Status "clear", "blocked" or "unavailable".
-- @field #string Reason Required non-empty failure reason, at most 128 bytes; absent when clear.
-- @field #number Cost Finite non-negative cost, required only for clear results when CostUnits was configured. Zero is valid.
-- @field #PATHLINE.ValidationFailure Evidence Optional bounded callback evidence; see its accepted fields.

--- Immutable job limits and identity, copied at start.
-- @type PATHLINE.ValidationOptions
-- @field #string ContextId Optional non-empty string or finite integer. Every step must supply the same value.
-- @field #number MaxWorkUnits Non-negative integer total cap, default 200000. Zero admits no work.
-- @field #number MaxEvaluatorCalls Connection-only non-negative integer total callback cap, default 4096.
-- @field #number MaxPointChecks Depth-only non-negative integer total point-check cap, default 50000.
-- @field #number MaxProfileQueries Depth-only non-negative integer total native-profile cap, default 4096.
-- @field #number MaxCPUSeconds Optional finite non-negative total active CPU seconds; no implicit default.

--- Per-step limits. Count fields are non-negative integers; zero is preserved.
-- Unknown fields and depth-specific budgets are rejected for connection evaluators.
-- @type PATHLINE.ValidationBudget
-- @field #number MaxWorkUnits Default 64. Bounds native operations, individual processing and state advances; callback and commit are separate units.
-- @field #number MaxEvaluatorCalls Connection-only default 1. A pending commit needs no new callback allowance.
-- @field #number MaxPointChecks Depth-only default 8. One point check makes at most two native queries.
-- @field #number MaxProfileQueries Depth-only default 1. Processing a returned profile needs no new query allowance.
-- @field #number MaxCPUSeconds Optional finite non-negative active CPU seconds; cooperative, never preemptive.

--- Opaque validation job. Pass the handle to step/report/cancel; do not edit it.
-- No owned timer, scheduler, controller or global job registry. Abandoned handles are collectible.
-- @type PATHLINE.ValidationJob

--- Work accounting. Native point/profile counts are absent for opaque connection callbacks.
-- @type PATHLINE.ValidationCounters
-- @field #number WorkUnits Admitted callbacks, native queries/checks, individual processing and bounded state advances, including failures/cancellation.
-- @field #number EvaluatorCalls Admitted whole-connection callbacks; internal work is not counted separately.
-- @field #number PointChecks Depth-only admitted VECTOR._CheckDepthPoint calls, including generated/native samples.
-- @field #number ProfileQueries Depth-only admitted native profile calls; no repeated query when resuming processing.
-- @field #number FallbackProfiles Depth-only valid empty/single-point native arrays using direct sampling. Longer arrays also require direct samples.
-- @field #number SkippedDegenerateSegments Depth-only original duplicate legs; common endpoints are checked through incident legs or once for an all-duplicate route.
-- @field #number CPUSeconds Measured active CPU seconds, or nil if any observation is unavailable. Excludes time between steps.

--- Last actual step; independent copy. Querying or revisiting a terminal job does not reset it.
-- @type PATHLINE.ValidationSlice
-- @extends #PATHLINE.ValidationCounters
-- @field #string YieldReason slice_work_limit, slice_evaluator_limit, slice_point_limit, slice_profile_query_limit or slice_cpu_limit while running; otherwise nil.
-- @field #number CPUOverrunSeconds Largest measured excess over a requested slice/total CPU cap, or nil without a usable measurement/cap.

--- Independent summary of validation. All nested tables are independent of the job.
-- Only "clear" completes validation; the owner must still check ContextId before consuming a result.
-- @type PATHLINE.ValidationReport
-- @field #string Status running, clear, blocked, unavailable, limited, cancelled or error. Only running is resumable.
-- @field #string Reason Failure reason; nil for running/clear. Exceptions become evaluation_error and are also rethrown unchanged.
-- @field #string ContextId Original context; alternatively an integer or nil.
-- @field #string EvaluatorKind "connection" or "depth".
-- @field #number CompletedSegments Original successfully committed segments; zero for single-point geometry even when clear.
-- @field #number CheckedPrefixDistance Horizontal meters through committed connections or depth sections with every offset checked; not stopping clearance.
-- @field #number CompletedCost Committed cost, starting at zero; nil without CostUnits.
-- @field #number TotalCost Final cost only when clear and CostUnits was configured.
-- @field #string CostUnits Configured cost units, or nil.
-- @field #PATHLINE.ValidationFailure Failure Independent limiting evidence, when applicable.
-- @field #table Cursor Diagnostic Phase, SegmentIndex/PointIndex and applicable SectionIndex, OffsetIndex, SampleIndex; absent when terminal. Never an external continuation token.
-- @field #PATHLINE.ValidationCounters Counters Cumulative work accounting.
-- @field #PATHLINE.ValidationSlice LastSlice Last step accounting; absent before the first step.
-- @field #table Coverage EvaluatorKind and optional CostUnits for callbacks; DepthCoverage for depth jobs. No implied hull/continuous-area coverage.

-- Keep state in each handle's closure. The weak identity set contains no state/callback
-- references: unlike weak-key state maps, this also collects callback/handle cycles in Lua 5.1.
local validationStateKey={}
local validationHandleKinds=setmetatable({}, {__mode="k"})
local connectionEvaluatorOptions={CostUnits=true}
local validationOptions={ContextId=true, MaxWorkUnits=true, MaxEvaluatorCalls=true, MaxCPUSeconds=true}
local validationBudgetOptions={MaxWorkUnits=true, MaxEvaluatorCalls=true, MaxCPUSeconds=true}
local depthEvaluatorOptions={MinDepth=true, LongitudinalSpacing=true, CorridorWidth=true, LateralSpacing=true,
  MaxSectionLength=true, MaxOffsets=true, MaxProfilePoints=true, MaxDirectPoints=true}
local depthValidationOptions={ContextId=true, MaxWorkUnits=true, MaxPointChecks=true, MaxProfileQueries=true, MaxCPUSeconds=true}
local depthValidationBudgetOptions={MaxWorkUnits=true, MaxPointChecks=true, MaxProfileQueries=true, MaxCPUSeconds=true}
local largestExactValidationInteger=9007199254740991
local connectionResultFields={Status=true, Reason=true, Cost=true, Evidence=true}
local validationEvidenceFields={Position=true, ProfileY=true, ProfileOffset=true, RouteDistance=true,
  Depth=true, SurfaceType=true, Source=true, Cause=true}

local function newValidationHandle(State, Kind)
  local handle=setmetatable({}, {
    __index=function(_, Key)
      if Key==validationStateKey then
        return State
      end
    end,
    __newindex=function()
      error(Kind.." is read-only", 2)
    end,
    __metatable="PATHLINE."..Kind,
  })
  validationHandleKinds[handle]=Kind
  return handle
end

local function validationState(Handle, Kind)
  assert(type(Handle)=="table" and validationHandleKinds[Handle]==Kind,
    Kind.." must be a handle created by PATHLINE")
  return Handle[validationStateKey]
end

local function checkValidationFields(Value, Fields, Name)
  assert(type(Value)=="table", Name.." must be a table")
  for field in next,Value do
    assert(Fields[field], "Unknown "..Name.." field: "..tostring(field))
  end
end

local function checkValidationString(Value, Name)
  assert(type(Value)=="string" and #Value>0 and #Value<=128,
    Name.." must be a non-empty string of at most 128 bytes")
end

local function checkValidationContext(Value)
  assert(Value==nil or (type(Value)=="string" and #Value>0)
    or (isFiniteNumber(Value) and Value%1==0),
    "ContextId must be a non-empty string or finite integer")
end

local function validationLimits(Options, Total, Kind)
  if Options==nil then
    Options={}
  end
  local fields=Total and validationOptions or validationBudgetOptions
  if Kind=="depth" then
    fields=Total and depthValidationOptions or depthValidationBudgetOptions
  end
  checkValidationFields(Options, fields, "Options")
  local limits={
    MaxWorkUnits=geometryOption(Options, "MaxWorkUnits", Total and 200000 or 64),
    MaxCPUSeconds=rawget(Options, "MaxCPUSeconds"),
  }
  local countNames={"MaxWorkUnits", "MaxEvaluatorCalls"}
  if Kind=="depth" then
    limits.MaxPointChecks=geometryOption(Options, "MaxPointChecks", Total and 50000 or 8)
    limits.MaxProfileQueries=geometryOption(Options, "MaxProfileQueries", Total and 4096 or 1)
    countNames={"MaxWorkUnits", "MaxPointChecks", "MaxProfileQueries"}
  else
    limits.MaxEvaluatorCalls=geometryOption(Options, "MaxEvaluatorCalls", Total and 4096 or 1)
  end
  for _,name in ipairs(countNames) do
    local value=limits[name]
    assert(isFiniteNumber(value) and value>=0 and value%1==0, name.." must be a non-negative integer")
  end
  assert(limits.MaxCPUSeconds==nil or (isFiniteNumber(limits.MaxCPUSeconds) and limits.MaxCPUSeconds>=0),
    "MaxCPUSeconds must be finite and non-negative")
  if Total then
    limits.ContextId=rawget(Options, "ContextId")
    checkValidationContext(limits.ContextId)
  end
  return limits
end

local function newValidationCounters(Kind)
  if Kind=="depth" then
    return {WorkUnits=0, PointChecks=0, ProfileQueries=0, FallbackProfiles=0, SkippedDegenerateSegments=0}
  end
  return {WorkUnits=0, EvaluatorCalls=0}
end

local function countValidationWork(State, Name)
  local report=State.Report
  report.Counters[Name]=report.Counters[Name]+1
  report.LastSlice[Name]=report.LastSlice[Name]+1
end

-- Only internal fixed-schema records reach this copier, never arbitrary callback graphs.
local function copyValidationRecord(Value)
  if type(Value)~="table" then
    return Value
  end
  local result={}
  for key,value in next,Value do
    result[key]=copyValidationRecord(value)
  end
  return result
end

local function copyValidationEvidence(Evidence)
  if Evidence==nil then
    return nil
  end
  checkValidationFields(Evidence, validationEvidenceFields, "Evidence")
  local result={}
  for field in next,validationEvidenceFields do
    local value=rawget(Evidence, field)
    if value~=nil then
      if field=="Position" then
        checkValidationFields(value, {x=true,z=true}, "Evidence.Position")
        assert(isFiniteNumber(rawget(value, "x")) and isFiniteNumber(rawget(value, "z")),
          "Evidence.Position must contain finite x/z coordinates")
        result.Position={x=rawget(value, "x"), z=rawget(value, "z")}
      elseif field=="Source" or field=="Cause" then
        checkValidationString(value, "Evidence."..field)
        result[field]=value
      else
        assert(isFiniteNumber(value), "Evidence."..field.." must be finite")
        if field=="RouteDistance" then
          assert(value>=0, "Evidence."..field.." must be non-negative")
        end
        result[field]=value
      end
    end
  end
  return result
end

local function copyConnectionResult(Result, CostUnits)
  checkValidationFields(Result, connectionResultFields, "Result")
  local status,reason,cost=rawget(Result, "Status"),rawget(Result, "Reason"),rawget(Result, "Cost")
  assert(status=="clear" or status=="blocked" or status=="unavailable", "Invalid connection Status")
  if status=="clear" then
    assert(reason==nil, "Clear connection Reason must be nil")
    if CostUnits then
      assert(isFiniteNumber(cost) and cost>=0, "Clear connection Cost must be finite and non-negative")
    else
      assert(cost==nil, "Connection Cost requires configured CostUnits")
    end
  else
    checkValidationString(reason, "Connection Reason")
    assert(cost==nil, "Failed connection Cost must be nil")
  end
  return {Status=status, Reason=reason, Cost=cost, Evidence=copyValidationEvidence(rawget(Result, "Evidence"))}
end

local function validationFailure(State, Evidence)
  local failure=Evidence or {}
  local cursor=State.Report.Cursor
  if cursor then
    failure.SegmentIndex=cursor.SegmentIndex
    failure.PointIndex=cursor.PointIndex
    failure.SectionIndex=cursor.SectionIndex
  end
  if State.Depth then
    failure.ProfileOffset=State.Depth.Offset
  end
  return failure
end

local function finishValidation(State, Status, Reason, Failure)
  local report=State.Report
  if report.Status~="running" then
    return
  end
  report.Status,report.Reason,report.Failure=Status,Reason,Failure
  report.Cursor=nil
  if report.LastSlice then
    report.LastSlice.YieldReason=nil
  end
  if Status=="clear" then
    report.TotalCost=report.CompletedCost
  end
  -- Retaining a final handle must not retain the route, callback captures or a pending result.
  State.Geometry,State.Callback,State.Pending=nil,nil,nil
  State.Depth,State.DepthOptions=nil,nil
end

--- Create a reusable atomic connection evaluator without invoking it.
-- Callback(Start, Goal, Context) receives independent endpoint/context copies and returns a ConnectionResult.
-- Every original connection is passed whole, including duplicates; custom costs are never silently split.
-- Single-point geometry is checked once with equal endpoint values. Callback exceptions propagate during stepping.
-- External callback configuration must stay stable, or the owner must cancel/invalidate its jobs.
-- Invalid callback/options raise argument errors; no terrain or scheduler access occurs here.
-- @param #function Callback Connection rule and optional cost evaluator.
-- @param #PATHLINE.ConnectionEvaluatorOptions Options (Optional) Copied configuration.
-- @return #PATHLINE.ConnectionEvaluator Opaque read-only descriptor; may be shared by independent jobs.
function PATHLINE.CreateConnectionEvaluator(Callback, Options)
  assert(type(Callback)=="function", "Callback must be a function")
  Options=checkGeometryOptions(Options, connectionEvaluatorOptions)
  local costUnits=rawget(Options, "CostUnits")
  if costUnits~=nil then
    checkValidationString(costUnits, "CostUnits")
  end
  return newValidationHandle({Kind="connection", Callback=Callback, CostUnits=costUnits}, "Evaluator")
end

--- Create a reusable evaluator for sampled water depth along a horizontal corridor.
-- Configuration is copied; creation performs no terrain work and allocates no offset array.
-- Checks use a hard MinDepth threshold, without preference weights or cost. Each section checks
-- the center, alternating right/left interior profiles, and both exact corridor edges.
-- Positive width requires LateralSpacing. Actual spacing never exceeds that maximum.
-- Invalid options raise argument errors. Unrepresentable layouts return nil, "numeric_range";
-- excessive offset counts return nil, "offset_limit", {Required=..., Limit=...} without coarsening.
-- Terrain rules/data must remain stable for a job, or its owner must cancel/change context.
-- @param #PATHLINE.DepthEvaluatorOptions Options Required sampling settings; see their units and defaults.
-- @return #PATHLINE.DepthEvaluator Opaque read-only descriptor on success.
-- @return #string Failure reason on layout failure, otherwise nil.
-- @return #table Optional independent layout-limit details.
function PATHLINE.CreateDepthEvaluator(Options)
  Options=checkGeometryOptions(Options, depthEvaluatorOptions)
  local config={
    MinDepth=rawget(Options, "MinDepth"),
    LongitudinalSpacing=rawget(Options, "LongitudinalSpacing"),
    CorridorWidth=geometryOption(Options, "CorridorWidth", 0),
    LateralSpacing=rawget(Options, "LateralSpacing"),
    MaxSectionLength=geometryOption(Options, "MaxSectionLength", 1000),
    MaxOffsets=geometryOption(Options, "MaxOffsets", 65),
    MaxProfilePoints=geometryOption(Options, "MaxProfilePoints", 4096),
    MaxDirectPoints=geometryOption(Options, "MaxDirectPoints", 4097),
  }
  for _,name in ipairs({"MinDepth", "LongitudinalSpacing", "MaxSectionLength"}) do
    assert(isFiniteNumber(config[name]) and config[name]>0, name.." must be finite and positive")
  end
  assert(isFiniteNumber(config.CorridorWidth) and config.CorridorWidth>=0, "CorridorWidth must be finite and non-negative")
  if config.CorridorWidth>0 or config.LateralSpacing~=nil then
    assert(isFiniteNumber(config.LateralSpacing) and config.LateralSpacing>0, "LateralSpacing must be finite and positive")
  end
  for _,name in ipairs({"MaxOffsets", "MaxProfilePoints", "MaxDirectPoints"}) do
    assert(isFiniteNumber(config[name]) and config[name]>0 and config[name]%1==0, name.." must be a positive integer")
  end

  config.HalfWidth=config.CorridorWidth/2
  config.SideCount=0
  config.ActualLateralSpacing=0
  if config.CorridorWidth>0 then
    config.SideCount=math.ceil(config.HalfWidth/config.LateralSpacing)
    if config.HalfWidth==0 or config.SideCount<1 or not isFiniteNumber(config.SideCount)
      or config.SideCount>(largestExactValidationInteger-1)/2 then
      return nil,"numeric_range"
    end
    config.ActualLateralSpacing=config.HalfWidth/config.SideCount
    if config.ActualLateralSpacing==0 then
      return nil,"numeric_range"
    end
  end
  config.OffsetCount=1+2*config.SideCount
  if config.OffsetCount>config.MaxOffsets then
    return nil,"offset_limit",{Required=config.OffsetCount, Limit=config.MaxOffsets}
  end
  return newValidationHandle({Kind="depth", Options=config}, "Evaluator")
end

--- Start an independent validation job without executing the evaluator.
-- Retains the geometry read-only; copies options. Rebuild geometry after changing points.
-- Slice limits yield running; total limits end limited when another operation needs the exhausted resource.
-- No timers, automatic retries, movement commands or resumptions are installed.
-- Invalid geometry/evaluator/options raise argument errors.
-- @param #PATHLINE.Geometry Geometry Snapshot returned by CreateGeometry().
-- @param #table Evaluator Opaque ConnectionEvaluator or DepthEvaluator descriptor returned by its factory.
-- @param #PATHLINE.ValidationOptions Options (Optional) Total limits and context identity.
-- @return #PATHLINE.ValidationJob Opaque job; always initially running, even for single-point geometry.
-- @return #PATHLINE.ValidationReport Independent initial summary; changing it cannot change the job.
function PATHLINE.StartValidation(Geometry, Evaluator, Options)
  checkGeometry(Geometry)
  local evaluator=validationState(Evaluator, "Evaluator")
  local limits=validationLimits(Options, true, evaluator.Kind)
  local cursor={Phase="evaluate"}
  if Geometry.SegmentCount==0 then
    cursor.PointIndex=1
  else
    cursor.SegmentIndex=1
  end
  local report={
    Status="running", ContextId=limits.ContextId, EvaluatorKind=evaluator.Kind,
    CompletedSegments=0, CheckedPrefixDistance=0, CostUnits=evaluator.CostUnits,
    Cursor=cursor, Counters=newValidationCounters(evaluator.Kind),
    Coverage={EvaluatorKind="connection", CostUnits=evaluator.CostUnits},
  }
  if evaluator.CostUnits then
    report.CompletedCost=0
  end
  local state={Geometry=Geometry, Callback=evaluator.Callback, Limits=limits, Report=report, CPUComplete=true}
  if evaluator.Kind=="depth" then
    state.DepthOptions=evaluator.Options
    state.Depth={}
    report.Coverage=copyValidationRecord(evaluator.Options)
    report.Coverage.HalfWidth,report.Coverage.SideCount=nil,nil
    report.Coverage.EvaluatorKind="depth"
    if Geometry.TotalLength==0 then
      report.Cursor={Phase="point_setup", PointIndex=1}
    else
      cursor.Phase="segment"
    end
  end
  return newValidationHandle(state, "Job"),copyValidationRecord(report)
end

--- Read an independent bounded report without advancing or measuring the job.
-- Raw route/sample arrays and callback-owned tables are never exposed. CPUSeconds is nil before the first step.
-- @param #PATHLINE.ValidationJob Job Valid job handle, running or terminal.
-- @return #PATHLINE.ValidationReport Independently owned summary and nested records.
function PATHLINE.GetValidationReport(Job)
  return copyValidationRecord(validationState(Job, "Job").Report)
end

--- Cancel a running validation job and release its retained work.
-- Terminal jobs retain their first result. A callback may cancel its own job; its uncommitted result is discarded.
-- In-flight atomic work cannot be interrupted; its CPU/count accounting finishes when that call returns.
-- This function does not stop/resume a vessel. The owner retains movement authority and checks result context.
-- @param #PATHLINE.ValidationJob Job Valid job handle.
-- @param #string Reason (Optional) Non-empty reason, at most 128 bytes; default "cancelled".
-- @return #PATHLINE.ValidationReport Independent report; repeated cancellation is idempotent.
function PATHLINE.CancelValidation(Job, Reason)
  local state=validationState(Job, "Job")
  if state.Report.Status=="running" then
    if Reason==nil then
      Reason="cancelled"
    end
    checkValidationString(Reason, "Reason")
    finishValidation(state, "cancelled", Reason)
  end
  return copyValidationRecord(state.Report)
end

local function validationCPUUnavailable(State, Timing)
  Timing.Read=nil
  State.CPUComplete=false
  State.Report.Counters.CPUSeconds=nil
  State.Report.LastSlice.CPUSeconds=nil
end

local function updateValidationCPU(State, Timing)
  if not Timing.Read then
    return
  end
  local now=Timing.Read()
  if not isFiniteNumber(now) or now<0 or (Timing.Previous and now<Timing.Previous) then
    validationCPUUnavailable(State, Timing)
    return
  end
  Timing.Previous=now
  if Timing.Start==nil then
    Timing.Start=now
  end
  local elapsed=now-Timing.Start
  local total=Timing.BaseCPU+elapsed
  if not isFiniteNumber(elapsed) or not isFiniteNumber(total) then
    validationCPUUnavailable(State, Timing)
    return
  end
  State.Report.LastSlice.CPUSeconds=elapsed
  if State.CPUComplete then
    State.Report.Counters.CPUSeconds=total
  end
end

local function limitValidation(State, Reason, Limit, Required)
  local failure=validationFailure(State)
  failure.Limit=Limit
  if isFiniteNumber(Required) then
    failure.Required=Required
  end
  finishValidation(State, "limited", Reason, failure)
end

-- Admission is ordered: total limits before slice limits. Processing/commits need
-- only work/CPU; reserve native/callback counters immediately before those operations.
local function admitValidationWork(State, Budget)
  local report=State.Report
  local total,slice,limits=report.Counters,report.LastSlice,State.Limits
  local phase=report.Cursor.Phase
  local counter,cap,reason
  if phase=="evaluate" then
    counter,cap,reason="EvaluatorCalls","MaxEvaluatorCalls","evaluator_limit"
  elseif phase=="query" then
    counter,cap,reason="ProfileQueries","MaxProfileQueries","profile_query_limit"
  elseif phase=="check" or phase=="point" then
    counter,cap,reason="PointChecks","MaxPointChecks","point_limit"
  end
  if (limits.MaxCPUSeconds~=nil or Budget.MaxCPUSeconds~=nil) and slice.CPUSeconds==nil then
    limitValidation(State, "cpu_clock_unavailable")
  elseif total.WorkUnits>=limits.MaxWorkUnits then
    limitValidation(State, "work_limit", limits.MaxWorkUnits, total.WorkUnits+1)
  elseif limits.MaxCPUSeconds~=nil and total.CPUSeconds>=limits.MaxCPUSeconds then
    limitValidation(State, "cpu_limit", limits.MaxCPUSeconds)
  elseif counter and total[counter]>=limits[cap] then
    limitValidation(State, reason, limits[cap], total[counter]+1)
  elseif slice.WorkUnits>=Budget.MaxWorkUnits then
    slice.YieldReason="slice_work_limit"
  elseif Budget.MaxCPUSeconds~=nil and slice.CPUSeconds>=Budget.MaxCPUSeconds then
    slice.YieldReason="slice_cpu_limit"
  elseif counter and slice[counter]>=Budget[cap] then
    slice.YieldReason="slice_"..reason
  else
    countValidationWork(State, "WorkUnits")
    if counter then
      countValidationWork(State, counter)
    end
    return true
  end
  return false
end

local function evaluateValidationConnection(State)
  local geometry,report=State.Geometry,State.Report
  local index=report.Cursor.SegmentIndex
  local start,goal,context
  if index then
    local segment=geometry.Segments[index]
    start,goal=geometry.Positions[index],geometry.Positions[index+1]
    context={SegmentIndex=index, Length=segment.Length, StartDistance=segment.StartDistance, EndDistance=segment.EndDistance}
  else
    start,goal=geometry.Positions[1],geometry.Positions[1]
    context={PointIndex=1, Length=0, StartDistance=0, EndDistance=0}
  end
  context.ContextId=report.ContextId
  local result=State.Callback(copyGeometryPosition(start), copyGeometryPosition(goal), copyValidationRecord(context))
  if report.Status~="running" then
    return
  end
  result=copyConnectionResult(result, report.CostUnits)
  if result.Status~="clear" then
    finishValidation(State, result.Status, result.Reason, validationFailure(State, result.Evidence))
    return
  end
  State.Pending={Cost=result.Cost, Context=context}
  report.Cursor.Phase="commit"
end

local function commitValidationConnection(State)
  local report,pending=State.Report,State.Pending
  if report.CostUnits then
    local cost=report.CompletedCost+pending.Cost
    if not isFiniteNumber(cost) then
      limitValidation(State, "numeric_range")
      return
    end
    report.CompletedCost=cost
  end
  local index=pending.Context.SegmentIndex
  if index then
    report.CompletedSegments=index
  end
  report.CheckedPrefixDistance=pending.Context.EndDistance
  if not index or index==State.Geometry.SegmentCount then
    finishValidation(State, "clear")
  else
    State.Pending=nil
    report.Cursor={Phase="evaluate", SegmentIndex=index+1}
  end
end

-- Every depth phase performs bounded bookkeeping or one explicitly admitted native
-- operation. No phase scans a complete native array or sorts a complete profile.
local function failDepthValidation(State, Reason)
  finishValidation(State, "unavailable", Reason, validationFailure(State))
end

local function depthValidationPosition(Start, Goal, Fraction)
  if Fraction==0 then
    return {x=Start.x, y=0, z=Start.z}
  elseif Fraction==1 then
    return {x=Goal.x, y=0, z=Goal.z}
  end
  return {x=(1-Fraction)*Start.x+Fraction*Goal.x, y=0, z=(1-Fraction)*Start.z+Fraction*Goal.z}
end

local function finiteDepthPosition(Position)
  return isFiniteNumber(Position.x) and isFiniteNumber(Position.z)
end

local function sameDepthPosition(First, Second)
  return First.x==Second.x and First.z==Second.z
end

local function prepareDepthSegment(State)
  local geometry,report=State.Geometry,State.Report
  local index=report.Cursor.SegmentIndex
  local segment=geometry.Segments[index]
  if segment.Length==0 then
    -- Incident positive segments check the shared endpoint. An entirely duplicate
    -- route is checked once before entering this bounded skip sequence.
    countValidationWork(State, "SkippedDegenerateSegments")
    report.CompletedSegments=index
    if index==geometry.SegmentCount then
      finishValidation(State, "clear")
    else
      report.Cursor={Phase="segment", SegmentIndex=index+1}
    end
    return
  end

  local sectionCount=math.ceil(segment.Length/State.DepthOptions.MaxSectionLength)
  if not isFiniteNumber(sectionCount) or sectionCount<1 or sectionCount>largestExactValidationInteger then
    limitValidation(State, "numeric_range")
    return
  end
  State.Depth={SectionCount=sectionCount}
  report.Cursor={Phase="section", SegmentIndex=index, SectionIndex=1}
end

local function prepareDepthSection(State)
  local geometry,cursor,depth=State.Geometry,State.Report.Cursor,State.Depth
  local segment=geometry.Segments[cursor.SegmentIndex]
  local firstFraction=(cursor.SectionIndex-1)/depth.SectionCount
  local lastFraction=cursor.SectionIndex/depth.SectionCount
  local start,goal=geometry.Positions[cursor.SegmentIndex],geometry.Positions[cursor.SegmentIndex+1]
  depth.Start=depthValidationPosition(start, goal, firstFraction)
  depth.Goal=depthValidationPosition(start, goal, lastFraction)
  depth.UX,depth.UZ=segment._UX,segment._UZ
  depth.StartDistance=segment.StartDistance+firstFraction*segment.Length
  depth.EndDistance=segment.StartDistance+lastFraction*segment.Length
  if cursor.SectionIndex==depth.SectionCount then
    depth.EndDistance=segment.EndDistance
  end
  depth.Length=horizontalLength(depth.Goal.x-depth.Start.x, depth.Goal.z-depth.Start.z)
  if not finiteDepthPosition(depth.Start) or not finiteDepthPosition(depth.Goal)
    or not depth.Length or depth.Length<=0 or not isFiniteNumber(depth.EndDistance)
    or depth.EndDistance<=depth.StartDistance then
    limitValidation(State, "numeric_range")
    return
  end
  depth.RightProfile,depth.LeftProfile=nil,nil
  cursor.OffsetIndex=1
  cursor.Phase="profile_setup"
end

local function prepareDepthProfile(State)
  local depth,options,cursor=State.Depth,State.DepthOptions,State.Report.Cursor
  local offset=0
  if cursor.OffsetIndex>1 then
    local sideIndex=math.floor(cursor.OffsetIndex/2)
    offset=options.HalfWidth*(sideIndex/options.SideCount)
    if cursor.OffsetIndex%2==1 then
      offset=-offset
    end
  end
  depth.Offset=offset
  local offsetX,offsetZ=-depth.UZ*offset,depth.UX*offset
  depth.ProfileStart={x=depth.Start.x+offsetX, y=0, z=depth.Start.z+offsetZ}
  depth.ProfileGoal={x=depth.Goal.x+offsetX, y=0, z=depth.Goal.z+offsetZ}
  local length=horizontalLength(depth.ProfileGoal.x-depth.ProfileStart.x, depth.ProfileGoal.z-depth.ProfileStart.z)
  if not finiteDepthPosition(depth.ProfileStart) or not finiteDepthPosition(depth.ProfileGoal)
    or not length or length<=0 then
    limitValidation(State, "numeric_range")
    return
  end
  if offset~=0 then
    local previous=depth.LeftProfile
    if offset>0 then
      previous=depth.RightProfile
    end
    if sameDepthPosition(depth.ProfileStart, depth.Start) or sameDepthPosition(depth.ProfileGoal, depth.Goal)
      or (previous and (sameDepthPosition(depth.ProfileStart, previous.Start) or sameDepthPosition(depth.ProfileGoal, previous.Goal))) then
      -- A finite offset can still disappear when added to large coordinates.
      -- Rechecking the same line must not certify an unrepresented corridor.
      limitValidation(State, "numeric_range")
      return
    end
    local profile={Start=depth.ProfileStart, Goal=depth.ProfileGoal}
    if offset>0 then
      depth.RightProfile=profile
    else
      depth.LeftProfile=profile
    end
  end
  depth.ProfileLength=length
  depth.ProfileUX=(depth.ProfileGoal.x-depth.ProfileStart.x)/length
  depth.ProfileUZ=(depth.ProfileGoal.z-depth.ProfileStart.z)/length
  depth.Intervals=math.max(2, math.ceil(length/options.LongitudinalSpacing))
  local directCount=depth.Intervals+1
  if not isFiniteNumber(directCount) or directCount>largestExactValidationInteger then
    limitValidation(State, "numeric_range")
    return
  elseif directCount>options.MaxDirectPoints then
    limitValidation(State, "direct_point_limit", options.MaxDirectPoints, directCount)
    return
  end
  depth.Records={}
  depth.RecordCount,depth.NativeCount,depth.MaxNativeIndex,depth.DirectIndex=0,0,0,0
  cursor.Phase="query"
end

local function queryDepthProfile(State)
  local depth=State.Depth
  local start,goal=depth.ProfileStart,depth.ProfileGoal
  -- Terrain profile order is canonical; sorting/evidence below use original travel.
  if start.x>goal.x or (start.x==goal.x and start.z>goal.z) then
    start,goal=goal,start
  end
  local profile=PATHLINE._QueryDepthProfile(copyGeometryPosition(start), copyGeometryPosition(goal))
  if State.Report.Status~="running" then
    return
  end
  if type(profile)~="table" then
    failDepthValidation(State, "profile_unavailable")
    return
  end
  depth.Raw=profile
  State.Report.Cursor.Phase="collect"
end

local function collectDepthProfile(State)
  local depth=State.Depth
  local key,point=next(depth.Raw, depth.RawKey)
  if key==nil then
    if depth.NativeCount~=depth.MaxNativeIndex then
      failDepthValidation(State, "invalid_profile")
      return
    end
    if depth.NativeCount<2 then
      countValidationWork(State, "FallbackProfiles")
    end
    depth.Raw,depth.RawKey=nil,nil
    State.Report.Cursor.Phase="generate"
    return
  end
  depth.RawKey=key
  if not isFiniteNumber(key) or key<1 or key%1~=0 or key>largestExactValidationInteger then
    failDepthValidation(State, "invalid_profile")
    return
  end
  local count=depth.NativeCount+1
  if count>State.DepthOptions.MaxProfilePoints then
    limitValidation(State, "profile_point_limit", State.DepthOptions.MaxProfilePoints, count)
    return
  end
  if type(point)~="table" or not isFiniteNumber(rawget(point, "x"))
    or not isFiniteNumber(rawget(point, "y")) or not isFiniteNumber(rawget(point, "z")) then
    failDepthValidation(State, "invalid_profile")
    return
  end
  local position={x=rawget(point, "x"), y=rawget(point, "y"), z=rawget(point, "z")}
  local along=(position.x-depth.ProfileStart.x)*depth.ProfileUX+(position.z-depth.ProfileStart.z)*depth.ProfileUZ
  if sameDepthPosition(position, depth.ProfileStart) then
    along=0
  elseif sameDepthPosition(position, depth.ProfileGoal) then
    along=depth.ProfileLength
  end
  if not isFiniteNumber(along) then
    limitValidation(State, "numeric_range")
    return
  end
  along=math.max(0, math.min(depth.ProfileLength, along))
  depth.NativeCount=count
  depth.MaxNativeIndex=math.max(depth.MaxNativeIndex, key)
  depth.RecordCount=count
  depth.Records[count]={Position=position, Along=along, Native=true, Index=key}
end

local function generateDepthPoint(State)
  local depth=State.Depth
  local fraction=depth.DirectIndex/depth.Intervals
  local position=depthValidationPosition(depth.ProfileStart, depth.ProfileGoal, fraction)
  local previous=depth.PreviousDirect
  if not finiteDepthPosition(position) or (previous and previous.x==position.x and previous.z==position.z) then
    limitValidation(State, "numeric_range")
    return
  end
  depth.RecordCount=depth.RecordCount+1
  depth.Records[depth.RecordCount]={Position=position, Along=fraction*depth.ProfileLength, Native=false, Index=depth.DirectIndex+1}
  depth.PreviousDirect=position
  depth.DirectIndex=depth.DirectIndex+1
  if depth.DirectIndex>depth.Intervals then
    depth.PreviousDirect=nil
    depth.Sort={Width=1, Left=1, Output={}}
    State.Report.Cursor.Phase="sort"
  end
end

local function depthRecordBefore(First, Second)
  if First.Along~=Second.Along then
    return First.Along<Second.Along
  elseif First.Native~=Second.Native then
    return First.Native
  end
  return First.Index<Second.Index
end

local function sortDepthRecords(State)
  local depth=State.Depth
  local sort=depth.Sort
  -- Merge adjacent half-open ranges. Initialize/advance a range in its own unit;
  -- each subsequent unit compares at most two heads and writes one output record.
  if sort.LeftCursor==nil then
    sort.LeftCursor=sort.Left
    sort.Middle=math.min(sort.Left+sort.Width, depth.RecordCount+1)
    sort.RightCursor=sort.Middle
    sort.Right=math.min(sort.Middle+sort.Width, depth.RecordCount+1)
    sort.OutputIndex=sort.Left
    return
  end
  if sort.LeftCursor<sort.Middle or sort.RightCursor<sort.Right then
    local takeLeft=sort.LeftCursor<sort.Middle and (sort.RightCursor>=sort.Right
      or depthRecordBefore(depth.Records[sort.LeftCursor], depth.Records[sort.RightCursor]))
    if takeLeft then
      sort.Output[sort.OutputIndex]=depth.Records[sort.LeftCursor]
      sort.LeftCursor=sort.LeftCursor+1
    else
      sort.Output[sort.OutputIndex]=depth.Records[sort.RightCursor]
      sort.RightCursor=sort.RightCursor+1
    end
    sort.OutputIndex=sort.OutputIndex+1
    return
  end

  sort.Left=sort.Right
  sort.LeftCursor=nil
  if sort.Left>depth.RecordCount then
    depth.Records=sort.Output
    sort.Width=sort.Width*2
    if sort.Width>=depth.RecordCount then
      depth.Sort=nil
      State.Report.Cursor.SampleIndex=1
      State.Report.Cursor.Phase="check"
    else
      sort.Left=1
      sort.Output={}
    end
  end
end

local function depthPointFailure(State, Record, Status, Cause, Depth, Surface)
  local work=State.Depth
  local routeDistance=0
  if work.StartDistance then
    local fraction=Record.Along/work.ProfileLength
    routeDistance=work.StartDistance+fraction*(work.EndDistance-work.StartDistance)
  end
  local evidence={Position={x=Record.Position.x, z=Record.Position.z}, RouteDistance=routeDistance,
    Depth=Depth, SurfaceType=Surface, Source=Record.Native and "profile" or "direct", Cause=Cause}
  if Record.Native then
    evidence.ProfileY=Record.Position.y
  end
  return {Status=Status, Reason=Cause, Evidence=evidence}
end

local function checkDepthRecord(State)
  local depth,cursor=State.Depth,State.Report.Cursor
  local record=depth.Records[cursor.SampleIndex]
  local clear,status,cause,value,surface=VECTOR._CheckDepthPoint(record.Position, State.DepthOptions.MinDepth, record.Native)
  if State.Report.Status~="running" then
    return
  end
  if not clear then
    -- Finish all equal-distance observations before deciding. Unknown data outranks
    -- land, which outranks shallow water; never invent a depth for unknown/land.
    local rank=1
    if status=="unavailable" then
      rank=3
    elseif cause=="non_water" then
      rank=2
    end
    local selected=depth.GroupFailure
    if not selected or rank>selected.Rank
      or (rank==1 and selected.Rank==1 and value<selected.Evidence.Depth) then
      selected=depthPointFailure(State, record, status, cause, value, surface)
      selected.Rank=rank
      depth.GroupFailure=selected
    end
  end
  cursor.SampleIndex=cursor.SampleIndex+1
  local following=depth.Records[cursor.SampleIndex]
  if not following or following.Along~=record.Along then
    cursor.Phase="group"
  end
end

local function finishDepthGroup(State)
  local depth,cursor=State.Depth,State.Report.Cursor
  local failure=depth.GroupFailure
  if failure then
    finishValidation(State, failure.Status, failure.Reason, validationFailure(State, failure.Evidence))
  elseif cursor.SampleIndex<=depth.RecordCount then
    cursor.Phase="check"
  else
    cursor.Phase="next_profile"
  end
end

local function advanceDepthProfile(State)
  local depth,cursor=State.Depth,State.Report.Cursor
  depth.Records,depth.Sort,depth.GroupFailure=nil,nil,nil
  cursor.SampleIndex=nil
  if cursor.OffsetIndex<State.DepthOptions.OffsetCount then
    cursor.OffsetIndex=cursor.OffsetIndex+1
    cursor.Phase="profile_setup"
  else
    cursor.Phase="commit_section"
  end
end

local function commitDepthSection(State)
  local report,depth=State.Report,State.Depth
  local cursor=report.Cursor
  report.CheckedPrefixDistance=depth.EndDistance
  depth.Offset=nil
  cursor.OffsetIndex=nil
  if cursor.SectionIndex<depth.SectionCount then
    cursor.SectionIndex=cursor.SectionIndex+1
    cursor.Phase="section"
  else
    report.CompletedSegments=cursor.SegmentIndex
    if cursor.SegmentIndex==State.Geometry.SegmentCount then
      finishValidation(State, "clear")
    else
      State.Depth={}
      report.Cursor={Phase="segment", SegmentIndex=cursor.SegmentIndex+1}
    end
  end
end

local function checkIsolatedDepthPoint(State)
  local position=copyGeometryPosition(State.Geometry.Positions[1])
  position.y=0
  local clear,status,cause,depth,surface=VECTOR._CheckDepthPoint(position, State.DepthOptions.MinDepth, false)
  if State.Report.Status~="running" then
    return
  end
  if not clear then
    local failure=depthPointFailure(State, {Position=position, Native=false}, status, cause, depth, surface)
    finishValidation(State, status, cause, validationFailure(State, failure.Evidence))
  elseif State.Geometry.SegmentCount==0 then
    finishValidation(State, "clear")
  else
    State.Report.Cursor={Phase="segment", SegmentIndex=1}
  end
end

local function stepDepthValidation(State)
  local phase=State.Report.Cursor.Phase
  if phase=="point_setup" then
    if State.DepthOptions.CorridorWidth>0 then
      failDepthValidation(State, "corridor_direction_unavailable")
    else
      State.Report.Cursor.Phase="point"
    end
  elseif phase=="point" then
    checkIsolatedDepthPoint(State)
  elseif phase=="segment" then
    prepareDepthSegment(State)
  elseif phase=="section" then
    prepareDepthSection(State)
  elseif phase=="profile_setup" then
    prepareDepthProfile(State)
  elseif phase=="query" then
    queryDepthProfile(State)
  elseif phase=="collect" then
    collectDepthProfile(State)
  elseif phase=="generate" then
    generateDepthPoint(State)
  elseif phase=="sort" then
    sortDepthRecords(State)
  elseif phase=="check" then
    checkDepthRecord(State)
  elseif phase=="group" then
    finishDepthGroup(State)
  elseif phase=="next_profile" then
    advanceDepthProfile(State)
  elseif phase=="commit_section" then
    commitDepthSection(State)
  end
end

local function runValidationSlice(State, Budget, Timing)
  if type(os)=="table" and type(os.clock)=="function" then
    Timing.Read=os.clock
    updateValidationCPU(State, Timing)
  else
    validationCPUUnavailable(State, Timing)
  end
  while State.Report.Status=="running" and admitValidationWork(State, Budget) do
    if State.Report.EvaluatorKind=="depth" then
      stepDepthValidation(State)
    elseif State.Report.Cursor.Phase=="evaluate" then
      evaluateValidationConnection(State)
    else
      commitValidationConnection(State)
    end
    updateValidationCPU(State, Timing)
  end
end

--- Advance validation within independent slice and total limits.
-- Evaluating a whole original connection and committing its successful result are separate work units.
-- Depth jobs separately admit a profile query, one raw record copy, one generated point, one merge output,
-- one point predicate or a bounded phase/group/section advance. Sorting and tied groups resume across steps.
-- Direct samples include endpoints and at least a midpoint. All section offsets must pass before its prefix commits.
-- Missing/malformed profile or depth data ends unavailable; valid empty/single-point profiles use direct fallback.
-- Equal-distance groups select unavailable, then non-water, then the shallowest insufficient depth.
-- Point-only/all-duplicate geometry is checked once at width zero; positive width is corridor_direction_unavailable.
-- Exhausted slice budgets return running with LastSlice.YieldReason; total caps end limited. Zero is preserved.
-- A pending connection commit can advance with MaxEvaluatorCalls=0. Failure/cancellation never commits pending work.
-- CPU time uses os.clock only, excludes idle time and may overrun during an atomic callback. Requested CPU caps
-- without a usable clock end cpu_clock_unavailable before further work. A completing unit retains its result.
-- Missing/wrong current context cancels before work. Recheck the returned ContextId before publishing a result:
-- terminal jobs return their original report even after the owner's context changes, and never auto-resume anything.
-- Invalid arguments leave a running job unchanged. Reentrant stepping raises an error. Callback/native errors
-- end a still-running job as error, release work, then rethrow the original error; they are never terrain failures.
-- @param #PATHLINE.ValidationJob Job Running or terminal job handle.
-- @param #PATHLINE.ValidationBudget Budget (Optional) Copied per-step limits; may differ on the next step.
-- @param #string CurrentContextId (Optional) Original string/integer context. Required to match if configured at start; otherwise omit.
-- @return #PATHLINE.ValidationReport Independent bounded summary; terminal results are stable and cannot be restarted.
function PATHLINE.StepValidation(Job, Budget, CurrentContextId)
  local state=validationState(Job, "Job")
  assert(not state.Busy, "Job is already being stepped")
  local report=state.Report
  if report.Status~="running" then
    return copyValidationRecord(report)
  end
  Budget=validationLimits(Budget, false, report.EvaluatorKind)
  checkValidationContext(CurrentContextId)
  assert(report.ContextId~=nil or CurrentContextId==nil, "CurrentContextId requires a configured ContextId")

  report.LastSlice=newValidationCounters(report.EvaluatorKind)
  if report.ContextId~=CurrentContextId then
    finishValidation(state, "cancelled", "context_changed")
    return copyValidationRecord(report)
  end

  state.Busy=true
  local timing={BaseCPU=report.Counters.CPUSeconds or 0}
  -- Protect only the evaluation boundary so failures release work and still reach the caller.
  local ok,err=pcall(runValidationSlice, state, Budget, timing)
  local timed,timingError=pcall(updateValidationCPU, state, timing)
  state.Busy=false
  if not timed then
    validationCPUUnavailable(state, timing)
  end

  local slice=report.LastSlice
  local sliceCap,totalCap=Budget.MaxCPUSeconds,state.Limits.MaxCPUSeconds
  if slice.CPUSeconds~=nil and (sliceCap~=nil or totalCap~=nil) then
    local overrun=0
    if sliceCap~=nil then
      overrun=math.max(overrun, slice.CPUSeconds-sliceCap)
    end
    if totalCap~=nil and report.Counters.CPUSeconds~=nil then
      overrun=math.max(overrun, report.Counters.CPUSeconds-totalCap)
    end
    slice.CPUOverrunSeconds=overrun
  end
  if not ok or not timed then
    finishValidation(state, "error", "evaluation_error", validationFailure(state))
    if not ok then
      error(err, 0)
    end
    error(timingError, 0)
  end
  if report.Status=="running" and (sliceCap~=nil or totalCap~=nil) then
    if slice.CPUSeconds==nil then
      limitValidation(state, "cpu_clock_unavailable")
    elseif totalCap~=nil and report.Counters.CPUSeconds>=totalCap then
      limitValidation(state, "cpu_limit", totalCap)
    end
  end
  if report.Status~="running" then
    slice.YieldReason=nil
  end
  return copyValidationRecord(report)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new PATHLINE object. Points need to be added later.
-- @param #PATHLINE self
-- @param #string Name (Optional) Name of the path. Default "Unknown Path".
-- @return #PATHLINE self
function PATHLINE:New(Name)

  -- Inherit from BASE and start with an independent, empty point list.
  local self=BASE:Inherit(self, BASE:New()) --#PATHLINE
  
  self.points={}
  self.name=Name or "Unknown Path"

  self.lid=string.format("PATHLINE %s | ", self.name)

  return self
end

--- Create a new PATHLINE object from a given list of 2D points.
-- @param #PATHLINE self
-- @param #string Name Name of the pathline.
-- @param #table Vec2Array List of DCS#Vec2 points.
-- @return #PATHLINE self
function PATHLINE:NewFromVec2Array(Name, Vec2Array)

  local self=PATHLINE:New(Name)

  for i=1,#Vec2Array do
    self:AddPointFromVec2(Vec2Array[i])
  end

  return self
end

--- Create a new PATHLINE object from a given list of 3D points.
-- @param #PATHLINE self
-- @param #string Name Name of the pathline.
-- @param #table Vec3Array List of DCS#Vec3 points.
-- @return #PATHLINE self
function PATHLINE:NewFromVec3Array(Name, Vec3Array)

  local self=PATHLINE:New(Name)

  for i=1,#Vec3Array do
    self:AddPointFromVec3(Vec3Array[i])
  end

  return self
end


--- Replace the path with copied 2D points, removing its previous point and line drawings.
-- The replacement is built before the current route is changed. Invalid positions and terrain-query errors
-- propagate without replacing the old points or removing their drawings. Call drawing methods again as needed.
-- @param #PATHLINE self
-- @param #string Name Unused; this operation retains the current name and database registration.
-- @param #table Vec2Array List of DCS#Vec2 points.
-- @return #PATHLINE self
function PATHLINE:UpdateFromVec2Array(Name, Vec2Array)

  return self:_UpdatePoints(Vec2Array)
end

--- Replace the path with copied 3D points, removing its previous point and line drawings.
-- The replacement is built before the current route is changed. Invalid positions and terrain-query errors
-- propagate without replacing the old points or removing their drawings. Call drawing methods again as needed.
-- @param #PATHLINE self
-- @param #string Name Unused; this operation retains the current name and database registration.
-- @param #table Vec3Array List of DCS#Vec3 points.
-- @return #PATHLINE self
function PATHLINE:UpdateFromVec3Array(Name, Vec3Array)

  return self:_UpdatePoints(Vec3Array)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Find a pathline in the database.
-- @param #PATHLINE self
-- @param #string Name The name of the pathline.
-- @return #PATHLINE self
function PATHLINE:FindByName(Name)
  local pathline = _DATABASE:FindPathline(Name)
  return pathline
end



--- Add a point to the path from a given 2D position. The third dimension is determined from the land height.
-- The input is copied. Nil adds nothing; malformed components raise an error before terrain queries or mutation.
-- A Vec2 also requires a finite terrain height. Missing surface/depth metadata remains unavailable.
-- @param #PATHLINE self
-- @param DCS#Vec2 Vec2 The 2D vector (x,y) to add.
-- @return #PATHLINE self
function PATHLINE:AddPointFromVec2(Vec2)

  if Vec2~=nil then
  
    local point=self:_CreatePoint(Vec2)

    table.insert(self.points, point)
    
  end
  
  return self
end

--- Add a point to the path from a given 3D position.
-- The input is copied. Nil adds nothing; malformed components raise an error before terrain queries or mutation.
-- A Vec2 also requires a finite terrain height. Missing surface/depth metadata remains unavailable.
-- @param #PATHLINE self
-- @param DCS#Vec3 Vec3 The 3D vector (x,y,z) to add.
-- @return #PATHLINE self
function PATHLINE:AddPointFromVec3(Vec3)

  if Vec3~=nil then
  
    local point=self:_CreatePoint(Vec3)

    table.insert(self.points, point)
    
  end
  
  return self
end

--- Get name of pathline.
-- @param #PATHLINE self
-- @return #string Name of the pathline.
function PATHLINE:GetName()  
  return self.name
end

--- Get number of points.
-- @param #PATHLINE self
-- @return #number Number of points.
function PATHLINE:GetNumberOfPoints()
  local N=#self.points
  return N
end

--- Get independent copies of all path points, including positions and terrain metadata.
-- Editing returned tables does not modify the path or its drawing IDs.
-- @param #PATHLINE self
-- @return #list <#PATHLINE.Point> List of points.
function PATHLINE:GetPoints()  
  return UTILS.DeepCopy(self.points)
end

--- Get independent 3D position copies in path order.
-- @param #PATHLINE self
-- @return <DCS#Vec3> List of DCS#Vec3 points.
function PATHLINE:GetPoints3D()

  local vecs={}
  
  for _,_point in ipairs(self.points) do
    local point=_point --#PATHLINE.Point
    table.insert(vecs, UTILS.DeepCopy(point.vec3))
  end

  return vecs
end

--- Get independent 2D position copies in path order.
-- @param #PATHLINE self
-- @return <DCS#Vec2> List of DCS#Vec2 points.
function PATHLINE:GetPoints2D()

  local vecs={}
  
  for _,_point in ipairs(self.points) do
    local point=_point --#PATHLINE.Point
    table.insert(vecs, UTILS.DeepCopy(point.vec2))
  end

  return vecs
end

--- Get COORDINATES of pathline. Note that COORDINATE objects are created when calling this function. That does involve deep copy calls and can have an impact on performance if done too often.
-- @param #PATHLINE self
-- @return <Core.Point#COORDINATE> List of COORDINATES points.
function PATHLINE:GetCoordinates()

  local vecs={}
  
  for _,_point in ipairs(self.points) do
    local point=_point --#PATHLINE.Point
    local coord=COORDINATE:NewFromVec3(point.vec3)
    table.insert(vecs,coord)
  end

  return vecs
end

--- Get an independent copy of the n-th point of the pathline.
-- Invalid indices are logged and return nil.
-- @param #PATHLINE self
-- @param #number n (optional) The index of the point. Default is the first point.
-- @return #PATHLINE.Point Point.
function PATHLINE:GetPointFromIndex(n)

  local N=self:GetNumberOfPoints()
  
  if n==nil then
    n=1
  end

  local point=nil --#PATHLINE.Point
  
  if type(n)=="number" and n>=1 and n<=N and n==math.floor(n) then
    point=UTILS.DeepCopy(self.points[n])
  else
    self:E(self.lid..string.format("ERROR: No point in pathline for N=%s", tostring(n)))
  end

  return point
end

--- Get an independent copy of the 3D position of the n-th point.
-- @param #PATHLINE self
-- @param #number n The n-th point.
-- @return DCS#Vec3 Position in 3D.
function PATHLINE:GetPoint3DFromIndex(n)

  local point=self:GetPointFromIndex(n)
  
  if point then
    return point.vec3
  end
  
  return nil
end

--- Get an independent copy of the 2D position of the n-th point.
-- @param #PATHLINE self
-- @param #number n The n-th point.
-- @return DCS#Vec2 Position in 2D.
function PATHLINE:GetPoint2DFromIndex(n)

  local point=self:GetPointFromIndex(n)
  
  if point then
    return point.vec2
  end
  
  return nil
end

--- Calculate the length of the line.
-- @param #PATHLINE self
-- @param #boolean Project2D Calculate 2D distance between points.
-- @return #number Length in meters.
function PATHLINE:GetLength(Project2D)
  local l=0

  local np=#self.points

  for i=1,np-1 do
    local p1=self.points[i]   --#PATHLINE.Point
    local p2=self.points[i+1] --#PATHLINE.Point
    
    if Project2D then
      l=l+UTILS.VecDist2D(p1.vec2, p2.vec2)
    else
      l=l+UTILS.VecDist3D(p1.vec3, p2.vec3)
    end
    
  end
  
  return l
end

--- Inspect navigable water depth and the usable prefix between two positions.
-- Uses the same point-depth rule as ASTAR.Depth(), but returns a detailed report without creating a PATHLINE instance.
-- Actual endpoints are checked separately; a blocked start or unavailable endpoint ends the check before querying a profile.
-- Otherwise, profile points are ordered from the original start. The first insufficient
-- depth is interpolated from the previous valid distance; a non-water sample limits the prefix to that distance.
-- Samples at the same projected distance are evaluated together: unavailable data takes precedence, then non-water,
-- then the shallowest depth. Tied evidence is selected by cause, location and coordinates, not native profile order.
-- Profiles with fewer than two points also use direct samples at most 100 meters apart, limited to 1000 intervals.
-- A positive corridor width checks the center and both parallel edges, not the entire area between them or a turning arc.
-- ClearDistance is a terrain estimate under the linear-interpolation assumption, not a ship's braking distance.
-- Missing or malformed terrain values produce Status="unavailable" and ClearDistance=0. DCS API errors propagate normally.
-- @param DCS#Vec3 Start Original start position. Accepts a VECTOR directly; its altitude is ignored.
-- @param DCS#Vec3 Goal Original goal position. Accepts a VECTOR directly; its altitude is ignored.
-- @param #number MinDepth Optional positive finite minimum water depth in meters, inclusive; default 20.
-- @param #number CorridorWidth Optional non-negative finite total corridor width in meters; default 0.
-- @return #boolean True when all depth checks pass.
-- @return #string Rejection reason, or nil on success.
-- @return #PATHLINE.DepthReport Structured result, including the usable prefix measured from Start.
function PATHLINE.CheckDepth(Start, Goal, MinDepth, CorridorWidth)

  if MinDepth==nil then
    MinDepth=20
  end

  if CorridorWidth==nil then
    CorridorWidth=0
  end

  assert(MinDepth>0 and MinDepth<math.huge,"PATHLINE: minimum depth must be finite and positive")
  assert(CorridorWidth>=0 and CorridorWidth<math.huge,"PATHLINE: corridor width must be finite and non-negative")

  local a,b=Start,Goal
  local dx,dz=b.x-a.x,b.z-a.z
  local distance=math.sqrt(dx*dx+dz*dz)

  if not (distance<math.huge) then
    local reason="invalid_distance"
    return false,reason,PATHLINE._DepthReport(0,MinDepth,0,reason,"unavailable",reason)
  end

  -- An endpoint preflight has no corridor direction and needs no native profile.
  if distance==0 then
    local clear,status,cause,depth,surface=VECTOR._CheckDepthPoint(a,MinDepth,false)
    local reason
    if status=="unavailable" then
      reason=cause
    elseif not clear then
      reason="start_blocked"
    end
    local report=PATHLINE._DepthReport(0,MinDepth,0,reason,status,cause,
      {Point=a,Location="start"},depth,surface,0)

    return clear,reason,report
  end

  -- Query DCS in the same canonical direction as A*. Report distances in the caller's original direction.
  local reverse=a.x>b.x or (a.x==b.x and a.z>b.z)
  if reverse then
    a,b=b,a
    dx,dz=-dx,-dz
  end

  local nx,nz=-dz/distance,dx/distance
  local lines=CorridorWidth>0 and 3 or 1
  local earliest

  for i=1,lines do
    local offset=0
    if i==2 then
      offset=CorridorWidth/2
    elseif i==3 then
      offset=-CorridorWidth/2
    end
    local start={x=a.x+nx*offset,y=0,z=a.z+nz*offset}
    local goal={x=b.x+nx*offset,y=0,z=b.z+nz*offset}
    local reportOffset=offset
    if reverse then
      reportOffset=-offset
    end
    local clear,reason,report=PATHLINE._CheckDepthLine(start,goal,distance,MinDepth,reportOffset,reverse)

    if not clear then
      if report.Status=="unavailable" then
        return false,reason,report
      end

      -- A side profile may become unsafe before the center line does.
      if not earliest or report.ClearDistance<earliest.ClearDistance then
        earliest=report
      end
    end
  end

  if earliest then
    return false,earliest.Reason,earliest
  end

  return true,nil,{Status="clear",Distance=distance,ClearDistance=distance,RequiredDepth=MinDepth}
end


--- Find the minimum stored water depth at the pathline's support points.
-- Uses the direct terrain measurements stored when points were created; vec3.y may be a route altitude.
-- This does not inspect the terrain between support points or check a ship's corridor.
-- @param #PATHLINE self
-- @return #number Minimum depth in meters, or nil for an empty path or invalid depth data.
-- @return #PATHLINE.Point Independent copy of the first point with this depth, or nil.
-- @return #string "empty_path" or "invalid_depth" when no minimum can be determined, otherwise nil.
function PATHLINE:GetDepthMin()

  if #self.points==0 then
    return nil,nil,"empty_path"
  end

  local minimum=math.huge
  local minimumPoint=nil

  for _,point in ipairs(self.points) do
    local depth=point.depth

    -- Missing or non-finite terrain data must not appear to be deep water.
    if type(depth)~="number" or not (depth>=0 and depth<math.huge) then
      return nil,nil,"invalid_depth"
    end

    if depth<minimum then
      minimum=depth
      minimumPoint=point
    end
  end

  return minimum,UTILS.DeepCopy(minimumPoint)
end

--- Find the first estimated ground-contact position along the pathline.
-- Linearly interpolates the stored direct depths between support points. Contact includes depth equal to Draft;
-- unlike a navigation minimum, Draft describes the hull's actual depth below the water surface.
-- The returned VECTOR uses the interpolated sampled surface height, not the route altitude or seabed height.
-- This is a support-point estimate, not a corridor check or a prediction of the ship's turning arc.
-- @param #PATHLINE self
-- @param #number Draft Ship's draft in meters, nonnegative.
-- @return Core.Vector#VECTOR First contact position, or nil when no contact is found or data is unavailable.
-- @return #string "empty_path", "invalid_depth" or "invalid_surface_height" for unavailable data; nil otherwise.
function PATHLINE:FindGroundingPoint(Draft)

  assert(Draft>=0 and Draft<math.huge, "PATHLINE: draft must be finite and nonnegative")

  if #self.points==0 then
    return nil,"empty_path"
  end

  local previous=nil

  for _,point in ipairs(self.points) do
    local depth=point.depth

    if type(depth)~="number" or not (depth>=0 and depth<math.huge) then
      return nil,"invalid_depth"
    end

    if depth<=Draft then
      local height=point.landHeight
      if type(height)~="number" or not (math.abs(height)<math.huge) then
        return nil,"invalid_surface_height"
      end

      -- Already in contact at the first point: return the same type as an interpolated result.
      if not previous then
        return VECTOR:New(point.vec3.x, height, point.vec3.z)
      end

      local previousHeight=previous.landHeight
      if type(previousHeight)~="number" or not (math.abs(previousHeight)<math.huge) then
        return nil,"invalid_surface_height"
      end

      -- Previous depth is strictly greater than Draft, so this denominator is positive.
      local fraction=(previous.depth-Draft)/(previous.depth-depth)
      local x=previous.vec3.x+fraction*(point.vec3.x-previous.vec3.x)
      local z=previous.vec3.z+fraction*(point.vec3.z-previous.vec3.z)
      local y=previousHeight+fraction*(height-previousHeight)

      return VECTOR:New(x, y, z)
    end

    previous=point
  end

  return nil
end


--- Mark points on F10 map, replacing previous point labels.
-- Missing, malformed or non-finite terrain metadata is shown as "unavailable" without inventing a numeric value.
-- Line drawings remain independent.
-- @param #PATHLINE self
-- @param #boolean Switch If `true` or nil, set marks. If `false`, remove marks.
-- @return #PATHLINE self
function PATHLINE:MarkPoints(Switch)

  for i,point in ipairs(self.points) do
    local text
    if Switch~=false then
      local surfaceText="unavailable"
      local heightText="unavailable"
      local depthText="unavailable"
      local surface=point.surfaceType

      if isFiniteNumber(surface) and surface%1==0 and surface>=1 and surface<=5 then
        surfaceText=string.format("%d",surface)
      end
      if isFiniteNumber(point.landHeight) then
        heightText=string.format("%.1f m",point.landHeight)
      end
      if isFiniteNumber(point.depth) and point.depth>=0 then
        depthText=string.format("%.1f m",point.depth)
      end

      text=string.format("Pathline %s: Point #%d\nSurface Type=%s\nHeight=%s\nDepth=%s",
        self.name,i,surfaceText,heightText,depthText)
    end

    -- Retain ownership of the existing label until the replacement text is ready.
    if point.markerID then
      UTILS.RemoveMark(point.markerID)
      point.markerID=nil
    end
    if text then
      local markerID=UTILS.GetMarkID()
      trigger.action.markToAll(markerID,text,point.vec3,false)
      point.markerID=markerID
    end
  end

  return self
end

--- Draw line on F10 map, replacing this pathline's existing line segments.
-- Point markers are independent and are retained.
-- @param #PATHLINE self
-- @param #number Recipient (Optional) Coalition recipient of the line: -1=All (default).
-- @param #table Color (optional) Color as RGB table plus alpha value. Default {1, 0, 0, 1.0}.
-- @param #number LineType (optional) Line type: 1=Solid (default).
-- @return #PATHLINE self
function PATHLINE:DrawLine(Recipient, Color, LineType)
  
  -- Input
  Recipient= Recipient or -1
  Color= Color or {1,0,0, 1.0}
  LineType=LineType or 1
  local ReadOnly=false
  self:UnDrawLine()
  

  local np=#self.points

  for i=1,np-1 do
    local p1=self.points[i]   --#PATHLINE.Point
    local p2=self.points[i+1] --#PATHLINE.Point
    
    p1.lineID = UTILS.GetMarkID()
    
    trigger.action.lineToAll(Recipient, p1.lineID, p1.vec3, p2.vec3, Color, LineType, ReadOnly, "")
    
  end

  return self
end

--- Remove line on F10 map. Repeated calls without a new drawing have no effect.
-- Delayed removal captures the current IDs and cannot remove subsequently drawn segments.
-- @param #PATHLINE self
-- @param #number Delay Delay in seconds before line is removed.
-- @return #PATHLINE self
function PATHLINE:UnDrawLine(Delay)

  for _,_point in ipairs(self.points) do
    local p=_point   --#PATHLINE.Point
    if p.lineID then
      UTILS.RemoveMark(p.lineID, Delay)
      p.lineID=nil
    end    
  end

  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Project a terrain-profile point onto its requested segment for distance reporting.
-- Trust native DCS geometry: offset points are projected, and points beyond an endpoint are clamped to the segment.
-- Surface and depth queries still use the original returned point.
-- @param DCS#Vec3 Point Terrain-profile point.
-- @param DCS#Vec3 Start Canonical segment start.
-- @param #number UX Unit direction x component.
-- @param #number UZ Unit direction z component.
-- @param #number Distance Segment length in meters.
-- @return #number Clamped distance along the segment, or nil when coordinates or the projection are not finite.
function PATHLINE._GetDepthProfileDistance(Point, Start, UX, UZ, Distance)

  if type(Point)~="table" or type(Point.x)~="number" or not (math.abs(Point.x)<math.huge)
    or type(Point.z)~="number" or not (math.abs(Point.z)<math.huge) then
    return nil
  end

  local dx,dz=Point.x-Start.x,Point.z-Start.z
  local along=dx*UX+dz*UZ

  if not (math.abs(along)<math.huge) then
    return nil
  end

  return math.max(0,math.min(Distance,along))
end

--- Create the diagnostic result for a depth sample.
-- @param #number Distance Segment length in meters.
-- @param #number MinDepth Required water depth in meters.
-- @param #number Offset Profile offset relative to the original direction.
-- @param #string Reason Rejection reason, or nil when clear.
-- @param #string Status "clear", "blocked", or "unavailable".
-- @param #string Cause Underlying rejection cause, or nil when clear.
-- @param #table Sample Optional sample and its original-direction location.
-- @param #number Depth Optional effective sample depth.
-- @param #number Surface Optional sample surface type.
-- @param #number ClearDistance Usable prefix in meters.
-- @return #PATHLINE.DepthReport Diagnostic result.
function PATHLINE._DepthReport(Distance, MinDepth, Offset, Reason, Status, Cause, Sample, Depth, Surface, ClearDistance)

  local point=Sample and Sample.Point
  local reportPoint
  if point then
    reportPoint={x=point.x,z=point.z}
    if isFiniteNumber(point.y) then
      reportPoint.y=point.y
    end
  end
  if Status=="unavailable" then
    ClearDistance=0
  end

  return {
    Status=Status,
    Reason=Reason,
    Cause=Cause,
    Distance=Distance,
    ClearDistance=ClearDistance,
    RequiredDepth=MinDepth,
    ProfileOffset=Offset,
    Location=Sample and Sample.Location,
    Point=reportPoint,
    Depth=Depth,
    SurfaceType=Surface,
  }
end

-- Select the conservative sample at one projected distance. Resolve equivalent evidence without depending
-- on table.sort stability or the order of native profile points. Unknown sample heights are omitted in reports.
local function depthSamplePrecedes(First, Second)

  if First.Priority~=Second.Priority then
    return First.Priority<Second.Priority
  end
  if First.Priority==3 and First.Depth~=Second.Depth then
    return First.Depth<Second.Depth
  end
  if First.Cause~=Second.Cause then
    return (First.Cause or "")<(Second.Cause or "")
  end
  if First.Location~=Second.Location then
    return First.Location<Second.Location
  end
  if First.Point.x~=Second.Point.x then
    return First.Point.x<Second.Point.x
  end
  if First.Point.z~=Second.Point.z then
    return First.Point.z<Second.Point.z
  end

  local firstHeight,secondHeight=-math.huge,-math.huge
  if isFiniteNumber(First.Point.y) then
    firstHeight=First.Point.y
  end
  if isFiniteNumber(Second.Point.y) then
    secondHeight=Second.Point.y
  end
  return firstHeight<secondHeight
end

--- Check one canonical profile and measure its first obstruction from the original start.
-- Sorts support points and interpolates the minimum-depth threshold; coincident samples keep their shallower bound.
-- @param DCS#Vec3 Start Canonical start position.
-- @param DCS#Vec3 Goal Canonical goal position.
-- @param #number Distance Segment length in meters.
-- @param #number MinDepth Required water depth in meters.
-- @param #number Offset Profile offset relative to the original direction.
-- @param #boolean Reverse Whether the original input direction is reversed.
-- @return #boolean True when the profile is clear.
-- @return #string Rejection reason, or nil.
-- @return #PATHLINE.DepthReport Diagnostic result on rejection.
function PATHLINE._CheckDepthLine(Start, Goal, Distance, MinDepth, Offset, Reverse)

  local samples={}

  -- DCS profiles may omit their actual endpoints. Cache these direct checks for the ordered scan below.
  for i=1,2 do
    local point=i==1 and Start or Goal
    local location=i==1 and "start" or "goal"
    local clear,status,cause,depth,surface=VECTOR._CheckDepthPoint(point,MinDepth,false)
    local sample={
      Point=point,
      Along=i==1 and 0 or Distance,
      Location=location,
      Checked=true,
      Clear=clear,
      Status=status,
      Cause=cause,
      Depth=depth,
      Surface=surface,
    }

    if Reverse then
      sample.Along=Distance-sample.Along
      sample.Location=location=="start" and "goal" or "start"
    end

    local reason
    if status=="unavailable" then
      reason=cause
    elseif not clear then
      reason=sample.Location.."_blocked"
    end
    sample.Reason=reason
    samples[#samples+1]=sample

    -- No prefix can be established when the starting position is blocked or an endpoint query has no valid data.
    if not clear and (status=="unavailable" or sample.Along==0) then
      return false,reason,PATHLINE._DepthReport(Distance,MinDepth,Offset,reason,status,cause,sample,depth,surface,0)
    end
  end

  local profile=PATHLINE._QueryDepthProfile(Start,Goal)
  if type(profile)~="table" then
    local reason="profile_unavailable"
    return false,reason,PATHLINE._DepthReport(Distance,MinDepth,Offset,reason,"unavailable",reason)
  end

  local ux,uz=(Goal.x-Start.x)/Distance,(Goal.z-Start.z)/Distance
  local intervals=#profile<2 and math.max(2,math.ceil(Distance/100)) or 0

  if intervals>1000 then
    local reason="profile_fallback_limit"
    return false,reason,PATHLINE._DepthReport(Distance,MinDepth,Offset,reason,"unavailable",reason)
  end

  -- Short native profiles receive direct samples, including a midpoint even on very short connections.
  for i=1,#profile+math.max(0,intervals-1) do
    local useProfile=i<=#profile
    local point=profile[i]
    local location=useProfile and "profile" or "profile_fallback"

    if not useProfile then
      local fraction=(i-#profile)/intervals
      point={x=Start.x+(Goal.x-Start.x)*fraction,z=Start.z+(Goal.z-Start.z)*fraction}
    end

    local along=PATHLINE._GetDepthProfileDistance(point,Start,ux,uz,Distance)
    if not along then
      local reason="invalid_profile_position"
      return false,reason,PATHLINE._DepthReport(Distance,MinDepth,Offset,reason,"unavailable",reason)
    end

    if Reverse then
      along=Distance-along
    end
    samples[#samples+1]={Point=point,Along=along,Location=location,UseProfile=useProfile}
  end

  table.sort(samples,function(a,b)
    return a.Along<b.Along
  end)

  local previous
  local index=1
  while index<=#samples do
    local along=samples[index].Along
    local limiting

    -- Finish the entire distance group before advancing the interpolation baseline. A deeper sample
    -- at the same position cannot extend the usable prefix or hide blocked/unavailable evidence.
    repeat
      local sample=samples[index]
      if not sample.Checked then
        sample.Clear,sample.Status,sample.Cause,sample.Depth,sample.Surface=
          VECTOR._CheckDepthPoint(sample.Point,MinDepth,sample.UseProfile)
      end

      sample.Priority=3
      if sample.Status=="unavailable" then
        sample.Priority=1
      elseif sample.Cause=="non_water" then
        sample.Priority=2
      end
      if not limiting or depthSamplePrecedes(sample,limiting) then
        limiting=sample
      end
      index=index+1
    until index>#samples or samples[index].Along~=along

    if not limiting.Clear then
      local reason=limiting.Reason
      if limiting.Status=="unavailable" then
        reason=limiting.Cause
      elseif not reason then
        reason=limiting.Location.."_blocked"
      end
      local clearDistance=0
      if previous then
        clearDistance=previous.Along
      end

      -- Non-water has no proven coastline transition; numeric depths permit threshold interpolation.
      local depth=limiting.Depth
      if previous and depth and depth<MinDepth then
        local fraction=(previous.Depth-MinDepth)/(previous.Depth-depth)
        clearDistance=previous.Along+(along-previous.Along)*fraction
      end

      return false,reason,PATHLINE._DepthReport(Distance,MinDepth,Offset,reason,
        limiting.Status,limiting.Cause,limiting,depth,limiting.Surface,clearDistance)
    end

    previous=limiting
  end

  return true
end

--- Build replacement points before releasing any geometry or drawings owned by this pathline.
-- Terrain errors propagate normally; construction does not mutate the current route.
-- @param #PATHLINE self
-- @param #table Positions Dense list of Vec2 or Vec3 positions.
-- @return #PATHLINE self.
function PATHLINE:_UpdatePoints(Positions)

  assert(type(Positions)=="table","PATHLINE: positions must be a list")
  local points={}
  for i=1,#Positions do
    if Positions[i]~=nil then
      points[#points+1]=self:_CreatePoint(Positions[i])
    end
  end

  self:UnDrawLine()
  self:MarkPoints(false)
  self.points=points
  return self
end

--- Create a point with copied position and sampled terrain metadata.
-- Reject malformed input before querying terrain. Vec2 altitude must also be finite; surface/depth data
-- remains unmodified so its unavailability can be reported by depth helpers and point labels.
-- @param #PATHLINE self
-- @param DCS#Vec3 Vec Position vector. Can also be a DCS#Vec2 in which case the altitude at landheight is taken.
-- @return #PATHLINE.Point
function PATHLINE:_CreatePoint(Vec)

  assert(type(Vec)=="table","PATHLINE: position must be a Vec2 or Vec3 table")
  assert(isFiniteNumber(Vec.x) and isFiniteNumber(Vec.y),"PATHLINE: x and y must be finite numbers")
  assert(Vec.z==nil or isFiniteNumber(Vec.z),"PATHLINE: z must be a finite number when supplied")

  local point={} --#PATHLINE.Point

  if Vec.z~=nil then
    -- Given vec is 3D
    point.vec3=UTILS.DeepCopy(Vec)
    point.vec2={x=Vec.x, y=Vec.z}
  else
    -- Given vec is 2D  
    local height=land.getHeight(Vec)
    assert(isFiniteNumber(height),"PATHLINE: Vec2 terrain height must be finite")
    point.vec2=UTILS.DeepCopy(Vec)
    point.vec3={x=Vec.x,y=height,z=Vec.y}
  end

  -- Get surface type.
  point.surfaceType=land.getSurfaceType(point.vec2)
  
  -- Get land height and depth.
  point.landHeight, point.depth=land.getSurfaceHeightWithSeabed(point.vec2)
  
  point.markerID=nil

  return point
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
