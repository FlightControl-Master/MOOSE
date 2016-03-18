--- A GROUP class abstraction of a DCSGroup class. 
-- The GROUP class will take an abstraction of the DCSGroup class, providing more methods that can be done with a GROUP.
-- 
-- 
-- @module GROUP
-- @extends BASE#BASE

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )
Include.File( "Unit" )

--- The GROUP class
-- @type GROUP
-- @field #Group DCSGroup The DCS group class.
-- @field #string GroupName The name of the group.
-- @field #number GroupID the ID of the group.
-- @field #table Controller The controller of the group.
GROUP = {
	ClassName = "GROUP",
	GroupName = "",
	GroupID = 0,
	Controller = nil,
	}
	
--- A DCSGroup
-- @type Group
-- @field id_ The ID of the group in DCS

GROUPS = {}
	
--- Create a new GROUP from a DCSGroup
-- @param self
-- @param #Group DCSGroup The DCS Group
-- @return #GROUP self
function GROUP:New( DCSGroup )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( DCSGroup:getName() )

	self.DCSGroup = DCSGroup
	self.GroupName = DCSGroup:getName()
	self.GroupID = DCSGroup:getID()
	self.Controller = DCSGroup:getController()

	return self
end


--- Create a new GROUP from an existing group name.
-- @param self
-- @param GroupName The name of the DCS Group.
-- @return #GROUP self
function GROUP:NewFromName( GroupName )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( GroupName )

	self.DCSGroup = Group.getByName( GroupName )
	if self.DCSGroup then
		self.GroupName = self.DCSGroup:getName()
		self.GroupID = self.DCSGroup:getID()
    self.Controller = self.DCSGroup:getController()
	end

	return self
end

--- Create a new GROUP from an existing DCSUnit in the mission.
-- @param self
-- @param DCSUnit The DCSUnit.
-- @return #GROUP self
function GROUP:NewFromDCSUnit( DCSUnit )
  local self = BASE:Inherit( self, BASE:New() )
  self:T( DCSUnit )

  self.DCSGroup = DCSUnit:getGroup()
  if self.DCSGroup then
    self.GroupName = self.DCSGroup:getName()
    self.GroupID = self.DCSGroup:getID()
    self.Controller = self.DCSGroup:getController()
  end

  return self
end

--- Gets the DCSGroup of the GROUP.
-- @param self
-- @return #Group The DCSGroup.
function GROUP:GetDCSGroup()
	self:T( { self.GroupName } )
	self.DCSGroup = Group.getByName( self.GroupName )
	return self.DCSGroup
end



--- Gets the DCS Unit of the GROUP.
-- @param self
-- @param #number UnitNumber The unit index to be returned from the GROUP.
-- @return #Unit The DCS Unit.
function GROUP:GetDCSUnit( UnitNumber )
	self:T( { self.GroupName, UnitNumber } )
	return self.DCSGroup:getUnit( UnitNumber )

end

--- Activates a GROUP.
-- @param self
function GROUP:Activate()
	self:T( { self.GroupName } )
	trigger.action.activateGroup( self:GetDCSGroup() )
	return self:GetDCSGroup()
end

--- Gets the name of the GROUP.
-- @param self
-- @return #string The name of the GROUP.
function GROUP:GetName()
	self:T( self.GroupName )
	
	return self.GroupName
end

--- Gets the current Point of the GROUP in VEC2 format.
-- @return #Vec2 Current x and Y position of the group.
function GROUP:GetPoint()
	self:T( self.GroupName )
	
	local GroupPoint = self:GetUnit(1):GetPoint()
	self:T( GroupPoint )
	return GroupPoint
end

--- Destroy a GROUP
-- Note that this destroy method also raises a destroy event at run-time.
-- So all event listeners will catch the destroy event of this GROUP.
-- @param self
function GROUP:Destroy()
	self:T( self.GroupName )
	
	for Index, UnitData in pairs( self.DCSGroup:getUnits() ) do
		self:CreateEventCrash( timer.getTime(), UnitData )
	end
	
	self.DCSGroup:destroy()
end



