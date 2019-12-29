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
-- ### Contributions: **funkyfranky**
-- 
-- ===
-- 
-- @module Functional.ZoneGoal
-- @image MOOSE.JPG

do -- Zone

  --- @type ZONE_GOAL
  -- @field #string ClassName Name of the class.
  -- @field Core.Goal#GOAL Goal The goal object.
  -- @field #number SmokeTime Time stamp in seconds when the last smoke of the zone was triggered.
  -- @field Core.Scheduler#SCHEDULER SmokeScheduler Scheduler responsible for smoking the zone.
  -- @field #number SmokeColor Color of the smoke.
  -- @field #boolean SmokeZone If true, smoke zone.
  -- @extends Core.Zone#ZONE_RADIUS


  --- Models processes that have a Goal with a defined achievement involving a Zone. 
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
    ClassName      = "ZONE_GOAL",
    Goal           = nil,
    SmokeTime      = nil,
    SmokeScheduler = nil,
    SmokeColor     = nil,
    SmokeZone      = nil,
  }
  
  --- ZONE_GOAL Constructor.
  -- @param #ZONE_GOAL self
  -- @param Core.Zone#ZONE_RADIUS Zone A @{Zone} object with the goal to be achieved.
  -- @return #ZONE_GOAL
  function ZONE_GOAL:New( Zone )
  
    local self = BASE:Inherit( self, ZONE_RADIUS:New( Zone:GetName(), Zone:GetVec2(), Zone:GetRadius() ) ) -- #ZONE_GOAL
    self:F( { Zone = Zone } )

    -- Goal object.
    self.Goal = GOAL:New()

    self.SmokeTime = nil
    
    -- Set smoke ON.
    self:SetSmokeZone(true)

    self:AddTransition( "*", "DestroyedUnit", "*" )

    --- DestroyedUnit event.
    -- @function [parent=#ZONE_GOAL] DestroyedUnit
    -- @param #ZONE_GOAL self

    --- DestroyedUnit delayed event
    -- @function [parent=#ZONE_GOAL] __DestroyedUnit
    -- @param #ZONE_GOAL self
    -- @param #number delay Delay in seconds.
  
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
  
  --- Get the Zone.
  -- @param #ZONE_GOAL self
  -- @return #ZONE_GOAL
  function ZONE_GOAL:GetZone()
    return self
  end
  
  
  --- Get the name of the Zone.
  -- @param #ZONE_GOAL self
  -- @return #string
  function ZONE_GOAL:GetZoneName()
    return self:GetName()
  end


  --- Activate smoking of zone with the color or the current owner.
  -- @param #ZONE_GOAL self
  -- @param #boolean switch If *true* or *nil* activate smoke. If *false* or *nil*, no smoke.
  -- @return #ZONE_GOAL
  function ZONE_GOAL:SetSmokeZone(switch)
    self.SmokeZone=switch
    --[[
    if switch==nil or switch==true then
      self.SmokeZone=true
    else
      self.SmokeZone=false
    end
    ]]
    return self
  end

  --- Set the smoke color.
  -- @param #ZONE_GOAL self
  -- @param DCS#SMOKECOLOR.Color SmokeColor
  function ZONE_GOAL:Smoke( SmokeColor ) 
    self:F( { SmokeColor = SmokeColor} )
  
    self.SmokeColor = SmokeColor
  end
    
  
  --- Flare the zone boundary.
  -- @param #ZONE_GOAL self
  -- @param DCS#SMOKECOLOR.Color FlareColor
  function ZONE_GOAL:Flare( FlareColor )
    self:FlareZone( FlareColor, 30)
  end


  --- When started, check the Smoke and the Zone status.
  -- @param #ZONE_GOAL self
  function ZONE_GOAL:onafterGuard()
    self:F("Guard")

    -- Start smoke
    if self.SmokeZone and not self.SmokeScheduler then
      self.SmokeScheduler = self:ScheduleRepeat(1, 1, 0.1, nil, self.StatusSmoke, self)
    end
  end


  --- Check status Smoke.
  -- @param #ZONE_GOAL self
  function ZONE_GOAL:StatusSmoke()
    self:F({self.SmokeTime, self.SmokeColor})
    
    if self.SmokeZone then
    
      -- Current time.
      local CurrentTime = timer.getTime()
    
      -- Restart smoke every 5 min.
      if self.SmokeTime == nil or self.SmokeTime + 300 <= CurrentTime then
        if self.SmokeColor then
          self:GetCoordinate():Smoke( self.SmokeColor )
          self.SmokeTime = CurrentTime
        end
      end
      
    end
    
  end


  --- @param #ZONE_GOAL self
  -- @param Core.Event#EVENTDATA EventData Event data table.
  function ZONE_GOAL:__Destroyed( EventData )
    self:F( { "EventDead", EventData } )

    self:F( { EventData.IniUnit } )
    
    if EventData.IniDCSUnit then

      local Vec3 = EventData.IniDCSUnit:getPosition().p
      self:F( { Vec3 = Vec3 } )    
    
      if Vec3 and self:IsVec3InZone(Vec3)  then
      
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
