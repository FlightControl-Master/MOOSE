--- Object Repeat Scheduling.
-- 
-- ===
-- 
-- Author: FlightControl
-- Date Created: 13 Dec 2016
--
-- # Situation
-- Three objects Test1, Test2, Test 3 are created with schedule a function.
-- After 15 seconds, Test1 is nillified and Garbage Collect is done.
-- After 30 seconds, Test2 is nillified and Garbage Collect is done.
-- After 45 seconds, Test3 is nillified and Garbage Collect is done.
-- Uses the Tracing functions from BASE within the DCS.log file. Check the DCS.log file for the results.
-- Create a new SCHEDULER object.
-- Check the DCS.log.
-- 
-- 
-- Three Test objects are created.
-- 
-- # Test cases:
-- 
-- 1. Object Test1 should start after 1 seconds showing every second "Hello World Repeat 1".
-- 2. Object Test2 should start after 2 seconds showing every 2 seconds "Hello World Repeat 2" and stop after one minute.
-- 3. Object Test3 should start after 10 seconds showing with a 10 seconds randomized interval of 10 seconds "Hello World Repeat 3" and stop after one minute.
-- 4. After 15 seconds, Test1 should stop working. No "Hello World Repeat 1" may be shown after 15 seconds.
-- 5. After 30 seconds, Test2 should stop working. No "Hello World Repeat 2" may be shown after 30 seconds.
-- 6. After 45 seconds, Test3 should stop working. No "Hello World Repeat 3" may be shown after 45 seconds.
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

-- Nillify Test1 after 15 seconds and garbage collect.
local Nil1 = SCHEDULER:New( nil,
  function()
    BASE:E( "Nillify Test1 and Garbage Collect" )
    Test1 = nil
    collectgarbage()
  end, {}, 15 )

end

local Test2 = TEST_BASE:New( "Hello World Repeat 2", 2, 2, 0, 60 ) 


local Test3 = TEST_BASE:New( "Hello World Repeat 3", 10, 10, 1.0, 60 ) 

-- Nillify Test2 after 30 seconds and garbage collect.
local Nil2 = SCHEDULER:New( nil,
  function()
    BASE:E( "Nillify Test2 and Garbage Collect" )
    Test2 = nil
    collectgarbage()
  end, {}, 30 )

-- Nillify Test3 after 45 seconds and garbage collect.
local Nil3 = SCHEDULER:New( nil,
  function()
    BASE:E( "Nillify Test3 and Garbage Collect" )
    Test3 = nil
    collectgarbage()
  end, {}, 45 )

collectgarbage()
