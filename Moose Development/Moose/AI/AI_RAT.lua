-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- ** AI **
-- @module AI_RAT

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Some ID to identify where we are
-- #string myid
myid="RAT | "

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- RAT class 
-- @type RAT
-- @field #string ClassName
-- @field #boolean debug
-- @field #string templatename
-- @field #number spawndelay
-- @field #number spawninterval
-- @field #number coalition
-- @field #string category
-- @field #string friendly
-- @field #table ctable
-- @field #table aircraft
-- @field #number Vcruisemax
-- @field #number Vclimb
-- @field #number AlphaDescent
-- @field #string roe
-- @field #string rot
-- @field #string takeoff
-- @field #number mindist
-- @field #number maxdist
-- @field #table airports_map
-- @field #table airports
-- @field #table airports_destination
-- @field #boolean random_departure
-- @field #boolean random_destination
-- @field #table departure_zones
-- @field #table departure_ports
-- @field #table destination_ports
-- @field #table ratcraft
-- @field #boolean reportstatus
-- @field #number statusinterval
-- @field #boolean placemarkers
-- @field #number FLuser
-- @field #number Vuser
-- @field #table RAT
-- @extends Functional.Spawn#SPAWN


--- RAT class
-- @field #RAT RAT
RAT={
  ClassName = "RAT",        -- Name of class: RAT = Random Air Traffic.
  debug=false,              -- Turn debug messages on or off.
  templatename=nil,         -- Name of the template group defined in the mission editor.
  spawndelay=1,             -- Delay time in seconds before first spawning happens.
  spawninterval=2,          -- Interval between spawning units/groups. Note that we add a randomization of 10%.
  coalition = nil,          -- Coalition of spawn group template.
  category = nil,           -- Category of aircarft: "plane" or "heli".
  friendly = "same",        -- Possible departure/destination airport: all=blue+red+neutral, same=spawn+neutral, spawnonly=spawn, blue=blue+neutral, blueonly=blue, red=red+neutral, redonly=red.
  ctable = {},              -- Table with the valid coalitons from choice self.friendly.
  aircraft = {},            -- Table which holds the basic aircraft properties (speed, range, ...).
  Vcruisemax=250,           -- Max cruise speed in m/s (250 m/s = 900 km/h = 486 kt).
  Vclimb=1500,              -- Default climb rate in ft/min.
  AlphaDescent=3.6,         -- Default angle of descenti in degrees. A value of 3.6 follows the 3:1 rule of 3 miles of travel and 1000 ft descent.
  roe = "hold",             -- ROE of spawned groups, default is weapon hold (this is a peaceful class for civil aircraft or ferry missions). Possible: "hold", "return", "free".
  rot = "noreaction",       -- ROT of spawned groups, default is no reaction. Possible: "noreaction", "passive", "evade".
  takeoff = "hot",          -- Takeoff type: "hot", "cold", "runway", "air", "random".
  mindist = 5000,           -- Min distance from departure to destination in meters. Default 5 km.
  maxdist = 500000,         -- Max distance from departure to destination in meters. Default 5000 km.
  airports_map={},          -- All airports available on current map (Caucasus, Nevada, Normandy, ...).
  airports={},              -- All airports of friedly coalitions.
  airports_destination={},  -- Possible destination airports which are in range of the chosen departure airport/zone.
  random_departure=true,    -- By default a random friendly airport is chosen as departure.
  random_destination=true,  -- By default a random friendly airport is chosen as destination.
  departure_zones={},       -- Array containing the names of the departure zones.
  departure_ports={},       -- Array containing the names of the departure airports.
  destination_ports={},     -- Array containing the names of the destination airports.
  ratcraft={},              -- Array with the spawned RAT aircraft.
  reportstatus=false,       -- Aircraft report status.
  statusinterval=30,        -- Intervall between status reports.
  placemarkers=false,       -- Place markers of waypoints on F10 map.
  FLuser=nil,               -- Flight level set by users explicitly.
  Vuser=nil,                -- Cruising speed set by user explicitly.
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- RAT categories.
-- @field #RAT cat
RAT.cat={
  plane="plane",
  heli="heli"
}

--- RAT unit conversions.
-- @field #RAT unit
-- @field #number ft2meter
RAT.unit={
  ft2meter=0.305,
  kmh2ms=0.278,
  FL2m=30.48,
  nm2km=1.852,
  nm2m=1852,
}

--- Running number of placed markers on the F10 map.
-- @field #RAT markerid
RAT.markerid=0

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--TODO list:
--DONE: Add scheduled spawn.
--DONE: Add possibility to spawn in air.
--DONE: Add departure zones for air start.
--DONE: Make more functions to adjust/set RAT parameters.
--DONE: Clean up debug messages.
--DONE: Improve flight plan. Especially check FL against route length.
--DONE: Add event handlers.
--DONE: Respawn units when they have landed.
--DONE: Change ROE state.
--DONE: Make ROE state user function
--TODO: Improve status reports.
--TODO: Check compatibility with other #SPAWN functions.
--TODO: Add possibility to continue journey at destination. Need "place" in event data for that.
--TODO: Add enumerators and get rid off error prone string comparisons.
--DONE: Check that FARPS are not used as airbases for planes.
--DONE: Add special cases for ships (similar to FARPs).
--DONE: Add cases for helicopters.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new RAT object.
-- @param #RAT self
-- @param #string groupname Name of the group as defined in the mission editor. This group is serving as a template for all spawned units.
-- @return #RAT Object of RAT class.
-- @return #nil Nil if the group does not exists in the mission editor.
-- @usage yak:RAT("RAT_YAK") will create a RAT object called "yak". The template group in the mission editor must have the name "RAT_YAK".
-- By default aircraft will spawn at neutral and red airports if the template group is part of the red coaliton.
function RAT:New(groupname)

  -- Inherit SPAWN clase.
  local self=BASE:Inherit(self, SPAWN:New(groupname)) -- #RAT
  
  -- Set template name.
  self.templatename=groupname
  
  -- Get template group defined in the mission editor.   
  local DCSgroup=Group.getByName(groupname)
  
  -- Check the group actually exists.
  if DCSgroup==nil then
    env.error("Group with name "..groupname.." does not exist in the mission editor!")
    return nil
  end

  -- Set own coalition.
  self.coalition=DCSgroup:getCoalition()
  
  -- Initialize aircraft parameters based on ME group template.
  self:_InitAircraft(DCSgroup)
  
  -- Get all airports of current map (Caucasus, NTTR, Normandy, ...).
  self:_GetAirportsOfMap()
   
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Spawn the AI aircraft.
-- @param #RAT self
-- @param #number naircraft (Optional) Number of aircraft to spawn. Default is one aircraft.
function RAT:Spawn(naircraft)

  -- Number of aircraft to spawn. Default is one.
  naircraft=naircraft or 1
  
    -- Set the coalition table based on choice of self.coalition and self.friendly.
  self:_SetCoalitionTable()
  
  -- Get all airports of this map beloning to friendly coalition(s).
  self:_GetAirportsOfCoalition()

  -- debug message
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Spawning %i aircraft from template %s of type %s.\n", naircraft, self.templatename, self.aircraft.type)
  text=text..string.format("Takeoff type: %s\n", self.takeoff)
  text=text..string.format("Friendly coalitions: %s\n", self.friendly)
  text=text..string.format("Number of friendly airports: %i\n", #self.airports)
  text=text..string.format("******************************************************\n")
  env.info(myid..text)
  
  -- Schedule spawning of aircraft.
  local Tstart=self.spawndelay
  local dt=self.spawninterval
  -- Ensure that interval is >= 180 seconds if spawn at runway is chosen. Aircraft need time to takeoff or the runway gets jammed.
  if self.takeoff:lower()=="takeoff-runway" or self.takeoff:lower()=="runway" then
    dt=math.max(dt, 180)
  end
  local Tstop=Tstart+dt*(naircraft-1)
  SCHEDULER:New(nil, self._SpawnWithRoute, {self}, Tstart, dt, 0.1, Tstop)
  
  -- Status report scheduler.
  if self.reportstatus then
    SCHEDULER:New(nil, self.Status, {self}, self.statusinterval, 30)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the friendly coalitions from which the airports can be used as departure or destination.
-- @param #RAT self
-- @param #string friendly Possible choices:
-- "all"=neutral+red+blue, "same"=spawn coalition+neutral, "sameonly"=spawn coalition, "blue"=blue+neutral, "blueonly"=blue, "red"=red+neutral, "redonly"=red, "neutral"=neutral.
-- Default is "same", so aircraft will use airports of the coalition their spawn template has plus all neutral airports.
-- @usage yak:SetCoalition("all") will spawn aircraft randomly on airports of any coaliton, i.e. red, blue and neutral.
-- @usage yak:SetCoalition("redonly")  will spawn aircraft randomly on airports belonging to the red coalition only.
function RAT:SetCoalition(friendly)
  self.friendly=friendly
end

--- Set takeoff type. Starting cold at airport, starting hot at airport, starting at runway, starting in the air or randomly select one of the previous.
-- Default is "takeoff-hot" for a start at airport with engines already running.
-- @param #RAT self
-- @param #string type Type can be "takeoff-cold" or "cold", "takeoff-hot" or "hot", "takeoff-runway" or "runway", "air", "random".
-- @usage RAT:Takeoff("hot") will spawn RAT objects at airports with engines started.
-- @usage RAT:Takeoff("cold") will spawn RAT objects at airports with engines off.
-- @usage RAT:Takeoff("air") will spawn RAT objects in air over random airports or within pre-defined zones. 
function RAT:SetTakeoff(type)

  -- All possible types for random selection.
  local types={"takeoff-cold", "takeoff-hot", "air"}
  
  local _Type
  if type:lower()=="takeoff-cold" or type:lower()=="cold" then
  _Type="takeoff-cold"
  elseif type:lower()=="takeoff-hot" or type:lower()=="hot" then
    _Type="takeoff-hot"
  elseif type:lower()=="takeoff-runway" or type:lower()=="runway" then    
    _Type="takeoff-runway"
  elseif type:lower()=="air" then
    _Type="air"
  elseif type:lower()=="random" then
    _Type=types[math.random(#types)]
  else
    _Type="takeoff-hot"
  end
  
  self.takeoff=_Type
end

--- Set possible departure ports. This can be an airport or a zone defined in the mission editor.
-- @param #RAT self
-- @param #string names Name or table of names of departure airports or zones.
-- @usage RAT:SetDeparture("Sochi-Adler") will spawn RAT objects at Sochi-Adler airport.
-- @usage RAT:SetDeparture({"Sochi-Adler", "Gudauta"}) will spawn RAT aircraft radomly at Sochi-Adler or Gudauta airport.
-- @usage RAT:SetDeparture({"Zone A", "Gudauta"}) will spawn RAT aircraft in air randomly within Zone A, which has to be defined in the mission editor, or within a zone around Gudauta airport. Note that this also requires RAT:takeoff("air") to be set.
function RAT:SetDeparture(names)
  self:E({"SetDeparture Names", names})

  -- Random departure is deactivated now that user specified departure ports.
  self.random_departure=false
  
  if type(names)=="table" then
  
    -- we did get a table of names
    for _,name in pairs(names) do
    
      if self:_AirportExists(name) then
        -- If an airport with this name exists, we put it in the ports array.
        table.insert(self.departure_ports, name)
      else
        -- If it is not an airport, we assume it is a zone.
        table.insert(self.departure_zones, name)
      end
      
    end
    
  elseif type(names)=="string" then

      if self:_AirportExists(names) then
        -- If an airport with this name exists, we put it in the ports array.
        table.insert(self.departure_ports, names)
      else
        -- If it is not an airport, we assume it is a zone.
        table.insert(self.departure_zones, names)
      end
  
  else
    -- error message
    env.error("Input parameter must be a string or a table!")
  end
  
end

--- Set name of destination airport for the AI aircraft. If no name is given an airport from the coalition is chosen randomly.
-- @param #RAT self
-- @param #string names Name of the destination airport or table of destination airports.
function RAT:SetDestination(names)

  -- Random departure is deactivated now that user specified departure ports.
  self.random_destination=false
  
  if type(names)=="table" then
  
    for _,name in pairs(names) do
      table.insert(self.destination_ports, name)    
    end
  
  elseif type(names)=="string" then
  
    self.destination_ports={names}
  
  else
    -- Error message.
    env.error("Input parameter must be a string or a table!")
  end

end

--- Set the delay before first group is spawned. Minimum delay is 0.5 seconds.
-- @param #RAT self
-- @param #number delay Delay in seconds.
function RAT:SetSpawnDelay(delay)
  self.spawndelay=math.max(0.5, delay)
end

--- Set the interval between spawnings of the template group. Minimum interval is 0.5 seconds.
-- @param #RAT self
-- @param #number interval Interval in seconds.
function RAT:SetSpawnInterval(interval)
  self.spawninterval=math.max(0.5, interval)
end

--- Set the maximum cruise speed of the aircraft.
-- @param #RAT self
-- @param #number speed Speed in km/h.
function RAT:SetMaxCruiseSpeed(speed)
  self.Vcruisemax=speed/3.6
end

--- Set the climb rate. Default is 1500 ft/min. This automatically sets the climb angle.
-- @param #RAT self
-- @param #number rate Climb rate in ft/min.
function RAT:SetClimbRate(rate)

  -- Convert from ft/min to m/s.
  self.Vclimb=rate*RAT.unit.ft2m/60
  
  -- Climb rate in m/s. Max is aircraft specific.
  self.aircraft.Vclimb=math.min(self.Vclimb, self.aircraft.Vymax)
  
  -- Climb angle in rad.
  self.aircraft.AlphaClimb=math.asin(self.aircraft.Vclimb/self.aircraft.Vmax)
end

--- Set the angle of descent. Default is 3.6 degrees, which corresponds to 3000 ft descent after one mile of travel.
-- @param #RAT self
-- @param #number angle Angle of descent in degrees.
function RAT:SetDescentAngle(angle)
  -- Convert to rad.
  self.aircraft.AlphaDescent=math.rad(angle)
end

--- Set rules of engagement (ROE). Default is weapon hold. This is a peaceful class.
-- @param #RAT self
-- @param #string roe "hold" = weapon hold, "return" = return fire, "free" = weapons free.
function RAT:SetROE(roe)
  if roe=="hold" or roe=="return" or roe=="free" then
    self.roe=roe
  else
    self.roe="hold"
  end
end

--- Set reaction to threat (ROT). Default is no reaction, i.e. aircraft will simply ignore all enemies.
-- @param #RAT self
-- @param #string rot "noreaction = no reactino, "passive" = passive defence, "evade" = weapons free.
function RAT:SetROT(rot)
  if rot=="noreaction" or rot=="passive" or rot=="evade" then
    self.rot=rot
  else
    self.rot="noreaction"
  end
end

--- Set minimum distance between departure and destination. Default is 5 km.
-- Minimum distance should not be smaller than ~500(?) meters to ensure that departure and destination are different.
-- @param #RAT self
-- @param #number dist Distance in km.
function RAT:SetMinDistance(dist)
  -- Distance in meters. Absolute minimum is 500 m.
  self.mindist=math.max(500, dist*1000)
end

--- Set maximum distance between departure and destination. Default is 5000 km but aircarft range is also taken into account automatically.
-- @param #RAT self
-- @param #number dist Distance in km.
function RAT:SetMaxDistance(dist)
  -- Distance in meters.
  self.maxdist=dist*1000
end

--- Turn debug messages on or off. Default is off.
-- @param #RAT self
-- @param #boolean switch true turn messages on, false=off.
function RAT:_Debug(switch)
  switch = switch or true
  self.debug=switch
end

--- Aircraft report status messages. Default is off.
-- @param #RAT self
-- @param #boolean switch true=on, false=off.
function RAT:StatusReports(switch)
  switch = switch or true
  self.reportstatus=switch
end

--- Place markers of waypoints on the F10 map. Default is off.
-- @param #RAT self
-- @param #boolean switch true=yes, false=no.
function RAT:PlaceMarkers(switch)
  switch = switch or true
  self.placemarkers=switch
end

--- Set flight level. Setting this value will overrule all other logic. Aircraft will try to fly at this height regardless.
-- @param #RAT self
-- @param #number height FL in hundrets of feet. E.g. FL200 = 20000 ft ASL.
function RAT:SetFL(height)
  self.FLuser=height*RAT.unit.FL2m
end

--- Set flight level of cruising part. This is still be checked for consitancy with selected route and prone to radomization.
-- Default is FL200 for planes and FL005 for helicopters.
-- @param #RAT self
-- @param #number height FL in hundrets of feet. E.g. FL200 = 20000 ft ASL.
function RAT:SetFLcruise(height)
  self.aircraft.FLcruise=height*RAT.unit.FL2m
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
  
  -- set category
  if DCScategory==Group.Category.AIRPLANE then
    self.category="plane"
  elseif DCScategory==Group.Category.HELICOPTER then
    self.category="heli"
  else
    self.category="other"
    env.error(myid.."Group of RAT is neither airplane nor helicopter!")
  end
  
  -- Get type of aircraft.
  self.aircraft.type=DCStype
  
  -- inital fuel in %
  self.aircraft.fuel=DCSunit:getFuel()

  -- operational range in NM converted to m
  self.aircraft.Rmax = DCSdesc.range*RAT.unit.nm2m
  
  -- effective range taking fuel into accound and a 10% reserve
  self.aircraft.Reff = self.aircraft.Rmax*self.aircraft.fuel*0.9
  
  -- max airspeed from group
  self.aircraft.Vmax = DCSdesc.speedMax
      
  -- max climb speed in m/s
  self.aircraft.Vymax=DCSdesc.VyMax
    
  -- service ceiling in meters
  self.aircraft.ceiling=DCSdesc.Hmax
  
      -- Default flight level (ASL).
  if self.category=="plane" then
    -- For planes: FL200 = 20000 ft = 6096 m.
    self.aircraft.FLcruise=200*RAT.unit.FL2m
  else
    -- For helos: FL005 = 500 ft = 152 m.
    self.aircraft.FLcruise=005*RAT.unit.FL2m
  end
  
  -- send debug message
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Aircraft parameters:\n")
  text=text..string.format("Category        =  %s\n",       self.category)
  text=text..string.format("Type            =  %s\n",       self.aircraft.type)
  text=text..string.format("Max air speed   = %6.1f m/s\n", self.aircraft.Vmax)
  text=text..string.format("Max climb speed = %6.1f m/s\n", self.aircraft.Vymax)
  text=text..string.format("Initial Fuel    = %6.1f\n",     self.aircraft.fuel*100)
  text=text..string.format("Max range       = %6.1f km\n",  self.aircraft.Rmax/1000)
  text=text..string.format("Eff range       = %6.1f km\n",  self.aircraft.Reff/1000)
  text=text..string.format("Ceiling         = %6.1f km = FL%3.0f\n", self.aircraft.ceiling/1000, self.aircraft.ceiling/RAT.unit.FL2m)
  text=text..string.format("FL cruise       = %6.1f km = FL%3.0f\n", self.aircraft.FLcruise/1000, self.aircraft.FLcruise/RAT.unit.FL2m)
  text=text..string.format("******************************************************\n")
  env.info(myid..text)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
  local group=self:SpawnWithIndex(self.SpawnIndex) -- Wrapper.Group#GROUP
  
  -- set ROE to "weapon hold" and ROT to "no reaction"
  self:_SetROE(group)
  self:_SetROT(group)

  -- Init ratcraft array.  
  self.ratcraft[self.SpawnIndex]={}
  self.ratcraft[self.SpawnIndex]["group"]=group
  self.ratcraft[self.SpawnIndex]["destination"]=destination
  self.ratcraft[self.SpawnIndex]["departure"]=departure
  self.ratcraft[self.SpawnIndex]["waypoints"]=waypoints
  self.ratcraft[self.SpawnIndex]["status"]="spawned"
  self.ratcraft[self.SpawnIndex]["airborn"]=false
  
  -- Handle events.
  self:HandleEvent(EVENTS.Birth,          self._OnBirthDay)
  self:HandleEvent(EVENTS.EngineStartup,  self._EngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self._OnTakeoff)
  self:HandleEvent(EVENTS.Land,           self._OnLand)
  self:HandleEvent(EVENTS.EngineShutdown, self._OnEngineShutdown)
  self:HandleEvent(EVENTS.Dead,           self._OnDead)
  -- TODO: Crash needs to be handled better. Does it always occur when dead?  
  --self:HandleEvent(EVENTS.Crash,          self._OnCrash)
  -- TODO: add hit event?
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
    
  
  -- Min cruise speed 70% of Vmax or 600 km/h whichever is lower.
  local VxCruiseMin = math.min(self.aircraft.Vmax*0.70, 166)
  
  -- Max cruise speed 90% of Vmax or 900 km/h whichever is lower.
  local VxCruiseMax = math.min(self.aircraft.Vmax*0.90, 250)
  
  -- Cruise speed (randomized).
  local VxCruise = self:_Randomize((VxCruiseMax-VxCruiseMin)/2+VxCruiseMin, 0.3 , VxCruiseMin, VxCruiseMax)
  
  -- Climb speed 90% ov Vmax but max 720 km/h.
  local VxClimb = math.min(self.aircraft.Vmax*0.90, 200)
  
  -- Descent speed 50% of Vmax but max 400 km/h.
  local VxDescent = math.min(self.aircraft.Vmax*0.50, 111)
  
  local VxHolding = VxDescent*0.8
  local VxFinal   = VxHolding*0.8
  
  -- Reasonably civil climb speed Vy=1500 ft/min but max aircraft specific climb rate.
  local VyClimb=math.min(self.Vclimb*ft2meter/60, self.aircraft.Vymax)
  
  -- Climb angle in rad.
  local AlphaClimb=math.asin(VyClimb/VxClimb)
  
  -- Descent angle in rad.
  local AlphaDescent=math.rad(self.AlphaDescent)  


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
  -- Get all destination airports within reach and at least a bit away from departure.
  self:_GetDestinations(Pdeparture, self.mindist, math.min(self.aircraft.Reff, self.maxdist))
  
  -- Pick a destination airport.
  local destination=self:_SetDestination()
  
  -- Check that departure and destination are not the same. Should not happen due to mindist.
  if destination:GetName()==departure:GetName() then
    local text="Destination and departure airport are identical: "..destination:GetName().." with ID "..destination:GetID()
    MESSAGE:New(text, 120):ToAll()
    env.error(myid..text)
  end
  
  -- Coordinates of destination airport.
  local Pdestination=destination:GetCoordinate()
  -- Height ASL of destination airport.
  local H_destination=Pdestination.y
    
  -- DESCENT/HOLDING POINT
  -- Get a random point between 5 and 10 km away from the destination.
  local Vholding
  if self.category=="plane" then
    Vholding=destination:GetCoordinate():GetRandomVec2InRadius(10000, 5000)
  else
    -- For helos we set a distance between 500 to 1000 m.
    Vholding=destination:GetCoordinate():GetRandomVec2InRadius(1000, 500)
  end
  -- Coordinates of the holding point. y is the land height at that point.
  local Pholding=COORDINATE:NewFromVec2(Vholding)
  
  -- AGL height of holding point.
  local H_holding=Pholding.y
  
  -- Holding point altitude. For planes between 1600 and 2400 m AGL. For helos 160 to 240 m AGL.
  local h_holding
  if self.category=="plane" then
    h_holding=2000
  else
    h_holding=200
  end
  h_holding=self:_Randomize(h_holding, 0.2)
    
  -- Distance from holding point to final destination.
  local d_holding=Pholding:Get2DDistance(Pdestination)
  
  -- Height difference between departure and holding point.
  local deltaH=h_holding+H_holding-H_departure
  
  -- GENERAL
  -- Heading from departure to holding point of destination.
  local heading=self:_Course(Pdeparture, Pholding)
  
  -- Total distance between departure and holding point near destination.
  local d_total=Pdeparture:Get2DDistance(Pholding)
  
  -- Climb/descent angle from departure to holding point
  local phi=math.atan(deltaH/d_total)
  
  -- Corrected climb angle.
  local PhiClimb=AlphaClimb+phi
  
  -- Corrected descent angle.
  local PhiDescent=AlphaDescent-phi

  --CRUISE  

  -- Max flight level the aircraft can reach if it only climbs and immidiately descents again (i.e. no cruising part).
  local FLmax=self:_FLmax(AlphaClimb, AlphaDescent, d_total, phi, H_departure)
  
  -- Min cruise alt is just above holding point at destination or departure height, whatever is larger.
  local FLmin=math.max(H_departure, H_holding+h_holding)
  
  -- If the route is very short we set FLmin a bit lower than FLmax.
  if FLmin>FLmax then
    FLmin=FLmax*0.75
  end
    
  -- For helicopters we take cruise alt between 50 to 1000 meters above ground. Default cruise alt is ~150 m.
  if self.category=="heli" then  
    FLmin=math.max(H_departure, H_destination)+50
    FLmax=math.max(H_departure, H_destination)+1000
  end
  
  -- Ensure that FLmax not above 90% its service ceiling.
  FLmax=math.min(FLmax, self.aircraft.ceiling*0.9)
  
  -- Set cruise altitude: default with 100% randomization but limited to FLmin and FLmax.
  local FLcruise=self:_Randomize(self.aircraft.FLcruise, 1.0, FLmin, FLmax)
  
  -- Overrule setting if user specifies a flight level very explicitly.
  if self.FLuser then
    FLcruise=self.FLuser
  end
    
  -- CLIMB
  -- Height of climb relative to ASL height of departure airport.
  local h_climb=FLcruise-H_departure
  -- x-distance of climb part 
  local d_climb=h_climb/math.tan(PhiClimb)
  
  -- DESCENT
  -- Height difference for descent form cruise alt to holding point.
  local h_descent=FLcruise-(H_holding+h_holding)
  -- x-distance of descent part
  local d_descent=h_descent/math.tan(PhiDescent)
  
  -- CRUISE
  -- Distance of the cruising part. This should in principle not become negative, but can happen for very short legs.
  local d_cruise=d_total-d_climb-d_descent
  
  -- debug message
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Speeds:\n")
  text=text..string.format("VxCruiseMin   = %6.1f m/s = %5.1f km/h\n", VxCruiseMin, VxCruiseMin*3.6)
  text=text..string.format("VxCruiseMax   = %6.1f m/s = %5.1f km/h\n", VxCruiseMax, VxCruiseMax*3.6)
  text=text..string.format("VxCruise      = %6.1f m/s = %5.1f km/h\n", VxCruise, VxCruise*3.6)
  text=text..string.format("VxClimb       = %6.1f m/s = %5.1f km/h\n", VxClimb, VxClimb*3.6)
  text=text..string.format("VxDescent     = %6.1f m/s = %5.1f km/h\n", VxDescent, VxDescent*3.6)
  text=text..string.format("VxHolding     = %6.1f m/s = %5.1f km/h\n", VxHolding, VxHolding*3.6)
  text=text..string.format("VxFinal       = %6.1f m/s = %5.1f km/h\n", VxFinal, VxFinal*3.6)
  text=text..string.format("VyClimb       = %6.1f m/s\n", VyClimb)
  text=text..string.format("\nDistances:\n")
  text=text..string.format("d_climb       = %6.1f km\n", d_climb/1000)
  text=text..string.format("d_cruise      = %6.1f km\n", d_cruise/1000)
  text=text..string.format("d_descent     = %6.1f km\n", d_descent/1000)
  text=text..string.format("d_holding     = %6.1f km\n", d_holding/1000)
  text=text..string.format("d_total       = %6.1f km\n", d_total/1000)
  text=text..string.format("\nHeights:\n")
  text=text..string.format("H_departure   = %6.1f m ASL\n", H_departure)
  text=text..string.format("H_destination = %6.1f m ASL\n", H_destination)
  text=text..string.format("H_holding     = %6.1f m ASL\n", H_holding)
  text=text..string.format("h_climb       = %6.1f m\n",     h_climb)
  text=text..string.format("h_descent     = %6.1f m\n",     h_descent)
  text=text..string.format("h_holding     = %6.1f m\n",     h_holding)
  text=text..string.format("FLmin         = %6.1f m ASL\n", FLmin)
  text=text..string.format("FLmax         = %6.1f m ASL\n", FLmax)
  text=text..string.format("FLcruise      = %6.1f m ASL\n", FLcruise)
  text=text..string.format("\nAngles:\n")  
  text=text..string.format("Alpha climb   = %6.1f Deg\n",   math.deg(AlphaClimb))
  text=text..string.format("Alpha descent = %6.1f Deg\n",   math.deg(AlphaDescent))
  text=text..string.format("Phi           = %6.1f Deg\n",   math.deg(phi))
  text=text..string.format("Heading       = %6.1f Deg\n",   heading)
  text=text..string.format("******************************************************\n")
  env.info(myid..text)
  
  -- Ensure that cruise distance is positve. Can be slightly negative in special cases. And we don't want to turn back.
  d_cruise=math.abs(d_cruise)
  
  -- Coordinates of route from departure (0) to cruise (1) to descent (2) to holing (3) to destination (4).
  local c0=Pdeparture
  local c1=c0:Translate(d_climb/2,   heading)
  local c2=c1:Translate(d_climb/2,   heading)
  local c3=c2:Translate(d_cruise,    heading)
  local c4=c3:Translate(d_descent/2, heading)
  local c5=Pholding
  local c6=Pdestination
  
  --Convert coordinates into route waypoints.
  local wp0=self:_Waypoint(self.takeoff, c0, VxClimb,   H_departure, departure)
  local wp1=self:_Waypoint("climb",      c1, VxClimb,   H_departure+(FLcruise-H_departure)/2)
  local wp2=self:_Waypoint("cruise",     c2, VxCruise,  FLcruise)
  local wp3=self:_Waypoint("cruise",     c3, VxCruise,  FLcruise)
  local wp4=self:_Waypoint("descent",    c4, VxDescent, FLcruise-(FLcruise-(h_holding+H_holding))/2)
  local wp5=self:_Waypoint("holding",    c5, VxHolding, H_holding+h_holding)
  local wp6=self:_Waypoint("landing",    c6, VxFinal,   H_destination, destination)
  
   -- set waypoints
  local waypoints = {wp0, wp1, wp2, wp3, wp4, wp5, wp6}
  
  -- Place markers of waypoints on F10 map.
  if self.placemarkers then
    self:_SetMarker("Takeoff",         c0)
    self:_SetMarker("Climb",           c1)
    self:_SetMarker("Begin of Cruise", c2)
    self:_SetMarker("End of Cruise",   c3)
    self:_SetMarker("Descent",         c4)
    self:_SetMarker("Holding Point",   c5)
    self:_SetMarker("Destination",     c6)
  end
    
  -- some info on the route as message
  self:_Routeinfo(waypoints, "Waypoint info in set_route:")
  
  -- return departure, destination and waypoints
  return departure, destination, waypoints
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the departure airport of the AI. If no airport name is given explicitly an airport from the coalition is chosen randomly.
-- If takeoff style is set to "air", we use zones around the airports or the zones specified by user input.
-- @param #RAT self
-- @return Wrapper.Airbase#AIRBASE Departure airport if spawning at airport.
function RAT:_SetDeparture()

  -- Array of possible departure airports or zones.
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
        self:E(self.departure_zones)
        env.info(myid.."Zone name: "..name)
        table.insert(departures, ZONE:New(name))
      end
      -- Put all specified airport zones in table.
      for _,name in pairs(self.departure_ports) do
        table.insert(departures, AIRBASE:FindByName(name):GetZone())
      end
      
    end
    
  else
  
    if self.random_departure then
    
      -- All friendly departure airports. 
      for _,airport in pairs(self.airports) do
        table.insert(departures, airport)
      end
      
    else
      
      -- All airports specified by user  
      for _,name in pairs(self.departure_ports) do
        table.insert(departures, AIRBASE:FindByName(name))
      end
        
    end
  end

  -- Select departure airport or zone.
  local departure=departures[math.random(#departures)]
  
  local text
  if self.takeoff=="air" then
    text="Chosen departure zone: "..departure:GetName()
  else
    text="Chosen departure airport: "..departure:GetName().." (ID "..departure:GetID()..")"
  end
  env.info(myid..text)
  MESSAGE:New(text, 30):ToAll()
  
  return departure
end


--- Set the destination airport of the AI. If no airport name is given an airport from the coalition is chosen randomly.
-- @param #RAT self
-- @return Wrapper.Airbase#AIRBASE Destination airport.
function RAT:_SetDestination()

  -- Array of possible destination airports.
  local destinations={}
  
  if self.random_destination then
  
    -- All airports of friendly coalitons.
    for _,airport in pairs(self.airports_destination) do
      table.insert(destinations, airport)
    end
  
  else
  
    -- All airports specified by user.
    for _,name in pairs(self.destination_ports) do
      table.insert(destinations, AIRBASE:FindByName(name))
    end
    
  end
  
  -- Randomly select one possible destination.
  local destination=destinations[math.random(#destinations)] -- Wrapper.Airbase#AIRBASE
  
  local text="Chosen destination airport: "..destination:GetName().." (ID "..destination:GetID()..")"
  env.info(myid..text)
  MESSAGE:New(text, 30):ToAll()
  
  return destination
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get all possible destination airports depending on departure position.
-- The list is sorted w.r.t. distance to departure position.
-- @param #RAT self
-- @param Core.Point#COORDINATE q Coordinate of the departure point.
-- @param #number minrange Minimum range to q in meters.
-- @param #number maxrange Maximum range to q in meters.
function RAT:_GetDestinations(q, minrange, maxrange)

  minrange=minrange or self.mindist
  maxrange=maxrange or self.maxdist
   
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
    for _,airbase in pairs(ab) do
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
        -- Planes cannot land on FARPs.
        local condition1=self.category=="plane" and airport:GetTypeName()=="FARP"
        -- Planes cannot land on ships.
        local condition2=self.category=="plane" and airport:GetCategory()==1
        if not (condition1 or condition2) then
          table.insert(self.airports, airport)
        end
      end
    end
  end
    
  if #self.airports==0 then
    local text="No possible departure/destination airports found!"
    MESSAGE:New(text, 180):ToAll()
    env.error(myid..text)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Report status of RAT groups.
-- @param #RAT self
function RAT:Status()

  local ngroups=#self.ratcraft
  
  local text=string.format("Groups spawned = %i\n", ngroups)
  text=text..string.format("Spawn Template: %s\n", self.SpawnTemplatePrefix)
  text=text..string.format("Spawn Index = %d\n", self.SpawnIndex)
  text=text..string.format("Spawn Count = %d\n", self.SpawnCount)
  text=text..string.format("Spawn Alive = %d", self.AliveUnits)
  MESSAGE:New(text, 60):ToAll()
  
  for i=1, ngroups do
  
    --local group=self.SpawnGroups[i].Group
    if self.ratcraft[i].group then
      local group=self.ratcraft[i].group  --Wrapper.Group#GROUP
      local prefix=self:_GetPrefixFromGroup(group)
      local life=self:_GetLife(group)
      local fuel=group:GetFuel()
      local airborn=group:InAir()
    
      local text=string.format("Group %s ID %i:\n", prefix, i) 
      text=text..string.format("Life = %3.0f\n", life)
      text=text..string.format("Fuel = %3.0f\n", fuel)
      text=text..string.format("Status = %s\n", self.ratcraft[i].status)
      text=text..string.format("Status = %s\n", tostring(airborn))
      text=text..string.format("Flying from %s to %s.",self.ratcraft[i].departure:GetName(), self.ratcraft[i].destination:GetName())
      MESSAGE:New(text, 60):ToAll()
      env.info(myid..text)
    else
      local text=string.format("Group %i does not exist.", i)
      MESSAGE:New(text, 60):ToAll()
      env.info(myid..text)
    end    
  end
end

--- Get (relative) life of first unit of a group.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group of unit.
-- @return #number Life of unit in percent.
function RAT:_GetLife(group)
  local life=0.0
  if group and group:IsAlive() then
    local unit=group:GetUnit(1)
    if unit then
      life=unit:GetLife()/unit:GetLife0()*100
    else
      env.error(myid.."Unit does not exist in RAT_Getlife(). Returning zero.")
    end
  else
    env.error(myid.."Group does not exist in RAT_Getlife(). Returning zero.")
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function is executed when a unit is spawned.
-- @param #RAT self
function RAT:_OnBirthDay(EventData)

  local SpawnGroup = EventData.IniGroup
  
  if SpawnGroup then
  
    local index=self:GetSpawnIndexFromGroup(SpawnGroup)
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    local text="Event: Group "..SpawnGroup:GetName().." was born."
    env.info(myid..text)
    self:_SetStatus(SpawnGroup, "starting engines (after birth)")
    
  else
    env.error("Group does not exist in RAT:_EngineStartup().")
  end
end

--- Function is executed when a unit starts its engines.
-- @param #RAT self
function RAT:_EngineStartup(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    local text="Event: Group "..SpawnGroup:GetName().." started engines. Life="..self:_GetLife(SpawnGroup)
    env.info(myid..text)
    
    local status
    if SpawnGroup:InAir() then
      status="airborn"
    else
      status="taxi (after engines started)"
    end
    self:_SetStatus(SpawnGroup, status)
  else
    env.error("Group does not exist in RAT:_EngineStartup().")
  end
end

--- Function is executed when a unit takes off.
-- @param #RAT self
function RAT:_OnTakeoff(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    local text="Event: Group "..SpawnGroup:GetName().." is airborn. Life="..self:_GetLife(SpawnGroup)
    env.info(myid..text)
    
    self:_SetStatus(SpawnGroup, "airborn (after takeoff)")
  else
    env.error("Group does not exist in RAT:_OnTakeoff().")
  end
end

--- Function is executed when a unit lands.
-- @param #RAT self
function RAT:_OnLand(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    local text="Event: Group "..SpawnGroup:GetName().." landed. Life="..self:_GetLife(SpawnGroup)
    env.info(myid..text)
    
    -- Set status.
    self:_SetStatus(SpawnGroup, "taxi (after landing)")
    
    -- Spawn new group.
    self:_SpawnWithRoute()
    
    text="Event: Group "..SpawnGroup:GetName().." will be respawned."
    env.info(myid..text)
    
  else
    env.error("Group does not exist in RAT:_OnLand().")
  end
end

--- Function is executed when a unit shuts down its engines.
-- @param #RAT self
function RAT:_OnEngineShutdown(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    local text="Event: Group "..SpawnGroup:GetName().." shut down its engines. Life="..self:_GetLife(SpawnGroup)
    env.info(myid..text)
    
    -- Set status.
    self:_SetStatus(SpawnGroup, "parking (after engine shut down)")
    
    text="Event: Group "..SpawnGroup:GetName().." will be destroyed now."
    env.info(myid..text)
        
    self:_Despawn(SpawnGroup)
  else
    env.error("Group does not exist in RAT:_OnEngineShutdown().")
  end
end

--- Function is executed when a unit is dead.
-- @param #RAT self
function RAT:_OnDead(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  env.info("In function _OnDead()")
  
  if SpawnGroup then
  
    local text="Event: Group "..SpawnGroup:GetName().." died."
    env.info(myid..text)
    
    -- Set status.
    self:_SetStatus(SpawnGroup, "destroyed (after dead)")

  else
    env.error("Group does not exist in RAT:_OnDead().")
  end
end

--- Function is executed when a unit crashes.
-- @param #RAT self
function RAT:_OnCrash(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    local text="Event: Group "..SpawnGroup:GetName().." crashed."
    env.info(myid..text)
    
    -- Set status.
    self:_SetStatus(SpawnGroup, "crashed")
    
    --TODO: Maybe spawn some people at the crash site and send a distress call.
    --      And define them as cargo which can be rescued.
  else
    env.error("Group does not exist in RAT:_OnCrash().")
  end
end

--- Function is executed when a unit crashes.
-- @param #RAT self
function RAT:_Despawn(group)

  local index=self:GetSpawnIndexFromGroup(group)
  env.info(myid.."Number of ratcraft before = "..#self.ratcraft)
  self.ratcraft[index].group:Destroy()
  self.ratcraft[index].group=nil
  --table.remove(self.ratcraft, index)
  env.info(myid.."Number of ratcraft after = "..#self.ratcraft)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a waypoint that can be used with the Route command.
-- @param #RAT self 
-- @param #string Type Type of waypoint. takeoff-cold, takeoff-hot, takeoff-runway, climb, cruise, descent, holding, land, landing.
-- @param Core.Point#COORDINATE Coord 3D coordinate of the waypoint.
-- @param #number Speed Speed in m/s.
-- @param #number Altitude Altitude in m.
-- @param Wrapper.Airbase#AIRBASE Airport Airport of object to spawn.
-- @return #table Waypoints for DCS task route or spawn template.
function RAT:_Waypoint(Type, Coord, Speed, Altitude, Airport)

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

  local case=2

if case==1 then
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
    local ab=Airbase.getByName("Farp")
    local p=ab:getPoint()
    --self:_SetMarker("Farp Position", p)
    self.E(ab:getDesc())
    _AID = 1
  elseif Type:lower()=="takeoff-runway" or Type:lower()=="runway" then
    -- take-off from runway
    _Type="TakeOff"
    _Action="From Parking Area"
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
    env.error("Unknown waypoint type in RAT:Waypoint function!")
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="RADIO"
  end

else

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
    _Action="From Parking Area"
    _Altitude = 2
    _alttype="RADIO"
    _AID = Airport:GetID()
  elseif Type:lower()=="air" then
    -- air start
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="BARO"
  elseif Type:lower()=="climb" then
      _Type="Turning Point"
    _Action="Turning Point"
    --_Action="Fly Over Point"
    _alttype="BARO"
  elseif Type:lower()=="cruise" then
    _Type="Turning Point"
    _Action="Turning Point"
    --_Action="Fly Over Point"
    _alttype="BARO"
  elseif Type:lower()=="descent" then
    _Type="Turning Point"
    _Action="Turning Point"
    --_Action="Fly Over Point"
    _alttype="BARO"
  elseif Type:lower()=="holding" then
    _Type="Turning Point"
    _Action="Turning Point"
    --_Action="Fly Over Point"
    _alttype="BARO"
  elseif Type:lower()=="landing" or Type:lower()=="land" then
    _Type="Land"
    _Action="Landing"
    _Altitude = 2
    _alttype="RADIO"
    _AID = Airport:GetID()
  else
    env.error("Unknown waypoint type in RAT:Waypoint() function!")
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="RADIO"
  end

end

  -- some debug info about input parameters
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Type: %s - %s\n", Type, _Type)
  text=text..string.format("Action: %s\n", _Action)
  text=text..string.format("Coord: x = %6.1f km, y = %6.1f km, alt = %6.1f m\n", Coord.x/1000, Coord.z/1000, Coord.y)
  text=text..string.format("Speed = %6.1f m/s = %6.1f km/h = %6.1f knots\n", Speed, Speed*3.6, Speed*1.94384)
  text=text..string.format("Land     = %6.1f m ASL\n", Hland)
  text=text..string.format("Altitude = %6.1f m (%s)\n", _Altitude, _alttype)
  if Airport then
    if Type:lower() == "air" then
      text=text..string.format("Zone = %s\n", Airport:GetName())
    else
      text=text..string.format("Airport = %s with ID %i\n", Airport:GetName(), Airport:GetID())
    end
  else
    text=text..string.format("No airport/zone specified\n")
  end
  text=text.."******************************************************\n"
  env.info(myid..text)
  
  -- define waypoint
  local RoutePoint = {}
  -- coordinates and altitude
  RoutePoint.x = Coord.x
  RoutePoint.y = Coord.z
  RoutePoint.alt = _Altitude
  -- altitude type: BARO=ASL or RADIO=AGL
  RoutePoint.alt_type = _alttype
  -- type 
  RoutePoint.type = _Type
  RoutePoint.action = _Action
  -- speed in m/s
  RoutePoint.speed = Speed
  RoutePoint.speed_locked = true
  -- ETA (not used)
  RoutePoint.ETA=0
  RoutePoint.ETA_locked = false
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
  
  -- Return waypoint.
  return RoutePoint
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Provide information about the assigned flightplan.
-- @param #RAT self
-- @param #table waypoints Waypoints of the flight plan.
-- @param #string comment Some comment to identify the provided information.
-- @return #number total Total route length in meters.
function RAT:_Routeinfo(waypoints, comment)

  local text=string.format("\n******************************************************\n")
  if comment then
    text=text..comment.."\n"
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
  text=text..string.format("Total distance = %6.1f km\n", total/1000)
  local text=string.format("******************************************************\n")
  -- send message
  env.info(myid..text)
  
  -- return total route length in meters
  return total
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
  env.info(myid.."Heading wp1->wp2: "..heading)

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
        --TODO: Somehow this does not work. Initial heading of the units for air start is not equal to heading specified here.
        SpawnTemplate.units[UnitID].heading = math.rad(heading)
        self:T('After Translation SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
      end
      
      -- Copy waypoints into spawntemplate. By this we avoid the nasty DCS "landing bug" :)
      for i,wp in ipairs(waypoints) do
        SpawnTemplate.route.points[i]=wp
      end
      
      -- Also modify x,y of the template. Not sure why.
      SpawnTemplate.x = PointVec3.x
      SpawnTemplate.y = PointVec3.z
      
      -- Update modified template for spawn group.
      self.SpawnGroups[self.SpawnIndex].SpawnTemplate=SpawnTemplate
      
      self:E(SpawnTemplate)        
    end
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Orbit at a specified position at a specified alititude with a specified speed.
-- @param #RAT self
-- @param Dcs.DCSTypes#Vec2 P1 The point to hold the position.
-- @param #number Altitude The altitude AGL to hold the position.
-- @param #number Speed The speed flying when holding the position in m/s.
-- @return Dcs.DCSTasking.Task#Task DCSTask
function RAT:_TaskHolding(P1, Altitude, Speed)
  local LandHeight = land.getHeight(P1)

  --TODO: randomize P1
  -- Second point is 10 km north of P1 and 200 m for helos.
  local dx=10000
  local dy=0
  if self.category=="heli" then
    dx=200
    dy=0
  end
  
  local P2={}
  P2.x=P1.x+dx
  P2.y=P1.y+dy
  local Task = {
    id = 'Orbit',
    params = {
      pattern = AI.Task.OrbitPattern.RACE_TRACK,
      point = P1,
      point2 = P2,
      speed = Speed,
      altitude = Altitude + LandHeight
    }
  }
  
  -- Duration of holing. Between 10 and 170 seconds. 
  local d=self:_Randomize(90,0.9)
  
  local DCSTask={}
  DCSTask.id="ControlledTask"
  DCSTask.params={}
  DCSTask.params.task=Task
  DCSTask.params.stopCondition={duration=d}
  
  return DCSTask
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Calculate the max flight level for a given distance and fixed climb and descent rates.
-- In other words we have a distance between two airports and want to know how high we
-- can climb before we must descent again to arrive at the destination without any level/cruising part.
-- @param #RAT self
-- @param #number alpha Angle of climb [rad].
-- @param #number beta Angle of descent [rad].
-- @param #number d Distance between the two airports [m].
-- @param #number phi Angle between departure and destination [rad].
-- @param #number h0 Height [m] of departure airport. Note we implicitly assume that the height difference between departure and destination is negligible.
-- @return #number  Maximal flight level in meters.
function RAT:_FLmax(alpha, beta, d, phi, h0)
-- Solve ASA triangle for one side (d) and two adjacent angles (alpha, beta) given.
  local gamma=math.rad(180)-alpha-beta
  local a=d*math.sin(alpha)/math.sin(gamma)
  local b=d*math.sin(beta)/math.sin(gamma)
  local h1=b*math.sin(alpha)
  local h2=a*math.sin(beta)
  local h3=b*math.cos(math.pi/2-(alpha+phi))
  -- h1 and h2 should be equal.
  local text=string.format("\nFLmax = FL%3.0f = %6.1f m.\n", h1/RAT.unit.FL2m, h1)
  text=text..string.format(  "FLmax = FL%3.0f = %6.1f m.\n", h2/RAT.unit.FL2m, h2)
  text=text..string.format(  "FLmax = FL%3.0f = %6.1f m.",   h3/RAT.unit.FL2m, h3)
  env.info(myid..text)
  return h3+h0
end


--- Test if an airport exists on the current map.
-- @param #RAT self
-- @param #string name
-- @return #boolean True if airport exsits, false otherwise. 
function RAT:_AirportExists(name)
  for _,airport in pairs(self.airports_map) do
    if airport:GetName()==name then
      return true
    end
  end
  return false
end

--- Set ROE for a group.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group for which the ROE is set.
function RAT:_SetROE(group)
  if self.roe=="return" then
    group:OptionROEReturnFire()
  elseif self.roe=="free" then
    group:OptionROEWeaponFree()
  else
    group:OptionROEHoldFire()
  end
end


--- Set ROT for a group.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group for which the ROT is set.
function RAT:_SetROT(group)
  if self.roe=="passive" then
    group:OptionROTPassiveDefense()
  elseif self.roe=="evade" then
    group:OptionROTEvadeFire()
  else
    group:OptionROTNoReaction()
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
    env.error("Unknown friendly coalition in _SetCoalitionTable(). Defaulting to NEUTRAL.")
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
  
  -- debug info
  local text=string.format("Random: value = %6.2f, fac = %4.2f, min = %6.2f, max = %6.2f, r = %6.2f", value, fac, min, max, r)
  env.info(myid..text)
  
  return r
end


--- Set a marker for all on the F10 map.
-- @param #RAT self
-- @param #string text Text of maker.
-- @param Core.Point#COORDINATE vec3 Position of marker.
function RAT:_SetMarker(text, vec3)
  RAT.markerid=RAT.markerid+1
  env.info(myid.."Placing marker with ID "..RAT.markerid..": "..text)
  trigger.action.markToAll(RAT.markerid, text, vec3)
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------