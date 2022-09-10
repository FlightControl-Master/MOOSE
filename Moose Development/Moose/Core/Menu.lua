--- **Core** - Manage hierarchical menu structures and commands for players within a mission.
-- 
-- ===
-- 
-- ### Features:
-- 
--   * Setup mission sub menus.
--   * Setup mission command menus.
--   * Setup coalition sub menus.
--   * Setup coalition command menus.
--   * Setup group sub menus.
--   * Setup group command menus.
--   * Manage menu creation intelligently, avoid double menu creation.
--   * Only create or delete menus when required, and keep existing menus persistent.
--   * Update menu structures.
--   * Refresh menu structures intelligently, based on a time stamp of updates.
--     - Delete obsolete menus.
--     - Create new one where required.
--     - Don't touch the existing ones.
--   * Provide a variable amount of parameters to menus.
--   * Update the parameters and the receiving methods, without updating the menu within DCS!
--   * Provide a great performance boost in menu management.
--   * Provide a great tool to manage menus in your code.
-- 
-- DCS Menus can be managed using the MENU classes. 
-- The advantage of using MENU classes is that it hides the complexity of dealing with menu management in more advanced scenarios where you need to 
-- set menus and later remove them, and later set them again. You'll find while using use normal DCS scripting functions, that setting and removing
-- menus is not a easy feat if you have complex menu hierarchies defined. 
-- Using the MOOSE menu classes, the removal and refreshing of menus are nicely being handled within these classes, and becomes much more easy.
-- On top, MOOSE implements **variable parameter** passing for command menus. 
-- 
-- There are basically two different MENU class types that you need to use:
-- 
-- ### To manage **main menus**, the classes begin with **MENU_**:
-- 
--   * @{Core.Menu#MENU_MISSION}: Manages main menus for whole mission file.
--   * @{Core.Menu#MENU_COALITION}: Manages main menus for whole coalition.
--   * @{Core.Menu#MENU_GROUP}: Manages main menus for GROUPs.
--   
-- ### To manage **command menus**, which are menus that allow the player to issue **functions**, the classes begin with **MENU_COMMAND_**:
--   
--   * @{Core.Menu#MENU_MISSION_COMMAND}: Manages command menus for whole mission file.
--   * @{Core.Menu#MENU_COALITION_COMMAND}: Manages command menus for whole coalition.
--   * @{Core.Menu#MENU_GROUP_COMMAND}: Manages command menus for GROUPs.
-- 
-- ===
--- 
-- ### Author: **FlightControl**
-- ### Contributions: 
-- 
-- ===
--   
-- @module Core.Menu
-- @image Core_Menu.JPG

MENU_INDEX = {}
MENU_INDEX.MenuMission = {}
MENU_INDEX.MenuMission.Menus = {}
MENU_INDEX.Coalition = {}
MENU_INDEX.Coalition[coalition.side.BLUE] = {}
MENU_INDEX.Coalition[coalition.side.BLUE].Menus = {}
MENU_INDEX.Coalition[coalition.side.RED] = {}
MENU_INDEX.Coalition[coalition.side.RED].Menus = {}
MENU_INDEX.Group = {}

function MENU_INDEX:ParentPath( ParentMenu, MenuText )
  local Path = ParentMenu and "@" .. table.concat( ParentMenu.MenuPath or {}, "@" ) or ""
  if ParentMenu then 
    if ParentMenu:IsInstanceOf( "MENU_GROUP" ) or ParentMenu:IsInstanceOf( "MENU_GROUP_COMMAND" ) then
      local GroupName = ParentMenu.Group:GetName()
      if not self.Group[GroupName].Menus[Path] then
        BASE:E( { Path = Path, GroupName = GroupName } ) 
        error( "Parent path not found in menu index for group menu" )
        return nil
      end
    elseif ParentMenu:IsInstanceOf( "MENU_COALITION" ) or ParentMenu:IsInstanceOf( "MENU_COALITION_COMMAND" ) then
      local Coalition = ParentMenu.Coalition
      if not self.Coalition[Coalition].Menus[Path] then
        BASE:E( { Path = Path, Coalition = Coalition } ) 
        error( "Parent path not found in menu index for coalition menu" )
        return nil
      end
    elseif ParentMenu:IsInstanceOf( "MENU_MISSION" ) or ParentMenu:IsInstanceOf( "MENU_MISSION_COMMAND" ) then
      if not self.MenuMission.Menus[Path] then
        BASE:E( { Path = Path } )
        error( "Parent path not found in menu index for mission menu" )
        return nil
      end
    end
  end
  
  Path = Path .. "@" .. MenuText
  return Path
end

function MENU_INDEX:PrepareMission()
    self.MenuMission.Menus = self.MenuMission.Menus or {}
end

function MENU_INDEX:PrepareCoalition( CoalitionSide )
    self.Coalition[CoalitionSide] = self.Coalition[CoalitionSide] or {}
    self.Coalition[CoalitionSide].Menus = self.Coalition[CoalitionSide].Menus or {}
end
---
-- @param Wrapper.Group#GROUP Group
function MENU_INDEX:PrepareGroup( Group )
  if Group and Group:IsAlive() ~= nil  then -- something was changed here!
    local GroupName = Group:GetName()
    self.Group[GroupName] = self.Group[GroupName] or {}
    self.Group[GroupName].Menus = self.Group[GroupName].Menus or {}
  end
end

function MENU_INDEX:HasMissionMenu( Path )
  return self.MenuMission.Menus[Path]
end
function MENU_INDEX:SetMissionMenu( Path, Menu )
  self.MenuMission.Menus[Path] = Menu
end
function MENU_INDEX:ClearMissionMenu( Path )
  self.MenuMission.Menus[Path] = nil
end

function MENU_INDEX:HasCoalitionMenu( Coalition, Path )
  return self.Coalition[Coalition].Menus[Path]
end
function MENU_INDEX:SetCoalitionMenu( Coalition, Path, Menu )
  self.Coalition[Coalition].Menus[Path] = Menu
end
function MENU_INDEX:ClearCoalitionMenu( Coalition, Path )
  self.Coalition[Coalition].Menus[Path] = nil
end

function MENU_INDEX:HasGroupMenu( Group, Path )
  if Group and Group:IsAlive() then
    local MenuGroupName = Group:GetName()
    return self.Group[MenuGroupName].Menus[Path]
  end
  return nil
end
function MENU_INDEX:SetGroupMenu( Group, Path, Menu )
  local MenuGroupName = Group:GetName()
  Group:F({MenuGroupName=MenuGroupName,Path=Path})
  self.Group[MenuGroupName].Menus[Path] = Menu
end
function MENU_INDEX:ClearGroupMenu( Group, Path )
  local MenuGroupName = Group:GetName()
  self.Group[MenuGroupName].Menus[Path] = nil
end
function MENU_INDEX:Refresh( Group )
    for MenuID, Menu in pairs( self.MenuMission.Menus ) do
      Menu:Refresh()  
    end 
    for MenuID, Menu in pairs( self.Coalition[coalition.side.BLUE].Menus ) do
      Menu:Refresh()  
    end 
    for MenuID, Menu in pairs( self.Coalition[coalition.side.RED].Menus ) do
      Menu:Refresh()  
    end 
    local GroupName = Group:GetName()
    for MenuID, Menu in pairs( self.Group[GroupName].Menus ) do
      Menu:Refresh()  
    end 
  
  return self
end

do -- MENU_BASE
  --- @type MENU_BASE
  -- @extends Core.Base#BASE
  --- Defines the main MENU class where other MENU classes are derived from.
  -- This is an abstract class, so don't use it.
  -- @field #MENU_BASE
  MENU_BASE = {
    ClassName = "MENU_BASE",
    MenuPath = nil,
    MenuText = "",
    MenuParentPath = nil,
  }
  
  --- Constructor
  -- @param #MENU_BASE
  -- @return #MENU_BASE
  function MENU_BASE:New( MenuText, ParentMenu )
  
    local MenuParentPath = {}
    if ParentMenu ~= nil then
      MenuParentPath = ParentMenu.MenuPath
    end
    local self = BASE:Inherit( self, BASE:New() )
  
    self.MenuPath = nil 
    self.MenuText = MenuText
    self.ParentMenu = ParentMenu
    self.MenuParentPath = MenuParentPath
    self.Path = ( self.ParentMenu and "@" .. table.concat( self.MenuParentPath or {}, "@" ) or "" ) .. "@" .. self.MenuText
    self.Menus = {}
    self.MenuCount = 0
    self.MenuStamp = timer.getTime()
    self.MenuRemoveParent = false
    
    if self.ParentMenu then
      self.ParentMenu.Menus = self.ParentMenu.Menus or {}
      self.ParentMenu.Menus[MenuText] = self
    end
    
    return self
  end
  function MENU_BASE:SetParentMenu( MenuText, Menu )
    if self.ParentMenu then
      self.ParentMenu.Menus = self.ParentMenu.Menus or {}
      self.ParentMenu.Menus[MenuText] = Menu
      self.ParentMenu.MenuCount = self.ParentMenu.MenuCount + 1
    end
  end
  function MENU_BASE:ClearParentMenu( MenuText )
    if self.ParentMenu and self.ParentMenu.Menus[MenuText] then
      self.ParentMenu.Menus[MenuText] = nil
      self.ParentMenu.MenuCount = self.ParentMenu.MenuCount - 1
      if self.ParentMenu.MenuCount == 0 then
        --self.ParentMenu:Remove()
      end
    end
  end
  --- Sets a @{Menu} to remove automatically the parent menu when the menu removed is the last child menu of that parent @{Menu}.
  -- @param #MENU_BASE self
  -- @param #boolean RemoveParent If true, the parent menu is automatically removed when this menu is the last child menu of that parent @{Menu}.
  -- @return #MENU_BASE
  function MENU_BASE:SetRemoveParent( RemoveParent )
    --self:F( { RemoveParent } )
    self.MenuRemoveParent = RemoveParent
    return self
  end
  
  --- Gets a @{Menu} from a parent @{Menu}
  -- @param #MENU_BASE self
  -- @param #string MenuText The text of the child menu.
  -- @return #MENU_BASE
  function MENU_BASE:GetMenu( MenuText )
    return self.Menus[MenuText]
  end
  
  --- Sets a menu stamp for later prevention of menu removal.
  -- @param #MENU_BASE self
  -- @param MenuStamp
  -- @return #MENU_BASE
  function MENU_BASE:SetStamp( MenuStamp )
    self.MenuStamp = MenuStamp
    return self
  end
  
  
  --- Gets a menu stamp for later prevention of menu removal.
  -- @param #MENU_BASE self
  -- @return MenuStamp
  function MENU_BASE:GetStamp()
    return timer.getTime()
  end
  
  
  --- Sets a time stamp for later prevention of menu removal.
  -- @param #MENU_BASE self
  -- @param MenuStamp
  -- @return #MENU_BASE
  function MENU_BASE:SetTime( MenuStamp )
    self.MenuStamp = MenuStamp
    return self
  end
  
  --- Sets a tag for later selection of menu refresh.
  -- @param #MENU_BASE self
  -- @param #string MenuTag A Tag or Key that will filter only menu items set with this key.
  -- @return #MENU_BASE
  function MENU_BASE:SetTag( MenuTag )
    self.MenuTag = MenuTag
    return self
  end
  
end
do -- MENU_COMMAND_BASE
  --- @type MENU_COMMAND_BASE
  -- @field #function MenuCallHandler
  -- @extends Core.Menu#MENU_BASE
  
  --- Defines the main MENU class where other MENU COMMAND_ 
  -- classes are derived from, in order to set commands.
  -- 
  -- @field #MENU_COMMAND_BASE
  MENU_COMMAND_BASE = {
    ClassName = "MENU_COMMAND_BASE",
    CommandMenuFunction = nil,
    CommandMenuArgument = nil,
    MenuCallHandler = nil,
  }
  
  --- Constructor
  -- @param #MENU_COMMAND_BASE
  -- @return #MENU_COMMAND_BASE
  function MENU_COMMAND_BASE:New( MenuText, ParentMenu, CommandMenuFunction, CommandMenuArguments )
  
    local self = BASE:Inherit( self, MENU_BASE:New( MenuText, ParentMenu ) ) -- #MENU_COMMAND_BASE
    -- When a menu function goes into error, DCS displays an obscure menu message.
    -- This error handler catches the menu error and displays the full call stack.
    local ErrorHandler = function( errmsg )
      env.info( "MOOSE error in MENU COMMAND function: " .. errmsg )
      if BASE.Debug ~= nil then
        env.info( BASE.Debug.traceback() )
      end
      return errmsg
    end
  
    self:SetCommandMenuFunction( CommandMenuFunction )
    self:SetCommandMenuArguments( CommandMenuArguments )
    self.MenuCallHandler = function()
      local function MenuFunction() 
        return self.CommandMenuFunction( unpack( self.CommandMenuArguments ) )
      end
      local Status, Result = xpcall( MenuFunction, ErrorHandler )
    end
    
    return self
  end
  
  --- This sets the new command function of a menu, 
  -- so that if a menu is regenerated, or if command function changes,
  -- that the function set for the menu is loosely coupled with the menu itself!!!
  -- If the function changes, no new menu needs to be generated if the menu text is the same!!!
  -- @param #MENU_COMMAND_BASE
  -- @return #MENU_COMMAND_BASE
  function MENU_COMMAND_BASE:SetCommandMenuFunction( CommandMenuFunction )
    self.CommandMenuFunction = CommandMenuFunction
    return self
  end
  --- This sets the new command arguments of a menu, 
  -- so that if a menu is regenerated, or if command arguments change,
  -- that the arguments set for the menu are loosely coupled with the menu itself!!!
  -- If the arguments change, no new menu needs to be generated if the menu text is the same!!!
  -- @param #MENU_COMMAND_BASE
  -- @return #MENU_COMMAND_BASE
  function MENU_COMMAND_BASE:SetCommandMenuArguments( CommandMenuArguments )
    self.CommandMenuArguments = CommandMenuArguments
    return self
  end
end

do -- MENU_MISSION
  --- @type MENU_MISSION
  -- @extends Core.Menu#MENU_BASE
  --- Manages the main menus for a complete mission.  
  -- 
  -- You can add menus with the @{#MENU_MISSION.New} method, which constructs a MENU_MISSION object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_MISSION.Remove}.
  -- @field #MENU_MISSION
  MENU_MISSION = {
    ClassName = "MENU_MISSION",
  }
  
  --- MENU_MISSION constructor. Creates a new MENU_MISSION object and creates the menu for a complete mission file.
  -- @param #MENU_MISSION self
  -- @param #string MenuText The text for the menu.
  -- @param #table ParentMenu The parent menu. This parameter can be ignored if you want the menu to be located at the parent menu of DCS world (under F10 other).
  -- @return #MENU_MISSION
  function MENU_MISSION:New( MenuText, ParentMenu )
  
    MENU_INDEX:PrepareMission()
    local Path = MENU_INDEX:ParentPath( ParentMenu, MenuText )
    local MissionMenu = MENU_INDEX:HasMissionMenu( Path )   
    if MissionMenu then
      return MissionMenu
    else
      local self = BASE:Inherit( self, MENU_BASE:New( MenuText, ParentMenu ) )
      MENU_INDEX:SetMissionMenu( Path, self )
      
      self.MenuPath = missionCommands.addSubMenu( self.MenuText, self.MenuParentPath )
      self:SetParentMenu( self.MenuText, self )
      return self
    end
  
  end
  
  --- Refreshes a radio item for a mission
  -- @param #MENU_MISSION self
  -- @return #MENU_MISSION
  function MENU_MISSION:Refresh()
    do
      missionCommands.removeItem( self.MenuPath )
      self.MenuPath = missionCommands.addSubMenu( self.MenuText, self.MenuParentPath )
    end
    return self
  end
  
  --- Removes the sub menus recursively of this MENU_MISSION. Note that the main menu is kept!
  -- @param #MENU_MISSION self
  -- @return #MENU_MISSION
  function MENU_MISSION:RemoveSubMenus()
  
    for MenuID, Menu in pairs( self.Menus or {} ) do
      Menu:Remove()
    end
    
    self.Menus = nil
  
  end
  
  --- Removes the main menu and the sub menus recursively of this MENU_MISSION.
  -- @param #MENU_MISSION self
  -- @return #nil
  function MENU_MISSION:Remove( MenuStamp, MenuTag )
  
    MENU_INDEX:PrepareMission()
    local Path = MENU_INDEX:ParentPath( self.ParentMenu, self.MenuText )
    local MissionMenu = MENU_INDEX:HasMissionMenu( Path )   
    if MissionMenu == self then
      self:RemoveSubMenus()
      if not MenuStamp or self.MenuStamp ~= MenuStamp then
        if ( not MenuTag ) or ( MenuTag and self.MenuTag and MenuTag == self.MenuTag ) then
          self:F( { Text = self.MenuText, Path = self.MenuPath } )
          if self.MenuPath ~= nil then
            missionCommands.removeItem( self.MenuPath )
          end
          MENU_INDEX:ClearMissionMenu( self.Path )
          self:ClearParentMenu( self.MenuText )
          return nil
        end
      end
    else
      BASE:E( { "Cannot Remove MENU_MISSION", Path = Path, ParentMenu = self.ParentMenu, MenuText = self.MenuText } )
    end
  
    return self
  end

end
do -- MENU_MISSION_COMMAND
  
  --- @type MENU_MISSION_COMMAND
  -- @extends Core.Menu#MENU_COMMAND_BASE
  
  --- Manages the command menus for a complete mission, which allow players to execute functions during mission execution.  
  -- 
  -- You can add menus with the @{#MENU_MISSION_COMMAND.New} method, which constructs a MENU_MISSION_COMMAND object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_MISSION_COMMAND.Remove}.
  -- 
  -- @field #MENU_MISSION_COMMAND
  MENU_MISSION_COMMAND = {
    ClassName = "MENU_MISSION_COMMAND",
  }
  
  --- MENU_MISSION constructor. Creates a new radio command item for a complete mission file, which can invoke a function with parameters.
  -- @param #MENU_MISSION_COMMAND self
  -- @param #string MenuText The text for the menu.
  -- @param Core.Menu#MENU_MISSION ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @param CommandMenuArgument An argument for the function. There can only be ONE argument given. So multiple arguments must be wrapped into a table. See the below example how to do this.
  -- @return #MENU_MISSION_COMMAND self
  function MENU_MISSION_COMMAND:New( MenuText, ParentMenu, CommandMenuFunction, ... )
  
    MENU_INDEX:PrepareMission()
    local Path = MENU_INDEX:ParentPath( ParentMenu, MenuText )
    local MissionMenu = MENU_INDEX:HasMissionMenu( Path )   
    if MissionMenu then
      MissionMenu:SetCommandMenuFunction( CommandMenuFunction )
      MissionMenu:SetCommandMenuArguments( arg )
      return MissionMenu
    else
      local self = BASE:Inherit( self, MENU_COMMAND_BASE:New( MenuText, ParentMenu, CommandMenuFunction, arg ) )
      MENU_INDEX:SetMissionMenu( Path, self )
      
      self.MenuPath = missionCommands.addCommand( MenuText, self.MenuParentPath, self.MenuCallHandler )
      self:SetParentMenu( self.MenuText, self )
      return self
    end
  end
  --- Refreshes a radio item for a mission
  -- @param #MENU_MISSION_COMMAND self
  -- @return #MENU_MISSION_COMMAND
  function MENU_MISSION_COMMAND:Refresh()
    do
      missionCommands.removeItem( self.MenuPath )
      missionCommands.addCommand( self.MenuText, self.MenuParentPath, self.MenuCallHandler )
    end
    return self
  end
  
  --- Removes a radio command item for a coalition
  -- @param #MENU_MISSION_COMMAND self
  -- @return #nil
  function MENU_MISSION_COMMAND:Remove()
  
    MENU_INDEX:PrepareMission()
    local Path = MENU_INDEX:ParentPath( self.ParentMenu, self.MenuText )
    local MissionMenu = MENU_INDEX:HasMissionMenu( Path )   
    if MissionMenu == self then
      if not MenuStamp or self.MenuStamp ~= MenuStamp then
        if ( not MenuTag ) or ( MenuTag and self.MenuTag and MenuTag == self.MenuTag ) then
          self:F( { Text = self.MenuText, Path = self.MenuPath } )
          if self.MenuPath ~= nil then
            missionCommands.removeItem( self.MenuPath )
          end
          MENU_INDEX:ClearMissionMenu( self.Path )
          self:ClearParentMenu( self.MenuText )
          return nil
        end
      end
    else
      BASE:E( { "Cannot Remove MENU_MISSION_COMMAND", Path = Path, ParentMenu = self.ParentMenu, MenuText = self.MenuText } )
    end
  
    return self
  end
end
do -- MENU_COALITION
  --- @type MENU_COALITION
  -- @extends Core.Menu#MENU_BASE
  
  --- Manages the main menus for @{DCS.coalition}s.  
  -- 
  -- You can add menus with the @{#MENU_COALITION.New} method, which constructs a MENU_COALITION object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_COALITION.Remove}.
  -- 
  --
  -- @usage
  --  -- This demo creates a menu structure for the planes within the red coalition.
  --  -- To test, join the planes, then look at the other radio menus (Option F10).
  --  -- Then switch planes and check if the menu is still there.
  --
  --  local Plane1 = CLIENT:FindByName( "Plane 1" )
  --  local Plane2 = CLIENT:FindByName( "Plane 2" )
  --
  --
  --  -- This would create a menu for the red coalition under the main DCS "Others" menu.
  --  local MenuCoalitionRed = MENU_COALITION:New( coalition.side.RED, "Manage Menus" )
  --
  --
  --  local function ShowStatus( StatusText, Coalition )
  --
  --    MESSAGE:New( Coalition, 15 ):ToRed()
  --    Plane1:Message( StatusText, 15 )
  --    Plane2:Message( StatusText, 15 )
  --  end
  --
  --  local MenuStatus -- Menu#MENU_COALITION
  --  local MenuStatusShow -- Menu#MENU_COALITION_COMMAND
  --
  --  local function RemoveStatusMenu()
  --    MenuStatus:Remove()
  --  end
  --
  --  local function AddStatusMenu()
  --    
  --    -- This would create a menu for the red coalition under the MenuCoalitionRed menu object.
  --    MenuStatus = MENU_COALITION:New( coalition.side.RED, "Status for Planes" )
  --    MenuStatusShow = MENU_COALITION_COMMAND:New( coalition.side.RED, "Show Status", MenuStatus, ShowStatus, "Status of planes is ok!", "Message to Red Coalition" )
  --  end
  --
  --  local MenuAdd = MENU_COALITION_COMMAND:New( coalition.side.RED, "Add Status Menu", MenuCoalitionRed, AddStatusMenu )
  --  local MenuRemove = MENU_COALITION_COMMAND:New( coalition.side.RED, "Remove Status Menu", MenuCoalitionRed, RemoveStatusMenu )
  --  
  --  @field #MENU_COALITION
  MENU_COALITION = {
    ClassName = "MENU_COALITION"
  }
  
  --- MENU_COALITION constructor. Creates a new MENU_COALITION object and creates the menu for a complete coalition.
  -- @param #MENU_COALITION self
  -- @param DCS#coalition.side Coalition The coalition owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param #table ParentMenu The parent menu. This parameter can be ignored if you want the menu to be located at the parent menu of DCS world (under F10 other).
  -- @return #MENU_COALITION self
  function MENU_COALITION:New( Coalition, MenuText, ParentMenu )
    MENU_INDEX:PrepareCoalition( Coalition )
    local Path = MENU_INDEX:ParentPath( ParentMenu, MenuText )
    local CoalitionMenu = MENU_INDEX:HasCoalitionMenu( Coalition, Path )   
    if CoalitionMenu then
      return CoalitionMenu
    else
      local self = BASE:Inherit( self, MENU_BASE:New( MenuText, ParentMenu ) )
      MENU_INDEX:SetCoalitionMenu( Coalition, Path, self )
      
      self.Coalition = Coalition
    
      self.MenuPath = missionCommands.addSubMenuForCoalition( Coalition, MenuText, self.MenuParentPath )
      self:SetParentMenu( self.MenuText, self )
      return self
    end
  end
  --- Refreshes a radio item for a coalition
  -- @param #MENU_COALITION self
  -- @return #MENU_COALITION
  function MENU_COALITION:Refresh()
    do
      missionCommands.removeItemForCoalition( self.Coalition, self.MenuPath )
      missionCommands.addSubMenuForCoalition( self.Coalition, self.MenuText, self.MenuParentPath )
    end
    return self
  end
  
  --- Removes the sub menus recursively of this MENU_COALITION. Note that the main menu is kept!
  -- @param #MENU_COALITION self
  -- @return #MENU_COALITION
  function MENU_COALITION:RemoveSubMenus()
  
    for MenuID, Menu in pairs( self.Menus or {} ) do
      Menu:Remove()
    end
    
    self.Menus = nil
  end
  
  --- Removes the main menu and the sub menus recursively of this MENU_COALITION.
  -- @param #MENU_COALITION self
  -- @return #nil
  function MENU_COALITION:Remove( MenuStamp, MenuTag )
  
    MENU_INDEX:PrepareCoalition( self.Coalition )
    local Path = MENU_INDEX:ParentPath( self.ParentMenu, self.MenuText )
    local CoalitionMenu = MENU_INDEX:HasCoalitionMenu( self.Coalition, Path )   
    if CoalitionMenu == self then
      self:RemoveSubMenus()
      if not MenuStamp or self.MenuStamp ~= MenuStamp then
        if ( not MenuTag ) or ( MenuTag and self.MenuTag and MenuTag == self.MenuTag ) then
          self:F( { Coalition = self.Coalition, Text = self.MenuText, Path = self.MenuPath } )
          if self.MenuPath ~= nil then
            missionCommands.removeItemForCoalition( self.Coalition, self.MenuPath )
          end
          MENU_INDEX:ClearCoalitionMenu( self.Coalition, Path )
          self:ClearParentMenu( self.MenuText )
          return nil
        end
      end
    else
      BASE:E( { "Cannot Remove MENU_COALITION", Path = Path, ParentMenu = self.ParentMenu, MenuText = self.MenuText, Coalition = self.Coalition } )
    end
  
    return self
  end
end
do -- MENU_COALITION_COMMAND
  
  --- @type MENU_COALITION_COMMAND
  -- @extends Core.Menu#MENU_COMMAND_BASE
  
  --- Manages the command menus for coalitions, which allow players to execute functions during mission execution.  
  -- 
  -- You can add menus with the @{#MENU_COALITION_COMMAND.New} method, which constructs a MENU_COALITION_COMMAND object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_COALITION_COMMAND.Remove}.
  --
  -- @field #MENU_COALITION_COMMAND
  MENU_COALITION_COMMAND = {
    ClassName = "MENU_COALITION_COMMAND"
  }
  
  --- MENU_COALITION constructor. Creates a new radio command item for a coalition, which can invoke a function with parameters.
  -- @param #MENU_COALITION_COMMAND self
  -- @param DCS#coalition.side Coalition The coalition owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param Core.Menu#MENU_COALITION ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @param CommandMenuArgument An argument for the function. There can only be ONE argument given. So multiple arguments must be wrapped into a table. See the below example how to do this.
  -- @return #MENU_COALITION_COMMAND
  function MENU_COALITION_COMMAND:New( Coalition, MenuText, ParentMenu, CommandMenuFunction, ... )
  
    MENU_INDEX:PrepareCoalition( Coalition )
    local Path = MENU_INDEX:ParentPath( ParentMenu, MenuText )
    local CoalitionMenu = MENU_INDEX:HasCoalitionMenu( Coalition, Path )   
    if CoalitionMenu then
      CoalitionMenu:SetCommandMenuFunction( CommandMenuFunction )
      CoalitionMenu:SetCommandMenuArguments( arg )
      return CoalitionMenu
    else
  
      local self = BASE:Inherit( self, MENU_COMMAND_BASE:New( MenuText, ParentMenu, CommandMenuFunction, arg ) )
      MENU_INDEX:SetCoalitionMenu( Coalition, Path, self )
      
      self.Coalition = Coalition
      self.MenuPath = missionCommands.addCommandForCoalition( self.Coalition, MenuText, self.MenuParentPath, self.MenuCallHandler )
      self:SetParentMenu( self.MenuText, self )
      return self
    end
  end
  --- Refreshes a radio item for a coalition
  -- @param #MENU_COALITION_COMMAND self
  -- @return #MENU_COALITION_COMMAND
  function MENU_COALITION_COMMAND:Refresh()
    do
      missionCommands.removeItemForCoalition( self.Coalition, self.MenuPath )
      missionCommands.addCommandForCoalition( self.Coalition, self.MenuText, self.MenuParentPath, self.MenuCallHandler )
    end
    
    return self
  end
  
  --- Removes a radio command item for a coalition
  -- @param #MENU_COALITION_COMMAND self
  -- @return #nil
  function MENU_COALITION_COMMAND:Remove( MenuStamp, MenuTag )
  
    MENU_INDEX:PrepareCoalition( self.Coalition )
    local Path = MENU_INDEX:ParentPath( self.ParentMenu, self.MenuText )
    local CoalitionMenu = MENU_INDEX:HasCoalitionMenu( self.Coalition, Path )   
    if CoalitionMenu == self then
      if not MenuStamp or self.MenuStamp ~= MenuStamp then
        if ( not MenuTag ) or ( MenuTag and self.MenuTag and MenuTag == self.MenuTag ) then
          self:F( { Coalition = self.Coalition, Text = self.MenuText, Path = self.MenuPath } )
          if self.MenuPath ~= nil then
            missionCommands.removeItemForCoalition( self.Coalition, self.MenuPath )
          end
          MENU_INDEX:ClearCoalitionMenu( self.Coalition, Path )
          self:ClearParentMenu( self.MenuText )
          return nil
        end
      end
    else
      BASE:E( { "Cannot Remove MENU_COALITION_COMMAND", Path = Path, ParentMenu = self.ParentMenu, MenuText = self.MenuText, Coalition = self.Coalition } )
    end
  
    return self
  end
end

--- MENU_GROUP
do
  -- This local variable is used to cache the menus registered under groups.
  -- Menus don't disappear when groups for players are destroyed and restarted.
  -- So every menu for a client created must be tracked so that program logic accidentally does not create.
  -- the same menus twice during initialization logic.
  -- These menu classes are handling this logic with this variable.
  local _MENUGROUPS = {}
  --- @type MENU_GROUP
  -- @extends Core.Menu#MENU_BASE
  
  
  --- Manages the main menus for @{Wrapper.Group}s.  
  -- 
  -- You can add menus with the @{#MENU_GROUP.New} method, which constructs a MENU_GROUP object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_GROUP.Remove}.
  -- 
  -- @usage
  --  -- This demo creates a menu structure for the two groups of planes.
  --  -- Each group will receive a different menu structure.
  --  -- To test, join the planes, then look at the other radio menus (Option F10).
  --  -- Then switch planes and check if the menu is still there.
  --  -- And play with the Add and Remove menu options.
  --  
  --  -- Note that in multi player, this will only work after the DCS groups bug is solved.
  --
  --  local function ShowStatus( PlaneGroup, StatusText, Coalition )
  --
  --    MESSAGE:New( Coalition, 15 ):ToRed()
  --    PlaneGroup:Message( StatusText, 15 )
  --  end
  --
  --  local MenuStatus = {}
  --
  --  local function RemoveStatusMenu( MenuGroup )
  --    local MenuGroupName = MenuGroup:GetName()
  --    MenuStatus[MenuGroupName]:Remove()
  --  end
  --
  --  --- @param Wrapper.Group#GROUP MenuGroup
  --  local function AddStatusMenu( MenuGroup )
  --    local MenuGroupName = MenuGroup:GetName()
  --    -- This would create a menu for the red coalition under the MenuCoalitionRed menu object.
  --    MenuStatus[MenuGroupName] = MENU_GROUP:New( MenuGroup, "Status for Planes" )
  --    MENU_GROUP_COMMAND:New( MenuGroup, "Show Status", MenuStatus[MenuGroupName], ShowStatus, MenuGroup, "Status of planes is ok!", "Message to Red Coalition" )
  --  end
  --
  --  SCHEDULER:New( nil,
  --    function()
  --      local PlaneGroup = GROUP:FindByName( "Plane 1" )
  --      if PlaneGroup and PlaneGroup:IsAlive() then
  --        local MenuManage = MENU_GROUP:New( PlaneGroup, "Manage Menus" )
  --        MENU_GROUP_COMMAND:New( PlaneGroup, "Add Status Menu Plane 1", MenuManage, AddStatusMenu, PlaneGroup )
  --        MENU_GROUP_COMMAND:New( PlaneGroup, "Remove Status Menu Plane 1", MenuManage, RemoveStatusMenu, PlaneGroup )
  --      end
  --    end, {}, 10, 10 )
  --
  --  SCHEDULER:New( nil,
  --    function()
  --      local PlaneGroup = GROUP:FindByName( "Plane 2" )
  --      if PlaneGroup and PlaneGroup:IsAlive() then
  --        local MenuManage = MENU_GROUP:New( PlaneGroup, "Manage Menus" )
  --        MENU_GROUP_COMMAND:New( PlaneGroup, "Add Status Menu Plane 2", MenuManage, AddStatusMenu, PlaneGroup )
  --        MENU_GROUP_COMMAND:New( PlaneGroup, "Remove Status Menu Plane 2", MenuManage, RemoveStatusMenu, PlaneGroup )
  --      end
  --    end, {}, 10, 10 )
  --
  -- @field #MENU_GROUP
  MENU_GROUP = {
    ClassName = "MENU_GROUP"
  }
  
  --- MENU_GROUP constructor. Creates a new radio menu item for a group.
  -- @param #MENU_GROUP self
  -- @param Wrapper.Group#GROUP Group The Group owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param #table ParentMenu The parent menu.
  -- @return #MENU_GROUP self
  function MENU_GROUP:New( Group, MenuText, ParentMenu )
  
    MENU_INDEX:PrepareGroup( Group )
    local Path = MENU_INDEX:ParentPath( ParentMenu, MenuText )
    local GroupMenu = MENU_INDEX:HasGroupMenu( Group, Path )
    if GroupMenu then
      return GroupMenu
    else
      self = BASE:Inherit( self, MENU_BASE:New( MenuText, ParentMenu ) )
      MENU_INDEX:SetGroupMenu( Group, Path, self )
      self.Group = Group
      self.GroupID = Group:GetID()
      self.MenuPath = missionCommands.addSubMenuForGroup( self.GroupID, MenuText, self.MenuParentPath )
      
      self:SetParentMenu( self.MenuText, self )
      return self
    end
    
  end
  
  --- Refreshes a new radio item for a group and submenus
  -- @param #MENU_GROUP self
  -- @return #MENU_GROUP
  function MENU_GROUP:Refresh()
    do
      missionCommands.removeItemForGroup( self.GroupID, self.MenuPath )
      missionCommands.addSubMenuForGroup( self.GroupID, self.MenuText, self.MenuParentPath )
      
      for MenuText, Menu in pairs( self.Menus or {} ) do
        Menu:Refresh()
      end
    end
    
    return self
  end
  
  --- Refreshes a new radio item for a group and submenus, ordering by (numerical) MenuTag
  -- @param #MENU_GROUP self
  -- @return #MENU_GROUP
  function MENU_GROUP:RefreshAndOrderByTag()

    do
      missionCommands.removeItemForGroup( self.GroupID, self.MenuPath )
      missionCommands.addSubMenuForGroup( self.GroupID, self.MenuText, self.MenuParentPath )
      
      local MenuTable = {}
      for MenuText, Menu in pairs( self.Menus or {} ) do
        local tag = Menu.MenuTag or math.random(1,10000)
        MenuTable[#MenuTable+1] = {Tag=tag, Enty=Menu}
      end
      table.sort(MenuTable, function (k1, k2) return k1.tag < k2.tag end )
      for _, Menu in pairs( MenuTable ) do
        Menu.Entry:Refresh()
      end 
    end
    
    return self
  end
  
  --- Removes the sub menus recursively of this MENU_GROUP.
  -- @param #MENU_GROUP self
  -- @param MenuStamp
  -- @param MenuTag A Tag or Key to filter the menus to be refreshed with the Tag set.
  -- @return #MENU_GROUP self
  function MENU_GROUP:RemoveSubMenus( MenuStamp, MenuTag )
    for MenuText, Menu in pairs( self.Menus or {} ) do
      Menu:Remove( MenuStamp, MenuTag )
    end
    
    self.Menus = nil
  
  end

  --- Removes the main menu and sub menus recursively of this MENU_GROUP.
  -- @param #MENU_GROUP self
  -- @param MenuStamp
  -- @param MenuTag A Tag or Key to filter the menus to be refreshed with the Tag set.
  -- @return #nil
  function MENU_GROUP:Remove( MenuStamp, MenuTag )
    MENU_INDEX:PrepareGroup( self.Group )
    local Path = MENU_INDEX:ParentPath( self.ParentMenu, self.MenuText )
    local GroupMenu = MENU_INDEX:HasGroupMenu( self.Group, Path )   
    if GroupMenu == self then
      self:RemoveSubMenus( MenuStamp, MenuTag )
      if not MenuStamp or self.MenuStamp ~= MenuStamp then
        if ( not MenuTag ) or ( MenuTag and self.MenuTag and MenuTag == self.MenuTag ) then
          if self.MenuPath ~= nil then
            self:F( { Group = self.GroupID, Text = self.MenuText, Path = self.MenuPath } )
            missionCommands.removeItemForGroup( self.GroupID, self.MenuPath )
          end
          MENU_INDEX:ClearGroupMenu( self.Group, Path )
          self:ClearParentMenu( self.MenuText )
          return nil
        end
      end
    else
      BASE:E( { "Cannot Remove MENU_GROUP", Path = Path, ParentMenu = self.ParentMenu, MenuText = self.MenuText, Group = self.Group } )
      return nil
    end
  
    return self
  end
  
  
  --- @type MENU_GROUP_COMMAND
  -- @extends Core.Menu#MENU_COMMAND_BASE
  
  --- The @{Core.Menu#MENU_GROUP_COMMAND} class manages the command menus for coalitions, which allow players to execute functions during mission execution.  
  -- You can add menus with the @{#MENU_GROUP_COMMAND.New} method, which constructs a MENU_GROUP_COMMAND object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_GROUP_COMMAND.Remove}.
  --
  -- @field #MENU_GROUP_COMMAND
  MENU_GROUP_COMMAND = {
    ClassName = "MENU_GROUP_COMMAND"
  }
  
  --- Creates a new radio command item for a group
  -- @param #MENU_GROUP_COMMAND self
  -- @param Wrapper.Group#GROUP Group The Group owning the menu.
  -- @param MenuText The text for the menu.
  -- @param ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @param CommandMenuArgument An argument for the function.
  -- @return #MENU_GROUP_COMMAND
  function MENU_GROUP_COMMAND:New( Group, MenuText, ParentMenu, CommandMenuFunction, ... )
    MENU_INDEX:PrepareGroup( Group )
    local Path = MENU_INDEX:ParentPath( ParentMenu, MenuText )
    local GroupMenu = MENU_INDEX:HasGroupMenu( Group, Path )   
    if GroupMenu then
      GroupMenu:SetCommandMenuFunction( CommandMenuFunction )
      GroupMenu:SetCommandMenuArguments( arg )
      return GroupMenu
    else
      self = BASE:Inherit( self, MENU_COMMAND_BASE:New( MenuText, ParentMenu, CommandMenuFunction, arg ) )
      MENU_INDEX:SetGroupMenu( Group, Path, self )
  
      self.Group = Group
      self.GroupID = Group:GetID()
  
      self.MenuPath = missionCommands.addCommandForGroup( self.GroupID, MenuText, self.MenuParentPath, self.MenuCallHandler )
      
      self:SetParentMenu( self.MenuText, self )
      return self
    end
  end
  --- Refreshes a radio item for a group
  -- @param #MENU_GROUP_COMMAND self
  -- @return #MENU_GROUP_COMMAND
  function MENU_GROUP_COMMAND:Refresh()
    do
      missionCommands.removeItemForGroup( self.GroupID, self.MenuPath )
      missionCommands.addCommandForGroup( self.GroupID, self.MenuText, self.MenuParentPath, self.MenuCallHandler )
    end
    
    return self
  end
  
  --- Removes a menu structure for a group.
  -- @param #MENU_GROUP_COMMAND self
  -- @param MenuStamp
  -- @param MenuTag A Tag or Key to filter the menus to be refreshed with the Tag set.
  -- @return #nil
  function MENU_GROUP_COMMAND:Remove( MenuStamp, MenuTag )
    MENU_INDEX:PrepareGroup( self.Group )
    local Path = MENU_INDEX:ParentPath( self.ParentMenu, self.MenuText )
    local GroupMenu = MENU_INDEX:HasGroupMenu( self.Group, Path )   
    if GroupMenu == self then
      if not MenuStamp or self.MenuStamp ~= MenuStamp then
        if ( not MenuTag ) or ( MenuTag and self.MenuTag and MenuTag == self.MenuTag ) then
          if self.MenuPath ~= nil then
           self:F( { Group = self.GroupID, Text = self.MenuText, Path = self.MenuPath } )
            missionCommands.removeItemForGroup( self.GroupID, self.MenuPath )
          end
          MENU_INDEX:ClearGroupMenu( self.Group, Path )
          self:ClearParentMenu( self.MenuText )
          return nil
        end
      end
    else
      BASE:E( { "Cannot Remove MENU_GROUP_COMMAND", Path = Path, ParentMenu = self.ParentMenu, MenuText = self.MenuText, Group = self.Group } )
    end
    
    return self
  end
end
--- MENU_GROUP_DELAYED
do
  --- @type MENU_GROUP_DELAYED
  -- @extends Core.Menu#MENU_BASE
  
  
  --- The MENU_GROUP_DELAYED class manages the main menus for groups.  
  -- You can add menus with the @{#MENU_GROUP.New} method, which constructs a MENU_GROUP object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_GROUP.Remove}.
  -- The creation of the menu item is delayed however, and must be created using the @{#MENU_GROUP.Set} method.
  -- This method is most of the time called after the "old" menu items have been removed from the sub menu.
  -- 
  --
  -- @field #MENU_GROUP_DELAYED
  MENU_GROUP_DELAYED = {
    ClassName = "MENU_GROUP_DELAYED"
  }
  
  --- MENU_GROUP_DELAYED constructor. Creates a new radio menu item for a group.
  -- @param #MENU_GROUP_DELAYED self
  -- @param Wrapper.Group#GROUP Group The Group owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param #table ParentMenu The parent menu.
  -- @return #MENU_GROUP_DELAYED self
  function MENU_GROUP_DELAYED:New( Group, MenuText, ParentMenu )
  
    MENU_INDEX:PrepareGroup( Group )
    local Path = MENU_INDEX:ParentPath( ParentMenu, MenuText )
    local GroupMenu = MENU_INDEX:HasGroupMenu( Group, Path )
    if GroupMenu then
      return GroupMenu
    else
      self = BASE:Inherit( self, MENU_BASE:New( MenuText, ParentMenu ) )
      MENU_INDEX:SetGroupMenu( Group, Path, self )
      self.Group = Group
      self.GroupID = Group:GetID()
      if self.MenuParentPath then
        self.MenuPath = UTILS.DeepCopy( self.MenuParentPath )
      else
        self.MenuPath = {}
      end
      table.insert( self.MenuPath, self.MenuText )
      
      self:SetParentMenu( self.MenuText, self )
      return self
    end
    
  end

  --- Refreshes a new radio item for a group and submenus
  -- @param #MENU_GROUP_DELAYED self
  -- @return #MENU_GROUP_DELAYED
  function MENU_GROUP_DELAYED:Set()
    do
      if not self.MenuSet then
        missionCommands.addSubMenuForGroup( self.GroupID, self.MenuText, self.MenuParentPath )
        self.MenuSet = true
      end
      
      for MenuText, Menu in pairs( self.Menus or {} ) do
        Menu:Set()
      end
    end
  end

  --- Refreshes a new radio item for a group and submenus
  -- @param #MENU_GROUP_DELAYED self
  -- @return #MENU_GROUP_DELAYED
  function MENU_GROUP_DELAYED:Refresh()
    do
      missionCommands.removeItemForGroup( self.GroupID, self.MenuPath )
      missionCommands.addSubMenuForGroup( self.GroupID, self.MenuText, self.MenuParentPath )
      
      for MenuText, Menu in pairs( self.Menus or {} ) do
        Menu:Refresh()
      end
    end
  
    return self
  end
  
  --- Removes the sub menus recursively of this MENU_GROUP_DELAYED.
  -- @param #MENU_GROUP_DELAYED self
  -- @param MenuStamp
  -- @param MenuTag A Tag or Key to filter the menus to be refreshed with the Tag set.
  -- @return #MENU_GROUP_DELAYED self
  function MENU_GROUP_DELAYED:RemoveSubMenus( MenuStamp, MenuTag )
    for MenuText, Menu in pairs( self.Menus or {} ) do
      Menu:Remove( MenuStamp, MenuTag )
    end
    
    self.Menus = nil
  
  end

  --- Removes the main menu and sub menus recursively of this MENU_GROUP.
  -- @param #MENU_GROUP_DELAYED self
  -- @param MenuStamp
  -- @param MenuTag A Tag or Key to filter the menus to be refreshed with the Tag set.
  -- @return #nil
  function MENU_GROUP_DELAYED:Remove( MenuStamp, MenuTag )
    MENU_INDEX:PrepareGroup( self.Group )
    local Path = MENU_INDEX:ParentPath( self.ParentMenu, self.MenuText )
    local GroupMenu = MENU_INDEX:HasGroupMenu( self.Group, Path )   
    if GroupMenu == self then
      self:RemoveSubMenus( MenuStamp, MenuTag )
      if not MenuStamp or self.MenuStamp ~= MenuStamp then
        if ( not MenuTag ) or ( MenuTag and self.MenuTag and MenuTag == self.MenuTag ) then
          if self.MenuPath ~= nil then
            self:F( { Group = self.GroupID, Text = self.MenuText, Path = self.MenuPath } )
            missionCommands.removeItemForGroup( self.GroupID, self.MenuPath )
          end
          MENU_INDEX:ClearGroupMenu( self.Group, Path )
          self:ClearParentMenu( self.MenuText )
          return nil
        end
      end
    else
      BASE:E( { "Cannot Remove MENU_GROUP_DELAYED", Path = Path, ParentMenu = self.ParentMenu, MenuText = self.MenuText, Group = self.Group } )
      return nil
    end
  
    return self
  end
  
  
  --- @type MENU_GROUP_COMMAND_DELAYED
  -- @extends Core.Menu#MENU_COMMAND_BASE
  
  --- Manages the command menus for coalitions, which allow players to execute functions during mission execution.  
  -- 
  -- You can add menus with the @{#MENU_GROUP_COMMAND_DELAYED.New} method, which constructs a MENU_GROUP_COMMAND_DELAYED object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_GROUP_COMMAND_DELAYED.Remove}.
  --
  -- @field #MENU_GROUP_COMMAND_DELAYED
  MENU_GROUP_COMMAND_DELAYED = {
    ClassName = "MENU_GROUP_COMMAND_DELAYED"
  }
  
  --- Creates a new radio command item for a group
  -- @param #MENU_GROUP_COMMAND_DELAYED self
  -- @param Wrapper.Group#GROUP Group The Group owning the menu.
  -- @param MenuText The text for the menu.
  -- @param ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @param CommandMenuArgument An argument for the function.
  -- @return #MENU_GROUP_COMMAND_DELAYED
  function MENU_GROUP_COMMAND_DELAYED:New( Group, MenuText, ParentMenu, CommandMenuFunction, ... )
    MENU_INDEX:PrepareGroup( Group )
    local Path = MENU_INDEX:ParentPath( ParentMenu, MenuText )
    local GroupMenu = MENU_INDEX:HasGroupMenu( Group, Path )   
    if GroupMenu then
      GroupMenu:SetCommandMenuFunction( CommandMenuFunction )
      GroupMenu:SetCommandMenuArguments( arg )
      return GroupMenu
    else
      self = BASE:Inherit( self, MENU_COMMAND_BASE:New( MenuText, ParentMenu, CommandMenuFunction, arg ) )
      MENU_INDEX:SetGroupMenu( Group, Path, self )
  
      self.Group = Group
      self.GroupID = Group:GetID()
      
      if self.MenuParentPath then
        self.MenuPath = UTILS.DeepCopy( self.MenuParentPath )
      else
        self.MenuPath = {}
      end
      table.insert( self.MenuPath, self.MenuText )
  
      self:SetParentMenu( self.MenuText, self )
      return self
    end
  end
  --- Refreshes a radio item for a group
  -- @param #MENU_GROUP_COMMAND_DELAYED self
  -- @return #MENU_GROUP_COMMAND_DELAYED
  function MENU_GROUP_COMMAND_DELAYED:Set()
    do
      if not self.MenuSet then
        self.MenuPath = missionCommands.addCommandForGroup( self.GroupID, self.MenuText, self.MenuParentPath, self.MenuCallHandler )
        self.MenuSet = true
      end
    end
  end
  
  --- Refreshes a radio item for a group
  -- @param #MENU_GROUP_COMMAND_DELAYED self
  -- @return #MENU_GROUP_COMMAND_DELAYED
  function MENU_GROUP_COMMAND_DELAYED:Refresh()
    do
      missionCommands.removeItemForGroup( self.GroupID, self.MenuPath )
      missionCommands.addCommandForGroup( self.GroupID, self.MenuText, self.MenuParentPath, self.MenuCallHandler )
    end
  
    return self
  end
  
  --- Removes a menu structure for a group.
  -- @param #MENU_GROUP_COMMAND_DELAYED self
  -- @param MenuStamp
  -- @param MenuTag A Tag or Key to filter the menus to be refreshed with the Tag set.
  -- @return #nil
  function MENU_GROUP_COMMAND_DELAYED:Remove( MenuStamp, MenuTag )
    MENU_INDEX:PrepareGroup( self.Group )
    local Path = MENU_INDEX:ParentPath( self.ParentMenu, self.MenuText )
    local GroupMenu = MENU_INDEX:HasGroupMenu( self.Group, Path )   
    if GroupMenu == self then
      if not MenuStamp or self.MenuStamp ~= MenuStamp then
        if ( not MenuTag ) or ( MenuTag and self.MenuTag and MenuTag == self.MenuTag ) then
          if self.MenuPath ~= nil then
            self:F( { Group = self.GroupID, Text = self.MenuText, Path = self.MenuPath } )
            missionCommands.removeItemForGroup( self.GroupID, self.MenuPath )
          end
          MENU_INDEX:ClearGroupMenu( self.Group, Path )
          self:ClearParentMenu( self.MenuText )
          return nil
        end
      end
    else
      BASE:E( { "Cannot Remove MENU_GROUP_COMMAND_DELAYED", Path = Path, ParentMenu = self.ParentMenu, MenuText = self.MenuText, Group = self.Group } )
    end
    
    return self
  end
end
