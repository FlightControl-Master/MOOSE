--- This module contains the AI\_PATROLZONE class.
-- 
-- ===
-- 
-- 1) @{#AI_PATROLZONE} class, extends @{StateMachine#STATEMACHINE}
-- ================================================================
-- The @{#AI_PATROLZONE} class implements the core functions to patrol a @{Zone} by an AIR @{Group}.
-- The patrol algorithm works that for each airplane patrolling, upon arrival at the patrol zone,
-- a random point is selected as the route point within the 3D space, within the given boundary limits.
-- The airplane will fly towards the random 3D point within the patrol zone, using a random speed within the given altitude and speed limits.
-- Upon arrival at the random 3D point, a new 3D random point will be selected within the patrol zone using the given limits.
-- This cycle will continue until a fuel treshold has been reached by the airplane.
-- When the fuel treshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- 1.1) AI\_PATROLZONE constructor:
-- ----------------------------
--   
--   * @{#AI_PATROLZONE.New}(): Creates a new AI\_PATROLZONE object.
-- 
-- 1.2) AI\_PATROLZONE state machine:
-- ----------------------------------
-- The AI\_PATROLZONE is a state machine: it manages the different events and states of the AIGroup it is controlling.
-- 
-- ### 1.2.1) AI\_PATROLZONE Events:
-- 
--   * @{#AI_PATROLZONE.Route}( AIGroup ):  A new 3D route point is selected and the AIGroup will fly towards that point with the given speed.
--   * @{#AI_PATROLZONE.Patrol}( AIGroup ): The AIGroup reports it is patrolling. This event is called every 30 seconds.
--   * @{#AI_PATROLZONE.RTB}( AIGroup ): The AIGroup will report return to base.
--   * @{#AI_PATROLZONE.End}( AIGroup ): The end of the AI\_PATROLZONE process.
--   * @{#AI_PATROLZONE.Dead}( AIGroup ): The AIGroup is dead. The AI\_PATROLZONE process will be ended.
-- 
-- ### 1.2.2) AI\_PATROLZONE States:
-- 
--   * **Route**: A new 3D route point is selected and the AIGroup will fly towards that point with the given speed.
--   * **Patrol**: The AIGroup is patrolling. This state is set every 30 seconds, so every 30 seconds, a state transition function can be used.
--   * **RTB**: The AIGroup reports it wants to return to the base.
--   * **Dead**: The AIGroup is dead ...
--   * **End**: The process has come to an end.
--   
-- ### 1.2.3) AI\_PATROLZONE state transition functions:
-- 
-- State transition functions can be set **by the mission designer** customizing or improving the behaviour of the state.
-- There are 2 moments when state transition functions will be called by the state machine:
-- 
--   * **Before** the state transition. 
--     The state transition function needs to start with the name **OnBefore + the name of the state**. 
--     If the state transition function returns false, then the processing of the state transition will not be done!
--     If you want to change the behaviour of the AIGroup at this event, return false, 
--     but then you'll need to specify your own logic using the AIGroup!
--   
--   * **After** the state transition. 
--     The state transition function needs to start with the name **OnAfter + the name of the state**. 
--     These state transition functions need to provide a return value, which is specified at the function description.
--
-- An example how to manage a state transition for an AI\_PATROLZONE object **Patrol** for the state **RTB**:
-- 
--      local PatrolZoneGroup = GROUP:FindByName( "Patrol Zone" )
--      local PatrolZone = ZONE_POLYGON:New( "PatrolZone", PatrolZoneGroup )
--
--      local PatrolSpawn = SPAWN:New( "Patrol Group" )
--      local PatrolGroup = PatrolSpawn:Spawn()
--
--      local Patrol = AI_PATROLZONE:New( PatrolZone, 3000, 6000, 300, 600 )
--      Patrol:AddGroup( PatrolGroup )
--      Patrol:ManageFuel( 0.2, 60 )
--
-- **OnBefore**RTB( AIGroup ) will be called by the AI\_PATROLZONE object when the AIGroup reports RTB, but **before** the RTB default action is processed by the AI_PATROLZONE object.
--
--      --- State transition function for the AI\_PATROLZONE **Patrol** object
--      -- @param #AI_PATROLZONE self 
--      -- @param Group#GROUP AIGroup
--      -- @return #boolean If false is returned, then the OnAfter state transition function will not be called.
--      function Patrol:OnBeforeRTB( AIGroup )
--        AIGroup:MessageToRed( "Returning to base", 20 )
--      end
--       
-- **OnAfter**RTB( AIGroup ) will be called by the AI\_PATROLZONE object when the AIGroup reports RTB, but **after** the RTB default action was processed by the AI_PATROLZONE object.
--
--      --- State transition function for the AI\_PATROLZONE **Patrol** object
--      -- @param #AI_PATROLZONE self 
--      -- @param Group#GROUP AIGroup
--      -- @return #Group#GROUP The new AIGroup object that is set to be patrolling the zone.
--      function Patrol:OnAfterRTB( AIGroup )
--        return PatrolSpawn:Spawn()
--      end 
--    
-- 1.3) Modify the AI\_PATROLZONE parameters:
-- --------------------------------------
-- The following methods are available to modify the parameters of a AI\_PATROLZONE object:
-- 
--   * @{#AI_PATROLZONE.SetGroup}(): Set the AI Patrol Group.
--   * @{#AI_PATROLZONE.SetSpeed}(): Set the patrol speed of the AI, for the next patrol.
--   * @{#AI_PATROLZONE.SetAltitude}(): Set altitude of the AI, for the next patrol.
-- 
-- 1.3) Manage the out of fuel in the AI\_PATROLZONE:
-- ----------------------------------------------
-- When the PatrolGroup is out of fuel, it is required that a new PatrolGroup is started, before the old PatrolGroup can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the PatrolGroup will continue for a given time its patrol task in orbit, while a new PatrolGroup is targetted to the AI\_PATROLZONE.
-- Once the time is finished, the old PatrolGroup will return to the base.
-- Use the method @{#AI_PATROLZONE.ManageFuel}() to have this proces in place.
-- 
-- ====
-- 
-- **API CHANGE HISTORY**
-- ======================
-- 
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
-- 
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
-- 
-- Hereby the change log:
-- 
-- 2016-08-17: AI\_PATROLZONE:New( **PatrolSpawn,** PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed ) replaces AI\_PATROLZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed )
-- 
-- 2016-07-01: Initial class and API.
-- 
-- ===
-- 
-- AUTHORS and CONTRIBUTIONS
-- =========================
-- 
-- ### Contributions: 
-- 
--   * **DutchBaron**: Testing.
-- 
-- ### Authors: 
-- 
--   * **FlightControl**: Design & Programming
-- 
-- 
-- @module AI_PatrolZone



--- AI\_PATROLZONE class
-- @type AI_PATROLZONE
-- @field Group#GROUP PatrolGroup The @{Group} patrolling.
-- @field Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @field DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @field DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @field DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Group} in km/h.
-- @field DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Group} in km/h.
-- @extends StateMachine#StateMachine
AI_PATROLZONE = {
  ClassName = "AI_PATROLZONE",
}



--- Creates a new AI\_PATROLZONE object
-- @param #AI_PATROLZONE self
-- @param Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Group} in km/h.
-- @param DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Group} in km/h.
-- @return #AI_PATROLZONE self
-- @usage
-- -- Define a new AI_PATROLZONE Object. This PatrolArea will patrol a group within PatrolZone between 3000 and 6000 meters, with a variying speed between 600 and 900 km/h.
-- PatrolZone = ZONE:New( 'PatrolZone' )
-- PatrolSpawn = SPAWN:New( 'Patrol Group' )
-- PatrolArea = AI_PATROLZONE:New( PatrolZone, 3000, 6000, 600, 900 )
function AI_PATROLZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed )

  local FSMT = {
    initial = 'None',
    events = {
      { name = 'Start',   from = '*',                       to = 'Route' },
      { name = 'Route',   from = '*',                       to = 'Route' },
      { name = 'Patrol',  from = { 'Patrol', 'Route' },     to = 'Patrol' },
      { name = 'RTB',     from = 'Patrol',                  to = 'RTB' },
      { name = 'End',     from = '*',                       to = 'End' },
      { name = 'Dead',    from = '*',                       to = 'End' }, 
    },
    callbacks = {
      onenterRoute = self._EnterRoute,
      onenterPatrol = self._EnterPatrol,
      onenterRTB = self._EnterRTB,
      onenterEnd = self._EnterEnd,
    },
  }
  
  -- Inherits from BASE
  local self = BASE:Inherit( self, STATEMACHINE:New( FSMT ) )
  
  self.PatrolZone = PatrolZone
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed

  return self
end



--- Set the @{Group} to act as the Patroller.
-- @param #AI_PATROLZONE self
-- @param Group#GROUP PatrolGroup The @{Group} patrolling.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetGroup( PatrolGroup )

  self.PatrolGroup = PatrolGroup
  self.PatrolGroupTemplateName = PatrolGroup:GetName()

  return self  
end



--- Sets (modifies) the minimum and maximum speed of the patrol.
-- @param #AI_PATROLZONE self
-- @param DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Group} in km/h.
-- @param DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Group} in km/h.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetSpeed( PatrolMinSpeed, PatrolMaxSpeed )
  self:F2( { PatrolMinSpeed, PatrolMaxSpeed } )
  
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
end



