-- Name: ZON-510 - Send message if Clients fly the first time in the Polygon Zones
-- Author: Wingthor and FlightControl
-- Date Created: 20 January 2017
--
-- # Situation:
--
-- There are a couple of player slots of Su-25Ts, that need to fly through two poly zones. 
-- Once a player flies through a poly zone, a message will be sent. But only once. If he flies back through the same zone,
-- nothing is displayed anymore. Unless he logs off and rejoins the mission.
--
-- # Test cases:
-- 
-- 

local PolyZoneGroup1 = GROUP:FindByName("PolyZone1")
local PolyZoneGroup2 = GROUP:FindByName("PolyZone2")

local PolyZone1 = ZONE_POLYGON:New( "PolyZone1", PolyZoneGroup1 )
local PolyZone2 = ZONE_POLYGON:New( "PolyZone2", PolyZoneGroup2 )

local RedClients = SET_CLIENT:New():FilterCoalitions("red"):FilterStart()



SchedulerInit, SchedulerInitID = SCHEDULER:New( nil, 
  function()
    RedClients:ForEachClient( 
      function( MooseClient )
      
        -- Here we register the state of the client in which step he is in.
        -- We set the state of the client "ZoneStep" to 0, indicating that he is not out of the first zone.
        local function ResetClientForZone( MooseClient )
          BASE:E("Reset")
          MooseClient:SetState( MooseClient, "ZoneStep", "0" )
        end
        
        BASE:E( { "Alive Init", Client = MooseClient } )
        MooseClient:Alive( ResetClientForZone )
      end
    )
  end, {}, 1
)

Scheduler, SchedulerID = SCHEDULER:New( nil, 
  function ()
    
    RedClients:ForEachClientInZone( PolyZone1, 
      function( MooseClient )
        BASE:E( { Client = MooseClient, State = MooseClient:GetState( MooseClient, "ZoneStep" ) } )
        if MooseClient:GetState( MooseClient, "ZoneStep" ) == "0" then
          MooseClient:SetState( MooseClient, "ZoneStep", "1" )
          MESSAGE:New("Lorem Ipsum", 15, "Pilot Update" ):ToClient( MooseClient )
        end
      end
      )

    RedClients:ForEachClientNotInZone( PolyZone1, 
      function( MooseClient )
        BASE:E( { Client = MooseClient, State = MooseClient:GetState( MooseClient, "ZoneStep" ) } )
        if MooseClient:GetState( MooseClient, "ZoneStep" ) == "1" then
          MooseClient:SetState( MooseClient, "ZoneStep", "2" )
          MESSAGE:New("Ipsum Ipsum", 15, "Pilot Update" ):ToClient( MooseClient )
        end
      end
      )

    RedClients:ForEachClientInZone( PolyZone2, 
      function( MooseClient )
        BASE:E( { Client = MooseClient, State = MooseClient:GetState( MooseClient, "ZoneStep" ) } )
        if MooseClient:GetState( MooseClient, "ZoneStep" ) == "2" then
          MooseClient:SetState( MooseClient, "ZoneStep", "3" )
          MESSAGE:New("Lorem Lorem", 15, "Pilot Update" ):ToClient( MooseClient )
        end
      end
      )
    
  end, {}, 10, 1 
  )

  