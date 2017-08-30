--- ** AI **
-- @module AI_RAT

--- Some ID to identify where we are
-- #string myid
myid="RAT | "

--- RAT class 
-- @type RAT
-- @field ClassName
-- @field #string prefix
-- @field #RAT
-- @extends #SPAWN
RAT={
  ClassName = "RAT",        -- Name of class: RAT = Random Air Traffic.
  debug=true,              -- Turn debug messages on or off.
  prefix=nil,               -- Prefix of the template group defined in the mission editor.
  spawndelay=5,             -- Delay time in seconds before first spawning happens.
  spawninterval=2,          -- Interval between spawning units/groups. Note that we add a randomization of 10%.
  coalition = nil,          -- Coalition of spawn group template.
  category = nil,           -- Category of aircarft: "plane" or "heli".
  friendly = "same",        -- Possible departure/destination airport: all=blue+red+neutral, same=spawn+neutral, spawnonly=spawn, blue=blue+neutral, blueonly=blue, red=red+neutral, redonly=red.
  ctable = {},              -- Table with the valid coalitons from choice self.friendly.
  aircraft = {},            -- Table which holds the basic aircraft properties (speed, range, ...).
  Vcruisemax=250,           -- Max cruise speed in m/s (250 m/s = 900 km/h = 486 kt).
  Vclimb=1500,              -- Default climb rate in ft/min.
  AlphaDescent=3.6,         -- Default angle of descenti in degrees. A value of 3.6 follows the 3:1 rule of 3 miles of travel and 1000 ft descent.
  roe = "hold",             -- ROE of spawned groups, default is weapon hold (this is a peaceful class for civil aircraft or ferry missions).
  takeoff = "hot",          -- Takeoff type: "hot", "cold", "runway", "air", "random".
  mindist = 5000,           -- Min distance from departure to destination in meters. Default 5 km.
  maxdist = 500000,         -- Max distance from departure to destination in meters. Default 5000 km.
  airports_map={},          -- All airports available on current map (Caucasus, Nevada, Normandy, ...).
  airports={},              -- All airports of friedly coalitions.
  airports_departure={},    -- Possible departure airports if unit/group is spawned at airport, spawnpoint=air or spawnpoint=airport.
  airports_destination={},  -- Possible destination airports if unit does not fly "overseas", destpoint=overseas or destpoint=airport.
  departure_name="random",  -- Name of the departure airport. Default is "random" for a randomly chosen one of the coalition airports.
  destination_name="random",-- Name of the destination airport. Default is "random" for a randomly chosen one of the coalition airports.
  random_departure=true,    -- By default a random friendly airport is chosen as departure.
  random_destination=true,  -- By default a random friendly airport is chosen as destination.
  departure_zones={},       -- Array containing the names of the departure zones. 
  departure_ports={},       -- Array containing the names of the destination zones.
  zones_departure={},       -- Departure zones for air start.
  Rzone=5000,               -- Radius of departure zones in meters.
  ratcraft={},              -- Array with the spawned RAT aircraft.
  markerid=0,
}

--- RAT categories.
-- @field #RAT cat
RAT.cat={
  plane="plane",
  heli="heli"
}

--TODO list:
--DONE: Add scheduled spawn.
--DONE: Add possibility to spawn in air.
--DONE: Add departure zones for air start.
--TODO: Make more functions to adjust/set RAT parameters.
--TODO: Clean up debug messages.
--DONE: Improve flight plan. Especially check FL against route length.
--DONE: Add event handlers.
--DONE: Respawn units when they have landed.
--DONE: Change ROE state.
--TODO: Make ROE state user function
--TODO: Improve status reports.
--TODO: Check compatibility with other #SPAWN functions.
--TODO: Add possibility to continue journey at destination. Need "place" in event data for that.
--TODO: Add enumerators and get rid off error prone string comparisons.
--DONE: Check that FARPS are not used as airbases for planes. Don't know if they appear in list of airports.
--DONE: Add cases for helicopters.

--- Creates a new RAT object.
-- @param #RAT self
-- @param #string prefix Prefix of the (template) group name defined in the mission editor.
-- @param #string friendly Friendly coalitions from which airports can be used.
-- "all"=neutral+red+blue, "same"=spawn coalition+neutral, "sameonly"=spawn coalition, "blue"=blue+neutral, "blueonly"=blue, "red"=red+neutral, "redonly"=red, "neutral"=neutral.
-- Default is "same", so aircraft will use airports of the coalition their spawn template has plus all neutral airports.  
-- @return #RAT self Object of RAT class.
-- @return #nil Nil if the group does not exists in the mission editor.
function RAT:New(prefix, friendly)

  -- Inherit SPAWN clase.
  local self=BASE:Inherit(self, SPAWN:New(prefix)) -- #RAT
  
  -- Set prefix.
  --TODO: Replace this by SpawnTemplatePrefix.
  self.prefix=prefix
  
  -- Set friendly coalitions. Default is "same", i.e. same coalition as template group plus neutrals.
  self.friendly = friendly or "same"

  -- Get template group defined in the mission editor.   
  local DCSgroup=Group.getByName(prefix)
  
  -- Check the group actually exists.
  if DCSgroup==nil then
    error("Group with name "..prefix.." does not exist in the mission editor!")
    return nil
  end

  -- Set own coalition.
  self.coalition=DCSgroup:getCoalition()
  
  -- Initialize aircraft parameters based on ME group template.
  self:_InitAircraft(DCSgroup)
  
  -- Get all airports of current map (Caucasus, NTTR, Normandy, ...).
  self:_GetAirportsOfMap()
  
  -- Set the coalition table based on choice of self.coalition and self.friendly.
  self:_SetCoalitionTable()
  
  -- Get all airports of this map beloning to friendly coalition(s).
  self:_GetAirportsOfCoalition()
   
  return self
end

