mode = ADF_ADF
receiver_mode = ADF_RECEIVER_TLF
homer_selection_method = ADF_HOMER_SELECTION_AUTO
channel = 1
volume = 0.5

local theatre = theatre or "none"
if theatre == 'Caucasus' then

	if Airdrome then
		-- for T3
		channels = {
			[1] = runway_homer_pair(Airdrome[Krasnodar],nil,localizedAirdromeName(terrainAirdromes[Krasnodar])),
			[2] = runway_homer_pair(Airdrome[Maykop]   ,nil,localizedAirdromeName(terrainAirdromes[Maykop])),
			[3] = runway_homer_pair(Airdrome[Krymsk]   ,nil,localizedAirdromeName(terrainAirdromes[Krymsk])),
			[4] = runway_homer_pair(Airdrome[Anapa]    ,nil,localizedAirdromeName(terrainAirdromes[Anapa])),
			[5] = runway_homer_pair(Airdrome[Mozdok]   ,nil,localizedAirdromeName(terrainAirdromes[Mozdok])),
			[6] = runway_homer_pair(Airdrome[Nalchick] ,nil,localizedAirdromeName(terrainAirdromes[Nalchick])),
			[7] = runway_homer_pair(Airdrome[MinVody]  ,nil,localizedAirdromeName(terrainAirdromes[MinVody])),
			[8] = {
				[ADF_HOMER_FAR]  = NDB(beacons["NDB_KISLOVODSK"]),
				[ADF_HOMER_NEAR] = NDB(beacons["NDB_PEREDOVAIA"])
			}
		}
	else
		-- for T4
		local beacons_by_id = {}
		
		for i,o in pairs(beacons) do
			if o.name == '' then
				beacons_by_id[o.beaconId] = o
			else
				beacons_by_id[o.name] = o
			end	
		end
		
		local caucasus_pair = function (id_1,id_2)
			return	{
				[ADF_HOMER_FAR]  = NDB(beacons_by_id[id_1]),
				[ADF_HOMER_NEAR] = NDB(beacons_by_id[id_2])
			}
		end

		channels = { 
			caucasus_pair('airfield13_2','airfield13_3'),
			caucasus_pair('airfield16_2','airfield16_3'),
			caucasus_pair("airfield15_4","airfield15_5"),
			caucasus_pair("airfield12_0","airfield12_1"),
			caucasus_pair("airfield28_0","airfield28_1"),
			caucasus_pair("airfield27_0","airfield27_1"),
			caucasus_pair("airfield26_0","airfield26_1"),
			caucasus_pair("world_9","world_58"),
		}
	end

elseif theatre == 'Nevada' then

	local beacons_by_name = {}
	
	for i,o in pairs(beacons) do
		if o.name == '' then
			beacons_by_name[o.beaconId] = o
		else
			beacons_by_name[o.name] = o
		end	
	end
	
	local nevada_pair = function (id_1,id_2) return		{
			[ADF_HOMER_FAR]  = NDB(beacons_by_name[id_1]),
			[ADF_HOMER_NEAR] = NDB(beacons_by_name[id_2])
		}
	end

	channels = { 
		nevada_pair('IndianSprings','Groom_Lake'),
		nevada_pair('LasVegas','Nellis'),
		nevada_pair("Milford","GOFFS"),
		nevada_pair("Tonopah","Mina"),
		nevada_pair("WilsonCreek","CedarCity"),
		nevada_pair("BryceCanyon","MormonMesa"),
		nevada_pair("Beatty","Bishop"),
		nevada_pair("Coaldale","PeachSprings"),
		nevada_pair("BoulderCity","Mercury"),
	}
end