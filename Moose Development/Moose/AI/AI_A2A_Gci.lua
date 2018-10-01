--- **AI** -- (R2.2) - Models the process of Ground Controlled Interception (GCI) for airplanes.
--
-- This is a class used in the @{AI_A2A_Dispatcher}.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_A2A_GCI
-- @image AI_Ground_Control_Intercept.JPG



--- @type AI_A2A_GCI
-- @extends AI.AI_A2A#AI_A2A


--- Implements the core functions to intercept intruders. Use the Engage trigger to intercept intruders.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia3.JPG)
-- 
-- The AI_A2A_GCI is assigned a @{Wrapper.Group} and this must be done before the AI_A2A_GCI process can be started using the **Start** event.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia4.JPG)
-- 
-- The AI will fly towards the random 3D point within the patrol zone, using a random speed within the given altitude and speed limits.
-- Upon arrival at the 3D point, a new random 3D point will be selected within the patrol zone using the given limits.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia5.JPG)
-- 
-- This cycle will continue.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia6.JPG)
-- 
-- During the patrol, the AI will detect enemy targets, which are reported through the **Detected** event.
--
-- ![Process](..\Presentations\AI_GCI\Dia9.JPG)
-- 
-- When enemies are detected, the AI will automatically engage the enemy.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia10.JPG)
-- 
-- Until a fuel or damage treshold has been reached by the AI, or when the AI is commanded to RTB.
-- When the fuel treshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia13.JPG)
-- 
-- ## 1. AI_A2A_GCI constructor
--   
--   * @{#AI_A2A_GCI.New}(): Creates a new AI_A2A_GCI object.
-- 
-- ## 2. AI_A2A_GCI is a FSM
-- 
-- ![Process](..\Presentations\AI_GCI\Dia2.JPG)
-- 
-- ### 2.1 AI_A2A_GCI States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Engaging** ( Group ): The AI is engaging the bogeys.
--   * **Returning** ( Group ): The AI is returning to Base..
-- 
-- ### 2.2 AI_A2A_GCI Events
-- 
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Route}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_A2A_GCI.Engage}**: Let the AI engage the bogeys.
--   * **@{#AI_A2A_GCI.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_A2A_GCI.Destroy}**: The AI has destroyed a bogey @{Wrapper.Unit}.
--   * **@{#AI_A2A_GCI.Destroyed}**: The AI has destroyed all bogeys @{Wrapper.Unit}s assigned in the CAS task.
--   * **Status** ( Group ): The AI is checking status (fuel and damage). When the tresholds have been reached, the AI will RTB.
--
-- ## 3. Set the Range of Engagement
-- 
-- ![Range](..\Presentations\AI_GCI\Dia11.JPG)
-- 
-- An optional range can be set in meters, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- The range can be beyond or smaller than the range of the Patrol Zone.
-- The range is applied at the position of the AI.
-- Use the method @{AI.AI_GCI#AI_A2A_GCI.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_GCI\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_A2A_GCI.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_A2A_GCI
AI_A2A_GCI = {
  ClassName = "AI_A2A_GCI",
}



--- Creates a new AI_A2A_GCI object
-- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept
-- @return #AI_A2A_GCI
function AI_A2A_GCI:New( AIIntercept, EngageMinSpeed, EngageMaxSpeed )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2A:New( AIIntercept ) ) -- #AI_A2A_GCI

  self.Accomplished = false
  self.Engaging = false
  
  self.EngageMinSpeed = EngageMinSpeed
  self.EngageMaxSpeed = EngageMaxSpeed
  self.PatrolMinSpeed = EngageMinSpeed
  self.PatrolMaxSpeed = EngageMaxSpeed
  
  self.PatrolAltType = "RADIO"
  
  self:AddTransition( { "Started", "Engaging", "Returning", "Airborne" }, "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_GCI.

  --- OnBefore Transition Handler for Event Engage.
  -- @function [parent=#AI_A2A_GCI] OnBeforeEngage
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_A2A_GCI] OnAfterEngage
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_A2A_GCI] Engage
  -- @param #AI_A2A_GCI self
  
  --- Asynchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_A2A_GCI] __Engage
  -- @param #AI_A2A_GCI self
  -- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Engaging.
-- @function [parent=#AI_A2A_GCI] OnLeaveEngaging
-- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_A2A_GCI] OnEnterEngaging
-- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_GCI.
  
  --- OnBefore Transition Handler for Event Fired.
  -- @function [parent=#AI_A2A_GCI] OnBeforeFired
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fired.
  -- @function [parent=#AI_A2A_GCI] OnAfterFired
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_A2A_GCI] Fired
  -- @param #AI_A2A_GCI self
  
  --- Asynchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_A2A_GCI] __Fired
  -- @param #AI_A2A_GCI self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Destroy", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_GCI.

  --- OnBefore Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2A_GCI] OnBeforeDestroy
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2A_GCI] OnAfterDestroy
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_A2A_GCI] Destroy
  -- @param #AI_A2A_GCI self
  
  --- Asynchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_A2A_GCI] __Destroy
  -- @param #AI_A2A_GCI self
  -- @param #number Delay The delay in seconds.


  self:AddTransition( "Engaging", "Abort", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_GCI.

  --- OnBefore Transition Handler for Event Abort.
  -- @function [parent=#AI_A2A_GCI] OnBeforeAbort
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Abort.
  -- @function [parent=#AI_A2A_GCI] OnAfterAbort
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_A2A_GCI] Abort
  -- @param #AI_A2A_GCI self
  
  --- Asynchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_A2A_GCI] __Abort
  -- @param #AI_A2A_GCI self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "Engaging", "Accomplish", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_GCI.

  --- OnBefore Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2A_GCI] OnBeforeAccomplish
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2A_GCI] OnAfterAccomplish
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_A2A_GCI] Accomplish
  -- @param #AI_A2A_GCI self
  
  --- Asynchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_A2A_GCI] __Accomplish
  -- @param #AI_A2A_GCI self
  -- @param #number Delay The delay in seconds.  

  return self
