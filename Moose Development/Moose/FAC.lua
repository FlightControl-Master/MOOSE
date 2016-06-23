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
-- 1.1) FAC constructor:
-- ----------------------------
--   * @{Fac#FAC.New}(): Create a new FAC object.
-- 
-- 1.2) FAC initialization:
-- ------------------------------
-- 
-- ===
-- 
-- @module Fac
-- @author Mechanic : Concept & Testing
-- @author FlightControl : Design & Programming



--- FAC_BASE class
-- @type FAC_BASE
-- @field Set#SET_CLIENT ClientSet The clients to which the FAC will report to.
-- @field Detection#DETECTION_BASE Detection The DETECTION_BASE object that is used to report the detected objects.
-- @extends Set#SET_BASE
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


--- Report the detected @{Unit#UNIT}s detected within the @{DetectION#DETECTION_BASE} object to the @{Set#SET_CLIENT}s.
-- @param #FAC_BASE self
function FAC_BASE:_FacScheduler( SchedulerName )
  self:F2( { SchedulerName } )
  
  self.ClientSet:ForEachClient(
    --- @param Client#CLIENT Client
    function( Client )
      if Client:IsAlive() then
        local DetectedUnitSets = self.Detection:GetDetectionUnitSets()
        local DetectedMsg = { }
        for DetectedUnitSetID, DetectedUnitSet in pairs( DetectedUnitSets ) do
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
      end
    return true
    end
  )
  
  return true
end