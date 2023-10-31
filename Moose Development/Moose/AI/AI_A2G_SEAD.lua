--- **AI** - Models the process of air to ground SEAD engagement for airplanes and helicopters.
--
-- This is a class used in the @{AI.AI_A2G_Dispatcher}.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_A2G_SEAD
-- @image AI_Air_To_Ground_Engage.JPG



--- @type AI_A2G_SEAD
-- @extends AI.AI_Air_Patrol#AI_AIR_PATROL
-- @extends AI.AI_Air_Engage#AI_AIR_ENGAGE


--- Implements the core functions to SEAD intruders. Use the Engage trigger to intercept intruders.
-- 
-- The AI_A2G_SEAD is assigned a @{Wrapper.Group} and this must be done before the AI_A2G_SEAD process can be started using the **Start** event.
-- 
-- The AI will fly towards the random 3D point within the patrol zone, using a random speed within the given altitude and speed limits.
-- Upon arrival at the 3D point, a new random 3D point will be selected within the patrol zone using the given limits.
-- 
-- This cycle will continue.
-- 
-- During the patrol, the AI will detect enemy targets, which are reported through the **Detected** event.
-- 
-- When enemies are detected, the AI will automatically engage the enemy.
-- 
-- Until a fuel or damage threshold has been reached by the AI, or when the AI is commanded to RTB.
-- When the fuel threshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- ## 1. AI_A2G_SEAD constructor
--   
--   * @{#AI_A2G_SEAD.New}(): Creates a new AI_A2G_SEAD object.
--
-- ## 3. Set the Range of Engagement
-- 
-- An optional range can be set in meters, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- The range can be beyond or smaller than the range of the Patrol Zone.
-- The range is applied at the position of the AI.
--
-- # Developer Note
-- 
-- Note while this class still works, it is no longer supported as the original author stopped active development of MOOSE
-- Therefore, this class is considered to be deprecated
--
-- ===
-- 
-- @field #AI_A2G_SEAD
AI_A2G_SEAD = {
  ClassName = "AI_A2G_SEAD",
}

--- Creates a new AI_A2G_SEAD object
-- @param #AI_A2G_SEAD self
-- @param Wrapper.Group#GROUP AIGroup
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude The highest altitude in meters where to execute the engagement.
-- @param DCS#AltitudeType EngageAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to "RADIO".
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Core.Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_A2G_SEAD
function AI_A2G_SEAD:New2( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  local AI_Air = AI_AIR:New( AIGroup )
  local AI_Air_Patrol = AI_AIR_PATROL:New( AI_Air, AIGroup, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )
  local AI_Air_Engage = AI_AIR_ENGAGE:New( AI_Air_Patrol, AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
  local self = BASE:Inherit( self, AI_Air_Engage )

  return self
end


--- Creates a new AI_A2G_SEAD object
-- @param #AI_A2G_SEAD self
-- @param Wrapper.Group#GROUP AIGroup
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude The highest altitude in meters where to execute the engagement.
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Core.Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_A2G_SEAD
function AI_A2G_SEAD:New( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  return self:New2( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, PatrolAltType, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )
end


--- Evaluate the attack and create an AttackUnitTask list. 
-- @param #AI_A2G_SEAD self
-- @param Core.Set#SET_UNIT AttackSetUnit The set of units to attack.
-- @param Wrapper.Group#GROUP DefenderGroup The group of defenders.
-- @param #number EngageAltitude The altitude to engage the targets.
-- @return #AI_A2G_SEAD self
function AI_A2G_SEAD:CreateAttackUnitTasks( AttackSetUnit, DefenderGroup, EngageAltitude )

  local AttackUnitTasks = {}
  
  local AttackSetUnitPerThreatLevel = AttackSetUnit:GetSetPerThreatLevel( 10, 0 )
  for AttackUnitID, AttackUnit in ipairs( AttackSetUnitPerThreatLevel ) do
    if AttackUnit then
      if AttackUnit:IsAlive() and AttackUnit:IsGround() then
        local HasRadar = AttackUnit:HasSEAD() 
        if HasRadar then
          self:F( { "SEAD Unit:", AttackUnit:GetName() } )
          AttackUnitTasks[#AttackUnitTasks+1] = DefenderGroup:TaskAttackUnit( AttackUnit, true, false, nil, nil, EngageAltitude )
        end
      end
    end
  end
  
  return AttackUnitTasks
end

