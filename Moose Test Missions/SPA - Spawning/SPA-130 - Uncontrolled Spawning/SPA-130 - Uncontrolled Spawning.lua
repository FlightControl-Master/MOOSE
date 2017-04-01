---
-- Name: SPA-130 - Uncontrolled Spawning
-- Author: FlightControl
-- Date Created: 04 Feb 2017
--
-- # Situation:
--
-- A plane will be spawned Uncontrolled and later one will be spawned Controlled.
-- Only the Controlled plane will move, the other will remain idle at the parking spot.
-- 
-- # Test cases:
-- 
-- 1. Observe the spawning of the UnControlled Plane.
-- 2. Observe the spawning of the Controlled Plane.


-- Create the SPAWN object looking for the group (template) "Plane".
SpawnPlane = SPAWN:New( "Plane" )

-- Set the spawn mode to UnControlled.
SpawnPlane:InitUnControlled( true )

-- Spawn the UnControlled Group
UnControlledPlane = SpawnPlane:Spawn()

-- Set the spawn mode back to Controlled.
SpawnPlane:InitUnControlled( false )

ControlledPlane = SpawnPlane:Spawn()

-- Now, let's create a menu option at a player slot plane...
-- We can only create the menu option if the player has joined the slot ...
PlayerPlane = CLIENT:FindByName( "PlayerPlane", "Select Menu item to activate UnControlled plane" )

PlayerPlane:Alive(
  function( Client, SpawnPlane )
  
    --- @param Functional.Spawn#SPAWN SpawnPlane
    local function ActivatePlane( SpawnPlane )
      SpawnPlane:InitUnControlled( false )
      SpawnPlane:ReSpawn( 1 )
    end
  
    local Menu = MENU_CLIENT_COMMAND:New( Client, "Select to activate UnControlled plane", nil, ActivatePlane, SpawnPlane )
  end
  , SpawnPlane 
)