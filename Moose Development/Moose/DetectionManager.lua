--- This module contains the DETECTION_MANAGER class and derived classes.
-- 
-- ===
-- 
-- 1) @{DetectionManager#DETECTION_MANAGER} class, extends @{Base#BASE}
-- ====================================================================
-- The @{DetectionManager#DETECTION_MANAGER} class defines the core functions to report detected objects to groups.
-- Reportings can be done in several manners, and it is up to the derived classes if DETECTION_MANAGER to model the reporting behaviour.
-- 
-- 1.1) DETECTION_MANAGER constructor:
-- -----------------------------------
--   * @{DetectionManager#DETECTION_MANAGER.New}(): Create a new DETECTION_MANAGER instance.
-- 
-- 1.2) DETECTION_MANAGER reporting:
-- ---------------------------------
-- Derived DETECTION_MANAGER classes will reports detected units using the method @{DetectionManager#DETECTION_MANAGER.ReportDetected}(). This method implements polymorphic behaviour.
-- 
-- The time interval in seconds of the reporting can be changed using the methods @{DetectionManager#DETECTION_MANAGER.SetReportInterval}(). 
-- To control how long a reporting message is displayed, use @{DetectionManager#DETECTION_MANAGER.SetReportDisplayTime}().
-- Derived classes need to implement the method @{DetectionManager#DETECTION_MANAGER.GetReportDisplayTime}() to use the correct display time for displayed messages during a report.
-- 
-- Reporting can be started and stopped using the methods @{DetectionManager#DETECTION_MANAGER.StartReporting}() and @{DetectionManager#DETECTION_MANAGER.StopReporting}() respectively.
-- If an ad-hoc report is requested, use the method @{DetectionManager#DETECTION_MANAGER#ReportNow}().
-- 
-- The default reporting interval is every 60 seconds. The reporting messages are displayed 15 seconds.
-- 
-- ===
-- 
-- 2) @{DetectionManager#DETECTION_REPORTING} class, extends @{DetectionManager#DETECTION_MANAGER}
-- =========================================================================================
-- The @{DetectionManager#DETECTION_REPORTING} class implements detected units reporting. Reporting can be controlled using the reporting methods available in the @{DetectionManager#DETECTION_MANAGER} class.
-- 
-- 2.1) DETECTION_REPORTING constructor:
-- -------------------------------
-- The @{DetectionManager#DETECTION_REPORTING.New}() method creates a new DETECTION_REPORTING instance.
--    
-- ===
-- 
-- 3) @{#DETECTION_DISPATCHER} class, extends @{#DETECTION_MANAGER}
-- ================================================================
-- The @{#DETECTION_DISPATCHER} class implements the dynamic dispatching of tasks upon groups of detected units determined a @{Set} of FAC (groups).
-- The FAC will detect units, will group them, and will dispatch @{Task}s to groups. Depending on the type of target detected, different tasks will be dispatched.
-- Find a summary below describing for which situation a task type is created:
-- 
--   * **CAS Task**: Is created when there are enemy ground units within range of the FAC, while there are friendly units in the FAC perimeter.
--   * **BAI Task**: Is created when there are enemy ground units within range of the FAC, while there are NO other friendly units within the FAC perimeter.
--   * **SEAD Task**: Is created when there are enemy ground units wihtin range of the FAC, with air search radars.
--   
-- Other task types will follow...
-- 
-- 3.1) DETECTION_DISPATCHER constructor:
-- --------------------------------------
-- The @{#DETECTION_DISPATCHER.New}() method creates a new DETECTION_DISPATCHER instance.
--    
-- ===
-- 
-- ### Contributions: Mechanist, Prof_Hilactic, FlightControl - Concept & Testing
-- ### Author: FlightControl - Framework Design &  Programming
-- 
-- @module DetectionManager

do -- DETECTION MANAGER
  
  --- DETECTION_MANAGER class.
  -- @type DETECTION_MANAGER
  -- @field Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
  -- @extends Base#BASE
  DETECTION_MANAGER = {
    ClassName = "DETECTION_MANAGER",
    SetGroup = nil,
    Detection = nil,
  }
  
  --- FAC constructor.
  -- @param #DETECTION_MANAGER self
  -- @param Set#SET_GROUP SetGroup
  -- @param Detection#DETECTION_BASE Detection
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:New( SetGroup, Detection )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, BASE:New() ) -- Detection#DETECTION_MANAGER
    
    self.SetGroup = SetGroup
    self.Detection = Detection
    
    self:SetReportInterval( 30 )
    self:SetReportDisplayTime( 25 )
    
    return self
  end
  
  --- Set the reporting time interval.
  -- @param #DETECTION_MANAGER self
  -- @param #number ReportInterval The interval in seconds when a report needs to be done.
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:SetReportInterval( ReportInterval )
    self:F2()
  
    self._ReportInterval = ReportInterval
  end
  
  
  --- Set the reporting message display time.
  -- @param #DETECTION_MANAGER self
  -- @param #number ReportDisplayTime The display time in seconds when a report needs to be done.
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:SetReportDisplayTime( ReportDisplayTime )
    self:F2()
  
    self._ReportDisplayTime = ReportDisplayTime
  end
  
  --- Get the reporting message display time.
  -- @param #DETECTION_MANAGER self
  -- @return #number ReportDisplayTime The display time in seconds when a report needs to be done.
  function DETECTION_MANAGER:GetReportDisplayTime()
    self:F2()
  
    return self._ReportDisplayTime
  end
  
  
  
  --- Reports the detected items to the @{Set#SET_GROUP}.
  -- @param #DETECTION_MANAGER self
  -- @param Detection#DETECTION_BASE Detection
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:ReportDetected( Detection )
  	self:F2()
  
  end
  
  --- Schedule the FAC reporting.
  -- @param #DETECTION_MANAGER self
  -- @param #number DelayTime The delay in seconds to wait the reporting.
  -- @param #number ReportInterval The repeat interval in seconds for the reporting to happen repeatedly.
  -- @return #DETECTION_MANAGER self
  function DETECTION_MANAGER:Schedule( DelayTime, ReportInterval )
  	self:F2()
  
    self._ScheduleDelayTime = DelayTime
    
    self:SetReportInterval( ReportInterval )
    
    self.FacScheduler = SCHEDULER:New(self, self._FacScheduler, { self, "DetectionManager" }, self._ScheduleDelayTime, self._ReportInterval )
    return self
  end
  
  --- Report the detected @{Unit#UNIT}s detected within the @{Detection#DETECTION_BASE} object to the @{Set#SET_GROUP}s.
  -- @param #DETECTION_MANAGER self
  function DETECTION_MANAGER:_FacScheduler( SchedulerName )
    self:F2( { SchedulerName } )
    
    return self:ProcessDetected( self.Detection )
    
--    self.SetGroup:ForEachGroup(
--      --- @param Group#GROUP Group
--      function( Group )
--        if Group:IsAlive() then
--          return self:ProcessDetected( self.Detection )
--        end
--      end
--    )
    
--    return true
  end

end


do -- DETECTION_REPORTING

  --- DETECTION_REPORTING class.
  -- @type DETECTION_REPORTING
  -- @field Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
  -- @extends #DETECTION_MANAGER
  DETECTION_REPORTING = {
    ClassName = "DETECTION_REPORTING",
  }
  
  
  --- DETECTION_REPORTING constructor.
  -- @param #DETECTION_REPORTING self
  -- @param Set#SET_GROUP SetGroup
  -- @param Detection#DETECTION_AREAS Detection
  -- @return #DETECTION_REPORTING self
  function DETECTION_REPORTING:New( SetGroup, Detection )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #DETECTION_REPORTING
    
    self:Schedule( 1, 30 )
    return self
  end
  
  --- Creates a string of the detected items in a @{Detection}.
  -- @param #DETECTION_MANAGER self
  -- @param Set#SET_UNIT DetectedSet The detected Set created by the @{Detection#DETECTION_BASE} object.
  -- @return #DETECTION_MANAGER self
  function DETECTION_REPORTING:GetDetectedItemsText( DetectedSet )
    self:F2()
  
    local MT = {} -- Message Text
    local UnitTypes = {}
  
    for DetectedUnitID, DetectedUnitData in pairs( DetectedSet:GetSet() ) do
      local DetectedUnit = DetectedUnitData -- Unit#UNIT
      if DetectedUnit:IsAlive() then
        local UnitType = DetectedUnit:GetTypeName()
    
        if not UnitTypes[UnitType] then
          UnitTypes[UnitType] = 1
        else
          UnitTypes[UnitType] = UnitTypes[UnitType] + 1
        end
      end
    end
  
    for UnitTypeID, UnitType in pairs( UnitTypes ) do
      MT[#MT+1] = UnitType .. " of " .. UnitTypeID
    end
  
    return table.concat( MT, ", " )
  end
  
  
  
  --- Reports the detected items to the @{Set#SET_GROUP}.
  -- @param #DETECTION_REPORTING self
  -- @param Group#GROUP Group The @{Group} object to where the report needs to go.
  -- @param Detection#DETECTION_AREAS Detection The detection created by the @{Detection#DETECTION_BASE} object.
  -- @return #boolean Return true if you want the reporting to continue... false will cancel the reporting loop.
  function DETECTION_REPORTING:ProcessDetected( Group, Detection )
    self:F2( Group )
  
    self:E( Group )
    local DetectedMsg = {}
    for DetectedAreaID, DetectedAreaData in pairs( Detection:GetDetectedAreas() ) do
      local DetectedArea = DetectedAreaData -- Detection#DETECTION_AREAS.DetectedArea
      DetectedMsg[#DetectedMsg+1] = " - Group #" .. DetectedAreaID .. ": " .. self:GetDetectedItemsText( DetectedArea.Set )
    end  
    local FACGroup = Detection:GetDetectionGroups()
    FACGroup:MessageToGroup( "Reporting detected target groups:\n" .. table.concat( DetectedMsg, "\n" ), self:GetReportDisplayTime(), Group  )
  
    return true
  end

end

do -- DETECTION_DISPATCHER

  --- DETECTION_DISPATCHER class.
  -- @type DETECTION_DISPATCHER
  -- @field Set#SET_GROUP SetGroup The groups to which the FAC will report to.
  -- @field Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
  -- @field Mission#MISSION Mission
  -- @field Group#GROUP CommandCenter
  -- @extends DetectionManager#DETECTION_MANAGER
  DETECTION_DISPATCHER = {
    ClassName = "DETECTION_DISPATCHER",
    Mission = nil,
    CommandCenter = nil,
    Detection = nil,
  }
  
  
  --- DETECTION_DISPATCHER constructor.
  -- @param #DETECTION_DISPATCHER self
  -- @param Set#SET_GROUP SetGroup
  -- @param Detection#DETECTION_BASE Detection
  -- @return #DETECTION_DISPATCHER self
  function DETECTION_DISPATCHER:New( Mission, CommandCenter, SetGroup, Detection )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #DETECTION_DISPATCHER
    
    self.Detection = Detection
    self.CommandCenter = CommandCenter
    self.Mission = Mission
    
    self:Schedule( 30 )
    return self
  end
  
  
  --- Creates a SEAD task when there are targets for it.
  -- @param #DETECTION_DISPATCHER self
  -- @param Detection#DETECTION_AREAS.DetectedArea DetectedArea
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function DETECTION_DISPATCHER:EvaluateSEAD( DetectedArea )
    self:F( { DetectedArea.AreaID } )
  
    local DetectedSet = DetectedArea.Set
    local DetectedZone = DetectedArea.Zone

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
  -- @param #DETECTION_DISPATCHER self
  -- @param Detection#DETECTION_AREAS.DetectedArea DetectedArea
  -- @return Task#TASK_BASE
  function DETECTION_DISPATCHER:EvaluateCAS( DetectedArea )
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
  -- @param #DETECTION_DISPATCHER self
  -- @param Detection#DETECTION_AREAS.DetectedArea DetectedArea
  -- @return Task#TASK_BASE
  function DETECTION_DISPATCHER:EvaluateBAI( DetectedArea, FriendlyCoalition )
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
  -- @param #DETECTION_DISPATCHER self
  -- @param Mission#MISSION Mission
  -- @param Task#TASK_BASE Task
  -- @param Detection#DETECTION_AREAS.DetectedArea DetectedArea
  -- @return Task#TASK_BASE
  function DETECTION_DISPATCHER:EvaluateRemoveTask( Mission, Task, DetectedArea )
    
    if Task then
      if Task:IsStatePlanned() and DetectedArea.Changed == true then
        Mission:RemoveTaskMenu( Task )
        Task = Mission:RemoveTask( Task )
      end
    end
    
    return Task
  end
  

  --- Assigns tasks in relation to the detected items to the @{Set#SET_GROUP}.
  -- @param #DETECTION_DISPATCHER self
  -- @param Detection#DETECTION_AREAS Detection The detection created by the @{Detection#DETECTION_AREAS} object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function DETECTION_DISPATCHER:ProcessDetected( Detection )
    self:F2()
  
    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}
    
    local Mission = self.Mission

    --- First we need to  the detected targets.
    for DetectedAreaID, DetectedAreaData in ipairs( Detection:GetDetectedAreas() ) do
    
      local DetectedArea = DetectedAreaData -- Detection#DETECTION_AREAS.DetectedArea
      local DetectedSet = DetectedArea.Set
      local DetectedZone = DetectedArea.Zone
      self:E( { "Targets in DetectedArea", DetectedArea.AreaID, DetectedSet:Count(), tostring( DetectedArea ) } )
      DetectedSet:Flush()
      
      local AreaID = DetectedArea.AreaID
      
      -- Evaluate SEAD Tasking
      local SEADTask = Mission:GetTask( "SEAD." .. AreaID )
      SEADTask = self:EvaluateRemoveTask( Mission, SEADTask, DetectedArea )
      if not SEADTask then
        local TargetSetUnit = self:EvaluateSEAD( DetectedArea ) -- Returns a SetUnit if there are targets to be SEADed...
        if TargetSetUnit then
          SEADTask = Mission:AddTask( TASK_SEAD:New( Mission, self.SetGroup, "SEAD." .. AreaID, TargetSetUnit , DetectedZone ) ):StatePlanned()
        end
      end        
      if SEADTask and SEADTask:IsStatePlanned() then
        SEADTask:SetPlannedMenu()
        TaskMsg[#TaskMsg+1] = "  - " .. SEADTask:GetStateString() .. " SEAD " .. AreaID .. " - " .. SEADTask.TargetSetUnit:GetUnitTypesText()
      end

      -- Evaluate CAS Tasking
      local CASTask = Mission:GetTask( "CAS." .. AreaID )
      CASTask = self:EvaluateRemoveTask( Mission, CASTask, DetectedArea )
      if not CASTask then
        local TargetSetUnit = self:EvaluateCAS( DetectedArea ) -- Returns a SetUnit if there are targets to be SEADed...
        if TargetSetUnit then
          CASTask = Mission:AddTask( TASK_A2G:New( Mission, self.SetGroup, "CAS." .. AreaID, "CAS", TargetSetUnit , DetectedZone, DetectedArea.NearestFAC ) ):StatePlanned()
        end
      end        
      if CASTask and CASTask:IsStatePlanned() then
        CASTask:SetPlannedMenu()
        TaskMsg[#TaskMsg+1] = "  - " .. CASTask:GetStateString() .. " CAS " .. AreaID .. " - " .. CASTask.TargetSetUnit:GetUnitTypesText()
      end

      -- Evaluate BAI Tasking
      local BAITask = Mission:GetTask( "BAI." .. AreaID )
      BAITask = self:EvaluateRemoveTask( Mission, BAITask, DetectedArea )
      if not BAITask then
        local TargetSetUnit = self:EvaluateBAI( DetectedArea, self.CommandCenter:GetCoalition() ) -- Returns a SetUnit if there are targets to be SEADed...
        if TargetSetUnit then
          BAITask = Mission:AddTask( TASK_A2G:New( Mission, self.SetGroup, "BAI." .. AreaID, "BAI", TargetSetUnit , DetectedZone, DetectedArea.NearestFAC ) ):StatePlanned()
        end
      end        
      if BAITask and BAITask:IsStatePlanned() then
        BAITask:SetPlannedMenu()
        TaskMsg[#TaskMsg+1] = "  - " .. BAITask:GetStateString() .. " BAI "  .. AreaID .. " - " .. BAITask.TargetSetUnit:GetUnitTypesText()
      end

      if #TaskMsg > 0 then
    
        local ThreatLevel = Detection:GetTreatLevelA2G( DetectedArea )

        local DetectedAreaVec3 = DetectedZone:GetPointVec3()
        local DetectedAreaPointVec3 = POINT_VEC3:New( DetectedAreaVec3.x, DetectedAreaVec3.y, DetectedAreaVec3.z )
        local DetectedAreaPointLL = DetectedAreaPointVec3:ToStringLL( 3, true )
        AreaMsg[#AreaMsg+1] = string.format( "  - Area #%d - %s - Threat Level [%s] (%2d)", 
                                                     DetectedAreaID,
                                                     DetectedAreaPointLL,
                                                     string.rep(  "■", ThreatLevel ),
                                                     ThreatLevel
                                      )
        
        -- Loop through the changes ...
        local ChangeText = Detection:GetChangeText( DetectedArea )
        
        if ChangeText ~= "" then
          ChangeMsg[#ChangeMsg+1] = string.gsub( string.gsub( ChangeText, "\n", "%1  - " ), "^.", "  - %1" )
        end
      end
      
      -- OK, so the tasking has been done, now delete the changes reported for the area.
      Detection:AcceptChanges( DetectedArea )
      
    end
    
    if #AreaMsg > 0 then
      for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
        if not TaskGroup:GetState( TaskGroup, "Assigned" ) then
          self.CommandCenter:MessageToGroup( 
            string.format( "HQ Reporting - Target areas for mission '%s':\nAreas:\n%s\n\nTasks:\n%s\n\nChanges:\n%s ", 
                           self.Mission:GetName(),
                           table.concat( AreaMsg, "\n" ),
                           table.concat( TaskMsg, "\n" ),
                           table.concat( ChangeMsg, "\n" )
            ), self:GetReportDisplayTime(), TaskGroup  
          )
        end
      end
    end
    
    return true
  end

end