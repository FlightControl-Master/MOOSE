--- This module contains the DETECTION_MANAGER class and derived classes.
-- @module DetectionManager
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
-- 2) @{DetectionManager#FAC_REPORTING} class, extends @{DetectionManager#DETECTION_MANAGER}
-- ======================================================
-- The @{DetectionManager#FAC_REPORTING} class implements detected units reporting. Reporting can be controlled using the reporting methods available in the @{DetectionManager#DETECTION_MANAGER} class.
-- 
-- 2.1) FAC_REPORTING constructor:
-- -------------------------------
-- The @{DetectionManager#FAC_REPORTING.New}() method creates a new FAC_REPORTING instance.
--    
-- ===
-- 
-- ### Contributions - Mechanic, Prof_Hilactic, FlightControl : Concept & Testing
-- ### Author - FlightControl : Framework Design &  Programming
-- 



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
  
  self:SetReportInterval( 60 )
  self:SetReportDisplayTime( 15 )
  
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
  
  self.SetGroup:ForEachGroup(
    --- @param Group#GROUP Group
    function( Group )
      if Group:IsAlive() then
        return self:ProcessDetected( Group, self.Detection )
      end
    end
  )
  
  return true
end

-- FAC_REPORTING

--- FAC_REPORTING class.
-- @type FAC_REPORTING
-- @field Set#SET_GROUP SetGroup The groups to which the FAC will report to.
-- @field Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
-- @extends #DETECTION_MANAGER
FAC_REPORTING = {
  ClassName = "FAC_REPORTING",
}


--- FAC_REPORTING constructor.
-- @param #FAC_REPORTING self
-- @param Set#SET_GROUP SetGroup
-- @param Detection#DETECTION_UNITGROUPS Detection
-- @return #FAC_REPORTING self
function FAC_REPORTING:New( SetGroup, Detection )

  -- Inherits from DETECTION_MANAGER
  local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #FAC_REPORTING
  
  self:Schedule( 5, 60 )
  return self
end

--- Creates a string of the detected items in a @{Detection}.
-- @param #DETECTION_MANAGER self
-- @param Set#SET_UNIT DetectedSet The detected Set created by the @{Detection#DETECTION_BASE} object.
-- @return #DETECTION_MANAGER self
function FAC_REPORTING:GetDetectedItemsText( DetectedSet )
  self:F2()

  local MT = {} -- Message Text
  local UnitTypes = {}

  for DetectedUnitID, DetectedUnitData in pairs( DetectedSet:GetSet() ) do
    local DetectedUnit = DetectedUnitData -- Unit#UNIT
    local UnitType = DetectedUnit:GetTypeName()

    if not UnitTypes[UnitType] then
      UnitTypes[UnitType] = 1
    else
      UnitTypes[UnitType] = UnitTypes[UnitType] + 1
    end
  end

  for UnitTypeID, UnitType in pairs( UnitTypes ) do
    MT[#MT+1] = UnitType .. " of " .. UnitTypeID
  end

  return table.concat( MT, ", " )
end



--- Reports the detected items to the @{Set#SET_GROUP}.
-- @param #FAC_REPORTING self
-- @param Group#GROUP Group The @{Group} object to where the report needs to go.
-- @param Detection#DETECTION_UNITGROUPS Detection The detection created by the @{Detection#DETECTION_BASE} object.
-- @return #boolean Return true if you want the reporting to continue... false will cancel the reporting loop.
function FAC_REPORTING:ProcessDetected( Group, Detection )
  self:F2( Group )

  self:E( Group )
  local DetectedMsg = {}
  for DetectedAreaID, DetectedAreaData in pairs( Detection:GetDetectedAreas() ) do
    local DetectedArea = DetectedAreaData -- Detection#DETECTION_UNITGROUPS.DetectedArea
    DetectedMsg[#DetectedMsg+1] = " - Group #" .. DetectedAreaID .. ": " .. self:GetDetectedItemsText( DetectedArea.Set )
  end  
  local FACGroup = Detection:GetDetectionGroups()
  FACGroup:MessageToGroup( "Reporting detected target groups:\n" .. table.concat( DetectedMsg, "\n" ), self:GetReportDisplayTime(), Group  )

  return true
end


--- TASK_DISPATCHER

--- TASK_DISPATCHER class.
-- @type TASK_DISPATCHER
-- @field Set#SET_GROUP SetGroup The groups to which the FAC will report to.
-- @field Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
-- @field Mission#MISSION Mission
-- @field Group#GROUP CommandCenter
-- @extends DetectionManager#DETECTION_MANAGER
TASK_DISPATCHER = {
  ClassName = "TASK_DISPATCHER",
  Mission = nil,
  CommandCenter = nil,
  Detection = nil,
}


--- TASK_DISPATCHER constructor.
-- @param #TASK_DISPATCHER self
-- @param Set#SET_GROUP SetGroup
-- @param Detection#DETECTION_BASE Detection
-- @return #TASK_DISPATCHER self
function TASK_DISPATCHER:New( Mission, CommandCenter, SetGroup, Detection )

  -- Inherits from DETECTION_MANAGER
  local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #TASK_DISPATCHER
  
  self.Detection = Detection
  self.CommandCenter = CommandCenter
  self.Mission = Mission
  
  self:Schedule( 30 )
  return self
end


--- Creates a SEAD task when there are targets for it.
-- @param #TASK_DISPATCHER self
-- @param Mission#MISSION Mission
-- @param Detection#DETECTION_UNITGROUPS.DetectedArea DetectedArea
-- @return #string Message explaining which task was added.
function TASK_DISPATCHER:EvaluateTaskSEAD( Mission, DetectedArea )
  self:F( { Mission, DetectedArea.AreaID } )

  MT = {}

  local DetectedSet = DetectedArea.Set
  local DetectedZone = DetectedArea.Zone
  
  -- Determine if the set has radar targets. If it does, construct a SEAD task.
  local RadarCount = DetectedSet:HasRadar( Unit.RadarType.AS )
  DetectedArea.Tasks = DetectedArea.Tasks or {}
  if RadarCount > 0 then
    if not DetectedArea.Tasks.SEADTask then
      local Task = TASK_SEAD:New( Mission, DetectedSet, DetectedZone )
      self.Mission:AddTask( Task )
      MT[#MT+1] = "SEAD"
      DetectedArea.Tasks.SEADTask = Task
    end
  else
    if DetectedArea.Tasks.SEADTask then
      -- Abort Task
    end
  end

  return table.concat( MT, "," )
end

--- Creates a CAS task when there are targets for it.
-- @param #TASK_DISPATCHER self
-- @param Mission#MISSION Mission
-- @param Detection#DETECTION_UNITGROUPS.DetectedArea DetectedArea
-- @return #string Message explaining which task was added.
function TASK_DISPATCHER:EvaluateTaskCAS( Mission, DetectedArea )
  self:F2( { Mission, DetectedArea.AreaID } )

  MT = {}

  local DetectedSet = DetectedArea.Set
  local DetectedZone = DetectedArea.Zone
  
  -- Determine if the set has radar targets. If it does, construct a SEAD task.
  local GroundUnitCount = DetectedSet:HasGroundUnits()
  DetectedArea.Tasks = DetectedArea.Tasks or {}
  if GroundUnitCount > 0 then
    if not DetectedArea.Tasks.CASTask then
      local Task = TASK_CAS:New( Mission, DetectedSet , DetectedZone )
      self.Mission:AddTask( Task )
      MT[#MT+1] = "CAS"
      DetectedArea.Tasks.CASTask = Task
    end
  else
    if DetectedArea.Tasks.CASTask then
      -- Abort Mission
    end    
  end

  return table.concat( MT, "," )
end

--- Creates a string of the detected items in a @{Detection}.
-- @param #DETECTION_MANAGER self
-- @param Set#SET_UNIT DetectedSet The detected Set created by the @{Detection#DETECTION_BASE} object.
-- @return #DETECTION_MANAGER self
function TASK_DISPATCHER:GetDetectedItemsText( DetectedSet )
  self:F2()

  local MT = {} -- Message Text
  local UnitTypes = {}

  for DetectedUnitID, DetectedUnitData in pairs( DetectedSet:GetSet() ) do
    local DetectedUnit = DetectedUnitData -- Unit#UNIT
    local UnitType = DetectedUnit:GetTypeName()

    if not UnitTypes[UnitType] then
      UnitTypes[UnitType] = 1
    else
      UnitTypes[UnitType] = UnitTypes[UnitType] + 1
    end
  end

  for UnitTypeID, UnitType in pairs( UnitTypes ) do
    MT[#MT+1] = UnitType .. " of " .. UnitTypeID
  end

  return table.concat( MT, ", " )
end



--- Assigns tasks in relation to the detected items to the @{Set#SET_GROUP}.
-- @param #TASK_DISPATCHER self
-- @param Group#GROUP Group The @{Group} object to where the report needs to go.
-- @param Detection#DETECTION_UNITGROUPS Detection The detection created by the @{Detection#DETECTION_UNITGROUPS} object.
-- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
function TASK_DISPATCHER:ProcessDetected( TaskGroup, Detection )
  self:F2( TaskGroup )

  local DetectedMsg = {}

  local FACGroup = self.Detection:GetDetectionGroups()
  local FACGroupName = FACGroup:GetName()

  self:E( TaskGroup )

  --- First we need to  the detected targets.
  for DetectedAreaID, DetectedAreaData in ipairs( Detection:GetDetectedAreas() ) do
    local DetectedArea = DetectedAreaData -- Detection#DETECTION_UNITGROUPS.DetectedArea
    local TargetSetUnit = DetectedArea.Set
    local MT = {} -- Message Text
    local UnitTypes = {}
    local TargetZone = DetectedArea.Zone -- Zone#ZONE_BASE
    Detection:FlareDetectedZones()
    Detection:FlareDetectedUnits()

    for DetectedUnitID, DetectedUnitData in pairs( TargetSetUnit:GetSet() ) do

      local TargetUnit = DetectedUnitData -- Unit#UNIT
      self:E( TargetUnit )
      local TargetUnitName = TargetUnit:GetName()
      local TargetUnitType = TargetUnit:GetTypeName()
      
      MT[#MT+1] = self:EvaluateTaskSEAD( self.Mission, DetectedArea )
      MT[#MT+1] = self:EvaluateTaskCAS( self.Mission, DetectedArea )
    end

    DetectedMsg[#DetectedMsg+1] = " - Group #" .. DetectedAreaID .. ": " .. self:GetDetectedItemsText( TargetSetUnit ) .. ". " .. table.concat( MT, "," ) .. " tasks addded."
  end
  
  self.CommandCenter:MessageToGroup( "Reporting tasks for target groups:\n" .. table.concat( DetectedMsg, "\n" ), self:GetReportDisplayTime(), TaskGroup  )
  self.Mission:CreateTaskMenus( TaskGroup )

  return true
end
