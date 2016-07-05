--- @module Task_Route

--- TASK2_ROUTE_CLIENT class
-- @type TASK2_ROUTE_CLIENT
-- @field Mission#MISSION Mission
-- @field Unit#UNIT TaskUnit
-- @field Zone#ZONE_BASE TargetZone
-- @extends Task2#TASK2
TASK2_ROUTE_CLIENT = { 
  ClassName = "TASK2_ROUTE_CLIENT",
}


--- Creates a new routing state machine. The task will route a CLIENT to a ZONE until the CLIENT is within that ZONE.
-- @param #TASK2_ROUTE_CLIENT self
-- @param Mission#MISSION Mission
-- @param Unit#UNIT Unit
-- @return #TASK2_ROUTE_CLIENT self
function TASK2_ROUTE_CLIENT:New( Mission, TaskUnit, TargetZone )

  -- Inherits from BASE
  local self = BASE:Inherit( self, TASK2:New( Mission, TaskUnit ) ) -- #TASK2_ROUTE_CLIENT
  
  self.TargetZone = TargetZone
  self.DisplayInterval = 30
  self.DisplayCount = 30
  self.DisplayMessage = true
  self.DisplayTime = 10 -- 10 seconds is the default
  self.DisplayCategory = "Route" -- Route is the default display category
  
  self.Fsm = STATEMACHINE_TASK:New( self, {
    initial = 'UnArrived',
    events = {
      { name = 'Route',  from = 'UnArrived',  to = 'Arrived' },
      { name = 'Fail',  from = 'UnArrived',  to = 'Failed' },
    },
    callbacks = {
      onleaveUnArrived = self.OnLeaveUnArrived,
      onFail = self.OnFail,
    },
    endstates = {
      'Arrived', 'Failed'
    },
  } )
  
  return self
end

--- Task Events

--- StateMachine callback function for a TASK2
-- @param #TASK2_ROUTE_CLIENT self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_ROUTE_CLIENT:OnLeaveUnArrived( Fsm, Event, From, To )
  self:E( { Event, From, To, self.TaskUnit.UnitName } )

  local IsInZone = self.TaskUnit:IsInZone( self.TargetZone )

  if self.DisplayCount >= self.DisplayInterval then
    if not IsInZone then
      local ZoneVec2 = self.TargetZone:GetVec2()
      local ZonePointVec2 = POINT_VEC2:New( ZoneVec2.x, ZoneVec2.y )
      local TaskUnitVec2 = self.TaskUnit:GetVec2()
      local TaskUnitPointVec2 = POINT_VEC2:New( TaskUnitVec2.x, TaskUnitVec2.y )
      local RouteText = TaskUnitPointVec2:GetBRText( ZonePointVec2 )
      self.TaskUnit:Message( RouteText, self.DisplayTime, self.DisplayCategory  )
    end
    self.DisplayCount = 1
  else
    self.DisplayCount = self.DisplayCount + 1
  end
  
  if not IsInZone then
    self:NextEvent( Fsm.Route )
  end

  return IsInZone -- if false, then the event will not be executed...
  
end

