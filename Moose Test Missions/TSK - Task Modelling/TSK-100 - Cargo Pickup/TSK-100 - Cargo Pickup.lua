---
-- Name: TSK-100 - Cargo Pickup
-- Author: FlightControl
-- Date Created: 25 Mar 2017
--
-- # Situation:
-- 
-- This mission demonstrates the pickup of cargo.
-- 
-- # Test cases: 
-- 
-- 

do
  HQ = GROUP:FindByName( "HQ", "Bravo HQ" )

  CommandCenter = COMMANDCENTER:New( HQ, "Lima" )

  Scoring = SCORING:New( "Pickup Demo" )

  Mission = MISSION
    :New( CommandCenter, "Transport", "High", "Pickup the team", coalition.side.BLUE )
    :AddScoring( Scoring )

  TransportHelicopters = SET_GROUP:New():FilterPrefixes( "Transport" ):FilterStart()

  CargoEngineer = UNIT:FindByName( "Engineer" )
  InfantryCargo = AI_CARGO_UNIT:New( CargoEngineer, "Engineer", "Engineer Sven", "81", 2000, 25 )

  Task_Cargo_Pickup = TASK_CARGO_TRANSPORT:New( Mission, TransportHelicopters, "Transport.001", InfantryCargo )

end	
					
