-- MOOSE include files.
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "DestroyGroupsTask" )
Include.File( "DestroyRadarsTask" )
Include.File( "DestroyUnitTypesTask" )
Include.File( "Group" )
Include.File( "Unit" )
Include.File( "Zone" )
Include.File( "Event" )

do
  local Mission = MISSION:New( 'Destroy Gound', 'Ground', 'Briefing', 'CCCP'  )

  Mission:AddClient( CLIENT:New( 'Client Plane', "Just wait and observe the SU-25T destoying targets. Your mission goal should increase..." ) )

  local DESTROYGROUPSTASK = DESTROYGROUPSTASK:New( 'Ground Vehicle', 'Ground Vehicles', { 'DESTROY Test 1' }, 100  ) -- 75% of a patriot battery needs to be destroyed to achieve mission success...
  DESTROYGROUPSTASK:SetGoalTotal( 1 )
  Mission:AddTask( DESTROYGROUPSTASK, 1 )
  
  MISSIONSCHEDULER.AddMission( Mission )
end


do
  local Mission = MISSION:New( 'Destroy Helicopters', 'Helicopters', 'Briefing', 'CCCP'  )

  Mission:AddClient( CLIENT:New( 'Client Plane', "Just wait and observe the SU-25T destoying the helicopters. The helicopter mission goal should increase once all are destroyed ..." ) )

  local DESTROYGROUPSTASK = DESTROYGROUPSTASK:New( 'Helicopter', 'Helicopters', { 'DESTROY Test 2' }, 50  )
  DESTROYGROUPSTASK:SetGoalTotal( 2 )
  Mission:AddTask( DESTROYGROUPSTASK, 1 )
  
  MISSIONSCHEDULER.AddMission( Mission )
end

-- MISSION SCHEDULER STARTUP
MISSIONSCHEDULER.Start()
MISSIONSCHEDULER.ReportMenu()
MISSIONSCHEDULER.ReportMissionsFlash( 30 )
MISSIONSCHEDULER.ReportMissionsHide()