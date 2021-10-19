---- **Core** - F10 Other Menu.
--
-- **Main Features:**
--
--    * Add Menus and Commands to the "F10 Other" Menu
--    * Create menus and commands at specific locations within the parent menu 
--    * Events when command functions are executed
--    
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.F10Menu
-- @image OPS_F10Menu.png

--- F10Menu class.
-- @type F10MENU
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string text Text of the menu item.
-- @field #table path Path of the menu.
-- @field #F10MENU parent Parent menu or `nil`.
-- @field #table commands Commands within this menu.
-- @field #table submenues Sub menues withing this menu.
-- @extends Core.Fsm#FSM

--- *In preparing for battle I have always found that plans are useless, but planning is indispensable* -- Dwight D Eisenhower
--
-- ===
--
-- # The CHIEF Concept
-- 
--
-- @field #F10MENU
F10MENU = {
  ClassName      = "F10MENU",
  verbose        =     0,
  lid            =   nil,
  commands       =    {},
  submenues      =    {},
}

--- Command executing a function.
-- @type F10MENU.Command
-- @field #number uid Unique ID.
-- @field #string text Description.
-- @field #function func Function.
-- @field #table args Arguments.
-- @field #table path Path.

--- F10 menu class version.
-- @field #string version
F10MENU.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructors
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new F10 menu entry.
-- @param #F10MENU self
-- @return #F10MENU self
function F10MENU:_New()

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, FSM:New()) --#F10MENU
  
  -- Add FSM transitions.
  --                 From State   -->    Event                     -->    To State
  self:AddTransition("*",                "MissionAssign",                 "*")   -- Assign mission to a COMMANDER.

  ------------------------
  --- Pseudo Functions ---
  ------------------------


  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new F10 menu for all players.
-- @param #F10MENU self
-- @param #string Text Description of menu.
-- @param #F10MENU ParentMenu Parent menu to which this menu is added. If not specified, the menu is added to the root menu.
-- @return #F10MENU self
function F10MENU:NewForAll(Text, ParentMenu)

  -- Inherit everything from INTEL class.
  local self=self:_New()
  
  self.text=Text
  
  self.parent=ParentMenu
  
  if self.parent then
    self.parent:_AddSubmenu(self)
  end
  
  local path=self.parent and self.parent:GetPath() or nil
  
  self.path=missionCommands.addSubMenu(self.text, path)

  return self
end

--- Removes the F10 menu and its entire contents.
-- @param #F10MENU self
-- @return #F10MENU self
function F10MENU:Remove()

  for path,_submenu in pairs(self.submenues) do
    local submenu=_submenu --#F10MENU
    submenu:Remove()
  end
  
end

--- Get path.
-- @param #F10MENU self
-- @return #table Path.
function F10MENU:GetPath()
  return self.path
end

--- Get commands
-- @param #F10MENU self
-- @return #table Path.
function F10MENU:GetCommands()
  return self.commands
end

--- Get submenues.
-- @param #F10MENU self
-- @return #table Path.
function F10MENU:GetSubmenues()
  return self.submenues
end


--- Add a command for all players.
-- @param #F10MENU self
-- @param #string Text Description.
-- @param #function CommandFunction Function to call.
-- @param ... Function arguments.
-- @return #F10MENU.Command Command.
function F10MENU:AddCommandForAll(Text, CommandFunction, ...)

  local command={} --#F10MENU.Command
  command.uid=1
  command.text=Text
  command.func=CommandFunction
  command.args=...
  command.path=missionCommands.addCommand(command.text, self.path, command.func, command.args)

  table.insert(self.commands, command)  
  
  return command
end

--- Add a command for players of a specific coalition.
-- @param #F10MENU self
-- @return #F10MENU self
function F10MENU:AddCommandForCoalition()

end


--- Add a command for players of a specific group.
-- @param #F10MENU self
-- @return #F10MENU self
function F10MENU:AddCommandForGroup()

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a command for players of a specific group.
-- @param #F10MENU self
-- @param #F10MENU Submenu The submenu to add.
-- @return #F10MENU self
function F10MENU:_AddSubmenu(Submenu)

  self.submenues[Submenu.path]=Submenu

end

--- Add a command for players of a specific group.
-- @param #F10MENU self
-- @return #F10MENU self
function F10MENU:_Refresh()

  

  for _,_submenu in pairs(self.submenues) do
    local submenu=_submenu --#F10MENU
     
    
  end

end

