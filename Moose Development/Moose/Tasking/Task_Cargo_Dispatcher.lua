--- **Tasking** - Creates and manages player TASK_CARGO tasks.
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

  --- @type TASK_CARGO_DISPATCHER.CSAR
  -- @field Wrapper.Unit#UNIT PilotUnit
  -- @field Tasking.Task#TASK Task
  

  --- Implements the dynamic dispatching of cargo tasks.
  -- 
  -- ![Banner Image](..\Presentations\TASK_CARGO_DISPATCHER\Dia3.JPG)
  -- 
  -- The EWR will detect units, will group them, and will dispatch @{Task}s to groups. Depending on the type of target detected, different tasks will be dispatched.
  -- Find a summary below describing for which situation a task type is created:
  -- 
  -- ![Banner Image](..\Presentations\TASK_CARGO_DISPATCHER\Dia9.JPG)
  -- 
  --   * **CSAR Task**: Is created when a fiendly pilot has ejected from a plane, and needs to be rescued (sometimes behind enemy lines).
  -- 
  -- ## 1. TASK\_A2A\_DISPATCHER constructor:
  -- 
  -- The @{#TASK_CARGO_DISPATCHER.New}() method creates a new TASK\_A2A\_DISPATCHER instance.
  -- 
  -- ### 1.1. Define or set the **Mission**:
  -- 
  -- Tasking is executed to accomplish missions. Therefore, a MISSION object needs to be given as the first parameter.
  -- 
  --     local HQ = GROUP:FindByName( "HQ", "Bravo" )
  --     local CommandCenter = COMMANDCENTER:New( HQ, "Lima" )
  --     local Mission = MISSION:New( CommandCenter, "A2A Mission", "High", "Watch the air enemy units being detected.", coalition.side.RED )
  -- 
  -- Missions are governed by COMMANDCENTERS, so, ensure you have a COMMANDCENTER object installed and setup within your mission.
  -- Create the MISSION object, and hook it under the command center.
  -- 
  -- ### 1.2. Build a set of the groups seated by human players:
  -- 
  -- ![Banner Image](..\Presentations\TASK_CARGO_DISPATCHER\Dia6.JPG)
  -- 
  -- A set or collection of the groups wherein human players can be seated, these can be clients or units that can be joined as a slot or jumping into.
  --     
  --     local AttackGroups = SET_GROUP:New():FilterCoalitions( "red" ):FilterPrefixes( "Defender" ):FilterStart()
  --     
  -- The set is built using the SET_GROUP class. Apply any filter criteria to identify the correct groups for your mission.
  -- Only these slots or units will be able to execute the mission and will receive tasks for this mission, once available.
  -- 
  -- ### 1.3. Define the **EWR network**:
  -- 
  -- As part of the TASK\_A2A\_DISPATCHER constructor, an EWR network must be given as the third parameter.
  -- An EWR network, or, Early Warning Radar network, is used to early detect potential airborne targets and to understand the position of patrolling targets of the enemy.
  -- 
  -- ![Banner Image](..\Presentations\TASK_CARGO_DISPATCHER\Dia5.JPG)
  -- 
  -- Typically EWR networks are setup using 55G6 EWR, 1L13 EWR, Hawk sr and Patriot str ground based radar units. 
  -- These radars have different ranges and 55G6 EWR and 1L13 EWR radars are Eastern Bloc units (eg Russia, Ukraine, Georgia) while the Hawk and Patriot radars are Western (eg US).
  -- Additionally, ANY other radar capable unit can be part of the EWR network! Also AWACS airborne units, planes, helicopters can help to detect targets, as long as they have radar.
  -- The position of these units is very important as they need to provide enough coverage 
  -- to pick up enemy aircraft as they approach so that CAP and GCI flights can be tasked to intercept them.
  -- 
  -- ![Banner Image](..\Presentations\TASK_CARGO_DISPATCHER\Dia7.JPG)
  --  
  -- Additionally in a hot war situation where the border is no longer respected the placement of radars has a big effect on how fast the war escalates. 
  -- For example if they are a long way forward and can detect enemy planes on the ground and taking off 
  -- they will start to vector CAP and GCI flights to attack them straight away which will immediately draw a response from the other coalition. 
  -- Having the radars further back will mean a slower escalation because fewer targets will be detected and 
  -- therefore less CAP and GCI flights will spawn and this will tend to make just the border area active rather than a melee over the whole map. 
  -- It all depends on what the desired effect is. 
  -- 
  -- EWR networks are **dynamically constructed**, that is, they form part of the @{Functional.Detection#DETECTION_BASE} object that is given as the input parameter of the TASK\_A2A\_DISPATCHER class.
  -- By defining in a **smart way the names or name prefixes of the groups** with EWR capable units, these groups will be **automatically added or deleted** from the EWR network, 
  -- increasing or decreasing the radar coverage of the Early Warning System.
  -- 
  -- See the following example to setup an EWR network containing EWR stations and AWACS.
  -- 
  --     local EWRSet = SET_GROUP:New():FilterPrefixes( "EWR" ):FilterCoalitions("red"):FilterStart()
  --
  --     local EWRDetection = DETECTION_AREAS:New( EWRSet, 6000 )
  --     EWRDetection:SetFriendliesRange( 10000 )
  --     EWRDetection:SetRefreshTimeInterval(30)
  --
  --     -- Setup the A2A dispatcher, and initialize it.
  --     A2ADispatcher = TASK_CARGO_DISPATCHER:New( Mission, AttackGroups, EWRDetection )
  -- 
  -- The above example creates a SET_GROUP instance, and stores this in the variable (object) **EWRSet**.
  -- **EWRSet** is then being configured to filter all active groups with a group name starting with **EWR** to be included in the Set.
  -- **EWRSet** is then being ordered to start the dynamic filtering. Note that any destroy or new spawn of a group with the above names will be removed or added to the Set.
  -- Then a new **EWRDetection** object is created from the class DETECTION_AREAS. A grouping radius of 6000 is choosen, which is 6km.
  -- The **EWRDetection** object is then passed to the @{#TASK_CARGO_DISPATCHER.New}() method to indicate the EWR network configuration and setup the A2A tasking and detection mechanism.
  -- 
  -- ### 2. Define the detected **target grouping radius**:
  -- 
  -- ![Banner Image](..\Presentations\TASK_CARGO_DISPATCHER\Dia8.JPG)
  -- 
  -- The target grouping radius is a property of the Detection object, that was passed to the AI\_A2A\_DISPATCHER object, but can be changed.
  -- The grouping radius should not be too small, but also depends on the types of planes and the era of the simulation.
  -- Fast planes like in the 80s, need a larger radius than WWII planes.  
  -- Typically I suggest to use 30000 for new generation planes and 10000 for older era aircraft.
  -- 
  -- Note that detected targets are constantly re-grouped, that is, when certain detected aircraft are moving further than the group radius, then these aircraft will become a separate
  -- group being detected. This may result in additional GCI being started by the dispatcher! So don't make this value too small!
  -- 
  -- ## 3. Set the **Engage radius**:
  -- 
  -- Define the radius to engage any target by airborne friendlies, which are executing cap or returning from an intercept mission.
  -- 
  -- ![Banner Image](..\Presentations\TASK_CARGO_DISPATCHER\Dia11.JPG)
  -- 
  -- So, if there is a target area detected and reported, 
  -- then any friendlies that are airborne near this target area, 
  -- will be commanded to (re-)engage that target when available (if no other tasks were commanded).
  -- For example, if 100000 is given as a value, then any friendly that is airborne within 100km from the detected target, 
  -- will be considered to receive the command to engage that target area.
  -- You need to evaluate the value of this parameter carefully.
  -- If too small, more intercept missions may be triggered upon detected target areas.
  -- If too large, any airborne cap may not be able to reach the detected target area in time, because it is too far.
  -- 
  -- ## 4. Set **Scoring** and **Messages**:
  -- 
  -- The TASK\_A2A\_DISPATCHER is a state machine. It triggers the event Assign when a new player joins a @{Task} dispatched by the TASK\_A2A\_DISPATCHER.
  -- An _event handler_ can be defined to catch the **Assign** event, and add **additional processing** to set _scoring_ and to _define messages_,
  -- when the player reaches certain achievements in the task.
  -- 
  -- The prototype to handle the **Assign** event needs to be developed as follows:
  -- 
  --      TaskDispatcher = TASK_CARGO_DISPATCHER:New( ... )
  -- 
  --      --- @param #TaskDispatcher self
  --      -- @param #string From Contains the name of the state from where the Event was triggered.
  --      -- @param #string Event Contains the name of the event that was triggered. In this case Assign.
  --      -- @param #string To Contains the name of the state that will be transitioned to.
  --      -- @param Tasking.Task_A2A#TASK_A2A Task The Task object, which is any derived object from TASK_A2A.
  --      -- @param Wrapper.Unit#UNIT TaskUnit The Unit or Client that contains the Player.
  --      -- @param #string PlayerName The name of the Player that joined the TaskUnit.
  --      function TaskDispatcher:OnAfterAssign( From, Event, To, Task, TaskUnit, PlayerName )
  --        Task:SetScoreOnProgress( PlayerName, 20, TaskUnit )
  --        Task:SetScoreOnSuccess( PlayerName, 200, TaskUnit )
  --        Task:SetScoreOnFail( PlayerName, -100, TaskUnit )
  --      end
  -- 
  -- The **OnAfterAssign** method (function) is added to the TaskDispatcher object.
  -- This method will be called when a new player joins a unit in the set of groups in scope of the dispatcher.
  -- So, this method will be called only **ONCE** when a player joins a unit in scope of the task.
  -- 
  -- The TASK class implements various methods to additional **set scoring** for player achievements:
  -- 
  --   * @{Tasking.Task#TASK.SetScoreOnProgress}() will add additional scores when a player achieves **Progress** while executing the task.
  --     Examples of **task progress** can be destroying units, arriving at zones etc.
  --   
  --   * @{Tasking.Task#TASK.SetScoreOnSuccess}() will add additional scores when the task goes into **Success** state. 
  --     This means the **task has been successfully completed**.
  --     
  --   * @{Tasking.Task#TASK.SetScoreOnSuccess}() will add additional (negative) scores when the task goes into **Failed** state. 
  --     This means the **task has not been successfully completed**, and the scores must be given with a negative value!
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
    
    -- For CSAR missions, we process the event when a pilot ejects.
    
    self:HandleEvent( EVENTS.Ejection )
    
    return self
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
        local CSARTaskName = self:AddCSARTask( self.CSARTaskName, CSARCoordinate, CSARHeading, CSARCountry, self.CSARBriefing )     
        self:SetCSARDeployZones( CSARTaskName, self.CSARDeployZones )
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
  --   TaskA2ADispatcher:AddCSARTask( Coordinate )
  --   
  --   -- Add a CSAR task to rescue a downed pilot from within a coordinate of country RUSSIA, which is pointing to the west (270°).
  --   local Coordinate = PlaneUnit:GetPointVec2()
  --   TaskA2ADispatcher:AddCSARTask( Coordinate, 270, Country.RUSSIA )
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
  function TASK_CARGO_DISPATCHER:AddTransportTask( TaskName, SetCargo, Briefing )

    self.TransportCount = self.TransportCount + 1
    
    local TaskName = string.format( ( TaskName or "Transport" ) .. ".%03d", self.TransportCount )
    
    self.Transport[TaskName] = {} 
    self.Transport[TaskName].SetCargo = SetCargo
    self.Transport[TaskName].Briefing = Briefing
    self.Transport[TaskName].Task = nil
    
    self:ManageTasks()
    
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
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function TASK_CARGO_DISPATCHER:ManageTasks()
    self:F()
  
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
          Mission:AddTask( CSAR.Task )
          TaskReport:Add( CSARName )
          if CSAR.DeployZones then
            CSAR.Task:SetDeployZones( CSAR.DeployZones or {} )
          else
            CSAR.Task:SetDeployZones( self.DefaultDeployZones or {} )
          end
        end
      end
      
      
      -- Now that all obsolete tasks are removed, loop through the Transport tasks.
      for TransportName, Transport in pairs( self.Transport ) do
        
        if not Transport.Task then
          -- New Transport Task
          Transport.Task = TASK_CARGO_TRANSPORT:New( Mission, self.SetGroup, TransportName, Transport.SetCargo, Transport.Briefing )
          Mission:AddTask( Transport.Task )
          TaskReport:Add( TransportName )
          function Transport.Task.OnEnterSuccess( Task, From, Event, To )
            self:Success( Task )
          end

          function Transport.Task.onenterCancelled( Task, From, Event, To )
            self:Cancelled( Task )
          end
          
          function Transport.Task.onenterFailed( Task, From, Event, To )
            self:Failed( Task )
          end

          function Transport.Task.onenterAborted( Task, From, Event, To )
            self:Aborted( Task )
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
        if ( not Mission:IsGroupAssigned(TaskGroup) ) and TaskText ~= "" then
          Mission:GetCommandCenter():MessageToGroup( string.format( "%s has tasks %s. Subscribe to a task using the radio menu.", Mission:GetShortText(), TaskText ), TaskGroup )
        end
      end
      
    end
    
    return true
  end

end
