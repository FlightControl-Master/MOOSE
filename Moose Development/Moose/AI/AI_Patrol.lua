--- Single-Player:Yes / Mulit-Player:Yes / AI:Yes / Human:No / Types:Air -- Make AI patrol zones and report detected targets.
-- 
-- ![Banner Image](..\Presentations\AI_Patrol\Dia1.JPG)
-- 
-- Examples can be found in the test missions.
-- 
-- ===
-- 
-- # 1) @{#AI_PATROLZONE} class, extends @{Core.Fsm#FSM_CONTROLLABLE}
-- 
-- The @{#AI_PATROLZONE} class implements the core functions to patrol a @{Zone} by an AI @{Controllable} or @{Group}.
-- The AI_PATROLZONE is assigned a @(Group) and this must be done before the AI_PATROLZONE process can be started. 
-- The AI will fly towards the random 3D point within the patrol zone, using a random speed within the given altitude and speed limits.
-- Upon arrival at the 3D point, a new random 3D point will be selected within the patrol zone using the given limits.
-- This cycle will continue until a fuel or damage treshold has been reached by the AI, or when the AI is commanded to RTB.
-- When the fuel treshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- ## 1.1) AI_PATROLZONE constructor
--   
--   * @{#AI_PATROLZONE.New}(): Creates a new AI_PATROLZONE object.
-- 
-- ## 1.2) AI_PATROLZONE is a FSM
-- 
-- ![Process](..\Presentations\AI_Patrol\Dia2.JPG)
-- 
-- ### 1.2.1) AI_PATROLZONE States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Returning** ( Group ): The AI is returning to Base..
-- 
-- ### 1.2.2) AI_PATROLZONE Events:
-- 
--   * **Start** ( Group ): Start the process.
--   * **Route** ( Group ): Route the AI to a new random 3D point within the Patrol Zone.
--   * **RTB** ( Group ): Route the AI to the home base.
--   * **Detect** ( Group ): The AI is detecting targets.
--   * **Detected** ( Group ): The AI has detected new targets.
--   * **Status** ( Group ): The AI is checking status (fuel and damage). When the tresholds have been reached, the AI will RTB.
--    
-- ## 1.3) Set or Get the AI controllable
-- 
--   * @{#AI_PATROLZONE.SetControllable}(): Set the AIControllable.
--   * @{#AI_PATROLZONE.GetControllable}(): Get the AIControllable.
--
-- ## 1.4) Set the Speed and Altitude boundaries of the AI controllable
--
--   * @{#AI_PATROLZONE.SetSpeed}(): Set the patrol speed boundaries of the AI, for the next patrol.
--   * @{#AI_PATROLZONE.SetAltitude}(): Set altitude boundaries of the AI, for the next patrol.
-- 
-- ## 1.5) Manage the detection process of the AI controllable
-- 
-- The detection process of the AI controllable can be manipulated.
-- Detection requires an amount of CPU power, which has an impact on your mission performance.
-- Only put detection on when absolutely necessary, and the frequency of the detection can also be set.
-- 
--   * @{#AI_PATROLZONE.SetDetectionOn}(): Set the detection on. The AI will detect for targets.
--   * @{#AI_PATROLZONE.SetDetectionOff}(): Set the detection off, the AI will not detect for targets. The existing target list will NOT be erased.
-- 
-- The detection frequency can be set with @{#AI_PATROLZONE.SetDetectionInterval}( seconds ), where the amount of seconds specify how much seconds will be waited before the next detection.
-- Use the method @{#AI_PATROLZONE.GetDetectedUnits}() to obtain a list of the @{Unit}s detected by the AI.
-- 
-- The detection can be filtered to potential targets in a specific zone.
-- Use the method @{#AI_PATROLZONE.SetDetectionZone}() to set the zone where targets need to be detected.
-- Note that when the zone is too far away, or the AI is not heading towards the zone, or the AI is too high, no targets may be detected
-- according the weather conditions.
-- 
-- ## 1.6) Manage the "out of fuel" in the AI_PATROLZONE
-- 
-- When the AI is out of fuel, it is required that a new AI is started, before the old AI can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the AI will continue for a given time its patrol task in orbit, 
-- while a new AI is targetted to the AI_PATROLZONE.
-- Once the time is finished, the old AI will return to the base.
-- Use the method @{#AI_PATROLZONE.ManageFuel}() to have this proces in place.
-- 
-- ## 1.7) Manage "damage" behaviour of the AI in the AI_PATROLZONE
-- 
-- When the AI is damaged, it is required that a new AIControllable is started. However, damage cannon be foreseen early on. 
-- Therefore, when the damage treshold is reached, the AI will return immediately to the home base (RTB).
-- Use the method @{#AI_PATROLZONE.ManageDamage}() to have this proces in place.
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
-- 2016-01-15: Complete revision. AI_PATROLZONE is the base class for other AI_PATROL like classes.
-- 
-- 2016-09-01: Initial class and API.
-- 
-- ===
-- 
-- # **AUTHORS and CONTRIBUTIONS**
-- 
-- ### Contributions: 
-- 
--   * **[Dutch_Baron](https://forums.eagle.ru/member.php?u=112075)**: Working together with James has resulted in the creation of the AI_BALANCER class. James has shared his ideas on balancing AI with air units, and together we made a first design which you can use now :-)
--   * **[Pikey](https://forums.eagle.ru/member.php?u=62835)**: Testing and API concept review.
-- 
-- ### Authors: 
-- 
--   * **FlightControl**: Design & Programming.
-- 
-- @module AI_Patrol

--- AI_PATROLZONE class
-- @type AI_PATROLZONE
-- @field Wrapper.Controllable#CONTROLLABLE AIControllable The @{Controllable} patrolling.
-- @field Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @field Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @field Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @field Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @field Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @field Functional.Spawn#SPAWN CoordTest
-- @extends Core.Fsm#FSM_CONTROLLABLE
AI_PATROLZONE = {
  ClassName = "AI_PATROLZONE",
}

--- Creates a new AI_PATROLZONE object
-- @param #AI_PATROLZONE self
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @return #AI_PATROLZONE self
-- @usage
-- -- Define a new AI_PATROLZONE Object. This PatrolArea will patrol an AIControllable within PatrolZone between 3000 and 6000 meters, with a variying speed between 600 and 900 km/h.
-- PatrolZone = ZONE:New( 'PatrolZone' )
-- PatrolSpawn = SPAWN:New( 'Patrol Group' )
-- PatrolArea = AI_PATROLZONE:New( PatrolZone, 3000, 6000, 600, 900 )
function AI_PATROLZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed )

  -- Inherits from BASE
  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_PATROLZONE
  
  
  self.PatrolZone = PatrolZone
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
  
  self:SetDetectionOn()

  self.CheckStatus = true
  
  self:ManageFuel( .2, 60 )
  self:ManageDamage( 10 )

  self.DetectedUnits = {} -- This table contains the targets detected during patrol.

  self:SetStartState( "None" ) 

  self:AddTransition( "None", "Start", "Patrolling" )

--- OnBefore Transition Handler for Event Start.
-- @function [parent=#AI_PATROLZONE] OnBeforeStart
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Start.
-- @function [parent=#AI_PATROLZONE] OnAfterStart
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Start.
-- @function [parent=#AI_PATROLZONE] Start
-- @param #AI_PATROLZONE self

--- Asynchronous Event Trigger for Event Start.
-- @function [parent=#AI_PATROLZONE] __Start
-- @param #AI_PATROLZONE self
-- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Patrolling.
-- @function [parent=#AI_PATROLZONE] OnLeavePatrolling
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Patrolling.
-- @function [parent=#AI_PATROLZONE] OnEnterPatrolling
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Patrolling", "Route", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROLZONE.

--- OnBefore Transition Handler for Event Route.
-- @function [parent=#AI_PATROLZONE] OnBeforeRoute
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Route.
-- @function [parent=#AI_PATROLZONE] OnAfterRoute
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Route.
-- @function [parent=#AI_PATROLZONE] Route
-- @param #AI_PATROLZONE self

--- Asynchronous Event Trigger for Event Route.
-- @function [parent=#AI_PATROLZONE] __Route
-- @param #AI_PATROLZONE self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Status", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROLZONE.

--- OnBefore Transition Handler for Event Status.
-- @function [parent=#AI_PATROLZONE] OnBeforeStatus
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Status.
-- @function [parent=#AI_PATROLZONE] OnAfterStatus
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Status.
-- @function [parent=#AI_PATROLZONE] Status
-- @param #AI_PATROLZONE self

--- Asynchronous Event Trigger for Event Status.
-- @function [parent=#AI_PATROLZONE] __Status
-- @param #AI_PATROLZONE self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Detect", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROLZONE.

--- OnBefore Transition Handler for Event Detect.
-- @function [parent=#AI_PATROLZONE] OnBeforeDetect
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Detect.
-- @function [parent=#AI_PATROLZONE] OnAfterDetect
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Detect.
-- @function [parent=#AI_PATROLZONE] Detect
-- @param #AI_PATROLZONE self

--- Asynchronous Event Trigger for Event Detect.
-- @function [parent=#AI_PATROLZONE] __Detect
-- @param #AI_PATROLZONE self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Detected", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROLZONE.

--- OnBefore Transition Handler for Event Detected.
-- @function [parent=#AI_PATROLZONE] OnBeforeDetected
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Detected.
-- @function [parent=#AI_PATROLZONE] OnAfterDetected
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Detected.
-- @function [parent=#AI_PATROLZONE] Detected
-- @param #AI_PATROLZONE self

--- Asynchronous Event Trigger for Event Detected.
-- @function [parent=#AI_PATROLZONE] __Detected
-- @param #AI_PATROLZONE self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "RTB", "RTB" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROLZONE.

--- OnBefore Transition Handler for Event RTB.
-- @function [parent=#AI_PATROLZONE] OnBeforeRTB
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event RTB.
-- @function [parent=#AI_PATROLZONE] OnAfterRTB
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event RTB.
-- @function [parent=#AI_PATROLZONE] RTB
-- @param #AI_PATROLZONE self

--- Asynchronous Event Trigger for Event RTB.
-- @function [parent=#AI_PATROLZONE] __RTB
-- @param #AI_PATROLZONE self
-- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Returning.
-- @function [parent=#AI_PATROLZONE] OnLeaveReturning
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Returning.
-- @function [parent=#AI_PATROLZONE] OnEnterReturning
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
  
  return self
end




--- Sets (modifies) the minimum and maximum speed of the patrol.
-- @param #AI_PATROLZONE self
-- @param Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetSpeed( PatrolMinSpeed, PatrolMaxSpeed )
  self:F2( { PatrolMinSpeed, PatrolMaxSpeed } )
  
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
end



--- Sets the floor and ceiling altitude of the patrol.
-- @param #AI_PATROLZONE self
-- @param Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetAltitude( PatrolFloorAltitude, PatrolCeilingAltitude )
  self:F2( { PatrolFloorAltitude, PatrolCeilingAltitude } )
  
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
end

--   * @{#AI_PATROLZONE.SetDetectionOn}(): Set the detection on. The AI will detect for targets.
--   * @{#AI_PATROLZONE.SetDetectionOff}(): Set the detection off, the AI will not detect for targets. The existing target list will NOT be erased.

--- Set the detection on. The AI will detect for targets.
-- @param #AI_PATROLZONE self
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetDetectionOn()
  self:F2()
  
  self.DetectUnits = true
end

--- Set the detection off. The AI will NOT detect for targets.
-- However, the list of already detected targets will be kept and can be enquired!
-- @param #AI_PATROLZONE self
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetDetectionOff()
  self:F2()
  
  self.DetectUnits = false
end

--- Set the interval in seconds between each detection executed by the AI.
-- The list of already detected targets will be kept and updated.
-- Newly detected targets will be added, but already detected targets that were 
-- not detected in this cycle, will NOT be removed!
-- The default interval is 30 seconds.
-- @param #AI_PATROLZONE self
-- @param #number Seconds The interval in seconds.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetDetectionInterval( Seconds )
  self:F2()

  if Seconds then  
    self.DetectInterval = Seconds
  else
    self.DetectInterval = 30
  end
end

--- Set the detection zone where the AI is detecting targets.
-- @param #AI_PATROLZONE self
-- @param Core.Zone#ZONE DetectionZone The zone where to detect targets.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:SetDetectionZone( DetectionZone )
  self:F2()

  if DetectionZone then  
    self.DetectZone = DetectionZone
  else
    self.DetectZone = nil
  end
end

--- Gets a list of @{Wrapper.Unit#UNIT}s that were detected by the AI.
-- No filtering is applied, so, ANY detected UNIT can be in this list.
-- It is up to the mission designer to use the @{Unit} class and methods to filter the targets.
-- @param #AI_PATROLZONE self
-- @return #table The list of @{Wrapper.Unit#UNIT}s
function AI_PATROLZONE:GetDetectedUnits()
  self:F2()

  return self.DetectedUnits
end


--- When the AI is out of fuel, it is required that a new AI is started, before the old AI can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the AI will continue for a given time its patrol task in orbit, while a new AIControllable is targetted to the AI_PATROLZONE.
-- Once the time is finished, the old AI will return to the base.
-- @param #AI_PATROLZONE self
-- @param #number PatrolFuelTresholdPercentage The treshold in percentage (between 0 and 1) when the AIControllable is considered to get out of fuel.
-- @param #number PatrolOutOfFuelOrbitTime The amount of seconds the out of fuel AIControllable will orbit before returning to the base.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:ManageFuel( PatrolFuelTresholdPercentage, PatrolOutOfFuelOrbitTime )

  self.PatrolManageFuel = true
  self.PatrolFuelTresholdPercentage = PatrolFuelTresholdPercentage
  self.PatrolOutOfFuelOrbitTime = PatrolOutOfFuelOrbitTime
  
  return self
end

--- When the AI is damaged beyond a certain treshold, it is required that the AI returns to the home base.
-- However, damage cannot be foreseen early on. 
-- Therefore, when the damage treshold is reached, 
-- the AI will return immediately to the home base (RTB).
-- Note that for groups, the average damage of the complete group will be calculated.
-- So, in a group of 4 airplanes, 2 lost and 2 with damage 0.2, the damage treshold will be 0.25.
-- @param #AI_PATROLZONE self
-- @param #number PatrolDamageTreshold The treshold in percentage (between 0 and 1) when the AI is considered to be damaged.
-- @return #AI_PATROLZONE self
function AI_PATROLZONE:ManageDamage( PatrolDamageTreshold )

  self.PatrolManageDamage = true
  self.PatrolDamageTreshold = PatrolDamageTreshold
  
  return self
end

--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_PATROLZONE self
-- @return #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_PATROLZONE:onafterStart( Controllable, From, Event, To )
  self:F2()

  self:Route() -- Route to the patrol point.
  self:__Status( 30 ) -- Check status status every 30 seconds.
  self:__Detect( self.DetectInterval ) -- Detect for new targets every 30 seconds.
  
  Controllable:OptionROEHoldFire()
  Controllable:OptionROTVertical()
  
end


--- @param #AI_PATROLZONE self
--- @param Wrapper.Controllable#CONTROLLABLE Controllable
function AI_PATROLZONE:onbeforeDetect( Controllable, From, Event, To )

  return self.DetectUnits
end

--- @param #AI_PATROLZONE self
--- @param Wrapper.Controllable#CONTROLLABLE Controllable
function AI_PATROLZONE:onafterDetect( Controllable, From, Event, To )

  local DetectedTargets = Controllable:GetDetectedTargets()
  for TargetID, Target in pairs( DetectedTargets ) do
    local TargetObject = Target.object
    self:T( TargetObject )
    if TargetObject and TargetObject:isExist() and TargetObject.id_ < 50000000 then

      local TargetUnit = UNIT:Find( TargetObject )
      local TargetUnitName = TargetUnit:GetName()
      
      if self.DetectionZone then
        if TargetUnit:IsInZone( self.DetectionZone ) then
          self:T( {"Detected ", TargetUnit } )
          self.DetectedUnits[TargetUnit] = TargetUnit 
        end
      else
        self.DetectedUnits[TargetUnit] = TargetUnit
      end
    end
  end
  
  self:__Detect( self.DetectInterval )
end

--- @param Wrapper.Controllable#CONTROLLABLE AIControllable
function _NewPatrolRoute( AIControllable )

  AIControllable:T( "NewPatrolRoute" )
  local PatrolZone = AIControllable:GetState( AIControllable, "PatrolZone" ) -- PatrolCore.Zone#AI_PATROLZONE
  PatrolZone:Route()
end


--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_PATROLZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_PATROLZONE:onafterRoute( Controllable, From, Event, To )

  self:F2()

  -- When RTB, don't allow anymore the routing.
  if From == "RTB" then
    return
  end

  
  if self.Controllable:IsAlive() then
    --- Determine if the AIControllable is within the PatrolZone. 
    -- If not, make a waypoint within the to that the AIControllable will fly at maximum speed to that point.
    
    local PatrolRoute = {}

    --- Calculate the current route point.
    local CurrentVec2 = self.Controllable:GetVec2()
    
    --TODO: Create GetAltitude function for GROUP, and delete GetUnit(1).
    local CurrentAltitude = self.Controllable:GetUnit(1):GetAltitude()
    local CurrentPointVec3 = POINT_VEC3:New( CurrentVec2.x, CurrentAltitude, CurrentVec2.y )
    local ToPatrolZoneSpeed = self.PatrolMaxSpeed
    local CurrentRoutePoint = CurrentPointVec3:RoutePointAir( 
        POINT_VEC3.RoutePointAltType.BARO, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        ToPatrolZoneSpeed, 
        true 
      )
    
    PatrolRoute[#PatrolRoute+1] = CurrentRoutePoint
    
    self:T2( PatrolRoute )
  
    if self.Controllable:IsNotInZone( self.PatrolZone ) then
      --- Find a random 2D point in PatrolZone.
      local ToPatrolZoneVec2 = self.PatrolZone:GetRandomVec2()
      self:T2( ToPatrolZoneVec2 )
      
      --- Define Speed and Altitude.
      local ToPatrolZoneAltitude = math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude )
      local ToPatrolZoneSpeed = self.PatrolMaxSpeed
      self:T2( ToPatrolZoneSpeed )
      
      --- Obtain a 3D @{Point} from the 2D point + altitude.
      local ToPatrolZonePointVec3 = POINT_VEC3:New( ToPatrolZoneVec2.x, ToPatrolZoneAltitude, ToPatrolZoneVec2.y )
      
      --- Create a route point of type air.
      local ToPatrolZoneRoutePoint = ToPatrolZonePointVec3:RoutePointAir( 
        POINT_VEC3.RoutePointAltType.BARO, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        ToPatrolZoneSpeed, 
        true 
      )

    PatrolRoute[#PatrolRoute+1] = ToPatrolZoneRoutePoint

    end
    
    --- Define a random point in the @{Zone}. The AI will fly to that point within the zone.
    
      --- Find a random 2D point in PatrolZone.
    local ToTargetVec2 = self.PatrolZone:GetRandomVec2()
    self:T2( ToTargetVec2 )

    --- Define Speed and Altitude.
    local ToTargetAltitude = math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude )
    local ToTargetSpeed = math.random( self.PatrolMinSpeed, self.PatrolMaxSpeed )
    self:T2( { self.PatrolMinSpeed, self.PatrolMaxSpeed, ToTargetSpeed } )
    
    --- Obtain a 3D @{Point} from the 2D point + altitude.
    local ToTargetPointVec3 = POINT_VEC3:New( ToTargetVec2.x, ToTargetAltitude, ToTargetVec2.y )
    
    --- Create a route point of type air.
    local ToTargetRoutePoint = ToTargetPointVec3:RoutePointAir( 
      POINT_VEC3.RoutePointAltType.BARO, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      ToTargetSpeed, 
      true 
    )
    
    --self.CoordTest:SpawnFromVec3( ToTargetPointVec3:GetVec3() )
    
    ToTargetPointVec3:SmokeRed()

    PatrolRoute[#PatrolRoute+1] = ToTargetRoutePoint
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    self.Controllable:WayPointInitialize( PatrolRoute )
    
    --- Do a trick, link the NewPatrolRoute function of the PATROLGROUP object to the AIControllable in a temporary variable ...
    self.Controllable:SetState( self.Controllable, "PatrolZone", self )
    self.Controllable:WayPointFunction( #PatrolRoute, 1, "_NewPatrolRoute" )

    --- NOW ROUTE THE GROUP!
    self.Controllable:WayPointExecute( 1, 2 )
  end

end

--- @param #AI_PATROLZONE self
function AI_PATROLZONE:onbeforeStatus()

  return self.CheckStatus
end

--- @param #AI_PATROLZONE self
function AI_PATROLZONE:onafterStatus()
  self:F2()

  if self.Controllable and self.Controllable:IsAlive() then
  
    local RTB = false
    
    local Fuel = self.Controllable:GetUnit(1):GetFuel()
    if Fuel < self.PatrolFuelTresholdPercentage then
      local OldAIControllable = self.Controllable
      local AIControllableTemplate = self.Controllable:GetTemplate()
      
      local OrbitTask = OldAIControllable:TaskOrbitCircle( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ), self.PatrolMinSpeed )
      local TimedOrbitTask = OldAIControllable:TaskControlled( OrbitTask, OldAIControllable:TaskCondition(nil,nil,nil,nil,self.PatrolOutOfFuelOrbitTime,nil ) )
      OldAIControllable:SetTask( TimedOrbitTask, 10 )

      RTB = true
    else
    end
    
    -- TODO: Check GROUP damage function.
    local Damage = self.Controllable:GetLife()
    if Damage <= self.PatrolDamageTreshold then
      RTB = true
    end
    
    if RTB == true then
      self:__RTB( 1 )
    else
      self:__Status( 30 ) -- Execute the Patrol event after 30 seconds.
    end
  end
end

--- @param #AI_PATROLZONE self
function AI_PATROLZONE:onafterRTB()
  self:F2()

  if self.Controllable and self.Controllable:IsAlive() then

    self:SetDetectionOff()
    self.CheckStatus = false
    
    local PatrolRoute = {}
  
    --- Calculate the current route point.
    local CurrentVec2 = self.Controllable:GetVec2()
    
    --TODO: Create GetAltitude function for GROUP, and delete GetUnit(1).
    local CurrentAltitude = self.Controllable:GetUnit(1):GetAltitude()
    local CurrentPointVec3 = POINT_VEC3:New( CurrentVec2.x, CurrentAltitude, CurrentVec2.y )
    local ToPatrolZoneSpeed = self.PatrolMaxSpeed
    local CurrentRoutePoint = CurrentPointVec3:RoutePointAir( 
        POINT_VEC3.RoutePointAltType.BARO, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        ToPatrolZoneSpeed, 
        true 
      )
    
    PatrolRoute[#PatrolRoute+1] = CurrentRoutePoint
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    self.Controllable:WayPointInitialize( PatrolRoute )
  
    --- NOW ROUTE THE GROUP!
    self.Controllable:WayPointExecute( 1, 1 )
    
  end
    
end