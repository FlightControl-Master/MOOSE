--- **Core** -- MENU_ classes model the definition of **hierarchical menu structures** and **commands for players** within a mission.
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
--- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- ### Contributions: 
-- 
-- ====
--   
-- @module Menu


do -- MENU_BASE

  --- @type MENU_BASE
  -- @extends Base#BASE

  --- # MENU_BASE class, extends @{Base#BASE}
  -- The MENU_BASE class defines the main MENU class where other MENU classes are derived from.
  -- This is an abstract class, so don't use it.
  -- @field #MENU_BASE
  MENU_BASE = {
    ClassName = "MENU_BASE",
    MenuPath = nil,
    MenuText = "",
    MenuParentPath = nil
  }
  
  --- Consructor
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
  	self.MenuParentPath = MenuParentPath
    self.Menus = {}
    self.MenuCount = 0
    self.MenuRemoveParent = false
    self.MenuTime = timer.getTime()
  	
  	return self
  end
  
  --- Gets a @{Menu} from a parent @{Menu}
  -- @param #MENU_BASE self
  -- @param #string MenuText The text of the child menu.
  -- @return #MENU_BASE
  function MENU_BASE:GetMenu( MenuText )
    self:F2( { Menu = self.Menus[MenuText] } )
    return self.Menus[MenuText]
  end
  
  --- Sets a @{Menu} to remove automatically the parent menu when the menu removed is the last child menu of that parent @{Menu}.
  -- @param #MENU_BASE self
  -- @param #boolean RemoveParent If true, the parent menu is automatically removed when this menu is the last child menu of that parent @{Menu}.
  -- @return #MENU_BASE
  function MENU_BASE:SetRemoveParent( RemoveParent )
    self:F2( { RemoveParent } )
    self.MenuRemoveParent = RemoveParent
    return self
  end
  
  
  --- Sets a time stamp for later prevention of menu removal.
  -- @param #MENU_BASE self
  -- @param MenuTime
  -- @return #MENU_BASE
  function MENU_BASE:SetTime( MenuTime )
    self.MenuTime = MenuTime
    return self
  end
  
end

do -- MENU_COMMAND_BASE

  --- @type MENU_COMMAND_BASE
  -- @field #function MenuCallHandler
  -- @extends Core.Menu#MENU_BASE
  
  --- # MENU_COMMAND_BASE class, extends @{Base#BASE}
  -- ----------------------------------------------------------
  -- The MENU_COMMAND_BASE class defines the main MENU class where other MENU COMMAND_ 
  -- classes are derived from, in order to set commands.
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
  
  	local self = BASE:Inherit( self, MENU_BASE:New( MenuText, ParentMenu ) )
  
    self.CommandMenuFunction = CommandMenuFunction
    self.MenuCallHandler = function( CommandMenuArguments )
      self.CommandMenuFunction( unpack( CommandMenuArguments ) )
    end
  	
  	return self
  end

end


