# Context


MOOSE is a **M**ission **O**bject **O**riented **S**cripting **E**nvironment, and is meant for mission designers and mission hosters.
It allows to quickly setup complex missions using pre-scripted scenarios using the available classes within the MOOSE Framework.
MOOSE is designed to work with DCS world 1.5. and 2.0.

![Banner](Presentations\MOOSE\Dia1.JPG)

# Goals

The goal of MOOSE is to allow mission designers to enhance their scripting with mission orchestration objects, which can be instantiated from defined classes within the framework. This will allow to write mission scripts with minimal code embedded. Of course, the richness of the framework will determine the richness of the misson scenarios. We can expect that MOOSE will evolve over time, as more missions will be designed within the framework.

## GitHub Repository

You can find the source of [MOOSE on GITHUB](https://github.com/FlightControl-Master/MOOSE/). It is free for download. 

# Installation of tools and sync the MOOSE repository.

1. Install [Eclipse LDT](https://eclipse.org/ldt) on your Windows 64 bit system. This is a free lua editor based on the Eclipse ecosystem. The advantage of LDT is that it greatly enhances your lua development environment with intellisense, better search capabilities etc. You may have to install [java](https://www.java.com/en/download) first. Ensure you install the **64-bit versions** of both Eclipse LDT and java!
2. Install [GITHUB](https://desktop.github.com) desktop. We use GITHUB desktop to sync the moose repository to your system.
3. Link the MOOSE repository on GITHUB to your freshly installed GITHUB desktop. Do this by browing to the MOOSE repository at GITHUB, and select the green button **Clone or Download** -> **Open in Desktop**.
4. Specify a local directory on your PC where you want to store the MOOSE repository contents.
5. Sync the MOOSE repository to a defined local MOOSE directory on your PC using GITHUB desktop (press the sync button).
6. On your local MOOOSE directory, execute the batch file [DCS_Folder_Sync.bat](https://github.com/FlightControl-Master/MOOSE/blob/master/DCS_Folder_Sync.bat). This will sync the dcs folder in the MOOSE repository from the submodule DCS API.

As a result, you have installed the MOOSE repository on your PC, and it is fully synced.

# Setup Eclipse LDT to work with MOOSE and activate your intellisense etc.

1. Open Eclipse LDT.
2. Select the workspace to be stored at your user id.
3. Select from the Menu: File -> New -> Lua Project.

![LDT_New_Project](Setup/LDT_New_Project.JPG)

4. A dialog box is shown.

![LDT_Project](Setup/LDT_Project.JPG)

5. Type the Project Name: Moose_Framework
6. In the sub-box Project Contents, select the option Create Project at existing location (from existing source). Browse to the local MOOSE directory and select the root directory of MOOSE.
7. Select the Next button.
8. You should see now a dialog box with the following properties. Note that the Moose_Framework/Moose Development/Moose directory is flagged as the **Source Directory*. This is important because it will search in the files in this directory and sub directories for lua documentator enabled lua files. It will make the intellisense work!

![LDT Finish](Setup/LDT_Moose_Framework_Finish.JPG)

9. Press the Finish button.

As a result, when you browse to the Script Explorer, you'll see the following:

![LDT_Script_Explorer](Setup/LDT_Script_Explorer.JPG)

## YouTube Broadcast Channel

MOOSE has a [broadcast channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg/playlists) on youtube. 
These videos are grouped into playlists, which explain specific MOOSE capabilities, 
and gradually build up the "understanding" and "what is possible" to do with the MOOSE framework.
I really, really encourage all to watch the explanation videos.

Some mandatory videos to watch are:

  * [MOOSE Introduction](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl1JEtVcyf9sazUV5_fGICz4)

  * [MOOSE Setup](https://www.youtube.com/watch?v=-Hxae3mTCE8&t=159s&index=1&list=PL7ZUrU4zZUl0riB9ULVh-bZvFlw1_Wym2)
  * [MOOSE Spawning](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl1jirWIo4t4YxqN-HxjqRkL)
  * [MOOSE Tasking](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl3CgxN2iAViiGLTPpQ-Ajdg)
  * [MOOSE Task Dispatching](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl3I6ieFM-cjey-rncF1ktNI)

## MOOSE community

There is a MOOSE community at various places out there. The main community can be found at slack.com.
Various channels and people are helping each other out using the framework.
If you would like to join, please contact me on skype: FlightControl_Skype.


## Test Missions

The framework comes with [Test Missions](https://github.com/FlightControl-Master/MOOSE/tree/master/Moose%20Test%20Missions), that you can try out and helps you to code. 
You can copy/paste code the code snippets into your missions, as it accellerates your mission developments.

These exact test missions are demonstrated at the demo videos in the YouTube channel.

Note: MOOSE is complementary to [MIST](https://github.com/mrSkortch/MissionScriptingTools/releases), so if you use MIST in parallel with MOOSE objects, this should work.

# MOOSE Directory Structure

As you can see at the GitHub site, the MOOSE framework is devided into a couple of directories:

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

# MOOSE Classes

The following classes are currently embedded within MOOSE and can be included within your mission scripts:

![Classes](Presentations\MOOSE\Dia2.JPG)

## MOOSE Core Classes

These classes define the base building blocks of the MOOSE framework. These classes are heavily used within the MOOSE framework.

* [BASE](Documentation/Base.html): The main class from which all MOOSE classes are derived from. The BASE class contains essential functions to support inheritance and MOOSE object execution tracing (logging within the DCS.log file in the saved games folder of the user).

* [DATABASE](Documentation/Database.html): Creates a collection of GROUPS[], UNITS[], CLIENTS[] and managed these sets automatically. Provides an API set to retrieve a GROUP, UNIT or CLIENT instance from the _DATABASE object using defined APIs. The collections are maintained dynamically during the execution of the mission, so when players join, leave, when units are created or destroyed, the collections are dynamically updated.

* [EVENT](Documentation/Event.html): Provides the Event Dispatcher base class to handle DCS Events, being fired upon registered events within the DCS simulator. Note that EVENT is used by BASE, exposing OnEvent() methods to catch these DCS events.

* [FSM](Documentation/Fsm.html):  The main FSM class can be used to build a Finite State Machine. The derived FSM_ classes provide Finite State Machine building capability for CONTROLLABLEs, ACT_ (Task Actions) classes, TASKs and SETs.

* [MENU](Documentation/Menu.html): Set Menu options (F10) for All Players, Coalitions, Groups, Clients. MENU also manages the recursive removal of menus, which is a big asset!

* [SETS](Documentation/Set.html): Create SETs of MOOSE objects.  SETs can be created for GROUPs, UNITs, AIRBASEs, ...  
The SET can be filtered with defined filter criteria.  
Iterators are available that iterate through the GROUPSET, calling a function for each object within the SET.

* [MESSAGE](Documentation/Message.html): A message publishing system, displaying messages to Clients, Coalitions or All players. 

* [POINTS](Documentation/Point.html): A set of point classes to manage the 2D or 3D simulation space, through an extensive method library.  
The POINT_VEC3 class manages the 3D simulation space, while the POINT_VEC2 class manages the 2D simulation space.

* [ZONES](Documentation/Zone.html): A set of zone classes that provide the functionality to validate the presence of GROUPS, UNITS, CLIENTS, STATICS within a certain ZONE. The zones can take various forms and can be movable.

* [SCHEDULER](Documentation/Scheduler.html): This class implements a timer scheduler that will call at optional specified intervals repeatedly or just one time a scheduled function.


## MOOSE Wrapper Classes

MOOSE Wrapper Classes provide an object oriented hierarchical mechanism to manage the DCS objects within the simulator.
Wrapper classes provide another easier mechanism to control Groups, Units, Statics, Airbases and other objects.

* **[OBJECT](Documentation/Object.html)**: This class provides the base for MOOSE objects.

* **[IDENTIFIABLE](Documentation/Identifiable.html)**: This class provides the base for MOOSE identifiable objects, which is every object within the simulator :-).

* **[POSITIONABLE](Documentation/Positionable.html)**: This class provides the base for MOOSE positionable objects. These are AIRBASEs, STATICs, GROUPs, UNITs ...

* **[CONTROLLABLE](Documentation/Controllable.html)**: This class provides the base for MOOSE controllable objects. These are GROUPs, UNITs, CLIENTs.

* **[AIRBASE](Documentation/Airbase.html)**: This class wraps a DCS Airbase object within the simulator.

* **[GROUP](Documentation/Group.html)**: This class wraps a DCS Group objects within the simulator, which are currently alive.  
It provides a more extensive API set.  
It takes an abstraction of the complexity to give tasks, commands and set various options to DCS Groups.  
Additionally, the GROUP class provides a much richer API to identify various properties of the DCS Group.  
For each DCS Group created object within a running mission, a GROUP object will be created automatically, beging managed within the DATABASE.

* **[UNIT](Documentation/Unit.html)**: This class wraps a DCS Unit object within the simulator, which are currently alive. It provides a more extensive API set, as well takes an abstraction of the complexity to give commands and set various options to DCS Units. Additionally, the UNIT class provides a much richer API to identify various properties of the DCS Unit. For each DCS Unit object created within a running mission, a UNIT object will be created automatically, that is stored within the DATABASE, under the _DATABASE object.
the UNIT class provides a more extensive API set, taking an abstraction of the complexity to give tasks, commands and set various options to DCS Units.  
For each DCS Unit created object within a running mission, a UNIT object will be created automatically, beging managed within the DATABASE.

* **[CLIENT](Documentation/Client.html)**: This class wraps a DCS Unit object within the simulator, which has a skill Client or Player.  
The CLIENT class derives from the UNIT class, thus contains the complete UNIT API set, and additionally, the CLIENT class provides an API set to manage players joining or leaving clients, sending messages to players, and manage the state of units joined by players. For each DCS Unit object created within a running mission that can be joined by a player, a CLIENT object will be created automatically, that is stored within the DATABASE, under the _DATABASE object.

* **[STATIC](Documentation/Static.html)**: This class wraps a DCS StaticObject object within the simulator. 
The STATIC class derives from the POSITIONABLE class, thus contains also the position API set.


## MOOSE Functional Classes

MOOSE Functional Classes provide various functions that are useful in mission design.

* [SPAWN](Documentation/Spawn.html): Spawn new groups (and units) during mission execution.

* [ESCORT](Moose Training/Documentation/Escort.html): Makes groups consisting of helicopters, airplanes, ground troops or ships within a mission joining your flight. You can control these groups through the ratio menu during your flight. Available commands are around: Navigation, Position Hold, Reporting (Target Detection), Attacking, Assisted Attacks, ROE, Evasion, Mission Execution and more ...

* [MISSILETRAINER](Moose Training/Documentation/MissileTrainer.html): Missile trainer, it destroys missiles when they are within a certain range of player airplanes, displays tracking and alert messages of missile launches; approach; destruction, and configure with radio menu commands. Various APIs available to configure the trainer.

* [DETECTION](Moose Training/Documentation/Detection.html): Detect other units using the available sensors of the detection unit. The DETECTION_BASE derived classes will provide different methods how the sets of detected objects are built.

## MOOSE AI Controlling Classes

MOOSE AI Controlling Classes provide mechanisms to control AI over long lasting processes.  
These AI Controlling Classes are based on FSM (Finite State Machine) Classes, and provided an encapsulated way to make AI behave or execute an activity.

* [AI_BALANCER](Documentation/AI_Balancer.html): Compensate in a multi player mission the abscence of players with dynamically spawned AI air units. When players join CLIENTS, the AI will either be destroyed, or will fly back to the home or nearest friendly airbase.

* [AI_PATROLZONE](Documentation/AI_PatrolZone.html): Make an alive AI Group patrol a zone derived from the ZONE_BASE class. Manage out-of-fuel events and set altitude and speed ranges for the patrol.

* [AI_CARGO](Documentation/AI_Cargo.html): Make AI behave as cargo. Various CARGO types exist.

## MOOSE Tasking Classes

MOOSE Tasking Classes provide a comprehensive Mission Orchestration System.
Through COMMANDCENTERs, multiple logical MISSIONs can be orchestrated for coalitions.
Within each MISSION, various TASKs can be defined.
Each TASK has a TASK ACTION flow, which is the flow that a player (hosted by a UNIT) within the simulator needs to follow and accomplish.

* [COMMANDCENTER](Documentation/CommandCenter.html): Orchestrates various logical MISSIONs for a coalition.

* [MISSION](Documentation/Mission.html): Each MISSION has various TASKs to be executed and accomplished by players.

* [TASK](Documentation/Task.html): Each TASK has a status, and has a TASK ACTION flow for each Player acting and executing the TASK.

* [TASK_SEAD](Documentation/Task_SEAD.html): Models a SEAD Task, where a Player is routed towards an attack zone, and various SEADing targets need to be eliminated.

* [TASK_A2G](Documentation/Task_A2G.html): Models a A2G Task, where a Player is routed towards an attack zone, and various A2G targets need to be eliminated.

## MOOSE Action Classes

MOOSE Action Classes are task action sub-flows, that can be used and combined, to quickly define a comprehensive end-to-end task action flow.
For example, for the SEAD Task, the task action flow combines the actions ASSIGN, ROUTE, ACCOUNT and ASSIST task action sub-flows.

* [ACT_ASSIGN](Documentation/Assign.html): Mechanism to accept a TASK by a player. For example, assign the task only after the player accepts the task using the menu.

* [ACT_ROUTE](Documentation/Route.html): Mechanisms to route players to zones or any other positionable coordinate. For example, route a player towards a zone.

* [ACT_ACCOUNT](Documentation/Account.html): Mechanisms to account various events within the simulator. For example, account the dead events, accounting dead units within a Target SET within a ZONE.

* [ACT_ASSIST](Documentation/Assist.html): Mechanisms to assist players executing a task. For example, acquire targets through smoking them.


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

**Mechanic (Gabor)**
Worked together with Gabor to create the concept of the DETECTION and FAC classes. Mechanic shared his ideas and concepts to group detected targets into sets within detection zones... Will continue to work with G�bor to workout the DETECTION and FAC classes.

**Shadoh**
Interacted on the eagle dynamics forum to build the FOLLOW class to build large WWII airplane formations.

For the rest I also would like to thank the numerous feedback and help and assistance of the moose community at SLACK.COM.
Note that there is a vast amount of other scripts out there. 
I may contact you personally to ask for your contribution / permission if i can use your idea or script to tweak it to the framework. 
Parts of these scripts will have to be redesigned to fit it into an OO framework.

The rest of the framework functions and class definitions were my own developments, especially the core of MOOSE.
Trust I've spent hours and hours investigating, trying and writing and documenting code building this framework.
Hope you think the idea is great and useful.