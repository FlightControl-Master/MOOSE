--- @module Process_Destroy

--- PROCESS_DESTROY class
-- @type PROCESS_DESTROY
-- @field Unit#UNIT ProcessUnit
-- @field Set#SET_UNIT TargetSetUnit
-- @extends Process#PROCESS
PROCESS_DESTROY = { 
  ClassName = "PROCESS_DESTROY",
  Fsm = {},
  TargetSetUnit = nil,
}


--- Creates a new DESTROY process.
-- @param #PROCESS_DESTROY self
-- @param Task#TASK Task
-- @param Unit#UNIT ProcessUnit
-- @param Set#SET_UNIT TargetSetUnit
-- @return #PROCESS_DESTROY self
function PROCESS_DESTROY:New( Task, ProcessName, ProcessUnit, TargetSetUnit )

  -- Inherits from BASE
  local self = BASE:Inherit( self, PROCESS:New( ProcessName, Task, ProcessUnit ) ) -- #PROCESS_DESTROY
  
  self.TargetSetUnit = TargetSetUnit

  self.DisplayInterval = 30
  self.DisplayCount = 30
  self.DisplayMessage = true
  self.DisplayTime = 10 -- 10 seconds is the default
  self.DisplayCategory = "HQ" -- Targets is the default display category

  self.Fsm = STATEMACHINE_PROCESS:New( self, {
    initial = 'Assigned',
    events = {
      { name = 'Start', from = 'Assigned', to = 'Waiting'    },
      { name = 'Start', from = 'Waiting', to = 'Waiting'    },
      { name = 'HitTarget',  from = 'Waiting',    to = 'Destroy' },
      { name = 'MoreTargets', from = 'Destroy', to = 'Waiting'  },
      { name = 'Destroyed', from = 'Destroy', to = 'Success' },      
      { name = 'Fail', from = 'Assigned', to = 'Failed' },
      { name = 'Fail', from = 'Waiting', to = 'Failed' },
      { name = 'Fail', from = 'Destroy', to = 'Failed' },
    },
    callbacks = {
      onStart =  self.OnStart,
      onWaiting = self.OnWaiting,
      onHitTarget =  self.OnHitTarget,
      onMoreTargets = self.OnMoreTargets,
      onDestroyed = self.OnDestroyed,
      onKilled = self.OnKilled,
    },
    endstates = { 'Success', 'Failed' }
  } )


  _EVENTDISPATCHER:OnDead( self.EventDead, self )
  
  return self
end

--- Process Events

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_DESTROY self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_DESTROY:OnStart( Fsm, Event, From, To )

  self:NextEvent( Fsm.Start )
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_DESTROY self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_DESTROY:OnWaiting( Fsm, Event, From, To )

  local TaskGroup = self.ProcessUnit:GetGroup()
  if self.DisplayCount >= self.DisplayInterval then
    MESSAGE:New( "Your group with assigned " .. self.Task:GetName() .. " task has " .. self.TargetSetUnit:GetUnitTypesText() .. " targets left to be destroyed.", 5, "HQ" ):ToGroup( TaskGroup )
    self.DisplayCount = 1
  else
    self.DisplayCount = self.DisplayCount + 1
  end
  
  return true -- Process always the event.
  
end


--- StateMachine callback function for a PROCESS
-- @param #PROCESS_DESTROY self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function PROCESS_DESTROY:OnHitTarget( Fsm, Event, From, To, Event )


  self.TargetSetUnit:Flush()
  
  if self.TargetSetUnit:FindUnit( Event.IniUnitName ) then
    self.TargetSetUnit:RemoveUnitsByName( Event.IniUnitName )
    local TaskGroup = self.ProcessUnit:GetGroup()
    MESSAGE:New( "You hit a target. Your group with assigned " .. self.Task:GetName() .. " task has " .. self.TargetSetUnit:Count() .. " targets ( " .. self.TargetSetUnit:GetUnitTypesText() .. " ) left to be destroyed.", 15, "HQ" ):ToGroup( TaskGroup )
  end

  
  if self.TargetSetUnit:Count() > 0 then
    self:NextEvent( Fsm.MoreTargets )
  else
    self:NextEvent( Fsm.Destroyed )
  end
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_DESTROY self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_DESTROY:OnMoreTargets( Fsm, Event, From, To )


end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_DESTROY self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA DCSEvent
function PROCESS_DESTROY:OnKilled( Fsm, Event, From, To )

  self:NextEvent( Fsm.Restart )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_DESTROY self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_DESTROY:OnRestart( Fsm, Event, From, To )

  self:NextEvent( Fsm.Menu )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_DESTROY self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_DESTROY:OnDestroyed( Fsm, Event, From, To )

end

--- DCS Events

--- @param #PROCESS_DESTROY self
-- @param Event#EVENTDATA Event
function PROCESS_DESTROY:EventDead( Event )

  if Event.IniDCSUnit then
    self:NextEvent( self.Fsm.HitTarget, Event )
  end
end


