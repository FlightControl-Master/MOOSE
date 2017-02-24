--- Single-Player:**Yes** / Mulit-Player:**Yes** / AI:**Yes** / Human:**No** / Types:**Air** -- 
-- **Provide Close Air Support to friendly ground troops.**
--
-- ![Banner Image](..\Presentations\AI_CAS\Dia1.JPG)
-- 
-- ===
--
-- # 1) @{#AI_CAS_ZONE} class, extends @{AI_Patrol#AI_PATROL_ZONE}
-- 
-- @{#AI_CAS_ZONE} derives from the @{AI_Patrol#AI_PATROL_ZONE}, inheriting its methods and behaviour.
--  
-- The @{#AI_CAS_ZONE} class implements the core functions to provide Close Air Support in an Engage @{Zone} by an AIR @{Controllable} or @{Group}.
-- The AI_CAS_ZONE runs a process. It holds an AI in a Patrol Zone and when the AI is commanded to engage, it will fly to an Engage Zone.
-- 
-- ![HoldAndEngage](..\Presentations\AI_CAS\Dia3.JPG)
-- 
-- The AI_CAS_ZONE is assigned a @{Group} and this must be done before the AI_CAS_ZONE process can be started through the **Start** event.
--  
-- ![Start Event](..\Presentations\AI_CAS\Dia4.JPG)
-- 
-- Upon started, The AI will **Route** itself towards the random 3D point within a patrol zone, 
-- using a random speed within the given altitude and speed limits.
-- Upon arrival at the 3D point, a new random 3D point will be selected within the patrol zone using the given limits.
-- This cycle will continue until a fuel or damage treshold has been reached by the AI, or when the AI is commanded to RTB.
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
-- When the fuel treshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- ![Engage Event](..\Presentations\AI_CAS\Dia12.JPG)
--
-- # 1.1) AI_CAS_ZONE constructor
--
--   * @{#AI_CAS_ZONE.New}(): Creates a new AI_CAS_ZONE object.
--
-- ## 1.2) AI_CAS_ZONE is a FSM
-- 
-- ![Process](..\Presentations\AI_CAS\Dia2.JPG)
-- 
-- ### 1.2.1) AI_CAS_ZONE States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Engaging** ( Group ): The AI is engaging the targets in the Engage Zone, executing CAS.
--   * **Returning** ( Group ): The AI is returning to Base..
-- 
-- ### 1.2.2) AI_CAS_ZONE Events
-- 
--   * **Start** ( Group ): Start the process.
--   * **Route** ( Group ): Route the AI to a new random 3D point within the Patrol Zone.
--   * **Engage** ( Group ): Engage the AI to provide CAS in the Engage Zone, destroying any target it finds.
--   * **RTB** ( Group ): Route the AI to the home base.
--   * **Detect** ( Group ): The AI is detecting targets.
--   * **Detected** ( Group ): The AI has detected new targets.
--   * **Status** ( Group ): The AI is checking status (fuel and damage). When the tresholds have been reached, the AI will RTB.
--    
-- ====
--
-- # **API CHANGE HISTORY**
--
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
--
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
--
-- Hereby the change log:
--
-- 2017-01-15: Initial class and API.
--
-- ===
--
-- # **AUTHORS and CONTRIBUTIONS**
--
-- ### Contributions:
--
--   * **[Quax](https://forums.eagle.ru/member.php?u=90530)**: Concept, Advice & Testing.
--   * **[Pikey](https://forums.eagle.ru/member.php?u=62835)**: Concept, Advice & Testing.
--   * **[Gunterlund](http://forums.eagle.ru:8080/member.php?u=75036)**: Test case revision.
--
-- ### Authors:
--
--   * **FlightControl**: Concept, Design & Programming.
--
-- @module AI_Cas


--- AI_CAS_ZONE class
-- @type AI_CAS_ZONE
-- @field Wrapper.Controllable#CONTROLLABLE AIControllable The @{Controllable} patrolling.
-- @field Core.Zone#ZONE_BASE TargetZone The @{Zone} where the patrol needs to be executed.
-- @extends AI.AI_Patrol#AI_PATROL_ZONE
AI_CAS_ZONE = {
  ClassName = "AI_CAS_ZONE",
}



--- Creates a new AI_CAS_ZONE object
-- @param #AI_CAS_ZONE self
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @param Core.Zone#ZONE_BASE EngageZone The zone where the engage will happen.
-- @param Dcs.DCSTypes#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
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
  -- @param #number EngageSpeed (optional) The speed the Group will hold when engaging to the target zone.
  -- @param Dcs.DCSTypes#AI.Task.WeaponExpend EngageWeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
  -- @param Dcs.DCSTypes#Distance EngageAltitude (optional) Desired altitude to perform the unit engagement.
  -- @param #number EngageAttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
  -- @param Dcs.DCSTypes#Azimuth EngageDirection (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
  
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Engage.
  -- @function [parent=#AI_CAS_ZONE] OnAfterEngage
  -- @param #AI_CAS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @param #number EngageSpeed (optional) The speed the Group will hold when engaging to the target zone.
  -- @param Dcs.DCSTypes#AI.Task.WeaponExpend EngageWeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
  -- @param Dcs.DCSTypes#Distance EngageAltitude (optional) Desired altitude to perform the unit engagement.
  -- @param #number EngageAttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
  -- @param Dcs.DCSTypes#Azimuth EngageDirection (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
  	
  --- Synchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_CAS_ZONE] Engage
  -- @param #AI_CAS_ZONE self
  
  --- Asynchronous Event Trigger for Event Engage.
  -- @function [parent=#AI_CAS_ZONE] __Engage
  -- @param #AI_CAS_ZONE self
  -- @param #number Delay The delay in seconds.

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
  self:HandleEvent( EVENTS.Dead, self.OnDead )
  
  self:SetDetectionDeactivated() -- When not engaging, set the detection off.
end

--- @param Wrapper.Controllable#CONTROLLABLE AIControllable
function _NewEngageRoute( AIControllable )

  AIControllable:T( "NewEngageRoute" )
  local EngageZone = AIControllable:GetState( AIControllable, "EngageZone" ) -- AI.AI_Cas#AI_CAS_ZONE
  EngageZone:__Engage( 1 )
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
  self:E("onafterTarget")

  if Controllable:IsAlive() then

    local AttackTasks = {}

    for DetectedUnit, Detected in pairs( self.DetectedUnits ) do
      local DetectedUnit = DetectedUnit -- Wrapper.Unit#UNIT
      if DetectedUnit:IsAlive() then
        if DetectedUnit:IsInZone( self.EngageZone ) then
          if Detected == true then
            self:E( {"Target: ", DetectedUnit } )
            self.DetectedUnits[DetectedUnit] = false
            local AttackTask = Controllable:EnRouteTaskEngageUnit( DetectedUnit, 1, true, self.EngageWeaponExpend, self.EngageAttackQty, self.EngageDirection, self.EngageAltitude, nil )
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
-- @param #number EngageSpeed (optional) The speed the Group will hold when engaging to the target zone.
-- @param Dcs.DCSTypes#AI.Task.WeaponExpend EngageWeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param Dcs.DCSTypes#Distance EngageAltitude (optional) Desired altitude to perform the unit engagement.
-- @param #number EngageAttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param Dcs.DCSTypes#Azimuth EngageDirection (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
function AI_CAS_ZONE:onafterEngage( Controllable, From, Event, To, EngageSpeed, EngageAltitude, EngageWeaponExpend, EngageAttackQty, EngageDirection )
  self:E("onafterEngage")

  self.EngageSpeed = EngageSpeed or 400
  self.EngageAltitude = EngageAltitude or 2000
  self.EngageWeaponExpend = EngageWeaponExpend
  self.EngageAttackQty = EngageAttackQty
  self.EngageDirection = EngageDirection

  if Controllable:IsAlive() then
  

    local EngageRoute = {}

    --- Calculate the current route point.
    local CurrentVec2 = self.Controllable:GetVec2()
    
    --TODO: Create GetAltitude function for GROUP, and delete GetUnit(1).
    local CurrentAltitude = self.Controllable:GetUnit(1):GetAltitude()
    local CurrentPointVec3 = POINT_VEC3:New( CurrentVec2.x, CurrentAltitude, CurrentVec2.y )
    local ToEngageZoneSpeed = self.PatrolMaxSpeed
    local CurrentRoutePoint = CurrentPointVec3:RoutePointAir( 
        self.PatrolAltType, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        self.EngageSpeed, 
        true 
      )
    
    EngageRoute[#EngageRoute+1] = CurrentRoutePoint

  
    if self.Controllable:IsNotInZone( self.EngageZone ) then

      -- Find a random 2D point in EngageZone.
      local ToEngageZoneVec2 = self.EngageZone:GetRandomVec2()
      self:T2( ToEngageZoneVec2 )
      
      -- Obtain a 3D @{Point} from the 2D point + altitude.
      local ToEngageZonePointVec3 = POINT_VEC3:New( ToEngageZoneVec2.x, self.EngageAltitude, ToEngageZoneVec2.y )
      
      -- Create a route point of type air.
      local ToEngageZoneRoutePoint = ToEngageZonePointVec3:RoutePointAir( 
        self.PatrolAltType, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        self.EngageSpeed, 
        true 
      )

      EngageRoute[#EngageRoute+1] = ToEngageZoneRoutePoint

    end
    
    --- Define a random point in the @{Zone}. The AI will fly to that point within the zone.
    
      --- Find a random 2D point in EngageZone.
    local ToTargetVec2 = self.EngageZone:GetRandomVec2()
    self:T2( ToTargetVec2 )

    --- Obtain a 3D @{Point} from the 2D point + altitude.
    local ToTargetPointVec3 = POINT_VEC3:New( ToTargetVec2.x, self.EngageAltitude, ToTargetVec2.y )
    
    --- Create a route point of type air.
    local ToTargetRoutePoint = ToTargetPointVec3:RoutePointAir( 
      self.PatrolAltType, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      self.EngageSpeed, 
      true 
    )
    
    ToTargetPointVec3:SmokeBlue()

    EngageRoute[#EngageRoute+1] = ToTargetRoutePoint
    

    Controllable:OptionROEOpenFire()
    Controllable:OptionROTVertical()

--    local AttackTasks = {}
--
--    for DetectedUnitID, DetectedUnit in pairs( self.DetectedUnits ) do
--      local DetectedUnit = DetectedUnit -- Wrapper.Unit#UNIT
--      self:T( DetectedUnit )
--      if DetectedUnit:IsAlive() then
--        if DetectedUnit:IsInZone( self.EngageZone ) then
--          self:E( {"Engaging ", DetectedUnit } )
--          AttackTasks[#AttackTasks+1] = Controllable:TaskAttackUnit( DetectedUnit )
--        end
--      else
--        self.DetectedUnits[DetectedUnit] = nil
--      end
--    end
--
--    EngageRoute[1].task = Controllable:TaskCombo( AttackTasks )

    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    self.Controllable:WayPointInitialize( EngageRoute )
    
    --- Do a trick, link the NewEngageRoute function of the object to the AIControllable in a temporary variable ...
    self.Controllable:SetState( self.Controllable, "EngageZone", self )

    self.Controllable:WayPointFunction( #EngageRoute, 1, "_NewEngageRoute" )

    --- NOW ROUTE THE GROUP!
    self.Controllable:WayPointExecute( 1 )
    
    self:SetDetectionInterval( 10 )
    self:SetDetectionActivated()
    self:__Target( -10 ) -- Start Targetting
  end
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
  
  Controllable:MessageToAll( "Destroyed a target", 15 , "Destroyed!" )
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
-- @param Core.Event#EVENTDATA EventData
function AI_CAS_ZONE:OnDead( EventData )
  self:T( { "EventDead", EventData } )

  if EventData.IniDCSUnit then
    self:__Destroy( 1, EventData )
  end
end


