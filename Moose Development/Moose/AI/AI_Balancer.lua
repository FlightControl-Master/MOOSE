--- This module contains the AI_BALANCER class.
-- 
-- ===
-- 
-- 1) @{AI.AI_Balancer#AI_BALANCER} class, extends @{Core.Fsm#FSM_SET}
-- ===================================================================================
-- The @{AI.AI_Balancer#AI_BALANCER} class monitors and manages as many AI GROUPS as there are
-- CLIENTS in a SET_CLIENT collection not occupied by players.
-- The AI_BALANCER class manages internally a collection of AI management objects, which govern the behaviour 
-- of the underlying AI GROUPS.
-- 
-- The parent class @{Core.Fsm#FSM_SET} manages the functionality to control the Finite State Machine (FSM) 
-- and calls for each event the state transition methods providing the internal @{Core.Fsm#FSM_SET.Set} object containing the
-- SET_GROUP and additional event parameters provided during the event.
-- 
-- 1.1) AI_BALANCER construction method
-- ---------------------------------------
-- Create a new AI_BALANCER object with the @{#AI_BALANCER.New} method:
-- 
--    * @{#AI_BALANCER.New}: Creates a new AI_BALANCER object.
--    
-- 1.2) 
-- ----
--    * Add
--    * Remove
-- 
-- 1.2) AI_BALANCER returns AI to Airbases
-- ------------------------------------------
-- You can configure to have the AI to return to:
-- 
--    * @{#AI_BALANCER.ReturnToHomeAirbase}: Returns the AI to the home @{Wrapper.Airbase#AIRBASE}.
--    * @{#AI_BALANCER.ReturnToNearestAirbases}: Returns the AI to the nearest friendly @{Wrapper.Airbase#AIRBASE}.
-- --
-- ===
-- 
-- **API CHANGE HISTORY**
-- ======================
-- 
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
-- 
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
-- 
-- Hereby the change log:
-- 
-- 2016-08-17: SPAWN:**InitCleanUp**( SpawnCleanUpInterval ) replaces SPAWN:_CleanUp_( SpawnCleanUpInterval )
-- 
--    * Want to ensure that the methods starting with **Init** are the first called methods before any _Spawn_ method is called!
--    * This notation makes it now more clear which methods are initialization methods and which methods are Spawn enablement methods.
-- 
-- ===
-- 
-- AUTHORS and CONTRIBUTIONS
-- =========================
-- 
-- ### Contributions: 
-- 
--   * **Dutch_Baron (James)**: Who you can search on the Eagle Dynamics Forums.  
--   Working together with James has resulted in the creation of the AI_BALANCER class.  
--   James has shared his ideas on balancing AI with air units, and together we made a first design which you can use now :-)
-- 
--   * **SNAFU**:
--   Had a couple of mails with the guys to validate, if the same concept in the GCI/CAP script could be reworked within MOOSE.
--   None of the script code has been used however within the new AI_BALANCER moose class.
-- 
-- ### Authors: 
-- 
--   * FlightControl: Framework Design &  Programming
-- 
-- @module AI_Balancer



--- AI_BALANCER class
-- @type AI_BALANCER
-- @field Core.Set#SET_CLIENT SetClient
-- @extends Core.Fsm#FSM_SET
AI_BALANCER = {
  ClassName = "AI_BALANCER",
  PatrolZones = {},
  AIGroups = {},
}

--- Creates a new AI_BALANCER object
-- @param #AI_BALANCER self
-- @param Core.Set#SET_CLIENT SetClient A SET\_CLIENT object that will contain the CLIENT objects to be monitored if they are alive or not (joined by a player).
-- @param Functional.Spawn#SPAWN SpawnAI The default Spawn object to spawn new AI Groups when needed.
-- @return #AI_BALANCER
-- @usage
-- -- Define a new AI_BALANCER Object.
function AI_BALANCER:New( SetClient, SpawnAI )
  
  -- Inherits from BASE
  local self = BASE:Inherit( self, FSM_SET:New( SET_GROUP:New() ) ) -- Core.Fsm#FSM_SET
  
  self:SetStartState( "None" )
  self:AddTransition( "*", "Start", "Monitoring" )
  self:AddTransition( "*", "Monitor", "Monitoring" )
  self:AddTransition( "*", "Spawn", "Spawning" )
  self:AddTransition( "Spawning", "Spawned", "Spawned" )
  self:AddTransition( "*", "Destroy", "Destroying" )
  self:AddTransition( "*", "Return", "Returning" )
  self:AddTransition( "*", "End", "End" )
  self:AddTransition( "*", "Dead", "End" )
  
  
  
  self.SetClient = SetClient
  self.SpawnAI = SpawnAI
  self.ToNearestAirbase = false
  self.ToHomeAirbase = false
  
  self:__Start( 1 )

  return self
end

--- Returns the AI to the nearest friendly @{Wrapper.Airbase#AIRBASE}.
-- @param #AI_BALANCER self
-- @param Dcs.DCSTypes#Distance ReturnTresholdRange If there is an enemy @{Wrapper.Client#CLIENT} within the ReturnTresholdRange given in meters, the AI will not return to the nearest @{Wrapper.Airbase#AIRBASE}.
-- @param Core.Set#SET_AIRBASE ReturnAirbaseSet The SET of @{Core.Set#SET_AIRBASE}s to evaluate where to return to.
function AI_BALANCER:ReturnToNearestAirbases( ReturnTresholdRange, ReturnAirbaseSet )

  self.ToNearestAirbase = true
  self.ReturnTresholdRange = ReturnTresholdRange
  self.ReturnAirbaseSet = ReturnAirbaseSet
end

--- Returns the AI to the home @{Wrapper.Airbase#AIRBASE}.
-- @param #AI_BALANCER self
-- @param Dcs.DCSTypes#Distance ReturnTresholdRange If there is an enemy @{Wrapper.Client#CLIENT} within the ReturnTresholdRange given in meters, the AI will not return to the nearest @{Wrapper.Airbase#AIRBASE}.
function AI_BALANCER:ReturnToHomeAirbase( ReturnTresholdRange )

  self.ToHomeAirbase = true
  self.ReturnTresholdRange = ReturnTresholdRange
end

--- @param #AI_BALANCER self
-- @param Core.Set#SET_GROUP SetGroup
-- @param #string ClientName
-- @param Wrapper.Group#GROUP AIGroup
function AI_BALANCER:onenterSpawning( SetGroup, Event, From, To, ClientName )

  -- OK, Spawn a new group from the default SpawnAI object provided.
  local AIGroup = self.SpawnAI:Spawn()
  AIGroup:E( "Spawning new AIGroup" )
  --TODO: need to rework UnitName thing ...
  
  SetGroup:Add( ClientName, AIGroup )
  
  -- Fire the Spawned event. The first parameter is the AIGroup just Spawned.
  -- Mission designers can catch this event to bind further actions to the AIGroup.
  self:Spawned( AIGroup ) 
end

--- @param #AI_BALANCER self
-- @param Core.Set#SET_GROUP SetGroup
-- @param Wrapper.Group#GROUP AIGroup
function AI_BALANCER:onenterDestroying( SetGroup, Event, From, To, AIGroup )

  AIGroup:Destroy()
end

--- @param #AI_BALANCER self
-- @param Core.Set#SET_GROUP SetGroup
-- @param Wrapper.Group#GROUP AIGroup
function AI_BALANCER:onenterReturning( SetGroup, Event, From, To, AIGroup )

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
      AIGroup:MessageToRed( "Returning to " .. ClosestAirbase:GetName().. " ...", 30 )
      local RTBRoute = AIGroup:RouteReturnToAirbase( ClosestAirbase )
      AIGroupTemplate.route = RTBRoute
      AIGroup:Respawn( AIGroupTemplate )
    end

end


--- @param #AI_BALANCER self
function AI_BALANCER:onenterMonitoring( SetGroup )

  self.SetClient:ForEachClient(
    --- @param Wrapper.Client#CLIENT Client
    function( Client )
      self:E(Client.ClientName)

      local AIGroup = self.Set:Get( Client.UnitName ) -- Wrapper.Group#GROUP
      if Client:IsAlive() then

        if AIGroup and AIGroup:IsAlive() == true then

          if self.ToNearestAirbase == false and self.ToHomeAirbase == false then
            self:Destroy( AIGroup )
          else
            -- We test if there is no other CLIENT within the self.ReturnTresholdRange of the first unit of the AI group.
            -- If there is a CLIENT, the AI stays engaged and will not return.
            -- If there is no CLIENT within the self.ReturnTresholdRange, then the unit will return to the Airbase return method selected.

            local PlayerInRange = { Value = false }          
            local RangeZone = ZONE_RADIUS:New( 'RangeZone', AIGroup:GetVec2(), self.ReturnTresholdRange )
            
            self:E( RangeZone )
            
            _DATABASE:ForEachPlayer(
              --- @param Wrapper.Unit#UNIT RangeTestUnit
              function( RangeTestUnit, RangeZone, AIGroup, PlayerInRange )
                self:E( { PlayerInRange, RangeTestUnit.UnitName, RangeZone.ZoneName } )
                if RangeTestUnit:IsInZone( RangeZone ) == true then
                  self:E( "in zone" )
                  if RangeTestUnit:GetCoalition() ~= AIGroup:GetCoalition() then
                    self:E( "in range" )
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
          self:E("client not alive")
          self:Spawn( Client.UnitName )
          self:E("text after spawn")
        end
      end
      return true
    end
  )
  
  self:__Monitor( 10 )
end



