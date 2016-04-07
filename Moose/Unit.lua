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
-- @return Unit#UNIT
function UNIT:New( DCSUnit )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( DCSUnit:getName() )

	self.DCSUnit = DCSUnit
	self.UnitName = DCSUnit:getName()
	self.UnitID = DCSUnit:getID()

	return self
end

function UNIT:IsAlive()
	self:F( self.UnitName )
	
	return ( self.DCSUnit and self.DCSUnit:isExist() )
end


function UNIT:GetDCSUnit()
	self:F( self.DCSUnit )
	
	return self.DCSUnit
end

function UNIT:GetID()
	self:F( self.UnitID )
	
	return self.UnitID
end


function UNIT:GetName()
	self:F( self.UnitName )
	
	return self.UnitName
end

function UNIT:GetTypeName()
	self:F( self.UnitName )
	
	return self.DCSUnit:getTypeName()
end

function UNIT:GetPrefix()
	self:F( self.UnitName )
	
	local UnitPrefix = string.match( self.UnitName, ".*#" ):sub( 1, -2 )
	self:T( UnitPrefix )

	return UnitPrefix
end


function UNIT:GetCallSign()
	self:F( self.UnitName )
	
	return self.DCSUnit:getCallsign()
end


function UNIT:GetPointVec2()
	self:F( self.UnitName )
	
	local UnitPos = self.DCSUnit:getPosition().p
	
	local UnitPoint = {}
	UnitPoint.x = UnitPos.x
	UnitPoint.y = UnitPos.z

	self:T( UnitPoint )
	return UnitPoint
end


function UNIT:GetPositionVec3()
	self:F( self.UnitName )
	
	local UnitPos = self.DCSUnit:getPosition().p

	self:T( UnitPos )
	return UnitPos
end

function UNIT:OtherUnitInRadius( AwaitUnit, Radius )
	self:F( { self.UnitName, AwaitUnit.UnitName, Radius } )

	local UnitPos = self:GetPositionVec3()
	local AwaitUnitPos = AwaitUnit:GetPositionVec3()

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

function UNIT:GetCategoryName()
  return self.CategoryName[ self.DCSUnit:getDesc().category ]
end

--- Signal a flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:Flare( FlareColor )
  self:F()
  trigger.action.signalFlare( self:GetPositionVec3(), FlareColor , 0 )
end

--- Signal a white flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareWhite()
  self:F()
  trigger.action.signalFlare( self:GetPositionVec3(), trigger.flareColor.White , 0 )
end

--- Signal a yellow flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareYellow()
  self:F()
  trigger.action.signalFlare( self:GetPositionVec3(), trigger.flareColor.Yellow , 0 )
end

--- Signal a green flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareGreen()
  self:F()
  trigger.action.signalFlare( self:GetPositionVec3(), trigger.flareColor.Green , 0 )
end

--- Signal a red flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareRed()
  self:F()
  trigger.action.signalFlare( self:GetPositionVec3(), trigger.flareColor.Red, 0 )
end

--- Smoke the UNIT.
-- @param #UNIT self
function UNIT:Smoke( SmokeColor )
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), SmokeColor )
end

--- Smoke the UNIT Green.
-- @param #UNIT self
function UNIT:SmokeGreen()
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), trigger.smokeColor.Green )
end

--- Smoke the UNIT Red.
-- @param #UNIT self
function UNIT:SmokeRed()
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), trigger.smokeColor.Red )
end

--- Smoke the UNIT White.
-- @param #UNIT self
function UNIT:SmokeWhite()
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), trigger.smokeColor.White )
end

--- Smoke the UNIT Orange.
-- @param #UNIT self
function UNIT:SmokeOrange()
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), trigger.smokeColor.Orange )
end

--- Smoke the UNIT Blue.
-- @param #UNIT self
function UNIT:SmokeBlue()
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), trigger.smokeColor.Blue )
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

