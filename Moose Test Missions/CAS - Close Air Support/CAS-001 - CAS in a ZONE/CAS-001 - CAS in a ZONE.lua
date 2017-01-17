-- Name: CAS in a ZONE
-- Author: FlightControl
-- Date Created: 13 January 2017
--
-- # Situation:
--
-- # Test cases:
-- 
-- Create a local variable (in this case called CASEngagementZone) and 
-- using the ZONE function find the pre-defined zone called "Engagement Zone" 
-- currently on the map and assign it to this variable
local CASEngagementZone = ZONE:New( "Engagement Zone" )

-- Create a local variable (in this case called CASPlane) and 
-- using the GROUP function find the aircraft group called "Plane" and assign to this variable
local CASPlane = GROUP:FindByName( "Plane" )

-- Create a local Variable (in this cased called PatrolZone and 
-- using the ZONE function find the pre-defined zone called "Patrol Zone" and assign it to this variable
local PatrolZone = ZONE:New( "Patrol Zone" )

-- Create and object (in this case called AICasZone) and 
-- using the functions AI_CAS_ZONE assign the parameters that define this object 
-- (in this case PatrolZone, 500, 1000, 500, 600, CASEngagementZone) 
local AICasZone = AI_CAS_ZONE:New( PatrolZone, 500, 1000, 500, 600, CASEngagementZone )

-- Create an object (in this case called Targets) and 
-- using the GROUP function find the group labeled "Targets" and assign it to this object
local Targets = GROUP:FindByName("Targets")


-- Tell the program to use the object (in this case called CASPlane) as the group to use in the CAS function
AICasZone:SetControllable( CASPlane )

-- Tell the group CASPlane to start the mission in 1 second. 
AICasZone:__Start( 1 ) -- They should statup, and start patrolling in the PatrolZone.

-- After 10 minutes, tell the group CASPlane to engage the targets located in the engagement zone called CASEngagement Zone. (600 is 600 seconds) 
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


-- When the targets in the zone are destroyed, (see scheduled function), the planes will return home ...
function AICasZone:OnAfterAccomplish( Controllable, From, Event, To )
  AICasZone:__RTB( 1 )
end
