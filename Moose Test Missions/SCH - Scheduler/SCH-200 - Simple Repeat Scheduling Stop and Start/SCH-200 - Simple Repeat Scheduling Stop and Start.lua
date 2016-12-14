--- Simple repeat scheduling of a function.
-- 
-- ===
-- 
-- Author: FlightControl
-- Date Created: 14 Dec 2016
--
-- # Situation
-- Uses the Tracing functions from BASE within the DCS.log file. Check the DCS.log file for the results.
-- Create a new SCHEDULER object.
-- Check the DCS.log.
-- 
-- Start a schedule called TestScheduler. TestScheduler will repeat the words "Hello World Repeat" every second in the log.
-- After 10 seconds, TestScheduler will stop the scheduler.
-- After 20 seconds, TestScheduler will restart the scheduler.
-- 
-- # Test cases:
-- 
-- 1. Check that the "Hello World Repeat" lines are consistent with the scheduling timing. They should stop showing after 10 seconds, and restart after 20 seconds. 
--
--
-- # Status: TESTED - 14 Dec 2016

local TestScheduler = SCHEDULER:New( nil, 
  function()
    BASE:E( timer.getTime() .. " - Hello World Repeat")
  end, {}, 1, 1
  )
  
SCHEDULER:New( nil, 
  function()
    TestScheduler:Stop() 
  end, {}, 10
  )

SCHEDULER:New( nil,
  function()
    TestScheduler:Start()
  end, {}, 20
  )
  