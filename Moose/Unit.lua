--- UNIT Classes
-- @module Unit

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

--- The UNIT class
-- @type UNIT
-- @Extends Base#BASE
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
	
--- Create a new UNIT from DCSUnit.
-- @param #UNIT self
-- @param DCSUnit#Unit DCSUnit
-- @param Database#DATABASE Database
-- @return Unit#UNIT
function UNIT:Register( UnitName )

  local self = BASE:Inherit( self, BASE:New() )
  self:F( UnitName )
  self.UnitName = UnitName
  return self
end


--- Finds a UNIT from the _DATABASE using a DCSUnit object.
-- @param #UNIT self
-- @param DCSUnit#Unit DCSUnit
-- @return Unit#UNIT
function UNIT:Find( DCSUnit )

  local UnitName = DCSUnit:getName()
  local UnitFound = _DATABASE:FindUnit( UnitName )
  return UnitFound
end

--- Find a UNIT in the _DATABASE using the name of the UNIT.
-- @param #UNIT self
-- @param #string Unit Name
-- @return Unit#UNIT
function UNIT:FindByName( UnitName )
--  self:F( UnitName )
  
  local FoundUnit = _DATABASE:FindUnit( UnitName )
  return FoundUnit
end

function UNIT:GetDCSUnit()
  local DCSUnit = Unit.getByName( self.UnitName )
  
  if DCSUnit then
    return DCSUnit
  end
    
  return nil
end

--- Returns coalition of the Unit.
-- @param Unit#UNIT self
-- @return DCSCoalitionObject#coalition.side
function UNIT:GetCoalition()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitCoalition = DCSUnit:getCoalition()
    self:T( UnitCoalition )
    return UnitCoalition
  end 
  
  return nil
end

--- Returns country of the Unit.
-- @param Unit#UNIT self
-- @return DCScountry#country.id The country identifyer.
function UNIT:GetCountry()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitCountry = DCSUnit:getCountry()
    self:T( UnitCountry )
    return UnitCountry
  end 
  
  return nil
end
 

--- Returns unit object by the name assigned to the unit in Mission Editor. 
-- If there is unit with such name or the unit is destroyed the function will return nil. 
-- The function provides access to non-activated units too.
--   
function UNIT:GetName()
  self:F( self.UnitName )

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
function UNIT:IsAlive()
  self:F( self.UnitName )

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
function UNIT:IsActive()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
  
    local UnitIsActive = DCSUnit:isActive()
    return UnitIsActive 
  end

  return nil
end

--- Returns name of the player that control the unit or nil if the unit is controlled by A.I.
-- @param Unit#UNIT self
-- @return #string Player Name
function UNIT:GetPlayerName()
  self:F( self.UnitName )

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
function UNIT:GetID()
  self:F( self.UnitName )

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
function UNIT:GetNumber()
  self:F( self.UnitName )

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
function UNIT:GetGroup()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitGroup = DCSUnit:getGroup()
    return UnitGroup
  end

  return nil
end


--- Returns the unit's callsign - the localized string.
-- @param Unit#UNIT self
-- @return #string The Callsign of the Unit.
function UNIT:GetCallSign()
  self:F( self.UnitName )

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
function UNIT:GetLife()
  self:F( self.UnitName )

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
function UNIT:GetLife0()
  self:F( self.UnitName )

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
function UNIT:GetFuel()
  self:F( self.UnitName )

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
function UNIT:GetAmmo()
  self:F( self.UnitName )

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
function UNIT:GetSensors()
  self:F( self.UnitName )

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
function UNIT:GetRadar()
  self:F( self.UnitName )

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
function UNIT:GetDesc()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitDesc = DCSUnit:getDesc()
    return UnitDesc
  end
  
  return nil
end



function UNIT:GetTypeName()
	self:F( self.UnitName )
	
  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitTypeName = DCSUnit:getTypeName()
    self:T( UnitTypeName )
    return UnitTypeName
  end

	return nil
end

function UNIT:GetPrefix()
	self:F( self.UnitName )
	
	local UnitPrefix = string.match( self.UnitName, ".*#" ):sub( 1, -2 )
	self:T( UnitPrefix )
	return UnitPrefix
end



function UNIT:GetPointVec2()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
	
  if DCSUnit then
  	local UnitPointVec3 = DCSUnit:getPosition().p
  	
  	local UnitPointVec2 = {}
  	UnitPointVec2.x = UnitPointVec3.x
  	UnitPointVec2.y = UnitPointVec3.z
  
  	self:T( UnitPointVec2 )
  	return UnitPointVec2
  end
  
  return nil
end


function UNIT:GetPointVec3()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
  	local UnitPointVec3 = DCSUnit:getPosition().p
  	self:T( UnitPointVec3 )
  	return UnitPointVec3
  end
	
	return nil
