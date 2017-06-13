--- **AI** -- **Execute Combat Air Patrol (CAP).**
--
-- ![Banner Image](..\Presentations\AI_CAP\Dia1.JPG)
-- 
-- ===
-- 
-- AI CAP classes makes AI Controllables execute a Combat Air Patrol.
-- 
-- There are the following types of CAP classes defined:
-- 
--   * @{#AI_A2A_CAP}: Perform a CAP in a zone.
--   
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
--
--   * **[Quax](https://forums.eagle.ru/member.php?u=90530)**: Concept, Advice & Testing.
--   * **[Pikey](https://forums.eagle.ru/member.php?u=62835)**: Concept, Advice & Testing.
--   * **[Gunterlund](http://forums.eagle.ru:8080/member.php?u=75036)**: Test case revision.
--   * **[Whisper](http://forums.eagle.ru/member.php?u=3829): Testing.
--   * **[Delta99](https://forums.eagle.ru/member.php?u=125166): Testing. 
-- 
-- ====       
--
-- @module AI_A2A_Cap

--BASE:TraceClass("AI_A2A_CAP")

--- @type AI_A2A_CAP
-- @extends AI.AI_A2A_Patrol#AI_A2A_PATROL


--- # AI_A2A_CAP class, extends @{AI_CAP#AI_PATROL_ZONE}
-- 
-- The AI_A2A_CAP class implements the core functions to patrol a @{Zone} by an AI @{Controllable} or @{Group} 
-- and automatically engage any airborne enemies that are within a certain range or within a certain zone.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia3.JPG)
-- 
-- The AI_A2A_CAP is assigned a @{Group} and this must be done before the AI_A2A_CAP process can be started using the **Start** event.
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
--   * **@{AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI_Patrol#AI_PATROL_ZONE.Route}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_A2A_CAP.Engage}**: Let the AI engage the bogeys.
--   * **@{#AI_A2A_CAP.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_A2A_CAP.Destroy}**: The AI has destroyed a bogey @{Unit}.
--   * **@{#AI_A2A_CAP.Destroyed}**: The AI has destroyed all bogeys @{Unit}s assigned in the CAS task.
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
-- Use the method @{AI_CAP#AI_A2A_CAP.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_CAP\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI_Cap#AI_A2A_CAP.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_A2A_CAP
AI_A2A_CAP = {
  ClassName = "AI_A2A_CAP",
}

--- Creates a new AI_A2A_CAP object
-- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AIGroup
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  EngageMinSpeed The minimum speed of the @{Controllable} in km/h when engaging a target.
-- @param Dcs.DCSTypes#Speed  EngageMaxSpeed The maximum speed of the @{Controllable} in km/h when engaging a target.
-- @param Dcs.DCSTypes#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_A2A_CAP
function AI_A2A_CAP:New( AIGroup, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2A_PATROL:New( AIGroup, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType ) ) -- #AI_A2A_CAP

  self.Accomplished = false
  self.Engaging = false
  
  self.EngageMinSpeed = EngageMinSpeed
  self.EngageMaxSpeed = EngageMaxSpeed
  
  self:AddTransition( { "Patrolling", "Engaging", "Returning" }, "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_CAP.

  --- OnBefore Transition Handler for Event Engage.
  -- @function [parent=#AI_A2A_CAP] OnBeforeEngage
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_A2A_CAP] OnAfterEngage
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
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
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_A2A_CAP] OnEnterEngaging
-- @param #AI_A2A_CAP self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A_CAP.
  
  --- OnBefore Transition Handler for Event Fired.
  -- @function [parent=#AI_A2A_CAP] OnBeforeFired
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fired.
  -- @function [parent=#AI_A2A_CAP] OnAfterFired
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
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
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2A_CAP] OnAfterDestroy
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
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
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Abort.
  -- @function [parent=#AI_A2A_CAP] OnAfterAbort
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
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
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2A_CAP] OnAfterAccomplish
  -- @param #AI_A2A_CAP self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
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
-- @param Wrapper.Controllable#CONTROLLABLE AIGroup The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onafterPatrol( AIGroup, From, Event, To )

  -- Call the parent Start event handler
  self:GetParent(self).onafterPatrol( self, AIGroup, From, Event, To )
  self:HandleEvent( EVENTS.Dead )

end

-- todo: need to fix this global function

--- @param Wrapper.Group#GROUP AIGroup
function AI_A2A_CAP.AttackRoute( AIGroup )

  local EngageZone = AIGroup:GetState( AIGroup, "AI_A2A_CAP" ) -- AI.AI_Cap#AI_A2A_CAP
  EngageZone:__Engage( 0.5 )
end

--- @param #AI_A2A_CAP self
-- @param Wrapper.Controllable#CONTROLLABLE AIGroup The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onbeforeEngage( AIGroup, From, Event, To )
  
  if self.Accomplished == true then
    return false
  end
end

--- @param #AI_A2A_CAP self
-- @param Wrapper.Controllable#CONTROLLABLE AIGroup The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onafterAbort( AIGroup, From, Event, To )
  AIGroup:ClearTasks()
  self:__Route( 0.5 )
end


--- @param #AI_A2A_CAP self
-- @param Wrapper.Controllable#CONTROLLABLE AIGroup The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onafterEngage( AIGroup, From, Event, To, AttackSetUnit )

  self:F( { AIGroup, From, Event, To, AttackSetUnit} )

  self.AttackSetUnit = AttackSetUnit or self.AttackSetUnit -- Core.Set#SET_UNIT
  
  local FirstAttackUnit = self.AttackSetUnit:GetFirst()
  
  if FirstAttackUnit then
  
    if AIGroup:IsAlive() then

      local EngageRoute = {}

      --- Calculate the target route point.
      local CurrentCoord = AIGroup:GetCoordinate()
      local ToTargetCoord = self.AttackSetUnit:GetFirst():GetCoordinate()
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
      self:T2( { self.MinSpeed, self.MaxSpeed, ToTargetSpeed } )
      
      EngageRoute[#EngageRoute+1] = ToPatrolRoutePoint

      AIGroup:OptionROEOpenFire()
      AIGroup:OptionROTPassiveDefense()
  
      local AttackTasks = {}
  
      for AttackUnitID, AttackUnit in pairs( self.AttackSetUnit:GetSet() ) do
        local AttackUnit = AttackUnit -- Wrapper.Unit#UNIT
        self:T( { "Attacking Unit:", AttackUnit:GetName(), AttackUnit:IsAlive(), AttackUnit:IsAir() } )
        if AttackUnit:IsAlive() and AttackUnit:IsAir() then
          AttackTasks[#AttackTasks+1] = AIGroup:TaskAttackUnit( AttackUnit )
        end
      end
  
      --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
      self.Controllable:WayPointInitialize( EngageRoute )
      
      
      if #AttackTasks == 0 then
        self:E("No targets found -> Going back to Patrolling")
        self:__Abort( 0.5 )
      else
        AttackTasks[#AttackTasks+1] = AIGroup:TaskFunction( 1, #AttackTasks, "AI_A2A_CAP.AttackRoute" )
        AttackTasks[#AttackTasks+1] = AIGroup:TaskOrbitCircle( 4000, self.PatrolMinSpeed )
        
        EngageRoute[1].task = AIGroup:TaskCombo( AttackTasks )
        
        --- Do a trick, link the NewEngageRoute function of the object to the AIControllable in a temporary variable ...
        AIGroup:SetState( AIGroup, "AI_A2A_CAP", self )
      end
      
      --- NOW ROUTE THE GROUP!
      AIGroup:WayPointExecute( 1, 0 )
    end
  else
    self:E("No targets found -> Going back to Patrolling")
    self:__Abort( 0.5 )
  end
end

--- @param #AI_A2A_CAP self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onafterAccomplish( Controllable, From, Event, To )
  self.Accomplished = true
  self:SetDetectionOff()
end

--- @param #AI_A2A_CAP self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Event#EVENTDATA EventData
function AI_A2A_CAP:onafterDestroy( Controllable, From, Event, To, EventData )

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
