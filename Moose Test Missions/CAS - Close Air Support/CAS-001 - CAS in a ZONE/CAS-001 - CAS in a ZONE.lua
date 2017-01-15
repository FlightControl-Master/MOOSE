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

local AICasZone = AI_CAS_ZONE:New( PatrolZone, 500, 1000, 500, 600, CASEngagementZone )
local Targets = GROUP:FindByName("Targets")

AICasZone:SetControllable(CASPlane)

AICasZone:__Start( 1 ) -- They should statup, and start patrolling in the PatrolZone.

-- After 5 minutes, engage
AICasZone:__Engage( 600 )

-- Check every 60 seconds whether the Targets have been eliminated.
-- When the trigger completed has been fired, the Plane will go back to the Patrol Zone.
Check, CheckScheduleID = SCHEDULER:New(nil,
  function()
    BASE:E( { "In Scheduler: ", Targets:GetSize() } )
    if Targets:IsAlive() and Targets:GetSize() > 5 then
      BASE:E("Still alive")
    else
      BASE:E("Destroyed")
      AICasZone:__Accomplish( 1 ) -- Now they should fly back to teh patrolzone and patrol.
      Check:Stop(CheckScheduleID)
    end
  end, {}, 20, 60, 0.2 )


-- When the targets in the zone are destroyed, (see scheduled function), the planes will return homs...
function AICasZone:OnAfterAccomplish( Controllable, From, Event, To )

  AICasZone:__RTB( 1 )
end
  

  
