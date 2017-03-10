local Player = UNIT:FindByName("Player")
Player:MessageToAll("MainScript Started", 10, "")

local PlayerRadio = Player:GetRadio()
PlayerRadio:NewTransmission("Noise.ogg", "Subtitle", 10, 251000, 0, 0)
PlayerRadio:Broadcast()