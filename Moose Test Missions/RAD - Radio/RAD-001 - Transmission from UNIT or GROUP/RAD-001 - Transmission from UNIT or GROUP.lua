-- This test mission demonstrates the RADIO class, particularily when the transmiter is a UNIT or a GROUP
-- The Player is in a Su25T parked on Batumi, and a Russian MiG-29 creatively named "Sergey" is placed above Kobuleti and is 
-- inbound for a landing on Batumi

-- Note that if you are not using an ASM aircraft (a clickable cockpit aircraft), then the frequency and the modulation is not important.
-- If you want to test the mission fully, replance the SU25T by an ASM aircraft you own and tune to the right frequency (108AM here)

Sergey = UNIT:FindByName("Sergey")

-- Let's get a reference to Sergey's RADIO
SergeyRadio = Sergey:GetRadio()  

-- Now, we'll set up the next transmission
SergeyRadio:SetFileName("Noise.ogg")  -- We first need the file name of a sound,
SergeyRadio:SetFrequency(108)         -- then a frequency in MHz,
SergeyRadio:SetModulation(radio.modulation.AM) -- and a modulation (we use DCS' enumartion, this way we don't have to type numbers).

-- Since Sergey is a UNIT, we can add a subtitle (displayed on the top left) to the transmission, and loop the transmission
SergeyRadio:SetSubtitle("Hey, hear that noise ?", 5)   -- The subtitle "Noise" will be displayed for 5 secs
SergeyRadio:SetLoop(false)

-- Notice that we didn't have to imput a power ? If the broadcater is a UNIT or a GROUP, DCS automatically guesses the power to use depending on the type of UNIT or GROUP

-- We have finished tinkering with our transmission, now is the time to broadcast it !
SergeyRadio:Broadcast()