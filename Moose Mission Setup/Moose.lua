env.info( '*** MOOSE DYNAMIC INCLUDE START *** ' )
env.info( 'Moose Generation Timestamp: 20170405_0123' )

local base = _G

__Moose = {}

__Moose.Include = function( IncludeFile )
	if not __Moose.Includes[ IncludeFile ] then
		__Moose.Includes[IncludeFile] = IncludeFile
		local f = assert( base.loadfile( __Moose.ProgramPath .. IncludeFile ) )
		if f == nil then
			error ("Moose: Could not load Moose file " .. IncludeFile )
		else
			env.info( "Moose: " .. IncludeFile .. " dynamically loaded from " .. __Moose.ProgramPath )
			return f()
		end
	end
end

__Moose.ProgramPath = "Scripts/Moose/"

__Moose.Includes = {}
__Moose.Include( 'Utilities/Routines.lua' )
__Moose.Include( 'Utilities/Utils.lua' )
__Moose.Include( 'Core/Base.lua' )
__Moose.Include( 'Core/Scheduler.lua' )
__Moose.Include( 'Core/ScheduleDispatcher.lua' )
__Moose.Include( 'Core/Event.lua' )
__Moose.Include( 'Core/Menu.lua' )
__Moose.Include( 'Core/Zone.lua' )
__Moose.Include( 'Core/Database.lua' )
__Moose.Include( 'Core/Set.lua' )
__Moose.Include( 'Core/Point.lua' )
__Moose.Include( 'Core/Message.lua' )
__Moose.Include( 'Core/Fsm.lua' )
__Moose.Include( 'Core/Radio.lua' )
__Moose.Include( 'Wrapper/Object.lua' )
__Moose.Include( 'Wrapper/Identifiable.lua' )
__Moose.Include( 'Wrapper/Positionable.lua' )
__Moose.Include( 'Wrapper/Controllable.lua' )
__Moose.Include( 'Wrapper/Group.lua' )
__Moose.Include( 'Wrapper/Unit.lua' )
__Moose.Include( 'Wrapper/Client.lua' )
__Moose.Include( 'Wrapper/Static.lua' )
__Moose.Include( 'Wrapper/Airbase.lua' )
__Moose.Include( 'Wrapper/Scenery.lua' )
__Moose.Include( 'Functional/Scoring.lua' )
__Moose.Include( 'Functional/CleanUp.lua' )
__Moose.Include( 'Functional/Spawn.lua' )
__Moose.Include( 'Functional/Movement.lua' )
__Moose.Include( 'Functional/Sead.lua' )
__Moose.Include( 'Functional/Escort.lua' )
__Moose.Include( 'Functional/MissileTrainer.lua' )
__Moose.Include( 'Functional/AirbasePolice.lua' )
__Moose.Include( 'Functional/Detection.lua' )
__Moose.Include( 'AI/AI_Balancer.lua' )
__Moose.Include( 'AI/AI_Patrol.lua' )
__Moose.Include( 'AI/AI_Cap.lua' )
__Moose.Include( 'AI/AI_Cas.lua' )
__Moose.Include( 'AI/AI_Cargo.lua' )
__Moose.Include( 'Actions/Act_Assign.lua' )
__Moose.Include( 'Actions/Act_Route.lua' )
__Moose.Include( 'Actions/Act_Account.lua' )
__Moose.Include( 'Actions/Act_Assist.lua' )
__Moose.Include( 'Tasking/CommandCenter.lua' )
__Moose.Include( 'Tasking/Mission.lua' )
__Moose.Include( 'Tasking/Task.lua' )
__Moose.Include( 'Tasking/DetectionManager.lua' )
__Moose.Include( 'Tasking/Task_A2G_Dispatcher.lua' )
__Moose.Include( 'Tasking/Task_A2G.lua' )
__Moose.Include( 'Moose.lua' )
BASE:TraceOnOff( true )
env.info( '*** MOOSE INCLUDE END *** ' )
