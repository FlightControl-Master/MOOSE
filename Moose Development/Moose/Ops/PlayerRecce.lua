--- **Ops** - Allow a player in a helo like the Gazelle, KA-50 to recon and lase ground targets.
--
-- ## Features:
--
--   * Allow a player in a helicopter to detect, smoke, flare, lase and report ground units to others.
--   * Implements visual detection from the helo
--   * Implements optical detection via the Gazelle Vivianne system and lasing
--   * KA-50 BlackShark basic support
--   * Everyone else gets visual detection only
--   * Upload target info to a PLAYERTASKCONTROLLER Instance
--
-- ===
--
-- # Demo Missions
--
-- ### Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/).
--
-- ===
--
--
-- ### Authors:
--
--   * Applevangelist (Design & Programming)
--   
-- ===
--
-- @module Ops.PlayerRecce
-- @image Ops_PlayerRecce.png

-------------------------------------------------------------------------------------------------------------------
-- PLAYERRECCE
-- TODO: PLAYERRECCE
-- DONE: No messages when no targets to flare or smoke
-- DONE: Smoke not all targets
-- DONE: Messages to Attack Group, use client settings
-- DONE: Lasing dist 8km
-- DONE: Reference Point RP
-- DONE: Sort for multiple targets in one direction
-- DONE: Targets with forget timeout, also report 
-------------------------------------------------------------------------------------------------------------------

--- PLAYERRECCE class.
-- @type PLAYERRECCE
-- @field #string ClassName Name of the class.
-- @field #boolean verbose Switch verbosity.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string version
-- @field #table ViewZone
-- @field #table ViewZoneVisual
-- @field #table ViewZoneLaser
-- @field #table LaserFOV
-- @field #table LaserTarget
-- @field Core.Set#SET_CLIENT PlayerSet
-- @field #string Name
-- @field #number Coalition
-- @field #string CoalitionName
-- @field #boolean debug
-- @field #table LaserSpots
-- @field #table UnitLaserCodes
-- @field #table LaserCodes
-- @field #table ClientMenus
-- @field #table OnStation
-- @field #number minthreatlevel
-- @field #number lasingtime
-- @field #table AutoLase
-- @field Core.Set#SET_CLIENT AttackSet
-- @field #boolean TransmitOnlyWithPlayers
-- @field Sound.SRS#MSRS SRS
-- @field Sound.SRS#MSRSQUEUE SRSQueue
-- @field #boolean UseController
-- @field Ops.PlayerTask#PLAYERTASKCONTROLLER Controller
-- @field #boolean ShortCallsign
-- @field #boolean Keepnumber
-- @field #table CallsignTranslations
-- @field Core.Point#COORDINATE ReferencePoint
-- @field #string RPName
-- @field Wrapper.Marker#MARKER RPMarker
-- @field #number TForget
-- @field Utilities.FiFo#FIFO TargetCache
-- @field #boolean smokeownposition
-- @field #table SmokeOwn
-- @field #boolean smokeaveragetargetpos
-- @field #boolean reporttostringbullsonly
-- @extends Core.Fsm#FSM

