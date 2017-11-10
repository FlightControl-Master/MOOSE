# 1. MOOSE framework

MOOSE is a **M**ission **O**bject **O**riented **S**cripting **E**nvironment, and is meant for mission designers and mission hosters.
It allows to quickly setup complex missions using pre-scripted scenarios using the available classes within the MOOSE Framework.
MOOSE works with DCS world 1.5. and 2.0.

![MOOSE Banner](Presentations\MOOSE\Dia1.JPG)

## MOOSE framework goal

The goal of MOOSE is to allow mission designers to enhance their scripting with mission orchestration objects, which can be instantiated from defined classes within the framework. This will allow to write mission scripts with minimal code embedded. Of course, the richness of the framework will determine the richness of the misson scenarios. 
The MOOSE is a service that is produced while being consumed ... , it will evolve further as more classes are developed for the framework, and as more users are using it.  

MOOSE is NOT meant to be a one-man show, it is meant to evolve within a growing community around the framework.  

Within the community, key users will start supporting, documenting, explaining and even creating new classes for the framework.
It is the ambition to grow this framework as a de-facto standard for mission designers to use.


# 2. MOOSE Framework

The following classes are currently embedded within MOOSE framework and can be included within your mission scripts:

MOOSE is an Object Oriented framework and defines **Classes**, which are components that combine **Methods** and **Variables**/**Properties** as one encapsulated structure (table).
Mission Designers can what we call **Instantiate Objects** from these MOOSE classes.

An example of what this means is shortly explained using the SPAWN class of MOOSE, which you can use to spawn new groups into your running mission.
The SPAWN class simplifies the process of spawning, and it has many methods that you can use to create variations how you want your spawn object to spawn new groups.

```lua
local SpawnObject = SPAWN:New( "GroupName" ) -- This creates a new SpawnObject from the SPAWN class, using the :New method constructor to instantiate a new SPAWN object searching for the GroupName as the late activated group defined within your Mission Editor.  
-- Nothing is spawned yet..., so let's use now the SpawnObject to spawn a new GROUP.

local SpawnGroup = SpawnObject:Spawn() -- Here we use the :Spawn() method of the SPAWN class. This method creates a new group from the GroupName template as defined within the Mission Editor.
```

MOOSE Classes derive or inherit from each other, that means, within MOOSE there is an **Inheritance** structure where **inherited MOOSE Classes** are re-using properties and methods from the **Parent MOOSE Class**.
This powerful concept is used everywhere within the MOOSE framework. The main (Parent) Class in the MOOSE framework is the BASE class. Every MOOSE Class is derived from this top BASE Class.
So is also the SPAWN class derived from the BASE class. The BASE class provides powerful methods for debugging, event handling and implements the class handling logic.
As a normal MOOSE user, you won't implement any code using inheritance but just know that the inheritance structure is omni present in the intellisense and documentation.
You'll need to browse to the right MOOSE Class within the inheritance tree structure to identify which methods are properties are defined for which class.

![MOOSE framework](Presentations\MOOSE\Dia2.JPG)



## MOOSE Demonstration Missions

The framework comes with demonstration missions which can be downloaded [here](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases), that you can try out and helps you to code.  
These missions provide examples of defined use cases how the MOOSE framework can be utilized. Each test mission is located in a separate directory, which contains at least one .lua file and .miz file.
The .lua file contains the mission script file that shows how the use case was implemented.
You can copy/paste code the code snippets from this .lua file into your missions, as it will accellerate your mission developments.
You will learn, see, and understand how the different MOOSE classes need to be applied, and how you can create
more complex mission scenarios by combining these MOOSE classes into a complex but powerful mission engine.

Some of these exact test missions are also demonstrated in a video format on the [YouTube channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg).


## 2.1. MOOSE Human Tasking Classes

MOOSE Tasking Classes provide a comprehensive Mission Orchestration System.
Through COMMANDCENTERs, multiple logical MISSIONs can be orchestrated for coalitions.
Within each MISSION, various TASKs can be defined.
Each TASK has a TASK ACTION flow, which is the flow that a player (hosted by a UNIT) within the simulator needs to follow and accomplish.

* [COMMANDCENTER](Documentation/CommandCenter.html): Orchestrates various logical MISSIONs for a coalition.

* [MISSION](Documentation/Mission.html): Each MISSION has various TASKs to be executed and accomplished by players.

* [TASK_A2A_DISPATCHER](Documentation/Task_A2A_Dispatcher.html): Automatically and dynamically dispatch A2A tasks to be executed by human players, as a result of the detection of airborne targets within a Mission scope.

* [TASK_A2G_DISPATCHER](Documentation/Task_A2G_Dispatcher.html): Automatically and dynamically dispatch A2G tasks to be executed by human players, as a result of the detection of ground targets within a Mission scope.

* [TASK_A2A](Documentation/Task_A2A.html): Models a A2A CAP, INTERCEPT and SWEEP tasks where a Player is routed towards an attack zone without enemies nearby, and various ground targets need to be eliminated.

* [TASK_A2G](Documentation/Task_A2G.html): Models a A2G SEAD, CAS and BAI tasks where a Player is routed towards an attack zone with enemies nearby, and various ground targets need to be eliminated.


## 2.2. MOOSE AI Controlling Classes

MOOSE AI Controlling Classes provide mechanisms to control AI over long lasting processes.  
These AI Controlling Classes are based on FSM (Finite State Machine) Classes, and provided an encapsulated way to make AI behave or execute an activity.

* [AI A2A Defenses](Documentation/AI_A2A_Dispatcher.html): Create automatic A2A defense systems executed by AI and perform CAP or GCI.
   * [AI\_A2A\_GCICAP](Documentation/AI_A2A_Dispatcher.html#AI_A2A_GCICAP): Using an easy process you can define an A2A defense system using the Mission Editor.
   * [AI\_A2A\_DISPATCHER](Documentation/AI_A2A_Dispatcher.html#AI_A2A_DISPATCHER): Same as AI\_A2A\_GCICAP, but is for more advanced or developer type mission designers. This class provides more options.

* [AI\_BALANCER](Documentation/AI_Balancer.html): Compensate in a multi player mission the abscence of players with dynamically spawned AI air units. When players join CLIENTS, the AI will either be destroyed, or will fly back to the home or nearest friendly airbase.

* [AI\_PATROL\_ZONE](Documentation/AI_Patrol_Zone.html): Make an alive AI Group patrol a zone derived from the ZONE_BASE class. Manage out-of-fuel events and set altitude and speed ranges for the patrol.

* [AI\_CAP](Documentation/AI_Cap.html): Make an alive AI Group perform Combat Air Patrol as a dynamic process.

* [AI\_CAS](Documentation/AI_Cas.html): Make an alive AI Group perform Close Air Support as a dynamic process.

* [AI\_BAI](Documentation/AI_Bai.html): Make an alive AI Group perform Battlefield Air Interdiction as a dynamic process.


## 2.3. MOOSE Functional Classes

MOOSE Functional Classes provide various functions that are useful in mission design.

* [ESCORT](Documentation/Escort.html): Makes groups consisting of helicopters, airplanes, ground troops or ships within a mission joining your flight. You can control these groups through the ratio menu during your flight. Available commands are around: Navigation, Position Hold, Reporting (Target Detection), Attacking, Assisted Attacks, ROE, Evasion, Mission Execution and more ...

* [MISSILETRAINER](Documentation/MissileTrainer.html): Missile trainer, it destroys missiles when they are within a certain range of player airplanes, displays tracking and alert messages of missile launches; approach; destruction, and configure with radio menu commands. Various APIs available to configure the trainer.

* [DETECTION](Documentation/Detection.html): Detect other units using the available sensors of the detection unit. The DETECTION_BASE derived classes will provide different methods how the sets of detected objects are built.

* [SCORING](Documentation/Scoring.html): Administer the scoring of player achievements, and create a CSV file logging the scoring events for use at team or squadron websites.

* [SEAD](Documentation/Sead.html): Make SAM sites avoid SEAD missiles being fired at.

* [DESIGNATE](Documentation/Designate.html): Make AI automatically designate detected targets, and provide menu options for players to give instructions to the AI how to designate (by laser, smoke or illumination).

* [AIRBASEPOLICE](Documentation/AirbasePolice.html): Control the speed of players at the airbases. Speeding players are eliminated (does not work due to a bug in the DCS).

* [CLEANUP\_AIRBASE](Documentation/CleanUp.html): Keeps the airbases clean from clutter. (Only partly functional due to a bug in DCS, destroyed objects cannot be removed).

* [RAT](Documentation/Rat.html): Random Air Traffic engine developed by FunkyFranky, use the available airspace!

* [ATC_GROUND](Documentation/ATC_Ground.html): Monitor players on the airbase and make them behave and provide instructions.
  * [ATC_GROUND](Documentation/ATC_Ground.html#ATC_GROUND_CAUCASUS): ATC Ground operations for Caucasus.
  * [ATC_GROUND](Documentation/ATC_Ground.html#ATC_GROUND_NEVADA): ATC Ground operations for Nevada.
  * [ATC_GROUND](Documentation/ATC_Ground.html#ATC_GROUND_NORMANDY): ATC Ground operations for Normandy.

* [ZONE\_CAPTURE\_COALITION](Documentation/ZoneCaptureCoalition.html): Create a zone capturing process around a zone! Zones can be guarded, attacked, empty or captured.


## 2.4. MOOSE Wrapper Classes

MOOSE Wrapper Classes provide an object oriented hierarchical mechanism to manage the DCS objects within the simulator.
Wrapper classes provide another easier mechanism to control Groups, Units, Statics, Airbases and other objects.

* [OBJECT](Documentation/Object.html): This class provides the base for MOOSE objects.

* [IDENTIFIABLE](Documentation/Identifiable.html): This class provides the base for MOOSE identifiable objects, which is every object within the simulator :-).

* [POSITIONABLE](Documentation/Positionable.html): This class provides the base for MOOSE positionable objects. These are AIRBASEs, STATICs, GROUPs, UNITs ...

* [CONTROLLABLE](Documentation/Controllable.html): This class provides the base for MOOSE controllable objects. These are GROUPs, UNITs, CLIENTs.

* [AIRBASE](Documentation/Airbase.html): This class wraps a DCS Airbase object within the simulator.

* [GROUP](Documentation/Group.html): This class wraps a DCS Group objects within the simulator.  

* [UNIT](Documentation/Unit.html): This class wraps a DCS Unit object within the simulator.

* [CLIENT](Documentation/Client.html): This class wraps a DCS Unit object within the simulator, which has a skill Client or Player.  

* [STATIC](Documentation/Static.html): This class wraps a DCS StaticObject object within the simulator. 


## 2.5. MOOSE Core Classes

These classes define the base building blocks of the MOOSE framework. These classes are heavily used within the MOOSE framework.

* [BASE](Documentation/Base.html): The main class from which all MOOSE classes are derived from. The BASE class contains essential functions to support inheritance and MOOSE object execution tracing (logging within the DCS.log file in the saved games folder of the user).

* [DATABASE](Documentation/Database.html): Creates a collection of GROUPS[], UNITS[], CLIENTS[] and managed these sets automatically. Provides an API set to retrieve a GROUP, UNIT or CLIENT instance from the _DATABASE object using defined APIs. The collections are maintained dynamically during the execution of the mission, so when players join, leave, when units are created or destroyed, the collections are dynamically updated.

* [EVENT](Documentation/Event.html): Provides the Event Dispatcher base class to handle DCS Events, being fired upon registered events within the DCS simulator. Note that EVENT is used by BASE, exposing OnEvent() methods to catch these DCS events.

* [SCHEDULER](Documentation/Scheduler.html): This class implements a timer scheduler that will call at optional specified intervals repeatedly or just one time a scheduled function.

* [SPAWN](Documentation/Spawn.html#SPAWN): Spawn new groups (and units) during mission execution.

* [SPAWNSTATIC](Documentation/SpawnStatic.html#SPAWNSTATIC): Spawn Static objects using a predefined "template".  

* [Finite State Machines](Documentation/Fsm.html):  Finite State Machine provides a process management or state machine capability for various scenarios.  
* [FSM](Documentation/Fsm.html#FSM):  The main FSM class can be used to build a generic Finite State Machine.  
* [FSM\_CONTROLLABLE](Documentation/Fsm.html#FSM_CONTROLLABLE):  An FSM class to control a Controllable. A controllable is a group or unit that can be controlled.  

* [MENU](Documentation/Menu.html): Set Menu options under the radio menu (F10). MENU classes also manage the recursive removal of menus, and the intelligent refresh of menu options (only the changes are applied).  
* [MENU\_MISSION](Documentation/Menu.html#MENU_MISSION): Set a main menu structure for the complete mission, for all players.  
* [MENU\_MISSION\_COMMAND](Documentation/Menu.html#MENU_MISSION_COMMAND): Set a main menu command for the complete mission, for all players.  
* [MENU\_COALITION](Documentation/Menu.html#MENU_COALITION): Set a menu structure for a coalition, for all players of that coalition.  
* [MENU\_COALITION\_COMMAND](Documentation/Menu.html#MENU_COALITION_COMMAND): Set a menu command for a coalition, for all players of that coalition.  
* [MENU\_GROUP](Documentation/Menu.html#MENU_GROUP): Set a menu structure for a group, for all players of that group.  
* [MENU\_GROUP\_COMMAND](Documentation/Menu.html#MENU_GROUP_COMMAND): Set a menu command for a group, for all players of that group.  

* [SET](Documentation/Set.html): Create SETs of MOOSE objects. The SET can be filtered with defined filter criteria. Iterators are available that iterate through the SET, calling a function for each object within the SET. 
* [SET\_GROUP](Documentation/Set.html#SET_GROUP): Create a SET of GROUP objects.  
* [SET\_UNIT](Documentation/Set.html#SET_UNIT): Create a SET of UNIT objects.  
* [SET\_CLIENT](Documentation/Set.html#SET_CLIENT): Create a SET of CLIENT objects.  
* [SET\_AIRBASE](Documentation/Set.html#SET_AIRBASE): Create a SET of AIRBASE objects.  
* [SET\_CARGO](Documentation/Set.html#SET_CARGO): Create a SET of CARGO objects.  

* [MESSAGE](Documentation/Message.html): A message publishing system, displaying messages to Clients, Coalitions or All players. 

* [COORDINATE](Documentation/Point.html#COORDINATE): Manage 2D and 3D points in the simulation space, and use its methods for various actions on the coordinate.  
* [POINT\_VEC2](Documentation/Point.html#POINT_VEC2): Manage 2D points in the simulation space.  
* [POINT\_VEC3](Documentation/Point.html#POINT_VEC3): Manage 3D points in the simulation space.  

* [ZONES](Documentation/Zone.html#ZONE): Create a zone object from a trigger zone as defined in the Mission Editor.  
* [ZONE\_POLYGON](Documentation/Zone.html#ZONE_POLYGON): Create a zone object from a group object, which is late activated, and its route points define the zone.  
* [ZONE\_RADIUS](Documentation/Zone.html#ZONE_RADIUS): Create a zone object from a 2D vector on the battlefield, with a defined radius.  
* [ZONE\_UNIT](Documentation/Zone.html#ZONE_UNIT): Create a zone object around a unit on the battlefield, with a defined radius. This, this zone is a moving zone!  
* [ZONE\_GROUP](Documentation/Zone.html#ZONE_GROUP): Create a zone object around a group on the battlefield, with a defined radius. The first object in the group has the zone, and is thus a moving zone!  

* [CARGO](Documentation/Cargo.html): Manage Cargo in the simulation.  
* [CARGO\_GROUP](Documentation/Cargo.html#CARGO_GROUP): Manage Cargo that is defined as a GROUP object within the simulation.  

* [BEACON](Documentation/Radio.html): Create beacons.  
* [RADIO](Documentation/Radio.html): Create radio communication.  



# 3. MOOSE usage

The delivery of MOOSE follows a structured release process. Over time, new features are added that can be used in your mission.

### The latest release of MOOSE can be downloaded **[here](https://github.com/FlightControl-Master/MOOSE/releases)**.  

There are 3 different ways how you can use MOOSE, each with a different engagement and complexity level:


## 3.1. Use MOOSE as a Mission Designer

Refer to the detailed **[Usage Guide](Usage_Guide.html)** for more information.


## 3.2. Beta test MOOSE

Beta testers of MOOSE are requested to install additional software. 

As a return or as a reward, testers get:
 
  * Newly developed features planned for the next MOOSE release can be tested and incorporated in your missions early.
  * You can evaluate and contribute to the stability of the next release.
  * Your mission creation workflow becomes very flexible. New features are dynamically added to you missions.

Please read the detailed **[Beta Test Guide](Beta_Test_Guide.html)** for more information.
  
  
## 3.3. Contribute on the MOOSE development

Those people who have experience in lua development or are excited to contribute to the MOOSE project are welcome.

Please consult the **[Contribution Guide](Contribution_Guide.html)** for more information.
  

## 3.4. Debug your code interactively using LDT

Have a look at the **[Interactive Debug Guide](Interactive_Debug_Guide.html)** to setup your system so you can debug your mission code.



# 4. MOOSE Support Channels

MOOSE is broadcasted, documented and supported through various social media channels.  

Click here for the **[communities guide](Communities.html)** of the MOOSE framework.



# 5. Credits

Note that most of the framework is based on code i've written myself, 
but some code of it is also based on code that i've seen as great scripting code and ideas, 
and which has been revised and/or reworked to fit into the MOOSE framework. 
I see this framework evolving towards a broader public, and the ownership may dissapear (or parts of it). Consider this code public domain. 
Therefore a list of credits to all who have or are contributing (this list will increase over time). 

You'll notice that within this framework, there are functions used from mist. I've taken the liberty to copy those atomic mist functions that are very nice and useful, and used those. 


**Greyecho**
Contributed the devevelopment of the new release system, and the development of the RADIO and BEACON functionalities.
We'll see more appearing from him.

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

**Grimes**
Without the effort of Grimes with MIST and his continuous documentation of the DCS API, the development of MOOSE would not have been possible.  
MOOSE is complementary to [MIST](https://github.com/mrSkortch/MissionScriptingTools/releases), so if you use MIST in parallel with MOOSE objects, this should work.  
The documentation of the [DCS API] is the work of Grimes. Please consult his documentation in case of any question concerning the DCS API level.

For the rest I also would like to thank the numerous feedback and help and assistance of the moose community at SLACK.COM.
Note that there is a vast amount of other scripts out there. 
I may contact you personally to ask for your contribution / permission if i can use your idea or script to tweak it to the framework. 
Parts of these scripts will have to be redesigned to fit it into an OO framework.

The rest of the framework functions and class definitions were my own developments, especially the core of MOOSE.
Trust I've spent hours and hours investigating, trying and writing and documenting code building this framework.
Hope you think the idea is great and useful.

Thank you!
FC
 