--- Sets the floor and ceiling altitude of the patrol.
-- @param #AI_PATROLZONE self
-- @param DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetAltitude( PatrolFloorAltitude, PatrolCeilingAltitude )
  self:F2( { PatrolFloorAltitude, PatrolCeilingAltitude } )
  
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
end



--- @param Group#GROUP PatrolGroup
function _NewPatrolRoute( PatrolGroup )

  PatrolGroup:T( "NewPatrolRoute" )
  local PatrolZone = PatrolGroup:GetState( PatrolGroup, "PatrolZone" ) -- PatrolZone#AI_PATROLZONE
  PatrolZone:__Route( 1, PatrolGroup )
end




--- When the PatrolGroup is out of fuel, it is required that a new PatrolGroup is started, before the old PatrolGroup can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the PatrolGroup will continue for a given time its patrol task in orbit, while a new PatrolGroup is targetted to the AI\_PATROLZONE.
-- Once the time is finished, the old PatrolGroup will return to the base.
-- @param #AI_PATROLZONE self
-- @param #number PatrolFuelTresholdPercentage The treshold in percentage (between 0 and 1) when the PatrolGroup is considered to get out of fuel.
-- @param #number PatrolOutOfFuelOrbitTime The amount of seconds the out of fuel PatrolGroup will orbit before returning to the base.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:ManageFuel( PatrolFuelTresholdPercentage, PatrolOutOfFuelOrbitTime )

  self.PatrolManageFuel = true
  self.PatrolFuelTresholdPercentage = PatrolFuelTresholdPercentage
  self.PatrolOutOfFuelOrbitTime = PatrolOutOfFuelOrbitTime
  
  return self
