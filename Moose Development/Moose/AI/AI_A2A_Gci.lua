--- **AI** -- **Execute Ground Controlled Interception (GCI).**
--
-- ![Banner Image](..\Presentations\AI_GCI\Dia1.JPG)
-- 
-- ===
-- 
-- AI A2A_INTEREPT class makes AI Groups execute an Intercept.
-- 
-- There are the following types of GCI classes defined:
-- 
--   * @{#AI_A2A_GCI}: Perform a GCI in a zone.
--   
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====       
--
-- @module AI_A2A_GCI


--BASE:TraceClass("AI_A2A_GCI")


--- @type AI_A2A_GCI
-- @extends AI.AI_A2A#AI_A2A


--- # AI_A2A_GCI class, extends @{AI_A2A#AI_A2A}
-- 
-- The AI_A2A_GCI class implements the core functions to intercept intruders. The Engage function will intercept intruders.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia3.JPG)
-- 
-- The AI_A2A_GCI is assigned a @{Group} and this must be done before the AI_A2A_GCI process can be started using the **Start** event.
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
--   * **@{AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI_Patrol#AI_PATROL_ZONE.Route}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_A2A_GCI.Engage}**: Let the AI engage the bogeys.
--   * **@{#AI_A2A_GCI.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_A2A_GCI.Destroy}**: The AI has destroyed a bogey @{Unit}.
--   * **@{#AI_A2A_GCI.Destroyed}**: The AI has destroyed all bogeys @{Unit}s assigned in the CAS task.
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
-- Use the method @{AI_GCI#AI_A2A_GCI.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_GCI\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI_Cap#AI_A2A_GCI.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_A2A_GCI
AI_A2A_GCI = {
  ClassName = "AI_A2A_GCI",
}



--- Creates a new AI_A2A_GCI object
-- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIGroup
-- @return #AI_A2A_GCI
function AI_A2A_GCI:New( AIGroup, EngageMinSpeed, EngageMaxSpeed )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2A:New( AIGroup ) ) -- #AI_A2A_GCI

  self.Accomplished = false
  self.Engaging = false
  
  self.EngageMinSpeed = EngageMinSpeed
  self.EngageMaxSpeed = EngageMaxSpeed
  self.PatrolMinSpeed = EngageMinSpeed
  self.PatrolMaxSpeed = EngageMaxSpeed
  
  self.PatrolAltType = "RADIO"
  
  self:AddTransition( { "Started", "Engaging", "Returning" }, "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_GCI.

  --- OnBefore Transition Handler for Event Engage.
  -- @function [parent=#AI_A2A_GCI] OnBeforeEngage
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_A2A_GCI] OnAfterEngage
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
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
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_A2A_GCI] OnEnterEngaging
-- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_GCI.
  
  --- OnBefore Transition Handler for Event Fired.
  -- @function [parent=#AI_A2A_GCI] OnBeforeFired
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fired.
  -- @function [parent=#AI_A2A_GCI] OnAfterFired
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
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
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2A_GCI] OnAfterDestroy
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
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
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Abort.
  -- @function [parent=#AI_A2A_GCI] OnAfterAbort
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
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
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2A_GCI] OnAfterAccomplish
  -- @param #AI_A2A_GCI self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
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
-- @param Wrapper.Group#GROUP AIGroup The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onafterEngage( AIGroup, From, Event, To )

  self:HandleEvent( EVENTS.Dead )

end

-- todo: need to fix this global function

--- @param Wrapper.Group#GROUP AIControllable
function AI_A2A_GCI.InterceptRoute( AIControllable )

  AIControllable:T( "NewEngageRoute" )
  local EngageZone = AIControllable:GetState( AIControllable, "EngageZone" ) -- AI.AI_Cap#AI_A2A_GCI
  EngageZone:__Engage( 0.5 )
end

--- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onbeforeEngage( AIGroup, From, Event, To )
  
  if self.Accomplished == true then
    return false
  end
end

--- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIGroup The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onafterAbort( AIGroup, From, Event, To )
  AIGroup:ClearTasks()
  self:Return()
  self:__RTB( 0.5 )
end


--- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onafterEngage( AIGroup, From, Event, To, AttackSetUnit )

  self:F( { AIGroup, From, Event, To, AttackSetUnit} )

  self.AttackSetUnit = AttackSetUnit or self.AttackSetUnit -- Core.Set#SET_UNIT
  
  local FirstAttackUnit = self.AttackSetUnit:GetFirst()
  
  if FirstAttackUnit then

    if AIGroup:IsAlive() then
  
      local EngageRoute = {}
  
      --- Calculate the target route point.
      
      local CurrentCoord = AIGroup:GetCoordinate()
      
      local ToTargetCoord = self.AttackSetUnit:GetFirst():GetCoordinate()
      self:SetTargetDistance( ToTargetCoord ) -- For RTB status check
      
      local ToTargetSpeed = math.random( self.EngageMinSpeed, self.EngageMaxSpeed )
      local ToInterceptAngle = CurrentCoord:GetAngleDegrees( CurrentCoord:GetDirectionVec3( ToTargetCoord ) )
      
      --- Create a route point of type air.
      local ToPatrolRoutePoint = CurrentCoord:Translate( 5000, ToInterceptAngle ):RoutePointAir( 
        self.PatrolAltType, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        ToTargetSpeed, 
        true 
      )
  
      self:F( { Angle = ToInterceptAngle, ToTargetSpeed = ToTargetSpeed } )
      self:T2( { self.EngageMinSpeed, self.EngageMaxSpeed, ToTargetSpeed } )
      
      EngageRoute[#EngageRoute+1] = ToPatrolRoutePoint
      
      AIGroup:OptionROEOpenFire()
      AIGroup:OptionROTPassiveDefense()
  
      local AttackTasks = {}
  
      for AttackUnitID, AttackUnit in pairs( self.AttackSetUnit:GetSet() ) do
        local AttackUnit = AttackUnit -- Wrapper.Unit#UNIT
        self:T( { "Intercepting Unit:", AttackUnit:GetName(), AttackUnit:IsAlive(), AttackUnit:IsAir() } )
        if AttackUnit:IsAlive() and AttackUnit:IsAir() then
          AttackTasks[#AttackTasks+1] = AIGroup:TaskAttackUnit( AttackUnit )
        end
      end
  
      --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
      AIGroup:WayPointInitialize( EngageRoute )
      
      
      if #AttackTasks == 0 then
        self:E("No targets found -> Going RTB")
        self:Return()
        self:__RTB( 0.5 )
      else
        AttackTasks[#AttackTasks+1] = AIGroup:TaskFunction( 1, #AttackTasks, "AI_A2A_GCI.InterceptRoute" )
        AttackTasks[#AttackTasks+1] = AIGroup:TaskOrbitCircle( 4000, self.EngageMinSpeed )
        EngageRoute[1].task = AIGroup:TaskCombo( AttackTasks )
        
        --- Do a trick, link the NewEngageRoute function of the object to the AIControllable in a temporary variable ...
        AIGroup:SetState( AIGroup, "EngageZone", self )
      end
      
      --- NOW ROUTE THE GROUP!
      AIGroup:WayPointExecute( 1, 0 )
    
    end
  else
    self:E("No targets found -> Going RTB")
    self:Return()
    self:__RTB( 0.5 )
  end
end

--- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onafterAccomplish( AIGroup, From, Event, To )
  self.Accomplished = true
  self:SetDetectionOff()
end

--- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Event#EVENTDATA EventData
function AI_A2A_GCI:onafterDestroy( AIGroup, From, Event, To, EventData )

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
