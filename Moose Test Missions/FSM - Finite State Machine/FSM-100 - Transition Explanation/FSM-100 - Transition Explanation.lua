--- Transition Explanation
-- 
-- ===
-- 
-- Name: Transition Explanation
-- Author: FlightControl
-- Date Created: 05 Jan 2017
--
-- # Situation:
-- 
-- Create a simple FSM.
-- Add 2 transitions that will switch state from "Green" to "Red" upon event "Switch".
-- 
-- # Test cases:
-- 
-- # Status: TESTED 05 Jan 2017

local FsmDemo = FSM:New() -- #FsmDemo
local FsmUnit = UNIT:FindByName( "FlareUnit" )

FsmDemo:SetStartState( "Green" )

do FsmDemo:AddTransition( "Green", "Switch", "Red" ) -- FSM Transition for type #FsmDemo.

	--- OnLeave State Transition for Green.
  -- @function [parent=#FsmDemo] OnLeaveGreen
  -- @param #FsmDemo self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnEnter State Transition for Red.
  -- @function [parent=#FsmDemo] OnEnterRed
  -- @param #FsmDemo self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- OnBefore State Transition for Switch.
  -- @function [parent=#FsmDemo] OnBeforeSwitch
  -- @param #FsmDemo self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnAfter State Transition for Switch.
  -- @function [parent=#FsmDemo] OnAfterSwitch
  -- @param #FsmDemo self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- Embedded Event Trigger for Switch.
  -- @function [parent=#FsmDemo] Switch
  -- @param #FsmDemo self

	--- Delayed Event Trigger for Switch
  -- @function [parent=#FsmDemo] __Switch
  -- @param #FsmDemo self
  -- @param #number Delay The delay in seconds.

end -- FsmDemo

do FsmDemo:AddTransition( "Red", "Switch", "Green" ) -- FSM Transition for type #FsmDemo.

	--- OnLeave State Transition for Red.
  -- @function [parent=#FsmDemo] OnLeaveRed
  -- @param #FsmDemo self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnEnter State Transition for Green.
  -- @function [parent=#FsmDemo] OnEnterGreen
  -- @param #FsmDemo self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- OnBefore State Transition for Switch.
  -- @function [parent=#FsmDemo] OnBeforeSwitch
  -- @param #FsmDemo self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.

	--- OnAfter State Transition for Switch.
  -- @function [parent=#FsmDemo] OnAfterSwitch
  -- @param #FsmDemo self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
	
	--- Embedded Event Trigger for Switch.
  -- @function [parent=#FsmDemo] Switch
  -- @param #FsmDemo self

	--- Delayed Event Trigger for Switch
  -- @function [parent=#FsmDemo] __Switch
  -- @param #FsmDemo self
  -- @param #number Delay The delay in seconds.

end -- FsmDemo

function FsmDemo:OnAfterSwitch( From, Event, To, FsmUnit )
  self:E( { From, Event, To, FsmUnit } )
  if From == "Green" then
    FsmUnit:Flare(FLARECOLOR.Green)
  else
    if From == "Red" then
      FsmUnit:Flare(FLARECOLOR.Red)
    end
  end
  FsmDemo:__Switch( 5, FsmUnit )
end

FsmDemo:__Switch( 5, FsmUnit )

