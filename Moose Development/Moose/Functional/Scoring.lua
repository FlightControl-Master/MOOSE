--- Scoring system for MOOSE.
-- This scoring class calculates the hits and kills that players make within a simulation session.
-- Scoring is calculated using a defined algorithm.
-- With a small change in MissionScripting.lua, the scoring can also be logged in a CSV file, that can then be uploaded
-- to a database or a BI tool to publish the scoring results to the player community.
-- @module Scoring
-- @author FlightControl


--- The Scoring class
-- @type SCORING
-- @field Players A collection of the current players that have joined the game.
-- @extends Core.Base#BASE
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
-- -- Define a new scoring object for the mission Gori Valley.
-- ScoringObject = SCORING:New( "Gori Valley" )
function SCORING:New( GameName )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  if GameName then 
    self.GameName = GameName
  else
    error( "A game name must be given to register the scoring results" )
  end
  
  
  self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
  self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
  self:HandleEvent( EVENTS.Hit, self._EventOnHit )

  --self.SchedulerId = routines.scheduleFunction( SCORING._FollowPlayersScheduled, { self }, 0, 5 )
  self.SchedulerId = SCHEDULER:New( self, self._FollowPlayersScheduled, {}, 0, 5 )

  self:ScoreMenu()
  
  self:OpenCSV( GameName)

  return self
  
end

--- Creates a score radio menu. Can be accessed using Radio -> F10.
-- @param #SCORING self
-- @return #SCORING self
function SCORING:ScoreMenu()
  self.Menu = MENU_MISSION:New( 'Scoring' )
  self.AllScoresMenu = MENU_MISSION_COMMAND:New( 'Score All Active Players', self.Menu, SCORING.ReportScoreAll, self )
  --- = COMMANDMENU:New('Your Current Score', ReportScore, SCORING.ReportScorePlayer, self )
  return self
end

