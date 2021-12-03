--- **Tasking** - Creates and manages player TASK_CARGO tasks.
-- 
-- The **TASK_CARGO_DISPATCHER** allows you to setup various tasks for let human
-- players transport cargo as part of a task. 
--  
-- The cargo dispatcher will implement for you mechanisms to create cargo transportation tasks:
--  
--   * As setup by the mission designer.
--   * Dynamically create CSAR missions (when a pilot is downed as part of a downed plane).
--   * Dynamically spawn new cargo and create cargo taskings!
--   
-- 
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
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Tasking.Task_Cargo_Dispatcher
-- @image Task_Cargo_Dispatcher.JPG

do -- TASK_CARGO_DISPATCHER

  --- TASK_CARGO_DISPATCHER class.
  -- @type TASK_CARGO_DISPATCHER
  -- @extends Tasking.Task_Manager#TASK_MANAGER
  -- @field TASK_CARGO_DISPATCHER.CSAR CSAR
  -- @field Core.Set#SET_ZONE SetZonesCSAR

  --- @type TASK_CARGO_DISPATCHER.CSAR
  -- @field Wrapper.Unit#UNIT PilotUnit
  -- @field Tasking.Task#TASK Task
  

  --- Implements the dynamic dispatching of cargo tasks.
  -- 
  -- The **TASK_CARGO_DISPATCHER** allows you to setup various tasks for let human
  -- players transport cargo as part of a task. 
  -- 
  -- There are currently **two types of tasks** that can be constructed:
  -- 
  --   * A **normal cargo transport** task, which tasks humans to transport cargo from a location towards a deploy zone.
  --   * A **CSAR** cargo transport task. CSAR tasks are **automatically generated** when a friendly (AI) plane is downed and the friendly pilot ejects... 
  --   You as a player (the helo pilot) can go out in the battlefield, fly behind enemy lines, and rescue the pilot (back to a deploy zone).
  -- 
  -- Let's explore **step by step** how to setup the task cargo dispatcher.
  -- 
  -- # 1. Setup a mission environment.
  -- 
  -- It is easy, as it works just like any other task setup, so setup a command center and a mission.
  -- 
  -- ## 1.1. Create a command center.
  -- 
  -- First you need to create a command center using the @{Tasking.CommandCenter#COMMANDCENTER.New}() constructor.
  -- 
  --     local CommandCenter = COMMANDCENTER
  --        :New( HQ, "Lima" ) -- Create the CommandCenter.
  --     
  -- ## 1.2. Create a mission.
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
  --             "Transport the cargo.", 
  --             coalition.side.RED 
  --           ) 
  -- 
  -- 
  -- # 2. Dispatch a **transport cargo** task.
  -- 
  -- So, now that we have a command center and a mission, we now create the transport task.
  -- We create the transport task using the @{#TASK_CARGO_DISPATCHER.AddTransportTask}() constructor.
  -- 
  -- ## 2.1. Create the cargo in the mission.
  -- 
  -- Because a transport task will not generate the cargo itself, you'll need to create it first.
  -- 
  --     -- Here we define the "cargo set", which is a collection of cargo objects.
  --     -- The cargo set will be the input for the cargo transportation task.
  --     -- So a transportation object is handling a cargo set, which is automatically updated when new cargo is added/deleted.
  --     local WorkmaterialsCargoSet = SET_CARGO:New():FilterTypes( "Workmaterials" ):FilterStart()
  --    
  --     -- Now we add cargo into the battle scene.
  --     local PilotGroup = GROUP:FindByName( "Engineers" )
  --      
  --     -- CARGO_GROUP can be used to setup cargo with a GROUP object underneath.
  --     -- We name the type of this group "Workmaterials", so that this cargo group will be included within the WorkmaterialsCargoSet.
  --     -- Note that the name of the cargo is "Engineer Team 1".
  --     local CargoGroup = CARGO_GROUP:New( PilotGroup, "Workmaterials", "Engineer Team 1", 500 )
  -- 
  -- What is also needed, is to have a set of @{Core.Group}s defined that contains the clients of the players.
  -- 
  --     -- Allocate the Transport, which are the helicopters to retrieve the pilot, that can be manned by players.
  --     -- The name of these helicopter groups containing one client begins with "Transport", as modelled within the mission editor.
  --     local PilotGroupSet = SET_GROUP:New():FilterPrefixes( "Transport" ):FilterStart()
  -- 
  -- ## 2.2. Setup the cargo transport task.
  -- 
  -- First, we need to create a TASK_CARGO_DISPATCHER object.
  -- 
  --     TaskDispatcher = TASK_CARGO_DISPATCHER:New( Mission, PilotGroupSet )
  -- 
  -- So, the variable `TaskDispatcher` will contain the object of class TASK_CARGO_DISPATCHER, which will allow you to dispatch cargo transport tasks:
  --  
  --   * for mission `Mission`.
  --   * for the group set `PilotGroupSet`.
  -- 
  -- Now that we have `TaskDispatcher` object, we can now **create the TransportTask**, using the @{#TASK_CARGO_DISPATCHER.AddTransportTask}() method!
  -- 
  --     local TransportTask = TaskDispatcher:AddTransportTask( 
  --       "Transport workmaterials", 
  --       WorkmaterialsCargoSet, 
  --       "Transport the workers, engineers and the equipment near the Workplace." )
  -- 
  -- As a result of this code, the `TransportTask` (returned) variable will contain an object of @{#TASK_CARGO_TRANSPORT}!
  -- We pass to the method the title of the task, and the `WorkmaterialsCargoSet`, which is the set of cargo groups to be transported!
  -- This object can also be used to setup additional things, or to control this specific task with special actions.
  -- 
  -- And you're done! As you can see, it is a bit of work, but the reward is great.
  -- And, because all this is done using program interfaces, you can build a mission with a **dynamic cargo transport task mechanism** yourself!
  -- Based on events happening within your mission, you can use the above methods to create new cargo, and setup a new task for cargo transportation to a group of players!
  -- 
  --     
  -- # 3. Dispatch CSAR tasks.
  -- 
  -- CSAR tasks can be dynamically created when a friendly pilot ejects, or can be created manually.
  -- We'll explore both options.
  -- 
  -- ## 3.1. CSAR task dynamic creation.
  -- 
  -- Because there is an "event" in a running simulation that creates CSAR tasks, the method @{#TASK_CARGO_DISPATCHER.StartCSARTasks}() will create automatically:
  -- 
  --   1. a new downed pilot at the location where the plane was shot
  --   2. declare that pilot as cargo
  --   3. creates a CSAR task automatically to retrieve that pilot
  --   4. requires deploy zones to be specified where to transport the downed pilot to, in order to complete that task.
  -- 
  -- You create a CSAR task dynamically in a very easy way:
  -- 
  --     TaskDispatcher:StartCSARTasks( 
  --       "CSAR", 
  --       { ZONE_UNIT:New( "Hospital", STATIC:FindByName( "Hospital" ), 100 ) }, 
  --       "One of our pilots has ejected. Go out to Search and Rescue our pilot!\n" .. 
  --       "Use the radio menu to let the command center assist you with the CSAR tasking."
  --     )
  -- 
  -- The method @{#TASK_CARGO_DISPATCHER.StopCSARTasks}() will automatically stop with the creation of CSAR tasks when friendly pilots eject.
  -- 
  -- **Remarks:** 
  --   
  --   * the ZONE_UNIT can also be a ZONE, or a ZONE_POLYGON object, or any other ZONE_ object!
  --   * you can declare the array of zones in another variable, or course!
  -- 
  -- 
  -- ## 3.2. CSAR task manual creation.
  -- 
  -- We create the CSAR task using the @{#TASK_CARGO_DISPATCHER.AddCSARTask}() constructor.
  -- 
  -- The method will create a new CSAR task, and will generate the pilots cargo itself, at the specified coordinate.
  -- 
  -- What is first needed, is to have a set of @{Core.Group}s defined that contains the clients of the players.
  -- 
  --     -- Allocate the Transport, which are the helicopter to retrieve the pilot, that can be manned by players.
  --     local GroupSet = SET_GROUP:New():FilterPrefixes( "Transport" ):FilterStart()
  -- 
  -- We need to create a TASK_CARGO_DISPATCHER object.
  -- 
  --     TaskDispatcher = TASK_CARGO_DISPATCHER:New( Mission, GroupSet )
  -- 
  -- So, the variable `TaskDispatcher` will contain the object of class TASK_CARGO_DISPATCHER, which will allow you to dispatch cargo CSAR tasks:
  --  
  --   * for mission `Mission`.
  --   * for the group of players (pilots) captured within the `GroupSet` (those groups with a name starting with `"Transport"`).
  -- 
  -- Now that we have a PilotsCargoSet and a GroupSet, we can now create the CSAR task manually.
  -- 
  --     -- Declare the CSAR task.
  --     local CSARTask = TaskDispatcher:AddCSARTask( 
  --       "CSAR Task",
  --       Coordinate,
  --       270,
  --       "Bring the pilot back!"
  --     )
  -- 
  -- As a result of this code, the `CSARTask` (returned) variable will contain an object of @{#TASK_CARGO_CSAR}!
  -- We pass to the method the title of the task, and the `WorkmaterialsCargoSet`, which is the set of cargo groups to be transported!
  -- This object can also be used to setup additional things, or to control this specific task with special actions.
  -- Note that when you declare a CSAR task manually, you'll still need to specify a deployment zone!
  -- 
  -- # 4. Setup the deploy zone(s).
  -- 
  -- The task cargo dispatcher also foresees methods to setup the deployment zones to where the cargo needs to be transported!
  -- 
  -- There are two levels on which deployment zones can be configured:
  -- 
  --   * Default deploy zones: The TASK_CARGO_DISPATCHER object can have default deployment zones, which will apply over all tasks active in the task dispatcher.
  --   * Task specific deploy zones: The TASK_CARGO_DISPATCHER object can have specific deployment zones which apply to a specific task only!
  -- 
  -- Note that for Task specific deployment zones, there are separate deployment zone creation methods per task type!
  -- 
  -- ## 4.1. Setup default deploy zones.
  -- 
  -- Use the @{#TASK_CARGO_DISPATCHER.SetDefaultDeployZone}() to setup one deployment zone, and @{#TASK_CARGO_DISPATCHER.SetDefaultDeployZones}() to setup multiple default deployment zones in one call.
  -- 
  -- ## 4.2. Setup task specific deploy zones for a **transport task**.
  -- 
  -- Use the @{#TASK_CARGO_DISPATCHER.SetTransportDeployZone}() to setup one deployment zone, and @{#TASK_CARGO_DISPATCHER.SetTransportDeployZones}() to setup multiple default deployment zones in one call.
  -- 
  -- ## 4.3. Setup task specific deploy zones for a **CSAR task**. 
  -- 
  -- Use the @{#TASK_CARGO_DISPATCHER.SetCSARDeployZone}() to setup one deployment zone, and @{#TASK_CARGO_DISPATCHER.SetCSARDeployZones}() to setup multiple default deployment zones in one call.
  -- 
  -- ## 4.4. **CSAR ejection zones**. 
  -- 
  -- Setup a set of zones where the pilots will only eject and a task is created for CSAR. When such a set of zones is given, any ejection outside those zones will not result in a pilot created for CSAR!
  -- 
  -- Use the @{#TASK_CARGO_DISPATCHER.SetCSARZones}() to setup the set of zones.
  -- 
  -- ## 4.5. **CSAR ejection maximum**.
  -- 
  -- Setup how many pilots will eject the maximum. This to avoid an overload of CSAR tasks being created :-) The default is endless CSAR tasks.
  -- 
  -- Use the @{#TASK_CARGO_DISPATCHER.SetMaxCSAR}() to setup the maximum of pilots that will eject for CSAR.
  -- 
  -- 
  -- # 5) Handle cargo task events.
  -- 
  -- When a player is picking up and deploying cargo using his carrier, events are generated by the dispatcher. These events can be captured and tailored with your own code.
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
  -- First, we need to create a TASK_CARGO_DISPATCHER object.
  -- 
  --      TaskDispatcher = TASK_CARGO_DISPATCHER:New( Mission, PilotGroupSet )
  -- 
  -- Second, we create a new cargo transport task for the transportation of workmaterials.
  -- 
  --      TaskDispatcher:AddTransportTask( 
  --        "Transport workmaterials", 
  --        WorkmaterialsCargoSet, 
  --        "Transport the workers, engineers and the equipment near the Workplace." )
  -- 
  -- Note that we don't really need to keep the resulting task, it is kept internally also in the dispatcher.
  -- 
  -- Using the `TaskDispatcher` object, we can now cpature the CargoPickedUp and CargoDeployed events.
  -- 
  -- ## 5.1) Handle the **CargoPickedUp** event.
  -- 
  -- Find below an example how to tailor the **CargoPickedUp** event, generated by the `TaskDispatcher`:
  -- 
  --      function TaskDispatcher:OnAfterCargoPickedUp( From, Event, To, Task, TaskPrefix, TaskUnit, Cargo )
  --        
  --        MESSAGE:NewType( "Unit " .. TaskUnit:GetName().. " has picked up cargo for task " .. Task:GetName() .. ".", MESSAGE.Type.Information ):ToAll()
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
  --      -- @param Tasking.Task_Cargo#TASK_CARGO Task The cargo task for which the cargo has been picked up. Note that this will be a derived TAKS_CARGO object!
  --      -- @param #string TaskPrefix The prefix of the task that was provided when the task was created.
  --      -- @param Wrapper.Unit#UNIT TaskUnit The unit (client) of the player that has picked up the cargo.
  --      -- @param Cargo.Cargo#CARGO Cargo The cargo object that has been picked up. Note that this can be a CARGO_GROUP, CARGO_CRATE or CARGO_SLINGLOAD object!
  --      function CLASS:OnAfterCargoPickedUp( From, Event, To, Task, TaskPrefix, TaskUnit, Cargo )
  --      
  --        -- Write here your own code.
  --      
  --      end
  -- 
  -- 
  -- ## 5.2) Handle the **CargoDeployed** event.
  -- 
  -- Find below an example how to tailor the **CargoDeployed** event, generated by the `TaskDispatcher`:
  -- 
  --       function WorkplaceTask:OnAfterCargoDeployed( From, Event, To, Task, TaskPrefix, TaskUnit, Cargo, DeployZone )
  --        
  --         MESSAGE:NewType( "Unit " .. TaskUnit:GetName().. " has deployed cargo at zone " .. DeployZone:GetName() .. " for task " .. Task:GetName() .. ".", MESSAGE.Type.Information ):ToAll()
  --        
  --         Helos[ math.random(1,#Helos) ]:Spawn()
  --         EnemyHelos[ math.random(1,#EnemyHelos) ]:Spawn()
  --       end
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
  --      -- @param Tasking.Task_Cargo#TASK_CARGO Task The cargo task for which the cargo has been deployed. Note that this will be a derived TAKS_CARGO object!
  --      -- @param #string TaskPrefix The prefix of the task that was provided when the task was created.
  --      -- @param Wrapper.Unit#UNIT TaskUnit The unit (client) of the player that has deployed the cargo.
  --      -- @param Cargo.Cargo#CARGO Cargo The cargo object that has been deployed. Note that this can be a CARGO_GROUP, CARGO_CRATE or CARGO_SLINGLOAD object!
  --      -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
  --      function CLASS:OnAfterCargoDeployed( From, Event, To, Task, TaskPrefix, TaskUnit, Cargo, DeployZone )
  --      
  --        -- Write here your own code.
  --      
  --      end
  -- 
  -- 
  -- 
  -- @field #TASK_CARGO_DISPATCHER
  TASK_CARGO_DISPATCHER = {
    ClassName = "TASK_CARGO_DISPATCHER",
    Mission = nil,
    Tasks = {},
    CSAR = {},
    CSARSpawned = 0,
    
    Transport = {},
    TransportCount = 0,
  }
  
  
  --- TASK_CARGO_DISPATCHER constructor.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param Tasking.Mission#MISSION Mission The mission for which the task dispatching is done.
  -- @param Core.Set#SET_GROUP SetGroup The set of groups that can join the tasks within the mission.
  -- @return #TASK_CARGO_DISPATCHER self
  function TASK_CARGO_DISPATCHER:New( Mission, SetGroup )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, TASK_MANAGER:New( SetGroup ) ) -- #TASK_CARGO_DISPATCHER
    
    self.Mission = Mission
    
    self:AddTransition( "Started", "Assign", "Started" )
    self:AddTransition( "Started", "CargoPickedUp", "Started" )
    self:AddTransition( "Started", "CargoDeployed", "Started" )
    
    --- OnAfter Transition Handler for Event Assign.
    -- @function [parent=#TASK_CARGO_DISPATCHER] OnAfterAssign
    -- @param #TASK_CARGO_DISPATCHER self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @param Tasking.Task_A2A#TASK_A2A Task
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param #string PlayerName
    
    self:SetCSARRadius()
    self:__StartTasks( 5 )
    
    self.MaxCSAR = nil
    self.CountCSAR = 0
    
    -- For CSAR missions, we process the event when a pilot ejects.
    
    self:HandleEvent( EVENTS.Ejection )
    
    return self
  end


  --- Sets the set of zones were pilots will only be spawned (eject) when the planes crash.  
  -- Note that because this is a set of zones, the MD can create the zones dynamically within his mission!
  -- Just provide a set of zones, see usage, but find the tactical situation here:
  -- 
  -- ![CSAR Zones](../Tasking/CSAR_Zones.JPG)
  -- 
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param Core.Set#SET_ZONE SetZonesCSAR The set of zones where pilots will only be spawned for CSAR when they eject.
  -- @usage
  -- 
  --      TaskDispatcher = TASK_CARGO_DISPATCHER:New( Mission, AttackGroups )
  -- 
  --      -- Use this call to pass the set of zones.
  --      -- Note that you can create the set of zones inline, because the FilterOnce method (and other SET_ZONE methods return self).
  --      -- So here the zones can be created as normal trigger zones (MOOSE creates a collection of ZONE objects when teh mission starts of all trigger zones).
  --      -- Just name them as CSAR zones here.
  --      TaskDispatcher:SetCSARZones( SET_ZONE:New():FilterPrefixes("CSAR"):FilterOnce() )
  -- 
  function TASK_CARGO_DISPATCHER:SetCSARZones( SetZonesCSAR )

    self.SetZonesCSAR = SetZonesCSAR
  
  end


  --- Sets the maximum of pilots that will be spawned (eject) when the planes crash.  
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param #number MaxCSAR The maximum of pilots that will eject for CSAR.
  -- @usage
  -- 
  --      TaskDispatcher = TASK_CARGO_DISPATCHER:New( Mission, AttackGroups )
  -- 
  --      -- Use this call to the maximum of CSAR to 10.
  --      TaskDispatcher:SetMaxCSAR( 10 )
  -- 
  function TASK_CARGO_DISPATCHER:SetMaxCSAR( MaxCSAR )

    self.MaxCSAR = MaxCSAR
  
  end



  --- Handle the event when a pilot ejects.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function TASK_CARGO_DISPATCHER:OnEventEjection( EventData )
    self:F( { EventData = EventData } )
    
    if self.CSARTasks == true then

      local CSARCoordinate = EventData.IniUnit:GetCoordinate()
      local CSARCoalition  = EventData.IniUnit:GetCoalition()
      local CSARCountry    = EventData.IniUnit:GetCountry()
      local CSARHeading    = EventData.IniUnit:GetHeading()
      
      -- Only add a CSAR task if the coalition of the mission is equal to the coalition of the ejected unit.
      if CSARCoalition == self.Mission:GetCommandCenter():GetCoalition() then
        -- And only add if the eject is in one of the zones, if defined.
        if not self.SetZonesCSAR or ( self.SetZonesCSAR and self.SetZonesCSAR:IsCoordinateInZone( CSARCoordinate ) ) then
          -- And only if the maximum of pilots is not reached that ejected!
          if not self.MaxCSAR or ( self.MaxCSAR and self.CountCSAR < self.MaxCSAR ) then
            local CSARTaskName = self:AddCSARTask( self.CSARTaskName, CSARCoordinate, CSARHeading, CSARCountry, self.CSARBriefing )     
            self:SetCSARDeployZones( CSARTaskName, self.CSARDeployZones )
            self.CountCSAR = self.CountCSAR + 1
          end
        end
      end
    end
    
    return self
  end
  

  --- Define one default deploy zone for all the cargo tasks.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param DefaultDeployZone A default deploy zone.
  -- @return #TASK_CARGO_DISPATCHER
  function TASK_CARGO_DISPATCHER:SetDefaultDeployZone( DefaultDeployZone )

    self.DefaultDeployZones = { DefaultDeployZone }
  
    return self
  end
  
  
  --- Define the deploy zones for all the cargo tasks.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param DefaultDeployZones A list of the deploy zones.
  -- @return #TASK_CARGO_DISPATCHER
  -- 
  function TASK_CARGO_DISPATCHER:SetDefaultDeployZones( DefaultDeployZones )

    self.DefaultDeployZones = DefaultDeployZones
  
    return self
  end


  --- Start the generation of CSAR tasks to retrieve a downed pilots.
  -- You need to specify a task briefing, a task name, default deployment zone(s).
  -- This method can only be used once!
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param #string CSARTaskName The CSAR task name.
  -- @param #string CSARDeployZones The zones to where the CSAR deployment should be directed.
  -- @param #string CSARBriefing The briefing of the CSAR tasks.
  -- @return #TASK_CARGO_DISPATCHER
  function TASK_CARGO_DISPATCHER:StartCSARTasks( CSARTaskName, CSARDeployZones, CSARBriefing)
  
    if not self.CSARTasks then
      self.CSARTasks = true
      self.CSARTaskName = CSARTaskName
      self.CSARDeployZones = CSARDeployZones
      self.CSARBriefing = CSARBriefing
    else
      error( "TASK_CARGO_DISPATCHER: The generation of CSAR tasks has already started." )
    end
  
    return self
  end
  
  
  --- Stop the generation of CSAR tasks to retrieve a downed pilots.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @return #TASK_CARGO_DISPATCHER
  function TASK_CARGO_DISPATCHER:StopCSARTasks()
  
    if self.CSARTasks then
      self.CSARTasks = nil
      self.CSARTaskName = nil
      self.CSARDeployZones = nil
      self.CSARBriefing = nil
    else
      error( "TASK_CARGO_DISPATCHER: The generation of CSAR tasks was not yet started." )
    end
  
    return self
  end
  
  
  --- Add a CSAR task to retrieve a downed pilot.
  -- You need to specify a coordinate from where the pilot will be spawned to be rescued.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param #string CSARTaskPrefix (optional) The prefix of the CSAR task. 
  -- @param Core.Point#COORDINATE CSARCoordinate The coordinate where a downed pilot will be spawned.
  -- @param #number CSARHeading The heading of the pilot in degrees.
  -- @param DCSCountry#Country CSARCountry The country ID of the pilot that will be spawned.
  -- @param #string CSARBriefing The briefing of the CSAR task.
  -- @return #string The CSAR Task Name as a string. The Task Name is the main key and is shown in the task list of the Mission Tasking menu.
  -- @usage
  -- 
  --   -- Add a CSAR task to rescue a downed pilot from within a coordinate.
  --   local Coordinate = PlaneUnit:GetPointVec2()
  --   TaskA2ADispatcher:AddCSARTask( "CSAR Task", Coordinate )
  --   
  --   -- Add a CSAR task to rescue a downed pilot from within a coordinate of country RUSSIA, which is pointing to the west (270°).
  --   local Coordinate = PlaneUnit:GetPointVec2()
  --   TaskA2ADispatcher:AddCSARTask( "CSAR Task", Coordinate, 270, Country.RUSSIA )
  --   
  function TASK_CARGO_DISPATCHER:AddCSARTask( CSARTaskPrefix, CSARCoordinate, CSARHeading, CSARCountry, CSARBriefing )

    local CSARCoalition = self.Mission:GetCommandCenter():GetCoalition()

    CSARHeading = CSARHeading or 0
    CSARCountry = CSARCountry or self.Mission:GetCommandCenter():GetCountry()

    self.CSARSpawned = self.CSARSpawned + 1
    
    local CSARTaskName = string.format( ( CSARTaskPrefix or "CSAR" ) .. ".%03d", self.CSARSpawned )
    
    -- Create the CSAR Pilot SPAWN object.
    -- Let us create the Template for the replacement Pilot :-)
    local Template = {
      ["visible"] = false,
      ["hidden"] = false,
      ["task"] = "Ground Nothing",
      ["name"] = string.format( "CSAR Pilot#%03d", self.CSARSpawned ),
      ["x"] = CSARCoordinate.x,
      ["y"] = CSARCoordinate.z,
      ["units"] = 
      {
        [1] = 
        {
          ["type"] = ( CSARCoalition == coalition.side.BLUE ) and "Soldier M4" or "Infantry AK",
          ["name"] = string.format( "CSAR Pilot#%03d-01", self.CSARSpawned ),
          ["skill"] = "Excellent",
          ["playerCanDrive"] = false,
          ["x"] = CSARCoordinate.x,
          ["y"] = CSARCoordinate.z,
          ["heading"] = CSARHeading,
        }, -- end of [1]
      }, -- end of ["units"]
    }

    local CSARGroup = GROUP:NewTemplate( Template, CSARCoalition, Group.Category.GROUND, CSARCountry )

    self.CSAR[CSARTaskName] = {} 
    self.CSAR[CSARTaskName].PilotGroup = CSARGroup
    self.CSAR[CSARTaskName].Briefing = CSARBriefing
    self.CSAR[CSARTaskName].Task = nil
    self.CSAR[CSARTaskName].TaskPrefix = CSARTaskPrefix
    
    return CSARTaskName
  end


  --- Define the radius to when a CSAR task will be generated for any downed pilot within range of the nearest CSAR airbase.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param #number CSARRadius (Optional, Default = 50000) The radius in meters to decide whether a CSAR needs to be created.
  -- @return #TASK_CARGO_DISPATCHER
  -- @usage
  -- 
  --   -- Set 20km as the radius to CSAR any downed pilot within range of the nearest CSAR airbase.
  --   TaskA2ADispatcher:SetEngageRadius( 20000 )
  --   
  --   -- Set 50km as the radius to to CSAR any downed pilot within range of the nearest CSAR airbase.
  --   TaskA2ADispatcher:SetEngageRadius() -- 50000 is the default value.
  --   
  function TASK_CARGO_DISPATCHER:SetCSARRadius( CSARRadius )

    self.CSARRadius = CSARRadius or 50000
  
    return self
  end
  
  
  --- Define one deploy zone for the CSAR tasks.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param #string CSARTaskName (optional) The name of the CSAR task. 
  -- @param CSARDeployZone A CSAR deploy zone.
  -- @return #TASK_CARGO_DISPATCHER
  function TASK_CARGO_DISPATCHER:SetCSARDeployZone( CSARTaskName, CSARDeployZone )

    if CSARTaskName then
      self.CSAR[CSARTaskName].DeployZones = { CSARDeployZone }
    end
  
    return self
  end
  
  
  --- Define the deploy zones for the CSAR tasks.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param #string CSARTaskName (optional) The name of the CSAR task.
  -- @param CSARDeployZones A list of the CSAR deploy zones.
  -- @return #TASK_CARGO_DISPATCHER
  -- 
  function TASK_CARGO_DISPATCHER:SetCSARDeployZones( CSARTaskName, CSARDeployZones )

    if CSARTaskName and self.CSAR[CSARTaskName] then
      self.CSAR[CSARTaskName].DeployZones = CSARDeployZones
    end
  
    return self
  end


  --- Add a Transport task to transport cargo from fixed locations to a deployment zone.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param #string TaskPrefix (optional) The prefix of the transport task. 
  -- This prefix will be appended with a . + a number of 3 digits.
  -- If no TaskPrefix is given, then "Transport" will be used as the prefix. 
  -- @param Core.SetCargo#SET_CARGO SetCargo The SetCargo to be transported.
  -- @param #string Briefing The briefing of the task transport to be shown to the player.
  -- @param #boolean Silent If true don't send a message that a new task is available.
  -- @return Tasking.Task_Cargo_Transport#TASK_CARGO_TRANSPORT
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
  function TASK_CARGO_DISPATCHER:AddTransportTask( TaskPrefix, SetCargo, Briefing, Silent )

    self.TransportCount = self.TransportCount + 1
    
    local verbose = Silent or false
    
    local TaskName = string.format( ( TaskPrefix or "Transport" ) .. ".%03d", self.TransportCount )
    
    self.Transport[TaskName] = {} 
    self.Transport[TaskName].SetCargo = SetCargo
    self.Transport[TaskName].Briefing = Briefing
    self.Transport[TaskName].Task = nil
    self.Transport[TaskName].TaskPrefix = TaskPrefix
    
    self:ManageTasks(verbose)
    
    return self.Transport[TaskName] and self.Transport[TaskName].Task
  end


  --- Define one deploy zone for the Transport tasks.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param Tasking.Task_Cargo_Transport#TASK_CARGO_TRANSPORT Task The name of the Transport task. 
  -- @param TransportDeployZone A Transport deploy zone.
  -- @return #TASK_CARGO_DISPATCHER
  -- @usage
  -- 
  -- 
  function TASK_CARGO_DISPATCHER:SetTransportDeployZone( Task, TransportDeployZone )

    if self.Transport[Task.TaskName] then
      self.Transport[Task.TaskName].DeployZones = { TransportDeployZone }
    else
      error( "Task does not exist" )
    end

    self:ManageTasks()
  
    return self
  end
  
  
  --- Define the deploy zones for the Transport tasks.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param Tasking.Task_Cargo_Transport#TASK_CARGO_TRANSPORT Task The name of the Transport task. 
  -- @param TransportDeployZones A list of the Transport deploy zones.
  -- @return #TASK_CARGO_DISPATCHER
  -- 
  function TASK_CARGO_DISPATCHER:SetTransportDeployZones( Task, TransportDeployZones )

    if self.Transport[Task.TaskName] then
      self.Transport[Task.TaskName].DeployZones = TransportDeployZones
    else
      error( "Task does not exist" )
    end

    self:ManageTasks()
  
    return self
  end
  
  --- Evaluates of a CSAR task needs to be started.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @return Core.Set#SET_CARGO The SetCargo to be rescued.
  -- @return #nil If there is no CSAR task required.
  function TASK_CARGO_DISPATCHER:EvaluateCSAR( CSARUnit )
  
    local CSARCargo = CARGO_GROUP:New( CSARUnit, "Pilot", CSARUnit:GetName(), 80, 1500, 10 )
    
    local SetCargo = SET_CARGO:New()
    SetCargo:AddCargosByName( CSARUnit:GetName() )
    
    SetCargo:Flush(self)
    
    return SetCargo
    
  end

  

  --- Assigns tasks to the @{Core.Set#SET_GROUP}.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param #boolean Silent Announce new task (nil/false) or not (true).
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function TASK_CARGO_DISPATCHER:ManageTasks(Silent)
    self:F()
    local verbose = Silent and true
    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}
    
    local Mission = self.Mission
    
    if Mission:IsIDLE() or Mission:IsENGAGED() then
    
      local TaskReport = REPORT:New()
      
      -- Checking the task queue for the dispatcher, and removing any obsolete task!
      for TaskIndex, TaskData in pairs( self.Tasks ) do
        local Task = TaskData -- Tasking.Task#TASK
        if Task:IsStatePlanned() then
          -- Here we need to check if the pilot is still existing.
--          local DetectedItem = Detection:GetDetectedItemByIndex( TaskIndex )
--          if not DetectedItem then
--            local TaskText = Task:GetName()
--            for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
--              Mission:GetCommandCenter():MessageToGroup( string.format( "Obsolete A2A task %s for %s removed.", TaskText, Mission:GetShortText() ), TaskGroup )
--            end
--            Task = self:RemoveTask( TaskIndex )
--          end
        end
      end

      -- Now that all obsolete tasks are removed, loop through the CSAR pilots.
      for CSARName, CSAR in pairs( self.CSAR ) do
      
        if not CSAR.Task then
          -- New CSAR Task
          local SetCargo = self:EvaluateCSAR( CSAR.PilotGroup )
          CSAR.Task = TASK_CARGO_CSAR:New( Mission, self.SetGroup, CSARName, SetCargo, CSAR.Briefing )
          CSAR.Task.TaskPrefix = CSAR.TaskPrefix -- We keep the TaskPrefix for further reference!
          Mission:AddTask( CSAR.Task )
          TaskReport:Add( CSARName )
          if CSAR.DeployZones then
            CSAR.Task:SetDeployZones( CSAR.DeployZones or {} )
          else
            CSAR.Task:SetDeployZones( self.DefaultDeployZones or {} )
          end
          
          -- Now broadcast the onafterCargoPickedUp event to the Task Cargo Dispatcher.
          function CSAR.Task.OnAfterCargoPickedUp( Task, From, Event, To, TaskUnit, Cargo )
            self:CargoPickedUp( Task, Task.TaskPrefix, TaskUnit, Cargo )
          end

          -- Now broadcast the onafterCargoDeployed event to the Task Cargo Dispatcher.
          function CSAR.Task.OnAfterCargoDeployed( Task, From, Event, To, TaskUnit, Cargo, DeployZone )
            self:CargoDeployed( Task, Task.TaskPrefix, TaskUnit, Cargo, DeployZone )
          end
          
        end
      end
      
      
      -- Now that all obsolete tasks are removed, loop through the Transport tasks.
      for TransportName, Transport in pairs( self.Transport ) do
        
        if not Transport.Task then
          -- New Transport Task
          Transport.Task = TASK_CARGO_TRANSPORT:New( Mission, self.SetGroup, TransportName, Transport.SetCargo, Transport.Briefing )
          Transport.Task.TaskPrefix = Transport.TaskPrefix -- We keep the TaskPrefix for further reference!
          Mission:AddTask( Transport.Task )
          TaskReport:Add( TransportName )
          function Transport.Task.OnEnterSuccess( Task, From, Event, To )
            self:Success( Task )
          end

          function Transport.Task.OnEnterCancelled( Task, From, Event, To )
            self:Cancelled( Task )
          end
          
          function Transport.Task.OnEnterFailed( Task, From, Event, To )
            self:Failed( Task )
          end

          function Transport.Task.OnEnterAborted( Task, From, Event, To )
            self:Aborted( Task )
          end

          -- Now broadcast the onafterCargoPickedUp event to the Task Cargo Dispatcher.
          function Transport.Task.OnAfterCargoPickedUp( Task, From, Event, To, TaskUnit, Cargo )
            self:CargoPickedUp( Task, Task.TaskPrefix, TaskUnit, Cargo )
          end

          -- Now broadcast the onafterCargoDeployed event to the Task Cargo Dispatcher.
          function Transport.Task.OnAfterCargoDeployed( Task, From, Event, To, TaskUnit, Cargo, DeployZone )
            self:CargoDeployed( Task, Task.TaskPrefix, TaskUnit, Cargo, DeployZone )
          end
          
        end
        
        if Transport.DeployZones then
          Transport.Task:SetDeployZones( Transport.DeployZones or {} )
        else
          Transport.Task:SetDeployZones( self.DefaultDeployZones or {} )
        end
        
      end
      
      
      -- TODO set menus using the HQ coordinator
      Mission:GetCommandCenter():SetMenu()

      local TaskText = TaskReport:Text(", ")
      
      for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
        if ( not Mission:IsGroupAssigned(TaskGroup) ) and TaskText ~= "" and not verbose then
          Mission:GetCommandCenter():MessageToGroup( string.format( "%s has tasks %s. Subscribe to a task using the radio menu.", Mission:GetShortText(), TaskText ), TaskGroup )
        end
      end
      
    end
    
    return true
  end

end