end

function UNIT:GetPositionVec3()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitPosition = DCSUnit:getPosition()
    self:T( UnitPosition )
    return UnitPosition
  end
  
  return nil
end

--- Returns the unit's velocity vector.
-- @param Unit#UNIT self
-- @return DCSTypes#Vec3 Velocity Vector
function UNIT:GetVelocity()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitVelocityVec3 = DCSUnit:getVelocity()
    self:T( UnitVelocityVec3 )
    return UnitVelocityVec3
  end
  
  return nil
end
 
--- Returns true if the Unit is in air.
-- @param Unit#UNIT self
-- @return #boolean true if in the air.
function UNIT:InAir()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitInAir = DCSUnit:inAir()
    self:T( UnitInAir )
    return UnitInAir
  end
  
  return nil
end
 
--- Returns the altitude of the UNIT.
-- @param #UNIT self
-- @return DCSTypes#Distance
function UNIT:GetAltitude()
  self:F()

  local DCSUnit = self:GetDCSUnit()
  
  if DCSUnit then
    local UnitPointVec3 = DCSUnit:getPoint() --DCSTypes#Vec3
    return UnitPointVec3.y
  end
  
  return nil
end 

function UNIT:OtherUnitInRadius( AwaitUnit, Radius )
	self:F( { self.UnitName, AwaitUnit.UnitName, Radius } )

	local UnitPos = self:GetPointVec3()
	local AwaitUnitPos = AwaitUnit:GetPointVec3()

	if  (((UnitPos.x - AwaitUnitPos.x)^2 + (UnitPos.z - AwaitUnitPos.z)^2)^0.5 <= Radius) then
		self:T( "true" )
		return true
	else
		self:T( "false" )
		return false
	end

	self:T( "false" )
	return false
end

--- Returns the Unit's Category Name as defined within the Unit's Descriptor.
-- @param Unit#UNIT self
-- @return #string Unit's Category Name
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
  self:F()
  trigger.action.signalFlare( self:GetPointVec3(), FlareColor , 0 )
end

--- Signal a white flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareWhite()
  self:F()
  trigger.action.signalFlare( self:GetPointVec3(), trigger.flareColor.White , 0 )
end

--- Signal a yellow flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareYellow()
  self:F()
  trigger.action.signalFlare( self:GetPointVec3(), trigger.flareColor.Yellow , 0 )
end

--- Signal a green flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareGreen()
  self:F()
  trigger.action.signalFlare( self:GetPointVec3(), trigger.flareColor.Green , 0 )
end

--- Signal a red flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareRed()
  self:F()
  trigger.action.signalFlare( self:GetPointVec3(), trigger.flareColor.Red, 0 )
end

--- Smoke the UNIT.
-- @param #UNIT self
function UNIT:Smoke( SmokeColor )
  self:F()
  trigger.action.smoke( self:GetPointVec3(), SmokeColor )
end

--- Smoke the UNIT Green.
-- @param #UNIT self
function UNIT:SmokeGreen()
  self:F()
  trigger.action.smoke( self:GetPointVec3(), trigger.smokeColor.Green )
end

--- Smoke the UNIT Red.
-- @param #UNIT self
function UNIT:SmokeRed()
  self:F()
  trigger.action.smoke( self:GetPointVec3(), trigger.smokeColor.Red )
end

--- Smoke the UNIT White.
-- @param #UNIT self
function UNIT:SmokeWhite()
  self:F()
  trigger.action.smoke( self:GetPointVec3(), trigger.smokeColor.White )
end

--- Smoke the UNIT Orange.
-- @param #UNIT self
function UNIT:SmokeOrange()
  self:F()
  trigger.action.smoke( self:GetPointVec3(), trigger.smokeColor.Orange )
end

--- Smoke the UNIT Blue.
-- @param #UNIT self
function UNIT:SmokeBlue()
  self:F()
  trigger.action.smoke( self:GetPointVec3(), trigger.smokeColor.Blue )
end

-- Is methods

--- Returns if the unit is of an air category.
-- If the unit is a helicopter or a plane, then this method will return true, otherwise false.
-- @param #UNIT self
-- @return #boolean Air category evaluation result.
function UNIT:IsAir()
  self:F()
  
  local UnitDescriptor = self.DCSUnit:getDesc()
  self:T( { UnitDescriptor.category, Unit.Category.AIRPLANE, Unit.Category.HELICOPTER } )
  
  local IsAirResult = ( UnitDescriptor.category == Unit.Category.AIRPLANE ) or ( UnitDescriptor.category == Unit.Category.HELICOPTER )

  self:T( IsAirResult )
  return IsAirResult
end

