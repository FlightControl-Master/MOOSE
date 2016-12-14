--- No Object Scheduling because of garbage collect and Object nillification.
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
-- A Test object is created.
-- It is nillified directly after the Schedule has been planned.
-- There should be no schedule fired.
-- The Test object should be garbage collected!
-- 
-- THIS IS A VERY IMPORTANT TEST!
-- 
-- # Test cases:
-- 
-- 1. No schedule should be fired! The destructors of the Test object should be shown.
-- 2. Commend the nillification of the Test object in the source, and test again.
--    The schedule should now be fired and Hello World should be logged through the Test object.
-- 
-- # Status: STARTED - 12 Dec 2016

local TEST_BASE = {
    ClassName = "TEST_BASE",
  }
  
function TEST_BASE:New( Message )
  self = BASE:Inherit( self, BASE:New() )
  
  self.TestScheduler = SCHEDULER:New( self,
    function( Object, Message )
      Object:E( Message )
    end, { Message }, 1 
    )
    return self
end

do
local Test1 = TEST_BASE:New( "Hello World Test 1" ) 
Test1 = nil
BASE:E( Test1 )
end

local Test2 = TEST_BASE:New( "Hello World Test 2" ) 
BASE:E( Test2 )

local Test3 = TEST_BASE:New( "Hello World Test 3" ) 
Test3 = nil
BASE:E( Test3 )

collectgarbage()

BASE:E( "Collect Garbage executed." )
BASE:E( "You should only see a Hello Worlld message for Test 2!" )
BASE:E( "Check if Test 1 and Test 3 are garbage collected!" )