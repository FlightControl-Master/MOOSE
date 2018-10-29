--- **Functional** - (R2.4) - Carrier CASE I Recovery Practice
-- 
-- Practice carrier landings.
--
-- Features:
--
--    * CASE I recovery.
--    * Performance evaluation.
--    * Feedback about performance during flight.
--
-- Please not that his class is work in progress and in an **alpha** stage.
-- At the moment training parameters are optimized for F/A-18C Hornet as aircraft and USS Stennis as carrier.
-- Other aircraft and carriers **might** be possible in future but would need a different set of parameters.
--
-- ===
--
-- ### Authors: **Bankler** (original idea and script), **funkyfranky** (MOOSE class implementation and enhancements)
--
-- @module Functional.CarrierTrainer
-- @image MOOSE.JPG

--- CARRIERTRAINER class.
-- @type CARRIERTRAINER
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field Wrapper.Unit#UNIT carrier Aircraft carrier unit on which we want to practice.
-- @field #string carriertype Type name of aircraft carrier.
-- @field #string alias Alias of the carrier trainer.
-- @field Core.Zone#ZONE_UNIT startZone Zone in which the pattern approach starts.
-- @field Core.Zone#ZONE_UNIT giantZone Large zone around the carrier to welcome players.
-- @field Core.Zone#ZONE_UNIT registerZone Zone behind the carrier to register for a new approach.
-- @field #table players Table of players. 
-- @field #table menuadded Table of units where the F10 radio menu was added.
-- @field #CARRIERTRAINER.Checkpoint Upwind Upwind checkpoint.
-- @field #CARRIERTRAINER.Checkpoint BreakEarly Early break checkpoint.
-- @field #CARRIERTRAINER.Checkpoint BreakLate Late brak checkpoint.
-- @field #CARRIERTRAINER.Checkpoint Abeam Abeam checkpoint.
-- @field #CARRIERTRAINER.Checkpoint Ninety At the ninety checkpoint.
-- @field #CARRIERTRAINER.Checkpoint Wake Right behind the carrier.
-- @field #CARRIERTRAINER.Checkpoint Groove In the groove checkpoint.
-- @field #CARRIERTRAINER.Checkpoint Trap Landing checkpoint.
-- @field
-- @extends Core.Fsm#FSM

--- Practice Carrier Landings
--
-- ===
--
-- ![Banner Image](..\Presentations\CARRIERTRAINER\CarrierTrainer_Main.png)
--
-- # The Trainer Concept
--
-- bla bla
--
-- @field #CARRIERTRAINER
CARRIERTRAINER = {
  ClassName = "CARRIERTRAINER",
  lid          = nil,
  Debug        = true,
  carrier      = nil,
  carriertype  = nil,
  alias        = nil,
  registerZone = nil,
  startZone    = nil,
  giantZone    = nil,
  players      = {},
  menuadded    = {},
  Upwind       = {},
  Abeam        = {},
  BreakEarly   = {},
  BreakLate    = {},
  Ninety       = {},
  Wake         = {},
  Groove       = {},
  Trap         = {},
  TACAN        = nil,
  ICLS         = nil,
}

--- Aircraft types.
-- @type CARRIERTRAINER.AircraftType
-- @field #string AV8B AV-8B Night Harrier.
-- @field #string HORNET F/A-18C Lot 20 Hornet.
CARRIERTRAINER.AircraftType={
  AV8B="AV8BNA",
  HORNET="FA-18C_hornet",
}

--- Carrier types.
-- @type CARRIERTRAINER.CarrierType
-- @field #string STENNIS USS John C. Stennis (CVN-74)
-- @field #string VINSON USS Carl Vinson (CVN-70)
-- @field #string TARAWA USS Tarawa (LHA-1)
-- @field #string KUZNETSOV Admiral Kuznetsov (CV 1143.5)
CARRIERTRAINER.CarrierType={
  STENNIS="Stennis",
  VINSON="Vinson",
  TARAWA="LHA_Tarawa",
  KUZNETSOV="KUZNECOW"
}

--- LSO calls.
-- @type CARRIERTRAINER.LSOcall
-- @field Core.UserSound#USERSOUND RIGHTFORLINEUPL "Right for line up!" call (loud).
-- @field Core.UserSound#USERSOUND RIGHTFORLINEUPS "Right for line up." call.
-- @field #string RIGHTFORLINEUPT "Right for line up" text.
-- @field Core.UserSound#USERSOUND COMELEFTL "Come left!" call (loud).
-- @field Core.UserSound#USERSOUND COMELEFTS "Come left." call.
-- @field #string COMELEFTT "Come left" text.
-- @field Core.UserSound#USERSOUND HIGHL "You're high!" call (loud).
-- @field Core.UserSound#USERSOUND HIGHS "You're high." call.
-- @field #string HIGHT "You're high" text.
-- @field Core.UserSound#USERSOUND POWERL "Power!" call (loud).
-- @field Core.UserSound#USERSOUND POWERS "Power." call.
-- @field #string POWERT "Power" text.
-- @field Core.UserSound#USERSOUND CALLTHEBALL "Call the ball." call.
-- @field #string CALLTHEBALLT "Call the ball." text.
-- @field Core.UserSound#USERSOUND ROGERBALL "Roger, ball." call.
-- @field #string ROGERBALLT "Roger, ball." text.
-- @field Core.UserSound#USERSOUND WAVEOFF "Wave off!" call.
-- @field #string WAVEOFFT "Wave off!" text.
-- @field Core.UserSound#USERSOUND BOLTER "Bolter, bolter!" call.
-- @field #string BOLTERT "Bolter, bolter!" text.
-- @field Core.UserSound#USERSOUND LONGGROOVE "You're long in the groove. Depart and re-enter." call.
-- @field #string LONGGROOVET "You're long in the groove. Depart and re-enter." text.
CARRIERTRAINER.LSOcall={
  RIGHTFORLINEUPL=USERSOUND:New("LSO - RightLineUp(L).ogg"),
  RIGHTFORLINEUPS=USERSOUND:New("LSO - RightLineUp(S).ogg"),
  RIGHTFORLINEUPT="Right for line up",
  COMELEFTL=USERSOUND:New("LSO - ComeLeft(L).ogg"),
  COMELEFTS=USERSOUND:New("LSO - ComeLeft(S).ogg"),
  COMELEFTT="Come left",
  HIGHL=USERSOUND:New("LSO - High(L).ogg"),
  HIGHS=USERSOUND:New("LSO - High(S).ogg"),
  HIGHT="You're high",
  POWERL=USERSOUND:New("LSO - Power(L).ogg"),
  POWERS=USERSOUND:New("LSO - Power(S).ogg"),
  POWERT="Power",
  CALLTHEBALL=USERSOUND:New("LSO - Call the Ball.ogg"),
  CALLTHEBALLT="Call the ball.",
  ROGERBALL=USERSOUND:New("LSO - Roger.ogg"),
  ROGERBALLT="Roger ball!",
  WAVEOFF=USERSOUND:New("LSO - WaveOff.ogg"),
  WAVEOFFT="Wave off!",
  BOLTER=USERSOUND:New("LSO - Bolter.ogg"),
  BOLTERT="Bolter, Bolter!",
  LONGGROOVE=USERSOUND:New("LSO - Long in Groove.ogg"),
  LONGGROOVET="You're lon in the groove. Depart and re-enter.",
}

--- Difficulty level.
-- @type CARRIERTRAINER.Difficulty
-- @field #string EASY Easy difficulty: error margin 10 for high score and 20 for low score. No score for deviation >20.
-- @field #string NORMAL Normal difficulty: error margin 5 deviation from ideal for high score and 10 for low score. No score for deviation >10.
-- @field #string HARD Hard difficulty: error margin 2.5 deviation from ideal value for high score and 5 for low score. No score for deviation >5.
CARRIERTRAINER.Difficulty={
  EASY="Rookey",
  NORMAL="Naval Aviator",
  HARD="TOPGUN Graduate",
}

--- Player data table holding all important parameters for each player.
-- @type CARRIERTRAINER.PlayerData
-- @field #number id Player ID.
-- @field Wrapper.Unit#UNIT unit Aircraft unit of the player.
-- @field #string callsign Callsign of player.
-- @field #number score Player score of the current pass.
-- @field #number passes Number of passes.
-- @field #table debrief Debrief analysis of the current step of this pass.
-- @field #table results Results of all passes.
-- @field Wrapper.Client#CLIENT client object of player.
-- @field #string difficulty Difficulty level.
-- @field #boolean inbigzone If true, player is in the big zone.
-- @field #boolean landed If true, player landed or attempted to land.
-- @field #boolean boltered If true, player boltered.
-- @field #boolean waveoff If true, player was waved off.
-- @field #boolean calledball If true, player called the ball.
-- @field #number Tlso Last time the LSO gave an advice.

