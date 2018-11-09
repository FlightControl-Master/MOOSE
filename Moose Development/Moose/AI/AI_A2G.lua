--- **AI** -- Models the process of air to ground operations for airplanes and helicopters.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===
-- 
-- @module AI.AI_A2G
-- @image AI_Air_To_Ground_Dispatching.JPG

--- @type AI_A2G
-- @extends AI.AI_Air#AI_AIR

--- The AI_A2G class implements the core functions to operate an AI @{Wrapper.Group} A2G tasking.
-- 
-- 
-- # 1) AI_A2G constructor
--   
--   * @{#AI_A2G.New}(): Creates a new AI_A2G object.
-- 
-- # 2) AI_A2G is a Finite State Machine.
-- 
-- This section must be read as follows. Each of the rows indicate a state transition, triggered through an event, and with an ending state of the event was executed.
-- The first column is the **From** state, the second column the **Event**, and the third column the **To** state.
-- 
-- So, each of the rows have the following structure.
-- 
--   * **From** => **Event** => **To**
-- 
-- Important to know is that an event can only be executed if the **current state** is the **From** state.
-- This, when an **Event** that is being triggered has a **From** state that is equal to the **Current** state of the state machine, the event will be executed,
-- and the resulting state will be the **To** state.
-- 
-- These are the different possible state transitions of this state machine implementation: 
-- 
--   * Idle => Start => Monitoring
--
-- ## 2.1) AI_A2G States.
-- 
--   * **Idle**: The process is idle.
-- 
-- ## 2.2) AI_A2G Events.
-- 
--   * **Start**: Start the transport process.
--   * **Stop**: Stop the transport process.
--   * **Monitor**: Monitor and take action.
--
-- @field #AI_A2G
AI_A2G = {
  ClassName = "AI_A2G",
}

--- Creates a new AI_A2G process.
-- @param #AI_A2G self
-- @param Wrapper.Group#GROUP AIGroup The group object to receive the A2G Process.
-- @return #AI_A2G
function AI_A2G:New( AIGroup )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_AIR:New( AIGroup ) ) -- #AI_A2G
  
  self:SetFuelThreshold( .2, 60 )
  self:SetDamageThreshold( 0.4 )
  self:SetDisengageRadius( 70000 )
  
  return self
end

