--- A GROUP class abstraction of a DCSGroup class. 
-- The GROUP class will take an abstraction of the DCSGroup class, providing more methods that can be done with a GROUP.
-- @module Group

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )
Include.File( "Unit" )

--- The GROUP class
-- @type GROUP
-- @extends Base#BASE
-- @field DCSGroup#Group DCSGroup The DCS group class.
-- @field #string GroupName The name of the group.
-- @field #number GroupID the ID of the group.
-- @field #table Controller The controller of the group.
GROUP = {
	ClassName = "GROUP",
	GroupName = "",
	GroupID = 0,
	Controller = nil,
	DCSGroup = nil,
	WayPointFunctions = {},
	}
	
--- A DCSGroup
-- @type DCSGroup
-- @field id_ The ID of the group in DCS

--- The GROUPS structure contains references to all the created GROUP instances.
local GROUPS = {}
	
--- Create a new GROUP from a DCSGroup
-- @param #GROUP self
-- @param DCSGroup#Group DCSGroup The DCS Group
-- @return #GROUP self
function GROUP:New( DCSGroup )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( DCSGroup )

	self.DCSGroup = DCSGroup
	if self.DCSGroup and self.DCSGroup:isExist() then
  	self.GroupName = DCSGroup:getName()
  	self.GroupID = DCSGroup:getID()
  	self.Controller = DCSGroup:getController()
  else
    self:E( { "DCSGroup is nil or does not exist, cannot initialize GROUP!", self.DCSGroup } )
  end
  
  GROUPS[self.GroupID] = self

	return self
end

--- Create a new GROUP from an existing group name.
-- @param #GROUP self
-- @param GroupName The name of the DCS Group.
-- @return #GROUP self
function GROUP:NewFromName( GroupName )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( GroupName )

	self.DCSGroup = Group.getByName( GroupName )
	if self.DCSGroup then
		self.GroupName = self.DCSGroup:getName()
		self.GroupID = self.DCSGroup:getID()
    self.Controller = self.DCSGroup:getController()
	end

  GROUPS[self.GroupID] = self

	return self
end

--- Create a new GROUP from an existing DCSUnit in the mission.
-- @param #GROUP self
-- @param DCSUnit The DCSUnit.
-- @return #GROUP self
function GROUP:NewFromDCSUnit( DCSUnit )
  local self = BASE:Inherit( self, BASE:New() )
	self:F( DCSUnit )

  self.DCSGroup = DCSUnit:getGroup()
  if self.DCSGroup then
    self.GroupName = self.DCSGroup:getName()
    self.GroupID = self.DCSGroup:getID()
    self.Controller = self.DCSGroup:getController()
  end

  GROUPS[self.GroupID] = self

  return self
end

