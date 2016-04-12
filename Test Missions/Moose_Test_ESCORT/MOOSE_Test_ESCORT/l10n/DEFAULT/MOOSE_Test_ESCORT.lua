Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Spawn" )
Include.File( "Escort" )


do

  local function EventAliveHelicopter( Client )
    local EscortGroupHeli1 = SpawnEscortHeli:ReSpawn(1)
    local EscortHeli1 = ESCORT:New( Client, EscortGroupHeli1, "Escort Alpha" )
    local EscortGroupPlane = SpawnEscortPlane:ReSpawn(1)
    local EscortPlane = ESCORT:New( Client, EscortGroupPlane, "Escort Test Plane" )
    local EscortGroupGround = SpawnEscortGround:ReSpawn(1)
    local EscortGround = ESCORT:New( Client, EscortGroupGround, "Test Ground" )
  end
  
  local function EventAlivePlane( Client )
    local EscortGroupPlane = SpawnEscortPlane:ReSpawn(1)
    local EscortPlane = ESCORT:New( Client, EscortGroupPlane, "Escort Test Plane" )
    
    local EscortGroupGround = SpawnEscortGround:ReSpawn(1)
    local EscortGround = ESCORT:New( Client, EscortGroupGround, "Test Ground" )

    local EscortGroupShip = SpawnEscortShip:ReSpawn(1)
    local EscortShip = ESCORT:New( Client, EscortGroupShip, "Test Ship" )
  end

  SpawnEscortHeli = SPAWN:New( "Escort Helicopter" )
  SpawnEscortPlane = SPAWN:New( "Escort Plane" )
  SpawnEscortGround = SPAWN:New( "Escort Ground" )
  SpawnEscortShip = SPAWN:New( "Escort Ship" )

  EscortClientHeli = CLIENT:New( "Lead Helicopter", "Fly around and observe the behaviour of the escort helicopter" ):Alive( EventAliveHelicopter )  
  EscortClientPlane = CLIENT:New( "Lead Plane", "Fly around and observe the behaviour of the escort airplane. Select Navigate->Joun-Up and airplane should follow you. Change speed and directions." )
                                  :Alive( EventAlivePlane )                                    

end

-- MISSION SCHEDULER STARTUP
MISSIONSCHEDULER.Start()
MISSIONSCHEDULER.ReportMenu()
MISSIONSCHEDULER.ReportMissionsHide()

env.info( "Test Mission loaded" )
