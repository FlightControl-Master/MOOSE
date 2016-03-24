--- Encapsulation of DCS World Menu system in a set of MENU classes.
-- @module MENU

Include.File( "Routines" )
Include.File( "Base" )

--- The MENU class
-- @type
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
-- @type
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
-- @type
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

--- The MENU_SUB_GROUP class
-- @type
MENU_SUB_GROUP = {
  ClassName = "MENU_SUB_GROUP"
}

--- Creates a new menu item for a group
-- @param self
-- @param MenuGroup The group owning the menu.
-- @param MenuText The text for the menu.
-- @param ParentMenu The parent menu.
-- @return #MENU_SUB_GROUP self
function MENU_SUB_GROUP:New( MenuGroup, MenuText, ParentMenu )

	-- Arrange meta tables
	local MenuParentPath = nil
	if ParentMenu ~= nil then
		MenuParentPath = ParentMenu.MenuPath
	end

	local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )

  self:T( { MenuGroup, MenuText, ParentMenu } )

  self.MenuGroup = MenuGroup
	self.MenuPath = missionCommands.addSubMenuForGroup( self.MenuGroup:GetID(), MenuText, MenuParentPath )
	return self
end

--- The MENU_COMMAND_GROUP class
-- @type
MENU_COMMAND_GROUP = {
  ClassName = "MENU_COMMAND_GROUP"
}

--- Creates a new radio command item for a group
-- @param self
-- @param MenuGroup The group owning the menu.
-- @param MenuText The text for the menu.
-- @param ParentMenu The parent menu.
-- @param CommandMenuFunction A function that is called when the menu key is pressed.
-- @param CommandMenuArgument An argument for the function.
-- @return #MENU_COMMAND_GROUP self
function MENU_COMMAND_GROUP:New( MenuGroup, MenuText, ParentMenu, CommandMenuFunction, CommandMenuArgument )

	-- Arrange meta tables
	
	local MenuParentPath = nil
	if ParentMenu ~= nil then
		MenuParentPath = ParentMenu.MenuPath
	end

	local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )
	
	self:T( { MenuGroup, MenuText, ParentMenu, CommandMenuFunction, CommandMenuArgument } )

  self.MenuGroup = MenuGroup
	self.MenuPath = missionCommands.addCommandForGroup( self.MenuGroup:GetID(), MenuText, MenuParentPath, CommandMenuFunction, CommandMenuArgument )
	self.CommandMenuFunction = CommandMenuFunction
	self.CommandMenuArgument = CommandMenuArgument
	return self
end

function MENU_COMMAND_GROUP:Remove()

  missionCommands.removeItemForGroup( self.MenuGroup:GetID(), self.MenuPath )
  return nil
end
