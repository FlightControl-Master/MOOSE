--- **Ops** -- Combat Troops & Logistics Deployment.
--
-- ===
-- 
-- **CTLD** - MOOSE based Helicopter CTLD Operations.
-- 
-- ===
-- 
-- ## Missions:
--
-- ### [CTLD - Combat Troop & Logistics Deployment](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/)
-- 
-- ===
-- 
-- **Main Features:**
--
--    * MOOSE-based Helicopter CTLD Operations for Players.
--
-- ===
--
-- ### Author: **Applevangelist** (Moose Version), ***Ciribob*** (original)
-- @module Ops.CTLD
-- @image OPS_CTLD.jpg

-- Date: June 2021

do
------------------------------------------------------
--- **CTLD_CARGO** class, extends #Core.Base#BASE
-- @type CTLD_CARGO
-- @field #number ID ID of this cargo.
-- @field #string Name Name for menu.
-- @field #table Templates Table of #POSITIONABLE objects.
-- @field #CTLD_CARGO.Enum Type Enumerator of Type.
-- @field #boolean HasBeenMoved Flag for moving.
-- @field #boolean LoadDirectly Flag for direct loading.
-- @field #number CratesNeeded Crates needed to build.
-- @field Wrapper.Positionable#POSITIONABLE Positionable Representation of cargo in the mission.
-- @field #boolean HasBeenDropped True if dropped from heli.
-- @extends Core.Fsm#FSM
CTLD_CARGO = {
  ClassName = "CTLD_CARGO",
  ID = 0,
  Name = "none",
  Templates = {},
  CargoType = "none",
  HasBeenMoved = false,
  LoadDirectly = false,
  CratesNeeded = 0,
  Positionable = nil,
  HasBeenDropped = false,
  }
  
  --- Define cargo types.
  -- @type CTLD_CARGO.Enum
  -- @field #string Type Type of Cargo.
  CTLD_CARGO.Enum = {
    VEHICLE = "Vehicle", -- #string vehicles
    TROOPS = "Troops", -- #string troops
    FOB = "FOB", -- #string FOB
    CRATE = "CRATE", -- #string crate
  }
  
  --- Function to create new CTLD_CARGO object.
  -- @param #CTLD_CARGO self
  -- @param #number ID ID of this #CTLD_CARGO
  -- @param #string Name Name for menu.
  -- @param #table Templates Table of #POSITIONABLE objects.
  -- @param #CTLD_CARGO.Enum Sorte Enumerator of Type.
  -- @param #boolean HasBeenMoved Flag for moving.
  -- @param #boolean LoadDirectly Flag for direct loading.
  -- @param #number CratesNeeded Crates needed to build.
  -- @param Wrapper.Positionable#POSITIONABLE Positionable Representation of cargo in the mission.
  -- @param #boolean Dropped Cargo/Troops have been unloaded from a chopper.
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:New(ID, Name, Templates, Sorte, HasBeenMoved, LoadDirectly, CratesNeeded, Positionable, Dropped)
    -- Inherit everything from BASE class.
    local self=BASE:Inherit(self, BASE:New()) -- #CTLD
    self:T({ID, Name, Templates, Sorte, HasBeenMoved, LoadDirectly, CratesNeeded, Positionable, Dropped})
    self.ID = ID or math.random(100000,1000000)
    self.Name = Name or "none" -- #string
    self.Templates = Templates or {} -- #table
    self.CargoType = Sorte or "type" -- #CTLD_CARGO.Enum
    self.HasBeenMoved = HasBeenMoved or false -- #booolean
    self.LoadDirectly = LoadDirectly or false -- #booolean
    self.CratesNeeded = CratesNeeded or 0 -- #number
    self.Positionable = Positionable or nil -- Wrapper.Positionable#POSITIONABLE
    self.HasBeenDropped = Dropped or false --#boolean
    return self
  end
  
  --- Query ID.
  -- @param #CTLD_CARGO self
  -- @return #number ID
  function CTLD_CARGO:GetID()
    return self.ID
  end
  
  --- Query Name.
  -- @param #CTLD_CARGO self
  -- @return #string Name
  function CTLD_CARGO:GetName()
    return self.Name
  end
  
  --- Query Templates.
  -- @param #CTLD_CARGO self
  -- @return #table Templates
  function CTLD_CARGO:GetTemplates()
    return self.Templates
  end
  
  --- Query has moved.
  -- @param #CTLD_CARGO self
  -- @return #boolean Has moved
  function CTLD_CARGO:HasMoved()
    return self.HasBeenMoved
  end
  
  --- Query was dropped.
  -- @param #CTLD_CARGO self
  -- @return #boolean Has been dropped.
  function CTLD_CARGO:WasDropped()
    return self.HasBeenDropped
  end
  
  --- Query directly loadable.
  -- @param #CTLD_CARGO self
  -- @return #boolean loadable
  function CTLD_CARGO:CanLoadDirectly()
    return self.LoadDirectly
  end
  
  --- Query number of crates or troopsize.
  -- @param #CTLD_CARGO self
  -- @return #number Crates or size of troops.
  function CTLD_CARGO:GetCratesNeeded()
    return self.CratesNeeded
  end
  
  --- Query type.
  -- @param #CTLD_CARGO self
  -- @return #CTLD_CARGO.Enum Type
  function CTLD_CARGO:GetType()
    return self.CargoType
  end
  
  --- Query type.
  -- @param #CTLD_CARGO self
  -- @return Wrapper.Positionable#POSITIONABLE Positionable
  function CTLD_CARGO:GetPositionable()
    return self.Positionable
  end
  
  --- Set HasMoved.
  -- @param #CTLD_CARGO self
  -- @param #boolean moved
  function CTLD_CARGO:SetHasMoved(moved)
    self.HasBeenMoved = moved or false
  end
  
   --- Query if cargo has been loaded.
  -- @param #CTLD_CARGO self
  -- @param #boolean loaded
  function CTLD_CARGO:Isloaded()
    if self.HasBeenMoved and not self.WasDropped() then
      return true
    else
     return false
    end 
  end
  --- Set WasDropped.
  -- @param #CTLD_CARGO self
  -- @param #boolean dropped
  function CTLD_CARGO:SetWasDropped(dropped)
    self.HasBeenDropped = dropped or false
  end

end

do
-------------------------------------------------------------------------
--- **CTLD** class, extends #Core.Base#BASE, #Core.Fsm#FSM
-- @type CTLD
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number coalition Coalition side number, e.g. `coalition.side.RED`.
-- @extends Core.Fsm#FSM