--- Gets the DCS Unit.
-- @param self
-- @param #number UnitNumber The number of the Unit to be returned.
-- @return #Unit The DCS Unit.
function GROUP:GetUnit( UnitNumber )
	self:T( { self.GroupName, UnitNumber } )
	return UNIT:New( self.DCSGroup:getUnit( UnitNumber ) )
end

--- Returns if the group is of an air category.
-- If the group is a helicopter or a plane, then this method will return true, otherwise false.
-- @param self
-- @return #boolean Air category evaluation result.
function GROUP:IsAir()
self:T()
	
	local IsAirResult = self.DCSGroup:getCategory() == Group.Category.AIRPLANE or self.DCSGroup:getCategory() == Group.Category.HELICOPTER

	self:T( IsAirResult )
	return IsAirResult
end

--- Returns if the group is alive.
-- When the group exists at run-time, this method will return true, otherwise false.
-- @param self
-- @return #boolean Alive result.
function GROUP:IsAlive()
self:T()
	
	local IsAliveResult = self.DCSGroup and self.DCSGroup:isExist()

	self:T( IsAliveResult )
	return IsAliveResult
end

--- Returns if all units of the group are on the ground or landed.
-- If all units of this group are on the ground, this function will return true, otherwise false.
-- @param self
-- @return #boolean All units on the ground result.
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

--- Returns the current maximum velocity of the group.
-- Each unit within the group gets evaluated, and the maximum velocity (= the unit which is going the fastest) is returned.
-- @param self
-- @return #number Maximum velocity found.
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


--- Returns the current minimum height of the group.
-- Each unit within the group gets evaluated, and the minimum height (= the unit which is the lowest elevated) is returned.
-- @param self
-- @return #number Minimum height found.
function GROUP:GetMinHeight()
  self:T()

end


--- Returns the current maximum height of the group.
-- Each unit within the group gets evaluated, and the maximum height (= the unit which is the highest elevated) is returned.
-- @param self
-- @return #number Maximum height found.
function GROUP:GetMaxHeight()
self:T()

end


--- Land the group at a Vec2Point.
-- @param self
-- @param #Vec2 Point The point where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @return #GROUP self
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

--- Move the group to a Vec2 Point, wait for a defined duration and embark a group.
-- @param self
-- @param #Vec2 Point The point where to wait.
-- @param #number Duration The duration in seconds to wait.
-- @param EmbarkingGroup The group to be embarked.
-- @return #GROUP self
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

--- Move to a defined Vec2 Point, and embark to a group when arrived within a defined Radius.
-- @param self
-- @param #Vec2 Point The point where to wait.
-- @param #number Radius The radius of the embarking zone around the Point.
-- @return #GROUP self
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

--- Make the group to follow a given route.
-- @param self
-- @param #table GoPoints A table of Route Points.
-- @return #GROUP self 
function GROUP:Route( GoPoints )
self:T( GoPoints )

	local Points = routines.utils.deepCopy( GoPoints )
	local MissionTask = { id = 'Mission', params = { route = { points = Points, }, }, }
	
	--self.Controller.setTask( self.Controller, MissionTask )

	routines.scheduleFunction( self.Controller.setTask, { self.Controller, MissionTask}, timer.getTime() + 1 )
	
	return self
end

--- Route the group to a given zone.
-- The group final destination point can be randomized.
-- A speed can be given in km/h.
-- A given formation can be given.
-- @param self
-- @param ZONE#ZONE Zone The zone where to route to.
-- @param #boolean Randomize Defines whether to target point gets randomized within the Zone.
-- @param #number Speed The speed.
-- @param BASE#FORMATION Formation The formation string.
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

--- Return the route of a group.
-- @param self
-- @param #number Begin The route point from where the copy will start. The base route point is 0.
-- @param #number End The route point where the copy will end. The End point is the last point - the End point. The last point has base 0.
-- @param #boolean Randomize Randomization of the route, when true.
-- @param #number Radius When randomization is on, the randomization is within the radius. 
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

--- Get the controller for the GROUP.
function GROUP:_GetController()

	return self.DCSGroup:getController()

end
