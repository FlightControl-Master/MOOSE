--- This module contains the AIBALANCER class.
-- 
-- ===
-- 
-- 1) @{AIBalancer#AIBALANCER} class, extends @{Base#BASE}
-- ================================================
-- The @{AIBalancer#AIBALANCER} class controls the dynamic spawning of AI GROUPS depending on a SET_CLIENT.
-- There will be as many AI GROUPS spawned as there at CLIENTS in SET_CLIENT not spawned.
-- 
-- 1.1) AIBALANCER construction method:
-- ------------------------------------
-- Create a new AIBALANCER object with the @{#AIBALANCER.New} method:
-- 
--    * @{#AIBALANCER.New}: Creates a new AIBALANCER object.
-- 
-- 
-- ===
-- @module AIBalancer
-- @author FlightControl

--- AIBALANCER class
-- @type AIBALANCER
-- @field Set#SET_CLIENT SetClient
-- @field Spawn#SPAWN SpawnAI
-- @extends Base#BASE
AIBALANCER = {
  ClassName = "AIBALANCER",
}

--- Creates a new AIBALANCER object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #AIBALANCER self
-- @param SetClient A SET_CLIENT object that will contain the CLIENT objects to be monitored if they are alive or not (joined by a player).
-- @param SpawnAI A SPAWN object that will spawn the AI units required, balancing the SetClient.
-- @return #AIBALANCER self
function AIBALANCER:New( SetClient, SpawnAI )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.SetClient = SetClient
  self.SpawnAI = SpawnAI

  self.AIMonitorSchedule = SCHEDULER:New( self, self._ClientAliveMonitorScheduler, {}, 1, 10, 0 ) 
  
  return self
end

--- @param #AIBALANCER self
function AIBALANCER:_ClientAliveMonitorScheduler()

  self.SetClient:ForEachClient(
    --- @param Client#CLIENT Client
    function( Client )
      local ClientAIAliveState = Client:GetState( self, 'AIAlive' )
      self:T( ClientAIAliveState )
      if Client:IsAlive() then
        if ClientAIAliveState == true then
          Client:SetState( self, 'AIAlive', false )
          local AIGroup = Client:GetState( self, 'AIGroup' ) -- Group#GROUP
          AIGroup:Destroy()
        end
      else
        if not ClientAIAliveState or ClientAIAliveState == false then
          Client:SetState( self, 'AIAlive', true )
          Client:SetState( self, 'AIGroup', self.SpawnAI:Spawn() )
        end
      end
    end
  )
  return true
end



