---
-- Name: EVT-001 - API Demo 1
-- Author: FlightControl
-- Date Created: 7 February 2017
--
-- # Situation:
--
-- A task shoots another tank. If one of the is dead, the event will be catched.
-- 
-- # Test cases:
-- 
-- 1. Observe the tanks shooting each other.
-- 2. If one of the tanks die, an event will be catched.
-- 3. Observe the surviving unit smoking.


local Tank1 = UNIT:FindByName( "Tank A" )
local Tank2 = UNIT:FindByName( "Tank B" )

Tank1:HandleEvent( EVENTS.Dead )

Tank2:HandleEvent( EVENTS.Dead )

--- @param Wrapper.Unit#UNIT self 
function Tank1:OnEventDead( EventData )

  self:SmokeGreen()
end

--- @param Wrapper.Unit#UNIT self 
function Tank2:OnEventDead( EventData )

  self:SmokeBlue()
end

function Tank2:OnEventCrash(EventData)

end


