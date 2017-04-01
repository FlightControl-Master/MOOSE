---
-- Name: CAS-003 - CAS in a Zone by Airplane Group - Engage with Speed and Altitude
-- Author: FlightControl
-- Date Created: 6 February 2017
--
-- # Situation:
--
-- A group of 4 Su-25T at patrolling north of an engage zone for 1 minute.
-- After 1 minute, the command center orders the Su-25T to engage the zone and execute a CAS.
--
-- # Test cases:
-- 
-- 1. Observe that the Su-25T is patrolling in the patrol zone, until the engage command is given.
-- 2. The Su-25T are not detecting any target during the patrol.
-- 3. When the Su-25T is commanded to engage, the group will fly to the engage zone
-- 3.1. The approach speed to the engage zone is set to 400 km/h.
-- 3.2. The altitude to the engage zone and CAS execution is set to 500 meters.
-- 4. Detection is activated and detected targets within the engage zone are assigned for CAS.
-- 5. Observe the Su-25T eliminating the targets.
-- 6. Observe the Su-25T defenses.
-- 7. When all targets within the engage zone are destroyed, the Su-25T CAS task is set to Accomplished.
-- 8. The Su-25T will return to base.



-- Create a local variable (in this case called CASEngagementZone) and 
-- using the ZONE function find the pre-defined zone called "Engagement Zone" 
-- currently on the map and assign it to this variable
CASEngagementZone = ZONE:New( "Engagement Zone" )

-- Create a local variable (in this case called CASPlane) and 
-- using the GROUP function find the aircraft group called "Plane" and assign to this variable
CASPlane = GROUP:FindByName( "Plane" )

-- Create a local Variable (in this cased called PatrolZone and 
-- using the ZONE function find the pre-defined zone called "Patrol Zone" and assign it to this variable
PatrolZone = ZONE:New( "Patrol Zone" )

-- Create and object (in this case called AICasZone) and 
-- using the functions AI_CAS_ZONE assign the parameters that define this object 
-- (in this case PatrolZone, 500, 1000, 500, 600, CASEngagementZone) 
AICasZone = AI_CAS_ZONE:New( PatrolZone, 500, 1000, 500, 600, CASEngagementZone )

-- Create an object (in this case called Targets) and 
-- using the GROUP function find the group labeled "Targets" and assign it to this object
Targets = GROUP:FindByName("Targets")


-- Tell the program to use the object (in this case called CASPlane) as the group to use in the CAS function
AICasZone:SetControllable( CASPlane )

-- Tell the group CASPlane to start the mission in 1 second. 
AICasZone:__Start( 1 ) -- They should statup, and start patrolling in the PatrolZone.

-- After 10 minutes, tell the group CASPlane to engage the targets located in the engagement zone called CASEngagement Zone. (600 is 600 seconds) 
AICasZone:__Engage( 600, 350, 4000 ) -- Engage after 10 minutes with a speed of 350 km/h and an altitude of 4000 meters.

-- Check every 60 seconds whether the Targets have been eliminated.
-- When the trigger completed has been fired, the Plane will go back to the Patrol Zone.
Check, CheckScheduleID = SCHEDULER:New(nil,
  function()
    if Targets:IsAlive() and Targets:GetSize() > 5 then
      BASE:E( "Test Mission: " .. Targets:GetSize() .. " targets left to be destroyed.")
    else
      BASE:E( "Test Mission: The required targets are destroyed." )
      AICasZone:__Accomplish( 1 ) -- Now they should fly back to teh patrolzone and patrol.
    end
  end, {}, 20, 60, 0.2 )


-- When the targets in the zone are destroyed, (see scheduled function), the planes will return home ...
function AICasZone:OnAfterAccomplish( Controllable, From, Event, To )
  BASE:E( "Test Mission: Sending the Su-25T back to base." )
  Check:Stop( CheckScheduleID )
  AICasZone:__RTB( 1 )
end
