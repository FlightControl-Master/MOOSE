# MOOSE Framework for Eagle Dynamics [DCS World](https://www.digitalcombatsimulator.com)

## Context
**MOOSE** is a **M**ission **O**bject **O**riented **S**cripting **E**nvironment, and is meant for mission designers and mission hosters.
It allows (will allow) to quickly setup complex missions using pre-scripted scenarios.
In order to run missions using this framework, you will need to install the framework within your Eagle Dynamics program files folder.

The goal of MOOSE is to allow mission designers to enhance their scripting with mission orchestration objects, which can be instantiated from defined classes within the framework.
This will allow to write mission scripts with minimal code embedded. Of course, the richness of the framework will determine the richness of the misson scenarios.
We can expect that MOOSE will evolve over time, as more missions will be designed within the framework.

## Currently supported functions
MOOSE contains currently the following mission design functions. The words in CAPITAL letters document the classes that can be used within MOOSE to accomplish these functions.

1. @{SPAWN}		Dynamic spawning and respawning of Groups with related functions.
2. @{MOVEMENT}	Keeps control over the amount of units driving around the battlefield simultaneously.
3. @{CLEANUP}	Clean-Up zones with air units that crashed. Can be used to prevent airports blocking air traffic and ground control operations due to crashed units near the airfield.
4. @{SEAD}		Enables the defenses for SAM sites. Mobile SAMs will evade fired anti-radiation missiles by shutting down their radars (for a while). If they are mobile, they will also drive away.
5. @{MISSION}	Create Taskforces or Missions within a DCS Mission. A mission will consist of @{TASK}s, and @{CLIENT}s.
6. @{TASK}		Add tasks for the mission. There are many different tasks that can be given, by using the classes derived from TASK.
   * @{DEPLOYTASK}			Deploy Cargo within a zone.
   * @{PICKUPTASK}			Pick-Up Cargo from a zone.
   * @{GOHOMETASK}			Fly back home.
   * @{DESTROYGROUPSTASK}		Destroy Groups.
   * @{DESTROYUNITTYPESTASK}	Destroy Units by measuring their UNIT Type.
   * @{DESTROYRADARSTASK}		Destroy Radars of SAM Groups.
   * @{SLINGLOADHOOKTASK}		Hook-Up Cargo within a zone and sling-load it outside of the zone.
   * @{SLINGLOADUNHOOKTASK}	Sling-load Cargo to a zone and Un-Hook the Cargo within the zone.
7. @{CLIENT}	Registers a client within MOOSE.
7. @{MESSAGE}	Send messages to @{CLIENT}s.
8. @{MENU}		Menu System.
				

## Installation
The installation of the MOOSE framework is straightforward.
   
1. Extract MOOSE.zip. You can do this quickly by right clicking the MOOSE.zip file, and select "Extract All".

2. The extraction will add a directory within the Scripts directory of the Eagle Dynamics DCS world installation.
   Example, the Scripts directory of my DCS World installation folder is C:\Program Files\Eagle Dynamics\DCS World\Scripts

3. Browse within the new MOOSE directory to the DCS_Script directory and run Install.bat as an administrator. 
   This will make a backup of the missionScripting.lua file and replace this with a new one.

And you're done.

## What has changed?

Not much. The missionscripting.lua file has been enhanced with the following code:

----
	Include = {}

	Include.LoadPath = 'Scripts/MOOSE'
	Include.Files = {}

	Include.File = function( IncludeFile )
		if not Include.Files[ IncludeFile ] then
			Include.Files[IncludeFile] = IncludeFile
			dofile( Include.LoadPath .. "/" .. IncludeFile .. ".lua" )
			env.info( "Include:" .. IncludeFile .. " loaded." )
		end
	end

	Include.File( "Database" )
	Include.File( "StatHandler" )
----

This code allows for the inclusion of the MOOSE framework, and this now becomes part of your DCS World Simulation Engine.
Missions designed with the MOOSE framework will now run.

