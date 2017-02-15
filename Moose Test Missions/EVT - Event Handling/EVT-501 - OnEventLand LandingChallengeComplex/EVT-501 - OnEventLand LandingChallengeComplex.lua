---
-- Name: EVT-103 - OnEventLand LandingChallengeComplex
-- Author: CraigOwen
-- Date Created: 12 February 2017
--
-- # Situation:
--
-- Approaching the airfield the client gets a message and can try to land inside the landing zones.
-- Here we want all clients to participate in the challenge, not only one. 
-- When the plane landed in one of the zones, a vehicle flares and a message ist printed out to the client.
-- 
-- # Test cases:
-- 
-- 1. Land one of the planes.
-- 2. While landing the plane, observe your message and the signal (flare).
-- 3. Check the contents of the fields of the S_EVENT_LAND entry in the dcs.log file.

-- In this advanced challenge we want to make sure all the following.
-- 1. The challenge takes place at a certain airfield.
-- 2. All clients can repeat the challange at any time, try after try.
-- 3. All clients approaching the airport get a message indicating the challenge.
-- 4. There is no useraction needet to participate in this, providing full focus on the task.

-- So lets go then... in five steps
-- 1. Create a unit to signalize (flare) whenever a client landed correctly
-- 2. Create Zones
-- 3. Create a set of clients
-- 4. Handle the EVENT.Land for all clients in the set using the signal unit
-- 5. Create a scheduler checking for clients in zones 

-- 1. Create a unit which signalizes if the client landed good.
signal = UNIT:FindByName("LandingZoneChallenge - Signal")

-- 2. Create Zones
-- Init Zone - This is the global Zone for the LandingChallenge
InitZone = ZONE:New("LandingChallange - InitZone")

--Ingress Zone - This Zone tries to asure the client approaches the runway from the right side
IngressZoneTemplate = GROUP:FindByName( "LandingZoneChallenge - IngressZone" )
IngressZone = ZONE_POLYGON:New( "IngressZone", IngressZoneTemplate )

-- Ropes - theese zones will simulate the ropes on a carrier.
zonegroup1 = GROUP:FindByName("LandingZoneChallenge - Rope 1" )
zonegroup2 = GROUP:FindByName("LandingZoneChallenge - Rope 2" )
zonegroup3 = GROUP:FindByName("LandingZoneChallenge - Rope 3" )
LandZoneRope1 = ZONE_POLYGON:New( "Rope1", zonegroup1)
LandZoneRope2 = ZONE_POLYGON:New( "Rope2", zonegroup2)
LandZoneRope3 = ZONE_POLYGON:New( "Rope3", zonegroup3)


-- 3. Create a set of clients
-- In this example we do not want to handle the event for one specific client, but rather for all red plane clients.
-- To achieve this, we start with filtering the clients and saving those into the "BlueClients" variable
RedClients = SET_CLIENT:New():FilterCoalitions("red"):FilterStart()


