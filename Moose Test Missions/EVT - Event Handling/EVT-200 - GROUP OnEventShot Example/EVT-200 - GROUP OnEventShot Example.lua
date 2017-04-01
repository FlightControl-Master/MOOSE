---
-- Name: EVT-200 - GROUP OnEventShot Example
-- Author: FlightControl
-- Date Created: 07 Mar 2017
--
-- # Situation:
--
-- Two groups of planes are flying in the air and shoot an missile to a multitude of ground targets.
-- 
-- # Test cases:
-- 
-- 1. Observe the planes shooting the missile.
-- 2. Observe when the planes shoots the missile, a dcs.log entry is written in the logging.
-- 3. Check the contents of the fields of the S_EVENT_SHOT entry.
-- 4. The planes of GROUP "Group Plane A", should only send a message when they shoot a missile.
-- 5. The planes of GROUP "Group Plane B", should NOT send a message when they shoot a missile.

PlaneGroup = GROUP:FindByName( "Group Plane A" )

PlaneGroup:HandleEvent( EVENTS.Shot )

function PlaneGroup:OnEventShot( EventData )

  self:E( "I just fired a missile and I am part of " .. EventData.IniGroupName )
  EventData.IniUnit:MessageToAll( "I just fired a missile and I am part of " .. EventData.IniGroupName, 15, "Alert!" )
end


