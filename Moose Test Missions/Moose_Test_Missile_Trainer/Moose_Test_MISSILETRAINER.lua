
-- Only use Include.File when developing new MOOSE classes.
-- When using Moose.lua in the DO SCIPTS FILE initialization box, 
-- these Include.File statements are not needed, because all classes within Moose will be loaded.


-- This is an example of a global
local Trainer = MISSILETRAINER
  :New( 200, "Trainer: Welcome to the missile training, trainee! Missiles will be fired at you. Try to evade them. Good luck!" )
  :InitMessagesOnOff(true)
  :InitAlertsToAll(true) 
  :InitAlertsHitsOnOff(true)
  :InitAlertsLaunchesOnOff(false) -- I'll put it on below ...
  :InitBearingOnOff(true)
  :InitRangeOnOff(true)
  :InitTrackingOnOff(true)
  :InitTrackingToAll(true)
  :InitMenusOnOff(false)

Trainer:InitAlertsToAll(true) -- Now alerts are also on