--- *Combat Troop & Logistics Deployment (CTLD): Everyone wants to be a POG, until there\'s POG stuff to be done.* (Mil Saying)
--
-- ===
--
-- ![Banner Image](OPS_CTLD.jpg)
--
-- # CTLD Concept
-- 
--  * MOOSE-based CTLD for Players.
--  * Object oriented refactoring of Ciribob\'s fantastic CTLD script.
--  * No need for extra MIST loading. 
--  * Additional events to tailor your mission.
--  * ANY late activated group can serve as cargo, either as troops or crates, which have to be build on-location.
-- 
-- ## 0. Prerequisites
-- 
-- You need to load an .ogg soundfile for the pilot\'s beacons into the mission, e.g. "beacon.ogg", use a once trigger, "sound to country" for that.
-- Create the late-activated troops, vehicles (no statics at this point!) that will make up your deployable forces.
-- 
-- ## 1. Basic Setup
-- 
-- ## 1.1 Create and start a CTLD instance
-- 
-- A basic setup example is the following:
--        
--        -- Instantiate and start a CTLD for the blue side, using helicopter groups named "Helicargo" and alias "Lufttransportbrigade I"
--        local my_ctld = CTLD:New(coalition.side.BLUE,{"Helicargo"},"Lufttransportbrigade I")
--        my_ctld:__Start(5)
--
-- ## 1.2 Add cargo types available
--        
-- Add *generic* cargo types that you need for your missions, here infantry units, vehicles and a FOB. These need to be late-activated Wrapper.Group#GROUP objects:
--        
--        -- add infantry unit called "Anti-Tank Small" using template "ATS", of type TROOP with size 3
--        -- infantry units will be loaded directly from LOAD zones into the heli (matching number of free seats needed)
--        my_ctld:AddTroopsCargo("Anti-Tank Small",{"ATS"},CTLD_CARGO.Enum.TROOPS,3)
--        
--        -- add infantry unit called "Anti-Tank" using templates "AA" and "AA"", of type TROOP with size 4
--        my_ctld:AddTroopsCargo("Anti-Air",{"AA","AA2"},CTLD_CARGO.Enum.TROOPS,4)
--        
--        -- add vehicle called "Humvee" using template "Humvee", of type VEHICLE, size 2, i.e. needs two crates to be build
--        -- vehicles and FOB will be spawned as crates in a LOAD zone first. Once transported to DROP zones, they can be build into the objects
--        my_ctld:AddCratesCargo("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,2)
--        
--        -- add infantry unit called "Forward Ops Base" using template "FOB", of type FOB, size 4, i.e. needs four crates to be build:
--        my_ctld:AddCratesCargo("Forward Ops Base",{"FOB"},CTLD_CARGO.Enum.FOB,4)
--        
-- ## 1.3 Add logistics zones
--  
--  Add zones for loading troops and crates and dropping, building crates
--  
--        -- Add a zone of type LOAD to our setup. Players can load troops and crates.
--        -- "Loadzone" is the name of the zone from the ME. Players can load, if they are inside of the zone.
--        -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
--        my_ctld:AddCTLDZone("Loadzone",CTLD.CargoZoneType.LOAD,SMOKECOLOR.Blue,true,true)
--        
--        -- Add a zone of type DROP. Players can drop crates here.
--        -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
--        -- NOTE: Troops can be unloaded anywhere, also when hovering in parameters.
--        my_ctld:AddCTLDZone("Dropzone",CTLD.CargoZoneType.DROP,SMOKECOLOR.Red,true,true)
--        
--        -- Add two zones of type MOVE. Dropped troops and vehicles will move to the nearest one. See options.
--        -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
--        my_ctld:AddCTLDZone("Movezone",CTLD.CargoZoneType.MOVE,SMOKECOLOR.Orange,false,false)
--        
--        my_ctld:AddCTLDZone("Movezone2",CTLD.CargoZoneType.MOVE,SMOKECOLOR.White,true,true)
--        
-- 
-- ## 2. Options
-- 
-- The following options are available (with their defaults). Only set the ones you want changed:
--
--          my_ctld.useprefix = true -- Adjust *before* starting CTLD. If set to false, *all* choppers of the coalition side will be enabled for CTLD.
--          my_ctld.CrateDistance = 30 -- List and Load crates in this radius only.
--          my_ctld.maximumHoverHeight = 15 -- Hover max this high to load.
--          my_ctld.minimumHoverHeight = 4 -- Hover min this low to load.
--          my_ctld.forcehoverload = true -- Crates (not: troops) can only be loaded while hovering.
--          my_ctld.hoverautoloading = true -- Crates in CrateDistance in a LOAD zone will be loaded automatically if space allows.
--          my_ctld.smokedistance = 2000 -- Smoke or flares can be request for zones this far away (in meters).
--          my_ctld.movetroopstowpzone = true -- Troops and vehicles will move to the nearest MOVE zone...
--          my_ctld.movetroopsdistance = 5000 -- .. but only if this far away (in meters)
--          my_ctld.smokedistance = 2000 -- Only smoke or flare zones if requesting player unit is this far away (in meters)
-- 
-- ## 2.1 User functions
-- 
-- ### 2.1.1 Adjust or add chopper unit-type capabilities
--  
-- Use this function to adjust what a heli type can or cannot do:
-- 
--        -- E.g. update unit capabilities for testing. Please stay realistic in your mission design.
--        -- Make a Gazelle into a heavy truck, this type can load both crates and troops and eight of each type:
--        my_ctld:UnitCapabilities("SA342L", true, true, 8, 8)
--        
--        Default unit type capabilities are:
--    
--        ["SA342Mistral"] = {type="SA342Mistral", crates=false, troops=true, cratelimit = 0, trooplimit = 4},
--        ["SA342L"] = {type="SA342L", crates=false, troops=true, cratelimit = 0, trooplimit = 2},
--        ["SA342M"] = {type="SA342M", crates=false, troops=true, cratelimit = 0, trooplimit = 4},
--        ["SA342Minigun"] = {type="SA342Minigun", crates=false, troops=true, cratelimit = 0, trooplimit = 2},
--        ["UH-1H"] = {type="UH-1H", crates=true, troops=true, cratelimit = 1, trooplimit = 8},
--        ["Mi-8MTV2"] = {type="Mi-8MTV2", crates=true, troops=true, cratelimit = 2, trooplimit = 12},
--        ["Ka-50"] = {type="Ka-50", crates=false, troops=false, cratelimit = 0, trooplimit = 0},
--        ["Mi-24P"] = {type="Mi-24P", crates=true, troops=true, cratelimit = 1, trooplimit = 8},
--        ["Mi-24V"] = {type="Mi-24V", crates=true, troops=true, cratelimit = 1, trooplimit = 8},
--
--        
-- ### 2.1.2 Activate and deactivate zones
-- 
-- Activate a zone:
-- 
--        -- Activate zone called Name of type #CTLD.CargoZoneType ZoneType:
--        my_ctld:ActivateZone(Name,ZoneType)
-- 
-- Deactivate a zone:
-- 
--        -- Deactivate zone called Name of type #CTLD.CargoZoneType ZoneType:
--        my_ctld:DeactivateZone(Name,ZoneType)
-- 
-- ## 3. Events
--
--  The class comes with a number of FSM-based events that missions designers can use to shape their mission.
--  These are:
-- 
-- ## 3.1 OnAfterTroopsPickedUp
-- 
--   This function is called when a player has loaded Troops:
--
--        function CTLD:OnAfterTroopsPickedUp(From, Event, To, Group, Unit, Cargo)
--          ... your code here ...
--        end
-- 
-- ## 3.2 OnAfterCratesPickedUp
-- 
--    This function is called when a player has picked up crates:
--
--        function CTLD:OnAfterCratesPickedUp(From, Event, To, Group, Unit, Cargo)
--          ... your code here ...
--        end
--  
-- ## 3.3 OnAfterTroopsTroopsDeployed
--  
--    This function is called when a player has deployed troops into the field:
--
--        function CTLD:OnAfterTroopsDeployed(From, Event, To, Group, Unit, Troops)
--          ... your code here ...
--        end
--  
-- ## 3.4 OnAfterTroopsCratesDropped
--  
--    This function is called when a player has deployed crates to a DROP zone:
--
--        function CTLD:OnAfterCratesDropped(From, Event, To, Group, Unit, Cargotable)
--          ... your code here ...
--        end
--  
-- ## 3.5 OnAfterTroopsCratesBuild
--  
--    This function is called when a player has build a vehicle or FOB:
--
--        function CTLD:OnAfterCratesBuild(From, Event, To, Group, Unit, Vehicle)
--          ... your code here ...
--        end
--  
-- ## 4. F10 Menu structure
-- 
-- CTLD management menu is under the F10 top menu and called "CTLD"
-- 
-- ## 4.1 Manage Crates
-- 
-- Use this entry to get, load, list nearby, drop, and build crates. Also @see options.
-- 
-- ## 4.2 Manage Troops
-- 
-- Use this entry to load and drop troops.
-- 
-- ## 4.3 List boarded cargo
-- 
-- Lists what you have loaded. Shows load capabilities for number of crates and number of seats for troops.
-- 
-- ## 4.4 Smoke & Flare zones nearby
-- 
-- Does what it says.
-- 
-- ## 4.5 List active zone beacons
-- 
-- Lists active radio beacons for all zones, where zones are both active and have a beacon. @see `CTLD:AddCTLDZone()`
-- 
-- ## 4.6 Show hover parameters
-- 
-- Lists hover parameters and indicates if these are curently fulfilled. Also @see options on hover heights.
--  
-- @field #CTLD
CTLD = {
  ClassName       = "CTLD",
  verbose         =     2,
  lid             =   "",
  coalition       = 1,
  coalitiontxt    = "blue",
  PilotGroups = {}, -- #GROUP_SET of heli pilots
  CtldUnits = {},   -- Table of helicopter #GROUPs
  FreeVHFFrequencies = {}, -- Table of VHF
  FreeUHFFrequencies = {}, -- Table of UHF
  FreeFMFrequencies = {}, -- Table of FM
  CargoCounter = 0,
  dropOffZones = {},
  wpZones = {},
  Cargo_Troops = {}, -- generic troops objects
  Cargo_Crates = {}, -- generic crate objects
  Loaded_Cargo = {}, -- cargo aboard units
  Spawned_Crates = {}, -- Holds objects for crates spawned generally
  Spawned_Cargo = {}, -- Binds together spawned_crates and their CTLD_CARGO objects
  CrateDistance = 30, -- list crates in this radius
  debug = false,
  wpZones = {},
  pickupZones  = {},
  dropOffZones = {},
}

------------------------------
-- DONE: Zone Checks
-- DONE: TEST Hover load and unload
-- DONE: Crate unload
-- DONE: Hover (auto-)load
-- TODO: (More) Housekeeping
-- DONE: Troops running to WP Zone
-- DONE: Zone Radio Beacons
-- DONE: Stats Running
------------------------------

--- Radio Beacons
-- @type CTLD.ZoneBeacon
-- @field #string name -- Name of zone for the coordinate
-- @field #number frequency -- in mHz
-- @field #number modulation -- i.e.radio.modulation.FM or radio.modulation.AM

--- Zone Info.
-- @type CTLD.CargoZone
-- @field #string name Name of Zone.
-- @field #string color Smoke color for zone, e.g. SMOKECOLOR.Red.
-- @field #boolean active Active or not.
-- @field #string type Type of zone, i.e. load,drop,move
-- @field #boolean hasbeacon Create and run radio beacons if active.
-- @field #table fmbeacon Beacon info as #CTLD.ZoneBeacon
-- @field #table uhfbeacon Beacon info as #CTLD.ZoneBeacon
-- @field #table vhfbeacon Beacon info as #CTLD.ZoneBeacon

--- Zone Type Info.
-- @type CTLD.
CTLD.CargoZoneType = {
  LOAD = "load",
  DROP = "drop",
  MOVE = "move",
}

--- Buildable table info.
-- @type CTLD.Buildable
-- @field #string Name Name of the object.
-- @field #number Required Required crates.
-- @field #number Found Found crates.
-- @field #table Template Template names for this build.
-- @field #boolean CanBuild Is buildable or not.
-- @field #CTLD_CARGO.Enum Type Type enumerator (for moves).

--- Unit capabilities.
-- @type CTLD.UnitCapabilities
-- @field #string type Unit type.
-- @field #boolean crates Can transport crate.
-- @field #boolean troops Can transport troops.
-- @field #number cratelimit Number of crates transportable.
-- @field #number trooplimit Number of troop units transportable.
CTLD.UnitTypes = {
    ["SA342Mistral"] = {type="SA342Mistral", crates=false, troops=true, cratelimit = 0, trooplimit = 4},
    ["SA342L"] = {type="SA342L", crates=false, troops=true, cratelimit = 0, trooplimit = 2},
    ["SA342M"] = {type="SA342M", crates=false, troops=true, cratelimit = 0, trooplimit = 4},
    ["SA342Minigun"] = {type="SA342Minigun", crates=false, troops=true, cratelimit = 0, trooplimit = 2},
    ["UH-1H"] = {type="UH-1H", crates=true, troops=true, cratelimit = 1, trooplimit = 8},
    ["Mi-8MTV2"] = {type="Mi-8MTV2", crates=true, troops=true, cratelimit = 2, trooplimit = 12},
    ["Ka-50"] = {type="Ka-50", crates=false, troops=false, cratelimit = 0, trooplimit = 0},
    ["Mi-24P"] = {type="Mi-24P", crates=true, troops=true, cratelimit = 2, trooplimit = 8},
    ["Mi-24V"] = {type="Mi-24V", crates=true, troops=true, cratelimit = 2, trooplimit = 8},
}

--- Updated and sorted known NDB beacons (in kHz!) from the available maps
-- @field #CTLD.SkipFrequencies 
CTLD.SkipFrequencies = {
  214,274,291.5,295,297.5,
  300.5,304,307,309.5,311,312,312.5,316,
  320,324,328,329,330,336,337,
  342,343,348,351,352,353,358,
  363,365,368,372.5,374,
  380,381,384,389,395,396,
  414,420,430,432,435,440,450,455,462,470,485,
  507,515,520,525,528,540,550,560,570,577,580,602,625,641,662,670,680,682,690,
  705,720,722,730,735,740,745,750,770,795,
  822,830,862,866,
  905,907,920,935,942,950,995,
  1000,1025,1030,1050,1065,1116,1175,1182,1210
  }
  
--- CTLD class version.
-- @field #string version
CTLD.version="0.1.1b1"

--- Instantiate a new CTLD.
-- @param #CTLD self
-- @param #string Coalition Coalition of this CTLD. I.e. coalition.side.BLUE or coalition.side.RED or coalition.side.NEUTRAL
-- @param #table Prefixes Table of pilot prefixes.
-- @param #string Alias Alias of this CTLD for logging.
-- @return #CTLD self
function CTLD:New(Coalition, Prefixes, Alias)
  -- TODO: CTLD Marker
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #CTLD
  
  BASE:T({Coalition, Prefixes, Alias})
  
  --set Coalition
  if Coalition and type(Coalition)=="string" then
    if Coalition=="blue" then
      self.coalition=coalition.side.BLUE
      self.coalitiontxt = Coalition
    elseif Coalition=="red" then
      self.coalition=coalition.side.RED
      self.coalitiontxt = Coalition
    elseif Coalition=="neutral" then
      self.coalition=coalition.side.NEUTRAL
      self.coalitiontxt = Coalition
    else
      self:E("ERROR: Unknown coalition in CTLD!")
    end
  else
    self.coalition = Coalition
    self.coalitiontxt = string.lower(UTILS.GetCoalitionName(self.coalition))
  end
  
  -- Set alias.
  if Alias then
    self.alias=tostring(Alias)
  else
    self.alias="UNHCR"  
    if self.coalition then
      if self.coalition==coalition.side.RED then
        self.alias="Red CTLD"
      elseif self.coalition==coalition.side.BLUE then
        self.alias="Blue CTLD"
      end
    end
  end
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- CTLD status update.
  self:AddTransition("*",             "TroopsPickedUp",      "*")           -- CTLD pickup  event. 
  self:AddTransition("*",             "CratesPickedUp",      "*")           -- CTLD pickup  event.  
  self:AddTransition("*",             "TroopsDeployed",      "*")           -- CTLD deploy  event.  
  self:AddTransition("*",             "CratesDropped",       "*")           -- CTLD deploy  event.  
  self:AddTransition("*",             "CratesBuild",         "*")           -- CTLD build  event.   
  self:AddTransition("*",             "Stop",               "Stopped")     -- Stop FSM.
  
  -- tables
  self.PilotGroups ={}
  self.CtldUnits = {}
  
  -- Beacons
  self.FreeVHFFrequencies = {}
  self.FreeUHFFrequencies = {}
  self.FreeFMFrequencies = {}
  self.UsedVHFFrequencies = {}
  self.UsedUHFFrequencies = {}
  self.UsedFMFrequencies = {}
  --self.jtacGeneratedLaserCodes = {}
  
  -- radio beacons
  self.RadioSound = "beacon.ogg"
  
  -- zones stuff
  self.pickupZones  = {}
  self.dropOffZones = {}
  self.wpZones = {}
  
  -- Cargo
  self.Cargo_Crates = {}
  self.Cargo_Troops = {}
  self.Loaded_Cargo = {}
  self.Spawned_Crates = {}
  self.Spawned_Cargo = {}
  self.MenusDone = {}
  self.DroppedTroops = {}
  self.DroppedCrates = {}
  self.CargoCounter = 0
  self.CrateCounter = 0
  self.TroopCounter = 0
  
  -- setup
  self.CrateDistance = 30 -- list/load crates in this radius
  self.prefixes = Prefixes or {"cargoheli"}
  self.useprefix = true
  
  self.maximumHoverHeight = 15
  self.minimumHoverHeight = 4
  self.forcehoverload = true
  self.hoverautoloading = true
  
  self.smokedistance = 2000
  self.movetroopstowpzone = true
  self.movetroopsdistance = 5000
  
  for i=1,100 do
    math.random()
  end
  
  self:_GenerateVHFrequencies()
  self:_GenerateUHFrequencies()
  self:_GenerateFMFrequencies()
  --self:_GenerateLaserCodes() -- curr unused
  
    ------------------------
  --- Pseudo Functions ---
  ------------------------
  
    --- Triggers the FSM event "Start". Starts the CTLD. Initializes parameters and starts event handlers.
  -- @function [parent=#CTLD] Start
  -- @param #CTLD self

  --- Triggers the FSM event "Start" after a delay. Starts the CTLD. Initializes parameters and starts event handlers.
  -- @function [parent=#CTLD] __Start
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the CTLD and all its event handlers.
  -- @param #CTLD self

  --- Triggers the FSM event "Stop" after a delay. Stops the CTLD and all its event handlers.
  -- @function [parent=#CTLD] __Stop
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#CTLD] Status
  -- @param #CTLD self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#CTLD] __Status
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.
  
  --- FSM Function OnAfterTroopsPickedUp.
  -- @function [parent=#CTLD] OnAfterTroopsPickedUp
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate.
  -- @return #CTLD self
  
  --- FSM Function OnAfterCratesPickedUp.
  -- @function [parent=#CTLD] OnAfterCratesPickedUp
  -- @param #CTLD self
  -- @param #string From State .
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate.
  -- @return #CTLD self
  
   --- FSM Function OnAfterTroopsDeployed.
  -- @function [parent=#CTLD] OnAfterTroopsDeployed
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops Troops #GROUP Object.
  -- @return #CTLD self
  
  --- FSM Function OnAfterCratesDropped.
  -- @function [parent=#CTLD] OnAfterCratesDropped
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects dropped.
  -- @return #CTLD self
  
   --- FSM Function OnAfterCratesBuild.
  -- @function [parent=#CTLD] OnAfterCratesBuild
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB build.
  -- @return #CTLD self
  
  return self
end

------------------------------------------------------------------- 
-- Helper and User Functions
------------------------------------------------------------------- 

--- Function to generate valid UHF Frequencies
-- @param #CTLD self
function CTLD:_GenerateUHFrequencies()
  self:T(self.lid .. " _GenerateUHFrequencies")
    self.FreeUHFFrequencies = {}
    local _start = 220000000

    while _start < 399000000 do
        table.insert(self.FreeUHFFrequencies, _start)
        _start = _start + 500000
    end

    return self
end

--- Function to generate valid FM Frequencies
-- @param #CTLD sel
function CTLD:_GenerateFMFrequencies()
  self:T(self.lid .. " _GenerateFMrequencies")
    self.FreeFMFrequencies = {}
    local _start = 220000000

    while _start < 399000000 do

        _start = _start + 500000
    end

    for _first = 3, 7 do
        for _second = 0, 5 do
            for _third = 0, 9 do
                local _frequency = ((100 * _first) + (10 * _second) + _third) * 100000 --extra 0 because we didnt bother with 4th digit
                table.insert(self.FreeFMFrequencies, _frequency)
            end
        end
    end

    return self
end

--- Populate table with available VHF beacon frequencies.
-- @param #CTLD self
function CTLD:_GenerateVHFrequencies()
  self:T(self.lid .. " _GenerateVHFrequencies")
  local _skipFrequencies = self.SkipFrequencies
      
   self.FreeVHFFrequencies = {}
   self.UsedVHFFrequencies = {}
    
    -- first range
  local _start = 200000
  while _start < 400000 do
  
      -- skip existing NDB frequencies#
      local _found = false
      for _, value in pairs(_skipFrequencies) do
          if value * 1000 == _start then
              _found = true
              break
          end
      end
      if _found == false then
          table.insert(self.FreeVHFFrequencies, _start)
      end
       _start = _start + 10000
  end
 
   -- second range
  _start = 400000
  while _start < 850000 do
       -- skip existing NDB frequencies
      local _found = false
      for _, value in pairs(_skipFrequencies) do
          if value * 1000 == _start then
              _found = true
              break
          end
      end
      if _found == false then
          table.insert(self.FreeVHFFrequencies, _start)
      end
      _start = _start + 10000
  end
  
  -- third range
  _start = 850000
  while _start <= 999000 do -- adjusted for Gazelle
      -- skip existing NDB frequencies
      local _found = false
      for _, value in pairs(_skipFrequencies) do
          if value * 1000 == _start then
              _found = true
              break
          end
      end
      if _found == false then
          table.insert(self.FreeVHFFrequencies, _start)
      end
       _start = _start + 50000
  end

  return self
end

--- Function to generate valid laser codes.
-- @param #CTLD self
function CTLD:_GenerateLaserCodes()
  self:T(self.lid .. " _GenerateLaserCodes")
    self.jtacGeneratedLaserCodes = {}
    -- generate list of laser codes
    local _code = 1111
    local _count = 1
    while _code < 1777 and _count < 30 do
        while true do
           _code = _code + 1
            if not self:_ContainsDigit(_code, 8)
                    and not self:_ContainsDigit(_code, 9)
                    and not self:_ContainsDigit(_code, 0) then
                table.insert(self.jtacGeneratedLaserCodes, _code)
                break
            end
        end
        _count = _count + 1
    end
end

--- Helper function to generate laser codes.
-- @param #CTLD self
-- @param #number _number
-- @param #number _numberToFind
function CTLD:_ContainsDigit(_number, _numberToFind)
  self:T(self.lid .. " _ContainsDigit")
    local _thisNumber = _number
    local _thisDigit = 0
    while _thisNumber ~= 0 do
        _thisDigit = _thisNumber % 10
        _thisNumber = math.floor(_thisNumber / 10)
        if _thisDigit == _numberToFind then
            return true
        end
    end
    return false
end

--- Event handler function
-- @param #CTLD self
-- @param Core.Event#EVENTDATA EventData
function CTLD:_EventHandler(EventData)
  -- TODO: events dead and playerleaveunit - nil table entries
  self:T(string.format("%s Event = %d",self.lid, EventData.id))
  local event = EventData -- Core.Event#EVENTDATA
  if event.id == EVENTS.PlayerEnterAircraft or event.id == EVENTS.PlayerEnterUnit then
    local _coalition = event.IniCoalition
    if _coalition ~= self.coalition then
        return --ignore!
    end
    -- check is Helicopter
    local _unit = event.IniUnit
    local _group = event.IniGroup
    if _unit:IsHelicopter() or _group:IsHelicopter() then
      self:_RefreshF10Menus()
    end    
    return
  elseif event.id == EVENTS.PlayerLeaveUnit then
    -- remove from pilot table
    local unitname = event.IniUnitName or "none"
    self.CtldUnits[unitname] = nil
  end
  return self
end

--- Function to load troops into a heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD_CARGO Cargotype
function CTLD:_LoadTroops(Group, Unit, Cargotype)
  self:T(self.lid .. " _LoadTroops")
  -- landed or hovering over load zone?
  local grounded = not self:IsUnitInAir(Unit)
  local hoverload = self:CanHoverLoad(Unit)
  -- check if we are in LOAD zone
  local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
  if not inzone then
    local m = MESSAGE:New("You are not close enough to a logistics zone!",15,"CTLD"):ToGroup(Group)
    if not self.debug then return self end
  elseif not grounded and not hoverload then
    local m = MESSAGE:New("You need to land or hover in position to load!",15,"CTLD"):ToGroup(Group)
    if not self.debug then return self end
  end
  -- load troops into heli
  local group = Group -- Wrapper.Group#GROUP
  local unit = Unit -- Wrapper.Unit#UNIT
  local unitname = unit:GetName()
  local cargotype = Cargotype -- #CTLD_CARGO
  local cratename = cargotype:GetName() -- #string
  self:T(self.lid .. string.format("Troops %s requested", cratename))
  -- see if this heli can load troops
  local unittype = unit:GetTypeName()
  local capabilities = self.UnitTypes[unittype] -- #CTLD.UnitCapabilities
  local cantroops = capabilities.troops -- #boolean
  local trooplimit = capabilities.trooplimit -- #number
  local troopsize = cargotype:GetCratesNeeded() -- #number
  -- have we loaded stuff already?
  local numberonboard = 0
  local loaded = {}
  if self.Loaded_Cargo[unitname] then
    loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
    numberonboard = loaded.Troopsloaded or 0
  else
    loaded = {} -- #CTLD.LoadedCargo
    loaded.Troopsloaded = 0
    loaded.Cratesloaded = 0
    loaded.Cargo = {}
  end
  if troopsize + numberonboard > trooplimit then
    local m = MESSAGE:New("Sorry, we\'re crammed already!",10,"CTLD",true):ToGroup(group)
    return
  else
    loaded.Troopsloaded = loaded.Troopsloaded + troopsize
    table.insert(loaded.Cargo,Cargotype)
    self.Loaded_Cargo[unitname] = loaded
    local m = MESSAGE:New("Troops boarded!",10,"CTLD",true):ToGroup(group)
    self:__TroopsPickedUp(1,Group, Unit, Cargotype)
  end
  return self
end

--- Function to spawn crates in front of the heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD_CARGO Cargo
-- @param #number number Number of crates to generate (for dropping)
-- @param #boolean drop If true we\'re dropping from heli rather than loading.
function CTLD:_GetCrates(Group, Unit, Cargo, number, drop)
  self:T(self.lid .. " _GetCrates")
  local cgoname = Cargo:GetName()
  self:T({cgoname, number, drop})
    -- check if we are in LOAD zone
  local inzone = true
  
  if drop then 
    local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.DROP)
  else
    local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
  end
  
  if not inzone then
    local m = MESSAGE:New("You are not close enough to a logistics zone!",15,"CTLD"):ToGroup(Group)
    if not self.debug then return self end
  end
  
  -- avoid crate spam
  local capabilities = self.UnitTypes[Unit:GetTypeName()] -- #CTLD.UnitCapabilities
  local canloadcratesno = capabilities.cratelimit
  local loaddist = self.CrateDistance or 30
  local nearcrates, numbernearby = self:_FindCratesNearby(Group,Unit,loaddist)
  if numbernearby >= canloadcratesno and not drop then
    local m = MESSAGE:New("There are enough crates nearby already! Take care of those first!",15,"CTLD"):ToGroup(Group)
    return self
  end
  -- spawn crates in front of helicopter
  local cargotype = Cargo -- #CTLD_CARGO
  local number = number or cargotype:GetCratesNeeded() --#number
  local cratesneeded = cargotype:GetCratesNeeded() --#number
  local cratename = cargotype:GetName()
  self:T(self.lid .. string.format("Crate %s requested", cratename))
  local cratetemplate = "Container"-- #string
  -- get position and heading of heli
  local position = Unit:GetCoordinate()
  local heading = Unit:GetHeading() + 1
  local height = Unit:GetHeight()
  local droppedcargo = {}
  -- loop crates needed
  for i=1,number do
    local cratealias = string.format("%s-%d", cratetemplate, math.random(1,100000))
    local cratedistance = i*4 + 6
    local rheading = math.floor(math.random(90,270) * heading + 1 / 360)
    local rheading = rheading + 180 -- mirror
    if rheading > 360 then rheading = rheading - 360 end -- catch > 360
    local cratecoord = position:Translate(cratedistance,rheading)
    local cratevec2 = cratecoord:GetVec2()
    self.CrateCounter = self.CrateCounter + 1   
    self.Spawned_Crates[self.CrateCounter] = SPAWNSTATIC:NewFromType("container_cargo","Cargos",country.id.GERMANY)
      :InitCoordinate(cratecoord)
      :Spawn(270,cratealias)

    local templ = cargotype:GetTemplates()
    local sorte = cargotype:GetType()
    self.CargoCounter = self.CargoCounter +1
    local realcargo = nil
    if drop then
      realcargo = CTLD_CARGO:New(self.CargoCounter,cratename,templ,sorte,true,false,cratesneeded,self.Spawned_Crates[self.CrateCounter],true)
      table.insert(droppedcargo,realcargo)
    else
      realcargo = CTLD_CARGO:New(self.CargoCounter,cratename,templ,sorte,false,false,cratesneeded,self.Spawned_Crates[self.CrateCounter])
    end
    table.insert(self.Spawned_Cargo, realcargo)
  end
    local text = string.format("Crates for %s have been positioned near you!",cratename)
    if drop then
      text = string.format("Crates for %s have been dropped!",cratename)
      self:__CratesDropped(1, Group, Unit, droppedcargo)
    end 
    local m = MESSAGE:New(text,15,"CTLD",true):ToGroup(Group)
    return self
end

--- Function to find and list nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_ListCratesNearby( _group, _unit)
  self:T(self.lid .. " _ListCratesNearby")
  local finddist = self.CrateDistance or 30
  local crates,number = self:_FindCratesNearby(_group,_unit, finddist) -- #table
  if number > 0 then
    local text = REPORT:New("Crates Found Nearby:")
    text:Add("------------------------------------------------------------")
    for _,_entry in pairs (crates) do
      local entry = _entry -- #CTLD_CARGO
      local name = entry:GetName() --#string
      -- TODO Meaningful sorting/aggregation
      local dropped = entry:WasDropped()
      if dropped then
        text:Add(string.format("Dropped crate for %s",name))
      else
        text:Add(string.format("Crate for %s",name))
      end
    end
    if text:GetCount() == 1 then
    text:Add("--------- N O N E ------------")
    end
    text:Add("------------------------------------------------------------")
    local m = MESSAGE:New(text:Text(),15,"CTLD",true):ToGroup(_group)
  else
    local m = MESSAGE:New(string.format("No (loadable) crates within %d meters!",finddist),15,"CTLD",true):ToGroup(_group)
  end
  return self
end

--- Return distance in meters between two coordinates.
-- @param #CTLD self
-- @param Core.Point#COORDINATE _point1 Coordinate one
-- @param Core.Point#COORDINATE _point2 Coordinate two
-- @return #number Distance in meters
function CTLD:_GetDistance(_point1, _point2)
  self:T(self.lid .. " _GetDistance")
  if _point1 and _point2 then
    local distance = _point1:DistanceFromPointVec2(_point2)
   return distance
  else
    return -1
  end
end

--- Function to find and return nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP _group Group
-- @param Wrapper.Unit#UNIT _unit Unit
-- @param #number _dist Distance
-- @return #table Table of crates
-- @return #number Number Number of crates found
function CTLD:_FindCratesNearby( _group, _unit, _dist)
  self:T(self.lid .. " _FindCratesNearby")
  local finddist = _dist
  local location = _group:GetCoordinate()
  local existingcrates = self.Spawned_Cargo -- #table
  -- cycle
  local index = 0
  local found = {}
  for _,_cargoobject in pairs (existingcrates) do
    local cargo = _cargoobject -- #CTLD_CARGO
    local static = cargo:GetPositionable() -- Wrapper.Static#STATIC -- crates
    local staticid = cargo:GetID()
    if static and static:IsAlive() then
      local staticpos = static:GetCoordinate()
      local distance = self:_GetDistance(location,staticpos)
      if distance <= finddist and static then
        index = index + 1
        table.insert(found, staticid, cargo)
      end
    end
  end
  self:T(string.format("Found crates = %d",index))
  -- table.sort(found)
  --self:T({found})
  return found, index
end

--- Function to get and load nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_LoadCratesNearby(Group, Unit)
  self:T(self.lid .. " _LoadCratesNearby")
    -- load crates into heli
  local group = Group -- Wrapper.Group#GROUP
  local unit = Unit -- Wrapper.Unit#UNIT
  local unitname = unit:GetName()
  -- see if this heli can load crates
  local unittype = unit:GetTypeName()
  local capabilities = self.UnitTypes[unittype] -- #CTLD.UnitCapabilities
  local cancrates = capabilities.crates -- #boolean
  local cratelimit = capabilities.cratelimit -- #number
  local grounded = not self:IsUnitInAir(Unit)
  local canhoverload = self:CanHoverLoad(Unit)
  --- cases -------------------------------
  -- Chopper can\'t do crates - bark & return
  -- Chopper can do crates -
  -- --> hover if forcedhover or bark and return
  -- --> hover or land if not forcedhover
  -----------------------------------------
  if not cancrates then
    local m = MESSAGE:New("Sorry this chopper cannot carry crates!",10,"CTLD"):ToGroup(Group)
  elseif self.forcehoverload and not canhoverload then
    local m = MESSAGE:New("Hover over the crates to pick them up!",10,"CTLD"):ToGroup(Group)
  elseif not grounded and not canhoverload then
    local m = MESSAGE:New("Land or hover over the crates to pick them up!",10,"CTLD"):ToGroup(Group)
  else
     -- have we loaded stuff already?
    local numberonboard = 0
    local loaded = {}
    if self.Loaded_Cargo[unitname] then
      loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
      numberonboard = loaded.Cratesloaded or 0
    else
      loaded = {} -- #CTLD.LoadedCargo
      loaded.Troopsloaded = 0
      loaded.Cratesloaded = 0
      loaded.Cargo = {}
    end
    -- get nearby crates
    local finddist = self.CrateDistance or 30
    local nearcrates,number = self:_FindCratesNearby(Group,Unit,finddist) -- #table
    if number == 0 or numberonboard == cratelimit then
      local m = MESSAGE:New("Sorry no loadable crates nearby or fully loaded!",10,"CTLD"):ToGroup(Group)
      return -- exit
    else
      -- go through crates and load
      local capacity = cratelimit - numberonboard
      local crateidsloaded = {}
      local loops = 0
      while loaded.Cratesloaded < cratelimit and loops < number do
      --for _ind,_crate in pairs (nearcrates) do
        loops = loops + 1
        local crateind = 0
        -- get crate with largest index
        for _ind,_crate in pairs (nearcrates) do
          if not _crate:HasMoved() and not _crate:WasDropped() and _crate:GetID() > crateind then
            --crate = _crate
            crateind = _crate:GetID()
          end
        end
        -- load one if we found one
        if crateind > 0 then
          local crate = nearcrates[crateind] -- #CTLD_CARGO
          loaded.Cratesloaded = loaded.Cratesloaded + 1
          crate:SetHasMoved(true)
          table.insert(loaded.Cargo, crate)
          table.insert(crateidsloaded,crate:GetID())
          -- destroy crate
          crate:GetPositionable():Destroy()
          crate.Positionable = nil
          local m = MESSAGE:New(string.format("Crate ID %d for %s loaded!",crate:GetID(),crate:GetName()),10,"CTLD"):ToGroup(Group)
          self:__CratesPickedUp(1, Group, Unit, crate)
        end
        --if loaded.Cratesloaded == cratelimit then break end
      end
      self.Loaded_Cargo[unitname] = loaded
      -- clean up real world crates
      local existingcrates = self.Spawned_Cargo -- #table
      local newexcrates = {}
      for _,_crate in pairs(existingcrates) do
        local excrate = _crate -- #CTLD_CARGO
        local ID = excrate:GetID()
        for _,_ID in pairs(crateidsloaded) do
          if ID ~= _ID then
            table.insert(newexcrates,_crate)
          end
        end
      end
      self.Spawned_Cargo = nil
      self.Spawned_Cargo = newexcrates
    end
  end
  return self
end

--- Function to list loaded cargo.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_ListCargo(Group, Unit)
  self:T(self.lid .. " _ListCargo")
  local unitname = Unit:GetName()
  local unittype = Unit:GetTypeName()
  local capabilities = self.UnitTypes[unittype] -- #CTLD.UnitCapabilities
  local trooplimit = capabilities.trooplimit -- #boolean
  local cratelimit = capabilities.cratelimit -- #numbe
  local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
  if self.Loaded_Cargo[unitname] then
    local no_troops = loadedcargo.Troopsloaded or 0
    local no_crates = loadedcargo.Cratesloaded or 0
    local cargotable = loadedcargo.Cargo or {} -- #table
    local report = REPORT:New("Transport Checkout Sheet")
    report:Add("------------------------------------------------------------")
    report:Add(string.format("Troops: %d(%d), Crates: %d(%d)",no_troops,trooplimit,no_crates,cratelimit))
    report:Add("------------------------------------------------------------")
    report:Add("-- TROOPS --")
    for _,_cargo in pairs(cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if type == CTLD_CARGO.Enum.TROOPS and not cargo:WasDropped() then
        report:Add(string.format("Troop: %s size %d",cargo:GetName(),cargo:GetCratesNeeded()))
      end
    end
    if report:GetCount() == 4 then
      report:Add("--------- N O N E ------------")
    end
    report:Add("------------------------------------------------------------")
    report:Add("-- CRATES --")
    local cratecount = 0
    for _,_cargo in pairs(cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if type ~= CTLD_CARGO.Enum.TROOPS then
        report:Add(string.format("Crate: %s size 1",cargo:GetName()))
        cratecount = cratecount + 1
      end
    end
    if cratecount == 0 then
      report:Add("--------- N O N E ------------")
    end
    report:Add("------------------------------------------------------------")
    local text = report:Text()
    local m = MESSAGE:New(text,30,"CTLD",true):ToGroup(Group)
  else
    local m = MESSAGE:New(string.format("Nothing loaded!\nTroop limit: %d | Crate limit %d",trooplimit,cratelimit),10,"CTLD"):ToGroup(Group)
  end
  return self
end

--- Function to unload troops from heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
function CTLD:_UnloadTroops(Group, Unit)
  self:T(self.lid .. " _UnloadTroops")
  -- check if we are in LOAD zone
  local droppingatbase = false
  local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
  if inzone then
    droppingatbase = true
  end
  -- check for hover unload
  local hoverunload = self:IsCorrectHover(Unit) --if true we\'re hovering in parameters
  -- check if we\'re landed
  local grounded = not self:IsUnitInAir(Unit)
  -- Get what we have loaded
  local unitname = Unit:GetName()
  if self.Loaded_Cargo[unitname] and (grounded or hoverunload) then
    if not droppingatbase or self.debug then
      local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
      -- looking for troops
      local cargotable = loadedcargo.Cargo
      for _,_cargo in pairs (cargotable) do
        local cargo = _cargo -- #CTLD_CARGO
        local type = cargo:GetType() -- #CTLD_CARGO.Enum
        if type == CTLD_CARGO.Enum.TROOPS and not cargo:WasDropped() then
          -- unload troops
          local name = cargo:GetName() or "none"
          local temptable = cargo:GetTemplates() or {}
          local position = Group:GetCoordinate()
          local zone = ZONE_GROUP:New(string.format("Unload zone-%s",unitname),Group,100)
          local randomcoord = zone:GetRandomCoordinate(10,30):GetVec2()
          for _,_template in pairs(temptable) do
            self.TroopCounter = self.TroopCounter + 1
            local alias = string.format("%s-%d", _template, math.random(1,100000))
            self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
              :InitRandomizeUnits(true,20,2)
              :InitDelayOff()
              :SpawnFromVec2(randomcoord)
            if self.movetroopstowpzone then
              self:_MoveGroupToZone(self.DroppedTroops[self.TroopCounter])
            end
          end -- template loop
          cargo:SetWasDropped(true)
          local m = MESSAGE:New(string.format("Dropped Troops %s into action!",name),10,"CTLD"):ToGroup(Group)
          self:__TroopsDeployed(1, Group, Unit, name, self.DroppedTroops[self.TroopCounter])
        end -- if type end
      end  -- cargotable loop
    else -- droppingatbase
        local m = MESSAGE:New("Troops have returned to base!",15,"CTLD"):ToGroup(Group)
    end
    -- cleanup load list
    local    loaded = {} -- #CTLD.LoadedCargo
    loaded.Troopsloaded = 0
    loaded.Cratesloaded = 0
    loaded.Cargo = {}
    local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
    local cargotable = loadedcargo.Cargo or {}
    for _,_cargo in pairs (cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      local dropped = cargo:WasDropped()
      --local moved = cargo:HasMoved()
      if type ~= CTLD_CARGO.Enum.TROOP and not dropped then
        table.insert(loaded.Cargo,_cargo)
        loaded.Cratesloaded = loaded.Cratesloaded + 1
      end
    end
    self.Loaded_Cargo[unitname] = nil
    self.Loaded_Cargo[unitname] = loaded
  else
   local m = MESSAGE:New("Nothing loaded or not hovering within parameters!",10,"CTLD"):ToGroup(Group)
  end
  return self
end

--- Function to unload crates from heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrappe.Unit#UNIT Unit
function CTLD:_UnloadCrates(Group, Unit)
  self:T(self.lid .. " _UnloadCrates")
  -- check if we are in DROP zone
  local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.DROP)
  if not inzone then
    local m = MESSAGE:New("You are not close enough to a drop zone!",15,"CTLD"):ToGroup(Group)
    if not self.debug then 
      return self 
    end
  end
  -- check for hover unload
  local hoverunload = self:IsCorrectHover(Unit) --if true we\'re hovering in parameters
  -- check if we\'re landed
  local grounded = not self:IsUnitInAir(Unit)
  -- Get what we have loaded
  local unitname = Unit:GetName()
  if self.Loaded_Cargo[unitname] and (grounded or hoverunload) then
      local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
    -- looking for troops
    local cargotable = loadedcargo.Cargo
    for _,_cargo in pairs (cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if type ~= CTLD_CARGO.Enum.TROOPS and not cargo:WasDropped() then
        -- unload crates
        self:_GetCrates(Group, Unit, cargo, 1, true)
        cargo:SetWasDropped(true)
        cargo:SetHasMoved(true)
        --local name cargo:GetName()
        --local m = MESSAGE:New(string.format("Dropped Crate for %s!",name),10,"CTLD"):ToGroup(Group)
      end
    end
    -- cleanup load list
    local    loaded = {} -- #CTLD.LoadedCargo
    loaded.Troopsloaded = 0
    loaded.Cratesloaded = 0
    loaded.Cargo = {}
    for _,_cargo in pairs (cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      local size = cargo:GetCratesNeeded()
      if type == CTLD_CARGO.Enum.TROOP then
        table.insert(loaded.Cargo,_cargo)
        loaded.Cratesloaded = loaded.Troopsloaded + size
      end
    end
    self.Loaded_Cargo[unitname] = nil
    self.Loaded_Cargo[unitname] = loaded
  else
   local m = MESSAGE:New("Nothing loaded or not hovering within parameters!",10,"CTLD"):ToGroup(Group)
  end
  return self
end

--- Function to build nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrappe.Unit#UNIT Unit
function CTLD:_BuildCrates(Group, Unit)
  self:T(self.lid .. " _BuildCrates")
  -- get nearby crates
  local finddist = self.CrateDistance or 30
  local crates,number = self:_FindCratesNearby(Group,Unit, finddist) -- #table
  local buildables = {}
  local foundbuilds = false
  local canbuild = false
  if number > 0 then
    -- get dropped crates
    for _,_crate in pairs(crates) do
      local Crate = _crate -- #CTLD_CARGO
      if Crate:WasDropped() then
        -- we can build these - maybe
        local name = Crate:GetName()
        local required = Crate:GetCratesNeeded()
        local template = Crate:GetTemplates()
        local ctype = Crate:GetType()
        if not buildables[name] then
          local object = {} -- #CTLD.Buildable
          object.Name = name
          object.Required = required
          object.Found = 1
          object.Template = template
          object.CanBuild = false
          object.Type = ctype -- #CTLD_CARGO.Enum
          buildables[name] = object
          foundbuilds = true
        else
         buildables[name].Found = buildables[name].Found + 1
         if buildables[name].Found >= buildables[name].Required then 
           buildables[name].CanBuild = true
           canbuild = true
         end
         foundbuilds = true
        end
        self:T({buildables = buildables})
      end -- end dropped
    end -- end crate loop
    -- ok let\'s list what we have
    local report = REPORT:New("Checklist Buildable Crates")
    report:Add("------------------------------------------------------------")
    for _,_build in pairs(buildables) do
      local build = _build -- Object table from above
      local name = build.Name
      local needed = build.Required
      local found = build.Found
      local txtok = "NO"
      if build.CanBuild then 
        txtok = "YES" 
      end
      self:T({name,needed,found,txtok})
      local text = string.format("Type: %s | Required %d | Found %d | Can Build %s", name, needed, found, txtok)
      report:Add(text)
    end -- end list buildables
    if not foundbuilds then report:Add("     --- None Found ---") end
    report:Add("------------------------------------------------------------")
    local text = report:Text()
    local m = MESSAGE:New(text,30,"CTLD",true):ToGroup(Group)
    -- let\'s get going
    if canbuild then
      -- loop again
      for _,_build in pairs(buildables) do
        local build = _build -- #CTLD.Buildable
        if build.CanBuild then
          self:_CleanUpCrates(crates,build,number)
          self:_BuildObjectFromCrates(Group,Unit,build)
        end
      end
    end
  else
    local m = MESSAGE:New(string.format("No crates within %d meters!",finddist),15,"CTLD",true):ToGroup(Group)  
  end -- number > 0
  return self
end

--- Function to actually SPAWN buildables in the mission.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Group#UNIT Unit
-- @param #CTLD.Buildable Build
function CTLD:_BuildObjectFromCrates(Group,Unit,Build)
  self:T(self.lid .. " _BuildObjectFromCrates")
  -- Spawn-a-crate-content
  local position = Unit:GetCoordinate() or Group:GetCoordinate()
  local unitname = Unit:GetName() or Group:GetName()
  local name = Build.Name
  local type = Build.Type -- #CTLD_CARGO.Enum
  local canmove = false
  if type == CTLD_CARGO.Enum.VEHICLE then canmove = true end
  local temptable = Build.Template or {}
  local zone = ZONE_GROUP:New(string.format("Unload zone-%s",unitname),Group,100)
  local randomcoord = zone:GetRandomCoordinate(20,50):GetVec2()
  for _,_template in pairs(temptable) do
    self.TroopCounter = self.TroopCounter + 1
    local alias = string.format("%s-%d", _template, math.random(1,100000))
    self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
      :InitRandomizeUnits(true,20,2)
      :InitDelayOff()
      :SpawnFromVec2(randomcoord)
    if self.movetroopstowpzone and canmove then
      self:_MoveGroupToZone(self.DroppedTroops[self.TroopCounter])
    end
    self:__CratesBuild(1,Group,Unit,self.DroppedTroops[self.TroopCounter])
  end -- template loop
  return self
end

--- Function to move group to WP zone.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group The Group to move.
function CTLD:_MoveGroupToZone(Group)
  self:T(self.lid .. " _MoveGroupToZone")
  local groupname = Group:GetName() or "none"
  local groupcoord = Group:GetCoordinate()
  self:T(self.lid .. " _MoveGroupToZone for " .. groupname)
  -- Get closest zone of type
  local outcome, name, zone, distance  = self:IsUnitInZone(Group,CTLD.CargoZoneType.MOVE)
  self:T(string.format("Closest WP zone %s is %d meters",name,distance))
  if (distance <= self.movetroopsdistance) and zone then
    -- yes, we can ;)
    local groupname = Group:GetName()
    self:T(string.format("Moving troops %s to zone %s, distance %d!",groupname,name,distance))
    local zonecoord = zone:GetRandomCoordinate(20,125) -- Core.Point#COORDINATE
    local coordinate = zonecoord:GetVec2()
    self:T({coordinate=coordinate})
    Group:SetAIOn()
    Group:OptionAlarmStateAuto()
    Group:OptionDisperseOnAttack(30)
    Group:OptionROEOpenFirePossible()
    Group:RouteToVec2(coordinate,5)
    end
  return self
end

--- Housekeeping - Cleanup crates when build
-- @param #CTLD self
-- @param #table Crates Table of #CTLD_CARGO objects near the unit.
-- @param #CTLD.Buildable Build Table build object.
-- @param #number Number Number of objects in Crates (found) to limit search.
function CTLD:_CleanUpCrates(Crates,Build,Number)
  self:T(self.lid .. " _CleanUpCrates")
  -- clean up real world crates
  local build = Build -- #CTLD.Buildable
  self:T({Build = Build})
  local existingcrates = self.Spawned_Cargo -- #table of exising crates
  local newexcrates = {}
  -- get right number of crates to destroy
  local numberdest = Build.Required
  local nametype = Build.Name
  local found = 0
  local rounds = Number
  local destIDs = {}
  
  -- loop and find matching IDs in the set
  for _,_crate in pairs(Crates) do
    local nowcrate = _crate -- #CTLD_CARGO
    local name = nowcrate:GetName()
    self:T(string.format("Looking for Crate for %s", name))
    local thisID = nowcrate:GetID()
    if name == nametype then -- matching crate type
      table.insert(destIDs,thisID)
      found = found + 1
      nowcrate:GetPositionable():Destroy()
      nowcrate.Positionable = nil
      self:T(string.format("%s Found %d Need %d", name, found, numberdest))
    end
    if found == numberdest then break end -- got enough
  end
  self:T({destIDs})
  -- loop and remove from real world representation
  for _,_crate in pairs(existingcrates) do
    local excrate = _crate -- #CTLD_CARGO
    local ID = excrate:GetID()
    for _,_ID in pairs(destIDs) do
      if ID ~= _ID then
        table.insert(newexcrates,_crate)
      end
    end
  end
  
  -- reset Spawned_Cargo
  self.Spawned_Cargo = nil
  self.Spawned_Cargo = newexcrates
  return self
end

--- Housekeeping - Function to refresh F10 menus.
-- @param #CTLD self
-- @return #CTLD self
function CTLD:_RefreshF10Menus()
  self:T(self.lid .. " _RefreshF10Menus")
  local PlayerSet = self.PilotGroups -- Core.Set#SET_GROUP
  local PlayerTable = PlayerSet:GetSetObjects() -- #table of #GROUP objects
  
  -- rebuild units table
  local _UnitList = {}
  for _key, _group in pairs (PlayerTable) do  
    local _unit = _group:GetUnit(1) -- Asume that there is only one unit in the flight for players
    if _unit then 
      if _unit:IsAlive() then         
        local unitName = _unit:GetName()
            _UnitList[unitName] = unitName
      end -- end isAlive
    end -- end if _unit
  end -- end for
  self.CtldUnits = _UnitList
  
  -- build unit menus

  local menucount = 0
  local menus = {}  
  for _, _unitName in pairs(self.CtldUnits) do
    if not self.MenusDone[_unitName] then 
      local _unit = UNIT:FindByName(_unitName) -- Wrapper.Unit#UNIT
      if _unit then
        local _group = _unit:GetGroup() -- Wrapper.Group#GROUP
        if _group then
          -- get chopper capabilities
          local unittype = _unit:GetTypeName()
          local capabilities = self.UnitTypes[unittype] -- #CTLD.UnitCapabilities
          local cantroops = capabilities.troops
          local cancrates = capabilities.crates
          -- top menu
          local topmenu = MENU_GROUP:New(_group,"CTLD",nil)
          local topcrates = MENU_GROUP:New(_group,"Manage Crates",topmenu)
          local toptroops = MENU_GROUP:New(_group,"Manage Troops",topmenu)
          local listmenu = MENU_GROUP_COMMAND:New(_group,"List boarded cargo",topmenu, self._ListCargo, self, _group, _unit)
          local smokemenu = MENU_GROUP_COMMAND:New(_group,"Smoke zones nearby",topmenu, self.SmokeZoneNearBy, self, _unit, false)
          local smokemenu = MENU_GROUP_COMMAND:New(_group,"Flare zones nearby",topmenu, self.SmokeZoneNearBy, self, _unit, true):Refresh()
          -- sub menus
          -- sub menu crates management
          if cancrates then 
            local loadmenu = MENU_GROUP_COMMAND:New(_group,"Load crates",topcrates, self._LoadCratesNearby, self, _group, _unit)
            local cratesmenu = MENU_GROUP:New(_group,"Get Crates",topcrates)
            for _,_entry in pairs(self.Cargo_Crates) do
              local entry = _entry -- #CTLD_CARGO
              menucount = menucount + 1
              local menutext = string.format("Get crate for %s",entry.Name)
              menus[menucount] = MENU_GROUP_COMMAND:New(_group,menutext,cratesmenu,self._GetCrates, self, _group, _unit, entry)
            end
            listmenu = MENU_GROUP_COMMAND:New(_group,"List crates nearby",topcrates, self._ListCratesNearby, self, _group, _unit)
            local unloadmenu = MENU_GROUP_COMMAND:New(_group,"Drop crates",topcrates, self._UnloadCrates, self, _group, _unit)
            local buildmenu = MENU_GROUP_COMMAND:New(_group,"Build crates",topcrates, self._BuildCrates, self, _group, _unit):Refresh()
          end
          -- sub menu troops management
          if cantroops then 
            local troopsmenu = MENU_GROUP:New(_group,"Load troops",toptroops)
            for _,_entry in pairs(self.Cargo_Troops) do
              local entry = _entry -- #CTLD_CARGO
              menucount = menucount + 1
              menus[menucount] = MENU_GROUP_COMMAND:New(_group,entry.Name,troopsmenu,self._LoadTroops, self, _group, _unit, entry)
            end
            local unloadmenu1 = MENU_GROUP_COMMAND:New(_group,"Drop troops",toptroops, self._UnloadTroops, self, _group, _unit):Refresh()
          end
          local rbcns = MENU_GROUP_COMMAND:New(_group,"List active zone beacons",topmenu, self._ListRadioBeacons, self, _group, _unit)
          local hoverpars = MENU_GROUP_COMMAND:New(_group,"Show hover parameters",topmenu, self._ShowHoverParams, self, _group, _unit):Refresh()
          self.MenusDone[_unitName] = true
        end -- end group
      end -- end unit
    else -- menu build check
      self:T(self.lid .. " Menus already done for this group!")
    end  -- end menu build check
  end  -- end for
  return self
 end

--- User function - Add *generic* troop type loadable as cargo. This type will load directly into the heli without crates.
-- @param #CTLD self
-- @param #Name Name Unique name of this type of troop. E.g. "Anti-Air Small".
-- @param #Table Templates Table of #string names of late activated Wrapper.Group#GROUP making up this troop.
-- @param #CTLD_CARGO.Enum Type Type of cargo, here TROOPS - these will move to a nearby destination zone when dropped/build.
-- @param #number NoTroops Size of the group in number of Units across combined templates (for loading).
function CTLD:AddTroopsCargo(Name,Templates,Type,NoTroops)
  self:T(self.lid .. " AddTroopsCargo")
  self.CargoCounter = self.CargoCounter + 1
  -- Troops are directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,Templates,Type,false,true,NoTroops)
  table.insert(self.Cargo_Troops,cargo)
  return self
end

--- User function - Add *generic* crate-type loadable as cargo. This type will create crates that need to be loaded, moved, dropped and built.
-- @param #CTLD self
-- @param #Name Name Unique name of this type of cargo. E.g. "Humvee".
-- @param #Table Templates Table of #string names of late activated Wrapper.Group#GROUP building this cargo.
-- @param #CTLD_CARGO.Enum Type Type of cargo. I.e. VEHICLE or FOB. VEHICLE will move to destination zones when dropped/build, FOB stays put.
-- @param #number NoCrates Number of crates needed to build this cargo.
function CTLD:AddCratesCargo(Name,Templates,Type,NoCrates)
  self:T(self.lid .. " AddCratesCargo")
  self.CargoCounter = self.CargoCounter + 1
  -- Crates are not directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,Templates,Type,false,false,NoCrates)
  table.insert(self.Cargo_Crates,cargo)
  return self
end

--- User function - Add a #CTLD.CargoZoneType zone for this CTLD instance.
-- @param #CTLD self
-- @param #CTLD.CargoZone Zone Zone #CTLD.CargoZone describing the zone.
function CTLD:AddZone(Zone)
  self:T(self.lid .. " AddZone")
  local zone = Zone -- #CTLD.CargoZone
  if zone.type == CTLD.CargoZoneType.LOAD then
    table.insert(self.pickupZones,zone)
    self:T("Registered LOAD zone " .. zone.name)
  elseif zone.type == CTLD.CargoZoneType.DROP then
    table.insert(self.dropOffZones,zone)
    self:T("Registered DROP zone " .. zone.name)
  else
    table.insert(self.wpZones,zone)
    self:T("Registered MOVE zone " .. zone.name)
  end
  return self
end

--- User function - Activate Name #CTLD.CargoZone.Type ZoneType for this CTLD instance.
-- @param #CTLD self
-- @param #string Name Name of the zone to change in the ME.
-- @param #CTLD.CargoZoneTyp ZoneType Type of zone this belongs to.
-- @param #boolean NewState (Optional) Set to true to activate, false to switch off.
function CTLD:ActivateZone(Name,ZoneType,NewState)
  self:T(self.lid .. " AddZone")
  local newstate = true
  -- set optional in case we\'re deactivating
  if not NewState or NewState == false then
    newstate = false
  end
  -- get correct table
  local zone = ZoneType -- #CTLD.CargoZone
  local table = {}
  if zone.type == CTLD.CargoZoneType.LOAD then
    table = self.pickupZones
  elseif zone.type == CTLD.CargoZoneType.DROP then
    table = self.dropOffZones
  else
    table = self.wpZones
  end
  -- loop table
  for _,_zone in pairs(table) do
    local thiszone = _zone --#CTLD.CargoZone
    if thiszone.name == Name then
      thiszone.active = newstate
      break
    end
  end
  return self
end

--- User function - Deactivate Name #CTLD.CargoZoneType ZoneType for this CTLD instance.
-- @param #CTLD self
-- @param #string Name Name of the zone to change in the ME.
-- @param #CTLD.CargoZoneTyp ZoneType Type of zone this belongs to.
function CTLD:DeactivateZone(Name,ZoneType)
  self:T(self.lid .. " AddZone")
  self:ActivateZone(Name,ZoneType,false)
  return self
end

--- Function to obtain a valid FM frequency.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @return #CTLD.ZoneBeacon Beacon Beacon table.
function CTLD:_GetFMBeacon(Name)
  self:T(self.lid .. " _GetFMBeacon")
  local beacon = {} -- #CTLD.ZoneBeacon  
  if #self.FreeFMFrequencies <= 1 then
      self.FreeFMFrequencies = self.UsedFMFrequencies
      self.UsedFMFrequencies = {}
  end 
  --random
  local FM = table.remove(self.FreeFMFrequencies, math.random(#self.FreeFMFrequencies))
  table.insert(self.UsedFMFrequencies, FM)  
  beacon.name = Name
  beacon.frequency = FM / 1000000
  beacon.modulation = radio.modulation.FM

  return beacon
end

--- Function to obtain a valid UHF frequency.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @return #CTLD.ZoneBeacon Beacon Beacon table.
function CTLD:_GetUHFBeacon(Name)
  self:T(self.lid .. " _GetUHFBeacon")
  local beacon = {} -- #CTLD.ZoneBeacon  
  if #self.FreeUHFFrequencies <= 1 then
      self.FreeUHFFrequencies = self.UsedUHFFrequencies
      self.UsedUHFFrequencies = {}
  end 
  --random
  local UHF = table.remove(self.FreeUHFFrequencies, math.random(#self.FreeUHFFrequencies))
  table.insert(self.UsedUHFFrequencies, UHF)
  beacon.name = Name
  beacon.frequency = UHF / 1000000
  beacon.modulation = radio.modulation.AM

  return beacon
end

--- Function to obtain a valid VHF frequency.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @return #CTLD.ZoneBeacon Beacon Beacon table.
function CTLD:_GetVHFBeacon(Name)
  self:T(self.lid .. " _GetVHFBeacon")
  local beacon = {} -- #CTLD.ZoneBeacon
  if #self.FreeVHFFrequencies <= 3 then
      self.FreeVHFFrequencies = self.UsedVHFFrequencies
      self.UsedVHFFrequencies = {}
  end
  --get random
  local VHF = table.remove(self.FreeVHFFrequencies, math.random(#self.FreeVHFFrequencies))
  table.insert(self.UsedVHFFrequencies, VHF)
  beacon.name = Name
  beacon.frequency = VHF / 1000000
  beacon.modulation = radio.modulation.FM
  return beacon
end


--- User function - Crates and adds a #CTLD.CargoZone zone for this CTLD instance.
--  Zones of type LOAD: Players load crates and troops here.  
--  Zones of type DROP: Players can drop crates here. Note that troops can be unloaded anywhere.  
--  Zone of type MOVE: Dropped troops and vehicles will start moving to the nearest zone of this type (also see options).  
-- @param #CTLD self
-- @param #string Name Name of this zone, as in Mission Editor.
-- @param #string Type Type of this zone, #CTLD.CargoZoneType
-- @param #number Color Smoke/Flare color e.g. #SMOKECOLOR.Red
-- @param #string Active Is this zone currently active?
-- @param #string HasBeacon Does this zone have a beacon if it is active?
-- @return #CTLD self
function CTLD:AddCTLDZone(Name, Type, Color, Active, HasBeacon)
  self:T(self.lid .. " AddCTLDZone")

  local ctldzone = {} -- #CTLD.CargoZone
  ctldzone.active = Active or false
  ctldzone.color = Color or SMOKECOLOR.Red
  ctldzone.name = Name or "NONE"
  ctldzone.type = Type or CTLD.CargoZoneType.MOVE -- #CTLD.CargoZoneType
  ctldzone.hasbeacon = HasBeacon or false
   
  if HasBeacon then
    ctldzone.fmbeacon = self:_GetFMBeacon(Name)
    ctldzone.uhfbeacon = self:_GetUHFBeacon(Name)
    ctldzone.vhfbeacon = self:_GetVHFBeacon(Name)
  else
    ctldzone.fmbeacon = nil
    ctldzone.uhfbeacon = nil
    ctldzone.vhfbeacon = nil
  end
  
  self:AddZone(ctldzone)
  return self
end

--- Function to show list of radio beacons
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
function CTLD:_ListRadioBeacons(Group, Unit)
  self:T(self.lid .. " _ListRadioBeacons")
  local report = REPORT:New("Active Zone Beacons")
  report:Add("------------------------------------------------------------")
  local zones = {[1] = self.pickupZones, [2] = self.wpZones, [3] = self.dropOffZones}
  for i=1,3 do
    for index,cargozone in pairs(zones[i]) do
      -- Get Beacon object from zone
      local czone = cargozone -- #CTLD.CargoZone
      if czone.active and czone.hasbeacon then
        local FMbeacon = czone.fmbeacon -- #CTLD.ZoneBeacon
        local VHFbeacon = czone.vhfbeacon -- #CTLD.ZoneBeacon
        local UHFbeacon = czone.uhfbeacon -- #CTLD.ZoneBeacon
        local Name = czone.name
        local FM = FMbeacon.frequency  -- MHz
        local VHF = VHFbeacon.frequency * 1000 -- KHz
        local UHF = UHFbeacon.frequency  -- MHz
        report:AddIndent(string.format(" %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ", Name, FM, VHF, UHF),"|")
      end
    end
  end
  if report:GetCount() == 1 then
    report:Add("--------- N O N E ------------")
  end
  report:Add("------------------------------------------------------------")
  local m = MESSAGE:New(report:Text(),30,"CTLD",true):ToGroup(Group)
  return self
end

--- Add radio beacon to zone. Runs 30 secs.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @param #string Sound Name of soundfile.
-- @param #number Mhz Frequency in Mhz.
-- @param #number Modulation Modulation AM or FM.
function CTLD:_AddRadioBeacon(Name, Sound, Mhz, Modulation)
  self:T(self.lid .. " _AddRadioBeacon")
  local Zone = ZONE:FindByName(Name)
  local Sound = Sound or "beacon.ogg"
  if Zone then
    local ZoneCoord = Zone:GetCoordinate()
    local ZoneVec3 = ZoneCoord:GetVec3()
    local Frequency = Mhz * 1000000 -- Freq in Hertz
    local Sound =  "l10n/DEFAULT/"..Sound
    trigger.action.radioTransmission(Sound, ZoneVec3, Modulation, false, Frequency, 1000) -- Beacon in MP only runs for 30secs straight
  end
  return self
end

--- Function to refresh radio beacons
-- @param #CTLD self
function CTLD:_RefreshRadioBeacons()
  self:I(self.lid .. " _RefreshRadioBeacons")

  local zones = {[1] = self.pickupZones, [2] = self.wpZones, [3] = self.dropOffZones}
  for i=1,3 do
    for index,cargozone in pairs(zones[i]) do
      -- Get Beacon object from zone
      local czone = cargozone -- #CTLD.CargoZone
      local Sound = self.RadioSound
      if czone.active and czone.hasbeacon then
        local FMbeacon = czone.fmbeacon -- #CTLD.ZoneBeacon
        local VHFbeacon = czone.vhfbeacon -- #CTLD.ZoneBeacon
        local UHFbeacon = czone.uhfbeacon -- #CTLD.ZoneBeacon
        local Name = czone.name
        local FM = FMbeacon.frequency  -- MHz
        local VHF = VHFbeacon.frequency -- KHz
        local UHF = UHFbeacon.frequency  -- MHz      
        self:_AddRadioBeacon(Name,Sound,FM,radio.modulation.FM)
        self:_AddRadioBeacon(Name,Sound,VHF,radio.modulation.FM)
        self:_AddRadioBeacon(Name,Sound,UHF,radio.modulation.AM)
      end
    end
  end
  return self
end

--- function to see if a unit is in a specific zone type.
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit Unit
-- @param #CTLD.CargoZoneType Zonetype Zonetype
-- @return #boolean Outcome Is in zone or not
-- @return #string name Closest zone name
-- @return #string zone Closest Core.Zone#ZONE object
-- @return #number distance Distance to closest zone
function CTLD:IsUnitInZone(Unit,Zonetype)
  self:T(self.lid .. " IsUnitInZone")
  local unitname = Unit:GetName()
  self:T(string.format("%s | Zone search for %s | Type %s",self.lid,unitname,Zonetype))
  local zonetable = {}
  local outcome = false
  if Zonetype == CTLD.CargoZoneType.LOAD then
    zonetable = self.pickupZones -- #table
  elseif Zonetype == CTLD.CargoZoneType.DROP then
    zonetable = self.dropOffZones -- #table
  else 
   zonetable = self.wpZones -- #table
  end
  --- now see if we\'re in
  local zonecoord = nil
  local colorret = nil
  local maxdist = 1000000 -- 100km
  local zoneret = nil
  local zonenameret = nil
  for _,_cargozone in pairs(zonetable) do
    local czone = _cargozone -- #CTLD.CargoZone
    local unitcoord = Unit:GetCoordinate()
    local zonename = czone.name
    local zone = ZONE:FindByName(zonename)
    zonecoord = zone:GetCoordinate()
    local active = czone.active
    local color = czone.color
    local zoneradius = zone:GetRadius()
    local distance = self:_GetDistance(zonecoord,unitcoord)
    self:T(string.format("Check distance: %d",distance))
    if distance <= zoneradius and active then 
      outcome = true
    end
    if maxdist > distance then 
      maxdist = distance
      zoneret = zone 
      zonenameret = zonename
      colorret = color 
    end
  end
  self:T({outcome, zonenameret, zoneret, maxdist})
  return outcome, zonenameret, zoneret, maxdist
end

--- Userfunction - Start smoke in a zone close to the Unit.
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit The Unit.
-- @param #boolean Flare If true, flare instead.
function CTLD:SmokeZoneNearBy(Unit, Flare)
  self:T(self.lid .. " SmokeZoneNearBy")
  -- table of #CTLD.CargoZone table
  local unitcoord = Unit:GetCoordinate()
  local Group = Unit:GetGroup()
  local smokedistance = self.smokedistance
  local smoked = false
  local zones = {[1] = self.pickupZones, [2] = self.wpZones, [3] = self.dropOffZones}
  for i=1,3 do
    for index,cargozone in pairs(zones[i]) do
      local CZone = cargozone --#CTLD.CargoZone
      local zonename = CZone.name
      local zone = ZONE:FindByName(zonename)
      local zonecoord = zone:GetCoordinate()
      local active = CZone.active
      local color = CZone.color
      local distance = self:_GetDistance(zonecoord,unitcoord)
      if distance < smokedistance and active then
        -- smoke zone since we\'re nearby
        if not Flare then 
          zonecoord:Smoke(color or SMOKECOLOR.White)
        else
          if color == SMOKECOLOR.Blue then color = FLARECOLOR.White end
          zonecoord:Flare(color or FLARECOLOR.White)
        end
        local txt = "smoking"
        if Flare then txt = "flaring" end
        local m = MESSAGE:New(string.format("Roger, %s zone %s!",txt, zonename),10,"CTLD"):ToGroup(Group)
        smoked = true
      end
    end
  end
  if not smoked then
    local distance = UTILS.MetersToNM(self.smkedistance)
    local m = MESSAGE:New(string.format("Negative, need to be closer than %dnm to a zone!",distance),10,"CTLD"):ToGroup(Group)
  end
  return self 
end
  --- User - Function to add/adjust unittype capabilities.
  -- @param #CTLD self
  -- @param #string Unittype The unittype to adjust. If passed as Wrapper.Unit#UNIT, it will search for the unit in the mission.
  -- @param #boolean Cancrates Unit can load crates.
  -- @param #boolean Cantroops Unit can load troops.
  -- @param #number Cratelimit Unit can carry number of crates.
  -- @param #number Trooplimit Unit can carry number of troops.
  function CTLD:UnitCapabilities(Unittype, Cancrates, Cantroops, Cratelimit, Trooplimit)
    self:T(self.lid .. " UnitCapabilities")
    local unittype =  nil
    local unit = nil
    if type(Unittype) == "string" then
      unittype = Unittype
    elseif type(Unittype) == "table" then
      unit = UNIT:FindByName(Unittype) -- Wrapper.Unit#UNIT
      unittype = unit:GetTypeName()
    else
      return self
    end
    -- set capabilities
    local capabilities = {} -- #CTLD.UnitCapabilities
    capabilities.type = unittype
    capabilities.crates = Cancrates or false
    capabilities.troops = Cantroops or false
    capabilities.cratelimit = Cratelimit or  0
    capabilities.trooplimit = Trooplimit or 0
    self.UnitTypes[unittype] = capabilities
    return self
  end
  
  --- Check if a unit is hovering *in parameters*.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:IsCorrectHover(Unit)
    self:T(self.lid .. " IsCorrectHover")
    local outcome = false
    -- see if we are in air and within parameters.
    if self:IsUnitInAir(Unit) then
      -- get speed and height
      local uspeed = Unit:GetVelocityMPS()
      local uheight = Unit:GetHeight()
      local ucoord = Unit:GetCoordinate()
      local gheight = ucoord:GetLandHeight()
      local aheight = uheight - gheight -- height above ground
      local maxh = self.maximumHoverHeight -- 15
      local minh =  self.minimumHoverHeight -- 5
      local mspeed = 2 -- 2 m/s
      self:T(string.format("%s Unit parameters: at %dm AGL with %dmps",self.lid,aheight,uspeed))
      if (uspeed <= maxh) and (aheight <= maxh) and (aheight >= minh)  then 
        -- yep within parameters
        outcome = true
      end
    end
    return outcome
  end
  
  --- List if a unit is hovering *in parameters*.
  -- @param #CTLD self
  -- @param Wrapper.Group#GROUP Group
  -- @param Wrapper.Unit#UNIT Unit
  function CTLD:_ShowHoverParams(Group,Unit)
    local inhover = self:IsCorrectHover(Unit)
    local htxt = "true"
    if not inhover then htxt = "false" end
    local text = string.format("Hover parameter (autoload):\n - Min height %dm \n - Max height %dm \n - Max speed 2mps \n - In parameter: %s", self.minimumHoverHeight, self.maximumHoverHeight, htxt)
    local m = MESSAGE:New(text,10,"CTLD",false):ToGroup(Group)
    return self
  end
  
  --- Check if a unit is in a load zone and is hovering in parameters.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:CanHoverLoad(Unit)
    self:T(self.lid .. " CanHoverLoad")
    local outcome = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD) and self:IsCorrectHover(Unit)
    return outcome
  end
  
    --- Check if a unit is above ground.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:IsUnitInAir(Unit)
    -- get speed and height
    local uheight = Unit:GetHeight()
    local ucoord = Unit:GetCoordinate()
    local gheight = ucoord:GetLandHeight()
    local aheight = uheight - gheight -- height above ground
    if aheight >= self.minimumHoverHeight then
      return true
    else
      return false
    end
  end
  
   --- Autoload if we can do crates, have capacity free and are in a load zone.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #CTLD self
  function CTLD:AutoHoverLoad(Unit)
    self:T(self.lid .. " AutoHoverLoad")
    -- get capabilities and current load
    local unittype = Unit:GetTypeName()
    local unitname = Unit:GetName()
    local Group = Unit:GetGroup()
    local capabilities = self.UnitTypes[unittype] -- #CTLD.UnitCapabilities
    local cancrates = capabilities.crates -- #boolean
    local cratelimit = capabilities.cratelimit -- #number
    if cancrates then
      -- get load
      local numberonboard = 0
      local loaded = {}
      if self.Loaded_Cargo[unitname] then
        loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
        numberonboard = loaded.Cratesloaded or 0
      end
      local load = cratelimit - numberonboard
      local canload = self:CanHoverLoad(Unit)
      if canload and load > 0 then
        self:_LoadCratesNearby(Group,Unit)
      end
    end
    return self
  end
  
  --- Run through all pilots and see if we autoload.
  -- @param #CTLD self
  -- @return #CTLD self
  function CTLD:CheckAutoHoverload()
    if self.hoverautoloading then
      for _,_pilot in pairs (self.CtldUnits) do
        local Unit = UNIT:FindByName(_pilot)
        self:AutoHoverLoad(Unit)
      end
    end
    return self
  end
  
------------------------------------------------------------------- 
-- FSM functions
------------------------------------------------------------------- 

  --- FSM Function onafterStart.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onafterStart(From, Event, To)
    self:I({From, Event, To})
    if self.useprefix then
      self.PilotGroups = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterPrefixes(self.prefixes):FilterCategoryHelicopter():FilterStart()
    else
      self.PilotGroups = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterCategoryHelicopter():FilterStart()
    end
    -- Events
    self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
    self:HandleEvent(EVENTS.PlayerEnterUnit, self._EventHandler)
    self:HandleEvent(EVENTS.PlayerLeaveUnit, self._EventHandler)   
    self:__Status(-5)
    return self
  end

  --- FSM Function onbeforeStatus.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onbeforeStatus(From, Event, To)
    self:T({From, Event, To})
    self:_RefreshF10Menus()
    self:_RefreshRadioBeacons()
    self:CheckAutoHoverload()
    return self
  end
  
  --- FSM Function onafterStatus.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onafterStatus(From, Event, To)
    self:I({From, Event, To})
     -- gather some stats
    -- pilots
    local pilots = 0
    for _,_pilot in pairs (self.CtldUnits) do
    
     pilots = pilots + 1
    end
     
    -- spawned cargo boxes curr in field
    local boxes = 0
    for _,_pilot in pairs (self.Spawned_Cargo) do
     boxes = boxes + 1
    end
    
    local cc =  self.CargoCounter
    local tc = self.TroopCounter
    
    if self.debug or self.verbose > 0 then 
      local text = string.format("%s Pilots %d | Live Crates %d |\nCargo Counter %d | Troop Counter %d", self.lid, pilots, boxes, cc, tc)
      local m = MESSAGE:New(text,10,"CTLD"):ToAll() 
    end
    self:__Status(-30)
    return self
  end
  
  --- FSM Function onafterStop.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onafterStop(From, Event, To)
    self:T({From, Event, To})
    self:UnhandleEvent(EVENTS.PlayerEnterAircraft)
    self:UnhandleEvent(EVENTS.PlayerEnterUnit)
    self:UnhandleEvent(EVENTS.PlayerLeaveUnit)
    return self
  end
  
  --- FSM Function onbeforeTroopsPickedUp.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate.
  -- @return #CTLD self
  function CTLD:onbeforeTroopsPickedUp(From, Event, To, Group, Unit, Cargo)
    self:I({From, Event, To})
    return self
  end
  
    --- FSM Function onbeforeCratesPickedUp.
  -- @param #CTLD self
  -- @param #string From State .
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate.
  -- @return #CTLD self
  function CTLD:onbeforeCratesPickedUp(From, Event, To, Group, Unit, Cargo)
    self:I({From, Event, To})
    return self
  end
  
    --- FSM Function onbeforeTroopsDeployed.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops Troops #GROUP Object.
  -- @return #CTLD self
  function CTLD:onbeforeTroopsDeployed(From, Event, To, Group, Unit, Troops)
    self:I({From, Event, To})
    return self
  end
  
    --- FSM Function onbeforeCratesDropped.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects dropped.
  -- @return #CTLD self
  function CTLD:onbeforeCratesDropped(From, Event, To, Group, Unit, Cargotable)
    self:I({From, Event, To})
    return self
  end
  
    --- FSM Function onbeforeCratesBuild.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB build.
  -- @return #CTLD self
  function CTLD:onbeforeCratesBuild(From, Event, To, Group, Unit, Vehicle)
    self:I({From, Event, To})
    return self
  end
  
end -- end do
-------------------------------------------------------------------
-- End Ops.CTLD.lua
-------------------------------------------------------------------
