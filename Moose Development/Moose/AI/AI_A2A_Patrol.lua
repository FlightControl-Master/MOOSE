--- **AI** -- **Air Patrolling or Staging.**
-- 
-- ![Banner Image](..\Presentations\AI_PATROL\Dia1.JPG)
-- 
-- ===
-- 
-- AI PATROL classes makes AI Controllables execute an Patrol.
-- 
-- There are the following types of PATROL classes defined:
-- 
--   * @{#AI_A2A_PATROL}: Perform a PATROL in a zone.
--   
-- ====
-- 
-- # Demo Missions
-- 
-- ### [AI_PATROL Demo Missions source code](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release/PAT%20-%20Patrolling)
-- 
-- ### [AI_PATROL Demo Missions, only for beta testers](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/PAT%20-%20Patrolling)
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [AI_PATROL YouTube Channel](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl35HvYZKA6G22WMt7iI3zky)
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- ### Contributions: 
-- 
--   * **[Dutch_Baron](https://forums.eagle.ru/member.php?u=112075)**: Working together with James has resulted in the creation of the AI_BALANCER class. James has shared his ideas on balancing AI with air units, and together we made a first design which you can use now :-)
--   * **[Pikey](https://forums.eagle.ru/member.php?u=62835)**: Testing and API concept review.
-- 
-- ====
-- 
-- @module AI_A2A_Patrol


--- @type AI_A2A_PATROL
-- @extends AI.AI_A2A#AI_A2A

--- # AI_A2A_PATROL class, extends @{Fsm#FSM_CONTROLLABLE}
-- 
-- The AI_A2A_PATROL class implements the core functions to patrol a @{Zone} by an AI @{Controllable} or @{Group}.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia3.JPG)
-- 
-- The AI_A2A_PATROL is assigned a @{Group} and this must be done before the AI_A2A_PATROL process can be started using the **Start** event.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia4.JPG)
-- 
-- The AI will fly towards the random 3D point within the patrol zone, using a random speed within the given altitude and speed limits.
-- Upon arrival at the 3D point, a new random 3D point will be selected within the patrol zone using the given limits.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia5.JPG)
-- 
-- This cycle will continue.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia6.JPG)
-- 
-- During the patrol, the AI will detect enemy targets, which are reported through the **Detected** event.
--
-- ![Process](..\Presentations\AI_PATROL\Dia9.JPG)
-- 
---- Note that the enemy is not engaged! To model enemy engagement, either tailor the **Detected** event, or
-- use derived AI_ classes to model AI offensive or defensive behaviour.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia10.JPG)
-- 
-- Until a fuel or damage treshold has been reached by the AI, or when the AI is commanded to RTB.
-- When the fuel treshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia11.JPG)
-- 
-- ## 1. AI_A2A_PATROL constructor
--   
--   * @{#AI_A2A_PATROL.New}(): Creates a new AI_A2A_PATROL object.
-- 
-- ## 2. AI_A2A_PATROL is a FSM
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia2.JPG)
-- 
-- ### 2.1. AI_A2A_PATROL States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Returning** ( Group ): The AI is returning to Base.
--   * **Stopped** ( Group ): The process is stopped.
--   * **Crashed** ( Group ): The AI has crashed or is dead.
-- 
-- ### 2.2. AI_A2A_PATROL Events
-- 
--   * **Start** ( Group ): Start the process.
--   * **Stop** ( Group ): Stop the process.
--   * **Route** ( Group ): Route the AI to a new random 3D point within the Patrol Zone.
--   * **RTB** ( Group ): Route the AI to the home base.
--   * **Detect** ( Group ): The AI is detecting targets.
--   * **Detected** ( Group ): The AI has detected new targets.
--   * **Status** ( Group ): The AI is checking status (fuel and damage). When the tresholds have been reached, the AI will RTB.
--    
-- ## 3. Set or Get the AI controllable
-- 
--   * @{#AI_A2A_PATROL.SetControllable}(): Set the AIControllable.
--   * @{#AI_A2A_PATROL.GetControllable}(): Get the AIControllable.
--
-- ## 4. Set the Speed and Altitude boundaries of the AI controllable
--
--   * @{#AI_A2A_PATROL.SetSpeed}(): Set the patrol speed boundaries of the AI, for the next patrol.
--   * @{#AI_A2A_PATROL.SetAltitude}(): Set altitude boundaries of the AI, for the next patrol.
-- 
-- ## 5. Manage the detection process of the AI controllable
-- 
-- The detection process of the AI controllable can be manipulated.
-- Detection requires an amount of CPU power, which has an impact on your mission performance.
-- Only put detection on when absolutely necessary, and the frequency of the detection can also be set.
-- 
--   * @{#AI_A2A_PATROL.SetDetectionOn}(): Set the detection on. The AI will detect for targets.
--   * @{#AI_A2A_PATROL.SetDetectionOff}(): Set the detection off, the AI will not detect for targets. The existing target list will NOT be erased.
-- 
-- The detection frequency can be set with @{#AI_A2A_PATROL.SetDetectionInterval}( seconds ), where the amount of seconds specify how much seconds will be waited before the next detection.
-- Use the method @{#AI_A2A_PATROL.GetDetectedUnits}() to obtain a list of the @{Unit}s detected by the AI.
-- 
-- The detection can be filtered to potential targets in a specific zone.
-- Use the method @{#AI_A2A_PATROL.SetDetectionZone}() to set the zone where targets need to be detected.
-- Note that when the zone is too far away, or the AI is not heading towards the zone, or the AI is too high, no targets may be detected
-- according the weather conditions.
-- 
-- ## 6. Manage the "out of fuel" in the AI_A2A_PATROL
-- 
-- When the AI is out of fuel, it is required that a new AI is started, before the old AI can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the AI will continue for a given time its patrol task in orbit, 
-- while a new AI is targetted to the AI_A2A_PATROL.
-- Once the time is finished, the old AI will return to the base.
-- Use the method @{#AI_A2A_PATROL.ManageFuel}() to have this proces in place.
-- 
-- ## 7. Manage "damage" behaviour of the AI in the AI_A2A_PATROL
-- 
-- When the AI is damaged, it is required that a new AIControllable is started. However, damage cannon be foreseen early on. 
-- Therefore, when the damage treshold is reached, the AI will return immediately to the home base (RTB).
-- Use the method @{#AI_A2A_PATROL.ManageDamage}() to have this proces in place.
-- 
-- ===
-- 
-- @field #AI_A2A_PATROL
AI_A2A_PATROL = {
  ClassName = "AI_A2A_PATROL",
}

--- Creates a new AI_A2A_PATROL object
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Group#GROUP AIGroup
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_A2A_PATROL self
-- @usage
-- -- Define a new AI_A2A_PATROL Object. This PatrolArea will patrol an AIControllable within PatrolZone between 3000 and 6000 meters, with a variying speed between 600 and 900 km/h.
-- PatrolZone = ZONE:New( 'PatrolZone' )
-- PatrolSpawn = SPAWN:New( 'Patrol Group' )
-- PatrolArea = AI_A2A_PATROL:New( PatrolZone, 3000, 6000, 600, 900 )
function AI_A2A_PATROL:New( AIGroup, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2A:New( AIGroup ) ) -- #AI_A2A_PATROL
  
  self.PatrolZone = PatrolZone
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
  
  -- defafult PatrolAltType to "RADIO" if not specified
  self.PatrolAltType = PatrolAltType or "RADIO"
  
  self:AddTransition( "Started", "Patrol", "Patrolling" )

--- OnBefore Transition Handler for Event Patrol.
-- @function [parent=#AI_A2A_PATROL] OnBeforePatrol
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Patrol.
-- @function [parent=#AI_A2A_PATROL] OnAfterPatrol
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Patrol.
-- @function [parent=#AI_A2A_PATROL] Patrol
-- @param #AI_A2A_PATROL self

--- Asynchronous Event Trigger for Event Patrol.
-- @function [parent=#AI_A2A_PATROL] __Patrol
-- @param #AI_A2A_PATROL self
-- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Patrolling.
-- @function [parent=#AI_A2A_PATROL] OnLeavePatrolling
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Patrolling.
-- @function [parent=#AI_A2A_PATROL] OnEnterPatrolling
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Patrolling", "Route", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_PATROL.

--- OnBefore Transition Handler for Event Route.
-- @function [parent=#AI_A2A_PATROL] OnBeforeRoute
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Route.
-- @function [parent=#AI_A2A_PATROL] OnAfterRoute
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Route.
-- @function [parent=#AI_A2A_PATROL] Route
-- @param #AI_A2A_PATROL self

--- Asynchronous Event Trigger for Event Route.
-- @function [parent=#AI_A2A_PATROL] __Route
-- @param #AI_A2A_PATROL self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Reset", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_PATROL.
  
  return self
end




--- Sets (modifies) the minimum and maximum speed of the patrol.
-- @param #AI_A2A_PATROL self
-- @param Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @return #AI_A2A_PATROL self
function AI_A2A_PATROL:SetSpeed( PatrolMinSpeed, PatrolMaxSpeed )
  self:F2( { PatrolMinSpeed, PatrolMaxSpeed } )
  
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
end



--- Sets the floor and ceiling altitude of the patrol.
-- @param #AI_A2A_PATROL self
-- @param Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @return #AI_A2A_PATROL self
function AI_A2A_PATROL:SetAltitude( PatrolFloorAltitude, PatrolCeilingAltitude )
  self:F2( { PatrolFloorAltitude, PatrolCeilingAltitude } )
  
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
end


--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_A2A_PATROL self
-- @return #AI_A2A_PATROL self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_PATROL:onafterPatrol( Controllable, From, Event, To )
  self:F2()

  self:ClearTargetDistance()

  self:__Route( 1 )
  
  self.Controllable:OnReSpawn(
    function( PatrolGroup )
      self:E( "ReSpawn" )
      self:__Reset( 1 )
      self:__Route( 5 )
    end
  )
end



--- @param Wrapper.Group#GROUP AIGroup
-- This statis method is called from the route path within the last task at the last waaypoint of the Controllable.
-- Note that this method is required, as triggers the next route when patrolling for the Controllable.
function AI_A2A_PATROL.PatrolRoute( AIGroup )

  local _AI_A2A_Patrol = AIGroup:GetState( AIGroup, "AI_A2A_PATROL" ) -- #AI_A2A_PATROL
  _AI_A2A_Patrol:Route()
end


--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_PATROL:onafterRoute( AIGroup, From, Event, To )

  self:F2()

  -- When RTB, don't allow anymore the routing.
  if From == "RTB" then
    return
  end

  
  if AIGroup:IsAlive() then
    
    local PatrolRoute = {}

    --- Calculate the target route point.
    
    local CurrentCoord = AIGroup:GetCoordinate()
    
    local ToTargetCoord = self.PatrolZone:GetRandomPointVec2()
    ToTargetCoord:SetAlt(math.random( self.PatrolFloorAltitude,self.PatrolCeilingAltitude ) )
    self:SetTargetDistance( ToTargetCoord ) -- For RTB status check
    
    local ToTargetSpeed = math.random( self.PatrolMinSpeed, self.PatrolMaxSpeed )
    
    --- Create a route point of type air.
    local ToPatrolRoutePoint = ToTargetCoord:RoutePointAir( 
      self.PatrolAltType, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      ToTargetSpeed, 
      true 
    )

    PatrolRoute[#PatrolRoute+1] = ToPatrolRoutePoint
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    AIGroup:WayPointInitialize( PatrolRoute )

    local Tasks = {}
    Tasks[#Tasks+1] = AIGroup:TaskFunction( 1, 1, "AI_A2A_PATROL.PatrolRoute" )
    
    PatrolRoute[1].task = AIGroup:TaskCombo( Tasks )
    
    --- Do a trick, link the NewPatrolRoute function of the PATROLGROUP object to the AIControllable in a temporary variable ...
    AIGroup:SetState( AIGroup, "AI_A2A_PATROL", self )

    --- NOW ROUTE THE GROUP!
    AIGroup:WayPointExecute( 1, 2 )
  end

end

