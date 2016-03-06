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
	
function GROUP:New( DCSGroup )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( DCSGroup:getName() )

	self.DCSGroup = DCSGroup
	self.GroupName = DCSGroup:getName()
	self.GroupID = DCSGroup:getID()
	self.Controller = DCSGroup:getController()

	return self
end


function GROUP:NewFromName( GroupName )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( GroupName )

	self.DCSGroup = Group.getByName( GroupName )
	self.GroupName = self.DCSGroup:getName()
	self.GroupID = self.DCSGroup:getID()

	return self
end

function GROUP:GetDCSGroup()
	self:T( { self.GroupName } )
	return self.DCSGroup
end

function GROUP:GetDCSUnit( UnitNumber )
	self:T( { self.GroupName, UnitNumber } )
	return self.DCSGroup:getUnit( UnitNumber )

end

function GROUP:Activate()
	self:T( { self.GroupName } )
	trigger.action.activateGroup( self:GetDCSGroup() )
	return self:GetDCSGroup()
end

function GROUP:GetName()
	self:T( self.GroupName )
	
	return self.GroupName
end

function GROUP:GetPoint()
	self:T( self.GroupName )
	
	local GroupPoint = self:GetUnit(1):GetPoint()
	self:T( GroupPoint )
	return GroupPoint
end


function GROUP:Destroy()
	self:T( self.GroupName )
	
	for Index, UnitData in pairs( self.DCSGroup:getUnits() ) do
		self:CreateEventCrash( timer.getTime(), UnitData )
	end
	
	self.DCSGroup:destroy()
end




function GROUP:GetUnit( UnitNumber )
	self:T( { self.GroupName, UnitNumber } )
	return UNIT:New( self.DCSGroup:getUnit( UnitNumber ) )
end


function GROUP:IsAir()
self:T()
	
	local IsAirResult = self.DCSGroup:getCategory() == Group.Category.AIRPLANE or self.DCSGroup:getCategory() == Group.Category.HELICOPTER

	self:T( IsAirResult )
	return IsAirResult
end

function GROUP:IsAlive()
self:T()
	
	local IsAliveResult = self.DCSGroup and self.DCSGroup:isExist()

	self:T( IsAliveResult )
	return IsAliveResult
end


function GROUP:AllOnGround()
self:T()

	local AllOnGroundResult = true

	for Index, UnitData in pairs( self.DCSGroup:getUnits() ) do
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
	
	for Index, UnitData in pairs( self.DCSGroup:getUnits() ) do

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
trace.f( self.ClassName, { self.GroupName, Point, Duration, EmbarkingGroup.DCSGroup } )

	local Controller = self:_GetController()
	
	trace.i( self.ClassName, EmbarkingGroup.GroupID )
	trace.i( self.ClassName, EmbarkingGroup.DCSGroup:getID() )
	trace.i( self.ClassName, EmbarkingGroup.DCSGroup.id )
	
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

function GROUP:Route( GoPoints )
self:T( GoPoints )

	local Points = routines.utils.deepCopy( GoPoints )
	local MissionTask = { id = 'Mission', params = { route = { points = Points, }, }, }
	
	--self.Controller.setTask( self.Controller, MissionTask )

	routines.scheduleFunction( self.Controller.setTask, { self.Controller, MissionTask}, timer.getTime() + 1 )
	
	return self
end

function GROUP:RouteToZone( Zone, Randomize, Speed, Formation )
	self:T( Zone )
	
	local GroupPoint = self:GetPoint()
	
	local PointFrom = {}
	PointFrom.x = GroupPoint.x
	PointFrom.y = GroupPoint.y
	PointFrom.type = "Turning Point"
	PointFrom.action = "Cone"
	PointFrom.speed = 20 / 1.6
	

	local PointTo = {}
	local ZonePoint 
	
	if Randomize then
		ZonePoint = Zone:GetRandomPoint()
	else
		ZonePoint = Zone:GetPoint()
	end

	PointTo.x = ZonePoint.x
	PointTo.y = ZonePoint.y
	PointTo.type = "Turning Point"
	
	if Formation then
		PointTo.action = Formation
	else
		PointTo.action = "Cone"
	end
	
	if Speed then
		PointTo.speed = Speed
	else
		PointTo.speed = 20 / 1.6
	end
	
	local Points = { PointFrom, PointTo }
	
	self:T( Points )
	
	self:Route( Points )
	
	return self
end

function GROUP:CopyRoute( Begin, End, Randomize, Radius )
self:T( { Begin, End } )

	local Points = {}
	
	-- Could be a Spawned Group
	local GroupName = string.match( self:GetName(), ".*#" )
	if GroupName then
		GroupName = GroupName:sub( 1, -2 )
	else
		GroupName = self:GetName()
	end
	
	self:T( { GroupName } )
	
	local Template = _Database.Groups[GroupName].Template
	
	if Template then
		if not Begin then
			Begin = 0
		end
		if not End then
			End = 0
		end
	
		for TPointID = Begin + 1, #Template.route.points - End do
			if Template.route.points[TPointID] then
				Points[#Points+1] = routines.utils.deepCopy( Template.route.points[TPointID] )
				if Randomize then
					if not Radius then
						Radius = 500
					end
					Points[#Points].x = Points[#Points].x + math.random( Radius * -1, Radius )
					Points[#Points].y = Points[#Points].y + math.random( Radius * -1, Radius )
				end	
			end
		end
		return Points
	end
	
	return nil
end


function GROUP:_GetController()

	return self.DCSGroup:getController()

end
