--- Simple repeat scheduling of a function.
-- 
-- ===
-- 
-- Author: FlightControl
-- Date Created: 13 Dec 2016
--
-- # Situation
-- Uses the Tracing functions from BASE within the DCS.log file. Check the DCS.log file for the results.
-- Create a new SCHEDULER object.
-- Check the DCS.log.
-- 
-- # Test cases:
-- 
-- 1. The log should contain "Hello World Repeat" lines that is fired off 1 second after mission start and is repeated every 1 seconds.
--
--
-- # Status: TESTED - 13 Dec 2016

local TestScheduler = SCHEDULER:New( nil, 
  function()
    BASE:E( "Hello World Repeat")
  end, {}, 1, 1
  )