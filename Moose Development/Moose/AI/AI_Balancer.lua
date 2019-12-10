--- **AI** -- Balance player slots with AI to create an engaging simulation environment, independent of the amount of players. 
-- 
-- **Features:**
-- 
--   * Automatically spawn AI as a replacement of free player slots for a coalition.
--   * Make the AI to perform tasks.
--   * Define a maximum amount of AI to be active at the same time.
--   * Configure the behaviour of AI when a human joins a slot for which an AI is active.
-- 
-- ===
-- 
-- ### [Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release/AIB%20-%20AI%20Balancing)
-- 
-- ===
-- 
-- ### [YouTube Playlist](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl2CJVIrL1TdAumuVS8n64B7)
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: 
-- 
--   * **[Dutch_Baron](https://forums.eagle.ru/member.php?u=112075)**: Working together with James has resulted in the creation of the AI_BALANCER class. James has shared his ideas on balancing AI with air units, and together we made a first design which you can use now :-)
-- 
-- ===
-- 
-- @module AI.AI_Balancer
-- @image AI_Balancing.JPG

--- @type AI_BALANCER
-- @field Core.Set#SET_CLIENT SetClient
-- @field Core.Spawn#SPAWN SpawnAI
-- @field Wrapper.Group#GROUP Test
-- @extends Core.Fsm#FSM_SET


--- Monitors and manages as many replacement AI groups as there are
-- CLIENTS in a SET\_CLIENT collection, which are not occupied by human players. 
-- In other words, use AI_BALANCER to simulate human behaviour by spawning in replacement AI in multi player missions.
-- 
-- The parent class @{Core.Fsm#FSM_SET} manages the functionality to control the Finite State Machine (FSM). 
-- The mission designer can tailor the behaviour of the AI_BALANCER, by defining event and state transition methods.
-- An explanation about state and event transition methods can be found in the @{FSM} module documentation.
-- 
-- The mission designer can tailor the AI_BALANCER behaviour, by implementing a state or event handling method for the following:
-- 
--   * @{#AI_BALANCER.OnAfterSpawned}( AISet, From, Event, To, AIGroup ): Define to add extra logic when an AI is spawned.
-- 
-- ## 1. AI_BALANCER construction
-- 
-- Create a new AI_BALANCER object with the @{#AI_BALANCER.New}() method:
-- 
-- ## 2. AI_BALANCER is a FSM
-- 
-- ![Process](..\Presentations\AI_Balancer\Dia13.JPG)
-- 
-- ### 2.1. AI_BALANCER States
-- 
--   * **Monitoring** ( Set ): Monitoring the Set if all AI is spawned for the Clients.
--   * **Spawning** ( Set, ClientName ): There is a new AI group spawned with ClientName as the name of reference.
--   * **Spawned** ( Set, AIGroup ): A new AI has been spawned. You can handle this event to customize the AI behaviour with other AI FSMs or own processes.
--   * **Destroying** ( Set, AIGroup ): The AI is being destroyed.
--   * **Returning** ( Set, AIGroup ): The AI is returning to the airbase specified by the ReturnToAirbase methods. Handle this state to customize the return behaviour of the AI, if any.
-- 
-- ### 2.2. AI_BALANCER Events
-- 
--   * **Monitor** ( Set ): Every 10 seconds, the Monitor event is triggered to monitor the Set.
--   * **Spawn** ( Set, ClientName ): Triggers when there is a new AI group to be spawned with ClientName as the name of reference.
--   * **Spawned** ( Set, AIGroup ): Triggers when a new AI has been spawned. You can handle this event to customize the AI behaviour with other AI FSMs or own processes.
--   * **Destroy** ( Set, AIGroup ): The AI is being destroyed.
--   * **Return** ( Set, AIGroup ): The AI is returning to the airbase specified by the ReturnToAirbase methods.
--    
-- ## 3. AI_BALANCER spawn interval for replacement AI
-- 
-- Use the method @{#AI_BALANCER.InitSpawnInterval}() to set the earliest and latest interval in seconds that is waited until a new replacement AI is spawned.
-- 
-- ## 4. AI_BALANCER returns AI to Airbases
-- 
-- By default, When a human player joins a slot that is AI_BALANCED, the AI group will be destroyed by default. 
-- However, there are 2 additional options that you can use to customize the destroy behaviour.
-- When a human player joins a slot, you can configure to let the AI return to:
-- 
--    * @{#AI_BALANCER.ReturnToHomeAirbase}: Returns the AI to the **home** @{Wrapper.Airbase#AIRBASE}.
--    * @{#AI_BALANCER.ReturnToNearestAirbases}: Returns the AI to the **nearest friendly** @{Wrapper.Airbase#AIRBASE}.
-- 
-- Note that when AI returns to an airbase, the AI_BALANCER will trigger the **Return** event and the AI will return, 
-- otherwise the AI_BALANCER will trigger a **Destroy** event, and the AI will be destroyed.
-- 
-- @field #AI_BALANCER
AI_BALANCER = {
  ClassName = "AI_BALANCER",
  PatrolZones = {},
  AIGroups = {},
  Earliest = 5, -- Earliest a new AI can be spawned is in 5 seconds.
  Latest = 60, -- Latest a new AI can be spawned is in 60 seconds.
}



--- Creates a new AI_BALANCER object
-- @param #AI_BALANCER self
-- @param Core.Set#SET_CLIENT SetClient A SET\_CLIENT object that will contain the CLIENT objects to be monitored if they are alive or not (joined by a player).
-- @param Core.Spawn#SPAWN SpawnAI The default Spawn object to spawn new AI Groups when needed.
-- @return #AI_BALANCER
function AI_BALANCER:New( SetClient, SpawnAI )
  
  -- Inherits from BASE
  local self = BASE:Inherit( self, FSM_SET:New( SET_GROUP:New() ) ) -- AI.AI_Balancer#AI_BALANCER
  
  -- TODO: Define the OnAfterSpawned event
  self:SetStartState( "None" )
  self:AddTransition( "*", "Monitor", "Monitoring" )
  self:AddTransition( "*", "Spawn", "Spawning" )
  self:AddTransition( "Spawning", "Spawned", "Spawned" )
  self:AddTransition( "*", "Destroy", "Destroying" )
  self:AddTransition( "*", "Return", "Returning" )
  
  self.SetClient = SetClient
  self.SetClient:FilterOnce()
  self.SpawnAI = SpawnAI
  
  self.SpawnQueue = {}

  self.ToNearestAirbase = false
  self.ToHomeAirbase = false
  
  self:__Monitor( 1 )

  return self
end

--- Sets the earliest to the latest interval in seconds how long AI_BALANCER will wait to spawn a new AI.
-- Provide 2 identical seconds if the interval should be a fixed amount of seconds.
-- @param #AI_BALANCER self
-- @param #number Earliest The earliest a new AI can be spawned in seconds.
-- @param #number Latest The latest a new AI can be spawned in seconds.
-- @return self
function AI_BALANCER:InitSpawnInterval( Earliest, Latest )

  self.Earliest = Earliest
  self.Latest = Latest
  
  return self
end

--- Returns the AI to the nearest friendly @{Wrapper.Airbase#AIRBASE}.
-- @param #AI_BALANCER self
-- @param DCS#Distance ReturnThresholdRange If there is an enemy @{Wrapper.Client#CLIENT} within the ReturnThresholdRange given in meters, the AI will not return to the nearest @{Wrapper.Airbase#AIRBASE}.
-- @param Core.Set#SET_AIRBASE ReturnAirbaseSet The SET of @{Core.Set#SET_AIRBASE}s to evaluate where to return to.
function AI_BALANCER:ReturnToNearestAirbases( ReturnThresholdRange, ReturnAirbaseSet )

  self.ToNearestAirbase = true
  self.ReturnThresholdRange = ReturnThresholdRange
  self.ReturnAirbaseSet = ReturnAirbaseSet
end

--- Returns the AI to the home @{Wrapper.Airbase#AIRBASE}.
-- @param #AI_BALANCER self
-- @param DCS#Distance ReturnThresholdRange If there is an enemy @{Wrapper.Client#CLIENT} within the ReturnThresholdRange given in meters, the AI will not return to the nearest @{Wrapper.Airbase#AIRBASE}.
function AI_BALANCER:ReturnToHomeAirbase( ReturnThresholdRange )

  self.ToHomeAirbase = true
  self.ReturnThresholdRange = ReturnThresholdRange
end

--- @param #AI_BALANCER self
-- @param Core.Set#SET_GROUP SetGroup
-- @param #string ClientName
-- @param Wrapper.Group#GROUP AIGroup
function AI_BALANCER:onenterSpawning( SetGroup, From, Event, To, ClientName )

  -- OK, Spawn a new group from the default SpawnAI object provided.
  local AIGroup = self.SpawnAI:Spawn() -- Wrapper.Group#GROUP
  if AIGroup then
    AIGroup:T( { "Spawning new AIGroup", ClientName = ClientName } )
    --TODO: need to rework UnitName thing ...
    
    SetGroup:Remove( ClientName ) -- Ensure that the previously allocated AIGroup to ClientName is removed in the Set.
    SetGroup:Add( ClientName, AIGroup )
    self.SpawnQueue[ClientName] = nil
    
    -- Fire the Spawned event. The first parameter is the AIGroup just Spawned.
    -- Mission designers can catch this event to bind further actions to the AIGroup.
    self:Spawned( AIGroup )
  end
end

--- @param #AI_BALANCER self
-- @param Core.Set#SET_GROUP SetGroup
-- @param Wrapper.Group#GROUP AIGroup
function AI_BALANCER:onenterDestroying( SetGroup, From, Event, To, ClientName, AIGroup )

  AIGroup:Destroy()
  SetGroup:Flush( self )
  SetGroup:Remove( ClientName )
  SetGroup:Flush( self )
end

--- RTB
-- @param #AI_BALANCER self
-- @param Core.Set#SET_GROUP SetGroup
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Group#GROUP AIGroup
function AI_BALANCER:onenterReturning( SetGroup, From, Event, To, AIGroup )

    local AIGroupTemplate = AIGroup:GetTemplate()
    if self.ToHomeAirbase == true then
      local WayPointCount = #AIGroupTemplate.route.points
      local SwitchWayPointCommand = AIGroup:CommandSwitchWayPoint( 1, WayPointCount, 1 )
      AIGroup:SetCommand( SwitchWayPointCommand )
      AIGroup:MessageToRed( "Returning to home base ...", 30 )
    else
      -- Okay, we need to send this Group back to the nearest base of the Coalition of the AI.
      --TODO: i need to rework the POINT_VEC2 thing.
      local PointVec2 = POINT_VEC2:New( AIGroup:GetVec2().x, AIGroup:GetVec2().y  )
      local ClosestAirbase = self.ReturnAirbaseSet:FindNearestAirbaseFromPointVec2( PointVec2 )
      self:T( ClosestAirbase.AirbaseName )
      --[[
      AIGroup:MessageToRed( "Returning to " .. ClosestAirbase:GetName().. " ...", 30 )
      local RTBRoute = AIGroup:RouteReturnToAirbase( ClosestAirbase )
      AIGroupTemplate.route = RTBRoute
      AIGroup:Respawn( AIGroupTemplate )
      ]]
      AIGroup:RouteRTB(ClosestAirbase)
    end

end


--- @param #AI_BALANCER self
function AI_BALANCER:onenterMonitoring( SetGroup )

  self:T2( { self.SetClient:Count() } )
  --self.SetClient:Flush()

  self.SetClient:ForEachClient(
    --- @param Wrapper.Client#CLIENT Client
    function( Client )
      self:T3(Client.ClientName)

      local AIGroup = self.Set:Get( Client.UnitName ) -- Wrapper.Group#GROUP
      if AIGroup then self:T( { AIGroup = AIGroup:GetName(), IsAlive = AIGroup:IsAlive() } ) end
      if Client:IsAlive() == true then

        if AIGroup and AIGroup:IsAlive() == true then

          if self.ToNearestAirbase == false and self.ToHomeAirbase == false then
            self:Destroy( Client.UnitName, AIGroup )
          else
            -- We test if there is no other CLIENT within the self.ReturnThresholdRange of the first unit of the AI group.
            -- If there is a CLIENT, the AI stays engaged and will not return.
            -- If there is no CLIENT within the self.ReturnThresholdRange, then the unit will return to the Airbase return method selected.

            local PlayerInRange = { Value = false }          
            local RangeZone = ZONE_RADIUS:New( 'RangeZone', AIGroup:GetVec2(), self.ReturnThresholdRange )
            
            self:T2( RangeZone )
            
            _DATABASE:ForEachPlayerUnit(
              --- @param Wrapper.Unit#UNIT RangeTestUnit
              function( RangeTestUnit, RangeZone, AIGroup, PlayerInRange )
                self:T2( { PlayerInRange, RangeTestUnit.UnitName, RangeZone.ZoneName } )
                if RangeTestUnit:IsInZone( RangeZone ) == true then
                  self:T2( "in zone" )
                  if RangeTestUnit:GetCoalition() ~= AIGroup:GetCoalition() then
                    self:T2( "in range" )
                    PlayerInRange.Value = true
                  end
                end
              end,
              
              --- @param Core.Zone#ZONE_RADIUS RangeZone
              -- @param Wrapper.Group#GROUP AIGroup
              function( RangeZone, AIGroup, PlayerInRange )
                if PlayerInRange.Value == false then
                  self:Return( AIGroup )
                end
              end
              , RangeZone, AIGroup, PlayerInRange
            )
            
          end
          self.Set:Remove( Client.UnitName )
        end
      else
        if not AIGroup or not AIGroup:IsAlive() == true then
          self:T( "Client " .. Client.UnitName .. " not alive." )
          self:T( { Queue = self.SpawnQueue[Client.UnitName] } )
          if not self.SpawnQueue[Client.UnitName] then
            -- Spawn a new AI taking into account the spawn interval Earliest, Latest
            self:__Spawn( math.random( self.Earliest, self.Latest ), Client.UnitName )
            self.SpawnQueue[Client.UnitName] = true
            self:T( "New AI Spawned for Client " .. Client.UnitName )
          end
        end
      end
      return true
    end
  )
  
  self:__Monitor( 10 )
end



