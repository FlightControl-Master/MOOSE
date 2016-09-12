-- This test will schedule the same function 2 times.

SpawnTest = SPAWN:New( "Test" )
TestZone = ZONE:New( "TestZone" ) 

local function MessageTest2()

  SpawnTest:SpawnInZone( TestZone, true )

end

local function MessageTest1()

  SpawnTest:SpawnInZone( TestZone, true )
  
  -- The second after 10 seconds
  SCHEDULER:New( nil, MessageTest2, {}, 5 )

  -- The third after 15 seconds
  SCHEDULER:New( nil, MessageTest2, {}, 10 )
  
end

-- The first after 5 seconds
SCHEDULER:New( nil, MessageTest1, {}, 5 )

-- The fourth after 20 seconds
SCHEDULER:New( nil, MessageTest1, {}, 20 )
