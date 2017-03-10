BASE:TraceAll(1)
BASE:TraceLevel(3)
local Player = UNIT:FindByName("Player")
Player:MessageToAll("MainScript Started 2", 10, "")

local Transmiter = UNIT:FindByName("Transmiter")

local TransmiterRadio = Transmiter:GetRadio()
TransmiterRadio:NewUnitTransmission("Noise.ogg", "Subtitle", 10, 251000, 0, 0)
TransmiterRadio:E({
                  TransmiterRadio.Positionable,
                  TransmiterRadio.FileName,
                  TransmiterRadio.Subtitle,
                  TransmiterRadio.SubtitleDuration,
                  TransmiterRadio.Frequency,
                  TransmiterRadio.Modulation,
                  })
TransmiterRadio:Broadcast()