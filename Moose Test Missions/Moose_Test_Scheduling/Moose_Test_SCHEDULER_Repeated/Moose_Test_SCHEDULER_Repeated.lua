-- This test will schedule the same function 2 times.

SpawnTest = SPAWN:New( "Test" )
TestZone = ZONE:New( "TestZone" ) 

local function MessageTest()

  SpawnTest:SpawnInZone( TestZone, true )

end

-- The first after 5 seconds
TestScheduler1 = SCHEDULER:New( nil, MessageTest, {}, 5 )

-- The second after 10 seconds
TestScheduler2 = SCHEDULER:New( nil, MessageTest, {}, 10 )