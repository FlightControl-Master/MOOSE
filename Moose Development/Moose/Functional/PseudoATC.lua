--- **Functional** - Rudimentary ATC.
--  
-- ![Banner Image](..\Presentations\PSEUDOATC\PSEUDOATC_Main.jpg)
-- 
-- ====
-- 
-- The pseudo ATC enhances the standard DCS ATC functions.
-- 
-- In particular, a menu entry "Pseudo ATC" is created in the "F10 Other..." radiomenu.
-- 
-- ## Features:
-- 
-- * Weather report at nearby airbases and mission waypoints.
-- * Report absolute bearing and range to nearest airports and mission waypoints.
-- * Report current altitude AGL of own aircraft.
-- * Upon request, ATC reports altitude until touchdown.
-- * Works with static and dynamic weather.
-- * Player can select the unit system (metric or imperial) in which information is reported.
-- * All maps supported (Caucasus, NTTR, Normandy, Persian Gulf and all future maps).
--  
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [MOOSE YouTube Channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: [FlightControl](https://forums.eagle.ru/member.php?u=89536)
-- 
-- ====
-- @module Functional.PseudoATC
-- @image Pseudo_ATC.JPG

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- PSEUDOATC class
-- @type PSEUDOATC
-- @field #string ClassName Name of the Class.
-- @field #table player Table comprising each player info.
-- @field #boolean Debug If true, print debug info to dcs.log file.
-- @field #number mdur Duration in seconds how low messages to the player are displayed.
-- @field #number mrefresh Interval in seconds after which the F10 menu is refreshed. E.g. by the closest airports. Default is 120 sec.
-- @field #number talt Interval in seconds between reporting altitude until touchdown. Default 3 sec.
-- @field #boolean chatty Display some messages on events like take-off and touchdown.
-- @field #boolean eventsmoose If true, events are handled by MOOSE. If false, events are handled directly by DCS eventhandler.
-- @extends Core.Base#BASE

--- Adds some rudimentary ATC functionality via the radio menu.
-- 
-- Local weather reports can be requested for nearby airports and player's mission waypoints.
-- The weather report includes
-- 
-- * QFE and QNH pressures,
-- * Temperature,
-- * Wind direction and strength.
-- 
-- The list of airports is updated every 60 seconds. This interval can be adjusted by the function @{#PSEUDOATC.SetMenuRefresh}(*interval*).
-- 
-- Likewise, absolute bearing and range to the close by airports and mission waypoints can be requested.
-- 
-- The player can switch the unit system in which all information is displayed during the mission with the MOOSE settings radio menu.
-- The unit system can be set to either imperial or metric. Altitudes are reported in feet or meter, distances in kilometers or nautical miles,
-- temperatures in degrees Fahrenheit or Celsius and QFE/QNH pressues in inHg or mmHg.
-- Note that the pressures are also reported in hPa independent of the unit system setting.
-- 
-- In bad weather conditions, the ATC can "talk you down", i.e. will continuously report your altitude on the final approach.
-- Default reporting time interval is 3 seconds. This can be adjusted via the @{#PSEUDOATC.SetReportAltInterval}(*interval*) function.
-- The reporting stops automatically when the player lands or can be stopped manually by clicking on the radio menu item again.
-- So the radio menu item acts as a toggle to switch the reporting on and off.
-- 
-- ## Scripting
-- 
-- Scripting is almost trivial. Just add the following two lines to your script:
-- 
--     pseudoATC=PSEUDOATC:New()
--     pseudoATC:Start()
-- 
-- 
-- @field #PSEUDOATC
PSEUDOATC={
  ClassName = "PSEUDOATC",
  player={},
  Debug=false,
  mdur=30,
  mrefresh=120,
  talt=3,
  chatty=true,
  eventsmoose=true,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
PSEUDOATC.id="PseudoATC | "

--- PSEUDOATC version.
-- @field #number version
PSEUDOATC.version="0.9.1"

-----------------------------------------------------------------------------------------------------------------------------------------

-- TODO list
-- DONE: Add takeoff event.
-- DONE: Add user functions.

-----------------------------------------------------------------------------------------------------------------------------------------

--- PSEUDOATC contructor.
-- @param #PSEUDOATC self
-- @return #PSEUDOATC Returns a PSEUDOATC object.
function PSEUDOATC:New()

  -- Inherit BASE.
  local self=BASE:Inherit(self, BASE:New()) -- #PSEUDOATC
  
  -- Debug info
  self:E(PSEUDOATC.id..string.format("PseudoATC version %s", PSEUDOATC.version))

  -- Return object.
  return self
end

--- Starts the PseudoATC event handlers.
-- @param #PSEUDOATC self
function PSEUDOATC:Start()
  self:F()
  
  -- Debug info
  self:E(PSEUDOATC.id.."Starting PseudoATC")
  
  -- Handle events.
  if self.eventsmoose then
    self:T(PSEUDOATC.id.."Events are handled by MOOSE.")
    self:HandleEvent(EVENTS.Birth,           self._OnBirth)
    self:HandleEvent(EVENTS.Land,            self._PlayerLanded)
    self:HandleEvent(EVENTS.Takeoff,         self._PlayerTakeOff)
    self:HandleEvent(EVENTS.PlayerLeaveUnit, self._PlayerLeft)
    self:HandleEvent(EVENTS.Crash,           self._PlayerLeft)
    --self:HandleEvent(EVENTS.Ejection,        self._PlayerLeft)
    --self:HandleEvent(EVENTS.PilotDead,       self._PlayerLeft)
  else
    self:T(PSEUDOATC.id.."Events are handled by DCS.")
    -- Events are handled directly by DCS.
    world.addEventHandler(self)
  end
  
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- User Functions

--- Debug mode on. Send messages to everone.
-- @param #PSEUDOATC self
function PSEUDOATC:DebugOn()
  self.Debug=true
end

--- Debug mode off. This is the default setting.
-- @param #PSEUDOATC self
function PSEUDOATC:DebugOff()
  self.Debug=false
end

--- Chatty mode on. Display some messages on take-off and touchdown.
-- @param #PSEUDOATC self
function PSEUDOATC:ChattyOn()
  self.chatty=true
end

--- Chatty mode off. Don't display some messages on take-off and touchdown.
-- @param #PSEUDOATC self
function PSEUDOATC:ChattyOff()
  self.chatty=false
end

--- Set duration how long messages are displayed.
-- @param #PSEUDOATC self
-- @param #number duration Time in seconds. Default is 30 sec.
function PSEUDOATC:SetMessageDuration(duration)
  self.mdur=duration or 30
end

--- Set time interval after which the F10 radio menu is refreshed.
-- @param #PSEUDOATC self
-- @param #number interval Interval in seconds. Default is every 120 sec.
function PSEUDOATC:SetMenuRefresh(interval)
  self.mrefresh=interval or 120
end

--- Enable/disable event handling by MOOSE or DCS.
-- @param #PSEUDOATC self
-- @param #boolean switch If true, events are handled by MOOSE (default). If false, events are handled directly by DCS.
function PSEUDOATC:SetEventsMoose(switch)
  self.eventsmoose=switch
end

--- Set time interval for reporting altitude until touchdown.
-- @param #PSEUDOATC self
-- @param #number interval Interval in seconds. Default is every 3 sec.
function PSEUDOATC:SetReportAltInterval(interval)
  self.talt=interval or 3
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
  self:T3(PSEUDOATC.id..string.format("EVENT: Event in onEvent with ID = %s", tostring(Event.id)))
  self:T3(PSEUDOATC.id..string.format("EVENT: Ini unit   = %s" , tostring(EventData.IniUnitName)))
  self:T3(PSEUDOATC.id..string.format("EVENT: Ini group  = %s" , tostring(EventData.IniGroupName)))
  self:T3(PSEUDOATC.id..string.format("EVENT: Ini player = %s" , tostring(_playername)))
  self:T3(PSEUDOATC.id..string.format("EVENT: Place      = %s" , tostring(EventData.PlaceName)))
  self:T3(PSEUDOATC.id..string.format("EVENT: SubPlace   = %s" , tostring(EventData.SubPlaceName)))
  
  -- Event birth.
  if Event.id == world.event.S_EVENT_BIRTH and _playername then
    self:_OnBirth(EventData)
  end
  
  -- Event takeoff.
  if Event.id == world.event.S_EVENT_TAKEOFF and _playername and EventData.Place then
    self:_PlayerTakeOff(EventData)
  end
  
  -- Event land.
  if Event.id == world.event.S_EVENT_LAND and _playername and EventData.Place then
    self:_PlayerLanded(EventData)
  end
  
  -- Event player left unit
  if Event.id == world.event.S_EVENT_PLAYER_LEAVE_UNIT and _playername then
    self:_PlayerLeft(EventData)
  end

  -- Event crash ==> player left unit
  if Event.id == world.event.S_EVENT_CRASH and _playername then
    self:_PlayerLeft(EventData)
  end

--[[
  -- Event eject ==> player left unit
  if Event.id == world.event.S_EVENT_EJECTION and _playername then
    self:_PlayerLeft(EventData)
  end

  -- Event pilot dead ==> player left unit
  if Event.id == world.event.S_EVENT_PILOT_DEAD and _playername then
    self:_PlayerLeft(EventData)
  end
]]    
end

--- Function called my MOOSE event handler when a player enters a unit.
-- @param #PSEUDOATC self
-- @param Core.Event#EVENTDATA EventData
function PSEUDOATC:_OnBirth(EventData)
  self:F({EventData=EventData})
  
  -- Get unit and player.
  local _unitName=EventData.IniUnitName  
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if a player entered.
  if _unit and _playername then
    self:PlayerEntered(_unit)
  end               
 
end

--- Function called by MOOSE event handler when a player leaves a unit or dies. 
-- @param #PSEUDOATC self
-- @param Core.Event#EVENTDATA EventData
function PSEUDOATC:_PlayerLeft(EventData)
  self:F({EventData=EventData})

  -- Get unit and player.
  local _unitName=EventData.IniUnitName  
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if a player left.
  if _unit and _playername then
    self:PlayerLeft(_unit)
  end
end

--- Function called by MOOSE event handler when a player landed. 
-- @param #PSEUDOATC self
-- @param Core.Event#EVENTDATA EventData
function PSEUDOATC:_PlayerLanded(EventData)
  self:F({EventData=EventData})

  -- Get unit, player and place.
  local _unitName=EventData.IniUnitName  
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  local _base=nil
  local _baseName=nil
  if EventData.place then
    _base=EventData.place
    _baseName=EventData.place:getName()
  end
--  if EventData.subplace then
--    local _subPlace=EventData.subplace
--    local _subPlaceName=EventData.subplace:getName()
--  end
  
  -- Call landed function.
  if _unit and _playername and _base then
    self:PlayerLanded(_unit, _baseName)
  end
end

--- Function called by MOOSE/DCS event handler when a player took off. 
-- @param #PSEUDOATC self
-- @param Core.Event#EVENTDATA EventData
function PSEUDOATC:_PlayerTakeOff(EventData)
  self:F({EventData=EventData})

  -- Get unit, player and place.
  local _unitName=EventData.IniUnitName  
  local _unit,_playername=self:_GetPlayerUnitAndName(_unitName)
  local _base=nil
  local _baseName=nil
  if EventData.place then
    _base=EventData.place
    _baseName=EventData.place:getName()
  end
  
  -- Call take-off function.
  if _unit and _playername and _base then
    self:PlayerTakeOff(_unit, _baseName)
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions

--- Function called when a player enters a unit.
-- @param #PSEUDOATC self
-- @param Wrapper.Unit#UNIT unit Unit the player entered.
function PSEUDOATC:PlayerEntered(unit)
  self:F2({unit=unit})

  -- Get player info.
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
  local text=string.format("Player %s entered unit %s of group %s (id=%d).", PlayerName, UnitName, GroupName, GID)
  self:T(PSEUDOATC.id..text)
  MESSAGE:New(text, 30):ToAllIf(self.Debug)
  
  -- Create main F10 menu, i.e. "F10/Pseudo ATC"
  self.player[GID].menu_main=missionCommands.addSubMenuForGroup(GID, "Pseudo ATC")
    
  -- Create/update list of nearby airports.
  self:LocalAirports(GID)
  
  -- Create submenu of local airports.
  self:MenuAirports(GID)
  
  -- Create submenu Waypoints.
  self:MenuWaypoints(GID)
  
  -- Start scheduler to refresh the F10 menues.
  self.player[GID].scheduler, self.player[GID].schedulerid=SCHEDULER:New(nil, self.MenuRefresh, {self, GID}, self.mrefresh, self.mrefresh)
 
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
  local Callsign=self.player[id].callsign
  local UnitName=self.player[id].unitname
  local GroupName=self.player[id].groupname
  local CallSign=self.player[id].callsign
  
  -- Debug message.
  local text=string.format("Player %s in unit %s of group %s (id=%d) landed at %s.", PlayerName, UnitName, GroupName, id, place)
  self:T(PSEUDOATC.id..text)
  MESSAGE:New(text, 30):ToAllIf(self.Debug)
  
  -- Stop altitude reporting timer if its activated.
  self:AltitudeTimerStop(id)
  
  -- Welcome message.
  if place and self.chatty then
    local text=string.format("Touchdown! Welcome to %s. Have a nice day!", place)
    MESSAGE:New(text, self.mdur):ToGroup(group)
  end

end

--- Function called when a player took off.
-- @param #PSEUDOATC self
-- @param Wrapper.Unit#UNIT unit Unit of player which has landed.
-- @param #string place Name of the place the player landed at.
function PSEUDOATC:PlayerTakeOff(unit, place)
  self:F2({unit=unit, place=place})
  
  -- Gather some information.
  local group=unit:GetGroup()
  local id=group:GetID()
  local PlayerName=self.player[id].playername
  local Callsign=self.player[id].callsign
  local UnitName=self.player[id].unitname
  local GroupName=self.player[id].groupname
  local CallSign=self.player[id].callsign
  
  -- Debug message.
  local text=string.format("Player %s in unit %s of group %s (id=%d) took off at %s.", PlayerName, UnitName, GroupName, id, place)
  self:T(PSEUDOATC.id..text)
  MESSAGE:New(text, 30):ToAllIf(self.Debug)
    
  -- Bye-Bye message.
  if place and self.chatty then
    local text=string.format("%s, %s, you are airborne. Have a safe trip!", place, CallSign)
    MESSAGE:New(text, self.mdur):ToGroup(group)
  end

end

--- Function called when a player leaves a unit or dies. 
-- @param #PSEUDOATC self
-- @param Wrapper.Unit#UNIT unit Player unit which was left.
function PSEUDOATC:PlayerLeft(unit)
  self:F({unit=unit})
 
  -- Get id.
  local group=unit:GetGroup()
  local id=group:GetID()
  
  if self.player[id] then
  
    -- Debug message.
    local text=string.format("Player %s (callsign %s) of group %s just left unit %s.", self.player[id].playername, self.player[id].callsign, self.player[id].groupname, self.player[id].unitname)
    self:T(PSEUDOATC.id..text)
    MESSAGE:New(text, 30):ToAllIf(self.Debug)
    
    -- Stop scheduler for menu updates
    if self.player[id].schedulerid then
      self.player[id].scheduler:Stop(self.player[id].schedulerid)
    end
    
    -- Stop scheduler for reporting alt if it runs.
    self:AltitudeTimerStop(id)
    
    -- Remove main menu.
    if self.player[id].menu_main then
      missionCommands.removeItem(self.player[id].menu_main)
    end
  
    -- Remove player array.
    self.player[id]=nil
    
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions

--- Refreshes all player menues.
-- @param #PSEUDOATC self.
-- @param #number id Group id of player unit. 
function PSEUDOATC:MenuRefresh(id)
  self:F({id=id})

  -- Debug message.
  local text=string.format("Refreshing menues for player %s in group %s.", self.player[id].playername, self.player[id].groupname)
  self:T(PSEUDOATC.id..text)
  MESSAGE:New(text,30):ToAllIf(self.Debug)

  -- Clear menu.
  self:MenuClear(id)
  
  -- Create list of nearby airports.
  self:LocalAirports(id)
      
  -- Create submenu Local Airports.
  self:MenuAirports(id)
  
  -- Create submenu Waypoints etc.
  self:MenuWaypoints(id)
  
end


--- Clear player menus.
-- @param #PSEUDOATC self.
-- @param #number id Group id of player unit. 
function PSEUDOATC:MenuClear(id)
  self:F(id)

  -- Debug message.
  local text=string.format("Clearing menus for player %s in group %s.", self.player[id].playername, self.player[id].groupname)
  self:T(PSEUDOATC.id..text)
  MESSAGE:New(text,30):ToAllIf(self.Debug)
  
  -- Delete Airports menu.
  if self.player[id].menu_airports then
    missionCommands.removeItemForGroup(id, self.player[id].menu_airports)
    self.player[id].menu_airports=nil
  else
    self:T2(PSEUDOATC.id.."No airports to clear menus.")
  end
 
  -- Delete waypoints menu.
  if self.player[id].menu_waypoints then
    missionCommands.removeItemForGroup(id, self.player[id].menu_waypoints)
    self.player[id].menu_waypoints=nil
  end
  
  -- Delete report alt until touchdown menu command.
  if self.player[id].menu_reportalt then
    missionCommands.removeItemForGroup(id, self.player[id].menu_reportalt)
    self.player[id].menu_reportalt=nil
  end

  -- Delete request current alt menu command.
  if self.player[id].menu_requestalt then
    missionCommands.removeItemForGroup(id, self.player[id].menu_requestalt)
    self.player[id].menu_requestalt=nil
  end

end

--- Create "F10/Pseudo ATC/Local Airports/Airport Name/" menu items each containing weather report and BR request.
-- @param #PSEUDOATC self
-- @param #number id Group id of player unit for which menues are created. 
function PSEUDOATC:MenuAirports(id)
  self:F(id)

  -- Table for menu entries.
  self.player[id].menu_airports=missionCommands.addSubMenuForGroup(id, "Local Airports", self.player[id].menu_main)
   
  local i=0
  for _,airport in pairs(self.player[id].airports) do
  
    i=i+1
    if i > 10 then
      break -- Max 10 airports due to 10 menu items restriction.
    end 
    
    local name=airport.name
    local d=airport.distance
    local pos=AIRBASE:FindByName(name):GetCoordinate()
    
    --F10menu_ATC_airports[ID][name] = missionCommands.addSubMenuForGroup(ID, name, F10menu_ATC)
    local submenu=missionCommands.addSubMenuForGroup(id, name, self.player[id].menu_airports)
    
    -- Create menu reporting commands
    missionCommands.addCommandForGroup(id, "Weather Report", submenu, self.ReportWeather, self, id, pos, name)
    missionCommands.addCommandForGroup(id, "Request BR", submenu, self.ReportBR, self, id, pos, name)
    
    -- Debug message.
    self:T(string.format(PSEUDOATC.id.."Creating airport menu item %s for ID %d", name, id))
  end
end

--- Create "F10/Pseudo ATC/Waypoints/<Waypoint i>  menu items.
-- @param #PSEUDOATC self
-- @param #number id Group id of player unit for which menues are created. 
function PSEUDOATC:MenuWaypoints(id)
  self:F(id)

  -- Player unit and callsign.
  local unit=self.player[id].unit --Wrapper.Unit#UNIT
  local callsign=self.player[id].callsign
  
  -- Debug info.
  self:T(PSEUDOATC.id..string.format("Creating waypoint menu for %s (ID %d).", callsign, id))
     
  if #self.player[id].waypoints>0 then
  
    -- F10/PseudoATC/Waypoints
    self.player[id].menu_waypoints=missionCommands.addSubMenuForGroup(id, "Waypoints", self.player[id].menu_main)

    local j=0    
    for i, wp in pairs(self.player[id].waypoints) do
    
      -- Increase counter
      j=j+1
      
      if j>10 then
        break -- max ten menu entries
      end
      
      -- Position of Waypoint
      local pos=COORDINATE:New(wp.x, wp.alt, wp.y)
      local name=string.format("Waypoint %d", i-1)
      
      -- "F10/PseudoATC/Waypoints/Waypoint X"
      local submenu=missionCommands.addSubMenuForGroup(id, name, self.player[id].menu_waypoints)
      
      -- Menu commands for each waypoint "F10/PseudoATC/My Aircraft (callsign)/Waypoints/Waypoint X/<Commands>"
      missionCommands.addCommandForGroup(id, "Weather Report", submenu, self.ReportWeather, self, id, pos, name)
      missionCommands.addCommandForGroup(id, "Request BR", submenu, self.ReportBR, self, id, pos, name)
    end
  end
  
  self.player[id].menu_reportalt  = missionCommands.addCommandForGroup(id, "Talk me down",     self.player[id].menu_main, self.AltidudeTimerToggle, self, id)
  self.player[id].menu_requestalt = missionCommands.addCommandForGroup(id, "Request altitude", self.player[id].menu_main, self.ReportHeight, self, id)
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- Reporting Functions

--- Weather Report. Report pressure QFE/QNH, temperature, wind at certain location.
-- @param #PSEUDOATC self
-- @param #number id Group id to which the report is delivered.
-- @param Core.Point#COORDINATE position Coordinates at which the pressure is measured.
-- @param #string location Name of the location at which the pressure is measured.
function PSEUDOATC:ReportWeather(id, position, location)
  self:F({id=id, position=position, location=location})
  
  -- Player unit system settings.
  local settings=_DATABASE:GetPlayerSettings(self.player[id].playername) or _SETTINGS --Core.Settings#SETTINGS
  
  local text=string.format("Local weather at %s:\n", location)
   
  -- Get pressure in hPa.  
  local Pqnh=position:GetPressure(0)  -- Get pressure at sea level.
  local Pqfe=position:GetPressure()   -- Get pressure at (land) height of position.
  
  -- Pressure conversion
  local hPa2inHg=0.0295299830714
  local hPa2mmHg=0.7500615613030
  
  -- Unit conversion.
  local _Pqnh=string.format("%.2f inHg", Pqnh * hPa2inHg)
  local _Pqfe=string.format("%.2f inHg", Pqfe * hPa2inHg)
  if settings:IsMetric() then
    _Pqnh=string.format("%.1f mmHg", Pqnh * hPa2mmHg)
    _Pqfe=string.format("%.1f mmHg", Pqfe * hPa2mmHg)
  end  
 
  -- Message text. 
  text=text..string.format("QFE %.1f hPa = %s.\n", Pqfe, _Pqfe)
  text=text..string.format("QNH %.1f hPa = %s.\n", Pqnh, _Pqnh)
  
  -- Get temperature at position in degrees Celsius. 
  local T=position:GetTemperature()
    
  -- Correct unit system.
  local _T=string.format('%d°F', UTILS.CelciusToFarenheit(T))
  if settings:IsMetric() then
    _T=string.format('%d°C', T)
  end
  
  -- Message text.  
  local text=text..string.format("Temperature %s\n", _T)
  
  -- Get wind direction and speed.
  local Dir,Vel=position:GetWind()
  
  -- Get Beaufort wind scale.
  local Bn,Bd=UTILS.BeaufortScale(Vel)
  
  -- Formatted wind direction.
  local Ds = string.format('%03d°', Dir)
    
  -- Velocity in player units.
  local Vs=string.format("%.1f knots", UTILS.MpsToKnots(Vel))
  if settings:IsMetric() then
    Vs=string.format('%.1f m/s', Vel)  
  end  
  
  -- Message text.
  local text=text..string.format("Wind from %s at %s (%s).", Ds, Vs, Bd)
  
  -- Send message
  self:_DisplayMessageToGroup(self.player[id].unit, text, self.mdur, true)
  
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
  local angle=coord:HeadingTo(position)
  
  -- Range from current to 
  local range=coord:Get2DDistance(position)
  
  -- Bearing string.
  local Bs=string.format('%03d°', angle)
  
  -- Settings.
  local settings=_DATABASE:GetPlayerSettings(self.player[id].playername) or _SETTINGS --Core.Settings#SETTINGS
  
  
  local Rs=string.format("%.1f NM", UTILS.MetersToNM(range))
  if settings:IsMetric() then
    Rs=string.format("%.1f km", range/1000)  
  end

  -- Message text.
  local text=string.format("%s: Bearing %s, Range %s.", location, Bs, Rs)

  -- Send message to player group.  
  MESSAGE:New(text, self.mdur):ToGroup(self.player[id].group)      
end

--- Report altitude above ground level of player unit.
-- @param #PSEUDOATC self
-- @param #number id Group id to the report is delivered.
-- @param #number dt (Optional) Duration the message is displayed.
-- @param #boolean _clear (Optional) Clear previouse messages. 
-- @return #number Altitude above ground.
function PSEUDOATC:ReportHeight(id, dt, _clear)
  self:F({id=id, dt=dt})

  local dt = dt or self.mdur
  if _clear==nil then
    _clear=false
  end

  -- Return height [m] above ground level.
  local function get_AGL(p)
    local agl=0
    local vec2={x=p.x,y=p.z}
    local ground=land.getHeight(vec2)
    local agl=p.y-ground
    return agl
  end

  -- Get height AGL.
  local unit=self.player[id].unit --Wrapper.Unit#UNIT
  
  if unit and unit:IsAlive() then
  
    local position=unit:GetCoordinate()
    local height=get_AGL(position)
    local callsign=unit:GetCallsign()
    
    -- Settings.
    local settings=_DATABASE:GetPlayerSettings(self.player[id].playername) or _SETTINGS --Core.Settings#SETTINGS
    
    -- Height string.
    local Hs=string.format("%d ft", UTILS.MetersToFeet(height))
    if settings:IsMetric() then
      Hs=string.format("%d m", height)
    end
    
    -- Message text.
    local _text=string.format("%s, your altitude is %s AGL.", callsign, Hs)
    
    -- Append flight level.
    if _clear==false then
      _text=_text..string.format(" FL%03d.", position.y/30.48)
    end
    
    -- Send message to player group.  
    self:_DisplayMessageToGroup(self.player[id].unit,_text, dt,_clear)
    
    -- Return height
    return height
  end
  
  return 0        
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Toggle report altitude reporting on/off.
-- @param #PSEUDOATC self.
-- @param #number id Group id of player unit. 
function PSEUDOATC:AltidudeTimerToggle(id)
  self:F(id)
  
  if self.player[id].altimerid then
    -- If the timer is on, we turn it off.
    self:AltitudeTimerStop(id)
  else
    -- If the timer is off, we turn it on.
    self:AltitudeTimeStart(id)
  end
end

--- Start altitude reporting scheduler.
-- @param #PSEUDOATC self.
-- @param #number id Group id of player unit. 
function PSEUDOATC:AltitudeTimeStart(id)
  self:F(id)
  
  -- Debug info.
  self:T(PSEUDOATC.id..string.format("Starting altitude report timer for player ID %d.", id))
  
  -- Start timer. Altitude is reported every ~3 seconds.
  self.player[id].altimer, self.player[id].altimerid=SCHEDULER:New(nil, self.ReportHeight, {self, id, 0.1, true}, 1, 3)
end

--- Stop/destroy DCS scheduler function for reporting altitude.
-- @param #PSEUDOATC self.
-- @param #number id Group id of player unit. 
function PSEUDOATC:AltitudeTimerStop(id)

  -- Debug info.
  self:T(PSEUDOATC.id..string.format("Stopping altitude report timer for player ID %d.", id))
  
  -- Stop timer.
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
  
    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)
    if DCSunit then
    
      -- Get the player name to make sure a player entered.  
      local playername=DCSunit:getPlayerName()
      local unit=UNIT:Find(DCSunit)
      
      -- Debug output.
      self:T2({DCSunit=DCSunit, unit=unit, playername=playername})
      
      if unit and playername then        
        -- Return MOOSE unit and player name
        return unit, playername
      end
      
    end    
  end
    
  return nil,nil
end


--- Display message to group.
-- @param #PSEUDOATC self
-- @param Wrapper.Unit#UNIT _unit Player unit.
-- @param #string _text Message text.
-- @param #number _time Duration how long the message is displayed.
-- @param #boolean _clear Clear up old messages.
function PSEUDOATC:_DisplayMessageToGroup(_unit, _text, _time, _clear)
  self:F({unit=_unit, text=_text, time=_time, clear=_clear})
  
  _time=_time or self.Tmsg
  if _clear==nil then
    _clear=false
  end
  
  -- Group ID.
  local _gid=_unit:GetGroup():GetID()
  
  if _gid then
    if _clear == true then
      trigger.action.outTextForGroup(_gid, _text, _time, _clear)
    else
      trigger.action.outTextForGroup(_gid, _text, _time)
    end
  end
  
end

--- Returns a string which consits of this callsign and the player name.  
-- @param #PSEUDOATC self
-- @param #string unitname Name of the player unit.
function PSEUDOATC:_myname(unitname)
  self:F2(unitname)
  
  local unit=UNIT:FindByName(unitname)
  local pname=unit:GetPlayerName()
  local csign=unit:GetCallsign()
  
  return string.format("%s (%s)", csign, pname)
end

