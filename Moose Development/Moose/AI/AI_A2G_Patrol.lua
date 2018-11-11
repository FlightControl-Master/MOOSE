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
-- @extends AI.AI_A2A_Patrol#AI_A2A_PATROL


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
-- @param Wrapper.Group#GROUP AIPatrol
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_A2G_PATROL
function AI_A2G_PATROL:New( AIPatrol, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2A_PATROL:New( AIPatrol, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType ) ) -- #AI_A2G_PATROL

  self.Accomplished = false
  self.Engaging = false
  
  self.EngageMinSpeed = EngageMinSpeed
  self.EngageMaxSpeed = EngageMaxSpeed
  
  self:AddTransition( { "Patrolling", "Engaging", "Returning", "Airborne" }, "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_PATROL.

  --- OnBefore Transition Handler for Event Engage.
  -- @function [parent=#AI_A2G_PATROL] OnBeforeEngage
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_A2G_PATROL] OnAfterEngage
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_A2G_PATROL] Engage
  -- @param #AI_A2G_PATROL self
  
  --- Asynchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_A2G_PATROL] __Engage
  -- @param #AI_A2G_PATROL self
  -- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Engaging.
-- @function [parent=#AI_A2G_PATROL] OnLeaveEngaging
-- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_A2G_PATROL] OnEnterEngaging
-- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_PATROL.
  
  --- OnBefore Transition Handler for Event Fired.
  -- @function [parent=#AI_A2G_PATROL] OnBeforeFired
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fired.
  -- @function [parent=#AI_A2G_PATROL] OnAfterFired
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_A2G_PATROL] Fired
  -- @param #AI_A2G_PATROL self
  
  --- Asynchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_A2G_PATROL] __Fired
  -- @param #AI_A2G_PATROL self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Destroy", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_PATROL.

  --- OnBefore Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2G_PATROL] OnBeforeDestroy
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2G_PATROL] OnAfterDestroy
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_A2G_PATROL] Destroy
  -- @param #AI_A2G_PATROL self
  
  --- Asynchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_A2G_PATROL] __Destroy
  -- @param #AI_A2G_PATROL self
  -- @param #number Delay The delay in seconds.


  self:AddTransition( "Engaging", "Abort", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_PATROL.

  --- OnBefore Transition Handler for Event Abort.
  -- @function [parent=#AI_A2G_PATROL] OnBeforeAbort
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Abort.
  -- @function [parent=#AI_A2G_PATROL] OnAfterAbort
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_A2G_PATROL] Abort
  -- @param #AI_A2G_PATROL self
  
  --- Asynchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_A2G_PATROL] __Abort
  -- @param #AI_A2G_PATROL self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "Engaging", "Accomplish", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_PATROL.

  --- OnBefore Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2G_PATROL] OnBeforeAccomplish
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2G_PATROL] OnAfterAccomplish
  -- @param #AI_A2G_PATROL self
  -- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_A2G_PATROL] Accomplish
  -- @param #AI_A2G_PATROL self
  
  --- Asynchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_A2G_PATROL] __Accomplish
  -- @param #AI_A2G_PATROL self
  -- @param #number Delay The delay in seconds.  

  return self
end


--- onafter State Transition for Event Patrol.
-- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_PATROL:onafterStart( AIPatrol, From, Event, To )

  self:GetParent( self ).onafterStart( self, AIPatrol, From, Event, To )
  AIPatrol:HandleEvent( EVENTS.Takeoff, nil, self )

end

--- Set the Engage Zone which defines where the AI will engage bogies. 
-- @param #AI_A2G_PATROL self
-- @param Core.Zone#ZONE EngageZone The zone where the AI is performing CAP.
-- @return #AI_A2G_PATROL self
function AI_A2G_PATROL:SetEngageZone( EngageZone )
  self:F2()

  if EngageZone then  
    self.EngageZone = EngageZone
  else
    self.EngageZone = nil
  end
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

--- onafter State Transition for Event Patrol.
-- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_PATROL:onafterPatrol( AIPatrol, From, Event, To )

  -- Call the parent Start event handler
  self:GetParent(self).onafterPatrol( self, AIPatrol, From, Event, To )
  self:HandleEvent( EVENTS.Dead )

end

-- todo: need to fix this global function

--- @param Wrapper.Group#GROUP AIPatrol
function AI_A2G_PATROL.AttackRoute( AIPatrol, Fsm )

  AIPatrol:F( { "AI_A2G_PATROL.AttackRoute:", AIPatrol:GetName() } )

  if AIPatrol:IsAlive() then
    Fsm:__Engage( 0.5 )
  end
