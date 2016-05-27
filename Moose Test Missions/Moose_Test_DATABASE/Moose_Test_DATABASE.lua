
Include.File( 'UnitSet' )
Include.File( 'GroupSet' )
Include.File( 'Spawn' )

DBBluePlanes = UNITSET:New()
  :FilterCoalitions( "blue" )
  :FilterCategories( "plane" )
  :FilterStart()

DBRedVehicles = UNITSET:New()
  :FilterCoalitions( "red" )
  :FilterCategories( "ground" )
  :FilterStart()

DBShips = UNITSET:New()
  :FilterCategories( "ship" )
  :FilterStart()
  
DBBelgium = UNITSET:New()
  :FilterCategories( "helicopter" )
  :FilterCountries( "BELGIUM" )
  :FilterStart()
  
DBNorthKorea = UNITSET:New()
  :FilterCountries( "NORTH_KOREA" )
  :FilterStart()
  
DBKA50Vinson = UNITSET:New()
  :FilterTypes( { "Ka-50", "VINSON" } )
  :FilterStart()
  
DBBluePlanesGroup = GROUPSET:New()
  :FilterCoalitions( "blue" )
  :FilterCategories( "plane" )
  :FilterStart()
  
DBNorthKoreaGroup = GROUPSET:New()
  :FilterCountries( "NORTH_KOREA" )
  :FilterStart()

DBBluePlanes:Flush()
DBRedVehicles:Flush()
DBShips:Flush()
DBBelgium:Flush()
DBNorthKorea:Flush()
DBKA50Vinson:Flush()
DBBluePlanesGroup:Flush()
DBNorthKoreaGroup:Flush()


SpawnUS_Plane = SPAWN:New( 'Database Spawn Test USA Plane')
GroupUS_Plane = SpawnUS_Plane:Spawn()

SpawnUS_Vehicle = SPAWN:New( 'Database Spawn Test USA Vehicle')
GroupUS_Vehicle = SpawnUS_Vehicle:Spawn()

SpawnUS_Ship = SPAWN:New( 'Database Spawn Test USA Ship')
GroupUS_Ship = SpawnUS_Ship:Spawn()

SpawnRU_Vehicle = SPAWN:New( 'Database Spawn Test RUSSIA Vehicle')
GroupRU_Vehicle = SpawnRU_Vehicle:Spawn()

SpawnRU_Ship = SPAWN:New( 'Database Spawn Test RUSSIA Ship')
GroupRU_Ship = SpawnRU_Ship:Spawn()

SpawnUS_AttackVehicle = SPAWN:New( 'Database Spawn Test USA Attack Vehicle' )
SpawnRU_AttackVehicle = SPAWN:New( 'Database Spawn Test RUSSIA Attack Vehicle' )

for i = 1, 2 do
  GroupRU_AttackVehicle = SpawnRU_AttackVehicle:SpawnInZone( ZONE:New("Spawn Zone RU"), true)
  GroupUS_AttackVehicle = SpawnUS_AttackVehicle:SpawnInZone( ZONE:New("Spawn Zone US"), true)
end


--DBBlue:TraceDatabase()
SCHEDULER:New( DBBluePlanes, DBBluePlanes.Flush, {  }, 1 )
SCHEDULER:New( DBRedVehicles, DBRedVehicles.Flush, {  }, 1 )
SCHEDULER:New( DBShips, DBShips.Flush, {  }, 1 )
SCHEDULER:New( DBBelgium, DBBelgium.Flush, {  }, 1 )
SCHEDULER:New( DBNorthKorea, DBNorthKorea.Flush, {  }, 1 )
SCHEDULER:New( DBKA50Vinson, DBKA50Vinson.Flush, {  }, 1 )

SCHEDULER:New( DBBluePlanesGroup, DBBluePlanesGroup.Flush, { }, 1 )
SCHEDULER:New( DBNorthKoreaGroup, DBNorthKoreaGroup.Flush, { }, 1 )

DBRedVehicles
  :ForEachUnit( function( MooseUnit ) 
    DBRedVehicles:T( MooseUnit:GetName() )
  end )

local function FlushPlayers()

  _DATABASE:E( "FlushPlayers" )
  _DATABASE
    :ForEachPlayerAlive( function( Player )
      _DATABASE:E( Player )
      MESSAGE:New( Player, "Test", 5, "Player Test" ):ToAll()
      return true
    end )
  return true
end

_DATABASE:E( "Schedule" )
local PlayerShow = SCHEDULER:New( nil, FlushPlayers, {}, 1, 10 )
  
  
  
