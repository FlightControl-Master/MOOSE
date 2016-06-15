--- This module contains the DETECTION classes.
-- 
-- ===
-- 
-- 1) @{Detection#DETECTION_BASE} class, extends @{Base#BASE}
-- =====================================================
-- The @{Detection#DETECTION_BASE} class defines the core functions to administer detected objects.
-- Detected objects are grouped in SETS of UNITS.
-- 
-- @module Detection
-- @author Mechanic : Concept & Testing
-- @author FlightControl : Design & Programming

--- DETECTION_BASE class
-- @type DETECTION_BASE
-- @field Group#GROUP FACGroup The GROUP in the Forward Air Controller role.
-- @field DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @field DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
-- @extends Set#SET_BASE
DETECTION_BASE = {
  ClassName = "DETECTION_BASE",
  Sets = {},
  FACGroup = nil,
  DetectionRange = nil,
  DetectionZoneRange = nil,
}

--- DETECTION constructor.
-- @param #DETECTION_BASE self
-- @return #DETECTION_BASE self
function DETECTION_BASE:New( FACGroup, DetectionRange, DetectionZoneRange )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.FACGroup = FACGroup
  self.DetectionRange = DetectionRange
  self.DetectionZoneRange = DetectionZoneRange
  
  self.DetectionScheduler = SCHEDULER:New(self, self._DetectionScheduler, { self, "Detection" }, 1, 30, 0.2 )
end

--- Form @{Set}s of detected @{Unit#UNIT}s in an array of @{Set#SET_UNIT}s.
-- @param #DETECTION_BASE self
function DETECTION_BASE:_DetectionScheduler( SchedulerName )
  self:F2( { SchedulerName } )
  
  self.Sets = {}
  
  if self.FACGroup:IsAlive() then
    local FACGroupName = self.FACGroup:GetName()
    local FACDetectedTargets = self.FACGroup:GetDetectedTargets()
    
    for FACDetectedTargetID, FACDetectedTarget in pairs( FACDetectedTargets ) do
      local FACObject = FACDetectedTarget.object
      self:T2( FACObject )
      
      if FACObject and FACObject:isExist() and FACObject.id_ < 50000000 then

        local FACDetectedTargetUnit = UNIT:Find( FACObject )
        local FACDetectedTargetUnitName = FACDetectedTargetUnit:GetName()

        local FACDetectedTargetUnitPositionVec3 = FACDetectedTargetUnit:GetPointVec3()
        local FACGroupPositionVec3 = self.FACGroup:GetPointVec3()
        local Distance = ( ( FACDetectedTargetUnitPositionVec3.x - FACGroupPositionVec3.x )^2 +
          ( FACDetectedTargetUnitPositionVec3.y - FACGroupPositionVec3.y )^2 +
          ( FACDetectedTargetUnitPositionVec3.z - FACGroupPositionVec3.z )^2
          ) ^ 0.5 / 1000

        self:T( { self.FACGroup:GetName(), FACDetectedTargetUnit:GetName(), Distance } )

        if Distance <= self then

          if not ClientEscortTargets[EscortTargetUnitName] then
            ClientEscortTargets[EscortTargetUnitName] = {}
          end
          ClientEscortTargets[EscortTargetUnitName].AttackUnit = FACDetectedTargetUnit
          ClientEscortTargets[EscortTargetUnitName].visible = EscortTarget.visible
          ClientEscortTargets[EscortTargetUnitName].type = EscortTarget.type
          ClientEscortTargets[EscortTargetUnitName].distance = EscortTarget.distance
        else
          if ClientEscortTargets[EscortTargetUnitName] then
            ClientEscortTargets[EscortTargetUnitName] = nil
          end
        end
      end
    
    end
    
  end
  
end