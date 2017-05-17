[SIZE=7]MOOSE Release 2.1.0[/SIZE]

Finally it is here, release 2.1.0 of MOOSE!
It took some time to prepare this release, as it was a lot of work to get the building blocks of the framework developed and tested. You'll find in this release a lot of new features as well as a couple of important bug fixes.

Release 2.1.0 is now published into the [B]master-release-2.1[/B] branch of this repository on github.
You can download the file moose.lua below to use MOOSE in your missions.
The moose.lua file is also located [URL="https://github.com/FlightControl-Master/MOOSE/blob/master-release-2.1/Moose%20Mission%20Setup/Moose.lua"]here[/URL] in the [B]master-release-2.1[/B] branch.

Those who are using the [B]master[/B] branch can continue to beta test, as new bleeding edge features will be added soon in preparation for release 2.2.0! There are many topics on the agenda to be added.

[B]This release would not have been possible without the help and contribution of many members of this community. THANK YOU![/B]



[SIZE=6]In summary:[/SIZE]

This release brings you [B]an improved tasking mechanism[/B]. 
Tasking is the system in MOOSE that allows to:

  * Execute [B]co-op[/B] missions and tasks
  * [B]Detect[/B] targets dynamically
  * Define new tasks [B]dynamically[/B]
  * Execute the tasks
  * Complete the mission [B]goals[/B]
  * Extensive menu system and briefings/reports for [B]player interaction[/B]
  * Improved Scoring of mission goal achievements, and task achievements.

On top, release brings you new functionality by the introduction of new classes to:

  * [B]Designate targets[/B] (lase, smoke or illuminate targets) by AI, assisting your attack. Allows to drop laser guides bombs.
  * A new [B]tasking[/B] system to [B]transport cargo[/B] of various types
  * Dynamically [B]spawn static objects[/B]
  * Improved [B]coordinate system[/B]
  * Build [B]large formations[/B], like bombers flying to a target area



   
[SIZE=6]1. TASKING SYSTEM![/SIZE]

A lot of work has been done in improving the tasking framework within MOOSE.

**The tasking system comes with TASK DISPATCHING mechanisms, that DYNAMICALLY 
allocate new tasks based on the tactical or strategical situation in the mission!!!
These tasks can then be engaged upon by the players!!!**

The [URL="http://flightcontrol-master.github.io/MOOSE/Documentation/Task_A2G_Dispatcher.html"]TASK_A2G_DISPATCHER[/URL] class implements the dynamic dispatching of tasks upon groups of detected units determined a Set of FAC (groups). The FAC will detect units, will group them, and will dispatch Tasks to groups of players. Depending on the type of target detected, different tasks will be dispatched. Find a summary below describing for which situation a task type is created:

  * [B]CAS Task[/B]: Is created when there are enemy ground units within range of the FAC, while there are friendly units in the FAC perimeter.
  * [B]BAI Task[/B]: Is created when there are enemy ground units within range of the FAC, while there are NO other friendly units within the FAC perimeter.
  * [B]SEAD Task[/B]: Is created when there are enemy ground units wihtin range of the FAC, with air search radars.

More TASK_... dispatcher classes are to come in the future, like A2A, G2G, etc...

Improvements on the TASKING are in summary:

  * A COMMANDCENTER has a dedicated menu.
  * A MISSION has a dedicated menu system.
  * A MISSION has a briefing report.
  * A MISSION has dedicated status reports.
  * A MISSION has for each TASK TYPE a menu.
  * A MISSION has for each TASK TYPE a dedicated menu system for each TASK defined.
  * A MISSION has an "assigned" task menu that contains menu actions relevant to the assigned task.
  * A TASK (of various types) has a dedicated menu system.
  * A TASK has a briefing report.
  * A TASK has dedicated status reports.
  * Player reports can be retrieved that explain which player is at which task.
  * ...
  
