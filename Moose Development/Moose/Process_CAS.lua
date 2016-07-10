--- @module Process_CAS

--- PROCESS_CAS class
-- @type PROCESS_CAS
-- @field Unit#UNIT ProcessUnit
-- @field Set#SET_UNIT TargetSetUnit
-- @extends Process#PROCESS
PROCESS_CAS = { 
  ClassName = "PROCESS_CAS",
  Fsm = {},
  TargetSetUnit = nil,
}


--- Creates a new CAS task.
-- @param #PROCESS_CAS self
-- @param Task#TASK Task
-- @param Unit#UNIT ProcessUnit
-- @param Set#SET_UNIT TargetSetUnit
-- @return #PROCESS_CAS self
function PROCESS_CAS:New( Task, ProcessUnit, TargetSetUnit )

  -- Inherits from BASE
  local self = BASE:Inherit( self, PROCESS:New( "CAS", Task, ProcessUnit ) ) -- #PROCESS_CAS
  
  self.TargetSetUnit = TargetSetUnit

  self.Fsm = STATEMACHINE_PROCESS:New( self, {
    initial = 'Assigned',
    events = {
      { name = 'Await', from = 'Assigned', to = 'Waiting'    },
      { name = 'HitTarget',  from = 'Waiting',    to = 'Destroy' },
      { name = 'MoreTargets', from = 'Destroy', to = 'Waiting'  },
      { name = 'Destroyed', from = 'Destroy', to = 'Success' },      
      { name = 'Fail', from = 'Assigned', to = 'Failed' },
      { name = 'Fail', from = 'Waiting', to = 'Failed' },
      { name = 'Fail', from = 'Destroy', to = 'Failed' },
    },
    callbacks = {
      onAwait =  self.OnAwait,
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
-- @param #PROCESS_CAS self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_CAS:OnAwait( Fsm, Event, From, To )
  self:E( { Event, From, To, self.ProcessUnit.UnitName} )

  self:NextEvent( Fsm.Await )
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_CAS self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function PROCESS_CAS:OnHitTarget( Fsm, Event, From, To, Event )

  if self.TargetSetUnit:Count() > 0 then
    self:NextEvent( Fsm.MoreTargets )
  else
    self:NextEvent( Fsm.Destroyed )
  end
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_CAS self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_CAS:OnMoreTargets( Fsm, Event, From, To )


end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_CAS self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA DCSEvent
function PROCESS_CAS:OnKilled( Fsm, Event, From, To )

  self:NextEvent( Fsm.Restart )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_CAS self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_CAS:OnRestart( Fsm, Event, From, To )

  self:NextEvent( Fsm.Menu )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_CAS self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_CAS:OnDestroyed( Fsm, Event, From, To )

end

--- DCS Events

--- @param #PROCESS_CAS self
-- @param Event#EVENTDATA Event
function PROCESS_CAS:EventDead( Event )

  if Event.IniUnit then
    self:NextEvent( self.Fsm.HitTarget, Event )
  end
end


