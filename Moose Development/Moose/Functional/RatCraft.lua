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
-- @field #boolean Debugmode Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string templatename Name of the group template.
-- @field #string alias Alias for spawn prefix. Default template group name.
-- @field #table template Table of the group template.
-- @field Wrapper.Group#GROUP templategroup Template group.
-- @field #number coalition Coalition side.
-- @field #number country Country number.
-- @field #string actype Aircraft type name.
-- @field #number category Category (plane=X, helo=Y).
-- @field #string attribute Generalized attribute.
-- @field #number ceiling Max altitude in meters of the aircraft group.
-- @field #number speedmax Max speed in km/h of the aircraft group. 
-- @field #number sizex Size X-axis in meters.
-- @field #number sizez Size Z-axis in meters.
-- @field #number size Max size (X, Z) in meters.
-- @field #table liveries Table of liveries.
-- @field #string livery Current livery.
-- @field #string skill Skill of group.
-- @field #string onboard Onboard number. This should better be on UNIT level!
-- @field #table departures Defined departures.
-- @field #table departure Current departure airbase or zone.
-- @field #table destinations Defined destinations.
-- @field #table destination Current destination.
-- @field #boolean commute If true, commute between to airbases/zones.
-- @field #boolean journey If true, continue journey from the current destination.
-- @field #string takeoff Takeoff type cold, hot, air.
-- @field #string landing Landing type.
-- @field #table flights Table of flight groups.
-- @field #number Nspawn Number of max spawned aircraft groups. 
-- @extends Core.Fsm#FSM
RATCRAFT = {
  ClassName      = "RATCRAFT",
  Debugmode      = false,
  lid            = nil,
  templatename   = nil,
  alias          = nil,
  template       = nil,
  templategroup  = nil,
  coalition      = nil,
  country        = nil,  
  actype         = nil,
  category       = nil,
  attribute      = nil,
  ceiling        = nil,
  speedmax       = nil,
  sizex          = nil,
  sizez          = nil,
  size           = nil,
  liveries       =  {},
  livery         = nil,
  skill          = nil,  
  onboard        = nil,
  departures     =  {},
  destinations   =  {},
  departure      = nil,
  destination    = nil,
  commute        = nil,
  journey        = nil,
  takeoff        = nil,
  landing        = nil,
  flights        =  {},
  Nspawn         =   2,
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

--- Departure/destination type, i.e. airbase or zone.
-- @type RATCRAFT.DeType
-- @field #string AIRBASE Departure/destination is an airbase.
-- @field #string ZONE Departure/destination is a zone.
RATCRAFT.DeType={
  AIRBASE="Airbase",
  ZONE="Zone",
}

--- Departure/destination parameters.
-- @type RATCRAFT.Departure
-- @field #string name Name of the departure/destination airbase/zone.
-- @field #string type Type of the departure/destination, i.e. an airbase or a zone.
-- @field #table parking Number of parking spot IDs for the aircraft.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: helos
-- TODO: despawn when arrived
-- TODO: zones as departures
-- TODO: zones as destinations
-- TODO: monitor if stationary
-- TODO: commute
-- TODO: continue journey
-- TODO: return zone

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new RATCRAFT class object from a template group defined in the mission editor.
-- @param #RATCRAFT self
-- @param #string groupname Name of the **late activated** template group.
-- @param #number nspawn Number of groups to spawn. Default 1.
-- @param #string alias (Optional) Alias for the group name used as spawn name prefix. Default is the group name. 
-- @return #RATCRAFT self
function RATCRAFT:New(groupname, nspawn, alias)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) --#RATCRAFT
  
  -- Defaults
  self.Nspawn=nspawn or 1
  self.alias=alias or groupname
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Load",            "Stopped")     -- Load ratcraft from file.
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start RAT2 script.
  self:AddTransition("Running",       "Pause",           "Paused")      -- Pause spawning RATCRAFT.
  self:AddTransition("Paused",        "Unpause",         "Running")     -- UnPause spawning RATCRAFT.
  
  -- Initialize aircraft parameters.
  self:_Init(groupname)
  
  self:Start()
  
  return self
end

--- Init aircraft parameters.
-- @param #RATCRAFT self
-- @param #string groupname Name of the template group.
-- @return #RATCRAFT self
function RATCRAFT:_Init(groupname)

  self.templatename=groupname  
  self.templategroup=GROUP:FindByName(groupname)
  self.template=self.templategroup:GetTemplate()
  
  
  self.speedmax=self.templategroup:GetSpeedMax()
  self.range=1000000
  self.DCSdesc=self.templategroup:GetDCSDesc(1)
  
  self.coalition=self.templategroup:GetCoalition()
  self.country=self.templategroup:GetUnit(1):GetCountry()
  
  self.category=self.templategroup:GetUnit(1):GetCategory()

  -- aircraft dimensions
  self.sizex=self.DCSdesc.box.max.x
  self.sizey=self.DCSdesc.box.max.y
  self.sizez=self.DCSdesc.box.max.z
  self.size =math.max(self.sizex, self.sizez)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add adeparture airbase for the aircraft.
