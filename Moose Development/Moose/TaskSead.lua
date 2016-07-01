--- @module Task_SEAD

--- TASK2_SEAD class
-- @type TASK2_SEAD
-- @field Client#CLIENT Client
-- @field Set#SET_UNIT TargetSet
-- @field Menu#MENU_CLIENT_COMMAND MenuSEAD
-- @extends Task2#TASK2
TASK2_SEAD = { 
  ClassName = "TASK2_SEAD",
  Fsm = {},
  TargetSet = nil,
}


--- Creates a new SEAD task.
-- @param #TASK2_SEAD self
-- @param Client#CLIENT Client
-- @param Mission#MISSION Mission
-- @param Set#SET_UNIT TargetSet
-- @return #TASK2_SEAD self
function TASK2_SEAD:New( Client, Mission, TargetSet )

  -- Inherits from BASE
  local self = BASE:Inherit( self, TASK2:New( Client, Mission ) ) -- #TASK2_SEAD
  
  self.TargetSet = TargetSet

  self.Fsm = STATEMACHINE_TASK:New( self, {
    initial = 'Start',
    events = {
      { name = 'Menu',  from = 'Start',  to = 'Unassigned' },
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
      onMenu = self.OnMenu,
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
  
  self:NextEvent( self.Fsm.Menu )
  
  return self
end

--- Task Events

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD:OnMenu( Fsm, Event, From, To )
  self:E( { Event, From, To, self.Client.ClientName} )

  self.Client:Message( "Menu", 15 )
  self.Menu = MENU_CLIENT:New( self.Client, self.Mission:GetName(), nil )
  self.MenuSEAD = MENU_CLIENT_COMMAND:New( self.Client, "SEAD", self.Menu, self.SEADAssign, self )
end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
function TASK2_SEAD:SEADAssign()
  self:E( )

  self.Client:Message( "SEAD Menu Assign", 15 )

  self:NextEvent( self.Fsm.Assign )
end



--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD:OnAssign( Fsm, Event, From, To )
  self:E( { Event, From, To, self.Client.ClientName} )

  self.Client:Message( "Assigned", 15 )
  self.MenuSEAD:Remove()
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
-- @param Event#EVENTDATA Event
function TASK2_SEAD:OnHitTarget( Fsm, Event, From, To, Event )

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
-- @param Event#EVENTDATA DCSEvent
function TASK2_SEAD:OnKilled( Fsm, Event, From, To )

  self.Client:Message( "Player got killed", 15 )
  self:NextEvent( Fsm.Restart )

end

--- StateMachine callback function for a TASK2
-- @param #TASK2_SEAD self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_SEAD:OnRestart( Fsm, Event, From, To )

  self.Client:Message( "Restart SEAD Task", 15 )
  self:NextEvent( Fsm.Menu )

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

--- DCS Events

--- @param #TASK2_SEAD self
-- @param Event#EVENTDATA Event
function TASK2_SEAD:EventHit( Event )

  if Event.IniUnit then
    self:NextEvent( self.Fsm.HitTarget, Event )
  end
end

--- @param #TASK2_SEAD self
-- @param Event#EVENTDATA Event
function TASK2_SEAD:EventKilled( Event )

  if Event.IniUnit then
    if Event.IniUnitName == self.Client.ClientName then
      self:NextEvent( self.Fsm.Killed, Event )
    end
  end
end

