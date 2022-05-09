--- **Tasking** -- Dynamically allocates A2G tasks to human players, based on detected ground targets through reconnaissance. 
-- 
-- **Features:**
-- 
--   * Dynamically assign tasks to human players based on detected targets.
--   * Dynamically change the tasks as the tactical situation evolves during the mission.
--   * Dynamically assign (CAS) Close Air Support tasks for human players.
--   * Dynamically assign (BAI) Battlefield Air Interdiction tasks for human players.
--   * Dynamically assign (SEAD) Supression of Enemy Air Defense tasks for human players to eliminate G2A missile threats.
--   * Define and use an EWR (Early Warning Radar) network.
--   * Define different ranges to engage upon intruders.
--   * Keep task achievements.
--   * Score task achievements.-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Tasking.Task_A2G_Dispatcher
-- @image Task_A2G_Dispatcher.JPG

do -- TASK_A2G_DISPATCHER

  --- TASK\_A2G\_DISPATCHER class.
  -- @type TASK_A2G_DISPATCHER
  -- @field Core.Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Functional.Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
  -- @field Tasking.Mission#MISSION Mission
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER

  --- Orchestrates dynamic **A2G Task Dispatching** based on the detection results of a linked @{Detection} object.
  -- 
  -- It uses the Tasking System within the MOOSE framework, which is a multi-player Tasking Orchestration system.
  -- It provides a truly dynamic battle environment for pilots and ground commanders to engage upon,
  -- in a true co-operation environment wherein **Multiple Teams** will collaborate in Missions to **achieve a common Mission Goal**.
  -- 
  -- The A2G dispatcher will dispatch the A2G Tasks to a defined  @{Set} of @{Wrapper.Group}s that will be manned by **Players**.   
  -- We call this the **AttackSet** of the A2G dispatcher. So, the Players are seated in the @{Client}s of the @{Wrapper.Group} @{Set}.
  -- 
  -- Depending on the actions of the enemy, preventive tasks are dispatched to the players to orchestrate the engagement in a true co-operation.
  -- The detection object will group the detected targets by its grouping method, and integrates a @{Set} of @{Wrapper.Group}s that are Recce vehicles or air units.
  -- We call this the **RecceSet** of the A2G dispatcher.
  -- 
  -- Depending on the current detected tactical situation, different task types will be dispatched to the Players seated in the AttackSet..
  -- There are currently 3 **Task Types** implemented in the TASK\_A2G\_DISPATCHER:
  -- 
  --   - **SEAD Task**: Dispatched when there are ground based Radar Emitters detected within an area.
  --   - **CAS Task**: Dispatched when there are no ground based Radar Emitters within the area, but there are friendly ground Units within 6 km from the enemy.
  --   - **BAI Task**: Dispatched when there are no ground based Radar Emitters within the area, and there aren't friendly ground Units within 6 km from the enemy.
  --
  -- # 0. Tactical Situations
  -- 
  -- This chapters provides some insights in the tactical situations when certain Task Types are created.
  -- The Task Types are depending on the enemy positions that were detected, and the current location of friendly units.
  -- 
  -- ![](..\Presentations\TASK_A2G_DISPATCHER\Dia3.JPG)
  -- 
  -- In the demonstration mission [TAD-A2G-000 - AREAS - Detection test], 
  -- the tactical situation is a demonstration how the A2G detection works.
  -- This example will be taken further in the explanation in the following chapters.
  -- 
  -- ![](..\Presentations\TASK_A2G_DISPATCHER\Dia4.JPG)
  -- 
  -- The red coalition are the players, the blue coalition is the enemy.
  -- 
  -- Red reconnaissance vehicles and airborne units are detecting the targets.
  -- We call this the RecceSet as explained above, which is a Set of Groups that
  -- have a group name starting with `Recce` (configured in the mission script).
  -- 
  -- Red attack units are responsible for executing the mission for the command center.
  -- We call this the AttackSet, which is a Set of Groups with a group name starting with `Attack` (configured in the mission script).
  -- These units are setup in this demonstration mission to be ground vehicles and airplanes.
  -- For demonstration purposes, the attack airplane is stationed on the ground to explain
  -- the messages and the menus properly.
  -- Further test missions demonstrate the A2G task dispatcher from within air.
  -- 
  -- Depending upon the detection results, the A2G dispatcher will create different tasks.
  -- 
  -- # 0.1. SEAD Task
  -- 
  -- A SEAD Task is dispatched when there are ground based Radar Emitters detected within an area.
  -- 
  -- ![](..\Presentations\TASK_A2G_DISPATCHER\Dia9.JPG)
  -- 
  --   - Once all Radar Emitting Units have been destroyed, the Task will convert into a BAI or CAS task!
  --   - A CAS and BAI task may be converted into a SEAD task, once a radar has been detected within the area!
  -- 
  -- # 0.2. CAS Task
  -- 
  -- A CAS Task is dispatched when there are no ground based Radar Emitters within the area, but there are friendly ground Units within 6 km from the enemy.
  -- 
  -- ![](..\Presentations\TASK_A2G_DISPATCHER\Dia10.JPG)
  -- 
  --   - After the detection of the CAS task, if the friendly Units are destroyed, the CAS task will convert into a BAI task!
  --   - Only ground Units are taken into account. Airborne units are ships are not considered friendlies that require Close Air Support.
  -- 
  -- # 0.3. BAI Task
  -- 
  -- A BAI Task is dispatched when there are no ground based Radar Emitters within the area, and there aren't friendly ground Units within 6 km from the enemy.
  -- 
  -- ![](..\Presentations\TASK_A2G_DISPATCHER\Dia11.JPG)
  --
  --   - A BAI task may be converted into a CAS task if friendly Ground Units approach within 6 km range!
  --
  -- # 1. Player Experience
  -- 
  -- The A2G dispatcher is residing under a @{CommandCenter}, which is orchestrating a @{Mission}.
  -- As a result, you'll find for DCS World missions that implement the A2G dispatcher a **Command Center Menu** and under this one or more **Mission Menus**.
  -- 
  -- For example, if there are 2 Command Centers (CC).
  -- Each CC is controlling a couple of Missions, the Radio Menu Structure could look like this:
  -- 
  --      Radio MENU Structure (F10. Other)
  -- 
  --      F1. Command Center [Gori]
  --        F1. Mission "Alpha (Primary)"
  --        F2. Mission "Beta (Secondary)"
  --        F3. Mission "Gamma (Tactical)"
  --      F1. Command Center [Lima]
  --        F1. Mission "Overlord (High)"
  -- 
  -- Command Center [Gori] is controlling Mission "Alpha", "Beta", "Gamma".  Alpha is the Primary mission, Beta the Secondary and there is a Tacical mission Gamma.
  -- Command Center [Lima] is controlling Missions "Overlord", which needs to be executed with High priority.
  --
  -- ## 1.1. Mission Menu (Under the Command Center Menu)
  -- 
  -- The Mission Menu controls the information of the mission, including the:
  -- 
  --   - **Mission Briefing**: A briefing of the Mission in text, which will be shown as a message.
  --   - **Mark Task Locations**: A summary of each Task will be shown on the map as a marker.
  --   - **Create Task Reports**: A menu to create various reports of the current tasks dispatched by the A2G dispatcher.
  --   - **Create Mission Reports**: A menu to create various reports on the current mission.
  -- 
  -- For CC [Lima], Mission "Overlord", the menu structure could look like this:
  -- 
  --      Radio MENU Structure (F10. Other)
  -- 
  --      F1. Command Center [Lima]
  --        F1. Mission "Overlord"
  --          F1. Mission Briefing
  --          F2. Mark Task Locations on Map
  --          F3. Task Reports
  --          F4. Mission Reports
  --          
  -- ![](..\Presentations\TASK_A2G_DISPATCHER\Dia5.JPG)
  --   
  -- ### 1.1.1. Mission Briefing Menu
  -- 
  -- The Mission Briefing Menu will show in text a summary description of the overall mission objectives and expectations.
  -- Note that the Mission Briefing is not the briefing of a specific task, but rather provides an overall strategy and tactical situation, 
  -- and explains the mission goals. 
  -- 
  -- 
  -- ### 1.1.2. Mark Task Locations Menu
  -- 
  -- The Mark Task Locations Menu will mark the location indications of the Tasks on the map, if this intelligence is known by the Command Center.
  -- For A2G tasks this information will always be know, but it can be that for other tasks a location intelligence will be less relevant.
  -- Note that each Planned task and each Engaged task will be marked. Completed, Failed and Cancelled tasks are not marked.
  -- Depending on the task type, a summary information is shown to bring to the player the relevant information for situational awareness.
  -- 
  -- ### 1.1.3. Task Reports Menu
  -- 
  -- The Task Reports Menu is a sub menu, that allows to create various reports:
  -- 
  --   - **Tasks Summary**: This report will list all the Tasks that are or were active within the mission, indicating its status.
  --   - **Planned Tasks**: This report will list all the Tasks that are in status Planned, which are Tasks not assigned to any player, and are ready to be executed.
  --   - **Assigned Tasks**: This report will list all the Tasks that are in status Assigned, which are Tasks assigned to (a) player(s) and are currently executed.
  --   - **Successful Tasks**: This report will list all the Tasks that are in status Success, which are Tasks executed by (a) player(s) and are completed successfully.
  --   - **Failed Tasks**: This report will list all the Tasks that are in status Success, which are Tasks executed by (a) player(s) and that have failed.
  --   
  -- The information shown of the tasks will vary according the underlying task type, but are self explanatory.
  --
  -- For CC [Gori], Mission "Alpha", the Task Reports menu structure could look like this:
  -- 
  --      Radio MENU Structure (F10. Other)
  -- 
  --      F1. Command Center [Gori]
  --        F1. Mission "Alpha"
  --          F1. Mission Briefing
  --          F2. Mark Task Locations on Map
  --          F3. Task Reports
  --            F1. Tasks Summary
  --            F2. Planned Tasks
  --            F3. Assigned Tasks
  --            F4. Successful Tasks
  --            F5. Failed Tasks
  --          F4. Mission Reports
  --   
  -- Note that these reports provide an "overview" of the tasks. Detailed information of the task can be retrieved using the Detailed Report on the Task Menu.
  -- (See later).
  -- 
  -- ### 1.1.4. Mission Reports Menu
  -- 
  -- The Mission Reports Menu is a sub menu, that provides options to retrieve further information on the current Mission:
  -- 
  --   - **Report Mission Progress**: Shows the progress of the current Mission. Each Task has a %-tage of completion.
  --   - **Report Players per Task**: Show which players are engaged on which Task within the Mission.
  -- 
  -- For CC |Gori|, Mission "Alpha", the Mission Reports menu structure could look like this:
  -- 
  --      Radio MENU Structure (F10. Other)
  -- 
  --      F1. Command Center [Gori]
  --        F1. Mission "Alpha"
  --          F1. Mission Briefing
  --          F2. Mark Task Locations on Map
  --          F3. Task Reports
  --          F4. Mission Reports
  --            F1. Report Mission Progress
  --            F2. Report Players per Task
  -- 
  --   
  -- ## 1.2. Task Management Menus
  --   
  -- Very important to remember is: **Multiple Players can be assigned to the same Task, but from the player perspective, the Player can only be assigned to one Task per Mission at the same time!**
  -- Consider this like the two major modes in which a player can be in. He can be free of tasks or he can be assigned to a Task.
  -- Depending on whether a Task has been Planned or Assigned to a Player (Group), 
  -- **the Mission Menu will contain extra Menus to control specific Tasks.**
  -- 
  -- #### 1.2.1. Join a Planned Task
  -- 
  -- If the Player has not yet been assigned to a Task within the Mission, the Mission Menu will contain additionally a:
  -- 
  --   - Join Planned Task Menu: This menu structure allows the player to join a planned task (a Task with status Planned).
  --   
  -- For CC |Gori|, Mission "Alpha", the menu structure could look like this:
  -- 
  --      Radio MENU Structure (F10. Other)
  -- 
  --      F1. Command Center [Gori]
  --        F1. Mission "Alpha"
  --          F1. Mission Briefing
  --          F2. Mark Task Locations on Map
  --          F3. Task Reports
  --          F4. Mission Reports
  --          F5. Join Planned Task
  -- 
  -- **The F5. Join Planned Task allows the player to join a Planned Task and take an engagement in the running Mission.**
  -- 
  -- #### 1.2.2. Manage an Assigned Task 
  -- 
  -- If the Player has been assigned to one Task within the Mission, the Mission Menu will contain an extra:
  -- 
  --   - Assigned Task __TaskName__ Menu: This menu structure allows the player to take actions on the currently engaged task.
  --   
  -- In this example, the Group currently seated by the player is not assigned yet to a Task.
  -- The Player has the option to assign itself to a Planned Task using menu option F5 under the Mission Menu "Alpha".
  -- 
  -- This would be an example menu structure, 
  -- for CC |Gori|, Mission "Alpha", when a player would have joined Task CAS.001:
  -- 
  --      Radio MENU Structure (F10. Other)
  -- 
  --      F1. Command Center [Gori]
  --        F1. Mission "Alpha"
  --          F1. Mission Briefing
  --          F2. Mark Task Locations on Map
  --          F3. Task Reports
  --          F4. Mission Reports
  --          F5. Assigned Task CAS.001
  -- 
  -- **The F5. Assigned Task __TaskName__ allows the player to control the current Assigned Task and take further actions.**
  -- 
  -- 
  -- ## 1.3. Join Planned Task Menu
  -- 
  -- The Join Planned Task Menu contains the different Planned A2G Tasks **in a structured Menu Hierarchy**.
  -- The Menu Hierarchy is structuring the Tasks per **Task Type**, and then by **Task Name (ID)**.  
  --     
  -- For example, for CC [Gori], Mission "Alpha", 
  -- if a Mission "ALpha" contains 5 Planned Tasks, which would be:
  -- 
  --   - 2 CAS Tasks 
  --   - 1 BAI Task
  --   - 2 SEAD Tasks
  --   
  -- the Join Planned Task Menu Hierarchy could look like this:
  -- 
  --      Radio MENU Structure (F10. Other)
  -- 
  --      F1. Command Center [Gori]
  --        F1. Mission "Alpha"
  --          F1. Mission Briefing
  --          F2. Mark Task Locations on Map
  --          F3. Task Reports
  --          F4. Mission Reports
  --          F5. Join Planned Task
  --            F2. BAI
  --              F1. BAI.001
  --            F1. CAS
  --              F1. CAS.002
  --            F3. SEAD
  --              F1. SEAD.003
  --              F2. SEAD.004
  --              F3. SEAD.005
  --          
  -- An example from within a running simulation:
  -- 
  -- ![](..\Presentations\TASK_A2G_DISPATCHER\Dia6.JPG)
  --          
  -- Each Task Type Menu would have a list of the Task Menus underneath. 
  -- Each Task Menu (eg. `CAS.001`) has a **detailed Task Menu structure to control the specific task**!
  --
  -- ### 1.3.1. Planned Task Menu
  --
  -- Each Planned Task Menu will allow for the following actions:
  -- 
  --   - Report Task Details: Provides a detailed report on the Planned Task.
  --   - Mark Task Location on Map: Mark the approximate location of the Task on the Map, if relevant.
  --   - Join Task: Join the Task. This is THE menu option to let a Player join the Task, and to engage within the Mission.
  --   
  -- The Join Planned Task Menu could look like this for for CC |Gori|, Mission "Alpha": 
  -- 
  --      Radio MENU Structure (F10. Other)
  -- 
  --      F1. Command Center |Gori|
  --        F1. Mission "Alpha"
  --          F1. Mission Briefing
  --          F2. Mark Task Locations on Map
  --          F3. Task Reports
  --          F4. Mission Reports
  --          F5. Join Planned Task
  --            F1. CAS
  --              F1. CAS.001
  --                F1. Report Task Details
  --                F2. Mark Task Location on Map
  --                F3. Join Task
  -- 
  -- **The Join Task is THE menu option to let a Player join the Task, and to engage within the Mission.**
  -- 
  -- 
  -- ## 1.4. Assigned Task Menu
  -- 
  -- The Assigned Task Menu allows to control the **current assigned task** within the Mission.
  -- 
  -- Depending on the Type of Task, the following menu options will be available:
  -- 
  --   - **Report Task Details**: Provides a detailed report on the Planned Task.
  --   - **Mark Task Location on Map**: Mark the approximate location of the Task on the Map, if relevant.
  --   - **Abort Task: Abort the current assigned Task:** This menu option lets the player abort the Task.
  -- 
  -- For example, for CC |Gori|, Mission "Alpha", the Assigned Menu could be:
  -- 
  --      F1. Command Center |Gori|
  --        F1. Mission "Alpha"
  --          F1. Mission Briefing
  --          F2. Mark Task Locations on Map
  --          F3. Task Reports
  --          F4. Mission Reports
  --          F5. Assigned Task
  --            F1. Report Task Details
  --            F2. Mark Task Location on Map
  --            F3. Abort Task
  --            
  -- Task abortion will result in the Task to be Cancelled, and the Task **may** be **Replanned**.
  -- However, this will depend on the setup of each Mission. 
  -- 
  -- ## 1.5. Messages
  -- 
  -- During game play, different messages are displayed.
  -- These messages provide an update of the achievements made, and the state wherein the task is.
  -- 
  -- The various reports can be used also to retrieve the current status of the mission and its tasks.
  -- 
  -- ![](..\Presentations\TASK_A2G_DISPATCHER\Dia7.JPG)
  -- 
  -- The @{Settings} menu provides additional options to control the timing of the messages.
  -- There are:
  -- 
  --   - Status messages, which are quick status updates. The settings menu allows to switch off these messages.
  --   - Information messages, which are shown a bit longer, as they contain important information.
  --   - Summary reports, which are quick reports showing a high level summary.
  --   - Overview reports, which are providing the essential information. It provides an overview of a greater thing, and may take a bit of time to read.
  --   - Detailed reports, which provide with very detailed information. It takes a bit longer to read those reports, so the display of those could be a bit longer.
  -- 
  -- # 2. TASK\_A2G\_DISPATCHER constructor
  -- 
  -- The @{#TASK_A2G_DISPATCHER.New}() method creates a new TASK\_A2G\_DISPATCHER instance.
  --
  -- # 3. Usage
  --
  -- To use the TASK\_A2G\_DISPATCHER class, you need:
  -- 
  --   - A @{CommandCenter} object. The master communication channel.
  --   - A @{Mission} object. Each task belongs to a Mission.
  --   - A @{Detection} object. There are several detection grouping methods to choose from.
  --   - A @{Task_A2G_Dispatcher} object. The master A2G task dispatcher.
  --   - A @{Set} of @{Wrapper.Group} objects that will detect the emeny, the RecceSet. This is attached to the @{Detection} object.
  --   - A @{Set} ob @{Wrapper.Group} objects that will attack the enemy, the AttackSet. This is attached to the @{Task_A2G_Dispatcher} object.
  -- 
  -- Below an example mission declaration that is defines a Task A2G Dispatcher object.   
  --
  --     -- Declare the Command Center 
  --     local HQ = GROUP
  --       :FindByName( "HQ", "Bravo HQ" )
  --
  --     local CommandCenter = COMMANDCENTER
  --       :New( HQ, "Lima" )
  --      
  --     -- Declare the Mission for the Command Center.
  --     local Mission = MISSION
  --       :New( CommandCenter, "Overlord", "High", "Attack Detect Mission Briefing", coalition.side.RED )
  --    
  --     -- Define the RecceSet that will detect the enemy.
  --     local RecceSet = SET_GROUP
  --       :New()
  --       :FilterPrefixes( "FAC" )
  --       :FilterCoalitions("red")
  --       :FilterStart()
  --    
  --     -- Setup the detection. We use DETECTION_AREAS to detect and group the enemies within areas of 3 km radius.
  --     local DetectionAreas = DETECTION_AREAS
  --       :New( RecceSet, 3000 )  -- The RecceSet will detect the enemies.
  --    
  --     -- Setup the AttackSet, which is a SET_GROUP.
  --     -- The SET_GROUP is a dynamic collection of GROUP objects.  
  --     local AttackSet = SET_GROUP
  --       :New()  -- Create the SET_GROUP object.
  --       :FilterCoalitions( "red" ) -- Only incorporate the RED coalitions.
  --       :FilterPrefixes( "Attack" ) -- Only incorporate groups that start with the name Attack.
  --       :FilterStart() -- Enable the dynamic filtering. From this moment the AttackSet will contain all groups that are red and start with the name Attack.
  --      
  --     -- Now we have everything to setup the main A2G TaskDispatcher.
  --     TaskDispatcher = TASK_A2G_DISPATCHER
  --       :New( Mission, AttackSet, DetectionAreas ) -- We assign the TaskDispatcher under Mission. The AttackSet will engage the enemy and will recieve the dispatched Tasks. The DetectionAreas will report any detected enemies to the TaskDispatcher.
  -- 
  --   
  --
  -- @field #TASK_A2G_DISPATCHER
  TASK_A2G_DISPATCHER = {
    ClassName = "TASK_A2G_DISPATCHER",
    Mission = nil,
    Detection = nil,
    Tasks = {},
  }
  
  
  --- TASK_A2G_DISPATCHER constructor.
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Tasking.Mission#MISSION Mission The mission for which the task dispatching is done.
  -- @param Core.Set#SET_GROUP SetGroup The set of groups that can join the tasks within the mission.
  -- @param Functional.Detection#DETECTION_BASE Detection The detection results that are used to dynamically assign new tasks to human players.
  -- @return #TASK_A2G_DISPATCHER self
  function TASK_A2G_DISPATCHER:New( Mission, SetGroup, Detection )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #TASK_A2G_DISPATCHER
    
    self.Detection = Detection
    self.Mission = Mission
    self.FlashNewTask = true --set to false to suppress flash messages
    
    self.Detection:FilterCategories( { Unit.Category.GROUND_UNIT } )
    
    self:AddTransition( "Started", "Assign", "Started" )
    
    --- OnAfter Transition Handler for Event Assign.
    -- @function [parent=#TASK_A2G_DISPATCHER] OnAfterAssign
    -- @param #TASK_A2G_DISPATCHER self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @param Tasking.Task_A2G#TASK_A2G Task
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param #string PlayerName
    
    self:__Start( 5 )
    
    return self
  end
  
    --- Set flashing player messages on or off
  -- @param #TASK_A2G_DISPATCHER self
  -- @param #boolean onoff Set messages on (true) or off (false)
  function TASK_A2G_DISPATCHER:SetSendMessages( onoff )
      self.FlashNewTask = onoff
  end
  
  --- Creates a SEAD task when there are targets for it.
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_AREAS.DetectedItem DetectedItem
  -- @return Core.Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function TASK_A2G_DISPATCHER:EvaluateSEAD( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone

    -- Determine if the set has radar targets. If it does, construct a SEAD task.
    local RadarCount = DetectedSet:HasSEAD()

    if RadarCount > 0 then

      -- Here we're doing something advanced... We're copying the DetectedSet, but making a new Set only with SEADable Radar units in it.
      local TargetSetUnit = SET_UNIT:New()
      TargetSetUnit:SetDatabase( DetectedSet )
      TargetSetUnit:FilterHasSEAD()
      TargetSetUnit:FilterOnce() -- Filter but don't do any events!!! Elements are added manually upon each detection.
    
      return TargetSetUnit
    end
    
    return nil
  end

  --- Creates a CAS task when there are targets for it.
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_AREAS.DetectedItem DetectedItem
  -- @return Core.Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function TASK_A2G_DISPATCHER:EvaluateCAS( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone


    -- Determine if the set has ground units.
    -- There should be ground unit friendlies nearby. Airborne units are valid friendlies types.
    -- And there shouldn't be any radar.
    local GroundUnitCount = DetectedSet:HasGroundUnits()
    local FriendliesNearBy = self.Detection:IsFriendliesNearBy( DetectedItem, Unit.Category.GROUND_UNIT ) -- Are there friendlies nearby of type GROUND_UNIT?
    local RadarCount = DetectedSet:HasSEAD()

    if RadarCount == 0 and GroundUnitCount > 0 and FriendliesNearBy == true then

      -- Copy the Set
      local TargetSetUnit = SET_UNIT:New()
      TargetSetUnit:SetDatabase( DetectedSet )
      TargetSetUnit:FilterOnce() -- Filter but don't do any events!!! Elements are added manually upon each detection.
      
      return TargetSetUnit
    end
  
    return nil
  end
  
  --- Creates a BAI task when there are targets for it.
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_AREAS.DetectedItem DetectedItem
  -- @return Core.Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function TASK_A2G_DISPATCHER:EvaluateBAI( DetectedItem, FriendlyCoalition )
    self:F( { DetectedItem.ItemID } )
  
    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone


    -- Determine if the set has ground units.
    -- There shouldn't be any ground unit friendlies nearby.
    -- And there shouldn't be any radar.
    local GroundUnitCount = DetectedSet:HasGroundUnits()
    local FriendliesNearBy = self.Detection:IsFriendliesNearBy( DetectedItem, Unit.Category.GROUND_UNIT ) -- Are there friendlies nearby of type GROUND_UNIT?
    local RadarCount = DetectedSet:HasSEAD()

    if RadarCount == 0 and GroundUnitCount > 0 and FriendliesNearBy == false then

      -- Copy the Set
      local TargetSetUnit = SET_UNIT:New()
      TargetSetUnit:SetDatabase( DetectedSet )
      TargetSetUnit:FilterOnce() -- Filter but don't do any events!!! Elements are added manually upon each detection.
      
      return TargetSetUnit
    end
  
    return nil
  end
  
  
  function TASK_A2G_DISPATCHER:RemoveTask( TaskIndex )
    self.Mission:RemoveTask( self.Tasks[TaskIndex] )
    self.Tasks[TaskIndex] = nil
  end
  
  --- Evaluates the removal of the Task from the Mission.
  -- Can only occur when the DetectedItem is Changed AND the state of the Task is "Planned".
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Tasking.Task#TASK Task
  -- @param #boolean DetectedItemID
  -- @param #boolean DetectedItemChange
  -- @return Tasking.Task#TASK
  function TASK_A2G_DISPATCHER:EvaluateRemoveTask( Mission, Task, TaskIndex, DetectedItemChanged )
    
    if Task then
      if ( Task:IsStatePlanned() and DetectedItemChanged == true ) or Task:IsStateCancelled() then
        --self:F( "Removing Tasking: " .. Task:GetTaskName() )
        self:RemoveTask( TaskIndex )
      end
    end
    
    return Task
  end
  

  --- Assigns tasks in relation to the detected items to the @{Core.Set#SET_GROUP}.
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Functional.Detection#DETECTION_BASE} derived object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function TASK_A2G_DISPATCHER:ProcessDetected( Detection )
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
          local DetectedItem = Detection:GetDetectedItemByIndex( TaskIndex )
          if not DetectedItem then
            local TaskText = Task:GetName()
            for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
              if self.FlashNewTask then
                Mission:GetCommandCenter():MessageToGroup( string.format( "Obsolete A2G task %s for %s removed.", TaskText, Mission:GetShortText() ), TaskGroup )
              end
            end
            Task = self:RemoveTask( TaskIndex )
          end
        end
      end

      --- First we need to  the detected targets.
      for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
      
        local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
        local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
        local DetectedZone = DetectedItem.Zone
        --self:F( { "Targets in DetectedItem", DetectedItem.ItemID, DetectedSet:Count(), tostring( DetectedItem ) } )
        --DetectedSet:Flush( self )
        
        local DetectedItemID = DetectedItem.ID
        local TaskIndex = DetectedItem.Index
        local DetectedItemChanged = DetectedItem.Changed
        
        self:F( { DetectedItemChanged = DetectedItemChanged, DetectedItemID = DetectedItemID, TaskIndex = TaskIndex } )
        
        local Task = self.Tasks[TaskIndex] -- Tasking.Task_A2G#TASK_A2G
        
        if Task then
          -- If there is a Task and the task was assigned, then we check if the task was changed ... If it was, we need to reevaluate the targets.
          if Task:IsStateAssigned() then
            if DetectedItemChanged == true then -- The detection has changed, thus a new TargetSet is to be evaluated and set
              local TargetsReport = REPORT:New()
              local TargetSetUnit = self:EvaluateSEAD( DetectedItem ) -- Returns a SetUnit if there are targets to be SEADed...
              if TargetSetUnit then
                if Task:IsInstanceOf( TASK_A2G_SEAD ) then
                  Task:SetTargetSetUnit( TargetSetUnit )
                  Task:SetDetection( Detection, DetectedItem )
                  Task:UpdateTaskInfo( DetectedItem )
                  TargetsReport:Add( Detection:GetChangeText( DetectedItem )  )
                else
                  Task:Cancel()
                end
              else
                local TargetSetUnit = self:EvaluateCAS( DetectedItem ) -- Returns a SetUnit if there are targets to be CASed...
                if TargetSetUnit then
                  if Task:IsInstanceOf( TASK_A2G_CAS ) then
                    Task:SetTargetSetUnit( TargetSetUnit )
                    Task:SetDetection( Detection, DetectedItem )
                    Task:UpdateTaskInfo( DetectedItem )
                    TargetsReport:Add( Detection:GetChangeText( DetectedItem ) )
                  else
                    Task:Cancel()
                    Task = self:RemoveTask( TaskIndex )
                  end
                else
                  local TargetSetUnit = self:EvaluateBAI( DetectedItem ) -- Returns a SetUnit if there are targets to be BAIed...
                  if TargetSetUnit then
                    if Task:IsInstanceOf( TASK_A2G_BAI ) then
                      Task:SetTargetSetUnit( TargetSetUnit )
                      Task:SetDetection( Detection, DetectedItem )
                      Task:UpdateTaskInfo( DetectedItem )
                      TargetsReport:Add( Detection:GetChangeText( DetectedItem ) )
                    else
                      Task:Cancel()
                      Task = self:RemoveTask( TaskIndex )
                    end
                  end
                end
              end
              
              -- Now we send to each group the changes, if any.
              for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
                local TargetsText = TargetsReport:Text(", ")
                if ( Mission:IsGroupAssigned(TaskGroup) ) and TargetsText ~= "" and self.FlashNewTask then
                  Mission:GetCommandCenter():MessageToGroup( string.format( "Task %s has change of targets:\n %s", Task:GetName(), TargetsText ), TaskGroup )
                end
              end
            end
          end
        end
          
        if Task then
          if Task:IsStatePlanned() then
            if DetectedItemChanged == true then -- The detection has changed, thus a new TargetSet is to be evaluated and set
              if Task:IsInstanceOf( TASK_A2G_SEAD ) then
                local TargetSetUnit = self:EvaluateSEAD( DetectedItem ) -- Returns a SetUnit if there are targets to be SEADed...
                if TargetSetUnit then
                  Task:SetTargetSetUnit( TargetSetUnit )
                  Task:SetDetection( Detection, DetectedItem )
                  Task:UpdateTaskInfo( DetectedItem )
                else
                  Task:Cancel()
                  Task = self:RemoveTask( TaskIndex )
                end
              else
                if Task:IsInstanceOf( TASK_A2G_CAS ) then
                  local TargetSetUnit = self:EvaluateCAS( DetectedItem ) -- Returns a SetUnit if there are targets to be CASed...
                  if TargetSetUnit then
                    Task:SetTargetSetUnit( TargetSetUnit )
                    Task:SetDetection( Detection, DetectedItem )
                    Task:UpdateTaskInfo( DetectedItem )
                  else
                    Task:Cancel()
                    Task = self:RemoveTask( TaskIndex )
                  end
                else
                  if Task:IsInstanceOf( TASK_A2G_BAI ) then
                    local TargetSetUnit = self:EvaluateBAI( DetectedItem ) -- Returns a SetUnit if there are targets to be BAIed...
                    if TargetSetUnit then
                      Task:SetTargetSetUnit( TargetSetUnit )
                      Task:SetDetection( Detection, DetectedItem )
                      Task:UpdateTaskInfo( DetectedItem )
                    else
                      Task:Cancel()
                      Task = self:RemoveTask( TaskIndex )
                    end
                  else
                    Task:Cancel()
                    Task = self:RemoveTask( TaskIndex )
                  end
                end
              end
            end
          end
        end

        -- Evaluate SEAD
        if not Task then
          local TargetSetUnit = self:EvaluateSEAD( DetectedItem ) -- Returns a SetUnit if there are targets to be SEADed...
          if TargetSetUnit then
            Task = TASK_A2G_SEAD:New( Mission, self.SetGroup, string.format( "SEAD.%03d", DetectedItemID ), TargetSetUnit )
            DetectedItem.DesignateMenuName = string.format( "SEAD.%03d", DetectedItemID ) --inject a name for DESIGNATE, if using same DETECTION object
            Task:SetDetection( Detection, DetectedItem )
          end

          -- Evaluate CAS
          if not Task then
            local TargetSetUnit = self:EvaluateCAS( DetectedItem ) -- Returns a SetUnit if there are targets to be CASed...
            if TargetSetUnit then
              Task = TASK_A2G_CAS:New( Mission, self.SetGroup, string.format( "CAS.%03d", DetectedItemID ), TargetSetUnit )
              DetectedItem.DesignateMenuName = string.format( "CAS.%03d", DetectedItemID ) --inject a name for DESIGNATE, if using same DETECTION object
              Task:SetDetection( Detection, DetectedItem )
            end

            -- Evaluate BAI
            if not Task then
              local TargetSetUnit = self:EvaluateBAI( DetectedItem, self.Mission:GetCommandCenter():GetPositionable():GetCoalition() ) -- Returns a SetUnit if there are targets to be BAIed...
              if TargetSetUnit then
                Task = TASK_A2G_BAI:New( Mission, self.SetGroup, string.format( "BAI.%03d", DetectedItemID ), TargetSetUnit )
                DetectedItem.DesignateMenuName = string.format( "BAI.%03d", DetectedItemID ) --inject a name for DESIGNATE, if using same DETECTION object
                Task:SetDetection( Detection, DetectedItem )
              end
            end
          end
          
          if Task then
            self.Tasks[TaskIndex] = Task
            Task:SetTargetZone( DetectedZone )
            Task:SetDispatcher( self )
            Task:UpdateTaskInfo( DetectedItem )
            Mission:AddTask( Task )
            
            function Task.OnEnterSuccess( Task, From, Event, To )
              self:Success( Task )
            end

            function Task.OnEnterCancelled( Task, From, Event, To )
              self:Cancelled( Task )
            end
            
            function Task.OnEnterFailed( Task, From, Event, To )
              self:Failed( Task )
            end

            function Task.OnEnterAborted( Task, From, Event, To )
              self:Aborted( Task )
            end
            
    
            TaskReport:Add( Task:GetName() )
          else
            self:F("This should not happen")
          end
        end

  
        -- OK, so the tasking has been done, now delete the changes reported for the area.
        Detection:AcceptChanges( DetectedItem )
      end
      
      -- TODO set menus using the HQ coordinator
      Mission:GetCommandCenter():SetMenu()
      
      local TaskText = TaskReport:Text(", ")
      for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
        if ( not Mission:IsGroupAssigned(TaskGroup) ) and TaskText ~= "" and self.FlashNewTask then
          Mission:GetCommandCenter():MessageToGroup( string.format( "%s has tasks %s. Subscribe to a task using the radio menu.", Mission:GetShortText(), TaskText ), TaskGroup )
        end
      end
      
    end
    
    return true
  end

end