--- Initialize basic parameters of the aircraft based on its (template) group in the mission editor.
-- @param #RAT self
-- @param Dcs.DCSWrapper.Group#Group DCSgroup Group of the aircraft in the mission editor.
function RAT:_InitAircraft(DCSgroup)

  local DCSunit=DCSgroup:getUnit(1)
  local DCSdesc=DCSunit:getDesc()
  local DCScategory=DCSgroup:getCategory()
  local DCStype=DCSunit:getTypeName()
 
  -- Ddescriptors table of unit.
  if self.debug then
    self:E({"DCSdesc", DCSdesc})
  end
  
  -- unit conversions
  local ft2meter=0.305
  local kmh2ms=0.278
  local FL2m=30.48
  local nm2km=1.852
  local nm2m=1852
  
  -- set category
  if DCScategory==Group.Category.AIRPLANE then
    self.category="plane"
  elseif DCScategory==Group.Category.HELICOPTER then
    self.category="heli"
  else
    self.category="other"
    error(myid.."Group of RAT is neither airplane nor helicopter!")
  end
  
  -- Define a first departure zone around the point where the group template in the ME was placed.
  local ZoneTemplate = ZONE_GROUP:New( "Template", GROUP:FindByName(self.prefix), self.Rzone)
  table.insert(self.zones_departure, ZoneTemplate)
  
  -- Get type of aircraft.
  self.aircraft.type=DCStype
  
  -- inital fuel in %
  self.aircraft.fuel=DCSunit:getFuel()

  -- operational range in NM converted to m
  self.aircraft.Rmax = DCSdesc.range*nm2m
  
  -- effective range taking fuel into accound and a 10% reserve
  self.aircraft.Reff = self.aircraft.Rmax*self.aircraft.fuel*0.9
  
  -- max airspeed from group
  self.aircraft.Vmax = DCSdesc.speedMax
  
  -- min cruise airspeed = 75% of max
  self.aircraft.Vmin = self.aircraft.Vmax*0.60
  
  -- actual travel speed (random between ASmin and ASmax)
  --TODO: This needs to be placed somewhere else! Randomization should not happen here. Otherwise it is not changed for multiple spawns.
  self.aircraft.Vcruise = math.random(self.aircraft.Vmin, self.aircraft.Vmax)
  
  -- Limit travel speed to ~900 km/h for jets.
  self.aircraft.Vcruise = math.min(self.aircraft.Vcruise, self.aircraft.Vmax)
    
  -- max climb speed in m/s
  self.aircraft.Vymax=DCSdesc.VyMax
  
  -- Reasonably civil climb speed Vy=1500 ft/min but max aircraft specific climb rate.
  self.aircraft.Vclimb=math.min(self.Vclimb*ft2meter/60, self.aircraft.Vymax)
  
  -- Climb angle in rad.
  self.aircraft.AlphaClimb=math.asin(self.aircraft.Vclimb/self.aircraft.Vmax)
  
  -- Descent angle in rad.
  self.aircraft.AlphaDescent=math.rad(self.AlphaDescent)
  
  -- service ceiling in meters
  self.aircraft.ceiling=DCSdesc.Hmax
  
  -- Default flight level (ASL).
  if self.category=="plane" then
    -- For planes: FL200 = 20000 ft = 6096 m.
    self.aircraft.FLcruise=200*FL2m
  else
    -- For helos: FL005 = 500 ft = 152 m.
    self.aircraft.FLcruise=005*FL2m
  end

  -- send debug message
  local text=string.format("Aircraft parameters:\n")
  text=text..string.format("Category         =   %s\n",       self.category)
  text=text..string.format("Max speed        = %6.1f m/s.\n", self.aircraft.Vmax)
  text=text..string.format("Max cruise speed = %6.1f m/s.\n", self.aircraft.Vcruise)
  text=text..string.format("Max climb speed  = %6.1f m/s.\n", self.aircraft.Vymax)
  text=text..string.format("Climb speed      = %6.1f m/s.\n", self.aircraft.Vclimb)
  text=text..string.format("Angle of climb   = %6.1f Deg.\n", math.deg(self.aircraft.AlphaClimb))
  text=text..string.format("Angle of descent = %6.1f Deg.\n", math.deg(self.aircraft.AlphaDescent))
  text=text..string.format("Initial Fuel     = %6.1f.\n",     self.aircraft.fuel*100)
  text=text..string.format("Max range = %6.1f km.\n",         self.aircraft.Rmax/1000)
  text=text..string.format("Eff range = %6.1f km.\n",         self.aircraft.Reff/1000)
  text=text..string.format("Ceiling   = FL%3.0f = %6.1f km.\n", self.aircraft.ceiling/FL2m, self.aircraft.ceiling/1000)
  text=text..string.format("FL cruise = FL%3.0f = %6.1f km.",   self.aircraft.FLcruise/FL2m, self.aircraft.FLcruise/1000)
  env.info(myid..text)
  if self.debug then
    MESSAGE:New(text, 60):ToAll()
  end

end


--- Spawn the AI aircraft.
-- @param #RAT self
-- @param #number naircraft (Optional) Number of aircraft to spawn. Default is one aircraft.
-- @param #string name (Optional) Name of the spawn group (for debugging only).
function RAT:Spawn(naircraft, name)

  -- Number of aircraft to spawn. Default is one.
  naircraft=naircraft or 1

  -- some of group for debugging
  --TODO: remove name from input parameter and make better unique RAT AI name
  name=name or "RAT AI "..self.aircraft.type

  -- debug message
  local text="Spawning "..naircraft.." aircraft of group "..self.prefix.." with name "..name.." of type "..self.aircraft.type..".\n"
  text=text.."Takeoff type: "..self.takeoff.."\n"
  text=text.."Friendly airports: "..self.friendly  
  env.info(myid..text)
  if self.debug then
    MESSAGE:New(text, 60, "Info"):ToAll()
  end
  
  -- Schedule spawning of aircraft.
  --TODO: make self.SpawnInterval and sef.spawndelay user input
  local Tstart=self.spawndelay
  local dt=self.spawninterval
  if self.takeoff:lower()=="takeoff-runway" or self.takeoff:lower()=="runway" then
    -- Ensure that interval is >= 180 seconds if spawn at runway is chosen. Aircraft need time to takeoff or the runway gets jammed.
    dt=math.max(dt, 180)
  end
  local Tstop=Tstart+dt*(naircraft-1)
  SCHEDULER:New(nil, self._SpawnWithRoute, {self}, Tstart, dt, 0.1, Tstop)
  
  -- Status report scheduler.
  SCHEDULER:New(nil, self.Status, {self}, 30, 30)
  
end


--- Spawn the AI aircraft with a route.
-- Sets the departure and destination airports and waypoints.
-- Modifies the spawn template.
-- Sets ROE/ROT.
-- Initializes the ratcraft array and event handlers.
-- @param #RAT self
function RAT:_SpawnWithRoute()

  -- Set flight plan.
  local departure, destination, waypoints = self:_SetRoute()
  
  -- Modify the spawn template to follow the flight plan.
  self:_ModifySpawnTemplate(waypoints) 
  
  -- Actually spawn the group.
  local group=self:SpawnWithIndex(self.SpawnIndex) -- Core.Group#GROUP
  
  -- set ROE to "weapon hold" and ROT to "no reaction"
  -- TODO: make user function to set this
  group:OptionROEReturnFire()
  --group:OptionROEHoldFire()
  group:OptionROTNoReaction()
  --group:OptionROTPassiveDefense()
  
  self.ratcraft[self.SpawnIndex]={}
  self.ratcraft[self.SpawnIndex]["group"]=group
  self.ratcraft[self.SpawnIndex]["destination"]=destination
  self.ratcraft[self.SpawnIndex]["departure"]=departure
  self.ratcraft[self.SpawnIndex]["status"]="spawned"
  
  -- Handle events.
  -- TODO: add hit event?
  self:HandleEvent(EVENTS.Birth,          self._OnBirthDay)
  self:HandleEvent(EVENTS.EngineStartup,  self._EngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self._OnTakeoff)
  self:HandleEvent(EVENTS.Land,           self._OnLand)
  self:HandleEvent(EVENTS.EngineShutdown, self._OnEngineShutdown)
  self:HandleEvent(EVENTS.Dead,           self._OnDead)
  -- TODO: Crash needs to be handled better. Does it always occur when dead?  
  --self:HandleEvent(EVENTS.Crash,          self._OnCrash)
