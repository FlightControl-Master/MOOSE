--- This module contains the DETECTION classes.
-- 
-- ===
-- 
-- 1) @{Detection#DETECTION_BASE} class, extends @{Base#BASE}
-- ==========================================================
-- The @{Detection#DETECTION_BASE} class defines the core functions to administer detected objects.
-- Detected objects are grouped in SETS of UNITS.
-- 
-- 1.1) DETECTION_BASE constructor:
-- --------------------------------
--   * @{Detection#DETECTION.New}(): Create a new DETECTION object.
-- 
-- 1.2) DETECTION_BASE initialization:
-- -----------------------------------
-- By default, detection will return detected objects with all the methods available.
-- However, you can ask how the objects were found with specific detection methods. 
-- If you use one of the below methods, the detection will work with the detection method specified.
-- You can specify to apply multiple detection methods.
-- Use the following functions to report the objects it detected using the methods Visual, Optical, Radar, IRST, RWR, DLINK:
-- 
--    * @{Detection#DETECTION.InitDetectVisual}(): Detected using Visual.
--    * @{Detection#DETECTION.InitDetectOptical}(): Detected using Optical.
--    * @{Detection#DETECTION.InitDetectRadar}(): Detected using Radar.
--    * @{Detection#DETECTION.InitDetectIRST}(): Detected using IRST.
--    * @{Detection#DETECTION.InitDetectRWR}(): Detected using RWR.
--    * @{Detection#DETECTION.InitDetectDLINK}(): Detected using DLINK.
-- 
-- 1.3) Obtain objects detected by DETECTION_BASE:
-- -----------------------------------------------
-- DETECTION_BASE builds @{Set}s of objects detected. These @{Set#SET_BASE}s can be retrieved using the method @{Detection#DETECTION_BASE.GetDetectedSets}().
-- The method will return a list (table) of @{Set#SET_BASE} objects.
-- 
-- 2) @{Detection#DETECTION_UNITGROUPS} class, extends @{Detection#DETECTION_BASE}
-- ===============================================================================
-- The @{Detection#DETECTION_UNITGROUPS} class will detect units within the battle zone for a FAC group, 
-- and will build a list (table) of @{Set#SET_UNIT}s containing the @{Unit#UNIT}s detected.
-- 
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
-- @field #DETECTION_BASE.DetectedSets DetectedSets A list of @{Set#SET_BASE}s containing the objects in each set that were detected within a DetectedZoneRange.
-- @field #DETECTION_BASE.DetectedZones DetectedZones A list of @{Zone#ZONE_BASE}s containing the zones of the reference detected objects.
-- @extends Set#SET_BASE
DETECTION_BASE = {
  ClassName = "DETECTION_BASE",
  DetectedSets = {},
  DetectedObjects = {},
  FACGroup = nil,
  DetectionRange = nil,
  DetectionZoneRange = nil,
}

--- @type DETECTION_BASE.DetectedSets
-- @list <Set#SET_BASE>

 
--- @type DETECTION_BASE.DetectedZones
-- @list <Zone#ZONE_BASE>


--- DETECTION constructor.
-- @param #DETECTION_BASE self
-- @param Group#GROUP FACGroup The GROUP in the Forward Air Controller role.
-- @param DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @param DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
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

--- Get the detected @{Set#SET_BASE}s.
-- @param #DETECTION_BASE self
-- @return #DETECTION_BASE.DetectedSets DetectedSets
function DETECTION_BASE:GetDetectionSets()

  local DetectionSets = self.DetectedSets
  return DetectionSets
end

--- Get the amount of SETs with detected objects.
-- @param #DETECTION_BASE self
-- @return #number Count
function DETECTION_BASE:GetDetectionSetCount()

  local DetectionSetCount = #self.DetectedSets
  return DetectionSetCount
end

--- Get a SET of detected objects using a given numeric index.
-- @param #DETECTION_BASE self
-- @param #number Index
-- @return Set#SET_BASE
function DETECTION_BASE:GetDetectionSet( Index )

  local DetectionSet = self.DetectedSets[Index]
  if DetectionSet then
    return DetectionSet
  end
  
  return nil
end

--- Make a DetectionSet table. This function will be overridden in the derived clsses.
-- @param #DETECTION_BASE self
-- @return #DETECTION_BASE self
function DETECTION_BASE:CreateDetectionSets()
	self:F2()

  self:E( "Error, in DETECTION_BASE class..." )

end

--- Form @{Set}s of detected @{Unit#UNIT}s in an array of @{Set#SET_BASE}s.
-- @param #DETECTION_BASE self
function DETECTION_BASE:_DetectionScheduler( SchedulerName )
  self:F2( { SchedulerName } )
  
  self.DetectedObjects = {}
  self.DetectedSets = {}
  self.DetectedZones = {}
  
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
      local FACObject = FACDetectedTarget.object -- DCSObject#Object
      self:T2( FACObject )
      
      if FACObject and FACObject:isExist() and FACObject.id_ < 50000000 then

        local FACDetectedObjectName = FACObject:getName()

        local FACDetectedObjectPositionVec3 = FACObject:getPoint()
        local FACGroupPositionVec3 = self.FACGroup:GetPointVec3()

        local Distance = ( ( FACDetectedObjectPositionVec3.x - FACGroupPositionVec3.x )^2 +
          ( FACDetectedObjectPositionVec3.y - FACGroupPositionVec3.y )^2 +
          ( FACDetectedObjectPositionVec3.z - FACGroupPositionVec3.z )^2
          ) ^ 0.5 / 1000

        self:T( { FACGroupName, FACDetectedObjectName, Distance } )

        if Distance <= self.DetectionRange then

          if not self.DetectedObjects[FACDetectedObjectName] then
            self.DetectedObjects[FACDetectedObjectName] = {}
          end
          self.DetectedObjects[FACDetectedObjectName].Name = FACDetectedObjectName
          self.DetectedObjects[FACDetectedObjectName].Visible = FACDetectedTarget.visible
          self.DetectedObjects[FACDetectedObjectName].Type = FACDetectedTarget.type
          self.DetectedObjects[FACDetectedObjectName].Distance = FACDetectedTarget.distance
        else
          -- if beyond the DetectionRange then nullify...
          if self.DetectedObjects[FACDetectedObjectName] then
            self.DetectedObjects[FACDetectedObjectName] = nil
          end
        end
      end
    end
    
    self:T2( self.DetectedObjects )

    -- okay, now we have a list of detected object names ...
    -- Sort the table based on distance ...
    self:T( { "Sorting DetectedObjects table:", self.DetectedObjects } )
    table.sort( self.DetectedObjects, function( a, b ) return a.Distance < b.Distance end )
    self:T( { "Sorted Targets Table:", self.DetectedObjects } )
    
    -- Now group the DetectedObjects table into SET_BASEs, evaluating the DetectionZoneRange.
    
    if self.DetectedObjects then
      self:CreateDetectionSets()
    end


  end
end



--- DETECTION_UNITGROUPS class
-- @type DETECTION_UNITGROUPS
-- @field #DETECTION_UNITGROUPS.DetectedSets DetectedSets A list of @{Set#SET_UNIT}s containing the units in each set that were detected within a DetectedZoneRange.
-- @field #DETECTION_UNITGROUPS.DetectedZones DetectedZones A list of @{Zone#ZONE_UNIT}s containing the zones of the reference detected units.
-- @extends Set#SET_BASE
DETECTION_UNITGROUPS = {
  ClassName = "DETECTION_UNITGROUPS",
  DetectedZones = {},
}

--- @type DETECTION_UNITGROUPS.DetectedSets
-- @list <Set#SET_UNIT>

 
--- @type DETECTION_UNITGROUPS.DetectedZones
-- @list <Zone#ZONE_UNIT>


--- DETECTION_UNITGROUPS constructor.
-- @param #DETECTION_UNITGROUPS self
-- @field Group#GROUP FACGroup The GROUP in the Forward Air Controller role.
-- @field DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @field DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:New( FACGroup, DetectionRange, DetectionZoneRange )

  -- Inherits from DETECTION_BASE
  local self = BASE:Inherit( self, DETECTION_BASE:New( FACGroup, DetectionRange, DetectionZoneRange ) )
  
  return self
end


--- Make a DetectionSet table. This function will be overridden in the derived clsses.
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:CreateDetectionSets()
  self:F2()

  for DetectedUnitName, DetectedUnitData in pairs( self.DetectedObjects ) do
    local DetectedUnit = UNIT:FindByName( DetectedUnitData.Name ) -- Unit#UNIT
    if DetectedUnit and DetectedUnit:IsAlive() then
      self:T( DetectedUnit:GetName() )
      if #self.DetectedSets == 0 then
        self:T( { "Adding Unit Set #", 1 } )
        self.DetectedZones[1] = ZONE_UNIT:New( DetectedUnitName, DetectedUnit, self.DetectionZoneRange )
        self.DetectedSets[1] = SET_BASE:New()
        self.DetectedSets[1]:AddUnit( DetectedUnit )
      else
        local AddedToSet = false
        for DetectedZoneIndex = 1, #self.DetectedZones do
          self:T( "Detected Unit Set #" .. DetectedZoneIndex )
          local DetectedUnitSet = self.DetectedSets[DetectedZoneIndex] -- Set#SET_BASE
          DetectedUnitSet:Flush()
          local DetectedZone = self.DetectedZones[DetectedZoneIndex] -- Zone#ZONE_UNIT
          if DetectedUnit:IsInZone( DetectedZone ) then
            self:T( "Adding to Unit Set #" .. DetectedZoneIndex )
            DetectedUnitSet:AddUnit( DetectedUnit )
            AddedToSet = true
          end
        end
        if AddedToSet == false then
          local DetectedZoneIndex = #self.DetectedZones + 1
          self:T( "Adding new zone #" .. DetectedZoneIndex )
          self.DetectedZones[DetectedZoneIndex] = ZONE_UNIT:New( DetectedUnitName, DetectedUnit, self.DetectionZoneRange )
          self.DetectedSets[DetectedZoneIndex] = SET_BASE:New()
          self.DetectedSets[DetectedZoneIndex]:AddUnit( DetectedUnit )
        end  
      end
    end
  end
  
  -- Now all the tests should have been build, now make some smoke and flares...
  
  for DetectedZoneIndex = 1, #self.DetectedZones do
    local DetectedUnitSet = self.DetectedSets[DetectedZoneIndex] -- Set#SET_BASE
    local DetectedZone = self.DetectedZones[DetectedZoneIndex] -- Zone#ZONE_UNIT
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


