--- **Tasking (Release 2.1)** -- The TASK_CARGO models tasks for players to transport @{Cargo}.
-- 
-- ![Banner Image](..\Presentations\TASK_CARGO\Dia1.JPG)
-- 
-- ====
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
-- 
-- ==
-- 
-- # **API CHANGE HISTORY**
--
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
--
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
--
-- Hereby the change log:
--
-- 2017-03-09: Revised version.
--
-- ===
--
-- # **AUTHORS and CONTRIBUTIONS**
--
-- ### Contributions:
--
-- ### Authors:
--
--   * **FlightControl**: Concept, Design & Programming.
--   
-- @module Task_Cargo

do -- TASK_CARGO

  --- @type TASK_CARGO
  -- @extends Tasking.Task#TASK

  ---
  -- # TASK_CARGO class, extends @{Task#TASK}
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
  -- based on the tasking capabilities defined in @{Task#TASK}.
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
  -- The TASK_CARGO is implemented using a @{Statemachine#FSM_TASK}, and has the following standard statuses:
  -- 
  --   * **None**: Start of the process.
  --   * **Planned**: The cargo task is planned.
  --   * **Assigned**: The cargo task is assigned to a @{Group#GROUP}.
  --   * **Success**: The cargo task is successfully completed.
  --   * **Failed**: The cargo task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
  -- 
  -- ===
  -- 
  -- @field #TASK_CARGO TASK_CARGO
  --   
  TASK_CARGO = {
    ClassName = "TASK_CARGO",
  }
  
  --- Instantiates a new TASK_CARGO.
  -- @param #TASK_CARGO self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_CARGO SetCargo The scope of the cargo to be transported.
  -- @param #string TaskType The type of Cargo task.
  -- @return #TASK_CARGO self
  function TASK_CARGO:New( Mission, SetGroup, TaskName, SetCargo, TaskType )
    local self = BASE:Inherit( self, TASK:New( Mission, SetGroup, TaskName, TaskType ) ) -- #TASK_CARGO
    self:F( {Mission, SetGroup, TaskName, SetCargo, TaskType})
  
    self.SetCargo = SetCargo
    self.TaskType = TaskType
    
    self.DeployZones = {} -- setmetatable( {}, { __mode = "v" } ) -- weak table on value

    Mission:AddTask( self )
    
    local Fsm = self:GetUnitProcess()
    

    Fsm:AddProcess   ( "Planned", "Accept", ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "SelectAction", Rejected = "Reject" }  )
    
    Fsm:AddTransition( "*", "SelectAction", "WaitingForCommand" )

    Fsm:AddTransition( "WaitingForCommand", "RouteToPickup", "RoutingToPickup" )
    Fsm:AddProcess   ( "RoutingToPickup", "RouteToPickupPoint", ACT_ROUTE_POINT:New(), { Arrived = "ArriveAtPickup" } )
    Fsm:AddTransition( "Arrived", "ArriveAtPickup", "ArrivedAtPickup" )

    Fsm:AddTransition( "WaitingForCommand", "RouteToDeploy", "RoutingToDeploy" )
    Fsm:AddProcess   ( "RoutingToDeploy", "RouteToDeployZone", ACT_ROUTE_ZONE:New(), { Arrived = "ArriveAtDeploy" } )
    Fsm:AddTransition( "Arrived", "ArriveAtDeploy", "ArrivedAtDeploy" )
    
    Fsm:AddTransition( { "ArrivedAtPickup", "ArrivedAtDeploy", "Landing" }, "Land", "Landing" )
    Fsm:AddTransition( "Landing", "Landed", "Landed" )
    
    Fsm:AddTransition( "WaitingForCommand", "PrepareBoarding", "AwaitBoarding" )
    Fsm:AddTransition( "AwaitBoarding", "Board", "Boarding" )
    Fsm:AddTransition( "Boarding", "Boarded", "Boarded" )

    Fsm:AddTransition( "WaitingForCommand", "PrepareUnBoarding", "AwaitUnBoarding" )
    Fsm:AddTransition( "AwaitUnBoarding", "UnBoard", "UnBoarding" )
    Fsm:AddTransition( "UnBoarding", "UnBoarded", "UnBoarded" )
    
    
    Fsm:AddTransition( "Deployed", "Success", "Success" )
    Fsm:AddTransition( "Rejected", "Reject", "Aborted" )
    Fsm:AddTransition( "Failed", "Fail", "Failed" )
    

    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnEnterWaitingForCommand( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      TaskUnit.Menu = MENU_GROUP:New( TaskUnit:GetGroup(), Task:GetName() .. " @ " .. TaskUnit:GetName() )
      
      Task.SetCargo:Flush()
      
      Task.SetCargo:ForEachCargo(
        
        --- @param Core.Cargo#CARGO Cargo
        function( Cargo ) 
          if Cargo:IsUnLoaded() then
            if Cargo:IsInRadius( TaskUnit:GetPointVec2() ) then
              MENU_GROUP_COMMAND:New(
                TaskUnit:GetGroup(),
                "Pickup cargo " .. Cargo.Name,
                TaskUnit.Menu,
                self.MenuBoardCargo,
                self,
                Cargo
              )
            else
              MENU_GROUP_COMMAND:New(
                TaskUnit:GetGroup(),
                "Route to cargo " .. Cargo.Name,
                TaskUnit.Menu,
                self.MenuRouteToPickup,
                self,
                Cargo
              )
            end
          end
          
          if Cargo:IsLoaded() then
            for DeployZoneName, DeployZone in pairs( Task.DeployZones ) do
              if Cargo:IsInZone( DeployZone ) then
                MENU_GROUP_COMMAND:New(
                  TaskUnit:GetGroup(),
                  "Deploy cargo " .. Cargo.Name,
                  TaskUnit.Menu,
                  self.MenuUnBoardCargo,
                  self,
                  Cargo,
                  DeployZone
                )
              else
                MENU_GROUP_COMMAND:New(
                  TaskUnit:GetGroup(),
                  "Route to deploy zone " .. DeployZoneName,
                  TaskUnit.Menu,
                  self.MenuRouteToDeploy,
                  self,
                  DeployZone
                )
              end
            end
          end
        
        end
      )
    end
    
    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnLeaveWaitingForCommand( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      TaskUnit.Menu:Remove()
    end
    
    function Fsm:MenuBoardCargo( Cargo )
      self:__PrepareBoarding( 1.0, Cargo )
    end
    
    function Fsm:MenuUnBoardCargo( Cargo, DeployZone )
      self:__PrepareUnBoarding( 1.0, Cargo, DeployZone )
    end
    
    function Fsm:MenuRouteToPickup( Cargo )
      self:__RouteToPickup( 1.0, Cargo )
    end
    
    function Fsm:MenuRouteToDeploy( DeployZone )
      self:__RouteToDeploy( 1.0, DeployZone )
    end
    
    --- Route to Cargo
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterRouteToPickup( TaskUnit, Task, From, Event, To, Cargo )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      
      self.Cargo = Cargo
      Task:SetCargoPickup( self.Cargo, TaskUnit )
      self:__RouteToPickupPoint( -0.1 )
    end


    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterArriveAtPickup( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if TaskUnit:IsAir() then
        self:__Land( -0.1, "Pickup" )
      else
        self:__SelectAction( -0.1 )
      end
    end


    --- Route to DeployZone
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    function Fsm:onafterRouteToDeploy( TaskUnit, Task, From, Event, To, DeployZone )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      
      self.DeployZone = DeployZone
      Task:SetDeployZone( self.DeployZone, TaskUnit )
      self:__RouteToDeployZone( -0.1 )
    end


    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterArriveAtDeploy( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if TaskUnit:IsAir() then
        self:__Land( -0.1, "Deploy" )
      else
        self:__SelectAction( -0.1 )
      end
    end



    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterLand( TaskUnit, Task, From, Event, To, Action )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if self.Cargo:IsInRadius( TaskUnit:GetPointVec2() ) then
        if TaskUnit:InAir() then
          Task:GetMission():GetCommandCenter():MessageToGroup( "Land", TaskUnit:GetGroup() )
          self:__Land( -10, Action )
        else
          Task:GetMission():GetCommandCenter():MessageToGroup( "Landed ...", TaskUnit:GetGroup() )
          self:__Landed( -0.1, Action )
        end
      else
        if Action == "Pickup" then
          self:__RouteToPickupZone( -0.1 )
        else
          self:__RouteToDeployZone( -0.1 )
        end
      end
    end

    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterLanded( TaskUnit, Task, From, Event, To, Action )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if self.Cargo:IsInRadius( TaskUnit:GetPointVec2() ) then
        if TaskUnit:InAir() then
          self:__Land( -0.1, Action )
        else
          self:__SelectAction( -0.1 )
        end
      else
        if Action == "Pickup" then
          self:__RouteToPickupZone( -0.1 )
        else
          self:__RouteToDeployZone( -0.1 )
        end
      end
    end
    
    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterPrepareBoarding( TaskUnit, Task, From, Event, To, Cargo )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      self.Cargo = Cargo -- Core.Cargo#CARGO_GROUP
      self:__Board( -0.1 )
    end
    
    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterBoard( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      function self.Cargo:OnEnterLoaded( From, Event, To, TaskUnit, TaskProcess )
      
        self:E({From, Event, To, TaskUnit, TaskProcess })
        
        TaskProcess:__Boarded( 0.1 )
      
      end

      
      if self.Cargo:IsInRadius( TaskUnit:GetPointVec2() ) then
        if TaskUnit:InAir() then
          --- ABORT the boarding. Split group if any and go back to select action.
        else
          self.Cargo:MessageToGroup( "Boarding ...", TaskUnit:GetGroup() ) 
          self.Cargo:Board( TaskUnit, 20, self )
        end
      else
        --self:__ArriveAtCargo( -0.1 )
      end
    end


    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterBoarded( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      self.Cargo:MessageToGroup( "Boarded ...", TaskUnit:GetGroup() )
      self:__SelectAction( 1 )
    end
    

    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterPrepareUnBoarding( TaskUnit, Task, From, Event, To, Cargo, DeployZone )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      self.Cargo = Cargo
      self.DeployZone = DeployZone      
      self:__UnBoard( -0.1 )
    end
    
    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterUnBoard( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      function self.Cargo:OnEnterUnLoaded( From, Event, To, DeployZone, TaskProcess )
      
        self:E({From, Event, To, TaskUnit, TaskProcess })
        
        TaskProcess:__UnBoarded( -0.1 )
      
      end

      self.Cargo:MessageToGroup( "UnBoarding ...", TaskUnit:GetGroup() )
      self.Cargo:UnBoard( self.DeployZone:GetPointVec2(), 20, self )
    end


    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterUnBoarded( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      self.Cargo:MessageToGroup( "UnBoarded ...", TaskUnit:GetGroup() )
      self:__SelectAction( 1 )
    end

    
    return self
 
  end
  
  --- @param #TASK_CARGO self
  function TASK_CARGO:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.TargetSetUnit:GetUnitTypesText() .. " )"
  end


  --- @param #TASK_CARGO self
  -- @param AI.AI_Cargo#AI_CARGO Cargo The cargo.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetCargoPickup( Cargo, TaskUnit  )
  
    self:F({Cargo, TaskUnit})
    local ProcessUnit = self:GetUnitProcess( TaskUnit )
  
    local ActRouteCargo = ProcessUnit:GetProcess( "RoutingToPickup", "RouteToPickupPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteCargo:SetPointVec2( Cargo:GetPointVec2() )
    ActRouteCargo:SetRange( Cargo:GetBoardingRange() )
    return self
  end
  

  --- @param #TASK_CARGO self
  -- @param Core.Zone#ZONE DeployZone
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetDeployZone( DeployZone, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteDeployZone = ProcessUnit:GetProcess( "RoutingToDeploy", "RouteToDeployZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteDeployZone:SetZone( DeployZone )
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
  -- @param @list<Core.Zone#ZONE> DeployZones
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetDeployZones( DeployZones, TaskUnit )
  
    for DeployZoneID, DeployZone in pairs( DeployZones ) do
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

  --- Set a score when a target in scope of the A2G attack, has been destroyed .
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when the target has been destroyed.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetScoreOnDestroy( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "Account", Text, Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2G attack, have been destroyed.
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when all targets hav been destroyed.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetScoreOnSuccess( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", Text, Score )
    
    return self
  end

  --- Set a penalty when the A2G attack has failed.
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when the A2G attack has failed.
  -- @param #number Penalty The penalty in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetPenaltyOnFailed( Text, Penalty, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", Text, Penalty )
    
    return self
  end

  
end 


do -- TASK_CARGO_TRANSPORT

  --- The TASK_CARGO_TRANSPORT class
  -- @type TASK_CARGO_TRANSPORT
  -- @extends #TASK_CARGO
  TASK_CARGO_TRANSPORT = {
    ClassName = "TASK_CARGO_TRANSPORT",
  }
  
  --- Instantiates a new TASK_CARGO_TRANSPORT.
  -- @param #TASK_CARGO_TRANSPORT self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_CARGO SetCargo The scope of the cargo to be transported.
  -- @return #TASK_CARGO_TRANSPORT self
  function TASK_CARGO_TRANSPORT:New( Mission, SetGroup, TaskName, SetCargo )
    local self = BASE:Inherit( self, TASK_CARGO:New( Mission, SetGroup, TaskName, SetCargo, "Transport" ) ) -- #TASK_CARGO_TRANSPORT
    self:F()
    
    return self
  end 

end

