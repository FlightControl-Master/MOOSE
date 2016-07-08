--- This module contains the FAC classes.
-- 
-- ===
-- 
-- 1) @{Fac#DETECTION_MANAGER} class, extends @{Base#BASE}
-- ==============================================
-- The @{Fac#DETECTION_MANAGER} class defines the core functions to report detected objects to groups.
-- Reportings can be done in several manners, and it is up to the derived classes if DETECTION_MANAGER to model the reporting behaviour.
-- 
-- 1.1) DETECTION_MANAGER constructor:
-- ----------------------------
--   * @{Fac#DETECTION_MANAGER.New}(): Create a new DETECTION_MANAGER instance.
-- 
-- 1.2) DETECTION_MANAGER reporting:
-- ------------------------
-- Derived DETECTION_MANAGER classes will reports detected units using the method @{Fac#DETECTION_MANAGER.ReportDetected}(). This method implements polymorphic behaviour.
-- 
-- The time interval in seconds of the reporting can be changed using the methods @{Fac#DETECTION_MANAGER.SetReportInterval}(). 
-- To control how long a reporting message is displayed, use @{Fac#DETECTION_MANAGER.SetReportDisplayTime}().
-- Derived classes need to implement the method @{Fac#DETECTION_MANAGER.GetReportDisplayTime}() to use the correct display time for displayed messages during a report.
-- 
-- Reporting can be started and stopped using the methods @{Fac#DETECTION_MANAGER.StartReporting}() and @{Fac#DETECTION_MANAGER.StopReporting}() respectively.
-- If an ad-hoc report is requested, use the method @{Fac#DETECTION_MANAGER#ReportNow}().
-- 
-- The default reporting interval is every 60 seconds. The reporting messages are displayed 15 seconds.
-- 
-- ===
-- 
-- 2) @{Fac#FAC_REPORTING} class, extends @{Fac#DETECTION_MANAGER}
-- ======================================================
-- The @{Fac#FAC_REPORTING} class implements detected units reporting. Reporting can be controlled using the reporting methods available in the @{Fac#DETECTION_MANAGER} class.
-- 
-- 2.1) FAC_REPORTING constructor:
-- -------------------------------
-- The @{Fac#FAC_REPORTING.New}() method creates a new FAC_REPORTING instance.
--    
-- ===
-- 
-- @module Fac
-- @author Mechanic, Prof_Hilactic, FlightControl : Concept & Testing
-- @author FlightControl : Design & Programming



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

--- Creates a string of the detected items in a @{Set}.
-- @param #DETECTION_MANAGER self
-- @param Set#SET_BASE DetectedSets The detected Sets created by the @{Detection#DETECTION_BASE} object.
-- @return #DETECTION_MANAGER self
function DETECTION_MANAGER:GetDetectedItemsText( DetectedSet )
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

  local MessageText = table.concat( MT, ", " )

  return MessageText
end



--- Reports the detected items to the @{Set#SET_GROUP}.
-- @param #DETECTION_MANAGER self
-- @param Set#SET_BASE DetectedSets The detected Sets created by the @{Detection#DETECTION_BASE} object.
-- @return #DETECTION_MANAGER self
function DETECTION_MANAGER:ReportDetected( DetectedSets )
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
  
  self.FacScheduler = SCHEDULER:New(self, self._FacScheduler, { self, "Fac" }, self._ScheduleDelayTime, self._ReportInterval )
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
        local DetectedSets = self.Detection:GetDetectedSets()
        local DetectedZones =self.Detection:GetDetectedZones()
        return self:ProcessDetected( Group, DetectedSets, DetectedZones )
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
-- @param Detection#DETECTION_BASE Detection
-- @return #FAC_REPORTING self
function FAC_REPORTING:New( SetGroup, Detection )

  -- Inherits from DETECTION_MANAGER
  local self = BASE:Inherit( self, DETECTION_MANAGER:New( SetGroup, Detection ) ) -- #FAC_REPORTING
  
  self:Schedule( 5, 60 )
  return self
end


--- Reports the detected items to the @{Set#SET_GROUP}.
-- @param #FAC_REPORTING self
-- @param Group#GROUP Group The @{Group} object to where the report needs to go.
-- @param Set#SET_BASE DetectedSets The detected Sets created by the @{Detection#DETECTION_BASE} object.
-- @return #boolean Return true if you want the reporting to continue... false will cancel the reporting loop.
function FAC_REPORTING:ProcessDetected( Group, DetectedSets, DetectedZones )
  self:F2( Group )

  self:E( Group )
  local DetectedMsg = {}
  for DetectedUnitSetID, DetectedUnitSet in pairs( DetectedSets ) do
    local UnitSet = DetectedUnitSet -- Set#SET_UNIT
    DetectedMsg[#DetectedMsg+1] = " - Group #" .. DetectedUnitSetID .. ": " .. self:GetDetectedItemsText( UnitSet )
  end  
  local FACGroup = self.Detection:GetDetectionGroups()
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
-- @extends #DETECTION_MANAGER
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


--- Assigns tasks in relation to the detected items to the @{Set#SET_GROUP}.
-- @param #TASK_DISPATCHER self
-- @param Group#GROUP Group The @{Group} object to where the report needs to go.
-- @param #table DetectedSets The detected Sets created by the @{Detection#DETECTION_BASE} object.
-- @param #table DetectedZones The detected Zones cretaed by the @{Detection#DETECTION_BASE} object.
-- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
function TASK_DISPATCHER:ProcessDetected( TaskGroup, DetectedSets, DetectedZones )
  self:F2( TaskGroup )

  local DetectedMsg = {}

  local FACGroup = self.Detection:GetDetectionGroups()
  local FACGroupName = FACGroup:GetName()

  self:E( TaskGroup )

  --- First we need to  the detected targets.
  for DetectedID, DetectedUnitSet in pairs( DetectedSets ) do
    local UnitSet = DetectedUnitSet -- Set#SET_UNIT
    local MT = {} -- Message Text
    local UnitTypes = {}

    for DetectedUnitID, DetectedUnitData in pairs( UnitSet:GetSet() ) do

      local DetectedUnit = DetectedUnitData -- Unit#UNIT
      self:E( DetectedUnit )
      local DetectedUnitName = DetectedUnit:GetName()
      local UnitType = DetectedUnit:GetTypeName()
      
      -- Determine if the set has radar targets. If it does, construct a SEAD task.
      local RadarCount = UnitSet:HasRadar( Unit.RadarType.AS )
      if RadarCount > 0 then
        local DetectedZone = DetectedZones[DetectedID]
        local Task = TASK_SEAD:New( self.Mission, UnitSet, DetectedZone, UnitSet )
        self.Mission:AddTask( Task )
        MT[#MT+1] = "SEAD task added."
      end
    end

    DetectedMsg[#DetectedMsg+1] = " - Group #" .. DetectedID .. ": " .. self:GetDetectedItemsText( UnitSet ) .. ". " .. table.concat( MT, "," )
  end
  
  self.CommandCenter:MessageToGroup( "Reporting tasks for target groups:\n" .. table.concat( DetectedMsg, "\n" ), self:GetReportDisplayTime(), TaskGroup  )
  self.Mission:FillMissionMenu( TaskGroup )

  return true
end
