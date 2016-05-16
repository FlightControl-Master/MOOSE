
-- Only use Include.File when developing new MOOSE classes.
-- When using Moose.lua in the DO SCIPTS FILE initialization box, 
-- these Include.File statements are not needed, because all classes within Moose will be loaded.
Include.File("MissileTrainer")

-- This is an example of a global
local Trainer = MISSILETRAINER
  :New( 200 )
  :InitMessagesOnOff(true)
  :InitAlertsToAll(false) -- I'll correct it below ...
  :InitAlertsHitsOnOff(true)
  :InitAlertsLaunchesOnOff(true)
  :InitBearingOnOff(true)
  :InitRangeOnOff(true)
  :InitTrackingOnOff(true)
  :InitTrackingToAll(true)

Trainer:InitAlertsHitsOnOff(true) -- Now alerts are also on
