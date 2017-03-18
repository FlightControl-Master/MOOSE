---
-- Name: EVT-104 - UNIT OnEventCrash Example
-- Author: FlightControl
-- Date Created: 7 Feb 2017
--
-- # Situation:
--
-- A human plane is fyling in the air. Crash it into the ground.
-- Once you are crashed into the ground, at the place where you crashed, a smoke should start burning ...
-- 
-- # Test cases:
-- 
-- 1. Fly the plane into the ground.
-- 2. When your plane crashes, observe a smoke starting to burn right were you crashed.
-- 3. Check the contents of the fields of the S_EVENT_CRASH entry in the dcs.log file.

-- Create a variable PlaneHuman that holds a reference to UNIT object (created by moose at the beginning of the mission) with the name "PlaneHuman".
PlaneHuman = UNIT:FindByName( "PlaneHuman" )

-- Subscribe to the event Crash. The Crash event occurs when a plane crashes into the ground (or into something else).
PlaneHuman:HandleEvent( EVENTS.Crash )

-- Because the PlaneHuman object is subscribed to the Crash event, the following method will be automatically
-- called when the Crash event is happening FOR THE PlaneHuman UNIT only!

--- @param self
-- @param Core.Event#EVENTDATA EventData
function PlaneHuman:OnEventCrash( EventData )

  -- Okay, the PlaneHuman has crashed, now smoke at the x, z position.
  self:E( "Smoking at the position" )
  EventData.IniUnit:SmokeOrange()
end


