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
-- ### Author: **Bankler** (original idea and script)
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
-- @field Core.Zone#ZONE_UNIT startZone Zone in which the pattern approach starts.
-- @field Core.Zone#ZONE_UNIT giantZone Zone around the carrier to register a new player.
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
-- @extends Core.Fsm#FSM

--- Practice Carrier Landings
--
-- ===
--
-- ![Banner Image](..\Presentations\CARRIERTRAINER\CarrierTrainer_Main.png)
--
-- # The Trainer Concept
--
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
-- @field #string callsign Callsign of player.
-- @field #number score Player score.
-- @field #number totalscore Score of all landing attempts.
-- @field #number passes Number of passes.
-- @field #string collectedResultString Results text of all passes.
-- @field Wrapper.Unit#UNIT unit Aircraft unit of the player.
-- @field #number lowestAltitude Lowest altitude. 
-- @field #number highestCarrierXDiff 
-- @field #number secondsStandingStill Time player does not move after a landing attempt. 
-- @field #string summary Result summary text.
-- @field Wrapper.Client#CLIENT client object of player.
-- @field #string difficulty Difficulty level.

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
CARRIERTRAINER.version="0.0.9"

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
    self.registerZone = ZONE_UNIT:New("registerZone", self.carrier,  2500, { dx = -5000, dy = 100, relative_to_unit = true })
    self.startZone    = ZONE_UNIT:New("startZone",    self.carrier,  1000, { dx = -2000, dy = 100, relative_to_unit = true })
    self.giantZone    = ZONE_UNIT:New("giantZone",    self.carrier, 30000, { dx =  0,    dy = 0,   relative_to_unit = true })
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
  --self:HandleEvent(EVENTS.Lan)

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
      
  end 
end

--- Initialize player data.
-- @param #CARRIERTRAINER self
-- @param #string unitname Name of the player unit.
-- @return #CARRIERTRAINER.PlayerData Player data.
function CARRIERTRAINER:_InitNewPlayer(unitname) 

  local playerData={} --#CARRIERTRAINER.PlayerData
  
  playerData.unit = UNIT:FindByName(unitname)
  playerData.client = CLIENT:FindByName(playerData.unit.UnitName, nil, true)
  playerData.callsign = playerData.unit:GetCallsign()
  playerData.totalscore = 0
  playerData.passes = 0
  playerData.collectedResultString = ""
    
  playerData=self:_InitNewRound(playerData)
  
  playerData.difficulty=CARRIERTRAINER.Difficulty.NORMAL
  
  return playerData
end

--- Initialize new approach for player by resetting parmeters to initial values.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @return #CARRIERTRAINER.PlayerData Initialized player data.
function CARRIERTRAINER:_InitNewRound(playerData)
  playerData.score = 0
  playerData.summary = "SUMMARY:\n"
  playerData.step = 0
  playerData.longDownwindDone = false
  playerData.highestCarrierXDiff = -9999999
  playerData.secondsStandingStill = 0
  playerData.lowestAltitude = 999999
  return playerData
end

--- Append text to summary text.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @param #string item Text item appeded to the summary.
function CARRIERTRAINER:_AddToSummary(playerData, item)
  playerData.summary = playerData.summary .. item .. "\n"
end

