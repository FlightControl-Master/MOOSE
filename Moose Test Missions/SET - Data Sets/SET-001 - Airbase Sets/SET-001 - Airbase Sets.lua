
BlueAirbaseSet = SET_AIRBASE:New():FilterCoalitions("blue"):FilterStart()

RedAirbaseSet = SET_AIRBASE:New():FilterCoalitions("red"):FilterStart()

RedAirbaseHelipadSet = SET_AIRBASE:New():FilterCoalitions("red"):FilterCategories("helipad"):FilterStart()

BlueAirbaseShipSet = SET_AIRBASE:New():FilterCoalitions("blue"):FilterCategories("ship"):FilterStart()

BlueAirbaseSet:Flush()

RedAirbaseSet:Flush()

RedAirbaseHelipadSet:Flush()

BlueAirbaseShipSet:Flush()