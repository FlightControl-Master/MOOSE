--- **AI** -- (R2.2) - Models the process of Combat Air Patrol (CAP) for airplanes.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_A2A_Cap
-- @image AI_Combat_Air_Patrol.JPG

--- @type AI_A2A_CAP
-- @extends AI.AI_A2A_Patrol#AI_A2A_PATROL


--- The AI_A2A_CAP class implements the core functions to patrol a @{Zone} by an AI @{Wrapper.Group} or @{Wrapper.Group} 
-- and automatically engage any airborne enemies that are within a certain range or within a certain zone.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia3.JPG)
-- 
-- The AI_A2A_CAP is assigned a @{Wrapper.Group} and this must be done before the AI_A2A_CAP process can be started using the **Start** event.
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
-- ## 1. AI_A2A_CAP constructor
--   
--   * @{#AI_A2A_CAP.New}(): Creates a new AI_A2A_CAP object.
-- 
-- ## 2. AI_A2A_CAP is a FSM
-- 
-- ![Process](..\Presentations\AI_CAP\Dia2.JPG)
-- 
-- ### 2.1 AI_A2A_CAP States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Engaging** ( Group ): The AI is engaging the bogeys.
--   * **Returning** ( Group ): The AI is returning to Base..
-- 
-- ### 2.2 AI_A2A_CAP Events
-- 
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Route}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_A2A_CAP.Engage}**: Let the AI engage the bogeys.
--   * **@{#AI_A2A_CAP.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_A2A_CAP.Destroy}**: The AI has destroyed a bogey @{Wrapper.Unit}.
--   * **@{#AI_A2A_CAP.Destroyed}**: The AI has destroyed all bogeys @{Wrapper.Unit}s assigned in the CAS task.
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
-- Use the method @{AI.AI_CAP#AI_A2A_CAP.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_CAP\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_A2A_CAP.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_A2A_CAP
AI_A2A_CAP = {
  ClassName = "AI_A2A_CAP",
}

--- Creates a new AI_A2A_CAP object
-- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_A2A_CAP
function AI_A2A_CAP:New( AICap, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2A_PATROL:New( AICap, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType ) ) -- #AI_A2A_CAP

  self.Accomplished = false
  self.Engaging = false
  
  self.EngageMinSpeed = EngageMinSpeed
  self.EngageMaxSpeed = EngageMaxSpeed
  
  self:AddTransition( { "Patrolling", "Engaging", "Returning", "Airborne" }, "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_CAP.

  --- OnBefore Transition Handler for Event Engage.
  -- @function [parent=#AI_A2A_CAP] OnBeforeEngage
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_A2A_CAP] OnAfterEngage
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_A2A_CAP] Engage
  -- @param #AI_A2A_CAP self
  
  --- Asynchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_A2A_CAP] __Engage
  -- @param #AI_A2A_CAP self
  -- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Engaging.
-- @function [parent=#AI_A2A_CAP] OnLeaveEngaging
-- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_A2A_CAP] OnEnterEngaging
-- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_CAP.
  
  --- OnBefore Transition Handler for Event Fired.
  -- @function [parent=#AI_A2A_CAP] OnBeforeFired
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fired.
  -- @function [parent=#AI_A2A_CAP] OnAfterFired
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_A2A_CAP] Fired
  -- @param #AI_A2A_CAP self
  
  --- Asynchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_A2A_CAP] __Fired
  -- @param #AI_A2A_CAP self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Destroy", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_CAP.

  --- OnBefore Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2A_CAP] OnBeforeDestroy
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2A_CAP] OnAfterDestroy
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_A2A_CAP] Destroy
  -- @param #AI_A2A_CAP self
  
  --- Asynchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_A2A_CAP] __Destroy
  -- @param #AI_A2A_CAP self
  -- @param #number Delay The delay in seconds.


  self:AddTransition( "Engaging", "Abort", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_CAP.

  --- OnBefore Transition Handler for Event Abort.
  -- @function [parent=#AI_A2A_CAP] OnBeforeAbort
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Abort.
  -- @function [parent=#AI_A2A_CAP] OnAfterAbort
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_A2A_CAP] Abort
  -- @param #AI_A2A_CAP self
  
  --- Asynchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_A2A_CAP] __Abort
  -- @param #AI_A2A_CAP self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "Engaging", "Accomplish", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_CAP.

  --- OnBefore Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2A_CAP] OnBeforeAccomplish
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2A_CAP] OnAfterAccomplish
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_A2A_CAP] Accomplish
  -- @param #AI_A2A_CAP self
  
  --- Asynchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_A2A_CAP] __Accomplish
  -- @param #AI_A2A_CAP self
  -- @param #number Delay The delay in seconds.  

  return self
