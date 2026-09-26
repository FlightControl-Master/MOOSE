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
-- @field #number surfaceType Surface type.
-- @field #number landHeight Land height in meters.
-- @field #number depth Water depth in meters.
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
-- @field DCS#Vec3 Point First rejected sample on the limiting profile, when known. This is not the interpolated threshold position.
-- @field #number Depth Water depth at Point, when known; the shallower of direct and profile depth.
-- @field #number SurfaceType DCS surface type at Point, when known.
-- @field #number ProfileOffset Signed distance from the route center line, in meters; positive is right of travel in DCS x/z coordinates.
-- @field #string Location "start", "goal", "profile", or "profile_fallback" relative to the original input direction.


--- PATHLINE class version.
-- @field #string version
PATHLINE.version="0.2.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

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


--- Update PATHLINE object from a given list of 2D points.
-- @param #PATHLINE self
-- @param #string Name Name of the pathline.
-- @param #table Vec2Array List of DCS#Vec2 points.
-- @return #PATHLINE self
function PATHLINE:UpdateFromVec2Array(Name, Vec2Array)

  -- Clear points
  self.points={}

  for i=1,#Vec2Array do
    self:AddPointFromVec2(Vec2Array[i])
  end

  return self
end

--- Update PATHLINE object from a given list of 3D points.
-- @param #PATHLINE self
-- @param #string Name Name of the pathline.
-- @param #table Vec3Array List of DCS#Vec3 points.
-- @return #PATHLINE self
function PATHLINE:UpdateFromVec3Array(Name, Vec3Array)

  -- Clear points
  self.points={}

  for i=1,#Vec3Array do
    self:AddPointFromVec3(Vec3Array[i])
  end

  return self
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
-- @param #PATHLINE self
-- @param DCS#Vec2 Vec2 The 2D vector (x,y) to add.
-- @return #PATHLINE self
function PATHLINE:AddPointFromVec2(Vec2)

  if Vec2 then
  
    local point=self:_CreatePoint(Vec2)

    table.insert(self.points, point)
    
  end
  
  return self
end

--- Add a point to the path from a given 3D position.
-- @param #PATHLINE self
-- @param DCS#Vec3 Vec3 The 3D vector (x,y,z) to add.
-- @return #PATHLINE self
function PATHLINE:AddPointFromVec3(Vec3)

  if Vec3 then
  
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
  
  if n==nil then n=1 end

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
-- Actual endpoints are checked separately, and profile points are ordered from the original start. The first insufficient
-- depth is interpolated from the previous valid sample; a non-water sample limits the prefix to the previous valid point.
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
    local reason=not clear and (status=="unavailable" and cause or "start_blocked") or nil
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
    local offset=i==2 and CorridorWidth/2 or (i==3 and -CorridorWidth/2 or 0)
    local start={x=a.x+nx*offset,y=0,z=a.z+nz*offset}
    local goal={x=b.x+nx*offset,y=0,z=b.z+nz*offset}
    local clear,reason,report=PATHLINE._CheckDepthLine(start,goal,distance,MinDepth,reverse and -offset or offset,reverse)

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


--- Mark points on F10 map.
-- @param #PATHLINE self
-- @param #boolean Switch If `true` or nil, set marks. If `false`, remove marks.
-- @return #PATHLINE self
function PATHLINE:MarkPoints(Switch)
  for i,_point in ipairs(self.points) do
    local point=_point --#PATHLINE.Point
    if Switch==false then
      
      if point.markerID then
        UTILS.RemoveMark(point.markerID)
        point.markerID=nil
      end
      
    else
    
      if point.markerID then
        UTILS.RemoveMark(point.markerID)
        point.markerID=nil
      end
    
      point.markerID=UTILS.GetMarkID()
      
      local text=string.format("Pathline %s: Point #%d\nSurface Type=%d\nHeight=%.1f m\nDepth=%.1f m", self.name, i, point.surfaceType, point.landHeight, point.depth)
      
      trigger.action.markToAll(point.markerID, text, point.vec3, false)
    
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

  return {
    Status=Status,Reason=Reason,Cause=Cause,Distance=Distance,ClearDistance=Status=="unavailable" and 0 or ClearDistance,
    RequiredDepth=MinDepth,ProfileOffset=Offset,Location=Sample and Sample.Location,
    Point=point and {x=point.x,y=point.y,z=point.z},Depth=Depth,SurfaceType=Surface,
  }
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
    local sample={Point=point,Along=i==1 and 0 or Distance,Location=location,
      Checked=true,Clear=clear,Status=status,Cause=cause,Depth=depth,Surface=surface}

    if Reverse then
      sample.Along=Distance-sample.Along
      sample.Location=location=="start" and "goal" or "start"
    end

    local reason=status=="unavailable" and cause or sample.Location.."_blocked"
    sample.Reason=reason
    samples[#samples+1]=sample

    -- No prefix can be established when the starting position is blocked or an endpoint query has no valid data.
    if not clear and (status=="unavailable" or sample.Along==0) then
      return false,reason,PATHLINE._DepthReport(Distance,MinDepth,Offset,reason,status,cause,sample,depth,surface,0)
    end
  end

  local profile=land.profile(Start,Goal)
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

    samples[#samples+1]={Point=point,Along=Reverse and Distance-along or along,Location=location,UseProfile=useProfile}
  end

  table.sort(samples,function(a,b) return a.Along<b.Along end)
  local previous

  for _,sample in ipairs(samples) do
    local clear,status,cause,depth,surface=sample.Clear,sample.Status,sample.Cause,sample.Depth,sample.Surface
    if not sample.Checked then
      clear,status,cause,depth,surface=VECTOR._CheckDepthPoint(sample.Point,MinDepth,sample.UseProfile)
    end

    if not clear then
      local reason=status=="unavailable" and cause or sample.Reason or sample.Location.."_blocked"
      local clearDistance=previous and previous.Along or 0

      -- Numeric depth samples allow linear interpolation. A non-water sample has no proven coastline
      -- transition, so the usable prefix ends at the previous valid sample instead.
      if previous and depth and depth<MinDepth and previous.Depth and previous.Depth>=MinDepth then
        local fraction=(previous.Depth-MinDepth)/(previous.Depth-depth)
        clearDistance=previous.Along+(sample.Along-previous.Along)*fraction
      end

      return false,reason,PATHLINE._DepthReport(Distance,MinDepth,Offset,reason,status,cause,sample,depth,surface,clearDistance)
    end

    -- Keep the shallower value when a native endpoint duplicates the direct endpoint check.
    -- Equal-position sorting must never change the interpolated usable prefix.
    sample.Depth=depth
    if previous and sample.Along==previous.Along then
      previous.Depth=math.min(previous.Depth,depth)
    else
      previous=sample
    end
  end

  return true
end

--- Create a point with copied position and sampled terrain metadata.
-- @param #PATHLINE self
-- @param DCS#Vec3 Vec Position vector. Can also be a DCS#Vec2 in which case the altitude at landheight is taken.
-- @return #PATHLINE.Point
function PATHLINE:_CreatePoint(Vec)

  local point={} --#PATHLINE.Point

  if Vec.z then
    -- Given vec is 3D
    point.vec3=UTILS.DeepCopy(Vec)
    point.vec2={x=Vec.x, y=Vec.z}
  else
    -- Given vec is 2D  
    point.vec2=UTILS.DeepCopy(Vec)
    point.vec3={x=Vec.x, y=land.getHeight(Vec), z=Vec.y}
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
