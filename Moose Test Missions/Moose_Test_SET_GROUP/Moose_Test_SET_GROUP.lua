
Include.File( 'Set' )
Include.File( 'Spawn' )

SetBluePlanesGroup = SET_GROUP:New()
  :FilterCoalitions( "blue" )
  :FilterCategories( "plane" )
  :FilterStart()
  
SetNorthKoreaGroup = SET_GROUP:New()
  :FilterCountries( "RUSSIA" )
  :FilterStart()

SetSAMGroup = SET_GROUP:New()
  :FilterPrefixes( "SAM" )
  :FilterStart()

SpawnUS_Plane = SPAWN:New( 'Spawn Test USA Plane')
GroupUS_Plane = SpawnUS_Plane:Spawn()

SpawnUS_Vehicle = SPAWN:New( 'Spawn Test USA Vehicle')
GroupUS_Vehicle = SpawnUS_Vehicle:Spawn()

SpawnUS_Ship = SPAWN:New( 'Spawn Test USA Ship')
GroupUS_Ship = SpawnUS_Ship:Spawn()

SpawnRU_Vehicle = SPAWN:New( 'Spawn Test RUSSIA Vehicle')
GroupRU_Vehicle = SpawnRU_Vehicle:Spawn()

SpawnRU_Ship = SPAWN:New( 'Spawn Test RUSSIA Ship')
GroupRU_Ship = SpawnRU_Ship:Spawn()

SpawnM2A2_AttackVehicle = SPAWN:New( 'Spawn Test M2A2 Attack Vehicle' )
SpawnSAM_AttackVehicle = SPAWN:New( 'Spawn Test SAM Attack Vehicle' )

for i = 1, 30 do
  GroupM2A2_AttackVehicle = SpawnM2A2_AttackVehicle:SpawnInZone( ZONE:New("Spawn Zone"), true)
  GroupSAM_AttackVehicle = SpawnSAM_AttackVehicle:SpawnInZone( ZONE:New("Spawn Zone"), true)
end


--DBBlue:TraceDatabase()
--SCHEDULER:New( DBBluePlanes, DBBluePlanes.Flush, {  }, 1 )
--SCHEDULER:New( DBRedVehicles, DBRedVehicles.Flush, {  }, 1 )
--SCHEDULER:New( DBShips, DBShips.Flush, {  }, 1 )
--SCHEDULER:New( DBBelgium, DBBelgium.Flush, {  }, 1 )
--SCHEDULER:New( DBNorthKorea, DBNorthKorea.Flush, {  }, 1 )
--SCHEDULER:New( DBKA50Vinson, DBKA50Vinson.Flush, {  }, 1 )
--
--SCHEDULER:New( DBBluePlanesGroup, DBBluePlanesGroup.Flush, { }, 1 )
--SCHEDULER:New( DBNorthKoreaGroup, DBNorthKoreaGroup.Flush, { }, 1 )

SetBluePlanesGroup:ForEachGroup( 
  --- @param Group#GROUP MooseGroup
  function( MooseGroup ) 
    for UnitId, UnitData in pairs( MooseGroup:GetUnits() ) do
      local UnitAction = UnitData -- Unit#UNIT
      UnitAction:SmokeBlue()
    end
  end 
)

SetNorthKoreaGroup:ForEachGroup( 
  --- @param Group#GROUP MooseGroup
  function( MooseGroup ) 
    for UnitId, UnitData in pairs( MooseGroup:GetUnits() ) do
      local UnitAction = UnitData -- Unit#UNIT
      UnitAction:SmokeRed()
    end
  end 
)

SetSAMGroup:ForEachGroup( 
  --- @param Group#GROUP MooseGroup
  function( MooseGroup ) 
    for UnitId, UnitData in pairs( MooseGroup:GetUnits() ) do
      local UnitAction = UnitData -- Unit#UNIT
      UnitAction:SmokeOrange()
    end
  end 
)
  
  