--- Retrieve the group mission and allow to place function hooks within the mission waypoint plan.
-- Use the method @{Group#GROUP:WayPointFunction} to define the hook functions for specific waypoints.
-- Use the method @{Group@GROUP:WayPointExecute) to start the execution of the new mission plan.
-- Note that when WayPointInitialize is called, the Mission of the group is RESTARTED!
-- @param #GROUP self
-- @param #number WayPoint
-- @return #GROUP
function GROUP:WayPointInitialize()

  self.WayPoints = self:GetTaskRoute()
  
  return self
end


--- Registers a waypoint function that will be executed when the group moves over the WayPoint.
-- @param #GROUP self
-- @param #number WayPoint The waypoint number. Note that the start waypoint on the route is WayPoint 1!
-- @param #number WayPointIndex When defining multiple WayPoint functions for one WayPoint, use WayPointIndex to set the sequence of actions.
-- @param #function WayPointFunction The waypoint function to be called when the group moves over the waypoint. The waypoint function takes variable parameters.
-- @return #GROUP
function GROUP:WayPointFunction( WayPoint, WayPointIndex, WayPointFunction, ... )
  self:F( { WayPoint, WayPointIndex, WayPointFunction } )
  
  table.insert( self.WayPoints[WayPoint].task.params.tasks, WayPointIndex )
  self.WayPoints[WayPoint].task.params.tasks[WayPointIndex] = self:TaskFunction( WayPoint, WayPointIndex, WayPointFunction, arg )
  return self
end


function GROUP:TaskFunction( WayPoint, WayPointIndex, FunctionString, FunctionArguments )

  local DCSTask
  
  local DCSScript = {}
  DCSScript[#DCSScript+1] = "local MissionGroup = GROUP.FindGroup( ... ) "
  DCSScript[#DCSScript+1] = FunctionString .. "( MissionGroup, " .. table.concat( FunctionArguments, "," ) .. ")"
  
  DCSTask = self:TaskWrappedAction( 
    self:CommandDoScript(
      table.concat( DCSScript )
    ), WayPointIndex
  )
  
  self:T( DCSTask )
  
  return DCSTask

end



--- Executes the WayPoint plan.
-- The function gets a WayPoint parameter, that you can use to restart the mission at a specific WayPoint.
-- Note that when the WayPoint parameter is used, the new start mission waypoint of the group will be 1!
-- @param #GROUP self
-- @param #number WayPoint The WayPoint from where to execute the mission.
-- @param #WaitTime The amount seconds to wait before initiating the mission.
-- @return #GROUP
function GROUP:WayPointExecute( WayPoint, WaitTime )

  if not WayPoint then
    WayPoint = 1
  end
  
  -- When starting the mission from a certain point, the TaskPoints need to be deleted before the given WayPoint.
  for TaskPointID = 1, WayPoint - 1 do
    table.remove( self.WayPoints, 1 )
  end

  self:T( self.WayPoints )
  
  self:SetTask( self:TaskRoute( self.WayPoints ), WaitTime )

  return self
end



--- Gets the DCSGroup of the GROUP.
-- @param #GROUP self
-- @return DCSGroup#Group The DCSGroup.
function GROUP:GetDCSGroup()
	self:F( { self.GroupName } )
	self.DCSGroup = Group.getByName( self.GroupName )
	return self.DCSGroup
end

--- Gets the DCS Unit of the GROUP.
-- @param #GROUP self
-- @param #number UnitNumber The unit index to be returned from the GROUP.
-- @return #Unit The DCS Unit.
function GROUP:GetDCSUnit( UnitNumber )
	self:F( { self.GroupName, UnitNumber } )
	return self.DCSGroup:getUnit( UnitNumber )

end

--- Gets the DCSUnits of the GROUP.
-- @param #GROUP self
-- @return #table The DCSUnits.
function GROUP:GetDCSUnits()
  self:F( { self.GroupName } )
  return self.DCSGroup:getUnits()

end

--- Activates a GROUP.
-- @param #GROUP self
function GROUP:Activate()
	self:F( { self.GroupName } )
	trigger.action.activateGroup( self:GetDCSGroup() )
	return self:GetDCSGroup()
end

--- Gets the ID of the GROUP.
-- @param #GROUP self
-- @return #number The ID of the GROUP.
function GROUP:GetID()
	self:F( self.GroupName )
  
  return self.GroupID
end

--- Gets the name of the GROUP.
-- @param #GROUP self
-- @return #string The name of the GROUP.
function GROUP:GetName()
	self:F( self.GroupName )
	
	return self.GroupName
end

--- Gets the type name of the group.
-- @param #GROUP self
-- @return #string The type name of the group.
function GROUP:GetTypeName()
  self:F( self.GroupName )
  
  return self.DCSGroup:getUnit(1):getTypeName()
end

--- Gets the callsign of the fist unit of the group.
-- @param #GROUP self
-- @return #string The callsign of the first unit of the group.
function GROUP:GetCallsign()
  self:F( self.GroupName )
  
  return self.DCSGroup:getUnit(1):getCallsign()
end

--- Gets the current Point of the GROUP in VEC3 format.
-- @return #Vec3 Current x,y and z position of the group.
function GROUP:GetPointVec2()
	self:F( self.GroupName )
	
	local GroupPoint = self:GetUnit(1):GetPointVec2()
	self:T( GroupPoint )
	return GroupPoint
end

--- Gets the current Point of the GROUP in VEC2 format.
-- @return #Vec2 Current x and y position of the group in the 2D plane.
function GROUP:GetPointVec2()
	self:F( self.GroupName )
  
  local GroupPoint = self:GetUnit(1):GetPointVec2()
  self:T( GroupPoint )
  return GroupPoint
end

--- Gets the current Point of the GROUP in VEC3 format.
-- @return #Vec3 Current Vec3 position of the group.
function GROUP:GetPositionVec3()
	self:F( self.GroupName )
  
  local GroupPoint = self:GetUnit(1):GetPositionVec3()
  self:T( GroupPoint )
  return GroupPoint
end

--- Destroy a GROUP
-- Note that this destroy method also raises a destroy event at run-time.
-- So all event listeners will catch the destroy event of this GROUP.
-- @param #GROUP self
function GROUP:Destroy()
	self:F( self.GroupName )
	
	for Index, UnitData in pairs( self.DCSGroup:getUnits() ) do
		self:CreateEventCrash( timer.getTime(), UnitData )
	end
	
	self.DCSGroup:destroy()
	self.DCSGroup = nil
end

--- Gets the DCS Unit.
-- @param #GROUP self
-- @param #number UnitNumber The number of the Unit to be returned.
-- @return Unit#UNIT The DCS Unit.
function GROUP:GetUnit( UnitNumber )
	self:F( { self.GroupName, UnitNumber } )
	return UNIT:New( self.DCSGroup:getUnit( UnitNumber ) )
end

--- Returns the category name of the group.
-- @param #GROUP self
-- @return #string Category name = Helicopter, Airplane, Ground Unit, Ship
function GROUP:GetCategoryName()
  self:F( self.GroupName )

  local CategoryNames = {
    [Group.Category.AIRPLANE] = "Airplane",
    [Group.Category.HELICOPTER] = "Helicopter",
    [Group.Category.GROUND] = "Ground Unit",
    [Group.Category.SHIP] = "Ship",  
  }
  
  return CategoryNames[self.DCSGroup:getCategory()]
end

-- Is Functions

--- Returns if the group is of an air category.
-- If the group is a helicopter or a plane, then this method will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean Air category evaluation result.
function GROUP:IsAir()
	self:F()
	
	local IsAirResult = self.DCSGroup:getCategory() == Group.Category.AIRPLANE or self.DCSGroup:getCategory() == Group.Category.HELICOPTER

	self:T( IsAirResult )
	return IsAirResult
end

--- Returns if the group is alive.
-- When the group exists at run-time, this method will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean Alive result.
function GROUP:IsAlive()
	self:F()
	
	local IsAliveResult = self.DCSGroup and self.DCSGroup:isExist()

	self:T( IsAliveResult )
	return IsAliveResult
end

--- Returns if the GROUP is a Helicopter.
-- @param #GROUP self
-- @return #boolean true if GROUP are Helicopters.
function GROUP:IsHelicopter()
  self:F2()
  
  local GroupCategory = self.DCSGroup:getCategory()
  self:T2( GroupCategory )
  
  return GroupCategory == Group.Category.HELICOPTER
end

--- Returns if the GROUP are AirPlanes.
-- @param #GROUP self
-- @return #boolean true if GROUP are AirPlanes.
function GROUP:IsAirPlane()
  self:F2()
  
  local GroupCategory = self.DCSGroup:getCategory()
  self:T2( GroupCategory )
  
  return GroupCategory == Group.Category.AIRPLANE
end

--- Returns if the GROUP are Ground troops.
-- @param #GROUP self
-- @return #boolean true if GROUP are Ground troops.
function GROUP:IsGround()
  self:F2()
  
  local GroupCategory = self.DCSGroup:getCategory()
  self:T2( GroupCategory )
  
  return GroupCategory == Group.Category.GROUND
end

--- Returns if the GROUP are Ships.
-- @param #GROUP self
-- @return #boolean true if GROUP are Ships.
function GROUP:IsShip()
  self:F2()
  
  local GroupCategory = self.DCSGroup:getCategory()
  self:T2( GroupCategory )
  
  return GroupCategory == Group.Category.SHIP
end

--- Returns if all units of the group are on the ground or landed.
-- If all units of this group are on the ground, this function will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean All units on the ground result.
function GROUP:AllOnGround()
	self:F()

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
-- @param #GROUP self
-- @return #number Maximum velocity found.
function GROUP:GetMaxVelocity()
	self:F()

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
-- @param #GROUP self
-- @return #number Minimum height found.
function GROUP:GetMinHeight()
	self:F()

end

--- Returns the current maximum height of the group.
-- Each unit within the group gets evaluated, and the maximum height (= the unit which is the highest elevated) is returned.
-- @param #GROUP self
-- @return #number Maximum height found.
function GROUP:GetMaxHeight()
	self:F()

end

-- Tasks

--- Popping current Task from the group.
-- @param #GROUP self
-- @return Group#GROUP self
function GROUP:PopCurrentTask()
	self:F()

  local Controller = self:_GetController()
  
  Controller:popTask()

  return self
end

--- Pushing Task on the queue from the group.
-- @param #GROUP self
-- @return Group#GROUP self
function GROUP:PushTask( DCSTask, WaitTime )
	self:F()

  local Controller = self:_GetController()
  
  -- When a group SPAWNs, it takes about a second to get the group in the simulator. Setting tasks to unspawned groups provides unexpected results.
  -- Therefore we schedule the functions to set the mission and options for the Group.
  -- Controller:pushTask( DCSTask )

  if not WaitTime then
    Controller:pushTask( DCSTask )
  else
    routines.scheduleFunction( Controller.pushTask, { Controller, DCSTask }, timer.getTime() + WaitTime )
  end

  return self
end

--- Clearing the Task Queue and Setting the Task on the queue from the group.
-- @param #GROUP self
-- @return Group#GROUP self
function GROUP:SetTask( DCSTask, WaitTime )
  self:F( { DCSTask } )

  local Controller = self:_GetController()
  
  -- When a group SPAWNs, it takes about a second to get the group in the simulator. Setting tasks to unspawned groups provides unexpected results.
  -- Therefore we schedule the functions to set the mission and options for the Group.
  -- Controller.setTask( Controller, DCSTask )

  if not WaitTime then
    WaitTime = 1
  end
  routines.scheduleFunction( Controller.setTask, { Controller, DCSTask }, timer.getTime() + WaitTime )
  
  return self
end


--- Return a condition section for a controlled task
-- @param #GROUP self
-- @param #Time time
-- @param #string userFlag 
-- @param #boolean userFlagValue 
-- @param #string condition
-- @param #Time duration 
-- @param #number lastWayPoint 
-- return DCSTask#Task
function GROUP:TaskCondition( time, userFlag, userFlagValue, condition, duration, lastWayPoint )
	self:F( { time, userFlag, userFlagValue, condition, duration, lastWayPoint } )
  
  local DCSStopCondition = {}
  DCSStopCondition.time = time
  DCSStopCondition.userFlag = userFlag
  DCSStopCondition.userFlagValue = userFlagValue
  DCSStopCondition.condition = condition
  DCSStopCondition.duration = duration
  DCSStopCondition.lastWayPoint = lastWayPoint
  
  self:T( { DCSStopCondition } )
  return DCSStopCondition 
end

--- Return a Controlled Task taking a Task and a TaskCondition
-- @param #GROUP self
-- @param DCSTask#Task DCSTask
-- @param #DCSStopCondition DCSStopCondition
-- @return DCSTask#Task
function GROUP:TaskControlled( DCSTask, DCSStopCondition )
	self:F( { DCSTask, DCSStopCondition } )

  local DCSTaskControlled
  
  DCSTaskControlled = { 
    id = 'ControlledTask', 
    params = { 
      task = DCSTask, 
      stopCondition = DCSStopCondition 
    } 
  }
  
  self:T( { DCSTaskControlled } )
  return DCSTaskControlled
end

--- Return a Combo Task taking an array of Tasks
-- @param #GROUP self
-- @param #list<DCSTask#Task> DCSTasks
-- @return DCSTask#Task
function GROUP:TaskCombo( DCSTasks )
  self:F( { DCSTasks } )

  local DCSTaskCombo
  
  DCSTaskCombo = { 
    id = 'ComboTask', 
    params = { 
      tasks = DCSTasks
    } 
  }
  
  self:T( { DCSTaskCombo } )
  return DCSTaskCombo
end

--- Return a WrappedAction Task taking a Command 
-- @param #GROUP self
-- @param DCSCommand#Command DCSCommand
-- @return DCSTask#Task
function GROUP:TaskWrappedAction( DCSCommand, Index )
  self:F( { DCSCommand } )

  local DCSTaskWrappedAction
  
  DCSTaskWrappedAction = { 
    id = "WrappedAction",
    enabled = true,
    number = Index,
    auto = false,
    params = {
      action = DCSCommand,
    },
  }

  self:T( { DCSTaskWrappedAction } )
  return DCSTaskWrappedAction
end

--- Orbit at a specified position at a specified alititude during a specified duration with a specified speed.
-- @param #GROUP self
-- @param #Vec2 Point The point to hold the position.
-- @param #number Altitude The altitude to hold the position.
-- @param #number Speed The speed flying when holding the position.
-- @return #GROUP self
function GROUP:TaskOrbitCircleAtVec2( Point, Altitude, Speed )
	self:F( { self.GroupName, Point, Altitude, Speed  } )

--  pattern = enum AI.Task.OribtPattern,
--    point = Vec2,
--    point2 = Vec2,
--    speed = Distance,
--    altitude = Distance
    
  local LandHeight = land.getHeight( Point )
  
  self:T( { LandHeight } )

  local DCSTask = { id = 'Orbit', 
                   params = { pattern = AI.Task.OrbitPattern.CIRCLE, 
                              point = Point, 
                              speed = Speed, 
                              altitude = Altitude + LandHeight
                            } 
                 } 

  
--  local AITask = { id = 'ControlledTask', 
--                   params = { task = { id = 'Orbit', 
--                                       params = { pattern = AI.Task.OrbitPattern.CIRCLE, 
--                                                  point = Point, 
--                                                  speed = Speed, 
--                                                  altitude = Altitude + LandHeight
--                                                } 
--                                     }, 
--                              stopCondition = { duration = Duration 
--                                              } 
--                            } 
--                 }
--               )
               
  return DCSTask
end

--- Orbit at the current position of the first unit of the group at a specified alititude
-- @param #GROUP self
-- @param #number Altitude The altitude to hold the position.
-- @param #number Speed The speed flying when holding the position.
-- @return #GROUP self
function GROUP:TaskOrbitCircle( Altitude, Speed )
	self:F( { self.GroupName, Altitude, Speed } )

  local GroupPoint = self:GetPointVec2()
  
  return self:TaskOrbitCircleAtVec2( GroupPoint, Altitude, Speed )
end



--- Hold position at the current position of the first unit of the group.
-- @param #GROUP self
-- @param #number Duration The maximum duration in seconds to hold the position.
-- @return #GROUP self
function GROUP:TaskHoldPosition()
	self:F( { self.GroupName } )

  return self:TaskOrbitCircle( 30, 10 )
end


--- Land the group at a Vec2Point.
-- @param #GROUP self
-- @param #Vec2 Point The point where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @return #GROUP self
function GROUP:TaskLandAtVec2( Point, Duration )
	self:F( { self.GroupName, Point, Duration } )

  local DCSTask
  
	if Duration and Duration > 0 then
		DCSTask = { id = 'Land', params = { point = Point, durationFlag = true, duration = Duration } }
	else
		DCSTask = { id = 'Land', params = { point = Point, durationFlag = false } }
	end

  self:T( DCSTask )
	return DCSTask
end

--- Land the group at a @{Zone#ZONE).
-- @param #GROUP self
-- @param Zone#ZONE Zone The zone where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @return #GROUP self
function GROUP:TaskLandAtZone( Zone, Duration, RandomPoint )
  self:F( { self.GroupName, Zone, Duration, RandomPoint } )

  local Point
  if RandomPoint then
    Point = Zone:GetRandomPointVec2()
  else
    Point = Zone:GetPointVec2()
  end
  
  local DCSTask = self:TaskLandAtVec2( Point, Duration )

  self:T( DCSTask )
  return DCSTask
end


--- Attack the Unit.
-- @param #GROUP self
-- @param Unit#UNIT The unit.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskAttackUnit( AttackUnit )
	self:F( { self.GroupName, AttackUnit } )

--  AttackUnit = { 
--    id = 'AttackUnit', 
--    params = { 
--      unitId = Unit.ID, 
--      weaponType = number, 
--      expend = enum AI.Task.WeaponExpend
--      attackQty = number, 
--      direction = Azimuth, 
--      attackQtyLimit = boolean, 
--      groupAttack = boolean, 
--    } 
--  }
  
  local DCSTask    
  DCSTask = { id = 'AttackUnit', 
              params = { unitId = AttackUnit:GetID(), 
                         expend = AI.Task.WeaponExpend.TWO,
                         groupAttack = true, 
                       } 
            } 
  
  self:T( { DCSTask } )
  return DCSTask
end

--- Fires at a VEC2 point.
-- @param #GROUP self
-- @param DCSTypes#Vec2 The point to fire at.
-- @param DCSTypes#Distance Radius The radius of the zone to deploy the fire at.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskFireAtPoint( PointVec2, Radius )
  self:F( { self.GroupName, PointVec2, Radius } )

-- FireAtPoint = { 
--   id = 'FireAtPoint', 
--   params = { 
--     point = Vec2,
--     radius = Distance, 
--   } 
-- }
   
  local DCSTask    
  DCSTask = { id = 'FireAtPoint', 
              params = { point = PointVec2, 
                         radius = Radius, 
                       } 
            } 
  
  self:T( { DCSTask } )
  return DCSTask
end



--- Move the group to a Vec2 Point, wait for a defined duration and embark a group.
-- @param #GROUP self
-- @param #Vec2 Point The point where to wait.
-- @param #number Duration The duration in seconds to wait.
-- @param #GROUP EmbarkingGroup The group to be embarked.
-- @return DCSTask#Task The DCS task structure
function GROUP:TaskEmbarkingAtVec2( Point, Duration, EmbarkingGroup )
	self:F( { self.GroupName, Point, Duration, EmbarkingGroup.DCSGroup } )

	local DCSTask 
	DCSTask =  { id = 'Embarking', 
	             params = { x = Point.x, 
    	                    y = Point.y, 
    		  							  duration = Duration, 
    			  						  groupsForEmbarking = { EmbarkingGroup.GroupID },
    				  					  durationFlag = true,
    					  				  distributionFlag = false,
    						  			  distribution = {},
    						  			} 
    				 }
	
	self:T( { DCSTask } )
	return DCSTask
end

--- Move to a defined Vec2 Point, and embark to a group when arrived within a defined Radius.
-- @param #GROUP self
-- @param #Vec2 Point The point where to wait.
-- @param #number Radius The radius of the embarking zone around the Point.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskEmbarkToTransportAtVec2( Point, Radius )
	self:F( { self.GroupName, Point, Radius } )

  local DCSTask --DCSTask#Task
	DCSTask = { id = 'EmbarkToTransport', 
	            params = { x = Point.x, 
				  	             y = Point.y, 
		    							   zoneRadius = Radius,
						           } 
						} 

  self:T( { DCSTask } )
	return DCSTask
end

--- Return a Misson task from a mission template.
-- @param #GROUP self
-- @param #table TaskMission A table containing the mission task.
-- @return DCSTask#Task 
function GROUP:TaskMission( TaskMission )
	self:F( Points )
  
  local DCSTask
  DCSTask = { id = 'Mission', params = { TaskMission, }, }
  
  self:T( { DCSTask } )
  return DCSTask
end

--- Return a Misson task to follow a given route defined by Points.
-- @param #GROUP self
-- @param #table Points A table of route points.
-- @return DCSTask#Task 
function GROUP:TaskRoute( Points )
  self:F( Points )
  
  local DCSTask
  DCSTask = { id = 'Mission', params = { route = { points = Points, }, }, }
  
  self:T( { DCSTask } )
  return DCSTask
end

--- Make the group to fly to a given point and hover.
-- @param #GROUP self
-- @param #Vec3 Point The destination point.
-- @param #number Speed The speed to travel.
-- @return #GROUP self
function GROUP:TaskRouteToVec3( Point, Speed )
  self:F( { Point, Speed } )

  local GroupPoint = self:GetUnit( 1 ):GetPositionVec3()
  
  local PointFrom = {}
  PointFrom.x = GroupPoint.x
  PointFrom.y = GroupPoint.z
  PointFrom.alt = GroupPoint.y
  PointFrom.alt_type = "BARO"
  PointFrom.type = "Turning Point"
  PointFrom.action = "Turning Point"
  PointFrom.speed = Speed  
  PointFrom.speed_locked = true
  PointFrom.properties = {
        ["vnav"] = 1,
        ["scale"] = 0,
        ["angle"] = 0,
        ["vangle"] = 0,
        ["steer"] = 2,
  }
  

  local PointTo = {}
  PointTo.x = Point.x
  PointTo.y = Point.z
  PointTo.alt = Point.y  
  PointTo.alt_type = "BARO"
  PointTo.type = "Turning Point"
  PointTo.action = "Fly Over Point"
  PointTo.speed = Speed
  PointTo.speed_locked = true
  PointTo.properties = {
        ["vnav"] = 1,
        ["scale"] = 0,
        ["angle"] = 0,
        ["vangle"] = 0,
        ["steer"] = 2,
  }

  
  local Points = { PointFrom, PointTo }
  
  self:T( Points )
  
  self:Route( Points )

  return self
end



--- Make the group to follow a given route.
-- @param #GROUP self
-- @param #table GoPoints A table of Route Points.
-- @return #GROUP self 
function GROUP:Route( GoPoints )
	self:F( GoPoints )

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
-- @param #GROUP self
-- @param Zone#ZONE Zone The zone where to route to.
-- @param #boolean Randomize Defines whether to target point gets randomized within the Zone.
-- @param #number Speed The speed.
-- @param Base#FORMATION Formation The formation string.
function GROUP:TaskRouteToZone( Zone, Randomize, Speed, Formation )
	self:F( Zone )
	
	local GroupPoint = self:GetPointVec2()
	
	local PointFrom = {}
	PointFrom.x = GroupPoint.x
	PointFrom.y = GroupPoint.y
	PointFrom.type = "Turning Point"
	PointFrom.action = "Cone"
	PointFrom.speed = 20 / 1.6
	

	local PointTo = {}
	local ZonePoint 
	
	if Randomize then
		ZonePoint = Zone:GetRandomPointVec2()
	else
		ZonePoint = Zone:GetPointVec2()
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

-- Commands

--- Do Script command
-- @param #GROUP self
-- @param #string DoScript
-- @return #DCSCommand
function GROUP:CommandDoScript( DoScript )

  local DCSDoScript = {
    id = "Script",
    params = {
      command = DoScript,
    },
  }

  self:T( DCSDoScript )
  return DCSDoScript
end


--- Return the mission template of the group.
-- @param #GROUP self
-- @return #table The MissionTemplate
function GROUP:GetTaskMission()
  self:F( self.GroupName )

  return routines.utils.deepCopy( _DATABASE.Groups[self.GroupName].Template )
end

--- Return the mission route of the group.
-- @param #GROUP self
-- @return #table The mission route defined by points.
function GROUP:GetTaskRoute()
  self:F( self.GroupName )

  return routines.utils.deepCopy( _DATABASE.Groups[self.GroupName].Template.route.points )
end

--- Return the route of a group by using the @{Database#DATABASE} class.
-- @param #GROUP self
-- @param #number Begin The route point from where the copy will start. The base route point is 0.
-- @param #number End The route point where the copy will end. The End point is the last point - the End point. The last point has base 0.
-- @param #boolean Randomize Randomization of the route, when true.
-- @param #number Radius When randomization is on, the randomization is within the radius. 
function GROUP:CopyRoute( Begin, End, Randomize, Radius )
	self:F( { Begin, End } )

	local Points = {}
	
	-- Could be a Spawned Group
	local GroupName = string.match( self:GetName(), ".*#" )
	if GroupName then
		GroupName = GroupName:sub( 1, -2 )
	else
		GroupName = self:GetName()
	end
	
	self:T( { GroupName } )
	
	local Template = _DATABASE.Groups[GroupName].Template
	
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
-- @function _GetController
-- @param #GROUP self
-- @return Controller#Controller
function GROUP:_GetController()

	return self.DCSGroup:getController()

end

function GROUP:GetDetectedTargets()

  return self:_GetController():getDetectedTargets()
  
end

function GROUP:IsTargetDetected( DCSObject )

  local TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity
        = self:_GetController().isTargetDetected( self:_GetController(), DCSObject, 
                                                  Controller.Detection.VISUAL,
                                                  Controller.Detection.OPTIC,
                                                  Controller.Detection.RADAR,
                                                  Controller.Detection.IRST,
                                                  Controller.Detection.RWR,
                                                  Controller.Detection.DLINK
                                                )

  return TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity

end

-- Options

--- Can the GROUP hold their weapons?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEHoldFirePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() or self:IsGround() or self:IsShip() then
    return true
  end
  
  return false
end

--- Holding weapons.
-- @param Group#GROUP self
-- @return Group#GROUP self
function GROUP:OptionROEHoldFire()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
  elseif self:IsGround() then
    Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD )
  elseif self:IsShip() then
    Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.WEAPON_HOLD )
  end
  
  return self
end

--- Can the GROUP attack returning on enemy fire?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEReturnFirePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() or self:IsGround() or self:IsShip() then
    return true
  end
  
  return false
end

--- Return fire.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROEReturnFire()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.RETURN_FIRE )
  elseif self:IsGround() then
    Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.RETURN_FIRE )
  elseif self:IsShip() then
    Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.RETURN_FIRE )
  end
   
  return self
