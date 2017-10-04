--- **Core** -- Base class that models processes to achieve goals involving a Zone for a Coalition.
--
-- ====
-- 
-- ZONE_GOAL_COALITION models processes that have a Goal with a defined achievement involving a Zone for a Coalition.  
-- Derived classes implement the ways how the achievements can be realized.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ====
-- 
-- @module ZoneGoalCoalition

do -- ZoneGoal

  --- @type ZONE_GOAL_COALITION
  -- @extends Core.ZoneGoal#ZONE_GOAL_COALITION


  --- # ZONE_GOAL_COALITION class, extends @{ZoneGoal#ZONE_GOAL_COALITION}
  -- 
  -- ZONE_GOAL_COALITION models processes that have a Goal with a defined achievement involving a Zone for a Coalition.  
  -- Derived classes implement the ways how the achievements can be realized.
  -- 
  -- ## 1. ZONE_GOAL_COALITION constructor
  --   
  --   * @{#ZONE_GOAL_COALITION.New}(): Creates a new ZONE_GOAL_COALITION object.
  -- 
  -- ## 2. ZONE_GOAL_COALITION is a finite state machine (FSM).
  -- 
  -- ### 2.1 ZONE_GOAL_COALITION States
  --  
  --   * **Captured**: The Zone has been captured by an other coalition.
  --   * **Attacked**: The Zone is currently intruded by an other coalition. There are units of the owning coalition and an other coalition in the Zone.
  --   * **Guarded**: The Zone is guarded by the owning coalition. There is no other unit of an other coalition in the Zone.
  --   * **Empty**: The Zone is empty. There is not valid unit in the Zone.
  -- 
  -- ### 2.2 ZONE_GOAL_COALITION Events
  -- 
  --   * **Capture**: The Zone has been captured by an other coalition.
  --   * **Attack**: The Zone is currently intruded by an other coalition. There are units of the owning coalition and an other coalition in the Zone.
  --   * **Guard**: The Zone is guarded by the owning coalition. There is no other unit of an other coalition in the Zone.
  --   * **Empty**: The Zone is empty. There is not valid unit in the Zone.
  --   
  -- ### 2.3 ZONE_GOAL_COALITION State Machine
  -- 
  --   
  --   
  -- Hello | World
  -- ------|------
  -- Test|Test2
  -- 
  -- @field #ZONE_GOAL_COALITION
  ZONE_GOAL_COALITION = {
    ClassName = "ZONE_GOAL_COALITION",
  }
  
  --- @field #table ZONE_GOAL_COALITION.States
  ZONE_GOAL_COALITION.States = {}
  
  --- ZONE_GOAL_COALITION Constructor.
  -- @param #ZONE_GOAL_COALITION self
  -- @param Core.Zone#ZONE Zone A @{Zone} object with the goal to be achieved.
  -- @param DCSCoalition.DCSCoalition#coalition Coalition The initial coalition owning the zone.
  -- @return #ZONE_GOAL_COALITION
  function ZONE_GOAL_COALITION:New( Zone, Coalition )
  
    local self = BASE:Inherit( self, ZONE_GOAL_COALITION:New( Zone ) ) -- #ZONE_GOAL_COALITION
    self:F( { Zone = Zone, Coalition  = Coalition  } )

    self:SetCoalition( Coalition )

    do 
    
      --- Captured State Handler OnLeave for ZONE_GOAL_COALITION
      -- @function [parent=#ZONE_GOAL_COALITION] OnLeaveCaptured
      -- @param #ZONE_GOAL_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Captured State Handler OnEnter for ZONE_GOAL_COALITION
      -- @function [parent=#ZONE_GOAL_COALITION] OnEnterCaptured
      -- @param #ZONE_GOAL_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  
  
    do 
    
      --- Attacked State Handler OnLeave for ZONE_GOAL_COALITION
      -- @function [parent=#ZONE_GOAL_COALITION] OnLeaveAttacked
      -- @param #ZONE_GOAL_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Attacked State Handler OnEnter for ZONE_GOAL_COALITION
      -- @function [parent=#ZONE_GOAL_COALITION] OnEnterAttacked
      -- @param #ZONE_GOAL_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end

    do 
    
      --- Guarded State Handler OnLeave for ZONE_GOAL_COALITION
      -- @function [parent=#ZONE_GOAL_COALITION] OnLeaveGuarded
      -- @param #ZONE_GOAL_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Guarded State Handler OnEnter for ZONE_GOAL_COALITION
      -- @function [parent=#ZONE_GOAL_COALITION] OnEnterGuarded
      -- @param #ZONE_GOAL_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  

    do 
    
      --- Empty State Handler OnLeave for ZONE_GOAL_COALITION
      -- @function [parent=#ZONE_GOAL_COALITION] OnLeaveEmpty
      -- @param #ZONE_GOAL_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Empty State Handler OnEnter for ZONE_GOAL_COALITION
      -- @function [parent=#ZONE_GOAL_COALITION] OnEnterEmpty
      -- @param #ZONE_GOAL_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  
    self:AddTransition( "*", "Guard", "Guarded" )
    
    --- Guard Handler OnBefore for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] OnBeforeGuard
    -- @param #ZONE_GOAL_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Guard Handler OnAfter for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] OnAfterGuard
    -- @param #ZONE_GOAL_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Guard Trigger for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] Guard
    -- @param #ZONE_GOAL_COALITION self
    
    --- Guard Asynchronous Trigger for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] __Guard
    -- @param #ZONE_GOAL_COALITION self
    -- @param #number Delay
    
    self:AddTransition( "*", "Empty", "Empty" )
    
    --- Empty Handler OnBefore for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] OnBeforeEmpty
    -- @param #ZONE_GOAL_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Empty Handler OnAfter for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] OnAfterEmpty
    -- @param #ZONE_GOAL_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Empty Trigger for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] Empty
    -- @param #ZONE_GOAL_COALITION self
    
    --- Empty Asynchronous Trigger for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] __Empty
    -- @param #ZONE_GOAL_COALITION self
    -- @param #number Delay
    
    
    self:AddTransition( {  "Guarded", "Empty" }, "Attack", "Attacked" )
  
    --- Attack Handler OnBefore for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] OnBeforeAttack
    -- @param #ZONE_GOAL_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Attack Handler OnAfter for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] OnAfterAttack
    -- @param #ZONE_GOAL_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Attack Trigger for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] Attack
    -- @param #ZONE_GOAL_COALITION self
    
    --- Attack Asynchronous Trigger for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] __Attack
    -- @param #ZONE_GOAL_COALITION self
    -- @param #number Delay
    
    self:AddTransition( { "Guarded", "Attacked", "Empty" }, "Capture", "Captured" )
   
    --- Capture Handler OnBefore for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] OnBeforeCapture
    -- @param #ZONE_GOAL_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Capture Handler OnAfter for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] OnAfterCapture
    -- @param #ZONE_GOAL_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Capture Trigger for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] Capture
    -- @param #ZONE_GOAL_COALITION self
    
    --- Capture Asynchronous Trigger for ZONE_GOAL_COALITION
    -- @function [parent=#ZONE_GOAL_COALITION] __Capture
    -- @param #ZONE_GOAL_COALITION self
    -- @param #number Delay

    return self
  end
  

  --- Set the owning coalition of the zone.
  -- @param #ZONE_GOAL_COALITION self
  -- @param DCSCoalition.DCSCoalition#coalition Coalition
  function ZONE_GOAL_COALITION:SetCoalition( Coalition )
    self.Coalition = Coalition
  end
  
  
  --- Get the owning coalition of the zone.
  -- @param #ZONE_GOAL_COALITION self
  -- @return DCSCoalition.DCSCoalition#coalition Coalition.
  function ZONE_GOAL_COALITION:GetCoalition()
    return self.Coalition
  end

  
  --- Get the owning coalition name of the zone.
  -- @param #ZONE_GOAL_COALITION self
  -- @return #string Coalition name.
  function ZONE_GOAL_COALITION:GetCoalitionName()
  
    if self.Coalition == coalition.side.BLUE then
      return "Blue"
    end
    
    if self.Coalition == coalition.side.RED then
      return "Red"
    end
    
    if self.Coalition == coalition.side.NEUTRAL then
      return "Neutral"
    end
    
    return ""
  end


  function ZONE_GOAL_COALITION:IsGuarded()
  
    local IsGuarded = self.Zone:IsAllInZoneOfCoalition( self.Coalition )
    self:E( { IsGuarded = IsGuarded } )
    return IsGuarded
  end


  function ZONE_GOAL_COALITION:IsEmpty()
  
    local IsEmpty = self.Zone:IsNoneInZone()
    self:E( { IsEmpty = IsEmpty } )
    return IsEmpty
  end


  function ZONE_GOAL_COALITION:IsCaptured()
  
    local IsCaptured = self.Zone:IsAllInZoneOfOtherCoalition( self.Coalition )
    self:E( { IsCaptured = IsCaptured } )
    return IsCaptured
  end
  
  
  function ZONE_GOAL_COALITION:IsAttacked()
  
    local IsAttacked = self.Zone:IsSomeInZoneOfCoalition( self.Coalition )
    self:E( { IsAttacked = IsAttacked } )
    return IsAttacked
  end
  
  

  --- Mark.
  -- @param #ZONE_GOAL_COALITION self
  function ZONE_GOAL_COALITION:Mark()
  
    local Coord = self.Zone:GetCoordinate()
    local ZoneName = self:GetZoneName()
    local State = self:GetState()
    
    if self.MarkRed and self.MarkBlue then
      self:E( { MarkRed = self.MarkRed, MarkBlue = self.MarkBlue } )
      Coord:RemoveMark( self.MarkRed )
      Coord:RemoveMark( self.MarkBlue )
    end
    
    if self.Coalition == coalition.side.BLUE then
      self.MarkBlue = Coord:MarkToCoalitionBlue( "Guard Zone: " .. ZoneName .. "\nStatus: " .. State )  
      self.MarkRed = Coord:MarkToCoalitionRed( "Capture Zone: " .. ZoneName .. "\nStatus: " .. State )  
    else
      self.MarkRed = Coord:MarkToCoalitionRed( "Guard Zone: " .. ZoneName .. "\nStatus: " .. State )  
      self.MarkBlue = Coord:MarkToCoalitionBlue( "Capture Zone: " .. ZoneName .. "\nStatus: " .. State )  
    end
  end

  --- Bound.
  -- @param #ZONE_GOAL_COALITION self
  function ZONE_GOAL_COALITION:onenterGuarded()
  
    --self:GetParent( self ):onenterGuarded()
  
    if self.Coalition == coalition.side.BLUE then
      --elf.ProtectZone:BoundZone( 12, country.id.USA )
    else
      --self.ProtectZone:BoundZone( 12, country.id.RUSSIA )
    end
    
    self:Mark()
    
  end
  
  function ZONE_GOAL_COALITION:onenterCaptured()
  
    --self:GetParent( self ):onenterCaptured()

    local NewCoalition = self.Zone:GetCoalition()
    self:E( { NewCoalition = NewCoalition } )
    self:SetCoalition( NewCoalition )
  
    self:Mark()
  end
  
  
  function ZONE_GOAL_COALITION:onenterEmpty()

    --self:GetParent( self ):onenterEmpty()
  
    self:Mark()
  end
  
  
  function ZONE_GOAL_COALITION:onenterAttacked()
  
    --self:GetParent( self ):onenterAttacked()
  
    self:Mark()
  end


  --- When started, check the Coalition status.
  -- @param #ZONE_GOAL_COALITION self
  function ZONE_GOAL_COALITION:onafterGuard()
  
    --self:E({BASE:GetParent( self )})
    --BASE:GetParent( self ).onafterGuard( self )
  
    if not self.SmokeScheduler then
      self.SmokeScheduler = self:ScheduleRepeat( 1, 1, 0.1, nil, self.StatusSmoke, self )
    end
    if not self.ScheduleStatusZone then
      self.ScheduleStatusZone = self:ScheduleRepeat( 15, 15, 0.1, nil, self.StatusZone, self )
    end
  end


  function ZONE_GOAL_COALITION:IsCaptured()
  
    local IsCaptured = self.Zone:IsAllInZoneOfOtherCoalition( self.Coalition )
    self:E( { IsCaptured = IsCaptured } )
    return IsCaptured
  end
  
  
  function ZONE_GOAL_COALITION:IsAttacked()
  
    local IsAttacked = self.Zone:IsSomeInZoneOfCoalition( self.Coalition )
    self:E( { IsAttacked = IsAttacked } )
    return IsAttacked
  end
  
  --- Check status Coalition ownership.
  -- @param #ZONE_GOAL_COALITION self
  function ZONE_GOAL_COALITION:StatusZone()
  
    self:GetParent( self, ZONE_GOAL_COALITION ).StatusZone( self )
    
    local State = self:GetState()
    self:E( { State = self:GetState() } )
  
    self.Zone:Scan()
  
    if State ~= "Guarded" and self:IsGuarded() then
      self:Guard()
    end
    
    if State ~= "Empty" and self:IsEmpty() then  
      self:Empty()
    end

    if State ~= "Attacked" and self:IsAttacked() then
      self:Attack()
    end
    
    if State ~= "Captured" and self:IsCaptured() then  
      self:Capture()
    end
    
  end
  
end

