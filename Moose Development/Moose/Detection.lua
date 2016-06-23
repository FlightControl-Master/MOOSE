--- This module contains the DETECTION classes.
-- 
-- ===
-- 
-- 1) @{Detection#DETECTION_BASE} class, extends @{Base#BASE}
-- ==========================================================
-- The @{Detection#DETECTION_BASE} class defines the core functions to administer detected objects.
-- Detected objects are grouped in SETS of UNITS.
-- 
-- 1.1) DETECTION constructor:
-- ----------------------------
--   * @{Detection#DETECTION.New}(): Create a new DETECTION object.
-- 
-- 1.2) DETECTION initialization:
-- ------------------------------
-- By default, detection will return detected units with all the methods available.
-- However, you can specify which units it found with specific detection methods. 
-- If you use one of the below functions, the detection will work with the detection method specified.
-- You can specify to apply multiple detection methods.
-- Use the following functions to report the units it detected using the methods Visual, Optical, Radar, IRST, RWR, DLINK:
-- 
--    * @{Detection#DETECTION.InitDetectVisual}(): Detected using Visual.
--    * @{Detection#DETECTION.InitDetectOptical}(): Detected using Optical.
--    * @{Detection#DETECTION.InitDetectRadar}(): Detected using Radar.
--    * @{Detection#DETECTION.InitDetectIRST}(): Detected using IRST.
--    * @{Detection#DETECTION.InitDetectRWR}(): Detected using RWR.
--    * @{Detection#DETECTION.InitDetectDLINK}(): Detected using DLINK.
-- 
-- ===
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
-- @field #DETECTION_BASE.DetectedUnitZones DetectedUnitZones A list of @{Zone#ZONE_UNIT}s containing the zones of the reference detected units.
-- @extends Set#SET_BASE
DETECTION_BASE = {
  ClassName = "DETECTION_BASE",
  DetectedUnitSets = {},
  DetectedUnitZones = {},
  DetectedUnits = {},
  FACGroup = nil,
  DetectionRange = nil,
  DetectionZoneRange = nil,
}

--- @type DETECTION_BASE.DetectedUnitSets
-- @list <Set#SET_UNIT>

 
--- @type DETECTION_BASE.DetectedUnitZones
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
  
  self:InitDetectVisual( false )
  self:InitDetectOptical( false )
  self:InitDetectRadar( false )
  self:InitDetectRWR( false )
  self:InitDetectIRST( false )
  self:InitDetectDLINK( false )
  
  self.DetectionScheduler = SCHEDULER:New(self, self._DetectionScheduler, { self, "Detection" }, 10, 30, 0.2 )
  
  return self
end

--- Detect Visual.
-- @param #DETECTION_BASE self
-- @param #boolean DetectVisual
-- @return #DETECTION_BASE self
function DETECTION_BASE:InitDetectVisual( DetectVisual )

  self.DetectVisual = DetectVisual
end

--- Detect Optical.
-- @param #DETECTION_BASE self
-- @param #boolean DetectOptical
-- @return #DETECTION_BASE self
function DETECTION_BASE:InitDetectOptical( DetectOptical )
	self:F2()

  self.DetectOptical = DetectOptical
end

--- Detect Radar.
-- @param #DETECTION_BASE self
-- @param #boolean DetectRadar
-- @return #DETECTION_BASE self
function DETECTION_BASE:InitDetectRadar( DetectRadar )
  self:F2()

  self.DetectRadar = DetectRadar
end

--- Detect IRST.
-- @param #DETECTION_BASE self
-- @param #boolean DetectIRST
-- @return #DETECTION_BASE self
function DETECTION_BASE:InitDetectIRST( DetectIRST )
  self:F2()

  self.DetectIRST = DetectIRST
end

--- Detect RWR.
-- @param #DETECTION_BASE self
-- @param #boolean DetectRWR
-- @return #DETECTION_BASE self
function DETECTION_BASE:InitDetectRWR( DetectRWR )
  self:F2()

  self.DetectRWR = DetectRWR
end

--- Detect DLINK.
-- @param #DETECTION_BASE self
-- @param #boolean DetectDLINK
-- @return #DETECTION_BASE self
function DETECTION_BASE:InitDetectDLINK( DetectDLINK )
  self:F2()

  self.DetectDLINK = DetectDLINK
end

--- Gets the FAC group.
-- @param #DETECTION_BASE self
-- @return Group#GROUP self
function DETECTION_BASE:GetFACGroup()
	self:F2()

  return self.FACGroup
end

--- Get the detected @{Set#SET_UNIT}s.
-- @param #DETECTION_BASE self
-- @return #DETECTION_BASE.DetectedUnitSets DetectedUnitSets
function DETECTION_BASE:GetDetectionUnitSets()

  local DetectionUnitSets = self.DetectedUnitSets
  return DetectionUnitSets
end

--- Get the amount of SETs with detected units.
-- @param #DETECTION_BASE self
-- @return #number Count
function DETECTION_BASE:GetDetectionUnitSetCount()

  local DetectionUnitSetCount = #self.DetectedUnitSets
  return DetectionUnitSetCount
end

--- Get a SET of detected units using a given numeric index.
-- @param #DETECTION_BASE self
-- @param #number Index
-- @return Set#SET_UNIT
function DETECTION_BASE:GetDetectionUnitSet( Index )

  local DetectionUnitSet = self.DetectedUnitSets[Index]
  if DetectionUnitSet then
    return DetectionUnitSet
  end
  
  return nil
end

--- Form @{Set}s of detected @{Unit#UNIT}s in an array of @{Set#SET_UNIT}s.
-- @param #DETECTION_BASE self
function DETECTION_BASE:_DetectionScheduler( SchedulerName )
  self:F2( { SchedulerName } )
  
  self.DetectedUnitSets = {}
  self.DetectedUnitZones = {}
  
  if self.FACGroup:IsAlive() then
    local FACGroupName = self.FACGroup:GetName()
    
    local FACDetectedTargets = self.FACGroup:GetDetectedTargets(
      self.DetectVisual,
      self.DetectOptical,
      self.DetectRadar,
      self.DetectIRST,
      self.DetectRWR,
      self.DetectDLINK
    )
    
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
            self.DetectedUnitZones[1] = ZONE_UNIT:New( DetectedUnitName, DetectedUnit, self.DetectionZoneRange )
            self.DetectedUnitSets[1] = SET_UNIT:New()
            self.DetectedUnitSets[1]:AddUnit( DetectedUnit )
          else
            local AddedToSet = false
            for DetectedZoneIndex = 1, #self.DetectedUnitZones do
              self:T( "Detected Unit Set #" .. DetectedZoneIndex )
              local DetectedUnitSet = self.DetectedUnitSets[DetectedZoneIndex] -- Set#SET_UNIT
              DetectedUnitSet:Flush()
              local DetectedZone = self.DetectedUnitZones[DetectedZoneIndex] -- Zone#ZONE_UNIT
              if DetectedUnit:IsInZone( DetectedZone ) then
                self:T( "Adding to Unit Set #" .. DetectedZoneIndex )
                DetectedUnitSet:AddUnit( DetectedUnit )
                AddedToSet = true
              end
            end
            if AddedToSet == false then
              local DetectedZoneIndex = #self.DetectedUnitZones + 1
              self:T( "Adding new zone #" .. DetectedZoneIndex )
              self.DetectedUnitZones[DetectedZoneIndex] = ZONE_UNIT:New( DetectedUnitName, DetectedUnit, self.DetectionZoneRange )
              self.DetectedUnitSets[DetectedZoneIndex] = SET_UNIT:New()
              self.DetectedUnitSets[DetectedZoneIndex]:AddUnit( DetectedUnit )
            end  
          end
        end
      end
    end

    -- Now all the tests should have been build, now make some smoke and flares...
    
    for DetectedZoneIndex = 1, #self.DetectedUnitZones do
      local DetectedUnitSet = self.DetectedUnitSets[DetectedZoneIndex] -- Set#SET_UNIT
      local DetectedZone = self.DetectedUnitZones[DetectedZoneIndex] -- Zone#ZONE_UNIT
      self:T( "Detected Set #" .. DetectedZoneIndex )
      DetectedUnitSet:ForEachUnit(
        --- @param Unit#UNIT DetectedUnit
        function( DetectedUnit )
          self:T( DetectedUnit:GetName() )
          DetectedUnit:FlareRed()
        end
      )
      DetectedZone:FlareZone( POINT_VEC3.SmokeColor.White, 30, math.random( 0,90 ) )
    end
  end
end