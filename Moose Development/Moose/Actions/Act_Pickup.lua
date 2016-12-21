--- @module Process_Pickup

--- PROCESS_PICKUP class
-- @type PROCESS_PICKUP
-- @field Wrapper.Unit#UNIT ProcessUnit
-- @field Core.Set#SET_UNIT TargetSetUnit
-- @extends Core.Fsm#FSM_PROCESS
PROCESS_PICKUP = { 
  ClassName = "PROCESS_PICKUP",
  Fsm = {},
  TargetSetUnit = nil,
}


--- Creates a new DESTROY process.
-- @param #PROCESS_PICKUP self
-- @param Tasking.Task#TASK Task
-- @param Wrapper.Unit#UNIT ProcessUnit
-- @param Core.Set#SET_UNIT TargetSetUnit
-- @return #PROCESS_PICKUP self
function PROCESS_PICKUP:New( Task, ProcessName, ProcessUnit )

  -- Inherits from BASE
  local self = BASE:Inherit( self, PROCESS:New( ProcessName, Task, ProcessUnit ) ) -- #PROCESS_PICKUP
  
  self.DisplayInterval = 30
  self.DisplayCount = 30
  self.DisplayMessage = true
  self.DisplayTime = 10 -- 10 seconds is the default
  self.DisplayCategory = "HQ" -- Targets is the default display category

  self.Fsm = FSM_PROCESS:New( self, {
    initial = 'Assigned',
    events = {
      { name = 'Start',     from = 'Assigned',        to = 'Navigating'    },
      { name = 'Start',     from = 'Navigating',      to = 'Navigating'    },
      { name = 'Nearby',    from = 'Navigating',      to = 'Preparing' },
      { name = 'Pickup',    from = 'Preparing',       to = 'Loading'  },
      { name = 'Load',      from = 'Loading',         to = 'Success'  },
      { name = 'Fail',      from = 'Assigned',        to = 'Failed' },
      { name = 'Fail',      from = 'Navigating',      to = 'Failed' },
      { name = 'Fail',      from = 'Preparing',       to = 'Failed' },
    },
    callbacks = {
      onStart =  self.OnStart,
      onNearby = self.OnNearby,
      onPickup =  self.OnPickup,
      onLoad = self.OnLoad,
    },
    endstates = { 'Success', 'Failed' }
  } )

  return self
end

--- Process Events

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_PICKUP self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_PICKUP:OnStart( Fsm, From, Event, To )

  self:NextEvent( Fsm.Start )
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_PICKUP self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_PICKUP:OnNavigating( Fsm, From, Event, To )

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
-- @param #PROCESS_PICKUP self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Core.Event#EVENTDATA Event
function PROCESS_PICKUP:OnHitTarget( Fsm, From, Event, To, Event )


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
-- @param #PROCESS_PICKUP self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_PICKUP:OnMoreTargets( Fsm, From, Event, To )


end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_PICKUP self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Core.Event#EVENTDATA DCSEvent
function PROCESS_PICKUP:OnKilled( Fsm, From, Event, To )

  self:NextEvent( Fsm.Restart )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_PICKUP self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_PICKUP:OnRestart( Fsm, From, Event, To )

  self:NextEvent( Fsm.Menu )

end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_PICKUP self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_PICKUP:OnDestroyed( Fsm, From, Event, To )

end

--- DCS Events

--- @param #PROCESS_PICKUP self
-- @param Core.Event#EVENTDATA Event
function PROCESS_PICKUP:EventDead( Event )

  if Event.IniDCSUnit then
    self:NextEvent( self.Fsm.HitTarget, Event )
  end
end


