---
-- Name: SCO-101 - Scoring Client to Client
-- Author: FlightControl
-- Date Created: 24 Feb 2017
--
-- # Situation:
-- 
-- A shooting range has been setup to test client to client scoring.
-- 
-- # Test cases:
-- 
-- 1. Observe the scoring granted to your flight when you hit and kill other clients.


HQ = GROUP:FindByName( "HQ", "Bravo HQ" )

CommandCenter = COMMANDCENTER:New( HQ, "Lima" )

Scoring = SCORING:New( "Detect Demo" )


