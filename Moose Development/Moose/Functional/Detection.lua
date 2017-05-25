--- **Functional** - DETECTION_ classes model the detection of enemy units by FACs or RECCEs and group them according various methods.
-- 
-- ![Banner Image](..\Presentations\DETECTION\Dia1.JPG)
-- 
-- ===
-- 
-- DETECTION classes facilitate the detection of enemy units within the battle zone executed by FACs (Forward Air Controllers) or RECCEs (Reconnassance Units).
-- DETECTION uses the in-built detection capabilities of DCS World, but adds new functionalities.
-- 
-- Find the DETECTION classes documentation further in this document in the globals section.
-- 
-- ====
-- 
-- # Demo Missions
-- 
-- ### [DETECTION Demo Missions and Source Code](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release/DET%20-%20Detection)
-- 
-- ### [DETECTION Demo Missions, only for Beta Testers](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/DET%20-%20Detection)
--
-- ### [ALL Demo Missions pack of the Latest Release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [DETECTION YouTube Channel](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl3Cf5jpI6BS0sBOVWK__tji)
-- 
-- ====
-- 
-- ### Contributions: 
-- 
--   * Mechanist : Early concept of DETECTION_AREAS.
-- 
-- ### Authors: 
-- 
--   * FlightControl : Analysis, Design, Programming, Testing
-- 
-- @module Detection