TASKING is vast, and at the moment there is too much to explain.  
[B]The best way to explore the TASKING is to TRY it...[/B]  
I suggest you have a look at the [URL="https://www.youtube.com/watch?v=v2Us8SS1-44&t=1070s"]GORI Valley Mission - Iteration 3[/URL].

Many people have contributed in the testing of the mechanism, especially:
@baluballa, @doom, @whiplash



[SIZE=6]2. New MOOSE classes have been added.[/SIZE]

MOOSE 2.1.0 comes with new classes that extends the functionality of the MOOSE framework and allow you to do new things in your missions:



[SIZE=5]2.1. Target designation by laser, smoke or illumination.[/SIZE]

[URL="http://flightcontrol-master.github.io/MOOSE/Documentation/Designate.html"]DESIGNATE[/URL] is orchestrating the designation of potential targets executed by a Recce group, 
and communicates these to a dedicated attacking group of players, 
so that following a dynamically generated menu system, 
each detected set of potential targets can be lased or smoked...
 
Targets can be:
 
   * [B]Lased[/B] for a period of time.
   * [B]Smoked[/B]. Artillery or airplanes with Illuminatino ordonance need to be present. (WIP, but early demo ready.)
   * [B]Illuminated[/B] through an illumination bomb. Artillery or airplanes with Illuminatino ordonance need to be present. (WIP, but early demo ready.

This class was made with the help of @EasyEB and many others.

[URL="https://www.youtube.com/playlist?list=PL7ZUrU4zZUl0dQ9UKQMb7YL8z2sKSqemH"]DESIGNATE is demonstrated on youtube[/URL]

DESIGNATE demonstration missions: 
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release-2.1/DES%20-%20Designation"]DES - Designation[/URL]



[SIZE=5]2.2. Transport cargo of different types to various locations as a human task within a mission.[/SIZE]

The Moose framework provides various CARGO classes that allow DCS physical or logical objects to be transported or sling loaded by Carriers.
The CARGO_ classes, as part of the moose core, are able to Board, Load, UnBoard and UnLoad cargo between Carrier units.
This collection of classes in this module define tasks for human players to handle these cargo objects.
Cargo can be transported, picked-up, deployed and sling-loaded from and to other places.
   
[URL="http://flightcontrol-master.github.io/MOOSE/Documentation/Task_Cargo.html#TASK_CARGO_TRANSPORT"]TASK_CARGO_TRANSPORT[/URL] defines a task for a human player to transport a set of cargo between various zones.
It is the first class that forms part of the TASK_CARGO classes suite.

The TASK_CARGO classes provide you with a flexible tasking sytem, 
that allows you to transport cargo of various types between various locations
and various dedicated deployment zones.
   
A human player can join the battle field in a client airborne slot or a ground vehicle within the CA module (ALT-J).
The player needs to accept the task from the task overview list within the mission, using the radio menus.
Once the TASK_CARGO_TRANSPORT is assigned to the player and accepted by the player, the player will obtain 
an extra [B]Cargo Handling Radio Menu[/B] that contains the CARGO objects that need to be transported.
Cargo can be transported towards different [B]Deployment Zones[/B], but can also be deployed anywhere within the battle field.
   
The Cargo Handling Radio Menu system allows to execute [B]various actions[/B] to handle the cargo.
In the menu, you'll find for each CARGO, that is part of the scope of the task, various actions that can be completed.
Depending on the location of your Carrier unit, the menu options will vary.
   
The [URL="http://flightcontrol-master.github.io/MOOSE/Documentation/Cargo.html#CARGO_GROUP"]CARGO_GROUP[/URL] class defines a 
cargo that is represented by a GROUP object within the simulator, and can be transported by a carrier.

The [URL="http://flightcontrol-master.github.io/MOOSE/Documentation/Cargo.html#CARGO_UNIT"]CARGO_UNIT[/URL] class defines a 
cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.

Mission designers can use the [URL="http://flightcontrol-master.github.io/MOOSE/Documentation/Set.html#SET_CARGO"]SET_CARGO[/URL] 
class to build sets of cargos.

Note 1: [B]Various other CARGO classes are defined and are WIP[/B].
Now that the foundation for Cargo handling is getting form, future releases will bring other types of CARGO handling
classes to the MOOSE framework quickly. Sling-loading, package, beacon and other types of CARGO will be released soon.

Note 2: [B]AI_CARGO has been renamed to CARGO and now forms part of the Core or MOOSE[/B].
If you were using AI_CARGO in your missions, please rename AI_CARGO with CARGO...

TASK_TRANSPORT_CARGO is demonstrated at the [URL="https://www.youtube.com/watch?v=v2Us8SS1-44&t=1070s"]GORI Valley Mission - Iteration 4[/URL]

TASK_TRANSPORT_CARGO demonstration missions:
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release-2.1/TSK%20-%20Task%20Modelling/TSK-110%20-%20Ground%20-%20Transport%20Cargo%20Group"]TSK-110 - Ground - Transport Cargo Group[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release-2.1/TSK%20-%20Task%20Modelling/TSK-210%20-%20Helicopter%20-%20Transport%20Cargo%20Group"]TSK-210 - Helicopter - Transport Cargo Group[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release-2.1/TSK%20-%20Task%20Modelling/TSK-211%20-%20Helicopter%20-%20Transport%20Multiple%20Cargo%20Groups"]TSK-211 - Helicopter - Transport Multiple Cargo Groups[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release-2.1/TSK%20-%20Task%20Modelling/TSK-212%20-%20Helicopter%20-%20Cargo%20handle%20PickedUp%20and%20Deployed%20events"]TSK-212 - Helicopter - Cargo handle PickedUp and Deployed events[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release-2.1/TSK%20-%20Task%20Modelling/TSK-213%20-%20Helicopter%20-%20Cargo%20Group%20Destroyed"]TSK-213 - Helicopter - Cargo Group Destroyed[/URL]



[SIZE=5]2.3. Dynamically spawn STATIC objects into your mission.[/SIZE]

The [URL="http://flightcontrol-master.github.io/MOOSE/Documentation/SpawnStatic.html#SPAWNSTATIC"]SPAWNSTATIC[/URL] class allows to spawn dynamically new Statics.
By creating a copy of an existing static object template as defined in the Mission Editor (ME), SPAWNSTATIC can retireve the properties of the defined static object template (like type, category etc), and "copy" these properties to create a new static object and place it at the desired coordinate.
New spawned Statics get the same name as the name of the template Static, or gets the given name when a new name is provided at the Spawn method. 

SPAWNSTATIC demonstration missions:
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release-2.1/SPS%20-%20Spawning%20Statics/SPS-100%20-%20Simple%20Spawning"]SPS-100 - Simple Spawning[/URL]



[SIZE=5]2.4. Better coordinate management in MGRS or LLor LLDecimal.[/SIZE]

The [URL="http://flightcontrol-master.github.io/MOOSE/Documentation/Point.html#COORDINATE"]COORDINATE[/URL] class 
defines a 2D coordinate in the simulator. A COORDINATE can be expressed in LL or in MGRS.



[SIZE=5]2.5. Improved scoring system[/SIZE]

Scoring is implemented throught the [URL="http://flightcontrol-master.github.io/MOOSE/Documentation/Scoring.html"]SCORING[/URL] class.
The scoring system has been improved a lot! Now, the scoring is correctly counting scores on normal units, statics and scenary objects.
Specific scores can be registered for specific targets. The scoring works together with the tasking system, so players can achieve 
additional scores when they achieve goals!

SCORING demonstration missions:
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SCO%20-%20Scoring/SCO-100%20-%20Scoring%20of%20Statics"]SCO-100 - Scoring of Statics[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SCO%20-%20Scoring/SCO-101%20-%20Scoring%20Client%20to%20Client"]SCO-101 - Scoring Client to Client[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SCO%20-%20Scoring/SCO-500%20-%20Scoring%20Multi%20Player%20Demo%20Mission%201"]SCO-500 - Scoring Multi Player Demo Mission 1[/URL]



[SIZE=5]2.6. Beacons and Radio[/SIZE]

The Radio contains 2 classes : RADIO and BEACON
  
What are radio communications in DCS ?

  * Radio transmissions consist of [B]sound files[/B] that are broadcasted on a specific [B]frequency[/B] (e.g. 115MHz) and [B]modulation[/B] (e.g. AM),
  * They can be [B]subtitled[/B] for a specific [B]duration[/B], the [B]power[/B] in Watts of the transmiter's antenna can be set, and the transmission can be [B]looped[/B].

These classes are the work of @Grey-Echo.

RADIO and BEACON demonstration missions:
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/RAD%20-%20Radio/RAD-000%20-%20Transmission%20from%20Static"]RAD-000 - Transmission from Static[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/RAD%20-%20Radio/RAD-001%20-%20Transmission%20from%20UNIT%20or%20GROUP"]RAD-001 - Transmission from UNIT or GROUP[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/RAD%20-%20Radio/RAD-002%20-%20Transmission%20Tips%20and%20Tricks"]RAD-002 - Transmission Tips and Tricks[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/RAD%20-%20Radio/RAD-010%20-%20Beacons"] 	RAD-010 - Beacons[/URL]



