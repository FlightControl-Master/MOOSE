-- Name: AIB-007 - AI Balancers For all airports and both coalitions
-- Author: Delta99
-- Date Created: 11 Feb 2017
--
-- Originally created to solve issues jg7xman (from Moose Slack group) was having in creating
-- AI_BALANCER across multiple airbases.

-- # Situation:
--
-- AI_BALANCERS created per airbase for both coalitions. Mutiple patrol zones are created
-- for each side. Each flight that is created by AI_BALANCER will pick a random patrol zone
-- to patrol.

-- # Test Cases
--
-- 1. Observe at least 1 flight spawning and taking off from each airbase.
-- 2. Each flight patrols randomly in one of its sides zones.
-- 3. AI will respawn after killed.
-- 4. Additional client slots are available at Sochi. If players don't take a slot there
--    will be more than one AI taking off from Sochi.
-- 5. Batumi contains a flight of 3 units rather than just 1 like most of the rest of the airbases.
-- 6. Watch the coalition AI clash and kill each other. 

-- Create the Red Patrol Zone Array

-- This zone array will be used in the AI_BALANCER to randomize the patrol
-- zone that each spawned group will patrol

RedPatrolZone = {}
RedPatrolZone[1] = ZONE:New( "RedPatrolZone1" )
RedPatrolZone[2] = ZONE:New( "RedPatrolZone2" )
RedPatrolZone[3] = ZONE:New( "RedPatrolZone3" )
RedPatrolZone[4] = ZONE:New( "RedPatrolZone4" )
RedPatrolZone[5] = ZONE:New( "RedPatrolZone5" )
RedPatrolZone[6] = ZONE:New( "RedPatrolZone6" )

-- Russian CAP Aircraft

-- These are the aircraft created in the mission editor that the AI will spawn
-- with replacing any CLIENT created aircraft in the mission that a human
-- player does not take.

RU_PlanesSpawn = {}
RU_PlanesSpawn[1] = SPAWN:New( "RU CAP Anapa AB" ):InitCleanUp( 45 )
RU_PlanesSpawn[2] = SPAWN:New( "RU CAP Beslan AB" ):InitCleanUp( 45 )
RU_PlanesSpawn[3] = SPAWN:New( "RU CAP Gelendzhik AB" ):InitCleanUp( 45 )
RU_PlanesSpawn[4] = SPAWN:New( "RU CAP Krasnodar Center AB" ):InitCleanUp( 45 )
RU_PlanesSpawn[5] = SPAWN:New( "RU CAP Krasnodar Pashkovsky AB" ):InitCleanUp( 45 )
RU_PlanesSpawn[6] = SPAWN:New( "RU CAP Krymsk AB" ):InitCleanUp( 45 )
RU_PlanesSpawn[7] = SPAWN:New( "RU CAP Maykop AB" ):InitCleanUp( 45 )
RU_PlanesSpawn[8] = SPAWN:New( "RU CAP Mineralnye Vody AB" ):InitCleanUp( 45 )
RU_PlanesSpawn[9] = SPAWN:New( "RU CAP Mozdok AB" ):InitCleanUp( 45 )
RU_PlanesSpawn[10] = SPAWN:New( "RU CAP Nalchik AB" ):InitCleanUp( 45 )
RU_PlanesSpawn[11] = SPAWN:New( "RU CAP Novorossiysk AB" ):InitCleanUp( 45 )

-- Russian Client Aircraft (via AI_BALANCER, AI will replace these if no human players are in the slot)

-- If you want more client slots per airbase that you want AI to be able to take control of then
-- name them with the prefixes below and they will be picked up automatically by FilterPrevixes.
--
-- For example, if you want another Client slot available at Anapa name it "RU CLIENT Anapa AB 2".
-- The code here does not need to be changed. Only an addition in the mission editor. An example
-- of this can be found on the USA side at Sochi AB. 

RU_PlanesClientSet = {}
RU_PlanesClientSet[1] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Anapa AB")
RU_PlanesClientSet[2] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Beslan AB")
RU_PlanesClientSet[3] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Gelendzhik AB")
RU_PlanesClientSet[4] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Krasnodar Center AB")
RU_PlanesClientSet[5] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Krasnodar Pashkovsky AB")
RU_PlanesClientSet[6] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Krymsk AB")
RU_PlanesClientSet[7] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Maykop AB")
RU_PlanesClientSet[8] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Mineralnye Vody AB")
RU_PlanesClientSet[9] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Mozdok AB")
RU_PlanesClientSet[10] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Nalchik AB")
RU_PlanesClientSet[11] = SET_CLIENT:New():FilterPrefixes("RU CLIENT Novorossiysk AB")

-- We setup an array to store all the AI_BALANCERS that are going to be created. Basically one
-- per airbase. We loop through and create an AI_BALANCER as well as a separate OnAfterSpawned
-- function for each. The Patrol Zone is randomized in the first parameter to AI_PATROL_ZONE:New()
-- call. This is done for each of the AI_BALANCERS. To add more patrol zones, just define them in
-- the mission editor and add into the array above. Code here does not need to be changed. The
-- table.getn(RedPatrolZone) gets the number of elements in the RedPatrolZone array so that all
-- of them are included to pick randomly.


