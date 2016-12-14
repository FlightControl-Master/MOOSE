--- Simple Object Scheduling
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
-- 1. Tracing of a scheduler in an Object.  
--    The log should contain a "Hello World" line of the object, that is fired off 1 seconds after mission start.
-- 
-- # Status: TESTED - 12 Dec 2016

local TEST_BASE = {
    ClassName = "TEST_BASE",
  }
  
function TEST_BASE:New( Message )
  self = BASE:Inherit( self, BASE:New() )
  
  local TestScheduler = SCHEDULER:New( self,
    function( Object, Message )
      Object:E( Message )
    end, { Message }, 1 
    )  
end

local Test = TEST_BASE:New( "Hello World" ) 