do -- MENU_MISSION

  --- @type MENU_MISSION
  -- @extends Core.Menu#MENU_BASE

  --- # MENU_MISSION class, extends @{Menu#MENU_BASE}
  -- 
  -- The MENU_MISSION class manages the main menus for a complete mission.  
  -- You can add menus with the @{#MENU_MISSION.New} method, which constructs a MENU_MISSION object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_MISSION.Remove}.
  -- @field #MENU_MISSION
  MENU_MISSION = {
    ClassName = "MENU_MISSION"
  }
  
  --- MENU_MISSION constructor. Creates a new MENU_MISSION object and creates the menu for a complete mission file.
  -- @param #MENU_MISSION self
  -- @param #string MenuText The text for the menu.
  -- @param #table ParentMenu The parent menu. This parameter can be ignored if you want the menu to be located at the perent menu of DCS world (under F10 other).
  -- @return #MENU_MISSION
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
  -- @return #MENU_MISSION
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
  
  --- @type MENU_MISSION_COMMAND
  -- @extends Core.Menu#MENU_COMMAND_BASE
  
  --- # MENU_MISSION_COMMAND class, extends @{Menu#MENU_COMMAND_BASE}
  --   
  -- The MENU_MISSION_COMMAND class manages the command menus for a complete mission, which allow players to execute functions during mission execution.  
  -- You can add menus with the @{#MENU_MISSION_COMMAND.New} method, which constructs a MENU_MISSION_COMMAND object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_MISSION_COMMAND.Remove}.
  -- 
  -- @field #MENU_MISSION_COMMAND
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

  --- @type MENU_COALITION
  -- @extends Core.Menu#MENU_BASE
  
  --- # MENU_COALITION class, extends @{Menu#MENU_BASE}
  -- 
  -- The @{Menu#MENU_COALITION} class manages the main menus for coalitions.  
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
  -- @param Dcs.DCSCoalition#coalition.side Coalition The coalition owning the menu.
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
  -- @return #MENU_COALITION
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
  
  --- @type MENU_COALITION_COMMAND
  -- @extends Core.Menu#MENU_COMMAND_BASE
  
  --- # MENU_COALITION_COMMAND class, extends @{Menu#MENU_COMMAND_BASE}
  -- 
  -- The MENU_COALITION_COMMAND class manages the command menus for coalitions, which allow players to execute functions during mission execution.  
  -- You can add menus with the @{#MENU_COALITION_COMMAND.New} method, which constructs a MENU_COALITION_COMMAND object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_COALITION_COMMAND.Remove}.
  --
  -- @field #MENU_COALITION_COMMAND
  MENU_COALITION_COMMAND = {
    ClassName = "MENU_COALITION_COMMAND"
  }
  
  --- MENU_COALITION constructor. Creates a new radio command item for a coalition, which can invoke a function with parameters.
  -- @param #MENU_COALITION_COMMAND self
  -- @param Dcs.DCSCoalition#coalition.side Coalition The coalition owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param Menu#MENU_COALITION ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @param CommandMenuArgument An argument for the function. There can only be ONE argument given. So multiple arguments must be wrapped into a table. See the below example how to do this.
  -- @return #MENU_COALITION_COMMAND
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
  -- @extends Core.Menu#MENU_BASE


  --- # MENU_CLIENT class, extends @{Menu#MENU_BASE}
  -- 
  -- The MENU_CLIENT class manages the main menus for coalitions.  
  -- You can add menus with the @{#MENU_CLIENT.New} method, which constructs a MENU_CLIENT object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_CLIENT.Remove}.
  -- 
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
  --  --- @param Wrapper.Client#CLIENT MenuClient
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
  --    
  -- @field #MENU_CLIENT
  MENU_CLIENT = {
    ClassName = "MENU_CLIENT"
  }
  
  --- MENU_CLIENT constructor. Creates a new radio menu item for a client.
  -- @param #MENU_CLIENT self
  -- @param Wrapper.Client#CLIENT Client The Client owning the menu.
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
  
  
  --- @type MENU_CLIENT_COMMAND
  -- @extends Core.Menu#MENU_COMMAND

  --- # MENU_CLIENT_COMMAND class, extends @{Menu#MENU_COMMAND_BASE}
  --
  -- The MENU_CLIENT_COMMAND class manages the command menus for coalitions, which allow players to execute functions during mission execution.  
  -- You can add menus with the @{#MENU_CLIENT_COMMAND.New} method, which constructs a MENU_CLIENT_COMMAND object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_CLIENT_COMMAND.Remove}.
  -- 
  -- @field #MENU_CLIENT_COMMAND
  MENU_CLIENT_COMMAND = {
    ClassName = "MENU_CLIENT_COMMAND"
  }
  
  --- MENU_CLIENT_COMMAND constructor. Creates a new radio command item for a client, which can invoke a function with parameters.
  -- @param #MENU_CLIENT_COMMAND self
  -- @param Wrapper.Client#CLIENT Client The Client owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param #MENU_BASE ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @return Menu#MENU_CLIENT_COMMAND self
  function MENU_CLIENT_COMMAND:New( Client, MenuText, ParentMenu, CommandMenuFunction, ... )
  
  	-- Arrange meta tables
  	
  	local MenuParentPath = {}
  	if ParentMenu ~= nil then
  		MenuParentPath = ParentMenu.MenuPath
  	end
  
  	local self = BASE:Inherit( self, MENU_COMMAND_BASE:New( MenuText, MenuParentPath, CommandMenuFunction, arg ) ) -- Menu#MENU_CLIENT_COMMAND
  	
    self.MenuClient = Client
    self.MenuClientGroupID = Client:GetClientGroupID()
    self.MenuParentPath = MenuParentPath
    self.MenuText = MenuText
    self.ParentMenu = ParentMenu
  
    if not _MENUCLIENTS[self.MenuClientGroupID] then
      _MENUCLIENTS[self.MenuClientGroupID] = {}
    end
    
    local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]
  
    self:T( { Client:GetClientGroupName(), MenuPath[table.concat(MenuParentPath)], MenuParentPath, MenuText, CommandMenuFunction, arg } )
  
    local MenuPathID = table.concat(MenuParentPath) .. "/" .. MenuText
    if MenuPath[MenuPathID] then
      missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), MenuPath[MenuPathID] )
    end
    
  	self.MenuPath = missionCommands.addCommandForGroup( self.MenuClient:GetClientGroupID(), MenuText, MenuParentPath, self.MenuCallHandler, arg )
    MenuPath[MenuPathID] = self.MenuPath
   
    if ParentMenu and ParentMenu.Menus then
    	ParentMenu.Menus[self.MenuPath] = self
    end
  	
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

  --- @type MENU_GROUP
  -- @extends Core.Menu#MENU_BASE
  
  
  --- #MENU_GROUP class, extends @{Menu#MENU_BASE}
  -- 
  -- The MENU_GROUP class manages the main menus for coalitions.  
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
  -- @param Wrapper.Group#GROUP MenuGroup The Group owning the menu.
  -- @param #string MenuText The text for the menu.
  -- @param #table ParentMenu The parent menu.
  -- @return #MENU_GROUP self
  function MENU_GROUP:New( MenuGroup, MenuText, ParentMenu )
  
    -- Determine if the menu was not already created and already visible at the group.
    -- If it is visible, then return the cached self, otherwise, create self and cache it.
    
    MenuGroup._Menus = MenuGroup._Menus or {}
    local Path = ( ParentMenu and ( table.concat( ParentMenu.MenuPath or {}, "@" ) .. "@" .. MenuText ) ) or MenuText 
    if MenuGroup._Menus[Path] then
      self = MenuGroup._Menus[Path]
    else
      self = BASE:Inherit( self, MENU_BASE:New( MenuText, ParentMenu ) )
      --if MenuGroup:IsAlive() then
        MenuGroup._Menus[Path] = self
      --end

      self.MenuGroup = MenuGroup
      self.Path = Path
      self.MenuGroupID = MenuGroup:GetID()
      self.MenuText = MenuText
      self.ParentMenu = ParentMenu

      self:T( { "Adding Menu ", MenuText, self.MenuParentPath } )
      self.MenuPath = missionCommands.addSubMenuForGroup( self.MenuGroupID, MenuText, self.MenuParentPath )

      if self.ParentMenu and self.ParentMenu.Menus then
        self.ParentMenu.Menus[MenuText] = self
        self:F( { self.ParentMenu.Menus, MenuText } )
        self.ParentMenu.MenuCount = self.ParentMenu.MenuCount + 1
      end
    end
    
    --self:F( { MenuGroup:GetName(), MenuText, ParentMenu.MenuPath } )

    return self
  end
  
  --- Removes the sub menus recursively of this MENU_GROUP.
  -- @param #MENU_GROUP self
  -- @param MenuTime
  -- @return #MENU_GROUP self
  function MENU_GROUP:RemoveSubMenus( MenuTime )
    --self:F2( { self.MenuPath, MenuTime, self.MenuTime } )
  
    --self:T( { "Removing Group SubMenus:", self.MenuGroup:GetName(), self.MenuPath } )
    for MenuText, Menu in pairs( self.Menus ) do
      Menu:Remove( MenuTime )
    end
  
  end


  --- Removes the main menu and sub menus recursively of this MENU_GROUP.
  -- @param #MENU_GROUP self
  -- @param MenuTime
  -- @return #nil
  function MENU_GROUP:Remove( MenuTime )
    --self:F2( { self.MenuGroupID, self.MenuPath, MenuTime, self.MenuTime } )
  
    self:RemoveSubMenus( MenuTime )
    
    if not MenuTime or self.MenuTime ~= MenuTime then
      if self.MenuGroup._Menus[self.Path] then
        self = self.MenuGroup._Menus[self.Path]
      
        missionCommands.removeItemForGroup( self.MenuGroupID, self.MenuPath )
        if self.ParentMenu then
          self.ParentMenu.Menus[self.MenuText] = nil
          self.ParentMenu.MenuCount = self.ParentMenu.MenuCount - 1
          if self.ParentMenu.MenuCount == 0 then
            if self.MenuRemoveParent == true then
              self:T2( "Removing Parent Menu " )
              self.ParentMenu:Remove()
            end
          end
        end
        self:T( { "Removing Group Menu:", MenuGroup = self.MenuGroup:GetName(), MenuPath = self.MenuGroup._Menus[self.Path].Path } )
        self.MenuGroup._Menus[self.Path] = nil
        self = nil
      end
    end
  
    return nil
  end
  
  
  --- @type MENU_GROUP_COMMAND
  -- @extends Core.Menu#MENU_BASE
  
  --- # MENU_GROUP_COMMAND class, extends @{Menu#MENU_COMMAND_BASE}
  -- 
  -- The @{Menu#MENU_GROUP_COMMAND} class manages the command menus for coalitions, which allow players to execute functions during mission execution.  
  -- You can add menus with the @{#MENU_GROUP_COMMAND.New} method, which constructs a MENU_GROUP_COMMAND object and returns you the object reference.
  -- Using this object reference, you can then remove ALL the menus and submenus underlying automatically with @{#MENU_GROUP_COMMAND.Remove}.
  --
  -- @field #MENU_GROUP_COMMAND
  MENU_GROUP_COMMAND = {
    ClassName = "MENU_GROUP_COMMAND"
  }
  
  --- Creates a new radio command item for a group
  -- @param #MENU_GROUP_COMMAND self
  -- @param Wrapper.Group#GROUP MenuGroup The Group owning the menu.
  -- @param MenuText The text for the menu.
  -- @param ParentMenu The parent menu.
  -- @param CommandMenuFunction A function that is called when the menu key is pressed.
  -- @param CommandMenuArgument An argument for the function.
  -- @return #MENU_GROUP_COMMAND
  function MENU_GROUP_COMMAND:New( MenuGroup, MenuText, ParentMenu, CommandMenuFunction, ... )
   
    MenuGroup._Menus = MenuGroup._Menus or {}
    local Path = ( ParentMenu and ( table.concat( ParentMenu.MenuPath or {}, "@" ) .. "@" .. MenuText ) ) or MenuText 
    if MenuGroup._Menus[Path] then
      self = MenuGroup._Menus[Path]
      self:F2( { "Re-using Group Command Menu:", MenuGroup:GetName(), MenuText } )
    else
      self = BASE:Inherit( self, MENU_COMMAND_BASE:New( MenuText, ParentMenu, CommandMenuFunction, arg ) )
      
      --if MenuGroup:IsAlive() then
        MenuGroup._Menus[Path] = self
      --end

      self.Path = Path
      self.MenuGroup = MenuGroup
      self.MenuGroupID = MenuGroup:GetID()
      self.MenuText = MenuText
      self.ParentMenu = ParentMenu

      self:F( { "Adding Group Command Menu:", MenuGroup = MenuGroup:GetName(), MenuText = MenuText, MenuPath = self.MenuParentPath } )
      self.MenuPath = missionCommands.addCommandForGroup( self.MenuGroupID, MenuText, self.MenuParentPath, self.MenuCallHandler, arg )

      if self.ParentMenu and self.ParentMenu.Menus then
        self.ParentMenu.Menus[MenuText] = self
        self.ParentMenu.MenuCount = self.ParentMenu.MenuCount + 1
        self:F2( { ParentMenu.Menus, MenuText } )
      end
    end

    return self
  end
  
  --- Removes a menu structure for a group.
  -- @param #MENU_GROUP_COMMAND self
  -- @param MenuTime
  -- @return #nil
  function MENU_GROUP_COMMAND:Remove( MenuTime )
    --self:F2( { self.MenuGroupID, self.MenuPath, MenuTime, self.MenuTime } )

    if not MenuTime or self.MenuTime ~= MenuTime then
      if self.MenuGroup._Menus[self.Path] then
        self = self.MenuGroup._Menus[self.Path]
    
        missionCommands.removeItemForGroup( self.MenuGroupID, self.MenuPath )
        self:T( { "Removing Group Command Menu:", MenuGroup = self.MenuGroup:GetName(), MenuText = self.MenuText, MenuPath = self.Path } )

        self.ParentMenu.Menus[self.MenuText] = nil
        self.ParentMenu.MenuCount = self.ParentMenu.MenuCount - 1
        if self.ParentMenu.MenuCount == 0 then
          if self.MenuRemoveParent == true then
            self:T2( "Removing Parent Menu " )
            self.ParentMenu:Remove()
          end
        end

        self.MenuGroup._Menus[self.Path] = nil
        self = nil
      end
    end
    
    return nil
  end

end

