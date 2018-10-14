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
-- # Demo Missions
--
-- ### [POINT_VEC Demo Missions source code]()
--
-- ### [POINT_VEC Demo Missions, only for beta testers]()
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
--
-- ===
--
-- # YouTube Channel
--
-- ### [POINT_VEC YouTube Channel]()
--
-- ===
--
-- ### Authors:
--
--   * FlightControl : Design & Programming
--
-- ### Contributions:
--
-- @module Core.Point
-- @image Core_Coordinate.JPG




do -- COORDINATE

  --- @type COORDINATE
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
  --   * @{#COORDINATE.GetNorthCorrection}(): Obtains the north correction at the current 3D point.
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
  -- The method @{#COORDINATE.IsLOS}() returns if the two coodinates have LOS.
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
  --
  --
  --
  --
  -- ## 8) Metric or imperial system
  --
  --   * @{#COORDINATE.IsMetric}(): Returns if the 3D point is Metric or Nautical Miles.
  --   * @{#COORDINATE.SetMetric}(): Sets the 3D point to Metric or Nautical Miles.
  --
  --
  -- ## 9) Coordinate text generation
  -- 
  --
  --   * @{#COORDINATE.ToStringBR}(): Generates a Bearing & Range text in the format of DDD for DI where DDD is degrees and DI is distance.
  --   * @{#COORDINATE.ToStringLL}(): Generates a Latutude & Longutude text.
  --
  -- @field #COORDINATE
  COORDINATE = {
    ClassName = "COORDINATE",
  }

  --- @field COORDINATE.WaypointAltType 
  COORDINATE.WaypointAltType = {
    BARO = "BARO",
    RADIO = "RADIO",
  }
  
  --- @field COORDINATE.WaypointAction 
  COORDINATE.WaypointAction = {
    TurningPoint = "Turning Point",
    FlyoverPoint = "Fly Over Point",
    FromParkingArea = "From Parking Area",
    FromParkingAreaHot = "From Parking Area Hot",
    FromRunway = "From Runway",
    Landing = "Landing",
  }

  --- @field COORDINATE.WaypointType 
  COORDINATE.WaypointType = {
    TakeOffParking = "TakeOffParking",
    TakeOffParkingHot = "TakeOffParkingHot",
    TakeOff = "TakeOffParkingHot",
    TurningPoint = "Turning Point",
    Land = "Land",
  }


  --- COORDINATE constructor.
  -- @param #COORDINATE self
  -- @param DCS#Distance x The x coordinate of the Vec3 point, pointing to the North.
  -- @param DCS#Distance y The y coordinate of the Vec3 point, pointing to the Right.
  -- @param DCS#Distance z The z coordinate of the Vec3 point, pointing to the Right.
  -- @return #COORDINATE
  function COORDINATE:New( x, y, z ) 

    local self = BASE:Inherit( self, BASE:New() ) -- #COORDINATE
    self.x = x
    self.y = y
    self.z = z
    
    return self
  end

  --- COORDINATE constructor.
  -- @param #COORDINATE self
  -- @param #COORDINATE Coordinate.
  -- @return #COORDINATE
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
  -- @param DCS#Distance LandHeightAdd (optional) The default height if required to be evaluated will be the land height of the x, y coordinate. You can specify an extra height to be added to the land height.
  -- @return #COORDINATE
  function COORDINATE:NewFromVec2( Vec2, LandHeightAdd ) 

    local LandHeight = land.getHeight( Vec2 )
    
    LandHeightAdd = LandHeightAdd or 0
    LandHeight = LandHeight + LandHeightAdd

    local self = self:New( Vec2.x, LandHeight, Vec2.y ) -- #COORDINATE

    self:F2( self )

    return self

  end

  --- Create a new COORDINATE object from  Vec3 coordinates.
  -- @param #COORDINATE self
  -- @param DCS#Vec3 Vec3 The Vec3 point.
  -- @return #COORDINATE
  function COORDINATE:NewFromVec3( Vec3 ) 

    local self = self:New( Vec3.x, Vec3.y, Vec3.z ) -- #COORDINATE

    self:F2( self )

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
      _coord.y=altitude
    else
      _coord.y=self:GetLandHeight()
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
  
  --- Returns if the 2 coordinates are at the same 2D position.
  -- @param #COORDINATE self
  -- @param #number radius (Optional) Scan radius in meters. Default 100 m.
  -- @param #boolean scanunits (Optional) If true scan for units. Default true.
  -- @param #boolean scanstatics (Optional) If true scan for static objects. Default true.
  -- @param #boolean scanscenery (Optional) If true scan for scenery objects. Default false.
  -- @return True if units were found.
  -- @return True if statics were found.
  -- @return True if scenery objects were found.
  -- @return Unit objects found.
  -- @return Static objects found.
  -- @return Scenery objects found.
  function COORDINATE:ScanObjects(radius, scanunits, scanstatics, scanscenery)
    self:F(string.format("Scanning in radius %.1f m.", radius))

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
        local ObjectCategory = ZoneObject:getCategory()
        
        -- Check for unit or static objects
        --if (ObjectCategory == Object.Category.UNIT and ZoneObject:isExist() and ZoneObject:isActive()) then
        if (ObjectCategory == Object.Category.UNIT and ZoneObject:isExist()) then
        
          table.insert(Units, UNIT:Find(ZoneObject))
          gotunits=true
          
        elseif (ObjectCategory == Object.Category.STATIC and ZoneObject:isExist()) then
        
          table.insert(Statics, ZoneObject)
          gotstatics=true
          
        elseif ObjectCategory == Object.Category.SCENERY then
        
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
    end
    for _,scenery in pairs(Scenery) do
      self:T(string.format("Scan found scenery %s", scenery:getTypeName()))
    end
    
    return gotunits, gotstatics, gotscenery, Units, Statics, Scenery
  end
 
  --- Calculate the distance from a reference @{#COORDINATE}.
  -- @param #COORDINATE self
  -- @param #COORDINATE PointVec2Reference The reference @{#COORDINATE}.
  -- @return DCS#Distance The distance from the reference @{#COORDINATE} in meters.
  function COORDINATE:DistanceFromPointVec2( PointVec2Reference )
    self:F2( PointVec2Reference )

    local Distance = ( ( PointVec2Reference.x - self.x ) ^ 2 + ( PointVec2Reference.z - self.z ) ^2 ) ^ 0.5

    self:T2( Distance )
    return Distance
  end

  --- Add a Distance in meters from the COORDINATE orthonormal plane, with the given angle, and calculate the new COORDINATE.
  -- @param #COORDINATE self
  -- @param DCS#Distance Distance The Distance to be added in meters.
  -- @param DCS#Angle Angle The Angle in degrees.
  -- @return #COORDINATE The new calculated COORDINATE.
  function COORDINATE:Translate( Distance, Angle )
    local SX = self.x
    local SY = self.z
    local Radians = Angle / 180 * math.pi
    local TX = Distance * math.cos( Radians ) + SX
    local TY = Distance * math.sin( Radians ) + SY

    return COORDINATE:NewFromVec2( { x = TX, y = TY } )
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
  -- @param DCS#Distance OuterRadius
  -- @param DCS#Distance InnerRadius
  -- @return #COORDINATE
  function COORDINATE:GetRandomCoordinateInRadius( OuterRadius, InnerRadius )
    self:F2( { OuterRadius, InnerRadius } )

    return COORDINATE:NewFromVec2( self:GetRandomVec2InRadius( OuterRadius, InnerRadius ) )
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
  -- @return #number
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
    return { x = TargetCoordinate.x - self.x, y = TargetCoordinate.y - self.y, z = TargetCoordinate.z - self.z }
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


  --- Return an angle in radians from the COORDINATE using a direction vector in Vec3 format.
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

  --- Return an angle in degrees from the COORDINATE using a direction vector in Vec3 format.
  -- @param #COORDINATE self
  -- @param DCS#Vec3 DirectionVec3 The direction vector in Vec3 format.
  -- @return #number DirectionRadians The angle in degrees.
  function COORDINATE:GetAngleDegrees( DirectionVec3 )
    local AngleRadians = self:GetAngleRadians( DirectionVec3 )
    local Angle = UTILS.ToDegree( AngleRadians )
    return Angle
  end


  --- Return the 2D distance in meters between the target COORDINATE and the COORDINATE.
  -- @param #COORDINATE self
  -- @param #COORDINATE TargetCoordinate The target COORDINATE.
  -- @return DCS#Distance Distance The distance in meters.
  function COORDINATE:Get2DDistance( TargetCoordinate )
    local TargetVec3 = TargetCoordinate:GetVec3()
    local SourceVec3 = self:GetVec3()
    return ( ( TargetVec3.x - SourceVec3.x ) ^ 2 + ( TargetVec3.z - SourceVec3.z ) ^ 2 ) ^ 0.5
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

  --- Returns a text of the temperature according the measurement system @{Settings}.
  -- The text will reflect the temperature like this:
  -- 
  --   - For Russian and European aircraft using the metric system - Degrees Celcius (°C)
  --   - For Americain aircraft we link to the imperial system - Degrees Farenheit (°F)
  -- 
  -- A text containing a pressure will look like this: 
  -- 
  --   - `Temperature: %n.d °C`  
  --   - `Temperature: %n.d °F`
  --   
   -- @param #COORDINATE self
  -- @param height (Optional) parameter specifying the height ASL.
  -- @return #string Temperature according the measurement system @{Settings}.
  function COORDINATE:GetTemperatureText( height, Settings )
  
    local DegreesCelcius = self:GetTemperature( height )
    
    local Settings = Settings or _SETTINGS

    if DegreesCelcius then
      if Settings:IsMetric() then
        return string.format( " %-2.2f °C", DegreesCelcius )
      else
        return string.format( " %-2.2f °F", UTILS.CelciusToFarenheit( DegreesCelcius ) )
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
  
  --- Returns a text of the pressure according the measurement system @{Settings}.
  -- The text will contain always the pressure in hPa and:
  -- 
  --   - For Russian and European aircraft using the metric system - hPa and mmHg
  --   - For Americain and European aircraft we link to the imperial system - hPa and inHg
  -- 
  -- A text containing a pressure will look like this: 
  -- 
  --   - `QFE: x hPa (y mmHg)`  
  --   - `QFE: x hPa (y inHg)`
  -- 
  -- @param #COORDINATE self
  -- @param height (Optional) parameter specifying the height ASL. E.g. set height=0 for QNH.
  -- @return #string Pressure in hPa and mmHg or inHg depending on the measurement system @{Settings}.
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
  
  --- Returns the wind direction (from) and strength.
  -- @param #COORDINATE self
  -- @param height (Optional) parameter specifying the height ASL. The minimum height will be always be the land height since the wind is zero below the ground.
  -- @return Direction the wind is blowing from in degrees.
  -- @return Wind strength in m/s.
  function COORDINATE:GetWind(height)
    local landheight=self:GetLandHeight()+0.1 -- we at 0.1 meters to be sure to be above ground since wind is zero below ground level.
    local point={x=self.x, y=math.max(height or self.y, landheight), z=self.z}
    -- get wind velocity vector
    local wind = atmosphere.getWind(point)    
    local direction = math.deg(math.atan2(wind.z, wind.x))
    if direction < 0 then
      direction = 360 + direction
    end
    -- Convert to direction to from direction 
    if direction > 180 then
      direction = direction-180
    else
      direction = direction+180
    end
    local strength=math.sqrt((wind.x)^2+(wind.z)^2)
    -- Return wind direction and strength km/h.
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


  --- Returns a text documenting the wind direction (from) and strength according the measurement system @{Settings}.
  -- The text will reflect the wind like this:
  -- 
  --   - For Russian and European aircraft using the metric system - Wind direction in degrees (°) and wind speed in meters per second (mps).
  --   - For Americain aircraft we link to the imperial system - Wind direction in degrees (°) and wind speed in knots per second (kps).
  -- 
  -- A text containing a pressure will look like this: 
  -- 
  --   - `Wind: %n ° at n.d mps`  
  --   - `Wind: %n ° at n.d kps`
  --   
  -- @param #COORDINATE self
  -- @param height (Optional) parameter specifying the height ASL. The minimum height will be always be the land height since the wind is zero below the ground.
  -- @return #string Wind direction and strength according the measurement system @{Settings}.
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
  -- @param #COORDINATE TargetCoordinate The target COORDINATE.
  -- @return DCS#Distance Distance The distance in meters.
  function COORDINATE:Get3DDistance( TargetCoordinate )
    local TargetVec3 = TargetCoordinate:GetVec3()
    local SourceVec3 = self:GetVec3()
    return ( ( TargetVec3.x - SourceVec3.x ) ^ 2 + ( TargetVec3.y - SourceVec3.y ) ^ 2 + ( TargetVec3.z - SourceVec3.z ) ^ 2 ) ^ 0.5
  end


  --- Provides a bearing text in degrees.
  -- @param #COORDINATE self
  -- @param #number AngleRadians The angle in randians.
  -- @param #number Precision The precision.
  -- @param Core.Settings#SETTINGS Settings
  -- @return #string The bearing text in degrees.
  function COORDINATE:GetBearingText( AngleRadians, Precision, Settings )

    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS

    local AngleDegrees = UTILS.Round( UTILS.ToDegree( AngleRadians ), Precision )
  
    local s = string.format( '%03d°', AngleDegrees ) 
    
    return s
  end

  --- Provides a distance text expressed in the units of measurement.
  -- @param #COORDINATE self
  -- @param #number Distance The distance in meters.
  -- @param Core.Settings#SETTINGS Settings
  -- @return #string The distance text expressed in the units of measurement.
  function COORDINATE:GetDistanceText( Distance, Settings )

    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS

    local DistanceText

    if Settings:IsMetric() then
      DistanceText = " for " .. UTILS.Round( Distance / 1000, 2 ) .. " km"
    else
      DistanceText = " for " .. UTILS.Round( UTILS.MetersToNM( Distance ), 2 ) .. " miles"
    end
    
    return DistanceText
  end

  --- Return the altitude text of the COORDINATE.
  -- @param #COORDINATE self
  -- @return #string Altitude text.
  function COORDINATE:GetAltitudeText( Settings )
    local Altitude = self.y
    local Settings = Settings or _SETTINGS
    if Altitude ~= 0 then
      if Settings:IsMetric() then
        return " at " .. UTILS.Round( self.y, -3 ) .. " meters"
      else
        return " at " .. UTILS.Round( UTILS.MetersToFeet( self.y ), -3 ) .. " feet"
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
  -- @return #string The BR Text
  function COORDINATE:GetBRText( AngleRadians, Distance, Settings )

    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS

    local BearingText = self:GetBearingText( AngleRadians, 0, Settings )
    local DistanceText = self:GetDistanceText( Distance, Settings )
    
    local BRText = BearingText .. DistanceText

    return BRText
  end

  --- Provides a Bearing / Range / Altitude string
  -- @param #COORDINATE self
  -- @param #number AngleRadians The angle in randians
  -- @param #number Distance The distance
  -- @param Core.Settings#SETTINGS Settings
  -- @return #string The BRA Text
  function COORDINATE:GetBRAText( AngleRadians, Distance, Settings )

    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS

    local BearingText = self:GetBearingText( AngleRadians, 0, Settings )
    local DistanceText = self:GetDistanceText( Distance, Settings )
    local AltitudeText = self:GetAltitudeText( Settings )

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

  --- Add a Distance in meters from the COORDINATE horizontal plane, with the given angle, and calculate the new COORDINATE.
  -- @param #COORDINATE self
  -- @param DCS#Distance Distance The Distance to be added in meters.
  -- @param DCS#Angle Angle The Angle in degrees.
  -- @return #COORDINATE The new calculated COORDINATE.
  function COORDINATE:Translate( Distance, Angle )
    local SX = self.x
    local SZ = self.z
    local Radians = Angle / 180 * math.pi
    local TX = Distance * math.cos( Radians ) + SX
    local TZ = Distance * math.sin( Radians ) + SZ

    return COORDINATE:New( TX, self.y, TZ )
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
  -- @return #table The route point.
  function COORDINATE:WaypointAir( AltType, Type, Action, Speed, SpeedLocked, airbase, DCSTasks, description )
    self:F2( { AltType, Type, Action, Speed, SpeedLocked } )
    
    -- Defaults
    AltType=AltType or "RADIO"
    if SpeedLocked==nil then
      SpeedLocked=true
    end
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
    -- Set speed/ETA.
    RoutePoint.speed = Speed/3.6
    RoutePoint.speed_locked = SpeedLocked
    RoutePoint.ETA=nil
    RoutePoint.ETA_locked = false    
    -- Waypoint description.
    RoutePoint.name=description
    -- Airbase parameters for takeoff and landing points.
    if airbase then
      local AirbaseID = airbase:GetID()
      local AirbaseCategory = airbase:GetDesc().category
      if AirbaseCategory == Airbase.Category.SHIP or AirbaseCategory == Airbase.Category.HELIPAD then
        RoutePoint.linkUnit = AirbaseID
        RoutePoint.helipadId = AirbaseID
      elseif AirbaseCategory == Airbase.Category.AIRDROME then
        RoutePoint.airdromeId = AirbaseID       
      else
        self:T("ERROR: Unknown airbase category in COORDINATE:WaypointAir()!")
      end  
    end        
    

    --  ["task"] =
    --  {
    --      ["id"] = "ComboTask",
    --      ["params"] =
    --      {
    --          ["tasks"] =
    --          {
    --          }, -- end of ["tasks"]
    --      }, -- end of ["params"]
    --  }, -- end of ["task"]

    -- Waypoint tasks.
    RoutePoint.task = {}
    RoutePoint.task.id = "ComboTask"
    RoutePoint.task.params = {}
    RoutePoint.task.params.tasks = DCSTasks or {}

    self:T({RoutePoint=RoutePoint})
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
  -- @return #table The route point.
  -- @usage
  -- 
  --    LandingZone = ZONE:New( "LandingZone" )
  --    LandingCoord = LandingZone:GetCoordinate()
  --    LandingWaypoint = LandingCoord:WaypointAirLanding( 60 )
  --    HeliGroup:Route( { LandWaypoint }, 1 ) -- Start landing the helicopter in one second.
  -- 
  function COORDINATE:WaypointAirLanding( Speed )
    return self:WaypointAir( nil, COORDINATE.WaypointType.Land, COORDINATE.WaypointAction.Landing, Speed )
  end
  
  
  
  
  --- Build an ground type route point.
  -- @param #COORDINATE self
  -- @param #number Speed (optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #string Formation (optional) The route point Formation, which is a text string that specifies exactly the Text in the Type of the route point, like "Vee", "Echelon Right".
  -- @return #table The route point.
  function COORDINATE:WaypointGround( Speed, Formation )
    self:F2( { Formation, Speed } )

 
    local RoutePoint = {}
    RoutePoint.x = self.x
    RoutePoint.y = self.z

    RoutePoint.action = Formation or ""
    --RoutePoint.formation_template = Formation and "" or nil


    RoutePoint.speed = ( Speed or 20 ) / 3.6
    RoutePoint.speed_locked = true

    --  ["task"] =
    --  {
    --      ["id"] = "ComboTask",
    --      ["params"] =
    --      {
    --          ["tasks"] =
    --          {
    --          }, -- end of ["tasks"]
    --      }, -- end of ["params"]
    --  }, -- end of ["task"]


    RoutePoint.task = {}
    RoutePoint.task.id = "ComboTask"
    RoutePoint.task.params = {}
    RoutePoint.task.params.tasks = {}


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
      local category=airbase:GetDesc().category
      if Category and Category==category or Category==nil then
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
    
    return closest,distmin
  end
  
  --- Gets the nearest parking spot.
  -- @param #COORDINATE self
  -- @param Wrapper.Airbase#AIRBASE airbase (Optional) Search only parking spots at this airbase.
  -- @param Wrapper.Airbase#Terminaltype terminaltype (Optional) Type of the terminal. Default any execpt valid spawn points on runway.
  -- @param #boolean free (Optional) If true, returns the closest free spot. If false, returns the closest occupied spot. If nil, returns the closest spot regardless of free or occupied.
  -- @return Core.Point#COORDINATE Coordinate of the nearest parking spot.
  -- @return #number Terminal ID.
  -- @return #number Distance to closest parking spot in meters.
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
          else    
            if _dist<_distmin then
              _distmin=_dist
              _closest=_coord
              _termID=_spot.TerminalID
            end
          end
                          
        end         
      end
    end
   
    return _closest, _termID, _distmin
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
    local vec2={ x = x, y = y }
    return COORDINATE:NewFromVec2(vec2)
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
        
        if MarkPath then
          coord:MarkToAll(string.format("Path segment %d.", _i))
        end
        if SmokePath then
          coord:SmokeGreen()
        end
      end
            
      -- Mark/smoke endpoints
      if IncludeEndpoints then
        if MarkPath then
          COORDINATE:NewFromVec2(path[1]):MarkToAll("Path Initinal Point")
          COORDINATE:NewFromVec2(path[1]):MarkToAll("Path Final Point")        
        end
        if SmokePath then
          COORDINATE:NewFromVec2(path[1]):SmokeBlue()
          COORDINATE:NewFromVec2(path[#path]):SmokeBlue()
        end
      end
            
    else
      self:E("Path is nil. No valid path on road could be found.")
      GotPath=false
    end
 
    -- Include end point, which might not be on road.
    if IncludeEndpoints then
      Path[#Path+1]=ToCoord
    end
    
    -- Sum up distances.
    if #Path>=2 then
      for i=1,#Path-1 do
        Way=Way+Path[i+1]:Get2DDistance(Path[i])
      end
    else
      -- There are cases where no path on road can be found.
      return nil,nil
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

  --- Checks if the surface type is road.
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
  -- @param #number ExplosionIntensity Intensity of the explosion in kg TNT.
  function COORDINATE:Explosion( ExplosionIntensity )
    self:F2( { ExplosionIntensity } )
    trigger.action.explosion( self:GetVec3(), ExplosionIntensity )
  end

  --- Creates an illumination bomb at the point.
  -- @param #COORDINATE self
  -- @param #number power
  function COORDINATE:IlluminationBomb(power)
    self:F2()
    trigger.action.illuminationBomb( self:GetVec3(), power )
  end


  --- Smokes the point in a color.
  -- @param #COORDINATE self
  -- @param Utilities.Utils#SMOKECOLOR SmokeColor
  function COORDINATE:Smoke( SmokeColor )
    self:F2( { SmokeColor } )
    trigger.action.smoke( self:GetVec3(), SmokeColor )
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
  -- @param Utilities.Utils#BIGSMOKEPRESET preset Smoke preset (0=small smoke and fire, 1=medium smoke and fire, 2=large smoke and fire, 3=huge smoke and fire, 4=small smoke, 5=medium smoke, 6=large smoke, 7=huge smoke).
  -- @param #number density (Optional) Smoke density. Number in [0,...,1]. Default 0.5.
  function COORDINATE:BigSmokeAndFire( preset, density )
    self:F2( { preset=preset, density=density } )
    density=density or 0.5
    trigger.action.effectSmokeBig( self:GetVec3(), preset, density )
  end

  --- Small smoke and fire at the coordinate.
  -- @param #COORDINATE self
  -- @number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  function COORDINATE:BigSmokeAndFireSmall( density )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.SmallSmokeAndFire, density)
  end

  --- Medium smoke and fire at the coordinate.
  -- @param #COORDINATE self
  -- @number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  function COORDINATE:BigSmokeAndFireMedium( density )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.MediumSmokeAndFire, density)
  end
  
  --- Large smoke and fire at the coordinate.
  -- @param #COORDINATE self
  -- @number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  function COORDINATE:BigSmokeAndFireLarge( density )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.LargeSmokeAndFire, density)
  end

  --- Huge smoke and fire at the coordinate.
  -- @param #COORDINATE self
  -- @number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  function COORDINATE:BigSmokeAndFireHuge( density )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.HugeSmokeAndFire, density)
  end
  
  --- Small smoke at the coordinate.
  -- @param #COORDINATE self
  -- @number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  function COORDINATE:BigSmokeSmall( density )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.SmallSmoke, density)
  end
  
  --- Medium smoke at the coordinate.
  -- @param #COORDINATE self
  -- @number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  function COORDINATE:BigSmokeMedium( density )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.MediumSmoke, density)
  end

  --- Large smoke at the coordinate.
  -- @param #COORDINATE self
  -- @number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  function COORDINATE:BigSmokeLarge( density )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.LargeSmoke, density)
  end
  
  --- Huge smoke at the coordinate.
  -- @param #COORDINATE self
  -- @number density (Optional) Smoke density. Number between 0 and 1. Default 0.5.
  function COORDINATE:BigSmokeHuge( density )
    self:F2( { density=density } )
    density=density or 0.5
    self:BigSmokeAndFire(BIGSMOKEPRESET.HugeSmoke, density)
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
    --   RemoveMark( MarkID ) -- The mark is now removed
    function COORDINATE:RemoveMark( MarkID )
      trigger.action.removeMark( MarkID )
    end
  
  end -- Markings
  

  --- Returns if a Coordinate has Line of Sight (LOS) with the ToCoordinate.
  -- @param #COORDINATE self
  -- @param #COORDINATE ToCoordinate
  -- @return #boolean true If the ToCoordinate has LOS with the Coordinate, otherwise false.
  function COORDINATE:IsLOS( ToCoordinate )

    -- Measurement of visibility should not be from the ground, so Adding a hypotethical 2 meters to each Coordinate.
    local FromVec3 = self:GetVec3()
    FromVec3.y = FromVec3.y + 2

    local ToVec3 = ToCoordinate:GetVec3()
    ToVec3.y = ToVec3.y + 2

    local IsLOS = land.isVisible( FromVec3, ToVec3 )

    return IsLOS
  end


  --- Returns if a Coordinate is in a certain Radius of this Coordinate in 2D plane using the X and Z axis.
  -- @param #COORDINATE self
  -- @param #COORDINATE ToCoordinate The coordinate that will be tested if it is in the radius of this coordinate.
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


  --- Return a BR string from a COORDINATE to the COORDINATE.
  -- @param #COORDINATE self
  -- @param #COORDINATE FromCoordinate The coordinate to measure the distance and the bearing from.
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The BR text.
  function COORDINATE:ToStringBR( FromCoordinate, Settings )
    local DirectionVec3 = FromCoordinate:GetDirectionVec3( self )
    local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
    local Distance = self:Get2DDistance( FromCoordinate )
    return "BR, " .. self:GetBRText( AngleRadians, Distance, Settings )
  end

  --- Return a BRAA string from a COORDINATE to the COORDINATE.
  -- @param #COORDINATE self
  -- @param #COORDINATE FromCoordinate The coordinate to measure the distance and the bearing from.
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The BR text.
  function COORDINATE:ToStringBRA( FromCoordinate, Settings )
    local DirectionVec3 = FromCoordinate:GetDirectionVec3( self )
    local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
    local Distance = FromCoordinate:Get2DDistance( self )
    local Altitude = self:GetAltitudeText()
    return "BRA, " .. self:GetBRAText( AngleRadians, Distance, Settings )
  end

  --- Return a BULLS string out of the BULLS of the coalition to the COORDINATE.
  -- @param #COORDINATE self
  -- @param DCS#coalition.side Coalition The coalition.
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The BR text.
  function COORDINATE:ToStringBULLS( Coalition, Settings )
    local BullsCoordinate = COORDINATE:NewFromVec3( coalition.getMainRefPoint( Coalition ) )
    local DirectionVec3 = BullsCoordinate:GetDirectionVec3( self )
    local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
    local Distance = self:Get2DDistance( BullsCoordinate )
    local Altitude = self:GetAltitudeText()
    return "BULLS, " .. self:GetBRText( AngleRadians, Distance, Settings )
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

  --- Provides a Lat Lon string in Degree Minute Second format.
  -- @param #COORDINATE self
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The LL DMS Text
  function COORDINATE:ToStringLLDMS( Settings ) 

    local LL_Accuracy = Settings and Settings.LL_Accuracy or _SETTINGS.LL_Accuracy
    local lat, lon = coord.LOtoLL( self:GetVec3() )
    return "LL DMS, " .. UTILS.tostringLL( lat, lon, LL_Accuracy, true )
  end

  --- Provides a Lat Lon string in Degree Decimal Minute format.
  -- @param #COORDINATE self
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The LL DDM Text
  function COORDINATE:ToStringLLDDM( Settings )

    local LL_Accuracy = Settings and Settings.LL_Accuracy or _SETTINGS.LL_Accuracy
    local lat, lon = coord.LOtoLL( self:GetVec3() )
    return "LL DDM, " .. UTILS.tostringLL( lat, lon, LL_Accuracy, false )
  end

  --- Provides a MGRS string
  -- @param #COORDINATE self
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The MGRS Text
  function COORDINATE:ToStringMGRS( Settings ) --R2.1 Fixes issue #424.

    local MGRS_Accuracy = Settings and Settings.MGRS_Accuracy or _SETTINGS.MGRS_Accuracy
    local lat, lon = coord.LOtoLL( self:GetVec3() )
    local MGRS = coord.LLtoMGRS( lat, lon )
    return "MGRS, " .. UTILS.tostringMGRS( MGRS, MGRS_Accuracy )
  end

  --- Provides a coordinate string of the point, based on a coordinate format system:
  --   * Uses default settings in COORDINATE.
  --   * Can be overridden if for a GROUP containing x clients, a menu was selected to override the default.
  -- @param #COORDINATE self
  -- @param #COORDINATE ReferenceCoord The refrence coordinate.
  -- @param #string ReferenceName The refrence name.
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The coordinate Text in the configured coordinate system.
  function COORDINATE:ToStringFromRP( ReferenceCoord, ReferenceName, Controllable, Settings )
  
    self:F2( { ReferenceCoord = ReferenceCoord, ReferenceName = ReferenceName } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS
    
    local IsAir = Controllable and Controllable:IsAirPlane() or false

    if IsAir then
      local DirectionVec3 = ReferenceCoord:GetDirectionVec3( self )
      local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
      local Distance = self:Get2DDistance( ReferenceCoord )
      return "Targets are the last seen " .. self:GetBRText( AngleRadians, Distance, Settings ) .. " from " .. ReferenceName
    else
      local DirectionVec3 = ReferenceCoord:GetDirectionVec3( self )
      local AngleRadians =  self:GetAngleRadians( DirectionVec3 )
      local Distance = self:Get2DDistance( ReferenceCoord )
      return "Target are located " .. self:GetBRText( AngleRadians, Distance, Settings ) .. " from " .. ReferenceName
    end
    
    return nil

  end

  --- Provides a coordinate string of the point, based on the A2G coordinate format system.
  -- @param #COORDINATE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @return #string The coordinate Text in the configured coordinate system.
  function COORDINATE:ToStringA2G( Controllable, Settings ) 
  
    self:F2( { Controllable = Controllable and Controllable:GetName() } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    if Settings:IsA2G_BR()  then
      -- If no Controllable is given to calculate the BR from, then MGRS will be used!!!
      if Controllable then
        local Coordinate = Controllable:GetCoordinate()
        return Controllable and self:ToStringBR( Coordinate, Settings ) or self:ToStringMGRS( Settings )
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
  -- @return #string The coordinate Text in the configured coordinate system.
  function COORDINATE:ToStringA2A( Controllable, Settings ) -- R2.2
  
    self:F2( { Controllable = Controllable and Controllable:GetName() } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    if Settings:IsA2A_BRAA()  then
      if Controllable then
        local Coordinate = Controllable:GetCoordinate()
        return self:ToStringBRA( Coordinate, Settings ) 
      else
        return self:ToStringMGRS( Settings )
      end
    end
    if Settings:IsA2A_BULLS() then
      local Coalition = Controllable:GetCoalition()
      return self:ToStringBULLS( Coalition, Settings )
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
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable
  -- @param Core.Settings#SETTINGS Settings (optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
  -- @param Tasking.Task#TASK Task The task for which coordinates need to be calculated.
  -- @return #string The coordinate Text in the configured coordinate system.
  function COORDINATE:ToString( Controllable, Settings, Task )
  
    self:F2( { Controllable = Controllable and Controllable:GetName() } )

    local Settings = Settings or ( Controllable and _DATABASE:GetPlayerSettings( Controllable:GetPlayerName() ) ) or _SETTINGS

    local ModeA2A = false
    self:E('A2A false')
    
    if Task then
      self:E('Task ' .. Task.ClassName )
      if Task:IsInstanceOf( TASK_A2A ) then
        ModeA2A = true
        self:E('A2A true')
      else
        if Task:IsInstanceOf( TASK_A2G ) then
          ModeA2A = false
        else
          if Task:IsInstanceOf( TASK_CARGO ) then
            ModeA2A = false
          else
            ModeA2A = false
          end
        end
      end
    else
      local IsAir = Controllable and Controllable:IsAirPlane() or false
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
  function COORDINATE:ToStringPressure( Controllable, Settings ) -- R2.3
  
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

end

do -- POINT_VEC3

  --- The POINT_VEC3 class
  -- @type POINT_VEC3
  -- @field #number x The x coordinate in 3D space.
  -- @field #number y The y coordinate in 3D space.
  -- @field #number z The z coordiante in 3D space.
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
  -- @return #number The x coodinate.
  function POINT_VEC3:GetX()
    return self.x
  end

  --- Return the y coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @return #number The y coodinate.
  function POINT_VEC3:GetY()
    return self.y
  end

  --- Return the z coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @return #number The z coodinate.
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
  -- @param #number x The x coordinate value to add to the current x coodinate.
  -- @return #POINT_VEC3
  function POINT_VEC3:AddX( x )
    self.x = self.x + x
    return self
  end

  --- Add to the y coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @param #number y The y coordinate value to add to the current y coodinate.
  -- @return #POINT_VEC3
  function POINT_VEC3:AddY( y )
    self.y = self.y + y
    return self
  end

  --- Add to the z coordinate of the POINT_VEC3.
  -- @param #POINT_VEC3 self
  -- @param #number z The z coordinate value to add to the current z coodinate.
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

  --- @type POINT_VEC2
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
  -- @return #number The x coodinate.
  function POINT_VEC2:GetX()
    return self.x
  end

  --- Return the y coordinate of the POINT_VEC2.
  -- @param #POINT_VEC2 self
  -- @return #number The y coodinate.
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
  -- @return #number The x coodinate.
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
  -- @return #number The y coodinate.
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


