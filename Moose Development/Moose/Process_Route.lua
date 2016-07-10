--- @module Task_Route

--- PROCESS_ROUTE class
-- @type PROCESS_ROUTE
-- @field Task#TASK TASK
-- @field Unit#UNIT ProcessUnit
-- @field Zone#ZONE_BASE TargetZone
-- @extends Task2#TASK2
PROCESS_ROUTE = { 
  ClassName = "PROCESS_ROUTE",
}


--- Creates a new routing state machine. The task will route a CLIENT to a ZONE until the CLIENT is within that ZONE.
-- @param #PROCESS_ROUTE self
-- @param Task#TASK Task
-- @param Unit#UNIT Unit
-- @return #PROCESS_ROUTE self
function PROCESS_ROUTE:New( Task, ProcessUnit, TargetZone )

  -- Inherits from BASE
  local self = BASE:Inherit( self, PROCESS:New( "ROUTE", Task, ProcessUnit ) ) -- #PROCESS_ROUTE
  
  self.TargetZone = TargetZone
  self.DisplayInterval = 30
  self.DisplayCount = 30
  self.DisplayMessage = true
  self.DisplayTime = 10 -- 10 seconds is the default
  self.DisplayCategory = "Route" -- Route is the default display category
  
  self.Fsm = STATEMACHINE_PROCESS:New( self, {
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
-- @param #PROCESS_ROUTE self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_ROUTE:OnLeaveUnArrived( Fsm, Event, From, To )

  local IsInZone = self.ProcessUnit:IsInZone( self.TargetZone )

  if self.DisplayCount >= self.DisplayInterval then
    if not IsInZone then
      local ZoneVec2 = self.TargetZone:GetVec2()
      local ZonePointVec2 = POINT_VEC2:New( ZoneVec2.x, ZoneVec2.y )
      local TaskUnitVec2 = self.ProcessUnit:GetVec2()
      local TaskUnitPointVec2 = POINT_VEC2:New( TaskUnitVec2.x, TaskUnitVec2.y )
      local RouteText = TaskUnitPointVec2:GetBRText( ZonePointVec2 )
      MESSAGE:New( RouteText, self.DisplayTime, self.DisplayCategory  ):ToGroup( self.ProcessUnit:GetGroup() )
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

