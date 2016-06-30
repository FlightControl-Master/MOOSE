--- This module contains the FAC classes.
-- 
-- ===
-- 
-- 1) @{Fac#DETECTION_MANAGER} class, extends @{Base#BASE}
-- ==============================================
-- The @{Fac#DETECTION_MANAGER} class defines the core functions to report detected objects to clients.
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
-- @field Set#SET_CLIENT ClientSet The clients to which the FAC will report to.
-- @field Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
-- @extends Base#BASE
DETECTION_MANAGER = {
  ClassName = "DETECTION_MANAGER",
  ClientSet = nil,
  Detection = nil,
}

--- FAC constructor.
-- @param #DETECTION_MANAGER self
-- @param Set#SET_CLIENT ClientSet
-- @param Detection#DETECTION_BASE Detection
-- @return #DETECTION_MANAGER self
function DETECTION_MANAGER:New( ClientSet, Detection )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() ) -- Fac#DETECTION_MANAGER
  
  self.ClientSet = ClientSet
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

--- Reports the detected items to the @{Set#SET_CLIENT}.
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

--- Report the detected @{Unit#UNIT}s detected within the @{DetectION#DETECTION_BASE} object to the @{Set#SET_CLIENT}s.
-- @param #DETECTION_MANAGER self
function DETECTION_MANAGER:_FacScheduler( SchedulerName )
  self:F2( { SchedulerName } )
  
  self.ClientSet:ForEachClient(
    --- @param Client#CLIENT Client
    function( Client )
      if Client:IsAlive() then
        local DetectedSets = self.Detection:GetDetectedSets()
        return self:ProcessDetected( Client, DetectedSets )
      end
    end
  )
  
  return true
end

-- FAC_REPORTING

--- FAC_REPORTING class.
-- @type FAC_REPORTING
-- @field Set#SET_CLIENT ClientSet The clients to which the FAC will report to.
-- @field Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
-- @extends #DETECTION_MANAGER
FAC_REPORTING = {
  ClassName = "FAC_REPORTING",
}


--- FAC_REPORTING constructor.
-- @param #FAC_REPORTING self
-- @param Set#SET_CLIENT ClientSet
-- @param Detection#DETECTION_BASE Detection
-- @return #FAC_REPORTING self
function FAC_REPORTING:New( ClientSet, Detection )

  -- Inherits from DETECTION_MANAGER
  local self = BASE:Inherit( self, DETECTION_MANAGER:New( ClientSet, Detection ) ) -- #FAC_REPORTING
  
  self:Schedule( 5, 60 )
  return self
end


--- Reports the detected items to the @{Set#SET_CLIENT}.
-- @param #FAC_REPORTING self
-- @param Client#CLIENT Client The @{Client} object to where the report needs to go.
-- @param Set#SET_BASE DetectedSets The detected Sets created by the @{Detection#DETECTION_BASE} object.
-- @return #boolean Return true if you want the reporting to continue... false will cancel the reporting loop.
function FAC_REPORTING:ProcessDetected( Client, DetectedSets )
  self:F2( Client )

  local DetectedMsg = {}
  for DetectedUnitSetID, DetectedUnitSet in pairs( DetectedSets ) do
    local UnitSet = DetectedUnitSet -- Set#SET_UNIT
    local MT = {} -- Message Text
    local UnitTypes = {}
    for DetectedUnitID, DetectedUnitData in pairs( UnitSet:GetSet() ) do
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
    DetectedMsg[#DetectedMsg+1] = " - Group #" .. DetectedUnitSetID .. ": " .. MessageText
  end  
  local FACGroup = self.Detection:GetFACGroup()
  FACGroup:MessageToClient( "Reporting detected target groups:\n" .. table.concat( DetectedMsg, "\n" ), self:GetReportDisplayTime(), Client  )

  return true
end


--- TASK_DISPATCHER

--- TASK_DISPATCHER class.
-- @type TASK_DISPATCHER
-- @field Set#SET_CLIENT ClientSet The clients to which the FAC will report to.
-- @field Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
-- @extends #DETECTION_MANAGER
TASK_DISPATCHER = {
  ClassName = "TASK_DISPATCHER",
}


--- TASK_DISPATCHER constructor.
-- @param #TASK_DISPATCHER self
-- @param Set#SET_CLIENT ClientSet
-- @param Detection#DETECTION_BASE Detection
-- @return #TASK_DISPATCHER self
function TASK_DISPATCHER:New( ClientSet, Detection, TaskType, Priority )

  -- Inherits from DETECTION_MANAGER
  local self = BASE:Inherit( self, DETECTION_MANAGER:New( ClientSet, Detection ) ) -- #TASK_DISPATCHER
  
  self:Schedule( 5, 60 )
  return self
end


--- Assigns tasks in relation to the detected items to the @{Set#SET_CLIENT}.
-- @param #FAC_REPORTING self
-- @param Client#CLIENT Client The @{Client} object to where the report needs to go.
-- @param Set#SET_BASE DetectedSets The detected Sets created by the @{Detection#DETECTION_BASE} object.
-- @param Mission#MISSIONSCHEDULER MissionScheduler
-- @param #string TaskID The task to be executed.
-- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
function TASK_DISPATCHER:ProcessDetected( Client, DetectedSets, MissionScheduler, Targets )
  self:F2( Client )

  local DetectedMsg = {}

  local FACGroup = self.Detection:GetFACGroup()
  local FACGroupName = FACGroup:GetName()

  for DetectedUnitSetID, DetectedUnitSet in pairs( DetectedSets ) do
    local UnitSet = DetectedUnitSet -- Set#SET_UNIT
    local MT = {} -- Message Text
    local UnitTypes = {}
    if not MissionScheduler.FindMission( FACGroupName ) then
      local Mission = MISSION:New()
      MissionScheduler.AddMission(Mission)
    end

    for DetectedUnitID, DetectedUnitData in pairs( UnitSet:GetSet() ) do

      local DetectedUnit = DetectedUnitData -- Unit#UNIT
      local UnitType = DetectedUnit:GetTypeName()
      local DetectedUnitName = DetectedUnit:GetName()
      
      if Task:GetTarget( DetectedUnitName ) then
        if not UnitTypes[UnitType] then
          UnitTypes[UnitType] = 1
        else
          UnitTypes[UnitType] = UnitTypes[UnitType] + 1
        end
        Task:AddTarget( DetectedUnit )
      end
    end

    for UnitTypeID, UnitType in pairs( UnitTypes ) do
      MT[#MT+1] = Task:GetCommand() .. " " .. UnitType .. " of " .. UnitTypeID
    end

    local MessageText = table.concat( MT, ", " )
    DetectedMsg[#DetectedMsg+1] = " - Group #" .. DetectedUnitSetID .. ": " .. MessageText
  end
  
  Task:Assign( Client )
  local FACGroup = self.Detection:GetFACGroup()
  FACGroup:MessageToClient( "Reporting detected target groups:\n" .. table.concat( DetectedMsg, "\n" ), self:GetReportDisplayTime(), Client  )

  return true
end
