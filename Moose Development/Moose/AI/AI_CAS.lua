--- SP:Y MP:Y AI:Y HU:N TYP:Air -- This module contains the AI_CAS class.
--
-- ===
--
-- 1) @{#AI_CAS} class, extends @{Core.Fsm#FSM_CONTROLLABLE}
-- ================================================================
-- The @{#AI_CAS} class implements the core functions to CAS a @{Zone} by an AIR @{Controllable} @{Group}.
--
-- 1.1) AI_CAS constructor:
-- ----------------------------
--
--   * @{#AI_CAS.New}(): Creates a new AI_CAS object.
--
-- 1.2) AI_CAS state machine:
-- ----------------------------------
-- The AI_CAS is a state machine: it manages the different events and states of the AIControllable it is controlling.
--
-- ### 1.2.1) AI_CAS Events:
--
--   * @{#AI_CAS.TakeOff}( AIControllable ):  The AI is taking-off from an airfield.
--   * @{#AI_CAS.Hold}( AIControllable ): The AI is holding in airspace at a zone.
--   * @{#AI_CAS.Engage}( AIControllable ): The AI is engaging the targets.
--   * @{#AI_CAS.WeaponReleased}( AIControllable ): The AI has released a weapon to the target.
--   * @{#AI_CAS.Destroy}( AIControllable ): The AI has destroyed a target.
--   * @{#AI_CAS.Complete}( AIControllable ): The AI has destroyed all defined targets.
--   * @{#AI_CAS.RTB}( AIControllable ): The AI is returning to the home base.
--
-- ### 1.2.2) AI_CAS States:
--
--
-- ### 1.2.3) AI_CAS state transition methods:
--
--
-- 1.3) Manage the AI_CAS parameters:
-- ------------------------------------------
-- The following methods are available to modify the parameters of an AI_CAS object:
--
--   * @{#AI_CAS.SetControllable}(): Set the AIControllable.
--   * @{#AI_CAS.GetControllable}(): Get the AIControllable.
--
-- ====
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
-- 2017-01-12: Initial class and API.
--
-- ===
--
-- AUTHORS and CONTRIBUTIONS
-- =========================
--
-- ### Contributions:
--
--   * **Quax**: Concept & Testing.
--   * **Pikey**: Concept & Testing.
--
-- ### Authors:
--
--   * **FlightControl**: Concept, Design & Programming.
--
--
-- @module Cas


--- AI_CAS class
-- @type AI_CAS
-- @field Wrapper.Controllable#CONTROLLABLE AIControllable The @{Controllable} patrolling.
-- @field Core.Zone#ZONE_BASE TargetZone The @{Zone} where the patrol needs to be executed.
-- @extends Core.Fsm#FSM_CONTROLLABLE
AI_CAS = {
  ClassName = "AI_CAS",
}



--- Creates a new AI_CAS object.
-- @param #AI_CAS self
-- @param Wrapper.Controllable#CONTROLLABLE Ct
-- @param Core.Zone#ZONE_BASE TargetZone The @{Zone} where the CAS needs to be executed.
-- @param Core.Set#SET_UNIT TargetSet The @{Set} of units to be destroyed.
-- @return #AI_CAS The new AI_CAS object.
function AI_CAS:New( Ct, TargetZone, TargetSet )

  -- Inherits from BASE
  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_CAS

  self:SetStartState( "None" )

  env.info( Ct )

  do self:AddTransition( "*", "TakeOff", "RTH" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS.

    --- OnLeave State Transition for *.
    -- @function [parent=#AI_CAS] OnLeave
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnEnter State Transition for RTH.
    -- @function [parent=#AI_CAS] OnEnterRTH
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- OnBefore State Transition for TakeOff.
    -- @function [parent=#AI_CAS] OnBeforeTakeOff
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnAfter State Transition for TakeOff.
    -- @function [parent=#AI_CAS] OnAfterTakeOff
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.


    --- Embedded Event Trigger for TakeOff.
    -- @function [parent=#AI_CAS] TakeOff
    -- @param #AI_CAS self

    --- Delayed Event Trigger for TakeOff
    -- @function [parent=#AI_CAS] __TakeOff
    -- @param #AI_CAS self
    -- @param #number Delay The delay in seconds.

  end -- AI_CAS

  do self:AddTransition( "RTH", "RouteToHold", "RTH" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS.

    --- OnLeave State Transition for RTH.
    -- @function [parent=#AI_CAS] OnLeaveRTH
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnEnter State Transition for RTH.
    -- @function [parent=#AI_CAS] OnEnterRTH
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- OnBefore State Transition for RouteToHold.
    -- @function [parent=#AI_CAS] OnBeforeRouteToHold
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.



    --- OnAfter State Transition for RouteToHold.
    -- @function [parent=#AI_CAS] OnAfterRouteToHold
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- Embedded Event Trigger for RouteToHold.
    -- @function [parent=#AI_CAS] RouteToHold
    -- @param #AI_CAS self

    --- Delayed Event Trigger for RouteToHold
    -- @function [parent=#AI_CAS] __RouteToHold
    -- @param #AI_CAS self
    -- @param #number Delay The delay in seconds.

  end -- AI_CAS

  do self:AddTransition( "RTH", "Hold", "Holding" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS.

    --- OnLeave State Transition for RTH.
    -- @function [parent=#AI_CAS] OnLeaveRTH
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnEnter State Transition for Holding.
    -- @function [parent=#AI_CAS] OnEnterHolding
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- OnBefore State Transition for Hold.
    -- @function [parent=#AI_CAS] OnBeforeHold
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnAfter State Transition for Hold.
    -- @function [parent=#AI_CAS] OnAfterHold
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- Embedded Event Trigger for Hold.
    -- @function [parent=#AI_CAS] Hold
    -- @param #AI_CAS self

    --- Delayed Event Trigger for Hold
    -- @function [parent=#AI_CAS] __Hold
    -- @param #AI_CAS self
    -- @param #number Delay The delay in seconds.

  end -- AI_CAS

  do self:AddTransition( "Holding", "Engage", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS.

    --- OnLeave State Transition for Holding.
    -- @function [parent=#AI_CAS] OnLeaveHolding
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnEnter State Transition for Engaging.
    -- @function [parent=#AI_CAS] OnEnterEngaging
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- OnBefore State Transition for Engage.
    -- @function [parent=#AI_CAS] OnBeforeEngage
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnAfter State Transition for Engage.
    -- @function [parent=#AI_CAS] OnAfterEngage
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- Embedded Event Trigger for Engage.
    -- @function [parent=#AI_CAS] Engage
    -- @param #AI_CAS self

    --- Delayed Event Trigger for Engage
    -- @function [parent=#AI_CAS] __Engage
    -- @param #AI_CAS self
    -- @param #number Delay The delay in seconds.

  end -- AI_CAS

  do self:AddTransition( "Engaging", "Fired", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS.

    --- OnLeave State Transition for Engaging.
    -- @function [parent=#AI_CAS] OnLeaveEngaging
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnEnter State Transition for Engaging.
    -- @function [parent=#AI_CAS] OnEnterEngaging
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- OnBefore State Transition for Fired.
    -- @function [parent=#AI_CAS] OnBeforeFired
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnAfter State Transition for Fired.
    -- @function [parent=#AI_CAS] OnAfterFired
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean

    --- Embedded Event Trigger for Fired.
    -- @function [parent=#AI_CAS] Fired
    -- @param #AI_CAS self

    --- Delayed Event Trigger for Fired
    -- @function [parent=#AI_CAS] __Fired
    -- @param #AI_CAS self
    -- @param #number Delay The delay in seconds.

  end -- AI_CAS

  do self:AddTransition( "Engaging", "Destroy", "Engaging" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS.

    --- OnLeave State Transition for Engaging.
    -- @function [parent=#AI_CAS] OnLeaveEngaging
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnEnter State Transition for Engaging.
    -- @function [parent=#AI_CAS] OnEnterEngaging
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- OnBefore State Transition for Destroy.
    -- @function [parent=#AI_CAS] OnBeforeDestroy
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnAfter State Transition for Destroy.
    -- @function [parent=#AI_CAS] OnAfterDestroy
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- Embedded Event Trigger for Destroy.
    -- @function [parent=#AI_CAS] Destroy
    -- @param #AI_CAS self

    --- Delayed Event Trigger for Destroy
    -- @function [parent=#AI_CAS] __Destroy
    -- @param #AI_CAS self
    -- @param #number Delay The delay in seconds.

  end -- AI_CAS

  do self:AddTransition( "Engaging", "Abort", "Holding" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS.

    --- OnLeave State Transition for Engaging.
    -- @function [parent=#AI_CAS] OnLeaveEngaging
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnEnter State Transition for Holding.
    -- @function [parent=#AI_CAS] OnEnterHolding
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- OnBefore State Transition for Abort.
    -- @function [parent=#AI_CAS] OnBeforeAbort
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnAfter State Transition for Abort.
    -- @function [parent=#AI_CAS] OnAfterAbort
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- Embedded Event Trigger for Abort.
    -- @function [parent=#AI_CAS] Abort
    -- @param #AI_CAS self

    --- Delayed Event Trigger for Abort
    -- @function [parent=#AI_CAS] __Abort
    -- @param #AI_CAS self
    -- @param #number Delay The delay in seconds.

  end -- AI_CAS


  do self:AddTransition( "Engaging", "Completed", "Holding" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS.

    --- OnLeave State Transition for Engaging.
    -- @function [parent=#AI_CAS] OnLeaveEngaging
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnEnter State Transition for Holding.
    -- @function [parent=#AI_CAS] OnEnterHolding
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- OnBefore State Transition for Completed.
    -- @function [parent=#AI_CAS] OnBeforeCompleted
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnAfter State Transition for Completed.
    -- @function [parent=#AI_CAS] OnAfterCompleted
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- Embedded Event Trigger for Completed.
    -- @function [parent=#AI_CAS] Completed
    -- @param #AI_CAS self

    --- Delayed Event Trigger for Completed
    -- @function [parent=#AI_CAS] __Completed
    -- @param #AI_CAS self
    -- @param #number Delay The delay in seconds.

  end -- AI_CAS


  do self:AddTransition( "Holding", "RTH", "RTB" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS.

    --- OnLeave State Transition for Holding.
    -- @function [parent=#AI_CAS] OnLeaveHolding
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnEnter State Transition for RTB.
    -- @function [parent=#AI_CAS] OnEnterRTB
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- OnBefore State Transition for RTH.
    -- @function [parent=#AI_CAS] OnBeforeRTH
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnAfter State Transition for RTH.
    -- @function [parent=#AI_CAS] OnAfterRTH
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- Embedded Event Trigger for RTH.
    -- @function [parent=#AI_CAS] RTH
    -- @param #AI_CAS self

    --- Delayed Event Trigger for RTH
    -- @function [parent=#AI_CAS] __RTH
    -- @param #AI_CAS self
    -- @param #number Delay The delay in seconds.

  end -- AI_CAS


  do self:AddTransition( "*", "Dead", "Dead" ) -- FSM_CONTROLLABLE Transition for type #AI_CAS.

    --- OnLeave State Transition for *.
    -- @function [parent=#AI_CAS] OnLeave
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnEnter State Transition for Dead.
    -- @function [parent=#AI_CAS] OnEnterDead
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- OnBefore State Transition for Dead.
    -- @function [parent=#AI_CAS] OnBeforeDead
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.

    --- OnAfter State Transition for Dead.
    -- @function [parent=#AI_CAS] OnAfterDead
    -- @param #AI_CAS self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    --- Embedded Event Trigger for Dead.
    -- @function [parent=#AI_CAS] Dead
    -- @param #AI_CAS self

    --- Delayed Event Trigger for Dead
    -- @function [parent=#AI_CAS] __Dead
    -- @param #AI_CAS self
    -- @param #number Delay The delay in seconds.

  end -- AI_CAS



  self.TargetZone = TargetZone
  self.TargetSet = TargetSet


  return self
end