--- Checkpoint parameters triggering the next step in the pattern.
-- @type CARRIERTRAINER.Checkpoint
-- @field #string name Name of checkpoint.
-- @field #number Xmin Minimum allowed longitual distance to carrier.
-- @field #number Xmax Maximum allowed longitual distance to carrier.
-- @field #number Zmin Minimum allowed latitudal distance to carrier.
-- @field #number Zmax Maximum allowed latitudal distance to carrier.
-- @field #number LimitXmin Latitudal threshold for triggering the next step if X<Xmin.
-- @field #number LimitXmax Latitudal threshold for triggering the next step if X>Xmax.
-- @field #number LimitZmin Latitudal threshold for triggering the next step if Z<Zmin.
-- @field #number LimitZmax Latitudal threshold for triggering the next step if Z>Zmax.
-- @field #number Altitude Optimal altitude at this point.
-- @field #number AoA Optimal AoA at this point.
-- @field #number Distance Optimal distance at this point.
-- @field #number Speed Optimal speed at this point.
-- @field #table Checklist Table of checklist text items to display at this point.

--- Main radio menu.
-- @field #table MenuF10
CARRIERTRAINER.MenuF10={}

--- Carrier trainer class version.
-- @field #string version
CARRIERTRAINER.version="0.1.2w"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create new carrier trainer.
-- @param #CARRIERTRAINER self
-- @param carriername Name of the aircraft carrier unit as defined in the mission editor.
-- @param alias (Optional) Alias for the carrier. This will be used for radio messages and the F10 radius menu. Default is the carrier name as defined in the mission editor.
-- @return #CARRIERTRAINER self
function CARRIERTRAINER:New(carriername, alias)

  -- Inherit everthing from FSM class.
  local self = BASE:Inherit(self, FSM:New()) -- #CARRIERTRAINER

  -- Set carrier unit.
  self.carrier=UNIT:FindByName(carriername)
  
  if self.carrier then
    self.registerZone = ZONE_UNIT:New("registerZone", self.carrier,  2500, {dx = -5000, dy = 100, relative_to_unit=true})
    self.startZone    = ZONE_UNIT:New("startZone",    self.carrier,  1000, {dx = -2000, dy = 100, relative_to_unit=true})
    self.giantZone    = ZONE_UNIT:New("giantZone",    self.carrier, 30000, {dx =  0,    dy = 0,   relative_to_unit=true})
  else
    local text=string.format("ERROR: Carrier unit %s could not be found! Make sure this UNIT is defined in the mission editor and check the spelling of the unit name carefully.", carriername)
    MESSAGE:New(text, 120):ToAll()
    self:E(self.lid..text)
    return nil
  end
    
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("CARRIERTRAINER %s | ", carriername)
  
  -- Get carrier type.
  self.carriertype=self.carrier:GetTypeName()
  
  -- Set alias.
  self.alias=alias or carriername
  
  if self.carriertype==CARRIERTRAINER.CarrierType.STENNIS then
    self:_InitStennis()
  elseif self.carriertype==CARRIERTRAINER.CarrierType.VINSON then
    -- TODO: Carl Vinson parameters.
    self:_InitStennis()
  elseif self.carriertype==CARRIERTRAINER.CarrierType.TARAWA then
    -- TODO: Tarawa parameters.
    self:_InitStennis()
  elseif self.carriertype==CARRIERTRAINER.CarrierType.KUZNETSOV then
    -- TODO: Kusnetsov parameters - maybe...
    self:_InitStennis()
  else
    self:E(self.lid.."ERROR: Unknown carrier type!")
    return nil
  end
  
  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event   -->   To State
  self:AddTransition("Stopped",       "Start",      "Running")
  self:AddTransition("Running",       "Status",     "Running")
  self:AddTransition("Running",       "Stop",       "Stopped")


  --- Triggers the FSM event "Start" that starts the carrier trainer. Initializes parameters and starts event handlers.
  -- @function [parent=#CARRIERTRAINER] Start
  -- @param #CARRIERTRAINER self

  --- Triggers the FSM event "Start" after a delay that starts the carrier trainer. Initializes parameters and starts event handlers.
  -- @function [parent=#CARRIERTRAINER] __Start
  -- @param #CARRIERTRAINER self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop" that stops the carrier trainer. Event handlers are stopped.
  -- @function [parent=#CARRIERTRAINER] Stop
  -- @param #CARRIERTRAINER self

  --- Triggers the FSM event "Stop" that stops the carrier trainer after a delay. Event handlers are stopped.
  -- @function [parent=#CARRIERTRAINER] __Stop
  -- @param #CARRIERTRAINER self
  -- @param #number delay Delay in seconds.
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM states
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the warehouse. Addes event handlers and schedules status updates of reqests and queue.
-- @param #CARRIERTRAINER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function CARRIERTRAINER:onafterStart(From, Event, To)

  -- Events are handled my MOOSE.
  self:I(self.lid..string.format("Starting Carrier Training %s for carrier unit %s of type %s.", CARRIERTRAINER.version, self.carrier:GetName(), self.carriertype))
  
  -- Handle events.
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.Land)

  -- Init status check
  self:__Status(5)
end

--- On after Status event. Checks player status.
-- @param #CARRIERTRAINER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function CARRIERTRAINER:onafterStatus(From, Event, To)

  -- Check player status.
  self:_CheckPlayerStatus()

  -- Call status again in one second.
  self:__Status(-1)
end

--- On after Stop event. Unhandle events and stop status updates. 
-- @param #CARRIERTRAINER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function CARRIERTRAINER:onafterStop(From, Event, To)
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.Land)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENT functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Carrier trainer event handler for event birth.
-- @param #CARRIERTRAINER self
-- @param Core.Event#EVENTDATA EventData
function CARRIERTRAINER:OnEventBirth(EventData)
  self:F3({eventbirth = EventData})
  
  local _unitName=EventData.IniUnitName
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  self:T3(self.lid.."BIRTH: unit   = "..tostring(EventData.IniUnitName))
  self:T3(self.lid.."BIRTH: group  = "..tostring(EventData.IniGroupName))
  self:T3(self.lid.."BIRTH: player = "..tostring(_playername))
      
  if _unit and _playername then
  
    local _uid=_unit:GetID()
    local _group=_unit:GetGroup()
    local _callsign=_unit:GetCallsign()
    
    -- Debug output.
    local text=string.format("Player %s, callsign %s entered unit %s (ID=%d) of group %s", _playername, _callsign, _unitName, _uid, _group:GetName())
    self:T(self.lid..text)
    MESSAGE:New(text, 5):ToAllIf(self.Debug)
    
    -- Add Menu commands.
    self:_AddF10Commands(_unitName)    
    
    -- Init player.
    if self.players[_playername]==nil then
      self.players[_playername]=self:_InitNewPlayer(_unitName)
    else
      self:_InitNewRound(self.players[_playername])
    end
    
    -- Test
    CARRIERTRAINER.LSOcall.HIGHL:ToGroup(_group)
      
  end 
end

--- Carrier trainer event handler for event land.
-- @param #CARRIERTRAINER self
-- @param Core.Event#EVENTDATA EventData
function CARRIERTRAINER:OnEventLand(EventData)
  self:F3({eventland = EventData})
  
  local _unitName=EventData.IniUnitName
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  self:T3(self.lid.."LAND: unit   = "..tostring(EventData.IniUnitName))
  self:T3(self.lid.."LAND: group  = "..tostring(EventData.IniGroupName))
  self:T3(self.lid.."LAND: player = "..tostring(_playername))
      
  if _unit and _playername then
  
    local _uid=_unit:GetID()
    local _group=_unit:GetGroup()
    local _callsign=_unit:GetCallsign()
    
    -- Debug output.
    local text=string.format("Player %s, callsign %s unit %s (ID=%d) of group %s landed.", _playername, _callsign, _unitName, _uid, _group:GetName())
    self:T(self.lid..text)
    MESSAGE:New(text, 5):ToAllIf(self.Debug)
    
    -- Check if we caught a wire after one second.
    -- TODO: test this!
    local playerData=self.players[_playername] --#CARRIERTRAINER.PlayerData
    local coord=playerData.unit:GetCoordinate()
    
    -- We did land.
    playerData.landed=true
    
    --TODO: maybe check that we actually landed on the right carrier.
    
    -- Call trapped function in 5 seconds to make sure we did not bolter.
    SCHEDULER:New(nil, self._Trapped,{self, playerData, coord}, 5)
      
  end 
end

--- Initialize player data.
-- @param #CARRIERTRAINER self
-- @param #string unitname Name of the player unit.
-- @return #CARRIERTRAINER.PlayerData Player data.
function CARRIERTRAINER:_InitNewPlayer(unitname) 

  local playerData={} --#CARRIERTRAINER.PlayerData
  
  -- Player unit, client and callsign.
  playerData.unit = UNIT:FindByName(unitname)
  playerData.client = CLIENT:FindByName(playerData.unit.UnitName, nil, true)
  playerData.callsign = playerData.unit:GetCallsign()
  
  playerData.totalscore = 0
  
  -- Number of passes done by player.
  playerData.passes=0
    
  playerData.results={}
  
  -- Set difficulty level.
  playerData.difficulty=CARRIERTRAINER.Difficulty.NORMAL
  
  -- Player is in the big zone around the carrier.
  playerData.inbigzone=playerData.unit:IsInZone(self.giantZone)

  -- Init stuff for this round.
  playerData=self:_InitNewRound(playerData)
  
  return playerData
end

--- Initialize new approach for player by resetting parmeters to initial values.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @return #CARRIERTRAINER.PlayerData Initialized player data.
function CARRIERTRAINER:_InitNewRound(playerData)
  playerData.step=0
  playerData.score=100
  playerData.grade={}
  playerData.debrief={}
  playerData.longDownwindDone=false
  playerData.boltered=false
  playerData.landed=false
  playerData.waveoff=false
  playerData.calledball=false
  playerData.Tlso=timer.getTime()
  return playerData
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CARRIER TRAINING functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Initialize player data.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
function CARRIERTRAINER:_NewRound(playerData) 
    
  if playerData.unit:IsInZone(self.registerZone) then
    local text="Cleared for approach."
    self:_SendMessageToPlayer(text, 10,playerData)
  
    self:_InitNewRound(playerData)
  
    -- Next step: start of pattern.
    playerData.step=1
  end
end

--- Start landing pattern, when player enters the start zone.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_Start(playerData)

  if playerData.unit:IsInZone(self.startZone) then
  
    local hint = string.format("Entering the pattern, %s! Aim for 800 feet and 350 kts in the break entry.", playerData.callsign)
    self:_SendMessageToPlayer(hint, 8, playerData)
  
    -- Next step: upwind.
    playerData.step=2
  end
  
end 

--- Upwind leg.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_Upwind(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ = self:_GetDistances(playerData.unit)
  
  -- Abort condition check.
  if self:_CheckAbort(diffX,diffZ, self.Upwind) then
    self:_AbortPattern(playerData, diffX, diffZ, self.Upwind)
    return
  end
  
  -- Check if we are in front of the boat (diffX > 0).
  if self:_CheckLimits(diffX, diffZ, self.Upwind) then
  
    local altitude=playerData.unit:GetAltitude()
  
    -- Get altitude.
    local hint=self:_AltitudeCheck(playerData, self.Upwind, altitude)
        
    -- Message to player
    self:_SendMessageToPlayer(hint, 8, playerData)
    
    -- Debrief.
    self:_AddToSummary(playerData, "Entering the Break", hint)
    
    -- Next step.
    playerData.step=3
  end
end


--- Break.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
-- @param #string part Part of the break.
function CARRIERTRAINER:_Break(playerData, part)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ = self:_GetDistances(playerData.unit)
  
  -- Early or late break.  
  local breakpoint = self.BreakEarly
  if part == "late" then
    breakpoint = self.BreakLate
  end
    
  -- Check abort conditions.
  if self:_CheckAbort(diffX, diffZ, breakpoint) then
    self:_AbortPattern(playerData, diffX, diffZ, breakpoint)
    return
  end

  -- Check limits.
  if self:_CheckLimits(diffX, diffZ, breakpoint) then
  
    -- Get current altitude.
    local altitude=playerData.unit:GetAltitude()
  
    -- Grade altitude.
    local hint=self:_AltitudeCheck(playerData, breakpoint, altitude)
    
    -- Send message to player.
    self:_SendMessageToPlayer(hint, 10, playerData)

    -- Debrief
    if part =="late" then
      self:_AddToSummary(playerData, "Late Break", hint)
    else
      self:_AddToSummary(playerData, "Early Entry", hint)
    end

    -- Nest step: late break or abeam.
    if (part == "early") then
      playerData.step = 4
    else
      playerData.step = 5
    end
  end
end

--- Long downwind leg check.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_CheckForLongDownwind(playerData)
  
  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ = self:_GetDistances(playerData.unit)

  -- Get relative heading.
  local relhead=self:_GetRelativeHeading(playerData.unit)

  -- One NM from carrier is way too far.  
  local limit = -UTILS.NMToMeters(1)
  
  local text=string.format("Long groove check: diffX=%d, relhead=%.1f", diffX, relhead)
  self:T(text)
  --MESSAGE:New(text, 1):ToAllIf(self.Debug)
  
  -- Check we are not too far out w.r.t back of the boat.
  if diffX<limit and relhead<45 then
    -- Message to player.
    local hint = "Your downwind leg is too long. Turn to final earlier next time."
    self:_SendMessageToPlayer(hint, 10, playerData)
    
    -- Sound output.
    CARRIERTRAINER.LSOcall.LONGGROOVE:ToGroup(playerData.unit:GetGroup())
    
    -- Debrief.
    self:_AddToSummary(playerData, "Long Downwind Leg", hint)
    
    -- Decrease score.
    playerData.score=playerData.score-40
    
    -- Long downwind done!
    playerData.longDownwindDone = true
    
    -- Next step: Debriefing.
    playerData.step=99
    
  end
  
end


--- Abeam.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_Abeam(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ = self:_GetDistances(playerData.unit)
  
  -- Check abort conditions.
  if self:_CheckAbort(diffX, diffZ, self.Abeam) then
    self:_AbortPattern(playerData, diffX, diffZ, self.Abeam)
    return
  end

  -- Check nest step threshold.  
  if self:_CheckLimits(diffX, diffZ, self.Abeam) then
  
    -- Checks:
    -- AoA
    -- Altitude
    -- Distance to carrier.

    -- Get AoA.
    local aoa = playerData.unit:GetAoA()
    local alt = playerData.unit:GetAltitude()
    
    -- Grade AoA.
    local hintAoA=self:_AoACheck(playerData, self.Abeam, aoa)
    
    -- Grade Altitude.
    local hintAlt=self:_AltitudeCheck(playerData, self.Abeam, alt)
    
    -- Grade distance to carrier.
    local hintDist=self:_DistanceCheck(playerData, self.Abeam, math.abs(diffZ))
    
    -- Compile full hint.
    local hintFull=string.format("%s\n%s\n%s", hintAlt, hintAoA, hintDist)
    
    -- Send message to playerr.
    self:_SendMessageToPlayer(hintFull, 10, playerData)
    
    -- Add to debrief.
    self:_AddToSummary(playerData, "Abeam Position", hintFull)
    
    -- Proceed to next step.
    playerData.step = 6
  end
end

--- Ninety.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_Ninety(playerData) 
  
  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ = self:_GetDistances(playerData.unit)
  
  --if(diffZ < -3700 or diffX < -3700 or diffX > 0) then
  if self:_CheckAbort(diffX, diffZ, self.Ninety) then
    self:_AbortPattern(playerData, diffX, diffZ, self.Ninety)
    return
  end
  
  -- Get Realtive heading player to carrier.
  local relheading=self:_GetRelativeHeading(playerData.unit)
  
  -- At the 90, i.e. 90 degrees between player heading and BRC of carrier.
  if relheading<=90 then
  
    local alt=playerData.unit:GetAltitude()
    local aoa=playerData.unit:GetAoA()
    
    -- Grade altitude.
    local hintAlt=self:_AltitudeCheck(playerData, self.Ninety, alt)
    
    -- Grade AoA.
    local hintAoA=self:_AoACheck(playerData, self.Ninety, aoa)
    
    -- Compile full hint.
    local hintFull=string.format("%s\n%s", hintAlt, hintAoA)
    
    -- Message to player.
    self:_SendMessageToPlayer(hintFull, 10, playerData)
    
    -- Add to debrief.
    self:_AddToSummary(playerData, "At the 90", hintFull)
    
    -- Long downwind not an issue any more
    playerData.longDownwindDone = true
    
    -- Next step: wake.
    playerData.step = 7
  end
end

--- Wake.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_Wake(playerData) 

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ = self:_GetDistances(playerData.unit)
    
  -- Check abort conditions.
  if self:_CheckAbort(diffX, diffZ, self.Wake) then
    self:_AbortPattern(playerData, diffX, diffZ, self.Wake)
    return
  end
  
  -- Right behind the wake of the carrier dZ>0.
  if self:_CheckLimits(diffX, diffZ, self.Wake) then
  
    local alt=playerData.unit:GetAltitude()
    local aoa=playerData.unit:GetAoA()
  
    -- Grade altitude.
    local hintAlt=self:_AltitudeCheck(playerData, self.Wake, alt)
    
    -- Grade AoA.
    local hintAoA=self:_AoACheck(playerData, self.Wake, aoa)

    -- Compile full hint.
    local hintFull=string.format("%s\n%s", hintAlt, hintAoA)

    -- Message to player.
    self:_SendMessageToPlayer(hintFull, 10, playerData)
    
    -- Add to debrief.
    self:_AddToSummary(playerData, "At the Wake", hintFull)

    -- Next step: Groove.
    playerData.step = 8
  end
end

--- Entering the Groove.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_Groove(playerData)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ = self:_GetDistances(playerData.unit)

  -- In front of carrier or more than 4 km behind carrier. 
  if self:_CheckAbort(diffX, diffZ, self.Groove) then
    self:_AbortPattern(playerData, diffX, diffZ, self.Groove)
    return
  end

  -- Get heading of runway.  
  local brc=self.carrier:GetHeading()
  local rwy=brc-10 --runway heading is -10 degree from carrier BRC. 
  if rwy<0 then
    rwy=rwy+360
  end
  -- Radial (inverse heading).
  rwy=rwy-180
  
  -- 0 means player is on BRC course but runway heading is -10 degrees.
  local heading=self:_GetRelativeHeading(playerData.unit)-10
  
  if diffZ>-1300 and heading<10 then

    local alt = playerData.unit:GetAltitude()
    local aoa = playerData.unit:GetAoA()

    -- Grade altitude.
    local hintAlt=self:_AltitudeCheck(playerData, self.Groove, alt)

    -- AoA feed back 
    local hintAoA=self:_AoACheck(playerData, self.Groove, aoa)
    
    -- Compile full hint.
    local hintFull=string.format("%s\n%s", hintAlt, hintAoA)

    -- Message to player.
    self:_SendMessageToPlayer(hintFull, 10, playerData)

    -- Add to debrief.
    self:_AddToSummary(playerData, "Entering the Groove", hintFull)
    
    -- Next step.
    playerData.step = 9
  end

end

--- Call the ball, i.e. 3/4 NM distance between aircraft and carrier.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_CallTheBall(playerData) 

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ, rho, phi = self:_GetDistances(playerData.unit)
  
  -- Player altitude
  local alt=playerData.unit:GetAltitude()
  
  -- Player group.
  local player=playerData.unit:GetGroup()  

  -- Get velocities.
  local playerVelocity  = playerData.unit:GetVelocityKMH()
  local carrierVelocity = self.carrier:GetVelocityKMH()

  -- Check abort conditions.
  if self:_CheckAbort(diffX, diffZ, self.Trap) then
    self:_AbortPattern(playerData, diffX, diffZ, self.Trap)
    return
  end
  
  -- Runway is at an angle of -10 degrees wrt to carrier X direction.
  -- TODO: make this carrier dependent
  local rwyangle=-10
  local deckheight=22
  local tailpos=-100
  
  -- Position at the end of the deck. From there we calculate the angle.
  -- TODO: Check exact number and make carrier dependent.
  local b={}
  b.x=tailpos
  b.z=0
  
  -- Position of the aircraft wrt carrier coordinates.
  local a={}
  a.x=diffX
  a.z=diffZ
  
  --a.x=-200
  --a.y=  0
  --a.z=17.632698070846  --(100)*math.tan(math.rad(10))
  --a.z=20
  --print(a.z)
  
  -- Vector from plane to ref point on boad.
  local c={}
  c.x=b.x-a.x
  c.z=b.z-a.z
  
  -- Current line up and error wrt to final heading of the runway.
  local lineup=math.atan2(c.z, c.x)
  local lineuperror=math.deg(lineup)-rwyangle
  
  if lineuperror<0 then
    env.info("come left")
  elseif lineuperror>0 then
    env.info("Right for lineup")
  end  

  -- Glideslope. Wee need to correct for the height of the deck. The ideal glide slope is 3.5 degrees.
  local h=playerData.unit:GetAltitude()-deckheight
  local x=math.abs(diffX-tailpos)
  local glideslope=math.atan(h/x)  
  local glideslopeError=math.deg(glideslope) - 3.5
  
  if diffX>-UTILS.NMToMeters(0.75) and diffX<-100 and playerData.calledball==false then
    self:_SendMessageToPlayer("Call the ball.", 8, playerData)
    playerData.calledball=true
    CARRIERTRAINER.LSOcall.CALLTHEBALL:ToGroup(player)
    return
  end
  
  -- Time since last LSO call.
  local time=timer.getTime()
  local deltaT=time-playerData.Tlso
  
  
  -- Check if we are beween 3/4 NM and end of ship.
  if diffX>-UTILS.NMToMeters(0.75) and diffX<-100 and deltaT>=3 then
  
    local text=""
    
    -- Glideslope high/low calls.
    if glideslopeError>1 then
      text="You're too high! Throttles back!"
      CARRIERTRAINER.LSOcall.HIGHL:ToGroup(player)
    elseif glideslopeError>0.5 then
      text="You're slightly high. Decrease power."
      CARRIERTRAINER.LSOcall.HIGHS:ToGroup(player)
    elseif glideslopeError<1.0 then
      text="Power! You're way too low."
      CARRIERTRAINER.LSOcall.POWERL:ToGroup(player)
    elseif glideslopeError<0.5 then
      text="You're slightly low. Increase power."
      CARRIERTRAINER.LSOcall.POWERS:ToGroup(player)
    else
      text="Good altitude."
    end
    
    -- Lineup left/right calls.
    if lineuperror<3 then
      text=text.."Come left!"
      CARRIERTRAINER.LSOcall.COMELEFTL:ToGroup(player)
    elseif lineuperror<1 then
      text=text.."Come left."
      CARRIERTRAINER.LSOcall.COMELEFTS:ToGroup(player)
    elseif lineuperror>3 then
      text=text.."Right for lineup!"
      CARRIERTRAINER.LSOcall.RIGHTFORLINEUPL:ToGroup(player)
    elseif lineuperror>1 then
      text=text.."Right for lineup."
      CARRIERTRAINER.LSOcall.RIGHTFORLINEUPS:ToGroup(player)
    else
      text=text.."Good lineup."
    end
    
    -- LSO Message to player.
    self:_SendMessageToPlayer(text, 8, playerData, true)
    
    -- Set last time.
    playerData.Tlso=time
    
  elseif diffX > 150 then
    
    local wire  = 0
    local hint  = ""
    local score = 0
    if playerData.landed then
      hint  = "You boltered."
    else
      hint  = "You were waved off."
      wire  = -1
      score = -10
    end
    
    -- Send message to player.
    self:_SendMessageToPlayer(hint, 8, playerData)
    
    -- Add to debrief.
    self:_AddToSummary(playerData, "Calling the Ball", hint)
        
    -- Next step: debrief.
    playerData.step = 99
  end 
end

--- Trapped?
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
-- @param Core.Point#COORDINATE pos Position of aircraft on landing event.
function CARRIERTRAINER:_Trapped(playerData, pos)

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ, rho, phi = self:_GetDistances(pos)
  
  -- Get velocities.
  local playerVelocity  = playerData.unit:GetVelocityKMH()
  local carrierVelocity = self.carrier:GetVelocityKMH()

  if playerData.unit:InAir()==false then
    -- Seems we have successfully landed.
    
    local wire  = 1
    local score = -10
    
    -- Which wire
    if(diffX < -14) then
      wire = 1
      score = -15
    elseif(diffX < -3) then
      wire = 2
      score = 10      
    elseif (diffX < 10) then
      wire = 3
      score = 20
    else
      wire = 4
      score = 7
    end
    
    local text=string.format("TRAPPED! %d-wire.", wire)
    self:_SendMessageToPlayer(text, 30, playerData)
    
    local text2=string.format("Distance %.1f meters resulted in a %d-wire estimate.", diffX, wire)
    MESSAGE:New(text,30):ToAllIf(self.Debug)
    env.info(text2)
       
    local fullHint = string.format("Trapped catching the %d-wire.", wire)
    self:_AddToSummary(playerData, "Trapped", fullHint)
    
  else
    --Boltered!
  end
end


---------
-- Bla functions
---------

--- Append text to debrief text.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @param #string step Current step in the pattern.
-- @param #string item Text item appeded to the debrief.
function CARRIERTRAINER:_AddToSummary(playerData, step, item)
  table.insert(playerData.debrief, {step=step, hint=item})
end

--- Show debriefing message.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
function CARRIERTRAINER:_Debrief(playerData)

  -- Debriefing text.
  local text=string.format("Debriefing:\n")
  text=text..string.format("===========\n\n")
  for _,_data in pairs(playerData.debrief) do
    local step=_data.step
    local comment=_data.hint
    text=text..string.format("* %s:\n",step)
    text=text..string.format("- %s\n", comment)
    text=text..string.format("------------------------------------\n\n")
  end
  
  -- Send debrief message to player
  self:_SendMessageToPlayer(text, 60, playerData, true)
  
  --TODO: add final grades, memorize score deductions.
  --self:_PrintFinalScore(playerData, 30, -2)
  --self:_HandleCollectedResult(playerData, -2)  
  
  -- Next step.
  playerData.step=0
end

--- Get relative heading of player wrt carrier.
-- @param #CARRIERTRAINER self
-- @param Wrapper.Unit#UNIT unit Player unit.
-- @return #number Relative heading in degrees.
function CARRIERTRAINER:_GetRelativeHeading(unit)
  local vC=self.carrier:GetOrientationX()
  local vP=unit:GetOrientationX()
  
  -- Get angle between the two orientation vectors in rad.
  local relHead=math.acos(UTILS.VecDot(vC,vP)/UTILS.VecNorm(vC)/UTILS.VecNorm(vP))
  
  -- Return heading in degrees.
  return math.deg(relHead)
end


--- Carrier trainer event handler for event birth.
-- @param #CARRIERTRAINER self
function CARRIERTRAINER:_CheckPlayerStatus()

  -- Loop over all players.
  for _playerName,_playerData in pairs(self.players) do  
    local playerData = _playerData --#CARRIERTRAINER.PlayerData
    
    if playerData then
    
      -- Player unit.
      local unit = playerData.unit
      
      if unit:IsAlive() then
      
        --self:_SendMessageToPlayer("current step "..self:_StepName(playerData.step),1,playerData)
        --self:_DetailedPlayerStatus(playerData)

        --self:_DetailedPlayerStatus(playerData)
        if unit:IsInZone(self.giantZone) then
          
          -- Check if player was previously not inside the zone.
          if playerData.inbigzone==false then
          
            local text=string.format("Welcome back, %s! TCN 1X, BRC 354 (MAG HDG).\n", playerData.callsign)
            local heading=playerData.unit:GetCoordinate():HeadingTo(self.registerZone:GetCoordinate())
            local distance=playerData.unit:GetCoordinate():Get2DDistance(self.registerZone:GetCoordinate())
            text=text..string.format("Fly heading %d for %.1f NM to begin your approach.", heading, distance)
            MESSAGE:New(text, 5):ToClient(playerData.client)
          
          end
        
          if playerData.step==0 and unit:InAir() then
            self:_NewRound(playerData)          
          elseif playerData.step == 1 then
            self:_Start(playerData)
          elseif playerData.step == 2 then
            self:_Upwind(playerData)
          elseif playerData.step == 3 then
            self:_Break(playerData, "early")
          elseif playerData.step == 4 then
            self:_Break(playerData, "late")
          elseif playerData.step == 5 then
            self:_Abeam(playerData)
          elseif playerData.step == 6 then
            -- Check long down wind leg.
            if playerData.longDownwindDone==false then
              self:_CheckForLongDownwind(playerData)
            end
            self:_Ninety(playerData)
          elseif playerData.step == 7 then
            self:_Wake(playerData)
          elseif playerData.step == 8 then
            self:_Groove(playerData)
          elseif playerData.step == 9 then
            self:_CallTheBall(playerData)
          elseif playerData.step == 99 then
            self:_Debrief(playerData)
          end
          
        else
          playerData.inbigzone=false          
        end
        
      else
        -- Unit not alive.
        --playerDatas[i] = nil
      end
    end
  end
  
end

--- Get name of the current pattern step.
-- @param #CARRIERTRAINER self
-- @param #number step Step
-- @return #string Name of the step
function CARRIERTRAINER:_StepName(step)

  local name="unknown"
  if step==0 then
    name="Unregistered"
  elseif step==1 then
    name="when entering pattern"
  elseif step==2 then
    name="in the break entry"
  elseif step==3 then
    name="at the early break"
  elseif step==4 then
    name="at the late break"
  elseif step==5 then
    name="in the abeam position"
  elseif step==6 then
    name="at the ninety"
  elseif step==7 then
    name="at the wake"
  elseif step==8 then
    name="in the groove"
  elseif step==9 then
    name="trapped"
  end
  
  return name
end

--- Calculate distances between carrier and player unit.
-- @param #CARRIERTRAINER self 
-- @param Wrapper.Unit#UNIT unit Player unit
-- @return #number Distance [m] in the direction of the orientation of the carrier.
-- @return #number Distance [m] perpendicular to the orientation of the carrier.
-- @return #number Distance [m] to the carrier.
-- @return #number Angle [Deg] from carrier to plane. Phi=0 if the plane is directly behind the carrier, phi=90 if the plane is starboard, phi=180 if the plane is in front of the carrier.
function CARRIERTRAINER:_GetDistances(unit)

  -- Vector to carrier
  local a=self.carrier:GetVec3()
  
  -- Vector to player
  local b=unit:GetVec3()
  
  -- Vector from carrier to player.
  local c={x=b.x-a.x, y=0, z=b.z-a.z}
  
  -- Orientation of carrier.
  local x=self.carrier:GetOrientationX()
  
  -- Projection of player pos on x component.
  local dx=UTILS.VecDot(x,c)
  
  -- Orientation of carrier.
  local z=self.carrier:GetOrientationZ()
  
  -- Projection of player pos on z component.  
  local dz=UTILS.VecDot(z,c)
  
  -- Polar coordinates
  local rho=math.sqrt(dx*dx+dz*dz)
  local phi=math.deg(math.atan2(dz,dx))
  if phi<0 then
    phi=phi+360
  end
  -- phi=0 if the plane is directly behind the carrier, phi=180 if the plane is in front of the carrier
  phi=phi-180
  
  return dx,dz,rho,phi
end

--- Check if a player is within the right area.
-- @param #CARRIERTRAINER self
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #table pos Position data limits.
-- @return #boolean If true, approach should be aborted.
function CARRIERTRAINER:_CheckAbort(X, Z, pos)

  local abort=false
  if pos.Xmin and X<pos.Xmin then
    abort=true
  elseif pos.Xmax and X>pos.Xmax then
    abort=true
  elseif pos.Zmin and Z<pos.Zmin then
    abort=true
  elseif pos.Zmax and Z>pos.Zmax then
    abort=true
  end

  return abort
end

--- Generate a text if a player is too far from where he should be.
-- @param #CARRIERTRAINER self
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #table posData Position data limits.
function CARRIERTRAINER:_TooFarOutText(X, Z, posData)

  local text="You are too far"
  
  local xtext=nil
  if posData.Xmin and X<posData.Xmin then
    xtext=" ahead"
  elseif posData.Xmax and X>posData.Xmax then
    xtext=" behind"
  end
  
  local ztext=nil
  if posData.Zmin and Z<posData.Zmin then
    ztext=" port (left)"
  elseif posData.Zmax and Z>posData.Zmax then
    ztext=" starboard (right)"
  end
  
  if xtext and ztext then
    text=text..xtext.." and"..ztext
  elseif xtext then
    text=text..xtext
  elseif ztext then
    text=text..ztext
  end
  
  text=text.." of the carrier!"
  
  return text
end

--- Pattern aborted.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @param #number X X distance player to carrier.
-- @param #number Z Z distance player to carrier.
-- @param #table posData Position data.
function CARRIERTRAINER:_AbortPattern(playerData, X, Z, posData)

  -- Text where we are wrong.
  local toofartext=self:_TooFarOutText(X, Z, posData)
  
  -- Send message to player.
  self:_SendMessageToPlayer(toofartext.." Abort approach!", 15, playerData, true)
  
  -- Debug.
  local text=string.format("Abort: X=%d Xmin=%s, Xmax=%s | Z=%d Zmin=%s Zmax=%s", X, tostring(posData.Xmin), tostring(posData.Xmax), Z, tostring(posData.Zmin), tostring(posData.Zmax))
  self:E(self.lid..text)
  --MESSAGE:New(text, 60):ToAllIf(self.Debug)
  
  -- Add to debrief.
  self:_AddToSummary(playerData, "Abort", "Approach aborted.")
  
  --TODO: set score and grade.
  
  -- Next step debrief.  
  playerData.step=99
end


--- Provide info about player status on the fly.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
function CARRIERTRAINER:_DetailedPlayerStatus(playerData)

  local unit=playerData.unit
  
  local aoa=unit:GetAoA()
  local yaw=unit:GetYaw()
  local roll=unit:GetRoll()
  local pitch=unit:GetPitch()
  local dist=playerData.unit:GetCoordinate():Get2DDistance(self.carrier:GetCoordinate())
  local dx,dz,rho,phi=self:_GetDistances(unit)

  -- Player and carrier position vector.
  local playerPosition = playerData.unit:GetVec3()  
  local carrierPosition = self.carrier:GetVec3()
  
  local diffZ = playerPosition.z - carrierPosition.z
  local diffX = playerPosition.x - carrierPosition.x

  local heading=unit:GetCoordinate():HeadingTo(self.startZone:GetCoordinate())
  
  local wind=unit:GetCoordinate():GetWindWithTurbulenceVec3()
  local velo=unit:GetVelocityVec3()
  
  local relhead=self:_GetRelativeHeading(playerData.unit)
 
  local text=string.format("%s, current AoA=%.1f\n", playerData.callsign, aoa)
  text=text..string.format("velo x=%.1f y=%.1f z=%.1f\n", velo.x, velo.y, velo.z)
  text=text..string.format("wind x=%.1f y=%.1f z=%.1f\n", wind.x, wind.y, wind.z)
  text=text..string.format("pitch=%.1f | roll=%.1f | yaw=%.1f | climb=%.1f\n", pitch, roll, yaw, unit:GetClimbAnge())
  text=text..string.format("relheading=%.1f degrees\n", relhead)
  text=text..string.format("rho=%.1f m phi=%.1f degrees\n", rho,phi)
  --text=text..string.format("current step = %d %s\n", playerData.step, self:_StepName(playerData.step))
  --text=text..string.format("Carrier distance: d=%d m\n", dist)
  --text=text..string.format("Carrier distance: x=%d m z=%d m sum=%d (old)\n", diffX, diffZ, math.abs(diffX)+math.abs(diffZ))
  --text=text..string.format("Carrier distance: x=%d m z=%d m sum=%d (new)", dx, dz, math.abs(dz)+math.abs(dx))  

  MESSAGE:New(text, 1, nil , true):ToClient(playerData.client)
end

--- Init parameters for USS Stennis carrier.
-- @param #CARRIERTRAINER self
function CARRIERTRAINER:_InitStennis()

  -- Upwind leg
  self.Upwind.name="Upwind"
  self.Upwind.Xmin=-4000  -- TODO Should be withing 4 km behind carrier. Why?
  self.Upwind.Xmax=nil
  self.Upwind.Zmin=0
  self.Upwind.Zmax=1200
  self.Upwind.LimitXmin=0
  self.Upwind.LimitXmax=nil
  self.Upwind.LimitZmin=0
  self.Upwind.LimitZmax=nil
  self.Upwind.Altitude=UTILS.FeetToMeters(800)
  self.Upwind.AoA=8.1
  self.Upwind.Distance=nil

  -- Early break
  self.BreakEarly.name="Early Break"
  self.BreakEarly.Xmin=-500
  self.BreakEarly.Xmax=nil
  self.BreakEarly.Zmin=-3700
  self.BreakEarly.Zmax=1500
  self.BreakEarly.LimitXmin=0
  self.BreakEarly.LimitXmax=nil
  self.BreakEarly.LimitZmin=-370   -- 0.2 NM port of carrier
  self.BreakEarly.LimitZmax=nil
  self.BreakEarly.Altitude=UTILS.FeetToMeters(800)
  self.BreakEarly.AoA=8.1
  self.BreakEarly.Distance=nil
  
  -- Late break
  self.BreakLate.name="Late Break"
  self.BreakLate.Xmin=-500
  self.BreakLate.Xmax=nil
  self.BreakLate.Zmin=-3700
  self.BreakLate.Zmax=1500
  self.BreakLate.LimitXmin=0
  self.BreakLate.LimitXmax=nil
  self.BreakLate.LimitZmin=-1470  --0.8 NM
  self.BreakLate.LimitZmax=nil
  self.BreakLate.Altitude=UTILS.FeetToMeters(800)
  self.BreakLate.AoA=8.1
  self.BreakLate.Distance=nil  
  
  -- Abeam position
  self.Abeam.name="Abeam Position"
  self.Abeam.Xmin=nil
  self.Abeam.Xmax=nil
  self.Abeam.Zmin=-4000
  self.Abeam.Zmax=-1000
  self.Abeam.LimitXmin=-200
  self.Abeam.LimitXmax=nil
  self.Abeam.LimitZmin=nil
  self.Abeam.LimitZmax=nil
  self.Abeam.Altitude=UTILS.FeetToMeters(600)  
  self.Abeam.AoA=8.1
  self.Abeam.Distance=UTILS.NMToMeters(1.2)

  -- At the ninety
  self.Ninety.name="Ninety"
  self.Ninety.Xmin=-4000
  self.Ninety.Xmax=0
  self.Ninety.Zmin=-3700
  self.Ninety.Zmax=nil
  self.Ninety.LimitXmin=nil
  self.Ninety.LimitXmax=nil
  self.Ninety.LimitZmin=nil
  self.Ninety.LimitZmax=-1111
  self.Ninety.Altitude=UTILS.FeetToMeters(500)
  self.Ninety.AoA=8.1
  self.Ninety.Distance=nil

  -- Wake position
  self.Wake.name="Wake"
  self.Wake.Xmin=-4000
  self.Wake.Xmax=0
  self.Wake.Zmin=-2000
  self.Wake.Zmax=nil
  self.Wake.LimitXmin=nil
  self.Wake.LimitXmax=nil
  self.Wake.LimitZmin=0
  self.Wake.LimitZmax=nil
  self.Wake.Altitude=UTILS.FeetToMeters(370)
  self.Wake.AoA=8.1
  self.Wake.Distance=nil

  -- In the groove
  self.Groove.name="Groove"
  self.Groove.Xmin=-4000
  self.Groove.Xmax=100
  self.Groove.Zmin=-2000
  self.Groove.Zmax=nil
  self.Groove.LimitXmin=nil
  self.Groove.LimitXmax=nil
  self.Groove.LimitZmin=nil
  self.Groove.LimitZmax=nil
  self.Groove.Altitude=UTILS.FeetToMeters(300)
  self.Groove.AoA=8.1
  self.Groove.Distance=nil
  
  -- Landing trap
  self.Trap.name="Trap"
  self.Trap.Xmin=-3000
  self.Trap.Xmax=nil
  self.Trap.Zmin=-2000
  self.Trap.Zmax=2000
  self.Trap.LimitXmin=nil
  self.Trap.LimitXmax=nil
  self.Trap.LimitZmin=nil
  self.Trap.LimitZmax=nil
  self.Trap.Altitude=nil
  self.Trap.AoA=nil
  self.Trap.Distance=nil 

end

--- Check limits for reaching next step.
-- @param #CARRIERTRAINER self
-- @param #number X X position of player unit.
-- @param #number Z Z position of player unit.
-- @param #CARRIERTRAINER.Checkpoint check Checkpoint.
-- @return #boolean If true, checkpoint condition for next step was reached.
function CARRIERTRAINER:_CheckLimits(X, Z, check)

  local nextXmin=check.LimitXmin==nil or (check.LimitXmin and (check.LimitXmin<0 and X<=check.LimitXmin or check.LimitXmin>=0 and X>=check.LimitXmin))
  local nextXmax=check.LimitXmax==nil or (check.LimitXmax and (check.LimitXmax<0 and X>=check.LimitXmax or check.LimitXmax>=0 and X<=check.LimitXmax))
  local nextZmin=check.LimitZmin==nil or (check.LimitZmin and (check.LimitZmin<0 and Z<=check.LimitZmin or check.LimitZmin>=0 and Z>=check.LimitZmin))
  local nextZmax=check.LimitZmax==nil or (check.LimitZmax and (check.LimitZmax<0 and Z>=check.LimitZmax or check.LimitZmax>=0 and Z<=check.LimitZmax))
  
  local next=nextXmin and nextXmax and nextZmin and nextZmax
  
  
  local text=string.format("step=%s: next=%s: X=%d Xmin=%s Xmax=%s | Z=%d Zmin=%s Zmax=%s", 
  check.name, tostring(next), X, tostring(check.LimitXmin), tostring(check.LimitXmax), Z, tostring(check.LimitZmin), tostring(check.LimitZmax))
  self:T(self.lid..text)
  --MESSAGE:New(text, 1):ToAllIf(self.Debug)

  return next
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MISC functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Evaluate player's altitude at checkpoint.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
-- @return #number Low score.
-- @return #number Bad score.
function CARRIERTRAINER:_GetGoodBadScore(playerData)

  local lowscore
  local badscore
  if playerData.difficulty==CARRIERTRAINER.Difficulty.EASY then
    lowscore=10
    badscore=20    
  elseif playerData.difficulty==CARRIERTRAINER.Difficulty.NORMAL then
    lowscore=5
    badscore=10     
  elseif playerData.difficulty==CARRIERTRAINER.Difficulty.HARD then
    lowscore=2.5
    badscore=5
  end
  
  return lowscore, badscore
end

--- Evaluate player's altitude at checkpoint.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
-- @param #CARRIERTRAINER.Checkpoint checkpoint Checkpoint.
-- @param #number altitude Player's current altitude in meters.
-- @return #string Feedback text.
function CARRIERTRAINER:_AltitudeCheck(playerData, checkpoint, altitude)

  -- Player altitude.
  local altitude=playerData.unit:GetAltitude()
  
  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore(playerData)
  
  -- Altitude error +-X%
  local _error=(altitude-checkpoint.Altitude)/checkpoint.Altitude*100
  
  local score
  local hint
  local steptext=self:_StepName(playerData.step)
    
  if _error>badscore then
    score = -10
    hint  = string.format("You're high %s. ", steptext)
  elseif _error>lowscore then
    score = -5
    hint  = string.format("You're slightly high %s. ", steptext)
  elseif _error<-badscore then
    score = -10
    hint  = string.format("You're low %s.", steptext)
  elseif _error<-lowscore then
    score = -5
    hint  = string.format("You're slightly low %s. ", steptext)
  else
    score = 0
    hint  = string.format("Good altitude %s. ", steptext)
  end
  
  hint=hint..string.format(" Altitude %d ft = %d%% deviation from %d ft target alt.", UTILS.MetersToFeet(altitude), _error, UTILS.MetersToFeet(checkpoint.Altitude))
  
  -- Set score.
  playerData.score=playerData.score+score
        
  return hint
end

--- Evaluate player's altitude at checkpoint.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
-- @param #CARRIERTRAINER.Checkpoint checkpoint Checkpoint.
-- @param #number distance Player's current distance to the boat in meters.
-- @return #string Feedback message text.
function CARRIERTRAINER:_DistanceCheck(playerData, checkpoint, distance)

  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore(playerData)
  
  -- Altitude error +-X%
  local _error=(distance-checkpoint.Distance)/checkpoint.Distance*100
  
  local score
  local hint
  local steptext=self:_StepName(playerData.step)
  if _error>badscore then
    score = -10
    hint  = string.format("You're too far from the boat!")
  elseif _error>lowscore then
    score =  -5 
    hint  = string.format("You're slightly too far from the boat.")
  elseif _error<-badscore then
    score = -10
    hint  = string.format( "You're too close to the boat!")
  elseif _error<-lowscore then
    score =  -5
    hint  = string.format("slightly too far from the boat.")
  else
    score =   0
    hint  = string.format("with perfect distance to the boat.")
  end
  
  hint=hint..string.format(" Distance %.1f NM = %d%% deviation from %.1f NM optimal distance.",UTILS.MetersToNM(distance), _error, UTILS.MetersToNM(checkpoint.Distance))

  -- Set score.
  playerData.score=playerData.score+score
  
  return hint
end

--- Score for correct AoA.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @param #CARRIERTRAINER.Checkpoint checkpoint Checkpoint.
-- @param #number aoa Player's current Angle of attack.
-- @return #string hint Feedback message text.
function CARRIERTRAINER:_AoACheck(playerData, checkpoint, aoa)

  -- Get relative score.
  local lowscore, badscore = self:_GetGoodBadScore(playerData)
  
  -- Altitude error +-X%
  local _error=(aoa-checkpoint.AoA)/checkpoint.AoA*100

  local score = 0
  local hint=""
  if _error>badscore then --Slow
    score = -10
    hint  = "You're slow."
  elseif _error>lowscore then --Slightly slow
    score = -5
    hint  = "You're slightly slow."
  elseif _error<-badscore then --Fast
    score = -10
    hint  = "You're fast."
  elseif _error<-lowscore then --Slightly fast
    score = -5
    hint  = "You're slightly fast."
  else --On speed
    score = 0
    hint  = "You're on speed!"
  end
  
  hint=hint..string.format(" AoA %.1f = %d %% deviation from %.1f target AoA.", aoa, _error, checkpoint.AoA)

  -- Set score.
  playerData.score=playerData.score+score
  
  return hint
end


--- Send message to playe client.
-- @param #CARRIERTRAINER self
-- @param #string message The message to send.
-- @param #number duration Display message duration.
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @param #boolean clear If true, clear screen from previous messages.
function CARRIERTRAINER:_SendMessageToPlayer(message, duration, playerData, clear)
  if playerData.client then
    MESSAGE:New(string.format("%s, %s, ", self.alias, playerData.callsign)..message, duration, nil, clear):ToClient(playerData.client)
  end
end

--- Display final score.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @param #number duration Duration for message display.
function CARRIERTRAINER:_PrintFinalScore(playerData, duration, wire)
  local wireText = ""
  if(wire == -2) then
    wireText = "Aborted approach"
  elseif(wire == -1) then
    wireText = "Wave-off"
  elseif(wire == 0) then
    wireText = "Bolter"
  else
    wireText = wire .. "-wire"
  end
  
  MessageToAll( playerData.callsign .. " - Final score: " .. playerData.score .. " / 140 (" .. wireText .. ")", duration, "FinalScore" )
  --self:_SendMessageToPlayer( playerData.summary, duration, playerData )
end

--- Collect result.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @param #number wire Trapped wire.
function CARRIERTRAINER:_HandleCollectedResult(playerData, wire)

  local newString = ""
  if(wire == -2) then
    newString = playerData.score .. " (Aborted)"
  elseif(wire == -1) then
    newString = playerData.score .. " (Wave-off)"
  elseif(wire == 0) then
    newString = playerData.score .. " (Bolter)"
  else
    newString = playerData.score .. " (" .. wire .."W)"
  end
  
  playerData.totalscore = playerData.totalscore + playerData.score
  playerData.passes = playerData.passes + 1
  
  --TODO: collect results
  --[[
  if playerData.collectedResultString == "" then
    playerData.collectedResultString = newString
  else
    playerData.collectedResultString = playerData.collectedResultString .. ", " .. newString
    MessageToAll( playerData.callsign .. "'s " .. playerData.passes .. " passes: " .. playerData.collectedResultString .. " (TOTAL: " .. playerData.totalscore .. ")"  , 30, "CollectedResult" )
  end
   ]]
   
  local heading=playerData.unit:GetCoordinate():HeadingTo(self.registerZone:GetCoordinate())
  local distance=playerData.unit:GetCoordinate():Get2DDistance(self.registerZone:GetCoordinate())
  local text=string.format("%s, fly heading %d for %d NM to restart the pattern.", playerData.callsign, heading, UTILS.MetersToNM(distance))
   --"Return south 4 nm (over the trailing ship), towards WP 1, to restart the pattern."
  self:_SendMessageToPlayer(text, 30, playerData)
end


--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #CARRIERTRAINER self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function CARRIERTRAINER:_GetPlayerUnitAndName(_unitName)
  self:F2(_unitName)

  if _unitName ~= nil then
  
    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)
    
    if DCSunit then
    
      local playername=DCSunit:getPlayerName()
      local unit=UNIT:Find(DCSunit)
    
      self:T2({DCSunit=DCSunit, unit=unit, playername=playername})
      if DCSunit and unit and playername then
        return unit, playername
      end
      
    end
    
  end
  
  -- Return nil if we could not find a player.
  return nil,nil
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add menu commands for player.
-- @param #CARRIERTRAINER self
-- @param #string _unitName Name of player unit.
function CARRIERTRAINER:_AddF10Commands(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check for player unit.
  if _unit and playername then

    -- Get group and ID.
    local group=_unit:GetGroup()
    local _gid=group:GetID()
  
    if group and _gid then
  
      if not self.menuadded[_gid] then
      
        -- Enable switch so we don't do this twice.
        self.menuadded[_gid] = true
  
        -- Main F10 menu: F10/Carrier Trainer/<Carrier Name>/
        if CARRIERTRAINER.MenuF10[_gid] == nil then
          CARRIERTRAINER.MenuF10[_gid]=missionCommands.addSubMenuForGroup(_gid, "Carrier Trainer")
        end
        
        local playerData=self.players[playername]
        
        -- F10/Carrier Trainer/<Carrier Name>
        local _trainPath    = missionCommands.addSubMenuForGroup(_gid, self.alias, CARRIERTRAINER.MenuF10[_gid])
        -- F10/Carrier Trainer/<Carrier Name>/Results
        --local _statsPath    = missionCommands.addSubMenuForGroup(_gid, "Results",      _trainPath)
        -- F10/Carrier Trainer/<Carrier Name>/My Settings
        local _settingsPath = missionCommands.addSubMenuForGroup(_gid, "My Settings",  _trainPath)
        -- F10/Carrier Trainer/<Carrier Name>/My Settings/Difficulty
        local _difficulPath = missionCommands.addSubMenuForGroup(_gid, "Difficulty",   _settingsPath)
        -- F10/Carrier Trainer/<Carrier Name>/Carrier Info
        local _infoPath     = missionCommands.addSubMenuForGroup(_gid, "Carrier Info", _trainPath)

        -- F10/Carrier Trainer/<Carrier Name>/Stats/
        --missionCommands.addCommandForGroup(_gid, "All Results",       _statsPath, self._DisplayStrafePitResults, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "My Results",        _statsPath, self._DisplayBombingResults, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "Reset All Results", _statsPath, self._ResetRangeStats, self, _unitName)
        -- F10/Carrier Trainer/<Carrier Name>/My Settings/
        --missionCommands.addCommandForGroup(_gid, "Smoke Delay On/Off",  _settingsPath, self._SmokeBombDelayOnOff, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "Smoke Impact On/Off",  _settingsPath, self._SmokeBombImpactOnOff, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "Flare Hits On/Off",    _settingsPath, self._FlareDirectHitsOnOff, self, _unitName)
        -- F10/Carrier Trainer/<Carrier Name>/My Settings/Difficulty
        missionCommands.addCommandForGroup(_gid, "Flight Student",      _difficulPath, self.SetDifficulty, self, playerData, CARRIERTRAINER.Difficulty.EASY)
        missionCommands.addCommandForGroup(_gid, "Naval Aviator",       _difficulPath, self.SetDifficulty, self, playerData, CARRIERTRAINER.Difficulty.NORMAL)
        missionCommands.addCommandForGroup(_gid, "TOPGUN Graduate",     _difficulPath, self.SetDifficulty, self, playerData, CARRIERTRAINER.Difficulty.HARD)
        -- F10/Carrier Trainer/<Carrier Name>/Carrier Info/
        missionCommands.addCommandForGroup(_gid, "Carrier Info",        _infoPath, self._DisplayCarrierInfo, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Weather Report",      _infoPath, self._DisplayCarrierWeather, self, _unitName)
      end
    else
      self:T(self.lid.."Could not find group or group ID in AddF10Menu() function. Unit name: ".._unitName)
    end
  else
    self:T(self.lid.."Player unit does not exist in AddF10Menu() function. Unit name: ".._unitName)
  end

end

--- Set difficulty level.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @param #CARRIERTRAINER.Difficulty difficulty Difficulty level.
function CARRIERTRAINER:SetDifficulty(playerData, difficulty)
  playerData.difficulty=difficulty
end

--- Report information about carrier.
-- @param #CARRIERTRAINER self
-- @param #string _unitname Name of the player unit.
function CARRIERTRAINER:_DisplayCarrierInfo(_unitname)
  self:F(_unitname)
  
  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Message text.
    local text=string.format("%s info:\n", self.alias)
   
    -- Current coordinates.
    local coord=self.carrier:GetCoordinate()
    
    local playerData=self.players[playername]  --#CARRIERTRAINER.PlayerData
    
    local carrierheading=self.carrier:GetHeading()
    local carrierspeed=UTILS.MpsToKnots(self.carrier:GetVelocity())

    text=text..string.format("BRC %d\n", carrierheading)
    text=text..string.format("Speed %d kts\n", carrierspeed)
    
    
    local tacan="unknown"
    local icls="unknown"
    if self.TACAN~=nil then
      tacan=tostring(self.TACAN)
    end
    if self.ICLS~=nil then
      icls=tostring(self.ICLS)
    end
    
    text=text..string.format("TACAN Channel %s", tacan)
    text=text..string.format("ICLS Channel %s", icls)
    
    self:_SendMessageToPlayer(text, 20, playerData)
   
  end  
  
end


--- Report weather conditions at the carrier location. Temperature, QFE pressure and wind data.
-- @param #CARRIERTRAINER self
-- @param #string _unitname Name of the player unit.
function CARRIERTRAINER:_DisplayCarrierWeather(_unitname)
  self:F(_unitname)

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Message text.
    local text=""
   
    -- Current coordinates.
    local coord=self.carrier:GetCoordinate()
    
    -- Get atmospheric data at range location.
    local position=self.location --Core.Point#COORDINATE
    local T=position:GetTemperature()
    local P=position:GetPressure()
    local Wd,Ws=position:GetWind()
    
    -- Get Beaufort wind scale.
    local Bn,Bd=UTILS.BeaufortScale(Ws)  
    
    local WD=string.format('%03d°', Wd)
    local Ts=string.format("%d°C",T)
    
    local hPa2inHg=0.0295299830714
    local hPa2mmHg=0.7500615613030
    
    local settings=_DATABASE:GetPlayerSettings(playername) or _SETTINGS --Core.Settings#SETTINGS
    local tT=string.format("%d°C",T)
    local tW=string.format("%.1f m/s", Ws)
    local tP=string.format("%.1f mmHg", P*hPa2mmHg)
    if settings:IsImperial() then
      tT=string.format("%d°F", UTILS.CelciusToFarenheit(T))
      tW=string.format("%.1f knots", UTILS.MpsToKnots(Ws))
      tP=string.format("%.2f inHg", P*hPa2inHg)      
    end
    
           
    -- Message text.
    text=text..string.format("Weather Report at %s:\n", self.rangename)
    text=text..string.format("--------------------------------------------------\n")
    text=text..string.format("Temperature %s\n", tT)
    text=text..string.format("Wind from %s at %s (%s)\n", WD, tW, Bd)
    text=text..string.format("QFE %.1f hPa = %s", P, tP)

    
    -- Send message to player group.
    --self:_DisplayMessageToGroup(unit, text, nil, true)
    self:_SendMessageToPlayer(text, 30, self.players[playername])
    
    -- Debug output.
    self:T2(self.lid..text)
  else
    self:T(self.lid..string.format("ERROR! Could not find player unit in RangeInfo! Name = %s", _unitname))
  end      
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LSO Class
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- LSO class.
-- @type LSO
-- @field #string ClassName Name of the class.
-- @extends Core.Fsm#FSM

--- Landing Signal Officer
--
-- ===
--
-- ![Banner Image](..\Presentations\LSO\LSO_Main.png)
--
-- # The Landing Signal Officer
--
-- bla bla
--
-- @field #LSO
LSO = {
  ClassName = "LSO",
}