end


--- Report status of RAT groups.
-- @param #RAT self
function RAT:Status()
  local ngroups=#self.SpawnGroups
  MESSAGE:New("Number of groups spawned = "..ngroups, 60):ToAll()
  for i=1, ngroups do
    local group=self.SpawnGroups[i].Group
    local prefix=self:_GetPrefixFromGroup(group)
    local life=self:_GetLife(group)
    local text=string.format("Group %s ID %i:\n", prefix, i) 
    text=text..string.format("Life = %3.0f\n", life)
    text=text..string.format("Status = %s\n", self.ratcraft[i].status)
    text=text..string.format("Flying from %s to %s.",self.ratcraft[i].departure:GetName(), self.ratcraft[i].destination:GetName())
    MESSAGE:New(text, 60):ToAll()
    env.info(myid..text)
  end
end

--- Get (relative) life of first unit of a group.
-- @param #RAT self
-- @param #Group group Group of unit.
-- @return #number Life of unit in percent.
function RAT:_GetLife(group)
  local life=0.0
  if group and group:IsAlive() then
    local unit=group:GetUnit(1)
    if unit then
      life=unit:GetLife()/unit:GetLife0()*100
    else
      error(myid.."Unit does not exists in RAT_Getlife(). Returning zero.")
    end
  else
    env.info(myid.."Group does not exists in RAT_Getlife(). Returning zero.")
  end
  return life
end

--- Set status of group.
-- @param #RAT self
function RAT:_SetStatus(group, status)
  local index=self:GetSpawnIndexFromGroup(group)
  env.info(myid.."Index for group "..group:GetName().." "..index.." status: "..status)
  self.ratcraft[index].status=status
end

--- Function is executed when a unit is spawned.
-- @param #RAT self
function RAT:_OnBirthDay(EventData)
  env.info(myid.."It's a birthday")
  local SpawnGroup = EventData.IniGroup
  if SpawnGroup then
    local index=self:GetSpawnIndexFromGroup(SpawnGroup)
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    local text="Event: Group "..SpawnGroup:GetName().." was born."
    env.info(myid..text)
    --MESSAGE:New(text, 180):ToAll()
    self:_SetStatus(SpawnGroup, "starting engines (born)")
  else
    error("Group does not exist in RAT:_EngineStartup().")
  end
end

--- Function is executed when a unit starts its engines.
-- @param #RAT self
function RAT:_EngineStartup(EventData)
  local SpawnGroup = EventData.IniGroup
  if SpawnGroup then
    local text="Event: Group "..SpawnGroup:GetName().." started engines. Life="..self:_GetLife(SpawnGroup)
    env.info(myid..text)
    --MESSAGE:New(text, 180):ToAll()
    local status
    if SpawnGroup:IsAir() then
      status="airborn"
    else
      status="taxi (engines started)"
    end
    self:_SetStatus(SpawnGroup, status)
  else
    error("Group does not exist in RAT:_EngineStartup().")
  end
end

--- Function is executed when a unit takes off.
-- @param #RAT self
function RAT:_OnTakeoff(EventData)
  local SpawnGroup = EventData.IniGroup
  if SpawnGroup then
    local text="Event: Group "..SpawnGroup:GetName().." took off. Life="..self:_GetLife(SpawnGroup)
    env.info(myid..text)
    --MESSAGE:New(text, 180):ToAll()
    self:_SetStatus(SpawnGroup, "airborn (took off)")
  else
    error("Group does not exist in RAT:_OnTakeoff().")
  end
end

--- Function is executed when a unit lands.
-- @param #RAT self
function RAT:_OnLand(EventData)
  local SpawnGroup = EventData.IniGroup
  if SpawnGroup then
    local text="Event: Group "..SpawnGroup:GetName().." landed. Life="..self:_GetLife(SpawnGroup)
    env.info(myid..text)
    --MESSAGE:New(text, 180):ToAll()
    self:_SetStatus(SpawnGroup, "landed")
    text="Event: Group "..SpawnGroup:GetName().." will be respawned."
    env.info(myid..text)
    --MESSAGE:New(text, 180):ToAll()
    self:_SpawnWithRoute()
  else
    error("Group does not exist in RAT:_OnLand().")
  end
end

--- Function is executed when a unit shuts down its engines.
-- @param #RAT self
function RAT:_OnEngineShutdown(EventData)
  local SpawnGroup = EventData.IniGroup
  if SpawnGroup then
    local text="Event: Group "..SpawnGroup:GetName().." shut down its engines. Life="..self:_GetLife(SpawnGroup)
    env.info(myid..text)
    --MESSAGE:New(text, 180):ToAll()
    self:_SetStatus(SpawnGroup, "arrived (engines shut down)")
    text="Event: Group "..SpawnGroup:GetName().." will be destroyed now."
    env.info(myid..text)
    --MESSAGE:New(text, 180):ToAll()
    SpawnGroup:Destroy()
  else
    error("Group does not exist in RAT:_OnEngineShutdown().")
  end
end

--- Function is executed when a unit is dead.
-- @param #RAT self
function RAT:_OnDead(EventData)
  local SpawnGroup = EventData.IniGroup
  if SpawnGroup then
    local text="Event: Group "..SpawnGroup:GetName().." was died. Life="..self:_GetLife(SpawnGroup)
    env.info(myid..text)
    self:_SetStatus(SpawnGroup, "dead (died)")
    --MESSAGE:New(text, 180):ToAll()
  else
    error("Group does not exist in RAT:_OnDead().")
  end
end

--- Function is executed when a unit crashes.
-- @param #RAT self
function RAT:_OnCrash(EventData)
  local SpawnGroup = EventData.IniGroup
  if SpawnGroup then
    local text="Event: Group "..SpawnGroup:GetName().." crashed. Life="..self:_GetLife(SpawnGroup)
    env.info(myid..text)
    --MESSAGE:New(text, 180):ToAll()
    self:_SetStatus(SpawnGroup, "crashed")
    --TODO: maybe spawn some people at the crash site and send a distress call. And define them as cargo which can be rescued.
  else
    error("Group does not exist in RAT:_OnCrash().")
  end
end


--- Set name of departure airport for the AI aircraft. If no name is given an airport from the coalition is chosen randomly.
-- @param #RAT self
-- @param #string name Name of the departure airport or "random" for a randomly chosen one of the coalition.
function RAT:SetDeparture(name)
  if name and AIRBASE:FindByName(name) then
    self.departure_name=name
  else
    self.departure_name="random"
  end
end

--- Set departure zones for spawning the AI aircraft.
-- @param #RAT self
-- @param #table zonenames Table of zone names where spawning should happen.
function RAT:SetDepartureZones(zonenames)
  self.zones_departure={}
  local z
  for _,name in pairs(zonenames) do
    if name:lower()=="zone template" then
      -- Zone with radius 5 km around the template group in the ME.
      z=ZONE_GROUP:New("Zone Template", GROUP:FindByName(self.prefix), self.Rzone)
    else
      -- Zone defined my user in the ME.
      z=ZONE:New(name)
    end
    if z then
      table.insert(self.zones_departure, z)
    else
      error(myid.."A zone with name "..name.." does not exist!")
    end
  end
