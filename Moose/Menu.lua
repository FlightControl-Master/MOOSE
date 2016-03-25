--- Encapsulation of DCS World Menu system in a set of MENU classes.
-- @module Menu

Include.File( "Routines" )
Include.File( "Base" )

--- The MENU class
-- @type MENU
-- @extends Base#BASE
MENU = {
  ClassName = "MENU",
  MenuPath = nil,
  MenuText = "",
  MenuParentPath = nil
}

---
function MENU:New( MenuText, MenuParentPath )

	-- Arrange meta tables
	local Child = BASE:Inherit( self, BASE:New() )

	Child.MenuPath = nil 
	Child.MenuText = MenuText
	Child.MenuParentPath = MenuParentPath
	return Child
end

--- The COMMANDMENU class
-- @type COMMANDMENU
-- @extends Menu#MENU
COMMANDMENU = {
  ClassName = "COMMANDMENU",
  CommandMenuFunction = nil,
  CommandMenuArgument = nil
}

function COMMANDMENU:New( MenuText, ParentMenu, CommandMenuFunction, CommandMenuArgument )

	-- Arrange meta tables
	
	local MenuParentPath = nil
	if ParentMenu ~= nil then
		MenuParentPath = ParentMenu.MenuPath
	end

	local Child = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )

	Child.MenuPath = missionCommands.addCommand( MenuText, MenuParentPath, CommandMenuFunction, CommandMenuArgument )
	Child.CommandMenuFunction = CommandMenuFunction
	Child.CommandMenuArgument = CommandMenuArgument
	return Child
end

--- The SUBMENU class
-- @type SUBMENU
-- @extends Menu#MENU
SUBMENU = {
  ClassName = "SUBMENU"
}

function SUBMENU:New( MenuText, ParentMenu )

	-- Arrange meta tables
	local MenuParentPath = nil
	if ParentMenu ~= nil then
		MenuParentPath = ParentMenu.MenuPath
	end

	local Child = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )

	Child.MenuPath = missionCommands.addSubMenu( MenuText, MenuParentPath )
	return Child
end

-- This local variable is used to cache the menus registered under clients.
-- Menus don't dissapear when clients are destroyed and restarted.
-- So every menu for a client created must be tracked so that program logic accidentally does not create
-- the same menus twice during initialization logic.
-- These menu classes are handling this logic with this variable.
local _MENUCLIENTS = {}

--- The MENU_CLIENT class
-- @type MENU_CLIENT
-- @extends Menu#MENU
MENU_CLIENT = {
  ClassName = "MENU_CLIENT"
}

--- Creates a new menu item for a group
-- @param self
-- @param Client#CLIENT MenuClient The Client owning the menu.
-- @param #string MenuText The text for the menu.
-- @param #table ParentMenu The parent menu.
-- @return #MENU_CLIENT self
function MENU_CLIENT:New( MenuClient, MenuText, ParentMenu )

	-- Arrange meta tables
	local MenuParentPath = {}
	if ParentMenu ~= nil then
	  MenuParentPath = ParentMenu.MenuPath
	end

	local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )

  self.MenuClient = MenuClient
  self.MenuClientGroupID = MenuClient:GetClientGroupID()
  self.MenuParentPath = MenuParentPath
  self.MenuText = MenuText

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  self:T( { MenuClient:GetClientGroupName(), MenuPath[table.concat(MenuParentPath)], MenuParentPath, MenuText } )

  if not MenuPath[table.concat(MenuParentPath) .. "/" .. MenuText] then
  	self.MenuPath = missionCommands.addSubMenuForGroup( self.MenuClient:GetClientGroupID(), MenuText, MenuParentPath )
  	MenuPath[table.concat(MenuParentPath) .. "/" .. MenuText] = self.MenuPath
  else
    self.MenuPath = MenuPath[table.concat(MenuParentPath) .. "/" .. MenuText] 
  end

	return self
end


--- The MENU_CLIENT_COMMAND class
-- @type MENU_CLIENT_COMMAND
-- @extends Menu#MENU
MENU_CLIENT_COMMAND = {
  ClassName = "MENU_CLIENT_COMMAND"
}

--- Creates a new radio command item for a group
-- @param self
-- @param Client#CLIENT MenuClient The Client owning the menu.
-- @param MenuText The text for the menu.
-- @param ParentMenu The parent menu.
-- @param CommandMenuFunction A function that is called when the menu key is pressed.
-- @param CommandMenuArgument An argument for the function.
-- @return Menu#MENU_CLIENT_COMMAND self
function MENU_CLIENT_COMMAND:New( MenuClient, MenuText, ParentMenu, CommandMenuFunction, CommandMenuArgument )

	-- Arrange meta tables
	
	local MenuParentPath = {}
	if ParentMenu ~= nil then
		MenuParentPath = ParentMenu.MenuPath
	end

	local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )
	
  self.MenuClient = MenuClient
  self.MenuClientGroupID = MenuClient:GetClientGroupID()
  self.MenuParentPath = MenuParentPath
  self.MenuText = MenuText

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  self:T( { MenuClient:GetClientGroupName(), MenuPath[table.concat(MenuParentPath)], MenuParentPath, MenuText, CommandMenuFunction, CommandMenuArgument } )

  if not MenuPath[table.concat(MenuParentPath) .. "/" .. MenuText] then
  	self.MenuPath = missionCommands.addCommandForGroup( self.MenuClient:GetClientGroupID(), MenuText, MenuParentPath, CommandMenuFunction, CommandMenuArgument )
    MenuPath[table.concat(MenuParentPath) .. "/" .. MenuText] = self.MenuPath
  else
    self.MenuPath = MenuPath[table.concat(MenuParentPath) .. "/" .. MenuText]
  end

	self.CommandMenuFunction = CommandMenuFunction
	self.CommandMenuArgument = CommandMenuArgument
	return self
end

function MENU_CLIENT_COMMAND:Remove()

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  if MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] then
    MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] = nil
  end
  missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), self.MenuPath )
  return nil
end