--- Append text to result text.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @param #string item Text item appeded to the result.
function CARRIERTRAINER:_AddToCollectedResult(playerData, item)
  playerData.collectedResultString = playerData.collectedResultString .. item .. "\n"
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
        if unit:IsInZone(self.giantZone) then
          --self:_DetailedPlayerStatus(playerData)
        end
        
        if playerData.step==0 and unit:IsInZone(self.giantZone) and unit:InAir() then
          self:_NewRound(playerData)
          self:_InitStennis()
        elseif playerData.step == 1 and unit:IsInZone(self.startZone) then
          self:_Start(playerData)
        elseif playerData.step == 2 and unit:IsInZone(self.giantZone) then
          self:_Upwind(playerData)
        elseif playerData.step == 3 and unit:IsInZone(self.giantZone) then
          self:_Break(playerData, "early")
        elseif playerData.step == 4 and unit:IsInZone(self.giantZone) then
          self:_Break(playerData, "late")
        elseif playerData.step == 5 and unit:IsInZone(self.giantZone) then
          self:_Abeam(playerData)
        elseif playerData.step == 6 and unit:IsInZone(self.giantZone) then
          -- Check long down wind leg.
          if not playerData.longDownwindDone then
            self:_CheckForLongDownwind(playerData)
          end
          self:_Ninety(playerData)
        elseif playerData.step == 7 and unit:IsInZone(self.giantZone) then
          self:_Wake(playerData)
        elseif playerData.step == 8 and unit:IsInZone(self.giantZone) then
          self:_Groove(playerData)
        elseif playerData.step == 9 and unit:IsInZone(self.giantZone) then
          self:_Trap(playerData)
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
    name="on upwind leg"
  elseif step==3 then
    name="at the early break"
  elseif step==4 then
    name="at the late break"
  elseif step==5 then
    name="in the abeam position"
  elseif step==6 then
    name="at the wake"
  elseif step==7 then
    name="at the ninety"
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
-- @return #number Distance in the direction of the orientation of the carrier.
-- @return #number Distance perpendicular to the orientation of the carrier.
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
  
  return dx,dz
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

  local toofartext=self:_TooFarOutText(X, Z, posData)
  
  self:_SendMessageToPlayer(toofartext.." Abort approach!", 15, playerData )
  
  local text=string.format("Abort: X=%d Xmin=%s, Xmax=%s | Z=%d Zmin=%s Zmax=%s", X, tostring(posData.Xmin), tostring(posData.Xmax), Z, tostring(posData.Zmin), tostring(posData.Zmax))
  self:E(self.lid..text)
  MESSAGE:New(text, 60):ToAllIf(self.Debug)
  
  self:_AddToSummary(playerData, "Approach aborted.")
  
  self:_PrintFinalScore(playerData, 30, -2)
  
  self:_HandleCollectedResult(playerData, -2)
  
  playerData.step = 0
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
  local dx,dz=self:_GetDistances(unit)

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
  text=text..string.format("relheading %.1f degrees", relhead)
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
  self.BreakEarly.LimitZmin=-370   --0.2 NM
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
  self.BreakLate.LimitXmax=10000
  self.BreakLate.LimitZmin=-1470  --0.8 NM
  self.BreakLate.LimitZmax=10000
  self.BreakLate.Altitude=UTILS.FeetToMeters(800)
  self.BreakLate.AoA=8.1
  self.BreakLate.Distance=nil  
  
  -- Abeam position
  self.Abeam.name="Abeam Position"
  self.Abeam.Xmin=nil
  self.Abeam.Xmax=nil
  self.Abeam.Zmin=-3700
  self.Abeam.Zmax=-1000
  self.Abeam.LimitXmin=-200
  self.Abeam.LimitXmax=10000
  self.Abeam.LimitZmin=0
  self.Abeam.LimitZmax=10000
  self.Abeam.Altitude=UTILS.FeetToMeters(600)  
  self.Abeam.AoA=8.1
  self.Abeam.Distance=nil

  -- At the ninety
  self.Ninety.name="Ninety"
  self.Ninety.Xmin=-3700
  self.Ninety.Xmax=0
  self.Ninety.Zmin=-3700
  self.Ninety.Zmax=nil
  self.Ninety.LimitXmin=nil
  self.Ninety.LimitXmax=nil
  self.Ninety.LimitZmin=nil
  self.Ninety.LimitZmax=-1111
  self.Ninety.Altitude=UTILS.FeetToMeters(500)
  self.Abeam.AoA=8.1
  self.Abeam.Distance=nil

  -- Wake position
  self.Wake.name="Wake"
  self.Wake.Xmin=-4000
  self.Wake.Xmax=0
  self.Wake.Zmin=-2000
  self.Wake.Zmax=nil
  self.Wake.LimitXmin=nil
  self.Wake.LimitXmax=nil
  self.Wake.LimitZmin=nil
  self.Wake.LimitZmax=0
  self.Wake.Altitude=UTILS.FeetToMeters(370)
  self.Wake.AoA=8.1
  self.Wake.Distance=nil

  -- In the groove
  self.Groove.name="Groove"
  self.Groove.Xmin=-4000
  self.Groove.Xmax=100
  
  -- Landing trap
  self.Trap.name="Trap"
  self.Trap.Xmin=-3000
  self.Trap.Xmax=nil
  self.Trap.Zmin=-2000
  self.Trap.Zmax=2000
  --self.Trap.Limit=nil
  self.Trap.Altitude=nil  

