---
-- Name: EVT-100 - UNIT OnEventShot Example
-- Author: FlightControl
-- Date Created: 7 Feb 2017
--
-- # Situation:
--
-- A plane is flying in the air and shoots an missile to a ground target.
-- 
-- # Test cases:
-- 
-- 1. Observe the plane shooting the missile.
-- 2. Observe when the plane shoots the missile, a dcs.log entry is written in the logging.
-- 3. Check the contents of the fields of the S_EVENT_SHOT entry.

Plane = UNIT:FindByName( "Plane" )

Plane:HandleEvent( EVENTS.Shot )

function Plane:OnEventShot( EventData )

  Plane:MessageToAll( "I just fired a missile!", 15, "Alert!" )
end


