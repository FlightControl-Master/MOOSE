--- This module contains the DETECTION classes.
-- 
-- ===
-- 
-- 1) @{Detection#DETECTION_BASE} class, extends @{Base#BASE}
-- ==========================================================
-- The @{Detection#DETECTION_BASE} class defines the core functions to administer detected objects.
-- The @{Detection#DETECTION_BASE} class will detect objects within the battle zone for a list of @{Group}s detecting targets following (a) detection method(s).
-- 
-- 1.1) DETECTION_BASE constructor
-- -------------------------------
-- Construct a new DETECTION_BASE instance using the @{Detection#DETECTION_BASE.New}() method.
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
-- The @{Detection#DETECTION_UNITGROUPS} class will detect units within the battle zone for a list of @{Group}s detecting targets following (a) detection method(s), 
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
-- @field Group#GROUP DetectionGroups The GROUP in the Forward Air Controller role.
-- @field DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @field #DETECTION_BASE.DetectedObjects DetectedObjects The list of detected objects.
-- @field #number DetectionRun
-- @extends Base#BASE
DETECTION_BASE = {
  ClassName = "DETECTION_BASE",
  DetectionGroups = nil,
  DetectionRange = nil,
  DetectedObjects = {},
  DetectionRun = 0,
}

--- @type DETECTION_BASE.DetectedObjects
-- @list <#DETECTION_BASE.DetectedObject>

--- @type DETECTION_BASE.DetectedObject
-- @field #string Name
-- @field #boolean Visible
-- @field #string Type
-- @field #number Distance
-- @field #boolean Identified

--- DETECTION constructor.
-- @param #DETECTION_BASE self
-- @param Group#GROUP DetectionGroups The GROUP in the Forward Air Controller role.
-- @param DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @return #DETECTION_BASE self
function DETECTION_BASE:New( DetectionGroups, DetectionRange )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.DetectionGroups = DetectionGroups
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

--- Gets a detected object with a given name.
-- @param #DETECTION_BASE self
-- @param #string ObjectName
-- @return #DETECTION_BASE.DetectedObject
function DETECTION_BASE:GetDetectedObject( ObjectName )
	self:F( ObjectName )
  
  if ObjectName then
    local DetectedObject = self.DetectedObjects[ObjectName]
    return DetectedObject
  end
  
  return nil
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

--- Get the detection Groups.
-- @param #DETECTION_BASE self
-- @return Group#GROUP
function DETECTION_BASE:GetDetectionGroups()

  local DetectionGroups = self.DetectionGroups
  return DetectionGroups
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
  self.DetectionRun = self.DetectionRun + 1
  
  if self.DetectionGroups:IsAlive() then
    local DetectionGroupsName = self.DetectionGroups:GetName()
    
    local DetectionDetectedTargets = self.DetectionGroups:GetDetectedTargets(
      self.DetectVisual,
      self.DetectOptical,
      self.DetectRadar,
      self.DetectIRST,
      self.DetectRWR,
      self.DetectDLINK
    )
    
    for DetectionDetectedTargetID, DetectionDetectedTarget in pairs( DetectionDetectedTargets ) do
      local DetectionObject = DetectionDetectedTarget.object -- DCSObject#Object
      self:T2( DetectionObject )
      
      if DetectionObject and DetectionObject:isExist() and DetectionObject.id_ < 50000000 then

        local DetectionDetectedObjectName = DetectionObject:getName()

        local DetectionDetectedObjectPositionVec3 = DetectionObject:getPoint()
        local DetectionGroupsPositionVec3 = self.DetectionGroups:GetPointVec3()

        local Distance = ( ( DetectionDetectedObjectPositionVec3.x - DetectionGroupsPositionVec3.x )^2 +
          ( DetectionDetectedObjectPositionVec3.y - DetectionGroupsPositionVec3.y )^2 +
          ( DetectionDetectedObjectPositionVec3.z - DetectionGroupsPositionVec3.z )^2
          ) ^ 0.5 / 1000

        self:T2( { DetectionGroupsName, DetectionDetectedObjectName, Distance } )

        if Distance <= self.DetectionRange then

          if not self.DetectedObjects[DetectionDetectedObjectName] then
            self.DetectedObjects[DetectionDetectedObjectName] = {}
          end
          self.DetectedObjects[DetectionDetectedObjectName].Name = DetectionDetectedObjectName
          self.DetectedObjects[DetectionDetectedObjectName].Visible = DetectionDetectedTarget.visible
          self.DetectedObjects[DetectionDetectedObjectName].Type = DetectionDetectedTarget.type
          self.DetectedObjects[DetectionDetectedObjectName].Distance = DetectionDetectedTarget.distance
          self.DetectedObjects[DetectionDetectedObjectName].Identified = false -- This flag is used to control identification.
        else
          -- if beyond the DetectionRange then nullify...
          if self.DetectedObjects[DetectionDetectedObjectName] then
            self.DetectedObjects[DetectionDetectedObjectName] = nil
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
-- @field DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
-- @field #DETECTION_UNITGROUPS.DetectedAreas DetectedAreas A list of areas containing the set of @{Unit}s, @{Zone}s, the center @{Unit} within the zone, and ID of each area that was detected within a DetectionZoneRange.
-- @extends Detection#DETECTION_BASE
DETECTION_UNITGROUPS = {
  ClassName = "DETECTION_UNITGROUPS",
  DetectedAreas = { n = 0 },
  DetectionZoneRange = nil,
}

--- @type DETECTION_UNITGROUPS.DetectedAreas
-- @list <#DETECTION_UNITGROUPS.DetectedArea>

--- @type DETECTION_UNITGROUPS.DetectedArea
-- @field Set#SET_UNIT Set -- The Set of Units in the detected area.
-- @field Zone#ZONE_UNIT Zone -- The Zone of the detected area.
-- @field #number AreaID -- The identifier of the detected area.


--- DETECTION_UNITGROUPS constructor.
-- @param Detection#DETECTION_UNITGROUPS self
-- @param Group#GROUP DetectionGroups The GROUP in the Forward Air Controller role.
-- @param DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @param DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
-- @return Detection#DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:New( DetectionGroups, DetectionRange, DetectionZoneRange )

  -- Inherits from DETECTION_BASE
  local self = BASE:Inherit( self, DETECTION_BASE:New( DetectionGroups, DetectionRange ) )

  self.DetectionZoneRange = DetectionZoneRange
  
  self:Schedule( 10, 30 )

  return self
end

--- Add a detected @{#DETECTION_UNITGROUPS.DetectedArea}.
-- @param Set#SET_UNIT Set -- The Set of Units in the detected area.
-- @param Zone#ZONE_UNIT Zone -- The Zone of the detected area.
-- @return #DETECTION_UNITGROUPS.DetectedArea DetectedArea
function DETECTION_UNITGROUPS:AddDetectedArea( Set, Zone )
  local DetectedAreas = self:GetDetectedAreas()
  DetectedAreas.n = self:GetDetectedAreaCount() + 1
  DetectedAreas[DetectedAreas.n] = {}
  local DetectedArea = DetectedAreas[DetectedAreas.n]
  DetectedArea.Set = Set
  DetectedArea.Zone = Zone
  DetectedArea.AreaID = #DetectedAreas
  return DetectedArea
end

--- Remove a detected @{#DETECTION_UNITGROUPS.DetectedArea} with a given Index.
-- @param #DETECTION_UNITGROUPS self
-- @param #number Index The Index of the detection are to be removed.
-- @return #nil
function DETECTION_UNITGROUPS:RemoveDetectedArea( Index )
  local DetectedAreas = self:GetDetectedAreas()
  local DetectedAreaCount = self:GetDetectedAreaCount()
  DetectedAreas[Index] = nil
  DetectedAreas.n = DetectedAreas.n - 1
  return nil
end


--- Get the detected @{#DETECTION_UNITGROUPS.DetectedAreas}.
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS.DetectedAreas DetectedAreas
function DETECTION_UNITGROUPS:GetDetectedAreas()

  local DetectedAreas = self.DetectedAreas
  return DetectedAreas
end

--- Get the amount of @{#DETECTION_UNITGROUPS.DetectedAreas}.
-- @param #DETECTION_UNITGROUPS self
-- @return #number DetectedAreaCount
function DETECTION_UNITGROUPS:GetDetectedAreaCount()

  local DetectedAreaCount = self.DetectedAreas.n
  return DetectedAreaCount
end

--- Get the @{Set#SET_UNIT} of a detecttion area using a given numeric index.
-- @param #DETECTION_UNITGROUPS self
-- @param #number Index
-- @return Set#SET_UNIT DetectedSet
function DETECTION_UNITGROUPS:GetDetectedSet( Index )

  local DetectedSetUnit = self.DetectedAreas[Index].Set
  if DetectedSetUnit then
    return DetectedSetUnit
  end
  
  return nil
end

--- Get the @{Zone#ZONE_UNIT} of a detection area using a given numeric index.
-- @param #DETECTION_UNITGROUPS self
-- @param #number Index
-- @return Zone#ZONE_UNIT DetectedZone
function DETECTION_UNITGROUPS:GetDetectedZone( Index )

  local DetectedZone = self.DetectedAreas[Index].Zone
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
  return self
end

--- Flare the detected units
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:FlareDetectedUnits()
  self:F2()

  self._FlareDetectedUnits = true
  return self
end

--- Smoke the detected zones
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:SmokeDetectedZones()
  self:F2()

  self._SmokeDetectedZones = true
  return self
end

--- Flare the detected zones
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:FlareDetectedZones()
  self:F2()

  self._FlareDetectedZones = true
  return self
end


--- Make a DetectionSet table. This function will be overridden in the derived clsses.
-- @param #DETECTION_UNITGROUPS self
-- @return #DETECTION_UNITGROUPS self
function DETECTION_UNITGROUPS:CreateDetectionSets()
  self:F2()

  -- First go through all detected sets, and check if there are new detected units, match all existing detected units and identify undetected units.
  -- Regroup when needed, split groups when needed.
  for DetectedAreaID, DetectedAreaData in ipairs( self.DetectedAreas ) do
    
    local DetectedArea = DetectedAreaData -- #DETECTION_UNITGROUPS.DetectedArea
    if DetectedArea then
    
      local DetectedSet = DetectedArea.Set
      local DetectedZone = DetectedArea.Zone
      
      -- first test if the center unit is detected in the detection area.

      local AreaExists = false -- This flag will determine of the detected area is still existing.
            
      local DetectedObject = self:GetDetectedObject( DetectedArea.Zone.ZoneUNIT.UnitName )
      self:T( DetectedObject )
      if DetectedObject then
        DetectedObject.Identified = true
        AreaExists = true
        self:T( { DetectedArea = DetectedArea.AreaID, "Detected Center Unit " .. DetectedArea.Zone.ZoneUNIT.UnitName } )
      else
        -- The center object of the detected area has not been detected. Find an other unit of the set to become the center of the area.
        -- First remove the center unit from the set.
        DetectedSet:RemoveUnitsByName( DetectedArea.Zone.ZoneUNIT.UnitName )
        self:T( { DetectedArea = DetectedArea.AreaID, "Removed Center Unit " .. DetectedArea.Zone.ZoneUNIT.UnitName } )
        for DetectedUnitName, DetectedUnitData in pairs( DetectedSet:GetSet() ) do
          local DetectedUnit = DetectedUnitData -- Unit#UNIT
          local DetectedObject = self:GetDetectedObject( DetectedUnit.UnitName )
          if DetectedObject then
            if DetectedObject.Identified == false and DetectedUnit:IsAlive() then
              DetectedObject.Identified = true
              AreaExists = true
              -- Assign the Unit as the new center unit of the detected area.
              DetectedArea.Zone = ZONE_UNIT:New( DetectedUnit:GetName(), DetectedUnit, self.DetectionZoneRange )
              self:T( { DetectedArea = DetectedArea.AreaID, "New Center Unit " .. DetectedArea.Zone.ZoneUNIT.UnitName } )
              break
            end
          end
        end
      end
      
      -- Now we've determined the center unit of the area, now we can iterate the units in the detected area.
      -- Note that the position of the area may have moved due to the center unit repositioning.
      -- If no center unit was identified, then the detected area does not exist anymore and should be deleted, as there are no valid units that can be the center unit.
      if AreaExists then
        -- ok, we found the center unit of the area, now iterate through the detected area set and see which units are still within the center unit zone ...
        -- Those units within the zone are flagged as Identified.
        -- If a unit was not found in the set, remove it from the set. This may be added later to other existing or new sets.
        for DetectedUnitName, DetectedUnitData in pairs( DetectedSet:GetSet() ) do
          local DetectedUnit = DetectedUnitData -- Unit#UNIT
          local DetectedObject = self:GetDetectedObject( DetectedUnit:GetName() )
          if DetectedObject then
            if DetectedObject.Identified == false then
              if DetectedUnit:IsInZone( DetectedZone ) then
                DetectedObject.Identified = true
                self:T( { DetectedArea = DetectedArea.AreaID, "Unit in zone " .. DetectedUnit.UnitName } )
              else
                -- Not anymore in the zone. Remove from the set.
                DetectedSet:Remove( DetectedUnitName )
                self:T( { DetectedArea = DetectedArea.AreaID, "Unit not in zone " .. DetectedUnit.UnitName } )
              end
            end
          else
            -- The detected object has not been found, delete from the Set!
            DetectedSet:Remove( DetectedUnitName )
            self:T( { DetectedArea = DetectedArea.AreaID, "Unit not found " .. DetectedUnit.UnitName } )
          end
        end
      else
        self:T( { DetectedArea = DetectedArea.AreaID, "Removed detected area " } )
        self:RemoveDetectedArea( DetectedAreaID )
      end
    end
  end
  
  -- We iterated through the existing detection areas and:
  --  - We checked which units are still detected in each detection area. Those units were flagged as Identified.
  --  - We recentered the detection area to new center units where it was needed.
  --
  -- Now we need to loop through the unidentified detected units and see where they belong:
  --  - They can be added to a new detection area and become the new center unit.
  --  - They can be added to a new detection area.
  for DetectedUnitName, DetectedObjectData in pairs( self.DetectedObjects ) do
    
    local DetectedObject = DetectedObjectData -- #DETECTION_BASE.DetectedObject
    
    if DetectedObject.Identified == false then
      -- We found an unidentified unit outside of any existing detection area.
      
      local DetectedUnit = UNIT:FindByName( DetectedObjectData.Name ) -- Unit#UNIT
      
      if DetectedUnit and DetectedUnit:IsAlive() then
        self:T( { "Search for " .. DetectedObjectData.Name, DetectedObjectData.Identified } )

        local AddedToDetectionArea = false
        for DetectedAreaID, DetectedAreaData in ipairs( self.DetectedAreas ) do
          
          local DetectedArea = DetectedAreaData -- #DETECTION_UNITGROUPS.DetectedArea
          if DetectedArea then
            self:T( "Detection Area #" .. DetectedArea.AreaID )
            local DetectedSet = DetectedArea.Set
            local DetectedZone = DetectedArea.Zone -- Zone#ZONE_UNIT
            if DetectedUnit:IsInZone( DetectedZone ) then
              DetectedSet:AddUnit( DetectedUnit )
              AddedToDetectionArea = true
              DetectedObject.Identified = true
              self:T( "Detection Area #" .. DetectedArea.AreaID .. " added unit " .. DetectedUnit.UnitName )
            end
          end
        end
        if AddedToDetectionArea == false then
          -- New detection area
          local DetectedArea = self:AddDetectedArea( 
            SET_UNIT:New(),
            ZONE_UNIT:New( DetectedUnitName, DetectedUnit, self.DetectionZoneRange )
          )
          self:T( { "Added Detection Area #", DetectedArea.AreaID } )
          DetectedArea.Set:AddUnit( DetectedUnit )
          self:T( "Detection Area #" .. DetectedArea.AreaID .. " added unit " .. DetectedUnit.UnitName )
          DetectedObject.Identified = true
        end  
      end
    end
  end
  
  -- Now all the tests should have been build, now make some smoke and flares...
  
  for DetectedAreaID, DetectedAreaData in ipairs( self.DetectedAreas ) do

    
    local DetectedArea = DetectedAreaData -- #DETECTION_UNITGROUPS.DetectedArea
    local DetectedSet = DetectedArea.Set
    local DetectedZone = DetectedArea.Zone
    DetectedZone.ZoneUNIT:SmokeRed()
    DetectedSet:ForEachUnit(
      --- @param Unit#UNIT DetectedUnit
      function( DetectedUnit )
        self:T( "Detected Set #" .. DetectedArea.AreaID .. ":" .. DetectedUnit:GetName() )
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


