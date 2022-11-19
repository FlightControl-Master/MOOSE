--- **Tasking** - Base class to model tasks for players to transport cargo.
-- 
-- ## Features:
-- 
--   * TASK_CARGO is the **base class** for:
--   
--     * @{Tasking.Task_Cargo_Transport#TASK_CARGO_TRANSPORT}
--     * @{Tasking.Task_CARGO_CSAR#TASK_CARGO_CSAR}
-- 
-- 
-- ===
-- 
-- ## Test Missions:
-- 
-- Test missions can be located on the main GITHUB site.
-- 
-- [FlightControl-Master/MOOSE_MISSIONS/TAD - Task Dispatching/CGO - Cargo Dispatching/](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/TAD%20-%20Task%20Dispatching/CGO%20-%20Cargo%20Dispatching)
-- 
-- ===
--
-- ## Tasking system.
-- 
-- #### If you are not yet aware what the MOOSE tasking system is about, read FIRST the explanation on the @{Tasking.Task} module.
-- 
-- ===
-- 
-- ## Context of cargo tasking.
-- 
-- The Moose framework provides various CARGO classes that allow DCS physical or logical objects to be transported or sling loaded by Carriers.
-- The CARGO_ classes, as part of the MOOSE core, are able to Board, Load, UnBoard and UnLoad cargo between Carrier units.
-- 
-- The TASK_CARGO class is not meant to use within your missions as a mission designer. It is a base class, and other classes are derived from it.
-- 
-- The following TASK_CARGO_ classes are important, as they implement the CONCRETE tasks:
-- 
--   * @{Tasking.Task_Cargo_Transport#TASK_CARGO_TRANSPORT}: Defines a task for a human player to transport a set of cargo between various zones.
--   * @{Tasking.Task_CARGO_CSAR#TASK_CARGO_CSAR}: Defines a task for a human player to Search and Rescue wounded pilots.
-- 
-- However! The menu system and basic usage of the TASK_CARGO classes is explained in the @{#TASK_CARGO} class description.
-- So please browse further below to understand how to use it from a player perspective!
-- 
-- ===
-- 
-- ## Cargo tasking from a player perspective.
-- 
-- A human player can join the battle field in a client airborne slot or a ground vehicle within the CA module (ALT-J).
-- The player needs to accept the task from the task overview list within the mission, using the menus.
-- 
-- Once the task is assigned to the player and accepted by the player, the player will obtain 
-- an extra **Cargo (Radio) Menu** that contains the CARGO objects that need to be transported.
-- 
-- Each @{Cargo.Cargo} object has a certain state:
-- 
--   * **UnLoaded**: The cargo is located within the battlefield. It may still need to be transported.
--   * **Loaded**: The cargo is loaded within a Carrier. This can be your air unit, or another air unit, or even a vehicle.
--   * **Boarding**: The cargo is running or moving towards your Carrier for loading.
--   * **UnBoarding**: The cargo is driving or jumping out of your Carrier and moves to a location in the Deployment Zone.
-- 
-- Cargo must be transported towards different Deployment @{Core.Zone}s.
-- 
-- The Cargo Menu system allows to execute **various actions** to transport the cargo.
-- In the menu, you'll find for each CARGO, that is part of the scope of the task, various actions that can be completed.
-- Depending on the location of your Carrier unit, the menu options will vary.
-- 
-- ### Joining a Cargo Transport Task
-- 
-- Once you've joined a task, using the **Join Planned Task Menu**, 
-- you can Pickup cargo from a pickup location and Deploy cargo in deployment zones, using the **Task Action Menu**.
--  
-- ### Task Action Menu.
-- 
-- When a player has joined a **`CARGO`** task (type), for that player only, 
-- it's **Task Action Menu** will show an additional menu options.
-- 
-- From within this menu, you will be able to route to a cargo location, deploy zone, and load/unload cargo.
-- 
-- ### Pickup cargo by Boarding, Loading and Sling Loading.
-- 
-- There are three different ways how cargo can be picked up:
-- 
--   - **Boarding**: Moveable cargo (like infantry or vehicles), can be boarded, that means, the cargo will move towards your carrier to board.
--     However, it can only execute the boarding actions if it is within the foreseen **Reporting Range**. 
--     Therefore, it is important that you steer your Carrier within the Reporting Range around the cargo, 
--     so that boarding actions can be executed on the cargo. The reporting range is set by the mission designer.
--     Fortunately, the cargo is reporting to you when it is within reporting range.
-- 
--   - **Loading**: Stationary cargo (like crates), which are heavy, can only be loaded or sling loaded, meaning, 
--     your carrier must be close enough to the cargo to be able to load the cargo within the carrier bays.
--     Moose provides you with an additional menu system to load stationary cargo into your carrier bays using the menu.
--     These menu options will become available, when the carrier is within loading range.
--     The Moose cargo will report to the carrier when the range is close enough. The load range is set by the mission designer.
--   
--   - **Sling Loading**: Stationary cargo (like crates), which are heavy, can only be loaded or sling loaded, meaning, 
--     your carrier must be close enough to the cargo to be able to load the cargo within the carrier bays.
--     Sling loading cargo is done using the default DCS menu system. However, Moose cargo will report to the carrier that
--     it is within sling loading range. 
--     
-- In order to be able to pickup cargo, you'll need to know where the cargo is located, right?
-- 
-- Fortunately, if your Carrier is not within the reporting range of the cargo, 
-- **the HQ can help to route you to the locations of cargo**.
-- 
-- ![Task_Types](../Tasking/Task_Cargo_Main_Menu.JPG)
-- 
-- Use the task action menu to receive HQ help for this.
-- 
-- ![Task_Types](../Tasking/Task_Cargo_Action_Menu.JPG)
--  
-- Depending on the location within the battlefield, the task action menu will contain **Route options** that can be selected
-- to start the HQ sending you routing messages.
-- The **route options will vary**, depending on the position of your carrier, and the location of the cargo and the deploy zones.
-- Note that the route options will **only be created** for cargo that is **in scope of your cargo transportation task**,
-- so there may be other cargo objects within the DCS simulation, but if those belong to other cargo transportations tasks,
-- then no routing options will be shown for these cargo.
-- This is done to ensure that **different teams** have a **defined scope** for defined cargo, and that **multiple teams** can join
-- **multiple tasks**, transporting cargo **simultaneously** in a **cooperation**.
-- 
-- In this example, there is a menu option to **Route to pickup cargo...**.
-- Use this menu to route towards cargo locations for pickup into your carrier.
-- 
-- ![Task_Types](../Tasking/Task_Cargo_Types_Menu.JPG)
-- 
-- When you select this menu, you'll see a new menu listing the different cargo types that are out there in the dcs simulator.
-- These cargo types are symbolic names that are assigned by the mission designer, like oil, liquid, engineers, food, workers etc.
-- MOOSE has introduced this concept to allow mission designers to make different cargo types for different purposes.
-- Only the creativity of the mission designer limits now the things that can be done with cargo ...
-- Okay, let's continue ..., and let's select Oil ...
-- 
-- When selected, the HQ will send you routing messages.
-- 
-- ![Task_Types](../Tasking/Task_Cargo_Routing_BR.JPG)  
-- 
-- An example of routing in BR mode.
-- 
-- Note that the coordinate display format in the message can be switched between LL DMS, LL DDM, MGRS and BR.
-- 
-- ![Task_Types](../Tasking/Main_Settings.JPG)
--   
-- Use the @{Core.Settings} menu to change your display format preferences. 
-- 
-- ![Task_Types](../Tasking/Settings_A2G_Coordinate.JPG)
-- 
-- There you can change the display format to another format that suits your need.
-- Because cargo transportation is Air 2 Ground oriented, you need to select the A2G coordinate format display options.
-- Note that the main settings menu contains much more
-- options to control your display formats, like switch to metric and imperial, or change the duration of the display messages.
-- 
-- ![Task_Types](../Tasking/Task_Cargo_Routing_LL.JPG)  
-- 
-- Here I changed the routing display format to LL DMS.
-- 
-- One important thing to know, is that the routing messages will flash at regular time intervals.
-- When using BR coordinate display format, the **distance and angle will change accordingly** from your carrier position and the location of the cargo.
-- 
-- Another important note is the routing towards deploy zones.
-- These routing options will only be shown, when your carrier bays have cargo loaded.
-- So, only when there is something to be deployed from your carrier, the deploy options will be shown.
--     
-- #### Pickup Cargo.
-- 
-- In order to pickup cargo, use the **task action menu** to **route to a specific cargo**.
-- When a cargo route is selected, the HQ will send you routing messages indicating the location of the cargo.
--  
-- Upon arrival at the cargo, and when the cargo is within **reporting range**, the cargo will contact you and **further instructions will be given**.
-- 
--   - When your Carrier is airborne, you will receive instructions to land your Carrier.
--     The action will not be completed until you've landed your Carrier.
--     
--   - For ground carriers, you can just drive to the optimal cargo board or load position.
-- 
-- It takes a bit of skill to land a helicopter near a cargo to be loaded, but that is part of the game, isn't it?
-- Expecially when you are landing in a "hot" zone, so when cargo is under immediate threat of fire.
-- 
-- #### Board Cargo (infantry).
-- 
-- ![](../Tasking/Boarding_Ready.png)  
-- 
-- If your Carrier is within the **Reporting Range of the cargo**, and the cargo is **moveable**, the **cargo can be boarded**!
-- This type of cargo will be most of the time be infantry.
-- 
-- ![](../Tasking/Boarding_Menu.png)  
-- 
-- A **Board cargo...** sub menu has appeared, because your carrier is in boarding range of the cargo (infantry).
-- Select the **Board cargo...** menu.
-- 
-- ![](../Tasking/Boarding_Menu_Engineers.png)  
-- 
-- Any cargo that can be boarded (thus movable cargo), within boarding range of the carrier, will be listed here!
-- In this example, the cargo **Engineers** can be boarded, by selecting the menu option.
-- 
-- ![](../Tasking/Boarding_Started.png)  
-- 
-- After the menu option to board the cargo has been selected, the boarding process is started.
-- A message from the cargo is communicated to the pilot, that boarding is started.
-- 
-- ![](../Tasking/Boarding_Ongoing.png)  
-- 
-- **The pilot must wait at the exact position until all cargo has been boarded!**  
-- 
-- The moveable cargo will run in formation to your carrier, and will board one by one, depending on the near range set by the mission designer.
-- The near range as added because carriers can be large or small, depending on the object size of the carrier.
-- 
-- ![](../Tasking/Boarding_In_Progress.png)  
-- 
-- ![](../Tasking/Boarding_Almost_Done.png)  
-- 
-- Note that multiple units may need to board your Carrier, so it is required to await the full boarding process.
-- 
-- ![](../Tasking/Boarding_Done.png)  
-- 
-- Once the cargo is fully boarded within your Carrier, you will be notified of this.
-- 
-- **Remarks:**
-- 
--   * For airborne Carriers, it is required to land first before the Boarding process can be initiated.
--     If during boarding the Carrier gets airborne, the boarding process will be cancelled.
--   * The carrier must remain stationary when the boarding sequence has started until further notified.
-- 
-- #### Load Cargo.
-- 
-- Cargo can be loaded into vehicles or helicopters or airplanes, as long as the carrier is sufficiently near to the cargo object.
-- 
-- ![](../Tasking/Loading_Ready.png)  
-- 
-- If your Carrier is within the **Loading Range of the cargo**, thus, sufficiently near to the cargo, and the cargo is **stationary**, the **cargo can be loaded**, but not boarded!
-- 
-- ![](../Tasking/Loading_Menu.png)  
-- 
-- Select the task action menu and now a **Load cargo...** sub menu will be listed.
-- Select the **Load cargo...** sub menu, and a further detailed menu will be shown.
-- 
-- ![](../Tasking/Loading_Menu_Crate.png)  
-- 
-- For each non-moveable cargo object (crates etc), **within loading range of the carrier**, the cargo will be listed and can be loaded into the carrier!
-- 
-- ![](../Tasking/Loading_Cargo_Loaded.png)  
-- 
-- Once the cargo is loaded within your Carrier, you will be notified of this.
-- 
-- **Remarks:**
--  
--   * For airborne Carriers, it is required to **land first right near the cargo**, before the loading process can be initiated.
-- As stated, this requires some pilot skills :-)
-- 
-- #### Sling Load Cargo (helicopters only).
-- 
-- If your Carrier is within the **Loading Range of the cargo**, and the cargo is **stationary**, the **cargo can also be sling loaded**!
-- Note that this is only possible for helicopters.
-- 
-- To sling load cargo, there is no task action menu required. Just follow the normal sling loading procedure and the cargo will report.
-- Use the normal DCS sling loading menu system to hook the cargo you the cable attached on your helicopter.
-- 
-- Again note that you may land firstly right next to the cargo, before the loading process can be initiated.
-- As stated, this requires some pilot skills :-)
-- 
-- 
-- ### Deploy cargo by Unboarding, Unloading and Sling Deploying.
-- 
-- #### **Deploying the relevant cargo within deploy zones, will make you achieve cargo transportation tasks!!!**
-- 
-- There are two different ways how cargo can be deployed:
-- 
--   - **Unboarding**: Moveable cargo (like infantry or vehicles), can be unboarded, that means, 
--     the cargo will step out of the carrier and will run to a group location.
--     Moose provides you with an additional menu system to unload stationary cargo from the carrier bays,
--     using the menu. These menu options will become available, when the carrier is within the deploy zone.
-- 
--   - **Unloading**: Stationary cargo (like crates), which are heavy, can only be unloaded or sling loaded. 
--     Moose provides you with an additional menu system to unload stationary cargo from the carrier bays,
--     using the menu. These menu options will become available, when the carrier is within the deploy zone.
--   
--   - **Sling Deploying**: Stationary cargo (like crates), which are heavy, can also be sling deployed. 
--     Once the cargo is within the deploy zone, the cargo can be deployed from the sling onto the ground.
--     
-- In order to be able to deploy cargo, you'll need to know where the deploy zone is located, right?
-- Fortunately, the HQ can help to route you to the locations of deploy zone.
-- Use the task action menu to receive HQ help for this.
-- 
-- ![](../Tasking/Routing_Deploy_Zone_Menu.png)
--  
-- Depending on the location within the battlefield, the task action menu will contain **Route options** that can be selected
-- to start the HQ sending you routing messages. Also, if the carrier cargo bays contain cargo, 
-- then beside **Route options** there will also be **Deploy options** listed.
-- These **Deploy options** are meant to route you to the deploy zone locations.
-- 
-- ![](../Tasking/Routing_Deploy_Zone_Menu_Workplace.png)
-- 
-- Depending on the task that you have selected, the deploy zones will be listed.
-- **There may be multiple deploy zones within the mission, but only the deploy zones relevant for your task will be available in the menu!**
--  
-- ![](../Tasking/Routing_Deploy_Zone_Message.png)
-- 
-- When a routing option is selected, you are sent routing messages in a selected coordinate format.
-- Possible routing coordinate formats are: Bearing Range (BR), Lattitude Longitude (LL) or Military Grid System (MGRS).
-- Note that for LL, there are two sub formats. (See pickup).
-- 
-- ![](../Tasking/Routing_Deploy_Zone_Arrived.png)
-- 
-- When you are within the range of the deploy zone (can be also a polygon!), a message is communicated by HQ that you have arrived within the zone!
-- 
-- The routing messages are formulated in the coordinate format that is currently active as configured in your settings profile.  
-- ![Task_Types](../Tasking/Task_Cargo_Settings.JPG)  
-- Use the **Settings Menu** to select the coordinate format that you would like to use for location determination.
-- 
-- #### Unboard Cargo.
-- 
-- If your carrier contains cargo, and the cargo is **moveable**, the **cargo can be unboarded**!
-- You can only unload cargo if there is cargo within your cargo bays within the carrier.
-- 
-- ![](../Tasking/Unboarding_Menu.png)
-- 
-- Select the task action menu and now an **Unboard cargo...** sub menu will be listed!
-- Again, this option will only be listed if there is a non moveable cargo within your cargo bays.
-- 
-- ![](../Tasking/Unboarding_Menu_Engineers.png)
-- 
-- Now you will see a menu option to unload the non-moveable cargo.
-- In this example, you can unload the **Engineers** that was loaded within your carrier cargo bays.
-- Depending on the cargo loaded within your cargo bays, you will see other options here!
-- Select the relevant menu option from the cargo unload menu, and the cargo will unloaded from your carrier.
-- 
-- ![](../Tasking/Unboarding_Started.png)
-- 
-- **The cargo will step out of your carrier and will move towards a grouping point.**
-- When the unboarding process has started, you will be notified by a message to your carrier.
-- 
-- ![](../Tasking/Unboarding_In_Progress.png)
-- 
-- The moveable cargo will unboard one by one, so note that multiple units may need to unboard your Carrier, 
-- so it is required to await the full completion of the unboarding process.
-- 
-- ![](../Tasking/Unboarding_Done.png)
-- 
-- Once the cargo is fully unboarded from your carrier, you will be notified of this.
--
-- **Remarks:**
-- 
--   * For airborne carriers, it is required to land first before the unboarding process can be initiated.
--     If during unboarding the Carrier gets airborne, the unboarding process will be cancelled.
--   * Once the moveable cargo is unboarded, they will start moving towards a specified gathering point.
--   * The moveable cargo will send a message to your carrier with unboarding status updates.
-- 
-- **Deploying a cargo within a deployment zone, may complete a deployment task! So ensure that you deploy the right cargo at the right deployment zone!**
-- 
-- #### Unload Cargo.
-- 
-- If your carrier contains cargo, and the cargo is **stationary**, the **cargo can be unloaded**, but not unboarded!
-- You can only unload cargo if there is cargo within your cargo bays within the carrier.
-- 
-- ![](../Tasking/Unloading_Menu.png)
-- 
-- Select the task action menu and now an **Unload cargo...** sub menu will be listed! 
-- Again, this option will only be listed if there is a non moveable cargo within your cargo bays.
-- 
-- ![](../Tasking/Unloading_Menu_Crate.png)
-- 
-- Now you will see a menu option to unload the non-moveable cargo.
-- In this example, you can unload the **Crate** that was loaded within your carrier cargo bays.
-- Depending on the cargo loaded within your cargo bays, you will see other options here!
-- Select the relevant menu option from the cargo unload menu, and the cargo will unloaded from your carrier.
-- 
-- ![](../Tasking/Unloading_Done.png)
-- 
-- Once the cargo is unloaded fom your Carrier, you may be notified of this, when there is a truck near to the cargo.
-- If there is no truck near to the unload area, no message will be sent to your carrier!
-- 
-- **Remarks:**
-- 
--   * For airborne Carriers, it is required to land first, before the unloading process can be initiated.
--   * A truck must be near the unload area to get messages to your carrier of the unload event!
--   * Unloading is only for non-moveable cargo.
--   * The non-moveable cargo must be within your cargo bays, or no unload option will be available.
--   
-- **Deploying a cargo within a deployment zone, may complete a deployment task! So ensure that you deploy the right cargo at the right deployment zone!**
-- 
-- 
-- #### Sling Deploy Cargo (helicopters only).
-- 
-- If your Carrier is within the **deploy zone**, and the cargo is **stationary**, the **cargo can also be sling deploying**!
-- Note that this is only possible for helicopters.
-- 
-- To sling deploy cargo, there is no task action menu required. Just follow the normal sling deploying procedure.
-- 
-- **Deploying a cargo within a deployment zone, may complete a deployment task! So ensure that you deploy the right cargo at the right deployment zone!**
-- 
-- ## Cargo tasking from a mission designer perspective.
-- 
-- Please consult the documentation how to implement the derived classes of SET_CARGO in:
-- 
--   - @{Tasking.Task_CARGO#TASK_CARGO}: Documents the main methods how to handle the cargo tasking from a mission designer perspective.
--   - @{Tasking.Task_CARGO#TASK_CARGO_TRANSPORT}: Documents the specific methods how to handle the cargo transportation tasking from a mission designer perspective.
--   - @{Tasking.Task_CARGO#TASK_CARGO_CSAR}: Documents the specific methods how to handle the cargo CSAR tasking from a mission designer perspective.
--   
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
--   
-- @module Tasking.Task_CARGO
-- @image MOOSE.JPG

do -- TASK_CARGO

  --- @type TASK_CARGO
  -- @extends Tasking.Task#TASK

  --- Model tasks for players to transport Cargo.
  -- 
  -- This models the process of a flexible transporation tasking system of cargo.
  -- 
  -- # 1) A flexible tasking system.
  -- 
  -- The TASK_CARGO classes provide you with a flexible tasking sytem, 
  -- that allows you to transport cargo of various types between various locations
  -- and various dedicated deployment zones.
  -- 
  -- The cargo in scope of the TASK\_CARGO classes must be explicitly given, and is of type SET\_CARGO.
  -- The SET_CARGO contains a collection of CARGO objects that must be handled by the players in the mission.
  -- 
  -- # 2) Cargo Tasking from a mission designer perspective.
  -- 
  -- A cargo task is governed by a @{Tasking.Mission} object. Tasks are of different types.
  -- The @{#TASK} object is used or derived by more detailed tasking classes that will implement the task execution mechanisms
  -- and goals. 
  -- 
  -- ## 2.1) Derived cargo task classes.
  -- 
  -- The following TASK_CARGO classes are derived from @{#TASK}.
  -- 
  --      TASK
  --        TASK_CARGO
  --          TASK_CARGO_TRANSPORT
  --          TASK_CARGO_CSAR
  -- 
  -- ### 2.1.1) Cargo Tasks  
  -- 
  --   - @{Tasking.Task_CARGO#TASK_CARGO_TRANSPORT} - Models the transportation of cargo to deployment zones. 
  --   - @{Tasking.Task_CARGO#TASK_CARGO_CSAR} - Models the rescue of downed friendly pilots from behind enemy lines.    
  --   
  -- ## 2.2) Handle TASK_CARGO Events ...
  -- 
  -- The TASK_CARGO classes define @{Cargo} transport tasks, 
  -- based on the tasking capabilities defined in @{Tasking.Task#TASK}.
  -- 
  -- ### 2.2.1) Boarding events.
  -- 
  -- Specific Cargo event can be captured, that allow to trigger specific actions!
  -- 
  --   * **Boarded**: Triggered when the Cargo has been Boarded into your Carrier.
  --   * **UnBoarded**: Triggered when the cargo has been Unboarded from your Carrier and has arrived at the Deployment Zone.
  -- 
  -- ### 2.2.2) Loading events.
  -- 
  -- Specific Cargo event can be captured, that allow to trigger specific actions!
  -- 
  --   * **Loaded**: Triggered when the Cargo has been Loaded into your Carrier.
  --   * **UnLoaded**: Triggered when the cargo has been Unloaded from your Carrier and has arrived at the Deployment Zone.
  -- 
  -- ### 2.2.2) Standard TASK_CARGO Events
  -- 
  -- The TASK_CARGO is implemented using a @{Core.Fsm#FSM_TASK}, and has the following standard statuses:
  -- 
  --   * **None**: Start of the process.
  --   * **Planned**: The cargo task is planned.
  --   * **Assigned**: The cargo task is assigned to a @{Wrapper.Group#GROUP}.
  --   * **Success**: The cargo task is successfully completed.
  --   * **Failed**: The cargo task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
  -- 
  -- 
  -- 
  -- ===
  -- 
  -- @field #TASK_CARGO
  TASK_CARGO = {
    ClassName = "TASK_CARGO",
  }
  
  --- Instantiates a new TASK_CARGO.
  -- @param #TASK_CARGO self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_CARGO SetCargo The scope of the cargo to be transported.
  -- @param #string TaskType The type of Cargo task.
  -- @param #string TaskBriefing The Cargo Task briefing.
  -- @return #TASK_CARGO self
  function TASK_CARGO:New( Mission, SetGroup, TaskName, SetCargo, TaskType, TaskBriefing )
    local self = BASE:Inherit( self, TASK:New( Mission, SetGroup, TaskName, TaskType, TaskBriefing ) ) -- #TASK_CARGO
    self:F( {Mission, SetGroup, TaskName, SetCargo, TaskType})
  
    self.SetCargo = SetCargo
    self.TaskType = TaskType
    self.SmokeColor = SMOKECOLOR.Red
    
    self.CargoItemCount = {} -- Map of Carriers having a cargo item count to check the cargo loading limits.
    self.CargoLimit = 10
    
    self.DeployZones = {} -- setmetatable( {}, { __mode = "v" } ) -- weak table on value

    self:AddTransition( "*", "CargoDeployed", "*" )
    
    --- CargoDeployed Handler OnBefore for TASK_CARGO
    -- @function [parent=#TASK_CARGO] OnBeforeCargoDeployed
    -- @param #TASK_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that Deployed the cargo. You can use this to retrieve the PlayerName etc.
    -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
    -- @param Core.Zone#ZONE DeployZone The zone where the Cargo got Deployed or UnBoarded.
    -- @return #boolean
    
    --- CargoDeployed Handler OnAfter for TASK_CARGO
    -- @function [parent=#TASK_CARGO] OnAfterCargoDeployed
    -- @param #TASK_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that Deployed the cargo. You can use this to retrieve the PlayerName etc.
    -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
    -- @param Core.Zone#ZONE DeployZone The zone where the Cargo got Deployed or UnBoarded.
    -- @usage
    -- 
    --   -- Add a Transport task to transport cargo of different types to a Transport Deployment Zone.
    --  TaskDispatcher = TASK_CARGO_DISPATCHER:New( Mission, TransportGroups )
    --  
    --  local CargoSetWorkmaterials = SET_CARGO:New():FilterTypes( "Workmaterials" ):FilterStart()
    --  local EngineerCargoGroup = CARGO_GROUP:New( GROUP:FindByName( "Engineers" ), "Workmaterials", "Engineers", 250 )
    --  local ConcreteCargo = CARGO_SLINGLOAD:New( STATIC:FindByName( "Concrete" ), "Workmaterials", "Concrete", 150, 50 )
    --  local CrateCargo = CARGO_CRATE:New( STATIC:FindByName( "Crate" ), "Workmaterials", "Crate", 150, 50 )
    --  local EnginesCargo = CARGO_CRATE:New( STATIC:FindByName( "Engines" ), "Workmaterials", "Engines", 150, 50 )
    --  local MetalCargo = CARGO_CRATE:New( STATIC:FindByName( "Metal" ), "Workmaterials", "Metal", 150, 50 )
    --  
    --  -- Here we add the task. We name the task "Build a Workplace".
    --  -- We provide the CargoSetWorkmaterials, and a briefing as the 2nd and 3rd parameter.
    --  -- The :AddTransportTask() returns a Tasking.Task_Cargo_Transport#TASK_CARGO_TRANSPORT object, which we keep as a reference for further actions.
    --  -- The WorkplaceTask holds the created and returned Tasking.Task_Cargo_Transport#TASK_CARGO_TRANSPORT object.
    --  local WorkplaceTask = TaskDispatcher:AddTransportTask( "Build a Workplace", CargoSetWorkmaterials, "Transport the workers, engineers and the equipment near the Workplace." )
    --  
    --  -- Here we set a TransportDeployZone. We use the WorkplaceTask as the reference, and provide a ZONE object.
    --  TaskDispatcher:SetTransportDeployZone( WorkplaceTask, ZONE:New( "Workplace" ) )
    --  
    --  Helos = { SPAWN:New( "Helicopters 1" ), SPAWN:New( "Helicopters 2" ), SPAWN:New( "Helicopters 3" ), SPAWN:New( "Helicopters 4" ), SPAWN:New( "Helicopters 5" ) }
    --  EnemyHelos = { SPAWN:New( "Enemy Helicopters 1" ), SPAWN:New( "Enemy Helicopters 2" ), SPAWN:New( "Enemy Helicopters 3" ) }
    --  
    --  -- This is our worker method! So when a cargo is deployed within a deployment zone, this method will be called.
    --  -- By example we are spawning here a random friendly helicopter and a random enemy helicopter.
    --  function WorkplaceTask:OnAfterCargoDeployed( From, Event, To, TaskUnit, Cargo, DeployZone )
    --    Helos[ math.random(1,#Helos) ]:Spawn()
    --    EnemyHelos[ math.random(1,#EnemyHelos) ]:Spawn()
    --  end
    
    self:AddTransition( "*", "CargoPickedUp", "*" )

    --- CargoPickedUp Handler OnBefore for TASK_CARGO
    -- @function [parent=#TASK_CARGO] OnBeforeCargoPickedUp
    -- @param #TASK_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that PickedUp the cargo. You can use this to retrieve the PlayerName etc.
    -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
    -- @return #boolean
    
    --- CargoPickedUp Handler OnAfter for TASK_CARGO
    -- @function [parent=#TASK_CARGO] OnAfterCargoPickedUp
    -- @param #TASK_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that PickedUp the cargo. You can use this to retrieve the PlayerName etc.
    -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.

    
    local Fsm = self:GetUnitProcess()
    
--    Fsm:SetStartState( "Planned" )
--
--    Fsm:AddProcess   ( "Planned", "Accept", ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "SelectAction", Rejected = "Reject" }  )
    
    Fsm:AddTransition( { "Planned", "Assigned", "Cancelled", "WaitingForCommand", "ArrivedAtPickup", "ArrivedAtDeploy", "Boarded", "UnBoarded", "Loaded", "UnLoaded", "Landed", "Boarding" }, "SelectAction", "*" )

    Fsm:AddTransition( "*", "RouteToPickup", "RoutingToPickup" )
    Fsm:AddProcess   ( "RoutingToPickup", "RouteToPickupPoint", ACT_ROUTE_POINT:New(), { Arrived = "ArriveAtPickup", Cancelled = "CancelRouteToPickup" } )
    Fsm:AddTransition( "Arrived", "ArriveAtPickup", "ArrivedAtPickup" )
    Fsm:AddTransition( "Cancelled", "CancelRouteToPickup", "Cancelled" )

    Fsm:AddTransition( "*", "RouteToDeploy", "RoutingToDeploy" )
    Fsm:AddProcess   ( "RoutingToDeploy", "RouteToDeployZone", ACT_ROUTE_ZONE:New(), { Arrived = "ArriveAtDeploy", Cancelled = "CancelRouteToDeploy" } )
    Fsm:AddTransition( "Arrived", "ArriveAtDeploy", "ArrivedAtDeploy" )
    Fsm:AddTransition( "Cancelled", "CancelRouteToDeploy", "Cancelled" )
    
    Fsm:AddTransition( { "ArrivedAtPickup", "ArrivedAtDeploy", "Landing" }, "Land", "Landing" )
    Fsm:AddTransition( "Landing", "Landed", "Landed" )
    
    Fsm:AddTransition( "*", "PrepareBoarding", "AwaitBoarding" )
    Fsm:AddTransition( "AwaitBoarding", "Board", "Boarding" )
    Fsm:AddTransition( "Boarding", "Boarded", "Boarded" )
    
    Fsm:AddTransition( "*", "Load", "Loaded" )

    Fsm:AddTransition( "*", "PrepareUnBoarding", "AwaitUnBoarding" )
    Fsm:AddTransition( "AwaitUnBoarding", "UnBoard", "UnBoarding" )
    Fsm:AddTransition( "UnBoarding", "UnBoarded", "UnBoarded" )

    Fsm:AddTransition( "*", "Unload", "Unloaded" )
    
    Fsm:AddTransition( "*", "Planned", "Planned" )
    
    
    Fsm:AddTransition( "Deployed", "Success", "Success" )
    Fsm:AddTransition( "Rejected", "Reject", "Aborted" )
    Fsm:AddTransition( "Failed", "Fail", "Failed" )

    ---- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param #TASK_CARGO Task
    function Fsm:OnAfterAssigned( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      self:SelectAction()
    end
    
    

    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param #TASK_CARGO Task
    function Fsm:onafterSelectAction( TaskUnit, Task )
      
      local TaskUnitName = TaskUnit:GetName()
      local MenuTime = Task:InitTaskControlMenu( TaskUnit )
      local MenuControl = Task:GetTaskControlMenu( TaskUnit )
      
      Task.SetCargo:ForEachCargo(
        
        --- @param Cargo.Cargo#CARGO Cargo
        function( Cargo ) 
        
          if Cargo:IsAlive() then
        
--            if Task:is( "RoutingToPickup" ) then
--              MENU_GROUP_COMMAND:New(
--                TaskUnit:GetGroup(),
--                "Cancel Route " .. Cargo.Name,
--                MenuControl,
--                self.MenuRouteToPickupCancel,
--                self,
--                Cargo
--              ):SetTime(MenuTime)
--            end

            --self:F( { CargoUnloaded = Cargo:IsUnLoaded(), CargoLoaded = Cargo:IsLoaded(), CargoItemCount = CargoItemCount } )
        
            local TaskGroup = TaskUnit:GetGroup()
            
            if Cargo:IsUnLoaded() then
              local CargoBayFreeWeight = TaskUnit:GetCargoBayFreeWeight()
              local CargoWeight = Cargo:GetWeight()
              
              self:F({CargoBayFreeWeight=CargoBayFreeWeight})
  
              -- Only when there is space within the bay to load the next cargo item!
              if CargoBayFreeWeight > CargoWeight then 
                if Cargo:IsInReportRadius( TaskUnit:GetPointVec2() ) then
                  local NotInDeployZones = true
                  for DeployZoneName, DeployZone in pairs( Task.DeployZones ) do
                    if Cargo:IsInZone( DeployZone ) then
                      NotInDeployZones = false
                    end
                  end
                  if NotInDeployZones then
                    if not TaskUnit:InAir() then
                      if Cargo:CanBoard() == true then
                        if Cargo:IsInLoadRadius( TaskUnit:GetPointVec2() ) then
                          Cargo:Report( "Ready for boarding.", "board", TaskUnit:GetGroup() )
                          local BoardMenu = MENU_GROUP:New( TaskGroup, "Board cargo", MenuControl ):SetTime( MenuTime ):SetTag( "Cargo" )
                          MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), Cargo.Name, BoardMenu, self.MenuBoardCargo, self, Cargo ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
                        else
                          Cargo:Report( "Board at " .. Cargo:GetCoordinate():ToString( TaskUnit:GetGroup() .. "." ), "reporting", TaskUnit:GetGroup() )
                        end
                      else
                        if Cargo:CanLoad() == true then
                          if Cargo:IsInLoadRadius( TaskUnit:GetPointVec2() ) then
                            Cargo:Report( "Ready for loading.", "load", TaskUnit:GetGroup() )
                            local LoadMenu = MENU_GROUP:New( TaskGroup, "Load cargo", MenuControl ):SetTime( MenuTime ):SetTag( "Cargo" )
                            MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), Cargo.Name, LoadMenu, self.MenuLoadCargo, self, Cargo ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
                          else
                            Cargo:Report( "Load at " .. Cargo:GetCoordinate():ToString( TaskUnit:GetGroup() ) .. " within " .. Cargo.NearRadius .. ".", "reporting", TaskUnit:GetGroup() )
                          end
                        else
                          --local Cargo = Cargo -- Cargo.CargoSlingload#CARGO_SLINGLOAD
                          if Cargo:CanSlingload() == true then
                            if Cargo:IsInLoadRadius( TaskUnit:GetPointVec2() ) then
                              Cargo:Report( "Ready for sling loading.", "slingload", TaskUnit:GetGroup() )
                              local SlingloadMenu = MENU_GROUP:New( TaskGroup, "Slingload cargo", MenuControl ):SetTime( MenuTime ):SetTag( "Cargo" )
                              MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), Cargo.Name, SlingloadMenu, self.MenuLoadCargo, self, Cargo ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
                            else
                              Cargo:Report( "Slingload at " .. Cargo:GetCoordinate():ToString( TaskUnit:GetGroup() ) .. ".", "reporting", TaskUnit:GetGroup() )
                            end
                          end
                        end
                      end
                    else
                      Cargo:ReportResetAll( TaskUnit:GetGroup() )
                    end
                  end
                else
                  if not Cargo:IsDeployed() == true then
                    local RouteToPickupMenu = MENU_GROUP:New( TaskGroup, "Route to pickup cargo", MenuControl ):SetTime( MenuTime ):SetTag( "Cargo" )
                    --MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), Cargo.Name, RouteToPickupMenu, self.MenuRouteToPickup, self, Cargo ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
                    Cargo:ReportResetAll( TaskUnit:GetGroup() )
                    if Cargo:CanBoard() == true then
                      if not Cargo:IsInLoadRadius( TaskUnit:GetPointVec2() ) then
                        local BoardMenu = MENU_GROUP:New( TaskGroup, "Board cargo", RouteToPickupMenu ):SetTime( MenuTime ):SetTag( "Cargo" )
                        MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), Cargo.Name, BoardMenu, self.MenuRouteToPickup, self, Cargo ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
                      end
                    else
                      if Cargo:CanLoad() == true then
                        if not Cargo:IsInLoadRadius( TaskUnit:GetPointVec2() ) then
                          local LoadMenu = MENU_GROUP:New( TaskGroup, "Load cargo", RouteToPickupMenu ):SetTime( MenuTime ):SetTag( "Cargo" )
                          MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), Cargo.Name, LoadMenu, self.MenuRouteToPickup, self, Cargo ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
                        end
                      else
                        --local Cargo = Cargo -- Cargo.CargoSlingload#CARGO_SLINGLOAD
                        if Cargo:CanSlingload() == true then
                          if not Cargo:IsInLoadRadius( TaskUnit:GetPointVec2() ) then
                            local SlingloadMenu = MENU_GROUP:New( TaskGroup, "Slingload cargo", RouteToPickupMenu ):SetTime( MenuTime ):SetTag( "Cargo" )
                            MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), Cargo.Name, SlingloadMenu, self.MenuRouteToPickup, self, Cargo ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
                          end
                        end
                      end
                    end
                  end
                end
              end
              
              -- Cargo in deployzones are flagged as deployed.
              for DeployZoneName, DeployZone in pairs( Task.DeployZones ) do
                if Cargo:IsInZone( DeployZone ) then
                  Task:I( { CargoIsDeployed = Task.CargoDeployed and "true" or "false" } )
                  if Cargo:IsDeployed() == false then
                    Cargo:SetDeployed( true )
                    -- Now we call a callback method to handle the CargoDeployed event.
                    Task:I( { CargoIsAlive = Cargo:IsAlive() and "true" or "false" } )
                    if Cargo:IsAlive() then
                      Task:CargoDeployed( TaskUnit, Cargo, DeployZone )
                    end
                  end
                end
              end
              
            end
            
            if Cargo:IsLoaded() == true and Cargo:IsLoadedInCarrier( TaskUnit ) == true then
              if not TaskUnit:InAir() then
                if Cargo:CanUnboard() == true then
                  local UnboardMenu = MENU_GROUP:New( TaskGroup, "Unboard cargo", MenuControl ):SetTime( MenuTime ):SetTag( "Cargo" )
                  MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), Cargo.Name, UnboardMenu, self.MenuUnboardCargo, self, Cargo ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
                else
                  if Cargo:CanUnload() == true then
                    local UnloadMenu = MENU_GROUP:New( TaskGroup, "Unload cargo", MenuControl ):SetTime( MenuTime ):SetTag( "Cargo" )
                    MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), Cargo.Name, UnloadMenu, self.MenuUnloadCargo, self, Cargo ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
                  end
                end
              end
            end

            -- Deployzones are optional zones that can be selected to request routing information.
            for DeployZoneName, DeployZone in pairs( Task.DeployZones ) do
              if not Cargo:IsInZone( DeployZone ) then
                local RouteToDeployMenu = MENU_GROUP:New( TaskGroup, "Route to deploy cargo", MenuControl ):SetTime( MenuTime ):SetTag( "Cargo" )
                MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), "Zone " .. DeployZoneName, RouteToDeployMenu, self.MenuRouteToDeploy, self, DeployZone ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
              end
            end
          end
        
        end
      )

      Task:RefreshTaskControlMenu( TaskUnit, MenuTime, "Cargo" )
      
      self:__SelectAction( -1 )
      
    end
    
    
    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param #TASK_CARGO Task
    function Fsm:OnLeaveWaitingForCommand( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      --local MenuControl = Task:GetTaskControlMenu( TaskUnit )
      
      --MenuControl:Remove()
    end
    
    function Fsm:MenuBoardCargo( Cargo )
      self:__PrepareBoarding( 1.0, Cargo )
    end
    
    function Fsm:MenuLoadCargo( Cargo )
      self:__Load( 1.0, Cargo )
    end
    
    function Fsm:MenuUnboardCargo( Cargo, DeployZone )
      self:__PrepareUnBoarding( 1.0, Cargo, DeployZone )
    end
    
    function Fsm:MenuUnloadCargo( Cargo, DeployZone )
      self:__Unload( 1.0, Cargo, DeployZone )
    end

    function Fsm:MenuRouteToPickup( Cargo )
      self:__RouteToPickup( 1.0, Cargo )
    end

    function Fsm:MenuRouteToDeploy( DeployZone )
      self:__RouteToDeploy( 1.0, DeployZone )
    end
    
    
    
    ---
    --#TASK_CAROG_TRANSPORT self
    --#Wrapper.Unit#UNIT

    
    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    -- @param From
    -- @param Event
    -- @param To
    -- @param Core.Cargo#CARGO Cargo
    function Fsm:onafterRouteToPickup( TaskUnit, Task, From, Event, To, Cargo )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      if Cargo:IsAlive() then
        self.Cargo = Cargo -- Cargo.Cargo#CARGO
        Task:SetCargoPickup( self.Cargo, TaskUnit )
        self:__RouteToPickupPoint( -0.1 )
      end
      
    end



    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterArriveAtPickup( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      if self.Cargo:IsAlive() then
        if TaskUnit:IsAir() then
          Task:GetMission():GetCommandCenter():MessageToGroup( "Land", TaskUnit:GetGroup() )
          self:__Land( -0.1, "Pickup" )
        else
          self:__SelectAction( -0.1 )
        end
      end
    end


    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterCancelRouteToPickup( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      Task:GetMission():GetCommandCenter():MessageToGroup( "Cancelled routing to Cargo " .. self.Cargo:GetName(), TaskUnit:GetGroup() )
      self:__SelectAction( -0.1 )
    end


    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    function Fsm:onafterRouteToDeploy( TaskUnit, Task, From, Event, To, DeployZone )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      self:F( DeployZone )
      self.DeployZone = DeployZone
      Task:SetDeployZone( self.DeployZone, TaskUnit )
      self:__RouteToDeployZone( -0.1 )
    end


    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterArriveAtDeploy( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if TaskUnit:IsAir() then
        Task:GetMission():GetCommandCenter():MessageToGroup( "Land", TaskUnit:GetGroup() )
        self:__Land( -0.1, "Deploy" )
      else
        self:__SelectAction( -0.1 )
      end
    end


    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterCancelRouteToDeploy( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      Task:GetMission():GetCommandCenter():MessageToGroup( "Cancelled routing to deploy zone " .. self.DeployZone:GetName(), TaskUnit:GetGroup() )
      self:__SelectAction( -0.1 )
    end



    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterLand( TaskUnit, Task, From, Event, To, Action )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if Action == "Pickup" then
        if self.Cargo:IsAlive() then
          if self.Cargo:IsInReportRadius( TaskUnit:GetPointVec2() ) then
            if TaskUnit:InAir() then
              self:__Land( -10, Action )
            else
              Task:GetMission():GetCommandCenter():MessageToGroup( "Landed at pickup location...", TaskUnit:GetGroup() )
              self:__Landed( -0.1, Action )
            end
          else
            self:__RouteToPickup( -0.1, self.Cargo )
          end
        end
      else
        if TaskUnit:IsAlive() then
          if TaskUnit:IsInZone( self.DeployZone ) then
            if TaskUnit:InAir() then
              self:__Land( -10, Action )
            else
              Task:GetMission():GetCommandCenter():MessageToGroup( "Landed at deploy zone " .. self.DeployZone:GetName(), TaskUnit:GetGroup() )
              self:__Landed( -0.1, Action )
            end
          else
            self:__RouteToDeploy( -0.1, self.Cargo )
          end
        end
      end
    end

    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterLanded( TaskUnit, Task, From, Event, To, Action )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if Action == "Pickup" then
        if self.Cargo:IsAlive() then
          if self.Cargo:IsInReportRadius( TaskUnit:GetPointVec2() ) then
            if TaskUnit:InAir() then
              self:__Land( -0.1, Action )
            else
              self:__SelectAction( -0.1 )
            end
          else
            self:__RouteToPickup( -0.1, self.Cargo )
          end
        end
      else
        if TaskUnit:IsAlive() then
          if TaskUnit:IsInZone( self.DeployZone ) then
            if TaskUnit:InAir() then
              self:__Land( -10, Action )
            else
              self:__SelectAction( -0.1 )
            end
          else
            self:__RouteToDeploy( -0.1, self.Cargo )
          end
        end
      end
    end
    
    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterPrepareBoarding( TaskUnit, Task, From, Event, To, Cargo )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if Cargo and Cargo:IsAlive() then
        self:__Board( -0.1, Cargo )
      end
    end

    
    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterBoard( TaskUnit, Task, From, Event, To, Cargo  )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      function Cargo:OnEnterLoaded( From, Event, To, TaskUnit, TaskProcess )
        self:F({From, Event, To, TaskUnit, TaskProcess })
        TaskProcess:__Boarded( 0.1, self )
      end

      if Cargo:IsAlive() then
        if Cargo:IsInLoadRadius( TaskUnit:GetPointVec2() ) then
          if TaskUnit:InAir() then
            --- ABORT the boarding. Split group if any and go back to select action.
          else
            Cargo:MessageToGroup( "Boarding ...", TaskUnit:GetGroup() )
            if not Cargo:IsBoarding() then
              Cargo:Board( TaskUnit, nil, self )
            end
          end
        else
          --self:__ArriveAtCargo( -0.1 )
        end
      end
    end


    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterBoarded( TaskUnit, Task, From, Event, To, Cargo  )
      
      local TaskUnitName = TaskUnit:GetName()
      self:F( { TaskUnit = TaskUnitName, Task = Task and Task:GetClassNameAndID() } )

      Cargo:MessageToGroup( "Boarded cargo " .. Cargo:GetName(), TaskUnit:GetGroup() )
      
      self:__Load( -0.1, Cargo )
      
    end
    

    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterLoad( TaskUnit, Task, From, Event, To, Cargo )
      
      local TaskUnitName = TaskUnit:GetName()
      self:F( { TaskUnit = TaskUnitName, Task = Task and Task:GetClassNameAndID() } )
      
      if not Cargo:IsLoaded() then
        Cargo:Load( TaskUnit )
      end

      Cargo:MessageToGroup( "Loaded cargo " .. Cargo:GetName(), TaskUnit:GetGroup() )
      TaskUnit:AddCargo( Cargo )

      Task:CargoPickedUp( TaskUnit, Cargo )

      self:SelectAction( -1 )
      
    end
    

    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    -- @param From
    -- @param Event
    -- @param To
    -- @param Cargo
    -- @param Core.Zone#ZONE_BASE DeployZone
    function Fsm:onafterPrepareUnBoarding( TaskUnit, Task, From, Event, To, Cargo )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID(), From, Event, To, Cargo  } )

      self.Cargo = Cargo
      self.DeployZone = nil

      -- Check if the Cargo is at a deployzone... If it is, provide it as a parameter!      
      if Cargo:IsAlive() then
        for DeployZoneName, DeployZone in pairs( Task.DeployZones ) do
          if Cargo:IsInZone( DeployZone ) then
            self.DeployZone = DeployZone  -- Core.Zone#ZONE_BASE
            break      
          end
        end
        self:__UnBoard( -0.1, Cargo, self.DeployZone )
      end
    end
    
    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    -- @param From
    -- @param Event
    -- @param To
    -- @param Cargo
    -- @param Core.Zone#ZONE_BASE DeployZone
    function Fsm:onafterUnBoard( TaskUnit, Task, From, Event, To, Cargo, DeployZone )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID(), From, Event, To, Cargo, DeployZone } )

      function self.Cargo:OnEnterUnLoaded( From, Event, To, DeployZone, TaskProcess )
        self:F({From, Event, To, DeployZone, TaskProcess })
        TaskProcess:__UnBoarded( -0.1 )
      end

      if self.Cargo:IsAlive() then
        self.Cargo:MessageToGroup( "UnBoarding ...", TaskUnit:GetGroup() )
        if DeployZone then
          self.Cargo:UnBoard( DeployZone:GetCoordinate():GetRandomCoordinateInRadius( 25, 10 ), 400, self )
        else
          self.Cargo:UnBoard( TaskUnit:GetCoordinate():GetRandomCoordinateInRadius( 25, 10 ), 400, self )
        end          
      end
    end


    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterUnBoarded( TaskUnit, Task )

      local TaskUnitName = TaskUnit:GetName()
      self:F( { TaskUnit = TaskUnitName, Task = Task and Task:GetClassNameAndID() } )
      
      self.Cargo:MessageToGroup( "UnBoarded cargo " .. self.Cargo:GetName(), TaskUnit:GetGroup() )
      
      self:Unload( self.Cargo )
    end

    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterUnload( TaskUnit, Task, From, Event, To, Cargo, DeployZone )

      local TaskUnitName = TaskUnit:GetName()
      self:F( { TaskUnit = TaskUnitName, Task = Task and Task:GetClassNameAndID() } )
      
      if not Cargo:IsUnLoaded() then
        if DeployZone then
          Cargo:UnLoad( DeployZone:GetCoordinate():GetRandomCoordinateInRadius( 25, 10 ), 400, self )
        else
          Cargo:UnLoad( TaskUnit:GetCoordinate():GetRandomCoordinateInRadius( 25, 10 ), 400, self )
        end          
      end
      TaskUnit:RemoveCargo( Cargo )
      
      Cargo:MessageToGroup( "Unloaded cargo " .. Cargo:GetName(), TaskUnit:GetGroup() )

      self:Planned()
      self:__SelectAction( 1 )
    end
    
    return self
 
  end


    --- Set a limit on the amount of cargo items that can be loaded into the Carriers.
    -- @param #TASK_CARGO self
    -- @param CargoLimit Specifies a number of cargo items that can be loaded in the helicopter.
    -- @return #TASK_CARGO
    function TASK_CARGO:SetCargoLimit( CargoLimit )
      self.CargoLimit = CargoLimit
      return self
    end
    

    ---@param Color Might be SMOKECOLOR.Blue, SMOKECOLOR.Red SMOKECOLOR.Orange, SMOKECOLOR.White or SMOKECOLOR.Green
    function TASK_CARGO:SetSmokeColor(SmokeColor)
       -- Makes sure Coloe is set
       if SmokeColor == nil then
          self.SmokeColor = SMOKECOLOR.Red -- Make sure a default color is exist
          
       elseif type(SmokeColor) == "number" then
       self:F2(SmokeColor)
        if SmokeColor > 0 and SmokeColor <=5 then -- Make sure number is within ragne, assuming first enum is one
          self.SmokeColor = SMOKECOLOR.SmokeColor
        end
       end
    end
     
    --@return SmokeColor
    function TASK_CARGO:GetSmokeColor()
      return self.SmokeColor
    end
  
  --- @param #TASK_CARGO self
  function TASK_CARGO:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.TargetSetUnit:GetUnitTypesText() .. " )"
  end

  --- @param #TASK_CARGO self
  -- @return Core.Set#SET_CARGO The Cargo Set.
  function TASK_CARGO:GetCargoSet()
  
    return self.SetCargo
  end
  
  --- @param #TASK_CARGO self
  -- @return #list<Core.Zone#ZONE_BASE> The Deployment Zones.
  function TASK_CARGO:GetDeployZones()
  
    return self.DeployZones
  end

  --- @param #TASK_CARGO self
  -- @param AI.AI_Cargo#AI_CARGO Cargo The cargo.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetCargoPickup( Cargo, TaskUnit )
  
    self:F({Cargo, TaskUnit})
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local MenuTime = self:InitTaskControlMenu( TaskUnit )
    local MenuControl = self:GetTaskControlMenu( TaskUnit )
  
    local ActRouteCargo = ProcessUnit:GetProcess( "RoutingToPickup", "RouteToPickupPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteCargo:Reset()
    ActRouteCargo:SetCoordinate( Cargo:GetCoordinate() )
    ActRouteCargo:SetRange( Cargo:GetLoadRadius() )
    ActRouteCargo:SetMenuCancel( TaskUnit:GetGroup(), "Cancel Routing to Cargo " .. Cargo:GetName(), MenuControl, MenuTime, "Cargo" )
    ActRouteCargo:Start()

    return self
  end
  

  --- @param #TASK_CARGO self
  -- @param Core.Zone#ZONE DeployZone
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetDeployZone( DeployZone, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local MenuTime = self:InitTaskControlMenu( TaskUnit )
    local MenuControl = self:GetTaskControlMenu( TaskUnit )
  
    local ActRouteDeployZone = ProcessUnit:GetProcess( "RoutingToDeploy", "RouteToDeployZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteDeployZone:Reset()
    ActRouteDeployZone:SetZone( DeployZone )
    ActRouteDeployZone:SetMenuCancel( TaskUnit:GetGroup(), "Cancel Routing to Deploy Zone" .. DeployZone:GetName(), MenuControl, MenuTime, "Cargo" )
    ActRouteDeployZone:Start()
    
    return self
  end
   
  
  --- @param #TASK_CARGO self
  -- @param Core.Zone#ZONE DeployZone
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:AddDeployZone( DeployZone, TaskUnit )
  
    self.DeployZones[DeployZone:GetName()] = DeployZone

    return self
  end
  
  --- @param #TASK_CARGO self
  -- @param Core.Zone#ZONE DeployZone
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:RemoveDeployZone( DeployZone, TaskUnit )
  
    self.DeployZones[DeployZone:GetName()] = nil

    return self
  end
  
  --- @param #TASK_CARGO self
  -- @param #list<Core.Zone#ZONE> DeployZones
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetDeployZones( DeployZones, TaskUnit )
  
    for DeployZoneID, DeployZone in pairs( DeployZones or {} ) do
      self.DeployZones[DeployZone:GetName()] = DeployZone
    end

    return self
  end
  
  

  --- @param #TASK_CARGO self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Zone#ZONE_BASE The Zone object where the Target is located on the map.
  function TASK_CARGO:GetTargetZone( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteTarget:GetZone()
  end

  --- Set a score when progress is made.
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when there is progress on the task goals.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetScoreOnProgress( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "Account", Text, Score )
    
    return self
  end

  --- Set a score when success is achieved.
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when the task goals have been achieved.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetScoreOnSuccess( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", Text, Score )
    
    return self
  end

  --- Set a penalty when the task goals have failed..
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when the task goals has failed.
  -- @param #number Penalty The penalty in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetScoreOnFail( Text, Penalty, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", Text, Penalty )
    
    return self
  end
  
  function TASK_CARGO:SetGoalTotal()
  
    self.GoalTotal = self.SetCargo:Count()
  end

  function TASK_CARGO:GetGoalTotal()
  
    return self.GoalTotal
  end
  
  --- @param #TASK_CARGO self
  function TASK_CARGO:UpdateTaskInfo()
  
    if self:IsStatePlanned() or self:IsStateAssigned() then
      self.TaskInfo:AddTaskName( 0, "MSOD" )
      self.TaskInfo:AddCargoSet( self.SetCargo, 10, "SOD", true )
      local Coordinates = {}
      for CargoName, Cargo in pairs( self.SetCargo:GetSet() ) do
        local Cargo = Cargo -- Cargo.Cargo#CARGO
        if not Cargo:IsLoaded() then
          Coordinates[#Coordinates+1] = Cargo:GetCoordinate()
        end
      end
      self.TaskInfo:AddCoordinates( Coordinates, 1, "M" )
    end
  end

  function TASK_CARGO:ReportOrder( ReportGroup ) 
    
    return 0
  end

  --- This function is called from the @{Tasking.CommandCenter#COMMANDCENTER} to determine the method of automatic task selection.
  -- @param #TASK_CARGO self
  -- @param #number AutoAssignMethod The method to be applied to the task.
  -- @param Wrapper.Group#GROUP TaskGroup The player group.
  function TASK_CARGO:GetAutoAssignPriority( AutoAssignMethod, TaskGroup )
  
    if     AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Random then
      return math.random( 1, 9 )
    elseif AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Distance then
      return 0
    elseif AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Priority then
      return 1
    end

    return 0
  end
  
  
  
end 


