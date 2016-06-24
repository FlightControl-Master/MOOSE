--- This module contains the FAC classes.
-- 
-- ===
-- 
-- 1) @{Fac#FAC_BASE} class, extends @{Base#BASE}
-- ==============================================
-- The @{Fac#FAC_BASE} class defines the core functions to report detected objects to:
-- 
--    * CLIENTS
--    * COALITIONS
--    
-- Detected objects are grouped in SETS of UNITS.
-- 
-- 1.1) FAC_BASE constructor:
-- ----------------------------
--   * @{Fac#FAC_BASE.New}(): Create a new FAC_BASE instance.
-- 
-- 1.2) FAC_BASE reporting:
-- ------------------------
-- Derived FAC_BASE classes will reports detected units using the method @{Fac#FAC_BASE.ReportDetected}(). This method implements polymorphic behaviour.
-- The time interval in seconds of the reporting can be changed using the methods @{Fac#FAC_BASE.SetReportInterval}(). 
-- Reporting can be started and stopped using the methods @{Fac#FAC_BASE.StartReporting}() and @{Fac#FAC_BASE.StopReporting}() respectively.
-- If an ad-hoc report is requested, use the method @{Fac#FAC_BASE#ReportNow}().
-- 
-- ===
-- 
-- 2) @{Fac#FAC_REPORTING} class, extends @{Fac#FAC_BASE}
-- ======================================================
-- The @{Fac#FAC_REPORTING} class implements detected units reporting. Reporting can be controlled using the reporting methods available in the @{Fac#FAC_BASE} class.
-- 
-- 2.1) FAC_REPORTING constructor:
-- -------------------------------
--    * @{Fac#FAC_REPORTING.New}(): Create a new FAC_REPORTING instance.
--    
-- ===
-- 
-- @module Fac
-- @author Mechanic, Prof_Hilactic, FlightControl : Concept & Testing
-- @author FlightControl : Design & Programming



--- FAC_BASE class.
-- @type FAC_BASE
-- @field Set#SET_CLIENT ClientSet The clients to which the FAC will report to.
-- @field Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
-- @extends Base#BASE
FAC_BASE = {
  ClassName = "FAC_BASE",
  ClientSet = nil,
  Detection = nil,
}

--- FAC constructor.
-- @param #FAC_BASE self
-- @param Set#SET_CLIENT ClientSet
-- @param Detection#DETECTION_BASE Detection
-- @return #FAC_BASE self
function FAC_BASE:New( ClientSet, Detection )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.ClientSet = ClientSet
  self.Detection = Detection

  self.FacScheduler = SCHEDULER:New(self, self._FacScheduler, { self, "Fac" }, 5, 15 )
  
  return self
end

--- Reports the detected items to the @{Set#SET_CLIENT}.
-- @param #FAC_BASE self
-- @param Set#SET_BASE DetectedSets The detected Sets created by the @{Detection#DETECTION_BASE} object.
-- @return #FAC_BASE self
function FAC_BASE:ReportDetected( DetectedSets )
	self:F2()

  

end

--- Schedule the FAC reporting.
-- @param #FAC_BASE self
-- @param #number DelayTime The delay in seconds to wait the reporting.
-- @param #number RepeatInterval The repeat interval in seconds for the reporting to happen repeatedly.
-- @return #FAC_BASE self
function FAC_BASE:Schedule( DelayTime, RepeatInterval )
	self:F2()

  self.ScheduleDelayTime = DelayTime
  self.ScheduleRepeatInterval = RepeatInterval
  
  self.FacScheduler = SCHEDULER:New(self, self._FacScheduler, { self, "Fac" }, DelayTime, RepeatInterval )
  return self
end

--- Report the detected @{Unit#UNIT}s detected within the @{DetectION#DETECTION_BASE} object to the @{Set#SET_CLIENT}s.
-- @param #FAC_BASE self
function FAC_BASE:_FacScheduler( SchedulerName )
  self:F2( { SchedulerName } )
  
  self.ClientSet:ForEachClient(
    --- @param Client#CLIENT Client
    function( Client )
      if Client:IsAlive() then
        local DetectedSets = self.Detection:GetDetectionSets()
        return self:ReportDetected( Client, DetectedSets )
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
-- @extends #FAC_BASE
FAC_REPORTING = {
  ClassName = "FAC_REPORTING",
}


--- FAC_REPORTING constructor.
-- @param #FAC_REPORTING self
-- @param Set#SET_CLIENT ClientSet
-- @param Detection#DETECTION_BASE Detection
-- @return #FAC_REPORTING self
function FAC_REPORTING:New( ClientSet, Detection )

  -- Inherits from FAC_BASE
  local self = BASE:Inherit( self, FAC_BASE:New( ClientSet, Detection ) ) -- #FAC_REPORTING
  
  self:Schedule( 5, 15 )
  return self
end


--- Reports the detected items to the @{Set#SET_CLIENT}.
-- @param #FAC_REPORTING self
-- @param Client#CLIENT Client The @{Client} object to where the report needs to go.
-- @param Set#SET_BASE DetectedSets The detected Sets created by the @{Detection#DETECTION_BASE} object.
-- @return #boolean Return true if you want the reporting to continue... false will cancel the reporting loop.
function FAC_REPORTING:ReportDetected( Client, DetectedSets )
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
  FACGroup:MessageToClient( "Reporting detected target groups:\n" .. table.concat( DetectedMsg, "\n" ), 12, Client  )

  return true
end

