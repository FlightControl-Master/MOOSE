--- **AI** -- Perform Combat Air Patrolling (CAP) for airplanes.
--
-- **Features:**
-- 
--   * Patrol AI airplanes within a given zone.
--   * Trigger detected events when enemy airplanes are detected.
--   * Manage a fuel treshold to RTB on time.
--   * Engage the enemy when detected.
-- 
--
-- ===
-- 
-- ### [Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release/CAP%20-%20Combat%20Air%20Patrol)
-- 
-- ===
-- 
-- ### [YouTube Playlist](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl1YCyPxJgoZn-CfhwyeW65L)
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: 
--
--   * **[Quax](https://forums.eagle.ru/member.php?u=90530)**: Concept, Advice & Testing.
--   * **[Pikey](https://forums.eagle.ru/member.php?u=62835)**: Concept, Advice & Testing.
--   * **[Gunterlund](http://forums.eagle.ru:8080/member.php?u=75036)**: Test case revision.
--   * **[Whisper](http://forums.eagle.ru/member.php?u=3829): Testing.
--   * **[Delta99](https://forums.eagle.ru/member.php?u=125166): Testing. 
-- 
-- ===       
--
-- @module AI.AI_Cap
-- @image AI_Combat_Air_Patrol.JPG


--- @type AI_CAP_ZONE
-- @field Wrapper.Controllable#CONTROLLABLE AIControllable The @{Wrapper.Controllable} patrolling.
-- @field Core.Zone#ZONE_BASE TargetZone The @{Zone} where the patrol needs to be executed.
-- @extends AI.AI_Patrol#AI_PATROL_ZONE


--- Implements the core functions to patrol a @{Zone} by an AI @{Wrapper.Controllable} or @{Wrapper.Group} 
-- and automatically engage any airborne enemies that are within a certain range or within a certain zone.
-- 
-- ![Process](..\Presentations\AI_CAP\Dia3.JPG)
-- 
-- The AI_CAP_ZONE is assigned a @{Wrapper.Group} and this must be done before the AI_CAP_ZONE process can be started using the **Start** event.
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
-- ## 1. AI_CAP_ZONE constructor
--   
--   * @{#AI_CAP_ZONE.New}(): Creates a new AI_CAP_ZONE object.
-- 
-- ## 2. AI_CAP_ZONE is a FSM
-- 
-- ![Process](..\Presentations\AI_CAP\Dia2.JPG)
-- 
-- ### 2.1 AI_CAP_ZONE States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Engaging** ( Group ): The AI is engaging the bogeys.
--   * **Returning** ( Group ): The AI is returning to Base..
-- 
-- ### 2.2 AI_CAP_ZONE Events
-- 
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Route}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_CAP_ZONE.Engage}**: Let the AI engage the bogeys.
--   * **@{#AI_CAP_ZONE.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_CAP_ZONE.Destroy}**: The AI has destroyed a bogey @{Wrapper.Unit}.
--   * **@{#AI_CAP_ZONE.Destroyed}**: The AI has destroyed all bogeys @{Wrapper.Unit}s assigned in the CAS task.
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
-- Use the method @{AI.AI_CAP#AI_CAP_ZONE.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_CAP\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_CAP_ZONE.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_CAP_ZONE
AI_CAP_ZONE = {
  ClassName = "AI_CAP_ZONE",
}



--- Creates a new AI_CAP_ZONE object
-- @param #AI_CAP_ZONE self
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Controllable} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Controllable} in km/h.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_CAP_ZONE self
function AI_CAP_ZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_PATROL_ZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType ) ) -- #AI_CAP_ZONE

  self.Accomplished = false
  self.Engaging = false
  
  self:AddTransition( { "Patrolling", "Engaging" }, "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_CAP_ZONE.

  --- OnBefore Transition Handler for Event Engage.
  -- @function [parent=#AI_CAP_ZONE] OnBeforeEngage
  -- @param #AI_CAP_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_CAP_ZONE] OnAfterEngage
  -- @param #AI_CAP_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_CAP_ZONE] Engage
  -- @param #AI_CAP_ZONE self
  
  --- Asynchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_CAP_ZONE] __Engage
  -- @param #AI_CAP_ZONE self
  -- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Engaging.
-- @function [parent=#AI_CAP_ZONE] OnLeaveEngaging
-- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_CAP_ZONE] OnEnterEngaging
-- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_CAP_ZONE.
  
  --- OnBefore Transition Handler for Event Fired.
  -- @function [parent=#AI_CAP_ZONE] OnBeforeFired
  -- @param #AI_CAP_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fired.
  -- @function [parent=#AI_CAP_ZONE] OnAfterFired
  -- @param #AI_CAP_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_CAP_ZONE] Fired
  -- @param #AI_CAP_ZONE self
  
  --- Asynchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_CAP_ZONE] __Fired
  -- @param #AI_CAP_ZONE self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Destroy", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_CAP_ZONE.

  --- OnBefore Transition Handler for Event Destroy.
  -- @function [parent=#AI_CAP_ZONE] OnBeforeDestroy
  -- @param #AI_CAP_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Destroy.
  -- @function [parent=#AI_CAP_ZONE] OnAfterDestroy
  -- @param #AI_CAP_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_CAP_ZONE] Destroy
  -- @param #AI_CAP_ZONE self
  
  --- Asynchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_CAP_ZONE] __Destroy
  -- @param #AI_CAP_ZONE self
  -- @param #number Delay The delay in seconds.


  self:AddTransition( "Engaging", "Abort", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_CAP_ZONE.

  --- OnBefore Transition Handler for Event Abort.
  -- @function [parent=#AI_CAP_ZONE] OnBeforeAbort
  -- @param #AI_CAP_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Abort.
  -- @function [parent=#AI_CAP_ZONE] OnAfterAbort
  -- @param #AI_CAP_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_CAP_ZONE] Abort
  -- @param #AI_CAP_ZONE self
  
  --- Asynchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_CAP_ZONE] __Abort
  -- @param #AI_CAP_ZONE self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "Engaging", "Accomplish", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_CAP_ZONE.

  --- OnBefore Transition Handler for Event Accomplish.
  -- @function [parent=#AI_CAP_ZONE] OnBeforeAccomplish
  -- @param #AI_CAP_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Accomplish.
  -- @function [parent=#AI_CAP_ZONE] OnAfterAccomplish
  -- @param #AI_CAP_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_CAP_ZONE] Accomplish
  -- @param #AI_CAP_ZONE self
  
  --- Asynchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_CAP_ZONE] __Accomplish
  -- @param #AI_CAP_ZONE self
  -- @param #number Delay The delay in seconds.  

  return self
end


--- Set the Engage Zone which defines where the AI will engage bogies. 
-- @param #AI_CAP_ZONE self
-- @param Core.Zone#ZONE EngageZone The zone where the AI is performing CAP.
-- @return #AI_CAP_ZONE self
function AI_CAP_ZONE:SetEngageZone( EngageZone )
  self:F2()

  if EngageZone then  
    self.EngageZone = EngageZone
  else
    self.EngageZone = nil
  end
end

--- Set the Engage Range when the AI will engage with airborne enemies. 
-- @param #AI_CAP_ZONE self
-- @param #number EngageRange The Engage Range.
-- @return #AI_CAP_ZONE self
function AI_CAP_ZONE:SetEngageRange( EngageRange )
  self:F2()

  if EngageRange then  
    self.EngageRange = EngageRange
  else
    self.EngageRange = nil
  end
end

--- onafter State Transition for Event Start.
-- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAP_ZONE:onafterStart( Controllable, From, Event, To )

  -- Call the parent Start event handler
  self:GetParent(self).onafterStart( self, Controllable, From, Event, To )
  self:HandleEvent( EVENTS.Dead )

end


--- @param AI.AI_CAP#AI_CAP_ZONE 
-- @param Wrapper.Group#GROUP EngageGroup
function AI_CAP_ZONE.EngageRoute( EngageGroup, Fsm )

  EngageGroup:F( { "AI_CAP_ZONE.EngageRoute:", EngageGroup:GetName() } )

  if EngageGroup:IsAlive() then
    Fsm:__Engage( 1 )
  end
end



--- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAP_ZONE:onbeforeEngage( Controllable, From, Event, To )
  
  if self.Accomplished == true then
    return false
  end
end

--- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAP_ZONE:onafterDetected( Controllable, From, Event, To )

  if From ~= "Engaging" then
  
    local Engage = false
  
    for DetectedUnit, Detected in pairs( self.DetectedUnits ) do
    
      local DetectedUnit = DetectedUnit -- Wrapper.Unit#UNIT
      self:T( DetectedUnit )
      if DetectedUnit:IsAlive() and DetectedUnit:IsAir() then
        Engage = true
        break
      end
    end
  
    if Engage == true then
      self:F( 'Detected -> Engaging' )
      self:__Engage( 1 )
    end
  end
end


--- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAP_ZONE:onafterAbort( Controllable, From, Event, To )
  Controllable:ClearTasks()
  self:__Route( 1 )
end




--- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAP_ZONE:onafterEngage( Controllable, From, Event, To )

  if Controllable and Controllable:IsAlive() then

    local EngageRoute = {}

    --- Calculate the current route point.
    local CurrentVec2 = self.Controllable:GetVec2()
    
    --TODO: Create GetAltitude function for GROUP, and delete GetUnit(1).
    local CurrentAltitude = self.Controllable:GetUnit(1):GetAltitude()
    local CurrentPointVec3 = POINT_VEC3:New( CurrentVec2.x, CurrentAltitude, CurrentVec2.y )
    local ToEngageZoneSpeed = self.PatrolMaxSpeed
    local CurrentRoutePoint = CurrentPointVec3:WaypointAir( 
        self.PatrolAltType, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        ToEngageZoneSpeed, 
        true 
      )
    
    EngageRoute[#EngageRoute+1] = CurrentRoutePoint

    
     --- Find a random 2D point in PatrolZone.
    local ToTargetVec2 = self.PatrolZone:GetRandomVec2()
    self:T2( ToTargetVec2 )

    --- Define Speed and Altitude.
    local ToTargetAltitude = math.random( self.EngageFloorAltitude, self.EngageCeilingAltitude )
    local ToTargetSpeed = math.random( self.PatrolMinSpeed, self.PatrolMaxSpeed )
    self:T2( { self.PatrolMinSpeed, self.PatrolMaxSpeed, ToTargetSpeed } )
    
    --- Obtain a 3D @{Point} from the 2D point + altitude.
    local ToTargetPointVec3 = POINT_VEC3:New( ToTargetVec2.x, ToTargetAltitude, ToTargetVec2.y )
    
    --- Create a route point of type air.
    local ToPatrolRoutePoint = ToTargetPointVec3:WaypointAir( 
      self.PatrolAltType, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      ToTargetSpeed, 
      true 
    )

    EngageRoute[#EngageRoute+1] = ToPatrolRoutePoint

    Controllable:OptionROEOpenFire()
    Controllable:OptionROTEvadeFire()

    local AttackTasks = {}

    for DetectedUnit, Detected in pairs( self.DetectedUnits ) do
      local DetectedUnit = DetectedUnit -- Wrapper.Unit#UNIT
      self:T( { DetectedUnit, DetectedUnit:IsAlive(), DetectedUnit:IsAir() } )
      if DetectedUnit:IsAlive() and DetectedUnit:IsAir() then
        if self.EngageZone then
          if DetectedUnit:IsInZone( self.EngageZone ) then
            self:F( {"Within Zone and Engaging ", DetectedUnit } )
            AttackTasks[#AttackTasks+1] = Controllable:TaskAttackUnit( DetectedUnit )
          end
        else        
          if self.EngageRange then
            if DetectedUnit:GetPointVec3():Get2DDistance(Controllable:GetPointVec3() ) <= self.EngageRange then
              self:F( {"Within Range and Engaging", DetectedUnit } )
              AttackTasks[#AttackTasks+1] = Controllable:TaskAttackUnit( DetectedUnit )
            end
          else
            AttackTasks[#AttackTasks+1] = Controllable:TaskAttackUnit( DetectedUnit )
          end
        end
      else
        self.DetectedUnits[DetectedUnit] = nil
      end
    end

    if #AttackTasks == 0 then
      self:F("No targets found -> Going back to Patrolling")
      self:__Abort( 1 )
      self:__Route( 1 )
      self:SetDetectionActivated()
    else

      AttackTasks[#AttackTasks+1] = Controllable:TaskFunction( "AI_CAP_ZONE.EngageRoute", self )
      EngageRoute[1].task = Controllable:TaskCombo( AttackTasks )
      
      self:SetDetectionDeactivated()
    end
    
    Controllable:Route( EngageRoute, 0.5 )
  
  end
end

--- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAP_ZONE:onafterAccomplish( Controllable, From, Event, To )
  self.Accomplished = true
  self:SetDetectionOff()
end

--- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Event#EVENTDATA EventData
function AI_CAP_ZONE:onafterDestroy( Controllable, From, Event, To, EventData )

  if EventData.IniUnit then
    self.DetectedUnits[EventData.IniUnit] = nil
  end
end

--- @param #AI_CAP_ZONE self
-- @param Core.Event#EVENTDATA EventData
function AI_CAP_ZONE:OnEventDead( EventData )
  self:F( { "EventDead", EventData } )

  if EventData.IniDCSUnit then
    if self.DetectedUnits and self.DetectedUnits[EventData.IniUnit] then
      self:__Destroy( 1, EventData )
    end
  end
end
