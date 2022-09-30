--- **Ops** - Allow a player in the Gazelle to detect, smoke, flare, lase and report ground units to others.
--
-- ## Features:
--
--   * Allow a player in the Gazelle to detect, smoke, flare, lase and report ground units to others.
--   * Implements visual detection from the helo
--   * Implements optical detection via the Vivianne system and lasing
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
--   * Applevengelist (Design & Programming)
--   
-- ===
--
-- @module Ops.PlayerRecce
-- @image @image Detection.JPG

-------------------------------------------------------------------------------------------------------------------
-- PLAYERRECCE
-- TODO: PLAYERRECCE
-- TODO: A lot...
-------------------------------------------------------------------------------------------------------------------

--- PLAYERRECCE class.
-- @type PLAYERRECCE
-- @field #string ClassName Name of the class.
-- @field #boolean verbose Switch verbosity.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string version
-- @field #table ViewZone
-- @field #table ViewZoneVisual
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
-- @extends Core.Fsm#FSM

---
--
-- *It is our attitude at the beginning of a difficult task which, more than anything else, which will affect its successful outcome.* (William James)
--
-- ===
-- 
-- # PLAYERRECCE 
-- 
--   * Allow a player in the Gazelle to detect, smoke, flare, lase and report ground units to others.
--   * Implements visual detection from the helo
--   * Implements optical detection via the Vivianne system and lasing
--    
-- If you have questions or suggestions, please visit the [MOOSE Discord](https://discord.gg/AeYAkHP) channel.  
-- 
--                          
-- @field #PLAYERRECCE
PLAYERRECCE = {
  ClassName          =   "PLAYERRECCE",
  verbose            =   true,
  lid                =   nil,
  version            =   "0.0.1",
  ViewZone           =   {},
  ViewZoneVisual     =   {},
  PlayerSet          =   nil,
  debug              =   true,
  LaserSpots         =   {},
  UnitLaserCodes     =   {},
  LaserCodes         =   {},
  ClientMenus        =   {},
  OnStation          =   {},
  minthreatlevel     =   0,
  lasingtime         =   60,
  AutoLase           =   {},
  AttackSet          =   nil,
}

---
-- @type LaserRelativePos
-- @field #string typename Unit type name
PLAYERRECCE.LaserRelativePos = {
  ["SA342M"] = { x = 1.7, y = 1.2, z = 0 },
  ["SA342Mistral"] = { x = 1.7, y = 1.2, z = 0 },
  ["SA342Minigun"] = { x = 1.7, y = 1.2, z = 0 },
  ["SA342L"] = { x = 1.7, y = 1.2, z = 0 },
}

---
-- @type MaxViewDistance
-- @field #string typename Unit type name
PLAYERRECCE.MaxViewDistance = {
  ["SA342M"] = 5000,
  ["SA342Mistral"] = 5000,
  ["SA342Minigun"] = 5000,
  ["SA342L"] = 5000,
}

---
-- @type Cameraheight
-- @field #string typename Unit type name
PLAYERRECCE.Cameraheight = {
  ["SA342M"] = 2.85,
  ["SA342Mistral"] = 2.85,
  ["SA342Minigun"] = 2.85,
  ["SA342L"] = 2.85,
}

---
-- @type CanLase
-- @field #string typename Unit type name
PLAYERRECCE.CanLase = {
  ["SA342M"] = true,
  ["SA342Mistral"] = true,
  ["SA342Minigun"] = false,
  ["SA342L"] = true,
}

---
-- @param #PLAYERRECCE self
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
  
  -- FSM start state is STOPPED.
  self:SetStartState("Stopped")
  
  self:AddTransition("Stopped",      "Start",               "Running")
  self:AddTransition("*",            "Status",              "*")
  self:AddTransition("*",            "RecceOnStation",      "*")
  self:AddTransition("*",            "RecceOffStation",     "*")
  self:AddTransition("*",            "TargetDetected",      "*")
  self:AddTransition("*",            "TargetsSmoked",       "*")
  self:AddTransition("*",            "TargetsFlared",       "*")
  self:AddTransition("*",            "TargetLasing",        "*")
  self:AddTransition("*",            "TargetLOSLost",       "*")
  self:AddTransition("*",            "TargetReport",        "*")
  self:AddTransition("*",            "TargetReportSent",    "*")
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
  
  return self
end

--- [Internal] Event handling
-- @param #PLAYERRECCE self
-- @param Core.Event#EVENTDATA EventData
-- @return #PLAYERRECCE self
function PLAYERRECCE:_EventHandler(EventData)
  self:T(self.lid.."_EventHandler: "..EventData.id)
  if EventData.id == EVENTS.PlayerLeaveUnit or EventData.id == EVENTS.Ejection or EventData.id == EVENTS.Crash or EventData.id == EVENTS.PilotDead then
    if EventData.IniPlayerName then
      self:I(self.lid.."Event for player: "..EventData.IniPlayerName)
      if self.ClientMenus[EventData.IniPlayerName] then
        self.ClientMenus[EventData.IniPlayerName]:Remove()
      end  
      self.ClientMenus[EventData.IniPlayerName] = nil
      self.LaserSpots[EventData.IniPlayerName] = nil
      self.OnStation[EventData.IniPlayerName] = false
    end
  elseif EventData.id == EVENTS.PlayerEnterAircraft and EventData.IniCoalition == self.Coalition then
    if EventData.IniPlayerName and EventData.IniGroup and self.UseSRS then
      self:I(self.lid.."Event for player: "..EventData.IniPlayerName)
      self.UnitLaserCodes[EventData.IniPlayerName] = 1688
      self.ClientMenus[EventData.IniPlayerName] = nil
      self.LaserSpots[EventData.IniPlayerName] = nil
      self.OnStation[EventData.IniPlayerName] = false
      self:_BuildMenus()
    end
  end
  return self
end

--- [User] Set a table of possible laser codes.
-- Each new RECCE can select a code from this table, default is 1688.
-- @param #PLAYERRECCE self
-- @param #list<#number> LaserCodes
-- @return #PLAYERRECCE
function PLAYERRECCE:SetLaserCodes( LaserCodes )
  self.LaserCodes = ( type( LaserCodes ) == "table" ) and LaserCodes or { LaserCodes }
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

--- [Internal] Get the view parameters from a Gazelle camera
-- @param #PLAYERRECCE self
-- @param Wrapper.Unit#UNIT Gazelle
-- @return #number cameraheading in degrees.
-- @return #number cameranodding in degrees.
-- @return #number maxview in meters.
-- @return #boolean cameraison If true, camera is on, else off.
function PLAYERRECCE:_GetGazelleVivianneSight(Gazelle)
  self:I(self.lid.."GetGazelleVivianneSight")
  local unit = Gazelle -- Wrapper.Unit#UNIT
  if unit and unit:IsAlive() then
    local dcsunit = Unit.getByName(Gazelle:GetName())
    local vivihorizontal = dcsunit:getDrawArgumentValue(215) or 0 -- (not in MiniGun) 1 to -1 -- zero is straight ahead, 1/-1 = 180 deg
    local vivivertical = dcsunit:getDrawArgumentValue(216) or 0 -- L/Mistral/Minigun model has no 216, ca 10deg up (=1) and down (=-1)
    local vivioff = false
    -- -1 = -180, 1 = 180
    -- Actual view -0,66 to 0,66
    -- Nick view -0,98 to 0,98 for +/- 30° 
    if vivihorizontal < -0.7 then 
      vivihorizontal = -0.7
      vivioff = true
      return 0,0,0,false 
    elseif vivihorizontal > 0.7 then 
      vivihorizontal = 0.7
      vivioff = true
      return 0,0,0,false
    end
    local horizontalview = vivihorizontal * -180 
    local verticalview = vivivertical * -30 -- ca +/- 30° 
    local heading = unit:GetHeading()
    local viviheading = (heading+horizontalview)%360
    local maxview = self:_GetActualMaxLOSight(unit,viviheading, verticalview,vivioff)
    return viviheading, verticalview, maxview, not vivioff
  end
  return 0,0,0,false
end

--- [Internal] Get the max line of sight based on unit head and camera nod via trigonometrie. Returns 0 if camera is off.
-- @param #PLAYERRECCE self
-- @param Wrapper.Unit#UNIT unit The unit which LOS we want
-- @param #number vheading Heading where the unit or camera is looking
-- @param #number vnod Nod down in degrees
-- @param #boolean vivoff Camera on or off
-- @return #number maxview Max view distance in meters
function PLAYERRECCE:_GetActualMaxLOSight(unit,vheading, vnod, vivoff)
  self:I(self.lid.."_GetActualMaxLOSight")
  if vivoff then return 0 end
  local maxview = 0
  if unit and unit:IsAlive() then
    local typename = unit:GetTypeName()
    maxview = self.MaxViewDistance[typename] or 5000
    local CamHeight = self.Cameraheight[typename] or 0
    if vnod > 0 then
        -- Looking down
        -- determine max distance we're looking at
        local beta = 90
        local gamma = math.floor(90-vnod)
        local alpha = math.floor(180-beta-gamma)
        local a = unit:GetHeight()-unit:GetCoordinate():GetLandHeight()+CamHeight
        local b = a / math.sin(math.rad(alpha))
        local c = b * math.sin(math.rad(gamma))
        maxview = c*1.2 -- +20%
    end
  end 
  return maxview 
end

--- [Internal] Build a ZONE_POLYGON from a given viewport of a unit
-- @param #PLAYERRECCE self
-- @param Wrapper.Unit#UNIT unit The unit which is looking
-- @param #number vheading Heading where the unit or camera is looking
-- @param #number vnod Nod down in degrees
-- @param #number maxview Max line of sight, depending on height
-- @param #number angle  Angle left/right to be added to heading to form a triangle
-- @param #boolean camon Camera is switched on
-- @param #boolean draw Draw the zone on the F10 map
-- @return Core.Zone#ZONE_POLYGON ViewZone or nil if camera is off
function PLAYERRECCE:_GetViewZone(unit, vheading, vnod, maxview, angle, camon, draw)
  self:I(self.lid.."_GetViewZone")
  local viewzone = nil
  if not camon then return nil end
  if unit and unit:IsAlive() then
    local unitname = unit:GetName()
    if self.ViewZone[unitname] then
      self.ViewZone[unitname]:UndrawZone()
    end
    --local vheading, vnod, maxview, vivon = self:GetGazelleVivianneSight(unit)
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
    if draw then
      viewzone:DrawZone(-1,{0,0,1},nil,nil,nil,1)
      self.ViewZone[unitname] = viewzone
    end  
  end
  return viewzone
end

--- [Internal] 
--@param #PLAYERRECCE self
--@param Wrapper.Unit#UNIT unit The FACA unit
--@param #boolean camera If true, use the unit's camera for targets in sight
--@return Core.Set#SET_UNIT Set of targets, can be empty!
--@return #number count Count of targets
function PLAYERRECCE:_GetTargetSet(unit,camera)
  self:I(self.lid.."_GetTargetSet")
  local finaltargets = SET_UNIT:New()
  local finalcount = 0
  local heading,nod,maxview,angle = 0,30,5000,10
  local camon = true
  local typename = unit:GetTypeName()
  local name = unit:GetName()
  if string.find(typename,"SA342") and camera then
    heading,nod,maxview,camon = self:_GetGazelleVivianneSight(unit)
    angle=10
  else
    -- visual
    heading = unit:GetHeading()
    nod,maxview,camon = 10,1000,true
    angle = 45
  end
  local zone = self:_GetViewZone(unit,heading,nod,maxview,angle,camon)
  if zone then
    local redcoalition = "red"
    if self.Coalition == coalition.side.RED then
      redcoalition = "blue"
    end
    -- determine what we can see
    local startpos = unit:GetCoordinate()
    local targetset = SET_UNIT:New():FilterCategories("ground"):FilterActive(true):FilterZones({zone}):FilterCoalitions(redcoalition):FilterOnce()
    self:I("Prefilter Target Count = "..targetset:CountAlive())
    -- TODO - Threat level filter?
    -- TODO - Min distance from unit?
    targetset:ForEach(
      function(_unit)
        local _unit = _unit -- Wrapper.Unit#UNIT
        local _unitpos = _unit:GetCoordinate()
        if startpos:IsLOS(_unitpos) then
            self:I("Adding to final targets: ".._unit:GetName())
          finaltargets:Add(_unit:GetName(),_unit)
        end
      end
      )
    finalcount = finaltargets:CountAlive()
    self:I(string.format("%s Unit: %s | Targets in view %s",self.lid,name,finalcount))
  end
  return finaltargets, finalcount, zone
end

---[Internal] 
--@param #PLAYERRECCE self
--@param Core.Set#SET_UNIT targetset Set of targets, can be empty!
--@return Wrapper.Unit#UNIT Target
function PLAYERRECCE:_GetHVTTarget(targetset)
   self:I(self.lid.."_GetHVTTarget")
   
   -- get one target
  -- local target = targetset:GetRandom() -- Wrapper.Unit#UNIT
   
   -- sort units
   local unitsbythreat = {}
   local minthreat = self.minthreatlevel or 0
   for _,_unit in pairs(targetset.Set) do
    local unit = _unit -- Wrapper.Unit#UNIT
    if unit and unit:IsAlive() then
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
   
 return unitsbythreat[1][1]
end

--- [Internal] 
--@param #PLAYERRECCE self
--@param Wrapper.Client#CLIENT client The FACA unit
--@param Core.Set#SET_UNIT targetset Set of targets, can be empty!
--@return #PLAYERRECCE self
function PLAYERRECCE:_LaseTarget(client,targetset)
  self:I(self.lid.."_LaseTarget")
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
    --function laser:OnAfterLaseOff(From,Event,To)
      --MESSAGE:New("Finished lasing",15,"Info"):ToClient(client)
    --end
    self.LaserSpots[playername] = laser
  else
    laser = self.LaserSpots[playername]
  end
  if not laser:IsLasing() and target then
    local relativecam = self.LaserRelativePos[client:GetTypeName()]
    laser:SetRelativeStartPosition(relativecam)
    local lasercode = self.UnitLaserCodes[playername] or laser.LaserCode or 1688
    local lasingtime = self.lasingtime or 60
    local targettype = target:GetTypeName()
    laser:LaseOn(target,lasercode,lasingtime)
    --MESSAGE:New(string.format("Lasing Target %s with Code %d",targettype,lasercode),15,"Info"):ToClient(client)
    self:__TargetLasing(-1,client,target,lasercode,lasingtime)
  else
    -- still looking at target?
    local oldtarget=laser.Target
    if targetset:IsNotInSet(oldtarget) then
        -- lost LOS
        local targettype = oldtarget:GetTypeName()
        laser:LaseOff()
        self:__TargetLOSLost(-1,client,oldtarget)
        --MESSAGE:New(string.format("Lost LOS on target %s!",targettype),15,"Info"):ToClient(client) 
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
function PLAYERRECCE:_SetClientLaserCode(client,group,playername,code)
  self:I(self.lid.."_SetClientLaserCode")
  self.UnitLaserCodes[playername] = code or 1688
  if self.ClientMenus[playername] then
    self.ClientMenus[playername]:Remove()
    self.ClientMenus[playername]=nil
  end
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_SwitchOnStation(client,group,playername)
  self:I(self.lid.."_SwitchOnStation")
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
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_SwitchLasing(client,group,playername)
  self:I(self.lid.."_SwitchLasing")
  if not self.AutoLase[playername] then
    self.AutoLase[playername] = true
    MESSAGE:New("Lasing is now ON",10,self.Name or "FACA"):ToClient(client)
  else
    self.AutoLase[playername] = false
    MESSAGE:New("Lasing is now OFF",10,self.Name or "FACA"):ToClient(client)
  end
  if self.ClientMenus[playername] then
    self.ClientMenus[playername]:Remove()
    self.ClientMenus[playername]=nil
  end
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_WIP(client,group,playername)
  self:I(self.lid.."_WIP")
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param Wrapper.Client#CLIENT client
-- @param Wrapper.Group#GROUP group
-- @param #string playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:_SmokeTargets(client,group,playername)
  self:I(self.lid.."_SmokeTargets")
  local cameraset = self:_GetTargetSet(client,true) -- Core.Set#SET_UNIT
  local visualset = self:_GetTargetSet(client,false) -- Core.Set#SET_UNIT
  cameraset:AddSet(visualset)
  self:__TargetsSmoked(-1,client,playername,cameraset)
  local highsmoke = SMOKECOLOR.Orange
  local medsmoke = SMOKECOLOR.White
  local lowsmoke = SMOKECOLOR.Green
  local lasersmoke = SMOKECOLOR.Red
  local laser = self.LaserSpots[playername] -- Core.Spot#SPOT
  -- laser targer gets extra smoke
  if laser and laser.Target and laser.Target:IsAlive() then
    laser.Target:GetCoordinate():Smoke(lasersmoke)
    if cameraset:IsInSet(laser.Target) then
      cameraset:Remove(laser.Target:GetName(),true)
    end
  end
  -- smoke everything else
  for _,_unit in pairs(cameraset.Set) do
    local unit = _unit --Wrapper.Unit#UNIT
    if unit then
      local coord = unit:GetCoordinate()
      local threat = unit:GetThreatLevel()
      if coord then
        local color = lowsmoke
        if threat > 7 then
          color = medsmoke
        elseif threat > 2 then
          color = lowsmoke
        end
        coord:Smoke(color)
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
function PLAYERRECCE:_FlareTargets(client,group,playername)
  self:I(self.lid.."_SmokeTargets")
  local cameraset = self:_GetTargetSet(client,true) -- Core.Set#SET_UNIT
  local visualset = self:_GetTargetSet(client,false) -- Core.Set#SET_UNIT
  cameraset:AddSet(visualset)
  self:__TargetsFlared(-1,client,playername,cameraset)
  local highsmoke = FLARECOLOR.Yellow
  local medsmoke = FLARECOLOR.White
  local lowsmoke = FLARECOLOR.Green
  local lasersmoke = FLARECOLOR.Red
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
    if unit then
      local coord = unit:GetCoordinate()
      local threat = unit:GetThreatLevel()
      if coord then
        local color = lowsmoke
        if threat > 7 then
          color = medsmoke
        elseif threat > 2 then
          color = lowsmoke
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
function PLAYERRECCE:_ReportLaserTargets(client,group,playername)
self:I(self.lid.."_ReportLaserTargets")
  local targetset, number = self:_GetTargetSet(client,true)
  if number > 0 and self.AutoLase[playername] then
    local Settings = ( client and _DATABASE:GetPlayerSettings( playername  ) ) or _SETTINGS
    local target = self:_GetHVTTarget(targetset) -- the one we're lasing
    local ThreatLevel = target:GetThreatLevel()
    local ThreatLevelText = "high"
    if ThreatLevel > 3 and ThreatLevel < 8 then
     ThreatLevelText = "medium"
    elseif  ThreatLevel <= 3 then
     ThreatLevelText = "low"
    end
    local ThreatGraph = "[" .. string.rep(  "■", ThreatLevel ) .. string.rep(  "□", 10 - ThreatLevel ) .. "]: "..ThreatLevel
    local report = REPORT:New("Lasing Report")
    report:Add(string.rep("-",15))
    report:Add("Target type: "..target:GetTypeName())
    report:Add("Threat Level: "..ThreatGraph.." ("..ThreatLevelText..")")
    report:Add("Location: "..client:GetCoordinate():ToStringBULLS(self.Coalition,Settings))
    --report:Add("Location: "..target:GetCoordinate():ToStringA2G(client,Settings))
    report:Add("Laser Code: "..self.UnitLaserCodes[playername] or 1688)
    report:Add(string.rep("-",15))
    local text = report:Text()
    self:__TargetReport(-1,client,targetset,target,text)
  else
    local report = REPORT:New("Lasing Report")
    report:Add(string.rep("-",15))
    report:Add("N O  T A R G E T S")
    report:Add(string.rep("-",15))
    local text = report:Text()
    self:__TargetReport(-1,client,nil,nil,text)
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
  self:I(self.lid.."_ReportVisualTargets")
  local targetset, number = self:_GetTargetSet(client,false)
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
    report:Add("Location: "..client:GetCoordinate():ToStringBULLS(self.Coalition,Settings))
    --report:Add("Location: "..client:GetCoordinate():ToStringA2G(client,Settings))
    report:Add(string.rep("-",15))
    local text = report:Text()
    self:__TargetReport(-1,client,targetset,nil,text)
  else
    local report = REPORT:New("Target Report")
    report:Add(string.rep("-",15))
    report:Add("N O  T A R G E T S")
    report:Add(string.rep("-",15))
    local text = report:Text()
    self:__TargetReport(-1,client,nil,nil,text)
  end
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param #PLAYERRECCE self
function PLAYERRECCE:_BuildMenus()
  self:I(self.lid.."_BuildMenus")
  local clients = self.PlayerSet -- Core.Set#SET_CLIENT
  local clientset = clients:GetSetObjects()
  for _,_client in pairs(clientset) do
    local client = _client -- Wrapper.Client#CLIENT
    if client and client:IsAlive() then
      local playername = client:GetPlayerName()
      if not self.UnitLaserCodes[playername] then
        self:_SetClientLaserCode(nil,nil,playername,1688)
      end
      local group = client:GetGroup()
      if not self.ClientMenus[playername] then
        local canlase = self.CanLase[client:GetTypeName()]
        self.ClientMenus[playername] = MENU_GROUP:New(group,self.Name or "RECCE")
        local txtonstation = self.OnStation[playername] and "ON" or "OFF"
        local text = string.format("Switch On-Station (%s)",txtonstation)
        local onstationmenu = MENU_GROUP_COMMAND:New(group,text,self.ClientMenus[playername],self._SwitchOnStation,self,client,group,playername)
        if self.OnStation[playername] then
          local smokemenu = MENU_GROUP_COMMAND:New(group,"Smoke Targets",self.ClientMenus[playername],self._SmokeTargets,self,client,group,playername)
          local smokemenu = MENU_GROUP_COMMAND:New(group,"Flare Targets",self.ClientMenus[playername],self._FlareTargets,self,client,group,playername)
          if canlase then
            local txtonstation = self.AutoLase[playername] and "ON" or "OFF"
            local text = string.format("Switch Lasing (%s)",txtonstation)
            local lasemenu = MENU_GROUP_COMMAND:New(group,text,self.ClientMenus[playername],self._SwitchLasing,self,client,group,playername)
          end
          local targetmenu = MENU_GROUP:New(group,"Target Report",self.ClientMenus[playername])
          if canlase then
            local reportL = MENU_GROUP_COMMAND:New(group,"Laser Target",targetmenu,self._ReportLaserTargets,self,client,group,playername)
          end
          local reportV = MENU_GROUP_COMMAND:New(group,"Visual Targets",targetmenu,self._ReportVisualTargets,self,client,group,playername)
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
  self:I(self.lid.."_CheckNewTargets")
  targetset:ForEachUnit(
    function(unit)
      if unit and unit:IsAlive() then
        if not unit.PlayerRecceDetected then
          unit.PlayerRecceDetected = {
            detected = true,
            recce = client,
            playername = playername,
            timestamp = timer.getTime()
          }
          self:__TargetDetected(-1,unit,client,playername)
        end
      end
    end
  )
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterStatus(From, Event, To)
  self:I({From, Event, To})
  
  self:_BuildMenus()
  
  self.PlayerSet:ForEachClient(
    function(Client)
        local client = Client -- Wrapper.Client#CLIENT
        local playername = client:GetPlayerName()
        if client and client:IsAlive() and self.OnStation[playername] then
          -- targets on camera
          local targetset, targetcount, tzone = self:_GetTargetSet(client,true)
          if targetset then
            if self.ViewZone[playername] then
              self.ViewZone[playername]:UndrawZone()
            end
            if self.debug and tzone then
              self.ViewZone[playername]=tzone:DrawZone(self.Coalition,{0,0,1},nil,nil,nil,1)
            end
          end
          self:I({targetcount=targetcount})
          -- visual targets
          local vistargetset, vistargetcount, viszone = self:_GetTargetSet(client,false)
          if vistargetset then
            if self.ViewZoneVisual[playername] then
              self.ViewZoneVisual[playername]:UndrawZone()
            end
            if self.debug and viszone then
              self.ViewZoneVisual[playername]=viszone:DrawZone(self.Coalition,{1,0,0},nil,nil,nil,3)
            end
          end
          self:I({targetcount=targetcount})
          -- lase targets on camera
          if targetcount > 0 then
            if self.CanLase[client:GetTypeName()] and self.AutoLase[playername] then
              -- DONE move to lase at will
              self:_LaseTarget(client,targetset)
            end
          end
          -- Report new targets
          targetset:AddSet(vistargetset)
          self:_CheckNewTargets(targetset,client,playername)
        end
    end
  )
   
  self:__Status(-10)
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterRecceOnStation(From, Event, To, Client, Playername)
  self:I({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(true,true)
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition)
  local text = string.format("All stations, FACA %s on station\nat %s!",callsign, coordtext)
  MESSAGE:New(text,15,self.Name or "FACA"):ToCoalition(self.Coalition)
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterRecceOffStation(From, Event, To, Client, Playername)
  self:I({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(true,true)
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition)
  local text = string.format("All stations, FACA %s leaving station\nat %s, going home!",callsign, coordtext)
  MESSAGE:New(text,15,self.Name or "FACA"):ToCoalition(self.Coalition)
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Unit#UNIT Target
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetDetected(From, Event, To, Target, Client, Playername)
  self:I({From, Event, To})
  if self.debug then
    local text = string.format("New target %s detected by %s!",Target:GetTypeName(),Playername)
    MESSAGE:New(text,10,self.Name or "FACA"):ToCoalition(self.Coalition)
  end
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @param Core.Set#SET_UNIT TargetSet
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetsSmoked(From, Event, To, Client, Playername, TargetSet)
  self:I({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(true,true)
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition)
  local text = string.format("All stations, FACA %s smoked targets\nat %s!",callsign, coordtext)
  MESSAGE:New(text,15,self.Name or "FACA"):ToCoalition(self.Coalition)
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param #string Playername
-- @param Core.Set#SET_UNIT TargetSet
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetsFlared(From, Event, To, Client, Playername, TargetSet)
  self:I({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(true,true)
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition)
  local text = string.format("All stations, FACA %s flared\ntargets at %s!",callsign, coordtext)
  MESSAGE:New(text,15,self.Name or "FACA"):ToCoalition(self.Coalition)
  return self
end
 
--- [Internal] 
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
  self:I({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(true,true)
  local Settings = ( Client and _DATABASE:GetPlayerSettings( Client:GetPlayerName() ) ) or _SETTINGS
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition,Settings)
  local targettype = Target:GetTypeName()
  local text = string.format("All stations, FACA %s lasing %s\nat %s!\nCode %d, Duration %d seconds!",callsign, targettype, coordtext, Lasercode, Lasingtime)
  MESSAGE:New(text,15,self.Name or "FACA"):ToCoalition(self.Coalition)
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param Wrapper.Unit#UNIT Target
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetLOSLost(From, Event, To, Client, Target)
  self:I({From, Event, To})
  local callsign = Client:GetGroup():GetCustomCallSign(true,true)
  local Settings = ( Client and _DATABASE:GetPlayerSettings( Client:GetPlayerName() ) ) or _SETTINGS
  local coord = Client:GetCoordinate()
  local coordtext = coord:ToStringBULLS(self.Coalition,Settings)
  local targettype = Target:GetTypeName()
  local text = string.format("All stations, FACA %s lost sight of %s\nat %s!",callsign, targettype, coordtext)
  MESSAGE:New(text,15,self.Name or "FACA"):ToCoalition(self.Coalition)
  return self
end

--- [Internal] 
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
  self:I({From, Event, To})
  MESSAGE:New(Text,45,self.Name or "FACA"):ToClient(Client)
  if self.AttackSet then
    -- send message to AttackSet
    for _,_client in pairs(self.AttackSet.Set) do
      local client = _client -- Wrapper.Client#CLIENT
      if client and client:IsAlive() then
        MESSAGE:New(Text,45,self.Name or "FACA"):ToClient(client)
      end
    end
  end
  self:__TargetReportSent(-2,Client, TargetSet, Target, Text)
  return self
end

--- [Internal] 
-- @param #PLAYERRECCE self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @param Core.Set#SET_UNIT TargetSet
-- @param Wrapper.Unit#UNIT Target
-- @param #string Text
-- @return #PLAYERRECCE self
function PLAYERRECCE:onafterTargetReportSent(From, Event, To, Client, TargetSet, Target, Text)
  self:I({From, Event, To})
  return self
end


--- [Internal] 
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

--[[ test script
local PlayerSet = SET_CLIENT:New():FilterCoalitions("blue"):FilterActive(true):FilterCategories("helicopter"):FilterStart()
local Attackers = SET_CLIENT:New():FilterCoalitions("blue"):FilterActive(true):FilterStart()
local myrecce = PLAYERRECCE:New("1st Forward FACA",coalition.side.BLUE,PlayerSet)
myrecce:SetAttackSet(Attackers)
--]]