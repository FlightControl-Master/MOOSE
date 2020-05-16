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
-- @module AI.AI_A2G_CAS
-- @image AI_Air_To_Ground_Engage.JPG



--- @type AI_A2G_CAS
-- @extends AI.AI_A2G_Patrol#AI_AIR_PATROL


--- Implements the core functions to intercept intruders. Use the Engage trigger to intercept intruders.
-- 
-- ===
-- 
-- @field #AI_A2G_CAS
AI_A2G_CAS = {
  ClassName = "AI_A2G_CAS",
}



--- Creates a new AI_A2G_CAS object
-- @param #AI_A2G_CAS self
-- @param Wrapper.Group#GROUP AIGroup
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude The highest altitude in meters where to execute the engagement.
-- @param DCS#AltitudeType EngageAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to "RADIO".
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_A2G_CAS
function AI_A2G_CAS:New2( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  local AI_Air = AI_AIR:New( AIGroup )
  local AI_Air_Patrol = AI_AIR_PATROL:New( AI_Air, AIGroup, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType ) -- #AI_AIR_PATROL
  local AI_Air_Engage = AI_AIR_ENGAGE:New( AI_Air_Patrol, AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
  local self = BASE:Inherit( self, AI_Air_Engage )

  return self
end


--- Creates a new AI_A2G_CAS object
-- @param #AI_A2G_CAS self
-- @param Wrapper.Group#GROUP AIGroup
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude The highest altitude in meters where to execute the engagement.
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_A2G_CAS
function AI_A2G_CAS:New( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  return self:New2( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, PatrolAltType, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType)
end

--- Evaluate the attack and create an AttackUnitTask list. 
-- @param #AI_A2G_CAS self
-- @param Core.Set#SET_UNIT AttackSetUnit The set of units to attack.
-- @param Wrappper.Group#GROUP DefenderGroup The group of defenders.
-- @param #number EngageAltitude The altitude to engage the targets.
-- @return #AI_A2G_CAS self
function AI_A2G_CAS:CreateAttackUnitTasks( AttackSetUnit, DefenderGroup, EngageAltitude )

  local AttackUnitTasks = {}
  
  local AttackSetUnitPerThreatLevel = AttackSetUnit:GetSetPerThreatLevel( 10, 0 )
  for AttackUnitIndex, AttackUnit in ipairs( AttackSetUnitPerThreatLevel or {} ) do
    if AttackUnit then
      if AttackUnit:IsAlive() and AttackUnit:IsGround() then
        self:T( { "CAS Unit:", AttackUnit:GetName() } )
        AttackUnitTasks[#AttackUnitTasks+1] = DefenderGroup:TaskAttackUnit( AttackUnit, true, false, nil, nil, EngageAltitude )
      end
    end
  end
  
  return AttackUnitTasks
end



