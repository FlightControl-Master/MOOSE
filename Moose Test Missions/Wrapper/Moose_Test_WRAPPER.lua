




BASE:TraceClass( "UNIT" )
BASE:TraceClass( "GROUP" )
BASE:TraceClass( "CLIENT" )

UnitTankAI1 = _DATABASE:FindUnit( "Smoke Test 1" )
UnitTankAI2 = _DATABASE:FindUnit( "Smoke Test 2" )
UnitTankAI3 = UNIT:FindByName( "Smoke Test 3" )
UnitTankAI4 = _DATABASE:FindUnit( "Smoke Test 4" )

UnitTankAI1:SmokeBlue()

UnitTankAI3:SmokeOrange()

UnitTankAI2:T( UnitTankAI2:GetAmmo() )

GroupTanks = GROUP:FindByName( "Smoke Test" )

GroupTanks:T( GroupTanks:OptionROEOpenFirePossible() )

GroupTanks:OptionROEOpenFire()

  local function ClientAlive( Client, ClientNumber )
    GroupTanks:MessageToClient( "Hello Client " .. ClientNumber .. "! We are reporting to you on our way...", 5, Client )
  end


ClientHeli = CLIENT:FindByName( "Client Test 1", "Fly slowly to waypoint 3 of the Command Post!" ):Alive( ClientAlive, 1 )
ClientHeli2 = CLIENT:FindByName( "Client Test 2", "Fly slowly to waypoint 3 of the Command Post!" ):Alive( ClientAlive, 2 )






