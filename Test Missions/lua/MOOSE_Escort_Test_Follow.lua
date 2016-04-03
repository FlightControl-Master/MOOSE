Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Spawn" )
Include.File( "Escort" )


do

  local function EventAliveHelicopter( Client )
    local SpawnEscortHeli = SPAWN:New( "Escort Helicopter" )
    local EscortGroupHeli1 = SpawnEscortHeli:Spawn()
    local EscortGroupHeli2 = SpawnEscortHeli:Spawn()
    local EscortGroupHeli3 = SpawnEscortHeli:Spawn()
    local EscortGroupHeli4 = SpawnEscortHeli:Spawn()
    local EscortHeli1 = ESCORT:New( Client, EscortGroupHeli1, "Escort Alpha" )
    local EscortHeli2 = ESCORT:New( Client, EscortGroupHeli2, "Escort Bravo" )
    local EscortHeli3 = ESCORT:New( Client, EscortGroupHeli3, "Escort Delta" )
    local EscortHeli4 = ESCORT:New( Client, EscortGroupHeli4, "Escort Gamma" )
  end
  
  local function EventAlivePlane( Client )
    local SpawnEscortPlane = SPAWN:New( "Escort Plane" )
    local EscortGroupPlane = SpawnEscortPlane:Spawn()
    local EscortPlane = ESCORT:New( Client, EscortGroupPlane, "Escort Test Plane" )
    
    local SpawnEscortGround = SPAWN:New( "Escort Ground" )
    local EscortGroupGround = SpawnEscortGround:Spawn()
    local EscortGround = ESCORT:New( Client, EscortGroupGround, "Test Ground" )

    local SpawnEscortShip = SPAWN:New( "Escort Ship" )
    local EscortGroupShip = SpawnEscortShip:Spawn()
    local EscortShip = ESCORT:New( Client, EscortGroupShip, "Test Ship" )
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
