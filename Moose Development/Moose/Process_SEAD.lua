--- @module Process_SEAD

--- PROCESS_SEAD class
-- @type PROCESS_SEAD
-- @field Unit#UNIT ProcessUnit
-- @field Set#SET_UNIT TargetSet
-- @extends Process#PROCESS
PROCESS_SEAD = { 
  ClassName = "PROCESS_SEAD",
  Fsm = {},
  TargetSet = nil,
}


--- Creates a new SEAD task.
-- @param #PROCESS_SEAD self
-- @param Task#MISSION Task
-- @param Unit#UNIT ProcessUnit
-- @param Set#SET_UNIT TargetSet
-- @return #PROCESS_SEAD self
function PROCESS_SEAD:New( Task, ProcessUnit, TargetSet )

  -- Inherits from BASE
  local self = BASE:Inherit( self, PROCESS:New( Task, ProcessUnit ) ) -- #PROCESS_SEAD
  
  self.TargetSet = TargetSet

  self.Fsm = STATEMACHINE_TASK:New( self, {
    initial = 'Assigned',
    events = {
      { name = 'Await', from = 'Assigned', to = 'Waiting'    },
      { name = 'HitTarget',  from = 'Waiting',    to = 'Destroy' },
      { name = 'MoreTargets', from = 'Destroy', to = 'Waiting'  },
      { name = 'Destroyed', from = 'Destroy', to = 'Success' },      
      { name = 'Killed', from = 'Assigned', to = 'Failed' },
      { name = 'Killed', from = 'Waiting', to = 'Failed' },
      { name = 'Killed', from = 'Destroy', to = 'Failed' },
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


  _EVENTDISPATCHER:OnHit( self.EventHit, self )
  _EVENTDISPATCHER:OnDead( self.EventKilled, self )
  _EVENTDISPATCHER:OnCrash( self.EventKilled, self )
  
  return self
end

--- Process Events

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_SEAD:OnAwait( Fsm, Event, From, To )
  self:E( { Event, From, To, self.ProcessUnit.UnitName} )

  self.ProcessUnit:Message( "Waiting", 15 )
  self:NextEvent( Fsm.Await )
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function PROCESS_SEAD:OnHitTarget( Fsm, Event, From, To, Event )

  self.ProcessUnit:Message( "Hit Target", 15 )
  if self.TargetSet:Count() > 0 then
    self:NextEvent( Fsm.MoreTargets )
  else
    self:NextEvent( Fsm.Destroyed )
  end
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_SEAD:OnMoreTargets( Fsm, Event, From, To )

    self.ProcessUnit:Message( "More Targets", 15 )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA DCSEvent
function PROCESS_SEAD:OnKilled( Fsm, Event, From, To )

  self.ProcessUnit:Message( "Player got killed", 15 )
  self:NextEvent( Fsm.Restart )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_SEAD:OnRestart( Fsm, Event, From, To )

  self.ProcessUnit:Message( "Restart SEAD Process", 15 )
  self:NextEvent( Fsm.Menu )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_SEAD:OnDestroyed( Fsm, Event, From, To )

    self.ProcessUnit:Message( "Destroyed", 15 )

end

--- DCS Events

--- @param #PROCESS_SEAD self
-- @param Event#EVENTDATA Event
function PROCESS_SEAD:EventHit( Event )

  if Event.IniUnit then
    self:NextEvent( self.Fsm.HitTarget, Event )
  end
end

--- @param #PROCESS_SEAD self
-- @param Event#EVENTDATA Event
function PROCESS_SEAD:EventKilled( Event )

  if Event.IniUnit then
    if Event.IniUnitName == self.ProcessUnit.UnitName then
      self:NextEvent( self.Fsm.Killed, Event )
    end
  end
end

