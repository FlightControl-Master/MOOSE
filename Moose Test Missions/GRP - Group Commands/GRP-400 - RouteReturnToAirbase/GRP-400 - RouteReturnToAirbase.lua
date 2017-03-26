--- 
-- Name: GRP-400 - RouteReturnToAirbase
-- Author: FlightControl
-- Date Created: 25 Mar 2017
--
-- # Situation:
-- Three air units are flying and are commanded to return a specific airbase.
-- 
-- # Test cases:
-- 
-- 1. Observe the Air1 group return to Batumi after 10 seconds.
-- 2. Observe the Air2 group returning to Kobuleti after 300 seconds. (It was planned to land at Kutaisi).
-- 3. Observe the Air3 group returning to the home (landing) airbase after 300 seconds. (It was planned to land at Kutaisi).
-- 

--- @param Wrapper.Group#GROUP AirGroup
function ReturnToBatumi( AirGroup )
  BASE:E("ReturnToBatumi")
  AirGroup:RouteRTB( AIRBASE:FindByName("Batumi") )
end

--- @param Wrapper.Group#GROUP AirGroup
function ReturnToKobuleti( AirGroup )
  BASE:E("ReturnToKobuleti")
  AirGroup:RouteRTB( AIRBASE:FindByName("Kobuleti") )
end

--- @param Wrapper.Group#GROUP AirGroup
function ReturnToHome( AirGroup )
  BASE:E("ReturnToHome")
  AirGroup:RouteRTB()
end

Air1Group = GROUP:FindByName( "Air1" )
Air2Group = GROUP:FindByName( "Air2" )
Air3Group = GROUP:FindByName( "Air3" )

Scheduler = SCHEDULER:New( nil )
ScheduleIDAir1 = Scheduler:Schedule(nil, ReturnToBatumi, { Air1Group }, 10 )
ScheduleIDAir2 = Scheduler:Schedule(nil, ReturnToKobuleti, { Air2Group }, 300 )
ScheduleIDAir3 = Scheduler:Schedule(nil, ReturnToHome, { Air3Group }, 300 )