[SIZE=5]2.7. Build large formations of AI.[/SIZE]

[URL="http://flightcontrol-master.github.io/MOOSE/Documentation/AI_Formation.html"]AI_FORMATION[/URL] makes AI @{GROUP}s fly in formation of various compositions.
The AI_FORMATION class models formations in a different manner than the internal DCS formation logic!!!
The purpose of the class is to:
 
  * Make formation building a process that can be managed while in flight, rather than a task.
  * Human players can guide formations, consisting of larget planes.
  * Build large formations (like a large bomber field).
  * Form formations that DCS does not support off the shelve.

AI_FORMATION Demo Missions: [URL=""]FOR - AI Group Formation[/URL]

AI_FORMATION demonstration missions:
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/FOR%20-%20AI%20Group%20Formation/FOR-100%20-%20Bomber%20Left%20Line%20Formation"]FOR-100 - Bomber Left Line Formation[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/FOR%20-%20AI%20Group%20Formation/FOR-101%20-%20Bomber%20Right%20Line%20Formation"]FOR-101 - Bomber Right Line Formation[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/FOR%20-%20AI%20Group%20Formation/FOR-102%20-%20Bomber%20Left%20Wing%20Formation"]FOR-102 - Bomber Left Wing Formation[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/FOR%20-%20AI%20Group%20Formation/FOR-103%20-%20Bomber%20Right%20Wing%20Formation"]FOR-103 - Bomber Right Wing Formation[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/FOR%20-%20AI%20Group%20Formation/FOR-104%20-%20Bomber%20Center%20Wing%20Formation"]FOR-104 - Bomber Center Wing Formation[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/FOR%20-%20AI%20Group%20Formation/FOR-105%20-%20Bomber%20Trail%20Formation"]FOR-105 - Bomber Trail Formation[/URL]
  * [URL="https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/FOR%20-%20AI%20Group%20Formation/FOR-106%20-%20Bomber%20Box%20Formation"]FOR-106 - Bomber Box Formation[/URL]

