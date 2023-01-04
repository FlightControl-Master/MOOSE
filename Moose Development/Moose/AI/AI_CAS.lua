--- **AI** - Perform Close Air Support (CAS) near friendlies.
--
-- **Features:**
-- 
--   * Hold and standby within a patrol zone.
--   * Engage upon command the enemies within an engagement zone.
--   * Loop the zone until all enemies are eliminated.
--   * Trigger different events upon the results achieved.
--   * After combat, return to the patrol zone and hold.
--   * RTB when commanded or after fuel.
--
-- ===
-- 
-- ### [Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/CAS%20-%20Close%20Air%20Support)
-- 
-- ===
-- 
-- ### [YouTube Playlist](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl3JBO1WDqqpyYRRmIkR2ir2)
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: 
--
--   * **[Quax](https://forums.eagle.ru/member.php?u=90530)**: Concept, Advice & Testing.
--   * **[Pikey](https://forums.eagle.ru/member.php?u=62835)**: Concept, Advice & Testing.
--   * **[Gunterlund](http://forums.eagle.ru:8080/member.php?u=75036)**: Test case revision.
--
-- ===
--
-- @module AI.AI_CAS
-- @image AI_Close_Air_Support.JPG

--- AI_CAS_ZONE class
-- @type AI_CAS_ZONE
-- @field Wrapper.Controllable#CONTROLLABLE AIControllable The @{Wrapper.Controllable} patrolling.
-- @field Core.Zone#ZONE_BASE TargetZone The @{Core.Zone} where the patrol needs to be executed.
-- @extends AI.AI_Patrol#AI_PATROL_ZONE

--- Implements the core functions to provide Close Air Support in an Engage @{Core.Zone} by an AIR @{Wrapper.Controllable} or @{Wrapper.Group}.
-- The AI_CAS_ZONE runs a process. It holds an AI in a Patrol Zone and when the AI is commanded to engage, it will fly to an Engage Zone.
-- 
-- ![HoldAndEngage](..\Presentations\AI_CAS\Dia3.JPG)
-- 
-- The AI_CAS_ZONE is assigned a @{Wrapper.Group} and this must be done before the AI_CAS_ZONE process can be started through the **Start** event.
--  
-- ![Start Event](..\Presentations\AI_CAS\Dia4.JPG)
-- 
-- Upon started, The AI will **Route** itself towards the random 3D point within a patrol zone, 
-- using a random speed within the given altitude and speed limits.
-- Upon arrival at the 3D point, a new random 3D point will be selected within the patrol zone using the given limits.
-- This cycle will continue until a fuel or damage threshold has been reached by the AI, or when the AI is commanded to RTB.
-- 
-- ![Route Event](..\Presentations\AI_CAS\Dia5.JPG)
-- 
-- When the AI is commanded to provide Close Air Support (through the event **Engage**), the AI will fly towards the Engage Zone.
-- Any target that is detected in the Engage Zone will be reported and will be destroyed by the AI.
-- 
-- ![Engage Event](..\Presentations\AI_CAS\Dia6.JPG)
-- 
-- The AI will detect the targets and will only destroy the targets within the Engage Zone.
-- 
-- ![Engage Event](..\Presentations\AI_CAS\Dia7.JPG)
-- 
-- Every target that is destroyed, is reported< by the AI.
-- 
-- ![Engage Event](..\Presentations\AI_CAS\Dia8.JPG)
-- 
-- Note that the AI does not know when the Engage Zone is cleared, and therefore will keep circling in the zone. 
--
-- ![Engage Event](..\Presentations\AI_CAS\Dia9.JPG)
-- 
-- Until it is notified through the event **Accomplish**, which is to be triggered by an observing party:
-- 
--   * a FAC
--   * a timed event
--   * a menu option selected by a human
--   * a condition
--   * others ...
-- 
-- ![Engage Event](..\Presentations\AI_CAS\Dia10.JPG)
-- 
-- When the AI has accomplished the CAS, it will fly back to the Patrol Zone.
-- 
-- ![Engage Event](..\Presentations\AI_CAS\Dia11.JPG)
-- 
-- It will keep patrolling there, until it is notified to RTB or move to another CAS Zone.
-- It can be notified to go RTB through the **RTB** event.
-- 
-- When the fuel threshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- ![Engage Event](..\Presentations\AI_CAS\Dia12.JPG)
--
-- ## AI_CAS_ZONE constructor
--
--   * @{#AI_CAS_ZONE.New}(): Creates a new AI_CAS_ZONE object.
--
-- ## AI_CAS_ZONE is a FSM
-- 
-- ![Process](..\Presentations\AI_CAS\Dia2.JPG)
-- 
-- ### 2.1. AI_CAS_ZONE States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Engaging** ( Group ): The AI is engaging the targets in the Engage Zone, executing CAS.
--   * **Returning** ( Group ): The AI is returning to Base..
-- 
-- ### 2.2. AI_CAS_ZONE Events
-- 
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Route}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_CAS_ZONE.Engage}**: Engage the AI to provide CAS in the Engage Zone, destroying any target it finds.
--   * **@{#AI_CAS_ZONE.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_CAS_ZONE.Destroy}**: The AI has destroyed a target @{Wrapper.Unit}.
--   * **@{#AI_CAS_ZONE.Destroyed}**: The AI has destroyed all target @{Wrapper.Unit}s assigned in the CAS task.
--   * **Status**: The AI is checking status (fuel and damage). When the thresholds have been reached, the AI will RTB.
-- 
-- ===
-- 
-- @field #AI_CAS_ZONE
AI_CAS_ZONE = {
  ClassName = "AI_CAS_ZONE",
}



--- Creates a new AI_CAS_ZONE object
-- @param #AI_CAS_ZONE self
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Core.Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Controllable} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Controllable} in km/h.
-- @param Core.Zone#ZONE_BASE EngageZone The zone where the engage will happen.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_CAS_ZONE self
function AI_CAS_ZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageZone, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_PATROL_ZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType ) ) -- #AI_CAS_ZONE

  self.EngageZone = EngageZone
  self.Accomplished = false
  
  self:SetDetectionZone( self.EngageZone )

  self:AddTransition( { "Patrolling", "Engaging" }, "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS_ZONE.

  --- OnBefore Transition Handler for Event Engage.
  -- @function [parent=#AI_CAS_ZONE] OnBeforeEngage
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_CAS_ZONE] OnAfterEngage
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_CAS_ZONE] Engage
  -- @param #AI_CAS_ZONE self
  -- @param #number EngageSpeed (optional) The speed the Group will hold when engaging to the target zone.
  -- @param DCS#Distance EngageAltitude (optional) Desired altitude to perform the unit engagement.
  -- @param DCS#AI.Task.WeaponExpend EngageWeaponExpend (optional) Determines how much weapon will be released at each attack. 
  -- If parameter is not defined the unit / controllable will choose expend on its own discretion.
  -- Use the structure @{DCS#AI.Task.WeaponExpend} to define the amount of weapons to be release at each attack.
  -- @param #number EngageAttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
  -- @param DCS#Azimuth EngageDirection (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
  
  --- Asynchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_CAS_ZONE] __Engage
  -- @param #AI_CAS_ZONE self
  -- @param #number Delay The delay in seconds.
  -- @param #number EngageSpeed (optional) The speed the Group will hold when engaging to the target zone.
  -- @param DCS#Distance EngageAltitude (optional) Desired altitude to perform the unit engagement.
  -- @param DCS#AI.Task.WeaponExpend EngageWeaponExpend (optional) Determines how much weapon will be released at each attack. 
  -- If parameter is not defined the unit / controllable will choose expend on its own discretion.
  -- Use the structure @{DCS#AI.Task.WeaponExpend} to define the amount of weapons to be release at each attack.
  -- @param #number EngageAttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
  -- @param DCS#Azimuth EngageDirection (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.

--- OnLeave Transition Handler for State Engaging.
-- @function [parent=#AI_CAS_ZONE] OnLeaveEngaging
-- @param #AI_CAS_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Engaging.
-- @function [parent=#AI_CAS_ZONE] OnEnterEngaging
-- @param #AI_CAS_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Engaging", "Target", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS_ZONE.

  self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS_ZONE.
  
  --- OnBefore Transition Handler for Event Fired.
  -- @function [parent=#AI_CAS_ZONE] OnBeforeFired
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fired.
  -- @function [parent=#AI_CAS_ZONE] OnAfterFired
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_CAS_ZONE] Fired
  -- @param #AI_CAS_ZONE self
  
  --- Asynchronous Event Trigger for Event Fired.
  -- @function [parent=#AI_CAS_ZONE] __Fired
  -- @param #AI_CAS_ZONE self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Destroy", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS_ZONE.

  --- OnBefore Transition Handler for Event Destroy.
  -- @function [parent=#AI_CAS_ZONE] OnBeforeDestroy
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Destroy.
  -- @function [parent=#AI_CAS_ZONE] OnAfterDestroy
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_CAS_ZONE] Destroy
  -- @param #AI_CAS_ZONE self
  
  --- Asynchronous Event Trigger for Event Destroy.
  -- @function [parent=#AI_CAS_ZONE] __Destroy
  -- @param #AI_CAS_ZONE self
  -- @param #number Delay The delay in seconds.


  self:AddTransition( "Engaging", "Abort", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS_ZONE.

  --- OnBefore Transition Handler for Event Abort.
  -- @function [parent=#AI_CAS_ZONE] OnBeforeAbort
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Abort.
  -- @function [parent=#AI_CAS_ZONE] OnAfterAbort
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_CAS_ZONE] Abort
  -- @param #AI_CAS_ZONE self
  
  --- Asynchronous Event Trigger for Event Abort.
  -- @function [parent=#AI_CAS_ZONE] __Abort
  -- @param #AI_CAS_ZONE self
  -- @param #number Delay The delay in seconds.

  self:AddTransition( "Engaging", "Accomplish", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS_ZONE.

  --- OnBefore Transition Handler for Event Accomplish.
  -- @function [parent=#AI_CAS_ZONE] OnBeforeAccomplish
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Accomplish.
  -- @function [parent=#AI_CAS_ZONE] OnAfterAccomplish
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_CAS_ZONE] Accomplish
  -- @param #AI_CAS_ZONE self
  
  --- Asynchronous Event Trigger for Event Accomplish.
  -- @function [parent=#AI_CAS_ZONE] __Accomplish
  -- @param #AI_CAS_ZONE self
  -- @param #number Delay The delay in seconds.  

  return self
end


--- Set the Engage Zone where the AI is performing CAS. Note that if the EngageZone is changed, the AI needs to re-detect targets.
-- @param #AI_CAS_ZONE self
-- @param Core.Zone#ZONE EngageZone The zone where the AI is performing CAS.
-- @return #AI_CAS_ZONE self
function AI_CAS_ZONE:SetEngageZone( EngageZone )
  self:F2()

  if EngageZone then  
    self.EngageZone = EngageZone
  else
    self.EngageZone = nil
  end
end



--- onafter State Transition for Event Start.
-- @param #AI_CAS_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAS_ZONE:onafterStart( Controllable, From, Event, To )

  -- Call the parent Start event handler
  self:GetParent(self).onafterStart( self, Controllable, From, Event, To )
  self:HandleEvent( EVENTS.Dead )
  
  self:SetDetectionDeactivated() -- When not engaging, set the detection off.
end

--- @param AI.AI_CAS#AI_CAS_ZONE 
-- @param Wrapper.Group#GROUP EngageGroup
function AI_CAS_ZONE.EngageRoute( EngageGroup, Fsm )

  EngageGroup:F( { "AI_CAS_ZONE.EngageRoute:", EngageGroup:GetName() } )

  if EngageGroup:IsAlive() then
    Fsm:__Engage( 1, Fsm.EngageSpeed, Fsm.EngageAltitude, Fsm.EngageWeaponExpend, Fsm.EngageAttackQty, Fsm.EngageDirection )
  end
end


--- @param #AI_CAS_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAS_ZONE:onbeforeEngage( Controllable, From, Event, To )
  
  if self.Accomplished == true then
    return false
  end
end

--- @param #AI_CAS_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAS_ZONE:onafterTarget( Controllable, From, Event, To )

  if Controllable:IsAlive() then

    local AttackTasks = {}

    for DetectedUnit, Detected in pairs( self.DetectedUnits ) do
      local DetectedUnit = DetectedUnit -- Wrapper.Unit#UNIT
      if DetectedUnit:IsAlive() then
        if DetectedUnit:IsInZone( self.EngageZone ) then
          if Detected == true then
            self:F( {"Target: ", DetectedUnit } )
            self.DetectedUnits[DetectedUnit] = false
            local AttackTask = Controllable:TaskAttackUnit( DetectedUnit, false, self.EngageWeaponExpend, self.EngageAttackQty, self.EngageDirection, self.EngageAltitude, nil )
            self.Controllable:PushTask( AttackTask, 1 )
          end
        end
      else
        self.DetectedUnits[DetectedUnit] = nil
      end
    end

    self:__Target( -10 )

  end
end


--- @param #AI_CAS_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAS_ZONE:onafterAbort( Controllable, From, Event, To )
  Controllable:ClearTasks()
  self:__Route( 1 )
end

--- @param #AI_CAS_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param #number EngageSpeed (optional) The speed the Group will hold when engaging to the target zone.
-- @param DCS#Distance EngageAltitude (optional) Desired altitude to perform the unit engagement.
-- @param DCS#AI.Task.WeaponExpend EngageWeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number EngageAttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth EngageDirection (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
function AI_CAS_ZONE:onafterEngage( Controllable, From, Event, To, 
                                    EngageSpeed, 
                                    EngageAltitude, 
                                    EngageWeaponExpend, 
                                    EngageAttackQty, 
                                    EngageDirection )
  self:F("onafterEngage")

  self.EngageSpeed = EngageSpeed or 400
  self.EngageAltitude = EngageAltitude or 2000
  self.EngageWeaponExpend = EngageWeaponExpend
  self.EngageAttackQty = EngageAttackQty
  self.EngageDirection = EngageDirection

  if Controllable:IsAlive() then

    Controllable:OptionROEOpenFire()
    Controllable:OptionROTVertical()

    local EngageRoute = {}

    --- Calculate the current route point.
    local CurrentVec2 = self.Controllable:GetVec2()
    
    --DONE: Create GetAltitude function for GROUP, and delete GetUnit(1).
    local CurrentAltitude = self.Controllable:GetAltitude()
    local CurrentPointVec3 = POINT_VEC3:New( CurrentVec2.x, CurrentAltitude, CurrentVec2.y )
    local ToEngageZoneSpeed = self.PatrolMaxSpeed
    local CurrentRoutePoint = CurrentPointVec3:WaypointAir( 
        self.PatrolAltType, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        self.EngageSpeed, 
        true 
      )
    
    EngageRoute[#EngageRoute+1] = CurrentRoutePoint

    local AttackTasks = {}

    for DetectedUnit, Detected in pairs( self.DetectedUnits ) do
      local DetectedUnit = DetectedUnit -- Wrapper.Unit#UNIT
      self:T( DetectedUnit )
      if DetectedUnit:IsAlive() then
        if DetectedUnit:IsInZone( self.EngageZone ) then
          self:F( {"Engaging ", DetectedUnit } )
          AttackTasks[#AttackTasks+1] = Controllable:TaskAttackUnit( DetectedUnit, 
                                                                     true, 
                                                                     EngageWeaponExpend, 
                                                                     EngageAttackQty, 
                                                                     EngageDirection 
                                                                   )
        end
      else
        self.DetectedUnits[DetectedUnit] = nil
      end
    end

    AttackTasks[#AttackTasks+1] = Controllable:TaskFunction( "AI_CAS_ZONE.EngageRoute", self )
    EngageRoute[#EngageRoute].task = Controllable:TaskCombo( AttackTasks )

    --- Define a random point in the @{Core.Zone}. The AI will fly to that point within the zone.
    
      --- Find a random 2D point in EngageZone.
    local ToTargetVec2 = self.EngageZone:GetRandomVec2()
    self:T2( ToTargetVec2 )

    --- Obtain a 3D @{Point} from the 2D point + altitude.
    local ToTargetPointVec3 = POINT_VEC3:New( ToTargetVec2.x, self.EngageAltitude, ToTargetVec2.y )
    
    --- Create a route point of type air.
    local ToTargetRoutePoint = ToTargetPointVec3:WaypointAir( 
      self.PatrolAltType, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      self.EngageSpeed, 
      true 
    )
    
    EngageRoute[#EngageRoute+1] = ToTargetRoutePoint
  
    Controllable:Route( EngageRoute, 0.5 )
    
    self:SetRefreshTimeInterval( 2 )
    self:SetDetectionActivated()
    self:__Target( -2 ) -- Start targeting
  end
end


--- @param #AI_CAS_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAS_ZONE:onafterAccomplish( Controllable, From, Event, To )
  self.Accomplished = true
  self:SetDetectionDeactivated()
end


--- @param #AI_CAS_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Core.Event#EVENTDATA EventData
function AI_CAS_ZONE:onafterDestroy( Controllable, From, Event, To, EventData )

  if EventData.IniUnit then
    self.DetectedUnits[EventData.IniUnit] = nil
  end
end


--- @param #AI_CAS_ZONE self
-- @param Core.Event#EVENTDATA EventData
function AI_CAS_ZONE:OnEventDead( EventData )
  self:F( { "EventDead", EventData } )

  if EventData.IniDCSUnit then
    if self.DetectedUnits and self.DetectedUnits[EventData.IniUnit] then
      self:__Destroy( 1, EventData )
    end
  end
end


