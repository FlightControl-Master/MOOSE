BASE:TraceAll(1)
BASE:TraceLevel(1)
local Player = UNIT:FindByName("Player")
Player:MessageToAll("MainScript Started 2", 10, "")

local Static = STATIC:FindByName("CommandCenter")

local StaticRadio = Static:GetRadio()
StaticRadio:NewGenericTransmission("Test Voice.ogg", 251000, radio.modulation.AM, 1000)
StaticRadio:Broadcast()
