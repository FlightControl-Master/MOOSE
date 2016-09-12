--- This module contains the MENU classes.
-- 
--  There is a small note... When you see a class like MENU_COMMAND_COALITION with COMMAND in italic, it acutally represents it like this: `MENU_COMMAND_COALITION`.
-- 
-- ===
-- 
-- DCS Menus can be managed using the MENU classes. 
-- The advantage of using MENU classes is that it hides the complexity of dealing with menu management in more advanced scanerios where you need to 
-- set menus and later remove them, and later set them again. You'll find while using use normal DCS scripting functions, that setting and removing
-- menus is not a easy feat if you have complex menu hierarchies defined. 
-- Using the MOOSE menu classes, the removal and refreshing of menus are nicely being handled within these classes, and becomes much more easy.
-- On top, MOOSE implements **variable parameter** passing for command menus. 
-- 
-- There are basically two different MENU class types that you need to use:
-- 
-- ### To manage **main menus**, the classes begin with **MENU_**:
-- 
--   * @{Menu#MENU_MISSION}: Manages main menus for whole mission file.
--   * @{Menu#MENU_COALITION}: Manages main menus for whole coalition.
--   * @{Menu#MENU_GROUP}: Manages main menus for GROUPs.
--   * @{Menu#MENU_CLIENT}: Manages main menus for CLIENTs. This manages menus for units with the skill level "Client".
--   
-- ### To manage **command menus**, which are menus that allow the player to issue **functions**, the classes begin with **MENU_COMMAND_**:
--   
--   * @{Menu#MENU_MISSION_COMMAND}: Manages command menus for whole mission file.
--   * @{Menu#MENU_COALITION_COMMAND}: Manages command menus for whole coalition.
--   * @{Menu#MENU_GROUP_COMMAND}: Manages command menus for GROUPs.
--   * @{Menu#MENU_CLIENT_COMMAND}: Manages command menus for CLIENTs. This manages menus for units with the skill level "Client".
-- 
-- ===
-- 
-- The above menus classes **are derived** from 2 main **abstract** classes defined within the MOOSE framework (so don't use these):
-- 
-- 1) MENU_ BASE abstract base classes (don't use them)
-- ====================================================
-- The underlying base menu classes are **NOT** to be used within your missions.
-- These are simply abstract base classes defining a couple of fields that are used by the 
-- derived MENU_ classes to manage menus.
-- 
-- 1.1) @{Menu#MENU_BASE} class, extends @{Base#BASE}
-- --------------------------------------------------
-- The @{#MENU_BASE} class defines the main MENU class where other MENU classes are derived from.
-- 
-- 1.2) @{Menu#MENU_COMMAND_BASE} class, extends @{Base#BASE}
-- ----------------------------------------------------------
-- The @{#MENU_COMMAND_BASE} class defines the main MENU class where other MENU COMMAND_ classes are derived from, in order to set commands.
-- 
-- ===
-- 
-- **The next menus define the MENU classes that you can use within your missions.**
--  
-- 2) MENU MISSION classes
-- ======================
-- The underlying classes manage the menus for a complete mission file.
-- 
-- 2.1) @{Menu#MENU_MISSION} class, extends @{Menu#MENU_BASE}
-- ---------------------------------------------------------
-- The @{Menu#MENU_MISSION} class manages the main menus for a complete mission.  
-- You can add menus with the @{#MENU_MISSION.New} method, which constructs a MENU_MISSION object and returns you the object reference.
-- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_MISSION.Remove}.
-- 
-- 2.2) @{Menu#MENU_MISSION_COMMAND} class, extends @{Menu#MENU_COMMAND_BASE}
-- -------------------------------------------------------------------------
-- The @{Menu#MENU_MISSION_COMMAND} class manages the command menus for a complete mission, which allow players to execute functions during mission execution.  
-- You can add menus with the @{#MENU_MISSION_COMMAND.New} method, which constructs a MENU_MISSION_COMMAND object and returns you the object reference.
-- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_MISSION_COMMAND.Remove}.
-- 
-- ===
-- 
-- 3) MENU COALITION classes
-- =========================
-- The underlying classes manage the menus for whole coalitions.
-- 
-- 3.1) @{Menu#MENU_COALITION} class, extends @{Menu#MENU_BASE}
-- ------------------------------------------------------------
-- The @{Menu#MENU_COALITION} class manages the main menus for coalitions.  
-- You can add menus with the @{#MENU_COALITION.New} method, which constructs a MENU_COALITION object and returns you the object reference.
-- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_COALITION.Remove}.
-- 
-- 3.2) @{Menu#MENU_COALITION_COMMAND} class, extends @{Menu#MENU_COMMAND_BASE}
-- ----------------------------------------------------------------------------
-- The @{Menu#MENU_COALITION_COMMAND} class manages the command menus for coalitions, which allow players to execute functions during mission execution.  
-- You can add menus with the @{#MENU_COALITION_COMMAND.New} method, which constructs a MENU_COALITION_COMMAND object and returns you the object reference.
-- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_COALITION_COMMAND.Remove}.
-- 
-- ===
-- 
-- 4) MENU GROUP classes
-- =====================
-- The underlying classes manage the menus for groups. Note that groups can be inactive, alive or can be destroyed.
-- 
-- 4.1) @{Menu#MENU_GROUP} class, extends @{Menu#MENU_BASE}
-- --------------------------------------------------------
-- The @{Menu#MENU_GROUP} class manages the main menus for coalitions.  
-- You can add menus with the @{#MENU_GROUP.New} method, which constructs a MENU_GROUP object and returns you the object reference.
-- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_GROUP.Remove}.
-- 
-- 4.2) @{Menu#MENU_GROUP_COMMAND} class, extends @{Menu#MENU_COMMAND_BASE}
-- ------------------------------------------------------------------------
-- The @{Menu#MENU_GROUP_COMMAND} class manages the command menus for coalitions, which allow players to execute functions during mission execution.  
-- You can add menus with the @{#MENU_GROUP_COMMAND.New} method, which constructs a MENU_GROUP_COMMAND object and returns you the object reference.
-- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_GROUP_COMMAND.Remove}.
-- 
-- ===
-- 
-- 5) MENU CLIENT classes
-- ======================
-- The underlying classes manage the menus for units with skill level client or player.
-- 
-- 5.1) @{Menu#MENU_CLIENT} class, extends @{Menu#MENU_BASE}
-- ---------------------------------------------------------
-- The @{Menu#MENU_CLIENT} class manages the main menus for coalitions.  
-- You can add menus with the @{#MENU_CLIENT.New} method, which constructs a MENU_CLIENT object and returns you the object reference.
-- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_CLIENT.Remove}.
-- 
-- 5.2) @{Menu#MENU_CLIENT_COMMAND} class, extends @{Menu#MENU_COMMAND_BASE}
-- -------------------------------------------------------------------------
-- The @{Menu#MENU_CLIENT_COMMAND} class manages the command menus for coalitions, which allow players to execute functions during mission execution.  
-- You can add menus with the @{#MENU_CLIENT_COMMAND.New} method, which constructs a MENU_CLIENT_COMMAND object and returns you the object reference.
-- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_CLIENT_COMMAND.Remove}.
-- 
-- ===
-- 
-- ### Contributions: -
-- ### Authors: FlightControl : Design & Programming
-- 
-- @module Menu


do -- MENU_BASE

  --- The MENU_BASE class
  -- @type MENU_BASE
  -- @extends Base#BASE
  MENU_BASE = {
    ClassName = "MENU_BASE",
    MenuPath = nil,
    MenuText = "",
    MenuParentPath = nil
  }
  
  --- Consructor
  function MENU_BASE:New( MenuText, ParentMenu )
  
    local MenuParentPath = {}
    if ParentMenu ~= nil then
      MenuParentPath = ParentMenu.MenuPath
    end

  	local self = BASE:Inherit( self, BASE:New() )
  
  	self.MenuPath = nil 
  	self.MenuText = MenuText
  	self.MenuParentPath = MenuParentPath
  	
  	return self
  end
  
end

do -- MENU_COMMAND_BASE

  --- The MENU_COMMAND_BASE class
  -- @type MENU_COMMAND_BASE
  -- @field #function MenuCallHandler
  -- @extends Menu#MENU_BASE
  MENU_COMMAND_BASE = {
    ClassName = "MENU_COMMAND_BASE",
    CommandMenuFunction = nil,
    CommandMenuArgument = nil,
    MenuCallHandler = nil,
  }
  
  --- Constructor
  function MENU_COMMAND_BASE:New( MenuText, ParentMenu, CommandMenuFunction, CommandMenuArguments )
  
  	local self = BASE:Inherit( self, MENU_BASE:New( MenuText, ParentMenu ) )
  
    self.CommandMenuFunction = CommandMenuFunction
    self.MenuCallHandler = function( CommandMenuArguments )
      self.CommandMenuFunction( unpack( CommandMenuArguments ) )
    end
  	
  	return self
  end

end


do -- MENU_MISSION

  --- The MENU_MISSION class
  -- @type MENU_MISSION
  -- @extends Menu#MENU_BASE
  MENU_MISSION = {
    ClassName = "MENU_MISSION"
  }
  
  --- MENU_MISSION constructor. Creates a new MENU_MISSION object and creates the menu for a complete mission file.
  -- @param #MENU_MISSION self
  -- @param #string MenuText The text for the menu.
  -- @param #table ParentMenu The parent menu. This parameter can be ignored if you want the menu to be located at the perent menu of DCS world (under F10 other).
  -- @return #MENU_MISSION self
  function MENU_MISSION:New( MenuText, ParentMenu )
  
    local self = BASE:Inherit( self, MENU_BASE:New( MenuText, ParentMenu ) )
    
    self:F( { MenuText, ParentMenu } )
  
    self.MenuText = MenuText
    self.ParentMenu = ParentMenu
    
    self.Menus = {}
  
    self:T( { MenuText } )
  
    self.MenuPath = missionCommands.addSubMenu( MenuText, self.MenuParentPath )
  
    self:T( { self.MenuPath } )
  
    if ParentMenu and ParentMenu.Menus then
      ParentMenu.Menus[self.MenuPath] = self
    end

    return self
  end
  
  --- Removes the sub menus recursively of this MENU_MISSION. Note that the main menu is kept!
  -- @param #MENU_MISSION self
  -- @return #MENU_MISSION self
  function MENU_MISSION:RemoveSubMenus()
    self:F( self.MenuPath )
  
    for MenuID, Menu in pairs( self.Menus ) do
      Menu:Remove()
    end
  
  end
  
  --- Removes the main menu and the sub menus recursively of this MENU_MISSION.
  -- @param #MENU_MISSION self
  -- @return #nil
  function MENU_MISSION:Remove()
    self:F( self.MenuPath )
  
    self:RemoveSubMenus()
    missionCommands.removeItem( self.MenuPath )
    if self.ParentMenu then
      self.ParentMenu.Menus[self.MenuPath] = nil
    end
  
    return nil
  end

end

do -- MENU_MISSION_COMMAND
  
  --- The MENU_MISSION_COMMAND class
  -- @type MENU_MISSION_COMMAND
  -- @extends Menu#MENU_COMMAND_BASE
  MENU_MISSION_COMMAND = {
    ClassName = "MENU_MISSION_COMMAND"
  }
  
  --- MENU_MISSION constructor. Creates a new radio command item for a complete mission file, which can invoke a function with parameters.
  -- @param #MENU_MISSION_COMMAND self
  -- @param #string MenuText The text for the menu.
  -- @param Menu#MENU_MISSION ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @param CommandMenuArgument An argument for the function. There can only be ONE argument given. So multiple arguments must be wrapped into a table. See the below example how to do this.
  -- @return #MENU_MISSION_COMMAND self
  function MENU_MISSION_COMMAND:New( MenuText, ParentMenu, CommandMenuFunction, ... )
  
    local self = BASE:Inherit( self, MENU_COMMAND_BASE:New( MenuText, ParentMenu, CommandMenuFunction, arg ) )
    
    self.MenuText = MenuText
    self.ParentMenu = ParentMenu
  
    self:T( { MenuText, CommandMenuFunction, arg } )
    
  
    self.MenuPath = missionCommands.addCommand( MenuText, self.MenuParentPath, self.MenuCallHandler, arg )
   
    ParentMenu.Menus[self.MenuPath] = self
    
    return self
  end
  
  --- Removes a radio command item for a coalition
  -- @param #MENU_MISSION_COMMAND self
  -- @return #nil
  function MENU_MISSION_COMMAND:Remove()
    self:F( self.MenuPath )
  
    missionCommands.removeItem( self.MenuPath )
    if self.ParentMenu then
      self.ParentMenu.Menus[self.MenuPath] = nil
    end
    return nil
  end

end



do -- MENU_COALITION

  --- The MENU_COALITION class
  -- @type MENU_COALITION
  -- @extends Menu#MENU_BASE
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
  MENU_COALITION = {
    ClassName = "MENU_COALITION"
  }
  
  --- MENU_COALITION constructor. Creates a new MENU_COALITION object and creates the menu for a complete coalition.
  -- @param #MENU_COALITION self
  -- @param DCSCoalition#coalition.side Coalition The coalition owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param #table ParentMenu The parent menu. This parameter can be ignored if you want the menu to be located at the perent menu of DCS world (under F10 other).
  -- @return #MENU_COALITION self
  function MENU_COALITION:New( Coalition, MenuText, ParentMenu )
  
    local self = BASE:Inherit( self, MENU_BASE:New( MenuText, ParentMenu ) )
    
    self:F( { Coalition, MenuText, ParentMenu } )
  
    self.Coalition = Coalition
    self.MenuText = MenuText
    self.ParentMenu = ParentMenu
    
    self.Menus = {}
  
    self:T( { MenuText } )
  
    self.MenuPath = missionCommands.addSubMenuForCoalition( Coalition, MenuText, self.MenuParentPath )
  
    self:T( { self.MenuPath } )
  
    if ParentMenu and ParentMenu.Menus then
      ParentMenu.Menus[self.MenuPath] = self
    end

    return self
  end
  
  --- Removes the sub menus recursively of this MENU_COALITION. Note that the main menu is kept!
  -- @param #MENU_COALITION self
  -- @return #MENU_COALITION self
  function MENU_COALITION:RemoveSubMenus()
    self:F( self.MenuPath )
  
    for MenuID, Menu in pairs( self.Menus ) do
      Menu:Remove()
    end
  
  end
  
  --- Removes the main menu and the sub menus recursively of this MENU_COALITION.
  -- @param #MENU_COALITION self
  -- @return #nil
  function MENU_COALITION:Remove()
    self:F( self.MenuPath )
  
    self:RemoveSubMenus()
    missionCommands.removeItemForCoalition( self.Coalition, self.MenuPath )
    if self.ParentMenu then
      self.ParentMenu.Menus[self.MenuPath] = nil
    end
  
    return nil
  end

end

do -- MENU_COALITION_COMMAND
  
  --- The MENU_COALITION_COMMAND class
  -- @type MENU_COALITION_COMMAND
  -- @extends Menu#MENU_COMMAND_BASE
  MENU_COALITION_COMMAND = {
    ClassName = "MENU_COALITION_COMMAND"
  }
  
  --- MENU_COALITION constructor. Creates a new radio command item for a coalition, which can invoke a function with parameters.
  -- @param #MENU_COALITION_COMMAND self
  -- @param DCSCoalition#coalition.side Coalition The coalition owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param Menu#MENU_COALITION ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @param CommandMenuArgument An argument for the function. There can only be ONE argument given. So multiple arguments must be wrapped into a table. See the below example how to do this.
  -- @return #MENU_COALITION_COMMAND self
  function MENU_COALITION_COMMAND:New( Coalition, MenuText, ParentMenu, CommandMenuFunction, ... )
  
    local self = BASE:Inherit( self, MENU_COMMAND_BASE:New( MenuText, ParentMenu, CommandMenuFunction, arg ) )
    
    self.MenuCoalition = Coalition
    self.MenuText = MenuText
    self.ParentMenu = ParentMenu
  
    self:T( { MenuText, CommandMenuFunction, arg } )
    
  
    self.MenuPath = missionCommands.addCommandForCoalition( self.MenuCoalition, MenuText, self.MenuParentPath, self.MenuCallHandler, arg )
   
    ParentMenu.Menus[self.MenuPath] = self
    
    return self
  end
  
  --- Removes a radio command item for a coalition
  -- @param #MENU_COALITION_COMMAND self
  -- @return #nil
  function MENU_COALITION_COMMAND:Remove()
    self:F( self.MenuPath )
  
    missionCommands.removeItemForCoalition( self.MenuCoalition, self.MenuPath )
    if self.ParentMenu then
      self.ParentMenu.Menus[self.MenuPath] = nil
    end
    return nil
  end

end

do -- MENU_CLIENT

  -- This local variable is used to cache the menus registered under clients.
  -- Menus don't dissapear when clients are destroyed and restarted.
  -- So every menu for a client created must be tracked so that program logic accidentally does not create
  -- the same menus twice during initialization logic.
  -- These menu classes are handling this logic with this variable.
  local _MENUCLIENTS = {}
  
  --- MENU_COALITION constructor. Creates a new radio command item for a coalition, which can invoke a function with parameters.
  -- @type MENU_CLIENT
  -- @extends Menu#MENU_BASE
  -- @usage
  --  -- This demo creates a menu structure for the two clients of planes.
  --  -- Each client will receive a different menu structure.
  --  -- To test, join the planes, then look at the other radio menus (Option F10).
  --  -- Then switch planes and check if the menu is still there.
  --  -- And play with the Add and Remove menu options.
  --  
  --  -- Note that in multi player, this will only work after the DCS clients bug is solved.
  --
  --  local function ShowStatus( PlaneClient, StatusText, Coalition )
  --
  --    MESSAGE:New( Coalition, 15 ):ToRed()
  --    PlaneClient:Message( StatusText, 15 )
  --  end
  --
  --  local MenuStatus = {}
  --
  --  local function RemoveStatusMenu( MenuClient )
  --    local MenuClientName = MenuClient:GetName()
  --    MenuStatus[MenuClientName]:Remove()
  --  end
  --
  --  --- @param Client#CLIENT MenuClient
  --  local function AddStatusMenu( MenuClient )
  --    local MenuClientName = MenuClient:GetName()
  --    -- This would create a menu for the red coalition under the MenuCoalitionRed menu object.
  --    MenuStatus[MenuClientName] = MENU_CLIENT:New( MenuClient, "Status for Planes" )
  --    MENU_CLIENT_COMMAND:New( MenuClient, "Show Status", MenuStatus[MenuClientName], ShowStatus, MenuClient, "Status of planes is ok!", "Message to Red Coalition" )
  --  end
  --
  --  SCHEDULER:New( nil,
  --    function()
  --      local PlaneClient = CLIENT:FindByName( "Plane 1" )
  --      if PlaneClient and PlaneClient:IsAlive() then
  --        local MenuManage = MENU_CLIENT:New( PlaneClient, "Manage Menus" )
  --        MENU_CLIENT_COMMAND:New( PlaneClient, "Add Status Menu Plane 1", MenuManage, AddStatusMenu, PlaneClient )
  --        MENU_CLIENT_COMMAND:New( PlaneClient, "Remove Status Menu Plane 1", MenuManage, RemoveStatusMenu, PlaneClient )
  --      end
  --    end, {}, 10, 10 )
  --
  --  SCHEDULER:New( nil,
  --    function()
  --      local PlaneClient = CLIENT:FindByName( "Plane 2" )
  --      if PlaneClient and PlaneClient:IsAlive() then
  --        local MenuManage = MENU_CLIENT:New( PlaneClient, "Manage Menus" )
  --        MENU_CLIENT_COMMAND:New( PlaneClient, "Add Status Menu Plane 2", MenuManage, AddStatusMenu, PlaneClient )
  --        MENU_CLIENT_COMMAND:New( PlaneClient, "Remove Status Menu Plane 2", MenuManage, RemoveStatusMenu, PlaneClient )
  --      end
  --    end, {}, 10, 10 )
  MENU_CLIENT = {
    ClassName = "MENU_CLIENT"
  }
  
  --- MENU_CLIENT constructor. Creates a new radio menu item for a client.
  -- @param #MENU_CLIENT self
  -- @param Client#CLIENT Client The Client owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param #table ParentMenu The parent menu.
  -- @return #MENU_CLIENT self
  function MENU_CLIENT:New( Client, MenuText, ParentMenu )
  
  	-- Arrange meta tables
  	local MenuParentPath = {}
  	if ParentMenu ~= nil then
  	  MenuParentPath = ParentMenu.MenuPath
  	end
  
  	local self = BASE:Inherit( self, MENU_BASE:New( MenuText, MenuParentPath ) )
  	self:F( { Client, MenuText, ParentMenu } )
  
    self.MenuClient = Client
    self.MenuClientGroupID = Client:GetClientGroupID()
    self.MenuParentPath = MenuParentPath
    self.MenuText = MenuText
    self.ParentMenu = ParentMenu
    
    self.Menus = {}
  
    if not _MENUCLIENTS[self.MenuClientGroupID] then
      _MENUCLIENTS[self.MenuClientGroupID] = {}
    end
    
    local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]
  
    self:T( { Client:GetClientGroupName(), MenuPath[table.concat(MenuParentPath)], MenuParentPath, MenuText } )
  
    local MenuPathID = table.concat(MenuParentPath) .. "/" .. MenuText
    if MenuPath[MenuPathID] then
      missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), MenuPath[MenuPathID] )
    end
  
  	self.MenuPath = missionCommands.addSubMenuForGroup( self.MenuClient:GetClientGroupID(), MenuText, MenuParentPath )
  	MenuPath[MenuPathID] = self.MenuPath
  
    self:T( { Client:GetClientGroupName(), self.MenuPath } )
  
    if ParentMenu and ParentMenu.Menus then
      ParentMenu.Menus[self.MenuPath] = self
    end
  	return self
  end
  
  --- Removes the sub menus recursively of this @{#MENU_CLIENT}.
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
  -- @return #nil
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
  -- @extends Menu#MENU_COMMAND
  MENU_CLIENT_COMMAND = {
    ClassName = "MENU_CLIENT_COMMAND"
  }
  
  --- MENU_CLIENT_COMMAND constructor. Creates a new radio command item for a client, which can invoke a function with parameters.
  -- @param #MENU_CLIENT_COMMAND self
  -- @param Client#CLIENT Client The Client owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param #MENU_BASE ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @param CommandMenuArgument An argument for the function.
  -- @return Menu#MENU_CLIENT_COMMAND self
  function MENU_CLIENT_COMMAND:New( MenuClient, MenuText, ParentMenu, CommandMenuFunction, ... )
  
  	-- Arrange meta tables
  	
  	local MenuParentPath = {}
  	if ParentMenu ~= nil then
  		MenuParentPath = ParentMenu.MenuPath
  	end
  
  	local self = BASE:Inherit( self, MENU_COMMAND_BASE:New( MenuText, MenuParentPath, CommandMenuFunction, arg ) ) -- Menu#MENU_CLIENT_COMMAND
  	
    self.MenuClient = MenuClient
    self.MenuClientGroupID = MenuClient:GetClientGroupID()
    self.MenuParentPath = MenuParentPath
    self.MenuText = MenuText
    self.ParentMenu = ParentMenu
  
    if not _MENUCLIENTS[self.MenuClientGroupID] then
      _MENUCLIENTS[self.MenuClientGroupID] = {}
    end
    
    local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]
  
    self:T( { MenuClient:GetClientGroupName(), MenuPath[table.concat(MenuParentPath)], MenuParentPath, MenuText, CommandMenuFunction, arg } )
  
    local MenuPathID = table.concat(MenuParentPath) .. "/" .. MenuText
    if MenuPath[MenuPathID] then
      missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), MenuPath[MenuPathID] )
    end
    
  	self.MenuPath = missionCommands.addCommandForGroup( self.MenuClient:GetClientGroupID(), MenuText, MenuParentPath, self.MenuCallHandler, arg )
    MenuPath[MenuPathID] = self.MenuPath
   
  	ParentMenu.Menus[self.MenuPath] = self
  	
  	return self
  end
  
  --- Removes a menu structure for a client.
  -- @param #MENU_CLIENT_COMMAND self
  -- @return #nil
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
end

--- MENU_GROUP

do
  -- This local variable is used to cache the menus registered under groups.
  -- Menus don't dissapear when groups for players are destroyed and restarted.
  -- So every menu for a client created must be tracked so that program logic accidentally does not create.
  -- the same menus twice during initialization logic.
  -- These menu classes are handling this logic with this variable.
  local _MENUGROUPS = {}

  --- The MENU_GROUP class
  -- @type MENU_GROUP
  -- @extends Menu#MENU_BASE
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
  --  --- @param Group#GROUP MenuGroup
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
  MENU_GROUP = {
    ClassName = "MENU_GROUP"
  }
  
  --- MENU_GROUP constructor. Creates a new radio menu item for a group.
  -- @param #MENU_GROUP self
  -- @param Group#GROUP MenuGroup The Group owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param #table ParentMenu The parent menu.
  -- @return #MENU_GROUP self
  function MENU_GROUP:New( MenuGroup, MenuText, ParentMenu )
  
    -- Arrange meta tables
    local MenuParentPath = {}
    if ParentMenu ~= nil then
      MenuParentPath = ParentMenu.MenuPath
    end
  
    local self = BASE:Inherit( self, MENU_BASE:New( MenuText, MenuParentPath ) )
    self:F( { MenuGroup, MenuText, ParentMenu } )
  
    self.MenuGroup = MenuGroup
    self.MenuGroupID = MenuGroup:GetID()
    self.MenuParentPath = MenuParentPath
    self.MenuText = MenuText
    self.ParentMenu = ParentMenu
    
    self.Menus = {}
  
    if not _MENUGROUPS[self.MenuGroupID] then
      _MENUGROUPS[self.MenuGroupID] = {}
    end
    
    local MenuPath = _MENUGROUPS[self.MenuGroupID]
  
    self:T( { MenuGroup:GetName(), MenuPath[table.concat(MenuParentPath)], MenuParentPath, MenuText } )
  
    local MenuPathID = table.concat(MenuParentPath) .. "/" .. MenuText
    if MenuPath[MenuPathID] then
      missionCommands.removeItemForGroup( self.MenuGroupID, MenuPath[MenuPathID] )
    end
  
    self:T( { "Adding for MenuPath ", MenuText, MenuParentPath } )
    self.MenuPath = missionCommands.addSubMenuForGroup( self.MenuGroupID, MenuText, MenuParentPath )
    MenuPath[MenuPathID] = self.MenuPath
  
    self:T( { self.MenuGroupID, self.MenuPath } )
  
    if ParentMenu and ParentMenu.Menus then
      ParentMenu.Menus[self.MenuPath] = self
    end
    return self
  end
  
  --- Removes the sub menus recursively of this MENU_GROUP.
  -- @param #MENU_GROUP self
  -- @return #MENU_GROUP self
  function MENU_GROUP:RemoveSubMenus()
    self:F( self.MenuPath )
  
    for MenuID, Menu in pairs( self.Menus ) do
      Menu:Remove()
    end
  
  end
  
  --- Removes the main menu and sub menus recursively of this MENU_GROUP.
  -- @param #MENU_GROUP self
  -- @return #nil
  function MENU_GROUP:Remove()
    self:F( self.MenuPath )
  
    self:RemoveSubMenus()
  
    if not _MENUGROUPS[self.MenuGroupID] then
      _MENUGROUPS[self.MenuGroupID] = {}
    end
    
    local MenuPath = _MENUGROUPS[self.MenuGroupID]
  
    if MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] then
      MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] = nil
    end
    
    missionCommands.removeItemForGroup( self.MenuGroupID, self.MenuPath )
    if self.ParentMenu then
      self.ParentMenu.Menus[self.MenuPath] = nil
    end
    return nil
  end
  
  
  --- The MENU_GROUP_COMMAND class
  -- @type MENU_GROUP_COMMAND
  -- @extends Menu#MENU_BASE
  MENU_GROUP_COMMAND = {
    ClassName = "MENU_GROUP_COMMAND"
  }
  
  --- Creates a new radio command item for a group
  -- @param #MENU_GROUP_COMMAND self
  -- @param Group#GROUP MenuGroup The Group owning the menu.
  -- @param MenuText The text for the menu.
  -- @param ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @param CommandMenuArgument An argument for the function.
  -- @return Menu#MENU_GROUP_COMMAND self
  function MENU_GROUP_COMMAND:New( MenuGroup, MenuText, ParentMenu, CommandMenuFunction, ... )
   
    local self = BASE:Inherit( self, MENU_COMMAND_BASE:New( MenuText, ParentMenu, CommandMenuFunction, arg ) )
    
    self.MenuGroup = MenuGroup
    self.MenuGroupID = MenuGroup:GetID()
    self.MenuText = MenuText
    self.ParentMenu = ParentMenu
  
    if not _MENUGROUPS[self.MenuGroupID] then
      _MENUGROUPS[self.MenuGroupID] = {}
    end
    
    local MenuPath = _MENUGROUPS[self.MenuGroupID]
  
    self:T( { MenuGroup:GetName(), MenuPath[table.concat(self.MenuParentPath)], self.MenuParentPath, MenuText, CommandMenuFunction, arg } )
  
    local MenuPathID = table.concat(self.MenuParentPath) .. "/" .. MenuText
    if MenuPath[MenuPathID] then
      missionCommands.removeItemForGroup( self.MenuGroupID, MenuPath[MenuPathID] )
    end
    
    self:T( { "Adding for MenuPath ", MenuText, self.MenuParentPath } )
    self.MenuPath = missionCommands.addCommandForGroup( self.MenuGroupID, MenuText, self.MenuParentPath, self.MenuCallHandler, arg )
    MenuPath[MenuPathID] = self.MenuPath
   
    ParentMenu.Menus[self.MenuPath] = self
    
    return self
  end
  
  --- Removes a menu structure for a group.
  -- @param #MENU_GROUP_COMMAND self
  -- @return #nil
  function MENU_GROUP_COMMAND:Remove()
    self:F( self.MenuPath )
  
    if not _MENUGROUPS[self.MenuGroupID] then
      _MENUGROUPS[self.MenuGroupID] = {}
    end
    
    local MenuPath = _MENUGROUPS[self.MenuGroupID]

  
    if MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] then
      MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] = nil
    end
    
    missionCommands.removeItemForGroup( self.MenuGroupID, self.MenuPath )
    self.ParentMenu.Menus[self.MenuPath] = nil
    return nil
  end

end

