---
-- Name: EVT-401 - Generic OnEventHit Example
-- Author: FlightControl
-- Date Created: 15 February 2017
--
-- # Situation:
--
-- Ground targets are shooting each other.
-- 
-- # Test cases:
-- 
-- 1. Observe the ground forces shooting each other.
-- 2. Observe when a tank receives a hit, a dcs.log entry is written in the logging.
-- 3. The generic EventHandler objects should receive the hit events.

CC = COMMANDCENTER:New( UNIT:FindByName( "HQ" ), "HQ" )

EventHandler1 = EVENTHANDLER:New()
EventHandler2 = EVENTHANDLER:New()

EventHandler1:HandleEvent( EVENTS.Hit )
EventHandler2:HandleEvent( EVENTS.Hit )

function EventHandler1:OnEventHit( EventData )
  self:E("hello 1")
  CC:GetPositionable():MessageToAll( "I just got hit!", 15 , "Alert!" )
end

function EventHandler2:OnEventHit( EventData )
  self:E("hello 2")
  CC:GetPositionable():MessageToAll( "I just got hit!", 15, "Alert!" )
end


