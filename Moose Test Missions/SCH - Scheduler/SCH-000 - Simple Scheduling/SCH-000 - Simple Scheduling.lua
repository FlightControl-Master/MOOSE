--- Simple function scheduling
-- 
-- ===
-- 
-- Author: FlightControl
-- Date Created: 12 Dec 2016
--
-- # Situation
-- Uses the Tracing functions from BASE within the DCS.log file. Check the DCS.log file for the results.
-- Create a new SCHEDULER object.
-- Check the DCS.log.
-- 
-- # Test cases:
-- 
-- 1. The log should contain a "Hello World" line that is fired off 10 seconds after mission start.
--
--
-- # Status: TESTED - 12 Dec 2016

local TestScheduler = SCHEDULER:New( nil, 
  function()
    BASE:E( "Hello World 1")
  end, {}, 1 
  )

SCHEDULER:New( nil, 
  function()
    BASE:E( "Hello World 2")
  end, {}, 2
  )
    
collectgarbage()

