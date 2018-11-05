--- **AI** -- Models the process of air to air operations for airplanes.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===
-- 
-- @module AI.AI_A2A
-- @image AI_Air_To_Air_Dispatching.JPG

--- @type AI_A2A
-- @extends Core.Fsm#FSM_CONTROLLABLE

--- The AI_A2A class implements the core functions to operate an AI @{Wrapper.Group} A2A tasking.
-- 
-- ## AI_A2A constructor
--   
--   * @{#AI_A2A.New}(): Creates a new AI_A2A object.
-- 
-- # 2) AI_A2A is a Finite State Machine.
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
-- ## 2.1) AI_A2A States.
-- 
--   * **None**: The process is not started yet.
--   * **Patrolling**: The AI is patrolling the Patrol Zone.
--   * **Returning**: The AI is returning to Base.
--   * **Stopped**: The process is stopped.
--   * **Crashed**: The AI has crashed or is dead.
-- 
-- ## 2.2) AI_A2A Events.
-- 
--   * **Start**: Start the process.
--   * **Stop**: Stop the process.
--   * **Route**: Route the AI to a new random 3D point within the Patrol Zone.
--   * **RTB**: Route the AI to the home base.
--   * **Detect**: The AI is detecting targets.
--   * **Detected**: The AI has detected new targets.
--   * **Status**: The AI is checking status (fuel and damage). When the tresholds have been reached, the AI will RTB.
--    
-- ## 3. Set or Get the AI controllable
-- 
--   * @{#AI_A2A.SetControllable}(): Set the AIControllable.
--   * @{#AI_A2A.GetControllable}(): Get the AIControllable.
--
-- @field #AI_A2A
AI_A2A = {
  ClassName = "AI_A2A",
}

--- Creates a new AI_A2A object
-- @param #AI_A2A self
-- @param Wrapper.Group#GROUP AIGroup The GROUP object to receive the A2A Process.
-- @return #AI_A2A
function AI_A2A:New( AIGroup )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_AIR:New( AIGroup ) ) -- #AI_A2A
  
  self:SetFuelThreshold( .2, 60 )
  self:SetDamageThreshold( 0.4 )
  self:SetDisengageRadius( 70000 )
  
  return self
end