RU_AI_Balancer = {}
for i=1, 11 do
  RU_AI_Balancer[i] = AI_BALANCER:New(RU_PlanesClientSet[i], RU_PlanesSpawn[i])
  
  -- We set a local variable within the for loop to the AI_BALANCER that was just created.
  -- I couldn't get RU_AI_BALANCER[i]:OnAfterSpawn to be recognized so this is just pointing
  -- curAIBalancer to the relevant RU_AI_BALANCER array item for each loop.
  
  -- So in this case there are essentially 11 OnAfterSpawned functions defined and handled.
  
  local curAIBalancer = RU_AI_Balancer[i]
  function curAIBalancer:OnAfterSpawned( SetGroup, From, Event, To, AIGroup )
    local Patrol = AI_PATROL_ZONE:New( RedPatrolZone[math.random( 1, table.getn(RedPatrolZone))], 1500, 5500, 700, 1400 )
    Patrol:ManageFuel( 0.2, 60 )
    Patrol:SetControllable( AIGroup )
    Patrol:Start()
  end
end

-- US / Blue side is setup pretty much identically to the RU side above. Same detailed comments
-- above apply here. The main difference here is 10 airbases instead of 11.

-- Another difference is additional client slots at Sochi and a group defined at Batumi with
-- more than 1 unit per group (flight of 3 units). This is just to show that you can have more
-- client slots per airbase and more units in a single group that the AI will control. I think
-- this will also allow you to fly lead with AI on your wing or you can fly wing with an AI
-- leader. 

-- Create the Blue Patrol Zone Array
BluePatrolZone = {}
BluePatrolZone[1] = ZONE:New( "BluePatrolZone1")
BluePatrolZone[2] = ZONE:New( "BluePatrolZone2")
BluePatrolZone[3] = ZONE:New( "BluePatrolZone3")
BluePatrolZone[4] = ZONE:New( "BluePatrolZone4")
BluePatrolZone[5] = ZONE:New( "BluePatrolZone5")
BluePatrolZone[6] = ZONE:New( "BluePatrolZone6")

--United States CAP Aircraft (these are used as templates for AI)

US_PlanesSpawn = {}
US_PlanesSpawn[1] = SPAWN:New( "US CAP Batumi AB" ):InitCleanUp( 45 )
US_PlanesSpawn[2] = SPAWN:New( "US CAP Gudauta AB" ):InitCleanUp( 45 )
US_PlanesSpawn[3] = SPAWN:New( "US CAP Kobuleti AB" ):InitCleanUp( 45 )
US_PlanesSpawn[4] = SPAWN:New( "US CAP Kutaisi AB" ):InitCleanUp( 45 )
US_PlanesSpawn[5] = SPAWN:New( "US CAP Senaki AB" ):InitCleanUp( 45 )
US_PlanesSpawn[6] = SPAWN:New( "US CAP Sochi AB" ):InitCleanUp( 45 )
US_PlanesSpawn[7] = SPAWN:New( "US CAP Soganlug AB" ):InitCleanUp( 45 )
US_PlanesSpawn[8] = SPAWN:New( "US CAP Sukhumi AB" ):InitCleanUp( 45 )
US_PlanesSpawn[9] = SPAWN:New( "US CAP Vaziani AB" ):InitCleanUp( 45 )
US_PlanesSpawn[10] = SPAWN:New( "US CAP Tbilisi AB" ):InitCleanUp( 45 )

--United States Client Aircraft (via AI_BALANCER, AI will replace these if no human players are in the slot)

US_PlanesClientSet = {}
US_PlanesClientSet[1] = SET_CLIENT:New():FilterPrefixes("US CLIENT Batumi AB")
US_PlanesClientSet[2] = SET_CLIENT:New():FilterPrefixes("US CLIENT Gudauta AB")
US_PlanesClientSet[3] = SET_CLIENT:New():FilterPrefixes("US CLIENT Kobuleti AB")
US_PlanesClientSet[4] = SET_CLIENT:New():FilterPrefixes("US CLIENT Kutaisi AB")
US_PlanesClientSet[5] = SET_CLIENT:New():FilterPrefixes("US CLIENT Senaki AB")
US_PlanesClientSet[6] = SET_CLIENT:New():FilterPrefixes("US CLIENT Sochi AB")
US_PlanesClientSet[7] = SET_CLIENT:New():FilterPrefixes("US CLIENT Soganlug AB")
US_PlanesClientSet[8] = SET_CLIENT:New():FilterPrefixes("US CLIENT Sukhumi AB")
US_PlanesClientSet[9] = SET_CLIENT:New():FilterPrefixes("US CLIENT Vaziani AB")
US_PlanesClientSet[10] = SET_CLIENT:New():FilterPrefixes("US CLIENT Tbilisi AB")

US_AI_Balancer = {}
for i=1, 10 do
  US_AI_Balancer[i] = AI_BALANCER:New( US_PlanesClientSet[i], US_PlanesSpawn[i] )

  local curAIBalancer = US_AI_Balancer[i]
  function curAIBalancer:OnAfterSpawned( SetGroup, From, Event, To, AIGroup )
    local Patrol = AI_PATROL_ZONE:New( BluePatrolZone[math.random( 1, table.getn(BluePatrolZone))], 1500, 5500, 700, 1400 )
    Patrol:ManageFuel( 0.2, 60 )
    Patrol:SetControllable( AIGroup )
    Patrol:Start()
  end
end