---
--
-- *It is our attitude at the beginning of a difficult task which, more than anything else, which will affect its successful outcome.* (William James)
--
-- ===
-- 
-- # PLAYERRECCE 
-- 
--   * Allow a player in a helicopter to detect, smoke, flare, lase and report ground units to others.
--   * Implements visual detection from the helo
--   * Implements optical detection via the Gazelle Vivianne system and lasing
--   * KA-50 BlackShark basic support
--   * Everyone else gets visual detection only
--   * Upload target info to a PLAYERTASKCONTROLLER Instance
--    
-- If you have questions or suggestions, please visit the [MOOSE Discord](https://discord.gg/AeYAkHP) channel.  
-- 
--                          
-- @field #PLAYERRECCE
PLAYERRECCE = {
  ClassName          =   "PLAYERRECCE",
  verbose            =   true,
  lid                =   nil,
  version            =   "0.1.26",
  ViewZone           =   {},
  ViewZoneVisual     =   {},
  ViewZoneLaser      =   {},
  LaserFOV           =   {},
  LaserTarget        =   {},
  PlayerSet          =   nil,
  debug              =   false,
  LaserSpots         =   {},
  UnitLaserCodes     =   {},
  LaserCodes         =   {},
  ClientMenus        =   {},
  OnStation          =   {},
  minthreatlevel     =   0,
  lasingtime         =   60,
  AutoLase           =   {},
  AttackSet          =   nil,
  TransmitOnlyWithPlayers = true,
  UseController      =   false,
  Controller         =   nil,
  ShortCallsign      =   true,
  Keepnumber         =   true,
  CallsignTranslations = nil,
  ReferencePoint     =   nil,
  TForget            =   600,
  TargetCache        =   nil,
  smokeownposition   =   false,
  SmokeOwn           =   {},
  smokeaveragetargetpos = true,
  reporttostringbullsonly = true,
}

--- 
-- @type PlayerRecceDetected
-- @field #boolean detected
-- @field Wrapper.Client#CLIENT recce
-- @field #string playername
-- @field #number timestamp

---
-- @type LaserRelativePos
-- @field #string typename Unit type name
PLAYERRECCE.LaserRelativePos = {
  ["SA342M"] = { x = 1.7, y = 1.2, z = 0 },
  ["SA342Mistral"] = { x = 1.7, y = 1.2, z = 0 },
  ["SA342Minigun"] = { x = 1.7, y = 1.2, z = 0 },
  ["SA342L"] = { x = 1.7, y = 1.2, z = 0 },
  ["Ka-50"] = { x = 6.1, y = -0.85 , z = 0 },
  ["Ka-50_3"] = { x = 6.1, y = -0.85 , z = 0 },
  ["OH58D"] = {x = 0, y = 2.8, z = 0},
}

---
-- @type MaxViewDistance
-- @field #string typename Unit type name
PLAYERRECCE.MaxViewDistance = {
  ["SA342M"] = 8000,
  ["SA342Mistral"] = 8000,
  ["SA342Minigun"] = 8000,
  ["SA342L"] = 8000,
  ["Ka-50"] = 8000, 
  ["Ka-50_3"] = 8000,
  ["OH58D"] = 8000, 
}

---
-- @type Cameraheight
-- @field #string typename Unit type name
PLAYERRECCE.Cameraheight = {
  ["SA342M"] = 2.85,
  ["SA342Mistral"] = 2.85,
  ["SA342Minigun"] = 2.85,
  ["SA342L"] = 2.85,
  ["Ka-50"] = 0.5, 
  ["Ka-50_3"] = 0.5,
  ["OH58D"] = 4.25, 
}

---
-- @type CanLase
-- @field #string typename Unit type name
PLAYERRECCE.CanLase = {
  ["SA342M"] = true,
  ["SA342Mistral"] = true,
  ["SA342Minigun"] = false, -- no optics
  ["SA342L"] = true,
  ["Ka-50"] = true,
  ["Ka-50_3"] = true,
  ["OH58D"] = false, -- has onboard and useable laser   
}

---
-- @type SmokeColor
-- @field #string color
PLAYERRECCE.SmokeColor = {
  ["highsmoke"] = SMOKECOLOR.Orange,
  ["medsmoke"] = SMOKECOLOR.White,
  ["lowsmoke"] = SMOKECOLOR.Green,
  ["lasersmoke"] = SMOKECOLOR.Red,
  ["ownsmoke"] = SMOKECOLOR.Blue,
}

---
-- @type FlareColor
-- @field #string color
PLAYERRECCE.FlareColor = {
  ["highflare"] =FLARECOLOR.Yellow,
  ["medflare"] = FLARECOLOR.White,
  ["lowflare"] = FLARECOLOR.Green,
  ["laserflare"] = FLARECOLOR.Red,
  ["ownflare"] = FLARECOLOR.Green,
}

--- Create and run a new PlayerRecce instance.
-- @param #PLAYERRECCE self
-- @param #string Name The name of this instance
-- @param #number Coalition, e.g. coalition.side.BLUE
-- @param Core.Set#SET_CLIENT PlayerSet The set of pilots working as recce
-- @return #PLAYERRECCE self
function PLAYERRECCE:New(Name, Coalition, PlayerSet)
  
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #PLAYERRECCE
  
  self.Name = Name or "Blue FACA"
  self.Coalition = Coalition or coalition.side.BLUE
  self.CoalitionName = UTILS.GetCoalitionName(Coalition)
  self.PlayerSet = PlayerSet
  
  self.lid=string.format("PlayerForwardController %s %s | ", self.Name, self.version)
  
  self:SetLaserCodes( { 1688, 1130, 4785, 6547, 1465, 4578 } ) -- set self.LaserCodes
  self.lasingtime = 60
  
  self.minthreatlevel = 0
  
  self.reporttostringbullsonly = true
  
  self.TForget = 600
  self.TargetCache = FIFO:New()
  
  -- FSM start state is STOPPED.
  self:SetStartState("Stopped")
  
  self:AddTransition("Stopped",      "Start",               "Running")
  self:AddTransition("*",            "Status",              "*")
  self:AddTransition("*",            "RecceOnStation",      "*")
  self:AddTransition("*",            "RecceOffStation",     "*")
  self:AddTransition("*",            "TargetDetected",      "*")
  self:AddTransition("*",            "TargetsSmoked",       "*")
  self:AddTransition("*",            "TargetsFlared",       "*")
  self:AddTransition("*",            "Illumination",        "*")
  self:AddTransition("*",            "TargetLasing",        "*")
  self:AddTransition("*",            "TargetLOSLost",       "*")
  self:AddTransition("*",            "TargetReport",        "*")
  self:AddTransition("*",            "TargetReportSent",    "*")
  self:AddTransition("*",            "Shack",                "*")
  self:AddTransition("Running",      "Stop",                "Stopped")
  
  -- Player Events
  self:HandleEvent(EVENTS.PlayerLeaveUnit, self._EventHandler)
  self:HandleEvent(EVENTS.Ejection, self._EventHandler)
  self:HandleEvent(EVENTS.Crash, self._EventHandler)
  self:HandleEvent(EVENTS.PilotDead, self._EventHandler)
  self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
  
  self:__Start(-1)
  local starttime = math.random(5,10)
  self:__Status(-starttime)
  
  self:I(self.lid.." Started.")
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------
  
    --- Triggers the FSM event "Start". Starts the PLAYERRECCE. Note: Start() is called automatically after New().
  -- @function [parent=#PLAYERRECCE] Start
  -- @param #PLAYERRECCE self

  --- Triggers the FSM event "Start" after a delay. Starts the PLAYERRECCE. Note: Start() is called automatically after New().
  -- @function [parent=#PLAYERRECCE] __Start
  -- @param #PLAYERRECCE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the PLAYERRECCE and all its event handlers.
  -- @param #PLAYERRECCE self
  
  --- Triggers the FSM event "Stop" after a delay. Stops the PLAYERRECCE and all its event handlers.
  -- @function [parent=#PLAYERRECCE] __Stop
  -- @param #PLAYERRECCE self
  -- @param #number delay Delay in seconds.
 
  --- FSM Function OnAfterRecceOnStation. Recce came on station.
  -- @function [parent=#PLAYERRECCE] OnAfterRecceOnStation
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Client#CLIENT Client
  -- @param #string Playername
  -- @return #PLAYERRECCE self
   
  --- FSM Function OnAfterRecceOffStation. Recce went off duty.
  -- @function [parent=#PLAYERRECCE] OnAfterRecceOffStation
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Client#CLIENT Client
  -- @param #string Playername
  -- @return #PLAYERRECCE self
   
  --- FSM Function OnAfterTargetDetected. Targets detected.
  -- @function [parent=#PLAYERRECCE] OnAfterTargetDetected
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param #table Targetsbyclock #table with index 1..12 containing a #table of Wrapper.Unit#UNIT objects each.
  -- @param Wrapper.Client#CLIENT Client
  -- @param #string Playername
  -- @return #PLAYERRECCE self
  
  --- FSM Function OnAfterTargetsSmoked. Smoke grenade shot.
  -- @function [parent=#PLAYERRECCE] OnAfterTargetsSmoked
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Client#CLIENT Client
  -- @param #string Playername
  -- @param Core.Set#SET_UNIT TargetSet
  -- @return #PLAYERRECCE self
   
  --- FSM Function OnAfterTargetsFlared. Flares shot.
  -- @function [parent=#PLAYERRECCE] OnAfterTargetsFlared
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Client#CLIENT Client
  -- @param #string Playername
  -- @param Core.Set#SET_UNIT TargetSet
  -- @return #PLAYERRECCE self
   
  --- FSM Function OnAfterIllumination. Illumination rocket shot.
  -- @function [parent=#PLAYERRECCE] OnAfterIllumination
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Client#CLIENT Client
  -- @param #string Playername
  -- @param Core.Set#SET_UNIT TargetSet
  -- @return #PLAYERRECCE self
   
  --- FSM Function OnAfterTargetLasing. Lasing a new target.
  -- @function [parent=#PLAYERRECCE] OnAfterTargetLasing
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Client#CLIENT Client
  -- @param Wrapper.Unit#UNIT Target
  -- @param #number Lasercode
  -- @param #number Lasingtime
  -- @return #PLAYERRECCE self
   
  --- FSM Function OnAfterTargetLOSLost. Lost LOS on lased target.
  -- @function [parent=#PLAYERRECCE] OnAfterTargetLOSLost
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Client#CLIENT Client
  -- @param Wrapper.Unit#UNIT Target
  -- @return #PLAYERRECCE self
   
  --- FSM Function OnAfterTargetReport. Laser target report sent.
  -- @function [parent=#PLAYERRECCE] OnAfterTargetReport
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Client#CLIENT Client
  -- @param Core.Set#SET_UNIT TargetSet
  -- @param Wrapper.Unit#UNIT Target Target currently lased
  -- @param #string Text
  -- @return #PLAYERRECCE self
   
  --- FSM Function OnAfterTargetReportSent. All targets report sent.
  -- @function [parent=#PLAYERRECCE] OnAfterTargetReportSent
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Client#CLIENT Client Client sending the report
  -- @param #string Playername Player name
  -- @param Core.Set#SET_UNIT TargetSet Set of targets
  -- @return #PLAYERRECCE self
   
  --- FSM Function OnAfterShack. Lased target has been destroyed.
  -- @function [parent=#PLAYERRECCE] OnAfterShack
  -- @param #PLAYERRECCE self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Client#CLIENT Client
  -- @param Wrapper.Unit#UNIT Target The destroyed target (if obtainable)
  -- @return #PLAYERRECCE self
  
  return self
end

------------------------------------------------------------------------------------------
-- TODO: Functions
------------------------------------------------------------------------------------------

--- [Internal] Event handling
-- @param #PLAYERRECCE self
-- @param Core.Event#EVENTDATA EventData
-- @return #PLAYERRECCE self
function PLAYERRECCE:_EventHandler(EventData)
  self:T(self.lid.."_EventHandler: "..EventData.id)
  if EventData.id == EVENTS.PlayerLeaveUnit or EventData.id == EVENTS.Ejection or EventData.id == EVENTS.Crash or EventData.id == EVENTS.PilotDead then
    if EventData.IniPlayerName then
      self:T(self.lid.."Event for player: "..EventData.IniPlayerName)
      if self.ClientMenus[EventData.IniPlayerName] then
        self.ClientMenus[EventData.IniPlayerName]:Remove()
      end  
      self.ClientMenus[EventData.IniPlayerName] = nil
      self.LaserSpots[EventData.IniPlayerName] = nil
      self.OnStation[EventData.IniPlayerName] = false
      self.LaserFOV[EventData.IniPlayerName] = nil
      self.UnitLaserCodes[EventData.IniPlayerName] = nil
      self.LaserTarget[EventData.IniPlayerName] = nil
      self.AutoLase[EventData.IniPlayerName] = false
      if self.ViewZone[EventData.IniPlayerName] then self.ViewZone[EventData.IniPlayerName]:UndrawZone() end
      if self.ViewZoneLaser[EventData.IniPlayerName] then self.ViewZoneLaser[EventData.IniPlayerName]:UndrawZone() end
      if self.ViewZoneVisual[EventData.IniPlayerName] then self.ViewZoneVisual[EventData.IniPlayerName]:UndrawZone() end
    end
  elseif EventData.id == EVENTS.PlayerEnterAircraft and EventData.IniCoalition == self.Coalition then
    if EventData.IniPlayerName then
      self:T(self.lid.."Event for player: "..EventData.IniPlayerName)
      self.UnitLaserCodes[EventData.IniPlayerName] = 1688
      self.ClientMenus[EventData.IniPlayerName] = nil
      self.LaserSpots[EventData.IniPlayerName] = nil
      self.OnStation[EventData.IniPlayerName] = false
      self.LaserFOV[EventData.IniPlayerName] = nil
      self.UnitLaserCodes[EventData.IniPlayerName] = nil
      self.LaserTarget[EventData.IniPlayerName] = nil
      self.AutoLase[EventData.IniPlayerName] = false
      if self.ViewZone[EventData.IniPlayerName] then self.ViewZone[EventData.IniPlayerName]:UndrawZone() end
      if self.ViewZoneLaser[EventData.IniPlayerName] then self.ViewZoneLaser[EventData.IniPlayerName]:UndrawZone() end
      if self.ViewZoneVisual[EventData.IniPlayerName] then self.ViewZoneVisual[EventData.IniPlayerName]:UndrawZone() end
      self:_BuildMenus()
    end
  end
  return self
end

--- (Internal) Function to determine clockwise direction to target.
-- @param #PLAYERRECCE self
-- @param Wrapper.Unit#UNIT unit The Helicopter
-- @param Wrapper.Unit#UNIT target The downed Group
-- @return #number direction
function PLAYERRECCE:_GetClockDirection(unit, target)
  self:T(self.lid .. " _GetClockDirection")
 
  local _playerPosition = unit:GetCoordinate() -- get position of helicopter
  local _targetpostions = target:GetCoordinate() -- get position of downed pilot
  local _heading = unit:GetHeading() -- heading
  --self:I("Heading = ".._heading)
  local DirectionVec3 = _playerPosition:GetDirectionVec3( _targetpostions )
  local Angle = _playerPosition:GetAngleDegrees( DirectionVec3 )
  --self:I("Angle = "..Angle)
  local clock = 12
  local hours = 0   
  if _heading and Angle then
    clock = 12
    --if angle == 0 then angle = 360 end
    clock = _heading-Angle  
    hours = (clock/30)*-1
    --self:I("hours = "..hours)
    clock = 12+hours
    clock = UTILS.Round(clock,0)
    if clock > 12 then clock = clock-12 end
    if clock == 0 then clock = 12 end
  end
  --self:I("Clock ="..clock)    
  return clock
end

--- [User] Set a table of possible laser codes.
-- Each new RECCE can select a code from this table, default is { 1688, 1130, 4785, 6547, 1465, 4578 }.
-- @param #PLAYERRECCE self
-- @param #list<#number> LaserCodes
-- @return #PLAYERRECCE
function PLAYERRECCE:SetLaserCodes( LaserCodes )
  self.LaserCodes = ( type( LaserCodes ) == "table" ) and LaserCodes or { LaserCodes }
  return self
end

--- [User] Set a reference point coordinate for A2G Operations. Will be used in coordinate references.
-- @param #PLAYERRECCE self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the RP
-- @param #string Name Name of the RP
-- @return #PLAYERRECCE
function PLAYERRECCE:SetReferencePoint(Coordinate,Name)
  self.ReferencePoint = Coordinate
  self.RPName = Name
  if self.RPMarker then
    self.RPMarker:Remove()
  end
  local llddm = Coordinate:ToStringLLDDM()
  local lldms = Coordinate:ToStringLLDMS()
  local mgrs = Coordinate:ToStringMGRS()
  local text = string.format("%s RP %s\n%s\n%s\n%s",self.Name,Name,llddm,lldms,mgrs)
  self.RPMarker = MARKER:New(Coordinate,text)
  self.RPMarker:ReadOnly()
  self.RPMarker:ToCoalition(self.Coalition)
  return self
end

--- [User] Set PlayerTaskController. Allows to upload target reports to the controller, in turn creating tasks for other players.
-- @param #PLAYERRECCE self
-- @param Ops.PlayerTask#PLAYERTASKCONTROLLER Controller
-- @return #PLAYERRECCE
function PLAYERRECCE:SetPlayerTaskController(Controller)
  self.UseController = true
  self.Controller = Controller
  return self
end

--- [User] Set a set of clients which will receive target reports
-- @param #PLAYERRECCE self
-- @param Core.Set#SET_CLIENT AttackSet
-- @return #PLAYERRECCE
function PLAYERRECCE:SetAttackSet(AttackSet)
  self.AttackSet = AttackSet
  return self
end

---[Internal] Check Helicopter camera in on
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param #string playername
-- @return #boolean OnOff
function PLAYERRECCE:_CameraOn(client,playername)
  local camera = true
  local unit = client -- Wrapper.Unit#UNIT
  if unit and unit:IsAlive() then
    local typename = unit:GetTypeName()
    if string.find(typename,"SA342") then
      local dcsunit = Unit.getByName(client:GetName())
      local vivihorizontal = dcsunit:getDrawArgumentValue(215) or 0 -- (not in MiniGun) 1 to -1 -- zero is straight ahead, 1/-1 = 180 deg
      if vivihorizontal < -0.7 or vivihorizontal > 0.7 then 
        camera = false
      end
    elseif string.find(typename,"OH58") then
      local dcsunit = Unit.getByName(client:GetName())
      local vivihorizontal = dcsunit:getDrawArgumentValue(528) or 0 -- Kiow
      if vivihorizontal < -0.527 or vivihorizontal > 0.527 then 
        camera = false
      end  
    elseif string.find(typename,"Ka-50")  then
      camera = true
    end
  end
  return camera
end

--- [Internal] Get the view parameters from a Kiowa MMS camera
-- @param #PLAYERRECCE self
-- @param Wrapper.Unit#UNIT Kiowa
-- @return #number cameraheading in degrees.
-- @return #number cameranodding in degrees.
-- @return #number maxview in meters.
-- @return #boolean cameraison If true, camera is on, else off.
function PLAYERRECCE:_GetKiowaMMSSight(Kiowa)
  self:T(self.lid.."_GetKiowaMMSSight")
  local unit = Kiowa -- Wrapper.Unit#UNIT
  if unit and unit:IsAlive() then
    local dcsunit = Unit.getByName(Kiowa:GetName())
    --[[
    shagrat — 01/01/2025 23:13
    Found the necessary ARGS for the Kiowa MMS angle and rotation:
    Arg 527 vertical movement
     0 = neutral
    -1.0 = max depression (30° max depression angle)
    +1.0 = max elevation angle (30° max elevation angle)
    
    Arg 528 horizontal movement 
    0 = forward (0 degr)
    -0.25 = 90° left
    -0.5 = rear (180°) left (max 190° = -0.527
    +0.25 = 90° right
    +0.5 = 180° right (max 190° = 0.527)
    --]]
    local mmshorizontal = dcsunit:getDrawArgumentValue(528) or 0
    local mmsvertical = dcsunit:getDrawArgumentValue(527) or 0
    self:T(string.format("Kiowa MMS Arguments Read: H %.3f V %.3f",mmshorizontal,mmsvertical))
    local mmson = true
    if mmshorizontal < -0.527 or mmshorizontal > 0.527 then mmson = false end
    local horizontalview = mmshorizontal / 0.527 * 190
    local heading = unit:GetHeading()
    local mmsheading = (heading+horizontalview)%360
    --local mmsyaw = mmsvertical * 30
    local mmsyaw = math.atan(mmsvertical)*40
    local maxview = self:_GetActualMaxLOSight(unit,mmsheading, mmsyaw,not mmson)
    if maxview > 8000 then maxview = 8000 end
    self:T(string.format("Kiowa MMS Heading %d, Yaw %d, MaxView %dm MMS On %s",mmsheading,mmsyaw,maxview,tostring(mmson)))
    return mmsheading,mmsyaw,maxview,mmson
  end
  return 0,0,0,false
end


--- [Internal] Get the view parameters from a Gazelle camera
-- @param #PLAYERRECCE self
-- @param Wrapper.Unit#UNIT Gazelle
-- @return #number cameraheading in degrees.
-- @return #number cameranodding in degrees.
-- @return #number maxview in meters.
-- @return #boolean cameraison If true, camera is on, else off.
function PLAYERRECCE:_GetGazelleVivianneSight(Gazelle)
  self:T(self.lid.."GetGazelleVivianneSight")
  local unit = Gazelle -- Wrapper.Unit#UNIT
  if unit and unit:IsAlive() then
    local dcsunit = Unit.getByName(Gazelle:GetName())
    local vivihorizontal = dcsunit:getDrawArgumentValue(215) or 0 -- (not in MiniGun) 1 to -1 -- zero is straight ahead, 1/-1 = 180 deg,
    local vivivertical = dcsunit:getDrawArgumentValue(216) or 0 -- L/Mistral/Minigun model has no 216, ca 10deg up (=1) and down (=-1)
    -- vertical model limits 1.53846, -1.10731
    local vivioff = false
    -- -1 = -180, 1 = 180
    -- Actual model view -0,66 to 0,66
    -- Nick view 1.53846, -1.10731 for - 30° to +45° 
    if vivihorizontal < -0.67 then  -- model end
      vivihorizontal = -0.67
      vivioff = false
      --return 0,0,0,false 
    elseif vivihorizontal > 0.67 then -- vivi off
      vivihorizontal = 0.67
      vivioff = true
      return 0,0,0,false
    end

    local horizontalview = vivihorizontal * -180 
    --local verticalview = vivivertical * 30 -- ca +/- 30°
    local verticalview = math.atan(vivivertical)

    local heading = unit:GetHeading()
    local viviheading = (heading+horizontalview)%360
    local maxview = self:_GetActualMaxLOSight(unit,viviheading, verticalview,vivioff)
    if maxview > 8000 then maxview = 8000 end
    return viviheading, verticalview,maxview, not vivioff
  end
  return 0,0,0,false
end

--- [Internal] Get the max line of sight based on unit head and camera nod via trigonometry. Returns 0 if camera is off.
-- @param #PLAYERRECCE self
-- @param Wrapper.Unit#UNIT unit The unit which LOS we want
-- @param #number vheading Heading where the unit or camera is looking
-- @param #number vnod Nod down in degrees
-- @param #boolean vivoff Camera on or off
-- @return #number maxview Max view distance in meters
function PLAYERRECCE:_GetActualMaxLOSight(unit,vheading, vnod, vivoff)
  self:T(self.lid.."_GetActualMaxLOSight")
  if vivoff then return 0 end
  --if vnod < -0.03 then vnod = -0.03 end
  local maxview = 0
  if unit and unit:IsAlive() then
    local typename = unit:GetTypeName()
    maxview = self.MaxViewDistance[typename] or 8000  
    local CamHeight = self.Cameraheight[typename] or 1
    if vnod < -2 then
        -- Looking down
        -- determine max distance we're looking at
        local beta = 90
        local gamma = 90-math.abs(vnod)
        local alpha = 90-gamma
        local a = unit:GetHeight()-unit:GetCoordinate():GetLandHeight()+CamHeight
        local b = a / math.sin(math.rad(alpha))
        local c = b * math.sin(math.rad(gamma))
        maxview = c*1.2 -- +20%
    end
  end 
  return math.ceil(math.abs(maxview))
end

--- [User] Set callsign options for TTS output. See @{Wrapper.Group#GROUP.GetCustomCallSign}() on how to set customized callsigns.
-- @param #PLAYERRECCE self
-- @param #boolean ShortCallsign If true, only call out the major flight number
-- @param #boolean Keepnumber If true, keep the **customized callsign** in the #GROUP name for players as-is, no amendments or numbers.
-- @param #table CallsignTranslations (optional) Table to translate between DCS standard callsigns and bespoke ones. Does not apply if using customized
-- callsigns from playername or group name.
-- @param #func CallsignCustomFunc (Optional) For player names only(!). If given, this function will return the callsign. Needs to take the groupname and the playername as first two arguments.
-- @param #arg ... (Optional) Comma separated arguments to add to the custom function call after groupname and playername.
-- @return #PLAYERRECCE self
function PLAYERRECCE:SetCallSignOptions(ShortCallsign,Keepnumber,CallsignTranslations,CallsignCustomFunc,...)
  if not ShortCallsign or ShortCallsign == false then
   self.ShortCallsign = false
  else
   self.ShortCallsign = true
  end
  self.Keepnumber = Keepnumber or false
  self.CallsignTranslations = CallsignTranslations
  self.CallsignCustomFunc = CallsignCustomFunc
  self.CallsignCustomArgs = arg or {}
  return self  
end

--- [Internal] Build a ZONE_POLYGON from a given viewport of a unit
-- @param #PLAYERRECCE self
-- @param Wrapper.Unit#UNIT unit The unit which is looking
-- @param #number vheading Heading where the unit or camera is looking
-- @param #number minview Min line of sight - for lasing
-- @param #number maxview Max line of sight
-- @param #number angle  Angle left/right to be added to heading to form a triangle
-- @param #boolean camon Camera is switched on
-- @param #boolean laser Zone is for lasing
-- @return Core.Zone#ZONE_POLYGON ViewZone or nil if camera is off
function PLAYERRECCE:_GetViewZone(unit, vheading, minview, maxview, angle, camon, laser)
  self:T(self.lid.."_GetViewZone")
  local viewzone = nil
  if not camon then return nil end
  if unit and unit:IsAlive() then
    local unitname = unit:GetName()
    if not laser then
      -- Triangle
      local startpos = unit:GetCoordinate()
      local heading1 = (vheading+angle)%360
      local heading2 = (vheading-angle)%360
      local pos1 = startpos:Translate(maxview,heading1)
      local pos2 = startpos:Translate(maxview,heading2)
      local array = {}
      table.insert(array,startpos:GetVec2())
      table.insert(array,pos1:GetVec2())
      table.insert(array,pos2:GetVec2())
      viewzone = ZONE_POLYGON:NewFromPointsArray(unitname,array)
    else
      -- Square
      local startp = unit:GetCoordinate()
      local heading1 = (vheading+90)%360
      local heading2 = (vheading-90)%360
      self:T({heading1,heading2})
      local startpos = startp:Translate(minview,vheading)
      local pos1 = startpos:Translate(12.5,heading1)
      local pos2 = startpos:Translate(12.5,heading2)
      local pos3 = pos1:Translate(maxview,vheading)
      local pos4 = pos2:Translate(maxview,vheading)
      local array = {}
      table.insert(array,pos1:GetVec2())
      table.insert(array,pos2:GetVec2())
      table.insert(array,pos4:GetVec2())
      table.insert(array,pos3:GetVec2())
      viewzone = ZONE_POLYGON:NewFromPointsArray(unitname,array)
    end 
  end
  return viewzone
end

--- [Internal] 
--@param #PLAYERRECCE self
--@param Wrapper.Client#CLIENT client
--@return Core.Set#SET_UNIT Set of targets, can be empty!
--@return #number count Count of targets
function PLAYERRECCE:_GetKnownTargets(client)
  self:T(self.lid.."_GetKnownTargets")
  local finaltargets = SET_UNIT:New()
  local targets = self.TargetCache:GetDataTable()
  local playername = client:GetPlayerName()
  for _,_target in pairs(targets) do
    local targetdata = _target.PlayerRecceDetected -- Ops.PlayerRecce#PLAYERRECCE.PlayerRecceDetected
    if targetdata.playername == playername then
      finaltargets:Add(_target:GetName(),_target)
    end
  end
  return finaltargets,finaltargets:CountAlive()
end

--- [Internal] 
--@param #PLAYERRECCE self
--@return #PLAYERRECCE self
function PLAYERRECCE:_CleanupTargetCache()
  self:T(self.lid.."_CleanupTargetCache")
  local cleancache = FIFO:New()
  self.TargetCache:ForEach(
    function(unit)
      local pull = false
      if unit and unit:IsAlive() and unit:GetLife() > 1 then
        if unit.PlayerRecceDetected and unit.PlayerRecceDetected.timestamp then
          local TNow = timer.getTime()
          if TNow-unit.PlayerRecceDetected.timestamp > self.TForget then
            -- Forget this unit
            pull = true
            unit.PlayerRecceDetected=nil
          end
        else
          -- no timestamp
          pull = true
        end
      else
        -- dead
        pull = true
      end
      if not pull then
        cleancache:Push(unit,unit:GetName())
      end
    end
  )
  self.TargetCache = nil
  self.TargetCache = cleancache
  return self
end

--- [Internal] 
--@param #PLAYERRECCE self
--@param Wrapper.Unit#UNIT unit The FACA unit
--@param #boolean camera If true, use the unit's camera for targets in sight
--@param #laser laser Use laser zone
--@return Core.Set#SET_UNIT Set of targets, can be empty!
--@return #number count Count of targets
function PLAYERRECCE:_GetTargetSet(unit,camera,laser)
  self:T(self.lid.."_GetTargetSet")
  local finaltargets = SET_UNIT:New()
  local finalcount = 0
  local minview = 0
  local typename = unit:GetTypeName()
  local playername = unit:GetPlayerName()
  local maxview = self.MaxViewDistance[typename] or 8000
  local heading,nod,maxview,angle = 0,30,8000,10
  local camon = false
  local name = unit:GetName()
  if string.find(typename,"SA342") and camera then
    heading,nod,maxview,camon = self:_GetGazelleVivianneSight(unit)
    angle=10
    -- Model nod and actual TV view don't compute
    maxview = self.MaxViewDistance[typename] or 8000
  elseif string.find(typename,"Ka-50") and camera then
    heading = unit:GetHeading()
    nod,maxview,camon = 10,1000,true
    angle = 10
    maxview = self.MaxViewDistance[typename] or 8000
  elseif string.find(typename,"OH58") and camera then
    --heading = unit:GetHeading()
    nod,maxview,camon = 0,8000,true
    heading,nod,maxview,camon = self:_GetKiowaMMSSight(unit)
    angle = 8
    if maxview == 0 then
      maxview = self.MaxViewDistance[typename] or 8000
    end
  else
    -- visual
    heading = unit:GetHeading()
    nod,maxview,camon = 10,3000,true
    maxview = self.MaxViewDistance[typename] or 3000
    angle = 45
  end
  if laser then
    -- get min/max values
    if not self.LaserFOV[playername] then
      minview = 100
      maxview = 2000
      self.LaserFOV[playername] = {
        min=100,
        max=2000,
      }
    else
      minview = self.LaserFOV[playername].min
      maxview = self.LaserFOV[playername].max
    end
  end
  local zone = self:_GetViewZone(unit,heading,minview,maxview,angle,camon,laser)
  if zone then
    local redcoalition = "red"
    if self.Coalition == coalition.side.RED then
      redcoalition = "blue"
    end
    -- determine what we can see
    local startpos = unit:GetCoordinate()
    local targetset = SET_UNIT:New():FilterCategories("ground"):FilterActive(true):FilterZones({zone}):FilterCoalitions(redcoalition):FilterOnce()
    self:T("Prefilter Target Count = "..targetset:CountAlive())
    -- TODO - Threat level filter?
    -- TODO - Min distance from unit?
    targetset:ForEach(
      function(_unit)
        local _unit = _unit -- Wrapper.Unit#UNIT
        local _unitpos = _unit:GetCoordinate()
        if startpos:IsLOS(_unitpos) and _unit:IsAlive() and _unit:GetLife()>1 then
            self:T("Adding to final targets: ".._unit:GetName())
          finaltargets:Add(_unit:GetName(),_unit)
        end
      end
      )
    finalcount = finaltargets:CountAlive()
    self:T(string.format("%s Unit: %s | Targets in view %s",self.lid,name,finalcount))
  end
  return finaltargets, finalcount, zone
end

---[Internal] 
--@param #PLAYERRECCE self
--@param Core.Set#SET_UNIT targetset Set of targets, can be empty!
--@return Wrapper.Unit#UNIT Target or nil
function PLAYERRECCE:_GetHVTTarget(targetset)
   self:T(self.lid.."_GetHVTTarget")
   -- sort units
   local unitsbythreat = {}
   local minthreat = self.minthreatlevel or 0
   for _,_unit in pairs(targetset.Set) do
    local unit = _unit -- Wrapper.Unit#UNIT
    if unit and unit:IsAlive() and unit:GetLife() >1 then
      local threat = unit:GetThreatLevel()
      if threat >= minthreat then
        -- prefer radar units
        if unit:HasAttribute("RADAR_BAND1_FOR_ARM") or unit:HasAttribute("RADAR_BAND2_FOR_ARM") or unit:HasAttribute("Optical Tracker") then
          threat = 11
        end
        table.insert(unitsbythreat,{unit,threat})
      end
    end
  end
  
  table.sort(unitsbythreat, function(a,b)
    local aNum = a[2] -- Coin value of a
    local bNum = b[2] -- Coin value of b
    return aNum > bNum -- Return their comparisons, < for ascending, > for descending
  end)
 
 if unitsbythreat[1] and unitsbythreat[1][1] then   
  return unitsbythreat[1][1]  
 else
  return nil
 end
end

--- [Internal] 
--@param #PLAYERRECCE self
--@param Wrapper.Client#CLIENT client The FACA unit
--@param Core.Set#SET_UNIT targetset Set of targets, can be empty!
--@return #PLAYERRECCE self
function PLAYERRECCE:_LaseTarget(client,targetset)
  self:T(self.lid.."_LaseTarget")
  -- get one target
  local target = self:_GetHVTTarget(targetset) -- Wrapper.Unit#UNIT
  local playername = client:GetPlayerName()
  local laser = nil -- Core.Spot#SPOT
  -- set laser
  if not self.LaserSpots[playername] then
    laser = SPOT:New(client)
    if not self.UnitLaserCodes[playername] then
      self.UnitLaserCodes[playername] = 1688
    end
    laser.LaserCode = self.UnitLaserCodes[playername] or 1688
    self.LaserSpots[playername] = laser
  else
    laser = self.LaserSpots[playername]
  end
  -- old target
  if self.LaserTarget[playername] then
    -- still looking at target?
    local target=self.LaserTarget[playername] -- Ops.Target#TARGET
    local oldtarget = target:GetObject() --or laser.Target
    self:T("Targetstate: "..target:GetState())
    self:T("Laser State: "..tostring(laser:IsLasing()))
    if (not oldtarget) or targetset:IsNotInSet(oldtarget) or target:IsDead() or target:IsDestroyed() then
      -- lost LOS or dead
      laser:LaseOff()
      self:T(self.lid.."Target Life Points: "..target:GetLife() or "none")
      if target:IsDead() or target:IsDestroyed() or target:GetDamage() > 79 or target:GetLife() <= 1 then
        self:__Shack(-1,client,oldtarget)
        --self.LaserTarget[playername] = nil
      else
        self:__TargetLOSLost(-1,client,oldtarget)
        --self.LaserTarget[playername] = nil
      end
      self.LaserTarget[playername] = nil
      oldtarget = nil
      self.LaserSpots[playername] = nil
    elseif oldtarget and laser and (not laser:IsLasing()) then
      --laser:LaseOff()
      self:T("Switching laser back on ..")
      local lasercode = self.UnitLaserCodes[playername] or laser.LaserCode or 1688
      local lasingtime = self.lasingtime or 60
      --local targettype = target:GetTypeName()
      laser:LaseOn(oldtarget,lasercode,lasingtime)
      --self:__TargetLasing(-1,client,oldtarget,lasercode,lasingtime) 
    else
      -- we should not be here...
      self:T("Target alive and laser is on!")
      --self.LaserSpots[playername] = nil
    end
  -- new target
  elseif (not laser:IsLasing()) and target then
    local relativecam = self.LaserRelativePos[client:GetTypeName()]
    laser:SetRelativeStartPosition(relativecam)
    local lasercode = self.UnitLaserCodes[playername] or laser.LaserCode or 1688
    local lasingtime = self.lasingtime or 60
    --local targettype = target:GetTypeName()
    laser:LaseOn(target,lasercode,lasingtime) 
    self.LaserTarget[playername] = TARGET:New(target)
    --self.LaserTarget[playername].TStatus = 9
    self:__TargetLasing(-1,client,target,lasercode,lasingtime)
  end
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_SetClientLaserCode(client,group,playername,code)
  self:T(self.lid.."_SetClientLaserCode")
  self.UnitLaserCodes[playername] = code or 1688
  if self.ClientMenus[playername] then
    self.ClientMenus[playername]:Remove()
    self.ClientMenus[playername]=nil
  end
  self:_BuildMenus()
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_SwitchOnStation(client,group,playername)
  self:T(self.lid.."_SwitchOnStation")
  if not self.OnStation[playername] then
    self.OnStation[playername] = true
    self:__RecceOnStation(-1,client,playername)
  else
    self.OnStation[playername] = false
    self:__RecceOffStation(-1,client,playername)
  end
  if self.ClientMenus[playername] then
    self.ClientMenus[playername]:Remove()
    self.ClientMenus[playername]=nil
  end
  self:_BuildMenus(client)
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_SwitchSmoke(client,group,playername)
  self:T(self.lid.."_SwitchLasing")
  if not self.SmokeOwn[playername] then
    self.SmokeOwn[playername] = true
    MESSAGE:New("Smoke self is now ON",10,self.Name or "FACA"):ToClient(client)
  else
    self.SmokeOwn[playername] = false
    MESSAGE:New("Smoke self is now OFF",10,self.Name or "FACA"):ToClient(client)
  end
  if self.ClientMenus[playername] then
    self.ClientMenus[playername]:Remove()
    self.ClientMenus[playername]=nil
  end
  self:_BuildMenus(client)
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_SwitchLasing(client,group,playername)
  self:T(self.lid.."_SwitchLasing")
  if not self.AutoLase[playername] then
    self.AutoLase[playername] = true
    MESSAGE:New("Lasing is now ON",10,self.Name or "FACA"):ToClient(client)
  else
    self.AutoLase[playername] = false
    if self.LaserSpots[playername] then 
      local laser = self.LaserSpots[playername] -- Core.Spot#SPOT
      if laser:IsLasing() then
        laser:LaseOff()
      end
      self.LaserSpots[playername] = nil
    end
    MESSAGE:New("Lasing is now OFF",10,self.Name or "FACA"):ToClient(client)
  end
  if self.ClientMenus[playername] then
    self.ClientMenus[playername]:Remove()
    self.ClientMenus[playername]=nil
  end
  self:_BuildMenus(client)
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @param #number mindist
-- @param #number maxdist
-- @return #PLAYERRECCE self
function PLAYERRECCE:_SwitchLasingDist(client,group,playername,mindist,maxdist)
  self:T(self.lid.."_SwitchLasingDist")
  local mind  = mindist or 100
  local maxd  = maxdist or 2000
  if not self.LaserFOV[playername] then
    self.LaserFOV[playername] = {
      min=mind,
      max=maxd,
    }
  else
    self.LaserFOV[playername].min=mind
    self.LaserFOV[playername].max=maxd
  end
  MESSAGE:New(string.format("Laser distance set to %d-%dm!",mindist,maxdist),10,"FACA"):ToClient(client)
  if self.ClientMenus[playername] then
    self.ClientMenus[playername]:Remove()
    self.ClientMenus[playername]=nil
  end
  self:_BuildMenus(client)
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_WIP(client,group,playername)
  self:T(self.lid.."_WIP")
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_SmokeTargets(client,group,playername)
  self:T(self.lid.."_SmokeTargets")
  local cameraset = self:_GetTargetSet(client,true) -- Core.Set#SET_UNIT
  local visualset = self:_GetTargetSet(client,false) -- Core.Set#SET_UNIT
  
  if cameraset:CountAlive() > 0 or visualset:CountAlive() > 0 then
    self:__TargetsSmoked(-1,client,playername,cameraset)
  else
    return self
  end
  
  local highsmoke = self.SmokeColor.highsmoke
  local medsmoke = self.SmokeColor.medsmoke
  local lowsmoke = self.SmokeColor.lowsmoke
  local lasersmoke = self.SmokeColor.lasersmoke
  local laser = self.LaserSpots[playername] -- Core.Spot#SPOT
  
  -- laser targer gets extra smoke
  if laser and laser.Target and laser.Target:IsAlive() then
    laser.Target:GetCoordinate():Smoke(lasersmoke)
  end
  
  local coord = visualset:GetCoordinate()
  if coord and self.smokeaveragetargetpos then
    coord:SetAtLandheight()
    coord:Smoke(medsmoke)
  else
    -- smoke everything 
    for _,_unit in pairs(visualset.Set) do
      local unit = _unit --Wrapper.Unit#UNIT
      if unit and unit:IsAlive() then
        local coord = unit:GetCoordinate()
        local threat = unit:GetThreatLevel()
        if coord then
          local color = lowsmoke
          if threat > 7 then
            color = highsmoke
          elseif threat > 2 then
            color = medsmoke
          end
          coord:Smoke(color)
        end
      end
    end
  end
  if self.SmokeOwn[playername] then
    local cc = client:GetVec2()
    -- don't smoke mid-air
    local lc = COORDINATE:NewFromVec2(cc,1)
    local color = self.SmokeColor.ownsmoke
    lc:Smoke(color)
  end
  
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_FlareTargets(client,group,playername)
  self:T(self.lid.."_FlareTargets")
  local cameraset = self:_GetTargetSet(client,true) -- Core.Set#SET_UNIT
  local visualset = self:_GetTargetSet(client,false) -- Core.Set#SET_UNIT
  cameraset:AddSet(visualset)
  if cameraset:CountAlive() > 0 then
    self:__TargetsFlared(-1,client,playername,cameraset)
  end
  local highsmoke = self.FlareColor.highflare
  local medsmoke = self.FlareColor.medflare
  local lowsmoke = self.FlareColor.lowflare
  local lasersmoke = self.FlareColor.laserflare
  local laser = self.LaserSpots[playername] -- Core.Spot#SPOT
  -- laser targer gets extra smoke
  if laser and laser.Target and laser.Target:IsAlive() then
    laser.Target:GetCoordinate():Flare(lasersmoke)
    if cameraset:IsInSet(laser.Target) then
      cameraset:Remove(laser.Target:GetName(),true)
    end
  end
  -- smoke everything else
  for _,_unit in pairs(cameraset.Set) do
    local unit = _unit --Wrapper.Unit#UNIT
    if unit and unit:IsAlive() then
      local coord = unit:GetCoordinate()
      local threat = unit:GetThreatLevel()
      if coord then
        local color = lowsmoke
        if threat > 7 then
          color = highsmoke
        elseif threat > 2 then
          color = medsmoke
        end
        coord:Flare(color)
      end
    end
  end
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_IlluTargets(client,group,playername)
  self:T(self.lid.."_IlluTargets")
  local totalset, count = self:_GetKnownTargets(client) -- Core.Set#SET_UNIT
  if count > 0 then
    local coord = totalset:GetCoordinate() -- Core.Point#COORDINATE
    coord.y = coord.y + 200
    coord:IlluminationBomb(nil,1)
    self:__Illumination(1,client,playername,totalset)
  end
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_UploadTargets(client,group,playername)
  self:T(self.lid.."_UploadTargets")
  --local targetset, number = self:_GetTargetSet(client,true)
  --local vtargetset, vnumber = self:_GetTargetSet(client,false)
  local totalset, count = self:_GetKnownTargets(client)
  --local totalset = SET_UNIT:New()
 -- totalset:AddSet(targetset)
  --totalset:AddSet(vtargetset)
  if count > 0 then
    self.Controller:AddTarget(totalset)
    self:__TargetReportSent(1,client,playername,totalset)
  end
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_ReportLaserTargets(client,group,playername)
self:T(self.lid.."_ReportLaserTargets")
  local targetset, number = self:_GetTargetSet(client,true,true)
  if number > 0 and self.AutoLase[playername] then
    local Settings = ( client and _DATABASE:GetPlayerSettings( playername  ) ) or _SETTINGS
    local target = self:_GetHVTTarget(targetset) -- the one we're lasing
    local ThreatLevel = target:GetThreatLevel() or 1
    local ThreatLevelText = "high"
    if ThreatLevel > 3 and ThreatLevel < 8 then
     ThreatLevelText = "medium"
    elseif  ThreatLevel <= 3 then
     ThreatLevelText = "low"
    end
    local ThreatGraph = "[" .. string.rep(  "■", ThreatLevel ) .. string.rep(  "□", 10 - ThreatLevel ) .. "]: "..ThreatLevel
    local report = REPORT:New("Lasing Report")
    report:Add(string.rep("-",15))
    report:Add("Target type: "..target:GetTypeName() or "unknown")
    report:Add("Threat Level: "..ThreatGraph.." ("..ThreatLevelText..")")
    if not self.ReferencePoint then
      report:Add("Location: "..client:GetCoordinate():ToStringBULLS(self.Coalition,Settings))
      if self.reporttostringbullsonly ~= true then
        report:Add("Location: "..client:GetCoordinate():ToStringA2G(nil,Settings))
      end
    else
      report:Add("Location: "..client:GetCoordinate():ToStringFromRPShort(self.ReferencePoint,self.RPName,client,Settings))
    end
    report:Add("Laser Code: "..self.UnitLaserCodes[playername] or 1688)
    report:Add(string.rep("-",15))
    local text = report:Text()
    self:__TargetReport(1,client,targetset,target,text)
  else
    local report = REPORT:New("Lasing Report")
    report:Add(string.rep("-",15))
    report:Add("N O  T A R G E T S")
    report:Add(string.rep("-",15))
    local text = report:Text()
    self:__TargetReport(1,client,nil,nil,text)
  end
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_ReportVisualTargets(client,group,playername)
  self:T(self.lid.."_ReportVisualTargets")
  local targetset, number = self:_GetKnownTargets(client)
    if number > 0 then
    local Settings = ( client and _DATABASE:GetPlayerSettings( playername ) ) or _SETTINGS
    local ThreatLevel = targetset:CalculateThreatLevelA2G()
    local ThreatLevelText = "high"
    if ThreatLevel > 3 and ThreatLevel < 8 then
     ThreatLevelText = "medium"
    elseif  ThreatLevel <= 3 then
     ThreatLevelText = "low"
    end
    local ThreatGraph = "[" .. string.rep(  "■", ThreatLevel ) .. string.rep(  "□", 10 - ThreatLevel ) .. "]: "..ThreatLevel
    local report = REPORT:New("Target Report")
    report:Add(string.rep("-",15))
    report:Add("Target count: "..number)
    report:Add("Threat Level: "..ThreatGraph.." ("..ThreatLevelText..")")
    if not self.ReferencePoint then
      report:Add("Location: "..client:GetCoordinate():ToStringBULLS(self.Coalition,Settings))
      if self.reporttostringbullsonly ~= true then
        report:Add("Location: "..client:GetCoordinate():ToStringA2G(nil,Settings))
      end
    else
      report:Add("Location: "..client:GetCoordinate():ToStringFromRPShort(self.ReferencePoint,self.RPName,client,Settings))
      if self.reporttostringbullsonly ~= true then
        report:Add("Location: "..client:GetCoordinate():ToStringA2G(nil,Settings))
      end
    end
    report:Add(string.rep("-",15))
    local text = report:Text()
    self:__TargetReport(1,client,targetset,nil,text)
  else
    local report = REPORT:New("Target Report")
    report:Add(string.rep("-",15))
    report:Add("N O  T A R G E T S")
    report:Add(string.rep("-",15))
    local text = report:Text()
    self:__TargetReport(1,client,nil,nil,text)
  end
  return self
end

--- [Internal] Build Menus
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT Client (optional) Client object
-- @return #PLAYERRECCE self
function PLAYERRECCE:_BuildMenus(Client)
  self:T(self.lid.."_BuildMenus")
  local clients = self.PlayerSet -- Core.Set#SET_CLIENT
  local clientset = clients:GetSetObjects()
  if Client then clientset = {Client} end
  for _,_client in pairs(clientset) do
    local client = _client -- Wrapper.Client#CLIENT
    if client and client:IsAlive() then
      local playername = client:GetPlayerName()
      self:T("Menu for "..playername)
      if not self.UnitLaserCodes[playername] then
        self:_SetClientLaserCode(nil,nil,playername,1688)
      end
      if self.SmokeOwn[playername] == nil then
        self.SmokeOwn[playername] = self.smokeownposition
      end
      local group = client:GetGroup()
      if not self.ClientMenus[playername] then
        self:T("Start Menubuild for "..playername)
        local canlase = self.CanLase[client:GetTypeName()]
        self.ClientMenus[playername] = MENU_GROUP:New(group,self.MenuName or self.Name or "RECCE")
        local txtonstation = self.OnStation[playername] and "ON" or "OFF"
        local text = string.format("Switch On-Station (%s)",txtonstation)
        local onstationmenu = MENU_GROUP_COMMAND:New(group,text,self.ClientMenus[playername],self._SwitchOnStation,self,client,group,playername)
        if self.OnStation[playername] then
          local smoketopmenu = MENU_GROUP:New(group,"Visual Markers",self.ClientMenus[playername])
          local smokemenu = MENU_GROUP_COMMAND:New(group,"Smoke Targets",smoketopmenu,self._SmokeTargets,self,client,group,playername)
          local flaremenu = MENU_GROUP_COMMAND:New(group,"Flare Targets",smoketopmenu,self._FlareTargets,self,client,group,playername)
          local illumenu = MENU_GROUP_COMMAND:New(group,"Illuminate Area",smoketopmenu,self._IlluTargets,self,client,group,playername)
          local ownsm = self.SmokeOwn[playername] and "ON" or "OFF"
          local owntxt = string.format("Switch smoke self (%s)",ownsm)
          local ownsmoke = MENU_GROUP_COMMAND:New(group,owntxt,smoketopmenu,self._SwitchSmoke,self,client,group,playername)
          if canlase then
            local txtonstation = self.AutoLase[playername] and "ON" or "OFF"
            local text = string.format("Switch Lasing (%s)",txtonstation)
            local lasemenu = MENU_GROUP_COMMAND:New(group,text,self.ClientMenus[playername],self._SwitchLasing,self,client,group,playername)
            local lasedist = MENU_GROUP:New(group,"Set Laser Distance",self.ClientMenus[playername])
            local mindist = 100
            local maxdist = 2000
            if self.LaserFOV[playername] and self.LaserFOV[playername].max then
              maxdist = self.LaserFOV[playername].max
            end
            local laselist={}
            for i=2,8 do
             local dist1 = (i*1000)-1000
             local dist2 = i*1000
             dist1 = dist1 == 1000 and 100 or dist1
             local text = string.format("%d-%dm",dist1,dist2)
             if dist2 == maxdist then
              text = text .. " (*)"
             end
             laselist[i] = MENU_GROUP_COMMAND:New(group,text,lasedist,self._SwitchLasingDist,self,client,group,playername,dist1,dist2)
            end
          end
          local targetmenu = MENU_GROUP:New(group,"Target Report",self.ClientMenus[playername])
          if canlase then
            local reportL = MENU_GROUP_COMMAND:New(group,"Laser Target",targetmenu,self._ReportLaserTargets,self,client,group,playername)
          end
          local reportV = MENU_GROUP_COMMAND:New(group,"Visual Targets",targetmenu,self._ReportVisualTargets,self,client,group,playername)
          if self.UseController then
            local text = string.format("Target Upload to %s",self.Controller.MenuName or self.Controller.Name)
            local upload = MENU_GROUP_COMMAND:New(group,text,targetmenu,self._UploadTargets,self,client,group,playername)
          end
          if canlase then
            local lasecodemenu = MENU_GROUP:New(group,"Set Laser Code",self.ClientMenus[playername])
            local codemenu = {}
            for _,_code in pairs(self.LaserCodes) do
              --self._SetClientLaserCode,self,client,group,playername)
              if _code == self.UnitLaserCodes[playername] then
                _code = tostring(_code).."(*)"
              end
              codemenu[playername.._code] = MENU_GROUP_COMMAND:New(group,tostring(_code),lasecodemenu,self._SetClientLaserCode,self,client,group,playername,_code)
            end 
          end   
        end
      end
    end
  end
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Core.Set#SET_UNIT targetset
-- @param Wrapper.Client#CLIENT client
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_CheckNewTargets(targetset,client,playername)
  self:T(self.lid.."_CheckNewTargets")
  local tempset = SET_UNIT:New()
  targetset:ForEach(
    function(unit)
      if unit and unit:IsAlive() then
        self:T("Report unit: "..unit:GetName())
        if not unit.PlayerRecceDetected then
          self:T("New unit: "..unit:GetName())
          unit.PlayerRecceDetected = {
            detected = true,
            recce = client,
            playername = playername,
            timestamp = timer.getTime()
          }
          --self:TargetDetected(unit,client,playername)
          tempset:Add(unit:GetName(),unit)
          if not self.TargetCache:HasUniqueID(unit:GetName()) then
            self.TargetCache:Push(unit,unit:GetName())
          end
        end
        if unit.PlayerRecceDetected and unit.PlayerRecceDetected.timestamp then
          local TNow = timer.getTime()
          if TNow-unit.PlayerRecceDetected.timestamp > self.TForget then
           unit.PlayerRecceDetected = {
              detected = true,
              recce = client,
              playername = playername,
              timestamp = timer.getTime()
              }
           if not self.TargetCache:HasUniqueID(unit:GetName()) then
            self.TargetCache:Push(unit,unit:GetName())
           end
           tempset:Add(unit:GetName(),unit)  
          end
        end
      end
    end
  )
  local targetsbyclock = {}
  for i=1,12 do
    targetsbyclock[i] = {}
  end
  tempset:ForEach(
    function (object)
      local obj=object -- Wrapper.Unit#UNIT
      local clock = self:_GetClockDirection(client,obj)
      table.insert(targetsbyclock[clock],obj)
    end
  )
  self:T("Known target Count: "..self.TargetCache:Count())
  if tempset:CountAlive() > 0 then
    self:TargetDetected(targetsbyclock,client,playername)
  end
  return self
end

--- [User] Set SRS TTS details - see @{Sound.SRS} for details
-- @param #PLAYERRECCE self
-- @param #number Frequency Frequency to be used. Can also be given as a table of multiple frequencies, e.g. 271 or {127,251}. There needs to be exactly the same number of modulations!
-- @param #number Modulation Modulation to be used. Can also be given as a table of multiple modulations, e.g. radio.modulation.AM or {radio.modulation.FM,radio.modulation.AM}. There needs to be exactly the same number of frequencies!
-- @param #string PathToSRS Defaults to "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio"
-- @param #string Gender (Optional) Defaults to "male"
-- @param #string Culture (Optional) Defaults to "en-US"
-- @param #number Port (Optional) Defaults to 5002
-- @param #string Voice (Optional) Use a specifc voice with the @{Sound.SRS#SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system. Can also be Google voice types, if you are using Google TTS.
-- @param #number Volume (Optional) Volume - between 0.0 (silent) and 1.0 (loudest)
-- @param #string PathToGoogleKey (Optional) Path to your google key if you want to use google TTS
-- @param #string Backend (optional) Backend to be used, can be MSRS.Backend.SRSEXE or MSRS.Backend.GRPC
-- @return #PLAYERRECCE self
function PLAYERRECCE:SetSRS(Frequency,Modulation,PathToSRS,Gender,Culture,Port,Voice,Volume,PathToGoogleKey,Backend)
  self:T(self.lid.."SetSRS")
  self.PathToSRS = PathToSRS or MSRS.path or "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio" --
  self.Gender = Gender or MSRS.gender or "male" --
  self.Culture = Culture or MSRS.culture or "en-US" --
  self.Port = Port or MSRS.port or 5002 --
  self.Voice = Voice or MSRS.voice --
  self.PathToGoogleKey = PathToGoogleKey --
  self.Volume = Volume or 1.0 -- 
  self.UseSRS = true
  self.Frequency = Frequency or {127,251} --
  self.BCFrequency = self.Frequency
  self.Modulation = Modulation or {radio.modulation.FM,radio.modulation.AM} --
  self.BCModulation = self.Modulation
  -- set up SRS 
  self.SRS=MSRS:New(self.PathToSRS,self.Frequency,self.Modulation)
  self.SRS:SetCoalition(self.Coalition)
  self.SRS:SetLabel(self.MenuName or self.Name)
  self.SRS:SetGender(self.Gender)
  self.SRS:SetCulture(self.Culture)
  self.SRS:SetPort(self.Port)
  self.SRS:SetVolume(self.Volume)
  if Backend then
    self.SRS:SetBackend(Backend)
  end
  if self.PathToGoogleKey then
    self.SRS:SetProviderOptionsGoogle(self.PathToGoogleKey,self.PathToGoogleKey)
    self.SRS:SetProvider(MSRS.Provider.GOOGLE)
  end
     -- Pre-configured Google?
  if (not PathToGoogleKey) and self.SRS:GetProvider() == MSRS.Provider.GOOGLE then
    self.PathToGoogleKey = MSRS.poptions.gcloud.credentials
    self.Voice = Voice or MSRS.poptions.gcloud.voice
  end
  self.SRS:SetVoice(self.Voice)
  self.SRSQueue = MSRSQUEUE:New(self.MenuName or self.Name)
  self.SRSQueue:SetTransmitOnlyWithPlayers(self.TransmitOnlyWithPlayers)
  return self
end

--- [User] For SRS - Switch to only transmit if there are players on the server.
-- @param #PLAYERRECCE self
-- @param #boolean Switch If true, only send SRS if there are alive Players.
-- @return #PLAYERRECCE self
function PLAYERRECCE:SetTransmitOnlyWithPlayers(Switch)
  self.TransmitOnlyWithPlayers = Switch
  if self.SRSQueue then
    self.SRSQueue:SetTransmitOnlyWithPlayers(Switch)
  end
  return self
end

--- [User] Set the top menu name to a custom string.
-- @param #PLAYERRECCE self
-- @param #string Name The name to use as the top menu designation.
-- @return #PLAYERRECCE self
function PLAYERRECCE:SetMenuName(Name)
 self:T(self.lid.."SetMenuName: "..Name)
 self.MenuName = Name
 return self
end

--- [User] Set reporting to be BULLS only or BULLS plus playersettings based coordinate.
-- @param #PLAYERRECCE self
-- @param #boolean OnOff
-- @return #PLAYERRECCE self
function PLAYERRECCE:SetReportBullsOnly(OnOff)
 self:T(self.lid.."SetReportBullsOnly: "..tostring(OnOff))
 self.reporttostringbullsonly = OnOff
 return self
end

--- [User] Enable smoking of own position
-- @param #PLAYERRECCE self
-- @return #PLAYERRECCE self
function PLAYERRECCE:EnableSmokeOwnPosition()
  self:T(self.lid.."EnableSmokeOwnPosition")
  self.smokeownposition = true
  return self
end

--- [User] Enable auto lasing for the Kiowa OH-58D.
-- @param #PLAYERRECCE self
-- @return #PLAYERRECCE self
function PLAYERRECCE:EnableKiowaAutolase()
  self:T(self.lid.."EnableKiowaAutolase")
  self.CanLase.OH58D = true
  return self
end

--- [User] Disable smoking of own position
-- @param #PLAYERRECCE self
-- @return #PLAYERRECCE 
function PLAYERRECCE:DisableSmokeOwnPosition()
  self:T(self.lid.."DisableSmokeOwnPosition")
  self.smokeownposition = false
  return self
end

--- [User] Enable smoking of average target positions, instead of all targets visible. Loses smoke per threatlevel -- each is med threat. Default is - smoke all positions.
-- @param #PLAYERRECCE self
-- @return #PLAYERRECCE self
function PLAYERRECCE:EnableSmokeAverageTargetPosition()
  self:T(self.lid.."ENableSmokeOwnPosition")
  self.smokeaveragetargetpos = true
  return self
end

--- [User] Disable smoking of average target positions, instead of all targets visible. Default is - smoke all positions.
-- @param #PLAYERRECCE self
-- @return #PLAYERRECCE 
function PLAYERRECCE:DisableSmokeAverageTargetPosition()
  self:T(self.lid.."DisableSmokeAverageTargetPosition")
  self.smokeaveragetargetpos = false
  return self
end

--- [Internal] Get text for text-to-speech.
-- Numbers are spaced out, e.g. "Heading 180" becomes "Heading 1 8 0 ".
-- @param #PLAYERRECCE self
-- @param #string text Original text.
-- @return #string Spoken text.
function PLAYERRECCE:_GetTextForSpeech(text)
  
  -- Space out numbers.
  text=string.gsub(text,"%d","%1 ")
  -- get rid of leading or trailing spaces
  text=string.gsub(text,"^%s*","")
  text=string.gsub(text,"%s*$","")
  text=string.gsub(text,"0","zero")
  text=string.gsub(text,"9","niner")
  text=string.gsub(text,"  "," ")
  
  return text
end

------------------------------------------------------------------------------------------
-- TODO: FSM Functions
------------------------------------------------------------------------------------------

--- [Internal] Status Loop
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterStatus(From, Event, To)
  self:T({From, Event, To})
  
  if not self.timestamp then
    self.timestamp = timer.getTime()
  else
    local tNow = timer.getTime()
    if tNow - self.timestamp >= 60 then
      self:_CleanupTargetCache()
      self.timestamp = timer.getTime()
    end
  end
  
  self:_BuildMenus()
  
  self.PlayerSet:ForEachClient(
    function(Client)
        local client = Client -- Wrapper.Client#CLIENT
        local playername = client:GetPlayerName()
        local cameraison = self:_CameraOn(client,playername)
        if client and client:IsAlive() and self.OnStation[playername] then
          ---
         local targetset, targetcount, tzone = nil,0,nil
         local laserset, lzone = nil,nil
         local vistargetset, vistargetcount, viszone = nil,0,nil
          -- targets on camera
          if cameraison then
            targetset, targetcount, tzone = self:_GetTargetSet(client,true)
            if targetset then
              if self.ViewZone[playername] then
                self.ViewZone[playername]:UndrawZone()
              end
              if self.debug and tzone then
                self.ViewZone[playername]=tzone:DrawZone(self.Coalition,{0,0,1},nil,nil,nil,1)
              end
            end
            self:T({targetcount=targetcount})
          end
          -- lase targets on camera
          if self.AutoLase[playername] and cameraison then
            laserset, targetcount, lzone = self:_GetTargetSet(client,true,true)
            if targetcount > 0 or self.LaserTarget[playername] then
              if self.CanLase[client:GetTypeName()] then
                -- DONE move to lase at will
                self:_LaseTarget(client,laserset)
              end
            end
            if lzone then
              if self.ViewZoneLaser[playername] then
                self.ViewZoneLaser[playername]:UndrawZone()
              end
              if self.debug and tzone then
                self.ViewZoneLaser[playername]=lzone:DrawZone(self.Coalition,{0,1,0},nil,nil,nil,1)
              end
            end
            self:T({lasercount=targetcount})
          end
          -- visual targets
          vistargetset, vistargetcount, viszone = self:_GetTargetSet(client,false)
          if vistargetset then
            if self.ViewZoneVisual[playername] then
              self.ViewZoneVisual[playername]:UndrawZone()
            end
            if self.debug and viszone then
              self.ViewZoneVisual[playername]=viszone:DrawZone(self.Coalition,{1,0,0},nil,nil,nil,3)
            end
          end
          self:T({visualtargetcount=vistargetcount})
          if targetset then
            vistargetset:AddSet(targetset)
          end
          if laserset then
            vistargetset:AddSet(laserset)
          end
          if not cameraison and self.debug then
            if self.ViewZoneLaser[playername] then
                self.ViewZoneLaser[playername]:UndrawZone()
              end
            if self.ViewZone[playername] then
              self.ViewZone[playername]:UndrawZone()
            end
          end
          self:_CheckNewTargets(vistargetset,client,playername)
        end
    end
  )
   
  self:__Status(-10)
  return self
end

--- [Internal] Recce on station
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterRecceOnStation(From, Event, To, Client, Playername)
  self:T({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition)
  if self.ReferencePoint then
    local Settings = Client and _DATABASE:GetPlayerSettings(Playername) or _SETTINGS -- Core.Settings#SETTINGS
    coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,Client,Settings)
  end
  local text1 = "Party time!"
  local text2 = string.format("All stations, FACA %s on station\nat %s!",callsign, coordtext)
  local text2tts = string.format(" All stations, FACA %s on station at %s!",callsign, coordtext)
  text2tts = self:_GetTextForSpeech(text2tts)
  if self.debug then
  self:T(text2.."\n"..text2tts)
  end
  if self.UseSRS then
    local grp = Client:GetGroup()
    local coord = grp:GetCoordinate()
    if coord then
      self.SRS:SetCoordinate(coord)
    end
    self.SRSQueue:NewTransmission(text1,nil,self.SRS,nil,2)
    self.SRSQueue:NewTransmission(text2tts,nil,self.SRS,nil,3)
    MESSAGE:New(text2,10,self.Name or "FACA"):ToCoalition(self.Coalition)
  else
    MESSAGE:New(text1,10,self.Name or "FACA"):ToClient(Client)
    MESSAGE:New(text2,10,self.Name or "FACA"):ToCoalition(self.Coalition)
  end
  return self
end

--- [Internal] Recce off station
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterRecceOffStation(From, Event, To, Client, Playername)
  self:T({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition)
  if self.ReferencePoint then
    local Settings = Client and _DATABASE:GetPlayerSettings(Playername) or _SETTINGS -- Core.Settings#SETTINGS
    coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,Client,Settings)
  end
  local text = string.format("All stations, FACA %s leaving station\nat %s, good bye!",callsign, coordtext)
  local texttts = string.format("All stations, FACA %s leaving station at %s, good bye!",callsign, coordtext)
  texttts = self:_GetTextForSpeech(texttts)
  if self.debug then
    self:T(text.."\n"..texttts)
  end
  local text1 = "Going home!"
  if self.UseSRS then
    local grp = Client:GetGroup()
    local coord = grp:GetCoordinate()
    if coord then
      self.SRS:SetCoordinate(coord)
    end
    self.SRSQueue:NewTransmission(text1,nil,self.SRS,nil,2)
    self.SRSQueue:NewTransmission(texttts,nil,self.SRS,nil,3)
    MESSAGE:New(text,10,self.Name or "FACA"):ToCoalition(self.Coalition)
  else
    MESSAGE:New(text,10,self.Name or "FACA"):ToCoalition(self.Coalition)
  end
  return self
end

--- [Internal] Target Detected
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #table Targetsbyclock. #table with index 1..12 containing a #table of Wrapper.Unit#UNIT objects each.
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetDetected(From, Event, To, Targetsbyclock, Client, Playername)
  self:T({From, Event, To})

  local dunits = "meters"
  local Settings = Client and _DATABASE:GetPlayerSettings(Playername) or _SETTINGS -- Core.Settings#SETTINGS
  local clientcoord = Client:GetCoordinate()
 
  for i=1,12 do
    local targets = Targetsbyclock[i] --#table
    local targetno = #targets
    if targetno == 1 then
      -- only one
      local targetdistance = clientcoord:Get2DDistance(targets[1]:GetCoordinate()) or 100
      local Threatlvl = targets[1]:GetThreatLevel()
      local ThreatTxt = "Low"
      if Threatlvl >=7  then
        ThreatTxt = "Medium"
      elseif Threatlvl >=3  then
        ThreatTxt = "High"
      end
      if Settings:IsMetric() then
       targetdistance = UTILS.Round(targetdistance,-2)
       if targetdistance >= 1000 then
        targetdistance = UTILS.Round(targetdistance/1000,0)
        dunits = "kilometer"
       end
      else
       if UTILS.MetersToNM(targetdistance) >=1 then
        targetdistance = UTILS.Round(UTILS.MetersToNM(targetdistance),0)
        dunits = "miles"
       else
         targetdistance = UTILS.Round(UTILS.MetersToFeet(targetdistance),-2)
         dunits = "feet"
       end
      end
      local text = string.format("Target! %s! %s o\'clock, %d %s!", ThreatTxt,i, targetdistance, dunits)
      local ttstext = string.format("Target! %s! %s oh clock, %d %s!", ThreatTxt, i, targetdistance, dunits)
      if self.UseSRS then
        local grp = Client:GetGroup()
        if clientcoord then
          self.SRS:SetCoordinate(clientcoord)
        end
        self.SRSQueue:NewTransmission(ttstext,nil,self.SRS,nil,1,{grp},text,10)
      else
        MESSAGE:New(text,10,self.Name or "FACA"):ToClient(Client)
      end
    elseif targetno > 1 then
      -- multiple
      local function GetNearest(TTable)
        local distance = 10000000
        for _,_unit in pairs(TTable) do
          local dist = clientcoord:Get2DDistance(_unit:GetCoordinate()) or 100
          if dist < distance then
            distance = dist
          end
        end
        return distance
      end
      local targetdistance = GetNearest(targets)
      if Settings:IsMetric() then
       targetdistance = UTILS.Round(targetdistance,-2)
        if targetdistance >= 1000 then
        targetdistance = UTILS.Round(targetdistance/1000,0)
        dunits = "kilometer"
       end
      else
       if UTILS.MetersToNM(targetdistance) >=1 then
        targetdistance = UTILS.Round(UTILS.MetersToNM(targetdistance),0)
        dunits = "miles"
       else
         targetdistance = UTILS.Round(UTILS.MetersToFeet(targetdistance),-2)
         dunits = "feet"
       end
      end
      local text = string.format(" %d targets! %s o\'clock, %d %s!", targetno, i, targetdistance, dunits)
      local ttstext = string.format("%d targets! %s oh clock, %d %s!", targetno, i, targetdistance, dunits)
      if self.UseSRS then
        local grp = Client:GetGroup()
        local coord = grp:GetCoordinate()
        if coord then
          self.SRS:SetCoordinate(coord)
        end
        self.SRSQueue:NewTransmission(ttstext,nil,self.SRS,nil,1,{grp},text,10)
      else
        MESSAGE:New(text,10,self.Name or "FACA"):ToClient(Client)
      end
    end
  end
  return self
end

--- [Internal] Targets Illuminated
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @param Core.Set#SET_UNIT TargetSet
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterIllumination(From, Event, To, Client, Playername, TargetSet)
  self:T({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition)
  if self.AttackSet then
    for _,_client in pairs(self.AttackSet.Set) do
      local client = _client --Wrapper.Client#CLIENT
      if client and client:IsAlive() then
        local Settings = client and _DATABASE:GetPlayerSettings(client:GetPlayerName())  or _SETTINGS
        local coordtext = coord:ToStringA2G(client,Settings)
        if self.ReferencePoint then
          coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,client,Settings)
        end
        local text = string.format("All stations, %s fired illumination\nat %s!",callsign, coordtext)
        MESSAGE:New(text,15,self.Name or "FACA"):ToClient(client)
      end
    end
  end
  local text = "Sunshine!"
  local ttstext = "Sunshine!"
  if self.UseSRS then
    local grp = Client:GetGroup()
    local coord = grp:GetCoordinate()
    if coord then
      self.SRS:SetCoordinate(coord)
    end
    self.SRSQueue:NewTransmission(ttstext,nil,self.SRS,nil,1,{grp},text,10)
  else
    MESSAGE:New(text,10,self.Name or "FACA"):ToClient(Client)
  end
  return self
end

--- [Internal] Targets Smoked
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @param Core.Set#SET_UNIT TargetSet
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetsSmoked(From, Event, To, Client, Playername, TargetSet)
  self:T({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition)
  if self.AttackSet then
    for _,_client in pairs(self.AttackSet.Set) do
      local client = _client --Wrapper.Client#CLIENT
      if client and client:IsAlive() then
        local Settings = client and _DATABASE:GetPlayerSettings(client:GetPlayerName())  or _SETTINGS
        local coordtext = coord:ToStringA2G(client,Settings)
        if self.ReferencePoint then
          coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,client,Settings)
        end
        local text = string.format("All stations, %s smoked targets\nat %s!",callsign, coordtext)
        MESSAGE:New(text,15,self.Name or "FACA"):ToClient(client)
      end
    end
  end
  local text = "Smoke on!"
  local ttstext = "Smoke and Mirrors!"
  if self.UseSRS then
    local grp = Client:GetGroup()
    local coord = grp:GetCoordinate()
    if coord then
      self.SRS:SetCoordinate(coord)
    end
    self.SRSQueue:NewTransmission(ttstext,nil,self.SRS,nil,1,{grp},text,10)
  else
    MESSAGE:New(text,10,self.Name or "FACA"):ToClient(Client)
  end
  return self
end

--- [Internal] Targets Flared
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @param Core.Set#SET_UNIT TargetSet
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetsFlared(From, Event, To, Client, Playername, TargetSet)
  self:T({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition)
  if self.AttackSet then
    for _,_client in pairs(self.AttackSet.Set) do
      local client = _client --Wrapper.Client#CLIENT
      if client and client:IsAlive() then
        local Settings = client and _DATABASE:GetPlayerSettings(client:GetPlayerName())  or _SETTINGS
        if self.ReferencePoint then
          coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,client,Settings)
        end
        local coordtext = coord:ToStringA2G(client,Settings)
        local text = string.format("All stations, %s flared targets\nat %s!",callsign, coordtext)
        MESSAGE:New(text,15,self.Name or "FACA"):ToClient(client)
      end
    end
  end
  local text = "Fireworks!"
  local ttstext = "Fire works!"
  if self.UseSRS then
    local grp = Client:GetGroup()
    local coord = grp:GetCoordinate()
    if coord then
      self.SRS:SetCoordinate(coord)
    end
    self.SRSQueue:NewTransmission(ttstext,nil,self.SRS,nil,1,{grp},text,10)
  else
    MESSAGE:New(text,10,self.Name or "FACA"):ToClient(Client)
  end
  return self
end
 
--- [Internal] Target lasing
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param Wrapper.Unit#UNIT Target
-- @param #number Lasercode
-- @param #number Lasingtime
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetLasing(From, Event, To, Client, Target, Lasercode, Lasingtime)
  self:T({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
  local Settings = ( Client and _DATABASE:GetPlayerSettings( Client:GetPlayerName() ) ) or _SETTINGS
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition,Settings)
  if self.ReferencePoint then
    coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,Client,Settings)
  end
  local targettype = Target:GetTypeName()
  if self.AttackSet then
    for _,_client in pairs(self.AttackSet.Set) do
      local client = _client --Wrapper.Client#CLIENT
      if client and client:IsAlive() then
        local Settings = client and _DATABASE:GetPlayerSettings(client:GetPlayerName())  or _SETTINGS
        if self.ReferencePoint then
          coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,client,Settings)
        end
        local coordtext = coord:ToStringA2G(client,Settings)
        local text = string.format("All stations, %s lasing %s\nat %s!\nCode %d, Duration %d plus seconds!",callsign, targettype, coordtext, Lasercode, Lasingtime)
        MESSAGE:New(text,15,self.Name or "FACA"):ToClient(client)
      end
    end
  end
  local text = "Lasing!"
  local ttstext = "Laser on!"
  if self.UseSRS then
    local grp = Client:GetGroup()
    local coord = grp:GetCoordinate()
    if coord then
      self.SRS:SetCoordinate(coord)
    end
    self.SRSQueue:NewTransmission(ttstext,nil,self.SRS,nil,1,{grp},text,10)
  else
    MESSAGE:New(text,10,self.Name or "FACA"):ToClient(Client)
  end
  return self
end

--- [Internal] Lased target destroyed
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param Wrapper.Unit#UNIT Target
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterShack(From, Event, To, Client, Target)
  self:T({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
  local Settings = ( Client and _DATABASE:GetPlayerSettings( Client:GetPlayerName() ) ) or _SETTINGS
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition,Settings)
  if self.ReferencePoint then
    coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,Client,Settings)
  end
  local targettype = "target"
  if self.AttackSet then
    for _,_client in pairs(self.AttackSet.Set) do
      local client = _client --Wrapper.Client#CLIENT
      if client and client:IsAlive() then
        local Settings = client and _DATABASE:GetPlayerSettings(client:GetPlayerName())  or _SETTINGS
        if self.ReferencePoint then
          coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,client,Settings)
        end
        local coordtext = coord:ToStringA2G(client,Settings)
        local text = string.format("All stations, %s good hit on %s\nat %s!",callsign, targettype, coordtext)
        MESSAGE:New(text,15,self.Name or "FACA"):ToClient(client)
      end
    end
  end
  local text = "Shack!"
  local ttstext = "Shack!"
  if self.UseSRS then
    local grp = Client:GetGroup()
    local coord = grp:GetCoordinate()
    if coord then
      self.SRS:SetCoordinate(coord)
    end
    self.SRSQueue:NewTransmission(ttstext,nil,self.SRS,nil,1)
  else
    MESSAGE:New(text,10,self.Name or "FACA"):ToClient(Client)
  end
  return self
end

--- [Internal] Laser lost LOS
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param Wrapper.Unit#UNIT Target
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetLOSLost(From, Event, To, Client, Target)
  self:T({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
  local Settings = ( Client and _DATABASE:GetPlayerSettings( Client:GetPlayerName() ) ) or _SETTINGS
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition,Settings)
  if self.ReferencePoint then
    coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,Client,Settings)
  end
  local targettype = "target" --Target:GetTypeName()
  if self.AttackSet then
    for _,_client in pairs(self.AttackSet.Set) do
      local client = _client --Wrapper.Client#CLIENT
      if client and client:IsAlive() then
        local Settings = client and _DATABASE:GetPlayerSettings(client:GetPlayerName())  or _SETTINGS
        if self.ReferencePoint then
          coordtext = coord:ToStringFromRPShort(self.ReferencePoint,self.RPName,client,Settings)
        end
        local coordtext = coord:ToStringA2G(client,Settings)
        local text = string.format("All stations, %s lost sight of %s\nat %s!",callsign, targettype, coordtext)
        MESSAGE:New(text,15,self.Name or "FACA"):ToClient(client)
      end
    end
  end
  local text = "Lost LOS!"
  local ttstext = "Lost L O S!"
  if self.UseSRS then
    local grp = Client:GetGroup()
    local coord = grp:GetCoordinate()
    if coord then
      self.SRS:SetCoordinate(coord)
    end
    self.SRSQueue:NewTransmission(ttstext,nil,self.SRS,nil,1,{grp},text,10)
  else
    MESSAGE:New(text,10,self.Name or "FACA"):ToClient(Client)
  end
  return self
end

--- [Internal] Target report
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param Core.Set#SET_UNIT TargetSet
-- @param Wrapper.Unit#UNIT Target
-- @param #string Text
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetReport(From, Event, To, Client, TargetSet, Target, Text)
  self:T({From, Event, To})
  MESSAGE:New(Text,45,self.Name or "FACA"):ToClient(Client)
  if self.AttackSet then
    -- send message to AttackSet
    for _,_client in pairs(self.AttackSet.Set) do
      local client = _client -- Wrapper.Client#CLIENT
      if client and client:IsAlive() and client ~= Client then
        MESSAGE:New(Text,45,self.Name or "FACA"):ToClient(client)
      end
    end
  end
  return self
end

--- [Internal] Target data upload
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client Client sending the report
-- @param #string Playername Player name
-- @param Core.Set#SET_UNIT TargetSet Set of targets
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetReportSent(From, Event, To, Client, Playername, TargetSet)
  self:T({From, Event, To})
  local text = "Upload completed!"
  if self.UseSRS then
    local grp = Client:GetGroup()
    local coord = grp:GetCoordinate()
    if coord then
      self.SRS:SetCoordinate(coord)
    end
    self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,1,{grp},text,10)
  else
    MESSAGE:New(text,10,self.Name or "FACA"):ToClient(Client)
  end
  return self
end

--- [Internal] Stop
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterStop(From, Event, To)
  self:I({From, Event, To})
  -- Player Events
  self:UnHandleEvent(EVENTS.PlayerLeaveUnit)
  self:UnHandleEvent(EVENTS.Ejection)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.PilotDead)
  self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
  return self
end

------------------------------------------------------------------------------------------
-- TODO: END PLAYERRECCE
------------------------------------------------------------------------------------------
