--- (AI) (FSM) Make AI patrol routes or zones.
-- 
-- ===
-- 
-- 1) @{#AI_PATROLZONE} class, extends @{Core.Fsm#FSM_CONTROLLABLE}
-- ================================================================
-- The @{#AI_PATROLZONE} class implements the core functions to patrol a @{Zone} by an AIR @{Controllable} @{Group}.
-- The patrol algorithm works that for each airplane patrolling, upon arrival at the patrol zone,
-- a random point is selected as the route point within the 3D space, within the given boundary limits.
-- The airplane will fly towards the random 3D point within the patrol zone, using a random speed within the given altitude and speed limits.
-- Upon arrival at the random 3D point, a new 3D random point will be selected within the patrol zone using the given limits.
-- This cycle will continue until a fuel treshold has been reached by the airplane.
-- When the fuel treshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- 1.1) AI_PATROLZONE constructor:
-- ----------------------------
--   
--   * @{#AI_PATROLZONE.New}(): Creates a new AI_PATROLZONE object.
-- 
-- 1.2) AI_PATROLZONE state machine:
-- ----------------------------------
-- The AI_PATROLZONE is a state machine: it manages the different events and states of the AIControllable it is controlling.
-- 
-- ### 1.2.1) AI_PATROLZONE Events:
-- 
--   * @{#AI_PATROLZONE.Route}( AIControllable ):  A new 3D route point is selected and the AIControllable will fly towards that point with the given speed.
--   * @{#AI_PATROLZONE.Patrol}( AIControllable ): The AIControllable reports it is patrolling. This event is called every 30 seconds.
--   * @{#AI_PATROLZONE.RTB}( AIControllable ): The AIControllable will report return to base.
--   * @{#AI_PATROLZONE.End}( AIControllable ): The end of the AI_PATROLZONE process.
--   * @{#AI_PATROLZONE.Dead}( AIControllable ): The AIControllable is dead. The AI_PATROLZONE process will be ended.
-- 
-- ### 1.2.2) AI_PATROLZONE States:
-- 
--   * **Route**: A new 3D route point is selected and the AIControllable will fly towards that point with the given speed.
--   * **Patrol**: The AIControllable is patrolling. This state is set every 30 seconds, so every 30 seconds, a state transition method can be used.
--   * **RTB**: The AIControllable reports it wants to return to the base.
--   * **Dead**: The AIControllable is dead ...
--   * **End**: The process has come to an end.
--   
-- ### 1.2.3) AI_PATROLZONE state transition methods:
-- 
-- State transition functions can be set **by the mission designer** customizing or improving the behaviour of the state.
-- There are 2 moments when state transition methods will be called by the state machine:
-- 
--   * **Before** the state transition. 
--     The state transition method needs to start with the name **OnBefore + the name of the state**. 
--     If the state transition method returns false, then the processing of the state transition will not be done!
--     If you want to change the behaviour of the AIControllable at this event, return false, 
--     but then you'll need to specify your own logic using the AIControllable!
--   
--   * **After** the state transition. 
--     The state transition method needs to start with the name **OnAfter + the name of the state**. 
--     These state transition methods need to provide a return value, which is specified at the function description.
--
-- An example how to manage a state transition for an AI_PATROLZONE object **Patrol** for the state **RTB**:
-- 
--      local PatrolZoneGroup = GROUP:FindByName( "Patrol Zone" )
--      local PatrolZone = ZONE_POLYGON:New( "PatrolZone", PatrolZoneGroup )
--
--      local PatrolSpawn = SPAWN:New( "Patrol Group" )
--      local PatrolGroup = PatrolSpawn:Spawn()
--
--      local Patrol = AI_PATROLZONE:New( PatrolZone, 3000, 6000, 300, 600 )
--      Patrol:SetControllable( PatrolGroup )
--      Patrol:ManageFuel( 0.2, 60 )
--
-- **OnBefore**RTB( AIGroup ) will be called by the AI_PATROLZONE object when the AIGroup reports RTB, but **before** the RTB default action is processed by the AI_PATROLZONE object.
--
--      --- State transition function for the AI_PATROLZONE **Patrol** object
--      -- @param #AI_PATROLZONE self 
--      -- @param Wrapper.Controllable#CONTROLLABLE AIGroup
--      -- @return #boolean If false is returned, then the OnAfter state transition method will not be called.
--      function Patrol:OnBeforeRTB( AIGroup )
--        AIGroup:MessageToRed( "Returning to base", 20 )
--      end
--       
-- **OnAfter**RTB( AIGroup ) will be called by the AI_PATROLZONE object when the AIGroup reports RTB, but **after** the RTB default action was processed by the AI_PATROLZONE object.
--
--      --- State transition function for the AI_PATROLZONE **Patrol** object
--      -- @param #AI_PATROLZONE self 
--      -- @param Wrapper.Controllable#CONTROLLABLE AIGroup
--      -- @return #Wrapper.Controllable#CONTROLLABLE The new AIGroup object that is set to be patrolling the zone.
--      function Patrol:OnAfterRTB( AIGroup )
--        return PatrolSpawn:Spawn()
--      end 
--    
-- 1.3) Manage the AI_PATROLZONE parameters:
-- ------------------------------------------
-- The following methods are available to modify the parameters of a AI_PATROLZONE object:
-- 
--   * @{#AI_PATROLZONE.SetControllable}(): Set the AIControllable.
--   * @{#AI_PATROLZONE.GetControllable}(): Get the AIControllable.
--   * @{#AI_PATROLZONE.SetSpeed}(): Set the patrol speed of the AI, for the next patrol.
--   * @{#AI_PATROLZONE.SetAltitude}(): Set altitude of the AI, for the next patrol.
-- 
-- 1.3) Manage the out of fuel in the AI_PATROLZONE:
-- ----------------------------------------------
-- When the AIControllable is out of fuel, it is required that a new AIControllable is started, before the old AIControllable can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the AIControllable will continue for a given time its patrol task in orbit, while a new AIControllable is targetted to the AI_PATROLZONE.
-- Once the time is finished, the old AIControllable will return to the base.
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
-- 2016-09-01: Initial class and API.
-- 
-- ===
-- 
-- AUTHORS and CONTRIBUTIONS
-- =========================
-- 
-- ### Contributions: 
-- 
--   * **DutchBaron**: Testing.
--   * **Pikey**: Testing and API concept review.
-- 
-- ### Authors: 
-- 
--   * **FlightControl**: Design & Programming.
-- 
-- 
-- @module AI_Patrol

--- AI_PATROLZONE class
-- @type AI_PATROLZONE
-- @field Wrapper.Controllable#CONTROLLABLE AIControllable The @{Controllable} patrolling.
-- @field Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @field Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @field Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @field Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @field Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @extends Core.Fsm#FSM_CONTROLLABLE
AI_PATROLZONE = {
  ClassName = "AI_PATROLZONE",
}



--- Creates a new AI_PATROLZONE object
-- @param #AI_PATROLZONE self
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @return #AI_PATROLZONE self
-- @usage
-- -- Define a new AI_PATROLZONE Object. This PatrolArea will patrol an AIControllable within PatrolZone between 3000 and 6000 meters, with a variying speed between 600 and 900 km/h.
-- PatrolZone = ZONE:New( 'PatrolZone' )
-- PatrolSpawn = SPAWN:New( 'Patrol Group' )
-- PatrolArea = AI_PATROLZONE:New( PatrolZone, 3000, 6000, 600, 900 )
function AI_PATROLZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed )

  -- Inherits from BASE
  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- Core.Fsm#FSM_CONTROLLABLE
  
  
    self.PatrolZone = PatrolZone
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
  
  self.PatrolFuelTresholdPercentage = 0.2

  
  self:SetStartState( "Route" )

do self:AddTransition( "Route", "Start", "Route" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROLZONE.

	--- OnLeave State Transition for Route.
  -- @function [parent=#AI_PATROLZONE] OnLeaveRoute
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnEnter State Transition for Route.
  -- @function [parent=#AI_PATROLZONE] OnEnterRoute
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- OnBefore State Transition for Start.
  -- @function [parent=#AI_PATROLZONE] OnBeforeStart
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnAfter State Transition for Start.
  -- @function [parent=#AI_PATROLZONE] OnAfterStart
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- Embedded Event Trigger for Start.
  -- @function [parent=#AI_PATROLZONE] Start
  -- @param #AI_PATROLZONE self

	--- Delayed Event Trigger for Start
  -- @function [parent=#AI_PATROLZONE] __Start
  -- @param #AI_PATROLZONE self
  -- @param #number Delay The delay in seconds.

end -- AI_PATROLZONE  

do self:AddTransition( "Route", "Route", "Route" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROLZONE.

	--- OnLeave State Transition for Route.
  -- @function [parent=#AI_PATROLZONE] OnLeaveRoute
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnEnter State Transition for Route.
  -- @function [parent=#AI_PATROLZONE] OnEnterRoute
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- OnBefore State Transition for Route.
  -- @function [parent=#AI_PATROLZONE] OnBeforeRoute
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnAfter State Transition for Route.
  -- @function [parent=#AI_PATROLZONE] OnAfterRoute
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- Embedded Event Trigger for Route.
  -- @function [parent=#AI_PATROLZONE] Route
  -- @param #AI_PATROLZONE self

	--- Delayed Event Trigger for Route
  -- @function [parent=#AI_PATROLZONE] __Route
  -- @param #AI_PATROLZONE self
  -- @param #number Delay The delay in seconds.

end -- AI_PATROLZONE  

do self:AddTransition( { "Patrol", "Route" }, "Patrol", "Patrol" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROLZONE.

	--- OnLeave State Transition for Patrol.
  -- @function [parent=#AI_PATROLZONE] OnLeavePatrol
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnEnter State Transition for Patrol.
  -- @function [parent=#AI_PATROLZONE] OnEnterPatrol
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- OnBefore State Transition for Patrol.
  -- @function [parent=#AI_PATROLZONE] OnBeforePatrol
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnAfter State Transition for Patrol.
  -- @function [parent=#AI_PATROLZONE] OnAfterPatrol
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- Embedded Event Trigger for Patrol.
  -- @function [parent=#AI_PATROLZONE] Patrol
  -- @param #AI_PATROLZONE self

	--- Delayed Event Trigger for Patrol
  -- @function [parent=#AI_PATROLZONE] __Patrol
  -- @param #AI_PATROLZONE self
  -- @param #number Delay The delay in seconds.

end -- AI_PATROLZONE

do self:AddTransition( "Patrol", "RTB", "RTB" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROLZONE.

	--- OnLeave State Transition for Patrol.
  -- @function [parent=#AI_PATROLZONE] OnLeavePatrol
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnEnter State Transition for RTB.
  -- @function [parent=#AI_PATROLZONE] OnEnterRTB
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- OnBefore State Transition for RTB.
  -- @function [parent=#AI_PATROLZONE] OnBeforeRTB
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnAfter State Transition for RTB.
  -- @function [parent=#AI_PATROLZONE] OnAfterRTB
  -- @param #AI_PATROLZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- Embedded Event Trigger for RTB.
  -- @function [parent=#AI_PATROLZONE] RTB
  -- @param #AI_PATROLZONE self

	--- Delayed Event Trigger for RTB
  -- @function [parent=#AI_PATROLZONE] __RTB
  -- @param #AI_PATROLZONE self
  -- @param #number Delay The delay in seconds.

end -- AI_PATROLZONE
  
  return self
end




--- Sets (modifies) the minimum and maximum speed of the patrol.
-- @param #AI_PATROLZONE self
-- @param Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetSpeed( PatrolMinSpeed, PatrolMaxSpeed )
  self:F2( { PatrolMinSpeed, PatrolMaxSpeed } )
  
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
end



--- Sets the floor and ceiling altitude of the patrol.
-- @param #AI_PATROLZONE self
-- @param Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetAltitude( PatrolFloorAltitude, PatrolCeilingAltitude )
  self:F2( { PatrolFloorAltitude, PatrolCeilingAltitude } )
  
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
end



--- @param Wrapper.Controllable#CONTROLLABLE AIControllable
function _NewPatrolRoute( AIControllable )

  AIControllable:T( "NewPatrolRoute" )
  local PatrolZone = AIControllable:GetState( AIControllable, "PatrolZone" ) -- PatrolCore.Zone#AI_PATROLZONE
  PatrolZone:__Route( 1 )
end




--- When the AIControllable is out of fuel, it is required that a new AIControllable is started, before the old AIControllable can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the AIControllable will continue for a given time its patrol task in orbit, while a new AIControllable is targetted to the AI_PATROLZONE.
-- Once the time is finished, the old AIControllable will return to the base.
-- @param #AI_PATROLZONE self
-- @param #number PatrolFuelTresholdPercentage The treshold in percentage (between 0 and 1) when the AIControllable is considered to get out of fuel.
-- @param #number PatrolOutOfFuelOrbitTime The amount of seconds the out of fuel AIControllable will orbit before returning to the base.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:ManageFuel( PatrolFuelTresholdPercentage, PatrolOutOfFuelOrbitTime )

  self.PatrolManageFuel = true
  self.PatrolFuelTresholdPercentage = PatrolFuelTresholdPercentage
  self.PatrolOutOfFuelOrbitTime = PatrolOutOfFuelOrbitTime
  
  return self
end

--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_PATROLZONE self
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:onenterRoute()

  self:F2()

  local PatrolRoute = {}
  
  if self.Controllable:IsAlive() then
    --- Determine if the AIControllable is within the PatrolZone. 
    -- If not, make a waypoint within the to that the AIControllable will fly at maximum speed to that point.
    
--    --- Calculate the current route point.
--    local CurrentVec2 = self.Controllable:GetVec2()
--    local CurrentAltitude = self.Controllable:GetUnit(1):GetAltitude()
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
  
    if self.Controllable:IsNotInZone( self.PatrolZone ) then
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
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    self.Controllable:WayPointInitialize( PatrolRoute )
    
    --- Do a trick, link the NewPatrolRoute function of the PATROLGROUP object to the AIControllable in a temporary variable ...
    self.Controllable:SetState( self.Controllable, "PatrolZone", self )
    self.Controllable:WayPointFunction( #PatrolRoute, 1, "_NewPatrolRoute" )

    --- NOW ROUTE THE GROUP!
    self.Controllable:WayPointExecute( 1, 5 )
    
    self:__Patrol( 30 )
  end
  
end


--- @param #AI_PATROLZONE self
function AI_PATROLZONE:onenterPatrol()
  self:F2()

  if self.Controllable and self.Controllable:IsAlive() then
  
    local Fuel = self.Controllable:GetUnit(1):GetFuel()
    if Fuel < self.PatrolFuelTresholdPercentage then
      local OldAIControllable = self.Controllable
      local AIControllableTemplate = self.Controllable:GetTemplate()
      
      local OrbitTask = OldAIControllable:TaskOrbitCircle( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ), self.PatrolMinSpeed )
      local TimedOrbitTask = OldAIControllable:TaskControlled( OrbitTask, OldAIControllable:TaskCondition(nil,nil,nil,nil,self.PatrolOutOfFuelOrbitTime,nil ) )
      OldAIControllable:SetTask( TimedOrbitTask, 10 )

      self:RTB()
    else
      self:__Patrol( 30 ) -- Execute the Patrol event after 30 seconds.
    end
  end
  
end
