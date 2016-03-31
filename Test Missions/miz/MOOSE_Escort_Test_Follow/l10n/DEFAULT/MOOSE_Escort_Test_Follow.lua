Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Escort" )


do

  local function EventAliveHelicopter( Client )
    local EscortGroupHeli = GROUP:NewFromName( "Escort Helicopter" )
    local EscortHeli = ESCORT:New( Client, EscortGroupHeli, "Escort Test Helicopter" )
  end
  
  local function EventAlivePlane( Client )
    local EscortGroupPlane = GROUP:NewFromName( "Escort Plane" )
    local EscortPlane = ESCORT:New( EscortClientPlane, EscortGroupPlane, "Escort Test Plane" )
  end

  local EscortClientHeli = CLIENT:New( "Lead Helicopter", "Fly around and observe the behaviour of the escort helicopter" ):Alive( EventAliveHelicopter )  
  local EscortClientPlane = CLIENT:New( "Lead Plane", "Fly around and observe the behaviour of the escort airplane. Select Navigate->Joun-Up and airplane should follow you. Change speed and directions." )
                                  :Alive( EventAlivePlane )                                    

end

-- MISSION SCHEDULER STARTUP
MISSIONSCHEDULER.Start()
MISSIONSCHEDULER.ReportMenu()
MISSIONSCHEDULER.ReportMissionsHide()

env.info( "Test Mission loaded" )
