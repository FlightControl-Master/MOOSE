--- UNIT Classes
-- @classmod UNIT

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

UNITS = {}


UNIT = {
	ClassName="UNIT",
	}
	
function UNIT:New( DCSUnit )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( DCSUnit:getName() )

	self.DCSUnit = DCSUnit
	self.UnitName = DCSUnit:getName()
	self.UnitID = DCSUnit:getID()

	return self
end

function UNIT:IsAlive()
	self:T( self.UnitName )
	
	return ( self.DCSUnit and self.DCSUnit:isExist() )
end


function UNIT:GetName()
	self:T( self.UnitName )
	
	return self.UnitName
end

function UNIT:GetTypeName()
	self:T( self.UnitName )
	
	return self.DCSUnit:getTypeName()
end

function UNIT:GetPrefix()
	self:T( self.UnitName )
	
	local UnitPrefix = string.match( self.UnitName, ".*#" ):sub( 1, -2 )
	self:T( UnitPrefix )

	return UnitPrefix
end


function UNIT:GetCallSign()
	self:T( self.UnitName )
	
	return self.DCSUnit:getCallsign()
end


function UNIT:GetPoint()
	self:T( self.UnitName )
	
	local UnitPos = self.DCSUnit:getPosition().p
	
	local UnitPoint = {}
	UnitPoint.x = UnitPos.x
	UnitPoint.y = UnitPos.z

	self:T( UnitPoint )
	return UnitPoint
end


function UNIT:GetPositionVec3()
	self:T( self.UnitName )
	
	local UnitPos = self.DCSUnit:getPosition().p

	self:T( UnitPos )
	return UnitPos
end

function UNIT:OtherUnitInRadius( AwaitUnit, Radius )
	self:T( { self.UnitName, AwaitUnit.UnitName, Radius } )

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

