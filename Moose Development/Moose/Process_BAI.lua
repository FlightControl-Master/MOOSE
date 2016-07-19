--- @module Process_BAI

--- PROCESS_BAI class
-- @type PROCESS_BAI
-- @field Unit#UNIT ProcessUnit
-- @field Set#SET_UNIT TargetSetUnit
-- @extends Process#PROCESS
PROCESS_BAI = { 
  ClassName = "PROCESS_BAI",
  Fsm = {},
  TargetSetUnit = nil,
}


--- Creates a new BAI task.
-- @param #PROCESS_BAI self
-- @param Task#TASK Task
-- @param Unit#UNIT ProcessUnit
-- @param Set#SET_UNIT TargetSetUnit
-- @return #PROCESS_BAI self
function PROCESS_BAI:New( Task, ProcessUnit, TargetSetUnit )

  -- Inherits from BASE
  local self = BASE:Inherit( self, PROCESS:New( "BAI", Task, ProcessUnit ) ) -- #PROCESS_BAI
  
  self.TargetSetUnit = TargetSetUnit

  self.Fsm = STATEMACHINE_PROCESS:New( self, {
    initial = 'Assigned',
    events = {
      { name = 'Start', from = 'Assigned', to = 'Waiting'    },
      { name = 'HitTarget',  from = 'Waiting',    to = 'Destroy' },
      { name = 'MoreTargets', from = 'Destroy', to = 'Waiting'  },
      { name = 'Destroyed', from = 'Destroy', to = 'Success' },      
      { name = 'Fail', from = 'Assigned', to = 'Failed' },
      { name = 'Fail', from = 'Waiting', to = 'Failed' },
      { name = 'Fail', from = 'Destroy', to = 'Failed' },
    },
    callbacks = {
      onStart =  self.OnStart,
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
-- @param #PROCESS_BAI self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_BAI:OnStart( Fsm, Event, From, To )
  self:E( { Event, From, To, self.ProcessUnit.UnitName} )

  self:NextEvent( Fsm.Start )
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_BAI self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function PROCESS_BAI:OnHitTarget( Fsm, Event, From, To, Event )

  if self.TargetSetUnit:Count() > 0 then
    self:NextEvent( Fsm.MoreTargets )
  else
    self:NextEvent( Fsm.Destroyed )
  end
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_BAI self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_BAI:OnMoreTargets( Fsm, Event, From, To )


end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_BAI self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA DCSEvent
function PROCESS_BAI:OnKilled( Fsm, Event, From, To )

  self:NextEvent( Fsm.Restart )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_BAI self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_BAI:OnRestart( Fsm, Event, From, To )

  self:NextEvent( Fsm.Menu )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_BAI self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_BAI:OnDestroyed( Fsm, Event, From, To )

end

--- DCS Events

--- @param #PROCESS_BAI self
-- @param Event#EVENTDATA Event
function PROCESS_BAI:EventDead( Event )

  if Event.IniDCSUnit then
    self.TargetSetUnit:Remove( Event.IniDCSUnitName )
    self:NextEvent( self.Fsm.HitTarget, Event )
  end
end


