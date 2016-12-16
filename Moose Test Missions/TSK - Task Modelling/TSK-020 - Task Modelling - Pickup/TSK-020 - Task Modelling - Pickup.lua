












do
	local Mission = MISSION:New( 'Pickup', 'Operational', 'Pickup Troops', 'NATO' )

	Mission:AddClient( CLIENT:FindByName( 'DE Pickup Test 1' ):Transport() )
	Mission:AddClient( CLIENT:FindByName( 'DE Pickup Test 2' ):Transport() )

	local CargoTable = {}

	local EngineerNames = { "Alpha", "Beta", "Gamma", "Delta", "Theta" }

	Cargo_Pickup_Zone_1 = CARGO_ZONE:New( 'Pickup Zone 1', 'DE Communication Center 1' ):BlueSmoke()
    Cargo_Pickup_Zone_2 = CARGO_ZONE:New( 'Pickup Zone 2', 'DE Communication Center 2' ):RedSmoke()
	
	for CargoItem = 1, 2 do
		CargoTable[CargoItem] = AI_CARGO_GROUP:New( 'Engineers', 'Team ' .. EngineerNames[CargoItem], math.random( 70, 100 ) * 3, 'DE Infantry',  Cargo_Pickup_Zone_1 )
	end

	for CargoItem = 3, 5 do
		CargoTable[CargoItem] = AI_CARGO_GROUP:New( 'Engineers', 'Team ' .. EngineerNames[CargoItem], math.random( 70, 100 ) * 3, 'DE Infantry',  Cargo_Pickup_Zone_2 )
	end
	
	--Cargo_Package = CARGO_INVISIBLE:New( 'Letter', 0.1, 'DE Secret Agent', 'Pickup Zone Package' )
	--Cargo_Goods = CARGO_STATIC:New( 'Goods', 20, 'Goods', 'Pickup Zone Goods', 'DE Collection Point' )
	--Cargo_SlingLoad = CARGO_SLING:New( 'Basket', 40, 'Basket', 'Pickup Zone Sling Load', 'DE Cargo Guard' )

					
	-- Assign the Pickup Task
	local PickupTask = PICKUPTASK:New( 'Engineers', CLIENT.ONBOARDSIDE.LEFT )
	PickupTask:FromZone( Cargo_Pickup_Zone_1 )
	PickupTask:FromZone( Cargo_Pickup_Zone_2 )
	PickupTask:InitCargo( CargoTable )
	PickupTask:SetGoalTotal( 3 )
	Mission:AddTask( PickupTask, 1 )

	
	Cargo_Deploy_Zone_1 = CARGO_ZONE:New( 'Deploy Zone 1', 'DE Communication Center 3' ):RedFlare()
	Cargo_Deploy_Zone_2 = CARGO_ZONE:New( 'Deploy Zone 2', 'DE Communication Center 4' ):WhiteFlare()

	-- Assign the Pickup Task
	local DeployTask = DEPLOYTASK:New( 'Engineers' )
	DeployTask:ToZone( Cargo_Deploy_Zone_1 )
	DeployTask:ToZone( Cargo_Deploy_Zone_2 )
	DeployTask:SetGoalTotal( 3 )
	Mission:AddTask( DeployTask, 2 )
	
	MISSIONSCHEDULER.AddMission( Mission )
end

do
	local Mission = MISSION:New( 'Deliver secret letter', 'Operational', 'Pickup letter to the commander.', 'NATO' )

	Client_Package_1 = CLIENT:FindByName( 'BE Package Test 1' ):Transport()
	
	Mission:AddClient( Client_Package_1 )

	Package_Pickup_Zone = CARGO_ZONE:New( 'Package Pickup Zone', 'DE Guard' ):GreenSmoke()

	Cargo_Package = AI_CARGO_PACKAGE:New( 'Letter', 'Letter to Command', 0.1, Client_Package_1 )
	--Cargo_Goods = CARGO_STATIC:New( 'Goods', 20, 'Goods', 'Pickup Zone Goods', 'DE Collection Point' )
	--Cargo_SlingLoad = CARGO_SLING:New( 'Basket', 40, 'Basket', 'Pickup Zone Sling Load', 'DE Cargo Guard' )

					
	-- Assign the Pickup Task
	local PickupTask = PICKUPTASK:New( 'Letter', CLIENT.ONBOARDSIDE.FRONT )
	PickupTask:FromZone( Package_Pickup_Zone  )
	PickupTask:InitCargo( { Cargo_Package } )
	PickupTask:SetGoalTotal( 1 )
	Mission:AddTask( PickupTask, 1 )

	
	Package_Deploy_Zone = CARGO_ZONE:New( 'Package Deploy Zone', 'DE Secret Car' ):GreenFlare()

	-- Assign the Pickup Task
	local DeployTask = DEPLOYTASK:New( 'Letter' )
	DeployTask:ToZone( Package_Deploy_Zone )
	DeployTask:SetGoalTotal( 1 )
	Mission:AddTask( DeployTask, 2 )
	
	MISSIONSCHEDULER.AddMission( Mission )
end

do
	local Mission = MISSION:New( 'Sling load Cargo', 'Operational', 'Sling Load Cargo to Deploy Zone.', 'NATO' )

	Mission:AddClient( CLIENT:FindByName( 'Sling Load Test Client 1' ):Transport() )
	Mission:AddClient( CLIENT:FindByName( 'Sling Load Test Client 2' ):Transport() )

	Sling_Load_Pickup_Zone = CARGO_ZONE:New( 'Sling Load Pickup Zone', 'Sling Load Guard' ):RedSmoke()

	Cargo_Sling_Load = CARGO_SLINGLOAD:New( 'Sling', 'Food Boxes', 200, 'Sling Load Pickup Zone', 'Sling Load Guard', country.id.USA )
	--Cargo_Goods = CARGO_STATIC:New( 'Goods', 20, 'Goods', 'Pickup Zone Goods', 'DE Collection Point' )
	--Cargo_SlingLoad = CARGO_SLING:New( 'Basket', 40, 'Basket', 'Pickup Zone Sling Load', 'DE Cargo Guard' )

					
	-- Assign the Pickup Task
	local PickupTask = PICKUPTASK:New( 'Sling', CLIENT.ONBOARDSIDE.FRONT )
	PickupTask:FromZone( Sling_Load_Pickup_Zone  )
	PickupTask:InitCargo( { Cargo_Sling_Load } )
	PickupTask:SetGoalTotal( 1 )
	Mission:AddTask( PickupTask, 1 )
	
	MISSIONSCHEDULER.AddMission( Mission )
end



-- MISSION SCHEDULER STARTUP
MISSIONSCHEDULER.Start()
MISSIONSCHEDULER.ReportMenu()
MISSIONSCHEDULER.ReportMissionsHide()

env.info( "Test Mission loaded" )
