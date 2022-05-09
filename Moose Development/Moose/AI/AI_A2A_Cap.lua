--- **AI** -- (R2.2) - Models the process of Combat Air Patrol (CAP) for airplanes.
--
-- ===
--
-- ### Author: **FlightControl**
--
-- ===
--
-- @module AI.AI_A2A_Cap
-- @image AI_Combat_Air_Patrol.JPG

--- @type AI_A2A_CAP
-- @extends AI.AI_Air_Patrol#AI_AIR_PATROL
-- @extends AI.AI_Air_Engage#AI_AIR_ENGAGE


--- The AI_A2A_CAP class implements the core functions to patrol a @{Zone} by an AI @{Wrapper.Group} or @{Wrapper.Group}
-- and automatically engage any airborne enemies that are within a certain range or within a certain zone.
--
-- ![Process](..\Presentations\AI_CAP\Dia3.JPG)
--
-- The AI_A2A_CAP is assigned a @{Wrapper.Group} and this must be done before the AI_A2A_CAP process can be started using the **Start** event.
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
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Start}**: Start the process.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Route}**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **@{#AI_A2A_CAP.Engage}**: Let the AI engage the bogeys.
--   * **@{#AI_A2A_CAP.Abort}**: Aborts the engagement and return patrolling in the patrol zone.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.RTB}**: Route the AI to the home base.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detect}**: The AI is detecting targets.
--   * **@{AI.AI_Patrol#AI_PATROL_ZONE.Detected}**: The AI has detected new targets.
--   * **@{#AI_A2A_CAP.Destroy}**: The AI has destroyed a bogey @{Wrapper.Unit}.
--   * **@{#AI_A2A_CAP.Destroyed}**: The AI has destroyed all bogeys @{Wrapper.Unit}s assigned in the CAS task.
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
-- Use the method @{AI.AI_CAP#AI_A2A_CAP.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
--
-- ![Zone](..\Presentations\AI_CAP\Dia12.JPG)
--
-- An optional @{Zone} can be set,
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_A2A_CAP.SetEngageZone}() to define that Zone.
--
-- ===
--
-- @field #AI_A2A_CAP
AI_A2A_CAP = {
  ClassName = "AI_A2A_CAP",
}

--- Creates a new AI_A2A_CAP object
-- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude The highest altitude in meters where to execute the engagement.
-- @param DCS#AltitudeType EngageAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to "RADIO".
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to "RADIO".
-- @return #AI_A2A_CAP
function AI_A2A_CAP:New2( AICap, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType, PatrolZone, PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType )

  -- Multiple inheritance ... :-)
  local AI_Air = AI_AIR:New( AICap )
  local AI_Air_Patrol = AI_AIR_PATROL:New( AI_Air, AICap, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType ) -- #AI_AIR_PATROL
  local AI_Air_Engage = AI_AIR_ENGAGE:New( AI_Air_Patrol, AICap, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
  local self = BASE:Inherit( self, AI_Air_Engage ) --#AI_A2A_CAP

  self:SetFuelThreshold( .2, 60 )
  self:SetDamageThreshold( 0.4 )
  self:SetDisengageRadius( 70000 )


  return self
end

--- Creates a new AI_A2A_CAP object
-- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_A2A_CAP
function AI_A2A_CAP:New( AICap, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, PatrolAltType )

  return self:New2( AICap, EngageMinSpeed, EngageMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType, PatrolZone, PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType )

end

--- onafter State Transition for Event Patrol.
-- @param #AI_A2A_CAP self
-- @param Wrapper.Group#GROUP AICap The AI Group managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A_CAP:onafterStart( AICap, From, Event, To )

  self:GetParent( self, AI_A2A_CAP ).onafterStart( self, AICap, From, Event, To )
  AICap:HandleEvent( EVENTS.Takeoff, nil, self )

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

--- Evaluate the attack and create an AttackUnitTask list.
-- @param #AI_A2A_CAP self
-- @param Core.Set#SET_UNIT AttackSetUnit The set of units to attack.
-- @param Wrappper.Group#GROUP DefenderGroup The group of defenders.
-- @param #number EngageAltitude The altitude to engage the targets.
-- @return #AI_A2A_CAP self
function AI_A2A_CAP:CreateAttackUnitTasks( AttackSetUnit, DefenderGroup, EngageAltitude )

  local AttackUnitTasks = {}

  for AttackUnitID, AttackUnit in pairs( self.AttackSetUnit:GetSet() ) do
    local AttackUnit = AttackUnit -- Wrapper.Unit#UNIT
    if AttackUnit and AttackUnit:IsAlive() and AttackUnit:IsAir() then
      -- TODO: Add coalition check? Only attack units of if AttackUnit:GetCoalition()~=AICap:GetCoalition()
      -- Maybe the detected set also contains
      self:T( { "Attacking Task:", AttackUnit:GetName(), AttackUnit:IsAlive(), AttackUnit:IsAir() } )
      AttackUnitTasks[#AttackUnitTasks+1] = DefenderGroup:TaskAttackUnit( AttackUnit )
    end
  end

  return AttackUnitTasks
end