end

--- onafter State Transition for Event Patrol.
-- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onafterStart( AIIntercept, From, Event, To )

  self:GetParent( self ).onafterStart( self, AIIntercept, From, Event, To )
  AIIntercept:HandleEvent( EVENTS.Takeoff, nil, self )

end



--- onafter State Transition for Event Patrol.
-- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onafterEngage( AIIntercept, From, Event, To )

  self:HandleEvent( EVENTS.Dead )

end

-- todo: need to fix this global function

--- @param Wrapper.Group#GROUP AIControllable
function AI_A2A_GCI.InterceptRoute( AIIntercept, Fsm )

  AIIntercept:F( { "AI_A2A_GCI.InterceptRoute:", AIIntercept:GetName() } )
  
  if AIIntercept:IsAlive() then
    Fsm:__Engage( 0.5 )
  
    --local Task = AIIntercept:TaskOrbitCircle( 4000, 400 )
    --AIIntercept:SetTask( Task )
  end
end

--- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onbeforeEngage( AIIntercept, From, Event, To )
  
  if self.Accomplished == true then
    return false
  end
end

--- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onafterAbort( AIIntercept, From, Event, To )
  AIIntercept:ClearTasks()
  self:Return()
  self:__RTB( 0.5 )
end


--- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept The GroupGroup managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onafterEngage( AIIntercept, From, Event, To, AttackSetUnit )

  self:F( { AIIntercept, From, Event, To, AttackSetUnit} )

  self.AttackSetUnit = AttackSetUnit or self.AttackSetUnit -- Core.Set#SET_UNIT
  
  local FirstAttackUnit = self.AttackSetUnit:GetFirst()
  
  if FirstAttackUnit and FirstAttackUnit:IsAlive() then

    if AIIntercept:IsAlive() then
  
      local EngageRoute = {}
      
      local CurrentCoord = AIIntercept:GetCoordinate()
  
      --- Calculate the target route point.
      
      local CurrentCoord = AIIntercept:GetCoordinate()
      
      local ToTargetCoord = self.AttackSetUnit:GetFirst():GetCoordinate()
      self:SetTargetDistance( ToTargetCoord ) -- For RTB status check
      
      local ToTargetSpeed = math.random( self.EngageMinSpeed, self.EngageMaxSpeed )
      local ToInterceptAngle = CurrentCoord:GetAngleDegrees( CurrentCoord:GetDirectionVec3( ToTargetCoord ) )
      
      --- Create a route point of type air.
      local ToPatrolRoutePoint = CurrentCoord:Translate( 15000, ToInterceptAngle ):WaypointAir( 
        self.PatrolAltType, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        ToTargetSpeed, 
        true 
      )
  
      self:F( { Angle = ToInterceptAngle, ToTargetSpeed = ToTargetSpeed } )
      self:F( { self.EngageMinSpeed, self.EngageMaxSpeed, ToTargetSpeed } )
      
      EngageRoute[#EngageRoute+1] = ToPatrolRoutePoint
      EngageRoute[#EngageRoute+1] = ToPatrolRoutePoint
      
      local AttackTasks = {}
  
      for AttackUnitID, AttackUnit in pairs( self.AttackSetUnit:GetSet() ) do
        local AttackUnit = AttackUnit -- Wrapper.Unit#UNIT
        if AttackUnit:IsAlive() and AttackUnit:IsAir() then
          self:T( { "Intercepting Unit:", AttackUnit:GetName(), AttackUnit:IsAlive(), AttackUnit:IsAir() } )
          AttackTasks[#AttackTasks+1] = AIIntercept:TaskAttackUnit( AttackUnit )
        end
      end
        
      if #AttackTasks == 0 then
        self:E("No targets found -> Going RTB")
        self:Return()
        self:__RTB( 0.5 )
      else
        AIIntercept:OptionROEOpenFire()
        AIIntercept:OptionROTEvadeFire()

        AttackTasks[#AttackTasks+1] = AIIntercept:TaskFunction( "AI_A2A_GCI.InterceptRoute", self )
        EngageRoute[#EngageRoute].task = AIIntercept:TaskCombo( AttackTasks )
      end
      
      AIIntercept:Route( EngageRoute, 0.5 )
    
    end
  else
    self:E("No targets found -> Going RTB")
    self:Return()
    self:__RTB( 0.5 )
  end
end

--- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onafterAccomplish( AIIntercept, From, Event, To )
  self.Accomplished = true
  self:SetDetectionOff()
end

--- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Event#EVENTDATA EventData
function AI_A2A_GCI:onafterDestroy( AIIntercept, From, Event, To, EventData )

  if EventData.IniUnit then
    self.AttackUnits[EventData.IniUnit] = nil
  end
end

--- @param #AI_A2A_GCI self
-- @param Core.Event#EVENTDATA EventData
function AI_A2A_GCI:OnEventDead( EventData )
  self:F( { "EventDead", EventData } )

  if EventData.IniDCSUnit then
    if self.AttackUnits and self.AttackUnits[EventData.IniUnit] then
      self:__Destroy( 1, EventData )
    end
  end  
end
