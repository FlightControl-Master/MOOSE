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
-- @field #DETECTION_BASE.DetectedUnitSets DetectedUnitSets A list of @{Set#SET_UNIT}s containing the units in each set that were detected within a DetectedZoneRange.
-- @field #DETECTION_BASE.DetectedZones DetectedZones A list of @{Zone#ZONE_UNIT}s containing the zones of the reference detected units.
-- @extends Set#SET_BASE
DETECTION_BASE = {
  ClassName = "DETECTION_BASE",
  DetectedUnitSets = {},
  DetectedUnits = {},
  FACGroup = nil,
  DetectionRange = nil,
  DetectionZoneRange = nil,
}

--- @type DETECTION_BASE.DetectedUnitSets
-- @list <Set#SET_UNIT>

 
--- @type DETECTION_BASE.DetectedZones
-- @list <Zone#ZONE_UNIT>


--- DETECTION constructor.
-- @param #DETECTION_BASE self
-- @return #DETECTION_BASE self
function DETECTION_BASE:New( FACGroup, DetectionRange, DetectionZoneRange )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.FACGroup = FACGroup
  self.DetectionRange = DetectionRange
  self.DetectionZoneRange = DetectionZoneRange
  
  self.DetectionScheduler = SCHEDULER:New(self, self._DetectionScheduler, { self, "Detection" }, 10, 30, 0.2 )
end

--- Form @{Set}s of detected @{Unit#UNIT}s in an array of @{Set#SET_UNIT}s.
-- @param #DETECTION_BASE self
function DETECTION_BASE:_DetectionScheduler( SchedulerName )
  self:F2( { SchedulerName } )
  
  self.DetectedUnitSets = {}
  
  if self.FACGroup:IsAlive() then
    local FACGroupName = self.FACGroup:GetName()
    local FACDetectedTargets = self.FACGroup:GetDetectedTargets()
    
    for FACDetectedTargetID, FACDetectedTarget in pairs( FACDetectedTargets ) do
      local FACObject = FACDetectedTarget.object
      self:T2( FACObject )
      
      if FACObject and FACObject:isExist() and FACObject.id_ < 50000000 then

        local FACDetectedUnit = UNIT:Find( FACObject )
        local FACDetectedUnitName = FACDetectedUnit:GetName()

        local FACDetectedUnitPositionVec3 = FACDetectedUnit:GetPointVec3()
        local FACGroupPositionVec3 = self.FACGroup:GetPointVec3()
        local Distance = ( ( FACDetectedUnitPositionVec3.x - FACGroupPositionVec3.x )^2 +
          ( FACDetectedUnitPositionVec3.y - FACGroupPositionVec3.y )^2 +
          ( FACDetectedUnitPositionVec3.z - FACGroupPositionVec3.z )^2
          ) ^ 0.5 / 1000

        self:T( { FACGroupName, FACDetectedUnitName, Distance } )

        if Distance <= self.DetectionRange then

          if not self.DetectedUnits[FACDetectedUnitName] then
            self.DetectedUnits[FACDetectedUnitName] = {}
          end
          self.DetectedUnits[FACDetectedUnitName].DetectedUnit = UNIT:FindByName( FACDetectedUnitName )
          self.DetectedUnits[FACDetectedUnitName].Visible = FACDetectedTarget.visible
          self.DetectedUnits[FACDetectedUnitName].Type = FACDetectedTarget.type
          self.DetectedUnits[FACDetectedUnitName].Distance = FACDetectedTarget.distance
        else
          -- if beyond the DetectionRange then nullify...
          if self.DetectedUnits[FACDetectedUnitName] then
            self.DetectedUnits[FACDetectedUnitName] = nil
          end
        end
      end
    end

    -- okay, now we have a list of detected unit names ...
    -- Sort the table based on distance ...
    self:T( { "Sorting DetectedUnits table:", self.DetectedUnits } )
    table.sort( self.DetectedUnits, function( a, b ) return a.Distance < b.Distance end )
    self:T( { "Sorted Targets Table:", self.DetectedUnits } )
    
    -- Now group the DetectedUnits table into SET_UNITs, evaluating the DetectionZoneRange.
    
    if self.DetectedUnits then
      for DetectedUnitName, DetectedUnitData in pairs( self.DetectedUnits ) do
        local DetectedUnit = DetectedUnitData.DetectedUnit -- Unit#UNIT
        if DetectedUnit and DetectedUnit:IsAlive() then
          self:T( DetectedUnit:GetName() )
          if #self.DetectedUnitSets == 0 then
            self:T( { "Adding Unit Set #", 1 } )
            self.DetectedUnitSets[1] = {}
            self.DetectedUnitSets[1].Zone = ZONE_UNIT:New( DetectedUnitName, DetectedUnit, self.DetectionZoneRange )
            self.DetectedUnitSets[1].Set = SET_UNIT:New()
            self.DetectedUnitSets[1].Set:AddUnit( DetectedUnit )
          else
            local AddedToSet = false
            for DetectedUnitSetID, DetectedUnitSetData in pairs( self.DetectedUnitSets ) do
              self:T( "Detected Unit Set #" .. DetectedUnitSetID )
              local DetectedUnitSet = DetectedUnitSetData.Set -- Set#SET_UNIT
              local DetectedZone = DetectedUnitSetData.Zone -- Zone#ZONE_UNIT
              if DetectedUnit:IsInZone( DetectedZone ) then
                self:T( "Adding to Unit Set #" .. DetectedUnitSetID )
                self.DetectedUnitSets[DetectedUnitSetID].Set:AddUnit( DetectedUnit )
                AddedToSet = true
              end
            end
            if AddedToSet == false then
              self:T( "Adding new Unit Set #" .. #self.DetectedUnitSets+1 )
              self.DetectedUnitSets[#self.DetectedUnitSets+1] = {}
              self.DetectedUnitSets[#self.DetectedUnitSets].Zone = ZONE_UNIT:New( DetectedUnitName, DetectedUnit, self.DetectionZoneRange )
              self.DetectedUnitSets[#self.DetectedUnitSets].Set = SET_UNIT:New()
              self.DetectedUnitSets[#self.DetectedUnitSets].Set:AddUnit( DetectedUnit )
            end  
          end
        end
      end
    end

    -- Now all the tests should have been build, now make some smoke and flares...
    
    for DetectedUnitSetID, DetectedUnitSetData in pairs( self.DetectedUnitSets ) do
      local DetectedUnitSet = DetectedUnitSetData.Set -- Set#SET_UNIT
      local DetectedZone = DetectedUnitSetData.Zone -- Zone#ZONE_UNIT
      self:T( "Detected Set #" .. DetectedUnitSetID )
      DetectedUnitSet:ForEachUnit(
        --- @param Unit#UNIT DetectedUnit
        function( DetectedUnit )
          self:T( DetectedUnit:GetName() )
          DetectedUnit:FlareRed()
        end
      )
      DetectedZone:SmokeZone( POINT_VEC3.SmokeColor.White, 30 )
    end
  end
end