Note: The AI_FORMATION is currently a first version showing the potential, a "building block". From this class, further classes will be derived and the class will be fine-tuned.



[SIZE=6]3. A lot of components have been reworked and bugs have been fixed.[/SIZE]



[SIZE=5]3.1. Better event handling and event dispatching.[/SIZE]

The underlying mechanisms to handle DCS events has been improved. Bugs have been fixed.
The MISSION_END event is now also supported.



[SIZE=5]2.2. Cargo handling has been made much better now.[/SIZE]

As a result, some of the WIP cargo classes that were defined earlier are still WIP.
But as mentioned earlier, new CARGO classes can be published faster now.
The framework is now more consistent internally.



[SIZE=6]3. A lot of new methods have been defined in several existing or new classes.[/SIZE]

AI_FORMATION:New( FollowUnit, FollowGroupSet, FollowName, FollowBriefing ) --R2.1  
AI_FORMATION:TestSmokeDirectionVector( SmokeDirection ) --R2.1  
AI_FORMATION:onafterFormationLine( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, YSpace, ZStart, ZSpace ) --R2.1  
AI_FORMATION:onafterFormationTrail( FollowGroupSet, From , Event , To, XStart, XSpace, YStart ) --R2.1  
AI_FORMATION:onafterFormationStack( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, YSpace ) --R2.1  
AI_FORMATION:onafterFormationLeftLine( FollowGroupSet, From , Event , To, XStart, YStart, ZStart, ZSpace ) --R2.1  
AI_FORMATION:onafterFormationRightLine( FollowGroupSet, From , Event , To, XStart, YStart, ZStart, ZSpace ) --R2.1  
AI_FORMATION:onafterFormationLeftWing( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, ZStart, ZSpace ) --R2.1  
AI_FORMATION:onafterFormationRightWing( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, ZStart, ZSpace ) --R2.1  
AI_FORMATION:onafterFormationCenterWing( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, YSpace, ZStart, ZSpace ) --R2.1  
AI_FORMATION:onafterFormationVic( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, YSpace, ZStart, ZSpace ) --R2.1  
AI_FORMATION:onafterFormationBox( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, YSpace, ZStart, ZSpace, ZLevels ) --R2.1  
AI_FORMATION:SetFlightRandomization( FlightRandomization ) --R2.1  
AI_FORMATION:onenterFollowing( FollowGroupSet ) --R2.1  

