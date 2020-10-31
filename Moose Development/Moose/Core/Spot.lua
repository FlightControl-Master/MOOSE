--- **Core** - Management of spotting logistics, that can be activated and deactivated upon command.
--
-- ===
-- 
-- SPOT implements the DCS Spot class functionality, but adds additional luxury to be able to:
-- 
--   * Spot for a defined duration.
--   * Updates of laer spot position every 0.2 seconds for moving targets.
--   * Wiggle the spot at the target.
--   * Provide a @{Wrapper.Unit} as a target, instead of a point.
--   * Implement a status machine, LaseOn, LaseOff.
--
-- ===
-- 
-- # Demo Missions
-- 
-- ### [SPOT Demo Missions source code]()
-- 
-- ### [SPOT Demo Missions, only for beta testers]()
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ===
-- 
-- # YouTube Channel
-- 
-- ### [SPOT YouTube Channel]()
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: 
-- 
--   * [**Ciribob**](https://forums.eagle.ru/member.php?u=112175): Showing the way how to lase targets + how laser codes work!!! Explained the autolase script.
--   * [**EasyEB**](https://forums.eagle.ru/member.php?u=112055): Ideas and Beta Testing
--   * [**Wingthor**](https://forums.eagle.ru/member.php?u=123698): Beta Testing
-- 
-- ===
-- 
-- @module Core.Spot
-- @image Core_Spot.JPG


do

  --- @type SPOT
  -- @extends Core.Fsm#FSM


  --- Implements the target spotting or marking functionality, but adds additional luxury to be able to:
  -- 
  --   * Mark targets for a defined duration.
  --   * Updates of laer spot position every 0.2 seconds for moving targets.
  --   * Wiggle the spot at the target.
  --   * Provide a @{Wrapper.Unit} as a target, instead of a point.
  --   * Implement a status machine, LaseOn, LaseOff.
  -- 
  -- ## 1. SPOT constructor
  --   
  --   * @{#SPOT.New}(..\Presentations\SPOT\Dia2.JPG): Creates a new SPOT object.
  -- 
  -- ## 2. SPOT is a FSM
  -- 
  -- ![Process]()
  -- 
  -- ### 2.1 SPOT States
  -- 
  --   * **Off**: Lasing is switched off.
  --   * **On**: Lasing is switched on.
  --   * **Destroyed**: Target is destroyed.
  -- 
  -- ### 2.2 SPOT Events
  -- 
  --   * **@{#SPOT.LaseOn}(Target, LaserCode, Duration)**: Lase to a target.
  --   * **@{#SPOT.LaseOff}()**: Stop lasing the target.
  --   * **@{#SPOT.Lasing}()**: Target is being lased.
  --   * **@{#SPOT.Destroyed}()**: Triggered when target is destroyed.
  -- 
  -- ## 3. Check if a Target is being lased
  -- 
  -- The method @{#SPOT.IsLasing}() indicates whether lasing is on or off.
  -- 
  -- @field #SPOT
  SPOT = {
    ClassName = "SPOT",
  }
  
  --- SPOT Constructor.
  -- @param #SPOT self
  -- @param Wrapper.Unit#UNIT Recce Unit that is lasing
  -- @return #SPOT
  function SPOT:New( Recce )
  
    local self = BASE:Inherit( self, FSM:New() ) -- #SPOT
    self:F( {} )
    
    self:SetStartState( "Off" )
    self:AddTransition( "Off", "LaseOn", "On" )
    
    --- LaseOn Handler OnBefore for SPOT
    -- @function [parent=#SPOT] OnBeforeLaseOn
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- LaseOn Handler OnAfter for SPOT
    -- @function [parent=#SPOT] OnAfterLaseOn
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- LaseOn Trigger for SPOT
    -- @function [parent=#SPOT] LaseOn
    -- @param #SPOT self
    -- @param Wrapper.Positionable#POSITIONABLE Target
    -- @param #number LaserCode Laser code.
    -- @param #number Duration Duration of lasing in seconds.
    
    --- LaseOn Asynchronous Trigger for SPOT
    -- @function [parent=#SPOT] __LaseOn
    -- @param #SPOT self
    -- @param #number Delay
    -- @param Wrapper.Positionable#POSITIONABLE Target
    -- @param #number LaserCode Laser code.
    -- @param #number Duration Duration of lasing in seconds.

    self:AddTransition( "Off", "LaseOnCoordinate", "On" )
    
    --- LaseOnCoordinate Handler OnBefore for SPOT.
    -- @function [parent=#SPOT] OnBeforeLaseOnCoordinate
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- LaseOnCoordinate Handler OnAfter for SPOT.
    -- @function [parent=#SPOT] OnAfterLaseOnCoordinate
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- LaseOnCoordinate Trigger for SPOT.
    -- @function [parent=#SPOT] LaseOnCoordinate
    -- @param #SPOT self
    -- @param Core.Point#COORDINATE Coordinate The coordinate to lase.
    -- @param #number LaserCode Laser code.
    -- @param #number Duration Duration of lasing in seconds.
    
    --- LaseOn Asynchronous Trigger for SPOT
    -- @function [parent=#SPOT] __LaseOn
    -- @param #SPOT self
    -- @param #number Delay
    -- @param Wrapper.Positionable#POSITIONABLE Target
    -- @param #number LaserCode Laser code.
    -- @param #number Duration Duration of lasing in seconds.

    
    
    self:AddTransition( "On",  "Lasing", "On" )
    self:AddTransition( { "On", "Destroyed" } , "LaseOff", "Off" )
    
    --- LaseOff Handler OnBefore for SPOT
    -- @function [parent=#SPOT] OnBeforeLaseOff
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- LaseOff Handler OnAfter for SPOT
    -- @function [parent=#SPOT] OnAfterLaseOff
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- LaseOff Trigger for SPOT
    -- @function [parent=#SPOT] LaseOff
    -- @param #SPOT self
    
    --- LaseOff Asynchronous Trigger for SPOT
    -- @function [parent=#SPOT] __LaseOff
    -- @param #SPOT self
    -- @param #number Delay
    
    self:AddTransition( "*" , "Destroyed", "Destroyed" )
    
    --- Destroyed Handler OnBefore for SPOT
    -- @function [parent=#SPOT] OnBeforeDestroyed
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Destroyed Handler OnAfter for SPOT
    -- @function [parent=#SPOT] OnAfterDestroyed
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Destroyed Trigger for SPOT
    -- @function [parent=#SPOT] Destroyed
    -- @param #SPOT self
    
    --- Destroyed Asynchronous Trigger for SPOT
    -- @function [parent=#SPOT] __Destroyed
    -- @param #SPOT self
    -- @param #number Delay
    
    
  
    self.Recce = Recce
  
    self.LaseScheduler = SCHEDULER:New( self )
  
    self:SetEventPriority( 5 )
    
    self.Lasing = false
  
    return self
  end
  
  --- On after LaseOn event. Activates the laser spot.
  -- @param #SPOT self
  -- @param From
  -- @param Event
  -- @param To
  -- @param Wrapper.Positionable#POSITIONABLE Target Unit that is being lased.
  -- @param #number LaserCode Laser code.
  -- @param #number Duration Duration of lasing in seconds.
  function SPOT:onafterLaseOn( From, Event, To, Target, LaserCode, Duration )
    self:F( { "LaseOn", Target, LaserCode, Duration } )

    local function StopLase( self )
      self:LaseOff()
    end
    
    self.Target = Target
    self.LaserCode = LaserCode
    
    self.Lasing = true
    
    local RecceDcsUnit = self.Recce:GetDCSObject()
    
    self.SpotIR = Spot.createInfraRed( RecceDcsUnit, { x = 0, y = 2, z = 0 }, Target:GetPointVec3():AddY(1):GetVec3() )
    self.SpotLaser = Spot.createLaser( RecceDcsUnit, { x = 0, y = 2, z = 0 }, Target:GetPointVec3():AddY(1):GetVec3(), LaserCode )

    if Duration then
      self.ScheduleID = self.LaseScheduler:Schedule( self, StopLase, {self}, Duration )
    end
    
    self:HandleEvent( EVENTS.Dead )
    
    self:__Lasing( -1 )
  end
  
  
  --- On after LaseOnCoordinate event. Activates the laser spot.
  -- @param #SPOT self
  -- @param From
  -- @param Event
  -- @param To
  -- @param Core.Point#COORDINATE Coordinate The coordinate at which the laser is pointing.
  -- @param #number LaserCode Laser code.
  -- @param #number Duration Duration of lasing in seconds.
  function SPOT:onafterLaseOnCoordinate(From, Event, To, Coordinate, LaserCode, Duration)
    self:F( { "LaseOnCoordinate", Coordinate, LaserCode, Duration } )

    local function StopLase( self )
      self:LaseOff()
    end
    
    self.Target = nil
    self.TargetCoord=Coordinate
    self.LaserCode = LaserCode
    
    self.Lasing = true
    
    local RecceDcsUnit = self.Recce:GetDCSObject()
    
    self.SpotIR = Spot.createInfraRed( RecceDcsUnit, { x = 0, y = 1, z = 0 }, Coordinate:GetVec3() )
    self.SpotLaser = Spot.createLaser( RecceDcsUnit, { x = 0, y = 1, z = 0 }, Coordinate:GetVec3(), LaserCode )

    if Duration then
      self.ScheduleID = self.LaseScheduler:Schedule( self, StopLase, {self}, Duration )
    end
    
    self:__Lasing(-1)
  end  

  --- @param #SPOT self
  -- @param Core.Event#EVENTDATA EventData
  function SPOT:OnEventDead(EventData)
    self:F( { Dead = EventData.IniDCSUnitName, Target = self.Target } )
    if self.Target then
      if EventData.IniDCSUnitName == self.Target:GetName() then
        self:F( {"Target dead ", self.Target:GetName() } )
        self:Destroyed()
        self:LaseOff()
      end
    end
  end
  
  --- @param #SPOT self
  -- @param From
  -- @param Event
  -- @param To
  function SPOT:onafterLasing( From, Event, To )
  
    if self.Target and self.Target:IsAlive() then
      self.SpotIR:setPoint( self.Target:GetPointVec3():AddY(1):AddY(math.random(-100,100)/100):AddX(math.random(-100,100)/100):GetVec3() )
      self.SpotLaser:setPoint( self.Target:GetPointVec3():AddY(1):GetVec3() )
      self:__Lasing( -0.2 )
    elseif self.TargetCoord then
    
      -- Wiggle the IR spot a bit.  
      local irvec3={x=self.TargetCoord.x+math.random(-100,100)/100, y=self.TargetCoord.y+math.random(-100,100)/100, z=self.TargetCoord.z} --#DCS.Vec3
      local lsvec3={x=self.TargetCoord.x, y=self.TargetCoord.y, z=self.TargetCoord.z} --#DCS.Vec3
      
      self.SpotIR:setPoint(irvec3)
      self.SpotLaser:setPoint(lsvec3)
      
      self:__Lasing(-0.25)    
    else
      self:F( { "Target is not alive", self.Target:IsAlive() } )
    end
  
  end

  --- @param #SPOT self
  -- @param From
  -- @param Event
  -- @param To
  -- @return #SPOT
  function SPOT:onafterLaseOff( From, Event, To )
  
    self:F( {"Stopped lasing for ", self.Target and self.Target:GetName() or "coord", SpotIR = self.SportIR, SpotLaser = self.SpotLaser } )
    
    self.Lasing = false
    
    self.SpotIR:destroy()
    self.SpotLaser:destroy()

    self.SpotIR = nil
    self.SpotLaser = nil
    
    if self.ScheduleID then
      self.LaseScheduler:Stop(self.ScheduleID)
    end
    self.ScheduleID = nil
    
    self.Target = nil
    
    return self
  end
  
  --- Check if the SPOT is lasing
  -- @param #SPOT self
  -- @return #boolean true if it is lasing
  function SPOT:IsLasing()
    return self.Lasing
  end
  
end