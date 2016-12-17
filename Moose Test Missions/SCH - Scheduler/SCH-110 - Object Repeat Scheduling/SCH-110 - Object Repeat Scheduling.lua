--- Object Repeat Scheduling.
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
-- Three Test objects are created.
-- 
-- # Test cases:
-- 
-- 1. Object Test1 should start after 1 seconds showing every second "Hello World Repeat 1".
-- 2. Object Test2 should start after 2 seconds showing every 2 seconds "Hello World Repeat 2" and stop after one minute.
-- 3. Object Test3 should start after 10 seconds showing with a 10 seconds randomized interval of 10 seconds "Hello World Repeat 3" and stop after one minute.
-- 
-- # Status: TESTED - 13 Dec 2016

local TEST_BASE = {
    ClassName = "TEST_BASE",
  }
  
function TEST_BASE:New( Message, Start, Repeat, Randomize, Stop )
  self = BASE:Inherit( self, BASE:New() )
  
  self.TestScheduler = SCHEDULER:New( self,
    function( Object, Message )
      Object:E( Message )
    end, { Message }, Start, Repeat, Randomize, Stop
    )
    return self
end

do
local Test1 = TEST_BASE:New( "Hello World Repeat 1", 1, 1 ) 
end

local Test2 = TEST_BASE:New( "Hello World Repeat 2", 2, 2, 0, 60 ) 

local Test3 = TEST_BASE:New( "Hello World Repeat 3", 10, 10, 1.0, 60 ) 