-- @param #RATCRAFT self
-- @param #string airbasename Departure airbase name.
-- @param #table parking (Optional) Table of parking spot IDs. At least the number of units in the group must be given.
-- @return #RATCRAFT self
function RATCRAFT:AddDepartureAirbase(airbasename, parking)

  local departure={} --#RATCRAFT.Departure
  
  local spots=nil
  if parking then
    if type(parking)=="number" then
      parking={parking}
    end
    
    -- Convert parking IDs to complete parking data.
    spots={}
    local airbase=AIRBASE:FindByName(airbasename)
    for _,TerminalID in pairs(parking) do
      local spot=airbase:GetParkingSpotData(TerminalID)
      if spot then
        table.insert(spots, spot)
      end
    end
  end
  
  departure.name=airbasename
  departure.type=RATCRAFT.DeType.AIRBASE
  departure.parking=parking  
  table.insert(self.departures, departure)
  
  return self
end

--- Add destination airbase for the aircraft and optionally specific parking spot IDs to be used by this group.
-- @param #RATCRAFT self
-- @param #string airbasename Destination airbase name.
-- @param #table parking (Optional) Table of parking spot IDs. At least the number of units in the group must be given.
-- @return #RATCRAFT self
function RATCRAFT:AddDestinationAirbase(airbasename, parking)

  local destination={} --#RATCRAFT.Departure  

  -- Convert parking IDs to complete parking data.
  local spots=nil
  if parking then
    if type(parking)=="number" then
      parking={parking}
    end
    
    spots={}
    local airbase=AIRBASE:FindByName(airbasename)
    for _,TerminalID in pairs(parking) do
      local spot=airbase:GetParkingSpotData(TerminalID)
      if spot then
        table.insert(spots, spot)
      end
    end
  end
    
  destination.name=airbasename
  destination.type=RATCRAFT.DeType.AIRBASE
  destination.parking=spots
  table.insert(self.destinations, destination)
    
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
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a departure for the aircraft.
-- @param #RATCRAFT self
function RATCRAFT:onafterStart()

  -- Create flight groups.
  for i=1,self.Nspawn do
  
    -- Group name.
    local groupname=string.format("%s-%02d", self.alias, i)
    
    -- New flight group.
    local flightgroup=FLIGHTGROUP:New(groupname)
    
    -- Add flight to tabloe.
    table.insert(self.flights, flightgroup)
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Departure Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get departure.
-- @param #RATCRAFT self
-- @return #RATCRAFT.Departure
-- @return #table Parking data table.
function RATCRAFT:GetDeparture()

  -- TODO: for commute/continue, set departure to current airbase/zone. Get same parking spot.

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
    
      -- Departure airbase.
      local airbase=AIRBASE:FindByName(departure.name)
      
      if airbase then
        
        -- Template group.
        local group=self.templategroup --Wrapper.Group#GROUP
        
        -- Get number of free parking spots.
        local parking=airbase:FindFreeParkingSpotForAircraft(group)
      
        -- Check if parking is sufficient.
        if #parking>=#group:GetUnits() then
          
          self:I(string.format("Returning departure %s", departure.name))
          return departure, parking
        
        else
        
          self:I(string.format("Removing departure %s", departure.name))
        
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

  if departure==nil then
    return nil
  end
  

  -- TODO: for commute, switch departure and destination.

  -- Create copy of all destinations.
  local destinations=UTILS.DeepCopy(self.destinations)
  
  -- Try each destination in random order.
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
      
      local depart=AIRBASE:FindByName(departure.name)
      
      if airbase then
        -- TODO: check
        -- coalition, terminal type, distance
        
        -- Distance between departure and destination.
        local distance=depart:GetCoordinate():Get2DDistance(airbase:GetCoordinate())
      
        if distance then
          
          self:I(string.format("Returning destination %s", destination.name))
          return destination
        
        else
        
          self:I(string.format("Removing destination %s", destination.name))
        
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
  local n=0
  
  for _,_flight in pairs(self.flights) do
    local flight=_flight --Ops.FlightGroup#FLIGHTGROUP
    
    if not flight:IsDead() then
      n=n+1
    end
  end


  return n
end