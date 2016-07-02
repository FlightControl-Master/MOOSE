
local Mission = MISSION:New( 'SEAD Targets', "Strategic", "SEAD the enemy", "RUSSIA" )
local Scoring = SCORING:New( "SEAD" )

Mission:AddScoring( Scoring )

local Client = CLIENT:FindByName( "Test SEAD" )
local TargetSet = SET_UNIT:New():FilterPrefixes( "US Hawk SR" ):FilterStart()

local Task_Menu = TASK2_CLIENT_MENU:New( Client, Mission, "SEAD" )
--local Task_Route = TASK2_ROUTE:New( Client, Mission ) -- Zone is dynamically defined in state machine
local Task_Client_Sead = TASK2_SEAD:New( Client, Mission, TargetSet )

Task_Client_Sead:AddScore( "Destroy", "Destroyed RADAR", 25 )
Task_Client_Sead:AddScore( "Success", "Destroyed all radars!!!", 100 )

local Task_Sead = STATEMACHINE:New( {
    initial = 'None',
    events = {
      { name = 'Start',  from = 'None',  to = 'Unassigned' },
      { name = 'Assign',  from = 'Unassigned',  to = 'Assigned' },
--      { name = 'Route', from = 'Assigned', to = 'Arrived'    },
      { name = 'Sead',  from = 'Assigned',    to = 'Seading' },
      { name = 'Destroyed', from = 'Destroy', to = 'Success' },      
    },
    subs = {
      Menu = { onstateparent = 'Unassigned', oneventparent = 'Start', fsm = Task_Menu.Fsm, event = 'Menu' },
      --Assigned = { onstateparent = 'Assigned', oneventparent = 'Assign', fsm = Task_Route.Fsm, event = 'Route' },
      Sead = { onstateparent = 'Assigned', oneventparent = 'Assign', fsm = Task_Client_Sead.Fsm, event = 'Await' }
    }
  } )

Task_Sead:Start()
