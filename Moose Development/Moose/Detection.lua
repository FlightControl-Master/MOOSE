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
-- 2) @{Detection#DETECTION_AREAS} class, extends @{Detection#DETECTION_BASE}
-- ===============================================================================
-- The @{Detection#DETECTION_AREAS} class will detect units within the battle zone for a list of @{Group}s detecting targets following (a) detection method(s), 
-- and will build a list (table) of @{Set#SET_UNIT}s containing the @{Unit#UNIT}s detected.
-- The class is group the detected units within zones given a DetectedZoneRange parameter.
-- A set with multiple detected zones will be created as there are groups of units detected.
-- 
-- 2.1) Retrieve the Detected Unit sets and Detected Zones
-- -------------------------------------------------------
-- The DetectedUnitSets methods are implemented in @{Detection#DECTECTION_BASE} and the DetectedZones methods is implemented in @{Detection#DETECTION_AREAS}.
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
-- Use the methods @{Detection#DETECTION_AREAS.FlareDetectedUnits}() or @{Detection#DETECTION_AREAS.SmokeDetectedUnits}() to flare or smoke the detected units when a new detection has taken place.
-- 
-- 1.5) Flare or Smoke detected zones
-- ----------------------------------
-- Use the methods @{Detection#DETECTION_AREAS.FlareDetectedZones}() or @{Detection#DETECTION_AREAS.SmokeDetectedZones}() to flare or smoke the detected zones when a new detection has taken place.
-- 
-- ===
-- 
-- ### Contributions: 
-- 
--   * Mechanist : Concept & Testing
-- 
-- ### Authors: 
-- 
--   * FlightControl : Design & Programming
-- 
-- @module Detection



--- DETECTION_BASE class
-- @type DETECTION_BASE
-- @field Set#SET_GROUP DetectionSetGroup The @{Set} of GROUPs in the Forward Air Controller role.
-- @field DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @field #DETECTION_BASE.DetectedObjects DetectedObjects The list of detected objects.
-- @field #table DetectedObjectsIdentified Map of the DetectedObjects identified.
-- @field #number DetectionRun
-- @extends Base#BASE
DETECTION_BASE = {
  ClassName = "DETECTION_BASE",
  DetectionSetGroup = nil,
  DetectionRange = nil,
  DetectedObjects = {},
  DetectionRun = 0,
  DetectedObjectsIdentified = {},
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
-- @param Set#SET_GROUP DetectionSetGroup The @{Set} of GROUPs in the Forward Air Controller role.
-- @param DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @return #DETECTION_BASE self
function DETECTION_BASE:New( DetectionSetGroup, DetectionRange )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.DetectionSetGroup = DetectionSetGroup
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

--- Determines if a detected object has already been identified during detection processing.
-- @param #DETECTION_BASE self
-- @param #DETECTION_BASE.DetectedObject DetectedObject
-- @return #boolean true if already identified.
function DETECTION_BASE:IsDetectedObjectIdentified( DetectedObject )
  self:F3( DetectedObject.Name )

  local DetectedObjectName = DetectedObject.Name
  local DetectedObjectIdentified = self.DetectedObjectsIdentified[DetectedObjectName] == true
  self:T3( DetectedObjectIdentified )
  return DetectedObjectIdentified
end

--- Identifies a detected object during detection processing.
-- @param #DETECTION_BASE self
-- @param #DETECTION_BASE.DetectedObject DetectedObject
function DETECTION_BASE:IdentifyDetectedObject( DetectedObject )
  self:F( DetectedObject.Name )

  local DetectedObjectName = DetectedObject.Name
  self.DetectedObjectsIdentified[DetectedObjectName] = true
end

--- UnIdentify a detected object during detection processing.
-- @param #DETECTION_BASE self
-- @param #DETECTION_BASE.DetectedObject DetectedObject
function DETECTION_BASE:UnIdentifyDetectedObject( DetectedObject )

  local DetectedObjectName = DetectedObject.Name
  self.DetectedObjectsIdentified[DetectedObjectName] = false
end

--- UnIdentify all detected objects during detection processing.
-- @param #DETECTION_BASE self
function DETECTION_BASE:UnIdentifyAllDetectedObjects()

  self.DetectedObjectsIdentified = {} -- Table will be garbage collected.
end

--- Gets a detected object with a given name.
-- @param #DETECTION_BASE self
-- @param #string ObjectName
-- @return #DETECTION_BASE.DetectedObject
function DETECTION_BASE:GetDetectedObject( ObjectName )
	self:F3( ObjectName )
  
  if ObjectName then
    local DetectedObject = self.DetectedObjects[ObjectName]

    -- Only return detected objects that are alive!
    local DetectedUnit = UNIT:FindByName( ObjectName )
    if DetectedUnit and DetectedUnit:IsAlive() then
      if self:IsDetectedObjectIdentified( DetectedObject ) == false then
        return DetectedObject
      end
    end
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
function DETECTION_BASE:GetDetectionSetGroup()

  local DetectionSetGroup = self.DetectionSetGroup
  return DetectionSetGroup
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
  
  self.DetectionRun = self.DetectionRun + 1
  
  self:UnIdentifyAllDetectedObjects() -- Resets the DetectedObjectsIdentified table
  
  for DetectionGroupID, DetectionGroupData in pairs( self.DetectionSetGroup:GetSet() ) do
    local DetectionGroup = DetectionGroupData -- Group#GROUP

    if DetectionGroup:IsAlive() then

      local DetectionGroupName = DetectionGroup:GetName()
      
      local DetectionDetectedTargets = DetectionGroup:GetDetectedTargets(
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
          local DetectionGroupPositionVec3 = DetectionGroup:GetPointVec3()
  
          local Distance = ( ( DetectionDetectedObjectPositionVec3.x - DetectionGroupPositionVec3.x )^2 +
            ( DetectionDetectedObjectPositionVec3.y - DetectionGroupPositionVec3.y )^2 +
            ( DetectionDetectedObjectPositionVec3.z - DetectionGroupPositionVec3.z )^2
            ) ^ 0.5 / 1000
  
          self:T2( { DetectionGroupName, DetectionDetectedObjectName, Distance } )
  
          if Distance <= self.DetectionRange then
  
            if not self.DetectedObjects[DetectionDetectedObjectName] then
              self.DetectedObjects[DetectionDetectedObjectName] = {}
            end
            self.DetectedObjects[DetectionDetectedObjectName].Name = DetectionDetectedObjectName
            self.DetectedObjects[DetectionDetectedObjectName].Visible = DetectionDetectedTarget.visible
            self.DetectedObjects[DetectionDetectedObjectName].Type = DetectionDetectedTarget.type
            self.DetectedObjects[DetectionDetectedObjectName].Distance = DetectionDetectedTarget.distance
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
      table.sort( self.DetectedObjects, function( a, b ) return a.Distance < b.Distance end )
    end
  end

  if self.DetectedObjects then
    self:CreateDetectionSets()
  end

  return true
end



--- DETECTION_AREAS class
-- @type DETECTION_AREAS
-- @field DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
-- @field #DETECTION_AREAS.DetectedAreas DetectedAreas A list of areas containing the set of @{Unit}s, @{Zone}s, the center @{Unit} within the zone, and ID of each area that was detected within a DetectionZoneRange.
-- @extends Detection#DETECTION_BASE
DETECTION_AREAS = {
  ClassName = "DETECTION_AREAS",
  DetectedAreas = { n = 0 },
  DetectionZoneRange = nil,
}

--- @type DETECTION_AREAS.DetectedAreas
-- @list <#DETECTION_AREAS.DetectedArea>

--- @type DETECTION_AREAS.DetectedArea
-- @field Set#SET_UNIT Set -- The Set of Units in the detected area.
-- @field Zone#ZONE_UNIT Zone -- The Zone of the detected area.
-- @field #boolean Changed Documents if the detected area has changes.
-- @field #table Changes A list of the changes reported on the detected area. (It is up to the user of the detected area to consume those changes).
-- @field #number AreaID -- The identifier of the detected area.
-- @field #boolean FriendliesNearBy Indicates if there are friendlies within the detected area.
-- @field Unit#UNIT NearestFAC The nearest FAC near the Area.


--- DETECTION_AREAS constructor.
-- @param Detection#DETECTION_AREAS self
-- @param Set#SET_GROUP DetectionSetGroup The @{Set} of GROUPs in the Forward Air Controller role.
-- @param DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
-- @param DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
-- @return Detection#DETECTION_AREAS self
function DETECTION_AREAS:New( DetectionSetGroup, DetectionRange, DetectionZoneRange )

  -- Inherits from DETECTION_BASE
  local self = BASE:Inherit( self, DETECTION_BASE:New( DetectionSetGroup, DetectionRange ) )

  self.DetectionZoneRange = DetectionZoneRange
  
  self._SmokeDetectedUnits = false
  self._FlareDetectedUnits = false
  self._SmokeDetectedZones = false
  self._FlareDetectedZones = false
  
  self:Schedule( 0, 30 )

  return self
end

--- Add a detected @{#DETECTION_AREAS.DetectedArea}.
-- @param Set#SET_UNIT Set -- The Set of Units in the detected area.
-- @param Zone#ZONE_UNIT Zone -- The Zone of the detected area.
-- @return #DETECTION_AREAS.DetectedArea DetectedArea
function DETECTION_AREAS:AddDetectedArea( Set, Zone )
  local DetectedAreas = self:GetDetectedAreas()
  DetectedAreas.n = self:GetDetectedAreaCount() + 1
  DetectedAreas[DetectedAreas.n] = {}
  local DetectedArea = DetectedAreas[DetectedAreas.n]
  DetectedArea.Set = Set
  DetectedArea.Zone = Zone
  DetectedArea.Removed = false
  DetectedArea.AreaID = DetectedAreas.n
  
  return DetectedArea
end

--- Remove a detected @{#DETECTION_AREAS.DetectedArea} with a given Index.
-- @param #DETECTION_AREAS self
-- @param #number Index The Index of the detection are to be removed.
-- @return #nil
function DETECTION_AREAS:RemoveDetectedArea( Index )
  local DetectedAreas = self:GetDetectedAreas()
  local DetectedAreaCount = self:GetDetectedAreaCount()
  local DetectedArea = DetectedAreas[Index]
  local DetectedAreaSet = DetectedArea.Set
  DetectedArea[Index] = nil
  return nil
end


--- Get the detected @{#DETECTION_AREAS.DetectedAreas}.
-- @param #DETECTION_AREAS self
-- @return #DETECTION_AREAS.DetectedAreas DetectedAreas
function DETECTION_AREAS:GetDetectedAreas()

  local DetectedAreas = self.DetectedAreas
  return DetectedAreas
end

--- Get the amount of @{#DETECTION_AREAS.DetectedAreas}.
-- @param #DETECTION_AREAS self
-- @return #number DetectedAreaCount
function DETECTION_AREAS:GetDetectedAreaCount()

  local DetectedAreaCount = self.DetectedAreas.n
  return DetectedAreaCount
end

--- Get the @{Set#SET_UNIT} of a detecttion area using a given numeric index.
-- @param #DETECTION_AREAS self
-- @param #number Index
-- @return Set#SET_UNIT DetectedSet
function DETECTION_AREAS:GetDetectedSet( Index )

  local DetectedSetUnit = self.DetectedAreas[Index].Set
  if DetectedSetUnit then
    return DetectedSetUnit
  end
  
  return nil
end

--- Get the @{Zone#ZONE_UNIT} of a detection area using a given numeric index.
-- @param #DETECTION_AREAS self
-- @param #number Index
-- @return Zone#ZONE_UNIT DetectedZone
function DETECTION_AREAS:GetDetectedZone( Index )

  local DetectedZone = self.DetectedAreas[Index].Zone
  if DetectedZone then
    return DetectedZone
  end
  
  return nil
end

--- Background worker function to determine if there are friendlies nearby ...
-- @param #DETECTION_AREAS self
-- @param Unit#UNIT ReportUnit
function DETECTION_AREAS:ReportFriendliesNearBy( ReportGroupData )
  self:F2()
  
  local DetectedArea = ReportGroupData.DetectedArea  -- Detection#DETECTION_AREAS.DetectedArea    
  local DetectedSet = ReportGroupData.DetectedArea.Set
  local DetectedZone = ReportGroupData.DetectedArea.Zone
  local DetectedZoneUnit = DetectedZone.ZoneUNIT

  DetectedArea.FriendliesNearBy = false
  
  local SphereSearch = {
   id = world.VolumeType.SPHERE,
    params = {
     point = DetectedZoneUnit:GetPointVec3(),
     radius = 6000,
    }
    
   }
   
   --- @param DCSUnit#Unit FoundDCSUnit
   -- @param Group#GROUP ReportGroup
   -- @param Set#SET_GROUP ReportSetGroup
   local FindNearByFriendlies = function( FoundDCSUnit, ReportGroupData )
      
      local DetectedArea = ReportGroupData.DetectedArea  -- Detection#DETECTION_AREAS.DetectedArea    
      local DetectedSet = ReportGroupData.DetectedArea.Set
      local DetectedZone = ReportGroupData.DetectedArea.Zone
      local DetectedZoneUnit = DetectedZone.ZoneUNIT -- Unit#UNIT
      local ReportSetGroup = ReportGroupData.ReportSetGroup

      local EnemyCoalition = DetectedZoneUnit:GetCoalition()
      
      local FoundUnitCoalition = FoundDCSUnit:getCoalition()
      local FoundUnitName = FoundDCSUnit:getName()
      local FoundUnitGroupName = FoundDCSUnit:getGroup():getName()
      local EnemyUnitName = DetectedZoneUnit:GetName()
      local FoundUnitInReportSetGroup = ReportSetGroup:FindGroup( FoundUnitGroupName ) ~= nil
      
      self:T3( { "Friendlies search:", FoundUnitName, FoundUnitCoalition, EnemyUnitName, EnemyCoalition, FoundUnitInReportSetGroup } )
      
      if FoundUnitCoalition ~= EnemyCoalition and FoundUnitInReportSetGroup == false then
        DetectedArea.FriendliesNearBy = true
        return false
      end
      
      return true
  end
  
  world.searchObjects( Object.Category.UNIT, SphereSearch, FindNearByFriendlies, ReportGroupData )

end



--- Returns if there are friendlies nearby the FAC units ...
-- @param #DETECTION_AREAS self
-- @return #boolean trhe if there are friendlies nearby 
function DETECTION_AREAS:IsFriendliesNearBy( DetectedArea )
  
  self:T3( DetectedArea.FriendliesNearBy )
  return DetectedArea.FriendliesNearBy or false
end

--- Calculate the maxium A2G threat level of the DetectedArea.
-- @param #DETECTION_AREAS self
-- @param #DETECTION_AREAS.DetectedArea DetectedArea
function DETECTION_AREAS:CalculateThreatLevelA2G( DetectedArea )
  
  local MaxThreatLevelA2G = 0
  for UnitName, UnitData in pairs( DetectedArea.Set:GetSet() ) do
    local ThreatUnit = UnitData -- Unit#UNIT
    local ThreatLevelA2G = ThreatUnit:GetThreatLevel()
    if ThreatLevelA2G > MaxThreatLevelA2G then
      MaxThreatLevelA2G = ThreatLevelA2G
    end
  end

  self:T3( MaxThreatLevelA2G )
  DetectedArea.MaxThreatLevelA2G = MaxThreatLevelA2G
  
end

--- Find the nearest FAC of the DetectedArea.
-- @param #DETECTION_AREAS self
-- @param #DETECTION_AREAS.DetectedArea DetectedArea
-- @return Unit#UNIT The nearest FAC unit
function DETECTION_AREAS:NearestFAC( DetectedArea )
  
  local NearestFAC = nil
  local MinDistance = 1000000000 -- Units are not further than 1000000 km away from an area :-)
  
  for FACGroupName, FACGroupData in pairs( self.DetectionSetGroup:GetSet() ) do
    for FACUnit, FACUnitData in pairs( FACGroupData:GetUnits() ) do
      local FACUnit = FACUnitData -- Unit#UNIT
      if FACUnit:IsActive() then
        local Vec3 = FACUnit:GetPointVec3()
        local PointVec3 = POINT_VEC3:NewFromVec3( Vec3 )
        local Distance = PointVec3:Get2DDistance(POINT_VEC3:NewFromVec3( FACUnit:GetPointVec3() ) )
        if Distance < MinDistance then
          MinDistance = Distance
          NearestFAC = FACUnit
        end
      end
    end
  end

  DetectedArea.NearestFAC = NearestFAC
  
end

--- Returns the A2G threat level of the units in the DetectedArea
-- @param #DETECTION_AREAS self
-- @param #DETECTION_AREAS.DetectedArea DetectedArea
-- @return #number a scale from 0 to 10. 
function DETECTION_AREAS:GetTreatLevelA2G( DetectedArea )
  
  self:T3( DetectedArea.MaxThreatLevelA2G )
  return DetectedArea.MaxThreatLevelA2G
end



--- Smoke the detected units
-- @param #DETECTION_AREAS self
-- @return #DETECTION_AREAS self
function DETECTION_AREAS:SmokeDetectedUnits()
  self:F2()

  self._SmokeDetectedUnits = true
  return self
end

--- Flare the detected units
-- @param #DETECTION_AREAS self
-- @return #DETECTION_AREAS self
function DETECTION_AREAS:FlareDetectedUnits()
  self:F2()

  self._FlareDetectedUnits = true
  return self
end

--- Smoke the detected zones
-- @param #DETECTION_AREAS self
-- @return #DETECTION_AREAS self
function DETECTION_AREAS:SmokeDetectedZones()
  self:F2()

  self._SmokeDetectedZones = true
  return self
end

--- Flare the detected zones
-- @param #DETECTION_AREAS self
-- @return #DETECTION_AREAS self
function DETECTION_AREAS:FlareDetectedZones()
  self:F2()

  self._FlareDetectedZones = true
  return self
end

--- Add a change to the detected zone.
-- @param #DETECTION_AREAS self
-- @param #DETECTION_AREAS.DetectedArea DetectedArea
-- @param #string ChangeCode
-- @return #DETECTION_AREAS self
function DETECTION_AREAS:AddChangeArea( DetectedArea, ChangeCode, AreaUnitType )

  DetectedArea.Changed = true
  local AreaID = DetectedArea.AreaID
  
  DetectedArea.Changes = DetectedArea.Changes or {}
  DetectedArea.Changes[ChangeCode] = DetectedArea.Changes[ChangeCode] or {}
  DetectedArea.Changes[ChangeCode].AreaID = AreaID
  DetectedArea.Changes[ChangeCode].AreaUnitType = AreaUnitType

  self:T( { "Change on Detection Area:", DetectedArea.AreaID, ChangeCode, AreaUnitType } )

  return self
end


--- Add a change to the detected zone.
-- @param #DETECTION_AREAS self
-- @param #DETECTION_AREAS.DetectedArea DetectedArea
-- @param #string ChangeCode
-- @param #string ChangeUnitType
-- @return #DETECTION_AREAS self
function DETECTION_AREAS:AddChangeUnit( DetectedArea, ChangeCode, ChangeUnitType )

  DetectedArea.Changed = true
  local AreaID = DetectedArea.AreaID
  
  DetectedArea.Changes = DetectedArea.Changes or {}
  DetectedArea.Changes[ChangeCode] = DetectedArea.Changes[ChangeCode] or {}
  DetectedArea.Changes[ChangeCode][ChangeUnitType] = DetectedArea.Changes[ChangeCode][ChangeUnitType] or 0
  DetectedArea.Changes[ChangeCode][ChangeUnitType] = DetectedArea.Changes[ChangeCode][ChangeUnitType] + 1
  DetectedArea.Changes[ChangeCode].AreaID = AreaID
  
  self:T( { "Change on Detection Area:", DetectedArea.AreaID, ChangeCode, ChangeUnitType } )

  return self
end

--- Make text documenting the changes of the detected zone.
-- @param #DETECTION_AREAS self
-- @param #DETECTION_AREAS.DetectedArea DetectedArea
-- @return #string The Changes text
function DETECTION_AREAS:GetChangeText( DetectedArea )
  self:F( DetectedArea )
  
  local MT = {}
  
  for ChangeCode, ChangeData in pairs( DetectedArea.Changes ) do

    if ChangeCode == "AA" then
      MT[#MT+1] = "Detected new area " .. ChangeData.AreaID .. ". The center target is a " .. ChangeData.AreaUnitType .. "."
    end

    if ChangeCode == "RAU" then
      MT[#MT+1] = "Changed area " .. ChangeData.AreaID .. ". Removed the center target."
    end
    
    if ChangeCode == "AAU" then
      MT[#MT+1] = "Changed area " .. ChangeData.AreaID .. ". The new center target is a " .. ChangeData.AreaUnitType "."
    end
    
    if ChangeCode == "RA" then
      MT[#MT+1] = "Removed old area " .. ChangeData.AreaID .. ". No more targets in this area."
    end
    
    if ChangeCode == "AU" then
      local MTUT = {}
      for ChangeUnitType, ChangeUnitCount in pairs( ChangeData ) do
        if ChangeUnitType  ~= "AreaID" then
          MTUT[#MTUT+1] = ChangeUnitCount .. " of " .. ChangeUnitType
        end
      end
      MT[#MT+1] = "Detected for area " .. ChangeData.AreaID .. " new target(s) " .. table.concat( MTUT, ", " ) .. "."
    end

    if ChangeCode == "RU" then
      local MTUT = {}
      for ChangeUnitType, ChangeUnitCount in pairs( ChangeData ) do
        if ChangeUnitType  ~= "AreaID" then
          MTUT[#MTUT+1] = ChangeUnitCount .. " of " .. ChangeUnitType
        end
      end
      MT[#MT+1] = "Removed for area " .. ChangeData.AreaID .. " invisible or destroyed target(s) " .. table.concat( MTUT, ", " ) .. "."
    end
    
  end
  
  return table.concat( MT, "\n" )
  
end


--- Accepts changes from the detected zone.
-- @param #DETECTION_AREAS self
-- @param #DETECTION_AREAS.DetectedArea DetectedArea
-- @return #DETECTION_AREAS self
function DETECTION_AREAS:AcceptChanges( DetectedArea )

  DetectedArea.Changed = false
  DetectedArea.Changes = {}

  return self
end


--- Make a DetectionSet table. This function will be overridden in the derived clsses.
-- @param #DETECTION_AREAS self
-- @return #DETECTION_AREAS self
function DETECTION_AREAS:CreateDetectionSets()
  self:F2()

  -- First go through all detected sets, and check if there are new detected units, match all existing detected units and identify undetected units.
  -- Regroup when needed, split groups when needed.
  for DetectedAreaID, DetectedAreaData in ipairs( self.DetectedAreas ) do
    
    local DetectedArea = DetectedAreaData -- #DETECTION_AREAS.DetectedArea
    if DetectedArea then
    
      local DetectedSet = DetectedArea.Set
      
      local AreaExists = false -- This flag will determine of the detected area is still existing.
            
      -- First test if the center unit is detected in the detection area.
      self:T3( DetectedArea.Zone.ZoneUNIT.UnitName )
      local DetectedZoneObject = self:GetDetectedObject( DetectedArea.Zone.ZoneUNIT.UnitName )
      self:T3( { "Detecting Zone Object", DetectedArea.AreaID, DetectedArea.Zone, DetectedZoneObject } )
      
      if DetectedZoneObject then

        --self:IdentifyDetectedObject( DetectedZoneObject )
        AreaExists = true


      
      else
        -- The center object of the detected area has not been detected. Find an other unit of the set to become the center of the area.
        -- First remove the center unit from the set.
        DetectedSet:RemoveUnitsByName( DetectedArea.Zone.ZoneUNIT.UnitName )

        self:AddChangeArea( DetectedArea, 'RAU', "Dummy" )
        
        -- Then search for a new center area unit within the set. Note that the new area unit candidate must be within the area range.
        for DetectedUnitName, DetectedUnitData in pairs( DetectedSet:GetSet() ) do
 
          local DetectedUnit = DetectedUnitData -- Unit#UNIT
          local DetectedObject = self:GetDetectedObject( DetectedUnit.UnitName ) 

          -- The DetectedObject can be nil when the DetectedUnit is not alive anymore or it is not in the DetectedObjects map.
          -- If the DetectedUnit was already identified, DetectedObject will be nil.
          if DetectedObject then
            self:IdentifyDetectedObject( DetectedObject )
            AreaExists = true

            -- Assign the Unit as the new center unit of the detected area.
            DetectedArea.Zone = ZONE_UNIT:New( DetectedUnit:GetName(), DetectedUnit, self.DetectionZoneRange )

            self:AddChangeArea( DetectedArea, "AAU", DetectedArea.Zone.ZoneUNIT:GetTypeName() )

            -- We don't need to add the DetectedObject to the area set, because it is already there ...
            break
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
          local DetectedObject = nil
          if DetectedUnit:IsAlive() then
          --self:E(DetectedUnit:GetName())
            DetectedObject = self:GetDetectedObject( DetectedUnit:GetName() )
          end
          if DetectedObject then
          
            -- Check if the DetectedUnit is within the DetectedArea.Zone
            if DetectedUnit:IsInZone( DetectedArea.Zone ) then
              
              -- Yes, the DetectedUnit is within the DetectedArea.Zone, no changes, DetectedUnit can be kept within the Set.
              self:IdentifyDetectedObject( DetectedObject )

            else
              -- No, the DetectedUnit is not within the DetectedArea.Zone, remove DetectedUnit from the Set.
              DetectedSet:Remove( DetectedUnitName )
              self:AddChangeUnit( DetectedArea, "RU", DetectedUnit:GetTypeName() )
            end
          
          else
            -- There was no DetectedObject, remove DetectedUnit from the Set.
            self:AddChangeUnit( DetectedArea, "RU", "destroyed target" )
            DetectedSet:Remove( DetectedUnitName )

            -- The DetectedObject has been identified, because it does not exist ...
            -- self:IdentifyDetectedObject( DetectedObject )
          end
        end
      else
        self:RemoveDetectedArea( DetectedAreaID )
        self:AddChangeArea( DetectedArea, "RA" )
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
    
    local DetectedObject = self:GetDetectedObject( DetectedUnitName )
    
    if DetectedObject then

      -- We found an unidentified unit outside of any existing detection area.
      local DetectedUnit = UNIT:FindByName( DetectedUnitName ) -- Unit#UNIT
      
      local AddedToDetectionArea = false
    
      for DetectedAreaID, DetectedAreaData in ipairs( self.DetectedAreas ) do
        
        local DetectedArea = DetectedAreaData -- #DETECTION_AREAS.DetectedArea
        if DetectedArea then
          self:T( "Detection Area #" .. DetectedArea.AreaID )
          local DetectedSet = DetectedArea.Set
          if not self:IsDetectedObjectIdentified( DetectedObject ) and DetectedUnit:IsInZone( DetectedArea.Zone ) then
            self:IdentifyDetectedObject( DetectedObject )
            DetectedSet:AddUnit( DetectedUnit )
            AddedToDetectionArea = true
            self:AddChangeUnit( DetectedArea, "AU", DetectedUnit:GetTypeName() )
          end
        end
      end
    
      if AddedToDetectionArea == false then
      
        -- New detection area
        local DetectedArea = self:AddDetectedArea( 
          SET_UNIT:New(),
          ZONE_UNIT:New( DetectedUnitName, DetectedUnit, self.DetectionZoneRange )
        )
        --self:E( DetectedArea.Zone.ZoneUNIT.UnitName )
        DetectedArea.Set:AddUnit( DetectedUnit )
        self:AddChangeArea( DetectedArea, "AA", DetectedUnit:GetTypeName() )
      end  
    end
  end
  
  -- Now all the tests should have been build, now make some smoke and flares...
  -- We also report here the friendlies within the detected areas.
  
  for DetectedAreaID, DetectedAreaData in ipairs( self.DetectedAreas ) do

    local DetectedArea = DetectedAreaData -- #DETECTION_AREAS.DetectedArea
    local DetectedSet = DetectedArea.Set
    local DetectedZone = DetectedArea.Zone

    self:ReportFriendliesNearBy( { DetectedArea = DetectedArea, ReportSetGroup = self.DetectionSetGroup } ) -- Fill the Friendlies table
    self:CalculateThreatLevelA2G( DetectedArea )  -- Calculate A2G threat level
    self:NearestFAC( DetectedArea )

    if DETECTION_AREAS._SmokeDetectedUnits or self._SmokeDetectedUnits then
      DetectedZone.ZoneUNIT:SmokeRed()
    end
    DetectedSet:ForEachUnit(
      --- @param Unit#UNIT DetectedUnit
      function( DetectedUnit )
        if DetectedUnit:IsAlive() then
          self:T( "Detected Set #" .. DetectedArea.AreaID .. ":" .. DetectedUnit:GetName() )
          if DETECTION_AREAS._FlareDetectedUnits or self._FlareDetectedUnits then
            DetectedUnit:FlareGreen()
          end
          if DETECTION_AREAS._SmokeDetectedUnits or self._SmokeDetectedUnits then
            DetectedUnit:SmokeGreen()
          end
        end
      end
    )
    if DETECTION_AREAS._FlareDetectedZones or self._FlareDetectedZones then
      DetectedZone:FlareZone( POINT_VEC3.SmokeColor.White, 30, math.random( 0,90 ) )
    end
    if DETECTION_AREAS._SmokeDetectedZones or self._SmokeDetectedZones then
      DetectedZone:SmokeZone( POINT_VEC3.SmokeColor.White, 30 )
    end
  end

end


