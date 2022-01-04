--- **Functional** - AI CSAR system
--
-- ## Main Features:
--
--    * Send out helicopters to downed pilots
--    * Rescues players and AI alike
--    * Coalition specific
--    * Starting from a FARP or Airbase
--    * Dedicated MASH zone
--    * Some FSM functions to include in your mission scripts
--
-- ===
--
-- ## Example Missions:
-- 
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/CSR-001%20-%20Basics).
--       
-- ===
-- 
-- ### Author: **applevangelist**
-- 
-- ===
-- @module Functional.AICSAR
-- @image MOOSE.JPG



--- AI CSAR class.
-- @type AICSAR
-- @field #string ClassName Name of this class.
-- @field #string version Versioning.
-- @field #string lid LID for log entries.
-- @field #number coalition Colition side.
-- @field #string template Template for pilot.
-- @field #string helotemplate Template for CSAR helo.
-- @field #string alias Alias Name.
-- @field Wrapper.Airbase#AIRBASE farp FARP object from where to start.
-- @field Core.Zone#ZONE farpzone MASH zone to drop rescued pilots.
-- @field #number maxdistance Max distance to go for a rescue.
-- @field #table pilotqueue Queue of pilots to rescue.
-- @field #number pilotindex Table index to bind pilot to helo.
-- @field #table helos Table of Ops.FlightGroup#FLIGHTGROUP objects
-- @field #boolean verbose Switch more output.
-- @field #number rescuezoneradius Radius around downed pilot for the helo to land in.
-- @field #table rescued Track number of rescued pilot.
-- @field #boolean autoonoff Only send a helo when no human heli pilots are available.
-- @field Core.Set#SET_CLIENT playerset Track if alive heli pilots are available.
-- 
-- @extends Core.Fsm#FSM


--- *I once donated a pint of my finest red corpuscles to the great American Red Cross and the doctor opined my blood was very helpful; contained so much alcohol they could use it to sterilize their instruments.*    
--  W.C.Fields
--
-- ===
--
-- # AICSAR Concept
-- 
-- For an AI or human pilot landing with a parachute, a rescue mission will be spawned. The helicopter will fly to the pilot, pick him or her up,
-- and fly back to a designated MASH (medical) zone, drop the pilot and then return to base.
-- Operational maxdistance can be set as well as the landing radius around the downed pilot.
-- Keep in mind that AI helicopters cannot hover-load at the time of writing, so rescue operations over water or in the mountains might not
-- work.
-- Optionally, if you have a CSAR operation with human pilots in your mission, you can set AICSAR to ignore missions when human helicopter
-- pilots are around.
--
-- ## Setup
-- 
-- Setup is a one-liner:
--            
--            -- @param #string Alias Name of this instance.
--            -- @param #number Coalition Coalition as in coalition.side.BLUE, can also be passed as "blue", "red" or "neutral"
--            -- @param #string Pilottemplate Pilot template name.
--            -- @param #string Helotemplate Helicopter template name.
--            -- @param Wrapper.Airbase#AIRBASE FARP FARP object or Airbase from where to start.
--            -- @param Core.Zone#ZONE MASHZone Zone where to drop pilots after rescue.
--            local my_aicsar=AICSAR:New("Luftrettung",coalition.side.BLUE,"Downed Pilot","Rescue Helo",AIRBASE:FindByName("Test FARP"),ZONE:New("MASH"))
--
-- ## Options are
--  
--            my_aicsar.maxdistance -- maximum operational distance in meters. Defaults to 50NM or 92.6km
--            my_aicsar.rescuezoneradius -- landing zone around downed pilot. Defaults to 200m
--            my_aicsar.autoonoff -- stop operations when human helicopter pilots are around. Defaults to true.
--            my_aicsar.verbose -- messages coalition side about ongoing operations. Defaults to true.
-- 
-- ===
---
--
-- @field #AICSAR
AICSAR = {
  ClassName = "AICSAR",
  version = "0.0.2",
  lid = "",
  coalition = coalition.side.BLUE,
  template = "",
  helotemplate = "",
  alias = "",
  farp = nil,
  farpzone = nil,
  maxdistance = UTILS.NMToMeters(50),
  pilotqueue = {},
  pilotindex = 0,
  helos = {},
  verbose = true,
  rescuezoneradius = 200,
  rescued = {},
  autoonoff = true,
  playerset = nil,
  Messages = {},
  SRS = nil,
  SRSRadio = false,
  SRSFrequency = 243,
  SRSPath = "\\",
  SRSModulation = radio.modulation.AM,
  SRSSoundPath = nil, -- defaults to "l10n/DEFAULT/", i.e. add messages by "Sount to..." in the ME
}

