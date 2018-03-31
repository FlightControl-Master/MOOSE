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
-- @module Task_Cargo_Dispatcher

do -- TASK_CARGO_DISPATCHER

  --- TASK_CARGO_DISPATCHER class.
  -- @type TASK_CARGO_DISPATCHER
  -- @extends Tasking.Task_Manager#TASK_MANAGER
  -- @field TASK_CARGO_DISPATCHER.CSAR CSAR

  --- @type TASK_CARGO_DISPATCHER.CSAR
  -- @field Wrapper.Unit#UNIT PilotUnit
  -- @field Tasking.Task#TASK Task
  

  --- # TASK_CARGO_DISPATCHER class, extends @{Task_Manager#TASK_MANAGER}
  -- 
  -- ![Banner Image](..\Presentations\TASK_CARGO_DISPATCHER\Dia1.JPG)
  -- 
  -- The @{#TASK_CARGO_DISPATCHER} class implements the dynamic dispatching of cargo tasks.
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
  -- EWR networks are **dynamically constructed**, that is, they form part of the @{Functional#DETECTION_BASE} object that is given as the input parameter of the TASK\_A2A\_DISPATCHER class.
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
  }
  
  
  --- TASK_CARGO_DISPATCHER constructor.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param Tasking.Mission#MISSION Mission The mission for which the task dispatching is done.
  -- @param Set#SET_GROUP SetGroup The set of groups that can join the tasks within the mission.
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

    self:E( { EventData = EventData } )

    local PlaneUnit = EventData.IniUnit
    local CSARName = EventData.IniUnitName
    
    local PilotUnit = nil
    
    self:ScheduleOnce( 1, 
      function()
        
        -- Search for the ejected pilot
    
        local PlaneCoord = PlaneUnit:GetCoordinate()
        
        local SphereSearch = {
         id = world.VolumeType.SPHERE,
          params = {
           point = PlaneCoord:GetVec3(),
           radius = 100,
          }
          
        }
         
        --- @param Dcs.DCSWrapper.Unit#Unit FoundDCSUnit
        -- @param Wrapper.Group#GROUP ReportGroup
        -- @param Set#SET_GROUP ReportSetGroup
        local FindEjectedPilot = function( FoundDCSUnit )
            
          local UnitName = FoundDCSUnit:getName()
            
          self:E( { "Units near Plane:", UnitName } )
          
          PilotUnit = UNIT:Register( UnitName )
          
          return true
        end
        
        world.searchObjects( { Object.Category.UNIT, Object.Category.STATIC, Object.Category.SCENERY, Object.Category.WEAPON }, SphereSearch, FindEjectedPilot )

        self.CSAR[CSARName] = {} 
        self.CSAR[CSARName].PilotUnit = PlaneUnit
        self.CSAR[CSARName].Task = nil
  
      end
    )
    
    
    return self
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
  -- @param DeployZone A deploy zone.
  -- @return #TASK_CARGO_DISPATCHER
  function TASK_CARGO_DISPATCHER:SetCSARDeployZone( CSARDeployZone )

    self.CSARDeployZones = { CSARDeployZone }
  
    return self
  end
  
  
  --- Define the deploy zones for the CSAR tasks.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @param DeployZones A list of the deploy zones.
  -- @return #TASK_CARGO_DISPATCHER
  function TASK_CARGO_DISPATCHER:SetCSARDeployZones( CSARDeployZones )

    self.CSARDeployZones = CSARDeployZones
  
    return self
  end
  
  
  --- Evaluates of a CSAR task needs to be started.
  -- @param #TASK_CARGO_DISPATCHER self
  -- @return Set#SET_CARGO The SetCargo to be rescued.
  -- @return #nil If there is no CSAR task required.
  function TASK_CARGO_DISPATCHER:EvaluateCSAR( CSARUnit )
  
    local CSARCargo = CARGO_UNIT:New( CSARUnit, "Pilot", CSARUnit:GetName(), 80, 1500, 10 )
    
    local SetCargo = SET_CARGO:New()
    SetCargo:AddCargosByName( CSARUnit:GetName() )
    
    SetCargo:Flush(self)
    
    return SetCargo
    
  end

  

  --- Assigns tasks to the @{Set#SET_GROUP}.
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
      for CSARID, CSARData in pairs( self.CSAR ) do
      
        if CSARData.Task then
        else
          -- New CSAR Task
          local SetCargo = self:EvaluateCSAR( CSARData.PilotUnit )
          local CSARTask = TASK_CARGO_CSAR:New( Mission, self.SetGroup, "Rescue Pilot", SetCargo )
          CSARTask:SetDeployZones( self.CSARDeployZones or {} )
          Mission:AddTask( CSARTask )
          TaskReport:Add( CSARTask:GetName() )
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
