ECHO OFF

REM Create Moose.lua File

ECHO Path to Moose *.lua files: %1
ECHO Current Date: %2
ECHO Path to Update Missions: %3
ECHO Dynamic or Static: %4

DEL Moose.lua

IF %4 == D GOTO Dynamic
IF %4 == S GOTO Static

GOTO End

:Dynamic

ECHO Dynamic Moose.lua

REM Create a timestamp with is logged in the DCS.log file.
ECHO env.info( '*** MOOSE DYNAMIC INCLUDE START *** ' ) > 					Moose.lua
ECHO env.info( 'Moose Generation Timestamp: %2' ) >> 						Moose.lua

COPY /b Moose.lua + "Moose Create Dynamic\Moose_Dynamic_Loader.lua"      	Moose.lua
COPY /b Moose.lua + "Moose Create Dynamic\Moose_Trace_On.lua"            	Moose.lua

GOTO End

:Static

ECHO Static Moose.lua

REM Create a timestamp with is logged in the DCS.log file.
ECHO env.info( '*** MOOSE STATIC INCLUDE START *** ' ) > 					Moose.lua
ECHO env.info( 'Moose Generation Timestamp: %2' ) >> 						Moose.lua

COPY /b Moose.lua + "Moose Create Static\Moose_Static_Loader.lua"        	Moose.lua


rem Core Routines
COPY /b Moose.lua + %1\Utilities\Routines.lua                                      	Moose.lua
COPY /b Moose.lua + %1\Utilities\Utils.lua                                         	Moose.lua

rem Core Classes
COPY /b Moose.lua + %1\Core\Base.lua                  	Moose.lua
COPY /b Moose.lua + %1\Core\Scheduler.lua             	Moose.lua
COPY /b Moose.lua + %1\Core\ScheduleDispatcher.lua    	Moose.lua
COPY /b Moose.lua + %1\Core\Event.lua                 	Moose.lua
COPY /b Moose.lua + %1\Core\Menu.lua                  	Moose.lua
COPY /b Moose.lua + %1\Core\Zone.lua                  	Moose.lua
COPY /b Moose.lua + %1\Core\Database.lua              	Moose.lua
COPY /b Moose.lua + %1\Core\Set.lua                   	Moose.lua
COPY /b Moose.lua + %1\Core\Point.lua                 	Moose.lua
COPY /b Moose.lua + %1\Core\Message.lua               	Moose.lua
COPY /b Moose.lua + %1\Core\Fsm.lua       	  		    Moose.lua
COPY /b Moose.lua + %1\Core\Radio.lua       	  		Moose.lua

rem Wrapper Classes
COPY /b Moose.lua + %1\Wrapper\Object.lua               Moose.lua
COPY /b Moose.lua + %1\Wrapper\Identifiable.lua         Moose.lua
COPY /b Moose.lua + %1\Wrapper\Positionable.lua         Moose.lua
COPY /b Moose.lua + %1\Wrapper\Controllable.lua         Moose.lua
COPY /b Moose.lua + %1\Wrapper\Group.lua                Moose.lua
COPY /b Moose.lua + %1\Wrapper\Unit.lua                 Moose.lua
COPY /b Moose.lua + %1\Wrapper\Client.lua               Moose.lua
COPY /b Moose.lua + %1\Wrapper\Static.lua               Moose.lua
COPY /b Moose.lua + %1\Wrapper\Airbase.lua              Moose.lua
COPY /b Moose.lua + %1\Wrapper\Scenery.lua              Moose.lua

rem Functional Classes
COPY /b Moose.lua + %1\Functional\Scoring.lua           Moose.lua
COPY /b Moose.lua + %1\Functional\CleanUp.lua           Moose.lua
COPY /b Moose.lua + %1\Functional\Spawn.lua             Moose.lua
COPY /b Moose.lua + %1\Functional\Movement.lua          Moose.lua
COPY /b Moose.lua + %1\Functional\Sead.lua              Moose.lua
COPY /b Moose.lua + %1\Functional\Escort.lua            Moose.lua
COPY /b Moose.lua + %1\Functional\MissileTrainer.lua    Moose.lua
COPY /b Moose.lua + %1\Functional\AirbasePolice.lua     Moose.lua
COPY /b Moose.lua + %1\Functional\Detection.lua         Moose.lua

rem AI Classes
COPY /b Moose.lua + %1\AI\AI_Balancer.lua  		       	Moose.lua
COPY /b Moose.lua + %1\AI\AI_Patrol.lua           		Moose.lua
COPY /b Moose.lua + %1\AI\AI_Cas.lua                 	Moose.lua
COPY /b Moose.lua + %1\AI\AI_Cap.lua                 	Moose.lua
COPY /b Moose.lua + %1\AI\AI_Cargo.lua                 	Moose.lua


rem Actions
COPY /b Moose.lua + %1\Actions\Act_Assign.lua    	  	Moose.lua
COPY /b Moose.lua + %1\Actions\Act_Route.lua   		  	Moose.lua
COPY /b Moose.lua + %1\Actions\Act_Account.lua    		Moose.lua
COPY /b Moose.lua + %1\Actions\Act_Assist.lua 		  	Moose.lua

rem Task Handling Classes
COPY /b Moose.lua + %1\Tasking\CommandCenter.lua 		Moose.lua
COPY /b Moose.lua + %1\Tasking\Mission.lua              Moose.lua
COPY /b Moose.lua + %1\Tasking\Task.lua    	         	Moose.lua
COPY /b Moose.lua + %1\Tasking\DetectionManager.lua     Moose.lua
COPY /b Moose.lua + %1\Tasking\Task_A2G_Dispatcher.lua 	Moose.lua
COPY /b Moose.lua + %1\Tasking\Task_A2G.lua         	Moose.lua

COPY /b Moose.lua + %1\Moose.lua                 		Moose.lua

COPY /b Moose.lua + "Moose Create Static\Moose_Trace_Off.lua"        		Moose.lua

GOTO End

:End

ECHO env.info( '*** MOOSE INCLUDE END *** ' ) >> 							Moose.lua
COPY Moose.lua %3
