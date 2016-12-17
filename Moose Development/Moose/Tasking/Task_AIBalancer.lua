--- This module contains the AI_BALANCER class.
-- 
-- ===
-- 
-- 1) @{AI.AI_Balancer#AI_BALANCER} class, extends @{Core.Base#BASE}
-- =======================================================
-- The @{AI.AI_Balancer#AI_BALANCER} class controls the dynamic spawning of AI GROUPS depending on a SET_CLIENT.
-- There will be as many AI GROUPS spawned as there at CLIENTS in SET_CLIENT not spawned.
-- The AI_Balancer uses the @{PatrolCore.Zone#AI_PATROLZONE} class to make AI patrol an zone until the fuel treshold is reached.
-- 
-- 1.1) AI_BALANCER construction method:
-- ------------------------------------
-- Create a new AI_BALANCER object with the @{#AI_BALANCER.New} method:
-- 
--    * @{#AI_BALANCER.New}: Creates a new AI_BALANCER object.
-- 
-- 1.2) AI_BALANCER returns AI to Airbases:
-- ---------------------------------------
-- You can configure to have the AI to return to:
-- 
--    * @{#AI_BALANCER.ReturnToHomeAirbase}: Returns the AI to the home @{Wrapper.Airbase#AIRBASE}.
--    * @{#AI_BALANCER.ReturnToNearestAirbases}: Returns the AI to the nearest friendly @{Wrapper.Airbase#AIRBASE}.
-- 
-- 1.3) AI_BALANCER allows AI to patrol specific zones:
-- ---------------------------------------------------
-- Use @{AI.AI_Balancer#AI_BALANCER.SetPatrolZone}() to specify a zone where the AI needs to patrol.
--
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
-- @field Functional.Spawn#SPAWN SpawnAI
-- @field #boolean ToNearestAirbase
-- @field Core.Set#SET_AIRBASE ReturnAirbaseSet
-- @field Dcs.DCSTypes#Distance ReturnTresholdRange
-- @field #boolean ToHomeAirbase
-- @field PatrolCore.Zone#AI_PATROLZONE PatrolZone
-- @extends Core.Base#BASE
AI_BALANCER = {
  ClassName = "AI_BALANCER",
  PatrolZones = {},
  AIGroups = {},
}

--- Creates a new AI_BALANCER object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #AI_BALANCER self
-- @param SetClient A SET_CLIENT object that will contain the CLIENT objects to be monitored if they are alive or not (joined by a player).
-- @param SpawnAI A SPAWN object that will spawn the AI units required, balancing the SetClient.
-- @return #AI_BALANCER self
function AI_BALANCER:New( SetClient, SpawnAI )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.SetClient = SetClient
  if type( SpawnAI ) == "table" then
    if SpawnAI.ClassName and SpawnAI.ClassName == "SPAWN" then
      self.SpawnAI = { SpawnAI }
    else
      local SpawnObjects = true
      for SpawnObjectID, SpawnObject in pairs( SpawnAI ) do
        if SpawnObject.ClassName and SpawnObject.ClassName == "SPAWN" then
          self:E( SpawnObject.ClassName )
        else
          self:E( "other object" )
          SpawnObjects = false
        end
      end
      if SpawnObjects == true then
        self.SpawnAI = SpawnAI
      else
        error( "No SPAWN object given in parameter SpawnAI, either as a single object or as a table of objects!" )
      end
    end
  end

  self.ToNearestAirbase = false
  self.ReturnHomeAirbase = false

  self.AIMonitorSchedule = SCHEDULER:New( self, self._ClientAliveMonitorScheduler, {}, 1, 10, 0 ) 
  
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

--- Let the AI patrol a @{Zone} with a given Speed range and Altitude range.
-- @param #AI_BALANCER self
-- @param PatrolCore.Zone#AI_PATROLZONE PatrolZone The @{PatrolZone} where the AI needs to patrol.
-- @return PatrolCore.Zone#AI_PATROLZONE self
function AI_BALANCER:SetPatrolZone( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed )

  self.PatrolZone = AI_PATROLZONE:New(
    self.SpawnAI,
    PatrolZone,
    PatrolFloorAltitude,
    PatrolCeilingAltitude,
    PatrolMinSpeed,
    PatrolMaxSpeed
  )
end

--- Get the @{PatrolZone} object assigned by the @{AI_Balancer} object.
-- @param #AI_BALANCER self
-- @return PatrolCore.Zone#AI_PATROLZONE PatrolZone The @{PatrolZone} where the AI needs to patrol.
function AI_BALANCER:GetPatrolZone()

  return self.PatrolZone
end



--- @param #AI_BALANCER self
function AI_BALANCER:_ClientAliveMonitorScheduler()

  self.SetClient:ForEachClient(
    --- @param Wrapper.Client#CLIENT Client
    function( Client )
      local ClientAIAliveState = Client:GetState( self, 'AIAlive' )
      self:T( ClientAIAliveState )
      if Client:IsAlive() then
        if ClientAIAliveState == true then
          Client:SetState( self, 'AIAlive', false )
          
          local AIGroup = self.AIGroups[Client.UnitName] -- Wrapper.Group#GROUP
          
--          local PatrolZone = Client:GetState( self, "PatrolZone" )
--          if PatrolZone then
--            PatrolZone = nil
--            Client:ClearState( self, "PatrolZone" )
--          end
          
          if self.ToNearestAirbase == false and self.ToHomeAirbase == false then
            AIGroup:Destroy()
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
                local AIGroupTemplate = AIGroup:GetTemplate()
                if PlayerInRange.Value == false then
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
              end
              , RangeZone, AIGroup, PlayerInRange
            )
            
          end
        end
      else
        if not ClientAIAliveState or ClientAIAliveState == false then
          Client:SetState( self, 'AIAlive', true )
          
          
          -- OK, spawn a new group from the SpawnAI objects provided.
          local SpawnAICount = #self.SpawnAI
          local SpawnAIIndex = math.random( 1, SpawnAICount )
          local AIGroup = self.SpawnAI[SpawnAIIndex]:Spawn()
          AIGroup:E( "spawning new AIGroup" )
          --TODO: need to rework UnitName thing ...
          self.AIGroups[Client.UnitName] = AIGroup
          
          --- Now test if the AIGroup needs to patrol a zone, otherwise let it follow its route...
          if self.PatrolZone then
            self.PatrolZones[#self.PatrolZones+1] = AI_PATROLZONE:New(
              self.PatrolZone.PatrolZone,
              self.PatrolZone.PatrolFloorAltitude,
              self.PatrolZone.PatrolCeilingAltitude,
              self.PatrolZone.PatrolMinSpeed,
              self.PatrolZone.PatrolMaxSpeed
            )
            
            if self.PatrolZone.PatrolManageFuel == true then
              self.PatrolZones[#self.PatrolZones]:ManageFuel( self.PatrolZone.PatrolFuelTresholdPercentage, self.PatrolZone.PatrolOutOfFuelOrbitTime )
            end 
            self.PatrolZones[#self.PatrolZones]:SetGroup( AIGroup )
            
            --self.PatrolZones[#self.PatrolZones+1] = PatrolZone
            
            --Client:SetState( self, "PatrolZone", PatrolZone )
          end
        end
      end
    end
  )
  return true
end



