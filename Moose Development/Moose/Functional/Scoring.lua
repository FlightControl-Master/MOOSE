--- **Functional** - Administer the scoring of player achievements, and create a CSV file logging the scoring events for use at team or squadron websites.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Set the scoring scales based on threat level.
--   * Positive scores and negative scores.
--   * A contribution model to score achievements.
--   * Score goals.
--   * Score specific achievements.
--   * Score the hits and destroys of units.
--   * Score the hits and destroys of statics.
--   * Score the hits and destroys of scenery.
--   * Log scores into a CSV file.
--   * Connect to a remote server using JSON and IP.
--   
-- ===
-- 
-- ## Missions:
-- 
-- [SCO - Scoring](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SCO%20-%20Scoring)
-- 
-- ===
-- 
-- Administers the scoring of player achievements, 
-- and creates a CSV file logging the scoring events and results for use at team or squadron websites.
-- 
-- SCORING automatically calculates the threat level of the objects hit and destroyed by players, 
-- which can be @{Wrapper.Unit}, @{Static) and @{Scenery} objects.
-- 
-- Positive score points are granted when enemy or neutral targets are destroyed. 
-- Negative score points or penalties are given when a friendly target is hit or destroyed. 
-- This brings a lot of dynamism in the scoring, where players need to take care to inflict damage on the right target.
-- By default, penalties weight heavier in the scoring, to ensure that players don't commit fratricide.
-- The total score of the player is calculated by **adding the scores minus the penalties**.
-- 
-- ![Banner Image](..\Presentations\SCORING\Dia4.JPG)
-- 
-- The score value is calculated based on the **threat level of the player** and the **threat level of the target**.
-- A calculated score takes the threat level of the target divided by a balanced threat level of the player unit.   
-- As such, if the threat level of the target is high, and the player threat level is low, a higher score will be given than 
-- if the threat level of the player would be high too.
-- 
-- ![Banner Image](..\Presentations\SCORING\Dia5.JPG)
-- 
-- When multiple players hit the same target, and finally succeed in destroying the target, then each player who contributed to the target
-- destruction, will receive a score. This is important for targets that require significant damage before it can be destroyed, like
-- ships or heavy planes.
-- 
-- ![Banner Image](..\Presentations\SCORING\Dia13.JPG)
-- 
-- Optionally, the score values can be **scaled** by a **scale**. Specific scales can be set for positive cores or negative penalties.
-- The default range of the scores granted is a value between 0 and 10. The default range of penalties given is a value between 0 and 30.
-- 
-- ![Banner Image](..\Presentations\SCORING\Dia7.JPG)
-- 
-- **Additional scores** can be granted to **specific objects**, when the player(s) destroy these objects.
-- 
-- ![Banner Image](..\Presentations\SCORING\Dia9.JPG)
-- 
-- Various @{Zone}s can be defined for which scores are also granted when objects in that @{Zone} are destroyed.
-- This is **specifically useful** to designate **scenery targets on the map** that will generate points when destroyed.
-- 
-- With a small change in MissionScripting.lua, the scoring results can also be logged in a **CSV file**.  
-- These CSV files can be used to:
-- 
--   * Upload scoring to a database or a BI tool to publish the scoring results to the player community.
--   * Upload scoring in an (online) Excel like tool, using pivot tables and pivot charts to show mission results.
--   * Share scoring amoung players after the mission to discuss mission results.
-- 
-- Scores can be **reported**. **Menu options** are automatically added to **each player group** when a player joins a client slot or a CA unit.
-- Use the radio menu F10 to consult the scores while running the mission. 
-- Scores can be reported for your user, or an overall score can be reported of all players currently active in the mission.
-- 
-- ===
-- 
-- ### Authors: **FlightControl**
-- 
-- ### Contributions:
-- 
--   * **Wingthor (TAW)**: Testing & Advice.
--   * **Dutch-Baron (TAW)**: Testing & Advice.
--   * **[Whisper](http://forums.eagle.ru/member.php?u=3829): Testing and Advice.
-- 
-- ===       
-- 
-- @module Functional.Scoring
-- @image Scoring.JPG


--- @type SCORING
-- @field Players A collection of the current players that have joined the game.
-- @extends Core.Base#BASE

--- SCORING class
-- 
-- # Constructor:
-- 
--      local Scoring = SCORING:New( "Scoring File" )
--       
-- 
-- # Set the destroy score or penalty scale:
-- 
-- Score scales can be set for scores granted when enemies or friendlies are destroyed.
-- Use the method @{#SCORING.SetScaleDestroyScore}() to set the scale of enemy destroys (positive destroys). 
-- Use the method @{#SCORING.SetScaleDestroyPenalty}() to set the scale of friendly destroys (negative destroys).
-- 
--      local Scoring = SCORING:New( "Scoring File" )
--      Scoring:SetScaleDestroyScore( 10 )
--      Scoring:SetScaleDestroyPenalty( 40 )
--      
-- The above sets the scale for valid scores to 10. So scores will be given in a scale from 0 to 10.
-- The penalties will be given in a scale from 0 to 40.
-- 
-- # Define special targets that will give extra scores:
-- 
-- Special targets can be set that will give extra scores to the players when these are destroyed.
-- Use the methods @{#SCORING.AddUnitScore}() and @{#SCORING.RemoveUnitScore}() to specify a special additional score for a specific @{Wrapper.Unit}s.  
-- Use the methods @{#SCORING.AddStaticScore}() and @{#SCORING.RemoveStaticScore}() to specify a special additional score for a specific @{Static}s.  
-- Use the method @{#SCORING.SetGroupGroup}() to specify a special additional score for a specific @{Wrapper.Group}s.  
-- 
--      local Scoring = SCORING:New( "Scoring File" )
--      Scoring:AddUnitScore( UNIT:FindByName( "Unit #001" ), 200 )
--      Scoring:AddStaticScore( STATIC:FindByName( "Static #1" ), 100 )
--      
-- The above grants an additional score of 200 points for Unit #001 and an additional 100 points of Static #1 if these are destroyed.
-- Note that later in the mission, one can remove these scores set, for example, when the a goal achievement time limit is over.
-- For example, this can be done as follows:
-- 
--      Scoring:RemoveUnitScore( UNIT:FindByName( "Unit #001" ) )
-- 
-- # Define destruction zones that will give extra scores:
-- 
-- Define zones of destruction. Any object destroyed within the zone of the given category will give extra points.
-- Use the method @{#SCORING.AddZoneScore}() to add a @{Zone} for additional scoring.  
-- Use the method @{#SCORING.RemoveZoneScore}() to remove a @{Zone} for additional scoring.  
-- There are interesting variations that can be achieved with this functionality. For example, if the @{Zone} is a @{Core.Zone#ZONE_UNIT}, 
-- then the zone is a moving zone, and anything destroyed within that @{Zone} will generate points.
-- The other implementation could be to designate a scenery target (a building) in the mission editor surrounded by a @{Zone}, 
-- just large enough around that building.
-- 
-- # Add extra Goal scores upon an event or a condition:
-- 
-- A mission has goals and achievements. The scoring system provides an API to set additional scores when a goal or achievement event happens.
-- Use the method @{#SCORING.AddGoalScore}() to add a score for a Player at any time in your mission.
-- 
-- # (Decommissioned) Configure fratricide level.
-- 
-- **This functionality is decomissioned until the DCS bug concerning Unit:destroy() not being functional in multi player for player units has been fixed by ED**.
-- 
-- When a player commits too much damage to friendlies, his penalty score will reach a certain level.
-- Use the method @{#SCORING.SetFratricide}() to define the level when a player gets kicked.  
-- By default, the fratricide level is the default penalty mutiplier * 2 for the penalty score.
-- 
-- # Penalty score when a player changes the coalition.
-- 
-- When a player changes the coalition, he can receive a penalty score.
-- Use the method @{#SCORING.SetCoalitionChangePenalty}() to define the penalty when a player changes coalition.
-- By default, the penalty for changing coalition is the default penalty scale.  
-- 
-- # Define output CSV files.
-- 
-- The CSV file is given the name of the string given in the @{#SCORING.New}{} constructor, followed by the .csv extension.
-- The file is incrementally saved in the **<User>\\Saved Games\\DCS\\Logs** folder, and has a time stamp indicating each mission run.
-- See the following example:
-- 
--     local ScoringFirstMission = SCORING:New( "FirstMission" )
--     local ScoringSecondMission = SCORING:New( "SecondMission" )
--     
-- The above documents that 2 Scoring objects are created, ScoringFirstMission and ScoringSecondMission. 
-- 
-- ### **IMPORTANT!!!*  
-- In order to allow DCS world to write CSV files, you need to adapt a configuration file in your DCS world installation **on the server**.
-- For this, browse to the **missionscripting.lua** file in your DCS world installation folder.
-- For me, this installation folder is in _D:\\Program Files\\Eagle Dynamics\\DCS World\Scripts_.
-- 
-- Edit a few code lines in the MissionScripting.lua file. Comment out the lines **os**, **io** and **lfs**:
-- 
--        do
--          --sanitizeModule('os')
--          --sanitizeModule('io')
--          --sanitizeModule('lfs')
--          require = nil
--          loadlib = nil
--        end
-- 
-- When these lines are not sanitized, functions become available to check the time, and to write files to your system at the above specified location.  
-- Note that the MissionScripting.lua file provides a warning. So please beware of this warning as outlined by Eagle Dynamics!
-- 
--        --Sanitize Mission Scripting environment
--        --This makes unavailable some unsecure functions. 
--        --Mission downloaded from server to client may contain potentialy harmful lua code that may use these functions.
--        --You can remove the code below and make availble these functions at your own risk.
-- 
-- The MOOSE designer cannot take any responsibility of any damage inflicted as a result of the de-sanitization.
-- That being said, I hope that the SCORING class provides you with a great add-on to score your squad mates achievements.
-- 
-- # Configure messages.
-- 
-- When players hit or destroy targets, messages are sent.
-- Various methods exist to configure:
-- 
--   * Which messages are sent upon the event.
--   * Which audience receives the message.
-- 
-- ## Configure the messages sent upon the event.
-- 
-- Use the following methods to configure when to send messages. By default, all messages are sent.
-- 
--   * @{#SCORING.SetMessagesHit}(): Configure to send messages after a target has been hit.
--   * @{#SCORING.SetMessagesDestroy}(): Configure to send messages after a target has been destroyed.
--   * @{#SCORING.SetMessagesAddon}(): Configure to send messages for additional score, after a target has been destroyed.
--   * @{#SCORING.SetMessagesZone}(): Configure to send messages for additional score, after a target has been destroyed within a given zone.
--   
-- ## Configure the audience of the messages.
-- 
-- Use the following methods to configure the audience of the messages. By default, the messages are sent to all players in the mission.
-- 
--   * @{#SCORING.SetMessagesToAll}(): Configure to send messages to all players.
--   * @{#SCORING.SetMessagesToCoalition}(): Configure to send messages to only those players within the same coalition as the player.
--
-- ===
-- 
-- @field #SCORING
SCORING = {
  ClassName = "SCORING",
  ClassID = 0,
  Players = {},
}

local _SCORINGCoalition =
  {
    [1] = "Red",
    [2] = "Blue",
  }

local _SCORINGCategory =
  {
    [Unit.Category.AIRPLANE] = "Plane",
    [Unit.Category.HELICOPTER] = "Helicopter",
    [Unit.Category.GROUND_UNIT] = "Vehicle",
    [Unit.Category.SHIP] = "Ship",
    [Unit.Category.STRUCTURE] = "Structure",
  }

--- Creates a new SCORING object to administer the scoring achieved by players.
-- @param #SCORING self
-- @param #string GameName The name of the game. This name is also logged in the CSV score file.
-- @return #SCORING self
-- @usage
-- 
-- -- Define a new scoring object for the mission Gori Valley.
-- ScoringObject = SCORING:New( "Gori Valley" )
-- 
function SCORING:New( GameName )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() ) -- #SCORING
  
  if GameName then 
    self.GameName = GameName
  else
    error( "A game name must be given to register the scoring results" )
  end
  
  
  -- Additional Object scores
  self.ScoringObjects = {}
  
  -- Additional Zone scores.
  self.ScoringZones = {}

  -- Configure Messages
  self:SetMessagesToAll()
  self:SetMessagesHit( false )
  self:SetMessagesDestroy( true )
  self:SetMessagesScore( true )
  self:SetMessagesZone( true )
  
  -- Scales
  self:SetScaleDestroyScore( 10 )
  self:SetScaleDestroyPenalty( 30 )

  -- Default fratricide penalty level (maximum penalty that can be assigned to a player before he gets kicked).
  self:SetFratricide( self.ScaleDestroyPenalty * 3 )
  
  -- Default penalty when a player changes coalition.
  self:SetCoalitionChangePenalty( self.ScaleDestroyPenalty )
  
  self:SetDisplayMessagePrefix()
  
  -- Event handlers  
  self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
  self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
  self:HandleEvent( EVENTS.Hit, self._EventOnHit )
  self:HandleEvent( EVENTS.Birth )
  --self:HandleEvent( EVENTS.PlayerEnterUnit )
  self:HandleEvent( EVENTS.PlayerLeaveUnit )
  
  -- During mission startup, especially for single player, 
  -- iterate the database for the player that has joined, and add him to the scoring, and set the menu.
  -- But this can only be started one second after the mission has started, so i need to schedule this ...
  self.ScoringPlayerScan = BASE:ScheduleOnce( 1, 
    function()
      for PlayerName, PlayerUnit in pairs( _DATABASE:GetPlayerUnits() ) do 
        self:_AddPlayerFromUnit( PlayerUnit )
        self:SetScoringMenu( PlayerUnit:GetGroup() )
      end
    end
  )
  

  -- Create the CSV file.
  self:OpenCSV( GameName )

  return self
  
end

--- Set a prefix string that will be displayed at each scoring message sent.
-- @param #SCORING self
-- @param #string DisplayMessagePrefix (Default="Scoring: ") The scoring prefix string.
-- @return #SCORING
function SCORING:SetDisplayMessagePrefix( DisplayMessagePrefix )
  self.DisplayMessagePrefix = DisplayMessagePrefix or ""
  return self
end


--- Set the scale for scoring valid destroys (enemy destroys).
-- A default calculated score is a value between 1 and 10.
-- The scale magnifies the scores given to the players.
-- @param #SCORING self
-- @param #number Scale The scale of the score given.
function SCORING:SetScaleDestroyScore( Scale )
  self.ScaleDestroyScore = Scale
  return self
end

--- Set the scale for scoring penalty destroys (friendly destroys).
-- A default calculated penalty is a value between 1 and 10.
-- The scale magnifies the scores given to the players.
-- @param #SCORING self
-- @param #number Scale The scale of the score given.
-- @return #SCORING
function SCORING:SetScaleDestroyPenalty( Scale )

  self.ScaleDestroyPenalty = Scale
  
  return self
end

--- Add a @{Wrapper.Unit} for additional scoring when the @{Wrapper.Unit} is destroyed.
-- Note that if there was already a @{Wrapper.Unit} declared within the scoring with the same name, 
-- then the old @{Wrapper.Unit}  will be replaced with the new @{Wrapper.Unit}.
-- @param #SCORING self
-- @param Wrapper.Unit#UNIT ScoreUnit The @{Wrapper.Unit} for which the Score needs to be given.
-- @param #number Score The Score value.
-- @return #SCORING
function SCORING:AddUnitScore( ScoreUnit, Score )

  local UnitName = ScoreUnit:GetName()

  self.ScoringObjects[UnitName] = Score
  
  return self
end

--- Removes a @{Wrapper.Unit} for additional scoring when the @{Wrapper.Unit} is destroyed.
-- @param #SCORING self
-- @param Wrapper.Unit#UNIT ScoreUnit The @{Wrapper.Unit} for which the Score needs to be given.
-- @return #SCORING
function SCORING:RemoveUnitScore( ScoreUnit )

  local UnitName = ScoreUnit:GetName()

  self.ScoringObjects[UnitName] = nil
  
  return self
end

--- Add a @{Static} for additional scoring when the @{Static} is destroyed.
-- Note that if there was already a @{Static} declared within the scoring with the same name, 
-- then the old @{Static}  will be replaced with the new @{Static}.
-- @param #SCORING self
-- @param Wrapper.Static#UNIT ScoreStatic The @{Static} for which the Score needs to be given.
-- @param #number Score The Score value.
-- @return #SCORING
function SCORING:AddStaticScore( ScoreStatic, Score )

  local StaticName = ScoreStatic:GetName()

  self.ScoringObjects[StaticName] = Score
  
  return self
end

--- Removes a @{Static} for additional scoring when the @{Static} is destroyed.
-- @param #SCORING self
-- @param Wrapper.Static#UNIT ScoreStatic The @{Static} for which the Score needs to be given.
-- @return #SCORING
function SCORING:RemoveStaticScore( ScoreStatic )

  local StaticName = ScoreStatic:GetName()

  self.ScoringObjects[StaticName] = nil
  
  return self
end


--- Specify a special additional score for a @{Wrapper.Group}.
-- @param #SCORING self
-- @param Wrapper.Group#GROUP ScoreGroup The @{Wrapper.Group} for which each @{Wrapper.Unit} a Score is given.
-- @param #number Score The Score value.
-- @return #SCORING
function SCORING:AddScoreGroup( ScoreGroup, Score )

  local ScoreUnits = ScoreGroup:GetUnits()

  for ScoreUnitID, ScoreUnit in pairs( ScoreUnits ) do
    local UnitName = ScoreUnit:GetName()
    self.ScoringObjects[UnitName] = Score
  end
  
  return self
end

--- Add a @{Zone} to define additional scoring when any object is destroyed in that zone.
-- Note that if a @{Zone} with the same name is already within the scoring added, the @{Zone} (type) and Score will be replaced!
-- This allows for a dynamic destruction zone evolution within your mission.
-- @param #SCORING self
-- @param Core.Zone#ZONE_BASE ScoreZone The @{Zone} which defines the destruction score perimeters. 
-- Note that a zone can be a polygon or a moving zone.
-- @param #number Score The Score value.
-- @return #SCORING
function SCORING:AddZoneScore( ScoreZone, Score )

  local ZoneName = ScoreZone:GetName()

  self.ScoringZones[ZoneName] = {}
  self.ScoringZones[ZoneName].ScoreZone = ScoreZone
  self.ScoringZones[ZoneName].Score = Score
  
  return self
end

--- Remove a @{Zone} for additional scoring.
-- The scoring will search if any @{Zone} is added with the given name, and will remove that zone from the scoring.
-- This allows for a dynamic destruction zone evolution within your mission.
-- @param #SCORING self
-- @param Core.Zone#ZONE_BASE ScoreZone The @{Zone} which defines the destruction score perimeters. 
-- Note that a zone can be a polygon or a moving zone.
-- @return #SCORING
function SCORING:RemoveZoneScore( ScoreZone )

  local ZoneName = ScoreZone:GetName()

  self.ScoringZones[ZoneName] = nil
  
  return self
end


--- Configure to send messages after a target has been hit.
-- @param #SCORING self
-- @param #boolean OnOff If true is given, the messages are sent. 
-- @return #SCORING
function SCORING:SetMessagesHit( OnOff )

  self.MessagesHit = OnOff
  return self
end

--- If to send messages after a target has been hit.
-- @param #SCORING self
-- @return #boolean
function SCORING:IfMessagesHit()

  return self.MessagesHit
end

--- Configure to send messages after a target has been destroyed.
-- @param #SCORING self
-- @param #boolean OnOff If true is given, the messages are sent. 
-- @return #SCORING
function SCORING:SetMessagesDestroy( OnOff )

  self.MessagesDestroy = OnOff
  return self
end

--- If to send messages after a target has been destroyed.
-- @param #SCORING self
-- @return #boolean
function SCORING:IfMessagesDestroy()

  return self.MessagesDestroy
end

--- Configure to send messages after a target has been destroyed and receives additional scores.
-- @param #SCORING self
-- @param #boolean OnOff If true is given, the messages are sent. 
-- @return #SCORING
function SCORING:SetMessagesScore( OnOff )

  self.MessagesScore = OnOff
  return self
end

--- If to send messages after a target has been destroyed and receives additional scores.
-- @param #SCORING self
-- @return #boolean
function SCORING:IfMessagesScore()

  return self.MessagesScore
end

--- Configure to send messages after a target has been hit in a zone, and additional score is received.
-- @param #SCORING self
-- @param #boolean OnOff If true is given, the messages are sent. 
-- @return #SCORING
function SCORING:SetMessagesZone( OnOff )

  self.MessagesZone = OnOff
  return self
end

--- If to send messages after a target has been hit in a zone, and additional score is received.
-- @param #SCORING self
-- @return #boolean
function SCORING:IfMessagesZone()

  return self.MessagesZone
end

--- Configure to send messages to all players.
-- @param #SCORING self
-- @return #SCORING
function SCORING:SetMessagesToAll()

  self.MessagesAudience = 1
  return self
end

--- If to send messages to all players.
-- @param #SCORING self
-- @return #boolean
function SCORING:IfMessagesToAll()

  return self.MessagesAudience == 1
end

--- Configure to send messages to only those players within the same coalition as the player.
-- @param #SCORING self
-- @return #SCORING
function SCORING:SetMessagesToCoalition()

  self.MessagesAudience = 2
  return self
end

--- If to send messages to only those players within the same coalition as the player.
-- @param #SCORING self
-- @return #boolean
function SCORING:IfMessagesToCoalition()

  return self.MessagesAudience == 2
end


--- When a player commits too much damage to friendlies, his penalty score will reach a certain level.
-- Use this method to define the level when a player gets kicked.  
-- By default, the fratricide level is the default penalty mutiplier * 2 for the penalty score.
-- @param #SCORING self
-- @param #number Fratricide The amount of maximum penalty that may be inflicted by a friendly player before he gets kicked. 
-- @return #SCORING
function SCORING:SetFratricide( Fratricide )

  self.Fratricide = Fratricide
  return self
end


--- When a player changes the coalition, he can receive a penalty score.
-- Use the method @{#SCORING.SetCoalitionChangePenalty}() to define the penalty when a player changes coalition.
-- By default, the penalty for changing coalition is the default penalty scale.  
-- @param #SCORING self
-- @param #number CoalitionChangePenalty The amount of penalty that is given. 
-- @return #SCORING
function SCORING:SetCoalitionChangePenalty( CoalitionChangePenalty )

  self.CoalitionChangePenalty = CoalitionChangePenalty
  return self
end


--- Sets the scoring menu.
-- @param #SCORING self
-- @return #SCORING
function SCORING:SetScoringMenu( ScoringGroup )
    local Menu = MENU_GROUP:New( ScoringGroup, 'Scoring and Statistics' )
    local ReportGroupSummary = MENU_GROUP_COMMAND:New( ScoringGroup, 'Summary report players in group', Menu, SCORING.ReportScoreGroupSummary, self, ScoringGroup )
    local ReportGroupDetailed = MENU_GROUP_COMMAND:New( ScoringGroup, 'Detailed report players in group', Menu, SCORING.ReportScoreGroupDetailed, self, ScoringGroup )
    local ReportToAllSummary = MENU_GROUP_COMMAND:New( ScoringGroup, 'Summary report all players', Menu, SCORING.ReportScoreAllSummary, self, ScoringGroup )
    self:SetState( ScoringGroup, "ScoringMenu", Menu )
  return self
end


--- Add a new player entering a Unit.
-- @param #SCORING self
-- @param Wrapper.Unit#UNIT UnitData
function SCORING:_AddPlayerFromUnit( UnitData )
  self:F( UnitData )

  if UnitData:IsAlive() then
    local UnitName = UnitData:GetName()
    local PlayerName = UnitData:GetPlayerName()
    local UnitDesc = UnitData:GetDesc()
    local UnitCategory = UnitDesc.category
    local UnitCoalition = UnitData:GetCoalition()
    local UnitTypeName = UnitData:GetTypeName()
    local UnitThreatLevel, UnitThreatType = UnitData:GetThreatLevel()

    self:T( { PlayerName, UnitName, UnitCategory, UnitCoalition, UnitTypeName } )

    if self.Players[PlayerName] == nil then -- I believe this is the place where a Player gets a life in a mission when he enters a unit ...
      self.Players[PlayerName] = {}
      self.Players[PlayerName].Hit = {}
      self.Players[PlayerName].Destroy = {}
      self.Players[PlayerName].Goals = {}
      self.Players[PlayerName].Mission = {}

      -- for CategoryID, CategoryName in pairs( SCORINGCategory ) do
      -- self.Players[PlayerName].Hit[CategoryID] = {}
      -- self.Players[PlayerName].Destroy[CategoryID] = {}
      -- end
      self.Players[PlayerName].HitPlayers = {}
      self.Players[PlayerName].Score = 0
      self.Players[PlayerName].Penalty = 0
      self.Players[PlayerName].PenaltyCoalition = 0
      self.Players[PlayerName].PenaltyWarning = 0
    end

    if not self.Players[PlayerName].UnitCoalition then
      self.Players[PlayerName].UnitCoalition = UnitCoalition
    else
      if self.Players[PlayerName].UnitCoalition ~= UnitCoalition then
        self.Players[PlayerName].Penalty = self.Players[PlayerName].Penalty + 50
        self.Players[PlayerName].PenaltyCoalition = self.Players[PlayerName].PenaltyCoalition + 1
        MESSAGE:NewType( self.DisplayMessagePrefix .. "Player '" .. PlayerName .. "' changed coalition from " .. _SCORINGCoalition[self.Players[PlayerName].UnitCoalition] .. " to " .. _SCORINGCoalition[UnitCoalition] ..
          "(changed " .. self.Players[PlayerName].PenaltyCoalition .. " times the coalition). 50 Penalty points added.",
          MESSAGE.Type.Information
        ):ToAll()
        self:ScoreCSV( PlayerName, "", "COALITION_PENALTY",  1, -50, self.Players[PlayerName].UnitName, _SCORINGCoalition[self.Players[PlayerName].UnitCoalition], _SCORINGCategory[self.Players[PlayerName].UnitCategory], self.Players[PlayerName].UnitType,
          UnitName, _SCORINGCoalition[UnitCoalition], _SCORINGCategory[UnitCategory], UnitData:GetTypeName() )
      end
    end
    
    self.Players[PlayerName].UnitName = UnitName
    self.Players[PlayerName].UnitCoalition = UnitCoalition
    self.Players[PlayerName].UnitCategory = UnitCategory
    self.Players[PlayerName].UnitType = UnitTypeName
    self.Players[PlayerName].UNIT = UnitData 
    self.Players[PlayerName].ThreatLevel = UnitThreatLevel
    self.Players[PlayerName].ThreatType = UnitThreatType

    -- TODO: DCS bug concerning Units with skill level client don't get destroyed in multi player. This logic is deactivated until this bug gets fixed.
    --[[
    if self.Players[PlayerName].Penalty > self.Fratricide * 0.50 then
      if self.Players[PlayerName].PenaltyWarning < 1 then
        MESSAGE:NewType( self.DisplayMessagePrefix .. "Player '" .. PlayerName .. "': WARNING! If you continue to commit FRATRICIDE and have a PENALTY score higher than " .. self.Fratricide .. ", you will be COURT MARTIALED and DISMISSED from this mission! \nYour total penalty is: " .. self.Players[PlayerName].Penalty,
          MESSAGE.Type.Information
        ):ToAll()
        self.Players[PlayerName].PenaltyWarning = self.Players[PlayerName].PenaltyWarning + 1
      end
    end

    if self.Players[PlayerName].Penalty > self.Fratricide then
      MESSAGE:NewType( self.DisplayMessagePrefix .. "Player '" .. PlayerName .. "' committed FRATRICIDE, he will be COURT MARTIALED and is DISMISSED from this mission!",
        MESSAGE.Type.Information
      ):ToAll()
      UnitData:GetGroup():Destroy()
    end
    --]]

  end
end


--- Add a goal score for a player.
-- The method takes the Player name for which the Goal score needs to be set.
-- The GoalTag is a string or identifier that is taken into the CSV file scoring log to identify the goal.
-- A free text can be given that is shown to the players.
-- The Score can be both positive and negative.
-- @param #SCORING self
-- @param #string PlayerName The name of the Player.
-- @param #string GoalTag The string or identifier that is used in the CSV file to identify the goal (sort or group later in Excel).
-- @param #string Text A free text that is shown to the players.
-- @param #number Score The score can be both positive or negative ( Penalty ).
function SCORING:AddGoalScorePlayer( PlayerName, GoalTag, Text, Score )

  self:F( { PlayerName, PlayerName, GoalTag, Text, Score } )

  -- PlayerName can be nil, if the Unit with the player crashed or due to another reason.
  if PlayerName then 
    local PlayerData = self.Players[PlayerName]

    PlayerData.Goals[GoalTag] = PlayerData.Goals[GoalTag] or { Score = 0 }
    PlayerData.Goals[GoalTag].Score = PlayerData.Goals[GoalTag].Score + Score  
    PlayerData.Score = PlayerData.Score + Score
  
    MESSAGE:NewType( self.DisplayMessagePrefix .. Text, MESSAGE.Type.Information ):ToAll()
  
    self:ScoreCSV( PlayerName, "", "GOAL_" .. string.upper( GoalTag ), 1, Score, nil )
  end
end



--- Add a goal score for a player.
-- The method takes the PlayerUnit for which the Goal score needs to be set.
-- The GoalTag is a string or identifier that is taken into the CSV file scoring log to identify the goal.
-- A free text can be given that is shown to the players.
-- The Score can be both positive and negative.
-- @param #SCORING self
-- @param Wrapper.Unit#UNIT PlayerUnit The @{Wrapper.Unit} of the Player. Other Properties for the scoring are taken from this PlayerUnit, like coalition, type etc. 
-- @param #string GoalTag The string or identifier that is used in the CSV file to identify the goal (sort or group later in Excel).
-- @param #string Text A free text that is shown to the players.
-- @param #number Score The score can be both positive or negative ( Penalty ).
function SCORING:AddGoalScore( PlayerUnit, GoalTag, Text, Score )

  local PlayerName = PlayerUnit:GetPlayerName()

  self:F( { PlayerUnit.UnitName, PlayerName, GoalTag, Text, Score } )

  -- PlayerName can be nil, if the Unit with the player crashed or due to another reason.
  if PlayerName then 
    local PlayerData = self.Players[PlayerName]

    PlayerData.Goals[GoalTag] = PlayerData.Goals[GoalTag] or { Score = 0 }
    PlayerData.Goals[GoalTag].Score = PlayerData.Goals[GoalTag].Score + Score  
    PlayerData.Score = PlayerData.Score + Score
  
    MESSAGE:NewType( self.DisplayMessagePrefix .. Text, MESSAGE.Type.Information ):ToAll()
  
    self:ScoreCSV( PlayerName, "", "GOAL_" .. string.upper( GoalTag ), 1, Score, PlayerUnit:GetName() )
  end
end


--- Registers Scores the players completing a Mission Task.
-- @param #SCORING self
-- @param Tasking.Mission#MISSION Mission
-- @param Wrapper.Unit#UNIT PlayerUnit
-- @param #string Text
-- @param #number Score
function SCORING:_AddMissionTaskScore( Mission, PlayerUnit, Text, Score )

  local PlayerName = PlayerUnit:GetPlayerName()
  local MissionName = Mission:GetName()

  self:F( { Mission:GetName(), PlayerUnit.UnitName, PlayerName, Text, Score } )

  -- PlayerName can be nil, if the Unit with the player crashed or due to another reason.
  if PlayerName then 
    local PlayerData = self.Players[PlayerName]
  
    if not PlayerData.Mission[MissionName] then
      PlayerData.Mission[MissionName] = {}
      PlayerData.Mission[MissionName].ScoreTask = 0
      PlayerData.Mission[MissionName].ScoreMission = 0
    end
  
    self:T( PlayerName )
    self:T( PlayerData.Mission[MissionName] )
  
    PlayerData.Score = self.Players[PlayerName].Score + Score
    PlayerData.Mission[MissionName].ScoreTask = self.Players[PlayerName].Mission[MissionName].ScoreTask + Score
  
    MESSAGE:NewType( self.DisplayMessagePrefix .. Mission:GetText() .. " : " .. Text .. " Score: " .. Score, MESSAGE.Type.Information ):ToAll()
  
    self:ScoreCSV( PlayerName, "", "TASK_" .. MissionName:gsub( ' ', '_' ), 1, Score, PlayerUnit:GetName() )
  end
end

--- Registers Scores the players completing a Mission Task.
-- @param #SCORING self
-- @param Tasking.Mission#MISSION Mission
-- @param #string PlayerName
-- @param #string Text
-- @param #number Score
function SCORING:_AddMissionGoalScore( Mission, PlayerName, Text, Score )

  local MissionName = Mission:GetName()

  self:F( { Mission:GetName(), PlayerName, Text, Score } )

  -- PlayerName can be nil, if the Unit with the player crashed or due to another reason.
  if PlayerName then 
    local PlayerData = self.Players[PlayerName]
  
    if not PlayerData.Mission[MissionName] then
      PlayerData.Mission[MissionName] = {}
      PlayerData.Mission[MissionName].ScoreTask = 0
      PlayerData.Mission[MissionName].ScoreMission = 0
    end
  
    self:T( PlayerName )
    self:T( PlayerData.Mission[MissionName] )
  
    PlayerData.Score = self.Players[PlayerName].Score + Score
    PlayerData.Mission[MissionName].ScoreTask = self.Players[PlayerName].Mission[MissionName].ScoreTask + Score
  
    MESSAGE:NewType( string.format( "%s%s: %s! Player %s receives %d score!", self.DisplayMessagePrefix, Mission:GetText(), Text, PlayerName, Score ), MESSAGE.Type.Information ):ToAll()

    self:ScoreCSV( PlayerName, "", "TASK_" .. MissionName:gsub( ' ', '_' ), 1, Score )
  end
end

--- Registers Mission Scores for possible multiple players that contributed in the Mission.
-- @param #SCORING self
-- @param Tasking.Mission#MISSION Mission
-- @param Wrapper.Unit#UNIT PlayerUnit
-- @param #string Text
-- @param #number Score
function SCORING:_AddMissionScore( Mission, Text, Score )
  
  local MissionName = Mission:GetName()

  self:F( { Mission, Text, Score } )
  self:F( self.Players )

  for PlayerName, PlayerData in pairs( self.Players ) do

    self:F( PlayerData )
    if PlayerData.Mission[MissionName] then

      PlayerData.Score = PlayerData.Score + Score
      PlayerData.Mission[MissionName].ScoreMission = PlayerData.Mission[MissionName].ScoreMission + Score

      MESSAGE:NewType( self.DisplayMessagePrefix .. "Player '" .. PlayerName .. "' has " .. Text .. " in " .. Mission:GetText() .. ". " ..
        Score .. " mission score!",
        MESSAGE.Type.Information ):ToAll()

      self:ScoreCSV( PlayerName, "", "MISSION_" .. MissionName:gsub( ' ', '_' ), 1, Score )
    end
  end
end



--- Handles the OnPlayerEnterUnit event for the scoring.
-- @param #SCORING self
-- @param Core.Event#EVENTDATA Event
--function SCORING:OnEventPlayerEnterUnit( Event )
--  if Event.IniUnit then
--    self:_AddPlayerFromUnit( Event.IniUnit )
--    self:SetScoringMenu( Event.IniGroup )
--  end
--end

--- Handles the OnBirth event for the scoring.
-- @param #SCORING self
-- @param Core.Event#EVENTDATA Event
function SCORING:OnEventBirth( Event )
  
  if Event.IniUnit then
    if Event.IniObjectCategory == 1 then
      local PlayerName = Event.IniUnit:GetPlayerName()
      if PlayerName then
        self:_AddPlayerFromUnit( Event.IniUnit )
        self:SetScoringMenu( Event.IniGroup )
      end
    end
  end
end

--- Handles the OnPlayerLeaveUnit event for the scoring.
-- @param #SCORING self
-- @param Core.Event#EVENTDATA Event
function SCORING:OnEventPlayerLeaveUnit( Event )
  if Event.IniUnit then
    local Menu = self:GetState( Event.IniUnit:GetGroup(), "ScoringMenu" ) -- Core.Menu#MENU_GROUP
    if Menu then
      -- TODO: Check if this fixes #281.
      --Menu:Remove()
    end
  end
end


--- Handles the OnHit event for the scoring.
-- @param #SCORING self
-- @param Core.Event#EVENTDATA Event
function SCORING:_EventOnHit( Event )
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
    --TODO: Workaround Client DCS Bug
    --InitCategory = InitUnit:getCategory()
    --InitCategory = InitUnit:getDesc().category
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
    --TODO: Workaround Client DCS Bug
    --TargetCategory = TargetUnit:getCategory()
    --TargetCategory = TargetUnit:getDesc().category
    TargetCategory = Event.TgtCategory
    TargetType = Event.TgtTypeName

    TargetUnitCoalition = _SCORINGCoalition[TargetCoalition]
    TargetUnitCategory = _SCORINGCategory[TargetCategory]
    TargetUnitType = TargetType

    self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType, TargetUnitCoalition, TargetUnitCategory, TargetUnitType } )
  end

  if InitPlayerName ~= nil then -- It is a player that is hitting something
    self:_AddPlayerFromUnit( InitUNIT )
    if self.Players[InitPlayerName] then -- This should normally not happen, but i'll test it anyway.
      if TargetPlayerName ~= nil then -- It is a player hitting another player ...
        self:_AddPlayerFromUnit( TargetUNIT )
      end

      self:T( "Hitting Something" )
      
      -- What is he hitting?
      if TargetCategory then
  
        -- A target got hit, score it.
        -- Player contains the score data from self.Players[InitPlayerName]
        local Player = self.Players[InitPlayerName]
        
        -- Ensure there is a hit table per TargetCategory and TargetUnitName.
        Player.Hit[TargetCategory] = Player.Hit[TargetCategory] or {}
        Player.Hit[TargetCategory][TargetUnitName] = Player.Hit[TargetCategory][TargetUnitName] or {}
        
        -- PlayerHit contains the score counters and data per unit that was hit.
        local PlayerHit = Player.Hit[TargetCategory][TargetUnitName]
         
        PlayerHit.Score = PlayerHit.Score or 0
        PlayerHit.Penalty = PlayerHit.Penalty or 0
        PlayerHit.ScoreHit = PlayerHit.ScoreHit or 0
        PlayerHit.PenaltyHit = PlayerHit.PenaltyHit or 0
        PlayerHit.TimeStamp = PlayerHit.TimeStamp or 0
        PlayerHit.UNIT = PlayerHit.UNIT or TargetUNIT
        PlayerHit.ThreatLevel, PlayerHit.ThreatType = PlayerHit.UNIT:GetThreatLevel()

        -- Only grant hit scores if there was more than one second between the last hit.        
        if timer.getTime() - PlayerHit.TimeStamp > 1 then
          PlayerHit.TimeStamp = timer.getTime()
        
          if TargetPlayerName ~= nil then -- It is a player hitting another player ...
    
            -- Ensure there is a Player to Player hit reference table.
            Player.HitPlayers[TargetPlayerName] = true
          end
          
          local Score = 0
          
          if InitCoalition then -- A coalition object was hit.
            if InitCoalition == TargetCoalition then
              Player.Penalty = Player.Penalty + 10
              PlayerHit.Penalty = PlayerHit.Penalty + 10
              PlayerHit.PenaltyHit = PlayerHit.PenaltyHit + 1
      
              if TargetPlayerName ~= nil then -- It is a player hitting another player ...
                MESSAGE
                  :NewType( self.DisplayMessagePrefix .. "Player '" .. InitPlayerName .. "' hit friendly player '" .. TargetPlayerName .. "' " .. 
                        TargetUnitCategory .. " ( " .. TargetType .. " ) " .. PlayerHit.PenaltyHit .. " times. " .. 
                        "Penalty: -" .. PlayerHit.Penalty .. ".  Score Total:" .. Player.Score - Player.Penalty,
                        MESSAGE.Type.Update
                      )
                  :ToAllIf( self:IfMessagesHit() and self:IfMessagesToAll() )
                  :ToCoalitionIf( InitCoalition, self:IfMessagesHit() and self:IfMessagesToCoalition() )
              else
                MESSAGE
                  :NewType( self.DisplayMessagePrefix .. "Player '" .. InitPlayerName .. "' hit friendly target " .. 
                        TargetUnitCategory .. " ( " .. TargetType .. " ) " .. PlayerHit.PenaltyHit .. " times. " .. 
                        "Penalty: -" .. PlayerHit.Penalty .. ".  Score Total:" .. Player.Score - Player.Penalty,
                        MESSAGE.Type.Update
                      )
                  :ToAllIf( self:IfMessagesHit() and self:IfMessagesToAll() )
                  :ToCoalitionIf( InitCoalition, self:IfMessagesHit() and self:IfMessagesToCoalition() )
              end
              self:ScoreCSV( InitPlayerName, TargetPlayerName, "HIT_PENALTY", 1, -10, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
            else
              Player.Score = Player.Score + 1
              PlayerHit.Score = PlayerHit.Score + 1
              PlayerHit.ScoreHit = PlayerHit.ScoreHit + 1
              if TargetPlayerName ~= nil then -- It is a player hitting another player ...
                MESSAGE
                  :NewType( self.DisplayMessagePrefix .. "Player '" .. InitPlayerName .. "' hit enemy player '" .. TargetPlayerName .. "' "  .. 
                        TargetUnitCategory .. " ( " .. TargetType .. " ) " .. PlayerHit.ScoreHit .. " times. " .. 
                        "Score: " .. PlayerHit.Score .. ".  Score Total:" .. Player.Score - Player.Penalty,
                        MESSAGE.Type.Update
                      )
                  :ToAllIf( self:IfMessagesHit() and self:IfMessagesToAll() )
                  :ToCoalitionIf( InitCoalition, self:IfMessagesHit() and self:IfMessagesToCoalition() )
              else
                MESSAGE
                  :NewType( self.DisplayMessagePrefix .. "Player '" .. InitPlayerName .. "' hit enemy target " .. 
                        TargetUnitCategory .. " ( " .. TargetType .. " ) " .. PlayerHit.ScoreHit .. " times. " .. 
                        "Score: " .. PlayerHit.Score .. ".  Score Total:" .. Player.Score - Player.Penalty,
                        MESSAGE.Type.Update
                      )
                  :ToAllIf( self:IfMessagesHit() and self:IfMessagesToAll() )
                  :ToCoalitionIf( InitCoalition, self:IfMessagesHit() and self:IfMessagesToCoalition() )
              end
              self:ScoreCSV( InitPlayerName, TargetPlayerName, "HIT_SCORE", 1, 1, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
            end
          else -- A scenery object was hit.
            MESSAGE
              :NewType( self.DisplayMessagePrefix .. "Player '" .. InitPlayerName .. "' hit scenery object.",
                    MESSAGE.Type.Update
                  )
              :ToAllIf( self:IfMessagesHit() and self:IfMessagesToAll() )
              :ToCoalitionIf( InitCoalition, self:IfMessagesHit() and self:IfMessagesToCoalition() )
            self:ScoreCSV( InitPlayerName, "", "HIT_SCORE", 1, 0, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, "", "Scenery", TargetUnitType )
          end
        end
      end
    end
  elseif InitPlayerName == nil then -- It is an AI hitting a player???

  end
  
  -- It is a weapon initiated by a player, that is hitting something
  -- This seems to occur only with scenery and static objects.
  if Event.WeaponPlayerName ~= nil then 
    self:_AddPlayerFromUnit( Event.WeaponUNIT )
    if self.Players[Event.WeaponPlayerName] then -- This should normally not happen, but i'll test it anyway.
      if TargetPlayerName ~= nil then -- It is a player hitting another player ...
        self:_AddPlayerFromUnit( TargetUNIT )
      end

      self:T( "Hitting Scenery" )
    
      -- What is he hitting?
      if TargetCategory then
  
        -- A scenery or static got hit, score it.
        -- Player contains the score data from self.Players[WeaponPlayerName]
        local Player = self.Players[Event.WeaponPlayerName]
        
        -- Ensure there is a hit table per TargetCategory and TargetUnitName.
        Player.Hit[TargetCategory] = Player.Hit[TargetCategory] or {}
        Player.Hit[TargetCategory][TargetUnitName] = Player.Hit[TargetCategory][TargetUnitName] or {}
        
        -- PlayerHit contains the score counters and data per unit that was hit.
        local PlayerHit = Player.Hit[TargetCategory][TargetUnitName]
         
        PlayerHit.Score = PlayerHit.Score or 0
        PlayerHit.Penalty = PlayerHit.Penalty or 0
        PlayerHit.ScoreHit = PlayerHit.ScoreHit or 0
        PlayerHit.PenaltyHit = PlayerHit.PenaltyHit or 0
        PlayerHit.TimeStamp = PlayerHit.TimeStamp or 0
        PlayerHit.UNIT = PlayerHit.UNIT or TargetUNIT
        PlayerHit.ThreatLevel, PlayerHit.ThreatType = PlayerHit.UNIT:GetThreatLevel()

        -- Only grant hit scores if there was more than one second between the last hit.        
        if timer.getTime() - PlayerHit.TimeStamp > 1 then
          PlayerHit.TimeStamp = timer.getTime()
          
          local Score = 0
          
          if InitCoalition then -- A coalition object was hit, probably a static.
            if InitCoalition == TargetCoalition then
              -- TODO: Penalty according scale
              Player.Penalty = Player.Penalty + 10
              PlayerHit.Penalty = PlayerHit.Penalty + 10
              PlayerHit.PenaltyHit = PlayerHit.PenaltyHit + 1
      
              MESSAGE
                :NewType( self.DisplayMessagePrefix .. "Player '" .. Event.WeaponPlayerName .. "' hit friendly target " .. 
                      TargetUnitCategory .. " ( " .. TargetType .. " ) " .. 
                      "Penalty: -" .. PlayerHit.Penalty .. " = " .. Player.Score - Player.Penalty,
                      MESSAGE.Type.Update
                    )
                :ToAllIf( self:IfMessagesHit() and self:IfMessagesToAll() )
                :ToCoalitionIf( Event.WeaponCoalition, self:IfMessagesHit() and self:IfMessagesToCoalition() )
              self:ScoreCSV( Event.WeaponPlayerName, TargetPlayerName, "HIT_PENALTY", 1, -10, Event.WeaponName, Event.WeaponCoalition, Event.WeaponCategory, Event.WeaponTypeName, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
            else
              Player.Score = Player.Score + 1
              PlayerHit.Score = PlayerHit.Score + 1
              PlayerHit.ScoreHit = PlayerHit.ScoreHit + 1
              MESSAGE
                :NewType( self.DisplayMessagePrefix .. "Player '" .. Event.WeaponPlayerName .. "' hit enemy target " .. 
                      TargetUnitCategory .. " ( " .. TargetType .. " ) " .. 
                      "Score: +" .. PlayerHit.Score .. " = " .. Player.Score - Player.Penalty,
                      MESSAGE.Type.Update
                    )
                :ToAllIf( self:IfMessagesHit() and self:IfMessagesToAll() )
                :ToCoalitionIf( Event.WeaponCoalition, self:IfMessagesHit() and self:IfMessagesToCoalition() )
              self:ScoreCSV( Event.WeaponPlayerName, TargetPlayerName, "HIT_SCORE", 1, 1, Event.WeaponName, Event.WeaponCoalition, Event.WeaponCategory, Event.WeaponTypeName, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
            end
          else -- A scenery object was hit.
            MESSAGE
              :NewType( self.DisplayMessagePrefix .. "Player '" .. Event.WeaponPlayerName .. "' hit scenery object.",
                    MESSAGE.Type.Update
                  )
              :ToAllIf( self:IfMessagesHit() and self:IfMessagesToAll() )
              :ToCoalitionIf( InitCoalition, self:IfMessagesHit() and self:IfMessagesToCoalition() )
            self:ScoreCSV( Event.WeaponPlayerName, "", "HIT_SCORE", 1, 0, Event.WeaponName, Event.WeaponCoalition, Event.WeaponCategory, Event.WeaponTypeName, TargetUnitName, "", "Scenery", TargetUnitType )
          end
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
    --TargetCategory = TargetUnit:getCategory()
    --TargetCategory = TargetUnit:getDesc().category  -- Workaround
    TargetCategory = Event.IniCategory
    TargetType = Event.IniTypeName

    TargetUnitCoalition = _SCORINGCoalition[TargetCoalition]
    TargetUnitCategory = _SCORINGCategory[TargetCategory]
    TargetUnitType = TargetType

    self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType } )
  end

  -- Player contains the score and reference data for the player.
  for PlayerName, Player in pairs( self.Players ) do
    if Player then -- This should normally not happen, but i'll test it anyway.
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

      -- What is the player destroying?
      if Player and Player.Hit and Player.Hit[TargetCategory] and Player.Hit[TargetCategory][TargetUnitName] and Player.Hit[TargetCategory][TargetUnitName].TimeStamp ~= 0 then -- Was there a hit for this unit for this player before registered???
        
        local TargetThreatLevel = Player.Hit[TargetCategory][TargetUnitName].ThreatLevel
        local TargetThreatType = Player.Hit[TargetCategory][TargetUnitName].ThreatType
        
        Player.Destroy[TargetCategory] = Player.Destroy[TargetCategory] or {}
        Player.Destroy[TargetCategory][TargetType] = Player.Destroy[TargetCategory][TargetType] or {}

        -- PlayerDestroy contains the destroy score data per category and target type of the player.
        local TargetDestroy = Player.Destroy[TargetCategory][TargetType]
        TargetDestroy.Score = TargetDestroy.Score or 0
        TargetDestroy.ScoreDestroy = TargetDestroy.ScoreDestroy or 0
        TargetDestroy.Penalty =  TargetDestroy.Penalty or 0
        TargetDestroy.PenaltyDestroy = TargetDestroy.PenaltyDestroy or 0

        if TargetCoalition then
          if InitCoalition == TargetCoalition then
            local ThreatLevelTarget = TargetThreatLevel
            local ThreatTypeTarget = TargetThreatType
            local ThreatLevelPlayer = Player.ThreatLevel / 10 + 1
            local ThreatPenalty = math.ceil( ( ThreatLevelTarget / ThreatLevelPlayer ) * self.ScaleDestroyPenalty / 10 )
            self:F( { ThreatLevel = ThreatPenalty, ThreatLevelTarget = ThreatLevelTarget, ThreatTypeTarget = ThreatTypeTarget, ThreatLevelPlayer = ThreatLevelPlayer  } )
            
            Player.Penalty = Player.Penalty + ThreatPenalty
            TargetDestroy.Penalty = TargetDestroy.Penalty + ThreatPenalty
            TargetDestroy.PenaltyDestroy = TargetDestroy.PenaltyDestroy + 1
            
            if Player.HitPlayers[TargetPlayerName] then -- A player destroyed another player
              MESSAGE
                :NewType( self.DisplayMessagePrefix .. "Player '" .. PlayerName .. "' destroyed friendly player '" .. TargetPlayerName .. "' " .. 
                      TargetUnitCategory .. " ( " .. ThreatTypeTarget .. " ) " .. 
                      "Penalty: -" .. TargetDestroy.Penalty .. " = " .. Player.Score - Player.Penalty,
                      MESSAGE.Type.Information 
                    )
                :ToAllIf( self:IfMessagesDestroy() and self:IfMessagesToAll() )
                :ToCoalitionIf( InitCoalition, self:IfMessagesDestroy() and self:IfMessagesToCoalition() )
            else
              MESSAGE
                :NewType( self.DisplayMessagePrefix .. "Player '" .. PlayerName .. "' destroyed friendly target " .. 
                      TargetUnitCategory .. " ( " .. ThreatTypeTarget .. " ) " .. 
                      "Penalty: -" .. TargetDestroy.Penalty .. " = " .. Player.Score - Player.Penalty,
                      MESSAGE.Type.Information 
                    )
                :ToAllIf( self:IfMessagesDestroy() and self:IfMessagesToAll() )
                :ToCoalitionIf( InitCoalition, self:IfMessagesDestroy() and self:IfMessagesToCoalition() )
            end

            Destroyed = true
            self:ScoreCSV( PlayerName, TargetPlayerName, "DESTROY_PENALTY", 1, ThreatPenalty, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
          else

            local ThreatLevelTarget = TargetThreatLevel
            local ThreatTypeTarget = TargetThreatType
            local ThreatLevelPlayer = Player.ThreatLevel / 10 + 1
            local ThreatScore = math.ceil( ( ThreatLevelTarget / ThreatLevelPlayer )  * self.ScaleDestroyScore / 10 )
            
            self:F( { ThreatLevel = ThreatScore, ThreatLevelTarget = ThreatLevelTarget, ThreatTypeTarget = ThreatTypeTarget, ThreatLevelPlayer = ThreatLevelPlayer  } )
  
            Player.Score = Player.Score + ThreatScore
            TargetDestroy.Score = TargetDestroy.Score + ThreatScore
            TargetDestroy.ScoreDestroy = TargetDestroy.ScoreDestroy + 1
            if Player.HitPlayers[TargetPlayerName] then -- A player destroyed another player
              MESSAGE
                :NewType( self.DisplayMessagePrefix .. "Player '" .. PlayerName .. "' destroyed enemy player '" .. TargetPlayerName .. "' " .. 
                      TargetUnitCategory .. " ( " .. ThreatTypeTarget .. " ) " .. 
                      "Score: +" .. TargetDestroy.Score .. " = " .. Player.Score - Player.Penalty,
                      MESSAGE.Type.Information 
                    )
                :ToAllIf( self:IfMessagesDestroy() and self:IfMessagesToAll() )
                :ToCoalitionIf( InitCoalition, self:IfMessagesDestroy() and self:IfMessagesToCoalition() )
            else
              MESSAGE
                :NewType( self.DisplayMessagePrefix .. "Player '" .. PlayerName .. "' destroyed enemy " .. 
                      TargetUnitCategory .. " ( " .. ThreatTypeTarget .. " ) " .. 
                      "Score: +" .. TargetDestroy.Score .. " = " .. Player.Score - Player.Penalty,
                      MESSAGE.Type.Information 
                    )
                :ToAllIf( self:IfMessagesDestroy() and self:IfMessagesToAll() )
                :ToCoalitionIf( InitCoalition, self:IfMessagesDestroy() and self:IfMessagesToCoalition() )
            end
            Destroyed = true
            self:ScoreCSV( PlayerName, TargetPlayerName, "DESTROY_SCORE", 1, ThreatScore, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
            
            local UnitName = TargetUnit:GetName()
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
              self:ScoreCSV( PlayerName, TargetPlayerName, "DESTROY_SCORE", 1, Score, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
              Destroyed = true
            end
            
            -- Check if there are Zones where the destruction happened.
            for ZoneName, ScoreZoneData in pairs( self.ScoringZones ) do
              self:F( { ScoringZone = ScoreZoneData } )
              local ScoreZone = ScoreZoneData.ScoreZone -- Core.Zone#ZONE_BASE
              local Score = ScoreZoneData.Score
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
                self:ScoreCSV( PlayerName, TargetPlayerName, "DESTROY_SCORE", 1, Score, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
                Destroyed = true
              end
            end
                          
          end
        else
          -- Check if there are Zones where the destruction happened.
          for ZoneName, ScoreZoneData in pairs( self.ScoringZones ) do
              self:F( { ScoringZone = ScoreZoneData } )
            local ScoreZone = ScoreZoneData.ScoreZone -- Core.Zone#ZONE_BASE
            local Score = ScoreZoneData.Score
            if ScoreZone:IsVec2InZone( TargetUnit:GetVec2() ) then
              Player.Score = Player.Score + Score
              TargetDestroy.Score = TargetDestroy.Score + Score
              MESSAGE
                :NewType( self.DisplayMessagePrefix .. "Scenery destroyed in zone '" .. ScoreZone:GetName() .. "'." .. 
                      "Player '" .. PlayerName .. "' receives an extra " .. Score .. " points! " .. 
                      "Total: " .. Player.Score - Player.Penalty, 
                      MESSAGE.Type.Information 
                    )
                :ToAllIf( self:IfMessagesZone() and self:IfMessagesToAll() )
                :ToCoalitionIf( InitCoalition, self:IfMessagesZone() and self:IfMessagesToCoalition() )
              Destroyed = true
              self:ScoreCSV( PlayerName, "", "DESTROY_SCORE", 1, Score, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, "", "Scenery", TargetUnitType )
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


--- Produce detailed report of player hit scores.
-- @param #SCORING self
-- @param #string PlayerName The name of the player.
-- @return #string The report.
function SCORING:ReportDetailedPlayerHits( PlayerName )

  local ScoreMessage = ""
  local PlayerScore = 0
  local PlayerPenalty = 0

  local PlayerData = self.Players[PlayerName]
  if PlayerData then -- This should normally not happen, but i'll test it anyway.
    self:T( "Score Player: " .. PlayerName )

    -- Some variables
    local InitUnitCoalition = _SCORINGCoalition[PlayerData.UnitCoalition]
    local InitUnitCategory = _SCORINGCategory[PlayerData.UnitCategory]
    local InitUnitType = PlayerData.UnitType
    local InitUnitName = PlayerData.UnitName

    local ScoreMessageHits = ""
    for CategoryID, CategoryName in pairs( _SCORINGCategory ) do
      self:T( CategoryName )
      if PlayerData.Hit[CategoryID] then
        self:T( "Hit scores exist for player " .. PlayerName )
        local Score = 0
        local ScoreHit = 0
        local Penalty = 0
        local PenaltyHit = 0
        for UnitName, UnitData in pairs( PlayerData.Hit[CategoryID] ) do
          Score = Score + UnitData.Score
          ScoreHit = ScoreHit + UnitData.ScoreHit
          Penalty = Penalty + UnitData.Penalty
          PenaltyHit = UnitData.PenaltyHit
        end
        local ScoreMessageHit = string.format( "%s:%d  ", CategoryName, Score - Penalty )
        self:T( ScoreMessageHit )
        ScoreMessageHits = ScoreMessageHits .. ScoreMessageHit
        PlayerScore = PlayerScore + Score
        PlayerPenalty = PlayerPenalty + Penalty
      else
       --ScoreMessageHits = ScoreMessageHits .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
      end
    end
    if ScoreMessageHits ~= "" then
      ScoreMessage = "Hits: " .. ScoreMessageHits
    end
  end
  
  return ScoreMessage, PlayerScore, PlayerPenalty
end


--- Produce detailed report of player destroy scores.
-- @param #SCORING self
-- @param #string PlayerName The name of the player.
-- @return #string The report.
function SCORING:ReportDetailedPlayerDestroys( PlayerName )

  local ScoreMessage = ""
  local PlayerScore = 0
  local PlayerPenalty = 0

  local PlayerData = self.Players[PlayerName]
  if PlayerData then -- This should normally not happen, but i'll test it anyway.
    self:T( "Score Player: " .. PlayerName )

    -- Some variables
    local InitUnitCoalition = _SCORINGCoalition[PlayerData.UnitCoalition]
    local InitUnitCategory = _SCORINGCategory[PlayerData.UnitCategory]
    local InitUnitType = PlayerData.UnitType
    local InitUnitName = PlayerData.UnitName

    local ScoreMessageDestroys = ""
    for CategoryID, CategoryName in pairs( _SCORINGCategory ) do
      if PlayerData.Destroy[CategoryID] then
        self:T( "Destroy scores exist for player " .. PlayerName )
        local Score = 0
        local ScoreDestroy = 0
        local Penalty = 0
        local PenaltyDestroy = 0

        for UnitName, UnitData in pairs( PlayerData.Destroy[CategoryID] ) do
          self:F( { UnitData = UnitData } )
          if UnitData ~= {} then
            Score = Score + UnitData.Score
            ScoreDestroy = ScoreDestroy + UnitData.ScoreDestroy
            Penalty = Penalty + UnitData.Penalty
            PenaltyDestroy = PenaltyDestroy + UnitData.PenaltyDestroy
          end
        end

        local ScoreMessageDestroy = string.format( "  %s:%d  ", CategoryName, Score - Penalty )
        self:T( ScoreMessageDestroy )
        ScoreMessageDestroys = ScoreMessageDestroys .. ScoreMessageDestroy

        PlayerScore = PlayerScore + Score
        PlayerPenalty = PlayerPenalty + Penalty
      else
        --ScoreMessageDestroys = ScoreMessageDestroys .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
      end
    end
    if ScoreMessageDestroys ~= "" then
      ScoreMessage = "Destroys: " .. ScoreMessageDestroys
    end
  end

  return ScoreMessage, PlayerScore, PlayerPenalty
end

--- Produce detailed report of player penalty scores because of changing the coalition.
-- @param #SCORING self
-- @param #string PlayerName The name of the player.
-- @return #string The report.
function SCORING:ReportDetailedPlayerCoalitionChanges( PlayerName )

  local ScoreMessage = ""
  local PlayerScore = 0
  local PlayerPenalty = 0

  local PlayerData = self.Players[PlayerName]
  if PlayerData then -- This should normally not happen, but i'll test it anyway.
    self:T( "Score Player: " .. PlayerName )

    -- Some variables
    local InitUnitCoalition = _SCORINGCoalition[PlayerData.UnitCoalition]
    local InitUnitCategory = _SCORINGCategory[PlayerData.UnitCategory]
    local InitUnitType = PlayerData.UnitType
    local InitUnitName = PlayerData.UnitName

    local ScoreMessageCoalitionChangePenalties = ""
    if PlayerData.PenaltyCoalition ~= 0 then
      ScoreMessageCoalitionChangePenalties = ScoreMessageCoalitionChangePenalties .. string.format( " -%d (%d changed)", PlayerData.Penalty, PlayerData.PenaltyCoalition )
      PlayerPenalty = PlayerPenalty + PlayerData.Penalty
    end
    if ScoreMessageCoalitionChangePenalties ~= "" then
      ScoreMessage = ScoreMessage .. "Coalition Penalties: " .. ScoreMessageCoalitionChangePenalties
    end
  end
  
  return ScoreMessage, PlayerScore, PlayerPenalty
end

--- Produce detailed report of player goal scores.
-- @param #SCORING self
-- @param #string PlayerName The name of the player.
-- @return #string The report.
function SCORING:ReportDetailedPlayerGoals( PlayerName )

  local ScoreMessage = ""
  local PlayerScore = 0
  local PlayerPenalty = 0

  local PlayerData = self.Players[PlayerName]
  if PlayerData then -- This should normally not happen, but i'll test it anyway.
    self:T( "Score Player: " .. PlayerName )

    -- Some variables
    local InitUnitCoalition = _SCORINGCoalition[PlayerData.UnitCoalition]
    local InitUnitCategory = _SCORINGCategory[PlayerData.UnitCategory]
    local InitUnitType = PlayerData.UnitType
    local InitUnitName = PlayerData.UnitName

    local ScoreMessageGoal = ""
    local ScoreGoal = 0
    local ScoreTask = 0
    for GoalName, GoalData in pairs( PlayerData.Goals ) do
      ScoreGoal = ScoreGoal + GoalData.Score
      ScoreMessageGoal = ScoreMessageGoal .. "'" .. GoalName .. "':" .. GoalData.Score .. "; "
    end
    PlayerScore = PlayerScore + ScoreGoal

    if ScoreMessageGoal ~= "" then
      ScoreMessage = "Goals: " .. ScoreMessageGoal
    end
  end
  
  return ScoreMessage, PlayerScore, PlayerPenalty
end

--- Produce detailed report of player penalty scores because of changing the coalition.
-- @param #SCORING self
-- @param #string PlayerName The name of the player.
-- @return #string The report.
function SCORING:ReportDetailedPlayerMissions( PlayerName )

  local ScoreMessage = ""
  local PlayerScore = 0
  local PlayerPenalty = 0

  local PlayerData = self.Players[PlayerName]
  if PlayerData then -- This should normally not happen, but i'll test it anyway.
    self:T( "Score Player: " .. PlayerName )

    -- Some variables
    local InitUnitCoalition = _SCORINGCoalition[PlayerData.UnitCoalition]
    local InitUnitCategory = _SCORINGCategory[PlayerData.UnitCategory]
    local InitUnitType = PlayerData.UnitType
    local InitUnitName = PlayerData.UnitName

    local ScoreMessageMission = ""
    local ScoreMission = 0
    local ScoreTask = 0
    for MissionName, MissionData in pairs( PlayerData.Mission ) do
      ScoreMission = ScoreMission + MissionData.ScoreMission
      ScoreTask = ScoreTask + MissionData.ScoreTask
      ScoreMessageMission = ScoreMessageMission .. "'" .. MissionName .. "'; "
    end
    PlayerScore = PlayerScore + ScoreMission + ScoreTask

    if ScoreMessageMission ~= "" then
      ScoreMessage = "Tasks: " .. ScoreTask .. " Mission: " .. ScoreMission .. " ( " .. ScoreMessageMission .. ")"
    end
  end
  
  return ScoreMessage, PlayerScore, PlayerPenalty
end


--- Report Group Score Summary
-- @param #SCORING self
-- @param Wrapper.Group#GROUP PlayerGroup The player group.
function SCORING:ReportScoreGroupSummary( PlayerGroup )

  local PlayerMessage = ""

  self:T( "Report Score Group Summary" )

  local PlayerUnits = PlayerGroup:GetUnits()
  for UnitID, PlayerUnit in pairs( PlayerUnits ) do
    local PlayerUnit = PlayerUnit -- Wrapper.Unit#UNIT
    local PlayerName = PlayerUnit:GetPlayerName()
    
    if PlayerName then
    
      local ReportHits, ScoreHits, PenaltyHits = self:ReportDetailedPlayerHits( PlayerName )
      ReportHits = ReportHits ~= "" and "\n- " .. ReportHits or ReportHits 
      self:F( { ReportHits, ScoreHits, PenaltyHits } )

      local ReportDestroys, ScoreDestroys, PenaltyDestroys = self:ReportDetailedPlayerDestroys( PlayerName )
      ReportDestroys = ReportDestroys ~= "" and "\n- " .. ReportDestroys or ReportDestroys
      self:F( { ReportDestroys, ScoreDestroys, PenaltyDestroys } )

      local ReportCoalitionChanges, ScoreCoalitionChanges, PenaltyCoalitionChanges = self:ReportDetailedPlayerCoalitionChanges( PlayerName )
      ReportCoalitionChanges = ReportCoalitionChanges ~= "" and "\n- " .. ReportCoalitionChanges or ReportCoalitionChanges
      self:F( { ReportCoalitionChanges, ScoreCoalitionChanges, PenaltyCoalitionChanges } )

      local ReportGoals, ScoreGoals, PenaltyGoals = self:ReportDetailedPlayerGoals( PlayerName )
      ReportGoals = ReportGoals ~= "" and "\n- " .. ReportGoals or ReportGoals
      self:F( { ReportGoals, ScoreGoals, PenaltyGoals } )

      local ReportMissions, ScoreMissions, PenaltyMissions = self:ReportDetailedPlayerMissions( PlayerName )
      ReportMissions = ReportMissions ~= "" and "\n- " .. ReportMissions or ReportMissions
      self:F( { ReportMissions, ScoreMissions, PenaltyMissions } )
      
      local PlayerScore = ScoreHits + ScoreDestroys + ScoreCoalitionChanges + ScoreGoals + ScoreMissions
      local PlayerPenalty = PenaltyHits + PenaltyDestroys + PenaltyCoalitionChanges + PenaltyGoals + PenaltyMissions
  
      PlayerMessage = 
        string.format( "Player '%s' Score = %d ( %d Score, -%d Penalties )", 
                       PlayerName, 
                       PlayerScore - PlayerPenalty, 
                       PlayerScore, 
                       PlayerPenalty
                     )
      MESSAGE:NewType( PlayerMessage, MESSAGE.Type.Detailed ):ToGroup( PlayerGroup )
    end
  end

end

--- Report Group Score Detailed
-- @param #SCORING self
-- @param Wrapper.Group#GROUP PlayerGroup The player group.
function SCORING:ReportScoreGroupDetailed( PlayerGroup )

  local PlayerMessage = ""

  self:T( "Report Score Group Detailed" )

  local PlayerUnits = PlayerGroup:GetUnits()
  for UnitID, PlayerUnit in pairs( PlayerUnits ) do
    local PlayerUnit = PlayerUnit -- Wrapper.Unit#UNIT
    local PlayerName = PlayerUnit:GetPlayerName()
    
    if PlayerName then
    
      local ReportHits, ScoreHits, PenaltyHits = self:ReportDetailedPlayerHits( PlayerName )
      ReportHits = ReportHits ~= "" and "\n- " .. ReportHits or ReportHits 
      self:F( { ReportHits, ScoreHits, PenaltyHits } )

      local ReportDestroys, ScoreDestroys, PenaltyDestroys = self:ReportDetailedPlayerDestroys( PlayerName )
      ReportDestroys = ReportDestroys ~= "" and "\n- " .. ReportDestroys or ReportDestroys
      self:F( { ReportDestroys, ScoreDestroys, PenaltyDestroys } )

      local ReportCoalitionChanges, ScoreCoalitionChanges, PenaltyCoalitionChanges = self:ReportDetailedPlayerCoalitionChanges( PlayerName )
      ReportCoalitionChanges = ReportCoalitionChanges ~= "" and "\n- " .. ReportCoalitionChanges or ReportCoalitionChanges
      self:F( { ReportCoalitionChanges, ScoreCoalitionChanges, PenaltyCoalitionChanges } )
      
      local ReportGoals, ScoreGoals, PenaltyGoals = self:ReportDetailedPlayerGoals( PlayerName )
      ReportGoals = ReportGoals ~= "" and "\n- " .. ReportGoals or ReportGoals
      self:F( { ReportGoals, ScoreGoals, PenaltyGoals } )

      local ReportMissions, ScoreMissions, PenaltyMissions = self:ReportDetailedPlayerMissions( PlayerName )
      ReportMissions = ReportMissions ~= "" and "\n- " .. ReportMissions or ReportMissions
      self:F( { ReportMissions, ScoreMissions, PenaltyMissions } )
      
      local PlayerScore = ScoreHits + ScoreDestroys + ScoreCoalitionChanges + ScoreGoals + ScoreMissions
      local PlayerPenalty = PenaltyHits + PenaltyDestroys + PenaltyCoalitionChanges + ScoreGoals + PenaltyMissions
  
      PlayerMessage = 
        string.format( "Player '%s' Score = %d ( %d Score, -%d Penalties )%s%s%s%s%s", 
                       PlayerName, 
                       PlayerScore - PlayerPenalty, 
                       PlayerScore, 
                       PlayerPenalty, 
                       ReportHits,
                       ReportDestroys,
                       ReportCoalitionChanges,
                       ReportGoals,
                       ReportMissions
                     )
      MESSAGE:NewType( PlayerMessage, MESSAGE.Type.Detailed ):ToGroup( PlayerGroup )
    end
  end

end

--- Report all players score
-- @param #SCORING self
-- @param Wrapper.Group#GROUP PlayerGroup The player group.
function SCORING:ReportScoreAllSummary( PlayerGroup )

  local PlayerMessage = ""

  self:T( { "Summary Score Report of All Players", Players = self.Players } )

  for PlayerName, PlayerData in pairs( self.Players ) do
  
    self:T( { PlayerName = PlayerName, PlayerGroup = PlayerGroup } )
    
    if PlayerName then
    
      local ReportHits, ScoreHits, PenaltyHits = self:ReportDetailedPlayerHits( PlayerName )
      ReportHits = ReportHits ~= "" and "\n- " .. ReportHits or ReportHits 
      self:F( { ReportHits, ScoreHits, PenaltyHits } )

      local ReportDestroys, ScoreDestroys, PenaltyDestroys = self:ReportDetailedPlayerDestroys( PlayerName )
      ReportDestroys = ReportDestroys ~= "" and "\n- " .. ReportDestroys or ReportDestroys
      self:F( { ReportDestroys, ScoreDestroys, PenaltyDestroys } )

      local ReportCoalitionChanges, ScoreCoalitionChanges, PenaltyCoalitionChanges = self:ReportDetailedPlayerCoalitionChanges( PlayerName )
      ReportCoalitionChanges = ReportCoalitionChanges ~= "" and "\n- " .. ReportCoalitionChanges or ReportCoalitionChanges
      self:F( { ReportCoalitionChanges, ScoreCoalitionChanges, PenaltyCoalitionChanges } )

      local ReportGoals, ScoreGoals, PenaltyGoals = self:ReportDetailedPlayerGoals( PlayerName )
      ReportGoals = ReportGoals ~= "" and "\n- " .. ReportGoals or ReportGoals
      self:F( { ReportGoals, ScoreGoals, PenaltyGoals } )

      local ReportMissions, ScoreMissions, PenaltyMissions = self:ReportDetailedPlayerMissions( PlayerName )
      ReportMissions = ReportMissions ~= "" and "\n- " .. ReportMissions or ReportMissions
      self:F( { ReportMissions, ScoreMissions, PenaltyMissions } )
      
      local PlayerScore = ScoreHits + ScoreDestroys + ScoreCoalitionChanges + ScoreGoals + ScoreMissions
      local PlayerPenalty = PenaltyHits + PenaltyDestroys + PenaltyCoalitionChanges + ScoreGoals + PenaltyMissions
  
      PlayerMessage = 
        string.format( "Player '%s' Score = %d ( %d Score, -%d Penalties )", 
                       PlayerName, 
                       PlayerScore - PlayerPenalty, 
                       PlayerScore, 
                       PlayerPenalty 
                     )
      MESSAGE:NewType( PlayerMessage, MESSAGE.Type.Overview ):ToGroup( PlayerGroup )
    end
  end

end


function SCORING:SecondsToClock(sSeconds)
  local nSeconds = sSeconds
  if nSeconds == 0 then
    --return nil;
    return "00:00:00";
  else
    nHours = string.format("%02.f", math.floor(nSeconds/3600));
    nMins = string.format("%02.f", math.floor(nSeconds/60 - (nHours*60)));
    nSecs = string.format("%02.f", math.floor(nSeconds - nHours*3600 - nMins *60));
    return nHours..":"..nMins..":"..nSecs
  end
end

--- Opens a score CSV file to log the scores.
-- @param #SCORING self
-- @param #string ScoringCSV
-- @return #SCORING self
-- @usage
-- -- Open a new CSV file to log the scores of the game Gori Valley. Let the name of the CSV file begin with "Player Scores".
-- ScoringObject = SCORING:New( "Gori Valley" )
-- ScoringObject:OpenCSV( "Player Scores" )
function SCORING:OpenCSV( ScoringCSV )
  self:F( ScoringCSV )
  
  if lfs and io and os then
    if ScoringCSV then
      self.ScoringCSV = ScoringCSV
      local fdir = lfs.writedir() .. [[Logs\]] .. self.ScoringCSV .. " " .. os.date( "%Y-%m-%d %H-%M-%S" ) .. ".csv"

      self.CSVFile, self.err = io.open( fdir, "w+" )
      if not self.CSVFile then
        error( "Error: Cannot open CSV file in " .. lfs.writedir() )
      end

      self.CSVFile:write( '"GameName","RunTime","Time","PlayerName","TargetPlayerName","ScoreType","PlayerUnitCoaltion","PlayerUnitCategory","PlayerUnitType","PlayerUnitName","TargetUnitCoalition","TargetUnitCategory","TargetUnitType","TargetUnitName","Times","Score"\n' )
  
      self.RunTime = os.date("%y-%m-%d_%H-%M-%S")
    else
      error( "A string containing the CSV file name must be given." )
    end
  else
    self:F( "The MissionScripting.lua file has not been changed to allow lfs, io and os modules to be used..." )
  end
  return self
end


--- Registers a score for a player.
-- @param #SCORING self
-- @param #string PlayerName The name of the player.
-- @param #string TargetPlayerName The name of the target player.
-- @param #string ScoreType The type of the score.
-- @param #string ScoreTimes The amount of scores achieved.
-- @param #string ScoreAmount The score given.
-- @param #string PlayerUnitName The unit name of the player.
-- @param #string PlayerUnitCoalition The coalition of the player unit.
-- @param #string PlayerUnitCategory The category of the player unit.
-- @param #string PlayerUnitType The type of the player unit.
-- @param #string TargetUnitName The name of the target unit.
-- @param #string TargetUnitCoalition The coalition of the target unit.
-- @param #string TargetUnitCategory The category of the target unit.
-- @param #string TargetUnitType The type of the target unit.
-- @return #SCORING self
function SCORING:ScoreCSV( PlayerName, TargetPlayerName, ScoreType, ScoreTimes, ScoreAmount, PlayerUnitName, PlayerUnitCoalition, PlayerUnitCategory, PlayerUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
  --write statistic information to file
  local ScoreTime = self:SecondsToClock( timer.getTime() )
  PlayerName = PlayerName:gsub( '"', '_' )
  
  TargetPlayerName = TargetPlayerName or ""
  TargetPlayerName = TargetPlayerName:gsub( '"', '_' )

  if PlayerUnitName and PlayerUnitName ~= '' then
    local PlayerUnit = Unit.getByName( PlayerUnitName )

    if PlayerUnit then
      if not PlayerUnitCategory then
        --PlayerUnitCategory = SCORINGCategory[PlayerUnit:getCategory()]
        PlayerUnitCategory = _SCORINGCategory[PlayerUnit:getDesc().category]
      end

      if not PlayerUnitCoalition then
        PlayerUnitCoalition = _SCORINGCoalition[PlayerUnit:getCoalition()]
      end

      if not PlayerUnitType then
        PlayerUnitType = PlayerUnit:getTypeName()
      end
    else
      PlayerUnitName = ''
      PlayerUnitCategory = ''
      PlayerUnitCoalition = ''
      PlayerUnitType = ''
    end
  else
    PlayerUnitName = ''
    PlayerUnitCategory = ''
    PlayerUnitCoalition = ''
    PlayerUnitType = ''
  end

  TargetUnitCoalition = TargetUnitCoalition or ""
  TargetUnitCategory = TargetUnitCategory or ""
  TargetUnitType = TargetUnitType or ""
  TargetUnitName = TargetUnitName or ""

  if lfs and io and os then
    self.CSVFile:write(
      '"' .. self.GameName        .. '"' .. ',' ..
      '"' .. self.RunTime         .. '"' .. ',' ..
      ''  .. ScoreTime            .. ''  .. ',' ..
      '"' .. PlayerName           .. '"' .. ',' ..
      '"' .. TargetPlayerName     .. '"' .. ',' ..
      '"' .. ScoreType            .. '"' .. ',' ..
      '"' .. PlayerUnitCoalition  .. '"' .. ',' ..
      '"' .. PlayerUnitCategory   .. '"' .. ',' ..
      '"' .. PlayerUnitType       .. '"' .. ',' ..
      '"' .. PlayerUnitName       .. '"' .. ',' ..
      '"' .. TargetUnitCoalition  .. '"' .. ',' ..
      '"' .. TargetUnitCategory   .. '"' .. ',' ..
      '"' .. TargetUnitType       .. '"' .. ',' ..
      '"' .. TargetUnitName       .. '"' .. ',' ..
      ''  .. ScoreTimes           .. ''  .. ',' ..
      ''  .. ScoreAmount
    )

    self.CSVFile:write( "\n" )
  end
end


function SCORING:CloseCSV()
  if lfs and io and os then
    self.CSVFile:close()
  end
end

