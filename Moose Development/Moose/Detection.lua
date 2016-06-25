--- This module contains the DETECTION classes.
-- 
-- ===
-- 
-- 1) @{Detection#DETECTION_BASE} class, extends @{Base#BASE}
-- ==========================================================
-- The @{Detection#DETECTION_BASE} class defines the core functions to administer detected objects.
-- 
-- 1.1) DETECTION_BASE constructor
-- -------------------------------
-- Construct a new DETECTION_BASE instance using the @{Detection#DETECTION.New}() method.
-- 
-- 1.2) DETECTION_BASE initialization
-- ----------------------------------
-- By default, detection will return detected objects with all the detection sensors available.
-- However, you can ask how the objects were found with specific detection methods. 
-- If you use one of the below methods, the detection will work with the detection method specified.
-- You can specify to apply multiple detection methods.
-- 
-- Use the following functions to report the objects it detected using the methods Visual, Optical, Radar, IRST, RWR, DLINK:
-- 
--   * @{Detection#DETECTION_BASE.InitDetectVisual}(): Detected using Visual.
--   * @{Detection#DETECTION_BASE.InitDetectOptical}(): Detected using Optical.
--   * @{Detection#DETECTION_BASE.InitDetectRadar}(): Detected using Radar.
--   * @{Detection#DETECTION_BASE.InitDetectIRST}(): Detected using IRST.
--   * @{Detection#DETECTION_BASE.InitDetectRWR}(): Detected using RWR.
--   * @{Detection#DETECTION_BASE.InitDetectDLINK}(): Detected using DLINK.
-- 
-- 1.3) Obtain objects detected by DETECTION_BASE
-- ----------------------------------------------
-- DETECTION_BASE builds @{Set}s of objects detected. These @{Set#SET_BASE}s can be retrieved using the method @{Detection#DETECTION_BASE.GetDetectedSets}().
-- The method will return a list (table) of @{Set#SET_BASE} objects.
-- 
-- ===
-- 
-- 2) @{Detection#DETECTION_UNITGROUPS} class, extends @{Detection#DETECTION_BASE}
-- ===============================================================================
-- The @{Detection#DETECTION_UNITGROUPS} class will detect units within the battle zone for a FAC group, 
-- and will build a list (table) of @{Set#SET_UNIT}s containing the @{Unit#UNIT}s detected.
-- The class is group the detected units within zones given a DetectedZoneRange parameter.
-- A set with multiple detected zones will be created as there are groups of units detected.
-- 
-- 2.1) Retrieve the Detected Unit sets and Detected Zones
-- -------------------------------------------------------
-- The DetectedUnitSets methods are implemented in @{Detection#DECTECTION_BASE} and the DetectedZones methods is implemented in @{Detection#DETECTION_UNITGROUPS}.
-- 
-- Retrieve the DetectedUnitSets with the method @{Detection#DETECTION_BASE.GetDetectedSets}(). A table will be return of @{Set#SET_UNIT}s.
-- To understand the amount of sets created, use the method @{Detection#DETECTION_BASE.GetDetectedSetCount}(). 
-- If you want to obtain a specific set from the DetectedSets, use the method @{Detection#DETECTION_BASE.GetDetectedSet}() with a given index.
-- 
-- Retrieve the formed @{Zone@ZONE_UNIT}s as a result of the grouping the detected units within the DetectionZoneRange, use the method @{Detection#DETECTION_BASE.GetDetectionZones}().
-- To understand the amount of zones created, use the method @{Detection#DETECTION_BASE.GetDetectionZoneCount}(). 
-- If you want to obtain a specific zone from the DetectedZones, use the method @{Detection#DETECTION_BASE.GetDetectionZone}() with a given index.
-- 
-- 1.4) Flare or Smoke detected units
-- ----------------------------------
-- Use the methods @{Detection#DETECTION_UNITGROUPS.FlareDetectedUnits}() or @{Detection#DETECTION_UNITGROUPS.SmokeDetectedUnits}() to flare or smoke the detected units when a new detection has taken place.
-- 
-- 1.5) Flare or Smoke detected zones
-- ----------------------------------
-- Use the methods @{Detection#DETECTION_UNITGROUPS.FlareDetectedZones}() or @{Detection#DETECTION_UNITGROUPS.SmokeDetectedZones}() to flare or smoke the detected zones when a new detection has taken place.
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
-- @field #DETECTION_BASE.DetectedSets DetectedSets A list of @{Set#SET_BASE}s containing the objects in each set that were detected. The base class will not build the detected sets, but will leave that to the derived classes.
-- @extends Base#BASE
DETECTION_BASE = {
  ClassName = "DETECTION_BASE",
  DetectedSets = {},
  DetectedObjects = {},
  FACGroup = nil,
  DetectionRange = nil,
}

--- @type DETECTION_BASE.DetectedSets
-- @list <Set#SET_BASE>

 
--- @type DETECTION_BASE.DetectedZones
-- @list <Zone#ZONE_BASE>


--- DETECTION constructor.
-- @param #DETECTION_BASE self
-- @param Group#GROUP FACGroup The GROUP in the Forward Air Controller role.
-- @param DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @return #DETECTION_BASE self
function DETECTION_BASE:New( FACGroup, DetectionRange )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.FACGroup = FACGroup
  self.DetectionRange = DetectionRange
  
  self:InitDetectVisual( false )
  self:InitDetectOptical( false )
  self:InitDetectRadar( false )
  self:InitDetectRWR( false )
  self:InitDetectIRST( false )
  self:InitDetectDLINK( false )
  
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
function DETECTION_BASE:GetDetectedSets()

  local DetectionSets = self.DetectedSets
  return DetectionSets
end

--- Get the amount of SETs with detected objects.
-- @param #DETECTION_BASE self
-- @return #number Count
function DETECTION_BASE:GetDetectedSetCount()

  local DetectionSetCount = #self.DetectedSets
  return DetectionSetCount
end

--- Get a SET of detected objects using a given numeric index.
-- @param #DETECTION_BASE self
-- @param #number Index
-- @return Set#SET_BASE
function DETECTION_BASE:GetDetectedSet( Index )

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

--- Schedule the DETECTION construction.
-- @param #DETECTION_BASE self
-- @param #number DelayTime The delay in seconds to wait the reporting.
-- @param #number RepeatInterval The repeat interval in seconds for the reporting to happen repeatedly.
-- @return #DETECTION_BASE self
function DETECTION_BASE:Schedule( DelayTime, RepeatInterval )
  self:F2()

  self.ScheduleDelayTime = DelayTime
  self.ScheduleRepeatInterval = RepeatInterval
  
  self.DetectionScheduler = SCHEDULER:New(self, self._DetectionScheduler, { self, "Detection" }, DelayTime, RepeatInterval )
  return self
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

--- @type DETECTION_UNITGROUPS.DetectedSets
-- @list <Set#SET_UNIT>
--

 
--- @type DETECTION_UNITGROUPS.DetectedZones
-- @list <Zone#ZONE_UNIT>
--


--- DETECTION_UNITGROUPS class
-- @type DETECTION_UNITGROUPS
-- @param DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
-- @field #DETECTION_UNITGROUPS.DetectedSets DetectedSets A list of @{Set#SET_UNIT}s containing the units in each set that were detected within a DetectionZoneRange.
-- @field #DETECTION_UNITGROUPS.DetectedZones DetectedZones A list of @{Zone#ZONE_UNIT}s containing the zones of the reference detected units.
-- @extends Detection#DETECTION_BASE
DETECTION_UNITGROUPS = {
  ClassName = "DETECTION_UNITGROUPS",
  DetectedZones = {},
}



--- DETECTION_UNITGROUPS constructor.
-- @param Detection#DETECTION_UNITGROUPS self
-- @param Group#GROUP FACGroup The GROUP in the Forward Air Controller role.
-- @param DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @param DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
-- @return Detection#DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:New( FACGroup, DetectionRange, DetectionZoneRange )

  -- Inherits from DETECTION_BASE
  local self = BASE:Inherit( self, DETECTION_BASE:New( FACGroup, DetectionRange ) )
  self.DetectionZoneRange = DetectionZoneRange
  
  self:Schedule( 10, 30 )

  return self
end

--- Get the detected @{Zone#ZONE_UNIT}s.
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS.DetectedZones DetectedZones
function DETECTION_UNITGROUPS:GetDetectedZones()

  local DetectedZones = self.DetectedZones
  return DetectedZones
end

--- Get the amount of @{Zone#ZONE_UNIT}s with detected units.
-- @param #DETECTION_UNITGROUPS self
-- @return #number Count
function DETECTION_UNITGROUPS:GetDetectedZoneCount()

  local DetectedZoneCount = #self.DetectedZones
  return DetectedZoneCount
end

--- Get a SET of detected objects using a given numeric index.
-- @param #DETECTION_UNITGROUPS self
-- @param #number Index
-- @return Zone#ZONE_UNIT
function DETECTION_UNITGROUPS:GetDetectedZone( Index )

  local DetectedZone = self.DetectedZones[Index]
  if DetectedZone then
    return DetectedZone
  end
  
  return nil
end

--- Smoke the detected units
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:SmokeDetectedUnits()
  self:F2()

  self._SmokeDetectedUnits = true
end

--- Flare the detected units
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:SmokeDetectedUnits()
  self:F2()

  self._FlareDetectedUnits = true
end

--- Smoke the detected zones
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:SmokeDetectedZones()
  self:F2()

  self._SmokeDetectedZones = true
end

--- Flare the detected zones
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:FlareDetectedZones()
  self:F2()

  self._FlareDetectedZones = true
end


--- Make a DetectionSet table. This function will be overridden in the derived clsses.
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:CreateDetectionSets()
  self:F2()

  for DetectedUnitName, DetectedUnitData in pairs( self.DetectedObjects ) do
    self:T( DetectedUnitData.Name )
    local DetectedUnit = UNIT:FindByName( DetectedUnitData.Name ) -- Unit#UNIT
    if DetectedUnit and DetectedUnit:IsAlive() then
      self:T( DetectedUnit:GetName() )
      if #self.DetectedSets == 0 then
        self:T( { "Adding Unit Set #", 1 } )
        self.DetectedZones[1] = ZONE_UNIT:New( DetectedUnitName, DetectedUnit, self.DetectionZoneRange )
        self.DetectedSets[1] = SET_UNIT:New()
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
          self.DetectedSets[DetectedZoneIndex] = SET_UNIT:New()
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
        if self._FlareDetectedUnits then
          DetectedUnit:FlareRed()
        end
        if self._SmokeDetectedUnits then
          DetectedUnit:SmokeRed()
        end
      end
    )
    if self._FlareDetectedZones then
      DetectedZone:FlareZone( POINT_VEC3.SmokeColor.White, 30, math.random( 0,90 ) )
    end
    if self._SmokeDetectedZones then
      DetectedZone:SmokeZone( POINT_VEC3.SmokeColor.White, 30 )
    end
  end

end


