--- **AI** -- Perform Air Patrolling for airplanes.
-- 
-- **Features:**
-- 
--   * Patrol AI airplanes within a given zone.
--   * Trigger detected events when enemy airplanes are detected.
--   * Manage a fuel treshold to RTB on time.
-- 
-- ===
-- 
-- AI PATROL classes makes AI Controllables execute an Patrol.
-- 
-- There are the following types of PATROL classes defined:
-- 
--   * @{#AI_PATROL_ZONE}: Perform a PATROL in a zone.
--   
-- ===
-- 
-- ### [Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release/PAT%20-%20Patrolling)
-- 
-- ===
-- 
-- ### [YouTube Playlist](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl35HvYZKA6G22WMt7iI3zky)
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: 
-- 
--   * **[Dutch_Baron](https://forums.eagle.ru/member.php?u=112075)**: Working together with James has resulted in the creation of the AI_BALANCER class. James has shared his ideas on balancing AI with air units, and together we made a first design which you can use now :-)
--   * **[Pikey](https://forums.eagle.ru/member.php?u=62835)**: Testing and API concept review.
-- 
-- ===
-- 
-- @module AI.AI_Patrol
-- @image AI_Air_Patrolling.JPG

--- AI_PATROL_ZONE class
-- @type AI_PATROL_ZONE
-- @field Wrapper.Controllable#CONTROLLABLE AIControllable The @{Wrapper.Controllable} patrolling.
-- @field Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @field DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @field DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @field DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Controllable} in km/h.
-- @field DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Controllable} in km/h.
-- @field Core.Spawn#SPAWN CoordTest
-- @extends Core.Fsm#FSM_CONTROLLABLE

--- Implements the core functions to patrol a @{Zone} by an AI @{Wrapper.Controllable} or @{Wrapper.Group}.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia3.JPG)
-- 
-- The AI_PATROL_ZONE is assigned a @{Wrapper.Group} and this must be done before the AI_PATROL_ZONE process can be started using the **Start** event.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia4.JPG)
-- 
-- The AI will fly towards the random 3D point within the patrol zone, using a random speed within the given altitude and speed limits.
-- Upon arrival at the 3D point, a new random 3D point will be selected within the patrol zone using the given limits.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia5.JPG)
-- 
-- This cycle will continue.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia6.JPG)
-- 
-- During the patrol, the AI will detect enemy targets, which are reported through the **Detected** event.
--
-- ![Process](..\Presentations\AI_PATROL\Dia9.JPG)
-- 
---- Note that the enemy is not engaged! To model enemy engagement, either tailor the **Detected** event, or
-- use derived AI_ classes to model AI offensive or defensive behaviour.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia10.JPG)
-- 
-- Until a fuel or damage treshold has been reached by the AI, or when the AI is commanded to RTB.
-- When the fuel treshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia11.JPG)
-- 
-- ## 1. AI_PATROL_ZONE constructor
--   
--   * @{#AI_PATROL_ZONE.New}(): Creates a new AI_PATROL_ZONE object.
-- 
-- ## 2. AI_PATROL_ZONE is a FSM
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia2.JPG)
-- 
-- ### 2.1. AI_PATROL_ZONE States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Returning** ( Group ): The AI is returning to Base.
--   * **Stopped** ( Group ): The process is stopped.
--   * **Crashed** ( Group ): The AI has crashed or is dead.
-- 
-- ### 2.2. AI_PATROL_ZONE Events
-- 
--   * **Start** ( Group ): Start the process.
--   * **Stop** ( Group ): Stop the process.
--   * **Route** ( Group ): Route the AI to a new random 3D point within the Patrol Zone.
--   * **RTB** ( Group ): Route the AI to the home base.
--   * **Detect** ( Group ): The AI is detecting targets.
--   * **Detected** ( Group ): The AI has detected new targets.
--   * **Status** ( Group ): The AI is checking status (fuel and damage). When the tresholds have been reached, the AI will RTB.
--    
-- ## 3. Set or Get the AI controllable
-- 
--   * @{#AI_PATROL_ZONE.SetControllable}(): Set the AIControllable.
--   * @{#AI_PATROL_ZONE.GetControllable}(): Get the AIControllable.
--
-- ## 4. Set the Speed and Altitude boundaries of the AI controllable
--
--   * @{#AI_PATROL_ZONE.SetSpeed}(): Set the patrol speed boundaries of the AI, for the next patrol.
--   * @{#AI_PATROL_ZONE.SetAltitude}(): Set altitude boundaries of the AI, for the next patrol.
-- 
-- ## 5. Manage the detection process of the AI controllable
-- 
-- The detection process of the AI controllable can be manipulated.
-- Detection requires an amount of CPU power, which has an impact on your mission performance.
-- Only put detection on when absolutely necessary, and the frequency of the detection can also be set.
-- 
--   * @{#AI_PATROL_ZONE.SetDetectionOn}(): Set the detection on. The AI will detect for targets.
--   * @{#AI_PATROL_ZONE.SetDetectionOff}(): Set the detection off, the AI will not detect for targets. The existing target list will NOT be erased.
-- 
-- The detection frequency can be set with @{#AI_PATROL_ZONE.SetRefreshTimeInterval}( seconds ), where the amount of seconds specify how much seconds will be waited before the next detection.
-- Use the method @{#AI_PATROL_ZONE.GetDetectedUnits}() to obtain a list of the @{Wrapper.Unit}s detected by the AI.
-- 
-- The detection can be filtered to potential targets in a specific zone.
-- Use the method @{#AI_PATROL_ZONE.SetDetectionZone}() to set the zone where targets need to be detected.
-- Note that when the zone is too far away, or the AI is not heading towards the zone, or the AI is too high, no targets may be detected
-- according the weather conditions.
-- 
-- ## 6. Manage the "out of fuel" in the AI_PATROL_ZONE
-- 
-- When the AI is out of fuel, it is required that a new AI is started, before the old AI can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the AI will continue for a given time its patrol task in orbit, 
-- while a new AI is targetted to the AI_PATROL_ZONE.
-- Once the time is finished, the old AI will return to the base.
-- Use the method @{#AI_PATROL_ZONE.ManageFuel}() to have this proces in place.
-- 
-- ## 7. Manage "damage" behaviour of the AI in the AI_PATROL_ZONE
-- 
-- When the AI is damaged, it is required that a new AIControllable is started. However, damage cannon be foreseen early on. 
-- Therefore, when the damage treshold is reached, the AI will return immediately to the home base (RTB).
-- Use the method @{#AI_PATROL_ZONE.ManageDamage}() to have this proces in place.
-- 
-- ===
-- 
-- @field #AI_PATROL_ZONE
AI_PATROL_ZONE = {
  ClassName = "AI_PATROL_ZONE",
}

--- Creates a new AI_PATROL_ZONE object
-- @param #AI_PATROL_ZONE self
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Controllable} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Controllable} in km/h.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_PATROL_ZONE self
-- @usage
-- -- Define a new AI_PATROL_ZONE Object. This PatrolArea will patrol an AIControllable within PatrolZone between 3000 and 6000 meters, with a variying speed between 600 and 900 km/h.
-- PatrolZone = ZONE:New( 'PatrolZone' )
-- PatrolSpawn = SPAWN:New( 'Patrol Group' )
-- PatrolArea = AI_PATROL_ZONE:New( PatrolZone, 3000, 6000, 600, 900 )
function AI_PATROL_ZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_PATROL_ZONE
  
  
  self.PatrolZone = PatrolZone
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
  
  -- defafult PatrolAltType to "BARO" if not specified
  self.PatrolAltType = PatrolAltType or "BARO"
  
  self:SetRefreshTimeInterval( 30 )
  
  self.CheckStatus = true
  
  self:ManageFuel( .2, 60 )
  self:ManageDamage( 1 )
  

  self.DetectedUnits = {} -- This table contains the targets detected during patrol.
  
  self:SetStartState( "None" ) 

  self:AddTransition( "*", "Stop", "Stopped" )

--- OnLeave Transition Handler for State Stopped.
-- @function [parent=#AI_PATROL_ZONE] OnLeaveStopped
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Stopped.
-- @function [parent=#AI_PATROL_ZONE] OnEnterStopped
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

--- OnBefore Transition Handler for Event Stop.
-- @function [parent=#AI_PATROL_ZONE] OnBeforeStop
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Stop.
-- @function [parent=#AI_PATROL_ZONE] OnAfterStop
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Stop.
-- @function [parent=#AI_PATROL_ZONE] Stop
-- @param #AI_PATROL_ZONE self

--- Asynchronous Event Trigger for Event Stop.
-- @function [parent=#AI_PATROL_ZONE] __Stop
-- @param #AI_PATROL_ZONE self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "None", "Start", "Patrolling" )

--- OnBefore Transition Handler for Event Start.
-- @function [parent=#AI_PATROL_ZONE] OnBeforeStart
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Start.
-- @function [parent=#AI_PATROL_ZONE] OnAfterStart
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Start.
-- @function [parent=#AI_PATROL_ZONE] Start
-- @param #AI_PATROL_ZONE self

--- Asynchronous Event Trigger for Event Start.
-- @function [parent=#AI_PATROL_ZONE] __Start
-- @param #AI_PATROL_ZONE self
-- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Patrolling.
-- @function [parent=#AI_PATROL_ZONE] OnLeavePatrolling
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Patrolling.
-- @function [parent=#AI_PATROL_ZONE] OnEnterPatrolling
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Patrolling", "Route", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROL_ZONE.

--- OnBefore Transition Handler for Event Route.
-- @function [parent=#AI_PATROL_ZONE] OnBeforeRoute
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Route.
-- @function [parent=#AI_PATROL_ZONE] OnAfterRoute
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Route.
-- @function [parent=#AI_PATROL_ZONE] Route
-- @param #AI_PATROL_ZONE self

--- Asynchronous Event Trigger for Event Route.
-- @function [parent=#AI_PATROL_ZONE] __Route
-- @param #AI_PATROL_ZONE self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Status", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROL_ZONE.

--- OnBefore Transition Handler for Event Status.
-- @function [parent=#AI_PATROL_ZONE] OnBeforeStatus
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Status.
-- @function [parent=#AI_PATROL_ZONE] OnAfterStatus
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Status.
-- @function [parent=#AI_PATROL_ZONE] Status
-- @param #AI_PATROL_ZONE self

--- Asynchronous Event Trigger for Event Status.
-- @function [parent=#AI_PATROL_ZONE] __Status
-- @param #AI_PATROL_ZONE self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Detect", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROL_ZONE.

--- OnBefore Transition Handler for Event Detect.
-- @function [parent=#AI_PATROL_ZONE] OnBeforeDetect
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Detect.
-- @function [parent=#AI_PATROL_ZONE] OnAfterDetect
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Detect.
-- @function [parent=#AI_PATROL_ZONE] Detect
-- @param #AI_PATROL_ZONE self

--- Asynchronous Event Trigger for Event Detect.
-- @function [parent=#AI_PATROL_ZONE] __Detect
-- @param #AI_PATROL_ZONE self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Detected", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROL_ZONE.

--- OnBefore Transition Handler for Event Detected.
-- @function [parent=#AI_PATROL_ZONE] OnBeforeDetected
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Detected.
-- @function [parent=#AI_PATROL_ZONE] OnAfterDetected
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Detected.
-- @function [parent=#AI_PATROL_ZONE] Detected
-- @param #AI_PATROL_ZONE self

--- Asynchronous Event Trigger for Event Detected.
-- @function [parent=#AI_PATROL_ZONE] __Detected
-- @param #AI_PATROL_ZONE self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "RTB", "Returning" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROL_ZONE.

--- OnBefore Transition Handler for Event RTB.
-- @function [parent=#AI_PATROL_ZONE] OnBeforeRTB
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event RTB.
-- @function [parent=#AI_PATROL_ZONE] OnAfterRTB
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event RTB.
-- @function [parent=#AI_PATROL_ZONE] RTB
-- @param #AI_PATROL_ZONE self

--- Asynchronous Event Trigger for Event RTB.
-- @function [parent=#AI_PATROL_ZONE] __RTB
-- @param #AI_PATROL_ZONE self
-- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Returning.
-- @function [parent=#AI_PATROL_ZONE] OnLeaveReturning
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Returning.
-- @function [parent=#AI_PATROL_ZONE] OnEnterReturning
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "*", "Reset", "Patrolling" ) -- FSM_CONTROLLABLE Transition for type #AI_PATROL_ZONE.
  
  self:AddTransition( "*", "Eject", "*" )
  self:AddTransition( "*", "Crash", "Crashed" )
  self:AddTransition( "*", "PilotDead", "*" )
  
  return self
end




--- Sets (modifies) the minimum and maximum speed of the patrol.
-- @param #AI_PATROL_ZONE self
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Controllable} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Controllable} in km/h.
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:SetSpeed( PatrolMinSpeed, PatrolMaxSpeed )
  self:F2( { PatrolMinSpeed, PatrolMaxSpeed } )
  
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
end



--- Sets the floor and ceiling altitude of the patrol.
-- @param #AI_PATROL_ZONE self
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:SetAltitude( PatrolFloorAltitude, PatrolCeilingAltitude )
  self:F2( { PatrolFloorAltitude, PatrolCeilingAltitude } )
  
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
end

--   * @{#AI_PATROL_ZONE.SetDetectionOn}(): Set the detection on. The AI will detect for targets.
--   * @{#AI_PATROL_ZONE.SetDetectionOff}(): Set the detection off, the AI will not detect for targets. The existing target list will NOT be erased.

--- Set the detection on. The AI will detect for targets.
-- @param #AI_PATROL_ZONE self
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:SetDetectionOn()
  self:F2()

  self.DetectOn = true
end

--- Set the detection off. The AI will NOT detect for targets.
-- However, the list of already detected targets will be kept and can be enquired!
-- @param #AI_PATROL_ZONE self
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:SetDetectionOff()
  self:F2()

  self.DetectOn = false
end

--- Set the status checking off.
-- @param #AI_PATROL_ZONE self
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:SetStatusOff()
  self:F2()
  
  self.CheckStatus = false
end

--- Activate the detection. The AI will detect for targets if the Detection is switched On.
-- @param #AI_PATROL_ZONE self
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:SetDetectionActivated()
  self:F2()
  
  self:ClearDetectedUnits()
  self.DetectActivated = true
  self:__Detect( -self.DetectInterval )
end

--- Deactivate the detection. The AI will NOT detect for targets.
-- @param #AI_PATROL_ZONE self
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:SetDetectionDeactivated()
  self:F2()
  
  self:ClearDetectedUnits()
  self.DetectActivated = false
end

--- Set the interval in seconds between each detection executed by the AI.
-- The list of already detected targets will be kept and updated.
-- Newly detected targets will be added, but already detected targets that were 
-- not detected in this cycle, will NOT be removed!
-- The default interval is 30 seconds.
-- @param #AI_PATROL_ZONE self
-- @param #number Seconds The interval in seconds.
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:SetRefreshTimeInterval( Seconds )
  self:F2()

  if Seconds then  
    self.DetectInterval = Seconds
  else
    self.DetectInterval = 30
  end
end

--- Set the detection zone where the AI is detecting targets.
-- @param #AI_PATROL_ZONE self
-- @param Core.Zone#ZONE DetectionZone The zone where to detect targets.
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:SetDetectionZone( DetectionZone )
  self:F2()

  if DetectionZone then  
    self.DetectZone = DetectionZone
  else
    self.DetectZone = nil
  end
end

--- Gets a list of @{Wrapper.Unit#UNIT}s that were detected by the AI.
-- No filtering is applied, so, ANY detected UNIT can be in this list.
-- It is up to the mission designer to use the @{Wrapper.Unit} class and methods to filter the targets.
-- @param #AI_PATROL_ZONE self
-- @return #table The list of @{Wrapper.Unit#UNIT}s
function AI_PATROL_ZONE:GetDetectedUnits()
  self:F2()

  return self.DetectedUnits 
end

--- Clears the list of @{Wrapper.Unit#UNIT}s that were detected by the AI.
-- @param #AI_PATROL_ZONE self
function AI_PATROL_ZONE:ClearDetectedUnits()
  self:F2()
  self.DetectedUnits = {}
end

--- When the AI is out of fuel, it is required that a new AI is started, before the old AI can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the AI will continue for a given time its patrol task in orbit, while a new AIControllable is targetted to the AI_PATROL_ZONE.
-- Once the time is finished, the old AI will return to the base.
-- @param #AI_PATROL_ZONE self
-- @param #number PatrolFuelThresholdPercentage The treshold in percentage (between 0 and 1) when the AIControllable is considered to get out of fuel.
-- @param #number PatrolOutOfFuelOrbitTime The amount of seconds the out of fuel AIControllable will orbit before returning to the base.
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:ManageFuel( PatrolFuelThresholdPercentage, PatrolOutOfFuelOrbitTime )

  self.PatrolFuelThresholdPercentage = PatrolFuelThresholdPercentage
  self.PatrolOutOfFuelOrbitTime = PatrolOutOfFuelOrbitTime
  
  return self
end

--- When the AI is damaged beyond a certain treshold, it is required that the AI returns to the home base.
-- However, damage cannot be foreseen early on. 
-- Therefore, when the damage treshold is reached, 
-- the AI will return immediately to the home base (RTB).
-- Note that for groups, the average damage of the complete group will be calculated.
-- So, in a group of 4 airplanes, 2 lost and 2 with damage 0.2, the damage treshold will be 0.25.
-- @param #AI_PATROL_ZONE self
-- @param #number PatrolDamageThreshold The treshold in percentage (between 0 and 1) when the AI is considered to be damaged.
-- @return #AI_PATROL_ZONE self
function AI_PATROL_ZONE:ManageDamage( PatrolDamageThreshold )

  self.PatrolManageDamage = true
  self.PatrolDamageThreshold = PatrolDamageThreshold
  
  return self
end

--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_PATROL_ZONE self
-- @return #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_PATROL_ZONE:onafterStart( Controllable, From, Event, To )
  self:F2()

  self:__Route( 1 ) -- Route to the patrol point. The asynchronous trigger is important, because a spawned group and units takes at least one second to come live.
  self:__Status( 60 ) -- Check status status every 30 seconds.
  self:SetDetectionActivated()
  
  self:HandleEvent( EVENTS.PilotDead, self.OnPilotDead )
  self:HandleEvent( EVENTS.Crash, self.OnCrash )
  self:HandleEvent( EVENTS.Ejection, self.OnEjection )
  
  Controllable:OptionROEHoldFire()
  Controllable:OptionROTVertical()

  self.Controllable:OnReSpawn(
    function( PatrolGroup )
      self:T( "ReSpawn" )
      self:__Reset( 1 )
      self:__Route( 5 )
    end
  )

  self:SetDetectionOn()
  
end


--- @param #AI_PATROL_ZONE self
--- @param Wrapper.Controllable#CONTROLLABLE Controllable
function AI_PATROL_ZONE:onbeforeDetect( Controllable, From, Event, To )

  return self.DetectOn and self.DetectActivated
end

--- @param #AI_PATROL_ZONE self
--- @param Wrapper.Controllable#CONTROLLABLE Controllable
function AI_PATROL_ZONE:onafterDetect( Controllable, From, Event, To )

  local Detected = false

  local DetectedTargets = Controllable:GetDetectedTargets()
  for TargetID, Target in pairs( DetectedTargets or {} ) do
    local TargetObject = Target.object

    if TargetObject and TargetObject:isExist() and TargetObject.id_ < 50000000 then

      local TargetUnit = UNIT:Find( TargetObject )
      
      -- Check that target is alive due to issue https://github.com/FlightControl-Master/MOOSE/issues/1234
      if TargetUnit and TargetUnit:IsAlive() then
      
        local TargetUnitName = TargetUnit:GetName()
        
        if self.DetectionZone then
          if TargetUnit:IsInZone( self.DetectionZone ) then
            self:T( {"Detected ", TargetUnit } )
            if self.DetectedUnits[TargetUnit] == nil then
              self.DetectedUnits[TargetUnit] = true
            end
            Detected = true 
          end
        else       
          if self.DetectedUnits[TargetUnit] == nil then
            self.DetectedUnits[TargetUnit] = true
          end
          Detected = true
        end
        
      end
    end
  end

  self:__Detect( -self.DetectInterval )
  
  if Detected == true then
    self:__Detected( 1.5 )
  end
  
end

--- @param Wrapper.Controllable#CONTROLLABLE AIControllable
-- This statis method is called from the route path within the last task at the last waaypoint of the Controllable.
-- Note that this method is required, as triggers the next route when patrolling for the Controllable.
function AI_PATROL_ZONE:_NewPatrolRoute( AIControllable )

  local PatrolZone = AIControllable:GetState( AIControllable, "PatrolZone" ) -- PatrolCore.Zone#AI_PATROL_ZONE
  PatrolZone:__Route( 1 )
end


--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_PATROL_ZONE self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_PATROL_ZONE:onafterRoute( Controllable, From, Event, To )

  self:F2()

  -- When RTB, don't allow anymore the routing.
  if From == "RTB" then
    return
  end

  
  if self.Controllable:IsAlive() then
    -- Determine if the AIControllable is within the PatrolZone. 
    -- If not, make a waypoint within the to that the AIControllable will fly at maximum speed to that point.
    
    local PatrolRoute = {}

    -- Calculate the current route point of the controllable as the start point of the route.
    -- However, when the controllable is not in the air,
    -- the controllable current waypoint is probably the airbase...
    -- Thus, if we would take the current waypoint as the startpoint, upon take-off, the controllable flies
    -- immediately back to the airbase, and this is not correct.
    -- Therefore, when on a runway, get as the current route point a random point within the PatrolZone.
    -- This will make the plane fly immediately to the patrol zone.
    
    if self.Controllable:InAir() == false then
      self:T( "Not in the air, finding route path within PatrolZone" )
      local CurrentVec2 = self.Controllable:GetVec2()
      --TODO: Create GetAltitude function for GROUP, and delete GetUnit(1).
      local CurrentAltitude = self.Controllable:GetUnit(1):GetAltitude()
      local CurrentPointVec3 = POINT_VEC3:New( CurrentVec2.x, CurrentAltitude, CurrentVec2.y )
      local ToPatrolZoneSpeed = self.PatrolMaxSpeed
      local CurrentRoutePoint = CurrentPointVec3:WaypointAir( 
          self.PatrolAltType, 
          POINT_VEC3.RoutePointType.TakeOffParking, 
          POINT_VEC3.RoutePointAction.FromParkingArea, 
          ToPatrolZoneSpeed, 
          true 
        )
      PatrolRoute[#PatrolRoute+1] = CurrentRoutePoint
    else
      self:T( "In the air, finding route path within PatrolZone" )
      local CurrentVec2 = self.Controllable:GetVec2()
      --TODO: Create GetAltitude function for GROUP, and delete GetUnit(1).
      local CurrentAltitude = self.Controllable:GetUnit(1):GetAltitude()
      local CurrentPointVec3 = POINT_VEC3:New( CurrentVec2.x, CurrentAltitude, CurrentVec2.y )
      local ToPatrolZoneSpeed = self.PatrolMaxSpeed
      local CurrentRoutePoint = CurrentPointVec3:WaypointAir( 
          self.PatrolAltType, 
          POINT_VEC3.RoutePointType.TurningPoint, 
          POINT_VEC3.RoutePointAction.TurningPoint, 
          ToPatrolZoneSpeed, 
          true 
        )
      PatrolRoute[#PatrolRoute+1] = CurrentRoutePoint
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
    local ToTargetRoutePoint = ToTargetPointVec3:WaypointAir( 
      self.PatrolAltType, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      ToTargetSpeed, 
      true 
    )
    
    --self.CoordTest:SpawnFromVec3( ToTargetPointVec3:GetVec3() )
    
    --ToTargetPointVec3:SmokeRed()

    PatrolRoute[#PatrolRoute+1] = ToTargetRoutePoint
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    self.Controllable:WayPointInitialize( PatrolRoute )
    
    --- Do a trick, link the NewPatrolRoute function of the PATROLGROUP object to the AIControllable in a temporary variable ...
    self.Controllable:SetState( self.Controllable, "PatrolZone", self )
    self.Controllable:WayPointFunction( #PatrolRoute, 1, "AI_PATROL_ZONE:_NewPatrolRoute" )

    --- NOW ROUTE THE GROUP!
    self.Controllable:WayPointExecute( 1, 2 )
  end

end

--- @param #AI_PATROL_ZONE self
function AI_PATROL_ZONE:onbeforeStatus()

  return self.CheckStatus
end

--- @param #AI_PATROL_ZONE self
function AI_PATROL_ZONE:onafterStatus()
  self:F2()

  if self.Controllable and self.Controllable:IsAlive() then
  
    local RTB = false
    
    local Fuel = self.Controllable:GetFuelMin()
    if Fuel < self.PatrolFuelThresholdPercentage then
      self:I( self.Controllable:GetName() .. " is out of fuel:" .. Fuel .. ", RTB!" )
      local OldAIControllable = self.Controllable
      
      local OrbitTask = OldAIControllable:TaskOrbitCircle( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ), self.PatrolMinSpeed )
      local TimedOrbitTask = OldAIControllable:TaskControlled( OrbitTask, OldAIControllable:TaskCondition(nil,nil,nil,nil,self.PatrolOutOfFuelOrbitTime,nil ) )
      OldAIControllable:SetTask( TimedOrbitTask, 10 )

      RTB = true
    else
    end
    
    -- TODO: Check GROUP damage function.
    local Damage = self.Controllable:GetLife()
    if Damage <= self.PatrolDamageThreshold then
      self:I( self.Controllable:GetName() .. " is damaged:" .. Damage .. ", RTB!" )
      RTB = true
    end
    
    if RTB == true then
      self:RTB()
    else
      self:__Status( 60 ) -- Execute the Patrol event after 30 seconds.
    end
  end
end

--- @param #AI_PATROL_ZONE self
function AI_PATROL_ZONE:onafterRTB()
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
    local CurrentRoutePoint = CurrentPointVec3:WaypointAir( 
        self.PatrolAltType, 
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

--- @param #AI_PATROL_ZONE self
function AI_PATROL_ZONE:onafterDead()
  self:SetDetectionOff()
  self:SetStatusOff()
end

--- @param #AI_PATROL_ZONE self
-- @param Core.Event#EVENTDATA EventData
function AI_PATROL_ZONE:OnCrash( EventData )

  if self.Controllable:IsAlive() and EventData.IniDCSGroupName == self.Controllable:GetName() then
    if #self.Controllable:GetUnits() == 1 then
      self:__Crash( 1, EventData )
    end
  end
end

--- @param #AI_PATROL_ZONE self
-- @param Core.Event#EVENTDATA EventData
function AI_PATROL_ZONE:OnEjection( EventData )

  if self.Controllable:IsAlive() and EventData.IniDCSGroupName == self.Controllable:GetName() then
    self:__Eject( 1, EventData )
  end
end

--- @param #AI_PATROL_ZONE self
-- @param Core.Event#EVENTDATA EventData
function AI_PATROL_ZONE:OnPilotDead( EventData )

  if self.Controllable:IsAlive() and EventData.IniDCSGroupName == self.Controllable:GetName() then
    self:__PilotDead( 1, EventData )
  end
end
