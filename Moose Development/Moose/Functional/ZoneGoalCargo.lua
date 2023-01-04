--- **Functional** - Base class that models processes to achieve goals involving a Zone and Cargo.
--
-- ===
-- 
-- ZONE_GOAL_CARGO models processes that have a Goal with a defined achievement involving a Zone and Cargo.  
-- Derived classes implement the ways how the achievements can be realized.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===
-- 
-- @module Functional.ZoneGoalCargo
-- @image MOOSE.JPG

do -- ZoneGoal

  --- @type ZONE_GOAL_CARGO
  -- @extends Functional.ZoneGoal#ZONE_GOAL


  --- Models processes that have a Goal with a defined achievement involving a Zone and Cargo.  
  -- Derived classes implement the ways how the achievements can be realized.
  -- 
  -- ## 1. ZONE_GOAL_CARGO constructor
  --   
  --   * @{#ZONE_GOAL_CARGO.New}(): Creates a new ZONE_GOAL_CARGO object.
  -- 
  -- ## 2. ZONE_GOAL_CARGO is a finite state machine (FSM).
  -- 
  -- ### 2.1 ZONE_GOAL_CARGO States
  --  
  --   * **Deployed**: The Zone has been captured by an other coalition.
  --   * **Airborne**: The Zone is currently intruded by an other coalition. There are units of the owning coalition and an other coalition in the Zone.
  --   * **Loaded**: The Zone is guarded by the owning coalition. There is no other unit of an other coalition in the Zone.
  --   * **Empty**: The Zone is empty. There is not valid unit in the Zone.
  -- 
  -- ### 2.2 ZONE_GOAL_CARGO Events
  -- 
  --   * **Capture**: The Zone has been captured by an other coalition.
  --   * **Attack**: The Zone is currently intruded by an other coalition. There are units of the owning coalition and an other coalition in the Zone.
  --   * **Guard**: The Zone is guarded by the owning coalition. There is no other unit of an other coalition in the Zone.
  --   * **Empty**: The Zone is empty. There is not valid unit in the Zone.
  --   
  -- ### 2.3 ZONE_GOAL_CARGO State Machine
  -- 
  -- @field #ZONE_GOAL_CARGO
  ZONE_GOAL_CARGO = {
    ClassName = "ZONE_GOAL_CARGO",
  }
  
  --- @field #table ZONE_GOAL_CARGO.States
  ZONE_GOAL_CARGO.States = {}
  
  --- ZONE_GOAL_CARGO Constructor.
  -- @param #ZONE_GOAL_CARGO self
  -- @param Core.Zone#ZONE Zone A @{Core.Zone} object with the goal to be achieved.
  -- @param DCSCoalition.DCSCoalition#coalition Coalition The initial coalition owning the zone.
  -- @return #ZONE_GOAL_CARGO
  function ZONE_GOAL_CARGO:New( Zone, Coalition )
  
    local self = BASE:Inherit( self, ZONE_GOAL:New( Zone ) ) -- #ZONE_GOAL_CARGO
    self:F( { Zone = Zone, Coalition  = Coalition  } )

    self:SetCoalition( Coalition )

    do 
    
      --- Captured State Handler OnLeave for ZONE_GOAL_CARGO
      -- @function [parent=#ZONE_GOAL_CARGO] OnLeaveCaptured
      -- @param #ZONE_GOAL_CARGO self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Captured State Handler OnEnter for ZONE_GOAL_CARGO
      -- @function [parent=#ZONE_GOAL_CARGO] OnEnterCaptured
      -- @param #ZONE_GOAL_CARGO self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  
  
    do 
    
      --- Attacked State Handler OnLeave for ZONE_GOAL_CARGO
      -- @function [parent=#ZONE_GOAL_CARGO] OnLeaveAttacked
      -- @param #ZONE_GOAL_CARGO self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Attacked State Handler OnEnter for ZONE_GOAL_CARGO
      -- @function [parent=#ZONE_GOAL_CARGO] OnEnterAttacked
      -- @param #ZONE_GOAL_CARGO self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end

    do 
    
      --- Guarded State Handler OnLeave for ZONE_GOAL_CARGO
      -- @function [parent=#ZONE_GOAL_CARGO] OnLeaveGuarded
      -- @param #ZONE_GOAL_CARGO self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Guarded State Handler OnEnter for ZONE_GOAL_CARGO
      -- @function [parent=#ZONE_GOAL_CARGO] OnEnterGuarded
      -- @param #ZONE_GOAL_CARGO self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  

    do 
    
      --- Empty State Handler OnLeave for ZONE_GOAL_CARGO
      -- @function [parent=#ZONE_GOAL_CARGO] OnLeaveEmpty
      -- @param #ZONE_GOAL_CARGO self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Empty State Handler OnEnter for ZONE_GOAL_CARGO
      -- @function [parent=#ZONE_GOAL_CARGO] OnEnterEmpty
      -- @param #ZONE_GOAL_CARGO self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  
    self:AddTransition( "*", "Guard", "Guarded" )
    
    --- Guard Handler OnBefore for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] OnBeforeGuard
    -- @param #ZONE_GOAL_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Guard Handler OnAfter for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] OnAfterGuard
    -- @param #ZONE_GOAL_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Guard Trigger for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] Guard
    -- @param #ZONE_GOAL_CARGO self
    
    --- Guard Asynchronous Trigger for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] __Guard
    -- @param #ZONE_GOAL_CARGO self
    -- @param #number Delay
    
    self:AddTransition( "*", "Empty", "Empty" )
    
    --- Empty Handler OnBefore for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] OnBeforeEmpty
    -- @param #ZONE_GOAL_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Empty Handler OnAfter for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] OnAfterEmpty
    -- @param #ZONE_GOAL_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Empty Trigger for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] Empty
    -- @param #ZONE_GOAL_CARGO self
    
    --- Empty Asynchronous Trigger for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] __Empty
    -- @param #ZONE_GOAL_CARGO self
    -- @param #number Delay
    
    
    self:AddTransition( {  "Guarded", "Empty" }, "Attack", "Attacked" )
  
    --- Attack Handler OnBefore for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] OnBeforeAttack
    -- @param #ZONE_GOAL_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Attack Handler OnAfter for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] OnAfterAttack
    -- @param #ZONE_GOAL_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Attack Trigger for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] Attack
    -- @param #ZONE_GOAL_CARGO self
    
    --- Attack Asynchronous Trigger for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] __Attack
    -- @param #ZONE_GOAL_CARGO self
    -- @param #number Delay
    
    self:AddTransition( { "Guarded", "Attacked", "Empty" }, "Capture", "Captured" )
   
    --- Capture Handler OnBefore for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] OnBeforeCapture
    -- @param #ZONE_GOAL_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Capture Handler OnAfter for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] OnAfterCapture
    -- @param #ZONE_GOAL_CARGO self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Capture Trigger for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] Capture
    -- @param #ZONE_GOAL_CARGO self
    
    --- Capture Asynchronous Trigger for ZONE_GOAL_CARGO
    -- @function [parent=#ZONE_GOAL_CARGO] __Capture
    -- @param #ZONE_GOAL_CARGO self
    -- @param #number Delay

    return self
  end
  

  --- Set the owning coalition of the zone.
  -- @param #ZONE_GOAL_CARGO self
  -- @param DCSCoalition.DCSCoalition#coalition Coalition
  function ZONE_GOAL_CARGO:SetCoalition( Coalition )
    self.Coalition = Coalition
  end
  
  
  --- Get the owning coalition of the zone.
  -- @param #ZONE_GOAL_CARGO self
  -- @return DCSCoalition.DCSCoalition#coalition Coalition.
  function ZONE_GOAL_CARGO:GetCoalition()
    return self.Coalition
  end

  
  --- Get the owning coalition name of the zone.
  -- @param #ZONE_GOAL_CARGO self
  -- @return #string Coalition name.
  function ZONE_GOAL_CARGO:GetCoalitionName()
  
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


  function ZONE_GOAL_CARGO:IsGuarded()
  
    local IsGuarded = self.Zone:IsAllInZoneOfCoalition( self.Coalition )
    self:F( { IsGuarded = IsGuarded } )
    return IsGuarded
  end


  function ZONE_GOAL_CARGO:IsEmpty()
  
    local IsEmpty = self.Zone:IsNoneInZone()
    self:F( { IsEmpty = IsEmpty } )
    return IsEmpty
  end


  function ZONE_GOAL_CARGO:IsCaptured()
  
    local IsCaptured = self.Zone:IsAllInZoneOfOtherCoalition( self.Coalition )
    self:F( { IsCaptured = IsCaptured } )
    return IsCaptured
  end
  
  
  function ZONE_GOAL_CARGO:IsAttacked()
  
    local IsAttacked = self.Zone:IsSomeInZoneOfCoalition( self.Coalition )
    self:F( { IsAttacked = IsAttacked } )
    return IsAttacked
  end
  
  

  --- Mark.
  -- @param #ZONE_GOAL_CARGO self
  function ZONE_GOAL_CARGO:Mark()
  
    local Coord = self.Zone:GetCoordinate()
    local ZoneName = self:GetZoneName()
    local State = self:GetState()
    
    if self.MarkRed and self.MarkBlue then
      self:F( { MarkRed = self.MarkRed, MarkBlue = self.MarkBlue } )
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
  -- @param #ZONE_GOAL_CARGO self
  function ZONE_GOAL_CARGO:onenterGuarded()
  
    --self:GetParent( self ):onenterGuarded()
  
    if self.Coalition == coalition.side.BLUE then
      --elf.ProtectZone:BoundZone( 12, country.id.USA )
    else
      --self.ProtectZone:BoundZone( 12, country.id.RUSSIA )
    end
    
    self:Mark()
    
  end
  
  function ZONE_GOAL_CARGO:onenterCaptured()
  
    --self:GetParent( self ):onenterCaptured()

    local NewCoalition = self.Zone:GetCoalition()
    self:F( { NewCoalition = NewCoalition } )
    self:SetCoalition( NewCoalition )
  
    self:Mark()
  end
  
  
  function ZONE_GOAL_CARGO:onenterEmpty()

    --self:GetParent( self ):onenterEmpty()
  
    self:Mark()
  end
  
  
  function ZONE_GOAL_CARGO:onenterAttacked()
  
    --self:GetParent( self ):onenterAttacked()
  
    self:Mark()
  end


  --- When started, check the Coalition status.
  -- @param #ZONE_GOAL_CARGO self
  function ZONE_GOAL_CARGO:onafterGuard()
  
    --self:F({BASE:GetParent( self )})
    --BASE:GetParent( self ).onafterGuard( self )
  
    if not self.SmokeScheduler then
      self.SmokeScheduler = self:ScheduleRepeat( 1, 1, 0.1, nil, self.StatusSmoke, self )
    end
    if not self.ScheduleStatusZone then
      self.ScheduleStatusZone = self:ScheduleRepeat( 15, 15, 0.1, nil, self.StatusZone, self )
    end
  end


  function ZONE_GOAL_CARGO:IsCaptured()
  
    local IsCaptured = self.Zone:IsAllInZoneOfOtherCoalition( self.Coalition )
    self:F( { IsCaptured = IsCaptured } )
    return IsCaptured
  end
  
  
  function ZONE_GOAL_CARGO:IsAttacked()
  
    local IsAttacked = self.Zone:IsSomeInZoneOfCoalition( self.Coalition )
    self:F( { IsAttacked = IsAttacked } )
    return IsAttacked
  end
  
  --- Check status Coalition ownership.
  -- @param #ZONE_GOAL_CARGO self
  function ZONE_GOAL_CARGO:StatusZone()
  
    local State = self:GetState()
    self:F( { State = self:GetState() } )
  
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

