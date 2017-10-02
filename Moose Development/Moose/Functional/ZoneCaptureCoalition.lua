--- **Core** -- Base class that models processes to capture a Zone for a Coalition, guarded by another Coalition.
--
-- ====
-- 
-- ZONE_CAPTURE_COALITION models processes that have an objective with a defined achievement involving a Zone. Derived classes implement the ways how the achievements can be realized.
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
  -- @extends Core.ZoneGoalCoalition#ZONE_GOAL_COALITION


  --- # ZONE_CAPTURE_COALITION class, extends @{Goal#GOAL}
  -- 
  -- ZONE_CAPTURE_COALITION models processes that have an objective with a defined achievement involving a Zone. Derived classes implement the ways how the achievements can be realized.
  -- 
  -- ## 1. ZONE_CAPTURE_COALITION constructor
  --   
  --   * @{#ZONE_CAPTURE_COALITION.New}(): Creates a new ZONE_CAPTURE_COALITION object.
  -- 
  -- ## 2. ZONE_CAPTURE_COALITION is a finite state machine (FSM).
  -- 
  -- ### 2.1 ZONE_CAPTURE_COALITION States
  -- 
  -- ### 2.2 ZONE_CAPTURE_COALITION Events
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

    return self
  end
  

  --- @param #ZONE_CAPTURE_COALITION self
  function ZONE_CAPTURE_COALITION:onenterCaptured()
  
    self:GetParent( self ):onenterCaptured()
    
    self.Goal:Achieved()
  end
  
end

