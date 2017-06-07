--- **AI** -- **Execute Interception of Intruders (CAP).**
--
-- ![Banner Image](..\Presentations\AI_CAP\Dia1.JPG)
-- 
-- ===
-- 
-- AI A2A_INTEREPT class makes AI Groups execute an Intercept.
-- 
-- There are the following types of CAP classes defined:
-- 
--   * @{#AI_A2A_INTERCEPT}: Perform a CAP in a zone.
--   
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====       
--
-- @module AI_A2A_Intercept


--BASE:TraceClass("AI_A2A_INTERCEPT")


--- @type AI_A2A_INTERCEPT
-- @extends AI.AI_A2A#AI_A2A


--- # AI_A2A_INTERCEPT class, extends @{AI_A2A#AI_A2A}
-- 
-- The AI_A2A_INTERCEPT class implements the core functions to intercept intruders. The Engage function will intercept intruders.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia3.JPG)
-- 
-- The AI_A2A_INTERCEPT is assigned a @{Group} and this must be done before the AI_A2A_INTERCEPT process can be started using the **Start** event.
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
-- ## 1. AI_A2A_INTERCEPT constructor
--   
--   * @{#AI_A2A_INTERCEPT.New}(): Creates a new AI_A2A_INTERCEPT object.
-- 
-- ## 2. AI_A2A_INTERCEPT is a FSM
-- 
-- ![Process](..\Presentations\AI_CAP\Dia2.JPG)
-- 
-- ### 2.1 AI_A2A_INTERCEPT States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Engaging** ( Group ): The AI is engaging the bogeys.
--   * **Returning** ( Group ): The AI is returning to Base..
-- 
-- ### 2.2 AI_A2A_INTERCEPT Events
-- 
--   * **@{AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI_Patrol#AI_PATROL_ZONE.Route}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_A2A_INTERCEPT.Engage}**: Let the AI engage the bogeys.
--   * **@{#AI_A2A_INTERCEPT.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_A2A_INTERCEPT.Destroy}**: The AI has destroyed a bogey @{Unit}.
--   * **@{#AI_A2A_INTERCEPT.Destroyed}**: The AI has destroyed all bogeys @{Unit}s assigned in the CAS task.
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
-- Use the method @{AI_CAP#AI_A2A_INTERCEPT.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_CAP\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI_Cap#AI_A2A_INTERCEPT.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_A2A_INTERCEPT
AI_A2A_INTERCEPT = {
  ClassName = "AI_A2A_INTERCEPT",
}



--- Creates a new AI_A2A_INTERCEPT object
-- @param #AI_A2A_INTERCEPT self
-- @param Wrapper.Group#GROUP AIGroup
-- @return #AI_A2A_INTERCEPT
function AI_A2A_INTERCEPT:New( AIGroup, MinSpeed, MaxSpeed )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2A:New( AIGroup ) ) -- #AI_A2A_INTERCEPT

  self.Accomplished = false
  self.Engaging = false
  
  self.MinSpeed = MinSpeed
  self.MaxSpeed = MaxSpeed
  
  self.PatrolAltType = "RADIO"
  
  self:AddTransition( { "Started", "Engaging" }, "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_INTERCEPT.

  --- OnBefore Transition Handler for Event Engage.
  -- @function [parent=#AI_A2A_INTERCEPT] OnBeforeEngage
  -- @param #AI_A2A_INTERCEPT self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_A2A_INTERCEPT] OnAfterEngage
  -- @param #AI_A2A_INTERCEPT self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_A2A_INTERCEPT] Engage
  -- @param #AI_A2A_INTERCEPT self
  
  --- Asynchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_A2A_INTERCEPT] __Engage
  -- @param #AI_A2A_INTERCEPT self
  -- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Engaging.
-- @function [parent=#AI_A2A_INTERCEPT] OnLeaveEngaging
-- @param #AI_A2A_INTERCEPT self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_A2A_INTERCEPT] OnEnterEngaging
-- @param #AI_A2A_INTERCEPT self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_INTERCEPT.
  
  --- OnBefore Transition Handler for Event Fired.
  -- @function [parent=#AI_A2A_INTERCEPT] OnBeforeFired
  -- @param #AI_A2A_INTERCEPT self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fired.
  -- @function [parent=#AI_A2A_INTERCEPT] OnAfterFired
  -- @param #AI_A2A_INTERCEPT self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_A2A_INTERCEPT] Fired
  -- @param #AI_A2A_INTERCEPT self
  
  --- Asynchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_A2A_INTERCEPT] __Fired
  -- @param #AI_A2A_INTERCEPT self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Destroy", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_INTERCEPT.

  --- OnBefore Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2A_INTERCEPT] OnBeforeDestroy
  -- @param #AI_A2A_INTERCEPT self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2A_INTERCEPT] OnAfterDestroy
  -- @param #AI_A2A_INTERCEPT self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_A2A_INTERCEPT] Destroy
  -- @param #AI_A2A_INTERCEPT self
  
  --- Asynchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_A2A_INTERCEPT] __Destroy
  -- @param #AI_A2A_INTERCEPT self
  -- @param #number Delay The delay in seconds.


  self:AddTransition( "Engaging", "Abort", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_INTERCEPT.

  --- OnBefore Transition Handler for Event Abort.
  -- @function [parent=#AI_A2A_INTERCEPT] OnBeforeAbort
  -- @param #AI_A2A_INTERCEPT self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Abort.
  -- @function [parent=#AI_A2A_INTERCEPT] OnAfterAbort
  -- @param #AI_A2A_INTERCEPT self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_A2A_INTERCEPT] Abort
  -- @param #AI_A2A_INTERCEPT self
  
  --- Asynchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_A2A_INTERCEPT] __Abort
  -- @param #AI_A2A_INTERCEPT self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "Engaging", "Accomplish", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_INTERCEPT.

  --- OnBefore Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2A_INTERCEPT] OnBeforeAccomplish
  -- @param #AI_A2A_INTERCEPT self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2A_INTERCEPT] OnAfterAccomplish
  -- @param #AI_A2A_INTERCEPT self
  -- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_A2A_INTERCEPT] Accomplish
  -- @param #AI_A2A_INTERCEPT self
  
  --- Asynchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_A2A_INTERCEPT] __Accomplish
  -- @param #AI_A2A_INTERCEPT self
  -- @param #number Delay The delay in seconds.  

  return self
end


--- onafter State Transition for Event Patrol.
-- @param #AI_A2A_INTERCEPT self
-- @param Wrapper.Group#GROUP AIGroup The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_INTERCEPT:onafterEngage( AIGroup, From, Event, To )

  self:HandleEvent( EVENTS.Dead )

end

-- todo: need to fix this global function

--- @param Wrapper.Group#GROUP AIControllable
function AI_A2A_INTERCEPT.InterceptRoute( AIControllable )

  AIControllable:T( "NewEngageRoute" )
  local EngageZone = AIControllable:GetState( AIControllable, "EngageZone" ) -- AI.AI_Cap#AI_A2A_INTERCEPT
  EngageZone:__Engage( 1 )
end

--- @param #AI_A2A_INTERCEPT self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_INTERCEPT:onbeforeEngage( AIGroup, From, Event, To )
  
  if self.Accomplished == true then
    return false
  end
end

--- @param #AI_A2A_INTERCEPT self
-- @param Wrapper.Group#GROUP AIGroup The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_INTERCEPT:onafterAbort( AIGroup, From, Event, To )
  AIGroup:ClearTasks()
  self:__Route( 1 )
end


--- @param #AI_A2A_INTERCEPT self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_INTERCEPT:onafterEngage( AIGroup, From, Event, To, AttackSetUnit )

  self:F( { AIGroup, From, Event, To, AttackSetUnit} )

  self.AttackSetUnit = AttackSetUnit or self.AttackSetUnit -- Core.Set#SET_UNIT
  
  local FirstAttackUnit = self.AttackSetUnit:GetFirst()
  
  if FirstAttackUnit then

    if AIGroup:IsAlive() then
  
      local EngageRoute = {}
  
      --- Calculate the target route point.
      
      local CurrentCoord = AIGroup:GetCoordinate()
      local ToTargetCoord = self.AttackSetUnit:GetFirst():GetCoordinate()
      local ToTargetSpeed = math.random( self.MinSpeed, self.MaxSpeed )
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
      self:T2( { self.MinSpeed, self.MaxSpeed, ToTargetSpeed } )
      
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
        self:__RTB( 1 )
      else
        AttackTasks[#AttackTasks+1] = AIGroup:TaskFunction( 1, #AttackTasks, "AI_A2A_INTERCEPT.InterceptRoute" )
        EngageRoute[1].task = AIGroup:TaskCombo( AttackTasks )
        
        --- Do a trick, link the NewEngageRoute function of the object to the AIControllable in a temporary variable ...
        AIGroup:SetState( AIGroup, "EngageZone", self )
      end
      
      --- NOW ROUTE THE GROUP!
      AIGroup:WayPointExecute( 1, 2 )
    
    end
  else
    self:E("No targets found -> Going RTB")
    self:__RTB( 1 )
  end
end

--- @param #AI_A2A_INTERCEPT self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_INTERCEPT:onafterAccomplish( AIGroup, From, Event, To )
  self.Accomplished = true
  self:SetDetectionOff()
end

--- @param #AI_A2A_INTERCEPT self
-- @param Wrapper.Group#GROUP AIGroup The AIGroup Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Event#EVENTDATA EventData
function AI_A2A_INTERCEPT:onafterDestroy( AIGroup, From, Event, To, EventData )

  if EventData.IniUnit then
    self.AttackUnits[EventData.IniUnit] = nil
  end
end

--- @param #AI_A2A_INTERCEPT self
-- @param Core.Event#EVENTDATA EventData
function AI_A2A_INTERCEPT:OnEventDead( EventData )
  self:F( { "EventDead", EventData } )

  if EventData.IniDCSUnit then
    if self.AttackUnits and self.AttackUnits[EventData.IniUnit] then
      self:__Destroy( 1, EventData )
    end
  end  
end
