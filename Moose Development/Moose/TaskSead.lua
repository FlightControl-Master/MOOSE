--- @module Task_SEAD

--- TASK2_SEAD_CLIENT class
-- @type TASK2_SEAD_CLIENT
-- @field Unit#UNIT TaskUnit
-- @field Set#SET_UNIT TargetSet
-- @field Menu#MENU_CLIENT_COMMAND MenuSEAD
-- @extends Task2#TASK2
TASK2_SEAD_CLIENT = { 
  ClassName = "TASK2_SEAD_CLIENT",
  Fsm = {},
  TargetSet = nil,
}


--- Creates a new SEAD task.
-- @param #TASK2_SEAD_CLIENT self
-- @param Mission#MISSION Mission
-- @param Unit#UNIT TaskUnit
-- @param Set#SET_UNIT TargetSet
-- @return #TASK2_SEAD_CLIENT self
function TASK2_SEAD_CLIENT:New( Mission, TaskUnit, TargetSet )

  -- Inherits from BASE
  local self = BASE:Inherit( self, TASK2:New( Mission, TaskUnit ) ) -- #TASK2_SEAD_CLIENT
  
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

--- Task Events

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD_CLIENT self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD_CLIENT:OnAwait( Fsm, Event, From, To )
  self:E( { Event, From, To, self.TaskUnit.UnitName} )

  self.TaskUnit:Message( "Waiting", 15 )
  self:NextEvent( Fsm.Await )
end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD_CLIENT self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function TASK2_SEAD_CLIENT:OnHitTarget( Fsm, Event, From, To, Event )

  self.TaskUnit:Message( "Hit Target", 15 )
  if self.TargetSet:Count() > 0 then
    self:NextEvent( Fsm.MoreTargets )
  else
    self:NextEvent( Fsm.Destroyed )
  end
end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD_CLIENT self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD_CLIENT:OnMoreTargets( Fsm, Event, From, To )

    self.TaskUnit:Message( "More Targets", 15 )

end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD_CLIENT self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA DCSEvent
function TASK2_SEAD_CLIENT:OnKilled( Fsm, Event, From, To )

  self.TaskUnit:Message( "Player got killed", 15 )
  self:NextEvent( Fsm.Restart )

end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD_CLIENT self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD_CLIENT:OnRestart( Fsm, Event, From, To )

  self.TaskUnit:Message( "Restart SEAD Task", 15 )
  self:NextEvent( Fsm.Menu )

end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD_CLIENT self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD_CLIENT:OnDestroyed( Fsm, Event, From, To )

    self.TaskUnit:Message( "Destroyed", 15 )

end

--- DCS Events

--- @param #TASK2_SEAD_CLIENT self
-- @param Event#EVENTDATA Event
function TASK2_SEAD_CLIENT:EventHit( Event )

  if Event.IniUnit then
    self:NextEvent( self.Fsm.HitTarget, Event )
  end
end

--- @param #TASK2_SEAD_CLIENT self
-- @param Event#EVENTDATA Event
function TASK2_SEAD_CLIENT:EventKilled( Event )

  if Event.IniUnit then
    if Event.IniUnitName == self.TaskUnit.UnitName then
      self:NextEvent( self.Fsm.Killed, Event )
    end
  end
end

