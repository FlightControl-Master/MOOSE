--- **Core** -- Base class that models processes to achieve goals.
--
-- ====
-- 
-- GOAL models processes that have an objective with a defined achievement. Derived classes implement the ways how the achievements can be realized.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ====
-- 
-- @module Goal

do -- Goal

  --- @type GOAL
  -- @extends Core.Fsm#FSM


  --- # GOAL class, extends @{Fsm#FSM}
  -- 
  -- GOAL models processes that have an objective with a defined achievement. Derived classes implement the ways how the achievements can be realized.
  -- 
  -- ## 1. GOAL constructor
  --   
  --   * @{#GOAL.New}(): Creates a new GOAL object.
  -- 
  -- ## 2. GOAL is a finite state machine (FSM).
  -- 
  -- ### 2.1 GOAL States
  -- 
  --   * **Off**: The goal is not timely measured.
  --   * **On**: The goal is timely being measured.
  --   * **Achieved**: The objective is achieved.
  -- 
  -- ### 2.2 GOAL Events
  -- 
  --   * **@{#GOAL.Start}()**: Start Measuring the Goal.
  --   * **@{#GOAL.Stop}()**: Stop Measuring the Goal.
  --   * **@{#GOAL.IsAchieved}()**: Check if the Goal is Achieved.
  -- 
  -- @field #GOAL
  GOAL = {
    ClassName = "GOAL",
  }
  
  --- @field #table GOAL.States
  GOAL.States = {}
  
  --- GOAL Constructor.
  -- @param #GOAL self
  -- @return #GOAL
  function GOAL:New()
  
    local self = BASE:Inherit( self, FSM:New() ) -- #GOAL
    self:F( {} )


    do 
    
      --- On State for GOAL
      -- @field GOAL.On

      --- On State Handler OnLeave for GOAL
      -- @function [parent=#GOAL] OnLeaveOn
      -- @param #GOAL self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- On State Handler OnEnter for GOAL
      -- @function [parent=#GOAL] OnEnterOn
      -- @param #GOAL self
      -- @param #string From
      -- @param #string Event
      -- @param #string To

    end

    do

      --- Off State for GOAL
      -- @field GOAL.Off

      --- Off State Handler OnLeave for GOAL
      -- @function [parent=#GOAL] OnLeaveOff
      -- @param #GOAL self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Off State Handler OnEnter for GOAL
      -- @function [parent=#GOAL] OnEnterOff
      -- @param #GOAL self
      -- @param #string From
      -- @param #string Event
      -- @param #string To

    end

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
    
    
    self:SetStartState( "Idle" )
    self:AddTransition( "Idle", "Start", "On" )
    
    --- Start Handler OnBefore for GOAL
    -- @function [parent=#GOAL] OnBeforeStart
    -- @param #GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Start Handler OnAfter for GOAL
    -- @function [parent=#GOAL] OnAfterStart
    -- @param #GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Start Trigger for GOAL
    -- @function [parent=#GOAL] Start
    -- @param #GOAL self
    
    --- Start Asynchronous Trigger for GOAL
    -- @function [parent=#GOAL] __Start
    -- @param #GOAL self
    -- @param #number Delay

    self:AddTransition( "On", "Stop", "Idle" )
    
    --- Stop Handler OnBefore for GOAL
    -- @function [parent=#GOAL] OnBeforeStop
    -- @param #GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Stop Handler OnAfter for GOAL
    -- @function [parent=#GOAL] OnAfterStop
    -- @param #GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Stop Trigger for GOAL
    -- @function [parent=#GOAL] Stop
    -- @param #GOAL self
    
    --- Stop Asynchronous Trigger for GOAL
    -- @function [parent=#GOAL] __Stop
    -- @param #GOAL self
    -- @param #number Delay
    
    
    self:AddTransition( "On",  "IsAchieved", "On" )
    
    --- IsAchieved Handler OnBefore for GOAL
    -- @function [parent=#GOAL] OnBeforeIsAchieved
    -- @param #GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- IsAchieved Handler OnAfter for GOAL
    -- @function [parent=#GOAL] OnAfterIsAchieved
    -- @param #GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- IsAchieved Trigger for GOAL
    -- @function [parent=#GOAL] IsAchieved
    -- @param #GOAL self
    
    --- IsAchieved Asynchronous Trigger for GOAL
    -- @function [parent=#GOAL] __IsAchieved
    -- @param #GOAL self
    -- @param #number Delay
    
    self:AddTransition( "*",  "Achieved", "Achieved" )
    
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
    
  
    self.AchievedScheduler = nil
  
    self:SetEventPriority( 5 )

    return self
  end
  
  
  --- @param #GOAL self
  -- @param From
  -- @param Event
  -- @param To
  function GOAL:onafterOn( From, Event, To )
    if not self.AchievedScheduler then
      self.AchievedScheduler = self:ScheduleRepeat( 15, 15, 0, nil, self.CheckAchieved, self )
    end
  end

  --- @param #GOAL self
  -- @param From
  -- @param Event
  -- @param To
  function GOAL:onafterOff( From, Event, To )
    self:ScheduleStop( self.CheckAchieved )
    self.ArchievedScheduler = nil
  end

  --- @param #GOAL self
  -- @param From
  -- @param Event
  -- @param To
  function GOAL:CheckAchieved( From, Event, To )
    self:IsAchieved()
  end

end