--- 
-- Name: GRP-310 - Command StopRoute
-- Author: FlightControl
-- Date Created: 25 Mar 2017
--
-- # Situation:
-- A ground unit is moving.
-- Using the command CommandStopMove it will stop moving after 10 seconds.
-- 
-- # Test cases:
-- 
-- 1. Observe the ground group stopping to move.
-- 

--- @param Wrapper.Group#GROUP GroundGroup
function StopMove( GroundGroup )
  
  BASE:E("Stop")
  local Command = GroundGroup:CommandStopRoute( true )
  GroundGroup:SetCommand(Command)

end

--- @param Wrapper.Group#GROUP GroundGroup
function StartMove( GroundGroup )
  
  BASE:E("Start")
  local Command = GroundGroup:CommandStopRoute( false )
  GroundGroup:SetCommand(Command)

end

GroundGroup = GROUP:FindByName( "Ground" )

Scheduler = SCHEDULER:New( nil )
ScheduleIDStop = Scheduler:Schedule(nil, StopMove, { GroundGroup }, 10, 20 )
ScheduleIDStart = Scheduler:Schedule(nil, StartMove, { GroundGroup }, 20, 20 )


