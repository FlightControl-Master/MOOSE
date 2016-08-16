--- 
-- MOOSE SPAWN repeat test scenario
--  -------------------------------
-- There are 8 GROUPs Spawned.
-- They fly around Kutaisi and will land.
-- Upon landing: 
-- 1. The KA-50 and the C-101EB should respawn itself directly when landed. 
-- 2. the MI-8MTV2 and the A-10C should respawn itself when the air unit has parked at the ramp.
-- 

do

  -- Declare SPAWN objects
  local Spawn_KA_50 = SPAWN:New("KA-50")
  local Spawn_MI_8MTV2 = SPAWN:New("MI-8MTV2")
  local Spawn_C_101EB = SPAWN:New("C-101EB")
  local Spawn_A_10C = SPAWN:New("A-10C")
  
  -- Choose repeat functionality
  
  -- Repeat on landing
  Spawn_KA_50:InitRepeatOnLanding()
  Spawn_C_101EB:InitRepeatOnLanding()
  
  -- Repeat on enging shutdown (when landed on the airport)
  Spawn_MI_8MTV2:InitRepeatOnEngineShutDown()
  Spawn_A_10C:InitRepeatOnEngineShutDown()
  
  -- Now SPAWN the GROUPs
  Spawn_KA_50:Spawn()
  Spawn_C_101EB:Spawn()
  Spawn_MI_8MTV2:Spawn()
  Spawn_A_10C:Spawn()
  Spawn_KA_50:Spawn()
  Spawn_C_101EB:Spawn()
  Spawn_MI_8MTV2:Spawn()
  Spawn_A_10C:Spawn()
  
  -- Now run the mission and observe the behaviour.

end
