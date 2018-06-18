--- **Tasking** -- The TASK_CARGO models tasks for players to transport @{Cargo}.
-- 
-- ![Banner Image](..\Presentations\TASK_CARGO\Dia1.JPG)
-- 
-- ===
--
-- The Moose framework provides various CARGO classes that allow DCS phisical or logical objects to be transported or sling loaded by Carriers.
-- The CARGO_ classes, as part of the moose core, are able to Board, Load, UnBoard and UnLoad cargo between Carrier units.
-- 
-- This collection of classes in this module define tasks for human players to handle these cargo objects.
-- Cargo can be transported, picked-up, deployed and sling-loaded from and to other places.
-- 
-- The following classes are important to consider:
-- 
--   * @{#TASK_CARGO_TRANSPORT}: Defines a task for a human player to transport a set of cargo between various zones.
--   * @{#TASK_CARGO_CSAR}: Defines a task for a human player to Search and Rescue wounded pilots.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
--   
-- @module Tasking.Task_Cargo
-- @image MOOSE.JPG

do -- TASK_CARGO

  --- @type TASK_CARGO
  -- @extends Tasking.Task#TASK

  ---
  -- # TASK_CARGO class, extends @{Tasking.Task#TASK}
  -- 
  -- ## A flexible tasking system
  -- 
  -- The TASK_CARGO classes provide you with a flexible tasking sytem, 
  -- that allows you to transport cargo of various types between various locations
  -- and various dedicated deployment zones.
  -- 
  -- The cargo in scope of the TASK_CARGO classes must be explicitly given, and is of type SET_CARGO.
  -- The SET_CARGO contains a collection of CARGO objects that must be handled by the players in the mission.
  -- 
  -- 
  -- ## Task execution experience from the player perspective
  -- 
  -- A human player can join the battle field in a client airborne slot or a ground vehicle within the CA module (ALT-J).
  -- The player needs to accept the task from the task overview list within the mission, using the radio menus.
  -- 
  -- Once the TASK_CARGO is assigned to the player and accepted by the player, the player will obtain 
  -- an extra **Cargo Handling Radio Menu** that contains the CARGO objects that need to be transported.
  -- 
  -- Each CARGO object has a certain state:
  -- 
  --   * **UnLoaded**: The CARGO is located within the battlefield. It may still need to be transported.
  --   * **Loaded**: The CARGO is loaded within a Carrier. This can be your air unit, or another air unit, or even a vehicle.
  --   * **Boarding**: The CARGO is running or moving towards your Carrier for loading.
  --   * **UnBoarding**: The CARGO is driving or jumping out of your Carrier and moves to a location in the Deployment Zone.
  -- 
  -- Cargo must be transported towards different **Deployment @{Zone}s**.
  -- 
  -- The Cargo Handling Radio Menu system allows to execute **various actions** to handle the cargo.
  -- In the menu, you'll find for each CARGO, that is part of the scope of the task, various actions that can be completed.
  -- Depending on the location of your Carrier unit, the menu options will vary.
  -- 
  -- 
  -- ## Cargo Pickup and Boarding
  -- 
  -- For cargo boarding, a cargo can only execute the boarding actions if it is within the foreseen **Reporting Range**. 
  -- Therefore, it is important that you steer your Carrier within the Reporting Range, 
  -- so that boarding actions can be executed on the cargo.
  -- To Pickup and Board cargo, the following menu items will be shown in your carrier radio menu:
  -- 
  -- ### Board Cargo
  -- 
  -- If your Carrier is within the Reporting Range of the cargo, it will allow to pickup the cargo by selecting this menu option.
  -- Depending on the Cargo type, the cargo will either move to your Carrier or you will receive instructions how to handle the cargo
  -- pickup. If the cargo moves to your carrier, it will indicate the boarding status.
  -- Note that multiple units need to board your Carrier, so it is required to await the full boarding process.
  -- Once the cargo is fully boarded within your Carrier, you will be notified of this.
  -- 
  -- Note that for airborne Carriers, it is required to land first before the Boarding process can be initiated.
  -- If during boarding the Carrier gets airborne, the boarding process will be cancelled.
  -- 
  -- ## Pickup Cargo
  -- 
  -- If your Carrier is not within the Reporting Range of the cargo, the HQ will guide you to its location. 
  -- Routing information is shown in flight that directs you to the cargo within Reporting Range.
  -- Upon arrival, the Cargo will contact you and further instructions will be given.
  -- When your Carrier is airborne, you will receive instructions to land your Carrier.
  -- The action will not be completed until you've landed your Carrier.
  -- 
  -- 
  -- ## Cargo Deploy and UnBoarding
  -- 
  -- Various Deployment Zones can be foreseen in the scope of the Cargo transportation. Each deployment zone can be of varying @{Zone} type.
  -- The Cargo Handling Radio Menu provides with menu options to execute an action to steer your Carrier to a specific Zone.
  -- 
  -- ### UnBoard Cargo
  -- 
  -- If your Carrier is already within a Deployment Zone, 
  -- then the Cargo Handling Radio Menu allows to **UnBoard** a specific cargo that is
  -- loaded within your Carrier group into the Deployment Zone.
  -- Note that the Unboarding process takes a while, as the cargo units (infantry or vehicles) must unload from your Carrier.
  -- Ensure that you stay at the position or stay on the ground while Unboarding.
  -- If any unforeseen manoeuvre is done by the Carrier, then the Unboarding will be cancelled.
  -- 
  -- ### Deploy Cargo
  -- 
  -- If your Carrier is not within a Deployment Zone, you'll need to fly towards one. 
  -- Fortunately, the Cargo Handling Radio Menu provides you with menu options to select a specific Deployment Zone to fly towards.
  -- Once a Deployment Zone has been selected, your Carrier will receive routing information from HQ towards the Deployment Zone center.
  -- Upon arrival, the HQ will provide you with further instructions.
  -- When your Carrier is airborne, you will receive instructions to land your Carrier.
  -- The action will not be completed until you've landed your Carrier!
  -- 
  -- ## Handle TASK_CARGO Events ...
  -- 
  -- The TASK_CARGO classes define @{Cargo} transport tasks, 
  -- based on the tasking capabilities defined in @{Tasking.Task#TASK}.
  -- 
  -- ### Specific TASK_CARGO Events
  -- 
  -- Specific Cargo Handling event can be captured, that allow to trigger specific actions!
  -- 
  --   * **Boarded**: Triggered when the Cargo has been Boarded into your Carrier.
  --   * **UnBoarded**: Triggered when the cargo has been Unboarded from your Carrier and has arrived at the Deployment Zone.
  -- 
  -- ### Standard TASK_CARGO Events
  -- 
  -- The TASK_CARGO is implemented using a @{Core.Fsm#FSM_TASK}, and has the following standard statuses:
  -- 
  --   * **None**: Start of the process.
  --   * **Planned**: The cargo task is planned.
  --   * **Assigned**: The cargo task is assigned to a @{Wrapper.Group#GROUP}.
  --   * **Success**: The cargo task is successfully completed.
  --   * **Failed**: The cargo task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
  -- 
  -- ===
  -- 
  -- @field #TASK_CARGO
  --   
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
      local CargoItemCount = TaskUnit:CargoItemCount()
      
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
              if CargoItemCount < 1 then 
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
                          if Cargo:CanSlingload() == true then
                            if Cargo:IsInLoadRadius( TaskUnit:GetPointVec2() ) then
                              Cargo:Report( "Ready for slingloading.", "slingload", TaskUnit:GetGroup() )
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
                    MENU_GROUP_COMMAND:New( TaskUnit:GetGroup(), Cargo.Name, RouteToPickupMenu, self.MenuRouteToPickup, self, Cargo ):SetTime(MenuTime):SetTag("Cargo"):SetRemoveParent()
                    Cargo:ReportResetAll( TaskUnit:GetGroup() )
                  end
                end
              end
              
              -- Cargo in deployzones are flagged as deployed.
              for DeployZoneName, DeployZone in pairs( Task.DeployZones ) do
                if Cargo:IsInZone( DeployZone ) then
                  Task:E( { CargoIsDeployed = Task.CargoDeployed and "true" or "false" } )
                  if Cargo:IsDeployed() == false then
                    Cargo:SetDeployed( true )
                    -- Now we call a callback method to handle the CargoDeployed event.
                    Task:E( { CargoIsAlive = Cargo:IsAlive() and "true" or "false" } )
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
              Cargo:Board( TaskUnit, 20, self )
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
  function TASK_CARGO:UpdateTaskInfo( DetectedItem )
  
    if self:IsStatePlanned() or self:IsStateAssigned() then
      self.TaskInfo:AddCargoSet( self.SetCargo, 10, "SOD", true )
    end
  end

  function TASK_CARGO:ReportOrder( ReportGroup ) 
    
    return 0
  end
  
  
  
end 