--- Follows new players entering Clients within the DCSRTE.
-- TODO: Need to see if i can catch this also with an event. It will eliminate the schedule ...
function SCORING:_FollowPlayersScheduled()
  self:F3( "_FollowPlayersScheduled" )

  local ClientUnit = 0
  local CoalitionsData = { AlivePlayersRed = coalition.getPlayers(coalition.side.RED), AlivePlayersBlue = coalition.getPlayers(coalition.side.BLUE) }
  local unitId
  local unitData
  local AlivePlayerUnits = {}

  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    self:T3( { "_FollowPlayersScheduled", CoalitionData } )
    for UnitId, UnitData in pairs( CoalitionData ) do
      self:_AddPlayerFromUnit( UnitData )
    end
  end
  
  return true
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

    TargetUnit = Event.IniDCSUnit
    TargetUnitName = Event.IniDCSUnitName
    TargetGroup = Event.IniDCSGroup
    TargetGroupName = Event.IniDCSGroupName
    TargetPlayerName = Event.IniPlayerName

    TargetCoalition = TargetUnit:getCoalition()
    --TargetCategory = TargetUnit:getCategory()
    TargetCategory = TargetUnit:getDesc().category  -- Workaround
    TargetType = TargetUnit:getTypeName()

    TargetUnitCoalition = _SCORINGCoalition[TargetCoalition]
    TargetUnitCategory = _SCORINGCategory[TargetCategory]
    TargetUnitType = TargetType

    self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType } )
  end

  for PlayerName, PlayerData in pairs( self.Players ) do
    if PlayerData then -- This should normally not happen, but i'll test it anyway.
      self:T( "Something got killed" )

      -- Some variables
      local InitUnitName = PlayerData.UnitName
      local InitUnitType = PlayerData.UnitType
      local InitCoalition = PlayerData.UnitCoalition
      local InitCategory = PlayerData.UnitCategory
      local InitUnitCoalition = _SCORINGCoalition[InitCoalition]
      local InitUnitCategory = _SCORINGCategory[InitCategory]

      self:T( { InitUnitName, InitUnitType, InitUnitCoalition, InitCoalition, InitUnitCategory, InitCategory } )

      -- What is he hitting?
      if TargetCategory then
        if PlayerData and PlayerData.Hit and PlayerData.Hit[TargetCategory] and PlayerData.Hit[TargetCategory][TargetUnitName] then -- Was there a hit for this unit for this player before registered???
          if not PlayerData.Kill[TargetCategory] then
            PlayerData.Kill[TargetCategory] = {}
        end
        if not PlayerData.Kill[TargetCategory][TargetType] then
          PlayerData.Kill[TargetCategory][TargetType] = {}
          PlayerData.Kill[TargetCategory][TargetType].Score = 0
          PlayerData.Kill[TargetCategory][TargetType].ScoreKill = 0
          PlayerData.Kill[TargetCategory][TargetType].Penalty = 0
          PlayerData.Kill[TargetCategory][TargetType].PenaltyKill = 0
        end

        if InitCoalition == TargetCoalition then
          PlayerData.Penalty = PlayerData.Penalty + 25
          PlayerData.Kill[TargetCategory][TargetType].Penalty = PlayerData.Kill[TargetCategory][TargetType].Penalty + 25
          PlayerData.Kill[TargetCategory][TargetType].PenaltyKill = PlayerData.Kill[TargetCategory][TargetType].PenaltyKill + 1
          MESSAGE:New( "Player '" .. PlayerName .. "' killed a friendly " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " ..
            PlayerData.Kill[TargetCategory][TargetType].PenaltyKill .. " times. Penalty: -" .. PlayerData.Kill[TargetCategory][TargetType].Penalty ..
            ".  Score Total:" .. PlayerData.Score - PlayerData.Penalty,
            5 ):ToAll()
          self:ScoreCSV( PlayerName, "KILL_PENALTY", 1, -125, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
        else
          PlayerData.Score = PlayerData.Score + 10
          PlayerData.Kill[TargetCategory][TargetType].Score = PlayerData.Kill[TargetCategory][TargetType].Score + 10
          PlayerData.Kill[TargetCategory][TargetType].ScoreKill = PlayerData.Kill[TargetCategory][TargetType].ScoreKill + 1
          MESSAGE:New( "Player '" .. PlayerName .. "' killed an enemy " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " ..
            PlayerData.Kill[TargetCategory][TargetType].ScoreKill .. " times. Score: " .. PlayerData.Kill[TargetCategory][TargetType].Score ..
            ".  Score Total:" .. PlayerData.Score - PlayerData.Penalty,
            5 ):ToAll()
          self:ScoreCSV( PlayerName, "KILL_SCORE", 1, 10, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
        end
        end
      end
    end
  end
end



--- Add a new player entering a Unit.
function SCORING:_AddPlayerFromUnit( UnitData )
  self:F( UnitData )

  if UnitData and UnitData:isExist() then
    local UnitName = UnitData:getName()
    local PlayerName = UnitData:getPlayerName()
    local UnitDesc = UnitData:getDesc()
    local UnitCategory = UnitDesc.category
    local UnitCoalition = UnitData:getCoalition()
    local UnitTypeName = UnitData:getTypeName()

    self:T( { PlayerName, UnitName, UnitCategory, UnitCoalition, UnitTypeName } )

    if self.Players[PlayerName] == nil then -- I believe this is the place where a Player gets a life in a mission when he enters a unit ...
      self.Players[PlayerName] = {}
      self.Players[PlayerName].Hit = {}
      self.Players[PlayerName].Kill = {}
      self.Players[PlayerName].Mission = {}

      -- for CategoryID, CategoryName in pairs( SCORINGCategory ) do
      -- self.Players[PlayerName].Hit[CategoryID] = {}
      -- self.Players[PlayerName].Kill[CategoryID] = {}
      -- end
      self.Players[PlayerName].HitPlayers = {}
      self.Players[PlayerName].HitUnits = {}
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
        MESSAGE:New( "Player '" .. PlayerName .. "' changed coalition from " .. _SCORINGCoalition[self.Players[PlayerName].UnitCoalition] .. " to " .. _SCORINGCoalition[UnitCoalition] ..
          "(changed " .. self.Players[PlayerName].PenaltyCoalition .. " times the coalition). 50 Penalty points added.",
          2
        ):ToAll()
        self:ScoreCSV( PlayerName, "COALITION_PENALTY",  1, -50, self.Players[PlayerName].UnitName, _SCORINGCoalition[self.Players[PlayerName].UnitCoalition], _SCORINGCategory[self.Players[PlayerName].UnitCategory], self.Players[PlayerName].UnitType,
          UnitName, _SCORINGCoalition[UnitCoalition], _SCORINGCategory[UnitCategory], UnitData:getTypeName() )
      end
    end
    self.Players[PlayerName].UnitName = UnitName
    self.Players[PlayerName].UnitCoalition = UnitCoalition
    self.Players[PlayerName].UnitCategory = UnitCategory
    self.Players[PlayerName].UnitType = UnitTypeName

    if self.Players[PlayerName].Penalty > 100 then
      if self.Players[PlayerName].PenaltyWarning < 1 then
        MESSAGE:New( "Player '" .. PlayerName .. "': WARNING! If you continue to commit FRATRICIDE and have a PENALTY score higher than 150, you will be COURT MARTIALED and DISMISSED from this mission! \nYour total penalty is: " .. self.Players[PlayerName].Penalty,
          30
        ):ToAll()
        self.Players[PlayerName].PenaltyWarning = self.Players[PlayerName].PenaltyWarning + 1
      end
    end

    if self.Players[PlayerName].Penalty > 150 then
      ClientGroup = GROUP:NewFromDCSUnit( UnitData )
      ClientGroup:Destroy()
      MESSAGE:New( "Player '" .. PlayerName .. "' committed FRATRICIDE, he will be COURT MARTIALED and is DISMISSED from this mission!",
        10
      ):ToAll()
    end

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

  self:E( { Mission:GetName(), PlayerUnit.UnitName, PlayerName, Text, Score } )

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
  
    MESSAGE:New( "Player '" .. PlayerName .. "' has " .. Text .. " in Mission '" .. MissionName .. "'. " ..
      Score .. " task score!",
      30 ):ToAll()
  
    self:ScoreCSV( PlayerName, "TASK_" .. MissionName:gsub( ' ', '_' ), 1, Score, PlayerUnit:GetName() )
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

  self:E( { Mission, Text, Score } )
  self:E( self.Players )

  for PlayerName, PlayerData in pairs( self.Players ) do

    self:E( PlayerData )
    if PlayerData.Mission[MissionName] then

      PlayerData.Score = PlayerData.Score + Score
      PlayerData.Mission[MissionName].ScoreMission = PlayerData.Mission[MissionName].ScoreMission + Score

      MESSAGE:New( "Player '" .. PlayerName .. "' has " .. Text .. " in Mission '" .. MissionName .. "'. " ..
        Score .. " mission score!",
        60 ):ToAll()

      self:ScoreCSV( PlayerName, "MISSION_" .. MissionName:gsub( ' ', '_' ), 1, Score )
    end
  end
end

--- Handles the OnHit event for the scoring.
-- @param #SCORING self
-- @param Core.Event#EVENTDATA Event
function SCORING:_EventOnHit( Event )
  self:F( { Event } )

  local InitUnit = nil
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
  local TargetUnitName = ""
  local TargetGroup = nil
  local TargetGroupName = ""
  local TargetPlayerName = ""

  local TargetCoalition = nil
  local TargetCategory = nil
  local TargetType = nil
  local TargetUnitCoalition = nil
  local TargetUnitCategory = nil
  local TargetUnitType = nil

  if Event.IniDCSUnit then

    InitUnit = Event.IniDCSUnit
    InitUnitName = Event.IniDCSUnitName
    InitGroup = Event.IniDCSGroup
    InitGroupName = Event.IniDCSGroupName
    InitPlayerName = Event.IniPlayerName

    InitCoalition = InitUnit:getCoalition()
    --TODO: Workaround Client DCS Bug
    --InitCategory = InitUnit:getCategory()
    InitCategory = InitUnit:getDesc().category
    InitType = InitUnit:getTypeName()

    InitUnitCoalition = _SCORINGCoalition[InitCoalition]
    InitUnitCategory = _SCORINGCategory[InitCategory]
    InitUnitType = InitType

    self:T( { InitUnitName, InitGroupName, InitPlayerName, InitCoalition, InitCategory, InitType , InitUnitCoalition, InitUnitCategory, InitUnitType } )
  end


  if Event.TgtDCSUnit then

    TargetUnit = Event.TgtDCSUnit
    TargetUnitName = Event.TgtDCSUnitName
    TargetGroup = Event.TgtDCSGroup
    TargetGroupName = Event.TgtDCSGroupName
    TargetPlayerName = Event.TgtPlayerName

    TargetCoalition = TargetUnit:getCoalition()
    --TODO: Workaround Client DCS Bug
    --TargetCategory = TargetUnit:getCategory()
    TargetCategory = TargetUnit:getDesc().category
    TargetType = TargetUnit:getTypeName()

    TargetUnitCoalition = _SCORINGCoalition[TargetCoalition]
    TargetUnitCategory = _SCORINGCategory[TargetCategory]
    TargetUnitType = TargetType

    self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType, TargetUnitCoalition, TargetUnitCategory, TargetUnitType } )
  end

  if InitPlayerName ~= nil then -- It is a player that is hitting something
    self:_AddPlayerFromUnit( InitUnit )
    if self.Players[InitPlayerName] then -- This should normally not happen, but i'll test it anyway.
      if TargetPlayerName ~= nil then -- It is a player hitting another player ...
        self:_AddPlayerFromUnit( TargetUnit )
        self.Players[InitPlayerName].HitPlayers = self.Players[InitPlayerName].HitPlayers + 1
    end

    self:T( "Hitting Something" )
    -- What is he hitting?
    if TargetCategory then
      if not self.Players[InitPlayerName].Hit[TargetCategory] then
        self.Players[InitPlayerName].Hit[TargetCategory] = {}
      end
      if not self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName] then
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName] = {}
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score = 0
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty = 0
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit = 0
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit = 0
      end
      local Score = 0
      if InitCoalition == TargetCoalition then
        self.Players[InitPlayerName].Penalty = self.Players[InitPlayerName].Penalty + 10
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty + 10
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit + 1
        MESSAGE:New( "Player '" .. InitPlayerName .. "' hit a friendly " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " ..
          self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit .. " times. Penalty: -" .. self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty ..
          ".  Score Total:" .. self.Players[InitPlayerName].Score - self.Players[InitPlayerName].Penalty,
          2
        ):ToAll()
        self:ScoreCSV( InitPlayerName, "HIT_PENALTY", 1, -25, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
      else
        self.Players[InitPlayerName].Score = self.Players[InitPlayerName].Score + 1
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score + 1
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit + 1
        MESSAGE:New( "Player '" .. InitPlayerName .. "' hit a target " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " ..
          self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit .. " times. Score: " .. self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score ..
          ".  Score Total:" .. self.Players[InitPlayerName].Score - self.Players[InitPlayerName].Penalty,
          2
        ):ToAll()
        self:ScoreCSV( InitPlayerName, "HIT_SCORE", 1, 1, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
      end
    end
    end
  elseif InitPlayerName == nil then -- It is an AI hitting a player???

  end
end


function SCORING:ReportScoreAll()

  env.info( "Hello World " )

  local ScoreMessage = ""
  local PlayerMessage = ""

  self:T( "Score Report" )

  for PlayerName, PlayerData in pairs( self.Players ) do
    if PlayerData then -- This should normally not happen, but i'll test it anyway.
      self:T( "Score Player: " .. PlayerName )

      -- Some variables
      local InitUnitCoalition = _SCORINGCoalition[PlayerData.UnitCoalition]
      local InitUnitCategory = _SCORINGCategory[PlayerData.UnitCategory]
      local InitUnitType = PlayerData.UnitType
      local InitUnitName = PlayerData.UnitName

      local PlayerScore = 0
      local PlayerPenalty = 0

      ScoreMessage = ":\n"

      local ScoreMessageHits = ""

      for CategoryID, CategoryName in pairs( _SCORINGCategory ) do
        self:T( CategoryName )
        if PlayerData.Hit[CategoryID] then
          local Score = 0
          local ScoreHit = 0
          local Penalty = 0
          local PenaltyHit = 0
          self:T( "Hit scores exist for player " .. PlayerName )
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
        ScoreMessage = ScoreMessage .. "  Hits: " .. ScoreMessageHits .. "\n"
      end

      local ScoreMessageKills = ""
      for CategoryID, CategoryName in pairs( _SCORINGCategory ) do
        self:T( "Kill scores exist for player " .. PlayerName )
        if PlayerData.Kill[CategoryID] then
          local Score = 0
          local ScoreKill = 0
          local Penalty = 0
          local PenaltyKill = 0

          for UnitName, UnitData in pairs( PlayerData.Kill[CategoryID] ) do
            Score = Score + UnitData.Score
            ScoreKill = ScoreKill + UnitData.ScoreKill
            Penalty = Penalty + UnitData.Penalty
            PenaltyKill = PenaltyKill + UnitData.PenaltyKill
          end

          local ScoreMessageKill = string.format( "  %s:%d  ", CategoryName, Score - Penalty )
          self:T( ScoreMessageKill )
          ScoreMessageKills = ScoreMessageKills .. ScoreMessageKill

          PlayerScore = PlayerScore + Score
          PlayerPenalty = PlayerPenalty + Penalty
        else
        --ScoreMessageKills = ScoreMessageKills .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
        end
      end
      if ScoreMessageKills ~= "" then
        ScoreMessage = ScoreMessage .. "  Kills: " .. ScoreMessageKills .. "\n"
      end

      local ScoreMessageCoalitionChangePenalties = ""
      if PlayerData.PenaltyCoalition ~= 0 then
        ScoreMessageCoalitionChangePenalties = ScoreMessageCoalitionChangePenalties .. string.format( " -%d (%d changed)", PlayerData.Penalty, PlayerData.PenaltyCoalition )
        PlayerPenalty = PlayerPenalty + PlayerData.Penalty
      end
      if ScoreMessageCoalitionChangePenalties ~= "" then
        ScoreMessage = ScoreMessage .. "  Coalition Penalties: " .. ScoreMessageCoalitionChangePenalties .. "\n"
      end

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
        ScoreMessage = ScoreMessage .. "  Tasks: " .. ScoreTask .. " Mission: " .. ScoreMission .. " ( " .. ScoreMessageMission .. ")\n"
      end

      PlayerMessage = PlayerMessage .. string.format( "Player '%s' Score:%d (%d Score -%d Penalties)%s", PlayerName, PlayerScore - PlayerPenalty, PlayerScore, PlayerPenalty, ScoreMessage )
    end
  end
  MESSAGE:New( PlayerMessage, 30, "Player Scores" ):ToAll()
end


function SCORING:ReportScorePlayer()

  env.info( "Hello World " )

  local ScoreMessage = ""
  local PlayerMessage = ""

  self:T( "Score Report" )

  for PlayerName, PlayerData in pairs( self.Players ) do
    if PlayerData then -- This should normally not happen, but i'll test it anyway.
      self:T( "Score Player: " .. PlayerName )

      -- Some variables
      local InitUnitCoalition = _SCORINGCoalition[PlayerData.UnitCoalition]
      local InitUnitCategory = _SCORINGCategory[PlayerData.UnitCategory]
      local InitUnitType = PlayerData.UnitType
      local InitUnitName = PlayerData.UnitName

      local PlayerScore = 0
      local PlayerPenalty = 0

      ScoreMessage = ""

      local ScoreMessageHits = ""

      for CategoryID, CategoryName in pairs( _SCORINGCategory ) do
        self:T( CategoryName )
        if PlayerData.Hit[CategoryID] then
          local Score = 0
          local ScoreHit = 0
          local Penalty = 0
          local PenaltyHit = 0
          self:T( "Hit scores exist for player " .. PlayerName )
          for UnitName, UnitData in pairs( PlayerData.Hit[CategoryID] ) do
            Score = Score + UnitData.Score
            ScoreHit = ScoreHit + UnitData.ScoreHit
            Penalty = Penalty + UnitData.Penalty
            PenaltyHit = UnitData.PenaltyHit
          end
          local ScoreMessageHit = string.format( "\n    %s = %d score(%d;-%d) hits(#%d;#-%d)", CategoryName, Score - Penalty, Score, Penalty, ScoreHit,  PenaltyHit )
          self:T( ScoreMessageHit )
          ScoreMessageHits = ScoreMessageHits .. ScoreMessageHit
          PlayerScore = PlayerScore + Score
          PlayerPenalty = PlayerPenalty + Penalty
        else
        --ScoreMessageHits = ScoreMessageHits .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
        end
      end
      if ScoreMessageHits ~= "" then
        ScoreMessage = ScoreMessage .. "\n  Hits: " .. ScoreMessageHits .. " "
      end

      local ScoreMessageKills = ""
      for CategoryID, CategoryName in pairs( _SCORINGCategory ) do
        self:T( "Kill scores exist for player " .. PlayerName )
        if PlayerData.Kill[CategoryID] then
          local Score = 0
          local ScoreKill = 0
          local Penalty = 0
          local PenaltyKill = 0

          for UnitName, UnitData in pairs( PlayerData.Kill[CategoryID] ) do
            Score = Score + UnitData.Score
            ScoreKill = ScoreKill + UnitData.ScoreKill
            Penalty = Penalty + UnitData.Penalty
            PenaltyKill = PenaltyKill + UnitData.PenaltyKill
          end

          local ScoreMessageKill = string.format( "\n    %s = %d score(%d;-%d) hits(#%d;#-%d)", CategoryName, Score - Penalty, Score, Penalty, ScoreKill, PenaltyKill )
          self:T( ScoreMessageKill )
          ScoreMessageKills = ScoreMessageKills .. ScoreMessageKill

          PlayerScore = PlayerScore + Score
          PlayerPenalty = PlayerPenalty + Penalty
        else
        --ScoreMessageKills = ScoreMessageKills .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
        end
      end
      if ScoreMessageKills ~= "" then
        ScoreMessage = ScoreMessage .. "\n  Kills: " .. ScoreMessageKills .. " "
      end

      local ScoreMessageCoalitionChangePenalties = ""
      if PlayerData.PenaltyCoalition ~= 0 then
        ScoreMessageCoalitionChangePenalties = ScoreMessageCoalitionChangePenalties .. string.format( " -%d (%d changed)", PlayerData.Penalty, PlayerData.PenaltyCoalition )
        PlayerPenalty = PlayerPenalty + PlayerData.Penalty
      end
      if ScoreMessageCoalitionChangePenalties ~= "" then
        ScoreMessage = ScoreMessage .. "\n  Coalition: " .. ScoreMessageCoalitionChangePenalties .. " "
      end

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
        ScoreMessage = ScoreMessage .. "\n  Tasks: " .. ScoreTask .. " Mission: " .. ScoreMission .. " ( " .. ScoreMessageMission .. ") "
      end

      PlayerMessage = PlayerMessage .. string.format( "Player '%s' Score = %d ( %d Score, -%d Penalties ):%s", PlayerName, PlayerScore - PlayerPenalty, PlayerScore, PlayerPenalty, ScoreMessage )
    end
  end
  MESSAGE:New( PlayerMessage, 30, "Player Scores" ):ToAll()

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

      self.CSVFile:write( '"GameName","RunTime","Time","PlayerName","ScoreType","PlayerUnitCoaltion","PlayerUnitCategory","PlayerUnitType","PlayerUnitName","TargetUnitCoalition","TargetUnitCategory","TargetUnitType","TargetUnitName","Times","Score"\n' )
  
      self.RunTime = os.date("%y-%m-%d_%H-%M-%S")
    else
      error( "A string containing the CSV file name must be given." )
    end
  else
    self:E( "The MissionScripting.lua file has not been changed to allow lfs, io and os modules to be used..." )
  end
  return self
end


--- Registers a score for a player.
-- @param #SCORING self
-- @param #string PlayerName The name of the player.
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
function SCORING:ScoreCSV( PlayerName, ScoreType, ScoreTimes, ScoreAmount, PlayerUnitName, PlayerUnitCoalition, PlayerUnitCategory, PlayerUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
  --write statistic information to file
  local ScoreTime = self:SecondsToClock( timer.getTime() )
  PlayerName = PlayerName:gsub( '"', '_' )

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

  if not TargetUnitCoalition then
    TargetUnitCoalition = ''
  end

  if not TargetUnitCategory then
    TargetUnitCategory = ''
  end

  if not TargetUnitType then
    TargetUnitType = ''
  end

  if not TargetUnitName then
    TargetUnitName = ''
  end

  if lfs and io and os then
    self.CSVFile:write(
      '"' .. self.GameName        .. '"' .. ',' ..
      '"' .. self.RunTime         .. '"' .. ',' ..
      ''  .. ScoreTime            .. ''  .. ',' ..
      '"' .. PlayerName           .. '"' .. ',' ..
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