end

--- Check limits for reaching next step.
-- @param #CARRIERTRAINER self
-- @param #number X X position of player unit.
-- @param #number Z Z position of player unit.
-- @param #CARRIERTRAINER.Checkpoint check Checkpoint.
-- @return #boolean If true, checkpoint condition for next step was reached.
function CARRIERTRAINER:_CheckLimits(X, Z, check)

  --[[
  local next=true
  if check.LimitXmin and X<check.LimitXmin then
    next=false
  elseif check.LimitXmax and X>check.LimitXmax then
    next=false
  elseif check.LimitZmin and Z<check.LimitZmin then
    next=false
  elseif check.LimitZmax and Z>check.LimitZmax then
    next=false
  end

  
  local next = ((check.LimitXmin and math.abs(X)>=math.abs(check.LimitXmin)) or check.LimitXmin==nil) and
               ((check.LimitXmax and math.abs(X)<=math.abs(check.LimitXmax)) or check.LimitXmax==nil) and
               ((check.LimitZmin and math.abs(Z)>=math.abs(check.LimitZmin)) or check.LimitZmin==nil) and
               ((check.LimitZmax and math.abs(Z)<=math.abs(check.LimitZmax)) or check.LimitZmax==nil)
  ]]
                 
  local nextXmin=check.LimitXmin==nil or (check.LimitXmin and (check.LimitXmin<0 and X<=check.LimitXmin or check.LimitXmin>=0 and X>=check.LimitXmin))
  local nextXmax=check.LimitXmax==nil or (check.LimitXmax and (check.LimitXmax<0 and X>=check.LimitXmax or check.LimitXmax>=0 and X<=check.LimitXmax))
  local nextZmin=check.LimitZmin==nil or (check.LimitZmin and (check.LimitZmin<0 and Z<=check.LimitZmin or check.LimitZmin>=0 and Z>=check.LimitZmin))
  local nextZmax=check.LimitZmax==nil or (check.LimitZmax and (check.LimitZmax<0 and Z>=check.LimitZmax or check.LimitZmax>=0 and Z<=check.LimitZmax))
  
  local next=nextXmin and nextXmax and nextZmin and nextZmax
  
  --self:E({next=next, X=X, Z=Z, check=check})
  
  local text=string.format("step=%s: next=%s: X=%d Xmin=%s Xmax=%s ||| Z=%d Zmin=%s Zmax=%s", 
  check.name, tostring(next), X, tostring(check.LimitXmin), tostring(check.LimitXmax), Z, tostring(check.LimitZmin), tostring(check.LimitZmax))
  self:E(self.lid..text)
  MESSAGE:New(text,1):ToAllIf(self.Debug)

  return next
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CARRIER TRAINING functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Initialize player data.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
function CARRIERTRAINER:_NewRound(playerData) 
    
  local text=string.format("Welcome back, %s! Cleared for approach. TCN 1X, BRC 354 (MAG HDG).", playerData.callsign)
  MESSAGE:New(text, 5):ToClient(playerData.client)
  
  self:_InitNewRound(playerData)
  playerData.step = 1
end

--- Start landing pattern, when player enters the start zone.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_Start(playerData)


  local hint = string.format("Entering the pattern, %s! Aim for 800 feet and 350-400 kts in the break entry.", playerData.callsign)
  self:_SendMessageToPlayer(hint, 8, playerData)
  
  -- TODO: Check for correct player heading!
  playerData.score = 0
  playerData.step  = 2
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
  
    -- Get altutide.
    local hint=self:_AltitudeCheck(playerData, self.Upwind, altitude)
    
    
    self:_SendMessageToPlayer(hint, 8, playerData)
    
    self:_AddToSummary(playerData, hint)
    
    -- Next step.
    playerData.step = 3    
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

  -- Check if too far left
  --if diffZ < limit then
  if self:_CheckLimits(diffX, diffZ, breakpoint) then
  
    local altitude=playerData.unit:GetAltitude()
  
    -- Check altitude.
    local hint=self:_AltitudeCheck(playerData, breakpoint, altitude)
    
    self:_SendMessageToPlayer(hint, 8, playerData)

    -- Add hint to summary.
    self:_AddToSummary(playerData, hint)

    if (part == "early") then
      playerData.step = 4
    else
      playerData.step = 5
    end
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
    
    local hintAoA=self:_AoACheck(playerData, self.Abeam, aoa)
    
    -- Check Altitude
    local hintAlt=self:_AltitudeCheck(playerData, self.Abeam, alt)
    
    -- Check distance.
    local hintDist=self:_DistanceCheck(playerData, self.Abeam, diffZ)
    
    local hintFull=string.format("%s.\n%s.\n%s.", hintAoA, hintAlt, hintDist)
    
    self:_SendMessageToPlayer(hintFull, 8, playerData )    
    
    self:_AddToSummary(playerData, hintFull)
    
    -- Proceed to next step.
    playerData.step = 6
  end