end

--- Can the GROUP attack designated targets?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEOpenFirePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() or self:IsGround() or self:IsShip() then
    return true
  end
  
  return false
end

--- Openfire.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROEOpenFire()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE )
  elseif self:IsGround() then
    Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE )
  elseif self:IsShip() then
    Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.OPEN_FIRE )
  end

  return self
end

--- Can the GROUP attack targets of opportunity?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEWeaponFreePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() then
    return true
  end
  
  return false
end

--- Weapon free.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROEWeaponFree()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE )
  end
  
  return self
end

--- Can the GROUP ignore enemy fire?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTNoReactionPossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() then
    return true
  end
  
  return false
end


--- No evasion on enemy threats.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTNoReaction()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.NO_REACTION )
  end
  
  return self
end

--- Can the GROUP evade using passive defenses?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTPassiveDefensePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() then
    return true
  end
  
  return false
end

--- Evasion passive defense.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTPassiveDefense()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.PASSIVE_DEFENCE )
  end
  
  return self
end

--- Can the GROUP evade on enemy fire?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTEvadeFirePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() then
    return true
  end
  
  return false
end


--- Evade on fire.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTEvadeFire()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
  end
  
  return self
end

--- Can the GROUP evade on fire using vertical manoeuvres?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTVerticalPossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() then
    return true
  end
  
  return false
