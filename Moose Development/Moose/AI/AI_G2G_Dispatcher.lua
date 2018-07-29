--- **AI** - (R2.4) - Manages automatic ground troups dispatching to the battle field.
-- 
-- 
-- Features:
-- 
--    * Some nice stuff.
-- 
-- # QUICK START GUIDE
-- 
-- ===
-- 
-- ### Authors: **funkyfranky**
-- 
-- @module AI.AI_G2G_Dispatcher
-- @image AI_Air_To_Air_Dispatching.JPG

do -- AI_G2G_DISPATCHER

  --- AI_G2G_DISPATCHER class.
  -- @type AI_G2G_DISPATCHER
  -- @field #string ClassName Name of the class.
  -- @field Functional.Detection#DETECTION_AREAS Detection Detection object responsible for identifying enemies.
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER

  --- Create an automatic ground . 
  -- 
  -- ===
  -- 
  -- # Demo Missions
  -- 
  -- ### [AI\_A2A\_DISPATCHER Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/release-2-2-pre/AID%20-%20AI%20Dispatching)
  -- 
  -- ===
  -- 
  -- # YouTube Channel
  -- 
  -- ### [DCS WORLD - MOOSE - A2A GCICAP - Build an automatic A2A Defense System](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl0S4KMNUUJpaUs6zZHjLKNx)
  -- 
  -- ===
  -- 
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia3.JPG)
  -- 
  -- It includes automatic spawning of Combat Air Patrol aircraft (CAP) and Ground Controlled Intercept aircraft (GCI) in response to enemy air movements that are detected by a ground based radar network. 
  -- CAP flights will take off and proceed to designated CAP zones where they will remain on station until the ground radars direct them to intercept detected enemy aircraft or they run short of fuel and must return to base (RTB). When a CAP flight leaves their zone to perform an interception or return to base a new CAP flight will spawn to take their place.
  -- If all CAP flights are engaged or RTB then additional GCI interceptors will scramble to intercept unengaged enemy aircraft under ground radar control.
  -- With a little time and with a little work it provides the mission designer with a convincing and completely automatic air defence system. 
  -- In short it is a plug in very flexible and configurable air defence module for DCS World.
  -- 
  -- Note that in order to create a two way A2A defense system, two AI\_A2A\_DISPATCHER defense system may need to be created, for each coalition one.
  -- This is a good implementation, because maybe in the future, more coalitions may become available in DCS world.
  -- 
  -- ===
  --
  -- # USAGE GUIDE
  -- 
  -- 
  -- 
  -- @field #AI_G2G_DISPATCHER
  AI_G2G_DISPATCHER = {
    ClassName = "AI_G2G_DISPATCHER",
    Detection = nil,
  }


  
  --- AI_G2G_DISPATCHER constructor. Creates a new AI_G2G_DISPATCHER object.
  -- @param #AI_G2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The DETECTION object that will detects targets using the the Early Warning Radar network.
  -- @return #AI_G2G_DISPATCHER self
  function AI_G2G_DISPATCHER:New(Detection)

    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit(self, DETECTION_MANAGER:New(nil, Detection)) -- #AI_G2G_DISPATCHER
    
    self.Detection = Detection -- Functional.Detection#DETECTION_AREAS
    
    self:AddTransition( "Started", "Assign", "Started" )
    
    self:__Start(5)
    
    return self
  end

  --- Adds an APC group to transport troops to the front line.
  -- @param #AI_G2G_DISPATCHER self  
  -- @param Wrapper.Group#GROUP group APC group.
  -- @return #AI_G2G_DISPATCHER self
  function AI_G2G_DISPATCHER:SetTransportAPC(group)
    
    
  end

  --- Adds an APC group to transport troops to the front line.
  -- @param #AI_G2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.  
  function AI_G2G_DISPATCHER:EvaluateDetectedItem(DetectedItem)
    local _coord=DetectedItem.Coordinate
    _coord:MarkToAll("detected")
  end

  --- Adds an APC group to transport troops to the front line.
  -- @param #AI_G2G_DISPATCHER self  
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Functional.Detection#DETECTION_BASE} derived object.
  -- @return #boolean True if you want the task assigning to continue while false will cancel the loop.    
  function AI_G2G_DISPATCHER:ProcessDetected(Detection)
  
  
    -- Now that all obsolete tasks are removed, loop through the detected targets.
    for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
    
      local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
      local DetectedCount = DetectedSet:Count()
      local DetectedZone = DetectedItem.Zone

      self:F( { "Target ID", DetectedItem.ItemID } )
      DetectedSet:Flush( self )

      local DetectedID = DetectedItem.ID
      local DetectionIndex = DetectedItem.Index
      local DetectedItemChanged = DetectedItem.Changed
      
      env.info(string.format("FF detected item id %d, index = %d, changed = %s", DetectedID, DetectedItem.Index, tostring(DetectedItem.Changed)))
      
      
      
    end
  end

end

