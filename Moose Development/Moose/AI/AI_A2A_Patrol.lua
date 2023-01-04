--- **AI** - Models the process of air patrol of airplanes.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===
-- 
-- @module AI.AI_A2A_Patrol
-- @image AI_Air_Patrolling.JPG


--- @type AI_A2A_PATROL
-- @extends AI.AI_A2A#AI_A2A

--- Implements the core functions to patrol a @{Core.Zone} by an AI @{Wrapper.Group} or @{Wrapper.Group}.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia3.JPG)
-- 
-- The AI_A2A_PATROL is assigned a @{Wrapper.Group} and this must be done before the AI_A2A_PATROL process can be started using the **Start** event.
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
-- Until a fuel or damage threshold has been reached by the AI, or when the AI is commanded to RTB.
-- When the fuel threshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
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
--   * **Status** ( Group ): The AI is checking status (fuel and damage). When the thresholds have been reached, the AI will RTB.
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
-- The detection frequency can be set with @{#AI_A2A_PATROL.SetRefreshTimeInterval}( seconds ), where the amount of seconds specify how much seconds will be waited before the next detection.
-- Use the method @{#AI_A2A_PATROL.GetDetectedUnits}() to obtain a list of the @{Wrapper.Unit}s detected by the AI.
-- 
-- The detection can be filtered to potential targets in a specific zone.
-- Use the method @{#AI_A2A_PATROL.SetDetectionZone}() to set the zone where targets need to be detected.
-- Note that when the zone is too far away, or the AI is not heading towards the zone, or the AI is too high, no targets may be detected
-- according the weather conditions.
-- 
-- ## 6. Manage the "out of fuel" in the AI_A2A_PATROL
-- 
-- When the AI is out of fuel, it is required that a new AI is started, before the old AI can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel threshold is calculated.
-- When the fuel threshold is reached, the AI will continue for a given time its patrol task in orbit, 
-- while a new AI is targeted to the AI_A2A_PATROL.
-- Once the time is finished, the old AI will return to the base.
-- Use the method @{#AI_A2A_PATROL.ManageFuel}() to have this proces in place.
-- 
-- ## 7. Manage "damage" behaviour of the AI in the AI_A2A_PATROL
-- 
-- When the AI is damaged, it is required that a new Patrol is started. However, damage cannon be foreseen early on. 
-- Therefore, when the damage threshold is reached, the AI will return immediately to the home base (RTB).
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
-- @param Wrapper.Group#GROUP AIPatrol The patrol group object.
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Core.Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to BARO
-- @return #AI_A2A_PATROL self
-- @usage
-- -- Define a new AI_A2A_PATROL Object. This PatrolArea will patrol a Group within PatrolZone between 3000 and 6000 meters, with a variying speed between 600 and 900 km/h.
-- PatrolZone = ZONE:New( 'PatrolZone' )
-- PatrolSpawn = SPAWN:New( 'Patrol Group' )
-- PatrolArea = AI_A2A_PATROL:New( PatrolZone, 3000, 6000, 600, 900 )
function AI_A2A_PATROL:New( AIPatrol, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  local AI_Air = AI_AIR:New( AIPatrol )
  local AI_Air_Patrol = AI_AIR_PATROL:New( AI_Air, AIPatrol, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType  )
  local self = BASE:Inherit( self, AI_Air_Patrol ) -- #AI_A2A_PATROL
  
  self:SetFuelThreshold( .2, 60 )
  self:SetDamageThreshold( 0.4 )
  self:SetDisengageRadius( 70000 )

  
  self.PatrolZone = PatrolZone
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
  
  -- defafult PatrolAltType to "BARO" if not specified
  self.PatrolAltType = PatrolAltType or "BARO"
  
  self:AddTransition( { "Started", "Airborne", "Refuelling" }, "Patrol", "Patrolling" )

--- OnBefore Transition Handler for Event Patrol.
-- @function [parent=#AI_A2A_PATROL] OnBeforePatrol
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Patrol.
-- @function [parent=#AI_A2A_PATROL] OnAfterPatrol
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
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
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Patrolling.
-- @function [parent=#AI_A2A_PATROL] OnEnterPatrolling
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Patrolling", "Route", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_PATROL.

--- OnBefore Transition Handler for Event Route.
-- @function [parent=#AI_A2A_PATROL] OnBeforeRoute
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Route.
-- @function [parent=#AI_A2A_PATROL] OnAfterRoute
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
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
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @return #AI_A2A_PATROL self
function AI_A2A_PATROL:SetSpeed( PatrolMinSpeed, PatrolMaxSpeed )
  self:F2( { PatrolMinSpeed, PatrolMaxSpeed } )
  
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
end



--- Sets the floor and ceiling altitude of the patrol.
-- @param #AI_A2A_PATROL self
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @return #AI_A2A_PATROL self
function AI_A2A_PATROL:SetAltitude( PatrolFloorAltitude, PatrolCeilingAltitude )
  self:F2( { PatrolFloorAltitude, PatrolCeilingAltitude } )
  
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
end


--- Defines a new patrol route using the @{AI.AI_Patrol#AI_PATROL_ZONE} parameters and settings.
-- @param #AI_A2A_PATROL self
-- @return #AI_A2A_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_PATROL:onafterPatrol( AIPatrol, From, Event, To )
  self:F2()

  self:ClearTargetDistance()

  self:__Route( 1 )
  
  AIPatrol:OnReSpawn(
    function( PatrolGroup )
      self:__Reset( 1 )
      self:__Route( 5 )
    end
  )
end


--- This static method is called from the route path within the last task at the last waypoint of the AIPatrol.
-- Note that this method is required, as triggers the next route when patrolling for the AIPatrol.
-- @param Wrapper.Group#GROUP AIPatrol The AI group.
-- @param #AI_A2A_PATROL Fsm The FSM.
function AI_A2A_PATROL.PatrolRoute( AIPatrol, Fsm )

  AIPatrol:F( { "AI_A2A_PATROL.PatrolRoute:", AIPatrol:GetName() } )

  if AIPatrol and AIPatrol:IsAlive() then
    Fsm:Route()
  end
  
end


--- Defines a new patrol route using the @{AI.AI_Patrol#AI_PATROL_ZONE} parameters and settings.
-- @param #AI_A2A_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_PATROL:onafterRoute( AIPatrol, From, Event, To )
  self:F2()

  -- When RTB, don't allow anymore the routing.
  if From == "RTB" then
    return
  end

  
  if AIPatrol and AIPatrol:IsAlive() then
    
    local PatrolRoute = {}

    --- Calculate the target route point.
    
    local CurrentCoord = AIPatrol:GetCoordinate()
    
    -- Random altitude.
    local altitude=math.random(self.PatrolFloorAltitude, self.PatrolCeilingAltitude)
      
    -- Random speed in km/h.
    local speedkmh = math.random(self.PatrolMinSpeed, self.PatrolMaxSpeed)
    
    -- First waypoint is current position.
    PatrolRoute[1]=CurrentCoord:WaypointAirTurningPoint(nil, speedkmh, {}, "Current")    
    
    if self.racetrack then
      
      -- Random heading.
      local heading = math.random(self.racetrackheadingmin, self.racetrackheadingmax)
      
      -- Random leg length.
      local leg=math.random(self.racetracklegmin, self.racetracklegmax)
      
      -- Random duration if any.
      local duration = self.racetrackdurationmin
      if self.racetrackdurationmax then
        duration=math.random(self.racetrackdurationmin, self.racetrackdurationmax)
      end
      
      -- CAP coordinate.
      local c0=self.PatrolZone:GetRandomCoordinate()
      if self.racetrackcapcoordinates and #self.racetrackcapcoordinates>0 then
        c0=self.racetrackcapcoordinates[math.random(#self.racetrackcapcoordinates)]
      end
      
      -- Race track points.
      local c1=c0:SetAltitude(altitude) --Core.Point#COORDINATE
      local c2=c1:Translate(leg, heading):SetAltitude(altitude)
      
      self:SetTargetDistance(c0) -- For RTB status check
      
      -- Debug:
      self:T(string.format("Patrol zone race track: v=%.1f knots, h=%.1f ft, heading=%03d, leg=%d m, t=%s sec", UTILS.KmphToKnots(speedkmh), UTILS.MetersToFeet(altitude), heading, leg, tostring(duration)))
      --c1:MarkToAll("Race track c1")
      --c2:MarkToAll("Race track c2")

      -- Task to orbit.              
      local taskOrbit=AIPatrol:TaskOrbit(c1, altitude, UTILS.KmphToMps(speedkmh), c2)
      
      -- Task function to redo the patrol at other random position.
      local taskPatrol=AIPatrol:TaskFunction("AI_A2A_PATROL.PatrolRoute", self)
      
      -- Controlled task with task condition.
      local taskCond=AIPatrol:TaskCondition(nil, nil, nil, nil, duration, nil)
      local taskCont=AIPatrol:TaskControlled(taskOrbit, taskCond)
      
      -- Second waypoint
      PatrolRoute[2]=c1:WaypointAirTurningPoint(self.PatrolAltType, speedkmh, {taskCont, taskPatrol}, "CAP Orbit")

    else

      -- Target coordinate.        
      local ToTargetCoord=self.PatrolZone:GetRandomCoordinate() --Core.Point#COORDINATE
      ToTargetCoord:SetAltitude(altitude)
      
      self:SetTargetDistance( ToTargetCoord ) -- For RTB status check
      
      local taskReRoute=AIPatrol:TaskFunction( "AI_A2A_PATROL.PatrolRoute", self )
      
      PatrolRoute[2]=ToTargetCoord:WaypointAirTurningPoint(self.PatrolAltType, speedkmh, {taskReRoute}, "Patrol Point")
            
    end

    -- ROE    
    AIPatrol:OptionROEReturnFire()
    AIPatrol:OptionROTEvadeFire()
  
    -- Patrol.
    AIPatrol:Route( PatrolRoute, 0.5)
  end

end

