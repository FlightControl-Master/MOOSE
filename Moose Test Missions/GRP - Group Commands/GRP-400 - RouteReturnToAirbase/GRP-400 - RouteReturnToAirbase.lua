--- 
-- Name: GRP-400 - RouteReturnToAirbase
-- Author: FlightControl
-- Date Created: 25 Mar 2017
--
-- # Situation:
-- Three air units are flying and are commanded to return a specific airbase.
-- The return commands are given after 10 seconds.
-- 
-- # Test cases:
-- 
-- 1. Observe the Air1 group return to Batumi.
-- 2. Observe the Air2 group returning to Sochi.
-- 3. Observe the Air3 group returning to the nearest airbase after 120 seconds.
-- 

--- @param Wrapper.Group#GROUP AirGroup
function ReturnToBatumi( AirGroup )
  BASE:E("ReturnToBatumi")
  AirGroup:RouteReturnToAirbase( AIRBASE:FindByName("Batumi") )
end

--- @param Wrapper.Group#GROUP AirGroup
function ReturnToSochi( AirGroup )
  BASE:E("ReturnToSochi")
  AirGroup:RouteReturnToAirbase( AIRBASE:FindByName("Sochi-Adler") )
end

--- @param Wrapper.Group#GROUP AirGroup
function ReturnToNearest( AirGroup )
  BASE:E("ReturnToHomeBase")
  AirGroup:RouteReturnToAirbase()
end

Air1Group = GROUP:FindByName( "Air1" )
Air2Group = GROUP:FindByName( "Air2" )
Air3Group = GROUP:FindByName( "Air3" )

Scheduler = SCHEDULER:New( nil )
ScheduleIDAir1 = Scheduler:Schedule(nil, ReturnToBatumi, { Air1Group }, 10 )
ScheduleIDAir2 = Scheduler:Schedule(nil, ReturnToSochi, { Air2Group }, 120 )
ScheduleIDAir3 = Scheduler:Schedule(nil, ReturnToNearest, { Air3Group }, 120 )