-- 4. We want to let every client subscribe to the event EVENT.Land. This event occurs when a plane lands. Be aware that this could be any airfield at this point.
-- To do so, we run the ForEachClient method on our set of clients and call a function taking the client as parameter
RedClients:ForEachClient( 
      --- This function will be called for every single client in the set
      -- @param MooseClient#CLIENT ClientInSet
      function( ClientInSet )
          
          -- Inside here we want to do two things. 
          -- 1. Write down the local function doing all the magic.
          -- 2. Call this function for each ClientInSet
          
          -- 1. The magic
          local function ResetClientForZone( MooseClient )          
            --At first we set this client to a state, in wich she/he is not participating in this event
            MooseClient:SetState( MooseClient, "ZoneStep", "0" )
          
            --Now we subscribe to the event just like we did in the first example.
            MooseClient:HandleEvent(EVENTS.Land)
  
            
            --- Finally we set up the so called handler FOR the event. This is a function wich will determine what happens, whenever a client lands.
            -- Note here, that the function has the MooseClient in front. So this function will literaly get a part of the client itself.
            -- Therefore we can refere to "self" inside the function whenever meaning the MooseClient
            -- The param EventData is a parameter given to all event handlers and providing several data about this particular event.
            -- @param Core.Event#EVENTDATA EventData
            function MooseClient:OnEventLand( EventData )
              
              -- Ok now the client "MooseClient" definetly has landed. And beeing here means being the client. MooseClient <-> self
              -- So now i want to know 2 things, to verify that i have done everything right.
              -- 1. I want to know if my(self) landed in the challengeZone, so landing in other places will not react to this challenge
              -- 2. Furthermore i want to know if my(self) came from the right side.
              -- In all other cases nothing shell happen, so we reset the client state here and return doin nothing else.           
              if not self:IsInZone(InitZone) or self:GetState( self, "ZoneStep" ) ~= "2" then
                self:SetState( self, "ZoneStep", "0" )
                return
              end
              
              -- Here we check wich rope was picked and set the signal and message according to it.
              if self:IsInZone(LandZoneRope1) then
                MESSAGE:New("Great job! You picked the first rope.", 15, "Landing challenge" ):ToClient( self )             
                signal:FlareGreen()           
              elseif self:IsInZone(LandZoneRope2) then
                MESSAGE:New("Good job! You picked the second rope.", 15, "Landing challenge" ):ToClient( self )
                signal:FlareYellow()
              elseif self:IsInZone(LandZoneRope3) then
                MESSAGE:New("Close! You picked the last rope.", 15, "Landing challenge" ):ToClient( self )
                signal:FlareRed()
              else
                MESSAGE:New("Too bad, no rope picked! Thrust your engines and try again.", 15, "Landing challenge" ):ToClient( self )
              end
              
              -- Finally we set the client back to step 1, allowing a new message for landing
              self:SetState( self, "ZoneStep", "1" )
              
            end
          end
          
          -- 2. As we're now all set, we can finally call our function for every ClientInSet 
          ClientInSet:Alive( ResetClientForZone )
        
      end
    )

-- 5. Finally we use a scheduler checking wether clients are inside or outside these zones.
LandingChallangeActionsScheduler, LandingChallangeActionsSchedulerID = SCHEDULER:New( nil, 
  function ()

    -- Flying by the airport there will be a message showing that the landing challange is currently in place. 
    -- This will make the ClientState shift from 0 -> 1
    RedClients:ForEachClientInZone( InitZone, 
      function( MooseClient )
        BASE:E( { Client = MooseClient, State = MooseClient:GetState( MooseClient, "ZoneStep" ) } )
        if MooseClient:IsAlive() and MooseClient:GetState( MooseClient, "ZoneStep" ) == "0" then
          MooseClient:SetState( MooseClient, "ZoneStep", "1" )
          MESSAGE:New("Welcome to the Landing challenge. If you want to participate, get yourself a landing clearance by ATC and navigate to the landing corridor.", 20, "Landing challenge" ):ToClient( MooseClient )
        end
      end
      )
    
    -- The client is approaching the runway from the correct side? 
    -- If yes, then shift state from 1 to 2
    RedClients:ForEachClientInZone( IngressZone, 
      function( MooseClient )
      BASE:E( { Client = MooseClient, State = MooseClient:GetState( MooseClient, "ZoneStep" ) } )
        if MooseClient:IsAlive() and MooseClient:GetState( MooseClient, "ZoneStep" ) == "1" then
          MooseClient:SetState( MooseClient, "ZoneStep", "2" )
          MESSAGE:New("Ok, now its your turn. Land your airframe and try to get one of the ropes. Good luck!", 15, "Landing challenge" ):ToClient( MooseClient )
        end
      end
      )    
    
  end, {}, 5, 5 
  )
  
MESSAGE:New("Try to land on the runway in between the red trucks located at the right side.", 15, "Landing challenge"):ToAll()