--- **AI** -- (R2.2) - Models the process of Ground Controlled Interception (GCI) for airplanes.
--
-- This is a class used in the @{AI_A2A_Dispatcher}.
--
-- ===
--
-- ### Author: **FlightControl**
--
-- ===
--
-- @module AI.AI_A2A_GCI
-- @image AI_Ground_Control_Intercept.JPG



--- @type AI_A2A_GCI
-- @extends AI.AI_A2A#AI_A2A


--- Implements the core functions to intercept intruders. Use the Engage trigger to intercept intruders.
--
-- ![Process](..\Presentations\AI_GCI\Dia3.JPG)
--
-- The AI_A2A_GCI is assigned a @{Wrapper.Group} and this must be done before the AI_A2A_GCI process can be started using the **Start** event.
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
-- ## 1. AI_A2A_GCI constructor
--
--   * @{#AI_A2A_GCI.New}(): Creates a new AI_A2A_GCI object.
--
-- ## 2. AI_A2A_GCI is a FSM
--
-- ![Process](..\Presentations\AI_GCI\Dia2.JPG)
--
-- ### 2.1 AI_A2A_GCI States
--
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Engaging** ( Group ): The AI is engaging the bogeys.
--   * **Returning** ( Group ): The AI is returning to Base..
--
-- ### 2.2 AI_A2A_GCI Events
--
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Route}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_A2A_GCI.Engage}**: Let the AI engage the bogeys.
--   * **@{#AI_A2A_GCI.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_A2A_GCI.Destroy}**: The AI has destroyed a bogey @{Wrapper.Unit}.
--   * **@{#AI_A2A_GCI.Destroyed}**: The AI has destroyed all bogeys @{Wrapper.Unit}s assigned in the CAS task.
--   * **Status** ( Group ): The AI is checking status (fuel and damage). When the tresholds have been reached, the AI will RTB.
--
-- ## 3. Set the Range of Engagement
--
-- ![Range](..\Presentations\AI_GCI\Dia11.JPG)
--
-- An optional range can be set in meters,
-- that will define when the AI will engage with the detected airborne enemy targets.
-- The range can be beyond or smaller than the range of the Patrol Zone.
-- The range is applied at the position of the AI.
-- Use the method @{AI.AI_GCI#AI_A2A_GCI.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
--
-- ![Zone](..\Presentations\AI_GCI\Dia12.JPG)
--
-- An optional @{Zone} can be set,
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_A2A_GCI.SetEngageZone}() to define that Zone.
--
-- ===
--
-- @field #AI_A2A_GCI
AI_A2A_GCI = {
  ClassName = "AI_A2A_GCI",
}



--- Creates a new AI_A2A_GCI object
-- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude The highest altitude in meters where to execute the engagement.
-- @param DCS#AltitudeType EngageAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to "RADIO".
-- @return #AI_A2A_GCI
function AI_A2A_GCI:New2( AIIntercept, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )

  local AI_Air = AI_AIR:New( AIIntercept )
  local AI_Air_Engage = AI_AIR_ENGAGE:New( AI_Air, AIIntercept, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
  local self = BASE:Inherit( self, AI_Air_Engage ) -- #AI_A2A_GCI

  self:SetFuelThreshold( .2, 60 )
  self:SetDamageThreshold( 0.4 )
  self:SetDisengageRadius( 70000 )

  return self
end

--- Creates a new AI_A2A_GCI object
-- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude The highest altitude in meters where to execute the engagement.
-- @param DCS#AltitudeType EngageAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to "RADIO".
-- @return #AI_A2A_GCI
function AI_A2A_GCI:New( AIIntercept, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )

  return self:New2( AIIntercept, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
end

--- onafter State Transition for Event Patrol.
-- @param #AI_A2A_GCI self
-- @param Wrapper.Group#GROUP AIIntercept The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_GCI:onafterStart( AIIntercept, From, Event, To )

  self:GetParent( self, AI_A2A_GCI ).onafterStart( self, AIIntercept, From, Event, To )
end


--- Evaluate the attack and create an AttackUnitTask list.
-- @param #AI_A2A_GCI self
-- @param Core.Set#SET_UNIT AttackSetUnit The set of units to attack.
-- @param Wrappper.Group#GROUP DefenderGroup The group of defenders.
-- @param #number EngageAltitude The altitude to engage the targets.
-- @return #AI_A2A_GCI self
function AI_A2A_GCI:CreateAttackUnitTasks( AttackSetUnit, DefenderGroup, EngageAltitude )

  local AttackUnitTasks = {}

  for AttackUnitID, AttackUnit in pairs( self.AttackSetUnit:GetSet() ) do
    local AttackUnit = AttackUnit -- Wrapper.Unit#UNIT
    self:T( { "Attacking Unit:", AttackUnit:GetName(), AttackUnit:IsAlive(), AttackUnit:IsAir() } )
    if AttackUnit:IsAlive() and AttackUnit:IsAir() then
      -- TODO: Add coalition check? Only attack units of if AttackUnit:GetCoalition()~=AICap:GetCoalition()
      -- Maybe the detected set also contains
      AttackUnitTasks[#AttackUnitTasks+1] = DefenderGroup:TaskAttackUnit( AttackUnit )
    end
  end

  return AttackUnitTasks
end