do -- DETECTION_BASE

  --- @type DETECTION_BASE
  -- @field Core.Set#SET_GROUP DetectionSetGroup The @{Set} of GROUPs in the Forward Air Controller role.
  -- @field Dcs.DCSTypes#Distance DetectionRange The range till which targets are accepted to be detected.
  -- @field #DETECTION_BASE.DetectedObjects DetectedObjects The list of detected objects.
  -- @field #table DetectedObjectsIdentified Map of the DetectedObjects identified.
  -- @field #number DetectionRun
  -- @extends Core.Fsm#FSM
  
  --- DETECTION_BASE class, extends @{Fsm#FSM}
  -- 
  -- The DETECTION_BASE class defines the core functions to administer detected objects.
  -- The DETECTION_BASE class will detect objects within the battle zone for a list of @{Group}s detecting targets following (a) detection method(s).
  -- 
  -- ## DETECTION_BASE constructor
  -- 
  -- Construct a new DETECTION_BASE instance using the @{#DETECTION_BASE.New}() method.
  -- 
  -- ## Initialization
  -- 
  -- By default, detection will return detected objects with all the detection sensors available.
  -- However, you can ask how the objects were found with specific detection methods. 
  -- If you use one of the below methods, the detection will work with the detection method specified.
  -- You can specify to apply multiple detection methods.
  -- 
  -- Use the following functions to report the objects it detected using the methods Visual, Optical, Radar, IRST, RWR, DLINK:
  -- 
  --   * @{#DETECTION_BASE.InitDetectVisual}(): Detected using Visual.
  --   * @{#DETECTION_BASE.InitDetectOptical}(): Detected using Optical.
  --   * @{#DETECTION_BASE.InitDetectRadar}(): Detected using Radar.
  --   * @{#DETECTION_BASE.InitDetectIRST}(): Detected using IRST.
  --   * @{#DETECTION_BASE.InitDetectRWR}(): Detected using RWR.
  --   * @{#DETECTION_BASE.InitDetectDLINK}(): Detected using DLINK.
  -- 
  -- ## **Filter** detected units based on **category of the unit**
  -- 
  -- Filter the detected units based on Unit.Category using the method @{#DETECTION_BASE.FilterCategories}().  
  -- The different values of Unit.Category can be:
  -- 
  --   * Unit.Category.AIRPLANE
  --   * Unit.Category.GROUND_UNIT
  --   * Unit.Category.HELICOPTER
  --   * Unit.Category.SHIP
  --   * Unit.Category.STRUCTURE
  --   
  -- Multiple Unit.Category entries can be given as a table and then these will be evaluated as an OR expression.
  -- 
  -- Example to filter a single category (Unit.Category.AIRPLANE).
  -- 
  --     DetectionObject:FilterCategories( Unit.Category.AIRPLANE ) 
  -- 
  -- Example to filter multiple categories (Unit.Category.AIRPLANE, Unit.Category.HELICOPTER). Note the {}.
  -- 
  --     DetectionObject:FilterCategories( { Unit.Category.AIRPLANE, Unit.Category.HELICOPTER } )
  -- 
  -- 
  -- ## **DETECTION_ derived classes** group the detected units into a **DetectedItems[]** list
  -- 
  -- DETECTION_BASE derived classes build a list called DetectedItems[], which is essentially a first later 
  -- of grouping of detected units. Each DetectedItem within the DetectedItems[] list contains
  -- a SET_UNIT object that contains the  detected units that belong to that group.
  -- 
  -- Derived classes will apply different methods to group the detected units. 
  -- Examples are per area, per quadrant, per distance, per type.
  -- See further the derived DETECTION classes on which grouping methods are currently supported. 
  -- 
  -- Various methods exist how to retrieve the grouped items from a DETECTION_BASE derived class:
  -- 
  --   * The method @{Detection#DETECTION_BASE.GetDetectedItems}() retrieves the DetectedItems[] list.
  --   * A DetectedItem from the DetectedItems[] list can be retrieved using the method @{Detection#DETECTION_BASE.GetDetectedItem}( DetectedItemIndex ).
  --     Note that this method returns a DetectedItem element from the list, that contains a Set variable and further information
  --     about the DetectedItem that is set by the DETECTION_BASE derived classes, used to group the DetectedItem.
  --   * A DetectedSet from the DetectedItems[] list can be retrieved using the method @{Detection#DETECTION_BASE.GetDetectedSet}( DetectedItemIndex ).
  --     This method retrieves the Set from a DetectedItem element from the DetectedItem list (DetectedItems[ DetectedItemIndex ].Set ).
  -- 
  -- ## **Visual filters** to fine-tune the probability of the detected objects
  -- 
  -- By default, DCS World will return any object that is in LOS and within "visual reach", or detectable through one of the electronic detection means.
  -- That being said, the DCS World detection algorithm can sometimes be unrealistic.
  -- Especially for a visual detection, DCS World is able to report within 1 second a detailed detection of a group of 20 units (including types of the units) that are 10 kilometers away, using only visual capabilities.
  -- Additionally, trees and other obstacles are not accounted during the DCS World detection.
  -- 
  -- Therefore, an additional (optional) filtering has been built into the DETECTION_BASE class, that can be set for visual detected units.
  -- For electronic detection, this filtering is not applied, only for visually detected targets.
  -- 
  -- The following additional filtering can be applied for visual filtering:
  -- 
  --   * A probability factor per kilometer distance.
  --   * A probability factor based on the alpha angle between the detected object and the unit detecting.
  --     A detection from a higher altitude allows for better detection than when on the ground.
  --   * Define a probability factor for "cloudy zones", which are zones where forests or villages are located. In these zones, detection will be much more difficult.
  --     The mission designer needs to define these cloudy zones within the mission, and needs to register these zones in the DETECTION_ objects additing a probability factor per zone.
  -- 
  -- I advise however, that, when you first use the DETECTION derived classes, that you don't use these filters.
  -- Only when you experience unrealistic behaviour in your missions, these filters could be applied.
  -- 
  -- 
  -- ### Distance visual detection probability
  -- 
  -- Upon a **visual** detection, the further away a detected object is, the less likely it is to be detected properly.
  -- Also, the speed of accurate detection plays a role.
  -- 
  -- A distance probability factor between 0 and 1 can be given, that will model a linear extrapolated probability over 10 km distance.
  -- 
  -- For example, if a probability factor of 0.6 (60%) is given, the extrapolated probabilities over 15 kilometers would like like:
  -- 1 km: 96%, 2 km: 92%, 3 km: 88%, 4 km: 84%, 5 km: 80%, 6 km: 76%, 7 km: 72%, 8 km: 68%, 9 km: 64%, 10 km: 60%, 11 km: 56%, 12 km: 52%, 13 km: 48%, 14 km: 44%, 15 km: 40%.
  -- 
  -- Note that based on this probability factor, not only the detection but also the **type** of the unit will be applied!
  -- 
  -- Use the method @{Detection#DETECTION_BASE.SetDistanceProbability}() to set the probability factor upon a 10 km distance.
  -- 
  -- ### Alpha Angle visual detection probability
  -- 
  -- Upon a **visual** detection, the higher the unit is during the detecting process, the more likely the detected unit is to be detected properly.
  -- A detection at a 90% alpha angle is the most optimal, a detection at 10% is less and a detection at 0% is less likely to be correct.
  -- 
  -- A probability factor between 0 and 1 can be given, that will model a progressive extrapolated probability if the target would be detected at a 0° angle.
  -- 
  -- For example, if a alpha angle probability factor of 0.7 is given, the extrapolated probabilities of the different angles would look like:
  -- 0°: 70%, 10°: 75,21%, 20°: 80,26%, 30°: 85%, 40°: 89,28%, 50°: 92,98%, 60°: 95,98%, 70°: 98,19%, 80°: 99,54%, 90°: 100%
  -- 
  -- Use the method @{Detection#DETECTION_BASE.SetAlphaAngleProbability}() to set the probability factor if 0°.
  -- 
  -- ### Cloudy Zones detection probability
  -- 
  -- Upon a **visual** detection, the more a detected unit is within a cloudy zone, the less likely the detected unit is to be detected successfully.
  -- The Cloudy Zones work with the ZONE_BASE derived classes. The mission designer can define within the mission
  -- zones that reflect cloudy areas where detected units may not be so easily visually detected.
  -- 
  -- Use the method @{Detection#DETECTION_BASE.SetZoneProbability}() to set for a defined number of zones, the probability factors.
  -- 
  -- Note however, that the more zones are defined to be "cloudy" within a detection, the more performance it will take
  -- from the DETECTION_BASE to calculate the presence of the detected unit within each zone.
  -- Expecially for ZONE_POLYGON, try to limit the amount of nodes of the polygon!
  -- 
  -- Typically, this kind of filter would be applied for very specific areas were a detection needs to be very realisting for
  -- AI not to detect so easily targets within a forrest or village rich area.
  -- 
  -- ## Accept / Reject detected units
  -- 
  -- DETECTION_BASE can accept or reject successful detections based on the location of the detected object, 
  -- if it is located in range or located inside or outside of specific zones.
  -- 
  -- ### Detection acceptance of within range limit
  -- 
  -- A range can be set that will limit a successful detection for a unit.
  -- Use the method @{Detection#DETECTION_BASE.SetAcceptRange}() to apply a range in meters till where detected units will be accepted.
  -- 
  --      local SetGroup = SET_GROUP:New():FilterPrefixes( "FAC" ):FilterStart() -- Build a SetGroup of Forward Air Controllers.
  -- 
  --      -- Build a detect object.
  --      local Detection = DETECTION_UNITS:New( SetGroup )
  --      
  --      -- This will accept detected units if the range is below 5000 meters.
  --      Detection:SetAcceptRange( 5000 ) 
  --      
  --      -- Start the Detection.
  --      Detection:Start()
  -- 
  -- 
  -- ### Detection acceptance if within zone(s).
  -- 
  -- Specific ZONE_BASE object(s) can be given as a parameter, which will only accept a detection if the unit is within the specified ZONE_BASE object(s).
  -- Use the method @{Detection#DETECTION_BASE.SetAcceptZones}() will accept detected units if they are within the specified zones.
  -- 
  --      local SetGroup = SET_GROUP:New():FilterPrefixes( "FAC" ):FilterStart() -- Build a SetGroup of Forward Air Controllers.
  -- 
  --      -- Search fo the zones where units are to be accepted.
  --      local ZoneAccept1 = ZONE:New( "AcceptZone1" )
  --      local ZoneAccept2 = ZONE:New( "AcceptZone2" )
  --      
  --      -- Build a detect object.
  --      local Detection = DETECTION_UNITS:New( SetGroup )
  --      
  --      -- This will accept detected units by Detection when the unit is within ZoneAccept1 OR ZoneAccept2.
  --      Detection:SetAcceptZones( { ZoneAccept1, ZoneAccept2 } ) 
  --      
  --      -- Start the Detection.
  --      Detection:Start()
  -- 
  -- ### Detection rejectance if within zone(s).
  -- 
  -- Specific ZONE_BASE object(s) can be given as a parameter, which will reject detection if the unit is within the specified ZONE_BASE object(s).
  -- Use the method @{Detection#DETECTION_BASE.SetRejectZones}() will reject detected units if they are within the specified zones.
  -- An example of how to use the method is shown below.
  -- 
  --      local SetGroup = SET_GROUP:New():FilterPrefixes( "FAC" ):FilterStart() -- Build a SetGroup of Forward Air Controllers.
  -- 
  --      -- Search fo the zones where units are to be rejected.
  --      local ZoneReject1 = ZONE:New( "RejectZone1" )
  --      local ZoneReject2 = ZONE:New( "RejectZone2" )
  --      
  --      -- Build a detect object.
  --      local Detection = DETECTION_UNITS:New( SetGroup )
  --      
  --      -- This will reject detected units by Detection when the unit is within ZoneReject1 OR ZoneReject2.
  --      Detection:SetRejectZones( { ZoneReject1, ZoneReject2 } ) 
  --      
  --      -- Start the Detection.
  --      Detection:Start()
  --      
  -- ## Detection of Friendlies Nearby
  -- 
  -- Use the method @{Detection#DETECTION_BASE.SetFriendliesRange}() to set the range what will indicate when friendlies are nearby
  -- a DetectedItem. The default range is 6000 meters. For air detections, it is advisory to use about 30.000 meters.
  -- 
  -- ## DETECTION_BASE is a Finite State Machine
  --
  -- Various Events and State Transitions can be tailored using DETECTION_BASE.
  -- 
  -- ### DETECTION_BASE States
  -- 
  --   * **Detecting**: The detection is running.
  --   * **Stopped**: The detection is stopped.
  -- 
  -- ### DETECTION_BASE Events
  -- 
  --   * **Start**: Start the detection process.
  --   * **Detect**: Detect new units.
  --   * **Detected**: New units have been detected.
  --   * **Stop**: Stop the detection process.
  --   
  -- @field #DETECTION_BASE DETECTION_BASE
  -- 
  DETECTION_BASE = {
    ClassName = "DETECTION_BASE",
    DetectionSetGroup = nil,
    DetectionRange = nil,
    DetectedObjects = {},
    DetectionRun = 0,
    DetectedObjectsIdentified = {},
    DetectedItems = {},
  }
  
  --- @type DETECTION_BASE.DetectedObjects
  -- @list <#DETECTION_BASE.DetectedObject>
  
  --- @type DETECTION_BASE.DetectedObject
  -- @field #string Name
  -- @field #boolean IsVisible
  -- @field #boolean KnowType
  -- @field #boolean KnowDistance
  -- @field #string Type
  -- @field #number Distance
  -- @field #boolean Identified
  -- @field #number LastTime
  -- @field #boolean LastPos
  -- @field #number LastVelocity

  
  --- @type DETECTION_BASE.DetectedItems
  -- @list <#DETECTION_BASE.DetectedItem>
  
  --- @type DETECTION_BASE.DetectedItem
  -- @field Core.Set#SET_UNIT Set
  -- @field Core.Set#SET_UNIT Set -- The Set of Units in the detected area.
  -- @field Core.Zone#ZONE_UNIT Zone -- The Zone of the detected area.
  -- @field #boolean Changed Documents if the detected area has changes.
  -- @field #table Changes A list of the changes reported on the detected area. (It is up to the user of the detected area to consume those changes).
  -- @field #number ItemID -- The identifier of the detected area.
  -- @field #boolean FriendliesNearBy Indicates if there are friendlies within the detected area.
  -- @field Wrapper.Unit#UNIT NearestFAC The nearest FAC near the Area.

  
  --- DETECTION constructor.
  -- @param #DETECTION_BASE self
  -- @param Core.Set#SET_GROUP DetectionSetGroup The @{Set} of GROUPs in the Forward Air Controller role.
  -- @return #DETECTION_BASE self
  function DETECTION_BASE:New( DetectionSetGroup )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM:New() ) -- #DETECTION_BASE
    
    self.DetectedItemCount = 0
    self.DetectedItemMax = 0
    self.DetectedItems = {}
    
    self.DetectionSetGroup = DetectionSetGroup
    
    self.DetectionInterval = 30
    
    self:InitDetectVisual( nil )
    self:InitDetectOptical( nil )
    self:InitDetectRadar( nil )
    self:InitDetectRWR( nil )
    self:InitDetectIRST( nil )
    self:InitDetectDLINK( nil )
    
    self:FilterCategories( {
      Unit.Category.AIRPLANE,
      Unit.Category.GROUND_UNIT,
      Unit.Category.HELICOPTER,
      Unit.Category.SHIP,
      Unit.Category.STRUCTURE
    } )
    
    self:SetFriendliesRange( 6000 )
  
    -- Create FSM transitions.
    
    self:SetStartState( "Stopped" )
    self.CountryID = DetectionSetGroup:GetFirst():GetCountry()
    
    self:AddTransition( "Stopped", "Start", "Detecting")
    
    --- OnLeave Transition Handler for State Stopped.
    -- @function [parent=#DETECTION_BASE] OnLeaveStopped
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.
    
    --- OnEnter Transition Handler for State Stopped.
    -- @function [parent=#DETECTION_BASE] OnEnterStopped
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    
    --- OnBefore Transition Handler for Event Start.
    -- @function [parent=#DETECTION_BASE] OnBeforeStart
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.
    
    --- OnAfter Transition Handler for Event Start.
    -- @function [parent=#DETECTION_BASE] OnAfterStart
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    	
    --- Synchronous Event Trigger for Event Start.
    -- @function [parent=#DETECTION_BASE] Start
    -- @param #DETECTION_BASE self
    
    --- Asynchronous Event Trigger for Event Start.
    -- @function [parent=#DETECTION_BASE] __Start
    -- @param #DETECTION_BASE self
    -- @param #number Delay The delay in seconds.
    
    --- OnLeave Transition Handler for State Detecting.
    -- @function [parent=#DETECTION_BASE] OnLeaveDetecting
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.
    
    --- OnEnter Transition Handler for State Detecting.
    -- @function [parent=#DETECTION_BASE] OnEnterDetecting
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    
    self:AddTransition( "Detecting", "Detect", "Detecting" )
    self:AddTransition( "Detecting", "DetectionGroup", "Detecting" )
    
    --- OnBefore Transition Handler for Event Detect.
    -- @function [parent=#DETECTION_BASE] OnBeforeDetect
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.
    
    --- OnAfter Transition Handler for Event Detect.
    -- @function [parent=#DETECTION_BASE] OnAfterDetect
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    	
    --- Synchronous Event Trigger for Event Detect.
    -- @function [parent=#DETECTION_BASE] Detect
    -- @param #DETECTION_BASE self
    
    --- Asynchronous Event Trigger for Event Detect.
    -- @function [parent=#DETECTION_BASE] __Detect
    -- @param #DETECTION_BASE self
    -- @param #number Delay The delay in seconds.
    
    
    self:AddTransition( "Detecting", "Detected", "Detecting" )
    
    --- OnBefore Transition Handler for Event Detected.
    -- @function [parent=#DETECTION_BASE] OnBeforeDetected
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.
    
    --- OnAfter Transition Handler for Event Detected.
    -- @function [parent=#DETECTION_BASE] OnAfterDetected
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    	
    --- Synchronous Event Trigger for Event Detected.
    -- @function [parent=#DETECTION_BASE] Detected
    -- @param #DETECTION_BASE self
    
    --- Asynchronous Event Trigger for Event Detected.
    -- @function [parent=#DETECTION_BASE] __Detected
    -- @param #DETECTION_BASE self
    -- @param #number Delay The delay in seconds.
    
    
    self:AddTransition( "*", "Stop", "Stopped" )
    
    --- OnBefore Transition Handler for Event Stop.
    -- @function [parent=#DETECTION_BASE] OnBeforeStop
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.
    
    --- OnAfter Transition Handler for Event Stop.
    -- @function [parent=#DETECTION_BASE] OnAfterStop
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    	
    --- Synchronous Event Trigger for Event Stop.
    -- @function [parent=#DETECTION_BASE] Stop
    -- @param #DETECTION_BASE self
    
    --- Asynchronous Event Trigger for Event Stop.
    -- @function [parent=#DETECTION_BASE] __Stop
    -- @param #DETECTION_BASE self
    -- @param #number Delay The delay in seconds.
    
    --- OnLeave Transition Handler for State Stopped.
    -- @function [parent=#DETECTION_BASE] OnLeaveStopped
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.
    
    --- OnEnter Transition Handler for State Stopped.
    -- @function [parent=#DETECTION_BASE] OnEnterStopped
    -- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    
    return self
  end
  
  do -- State Transition Handling
  
    --- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    function DETECTION_BASE:onafterStart(From,Event,To)
      self:__Detect(0.1)
    end

    --- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    function DETECTION_BASE:onafterDetect(From,Event,To)
      self:E( { From, Event, To } )

      local DetectDelay = 0.1
      self.DetectionCount = 0
      self.DetectionRun = 0
      self:UnIdentifyAllDetectedObjects() -- Resets the DetectedObjectsIdentified table
      
      for DetectionGroupID, DetectionGroupData in pairs( self.DetectionSetGroup:GetSet() ) do
        --self:E( { DetectionGroupData } )
        self:__DetectionGroup( DetectDelay, DetectionGroupData ) -- Process each detection asynchronously.
        self.DetectionCount = self.DetectionCount + 1
        DetectDelay = DetectDelay + 0.1
      end
    end
    
    --- @param #DETECTION_BASE self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @param Wrapper.Group#GROUP DetectionGroup The Group detecting.
    function DETECTION_BASE:onafterDetectionGroup( From, Event, To, DetectionGroup  )
      self:E( { From, Event, To } )
      
      self.DetectionRun = self.DetectionRun + 1
      
      local HasDetectedObjects = false
      
      if DetectionGroup:IsAlive() then
    
        self:T( { "DetectionGroup is Alive", DetectionGroup:GetName() } )
        
        local DetectionGroupName = DetectionGroup:GetName()
        local DetectionUnit = DetectionGroup:GetUnit(1)
        
        local DetectedUnits = {}
        
        local DetectedTargets = DetectionGroup:GetDetectedTargets(
          self.DetectVisual,
          self.DetectOptical,
          self.DetectRadar,
          self.DetectIRST,
          self.DetectRWR,
          self.DetectDLINK
        )
        
        self:T( DetectedTargets )
        
        for DetectionObjectID, Detection in pairs( DetectedTargets ) do
          local DetectedObject = Detection.object -- Dcs.DCSWrapper.Object#Object
          
          if DetectedObject and DetectedObject:isExist() and DetectedObject.id_ < 50000000 then -- and ( DetectedObject:getCategory() == Object.Category.UNIT or DetectedObject:getCategory() == Object.Category.STATIC ) then
    
            local TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity = DetectionUnit:IsTargetDetected( 
              DetectedObject,
              self.DetectVisual,
              self.DetectOptical,
              self.DetectRadar,
              self.DetectIRST,
              self.DetectRWR,
              self.DetectDLINK
            )
            
            self:T2( { TargetIsDetected = TargetIsDetected, TargetIsVisible = TargetIsVisible, TargetLastTime = TargetLastTime, TargetKnowType = TargetKnowType, TargetKnowDistance = TargetKnowDistance, TargetLastPos = TargetLastPos, TargetLastVelocity = TargetLastVelocity } )

            local DetectionAccepted = true
            
            local DetectedObjectName = DetectedObject:getName()
    
            local DetectedObjectVec3 = DetectedObject:getPoint()
            local DetectedObjectVec2 = { x = DetectedObjectVec3.x, y = DetectedObjectVec3.z }
            local DetectionGroupVec3 = DetectionGroup:GetVec3()
            local DetectionGroupVec2 = { x = DetectionGroupVec3.x, y = DetectionGroupVec3.z }
    
            local Distance = ( ( DetectedObjectVec3.x - DetectionGroupVec3.x )^2 +
              ( DetectedObjectVec3.y - DetectionGroupVec3.y )^2 +
              ( DetectedObjectVec3.z - DetectionGroupVec3.z )^2
              ) ^ 0.5 / 1000

            local DetectedUnitCategory = DetectedObject:getDesc().category
    
            self:T2( { "Detected Target:", DetectionGroupName, DetectedObjectName, Distance, DetectedUnitCategory } )

            -- Calculate Acceptance
            
            DetectionAccepted = self._.FilterCategories[DetectedUnitCategory] ~= nil and DetectionAccepted or false
    
            if self.AcceptRange and Distance > self.AcceptRange then
              DetectionAccepted = false
            end
            
            if self.AcceptZones then
              for AcceptZoneID, AcceptZone in pairs( self.AcceptZones ) do
                local AcceptZone = AcceptZone -- Core.Zone#ZONE_BASE
                if AcceptZone:IsPointVec2InZone( DetectedObjectVec2 ) == false then
                  DetectionAccepted = false
                end
              end
            end

            if self.RejectZones then
              for RejectZoneID, RejectZone in pairs( self.RejectZones ) do
                local RejectZone = RejectZone -- Core.Zone#ZONE_BASE
                if RejectZone:IsPointVec2InZone( DetectedObjectVec2 ) == true then
                  DetectionAccepted = false
                end
              end
            end
            
            -- Calculate additional probabilities
            
            if not self.DetectedObjects[DetectedObjectName] and Detection.visible and self.DistanceProbability then
              local DistanceFactor = Distance / 4
              local DistanceProbabilityReversed = ( 1 - self.DistanceProbability ) * DistanceFactor
              local DistanceProbability = 1 - DistanceProbabilityReversed
              DistanceProbability = DistanceProbability * 30 / 300
              local Probability = math.random() -- Selects a number between 0 and 1
              self:T( { Probability, DistanceProbability } )
              if Probability > DistanceProbability then
                DetectionAccepted = false
              end
            end
            
            if not self.DetectedObjects[DetectedObjectName] and Detection.visible and self.AlphaAngleProbability then
              local NormalVec2 = { x = DetectedObjectVec2.x - DetectionGroupVec2.x, y = DetectedObjectVec2.y - DetectionGroupVec2.y }
              local AlphaAngle = math.atan2( NormalVec2.y, NormalVec2.x )
              local Sinus = math.sin( AlphaAngle )
              local AlphaAngleProbabilityReversed = ( 1 - self.AlphaAngleProbability ) * ( 1 - Sinus )
              local AlphaAngleProbability = 1 - AlphaAngleProbabilityReversed
              
              AlphaAngleProbability = AlphaAngleProbability * 30 / 300
              
              local Probability =  math.random() -- Selects a number between 0 and 1
              self:T( { Probability, AlphaAngleProbability } )
              if Probability > AlphaAngleProbability then
                DetectionAccepted = false
              end
               
            end
            
            if not self.DetectedObjects[DetectedObjectName] and Detection.visible and self.ZoneProbability then
            
              for ZoneDataID, ZoneData in pairs( self.ZoneProbability ) do
                self:E({ZoneData})
                local ZoneObject = ZoneData[1] -- Core.Zone#ZONE_BASE
                local ZoneProbability = ZoneData[2] -- #number
                ZoneProbability = ZoneProbability * 30 / 300
                
                if ZoneObject:IsPointVec2InZone( DetectedObjectVec2 ) == true then
                  local Probability =  math.random() -- Selects a number between 0 and 1
                  self:T( { Probability, ZoneProbability } )
                  if Probability > ZoneProbability then
                    DetectionAccepted = false
                    break
                  end
                end
              end
            end
            
            if DetectionAccepted then
              
              HasDetectedObjects = true
    
              self.DetectedObjects[DetectedObjectName] = self.DetectedObjects[DetectedObjectName] or {} 
              self.DetectedObjects[DetectedObjectName].Name = DetectedObjectName
              self.DetectedObjects[DetectedObjectName].IsVisible = TargetIsVisible 
              self.DetectedObjects[DetectedObjectName].LastTime = TargetLastTime
              self.DetectedObjects[DetectedObjectName].LastPos = TargetLastPos
              self.DetectedObjects[DetectedObjectName].LastVelocity = TargetLastVelocity
              self.DetectedObjects[DetectedObjectName].KnowType = TargetKnowType
              self.DetectedObjects[DetectedObjectName].KnowDistance = Detection.distance   -- TargetKnowDistance
              self.DetectedObjects[DetectedObjectName].Distance = Distance
              
              local DetectedUnit = UNIT:FindByName( DetectedObjectName )
              
              DetectedUnits[DetectedObjectName] = DetectedUnit
            else
              -- if beyond the DetectionRange then nullify...
              if self.DetectedObjects[DetectedObjectName] then
                self.DetectedObjects[DetectedObjectName] = nil
              end
            end
          end
          
          self:T2( self.DetectedObjects )
        end
        
        if HasDetectedObjects then
          self:__Detected( 0.1, DetectedUnits )
        end
        
      end
      
      if self.DetectionCount > 0 and self.DetectionRun == self.DetectionCount then
        self:T( "--> Create Detection Sets" )

        self:CreateDetectionItems() -- Polymorphic call to Create/Update the DetectionItems list for the DETECTION_ class grouping method.
        self:CleanDetectionItems() -- Any DetectionItem that has a Set with zero elements in it, must be removed from the DetectionItems list.
 
        self:__Detect( self.DetectionInterval )
      end

    end
  
  
  end
  
  do -- DetectionItems Creation
  
    --- Make a DetectionSet table. This function will be overridden in the derived clsses.
    -- @param #DETECTION_BASE self
    -- @return #DETECTION_BASE
    function DETECTION_BASE:CleanDetectionItems() --R2.1 Clean the DetectionItems list
      self:F2()
    
      -- We clean all DetectedItems.
      -- if there are any remaining DetectedItems with no Set Objects then the Item in the DetectedItems must be deleted.
  
      for DetectedItemID, DetectedItemData in pairs( self.DetectedItems ) do
    
        local DetectedItem = DetectedItemData -- #DETECTION_BASE.DetectedItem
        local DetectedSet = DetectedItem.Set
        
        if DetectedSet:Count() == 0 then
          self:RemoveDetectedItem(DetectedItemID)
        end
      end

      return self
    end
  
    --- Make a DetectionSet table. This function will be overridden in the derived clsses.
    -- @param #DETECTION_BASE self
    -- @return #DETECTION_BASE
    function DETECTION_BASE:CreateDetectionItems()
      self:F2()
    
      self:E( "Error, in DETECTION_BASE class..." )
      return self
    end
  

  end
  
  do -- Initialization methods
  
    --- Detect Visual.
    -- @param #DETECTION_BASE self
    -- @param #boolean DetectVisual
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:InitDetectVisual( DetectVisual )
    
      self.DetectVisual = DetectVisual
      
      return self
    end
    
    --- Detect Optical.
    -- @param #DETECTION_BASE self
    -- @param #boolean DetectOptical
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:InitDetectOptical( DetectOptical )
    	self:F2()
    
      self.DetectOptical = DetectOptical
      
      return self
    end
    
    --- Detect Radar.
    -- @param #DETECTION_BASE self
    -- @param #boolean DetectRadar
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:InitDetectRadar( DetectRadar )
      self:F2()
    
      self.DetectRadar = DetectRadar
      
      return self
    end
    
    --- Detect IRST.
    -- @param #DETECTION_BASE self
    -- @param #boolean DetectIRST
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:InitDetectIRST( DetectIRST )
      self:F2()
    
      self.DetectIRST = DetectIRST
      
      return self
    end
    
    --- Detect RWR.
    -- @param #DETECTION_BASE self
    -- @param #boolean DetectRWR
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:InitDetectRWR( DetectRWR )
      self:F2()
    
      self.DetectRWR = DetectRWR
      
      return self
    end
    
    --- Detect DLINK.
    -- @param #DETECTION_BASE self
    -- @param #boolean DetectDLINK
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:InitDetectDLINK( DetectDLINK )
      self:F2()
    
      self.DetectDLINK = DetectDLINK
      
      return self
    end
  
  end
  
  do -- Filter methods
  
    --- Filter the detected units based on Unit.Category  
    -- The different values of Unit.Category can be:
    -- 
    --   * Unit.Category.AIRPLANE
    --   * Unit.Category.GROUND_UNIT
    --   * Unit.Category.HELICOPTER
    --   * Unit.Category.SHIP
    --   * Unit.Category.STRUCTURE
    --   
    -- Multiple Unit.Category entries can be given as a table and then these will be evaluated as an OR expression.
    -- 
    -- Example to filter a single category (Unit.Category.AIRPLANE).
    -- 
    --     DetectionObject:FilterCategories( Unit.Category.AIRPLANE ) 
    -- 
    -- Example to filter multiple categories (Unit.Category.AIRPLANE, Unit.Category.HELICOPTER). Note the {}.
    -- 
    --     DetectionObject:FilterCategories( { Unit.Category.AIRPLANE, Unit.Category.HELICOPTER } )
    -- 
    -- @param #DETECTION_BASE self
    -- @param #list<Dcs.DCSUnit#Unit> FilterCategories The Categories entries
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:FilterCategories( FilterCategories )
      self:F2()
    
      self._.FilterCategories = {}
      if type( FilterCategories ) == "table" then
        for CategoryID, Category in pairs( FilterCategories ) do
          self._.FilterCategories[Category] = Category
        end 
      else
        self._.FilterCategories[FilterCategories] = FilterCategories
      end
      return self
      
    end

  end

  do
  
    --- Set the detection interval time in seconds.
    -- @param #DETECTION_BASE self
    -- @param #number DetectionInterval Interval in seconds.
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:SetDetectionInterval( DetectionInterval )
      self:F2()
    
      self.DetectionInterval = DetectionInterval
      
      return self
    end
  
  end

  do -- Friendlies Radius

    --- Set the radius in meters to validate if friendlies are nearby.
    -- @param #DETECTION_BASE self
    -- @param #number FriendliesRange Radius to use when checking if Friendlies are nearby.
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:SetFriendliesRange( FriendliesRange ) --R2.2 Friendlies range
      self:F2()
    
      self.FriendliesRange = FriendliesRange
      
      return self
    end
  
  end
  
  do -- Accept / Reject detected units
  
    --- Accept detections if within a range in meters.
    -- @param #DETECTION_BASE self
    -- @param #number AcceptRange Accept a detection if the unit is within the AcceptRange in meters.
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:SetAcceptRange( AcceptRange )
      self:F2()
    
      self.AcceptRange = AcceptRange
      
      return self
    end
    
    --- Accept detections if within the specified zone(s).
    -- @param #DETECTION_BASE self
    -- @param AcceptZones Can be a list or ZONE_BASE objects, or a single ZONE_BASE object.
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:SetAcceptZones( AcceptZones )
      self:F2()
    
      if type( AcceptZones ) == "table" then
        self.AcceptZones = AcceptZones
      else
        self.AcceptZones = { AcceptZones }
      end
      
      return self
    end
    
    --- Reject detections if within the specified zone(s).
    -- @param #DETECTION_BASE self
    -- @param RejectZones Can be a list or ZONE_BASE objects, or a single ZONE_BASE object.
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:SetRejectZones( RejectZones )
      self:F2()
    
      if type( RejectZones ) == "table" then
        self.RejectZones = RejectZones
      else
        self.RejectZones = { RejectZones }
      end
      
      return self
    end
  
  end
  
  do -- Probability methods
  
    --- Upon a **visual** detection, the further away a detected object is, the less likely it is to be detected properly.
    -- Also, the speed of accurate detection plays a role.
    -- A distance probability factor between 0 and 1 can be given, that will model a linear extrapolated probability over 10 km distance.
    -- For example, if a probability factor of 0.6 (60%) is given, the extrapolated probabilities over 15 kilometers would like like:
    -- 1 km: 96%, 2 km: 92%, 3 km: 88%, 4 km: 84%, 5 km: 80%, 6 km: 76%, 7 km: 72%, 8 km: 68%, 9 km: 64%, 10 km: 60%, 11 km: 56%, 12 km: 52%, 13 km: 48%, 14 km: 44%, 15 km: 40%.
    -- @param #DETECTION_BASE self
    -- @param DistanceProbability The probability factor.
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:SetDistanceProbability( DistanceProbability )
      self:F2()
    
      self.DistanceProbability = DistanceProbability
      
      return self
    end
  
  
    --- Upon a **visual** detection, the higher the unit is during the detecting process, the more likely the detected unit is to be detected properly.
    -- A detection at a 90% alpha angle is the most optimal, a detection at 10% is less and a detection at 0% is less likely to be correct.
    -- 
    -- A probability factor between 0 and 1 can be given, that will model a progressive extrapolated probability if the target would be detected at a 0° angle.
    -- 
    -- For example, if a alpha angle probability factor of 0.7 is given, the extrapolated probabilities of the different angles would look like:
    -- 0°: 70%, 10°: 75,21%, 20°: 80,26%, 30°: 85%, 40°: 89,28%, 50°: 92,98%, 60°: 95,98%, 70°: 98,19%, 80°: 99,54%, 90°: 100%
    -- @param #DETECTION_BASE self
    -- @param AlphaAngleProbability The probability factor.
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:SetAlphaAngleProbability( AlphaAngleProbability )
      self:F2()
    
      self.AlphaAngleProbability = AlphaAngleProbability
      
      return self
    end
  
    --- Upon a **visual** detection, the more a detected unit is within a cloudy zone, the less likely the detected unit is to be detected successfully.
    -- The Cloudy Zones work with the ZONE_BASE derived classes. The mission designer can define within the mission
    -- zones that reflect cloudy areas where detected units may not be so easily visually detected.
    -- @param #DETECTION_BASE self
    -- @param ZoneArray Aray of a The ZONE_BASE object and a ZoneProbability pair..
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:SetZoneProbability( ZoneArray )
      self:F2()
    
      self.ZoneProbability = ZoneArray 
      
      return self
    end
  
  
  end
  
  do -- Change processing
  
    --- Accepts changes from the detected item.
    -- @param #DETECTION_BASE self
    -- @param #DETECTION_BASE.DetectedItem DetectedItem
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:AcceptChanges( DetectedItem )
    
      DetectedItem.Changed = false
      DetectedItem.Changes = {}
    
      return self
    end

    --- Add a change to the detected zone.
    -- @param #DETECTION_BASE self
    -- @param #DETECTION_BASE.DetectedItem DetectedItem
    -- @param #string ChangeCode
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:AddChangeItem( DetectedItem, ChangeCode, ItemUnitType )
    
      DetectedItem.Changed = true
      local ItemID = DetectedItem.ItemID
      
      DetectedItem.Changes = DetectedItem.Changes or {}
      DetectedItem.Changes[ChangeCode] = DetectedItem.Changes[ChangeCode] or {}
      DetectedItem.Changes[ChangeCode].ItemID = ItemID
      DetectedItem.Changes[ChangeCode].ItemUnitType = ItemUnitType
    
      self:T( { "Change on Detection Item:", DetectedItem.ItemID, ChangeCode, ItemUnitType } )
    
      return self
    end
    
    
    --- Add a change to the detected zone.
    -- @param #DETECTION_BASE self
    -- @param #DETECTION_BASE.DetectedItem DetectedItem
    -- @param #string ChangeCode
    -- @param #string ChangeUnitType
    -- @return #DETECTION_BASE self
    function DETECTION_BASE:AddChangeUnit( DetectedItem, ChangeCode, ChangeUnitType )
    
      DetectedItem.Changed = true
      local ItemID = DetectedItem.ItemID
      
      DetectedItem.Changes = DetectedItem.Changes or {}
      DetectedItem.Changes[ChangeCode] = DetectedItem.Changes[ChangeCode] or {}
      DetectedItem.Changes[ChangeCode][ChangeUnitType] = DetectedItem.Changes[ChangeCode][ChangeUnitType] or 0
      DetectedItem.Changes[ChangeCode][ChangeUnitType] = DetectedItem.Changes[ChangeCode][ChangeUnitType] + 1
      DetectedItem.Changes[ChangeCode].ItemID = ItemID
      
      self:T( { "Change on Detection Item:", DetectedItem.ItemID, ChangeCode, ChangeUnitType } )
    
      return self
    end
    
  
  end
  
  do -- Threat
  
    --- Returns if there are friendlies nearby the FAC units ...
    -- @param #DETECTION_BASE self
    -- @return #boolean trhe if there are friendlies nearby 
    function DETECTION_BASE:IsFriendliesNearBy( DetectedItem )
      
      return DetectedItem.FriendliesNearBy ~= nil or false
    end
  
    --- Returns friendly units nearby the FAC units ...
    -- @param #DETECTION_BASE self
    -- @return #map<#string,Wrapper.Unit#UNIT> The map of Friendly UNITs. 
    function DETECTION_BASE:GetFriendliesNearBy( DetectedItem )
      
      return DetectedItem.FriendliesNearBy
    end
  
    --- Returns if there are friendlies nearby the FAC units ...
    -- @param #DETECTION_BASE self
    -- @return #boolean trhe if there are friendlies nearby 
    function DETECTION_BASE:IsPlayersNearBy( DetectedItem )
      
      return DetectedItem.PlayersNearBy ~= nil
    end
  
    --- Returns friendly units nearby the FAC units ...
    -- @param #DETECTION_BASE self
    -- @return #map<#string,Wrapper.Unit#UNIT> The map of Friendly UNITs. 
    function DETECTION_BASE:GetPlayersNearBy( DetectedItem )
      
      return DetectedItem.PlayersNearBy
    end
  
    --- Background worker function to determine if there are friendlies nearby ...
    -- @param #DETECTION_BASE self
    function DETECTION_BASE:ReportFriendliesNearBy( ReportGroupData )
      self:F2()
      
      local DetectedItem = ReportGroupData.DetectedItem  -- Functional.Detection#DETECTION_BASE.DetectedItem    
      local DetectedSet = ReportGroupData.DetectedItem.Set
      local DetectedUnit = DetectedSet:GetFirst()
    
      DetectedItem.FriendliesNearBy = nil

      if DetectedUnit then
      
        
        local SphereSearch = {
         id = world.VolumeType.SPHERE,
          params = {
           point = DetectedUnit:GetVec3(),
           radius = self.FriendliesRange,
          }
          
         }
         
        --- @param Dcs.DCSWrapper.Unit#Unit FoundDCSUnit
        -- @param Wrapper.Group#GROUP ReportGroup
        -- @param Set#SET_GROUP ReportSetGroup
        local FindNearByFriendlies = function( FoundDCSUnit, ReportGroupData )
            
          local DetectedItem = ReportGroupData.DetectedItem  -- Functional.Detection#DETECTION_BASE.DetectedItem    
          local DetectedSet = ReportGroupData.DetectedItem.Set
          local DetectedUnit = DetectedSet:GetFirst() -- Wrapper.Unit#UNIT
          local ReportSetGroup = ReportGroupData.ReportSetGroup
    
          local EnemyCoalition = DetectedUnit:GetCoalition()
          
          local FoundUnitCoalition = FoundDCSUnit:getCoalition()
          local FoundUnitName = FoundDCSUnit:getName()
          local FoundUnitGroupName = FoundDCSUnit:getGroup():getName()
          local EnemyUnitName = DetectedUnit:GetName()
          local FoundUnitInReportSetGroup = ReportSetGroup:FindGroup( FoundUnitGroupName ) ~= nil
          
          self:T3( { "Friendlies search:", FoundUnitName, FoundUnitCoalition, EnemyUnitName, EnemyCoalition, FoundUnitInReportSetGroup } )
          
          if FoundUnitCoalition ~= EnemyCoalition and FoundUnitInReportSetGroup == false then
            DetectedItem.FriendliesNearBy = DetectedItem.FriendliesNearBy or {}
            DetectedItem.FriendliesNearBy[FoundUnitName] = UNIT:Find( FoundDCSUnit )
            return false
          end
          
          return true
        end
        
        world.searchObjects( Object.Category.UNIT, SphereSearch, FindNearByFriendlies, ReportGroupData )

        DetectedItem.PlayersNearBy = nil
        local DetectionZone = ZONE_UNIT:New( "DetectionPlayers", DetectedUnit, self.FriendliesRange )
        
        _DATABASE:ForEachPlayer(
          --- @param Wrapper.Unit#UNIT PlayerUnit
          function( PlayerUnitName )
            local PlayerUnit = UNIT:FindByName( PlayerUnitName )
            if PlayerUnit:IsInZone(DetectionZone) then
              DetectedItem.FriendliesNearBy = DetectedItem.FriendliesNearBy or {}
              local PlayerUnitName = PlayerUnit:GetName()
              DetectedItem.PlayersNearBy = DetectedItem.PlayersNearBy or {}
              DetectedItem.PlayersNearBy[PlayerUnitName] = PlayerUnit
              DetectedItem.FriendliesNearBy = DetectedItem.FriendliesNearBy or {}
              DetectedItem.FriendliesNearBy[PlayerUnitName] = PlayerUnit
            end
          end
        )
      end    
    end
  
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
    self:F( { "Identified:", DetectedObject.Name } )
  
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
  	self:F2( ObjectName )
    
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
  
  
  --- Adds a new DetectedItem to the DetectedItems list.
  -- The DetectedItem is a table and contains a SET_UNIT in the field Set.
  -- @param #DETECTION_BASE self
  -- @param ItemPrefix
  -- @param #string DetectedItemIndex The index of the DetectedItem.
  -- @param Core.Set#SET_UNIT Set (optional) The Set of Units to be added.
  -- @return #DETECTION_BASE.DetectedItem
  function DETECTION_BASE:AddDetectedItem( ItemPrefix, DetectedItemIndex, Set )
  
    local DetectedItem = {}
    self.DetectedItemCount = self.DetectedItemCount + 1
    self.DetectedItemMax = self.DetectedItemMax + 1
    
    if DetectedItemIndex then
      self.DetectedItems[DetectedItemIndex] = DetectedItem
    else
      self.DetectedItems[self.DetectedItemCount] = DetectedItem
    end
    
    DetectedItem.Set = Set or SET_UNIT:New():FilterDeads():FilterCrashes()
    DetectedItem.Index = DetectedItemIndex or self.DetectedItemCount
    DetectedItem.ItemID = ItemPrefix .. "." .. self.DetectedItemMax
    DetectedItem.ID = self.DetectedItemMax
    DetectedItem.Removed = false
    
    return DetectedItem
  end
  
  --- Adds a new DetectedItem to the DetectedItems list.
  -- The DetectedItem is a table and contains a SET_UNIT in the field Set.
  -- @param #DETECTION_BASE self
  -- @param #string DetectedItemIndex The index of the DetectedItem.
  -- @param Core.Set#SET_UNIT Set (optional) The Set of Units to be added.
  -- @param Core.Zone#ZONE_UNIT Zone (optional) The Zone to be added where the Units are located.
  -- @return #DETECTION_BASE.DetectedItem
  function DETECTION_BASE:AddDetectedItemZone( DetectedItemIndex, Set, Zone )
  
    local DetectedItem = self:AddDetectedItem( "AREA", DetectedItemIndex, Set )

    DetectedItem.Zone = Zone
    
    return DetectedItem
  end
  
  --- Removes an existing DetectedItem from the DetectedItems list.
  -- The DetectedItem is a table and contains a SET_UNIT in the field Set.
  -- @param #DETECTION_BASE self
  -- @param #number DetectedItemIndex The index or position in the DetectedItems list where the item needs to be removed.
  function DETECTION_BASE:RemoveDetectedItem( DetectedItemIndex )
    
    if self.DetectedItems[DetectedItemIndex] then
      self.DetectedItemCount = self.DetectedItemCount - 1
      self.DetectedItems[DetectedItemIndex] = nil
    end
  end
  
  
  --- Get the detected @{Set#SET_BASE}s.
  -- @param #DETECTION_BASE self
  -- @return #DETECTION_BASE.DetectedItems
  function DETECTION_BASE:GetDetectedItems()
  
    return self.DetectedItems
  end
  
  --- Get the amount of SETs with detected objects.
  -- @param #DETECTION_BASE self
  -- @return #number The amount of detected items. Note that the amount of detected items can differ with the reality, because detections are not real-time but doen in intervals!
  function DETECTION_BASE:GetDetectedItemsCount()
  
    local DetectedCount = self.DetectedItemCount
    return DetectedCount
  end
  
  --- Get a detected item using a given numeric index.
  -- @param #DETECTION_BASE self
  -- @param #number Index
  -- @return #DETECTION_BASE.DetectedItem
  function DETECTION_BASE:GetDetectedItem( Index )
  
    local DetectedItem = self.DetectedItems[Index]
    if DetectedItem then
      return DetectedItem
    end
    
    return nil
  end
  
  --- Get a detected ItemID using a given numeric index.
  -- @param #DETECTION_BASE self
  -- @param #number Index
  -- @return #string DetectedItemID
  function DETECTION_BASE:GetDetectedItemID( Index ) --R2.1
  
    local DetectedItem = self.DetectedItems[Index]
    if DetectedItem then
      return DetectedItem.ItemID
    end
    
    return ""
  end
  
  --- Get a detected ID using a given numeric index.
  -- @param #DETECTION_BASE self
  -- @param #number Index
  -- @return #string DetectedItemID
  function DETECTION_BASE:GetDetectedID( Index ) --R2.1
  
    local DetectedItem = self.DetectedItems[Index]
    if DetectedItem then
      return DetectedItem.ID
    end
    
    return ""
  end
  
  --- Get the @{Set#SET_UNIT} of a detecttion area using a given numeric index.
  -- @param #DETECTION_BASE self
  -- @param #number Index
  -- @return Core.Set#SET_UNIT DetectedSet
  function DETECTION_BASE:GetDetectedSet( Index )
  
    local DetectedItem = self:GetDetectedItem( Index )
    local DetectedSetUnit = DetectedItem.Set
    if DetectedSetUnit then
      return DetectedSetUnit
    end
    
    return nil
  end
  
  do -- Coordinates

    --- Get the COORDINATE of a detection item using a given numeric index.
    -- @param #DETECTION_BASE self
    -- @param #number Index
    -- @return Core.Point#COORDINATE
    function DETECTION_BASE:GetDetectedItemCoordinate( Index )
    
      -- If the Zone is set, return the coordinate of the Zone.
      local DetectedItemSet = self:GetDetectedSet( Index )
      local FirstUnit = DetectedItemSet:GetFirst()

      local DetectedZone = self:GetDetectedItemZone( Index )
      if DetectedZone then
        local Coordinate = DetectedZone:GetPointVec2()
        Coordinate:SetHeading(FirstUnit:GetHeading())
        Coordinate:SetAlt( FirstUnit:GetAltitude() )
        return Coordinate
      end
      
      -- If no Zone is set, return the coordinate of the first unit in the Set
      if FirstUnit then
        local Coordinate = FirstUnit:GetPointVec3()
        FirstUnit:SetHeading(FirstUnit:GetHeading())
        return Coordinate
      end
      
      return nil
    end
  
  end

  do -- Zones
  
    --- Get the @{Zone#ZONE_UNIT} of a detection area using a given numeric index.
    -- @param #DETECTION_BASE self
    -- @param #number Index
    -- @return Core.Zone#ZONE_UNIT DetectedZone
    function DETECTION_BASE:GetDetectedItemZone( Index )
    
      local DetectedZone = self.DetectedItems[Index].Zone
      if DetectedZone then
        return DetectedZone
      end
      
      local Detected
      
      return nil
    end

  end  

  --- Menu of a detected item using a given numeric index.
  -- @param #DETECTION_BASE self
  -- @param Index
  -- @return #string
  function DETECTION_BASE:DetectedItemMenu( Index, AttackGroup )
    self:F( Index )
    return nil
  end

  
  --- Report summary of a detected item using a given numeric index.
  -- @param #DETECTION_BASE self
  -- @param Index
  -- @return #string
  function DETECTION_BASE:DetectedItemReportSummary( Index, AttackGroup )
    self:F( Index )
    return nil
  end
  
  --- Report detailed of a detectedion result.
  -- @param #DETECTION_BASE self
  -- @return #string
  function DETECTION_BASE:DetectedReportDetailed( AttackGroup )
    self:F()
    return nil
  end
  
  --- Get the detection Groups.
  -- @param #DETECTION_BASE self
  -- @return Core.Set#SET_GROUP
  function DETECTION_BASE:GetDetectionSetGroup()
  
    local DetectionSetGroup = self.DetectionSetGroup
    return DetectionSetGroup
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
    
    self.DetectionScheduler = SCHEDULER:New( self, self._DetectionScheduler, { self, "Detection" }, DelayTime, RepeatInterval )
    return self
  end

end

do -- DETECTION_UNITS

  --- # DETECTION_UNITS class, extends @{Detection#DETECTION_BASE}
  -- 
  -- The DETECTION_UNITS class will detect units within the battle zone.
  -- It will build a DetectedItems list filled with DetectedItems. Each DetectedItem will contain a field Set, which contains a @{Set#SET_UNIT} containing ONE @{UNIT} object reference.
  -- Beware that when the amount of units detected is large, the DetectedItems list will be large also. 
  -- 
  -- @type DETECTION_UNITS
  -- @field Dcs.DCSTypes#Distance DetectionRange The range till which targets are detected.
  -- @extends #DETECTION_BASE
  DETECTION_UNITS = {
    ClassName = "DETECTION_UNITS",
    DetectionRange = nil,
  }
  
  --- DETECTION_UNITS constructor.
  -- @param Functional.Detection#DETECTION_UNITS self
  -- @param Core.Set#SET_GROUP DetectionSetGroup The @{Set} of GROUPs in the Forward Air Controller role.
  -- @return Functional.Detection#DETECTION_UNITS self
  function DETECTION_UNITS:New( DetectionSetGroup )
  
    -- Inherits from DETECTION_BASE
    local self = BASE:Inherit( self, DETECTION_BASE:New( DetectionSetGroup ) ) -- #DETECTION_UNITS
  
    self._SmokeDetectedUnits = false
    self._FlareDetectedUnits = false
    self._SmokeDetectedZones = false
    self._FlareDetectedZones = false
    self._BoundDetectedZones = false
    
    return self
  end

  --- Make text documenting the changes of the detected zone.
  -- @param #DETECTION_UNITS self
  -- @param #DETECTION_UNITS.DetectedItem DetectedItem
  -- @return #string The Changes text
  function DETECTION_UNITS:GetChangeText( DetectedItem )
    self:F( DetectedItem )
    
    local MT = {}
    
    for ChangeCode, ChangeData in pairs( DetectedItem.Changes ) do
  
      if ChangeCode == "AU" then
        local MTUT = {}
        for ChangeUnitType, ChangeUnitCount in pairs( ChangeData ) do
          if ChangeUnitType  ~= "ItemID" then
            MTUT[#MTUT+1] = ChangeUnitCount .. " of " .. ChangeUnitType
          end
        end
        MT[#MT+1] = "   New target(s) detected: " .. table.concat( MTUT, ", " ) .. "."
      end
  
      if ChangeCode == "RU" then
        local MTUT = {}
        for ChangeUnitType, ChangeUnitCount in pairs( ChangeData ) do
          if ChangeUnitType  ~= "ItemID" then
            MTUT[#MTUT+1] = ChangeUnitCount .. " of " .. ChangeUnitType
          end
        end
        MT[#MT+1] = "   Invisible or destroyed target(s): " .. table.concat( MTUT, ", " ) .. "."
      end
      
    end
    
    return table.concat( MT, "\n" )
    
  end
  
  
  --- Create the DetectedItems list from the DetectedObjects table. 
  -- For each DetectedItem, a one field array is created containing the Unit detected.
  -- @param #DETECTION_UNITS self
  -- @return #DETECTION_UNITS self
  function DETECTION_UNITS:CreateDetectionItems()
    self:F2( #self.DetectedObjects )
  
    -- Loop the current detected items, and check if each object still exists and is detected.
    
    for DetectedItemID, DetectedItem in pairs( self.DetectedItems ) do
    
      local DetectedItemSet = DetectedItem.Set -- Core.Set#SET_UNIT
      
      for DetectedUnitName, DetectedUnitData in pairs( DetectedItemSet:GetSet() ) do
        local DetectedUnit = DetectedUnitData -- Wrapper.Unit#UNIT

        local DetectedObject = nil
        --self:E( DetectedUnit )
        if DetectedUnit:IsAlive() then
        --self:E(DetectedUnit:GetName())
          DetectedObject = self:GetDetectedObject( DetectedUnit:GetName() )
        end
        if DetectedObject then
            
          -- Yes, the DetectedUnit is still detected or exists. Flag as identified.
          self:IdentifyDetectedObject( DetectedObject )
          
          -- Update the detection with the new data provided.
          DetectedItem.TypeName = DetectedUnit:GetTypeName()            
          DetectedItem.Name = DetectedObject.Name
          DetectedItem.IsVisible = DetectedObject.IsVisible 
          DetectedItem.LastTime = DetectedObject.LastTime
          DetectedItem.LastPos = DetectedObject.LastPos
          DetectedItem.LastVelocity = DetectedObject.LastVelocity
          DetectedItem.KnowType = DetectedObject.KnowType
          DetectedItem.KnowDistance = DetectedObject.KnowDistance
          DetectedItem.Distance = DetectedObject.Distance
        else
          -- There was no DetectedObject, remove DetectedUnit from the Set.
          self:AddChangeUnit( DetectedItem, "RU", DetectedUnitName )
          DetectedItemSet:Remove( DetectedUnitName )
        end
      end
    end


    -- Now we need to loop through the unidentified detected units and add these... These are all new items.
    for DetectedUnitName, DetectedObjectData in pairs( self.DetectedObjects ) do
  
      local DetectedObject = self:GetDetectedObject( DetectedUnitName )
      if DetectedObject then
        self:T( { "Detected Unit #", DetectedUnitName } )
    
        local DetectedUnit = UNIT:FindByName( DetectedUnitName ) -- Wrapper.Unit#UNIT
        
        if DetectedUnit then
          local DetectedTypeName = DetectedUnit:GetTypeName()
          local DetectedItem = self:GetDetectedItem( DetectedUnitName )
          if not DetectedItem then
            self:T( "Added new DetectedItem" )
            DetectedItem = self:AddDetectedItem( "UNIT", DetectedUnitName )
            DetectedItem.TypeName = DetectedUnit:GetTypeName()            
            DetectedItem.Name = DetectedObject.Name
            DetectedItem.IsVisible = DetectedObject.IsVisible 
            DetectedItem.LastTime = DetectedObject.LastTime
            DetectedItem.LastPos = DetectedObject.LastPos
            DetectedItem.LastVelocity = DetectedObject.LastVelocity
            DetectedItem.KnowType = DetectedObject.KnowType
            DetectedItem.KnowDistance = DetectedObject.KnowDistance
            DetectedItem.Distance = DetectedObject.Distance
          end
        
          DetectedItem.Set:AddUnit( DetectedUnit )
          self:AddChangeUnit( DetectedItem, "AU", DetectedTypeName )
        end
      end    
    end
    
    for DetectedItemID, DetectedItemData in pairs( self.DetectedItems ) do
  
      local DetectedItem = DetectedItemData -- #DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set
  
      self:ReportFriendliesNearBy( { DetectedItem = DetectedItem, ReportSetGroup = self.DetectionSetGroup } ) -- Fill the Friendlies table
      --self:NearestFAC( DetectedItem )
    end
    
  end

  --- Menu of a DetectedItem using a given numeric index.
  -- @param #DETECTION_UNITS self
  -- @param Index
  -- @return #string
  function DETECTION_UNITS:DetectedItemMenu( Index, AttackGroup )
    self:F( Index )
  
    local DetectedItem = self:GetDetectedItem( Index )
    local DetectedSet = self:GetDetectedSet( Index )
    local DetectedItemID = self:GetDetectedItemID( Index )
    
    self:T( DetectedSet )
    if DetectedSet then
      local ReportSummary = ""
      local UnitDistanceText = ""
      local UnitCategoryText = ""
  
      local DetectedItemUnit = DetectedSet:GetFirst() -- Wrapper.Unit#UNIT
      
      if DetectedItemUnit and DetectedItemUnit:IsAlive() then
        self:T(DetectedItemUnit)
  
        local DetectedItemCoordinate = DetectedItemUnit:GetCoordinate()
        local DetectedItemCoordText = DetectedItemCoordinate:ToString( AttackGroup )
 
        ReportSummary = string.format( 
          "%s - %s",
          DetectedItemID,
          DetectedItemCoordText
        )
      end
      
      self:T( ReportSummary )
    
      return ReportSummary
    end
  end
  
  --- Report summary of a DetectedItem using a given numeric index.
  -- @param #DETECTION_UNITS self
  -- @param Index
  -- @return #string
  function DETECTION_UNITS:DetectedItemReportSummary( Index, AttackGroup )
    self:F( { Index, self.DetectedItems } )
  
    local DetectedItem = self:GetDetectedItem( Index )
    local DetectedSet = self:GetDetectedSet( Index )
    local DetectedItemID = self:GetDetectedItemID( Index )
    
    self:T( DetectedSet )
    if DetectedSet then
      local ReportSummary = ""
      local UnitDistanceText = ""
      local UnitCategoryText = ""
  
      local DetectedItemUnit = DetectedSet:GetFirst() -- Wrapper.Unit#UNIT
      
      if DetectedItemUnit and DetectedItemUnit:IsAlive() then
        self:T(DetectedItemUnit)
  
  
        if DetectedItem.KnowType then
          local UnitCategoryName = DetectedItemUnit:GetCategoryName()
          if UnitCategoryName then
            UnitCategoryText = UnitCategoryName
          end
          if DetectedItem.TypeName then
            UnitCategoryText = UnitCategoryText .. " (" .. DetectedItem.TypeName .. ")"
          end
        else
          UnitCategoryText = "Unknown"
        end
        
        if DetectedItem.KnowDistance then
          if DetectedItem.IsVisible then
            UnitDistanceText = " at " .. string.format( "%.2f", DetectedItem.Distance ) .. " km"
          end
        else
          if DetectedItem.IsVisible then
            UnitDistanceText = " at +/- " .. string.format( "%.0f", DetectedItem.Distance ) .. " km"
          end
        end
        
        local DetectedItemCoordinate = DetectedItemUnit:GetCoordinate()
        local DetectedItemCoordText = DetectedItemCoordinate:ToString( AttackGroup )
 
        local ThreatLevelA2G = DetectedItemUnit:GetThreatLevel( DetectedItem )
        
        ReportSummary = string.format( 
          "%s - %s - Threat:[%s](%2d) - %s%s",
          DetectedItemID,
          DetectedItemCoordText,
          string.rep(  "■", ThreatLevelA2G ),
          ThreatLevelA2G,
          UnitCategoryText,
          UnitDistanceText
        )
      end
      
      self:T( ReportSummary )
    
      return ReportSummary
    end
  end

  
  --- Report detailed of a detection result.
  -- @param #DETECTION_UNITS self
  -- @return #string
  function DETECTION_UNITS:DetectedReportDetailed( AttackGroup )
    self:F()
    
    local Report = REPORT:New( "Detected units:" )
    for DetectedItemID, DetectedItem in pairs( self.DetectedItems ) do
      local DetectedItem = DetectedItem -- #DETECTION_BASE.DetectedItem
      local ReportSummary = self:DetectedItemReportSummary( DetectedItemID, AttackGroup )
      Report:Add( ReportSummary )
    end
    
    local ReportText = Report:Text()
    
    return ReportText
  end

end

do -- DETECTION_TYPES

  --- # 3) DETECTION_TYPES class, extends @{Detection#DETECTION_BASE}
  -- 
  -- The DETECTION_TYPES class will detect units within the battle zone.
  -- It will build a DetectedItems[] list filled with DetectedItems, grouped by the type of units detected. 
  -- Each DetectedItem will contain a field Set, which contains a @{Set#SET_UNIT} containing ONE @{UNIT} object reference.
  -- Beware that when the amount of different types detected is large, the DetectedItems[] list will be large also. 
  -- 
  -- @type DETECTION_TYPES
  -- @extends #DETECTION_BASE
  DETECTION_TYPES = {
    ClassName = "DETECTION_TYPES",
    DetectionRange = nil,
  }
  
  --- DETECTION_TYPES constructor.
  -- @param Functional.Detection#DETECTION_TYPES self
  -- @param Core.Set#SET_GROUP DetectionSetGroup The @{Set} of GROUPs in the Recce role.
  -- @return Functional.Detection#DETECTION_TYPES self
  function DETECTION_TYPES:New( DetectionSetGroup )
  
    -- Inherits from DETECTION_BASE
    local self = BASE:Inherit( self, DETECTION_BASE:New( DetectionSetGroup ) ) -- #DETECTION_TYPES
  
    self._SmokeDetectedUnits = false
    self._FlareDetectedUnits = false
    self._SmokeDetectedZones = false
    self._FlareDetectedZones = false
    self._BoundDetectedZones = false
    
    return self
  end
  
  --- Make text documenting the changes of the detected zone.
  -- @param #DETECTION_TYPES self
  -- @param #DETECTION_TYPES.DetectedItem DetectedItem
  -- @return #string The Changes text
  function DETECTION_TYPES:GetChangeText( DetectedItem )
    self:F( DetectedItem )
    
    local MT = {}
    
    for ChangeCode, ChangeData in pairs( DetectedItem.Changes ) do
  
      if ChangeCode == "AU" then
        local MTUT = {}
        for ChangeUnitType, ChangeUnitCount in pairs( ChangeData ) do
          if ChangeUnitType  ~= "ItemID" then
            MTUT[#MTUT+1] = ChangeUnitCount .. " of " .. ChangeUnitType
          end
        end
        MT[#MT+1] = "   New target(s) detected: " .. table.concat( MTUT, ", " ) .. "."
      end
  
      if ChangeCode == "RU" then
        local MTUT = {}
        for ChangeUnitType, ChangeUnitCount in pairs( ChangeData ) do
          if ChangeUnitType  ~= "ItemID" then
            MTUT[#MTUT+1] = ChangeUnitCount .. " of " .. ChangeUnitType
          end
        end
        MT[#MT+1] = "   Invisible or destroyed target(s): " .. table.concat( MTUT, ", " ) .. "."
      end
      
    end
    
    return table.concat( MT, "\n" )
    
  end
  
  
  --- Create the DetectedItems list from the DetectedObjects table. 
  -- For each DetectedItem, a one field array is created containing the Unit detected.
  -- @param #DETECTION_TYPES self
  -- @return #DETECTION_TYPES self
  function DETECTION_TYPES:CreateDetectionItems()
    self:F2( #self.DetectedObjects )
  
    -- Loop the current detected items, and check if each object still exists and is detected.
    
    for DetectedItemID, DetectedItem in pairs( self.DetectedItems ) do
    
      local DetectedItemSet = DetectedItem.Set -- Core.Set#SET_UNIT
      local DetectedTypeName = DetectedItem.TypeName
      
      for DetectedUnitName, DetectedUnitData in pairs( DetectedItemSet:GetSet() ) do
        local DetectedUnit = DetectedUnitData -- Wrapper.Unit#UNIT

        local DetectedObject = nil
        if DetectedUnit:IsAlive() then
        --self:E(DetectedUnit:GetName())
          DetectedObject = self:GetDetectedObject( DetectedUnit:GetName() )
        end
        if DetectedObject then
            
          -- Yes, the DetectedUnit is still detected or exists. Flag as identified.
          self:IdentifyDetectedObject( DetectedObject )
        else
          -- There was no DetectedObject, remove DetectedUnit from the Set.
          self:AddChangeUnit( DetectedItem, "RU", DetectedUnitName )
          DetectedItemSet:Remove( DetectedUnitName )
        end
      end
    end


    -- Now we need to loop through the unidentified detected units and add these... These are all new items.
    for DetectedUnitName, DetectedObjectData in pairs( self.DetectedObjects ) do
  
      local DetectedObject = self:GetDetectedObject( DetectedUnitName )
      if DetectedObject then
        self:T( { "Detected Unit #", DetectedUnitName } )
    
        local DetectedUnit = UNIT:FindByName( DetectedUnitName ) -- Wrapper.Unit#UNIT
        
        if DetectedUnit then
          local DetectedTypeName = DetectedUnit:GetTypeName()
          local DetectedItem = self:GetDetectedItem( DetectedTypeName )
          if not DetectedItem then
            DetectedItem = self:AddDetectedItem( "TYPE", DetectedTypeName )
            DetectedItem.TypeName = DetectedUnit:GetTypeName()
          end
        
          DetectedItem.Set:AddUnit( DetectedUnit )
          self:AddChangeUnit( DetectedItem, "AU", DetectedTypeName )
        end
      end    
    end
    
    

    -- Check if there are any friendlies nearby.    
    for DetectedItemID, DetectedItemData in pairs( self.DetectedItems ) do
  
      local DetectedItem = DetectedItemData -- #DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set
  
      self:ReportFriendliesNearBy( { DetectedItem = DetectedItem, ReportSetGroup = self.DetectionSetGroup } ) -- Fill the Friendlies table
      --self:NearestFAC( DetectedItem )
    end
    
  end

  --- Menu of a DetectedItem using a given numeric index.
  -- @param #DETECTION_TYPES self
  -- @param Index
  -- @return #string
  function DETECTION_TYPES:DetectedItemMenu( DetectedTypeName, AttackGroup )
    self:F( DetectedTypeName )
  
    local DetectedItem = self:GetDetectedItem( DetectedTypeName )
    local DetectedSet = self:GetDetectedSet( DetectedTypeName )
    local DetectedItemID = self:GetDetectedItemID( DetectedTypeName )
    
    self:T( DetectedItem )
    if DetectedItem then

      local DetectedItemUnit = DetectedSet:GetFirst()

      local DetectedItemCoordinate = DetectedItemUnit:GetCoordinate()
      local DetectedItemCoordText = DetectedItemCoordinate:ToString( AttackGroup )
      
      --self:E( { DetectedItemID,
      --  DetectedItemCoordText } )

      local ReportSummary = string.format( 
        "%s - %s", 
        DetectedItemID,
        DetectedItemCoordText
      )
      self:T( ReportSummary )
    
      return ReportSummary
    end
  end
  
  --- Report summary of a DetectedItem using a given numeric index.
  -- @param #DETECTION_TYPES self
  -- @param Index
  -- @return #string
  function DETECTION_TYPES:DetectedItemReportSummary( DetectedTypeName, AttackGroup )
    self:F( DetectedTypeName )
  
    local DetectedItem = self:GetDetectedItem( DetectedTypeName )
    local DetectedSet = self:GetDetectedSet( DetectedTypeName )
    local DetectedItemID = self:GetDetectedItemID( DetectedTypeName )
    
    self:T( DetectedItem )
    if DetectedItem then

      local ThreatLevelA2G = DetectedSet:CalculateThreatLevelA2G()
      local DetectedItemsCount = DetectedSet:Count()
      local DetectedItemType = DetectedItem.TypeName
      
      local DetectedItemUnit = DetectedSet:GetFirst()

      local DetectedItemCoordinate = DetectedItemUnit:GetCoordinate()
      local DetectedItemCoordText = DetectedItemCoordinate:ToString( AttackGroup )

      local ReportSummary = string.format( 
        "%s - %s - Threat:[%s](%2d) - %2d of %s", 
        DetectedItemID,
        DetectedItemCoordText,
        string.rep(  "■", ThreatLevelA2G ),
        ThreatLevelA2G,
        DetectedItemsCount,
        DetectedItemType
      )
      self:T( ReportSummary )
    
      return ReportSummary
    end
  end
  
  --- Report detailed of a detection result.
  -- @param #DETECTION_TYPES self
  -- @return #string
  function DETECTION_TYPES:DetectedReportDetailed( AttackGroup )
    self:F()
    
    local Report = REPORT:New( "Detected types:" )
    for DetectedItemTypeName, DetectedItem in pairs( self.DetectedItems ) do
      local DetectedItem = DetectedItem -- #DETECTION_BASE.DetectedItem
      local ReportSummary = self:DetectedItemReportSummary( DetectedItemTypeName, AttackGroup )
      Report:Add( ReportSummary )
    end
    
    local ReportText = Report:Text()
    
    return ReportText
  end

end


do -- DETECTION_AREAS

  --- # 4) DETECTION_AREAS class, extends @{Detection#DETECTION_BASE}
  -- 
  -- The DETECTION_AREAS class will detect units within the battle zone for a list of @{Group}s detecting targets following (a) detection method(s), 
  -- and will build a list (table) of @{Set#SET_UNIT}s containing the @{Unit#UNIT}s detected.
  -- The class is group the detected units within zones given a DetectedZoneRange parameter.
  -- A set with multiple detected zones will be created as there are groups of units detected.
  -- 
  -- ## 4.1) Retrieve the Detected Unit Sets and Detected Zones
  -- 
  -- The methods to manage the DetectedItems[].Set(s) are implemented in @{Detection#DECTECTION_BASE} and 
  -- the methods to manage the DetectedItems[].Zone(s) is implemented in @{Detection#DETECTION_AREAS}.
  -- 
  -- Retrieve the DetectedItems[].Set with the method @{Detection#DETECTION_BASE.GetDetectedSet}(). A @{Set#SET_UNIT} object will be returned.
  -- 
  -- Retrieve the formed @{Zone@ZONE_UNIT}s as a result of the grouping the detected units within the DetectionZoneRange, use the method @{Detection#DETECTION_BASE.GetDetectionZones}().
  -- To understand the amount of zones created, use the method @{Detection#DETECTION_BASE.GetDetectionZoneCount}(). 
  -- If you want to obtain a specific zone from the DetectedZones, use the method @{Detection#DETECTION_BASE.GetDetectionZone}() with a given index.
  -- 
  -- ## 4.4) Flare or Smoke detected units
  -- 
  -- Use the methods @{Detection#DETECTION_AREAS.FlareDetectedUnits}() or @{Detection#DETECTION_AREAS.SmokeDetectedUnits}() to flare or smoke the detected units when a new detection has taken place.
  -- 
  -- ## 4.5) Flare or Smoke or Bound detected zones
  -- 
  -- Use the methods:
  -- 
  --   * @{Detection#DETECTION_AREAS.FlareDetectedZones}() to flare in a color 
  --   * @{Detection#DETECTION_AREAS.SmokeDetectedZones}() to smoke in a color
  --   * @{Detection#DETECTION_AREAS.SmokeDetectedZones}() to bound with a tire with a white flag
  --   
  -- the detected zones when a new detection has taken place.
  -- 
  -- @type DETECTION_AREAS
  -- @field Dcs.DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
  -- @field #DETECTION_BASE.DetectedItems DetectedItems A list of areas containing the set of @{Unit}s, @{Zone}s, the center @{Unit} within the zone, and ID of each area that was detected within a DetectionZoneRange.
  -- @extends #DETECTION_BASE
  DETECTION_AREAS = {
    ClassName = "DETECTION_AREAS",
    DetectionZoneRange = nil,
  }
  
  
  --- DETECTION_AREAS constructor.
  -- @param #DETECTION_AREAS self
  -- @param Core.Set#SET_GROUP DetectionSetGroup The @{Set} of GROUPs in the Forward Air Controller role.
  -- @param Dcs.DCSTypes#Distance DetectionZoneRange The range till which targets are grouped upon the first detected target.
  -- @return #DETECTION_AREAS
  function DETECTION_AREAS:New( DetectionSetGroup, DetectionZoneRange )
  
    -- Inherits from DETECTION_BASE
    local self = BASE:Inherit( self, DETECTION_BASE:New( DetectionSetGroup ) )
  
    self.DetectionZoneRange = DetectionZoneRange
    
    self._SmokeDetectedUnits = false
    self._FlareDetectedUnits = false
    self._SmokeDetectedZones = false
    self._FlareDetectedZones = false
    self._BoundDetectedZones = false
    
    return self
  end

  --- Menu of a detected item using a given numeric index.
  -- @param #DETECTION_AREAS self
  -- @param Index
  -- @return #string
  function DETECTION_AREAS:DetectedItemMenu( Index, AttackGroup )
    self:F( Index )
  
    local DetectedItem = self:GetDetectedItem( Index )
    local DetectedItemID = self:GetDetectedItemID( Index )
    
    if DetectedItem then
      local DetectedSet = self:GetDetectedSet( Index )
      local ReportSummaryItem
      
      local DetectedZone = self:GetDetectedItemZone( Index )
      local DetectedItemCoordinate = DetectedZone:GetCoordinate()
      local DetectedItemCoordText = DetectedItemCoordinate:ToString( AttackGroup )

      local ReportSummary = string.format( 
        "%s - %s", 
        DetectedItemID,
        DetectedItemCoordText
      )
      
      return ReportSummary
    end
    
    return nil
  end
  
  --- Report summary of a detected item using a given numeric index.
  -- @param #DETECTION_AREAS self
  -- @param Index
  -- @return #string
  function DETECTION_AREAS:DetectedItemReportSummary( Index, AttackGroup )
    self:F( Index )
  
    local DetectedItem = self:GetDetectedItem( Index )
    local DetectedItemID = self:GetDetectedItemID( Index )
    
    if DetectedItem then
      local DetectedSet = self:GetDetectedSet( Index )
      local ReportSummaryItem
      
      local DetectedZone = self:GetDetectedItemZone( Index )
      local DetectedItemCoordinate = DetectedZone:GetCoordinate()
      local DetectedItemCoordText = DetectedItemCoordinate:ToString( AttackGroup )

      local ThreatLevelA2G = self:GetTreatLevelA2G( DetectedItem )
      local DetectedItemsCount = DetectedSet:Count()
      local DetectedItemsTypes = DetectedSet:GetTypeNames()
      
      local ReportSummary = string.format( 
        "%s - %s - Threat:[%s](%2d)\n   %2d of %s", 
        DetectedItemID,
        DetectedItemCoordText,
        string.rep(  "■", ThreatLevelA2G ),
        ThreatLevelA2G,
        DetectedItemsCount,
        DetectedItemsTypes
      )
      
      return ReportSummary
    end
    
    return nil
  end

  --- Report detailed of a detection result.
  -- @param #DETECTION_AREAS self
  -- @return #string
  function DETECTION_AREAS:DetectedReportDetailed( AttackGroup) --R2.1  Fixed missing report
    self:F()
    
    local Report = REPORT:New( "Detected areas:" )
    for DetectedItemIndex, DetectedItem in pairs( self.DetectedItems ) do
      local DetectedItem = DetectedItem -- #DETECTION_BASE.DetectedItem
      local ReportSummary = self:DetectedItemReportSummary( DetectedItemIndex, AttackGroup )
      Report:Add( ReportSummary )
    end
    
    local ReportText = Report:Text()
    
    return ReportText
  end

  
  --- Calculate the maxium A2G threat level of the DetectedItem.
  -- @param #DETECTION_AREAS self
  -- @param #DETECTION_BASE.DetectedItem DetectedItem
  function DETECTION_AREAS:CalculateThreatLevelA2G( DetectedItem )
    
    local MaxThreatLevelA2G = 0
    for UnitName, UnitData in pairs( DetectedItem.Set:GetSet() ) do
      local ThreatUnit = UnitData -- Wrapper.Unit#UNIT
      local ThreatLevelA2G = ThreatUnit:GetThreatLevel()
      if ThreatLevelA2G > MaxThreatLevelA2G then
        MaxThreatLevelA2G = ThreatLevelA2G
      end
    end
  
    self:T3( MaxThreatLevelA2G )
    DetectedItem.MaxThreatLevelA2G = MaxThreatLevelA2G
    
  end
  
  --- Find the nearest FAC of the DetectedItem.
  -- @param #DETECTION_AREAS self
  -- @param #DETECTION_BASE.DetectedItem DetectedItem
  -- @return Wrapper.Unit#UNIT The nearest FAC unit
  function DETECTION_AREAS:NearestFAC( DetectedItem )
    
    local NearestFAC = nil
    local MinDistance = 1000000000 -- Units are not further than 1000000 km away from an area :-)
    
    for FACGroupName, FACGroupData in pairs( self.DetectionSetGroup:GetSet() ) do
      for FACUnit, FACUnitData in pairs( FACGroupData:GetUnits() ) do
        local FACUnit = FACUnitData -- Wrapper.Unit#UNIT
        if FACUnit:IsActive() then
          local Vec3 = FACUnit:GetVec3()
          local PointVec3 = POINT_VEC3:NewFromVec3( Vec3 )
          local Distance = PointVec3:Get2DDistance(POINT_VEC3:NewFromVec3( FACUnit:GetVec3() ) )
          if Distance < MinDistance then
            MinDistance = Distance
            NearestFAC = FACUnit
          end
        end
      end
    end
  
    DetectedItem.NearestFAC = NearestFAC
    
  end
  
  --- Returns the A2G threat level of the units in the DetectedItem
  -- @param #DETECTION_AREAS self
  -- @param #DETECTION_BASE.DetectedItem DetectedItem
  -- @return #number a scale from 0 to 10. 
  function DETECTION_AREAS:GetTreatLevelA2G( DetectedItem )
    
    self:T3( DetectedItem.MaxThreatLevelA2G )
    return DetectedItem.MaxThreatLevelA2G
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

  --- Bound the detected zones
  -- @param #DETECTION_AREAS self
  -- @return #DETECTION_AREAS self
  function DETECTION_AREAS:BoundDetectedZones()
    self:F2()
  
    self._BoundDetectedZones = true
    return self
  end
  
  --- Make text documenting the changes of the detected zone.
  -- @param #DETECTION_AREAS self
  -- @param #DETECTION_BASE.DetectedItem DetectedItem
  -- @return #string The Changes text
  function DETECTION_AREAS:GetChangeText( DetectedItem )
    self:F( DetectedItem )
    
    local MT = {}
    
    for ChangeCode, ChangeData in pairs( DetectedItem.Changes ) do
  
      if ChangeCode == "AA" then
        MT[#MT+1] = "Detected new area " .. ChangeData.ItemID .. ". The center target is a " .. ChangeData.ItemUnitType .. "."
      end
  
      if ChangeCode == "RAU" then
        MT[#MT+1] = "Changed area " .. ChangeData.ItemID .. ". Removed the center target."
      end
      
      if ChangeCode == "AAU" then
        MT[#MT+1] = "Changed area " .. ChangeData.ItemID .. ". The new center target is a " .. ChangeData.ItemUnitType .. "."
      end
      
      if ChangeCode == "RA" then
        MT[#MT+1] = "Removed old area " .. ChangeData.ItemID .. ". No more targets in this area."
      end
      
      if ChangeCode == "AU" then
        local MTUT = {}
        for ChangeUnitType, ChangeUnitCount in pairs( ChangeData ) do
          if ChangeUnitType  ~= "ItemID" then
            MTUT[#MTUT+1] = ChangeUnitCount .. " of " .. ChangeUnitType
          end
        end
        MT[#MT+1] = "Detected for area " .. ChangeData.ItemID .. " new target(s) " .. table.concat( MTUT, ", " ) .. "."
      end
  
      if ChangeCode == "RU" then
        local MTUT = {}
        for ChangeUnitType, ChangeUnitCount in pairs( ChangeData ) do
          if ChangeUnitType  ~= "ItemID" then
            MTUT[#MTUT+1] = ChangeUnitCount .. " of " .. ChangeUnitType
          end
        end
        MT[#MT+1] = "Removed for area " .. ChangeData.ItemID .. " invisible or destroyed target(s) " .. table.concat( MTUT, ", " ) .. "."
      end
      
    end
    
    return table.concat( MT, "\n" )
    
  end
  
  
  --- Make a DetectionSet table. This function will be overridden in the derived clsses.
  -- @param #DETECTION_AREAS self
  -- @return #DETECTION_AREAS self
  function DETECTION_AREAS:CreateDetectionItems()
    self:F2()
  
  
    self:T( "Checking Detected Items for new Detected Units ..." )
    -- First go through all detected sets, and check if there are new detected units, match all existing detected units and identify undetected units.
    -- Regroup when needed, split groups when needed.
    for DetectedItemID, DetectedItemData in pairs( self.DetectedItems ) do
      
      local DetectedItem = DetectedItemData -- #DETECTION_BASE.DetectedItem
      if DetectedItem then
      
        self:T( { "Detected Item ID:", DetectedItemID } )
        
      
        local DetectedSet = DetectedItem.Set
        
        local AreaExists = false -- This flag will determine of the detected area is still existing.
              
        -- First test if the center unit is detected in the detection area.
        self:T3( { "Zone Center Unit:", DetectedItem.Zone.ZoneUNIT.UnitName } )
        local DetectedZoneObject = self:GetDetectedObject( DetectedItem.Zone.ZoneUNIT.UnitName )
        self:T3( { "Detected Zone Object:", DetectedItem.Zone:GetName(), DetectedZoneObject } )
        
        if DetectedZoneObject then
  
          --self:IdentifyDetectedObject( DetectedZoneObject )
          AreaExists = true
  
  
        
        else
          -- The center object of the detected area has not been detected. Find an other unit of the set to become the center of the area.
          -- First remove the center unit from the set.
          DetectedSet:RemoveUnitsByName( DetectedItem.Zone.ZoneUNIT.UnitName )
  
          self:AddChangeItem( DetectedItem, 'RAU', "Dummy" )
          
          -- Then search for a new center area unit within the set. Note that the new area unit candidate must be within the area range.
          for DetectedUnitName, DetectedUnitData in pairs( DetectedSet:GetSet() ) do
   
            local DetectedUnit = DetectedUnitData -- Wrapper.Unit#UNIT
            local DetectedObject = self:GetDetectedObject( DetectedUnit.UnitName ) 
  
            -- The DetectedObject can be nil when the DetectedUnit is not alive anymore or it is not in the DetectedObjects map.
            -- If the DetectedUnit was already identified, DetectedObject will be nil.
            if DetectedObject then
              self:IdentifyDetectedObject( DetectedObject )
              AreaExists = true
  
              --DetectedItem.Zone:BoundZone( 12, self.CountryID, true)
  
              -- Assign the Unit as the new center unit of the detected area.
              DetectedItem.Zone = ZONE_UNIT:New( DetectedUnit:GetName(), DetectedUnit, self.DetectionZoneRange )
  
              self:AddChangeItem( DetectedItem, "AAU", DetectedItem.Zone.ZoneUNIT:GetTypeName() )
  
              -- We don't need to add the DetectedObject to the area set, because it is already there ...
              break
            else
              DetectedSet:Remove( DetectedUnitName )
              self:AddChangeUnit( DetectedItem, "RU", DetectedUnit:GetTypeName() )
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
  
            local DetectedUnit = DetectedUnitData -- Wrapper.Unit#UNIT
            local DetectedObject = nil
            if DetectedUnit:IsAlive() then
            --self:E(DetectedUnit:GetName())
              DetectedObject = self:GetDetectedObject( DetectedUnit:GetName() )
            end
            if DetectedObject then
            
              -- Check if the DetectedUnit is within the DetectedItem.Zone
              if DetectedUnit:IsInZone( DetectedItem.Zone ) then
                
                -- Yes, the DetectedUnit is within the DetectedItem.Zone, no changes, DetectedUnit can be kept within the Set.
                self:IdentifyDetectedObject( DetectedObject )
  
              else
                -- No, the DetectedUnit is not within the DetectedItem.Zone, remove DetectedUnit from the Set.
                DetectedSet:Remove( DetectedUnitName )
                self:AddChangeUnit( DetectedItem, "RU", DetectedUnit:GetTypeName() )
              end
            
            else
              -- There was no DetectedObject, remove DetectedUnit from the Set.
              self:AddChangeUnit( DetectedItem, "RU", "destroyed target" )
              DetectedSet:Remove( DetectedUnitName )
  
              -- The DetectedObject has been identified, because it does not exist ...
              -- self:IdentifyDetectedObject( DetectedObject )
            end
          end
        else
          --DetectedItem.Zone:BoundZone( 12, self.CountryID, true)
          self:RemoveDetectedItem( DetectedItemID )
          self:AddChangeItem( DetectedItem, "RA" )
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
        local DetectedUnit = UNIT:FindByName( DetectedUnitName ) -- Wrapper.Unit#UNIT
        
        local AddedToDetectionArea = false
      
        for DetectedItemID, DetectedItemData in pairs( self.DetectedItems ) do
          
          local DetectedItem = DetectedItemData -- #DETECTION_BASE.DetectedItem
          if DetectedItem then
            self:T( "Detection Area #" .. DetectedItem.ItemID )
            local DetectedSet = DetectedItem.Set
            if not self:IsDetectedObjectIdentified( DetectedObject ) and DetectedUnit:IsInZone( DetectedItem.Zone ) then
              self:IdentifyDetectedObject( DetectedObject )
              DetectedSet:AddUnit( DetectedUnit )
              AddedToDetectionArea = true
              self:AddChangeUnit( DetectedItem, "AU", DetectedUnit:GetTypeName() )
            end
          end
        end
      
        if AddedToDetectionArea == false then
        
          -- New detection area
          local DetectedItem = self:AddDetectedItemZone( nil, 
            SET_UNIT:New():FilterDeads():FilterCrashes(),
            ZONE_UNIT:New( DetectedUnitName, DetectedUnit, self.DetectionZoneRange )
          )
          --self:E( DetectedItem.Zone.ZoneUNIT.UnitName )
          DetectedItem.Set:AddUnit( DetectedUnit )
          self:AddChangeItem( DetectedItem, "AA", DetectedUnit:GetTypeName() )
        end  
      end
    end
    
    -- Now all the tests should have been build, now make some smoke and flares...
    -- We also report here the friendlies within the detected areas.
    
    for DetectedItemID, DetectedItemData in pairs( self.DetectedItems ) do
  
      local DetectedItem = DetectedItemData -- #DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set
      local DetectedZone = DetectedItem.Zone
  
      self:ReportFriendliesNearBy( { DetectedItem = DetectedItem, ReportSetGroup = self.DetectionSetGroup } ) -- Fill the Friendlies table
      self:CalculateThreatLevelA2G( DetectedItem )  -- Calculate A2G threat level
      self:NearestFAC( DetectedItem )
  
      if DETECTION_AREAS._SmokeDetectedUnits or self._SmokeDetectedUnits then
        DetectedZone.ZoneUNIT:SmokeRed()
      end
      
      --DetectedSet:Flush()
      
      DetectedSet:ForEachUnit(
        --- @param Wrapper.Unit#UNIT DetectedUnit
        function( DetectedUnit )
          if DetectedUnit:IsAlive() then
            --self:T( "Detected Set #" .. DetectedItem.ItemID .. ":" .. DetectedUnit:GetName() )
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
        DetectedZone:FlareZone( SMOKECOLOR.White, 30, math.random( 0,90 ) )
      end
      if DETECTION_AREAS._SmokeDetectedZones or self._SmokeDetectedZones then
        DetectedZone:SmokeZone( SMOKECOLOR.White, 30 )
      end

      if DETECTION_AREAS._BoundDetectedZones or self._BoundDetectedZones then
        DetectedZone:BoundZone( 12, self.CountryID )
      end
    end
  
  end
  
end  
