
-- Only use Include.File when developing new MOOSE classes.
-- When using Moose.lua in the DO SCIPTS FILE initialization box, 
-- these Include.File statements are not needed, because all classes within Moose will be loaded.
Include.File("MissileTrainer")

-- This is an example of a global
local Trainer = MISSILETRAINER
  :New( 200 )
  :InitMessagesOnOff(true)
  :InitAlertsToAll(true) -- I'll correct it below ...
  :InitAlertsHitsOnOff(true)
  :InitAlertsLaunchesOnOff(false)
  :InitBearingOnOff(true)
  :InitRangeOnOff(true)
  :InitTrackingOnOff(true)
  :InitTrackingToAll(true)
  :InitMenusOnOff(false) -- Disable menus
  :InitTrackingFrequency( 1 ) -- Make Tracking Frequency 4 seconds ...
  
-- Trainer:InitAlertsToAll(true) -- Now alerts are also on
