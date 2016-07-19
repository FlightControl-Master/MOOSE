--- @module Task_Client_Menu

--- TASK2_MENU_CLIENT class
-- @type TASK2_MENU_CLIENT
-- @field Unit#UNIT TaskUnit
-- @field Set#SET_UNIT TargetSet
-- @field Menu#MENU_CLIENT_COMMAND MenuTask
-- @extends Task2#TASK2
TASK2_MENU_CLIENT = { 
  ClassName = "TASK2_MENU_CLIENT",
  TargetSet = nil,
}


--- Creates a new MENU handling machine.
-- @param #TASK2_MENU_CLIENT self
-- @param Mission#MISSION Mission
-- @param Unit#UNIT TaskUnit
-- @param #string MenuText The text of the menu item.
-- @return #TASK2_MENU_CLIENT self
function TASK2_MENU_CLIENT:New( Mission, TaskUnit, MenuText )

  -- Inherits from BASE
  local self = BASE:Inherit( self, TASK2:New( Mission, TaskUnit ) ) -- #TASK2_MENU_CLIENT
  
  self.MenuText = MenuText

  self.Fsm = STATEMACHINE_TASK:New( self, {
    initial = 'Unassigned',
    events = {
      { name = 'Menu',  from = 'Unassigned',  to = 'AwaitingMenu' },
      { name = 'Assign',  from = 'AwaitingMenu',  to = 'Assigned' },
    },
    callbacks = {
      onMenu = self.OnMenu,
      onAssign =  self.OnAssign,
    },
    endstates = {
      'Assigned'
    },
  } )
  
  return self
end

--- Task Events

--- StateMachine callback function for a TASK2
-- @param #TASK2_MENU_CLIENT self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_MENU_CLIENT:OnMenu( Fsm, Event, From, To )
  self:E( { Event, From, To, self.TaskUnit.UnitName} )

  self.TaskUnit:Message( "Press F10 for task menu", 15 )
  self.Menu = MENU_CLIENT:New( self.TaskUnit, self.Mission:GetName(), nil )
  self.MenuTask = MENU_CLIENT_COMMAND:New( self.TaskUnit, self.MenuText, self.Menu, self.MenuAssign, self )
end

--- Menu function.
-- @param #TASK2_MENU_CLIENT self
function TASK2_MENU_CLIENT:MenuAssign()
  self:E( )

  self.TaskUnit:Message( "Menu Assign", 15 )

  self:NextEvent( self.Fsm.Assign )
end

--- StateMachine callback function for a TASK2
-- @param #TASK2_MENU_CLIENT self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_MENU_CLIENT:OnAssign( Fsm, Event, From, To )
  self:E( { Event, From, To, self.TaskUnit.UnitName} )

  self.TaskUnit:Message( "Assign Task", 15 )
  self.MenuTask:Remove()
end

