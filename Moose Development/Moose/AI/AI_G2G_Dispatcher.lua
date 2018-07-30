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
    coalition = nil,
    homebase  = nil,
    plane    = {},
    helo     = {},
    arty     = {},
    tank     = {},
    apc      = {},
    infantry = {},
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

    -- Inherits from FSM
    local self = BASE:Inherit( self, FSM:New() ) -- #WAREHOUSE
    
    self.homebase=airbase
    self.coordinate=airbase:GetCoordinate()
    self.coalition=airbase:GetCoalition()
    
    
    self:AddTransition("*", "Start", "Idle")
    self:AddTransition("*", "Status", "*")
    self:AddTransition("*", "Request", "*")
    
    --- Triggers the FSM event "Start".
    -- @function [parent=#WAREHOUSE] Start
    -- @param #WAREHOUSE self
  
    --- Triggers the FSM event "Start" after a delay.
    -- @function [parent=#WAREHOUSE] __Start
    -- @param #WAREHOUSE self
    -- @param #number delay Delay in seconds.

  
    --- Triggers the FSM event "Status".
    -- @function [parent=#WAREHOUSE] Status
    -- @param #WAREHOUSE self
  
    --- Triggers the FSM event "Status" after a delay.
    -- @function [parent=#WAREHOUSE] __Status
    -- @param #WAREHOUSE self
    -- @param #number delay Delay in seconds.
          

    --- Triggers the FSM event "Request".
    -- @function [parent=#WAREHOUSE] Request
    -- @param #WAREHOUSE self
    -- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
    -- @param #string Asset Asset that is requested.
    -- @param #string TransportType Type of transport: "Plane", "Helicopter", "APC"
  
    --- Triggers the FSM event "Request" after a delay.
    -- @function [parent=#WAREHOUSE] __Request
    -- @param #WAREHOUSE self
    -- @param #number delay Delay in seconds.
    -- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
    -- @param #string Asset Asset that is requested.
    -- @param #string TransportType Type of transport: "Plane", "Helicopter", "APC"
    
    return self
  end

  --- Warehouse
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  function WAREHOUSE:onafterStart(From, Event, To)
    env.info("FF starting warehouse of airbase of "..self.homebase:GetName())
    
    -- handle events
    -- event takeoff
    -- event landing
    -- event crash/dead
    -- event base captured
    self:__Status(-5)
  end
  

  --- Warehouse
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  function WAREHOUSE:onafterStatus(From, Event, To)
    env.info("FF checking warehouse status of "..self.homebase:GetName())
    
    env.info(string.format("FF warehouse at %s: number of transport planes = %d", self.homebase:GetName(), #self.plane))
    
    self:__Status(-30)
  end

  --- Warehouse
  -- @param #WAREHOUSE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase requesting supply.
  -- @param #string Asset Asset that is requested.
  -- @param #number nAssed Number of groups of that asset requested.
  -- @param #string TransportType Type of transport: "Plane", "Helicopter", "APC"
  function WAREHOUSE:onafterRequest(From, Event, To, Airbase, Asset, nAsset, TransportType)
    env.info(string.format("FF airbase %s is requesting asset %s from warehouse %s", Airbase:GetName(), Asset, self.homebase:GetName()))
    
    local nAsset=nAsset or 1
    
    if TransportType=="Air" then
    
      local template=self.plane[math.random(#self.plane)]
      
      if template then
      
        local Plane=SPAWN:New(template):SpawnAtAirbase(Airbase, nil, nil, nil, false)
        
        local CargoGroups = SET_CARGO:New()
        
        local spawn=SPAWN:New("Infantry Platoon Alpha")
        
        for i=1,nAsset do
          local spawngroup=spawn:SpawnFromVec3(self.homebase:GetZone():GetRandomPointVec3(100,500))
          local cargogroup = CARGO_GROUP:New(spawngroup, "Infantry", string.format( "Infantry Platoon %d", i), 5000, 35)
          CargoGroups:AddCargo(cargogroup)  
        end
        
        local CargoPlane  = AI_CARGO_AIRPLANE:New(Plane, CargoGroups)
        
        CargoPlane:__Pickup(5, self.homebase)
        
        function CargoPlane:onafterLoaded( Airplane, From, Event, To, Cargo)
          CargoPlane:__Deploy(10, Airbase, 500)
        end
        
                
      end
    end
    
  end
  
  --- Add an airplane group to the warehouse stock.
  -- @param #WAREHOUSE self
  -- @param #string templateprefix Name of the late activated template group as defined in the mission editor.
  -- @param #number n Number of groups to add to the warehouse stock.
  -- @return #WAREHOUSE self
  function WAREHOUSE:AddTransportPlane(templateprefix, n)
  
    local n=n or 1
    
    local group=GROUP:FindByName(templateprefix)
    local DCSgroup=group:GetDCSObject()
    local DCSunit=DCSgroup:getUnit(1)
    local DCSdesc=DCSunit:getDesc()
    local DCSdisplay=DCSunit:getDesc().displayName
    local DCScategory=DCSgroup:getCategory()
    local DCStype=DCSunit:getTypeName()
    
    --env.info(string.format("FF adding %d transport plane template %s type %s, display %s", n, tostring(templateprefix), tostring(typename), tostring(displayname)))

    --[[    
    -- Create a table with properties.
    self.airplane[templateprefix]=self.airplane[templateprefix] or {}
    
    -- Increase number in stock.
    if self.airplane[templateprefix].nstock then
      self.airplane[templateprefix].nstock=self.airplane[templateprefix].nstock+n
    else
      self.airplane[templateprefix].nstock=n
    end
    
    self.airplane[templateprefix].nstock=n
    ]]
    
    for i=1,n do
      table.insert(self.plane, templateprefix)
    end
    
  end

end



