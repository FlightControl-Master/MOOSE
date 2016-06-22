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


COPY /b Moose.lua + %1\Routines.lua                                      	Moose.lua
COPY /b Moose.lua + %1\Base.lua                  							Moose.lua
COPY /b Moose.lua + %1\Scheduler.lua             							Moose.lua
COPY /b Moose.lua + %1\Event.lua                 							Moose.lua
COPY /b Moose.lua + %1\Menu.lua                  							Moose.lua
COPY /b Moose.lua + %1\Group.lua                 							Moose.lua
COPY /b Moose.lua + %1\Unit.lua                  							Moose.lua
COPY /b Moose.lua + %1\Zone.lua                  							Moose.lua
COPY /b Moose.lua + %1\Client.lua                							Moose.lua
COPY /b Moose.lua + %1\Static.lua                							Moose.lua
COPY /b Moose.lua + %1\Airbase.lua                							Moose.lua
COPY /b Moose.lua + %1\Database.lua              							Moose.lua
COPY /b Moose.lua + %1\Set.lua                   							Moose.lua
COPY /b Moose.lua + %1\Point.lua                 							Moose.lua
COPY /b Moose.lua + %1\Moose.lua                 							Moose.lua
COPY /b Moose.lua + %1\Scoring.lua               							Moose.lua
COPY /b Moose.lua + %1\Cargo.lua                 							Moose.lua
COPY /b Moose.lua + %1\Message.lua               							Moose.lua
COPY /b Moose.lua + %1\Stage.lua                 							Moose.lua
COPY /b Moose.lua + %1\Task.lua                  							Moose.lua
COPY /b Moose.lua + %1\GoHomeTask.lua            							Moose.lua
COPY /b Moose.lua + %1\DestroyBaseTask.lua       							Moose.lua
COPY /b Moose.lua + %1\DestroyGroupsTask.lua    							Moose.lua
COPY /b Moose.lua + %1\DestroyRadarsTask.lua     							Moose.lua
COPY /b Moose.lua + %1\DestroyUnitTypesTask.lua  							Moose.lua
COPY /b Moose.lua + %1\PickupTask.lua            							Moose.lua
COPY /b Moose.lua + %1\DeployTask.lua            							Moose.lua
COPY /b Moose.lua + %1\NoTask.lua                							Moose.lua
COPY /b Moose.lua + %1\RouteTask.lua             							Moose.lua
COPY /b Moose.lua + %1\Mission.lua               							Moose.lua
COPY /b Moose.lua + %1\CleanUp.lua               							Moose.lua
COPY /b Moose.lua + %1\Spawn.lua                 							Moose.lua
COPY /b Moose.lua + %1\Movement.lua              							Moose.lua
COPY /b Moose.lua + %1\Sead.lua                  							Moose.lua
COPY /b Moose.lua + %1\Escort.lua                							Moose.lua
COPY /b Moose.lua + %1\MissileTrainer.lua        							Moose.lua
COPY /b Moose.lua + %1\PatrolZone.lua            							Moose.lua
COPY /b Moose.lua + %1\AIBalancer.lua            							Moose.lua
COPY /b Moose.lua + %1\AirbasePolice.lua          							Moose.lua
COPY /b Moose.lua + %1\Detection.lua            							Moose.lua

COPY /b Moose.lua + "Moose Create Static\Moose_Trace_Off.lua"        		Moose.lua

GOTO End

:End

ECHO env.info( '*** MOOSE INCLUDE END *** ' ) >> 							Moose.lua
COPY Moose.lua %3
