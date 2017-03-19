-- This test mission demonstrates the RADIO class, particularily when the transmiter is anything but a UNIT or a GROUP (a STATIC in this case)
-- The Player is in a Su25T parked on Batumi, and a Russian command center named "Russian Command Center" is placed 12km east of Batumi.

-- Note that if you are not using an ASM aircraft (a clickable cockpit aircraft), then the frequency and the modulation is not important.
-- If you want to test the mission fully, replance the SU25T by an ASM aircraft you own and tune to the right frequency (108AM here)

CommandCenter = STATIC:FindByName("Russian Command Center")

-- Let's get a reference to the Command Center's RADIO
CommandCenterRadio = CommandCenter:GetRadio()  

-- Now, we'll set up the next transmission
CommandCenterRadio:SetFileName("Noise.ogg")  -- We first need the file name of a sound,
CommandCenterRadio:SetFrequency(108)         -- then a frequency in MHz,
CommandCenterRadio:SetModulation(radio.modulation.AM) -- a modulation (we use DCS' enumartion, this way we don't have to type numbers)...
CommandCenterRadio:SetPower(100)             -- and finally a power in Watts. A "normal" ground TACAN station has a power of 120W.

-- We have finished tinkering with our transmission, now is the time to broadcast it !
CommandCenterRadio:Broadcast()