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
  -- Blabla. 
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
    Homebase  = {},
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
  function AI_G2G_DISPATCHER:AddTransportAPC(group, homebase, resources)
    self.TransportAPC[group]={}
    self.TransportAPC[group].group=group
    self.TransportAPC[group].homebase=homebase
    self.TransportAPC[group].resources=resources
    
    -- Add homebase
    if not self:GetHomebase(homebase) then
      self:AddHomebase(homebase)
    end
  end

  --- Adds an APC group to transport troops to the front line.
  -- @param #AI_G2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.  
  function AI_G2G_DISPATCHER:EvaluateDetectedItem(DetectedItem)
    local _coord=DetectedItem.Coordinate
    _coord:MarkToAll("detected")
    
    
    local _id=DetectedItem.ID
    
    
    
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



do

  --- WAREHOUSE class.
  -- @type WAREHOUSE
  -- @field #string ClassName Name of the class.
  -- @extends Core.Fsm#FSM

  --- Create an automatic ground . 
  -- 
  -- ===
  -- 
  -- # Demo Missions
  -- 
  -- ### None.
  -- 
  -- ===
  -- 
  -- # YouTube Channel
  -- 
  -- ### None.
  -- 
  -- ===
  -- 
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia3.JPG)
  -- 
  -- Warehouse
  -- 
  -- ===
  --
  -- # USAGE GUIDE
  -- 
  -- 
  -- 
  -- @field #WAREHOUSE
  WAREHOUSE = {
    ClassName = "WAREHOUSE",
    Homebase  = nil,
    plane = {},
    helicopter = {},
    artillery={},
    tank = {},
    apcs = {},
    infantry={},
  }
  
  WAREHOUSE.category= {
    Transport=1,
    Figherplane=1,
    AWACS=1,
    Tanker=1,
    
  }

  --- WAREHOUSE constructor. Creates a new WAREHOUSE object.
  -- @param #WAREHOUSE self
  -- @param Wrapper.Airbase#AIRBASE airbase Airbase.
  -- @return #WAREHOUSE self
  function WAREHOUSE:NewAirbase(airbase)

    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, FSM:New() ) -- #WAREHOUSE
    
    self.Homebase=airbase
    
    return self
  end
  
  --- Add an airplane group to the warehouse stock.
  -- @param #WAREHOUSE self
  -- @param #string templateprefix Name of the late activated template group as defined in the mission editor.
  -- @param #number n Number of groups to add to the warehouse stock.
  -- @return #WAREHOUSE self
  function WAREHOUSE:AddAirplane(templateprefix, n, warehousetype)
    
    local group=GROUP:FindByName(templateprefix)
    local typename=group:GetDesc().typeName
    local displayname=group:GetDesc().displayName
    
    -- Create a table with properties.
    self.airplane[templateprefix]=self.airplane[templateprefix] or {}
    
    -- Increase number in stock.
    if self.airplane[templateprefix].nstock then
      self.airplane[templateprefix].nstock=self.airplane[templateprefix].nstock+n
    else
      self.airplane[templateprefix].nstock=n
    end
    
    self.airplane[templateprefix].nstock=n
    
  end

end



