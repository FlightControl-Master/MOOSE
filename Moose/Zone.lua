--- ZONE Classes
-- @module Zone

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

--- The ZONE class
-- @type ZONE
-- @Extends Base#BASE
ZONE = {
	ClassName="ZONE",
	}
	
function ZONE:New( ZoneName )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( ZoneName )

	local Zone = trigger.misc.getZone( ZoneName )
	
	if not Zone then
		error( "Zone " .. ZoneName .. " does not exist." )
		return nil
	end
	
	self.Zone = Zone
	self.ZoneName = ZoneName
	
	return self
end

function ZONE:GetPointVec2()
	self:F( self.ZoneName )

	local Zone = trigger.misc.getZone( self.ZoneName )
	local Point = { x = Zone.point.x, y = Zone.point.z }

	self:T( { Zone, Point } )
	
	return Point	
end

function ZONE:GetRandomPointVec2()
	self:F( self.ZoneName )

	local Point = {}

	local Zone = trigger.misc.getZone( self.ZoneName )

	Point.x = Zone.point.x + math.random( Zone.radius * -1, Zone.radius )
	Point.y = Zone.point.z + math.random( Zone.radius * -1, Zone.radius )
	
	self:T( { Zone, Point } )
	
	return Point
end

function ZONE:GetRadius()
	self:F( self.ZoneName )

	local Zone = trigger.misc.getZone( self.ZoneName )

	self:T( { Zone } )

	return Zone.radius
end

