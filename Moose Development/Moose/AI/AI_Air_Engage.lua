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
-- @module AI.AI_Air_Engage
-- @image AI_Air_To_Ground_Engage.JPG



--- @type AI_AIR_ENGAGE
-- @extends AI.AI_AIR#AI_AIR


--- Implements the core functions to intercept intruders. Use the Engage trigger to intercept intruders.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia3.JPG)
-- 
-- The AI_AIR_ENGAGE is assigned a @{Wrapper.Group} and this must be done before the AI_AIR_ENGAGE process can be started using the **Start** event.
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
-- ## 1. AI_AIR_ENGAGE constructor
--   
--   * @{#AI_AIR_ENGAGE.New}(): Creates a new AI_AIR_ENGAGE object.
--
-- ## 3. Set the Range of Engagement
-- 
-- ![Range](..\Presentations\AI_GCI\Dia11.JPG)
-- 
-- An optional range can be set in meters, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- The range can be beyond or smaller than the range of the Patrol Zone.
-- The range is applied at the position of the AI.
-- Use the method @{AI.AI_GCI#AI_AIR_ENGAGE.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_GCI\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_AIR_ENGAGE.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_AIR_ENGAGE
AI_AIR_ENGAGE = {
  ClassName = "AI_AIR_ENGAGE",
}



--- Creates a new AI_AIR_ENGAGE object
-- @param #AI_AIR_ENGAGE self
-- @param AI.AI_Air#AI_AIR AI_Air The AI_AIR FSM.
-- @param Wrapper.Group#GROUP AIGroup The AI group.
-- @param DCS#Speed EngageMinSpeed (optional, default = 50% of max speed) The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
-- @param DCS#AltitudeType EngageAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to "RADIO".
-- @return #AI_AIR_ENGAGE
function AI_AIR_ENGAGE:New( AI_Air, AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_Air ) -- #AI_AIR_ENGAGE

  self.Accomplished = false
  self.Engaging = false
  
  local SpeedMax = AIGroup:GetSpeedMax()
  
  self.EngageMinSpeed = EngageMinSpeed or SpeedMax * 0.5
  self.EngageMaxSpeed = EngageMaxSpeed or SpeedMax * 0.75
  self.EngageFloorAltitude = EngageFloorAltitude or 1000
  self.EngageCeilingAltitude = EngageCeilingAltitude or 1500
  self.EngageAltType = EngageAltType or "RADIO"
  
  self:AddTransition( { "Started", "Engaging", "Returning", "Airborne", "Patrolling" }, "EngageRoute", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_AIR_ENGAGE.

  --- OnBefore Transition Handler for Event EngageRoute.
  -- @function [parent=#AI_AIR_ENGAGE] OnBeforeEngageRoute
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event EngageRoute.
  -- @function [parent=#AI_AIR_ENGAGE] OnAfterEngageRoute
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event EngageRoute.
  -- @function [parent=#AI_AIR_ENGAGE] EngageRoute
  -- @param #AI_AIR_ENGAGE self
  
  --- Asynchronous Event Trigger for Event EngageRoute.
  -- @function [parent=#AI_AIR_ENGAGE] __EngageRoute
  -- @param #AI_AIR_ENGAGE self
  -- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Engaging.
-- @function [parent=#AI_AIR_ENGAGE] OnLeaveEngaging
-- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_AIR_ENGAGE] OnEnterEngaging
-- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( { "Started", "Engaging", "Returning", "Airborne", "Patrolling" }, "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_AIR_ENGAGE.

  --- OnBefore Transition Handler for Event Engage.
  -- @function [parent=#AI_AIR_ENGAGE] OnBeforeEngage
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_AIR_ENGAGE] OnAfterEngage
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
    
  --- Synchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_AIR_ENGAGE] Engage
  -- @param #AI_AIR_ENGAGE self
  
  --- Asynchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_AIR_ENGAGE] __Engage
  -- @param #AI_AIR_ENGAGE self
  -- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Engaging.
-- @function [parent=#AI_AIR_ENGAGE] OnLeaveEngaging
-- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_AIR_ENGAGE] OnEnterEngaging
-- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_AIR_ENGAGE.
  
  --- OnBefore Transition Handler for Event Fired.
  -- @function [parent=#AI_AIR_ENGAGE] OnBeforeFired
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fired.
  -- @function [parent=#AI_AIR_ENGAGE] OnAfterFired
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_AIR_ENGAGE] Fired
  -- @param #AI_AIR_ENGAGE self
  
  --- Asynchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_AIR_ENGAGE] __Fired
  -- @param #AI_AIR_ENGAGE self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Destroy", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_AIR_ENGAGE.

  --- OnBefore Transition Handler for Event Destroy.
  -- @function [parent=#AI_AIR_ENGAGE] OnBeforeDestroy
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Destroy.
  -- @function [parent=#AI_AIR_ENGAGE] OnAfterDestroy
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_AIR_ENGAGE] Destroy
  -- @param #AI_AIR_ENGAGE self
  
  --- Asynchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_AIR_ENGAGE] __Destroy
  -- @param #AI_AIR_ENGAGE self
  -- @param #number Delay The delay in seconds.


  self:AddTransition( "Engaging", "Abort", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_AIR_ENGAGE.

  --- OnBefore Transition Handler for Event Abort.
  -- @function [parent=#AI_AIR_ENGAGE] OnBeforeAbort
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Abort.
  -- @function [parent=#AI_AIR_ENGAGE] OnAfterAbort
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_AIR_ENGAGE] Abort
  -- @param #AI_AIR_ENGAGE self
  
  --- Asynchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_AIR_ENGAGE] __Abort
  -- @param #AI_AIR_ENGAGE self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "Engaging", "Accomplish", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_AIR_ENGAGE.

  --- OnBefore Transition Handler for Event Accomplish.
  -- @function [parent=#AI_AIR_ENGAGE] OnBeforeAccomplish
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Accomplish.
  -- @function [parent=#AI_AIR_ENGAGE] OnAfterAccomplish
  -- @param #AI_AIR_ENGAGE self
  -- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_AIR_ENGAGE] Accomplish
  -- @param #AI_AIR_ENGAGE self
  
  --- Asynchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_AIR_ENGAGE] __Accomplish
  -- @param #AI_AIR_ENGAGE self
  -- @param #number Delay The delay in seconds.  

  self:AddTransition( { "Patrolling", "Engaging" }, "Refuel", "Refuelling" ) 

  return self
end

--- onafter event handler for Start event.
-- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The AI group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_AIR_ENGAGE:onafterStart( AIGroup, From, Event, To )

  self:GetParent( self, AI_AIR_ENGAGE ).onafterStart( self, AIGroup, From, Event, To )

  AIGroup:HandleEvent( EVENTS.Takeoff, nil, self )

end



--- onafter event handler for Engage event.
-- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_AIR_ENGAGE:onafterEngage( AIGroup, From, Event, To )
  -- TODO: This function is overwritten below!
  self:HandleEvent( EVENTS.Dead )
end

-- todo: need to fix this global function


--- onbefore event handler for Engage event.
-- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_AIR_ENGAGE:onbeforeEngage( AIGroup, From, Event, To )
  if self.Accomplished == true then
    return false
  end  
  return true
end

--- onafter event handler for Abort event.
-- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_AIR_ENGAGE:onafterAbort( AIGroup, From, Event, To )
  AIGroup:ClearTasks()
  self:Return()
end


--- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_AIR_ENGAGE:onafterAccomplish( AIGroup, From, Event, To )
  self.Accomplished = true
  --self:SetDetectionOff()
end

--- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP AIGroup The Group Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Event#EVENTDATA EventData
function AI_AIR_ENGAGE:onafterDestroy( AIGroup, From, Event, To, EventData )

  if EventData.IniUnit then
    self.AttackUnits[EventData.IniUnit] = nil
  end
end

--- @param #AI_AIR_ENGAGE self
-- @param Core.Event#EVENTDATA EventData
function AI_AIR_ENGAGE:OnEventDead( EventData )
  self:F( { "EventDead", EventData } )

  if EventData.IniDCSUnit then
    if self.AttackUnits and self.AttackUnits[EventData.IniUnit] then
      self:__Destroy( self.TaskDelay, EventData )
    end
  end  
end


--- @param Wrapper.Group#GROUP AIControllable
function AI_AIR_ENGAGE.___EngageRoute( AIGroup, Fsm, AttackSetUnit )
  Fsm:I(string.format("AI_AIR_ENGAGE.___EngageRoute: %s", tostring(AIGroup:GetName())))
  
  if AIGroup and AIGroup:IsAlive() then
    Fsm:__EngageRoute( Fsm.TaskDelay or 0.1, AttackSetUnit )
  end
end


--- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP DefenderGroup The GroupGroup managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Set#SET_UNIT AttackSetUnit Unit set to be attacked.
function AI_AIR_ENGAGE:onafterEngageRoute( DefenderGroup, From, Event, To, AttackSetUnit )
  self:I( { DefenderGroup, From, Event, To, AttackSetUnit } )
  
  local DefenderGroupName = DefenderGroup:GetName()

  self.AttackSetUnit = AttackSetUnit -- Kept in memory in case of resume from refuel in air!

  local AttackCount = AttackSetUnit:CountAlive()
  
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
      
      -- TODO: A factor of * 3 is way too close. This causes the AI not to engange until merged sometimes!
      if TargetDistance <= EngageDistance * 9 then

        self:I(string.format("AI_AIR_ENGAGE onafterEngageRoute ==> __Engage - target distance = %.1f km", TargetDistance/1000))
        self:__Engage( 0.1, AttackSetUnit )

      else
      
        self:I(string.format("FF AI_AIR_ENGAGE onafterEngageRoute ==> Routing - target distance = %.1f km", TargetDistance/1000))

        local EngageRoute = {}
        local AttackTasks = {}
        
        --- Calculate the target route point.
        
        local FromWP = DefenderCoord:WaypointAir(self.PatrolAltType or "RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, EngageSpeed, true)
        
        EngageRoute[#EngageRoute+1] = FromWP
  
        self:SetTargetDistance( TargetCoord ) -- For RTB status check
        
        local FromEngageAngle = DefenderCoord:GetAngleDegrees( DefenderCoord:GetDirectionVec3( TargetCoord ) )
        local ToCoord=DefenderCoord:Translate( EngageDistance, FromEngageAngle, true )
        
        local ToWP = ToCoord:WaypointAir(self.PatrolAltType or "RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, EngageSpeed, true)
  
        EngageRoute[#EngageRoute+1] = ToWP

        AttackTasks[#AttackTasks+1] = DefenderGroup:TaskFunction( "AI_AIR_ENGAGE.___EngageRoute", self, AttackSetUnit )
        EngageRoute[#EngageRoute].task = DefenderGroup:TaskCombo( AttackTasks )
        
        DefenderGroup:OptionROEReturnFire()
        DefenderGroup:OptionROTEvadeFire()
        
        DefenderGroup:Route( EngageRoute, self.TaskDelay or 0.1 )
      end

    end
  else
    -- TODO: This will make an A2A Dispatcher CAP flight to return rather than going back to patrolling!
    self:I( DefenderGroupName .. ": No targets found -> Going RTB")
    self:Return()
  end
end


--- @param Wrapper.Group#GROUP AIControllable
function AI_AIR_ENGAGE.___Engage( AIGroup, Fsm, AttackSetUnit )

  Fsm:I(string.format("AI_AIR_ENGAGE.___Engage: %s", tostring(AIGroup:GetName())))
  
  if AIGroup and AIGroup:IsAlive() then
    local delay=Fsm.TaskDelay or 0.1
    Fsm:__Engage(delay, AttackSetUnit)
  end
end


--- @param #AI_AIR_ENGAGE self
-- @param Wrapper.Group#GROUP DefenderGroup The GroupGroup managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Set#SET_UNIT AttackSetUnit Set of units to be attacked.
function AI_AIR_ENGAGE:onafterEngage( DefenderGroup, From, Event, To, AttackSetUnit )
  self:F( { DefenderGroup, From, Event, To, AttackSetUnit} )
  
  local DefenderGroupName = DefenderGroup:GetName()

  self.AttackSetUnit = AttackSetUnit -- Kept in memory in case of resume from refuel in air!

  local AttackCount = AttackSetUnit:CountAlive()
  self:T({AttackCount = AttackCount})
  
  if AttackCount > 0 then

    if DefenderGroup and DefenderGroup:IsAlive() then

      local EngageAltitude = math.random( self.EngageFloorAltitude or 500, self.EngageCeilingAltitude or 1000 )
      local EngageSpeed = math.random( self.EngageMinSpeed, self.EngageMaxSpeed )

      local DefenderCoord = DefenderGroup:GetPointVec3()
      DefenderCoord:SetY( EngageAltitude ) -- Ground targets don't have an altitude.

      local TargetCoord = AttackSetUnit:GetFirst():GetPointVec3()
      TargetCoord:SetY( EngageAltitude ) -- Ground targets don't have an altitude.
      
      local TargetDistance = DefenderCoord:Get2DDistance( TargetCoord )
      
      local EngageDistance = ( DefenderGroup:IsHelicopter() and 5000 ) or ( DefenderGroup:IsAirPlane() and 10000 )
      
      local EngageRoute = {}
      local AttackTasks = {}
      
      local FromWP = DefenderCoord:WaypointAir(self.EngageAltType or "RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, EngageSpeed, true)
      EngageRoute[#EngageRoute+1] = FromWP

      self:SetTargetDistance( TargetCoord ) -- For RTB status check

      local FromEngageAngle = DefenderCoord:GetAngleDegrees( DefenderCoord:GetDirectionVec3( TargetCoord ) )
      local ToCoord=DefenderCoord:Translate( EngageDistance, FromEngageAngle, true )
      
      local ToWP = ToCoord:WaypointAir(self.EngageAltType or "RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, EngageSpeed, true)
      EngageRoute[#EngageRoute+1] = ToWP
      
      -- TODO: A factor of * 3 this way too low. This causes the AI NOT to engage until very close or even merged sometimes. Some A2A missiles have a much longer range! Needs more frequent updates of the task!
      if TargetDistance <= EngageDistance * 9 then
      
        local AttackUnitTasks = self:CreateAttackUnitTasks( AttackSetUnit, DefenderGroup, EngageAltitude ) -- Polymorphic
        
        if #AttackUnitTasks == 0 then
          self:I( DefenderGroupName .. ": No valid targets found -> Going RTB")
          self:Return()
          return
        else
          local text=string.format("%s: Engaging targets at distance %.2f NM", DefenderGroupName, UTILS.MetersToNM(TargetDistance))
          self:I(text)
          DefenderGroup:OptionROEOpenFire()
          DefenderGroup:OptionROTEvadeFire()
          DefenderGroup:OptionKeepWeaponsOnThreat()
  
          AttackTasks[#AttackTasks+1] = DefenderGroup:TaskCombo( AttackUnitTasks )
        end
      end

      AttackTasks[#AttackTasks+1] = DefenderGroup:TaskFunction( "AI_AIR_ENGAGE.___Engage", self, AttackSetUnit )
      EngageRoute[#EngageRoute].task = DefenderGroup:TaskCombo( AttackTasks )
      
      DefenderGroup:Route( EngageRoute, self.TaskDelay or 0.1 )
      
    end
  else
    -- TODO: This will make an A2A Dispatcher CAP flight to return rather than going back to patrolling!
    self:I( DefenderGroupName .. ": No targets found -> returning.")
    self:Return()
    return
  end
end

--- @param Wrapper.Group#GROUP AIEngage
function AI_AIR_ENGAGE.Resume( AIEngage, Fsm )

  AIEngage:F( { "Resume:", AIEngage:GetName() } )
  if AIEngage and AIEngage:IsAlive() then
    Fsm:__Reset( Fsm.TaskDelay or 0.1 )
    Fsm:__EngageRoute( Fsm.TaskDelay or 0.2, Fsm.AttackSetUnit )
  end
  
end
