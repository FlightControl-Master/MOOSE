--- **AI** -- Models the process of air to ground engagement for airplanes and helicopters.
--
-- This is a class used in the @{AI_A2G_Dispatcher}.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_A2G_Engage
-- @image AI_Air_To_Ground_Engage.JPG



--- @type AI_A2G_ENGAGE
-- @extends AI.AI_A2G#AI_A2G


--- Implements the core functions to intercept intruders. Use the Engage trigger to intercept intruders.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia3.JPG)
-- 
-- The AI_A2G_ENGAGE is assigned a @{Wrapper.Group} and this must be done before the AI_A2G_ENGAGE process can be started using the **Start** event.
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
-- ## 1. AI_A2G_ENGAGE constructor
--   
--   * @{#AI_A2G_ENGAGE.New}(): Creates a new AI_A2G_ENGAGE object.
--
-- ## 3. Set the Range of Engagement
-- 
-- ![Range](..\Presentations\AI_GCI\Dia11.JPG)
-- 
-- An optional range can be set in meters, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- The range can be beyond or smaller than the range of the Patrol Zone.
-- The range is applied at the position of the AI.
-- Use the method @{AI.AI_GCI#AI_A2G_ENGAGE.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_GCI\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_A2G_ENGAGE.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_A2G_ENGAGE
AI_A2G_ENGAGE = {
  ClassName = "AI_A2G_ENGAGE",
}



--- Creates a new AI_A2G_ENGAGE object
-- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup
-- @param DCS#Speed EngageMinSpeed (optional, default = 50% of max speed) The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
-- @return #AI_A2G_ENGAGE
function AI_A2G_ENGAGE:New( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2G:New( AIGroup ) ) -- #AI_A2G_ENGAGE

  self.Accomplished = false
  self.Engaging = false
  
  local SpeedMax = AIGroup:GetSpeedMax()
  
  self.EngageMinSpeed = EngageMinSpeed or SpeedMax * 0.5
  self.EngageMaxSpeed = EngageMaxSpeed or SpeedMax * 0.75
  self.EngageFloorAltitude = EngageFloorAltitude or 1000
  self.EngageCeilingAltitude = EngageCeilingAltitude or 1500
  
  self:AddTransition( { "Started", "Engaging", "Returning", "Airborne", "Patrolling" }, "EngageRoute", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_ENGAGE.

  --- OnBefore Transition Handler for Event EngageRoute.
  -- @function [parent=#AI_A2G_ENGAGE] OnBeforeEngageRoute
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event EngageRoute.
  -- @function [parent=#AI_A2G_ENGAGE] OnAfterEngageRoute
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event EngageRoute.
  -- @function [parent=#AI_A2G_ENGAGE] EngageRoute
  -- @param #AI_A2G_ENGAGE self
  
  --- Asynchronous Event Trigger for Event EngageRoute.
  -- @function [parent=#AI_A2G_ENGAGE] __EngageRoute
  -- @param #AI_A2G_ENGAGE self
  -- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Engaging.
-- @function [parent=#AI_A2G_ENGAGE] OnLeaveEngaging
-- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_A2G_ENGAGE] OnEnterEngaging
-- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( { "Started", "Engaging", "Returning", "Airborne", "Patrolling" }, "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_ENGAGE.

  --- OnBefore Transition Handler for Event Engage.
  -- @function [parent=#AI_A2G_ENGAGE] OnBeforeEngage
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_A2G_ENGAGE] OnAfterEngage
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
    
  --- Synchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_A2G_ENGAGE] Engage
  -- @param #AI_A2G_ENGAGE self
  
  --- Asynchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_A2G_ENGAGE] __Engage
  -- @param #AI_A2G_ENGAGE self
  -- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Engaging.
-- @function [parent=#AI_A2G_ENGAGE] OnLeaveEngaging
-- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_A2G_ENGAGE] OnEnterEngaging
-- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_ENGAGE.
  
  --- OnBefore Transition Handler for Event Fired.
  -- @function [parent=#AI_A2G_ENGAGE] OnBeforeFired
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fired.
  -- @function [parent=#AI_A2G_ENGAGE] OnAfterFired
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_A2G_ENGAGE] Fired
  -- @param #AI_A2G_ENGAGE self
  
  --- Asynchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_A2G_ENGAGE] __Fired
  -- @param #AI_A2G_ENGAGE self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Destroy", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_ENGAGE.

  --- OnBefore Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2G_ENGAGE] OnBeforeDestroy
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Destroy.
  -- @function [parent=#AI_A2G_ENGAGE] OnAfterDestroy
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_A2G_ENGAGE] Destroy
  -- @param #AI_A2G_ENGAGE self
  
  --- Asynchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_A2G_ENGAGE] __Destroy
  -- @param #AI_A2G_ENGAGE self
  -- @param #number Delay The delay in seconds.


  self:AddTransition( "Engaging", "Abort", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_ENGAGE.

  --- OnBefore Transition Handler for Event Abort.
  -- @function [parent=#AI_A2G_ENGAGE] OnBeforeAbort
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Abort.
  -- @function [parent=#AI_A2G_ENGAGE] OnAfterAbort
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_A2G_ENGAGE] Abort
  -- @param #AI_A2G_ENGAGE self
  
  --- Asynchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_A2G_ENGAGE] __Abort
  -- @param #AI_A2G_ENGAGE self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "Engaging", "Accomplish", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_A2G_ENGAGE.

  --- OnBefore Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2G_ENGAGE] OnBeforeAccomplish
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Accomplish.
  -- @function [parent=#AI_A2G_ENGAGE] OnAfterAccomplish
  -- @param #AI_A2G_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_A2G_ENGAGE] Accomplish
  -- @param #AI_A2G_ENGAGE self
  
  --- Asynchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_A2G_ENGAGE] __Accomplish
  -- @param #AI_A2G_ENGAGE self
  -- @param #number Delay The delay in seconds.  

  return self
end

--- onafter event handler for Start event.
-- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The AI group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_ENGAGE:onafterStart( AIGroup, From, Event, To )

  self:GetParent( self, AI_A2G_ENGAGE ).onafterStart( self, AIGroup, From, Event, To )

  AIGroup:HandleEvent( EVENTS.Takeoff, nil, self )

end



--- onafter event handler for Engage event.
-- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_ENGAGE:onafterEngage( AIGroup, From, Event, To )

  self:HandleEvent( EVENTS.Dead )

end

-- todo: need to fix this global function

--- @param Wrapper.Group#GROUP AIControllable
function AI_A2G_ENGAGE.___EngageRoute( AIGroup, Fsm, AttackSetUnit )

  AIGroup:I( { "AI_A2G_ENGAGE.___EngageRoute:", AIGroup:GetName() } )
  
  if AIGroup:IsAlive() then
    Fsm:__EngageRoute( Fsm.TaskDelay, AttackSetUnit )
  
    --local Task = AIGroup:TaskOrbitCircle( 4000, 400 )
    --AIGroup:SetTask( Task )
  end
end

--- @param Wrapper.Group#GROUP AIControllable
function AI_A2G_ENGAGE.___Engage( AIGroup, Fsm, AttackSetUnit )

  AIGroup:I( { "AI_A2G_ENGAGE.___Engage:", AIGroup:GetName() } )
  
  if AIGroup:IsAlive() then
    Fsm:__Engage( Fsm.TaskDelay, AttackSetUnit )
  
    --local Task = AIGroup:TaskOrbitCircle( 4000, 400 )
    --AIGroup:SetTask( Task )
  end
end

--- onbefore event handler for Engage event.
-- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_ENGAGE:onbeforeEngage( AIGroup, From, Event, To )
  
  if self.Accomplished == true then
    return false
  end
end

--- onafter event handler for Abort event.
-- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_ENGAGE:onafterAbort( AIGroup, From, Event, To )
  AIGroup:ClearTasks()
  self:Return()
  self:__RTB( self.TaskDelay )
end


--- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP DefenderGroup The GroupGroup managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_ENGAGE:onafterEngageRoute( DefenderGroup, From, Event, To, AttackSetUnit )

  self:F( { DefenderGroup, From, Event, To, AttackSetUnit} )
  
end

--- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_ENGAGE:onafterAccomplish( AIGroup, From, Event, To )
  self.Accomplished = true
  self:SetDetectionOff()
end

--- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Event#EVENTDATA EventData
function AI_A2G_ENGAGE:onafterDestroy( AIGroup, From, Event, To, EventData )

  if EventData.IniUnit then
    self.AttackUnits[EventData.IniUnit] = nil
  end
end

--- @param #AI_A2G_ENGAGE self
-- @param Core.Event#EVENTDATA EventData
function AI_A2G_ENGAGE:OnEventDead( EventData )
  self:F( { "EventDead", EventData } )

  if EventData.IniDCSUnit then
    if self.AttackUnits and self.AttackUnits[EventData.IniUnit] then
      self:__Destroy( self.TaskDelay, EventData )
    end
  end  
end

--- @param #AI_A2G_ENGAGE self
-- @param Wrapper.Group#GROUP DefenderGroup The GroupGroup managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_ENGAGE:onafterEngageRoute( DefenderGroup, From, Event, To, AttackSetUnit )

  self:F( { DefenderGroup, From, Event, To, AttackSetUnit} )
  
  local DefenderGroupName = DefenderGroup:GetName()

  local AttackCount = AttackSetUnit:Count()
  
  if AttackCount > 0 then

    if DefenderGroup:IsAlive() then

      local EngageAltitude = math.random( self.EngageFloorAltitude, self.EngageCeilingAltitude )
      local EngageSpeed = math.random( self.EngageMinSpeed, self.EngageMaxSpeed )

      -- Determine the distance to the target.
      -- If it is less than 10km, then attack without a route.
      -- Otherwise perform a route attack.

      local DefenderCoord = DefenderGroup:GetPointVec3()
      DefenderCoord:SetY( EngageAltitude ) -- Ground targets don't have an altitude.

      local TargetCoord = AttackSetUnit:GetFirst():GetPointVec3()
      TargetCoord:SetY( EngageAltitude ) -- Ground targets don't have an altitude.
      
      local TargetDistance = DefenderCoord:Get2DDistance( TargetCoord )
      local EngageDistance = ( DefenderGroup:IsHelicopter() and 5000 ) or ( DefenderGroup:IsAirPlane() and 10000 ) 
      
      if TargetDistance <= EngageDistance * 3 then

        self:__Engage( 0.1, AttackSetUnit )

      else

        local EngageRoute = {}
        local AttackTasks = {}
        
        --- Calculate the target route point.
        
        local FromWP = DefenderCoord:WaypointAir( 
          self.PatrolAltType or "RADIO", 
          POINT_VEC3.RoutePointType.TurningPoint, 
          POINT_VEC3.RoutePointAction.TurningPoint, 
          EngageSpeed, 
          true 
        )
        
        EngageRoute[#EngageRoute+1] = FromWP
  
        self:SetTargetDistance( TargetCoord ) -- For RTB status check
        
        local FromEngageAngle = DefenderCoord:GetAngleDegrees( DefenderCoord:GetDirectionVec3( TargetCoord ) )
        local ToWP = DefenderCoord:Translate( EngageDistance, FromEngageAngle, true ):WaypointAir( 
          self.PatrolAltType or "RADIO", 
          POINT_VEC3.RoutePointType.TurningPoint, 
          POINT_VEC3.RoutePointAction.TurningPoint, 
          EngageSpeed, 
          true 
        )
  
        EngageRoute[#EngageRoute+1] = ToWP

        AttackTasks[#AttackTasks+1] = DefenderGroup:TaskFunction( "AI_A2G_ENGAGE.___EngageRoute", self, AttackSetUnit )
        EngageRoute[#EngageRoute].task = DefenderGroup:TaskCombo( AttackTasks )
        
        DefenderGroup:OptionROEReturnFire()
        DefenderGroup:OptionROTEvadeFire()
        
        DefenderGroup:Route( EngageRoute, self.TaskDelay )
      end

    end
  else
    self:E( DefenderGroupName .. ": No targets found -> Going RTB")
    self:Return()
    self:__RTB( self.TaskDelay )
  end
end