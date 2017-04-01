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


HQ = GROUP:FindByName( "HQ", "Bravo HQ" )

CommandCenter = COMMANDCENTER:New( HQ, "Bravo" )

Scoring = SCORING:New( "Shooting Range 1" )

Scoring:SetScaleDestroyScore( 10 )

Scoring:SetScaleDestroyPenalty( 40 )

Scoring:AddUnitScore( UNIT:FindByName( "Unit #001" ), 200 )

-- Test for zone scores.

-- This one is to test scoring on normal units.
ShootingRangeZone = ZONE:New( "ScoringZone1" )
Scoring:AddZoneScore( ShootingRangeZone, 200 )

-- This one is to test scoring on scenery.
-- Note that you can only destroy scenery with heavy weapons.
SceneryZone = ZONE:New( "ScoringZone2" )
Scoring:AddZoneScore( SceneryZone, 200 )

Scoring:AddStaticScore(STATIC:FindByName( "Shooting Range #010" ), 100 )
