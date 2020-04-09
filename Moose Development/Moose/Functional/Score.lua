--- **Functional** - (R2.5) - Simple and Persistent Player Scoring.
-- 
-- 
-- Score!
-- 
--
-- ## Main Features:
-- 
--    * Good stuff.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Functional.SimpleScore
-- @image Functional_SimpleScore.png


--- SCORE class.
-- @type SCORE
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table menuadded Table of groups the menu was added for.
-- @field #boolean menudisabled If true, F10 menu for players is disabled.
-- @field #table playerscores Player score table.
-- @extends Core.Fsm#FSM

--- Goooooaaaallllll!
--
-- ===
--
-- ![Banner Image](..\Presentations\SCORE\SCORE_Main.png)
--
-- # The Scoring Concept
-- 
-- Score
-- 
-- # Basic Script
-- 
--     -- Create a new score object.
--     score=SCORE:New()
--     
--     -- Start score.
--     SCORE:Start()
-- 
-- # Training Zones
-- 
-- Players are only protected if they are inside one of the training zones.
-- 
--     -- Create a new missile trainer object.
--     SCORE=SCORE:New()
--     
--     -- Add training zones.
--     SCORE:AddSafeZone(ZONE:New("Training Zone Alpha")
--     SCORE:AddSafeZone(ZONE:New("Training Zone Bravo")
--     
--     -- Start missile trainer.
--     SCORE:Start()
-- 
-- 
-- Todo!
-- 
-- 
-- @field #SCORE
SCORE = {
  ClassName      = "SCORE",
  Debug          = false,
  lid            =   nil,
  menuadded      =    {},
  menudisabled   =   nil,
  playerscores   =   nil,
}


--- Player data table holding all important parameters of each player.
-- @type SCORE.PlayerData
-- @field Wrapper.Unit#UNIT unit Aircraft of the player.
-- @field #string unitname Name of the unit.
-- @field Wrapper.Client#CLIENT client Client object of player.
-- @field #string callsign Callsign of player.
-- @field Wrapper.Group#GROUP group Aircraft group of player.
-- @field #string groupname Name of the the player aircraft group.
-- @field #string name Player name.
-- @field #number coalition Coalition number of player.
-- @field #table hit Table of hit units.

--- Hit unit data.
-- @type SCORE.HitData
-- @field #string unitname Name of the hit unit.
-- @field #string category Category of hit unit.
-- @field #number score Score
-- @field #boolean friendly If true, unit is friendly.
-- @field #boolean destroyed If true, unit was destroyed.



--- Create a new SCORE class object.
-- @param #SCORE self
-- @return #SCORE self.
function SCORE:New()

  self.lid="SCORE | "

  -- Inherit everthing from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #SCORE
  
  -- Defaults:
  self:SetDefaultMissileDestruction(true)
  self:SetDefaultLaunchAlerts(true)
  self:SetDefaultLaunchMarks(true)
  self:SetExplosionPower()
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State   -->   Event        -->     To State
  self:AddTransition("Stopped",           "Start",          "Running")     -- Start SCORE script.
  self:AddTransition("*",                "Status",          "*")           -- Status update.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the SCORE. Initializes parameters and starts event handlers.
  -- @function [parent=#SCORE] Start
  -- @param #SCORE self

  --- Triggers the FSM event "Start" after a delay. Starts the SCORE. Initializes parameters and starts event handlers.
  -- @function [parent=#SCORE] __Start
  -- @param #SCORE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the SCORE and all its event handlers.
  -- @param #SCORE self

  --- Triggers the FSM event "Stop" after a delay. Stops the SCORE and all its event handlers.
  -- @function [parent=#SCORE] __Stop
  -- @param #SCORE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#SCORE] Status
  -- @param #SCORE self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#SCORE] __Status
  -- @param #SCORE self
  -- @param #number delay Delay in seconds.

  return self
end


--- On after Start event. Starts the missile trainer and adds event handlers.
-- @param #SCORE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SCORE:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting SCORE v%s", SCORE.version)
  env.info(text)
  
  -- Init player scores table.
  self.playerscores={}  

  -- Event handlers  
  self:HandleEvent(EVENTS.Dead,  self._EventDeadOrCrash)
  self:HandleEvent(EVENTS.Crash, self._EventDeadOrCrash)
  self:HandleEvent(EVENTS.Hit,   self._EventHit)
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.PlayerLeaveUnit)

  -- Handle events:
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.Shot)
  
  if self.Debug then
    self:TraceClass(self.ClassName)
    self:TraceLevel(2)
  end
  
  self:__Status(-10)
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- SCORE event handler for event birth.
-- @param #SCORE self
-- @param Core.Event#EVENTDATA EventData
function SCORE:OnEventBirth(EventData)
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
      SCHEDULER:New(nil, self._AddF10Commands, {self,_unitName}, 0.1)
    end
    
    -- Player data.
    local playerData={} --#SCORE.PlayerData
    
    -- Player unit, client and callsign.
    playerData.unit      = playerunit
    playerData.unitname  = _unitName
    playerData.group     = _group
    playerData.groupname = _group:GetName()
    playerData.name      = playername
    playerData.callsign  = playerData.unit:GetCallsign()
    playerData.client    = CLIENT:FindByName(_unitName, nil, true)
    playerData.coalition = _group:GetCoalition()
        
    playerData.hit       = playerData.hit or {}
    
    -- Init player data.
    self.players[playername]=playerData
    
  end 
end


--- Handles the OnHit event for the scoring.
-- @param #SCORE self
-- @param Core.Event#EVENTDATA Event
function SCORE:_EventOnHit(Event)
  self:F( { Event } )

  local InitUnit = nil
  local InitUNIT = nil
  local InitUnitName = ""
  local InitGroup = nil
  local InitGroupName = ""
  local InitPlayerName = nil

  local InitCoalition = nil
  local InitCategory = nil
  local InitType = nil
  local InitUnitCoalition = nil
  local InitUnitCategory = nil
  local InitUnitType = nil

  local TargetUnit = nil
  local TargetUNIT = nil
  local TargetUnitName = ""
  local TargetGroup = nil
  local TargetGroupName = ""
  local TargetPlayerName = nil

  local TargetCoalition = nil
  local TargetCategory = nil
  local TargetType = nil
  local TargetUnitCoalition = nil
  local TargetUnitCategory = nil
  local TargetUnitType = nil

  if Event.IniDCSUnit then

    InitUnit = Event.IniDCSUnit
    InitUNIT = Event.IniUnit
    InitUnitName = Event.IniDCSUnitName
    InitGroup = Event.IniDCSGroup
    InitGroupName = Event.IniDCSGroupName
    InitPlayerName = Event.IniPlayerName

    InitCoalition = Event.IniCoalition
    InitCategory = Event.IniCategory
    InitType = Event.IniTypeName

    InitUnitCoalition = _SCORINGCoalition[InitCoalition]
    InitUnitCategory = _SCORINGCategory[InitCategory]
    InitUnitType = InitType

    self:T( { InitUnitName, InitGroupName, InitPlayerName, InitCoalition, InitCategory, InitType , InitUnitCoalition, InitUnitCategory, InitUnitType } )
  end


  if Event.TgtDCSUnit then

    TargetUnit = Event.TgtDCSUnit
    TargetUNIT = Event.TgtUnit
    TargetUnitName = Event.TgtDCSUnitName
    TargetGroup = Event.TgtDCSGroup
    TargetGroupName = Event.TgtDCSGroupName
    TargetPlayerName = Event.TgtPlayerName

    TargetCoalition = Event.TgtCoalition
    TargetCategory = Event.TgtCategory
    TargetType = Event.TgtTypeName

    TargetUnitCoalition = _SCORINGCoalition[TargetCoalition]
    TargetUnitCategory = _SCORINGCategory[TargetCategory]
    TargetUnitType = TargetType
    
  end
  
  -- Current time.
  local Tnow=timer.getTime()

  if InitPlayerName~=nil then -- It is a player that is hitting something
  
    self:T("Hitting Something")
    
    -- What is he hitting?
    if TargetCategory then

      -- A target got hit, score it.
      -- Player contains the score data from self.Players[InitPlayerName]
      local player=self.Players[InitPlayerName]  --#SCORE.PlayerData
      
      -- Hit table.
      player.hit[TargetUnitName]=player.hit[TargetUnitName] or {}
      
      local hit=player.hit[TargetUnitName] --#SCORE.HitData
       
      hit.score = hit.score or 0
      hit.penalty = hit.penalty or 0
      hit.timeStamp = hit.timeStamp or 0
      hit.unit = hit.unit or TargetUNIT
      hit.threatLevel, hit.threatType = hit.unit:GetThreatLevel()

      -- Only grant hit scores if there was more than one second between the last hit.        
      if Tnow-hit.timeStamp>1 then
      
        -- Update timestamp
        hit.timeStamp = Tnow
      
        if TargetPlayerName~=nil then 
          -- It is a player hitting another player ...
          hit.otherplayer=true
        end
        
        local Score = 0
        
        if InitCoalition then -- A coalition object was hit.
          if InitCoalition == TargetCoalition then
          
            ------------------
            -- Hit Friendly --
            ------------------
           
            hit.friendly=true
            
            player.penalty = player.penalty-10
            hit.penalty=hit.penalty-10
            
            -- Check if target was another player.
            if TargetPlayerName~=nil then -- It is a player hitting another player ...

            else
            
            end
            
            -- Write penalty to CSV file.
            --self:ScoreCSV( InitPlayerName, TargetPlayerName, "HIT_PENALTY", 1, -10, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
            
          else
          
            ----------------
            -- Hit Enemey --
            ----------------
          
            hit.friendly=true
          
            player.score=player.score+1
            hit.score=hit.score+1
            
            --hit.scoreHit = hit.ScoreHit + 1
            
            -- Check if it was a player.
            if TargetPlayerName~=nil then -- It is a player hitting another player ...
            
            else
            
            end
            
            -- Write score to CSV file. Score 1 PT.
            
          end
          
        else -- A scenery object was hit.
        
        
        end
        
      end
    end
  end
  
end

--- Track  DEAD or CRASH events for the scoring.
-- @param #SCORING self
-- @param Core.Event#EVENTDATA Event
function SCORING:_EventOnDeadOrCrash( Event )
  self:F( { Event } )

  local TargetUnit = nil
  local TargetGroup = nil
  local TargetUnitName = ""
  local TargetGroupName = ""
  local TargetPlayerName = ""
  local TargetCoalition = nil
  local TargetCategory = nil
  local TargetType = nil
  local TargetUnitCoalition = nil
  local TargetUnitCategory = nil
  local TargetUnitType = nil

  if Event.IniDCSUnit then

    TargetUnit = Event.IniUnit
    TargetUnitName = Event.IniDCSUnitName
    TargetGroup = Event.IniDCSGroup
    TargetGroupName = Event.IniDCSGroupName
    TargetPlayerName = Event.IniPlayerName

    TargetCoalition = Event.IniCoalition
    TargetCategory = Event.IniCategory
    TargetType = Event.IniTypeName

    TargetUnitCoalition = _SCORINGCoalition[TargetCoalition]
    TargetUnitCategory = _SCORINGCategory[TargetCategory]
    TargetUnitType = TargetType

    self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType } )
  end

  -- Player contains the score and reference data for the player.
  for PlayerName, _player in pairs(self.Players) do
    local player=_player --#SCORE.PlayerData
    
    if player and player.unit and player.unit:IsAlive() then
    
      self:T( "Something got destroyed" )

      -- Some variables
      local InitUnitName = Player.UnitName
      local InitUnitType = Player.UnitType
      local InitCoalition = Player.UnitCoalition
      local InitCategory = Player.UnitCategory
      local InitUnitCoalition = _SCORINGCoalition[InitCoalition]
      local InitUnitCategory = _SCORINGCategory[InitCategory]

      self:T( { InitUnitName, InitUnitType, InitUnitCoalition, InitCoalition, InitUnitCategory, InitCategory } )

      local Destroyed = false
      
      local hit=player.hit[TargetUnitName] --#SCORE.HitData

      -- What is the player destroying?
      if hit and hit.timeStamp~=0 then -- Was there a hit for this unit for this player before registered?
        
        local TargetThreatLevel = hit.threatLevel
        local TargetThreatType  = hit.threatType
        
        Player.Destroy[TargetCategory] = Player.Destroy[TargetCategory] or {}
        Player.Destroy[TargetCategory][TargetType] = Player.Destroy[TargetCategory][TargetType] or {}
        
        local destroy={} --#SCORE.DestroyData

        -- PlayerDestroy contains the destroy score data per category and target type of the player.
        local TargetDestroy = Player.Destroy[TargetCategory][TargetType]
        TargetDestroy.Score = TargetDestroy.Score or 0
        TargetDestroy.ScoreDestroy = TargetDestroy.ScoreDestroy or 0
        TargetDestroy.Penalty =  TargetDestroy.Penalty or 0
        TargetDestroy.PenaltyDestroy = TargetDestroy.PenaltyDestroy or 0

        if TargetCoalition then
          if InitCoalition == TargetCoalition then
          
            ---
            -- Hit Friendly
            ---
          
            local ThreatLevelTarget = TargetThreatLevel
            local ThreatTypeTarget = TargetThreatType
            local ThreatLevelPlayer = Player.ThreatLevel / 10 + 1
            local ThreatPenalty = math.ceil( ( ThreatLevelTarget / ThreatLevelPlayer ) * self.ScaleDestroyPenalty / 10 )
            self:F( { ThreatLevel = ThreatPenalty, ThreatLevelTarget = ThreatLevelTarget, ThreatTypeTarget = ThreatTypeTarget, ThreatLevelPlayer = ThreatLevelPlayer  } )
            
            Player.Penalty = Player.Penalty + ThreatPenalty
            TargetDestroy.Penalty = TargetDestroy.Penalty + ThreatPenalty
            TargetDestroy.PenaltyDestroy = TargetDestroy.PenaltyDestroy + 1
            
            if Player.HitPlayers[TargetPlayerName] then 
              -- A player destroyed another friendly player.
            else
              -- A player destroyed another friendly target.
            end

            -- Write CSV penalty.
            Destroyed = true
            --self:ScoreCSV( PlayerName, TargetPlayerName, "DESTROY_PENALTY", 1, ThreatPenalty, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
            
          else
          
            ---
            -- Hit Enemy
            ---

            local ThreatLevelTarget = TargetThreatLevel
            local ThreatTypeTarget = TargetThreatType
            local ThreatLevelPlayer = Player.ThreatLevel / 10 + 1
            local ThreatScore = math.ceil( ( ThreatLevelTarget / ThreatLevelPlayer )  * self.ScaleDestroyScore / 10 )
            
            self:F( { ThreatLevel = ThreatScore, ThreatLevelTarget = ThreatLevelTarget, ThreatTypeTarget = ThreatTypeTarget, ThreatLevelPlayer = ThreatLevelPlayer  } )
  
            Player.Score = Player.Score + ThreatScore
            TargetDestroy.Score = TargetDestroy.Score + ThreatScore
            TargetDestroy.ScoreDestroy = TargetDestroy.ScoreDestroy + 1
            
            if Player.HitPlayers[TargetPlayerName] then 
              -- A player destroyed another enemy player.
            else
              -- A player destroyed another enemy target.
            end
            
            -- Write CSV.
            Destroyed = true
            --self:ScoreCSV( PlayerName, TargetPlayerName, "DESTROY_SCORE", 1, ThreatScore, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
            
            local UnitName = TargetUnit:GetName()
            
            -- Scoring for special objects.
            local Score = self.ScoringObjects[UnitName]
            
            if Score then
            
              Player.Score = Player.Score + Score
              TargetDestroy.Score = TargetDestroy.Score + Score
              
              MESSAGE
                :NewType( self.DisplayMessagePrefix .. "Special target '" .. TargetUnitCategory .. " ( " .. ThreatTypeTarget .. " ) " .. " destroyed! " .. 
                      "Player '" .. PlayerName .. "' receives an extra " .. Score .. " points! Total: " .. Player.Score - Player.Penalty,
                      MESSAGE.Type.Information 
                    )
                :ToAllIf( self:IfMessagesScore() and self:IfMessagesToAll() )
                :ToCoalitionIf( InitCoalition, self:IfMessagesScore() and self:IfMessagesToCoalition() )
                
              -- Write CSV file.
              self:ScoreCSV( PlayerName, TargetPlayerName, "DESTROY_SCORE", 1, Score, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
              Destroyed = true
            end
            
            -- Check if there are Zones where the destruction happened.
            for ZoneName, ScoreZoneData in pairs(self.ScoringZones) do
              self:F( { ScoringZone = ScoreZoneData } )
              
              local ScoreZone = ScoreZoneData.ScoreZone -- Core.Zone#ZONE_BASE
              
              local Score = ScoreZoneData.Score
              
              -- Check if target is in zone.
              if ScoreZone:IsVec2InZone( TargetUnit:GetVec2() ) then
                Player.Score = Player.Score + Score
                TargetDestroy.Score = TargetDestroy.Score + Score
                
                MESSAGE
                  :NewType( self.DisplayMessagePrefix .. "Target destroyed in zone '" .. ScoreZone:GetName() .. "'." .. 
                        "Player '" .. PlayerName .. "' receives an extra " .. Score .. " points! " .. 
                        "Total: " .. Player.Score - Player.Penalty,
                        MESSAGE.Type.Information )
                  :ToAllIf( self:IfMessagesZone() and self:IfMessagesToAll() )
                  :ToCoalitionIf( InitCoalition, self:IfMessagesZone() and self:IfMessagesToCoalition() )
                  
                -- Write CSV.
                self:ScoreCSV( PlayerName, TargetPlayerName, "DESTROY_SCORE", 1, Score, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
                Destroyed = true
              end
            end
                          
          end
          
        else
        
          ---
          -- Scenery Destroyed
          ---
        
          -- Check if there are Zones where the destruction happened.
          for ZoneName, ScoreZoneData in pairs(self.ScoringZones) do
          
            local ScoreZone = ScoreZoneData.ScoreZone -- Core.Zone#ZONE_BASE
            local Score = ScoreZoneData.Score
            
            if ScoreZone:IsVec2InZone(TargetUnit:GetVec2()) then
            
              Player.Score = Player.Score + Score
              TargetDestroy.Score = TargetDestroy.Score + Score

              -- Player destroyed scenery in scoring zone.              
                
              --Write CSV.
              Destroyed = true
              --self:ScoreCSV( PlayerName, "", "DESTROY_SCORE", 1, Score, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, "", "Scenery", TargetUnitType )
            end
          end
          
        end
        
        -- Delete now the hit cache if the target was destroyed.
        -- Otherwise points will be granted every time a target gets killed by the players that hit that target.
        -- This is only relevant for player to player destroys.
        if Destroyed then
          Player.Hit[TargetCategory][TargetUnitName].TimeStamp = 0
        end
        
      end
    end
  end
end

--- On before "Save" event. Checks if io and lfs are available.
-- @param #SCORE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path (Optional) Path where the file is saved. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
-- @param #string filename (Optional) File name for saving the player grades. Default is "SCORE-<ALIAS>_LSOgrades.csv".
function SCORE:onbeforeSave(From, Event, To, path, filename)

  -- Check io module is available.
  if not io then
    self:E(self.lid.."ERROR: io not desanitized. Can't save player grades.")
    return false
  end
  
  -- Check default path.
  if path==nil and not lfs then
    self:E(self.lid.."WARNING: lfs not desanitized. Results will be saved in DCS installation root directory rather than your \"Saved Games\DCS\" folder.")
  end

  return true
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- On after "Save" event. Player data is saved to file.
-- @param #SCORE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string path Path where the file is saved. If nil, file is saved in the DCS root installtion directory or your "Saved Games" folder if lfs was desanitized.
-- @param #string filename (Optional) File name for saving the player grades. Default is "SCORE-<ALIAS>_LSOgrades.csv".
function SCORE:onafterSave(From, Event, To, path, filename)

  --- Function that saves data to file
  local function _savefile(filename, data)
    local f = io.open(filename, "wb")
    if f then
      f:write(data)
      f:close()
    end
  end
  
  -- Set path or default.
  if lfs then
    path=path or lfs.writedir()
  end

  -- Set file name.
  filename=filename or string.format("Score.csv")

  -- Set path.
  if path~=nil then
    filename=path.."\\"..filename
  end

  -- Header line
  local scores="Name,Pass,Points Final,Points Pass,Grade,Details,Wire,Tgroove,Case,Wind,Modex,Airframe,Carrier Type,Carrier Name,Theatre,Mission Time,Mission Date,OS Date\n"
  
  local scores="Name,Player Unit,Player Coalition,Player Category,Score Type,Target Category,Target Name, Target Coalition,Target Player,Target Score,Mission Date, Mission Time, OS Date"
  
  -- Loop over all players.
  local n=0
  for playername,grades in pairs(self.playerscores) do
  
    -- Loop over player grades table.
    for i,_grade in pairs(grades) do
      local grade=_grade --#SCORE.LSOgrade
      
      -- Check some stuff that could be nil.
      local wire="n/a"
      if grade.wire and grade.wire<=4 then
        wire=tostring(grade.wire)
      end
      
      local Tgroove="n/a"
      if grade.Tgroove and grade.Tgroove<=360 and grade.case<3 then
        Tgroove=tostring(UTILS.Round(grade.Tgroove, 1))
      end
      
      local finalscore="n/a"
      if grade.finalscore then
        finalscore=tostring(UTILS.Round(grade.finalscore, 1))
      end
      
      -- Compile grade line.
      scores=scores..string.format("%s,%d,%s,%.1f,%s,%s,%s,%s,%d,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
      playername, i, finalscore, grade.points, grade.grade, grade.details, wire, Tgroove, grade.case,
      grade.wind, grade.modex, grade.airframe, grade.carriertype, grade.carriername, grade.theatre, grade.mitime, grade.midate, grade.osdate)
      n=n+1
    end
  end
  
  -- Info
  local text=string.format("Saving %d player LSO grades to file %s", n, filename)
  self:I(self.lid..text)  
  
  -- Save file.
  _savefile(filename, scores)
end