end

--- Test if an airport exists on the current map.
-- @param #RAT self
-- @param #string name
-- @return #boolean True if airport exsits, false otherwise. 
function RAT:_AirportExists(name)
  for _,airport in pairs(self.airports_map) do
    if airport:GeName()==name then
      return true
    end
  end
  return false
end


--- Set possible departure ports. This can be an airport or a zone defined in the mission editor.
-- @param #RAT self
function RAT:SetDepartureAll(names)

  -- Random departure is deactivated now that user specified departure ports.
  self.random_departure=false
  
  if type(names)=="table" then
  
    -- we did get a table of names
    for _,name in pairs(names) do
    
      if self:_AirportExists(name) then
        -- If an airport with this name exists, we put it in the ports array.
        table.insert(self.departure_ports,"name")
      else
        -- If it is not an airport, we assume it is a zone.
        table.insert(self.departure_zones,"name")
      end
      
    end
    
  elseif type(names)=="string" then

      if self:_AirportExists("names") then
        -- If an airport with this name exists, we put it in the ports array.
        table.insert(self.departure_ports, "names")
      else
        -- If it is not an airport, we assume it is a zone.
        table.insert(self.departure_zones, "names")
      end
  
  else
    -- error message
    error("Input parameter must be a string or a table!")
  end
  
end

--- Set name of destination airport for the AI aircraft. If no name is given an airport from the coalition is chosen randomly.
-- @param #RAT self
-- @param #string name Name of the destination airport or "random" for a randomly chosen one of the coalition.
function RAT:SetDestination(name)
  if name and AIRBASE:FindByName(name) then
    self.destination_name=name
  else
    self.destination_name="random"
  end
end


--- Set the departure airport of the AI. If no airport name is given explicitly an airport from the coalition is chosen randomly.
-- If takeoff style is set to "air", we use zones around the airports or the zones specified by user input.
-- @param #RAT self
-- @return Wrapper.Airbase#AIRBASE Departure airport if spawning at airport.
function RAT:_SetDeparture()

  local departure
  
  -- Array containing possible departure airports or zones.
  local departures={}
  
  if self.takeoff=="air" then
  
    if self.random_departure then
    
      -- Air start above a random airport.
      for _,airport in pairs(self.airports)do
        table.insert(departures, airport:GetZone())
      end
    
    else
      
      -- Put all specified zones in table.
      for _,name in pairs(self.departure_zones) do
        table.insert(departures, ZONE:New(name))
      end
      -- Put all specified airport zones in table.
      for _,name in pairs(self.departure_zones) do
        table.insert(departures, AIRBASE:FindByName("name"):GetZone())
      end
      
    end