CARGO:GetName()  
CARGO:GetObjectName()

DATABASE:ForEachStatic( IteratorFunction, FinalizeFunction, ... )  

EVENT:Reset( EventObject ) --R2.1  

POINT_VEC3:IsLOS( ToPointVec3 ) --R2.1  

COORDINATE:New( x, y, LandHeightAdd ) --R2.1 Fixes issue #424.  
COORDINATE:NewFromVec2( Vec2, LandHeightAdd ) --R2.1 Fixes issue #424.  
COORDINATE:NewFromVec3( Vec3 ) --R2.1 Fixes issue #424.  
COORDINATE:ToStringLL( LL_Accuracy, LL_DMS ) --R2.1 Fixes issue #424.  
COORDINATE:ToStringMGRS( MGRS_Accuracy ) --R2.1 Fixes issue #424.  
COORDINATE:ToString() --R2.1 Fixes issue #424.  
COORDINATE:CoordinateMenu( RootMenu ) --R2.1 Fixes issue #424.  
COORDINATE:MenuSystem( System ) --R2.1 Fixes issue #424.  
COORDINATE:MenuLL_Accuracy( LL_Accuracy ) --R2.1 Fixes issue #424.  
COORDINATE:MenuLL_DMS( LL_DMS ) --R2.1 Fixes issue #424.  
COORDINATE:MenuMGRS_Accuracy( MGRS_Accuracy ) --R2.1 Fixes issue #424.  

SET_BASE:FilterDeads() --R2.1 allow deads to be filtered to automatically handle deads in the collection.  
SET_BASE:FilterCrashes() --R2.1 allow crashes to be filtered to automatically handle crashes in the collection.  

SET_UNIT:ForEachUnitPerThreatLevel( FromThreatLevel, ToThreatLevel, IteratorFunction, ... ) --R2.1 Threat Level implementation  

