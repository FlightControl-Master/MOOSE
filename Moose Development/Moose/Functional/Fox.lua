--- **Functional** - Yet Another Missile Trainer.
-- 
-- 
-- Practice to evade missiles without being destroyed.
-- 
--
-- ## Main Features:
-- 
--    * Handles air-to-air and surface-to-air missiles.
--    * Define your own training zones on the map. Players in this zone will be protected.
--    * Define launch zones. Only missiles launched in these zones are tracked. 
--    * Define protected AI groups.
--    * F10 radio menu to adjust settings for each player.
--    * Alert on missile launch (optional).
--    * Marker of missile launch position (optional).
--    * Adaptive update of missile-to-player distance.
--    * Finite State Machine (FSM) implementation.
--    * Easy to use. See examples below.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Functional.Fox
-- @image Functional_FOX.png

--- FOX class.
-- @type FOX
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table menuadded Table of groups the menu was added for.
-- @field #boolean menudisabled If true, F10 menu for players is disabled.
-- @field #boolean destroy Default player setting for destroying missiles.
-- @field #boolean launchalert Default player setting for launch alerts.
-- @field #boolean marklaunch Default player setting for mark launch coordinates.
-- @field #table players Table of players.
-- @field #table missiles Table of tracked missiles.
-- @field #table safezones Table of practice zones.
-- @field #table launchzones Table of launch zones.
-- @field Core.Set#SET_GROUP protectedset Set of protected groups.
-- @field #number explosionpower Power of explostion when destroying the missile in kg TNT. Default 5 kg TNT.
-- @field #number explosiondist Missile player distance in meters for destroying smaller missiles. Default 200 m.
-- @field #number explosiondist2 Missile player distance in meters for destroying big missiles. Default 500 m.
-- @field #number bigmissilemass Explosion power of big missiles. Default 50 kg TNT. Big missiles will be destroyed earlier.
-- @field #number dt50 Time step [sec] for missile position updates if distance to target > 50 km. Default 5 sec.
-- @field #number dt10 Time step [sec] for missile position updates if distance to target > 10 km and < 50 km. Default 1 sec.
-- @field #number dt05 Time step [sec] for missile position updates if distance to target > 5 km and < 10 km. Default 0.5 sec.
-- @field #number dt01 Time step [sec] for missile position updates if distance to target > 1 km and < 5 km. Default 0.1 sec.
-- @field #number dt00 Time step [sec] for missile position updates if distance to target < 1 km. Default 0.01 sec. 
-- @extends Core.Fsm#FSM

