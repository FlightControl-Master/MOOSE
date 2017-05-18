--- **Tasking** - The TASK_A2A_DISPATCHER creates and manages player TASK_A2A tasks based on detected targets.
-- 
-- ===
-- 
-- # 1) @{#TASK_A2A_DISPATCHER} class, extends @{#DETECTION_MANAGER}
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
-- 3.1) TASK_A2A_DISPATCHER constructor:
-- --------------------------------------
-- The @{#TASK_A2A_DISPATCHER.New}() method creates a new TASK_A2A_DISPATCHER instance.
--    
-- ===
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
-- @module Task_A2A_Dispatcher

do -- TASK_A2A_DISPATCHER

  --- TASK_A2A_DISPATCHER class.
  -- @type TASK_A2A_DISPATCHER
  -- @field Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Functional.Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects. The Detection object will only function in RADAR mode!!!
  -- @field Tasking.Mission#MISSION Mission
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER
  TASK_A2A_DISPATCHER = {
    ClassName = "TASK_A2A_DISPATCHER",
    Mission = nil,
    Detection = nil,
    Tasks = {},
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
    
    self.Detection:FilterCategories( Unit.Category.AIRPLANE, Unit.Category.HELICOPTER )
    self.Detection:InitDetectRadar( true )
    self.Detection:SetDetectionInterval(30)
    
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

    -- Put here the intercept logic....

    if true then

      -- Here we're doing something advanced... We're copying the DetectedSet, but making a new Set only with SEADable Radar units in it.
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
  -- @param #boolean DetectedItemID
  -- @param #boolean DetectedItemChange
  -- @return Tasking.Task#TASK
  function TASK_A2A_DISPATCHER:EvaluateRemoveTask( Mission, Task, DetectedItemID, DetectedItemChanged )
    
    if Task then
      if Task:IsStatePlanned() and DetectedItemChanged == true then
        self:E( "Removing Tasking: " .. Task:GetTaskName() )
        Mission:RemoveTask( Task )
        self.Tasks[DetectedItemID] = nil
      end
    end
    
    return Task
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

      --- First we need to  the detected targets.
      for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
      
        local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
        local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
        local DetectedZone = DetectedItem.Zone
        self:E( { "Targets in DetectedItem", DetectedItem.ItemID, DetectedSet:Count(), tostring( DetectedItem ) } )
        DetectedSet:Flush()
        
        local DetectedID = DetectedItem.ID
        local DetectedIndex = DetectedItem.Index
        local DetectedItemChanged = DetectedItem.Changed
        
        local Task = self.Tasks[DetectedID]
        Task = self:EvaluateRemoveTask( Mission, Task, DetectedID, DetectedItemChanged ) -- Task will be removed if it is planned and changed.

        -- Evaluate INTERCEPT
        if not Task then
          local TargetSetUnit = self:EvaluateINTERCEPT( DetectedItem ) -- Returns a SetUnit if there are targets to be INTERCEPTed...
          if TargetSetUnit then
            Task = TASK_INTERCEPT:New( Mission, self.SetGroup, string.format( "INTERCEPT.%03d", DetectedID ), TargetSetUnit )
          end

          if Task then
            self.Tasks[DetectedID] = Task
            Task:SetTargetZone( DetectedZone )
            Task:SetDispatcher( self )
            Task:SetInfo( "ThreatLevel", "[" .. string.rep(  "■", DetectedSet:CalculateThreatLevelA2G() ) .. "]" )
            local DetectedItemsCount = DetectedSet:Count()
            local DetectedItemsTypes = DetectedSet:GetTypeNames()
            Task:SetInfo( "Targets", string.format( "%d of %s", DetectedItemsCount, DetectedItemsTypes ) ) 
            Task:SetInfo( "Coordinates", Detection:GetDetectedItemCoordinate( DetectedIndex ) )
            Task:SetInfo( "Changes", Detection:GetChangeText( DetectedItem ) )
            Task:SetInfo( "Object", DetectedSet:GetFirst() )
            Mission:AddTask( Task )
          else
            self:E("This should not happen")
          end

        end

        TaskReport:Add( Task:GetName() )
  
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
