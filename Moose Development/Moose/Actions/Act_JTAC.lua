--- @module Process_JTAC

--- PROCESS_JTAC class
-- @type PROCESS_JTAC
-- @field Wrapper.Unit#UNIT ProcessUnit
-- @field Core.Set#SET_UNIT TargetSetUnit
-- @extends Core.Fsm#FSM_PROCESS
PROCESS_JTAC = { 
  ClassName = "PROCESS_JTAC",
  Fsm = {},
  TargetSetUnit = nil,
}


--- Creates a new DESTROY process.
-- @param #PROCESS_JTAC self
-- @param Tasking.Task#TASK Task
-- @param Wrapper.Unit#UNIT ProcessUnit
-- @param Core.Set#SET_UNIT TargetSetUnit
-- @param Wrapper.Unit#UNIT FACUnit
-- @return #PROCESS_JTAC self
function PROCESS_JTAC:New( Task, ProcessUnit, TargetSetUnit, FACUnit )

  -- Inherits from BASE
  local self = BASE:Inherit( self, PROCESS:New( "JTAC", Task, ProcessUnit ) ) -- #PROCESS_JTAC
  
  self.TargetSetUnit = TargetSetUnit
  self.FACUnit = FACUnit

  self.DisplayInterval = 60
  self.DisplayCount = 30
  self.DisplayMessage = true
  self.DisplayTime = 10 -- 10 seconds is the default
  self.DisplayCategory = "HQ" -- Targets is the default display category


  self.Fsm = FSM_PROCESS:New( self, {
    initial = 'Assigned',
    events = {
      { name = 'Start', from = 'Assigned', to = 'CreatedMenu'    },
      { name = 'JTACMenuUpdate', from = 'CreatedMenu', to = 'AwaitingMenu'    },
      { name = 'JTACMenuAwait', from = 'AwaitingMenu', to = 'AwaitingMenu'    },
      { name = 'JTACMenuSpot', from = 'AwaitingMenu', to = 'AwaitingMenu'    },
      { name = 'JTACMenuCancel', from = 'AwaitingMenu', to = 'AwaitingMenu'  },
      { name = 'JTACStatus', from = 'AwaitingMenu', to = 'AwaitingMenu'  },
      { name = 'Fail', from = 'AwaitingMenu', to = 'Failed' },
      { name = 'Fail', from = 'CreatedMenu', to = 'Failed' },
    },
    callbacks = {
      onStart =  self.OnStart,
      onJTACMenuUpdate = self.OnJTACMenuUpdate,
      onJTACMenuAwait =  self.OnJTACMenuAwait,
      onJTACMenuSpot = self.OnJTACMenuSpot,
      onJTACMenuCancel = self.OnJTACMenuCancel,
    },
    endstates = { 'Failed' }
  } )

  self:HandleEvent( EVENTS.Dead, self.EventDead )
  
  return self
end