-- TODO Messages
--- Messages enum
-- @field Messages
AICSAR.Messages = {
  INITIALOK = "Roger, Pilot, we hear you. Stay where you are, a helo is on the way!",
  INITIALNOTOK = "Sorry, Pilot. You're behind maximum operational distance! Good Luck!",
  PILOTDOWN = "Pilot down at %s!",
  PILOTKIA = "Pilot KIA!",
  HELODOWN = "CSAR Helo Down!",
  PILOTRESCUED = "Pilot rescued!",
  PILOTINHELO = "Pilot picked up!",
}

-- TODO Radio Messages
--- Radio Messages enum for ogg files
-- @field RadioMessages
AICSAR.RadioMessages = {
  INITIALOK = "initialok.ogg", -- 4.1 secs
  INITIALNOTOK = "initialnotok.ogg", -- 4.6 secs
  PILOTDOWN = "pilotdown.ogg", -- 2.6 secs
  PILOTKIA = "pilotkia.ogg", -- 1.1 sec
  HELODOWN = "helodown.ogg", -- 2.1 secs
  PILOTRESCUED = "pilotrescued.ogg", -- 3.5 secs
  PILOTINHELO = "pilotinhelo.ogg", -- 2.6 secs
}

-- TODO Radio Messages
--- Radio Messages enum for ogg files length in secs
-- @field RadioLength
AICSAR.RadioLength = {
  INITIALOK = 4.1,
  INITIALNOTOK = 4.6, 
  PILOTDOWN = 2.6,
  PILOTKIA = 1.1,
  HELODOWN = 2.1,
  PILOTRESCUED = 3.5,
  PILOTINHELO = 2.6,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function to create a new AICSAR object
-- @param #AICSAR self
-- @param #string Alias Name of this instance.
-- @param #number Coalition Coalition as in coalition.side.BLUE, can also be passed as "blue", "red" or "neutral"
-- @param #string Pilottemplate Pilot template name.
-- @param #string Helotemplate Helicopter template name.
-- @param Wrapper.Airbase#AIRBASE FARP FARP object or Airbase from where to start.
-- @param Core.Zone#ZONE MASHZone Zone where to drop pilots after rescue.
-- @return #AICSAR self
function AICSAR:New(Alias,Coalition,Pilottemplate,Helotemplate,FARP,MASHZone)
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New())
  
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
      self:E("ERROR: Unknown coalition in CSAR!")
    end
  else
    self.coalition = Coalition
    self.coalitiontxt = string.lower(UTILS.GetCoalitionName(self.coalition))
  end
  
    -- Set alias.
  if Alias then
    self.alias=tostring(Alias)
  else
    self.alias="Red Cross"  
    if self.coalition then
      if self.coalition==coalition.side.RED then
        self.alias="IFRC"
      elseif self.coalition==coalition.side.BLUE then
        self.alias="CSAR"
      end
    end
  end
  
  self.template = Pilottemplate
  self.helotemplate = Helotemplate
  self.farp = FARP
  self.farpzone = MASHZone
  self.playerset = SET_CLIENT:New():FilterActive(true):FilterCategories("helicopter"):FilterStart()
  
  -- Radio
  self.SRS = nil
  self.SRSRadio = false
  self.SRSFrequency = 243
  self.SRSPath = "\\"
  self.SRSModulation = radio.modulation.AM
  self.SRSSoundPath = nil -- defaults to "l10n/DEFAULT/", i.e. add messages by "Sound to..." in the ME
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")
  
  -- Start State.
  self:SetStartState("Stopped")
  
    -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- CSAR status update.
  self:AddTransition("*",             "PilotDown",          "*")           -- Pilot down
  self:AddTransition("*",             "PilotPickedUp",      "*")           -- Pilot in helo
  self:AddTransition("*",             "PilotRescued",       "*")           -- Pilot Rescued
  self:AddTransition("*",             "PilotKIA",           "*")           -- Pilot dead
  self:AddTransition("*",             "HeloDown",           "*")           -- Helo dead
  self:AddTransition("*",             "Stop",               "Stopped")     -- Stop FSM.
  
  self:HandleEvent(EVENTS.LandingAfterEjection)
  
  self:__Start(math.random(2,5))
  
  self:I(self.lid .. " AI CSAR Starting")
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Status".
  -- @function [parent=#AICSAR] Status
  -- @param #AICSAR self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#AICSAR] __Status
  -- @param #AICSAR self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop".
  -- @function [parent=#AICSAR] Stop
  -- @param #AICSAR self

  --- Triggers the FSM event "Stop" after a delay.
  -- @function [parent=#AICSAR] __Stop
  -- @param #AICSAR self
  -- @param #number delay Delay in seconds.
  
  --- On after "PilotDown" event.
  -- @function [parent=#AICSAR] OnAfterPilotDown
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Point#COORDINATE Coordinate Location of the pilot.
  -- @param #boolean InReach True if in maxdistance else false. 
  
  --- On after "PilotPickedUp" event.
  -- @function [parent=#AICSAR] OnAfterPilotPickedUp
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.FlightGroup#FLIGHTGROUP Helo
  -- @param #table CargoTable of Ops.OpsGroup#OPSGROUP Cargo objects
  -- @param #number Index  
  
  --- On after "PilotRescued" event.
  -- @function [parent=#AICSAR] OnAfterPilotRescued
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state. 

  --- On after "PilotKIA" event.
  -- @function [parent=#AICSAR] OnAfterPilotKIA
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state. 

  --- On after "HeloDown" event.
  -- @function [parent=#AICSAR] OnAfterHeloDown
  -- @param #AICSAR self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.FlightGroup#FLIGHTGROUP Helo
  -- @param #number Index  
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [User] Switch sound output on and use SRS
-- @param #AICSAR self
-- @param #boolean OnOff Switch on (true) or off (false).
-- @param #string Path Path to your SRS Server Component, e.g. "E:\\\\Program Files\\\\DCS-SimpleRadio-Standalone"
-- @param #number Frequency Defaults to 243 (guard)
-- @param #number Modulation Radio modulation. Defaults to radio.modulation.AM
-- @param #string SoundPath Where to find the audio files. Defaults to nil, i.e. add messages by "Sound to..." in the Mission Editor.
-- @return #AICSAR self
function AICSAR:SetSRSRadio(OnOff,Path,Frequency,Modulation,SoundPath)
  self:T(self.lid .. "SetSRSRadio to "..tostring(OnOff))
  self.SRSRadio = OnOff or true
  self.SRSFrequency = Frequency or 243
  self.SRSPath = Path or "c:\\"
  self.SRSModulation = Modulation or radio.modulation.AM
  self.SRSSoundPath = SoundPath or nil -- defaults to "l10n/DEFAULT/", i.e. add messages by "Sound to..." in the ME
  if OnOff then
    self.SRS = MSRS:New(Path,Frequency,Modulation)
  end
  return self
end

--- [Internal] Catch the landing after ejection and spawn a pilot in situ.
-- @param #AICSAR self
-- @param Core.Event#EVENTDATA EventData
-- @return #AICSAR self
function AICSAR:OnEventLandingAfterEjection(EventData)
  self:T(self.lid .. "OnEventLandingAfterEjection ID=" .. EventData.id)
  
  -- autorescue on off?
  if self.autoonoff then
    if self.playerset:CountAlive() > 0 then
      return self
    end
  end
  
  local _event = EventData -- Core.Event#EVENTDATA
  -- get position and spawn in a template pilot
  local _LandingPos = COORDINATE:NewFromVec3(_event.initiator:getPosition().p)
  local _country = _event.initiator:getCountry()
  local _coalition = coalition.getCountryCoalition( _country )
  
  -- DONE: add distance check
  local distancetofarp = _LandingPos:Get2DDistance(self.farp:GetCoordinate())
  
  if _coalition == self.coalition and distancetofarp <= self.maxdistance then
    self:T(self.lid .. "Spawning new Pilot")
    self.pilotindex = self.pilotindex + 1
    local newpilot = SPAWN:NewWithAlias(self.template,string.format("%s-AICSAR-%d",self.template, self.pilotindex))
    newpilot:InitDelayOff()
    newpilot:OnSpawnGroup(
      function (grp)
        self.pilotqueue[self.pilotindex] = grp
      end
    )    
    newpilot:SpawnFromCoordinate(_LandingPos)
    --self.pilotqueue[self.pilotindex] = newpilot
    Unit.destroy(_event.initiator) -- shagrat remove static Pilot model
    self:__PilotDown(2,_LandingPos,true)
    if self.verbose then
      --local text = "Roger, Pilot, we hear you. Stay where you are, a helo is on the way!"
      local text = AICSAR.Messages.INITIALOK
      MESSAGE:New(text,15,"AICSAR"):ToCoalition(self.coalition)
    end
    if self.SRSRadio then
      local sound = SOUNDFILE:New(AICSAR.RadioMessages.INITIALOK,nil,AICSAR.RadioLength.INITIALOK)
      self.SRS:PlaySoundFile(sound,2)
    end
  elseif _coalition == self.coalition and distancetofarp > self.maxdistance then
    -- apologies, too far off   
    self:T(self.lid .. "Pilot out of reach")
    self:__PilotDown(2,_LandingPos,false)
    if self.verbose then
      local text = AICSAR.Messages.INITIALNOTOK
      --local text = "Sorry, Pilot. You're behind maximum operational distance! Good Luck!"
      MESSAGE:New(text,15,"AICSAR"):ToCoalition(self.coalition)
    end
    if self.SRSRadio then
      local sound = SOUNDFILE:New(AICSAR.RadioMessages.INITIALNOTOK,nil,AICSAR.RadioLength.INITIALNOTOK)
      self.SRS:PlaySoundFile(sound,2)
    end
  end 
  return self
end

--- [Internal] Get FlightGroup
-- @param #AICSAR self
-- @return Ops.FlightGroup#FLIGHTGROUP The FlightGroup
function AICSAR:_GetFlight()
  self:T(self.lid .. "_GetFlight")
  -- Helo Carrier.
  local newhelo = SPAWN:NewWithAlias(self.helotemplate,self.helotemplate..math.random(1,10000))
    :InitDelayOff()
    :InitUnControlled(true)
    :Spawn()
    
  local nhelo=FLIGHTGROUP:New(newhelo)
  nhelo:SetHomebase(self.farp)
  nhelo:Activate()
  return nhelo
end

--- [Internal] Create a new rescue mission
-- @param #AICSAR self
-- @param Wrapper.Group#GROUP Pilot The pilot to be rescued.
-- @param #number Index Index number of this pilot
-- @return #AICSAR self
function AICSAR:_InitMission(Pilot,Index)
  self:T(self.lid .. "_InitMission")
  
  local pickupzone = ZONE_GROUP:New(Pilot:GetName(),Pilot,self.rescuezoneradius)
  --local pilotset = SET_GROUP:New()
  --pilotset:AddGroup(Pilot)
  
    -- Cargo transport assignment.
  local opstransport=OPSTRANSPORT:New(Pilot, pickupzone, self.farpzone)
  
  local helo = self:_GetFlight()
  -- inject reservation
  helo.AICSARReserved = true
  
  -- Cargo transport assignment to first Huey group.
  helo:AddOpsTransport(opstransport)
  
  -- callback functions
  local function AICPickedUp(Helo,Cargo,Index)
    self:__PilotPickedUp(2,Helo,Cargo,Index)   
  end
  
  local function AICHeloDead(Helo,Index)
    self:__HeloDown(2,Helo,Index)   
  end
  
  function helo:OnAfterLoadingDone(From,Event,To)
    AICPickedUp(helo,helo:GetCargoGroups(),Index)   
  end
  
  function helo:OnAfterDead(From,Event,To)
    AICHeloDead(helo,Index)
  end
  
  self.helos[Index] = helo
  
  return self
end

--- [Internal] Check if pilot arrived in rescue zone (MASH)
-- @param #AICSAR self
-- @param Wrapper.Group#GROUP Pilot The pilot to be rescued.
-- @return #boolean outcome
function AICSAR:_CheckInMashZone(Pilot)
  self:T(self.lid .. "_CheckQueue")
  if Pilot:IsInZone(self.farpzone) then
    return true
  else
    return false
  end
end

--- [Internal] Check helo queue 
-- @param #AICSAR self
-- @return #AICSAR self
function AICSAR:_CheckHelos()
  self:T(self.lid .. "_CheckHelos")
  for _index,_helo in pairs(self.helos) do
    local helo = _helo -- Ops.FlightGroup#FLIGHTGROUP
    if helo and helo.ClassName == "FLIGHTGROUP" then
      local state = helo:GetState()
      local name = helo:GetName()
      self:T("Helo group "..name.." in state "..state)
      if state == "Arrived" then
        helo:__Stop(5)
        self.helos[_index] = nil
      end
    else
      self.helos[_index] = nil
    end
  end
  return self
end

--- [Internal] Check pilot queue for next mission
-- @param #AICSAR self
-- @return #AICSAR self
function AICSAR:_CheckQueue()
  self:T(self.lid .. "_CheckQueue")
  for _index, _pilot in pairs(self.pilotqueue) do
    local classname = _pilot.ClassName and _pilot.ClassName or "NONE"
    local name = _pilot.GroupName and _pilot.GroupName or "NONE"
    --self:T("Looking at " .. classname .. " " .. name)
    -- find one w/o mission
    if _pilot and _pilot.ClassName and _pilot.ClassName == "GROUP" then
      -- has no mission assigned?
      if not _pilot.AICSAR then
        _pilot.AICSAR = {}
        _pilot.AICSAR.Status = "Initiated"
        _pilot.AICSAR.Boarded = false
        self:_InitMission(_pilot,_index)
        break
      else 
       -- update status from OPSGROUP
       local flightgroup = self.helos[_index] -- Ops.FlightGroup#FLIGHTGROUP
       if flightgroup then
         local state = flightgroup:GetState()
         _pilot.AICSAR.Status = state
       end
       --self:T("Flight for " .. _pilot.GroupName .. " in state " .. state)
       if self:_CheckInMashZone(_pilot) then
        self:T("Pilot" .. _pilot.GroupName .. " rescued!") 
        _pilot:Destroy(false)
        self.pilotqueue[_index] = nil
        self.rescued[_index] = true
        self:__PilotRescued(2)
        flightgroup.AICSARReserved = false
       end
      end
    end
  end
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [Internal] onafterStart
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AICSAR self
function AICSAR:onafterStart(From, Event, To)
  self:T({From, Event, To})
  self:__Status(3)
  return self
end

--- [Internal] onafterStatus
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AICSAR self
function AICSAR:onafterStatus(From, Event, To)
  self:T({From, Event, To})
  self:_CheckQueue()
  self:_CheckHelos()
  self:__Status(30)
  return self
end

--- [Internal] onafterStop
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AICSAR self
function AICSAR:onafterStop(From, Event, To)
  self:T({From, Event, To})
  self:UnHandleEvent(EVENTS.LandingAfterEjection)
  return self
end

--- [Internal] onafterPilotDown
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Core.Point#COORDINATE Coordinate Location of the pilot.
-- @param #boolean InReach True if in maxdistance else false.
-- @return #AICSAR self
function AICSAR:onafterPilotDown(From, Event, To, Coordinate, InReach)
  self:T({From, Event, To})
  local CoordinateText = Coordinate:ToStringMGRS()
  local inreach = tostring(InReach)
  --local text = string.format("Pilot down at %s. In reach = %s",CoordinateText,inreach)
  
  local text = string.format(AICSAR.Messages.PILOTDOWN,CoordinateText)
  self:T(text)
  if self.verbose then
    MESSAGE:New(text,15,"AICSAR"):ToCoalition(self.coalition)
  end
  if self.SRSRadio then
    local sound = SOUNDFILE:New(AICSAR.RadioMessages.PILOTDOWN,nil,AICSAR.RadioLength.PILOTDOWN)
    self.SRS:PlaySoundFile(sound,2)
  end
  return self
end

--- [Internal] onafterPilotKIA
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AICSAR self
function AICSAR:onafterPilotKIA(From, Event, To)
  self:T({From, Event, To})
  if self.verbose then
    MESSAGE:New(AICSAR.Messages.PILOTKIA,15,"AICSAR"):ToCoalition(self.coalition)
  end
  if self.SRSRadio then
    local sound = SOUNDFILE:New(AICSAR.RadioMessages.PILOTKIA,nil,AICSAR.RadioLength.PILOTKIA)
    self.SRS:PlaySoundFile(sound,2)
  end
  return self
end

--- [Internal] onafterHeloDown
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.FlightGroup#FLIGHTGROUP Helo
-- @param #number Index
-- @return #AICSAR self
function AICSAR:onafterHeloDown(From, Event, To, Helo, Index)
  self:T({From, Event, To})
  if self.verbose then
    MESSAGE:New(AICSAR.Messages.HELODOWN,15,"AICSAR"):ToCoalition(self.coalition)
  end
  if self.SRSRadio then
    local sound = SOUNDFILE:New(AICSAR.RadioMessages.HELODOWN,nil,AICSAR.RadioLength.HELODOWN)
    self.SRS:PlaySoundFile(sound,2)
  end
  local findex = 0
  local fhname = Helo:GetName()
  -- find index of Helo
  if Index and Index > 0 then
    findex=Index
  else
    for _index, _helo in pairs(self.helos) do
      local helo = _helo -- Ops.FlightGroup#FLIGHTGROUP
      local hname = helo:GetName()
      if fhname == hname then
        findex = _index
        break
      end
    end
  end
  -- find pilot
  if findex > 0  and not self.rescued[findex] then
    local pilot = self.pilotqueue[findex]
    self.helos[findex] = nil
    if pilot.AICSAR.Boarded then
      self:T("Helo Down: Found DEAD Pilot ID " .. findex .. " with name " .. pilot:GetName())
      -- pilot also dead
      self:__PilotKIA(2)
      self.pilotqueue[findex] = nil
    else
      -- initiate new mission
      self:T("Helo Down: Found ALIVE Pilot ID " .. findex .. " with name " .. pilot:GetName())
      self:_InitMission(pilot,findex)
    end
  end
  return self
end

--- [Internal] onafterPilotRescued
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AICSAR self
function AICSAR:onafterPilotRescued(From, Event, To)
  self:T({From, Event, To})
  if self.verbose then
    MESSAGE:New(AICSAR.Messages.PILOTRESCUED,15,"AICSAR"):ToCoalition(self.coalition)
  end
  if self.SRSRadio then
    local sound = SOUNDFILE:New(AICSAR.RadioMessages.PILOTRESCUED,nil,AICSAR.RadioLength.PILOTRESCUED)
    self.SRS:PlaySoundFile(sound,2)
  end
  return self
end

--- [Internal] onafterPilotPickedUp
-- @param #AICSAR self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.FlightGroup#FLIGHTGROUP Helo
-- @param #table CargoTable of Ops.OpsGroup#OPSGROUP Cargo objects
-- @param #number Index 
-- @return #AICSAR self
function AICSAR:onafterPilotPickedUp(From, Event, To, Helo, CargoTable, Index)
  self:T({From, Event, To})
  if self.verbose then
    MESSAGE:New(AICSAR.Messages.PILOTINHELO,15,"AICSAR"):ToCoalition(self.coalition)
  end
  if self.SRSRadio then
    local sound = SOUNDFILE:New(AICSAR.RadioMessages.PILOTINHELO,nil,AICSAR.RadioLength.PILOTINHELO)
    self.SRS:PlaySoundFile(sound,2)
  end
  local findex = 0
  local fhname = Helo:GetName()
  if Index and Index > 0 then
    findex = Index
  else
    -- find index of Helo
    for _index, _helo in pairs(self.helos) do
      local helo = _helo -- Ops.FlightGroup#FLIGHTGROUP
      local hname = helo:GetName()
      if fhname == hname then
        findex = _index
        break
      end
    end
  end
  -- find pilot
  if findex > 0  then
    local pilot = self.pilotqueue[findex]
    self:T("Boarded: Found Pilot ID " .. findex .. " with name " .. pilot:GetName())
    pilot.AICSAR.Boarded = true -- mark as boarded
  end
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- END AICSAR
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
