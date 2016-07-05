--- Encapsulation of DCS World Menu system in a set of MENU classes.
-- @module Menu

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
	self:F( { MenuClient, MenuText, ParentMenu } )

  self.MenuClient = MenuClient
  self.MenuClientGroupID = MenuClient:GetClientGroupID()
  self.MenuParentPath = MenuParentPath
  self.MenuText = MenuText
  self.ParentMenu = ParentMenu
  
  self.Menus = {}

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  self:T( { MenuClient:GetClientGroupName(), MenuPath[table.concat(MenuParentPath)], MenuParentPath, MenuText } )

  local MenuPathID = table.concat(MenuParentPath) .. "/" .. MenuText
  if MenuPath[MenuPathID] then
    missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), MenuPath[MenuPathID] )
  end

	self.MenuPath = missionCommands.addSubMenuForGroup( self.MenuClient:GetClientGroupID(), MenuText, MenuParentPath )
	MenuPath[MenuPathID] = self.MenuPath

  self:T( { MenuClient:GetClientGroupName(), self.MenuPath } )

  if ParentMenu and ParentMenu.Menus then
    ParentMenu.Menus[self.MenuPath] = self
  end
	return self
end

--- Removes the sub menus recursively of this MENU_CLIENT.
-- @param #MENU_CLIENT self
-- @return #MENU_CLIENT self
function MENU_CLIENT:RemoveSubMenus()
  self:F( self.MenuPath )

  for MenuID, Menu in pairs( self.Menus ) do
    Menu:Remove()
  end

end

--- Removes the sub menus recursively of this MENU_CLIENT.
-- @param #MENU_CLIENT self
-- @return #MENU_CLIENT self
function MENU_CLIENT:Remove()
  self:F( self.MenuPath )

  self:RemoveSubMenus()

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  if MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] then
    MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] = nil
  end
  
  missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), self.MenuPath )
  self.ParentMenu.Menus[self.MenuPath] = nil
  return nil
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
  self.ParentMenu = ParentMenu

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  self:T( { MenuClient:GetClientGroupName(), MenuPath[table.concat(MenuParentPath)], MenuParentPath, MenuText, CommandMenuFunction, CommandMenuArgument } )

  local MenuPathID = table.concat(MenuParentPath) .. "/" .. MenuText
  if MenuPath[MenuPathID] then
    missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), MenuPath[MenuPathID] )
  end
  
	self.MenuPath = missionCommands.addCommandForGroup( self.MenuClient:GetClientGroupID(), MenuText, MenuParentPath, CommandMenuFunction, CommandMenuArgument )
  MenuPath[MenuPathID] = self.MenuPath
 
	self.CommandMenuFunction = CommandMenuFunction
	self.CommandMenuArgument = CommandMenuArgument
	
	ParentMenu.Menus[self.MenuPath] = self
	
	return self
end

function MENU_CLIENT_COMMAND:Remove()
  self:F( self.MenuPath )

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  if MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] then
    MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] = nil
  end
  
  missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), self.MenuPath )
  self.ParentMenu.Menus[self.MenuPath] = nil
  return nil
end


--- The MENU_COALITION class
-- @type MENU_COALITION
-- @extends Menu#MENU
MENU_COALITION = {
  ClassName = "MENU_COALITION"
}

--- Creates a new coalition menu item
-- @param #MENU_COALITION self
-- @param DCSCoalition#coalition.side Coalition The coalition owning the menu.
-- @param #string MenuText The text for the menu.
-- @param #table ParentMenu The parent menu.
-- @return #MENU_COALITION self
function MENU_COALITION:New( Coalition, MenuText, ParentMenu )

  -- Arrange meta tables
  local MenuParentPath = {}
  if ParentMenu ~= nil then
    MenuParentPath = ParentMenu.MenuPath
  end

  local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )
  self:F( { Coalition, MenuText, ParentMenu } )

  self.Coalition = Coalition
  self.MenuParentPath = MenuParentPath
  self.MenuText = MenuText
  self.ParentMenu = ParentMenu
  
  self.Menus = {}

  self:T( { MenuParentPath, MenuText } )

  self.MenuPath = missionCommands.addSubMenuForCoalition( self.Coalition, MenuText, MenuParentPath )

  self:T( { self.MenuPath } )

  if ParentMenu and ParentMenu.Menus then
    ParentMenu.Menus[self.MenuPath] = self
  end
  return self
end

--- Removes the sub menus recursively of this MENU_COALITION.
-- @param #MENU_COALITION self
-- @return #MENU_COALITION self
function MENU_COALITION:RemoveSubMenus()
  self:F( self.MenuPath )

  for MenuID, Menu in pairs( self.Menus ) do
    Menu:Remove()
  end

end

--- Removes the sub menus recursively of this MENU_COALITION.
-- @param #MENU_COALITION self
-- @return #MENU_COALITION self
function MENU_COALITION:Remove()
  self:F( self.MenuPath )

  self:RemoveSubMenus()
  missionCommands.removeItemForCoalition( self.MenuCoalition, self.MenuPath )
  self.ParentMenu.Menus[self.MenuPath] = nil

  return nil
end


--- The MENU_COALITION_COMMAND class
-- @type MENU_COALITION_COMMAND
-- @extends Menu#MENU
MENU_COALITION_COMMAND = {
  ClassName = "MENU_COALITION_COMMAND"
}

--- Creates a new radio command item for a group
-- @param #MENU_COALITION_COMMAND self
-- @param DCSCoalition#coalition.side MenuCoalition The coalition owning the menu.
-- @param MenuText The text for the menu.
-- @param ParentMenu The parent menu.
-- @param CommandMenuFunction A function that is called when the menu key is pressed.
-- @param CommandMenuArgument An argument for the function.
-- @return #MENU_COALITION_COMMAND self
function MENU_COALITION_COMMAND:New( MenuCoalition, MenuText, ParentMenu, CommandMenuFunction, CommandMenuArgument )

  -- Arrange meta tables
  
  local MenuParentPath = {}
  if ParentMenu ~= nil then
    MenuParentPath = ParentMenu.MenuPath
  end

  local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )
  
  self.MenuCoalition = MenuCoalition
  self.MenuParentPath = MenuParentPath
  self.MenuText = MenuText
  self.ParentMenu = ParentMenu

  self:T( { MenuParentPath, MenuText, CommandMenuFunction, CommandMenuArgument } )

  self.MenuPath = missionCommands.addCommandForCoalition( self.MenuCoalition, MenuText, MenuParentPath, CommandMenuFunction, CommandMenuArgument )
 
  self.CommandMenuFunction = CommandMenuFunction
  self.CommandMenuArgument = CommandMenuArgument
  
  ParentMenu.Menus[self.MenuPath] = self
  
  return self
end

--- Removes a radio command item for a coalition
-- @param #MENU_COALITION_COMMAND self
-- @return #MENU_COALITION_COMMAND self
function MENU_COALITION_COMMAND:Remove()
  self:F( self.MenuPath )

  missionCommands.removeItemForCoalition( self.MenuCoalition, self.MenuPath )
  self.ParentMenu.Menus[self.MenuPath] = nil
  return nil
end