--- Fox 3!
--
-- ===
--
-- ![Banner Image](..\Presentations\FOX\FOX_Main.png)
--
-- # The FOX Concept
-- 
-- As you probably know [Fox](https://en.wikipedia.org/wiki/Fox_(code_word)) is a NATO brevity code for launching air-to-air munition. Therefore, the class name is not 100% accurate as this
-- script handles air-to-air but also surface-to-air missiles.
-- 
-- # Basic Script
-- 
--     -- Create a new missile trainer object.
--     fox=FOX:New()
--     
--     -- Start missile trainer.
--     fox:Start()
-- 
-- # Training Zones
-- 
-- Players are only protected if they are inside one of the training zones.
-- 
--     -- Create a new missile trainer object.
--     fox=FOX:New()
--     
--     -- Add training zones.
--     fox:AddSafeZone(ZONE:New("Training Zone Alpha"))
--     fox:AddSafeZone(ZONE:New("Training Zone Bravo"))
--     
--     -- Start missile trainer.
--     fox:Start()
-- 
-- # Launch Zones
-- 
-- Missile launches are only monitored if the shooter is inside the defined launch zone.
-- 
--     -- Create a new missile trainer object.
--     fox=FOX:New()
--     
--     -- Add training zones.
--     fox:AddLaunchZone(ZONE:New("Launch Zone SA-10 Krim"))
--     fox:AddLaunchZone(ZONE:New("Training Zone Bravo"))
--     
--     -- Start missile trainer.
--     fox:Start()
-- 
-- # Protected AI Groups
-- 
-- Define AI protected groups. These groups cannot be harmed by missiles.
-- 
-- ## Add Individual Groups
-- 
--     -- Create a new missile trainer object.
--     fox=FOX:New()
--     
--     -- Add single protected group(s).
--     fox:AddProtectedGroup(GROUP:FindByName("A-10 Protected"))
--     fox:AddProtectedGroup(GROUP:FindByName("Yak-40"))
--     
--     -- Start missile trainer.
--     fox:Start()
-- 
-- # Fine Tuning
-- 
-- Todo!
-- 
-- # Special Events
-- 
-- Todo!
-- 
-- 
-- @field #FOX
FOX = {
  ClassName      = "FOX",
  verbose        =    0,
  Debug          = false,
  lid            =   nil,
  menuadded      =    {},
  menudisabled   =   nil,
  destroy        =   nil,
  launchalert    =   nil,
  marklaunch     =   nil,
  missiles       =    {},
  players        =    {},
  safezones      =    {},
  launchzones    =    {},
  protectedset   =   nil,
  explosionpower =   0.1,
  explosiondist  =   200,
  explosiondist2 =   500,
  bigmissilemass =    50,
  destroy        =   nil,
  dt50           =     5,
  dt10           =     1,
  dt05           =   0.5,
  dt01           =   0.1,
  dt00           =  0.01,
}


--- Player data table holding all important parameters of each player.
-- @type FOX.PlayerData
-- @field Wrapper.Unit#UNIT unit Aircraft of the player.
-- @field #string unitname Name of the unit.
-- @field Wrapper.Client#CLIENT client Client object of player.
-- @field #string callsign Callsign of player.
-- @field Wrapper.Group#GROUP group Aircraft group of player.
-- @field #string groupname Name of the the player aircraft group.
-- @field #string name Player name.
-- @field #number coalition Coalition number of player.
-- @field #boolean destroy Destroy missile.
-- @field #boolean launchalert Alert player on detected missile launch.
-- @field #boolean marklaunch Mark position of launched missile on F10 map.
-- @field #number defeated Number of missiles defeated.
-- @field #number dead Number of missiles not defeated.
-- @field #boolean inzone Player is inside a protected zone.

--- Missile data table.
-- @type FOX.MissileData
-- @field DCS#Weapon weapon Missile weapon object.
-- @field #boolean active If true the missile is active.
-- @field #string missileType Type of missile.
-- @field #string missileName Name of missile.
-- @field #number missileRange Range of missile in meters.
-- @field #number fuseDist Fuse distance in meters.
-- @field #number explosive Explosive mass in kg TNT.
-- @field Wrapper.Unit#UNIT shooterUnit Unit that shot the missile.
-- @field Wrapper.Group#GROUP shooterGroup Group that shot the missile.
-- @field #number shooterCoalition Coalition side of the shooter.
-- @field #string shooterName Name of the shooter unit.
-- @field #number shotTime Abs. mission time in seconds the missile was fired.
-- @field Core.Point#COORDINATE shotCoord Coordinate where the missile was fired.
-- @field Wrapper.Unit#UNIT targetUnit Unit that was targeted.
-- @field #string targetName Name of the target unit or "unknown".
-- @field #string targetOrig Name of the "original" target, i.e. the one right after launched.
-- @field #FOX.PlayerData targetPlayer Player that was targeted or nil.
-- @field Core.Point#COORDINATE missileCoord Missile coordinate during tracking.
-- @field Wrapper.Weapon#WEAPON Weapon Weapon object.

--- Main radio menu on group level.
-- @field #table MenuF10 Root menu table on group level.
FOX.MenuF10={}

--- Main radio menu on mission level.
-- @field #table MenuF10Root Root menu on mission level.
FOX.MenuF10Root=nil

--- FOX class version.
-- @field #string version
FOX.version="0.8.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO list:
-- DONE: safe zones
-- DONE: mark shooter on F10

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FOX class object.
-- @param #FOX self
-- @return #FOX self.
function FOX:New()

  self.lid="FOX | "

  -- Inherit everthing from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #FOX
  
  -- Defaults:
  self:SetDefaultMissileDestruction(true)
  self:SetDefaultLaunchAlerts(true)
  self:SetDefaultLaunchMarks(true)
  
  -- Explosion/destruction defaults.
  self:SetExplosionDistance()
  self:SetExplosionDistanceBigMissiles()
  self:SetExplosionPower()
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State   -->   Event        -->     To State
  self:AddTransition("Stopped",           "Start",          "Running")     -- Start FOX script.
  self:AddTransition("*",                "Status",          "*")           -- Status update.
  self:AddTransition("*",         "MissileLaunch",          "*")           -- Missile was launched.
  self:AddTransition("*",      "MissileDestroyed",          "*")           -- Missile was destroyed before impact.
  self:AddTransition("*",         "EnterSafeZone",          "*")           -- Player enters a safe zone.
  self:AddTransition("*",          "ExitSafeZone",          "*")           -- Player exists a safe zone.
  self:AddTransition("Running",            "Stop",          "Stopped")     -- Stop FOX script.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the FOX. Initializes parameters and starts event handlers.
  -- @function [parent=#FOX] Start
  -- @param #FOX self

  --- Triggers the FSM event "Start" after a delay. Starts the FOX. Initializes parameters and starts event handlers.
  -- @function [parent=#FOX] __Start
  -- @param #FOX self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the FOX and all its event handlers.
  -- @param #FOX self

  --- Triggers the FSM event "Stop" after a delay. Stops the FOX and all its event handlers.
  -- @function [parent=#FOX] __Stop
  -- @param #FOX self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#FOX] Status
  -- @param #FOX self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#FOX] __Status
  -- @param #FOX self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "MissileLaunch".
  -- @function [parent=#FOX] MissileLaunch
  -- @param #FOX self
  -- @param #FOX.MissileData missile Data of the fired missile.

  --- Triggers the FSM delayed event "MissileLaunch".
  -- @function [parent=#FOX] __MissileLaunch
  -- @param #FOX self
  -- @param #number delay Delay in seconds before the function is called.
  -- @param #FOX.MissileData missile Data of the fired missile.

  --- On after "MissileLaunch" event user function. Called when a missile was launched.
  -- @function [parent=#FOX] OnAfterMissileLaunch
  -- @param #FOX self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #FOX.MissileData missile Data of the fired missile.

  --- Triggers the FSM event "MissileDestroyed".
  -- @function [parent=#FOX] MissileDestroyed
  -- @param #FOX self
  -- @param #FOX.MissileData missile Data of the destroyed missile.

  --- Triggers the FSM delayed event "MissileDestroyed".
  -- @function [parent=#FOX] __MissileDestroyed
  -- @param #FOX self
  -- @param #number delay Delay in seconds before the function is called.
  -- @param #FOX.MissileData missile Data of the destroyed missile.

  --- On after "MissileDestroyed" event user function. Called when a missile was destroyed.
  -- @function [parent=#FOX] OnAfterMissileDestroyed
  -- @param #FOX self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #FOX.MissileData missile Data of the destroyed missile.


  --- Triggers the FSM event "EnterSafeZone".
  -- @function [parent=#FOX] EnterSafeZone
  -- @param #FOX self
  -- @param #FOX.PlayerData player Player data.

  --- Triggers the FSM delayed event "EnterSafeZone".
  -- @function [parent=#FOX] __EnterSafeZone
  -- @param #FOX self
  -- @param #number delay Delay in seconds before the function is called.
  -- @param #FOX.PlayerData player Player data.

  --- On after "EnterSafeZone" event user function. Called when a player enters a safe zone.
  -- @function [parent=#FOX] OnAfterEnterSafeZone
  -- @param #FOX self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #FOX.PlayerData player Player data.


  --- Triggers the FSM event "ExitSafeZone".
  -- @function [parent=#FOX] ExitSafeZone
  -- @param #FOX self
  -- @param #FOX.PlayerData player Player data.

  --- Triggers the FSM delayed event "ExitSafeZone".
  -- @function [parent=#FOX] __ExitSafeZone
  -- @param #FOX self
  -- @param #number delay Delay in seconds before the function is called.
  -- @param #FOX.PlayerData player Player data.

  --- On after "ExitSafeZone" event user function. Called when a player exists a safe zone.
  -- @function [parent=#FOX] OnAfterExitSafeZone
  -- @param #FOX self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #FOX.PlayerData player Player data.

  
  return self
end

--- On after Start event. Starts the missile trainer and adds event handlers.
-- @param #FOX self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FOX:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting FOX Missile Trainer %s", FOX.version)
  env.info(text)

  -- Handle events:
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.Shot)
  
  if self.Debug then
    self:HandleEvent(EVENTS.Hit)
  end
  
  if self.Debug then
    self:TraceClass(self.ClassName)
    self:TraceLevel(2)
  end
  
  self:__Status(-20)
end

--- On after Stop event. Stops the missile trainer and unhandles events.
-- @param #FOX self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FOX:onafterStop(From, Event, To)

  -- Short info.
  local text=string.format("Stopping FOX Missile Trainer %s", FOX.version)
  env.info(text)

  -- Handle events:
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.Shot)
  
  if self.Debug then
    self:UnhandleEvent(EVENTS.Hit)
  end

end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a training zone. Players in the zone are safe.
-- @param #FOX self
-- @param Core.Zone#ZONE zone Training zone.
-- @return #FOX self
function FOX:AddSafeZone(zone)

  table.insert(self.safezones, zone)

  return self
end

--- Add a launch zone. Only missiles launched within these zones will be tracked.
-- @param #FOX self
-- @param Core.Zone#ZONE zone Training zone.
-- @return #FOX self
function FOX:AddLaunchZone(zone)

  table.insert(self.launchzones, zone)

  return self
end

--- Add a protected set of groups.
-- @param #FOX self
-- @param Core.Set#SET_GROUP groupset The set of groups.
-- @return #FOX self
function FOX:SetProtectedGroupSet(groupset)
  self.protectedset=groupset
  return self
end

--- Add a group to the protected set.
-- @param #FOX self
-- @param Wrapper.Group#GROUP group Protected group.
-- @return #FOX self
function FOX:AddProtectedGroup(group)
  
  if not self.protectedset then
    self.protectedset=SET_GROUP:New()
  end
  
  self.protectedset:AddGroup(group)
  
  return self
end

--- Set explosion power. This is an "artificial" explosion generated when the missile is destroyed. Just for the visual effect.
-- Don't set the explosion power too big or it will harm the aircraft in the vicinity.
-- @param #FOX self
-- @param #number power Explosion power in kg TNT. Default 0.1 kg.
-- @return #FOX self
function FOX:SetExplosionPower(power)

  self.explosionpower=power or 0.1

  return self
end

--- Set missile-player distance when missile is destroyed.
-- @param #FOX self
-- @param #number distance Distance in meters. Default 200 m.
-- @return #FOX self
function FOX:SetExplosionDistance(distance)

  self.explosiondist=distance or 200

  return self
end

--- Set missile-player distance when BIG missiles are destroyed.
-- @param #FOX self
-- @param #number distance Distance in meters. Default 500 m.
-- @param #number explosivemass Explosive mass of missile threshold in kg TNT. Default 50 kg.
-- @return #FOX self
function FOX:SetExplosionDistanceBigMissiles(distance, explosivemass)

  self.explosiondist2=distance or 500
  
  self.bigmissilemass=explosivemass or 50

  return self
end

--- Disable F10 menu for all players.
-- @param #FOX self
-- @return #FOX self
function FOX:SetDisableF10Menu()

  self.menudisabled=true

  return self
end


--- Enable F10 menu for all players.
-- @param #FOX self
-- @return #FOX self
function FOX:SetEnableF10Menu()

  self.menudisabled=false

  return self
end

--- Set verbosity level.
-- @param #FOX self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #FOX self
function FOX:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Set default player setting for missile destruction.
-- @param #FOX self
-- @param #boolean switch If true missiles are destroyed. If false/nil missiles are not destroyed.
-- @return #FOX self
function FOX:SetDefaultMissileDestruction(switch)

  if switch==nil then
    self.destroy=false
  else
    self.destroy=switch
  end

  return self
end

--- Set default player setting for launch alerts.
-- @param #FOX self
-- @param #boolean switch If true launch alerts to players are active. If false/nil no launch alerts are given.
-- @return #FOX self
function FOX:SetDefaultLaunchAlerts(switch)

  if switch==nil then
    self.launchalert=false
  else
    self.launchalert=switch
  end

  return self
end

--- Set default player setting for marking missile launch coordinates
-- @param #FOX self
-- @param #boolean switch If true missile launches are marked. If false/nil marks are disabled.
-- @return #FOX self
function FOX:SetDefaultLaunchMarks(switch)

  if switch==nil then
    self.marklaunch=false
  else
    self.marklaunch=switch
  end

  return self
end


--- Set debug mode on/off.
-- @param #FOX self
-- @param #boolean switch If true debug mode on. If false/nil debug mode off.
-- @return #FOX self
function FOX:SetDebugOnOff(switch)

  if switch==nil then
    self.Debug=false
  else
    self.Debug=switch
  end

  return self
end

--- Set debug mode on.
-- @param #FOX self
-- @return #FOX self
function FOX:SetDebugOn()
  self:SetDebugOnOff(true)
  return self
end

--- Set debug mode off.
-- @param #FOX self
-- @return #FOX self
function FOX:SetDebugOff()
  self:SetDebugOff(false)
  return self
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status Functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check spawn queue and spawn aircraft if necessary.
-- @param #FOX self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FOX:onafterStatus(From, Event, To)

  -- Get FSM state.
  local fsmstate=self:GetState()
  
  local time=timer.getAbsTime()
  local clock=UTILS.SecondsToClock(time)
  
  -- Status.
  if self.verbose>=1 then
    self:I(self.lid..string.format("Missile trainer status %s: %s", clock, fsmstate))
  end
  
  -- Check missile status.
  self:_CheckMissileStatus()
  
  -- Check player status.
  self:_CheckPlayers()

  if fsmstate=="Running" then
    self:__Status(-10)
  end
end

--- Check status of players.
-- @param #FOX self
function FOX:_CheckPlayers()

  for playername,_playersettings in pairs(self.players) do
    local playersettings=_playersettings  --#FOX.PlayerData
    
    local unitname=playersettings.unitname
    local unit=UNIT:FindByName(unitname)
    
    if unit and unit:IsAlive() then
    
      local coord=unit:GetCoordinate()
      
      local issafe=self:_CheckCoordSafe(coord)
      
        
      if issafe then
      
        -----------------------------
        -- Player INSIDE Safe Zone --
        -----------------------------
      
        if not playersettings.inzone then
          self:EnterSafeZone(playersettings)
          playersettings.inzone=true
        end
        
      else
      
        ------------------------------
        -- Player OUTSIDE Safe Zone --
        ------------------------------     
      
        if playersettings.inzone==true then
          self:ExitSafeZone(playersettings)
          playersettings.inzone=false
        end
        
      end
    end
  end

end

--- Remove missile.
-- @param #FOX self
-- @param #FOX.MissileData missile Missile data.
function FOX:_RemoveMissile(missile)

  if missile then
    for i,_missile in pairs(self.missiles) do
      local m=_missile --#FOX.MissileData
      if missile.missileName==m.missileName then
        table.remove(self.missiles, i)
        return
      end
    end  
  end

end

--- Missile status.
-- @param #FOX self
function FOX:_CheckMissileStatus()

  local text="Missiles:"
  local inactive={}
  for i,_missile in pairs(self.missiles) do
    local missile=_missile --#FOX.MissileData
    
    local targetname="unkown"
    if missile.targetUnit then
      targetname=missile.targetUnit:GetName()
    end
    local playername="none"
    if missile.targetPlayer then
      playername=missile.targetPlayer.name
    end
    local active=tostring(missile.active)
    local mtype=missile.missileType
    local dtype=missile.missileType
    local range=UTILS.MetersToNM(missile.missileRange)
    
    if not active then
      table.insert(inactive,i)
    end
    local heading=self:_GetWeapongHeading(missile.weapon)
    
    text=text..string.format("\n[%d] %s: active=%s, range=%.1f NM, heading=%03d, target=%s, player=%s, missilename=%s", i, mtype, active, range, heading, targetname, playername, missile.missileName)
    
  end
  if #self.missiles==0 then
    text=text.." none"
  end
  if self.verbose>=2 then
    self:I(self.lid..text)
  end

  -- Remove inactive missiles.  
  for i=#self.missiles,1,-1 do
    local missile=self.missiles[i] --#FOX.MissileData
    if missile and not missile.active then
      table.remove(self.missiles, i)
    end
  end

end

--- Check if missile target is protected.
-- @param #FOX self
-- @param Wrapper.Unit#UNIT targetunit Target unit.
-- @return #boolean If true, unit is protected.
function FOX:_IsProtected(targetunit)

  if not self.protectedset then
    return false
  end
  
  if targetunit and targetunit:IsAlive() then

    -- Get Group.
    local targetgroup=targetunit:GetGroup()
    
    if targetgroup then
      local targetname=targetgroup:GetName()
      
      for _,_group in pairs(self.protectedset:GetSet()) do
        local group=_group --Wrapper.Group#GROUP
        
        if group then
          local groupname=group:GetName()
          
          -- Target belongs to a protected set.
          if targetname==groupname then
            return true
          end
        end
        
      end
    end
  end
  
  return false
end


--- Function called from weapon tracking.
-- @param Wrapper.Weapon#WEAPON weapon Weapon object.
-- @param #FOX self FOX object.
-- @param #FOX.MissileData missile Fired missile
function FOX._FuncTrack(weapon, self, missile)

  -- Missile coordinate.
  local missileCoord= missile.missileCoord:UpdateFromVec3(weapon.vec3) --COORDINATE:NewFromVec3(_lastBombPos)
  
  -- Missile velocity in m/s.
  local missileVelocity=weapon:GetSpeed() --UTILS.VecNorm(_ordnance:getVelocity())
  
  -- Update missile target if necessary.
  self:GetMissileTarget(missile)
  
 -- Target unit of the missile.
  local target=nil --Wrapper.Unit#UNIT  
  
  if missile.targetUnit then
  
    -----------------------------------
    -- Missile has a specific target --
    -----------------------------------
  
    if missile.targetPlayer then
      -- Target is a player.
      if missile.targetPlayer.destroy==true then
        target=missile.targetUnit
      end
    else
      -- Check if unit is protected.
      if self:_IsProtected(missile.targetUnit) then
        target=missile.targetUnit
      end
    end
    
  else
  
    ------------------------------------
    -- Missile has NO specific target --
    ------------------------------------   
    
    -- TODO: This might cause a problem with wingman. Even if the shooter itself is excluded from the check, it's wingmen are not.
    --       That would trigger the distance check right after missile launch if things to wrong.
    --
    --       Possible solutions:
    --       * Time check: enable this check after X seconds after missile was fired. What is X?
    --       * Coalition check. But would not work in training situations where blue on blue is valid!
    --       * At least enable it for surface-to-air missiles.
    
    local function _GetTarget(_unit)
      local unit=_unit --Wrapper.Unit#UNIT
  
      -- Player position.
      local playerCoord=unit:GetCoordinate()
        
      -- Distance.            
      local dist=missileCoord:Get3DDistance(playerCoord)
                    
      -- Update mindist if necessary. Only include players in range of missile + 50% safety margin.
      if dist<=self.explosiondist then
        return unit
      end          
    end
    
    -- Distance to closest player.
    local mindist=nil
    
    -- Loop over players.
    for _,_player in pairs(self.players) do
      local player=_player  --#FOX.PlayerData
      
      -- Check that player was not the one who launched the missile.
      if player.unitname~=missile.shooterName then
      
        -- Player position.
        local playerCoord=player.unit:GetCoordinate()
        
        -- Distance.            
        local dist=missileCoord:Get3DDistance(playerCoord)
        
        -- Distance from shooter to player.
        local Dshooter2player=playerCoord:Get3DDistance(missile.shotCoord)
        
        -- Update mindist if necessary. Only include players in range of missile + 50% safety margin.
        if (mindist==nil or dist<mindist) and (Dshooter2player<=missile.missileRange*1.5 or dist<=self.explosiondist) then
          mindist=dist
          target=player.unit
        end
      end            
    end
    
    if self.protectedset then
    
      -- Distance to closest protected unit.
      mindist=nil
    
      for _,_group in pairs(self.protectedset:GetSet()) do
        local group=_group --Wrapper.Group#GROUP
        for _,_unit in pairs(group:GetUnits()) do
          local unit=_unit --Wrapper.Unit#UNIT
          
          if unit and unit:IsAlive() then
          
            -- Check that player was not the one who launched the missile.
            if unit:GetName()~=missile.shooterName then
            
              -- Player position.
              local playerVec3=unit:GetVec3()
              
              -- Distance.
              local dist=missileCoord:Get3DDistance(playerVec3)
                            
              -- Distance from shooter to player.
              local Dshooter2player=missile.shotCoord:Get3DDistance(playerVec3)
              
              -- Update mindist if necessary. Only include players in range of missile + 50% safety margin.
              if (mindist==nil or dist<mindist) and (Dshooter2player<=missile.missileRange*1.5 or dist<=self.explosiondist) then
                mindist=dist
                target=unit
              end
            end
                                      
          end              
        end             
      end
    end
    
    if target then
      self:T(self.lid..string.format("Missile %s with NO explicit target got closest unit to missile as target %s. Dist=%s m", missile.missileType, target:GetName(), tostring(mindist)))
    end
         
  end
  
  -- Check if missile has a valid target.
  if target then
  
    -- Target coordinate.
    local targetVec3=target:GetVec3() --target:GetCoordinate()
  
    -- Distance from missile to target.
    local distance=missileCoord:Get3DDistance(targetVec3)
    
    -- Distance missile to shooter.
    local distShooter=nil
    if missile.shooterUnit and missile.shooterUnit:IsAlive() then
      distShooter=missileCoord:Get3DDistance(missile.shooterUnit:GetVec3())
    end
    
    
    -- Debug output.
    if self.Debug then    
      local bearing=missileCoord:HeadingTo(targetVec3)
      local eta=distance/missileVelocity    
      -- Debug distance check.
      self:I(self.lid..string.format("Missile %s Target %s: Distance = %.1f m, v=%.1f m/s, bearing=%03d°, ETA=%.1f sec", missile.missileType, target:GetName(), distance, missileVelocity, bearing, eta))
    end
    
    -- Distroy missile if it's getting too close.
    local destroymissile=distance<=self.explosiondist
    
    -- Check BIG missiles.
    if self.explosiondist2 and distance<=self.explosiondist2 and not destroymissile then
       destroymissile=missile.explosive>=self.bigmissilemass
    end
  
    -- If missile is 150 m from target ==> destroy missile if in safe zone.
    if destroymissile and self:_CheckCoordSafe(targetVec3) then
    
      -- Destroy missile.
      self:I(self.lid..string.format("Destroying missile %s(%s) fired by %s aimed at %s [player=%s] at distance %.1f m", 
      missile.missileType, missile.missileName, missile.shooterName, target:GetName(), tostring(missile.targetPlayer~=nil), distance))
      weapon:Destroy()
      
      -- Missile is not active any more.
      missile.active=false
      
      -- Debug smoke.
      if self.Debug then
        missileCoord:SmokeRed()          
      end
      
      -- Create event.
      self:MissileDestroyed(missile)
      
      -- Little explosion for the visual effect.
      if self.explosionpower>0 and distance>50 and (distShooter==nil or (distShooter and distShooter>50)) then
        missileCoord:Explosion(self.explosionpower)
      end
                
      -- Target was a player.
      if missile.targetPlayer then
      
        -- Message to target.
        local text=string.format("Destroying missile. %s", self:_DeadText())
        MESSAGE:New(text, 10):ToGroup(target:GetGroup())
                
        -- Increase dead counter.
        missile.targetPlayer.dead=missile.targetPlayer.dead+1
      end

      -- We could disable the tracking here but then the impact function would not be called.
      --weapon.tracking=false
      
    else
    
      -- Time step.
      local dt=1.0          
      if distance>50000 then
        -- > 50 km
        dt=self.dt50 --=5.0
      elseif distance>10000 then
        -- 10-50 km
        dt=self.dt10 --=1.0
      elseif distance>5000 then
        -- 5-10 km
        dt=self.dt05 --0.5
      elseif distance>1000 then
        -- 1-5 km
        dt=self.dt01 --0.1
      else
        -- < 1 km
        dt=self.dt00 --0.01
      end
    
      -- Set time step.
      weapon:SetTimeStepTrack(dt)
    end
    
  else
  
    -- No current target.
    self:T(self.lid..string.format("Missile %s(%s) fired by %s has no current target. Checking back in 0.1 sec.",  missile.missileType, missile.missileName, missile.shooterName))
    weapon:SetTimeStepTrack(0.1)
    
  end

end

--- Callback function on impact or destroy otherwise.
-- @param Wrapper.Weapon#WEAPON weapon Weapon object.
-- @param #FOX self FOX object.
-- @param #FOX.MissileData missile Fired missile.
function FOX._FuncImpact(weapon, self, missile)

  if missile.targetPlayer then  
  
    -- Get human player.
    local player=missile.targetPlayer
    
    -- Check for player and distance < 10 km.
    if player and player.unit:IsAlive() then -- and missileCoord and player.unit:GetCoordinate():Get3DDistance(missileCoord)<10*1000 then
      local text=string.format("Missile defeated. Well done, %s!", player.name)
      MESSAGE:New(text, 10):ToClient(player.client)
      
      -- Increase defeated counter.
      player.defeated=player.defeated+1
    end
    
  end
  
  -- Missile is not active any more.
  missile.active=false   
          
  --Terminate the timer.
  self:T(FOX.lid..string.format("Terminating missile track timer."))
  weapon.tracking=false

end

--- Missle launch event.
-- @param #FOX self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FOX.MissileData missile Fired missile
function FOX:onafterMissileLaunch(From, Event, To, missile)

  -- Tracking info and init of last bomb position.
  local text=string.format("FOX: Tracking missile %s(%s) - target %s - shooter %s", missile.missileType, missile.missileName, tostring(missile.targetName), missile.shooterName)
  self:I(FOX.lid..text)
  MESSAGE:New(text, 10):ToAllIf(self.Debug)
  
  -- Loop over players.
  for _,_player in pairs(self.players) do
    local player=_player  --#FOX.PlayerData
    
    -- Player position.
    local playerUnit=player.unit
    
    -- Check that player is alive and of the opposite coalition.
    if playerUnit and playerUnit:IsAlive() and player.coalition~=missile.shooterCoalition then
    
      -- Player missile distance.
      local distance=playerUnit:GetCoordinate():Get3DDistance(missile.shotCoord)
      
      -- Player bearing to missile.
      local bearing=playerUnit:GetCoordinate():HeadingTo(missile.shotCoord)
      
      -- Alert that missile has been launched.
      if player.launchalert then
      
        -- Alert directly targeted players or players that are within missile max range.
        if (missile.targetPlayer and player.unitname==missile.targetPlayer.unitname) or (distance<missile.missileRange)  then
              
          -- Inform player.
          local text=string.format("Missile launch detected! Distance %.1f NM, bearing %03d°.", UTILS.MetersToNM(distance), bearing)
          
          -- Say notching headings.
          self:ScheduleOnce(5, FOX._SayNotchingHeadings, self, player, missile.weapon)
                    
          --TODO: ALERT or INFO depending on whether this is a direct target.
          --TODO: lauchalertall option.
          MESSAGE:New(text, 5, "ALERT"):ToClient(player.client)
          
        end
        
      end
        
      -- Mark coordinate.
      if player.marklaunch then
        local text=string.format("Missile launch coordinates:\n%s\n%s", missile.shotCoord:ToStringLLDMS(), missile.shotCoord:ToStringBULLS(player.coalition))          
        missile.shotCoord:MarkToGroup(text, player.group)
      end
        
    end
  end
  
  -- Set callback function for tracking.
  missile.Weapon:SetFuncTrack(FOX._FuncTrack, self, missile)
  
  -- Set callback function for impact.
  missile.Weapon:SetFuncImpact(FOX._FuncImpact, self, missile)
  
  
  -- Weapon is not yet "alife" just yet. Start timer with a little delay.
  self:T(FOX.lid..string.format("Tracking of missile starts in 0.0001 seconds."))
  --timer.scheduleFunction(trackMissile, missile.weapon, timer.getTime()+0.0001)
  missile.Weapon:StartTrack(0.0001)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- FOX event handler for event birth.
-- @param #FOX self
-- @param Core.Event#EVENTDATA EventData
function FOX:OnEventPlayerEnterAircraft(EventData)

end

--- FOX event handler for event birth.
-- @param #FOX self
-- @param Core.Event#EVENTDATA EventData
function FOX:OnEventBirth(EventData)
  self:F3({eventbirth = EventData})
  
  -- Nil checks.
  if EventData==nil then
    self:E(self.lid.."ERROR: EventData=nil in event BIRTH!")
    self:E(EventData)
    return
  end
  if EventData.IniUnit==nil then
    self:E(self.lid.."ERROR: EventData.IniUnit=nil in event BIRTH!")
    self:E(EventData)
    return
  end  
  
  -- Player unit and name.
  local _unitName=EventData.IniUnitName
  local playerunit, playername=self:_GetPlayerUnitAndName(_unitName)
  
  -- Debug info.
  self:T(self.lid.."BIRTH: unit   = "..tostring(EventData.IniUnitName))
  self:T(self.lid.."BIRTH: group  = "..tostring(EventData.IniGroupName))
  self:T(self.lid.."BIRTH: player = "..tostring(playername))
      
  -- Check if player entered.
  if playerunit and playername then
  
    local _uid=playerunit:GetID()
    local _group=playerunit:GetGroup()
    local _callsign=playerunit:GetCallsign()
    
    -- Debug output.
    local text=string.format("Pilot %s, callsign %s entered unit %s of group %s.", playername, _callsign, _unitName, _group:GetName())
    self:T(self.lid..text)
    MESSAGE:New(text, 5):ToAllIf(self.Debug)
            
    -- Add F10 radio menu for player.
    if not self.menudisabled then
      self:ScheduleOnce(0.1, self._AddF10Commands, self, _unitName)
    end
    
    -- Player data.
    local playerData={} --#FOX.PlayerData
    
    -- Player unit, client and callsign.
    playerData.unit      = playerunit
    playerData.unitname  = _unitName
    playerData.group     = _group
    playerData.groupname = _group:GetName()
    playerData.name      = playername
    playerData.callsign  = playerData.unit:GetCallsign()
    playerData.client    = CLIENT:FindByName(_unitName, nil, true)
    playerData.coalition = _group:GetCoalition()
    
    playerData.destroy=playerData.destroy or self.destroy
    playerData.launchalert=playerData.launchalert or self.launchalert
    playerData.marklaunch=playerData.marklaunch or self.marklaunch
    
    playerData.defeated=playerData.defeated or 0
    playerData.dead=playerData.dead or 0
    
    -- Init player data.
    self.players[playername]=playerData
    
  end 
end

--- Get missile target.
-- @param #FOX self
-- @param #FOX.MissileData missile The missile data table.
function FOX:GetMissileTarget(missile)

  local target=nil
  local targetName="unknown"
  local targetUnit=nil --Wrapper.Unit#UNIT
  
  if missile.weapon and missile.weapon:isExist() then
  
    -- Get target of missile.
    target=missile.weapon:getTarget()

    -- Get the target unit. Note if if _target is not nil, the unit can sometimes not be found!
    if target then    
      self:T2({missiletarget=target})
      
      -- Get target unit.
      targetUnit=UNIT:Find(target)
      
      if targetUnit then
        targetName=targetUnit:GetName()
        
        missile.targetUnit=targetUnit
        missile.targetPlayer=self:_GetPlayerFromUnit(missile.targetUnit)  
      end
      
    end
  end
  
  -- Missile got new target.
  if missile.targetName and missile.targetName~=targetName then
    self:I(self.lid..string.format("Missile %s(%s) changed target to %s. Previous target was %s.", missile.missileType, missile.missileName, targetName, missile.targetName))
  end
  
  -- Set target name.
  missile.targetName=targetName

end

--- FOX event handler for event shot (when a unit releases a rocket or bomb (but not a fast firing gun). 
-- @param #FOX self
-- @param Core.Event#EVENTDATA EventData
function FOX:OnEventShot(EventData)
  self:T2({eventshot=EventData})

  -- Nil checks.  
  if EventData.Weapon==nil or EventData.IniDCSUnit==nil or EventData.weapon==nil then
    return
  end
  
  -- Create a weapon object.
  local weapon=WEAPON:New(EventData.weapon)
  
  -- Weapon data.
  local _weapon     = weapon:GetTypeName()
  local _target     = EventData.Weapon:getTarget()
  local _targetName = "unknown"
  local _targetUnit = nil --Wrapper.Unit#UNIT
  
  -- Weapon descriptor.
  local desc=weapon.desc
  self:T2({desc=desc})
  
  -- Missile category: 1=AAM, 2=SAM, 6=OTHER
  local missilecategory=desc.missileCategory
  
  -- Missile range.
  local missilerange=nil
  if missilecategory then
    missilerange=desc.rangeMaxAltMax
  end
  
  -- Debug info.
  self:T2(FOX.lid.."EVENT SHOT: FOX")
  self:T2(FOX.lid..string.format("EVENT SHOT: Ini unit     = %s", tostring(EventData.IniUnitName)))
  self:T2(FOX.lid..string.format("EVENT SHOT: Ini group    = %s", tostring(EventData.IniGroupName)))
  self:T2(FOX.lid..string.format("EVENT SHOT: Weapon type  = %s", tostring(weapon:GetTypeName())))
  self:T2(FOX.lid..string.format("EVENT SHOT: Weapon categ = %s", tostring(weapon:GetCategory())))
  self:T2(FOX.lid..string.format("EVENT SHOT: Missil categ = %s", tostring(missilecategory)))
  self:T2(FOX.lid..string.format("EVENT SHOT: Missil range = %s", tostring(missilerange)))
  
  
  -- Check if fired in launch zone.
  if not self:_CheckCoordLaunch(EventData.IniUnit:GetCoordinate()) then
    self:T(self.lid.."Missile was not fired in launch zone. No tracking!")
    return
  end
  
  -- Track missiles of type AAM=1, SAM=2 or OTHER=6
  local _track = weapon:IsMissile() and missilecategory and (missilecategory==1 or missilecategory==2 or missilecategory==6)
  
  -- Only track missiles
  if _track then
  
    local missile={} --#FOX.MissileData
    
    missile.active=true
    missile.weapon=EventData.weapon
    missile.Weapon=weapon
    missile.missileType=_weapon
    missile.missileRange=missilerange
    missile.missileName=EventData.weapon:getName()
    missile.shooterUnit=EventData.IniUnit
    missile.shooterGroup=EventData.IniGroup
    missile.shooterCoalition=EventData.IniUnit:GetCoalition()
    missile.shooterName=EventData.IniUnitName
    missile.shotTime=timer.getAbsTime()
    missile.shotCoord=EventData.IniUnit:GetCoordinate()
    missile.fuseDist=desc.fuseDist
    missile.explosive=desc.warhead.explosiveMass or desc.warhead.shapedExplosiveMass
    missile.targetOrig=missile.targetName
    missile.missileCoord=COORDINATE:New(0,0,0)
    
    -- Set missile target name, unit and player.
    self:GetMissileTarget(missile)
    
    self:I(FOX.lid..string.format("EVENT SHOT: Shooter=%s %s(%s) ==> Target=%s, fuse dist=%s, explosive=%s",
    tostring(missile.shooterName), tostring(missile.missileType), tostring(missile.missileName), tostring(missile.targetName), tostring(missile.fuseDist), tostring(missile.explosive)))
    
    -- Only track if target was a player or target is protected. Saw the 9M311 missiles have no target!
    if missile.targetPlayer or self:_IsProtected(missile.targetUnit) or missile.targetName=="unknown" then
    
      -- Add missile table.
      table.insert(self.missiles, missile)
      
      -- Trigger MissileLaunch event.
      self:__MissileLaunch(0.1, missile)
      
    end
    
  end --if _track
  
end

--- FOX event handler for event hit.
-- @param #FOX self
-- @param Core.Event#EVENTDATA EventData
function FOX:OnEventHit(EventData)
  self:T({eventhit = EventData})
  
  -- Nil checks.
  if EventData.Weapon==nil then
    return
  end
  if EventData.IniUnit==nil then
    return
  end
  if EventData.TgtUnit==nil then
    return
  end
  
  local weapon=EventData.Weapon
  local weaponname=weapon:getName()
  
  for i,_missile in pairs(self.missiles) do
    local missile=_missile --#FOX.MissileData
    if missile.missileName==weaponname then
      self:I(self.lid..string.format("WARNING: Missile %s (%s) hit target %s. Missile trainer target was %s.", missile.missileType, missile.missileName, EventData.TgtUnitName, missile.targetName))
      self:I({missile=missile})
      return
    end
  end

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RADIO MENU Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add menu commands for player.
-- @param #FOX self
-- @param #string _unitName Name of player unit.
function FOX:_AddF10Commands(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check for player unit.
  if _unit and playername then

    -- Get group and ID.
    local group=_unit:GetGroup()
    local gid=group:GetID()
      
    if group and gid then
  
      if not self.menuadded[gid] then
      
        -- Enable switch so we don't do this twice.
        self.menuadded[gid]=true
        
        -- Set menu root path.
        local _rootPath=nil
        if FOX.MenuF10Root then
          ------------------------
          -- MISSON LEVEL MENUE --
          ------------------------          
           
          -- F10/FOX/...
          _rootPath=FOX.MenuF10Root
         
        else
          ------------------------
          -- GROUP LEVEL MENUES --
          ------------------------
          
          -- Main F10 menu: F10/FOX/
          if FOX.MenuF10[gid]==nil then
            FOX.MenuF10[gid]=missionCommands.addSubMenuForGroup(gid, "FOX")
          end
          
          -- F10/FOX/...
          _rootPath=FOX.MenuF10[gid]
          
        end
        
        
        --------------------------------        
        -- F10/F<X> FOX/F1 Help
        --------------------------------
        --local _helpPath=missionCommands.addSubMenuForGroup(gid, "Help", _rootPath)
        -- F10/FOX/F1 Help/
        --missionCommands.addCommandForGroup(gid, "Subtitles On/Off",    _helpPath, self._SubtitlesOnOff,      self, _unitName)   -- F7
        --missionCommands.addCommandForGroup(gid, "Trapsheet On/Off",    _helpPath, self._TrapsheetOnOff,      self, _unitName)   -- F8

        -------------------------
        -- F10/F<X> FOX/
        -------------------------
                
        missionCommands.addCommandForGroup(gid, "Destroy Missiles On/Off", _rootPath, self._ToggleDestroyMissiles, self, _unitName) -- F1
        missionCommands.addCommandForGroup(gid, "Launch Alerts On/Off",    _rootPath, self._ToggleLaunchAlert,     self, _unitName) -- F2
        missionCommands.addCommandForGroup(gid, "Mark Launch On/Off",      _rootPath, self._ToggleLaunchMark,      self, _unitName) -- F3
        missionCommands.addCommandForGroup(gid, "My Status",               _rootPath, self._MyStatus,              self, _unitName) -- F4
        
      end
    else
      self:E(self.lid..string.format("ERROR: Could not find group or group ID in AddF10Menu() function. Unit name: %s.", _unitName or "unknown"))
    end
  else
    self:E(self.lid..string.format("ERROR: Player unit does not exist in AddF10Menu() function. Unit name: %s.", _unitName or "unknown"))
  end

end


--- Turn player's launch alert on/off.
-- @param #FOX self
-- @param #string _unitname Name of the player unit.
function FOX:_MyStatus(_unitname)
  self:F2(_unitname)
  
  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Player data.  
    local playerData=self.players[playername]  --#FOX.PlayerData
    
    if playerData then
    
      local m,mtext=self:_GetTargetMissiles(playerData.name)
    
      local text=string.format("Status of player %s:\n", playerData.name)
      local safe=self:_CheckCoordSafe(playerData.unit:GetCoordinate())
      
      text=text..string.format("Destroy missiles? %s\n", tostring(playerData.destroy))
      text=text..string.format("Launch alert? %s\n", tostring(playerData.launchalert))
      text=text..string.format("Launch marks? %s\n", tostring(playerData.marklaunch))
      text=text..string.format("Am I safe? %s\n", tostring(safe))
      text=text..string.format("Missiles defeated: %d\n", playerData.defeated)
      text=text..string.format("Missiles destroyed: %d\n", playerData.dead)
      text=text..string.format("Me target: %d\n%s", m, mtext)
      
      MESSAGE:New(text, 10, nil, true):ToClient(playerData.client)
    
    end
  end
end

--- Turn player's launch alert on/off.
-- @param #FOX self
-- @param #string playername Name of the player.
-- @return #number Number of missiles targeting the player.
-- @return #string Missile info.
function FOX:_GetTargetMissiles(playername)

  local text=""
  local n=0
  for _,_missile in pairs(self.missiles) do
    local missile=_missile --#FOX.MissileData
    
    if missile.targetPlayer and missile.targetPlayer.name==playername then
      n=n+1
      text=text..string.format("Type %s: active %s\n", missile.missileType, tostring(missile.active))
    end
    
  end

  return n,text
end

--- Turn player's launch alert on/off.
-- @param #FOX self
-- @param #string _unitname Name of the player unit.
function FOX:_ToggleLaunchAlert(_unitname)
  self:F2(_unitname)
  
  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Player data.  
    local playerData=self.players[playername]  --#FOX.PlayerData
    
    if playerData then
    
      -- Invert state.
      playerData.launchalert=not playerData.launchalert
      
      -- Inform player.
      local text=""
      if playerData.launchalert==true then
        text=string.format("%s, missile launch alerts are now ENABLED.", playerData.name)
      else
        text=string.format("%s, missile launch alerts are now DISABLED.", playerData.name)
      end
      MESSAGE:New(text, 5):ToClient(playerData.client)
            
    end
  end
end

--- Turn player's launch marks on/off.
-- @param #FOX self
-- @param #string _unitname Name of the player unit.
function FOX:_ToggleLaunchMark(_unitname)
  self:F2(_unitname)
  
  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Player data.  
    local playerData=self.players[playername]  --#FOX.PlayerData
    
    if playerData then
    
      -- Invert state.
      playerData.marklaunch=not playerData.marklaunch
      
      -- Inform player.
      local text=""
      if playerData.marklaunch==true then
        text=string.format("%s, missile launch marks are now ENABLED.", playerData.name)
      else
        text=string.format("%s, missile launch marks are now DISABLED.", playerData.name)
      end
      MESSAGE:New(text, 5):ToClient(playerData.client)
            
    end
  end
end


--- Turn destruction of missiles on/off for player.
-- @param #FOX self
-- @param #string _unitname Name of the player unit.
function FOX:_ToggleDestroyMissiles(_unitname)
  self:F2(_unitname)
  
  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Player data.  
    local playerData=self.players[playername]  --#FOX.PlayerData
    
    if playerData then
    
      -- Invert state.
      playerData.destroy=not playerData.destroy
      
      -- Inform player.
      local text=""
      if playerData.destroy==true then
        text=string.format("%s, incoming missiles will be DESTROYED.", playerData.name)
      else
        text=string.format("%s, incoming missiles will NOT be DESTROYED.", playerData.name)
      end
      MESSAGE:New(text, 5):ToClient(playerData.client)
            
    end
  end
end


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get a random text message in case you die.
-- @param #FOX self
-- @return #string Text in case you die.
function FOX:_DeadText()

  local texts={}
  texts[1]="You're dead!"
  texts[2]="Meet your maker!"
  texts[3]="Time to meet your maker!"
  texts[4]="Well, I guess that was it!"
  texts[5]="Bye, bye!"
  texts[6]="Cheers buddy, was nice knowing you!"
  
  local r=math.random(#texts)
  
  return texts[r]
end


--- Check if a coordinate lies within a safe training zone.
-- @param #FOX self
-- @param Core.Point#COORDINATE coord Coordinate to check. Can also be a DCS#Vec3.
-- @return #boolean True if safe.
function FOX:_CheckCoordSafe(coord)

  -- No safe zones defined ==> Everything is safe.
  if #self.safezones==0 then
    return true    
  end
  
  -- Loop over all zones.
  for _,_zone in pairs(self.safezones) do
    local zone=_zone --Core.Zone#ZONE
    local Vec2={x=coord.x, y=coord.z}
    local inzone=zone:IsVec2InZone(Vec2)
    --local inzone=zone:IsCoordinateInZone(coord)
    if inzone then
      return true
    end
  end

  return false
end

--- Check if a coordinate lies within a launch zone.
-- @param #FOX self
-- @param Core.Point#COORDINATE coord Coordinate to check. Can also be a DCS#Vec2.
-- @return #boolean True if in launch zone.
function FOX:_CheckCoordLaunch(coord)

  -- No safe zones defined ==> Everything is safe.
  if #self.launchzones==0 then
    return true    
  end
  
  -- Loop over all zones.
  for _,_zone in pairs(self.launchzones) do
    local zone=_zone --Core.Zone#ZONE
    local Vec2={x=coord.x, y=coord.z}
    local inzone=zone:IsVec2InZone(Vec2)
    --local inzone=zone:IsCoordinateInZone(coord)
    if inzone then
      return true
    end
  end

  return false
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #FOX self
-- @param DCS#Weapon weapon The weapon.
-- @return #number Heading of weapon in degrees or -1.
function FOX:_GetWeapongHeading(weapon)

  if weapon and weapon:isExist() then
  
    local wp=weapon:getPosition()
  
    local wph = math.atan2(wp.x.z, wp.x.x)
    
    if wph < 0 then
      wph=wph+2*math.pi
    end
    
    wph=math.deg(wph)
    
    return wph
  end

  return -1
end

--- Tell player notching headings. 
-- @param #FOX self
-- @param #FOX.PlayerData playerData Player data.
-- @param DCS#Weapon weapon The weapon.
function FOX:_SayNotchingHeadings(playerData, weapon)

  if playerData and playerData.unit and playerData.unit:IsAlive() then
  
    local nr, nl=self:_GetNotchingHeadings(weapon)
    
    if nr and nl then
      local text=string.format("Notching heading %03d° or %03d°", nr, nl)    
      MESSAGE:New(text, 5, "FOX"):ToClient(playerData.client)
    end
  
  end

end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #FOX self
-- @param DCS#Weapon weapon The weapon.
-- @return #number Notching heading right, i.e. missile heading +90°.
-- @return #number Notching heading left, i.e. missile heading -90°.
function FOX:_GetNotchingHeadings(weapon)

  if weapon then
  
    local hdg=self:_GetWeapongHeading(weapon)
    
    local hdg1=hdg+90
    if hdg1>360 then
      hdg1=hdg1-360
    end
    
    local hdg2=hdg-90
    if hdg2<0 then
      hdg2=hdg2+360
    end
  
    return hdg1, hdg2
  end  
  
  return nil, nil
end

--- Returns the player data from a unit name.
-- @param #FOX self
-- @param #string unitName Name of the unit.
-- @return #FOX.PlayerData Player data.
function FOX:_GetPlayerFromUnitname(unitName)

  for _,_player in pairs(self.players) do  
    local player=_player --#FOX.PlayerData
    
    if player.unitname==unitName then
      return player
    end
  end
  
  return nil
end

--- Retruns the player data from a unit.
-- @param #FOX self
-- @param Wrapper.Unit#UNIT unit
-- @return #FOX.PlayerData Player data.
function FOX:_GetPlayerFromUnit(unit)

  if unit and unit:IsAlive() then

    -- Name of the unit
    local unitname=unit:GetName()

    for _,_player in pairs(self.players) do  
      local player=_player --#FOX.PlayerData
      
      if player.unitname==unitname then
        return player
      end
    end

  end
  
  return nil
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #FOX self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function FOX:_GetPlayerUnitAndName(_unitName)
  self:F2(_unitName)

  if _unitName ~= nil then
    
    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)
    
    if DCSunit then
    
      -- Get player name if any.
      local playername=DCSunit:getPlayerName()
      
      -- Unit object.
      local unit=UNIT:Find(DCSunit)
    
      -- Debug.
      self:T2({DCSunit=DCSunit, unit=unit, playername=playername})
      
      -- Check if enverything is there.
      if DCSunit and unit and playername then
        self:T(self.lid..string.format("Found DCS unit %s with player %s.", tostring(_unitName), tostring(playername)))
        return unit, playername
      end
      
    end
    
  end
  
  -- Return nil if we could not find a player.
  return nil,nil
end


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------