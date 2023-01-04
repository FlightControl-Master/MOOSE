--- **Tasking** - Dynamically allocates A2A tasks to human players, based on detected airborne targets through an EWR network.
--
-- **Features:**
--
--   * Dynamically assign tasks to human players based on detected targets.
--   * Dynamically change the tasks as the tactical situation evolves during the mission.
--   * Dynamically assign (CAP) Control Air Patrols tasks for human players to perform CAP.
--   * Dynamically assign (GCI) Ground Control Intercept tasks for human players to perform GCI.
--   * Dynamically assign Engage tasks for human players to engage on close-by airborne bogeys.
--   * Define and use an EWR (Early Warning Radar) network.
--   * Define different ranges to engage upon intruders.
--   * Keep task achievements.
--   * Score task achievements.
--
-- ===
--
-- ### Author: **FlightControl**
--
-- ### Contributions:
--
-- ===
--
-- @module Tasking.Task_A2A_Dispatcher
-- @image Task_A2A_Dispatcher.JPG

do -- TASK_A2A_DISPATCHER

  --- TASK_A2A_DISPATCHER class.
  -- @type TASK_A2A_DISPATCHER
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER

  --- Orchestrates the dynamic dispatching of tasks upon groups of detected units determined a @{Core.Set} of EWR installation groups.
  --
  -- ![Banner Image](..\Presentations\TASK_A2A_DISPATCHER\Dia3.JPG)
  --
  -- The EWR will detect units, will group them, and will dispatch @{Tasking.Task}s to groups. Depending on the type of target detected, different tasks will be dispatched.
  -- Find a summary below describing for which situation a task type is created:
  --
  -- ![Banner Image](..\Presentations\TASK_A2A_DISPATCHER\Dia9.JPG)
  --
  --   * **INTERCEPT Task**: Is created when the target is known, is detected and within a danger zone, and there is no friendly airborne in range.
  --   * **SWEEP Task**: Is created when the target is unknown, was detected and the last position is only known, and within a danger zone, and there is no friendly airborne in range.
  --   * **ENGAGE Task**: Is created when the target is known, is detected and within a danger zone, and there is a friendly airborne in range, that will receive this task.
  --
  -- ## 1. TASK\_A2A\_DISPATCHER constructor:
  --
  -- The @{#TASK_A2A_DISPATCHER.New}() method creates a new TASK\_A2A\_DISPATCHER instance.
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
  -- ![Banner Image](..\Presentations\TASK_A2A_DISPATCHER\Dia6.JPG)
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
  -- ![Banner Image](..\Presentations\TASK_A2A_DISPATCHER\Dia5.JPG)
  --
  -- Typically EWR networks are setup using 55G6 EWR, 1L13 EWR, Hawk sr and Patriot str ground based radar units. 
  -- These radars have different ranges and 55G6 EWR and 1L13 EWR radars are Eastern Bloc units (eg Russia, Ukraine, Georgia) while the Hawk and Patriot radars are Western (eg US).
  -- Additionally, ANY other radar capable unit can be part of the EWR network! Also AWACS airborne units, planes, helicopters can help to detect targets, as long as they have radar.
  -- The position of these units is very important as they need to provide enough coverage 
  -- to pick up enemy aircraft as they approach so that CAP and GCI flights can be tasked to intercept them.
  --
  -- ![Banner Image](..\Presentations\TASK_A2A_DISPATCHER\Dia7.JPG)
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
  --     A2ADispatcher = TASK_A2A_DISPATCHER:New( Mission, AttackGroups, EWRDetection )
  --
  -- The above example creates a SET_GROUP instance, and stores this in the variable (object) **EWRSet**.
  -- **EWRSet** is then being configured to filter all active groups with a group name starting with **EWR** to be included in the Set.
  -- **EWRSet** is then being ordered to start the dynamic filtering. Note that any destroy or new spawn of a group with the above names will be removed or added to the Set.
  -- Then a new **EWRDetection** object is created from the class DETECTION_AREAS. A grouping radius of 6000 is chosen, which is 6 km.
  -- The **EWRDetection** object is then passed to the @{#TASK_A2A_DISPATCHER.New}() method to indicate the EWR network configuration and setup the A2A tasking and detection mechanism.
  --
  -- ### 2. Define the detected **target grouping radius**:
  --
  -- ![Banner Image](..\Presentations\TASK_A2A_DISPATCHER\Dia8.JPG)
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
  -- ![Banner Image](..\Presentations\TASK_A2A_DISPATCHER\Dia11.JPG)
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
  -- The TASK\_A2A\_DISPATCHER is a state machine. It triggers the event Assign when a new player joins a @{Tasking.Task} dispatched by the TASK\_A2A\_DISPATCHER.
  -- An _event handler_ can be defined to catch the **Assign** event, and add **additional processing** to set _scoring_ and to _define messages_,
  -- when the player reaches certain achievements in the task.
  --
  -- The prototype to handle the **Assign** event needs to be developed as follows:
  --
  --      TaskDispatcher = TASK_A2A_DISPATCHER:New( ... )
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
  -- @field #TASK_A2A_DISPATCHER
  TASK_A2A_DISPATCHER = {
    ClassName = "TASK_A2A_DISPATCHER",
    Mission = nil,
    Detection = nil,
    Tasks = {},
    SweepZones = {},
  }

  --- TASK_A2A_DISPATCHER constructor.
  -- @param #TASK_A2A_DISPATCHER self
  -- @param Tasking.Mission#MISSION Mission The mission for which the task dispatching is done.
  -- @param Core.Set#SET_GROUP SetGroup The set of groups that can join the tasks within the mission.
  -- @param Functional.Detection#DETECTION_BASE Detection The detection results that are used to dynamically assign new tasks to human players.
  -- @return #TASK_A2A_DISPATCHER self
  function TASK_A2A_DISPATCHER:New( Mission, SetGroup, Detection )

    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #TASK_A2A_DISPATCHER

    self.Detection = Detection
    self.Mission = Mission
    self.FlashNewTask = false

    -- TODO: Check detection through radar.
    self.Detection:FilterCategories( Unit.Category.AIRPLANE, Unit.Category.HELICOPTER )
    self.Detection:InitDetectRadar( true )
    self.Detection:SetRefreshTimeInterval( 30 )

    self:AddTransition( "Started", "Assign", "Started" )

    --- OnAfter Transition Handler for Event Assign.
    -- @function [parent=#TASK_A2A_DISPATCHER] OnAfterAssign
    -- @param #TASK_A2A_DISPATCHER self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @param Tasking.Task_A2A#TASK_A2A Task
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param #string PlayerName

    self:__Start( 5 )

    return self
  end

  --- Define the radius to when an ENGAGE task will be generated for any nearby by airborne friendlies, which are executing cap or returning from an intercept mission.
  -- So, if there is a target area detected and reported,
  -- then any friendlies that are airborne near this target area,
  -- will be commanded to (re-)engage that target when available (if no other tasks were commanded).
  -- An ENGAGE task will be created for those pilots.
  -- For example, if 100000 is given as a value, then any friendly that is airborne within 100km from the detected target, 
  -- will be considered to receive the command to engage that target area.
  -- You need to evaluate the value of this parameter carefully.
  -- If too small, more intercept missions may be triggered upon detected target areas.
  -- If too large, any airborne cap may not be able to reach the detected target area in time, because it is too far.
  -- @param #TASK_A2A_DISPATCHER self
  -- @param #number EngageRadius (Optional, Default = 100000) The radius to report friendlies near the target.
  -- @return #TASK_A2A_DISPATCHER
  -- @usage
  --
  --   -- Set 50km as the radius to engage any target by airborne friendlies.
  --   TaskA2ADispatcher:SetEngageRadius( 50000 )
  --
  --   -- Set 100km as the radius to engage any target by airborne friendlies.
  --   TaskA2ADispatcher:SetEngageRadius() -- 100000 is the default value.
  --
  function TASK_A2A_DISPATCHER:SetEngageRadius( EngageRadius )

    self.Detection:SetFriendliesRange( EngageRadius or 100000 )

    return self
  end

  --- Set flashing player messages on or off
  -- @param #TASK_A2A_DISPATCHER self
  -- @param #boolean onoff Set messages on (true) or off (false)
  function TASK_A2A_DISPATCHER:SetSendMessages( onoff )
    self.FlashNewTask = onoff
  end

  --- Creates an INTERCEPT task when there are targets for it.
  -- @param #TASK_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Core.Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function TASK_A2A_DISPATCHER:EvaluateINTERCEPT( DetectedItem )
    self:F( { DetectedItem.ItemID } )

    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone

    -- Check if there is at least one UNIT in the DetectedSet is visible.

    if DetectedItem.IsDetected == true then

      -- Here we're doing something advanced... We're copying the DetectedSet.
      local TargetSetUnit = SET_UNIT:New()
      TargetSetUnit:SetDatabase( DetectedSet )
      TargetSetUnit:FilterOnce() -- Filter but don't do any events!!! Elements are added manually upon each detection.

      return TargetSetUnit
    end

    return nil
  end

  --- Creates an SWEEP task when there are targets for it.
  -- @param #TASK_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Core.Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function TASK_A2A_DISPATCHER:EvaluateSWEEP( DetectedItem )
    self:F( { DetectedItem.ItemID } )

    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone -- TODO: This seems unused, remove?

    if DetectedItem.IsDetected == false then

      -- Here we're doing something advanced... We're copying the DetectedSet.
      local TargetSetUnit = SET_UNIT:New()
      TargetSetUnit:SetDatabase( DetectedSet )
      TargetSetUnit:FilterOnce() -- Filter but don't do any events!!! Elements are added manually upon each detection.

      return TargetSetUnit
    end

    return nil
  end

  --- Creates an ENGAGE task when there are human friendlies airborne near the targets.
  -- @param #TASK_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Core.Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function TASK_A2A_DISPATCHER:EvaluateENGAGE( DetectedItem )
    self:F( { DetectedItem.ItemID } )

    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone -- TODO: This seems unused, remove?

    local PlayersCount, PlayersReport = self:GetPlayerFriendliesNearBy( DetectedItem )

    -- Only allow ENGAGE when there are Players near the zone, and when the Area has detected items since the last run in a 60 seconds time zone.
    if PlayersCount > 0 and DetectedItem.IsDetected == true then

      -- Here we're doing something advanced... We're copying the DetectedSet.
      local TargetSetUnit = SET_UNIT:New()
      TargetSetUnit:SetDatabase( DetectedSet )
      TargetSetUnit:FilterOnce() -- Filter but don't do any events!!! Elements are added manually upon each detection.

      return TargetSetUnit
    end

    return nil
  end

  --- Evaluates the removal of the Task from the Mission.
  -- Can only occur when the DetectedItem is Changed AND the state of the Task is "Planned".
  -- @param #TASK_A2A_DISPATCHER self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Tasking.Task#TASK Task
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Functional.Detection#DETECTION_BASE} derived object.
  -- @param #boolean DetectedItemID
  -- @param #boolean DetectedItemChange
  -- @return Tasking.Task#TASK
  function TASK_A2A_DISPATCHER:EvaluateRemoveTask( Mission, Task, Detection, DetectedItem, DetectedItemIndex, DetectedItemChanged )

    if Task then

      if Task:IsStatePlanned() then
        local TaskName = Task:GetName()
        local TaskType = TaskName:match( "(%u+)%.%d+" )

        self:T2( { TaskType = TaskType } )

        local Remove = false

        local IsPlayers = Detection:IsPlayersNearBy( DetectedItem )
        if TaskType == "ENGAGE" then
          if IsPlayers == false then
            Remove = true
          end
        end

        if TaskType == "INTERCEPT" then
          if IsPlayers == true then
            Remove = true
          end
          if DetectedItem.IsDetected == false then
            Remove = true
          end
        end

        if TaskType == "SWEEP" then
          if DetectedItem.IsDetected == true then
            Remove = true
          end
        end

        local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
        -- DetectedSet:Flush( self )
        -- self:F( { DetectedSetCount = DetectedSet:Count() } )
        if DetectedSet:Count() == 0 then
          Remove = true
        end

        if DetectedItemChanged == true or Remove then
          Task = self:RemoveTask( DetectedItemIndex )
        end
      end
    end

    return Task
  end

  --- Calculates which friendlies are nearby the area
  -- @param #TASK_A2A_DISPATCHER self
  -- @param DetectedItem
  -- @return #number, Core.CommandCenter#REPORT
  function TASK_A2A_DISPATCHER:GetFriendliesNearBy( DetectedItem )

    local DetectedSet = DetectedItem.Set
    local FriendlyUnitsNearBy = self.Detection:GetFriendliesNearBy( DetectedItem, Unit.Category.AIRPLANE )

    local FriendlyTypes = {}
    local FriendliesCount = 0

    if FriendlyUnitsNearBy then
      local DetectedTreatLevel = DetectedSet:CalculateThreatLevelA2G()
      for FriendlyUnitName, FriendlyUnitData in pairs( FriendlyUnitsNearBy ) do
        local FriendlyUnit = FriendlyUnitData -- Wrapper.Unit#UNIT
        if FriendlyUnit:IsAirPlane() then
          local FriendlyUnitThreatLevel = FriendlyUnit:GetThreatLevel()
          FriendliesCount = FriendliesCount + 1
          local FriendlyType = FriendlyUnit:GetTypeName()
          FriendlyTypes[FriendlyType] = FriendlyTypes[FriendlyType] and (FriendlyTypes[FriendlyType] + 1) or 1
          if DetectedTreatLevel < FriendlyUnitThreatLevel + 2 then
          end
        end
      end

    end

    -- self:F( { FriendliesCount = FriendliesCount } )

    local FriendlyTypesReport = REPORT:New()

    if FriendliesCount > 0 then
      for FriendlyType, FriendlyTypeCount in pairs( FriendlyTypes ) do
        FriendlyTypesReport:Add( string.format( "%d of %s", FriendlyTypeCount, FriendlyType ) )
      end
    else
      FriendlyTypesReport:Add( "-" )
    end

    return FriendliesCount, FriendlyTypesReport
  end

  --- Calculates which HUMAN friendlies are nearby the area
  -- @param #TASK_A2A_DISPATCHER self
  -- @param DetectedItem
  -- @return #number, Core.CommandCenter#REPORT
  function TASK_A2A_DISPATCHER:GetPlayerFriendliesNearBy( DetectedItem )

    local DetectedSet = DetectedItem.Set
    local PlayersNearBy = self.Detection:GetPlayersNearBy( DetectedItem )

    local PlayerTypes = {}
    local PlayersCount = 0

    if PlayersNearBy then
      local DetectedTreatLevel = DetectedSet:CalculateThreatLevelA2G()
      for PlayerUnitName, PlayerUnitData in pairs( PlayersNearBy ) do
        local PlayerUnit = PlayerUnitData -- Wrapper.Unit#UNIT
        local PlayerName = PlayerUnit:GetPlayerName()
        -- self:F( { PlayerName = PlayerName, PlayerUnit = PlayerUnit } )
        if PlayerUnit:IsAirPlane() and PlayerName ~= nil then
          local FriendlyUnitThreatLevel = PlayerUnit:GetThreatLevel()
          PlayersCount = PlayersCount + 1
          local PlayerType = PlayerUnit:GetTypeName()
          PlayerTypes[PlayerName] = PlayerType
          if DetectedTreatLevel < FriendlyUnitThreatLevel + 2 then
          end
        end
      end

    end

    local PlayerTypesReport = REPORT:New()

    if PlayersCount > 0 then
      for PlayerName, PlayerType in pairs( PlayerTypes ) do
        PlayerTypesReport:Add( string.format( '"%s" in %s', PlayerName, PlayerType ) )
      end
    else
      PlayerTypesReport:Add( "-" )
    end

    return PlayersCount, PlayerTypesReport
  end

  function TASK_A2A_DISPATCHER:RemoveTask( TaskIndex )
    self.Mission:RemoveTask( self.Tasks[TaskIndex] )
    self.Tasks[TaskIndex] = nil
  end

  --- Assigns tasks in relation to the detected items to the @{Core.Set#SET_GROUP}.
  -- @param #TASK_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Functional.Detection#DETECTION_BASE} derived object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function TASK_A2A_DISPATCHER:ProcessDetected( Detection )
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
              Mission:GetCommandCenter():MessageToGroup( string.format( "Obsolete A2A task %s for %s removed.", TaskText, Mission:GetShortText() ), TaskGroup )
            end
            Task = self:RemoveTask( TaskIndex )
          end
        end
      end

      -- Now that all obsolete tasks are removed, loop through the detected targets.
      for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do

        local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
        local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
        local DetectedCount = DetectedSet:Count()
        local DetectedZone = DetectedItem.Zone
        -- self:F( { "Targets in DetectedItem", DetectedItem.ItemID, DetectedSet:Count(), tostring( DetectedItem ) } )
        -- DetectedSet:Flush( self )

        local DetectedID = DetectedItem.ID
        local TaskIndex = DetectedItem.Index
        local DetectedItemChanged = DetectedItem.Changed

        local Task = self.Tasks[TaskIndex]
        Task = self:EvaluateRemoveTask( Mission, Task, Detection, DetectedItem, TaskIndex, DetectedItemChanged ) -- Task will be removed if it is planned and changed.

        -- Evaluate INTERCEPT
        if not Task and DetectedCount > 0 then
          local TargetSetUnit = self:EvaluateENGAGE( DetectedItem ) -- Returns a SetUnit if there are targets to be INTERCEPTed...
          if TargetSetUnit then
            Task = TASK_A2A_ENGAGE:New( Mission, self.SetGroup, string.format( "ENGAGE.%03d", DetectedID ), TargetSetUnit )
            Task:SetDetection( Detection, DetectedItem )
            Task:UpdateTaskInfo( DetectedItem )
          else
            local TargetSetUnit = self:EvaluateINTERCEPT( DetectedItem ) -- Returns a SetUnit if there are targets to be INTERCEPTed...
            if TargetSetUnit then
              Task = TASK_A2A_INTERCEPT:New( Mission, self.SetGroup, string.format( "INTERCEPT.%03d", DetectedID ), TargetSetUnit )
              Task:SetDetection( Detection, DetectedItem )
              Task:UpdateTaskInfo( DetectedItem )
            else
              local TargetSetUnit = self:EvaluateSWEEP( DetectedItem ) -- Returns a SetUnit 
              if TargetSetUnit then
                Task = TASK_A2A_SWEEP:New( Mission, self.SetGroup, string.format( "SWEEP.%03d", DetectedID ), TargetSetUnit )
                Task:SetDetection( Detection, DetectedItem )
                Task:UpdateTaskInfo( DetectedItem )
              end
            end
          end

          if Task then
            self.Tasks[TaskIndex] = Task
            Task:SetTargetZone( DetectedZone, DetectedItem.Coordinate.y, DetectedItem.Coordinate.Heading )
            Task:SetDispatcher( self )
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
            self:F( "This should not happen" )
          end

        end

        if Task then
          local FriendliesCount, FriendliesReport = self:GetFriendliesNearBy( DetectedItem, Unit.Category.AIRPLANE )
          Task.TaskInfo:AddText( "Friendlies", string.format( "%d ( %s )", FriendliesCount, FriendliesReport:Text( "," ) ), 40, "MOD" )
          local PlayersCount, PlayersReport = self:GetPlayerFriendliesNearBy( DetectedItem )
          Task.TaskInfo:AddText( "Players", string.format( "%d ( %s )", PlayersCount, PlayersReport:Text( "," ) ), 40, "MOD" )
        end

        -- OK, so the tasking has been done, now delete the changes reported for the area.
        Detection:AcceptChanges( DetectedItem )
      end

      -- TODO set menus using the HQ coordinator
      Mission:GetCommandCenter():SetMenu()

      local TaskText = TaskReport:Text( ", " )

      for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
        if (not Mission:IsGroupAssigned( TaskGroup )) and TaskText ~= "" and (self.FlashNewTask) then
          Mission:GetCommandCenter():MessageToGroup( string.format( "%s has tasks %s. Subscribe to a task using the radio menu.", Mission:GetShortText(), TaskText ), TaskGroup )
        end
      end

    end

    return true
  end

end
