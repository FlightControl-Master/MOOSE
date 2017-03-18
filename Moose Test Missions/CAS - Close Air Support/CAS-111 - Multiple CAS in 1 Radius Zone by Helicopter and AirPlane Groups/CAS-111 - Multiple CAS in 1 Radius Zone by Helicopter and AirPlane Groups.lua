---
-- Name: CAS-111 - Multiple CAS in 1 Radius Zone by Helicopter and AirPlane Groups
-- Author: FlightControl
-- Date Created: 6 February 2017
--
-- # Situation:
--
-- A group of 4 Ka-50 and 5 Su-25T are patrolling north in two engage zone for 5 minutes.
-- After 5 minutes, the command center orders the groups to engage the zone and execute a CAS.
--
-- # Test cases:
-- 
-- 1. Observe that the groups is patrolling in the patrol zone, until the engage command is given.
-- 2. The groups are not detecting any target during the patrol.
-- 3. When the groups is commanded to engage, the group will fly to the engage zone.
-- 3.1. Engage Speed for the Su-25T is set to 350 km/h.
-- 3.2. Engage Altitude for the Su-25T is set to 1500 meters.
-- 3.3. Engage Speed for the Ka-50 is set to 100 km/h.
-- 3.4. Engage Altitude for the Ka-50 is set to 150 meters.
-- 4. Detection is activated and detected targets within the engage zone are assigned for CAS.
-- 5. Observe the groups eliminating the targets.
-- 6. Observe the groups defenses.
-- 7. When all targets within the engage zone are destroyed, the groups CAS task is set to Accomplished.
-- 8. The groups will return to base.



-- Create a local variable (in this case called CASEngagementZone) and 
-- using the ZONE function find the pre-defined zone called "Engagement Zone" 
-- currently on the map and assign it to this variable
CASEngagementZone = ZONE:New( "Engagement Zone" )

-- Create a local variables (in this case called CASPlane and CASHelicopters) and 
-- using the GROUP function find the aircraft group called "Plane" and "Helicopter" and assign to these variables
CASPlane = GROUP:FindByName( "Plane" )
CASHelicopter = GROUP:FindByName( "Helicopter" )

-- Create two patrol zones, one for the Planes and one for the Helicopters.
PatrolZonePlanes = ZONE:New( "Patrol Zone Planes" )
PatrolZoneHelicopters = ZONE:New( "Patrol Zone Helicopters" )

-- Create and object (in this case called AICasZone) and 
-- using the functions AI_CAS_ZONE assign the parameters that define this object 
-- (in this case PatrolZone, 500, 1000, 500, 600, CASEngagementZone) 
AICasZonePlanes = AI_CAS_ZONE:New( PatrolZonePlanes, 400, 500, 500, 2500, CASEngagementZone )
AICasZoneHelicopters = AI_CAS_ZONE:New( PatrolZoneHelicopters, 100, 250, 300, 1000, CASEngagementZone )

-- Create an object (in this case called Targets) and 
-- using the GROUP function find the group labeled "Targets" and assign it to this object
Targets = GROUP:FindByName("Targets")


-- Tell the program to use the object (in this case called CASPlane) as the group to use in the CAS function
AICasZonePlanes:SetControllable( CASPlane )
AICasZoneHelicopters:SetControllable( CASHelicopter )

-- Tell the group CASPlane to start the mission in 1 second. 
AICasZonePlanes:__Start( 1 ) -- They should startup, and start patrolling in the PatrolZone.
AICasZoneHelicopters:__Start( 1 ) -- They should startup, and start patrolling in the PatrolZone.

-- After 10 minutes, tell the group CASPlanes and CASHelicopters to engage the targets located in the engagement zone called CASEngagement Zone. 
AICasZonePlanes:__Engage( 300, 350, 1500 ) -- Engage with a speed of 350 km/h and 1500 meter altitude.
AICasZoneHelicopters:__Engage( 300, 100, 150 ) -- Engage with a speed of 100 km/h and 150 meter altitude.


-- Check every 60 seconds whether the Targets have been eliminated.
-- When the trigger completed has been fired, the Planes and Helicopters will go back to the Patrol Zone.
Check, CheckScheduleID = SCHEDULER:New(nil,
  function()
    if Targets:IsAlive() and Targets:GetSize() > 5 then
      BASE:E( "Test Mission: " .. Targets:GetSize() .. " targets left to be destroyed.")
    else
      BASE:E( "Test Mission: The required targets are destroyed." )
      Check:Stop( CheckScheduleID )
      AICasZonePlanes:__Accomplish( 1 ) -- Now they should fly back to teh patrolzone and patrol.
      AICasZoneHelicopters:__Accomplish( 1 ) -- Now they should fly back to teh patrolzone and patrol.
    end
  end, {}, 20, 60, 0.2 )


-- When the targets in the zone are destroyed, (see scheduled function), the planes will return home ...
function AICasZonePlanes:OnAfterAccomplish( Controllable, From, Event, To )
  BASE:E( "Test Mission: Sending the Su-25T back to base." )
  AICasZonePlanes:__RTB( 1 )
end

-- When the targets in the zone are destroyed, (see scheduled function), the helicpters will return home ...
function AICasZoneHelicopters:OnAfterAccomplish( Controllable, From, Event, To )
  BASE:E( "Test Mission: Sending the Ka-50 back to base." )
  AICasZoneHelicopters:__RTB( 1 )
end
