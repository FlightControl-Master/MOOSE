--- **Functional (wIP)** -- Models the process to capture a Zone for a Coalition, which is guarded by another Coalition.
--
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ====
-- 
-- @module ZoneCaptureCoalition

do -- ZoneGoal

  --- @type ZONE_CAPTURE_COALITION
  -- @extends Functional.ZoneGoalCoalition#ZONE_GOAL_COALITION


  --- # ZONE_CAPTURE_COALITION class, extends @{ZoneGoalCoalition#ZONE_GOAL_COALITION}
  -- 
  -- Models the process to capture a Zone for a Coalition, which is guarded by another Coalition.
  -- 
  -- The Zone is initially **Guarded** by the __owning coalition__, which is the coalition that initially occupies the zone with units of its coalition.
  -- Once units of an other coalition are entering the Zone, the state will change to **Attacked**. As long as these units remain in the zone, the state keeps set to Attacked.
  -- When all units are destroyed in the Zone, the state will change to **Empty**, which expresses that the Zone is empty, and can be captured.
  -- When units of the other coalition are in the Zone, and no other units of the owning coalition is in the Zone, the Zone is captured, and its state will change to **Captured**.
  -- 
  -- Event handlers can be defined by the mission designer to action on the state transitions.
  -- 
  -- ## 1. ZONE_CAPTURE_COALITION constructor
  --   
  --   * @{#ZONE_CAPTURE_COALITION.New}(): Creates a new ZONE_CAPTURE_COALITION object.
  -- 
  -- ## 2. ZONE_CAPTURE_COALITION is a finite state machine (FSM).
  -- 
  -- ### 2.1 ZONE_CAPTURE_COALITION States
  -- 
  --   * **Captured**: The Zone has been captured by an other coalition.
  --   * **Attacked**: The Zone is currently intruded by an other coalition. There are units of the owning coalition and an other coalition in the Zone.
  --   * **Guarded**: The Zone is guarded by the owning coalition. There is no other unit of an other coalition in the Zone.
  --   * **Empty**: The Zone is empty. There is not valid unit in the Zone.
  --   
  -- ### 2.2 ZONE_CAPTURE_COALITION Events
  -- 
  --   * **Capture**: The Zone has been captured by an other coalition.
  --   * **Attack**: The Zone is currently intruded by an other coalition. There are units of the owning coalition and an other coalition in the Zone.
  --   * **Guard**: The Zone is guarded by the owning coalition. There is no other unit of an other coalition in the Zone.
  --   * **Empty**: The Zone is empty. There is not valid unit in the Zone.
  --   
  -- @field #ZONE_CAPTURE_COALITION
  ZONE_CAPTURE_COALITION = {
    ClassName = "ZONE_CAPTURE_COALITION",
  }
  
  --- @field #table ZONE_CAPTURE_COALITION.States
  ZONE_CAPTURE_COALITION.States = {}
  
  --- ZONE_CAPTURE_COALITION Constructor.
  -- @param #ZONE_CAPTURE_COALITION self
  -- @param Core.Zone#ZONE Zone A @{Zone} object with the goal to be achieved.
  -- @param DCSCoalition.DCSCoalition#coalition Coalition The initial coalition owning the zone.
  -- @return #ZONE_CAPTURE_COALITION
  function ZONE_CAPTURE_COALITION:New( Zone, Coalition )
  
    local self = BASE:Inherit( self, ZONE_GOAL_COALITION:New( Zone, Coalition ) ) -- #ZONE_CAPTURE_COALITION

    self:F( { Zone = Zone, Coalition  = Coalition } )

    do 
    
      --- Captured State Handler OnLeave for ZONE_CAPTURE_COALITION
      -- @function [parent=#ZONE_CAPTURE_COALITION] OnLeaveCaptured
      -- @param #ZONE_CAPTURE_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Captured State Handler OnEnter for ZONE_CAPTURE_COALITION
      -- @function [parent=#ZONE_CAPTURE_COALITION] OnEnterCaptured
      -- @param #ZONE_CAPTURE_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  
  
    do 
    
      --- Attacked State Handler OnLeave for ZONE_CAPTURE_COALITION
      -- @function [parent=#ZONE_CAPTURE_COALITION] OnLeaveAttacked
      -- @param #ZONE_CAPTURE_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Attacked State Handler OnEnter for ZONE_CAPTURE_COALITION
      -- @function [parent=#ZONE_CAPTURE_COALITION] OnEnterAttacked
      -- @param #ZONE_CAPTURE_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end

    do 
    
      --- Guarded State Handler OnLeave for ZONE_CAPTURE_COALITION
      -- @function [parent=#ZONE_CAPTURE_COALITION] OnLeaveGuarded
      -- @param #ZONE_CAPTURE_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Guarded State Handler OnEnter for ZONE_CAPTURE_COALITION
      -- @function [parent=#ZONE_CAPTURE_COALITION] OnEnterGuarded
      -- @param #ZONE_CAPTURE_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  

    do 
    
      --- Empty State Handler OnLeave for ZONE_CAPTURE_COALITION
      -- @function [parent=#ZONE_CAPTURE_COALITION] OnLeaveEmpty
      -- @param #ZONE_CAPTURE_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
      -- @return #boolean
  
      --- Empty State Handler OnEnter for ZONE_CAPTURE_COALITION
      -- @function [parent=#ZONE_CAPTURE_COALITION] OnEnterEmpty
      -- @param #ZONE_CAPTURE_COALITION self
      -- @param #string From
      -- @param #string Event
      -- @param #string To
  
    end
  
    self:AddTransition( "*", "Guard", "Guarded" )
    
    --- Guard Handler OnBefore for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] OnBeforeGuard
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Guard Handler OnAfter for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] OnAfterGuard
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Guard Trigger for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] Guard
    -- @param #ZONE_CAPTURE_COALITION self
    
    --- Guard Asynchronous Trigger for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] __Guard
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #number Delay
    
    self:AddTransition( "*", "Empty", "Empty" )
    
    --- Empty Handler OnBefore for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] OnBeforeEmpty
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Empty Handler OnAfter for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] OnAfterEmpty
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Empty Trigger for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] Empty
    -- @param #ZONE_CAPTURE_COALITION self
    
    --- Empty Asynchronous Trigger for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] __Empty
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #number Delay
    
    
    self:AddTransition( {  "Guarded", "Empty" }, "Attack", "Attacked" )
  
    --- Attack Handler OnBefore for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] OnBeforeAttack
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Attack Handler OnAfter for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] OnAfterAttack
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Attack Trigger for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] Attack
    -- @param #ZONE_CAPTURE_COALITION self
    
    --- Attack Asynchronous Trigger for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] __Attack
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #number Delay
    
    self:AddTransition( { "Guarded", "Attacked", "Empty" }, "Capture", "Captured" )
   
    --- Capture Handler OnBefore for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] OnBeforeCapture
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Capture Handler OnAfter for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] OnAfterCapture
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Capture Trigger for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] Capture
    -- @param #ZONE_CAPTURE_COALITION self
    
    --- Capture Asynchronous Trigger for ZONE_CAPTURE_COALITION
    -- @function [parent=#ZONE_CAPTURE_COALITION] __Capture
    -- @param #ZONE_CAPTURE_COALITION self
    -- @param #number Delay

    return self
  end
  

  --- @param #ZONE_CAPTURE_COALITION self
  function ZONE_CAPTURE_COALITION:onenterCaptured()
  
    self:GetParent( self, ZONE_CAPTURE_COALITION ).onenterCaptured( self )
    
    self.Goal:Achieved()
  end


  function ZONE_CAPTURE_COALITION:IsGuarded()
  
    local IsGuarded = self.Zone:IsAllInZoneOfCoalition( self.Coalition )
    self:E( { IsGuarded = IsGuarded } )
    return IsGuarded
  end


  function ZONE_CAPTURE_COALITION:IsEmpty()
  
    local IsEmpty = self.Zone:IsNoneInZone()
    self:E( { IsEmpty = IsEmpty } )
    return IsEmpty
  end


  function ZONE_CAPTURE_COALITION:IsCaptured()
  
    local IsCaptured = self.Zone:IsAllInZoneOfOtherCoalition( self.Coalition )
    self:E( { IsCaptured = IsCaptured } )
    return IsCaptured
  end
  
  
  function ZONE_CAPTURE_COALITION:IsAttacked()
  
    local IsAttacked = self.Zone:IsSomeInZoneOfCoalition( self.Coalition )
    self:E( { IsAttacked = IsAttacked } )
    return IsAttacked
  end
  
  

  --- Mark.
  -- @param #ZONE_CAPTURE_COALITION self
  function ZONE_CAPTURE_COALITION:Mark()
  
    local Coord = self.Zone:GetCoordinate()
    local ZoneName = self:GetZoneName()
    local State = self:GetState()
    
    if self.MarkRed and self.MarkBlue then
      self:E( { MarkRed = self.MarkRed, MarkBlue = self.MarkBlue } )
      Coord:RemoveMark( self.MarkRed )
      Coord:RemoveMark( self.MarkBlue )
    end
    
    if self.Coalition == coalition.side.BLUE then
      self.MarkBlue = Coord:MarkToCoalitionBlue( "Coalition: Blue\nGuard Zone: " .. ZoneName .. "\nStatus: " .. State )  
      self.MarkRed = Coord:MarkToCoalitionRed( "Coalition: Blue\nCapture Zone: " .. ZoneName .. "\nStatus: " .. State )
    else
      self.MarkRed = Coord:MarkToCoalitionRed( "Coalition: Red\nGuard Zone: " .. ZoneName .. "\nStatus: " .. State )  
      self.MarkBlue = Coord:MarkToCoalitionBlue( "Coalition: Red\nCapture Zone: " .. ZoneName .. "\nStatus: " .. State )  
    end
  end

  --- Bound.
  -- @param #ZONE_CAPTURE_COALITION self
  function ZONE_CAPTURE_COALITION:onenterGuarded()
  
    --self:GetParent( self ):onenterGuarded()
  
    if self.Coalition == coalition.side.BLUE then
      --elf.ProtectZone:BoundZone( 12, country.id.USA )
    else
      --self.ProtectZone:BoundZone( 12, country.id.RUSSIA )
    end
    
    self:Mark()
    
  end
  
  function ZONE_CAPTURE_COALITION:onenterCaptured()
  
    --self:GetParent( self ):onenterCaptured()

    local NewCoalition = self.Zone:GetScannedCoalition()
    self:E( { NewCoalition = NewCoalition } )
    self:SetCoalition( NewCoalition )
  
    self:Mark()
  end
  
  
  function ZONE_CAPTURE_COALITION:onenterEmpty()

    --self:GetParent( self ):onenterEmpty()
  
    self:Mark()
  end
  
  
  function ZONE_CAPTURE_COALITION:onenterAttacked()
  
    --self:GetParent( self ):onenterAttacked()
  
    self:Mark()
  end


  --- When started, check the Coalition status.
  -- @param #ZONE_CAPTURE_COALITION self
  function ZONE_CAPTURE_COALITION:onafterGuard()
  
    --self:E({BASE:GetParent( self )})
    --BASE:GetParent( self ).onafterGuard( self )
  
    if not self.SmokeScheduler then
      self.SmokeScheduler = self:ScheduleRepeat( 1, 1, 0.1, nil, self.StatusSmoke, self )
    end
    if not self.ScheduleStatusZone then
      self.ScheduleStatusZone = self:ScheduleRepeat( 15, 15, 0.1, nil, self.StatusZone, self )
    end
  end


  function ZONE_CAPTURE_COALITION:IsCaptured()
  
    local IsCaptured = self.Zone:IsAllInZoneOfOtherCoalition( self.Coalition )
    self:E( { IsCaptured = IsCaptured } )
    return IsCaptured
  end
  
  
  function ZONE_CAPTURE_COALITION:IsAttacked()
  
    local IsAttacked = self.Zone:IsSomeInZoneOfCoalition( self.Coalition )
    self:E( { IsAttacked = IsAttacked } )
    return IsAttacked
  end
  

  --- Check status Coalition ownership.
  -- @param #ZONE_CAPTURE_COALITION self
  function ZONE_CAPTURE_COALITION:StatusZone()
  
    local State = self:GetState()
    self:E( { State = self:GetState() } )
  
    self:GetParent( self, ZONE_CAPTURE_COALITION ).StatusZone( self )
    
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

