--- This module contains the AIBALANCER class.
-- 
-- ===
-- 
-- 1) @{AIBalancer#AIBALANCER} class, extends @{StateMachine#STATEMACHINE_SET}
-- ===================================================================================
-- The @{AIBalancer#AIBALANCER} class monitors and manages as many AI GROUPS as there are
-- CLIENTS in a SET_CLIENT collection not occupied by players.
-- The AIBALANCER class manages internally a collection of AI management objects, which govern the behaviour 
-- of the underlying AI GROUPS.
-- 
-- The parent class @{StateMachine#STATEMACHINE_SET} manages the functionality to control the Finite State Machine (FSM) 
-- and calls for each event the state transition methods providing the internal @{StateMachine#STATEMACHINE_SET.Set} object containing the
-- SET_GROUP and additional event parameters provided during the event.
-- 
-- 1.1) AIBALANCER construction method
-- ---------------------------------------
-- Create a new AIBALANCER object with the @{#AIBALANCER.New} method:
-- 
--    * @{#AIBALANCER.New}: Creates a new AIBALANCER object.
--    
-- 1.2) 
-- ----
--    * Add
--    * Remove
-- 
-- 1.2) AIBALANCER returns AI to Airbases
-- ------------------------------------------
-- You can configure to have the AI to return to:
-- 
--    * @{#AIBALANCER.ReturnToHomeAirbase}: Returns the AI to the home @{Airbase#AIRBASE}.
--    * @{#AIBALANCER.ReturnToNearestAirbases}: Returns the AI to the nearest friendly @{Airbase#AIRBASE}.
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
--   Working together with James has resulted in the creation of the AIBALANCER class.  
--   James has shared his ideas on balancing AI with air units, and together we made a first design which you can use now :-)
-- 
--   * **SNAFU**:
--   Had a couple of mails with the guys to validate, if the same concept in the GCI/CAP script could be reworked within MOOSE.
--   None of the script code has been used however within the new AIBALANCER moose class.
-- 
-- ### Authors: 
-- 
--   * FlightControl: Framework Design &  Programming
-- 
-- @module AIBalancer



--- AIBALANCER class
-- @type AIBALANCER
-- @field Set#SET_CLIENT SetClient
-- @extends StateMachine#STATEMACHINE_SET
AIBALANCER = {
  ClassName = "AIBALANCER",
  PatrolZones = {},
  AIGroups = {},
}

--- Creates a new AIBALANCER object
-- @param #AIBALANCER self
-- @param Set#SET_CLIENT SetClient A SET\_CLIENT object that will contain the CLIENT objects to be monitored if they are alive or not (joined by a player).
-- @param Spawn#SPAWN SpawnAI The default Spawn object to spawn new AI Groups when needed.
-- @return #AIBALANCER
-- @usage
-- -- Define a new AIBALANCER Object.
function AIBALANCER:New( SetClient, SpawnAI )

  local FSMT = {
    initial = 'None',
    events = {
      { name = 'Start',             from = '*',                       to = 'Monitoring' },
      { name = 'Monitor',           from = '*',                       to = 'Monitoring' },
      { name = 'Spawn',             from = '*',                       to = 'Spawning' },
      { name = 'Destroy',           from = '*',                       to = 'Destroying' },
      { name = 'Return',            from = '*',                       to = 'Returning' },
      { name = 'End',               from = '*',                       to = 'End' },
      { name = 'Dead',              from = '*',                       to = 'End' }, 
    },
  }
  
  -- Inherits from BASE
  local self = BASE:Inherit( self, STATEMACHINE_SET:New( FSMT, SET_GROUP:New() ) )
  
  self.SetClient = SetClient
  self.SpawnAI = SpawnAI
  self.ToNearestAirbase = false
  self.ToHomeAirbase = false
  
  self:__Start( 1 )

  return self
end

--- Returns the AI to the nearest friendly @{Airbase#AIRBASE}.
-- @param #AIBALANCER self
-- @param DCSTypes#Distance ReturnTresholdRange If there is an enemy @{Client#CLIENT} within the ReturnTresholdRange given in meters, the AI will not return to the nearest @{Airbase#AIRBASE}.
-- @param Set#SET_AIRBASE ReturnAirbaseSet The SET of @{Set#SET_AIRBASE}s to evaluate where to return to.
function AIBALANCER:ReturnToNearestAirbases( ReturnTresholdRange, ReturnAirbaseSet )

  self.ToNearestAirbase = true
  self.ReturnTresholdRange = ReturnTresholdRange
  self.ReturnAirbaseSet = ReturnAirbaseSet
end

--- Returns the AI to the home @{Airbase#AIRBASE}.
-- @param #AIBALANCER self
-- @param DCSTypes#Distance ReturnTresholdRange If there is an enemy @{Client#CLIENT} within the ReturnTresholdRange given in meters, the AI will not return to the nearest @{Airbase#AIRBASE}.
function AIBALANCER:ReturnToHomeAirbase( ReturnTresholdRange )

  self.ToHomeAirbase = true
  self.ReturnTresholdRange = ReturnTresholdRange
end

--- @param #AIBALANCER self
-- @param Set#SET_GROUP SetGroup
-- @param #string ClientName
-- @param Group#GROUP AIGroup
function AIBALANCER:onenterSpawning( SetGroup, ClientName )

  -- OK, Spawn a new group from the default SpawnAI object provided.
  local AIGroup = self.SpawnAI:Spawn()
  AIGroup:E( "Spawning new AIGroup" )
  --TODO: need to rework UnitName thing ...
  
  SetGroup:Add( ClientName, AIGroup )
end

--- @param #AIBALANCER self
-- @param Set#SET_GROUP SetGroup
-- @param Group#GROUP AIGroup
function AIBALANCER:onenterDestroying( SetGroup, AIGroup )

  AIGroup:Destroy()
end

--- @param #AIBALANCER self
-- @param Set#SET_GROUP SetGroup
-- @param Group#GROUP AIGroup
function AIBALANCER:onenterReturning( SetGroup, AIGroup )

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


--- @param #AIBALANCER self
function AIBALANCER:onenterMonitoring( SetGroup )

  self.SetClient:ForEachClient(
    --- @param Client#CLIENT Client
    function( Client )
      self:E(Client.ClientName)

      local AIGroup = self.Set:Get( Client.UnitName ) -- Group#GROUP
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
              --- @param Unit#UNIT RangeTestUnit
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
              
              --- @param Zone#ZONE_RADIUS RangeZone
              -- @param Group#GROUP AIGroup
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



