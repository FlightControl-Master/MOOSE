-- Name: CAS in a ZONE
-- Author: FlightControl
-- Date Created: 13 January 2017
--
-- # Situation:
--
-- # Test cases:
-- 

local CASEngagementZone = ZONE:New( "Engagement Zone" )

local CASPlane = GROUP:FindByName( "Plane" )

local PatrolZone = ZONE:New( "Patrol Zone" )

local AICasZone = AI_CAS_ZONE:New( PatrolZone, 500, 1000, 350, 600, CASEngagementZone )
local Targets = GROUP:FindByName("Targets")

AICasZone:SetControllable(CASPlane)
AICasZone:__Start(1)
AICasZone:__Engage(10)

-- Check every 60 seconds whether the Targets have been eliminated.
-- When the trigger completed has been fired, the Plane will go back to the Patrol Zone.
Check = SCHEDULER:New(nil,
  function()
    BASE:E( { "In Scheduler: ", Targets:GetSize() } )
    if Targets:IsAlive() and Targets:GetSize() ~= 0 then
      BASE:E("Still alive")
    else
      BASE:E("Destroyed")
      AICasZone:__Completed(1)
    end
  end, {}, 20, 60, 0.2 )
  

  
