--- **Tasking** -- Models tasks for players to transport cargo.
-- 
-- **Specific features:**
-- 
--   * Creates a task to transport @{Cargo.Cargo} to and between deployment zones.
--   * Derived from the TASK_CARGO class, which is derived from the TASK class.
--   * Orchestrate the task flow, so go from Planned to Assigned to Success, Failed or Cancelled.
--   * Co-operation tasking, so a player joins a group of players executing the same task.
-- 
-- 
-- **A complete task menu system to allow players to:**
--   
--   * Join the task, abort the task.
--   * Mark the task location on the map.
--   * Provide details of the target.
--   * Route to the cargo.
--   * Route to the deploy zones.
--   * Load/Unload cargo.
--   * Board/Unboard cargo.
--   * Slingload cargo.
--   * Display the task briefing.
--   
--   
-- **A complete mission menu system to allow players to:**
--   
--   * Join a task, abort the task.
--   * Display task reports.
--   * Display mission statistics.
--   * Mark the task locations on the map.
--   * Provide details of the targets.
--   * Display the mission briefing.
--   * Provide status updates as retrieved from the command center.
--   * Automatically assign a random task as part of a mission.
--   * Manually assign a specific task as part of a mission.
--   
--   
--  **A settings system, using the settings menu:**
--  
--   * Tweak the duration of the display of messages.
--   * Switch between metric and imperial measurement system.
--   * Switch between coordinate formats used in messages: BR, BRA, LL DMS, LL DDM, MGRS.
--   * Different settings modes for A2G and A2A operations.
--   * Various other options.
--
-- ===
-- 
-- Please read through the @{Tasking.Task_Cargo} process to understand the mechanisms of tasking and cargo tasking and handling.
-- 
-- Enjoy!
-- FC
-- 
-- ===
-- 
-- @module Tasking.Task_Cargo_Transport
-- @image Task_Cargo_Transport.JPG


