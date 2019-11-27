--- **Functional** - (R2.5) - Random Air Traffic.
-- 
-- 
-- 
-- RATCRAFT creates random air traffic on the map.
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
-- @module Functional.RatCraft
-- @image Functional_Rat2.png

--- RATCRAFT
-- 
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
-- @field #string attribute Attribute.
-- @field #table template Spawn template table.
-- @extends Core.Fsm#FSM
RATCRAFT = {
  ClassName      = "RATCRAFT",
  Debug          = false,
  lid            = nil,
  templatename   = nil,
  alias          = nil,
  idx            =   0,
  liveries       =  {},
  livery         = nil,
  actype         = nil,
  attribute      = nil,
  ceiling        = nil,
  speedmax       = nil,
  sizex          = nil,
  sizez          = nil,
  size           = nil,
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
  flights        =  {},
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

--- Departure/destination 
-- @type RATCRAFT.DeType
-- @field #string AIRBASE Departure/destination is an airbase.
-- @field #string ZONE Departure/destination is a zone.
RATCRAFT.DeType={
  AIRBASE="Airbase",
  ZONE="Zone",
}

--- Departure/destination 
-- @type RATCRAFT.Departure
-- @field #string name
-- @field #string type

--- Create a new AIRBOSS class object for a specific aircraft carrier unit.
-- @param #RATCRAFT self
-- @param #string groupname Name of the late activated template group.
-- @param #string alias Alias for the group name used as spawning name prefix. 
-- @return #RATCRAFT self
function RATCRAFT:New(groupname, alias)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) --#RATCRAFT
  
  self.templategroup=GROUP:FindByName(groupname)
  self.templatename=groupname
  self.alias=alias
  
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Load",            "Stopped")     -- Load player scores from file.
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start RAT2 script.
  
  return self
end

--- Init aircraft parameters.
-- @param #RATCRAFT self
-- @return #RATCRAFT self
function RATCRAFT:_Init()


end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a departure for the aircraft.
-- @param #RATCRAFT self
-- @return #RATCRAFT self
function RATCRAFT:AddDeparture(departure)

  if type(departure)=="string" then
  
    -- Try to find an airbase.
    local airbase=AIRBASE:FindByName(departure)
    local zone=ZONE:New(ZoneName)
    
    if airbase then
      self:AddDepartureAirbase(airbase)
    else
      self:AddDepartureZone(departure)
    end
  
  else
  
  end

end

--- Add one or multiple departure airbase(s) for the aircraft.
-- @param #RATCRAFT self
-- @param #string airbase Departure airbase name or a table of names.
-- @return #RATCRAFT self
function RATCRAFT:AddDepartureAirbase(airbase)

  local departure={} --#RATCRAFT.Departure  
    
  if type(airbase)=="table" then
  
    for _,ab in pairs(airbase) do
      departure.name=ab
      departure.type=RATCRAFT.DeType.AIRBASE
      table.insert(self.departures, departure)
    end
  
  else
  
    departure.name=airbase
    departure.type=RATCRAFT.DeType.AIRBASE  
    table.insert(self.departures, departure)
    
  end
  
  return self
end

--- Add a departure for the aircraft.
-- @param #RATCRAFT self
-- @param Core.Zone#ZONE zone Zone.
-- @return #RATCRAFT self
function RATCRAFT:AddDepartureZone(zone)

  local departure={} --#RATCRAFT.Departure
  
  departure.type={}
  
  table.insert(self.departures, zone)
  

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Departure Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get departure.
-- @param #RATCRAFT self
-- @return #RATCRAFT.Departure
-- @return #table Parking data table.
function RATCRAFT:GetDeparture()

  local departures=UTILS.DeepCopy(self.departures)
  
  -- Try each departure in random order.
  for i=1,#departures do
    
    -- Roll dice.
    local r=math.random(#departures)
    
    -- Get random departure
    local departure=departures[r] --#RATCRAFT.Departure
    
    -- Check if airbase or zone.
    if departure.type==RATCRAFT.DeType.AIRBASE then
    
      ---
      -- Airbase
      ---
    
      local airbase=AIRBASE:FindByName(departure.name)
      
      if airbase then
        
        local group=self.templategroup --Wrapper.Group#GROUP
        
        -- Get number of free parking spots.
        local parking=airbase:FindFreeParkingSpotForAircraft(group)
      
        if #parking>=#group:GetUnits() then
          
          return departure, parking
        
        else
        
          -- Remove from table so it does not get selected again.
          table.remove(departures, r)
          
        end
      
      else
        self:E("ERROR: Could not find airbase!")
      end
      
    else
    
      ---
      -- Zone
      ---
    
    end
    
  end

end


--- Get destination.
-- @param #RATCRAFT self
-- @param #RATCRAFT.Departure departure The chosen departure.
-- @return #RATCRAFT.Departure
function RATCRAFT:GetDestination(departure)

  -- Create copy of all destinations.
  local destinations=UTILS.DeepCopy(self.destinations)
  
  -- Try each departure in random order.
  for i=1,#destinations do
    
    -- Roll dice.
    local r=math.random(#destinations)
    
    -- Get random departure
    local destination=destinations[r] --#RATCRAFT.Departure
    
    -- Check if airbase or zone.
    if destination.type==RATCRAFT.DeType.AIRBASE then
    
      ---
      -- Airbase
      ---
    
      -- Get airbase.
      local airbase=AIRBASE:FindByName(destination.name)
      
      local dest=AIRBASE:FindByName(departure.name)
      
      if airbase then
        -- TODO: check
        -- coalition, terminal type, distance
        
        local distance=dest:GetCoordinate():Get2DDistance(airbase:GetCoordinate())
      
        if distance then
          
          return departure
        
        else
        
          -- Remove from table so it does not get selected again.
          table.remove(destinations, r)
          
        end
      
      else
        self:E("ERROR: Could not find airbase!")
      end
      
    else
    
      ---
      -- Zone
      ---
    
    end
    
  end

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