do -- DETECTION_ZONES

  --- @type DETECTION_ZONES
  -- @field DCS#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
  -- @field #DETECTION_BASE.DetectedItems DetectedItems A list of areas containing the set of @{Wrapper.Unit}s, @{Zone}s, the center @{Wrapper.Unit} within the zone, and ID of each area that was detected within a DetectionZoneRange.
  -- @extends Functional.Detection#DETECTION_BASE

  --- (old, to be revised ) Detect units within the battle zone for a list of @{Core.Zone}s detecting targets following (a) detection method(s), 
  -- and will build a list (table) of @{Core.Set#SET_UNIT}s containing the @{Wrapper.Unit#UNIT}s detected.
  -- The class is group the detected units within zones given a DetectedZoneRange parameter.
  -- A set with multiple detected zones will be created as there are groups of units detected.
  -- 
  -- ## 4.1) Retrieve the Detected Unit Sets and Detected Zones
  -- 
  -- The methods to manage the DetectedItems[].Set(s) are implemented in @{Functional.Detection#DECTECTION_BASE} and 
  -- the methods to manage the DetectedItems[].Zone(s) is implemented in @{Functional.Detection#DETECTION_ZONES}.
  -- 
  -- Retrieve the DetectedItems[].Set with the method @{Functional.Detection#DETECTION_BASE.GetDetectedSet}(). A @{Core.Set#SET_UNIT} object will be returned.
  -- 
  -- Retrieve the formed @{Zone@ZONE_UNIT}s as a result of the grouping the detected units within the DetectionZoneRange, use the method @{Functional.Detection#DETECTION_BASE.GetDetectionZones}().
  -- To understand the amount of zones created, use the method @{Functional.Detection#DETECTION_BASE.GetDetectionZoneCount}(). 
  -- If you want to obtain a specific zone from the DetectedZones, use the method @{Functional.Detection#DETECTION_BASE.GetDetectionZone}() with a given index.
  -- 
  -- ## 4.4) Flare or Smoke detected units
  -- 
  -- Use the methods @{Functional.Detection#DETECTION_ZONES.FlareDetectedUnits}() or @{Functional.Detection#DETECTION_ZONES.SmokeDetectedUnits}() to flare or smoke the detected units when a new detection has taken place.
  -- 
  -- ## 4.5) Flare or Smoke or Bound detected zones
  -- 
  -- Use the methods:
  -- 
  --   * @{Functional.Detection#DETECTION_ZONES.FlareDetectedZones}() to flare in a color 
  --   * @{Functional.Detection#DETECTION_ZONES.SmokeDetectedZones}() to smoke in a color
  --   * @{Functional.Detection#DETECTION_ZONES.SmokeDetectedZones}() to bound with a tire with a white flag
  --   
  -- the detected zones when a new detection has taken place.
  -- 
  -- @field #DETECTION_ZONES
  DETECTION_ZONES = {
    ClassName = "DETECTION_ZONES",
    DetectionZoneRange = nil,
  }
  
  
  --- DETECTION_ZONES constructor.
  -- @param #DETECTION_ZONES self
  -- @param Core.Set#SET_ZONE DetectionSetZone The @{Set} of ZONE_RADIUS.
  -- @param DCS#Coalition.side DetectionCoalition The coalition of the detection.
  -- @return #DETECTION_ZONES
  function DETECTION_ZONES:New( DetectionSetZone, DetectionCoalition )
  
    -- Inherits from DETECTION_BASE
    local self = BASE:Inherit( self, DETECTION_BASE:New( DetectionSetZone ) ) -- #DETECTION_ZONES
  
    self.DetectionSetZone = DetectionSetZone  -- Core.Set#SET_ZONE
    self.DetectionCoalition = DetectionCoalition
    
    self._SmokeDetectedUnits = false
    self._FlareDetectedUnits = false
    self._SmokeDetectedZones = false
    self._FlareDetectedZones = false
    self._BoundDetectedZones = false
    
    return self
  end

  --- @param #DETECTION_ZONES self
  -- @param #number The amount of alive recce.
  function DETECTION_ZONES:CountAliveRecce()

    return self.DetectionSetZone:Count()

  end    
  
  --- @param #DETECTION_ZONES self
  function DETECTION_ZONES:ForEachAliveRecce( IteratorFunction, ... )
    self:F2( arg )
    
    self.DetectionSetZone:ForEachZone( IteratorFunction, arg )
  
    return self
  end

  --- Report summary of a detected item using a given numeric index.
  -- @param #DETECTION_ZONES self
  -- @param #DETECTION_BASE.DetectedItem DetectedItem The DetectedItem.
  -- @param Wrapper.Group#GROUP AttackGroup The group to get the settings for.
  -- @param Core.Settings#SETTINGS Settings (Optional) Message formatting settings to use.
  -- @return Core.Report#REPORT The report of the detection items.
  function DETECTION_ZONES:DetectedItemReportSummary( DetectedItem, AttackGroup, Settings )
    self:F( { DetectedItem = DetectedItem } )
  
    local DetectedItemID = self:GetDetectedItemID( DetectedItem )
    
    if DetectedItem then
      local DetectedSet = self:GetDetectedItemSet( DetectedItem )
      local ReportSummaryItem
      
      local DetectedZone = self:GetDetectedItemZone( DetectedItem )
      local DetectedItemCoordinate = DetectedZone:GetCoordinate()
      local DetectedItemCoordText = DetectedItemCoordinate:ToString( AttackGroup, Settings )

      local ThreatLevelA2G = self:GetDetectedItemThreatLevel( DetectedItem )
      local DetectedItemsCount = DetectedSet:Count()
      local DetectedItemsTypes = DetectedSet:GetTypeNames()
      
      local Report = REPORT:New()
      Report:Add(DetectedItemID .. ", " .. DetectedItemCoordText)
      Report:Add( string.format( "Threat: [%s]", string.rep(  "■", ThreatLevelA2G ), string.rep(  "□", 10-ThreatLevelA2G ) ) )
      Report:Add( string.format("Type: %2d of %s", DetectedItemsCount, DetectedItemsTypes ) )
      Report:Add( string.format("Detected: %s", DetectedItem.IsDetected and "yes" or "no" ) )
      
      return Report
    end
    
    return nil
  end

  --- Report detailed of a detection result.
  -- @param #DETECTION_ZONES self
  -- @param Wrapper.Group#GROUP AttackGroup The group to generate the report for.
  -- @return #string
  function DETECTION_ZONES:DetectedReportDetailed( AttackGroup ) --R2.1  Fixed missing report
    self:F()
    
    local Report = REPORT:New()
    for DetectedItemIndex, DetectedItem in pairs( self.DetectedItems ) do
      local DetectedItem = DetectedItem -- #DETECTION_BASE.DetectedItem
      local ReportSummary = self:DetectedItemReportSummary( DetectedItem, AttackGroup )
      Report:SetTitle( "Detected areas:" )
      Report:Add( ReportSummary:Text() )
    end
    
    local ReportText = Report:Text()
    
    return ReportText
  end

  
  --- Calculate the optimal intercept point of the DetectedItem.
  -- @param #DETECTION_ZONES self
  -- @param #DETECTION_BASE.DetectedItem DetectedItem
  function DETECTION_ZONES:CalculateIntercept( DetectedItem )

    local DetectedCoord = DetectedItem.Coordinate
--    local DetectedSpeed = DetectedCoord:GetVelocity()
--    local DetectedHeading = DetectedCoord:GetHeading()
--
--    if self.Intercept then
--      local DetectedSet = DetectedItem.Set
--      -- todo: speed
--  
--      local TranslateDistance = DetectedSpeed * self.InterceptDelay
--      
--      local InterceptCoord = DetectedCoord:Translate( TranslateDistance, DetectedHeading )
--      
--      DetectedItem.InterceptCoord = InterceptCoord
--    else
--      DetectedItem.InterceptCoord = DetectedCoord
--    end
    DetectedItem.InterceptCoord = DetectedCoord    
  end
  
  

  --- Smoke the detected units
  -- @param #DETECTION_ZONES self
  -- @return #DETECTION_ZONES self
  function DETECTION_ZONES:SmokeDetectedUnits()
    self:F2()
  
    self._SmokeDetectedUnits = true
    return self
  end
  
  --- Flare the detected units
  -- @param #DETECTION_ZONES self
  -- @return #DETECTION_ZONES self
  function DETECTION_ZONES:FlareDetectedUnits()
    self:F2()
  
    self._FlareDetectedUnits = true
    return self
  end
  
  --- Smoke the detected zones
  -- @param #DETECTION_ZONES self
  -- @return #DETECTION_ZONES self
  function DETECTION_ZONES:SmokeDetectedZones()
    self:F2()
  
    self._SmokeDetectedZones = true
    return self
  end
  
  --- Flare the detected zones
  -- @param #DETECTION_ZONES self
  -- @return #DETECTION_ZONES self
  function DETECTION_ZONES:FlareDetectedZones()
    self:F2()
  
    self._FlareDetectedZones = true
    return self
  end

  --- Bound the detected zones
  -- @param #DETECTION_ZONES self
  -- @return #DETECTION_ZONES self
  function DETECTION_ZONES:BoundDetectedZones()
    self:F2()
  
    self._BoundDetectedZones = true
    return self
  end
  
  --- Make text documenting the changes of the detected zone.
  -- @param #DETECTION_ZONES self
  -- @param #DETECTION_BASE.DetectedItem DetectedItem
  -- @return #string The Changes text
  function DETECTION_ZONES:GetChangeText( DetectedItem )
    self:F( DetectedItem )
    
    local MT = {}
    
    for ChangeCode, ChangeData in pairs( DetectedItem.Changes ) do
  
      if ChangeCode == "AA" then
        MT[#MT+1] = "Detected new area " .. ChangeData.ID .. ". The center target is a " .. ChangeData.ItemUnitType .. "."
      end
  
      if ChangeCode == "RAU" then
        MT[#MT+1] = "Changed area " .. ChangeData.ID .. ". Removed the center target."
      end
      
      if ChangeCode == "AAU" then
        MT[#MT+1] = "Changed area " .. ChangeData.ID .. ". The new center target is a " .. ChangeData.ItemUnitType .. "."
      end
      
      if ChangeCode == "RA" then
        MT[#MT+1] = "Removed old area " .. ChangeData.ID .. ". No more targets in this area."
      end
      
      if ChangeCode == "AU" then
        local MTUT = {}
        for ChangeUnitType, ChangeUnitCount in pairs( ChangeData ) do
          if ChangeUnitType  ~= "ID" then
            MTUT[#MTUT+1] = ChangeUnitCount .. " of " .. ChangeUnitType
          end
        end
        MT[#MT+1] = "Detected for area " .. ChangeData.ID .. " new target(s) " .. table.concat( MTUT, ", " ) .. "."
      end
  
      if ChangeCode == "RU" then
        local MTUT = {}
        for ChangeUnitType, ChangeUnitCount in pairs( ChangeData ) do
          if ChangeUnitType  ~= "ID" then
            MTUT[#MTUT+1] = ChangeUnitCount .. " of " .. ChangeUnitType
          end
        end
        MT[#MT+1] = "Removed for area " .. ChangeData.ID .. " invisible or destroyed target(s) " .. table.concat( MTUT, ", " ) .. "."
      end
      
    end
    
    return table.concat( MT, "\n" )
    
  end
  
  
  --- Make a DetectionSet table. This function will be overridden in the derived clsses.
  -- @param #DETECTION_ZONES self
  -- @return #DETECTION_ZONES self
  function DETECTION_ZONES:CreateDetectionItems()
  
  
    self:F( "Checking Detected Items for new Detected Units ..." )
    
    local DetectedUnits = SET_UNIT:New()
    
    -- First go through all zones, and check if there are new Zones.
    -- New Zones become a new DetectedItem.
    for ZoneName, DetectionZone in pairs( self.DetectionSetZone:GetSet() ) do
      
      local DetectedItem = self:GetDetectedItemByKey( ZoneName )

      if DetectedItem == nil then
        DetectedItem = self:AddDetectedItemZone( "ZONE", ZoneName, nil, DetectionZone )
      end

      local DetectedItemSetUnit = self:GetDetectedItemSet( DetectedItem )
      
      -- Scan the zone
      DetectionZone:Scan( { Object.Category.UNIT }, { Unit.Category.GROUND_UNIT } )
      
      -- For all the units in the zone,
      -- check if they are of the same coalition to be included.
      local ZoneUnits = DetectionZone:GetScannedUnits()
      for DCSUnitID, DCSUnit in pairs( ZoneUnits ) do
        local UnitName = DCSUnit:getName()
        local ZoneUnit = UNIT:FindByName( UnitName )
        local ZoneUnitCoalition = ZoneUnit:GetCoalition()
        if ZoneUnitCoalition == self.DetectionCoalition then
          if DetectedItemSetUnit:FindUnit( UnitName ) == nil and DetectedUnits:FindUnit( UnitName ) == nil then
            self:F( "Adding " .. UnitName )
            DetectedItemSetUnit:AddUnit( ZoneUnit )
            DetectedUnits:AddUnit( ZoneUnit )
          end
        end
      end
    end
            
    
    -- Now all the tests should have been build, now make some smoke and flares...
    -- We also report here the friendlies within the detected areas.
    
    for DetectedItemID, DetectedItemData in pairs( self.DetectedItems ) do
  
      local DetectedItem = DetectedItemData -- #DETECTION_BASE.DetectedItem
      local DetectedSet = self:GetDetectedItemSet( DetectedItem )
      local DetectedFirstUnit = DetectedSet:GetFirst()
      local DetectedZone = self:GetDetectedItemZone( DetectedItem )
 
      -- Set the last known coordinate to the detection item.
      local DetectedZoneCoord = DetectedZone:GetCoordinate()
      self:SetDetectedItemCoordinate( DetectedItem, DetectedZoneCoord, DetectedFirstUnit )
      
      self:CalculateIntercept( DetectedItem )
  
      -- We search for friendlies nearby.
      -- If there weren't any friendlies nearby, and now there are friendlies nearby, we flag the area as "changed".
      -- If there were friendlies nearby, and now there aren't any friendlies nearby, we flag the area as "changed".
      -- This is for the A2G dispatcher to detect if there is a change in the tactical situation.
      local OldFriendliesNearbyGround = self:IsFriendliesNearBy( DetectedItem, Unit.Category.GROUND_UNIT )
      self:ReportFriendliesNearBy( { DetectedItem = DetectedItem, ReportSetGroup = self.DetectionSetGroup } ) -- Fill the Friendlies table
      local NewFriendliesNearbyGround = self:IsFriendliesNearBy( DetectedItem, Unit.Category.GROUND_UNIT  )
      if OldFriendliesNearbyGround ~= NewFriendliesNearbyGround then
        DetectedItem.Changed = true
      end

      self:SetDetectedItemThreatLevel( DetectedItem )  -- Calculate A2G threat level
      --self:NearestRecce( DetectedItem )

      
      if DETECTION_ZONES._SmokeDetectedUnits or self._SmokeDetectedUnits then
        DetectedZone:SmokeZone( SMOKECOLOR.Red, 30 )
      end
      
      --DetectedSet:Flush( self )
      
      DetectedSet:ForEachUnit(
        --- @param Wrapper.Unit#UNIT DetectedUnit
        function( DetectedUnit )
          if DetectedUnit:IsAlive() then
            --self:T( "Detected Set #" .. DetectedItem.ID .. ":" .. DetectedUnit:GetName() )
            if DETECTION_ZONES._FlareDetectedUnits or self._FlareDetectedUnits then
              DetectedUnit:FlareGreen()
            end
            if DETECTION_ZONES._SmokeDetectedUnits or self._SmokeDetectedUnits then
              DetectedUnit:SmokeGreen()
            end
          end
        end
      )
      if DETECTION_ZONES._FlareDetectedZones or self._FlareDetectedZones then
        DetectedZone:FlareZone( SMOKECOLOR.White, 30, math.random( 0,90 ) )
      end
      if DETECTION_ZONES._SmokeDetectedZones or self._SmokeDetectedZones then
        DetectedZone:SmokeZone( SMOKECOLOR.White, 30 )
      end

      if DETECTION_ZONES._BoundDetectedZones or self._BoundDetectedZones then
        self.CountryID = DetectedSet:GetFirst():GetCountry()
        DetectedZone:BoundZone( 12, self.CountryID )
      end
    end
  
  end

  --- @param #DETECTION_ZONES self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @param Detection The element on which the detection is based.
  -- @param #number DetectionTimeStamp Time stamp of detection event.
  function DETECTION_ZONES:onafterDetection( From, Event, To, Detection, DetectionTimeStamp  )

    self.DetectionRun = self.DetectionRun + 1
    if self.DetectionCount > 0 and self.DetectionRun == self.DetectionCount then
      self:CreateDetectionItems() -- Polymorphic call to Create/Update the DetectionItems list for the DETECTION_ class grouping method.
  
      for DetectedItemID, DetectedItem in pairs( self.DetectedItems ) do
        self:UpdateDetectedItemDetection( DetectedItem )
        self:CleanDetectionItem( DetectedItem, DetectedItemID ) -- Any DetectionItem that has a Set with zero elements in it, must be removed from the DetectionItems list.
        if DetectedItem then
          self:__DetectedItem( 0.1, DetectedItem )
        end
      end
      self:__Detect( -self.RefreshTimeInterval )
    end
  end
  
  
  --- Set IsDetected flag for the DetectedItem, which can have more units.
  -- @param #DETECTION_ZONES self
  -- @return #DETECTION_ZONES.DetectedItem DetectedItem
  -- @return #boolean true if at least one UNIT is detected from the DetectedSet, false if no UNIT was detected from the DetectedSet.
  function DETECTION_ZONES:UpdateDetectedItemDetection( DetectedItem )
    
    local IsDetected = true
    
    DetectedItem.IsDetected = true
    
    return IsDetected
  end
  
end 