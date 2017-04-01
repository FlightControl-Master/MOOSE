-- This test mission demonstrates the RADIO class in a practical scenario.
-- It also focuses on how to create transmissions faster and more efficiently
-- Please Read both RAD-000 and RAD-001, as well as SCH-000 code first.

-- Note that if you are not using an ASM aircraft (a clickable cockpit aircraft), then the frequency and the modulation is not important.
-- If you want to test the mission fully, replance the SU25T by an ASM aircraft you own and tune to the right frequency (115AM here)

-- The Player is in a Su25T parked on Batumi, and a Russian command center named "Batumi Tower" placed near Batumi will act as Batumi's Radio Tower.
-- This mission also features the "Viktor" flight, a Russian Su25, who is inbound for landing on Batumi.
-- The goal of this script is to manage the dialog between Viktor and Batumi Tower.

-- The (short) conversation between Viktor and Batumi Tower will happen on 115 AM
-- Time 0 :   Batumi Tower  "Viktor flight, this is Batumi Tower, enter left base runway one two five, report 5 kilometers final. Over."
-- Time 10 :  Viktor        "Report 5 kilometers final, one two five, viktor"
-- Time 145 : Viktor        "Batumi Tower, Viktor is 5 kilomters final, request landing clearance. Over?"
-- Time 154 : Batumi Tower  "Viktor flight, you are claer to land, runway one two five. Check gear down."
-- Time 160 : Viktor        "Clear to land, One two five, Viktor"
-- Time 210 : Viktor        "Viktor, touchdown"
-- Time 215 : Batumi Tower  "Viktor, confirmed touchdown, taxi to parking area, Batumi Tower out."


BatumiRadio = STATIC:FindByName("Batumi Tower"):GetRadio()
ViktorRadio = UNIT:FindByName("Viktor"):GetRadio()

-- Let's first explore different shortcuts to setup a transmission before broadcastiong it
------------------------------------------------------------------------------------------------------------------------------------------------------
-- First, the long way. 
BatumiRadio:SetFileName("Batumi Tower - Enter left base.ogg")
BatumiRadio:SetFrequency(115)
BatumiRadio:SetModulation(radio.modulation.AM)
BatumiRadio:SetPower(100)

-- Every RADIO.SetXXX() function returns the radio, so we can rewrite the code above this way :
BatumiRadio:SetFileName("Batumi Tower - Enter left base.ogg"):SetFrequency(115):SetModulation(radio.modulation.AM):SetPower(100)

-- We can also use the shortcut RADIO:NewGenericTransmission() to set multiple parameters in one function call
-- If our broadcaster was a UNIT or a GROUP, the more appropriate shortcut to use would have been NewUnitTransmission()
-- it works for both UNIT and GROUP, despite its name !
BatumiRadio:NewGenericTransmission("Batumi Tower - Enter left base.ogg", 115, radio.modulation.AM, 100)

-- If you already set some parameters previously, you don't have to redo it !
-- NewGenericTransmission's paramter have to be set in order
BatumiRadio:NewGenericTransmission("Batumi Tower - Enter left base.ogg", 115) -- Modulation is still AM and power is still 100 (set previously)

--If you want to change only the sound file, the frequency and the power for exemple, you can still use the appropriate Set function
BatumiRadio:NewGenericTransmission("Batumi Tower - Enter left base.ogg", 115):SetPower(100) 

-- We have finished tinkering with our transmission, now is the time to broadcast it !
BatumiRadio:Broadcast()

-- Now, if Viktor answered imedately, the two radio broadcasts would overlap. We need to delay Viktor's answer. 
------------------------------------------------------------------------------------------------------------------------------------------------------
CommunitcationScheduler = SCHEDULER:New( nil,
  function()
    ViktorRadio:SetFileName("Viktor - Enter left base ack.ogg"):SetFrequency(115):SetModulation(radio.modulation.AM):Broadcast() -- We don't specify a subtitle since we don't want one
  end, {}, 10 -- 10s delay
  )
  
-- Viktor takes 145s to be 5km final, and need to contact Batumi Tower. 
------------------------------------------------------------------------------------------------------------------------------------------------------ 
CommunitcationScheduler:Schedule( nil,
  function()
    ViktorRadio:SetFileName("Viktor - Request landing clearance.ogg"):Broadcast() --We only specify the new file name, since frequency and modulation didn't change
  end, {}, 145
  )
  
-- Now that you understand everything about the RADIO class, the rest is pretty trivial
-------------------------------------------------------------------------------------------------------------------------------------------------------
CommunitcationScheduler:Schedule( nil,
  function()
    BatumiRadio:SetFileName("Batumi Tower - Clear to land.ogg"):Broadcast()
  end, {}, 154
  )
  
CommunitcationScheduler:Schedule( nil,
  function()
    ViktorRadio:SetFileName("Viktor - Clear to land ack.ogg"):Broadcast()
  end, {}, 160
  )
  
CommunitcationScheduler:Schedule( nil,
  function()
    ViktorRadio:SetFileName("Viktor - Touchdown.ogg"):Broadcast()
  end, {}, 210
  )
  
CommunitcationScheduler:Schedule( nil,
  function()
    BatumiRadio:SetFileName("Batumi Tower - Taxi to parking.ogg"):Broadcast()
  end, {}, 215
  )