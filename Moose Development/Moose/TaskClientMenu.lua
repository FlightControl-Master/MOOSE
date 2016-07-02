--- @module Task_Client_Menu

--- TASK2_CLIENT_MENU class
-- @type TASK2_CLIENT_MENU
-- @field Client#CLIENT Client
-- @field Set#SET_UNIT TargetSet
-- @field Menu#MENU_CLIENT_COMMAND MenuSEAD
-- @extends Task2#TASK2
TASK2_CLIENT_MENU = { 
  ClassName = "TASK2_CLIENT_MENU",
  TargetSet = nil,
}


--- Creates a new MENU handling machine.
-- @param #TASK2_CLIENT_MENU self
-- @param Client#CLIENT Client
-- @param Mission#MISSION Mission
-- @param #string MenuText The text of the menu item.
-- @return #TASK2_CLIENT_MENU self
function TASK2_CLIENT_MENU:New( Client, Mission, MenuText )

  -- Inherits from BASE
  local self = BASE:Inherit( self, TASK2:New( Client, Mission ) ) -- #TASK2_CLIENT_MENU
  
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
-- @param #TASK2_CLIENT_MENU self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_CLIENT_MENU:OnMenu( Fsm, Event, From, To )
  self:E( { Event, From, To, self.Client.ClientName} )

  self.Client:Message( "Press F10 for task menu", 15 )
  self.Menu = MENU_CLIENT:New( self.Client, self.Mission:GetName(), nil )
  self.MenuTask = MENU_CLIENT_COMMAND:New( self.Client, self.MenuText, self.Menu, self.MenuAssign, self )
end

--- Menu function.
-- @param #TASK2_CLIENT_MENU self
function TASK2_CLIENT_MENU:MenuAssign()
  self:E( )

  self.Client:Message( "Menu Assign", 15 )

  self:NextEvent( self.Fsm.Assign )
end

--- StateMachine callback function for a TASK2
-- @param #TASK2_CLIENT_MENU self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2_CLIENT_MENU:OnAssign( Fsm, Event, From, To )
  self:E( { Event, From, To, self.Client.ClientName} )

  self.Client:Message( "Assign Task", 15 )
  self.MenuTask:Remove()
end

