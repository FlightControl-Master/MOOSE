---
-- Name: SCO-100 - Scoring of Statics
-- Author: FlightControl
-- Date Created: 21 Feb 2017
--
-- # Situation:
-- 
-- A shooting range has been setup. Fly the Ka-50 or the Su-25T to the statics located near the airport, and shoot them.
-- 
-- # Test cases:
-- 
-- 1. Observe the scoring granted to your flight when you hit and kill targets.


local HQ = GROUP:FindByName( "HQ", "Bravo HQ" )

local CommandCenter = COMMANDCENTER:New( HQ, "Lima" )

local Scoring = SCORING:New( "Detect Demo" )


