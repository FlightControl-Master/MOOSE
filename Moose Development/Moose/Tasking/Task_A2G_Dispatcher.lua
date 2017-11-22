--- **Tasking** - The TASK_A2G_DISPATCHER creates and manages player TASK_A2G tasks based on detected targets.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====
-- 
-- @module Task_A2G_Dispatcher

do -- TASK_A2G_DISPATCHER

  --- TASK_A2G_DISPATCHER class.
  -- @type TASK_A2G_DISPATCHER
  -- @field Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Functional.Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
  -- @field Tasking.Mission#MISSION Mission
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER

  --- # TASK_A2G_DISPATCHE} class, extends @{#DETECTION_MANAGER}
  -- 
  -- The TASK_A2G_DISPATCHER class implements the dynamic dispatching of tasks upon groups of detected units determined a @{Set} of FAC (groups).
  -- The FAC will detect units, will group them, and will dispatch @{Task}s to groups. Depending on the type of target detected, different tasks will be dispatched.
  -- Find a summary below describing for which situation a task type is created:
  -- 
  --   * **CAS Task**: Is created when there are enemy ground units within range of the FAC, while there are friendly units in the FAC perimeter.
  --   * **BAI Task**: Is created when there are enemy ground units within range of the FAC, while there are NO other friendly units within the FAC perimeter.
  --   * **SEAD Task**: Is created when there are enemy ground units wihtin range of the FAC, with air search radars.
  --   
  -- Other task types will follow...
  -- 
  -- ## TASK_A2G_DISPATCHER constructor
  -- 
  -- The @{#TASK_A2G_DISPATCHER.New}() method creates a new TASK_A2G_DISPATCHER instance.
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
  -- @param Set#SET_GROUP SetGroup The set of groups that can join the tasks within the mission.
  -- @param Functional.Detection#DETECTION_BASE Detection The detection results that are used to dynamically assign new tasks to human players.
  -- @return #TASK_A2G_DISPATCHER self
  function TASK_A2G_DISPATCHER:New( Mission, SetGroup, Detection )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #TASK_A2G_DISPATCHER
    
    self.Detection = Detection
    self.Mission = Mission
    
    self.Detection:FilterCategories( Unit.Category.GROUND_UNIT, Unit.Category.SHIP )
    self.Detection:FilterFriendliesCategory( Unit.Category.GROUND_UNIT )
    
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


    -- Determine if the set has radar targets. If it does, construct a SEAD task.
    local GroundUnitCount = DetectedSet:HasGroundUnits()
    local FriendliesNearBy = self.Detection:IsFriendliesNearBy( DetectedItem )
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


    -- Determine if the set has radar targets. If it does, construct a SEAD task.
    local GroundUnitCount = DetectedSet:HasGroundUnits()
    local FriendliesNearBy = self.Detection:IsFriendliesNearBy( DetectedItem )
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
        --self:E( "Removing Tasking: " .. Task:GetTaskName() )
        self:RemoveTask( TaskIndex )
      end
    end
    
    return Task
  end
  

  --- Assigns tasks in relation to the detected items to the @{Set#SET_GROUP}.
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Detection#DETECTION_BASE} derived object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function TASK_A2G_DISPATCHER:ProcessDetected( Detection )
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
              Mission:GetCommandCenter():MessageToGroup( string.format( "Obsolete A2G task %s for %s removed.", TaskText, Mission:GetName() ), TaskGroup )
            end
            Task = self:RemoveTask( TaskIndex )
            Mission:RemoveTask( Task )
            self.Tasks[TaskIndex] = nil
          end
        end
      end

      --- First we need to  the detected targets.
      for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
      
        local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
        local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
        local DetectedZone = DetectedItem.Zone
        --self:E( { "Targets in DetectedItem", DetectedItem.ItemID, DetectedSet:Count(), tostring( DetectedItem ) } )
        --DetectedSet:Flush()
        
        local DetectedItemID = DetectedItem.ID
        local TaskIndex = DetectedItem.ID
        local DetectedItemChanged = DetectedItem.Changed
        
        self:E( { DetectedItemChanged = DetectedItemChanged, DetectedItemID = DetectedItemID, TaskIndex = TaskIndex } )
        
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
                  Task:UpdateTaskInfo()
                  TargetsReport:Add( Detection:GetChangeText( DetectedItem )  )
                else
                  Task:Cancel()
                end
              else
                local TargetSetUnit = self:EvaluateCAS( DetectedItem ) -- Returns a SetUnit if there are targets to be CASed...
                if TargetSetUnit then
                  if Task:IsInstanceOf( TASK_A2G_CAS ) then
                    Task:SetTargetSetUnit( TargetSetUnit )
                    Task:SetDetection( Detection, TaskIndex )
                    Task:UpdateTaskInfo()
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
                      Task:SetDetection( Detection, TaskIndex )
                      Task:UpdateTaskInfo()
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
                if ( Mission:IsGroupAssigned(TaskGroup) ) and TargetsText ~= "" then
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
                  Task:UpdateTaskInfo()
                else
                  Task:Cancel()
                  Task = self:RemoveTask( TaskIndex )
                end
              else
                if Task:IsInstanceOf( TASK_A2G_CAS ) then
                  local TargetSetUnit = self:EvaluateCAS( DetectedItem ) -- Returns a SetUnit if there are targets to be CASed...
                  if TargetSetUnit then
                    Task:SetTargetSetUnit( TargetSetUnit )
                    Task:SetDetection( Detection, TaskIndex )
                    Task:UpdateTaskInfo()
                  else
                    Task:Cancel()
                    Task = self:RemoveTask( TaskIndex )
                  end
                else
                  if Task:IsInstanceOf( TASK_A2G_BAI ) then
                    local TargetSetUnit = self:EvaluateBAI( DetectedItem ) -- Returns a SetUnit if there are targets to be BAIed...
                    if TargetSetUnit then
                      Task:SetTargetSetUnit( TargetSetUnit )
                      Task:SetDetection( Detection, TaskIndex )
                      Task:UpdateTaskInfo()
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
            Task:SetDetection( Detection, TaskIndex )
          end

          -- Evaluate CAS
          if not Task then
            local TargetSetUnit = self:EvaluateCAS( DetectedItem ) -- Returns a SetUnit if there are targets to be CASed...
            if TargetSetUnit then
              Task = TASK_A2G_CAS:New( Mission, self.SetGroup, string.format( "CAS.%03d", DetectedItemID ), TargetSetUnit )
              Task:SetDetection( Detection, TaskIndex )
            end

            -- Evaluate BAI
            if not Task then
              local TargetSetUnit = self:EvaluateBAI( DetectedItem, self.Mission:GetCommandCenter():GetPositionable():GetCoalition() ) -- Returns a SetUnit if there are targets to be BAIed...
              if TargetSetUnit then
                Task = TASK_A2G_BAI:New( Mission, self.SetGroup, string.format( "BAI.%03d", DetectedItemID ), TargetSetUnit )
                Task:SetDetection( Detection, TaskIndex )
              end
            end
          end
          
          if Task then
            self.Tasks[TaskIndex] = Task
            Task:SetTargetZone( DetectedZone )
            Task:SetDispatcher( self )
            Task:UpdateTaskInfo()
            Mission:AddTask( Task )
    
            TaskReport:Add( Task:GetName() )
          else
            self:E("This should not happen")
          end
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