---
-- Name: EVT-102 - UNIT OnEventTakeoff Example
-- Author: FlightControl
-- Date Created: 7 Feb 2017
--
-- # Situation:
--
-- A human plane and an AI plane are taking off from an airfield.
-- 
-- # Test cases:
-- 
-- 1. Take-Off the planes from the runway.
-- 2. When the planes take-off, observe the message being sent.
-- 3. Check the contents of the fields of the S_EVENT_TAKEOFF entry in the dcs.log file.

PlaneAI = UNIT:FindByName( "PlaneAI" )

PlaneHuman = UNIT:FindByName( "PlaneHuman" )

PlaneAI:HandleEvent( EVENTS.Takeoff )
PlaneHuman:HandleEvent( EVENTS.Takeoff )

function PlaneAI:OnEventTakeoff( EventData )

  PlaneHuman:MessageToAll( "AI Taking Off", 15, "Alert!" )
end

function PlaneHuman:OnEventTakeoff( EventData )

  PlaneHuman:MessageToAll( "Player " .. PlaneHuman:GetPlayerName() .. " is Taking Off", 15, "Alert!" )
end