end


--- Evade on fire using vertical manoeuvres.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTVertical()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE )
  end
  
  return self
end

-- Message APIs

--- Returns a message for a coalition or a client.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
-- @return Message#MESSAGE
function GROUP:Message( Message, Duration )
  self:F( { Message, Duration } )
  
  return MESSAGE:New( Message, self:GetCallsign() .. " (" .. self:GetTypeName() .. ")", Duration, self:GetClassNameAndID() )
end

--- Send a message to all coalitions.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
function GROUP:MessageToAll( Message, Duration )
  self:F( { Message, Duration } )
  
  self:Message( Message, Duration ):ToAll()
end

--- Send a message to the red coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
function GROUP:MessageToRed( Message, Duration )
  self:F( { Message, Duration } )
  
  self:Message( Message, Duration ):ToRed()
end

--- Send a message to the blue coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
function GROUP:MessageToBlue( Message, Duration )
  self:F( { Message, Duration } )
  
  self:Message( Message, Duration ):ToBlue()
end

--- Send a message to a client.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
-- @param Client#CLIENT Client The client object receiving the message.
function GROUP:MessageToClient( Message, Duration, Client )
  self:F( { Message, Duration } )
  
  self:Message( Message, Duration ):ToClient( Client )
end




--- Find the created GROUP using the DCSGroup ID. If a GROUP was created with the DCSGroupID, the the GROUP instance will be returned.
-- Otherwise nil will be returned.
-- @param DCSGroup#Group Group
-- @return #GROUP
function GROUP.FindGroup( DCSGroup )

  local self = GROUPS[DCSGroup:getID()] -- Group#GROUP
  self:T( self:GetClassNameAndID() )
  return self

end


