-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- **Functional** - Pseudo ATC.
--  
-- ![Banner Image](..\Presentations\PSEUDOATC\PSEUDOATC_Main.jpg)
-- 
-- ====
-- 
-- The pseudo ATC enhances the standard DCS ATC functions.
-- 
-- In particular, a menu entry "Pseudo ATC" is created in the special F10 menu.
-- 
-- ## Features
-- 
-- * Report QFE or QNH pressures at nearby airbases.
-- * Report wind direction and strength at airbases.
-- * Report temperature at airbases
-- * Report absolute bearing and range to nearest airports.
-- * Report current altitude AGL of own aircraft.
-- * Upon request, ATC reports altitude until touchdown.
-- * Pressure temperature, wind data and BR for mission waypoints.
-- * Works with static and dynamic weather.
-- * All maps supported (Caucasus, NTTR, Normandy, and all future maps).
-- * Multiplayer ready (?) (I suppose yes, but I don't have a server to test or debug. Jumping from client to client works.)
--  
--  Pressure units: hPa (european aircraft), mmHg (russian aircraft), inHg (american aircraft).
-- 
-- ====
-- 
-- # Demo Missions
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [MOOSE YouTube Channel](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl1jirWIo4t4YxqN-HxjqRkL)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: **Sven van de Velde ([FlightControl](https://forums.eagle.ru/member.php?u=89536))**
-- 
-- ====
-- @module PeusoATC

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- PSEUDOATC class
-- @type PSEUDOATC
-- @field #string ClassName Name of the Class.
-- @field #boolean Debug If true, print debug info to dcs.log file.
-- @field #table player Table comprising the player info.
-- @field #number mdur Duration in seconds how low messages to the player are displayed.
-- @field #boolean eventsmoose If true, events are handled by MOOSE. If false, events are handled directly by DCS eventhandler.
-- @extends Core.Base#BASE

---# PSEUDOATC class, extends @{Base#BASE}
-- The PSEUDOATC class adds some rudimentary ATC functionality via the radio menu.
-- 
-- ## Scripting:
-- 
-- Scripting is almost trivial. Just add the following line to your script:
-- 
--     PSEUDOATC:Start()
-- 
-- 
-- @field #PSEUDOATC
PSEUDOATC={
  ClassName = "PSEUDOATC",
  Debug=true,
  player={},
  maxairport=9,
  mdur=30,
  mrefresh=120,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- PSEUDOATC unit conversions.
-- @list unit
PSEUDOATC.unit={
  hPa2inHg=0.0295299830714,
  hPa2mmHg=0.7500615613030,
  meter2feet=3.28084,
  km2nm=0.539957,
}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
PSEUDOATC.id="PseudoATC | "

--- PSEUDOATC version.
-- @field #list
PSEUDOATC.version={
  version = "0.5.0",
  print = true,
}


--- PSEUDOATC contructor. Starts the PseudoATC.
-- @param #PSEUDOATC self
-- @return #PSEUDOATC Returns a PSEUDOATC object.
function PSEUDOATC:Start()

  -- Inherit BASE.
  local self=BASE:Inherit(self, BASE:New()) -- #PSEUDOATC
  
  -- Debug info
  env.info(PSEUDOATC.id..string.format("Creating PseudoATC object. PseudoATC version %s", PSEUDOATC.version.version))
  
  -- Handle events.
  if self.eventsmoose then
    self:HandleEvent(EVENTS.Birth, self._OnBirth)
    self:HandleEvent(EVENTS.PlayerLeaveUnit, self._PlayerLeft)
    --self:HandleEvent(EVENTS.PilotDead, self._PlayerLeft)
    self:HandleEvent(EVENTS.Land, self._PlayerLanded)
    --self:HandleEvent(EVENTS.Takeoff, self._PlayerTakeoff)
  else
    -- Events are handled directly by DCS.
    world.addEventHandler(self)
  end
  
  -- Return object.
  return self
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Event Handling

--- Event handler for suppressed groups.
--@param #PSEUDOATC self
--@param #table Event Event data table. Holds event.id, event.initiator and event.target etc.
function PSEUDOATC:onEvent(Event)
  if Event == nil or Event.initiator == nil or Unit.getByName(Event.initiator:getName()) == nil then
    return true
  end

  local DCSiniunit  = Event.initiator
  local DCSplace    = Event.place
  local DCSsubplace = Event.subplace

  local EventData={}
  local _playerunit=nil
  local _playername=nil
  
  if Event.initiator then
    EventData.IniUnitName  = Event.initiator:getName()
    EventData.IniDCSGroup  = Event.initiator:getGroup()
    EventData.IniGroupName = Event.initiator:getGroup():getName()  
    -- Get player unit and name. This returns nil,nil if the event was not fired by a player unit. And these are the only events we are interested in. 
    _playerunit, _playername = self:_GetPlayerUnitAndName(EventData.IniUnitName)  
  end

  if Event.place then
    EventData.Place=Event.place
    EventData.PlaceName=Event.place:getName()
  end
  if Event.subplace then
    EventData.SubPlace=Event.subplace
    EventData.SubPlaceName=Event.subplace:getName()
  end
  
  -- Event info.
  if self.Debug then
    env.info(PSEUDOATC.id..string.format("EVENT: Event in onEvent with ID = %s", tostring(Event.id)))
    env.info(PSEUDOATC.id..string.format("EVENT: Ini unit   = %s" , tostring(EventData.IniUnitName)))
    env.info(PSEUDOATC.id..string.format("EVENT: Ini group  = %s" , tostring(EventData.IniGroupName)))
    env.info(PSEUDOATC.id..string.format("EVENT: Ini player = %s" , tostring(_playername)))
    env.info(PSEUDOATC.id..string.format("EVENT: Place      = %s" , tostring(EventData.PlaceName)))
    env.info(PSEUDOATC.id..string.format("EVENT: SubPlace   = %s" , tostring(EventData.SubPlaceName)))
  end
  
  -- Event birth.
  if Event.id == world.event.S_EVENT_BIRTH and _playername then
    self:_OnBirth(EventData)
  end
  
  -- Event land.
  if Event.id == world.event.S_EVENT_LAND and _playername and EventData.Place then
    self:_PlayerLanded(EventData)
  end
  
  -- Event player left unit
  if Event.id == world.event.S_EVENT_PLAYER_LEAVE_UNIT and _playername then
    self:_PlayerLeft(EventData)
  end
  
end

--- Function called my MOOSE event handler when a player enters a unit.
-- @param #PSEUDOATC self
-- @param Core.Event#EVENTDATA EventData
function PSEUDOATC:_OnBirth(EventData)
  env.info(PSEUDOATC.id.."PlayerEntered event caught my MOOSE.")
  
  local _unitName=EventData.IniUnitName  
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  if _unit and _playername then
    self:PlayerEntered(_unit)
  end               
 
end

--- Function called by MOOSE event handler when a player leaves a unit or dies. 
-- @param #PSEUDOATC self
-- @param Core.Event#EVENTDATA EventData
function PSEUDOATC:_PlayerLeft(EventData)

  local _unitName=EventData.IniUnitName  
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  if _unit and _playername then
    self:PlayerLeft(_unit)
  end
end

--- Function called by MOOSE event handler when a player landed. 
-- @param #PSEUDOATC self
-- @param Core.Event#EVENTDATA EventData
function PSEUDOATC:_PlayerLanded(EventData)

  local _unitName=EventData.IniUnitName  
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  local _base=EventData.Place
  local _baseName=EventData.PlaceName
  
  if _unit and _playername and _base  then
    self:PlayerLanded(_unit, _baseName)
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions

--- Function called when a player enters a unit.
-- @param #PSEUDOATC self
-- @param Wrapper.Unit#UNIT unit Unit the player entered.
function PSEUDOATC:PlayerEntered(unit)
  self:F2({unit=unit})

  local group=unit:GetGroup() --Wrapper.Group#GROUP
  local GID=group:GetID()
  local GroupName=group:GetName()
  local PlayerName=unit:GetPlayerName()
  local UnitName=unit:GetName()
  local CallSign=unit:GetCallsign()
  
  -- Init player table.  
  self.player[GID]={}
  self.player[GID].group=group
  self.player[GID].unit=unit
  self.player[GID].groupname=GroupName
  self.player[GID].unitname=UnitName
  self.player[GID].playername=PlayerName
  self.player[GID].callsign=CallSign
  self.player[GID].waypoints=group:GetTaskRoute()
  
  -- Info message.
  local text=string.format("Player %s entered unit %s of group %s. ID = %d", PlayerName, UnitName, GroupName, GID)
  if self.Debug then
    MESSAGE:New(text, 30):ToGroup(group)
    env.info(PSEUDOATC.id..text)
  end
  
  -- Create main F10 menu, i.e. "F10/Pseudo ATC"
  self.player[GID].menu_main=missionCommands.addSubMenuForGroup(GID, "Pseudo ATC")
    
  -- Create list of nearby airports.
  self:LocalAirports(GID)
  
  -- Create submenu My Positon.
  self:MenuAircraft(GID)
  
  -- Create submenu airports.
  self:MenuAirports(GID)
  
  -- Start scheduler to refresh the F10 menues.
  self.player[GID].scheduler, self.player[GID].schedulerid=SCHEDULER:New(nil, self.MenuRefresh, {self, GID}, self.mrefresh, self.mrefresh)
 
  self:T2(self.player[GID])
end

--- Function called when a player has landed.
-- @param #PSEUDOATC self
-- @param Wrapper.Unit#UNIT unit Unit of player which has landed.
-- @param #string place Name of the place the player landed at.
function PSEUDOATC:PlayerLanded(unit, place)
  self:F2({unit=unit, place=place})
  
  -- Gather some information.
  local group=unit:GetGroup()
  local id=group:GetID()
  local PlayerName=self.player[id].playername
  local UnitName=self.player[id].playername
  local GroupName=self.player[id].groupname
  local CallSign=self.player[id].callsign
  
  -- Debug message.
  if self.Debug then
    local text=string.format("Player %s (%s) from group %s with ID %d landed at %s", PlayerName, UnitName, GroupName, place)
    MESSAGE:New(text,30):ToAll()
    env.info(PSEUDOATC.id..text)
  end
  
  -- Stop altitude reporting timer if its activated.
  self:AltidudeStopTimer(id)
  
  -- Welcome message.
  if place then
    local text=string.format("Touchdown! Welcome to %s. Have a nice day!", place)
    MESSAGE:New(text, self.mdur):ToGroup(group)
  end

end

--- Function called when a player leaves a unit or dies. 
-- @param #PSEUDOATC self
-- @param Wrapper.Unit#UNIT unit Player unit which was left.
function PSEUDOATC:PlayerLeft(unit)
  self:F2({unit=unit})
 
  -- Get id.
  local group=unit:GetGroup()
  local id=group:GetID()
  
  -- Debug message.
  if self.Debug then
    local text=string.format("Player %s (%s) callsign %s of group %s just left.", self.player[id].playername, self.player[id].unitname, self.player[id].callsign, self.player[id].groupname)
    MESSAGE:New(text,30):ToAll()
    env.info(PSEUDOATC.id..text)
  end
  
  -- Stop scheduler for menu updates
  if self.player[id].schedulerid then
    self.player[id].scheduler:Stop(self.player[id].schedulerid)
    self.player[id].scheduler=nil
    self.player[id].schedulerid=nil
  end
    
  -- Remove main menu
  missionCommands.removeItem(self.player[id].menu_main)
  
  -- Remove player array.
  self.player[id]=nil
               
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions

--- Refreshes all player menues.
-- @param #PSEUDOATC self.
-- @param #number id Group id of player unit. 
function PSEUDOATC:MenuRefresh(id)
  self:F(id)

  if self.Debug then
    local text=string.format("Refreshing menues for player %s in group %s.", self.player[id].playername, self.player[id].groupname)
    env.info(PSEUDOATC.id..text)
    MESSAGE:New(text,30):ToAll()
  end

  -- Clear menu.
  self:MenuClear(id)
  
  -- Create list of nearby airports.
  self:LocalAirports(id)
    
  -- Create submenu My Positon.
  self:MenuAircraft(id)
  
  -- Create submenu airports.
  self:MenuAirports(id)
end


--- Clear player menues.
-- @param #PSEUDOATC self.
-- @param #number id Group id of player unit. 
function PSEUDOATC:MenuClear(id)
  self:F(id)

  if self.Debug then
    local text=string.format("Clearing menues for player %s in group %s.", self.player[id].playername, self.player[id].groupname)
    env.info(PSEUDOATC.id..text)
    MESSAGE:New(text,30):ToAll()
  end
  
  BASE:E(self.player[id].menu_airports)
  
  if self.player[id].menu_airports then
    for name,item in pairs(self.player[id].menu_airports) do
    
      if self.Debug then
        env.info(PSEUDOATC.id..string.format("Deleting menu item %s for ID %d", name, id))
        BASE:E(item)
      end
      
      missionCommands.removeItemForGroup(id, self.player[id].menu_airports[name])
      --missionCommands.removeItemForGroup(id, item)
    end
    
  else
    if self.Debug then
      local text=string.format("no airports to clear menues")
      env.info(PSEUDOATC.id..text)
    end
  end
 
  if self.player[id].menu_aircraft then
    missionCommands.removeItemForGroup(id, self.player[id].menu_aircraft.main)
  end
  
  self.player[id].menu_airports=nil
  self.player[id].menu_aircraft=nil
end

--- Create "F10/Pseudo ATC" menu items "Airport Data".
-- @param #PSEUDOATC self
-- @param #number id Group id of player unit for which menues are created. 
function PSEUDOATC:MenuAirports(id)
  self:F(id)

  -- Table for menu entries.
  self.player[id].menu_airports={}
   
  local i=0
  for _,airport in pairs(self.player[id].airports) do
  
    i=i+1
    if i>self.maxairport then
      break -- Max X<10 airports due to 10 menu items restriction.
    end 
    
    local name=airport.name
    local d=airport.distance
    local pos=AIRBASE:FindByName(name):GetCoordinate()
    
    --F10menu_ATC_airports[ID][name] = missionCommands.addSubMenuForGroup(ID, name, F10menu_ATC)
    local submenu=missionCommands.addSubMenuForGroup(id, name, self.player[id].menu_main)
    self.player[id].menu_airports[name]=submenu
    
    -- Create menu reporting commands
    missionCommands.addCommandForGroup(id, "Request QFE", submenu, self.ReportPressure, self, id, "QFE", pos, name)
    missionCommands.addCommandForGroup(id, "Request QNH", submenu, self.ReportPressure, self, id, "QNH", pos, name)
    missionCommands.addCommandForGroup(id, "Request Wind", submenu, self.ReportWind, self, id, pos, name)
    missionCommands.addCommandForGroup(id, "Request Temperature", submenu, self.ReportTemperature, self, id, pos, name)
    missionCommands.addCommandForGroup(id, "Request BR", submenu, self.ReportBR, self, id, pos, name)
    
    if self.Debug then
      env.info(string.format(PSEUDOATC.id.."Creating airport menu item %s for ID %d", name, id))
    end
  end
end

--- Create F10/Pseudo ATC menu item "My Plane".
-- @param #PSEUDOATC self
-- @param #number id Group id of player unit for which menues are created. 
function PSEUDOATC:MenuAircraft(id)
  self:F(id)

  -- Table for menu entries.
  self.player[id].menu_aircraft={}

  local unit=self.player[id].unit --Wrapper.Unit#UNIT
  local callsign=self.player[id].callsign
  local name=string.format("My Aircraft (%s)", callsign)
  
  -- Debug info.
  if self.Debug then
    env.info(PSEUDOATC.id..string.format("Creating menu item %s for ID %d", name,id))
  end
  
  -- F10/PseudoATC/My Aircraft (callsign)
  self.player[id].menu_aircraft.main = missionCommands.addSubMenuForGroup(id, name, self.player[id].menu_main)
  
  -- F10/PseudoATC/My Aircraft (callsign)/Waypoints
  if #self.player[id].waypoints>0 then
  
    --F10menu_ATC_waypoints[ID]={}
    self.player[id].menu_aircraft_waypoints={}
    self.player[id].menu_aircraft_waypoints.main=missionCommands.addSubMenuForGroup(id, "Waypoints", self.player[id].menu_aircraft.main)

    local j=0    
    for i, wp in pairs(self.player[id].waypoints) do
      -- Increase counter
      j=j+1
      
      if j>10 then
        break -- max ten menu entries
      end
      
      local pos=COORDINATE:New(wp.x,wp.alt,wp.z)
       
      local fname=string.format("Waypoint %d for %s", i-1, callsign)
      local pname=string.format("Waypoint %d", i-1)
      
      -- "F10/PseudoATC/My Aircraft (callsign)/Waypoints/Waypoint X"
      local submenu=missionCommands.addSubMenuForGroup(id, pname, self.player[id].menu_aircraft_waypoints.main)
      self.player[id].menu_aircraft_waypoints.pname=submenu
      
      -- Menu commands for each waypoint "F10/PseudoATC/My Aircraft (callsign)/Waypoints/Waypoint X/<Commands>"
      missionCommands.addCommandForGroup(id, "Request QFE", submenu, self.ReportPressure, self, id, "QFE", pos, pname)
      missionCommands.addCommandForGroup(id, "Request QNH", submenu, self.ReportPressure, self, id, "QNH", pos, pname)
      missionCommands.addCommandForGroup(id, "Request Wind", submenu, self.ReportWind, self, id, pos, pname)
      missionCommands.addCommandForGroup(id, "Request Temperature", submenu, self.ReportTemperature, self, id, pos, pname)
      missionCommands.addCommandForGroup(id, "Request BR", submenu, self.ReportBR, self, id, pos, pname)
    end
  end
  missionCommands.addCommandForGroup(id, "Request current altitude AGL", self.player[id].menu_aircraft.main, self.ReportHeight, self, id)
  missionCommands.addCommandForGroup(id, "Report altitude until touchdown", self.player[id].menu_aircraft.main, self.AltidudeStartTimer, self, id)
  missionCommands.addCommandForGroup(id, "Quit reporting altitude", self.player[id].menu_aircraft.main, self.AltidudeStopTimer, self, id)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Reporting Functions

--- Report pressure.
-- @param #PSEUDOATC self
-- @param #number id Group id to which the report is delivered.
-- @param #string Qcode Can be "QNH" for pressure at sea level or "QFE" for pressure at field elevation. Default is QFE or more precisely pressure at position.
-- @param Core.Point#COORDINATE position Coordinates at which the pressure is measured.
-- @param #string location Name of the location at which the pressure is measured.
function PSEUDOATC:ReportPressure(id, Qcode, position, location)
  self:F({id=id, Qcode=Qcode, position=position, location=location})

  -- Get pressure in hPa.  
  local P
  if Qcode=="QNH" then
    P=position:GetPressure(0)  -- Get pressure at sea level.
  else
    P=position:GetPressure()   -- Get pressure at (land) height of position.
  end
  
  -- Unit conversion.
  local P_inHg=P * PSEUDOATC.unit.hPa2inHg
  local P_mmHg=P * PSEUDOATC.unit.hPa2mmHg
 
  -- Message text. 
  local text=string.format("%s at %s: P = %.1f hPa = %.2f inHg = %.1f mmHg.", Qcode, location, P, P_inHg, P_mmHg)
  
  -- Send message.
  MESSAGE:New(text, self.mdur):ToGroup(self.player[id].group)
end

--- Report temperature.
-- @param #PSEUDOATC self
-- @param #number id Group id to the report is delivered.
-- @param Core.Point#COORDINATE position Coordinates at which the pressure is measured.
-- @param #string location Name of the location at which the pressure is measured.
function PSEUDOATC:ReportTemperature(id, position, location)
  self:F({id=id, position=position, location=location})

  --- convert celsius to fahrenheit
  local function celsius2fahrenheit(degC)
    return degC*1.8+32
  end
 
  -- Get temperature at position in degrees Celsius. 
  local T=position:GetTemperature()
  
  -- Formatted temperature in Celsius and Fahrenheit.
  local Tc=string.format('%d°C', T)
  local Tf=string.format('%d°F', celsius2fahrenheit(T))
  
  -- Message text.  
  local text=string.format("Temperature at %s is %s = %s", location, Tc, Tf)
  
  -- Send message to player group.  
  MESSAGE:New(text, self.mdur):ToGroup(self.player[id].group)
end

--- Report wind direction and strength.
-- @param #PSEUDOATC self
-- @param #number id Group id to the report is delivered.
-- @param Core.Point#COORDINATE position Coordinates at which the pressure is measured.
-- @param #string location Name of the location at which the pressure is measured.
function PSEUDOATC:ReportWind(id, position, location)
  self:F({id=id, position=position, location=location})

  -- Get wind direction and speed.
  local Dir,Vel=position:GetWind()
  
  -- Get Beaufort wind scale.
  local Bn,Bd=UTILS.BeaufortScale(Vel)
  
  -- Formatted wind direction.
  local Ds = string.format('%03d°', Dir)
  
  -- Message text.
  local text=string.format("%s: Wind from %s at %.1f m/s (%s).", location, Ds, Vel, Bd)
    
  -- Send message to player group.  
  MESSAGE:New(text, self.mdur):ToGroup(self.player[id].group)    
end

--- Report absolute bearing and range form player unit to airport.
-- @param #PSEUDOATC self
-- @param #number id Group id to the report is delivered.
-- @param Core.Point#COORDINATE position Coordinates at which the pressure is measured.
-- @param #string location Name of the location at which the pressure is measured.
function PSEUDOATC:ReportBR(id, position, location)
  self:F({id=id, position=position, location=location})

  -- Current coordinates.
  local unit=self.player[id].unit --Wrapper.Unit#UNIT
  local coord=unit:GetCoordinate()
  
  -- Direction vector from current position (coord) to target (position).
  local vec3=coord:GetDirectionVec3(position)
  local angle=coord:GetAngleDegrees(vec3)
  local range=coord:Get2DDistance(position)
  
  -- Bearing string.
  local Bs=string.format('%03d°', angle)  

  -- Message text.
  local text=string.format("%s: Bearing %s, Range %.1f km = %.1f NM.", location, Bs, range/1000, range/1000 * PSEUDOATC.unit.km2nm)

  -- Send message to player group.  
  MESSAGE:New(text, self.mdur):ToGroup(self.player[id].group)      
end

--- Report altitude above ground level of player unit.
-- @param #PSEUDOATC self
-- @param #number id Group id to the report is delivered.
-- @param #number dt (Optional) Duration the message is displayed.
-- @return #number Altuitude above ground.
function PSEUDOATC:ReportHeight(id, dt)
  self:F({id=id, dt=dt})

  local dt = dt or self.mdur

  -- Return height [m] above ground level.
  local function get_AGL(p)
    local vec2={x=p.x,y=p.z}
    local ground=land.getHeight(vec2)
    local agl=p.y-ground
    return agl
  end

  -- Get height AGL.
  local unit=self.player[id].unit --Wrapper.Unit#UNIT
  local position=unit:GetCoordinate()
  local height=get_AGL(position)
  local callsign=unit:GetCallsign()
  
  -- Message text.
  local text=string.format("%s: Your altitude is %d m = %d ft AGL.", callsign, height, height*PSEUDOATC.unit.meter2feet)
  
  -- Send message to player group.  
  MESSAGE:New(text, dt):ToGroup(self.player[id].group)
  
  -- Return height
  return height        
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start DCS scheduler function.
-- @param #PSEUDOATC self.
-- @param #number id Group id of player unit. 
function PSEUDOATC:AltidudeStartTimer(id)
  self:F(id)
  
  -- Debug info.
  if self.Debug then
    env.info(PSEUDOATC.id..string.format("Starting altitude report timer for player ID %d.", id))
  end
  
  -- Start timer.
  --self.player[id].altimer=timer.scheduleFunction(self.ReportAltTouchdown, self, id, Tnow+2)
  self.player[id].altimer, self.player[id].altimerid=SCHEDULER:New(nil, self.ReportHeight, {self, id, 0.1}, 1, 5)
end

--- Stop/destroy DCS scheduler function for reporting altitude.
-- @param #PSEUDOATC self.
-- @param #number id Group id of player unit. 
function PSEUDOATC:AltidudeStopTimer(id)

  -- Debug info.
  if self.Debug then
    env.info(PSEUDOATC.id..string.format("Stopping altitude report timer for player ID %d.", id))
  end
  
  -- Stop timer.
  --timer.removeFunction(self.player[id].alttimer)
  if self.player[id].altimerid then
    self.player[id].altimer:Stop(self.player[id].altimerid)
  end
  
  self.player[id].altimer=nil
  self.player[id].altimerid=nil
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc

--- Create list of nearby airports sorted by distance to player unit.
-- @param #PSEUDOATC self
-- @param #number id Group id of player unit.
function PSEUDOATC:LocalAirports(id)
  self:F(id)

  -- Airports table.  
  self.player[id].airports=nil
  self.player[id].airports={}
  
  -- Current player position.
  local pos=self.player[id].unit:GetCoordinate()
  
  -- Loop over coalitions.
  for i=0,2 do
    
    -- Get all airbases of coalition.
    local airports=coalition.getAirbases(i)
    
    -- Loop over airbases
    for _,airbase in pairs(airports) do
    
      local name=airbase:getName()
      local q=AIRBASE:FindByName(name):GetCoordinate()
      local d=q:Get2DDistance(pos)
      
      -- Add to table.
      table.insert(self.player[id].airports, {distance=d, name=name})
      
    end
  end
  
  --- compare distance (for sorting airports)
  local function compare(a,b)
    return a.distance < b.distance
  end
  
  -- Sort airports table w.r.t. distance to player.
  table.sort(self.player[id].airports, compare)
  
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #PSEUDOATC self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player.
-- @return #string Name of the player.
-- @return nil If player does not exist.
function PSEUDOATC:_GetPlayerUnitAndName(_unitName)
  self:F(_unitName)

  if _unitName ~= nil then
    local DCSunit=Unit.getByName(_unitName)
    local playername=DCSunit:getPlayerName()
    local unit=UNIT:Find(DCSunit)
    
    if DCSunit and unit and playername then
      return unit, playername
    end
  end
    
  return nil,nil
end



