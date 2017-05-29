--- **Tasking** - The TASK_A2A_DISPATCHER creates and manages player TASK_A2A tasks based on detected targets.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====
-- 
-- @module Task_A2A_Dispatcher

do -- TASK_A2A_DISPATCHER

  --- TASK_A2A_DISPATCHER class.
  -- @type TASK_A2A_DISPATCHER
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER

  --- # TASK_A2A_DISPATCHER class, extends @{Tasking#DETECTION_MANAGER}
  -- 
  -- The @{#TASK_A2A_DISPATCHER} class implements the dynamic dispatching of tasks upon groups of detected units determined a @{Set} of EWR installation groups.
  -- The EWR will detect units, will group them, and will dispatch @{Task}s to groups. Depending on the type of target detected, different tasks will be dispatched.
  -- Find a summary below describing for which situation a task type is created:
  -- 
  --   * **INTERCEPT Task**: Is created when the target is known, is detected and within a danger zone, and there is no friendly airborne in range.
  --   * **SWEEP Task**: Is created when the target is unknown, was detected and the last position is only known, and within a danger zone, and there is no friendly airborne in range.
  --   * **ENGAGE Task**: Is created when the target is known, is detected and within a danger zone, and there is a friendly airborne in range, that will receive this task.
  --   
  -- Other task types will follow...
  -- 
  -- # TASK_A2A_DISPATCHER constructor:
  -- --------------------------------------
  -- The @{#TASK_A2A_DISPATCHER.New}() method creates a new TASK_A2A_DISPATCHER instance.
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
  -- @param Set#SET_GROUP SetGroup The set of groups that can join the tasks within the mission.
  -- @param Functional.Detection#DETECTION_BASE Detection The detection results that are used to dynamically assign new tasks to human players.
  -- @return #TASK_A2A_DISPATCHER self
  function TASK_A2A_DISPATCHER:New( Mission, SetGroup, Detection )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #TASK_A2A_DISPATCHER
    
    self.Detection = Detection
    self.Mission = Mission
    
    
    -- TODO: Check detection through radar.
    self.Detection:FilterCategories( Unit.Category.AIRPLANE, Unit.Category.HELICOPTER )
    --self.Detection:InitDetectRadar( true )
    self.Detection:SetDetectionInterval( 30 )
    
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
  
  
  --- Creates an INTERCEPT task when there are targets for it.
  -- @param #TASK_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
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
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function TASK_A2A_DISPATCHER:EvaluateSWEEP( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone


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
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function TASK_A2A_DISPATCHER:EvaluateENGAGE( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone

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
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Detection#DETECTION_BASE} derived object.
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
        --DetectedSet:Flush()
        --self:E( { DetectedSetCount = DetectedSet:Count() } )
        if DetectedSet:Count() == 0 then
          Remove = true
        end
         
        if DetectedItemChanged == true or Remove then
          --self:E( "Removing Tasking: " .. Task:GetTaskName() )
          Mission:RemoveTask( Task )
          self.Tasks[DetectedItemIndex] = nil
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
    local FriendlyUnitsNearBy = self.Detection:GetFriendliesNearBy( DetectedItem )
    
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
          FriendlyTypes[FriendlyType] = FriendlyTypes[FriendlyType] and ( FriendlyTypes[FriendlyType] + 1 ) or 1
          if DetectedTreatLevel < FriendlyUnitThreatLevel + 2 then
          end
        end
      end
      
    end

    --self:E( { FriendliesCount = FriendliesCount } )
    
    local FriendlyTypesReport = REPORT:New()
    
    if FriendliesCount > 0 then
      for FriendlyType, FriendlyTypeCount in pairs( FriendlyTypes ) do
        FriendlyTypesReport:Add( string.format("%d of %s", FriendlyTypeCount, FriendlyType ) )
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
        --self:E( { PlayerName = PlayerName, PlayerUnit = PlayerUnit } )
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

    --self:E( { PlayersCount = PlayersCount } )
    
    local PlayerTypesReport = REPORT:New()
    
    if PlayersCount > 0 then
      for PlayerName, PlayerType in pairs( PlayerTypes ) do
        PlayerTypesReport:Add( string.format('"%s" in %s', PlayerName, PlayerType ) )
      end
    else
      PlayerTypesReport:Add( "-" )
    end
    
    
    return PlayersCount, PlayerTypesReport
  end


  --- Assigns tasks in relation to the detected items to the @{Set#SET_GROUP}.
  -- @param #TASK_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Detection#DETECTION_BASE} derived object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function TASK_A2A_DISPATCHER:ProcessDetected( Detection )
    self:E()
  
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
          local DetectedItem = Detection:GetDetectedItem( TaskIndex )
          if not DetectedItem then
            local TaskText = Task:GetName()
            for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
              Mission:GetCommandCenter():MessageToGroup( string.format( "Obsolete A2A task %s for %s removed.", TaskText, Mission:GetName() ), TaskGroup )
            end
            Mission:RemoveTask( Task )
            self.Tasks[TaskIndex] = nil
          end
        end
      end

      -- Now that all obsolete tasks are removed, loop through the detected targets.
      for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
      
        local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
        local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
        local DetectedCount = DetectedSet:Count()
        local DetectedZone = DetectedItem.Zone
        --self:E( { "Targets in DetectedItem", DetectedItem.ItemID, DetectedSet:Count(), tostring( DetectedItem ) } )
        --DetectedSet:Flush()
        
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
          else
            local TargetSetUnit = self:EvaluateINTERCEPT( DetectedItem ) -- Returns a SetUnit if there are targets to be INTERCEPTed...
            if TargetSetUnit then
              Task = TASK_A2A_INTERCEPT:New( Mission, self.SetGroup, string.format( "INTERCEPT.%03d", DetectedID ), TargetSetUnit )
            else
              local TargetSetUnit = self:EvaluateSWEEP( DetectedItem ) -- Returns a SetUnit 
              if TargetSetUnit then
                Task = TASK_A2A_SWEEP:New( Mission, self.SetGroup, string.format( "SWEEP.%03d", DetectedID ), TargetSetUnit )
              end  
            end
          end

          if Task then
            self.Tasks[TaskIndex] = Task
            Task:SetTargetZone( DetectedZone, DetectedSet:GetFirst():GetAltitude(), DetectedSet:GetFirst():GetHeading() )
            Task:SetDispatcher( self )
            Mission:AddTask( Task )
            
            TaskReport:Add( Task:GetName() )
          else
            self:E("This should not happen")
          end

        end

        if Task then
          local FriendliesCount, FriendliesReport = self:GetFriendliesNearBy( DetectedItem )
          Task:SetInfo( "Friendlies", string.format( "%d ( %s )", FriendliesCount, FriendliesReport:Text( "," ) ) ) 
          local PlayersCount, PlayersReport = self:GetPlayerFriendliesNearBy( DetectedItem )
          Task:SetInfo( "Players", string.format( "%d ( %s )", PlayersCount, PlayersReport:Text( "," ) ) ) 
        end
  
        -- OK, so the tasking has been done, now delete the changes reported for the area.
        Detection:AcceptChanges( DetectedItem )
      end
      
      -- TODO set menus using the HQ coordinator
      Mission:GetCommandCenter():SetMenu()

      local TaskText = TaskReport:Text(", ")
      
      for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
        if ( not Mission:IsGroupAssigned(TaskGroup) ) and TaskText ~= "" then
          Mission:GetCommandCenter():MessageToGroup( string.format( "%s has tasks %s. Subscribe to a task using the radio menu.", Mission:GetName(), TaskText ), TaskGroup )
        end
      end
      
    end
    
    return true
  end

end
