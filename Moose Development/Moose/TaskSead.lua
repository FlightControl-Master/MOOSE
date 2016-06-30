

--- @module Task2

--- TASK2_SEAD class
-- @type TASK2_SEAD
-- @extends Task2#TASK2
TASK2_SEAD = { 
  ClassName = "TASK2_SEAD",
  StateMachine = {},
}


function TASK2_SEAD:New( Client )

  -- Inherits from BASE
  local self = BASE:Inherit( self, TASK2:New( Client ) ) -- #TASK2_SEAD


  --- @param #TASK2_SEAD self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Client#CLIENT Client
  local function OnAssign( self, Event, From, To, Task, Client )
  Task:E( { Event, From, To, Client.ClientName} )
  
    Client:Message( "Assigned", 15 )
    Task:NextEvent( self.Await )
  end
  
  --- @param #string Event
  -- @param #string From
  -- @param #string To
  local function OnAwait( self, Event, From, To, Task, Client )
  Task:E( { Event, From, To, Client.ClientName} )
  
    Client:Message( "Waiting", 15 )
    Task:NextEvent( self.Await )
  end
  
  --- @param #string Event
  -- @param #string From
  -- @param #string To
  local function OnHitTarget( self, Event, From, To )
  
  end
  
  --- @param #string Event
  -- @param #string From
  -- @param #string To
  local function OnMoreTargets( self, Event, From, To )
  
  end
  
  local function OnKilled( self, Event, From, To )
  
  end
  
  local function OnFailed( self, Event, From, To )
  
  end
  
  local function OnDestroyed( self, Event, From, To )
  
  end

  self.StateMachine = STATEMACHINE:New( {
    initial = 'Unassigned',
    events = {
      { name = 'Assign',  from = 'Unassigned',  to = 'Assigned' },
      { name = 'Await', from = 'Assigned', to = 'Waiting'    },
      { name = 'Await', from = 'Waiting', to = 'Waiting'    },
      { name = 'HitTarget',  from = 'Waiting',    to = 'Destroyed' },
      { name = 'MoreTargets', from = 'Destroyed', to = 'Waiting'  },
      { name = 'Killed', from = 'Waiting', to = 'Killed' },
      { name = 'Failed', from = 'Killed', to = 'Unassigned' },
      { name = 'Destroyed', from = 'Destroyed', to = 'Finished' }      
    },
    callbacks = {
      onAssign =  OnAssign,
      onAwait =  OnAwait,
      onHitTarget =  OnHitTarget,
      onMoreTargets = OnMoreTargets,
      onKilled = OnKilled,
      onFailed = OnFailed,
      onDestroyed = OnDestroyed,
    }
  } )


  _EVENTDISPATCHER:OnHit( self.OnHit, self )
  
  self:Schedule()
  
end

--- @param #TASK2_SEAD self
-- @param Event#EVENTDATA Event
function TASK2_SEAD:OnHit( Event )

  if Event.IniUnit then
    self:NextEvent( self.StateMachine.OnHitTarget )
  end
end

