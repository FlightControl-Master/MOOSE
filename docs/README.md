# Context

TEST

MOOSE is a **M**ission **O**bject **O**riented **S**cripting **E**nvironment, and is meant for mission designers and mission hosters.
It allows to quickly setup complex missions using pre-scripted scenarios using the available classes within the MOOSE Framework.
MOOSE is currently still in alpha version, but will evolve over time. Right now, it has been updated to work with DCS world 1.5. and 2.0.

You can find the source of MOOSE here on GITHUB. It is free for download: 
https://github.com/FlightControl-Master/MOOSE/

Note: MOOSE is complementary to [MIST](https://github.com/mrSkortch/MissionScriptingTools/releases), so if you use MIST in parallel with MOOSE objects, this should work.

# Goals

The goal of MOOSE is to allow mission designers to enhance their scripting with mission orchestration objects, which can be instantiated from defined classes within the framework. This will allow to write mission scripts with minimal code embedded. Of course, the richness of the framework will determine the richness of the misson scenarios. We can expect that MOOSE will evolve over time, as more missions will be designed within the framework.

# MOOSE Directory Structure

* Moose Development: Contains the collection of lua files that define the MOOSE classes. You can use this directory to build the dynamic luadoc documentation intellisense in your eclipse development environment.
* Moose Mission Setup: Contains the Moose.lua file to be included in your scripts when using MOOSE classes (see below the point Mission Design with Moose).
* Moose Test Missions: Contains a directory structure with Moose Test Missions and examples. In each directory, you will find a miz file and a lua file containing the main mission script.
* Moose Training: Contains the documentation of Moose generated with luadoc from the Moose source code. The presentations used during the videos in my [youtube channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg), are also to be found here.

# Mission Design with Moose

In order to create a mission using MOOSE, you'll have to include a file named **Moose.lua**:

1. Create a new mission in the DCS World Mission Editor.
2. In the mission editor, create a new trigger.
3. Name the trigger Moose Load and let it execute only at MISSION START.
4. Add an action DO SCRIPT FILE (without a condition, so the middle column must be empty).
5. In the action, browse to the **[Moose.lua](https://github.com/FlightControl-Master/MOOSE/tree/master/Moose%20Mission%20Setup)** file in the **Moose Mission Setup** directory, and include this file within your mission.
6. Make sure that the "Moose Load" trigger is completely at the top of your mission.

Voila, MOOSE is now included in your mission. During the execution of this mission, all MOOSE classes will be loaded, and all MOOSE initializations will be exectuted before any other mission action is executed.

IMPORTANT NOTE: When a new version of MOOSE is released, you'll have to UPDATE the Moose.lua file in EACH OF YOUR MISSION.
This can be a tedious task, and for this purpose, a tool has been developed that will update the Moose.lua files automatically within your missions.
Refer to the tool at [Moose Mission Setup\Moose Mission Update](https://github.com/FlightControl-Master/MOOSE/tree/master/Moose%20Mission%20Setup/Moose%20Mission%20Update) directory for further information included in the [READ.ME]() file.


# MOOSE LUA Classes

The following classes are currently embedded within MOOSE and can be included within your mission scripts:

* [BASE](Moose Training/Documentation/Base.html): The main class from which all MOOSE classes are derived from. The BASE class contains essential functions to support inheritance and MOOSE object execution tracing (logging within the DCS.log file in the saved games folder of the user).

* [DATABASE](Moose Training/Documentation/Database.html): Creates a collection of GROUPS[], UNITS[], CLIENTS[] and managed these sets automatically. Provides an API set to retrieve a GROUP, UNIT or CLIENT instance from the _DATABASE object using defined APIs. The collections are maintained dynamically during the execution of the mission, so when players join, leave, when units are created or destroyed, the collections are dynamically updated.

* [GROUP](Moose Training/Documentation/Group.html): This class wraps a DCS Group object within the simulator. It provides a more extensive API set, as well takes an abstraction of the complexity to give tasks, commands and set various options to DCS Groups. Additionally, the GROUP class provides a much richer API to identify various properties of the DCS Group. For each DCS Group created object within a running mission, a GROUP object will be created automatically, that is managed within the DATABASE, under the _DATABASE object.

* [UNIT](Moose Training/Documentation/Unit.html): This class wraps a DCS Unit object within the simulator. It provides a more extensive API set, as well takes an abstraction of the complexity to give commands and set various options to DCS Units. Additionally, the UNIT class provides a much richer API to identify various properties of the DCS Unit. For each DCS Unit object created within a running mission, a UNIT object will be created automatically, that is stored within the DATABASE, under the _DATABASE object.

* [CLIENT](Moose Training/Documentation/Client.html): This class wraps a DCS Unit object within the simulator, which has a skill Client or Player. The CLIENT class derives from the UNIT class, thus contains the complete UNIT API set, and additionally, the CLIENT class provides an API set to manage players joining or leaving clients, sending messages to players, and manage the state of units joined by players. For each DCS Unit object created within a running mission that can be joined by a player, a CLIENT object will be created automatically, that is stored within the DATABASE, under the _DATABASE object.

* [STATIC](Moose Training/Documentation/Static.html): This class wraps a DCS StaticObject object within the simulator. The STATIC class derives from the POSITIONABLE class, thus contains also the position API set.

* [AIRBASE](Moose Training/Documentation/Airbase.html): This class wraps a DCS Airbase object within the simulator. The AIRBASE class derives from the POSITIONALBE class, thus contains also the position API set.

* [MENU](Moose Training/Documentation/Menu.html): Manage DCS Menus for Coalitions, Groups, Clients.

* [SETS](Moose Training/Documentation/Set.html): Builds dynamically a SET of objects. The SET can be filtered with defined filter criteria. Iterators are available that iterate through the GROUPSET, calling a function for each object within the SET.

* [MESSAGE](Moose Training/Documentation/Message.html): A message system, displaying messages to Clients, Coalitions or All players. 

* [POINTS](Moose Training/Documentation/Point.html): A set of point classes that provide the functionality to define points within the simulator, either 2D or 3D. These points have enriched functionality, like smoking, flaring and other functions.

* [ZONES](Moose Training/Documentation/Zone.html): A set of zone classes that provide the functionality to validate the presence of GROUPS, UNITS, CLIENTS, STATICS within a certain ZONE. The zones can take various forms and can be movable.

* [SCHEDULER](Moose Training/Documentation/Scheduler.html): This class implements a timer scheduler that will call at optional specified intervals repeatedly or just one time a scheduled function.

* [SPAWN](Moose Training/Documentation/Spawn.html): Spawn new groups (and units) during mission execution.

* [ESCORT](Moose Training/Documentation/Escort.html): Makes groups consisting of helicopters, airplanes, ground troops or ships within a mission joining your flight. You can control these groups through the ratio menu during your flight. Available commands are around: Navigation, Position Hold, Reporting (Target Detection), Attacking, Assisted Attacks, ROE, Evasion, Mission Execution and more ...

* [MISSILETRAINER](Moose Training/Documentation/MissileTrainer.html): Missile trainer, it destroys missiles when they are within a certain range of player airplanes, displays tracking and alert messages of missile launches; approach; destruction, and configure with radio menu commands. Various APIs available to configure the trainer.

* [PATROLZONE](Moose Training/Documentation/PatrolZone.html): Make an alive AI Group patrol a zone derived from the ZONE_BASE class. Manage out-of-fuel events and set altitude and speed ranges for the patrol.

* [AIBALANCER](Moose Training/Documentation/AIBalancer.html): Compensate in a multi player mission the abscence of players with dynamically spawned AI air units. When players join CLIENTS, the AI will either be destroyed, or will fly back to the home or nearest friendly airbase.

* [DETECTION](Moose Training/Documentation/Detection.html): Detect other units using the available sensors of the detection unit. The DETECTION_BASE derived classes will provide different methods how the sets of detected objects are built.

* [FAC](Moose Training/Documentation/Fac.html): Using the DETECTION_BASE derived classes, detected objects can be reported in different ways to a set of clients (SET_CLIENT). FAC_BASE derived classes will provide target detection reporting and control using the radio menu. 

* [FOLLOW](Moose Training/Documentation/Follow.html): Build large air formations using the FOLLOW class.

# MOOSE Tutorials and Examples

You can download [test missions](https://github.com/FlightControl-Master/MOOSE/tree/master/Test%20Missions) to have examples and learn the syntax and usage of the MOOSE classes.

There are [Video Tutorials](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg) on my YOUTUBE channel on which you can learn some coding aspects with mission execution demos, as well as some of the tooling and internal mechanisms within MOOSE.


In the triggers section, there is a flag (9999) that will decide how MOOSE will be loaded. When flag 9999 is set, MOOSE will be dynamically loaded. When flag 9999 is off, MOOSE will be loaded embedded. Note that when loaded embedded, **your mission must include the last Moose_Embedded.lua file**. So, ensure that the last file is included in the DO SCRIPT section when MOOSE got an update! 

# Credits

Note that the framework is based on code i've written myself, but some of it is also based on code that i've seen as great scripting code and ideas, and which i've revised. I see this framework evolving towards a broader public, and the ownership may dissapear (or parts of it). Consider this code public domain. Therefore a list of credits to all who have or are contributing (this list will increase over time): Grimes, Prof_Hilactic, xcom, the 476 virtual squadron team, ...

You'll notice that within this framework, there are functions used from mist. I've taken the liberty to copy those atomic mist functions that are very nice and useful, and used those. 

**Grimes**
Without the effort of Grimes with MIST and his continuous documentation, the development of MOOSE would not have been possible. MOOSE is not replacing MIST, but is compensating it.

**Prof_hilactic**
SEAD Defenses. I've taken the script, and reworded it to fit within MOOSE. The script within MOOSE is hardly recognizable anymore from the original. Find here the posts: http://forums.eagle.ru/showpost.php?...59&postcount=1

**xcom**
His contribution is related to the Event logging system. I've analyzed and studied his scripts, and reworked it a bit to use it also within the framework (I've also tweaked it a bit). Find his post here: http://forums.eagle.ru/showpost.php?...73&postcount=1

**Dutch_Baron (James)**
Working together with James has resulted in the creation of the AIBALANCER class. James has shared his ideas on balancing AI with air units, and together we made a first design which you can use now :-)

**Stuka (Danny)**
Working together with Danny has resulted in the MISSILETRAINER class. Stuka has shared his ideas and together we made a design. Together with the 476 virtual team, we tested this CLASS, and got much positive feedback!

**Mechanic (G�bor)**
Worked together with G�bor to create the concept of the DETECTION and FAC classes. Mechanic shared his ideas and concepts to group detected targets into sets within detection zones... Will continue to work with G�bor to workout the DETECTION and FAC classes.

**Shadoh**
Interacted on the eagle dynamics forum to build the FOLLOW class to build large WWII airplane formations.

For the rest I also would like to thank the numerous feedback and help and assistance of the moose community at SLACK.COM.
Note that there is a vast amount of other scripts out there. 
I may contact you personally to ask for your contribution / permission if i can use your idea or script to tweak it to the framework. 
Parts of these scripts will have to be redesigned to fit it into an OO framework.

The rest of the framework functions and class definitions were my own developments, especially the core of MOOSE.
Trust I've spent hours and hours investigating, trying and writing and documenting code building this framework.
Hope you think the idea is great and useful.