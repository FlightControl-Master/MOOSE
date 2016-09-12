--- This test demonstrates the use(s) of the SwitchWayPoint method of the GROUP class.

HeliGroup = GROUP:FindByName( "Helicopter" )

--- Route the helicopter back to the FARP after 60 seconds.
-- We use the SCHEDULER class to do this.
SCHEDULER:New( nil,
  function( HeliGroup )
    local CommandRTB = HeliGroup:CommandSwitchWayPoint( 2, 8 )
    HeliGroup:SetCommand( CommandRTB )
  end, { HeliGroup }, 90 
)