SET_CARGO:New() --R2.1  
SET_CARGO:AddCargosByName( AddCargoNames ) --R2.1  
SET_CARGO:RemoveCargosByName( RemoveCargoNames ) --R2.1  
SET_CARGO:FindCargo( CargoName ) --R2.1  
SET_CARGO:FilterCoalitions( Coalitions ) --R2.1  
SET_CARGO:FilterTypes( Types ) --R2.1  
SET_CARGO:FilterCountries( Countries ) --R2.1  
SET_CARGO:FilterPrefixes( Prefixes ) --R2.1  
SET_CARGO:FilterStart() --R2.1  
SET_CARGO:AddInDatabase( Event ) --R2.1  
SET_CARGO:FindInDatabase( Event ) --R2.1  
SET_CARGO:ForEachCargo( IteratorFunction, ... ) --R2.1  
SET_CARGO:FindNearestCargoFromPointVec2( PointVec2 ) --R2.1  
SET_CARGO:IsIncludeObject( MCargo ) --R2.1  
SET_CARGO:OnEventNewCargo( EventData ) --R2.1  
SET_CARGO:OnEventDeleteCargo( EventData ) --R2.1  SpawnStatic.lua (5 matches)

SPAWNSTATIC:NewFromStatic( SpawnTemplatePrefix, CountryID ) --R2.1  
SPAWNSTATIC:NewFromType( SpawnTypeName, SpawnShapeName, SpawnCategory, CountryID ) --R2.1  
SPAWNSTATIC:SpawnFromPointVec2( PointVec2, Heading, NewName ) --R2.1  
SPAWNSTATIC:SpawnFromZone( Zone, Heading, NewName ) --R2.1  

ZONE_BASE:GetCoordinate( Height ) --R2.1  

DESIGNATE:SetFlashStatusMenu( FlashMenu ) --R2.1  
DESIGNATE:SetLaserCodes( LaserCodes ) --R2.1  
DESIGNATE:GenerateLaserCodes() --R2.1  
DESIGNATE:SetAutoLase( AutoLase ) --R2.1  
DESIGNATE:SetThreatLevelPrioritization( Prioritize ) --R2.1  

DETECTION_BASE:CleanDetectionItems() --R2.1 Clean the DetectionItems list  
DETECTION_BASE:GetDetectedItemID( Index ) --R2.1  
DETECTION_BASE:GetDetectedID( Index ) --R2.1  
DETECTION_AREAS:DetectedReportDetailed() --R2.1  Fixed missing report  

REPORT:HasText() --R2.1  
REPORT:SetIndent( Indent ) --R2.1  
REPORT:AddIndent( Text ) --R2.1  

MISSION:GetMenu( TaskGroup ) -- R2.1 -- Changed Menu Structure  

TASK:SetMenu( MenuTime ) --R2.1 Mission Reports and Task Reports added. Fixes issue #424.  
TASK:ReportSummary() --R2.1 fixed report. Now nicely formatted and contains the info required.  
TASK:ReportOverview() --R2.1 fixed report. Now nicely formatted and contains the info required.  
TASK:GetPlayerCount() --R2.1 Get a count of the players.  
TASK:GetPlayerNames() --R2.1 Get a map of the players.  
TASK:ReportDetails() --R2.1 fixed report. Now nicely formatted and contains the info required.  

UTILS.tostringMGRS = function(MGRS, acc) --R2.1  

POSITIONABLE:GetBoundingBox() --R2.1  
POSITIONABLE:GetHeight() --R2.1  
POSITIONABLE:GetMessageText( Message, Name ) --R2.1 added  
POSITIONABLE:GetMessage( Message, Duration, Name ) --R2.1 changed callsign and name and using GetMessageText  
POSITIONABLE:MessageToSetGroup( Message, Duration, MessageSetGroup, Name )  --R2.1  
POSITIONABLE:GetRadio() --R2.1  
POSITIONABLE:GetBeacon() --R2.1  
POSITIONABLE:LaseUnit( Target, LaserCode, Duration ) --R2.1  
POSITIONABLE:LaseOff() --R2.1  
POSITIONABLE:IsLasing() --R2.1  
POSITIONABLE:GetSpot() --R2.1  
POSITIONABLE:GetLaserCode() --R2.1  

UNIT:IsDetected( TargetUnit ) --R2.1  
UNIT:IsLOS( TargetUnit ) --R2.1  
