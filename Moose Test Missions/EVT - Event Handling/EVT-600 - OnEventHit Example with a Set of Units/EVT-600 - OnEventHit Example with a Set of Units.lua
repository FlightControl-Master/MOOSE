---
-- Name: EVT-600 - OnEventHit Example with a Set of Units
-- Author: FlightControl
-- Date Created: 6 Mar 2017
--
-- # Situation:
--
-- A plane is flying in the air and shoots an missile to a ground target.
-- It will shoot a couple of tanks units that are part of a Set.
-- 
-- # Test cases:
-- 
-- 1. Observe the plane shooting the missile.
-- 2. Observe when the plane hits a tank, a dcs.log entry is written in the logging.
-- 4. Observe the tanks hitting the targets and the messages appear.
-- 3. Check the contents of the fields of the S_EVENT_HIT entries.

Plane = UNIT:FindByName( "Plane" )

UnitSet = SET_UNIT:New():FilterPrefixes( "Tank" ):FilterStart()

UnitSet:HandleEvent( EVENTS.Hit )

function UnitSet:OnEventHit( EventData )

  Plane:MessageToAll( "I just hit a tank! " .. EventData.IniUnit:GetName(), 15, "Alert!" )
end


