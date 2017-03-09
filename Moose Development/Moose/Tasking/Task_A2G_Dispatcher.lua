--- **Tasking** - The TASK_A2G_DISPATCHER creates and manages player TASK_A2G tasks based on detected targets.
-- 
-- ===
-- 
-- # 1) @{#TASK_A2G_DISPATCHER} class, extends @{#DETECTION_MANAGER}
-- 
-- The @{#TASK_A2G_DISPATCHER} class implements the dynamic dispatching of tasks upon groups of detected units determined a @{Set} of FAC (groups).
-- The FAC will detect units, will group them, and will dispatch @{Task}s to groups. Depending on the type of target detected, different tasks will be dispatched.
-- Find a summary below describing for which situation a task type is created:
-- 
--   * **CAS Task**: Is created when there are enemy ground units within range of the FAC, while there are friendly units in the FAC perimeter.
--   * **BAI Task**: Is created when there are enemy ground units within range of the FAC, while there are NO other friendly units within the FAC perimeter.
--   * **SEAD Task**: Is created when there are enemy ground units wihtin range of the FAC, with air search radars.
--   
-- Other task types will follow...
-- 
-- 3.1) TASK_A2G_DISPATCHER constructor:
-- --------------------------------------
-- The @{#TASK_A2G_DISPATCHER.New}() method creates a new TASK_A2G_DISPATCHER instance.
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
-- 2017-03-09: Initial class and API.
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
-- @module Task_A2G_Dispatcher

do -- TASK_A2G_DISPATCHER

  --- TASK_A2G_DISPATCHER class.
  -- @type TASK_A2G_DISPATCHER
  -- @field Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Functional.Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
  -- @field Tasking.Mission#MISSION Mission
  -- @field Wrapper.Group#GROUP CommandCenter
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER
  TASK_A2G_DISPATCHER = {
    ClassName = "TASK_A2G_DISPATCHER",
    Mission = nil,
    CommandCenter = nil,
    Detection = nil,
  }
  
  
  --- TASK_A2G_DISPATCHER constructor.
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Set#SET_GROUP SetGroup
  -- @param Functional.Detection#DETECTION_BASE Detection
  -- @return #TASK_A2G_DISPATCHER self
  function TASK_A2G_DISPATCHER:New( Mission, CommandCenter, SetGroup, Detection )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #TASK_A2G_DISPATCHER
    
    self.Detection = Detection
    self.CommandCenter = CommandCenter
    self.Mission = Mission
    
    self:Schedule( 30 )
    return self
  end
  
  
  --- Creates a SEAD task when there are targets for it.
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_AREAS.DetectedItem DetectedItem
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function TASK_A2G_DISPATCHER:EvaluateSEAD( DetectedItem )
    self:F( { DetectedItem.AreaID } )
  
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
  -- @param Functional.Detection#DETECTION_AREAS.DetectedArea DetectedArea
  -- @return Tasking.Task#TASK
  function TASK_A2G_DISPATCHER:EvaluateCAS( DetectedArea )
    self:F( { DetectedArea.AreaID } )
  
    local DetectedSet = DetectedArea.Set
    local DetectedZone = DetectedArea.Zone


    -- Determine if the set has radar targets. If it does, construct a SEAD task.
    local GroundUnitCount = DetectedSet:HasGroundUnits()
    local FriendliesNearBy = self.Detection:IsFriendliesNearBy( DetectedArea )

    if GroundUnitCount > 0 and FriendliesNearBy == true then

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
  -- @param Functional.Detection#DETECTION_AREAS.DetectedArea DetectedArea
  -- @return Tasking.Task#TASK
  function TASK_A2G_DISPATCHER:EvaluateBAI( DetectedArea, FriendlyCoalition )
    self:F( { DetectedArea.AreaID } )
  
    local DetectedSet = DetectedArea.Set
    local DetectedZone = DetectedArea.Zone


    -- Determine if the set has radar targets. If it does, construct a SEAD task.
    local GroundUnitCount = DetectedSet:HasGroundUnits()
    local FriendliesNearBy = self.Detection:IsFriendliesNearBy( DetectedArea )

    if GroundUnitCount > 0 and FriendliesNearBy == false then

      -- Copy the Set
      local TargetSetUnit = SET_UNIT:New()
      TargetSetUnit:SetDatabase( DetectedSet )
      TargetSetUnit:FilterOnce() -- Filter but don't do any events!!! Elements are added manually upon each detection.
      
      return TargetSetUnit
    end
  
    return nil
  end
  
  --- Evaluates the removal of the Task from the Mission.
  -- Can only occur when the DetectedArea is Changed AND the state of the Task is "Planned".
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Tasking.Task#TASK Task
  -- @param Functional.Detection#DETECTION_AREAS.DetectedItem DetectedItem
  -- @return Tasking.Task#TASK
  function TASK_A2G_DISPATCHER:EvaluateRemoveTask( Mission, Task, DetectedItem )
    
    if Task then
      if Task:IsStatePlanned() and DetectedItem.Changed == true then
        self:E( "Removing Tasking: " .. Task:GetTaskName() )
        Task = Mission:RemoveTask( Task )
      end
    end
    
    return Task
  end
  

  --- Assigns tasks in relation to the detected items to the @{Set#SET_GROUP}.
  -- @param #TASK_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Detection#DETECTION_BASE} derived object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function TASK_A2G_DISPATCHER:ProcessDetected( Detection )
    self:F2()
  
    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}
    
    local Mission = self.Mission
    local ReportSEAD = REPORT:New( " - SEAD Tasks:")
    local ReportCAS = REPORT:New( " - CAS Tasks:")
    local ReportBAI = REPORT:New( " - BAI Tasks:")

    --- First we need to  the detected targets.
    for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
    
      local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set -- Functional.Detection#DETECTION_BASE.DetectedSet
      local DetectedZone = DetectedItem.Zone
      self:E( { "Targets in DetectedArea", DetectedItem.AreaID, DetectedSet:Count(), tostring( DetectedItem ) } )
      DetectedSet:Flush()
      
      local AreaID = DetectedItem.AreaID
      
      -- Evaluate SEAD Tasking
      local SEADTask = Mission:GetTask( string.format( "SEAD.%03d", AreaID ) )
      SEADTask = self:EvaluateRemoveTask( Mission, SEADTask, DetectedItem )
      if not SEADTask then
        local TargetSetUnit = self:EvaluateSEAD( DetectedItem ) -- Returns a SetUnit if there are targets to be SEADed...
        if TargetSetUnit then
          local Task = TASK_SEAD:New( Mission, self.SetGroup, string.format( "SEAD.%03d", AreaID ), TargetSetUnit )
          Task:SetTargetZone( DetectedZone )
          SEADTask = Mission:AddTask( Task )
          
        end
      end        
      if SEADTask and SEADTask:IsStatePlanned() then
        ReportSEAD:Add( string.format( " - %s.%02d - %s", "SEAD", AreaID, Detection:DetectedItemReportSummary(DetectedItemID) ) )
      end

      -- Evaluate CAS Tasking
      local CASTask = Mission:GetTask( string.format( "CAS.%03d", AreaID ) )
      CASTask = self:EvaluateRemoveTask( Mission, CASTask, DetectedItem )
      if not CASTask then
        local TargetSetUnit = self:EvaluateCAS( DetectedItem ) -- Returns a SetUnit if there are targets to be SEADed...
        if TargetSetUnit then
          local Task = TASK_CAS:New( Mission, self.SetGroup, string.format( "CAS.%03d", AreaID ), TargetSetUnit )
          Task:SetTargetZone( DetectedZone )
          CASTask = Mission:AddTask( Task )
        end
      end        
      if CASTask and CASTask:IsStatePlanned() then
        ReportCAS:Add( string.format( " - %s.%02d - %s", "CAS.", AreaID, Detection:DetectedItemReportSummary(DetectedItemID) ) )
      end

      -- Evaluate BAI Tasking
      local BAITask = Mission:GetTask( string.format( "BAI.%03d", AreaID ) )
      BAITask = self:EvaluateRemoveTask( Mission, BAITask, DetectedItem )
      if not BAITask then
        local TargetSetUnit = self:EvaluateBAI( DetectedItem, self.CommandCenter:GetCoalition() ) -- Returns a SetUnit if there are targets to be SEADed...
        if TargetSetUnit then
          local Task = TASK_BAI:New( Mission, self.SetGroup, string.format( "BAI.%03d", AreaID ), TargetSetUnit )
          Task:SetTargetZone( DetectedZone )
          BAITask = Mission:AddTask( Task )
        end
      end        
      if BAITask and BAITask:IsStatePlanned() then
        ReportBAI:Add( string.format( " - %s.%02d - %s", "BAI", AreaID, Detection:DetectedItemReportSummary(DetectedItemID) ) )
      end

--        -- Loop through the changes ...
--        local ChangeText = Detection:GetChangeText( DetectedItem )
--        
--        if ChangeText ~= "" then
--          ChangeMsg[#ChangeMsg+1] = string.gsub( string.gsub( ChangeText, "\n", "%1  - " ), "^.", "  - %1" )
--        end
--      end
      
      -- OK, so the tasking has been done, now delete the changes reported for the area.
      Detection:AcceptChanges( DetectedItem )
      
    end
    
    -- TODO set menus using the HQ coordinator
    Mission:GetCommandCenter():SetMenu()
    
    for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
      if not TaskGroup:GetState( TaskGroup, "Assigned" ) then
        self.CommandCenter:MessageToGroup( 
          string.format( "HQ Reporting - Planned tasks for mission '%s':\n%s\n", 
                         self.Mission:GetName(),
                         string.format( "%s\n%s\n%s", ReportSEAD:Text(), ReportCAS:Text(), ReportBAI:Text() )
          ), self:GetReportDisplayTime(), TaskGroup  
        )
      end
    end
    
    return true
  end

end