end

--- Down wind long check.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_CheckForLongDownwind(playerData)
  
  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ = self:_GetDistances(playerData.unit)
  
  local limit = -1500
  
  -- Check we are not too far out w.r.t back of the boat.
  if diffX < limit then
  
    local relhead=self:_GetRelativeHeading(playerData.unit)

    if relhead<45 then
    
      local hint = "Too long downwind. Turn final earlier next time."
      self:_SendMessageToPlayer(hint, 8, playerData)
      
      self:_AddToSummary(playerData, hint)
      
      playerData.score=playerData.score-40
      
      -- Long downwind done!
      playerData.longDownwindDone = true
    end
    
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
  
  local limitEast = -1111 --0.6nm
  
  --if diffZ > limitEast then
  if self:_CheckLimits(diffX, diffZ, self.Ninety) then
  
    local alt=playerData.unit:GetAltitude()
    local aoa=playerData.unit:GetAoA()
    
    local hintAlt=self:_AltitudeCheck(playerData, self.Ninety, alt)
    local hintAoA=self:_AoACheck(playerData, self.Ninety, aoa)
    
    
    local hintFull=string.format("%s.\n%s.", hintAoA, hintAlt)
    self:_AddToSummary(playerData, hintFull)
    
    playerData.longDownwindDone = true
    
    -- Next step.
    playerData.step = 7
  end
end

--- Wake.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_Wake(playerData) 

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ = self:_GetDistances(playerData.unit)
    
  --if (diffZ < -2000 or diffX < -4000 or diffX > 0) then
  if self:_CheckAbort(diffX, diffZ, self.Wake) then
    self:_AbortPattern(playerData, diffX, diffZ, self.Wake)
    return
  end
  
  --if diffZ > 0 then
  if self:_CheckLimits(diffX, diffZ, self.Wake) then
  
    local alt=playerData.unit:GetAltitude()
    local aoa=playerData.unit:GetAoA()
  
    local hintAlt=self:_AltitudeCheck(playerData, self.Wake, alt)
    local hintAoA=self:_AoACheck(playerData, self.Wake, aoa)


    local hintFull=string.format("%s.\n%s.", hintAoA, hintAlt)
    self:_AddToSummary(playerData, hintFull)

    -- Next step.
    playerData.step = 8
  end
end

--- Groove.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_Groove(playerData)

  --TODO -100?!
  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffX, diffZ = self:_GetDistances(playerData.unit)
  
  --diffX=diffX+100
  
  -- In front of carrier or more than 4 km behind carrier. 
  --if (diffX > 0 or diffX < -4000) then
  if self:_CheckAbort(diffX, diffZ, self.Groove) then
    self:_AbortPattern(playerData, diffX, diffZ, self.Groove)
    return
  end
  
  --TODO: 
  if (diffX > -500) then --Reached in close before groove
  
    local hint = "You're too far left and never reached the groove."
    self:_SendMessageToPlayer( hint, 8, playerData )
    
    -- zero score
    self:_PrintScore(0, playerData, true)
    self:_AddToSummary(playerData, hint)
    
    -- Next step.
    playerData.step = 9
    
  else
  
    local limitDeg = 8.0
      
    -- TODO: what is this angle? Does not make sense!
    local fraction = diffZ / (-diffX)
    local asinValue = math.asin(fraction)
    local angle = math.deg(asinValue)
    
    if diffZ > -1300 and angle > limitDeg then

      -- Altitude check.
      local score, hint=self:_AltitudeCheck(playerData, self.Groove)

      -- AoA feed back
      local aoa = playerData.unit:GetAoA() 
      local score, hint=self:_AoACheck(aoa, self.Groove,playerData)

      -- TODO
      --local fullHint = hint .. " (" .. aoaFeedback .. ")"
      --self:_AddToSummary(playerData, fullHint)
      
      -- Next step.
      playerData.step = 9
    end
  end
