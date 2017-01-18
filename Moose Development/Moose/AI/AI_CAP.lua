--- Single-Player:**Yes** / Mulit-Player:**Yes** / AI:**Yes** / Human:**No** / Types:**Air** -- **Execute Combat Air Patrol (CAP).**
--
-- ![Banner Image](..\Presentations\AI_Cap\Dia1.JPG)
-- 
-- 
-- ===
--
-- # 1) @{#AI_CAP_ZONE} class, extends @{AI.AI_Cap#AI_PATROL_ZONE}
-- 
-- The @{#AI_CAP_ZONE} class implements the core functions to patrol a @{Zone} by an AI @{Controllable} or @{Group} 
-- and automatically engage any airborne enemies that are within a certain range or within a certain zone.
-- 
-- ![Process](..\Presentations\AI_Cap\Dia3.JPG)
-- 
-- The AI_CAP_ZONE is assigned a @(Group) and this must be done before the AI_CAP_ZONE process can be started using the **Start** event.
-- 
-- ![Process](..\Presentations\AI_Cap\Dia4.JPG)
-- 
-- The AI will fly towards the random 3D point within the patrol zone, using a random speed within the given altitude and speed limits.
-- Upon arrival at the 3D point, a new random 3D point will be selected within the patrol zone using the given limits.
-- 
-- ![Process](..\Presentations\AI_Cap\Dia5.JPG)
-- 
-- This cycle will continue.
-- 
-- ![Process](..\Presentations\AI_Cap\Dia6.JPG)
-- 
-- During the patrol, the AI will detect enemy targets, which are reported through the **Detected** event.
--
-- ![Process](..\Presentations\AI_Cap\Dia9.JPG)
-- 
-- When enemies are detected, the AI will automatically engage the enemy.
-- 
-- ![Process](..\Presentations\AI_Cap\Dia10.JPG)
-- 
-- Until a fuel or damage treshold has been reached by the AI, or when the AI is commanded to RTB.
-- When the fuel treshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- ![Process](..\Presentations\AI_Cap\Dia13.JPG)
-- 
-- ## 1.1) AI_CAP_ZONE constructor
--   
--   * @{#AI_CAP_ZONE.New}(): Creates a new AI_CAP_ZONE object.
-- 
-- ## 1.2) AI_CAP_ZONE is a FSM
-- 
-- ![Process](..\Presentations\AI_Cap\Dia2.JPG)
-- 
-- ### 1.2.1) AI_CAP_ZONE States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Engaging** ( Group ): The AI is engaging the bogeys.
--   * **Returning** ( Group ): The AI is returning to Base..
-- 
-- ### 1.2.2) AI_CAP_ZONE Events
-- 
--   * **Start** ( Group ): Start the process.
--   * **Route** ( Group ): Route the AI to a new random 3D point within the Patrol Zone.
--   * **Engage** ( Group ): Let the AI engage the bogeys.
--   * **RTB** ( Group ): Route the AI to the home base.
--   * **Detect** ( Group ): The AI is detecting targets.
--   * **Detected** ( Group ): The AI has detected new targets.
--   * **Status** ( Group ): The AI is checking status (fuel and damage). When the tresholds have been reached, the AI will RTB.
--
-- ## 1.3) Set the Range of Engagement
-- 
-- ![Range](..\Presentations\AI_Cap\Dia11.JPG)
-- 
-- An optional range can be set in meters, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- The range can be beyond or smaller than the range of the Patrol Zone.
-- The range is applied at the position of the AI.
-- Use the method @{AI.AI_Cap#AI_CAP_ZONE.SetEngageRange}() to define that range.
--
-- ## 1.4) Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_Cap\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_CAP_ZONE.SetEngageZone}() to define that Zone.
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
-- @module AI_Cap


--- AI_CAP_ZONE class
-- @type AI_CAP_ZONE
-- @field Wrapper.Controllable#CONTROLLABLE AIControllable The @{Controllable} patrolling.
-- @field Core.Zone#ZONE_BASE TargetZone The @{Zone} where the patrol needs to be executed.
-- @extends AI.AI_Patrol#AI_PATROL_ZONE
AI_CAP_ZONE = {
  ClassName = "AI_CAP_ZONE",
}



--- Creates a new AI_CAP_ZONE object
-- @param #AI_CAP_ZONE self
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @return #AI_CAP_ZONE self
function AI_CAP_ZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_PATROL_ZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed ) ) -- #AI_CAP_ZONE

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


  self:Route()
  self:__Status( 30 ) -- Check status status every 30 seconds.
  self:__Detect( self.DetectInterval ) -- Detect for new targets every DetectInterval in the EngageZone.

  self:EventOnDead( self.OnDead )
  
  Controllable:OptionROEOpenFire()
  
  self.Controllable:OnReSpawn(
    function( PatrolGroup )
      self:E( "ReSpawn" )
      self:__Reset()
      self:__Route( 5 )
    end
  )
  
end

--- @param Wrapper.Controllable#CONTROLLABLE AIControllable
function _NewEngageCapRoute( AIControllable )

  AIControllable:T( "NewEngageRoute" )
  local EngageZone = AIControllable:GetState( AIControllable, "EngageZone" ) -- AI.AI_Cap#AI_CAP_ZONE
  EngageZone:__Engage( 1 )
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
  
    for DetectedUnitID, DetectedUnit in pairs( self.DetectedUnits ) do
    
      local DetectedUnit = DetectedUnit -- Wrapper.Unit#UNIT
      self:T( DetectedUnit )
      if DetectedUnit:IsAlive() and DetectedUnit:IsAir() then
        Engage = true
        break
      end
    end
  
    if Engage == true then
      self:E( 'Detected -> Engaging' )
      self:__Engage( 1 )
    end
  end
end



--- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAP_ZONE:onafterEngage( Controllable, From, Event, To )

  if Controllable:IsAlive() then

    self:Detect( self.EngageZone )

    local EngageRoute = {}

    --- Calculate the current route point.
    local CurrentVec2 = self.Controllable:GetVec2()
    
    --TODO: Create GetAltitude function for GROUP, and delete GetUnit(1).
    local CurrentAltitude = self.Controllable:GetUnit(1):GetAltitude()
    local CurrentPointVec3 = POINT_VEC3:New( CurrentVec2.x, CurrentAltitude, CurrentVec2.y )
    local ToEngageZoneSpeed = self.PatrolMaxSpeed
    local CurrentRoutePoint = CurrentPointVec3:RoutePointAir( 
        POINT_VEC3.RoutePointAltType.BARO, 
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
    local ToPatrolRoutePoint = ToTargetPointVec3:RoutePointAir( 
      POINT_VEC3.RoutePointAltType.BARO, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      ToTargetSpeed, 
      true 
    )

    EngageRoute[#EngageRoute+1] = ToPatrolRoutePoint

    Controllable:OptionROEOpenFire()
    Controllable:OptionROTPassiveDefense()

    local AttackTasks = {}

    for DetectedUnitID, DetectedUnit in pairs( self.DetectedUnits ) do
      local DetectedUnit = DetectedUnit -- Wrapper.Unit#UNIT
      self:T( DetectedUnit )
      if DetectedUnit:IsAlive() and DetectedUnit:IsAir() then
        if self.EngageZone then
          if DetectedUnit:IsInZone( self.EngageZone ) then
            self:E( {"Within Zone and Engaging ", DetectedUnit } )
            AttackTasks[#AttackTasks+1] = Controllable:TaskAttackUnit( DetectedUnit )
          end
        else        
          if self.EngageRange then
            if DetectedUnit:GetPointVec3():Get2DDistance(Controllable:GetPointVec3() ) <= self.EngageRange then
              self:E( {"Within Range and Engaging", DetectedUnit } )
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

    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    self.Controllable:WayPointInitialize( EngageRoute )
    
    
    if #AttackTasks == 0 then
      self:E("No targets found -> Going back to Patrolling")
      self:Accomplish()
      self:Route()
    else
      EngageRoute[1].task = Controllable:TaskCombo( AttackTasks )
      
      --- Do a trick, link the NewEngageRoute function of the object to the AIControllable in a temporary variable ...
      self.Controllable:SetState( self.Controllable, "EngageZone", self )
  
      self.Controllable:WayPointFunction( #EngageRoute, 1, "_NewEngageCapRoute" )
  
    end
    
        --- NOW ROUTE THE GROUP!
    self.Controllable:WayPointExecute( 1, 2 )
  
  end
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
  
  Controllable:MessageToAll( "Destroyed a target", 15 , "Destroyed!" )
end

--- @param #AI_CAP_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_CAP_ZONE:onafterAccomplish( Controllable, From, Event, To )
  self.Accomplished = true
  self.DetectUnits = false
end

--- @param #AI_CAP_ZONE self
-- @param Core.Event#EVENTDATA EventData
function AI_CAP_ZONE:OnDead( EventData )
  self:T( { "EventDead", EventData } )

  if EventData.IniDCSUnit then
    self:__Destroy( 1, EventData )
  end
end


