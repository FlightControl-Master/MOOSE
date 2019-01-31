--- **AI** -- Models the process of A2G patrolling and engaging ground targets for airplanes and helicopters.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_A2G_Patrol
-- @image AI_Air_To_Ground_Patrol.JPG

--- @type AI_A2G_PATROL
-- @extends AI.AI_A2G_Engage#AI_A2G_ENGAGE


--- The AI_A2G_PATROL class implements the core functions to patrol a @{Zone} by an AI @{Wrapper.Group} or @{Wrapper.Group} 
-- and automatically engage any airborne enemies that are within a certain range or within a certain zone.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia3.JPG)
-- 
-- The AI_A2G_PATROL is assigned a @{Wrapper.Group} and this must be done before the AI_A2G_PATROL process can be started using the **Start** event.
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
-- ## 1. AI_A2G_PATROL constructor
--   
--   * @{#AI_A2G_PATROL.New}(): Creates a new AI_A2G_PATROL object.
-- 
-- ## 2. AI_A2G_PATROL is a FSM
-- 
-- ![Process](..\Presentations\AI_CAP\Dia2.JPG)
-- 
-- ### 2.1 AI_A2G_PATROL States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Engaging** ( Group ): The AI is engaging the bogeys.
--   * **Returning** ( Group ): The AI is returning to Base..
-- 
-- ### 2.2 AI_A2G_PATROL Events
-- 
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Route}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_A2G_PATROL.Engage}**: Let the AI engage the bogeys.
--   * **@{#AI_A2G_PATROL.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_A2G_PATROL.Destroy}**: The AI has destroyed a bogey @{Wrapper.Unit}.
--   * **@{#AI_A2G_PATROL.Destroyed}**: The AI has destroyed all bogeys @{Wrapper.Unit}s assigned in the CAS task.
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
-- Use the method @{AI.AI_CAP#AI_A2G_PATROL.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_CAP\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_A2G_PATROL.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_A2G_PATROL
AI_A2G_PATROL = {
  ClassName = "AI_A2G_PATROL",
}

--- Creates a new AI_A2G_PATROL object
-- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIGroup
-- @param DCS#Speed EngageMinSpeed (optional, default = 50% of max speed) The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO.
-- @return #AI_A2G_PATROL
function AI_A2G_PATROL:New( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2G_ENGAGE:New( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude ) ) -- #AI_A2G_PATROL

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
  -- @function [parent=#AI_A2G_PATROL] OnBeforePatrol
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Patrol.
  -- @function [parent=#AI_A2G_PATROL] OnAfterPatrol
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
    
  --- Synchronous Event Trigger for Event Patrol.
  -- @function [parent=#AI_A2G_PATROL] Patrol
  -- @param #AI_A2G_PATROL self
  
  --- Asynchronous Event Trigger for Event Patrol.
  -- @function [parent=#AI_A2G_PATROL] __Patrol
  -- @param #AI_A2G_PATROL self
  -- @param #number Delay The delay in seconds.
  
  --- OnLeave Transition Handler for State Patrolling.
  -- @function [parent=#AI_A2G_PATROL] OnLeavePatrolling
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnEnter Transition Handler for State Patrolling.
  -- @function [parent=#AI_A2G_PATROL] OnEnterPatrolling
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  
    self:AddTransition( "Patrolling", "Route", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_PATROL.
  
  --- OnBefore Transition Handler for Event Route.
  -- @function [parent=#AI_A2G_PATROL] OnBeforeRoute
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Route.
  -- @function [parent=#AI_A2G_PATROL] OnAfterRoute
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
    
  --- Synchronous Event Trigger for Event Route.
  -- @function [parent=#AI_A2G_PATROL] Route
  -- @param #AI_A2G_PATROL self
  
  --- Asynchronous Event Trigger for Event Route.
  -- @function [parent=#AI_A2G_PATROL] __Route
  -- @param #AI_A2G_PATROL self
  -- @param #number Delay The delay in seconds.


  self:AddTransition( "*", "Reset", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_PATROL.

  return self
end


--- Set the Engage Range when the AI will engage with airborne enemies. 
-- @param #AI_A2G_PATROL self
-- @param #number EngageRange The Engage Range.
-- @return #AI_A2G_PATROL self
function AI_A2G_PATROL:SetEngageRange( EngageRange )
  self:F2()

  if EngageRange then  
    self.EngageRange = EngageRange
  else
    self.EngageRange = nil
  end
end

--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_A2G_PATROL self
-- @return #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_PATROL:onafterPatrol( AIPatrol, From, Event, To )
  self:F2()

  self:ClearTargetDistance()

  self:__Route( self.TaskDelay )
  
  AIPatrol:OnReSpawn(
    function( PatrolGroup )
      self:__Reset( self.TaskDelay )
      self:__Route( self.TaskDelay )
    end
  )
end

--- @param Wrapper.Group#GROUP AIPatrol
-- This statis method is called from the route path within the last task at the last waaypoint of the AIPatrol.
-- Note that this method is required, as triggers the next route when patrolling for the AIPatrol.
function AI_A2G_PATROL.PatrolRoute( AIPatrol, Fsm )

  AIPatrol:F( { "AI_A2G_PATROL.PatrolRoute:", AIPatrol:GetName() } )

  if AIPatrol:IsAlive() then
    Fsm:Route()
  end
  
end

--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_PATROL:onafterRoute( AIPatrol, From, Event, To )

  self:F2()

  -- When RTB, don't allow anymore the routing.
  if From == "RTB" then
    return
  end

  
  if AIPatrol:IsAlive() then
    
    local PatrolRoute = {}

    --- Calculate the target route point.
    
    local CurrentCoord = AIPatrol:GetCoordinate()
    
    local ToTargetCoord = self.PatrolZone:GetRandomPointVec2()
    ToTargetCoord:SetAlt( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ) )
    self:SetTargetDistance( ToTargetCoord ) -- For RTB status check
    
    local ToTargetSpeed = math.random( self.PatrolMinSpeed, self.PatrolMaxSpeed )
    
    --- Create a route point of type air.
    local ToPatrolRoutePoint = ToTargetCoord:WaypointAir( 
      self.PatrolAltType, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      ToTargetSpeed, 
      true 
    )

    PatrolRoute[#PatrolRoute+1] = ToPatrolRoutePoint
    PatrolRoute[#PatrolRoute+1] = ToPatrolRoutePoint
    
    local Tasks = {}
    Tasks[#Tasks+1] = AIPatrol:TaskFunction( "AI_A2G_PATROL.PatrolRoute", self )
    PatrolRoute[#PatrolRoute].task = AIPatrol:TaskCombo( Tasks )
    
    AIPatrol:OptionROEReturnFire()
    AIPatrol:OptionROTEvadeFire()

    AIPatrol:Route( PatrolRoute, self.TaskDelay )
  end

end

--- @param Wrapper.Group#GROUP AIPatrol
function AI_A2G_PATROL.Resume( AIPatrol, Fsm )

  AIPatrol:F( { "AI_A2G_PATROL.Resume:", AIPatrol:GetName() } )
  if AIPatrol:IsAlive() then
    Fsm:__Reset( self.TaskDelay )
    Fsm:__Route( self.TaskDelay )
  end
  
end
