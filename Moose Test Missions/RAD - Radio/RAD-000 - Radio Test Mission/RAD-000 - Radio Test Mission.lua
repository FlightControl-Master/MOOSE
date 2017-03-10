BASE:TraceOnOff(true)
BASE:TraceClass("RADIO")
BASE:TraceLevel(3)


local Player = UNIT:FindByName("Player")
Player:MessageToAll("MainScript Started 3", 10, "")

local Static = STATIC:FindByName("CommandCenter")
local Transmiter = UNIT:FindByName("Transmiter")

local Radio = Transmiter:GetRadio()
Radio:SetFrequency(25)
Radio:SetFrequency(89)
Radio:SetFrequency(152)
Radio:SetFrequency(500)
Radio:SetFrequency("a")
Radio:SetFrequency(225)
Radio:SetFrequency(251.3)

Radio:SetFileName("Noise.ogg")
Radio:Broadcast()