--- This module contains the UNIT class.
-- 
-- 1) @{Unit#UNIT} class, extends @{Base#BASE}
-- ===========================================
-- The @{Unit#UNIT} class is a wrapper class to handle the DCS Unit objects:
-- 
--  * Support all DCS Unit APIs.
--  * Enhance with Unit specific APIs not in the DCS Unit API set.
--  * Handle local Unit Controller.
--  * Manage the "state" of the DCS Unit.
--  
--  
-- 1.1) UNIT reference methods
-- ----------------------
-- For each DCS Unit object alive within a running mission, a UNIT wrapper object (instance) will be created within the _@{DATABASE} object.
-- This is done at the beginning of the mission (when the mission starts), and dynamically when new DCS Unit objects are spawned (using the @{SPAWN} class).
--  
-- The UNIT class **does not contain a :New()** method, rather it provides **:Find()** methods to retrieve the object reference
-- using the DCS Unit or the DCS UnitName.
-- 
-- Another thing to know is that UNIT objects do not "contain" the DCS Unit object. 
-- The UNIT methods will reference the DCS Unit object by name when it is needed during API execution.
-- If the DCS Unit object does not exist or is nil, the UNIT methods will return nil and log an exception in the DCS.log file.
--  
-- The UNIT class provides the following functions to retrieve quickly the relevant UNIT instance:
-- 
--  * @{#UNIT.Find}(): Find a UNIT instance from the _DATABASE object using a DCS Unit object.
--  * @{#UNIT.FindByName}(): Find a UNIT instance from the _DATABASE object using a DCS Unit name.
--  
-- IMPORTANT: ONE SHOULD NEVER SANATIZE these UNIT OBJECT REFERENCES! (make the UNIT object references nil).
-- 
-- 1.2) DCS UNIT APIs
-- ------------------
-- The DCS Unit APIs are used extensively within MOOSE. The UNIT class has for each DCS Unit API a corresponding method.
-- To be able to distinguish easily in your code the difference between a UNIT API call and a DCS Unit API call,
-- the first letter of the method is also capitalized. So, by example, the DCS Unit method @{DCSUnit#Unit.getName}()
-- is implemented in the UNIT class as @{#UNIT.GetName}().
-- 
-- 1.3) Smoke, Flare Units
-- -----------------------
-- The UNIT class provides methods to smoke or flare units easily. 
-- The @{#UNIT.SmokeBlue}(), @{#UNIT.SmokeGreen}(),@{#UNIT.SmokeOrange}(), @{#UNIT.SmokeRed}(), @{#UNIT.SmokeRed}() methods
-- will smoke the unit in the corresponding color. Note that smoking a unit is done at the current position of the DCS Unit. 
-- When the DCS Unit moves for whatever reason, the smoking will still continue!
-- The @{#UNIT.FlareGreen}(), @{#UNIT.FlareRed}(), @{#UNIT.FlareWhite}(), @{#UNIT.FlareYellow}() 
-- methods will fire off a flare in the air with the corresponding color. Note that a flare is a one-off shot and its effect is of very short duration.
-- 
-- 1.4) Location Position, Point
-- -----------------------------
-- The UNIT class provides methods to obtain the current point or position of the DCS Unit.
-- The @{#UNIT.GetPointVec2}(), @{#UNIT.GetPointVec3}() will obtain the current **location** of the DCS Unit in a Vec2 (2D) or a **point** in a Vec3 (3D) vector respectively.
-- If you want to obtain the complete **3D position** including oriëntation and direction vectors, consult the @{#UNIT.GetPositionVec3}() method respectively.
-- 
-- 1.5) Test if alive
-- ------------------
-- The @{#UNIT.IsAlive}(), @{#UNIT.IsActive}() methods determines if the DCS Unit is alive, meaning, it is existing and active.
-- 
-- 1.6) Test for proximity
-- -----------------------
-- The UNIT class contains methods to test the location or proximity against zones or other objects.
-- 
-- ### 1.6.1) Zones
-- To test whether the Unit is within a **zone**, use the @{#UNIT.IsInZone}() or the @{#UNIT.IsNotInZone}() methods. Any zone can be tested on, but the zone must be derived from @{Zone#ZONE_BASE}. 
-- 
-- ### 1.6.2) Units
-- Test if another DCS Unit is within a given radius of the current DCS Unit, use the @{#UNIT.OtherUnitInRadius}() method.
-- 
-- @module Unit
-- @author FlightControl





--- The UNIT class
-- @type UNIT
-- @extends Base#BASE
-- @field #UNIT.FlareColor FlareColor
-- @field #UNIT.SmokeColor SmokeColor
UNIT = {
	ClassName="UNIT",
	CategoryName = { 
    [Unit.Category.AIRPLANE]      = "Airplane",
    [Unit.Category.HELICOPTER]    = "Helicoper",
    [Unit.Category.GROUND_UNIT]   = "Ground Unit",
    [Unit.Category.SHIP]          = "Ship",
    [Unit.Category.STRUCTURE]     = "Structure",
    },
  FlareColor = {
    Green = trigger.flareColor.Green,
    Red = trigger.flareColor.Red,
    White = trigger.flareColor.White,
    Yellow = trigger.flareColor.Yellow
    },
  SmokeColor = {
    Green = trigger.smokeColor.Green,
    Red = trigger.smokeColor.Red,
    White = trigger.smokeColor.White,
    Orange = trigger.smokeColor.Orange,
    Blue = trigger.smokeColor.Blue
    },
	}

--- FlareColor
-- @type UNIT.FlareColor
-- @field Green
-- @field Red
-- @field White
-- @field Yellow

--- SmokeColor
-- @type UNIT.SmokeColor
-- @field Green
-- @field Red
-- @field White
-- @field Orange
-- @field Blue

-- Registration.
	
--- Create a new UNIT from DCSUnit.
-- @param #UNIT self
-- @param DCSUnit#Unit DCSUnit
-- @param Database#DATABASE Database
-- @return Unit#UNIT
function UNIT:Register( UnitName )

  local self = BASE:Inherit( self, BASE:New() )
  self:F2( UnitName )
  self.UnitName = UnitName
  return self
end

-- Reference methods.

--- Finds a UNIT from the _DATABASE using a DCSUnit object.
-- @param #UNIT self
-- @param DCSUnit#Unit DCSUnit An existing DCS Unit object reference.
-- @return Unit#UNIT self
function UNIT:Find( DCSUnit )

  local UnitName = DCSUnit:getName()
  local UnitFound = _DATABASE:FindUnit( UnitName )
  return UnitFound
end

--- Find a UNIT in the _DATABASE using the name of an existing DCS Unit.
-- @param #UNIT self
-- @param #string UnitName The Unit Name.
-- @return Unit#UNIT self
function UNIT:FindByName( UnitName )
  
  local UnitFound = _DATABASE:FindUnit( UnitName )
  return UnitFound
end

function UNIT:GetDCSUnit()
  local DCSUnit = Unit.getByName( self.UnitName )
  
  if DCSUnit then
    return DCSUnit
  end
  
  self:E( "Unit " .. self.UnitName .. " not found!" )
  return nil
end

--- Returns coalition of the Unit.
-- @param Unit#UNIT self
-- @return DCSCoalitionObject#coalition.side The side of the coalition.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetCoalition()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitCoalition = DCSUnit:getCoalition()
    self:T3( UnitCoalition )
    return UnitCoalition
  end 
  
  return nil
end

--- Returns country of the Unit.
-- @param Unit#UNIT self
-- @return DCScountry#country.id The country identifier.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetCountry()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitCountry = DCSUnit:getCountry()
    self:T3( UnitCountry )
    return UnitCountry
  end 
  
  return nil
end
 

--- Returns DCS Unit object name. 
-- The function provides access to non-activated units too.
-- @param Unit#UNIT self
-- @return #string The name of the DCS Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetName()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitName = self.UnitName
    return UnitName
  end 
  
  return nil
end


--- Returns if the unit is alive.
-- @param Unit#UNIT self
-- @return #boolean true if Unit is alive.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:IsAlive()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitIsAlive = DCSUnit:isExist()
    return UnitIsAlive
  end	
	
	return false
end

--- Returns if the unit is activated.
-- @param Unit#UNIT self
-- @return #boolean true if Unit is activated.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:IsActive()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
  
    local UnitIsActive = DCSUnit:isActive()
    return UnitIsActive 
  end

  return nil
end

--- Returns if the unit is located above a runway.
-- @param Unit#UNIT self
-- @return #boolean true if Unit is above a runway.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:IsAboveRunway()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
  
    local PointVec2 = self:GetPointVec2()
    local SurfaceType = land.getSurfaceType( PointVec2 )
    local IsAboveRunway = SurfaceType == land.SurfaceType.RUNWAY
  
    self:T2( IsAboveRunway )
    return IsAboveRunway
  end

  return nil
end



--- Returns name of the player that control the unit or nil if the unit is controlled by A.I.
-- @param Unit#UNIT self
-- @return #string Player Name
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetPlayerName()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
  
    local PlayerName = DCSUnit:getPlayerName()
    if PlayerName == nil then
      PlayerName = ""
    end
    return PlayerName
  end

  return nil
end

--- Returns the unit's unique identifier.
-- @param Unit#UNIT self
-- @return DCSUnit#Unit.ID Unit ID
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetID()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitID = DCSUnit:getID()
    return UnitID
  end	

  return nil
end

--- Returns the unit's number in the group. 
-- The number is the same number the unit has in ME. 
-- It may not be changed during the mission. 
-- If any unit in the group is destroyed, the numbers of another units will not be changed.
-- @param Unit#UNIT self
-- @return #number The Unit number. 
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetNumber()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitNumber = DCSUnit:getNumber()
    return UnitNumber
  end

  return nil
end

--- Returns the unit's group if it exist and nil otherwise.
-- @param Unit#UNIT self
-- @return Group#GROUP The Group of the Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetGroup()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitGroup = GROUP:Find( DCSUnit:getGroup() )
    return UnitGroup
  end

  return nil
end


--- Returns the unit's callsign - the localized string.
-- @param Unit#UNIT self
-- @return #string The Callsign of the Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetCallSign()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitCallSign = DCSUnit:getCallsign()
    return UnitCallSign
  end
  
  return nil
end

--- Returns the unit's health. Dead units has health <= 1.0.
-- @param Unit#UNIT self
-- @return #number The Unit's health value.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetLife()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitLife = DCSUnit:getLife()
    return UnitLife
  end
  
  return nil
end

--- Returns the Unit's initial health.
-- @param Unit#UNIT self
-- @return #number The Unit's initial health value.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetLife0()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitLife0 = DCSUnit:getLife0()
    return UnitLife0
  end
  
  return nil
end

--- Returns relative amount of fuel (from 0.0 to 1.0) the unit has in its internal tanks. If there are additional fuel tanks the value may be greater than 1.0.
-- @param Unit#UNIT self
-- @return #number The relative amount of fuel (from 0.0 to 1.0).
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetFuel()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitFuel = DCSUnit:getFuel()
    return UnitFuel
  end
  
  return nil
end

--- Returns the Unit's ammunition.
-- @param Unit#UNIT self
-- @return DCSUnit#Unit.Ammo
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetAmmo()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitAmmo = DCSUnit:getAmmo()
    return UnitAmmo
  end
  
  return nil
end

--- Returns the unit sensors.
-- @param Unit#UNIT self
-- @return DCSUnit#Unit.Sensors
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetSensors()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitSensors = DCSUnit:getSensors()
    return UnitSensors
  end
  
  return nil
end

-- Need to add here a function per sensortype
--  unit:hasSensors(Unit.SensorType.RADAR, Unit.RadarType.AS)

--- Returns two values:
-- 
--  * First value indicates if at least one of the unit's radar(s) is on.
--  * Second value is the object of the radar's interest. Not nil only if at least one radar of the unit is tracking a target.
-- @param Unit#UNIT self
-- @return #boolean  Indicates if at least one of the unit's radar(s) is on.
-- @return DCSObject#Object The object of the radar's interest. Not nil only if at least one radar of the unit is tracking a target.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetRadar()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitRadarOn, UnitRadarObject = DCSUnit:getRadar()
    return UnitRadarOn, UnitRadarObject
  end
  
  return nil, nil
end

-- Need to add here functions to check if radar is on and which object etc.

--- Returns unit descriptor. Descriptor type depends on unit category.
-- @param Unit#UNIT self
-- @return DCSUnit#Unit.Desc The Unit descriptor.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetDesc()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitDesc = DCSUnit:getDesc()
    self:T2( UnitDesc )
    return UnitDesc
  end
  
  self:E( "Unit " .. self.UnitName .. "not found!" )
  return nil
end


--- Returns the type name of the DCS Unit.
-- @param Unit#UNIT self
-- @return #string The type name of the DCS Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetTypeName()
	self:F2( self.UnitName )
	
  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitTypeName = DCSUnit:getTypeName()
    self:T3( UnitTypeName )
    return UnitTypeName
  end

	return nil
end



--- Returns the prefix name of the DCS Unit. A prefix name is a part of the name before a '#'-sign.
-- DCS Units spawned with the @{SPAWN} class contain a '#'-sign to indicate the end of the (base) DCS Unit name. 
-- The spawn sequence number and unit number are contained within the name after the '#' sign. 
-- @param Unit#UNIT self
-- @return #string The name of the DCS Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetPrefix()
	self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
	
  if DCSUnit then
  	local UnitPrefix = string.match( self.UnitName, ".*#" ):sub( 1, -2 )
  	self:T3( UnitPrefix )
  	return UnitPrefix
  end
  
  return nil
end



--- Returns the @{DCSTypes#Vec2} vector indicating the point in 2D of the DCS Unit within the mission.
-- @param Unit#UNIT self
-- @return DCSTypes#Vec2 The 2D point vector of the DCS Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetPointVec2()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
	
  if DCSUnit then
  	local UnitPointVec3 = DCSUnit:getPosition().p
  	
  	local UnitPointVec2 = {}
  	UnitPointVec2.x = UnitPointVec3.x
  	UnitPointVec2.y = UnitPointVec3.z
  
  	self:T2( UnitPointVec2 )
  	return UnitPointVec2
  end
  
  return nil
end


--- Returns the @{DCSTypes#Vec3} vector indicating the point in 3D of the DCS Unit within the mission.
-- @param Unit#UNIT self
-- @return DCSTypes#Vec3 The 3D point vector of the DCS Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetPointVec3()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
  	local UnitPointVec3 = DCSUnit:getPosition().p
  	self:T3( UnitPointVec3 )
  	return UnitPointVec3
  end
	
	return nil
end

--- Returns the @{DCSTypes#Position3} position vectors indicating the point and direction vectors in 3D of the DCS Unit within the mission.
-- @param Unit#UNIT self
-- @return DCSTypes#Position The 3D position vectors of the DCS Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetPositionVec3()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitPosition = DCSUnit:getPosition()
    self:T3( UnitPosition )
    return UnitPosition
  end
  
  return nil
end

--- Returns the DCS Unit velocity vector.
-- @param Unit#UNIT self
-- @return DCSTypes#Vec3 The velocity vector
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetVelocity()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitVelocityVec3 = DCSUnit:getVelocity()
    self:T3( UnitVelocityVec3 )
    return UnitVelocityVec3
  end
  
  return nil
end

-- Is functions

--- Returns true if the unit is within a @{Zone}.
-- @param #UNIT self
-- @param Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the unit is within the @{Zone#ZONE_BASE}
function UNIT:IsInZone( Zone )
  self:F2( { self.UnitName, Zone } )

  local IsInZone = Zone:IsPointVec3InZone( self:GetPointVec3() )
  
  self:T( { IsInZone } )
  return IsInZone 
end

--- Returns true if the unit is not within a @{Zone}.
-- @param #UNIT self
-- @param Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the unit is not within the @{Zone#ZONE_BASE}
function UNIT:IsNotInZone( Zone )
  self:F2( { self.UnitName, Zone } )

  local IsInZone = not Zone:IsPointVec3InZone( self:GetPointVec3() )
  
  self:T( { IsInZone } )
  return IsInZone 
end

--- Returns true if the DCS Unit is in the air.
-- @param Unit#UNIT self
-- @return #boolean true if in the air.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:InAir()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitInAir = DCSUnit:inAir()
    self:T3( UnitInAir )
    return UnitInAir
  end
  
  return nil
end
 
--- Returns the altitude of the DCS Unit.
-- @param Unit#UNIT self
-- @return DCSTypes#Distance The altitude of the DCS Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetAltitude()
  self:F2()

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitPointVec3 = DCSUnit:getPoint() --DCSTypes#Vec3
    return UnitPointVec3.y
  end
  
  return nil
end 

--- Returns true if there is an **other** DCS Unit within a radius of the current 2D point of the DCS Unit.
-- @param Unit#UNIT self
-- @param Unit#UNIT AwaitUnit The other UNIT wrapper object.
-- @param Radius The radius in meters with the DCS Unit in the centre.
-- @return true If the other DCS Unit is within the radius of the 2D point of the DCS Unit. 
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:OtherUnitInRadius( AwaitUnit, Radius )
	self:F2( { self.UnitName, AwaitUnit.UnitName, Radius } )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
  	local UnitPos = self:GetPointVec3()
  	local AwaitUnitPos = AwaitUnit:GetPointVec3()
  
  	if  (((UnitPos.x - AwaitUnitPos.x)^2 + (UnitPos.z - AwaitUnitPos.z)^2)^0.5 <= Radius) then
  		self:T3( "true" )
  		return true
  	else
  		self:T3( "false" )
  		return false
  	end
  end

	return nil
end

--- Returns the DCS Unit category name as defined within the DCS Unit Descriptor.
-- @param Unit#UNIT self
-- @return #string The DCS Unit Category Name
function UNIT:GetCategoryName()
  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitCategoryName = self.CategoryName[ self:GetDesc().category ]
    return UnitCategoryName
  end
  
  return nil
end

--- Signal a flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:Flare( FlareColor )
  self:F2()
  trigger.action.signalFlare( self:GetPointVec3(), FlareColor , 0 )
end

--- Signal a white flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareWhite()
  self:F2()
  trigger.action.signalFlare( self:GetPointVec3(), trigger.flareColor.White , 0 )
end

--- Signal a yellow flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareYellow()
  self:F2()
  trigger.action.signalFlare( self:GetPointVec3(), trigger.flareColor.Yellow , 0 )
end

--- Signal a green flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareGreen()
  self:F2()
  trigger.action.signalFlare( self:GetPointVec3(), trigger.flareColor.Green , 0 )
end

--- Signal a red flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareRed()
  self:F2()
  trigger.action.signalFlare( self:GetPointVec3(), trigger.flareColor.Red, 0 )
end

--- Smoke the UNIT.
-- @param #UNIT self
function UNIT:Smoke( SmokeColor )
  self:F2()
  trigger.action.smoke( self:GetPointVec3(), SmokeColor )
end

--- Smoke the UNIT Green.
-- @param #UNIT self
function UNIT:SmokeGreen()
  self:F2()
  trigger.action.smoke( self:GetPointVec3(), trigger.smokeColor.Green )
end

--- Smoke the UNIT Red.
-- @param #UNIT self
function UNIT:SmokeRed()
  self:F2()
  trigger.action.smoke( self:GetPointVec3(), trigger.smokeColor.Red )
end

--- Smoke the UNIT White.
-- @param #UNIT self
function UNIT:SmokeWhite()
  self:F2()
  trigger.action.smoke( self:GetPointVec3(), trigger.smokeColor.White )
end

--- Smoke the UNIT Orange.
-- @param #UNIT self
function UNIT:SmokeOrange()
  self:F2()
  trigger.action.smoke( self:GetPointVec3(), trigger.smokeColor.Orange )
end

--- Smoke the UNIT Blue.
-- @param #UNIT self
function UNIT:SmokeBlue()
  self:F2()
  trigger.action.smoke( self:GetPointVec3(), trigger.smokeColor.Blue )
end

-- Is methods

--- Returns if the unit is of an air category.
-- If the unit is a helicopter or a plane, then this method will return true, otherwise false.
-- @param #UNIT self
-- @return #boolean Air category evaluation result.
function UNIT:IsAir()
  self:F2()
  
  local UnitDescriptor = self.DCSUnit:getDesc()
  self:T3( { UnitDescriptor.category, Unit.Category.AIRPLANE, Unit.Category.HELICOPTER } )
  
  local IsAirResult = ( UnitDescriptor.category == Unit.Category.AIRPLANE ) or ( UnitDescriptor.category == Unit.Category.HELICOPTER )

  self:T3( IsAirResult )
  return IsAirResult
end

