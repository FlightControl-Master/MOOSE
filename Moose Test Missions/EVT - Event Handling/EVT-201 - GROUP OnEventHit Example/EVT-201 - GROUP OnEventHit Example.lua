---
-- Name: EVT-201 - GROUP OnEventHit Example
-- Author: FlightControl
-- Date Created: 08 Mar 2017
--
-- # Situation:
--
-- Two groups of planes are flying in the air and shoot an missile to a multitude of ground targets.
-- 
-- # Test cases:
-- 
-- 1. Observe the planes shooting the missile.
-- 2. Observe when the planes shoots the missile, and hit the group Tanks A, a dcs.log entry is written in the logging.
-- 3. Check the contents of the fields of the S_EVENT_HIT entry.
-- 4. The tanks of GROUP "Group Tanks A", should only send a message when they get hit.
-- 5. The tanks of GROUP "Group Tanks B", should NOT send a message when they get hit.

TanksGroup = GROUP:FindByName( "Group Tanks A" )

TanksGroup:HandleEvent( EVENTS.Hit )

function TanksGroup:OnEventHit( EventData )

  self:E( "I just got hit and I am part of " .. EventData.TgtGroupName )
  EventData.TgtUnit:MessageToAll( "I just got hit and I am part of " .. EventData.TgtGroupName, 15, "Alert!" )
end


