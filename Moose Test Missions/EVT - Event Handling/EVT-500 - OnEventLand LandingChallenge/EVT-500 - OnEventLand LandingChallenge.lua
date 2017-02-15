---
-- Name: EVT-103 - OnEventLand Example
-- Author: CraigOwen
-- Date Created: 12 February 2017
--
-- # Situation:
--
-- A client plane is landing on an airfield, trying to pick a rope in the landing zones.
-- When the plane landed in one of the zones, a vehicle flares and a message ist printed out to the client.
-- 
-- # Test cases:
-- 
-- 1. Land the plane.
-- 2. When the plane landed, observe your message and the signal.
-- 3. Check the contents of the fields of the S_EVENT_LAND entry in the dcs.log file.

-- Create a unit which signalizes if the client landed good.
signal = UNIT:FindByName("LandingZoneChallenge - Signal")

-- Create the zones used for the landing check
-- Init Zone
InitZone = ZONE:New("LandingChallange - InitZone")
    
-- Ropes
zonegroup1 = GROUP:FindByName("LandingZoneChallenge - RopeGroup 1" )
zonegroup2 = GROUP:FindByName("LandingZoneChallenge - RopeGroup 2" )
zonegroup3 = GROUP:FindByName("LandingZoneChallenge - RopeGroup 3" )
LandZoneRope1 = ZONE_POLYGON:New( "Rope1", zonegroup1)
LandZoneRope2 = ZONE_POLYGON:New( "Rope2", zonegroup2)
LandZoneRope3 = ZONE_POLYGON:New( "Rope3", zonegroup3)

-- Create a variable Plane that holds a reference to CLIENT object (created by moose at the beginning of the mission) with the name "Plane".
Plane = CLIENT:FindByName( "Plane" )
-- Subscribe to the event Land. The Land event occurs when a plane lands at an airfield.
Plane:HandleEvent( EVENTS.Land )

-- This function will be called whenever the Plane-Object (client) lands!
function Plane:OnEventLand( EventData )

      -- check wether the client landet at the right airport, where the challenge is located
      if not Plane:IsInZone(InitZone) then
        return
      end
      
      -- check if the touchdown took place inside of one of the zones
      if Plane:IsInZone(LandZoneRope1) then
        MESSAGE:New("Great job! You picked the first rope.", 15, "Landing challenge" ):ToClient( Plane )             
        signal:FlareGreen()           
      elseif Plane:IsInZone(LandZoneRope2) then
        MESSAGE:New("Good job! You picked the second rope.", 15, "Landing challenge" ):ToClient( Plane )
        signal:FlareYellow()
      elseif Plane:IsInZone(LandZoneRope3) then
        MESSAGE:New("Close! You picked the last rope.", 15, "Landing challenge" ):ToClient( Plane )
        signal:FlareRed()
      else
        MESSAGE:New("Too bad, no rope picked! Thrust your engines and try again.", 15, "Landing challenge" ):ToClient( Plane )
      end
      
            
end


MESSAGE:New("Try to land on the runway in between the red trucks.", 15, "Landing challenge"):ToClient(Plane)