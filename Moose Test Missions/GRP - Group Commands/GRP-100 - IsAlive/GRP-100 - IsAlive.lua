---
-- Name: GRP-100 - IsAlive
-- Author: FlightControl
-- Date Created: 23 Feb 2017
--
-- # Situation:
--
-- This test is about checking if IsAlive on GROUP level is working correctly.
-- Two ground forces GROUPS are shooting each other.
-- Check the IsAlive status in the logging of the survivor and the defeat.
-- 
-- # Test cases:
-- 
-- 1. Observe the IsAlive statuses in the dcs.log file.



--Create Spawn Groups
local GroupBlue = GROUP:FindByName( "Blue" )
local GroupRed = GROUP:FindByName( "Red" )

local Schedule, ScheduleID = SCHEDULER:New( nil,
  --- Variable Declarations
  -- @param Wrapper.Group#GROUP GroupBlue
  -- @param Wrapper.Group#GROUP GroupRed
  function( GroupBlue, GroupRed )
    local IsAliveBlue = GroupBlue:IsAlive()
    local IsAliveRed = GroupRed:IsAlive()
    BASE:E( { IsAliveBlue = IsAliveBlue, IsAliveRed = IsAliveRed } )
  end, { GroupBlue, GroupRed }, 1, 1 
)

