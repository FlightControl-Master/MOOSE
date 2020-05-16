--- **AI** -- Models the process of A2G patrolling and engaging ground targets for airplanes and helicopters.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Air_Patrol
-- @image AI_Air_To_Ground_Patrol.JPG

--- @type AI_AIR_PATROL
-- @extends AI.AI_Air#AI_AIR


--- The AI_AIR_PATROL class implements the core functions to patrol a @{Zone} by an AI @{Wrapper.Group} or @{Wrapper.Group} 
-- and automatically engage any airborne enemies that are within a certain range or within a certain zone.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia3.JPG)
-- 
-- The AI_AIR_PATROL is assigned a @{Wrapper.Group} and this must be done before the AI_AIR_PATROL process can be started using the **Start** event.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia4.JPG)
-- 
-- The AI will fly towards the random 3D point within the patrol zone, using a random speed within the given altitude and speed limits.
-- Upon arrival at the 3D point, a new random 3D point will be selected within the patrol zone using the given limits.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia5.JPG)
-- 
-- This cycle will continue.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia6.JPG)
-- 
-- During the patrol, the AI will detect enemy targets, which are reported through the **Detected** event.
--
-- ![Process](..\Presentations\AI_CAP\Dia9.JPG)
-- 
-- When enemies are detected, the AI will automatically engage the enemy.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia10.JPG)
-- 
-- Until a fuel or damage treshold has been reached by the AI, or when the AI is commanded to RTB.
-- When the fuel treshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia13.JPG)
-- 
-- ## 1. AI_AIR_PATROL constructor
--   
--   * @{#AI_AIR_PATROL.New}(): Creates a new AI_AIR_PATROL object.
-- 
-- ## 2. AI_AIR_PATROL is a FSM
-- 
-- ![Process](..\Presentations\AI_CAP\Dia2.JPG)
-- 
-- ### 2.1 AI_AIR_PATROL States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Engaging** ( Group ): The AI is engaging the bogeys.
--   * **Returning** ( Group ): The AI is returning to Base..
-- 
-- ### 2.2 AI_AIR_PATROL Events
-- 
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.PatrolRoute}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_AIR_PATROL.Engage}**: Let the AI engage the bogeys.
--   * **@{#AI_AIR_PATROL.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_AIR_PATROL.Destroy}**: The AI has destroyed a bogey @{Wrapper.Unit}.
--   * **@{#AI_AIR_PATROL.Destroyed}**: The AI has destroyed all bogeys @{Wrapper.Unit}s assigned in the CAS task.
--   * **Status** ( Group ): The AI is checking status (fuel and damage). When the tresholds have been reached, the AI will RTB.
--
-- ## 3. Set the Range of Engagement
-- 
-- ![Range](..\Presentations\AI_CAP\Dia11.JPG)
-- 
-- An optional range can be set in meters, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- The range can be beyond or smaller than the range of the Patrol Zone.
-- The range is applied at the position of the AI.
-- Use the method @{AI.AI_CAP#AI_AIR_PATROL.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_CAP\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_AIR_PATROL.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_AIR_PATROL
AI_AIR_PATROL = {
  ClassName = "AI_AIR_PATROL",
}

--- Creates a new AI_AIR_PATROL object
-- @param #AI_AIR_PATROL self
-- @param AI.AI_Air#AI_AIR AI_Air The AI_AIR FSM.
-- @param Wrapper.Group#GROUP AIGroup The AI group.
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO.
-- @return #AI_AIR_PATROL
function AI_AIR_PATROL:New( AI_Air, AIGroup, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_Air ) -- #AI_AIR_PATROL

  local SpeedMax = AIGroup:GetSpeedMax()
  
  self.PatrolZone = PatrolZone
  
  self.PatrolFloorAltitude = PatrolFloorAltitude or 1000
  self.PatrolCeilingAltitude = PatrolCeilingAltitude or 1500
  self.PatrolMinSpeed = PatrolMinSpeed or SpeedMax * 0.5
  self.PatrolMaxSpeed = PatrolMaxSpeed or SpeedMax * 0.75
  
  -- defafult PatrolAltType to "RADIO" if not specified
  self.PatrolAltType = PatrolAltType or "RADIO"
  
  self:AddTransition( { "Started", "Airborne", "Refuelling" }, "Patrol", "Patrolling" )

  --- OnBefore Transition Handler for Event Patrol.
  -- @function [parent=#AI_AIR_PATROL] OnBeforePatrol
  -- @param #AI_AIR_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Patrol.
  -- @function [parent=#AI_AIR_PATROL] OnAfterPatrol
  -- @param #AI_AIR_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
    
  --- Synchronous Event Trigger for Event Patrol.
  -- @function [parent=#AI_AIR_PATROL] Patrol
  -- @param #AI_AIR_PATROL self
  
  --- Asynchronous Event Trigger for Event Patrol.
  -- @function [parent=#AI_AIR_PATROL] __Patrol
  -- @param #AI_AIR_PATROL self
  -- @param #number Delay The delay in seconds.
  
  --- OnLeave Transition Handler for State Patrolling.
  -- @function [parent=#AI_AIR_PATROL] OnLeavePatrolling
  -- @param #AI_AIR_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnEnter Transition Handler for State Patrolling.
  -- @function [parent=#AI_AIR_PATROL] OnEnterPatrolling
  -- @param #AI_AIR_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  
    self:AddTransition( "Patrolling", "PatrolRoute", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_AIR_PATROL.
  
  --- OnBefore Transition Handler for Event PatrolRoute.
  -- @function [parent=#AI_AIR_PATROL] OnBeforePatrolRoute
  -- @param #AI_AIR_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event PatrolRoute.
  -- @function [parent=#AI_AIR_PATROL] OnAfterPatrolRoute
  -- @param #AI_AIR_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
    
  --- Synchronous Event Trigger for Event PatrolRoute.
  -- @function [parent=#AI_AIR_PATROL] PatrolRoute
  -- @param #AI_AIR_PATROL self
  
  --- Asynchronous Event Trigger for Event PatrolRoute.
  -- @function [parent=#AI_AIR_PATROL] __PatrolRoute
  -- @param #AI_AIR_PATROL self
  -- @param #number Delay The delay in seconds.


  self:AddTransition( "*", "Reset", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_AIR_PATROL.

  return self
end


--- Set the Engage Range when the AI will engage with airborne enemies. 
-- @param #AI_AIR_PATROL self
-- @param #number EngageRange The Engage Range.
-- @return #AI_AIR_PATROL self
function AI_AIR_PATROL:SetEngageRange( EngageRange )
  self:F2()

  if EngageRange then  
    self.EngageRange = EngageRange
  else
    self.EngageRange = nil
  end
end

--- Set race track parameters. CAP flights will perform race track patterns rather than randomly patrolling the zone.
-- @param #AI_AIR_PATROL self
-- @param #number LegMin Min Length of the race track leg in meters. Default 10,000 m.
-- @param #number LegMax Max length of the race track leg in meters. Default 15,000 m.
-- @param #number HeadingMin Min heading of the race track in degrees. Default 0 deg, i.e. from South to North.
-- @param #number HeadingMax Max heading of the race track in degrees. Default 180 deg, i.e. from South to North.
-- @param #number DurationMin (Optional) Min duration before switching the orbit position. Default is keep same orbit until RTB or engage.
-- @param #number DurationMax (Optional) Max duration before switching the orbit position. Default is keep same orbit until RTB or engage.
-- @param #table CapCoordinates Table of coordinates of first race track point. Second point is determined by leg length and heading. 
-- @return #AI_AIR_PATROL self
function AI_AIR_PATROL:SetRaceTrackPattern(LegMin, LegMax, HeadingMin, HeadingMax, DurationMin, DurationMax, CapCoordinates)
  
  self.racetrack=true
  self.racetracklegmin=LegMin or 10000
  self.racetracklegmax=LegMax or 15000
  self.racetrackheadingmin=HeadingMin or 0
  self.racetrackheadingmax=HeadingMax or 180
  self.racetrackdurationmin=DurationMin
  self.racetrackdurationmax=DurationMax
  
  if self.racetrackdurationmax and not self.racetrackdurationmin then
    self.racetrackdurationmin=self.racetrackdurationmax
  end
  
  self.racetrackcapcoordinates=CapCoordinates
  
end



--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_AIR_PATROL self
-- @return #AI_AIR_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_AIR_PATROL:onafterPatrol( AIPatrol, From, Event, To )
  self:F2()

  self:ClearTargetDistance()

  self:__PatrolRoute( self.TaskDelay )
  
  AIPatrol:OnReSpawn(
    function( PatrolGroup )
      self:__Reset( self.TaskDelay )
      self:__PatrolRoute( self.TaskDelay )
    end
  )
end

--- This statis method is called from the route path within the last task at the last waaypoint of the AIPatrol.
-- Note that this method is required, as triggers the next route when patrolling for the AIPatrol.
-- @param Wrapper.Group#GROUP AIPatrol The AI group.
-- @param #AI_AIR_PATROL Fsm The FSM.
function AI_AIR_PATROL.___PatrolRoute( AIPatrol, Fsm )

  AIPatrol:F( { "AI_AIR_PATROL.___PatrolRoute:", AIPatrol:GetName() } )

  if AIPatrol and AIPatrol:IsAlive() then
    Fsm:PatrolRoute()
  end
  
end

--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_AIR_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_AIR_PATROL:onafterPatrolRoute( AIPatrol, From, Event, To )

  self:F2()

  -- When RTB, don't allow anymore the routing.
  if From == "RTB" then
    return
  end

  
  if AIPatrol and  AIPatrol:IsAlive() then
    
    local PatrolRoute = {}

    --- Calculate the target route point.
    
    local CurrentCoord = AIPatrol:GetCoordinate()
    
    local altitude= math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude )
    
    local ToTargetCoord = self.PatrolZone:GetRandomPointVec2()
    ToTargetCoord:SetAlt( altitude )
    self:SetTargetDistance( ToTargetCoord ) -- For RTB status check
    
    local ToTargetSpeed = math.random( self.PatrolMinSpeed, self.PatrolMaxSpeed )
    local speedkmh=ToTargetSpeed

    local FromWP = CurrentCoord:WaypointAir(self.PatrolAltType or "RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, ToTargetSpeed, true)
    PatrolRoute[#PatrolRoute+1] = FromWP

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
      local taskPatrol=AIPatrol:TaskFunction("AI_AIR_PATROL.___PatrolRoute", self)
      
      -- Controlled task with task condition.
      local taskCond=AIPatrol:TaskCondition(nil, nil, nil, nil, duration, nil)
      local taskCont=AIPatrol:TaskControlled(taskOrbit, taskCond)
      
      -- Second waypoint
      PatrolRoute[2]=c1:WaypointAirTurningPoint(self.PatrolAltType, speedkmh, {taskCont, taskPatrol}, "CAP Orbit")

    else
    
      --- Create a route point of type air.
      local ToWP = ToTargetCoord:WaypointAir(self.PatrolAltType, POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, ToTargetSpeed, true)  
      PatrolRoute[#PatrolRoute+1] = ToWP
      
      local Tasks = {}
      Tasks[#Tasks+1] = AIPatrol:TaskFunction("AI_AIR_PATROL.___PatrolRoute", self)
      PatrolRoute[#PatrolRoute].task = AIPatrol:TaskCombo( Tasks )
      
    end
    
    AIPatrol:OptionROEReturnFire()
    AIPatrol:OptionROTEvadeFire()
  
    AIPatrol:Route( PatrolRoute, self.TaskDelay )
    
  end

end

--- @param Wrapper.Group#GROUP AIPatrol
function AI_AIR_PATROL.Resume( AIPatrol, Fsm )

  AIPatrol:F( { "AI_AIR_PATROL.Resume:", AIPatrol:GetName() } )
  if AIPatrol and AIPatrol:IsAlive() then
    Fsm:__Reset( Fsm.TaskDelay )
    Fsm:__PatrolRoute( Fsm.TaskDelay )
  end
  
end
