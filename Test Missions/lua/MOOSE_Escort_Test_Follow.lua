Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Escort" )


do
  local EscortClient = CLIENT:New( "Lead Helicopter", "Fly around and observe the behaviour of the escort helicopter" )  
  local EscortGroup = GROUP:NewFromName( "Escort Helicopter" )

  local Escort = ESCORT:New( EscortClient, EscortGroup, "Escort Test" )
end


-- MISSION SCHEDULER STARTUP
MISSIONSCHEDULER.Start()
MISSIONSCHEDULER.ReportMenu()
MISSIONSCHEDULER.ReportMissionsHide()

env.info( "Test Mission loaded" )
