--- **Ops** - (R2.5) - Random Air Traffic.
-- 
-- 
-- 
-- RAT2 creates random air traffic on the map.
-- 
-- 
--
-- **Main Features:**
--
--     * It's very random.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Functional.Ratcraft
-- @image Functional_Ratcraft.png


--- RATCRAFT class.
-- @type RATCRAFT
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number coalition Coalition side.
-- @field #number country Country number.
-- @field #number size Max size in meters.
-- @field #table liveries Table of liveries.
-- @field #string livery Livery.
-- @field #string actype Aircraft type name.
-- @field #number category Category (plane=X, helo=Y).
-- @field #RATCRAFT.Attribute attribute Attribute.
-- @field #table template Spawn template table.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\RAT2\RAT2_Main.png)
--
-- # The RAT2 Concept
-- 
-- 
-- 
-- @field #RATCRAFT
RATCRAFT = {
  ClassName      = "RATCRAFT",
  Debug          = false,
  lid            = nil,
  liveries       =  {},
  livery         = nil,
  actype         = nil,
  attribute      = nil,
  ceiling        = nil,
  speedmax       = nil,
  sizex          = nil,
  sizez          = nil,
  size           = nil,
  commute        = nil,
  coalition      = nil,
  country        = nil,
  skill          = nil,
  onboard        = nil,
  departures     =  {},
  destinations   =  {},
  departure      = nil,
  destination    = nil,
  commute        = nil,
  takeoff        = nil,
  landing        = nil,
}

--- Generalized asset attributes. Can be used to request assets with certain general characteristics. See [DCS attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes) on hoggit.
-- @type RATCRAFT.Attribute
-- @field #string TRANSPORTPLANE Airplane with transport capability. This can be used to transport other assets.
-- @field #string AWACS Airborne Early Warning and Control System.
-- @field #string FIGHTER Fighter, interceptor, ... airplane.
-- @field #string BOMBER Aircraft which can be used for strategic bombing.
-- @field #string TANKER Airplane which can refuel other aircraft.
-- @field #string TRANSPORTHELO Helicopter with transport capability. This can be used to transport other assets.
-- @field #string ATTACKHELO Attack helicopter.
-- @field #string UAV Unpiloted Aerial Vehicle, e.g. drones.
RATCRAFT.Attribute = {
  TRANSPORTPLANE="TransportPlane",
  AWACS="AWACS",
  FIGHTER="Fighter",
  BOMBER="Bomber",
  TANKER="Tanker",
  TRANSPORTHELO="TransportHelo",
  ATTACKHELO="AttackHelo",
  UAV="UAV",
  OTHER="Other",
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new AIRBOSS class object for a specific aircraft carrier unit.
-- @param #RATCRAFT self
-- @return #RATCRAFT self
function RATCRAFT:New(group)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #RATCRAFT
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Load",            "Stopped")     -- Load player scores from file.
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start RAT2 script.
  
end

function RATCRAFT:_Init()


end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a departure to 
-- @param #RATCRAFT self
-- @return #RATCRAFT self
function RATCRAFT:AddDeparture(departure)

  if type(departure)=="string" then
  
  else
  
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Departure Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get departure.
-- @param #RATCRAFT self
-- @return Wrapper.Airbase#AIRBASE
function RATCRAFT:_GetDeparture()

  
  

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get number of alive groups
-- @param #RATCRAFT self
-- @return #number N live.
function RATCRAFT:_GetAliveGroups()

  return 0
end


