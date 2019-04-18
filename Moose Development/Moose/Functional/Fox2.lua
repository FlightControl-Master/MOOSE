--- **Functional** - (R2.5) - Yet another missile trainer.
-- 
-- 
-- Train to evade missiles without being destroyed.
-- 
--
-- **Main Features:**
--
--     * Adaptive update of missile-to-player distance.
--     * F10 radio menu.
--     * Easy to use.
--     * Handles air-to-air and surface-to-air missiles.
--     * Alert on missile launch (optional).
--     * Marker of missile launch position (optional).
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Functional.FOX2
-- @image Functional_FOX2.png


--- FOX2 class.
-- @type FOX2
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table menuadded Table of groups the menu was added for.
-- @field #table players Table of players.
-- @field #table missiles Table of tracked missiles.
-- @field #table safezones Table of practice zones.
-- @field #table launchzones Table of launch zones.
-- @field Core.Set#SET_GROUP protectedset Set of protected groups.
-- @field #number explosionpower Power of explostion when destroying the missile in kg TNT. Default 5 kg TNT.
-- @field #number explosiondist Missile player distance in meters for destroying the missile. Default 100 m.
-- @extends Core.Fsm#FSM

--- Fox 2!
--
-- ===
--
-- ![Banner Image](..\Presentations\FOX2\FOX2_Main.png)
--
-- # The FOX2 Concept
-- 
-- 
-- 
-- @field #FOX2
FOX2 = {
  ClassName      = "FOX2",
  Debug          = false,
  lid            =   nil,
  menuadded      =    {},
  missiles       =    {},
  players        =    {},
  safezones      =    {},
  launchzones    =    {},
  protectedset   =   nil,
  explosionpower =     5,
  explosiondist  =   100,
  destroy        =   nil,
}


--- Player data table holding all important parameters of each player.
-- @type FOX2.PlayerData
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

--- Missile data table.
-- @type FOX2.MissileData
-- @field #boolean active If true the missile is active.
-- @field #string missileType Type of missile.
-- @field #number missileRange Range of missile in meters.
-- @field Wrapper.Unit#UNIT shooterUnit Unit that shot the missile.
-- @field Wrapper.Group#GROUP shooterGroup Group that shot the missile.
-- @field #number shooterCoalition Coalition side of the shooter.
-- @field #string shooterName Name of the shooter unit.
-- @field #number shotTime Abs mission time in seconds the missile was fired.
-- @field Core.Point#COORDINATE shotCoord Coordinate where the missile was fired.
-- @field Wrapper.Unit#UNIT targetUnit Unit that was targeted.
-- @field #FOX2.PlayerData targetPlayer Player that was targeted or nil.

--- Main radio menu on group level.
-- @field #table MenuF10 Root menu table on group level.
FOX2.MenuF10={}

--- Main radio menu on mission level.
-- @field #table MenuF10Root Root menu on mission level.
FOX2.MenuF10Root=nil

