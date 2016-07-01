

--- @module Task2

--- TASK2_SEAD class
-- @type TASK2_SEAD
-- @field Client#CLIENT Client
-- @field Set#SET_UNIT TargetSet
-- @extends Task2#TASK2
TASK2_SEAD = { 
  ClassName = "TASK2_SEAD",
  Fsm = {},
  TargetSet = nil,
}

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD:OnAssign( Fsm, Event, From, To )
  self:E( { Event, From, To, self.Client.ClientName} )

  self.Client:Message( "Assigned", 15 )
  self:NextEvent( Fsm.Await )
end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD:OnAwait( Fsm, Event, From, To )
  self:E( { Event, From, To, self.Client.ClientName} )

  self.Client:Message( "Waiting", 15 )
  self:NextEvent( Fsm.Await )
end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD:OnHitTarget( Fsm, Event, From, To, TargetUnit )

  self.Client:Message( "Hit Target", 15 )
  if self.TargetSet:Count() > 0 then
    self:NextEvent( Fsm.MoreTargets )
  else
    self:NextEvent( Fsm.Destroyed )
  end
end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD:OnMoreTargets( Fsm, Event, From, To )

    self.Client:Message( "More Targets", 15 )

end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Unit#UNIT KilledUnit
function TASK2_SEAD:OnKilled( Fsm, Event, From, To, KilledUnit )

  if KilledUnit:GetName() == self.Client:GetName() then
    self.Client:Message( "Player got killed", 15 )
    self:NextEvent( Fsm.Restart )
  end

end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD:OnRestart( Fsm, Event, From, To )

  self.Client:Message( "Restart SEAD Task", 15 )

end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD:OnDestroyed( Fsm, Event, From, To )

    self.Client:Message( "Destroyed", 15 )

end

function TASK2_SEAD:New( Client, TargetSet )

  -- Inherits from BASE
  local self = BASE:Inherit( self, TASK2:New( Client ) ) -- #TASK2_SEAD
  
  self.TargetSet = TargetSet

  self.Fsm = STATEMACHINE_TASK:New( self, {
    initial = 'Unassigned',
    events = {
      { name = 'Assign',  from = 'Unassigned',  to = 'Assigned' },
      { name = 'Await', from = 'Assigned', to = 'Waiting'    },
      { name = 'HitTarget',  from = 'Waiting',    to = 'Destroy' },
      { name = 'MoreTargets', from = 'Destroy', to = 'Waiting'  },
      { name = 'Destroyed', from = 'Destroy', to = 'Success' },      
      { name = 'Killed', from = 'Assigned', to = 'Failed' },
      { name = 'Killed', from = 'Waiting', to = 'Failed' },
      { name = 'Killed', from = 'Destroy', to = 'Failed' },
      { name = 'Restart', from = 'Failed', to = 'Unassigned' }
    },
    callbacks = {
      onAssign =  self.OnAssign,
      onAwait =  self.OnAwait,
      onHitTarget =  self.OnHitTarget,
      onMoreTargets = self.OnMoreTargets,
      onDestroyed = self.OnDestroyed,
      onKilled = self.OnKilled,
      onRestart = self.OnRestart,
    }
  } )


  _EVENTDISPATCHER:OnHit( self.EventHit, self )
  _EVENTDISPATCHER:OnDead( self.EventKilled, self )
  _EVENTDISPATCHER:OnCrash( self.EventKilled, self )
  
  self:Schedule()
  
end



--- @param #TASK2_SEAD self
-- @param Event#EVENTDATA Event
function TASK2_SEAD:EventHit( Event )

  if Event.IniUnit then
    self:NextEvent( self.Fsm.HitTarget, Event.IniUnit )
  end
end

--- @param #TASK2_SEAD self
-- @param Event#EVENTDATA Event
function TASK2_SEAD:EventKilled( Event )

  if Event.IniUnit then
    self:NextEvent( self.Fsm.Killed, Event.IniUnit )
  end
end

