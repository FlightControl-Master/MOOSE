-- This test mission models the behaviour of the AI_PATROL_ZONE class.
-- 
-- It creates a 2 AI_PATROL_ZONE objects with the name Patrol1 and Patrol2.
-- Patrol1 will govern a GROUP object to patrol the zone defined by PatrolZone1, within 3000 meters and 6000 meters, within a speed of 400 and 600 km/h.
-- When the GROUP object that is assigned to Patrol has fuel below 20%, the GROUP object will orbit for 60 secondes, before returning to base.
-- 
-- Patrol2 will goven a GROUP object to patrol the zone defined by PatrolZone2, within 600 meters and 1000 meters, within a speed of 300 and 400 km/h.
-- When the GROUP object that is assigned to Patrol has fuel below 20%, the GROUP object will orbit for 0 secondes, before returning to base.
--
-- The Patrol1 and Patrol2 object have 2 state transition functions defined, which customize the default behaviour of the RTB state.
-- When Patrol1 goes RTB, it will create a new GROUP object, that will be assigned to Patrol2.
-- When Patrol2 goes RTB, it will create a new GROUP object, that will be assgined to Patrol1.
--
-- In this way, the Patrol1 and Patrol2 objects are fluctuating the patrol pattern from PatrolZone1 and PatrolZone2 :-)


PatrolZoneGroup1 = GROUP:FindByName( "Patrol Zone 1" )
PatrolZone1 = ZONE_POLYGON:New( "Patrol Zone 1", PatrolZoneGroup1 )

PatrolZoneGroup2 = GROUP:FindByName( "Patrol Zone 2" )
PatrolZone2 = ZONE_POLYGON:New( "Patrol Zone 2", PatrolZoneGroup2 )

PatrolSpawn = SPAWN:New( "Patrol Group" )
PatrolGroup = PatrolSpawn:Spawn()

Patrol1 = AI_PATROL_ZONE:New( PatrolZone1, 3000, 6000, 400, 600 )
Patrol1:ManageFuel( 0.2, 60 )
Patrol1:SetControllable( PatrolGroup )
Patrol1:__Start( 5 )

Patrol2 = AI_PATROL_ZONE:New( PatrolZone2, 600, 1000, 300, 400 )
Patrol2:ManageFuel( 0.2, 0 )

--- State transition function for the PROCESS\_PATROLZONE **Patrol1** object
-- @param #AI_PATROL_ZONE self 
-- @param Wrapper.Group#GROUP AIGroup
-- @return #boolean If false is returned, then the OnAfter state transition function will not be called.
function Patrol1:OnLeaveRTB( AIGroup )
  AIGroup:MessageToRed( "Returning to base", 20 )
end 

--- State transition function for the PROCESS\_PATROLZONE **Patrol1** object
-- @param Process_PatrolCore.Zone#AI_PATROL_ZONE self 
-- @param Wrapper.Group#GROUP AIGroup
function Patrol1:OnAfterRTB( AIGroup )
  local NewGroup = PatrolSpawn:Spawn()
  Patrol2:SetControllable( NewGroup )
  Patrol2:__Start( 1 )
end 

--- State transition function for the PROCESS\_PATROLZONE **Patrol1** object
-- @param Process_PatrolCore.Zone#AI_PATROL_ZONE self 
-- @param Wrapper.Group#GROUP AIGroup
function Patrol1:OnEnterPatrol( AIGroup )
  AIGroup:MessageToRed( "Patrolling in zone " .. PatrolZone1:GetName() , 20 )
end 

--- State transition function for the PROCESS\_PATROLZONE **Patrol2** object
-- @param #AI_PATROL_ZONE self 
-- @param Wrapper.Group#GROUP AIGroup
-- @return #boolean If false is returned, then the OnEnter state transition function will not be called.
function Patrol2:OnBeforeRTB( AIGroup )
  AIGroup:MessageToRed( "Returning to base", 20 )
end 

--- State transition function for the PROCESS\_PATROLZONE **Patrol2** object
-- @param Process_PatrolCore.Zone#AI_PATROL_ZONE self 
-- @param Wrapper.Group#GROUP AIGroup
function Patrol2:OnEnterRTB( AIGroup )
  local NewGroup = PatrolSpawn:Spawn()
  Patrol1:SetControllable( NewGroup )
  Patrol1:__Start( 1 )
end 

--- State transition function for the PROCESS\_PATROLZONE **Patrol2** object
-- @param Process_PatrolCore.Zone#AI_PATROL_ZONE self 
-- @param Wrapper.Group#GROUP AIGroup
function Patrol2:OnEnterPatrol( AIGroup )
  AIGroup:MessageToRed( "Patrolling in zone " .. PatrolZone2:GetName() , 20 )
end 
