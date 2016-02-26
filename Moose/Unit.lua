--- UNIT Classes
-- @classmod UNIT

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

UNITS = {}


UNIT = {
	ClassName="UNIT",
	}
	
function UNIT:New( _Unit )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( _Unit:getName() )

	self._Unit = _Unit
	self.UnitName = _Unit:getName()
	self.UnitID = _Unit:getID()

	return self
end

function UNIT:GetCallSign()
	self:T( self.UnitName )
	
	return self._Unit:getCallsign()
end

function UNIT:GetPositionVec3()
	self:T( self.UnitName )
	
	local UnitPos = self._Unit:getPosition().p

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