end

--- Defines a new patrol route using the @{PatrolZone} parameters and settings.
-- @param #AI_PATROLZONE self
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:_EnterRoute( AIGroup )

  self:F2()

  local PatrolRoute = {}
  
  if self.PatrolGroup:IsAlive() then
    --- Determine if the PatrolGroup is within the PatrolZone. 
    -- If not, make a waypoint within the to that the PatrolGroup will fly at maximum speed to that point.
    
--    --- Calculate the current route point.
--    local CurrentVec2 = self.PatrolGroup:GetVec2()
--    local CurrentAltitude = self.PatrolGroup:GetUnit(1):GetAltitude()
--    local CurrentPointVec3 = POINT_VEC3:New( CurrentVec2.x, CurrentAltitude, CurrentVec2.y )
--    local CurrentRoutePoint = CurrentPointVec3:RoutePointAir( 
--        POINT_VEC3.RoutePointAltType.BARO, 
--        POINT_VEC3.RoutePointType.TurningPoint, 
--        POINT_VEC3.RoutePointAction.TurningPoint, 
--        ToPatrolZoneSpeed, 
--        true 
--      )
--    
--    PatrolRoute[#PatrolRoute+1] = CurrentRoutePoint
    
    self:T2( PatrolRoute )
  
    if self.PatrolGroup:IsNotInZone( self.PatrolZone ) then
      --- Find a random 2D point in PatrolZone.
      local ToPatrolZoneVec2 = self.PatrolZone:GetRandomVec2()
      self:T2( ToPatrolZoneVec2 )
      
      --- Define Speed and Altitude.
      local ToPatrolZoneAltitude = math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude )
      local ToPatrolZoneSpeed = self.PatrolMaxSpeed
      self:T2( ToPatrolZoneSpeed )
      
      --- Obtain a 3D @{Point} from the 2D point + altitude.
      local ToPatrolZonePointVec3 = POINT_VEC3:New( ToPatrolZoneVec2.x, ToPatrolZoneAltitude, ToPatrolZoneVec2.y )
      
      --- Create a route point of type air.
      local ToPatrolZoneRoutePoint = ToPatrolZonePointVec3:RoutePointAir( 
        POINT_VEC3.RoutePointAltType.BARO, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        ToPatrolZoneSpeed, 
        true 
      )

    PatrolRoute[#PatrolRoute+1] = ToPatrolZoneRoutePoint

    end
    
    --- Define a random point in the @{Zone}. The AI will fly to that point within the zone.
    
      --- Find a random 2D point in PatrolZone.
    local ToTargetVec2 = self.PatrolZone:GetRandomVec2()
    self:T2( ToTargetVec2 )

    --- Define Speed and Altitude.
    local ToTargetAltitude = math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude )
    local ToTargetSpeed = math.random( self.PatrolMinSpeed, self.PatrolMaxSpeed )
    self:T2( { self.PatrolMinSpeed, self.PatrolMaxSpeed, ToTargetSpeed } )
    
    --- Obtain a 3D @{Point} from the 2D point + altitude.
    local ToTargetPointVec3 = POINT_VEC3:New( ToTargetVec2.x, ToTargetAltitude, ToTargetVec2.y )
    
    --- Create a route point of type air.
    local ToTargetRoutePoint = ToTargetPointVec3:RoutePointAir( 
      POINT_VEC3.RoutePointAltType.BARO, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      ToTargetSpeed, 
      true 
    )
    
    --ToTargetPointVec3:SmokeRed()

    PatrolRoute[#PatrolRoute+1] = ToTargetRoutePoint
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the PatrolGroup...
    self.PatrolGroup:WayPointInitialize( PatrolRoute )
    
    --- Do a trick, link the NewPatrolRoute function of the PATROLGROUP object to the PatrolGroup in a temporary variable ...
    self.PatrolGroup:SetState( self.PatrolGroup, "PatrolZone", self )
    self.PatrolGroup:WayPointFunction( #PatrolRoute, 1, "_NewPatrolRoute" )

    --- NOW ROUTE THE GROUP!
    self.PatrolGroup:WayPointExecute( 1 )
    
    self:__Patrol( 30, self.PatrolGroup )
  end
  
end


--- @param #AI_PATROLZONE self
function AI_PATROLZONE:_EnterPatrol( AIGroup )
  self:F2()

  if self.PatrolGroup and self.PatrolGroup:IsAlive() then
  
    local Fuel = self.PatrolGroup:GetUnit(1):GetFuel()
    if Fuel < self.PatrolFuelTresholdPercentage then
      local OldPatrolGroup = self.PatrolGroup
      local PatrolGroupTemplate = self.PatrolGroup:GetTemplate()
      
      local OrbitTask = OldPatrolGroup:TaskOrbitCircle( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ), self.PatrolMinSpeed )
      local TimedOrbitTask = OldPatrolGroup:TaskControlled( OrbitTask, OldPatrolGroup:TaskCondition(nil,nil,nil,nil,self.PatrolOutOfFuelOrbitTime,nil ) )
      OldPatrolGroup:SetTask( TimedOrbitTask, 10 )

      self:RTB( self.PatrolGroup )
    else
      self:__Patrol( 30, self.PatrolGroup ) -- Execute the Patrol event after 30 seconds.
    end
  end
  
end