end

--- onafter State Transition for Event Patrol.
-- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onafterStart( AICap, From, Event, To )

  self:GetParent( self ).onafterStart( self, AICap, From, Event, To )
  AICap:HandleEvent( EVENTS.Takeoff, nil, self )

end

--- Set the Engage Zone which defines where the AI will engage bogies. 
-- @param #AI_A2A_CAP self
-- @param Core.Zone#ZONE EngageZone The zone where the AI is performing CAP.
-- @return #AI_A2A_CAP self
function AI_A2A_CAP:SetEngageZone( EngageZone )
  self:F2()

  if EngageZone then  
    self.EngageZone = EngageZone
  else
    self.EngageZone = nil
  end
end

--- Set the Engage Range when the AI will engage with airborne enemies. 
-- @param #AI_A2A_CAP self
-- @param #number EngageRange The Engage Range.
-- @return #AI_A2A_CAP self
function AI_A2A_CAP:SetEngageRange( EngageRange )
  self:F2()

  if EngageRange then  
    self.EngageRange = EngageRange
  else
    self.EngageRange = nil
  end
end

--- onafter State Transition for Event Patrol.
-- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onafterPatrol( AICap, From, Event, To )

  -- Call the parent Start event handler
  self:GetParent(self).onafterPatrol( self, AICap, From, Event, To )
  self:HandleEvent( EVENTS.Dead )

end

-- todo: need to fix this global function

--- @param Wrapper.Group#GROUP AICap
function AI_A2A_CAP.AttackRoute( AICap, Fsm )

  AICap:F( { "AI_A2A_CAP.AttackRoute:", AICap:GetName() } )

  if AICap:IsAlive() then
    Fsm:__Engage( 0.5 )
  end
end

--- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onbeforeEngage( AICap, From, Event, To )
  
  if self.Accomplished == true then
    return false
  end
end

--- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onafterAbort( AICap, From, Event, To )
  AICap:ClearTasks()
  self:__Route( 0.5 )
end


--- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap The AICap Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onafterEngage( AICap, From, Event, To, AttackSetUnit )

  self:F( { AICap, From, Event, To, AttackSetUnit} )

  self.AttackSetUnit = AttackSetUnit or self.AttackSetUnit -- Core.Set#SET_UNIT
  
  local FirstAttackUnit = self.AttackSetUnit:GetFirst() -- Wrapper.Unit#UNIT
  
  if FirstAttackUnit and FirstAttackUnit:IsAlive() then -- If there is no attacker anymore, stop the engagement.
  
    if AICap:IsAlive() then

      local EngageRoute = {}

      --- Calculate the target route point.
      local CurrentCoord = AICap:GetCoordinate()
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
        if AttackUnit:IsAlive() and AttackUnit:IsAir() then
          AttackTasks[#AttackTasks+1] = AICap:TaskAttackUnit( AttackUnit )
        end
      end
  
      if #AttackTasks == 0 then
        self:E("No targets found -> Going back to Patrolling")
        self:__Abort( 0.5 )
      else
        AICap:OptionROEOpenFire()
        AICap:OptionROTEvadeFire()

        AttackTasks[#AttackTasks+1] = AICap:TaskFunction( "AI_A2A_CAP.AttackRoute", self )
        EngageRoute[#EngageRoute].task = AICap:TaskCombo( AttackTasks )
      end
      
      AICap:Route( EngageRoute, 0.5 )
    end
  else
    self:E("No targets found -> Going back to Patrolling")
    self:__Abort( 0.5 )
  end
end

--- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onafterAccomplish( AICap, From, Event, To )
  self.Accomplished = true
  self:SetDetectionOff()
end

--- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Event#EVENTDATA EventData
function AI_A2A_CAP:onafterDestroy( AICap, From, Event, To, EventData )

  if EventData.IniUnit then
    self.AttackUnits[EventData.IniUnit] = nil
  end
end

--- @param #AI_A2A_CAP self
-- @param Core.Event#EVENTDATA EventData
function AI_A2A_CAP:OnEventDead( EventData )
  self:F( { "EventDead", EventData } )

  if EventData.IniDCSUnit then
    if self.AttackUnits and self.AttackUnits[EventData.IniUnit] then
      self:__Destroy( 1, EventData )
    end
  end  
end

--- @param Wrapper.Group#GROUP AICap
function AI_A2A_CAP.Resume( AICap, Fsm )

  AICap:I( { "AI_A2A_CAP.Resume:", AICap:GetName() } )
  if AICap:IsAlive() then
    Fsm:__Reset( 1 )
    Fsm:__Route( 5 )
  end
  
end
