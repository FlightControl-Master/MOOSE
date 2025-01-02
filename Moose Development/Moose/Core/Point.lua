--- **Core** - Defines an extensive API to manage 3D points in the DCS World 3D simulation space.
--
-- ## Features:
--
--   * Provides a COORDINATE class, which allows to manage points in 3D space and perform various operations on it.
--   * Provides a POINT\_VEC2 class, which is derived from COORDINATE, and allows to manage points in 3D space, but from a Lat/Lon and Altitude perspective.
--   * Provides a POINT\_VEC3 class, which is derived from COORDINATE, and allows to manage points in 3D space, but from a X, Z and Y vector perspective.
--
-- ===
--
-- ### Authors:
--
--   * FlightControl (Design & Programming)
--
-- ### Contributions:
-- 
--   * funkyfranky
--   * Applevangelist
--   
-- ===
--
-- @module Core.Point
-- @image Core_Coordinate.JPG


do -- COORDINATE
  
  ---
  -- @type COORDINATE
  -- @field #string ClassName Name of the class
  -- @field #number x Component of the 3D vector.
  -- @field #number y Component of the 3D vector.
  -- @field #number z Component of the 3D vector.
  -- @field #number Heading Heading in degrees. Needs to be set first.
  -- @field #number Velocity Velocity in meters per second. Needs to be set first.
  -- @extends Core.Base#BASE


  --- Defines a 3D point in the simulator and with its methods, you can use or manipulate the point in 3D space.
  --
  -- # 1) Create a COORDINATE object.
  --
  -- A new COORDINATE object can be created with 3 various methods:
  --
  --  * @{#COORDINATE.New}(): from a 3D point.
  --  * @{#COORDINATE.NewFromVec2}(): from a @{DCS#Vec2} and possible altitude.
  --  * @{#COORDINATE.NewFromVec3}(): from a @{DCS#Vec3}.
  --
  --
  -- # 2) Smoke, flare, explode, illuminate at the coordinate.
  --
  -- At the point a smoke, flare, explosion and illumination bomb can be triggered. Use the following methods:
  --
  -- ## 2.1) Smoke
  --
  --   * @{#COORDINATE.Smoke}(): To smoke the point in a certain color.
  --   * @{#COORDINATE.SmokeBlue}(): To smoke the point in blue.
  --   * @{#COORDINATE.SmokeRed}(): To smoke the point in red.
  --   * @{#COORDINATE.SmokeOrange}(): To smoke the point in orange.
  --   * @{#COORDINATE.SmokeWhite}(): To smoke the point in white.
  --   * @{#COORDINATE.SmokeGreen}(): To smoke the point in green.
  --
  -- ## 2.2) Flare
  --
  --   * @{#COORDINATE.Flare}(): To flare the point in a certain color.
  --   * @{#COORDINATE.FlareRed}(): To flare the point in red.
  --   * @{#COORDINATE.FlareYellow}(): To flare the point in yellow.
  --   * @{#COORDINATE.FlareWhite}(): To flare the point in white.
  --   * @{#COORDINATE.FlareGreen}(): To flare the point in green.
  --
  -- ## 2.3) Explode
  --
  --   * @{#COORDINATE.Explosion}(): To explode the point with a certain intensity.
  --
  -- ## 2.4) Illuminate
  --
  --   * @{#COORDINATE.IlluminationBomb}(): To illuminate the point.
  --
  --
  -- # 3) Create markings on the map.
  --
  -- Place markers (text boxes with clarifications for briefings, target locations or any other reference point)
  -- on the map for all players, coalitions or specific groups:
  --
  --   * @{#COORDINATE.MarkToAll}(): Place a mark to all players.
  --   * @{#COORDINATE.MarkToCoalition}(): Place a mark to a coalition.
  --   * @{#COORDINATE.MarkToCoalitionRed}(): Place a mark to the red coalition.
  --   * @{#COORDINATE.MarkToCoalitionBlue}(): Place a mark to the blue coalition.
  --   * @{#COORDINATE.MarkToGroup}(): Place a mark to a group (needs to have a client in it or a CA group (CA group is bugged)).
  --   * @{#COORDINATE.RemoveMark}(): Removes a mark from the map.
  --
  -- # 4) Coordinate calculation methods.
  --
  -- Various calculation methods exist to use or manipulate 3D space. Find below a short description of each method:
  --
  -- ## 4.1) Get the distance between 2 points.
  --
  --   * @{#COORDINATE.Get3DDistance}(): Obtain the distance from the current 3D point to the provided 3D point in 3D space.
  --   * @{#COORDINATE.Get2DDistance}(): Obtain the distance from the current 3D point to the provided 3D point in 2D space.
  --
  -- ## 4.2) Get the angle.
  --
  --   * @{#COORDINATE.GetAngleDegrees}(): Obtain the angle in degrees from the current 3D point with the provided 3D direction vector.
  --   * @{#COORDINATE.GetAngleRadians}(): Obtain the angle in radians from the current 3D point with the provided 3D direction vector.
  --   * @{#COORDINATE.GetDirectionVec3}(): Obtain the 3D direction vector from the current 3D point to the provided 3D point.
  --
  -- ## 4.3) Coordinate translation.
  --
  --   * @{#COORDINATE.Translate}(): Translate the current 3D point towards an other 3D point using the given Distance and Angle.
  --
  -- ## 4.4) Get the North correction of the current location.
  --
  --   * @{#COORDINATE.GetNorthCorrectionRadians}(): Obtains the north correction at the current 3D point.
  --
  -- ## 4.5) Point Randomization
  --
  -- Various methods exist to calculate random locations around a given 3D point.
  --
  --   * @{#COORDINATE.GetRandomVec2InRadius}(): Provides a random 2D vector around the current 3D point, in the given inner to outer band.
  --   * @{#COORDINATE.GetRandomVec3InRadius}(): Provides a random 3D vector around the current 3D point, in the given inner to outer band.
  --
  -- ## 4.6) LOS between coordinates.
  --
  -- Calculate if the coordinate has Line of Sight (LOS) with the other given coordinate.
  -- Mountains, trees and other objects can be positioned between the two 3D points, preventing visibilty in a straight continuous line.
  -- The method @{#COORDINATE.IsLOS}() returns if the two coordinates have LOS.
  --
  -- ## 4.7) Check the coordinate position.
  --
  -- Various methods are available that allow to check if a coordinate is:
  --
  --   * @{#COORDINATE.IsInRadius}(): in a give radius.
  --   * @{#COORDINATE.IsInSphere}(): is in a given sphere.
  --   * @{#COORDINATE.IsAtCoordinate2D}(): is in a given coordinate within a specific precision.
  --
  --
  --
  -- # 5) Measure the simulation environment at the coordinate.
  --
  -- ## 5.1) Weather specific.
  --
  -- Within the DCS simulator, a coordinate has specific environmental properties, like wind, temperature, humidity etc.
  --
  --   * @{#COORDINATE.GetWind}(): Retrieve the wind at the specific coordinate within the DCS simulator.
  --   * @{#COORDINATE.GetTemperature}(): Retrieve the temperature at the specific height within the DCS simulator.
  --   * @{#COORDINATE.GetPressure}(): Retrieve the pressure at the specific height within the DCS simulator.
  --
  -- ## 5.2) Surface specific.
  --
  -- Within the DCS simulator, the surface can have various objects placed at the coordinate, and the surface height will vary.
  --
  --   * @{#COORDINATE.GetLandHeight}(): Retrieve the height of the surface (on the ground) within the DCS simulator.
  --   * @{#COORDINATE.GetSurfaceType}(): Retrieve the surface type (on the ground) within the DCS simulator.
  --
  -- # 6) Create waypoints for routes.
  --
  -- A COORDINATE can prepare waypoints for Ground and Air groups to be embedded into a Route.
  --
  --   * @{#COORDINATE.WaypointAir}(): Build an air route point.
  --   * @{#COORDINATE.WaypointGround}(): Build a ground route point.
  --   * @{#COORDINATE.WaypointNaval}(): Build a naval route point.
  --
  -- Route points can be used in the Route methods of the @{Wrapper.Group#GROUP} class.
  --
  -- ## 7) Manage the roads.
  --
  -- Important for ground vehicle transportation and movement, the method @{#COORDINATE.GetClosestPointToRoad}() will calculate
  -- the closest point on the nearest road.
  --
  -- In order to use the most optimal road system to transport vehicles, the method @{#COORDINATE.GetPathOnRoad}() will calculate
  -- the most optimal path following the road between two coordinates.
  --
  -- ## 8) Metric or imperial system
  --
  --   * @{#COORDINATE.IsMetric}(): Returns if the 3D point is Metric or Nautical Miles.
  --   * @{#COORDINATE.SetMetric}(): Sets the 3D point to Metric or Nautical Miles.
  --
  --
  -- ## 9) Coordinate text generation
  --
  --   * @{#COORDINATE.ToStringBR}(): Generates a Bearing & Range text in the format of DDD for DI where DDD is degrees and DI is distance.
  --   * @{#COORDINATE.ToStringBRA}(): Generates a Bearing, Range & Altitude text.
  --   * @{#COORDINATE.ToStringBRAANATO}(): Generates a Generates a Bearing, Range, Aspect & Altitude text in NATOPS.
  --   * @{#COORDINATE.ToStringLL}(): Generates a Latitude & Longitude text.
  --   * @{#COORDINATE.ToStringLLDMS}(): Generates a Lat, Lon, Degree, Minute, Second text.
  --   * @{#COORDINATE.ToStringLLDDM}(): Generates a Lat, Lon, Degree, decimal Minute text.
  --   * @{#COORDINATE.ToStringMGRS}(): Generates a MGRS grid coordinate text.
  --
  -- ## 10) Drawings on F10 map
  --
  --   * @{#COORDINATE.CircleToAll}(): Draw a circle on the F10 map.
  --   * @{#COORDINATE.LineToAll}(): Draw a line on the F10 map.
  --   * @{#COORDINATE.RectToAll}(): Draw a rectangle on the F10 map.
  --   * @{#COORDINATE.QuadToAll}(): Draw a shape with four points on the F10 map.
  --   * @{#COORDINATE.TextToAll}(): Write some text on the F10 map.
  --   * @{#COORDINATE.ArrowToAll}(): Draw an arrow on the F10 map.
  --
  -- @field #COORDINATE
  COORDINATE = {
    ClassName = "COORDINATE",
  }

  --- Waypoint altitude types.
  -- @type COORDINATE.WaypointAltType
  -- @field #string BARO Barometric altitude.
  -- @field #string RADIO Radio altitude.
  COORDINATE.WaypointAltType = {
    BARO = "BARO",
    RADIO = "RADIO",
  }

  --- Waypoint actions.
  -- @type COORDINATE.WaypointAction
  -- @field #string TurningPoint Turning point.
  -- @field #string FlyoverPoint Fly over point.
  -- @field #string FromParkingArea From parking area.
  -- @field #string FromParkingAreaHot From parking area hot.
  -- @field #string FromGroundAreaHot From ground area hot.
  -- @field #string FromGroundArea From ground area.
  -- @field #string FromRunway From runway.
  -- @field #string Landing Landing.
  -- @field #string LandingReFuAr Landing and refuel and rearm.
  COORDINATE.WaypointAction = {
    TurningPoint       = "Turning Point",
    FlyoverPoint       = "Fly Over Point",
    FromParkingArea    = "From Parking Area",
    FromParkingAreaHot = "From Parking Area Hot",
    FromGroundAreaHot  = "From Ground Area Hot",
    FromGroundArea     = "From Ground Area",
    FromRunway         = "From Runway",
    Landing            = "Landing",
    LandingReFuAr      = "LandingReFuAr",
  }

  --- Waypoint types.
  -- @type COORDINATE.WaypointType
  -- @field #string TakeOffParking Take of parking.
  -- @field #string TakeOffParkingHot Take of parking hot.
  -- @field #string TakeOff Take off parking hot.
  -- @field #string TakeOffGroundHot Take of from ground hot.
  -- @field #string TurningPoint Turning point.
  -- @field #string Land Landing point.
  -- @field #string LandingReFuAr Landing and refuel and rearm.
  COORDINATE.WaypointType = {
    TakeOffParking    = "TakeOffParking",
    TakeOffParkingHot = "TakeOffParkingHot",
    TakeOff           = "TakeOffParkingHot",
    TakeOffGroundHot  = "TakeOffGroundHot",
    TakeOffGround     = "TakeOffGround",
    TurningPoint      = "Turning Point",
    Land              = "Land",
    LandingReFuAr     = "LandingReFuAr",    
  }


  --- COORDINATE constructor.
  -- @param #COORDINATE self
  -- @param DCS#Distance x The x coordinate of the Vec3 point, pointing to the North.
  -- @param DCS#Distance y The y coordinate of the Vec3 point, pointing to up.
  -- @param DCS#Distance z The z coordinate of the Vec3 point, pointing to the right.
  -- @return #COORDINATE self
  function COORDINATE:New( x, y, z )

    local self=BASE:Inherit(self, BASE:New()) -- #COORDINATE
    
    self.x = x
    self.y = y
    self.z = z

    return self
  end

  --- COORDINATE constructor.
  -- @param #COORDINATE self
  -- @param #COORDINATE Coordinate.
  -- @return #COORDINATE self
  function COORDINATE:NewFromCoordinate( Coordinate )

    local self = BASE:Inherit( self, BASE:New() ) -- #COORDINATE
    self.x = Coordinate.x
    self.y = Coordinate.y
    self.z = Coordinate.z

    return self
  end

  --- Create a new COORDINATE object from  Vec2 coordinates.
  -- @param #COORDINATE self
  -- @param DCS#Vec2 Vec2 The Vec2 point.
  -- @param DCS#Distance LandHeightAdd (Optional) The default height if required to be evaluated will be the land height of the x, y coordinate. You can specify an extra height to be added to the land height.
  -- @return #COORDINATE self
  function COORDINATE:NewFromVec2( Vec2, LandHeightAdd )

    local LandHeight = land.getHeight( Vec2 )

    LandHeightAdd = LandHeightAdd or 0
    LandHeight = LandHeight + LandHeightAdd

    local self = self:New( Vec2.x, LandHeight, Vec2.y ) -- #COORDINATE

    return self

  end

  --- Create a new COORDINATE object from  Vec3 coordinates.
  -- @param #COORDINATE self
  -- @param DCS#Vec3 Vec3 The Vec3 point.
  -- @return #COORDINATE self
  function COORDINATE:NewFromVec3( Vec3 )

    local self = self:New( Vec3.x, Vec3.y, Vec3.z ) -- #COORDINATE

    self:F2( self )

    return self
  end
  
  --- Create a new COORDINATE object from a waypoint. This uses the components
  -- 
  --  * `waypoint.x`
  --  * `waypoint.alt`
  --  * `waypoint.y`
  --  
  -- @param #COORDINATE self
  -- @param DCS#Waypoint Waypoint The waypoint.
  -- @return #COORDINATE self
  function COORDINATE:NewFromWaypoint(Waypoint)

    local self=self:New(Waypoint.x, Waypoint.alt, Waypoint.y) -- #COORDINATE
    
    return self
  end  

  --- Return the coordinates itself. Sounds stupid but can be useful for compatibility.
  -- @param #COORDINATE self
  -- @return #COORDINATE self
  function COORDINATE:GetCoordinate()
    return self
  end

  --- Return the coordinates of the COORDINATE in Vec3 format.
  -- @param #COORDINATE self
  -- @return DCS#Vec3 The Vec3 format coordinate.
  function COORDINATE:GetVec3()
    return { x = self.x, y = self.y, z = self.z }
  end


  --- Return the coordinates of the COORDINATE in Vec2 format.
  -- @param #COORDINATE self
  -- @return DCS#Vec2 The Vec2 format coordinate.
  function COORDINATE:GetVec2()
    return { x = self.x, y = self.z }
  end

  --- Update x,y,z coordinates from a given 3D vector.
  -- @param #COORDINATE self
  -- @param DCS#Vec3 Vec3 The 3D vector with x,y,z components.
  -- @return #COORDINATE The modified COORDINATE itself.
  function COORDINATE:UpdateFromVec3(Vec3)

    self.x=Vec3.x
    self.y=Vec3.y
    self.z=Vec3.z

    return self
  end

  --- Update x,y,z coordinates from another given COORDINATE.
  -- @param #COORDINATE self
  -- @param #COORDINATE Coordinate The coordinate with the new x,y,z positions.
  -- @return #COORDINATE The modified COORDINATE itself.
  function COORDINATE:UpdateFromCoordinate(Coordinate)

    self.x=Coordinate.x
    self.y=Coordinate.y
    self.z=Coordinate.z

    return self
  end

  --- Update x and z coordinates from a given 2D vector.
  -- @param #COORDINATE self
  -- @param DCS#Vec2 Vec2 The 2D vector with x,y components. x is overwriting COORDINATE.x while y is overwriting COORDINATE.z.
  -- @return #COORDINATE The modified COORDINATE itself.
  function COORDINATE:UpdateFromVec2(Vec2)

    self.x=Vec2.x
    self.z=Vec2.y

    return self
  end

  --- Returns the magnetic declination at the given coordinate.
  -- NOTE that this needs `require` to be available so you need to desanitize the `MissionScripting.lua` file in your DCS/Scrips folder.
  -- If `require` is not available, a constant value for the whole map.
  -- @param #COORDINATE self
  -- @param #number Month (Optional) The month at which the declination is calculated. Default is the mission month.
  -- @param #number Year (Optional) The year at which the declination is calculated. Default is the mission year.
  -- @return #number Magnetic declination in degrees.
  function COORDINATE:GetMagneticDeclination(Month, Year)
  
    local decl=UTILS.GetMagneticDeclination()
    
    if require then
      
      local magvar = require('magvar')
      
      if magvar then
      
        local date, year, month, day=UTILS.GetDCSMissionDate()
        
        magvar.init(Month or month, Year or year)
      
        local lat, lon=self:GetLLDDM()
        
        decl=magvar.get_mag_decl(lat, lon)
        
        if decl then
          decl=math.deg(decl)
        end
        
      end
    else
      self:T("The require package is not available. Using constant value for magnetic declination")    
    end
  
    return decl
  end

  --- Returns the coordinate from the latitude and longitude given in decimal degrees.
  -- @param #COORDINATE self
  -- @param #number latitude Latitude in decimal degrees.
  -- @param #number longitude Longitude in decimal degrees.
  -- @param #number altitude (Optional) Altitude in meters. Default is the land height at the coordinate.
  -- @return #COORDINATE
  function COORDINATE:NewFromLLDD( latitude, longitude, altitude)

    -- Returns a point from latitude and longitude in the vec3 format.
    local vec3=coord.LLtoLO(latitude, longitude)

    -- Convert vec3 to coordinate object.
    local _coord=self:NewFromVec3(vec3)

    -- Adjust height
    if altitude==nil then
      _coord.y=self:GetLandHeight()
    else
      _coord.y=altitude
    end

    return _coord
  end


  --- Returns if the 2 coordinates are at the same 2D position.
  -- @param #COORDINATE self
  -- @param #COORDINATE Coordinate
  -- @param #number Precision
  -- @return #boolean true if at the same position.
  function COORDINATE:IsAtCoordinate2D( Coordinate, Precision )

    self:F( { Coordinate = Coordinate:GetVec2() } )
    self:F( { self = self:GetVec2() } )

    local x = Coordinate.x
    local z = Coordinate.z

    return x - Precision <= self.x and x + Precision >= self.x and z - Precision <= self.z and z + Precision >= self.z
  end

  --- Scan/find objects (units, statics, scenery) within a certain radius around the coordinate using the world.searchObjects() DCS API function.
  -- @param #COORDINATE self
  -- @param #number radius (Optional) Scan radius in meters. Default 100 m.
  -- @param #boolean scanunits (Optional) If true scan for units. Default true.
  -- @param #boolean scanstatics (Optional) If true scan for static objects. Default true.
  -- @param #boolean scanscenery (Optional) If true scan for scenery objects. Default false.
  -- @return #boolean True if units were found.
  -- @return #boolean True if statics were found.
  -- @return #boolean True if scenery objects were found.
  -- @return #table Table of MOOSE @{Wrapper.Unit#UNIT} objects found.
  -- @return #table Table of DCS static objects found.
  -- @return #table Table of DCS scenery objects found.
  function COORDINATE:ScanObjects(radius, scanunits, scanstatics, scanscenery)
    self:F(string.format("Scanning in radius %.1f m.", radius or 100))

    local SphereSearch = {
      id = world.VolumeType.SPHERE,
        params = {
        point = self:GetVec3(),
        radius = radius,
        }
      }

    -- Defaults
    radius=radius or 100
    if scanunits==nil then
      scanunits=true
    end
    if scanstatics==nil then
      scanstatics=true
    end
    if scanscenery==nil then
      scanscenery=false
    end

    --{Object.Category.UNIT, Object.Category.STATIC, Object.Category.SCENERY}
    local scanobjects={}
    if scanunits then
      table.insert(scanobjects, Object.Category.UNIT)
    end
    if scanstatics then
      table.insert(scanobjects, Object.Category.STATIC)
    end
    if scanscenery then
      table.insert(scanobjects, Object.Category.SCENERY)
    end

    -- Found stuff.
    local Units = {}
    local Statics = {}
    local Scenery = {}
    local gotstatics=false
    local gotunits=false
    local gotscenery=false

    local function EvaluateZone(ZoneObject)

      if ZoneObject then

        -- Get category of scanned object.
        local ObjectCategory = Object.getCategory(ZoneObject)

        -- Check for unit or static objects
        if ObjectCategory==Object.Category.UNIT and ZoneObject:isExist() then

          table.insert(Units, UNIT:Find(ZoneObject))
          gotunits=true

        elseif ObjectCategory==Object.Category.STATIC and ZoneObject:isExist() then

          table.insert(Statics, ZoneObject)
          gotstatics=true

        elseif ObjectCategory==Object.Category.SCENERY then

          table.insert(Scenery, ZoneObject)
          gotscenery=true

        end

      end

      return true
    end

    -- Search the world.
    world.searchObjects(scanobjects, SphereSearch, EvaluateZone)

    for _,unit in pairs(Units) do
      self:T(string.format("Scan found unit %s", unit:GetName()))
    end
    for _,static in pairs(Statics) do
      self:T(string.format("Scan found static %s", static:getName()))
      _DATABASE:AddStatic(static:getName())
    end
    for _,scenery in pairs(Scenery) do
      self:T(string.format("Scan found scenery %s typename=%s", scenery:getName(), scenery:getTypeName()))
      --SCENERY:Register(scenery:getName(), scenery)
    end

    return gotunits, gotstatics, gotscenery, Units, Statics, Scenery
  end

  --- Scan/find UNITS within a certain radius around the coordinate using the world.searchObjects() DCS API function.
  -- @param #COORDINATE self
  -- @param #number radius (Optional) Scan radius in meters. Default 100 m.
  -- @return Core.Set#SET_UNIT Set of units.
  function COORDINATE:ScanUnits(radius)

    local _,_,_,units=self:ScanObjects(radius, true, false, false)

    local set=SET_UNIT:New()

    for _,unit in pairs(units) do
      set:AddUnit(unit)
    end

    return set
  end
  
  --- Scan/find STATICS within a certain radius around the coordinate using the world.searchObjects() DCS API function.
  -- @param #COORDINATE self
  -- @param #number radius (Optional) Scan radius in meters. Default 100 m.
  -- @return Core.Set#SET_UNIT Set of units.
  function COORDINATE:ScanStatics(radius)

    local _,_,_,_,statics=self:ScanObjects(radius, false, true, false)

    local set=SET_STATIC:New()

    for _,stat in pairs(statics) do
      set:AddStatic(STATIC:Find(stat))
    end

    return set
  end

  --- Find the closest static to the COORDINATE within a certain radius.
  -- @param #COORDINATE self
  -- @param #number radius Scan radius in meters. Default 100 m.
  -- @return Wrapper.Static#STATIC The closest static or #nil if no unit is inside the given radius.
  function COORDINATE:FindClosestStatic(radius)

    local units=self:ScanStatics(radius)

    local umin=nil --Wrapper.Unit#UNIT
    local dmin=math.huge
    for _,_unit in pairs(units.Set) do
      local unit=_unit --Wrapper.Static#STATIC
      local coordinate=unit:GetCoordinate()
      local d=self:Get2DDistance(coordinate)
      if d<dmin then
        dmin=d
        umin=unit
      end
    end

    return umin
  end

  --- Find the closest unit to the COORDINATE within a certain radius.
  -- @param #COORDINATE self
  -- @param #number radius Scan radius in meters. Default 100 m.
  -- @return Wrapper.Unit#UNIT The closest unit or #nil if no unit is inside the given radius.
  function COORDINATE:FindClosestUnit(radius)

    local units=self:ScanUnits(radius)

    local umin=nil --Wrapper.Unit#UNIT
    local dmin=math.huge
    for _,_unit in pairs(units.Set) do
      local unit=_unit --Wrapper.Unit#UNIT
      local coordinate=unit:GetCoordinate()
      local d=self:Get2DDistance(coordinate)
      if d<dmin then
        dmin=d
        umin=unit
      end
    end

    return umin
  end

  --- Scan/find SCENERY objects within a certain radius around the coordinate using the world.searchObjects() DCS API function.
  -- @param #COORDINATE self
  -- @param #number radius (Optional) Scan radius in meters. Default 100 m.
  -- @return table Table of SCENERY objects.
  function COORDINATE:ScanScenery(radius)

    local _,_,_,_,_,scenerys=self:ScanObjects(radius, false, false, true)

    local set={}

    for _,_scenery in pairs(scenerys) do
      local scenery=_scenery --DCS#Object

      local name=scenery:getName()
      local s=SCENERY:Register(name, scenery)
      table.insert(set, s)

    end

    return set
  end

  --- Find the closest scenery to the COORDINATE within a certain radius.
  -- @param #COORDINATE self
  -- @param #number radius Scan radius in meters. Default 100 m.
  -- @return Wrapper.Scenery#SCENERY The closest scenery or #nil if no object is inside the given radius.
  function COORDINATE:FindClosestScenery(radius)

    local sceneries=self:ScanScenery(radius)

    local umin=nil --Wrapper.Scenery#SCENERY
    local dmin=math.huge
    for _,_scenery in pairs(sceneries) do
      local scenery=_scenery --Wrapper.Scenery#SCENERY
      local coordinate=scenery:GetCoordinate()
      local d=self:Get2DDistance(coordinate)
      if d<dmin then
        dmin=d
        umin=scenery
      end
    end

    return umin
  end

  --- Calculate the distance from a reference @{#COORDINATE}.
  -- @param #COORDINATE self
  -- @param #COORDINATE PointVec2Reference The reference @{#COORDINATE}.
  -- @return DCS#Distance The distance from the reference @{#COORDINATE} in meters.
  function COORDINATE:DistanceFromPointVec2( PointVec2Reference )
    self:F2( PointVec2Reference )  
    if not PointVec2Reference then return math.huge end
    
    local Distance = ( ( PointVec2Reference.x - self.x ) ^ 2 + ( PointVec2Reference.z - self.z ) ^2 ) ^ 0.5

    self:T2( Distance )
    return Distance
  end

  --- Add a Distance in meters from the COORDINATE orthonormal plane, with the given angle, and calculate the new COORDINATE.
  -- @param #COORDINATE self
  -- @param DCS#Distance Distance The Distance to be added in meters.
  -- @param DCS#Angle Angle The Angle in degrees. Defaults to 0 if not specified (nil).
  -- @param #boolean Keepalt If true, keep altitude of original coordinate. Default is that the new coordinate is created at the translated land height.
  -- @param #boolean Overwrite If true, overwrite the original COORDINATE with the translated one. Otherwise, create a new COORDINATE.
  -- @return #COORDINATE The new calculated COORDINATE.
  function COORDINATE:Translate( Distance, Angle, Keepalt, Overwrite )

    -- Angle in rad.
    local alpha = math.rad((Angle or 0))

    local x = Distance * math.cos(alpha) + self.x  -- New x
    local z = Distance * math.sin(alpha) + self.z  -- New z

    local y=Keepalt and self.y or land.getHeight({x=x, y=z})

    if Overwrite then
      self.x=x
      self.y=y
      self.z=z
      return self
    else
      --env.info("FF translate with NEW coordinate T="..timer.getTime())
      local coord=COORDINATE:New(x, y, z)
      return coord
    end

  end

  --- Rotate coordinate in 2D (x,z) space.
  -- @param #COORDINATE self
  -- @param DCS#Angle Angle Angle of rotation in degrees.
  -- @return Core.Point#COORDINATE The rotated coordinate.
  function COORDINATE:Rotate2D(Angle)

    if not Angle then
      return self
    end

    local phi=math.rad(Angle)

    local X=self.z
    local Y=self.x

    --slocal R=math.sqrt(X*X+Y*Y)

    local x=X*math.cos(phi)-Y*math.sin(phi)
    local y=X*math.sin(phi)+Y*math.cos(phi)

    -- Coordinate assignment looks bit strange but is correct.
    local coord=COORDINATE:NewFromVec3({x=y, y=self.y, z=x})
    return coord
  end

  --- Return a random Vec2 within an Outer Radius and optionally NOT within an Inner Radius of the COORDINATE.
  -- @param #COORDINATE self
  -- @param DCS#Distance OuterRadius
  -- @param DCS#Distance InnerRadius
  -- @return DCS#Vec2 Vec2
  function COORDINATE:GetRandomVec2InRadius( OuterRadius, InnerRadius )
    self:F2( { OuterRadius, InnerRadius } )

    local Theta = 2 * math.pi * math.random()
    local Radials = math.random() + math.random()
    if Radials > 1 then
      Radials = 2 - Radials
    end

    local RadialMultiplier
    if InnerRadius and InnerRadius <= OuterRadius then
      RadialMultiplier = ( OuterRadius - InnerRadius ) * Radials + InnerRadius
    else
      RadialMultiplier = OuterRadius * Radials
    end

    local RandomVec2
    if OuterRadius > 0 then
      RandomVec2 = { x = math.cos( Theta ) * RadialMultiplier + self.x, y = math.sin( Theta ) * RadialMultiplier + self.z }
    else
      RandomVec2 = { x = self.x, y = self.z }
    end

    return RandomVec2
  end


  --- Return a random Coordinate within an Outer Radius and optionally NOT within an Inner Radius of the COORDINATE.
  -- @param #COORDINATE self
  -- @param DCS#Distance OuterRadius Outer radius in meters.
  -- @param DCS#Distance InnerRadius Inner radius in meters.
  -- @return #COORDINATE self
  function COORDINATE:GetRandomCoordinateInRadius( OuterRadius, InnerRadius )
    self:F2( { OuterRadius, InnerRadius } )

    local coord=COORDINATE:NewFromVec2( self:GetRandomVec2InRadius( OuterRadius, InnerRadius ) )
    return coord
  end


  --- Return a random Vec3 within an Outer Radius and optionally NOT within an Inner Radius of the COORDINATE.
  -- @param #COORDINATE self
  -- @param DCS#Distance OuterRadius
  -- @param DCS#Distance InnerRadius
  -- @return DCS#Vec3 Vec3
  function COORDINATE:GetRandomVec3InRadius( OuterRadius, InnerRadius )

    local RandomVec2 = self:GetRandomVec2InRadius( OuterRadius, InnerRadius )
    local y = self.y + math.random( InnerRadius, OuterRadius )
    local RandomVec3 = { x = RandomVec2.x, y = y, z = RandomVec2.y }

    return RandomVec3
  end

  --- Return the height of the land at the coordinate.
  -- @param #COORDINATE self
  -- @return #number Land height (ASL) in meters.
  function COORDINATE:GetLandHeight()
    local Vec2 = { x = self.x, y = self.z }
    return land.getHeight( Vec2 )
  end


  --- Set the heading of the coordinate, if applicable.
  -- @param #COORDINATE self
  function COORDINATE:SetHeading( Heading )
    self.Heading = Heading
  end


  --- Get the heading of the coordinate, if applicable.
  -- @param #COORDINATE self
  -- @return #number or nil
  function COORDINATE:GetHeading()
    return self.Heading
  end


  --- Set the velocity of the COORDINATE.
  -- @param #COORDINATE self
  -- @param #string Velocity Velocity in meters per second.
  function COORDINATE:SetVelocity( Velocity )
    self.Velocity = Velocity
  end


  --- Return the velocity of the COORDINATE.
  -- @param #COORDINATE self
  -- @return #number Velocity in meters per second.
  function COORDINATE:GetVelocity()
    local Velocity = self.Velocity
    return Velocity or 0
  end

  --- Return the "name" of the COORDINATE. Obviously, a coordinate does not have a name like a unit, static or group. So here we take the MGRS coordinates of the position.
  -- @param #COORDINATE self
  -- @return #string MGRS coordinates.
  function COORDINATE:GetName()
    local name=self:ToStringMGRS()
    return name
  end

  --- Return velocity text of the COORDINATE.
  -- @param #COORDINATE self
  -- @return #string
  function COORDINATE:GetMovingText( Settings )

    return self:GetVelocityText( Settings ) .. ", " .. self:GetHeadingText( Settings )
  end


  --- Return a direction vector Vec3 from COORDINATE to the COORDINATE.
  -- @param #COORDINATE self
  -- @param #COORDINATE TargetCoordinate The target COORDINATE.
  -- @return DCS#Vec3 DirectionVec3 The direction vector in Vec3 format.
  function COORDINATE:GetDirectionVec3( TargetCoordinate )
    if TargetCoordinate then
      return { x = TargetCoordinate.x - self.x, y = TargetCoordinate.y - self.y, z = TargetCoordinate.z - self.z }
    else
      return { x=0,y=0,z=0}
    end
  end


  --- Get a correction in radians of the real magnetic north of the COORDINATE.
  -- @param #COORDINATE self
  -- @return #number CorrectionRadians The correction in radians.
  function COORDINATE:GetNorthCorrectionRadians()
    local TargetVec3 = self:GetVec3()
    local lat, lon = coord.LOtoLL(TargetVec3)
    local north_posit = coord.LLtoLO(lat + 1, lon)
    return math.atan2( north_posit.z - TargetVec3.z, north_posit.x - TargetVec3.x )
  end


  --- Return an angle in radians from the COORDINATE using a **direction vector in Vec3 format**.
  -- @param #COORDINATE self
  -- @param DCS#Vec3 DirectionVec3 The direction vector in Vec3 format.
  -- @return #number DirectionRadians The angle in radians.
  function COORDINATE:GetAngleRadians( DirectionVec3 )
    local DirectionRadians = math.atan2( DirectionVec3.z, DirectionVec3.x )
    --DirectionRadians = DirectionRadians + self:GetNorthCorrectionRadians()
    if DirectionRadians < 0 then
      DirectionRadians = DirectionRadians + 2 * math.pi  -- put dir in range of 0 to 2*pi ( the full circle )
    end
    return DirectionRadians
  end

  --- Return an angle in degrees from the COORDINATE using a **direction vector in Vec3 format**.
  -- @param #COORDINATE self
  -- @param DCS#Vec3 DirectionVec3 The direction vector in Vec3 format.
  -- @return #number DirectionRadians The angle in degrees.
  -- @usage
  --         local directionAngle = currentCoordinate:GetAngleDegrees(currentCoordinate:GetDirectionVec3(sourceCoordinate:GetVec3()))
  function COORDINATE:GetAngleDegrees( DirectionVec3 )
    local AngleRadians = self:GetAngleRadians( DirectionVec3 )
    local Angle = UTILS.ToDegree( AngleRadians )
    return Angle
  end

  --- Return an intermediate COORDINATE between this an another coordinate.
  -- @param #COORDINATE self
  -- @param #COORDINATE ToCoordinate The other coordinate.
  -- @param #number Fraction The fraction (0,1) where the new coordinate is created. Default 0.5, i.e. in the middle.
  -- @return #COORDINATE Coordinate between this and the other coordinate.
  function COORDINATE:GetIntermediateCoordinate( ToCoordinate, Fraction )

    local f=Fraction or 0.5

    -- Get the vector from A to B
    local vec=UTILS.VecSubstract(ToCoordinate, self)
    
    if f>1 then
      local norm=UTILS.VecNorm(vec)      
      f=Fraction/norm
    end

    -- Scale the vector.
    vec.x=f*vec.x
    vec.y=f*vec.y
    vec.z=f*vec.z

    -- Move the vector to start at the end of A.
    vec=UTILS.VecAdd(self, vec)

    -- Create a new coordiante object.
    local coord=COORDINATE:New(vec.x,vec.y,vec.z)
    
    return coord
  end

  --- Return the 2D distance in meters between the target COORDINATE and the COORDINATE.
  -- @param #COORDINATE self
  -- @param #COORDINATE TargetCoordinate The target COORDINATE. Can also be a DCS#Vec3.
  -- @return DCS#Distance Distance The distance in meters.
  function COORDINATE:Get2DDistance(TargetCoordinate)
    if not TargetCoordinate then return 1000000 end
    --local a={x=TargetCoordinate.x-self.x, y=0, z=TargetCoordinate.z-self.z}
    local a = self:GetVec2()
    local b = TargetCoordinate:GetVec2()
    local norm=UTILS.VecDist2D(a,b)
    return norm
  end

  --- Returns the temperature in Degrees Celsius.
  -- @param #COORDINATE self
  -- @param height (Optional) parameter specifying the height ASL.
  -- @return Temperature in Degrees Celsius.
  function COORDINATE:GetTemperature(height)
    self:F2(height)
    local y=height or self.y
    local point={x=self.x, y=height or self.y, z=self.z}
    -- get temperature [K] and pressure [Pa] at point
    local T,P=atmosphere.getTemperatureAndPressure(point)
    -- Return Temperature in Deg C
    return T-273.15
  end

  --- Returns a text of the temperature according the measurement system @{Core.Settings}.
  -- The text will reflect the temperature like this:
  --
  --   - For Russian and European aircraft using the metric system - Degrees Celcius (°C)
  --   - For American aircraft we link to the imperial system - Degrees Fahrenheit (°F)
  --
  -- A text containing a pressure will look like this:
  --
  --   - `Temperature: %n.d °C`
  --   - `Temperature: %n.d °F`
  --
   -- @param #COORDINATE self
  -- @param height (Optional) parameter specifying the height ASL.
  -- @return #string Temperature according the measurement system @{Core.Settings}.
  function COORDINATE:GetTemperatureText( height, Settings )

    local DegreesCelcius = self:GetTemperature( height )

    local Settings = Settings or _SETTINGS

    if DegreesCelcius then
      if Settings:IsMetric() then
        return string.format( " %-2.2f °C", DegreesCelcius )
      else
        return string.format( " %-2.2f °F", UTILS.CelsiusToFahrenheit( DegreesCelcius ) )
      end
    else
      return " no temperature"
    end

    return nil
  end


  --- Returns the pressure in hPa.
  -- @param #COORDINATE self
  -- @param height (Optional) parameter specifying the height ASL. E.g. set height=0 for QNH.
  -- @return Pressure in hPa.
  function COORDINATE:GetPressure(height)
    local point={x=self.x, y=height or self.y, z=self.z}
    -- get temperature [K] and pressure [Pa] at point
    local T,P=atmosphere.getTemperatureAndPressure(point)
    -- Return Pressure in hPa.
    return P/100
  end

  --- Returns a text of the pressure according the measurement system @{Core.Settings}.
  -- The text will contain always the pressure in hPa and:
  --
  --   - For Russian and European aircraft using the metric system - hPa and mmHg
  --   - For American and European aircraft we link to the imperial system - hPa and inHg
  --
  -- A text containing a pressure will look like this:
  --
  --   - `QFE: x hPa (y mmHg)`
  --   - `QFE: x hPa (y inHg)`
  --
  -- @param #COORDINATE self
  -- @param height (Optional) parameter specifying the height ASL. E.g. set height=0 for QNH.
  -- @return #string Pressure in hPa and mmHg or inHg depending on the measurement system @{Core.Settings}.
  function COORDINATE:GetPressureText( height, Settings )

    local Pressure_hPa = self:GetPressure( height )
    local Pressure_mmHg = Pressure_hPa * 0.7500615613030
    local Pressure_inHg = Pressure_hPa * 0.0295299830714

    local Settings = Settings or _SETTINGS

    if Pressure_hPa then
      if Settings:IsMetric() then
        return string.format( " %4.1f hPa (%3.1f mmHg)", Pressure_hPa, Pressure_mmHg )
      else
        return string.format( " %4.1f hPa (%3.2f inHg)", Pressure_hPa, Pressure_inHg )
      end
    else
      return " no pressure"
    end

    return nil
  end

  --- Returns the heading from this to another coordinate.
  -- @param #COORDINATE self
  -- @param #COORDINATE ToCoordinate
  -- @return #number Heading in degrees.
  function COORDINATE:HeadingTo(ToCoordinate)
    local dz=ToCoordinate.z-self.z
    local dx=ToCoordinate.x-self.x
    local heading=math.deg(math.atan2(dz, dx))
    if heading < 0 then
      heading = 360 + heading
    end
    return heading
  end

  --- Returns the 3D wind direction vector. Note that vector points into the direction the wind in blowing to.
  -- @param #COORDINATE self
  -- @param #number height (Optional) parameter specifying the height ASL in meters. The minimum height will be always be the land height since the wind is zero below the ground.
  -- @param #boolean turbulence (Optional) If `true`, include turbulence.
  -- @return DCS#Vec3 Wind 3D vector. Components in m/s.
  function COORDINATE:GetWindVec3(height, turbulence)
  
    -- We at 0.1 meters to be sure to be above ground since wind is zero below ground level.
    local landheight=self:GetLandHeight()+0.1 
  
    local point={x=self.x, y=math.max(height or self.y, landheight), z=self.z}
        
    -- Get wind velocity vector.
    local wind = nil --DCS#Vec3
    
    if turbulence then
      wind = atmosphere.getWindWithTurbulence(point)
    else
      wind = atmosphere.getWind(point)
    end
    
    return wind
  end

  --- Returns the wind direction (from) and strength.
  -- @param #COORDINATE self
  -- @param #number height (Optional) parameter specifying the height ASL. The minimum height will be always be the land height since the wind is zero below the ground.
  -- @param #boolean turbulence If `true`, include turbulence. If `false` or `nil`, wind without turbulence.
  -- @return #number Direction the wind is blowing from in degrees.
  -- @return #number Wind strength in m/s.
  function COORDINATE:GetWind(height, turbulence)

    -- Get wind velocity vector
    local wind = self:GetWindVec3(height, turbulence)

    -- Calculate the direction of the vector.    
    local direction=UTILS.VecHdg(wind)
    
    -- Invert "to" direction to "from" direction.
    if direction > 180 then
      direction = direction-180
    else
      direction = direction+180
    end
    
    -- Wind strength in m/s.
    local strength=UTILS.VecNorm(wind) -- math.sqrt((wind.x)^2+(wind.z)^2)
    
    -- Return wind direction and strength.
    return direction, strength
  end

  --- Returns the wind direction (from) and strength.
  -- @param #COORDINATE self
  -- @param height (Optional) parameter specifying the height ASL. The minimum height will be always be the land height since the wind is zero below the ground.
  -- @return Direction the wind is blowing from in degrees.
  function COORDINATE:GetWindWithTurbulenceVec3(height)

    -- AGL height if
    local landheight=self:GetLandHeight()+0.1 -- we at 0.1 meters to be sure to be above ground since wind is zero below ground level.

    -- Point at which the wind is evaluated.
    local point={x=self.x, y=math.max(height or self.y, landheight), z=self.z}

    -- Get wind velocity vector including turbulences.
    local vec3 = atmosphere.getWindWithTurbulence(point)

    return vec3
  end


  --- Returns a text documenting the wind direction (from) and strength according the measurement system @{Core.Settings}.
  -- The text will reflect the wind like this:
  --
  --   - For Russian and European aircraft using the metric system - Wind direction in degrees (°) and wind speed in meters per second (mps).
  --   - For American aircraft we link to the imperial system - Wind direction in degrees (°) and wind speed in knots per second (kps).
  --
  -- A text containing a pressure will look like this:
  --
  --   - `Wind: %n ° at n.d mps`
  --   - `Wind: %n ° at n.d kps`
  --
  -- @param #COORDINATE self
  -- @param height (Optional) parameter specifying the height ASL. The minimum height will be always be the land height since the wind is zero below the ground.
  -- @return #string Wind direction and strength according the measurement system @{Core.Settings}.
  function COORDINATE:GetWindText( height, Settings )

    local Direction, Strength = self:GetWind( height )

    local Settings = Settings or _SETTINGS

    if Direction and Strength then
      if Settings:IsMetric() then
        return string.format( " %d ° at %3.2f mps", Direction, UTILS.MpsToKmph( Strength ) )
      else
        return string.format( " %d ° at %3.2f kps", Direction, UTILS.MpsToKnots( Strength ) )
      end
    else
      return " no wind"
    end

    return nil
  end

  --- Return the 3D distance in meters between the target COORDINATE and the COORDINATE.
  -- @param #COORDINATE self
  -- @param #COORDINATE TargetCoordinate The target COORDINATE. Can also be a DCS#Vec3.
  -- @return DCS#Distance Distance The distance in meters.
  function COORDINATE:Get3DDistance( TargetCoordinate )
    --local TargetVec3 = TargetCoordinate:GetVec3()
    local TargetVec3 = {x=TargetCoordinate.x, y=TargetCoordinate.y, z=TargetCoordinate.z}
    local SourceVec3 = self:GetVec3()
    --local dist=( ( TargetVec3.x - SourceVec3.x ) ^ 2 + ( TargetVec3.y - SourceVec3.y ) ^ 2 + ( TargetVec3.z - SourceVec3.z ) ^ 2 ) ^ 0.5
    local dist=UTILS.VecDist3D(TargetVec3, SourceVec3)
    return dist
  end


  --- Provides a bearing text in degrees.
  -- @param #COORDINATE self
  -- @param #number AngleRadians The angle in randians.
  -- @param #number Precision The precision.
  -- @param Core.Settings#SETTINGS Settings
  -- @param #boolean MagVar If true, include magentic degrees
  -- @return #string The bearing text in degrees.
  function COORDINATE:GetBearingText( AngleRadians, Precision, Settings, MagVar )

    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS

    local AngleDegrees = UTILS.Round( UTILS.ToDegree( AngleRadians ), Precision )

    local s = string.format( '%03d°', AngleDegrees )
    
    if MagVar then
      local variation = UTILS.GetMagneticDeclination() or 0
      local AngleMagnetic = AngleDegrees - variation
      
      if AngleMagnetic < 0 then AngleMagnetic = 360-AngleMagnetic end
      
      s = string.format( '%03d°M|%03d°', AngleMagnetic,AngleDegrees )
    end
    
    return s
  end

  --- Provides a distance text expressed in the units of measurement.
  -- @param #COORDINATE self
  -- @param #number Distance The distance in meters.
  -- @param Core.Settings#SETTINGS Settings
  -- @param #string Language (optional) "EN" or "RU"
  -- @param #number Precision (optional) round to this many decimal places
  -- @return #string The distance text expressed in the units of measurement.
  function COORDINATE:GetDistanceText( Distance, Settings, Language, Precision )

    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS
    local Language = Language or Settings.Locale or _SETTINGS.Locale or "EN"
    Language = string.lower(Language)
    local Precision = Precision or 0
    
    local DistanceText

    if Settings:IsMetric() then
      if     Language == "en" then
        DistanceText = " for " .. UTILS.Round( Distance / 1000, Precision ) .. " km"
      elseif Language == "ru" then
        DistanceText = " за " .. UTILS.Round( Distance / 1000, Precision ) .. " километров"
      end
    else
      if     Language == "en" then
        DistanceText = " for " .. UTILS.Round( UTILS.MetersToNM( Distance ), Precision ) .. " miles"
      elseif Language == "ru" then
        DistanceText = " за " .. UTILS.Round( UTILS.MetersToNM( Distance ), Precision ) .. " миль"
      end
    end

    return DistanceText
  end

  --- Return the altitude text of the COORDINATE.
  -- @param #COORDINATE self
  -- @return #string Altitude text.
  function COORDINATE:GetAltitudeText( Settings, Language )
    local Altitude = self.y
    local Settings = Settings or _SETTINGS
    local Language = Language or Settings.Locale or _SETTINGS.Locale or "EN"
    
    Language = string.lower(Language)
    
    if Altitude ~= 0 then
      if Settings:IsMetric() then
        if     Language == "en" then
          return " at " .. UTILS.Round( self.y, -3 ) .. " meters"
        elseif Language == "ru" then
          return " в " .. UTILS.Round( self.y, -3 ) .. " метры"
        end
      else
        if     Language == "en" then
          return " at " .. UTILS.Round( UTILS.MetersToFeet( self.y ), -3 ) .. " feet"
        elseif Language == "ru" then
          return " в " .. UTILS.Round( self.y, -3 ) .. " ноги"
        end
      end
    else
      return ""
    end
  end



  --- Return the velocity text of the COORDINATE.
  -- @param #COORDINATE self
  -- @return #string Velocity text.
  function COORDINATE:GetVelocityText( Settings )
    local Velocity = self:GetVelocity()
    local Settings = Settings or _SETTINGS
    if Velocity then
      if Settings:IsMetric() then
        return string.format( " moving at %d km/h", UTILS.MpsToKmph( Velocity ) )
      else
        return string.format( " moving at %d mi/h", UTILS.MpsToKmph( Velocity ) / 1.852 )
      end
    else
      return " stationary"
    end
  end


  --- Return the heading text of the COORDINATE.
  -- @param #COORDINATE self
  -- @return #string Heading text.
  function COORDINATE:GetHeadingText( Settings )
    local Heading = self:GetHeading()
    if Heading then
      return string.format( " bearing %3d°", Heading )
    else
      return " bearing unknown"
    end
  end


  --- Provides a Bearing / Range string
  -- @param #COORDINATE self
  -- @param #number AngleRadians The angle in randians
  -- @param #number Distance The distance
  -- @param Core.Settings#SETTINGS Settings
  -- @param #string Language (Optional) Language "en" or "ru"
  -- @param #boolean MagVar If true, also state angle in magnetic
  -- @param #number Precision Rounding precision, defaults to 0
  -- @return #string The BR Text
  function COORDINATE:GetBRText( AngleRadians, Distance, Settings, Language, MagVar, Precision )

    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS
      
    Precision = Precision or 0
      
    local BearingText = self:GetBearingText( AngleRadians, 0, Settings, MagVar )
    local DistanceText = self:GetDistanceText( Distance, Settings, Language, Precision )

    local BRText = BearingText .. DistanceText

    return BRText
  end

  --- Provides a Bearing / Range / Altitude string
  -- @param #COORDINATE self
  -- @param #number AngleRadians The angle in randians
  -- @param #number Distance The distance
  -- @param Core.Settings#SETTINGS Settings
  -- @param #string Language (Optional) Language "en" or "ru"
  -- @param #boolean MagVar If true, also state angle in magnetic
  -- @return #string The BRA Text
  function COORDINATE:GetBRAText( AngleRadians, Distance, Settings, Language, MagVar )

    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS

    local BearingText = self:GetBearingText( AngleRadians, 0, Settings, MagVar )
    local DistanceText = self:GetDistanceText( Distance, Settings, Language, 0  )
    local AltitudeText = self:GetAltitudeText( Settings, Language  )

    local BRAText = BearingText .. DistanceText .. AltitudeText -- When the POINT is a VEC2, there will be no altitude shown.

    return BRAText
  end


  --- Set altitude.
  -- @param #COORDINATE self
  -- @param #number altitude New altitude in meters.
  -- @param #boolean asl Altitude above sea level. Default is above ground level.
  -- @return #COORDINATE The COORDINATE with adjusted altitude.
  function COORDINATE:SetAltitude(altitude, asl)
    local alt=altitude
    if asl then
      alt=altitude
    else
      alt=self:GetLandHeight()+altitude
    end
    self.y=alt
    return self
  end
  
  --- Set altitude to be at land height (i.e. on the ground!)
  -- @param #COORDINATE self
  function COORDINATE:SetAtLandheight()
    local alt=self:GetLandHeight()
    self.y=alt
    return self
  end
  
  --- Build an air type route point.
  -- @param #COORDINATE self
  -- @param #COORDINATE.WaypointAltType AltType The altitude type.
  -- @param #COORDINATE.WaypointType Type The route point type.
  -- @param #COORDINATE.WaypointAction Action The route point action.
  -- @param DCS#Speed Speed Airspeed in km/h. Default is 500 km/h.
  -- @param #boolean SpeedLocked true means the speed is locked.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase for takeoff and landing points.
  -- @param #table DCSTasks A table of @{DCS#Task} items which are executed at the waypoint.
  -- @param #string description A text description of the waypoint, which will be shown on the F10 map.
  -- @param #number timeReFuAr Time in minutes the aircraft stays at the airport for ReFueling and ReArming.
  -- @return #table The route point.
  function COORDINATE:WaypointAir( AltType, Type, Action, Speed, SpeedLocked, airbase, DCSTasks, description, timeReFuAr )
    self:F2( { AltType, Type, Action, Speed, SpeedLocked } )

    -- Set alttype or "RADIO" which is AGL.
    AltType=AltType or "RADIO"

    -- Speedlocked by default
    if SpeedLocked==nil then
      SpeedLocked=true
    end

    -- Speed or default 500 km/h.
    Speed=Speed or 500

    -- Waypoint array.
    local RoutePoint = {}

    -- Coordinates.
    RoutePoint.x = self.x
    RoutePoint.y = self.z

    -- Altitude.
    RoutePoint.alt = self.y
    RoutePoint.alt_type = AltType

    -- Waypoint type.
    RoutePoint.type = Type or nil
    RoutePoint.action = Action or nil

    -- Speed.
    RoutePoint.speed = Speed/3.6
    RoutePoint.speed_locked = SpeedLocked

    -- ETA.
    RoutePoint.ETA=0
    RoutePoint.ETA_locked=false

    -- Waypoint description.
    RoutePoint.name=description

    -- Airbase parameters for takeoff and landing points.
    if airbase then
      local AirbaseID = airbase:GetID()
      local AirbaseCategory = airbase:GetAirbaseCategory()
      if AirbaseCategory == Airbase.Category.SHIP or AirbaseCategory == Airbase.Category.HELIPAD then
        RoutePoint.linkUnit = AirbaseID
        RoutePoint.helipadId = AirbaseID
      elseif AirbaseCategory == Airbase.Category.AIRDROME then
        RoutePoint.airdromeId = AirbaseID
      else
        self:E("ERROR: Unknown airbase category in COORDINATE:WaypointAir()!")
      end
    end

    -- Time in minutes to stay at the airbase before resuming route.
    if Type==COORDINATE.WaypointType.LandingReFuAr then
      RoutePoint.timeReFuAr=timeReFuAr or 10
    end

    -- Waypoint tasks.
    RoutePoint.task = {}
    RoutePoint.task.id = "ComboTask"
    RoutePoint.task.params = {}
    RoutePoint.task.params.tasks = DCSTasks or {}

    --RoutePoint.properties={}
    --RoutePoint.properties.addopt={}

    --RoutePoint.formation_template=""

    -- Debug.
    self:T({RoutePoint=RoutePoint})

    -- Return waypoint.
    return RoutePoint
  end


  --- Build a Waypoint Air "Turning Point".
  -- @param #COORDINATE self
  -- @param #COORDINATE.WaypointAltType AltType The altitude type.
  -- @param DCS#Speed Speed Airspeed in km/h.
  -- @param #table DCSTasks (Optional) A table of @{DCS#Task} items which are executed at the waypoint.
  -- @param #string description (Optional) A text description of the waypoint, which will be shown on the F10 map.
  -- @return #table The route point.
  function COORDINATE:WaypointAirTurningPoint( AltType, Speed, DCSTasks, description )
    return self:WaypointAir( AltType, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, Speed, true, nil, DCSTasks, description )
  end


  --- Build a Waypoint Air "Fly Over Point".
  -- @param #COORDINATE self
  -- @param #COORDINATE.WaypointAltType AltType The altitude type.
  -- @param DCS#Speed Speed Airspeed in km/h.
  -- @return #table The route point.
  function COORDINATE:WaypointAirFlyOverPoint( AltType, Speed )
    return self:WaypointAir( AltType, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.FlyoverPoint, Speed )
  end


  --- Build a Waypoint Air "Take Off Parking Hot".
  -- @param #COORDINATE self
  -- @param #COORDINATE.WaypointAltType AltType The altitude type.
  -- @param DCS#Speed Speed Airspeed in km/h.
  -- @return #table The route point.
  function COORDINATE:WaypointAirTakeOffParkingHot( AltType, Speed )
    return self:WaypointAir( AltType, COORDINATE.WaypointType.TakeOffParkingHot, COORDINATE.WaypointAction.FromParkingAreaHot, Speed )
  end


  --- Build a Waypoint Air "Take Off Parking".
  -- @param #COORDINATE self
  -- @param #COORDINATE.WaypointAltType AltType The altitude type.
  -- @param DCS#Speed Speed Airspeed in km/h.
  -- @return #table The route point.
  function COORDINATE:WaypointAirTakeOffParking( AltType, Speed )
    return self:WaypointAir( AltType, COORDINATE.WaypointType.TakeOffParking, COORDINATE.WaypointAction.FromParkingArea, Speed )
  end


  --- Build a Waypoint Air "Take Off Runway".
  -- @param #COORDINATE self
  -- @param #COORDINATE.WaypointAltType AltType The altitude type.
  -- @param DCS#Speed Speed Airspeed in km/h.
  -- @return #table The route point.
  function COORDINATE:WaypointAirTakeOffRunway( AltType, Speed )
    return self:WaypointAir( AltType, COORDINATE.WaypointType.TakeOff, COORDINATE.WaypointAction.FromRunway, Speed )
  end


  --- Build a Waypoint Air "Landing".
  -- @param #COORDINATE self
  -- @param DCS#Speed Speed Airspeed in km/h.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase for takeoff and landing points.
  -- @param #table DCSTasks A table of @{DCS#Task} items which are executed at the waypoint.
  -- @param #string description A text description of the waypoint, which will be shown on the F10 map.
  -- @return #table The route point.
  -- @usage
  --
  --    LandingZone = ZONE:New( "LandingZone" )
  --    LandingCoord = LandingZone:GetCoordinate()
  --    LandingWaypoint = LandingCoord:WaypointAirLanding( 60 )
  --    HeliGroup:Route( { LandWaypoint }, 1 ) -- Start landing the helicopter in one second.
  --
  function COORDINATE:WaypointAirLanding( Speed, airbase, DCSTasks, description )
    return self:WaypointAir(nil, COORDINATE.WaypointType.Land, COORDINATE.WaypointAction.Landing, Speed, false, airbase, DCSTasks, description)
  end

  --- Build a Waypoint Air "LandingReFuAr". Mimics the aircraft ReFueling and ReArming.
  -- @param #COORDINATE self
  -- @param DCS#Speed Speed Airspeed in km/h.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase for takeoff and landing points.
  -- @param #number timeReFuAr Time in minutes, the aircraft stays at the airbase. Default 10 min.
  -- @param #table DCSTasks A table of @{DCS#Task} items which are executed at the waypoint.
  -- @param #string description A text description of the waypoint, which will be shown on the F10 map.
  -- @return #table The route point.
  function COORDINATE:WaypointAirLandingReFu( Speed, airbase, timeReFuAr, DCSTasks, description )
    return self:WaypointAir(nil, COORDINATE.WaypointType.LandingReFuAr, COORDINATE.WaypointAction.LandingReFuAr, Speed, false, airbase, DCSTasks, description, timeReFuAr or 10)
  end


  --- Build an ground type route point.
  -- @param #COORDINATE self
  -- @param #number Speed (Optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #string Formation (Optional) The route point Formation, which is a text string that specifies exactly the Text in the Type of the route point, like "Vee", "Echelon Right".
  -- @param #table DCSTasks (Optional) A table of DCS tasks that are executed at the waypoints. Mind the curly brackets {}!
  -- @return #table The route point.
  function COORDINATE:WaypointGround( Speed, Formation, DCSTasks )
    self:F2( { Speed, Formation, DCSTasks } )

    local RoutePoint = {}

    RoutePoint.x    = self.x
    RoutePoint.y    = self.z

    RoutePoint.alt      = self:GetLandHeight()+1
    RoutePoint.alt_type = COORDINATE.WaypointAltType.BARO

    RoutePoint.type = "Turning Point"

    RoutePoint.action = Formation or "Off Road"
    RoutePoint.formation_template=""

    RoutePoint.ETA=0
    RoutePoint.ETA_locked=false

    RoutePoint.speed = ( Speed or 20 ) / 3.6
    RoutePoint.speed_locked = true

    RoutePoint.task = {}
    RoutePoint.task.id = "ComboTask"
    RoutePoint.task.params = {}
    RoutePoint.task.params.tasks = DCSTasks or {}

    return RoutePoint
  end

  --- Build route waypoint point for Naval units.
  -- @param #COORDINATE self
  -- @param #number Speed (Optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #string Depth (Optional) Dive depth in meters. Only for submarines. Default is COORDINATE.y component.
  -- @param #table DCSTasks (Optional) A table of DCS tasks that are executed at the waypoints. Mind the curly brackets {}!
  -- @return #table The route point.
  function COORDINATE:WaypointNaval( Speed, Depth, DCSTasks )
    self:F2( { Speed, Depth, DCSTasks } )

    local RoutePoint = {}

    RoutePoint.x    = self.x
    RoutePoint.y    = self.z

    RoutePoint.alt  = Depth or self.y  -- Depth is for submarines only. Ships should have alt=0.
    RoutePoint.alt_type = "BARO"

    RoutePoint.type   = "Turning Point"
    RoutePoint.action = "Turning Point"
    RoutePoint.formation_template = ""

    RoutePoint.ETA=0
    RoutePoint.ETA_locked=false

    RoutePoint.speed = ( Speed or 20 ) / 3.6
    RoutePoint.speed_locked = true

    RoutePoint.task = {}
    RoutePoint.task.id = "ComboTask"
    RoutePoint.task.params = {}
    RoutePoint.task.params.tasks = DCSTasks or {}

    return RoutePoint
  end

  --- Gets the nearest airbase with respect to the current coordinates.
  -- @param #COORDINATE self
  -- @param #number Category (Optional) Category of the airbase. Enumerator of @{Wrapper.Airbase#AIRBASE.Category}.
  -- @param #number Coalition (Optional) Coalition of the airbase.
  -- @return Wrapper.Airbase#AIRBASE Closest Airbase to the given coordinate.
  -- @return #number Distance to the closest airbase in meters.
  function COORDINATE:GetClosestAirbase(Category, Coalition)

    -- Get all airbases of the map.
    local airbases=AIRBASE.GetAllAirbases(Coalition)

    local closest=nil
    local distmin=nil
    -- Loop over all airbases.
    for _,_airbase in pairs(airbases) do
      local airbase=_airbase --Wrapper.Airbase#AIRBASE
      if airbase then
        local category=airbase:GetAirbaseCategory()
        if Category and Category==category or Category==nil then

          -- Distance to airbase.
          local dist=self:Get2DDistance(airbase:GetCoordinate())

          if closest==nil then
            distmin=dist
            closest=airbase
          else
            if dist<distmin then
              distmin=dist
              closest=airbase
            end
          end

        end
      end
    end

    return closest,distmin
  end

  --- [kept for downwards compatibility only] Gets the nearest airbase with respect to the current coordinates.
  -- @param #COORDINATE self
  -- @param #number Category (Optional) Category of the airbase. Enumerator of @{Wrapper.Airbase#AIRBASE.Category}.
  -- @param #number Coalition (Optional) Coalition of the airbase.
  -- @return Wrapper.Airbase#AIRBASE Closest Airbase to the given coordinate.
  -- @return #number Distance to the closest airbase in meters.
  function COORDINATE:GetClosestAirbase2(Category, Coalition)
    local closest, distmin = self:GetClosestAirbase(Category, Coalition)
    return closest, distmin 
  end

  --- Gets the nearest parking spot.
  -- @param #COORDINATE self
  -- @param Wrapper.Airbase#AIRBASE airbase (Optional) Search only parking spots at this airbase.
  -- @param Wrapper.Airbase#Terminaltype terminaltype (Optional) Type of the terminal. Default any execpt valid spawn points on runway.
  -- @param #boolean free (Optional) If true, returns the closest free spot. If false, returns the closest occupied spot. If nil, returns the closest spot regardless of free or occupied.
  -- @return Core.Point#COORDINATE Coordinate of the nearest parking spot.
  -- @return #number Terminal ID.
  -- @return #number Distance to closest parking spot in meters.
  -- @return Wrapper.Airbase#AIRBASE#ParkingSpot Parking spot table.
  function COORDINATE:GetClosestParkingSpot(airbase, terminaltype, free)

    -- Get airbase table.
    local airbases={}
    if airbase then
      table.insert(airbases,airbase)
    else
      airbases=AIRBASE.GetAllAirbases()
    end

    -- Init.
    local _closest=nil --Core.Point#COORDINATE
    local _termID=nil
    local _distmin=nil
    local spot=nil --Wrapper.Airbase#AIRBASE.ParkingSpot

    -- Loop over all airbases.
    for _,_airbase in pairs(airbases) do

      local mybase=_airbase --Wrapper.Airbase#AIRBASE
      local parkingdata=mybase:GetParkingSpotsTable(terminaltype)

      for _,_spot in pairs(parkingdata) do

        -- Check for parameters.
        if (free==true and _spot.Free==true) or (free==false and _spot.Free==false) or free==nil then

          local _coord=_spot.Coordinate --Core.Point#COORDINATE

          local _dist=self:Get2DDistance(_coord)
          if _distmin==nil then
            _closest=_coord
            _distmin=_dist
            _termID=_spot.TerminalID
            spot=_spot
          else
            if _dist<_distmin then
              _distmin=_dist
              _closest=_coord
              _termID=_spot.TerminalID
              spot=_spot
            end
          end

        end
      end
    end

    return _closest, _termID, _distmin, spot
  end

  --- Gets the nearest free parking spot.
  -- @param #COORDINATE self
  -- @param Wrapper.Airbase#AIRBASE airbase (Optional) Search only parking spots at that airbase.
  -- @param Wrapper.Airbase#Terminaltype terminaltype (Optional) Type of the terminal.
  -- @return #COORDINATE Coordinate of the nearest free parking spot.
  -- @return #number Terminal ID.
  -- @return #number Distance to closest free parking spot in meters.
  function COORDINATE:GetClosestFreeParkingSpot(airbase, terminaltype)
    return self:GetClosestParkingSpot(airbase, terminaltype, true)
  end

  --- Gets the nearest occupied parking spot.
  -- @param #COORDINATE self
  -- @param Wrapper.Airbase#AIRBASE airbase (Optional) Search only parking spots at that airbase.
  -- @param Wrapper.Airbase#Terminaltype terminaltype (Optional) Type of the terminal.
  -- @return #COORDINATE Coordinate of the nearest occupied parking spot.
  -- @return #number Terminal ID.
  -- @return #number Distance to closest occupied parking spot in meters.
  function COORDINATE:GetClosestOccupiedParkingSpot(airbase, terminaltype)
    return self:GetClosestParkingSpot(airbase, terminaltype, false)
  end

  --- Gets the nearest coordinate to a road (or railroad).
  -- @param #COORDINATE self
  -- @param #boolean Railroad (Optional) If true, closest point to railroad is returned rather than closest point to conventional road. Default false.
  -- @return #COORDINATE Coordinate of the nearest road.
  function COORDINATE:GetClosestPointToRoad(Railroad)
    local roadtype="roads"
    if Railroad==true then
      roadtype="railroads"
    end
    local x,y = land.getClosestPointOnRoads(roadtype, self.x, self.z)
    local coord=nil
    if x and y then
      local vec2={ x = x, y = y }
      coord=COORDINATE:NewFromVec2(vec2)
    end
    return coord
  end


  --- Returns a table of coordinates to a destination using only roads or railroads.
  -- The first point is the closest point on road of the given coordinate.
  -- By default, the last point is the closest point on road of the ToCoord. Hence, the coordinate itself and the final ToCoord are not necessarily included in the path.
  -- @param #COORDINATE self
  -- @param #COORDINATE ToCoord Coordinate of destination.
  -- @param #boolean IncludeEndpoints (Optional) Include the coordinate itself and the ToCoordinate in the path.
  -- @param #boolean Railroad (Optional) If true, path on railroad is returned. Default false.
  -- @param #boolean MarkPath (Optional) If true, place markers on F10 map along the path.
  -- @param #boolean SmokePath (Optional) If true, put (green) smoke along the
  -- @return #table Table of coordinates on road. If no path on road can be found, nil is returned or just the endpoints.
  -- @return #number Tonal length of path.
  -- @return #boolean If true a valid path on road/rail was found. If false, only the direct way is possible.
  function COORDINATE:GetPathOnRoad(ToCoord, IncludeEndpoints, Railroad, MarkPath, SmokePath)

    -- Set road type.
    local RoadType="roads"
    if Railroad==true then
      RoadType="railroads"
    end

    -- DCS API function returning a table of vec2.
    local path = land.findPathOnRoads(RoadType, self.x, self.z, ToCoord.x, ToCoord.z)

    -- Array holding the path coordinates.
    local Path={}
    local Way=0

    -- Include currrent position.
    if IncludeEndpoints then
      Path[1]=self
    end

    -- Assume we could get a valid path.
    local GotPath=true

    -- Check that DCS routine actually returned a path. There are situations where this is not the case.
    if path then

      -- Include all points on road.
      for _i,_vec2 in ipairs(path) do

        local coord=COORDINATE:NewFromVec2(_vec2)

        Path[#Path+1]=coord
      end

    else
      self:E("Path is nil. No valid path on road could be found.")
      GotPath=false
    end

    -- Include end point, which might not be on road.
    if IncludeEndpoints then
      Path[#Path+1]=ToCoord
    end

    -- Mark or smoke.
    if MarkPath or SmokePath then
      for i,c in pairs(Path) do
        local coord=c --#COORDINATE
        if MarkPath then
          coord:MarkToAll(string.format("Path segment %d", i))
        end
        if SmokePath then
          if i==1 or i==#Path then
            coord:SmokeBlue()
          else
            coord:SmokeGreen()
          end
        end
      end
    end

    -- Sum up distances.
    if #Path>=2 then
      for i=1,#Path-1 do
        Way=Way+Path[i+1]:Get2DDistance(Path[i])
      end
    else
      -- There are cases where no path on road can be found.
      return nil,nil,false
    end

    return Path, Way, GotPath
  end

  --- Gets the surface type at the coordinate.
  -- @param #COORDINATE self
  -- @return DCS#SurfaceType Surface type.
  function COORDINATE:GetSurfaceType()
    local vec2=self:GetVec2()
    local surface=land.getSurfaceType(vec2)
    return surface
  end

  --- Checks if the surface type is on land.
  -- @param #COORDINATE self
  -- @return #boolean If true, the surface type at the coordinate is land.
  function COORDINATE:IsSurfaceTypeLand()
    return self:GetSurfaceType()==land.SurfaceType.LAND
  end

  --- Checks if the surface type is land.
  -- @param #COORDINATE self
  -- @return #boolean If true, the surface type at the coordinate is land.
  function COORDINATE:IsSurfaceTypeLand()
    return self:GetSurfaceType()==land.SurfaceType.LAND
  end


  --- Checks if the surface type is road.
  -- @param #COORDINATE self
  -- @return #boolean If true, the surface type at the coordinate is a road.
  function COORDINATE:IsSurfaceTypeRoad()
    return self:GetSurfaceType()==land.SurfaceType.ROAD
  end

  --- Checks if the surface type is runway.
  -- @param #COORDINATE self
  -- @return #boolean If true, the surface type at the coordinate is a runway or taxi way.
  function COORDINATE:IsSurfaceTypeRunway()
    return self:GetSurfaceType()==land.SurfaceType.RUNWAY
  end

  --- Checks if the surface type is shallow water.
  -- @param #COORDINATE self
  -- @return #boolean If true, the surface type at the coordinate is a shallow water.
  function COORDINATE:IsSurfaceTypeShallowWater()
    return self:GetSurfaceType()==land.SurfaceType.SHALLOW_WATER
  end

  --- Checks if the surface type is water.
  -- @param #COORDINATE self
  -- @return #boolean If true, the surface type at the coordinate is a deep water.
  function COORDINATE:IsSurfaceTypeWater()
    return self:GetSurfaceType()==land.SurfaceType.WATER
  end


  --- Creates an explosion at the point of a certain intensity.
  -- @param #COORDINATE self
  -- @param #number ExplosionIntensity Intensity of the explosion in kg TNT. Default 100 kg.
  -- @param #number Delay (Optional) Delay before explosion is triggered in seconds.
  -- @return #COORDINATE self
  function COORDINATE:Explosion( ExplosionIntensity, Delay )
    ExplosionIntensity=ExplosionIntensity or 100
    if Delay and Delay>0 then
      self:ScheduleOnce(Delay, self.Explosion, self, ExplosionIntensity)
    else
      trigger.action.explosion(self:GetVec3(), ExplosionIntensity)
    end
    return self
  end

  --- Creates an illumination bomb at the point.
  -- @param #COORDINATE self
  -- @param #number Power Power of illumination bomb in Candela. Default 1000 cd.
  -- @param #number Delay (Optional) Delay before bomb is ignited in seconds.
  -- @return #COORDINATE self
  function COORDINATE:IlluminationBomb(Power, Delay)
    Power=Power or 1000
    if Delay and Delay>0 then
      self:ScheduleOnce(Delay, self.IlluminationBomb, self, Power)
    else
      trigger.action.illuminationBomb(self:GetVec3(), Power)
    end
    return self
  end


  --- Smokes the point in a color.
  -- @param #COORDINATE self
  -- @param Utilities.Utils#SMOKECOLOR SmokeColor
  -- @param #string name (Optional) Name if you want to stop the smoke early (normal duration: 5mins)
  function COORDINATE:Smoke( SmokeColor, name )
    self:F2( { SmokeColor } )
    self.firename = name or "Smoke-"..math.random(1,100000)
    trigger.action.smoke( self:GetVec3(), SmokeColor, self.firename )
  end

  --- Stops smoking the point in a color.
  -- @param #COORDINATE self
  -- @param #string name (Optional) Name if you want to stop the smoke early (normal duration: 5mins)
  function COORDINATE:StopSmoke( name )
    self:StopBigSmokeAndFire( name )
  end

  --- Smoke the COORDINATE Green.
  -- @param #COORDINATE self
  function COORDINATE:SmokeGreen()
    self:F2()
    self:Smoke( SMOKECOLOR.Green )
  end

  --- Smoke the COORDINATE Red.
  -- @param #COORDINATE self
  function COORDINATE:SmokeRed()
    self:F2()
    self:Smoke( SMOKECOLOR.Red )
  end

  --- Smoke the COORDINATE White.
  -- @param #COORDINATE self
  function COORDINATE:SmokeWhite()
    self:F2()
    self:Smoke( SMOKECOLOR.White )
  end

  --- Smoke the COORDINATE Orange.
  -- @param #COORDINATE self
  function COORDINATE:SmokeOrange()
    self:F2()
    self:Smoke( SMOKECOLOR.Orange )
  end

  --- Smoke the COORDINATE Blue.
  -- @param #COORDINATE self
  function COORDINATE:SmokeBlue()
    self:F2()
    self:Smoke( SMOKECOLOR.Blue )
  end

  --- Big smoke and fire at the coordinate.
  -- @param #COORDINATE self
  -- @param Utilities.Utils#BIGSMOKEPRESET preset Smoke preset (1=small smoke and fire, 2=medium smoke and fire, 3=large smoke and fire, 4=huge smoke and fire, 5=small smoke, 6=medium smoke, 7=large smoke, 8=huge smoke).
  -- @param #number density (Optional) Smoke density. Number in [0,...,1]. Default 0.5.
  -- @param #string name (Optional) Name of the fire to stop it later again if not using the same COORDINATE object. Defaults to "Fire-" plus a random 5-digit-number.
  function COORDINATE:BigSmokeAndFire( preset, density, name )
    self:F2( { preset=preset, density=density } )
    density=density or 0.5
    self.firename = name or "Fire-"..math.random(1,10000)
    trigger.action.effectSmokeBig( self:GetVec3(), preset, density, self.firename )
  end
  
  --- Stop big smoke and fire at the coordinate.
  -- @param #COORDINATE self
  -- @param #string name (Optional) Name of the fire to stop it, if not using the same COORDINATE object.
  function COORDINATE:StopBigSmokeAndFire( name )
    name = name or self.firename
    trigger.action.effectSmokeStop( name )
  end

  --- Small smoke and fire at the coordinate.
  -- @param #COORDINATE self
  -- @param #number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  -- @param #string name (Optional) Name of the fire to stop it later again if not using the same COORDINATE object. Defaults to "Fire-" plus a random 5-digit-number.
  function COORDINATE:BigSmokeAndFireSmall( density, name )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.SmallSmokeAndFire, density, name)
  end

  --- Medium smoke and fire at the coordinate.
  -- @param #COORDINATE self
  -- @param #number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  -- @param #string name (Optional) Name of the fire to stop it later again if not using the same COORDINATE object. Defaults to "Fire-" plus a random 5-digit-number.
  function COORDINATE:BigSmokeAndFireMedium( density, name )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.MediumSmokeAndFire, density, name)
  end

  --- Large smoke and fire at the coordinate.
  -- @param #COORDINATE self
  -- @param #number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  -- @param #string name (Optional) Name of the fire to stop it later again if not using the same COORDINATE object. Defaults to "Fire-" plus a random 5-digit-number.
  function COORDINATE:BigSmokeAndFireLarge( density, name )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.LargeSmokeAndFire, density, name)
  end

  --- Huge smoke and fire at the coordinate.
  -- @param #COORDINATE self
  -- @param #number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  -- @param #string name (Optional) Name of the fire to stop it later again if not using the same COORDINATE object. Defaults to "Fire-" plus a random 5-digit-number.
  function COORDINATE:BigSmokeAndFireHuge( density, name )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.HugeSmokeAndFire, density, name)
  end

  --- Small smoke at the coordinate.
  -- @param #COORDINATE self
  -- @param #number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  -- @param #string name (Optional) Name of the fire to stop it later again if not using the same COORDINATE object. Defaults to "Fire-" plus a random 5-digit-number.
  function COORDINATE:BigSmokeSmall( density, name )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.SmallSmoke, density, name)
  end

  --- Medium smoke at the coordinate.
  -- @param #COORDINATE self
  -- @param number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  -- @param #string name (Optional) Name of the fire to stop it later again if not using the same COORDINATE object. Defaults to "Fire-" plus a random 5-digit-number.
  function COORDINATE:BigSmokeMedium( density, name )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.MediumSmoke, density, name)
  end

  --- Large smoke at the coordinate.
  -- @param #COORDINATE self
  -- @param #number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  -- @param #string name (Optional) Name of the fire to stop it later again if not using the same COORDINATE object. Defaults to "Fire-" plus a random 5-digit-number.
  function COORDINATE:BigSmokeLarge( density, name )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.LargeSmoke, density,name)
  end

  --- Huge smoke at the coordinate.
  -- @param #COORDINATE self
  -- @param #number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  -- @param #string name (Optional) Name of the fire to stop it later again if not using the same COORDINATE object. Defaults to "Fire-" plus a random 5-digit-number.
  function COORDINATE:BigSmokeHuge( density, name )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.HugeSmoke, density,name)
  end

  --- Flares the point in a color.
  -- @param #COORDINATE self
  -- @param Utilities.Utils#FLARECOLOR FlareColor
  -- @param DCS#Azimuth Azimuth (optional) The azimuth of the flare direction. The default azimuth is 0.
  function COORDINATE:Flare( FlareColor, Azimuth )
    self:F2( { FlareColor } )
    trigger.action.signalFlare( self:GetVec3(), FlareColor, Azimuth and Azimuth or 0 )
  end

  --- Flare the COORDINATE White.
  -- @param #COORDINATE self
  -- @param DCS#Azimuth Azimuth (optional) The azimuth of the flare direction. The default azimuth is 0.
  function COORDINATE:FlareWhite( Azimuth )
    self:F2( Azimuth )
    self:Flare( FLARECOLOR.White, Azimuth )
  end

  --- Flare the COORDINATE Yellow.
  -- @param #COORDINATE self
  -- @param DCS#Azimuth Azimuth (optional) The azimuth of the flare direction. The default azimuth is 0.
  function COORDINATE:FlareYellow( Azimuth )
    self:F2( Azimuth )
    self:Flare( FLARECOLOR.Yellow, Azimuth )
  end

  --- Flare the COORDINATE Green.
  -- @param #COORDINATE self
  -- @param DCS#Azimuth Azimuth (optional) The azimuth of the flare direction. The default azimuth is 0.
  function COORDINATE:FlareGreen( Azimuth )
    self:F2( Azimuth )
    self:Flare( FLARECOLOR.Green, Azimuth )
  end

  --- Flare the COORDINATE Red.
  -- @param #COORDINATE self
  function COORDINATE:FlareRed( Azimuth )
    self:F2( Azimuth )
    self:Flare( FLARECOLOR.Red, Azimuth )
  end

  do -- Markings

    --- Mark to All
    -- @param #COORDINATE self
    -- @param #string MarkText Free format text that shows the marking clarification.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID which is a number.
    -- @usage
    --   local TargetCoord = TargetGroup:GetCoordinate()
    --   local MarkID = TargetCoord:MarkToAll( "This is a target for all players" )
    function COORDINATE:MarkToAll( MarkText, ReadOnly, Text )
      local MarkID = UTILS.GetMarkID()
      if ReadOnly==nil then
        ReadOnly=false
      end
      local text=Text or ""
      trigger.action.markToAll( MarkID, MarkText, self:GetVec3(), ReadOnly, text)
      return MarkID
    end

    --- Mark to Coalition
    -- @param #COORDINATE self
    -- @param #string MarkText Free format text that shows the marking clarification.
    -- @param Coalition
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID which is a number.
    -- @usage
    --   local TargetCoord = TargetGroup:GetCoordinate()
    --   local MarkID = TargetCoord:MarkToCoalition( "This is a target for the red coalition", coalition.side.RED )
    function COORDINATE:MarkToCoalition( MarkText, Coalition, ReadOnly, Text )
      local MarkID = UTILS.GetMarkID()
      if ReadOnly==nil then
        ReadOnly=false
      end
      local text=Text or ""
      trigger.action.markToCoalition( MarkID, MarkText, self:GetVec3(), Coalition, ReadOnly, text )
      return MarkID
    end

    --- Mark to Red Coalition
    -- @param #COORDINATE self
    -- @param #string MarkText Free format text that shows the marking clarification.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID which is a number.
    -- @usage
    --   local TargetCoord = TargetGroup:GetCoordinate()
    --   local MarkID = TargetCoord:MarkToCoalitionRed( "This is a target for the red coalition" )
    function COORDINATE:MarkToCoalitionRed( MarkText, ReadOnly, Text )
      return self:MarkToCoalition( MarkText, coalition.side.RED, ReadOnly, Text )
    end

    --- Mark to Blue Coalition
    -- @param #COORDINATE self
    -- @param #string MarkText Free format text that shows the marking clarification.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID which is a number.
    -- @usage
    --   local TargetCoord = TargetGroup:GetCoordinate()
    --   local MarkID = TargetCoord:MarkToCoalitionBlue( "This is a target for the blue coalition" )
    function COORDINATE:MarkToCoalitionBlue( MarkText, ReadOnly, Text )
      return self:MarkToCoalition( MarkText, coalition.side.BLUE, ReadOnly, Text )
    end

    --- Mark to Group
    -- @param #COORDINATE self
    -- @param #string MarkText Free format text that shows the marking clarification.
    -- @param Wrapper.Group#GROUP MarkGroup The @{Wrapper.Group} that receives the mark.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID which is a number.
    -- @usage
    --   local TargetCoord = TargetGroup:GetCoordinate()
    --   local MarkGroup = GROUP:FindByName( "AttackGroup" )
    --   local MarkID = TargetCoord:MarkToGroup( "This is a target for the attack group", AttackGroup )
    function COORDINATE:MarkToGroup( MarkText, MarkGroup, ReadOnly, Text )
      local MarkID = UTILS.GetMarkID()
      if ReadOnly==nil then
        ReadOnly=false
      end
      local text=Text or ""
      trigger.action.markToGroup( MarkID, MarkText, self:GetVec3(), MarkGroup:GetID(), ReadOnly, text )
      return MarkID
    end

    --- Remove a mark
    -- @param #COORDINATE self
    -- @param #number MarkID The ID of the mark to be removed.
    -- @usage
    --   local TargetCoord = TargetGroup:GetCoordinate()
    --   local MarkGroup = GROUP:FindByName( "AttackGroup" )
    --   local MarkID = TargetCoord:MarkToGroup( "This is a target for the attack group", AttackGroup )
    --   <<< logic >>>
    --   TargetCoord:RemoveMark( MarkID ) -- The mark is now removed
    function COORDINATE:RemoveMark( MarkID )
      trigger.action.removeMark( MarkID )
    end

    --- Line to all.
    -- Creates a line on the F10 map from one point to another.
    -- @param #COORDINATE self
    -- @param #COORDINATE Endpoint COORDINATE to where the line is drawn.
    -- @param #number Coalition Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1=All.
    -- @param #table Color RGB color table {r, g, b}, e.g. {1,0,0} for red (default).
    -- @param #number Alpha Transparency [0,1]. Default 1.
    -- @param #number LineType Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 1=Solid.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID, which is a number. Can be used to remove the object again.
    function COORDINATE:LineToAll(Endpoint, Coalition, Color, Alpha, LineType, ReadOnly, Text)
      local MarkID = UTILS.GetMarkID()
      if ReadOnly==nil then
        ReadOnly=false
      end
      local vec3=Endpoint:GetVec3()
      Coalition=Coalition or -1
      Color=Color or {1,0,0}
      Color[4]=Alpha or 1.0
      LineType=LineType or 1
      trigger.action.lineToAll(Coalition, MarkID, self:GetVec3(), vec3, Color, LineType, ReadOnly, Text or "")
      return MarkID
    end

    --- Circle to all.
    -- Creates a circle on the map with a given radius, color, fill color, and outline.
    -- @param #COORDINATE self
    -- @param #number Radius Radius in meters. Default 1000 m.
    -- @param #number Coalition Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1=All.
    -- @param #table Color RGB color table {r, g, b}, e.g. {1,0,0} for red (default).
    -- @param #number Alpha Transparency [0,1]. Default 1.
    -- @param #table FillColor RGB color table {r, g, b}, e.g. {1,0,0} for red. Default is same as `Color` value.
    -- @param #number FillAlpha Transparency [0,1]. Default 0.15.
    -- @param #number LineType Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 1=Solid.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID, which is a number. Can be used to remove the object again.
    function COORDINATE:CircleToAll(Radius, Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly, Text)
      local MarkID = UTILS.GetMarkID()
      if ReadOnly==nil then
        ReadOnly=false
      end
      
      local vec3=self:GetVec3()
      
      Radius=Radius or 1000
      
      Coalition=Coalition or -1
      
      Color=Color or {1,0,0}
      Color[4]=Alpha or 1.0
      
      LineType=LineType or 1
      
      FillColor=FillColor or UTILS.DeepCopy(Color)
      FillColor[4]=FillAlpha or 0.15
      
      trigger.action.circleToAll(Coalition, MarkID, vec3, Radius, Color, FillColor, LineType, ReadOnly, Text or "")
      return MarkID
    end

  end -- Markings

    --- Rectangle to all. Creates a rectangle on the map from the COORDINATE in one corner to the end COORDINATE in the opposite corner.
    -- Creates a line on the F10 map from one point to another.
    -- @param #COORDINATE self
    -- @param #COORDINATE Endpoint COORDINATE in the opposite corner.
    -- @param #number Coalition Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1=All.
    -- @param #table Color RGB color table {r, g, b}, e.g. {1,0,0} for red (default).
    -- @param #number Alpha Transparency [0,1]. Default 1.
    -- @param #table FillColor RGB color table {r, g, b}, e.g. {1,0,0} for red. Default is same as `Color` value.
    -- @param #number FillAlpha Transparency [0,1]. Default 0.15.
    -- @param #number LineType Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 1=Solid.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID, which is a number. Can be used to remove the object again.
    function COORDINATE:RectToAll(Endpoint, Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly, Text)
      local MarkID = UTILS.GetMarkID()
      if ReadOnly==nil then
        ReadOnly=false
      end
      
      local vec3=Endpoint:GetVec3()
      
      Coalition=Coalition or -1
      
      Color=Color or {1,0,0}
      Color[4]=Alpha or 1.0
      
      LineType=LineType or 1
      
      FillColor=FillColor or UTILS.DeepCopy(Color)
      FillColor[4]=FillAlpha or 0.15
      
      trigger.action.rectToAll(Coalition, MarkID, self:GetVec3(), vec3, Color, FillColor, LineType, ReadOnly, Text or "")
      return MarkID
    end

    --- Creates a shape defined by 4 points on the F10 map. The first point is the current COORDINATE. The remaining three points need to be specified.
    -- @param #COORDINATE self
    -- @param #COORDINATE Coord2 Second COORDINATE of the quad shape.
    -- @param #COORDINATE Coord3 Third COORDINATE of the quad shape.
    -- @param #COORDINATE Coord4 Fourth COORDINATE of the quad shape.
    -- @param #number Coalition Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1=All.
    -- @param #table Color RGB color table {r, g, b}, e.g. {1,0,0} for red (default).
    -- @param #number Alpha Transparency [0,1]. Default 1.
    -- @param #table FillColor RGB color table {r, g, b}, e.g. {1,0,0} for red. Default is same as `Color` value.
    -- @param #number FillAlpha Transparency [0,1]. Default 0.15.
    -- @param #number LineType Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 1=Solid.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID, which is a number. Can be used to remove the object again.
    function COORDINATE:QuadToAll(Coord2, Coord3, Coord4, Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly, Text)
      local MarkID = UTILS.GetMarkID()
      if ReadOnly==nil then
        ReadOnly=false
      end
      
      local point1=self:GetVec3()
      local point2=Coord2:GetVec3()
      local point3=Coord3:GetVec3()
      local point4=Coord4:GetVec3()
      
      Coalition=Coalition or -1
      
      Color=Color or {1,0,0}
      Color[4]=Alpha or 1.0
      
      LineType=LineType or 1
      
      FillColor=FillColor or UTILS.DeepCopy(Color)
      FillColor[4]=FillAlpha or 0.15
      
      trigger.action.quadToAll(Coalition, MarkID, point1, point2, point3, point4, Color, FillColor, LineType, ReadOnly, Text or "")
      return MarkID
    end

    --- Creates a free form shape on the F10 map. The first point is the current COORDINATE. The remaining points need to be specified.
    -- @param #COORDINATE self
    -- @param #table Coordinates Table of coordinates of the remaining points of the shape.
    -- @param #number Coalition Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1=All.
    -- @param #table Color RGB color table {r, g, b}, e.g. {1,0,0} for red (default).
    -- @param #number Alpha Transparency [0,1]. Default 1.
    -- @param #table FillColor RGB color table {r, g, b}, e.g. {1,0,0} for red. Default is same as `Color` value.
    -- @param #number FillAlpha Transparency [0,1]. Default 0.15.
    -- @param #number LineType Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 1=Solid.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID, which is a number. Can be used to remove the object again.
    function COORDINATE:MarkupToAllFreeForm(Coordinates, Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly, Text)

      local MarkID = UTILS.GetMarkID()
      if ReadOnly==nil then
        ReadOnly=false
      end

      Coalition=Coalition or -1

      Color=Color or {1,0,0}
      Color[4]=Alpha or 1.0

      LineType=LineType or 1

      FillColor=FillColor or UTILS.DeepCopy(Color)
      FillColor[4]=FillAlpha or 0.15

      local vecs={}
      vecs[1]=self:GetVec3()
      for i,coord in ipairs(Coordinates) do
        vecs[i+1]=coord:GetVec3()
      end
      
      if #vecs<3 then
        self:E("ERROR: A free form polygon needs at least three points!")
      elseif #vecs==3 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], Color, FillColor, LineType, ReadOnly, Text or "")
      elseif #vecs==4 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], Color, FillColor, LineType, ReadOnly, Text or "")
      elseif #vecs==5 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], Color, FillColor, LineType, ReadOnly, Text or "")
      elseif #vecs==6 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], vecs[6], Color, FillColor, LineType, ReadOnly, Text or "")
      elseif #vecs==7 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], vecs[6], vecs[7], Color, FillColor, LineType, ReadOnly, Text or "")
      elseif #vecs==8 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], vecs[6], vecs[7], vecs[8], Color, FillColor, LineType, ReadOnly, Text or "")
      elseif #vecs==9 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], vecs[6], vecs[7], vecs[8], vecs[9], Color, FillColor, LineType, ReadOnly, Text or "")
      elseif #vecs==10 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], vecs[6], vecs[7], vecs[8], vecs[9], vecs[10], Color, FillColor, LineType, ReadOnly, Text or "")
      elseif #vecs==11 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], vecs[6], vecs[7], vecs[8], vecs[9], vecs[10],
                                                         vecs[11], 
                                                         Color, FillColor, LineType, ReadOnly, Text or "")        
      elseif #vecs==12 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], vecs[6], vecs[7], vecs[8], vecs[9], vecs[10],
                                                         vecs[11], vecs[12],
                                                         Color, FillColor, LineType, ReadOnly, Text or "")
      elseif #vecs==13 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], vecs[6], vecs[7], vecs[8], vecs[9], vecs[10],
                                                         vecs[11], vecs[12], vecs[13],
                                                         Color, FillColor, LineType, ReadOnly, Text or "")
      elseif #vecs==14 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], vecs[6], vecs[7], vecs[8], vecs[9], vecs[10],
                                                         vecs[11], vecs[12], vecs[13], vecs[14],
                                                         Color, FillColor, LineType, ReadOnly, Text or "")                                                                                                                                                                                                           
      elseif #vecs==15 then
        trigger.action.markupToAll(7, Coalition, MarkID, vecs[1], vecs[2], vecs[3], vecs[4], vecs[5], vecs[6], vecs[7], vecs[8], vecs[9], vecs[10],
                                                         vecs[11], vecs[12], vecs[13], vecs[14], vecs[15],
                                                         Color, FillColor, LineType, ReadOnly, Text or "")
      else
        
        -- Unfortunately, unpack(vecs) does not work! So no idea how to generalize this :(
        --trigger.action.markupToAll(7, Coalition, MarkID, unpack(vecs), Color, FillColor, LineType, ReadOnly, Text or "")
        
        -- Write command as string and execute that. Idea by Grimes https://forum.dcs.world/topic/324201-mark-to-all-function/#comment-5273793
        local s=string.format("trigger.action.markupToAll(7, %d, %d,", Coalition, MarkID)
        for _,vec in pairs(vecs) do
          --s=s..string.format("%s,", UTILS._OneLineSerialize(vec))
          s=s..string.format("{x=%.1f, y=%.1f, z=%.1f},", vec.x, vec.y, vec.z)
        end
        s=s..string.format("{%.3f, %.3f, %.3f, %.3f},", Color[1], Color[2], Color[3], Color[4])
        s=s..string.format("{%.3f, %.3f, %.3f, %.3f},", FillColor[1], FillColor[2], FillColor[3], FillColor[4])
        s=s..string.format("%d,", LineType or 1)
        s=s..string.format("%s", tostring(ReadOnly))
        if Text and type(Text)=="string" and string.len(Text)>0 then
          s=s..string.format(", \"%s\"", tostring(Text))
        end
        s=s..")"
        
        -- Execute string command
        local success=UTILS.DoString(s)
                
        if not success then
          self:E("ERROR: Could not draw polygon")
          env.info(s)
        end
        
      end

      return MarkID
    end

    --- Text to all. Creates a text imposed on the map at the COORDINATE. Text scales with the map.
    -- @param #COORDINATE self
    -- @param #string Text Text displayed on the F10 map.
    -- @param #number Coalition Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1=All.
    -- @param #table Color RGB color table {r, g, b}, e.g. {1,0,0} for red (default).
    -- @param #number Alpha Transparency [0,1]. Default 1.
    -- @param #table FillColor RGB color table {r, g, b}, e.g. {1,0,0} for red. Default is same as `Color` value.
    -- @param #number FillAlpha Transparency [0,1]. Default 0.3.
    -- @param #number FontSize Font size. Default 14.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @return #number The resulting Mark ID, which is a number. Can be used to remove the object again.
    function COORDINATE:TextToAll(Text, Coalition, Color, Alpha, FillColor, FillAlpha, FontSize, ReadOnly)
      local MarkID = UTILS.GetMarkID()
      if ReadOnly==nil then
        ReadOnly=false
      end
      Coalition=Coalition or -1
      
      Color=Color or {1,0,0}
      Color[4]=Alpha or 1.0
      
      FillColor=FillColor or UTILS.DeepCopy(Color)
      FillColor[4]=FillAlpha or 0.3
      
      FontSize=FontSize or 14
      
      trigger.action.textToAll(Coalition, MarkID, self:GetVec3(), Color, FillColor, FontSize, ReadOnly, Text or "Hello World")
      return MarkID
    end

    --- Arrow to all. Creates an arrow from the COORDINATE to the endpoint COORDINATE on the F10 map. There is no control over other dimensions of the arrow.
    -- @param #COORDINATE self
    -- @param #COORDINATE Endpoint COORDINATE where the tip of the arrow is pointing at.
    -- @param #number Coalition Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1=All.
    -- @param #table Color RGB color table {r, g, b}, e.g. {1,0,0} for red (default).
    -- @param #number Alpha Transparency [0,1]. Default 1.
    -- @param #table FillColor RGB color table {r, g, b}, e.g. {1,0,0} for red. Default is same as `Color` value.
    -- @param #number FillAlpha Transparency [0,1]. Default 0.15.
    -- @param #number LineType Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 1=Solid.
    -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
    -- @param #string Text (Optional) Text displayed when mark is added. Default none.
    -- @return #number The resulting Mark ID, which is a number. Can be used to remove the object again.
    function COORDINATE:ArrowToAll(Endpoint, Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly, Text)
      local MarkID = UTILS.GetMarkID()
      if ReadOnly==nil then
        ReadOnly=false
      end
      
      local vec3=Endpoint:GetVec3()
      
      Coalition=Coalition or -1
      
      Color=Color or {1,0,0}
      Color[4]=Alpha or 1.0
      
      LineType=LineType or 1
      
      FillColor=FillColor or UTILS.DeepCopy(Color)
      FillColor[4]=FillAlpha or 0.15
      
      --trigger.action.textToAll(Coalition, MarkID, self:GetVec3(), Color, FillColor, FontSize, ReadOnly, Text or "Hello World")
      trigger.action.arrowToAll(Coalition, MarkID, vec3, self:GetVec3(), Color, FillColor, LineType, ReadOnly, Text or "")
      return MarkID
    end

  --- Returns if a Coordinate has Line of Sight (LOS) with the ToCoordinate.
  -- @param #COORDINATE self
  -- @param #COORDINATE ToCoordinate
  -- @param #number Offset Height offset in meters. Default 2 m.
  -- @return #boolean true If the ToCoordinate has LOS with the Coordinate, otherwise false.
  function COORDINATE:IsLOS( ToCoordinate, Offset )

    Offset=Offset or 2

    -- Measurement of visibility should not be from the ground, so Adding a hypothetical 2 meters to each Coordinate.
    local FromVec3 = self:GetVec3()
    FromVec3.y = FromVec3.y + Offset

    local ToVec3 = ToCoordinate:GetVec3()
    ToVec3.y = ToVec3.y + Offset

    local IsLOS = land.isVisible( FromVec3, ToVec3 )

    return IsLOS
  end


  --- Returns if a Coordinate is in a certain Radius of this Coordinate in 2D plane using the X and Z axis.
  -- @param #COORDINATE self
  -- @param #COORDINATE Coordinate The coordinate that will be tested if it is in the radius of this coordinate.
  -- @param #number Radius The radius of the circle on the 2D plane around this coordinate.
  -- @return #boolean true if in the Radius.
  function COORDINATE:IsInRadius( Coordinate, Radius )

    local InVec2 = self:GetVec2()
    local Vec2 = Coordinate:GetVec2()

    local InRadius = UTILS.IsInRadius( InVec2, Vec2, Radius)

    return InRadius
  end


  --- Returns if a Coordinate is in a certain radius of this Coordinate in 3D space using the X, Y and Z axis.
  -- So Radius defines the radius of the a Sphere in 3D space around this coordinate.
  -- @param #COORDINATE self
  -- @param #COORDINATE ToCoordinate The coordinate that will be tested if it is in the radius of this coordinate.
  -- @param #number Radius The radius of the sphere in the 3D space around this coordinate.
  -- @return #boolean true if in the Sphere.
  function COORDINATE:IsInSphere( Coordinate, Radius )

    local InVec3 = self:GetVec3()
    local Vec3 = Coordinate:GetVec3()

    local InSphere = UTILS.IsInSphere( InVec3, Vec3, Radius)

    return InSphere
  end

  --- Get sun rise time for a specific date at the coordinate.
  -- @param #COORDINATE self
  -- @param #number Day The day.
  -- @param #number Month The month.
  -- @param #number Year The year.
  -- @param #boolean InSeconds If true, return the sun rise time in seconds.
  -- @return #string Sunrise time, e.g. "05:41".
  function COORDINATE:GetSunriseAtDate(Day, Month, Year, InSeconds)

    -- Day of the year.
    local DayOfYear=UTILS.GetDayOfYear(Year, Month, Day)

    local Latitude, Longitude=self:GetLLDDM()

    local Tdiff=UTILS.GMTToLocalTimeDifference()

    local sunrise=UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, true, Tdiff)

    if InSeconds then
      return sunrise
    else
      return UTILS.SecondsToClock(sunrise, true)
    end

  end

  --- Get sun rise time for a specific day of the year at the coordinate.
  -- @param #COORDINATE self
  -- @param #number DayOfYear The day of the year.
  -- @param #boolean InSeconds If true, return the sun rise time in seconds.
  -- @return #string Sunrise time, e.g. "05:41".
  function COORDINATE:GetSunriseAtDayOfYear(DayOfYear, InSeconds)

    local Latitude, Longitude=self:GetLLDDM()

    local Tdiff=UTILS.GMTToLocalTimeDifference()

    local sunrise=UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, true, Tdiff)

    if InSeconds then
      return sunrise
    else
      return UTILS.SecondsToClock(sunrise, true)
    end

  end

  --- Get todays sun rise time.
  -- @param #COORDINATE self
  -- @param #boolean InSeconds If true, return the sun rise time in seconds.
  -- @return #string Sunrise time, e.g. "05:41".
  function COORDINATE:GetSunrise(InSeconds)

    -- Get current day of the year.
    local DayOfYear=UTILS.GetMissionDayOfYear()

    -- Lat and long at this point.
    local Latitude, Longitude=self:GetLLDDM()

    -- GMT time diff.
    local Tdiff=UTILS.GMTToLocalTimeDifference()

    -- Sunrise in seconds of the day.
    local sunrise=UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, true, Tdiff)

    local date=UTILS.GetDCSMissionDate()

    -- Debug output.
    --self:I(string.format("Sun rise at lat=%.3f long=%.3f on %s (DayOfYear=%d): %s (%s sec of the day) (GMT %d)", Latitude, Longitude, date, DayOfYear, tostring(UTILS.SecondsToClock(sunrise)), tonumber(sunrise) or "0", Tdiff))

    if InSeconds or type(sunrise) == "string" then
      return sunrise
    else
      return UTILS.SecondsToClock(sunrise, true)
    end

  end

  --- Get minutes until the next sun rise at this coordinate.
  -- @param #COORDINATE self
  -- @param OnlyToday If true, only calculate the sun rise of today. If sun has already risen, the time in negative minutes since sunrise is reported.
  -- @return #number Minutes to the next sunrise.
  function COORDINATE:GetMinutesToSunrise(OnlyToday)

    -- Seconds of today
    local time=UTILS.SecondsOfToday()

    -- Next Sunrise in seconds.
    local sunrise=nil

    -- Time to sunrise.
    local delta=nil

    if OnlyToday then

      ---
      -- Sunrise of today
      ---

      sunrise=self:GetSunrise(true)

      delta=sunrise-time

    else

      ---
      -- Sunrise of tomorrow
      ---

      -- Tomorrows day of the year.
      local DayOfYear=UTILS.GetMissionDayOfYear()+1

      local Latitude, Longitude=self:GetLLDDM()

      local Tdiff=UTILS.GMTToLocalTimeDifference()

      sunrise=UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, true, Tdiff)

      delta=sunrise+UTILS.SecondsToMidnight()

    end

    return delta/60
  end

  --- Check if it is day, i.e. if the sun has risen about the horizon at this coordinate.
  -- @param #COORDINATE self
  -- @param #string Clock (Optional) Time in format "HH:MM:SS+D", e.g. "05:40:00+3" to check if is day at 5:40 at third day after mission start. Default is to check right now.
  -- @return #boolean If true, it is day. If false, it is night time.
  function COORDINATE:IsDay(Clock)

    if Clock then

      local Time=UTILS.ClockToSeconds(Clock)

      local clock=UTILS.Split(Clock, "+")[1]

      -- Tomorrows day of the year.
      local DayOfYear=UTILS.GetMissionDayOfYear(Time)

      local Latitude, Longitude=self:GetLLDDM()

      local Tdiff=UTILS.GMTToLocalTimeDifference()

      local sunrise=UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, true, Tdiff)
      local sunset=UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, false, Tdiff)
      
      if sunrise == "N/R" then return false end
      if sunrise == "N/S" then return true end
      
      local time=UTILS.ClockToSeconds(clock)

      -- Check if time is between sunrise and sunset.
      if time>sunrise and time<=sunset then
        return true
      else
        return false
      end

    else

      -- Todays sun rise in sec.
      local sunrise=self:GetSunrise(true)

      -- Todays sun set in sec.
      local sunset=self:GetSunset(true)

      -- Seconds passed since midnight.
      local time=UTILS.SecondsOfToday()

      -- Check if time is between sunrise and sunset.
      if time>sunrise and time<=sunset then
        return true
      else
        return false
      end

    end

  end

  --- Check if it is night, i.e. if the sun has set below the horizon at this coordinate.
  -- @param #COORDINATE self
  -- @param #string Clock (Optional) Time in format "HH:MM:SS+D", e.g. "05:40:00+3" to check if is night at 5:40 at third day after mission start. Default is to check right now.
  -- @return #boolean If true, it is night. If false, it is day time.
  function COORDINATE:IsNight(Clock)
    return not self:IsDay(Clock)
  end

  --- Get sun set time for a specific date at the coordinate.
  -- @param #COORDINATE self
  -- @param #number Day The day.
  -- @param #number Month The month.
  -- @param #number Year The year.
  -- @param #boolean InSeconds If true, return the sun rise time in seconds.
  -- @return #string Sunset time, e.g. "20:41".
  function COORDINATE:GetSunsetAtDate(Day, Month, Year, InSeconds)

    -- Day of the year.
    local DayOfYear=UTILS.GetDayOfYear(Year, Month, Day)

    local Latitude, Longitude=self:GetLLDDM()

    local Tdiff=UTILS.GMTToLocalTimeDifference()

    local sunset=UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, false, Tdiff)

    if InSeconds then
      return sunset
    else
      return UTILS.SecondsToClock(sunset, true)
    end

  end

  --- Get todays sun set time.
  -- @param #COORDINATE self
  -- @param #boolean InSeconds If true, return the sun set time in seconds.
  -- @return #string Sunrise time, e.g. "20:41".
  function COORDINATE:GetSunset(InSeconds)

    -- Get current day of the year.
    local DayOfYear=UTILS.GetMissionDayOfYear()

    -- Lat and long at this point.
    local Latitude, Longitude=self:GetLLDDM()

    -- GMT time diff.
    local Tdiff=UTILS.GMTToLocalTimeDifference()

    -- Sunrise in seconds of the day.
    local sunrise=UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, false, Tdiff)

    local date=UTILS.GetDCSMissionDate()

    -- Debug output.
    --self:I(string.format("Sun set at lat=%.3f long=%.3f on %s (DayOfYear=%d): %s (%s sec of the day) (GMT %d)", Latitude, Longitude, date, DayOfYear, tostring(UTILS.SecondsToClock(sunrise)), tostring(sunrise) or "0", Tdiff))

    if InSeconds or type(sunrise) == "string" then
      return sunrise
    else
      return UTILS.SecondsToClock(sunrise, true)
    end

  end

  --- Get minutes until the next sun set at this coordinate.
  -- @param #COORDINATE self
  -- @param OnlyToday If true, only calculate the sun set of today. If sun has already set, the time in negative minutes since sunset is reported.
  -- @return #number Minutes to the next sunrise.
  function COORDINATE:GetMinutesToSunset(OnlyToday)

    -- Seconds of today
    local time=UTILS.SecondsOfToday()

    -- Next Sunset in seconds.
    local sunset=nil

    -- Time to sunrise.
    local delta=nil

    if OnlyToday then

      ---
      -- Sunset of today
      ---

      sunset=self:GetSunset(true)

      delta=sunset-time

    else

      ---
      -- Sunset of tomorrow
      ---

      -- Tomorrows day of the year.
      local DayOfYear=UTILS.GetMissionDayOfYear()+1

      local Latitude, Longitude=self:GetLLDDM()

      local Tdiff=UTILS.GMTToLocalTimeDifference()

      sunset=UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, false, Tdiff)

      delta=sunset+UTILS.SecondsToMidnight()

    end

    return delta/60
  end


  --- Return a BR string from a COORDINATE to the COORDINATE.
  -- @param #COORDINATE self
  -- @param #COORDINATE FromCoordinate The coordinate to measure the distance and the bearing from.
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @param #boolean MagVar If true, also get angle in MagVar for BR/BRA
  -- @param #number Precision Rounding precision, currently full km as default (=0)
  -- @return #string The BR text.
  function COORDINATE:ToStringBR( FromCoordinate, Settings, MagVar, Precision )
    local DirectionVec3 = FromCoordinate:GetDirectionVec3( self )
    local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
    local Distance = self:Get2DDistance( FromCoordinate )
    return "BR, " .. self:GetBRText( AngleRadians, Distance, Settings, nil, MagVar, Precision )
  end

  --- Return a BRA string from a COORDINATE to the COORDINATE.
  -- @param #COORDINATE self
  -- @param #COORDINATE FromCoordinate The coordinate to measure the distance and the bearing from.
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @param #boolean MagVar If true, also get angle in MagVar for BR/BRA
  -- @return #string The BR text.
  function COORDINATE:ToStringBRA( FromCoordinate, Settings, MagVar )
    local DirectionVec3 = FromCoordinate:GetDirectionVec3( self )
    local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
    local Distance = FromCoordinate:Get2DDistance( self )
    local Altitude = self:GetAltitudeText()
    return "BRA, " .. self:GetBRAText( AngleRadians, Distance, Settings, nil, MagVar )
  end
  
  --- Create a BRAA NATO call string to this COORDINATE from the FromCOORDINATE. Note - BRA delivered if no aspect can be obtained and "Merged" if range < 3nm
  -- @param #COORDINATE self
  -- @param #COORDINATE FromCoordinate The coordinate to measure the distance and the bearing from.
  -- @param #boolean Bogey Add "Bogey" at the end if true (not yet declared hostile or friendly)
  -- @param #boolean Spades Add "Spades" at the end if true (no IFF/VID ID yet known)
  -- @param #boolean SSML Add SSML tags speaking aspect as 0 1 2 and "brah" instead of BRAA
  -- @param #boolean Angels If true, altitude is e.g. "Angels 25" (i.e., a friendly plane), else "25 thousand"
  -- @param #boolean Zeros If using SSML, be aware that Google TTS will say "oh" and not "zero" for "0"; if Zeros is set to true, "0" will be replaced with "zero"
  -- @return #string The BRAA text.
  function COORDINATE:ToStringBRAANATO(FromCoordinate,Bogey,Spades,SSML,Angels,Zeros)
    
    -- Thanks to @Pikey
    local BRAANATO = "Merged."

    local currentCoord = FromCoordinate
    local DirectionVec3 = FromCoordinate:GetDirectionVec3( self )
    local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
    
    local bearing = UTILS.Round( UTILS.ToDegree( AngleRadians ),0 )
    
    local rangeMetres = self:Get2DDistance(currentCoord)
    local rangeNM = UTILS.Round( UTILS.MetersToNM(rangeMetres), 0)
    
    local aspect = self:ToStringAspect(currentCoord)

    local alt = UTILS.Round(UTILS.MetersToFeet(self.y)/1000,0)--*1000
    
    local alttext = string.format("%d thousand",alt)
    
    if Angels then
      alttext = string.format("Angels %d",alt)
    end
    
    if alt < 1 then
      alttext = "very low"
    end

    -- corrected Track to be direction of travel of bogey (self in this case)
    local track = "Maneuver"
  
  if self.Heading then
    track = UTILS.BearingToCardinal(self.Heading) or "North"
    end
    
    if rangeNM > 3 then
      if SSML then -- google says "oh" instead of zero, be aware
        if Zeros then
          bearing = string.format("%03d",bearing)
          local AngleDegText = string.gsub(bearing,"%d","%1 ") -- "0 5 1 "
          AngleDegText = string.gsub(AngleDegText," $","") -- "0 5 1"
          AngleDegText = string.gsub(AngleDegText,"0","zero")
          if aspect == "" then
            BRAANATO = string.format("brah %s, %d miles, %s, Track %s", AngleDegText, rangeNM, alttext, track)
          else
            BRAANATO = string.format("brah %s, %d miles, %s, %s, Track %s", AngleDegText, rangeNM, alttext, aspect, track)      
          end  
        else
          if aspect == "" then
            BRAANATO = string.format("brah <say-as interpret-as='characters'>%03d</say-as>, %d miles, %s, Track %s", bearing, rangeNM, alttext, track)
          else
            BRAANATO = string.format("brah <say-as interpret-as='characters'>%03d</say-as>, %d miles, %s, %s, Track %s", bearing, rangeNM, alttext, aspect, track)      
          end
        end
        if Bogey and Spades then
          BRAANATO = BRAANATO..", Bogey, Spades."
        elseif Bogey then
          BRAANATO = BRAANATO..", Bogey."
        elseif Spades then
         BRAANATO = BRAANATO..", Spades."
        else
         BRAANATO = BRAANATO.."."
        end
      else
        if aspect == "" then
          BRAANATO = string.format("BRA %03d, %d miles, %s, Track %s",bearing, rangeNM, alttext, track)
        else
          BRAANATO = string.format("BRAA %03d, %d miles, %s, %s, Track %s",bearing, rangeNM, alttext, aspect, track)      
        end
        if Bogey and Spades then
          BRAANATO = BRAANATO..", Bogey, Spades."
        elseif Bogey then
          BRAANATO = BRAANATO..", Bogey."
        elseif Spades then
         BRAANATO = BRAANATO..", Spades."
        else
         BRAANATO = BRAANATO.."."
        end
      end
    end
      
    return BRAANATO 
  end
  
  --- Return the BULLSEYE as COORDINATE Object
  -- @param #number Coalition Coalition of the bulls eye to return, e.g. coalition.side.BLUE
  -- @return #COORDINATE self
  -- @usage
  --          -- note the dot (.) here,not using the colon (:)
  --          local redbulls = COORDINATE.GetBullseyeCoordinate(coalition.side.RED)
  function COORDINATE.GetBullseyeCoordinate(Coalition)
    return COORDINATE:NewFromVec3( coalition.getMainRefPoint( Coalition ) )
  end
  
  --- Return a BULLS string out of the BULLS of the coalition to the COORDINATE.
  -- @param #COORDINATE self
  -- @param DCS#coalition.side Coalition The coalition.
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @param #boolean MagVar If true, als get angle in magnetic
  -- @return #string The BR text.
  function COORDINATE:ToStringBULLS( Coalition, Settings, MagVar )
    local BullsCoordinate = COORDINATE:NewFromVec3( coalition.getMainRefPoint( Coalition ) )
    local DirectionVec3 = BullsCoordinate:GetDirectionVec3( self )
    local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
    local Distance = self:Get2DDistance( BullsCoordinate )
    local Altitude = self:GetAltitudeText()
    return "BULLS, " .. self:GetBRText( AngleRadians, Distance, Settings, nil, MagVar )
  end

  --- Return an aspect string from a COORDINATE to the Angle of the object.
  -- @param #COORDINATE self
  -- @param #COORDINATE TargetCoordinate The target COORDINATE.
  -- @return #string The Aspect string, which is Hot, Cold or Flanking.
  function COORDINATE:ToStringAspect( TargetCoordinate )
    local Heading = self.Heading
    local DirectionVec3 = self:GetDirectionVec3( TargetCoordinate )
    local Angle = self:GetAngleDegrees( DirectionVec3 )

    if Heading then
      local Aspect = Angle - Heading
      if Aspect > -135 and Aspect <= -45 then
        return "Flanking"
      end
      if Aspect > -45 and Aspect <= 45 then
        return "Hot"
      end
      if Aspect > 45 and Aspect <= 135 then
        return "Flanking"
      end
      if Aspect > 135 or Aspect <= -135 then
        return "Cold"
      end
    end
    return ""
  end

  --- Get Latitude and Longitude in Degrees Decimal Minutes (DDM).
  -- @param #COORDINATE self
  -- @return #number Latitude in DDM.
  -- @return #number Lontitude in DDM.
  function COORDINATE:GetLLDDM()
    return coord.LOtoLL( self:GetVec3() )
  end

  --- Get Latitude & Longitude text.
  -- @param #COORDINATE self
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string LLText
  function COORDINATE:ToStringLL( Settings )
  
    local LL_Accuracy = Settings and Settings.LL_Accuracy or _SETTINGS.LL_Accuracy
    local lat, lon = coord.LOtoLL( self:GetVec3() )
    return string.format('%f', lat) .. ' ' .. string.format('%f', lon)
  end

  
  --- Provides a Lat Lon string in Degree Minute Second format.
  -- @param #COORDINATE self
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The LL DMS Text
  function COORDINATE:ToStringLLDMS( Settings )

    local LL_Accuracy = Settings and Settings.LL_Accuracy or _SETTINGS.LL_Accuracy
    local lat, lon = coord.LOtoLL( self:GetVec3() )
    return "LL DMS " .. UTILS.tostringLL( lat, lon, LL_Accuracy, true )
  end

  --- Provides a Lat Lon string in Degree Decimal Minute format.
  -- @param #COORDINATE self
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The LL DDM Text
  function COORDINATE:ToStringLLDDM( Settings )

    local LL_Accuracy = Settings and Settings.LL_Accuracy or _SETTINGS.LL_Accuracy
    local lat, lon = coord.LOtoLL( self:GetVec3() )
    return "LL DDM " .. UTILS.tostringLL( lat, lon, LL_Accuracy, false )
  end

  --- Provides a MGRS string
  -- @param #COORDINATE self
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The MGRS Text
  function COORDINATE:ToStringMGRS( Settings )

    local MGRS_Accuracy = Settings and Settings.MGRS_Accuracy or _SETTINGS.MGRS_Accuracy
    local lat, lon = coord.LOtoLL( self:GetVec3() )
    local MGRS = coord.LLtoMGRS( lat, lon )
    return "MGRS " .. UTILS.tostringMGRS( MGRS, MGRS_Accuracy )
  end
  
  --- Provides a COORDINATE from an MGRS String
  -- @param #COORDINATE self
  -- @param #string MGRSString MGRS String, e.g. "MGRS 37T DK 12345 12345"
  -- @return #COORDINATE self
  function COORDINATE:NewFromMGRSString( MGRSString )
    local myparts = UTILS.Split(MGRSString," ")
    local northing = tostring(myparts[5]) or ""
    local easting = tostring(myparts[4]) or ""
    if string.len(easting) < 5 then easting = easting..string.rep("0",5-string.len(easting)) end  
    if string.len(northing) < 5 then northing = northing..string.rep("0",5-string.len(northing)) end
    local MGRS = {
            UTMZone = myparts[2],
            MGRSDigraph = myparts[3],
            Easting = easting,
            Northing = northing,
          } 
    local lat, lon = coord.MGRStoLL(MGRS)
    local point = coord.LLtoLO(lat, lon, 0)
    local coord = COORDINATE:NewFromVec2({x=point.x,y=point.z})
    return coord
  end
  
  --- Provides a COORDINATE from an MGRS Coordinate
  -- @param #COORDINATE self
  -- @param #string UTMZone UTM Zone, e.g. "37T"
  -- @param #string MGRSDigraph Digraph, e.g. "DK"
  -- @param #string Easting Meters easting - string in order to allow for leading zeros, e.g. "01234". Should be 5 digits.
  -- @param #string Northing Meters northing - string in order to allow for leading zeros, e.g. "12340". Should be 5 digits.
  -- @return #COORDINATE self
  function COORDINATE:NewFromMGRS( UTMZone, MGRSDigraph, Easting, Northing )
    if string.len(Easting) < 5 then Easting = tostring(Easting..string.rep("0",5-string.len(Easting) )) end  
    if string.len(Northing) < 5 then Northing = tostring(Northing..string.rep("0",5-string.len(Northing) )) end
    local MGRS = {
            UTMZone = UTMZone,
            MGRSDigraph = MGRSDigraph,
            Easting = tostring(Easting),
            Northing = tostring(Northing),
          }
    local lat, lon = coord.MGRStoLL(MGRS)
    local point = coord.LLtoLO(lat, lon, 0)
    local coord = COORDINATE:NewFromVec2({x=point.x,y=point.z})
    return coord
  end

  --- Provides a coordinate string of the point, based on a coordinate format system:
  --   * Uses default settings in COORDINATE.
  --   * Can be overridden if for a GROUP containing x clients, a menu was selected to override the default.
  -- @param #COORDINATE self
  -- @param #COORDINATE ReferenceCoord The reference coordinate.
  -- @param #string ReferenceName The reference name.
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @param #boolean MagVar If true also show angle in magnetic
  -- @return #string The coordinate Text in the configured coordinate system.
  function COORDINATE:ToStringFromRP( ReferenceCoord, ReferenceName, Controllable, Settings, MagVar )

    self:F2( { ReferenceCoord = ReferenceCoord, ReferenceName = ReferenceName } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    local IsAir = Controllable and Controllable:IsAirPlane() or false

    if IsAir then
      local DirectionVec3 = ReferenceCoord:GetDirectionVec3( self )
      local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
      local Distance = self:Get2DDistance( ReferenceCoord )
      return "Targets are the last seen " .. self:GetBRText( AngleRadians, Distance, Settings, nil, MagVar ) .. " from " .. ReferenceName
    else
      local DirectionVec3 = ReferenceCoord:GetDirectionVec3( self )
      local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
      local Distance = self:Get2DDistance( ReferenceCoord )
      return "Target are located " .. self:GetBRText( AngleRadians, Distance, Settings, nil, MagVar ) .. " from " .. ReferenceName
    end

    return nil

  end
  
  --- Provides a coordinate string of the point, based on a coordinate format system:
  --   * Uses default settings in COORDINATE.
  --   * Can be overridden if for a GROUP containing x clients, a menu was selected to override the default.
  -- @param #COORDINATE self
  -- @param #COORDINATE ReferenceCoord The reference coordinate.
  -- @param #string ReferenceName The reference name.
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @param #boolean MagVar If true also get the angle as magnetic
  -- @return #string The coordinate Text in the configured coordinate system.
  function COORDINATE:ToStringFromRPShort( ReferenceCoord, ReferenceName, Controllable, Settings, MagVar )

    self:F2( { ReferenceCoord = ReferenceCoord, ReferenceName = ReferenceName } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    local IsAir = Controllable and Controllable:IsAirPlane() or false

    if IsAir then
      local DirectionVec3 = ReferenceCoord:GetDirectionVec3( self )
      local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
      local Distance = self:Get2DDistance( ReferenceCoord )
      return self:GetBRText( AngleRadians, Distance, Settings, nil, MagVar ) .. " from " .. ReferenceName
    else
      local DirectionVec3 = ReferenceCoord:GetDirectionVec3( self )
      local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
      local Distance = self:Get2DDistance( ReferenceCoord )
      return self:GetBRText( AngleRadians, Distance, Settings, nil, MagVar ) .. " from " .. ReferenceName
    end

    return nil

  end
  
  --- Provides a coordinate string of the point, based on the A2G coordinate format system.
  -- @param #COORDINATE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @param #boolean MagVar If true, also get angle in MagVar for BR/BRA
  -- @return #string The coordinate Text in the configured coordinate system.
  function COORDINATE:ToStringA2G( Controllable, Settings, MagVar )

    self:F2( { Controllable = Controllable and Controllable:GetName() } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    if Settings:IsA2G_BR()  then
      -- If no Controllable is given to calculate the BR from, then MGRS will be used!!!
      if Controllable then
        local Coordinate = Controllable:GetCoordinate()
        return Controllable and self:ToStringBR( Coordinate, Settings, MagVar ) or self:ToStringMGRS( Settings )
      else
        return self:ToStringMGRS( Settings )
      end
    end
    if Settings:IsA2G_LL_DMS()  then
      return self:ToStringLLDMS( Settings )
    end
    if Settings:IsA2G_LL_DDM()  then
      return self:ToStringLLDDM( Settings )
    end
    if Settings:IsA2G_MGRS() then
      return self:ToStringMGRS( Settings )
    end

    return nil

  end


  --- Provides a coordinate string of the point, based on the A2A coordinate format system.
  -- @param #COORDINATE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @param #boolean MagVar If true, also get angle in MagVar for BR/BRA
  -- @return #string The coordinate Text in the configured coordinate system.
  function COORDINATE:ToStringA2A( Controllable, Settings, MagVar ) 

    self:F2( { Controllable = Controllable and Controllable:GetName() } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    if Settings:IsA2A_BRAA() then
      if Controllable then
        local Coordinate = Controllable:GetCoordinate()
        return self:ToStringBRA( Coordinate, Settings, MagVar )
      else
        return self:ToStringMGRS( Settings )
      end
    end
    if Settings:IsA2A_BULLS() then
      local Coalition = Controllable:GetCoalition()
      return self:ToStringBULLS( Coalition, Settings, MagVar )
    end
    if Settings:IsA2A_LL_DMS()  then
      return self:ToStringLLDMS( Settings )
    end
    if Settings:IsA2A_LL_DDM()  then
      return self:ToStringLLDDM( Settings )
    end
    if Settings:IsA2A_MGRS() then
      return self:ToStringMGRS( Settings )
    end

    return nil

  end

  --- Provides a coordinate string of the point, based on a coordinate format system:
  --   * Uses default settings in COORDINATE.
  --   * Can be overridden if for a GROUP containing x clients, a menu was selected to override the default.
  -- @param #COORDINATE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The controllable to retrieve the settings from, otherwise the default settings will be chosen.
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The coordinate Text in the configured coordinate system.
  function COORDINATE:ToString( Controllable, Settings )

--    self:E( { Controllable = Controllable and Controllable:GetName() } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    local ModeA2A = nil
    
    --[[
    if Task then
      if Task:IsInstanceOf( TASK_A2A ) then
        ModeA2A = true
      else
        if Task:IsInstanceOf( TASK_A2G ) then
          ModeA2A = false
        else
          if Task:IsInstanceOf( TASK_CARGO ) then
            ModeA2A = false
          end
            if Task:IsInstanceOf( TASK_CAPTURE_ZONE ) then
              ModeA2A = false
            end
        end
      end
    end
    --]]

    if ModeA2A == nil then
      local IsAir = Controllable and ( Controllable:IsAirPlane() or Controllable:IsHelicopter() ) or false
      if IsAir  then
        ModeA2A = true
      else
        ModeA2A = false
      end
    end


    if ModeA2A == true then
      return self:ToStringA2A( Controllable, Settings )
    else
      return self:ToStringA2G( Controllable, Settings )
    end

    return nil

  end

  --- Provides a pressure string of the point, based on a measurement system:
  --   * Uses default settings in COORDINATE.
  --   * Can be overridden if for a GROUP containing x clients, a menu was selected to override the default.
  -- @param #COORDINATE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The pressure text in the configured measurement system.
  function COORDINATE:ToStringPressure( Controllable, Settings ) 

    self:F2( { Controllable = Controllable and Controllable:GetName() } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    return self:GetPressureText( nil, Settings )
  end

  --- Provides a wind string of the point, based on a measurement system:
  --   * Uses default settings in COORDINATE.
  --   * Can be overridden if for a GROUP containing x clients, a menu was selected to override the default.
  -- @param #COORDINATE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The wind text in the configured measurement system.
  function COORDINATE:ToStringWind( Controllable, Settings )

    self:F2( { Controllable = Controllable and Controllable:GetName() } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    return self:GetWindText( nil, Settings )
  end

  --- Provides a temperature string of the point, based on a measurement system:
  --   * Uses default settings in COORDINATE.
  --   * Can be overridden if for a GROUP containing x clients, a menu was selected to override the default.
  -- @param #COORDINATE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS
  -- @return #string The temperature text in the configured measurement system.
  function COORDINATE:ToStringTemperature( Controllable, Settings )

    self:F2( { Controllable = Controllable and Controllable:GetName() } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    return self:GetTemperatureText( nil, Settings )
  end
  
  
  --- Function to check if a coordinate is in a steep (>8% elevation) area of the map
  -- @param #COORDINATE self
  -- @param #number Radius (Optional) Radius to check around the coordinate, defaults to 50m (100m diameter)
  -- @param #number Minelevation (Optional) Elevation from which on a area is defined as steep, defaults to 8% (8m height gain across 100 meters)
  -- @return #boolean IsSteep If true, area is steep
  -- @return #number MaxElevation Elevation in meters measured over 100m
  function COORDINATE:IsInSteepArea(Radius,Minelevation)
    local steep = false
    local elev = Minelevation or 8
    local bdelta = 0
    local h0 = self:GetLandHeight()
    local radius = Radius or 50
    local diam = radius * 2
    for i=0,150,30 do
      local polar = math.fmod(i+180,360)
      local c1 = self:Translate(radius,i,false,false)
      local c2 = self:Translate(radius,polar,false,false)
      local h1 = c1:GetLandHeight()
      local h2 = c2:GetLandHeight()
      local d1 = math.abs(h1-h2)
      local d2 = math.abs(h0-h1)
      local d3 = math.abs(h0-h2)
      local dm = d1 > d2 and d1 or d2
      local dm1 = dm > d3 and dm or d3
      bdelta = dm1 > bdelta and dm1 or bdelta
      self:T(string.format("d1=%d, d2=%d, d3=%d, max delta=%d",d1,d2,d3,bdelta))
    end
    local steepness = bdelta / (radius / 100)    
    if steepness >= elev then steep = true end
    return steep, math.floor(steepness)
  end
  
    --- Function to check if a coordinate is in a flat (<8% elevation) area of the map
  -- @param #COORDINATE self
  -- @param #number Radius (Optional) Radius to check around the coordinate, defaults to 50m (100m diameter)
  -- @param #number Minelevation (Optional) Elevation from which on a area is defined as steep, defaults to 8% (8m height gain across 100 meters)
  -- @return #boolean IsFlat If true, area is flat
  -- @return #number MaxElevation Elevation in meters measured over 100m
  function COORDINATE:IsInFlatArea(Radius,Minelevation)
    local steep, elev = self:IsInSteepArea(Radius,Minelevation)
    local flat = not steep
    return flat, elev
  end
  
end

do -- POINT_VEC3

  --- The POINT_VEC3 class
  -- @type POINT_VEC3
  -- @field #number x The x coordinate in 3D space.
  -- @field #number y The y coordinate in 3D space.
  -- @field #number z The z COORDINATE in 3D space.
  -- @field Utilities.Utils#SMOKECOLOR SmokeColor
  -- @field Utilities.Utils#FLARECOLOR FlareColor
  -- @field #POINT_VEC3.RoutePointAltType RoutePointAltType
  -- @field #POINT_VEC3.RoutePointType RoutePointType
  -- @field #POINT_VEC3.RoutePointAction RoutePointAction
  -- @extends #COORDINATE


  --- Defines a 3D point in the simulator and with its methods, you can use or manipulate the point in 3D space.
  --
  -- **Important Note:** Most of the functions in this section were taken from MIST, and reworked to OO concepts.
  -- In order to keep the credibility of the the author,
  -- I want to emphasize that the formulas embedded in the MIST framework were created by Grimes or previous authors,
  -- who you can find on the Eagle Dynamics Forums.
  --
  --
  -- ## POINT_VEC3 constructor
  --
  -- A new POINT_VEC3 object can be created with:
  --
  --  * @{#POINT_VEC3.New}(): a 3D point.
  --  * @{#POINT_VEC3.NewFromVec3}(): a 3D point created from a @{DCS#Vec3}.
  --
  --
  -- ## Manupulate the X, Y, Z coordinates of the POINT_VEC3
  --
  -- A POINT_VEC3 class works in 3D space. It contains internally an X, Y, Z coordinate.
  -- Methods exist to manupulate these coordinates.
  --
  -- The current X, Y, Z axis can be retrieved with the methods @{#POINT_VEC3.GetX}(), @{#POINT_VEC3.GetY}(), @{#POINT_VEC3.GetZ}() respectively.
  -- The methods @{#POINT_VEC3.SetX}(), @{#POINT_VEC3.SetY}(), @{#POINT_VEC3.SetZ}() change the respective axis with a new value.
  -- The current axis values can be changed by using the methods @{#POINT_VEC3.AddX}(), @{#POINT_VEC3.AddY}(), @{#POINT_VEC3.AddZ}()
  -- to add or substract a value from the current respective axis value.
  -- Note that the Set and Add methods return the current POINT_VEC3 object, so these manipulation methods can be chained... For example:
  --
  --      local Vec3 = PointVec3:AddX( 100 ):AddZ( 150 ):GetVec3()
  --
  --
  -- ## 3D calculation methods
  --
  -- Various calculation methods exist to use or manipulate 3D space. Find below a short description of each method:
  --
  --
  -- ## Point Randomization
  --
  -- Various methods exist to calculate random locations around a given 3D point.
  --
  --   * @{#POINT_VEC3.GetRandomPointVec3InRadius}(): Provides a random 3D point around the current 3D point, in the given inner to outer band.
  --
  --
  -- @field #POINT_VEC3
  POINT_VEC3 = {
    ClassName = "POINT_VEC3",
    Metric = true,
    RoutePointAltType = {
      BARO = "BARO",
    },
    RoutePointType = {
      TakeOffParking = "TakeOffParking",
      TurningPoint = "Turning Point",
    },
    RoutePointAction = {
      FromParkingArea = "From Parking Area",
      TurningPoint = "Turning Point",
    },
  }

  --- RoutePoint AltTypes
  -- @type POINT_VEC3.RoutePointAltType
  -- @field BARO "BARO"

  --- RoutePoint Types
  -- @type POINT_VEC3.RoutePointType
  -- @field TakeOffParking "TakeOffParking"
  -- @field TurningPoint "Turning Point"

  --- RoutePoint Actions
  -- @type POINT_VEC3.RoutePointAction
  -- @field FromParkingArea "From Parking Area"
  -- @field TurningPoint "Turning Point"

  -- Constructor.

  --- Create a new POINT_VEC3 object.
  -- @param #POINT_VEC3 self
  -- @param DCS#Distance x The x coordinate of the Vec3 point, pointing to the North.
  -- @param DCS#Distance y The y coordinate of the Vec3 point, pointing Upwards.
  -- @param DCS#Distance z The z coordinate of the Vec3 point, pointing to the Right.
  -- @return Core.Point#POINT_VEC3
  function POINT_VEC3:New( x, y, z )

    local self = BASE:Inherit( self, COORDINATE:New( x, y, z ) ) -- Core.Point#POINT_VEC3
    self:F2( self )

    return self
  end

  --- Create a new POINT_VEC3 object from Vec2 coordinates.
  -- @param #POINT_VEC3 self
  -- @param DCS#Vec2 Vec2 The Vec2 point.
  -- @param DCS#Distance LandHeightAdd (optional) Add a landheight.
  -- @return Core.Point#POINT_VEC3 self
  function POINT_VEC3:NewFromVec2( Vec2, LandHeightAdd )

    local self = BASE:Inherit( self, COORDINATE:NewFromVec2( Vec2, LandHeightAdd ) ) -- Core.Point#POINT_VEC3
    self:F2( self )

    return self
  end


  --- Create a new POINT_VEC3 object from  Vec3 coordinates.
  -- @param #POINT_VEC3 self
  -- @param DCS#Vec3 Vec3 The Vec3 point.
  -- @return Core.Point#POINT_VEC3 self
  function POINT_VEC3:NewFromVec3( Vec3 )

    local self = BASE:Inherit( self, COORDINATE:NewFromVec3( Vec3 ) ) -- Core.Point#POINT_VEC3
    self:F2( self )

    return self
  end



  --- Return the x coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @return #number The x coordinate.
  function POINT_VEC3:GetX()
    return self.x
  end

  --- Return the y coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @return #number The y coordinate.
  function POINT_VEC3:GetY()
    return self.y
  end

  --- Return the z coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @return #number The z coordinate.
  function POINT_VEC3:GetZ()
    return self.z
  end

  --- Set the x coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @param #number x The x coordinate.
  -- @return #POINT_VEC3
  function POINT_VEC3:SetX( x )
    self.x = x
    return self
  end

  --- Set the y coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @param #number y The y coordinate.
  -- @return #POINT_VEC3
  function POINT_VEC3:SetY( y )
    self.y = y
    return self
  end

  --- Set the z coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @param #number z The z coordinate.
  -- @return #POINT_VEC3
  function POINT_VEC3:SetZ( z )
    self.z = z
    return self
  end

  --- Add to the x coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @param #number x The x coordinate value to add to the current x coordinate.
  -- @return #POINT_VEC3
  function POINT_VEC3:AddX( x )
    self.x = self.x + x
    return self
  end

  --- Add to the y coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @param #number y The y coordinate value to add to the current y coordinate.
  -- @return #POINT_VEC3
  function POINT_VEC3:AddY( y )
    self.y = self.y + y
    return self
  end

  --- Add to the z coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @param #number z The z coordinate value to add to the current z coordinate.
  -- @return #POINT_VEC3
  function POINT_VEC3:AddZ( z )
    self.z = self.z +z
    return self
  end

  --- Return a random POINT_VEC3 within an Outer Radius and optionally NOT within an Inner Radius of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @param DCS#Distance OuterRadius
  -- @param DCS#Distance InnerRadius
  -- @return #POINT_VEC3
  function POINT_VEC3:GetRandomPointVec3InRadius( OuterRadius, InnerRadius )

    return POINT_VEC3:NewFromVec3( self:GetRandomVec3InRadius( OuterRadius, InnerRadius ) )
  end

end

do -- POINT_VEC2

  -- @type POINT_VEC2
  -- @field DCS#Distance x The x coordinate in meters.
  -- @field DCS#Distance y the y coordinate in meters.
  -- @extends Core.Point#COORDINATE

  --- Defines a 2D point in the simulator. The height coordinate (if needed) will be the land height + an optional added height specified.
  --
  -- ## POINT_VEC2 constructor
  --
  -- A new POINT_VEC2 instance can be created with:
  --
  --  * @{Core.Point#POINT_VEC2.New}(): a 2D point, taking an additional height parameter.
  --  * @{Core.Point#POINT_VEC2.NewFromVec2}(): a 2D point created from a @{DCS#Vec2}.
  --
  -- ## Manupulate the X, Altitude, Y coordinates of the 2D point
  --
  -- A POINT_VEC2 class works in 2D space, with an altitude setting. It contains internally an X, Altitude, Y coordinate.
  -- Methods exist to manupulate these coordinates.
  --
  -- The current X, Altitude, Y axis can be retrieved with the methods @{#POINT_VEC2.GetX}(), @{#POINT_VEC2.GetAlt}(), @{#POINT_VEC2.GetY}() respectively.
  -- The methods @{#POINT_VEC2.SetX}(), @{#POINT_VEC2.SetAlt}(), @{#POINT_VEC2.SetY}() change the respective axis with a new value.
  -- The current Lat(itude), Alt(itude), Lon(gitude) values can also be retrieved with the methods @{#POINT_VEC2.GetLat}(), @{#POINT_VEC2.GetAlt}(), @{#POINT_VEC2.GetLon}() respectively.
  -- The current axis values can be changed by using the methods @{#POINT_VEC2.AddX}(), @{#POINT_VEC2.AddAlt}(), @{#POINT_VEC2.AddY}()
  -- to add or substract a value from the current respective axis value.
  -- Note that the Set and Add methods return the current POINT_VEC2 object, so these manipulation methods can be chained... For example:
  --
  --      local Vec2 = PointVec2:AddX( 100 ):AddY( 2000 ):GetVec2()
  --
  -- @field #POINT_VEC2
  POINT_VEC2 = {
    ClassName = "POINT_VEC2",
  }



  --- POINT_VEC2 constructor.
  -- @param #POINT_VEC2 self
  -- @param DCS#Distance x The x coordinate of the Vec3 point, pointing to the North.
  -- @param DCS#Distance y The y coordinate of the Vec3 point, pointing to the Right.
  -- @param DCS#Distance LandHeightAdd (optional) The default height if required to be evaluated will be the land height of the x, y coordinate. You can specify an extra height to be added to the land height.
  -- @return Core.Point#POINT_VEC2
  function POINT_VEC2:New( x, y, LandHeightAdd )

    local LandHeight = land.getHeight( { ["x"] = x, ["y"] = y } )

    LandHeightAdd = LandHeightAdd or 0
    LandHeight = LandHeight + LandHeightAdd

    local self = BASE:Inherit( self, COORDINATE:New( x, LandHeight, y ) ) -- Core.Point#POINT_VEC2
    self:F2( self )

    return self
  end

  --- Create a new POINT_VEC2 object from  Vec2 coordinates.
  -- @param #POINT_VEC2 self
  -- @param DCS#Vec2 Vec2 The Vec2 point.
  -- @return Core.Point#POINT_VEC2 self
  function POINT_VEC2:NewFromVec2( Vec2, LandHeightAdd )

    local LandHeight = land.getHeight( Vec2 )

    LandHeightAdd = LandHeightAdd or 0
    LandHeight = LandHeight + LandHeightAdd

    local self = BASE:Inherit( self, COORDINATE:NewFromVec2( Vec2, LandHeightAdd ) ) -- #POINT_VEC2
    self:F2( self )

    return self
  end

  --- Create a new POINT_VEC2 object from  Vec3 coordinates.
  -- @param #POINT_VEC2 self
  -- @param DCS#Vec3 Vec3 The Vec3 point.
  -- @return Core.Point#POINT_VEC2 self
  function POINT_VEC2:NewFromVec3( Vec3 )

    local self = BASE:Inherit( self, COORDINATE:NewFromVec3( Vec3 ) ) -- #POINT_VEC2
    self:F2( self )

    return self
  end

  --- Return the x coordinate of the POINT_VEC2.
  -- @param #POINT_VEC2 self
  -- @return #number The x coordinate.
  function POINT_VEC2:GetX()
    return self.x
  end

  --- Return the y coordinate of the POINT_VEC2.
  -- @param #POINT_VEC2 self
  -- @return #number The y coordinate.
  function POINT_VEC2:GetY()
    return self.z
  end

  --- Set the x coordinate of the POINT_VEC2.
  -- @param #POINT_VEC2 self
  -- @param #number x The x coordinate.
  -- @return #POINT_VEC2
  function POINT_VEC2:SetX( x )
    self.x = x
    return self
  end

  --- Set the y coordinate of the POINT_VEC2.
  -- @param #POINT_VEC2 self
  -- @param #number y The y coordinate.
  -- @return #POINT_VEC2
  function POINT_VEC2:SetY( y )
    self.z = y
    return self
  end

  --- Return Return the Lat(itude) coordinate of the POINT_VEC2 (ie: (parent)POINT_VEC3.x).
  -- @param #POINT_VEC2 self
  -- @return #number The x coordinate.
  function POINT_VEC2:GetLat()
    return self.x
  end

  --- Set the Lat(itude) coordinate of the POINT_VEC2 (ie: POINT_VEC3.x).
  -- @param #POINT_VEC2 self
  -- @param #number x The x coordinate.
  -- @return #POINT_VEC2
  function POINT_VEC2:SetLat( x )
    self.x = x
    return self
  end

  --- Return the Lon(gitude) coordinate of the POINT_VEC2 (ie: (parent)POINT_VEC3.z).
  -- @param #POINT_VEC2 self
  -- @return #number The y coordinate.
  function POINT_VEC2:GetLon()
    return self.z
  end

  --- Set the Lon(gitude) coordinate of the POINT_VEC2 (ie: POINT_VEC3.z).
  -- @param #POINT_VEC2 self
  -- @param #number y The y coordinate.
  -- @return #POINT_VEC2
  function POINT_VEC2:SetLon( z )
    self.z = z
    return self
  end

  --- Return the altitude (height) of the land at the POINT_VEC2.
  -- @param #POINT_VEC2 self
  -- @return #number The land altitude.
  function POINT_VEC2:GetAlt()
    return self.y ~= 0 or land.getHeight( { x = self.x, y = self.z } )
  end

  --- Set the altitude of the POINT_VEC2.
  -- @param #POINT_VEC2 self
  -- @param #number Altitude The land altitude. If nothing (nil) is given, then the current land altitude is set.
  -- @return #POINT_VEC2
  function POINT_VEC2:SetAlt( Altitude )
    self.y = Altitude or land.getHeight( { x = self.x, y = self.z } )
    return self
  end

  --- Add to the x coordinate of the POINT_VEC2.
  -- @param #POINT_VEC2 self
  -- @param #number x The x coordinate.
  -- @return #POINT_VEC2
  function POINT_VEC2:AddX( x )
    self.x = self.x + x
    return self
  end

  --- Add to the y coordinate of the POINT_VEC2.
  -- @param #POINT_VEC2 self
  -- @param #number y The y coordinate.
  -- @return #POINT_VEC2
  function POINT_VEC2:AddY( y )
    self.z = self.z + y
    return self
  end

  --- Add to the current land height an altitude.
  -- @param #POINT_VEC2 self
  -- @param #number Altitude The Altitude to add. If nothing (nil) is given, then the current land altitude is set.
  -- @return #POINT_VEC2
  function POINT_VEC2:AddAlt( Altitude )
    self.y = land.getHeight( { x = self.x, y = self.z } ) + Altitude or 0
    return self
  end


  --- Return a random POINT_VEC2 within an Outer Radius and optionally NOT within an Inner Radius of the POINT_VEC2.
  -- @param #POINT_VEC2 self
  -- @param DCS#Distance OuterRadius
  -- @param DCS#Distance InnerRadius
  -- @return #POINT_VEC2
  function POINT_VEC2:GetRandomPointVec2InRadius( OuterRadius, InnerRadius )
    self:F2( { OuterRadius, InnerRadius } )

    return POINT_VEC2:NewFromVec2( self:GetRandomVec2InRadius( OuterRadius, InnerRadius ) )
  end

  -- TODO: Check this to replace
  --- Calculate the distance from a reference @{#POINT_VEC2}.
  -- @param #POINT_VEC2 self
  -- @param #POINT_VEC2 PointVec2Reference The reference @{#POINT_VEC2}.
  -- @return DCS#Distance The distance from the reference @{#POINT_VEC2} in meters.
  function POINT_VEC2:DistanceFromPointVec2( PointVec2Reference )
    self:F2( PointVec2Reference )

    local Distance = ( ( PointVec2Reference.x - self.x ) ^ 2 + ( PointVec2Reference.z - self.z ) ^2 ) ^ 0.5

    self:T2( Distance )
    return Distance
  end

end
