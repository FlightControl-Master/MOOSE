--- **Functional (WIP)** -- Base class that models processes to achieve goals involving a Zone.
--
-- ===
-- 
-- ZONE_GOAL models processes that have a Goal with a defined achievement involving a Zone. 
-- Derived classes implement the ways how the achievements can be realized.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===
-- 
-- @module Functional.ZoneGoal
-- @image MOOSE.JPG

do -- Zone

  --- @type ZONE_GOAL
  -- @extends Core.Fsm#FSM


  -- Models processes that have a Goal with a defined achievement involving a Zone. 
  -- Derived classes implement the ways how the achievements can be realized.
  -- 
  -- ## 1. ZONE_GOAL constructor
  --   
  --   * @{#ZONE_GOAL.New}(): Creates a new ZONE_GOAL object.
  -- 
  -- ## 2. ZONE_GOAL is a finite state machine (FSM).
  -- 
  -- ### 2.1 ZONE_GOAL States
  -- 
  --  * None: Initial State
  -- 
  -- ### 2.2 ZONE_GOAL Events
  -- 
  --   * DestroyedUnit: A @{Wrapper.Unit} is destroyed in the Zone. The event will only get triggered if the method @{#ZONE_GOAL.MonitorDestroyedUnits}() is used.
  -- 
  -- @field #ZONE_GOAL
  ZONE_GOAL = {
    ClassName = "ZONE_GOAL",
  }
  
  --- ZONE_GOAL Constructor.
  -- @param #ZONE_GOAL self
  -- @param Core.Zone#ZONE_BASE Zone A @{Zone} object with the goal to be achieved.
  -- @return #ZONE_GOAL
  function ZONE_GOAL:New( Zone )
  
    local self = BASE:Inherit( self, FSM:New() ) -- #ZONE_GOAL
    self:F( { Zone = Zone } )

    self.Zone = Zone -- Core.Zone#ZONE_BASE
    self.Goal = GOAL:New()

    self.SmokeTime = nil

    self:AddTransition( "*", "DestroyedUnit", "*" )
  
    --- DestroyedUnit Handler OnAfter for ZONE_GOAL
    -- @function [parent=#ZONE_GOAL] OnAfterDestroyedUnit
    -- @param #ZONE_GOAL self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Wrapper.Unit#UNIT DestroyedUnit The destroyed unit.
    -- @param #string PlayerName The name of the player.

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
    
    self:F("Guard")
  
    --self:ScheduleRepeat( 15, 15, 0.1, nil, self.StatusZone, self )
    if not self.SmokeScheduler then
      self.SmokeScheduler = self:ScheduleRepeat( 1, 1, 0.1, nil, self.StatusSmoke, self )
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


  --- @param #ZONE_GOAL self
  -- @param Core.Event#EVENTDATA EventData
  function ZONE_GOAL:__Destroyed( EventData )
    self:F( { "EventDead", EventData } )

    self:F( { EventData.IniUnit } )
    
    local Vec3 = EventData.IniDCSUnit:getPosition().p
    self:F( { Vec3 = Vec3 } )
    local ZoneGoal = self:GetZone()
    self:F({ZoneGoal})

    if EventData.IniDCSUnit then
      if ZoneGoal:IsVec3InZone(Vec3)  then
        local PlayerHits = _DATABASE.HITS[EventData.IniUnitName]
        if PlayerHits then
          for PlayerName, PlayerHit in pairs( PlayerHits.Players or {} ) do
            self.Goal:AddPlayerContribution( PlayerName )
            self:DestroyedUnit( EventData.IniUnitName, PlayerName )
          end
        end
      end
    end
  end
  
  
  --- Activate the event UnitDestroyed to be fired when a unit is destroyed in the zone.
  -- @param #ZONE_GOAL self
  function ZONE_GOAL:MonitorDestroyedUnits()

    self:HandleEvent( EVENTS.Dead,  self.__Destroyed )
    self:HandleEvent( EVENTS.Crash, self.__Destroyed )
  
  end
  
end
