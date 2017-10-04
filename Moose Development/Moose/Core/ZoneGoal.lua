--- **Core** -- Base class that models processes to achieve goals involving a Zone.
--
-- ====
-- 
-- ZONE_GOAL models processes that have an objective with a defined achievement involving a Zone. Derived classes implement the ways how the achievements can be realized.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ====
-- 
-- @module ZoneGoal

do -- Zone

  --- @type ZONE_GOAL
  -- @extends Core.Fsm#FSM


  --- # ZONE_GOAL class, extends @{Fsm#FSM}
  -- 
  -- ZONE_GOAL models processes that have an objective with a defined achievement involving a Zone. Derived classes implement the ways how the achievements can be realized.
  -- 
  -- ## 1. ZONE_GOAL constructor
  --   
  --   * @{#ZONE_GOAL.New}(): Creates a new ZONE_GOAL object.
  -- 
  -- ## 2. ZONE_GOAL is a finite state machine (FSM).
  -- 
  -- ### 2.1 ZONE_GOAL States
  -- 
  --   * **Empty**: The Zone is Empty.
  --   * **Guarded**: The Zone is Guarded.
  -- 
  -- ### 2.2 ZONE_GOAL Events
  -- 
  --   * **@{#ZONE_GOAL.Guard}()**: Set the Zone to Guarded.
  --   * **@{#ZONE_GOAL.Empty}()**: Set the Zone to Empty.
  -- 
  -- @field #ZONE_GOAL
  ZONE_GOAL = {
    ClassName = "ZONE_GOAL",
  }
  
  --- @field #table ZONE_GOAL.States
  ZONE_GOAL.States = {}
  
  --- ZONE_GOAL Constructor.
  -- @param #ZONE_GOAL self
  -- @param Core.Zone#ZONE_BASE Zone A @{Zone} object with the goal to be achieved.
  -- @return #ZONE_GOAL
  function ZONE_GOAL:New( Zone )
  
    local self = BASE:Inherit( self, FSM:New() ) -- #ZONE_GOAL
    self:F( { Zone = Zone } )

    self.Zone = Zone -- Core.Zone#ZONE_BASE
    self.Goal = GOAL:New()

    do 
    
      --- Guarded State Handler OnLeave for ZONE_GOAL
      -- @function [parent=#ZONE_GOAL] OnLeaveGuarded
      -- @param #ZONE_GOAL self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Guarded State Handler OnEnter for ZONE_GOAL
      -- @function [parent=#ZONE_GOAL] OnEnterGuarded
      -- @param #ZONE_GOAL self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  

    do 
    
      --- Empty State Handler OnLeave for ZONE_GOAL
      -- @function [parent=#ZONE_GOAL] OnLeaveEmpty
      -- @param #ZONE_GOAL self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Empty State Handler OnEnter for ZONE_GOAL
      -- @function [parent=#ZONE_GOAL] OnEnterEmpty
      -- @param #ZONE_GOAL self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  

    self:AddTransition( "*", "Guard", "Guarded" )
    
    --- Guard Handler OnBefore for ZONE_GOAL
    -- @function [parent=#ZONE_GOAL] OnBeforeGuard
    -- @param #ZONE_GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Guard Handler OnAfter for ZONE_GOAL
    -- @function [parent=#ZONE_GOAL] OnAfterGuard
    -- @param #ZONE_GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Guard Trigger for ZONE_GOAL
    -- @function [parent=#ZONE_GOAL] Guard
    -- @param #ZONE_GOAL self
    
    --- Guard Asynchronous Trigger for ZONE_GOAL
    -- @function [parent=#ZONE_GOAL] __Guard
    -- @param #ZONE_GOAL self
    -- @param #number Delay
    
    self:AddTransition( "*", "Empty", "Empty" )
    
    --- Empty Handler OnBefore for ZONE_GOAL
    -- @function [parent=#ZONE_GOAL] OnBeforeEmpty
    -- @param #ZONE_GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Empty Handler OnAfter for ZONE_GOAL
    -- @function [parent=#ZONE_GOAL] OnAfterEmpty
    -- @param #ZONE_GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Empty Trigger for ZONE_GOAL
    -- @function [parent=#ZONE_GOAL] Empty
    -- @param #ZONE_GOAL self
    
    --- Empty Asynchronous Trigger for ZONE_GOAL
    -- @function [parent=#ZONE_GOAL] __Empty
    -- @param #ZONE_GOAL self
    -- @param #number Delay
    

    self.SmokeTime = nil

    return self
  end
  
  --- Get the Zone
  -- @param #ZONE_GOAL self
  -- @return Core.Zone#ZONE_BASE
  function ZONE_GOAL:GetZone()
    return self.Zone
  end
  
  
  --- Get the name of the ProtectZone
  -- @param #ZONE_GOAL self
  -- @return #string
  function ZONE_GOAL:GetZoneName()
    return self.Zone:GetName()
  end

  --- Smoke the center of theh zone.
  -- @param #ZONE_GOAL self
  -- @param #SMOKECOLOR.Color SmokeColor
  function ZONE_GOAL:Smoke( SmokeColor )
  
    self:F( { SmokeColor = SmokeColor} )
  
    self.SmokeColor = SmokeColor
  end
    
  
  --- Flare the center of the zone.
  -- @param #ZONE_GOAL self
  -- @param #SMOKECOLOR.Color FlareColor
  function ZONE_GOAL:Flare( FlareColor )
    self.Zone:FlareZone( FlareColor, math.random( 1, 360 ) )
  end


  --- When started, check the Smoke and the Zone status.
  -- @param #ZONE_GOAL self
  function ZONE_GOAL:onafterGuard()
  
    --self:GetParent( self ):onafterStart()
    
    self:E("Guard")
  
    --self:ScheduleRepeat( 15, 15, 0.1, nil, self.StatusZone, self )
    if not self.SmokeScheduler then
      self.SmokeScheduler = self:ScheduleRepeat( 1, 1, 0.1, nil, self.StatusSmoke, self )
    end
  end

  function ZONE_GOAL:IsGuarded()
  
    local IsGuarded = self.Zone:IsAllInZoneOfCoalition( self.Coalition )
    self:E( { IsGuarded = IsGuarded } )
    return IsGuarded
  end


  function ZONE_GOAL:IsEmpty()
  
    local IsEmpty = self.Zone:IsNoneInZone()
    self:E( { IsEmpty = IsEmpty } )
    return IsEmpty
  end


  --- Check status Zone.
  -- @param #ZONE_GOAL self
  function ZONE_GOAL:StatusZone()
    
    local State = self:GetState()
    self:E( { State = self:GetState() } )
  
    self.Zone:Scan()
  
    if State ~= "Guarded" and self:IsGuarded() then
      self:Guard()
    end
    
    if State ~= "Empty" and self:IsEmpty() then  
      self:Empty()
    end
    
  end
  
  --- Check status Smoke.
  -- @param #ZONE_GOAL self
  function ZONE_GOAL:StatusSmoke()
  
    self:F({self.SmokeTime, self.SmokeColor})
    
    local CurrentTime = timer.getTime()
  
    if self.SmokeTime == nil or self.SmokeTime + 300 <= CurrentTime then
      if self.SmokeColor then
        self.Zone:GetCoordinate():Smoke( self.SmokeColor )
        --self.SmokeColor = nil
        self.SmokeTime = CurrentTime
      end
    end
  end
  
end
