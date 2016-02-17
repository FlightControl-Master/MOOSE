--- GROUP Classes
-- @classmod GROUP

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

GROUPS = {}


GROUP = {
	ClassName="GROUP",
	}
	
function GROUP:New( _Group )
trace.f( self.ClassName, _Group:getName() )

	local self = BASE:Inherit( self, BASE:New() )

	self._Group = _Group
	self.GroupName = _Group:getName()
	self.GroupID = _Group:getID()

	return self
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
