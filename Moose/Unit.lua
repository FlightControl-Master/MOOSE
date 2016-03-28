--- UNIT Classes
-- @module UNIT

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

--- The UNIT class
-- @type UNIT
-- @Extends Base#BASE
UNIT = {
	ClassName="UNIT",
	CategoryName = { 
    [Unit.Category.AIRPLANE]      = "Airplane",
    [Unit.Category.HELICOPTER]    = "Helicoper",
    [Unit.Category.GROUND_UNIT]   = "Ground Unit",
    [Unit.Category.SHIP]          = "Ship",
    [Unit.Category.STRUCTURE]     = "Structure",
    }
	}
	
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