end

--- Trap.
-- @param #CARRIERTRAINER self
-- @param #CARRIERTRAINER.PlayerData playerData Player data table.
function CARRIERTRAINER:_Trap(playerData) 

  -- Get distances between carrier and player unit (parallel and perpendicular to direction of movement of carrier)
  local diffZ, diffX = self:_GetDistances(playerData.unit)
  
  -- Player altitude
  local alt=playerData.unit:GetAltitude()

  -- Get velocities.
  local playerVelocity = playerData.unit:GetVelocityKMH()
  local carrierVelocity = self.carrier:GetVelocityKMH()

  --if(diffZ < -2000 or diffZ > 2000 or diffX < -3000) then
  if self:_CheckAbort(diffX, diffZ, self.Trap) then
    self:_AbortPattern(playerData, diffX, diffZ, self.Trap)
    return
  end

  if (diffX > playerData.highestCarrierXDiff) then
    playerData.highestCarrierXDiff = diffX
  end
  
  if (alt < playerData.lowestAltitude) then
    playerData.lowestAltitude = alt
  end
  
  if math.abs(playerVelocity-carrierVelocity) < 0.01 then
  
    playerData.secondsStandingStill = playerData.secondsStandingStill + 1
  
    if diffX < playerData.highestCarrierXDiff or playerData.secondsStandingStill > 5 then
      
      env.info("Trap identified! diff " .. diffX .. ",  highestCarrierXDiff" .. playerData.highestCarrierXDiff .. ", secondsStandingStill: " .. playerData.secondsStandingStill);
        
      local wire = 1
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
      
      self:_IncreaseScore(playerData, score)
      
      self:_SendMessageToPlayer( "TRAPPED! " .. wire .. "-wire!", 30, playerData )
      self:_PrintScore(score, playerData, false)

      env.info("Distance! " .. diffX .. " meters resulted in a " .. wire .. "-wire estimation.");
      
      local fullHint = "Trapped catching the " .. wire .. "-wire."
      
      self:_AddToSummary(playerData, fullHint)
      
      self:_PrintFinalScore(playerData, 60, wire)
      self:_HandleCollectedResult(playerData, wire)
      playerData.step = 0
    end
    
  elseif (diffX > 150) then
    
    local wire  = 0
    local hint  = ""
    local score = 0
    if (playerData.lowestAltitude < 23) then
      hint  = "You boltered."
    else
      hint  = "You were waved off."
      wire  = -1
      score = -10
    end
    
    self:_SendMessageToPlayer( hint, 8, playerData )
    self:_PrintScore(score, playerData, true)
       
    self:_AddToSummary(playerData, hint)
    
    self:_PrintFinalScore(playerData, 60, wire)
    self:_HandleCollectedResult(playerData, wire)
    
    playerData.step = 0
  end 
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
        local _rangePath    = missionCommands.addSubMenuForGroup(_gid, self.alias, CARRIERTRAINER.MenuF10[_gid])
        local _statsPath    = missionCommands.addSubMenuForGroup(_gid, "Results",   _rangePath)
        local _settingsPath = missionCommands.addSubMenuForGroup(_gid, "My Settings",  _rangePath)
        local _infoPath     = missionCommands.addSubMenuForGroup(_gid, "Carrier Info",   _rangePath)

        -- F10/On the Range/<Range Name>/Stats/
        --missionCommands.addCommandForGroup(_gid, "All Results",       _statsPath, self._DisplayStrafePitResults, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "My Results",        _statsPath, self._DisplayBombingResults, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "Reset All Results", _statsPath, self._ResetRangeStats, self, _unitName)
        -- F10/On the Range/<Range Name>/My Settings/
        --missionCommands.addCommandForGroup(_gid, "Smoke Delay On/Off",  _settingsPath, self._SmokeBombDelayOnOff, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "Smoke Impact On/Off",  _settingsPath, self._SmokeBombImpactOnOff, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "Flare Hits On/Off",    _settingsPath, self._FlareDirectHitsOnOff, self, _unitName)        
        -- F10/On the Range/<Range Name>/Range Information
        --missionCommands.addCommandForGroup(_gid, "General Info",        _infoPath, self._DisplayRangeInfo, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Weather Report",      _infoPath, self._DisplayCarrierWeather, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "Bombing Targets",     _infoPath, self._DisplayBombTargets, self, _unitName)
        --missionCommands.addCommandForGroup(_gid, "Strafe Pits",         _infoPath, self._DisplayStrafePits, self, _unitName)
      end
    else
      self:T(self.lid.."Could not find group or group ID in AddF10Menu() function. Unit name: ".._unitName)
    end
  else
    self:T(self.lid.."Player unit does not exist in AddF10Menu() function. Unit name: ".._unitName)
  end

end

--- Report weather conditions at range. Temperature, QFE pressure and wind data.
-- @param #CARRIERTRAINER self
-- @param #string _unitname Name of the player unit.
function CARRIERTRAINER:_DisplayCarrierWeather(_unitname)
  self:E(_unitname)

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
  
  hint=hint..string.format(" %d deviation from %d ft target alt.", _error, UTILS.MetersToFeet(checkpoint.Altitude))
  
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
  local dnm=UTILS.MetersToNM(distance)
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
  
  hint=hint..string.format(" %d\% deviation from %d target distance %.1f NM.", _error, UTILS.MetersToNM(checkpoint.Distance))

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
  
  hint=hint..string.format(" %d\% deviation from %d target AoA.", _error, checkpoint.AoA)

  -- Set score.
  playerData.score=playerData.score+score
  
  return hint
end


--- Send message to playe client.
-- @param #CARRIERTRAINER self
-- @param #string message The message to send.
-- @param #number duration Display message duration.
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
function CARRIERTRAINER:_SendMessageToPlayer(message, duration, playerData)
  if playerData.client then
    MESSAGE:New(string.format("%s, %s, ", self.alias, playerData.callsign)..message, duration):ToClient(playerData.client)
  end
end

--- Send message to playe client.
-- @param #CARRIERTRAINER self
-- @param #number score Score.
-- @param #CARRIERTRAINER.PlayerData playerData Player data.
-- @param #boolean printtotal Also print total score.
function CARRIERTRAINER:_PrintScore(score, playerData, printtotal)

  if printtotal then
    self:_SendMessageToPlayer( "Score: " .. score .. " (Total: " .. playerData.score .. ")", 8, playerData )
  else
    self:_SendMessageToPlayer( "Score: " .. score, 8, playerData )
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
  self:_SendMessageToPlayer( playerData.summary, duration, playerData )
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
  
  if playerData.collectedResultString == "" then
    playerData.collectedResultString = newString
  else
    playerData.collectedResultString = playerData.collectedResultString .. ", " .. newString
    MessageToAll( playerData.callsign .. "'s " .. playerData.passes .. " passes: " .. playerData.collectedResultString .. " (TOTAL: " .. playerData.totalScore .. ")"  , 30, "CollectedResult" )
  end
  
  local heading=playerData.unit:GetCoordinate():HeadingTo(self.startZone:GetCoordinate())
  local distance=playerData.unit:GetCoordinate():Get2DDistance(self.startZone:GetCoordinate())
  local text=string.format("%s, fly heading %d for %d nm to restart the pattern.", playerData.callsign, heading, UTILS.MetersToNM(distance))
   --"Return south 4 nm (over the trailing ship), towards WP 1, to restart the pattern."
  self:_SendMessageToPlayer(text, 30, playerData)
end


--- Get the formatted score.
-- @param #CARRIERTRAINER self
-- @param #number score Score of player.
-- @param #number maxScore Max score possible.
-- @return #string Formatted score text.
function CARRIERTRAINER:_GetFormattedScore(score, maxScore)
  if(score < maxScore) then
    return " (" .. score .. " points)."
  else
    return " (" .. score .. " points)!"
  end
end

--- Get distance feedback.
-- @param #CARRIERTRAINER self
-- @param #number distance Distance to boat.
-- @param #number idealDistance Ideal distance.
-- @return #string Feedback text.
function CARRIERTRAINER:_GetDistanceFeedback(distance, idealDistance)
  return distance .. " nm (Target: " .. idealDistance .. " nm)"
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


