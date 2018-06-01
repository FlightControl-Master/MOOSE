--- **Functional (WIP)** -- Base class that models processes to achieve goals involving a Zone for a Coalition.
--
-- ===
-- 
-- ZONE_GOAL_COALITION models processes that have a Goal with a defined achievement involving a Zone for a Coalition.  
-- Derived classes implement the ways how the achievements can be realized.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===
-- 
-- @module Functional.ZoneGoalCoalition
-- @image MOOSE.JPG

do -- ZoneGoal

  --- @type ZONE_GOAL_COALITION
  -- @extends Functional.ZoneGoal#ZONE_GOAL


  --- ZONE_GOAL_COALITION models processes that have a Goal with a defined achievement involving a Zone for a Coalition.  
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
  -- ### 2.2 ZONE_GOAL_COALITION Events
  -- 
  -- ### 2.3 ZONE_GOAL_COALITION State Machine
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
  
    local self = BASE:Inherit( self, ZONE_GOAL:New( Zone ) ) -- #ZONE_GOAL_COALITION
    self:F( { Zone = Zone, Coalition  = Coalition  } )

    self:SetCoalition( Coalition )


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


  --- Check status Coalition ownership.
  -- @param #ZONE_GOAL_COALITION self
  function ZONE_GOAL_COALITION:StatusZone()
  
    local State = self:GetState()
    self:F( { State = self:GetState() } )
  
    self.Zone:Scan( { Object.Category.UNIT, Object.Category.STATIC } )
  
  end
  
end

