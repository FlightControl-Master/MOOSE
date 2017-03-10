BASE:TraceOnOff(true)
BASE:TraceClass("RADIO")
BASE:TraceLevel(3)


local Player = UNIT:FindByName("Player")
Player:MessageToAll("MainScript Started 3", 10, "")

local Static = STATIC:FindByName("CommandCenter")
local Transmiter = UNIT:FindByName("Transmiter")

local Radio = Transmiter:GetRadio()
Radio:SetSubtitle(6, "tes")
Radio:SetFileName("Noise.ogg")
Radio:SetFrequency(251.3)
Radio:Broadcast()