--- GROUP Classes
-- @classmod GROUP

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )
Include.File( "Unit" )

GROUPS = {}


GROUP = {
	ClassName="GROUP",
	}
	
function GROUP:New( _Group )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( _Group:getName() )

	self._Group = _Group
	self.GroupName = _Group:getName()
	self.GroupID = _Group:getID()

	return self
end


function GROUP:NewFromName( GroupName )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( GroupName )

	self._Group = Group.getByName( GroupName )
	self.GroupName = self._Group:getName()
	self.GroupID = self._Group:getID()

	return self
end


function GROUP:GetName()
	self:T( self.GroupName )
	
	return self.GroupName
end


function GROUP:Destroy()
	self:T( self.GroupName )
	
	for Index, UnitData in pairs( self._Group:getUnits() ) do
		self:CreateEventCrash( timer.getTime(), UnitData )
	end
	
	self._Group:destroy()
end


function GROUP:GetUnit( UnitNumber )
	self:T( self.GroupName )
	return UNIT:New( self._Group:getUnit( UnitNumber ) )
end


function GROUP:IsAir()
self:T()
	
	local IsAirResult = self._Group:getCategory() == Group.Category.AIRPLANE or self._Group:getCategory() == Group.Category.HELICOPTER

	self:T( IsAirResult )
	return IsAirResult
end


function GROUP:AllOnGround()
self:T()

	local AllOnGroundResult = true

	for Index, UnitData in pairs( self._Group:getUnits() ) do
		if UnitData:inAir() then
			AllOnGroundResult = false
		end
	end
	
	self:T( AllOnGroundResult )
	return AllOnGroundResult
end


function GROUP:GetMaxVelocity()
self:T()

	local MaxVelocity = 0
	
	for Index, UnitData in pairs( self._Group:getUnits() ) do

		local Velocity = UnitData:getVelocity()
		local VelocityTotal = math.abs( Velocity.x ) + math.abs( Velocity.y ) + math.abs( Velocity.z )

		if VelocityTotal < MaxVelocity then
			MaxVelocity = VelocityTotal
		end 
	end
	
	return MaxVelocity
end


function GROUP:GetHeight()
self:T()


end


function GROUP:Land( Point, Duration )
trace.f( self.ClassName, { self.GroupName, Point, Duration } )

	local Controller = self:_GetController()
	
	if Duration and Duration > 0 then
		Controller:pushTask( { id = 'Land', params = { point = Point, durationFlag = true, duration = Duration } } )
	else
		Controller:pushTask( { id = 'Land', params = { point = Point, durationFlag = false } } )
	end

	return self
end


function GROUP:Embarking( Point, Duration, EmbarkingGroup )
trace.f( self.ClassName, { self.GroupName, Point, Duration, EmbarkingGroup._Group } )

	local Controller = self:_GetController()
	
	trace.i( self.ClassName, EmbarkingGroup.GroupID )
	trace.i( self.ClassName, EmbarkingGroup._Group:getID() )
	trace.i( self.ClassName, EmbarkingGroup._Group.id )
	
	Controller:pushTask( { id = 'Embarking', 
	                       params = { x = Point.x, 
	                                  y = Point.y, 
									  duration = Duration, 
									  groupsForEmbarking = { EmbarkingGroup.GroupID },
									  durationFlag = true,
									  distributionFlag = false,
									  distribution = {},
									} 
						  } 
						)
	
	return self
end


function GROUP:EmbarkToTransport( Point, Radius )
trace.f( self.ClassName, { self.GroupName, Point, Radius } )

	local Controller = self:_GetController()
	
	Controller:pushTask( { id = 'EmbarkToTransport', 
	                       params = { x = Point.x, 
						              y = Point.y, 
									  zoneRadius = Radius,
									} 
						  } 
						)

	return self
end


function GROUP:_GetController()

	return self._Group:getController()

end