do -- TASK_CARGO_TRANSPORT

  --- @type TASK_CARGO_TRANSPORT
  -- @extends Tasking.Task_CARGO#TASK_CARGO

  --- Orchestrates the task for players to transport cargo to or between deployment zones.
  -- 
  -- Transport tasks are suited to govern the process of transporting cargo to specific deployment zones.
  -- Typically, this task is executed by helicopter pilots, but it can also be executed by ground forces!
  -- 
  -- ===
  -- 
  -- A transport task can be created manually.
  --  
  -- # 1) Create a transport task manually (code it).
  -- 
  -- Although it is recommended to use the dispatcher, you can create a transport task yourself as a mission designer.
  -- It is easy, as it works just like any other task setup.
  -- 
  -- ## 1.1) Create a command center.
  -- 
  -- First you need to create a command center using the @{Tasking.CommandCenter#COMMANDCENTER.New}() constructor.
  -- 
  --     local CommandCenter = COMMANDCENTER
  --        :New( HQ, "Lima" ) -- Create the CommandCenter.
  --     
  -- ## 1.2) Create a mission.
  -- 
  -- Tasks work in a mission, which groups these tasks to achieve a joint mission goal.
  -- A command center can govern multiple missions.
  -- Create a new mission, using the @{Tasking.Mission#MISSION.New}() constructor.
  -- 
  --     -- Declare the Mission for the Command Center.
  --     local Mission = MISSION
  --       :New( CommandCenter, 
  --             "Overlord", 
  --             "High", 
  --             "Transport the cargo to the deploy zones.", 
  --             coalition.side.RED 
  --           ) 
  -- 
  -- ## 1.3) Create the transport cargo task.
  -- 
  -- So, now that we have a command center and a mission, we now create the transport task.
  -- We create the transport task using the @{#TASK_CARGO_TRANSPORT.New}() constructor.
  -- 
  -- Because a transport task will not generate the cargo itself, you'll need to create it first.
  -- The cargo in this case will be the downed pilot!
  -- 
  --     -- Here we define the "cargo set", which is a collection of cargo objects.
  --     -- The cargo set will be the input for the cargo transportation task.
  --     -- So a transportation object is handling a cargo set, which is automatically refreshed when new cargo is added/deleted.
  --     local CargoSet = SET_CARGO:New():FilterTypes( "Cargo" ):FilterStart()
  --    
  --     -- Now we add cargo into the battle scene.
  --     local PilotGroup = GROUP:FindByName( "Engineers" )
  --      
  --     -- CARGO_GROUP can be used to setup cargo with a GROUP object underneath.
  --     -- We name this group Engineers.
  --     -- Note that the name of the cargo is "Engineers".
  --     -- The cargoset "CargoSet" will embed all defined cargo of type "Pilots" (prefix) into its set.
  --     local CargoGroup = CARGO_GROUP:New( PilotGroup, "Cargo", "Engineer Team 1", 500 )
  -- 
  -- What is also needed, is to have a set of @{Core.Group}s defined that contains the clients of the players.
  -- 
  --     -- Allocate the Transport, which are the helicopter to retrieve the pilot, that can be manned by players.
  --     local GroupSet = SET_GROUP:New():FilterPrefixes( "Transport" ):FilterStart()
  -- 
  -- Now that we have a CargoSet and a GroupSet, we can now create the TransportTask manually.
  -- 
  --     -- Declare the transport task.
  --     local TransportTask = TASK_CARGO_TRANSPORT
  --       :New( Mission, 
  --             GroupSet, 
  --             "Transport Engineers", 
  --             CargoSet, 
  --             "Fly behind enemy lines, and retrieve the downed pilot." 
  --           )
  -- 
  -- So you can see, setting up a transport task manually is a lot of work.
  -- It is better you use the cargo dispatcher to create transport tasks and it will work as it is intended.
  -- By doing this, cargo transport tasking will become a dynamic experience.
  -- 
  -- 
  -- # 2) Create a task using the @{Tasking.Task_Cargo_Dispatcher} module.
  -- 
  -- Actually, it is better to **GENERATE** these tasks using the @{Tasking.Task_Cargo_Dispatcher} module.
  -- Using the dispatcher module, transport tasks can be created much more easy.
  -- 
  -- Find below an example how to use the TASK_CARGO_DISPATCHER class:
  -- 
  -- 
  --    -- Find the HQ group.
  --    HQ = GROUP:FindByName( "HQ", "Bravo" )
  --    
  --    -- Create the command center with the name "Lima".
  --    CommandCenter = COMMANDCENTER
  --      :New( HQ, "Lima" )
  --    
  --    -- Create the mission, for the command center, with the name "Operation Cargo Fun", a "Tactical" mission, with the mission briefing "Transport Cargo", for the BLUE coalition.
  --    Mission = MISSION
  --      :New( CommandCenter, "Operation Cargo Fun", "Tactical", "Transport Cargo", coalition.side.BLUE )
  --    
  --    -- Create the SET of GROUPs containing clients (players) that will transport the cargo.
  --    -- These are have a name that start with "Transport" and are of the "blue" coalition.
  --    TransportGroups = SET_GROUP:New():FilterCoalitions( "blue" ):FilterPrefixes( "Transport" ):FilterStart()
  --    
  --    
  --    -- Here we create the TASK_CARGO_DISPATCHER object! This is where we assign the dispatcher to generate tasks in the Mission for the TransportGroups.
  --    TaskDispatcher = TASK_CARGO_DISPATCHER:New( Mission, TransportGroups )
  --    
  --    
  --    -- Here we declare the SET of CARGOs called "Workmaterials".
  --    local CargoSetWorkmaterials = SET_CARGO:New():FilterTypes( "Workmaterials" ):FilterStart()
  --    
  --    -- Here we declare (add) CARGO_GROUP objects of various types, that are filtered and added in the CargoSetworkmaterials cargo set.
  --    -- These cargo objects have the type "Workmaterials" which is exactly the type of cargo the CargoSetworkmaterials is filtering on.
  --    local EngineerCargoGroup = CARGO_GROUP:New( GROUP:FindByName( "Engineers" ), "Workmaterials", "Engineers", 250 )
  --    local ConcreteCargo = CARGO_SLINGLOAD:New( STATIC:FindByName( "Concrete" ), "Workmaterials", "Concrete", 150, 50 )
  --    local CrateCargo = CARGO_CRATE:New( STATIC:FindByName( "Crate" ), "Workmaterials", "Crate", 150, 50 )
  --    local EnginesCargo = CARGO_CRATE:New( STATIC:FindByName( "Engines" ), "Workmaterials", "Engines", 150, 50 )
  --    local MetalCargo = CARGO_CRATE:New( STATIC:FindByName( "Metal" ), "Workmaterials", "Metal", 150, 50 )
  --    
  --    -- And here we create a new WorkplaceTask, using the :AddTransportTask method of the TaskDispatcher.
  --    local WorkplaceTask = TaskDispatcher:AddTransportTask( "Build a Workplace", CargoSetWorkmaterials, "Transport the workers, engineers and the equipment near the Workplace." )
  --    TaskDispatcher:SetTransportDeployZone( WorkplaceTask, ZONE:New( "Workplace" ) )
  -- 
  -- # 3) Handle cargo task events.
  -- 
  -- When a player is picking up and deploying cargo using his carrier, events are generated by the tasks. These events can be captured and tailored with your own code.
  -- 
  -- In order to properly capture the events and avoid mistakes using the documentation, it is advised that you execute the following actions:
  -- 
  --   * **Copy / Paste** the code section into your script.
  --   * **Change** the CLASS literal to the task object name you have in your script.
  --   * Within the function, you can now **write your own code**!
  --   * **IntelliSense** will recognize the type of the variables provided by the function. Note: the From, Event and To variables can be safely ignored, 
  --     but you need to declare them as they are automatically provided by the event handling system of MOOSE.
  -- 
  -- You can send messages or fire off any other events within the code section. The sky is the limit!
  -- 
  -- 
  -- ## 3.1) Handle the CargoPickedUp event.
  -- 
  -- Find below an example how to tailor the **CargoPickedUp** event, generated by the WorkplaceTask:
  -- 
  --      function WorkplaceTask:OnAfterCargoPickedUp( From, Event, To, TaskUnit, Cargo )
  --        
  --        MESSAGE:NewType( "Unit " .. TaskUnit:GetName().. " has picked up cargo.", MESSAGE.Type.Information ):ToAll()
  --        
  --      end
  -- 
  -- If you want to code your own event handler, use this code fragment to tailor the event when a player carrier has picked up a cargo object in the CarrierGroup.
  -- You can use this event handler to post messages to players, or provide status updates etc.
  -- 
  --      --- CargoPickedUp event handler OnAfter for CLASS.
  --      -- @param #CLASS self
  --      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
  --      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
  --      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
  --      -- @param Wrapper.Unit#UNIT TaskUnit The unit (client) of the player that has picked up the cargo.
  --      -- @param Cargo.Cargo#CARGO Cargo The cargo object that has been picked up. Note that this can be a CARGO_GROUP, CARGO_CRATE or CARGO_SLINGLOAD object!
  --      function CLASS:OnAfterCargoPickedUp( From, Event, To, TaskUnit, Cargo )
  --      
  --        -- Write here your own code.
  --      
  --      end
  -- 
  -- 
  -- ## 3.2) Handle the CargoDeployed event.
  -- 
  -- Find below an example how to tailor the **CargoDeployed** event, generated by the WorkplaceTask:
  -- 
  --      function WorkplaceTask:OnAfterCargoDeployed( From, Event, To, TaskUnit, Cargo, DeployZone )
  --        
  --        MESSAGE:NewType( "Unit " .. TaskUnit:GetName().. " has deployed cargo at zone " .. DeployZone:GetName(), MESSAGE.Type.Information ):ToAll()
  --        
  --        Helos[ math.random(1,#Helos) ]:Spawn()
  --        EnemyHelos[ math.random(1,#EnemyHelos) ]:Spawn()
  --      end
  -- 
  -- If you want to code your own event handler, use this code fragment to tailor the event when a player carrier has deployed a cargo object from the CarrierGroup.
  -- You can use this event handler to post messages to players, or provide status updates etc.
  -- 
  -- 
  --      --- CargoDeployed event handler OnAfter for CLASS.
  --      -- @param #CLASS self
  --      -- @param #string From A string that contains the "*from state name*" when the event was triggered.
  --      -- @param #string Event A string that contains the "*event name*" when the event was triggered.
  --      -- @param #string To A string that contains the "*to state name*" when the event was triggered.
  --      -- @param Wrapper.Unit#UNIT TaskUnit The unit (client) of the player that has deployed the cargo.
  --      -- @param Cargo.Cargo#CARGO Cargo The cargo object that has been deployed. Note that this can be a CARGO_GROUP, CARGO_CRATE or CARGO_SLINGLOAD object!
  --      -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
  --      function CLASS:OnAfterCargoDeployed( From, Event, To, TaskUnit, Cargo, DeployZone )
  --      
  --        -- Write here your own code.
  --      
  --      end
  -- 
  -- 
  -- 
  -- ===
  -- 
  -- @field #TASK_CARGO_TRANSPORT
  TASK_CARGO_TRANSPORT = {
    ClassName = "TASK_CARGO_TRANSPORT",
  }
  
  --- Instantiates a new TASK_CARGO_TRANSPORT.
  -- @param #TASK_CARGO_TRANSPORT self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_CARGO SetCargo The scope of the cargo to be transported.
  -- @param #string TaskBriefing The Cargo Task briefing.
  -- @return #TASK_CARGO_TRANSPORT self
  function TASK_CARGO_TRANSPORT:New( Mission, SetGroup, TaskName, SetCargo, TaskBriefing )
    local self = BASE:Inherit( self, TASK_CARGO:New( Mission, SetGroup, TaskName, SetCargo, "Transport", TaskBriefing ) ) -- #TASK_CARGO_TRANSPORT
    self:F()
    
    Mission:AddTask( self )
    
    local Fsm = self:GetUnitProcess()

    local CargoReport = REPORT:New( "Transport Cargo. The following cargo needs to be transported including initial positions:")
    
    SetCargo:ForEachCargo(
      --- @param Core.Cargo#CARGO Cargo
      function( Cargo )
        local CargoType = Cargo:GetType()
        local CargoName = Cargo:GetName()
        local CargoCoordinate = Cargo:GetCoordinate()
        CargoReport:Add( string.format( '- "%s" (%s) at %s', CargoName, CargoType, CargoCoordinate:ToStringMGRS() ) )
      end
    )
    
    self:SetBriefing( 
      TaskBriefing or 
      CargoReport:Text()
    )

    
    return self
  end 

  function TASK_CARGO_TRANSPORT:ReportOrder( ReportGroup ) 
    
    return 0
  end

  
  --- 
  -- @param #TASK_CARGO_TRANSPORT self
  -- @return #boolean
  function TASK_CARGO_TRANSPORT:IsAllCargoTransported()
  
    local CargoSet = self:GetCargoSet()
    local Set = CargoSet:GetSet()
    
    local DeployZones = self:GetDeployZones()
    
    local CargoDeployed = true
    
    -- Loop the CargoSet (so evaluate each Cargo in the SET_CARGO ).
    for CargoID, CargoData in pairs( Set ) do
      local Cargo = CargoData -- Core.Cargo#CARGO
      
      self:F( { Cargo = Cargo:GetName(), CargoDeployed = Cargo:IsDeployed() } )

      if Cargo:IsDeployed() then
      
--        -- Loop the DeployZones set for the TASK_CARGO_TRANSPORT.
--        for DeployZoneID, DeployZone in pairs( DeployZones ) do
--        
--          -- If all cargo is in one of the deploy zones, then all is good.
--          self:T( { Cargo.CargoObject } )
--          if Cargo:IsInZone( DeployZone ) == false then
--            CargoDeployed = false
--          end
--        end
      else
        CargoDeployed = false
      end
    end

    self:F( { CargoDeployed = CargoDeployed } )
    
    return CargoDeployed
  end
  
  --- @param #TASK_CARGO_TRANSPORT self
  function TASK_CARGO_TRANSPORT:onafterGoal( TaskUnit, From, Event, To )
    local CargoSet = self.CargoSet
    
    if self:IsAllCargoTransported() then
      self:Success()
    end
    
    self:__Goal( -10 )
  end

end