end

--- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_PATROL:onbeforeEngage( AIPatrol, From, Event, To )
  
  if self.Accomplished == true then
    return false
  end
end

--- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_PATROL:onafterAbort( AIPatrol, From, Event, To )
  AIPatrol:ClearTasks()
  self:__Route( 0.5 )
end


--- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The AIPatrol Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_PATROL:onafterEngage( AIPatrol, From, Event, To, AttackSetUnit )

  self:F( { AIPatrol, From, Event, To, AttackSetUnit} )

  self.AttackSetUnit = AttackSetUnit or self.AttackSetUnit -- Core.Set#SET_UNIT
  
  local FirstAttackUnit = self.AttackSetUnit:GetFirst() -- Wrapper.Unit#UNIT
  
  if FirstAttackUnit and FirstAttackUnit:IsAlive() then -- If there is no attacker anymore, stop the engagement.
  
    if AIPatrol:IsAlive() then

      local EngageRoute = {}

      --- Calculate the target route point.
      local CurrentCoord = AIPatrol:GetCoordinate()
      local ToTargetCoord = self.AttackSetUnit:GetFirst():GetCoordinate()
      local ToTargetSpeed = math.random( self.EngageMinSpeed, self.EngageMaxSpeed )
      local ToInterceptAngle = CurrentCoord:GetAngleDegrees( CurrentCoord:GetDirectionVec3( ToTargetCoord ) )
      
      --- Create a route point of type air.
      local ToPatrolRoutePoint = CurrentCoord:Translate( 5000, ToInterceptAngle ):WaypointAir( 
        self.PatrolAltType, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        ToTargetSpeed, 
        true 
      )
  
      self:F( { Angle = ToInterceptAngle, ToTargetSpeed = ToTargetSpeed } )
      self:T2( { self.MinSpeed, self.MaxSpeed, ToTargetSpeed } )
      
      EngageRoute[#EngageRoute+1] = ToPatrolRoutePoint
      EngageRoute[#EngageRoute+1] = ToPatrolRoutePoint

      local AttackTasks = {}
  
      for AttackUnitID, AttackUnit in pairs( self.AttackSetUnit:GetSet() ) do
        local AttackUnit = AttackUnit -- Wrapper.Unit#UNIT
        self:T( { "Attacking Unit:", AttackUnit:GetName(), AttackUnit:IsAlive(), AttackUnit:IsAir() } )
        if AttackUnit:IsAlive() and AttackUnit:IsGround() then
          AttackTasks[#AttackTasks+1] = AIPatrol:TaskAttackUnit( AttackUnit )
        end
      end
  
      if #AttackTasks == 0 then
        self:E("No targets found -> Going back to Patrolling")
        self:__Abort( 0.5 )
      else
        AIPatrol:OptionROEOpenFire()
        AIPatrol:OptionROTEvadeFire()

        AttackTasks[#AttackTasks+1] = AIPatrol:TaskFunction( "AI_A2G_PATROL.AttackRoute", self )
        EngageRoute[#EngageRoute].task = AIPatrol:TaskCombo( AttackTasks )
      end
      
      AIPatrol:Route( EngageRoute, 0.5 )
    end
  else
    self:E("No targets found -> Going back to Patrolling")
    self:__Abort( 0.5 )
  end
end

--- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_PATROL:onafterAccomplish( AIPatrol, From, Event, To )
  self.Accomplished = true
  self:SetDetectionOff()
end

--- @param #AI_A2G_PATROL self
-- @param Wrapper.Group#GROUP AIPatrol The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Event#EVENTDATA EventData
function AI_A2G_PATROL:onafterDestroy( AIPatrol, From, Event, To, EventData )

  if EventData.IniUnit then
    self.AttackUnits[EventData.IniUnit] = nil
  end
end

--- @param #AI_A2G_PATROL self
-- @param Core.Event#EVENTDATA EventData
function AI_A2G_PATROL:OnEventDead( EventData )
  self:F( { "EventDead", EventData } )

  if EventData.IniDCSUnit then
    if self.AttackUnits and self.AttackUnits[EventData.IniUnit] then
      self:__Destroy( 1, EventData )
    end
  end  
end

--- @param Wrapper.Group#GROUP AIPatrol
function AI_A2G_PATROL.Resume( AIPatrol, Fsm )

  AIPatrol:I( { "AI_A2G_PATROL.Resume:", AIPatrol:GetName() } )
  if AIPatrol:IsAlive() then
    Fsm:__Reset( 1 )
    Fsm:__Route( 5 )
  end
  
end
