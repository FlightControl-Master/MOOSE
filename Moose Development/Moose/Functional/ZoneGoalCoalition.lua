--- **Functional** - Base class that models processes to achieve goals involving a Zone for a Coalition.
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
  -- @field #string ClassName Name of the Class.
  -- @field #number Coalition The current coalition ID of the zone owner.
  -- @field #number PreviousCoalition The previous owner of the zone.
  -- @field #table UnitCategories Table of unit categories that are able to capture and hold the zone. Default is only GROUND units.
  -- @field #table ObjectCategories Table of object categories that are able to hold a zone. Default is UNITS and STATICS.
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
    Coalition = nil,
    PreviousCoalition = nil,
    UnitCategories = nil,
    ObjectCategories = nil,
  }

  --- @field #table ZONE_GOAL_COALITION.States
  ZONE_GOAL_COALITION.States = {}

  --- ZONE_GOAL_COALITION Constructor.
  -- @param #ZONE_GOAL_COALITION self
  -- @param Core.Zone#ZONE Zone A @{Core.Zone} object with the goal to be achieved.
  -- @param DCSCoalition.DCSCoalition#coalition Coalition The initial coalition owning the zone. Default coalition.side.NEUTRAL.
  -- @param #table UnitCategories Table of unit categories. See [DCS Class Unit](https://wiki.hoggitworld.com/view/DCS_Class_Unit). Default {Unit.Category.GROUND_UNIT}.
  -- @return #ZONE_GOAL_COALITION
  function ZONE_GOAL_COALITION:New( Zone, Coalition, UnitCategories )

    if not Zone then
      BASE:E( "ERROR: No Zone specified in ZONE_GOAL_COALITION!" )
      return nil
    end

    -- Inherit ZONE_GOAL.
    local self = BASE:Inherit( self, ZONE_GOAL:New( Zone ) ) -- #ZONE_GOAL_COALITION
    self:F( { Zone = Zone, Coalition = Coalition } )

    -- Set initial owner.
    self:SetCoalition( Coalition or coalition.side.NEUTRAL )

    -- Set default unit and object categories for the zone scan.
    self:SetUnitCategories( UnitCategories )
    self:SetObjectCategories()

    return self
  end

  --- Set the owning coalition of the zone.
  -- @param #ZONE_GOAL_COALITION self
  -- @param DCSCoalition.DCSCoalition#coalition Coalition The coalition ID, e.g. *coalition.side.RED*.
  -- @return #ZONE_GOAL_COALITION
  function ZONE_GOAL_COALITION:SetCoalition( Coalition )
    self.PreviousCoalition = self.Coalition or Coalition
    self.Coalition = Coalition
    return self
  end

  --- Set the owning coalition of the zone.
  -- @param #ZONE_GOAL_COALITION self
  -- @param #table UnitCategories Table of unit categories. See [DCS Class Unit](https://wiki.hoggitworld.com/view/DCS_Class_Unit). Default {Unit.Category.GROUND_UNIT}.
  -- @return #ZONE_GOAL_COALITION
  function ZONE_GOAL_COALITION:SetUnitCategories( UnitCategories )

    if UnitCategories and type( UnitCategories ) ~= "table" then
      UnitCategories = { UnitCategories }
    end

    self.UnitCategories = UnitCategories or { Unit.Category.GROUND_UNIT }

    return self
  end

  --- Set the owning coalition of the zone.
  -- @param #ZONE_GOAL_COALITION self
  -- @param #table ObjectCategories Table of unit categories. See [DCS Class Object](https://wiki.hoggitworld.com/view/DCS_Class_Object). Default {Object.Category.UNIT, Object.Category.STATIC}, i.e. all UNITS and STATICS.
  -- @return #ZONE_GOAL_COALITION
  function ZONE_GOAL_COALITION:SetObjectCategories( ObjectCategories )

    if ObjectCategories and type( ObjectCategories ) ~= "table" then
      ObjectCategories = { ObjectCategories }
    end

    self.ObjectCategories = ObjectCategories or { Object.Category.UNIT, Object.Category.STATIC }

    return self
  end

  --- Get the owning coalition of the zone.
  -- @param #ZONE_GOAL_COALITION self
  -- @return DCSCoalition.DCSCoalition#coalition Coalition.
  function ZONE_GOAL_COALITION:GetCoalition()
    return self.Coalition
  end

  --- Get the previous coalition, i.e. the one owning the zone before the current one. 
  -- @param #ZONE_GOAL_COALITION self
  -- @return DCSCoalition.DCSCoalition#coalition Coalition.
  function ZONE_GOAL_COALITION:GetPreviousCoalition()
    return self.PreviousCoalition
  end

  --- Get the owning coalition name of the zone.
  -- @param #ZONE_GOAL_COALITION self
  -- @return #string Coalition name.
  function ZONE_GOAL_COALITION:GetCoalitionName()
    return UTILS.GetCoalitionName( self.Coalition )
  end

  --- Check status Coalition ownership.
  -- @param #ZONE_GOAL_COALITION self
  -- @return #ZONE_GOAL_COALITION
  function ZONE_GOAL_COALITION:StatusZone()

    -- Get current state.
    local State = self:GetState()

    -- Debug text.
    local text = string.format( "Zone state=%s, Owner=%s, Scanning...", State, self:GetCoalitionName() )
    self:F( text )

    -- Scan zone.
    self:Scan( self.ObjectCategories, self.UnitCategories )

    return self
  end

end