--- Process Events

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_JTAC self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_JTAC:OnStart( Fsm, From, Event, To )

  self:NextEvent( Fsm.JTACMenuUpdate )
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_JTAC self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_JTAC:OnJTACMenuUpdate( Fsm, From, Event, To )

  local function JTACMenuSpot( MenuParam )
    self:E( MenuParam.TargetUnit.UnitName )
    local self = MenuParam.self
    local TargetUnit = MenuParam.TargetUnit

    self:NextEvent( self.Fsm.JTACMenuSpot, TargetUnit )
  end

  local function JTACMenuCancel( MenuParam )
    self:E( MenuParam )
    local self = MenuParam.self
    local TargetUnit = MenuParam.TargetUnit
 
    self:NextEvent( self.Fsm.JTACMenuCancel, TargetUnit )
  end


  -- Loop each unit in the target set, and determine the threat levels map table.
  local UnitThreatLevels = self.TargetSetUnit:GetUnitThreatLevels()
  
  self:E( {"UnitThreadLevels", UnitThreatLevels } )
  
  local JTACMenu = self.ProcessGroup:GetState( self.ProcessGroup, "JTACMenu" )
  
  if not JTACMenu then
    JTACMenu = MENU_GROUP:New( self.ProcessGroup, "JTAC", self.MissionMenu )
    for ThreatLevel, ThreatLevelTable in pairs( UnitThreatLevels ) do
      local JTACMenuThreatLevel = MENU_GROUP:New( self.ProcessGroup, ThreatLevelTable.UnitThreatLevelText, JTACMenu )
      for ThreatUnitName, ThreatUnit in pairs( ThreatLevelTable.Units ) do
        local JTACMenuUnit = MENU_GROUP:New( self.ProcessGroup, ThreatUnit:GetTypeName(), JTACMenuThreatLevel )
        MENU_GROUP_COMMAND:New( self.ProcessGroup, "Lase Target", JTACMenuUnit, JTACMenuSpot, { self = self, TargetUnit = ThreatUnit } )
        MENU_GROUP_COMMAND:New( self.ProcessGroup, "Cancel Target", JTACMenuUnit, JTACMenuCancel, { self = self, TargetUnit = ThreatUnit } )
      end
    end
  end  
  
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_JTAC self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_JTAC:OnJTACMenuAwait( Fsm, From, Event, To )

  if self.DisplayCount >= self.DisplayInterval then

    local TaskJTAC = self.Task -- Tasking.Task#TASK_JTAC
    TaskJTAC.Spots = TaskJTAC.Spots or {}
    for TargetUnitName, SpotData in pairs( TaskJTAC.Spots) do
      local TargetUnit = UNIT:FindByName( TargetUnitName )
      self.FACUnit:MessageToGroup( "Lasing " .. TargetUnit:GetTypeName() .. " with laser code " .. SpotData:getCode(), 15, self.ProcessGroup )
    end
    self.DisplayCount = 1
  else
    self.DisplayCount = self.DisplayCount + 1
  end
  
  self:NextEvent( Fsm.JTACMenuAwait )
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_JTAC self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT TargetUnit
function PROCESS_JTAC:OnJTACMenuSpot( Fsm, From, Event, To, TargetUnit )

  local TargetUnitName = TargetUnit:GetName()
  
  local TaskJTAC = self.Task -- Tasking.Task#TASK_JTAC
  
  TaskJTAC.Spots = TaskJTAC.Spots or {}
  TaskJTAC.Spots[TargetUnitName] = TaskJTAC.Spots[TargetUnitName] or {}

  local DCSFACObject = self.FACUnit:GetDCSObject()
  local TargetVec3 = TargetUnit:GetVec3()

  TaskJTAC.Spots[TargetUnitName] = Spot.createInfraRed( self.FACUnit:GetDCSObject(), { x = 0, y = 1, z = 0 }, TargetUnit:GetVec3(), math.random( 1000, 9999 ) )
  
  local SpotData = TaskJTAC.Spots[TargetUnitName]
  self.FACUnit:MessageToGroup( "Lasing " .. TargetUnit:GetTypeName() .. " with laser code " .. SpotData:getCode(), 15, self.ProcessGroup )

  self:NextEvent( Fsm.JTACMenuAwait )
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS_JTAC self
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT TargetUnit
function PROCESS_JTAC:OnJTACMenuCancel( Fsm, From, Event, To, TargetUnit )

  local TargetUnitName = TargetUnit:GetName()
  
  local TaskJTAC = self.Task -- Tasking.Task#TASK_JTAC
  
  TaskJTAC.Spots = TaskJTAC.Spots or {}
  if TaskJTAC.Spots[TargetUnitName] then
    TaskJTAC.Spots[TargetUnitName]:destroy() -- destroys the spot
    TaskJTAC.Spots[TargetUnitName] = nil
  end

  self.FACUnit:MessageToGroup( "Stopped lasing " .. TargetUnit:GetTypeName(), 15, self.ProcessGroup )

  self:NextEvent( Fsm.JTACMenuAwait )
end


