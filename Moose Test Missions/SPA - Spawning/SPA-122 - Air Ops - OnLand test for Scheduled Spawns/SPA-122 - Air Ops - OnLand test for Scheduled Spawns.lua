---
-- Name: SPA-122 - Air Ops - OnLand test for Scheduled Spawns
-- Author: FlightControl
-- Date Created: 21 Mar 2017
--
-- # Situation:
--
-- An airplane is spawned at a scheduled interval.
-- There is a limit on how many airplanes can be alive at the same time.
-- Upon landing, the airplane will respawn in the air.
-- 
-- # Test cases:
-- 
-- 1. Observe the spawning of the airplanes
-- 2. There should not be more airplanes alive than there are set by InitLimit.
-- 3. Upon landing, the planes should respawn.
-- 4. The KA-50 and the C-101EB should respawn itself directly when landed. 
-- 5. the MI-8MTV2 and the A-10C should respawn itself when the air unit has parked at the ramp.


do

  -- Declare SPAWN objects
  Spawn_KA_50 = SPAWN:New("KA-50"):InitLimit( 1, 0 )
  Spawn_MI_8MTV2 = SPAWN:New("MI-8MTV2"):InitLimit( 1, 0 )
  Spawn_C_101EB = SPAWN:New("C-101EB"):InitLimit( 1, 0 )
  Spawn_A_10C = SPAWN:New("A-10C"):InitLimit( 1, 0 )
  
  -- Choose repeat functionality
  
  -- Repeat on landing
  Spawn_KA_50:InitRepeatOnLanding()
  Spawn_C_101EB:InitRepeatOnLanding()
  
  -- Repeat on enging shutdown (when landed on the airport)
  Spawn_MI_8MTV2:InitRepeatOnEngineShutDown()
  Spawn_A_10C:InitRepeatOnEngineShutDown()
  
  -- Now SPAWN the GROUPs
  Spawn_KA_50:SpawnScheduled(30,0)
  Spawn_C_101EB:SpawnScheduled(30,0)
  Spawn_MI_8MTV2:SpawnScheduled(30,0)
  Spawn_A_10C:SpawnScheduled(30,0)
  
  -- Now run the mission and observe the behaviour.

end
