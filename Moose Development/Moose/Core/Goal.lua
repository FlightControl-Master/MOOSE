--- **Core** - Models the process to achieve goal(s).
--
-- ===
--
-- ## Features:
--
--   * Define the goal.
--   * Monitor the goal achievement.
--   * Manage goal contribution by players.
--
-- ===
--
-- Classes that implement a goal achievement, will derive from GOAL to implement the ways how the achievements can be realized.
--
-- ===
--
-- ### Author: **FlightControl**
-- ### Contributions: **funkyfranky**
--
-- ===
--
-- @module Core.Goal
-- @image Core_Goal.JPG

do -- Goal

  --- @type GOAL
  -- @extends Core.Fsm#FSM

  --- Models processes that have an objective with a defined achievement. Derived classes implement the ways how the achievements can be realized.
  --
  -- # 1. GOAL constructor
  --
  --   * @{#GOAL.New}(): Creates a new GOAL object.
  --
  -- # 2. GOAL is a finite state machine (FSM).
  --
  -- ## 2.1. GOAL States
  --
  --   * **Pending**: The goal object is in progress.
  --   * **Achieved**: The goal objective is Achieved.
  --
  -- ## 2.2. GOAL Events
  --
  --   * **Achieved**: Set the goal objective to Achieved.
  --
  -- # 3. Player contributions.
  --
  -- Goals are most of the time achieved by players. These player achievements can be registered as part of the goal achievement.
  -- Use @{#GOAL.AddPlayerContribution}() to add a player contribution to the goal.
  -- The player contributions are based on a points system, an internal counter per player.
  -- So once the goal has been achieved, the player contributions can be queried using @{#GOAL.GetPlayerContributions}(),
  -- that retrieves all contributions done by the players. For one player, the contribution can be queried using @{#GOAL.GetPlayerContribution}().
  -- The total amount of player contributions can be queried using @{#GOAL.GetTotalContributions}().
  --
  -- # 4. Goal achievement.
  --
  -- Once the goal is achieved, the mission designer will need to trigger the goal achievement using the **Achieved** event.
  -- The underlying 2 examples will achieve the goals for the `Goal` object:
  --
  --       Goal:Achieved() -- Achieve the goal immediately.
  --       Goal:__Achieved( 30 ) -- Achieve the goal within 30 seconds.
  --
  -- # 5. Check goal achievement.
  --
  -- The method @{#GOAL.IsAchieved}() will return true if the goal is achieved (the trigger **Achieved** was executed).
  -- You can use this method to check asynchronously if a goal has been achieved, for example using a scheduler.
  --
  -- @field #GOAL
  GOAL = {
    ClassName = "GOAL",
  }

  --- @field #table GOAL.Players
  GOAL.Players = {}

  --- @field #number GOAL.TotalContributions
  GOAL.TotalContributions = 0

  --- GOAL Constructor.
  -- @param #GOAL self
  -- @return #GOAL
  function GOAL:New()

    local self = BASE:Inherit( self, FSM:New() ) -- #GOAL
    self:F( {} )

    --- Achieved State for GOAL
    -- @field GOAL.Achieved

    --- Achieved State Handler OnLeave for GOAL
    -- @function [parent=#GOAL] OnLeaveAchieved
    -- @param #GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean

    --- Achieved State Handler OnEnter for GOAL
    -- @function [parent=#GOAL] OnEnterAchieved
    -- @param #GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To

    self:SetStartState( "Pending" )
    self:AddTransition( "*", "Achieved", "Achieved" )

    --- Achieved Handler OnBefore for GOAL
    -- @function [parent=#GOAL] OnBeforeAchieved
    -- @param #GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean

    --- Achieved Handler OnAfter for GOAL
    -- @function [parent=#GOAL] OnAfterAchieved
    -- @param #GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To

    --- Achieved Trigger for GOAL
    -- @function [parent=#GOAL] Achieved
    -- @param #GOAL self

    --- Achieved Asynchronous Trigger for GOAL
    -- @function [parent=#GOAL] __Achieved
    -- @param #GOAL self
    -- @param #number Delay

    self:SetEventPriority( 5 )

    return self
  end

  --- Add a new contribution by a player.
  -- @param #GOAL self
  -- @param #string PlayerName The name of the player.
  function GOAL:AddPlayerContribution( PlayerName )
    self:F( { PlayerName } )
    self.Players[PlayerName] = self.Players[PlayerName] or 0
    self.Players[PlayerName] = self.Players[PlayerName] + 1
    self.TotalContributions = self.TotalContributions + 1
  end

  --- @param #GOAL self
  -- @param #number Player contribution.
  function GOAL:GetPlayerContribution( PlayerName )
    return self.Players[PlayerName] or 0
  end

  --- Get the players who contributed to achieve the goal.
  -- The result is a list of players, sorted by the name of the players.
  -- @param #GOAL self
  -- @return #list The list of players, indexed by the player name.
  function GOAL:GetPlayerContributions()
    return self.Players or {}
  end

  --- Gets the total contributions that happened to achieve the goal.
  -- The result is a number.
  -- @param #GOAL self
  -- @return #number The total number of contributions. 0 is returned if there were no contributions (yet).
  function GOAL:GetTotalContributions()
    return self.TotalContributions or 0
  end

  --- Validates if the goal is achieved.
  -- @param #GOAL self
  -- @return #boolean true if the goal is achieved.
  function GOAL:IsAchieved()
    return self:Is( "Achieved" )
  end

end
