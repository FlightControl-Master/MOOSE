
local BlueAirbaseSet = SET_AIRBASE:New():FilterCoalitions("blue"):FilterStart()

local RedAirbaseSet = SET_AIRBASE:New():FilterCoalitions("red"):FilterStart()

local RedAirbaseHelipadSet = SET_AIRBASE:New():FilterCoalitions("red"):FilterCategories("helipad"):FilterStart()

local BlueAirbaseShipSet = SET_AIRBASE:New():FilterCoalitions("blue"):FilterCategories("ship"):FilterStart()

BlueAirbaseSet:Flush()

RedAirbaseSet:Flush()

RedAirbaseHelipadSet:Flush()

BlueAirbaseShipSet:Flush()