--- FOX2 class version.
-- @field #string version
FOX2.version="0.1.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO list:
-- TODO: safe zones
-- TODO: mark shooter on F10

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FOX2 class object.
-- @param #FOX2 self
-- @return #FOX2 self.
function FOX2:New()

  self.lid="FOX2 | "

  -- Inherit everthing from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #FOX2
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start FOX2 script.
  self:AddTransition("*",             "Status",          "*")           -- Start FOX2 script.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the FOX2. Initializes parameters and starts event handlers.
  -- @function [parent=#FOX2] Start
  -- @param #FOX2 self

  --- Triggers the FSM event "Start" after a delay. Starts the FOX2. Initializes parameters and starts event handlers.
  -- @function [parent=#FOX2] __Start
  -- @param #FOX2 self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the FOX2 and all its event handlers.
  -- @param #FOX2 self

  --- Triggers the FSM event "Stop" after a delay. Stops the FOX2 and all its event handlers.
  -- @function [parent=#FOX2] __Stop
  -- @param #FOX2 self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#FOX2] Status
  -- @param #FOX2 self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#FOX2] __Status
  -- @param #FOX2 self
  -- @param #number delay Delay in seconds.
  
  return self
end

--- On after Start event. Starts the missile trainer and adds event handlers.
-- @param #FOX2 self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FOX2:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting FOX2 Missile Trainer %s", FOX2.version)
  env.info(text)

  -- Handle events:
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.Shot)
  
  self:TraceClass(self.ClassName)
  self:TraceLevel(2)

  self:__Status(-1)
end

--- On after Stop event. Stops the missile trainer and unhandles events.
-- @param #FOX2 self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FOX2:onafterStop(From, Event, To)

  -- Short info.
  local text=string.format("Stopping FOX2 Missile Trainer v0.0.1")
  env.info(text)

  -- Handle events:
  self:UnhandleEvent(EVENTS.Birth)
  self:UnhandleEvent(EVENTS.Shot)

end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a training zone. Players in the zone are safe.
-- @param #FOX2 self
-- @param Core.Zone#ZONE zone Training zone.
function FOX2:AddSafeZone(zone)

  table.insert(self.safezones, zone)

end

--- Add a launch zone. Only missiles launched within these zones will be tracked.
-- @param #FOX2 self
-- @param Core.Zone#ZONE zone Training zone.
function FOX2:AddLaunchZone(zone)

  table.insert(self.safezones, zone)

end


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status Functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check spawn queue and spawn aircraft if necessary.
-- @param #FOX2 self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FOX2:onafterStatus(From, Event, To)

  self:I(self.lid..string.format("Missile trainer status: %s", self.GetState()))
  
  self:_CheckMissileStatus()

  self:__Status(-30)
end

--- Missile status 
-- @param #FOX2 self
function FOX2:_CheckMissileStatus()

  local text="Missiles:"
  for i,_missile in pairs(self.missiles) do
    local missile=_missile --#FOX2.MissileData
    
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
    local range=UTILS.MetersToNM(missile.missileRange)
    
    text=text..string.format("\n%d: active=%s, type=%d, range=%.1f NM, target=%s, player=%s, missilename=%s", i, active, mtype, range, targetname, playername)
    
  end
  self:T(self.lid..text)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- FOX2 event handler for event birth.
-- @param #FOX2 self
-- @param Core.Event#EVENTDATA EventData
function FOX2:OnEventBirth(EventData)
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
            
    -- Add Menu commands.
    self:_AddF10Commands(_unitName)
    
    -- Player data.
    local playerData={} --#FOX2.PlayerData
    
    -- Player unit, client and callsign.
    playerData.unit      = playerunit
    playerData.unitname  = _unitName
    playerData.group     = _group
    playerData.groupname = _group:GetName()
    playerData.name      = playername
    playerData.callsign  = playerData.unit:GetCallsign()
    playerData.client    = CLIENT:FindByName(_unitName, nil, true)
    playerData.coalition = _group:GetCoalition()
    
    playerData.destroy=playerData.destroy or true
    playerData.launchalert=playerData.launchalert or true
    playerData.marklaunch=playerData.marklaunch or true
    
    playerData.defeated=playerData.defeated or 0
    playerData.dead=playerData.dead or 0
    
    -- Init player data.
    self.players[playername]=playerData
      
    -- Init player grades table if necessary.
    --self.playerscores[playername]=self.playerscores[playername] or {}    
    
  end 
end

--- FOX2 event handler for event shot (when a unit releases a rocket or bomb (but not a fast firing gun). 
-- @param #FOX2 self
-- @param Core.Event#EVENTDATA EventData
function FOX2:OnEventShot(EventData)
  self:I({eventshot = EventData})
  
  if EventData.Weapon==nil then
    return
  end
  if EventData.IniDCSUnit==nil then
    return
  end
  
  -- Weapon data.
  local _weapon     = EventData.WeaponName
  local _target     = EventData.Weapon:getTarget()
  local _targetName = "unknown"
  local _targetUnit = nil --Wrapper.Unit#UNIT
  
  -- Weapon descriptor.
  local desc=EventData.Weapon:getDesc()
  self:E({desc=desc})
  
  -- Weapon category: 0=Shell, 1=Missile, 2=Rocket, 3=BOMB
  local weaponcategory=desc.category
  
  -- Missile category: 1=AAM, 2=SAM, 6=OTHER
  local missilecategory=desc.missileCategory
  
  local missilerange=nil
  if missilecategory then
    missilerange=desc.rangeMaxAltMax
  end
  
  -- Debug info.
  self:E(FOX2.lid.."EVENT SHOT: FOX2")
  self:E(FOX2.lid..string.format("EVENT SHOT: Ini unit     = %s", tostring(EventData.IniUnitName)))
  self:E(FOX2.lid..string.format("EVENT SHOT: Ini group    = %s", tostring(EventData.IniGroupName)))
  self:E(FOX2.lid..string.format("EVENT SHOT: Weapon type  = %s", tostring(_weapon)))
  self:E(FOX2.lid..string.format("EVENT SHOT: Weapon categ = %s", tostring(weaponcategory)))
  self:E(FOX2.lid..string.format("EVENT SHOT: Missil categ = %s", tostring(missilecategory)))
  self:E(FOX2.lid..string.format("EVENT SHOT: Missil range = %s", tostring(missilerange)))
  
  
  -- Check if fired in launch zone.
  if not self:_CheckCoordLaunch(EventData.IniUnit:GetCoordinate()) then
    self:T(self.lid.."Missile was not fired in launch zone. No tracking!")
    return
  end
  
  -- Get the target unit. Note if if _target is not nil, the unit can sometimes not be found!
  if _target then
    self:E({target=_target})
    --_targetName=Unit.getName(_target)
    --_targetUnit=UNIT:FindByName(_targetName)
    _targetUnit=UNIT:Find(_target)
  end
  self:E(FOX2.lid..string.format("EVENT SHOT: Target name = %s", tostring(_targetName)))
    
  -- Track missiles of type AAM=1, SAM=2 or OTHER=6
  local _track = weaponcategory==1 and missilecategory and (missilecategory==1 or missilecategory==2 or missilecategory==6)
    
  -- Get shooter.
  --local shooterUnit = EventData.IniUnit
 -- local shooterName = EventData.IniUnitName
 -- local shooterCoalition=shooterUnit:GetCoalition()
 -- local shooterCoord=shooterUnit:GetCoordinate()

  -- Only track missiles
  if _track then
  
    local missile={} --#FOX2.MissileData
    
    missile.active=true
    missile.missileType=_weapon
    missile.missileRange=missilerange
    missile.missileName=EventData.weapon:getName()
    missile.shooterUnit=EventData.IniUnit
    missile.shooterGroup=EventData.IniGroup
    missile.shooterCoalition=EventData.IniUnit:GetCoalition()
    missile.shooterName=EventData.IniUnitName
    missile.shotTime=timer.getAbsTime()
    missile.shotCoord=EventData.IniUnit:GetCoordinate()
    missile.targetUnit=_targetUnit
    missile.targetPlayer=self:_GetPlayerFromUnit(missile.targetUnit)
    
    -- Add missile table.
    table.insert(self.missiles, missile)
    
    
    -- Tracking info and init of last bomb position.
    self:I(FOX2.lid..string.format("FOX2: Tracking %s - %s.", missile.missileType, missile.missileName))
    
    -- Loop over players.
    for _,_player in pairs(self.players) do
      local player=_player  --#FOX2.PlayerData
      
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
            
            --TODO: ALERT or INFO depending on wether this is a direct target.
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
    
    -- Init missile position.
    local _lastBombPos = {x=0,y=0,z=0}
    
    -- Missile coordinate.
    local missileCoord = nil --Core.Point#COORDINATE
    
    -- Target unit of the missile.
    local target=nil --Wrapper.Unit#UNIT
        
    --- Function monitoring the position of a bomb until impact.
    local function trackMissile(_ordnance)

      -- When the pcall returns a failure the weapon has hit.
      local _status,_bombPos =  pcall(
      function()
        return _ordnance:getPoint()
      end)

      -- Check if status is not nil. If so, we have a valid point.
      if _status then
      
        ----------------------------------------------
        -- Still in the air. Remember this position --
        ----------------------------------------------
        
        -- Missile position.
        _lastBombPos = {x=_bombPos.x, y=_bombPos.y, z=_bombPos.z}
        
        -- Missile coordinate.
        missileCoord=COORDINATE:NewFromVec3(_lastBombPos)
        
        -- Missile velocity in m/s.
        local missileVelocity=UTILS.VecNorm(_ordnance:getVelocity())
        
        if missile.targetUnit then
          -----------------------------------
          -- Missile has a specific target --
          -----------------------------------
        
          if missile.targetPlayer then
            -- Target is a player.
            target=missile.targetUnit
          else
            --TODO: Check if unit is protected.
          end
          
        else
        
          ------------------------------------
          -- Missile has NO specific target --
          ------------------------------------       
          
          -- Distance to closest player.
          local mindist=nil
          
          -- Loop over players.
          for _,_player in pairs(self.players) do
            local player=_player  --#FOX2.PlayerData
            
            -- Player position.
            local playerCoord=player.unit:GetCoordinate()
            
            -- Distance.            
            local dist=missileCoord:Get3DDistance(playerCoord)
            
            -- Maxrange from launch point to player.
            local maxrange=playerCoord:Get3DDistance(missile.shotCoord)
            
            -- Update mindist if necessary. Only include players in range of missile.
            if (mindist==nil or dist<mindist) and dist<=maxrange then
              mindist=dist
              target=player.unit
            end            
          end
          
        end

        -- Check if missile has a valid target.
        if target then
        
          -- Target coordinate.
          local targetCoord=target:GetCoordinate()
        
          -- Distance from missile to target.
          local distance=missileCoord:Get3DDistance(targetCoord)
          
          local bearing=targetCoord:HeadingTo(missileCoord)
          local eta=distance/missileVelocity
          
          self:T2(self.lid..string.format("Distance = %.1f m, v=%.1f m/s, bearing=%03d°, eta=%.1f sec", distance, missileVelocity, bearing, eta))
        
          -- If missile is 100 m from target ==> destroy missile if in safe zone.
          if distance<self.explosiondist and self:_CheckCoordSafe(targetCoord)then
          
            -- Destroy missile.
            self:T(self.lid..string.format("Destroying missile at distance %.1f m", distance))
            _ordnance:destroy()
            
            -- Little explosion for the visual effect.
            missileCoord:Explosion(self.explosionpower)
            
            local text="Destroying missile. You're dead!"
            MESSAGE:New(text, 10):ToGroup(target:GetGroup())
            
            -- Terminate timer.
            return nil
          else
          
            -- Time step.
            local dt=1.0          
            if distance>50000 then
              -- > 50 km
              dt=5.0
            elseif distance>10000 then
              -- 10-50 km
              dt=1.0
            elseif distance>5000 then
              -- 5-10 km
              dt=0.5
            elseif distance>1000 then
              -- 1-5 km
              dt=0.1
            else
              -- < 1 km
              dt=0.01
            end
          
            -- Check again in dt seconds.
            return timer.getTime()+dt
          end
        else
        
          -- No target ==> terminate timer.
          return nil
        end
        
      else
      
        -------------------------------------
        -- Missile does not exist any more --
        -------------------------------------
              
        if target then  
        
          -- Get human player.
          local player=self:_GetPlayerFromUnit(target)
          
          -- Check for player and distance < 10 km.
          if player and player.unit:IsAlive() then -- and missileCoord and player.unit:GetCoordinate():Get3DDistance(missileCoord)<10*1000 then
            local text=string.format("Missile defeated. Well done, %s!", player.name)
            MESSAGE:New(text, 10):ToClient(player.client)
          end
          
        end
        
        -- Missile is not active any more.
        missile.active=false   
                
        --Terminate the timer.
        self:T(FOX2.lid..string.format("Terminating missile track timer."))
        return nil

      end -- _status check
      
    end -- end function trackBomb

    -- Weapon is not yet "alife" just yet. Start timer with a little delay.
    self:T(FOX2.lid..string.format("Tracking of missile starts in 0.1 seconds."))
    timer.scheduleFunction(trackMissile, EventData.weapon, timer.getTime()+0.1)
    
  end --if _track
  
end


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RADIO MENU Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add menu commands for player.
-- @param #FOX2 self
-- @param #string _unitName Name of player unit.
function FOX2:_AddF10Commands(_unitName)
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
        if FOX2.MenuF10Root then
          ------------------------
          -- MISSON LEVEL MENUE --
          ------------------------          
           
          -- F10/FOX2/...
          _rootPath=FOX2.MenuF10Root
         
        else
          ------------------------
          -- GROUP LEVEL MENUES --
          ------------------------
          
          -- Main F10 menu: F10/FOX2/
          if FOX2.MenuF10[gid]==nil then
            FOX2.MenuF10[gid]=missionCommands.addSubMenuForGroup(gid, "FOX2")
          end
          
          -- F10/FOX2/...
          _rootPath=FOX2.MenuF10[gid]
          
        end
        
        
        --------------------------------        
        -- F10/F<X> FOX2/F1 Help
        --------------------------------
        local _helpPath=missionCommands.addSubMenuForGroup(gid, "Help", _rootPath)
        -- F10/FOX2/F1 Help/
        --missionCommands.addCommandForGroup(gid, "Subtitles On/Off",    _helpPath, self._SubtitlesOnOff,      self, _unitName)   -- F7
        --missionCommands.addCommandForGroup(gid, "Trapsheet On/Off",    _helpPath, self._TrapsheetOnOff,      self, _unitName)   -- F8

        -------------------------
        -- F10/F<X> FOX2/
        -------------------------
        
        missionCommands.addCommandForGroup(gid, "Launch Alerts On/Off",    _rootPath, self._ToggleLaunchAlert,     self, _unitName) -- F2
        missionCommands.addCommandForGroup(gid, "Destroy Missiles On/Off", _rootPath, self._ToggleDestroyMissiles, self, _unitName) -- F3
        
      end
    else
      self:E(self.lid..string.format("ERROR: Could not find group or group ID in AddF10Menu() function. Unit name: %s.", _unitName))
    end
  else
    self:E(self.lid..string.format("ERROR: Player unit does not exist in AddF10Menu() function. Unit name: %s.", _unitName))
  end

end


--- Turn player's launch alert on/off.
-- @param #FOX2 self
-- @param #string _unitname Name of the player unit.
function FOX2:_ToggleLaunchAlert(_unitname)
  self:F2(_unitname)
  
  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Player data.  
    local playerData=self.players[playername]  --#FOX2.PlayerData
    
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

--- Turn player's 
-- @param #FOX2 self
-- @param #string _unitname Name of the player unit.
function FOX2:_ToggleDestroyMissiles(_unitname)
  self:F2(_unitname)
  
  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Player data.  
    local playerData=self.players[playername]  --#FOX2.PlayerData
    
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

--- Check if a coordinate lies within a safe training zone.
-- @param #FOX2 self
-- @param Core.Point#COORDINATE coord Coordinate to check.
-- @return #boolean
function FOX2:_CheckCoordSafe(coord)

  -- No safe zones defined ==> Everything is safe.
  if #self.safezones==0 then
    return true    
  end
  
  -- Loop over all zones.
  for _,_zone in pairs(self.safezones) do
    local zone=_zone --Core.Zone#ZONE
    local inzone=zone:IsCoordinateInZone(coord)
    if inzone then
      return true
    end
  end

  return false
end

--- Check if a coordinate lies within a launch zone.
-- @param #FOX2 self
-- @param Core.Point#COORDINATE coord Coordinate to check.
-- @return #boolean
function FOX2:_CheckCoordLaunch(coord)

  -- No safe zones defined ==> Everything is safe.
  if #self.launchzones==0 then
    return true    
  end
  
  -- Loop over all zones.
  for _,_zone in pairs(self.launchzones) do
    local zone=_zone --Core.Zone#ZONE
    local inzone=zone:IsCoordinateInZone(coord)
    if inzone then
      return true
    end
  end

  return false
end


--- Returns the player data from a unit name.
-- @param #FOX2 self
-- @param #string unitName Name of the unit.
-- @return #FOX2.PlayerData Player data.
function FOX2:_GetPlayerFromUnitname(unitName)

  for _,_player in pairs(self.players) do  
    local player=_player --#FOX2.PlayerData
    
    if player.unitname==unitName then
      return player
    end
  end
  
  return nil
end

--- Retruns the player data from a unit.
-- @param #FOX2 self
-- @param Wrapper.Unit#UNIT unit
-- @return #FOX2.PlayerData Player data.
function FOX2:_GetPlayerFromUnit(unit)

  if unit and unit:IsAlive() then

    -- Name of the unit
    local unitname=unit:GetName()

    for _,_player in pairs(self.players) do  
      local player=_player --#FOX2.PlayerData
      
      if player.unitname==unitname then
        return player
      end
    end

  end
  
  return nil
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #FOX2 self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function FOX2:_GetPlayerUnitAndName(_unitName)
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