--[[ 
    if self.departure_name=="random" then
      departure=self.zones_departure[math.random(#self.zones_departure)]
    else
      departure=ZONE:FindByName(self.departure_name)
    end
    
    text="Chosen departure zone: "..departure:GetName()
]]
  else
  
    if self.random_departure then
    
      -- All friendly departure airports. 
      departures=self.airports
      
    else
        
      for _,name in pairs(self.departure_ports) do
        table.insert(departures, AIRBASE:FindByName(name))
      end
        
    end
  end
  
--[[  
    if self.departure_name=="random" then
      -- Get a random departure airport from all friendly coalition airports.
      departure=self.airports[math.random(#self.airports)]
    elseif AIRBASE:FindByName(self.departure_name) then
      -- Take the explicit airport provided.
      departure=AIRBASE:FindByName(self.departure_name)
    else
      -- If nothing else works, we randomly choose from friendly coalition airports.
      departure=self.airports[math.random(#self.airports)]
    end
    
    text="Chosen departure airport: "..departure:GetName().." with ID "..departure:GetID()
  end
]]

  -- Select departure airport or zone.
  local departure=departures[math.random(#departures)]
  
  local text
  if self.takeoff=="air" then
    text="Chosen departure zone: "..departure:GetName()
  else
    text="Chosen departure airport: "..departure:GetName().." (ID "..departure:GetID()..")"
  end
  env.info(myid..text)
  MESSAGE:New(text, 60):ToAll()
  
  return departure
end


--- Set the destination airport of the AI. If no airport name is given an airport from the coalition is chosen randomly.
-- @param #RAT self
-- @return Wrapper.Airbase#AIRBASE Destination airport.
function RAT:_SetDestination()
  local destination -- Wrapper.Airbase#AIRBASE
  if self.destination_name=="random" then
    -- Get random destination from all friendly airports within range.
    destination=self.airports_destination[math.random(1, #self.airports_destination)]
  elseif self.destination_name and AIRBASE:FindByName(self.destination_name) then
    -- Take the explicit airport provided.
    destination=AIRBASE:FindByName(self.destination_name)
  else
    -- If nothing else works, we randomly choose from frindly coalition airports.
    destination=self.airports_destination[math.random(1, #self.airports_destination)]
  end
  local text="Chosen destination airport: "..destination:GetName().." with ID "..destination:GetID()
  self:E(destination:GetDesc())
  env.info(myid..text)
  MESSAGE:New(text, 60):ToAll()
  return destination
end


--- Get all possible destination airports depending on departure position.
-- The list is sorted w.r.t. distance to departure position.
-- @param #RAT self
-- @param Core.Point#COORDINATE q Coordinate of the departure point.
-- @param #number minrange Minimum range to q in meters.
-- @param #number maxrange Maximum range to q in meters.
function RAT:_GetDestinations(q, minrange, maxrange)

  local absolutemin=5000             -- Absolute minimum is 5 km.
  minrange=minrange or absolutemin   -- Default min is absolute min.
  maxrange=maxrange or 10000000      -- Default max 10,000 km.
  
  -- Ensure that minrange is always > 10 km to ensure the destination != departure.
  minrange=math.max(absolutemin, minrange)
   
  -- loop over all friendly airports
  for _,airport in pairs(self.airports) do
    local p=airport:GetCoordinate()
    local distance=q:Get2DDistance(p)
    -- check if distance form departure to destination is within min/max range
    if distance>=minrange and distance<=maxrange then
      table.insert(self.airports_destination, airport)
    end
  end
  env.info(myid.."Number of possible destination airports = "..#self.airports_destination)
  
  if #self.airports_destination > 1 then
    --- Compare distance of destination airports.
    -- @param Core.Point#COORDINATE a Coordinate of point a.
    -- @param Core.Point#COORDINATE b Coordinate of point b.
    -- @return #list Table sorted by distance.
    local function compare(a,b)
      local qa=q:Get2DDistance(a:GetCoordinate())
      local qb=q:Get2DDistance(b:GetCoordinate())
      return qa < qb
    end
    table.sort(self.airports_destination, compare)
  end
  
end


--- Get all airports of the current map.
-- @param #RAT self
function RAT:_GetAirportsOfMap()
  local _coalition
  
  for i=0,2 do -- cycle coalition.side 0=NEUTRAL, 1=RED, 2=BLUE
  
    -- set coalition
    if i==0 then
      _coalition=coalition.side.NEUTRAL
    elseif i==1 then
      _coalition=coalition.side.RED
    elseif i==2 then
      _coalition=coalition.side.BLUE
    end
    
    -- get airbases of coalition
    local ab=coalition.getAirbases(i)
    
    -- loop over airbases and put them in a table
    for _,airbase in pairs(ab) do -- loop over airbases
      local _id=airbase:getID()
      local _p=airbase:getPosition().p
      local _name=airbase:getName()
      local _myab=AIRBASE:FindByName(_name)
      local text="Airport ID = ".._myab:GetID().." and Name = ".._myab:GetName()..", Category = ".._myab:GetCategory()..", TypeName = ".._myab:GetTypeName()
      env.info(myid..text)
      table.insert(self.airports_map, _myab)
    end
    
  end
end


--- Get all "friendly" airports of the current map.
-- @param #RAT self
function RAT:_GetAirportsOfCoalition()
  for _,coalition in pairs(self.ctable) do
    for _,airport in pairs(self.airports_map) do
      if airport:GetCoalition()==coalition then
        airport:GetTypeName()
        -- Remember that planes cannot land on FARPs.
        -- TODO: Probably have to add ships as well!
        if not (self.category=="plane" and airport:GetTypeName()=="FARP") then
          table.insert(self.airports, airport)
        end
      end
    end
  end
    
  if #self.airports==0 then
    local text="No possible departure/destination airports found!"
    MESSAGE:New(text, 180):ToAll()
    error(myid..text)
  end
end


--- Create a waypoint that can be used with the Route command.
-- @param #RAT self 
-- @param #string Type Type of waypoint. takeoff-cold, takeoff-hot, takeoff-runway, climb, cruise, descent, holding, land, landing.
-- @param Core.Point#COORDINATE Coord 3D coordinate of the waypoint.
-- @param #number Speed Speed in m/s.
-- @param #number Altitude Altitude in m.
-- @param Wrapper.Airbase#AIRBASE Airport Airport of object to spawn.
-- @return #table Waypoints for DCS task route or spawn template.
function RAT:Waypoint(Type, Coord, Speed, Altitude, Airport)

  -- Altitude of input parameter or y-component of 3D-coordinate.
  local _Altitude=Altitude or Coord.y
  
  --TODO: _Type should be generalized to Grouptemplate.Type
  --TODO: Only use _alttype="BARO" and add landheight for _alttype="RADIO". Don't know if "RADIO" really works well.
  
  -- Land height at given coordinate.
  local Hland=Coord:GetLandHeight()
  
  -- convert type and action in DCS format
  local _Type=nil
  local _Action=nil
  local _alttype="RADIO"
  local _AID=nil
  
  if Type:lower()=="takeoff-cold" or Type:lower()=="cold" then
    -- take-off with engine off
    _Type="TakeOffParking"
    _Action="From Parking Area"
    _Altitude = 2
    _alttype="RADIO"
    _AID = Airport:GetID()
  elseif Type:lower()=="takeoff-hot" or Type:lower()=="hot" then
    -- take-off with engine on 
    _Type="TakeOffParkingHot"
    _Action="From Parking Area"
    _Altitude = 2
    _alttype="RADIO"
    _AID = Airport:GetID()
  elseif Type:lower()=="takeoff-runway" or Type:lower()=="runway" then
    -- take-off from runway
    _Type="TakeOff"
    _Action="From Parking Area"  --TODO: Is this correct for a runway start?
    _Altitude = 2
    _alttype="RADIO"
    _AID = Airport:GetID()
  elseif Type:lower()=="air" then
    -- air start
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="BARO"
  elseif Type:lower()=="climb" or Type:lower()=="cruise" then
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="BARO"
  elseif Type:lower()=="descent" then
    _Type="Turning Point"
    _Action="Fly Over Point"
    _alttype="RADIO"
  elseif Type:lower()=="holding" then
    _Type="Turning Point"
    _Action="Fly Over Point"
    _alttype="RADIO"
  elseif Type:lower()=="landing" or Type:lower()=="land" then
    _Type="Land"
    _Action="Landing"
    _Altitude = 2
    _alttype="RADIO"
    _AID = Airport:GetID()
  else
    error("Unknown waypoint type in RAT:Waypoint function!")
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="RADIO"
  end
  
  -- some debug info about input parameters
  if self.debug then
    local at="unknown (oops!)"
    if _alttype=="BARO" then
      at="ASL"
    elseif _alttype=="RADIO" then
      at="AGL"
    end
    local text=string.format("\nType: %s.\n", Type)
    if _Action then
      text=text..string.format("Action: %s.\n", tostring(_Action))
    end
    text=text..string.format("Coord: x = %6.1f km, y = %6.1f km, alt = %6.1f m.\n", Coord.x/1000, Coord.z/1000, Coord.y)
    text=text..string.format("Speed = %6.1f m/s = %6.1f km/h = %6.1f knots.\n", Speed, Speed*3.6, Speed*1.94384)
    text=text..string.format("Altitude = %6.1f m "..at..".\n", _Altitude)
    if Airport then
      if Type:lower() == "air" then
        text=text..string.format("Zone = %s.", Airport:GetName())
      else
        text=text..string.format("Airport = %s with ID %i.", Airport:GetName(), Airport:GetID())
      end
    else
      text=text..string.format("No (valid) airport specified.")
    end
    local debugmessage=false
    if debugmessage then
      MESSAGE:New(text, 30, "RAT Waypoint Debug"):ToAll()
    end
    env.info(myid..text)
  end
  
  -- define waypoint
  local RoutePoint = {}
  -- coordinates and altitude
  RoutePoint.x = Coord.x
  RoutePoint.y = Coord.z
  RoutePoint.alt = _Altitude
  -- altitude type: BARO=ASL or RADIO=AGL
  RoutePoint.alt_type = _alttype
  -- type 
  RoutePoint.type = _Type or nil
  RoutePoint.action = _Action or nil
  -- speed in m/s
  RoutePoint.speed = Speed
  RoutePoint.speed_locked = true
  -- ETA (not used)
  --TODO: ETA check if this makes the DCS bug go away
  --RoutePoint.ETA=nil
  RoutePoint.ETA_locked=true
  -- waypoint name (only for the mission editor)
  RoutePoint.name="RAT waypoint"
  if _AID then
    RoutePoint.airdromeId=_AID
  end
  -- properties
  RoutePoint.properties = {
    ["vnav"]   = 1,
    ["scale"]  = 0,
    ["angle"]  = 0,
    ["vangle"] = 0,
    ["steer"]  = 2,
  }
  -- task
  if Type:lower()=="holding" then
    RoutePoint.task=self:_TaskHolding({x=Coord.x, y=Coord.z}, Altitude, Speed)
  else
    RoutePoint.task = {}
    RoutePoint.task.id = "ComboTask"
    RoutePoint.task.params = {}
    RoutePoint.task.params.tasks = {}
  end
  -- return the waypoint
  return RoutePoint
end


--- Set takeoff type. Starting cold at airport, starting hot at airport, starting at runway, starting in the air or randomly select one of the previous.
-- Default is "takeoff-hot" for a start at airport with engines already running.
-- @param #RAT self
-- @param #string type Type can be "takeoff-cold" or "cold", "takeoff-hot" or "hot", "takeoff-runway" or "runway", "air", "random".
function RAT:SetTakeoff(type)
  -- All possible types for random selection.
  local types={"takeoff-cold", "takeoff-hot", "takeoff-runway"}
  local _Type
  if type:lower()=="takeoff-cold" or type:lower()=="cold" then
  _Type="takeoff-cold"
  elseif type:lower()=="takeoff-hot" or type:lower()=="hot" then
    _Type="takeoff-hot"
  elseif type:lower()=="takeoff-runway" or type:lower()=="runway" then    
    _Type="takeoff-runway"
  elseif type:lower()=="air" then
    --TODO: not implemented yet
    _Type="air"
  elseif type:lower()=="random" then
    _Type=types[math.random(1, #types)]
  else
    _Type="takeoff-hot"
  end
  self.takeoff=_Type
end

--- Orbit at a specified position at a specified alititude with a specified speed.
-- @param #RAT self
-- @param Dcs.DCSTypes#Vec2 P1 The point to hold the position.
-- @param #number Altitude The altitude AGL to hold the position.
-- @param #number Speed The speed flying when holding the position in m/s.
-- @return Dcs.DCSTasking.Task#Task DCSTask
function RAT:_TaskHolding(P1, Altitude, Speed)
  local LandHeight = land.getHeight(P1)

  --TODO: Add duration of holding. Otherwise it will hold until fuel is emtpy.

  -- second point is 10 km north of P1
  --TODO: randomize P1
  local P2={}
  P2.x=P1.x
  P2.y=P1.y+10000
  local DCSTask = {
    id = 'Orbit',
    params = {
      pattern = AI.Task.OrbitPattern.RACE_TRACK,
      point = P1,
      point2 = P2,
      speed = Speed,
      altitude = Altitude + LandHeight
    }
  }
  
  return DCSTask
end


--- Provide information about the assigned flightplan.
-- @param #RAT self
-- @param #list waypoints Waypoints of the flight plan.
-- @param #string comment Some comment to identify the provided information.
-- @return #number total Total route length in meters.
function RAT:_Routeinfo(waypoints, comment)

  local text=""
  if comment then
    text=comment.."\n"
  end
  text=text..string.format("Number of waypoints = %i\n", #waypoints)
  -- info on coordinate and altitude
  for i=1,#waypoints do
    local p=waypoints[i]
    text=text..string.format("WP #%i: x = %6.1f km, y = %6.1f km, alt = %6.1f m\n", i-1, p.x/1000, p.y/1000, p.alt)
  end
  -- info on distance between waypoints
  local total=0.0
  for i=1,#waypoints-1 do
    local point1=waypoints[i]
    local point2=waypoints[i+1]
    local x1=point1.x
    local y1=point1.y
    local x2=point2.x
    local y2=point2.y
    local d=math.sqrt((x1-x2)^2 + (y1-y2)^2)
    local heading=self:_Course(point1, point2)
    total=total+d
    text=text..string.format("Distance from WP %i-->%i = %6.1f km. Heading = %i.\n", i-1, i, d/1000, heading)
  end
  text=text..string.format("Total distance = %6.1f km", total/1000)
  
  -- send message
  env.info(text)
  if self.debug then
    MESSAGE:New(text, 60):ToAll()
  end
  
  -- return total route length in meters
  return total
end


--- Set the route of the AI plane. Due to DCS landing bug, this has to be done before the unit is spawned.
-- @param #RAT self
-- @return Wrapper.Airport#AIRBASE Departure airbase.
-- @return Wrapper.Airport#AIRBASE Destination airbase.
-- @return #table Table of flight plan waypoints. 
function RAT:_SetRoute()

  -- unit conversions
  local ft2meter=0.305
  local kmh2ms=0.278
  local FL2m=30.48
  local nm2km=1.852

  -- DEPARTURE AIRPORT  
  -- Departure airport or zone.
  local departure=self:_SetDeparture()

  -- Coordinates of departure point.
  local Pdeparture
  if self.takeoff=="air" then
      -- For an air start, we take a random point within the spawn zone.
    local vec2=departure:GetRandomVec2()
    --Pdeparture=COORDINATE:New(vec2.x, self.aircraft.FLcruise, vec2.y)
    Pdeparture=COORDINATE:NewFromVec2(vec2) 
  else
    Pdeparture=departure:GetCoordinate()
  end
  
  -- Height ASL of departure point.
  local H_departure
  if self.takeoff=="air" then
    -- Departure altitude is 70% of default cruise with 30% variation and limited to 1000 m AGL (50 m for helos). 
    local Hmin
    if self.category=="plane" then
      Hmin=1000
    else
      Hmin=50
    end
    H_departure=self:_Randomize(self.aircraft.FLcruise*0.7, 0.3, Pdeparture.y+Hmin, self.aircraft.FLcruise)
  else
    H_departure=Pdeparture.y
  end
  
  -- DESTINATION AIRPORT
  -- Get all destination airports within reach and at least 10 km away from departure.
  self:_GetDestinations(Pdeparture, self.mindist, self.aircraft.Reff)
  
  -- Pick a destination airport.
  local destination=self:_SetDestination()
  
  -- Check that departure and destination are not the same. Should not happen due to mindist.
  if destination:GetName()==departure:GetName() then
    local text="Destination and departure airport are identical: "..destination:GetName().." with ID "..destination:GetID()
    MESSAGE:New(text, 120):ToAll()
    error(myid..text)
  end
  
  -- Coordinates of destination airport.
  local Pdestination=destination:GetCoordinate()
  -- Height ASL of destination airport.
  local H_destination=Pdestination.y
    
  -- DESCENT/HOLDING POINT
  -- Get a random point between 10 and 20 km away from the destination.
  local Vholding
  if self.category=="plane" then
    Vholding=destination:GetCoordinate():GetRandomVec2InRadius(20000, 10000)
  else
    -- For helos we set a distance between 500 to 1000 m.
    Vholding=destination:GetCoordinate():GetRandomVec2InRadius(1000, 500)
  end
  -- Coordinates of the holding point. y is the land height at that point.
  local Pholding=COORDINATE:NewFromVec2(Vholding)
  
  -- Holding point altitude. For planes between 800 and 1200 m AGL. For helos 80 to 120 m AGL.
  local h_holding
  if self.category=="plane" then
    h_holding=1000
  else
    h_holding=100
  end
  h_holding=self:_Randomize(h_holding, 0.2)
    
  -- Distance from holding point to destination.
  local d_holding=Pholding:Get2DDistance(Pdestination)
  
  -- GENERAL
  -- heading from departure to holding point of destination
  local heading=self:_Course(Pdeparture, Pholding) -- heading from departure to destination
  
  -- total distance between departure and holding point (+last bit to destination)
  local d_total=Pdeparture:Get2DDistance(Pholding)
  
  -- CLIMB and DESCENT angles
  -- TODO: Randomize climb/descent angles. This did not work in rad. Need to convert to deg first.
  local AlphaClimb=self.aircraft.AlphaClimb    --=self:_Randomize(self.aircraft.AlphaClimb, 0.1)
  local AlphaDescent=self.aircraft.AlphaDescent --self:_Randomize(self.aircraft.AlphaDescent, 0.1)
  
  --CRUISE  
  -- Set min/max cruise altitudes.
  local FLmax
  local FLmin
  local FLcruise=self.aircraft.FLcruise
  if self.category=="plane" then
    -- Min cruise alt is just above holding point at destination or departure height, whatever is larger.
    FLmin=math.max(H_departure, H_destination+h_holding)
    -- Check if the distance between the two airports is large enough to reach the desired FL and descent again at the given climb/descent rates.
    if self.takeoff=="air" then
      -- This is the case where we only descent to the ground at the given descent angle.
      -- TODO: should this not better be h_holding Pholding.y? 
      FLmax=d_total*math.tan(AlphaDescent)+H_destination
    else
      FLmax=self:_FLmax(AlphaClimb, AlphaDescent, d_total, H_departure)
    end
    -- If the route is very short we set FLmin a bit lower than FLmax.
    if FLmin>FLmax then
      FLmin=FLmax*0.8
    end
    -- Again, if the route is too short to climb and descent, we set the default cruise alt at bit lower than the max we can reach.
    if FLcruise>FLmax then
      FLcruise=FLmax*0.9
    end
  else
    -- For helicopters we take cruise alt between 50 to 1000 meters above ground. Default cruise alt is ~150 m.
    FLmin=math.max(H_departure, H_destination)+50
    FLmax=math.max(H_departure, H_destination)+1000
  end
  -- Set randomized cruise altitude: default +-50% but limited to FLmin and FLmax.
  FLcruise=self:_Randomize(FLcruise, 0.5, FLmin, FLmax)
  -- Finally, check that we are not above 90% of service ceiling.
  FLcruise=math.min(FLcruise, self.aircraft.ceiling*0.9)
  
  if self.takeoff=="air" then
    H_departure=math.min(H_departure,FLmax)
  end
    
  -- CLIMB
  -- Height of climb relative to ASL height of departure airport.
  local h_climb=FLcruise-H_departure
  -- x-distance of climb part 
  local d_climb=math.abs(h_climb/math.tan(AlphaClimb))
  -- time of climb in seconds
  local t_climb=h_climb/self.aircraft.Vclimb
  
  -- DESCENT
  -- Height difference for descent form cruise alt to holding point.
  local h_descent=FLcruise-h_holding-Pholding.y
  -- x-distance of descent part
  local d_descent=math.abs(h_descent/math.tan(AlphaDescent))
  
  -- CRUISE
  -- Distance of the cruising part. This should in principle not become negative, but can happen for very short legs.
  local d_cruise=d_total-d_climb-d_descent
  
  -- debug message
  local text=string.format("Route distances:\n")
  text=text..string.format("d_climb   = %6.1f km\n", d_climb/1000)
  text=text..string.format("d_cruise  = %6.1f km\n", d_cruise/1000)
  text=text..string.format("d_descent = %6.1f km\n", d_descent/1000)
  text=text..string.format("d_holding = %6.1f km\n", d_holding/1000)
  text=text..string.format("d_total   = %6.1f km\n", d_total/1000)
  text=text..string.format("Route heights:\n")
  text=text..string.format("H_departure   = %6.1f m ASL\n", H_departure)
  text=text..string.format("H_destination = %6.1f m ASL\n", H_destination)
  text=text..string.format("h_climb       = %6.1f m AGL\n", h_climb)
  text=text..string.format("h_descent     = %6.1f m\n",     h_descent)
  text=text..string.format("h_holding     = %6.1f m AGL\n", h_holding)
  text=text..string.format("P_holding alt = %6.1f m ASL\n", Pholding.y)
  text=text..string.format("Alpha_climb   = %6.1f Deg\n", math.deg(AlphaClimb))
  text=text..string.format("Alpha_descent = %6.1f Deg\n", math.deg(AlphaDescent))
  text=text..string.format("FLmin         = %6.1f m ASL\n", FLmin)
  text=text..string.format("FLmax         = %6.1f m ASL\n", FLmax)
  text=text..string.format("FLcruise      = %6.1f m ASL\n", FLcruise)
  text=text..string.format("Heading = %6.1f Degrees", heading)
  env.info(myid..text)
  if self.debug then
    MESSAGE:New(text, 60):ToAll()
  end
  
  -- Coordinates of route from departure (0) to cruise (1) to descent (2) to holing (3) to destination (4).
  local c0=Pdeparture
  local c1=c0:Translate(d_climb,   heading)
  local c2=c1:Translate(d_cruise,  heading)
  local c3=c2:Translate(d_descent, heading)
  local c3=Pholding
  local c4=Pdestination
  
  --Convert coordinates into route waypoints.
  local wp0=self:Waypoint(self.takeoff, c0, self.aircraft.Vmin, H_departure, departure)
  local wp1=self:Waypoint("climb",      c1, self.aircraft.Vmax, FLcruise)
  local wp2=self:Waypoint("cruise",     c2, self.aircraft.Vcruise, FLcruise)
  --TODO: add the possibility for a holing point, i.e. we circle a bit before final approach.
  --local wp3=self:Waypoint("descent",    c3, self.aircraft.Vmin, h_holding)
  local wp3=self:Waypoint("holding",    c3, self.aircraft.Vmin, h_holding)
  local wp4=self:Waypoint("landing",    c4, self.aircraft.Vmin, 2, destination)
  
   -- set waypoints
  local waypoints = {wp0, wp1, wp2, wp3, wp4}
  
  self:_SetMarker("Takeoff and begin of climb.", c0)
  self:_SetMarker("End of climb and begin of cruise",   c1)
  self:_SetMarker("End of Cruise and begin of descent",  c2)
  self:_SetMarker("Holding Point", c3)
  self:_SetMarker("Final Destination", c4)
  
  -- some info on the route as message
  self:_Routeinfo(waypoints, "Waypoint info in set_route:")
  
  -- return departure, destination and waypoints
  return departure, destination, waypoints
  
end

--- Calculate the max flight level for a given distance and fixed climb and descent rates.
-- In other words we have a distance between two airports and want to know how high we
-- can climb before we must descent again to arrive at the destination without any level/cruising part.
-- @param #RAT self
-- @param #number alpha Angle of climb [rad].
-- @param #number beta Angle of descent [rad].
-- @param #number d Distance between the two airports [m].
-- @param #number h0 Height [m] of departure airport. Note we implicitly assume that the height difference between departure and destination is negligible.
-- @return #number  Maximal flight level in meters.
function RAT:_FLmax(alpha, beta, d, h0)
-- Solve ASA triangle for one side (d) and two adjacent angles (alpha, beta) given.
  local gamma=math.rad(180)-alpha-beta
  local a=d*math.sin(alpha)/math.sin(gamma)
  local b=d*math.sin(beta)/math.sin(gamma)
  local h1=b*math.sin(alpha)
  local h2=a*math.sin(beta)
  local FL2m=30.48
  -- h1 and h2 should be equal.
  local text=string.format("FLmax = FL%3.0f = %6.1f m.\n", h1/FL2m, h1)
  text=text..string.format("FLmax = FL%3.0f = %6.1f m.",   h2/FL2m, h2)
  env.info(myid..text)
  return b*math.sin(alpha)+h0
end


--- Modifies the template of the group to be spawned.
-- In particular, the waypoints of the group's flight plan are copied into the spawn template.
-- This allows to spawn at airports and also land at other airports, i.e. circumventing the DCS "landing bug".
-- @param #RAT self
-- @param #table waypoints The waypoints of the AI flight plan.
function RAT:_ModifySpawnTemplate(waypoints)

  -- The 3D vector of the first waypoint, i.e. where we actually spawn the template group.
  local PointVec3 = {x=waypoints[1].x, y=waypoints[1].alt, z=waypoints[1].y}
  
  -- Heading from first to seconds waypoints
  local heading = self:_Course(waypoints[1], waypoints[2])
  env.info(myid.."Heading wp1->wp2: ", heading)

  if self:_GetSpawnIndex(self.SpawnIndex+1) then
  
    -- Get copy of spawn template.
    local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
  
    if SpawnTemplate then
      self:E(SpawnTemplate)

      -- Translate the position of the Group Template to the Vec3.
      for UnitID = 1, #SpawnTemplate.units do
        self:T('Before Translation SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
        local UnitTemplate = SpawnTemplate.units[UnitID]
        local SX = UnitTemplate.x
        local SY = UnitTemplate.y 
        local BX = SpawnTemplate.route.points[1].x
        local BY = SpawnTemplate.route.points[1].y
        local TX = PointVec3.x + (SX-BX)
        local TY = PointVec3.z + (SY-BY)
        SpawnTemplate.units[UnitID].x   = TX
        SpawnTemplate.units[UnitID].y   = TY
        SpawnTemplate.units[UnitID].alt = PointVec3.y
        SpawnTemplate.units[UnitID].heading = heading
        self:T('After Translation SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
      end
      
      -- Copy waypoints into spawntemplate. By this we avoid the nasty DCS "landing bug" :)
      for i,wp in ipairs(waypoints) do
        SpawnTemplate.route.points[i]=wp
      end
      
      -- Also modify x,y of the template. Not sure why.
      SpawnTemplate.x = PointVec3.x
      SpawnTemplate.y = PointVec3.z
      SpawnTemplate.heading = heading
      
      -- Update modified template for spawn group.
      self.SpawnGroups[self.SpawnIndex].SpawnTemplate=SpawnTemplate
      
      self:E(SpawnTemplate)        
    end
  end
end


--- Create a table with the valid coalitions for departure and destination airports.
-- @param #RAT self
function RAT:_SetCoalitionTable()
  -- get all possible departures/destinations depending on coalition
  if self.friendly=="all" then
    self.ctable={coalition.side.BLUE, coalition.side.RED, coalition.side.NEUTRAL}
  elseif self.friendly=="blue" then
    self.ctable={coalition.side.BLUE, coalition.side.NEUTRAL}
  elseif self.friendly=="blueonly" then
    self.ctable={coalition.side.BLUE}
  elseif self.friendly=="red" then
    self.ctable={coalition.side.RED, coalition.side.NEUTRAL}
  elseif self.friendly=="redonly" then
    self.ctable={coalition.side.RED}
  elseif self.friendly=="neutral" then
    self.ctable={coalition.side.NEUTRAL}
  elseif self.friendly=="same" then
    self.ctable={self.coalition, coalition.side.NEUTRAL}
  elseif self.friendly=="sameonly" then
    self.ctable={self.coalition}
  else
    self.ctable={self.coalition, coalition.side.NEUTRAL}
  end
  -- debug info
  self:T({"Coalition table: ", self.ctable})
end


--- Convert 3D waypoint to 3D coordinate. x==>x, alt==>y, y==>z
-- @param #RAT self
-- @param #table wp Containing .x, .y and .alt
-- @return Core.Point#COORDINATE Coordinates of the waypoint.
function RAT:_WP2COORD(wp)
  local _coord = COORDINATE:New(wp.x, wp.alt, wp.y) -- Core.Point#COORDINATE
  return _coord
end


---Determine the heading from point a to point b.
--@param #RAT self
--@param Core.Point#COORDINATE a Point from.
--@param Core.Point#COORDINATE b Point to.
--@return #number Heading/angle in degrees. 
function RAT:_Course(a,b)
  local dx = b.x-a.x
  -- take the right value for y-coordinate (if we have "alt" then "y" if not "z")
  local ay
  if a.alt then
    ay=a.y
  else
    ay=a.z
  end
  local by
  if b.alt then
    by=b.y
  else
    by=b.z
  end
  local dy = by-ay
  local angle = math.deg(math.atan2(dy,dx))
  if angle < 0 then
    angle = 360 + angle
  end
  return angle
end


--- Randomize a value by a certain amount.
-- @param #RAT self
-- @param #number value The value which should be randomized
-- @param #number fac Randomization factor.
-- @param #number lower (Optional) Lower limit of the returned value.
-- @param #number upper (Optional) Upper limit of the returned value.
-- @return #number Randomized value.
-- @usage _Randomize(100, 0.1) returns a value between 90 and 110, i.e. a plus/minus ten percent variation.
-- @usage _Randomize(100, 0.5, nil, 120) returns a value between 50 and 120, i.e. a plus/minus fivty percent variation with upper bound 120.
function RAT:_Randomize(value, fac, lower, upper)
  local min
  if lower then
    min=math.max(value-value*fac, lower)
  else
    min=value-value*fac
  end
  local max
  if upper then
    max=math.min(value+value*fac, upper)
  else
    max=value+value*fac
  end
  
  local r=math.random(min, max)
  local text=string.format("Random: value = %6.2f, fac = %4.2f, min = %6.2f, max = %6.2f, r = %6.2f", value, fac, min, max, r)
  env.info(myid..text)
  --local r=math.random(value-value*fac,value+value*fac)
--  if upper and r>upper then
--    r=upper
--  end
--  if lower and r<lower then
--    r=lower
--  end
  return r
end

--- Set a marker for all on the F10 map.
-- @param #RAT self
-- @param #number id Index of marker.
-- @param #string text Text of maker.
-- @param #vec3 vec3 Position of marker.
function RAT:_SetMarker(text, vec3)
  self.markerid=self.markerid+1
  env.info(myid.."Placing marker with ID "..self.markerid.." and text "..text)
  trigger.action.markToAll(self.markerid, text, vec3)
end

--[[
--- @type RATPORT
-- @extends Wrapper.Positionable#POSITIONABLE

--- #RATPORT class, extends @{Positionable#POSITIONABLE}
-- @field #RATPORT RATPORT
RATPORT={
  ClassName="RATPORT",
}

--- Creates a new RATPORT object.
-- @param #RATPORT self
-- @param #string name Name of airport or zone.
-- @return #RATPORT self
function RATPORT:New(name)
  local self = BASE:Inherit(self, POSITIONABLE:New(name)) -- #RATPORT
  return self
end

--function RATCRAFT:New(name)
--  local self = BASE:Inherit(self, GROUP:New(name))
--end
]]