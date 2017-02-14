---
-- Name: SPA-121 - Air Ops - Scheduled Spawns with Repeat on Landing with Limit
-- Author: FlightControl
-- Date Created: 05 Feb 2017
--
-- # Situation:
--
-- One airplane and one helicopter will be spawned.
-- Only one airplane and one helicopter can be alive at the same time.
-- Upon landing, the airplane and helicopter will respawn at Kutaisi.
-- 
-- # Test cases:
-- 
-- 1. Observe the spawning of the airplane and helicopter
-- 2. There should not be more airplanes alive than there are set by InitLimit.
-- 3. Upon landing, the planes should respawn.
-- 4. The KA-50 should respawn itself directly when landed. 
-- 5. The A-10C should respawn itself when the air unit has parked at the ramp.


do

  -- Declare SPAWN objects
  local Spawn_KA_50 = SPAWN:New("KA-50"):InitLimit( 1, 10 )
  local Spawn_A_10C = SPAWN:New("A-10C"):InitLimit( 1, 10 )
  
  -- Choose repeat functionality
  
  -- Repeat on landing
  Spawn_KA_50:InitRepeatOnLanding()
  
  -- Repeat on enging shutdown (when landed on the airport)
  Spawn_A_10C:InitRepeatOnEngineShutDown()
  
  -- Now SPAWN the GROUPs
  Spawn_KA_50:SpawnScheduled(30,0)
  Spawn_A_10C:SpawnScheduled(30,0)
  
  -- Now run the mission and observe the behaviour.

end
