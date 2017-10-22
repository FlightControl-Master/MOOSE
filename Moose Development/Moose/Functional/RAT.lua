-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- **Functional** - Create random airtraffic in your missions.
--  
-- ![Banner Image](..\Presentations\RAT\RAT.png)
-- 
-- ====
-- 
-- The aim of the RAT class is to fill the empty DCS world with randomized air traffic and bring more life to your airports.
-- 
-- In particular, it is designed to spawn AI air units at random airports. These units will be assigned a random flight path to another random airport on the map.
-- 
-- Even the mission designer will not know where aircraft will be spawned and which route they follow.
-- 
-- ## Features
-- 
--  * Very simple interface. Just one unit and two lines of Lua code needed to fill your map.
--  * High degree of randomization. Aircraft will spawn at random airports, have random routes and random destinations.
--  * Specific departure and/or destination airports can be chosen.
--  * Departure and destination airports can be restricted by coalition.
--  * Planes and helicopters supported. Helicopters can also be send to FARPs and ships.
--  * Units can also be spawned in air within pre-defined zones of the map.
--  * Aircraft will be removed when they arrive at their destination (or get stuck on the ground).
--  * When a unit is removed a new unit with a different flight plan is respawned.
--  * Aircraft can report their status during the route.
--  * All of the above can be customized by the user if necessary.
--  * All current (Caucasus, Nevada, Normandy) and future maps are supported.
--  
--  The RAT class creates an entry in the F10 menu which allows to
--  
--  * Create new groups on-the-fly, i.e. at run time within the mission,
--  * Destroy specific groups (e.g. if they get stuck or damaged and block a runway),
--  * Request the status of all RAT aircraft or individual groups,
--  * Place markers at waypoints on the F10 map for each group.
-- 
-- Note that by its very nature, this class is suited best for civil or transport aircraft. However, it also works perfectly fine for military aircraft of any kind.
-- 
-- More of the documentation include some simple examples can be found further down this page.
-- 
-- ====
-- 
-- # Demo Missions
--
-- ### [RAT Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/Release/RAT%20-%20Random%20Air%20Traffic)
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### RAT videos are work in progress.
-- ### [MOOSE YouTube Channel](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl1jirWIo4t4YxqN-HxjqRkL)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: **Sven van de Velde ([FlightControl](https://forums.eagle.ru/member.php?u=89536))**
-- 
-- ====
-- @module Rat

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- RAT class
-- @type RAT
-- @field #string ClassName Name of the Class.
-- @field #boolean debug Turn debug messages on or off.
-- @field Core.Group#GROUP templategroup Group serving as template for the RAT aircraft.
-- @field #string alias Alias for spawned group.
-- @field #boolean spawninitialized If RAT:Spawn() was already called this RAT object is set to true to prevent users to call it again.
-- @field #number spawndelay Delay time in seconds before first spawning happens.
-- @field #number spawninterval Interval between spawning units/groups. Note that we add a randomization of 50%.
-- @field #number coalition Coalition of spawn group template.
-- @field #number country Country of spawn group template.
-- @field #string category Category of aircarft: "plane" or "heli".
-- @field #string friendly Possible departure/destination airport: all=blue+red+neutral, same=spawn+neutral, spawnonly=spawn, blue=blue+neutral, blueonly=blue, red=red+neutral, redonly=red.
-- @field #table ctable Table with the valid coalitons from choice self.friendly.
-- @field #table aircraft Table which holds the basic aircraft properties (speed, range, ...).
-- @field #number Vcruisemax Max cruise speed in m/s (250 m/s = 900 km/h = 486 kt) set by user.
-- @field #number Vclimb Default climb rate in ft/min.
-- @field #number AlphaDescent Default angle of descenti in degrees. A value of 3.6 follows the 3:1 rule of 3 miles of travel and 1000 ft descent.
-- @field #string roe ROE of spawned groups, default is weapon hold (this is a peaceful class for civil aircraft or ferry missions). Possible: "hold", "return", "free".
-- @field #string rot ROT of spawned groups, default is no reaction. Possible: "noreaction", "passive", "evade".
-- @field #string takeoff Takeoff type. 0=coldorhot.
-- @field #number mindist Min distance from departure to destination in meters. Default 5 km.
-- @field #number maxdist Max distance from departure to destination in meters. Default 5000 km.
-- @field #table airports_map All airports available on current map (Caucasus, Nevada, Normandy, ...).
-- @field #table airports All airports of friedly coalitions.
-- @field #boolean random_departure By default a random friendly airport is chosen as departure.
-- @field #boolean random_destination By default a random friendly airport is chosen as destination.
-- @field #table departure_zones Array containing the names of the departure zones.
-- @field #table departure_ports Array containing the names of the destination airports.
-- @field #table destination_ports Array containing the names of the destination airports.
-- @field #table excluded_ports Array containing the names of explicitly excluded airports.
-- @field #table destination_zones Array containing the names of the destination zones.
-- @field #boolean destinationzone Destination is a zone and not an airport.
-- @field #table return_zones Array containing the names of the return zones.
-- @field #boolean returnzone Zone where aircraft will fly to before returning to their departure airport.
-- @field Core.Zone#ZONE departure_Azone Zone containing the departure airports.
-- @field Core.Zone#ZONE destination_Azone Zone containing the destination airports.
-- @field #table ratcraft Array with the spawned RAT aircraft.
-- @field #number Tinactive Time in seconds after which inactive units will be destroyed. Default is 300 seconds.
-- @field #boolean reportstatus Aircraft report status.
-- @field #number statusinterval Intervall between status checks (and reports if enabled).
-- @field #boolean placemarkers Place markers of waypoints on F10 map.
-- @field #number FLuser Flight level set by users explicitly.
-- @field #number FLminuser Minimum flight level set by user.
-- @field #number FLmaxuser Maximum flight level set by user.
-- @field #boolean commute Aircraft commute between departure and destination, i.e. when respawned the departure airport becomes the new destiation.
-- @field #boolean continuejourney Aircraft will continue their journey, i.e. get respawned at their destination with a new random destination.
-- @field #number ngroups Number of groups to be spawned in total.
-- @field #number alive Number of groups which are alive.
-- @field #boolean f10menu Add an F10 menu for RAT.
-- @field #table Menu F10 menu items for this RAT object.
-- @field #string SubMenuName Submenu name for RAT object.
-- @field #boolean respawn_at_landing Respawn aircraft the moment they land rather than at engine shutdown.
-- @field #boolean norespawn Aircraft will not be respawned after they have finished their route.
-- @field #boolean respawn_after_takeoff Aircraft will be respawned directly after take-off.
-- @field #number respawn_delay Delay in seconds until repawn happens after landing.
-- @field #table markerids Array with marker IDs.
-- @field #table waypointdescriptions Table with strings for waypoint descriptions of markers.
-- @field #table waypointstatus Table with strings of waypoint status.
-- @field #string livery Livery of the aircraft set by user.
-- @field #string skill Skill of AI.
-- @field #boolean ATCswitch Enable/disable ATC if set to true/false.
-- @field #string parking_id String with a special parking ID for the aircraft.
-- @field #number wp_final Index of the final waypoint.
-- @field #number wp_holding Index of the holding waypoint.
-- @field #boolean radio If true/false disables radio messages from the RAT groups.
-- @field #number frequency Radio frequency used by the RAT groups.
-- @field #string modulation Ratio modulation. Either "FM" or "AM". 
-- @extends Core.Spawn#SPAWN

---# RAT class, extends @{Spawn#SPAWN}
-- The RAT class implements an easy to use way to randomly fill your map with AI aircraft.
-- 
--
-- ## Airport Selection
-- 
-- ![Process](..\Presentations\RAT\RAT_Airport_Selection.png)
-- 
-- ### Default settings:
-- 
-- * By default, aircraft are spawned at airports of their own coalition (blue or red) or neutral airports.
-- * Destination airports are by default also of neutral or of the same coalition as the template group of the spawned aircraft.
-- * Possible destinations are restricted by their distance to the departure airport. The maximal distance depends on the max range of spawned aircraft type and its initial fuel amount.
-- 
-- ### The default behavior can be changed:
-- 
-- * A specific departure and/or destination airport can be chosen.
-- * Valid coalitions can be set, e.g. only red, blue or neutral, all three "colours".
-- * It is possible to start in air within a zone defined in the mission editor or within a zone above an airport of the map.
-- 
-- ## Flight Plan
-- 
-- ![Process](..\Presentations\RAT\RAT_Flight_Plan.png)
-- 
-- * A general flight plan has five main airborne segments: Climb, cruise, descent, holding and final approach.
-- * Events monitored during the flight are: birth, engine-start, take-off, landing and engine-shutdown.
-- * The default flight level (FL) is set to ~FL200, i.e. 20000 feet ASL but randomized for each aircraft.
-- Service ceiling of aircraft type is into account for max FL as well as the distance between departure and destination.
-- * Maximal distance between destination and departure airports depends on range and initial fuel of aircraft.
-- * Climb rate is set to a moderate value of ~1500 ft/min.
-- * The standard descent rate follows the 3:1 rule, i.e. 1000 ft decent per 3 miles of travel. Hence, angle of descent is ~3.6 degrees.
-- * A holding point is randomly selected at a distance between 5 and 10 km away from destination airport.
-- * The altitude of theholding point is ~1200 m AGL. Holding patterns might or might not happen with variable duration.
-- * If an aircraft is spawned in air, the procedure omitts taxi and take-off and starts with the climb/cruising part.
-- * All values are randomized for each spawned aircraft.
-- 
-- ## Mission Editor Setup
-- 
-- ![Process](..\Presentations\RAT\RAT_Mission_Setup.png)
-- 
-- Basic mission setup is very simple and essentially a three step process:
-- 
-- * Place your aircraft **anywhere** on the map. It really does not matter where you put it.
-- * Give the group a good name. In the example above the group is named "RAT_YAK".
-- * Activate the "LATE ACTIVATION" tick box. Note that this aircraft will not be spawned itself but serves a template for each RAT aircraft spawned when the mission starts. 
-- 
-- Voilà, your already done!
-- 
-- Optionally, you can set a specific livery for the aircraft or give it some weapons.
-- However, the aircraft will by default not engage any enemies. Think of them as beeing on a peaceful or ferry mission.
-- 
-- ## Basic Lua Script
-- 
-- ![Process](..\Presentations\RAT\RAT_Basic_Lua_Script.png)
-- 
-- The basic Lua script for one template group consits of two simple lines as shown in the picture above.
-- 
-- * **Line 2** creates a new RAT object "yak". The only required parameter for the constructor @{#RAT.New}() is the name of the group as defined in the mission editor. In this example it is "RAT_YAK".
-- * **Line 5** trigger the command to spawn the aircraft. The (optional) parameter for the @{#RAT.Spawn}() function is the number of aircraft to be spawned of this object.
-- By default each of these aircraft gets a random departure airport anywhere on the map and a random destination airport, which lies within range of the of the selected aircraft type.
-- 
-- In this simple example aircraft are respawned with a completely new flightplan when they have reached their destination airport.
-- The "old" aircraft is despawned (destroyed) after it has shut-down its engines and a new aircraft of the same type is spawned at a random departure airport anywhere on the map.
-- Hence, the default flight plan for a RAT aircraft will be: Fly from airport A to B, get respawned at C and fly to D, get respawned at E and fly to F, ...
-- This ensures that you always have a constant number of AI aircraft on your map.
-- 
-- ## Examples
-- 
-- Here are a few examples, how you can modify the default settings of RAT class objects.
-- 
-- ### Specify Departure and Destinations
-- 
-- ![Process](..\Presentations\RAT\RAT_Examples_Specify_Departure_and_Destination.png)
-- 
-- In the picture above you find a few possibilities how to modify the default behaviour to spawn at random airports and fly to random destinations.
-- 
-- In particular, you can specify fixed departure and/or destination airports. This is done via the @{#RAT.SetDeparture}() or @{#RAT.SetDestination}() functions, respectively.
-- 
-- * If you only fix a specific departure airport via @{#RAT.SetDeparture}() all aircraft will be spawned at that airport and get random destination airports.
-- * If you only fix the destination airport via @{#RAT.SetDestination}(), aircraft a spawned at random departure airports but will all fly to the destination airport.
-- * If you fix departure and destination airports, aircraft will only travel from between those airports.
-- When the aircraft reaches its destination, it will be respawned at its departure and fly again to its destination.   
-- 
-- There is also an option that allows aircraft to "continue their journey" from their destination. This is achieved by the @{#RAT.ContinueJourney}() function.
-- In that case, when the aircraft arrives at its first destination it will be respawned at that very airport and get a new random destination.
-- So the flight plan in this case would be: Fly from airport A to B, then from B to C, then from C to D, ...
-- 
-- It is also possible to make aircraft "commute" between two airports, i.e. flying from airport A to B and then back from B to A, etc.
-- This can be done by the @{#RAT.Commute}() function. Note that if no departure or destination airports are specified, the first departure and destination are chosen randomly.
-- Then the aircraft will fly back and forth between those two airports indefinetly.
-- 
-- 
-- ### Spawn in Air
-- 
-- ![Process](..\Presentations\RAT\RAT_Examples_Spawn_in_Air.png)
-- 
-- Aircraft can also be spawned in air rather than at airports on the ground. This is done by setting @{#RAT.SetTakeoff}() to "air".
-- 
-- By default, aircraft are spawned randomly above airports of the map.
-- 
-- The @{#RAT.SetDeparture}() option can be used to specify zones, which have been defined in the mission editor as departure zones.
-- Aircraft will then be spawned at a random point within the zone or zones.
-- 
-- Note that @{#RAT.SetDeparture}() also accepts airport names. For an air takeoff these are treated like zones with a radius of XX kilometers.
-- Again, aircraft are spawned at random points within these zones around the airport.
-- 
-- ### Misc Options
-- 
-- ![Process](..\Presentations\RAT\RAT_Examples_Misc.png)
-- 
-- The default "takeoff" type of RAT aircraft is that they are spawned with hot or cold engines.
-- The choice is random, so 50% of aircraft will be spawned with hot engines while the other 50% will be spawned with cold engines.
-- This setting can be changed using the @{#RAT.SetTakeoff}() function. The possible parameters for starting on ground are:
-- 
-- *  @{#RAT.SetTakeoff}("cold"), which means that all aircraft are spawned with their engines off,
-- *  @{#RAT.SetTakeoff}("hot"), which means that all aircraft are spawned with their engines on,
-- *  @{#RAT.SetTakeoff}("runway"), which means that all aircraft are spawned already at the runway ready to takeoff.
-- Note that in this case the default spawn intervall is set to 180 seconds in order to avoid aircraft jamms on the runway. Generally, this takeoff at runways should be used with care and problems are to be expected.
-- 
-- 
-- The options @{#RAT.SetMinDistance}() and @{#RAT.SetMaxDistance}() can be used to restrict the range from departure to destination. For example
-- 
-- * @{#RAT.SetMinDistance}(100) will cause only random destination airports to be selected which are **at least** 100 km away from the departure airport.
-- * @{#RAT.SetMaxDistance}(150) will allow only destination airports which are **less than** 150 km away from the departure airport.
-- 
-- ![Process](..\Presentations\RAT\RAT_Gaussian.png)
-- 
-- By default planes get a cruise altitude of ~20,000 ft ASL. The actual altitude is sampled from a Gaussian distribution. The picture shows this distribution
-- if one would spawn 1000 planes. As can be seen most planes get a cruising alt of around FL200. Other values are possible but less likely the further away
-- one gets from the expectation value.
-- 
-- The expectation value, i.e. the altitude most aircraft get, can be set with the function @{#RAT.SetFLcruise}().
-- It is possible to restrict the minimum cruise altitude by @{#RAT.SetFLmin}() and the maximum cruise altitude by @{#RAT.SetFLmax}()
-- 
-- The cruise altitude can also be given in meters ASL by the functions @{#RAT.SetCruiseAltitude}(), @{#RAT.SetMinCruiseAltitude}() and @{#RAT.SetMaxCruiseAltitude}().
-- 
-- For example:
-- 
-- * @{#RAT.SetFLcruise}(300) will cause most planes fly around FL300.
-- * @{#RAT.SetFLmin}(100) restricts the cruising alt such that no plane will fly below FL100. Note that this automatically changes the minimum distance from departure to destination.
-- That means that only destinations are possible for which the aircraft has had enought time to reach that flight level and descent again.  
-- * @{#RAT.SetFLmax}(200) will restrict the cruise alt to maximum FL200, i.e. no aircraft will travel above this height.
-- 
-- 
-- @field #RAT
RAT={
  ClassName = "RAT",        -- Name of class: RAT = Random Air Traffic.
  debug=false,              -- Turn debug messages on or off.
  templategroup=nil,        -- Template group for the RAT aircraft.
  alias=nil,                -- Alias for spawned group.
  spawninitialized=false,   -- If RAT:Spawn() was already called this is set to true to prevent users to call it again.
  spawndelay=5,             -- Delay time in seconds before first spawning happens.
  spawninterval=5,          -- Interval between spawning units/groups. Note that we add a randomization of 50%.
  coalition = nil,          -- Coalition of spawn group template.
  country = nil,            -- Country of the group template.
  category = nil,           -- Category of aircarft: "plane" or "heli".
  friendly = "same",        -- Possible departure/destination airport: all=blue+red+neutral, same=spawn+neutral, spawnonly=spawn, blue=blue+neutral, blueonly=blue, red=red+neutral, redonly=red.
  ctable = {},              -- Table with the valid coalitons from choice self.friendly.
  aircraft = {},            -- Table which holds the basic aircraft properties (speed, range, ...).
  Vcruisemax=nil,           -- Max cruise speed in set by user.
  Vclimb=1500,              -- Default climb rate in ft/min.
  AlphaDescent=3.6,         -- Default angle of descenti in degrees. A value of 3.6 follows the 3:1 rule of 3 miles of travel and 1000 ft descent.
  roe = "hold",             -- ROE of spawned groups, default is weapon hold (this is a peaceful class for civil aircraft or ferry missions). Possible: "hold", "return", "free".
  rot = "noreaction",       -- ROT of spawned groups, default is no reaction. Possible: "noreaction", "passive", "evade".
  takeoff = 0,              -- Takeoff type. 0=coldorhot.
  mindist = 5000,           -- Min distance from departure to destination in meters. Default 5 km.
  maxdist = 500000,         -- Max distance from departure to destination in meters. Default 5000 km.
  airports_map={},          -- All airports available on current map (Caucasus, Nevada, Normandy, ...).
  airports={},              -- All airports of friedly coalitions.
  random_departure=true,    -- By default a random friendly airport is chosen as departure.
  random_destination=true,  -- By default a random friendly airport is chosen as destination.
  departure_zones={},       -- Array containing the names of the departure zones.
  departure_ports={},       -- Array containing the names of the departure airports.
  destination_ports={},     -- Array containing the names of the destination airports.
  destination_zones={},     -- Array containing the names of destination zones.
  destinationzone=false,    -- Destination is a zone and not an airport.
  return_zones={},          -- Array containing the names of return zones.
  returnzone=false,         -- Aircraft will fly to a zone and back.
  excluded_ports={},        -- Array containing the names of explicitly excluded airports.
  departure_Azone=nil,      -- Zone containing the departure airports.
  destination_Azone=nil,    -- Zone containing the destination airports.
  ratcraft={},              -- Array with the spawned RAT aircraft.
  Tinactive=300,            -- Time in seconds after which inactive units will be destroyed. Default is 300 seconds.
  reportstatus=false,       -- Aircraft report status.
  statusinterval=30,        -- Intervall between status checks (and reports if enabled).
  placemarkers=false,       -- Place markers of waypoints on F10 map.
  FLminuser=nil,            -- Minimum flight level set by user.
  FLmaxuser=nil,            -- Maximum flight level set by user.
  FLuser=nil,               -- Flight level set by users explicitly.
  commute=false,            -- Aircraft commute between departure and destination, i.e. when respawned the departure airport becomes the new destiation.
  continuejourney=false,    -- Aircraft will continue their journey, i.e. get respawned at their destination with a new random destination.
  alive=0,                  -- Number of groups which are alive.
  ngroups=nil,              -- Number of groups to be spawned in total. 
  f10menu=true,             -- Add an F10 menu for RAT.
  Menu={},                  -- F10 menu items for this RAT object.
  SubMenuName=nil,          -- Submenu name for RAT object.
  respawn_at_landing=false, -- Respawn aircraft the moment they land rather than at engine shutdown.
  norespawn=false,          -- Aircraft will not get respawned.
  respawn_after_takeoff=false, -- Aircraft will be respawned directly after takeoff.
  respawn_delay=nil,        -- Delay in seconds until repawn happens after landing.
  markerids={},             -- Array with marker IDs.
  waypointdescriptions={},  -- Array with descriptions for waypoint markers.
  waypointstatus={},        -- Array with status info on waypoints.
  livery=nil,               -- Livery of the aircraft.
  skill="High",             -- Skill of AI.
  ATCswitch=true,           -- Enable ATC.
  parking_id=nil,           -- Specific parking ID when aircraft are spawned at airports.
  wp_final=nil,             -- Index of the final waypoint.
  wp_holding=nil,           -- Index of the holding waypoint.
  radio=nil,                -- If true/false disables radio messages from the RAT groups.
  frequency=nil,            -- Radio frequency used by the RAT groups.
  modulation=nil,           -- Ratio modulation. Either "FM" or "AM".
  actype=nil,               -- Aircraft type set by user. Changes the type of the template group.
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Categories of the RAT class. 
-- @list cat
-- @field #string plane Plane.
-- @field #string heli Heli.
RAT.cat={
  plane="plane",
  heli="heli",
}

--- RAT waypoint type.
-- @list wp
RAT.wp={
  coldorhot=0,
  air=1,
  runway=2,
  hot=3,
  cold=4,  
  climb=5,
  cruise=6,
  descent=7,
  holding=8,
  landing=9,
  finalwp=10,
}

--- RAT aircraft status.
-- @list status
RAT.status={
  -- Waypoint states.
  Departure="At departure point",
  Climb="Climbing",
  Cruise="Cruising",
  Uturn="Flying back home",
  Descent="Descending",
  DescentHolding="Descend to holding point",
  Holding="Holding",
  Destination="Arrived at destination",
  -- Event states.
  EventBirthAir="Born in air",
  EventBirth="Born on ground",
  EventEngineStartAir="Started engines (in air)",
  EventEngineStart="Started engines",
  EventTakeoff="Took off",
  EventLand="Landed",
  EventEngineShutdown="Engines shut down",
  EventDead="Dead",
  EventCrash="Crashed",
}

--- RAT friendly coalitions.
-- @list coal
RAT.coal={
  same="same",
  sameonly="sameonly",
  neutral="neutral",
}

--- RAT unit conversions.
-- @list unit
RAT.unit={
  ft2meter=0.305,
  kmh2ms=0.278,
  FL2m=30.48,
  nm2km=1.852,
  nm2m=1852,
}

--- RAT rules of engagement.
-- @list ROE
RAT.ROE={
  weaponhold="hold",
  weaponfree="free",
  returnfire="return",
}

--- RAT reaction to threat.
-- @list ROT
RAT.ROT={
  evade="evade",
  passive="passive",
  noreaction="noreaction",
}

RAT.ATC={
  init=false,
  flight={},
  airport={},
  unregistered=-1,
  onfinal=-100,
  Nclearance=2,
  delay=180,
}

--- Running number of placed markers on the F10 map.
-- @field #number markerid
RAT.markerid=0

--- Main F10 menu.
-- @field #string MenuF10
RAT.MenuF10=nil

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
RAT.id="RAT | "

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--TODO list:
--DONE: Add scheduled spawn.
--DONE: Add possibility to spawn in air.
--DONE: Add departure zones for air start.
--DONE: Make more functions to adjust/set RAT parameters.
--DONE: Clean up debug messages.
--DONE: Improve flight plan. Especially check FL against route length.
--DONE: Add event handlers.
--DONE: Respawn units when they have landed.
--DONE: Change ROE state.
--DONE: Make ROE state user function
--DONE: Improve status reports.
--DONE: Check compatibility with other #SPAWN functions. nope, not all!
--DONE: Add possibility to continue journey at destination. Need "place" in event data for that.
--DONE: Add enumerators and get rid off error prone string comparisons.
--DONE: Check that FARPS are not used as airbases for planes.
--DONE: Add special cases for ships (similar to FARPs).
--DONE: Add cases for helicopters.
--DONE: Add F10 menu.
--DONE: Add markers to F10 menu.
--DONE: Add respawn limit. Later...
--DONE: Make takeoff method random between cold and hot start.
--DONE: Check out uncontrolled spawning. Not now!
--DONE: Check aircraft spawning in air at Sochi after third aircraft was spawned. ==> DCS behaviour.
--DONE: Improve despawn after stationary. Might lead to despawning if many aircraft spawn at the same time.
--DONE: Check why birth event is not handled. ==> Seems to be okay if it is called _OnBirth rather than _OnBirthday. Dont know why actually!?
--DONE: Improve behaviour when no destination or departure airports were found. Leads to crash, e.g. 1184: attempt to get length of local 'destinations' (a nil value)
--DONE: Check cases where aircraft get shot down.
--DONE: Handle the case where more than 10 RAT objects are spawned. Likewise, more than 10 groups of one object. Causes problems with the number of menu items! ==> not now!
--DONE: Add custom livery choice if possible.
--TODO: When only a destination is set, it should be checked that the departure is within range. Also, that departure and destination are not the same.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new RAT object.
-- @param #RAT self
-- @param #string groupname Name of the group as defined in the mission editor. This group is serving as a template for all spawned units.
-- @param #string alias (Optional) Alias of the group. This is and optional parameter but must(!) be used if the same template group is used for more than one RAT object.  
-- @return #RAT Object of RAT class.
-- @return #nil If the group does not exist in the mission editor.
-- @usage yak1:RAT("RAT_YAK") will create a RAT object called "yak1". The template group in the mission editor must have the name "RAT_YAK".
-- @usage yak2:RAT("RAT_YAK", "Yak2") will create a RAT object "yak2". The template group in the mission editor must have the name "RAT_YAK" but the group will be called "Yak2" in e.g. the F10 menu.
function RAT:New(groupname, alias)

  -- Welcome message.
  env.info(RAT.id.."Creating new RAT object from template: "..groupname)
  
  -- Set alias.
  alias=alias or groupname

  -- Inherit SPAWN class.
  local self=BASE:Inherit(self, SPAWN:NewWithAlias(groupname, alias)) -- #RAT
  
  -- Alias of groupname.
  self.alias=alias
  
  -- Get template group defined in the mission editor.
  local DCSgroup=Group.getByName(groupname)
  
  -- Check the group actually exists.
  if DCSgroup==nil then
    env.error("Group with name "..groupname.." does not exist in the mission editor!")
    return nil
  end
  
  -- Store template group.
  self.templategroup=GROUP:FindByName(groupname)

  -- Set own coalition.
  self.coalition=DCSgroup:getCoalition()
  
  -- Initialize aircraft parameters based on ME group template.
  self:_InitAircraft(DCSgroup)
  
  -- Get all airports of current map (Caucasus, NTTR, Normandy, ...).
  self:_GetAirportsOfMap()
     
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Triggers the spawning of AI aircraft. Note that all additional options should be set before giving the spawn command.
-- @param #RAT self
-- @param #number naircraft (Optional) Number of aircraft to spawn. Default is one aircraft.
-- @usage yak:Spawn(5) will spawn five aircraft. By default aircraft will spawn at neutral and red airports if the template group is part of the red coaliton.
function RAT:Spawn(naircraft)

  -- Make sure that this function is only been called once per RAT object.
  if self.spawninitialized==true then
    env.error("Spawn function should only be called once per RAT object! Exiting and returning nil.")
    return nil
  else
    self.spawninitialized=false
  end

  -- Number of aircraft to spawn. Default is one.
  self.ngroups=naircraft or 1
  
  -- Init RAT ATC if not already done.
  if self.ATCswitch and not RAT.ATC.init then
    RAT:_ATCInit(self.airports_map)
  end
  
  -- Create F10 main menu if it does not exists yet.
  if self.f10menu and not RAT.MenuF10 then
    RAT.MenuF10 = MENU_MISSION:New("RAT")
  end
  
    -- Set the coalition table based on choice of self.coalition and self.friendly.
  self:_SetCoalitionTable()
  
  -- Get all airports of this map beloning to friendly coalition(s).
  self:_GetAirportsOfCoalition()
  
  -- Set submenuname if it has not been set by user.
  if not self.SubMenuName then
    self.SubMenuName=self.alias
  end

  -- Get all departure airports inside a Moose zone.  
  if self.departure_Azone~=nil then
    self.departure_ports=self:_GetAirportsInZone(self.departure_Azone)
  end
  
  -- Get all destination airports inside a Moose zone.  
  if self.destination_Azone~=nil then
    self.destination_ports=self:_GetAirportsInZone(self.destination_Azone)
  end
  
  
  -- Consistancy checks
  -- Destination zone and return zone should not be used together.
  if self.destinationzone and self.returnzone then
    env.error(RAT.id.."Destination zone _and_ return to zone not possible! Disabling return to zone.")
    self.returnzone=false
  end
  -- Return zone should not be used together with air start. Why actually?
  if self.returnzone and self.takeoff==RAT.wp.air then
    env.error(RAT.id.."Combination return zone _and_ air start not possible! Falling back to destination zone instead.")
    self.returnzone=false
    self.destinationzone=true
  end
  -- Return zone and commute does not make sense.  
  if self.returnzone and self.continuejourney then
    env.error(RAT.id.."Combination return zone _and_ commute does not make sense! Disabling commute.")
    self.commute=false
  end
  
  -- Return zone and commute does not make sense.  
--  if self.returnzone and self.commute then
--    env.error(RAT.id.."Combination return zone _and_ commute does not make sense! Disabling commute.")
--    self.commute=false  
--  end
  
  
  -- Settings info
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Spawning %i aircraft from template %s of type %s.\n", self.ngroups, self.SpawnTemplatePrefix, self.aircraft.type)
  text=text..string.format("Alias: %s\n", self.alias)
  text=text..string.format("Category: %s\n", self.category)
  text=text..string.format("Friendly coalitions: %s\n", self.friendly)
  text=text..string.format("Number of airports on map  : %i\n", #self.airports_map)
  text=text..string.format("Number of friendly airports: %i\n", #self.airports)
  text=text..string.format("Min dist to destination: %4.1f\n", self.mindist)
  text=text..string.format("Max dist to destination: %4.1f\n", self.maxdist)
  text=text..string.format("Takeoff type: %i\n", self.takeoff)
  text=text..string.format("Commute: %s\n", tostring(self.commute))
  text=text..string.format("Journey: %s\n", tostring(self.continuejourney))
  text=text..string.format("Destination Zone: %s\n", tostring(self.destinationzone))
  text=text..string.format("Return Zone: %s\n", tostring(self.returnzone))
  text=text..string.format("Spawn delay: %4.1f\n", self.spawndelay)
  text=text..string.format("Spawn interval: %4.1f\n", self.spawninterval)
  text=text..string.format("Respawn after landing: %s\n", tostring(self.respawn_at_landing))
  text=text..string.format("Respawning off: %s\n", tostring(self.norespawn))
  text=text..string.format("Respawn after take-off: %s\n", tostring(self.respawn_after_takeoff))
  text=text..string.format("Respawn delay: %s\n", tostring(self.respawn_delay))
  text=text..string.format("ROE: %s\n", tostring(self.roe))
  text=text..string.format("ROT: %s\n", tostring(self.rot))
  text=text..string.format("Vclimb: %4.1f\n", self.Vclimb)
  text=text..string.format("AlphaDescent: %4.2f\n", self.AlphaDescent)
  text=text..string.format("Vcruisemax: %s\n", tostring(self.Vcruisemax))
  text=text..string.format("FLuser: %s\n", tostring(self.Fluser))
  text=text..string.format("FLminuser: %s\n", tostring(self.Flminuser))
  text=text..string.format("FLmaxuser: %s\n", tostring(self.Flmaxuser))
  text=text..string.format("Place markers: %s\n", tostring(self.placemarkers))
  text=text..string.format("Report status: %s\n", tostring(self.reportstatus))
  text=text..string.format("Status interval: %4.1f\n", self.statusinterval)
  text=text..string.format("Time inactive: %4.1f\n", self.Tinactive)
  text=text..string.format("Create F10 menu : %s\n", tostring(self.f10menu))
  text=text..string.format("F10 submenu name: %s\n", self.SubMenuName)
  text=text..string.format("ATC enabled : %s\n", tostring(self.ATCswitch))
  text=text..string.format("Radio comms      : %s\n", tostring(self.radio))
  text=text..string.format("Radio frequency  : %s\n", tostring(self.frequency))
  text=text..string.format("Radio modulation : %s\n", tostring(self.frequency))
  text=text..string.format("******************************************************\n")
  env.info(RAT.id..text)
  
  -- Create submenus.
  if self.f10menu then
    self.Menu[self.SubMenuName]=MENU_MISSION:New(self.SubMenuName, RAT.MenuF10)
    self.Menu[self.SubMenuName]["groups"]=MENU_MISSION:New("Groups", self.Menu[self.SubMenuName])
    MENU_MISSION_COMMAND:New("Spawn new group", self.Menu[self.SubMenuName], self._SpawnWithRoute, self)
    MENU_MISSION_COMMAND:New("Delete markers", self.Menu[self.SubMenuName], self._DeleteMarkers, self)
    MENU_MISSION_COMMAND:New("Status report", self.Menu[self.SubMenuName], self.Status, self, true)
  end
  
  -- Schedule spawning of aircraft.
  local Tstart=self.spawndelay
  local dt=self.spawninterval
  -- Ensure that interval is >= 180 seconds if spawn at runway is chosen. Aircraft need time to takeoff or the runway gets jammed.
  if self.takeoff==RAT.wp.runway and not self.random_departure then
    dt=math.max(dt, 180)
  end
  local Tstop=Tstart+dt*(self.ngroups-1)
  SCHEDULER:New(nil, self._SpawnWithRoute, {self}, Tstart, dt, 0.0, Tstop)
  
  -- Status check and report scheduler.
  SCHEDULER:New(nil, self.Status, {self}, Tstart+1, self.statusinterval)
  
  -- Handle events.
  self:HandleEvent(EVENTS.Birth,          self._OnBirth)
  self:HandleEvent(EVENTS.EngineStartup,  self._EngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self._OnTakeoff)
  self:HandleEvent(EVENTS.Land,           self._OnLand)
  self:HandleEvent(EVENTS.EngineShutdown, self._OnEngineShutdown)
  self:HandleEvent(EVENTS.Dead,           self._OnDead)
  self:HandleEvent(EVENTS.Crash,          self._OnCrash)
  -- TODO: add hit event?
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the friendly coalitions from which the airports can be used as departure and destination.
-- @param #RAT self
-- @param #string friendly "same"=own coalition+neutral (default), "sameonly"=own coalition only, "neutral"=all neutral airports.
-- Default is "same", so aircraft will use airports of the coalition their spawn template has plus all neutral airports.
-- @usage yak:SetCoalition("neutral") will spawn aircraft randomly on all neutral airports.
-- @usage yak:SetCoalition("sameonly") will spawn aircraft randomly on airports belonging to the same coalition only as the template.
function RAT:SetCoalition(friendly)
  if friendly:lower()=="sameonly" then
    self.friendly=RAT.coal.sameonly
  elseif friendly:lower()=="neutral" then
    self.friendly=RAT.coal.neutral
  else
    self.friendly=RAT.coal.same
  end
end

--- Set coalition of RAT group. You can make red templates blue and vice versa.
-- @param #RAT self
-- @param #string color Color of coalition, i.e. "red" or blue".
function RAT:SetCoalitionAircraft(color)
  if color:lower()=="blue" then
    self.coalition=coalition.side.BLUE
    if not self.country then
      self.country=country.id.USA
    end
  elseif color:lower()=="red" then
    self.coalition=coalition.side.RED
    if not self.country then
      self.country=country.id.RUSSIA
    end
  elseif color:lower()=="neutral" then
    self.coalition=coalition.side.NEUTRAL
  end
end

--- Set country of RAT group. This overrules the coalition settings.
-- @param #RAT self
-- @param #number id DCS country enumerator ID. For example country.id.USA or country.id.RUSSIA.
function RAT:SetCountry(id)
  self.country=id
end

--- Set takeoff type. Starting cold at airport, starting hot at airport, starting at runway, starting in the air.
-- Default is "takeoff-coldorhot". So there is a 50% chance that the aircraft starts with cold engines and 50% that it starts with hot engines. 
-- @param #RAT self
-- @param #string type Type can be "takeoff-cold" or "cold", "takeoff-hot" or "hot", "takeoff-runway" or "runway", "air".
-- @usage RAT:Takeoff("hot") will spawn RAT objects at airports with engines started.
-- @usage RAT:Takeoff("cold") will spawn RAT objects at airports with engines off.
-- @usage RAT:Takeoff("air") will spawn RAT objects in air over random airports or within pre-defined zones. 
function RAT:SetTakeoff(type)
  
  local _Type
  if type:lower()=="takeoff-cold" or type:lower()=="cold" then
    _Type=RAT.wp.cold
  elseif type:lower()=="takeoff-hot" or type:lower()=="hot" then
    _Type=RAT.wp.hot
  elseif type:lower()=="takeoff-runway" or type:lower()=="runway" then    
    _Type=RAT.wp.runway
  elseif type:lower()=="air" then
    _Type=RAT.wp.air
  else
    _Type=RAT.wp.coldorhot
  end
  
  self.takeoff=_Type
end

--- Set possible departure ports. This can be an airport or a zone defined in the mission editor.
-- @param #RAT self
-- @param #string names Name or table of names of departure airports or zones.
-- @usage RAT:SetDeparture("Sochi-Adler") will spawn RAT objects at Sochi-Adler airport.
-- @usage RAT:SetDeparture({"Sochi-Adler", "Gudauta"}) will spawn RAT aircraft radomly at Sochi-Adler or Gudauta airport.
-- @usage RAT:SetDeparture({"Zone A", "Gudauta"}) will spawn RAT aircraft in air randomly within Zone A, which has to be defined in the mission editor, or within a zone around Gudauta airport. Note that this also requires RAT:takeoff("air") to be set.
function RAT:SetDeparture(names)

  -- Random departure is deactivated now that user specified departure ports.
  self.random_departure=false
  
  if type(names)=="table" then
  
    -- we did get a table of names
    for _,name in pairs(names) do
    
      if self:_AirportExists(name) then
        -- If an airport with this name exists, we put it in the ports array.
        table.insert(self.departure_ports, name)
      else
        -- If it is not an airport, we assume it is a zone.
        -- We need the DCS call to determine if it's really a zone. Otherwise code will crash at some point. 
        local z=trigger.misc.getZone(name)
        if z then
          table.insert(self.departure_zones, name)
        end
      end
      
    end
    
  elseif type(names)=="string" then

      if self:_AirportExists(names) then
        -- If an airport with this name exists, we put it in the ports array.
        table.insert(self.departure_ports, names)
      else
        -- If it is not an airport, we assume it is a zone.
        table.insert(self.departure_zones, names)
      end
  
  else
    -- error message
    env.error("Input parameter must be a string or a table!")
  end
  
end

--- Set name of destination airport for the AI aircraft. If no name is given an airport from the friendly coalition(s) is chosen randomly.
-- @param #RAT self
-- @param #string names Name of the destination airport or table of destination airports.
-- @usage RAT:SetDestination("Krymsk") makes all aircraft of this RAT oject fly to Krymsk airport.
function RAT:SetDestination(names)

  -- Random departure is deactivated now that user specified departure ports.
  self.random_destination=false
  
  if type(names)=="table" then
  
    for _,name in pairs(names) do
      if self:_AirportExists(name) then
        table.insert(self.destination_ports, name)
      else
        local text=string.format("Airport %s does not exist on map!", name)
        env.error(text)
      end
    end
  
  elseif type(names)=="string" then
  
    if self:_AirportExists(names) then
      self.destination_ports={names}
    else
      local text=string.format("Airport %s does not exist on map!", names)
      env.error(text)
    end
    
  else
    -- Error message.
    env.error("Input parameter must be a string or a table!")
  end

end

--- Set name of destination zones for the AI aircraft. If multiple names are given as a table, one zone is picked randomly as destination.
-- @param #RAT self
-- @param #string zonenames Name or table of names of zones defined in the mission editor or names of airports on the map.
function RAT:SetDestinationZone(zonenames)

  -- Random destination is deactivated now that user specified destination zone(s).
  self.random_destination=false
  -- Destination is a zone. Needs special care.
  self.destinationzone=true
  -- No ATC required.
  self.ATCswitch=false
  
  local names
  if type(zonenames)=="table" then
    names=zonenames
  elseif type(zonenames)=="string" then
    names={zonenames}
  else
    -- Error message.
    env.error("Input parameter must be a string or a table!")
  end
  
  for _,name in pairs(names) do
    if self:_AirportExists(name) then
      -- Take airport as zone.
      local airportzone=AIRBASE:FindByName(name):GetZone()
      table.insert(self.destination_zones, airportzone)
    else
      -- If it is not an airport, we assume it is a zone.
      -- We need the DCS call to determine if it's really a zone. Otherwise code will crash at some point. 
      local z=trigger.misc.getZone(name)
      if z then            
        table.insert(self.destination_zones, ZONE:New(name))
      end
    end
  end

end

--- Set name of "return" zones for the AI aircraft. If multiple names are given as a table, one zone is picked randomly as destination.
-- @param #RAT self
-- @param #string zonenames Name or table of names of zones defined in the mission editor.
function RAT:SetReturnZone(zonenames)

  -- Random destination is deactivated now that user specified destination zone(s).
  self.random_destination=false
  -- Destination is a zone. Needs special care.
  self.returnzone=true

--[[
  if type(names)=="table" then
  
    for _,name in pairs(names) do
      table.insert(self.destination_zones, ZONE:New(name))
    end
  
  elseif type(names)=="string" then
  
    table.insert(self.destination_zones, ZONE:New(names))
      
  else
    -- Error message.
    env.error("Input parameter must be a string or a table!")
  end
]]
  
  local names
  if type(zonenames)=="table" then
    names=zonenames
  elseif type(zonenames)=="string" then
    names={zonenames}
  else
    -- Error message.
    env.error("Input parameter must be a string or a table!")
  end
  
  for _,name in pairs(names) do
    if self:_AirportExists(name) then
      table.insert(self.destination_zones, AIRBASE:FindByName(name):GetZone())
    elseif self:_ZoneExists(name) then
      table.insert(self.destination_zones, ZONE:New(name))
    else
      env.error(RAT.id.."Specified airport or zone "..name.." does not exist in mission editor!")
    end
  end

end


--- Include all airports which lie in a zone as possible destinations.
-- @param #RAT self
-- @param Core.Zone#ZONE zone Zone in which the airports lie.
function RAT:SetDestinationsFromZone(zone)

  -- Random departure is deactivated now that user specified departure ports.
  self.random_destination=false
  
  self.destination_Azone=zone
end

--- Include all airports which lie in a zone as possible destinations.
-- @param #RAT self
-- @param Core.Zone#ZONE zone Zone in which the airports lie.
function RAT:SetDeparturesFromZone(zone)
  -- Random departure is deactivated now that user specified departure ports.
  self.random_departure=false

  self.departure_Azone=zone
end


--- Airports, FARPs and ships explicitly excluded as departures and destinations.
-- @param #RAT self
-- @param #string ports Name or table of names of excluded airports.
function RAT:ExcludedAirports(ports)
  if type(ports)=="string" then
    self.excluded_ports={ports}
  else
    self.excluded_ports=ports
  end
end

--- Set livery of aircraft. If more than one livery is specified in a table, the actually used one is chosen randomly from the selection.
-- @param #RAT self
-- @param #table skins Name of livery or table of names of liveries.
function RAT:Livery(skins)
  if type(skins)=="string" then
    self.livery={skins}
  else
    self.livery=skins
  end
end

--- Change aircraft type. This is a dirty hack which allows to change the aircraft type of the template group.
-- Note that all parameters like cruise speed, climb rate, range etc are still taken from the template group which likely leads to strange behaviour.
-- @param #RAT self
-- @param #string actype Type of aircraft which is spawned independent of the template group. Use with care and expect problems!
function RAT:ChangeAircraft(actype)
  self.actype=actype
end

--- Aircraft will continue their journey from their destination. This means they are respawned at their destination and get a new random destination.
-- @param #RAT self
-- @param #boolean switch Turn journey on=true or off=false. If no value is given switch=true.
function RAT:ContinueJourney(switch)
  switch=switch or true
  self.continuejourney=switch
end

--- Aircraft will commute between their departure and destination airports.
-- Note, this option is not available if aircraft are spawned in air since they don't have a valid departure airport to fly back to.
-- @param #RAT self
-- @param #boolean switch Turn commute on=true or off=false. If no value is given switch=true.
function RAT:Commute(switch)
  switch=switch or true
  self.commute=switch
end

--- Set the delay before first group is spawned. Minimum delay is 0.5 seconds.
-- @param #RAT self
-- @param #number delay Delay in seconds.
function RAT:SetSpawnDelay(delay)
  self.spawndelay=math.max(0.5, delay)
end

--- Set the interval between spawnings of the template group. Minimum interval is 0.5 seconds.
-- @param #RAT self
-- @param #number interval Interval in seconds.
function RAT:SetSpawnInterval(interval)
  self.spawninterval=math.max(0.5, interval)
end

--- Make aircraft respawn the moment they land rather than at engine shut down.
-- @param #RAT self
-- @param #number delay (Optional) Delay in seconds until respawn happens after landing. Default is 180 seconds.
function RAT:RespawnAfterLanding(delay)
  delay = delay or 180
  self.respawn_at_landing=true
  self.respawn_delay=delay
end

--- Aircraft will not get respawned when they finished their route.
-- @param #RAT self
function RAT:NoRespawn()
  self.norespawn=true
end

--- Aircraft will be respawned directly after take-off.
-- @param #RAT self
function RAT:RespawnAfterTakeoff()
  self.respawn_after_takeoff=true
end

--- Set parking id of aircraft.
-- @param #RAT self
-- @param #string id Parking ID of the aircraft.
function RAT:SetParkingID(id)
  self.parking_id=id
  env.info(RAT.id.."Setting parking ID to "..self.parking_id)
end

--- Enable Radio. Overrules the ME setting.
-- @param #RAT self
function RAT:RadioON()
  self.radio=true
end

--- Disable Radio. Overrules the ME setting.
-- @param #RAT self
function RAT:RadioOFF()
  self.radio=false
end

--- Set radio frequency.
-- @param #RAT self
-- @param #number frequency Radio frequency.
function RAT:RadioFrequency(frequency)
  self.frequency=frequency
end

--- Set radio modulation. Default is AM.
-- @param #RAT self
-- @param #string modulation Either "FM" or "AM". If no value is given, modulation is set to AM.
function RAT:RadioFrequency(modulation)
  if modulation=="AM" then
    self.modulation=radio.modulation.AM
  elseif modulation=="FM" then
    self.modulation=radio.modulation.FM
  else
    self.modulation=radio.modulation.AM
  end
end

--- Set the time after which inactive groups will be destroyed. Default is 300 seconds.
-- @param #RAT self
-- @param #number time Time in seconds.
function RAT:TimeDestroyInactive(time)
  self.Tinactive=time
end

--- Set the maximum cruise speed of the aircraft.
-- @param #RAT self
-- @param #number speed Speed in km/h.
function RAT:SetMaxCruiseSpeed(speed)
  -- Convert to m/s.
  self.Vcruisemax=speed/3.6
end

--- Set the climb rate. Default is 1500 ft/min. This automatically sets the climb angle.
-- @param #RAT self
-- @param #number rate Climb rate in ft/min.
function RAT:SetClimbRate(rate)
  self.Vclimb=rate or 1500
end

--- Set the angle of descent. Default is 3.6 degrees, which corresponds to 3000 ft descent after one mile of travel.
-- @param #RAT self
-- @param #number angle Angle of descent in degrees.
function RAT:SetDescentAngle(angle)
  self.AlphaDescent=angle
end

--- Set rules of engagement (ROE). Default is weapon hold. This is a peaceful class.
-- @param #RAT self
-- @param #string roe "hold" = weapon hold, "return" = return fire, "free" = weapons free.
function RAT:SetROE(roe)
  if roe=="return" then 
    self.roe=RAT.ROE.returnfire
  elseif roe=="free" then
    self.roe=RAT.ROE.weaponfree
  else
    self.roe=RAT.ROE.weaponhold
  end
end

--- Set reaction to threat (ROT). Default is no reaction, i.e. aircraft will simply ignore all enemies.
-- @param #RAT self
-- @param #string rot "noreaction" = no reaction to threats, "passive" = passive defence, "evade" = evade enemy attacks.
function RAT:SetROT(rot)
  if rot=="passive" then
    self.rot=RAT.ROT.passive
  elseif rot=="evade" then
    self.rot=RAT.ROT.evade
  else
    self.rot=RAT.ROT.noreaction
  end
end

--- Set the name of the F10 submenu. Default is the name of the template group.
-- @param #RAT self
-- @param #string name Submenu name.
function RAT:MenuName(name)
  self.SubMenuName=tostring(name)
end

--- Enable ATC, which manages the landing queue for RAT aircraft if they arrive simultaniously at the same airport.
-- @param #RAT self
-- @param #boolean switch true=enable ATC, false=disable ATC. 
function RAT:EnableATC(switch)
  self.ATCswitch=switch or true
end

--- Max number of planes that get landing clearance of the RAT ATC. This setting effects all RAT objects and groups! 
-- @param #RAT self
-- @param #number n Number of aircraft that are allowed to land simultaniously. Default is 1.
function RAT:ATC_Clearance(n)
  RAT.ATC.Nclearance=n or 1
end

--- Delay between granting landing clearance for simultanious landings. This setting effects all RAT objects and groups! 
-- @param #RAT self
-- @param #number time Delay time when the next aircraft will get landing clearance event if the previous one did not land yet. Default is  240 sec.
function RAT:ATC_Delay(time)
  RAT.ATC.delay=time or 240
end

--- Set minimum distance between departure and destination. Default is 5 km.
-- Minimum distance should not be smaller than maybe ~500 meters to ensure that departure and destination are different.
-- @param #RAT self
-- @param #number dist Distance in km.
function RAT:SetMinDistance(dist)
  -- Distance in meters. Absolute minimum is 500 m.
  self.mindist=math.max(500, dist*1000)
end

--- Set maximum distance between departure and destination. Default is 5000 km but aircarft range is also taken into account automatically.
-- @param #RAT self
-- @param #number dist Distance in km.
function RAT:SetMaxDistance(dist)
  -- Distance in meters.
  self.maxdist=dist*1000
end

--- Turn debug messages on or off. Default is off.
-- @param #RAT self
-- @param #boolean switch true turn messages on, false=off.
function RAT:_Debug(switch)
  switch = switch or true
  self.debug=switch
end

--- Aircraft report status messages. Default is off.
-- @param #RAT self
-- @param #boolean switch true=on, false=off.
function RAT:StatusReports(switch)
  self.reportstatus=switch or true
end

--- Place markers of waypoints on the F10 map. Default is off.
-- @param #RAT self
-- @param #boolean switch true=yes, false=no.
function RAT:PlaceMarkers(switch)
  switch = switch or true
  self.placemarkers=switch
end

--- Set flight level. Setting this value will overrule all other logic. Aircraft will try to fly at this height regardless.
-- @param #RAT self
-- @param #number height FL in hundrets of feet. E.g. FL200 = 20000 ft ASL.
function RAT:SetFL(height)
  self.FLuser=height*RAT.unit.FL2m
end

--- Set max flight level. Setting this value will overrule all other logic. Aircraft will try to fly at less than this FL regardless.
-- @param #RAT self
-- @param #number height Maximum FL in hundrets of feet.
function RAT:SetFLmax(height)
  self.FLmaxuser=height*RAT.unit.FL2m
end

--- Set max cruising altitude above sea level.
-- @param #RAT self
-- @param #number alt Altitude ASL in meters.
function RAT:SetMaxCruiseAltitude(alt)
  self.FLmaxuser=alt
end

--- Set min flight level. Setting this value will overrule all other logic. Aircraft will try to fly at higher than this FL regardless.
-- @param #RAT self
-- @param #number height Maximum FL in hundrets of feet.
function RAT:SetFLmin(height)
  self.FLminuser=height*RAT.unit.FL2m
end

--- Set min cruising altitude above sea level.
-- @param #RAT self
-- @param #number alt Altitude ASL in meters.
function RAT:SetMinCruiseAltitude(alt)
  self.FLminuser=alt
end

--- Set flight level of cruising part. This is still be checked for consitancy with selected route and prone to radomization.
-- Default is FL200 for planes and FL005 for helicopters.
-- @param #RAT self
-- @param #number height FL in hundrets of feet. E.g. FL200 = 20000 ft ASL.
function RAT:SetFLcruise(height)
  self.aircraft.FLcruise=height*RAT.unit.FL2m
end

--- Set cruising altitude. This is still be checked for consitancy with selected route and prone to radomization.
-- @param #RAT self
-- @param #number alt Cruising altitude ASL in meters.
function RAT:SetCruiseAltitude(alt)
  self.aircraft.FLcruise=alt
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Initialize basic parameters of the aircraft based on its (template) group in the mission editor.
-- @param #RAT self
-- @param Dcs.DCSWrapper.Group#Group DCSgroup Group of the aircraft in the mission editor.
function RAT:_InitAircraft(DCSgroup)

  local DCSunit=DCSgroup:getUnit(1)
  local DCSdesc=DCSunit:getDesc()
  local DCScategory=DCSgroup:getCategory()
  local DCStype=DCSunit:getTypeName()
 
  -- Descriptors table of unit.
  if self.debug then
    self:E({"DCSdesc", DCSdesc})
  end
  
  -- set category
  if DCScategory==Group.Category.AIRPLANE then
    self.category=RAT.cat.plane
  elseif DCScategory==Group.Category.HELICOPTER then
    self.category=RAT.cat.heli
  else
    self.category="other"
    env.error(RAT.id.."Group of RAT is neither airplane nor helicopter!")
  end
  
  -- Get type of aircraft.
  self.aircraft.type=DCStype
  
  -- inital fuel in %
  self.aircraft.fuel=DCSunit:getFuel()

  -- operational range in NM converted to m
  self.aircraft.Rmax = DCSdesc.range*RAT.unit.nm2m
  
  -- effective range taking fuel into accound and a 10% reserve
  self.aircraft.Reff = self.aircraft.Rmax*self.aircraft.fuel*0.9
  
  -- max airspeed from group
  self.aircraft.Vmax = DCSdesc.speedMax
      
  -- max climb speed in m/s
  self.aircraft.Vymax=DCSdesc.VyMax
    
  -- service ceiling in meters
  self.aircraft.ceiling=DCSdesc.Hmax
  
      -- Default flight level (ASL).
  if self.category==RAT.cat.plane then
    -- For planes: FL200 = 20000 ft = 6096 m.
    self.aircraft.FLcruise=200*RAT.unit.FL2m
  else
    -- For helos: FL005 = 500 ft = 152 m.
    self.aircraft.FLcruise=005*RAT.unit.FL2m
  end
  
  -- info message
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Aircraft parameters:\n")
  text=text..string.format("Template group  =  %s\n",       self.SpawnTemplatePrefix)
  text=text..string.format("Alias           =  %s\n",       self.alias)
  text=text..string.format("Category        =  %s\n",       self.category)
  text=text..string.format("Type            =  %s\n",       self.aircraft.type)
  text=text..string.format("Max air speed   = %6.1f m/s\n", self.aircraft.Vmax)
  text=text..string.format("Max climb speed = %6.1f m/s\n", self.aircraft.Vymax)
  text=text..string.format("Initial Fuel    = %6.1f\n",     self.aircraft.fuel*100)
  text=text..string.format("Max range       = %6.1f km\n",  self.aircraft.Rmax/1000)
  text=text..string.format("Eff range       = %6.1f km\n",  self.aircraft.Reff/1000)
  text=text..string.format("Ceiling         = %6.1f km = FL%3.0f\n", self.aircraft.ceiling/1000, self.aircraft.ceiling/RAT.unit.FL2m)
  text=text..string.format("FL cruise       = %6.1f km = FL%3.0f\n", self.aircraft.FLcruise/1000, self.aircraft.FLcruise/RAT.unit.FL2m)
  text=text..string.format("******************************************************\n")
  env.info(RAT.id..text)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Spawn the AI aircraft with a route.
-- Sets the departure and destination airports and waypoints.
-- Modifies the spawn template.
-- Sets ROE/ROT.
-- Initializes the ratcraft array and group menu.
-- @param #RAT self
-- @param #string _departure (Optional) Name of departure airbase.
-- @param #string _destination (Optional) Name of destination airbase.
-- @param #number _takeoff Takeoff type id.
function RAT:_SpawnWithRoute(_departure, _destination, _takeoff)

  -- Set takeoff type.
  local takeoff=self.takeoff
  if self.takeoff==RAT.wp.coldorhot then
    local temp={RAT.wp.cold, RAT.wp.hot}
    takeoff=temp[math.random(2)]
  end
  if _takeoff then
    takeoff=_takeoff
  end

  -- Set flight plan.
  local departure, destination, waypoints = self:_SetRoute(takeoff, _departure, _destination)
  
  -- Return nil if we could not find a departure destination or waypoints
  if not (departure and destination and waypoints) then
    return nil
  end
  
  -- Modify the spawn template to follow the flight plan.
  self:_ModifySpawnTemplate(waypoints)
  
  -- Actually spawn the group.
  local group=self:SpawnWithIndex(self.SpawnIndex) -- Wrapper.Group#GROUP
  self.alive=self.alive+1
  
  -- ATC is monitoring this flight.
  if self.ATCswitch then
    RAT:_ATCAddFlight(group:GetName(), destination:GetName())
  end
  
  -- Set ROE, default is "weapon hold".
  self:_SetROE(group, self.roe)
  
  -- Set ROT, default is "no reaction".
  self:_SetROT(group, self.rot)

  -- Init ratcraft array.  
  self.ratcraft[self.SpawnIndex]={}
  self.ratcraft[self.SpawnIndex]["group"]=group
  self.ratcraft[self.SpawnIndex]["destination"]=destination
  self.ratcraft[self.SpawnIndex]["departure"]=departure
  self.ratcraft[self.SpawnIndex]["waypoints"]=waypoints
  self.ratcraft[self.SpawnIndex]["status"]="spawned"
  self.ratcraft[self.SpawnIndex]["airborne"]=group:InAir()
  -- Time and position on ground. For check if aircraft is stuck somewhere.
  if group:InAir() then
    self.ratcraft[self.SpawnIndex]["Tground"]=nil
    self.ratcraft[self.SpawnIndex]["Pground"]=nil
    self.ratcraft[self.SpawnIndex]["Tlastcheck"]=nil
  else
    self.ratcraft[self.SpawnIndex]["Tground"]=timer.getTime()
    self.ratcraft[self.SpawnIndex]["Pground"]=group:GetCoordinate()
    self.ratcraft[self.SpawnIndex]["Tlastcheck"]=timer.getTime()
  end
  -- Initial and current position. For calculating the travelled distance.
  self.ratcraft[self.SpawnIndex]["P0"]=group:GetCoordinate()
  self.ratcraft[self.SpawnIndex]["Pnow"]=group:GetCoordinate()
  self.ratcraft[self.SpawnIndex]["Distance"]=0
  
  -- Each aircraft gets its own takeoff type. unused?
  self.ratcraft[self.SpawnIndex]["takeoff"]=_takeoff
  self.ratcraft[self.SpawnIndex].despawnme=false

  
  -- Create submenu for this group.
  if self.f10menu then
    local name=self.aircraft.type.." ID "..tostring(self.SpawnIndex)
    -- F10/RAT/<templatename>/Group X
    self.Menu[self.SubMenuName].groups[self.SpawnIndex]=MENU_MISSION:New(name, self.Menu[self.SubMenuName].groups)
    -- F10/RAT/<templatename>/Group X/Set ROE
    self.Menu[self.SubMenuName].groups[self.SpawnIndex]["roe"]=MENU_MISSION:New("Set ROE", self.Menu[self.SubMenuName].groups[self.SpawnIndex])
    MENU_MISSION_COMMAND:New("Weapons hold", self.Menu[self.SubMenuName].groups[self.SpawnIndex]["roe"], self._SetROE, self, group, RAT.ROE.weaponhold)
    MENU_MISSION_COMMAND:New("Weapons free", self.Menu[self.SubMenuName].groups[self.SpawnIndex]["roe"], self._SetROE, self, group, RAT.ROE.weaponfree)
    MENU_MISSION_COMMAND:New("Return fire",  self.Menu[self.SubMenuName].groups[self.SpawnIndex]["roe"], self._SetROE, self, group, RAT.ROE.returnfire)
    -- F10/RAT/<templatename>/Group X/Set ROT
    self.Menu[self.SubMenuName].groups[self.SpawnIndex]["rot"]=MENU_MISSION:New("Set ROT", self.Menu[self.SubMenuName].groups[self.SpawnIndex])
    MENU_MISSION_COMMAND:New("No reaction",     self.Menu[self.SubMenuName].groups[self.SpawnIndex]["rot"], self._SetROT, self, group, RAT.ROT.noreaction)
    MENU_MISSION_COMMAND:New("Passive defense", self.Menu[self.SubMenuName].groups[self.SpawnIndex]["rot"], self._SetROT, self, group, RAT.ROT.passive)
    MENU_MISSION_COMMAND:New("Evade on fire",   self.Menu[self.SubMenuName].groups[self.SpawnIndex]["rot"], self._SetROT, self, group, RAT.ROT.evade)    
    -- F10/RAT/<templatename>/Group X/
    MENU_MISSION_COMMAND:New("Despawn group",  self.Menu[self.SubMenuName].groups[self.SpawnIndex], self._Despawn, self, group)
    MENU_MISSION_COMMAND:New("Place markers",  self.Menu[self.SubMenuName].groups[self.SpawnIndex], self._PlaceMarkers, self, waypoints)
    MENU_MISSION_COMMAND:New("Status report",  self.Menu[self.SubMenuName].groups[self.SpawnIndex], self.Status, self, true, self.SpawnIndex)
  end
  
  return self.SpawnIndex
  
end


--- Clear flight for landing. Sets tigger value to 1.
-- @param #RAT self
-- @param #string name Name of flight to be cleared for landing.
function RAT:ClearForLanding(name)
  trigger.action.setUserFlag(name, 1)
  local flagvalue=trigger.misc.getUserFlag(name)
  env.info(RAT.id.."ATC: User flag value (landing) for "..name.." set to "..flagvalue)
end

--- Respawn a group.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group to be repawned.
function RAT:_Respawn(group)
  
  -- Get the spawn index from group
  local index=self:GetSpawnIndexFromGroup(group)
  
  -- Get departure and destination from previous journey.
  local departure=self.ratcraft[index].departure
  local destination=self.ratcraft[index].destination
  
  local _departure=nil
  local _destination=nil
  local _takeoff=nil
 
  if self.continuejourney then
    -- We continue our journey from the old departure airport.
    _departure=destination:GetName()
    if self.destinationzone then
      _takeoff=RAT.wp.air
    end
  elseif self.commute then
    -- We commute between departure and destination.
    _departure=destination:GetName()
    _destination=departure:GetName()
  end
    
  -- Spawn new group.
  if self.respawn_delay then
    SCHEDULER:New(nil, self._SpawnWithRoute, {self, _departure, _destination, _takeoff}, self.respawn_delay)
  else
    self:_SpawnWithRoute(_departure, _destination, _takeoff)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the route of the AI plane. Due to DCS landing bug, this has to be done before the unit is spawned.
-- @param #RAT self
-- @param takeoff #RAT.wp Takeoff type.
-- @param Wrapper.Airport#AIRBASE _departure (Optional) Departure airbase.
-- @param Wrapper.Airport#AIRBASE _destination (Optional) Destination airbase.
-- @return Wrapper.Airport#AIRBASE Departure airbase.
-- @return Wrapper.Airport#AIRBASE Destination airbase.
-- @return #table Table of flight plan waypoints.
-- @return #nil If no valid departure or destination airport could be found.
function RAT:_SetRoute(takeoff, _departure, _destination)
    
  -- Max cruise speed.
  local VxCruiseMax
  if self.Vcruisemax then
    -- User input.
    VxCruiseMax = min(self.Vcruisemax, self.aircraft.Vmax)
  else
    -- Max cruise speed 90% of Vmax or 900 km/h whichever is lower.
    VxCruiseMax = math.min(self.aircraft.Vmax*0.90, 250)
  end
  
  -- Min cruise speed 70% of max cruise or 600 km/h whichever is lower.
  local VxCruiseMin = math.min(VxCruiseMax*0.70, 166)
  
  -- Cruise speed (randomized). Expectation value at midpoint between min and max.
  local VxCruise = self:_Random_Gaussian((VxCruiseMax-VxCruiseMin)/2+VxCruiseMin, (VxCruiseMax-VxCruiseMax)/4, VxCruiseMin, VxCruiseMax)
  
  -- Climb speed 90% ov Vmax but max 720 km/h.
  local VxClimb = math.min(self.aircraft.Vmax*0.90, 200)
  
  -- Descent speed 60% of Vmax but max 500 km/h.
  local VxDescent = math.min(self.aircraft.Vmax*0.60, 140)
  
  -- Holding speed is 90% of descent speed.
  local VxHolding = VxDescent*0.9
  
  -- Final leg is 90% of holding speed.
  local VxFinal = VxHolding*0.9
  
  -- Reasonably civil climb speed Vy=1500 ft/min = 7.6 m/s but max aircraft specific climb rate.
  local VyClimb=math.min(self.Vclimb*RAT.unit.ft2meter/60, self.aircraft.Vymax)
  
  -- Climb angle in rad.
  local AlphaClimb=math.asin(VyClimb/VxClimb)
  
  -- Descent angle in rad.
  local AlphaDescent=math.rad(self.AlphaDescent)
  
  local returnzone=self.returnzone
  local destinationzone=self.destinationzone
  
  
  -- DEPARTURE AIRPORT  
  -- Departure airport or zone.
  local departure=nil
  if _departure then
  
    if self:_AirportExists(_departure) then
      -- Check if new departure is an airport.
      departure=AIRBASE:FindByName(_departure)
    elseif self:_ZoneExists(_departure) then
      -- If it's not an airport, check whether it's a zone.
      departure=ZONE:New(_departure)
    else
      local text=string.format("ERROR: Specified departure airport %s does not exist for %s!", _departure, self.alias)
      env.error(RAT.id..text)
    end
    
    if self.commute then
      if returnzone then
        -- should not be a problem because we flew back to the departure. Departure=destination ==> nothing really changes.
        -- Just that the next departure is not random but the same airport we started first.
      elseif destinationzone then
        -- We initially flew to a zone.
        if self.takeoff==RAT.wp.air then
          -- We initially came from a zone, i.e. airstart.
          if takeoff==RAT.wp.air then
            -- Now we also fly to zone.
          else
            -- Now we fly to an airport where we land
          end
        else
          -- We initally 
        end  
      end
    elseif self.continuejourney then
    
      departure=departure:GetZone()
    end
    
    
  else
    departure=self:_PickDeparture(takeoff)
  end
   
  -- Return nil if no departure could be found.
  if not departure then
    local text=string.format("No valid departure airport could be found for %s.", self.alias)
    MESSAGE:New(text, 60):ToAll()
    env.error(RAT.id..text)
    return nil
  end

  -- Coordinates of departure point.
  local Pdeparture
  if takeoff==RAT.wp.air then
    -- For an air start, we take a random point within the spawn zone.
    local vec2=departure:GetRandomVec2()
    Pdeparture=COORDINATE:NewFromVec2(vec2) 
  else
    Pdeparture=departure:GetCoordinate()
  end
  
  -- Height ASL of departure point.
  local H_departure
  if takeoff==RAT.wp.air then
    -- Departure altitude is 70% of default cruise with 30% variation and limited to 1000 m AGL (50 m for helos). 
    local Hmin
    if self.category==RAT.cat.plane then
      Hmin=1000
    else
      Hmin=50
    end
    H_departure=self:_Randomize(self.aircraft.FLcruise*0.7, 0.3, Pdeparture.y+Hmin, self.aircraft.FLcruise)
  else
    H_departure=Pdeparture.y
  end
  
  -- Adjust min distance between departure and destination for user set min flight level.
  if self.FLminuser then
    self.mindist=self:_MinDistance(AlphaClimb, AlphaDescent, self.FLminuser-H_departure)
    local text=string.format("Adjusting min distance to %d km (for given min FL%03d)", self.mindist/1000, self.FLminuser/RAT.unit.FL2m)
    env.info(RAT.id..text)
  end
  
  -- DESTINATION AIRPORT
  local destination=nil
  if _destination then
  
    if self:_AirportExists(_destination) then
      destination=AIRBASE:FindByName(_destination)
      if self.destinationzone then
        destination=destination:GetZone()
      end
    elseif self:_ZoneExists(_destination) then
      destination=ZONE:New(_destination)
      if not self.returnzone then
        self.destinationzone=true
      end
    else
      local text=string.format("ERROR: Specified destination airport/zone %s does not exist for %s!", _destination, self.alias)
      env.error(RAT.id..text)
    end
    
  else

    -- This handes the case where we have a journey and the first flight is done, i.e. _departure is set.
    -- If a user specified more than two destination airport explicitly, then we will stick to this.
    -- Otherwise, the route is random from now on.
    if self.continuejourney and _departure and #self.destination_ports<3 then
      self.random_destination=true
    end
  
    -- Get all destination airports within reach.
    local destinations=self:_GetDestinations(departure, Pdeparture, self.mindist, math.min(self.aircraft.Reff, self.maxdist))
    
    -- Pick a destination airport.
    destination=self:_PickDestination(destinations)
  end
    
  -- Return nil if no departure could be found.
  if not destination then
    local text=string.format("No valid destination airport could be found for %s!", self.alias)
    MESSAGE:New(text, 60):ToAll()
    env.error(RAT.id..text)
    return nil
  end
  
  -- Check that departure and destination are not the same. Should not happen due to mindist.
  if destination:GetName()==departure:GetName() then
    local text=string.format("%s: Destination and departure airport are identical. Airport %s.", self.alias, destination:GetName())
    MESSAGE:New(text, 30):ToAll()
    env.error(RAT.id..text)
  end
  
  -- Coordinates of destination airport.
  local Pdestination
  local Preturn
  if self.destinationzone then
    -- Destination is a zone and we pick a random point within the zone.
    local vec2=destination:GetRandomVec2()
    Pdestination=COORDINATE:NewFromVec2(vec2)
  elseif self.returnzone then
    -- We fly to a random point within a zone and back to the departure airport.
    Pdestination=departure:GetCoordinate()
    local vec2=destination:GetRandomVec2()
    Preturn=COORDINATE:NewFromVec2(vec2)
    destination=departure
  else 
    Pdestination=destination:GetCoordinate()
  end
  -- Height ASL of destination airport.
  local H_destination=Pdestination.y
    
  -- DESCENT/HOLDING POINT
  -- Get a random point between 5 and 10 km away from the destination.
  local Rhmin=5000
  local Rhmax=10000
  if self.category==RAT.cat.heli then
    -- For helos we set a distance between 500 to 1000 m.
    Rhmin=500
    Rhmax=1000
  end
  
  -- Coordinates of the holding point. y is the land height at that point.
  local Vholding=Pdestination:GetRandomVec2InRadius(Rhmax, Rhmin)
  local Pholding=COORDINATE:NewFromVec2(Vholding)
  
  -- AGL height of holding point.
  local H_holding=Pholding.y
  
  -- Holding point altitude. For planes between 1600 and 2400 m AGL. For helos 160 to 240 m AGL.
  local h_holding
  if self.category==RAT.cat.plane then
    h_holding=1200
  else
    h_holding=150
  end
  h_holding=self:_Randomize(h_holding, 0.2)
    
  -- Distance from holding point to final destination.
  local d_holding=Pholding:Get2DDistance(Pdestination)
  
  -- GENERAL
  local heading
  local d_total
  if self.returnzone then
  
    -- Heading from departure to destination in return zone.
    heading=self:_Course(Pdeparture, Preturn)
  
    -- Total distance to return zone and back.
    d_total=Pdeparture:Get2DDistance(Preturn) + Preturn:Get2DDistance(Pholding)
      
  else
    -- Heading from departure to holding point of destination.
    heading=self:_Course(Pdeparture, Pholding)
  
    -- Total distance between departure and holding point near destination.
    d_total=Pdeparture:Get2DDistance(Pholding)
  end
  
  -- max height if we only would descent to holding point for the given distance
  -- TODO: Add case for destination zone. We could allow a higher max because no descent is necessary. 
  if takeoff==RAT.wp.air then
    local H_departure_max
    if self.destinationzone then
      H_departure_max = H_departure
    else
      H_departure_max = d_total * math.tan(AlphaDescent) + H_holding + h_holding
    end
    H_departure=math.min(H_departure, H_departure_max)
  end
  
  --------------------------------------------
  
  -- Height difference between departure and destination.
  local deltaH=math.abs(H_departure-h_holding-H_holding)
  
  -- Slope between departure and destination.
  local phi = math.atan(deltaH/d_total)
  
  -- Adjusted climb/descent angles.
  local phi_climb
  local phi_descent
  if (H_departure > H_holding+h_holding) then
    phi_climb=AlphaClimb+phi
    phi_descent=AlphaDescent-phi
  else
    phi_climb=AlphaClimb-phi
    phi_descent=AlphaDescent+phi
  end

  -- Total distance including slope.
  local D_total
  if self.returnzone then
    D_total = math.sqrt(deltaH*deltaH+d_total/2*d_total/2)
  else
    D_total = math.sqrt(deltaH*deltaH+d_total*d_total)
  end
  
  -- SSA triangle for sloped case.
  local gamma=math.rad(180)-phi_climb-phi_descent
  local a = D_total*math.sin(phi_climb)/math.sin(gamma)
  local b = D_total*math.sin(phi_descent)/math.sin(gamma)
  local hphi_max  = b*math.sin(phi_climb)
  local hphi_max2 = a*math.sin(phi_descent)
  
  -- Height of triangle.
  local h_max1 = b*math.sin(AlphaClimb)
  local h_max2 = a*math.sin(AlphaDescent)
  
  -- Max height relative to departure or destination.
  local h_max
  if (H_departure > H_holding+h_holding) then
    h_max=math.min(h_max1, h_max2)
  else
    h_max=math.max(h_max1, h_max2)
  end
  
  -- Max flight level aircraft can reach for given angles and distance.
  local FLmax = h_max+H_departure
    
  -- Max heights and distances if we would travel at FLmax.
  local h_climb_max   = FLmax-H_departure
  local h_descent_max = FLmax - (H_holding+h_holding)  
  local d_climb_max   = h_climb_max/math.tan(AlphaClimb) 
  local d_descent_max = h_descent_max/math.tan(AlphaDescent)
  local d_cruise_max  = d_total-d_climb_max-d_descent_max
  local d_total_max   = d_climb_max + d_cruise_max + d_descent_max
  
  --CRUISE  
  -- Min cruise alt is just above holding point at destination or departure height, whatever is larger.
  local FLmin=math.max(H_departure, H_holding+h_holding)
  
  -- If the route is very short we set FLmin a bit lower than FLmax.
  if FLmin>FLmax then
    FLmin=FLmax*0.75
  end
    
  -- For helicopters we take cruise alt between 50 to 1000 meters above ground. Default cruise alt is ~150 m.
  if self.category==RAT.cat.heli then  
    FLmin=math.max(H_departure, H_destination)+50
    FLmax=math.max(H_departure, H_destination)+1000
  end
  
  -- Ensure that FLmax not above 95% its service ceiling.
  FLmax=math.min(FLmax, self.aircraft.ceiling*0.95)
  
  -- Overrule setting if user specified min/max flight level explicitly.
  if self.FLminuser then
    FLmin=self.FLminuser
  end
  if self.FLmaxuser then
    FLmax=self.FLmaxuser
  end
  
  -- Adjust FLcruise to be at leat FLmin and at most FLmax
  if self.aircraft.FLcruise<FLmin then
    self.aircraft.FLcruise=FLmin
  end
  if self.aircraft.FLcruise>FLmax then
    self.aircraft.FLcruise=FLmax
  end
    
  -- Set cruise altitude. Selected from Gaussian distribution but limited to FLmin and FLmax.
  local FLcruise=self:_Random_Gaussian(self.aircraft.FLcruise, (FLmax-FLmin)/4, FLmin, FLmax)
    
  -- Overrule setting if user specified a flight level explicitly.
  if self.FLuser then
    FLcruise=self.FLuser
  end

  -- Climb and descent heights.
  local h_climb   = FLcruise - H_departure
  local h_descent = FLcruise - (H_holding+h_holding)
  
  -- Distances.
  local d_climb   = h_climb/math.tan(AlphaClimb)
  local d_descent = h_descent/math.tan(AlphaDescent)
  local d_cruise  = d_total-d_climb-d_descent
  local d_total_cruise = d_climb + d_cruise + d_descent
  --------------------------------------------
  
  -- debug message
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Template      =  %s\n",   self.SpawnTemplatePrefix)
  text=text..string.format("Alias         =  %s\n",   self.alias)
  text=text..string.format("Group name    =  %s\n\n", self:_AnticipatedGroupName())
  text=text..string.format("Speeds:\n")
  text=text..string.format("VxCruiseMin   = %6.1f m/s = %5.1f km/h\n", VxCruiseMin, VxCruiseMin*3.6)
  text=text..string.format("VxCruiseMax   = %6.1f m/s = %5.1f km/h\n", VxCruiseMax, VxCruiseMax*3.6)
  text=text..string.format("VxCruise      = %6.1f m/s = %5.1f km/h\n", VxCruise, VxCruise*3.6)
  text=text..string.format("VxClimb       = %6.1f m/s = %5.1f km/h\n", VxClimb, VxClimb*3.6)
  text=text..string.format("VxDescent     = %6.1f m/s = %5.1f km/h\n", VxDescent, VxDescent*3.6)
  text=text..string.format("VxHolding     = %6.1f m/s = %5.1f km/h\n", VxHolding, VxHolding*3.6)
  text=text..string.format("VxFinal       = %6.1f m/s = %5.1f km/h\n", VxFinal, VxFinal*3.6)
  text=text..string.format("VyClimb       = %6.1f m/s\n", VyClimb)
  text=text..string.format("\nDistances:\n")
  text=text..string.format("d_climb       = %6.1f km\n", d_climb/1000)
  text=text..string.format("d_cruise      = %6.1f km\n", d_cruise/1000)
  text=text..string.format("d_descent     = %6.1f km\n", d_descent/1000)
  text=text..string.format("d_holding     = %6.1f km\n", d_holding/1000)
  text=text..string.format("d_total       = %6.1f km\n", d_total/1000)
  text=text..string.format("\nHeights:\n")
  text=text..string.format("H_departure   = %6.1f m ASL\n", H_departure)
  text=text..string.format("H_destination = %6.1f m ASL\n", H_destination)
  text=text..string.format("H_holding     = %6.1f m ASL\n", H_holding)
  text=text..string.format("h_climb       = %6.1f m\n",     h_climb)
  text=text..string.format("h_descent     = %6.1f m\n",     h_descent)
  text=text..string.format("h_holding     = %6.1f m\n",     h_holding)
  text=text..string.format("delta H       = %6.1f m\n",     deltaH)
  text=text..string.format("FLmin         = %6.1f m ASL = FL%03d\n", FLmin, FLmin/RAT.unit.FL2m)
  text=text..string.format("FLcruise      = %6.1f m ASL = FL%03d\n", FLcruise, FLcruise/RAT.unit.FL2m)
  text=text..string.format("FLmax         = %6.1f m ASL = FL%03d\n", FLmax, FLmax/RAT.unit.FL2m)
  text=text..string.format("\nAngles:\n")  
  text=text..string.format("Alpha climb   = %6.2f Deg\n",   math.deg(AlphaClimb))
  text=text..string.format("Alpha descent = %6.2f Deg\n",   math.deg(AlphaDescent))
  text=text..string.format("Phi (slope)   = %6.2f Deg\n",   math.deg(phi))
  text=text..string.format("Phi climb     = %6.2f Deg\n",   math.deg(phi_climb))
  text=text..string.format("Phi descent   = %6.2f Deg\n",   math.deg(phi_descent))
  if self.debug then
    text=text..string.format("Heading       = %6.1f Deg\n",   heading)
    text=text..string.format("\nSSA triangle:\n")
    text=text..string.format("D_total       = %6.1f km\n",  D_total/1000)
    text=text..string.format("gamma         = %6.1f Deg\n", math.deg(gamma))
    text=text..string.format("a             = %6.1f m\n",   a)
    text=text..string.format("b             = %6.1f m\n",   b)
    text=text..string.format("hphi_max      = %6.1f m\n",   hphi_max)
    text=text..string.format("hphi_max2     = %6.1f m\n",   hphi_max2)
    text=text..string.format("h_max1        = %6.1f m\n",   h_max1)
    text=text..string.format("h_max2        = %6.1f m\n",   h_max2)
    text=text..string.format("h_max         = %6.1f m\n",   h_max)
    text=text..string.format("\nMax heights and distances:\n")
    text=text..string.format("d_climb_max   = %6.1f km\n", d_climb_max/1000)
    text=text..string.format("d_cruise_max  = %6.1f km\n", d_cruise_max/1000)
    text=text..string.format("d_descent_max = %6.1f km\n", d_descent_max/1000)
    text=text..string.format("d_total_max   = %6.1f km\n", d_total_max/1000)
    text=text..string.format("h_climb_max   = %6.1f m\n",  h_climb_max)
    text=text..string.format("h_descent_max = %6.1f m\n",  h_descent_max)
  end
  text=text..string.format("******************************************************\n")
  env.info(RAT.id..text)
  
  -- Ensure that cruise distance is positve. Can be slightly negative in special cases. And we don't want to turn back.
  if d_cruise<0 then
    d_cruise=100
  end

  -- Waypoints and coordinates
  local wp={}
  local c={}
  
  -- Departure/Take-off
  c[#c+1]=Pdeparture
  wp[#wp+1]=self:_Waypoint(#wp+1, takeoff, c[#wp+1], VxClimb, H_departure, departure)
  self.waypointdescriptions[#wp]="Departure"
  self.waypointstatus[#wp]=RAT.status.Departure
  
  -- Climb
  if takeoff==RAT.wp.air then
  
    -- Air start.
    if d_climb < 1000 or d_cruise < 1000 then
      -- We omit the climb phase completely and add it to the cruise part.
      d_cruise=d_cruise+d_climb
    else      
      -- Only one waypoint at the end of climb = begin of cruise.
      c[#c+1]=c[#c]:Translate(d_climb, heading)
            
      wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.cruise, c[#wp+1], VxCruise, FLcruise)
      self.waypointdescriptions[#wp]="Begin of Cruise"
      self.waypointstatus[#wp]=RAT.status.Cruise
    end
    
  else
  
    -- Ground start.
    c[#c+1]=c[#c]:Translate(d_climb/2, heading)
    c[#c+1]=c[#c]:Translate(d_climb/2, heading)
    
    wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.climb,  c[#wp+1], VxClimb, H_departure+(FLcruise-H_departure)/2)
    self.waypointdescriptions[#wp]="Climb"
    self.waypointstatus[#wp]=RAT.status.Climb
    
    wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.cruise, c[#wp+1], VxCruise, FLcruise)
    self.waypointdescriptions[#wp]="Begin of Cruise"
    self.waypointstatus[#wp]=RAT.status.Cruise
 
  end
  
  -- Cruise
  if self.destinationzone then
  
    -- Next waypoint is already the final destination.
    c[#c+1]=Pdestination
    wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.finalwp, c[#wp+1], VxCruise,  FLcruise)
    self.waypointdescriptions[#wp]="Final Destination"
    self.waypointstatus[#wp]=RAT.status.Destination
  
  elseif self.returnzone then
  
    c[#c+1]=Preturn
    c[#c+1]=c[#c]:Translate(d_cruise/2, heading-180)
    
    wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.cruise, c[#wp+1], VxCruise, FLcruise)
    self.waypointdescriptions[#wp]="Return Zone"
    self.waypointstatus[#wp]=RAT.status.Uturn
    
    wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.cruise, c[#wp+1], VxCruise,  FLcruise)
    self.waypointdescriptions[#wp]="End of Cruise"
    self.waypointstatus[#wp]=RAT.status.Descent
    
  else
  
    c[#c+1]=c[#c]:Translate(d_cruise, heading)
    wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.cruise, c[#wp+1], VxCruise,  FLcruise)
    self.waypointdescriptions[#wp]="End of Cruise"
    self.waypointstatus[#wp]=RAT.status.Descent
  end
  
  -- Descent
  if self.destinationzone then
    -- Nothing to do.
  elseif self.returnzone then
    c[#c+1]=c[#c]:Translate(d_descent/2, heading-180)
    wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.descent, c[#wp+1], VxDescent, FLcruise-(FLcruise-(h_holding+H_holding))/2)
    self.waypointdescriptions[#wp]="Descent"
    self.waypointstatus[#wp]=RAT.status.DescentHolding
  else
    c[#c+1]=c[#c]:Translate(d_descent/2, heading)
    wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.descent, c[#wp+1], VxDescent, FLcruise-(FLcruise-(h_holding+H_holding))/2)
    self.waypointdescriptions[#wp]="Descent"
    self.waypointstatus[#wp]=RAT.status.DescentHolding
  end
  
  -- Holding and final destination.
  if self.destinationzone then
    -- Nothing to do.
  else
    c[#c+1]=Pholding
    c[#c+1]=Pdestination
    
    wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.holding, c[#wp+1], VxHolding, H_holding+h_holding)
    self.waypointdescriptions[#wp]="Holding Point"
    self.waypointstatus[#wp]=RAT.status.Holding
    self.wp_holding=#wp
    
    wp[#wp+1]=self:_Waypoint(#wp+1, RAT.wp.landing, c[#wp+1], VxFinal, H_destination, destination)
    self.waypointdescriptions[#wp]="Destination"
    self.waypointstatus[#wp]=RAT.status.Destination
  end
  
  -- Final Waypoint
  self.wp_final=#wp
  
  -- Fill table with waypoints.
  local waypoints={}
  for _,p in ipairs(wp) do
    table.insert(waypoints, p)
  end
  
  -- Place markers of waypoints on F10 map.
  if self.placemarkers then
    self:_PlaceMarkers(waypoints)
  end
    
  -- Some info on the route.
  self:_Routeinfo(waypoints, "Waypoint info in set_route:")
  
  -- return departure, destination and waypoints
  return departure, destination, waypoints
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the departure airport of the AI. If no airport name is given explicitly an airport from the coalition is chosen randomly.
-- If takeoff style is set to "air", we use zones around the airports or the zones specified by user input.
-- @param #RAT self
-- @param #number takeoff Takeoff type.
-- @return Wrapper.Airbase#AIRBASE Departure airport if spawning at airport.
-- @return Core.Zone#ZONE Departure zone if spawning in air.
function RAT:_PickDeparture(takeoff)

  -- Array of possible departure airports or zones.
  local departures={}
  
  if takeoff==RAT.wp.air then
  
    if self.random_departure then
    
      -- Air start above a random airport.
      for _,airport in pairs(self.airports) do
        if not self:_Excluded(airport:GetName()) then
          table.insert(departures, airport:GetZone())
        end
      end
    
    else
      
      -- Put all specified zones in table.
      for _,name in pairs(self.departure_zones) do
        if not self:_Excluded(name) then
          table.insert(departures, ZONE:New(name))
        end
      end
      -- Put all specified airport zones in table.
      for _,name in pairs(self.departure_ports) do
        if not self:_Excluded(name) then
          table.insert(departures, AIRBASE:FindByName(name):GetZone())
        end
      end
      
    end
    
  else
  
    if self.random_departure then
    
      -- All friendly departure airports. 
      for _,airport in pairs(self.airports) do
        if not self:_Excluded(airport:GetName()) then
          table.insert(departures, airport)
        end
      end
      
    else
      
      -- All airports specified by user  
      for _,name in pairs(self.departure_ports) do
        if self:_IsFriendly(name) and not self:_Excluded(name) then
          table.insert(departures, AIRBASE:FindByName(name))
        end
      end
        
    end
  end

  -- Select departure airport or zone.
  local departure=departures[math.random(#departures)]
  
  local text
  if departure and departure:GetName() then
    if takeoff==RAT.wp.air then
      text="Chosen departure zone: "..departure:GetName()
    else
      text="Chosen departure airport: "..departure:GetName().." (ID "..departure:GetID()..")"
    end
    env.info(RAT.id..text)
    if self.debug then
      MESSAGE:New(text, 30):ToAll()
    end
  else
    departure=nil
  end
  
  return departure
end


--- Pick destination airport. If no airport name is given an airport from the coalition is chosen randomly.
-- @param #RAT self
-- @param #table destinations Table with destination airports.
-- @param #boolean _random (Optional) Switch to activate a random selection of airports.
-- @return Wrapper.Airbase#AIRBASE Destination airport.
function RAT:_PickDestination(destinations, _random)
  
  -- Randomly select one possible destination.
  local destination=nil
  if destinations and #destinations>0 then
  
    -- Random selection.
    destination=destinations[math.random(#destinations)] -- Wrapper.Airbase#AIRBASE
  
    -- Debug message.
    local text
    if self.destinationzone or self.returnzone then
      text="Chosen destination zone: "..destination:GetName()
    else
      text="Chosen destination airport: "..destination:GetName().." (ID "..destination:GetID()..")"
    end
    env.info(RAT.id..text)
    if self.debug then
      MESSAGE:New(text, 30):ToAll()
    end
    
  else
    env.error(RAT.id.."No destination airport found.")
  end
  
  return destination
end


--- Get all possible destination airports depending on departure position.
-- The list is sorted w.r.t. distance to departure position.
-- @param #RAT self
-- @param Wrapper.Airbase#AIRBASE departure Departure airport or zone.
-- @param Core.Point#COORDINATE q Coordinate of the departure point.
-- @param #number minrange Minimum range to q in meters.
-- @param #number maxrange Maximum range to q in meters.
-- @return #table Table with possible destination airports.
-- @return #nil If no airports could be found.
function RAT:_GetDestinations(departure, q, minrange, maxrange)

  -- Min/max range to destination.
  minrange=minrange or self.mindist
  maxrange=maxrange or self.maxdist

  local possible_destinations={}
  if self.random_destination then
  
    -- Airports of friendly coalitions.
    for _,airport in pairs(self.airports) do
      local name=airport:GetName()
      if self:_IsFriendly(name) and not self:_Excluded(name) and name~=departure:GetName() then
      
        -- Distance from departure to possible destination
        local distance=q:Get2DDistance(airport:GetCoordinate())
        
        -- Check if distance form departure to destination is within min/max range.
        if distance>=minrange and distance<=maxrange then
          table.insert(possible_destinations, airport)
        end
      end
    end
    
  else
    
    if self.destinationzone or self.returnzone then
    
      -- Destination or return zones specified by user.
      for _,zone in pairs(self.destination_zones) do
        if zone:GetName() ~= departure:GetName() then
        
          -- Distance from departure to possible destination
          local distance=q:Get2DDistance(zone:GetCoordinate())
          
          -- Add as possible destination if zone is within range.
          if distance>=minrange and distance<=maxrange then
            table.insert(possible_destinations, zone)
          end
        end
      end
          
    else
        
      -- Airports specified by user.
      for _,name in pairs(self.destination_ports) do
        --if self:_IsFriendly(name) and not self:_Excluded(name) and name~=departure:GetName() then
        if name~=departure:GetName() then
          local airport=AIRBASE:FindByName(name)
          
          -- Distance from departure to possible destination
          local distance=q:Get2DDistance(airport:GetCoordinate())
          
          -- Add as possible destination if airport is within range.
          if distance>=minrange and distance<=maxrange then
            table.insert(possible_destinations, airport)
          end
          
        end
      end
    end
    
  end
  
  -- Info message.
  env.info(RAT.id.."Number of possible destination airports = "..#possible_destinations)
  
  if #possible_destinations > 0 then
    --- Compare distance of destination airports.
    -- @param Core.Point#COORDINATE a Coordinate of point a.
    -- @param Core.Point#COORDINATE b Coordinate of point b.
    -- @return #list Table sorted by distance.
    local function compare(a,b)
      local qa=q:Get2DDistance(a:GetCoordinate())
      local qb=q:Get2DDistance(b:GetCoordinate())
      return qa < qb
    end
    table.sort(possible_destinations, compare)
  else
    env.error(RAT.id.."No possible destinations found!")
    possible_destinations=nil
  end
  
  -- Return table with destination airports.
  return possible_destinations
  
end

--- Find airports within a zone.
-- @param #RAT self
-- @param Core.Zone#ZONE zone
-- @return #list Table with airport names that lie within the zone.
function RAT:_GetAirportsInZone(zone)
  local airports={}
  for _,airport in pairs(self.airports) do
    local name=airport:GetName()
    local coord=airport:GetCoordinate()
    
    if zone:IsPointVec3InZone(coord) then
      table.insert(airports, name)
    end
  end
  return airports
end

--- Check if airport is excluded from possible departures and destinations.
-- @param #RAT self
-- @param #string port Name of airport, FARP or ship to check.
-- @return #boolean true if airport is excluded and false otherwise.
function RAT:_Excluded(port)
  for _,name in pairs(self.excluded_ports) do
    if name==port then
      return true
    end
  end
  return false
end

--- Check if airport is friendly, i.e. belongs to the right coalition.
-- @param #RAT self
-- @param #string port Name of airport, FARP or ship to check.
-- @return #boolean true if airport is friendly and false otherwise.
function RAT:_IsFriendly(port)
  for _,airport in pairs(self.airports) do
    local name=airport:GetName()
    if name==port then
      return true
    end
  end
  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get all airports of the current map.
-- @param #RAT self
function RAT:_GetAirportsOfMap()
  local _coalition
  
  for i=0,2 do -- cycle coalition.side 0=NEUTRAL, 1=RED, 2=BLUE
  
    -- set coalition
    if i==0 then
      _coalition=coalition.side.NEUTRAL
    elseif i==1 then
      _coalition=coalition.side.RED
    elseif i==2 then
      _coalition=coalition.side.BLUE
    end
    
    -- get airbases of coalition
    local ab=coalition.getAirbases(i)
    
    -- loop over airbases and put them in a table
    for _,airbase in pairs(ab) do
    
      local _id=airbase:getID()
      local _p=airbase:getPosition().p
      local _name=airbase:getName()
      local _myab=AIRBASE:FindByName(_name)
      
      -- Add airport to table.
      table.insert(self.airports_map, _myab)
      
      if self.debug then
        local text1="MOOSE: Airport ID = ".._myab:GetID().." and Name = ".._myab:GetName()..", Category = ".._myab:GetCategory()..", TypeName = ".._myab:GetTypeName()
        --local text2="DCS  : Airport ID = "..airbase:getID().." and Name = "..airbase:getName()..", Category = "..airbase:getCategory()..", TypeName = "..airbase:getTypeName()
        env.info(RAT.id..text1)
        --env.info(RAT.id..text2)
      end
      
    end
    
  end
end

--- Get all "friendly" airports of the current map.
-- @param #RAT self
function RAT:_GetAirportsOfCoalition()
  for _,coalition in pairs(self.ctable) do
    for _,airport in pairs(self.airports_map) do
      if airport:GetCoalition()==coalition then
        -- Planes cannot land on FARPs.
        local condition1=self.category==RAT.cat.plane and airport:GetTypeName()=="FARP"
        -- Planes cannot land on ships.
        local condition2=self.category==RAT.cat.plane and airport:GetCategory()==1
        if not (condition1 or condition2) then
          table.insert(self.airports, airport)
        end
      end
    end
  end
    
  if #self.airports==0 then
    local text="No possible departure/destination airports found!"
    MESSAGE:New(text, 60):ToAll()
    env.error(RAT.id..text)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Report status of RAT groups.
-- @param #RAT self
-- @param #boolean message (Optional) Send message with report to all if true.
-- @param #number forID (Optional) Send message only for this ID.
function RAT:Status(message, forID)

  message=message or false
  forID=forID or false

  -- number of ratcraft spawned.
  local ngroups=#self.ratcraft
  
  -- Current time.
  local Tnow=timer.getTime()
    
  for i=1, ngroups do
  
    if self.ratcraft[i].group then
      if self.ratcraft[i].group:IsAlive() then
      
        -- Gather some information.
        local group=self.ratcraft[i].group  --Wrapper.Group#GROUP
        local prefix=self:_GetPrefixFromGroup(group)
        local life=self:_GetLife(group)
        local fuel=group:GetFuel()*100.0
        local airborne=group:InAir()
        local coords=group:GetCoordinate()
        local alt=coords.y
        --local vel=group:GetVelocityKMH()
        local departure=self.ratcraft[i].departure:GetName()
        local destination=self.ratcraft[i].destination:GetName()
        local type=self.aircraft.type
        
        
        -- Monitor time and distance on ground.
        local Tg=0
        local Dg=0
        local dTlast=0
        local stationary=false --lets assume, we did move
        if airborne then
          -- Aircraft is airborne.
          self.ratcraft[i]["Tground"]=nil
          self.ratcraft[i]["Pground"]=nil
          self.ratcraft[i]["Tlastcheck"]=nil
        else
          --Aircraft is on ground.
          if self.ratcraft[i]["Tground"] then
            -- Aircraft was already on ground. Calculate total time on ground.
            Tg=Tnow-self.ratcraft[i]["Tground"]
            
            -- Distance on ground since last check.
            Dg=coords:Get2DDistance(self.ratcraft[i]["Pground"])
            
            -- Time interval since last check.
            dTlast=Tnow-self.ratcraft[i]["Tlastcheck"]
            
            -- If more than Tinactive seconds passed since last check ==> check how much we moved meanwhile.
            if dTlast > self.Tinactive then
                    
              -- If aircraft did not move more than 50 m since last check, we call it stationary and despawn it.
              --TODO: add case that the aircraft are currently starting their engines. This should not count as being stationary.
              --local starting_engines=self.ratcraft[i].status==""
              if Dg<50 then
                stationary=true
              end
              
               -- Set the current time to know when the next check is necessary.
              self.ratcraft[i]["Tlastcheck"]=Tnow
              self.ratcraft[i]["Pground"]=coords
            end
            
          else
            -- First time we see that the aircraft is on ground. Initialize the times and position.
            self.ratcraft[i]["Tground"]=Tnow
            self.ratcraft[i]["Tlastcheck"]=Tnow
            self.ratcraft[i]["Pground"]=coords
          end
        end
        
        -- Monitor travelled distance since last check.
        local Pn=coords
        local Dtravel=Pn:Get2DDistance(self.ratcraft[i]["Pnow"])
        self.ratcraft[i]["Pnow"]=Pn
        
        -- Add up the travelled distance.
        self.ratcraft[i]["Distance"]=self.ratcraft[i]["Distance"]+Dtravel
        
        -- Distance remaining to destination.
        local Ddestination=Pn:Get2DDistance(self.ratcraft[i].destination:GetCoordinate())
        
        -- Status shortcut.
        local status=self.ratcraft[i].status
     
        -- Status report.
        if (forID and i==forID) or (not forID) then
          local text=string.format("ID %i of group %s\n", i, prefix)
          if self.commute then
            text=text..string.format("%s commuting between %s and %s\n", type, departure, destination)
          elseif self.continuejourney then
            text=text..string.format("%s travelling from %s to %s (and continueing form there)\n", type, departure, destination)
          else
            text=text..string.format("%s travelling from %s to %s\n", type, departure, destination)
          end
          text=text..string.format("Status: %s", self.ratcraft[i].status)
          if airborne then
            text=text.." [airborne]\n"
          else
            text=text.." [on ground]\n"
          end
          text=text..string.format("Fuel = %3.0f %%\n", fuel)
          text=text..string.format("Life  = %3.0f %%\n", life)
          text=text..string.format("FL%03d = %i m\n", alt/RAT.unit.FL2m, alt)
          --text=text..string.format("Speed = %i km/h\n", vel)
          text=text..string.format("Distance travelled        = %6.1f km\n", self.ratcraft[i]["Distance"]/1000)
          text=text..string.format("Distance to destination = %6.1f km", Ddestination/1000)
          if not airborne then
            text=text..string.format("\nTime on ground  = %6.0f seconds\n", Tg)
            text=text..string.format("Position change = %8.1f m since %3.0f seconds.", Dg, dTlast)
          end
          if self.debug then
            env.info(RAT.id..text)
          end
          if message then
            MESSAGE:New(text, 20):ToAll()
          end
        end
        
        -- Despawn groups if they are on ground and don't move or are damaged.
        if not airborne then
        
          -- Despawn unit if it did not move more then 50 m in the last 180 seconds.
          if stationary then
            local text=string.format("Group %s is despawned after being %4.0f seconds inaktive on ground.", self.alias, dTlast)
            env.info(RAT.id..text)
            self:_Despawn(group)
          end
          -- Despawn group if life is < 10% and distance travelled < 100 m.
          if life<10 and Dtravel<100 then
            local text=string.format("Damaged group %s is despawned. Life = %3.0f", self.alias, life)
            self:_Despawn(group)
          end
        end
        
        if self.ratcraft[i].despawnme then
          local text=string.format("Flight %s will be despawned NOW!", self.alias)
          env.info(RAT.id..text)
            -- Despawn old group.
          self:_Respawn(self.ratcraft[i].group)
          self:_Despawn(self.ratcraft[i].group)
        end
      end       
    else
      if self.debug then
        local text=string.format("Group %i does not exist.", i)
        env.info(RAT.id..text)
      end
    end    
  end
  
  if (message and not forID) then
    local text=string.format("Alive groups of %s: %d", self.alias, self.alive)
    env.info(RAT.id..text)
    MESSAGE:New(text, 20):ToAll()
  end  
  
end

--- Get (relative) life of first unit of a group.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group of unit.
-- @return #number Life of unit in percent.
function RAT:_GetLife(group)
  local life=0.0
  if group and group:IsAlive() then
    local unit=group:GetUnit(1)
    if unit then
      life=unit:GetLife()/unit:GetLife0()*100
    else
      if self.debug then
        env.error(RAT.id.."Unit does not exist in RAT_Getlife(). Returning zero.")
      end
    end
  else
    if self.debug then
      env.error(RAT.id.."Group does not exist in RAT_Getlife(). Returning zero.")
    end
  end
  return life
end

--- Set status of group.
-- @param #RAT self
function RAT:_SetStatus(group, status)

  -- Get index from groupname.
  local index=self:GetSpawnIndexFromGroup(group)
  
  -- Set new status.
  self.ratcraft[index].status=status
  
  -- No status update message for "first waypoint", "holding"
  local noupdate1 = status==RAT.status.Departure
  local noupdate2 = status==RAT.status.Holding
  
  local text=string.format("Flight %s: %s.", group:GetName(), status)
  env.info(RAT.id..text)
  
  if (not (noupdate1 or noupdate2)) then
    MESSAGE:New(text, 10):ToAllIf(self.reportstatus)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function is executed when a unit is spawned.
-- @param #RAT self
function RAT:_OnBirth(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
    
        local text="Event: Group "..SpawnGroup:GetName().." was born."
        env.info(RAT.id..text)

        -- Set status.
        local status
        if SpawnGroup:InAir() then
          status="Just born (after air start)"
          status=RAT.status.EventBirthAir
        else
          status="Starting engines (after birth)"
          status=RAT.status.EventBirth
        end
        self:_SetStatus(SpawnGroup, status)
        
      end
    end
  else
    if self.debug then
      env.error("Group does not exist in RAT:_OnBirthDay().")
    end
  end
end

--- Function is executed when a unit starts its engines.
-- @param #RAT self
function RAT:_EngineStartup(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        local text="Event: Group "..SpawnGroup:GetName().." started engines."
        env.info(RAT.id..text)
    
        -- Set status.
        local status
        if SpawnGroup:InAir() then
          status="On journey (after air start)"
          status=RAT.status.EventEngineStartAir
        else
          status="Taxiing (after engines started)"
          status=RAT.status.EventEngineStart
        end
        self:_SetStatus(SpawnGroup, status)
      end
    end
    
  else
    if self.debug then
      env.error("Group does not exist in RAT:_EngineStartup().")
    end
  end
end

--- Function is executed when a unit takes off.
-- @param #RAT self
function RAT:_OnTakeoff(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        local text="Event: Group "..SpawnGroup:GetName().." is airborne."
        env.info(RAT.id..text)
    
        -- Set status.
        local status=RAT.status.EventTakeoff
        --self:_SetStatus(SpawnGroup, "On journey (after takeoff)")
        self:_SetStatus(SpawnGroup, status)
        
        if self.respawn_after_takeoff then
          text="Event: Group "..SpawnGroup:GetName().." will be respawned."
          env.info(RAT.id..text)
        
          -- Respawn group.
          self:_Respawn(SpawnGroup)
        end
        
      end
    end
    
  else
    if self.debug then
      env.error("Group does not exist in RAT:_OnTakeoff().")
    end
  end
end

--- Function is executed when a unit lands.
-- @param #RAT self
function RAT:_OnLand(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        local text="Event: Group "..SpawnGroup:GetName().." landed."
        env.info(RAT.id..text)
    
        -- Set status.
        --self:_SetStatus(SpawnGroup, "Taxiing (after landing)")
        local status=RAT.status.EventLand
        self:_SetStatus(SpawnGroup, status)

        -- ATC plane landed. Take it out of the queue and set runway to free.
        if self.ATCswitch then
          RAT:_ATCFlightLanded(SpawnGroup:GetName())
        end        
        
        if self.respawn_at_landing and not self.norespawn then
          text="Event: Group "..SpawnGroup:GetName().." will be respawned."
          env.info(RAT.id..text)
        
          -- Respawn group.
          self:_Respawn(SpawnGroup)
        end
        
      end
    end
    
  else
    if self.debug then
      env.error("Group does not exist in RAT:_OnLand().")
    end
  end
end

--- Function is executed when a unit shuts down its engines.
-- @param #RAT self
function RAT:_OnEngineShutdown(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        local text="Event: Group "..SpawnGroup:GetName().." shut down its engines."
        env.info(RAT.id..text)
    
        -- Set status.
        --self:_SetStatus(SpawnGroup, "Parking (shutting down engines)")
        local status=RAT.status.EventEngineShutdown
        self:_SetStatus(SpawnGroup, status)
        
        if not self.respawn_at_landing and not self.norespawn then
          text="Event: Group "..SpawnGroup:GetName().." will be respawned."
          env.info(RAT.id..text)
        
          -- Respawn group.
          self:_Respawn(SpawnGroup)
        end
        
        -- Despawn group.
        text="Event: Group "..SpawnGroup:GetName().." will be destroyed now."
        env.info(RAT.id..text)
        self:_Despawn(SpawnGroup)
        
      end
    end
    
  else
    if self.debug then
      env.error("Group does not exist in RAT:_OnEngineShutdown().")
    end
  end
end

--- Function is executed when a unit is dead.
-- @param #RAT self
function RAT:_OnDead(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        local text="Event: Group "..SpawnGroup:GetName().." died."
        env.info(RAT.id..text)
    
        -- Set status.
        --self:_SetStatus(SpawnGroup, "Destroyed (after dead)")
        local status=RAT.status.EventDead
        self:_SetStatus(SpawnGroup, status)
        
      end
    end

  else
    if self.debug then
      env.error("Group does not exist in RAT:_OnDead().")
    end
  end
end

--- Function is executed when a unit crashes.
-- @param #RAT self
function RAT:_OnCrash(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    env.info(string.format("%sGroup %s crashed!", RAT.id, SpawnGroup:GetName()))

    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        local text="Event: Group "..SpawnGroup:GetName().." crashed."
        env.info(RAT.id..text)
    
        -- Set status.
        --self:_SetStatus(SpawnGroup, "Crashed")
        local status=RAT.status.EventCrash
        self:_SetStatus(SpawnGroup, status)
        
        --TODO: Aircraft are not respawned if they crash. Should they?
    
        --TODO: Maybe spawn some people at the crash site and send a distress call.
        --      And define them as cargo which can be rescued.
      end
    end
    
  else
    if self.debug then
      env.error("Group does not exist in RAT:_OnCrash().")
    end
  end
end

--- Despawn unit. Unit gets destoyed and group is set to nil.
-- Index of ratcraft array is taken from spawned group name.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group to be despawned.
function RAT:_Despawn(group)

  local index=self:GetSpawnIndexFromGroup(group)
  --self.ratcraft[index].group:Destroy()
  self.ratcraft[index].group=nil
  group:Destroy()

  -- Decrease group alive counter.
  self.alive=self.alive-1
  
    -- Remove submenu for this group.
  if self.f10menu then
    self.Menu[self.SubMenuName]["groups"][index]:Remove()
  end

  --TODO: Maybe here could be some more arrays deleted?
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a waypoint that can be used with the Route command.
-- @param #RAT self
-- @param #number Running index of waypoints. Starts with 1 which is normally departure/spawn waypoint.
-- @param #number Type Type of waypoint.
-- @param Core.Point#COORDINATE Coord 3D coordinate of the waypoint.
-- @param #number Speed Speed in m/s.
-- @param #number Altitude Altitude in m.
-- @param Wrapper.Airbase#AIRBASE Airport Airport of object to spawn.
-- @return #table Waypoints for DCS task route or spawn template.
function RAT:_Waypoint(index, Type, Coord, Speed, Altitude, Airport)

  -- Altitude of input parameter or y-component of 3D-coordinate.
  local _Altitude=Altitude or Coord.y
  
  -- Land height at given coordinate.
  local Hland=Coord:GetLandHeight()
  
  -- convert type and action in DCS format
  local _Type=nil
  local _Action=nil
  local _alttype="RADIO"

  if Type==RAT.wp.cold then
    -- take-off with engine off
    _Type="TakeOffParking"
    _Action="From Parking Area"
    _Altitude = 0
    _alttype="RADIO"
  elseif Type==RAT.wp.hot then
    -- take-off with engine on 
    _Type="TakeOffParkingHot"
    _Action="From Parking Area Hot"
    _Altitude = 0
    _alttype="RADIO"
  elseif Type==RAT.wp.runway then
    -- take-off from runway
    _Type="TakeOff"
    _Action="From Parking Area"
    _Altitude = 0
    _alttype="RADIO"
  elseif Type==RAT.wp.air then
    -- air start
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="BARO"
  elseif Type==RAT.wp.climb then
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="BARO"
  elseif Type==RAT.wp.cruise then
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="BARO"
  elseif Type==RAT.wp.descent then
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="BARO"
  elseif Type==RAT.wp.holding then
    _Type="Turning Point"
    --_Action="Turning Point"
    _Action="Fly Over Point"
    _alttype="BARO"
  elseif Type==RAT.wp.landing then
    _Type="Land"
    _Action="Landing"
    _Altitude = 0
    _alttype="RADIO"
  elseif Type==RAT.wp.finalwp then
    _Type="Turning Point"
    _Action="Fly Over Point"
    _alttype="BARO"
  else
    env.error("Unknown waypoint type in RAT:Waypoint() function!")
    _Type="Turning Point"
    _Action="Turning Point"
    _alttype="RADIO"
  end

  -- some debug info about input parameters
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Waypoint =  %d\n", index)
  text=text..string.format("Template =  %s\n", self.SpawnTemplatePrefix)
  text=text..string.format("Alias    =  %s\n", self.alias)
  text=text..string.format("Type: %i - %s\n", Type, _Type)
  text=text..string.format("Action: %s\n", _Action)
  text=text..string.format("Coord: x = %6.1f km, y = %6.1f km, alt = %6.1f m\n", Coord.x/1000, Coord.z/1000, Coord.y)
  text=text..string.format("Speed = %6.1f m/s = %6.1f km/h = %6.1f knots\n", Speed, Speed*3.6, Speed*1.94384)
  text=text..string.format("Land     = %6.1f m ASL\n", Hland)
  text=text..string.format("Altitude = %6.1f m (%s)\n", _Altitude, _alttype)
  if Airport then
    if Type==RAT.wp.air then
      text=text..string.format("Zone = %s\n", Airport:GetName())
    else
      --text=text..string.format("Airport = %s with ID %i\n", Airport:GetName(), Airport:GetID())
      text=text..string.format("Airport = %s\n", Airport:GetName())
    end
  else
    text=text..string.format("No airport/zone specified\n")
  end
  text=text.."******************************************************\n"
  if self.debug then
    env.info(RAT.id..text)
  end
    
  -- define waypoint
  local RoutePoint = {}
  -- coordinates and altitude
  RoutePoint.x = Coord.x
  RoutePoint.y = Coord.z
  RoutePoint.alt = _Altitude
  -- altitude type: BARO=ASL or RADIO=AGL
  RoutePoint.alt_type = _alttype
  -- type 
  RoutePoint.type = _Type
  RoutePoint.action = _Action
  -- speed in m/s
  RoutePoint.speed = Speed
  RoutePoint.speed_locked = true
  -- ETA (not used)
  RoutePoint.ETA=nil
  RoutePoint.ETA_locked = false
  -- waypoint name (only for the mission editor)
  RoutePoint.name="RAT waypoint"
  
  if (Airport~=nil) and Type~=RAT.wp.air then
    env.info(RAT.id.."Airport = "..Airport:GetName())
    env.info(RAT.id.."Type    = "..Type)
    local AirbaseID = Airport:GetID()
    local AirbaseCategory = Airport:GetDesc().category
    if AirbaseCategory == Airbase.Category.SHIP then
      RoutePoint.linkUnit = AirbaseID
      RoutePoint.helipadId = AirbaseID
      --env.info(RAT.id.."WP: Ship id = "..AirbaseID)
    elseif AirbaseCategory == Airbase.Category.HELIPAD then
      RoutePoint.linkUnit = AirbaseID
      RoutePoint.helipadId = AirbaseID
      --env.info(RAT.id.."WP: Helipad id = "..AirbaseID)
    elseif AirbaseCategory == Airbase.Category.AIRDROME then
      RoutePoint.airdromeId = AirbaseID
      --env.info(RAT.id.."WP: Airdrome id = "..AirbaseID)
    else
      --env.error(RAT.id.."Unknown Airport categoryin _Waypoint()!")
    end  
  end
  -- properties
  RoutePoint.properties = {
    ["vnav"]   = 1,
    ["scale"]  = 0,
    ["angle"]  = 0,
    ["vangle"] = 0,
    ["steer"]  = 2,
  }
  -- tasks
  local TaskCombo = {}
  local TaskHolding  = self:_TaskHolding({x=Coord.x, y=Coord.z}, Altitude, Speed, self:_Randomize(90,0.9))
  local TaskRespawn  = self:_TaskFunction("RAT._FinalWaypoint", self)
  local TaskWaypoint = self:_TaskFunction("RAT._WaypointFunction", self, index)
  
  RoutePoint.task = {}
  RoutePoint.task.id = "ComboTask"
  RoutePoint.task.params = {}
  
  TaskCombo[#TaskCombo+1]=TaskWaypoint
  if Type==RAT.wp.holding then
    TaskCombo[#TaskCombo+1]=TaskHolding
  end
  
  RoutePoint.task.params.tasks = TaskCombo

  -- Return waypoint.
  return RoutePoint
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Provide information about the assigned flightplan.
-- @param #RAT self
-- @param #table waypoints Waypoints of the flight plan.
-- @param #string comment Some comment to identify the provided information.
-- @return #number total Total route length in meters.
function RAT:_Routeinfo(waypoints, comment)
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Template =  %s\n", self.SpawnTemplatePrefix)
  if comment then
    text=text..comment.."\n"
  end
  text=text..string.format("Number of waypoints = %i\n", #waypoints)
  -- info on coordinate and altitude
  for i=1,#waypoints do
    local p=waypoints[i]
    text=text..string.format("WP #%i: x = %6.1f km, y = %6.1f km, alt = %6.1f m  %s\n", i-1, p.x/1000, p.y/1000, p.alt, self.waypointdescriptions[i])
  end
  -- info on distance between waypoints
  local total=0.0
  for i=1,#waypoints-1 do
    local point1=waypoints[i]
    local point2=waypoints[i+1]
    local x1=point1.x
    local y1=point1.y
    local x2=point2.x
    local y2=point2.y
    local d=math.sqrt((x1-x2)^2 + (y1-y2)^2)
    local heading=self:_Course(point1, point2)
    total=total+d
    text=text..string.format("Distance from WP %i-->%i = %6.1f km. Heading = %03d:  %s - %s\n", i-1, i, d/1000, heading, self.waypointdescriptions[i], self.waypointdescriptions[i+1])
  end
  text=text..string.format("Total distance = %6.1f km\n", total/1000)
  text=text..string.format("******************************************************\n")
  
  -- send message
  if self.debug then
    --env.info(RAT.id..text)
  end
  env.info(RAT.id..text)
  
  -- return total route length in meters
  return total
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Orbit at a specified position at a specified alititude with a specified speed.
-- @param #RAT self
-- @param Dcs.DCSTypes#Vec2 P1 The point to hold the position.
-- @param #number Altitude The altitude ASL at which to hold the position.
-- @param #number Speed The speed flying when holding the position in m/s.
-- @param #number Duration Duration of holding pattern in seconds.
-- @return Dcs.DCSTasking.Task#Task DCSTask
function RAT:_TaskHolding(P1, Altitude, Speed, Duration)

  --local LandHeight = land.getHeight(P1)

  --TODO: randomize P1
  -- Second point is 3 km north of P1 and 200 m for helos.
  local dx=3000
  local dy=0
  if self.category==RAT.cat.heli then
    dx=200
    dy=0
  end
  
  local P2={}
  P2.x=P1.x+dx
  P2.y=P1.y+dy
  local Task = {
    id = 'Orbit',
    params = {
      pattern = AI.Task.OrbitPattern.RACE_TRACK,
      --pattern = AI.Task.OrbitPattern.CIRCLE,
      point = P1,
      point2 = P2,
      speed = Speed,
      altitude = Altitude
    }
  }
  
  local DCSTask={}
  DCSTask.id="ControlledTask"
  DCSTask.params={}
  DCSTask.params.task=Task
  
  if self.ATCswitch then
    -- Set stop condition for holding. Either flag=1 or after max. 30 min holding.
    local userflagname=string.format("%s#%03d", self.alias, self.SpawnIndex+1)
    DCSTask.params.stopCondition={userFlag=userflagname, userFlagValue=1, duration=1800}
  else
    DCSTask.params.stopCondition={duration=Duration}
  end
  
  return DCSTask
end

--- Function which is called after passing every waypoint. Info on waypoint is given and special functions are executed.
-- @param Core.Group#GROUP group Group of aircraft.
-- @param #RAT rat RAT object.
-- @param #number wp Waypoint index. Running number of the waypoints. Determines the actions to be executed.
function RAT._WaypointFunction(group, rat, wp)

  -- Current time and Spawnindex.
  local Tnow=timer.getTime()
  local sdx=rat:GetSpawnIndexFromGroup(group)
  
  -- Departure and destination names.
  local departure=rat.ratcraft[sdx].departure:GetName()
  local destination=rat.ratcraft[sdx].destination:GetName()
  
  -- For messages
  local text
  
  -- Info on passing waypoint.
  text=string.format("Flight %s passing waypoint #%d %s.", group:GetName(), wp, rat.waypointdescriptions[wp])
  env.info(RAT.id..text)
    
  -- New status.
  local status=rat.waypointstatus[wp]
    
  --rat.ratcraft[sdx].status=status
  rat:_SetStatus(group, status)
    
  if wp==rat.wp_holding then
  
    -- Aircraft arrived at holding point
    text=string.format("Flight %s to %s ATC: Holding and awaiting landing clearance.", group:GetName(), destination)
    MESSAGE:New(text, 10):ToAllIf(rat.reportstatus)
     
    -- Register aircraft at ATC.
    if rat.ATCswitch then
       MENU_MISSION_COMMAND:New("Clear for landing", rat.Menu[rat.SubMenuName].groups[sdx], rat.ClearForLanding, rat, group:GetName())
       rat:_ATCRegisterFlight(group:GetName(), Tnow)
    end
  end
  
  if wp==rat.wp_final then
    text=string.format("Flight %s arrived at final destination %s.", group:GetName(), destination)
    MESSAGE:New(text, 10):ToAllIf(rat.reportstatus)
    env.info(RAT.id..text)
  
    if rat.destinationzone then
      text=string.format("Activating despawn switch for flight %s! Group will be detroyed soon.", group:GetName())
      MESSAGE:New(text, 30):ToAllIf(rat.debug)
      env.info(RAT.id..text)
      -- Enable despawn switch. Next time the status function is called, the aircraft will be despawned.
      rat.ratcraft[sdx].despawnme=true
    end
  end
end

--- Task function.
-- @param #RAT self
-- @param #string FunctionString Name of the function to be called.
function RAT:_TaskFunction(FunctionString, ... )
  self:F2({FunctionString, arg})
  
  local DCSTask
  local ArgumentKey
  
  -- Templatename and anticipated name the group will get
  local templatename=self.templategroup:GetName()
  local groupname=self:_AnticipatedGroupName()
  
  local DCSScript = {}
  --DCSScript[#DCSScript+1] = "local MissionControllable = GROUP:Find( ... ) "
  DCSScript[#DCSScript+1] = "local MissionControllable = GROUP:FindByName(\""..groupname.."\") "
  DCSScript[#DCSScript+1] = "local RATtemplateControllable = GROUP:FindByName(\""..templatename.."\") "

  if arg and arg.n > 0 then
    ArgumentKey = '_' .. tostring(arg):match("table: (.*)")
    self.templategroup:SetState(self.templategroup, ArgumentKey, arg)
    DCSScript[#DCSScript+1] = "local Arguments = RATtemplateControllable:GetState(RATtemplateControllable, '" .. ArgumentKey .. "' ) "
    DCSScript[#DCSScript+1] = FunctionString .. "( MissionControllable, unpack( Arguments ) )"
  else
    DCSScript[#DCSScript+1] = FunctionString .. "( MissionControllable )"
  end
  
  DCSTask = self.templategroup:TaskWrappedAction(self.templategroup:CommandDoScript(table.concat(DCSScript)))

  --env.info(RAT.id.."Taskfunction:")
  --self:E( DCSTask )

  return DCSTask
end

--- Anticipated group name from alias and spawn index.
-- @param #RAT self
-- @param #number index Spawnindex of group if given or self.SpawnIndex+1 by default.  
-- @return #string Name the group will get after it is spawned.
function RAT:_AnticipatedGroupName(index)
  local index=index or self.SpawnIndex+1
  return string.format("%s#%03d", self.alias, self.SpawnIndex+1)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Calculate the max flight level for a given distance and fixed climb and descent rates.
-- In other words we have a distance between two airports and want to know how high we
-- can climb before we must descent again to arrive at the destination without any level/cruising part.
-- @param #RAT self
-- @param #number alpha Angle of climb [rad].
-- @param #number beta Angle of descent [rad].
-- @param #number d Distance between the two airports [m].
-- @param #number phi Angle between departure and destination [rad].
-- @param #number h0 Height [m] of departure airport. Note we implicitly assume that the height difference between departure and destination is negligible.
-- @return #number Maximal flight level in meters.
function RAT:_FLmax(alpha, beta, d, phi, h0)
-- Solve ASA triangle for one side (d) and two adjacent angles (alpha, beta) given.
  local gamma=math.rad(180)-alpha-beta
  local a=d*math.sin(alpha)/math.sin(gamma)
  local b=d*math.sin(beta)/math.sin(gamma)
  -- h1 and h2 should be equal.
  local h1=b*math.sin(alpha)
  local h2=a*math.sin(beta)
  -- We also take the slope between departure and destination into account.
  local h3=b*math.cos(math.pi/2-(alpha+phi))
  -- Debug message.
  local text=string.format("\nFLmax = FL%3.0f = %6.1f m.\n", h1/RAT.unit.FL2m, h1)
  text=text..string.format(  "FLmax = FL%3.0f = %6.1f m.\n", h2/RAT.unit.FL2m, h2)
  text=text..string.format(  "FLmax = FL%3.0f = %6.1f m.",   h3/RAT.unit.FL2m, h3)
  if self.debug then
    env.info(RAT.id..text)
  end
  return h3+h0
end

--- Calculate min distance between departure and destination for given minimum flight level and climb/decent rates
-- @param #RAT self
-- @param #number alpha Angle of climb [rad].
-- @param #number beta Angle of descent [rad].
-- @param #number h min height AGL.
-- @return #number Minimum distance between departure and destiantion.
function RAT:_MinDistance(alpha, beta, h)
  local d1=h/math.tan(alpha)
  local d2=h/math.tan(beta)
  return d1+d2
end


--- Test if an airport exists on the current map.
-- @param #RAT self
-- @param #string name
-- @return #boolean True if airport exsits, false otherwise. 
function RAT:_AirportExists(name)
  for _,airport in pairs(self.airports_map) do
    if airport:GetName()==name then
      return true
    end
  end
  return false
end

--- Test if a trigger zone defined in the mission editor exists.
-- @param #RAT self
-- @param #string name
-- @return #boolean True if zone exsits, false otherwise. 
function RAT:_ZoneExists(name)
  local z=trigger.misc.getZone(name)
  if z then            
    return true
  end
  return false
end

--- Set ROE for a group.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group for which the ROE is set.
-- @param #string roe ROE of group.
function RAT:_SetROE(group, roe)
  env.info(RAT.id.."Setting ROE to "..roe.." for group "..group:GetName())
  if self.roe==RAT.ROE.returnfire then
    group:OptionROEReturnFire()
  elseif self.roe==RAT.ROE.weaponfree then
    group:OptionROEWeaponFree()
  else
    group:OptionROEHoldFire()
  end
end


--- Set ROT for a group.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group for which the ROT is set.
-- @param #string rot ROT of group.
function RAT:_SetROT(group, rot)
  env.info(RAT.id.."Setting ROT to "..rot.." for group "..group:GetName())
  if self.rot==RAT.ROT.passive then
    group:OptionROTPassiveDefense()
  elseif self.rot==RAT.ROT.evade then
    group:OptionROTEvadeFire()
  else
    group:OptionROTNoReaction()
  end
end


--- Create a table with the valid coalitions for departure and destination airports.
-- @param #RAT self
function RAT:_SetCoalitionTable()
  -- get all possible departures/destinations depending on coalition
  if self.friendly==RAT.coal.neutral then
    self.ctable={coalition.side.NEUTRAL}
  elseif self.friendly==RAT.coal.same then
    self.ctable={self.coalition, coalition.side.NEUTRAL}
  elseif self.friendly==RAT.coal.sameonly then
    self.ctable={self.coalition}
  else
    env.error("Unknown friendly coalition in _SetCoalitionTable(). Defaulting to NEUTRAL.")
    self.ctable={self.coalition, coalition.side.NEUTRAL}
  end
end


---Determine the heading from point a to point b.
--@param #RAT self
--@param Core.Point#COORDINATE a Point from.
--@param Core.Point#COORDINATE b Point to.
--@return #number Heading/angle in degrees. 
function RAT:_Course(a,b)
  local dx = b.x-a.x
  -- take the right value for y-coordinate (if we have "alt" then "y" if not "z")
  local ay
  if a.alt then
    ay=a.y
  else
    ay=a.z
  end
  local by
  if b.alt then
    by=b.y
  else
    by=b.z
  end
  local dy = by-ay
  local angle = math.deg(math.atan2(dy,dx))
  if angle < 0 then
    angle = 360 + angle
  end
  return angle
end


--- Randomize a value by a certain amount.
-- @param #RAT self
-- @param #number value The value which should be randomized
-- @param #number fac Randomization factor.
-- @param #number lower (Optional) Lower limit of the returned value.
-- @param #number upper (Optional) Upper limit of the returned value.
-- @return #number Randomized value.
-- @usage _Randomize(100, 0.1) returns a value between 90 and 110, i.e. a plus/minus ten percent variation.
-- @usage _Randomize(100, 0.5, nil, 120) returns a value between 50 and 120, i.e. a plus/minus fivty percent variation with upper bound 120.
function RAT:_Randomize(value, fac, lower, upper)
  local min
  if lower then
    min=math.max(value-value*fac, lower)
  else
    min=value-value*fac
  end
  local max
  if upper then
    max=math.min(value+value*fac, upper)
  else
    max=value+value*fac
  end
  
  local r=math.random(min, max)
  
  -- debug info
  if self.debug then
    local text=string.format("Random: value = %6.2f, fac = %4.2f, min = %6.2f, max = %6.2f, r = %6.2f", value, fac, min, max, r)
    env.info(RAT.id..text)
  end
  
  return r
end

--- Generate Gaussian pseudo-random numbers.
-- @param #number x0 Expectation value of distribution.
-- @param #number sigma (Optional) Standard deviation. Default 10.
-- @param #number xmin (Optional) Lower cut-off value.
-- @param #number xmax (Optional) Upper cut-off value.
-- @return #number Gaussian random number.
function RAT:_Random_Gaussian(x0, sigma, xmin, xmax)

  -- Standard deviation. Default 10 if not given.
  sigma=sigma or 10
    
  local r
  local gotit=false
  local i=0
  while not gotit do
  
    -- Uniform numbers in [0,1). We need two.
    local x1=math.random()
    local x2=math.random()
  
    -- Transform to Gaussian exp(-(x-x0)²/(2*sigma²).
    r = math.sqrt(-2*sigma*sigma * math.log(x1)) * math.cos(2*math.pi * x2) + x0
    
    i=i+1
    if (r>=xmin and r<=xmax) or i>100 then
      gotit=true
    end
  end
  
  return r

end

--- Place markers of the waypoints. Note we assume a very specific number and type of waypoints here.
-- @param #RAT self
-- @param #table waypoints Table with waypoints.
function RAT:_PlaceMarkers(waypoints)
  for i=1,#waypoints do
    self:_SetMarker(self.waypointdescriptions[i], waypoints[i])
  end
end


--- Set a marker visible for all on the F10 map.
-- @param #RAT self
-- @param #string text Info text displayed at maker.
-- @param #table wp Position of marker coming in as waypoint, i.e. has x, y and alt components.
function RAT:_SetMarker(text, wp)
  RAT.markerid=RAT.markerid+1
  self.markerids[#self.markerids+1]=RAT.markerid
  if self.debug then
    env.info(RAT.id..self.SpawnTemplatePrefix..": placing marker with ID "..RAT.markerid..": "..text)
  end
  -- Convert to coordinate.
  local vec={x=wp.x, y=wp.alt, z=wp.y}
  -- Place maker visible for all on the F10 map.
  local text1=string.format("%s:\n%s", self.alias, text)
  trigger.action.markToAll(RAT.markerid, text1, vec)
end

--- Delete all markers on F10 map.
-- @param #RAT self
function RAT:_DeleteMarkers()
  for k,v in ipairs(self.markerids) do
    trigger.action.removeMark(v)
  end
  for k,v in ipairs(self.markerids) do
    self.markerids[k]=nil
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Modifies the template of the group to be spawned.
-- In particular, the waypoints of the group's flight plan are copied into the spawn template.
-- This allows to spawn at airports and also land at other airports, i.e. circumventing the DCS "landing bug".
-- @param #RAT self
-- @param #table waypoints The waypoints of the AI flight plan.
function RAT:_ModifySpawnTemplate(waypoints)

  -- The 3D vector of the first waypoint, i.e. where we actually spawn the template group.
  local PointVec3 = {x=waypoints[1].x, y=waypoints[1].alt, z=waypoints[1].y}
  
  -- Heading from first to seconds waypoints to align units in case of air start.
  local heading = self:_Course(waypoints[1], waypoints[2])
  
  -- Set (another) livery.
  local skin=nil
  if self.livery then
    if self.debug then
      for _, skin in pairs(self.livery) do
        env.info(RAT.id.."Possible livery: "..skin.." for group "..self:_AnticipatedGroupName())
      end
    end
    skin=self.livery[math.random(#self.livery)]
    env.info(RAT.id.."Chosen livery: "..skin.." for group "..self:_AnticipatedGroupName())
  end

  if self:_GetSpawnIndex(self.SpawnIndex+1) then
  
    local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
  
    if SpawnTemplate then
      self:T(SpawnTemplate)
        
      -- Translate the position of the Group Template to the Vec3.
      for UnitID = 1, #SpawnTemplate.units do
        self:T('Before Translation SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
        
        -- Tranlate position.
        local UnitTemplate = SpawnTemplate.units[UnitID]
        local SX = UnitTemplate.x
        local SY = UnitTemplate.y 
        local BX = SpawnTemplate.route.points[1].x
        local BY = SpawnTemplate.route.points[1].y
        local TX = PointVec3.x + (SX-BX)
        local TY = PointVec3.z + (SY-BY)
        SpawnTemplate.units[UnitID].x   = TX
        SpawnTemplate.units[UnitID].y   = TY
        SpawnTemplate.units[UnitID].alt = PointVec3.y
        SpawnTemplate.units[UnitID].heading = math.rad(heading)
        
        -- Set livery (will be the same for all units of the group).
        if skin then
          SpawnTemplate.units[UnitID].livery_id = skin
        end
        
        -- Set type of aircraft.
        if self.actype then
          SpawnTemplate.units[UnitID]["type"] = self.actype
        end
        
        -- Set AI skill.
        SpawnTemplate.units[UnitID]["skill"] = self.skill
        
        -- Onboard number.
        SpawnTemplate.units[UnitID]["onboard_num"] = self.SpawnIndex
        
        -- Modify coaltion and country of template.
        SpawnTemplate.CoalitionID=self.coalition
        if self.country then
          SpawnTemplate.CountryID=self.country
        end
        
        -- Parking spot.
        UnitTemplate.parking = nil
        UnitTemplate.parking_id = self.parking_id
        --env.info(RAT.id.."Parking ID "..tostring(self.parking_id))
        
        -- Initial altitude
        UnitTemplate.alt=PointVec3.y
        
        self:T('After Translation SpawnTemplate.units['..UnitID..'].x = '..SpawnTemplate.units[UnitID].x..', SpawnTemplate.units['..UnitID..'].y = '..SpawnTemplate.units[UnitID].y)
        
      end
      
      -- Copy waypoints into spawntemplate. By this we avoid the nasty DCS "landing bug" :)
      for i,wp in ipairs(waypoints) do
        SpawnTemplate.route.points[i]=wp
      end
      
      -- Also modify x,y of the template. Not sure why.
      SpawnTemplate.x = PointVec3.x
      SpawnTemplate.y = PointVec3.z
      
      -- Enable/disable radio. Same as checking the COMM box in the ME
      if self.radio then
        SpawnTemplate.communication=self.radio
      end
      
      -- Set radio frequency and modulation.
      if self.frequency then
        SpawnTemplate.frequency=self.frequency
      end
      if self.modulation then
        SpawnTemplate.modulation=self.modulation
      end
      
      --SpawnTemplate.uncontrolled=true
      
      -- Update modified template for spawn group.
      --self.SpawnGroups[self.SpawnIndex].SpawnTemplate=SpawnTemplate
      
      self:T(SpawnTemplate)        
    end
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Initializes the ATC arrays and starts schedulers.
-- @param #RAT self
-- @param #table airports_map List of all airports of the map.
function RAT:_ATCInit(airports_map)
  if not RAT.ATC.init then
    env.info(RAT.id.."Starting RAT ATC.")
    env.info(RAT.id.."Simultanious = "..RAT.ATC.Nclearance)
    env.info(RAT.id.."Delay        = "..RAT.ATC.delay)
    RAT.ATC.init=true
    for _,ap in pairs(airports_map) do
      local name=ap:GetName()
      RAT.ATC.airport[name]={}
      RAT.ATC.airport[name].queue={}
      RAT.ATC.airport[name].busy=false
      RAT.ATC.airport[name].onfinal={}
      RAT.ATC.airport[name].Nonfinal=0
      RAT.ATC.airport[name].traffic=0
      RAT.ATC.airport[name].Tlastclearance=nil
    end
    SCHEDULER:New(nil, RAT._ATCCheck, {self}, 5, 15)
    SCHEDULER:New(nil, RAT._ATCStatus, {self}, 5, 60)
    RAT.ATC.T0=timer.getTime()
  end
end

--- Adds andd initializes a new flight after it was spawned.
-- @param #RAT self
-- @param #string name Group name of the flight.
-- @param #string dest Name of the destination airport.
function RAT:_ATCAddFlight(name, dest)
  env.info(string.format("%sATC %s: Adding flight %s with destination %s.", RAT.id, dest, name, dest))
  RAT.ATC.flight[name]={}
  RAT.ATC.flight[name].destination=dest
  RAT.ATC.flight[name].Tarrive=-1
  RAT.ATC.flight[name].holding=-1
  RAT.ATC.flight[name].Tonfinal=-1
end

--- Deletes a flight from ATC lists after it landed.
-- @param #RAT self
-- @param #table t Table.
-- @param #string entry Flight name which shall be deleted.
function RAT:_ATCDelFlight(t,entry)
  for k,_ in pairs(t) do
    if k==entry then
      t[entry]=nil
    end
  end
end

--- Registers a flight once it is near its holding point at the final destination.
-- @param #RAT self
-- @param #string name Group name of the flight.
-- @param #number time Time the fight first registered.
function RAT:_ATCRegisterFlight(name, time)
  env.info(RAT.id.."Flight ".. name.." registered at ATC for landing clearance.")
  RAT.ATC.flight[name].Tarrive=time
  RAT.ATC.flight[name].holding=0
end


--- ATC status report about flights.
-- @param #RAT self
function RAT:_ATCStatus()

  -- Current time.
  local Tnow=timer.getTime()
   
  for name,_ in pairs(RAT.ATC.flight) do

    -- Holding time at destination.
    local hold=RAT.ATC.flight[name].holding
    local dest=RAT.ATC.flight[name].destination
    
    if hold >= 0 then
    
      -- Some string whether the runway is busy or not.
      local busy="Runway state is unknown"
      if RAT.ATC.airport[dest].Nonfinal>0 then
        busy="Runway is occupied by "..RAT.ATC.airport[dest].Nonfinal
      else
        busy="Runway is currently clear"
      end
      
      -- Aircraft is holding.
      local text=string.format("STATUS: ATC %s: Flight %s is holding for %i:%02d. %s.", dest, name, hold/60, hold%60, busy)
      env.info(RAT.id..text)
      
    elseif hold==RAT.ATC.onfinal then
    
      -- Aircarft is on final approach for landing.
      local Tfinal=Tnow-RAT.ATC.flight[name].Tonfinal
      
      local text=string.format("STATUS: ATC %s: Flight %s is on final. Waiting %i:%02d for landing event.", dest, name, Tfinal/60, Tfinal%60)
      env.info(RAT.id..text)
      
    elseif hold==RAT.ATC.unregistered then
    
      -- Aircraft has not arrived at holding point.
      --env.info(string.format("ATC %s: Flight %s is not registered yet (hold %d).", dest, name, hold))
      
    else
      env.error(RAT.id.."Unknown holding time in RAT:_ATCStatus().")
    end
  end
  
end

--- Main ATC function. Updates the landing queue of all airports and inceases holding time for all flights.
-- @param #RAT self
function RAT:_ATCCheck()

  -- Init queue of flights at all airports.
  RAT:_ATCQueue()
  
  -- Current time.
  local Tnow=timer.getTime()
  
  for name,_ in pairs(RAT.ATC.airport) do
    
    for qID,flight in ipairs(RAT.ATC.airport[name].queue) do
    
      -- Number of aircraft in queue.
      local nqueue=#RAT.ATC.airport[name].queue
    
      -- Conditions to clear an aircraft for landing
      local landing1
      if RAT.ATC.airport[name].Tlastclearance then
        -- Landing if time is enough and less then two planes are on final.
        landing1=(Tnow-RAT.ATC.airport[name].Tlastclearance > RAT.ATC.delay) and RAT.ATC.airport[name].Nonfinal < RAT.ATC.Nclearance
      else
        landing1=false
      end
      -- No other aircraft is on final.
      local landing2=RAT.ATC.airport[name].Nonfinal==0


      if not landing1 and not landing2 then
      
        -- Update holding time.
        RAT.ATC.flight[flight].holding=Tnow-RAT.ATC.flight[flight].Tarrive
        
        -- Debug message.
        local text=string.format("CHECK: ATC %s: Flight %s runway is busy. You are #%d of %d in landing queue. Your holding time is %i:%02d.", name, flight,qID, nqueue, RAT.ATC.flight[flight].holding/60, RAT.ATC.flight[flight].holding%60)
        env.info(RAT.id..text)
        
      else
      
        local text=string.format("CHECK: ATC %s: Flight %s was cleared for landing. Your holding time was %i:%02d.", name, flight, RAT.ATC.flight[flight].holding/60, RAT.ATC.flight[flight].holding%60)
        env.info(RAT.id..text)
      
        -- Clear flight for landing.
        RAT:_ATCClearForLanding(name, flight)
        
      end
      
    end
        
  end
  
  -- Update queue of flights at all airports.
  RAT:_ATCQueue()
  
end

--- Giving landing clearance for aircraft by setting user flag.
-- @param #RAT self
-- @param #string airport Name of destination airport.
-- @param #string flight Group name of flight, which gets landing clearence.
function RAT:_ATCClearForLanding(airport, flight)
  -- Flight is cleared for landing.
  RAT.ATC.flight[flight].holding=RAT.ATC.onfinal
  -- Airport runway is busy now.
  RAT.ATC.airport[airport].busy=true
  -- Flight which is landing.
  RAT.ATC.airport[airport].onfinal[flight]=flight
  -- Number of planes on final approach.
  RAT.ATC.airport[airport].Nonfinal=RAT.ATC.airport[airport].Nonfinal+1
  -- Last time an aircraft got landing clearance.
  RAT.ATC.airport[airport].Tlastclearance=timer.getTime()  
  -- Current time.
  RAT.ATC.flight[flight].Tonfinal=timer.getTime()
  -- Set user flag to 1 ==> stop condition for holding.
  trigger.action.setUserFlag(flight, 1)
  local flagvalue=trigger.misc.getUserFlag(flight)
  
  -- Debug message.
  local text1=string.format("ATC %s: Flight %s cleared for landing (flag=%d).", airport, flight, flagvalue)
  local text2=string.format("ATC %s: Flight %s you are cleared for landing.", airport, flight)
  env.info( RAT.id..text1)
  MESSAGE:New(text2, 10):ToAll()
end

--- Takes care of organisational stuff after a plane has landed.
-- @param #RAT self
-- @param #string name Group name of flight.
function RAT:_ATCFlightLanded(name)

  if RAT.ATC.flight[name] then
  
    -- Destination airport.
    local dest=RAT.ATC.flight[name].destination
    
    -- Times for holding and final approach.
    local Tnow=timer.getTime()
    local Tfinal=Tnow-RAT.ATC.flight[name].Tonfinal
    local Thold=RAT.ATC.flight[name].Tonfinal-RAT.ATC.flight[name].Tarrive
    
    -- Airport is not busy any more.
    RAT.ATC.airport[dest].busy=false
    
    -- No aircraft on final any more.
    RAT.ATC.airport[dest].onfinal[name]=nil
    
    -- Decrease number of aircraft on final.
    RAT.ATC.airport[dest].Nonfinal=RAT.ATC.airport[dest].Nonfinal-1
    
    -- Remove this flight from list of flights.
    RAT:_ATCDelFlight(RAT.ATC.flight, name)
    
    -- Increase landing counter to monitor traffic.
    RAT.ATC.airport[dest].traffic=RAT.ATC.airport[dest].traffic+1
    
    -- Number of planes landing per hour.
    local TrafficPerHour=RAT.ATC.airport[dest].traffic/(timer.getTime()-RAT.ATC.T0)*3600
    
    -- Debug info
    local text1=string.format("ATC %s: Flight %s landed. Tholding = %i:%02d, Tfinal = %i:%02d.", dest, name, Thold/60, Thold%60, Tfinal/60, Tfinal%60)
    local text2=string.format("ATC %s: Number of flights still on final %d.", dest, RAT.ATC.airport[dest].Nonfinal)
    local text3=string.format("ATC %s: Traffic report: Number of planes landed in total %d. Flights/hour = %3.2f.", dest, RAT.ATC.airport[dest].traffic, TrafficPerHour)
    local text4=string.format("ATC %s: Flight %s landed. Welcome to %s.", dest, name, dest)
    env.info(RAT.id..text1)
    env.info(RAT.id..text2)
    env.info(RAT.id..text3)
    MESSAGE:New(text4, 10):ToAll()
  end
  
end

--- Creates a landing queue for all flights holding at airports. Aircraft with longest holding time gets first permission to land.
-- @param #RAT self
function RAT:_ATCQueue()

  for airport,_ in pairs(RAT.ATC.airport) do
  
    -- Local airport queue.
    local _queue={}

    -- Loop over all flights.
    for name,_ in pairs(RAT.ATC.flight) do
      --fvh
      local Tnow=timer.getTime()
      
      -- Update holding time (unless holing is set to onfinal=-100)
      if RAT.ATC.flight[name].holding>=0 then
        RAT.ATC.flight[name].holding=Tnow-RAT.ATC.flight[name].Tarrive
      end
      local hold=RAT.ATC.flight[name].holding
      local dest=RAT.ATC.flight[name].destination
      
      -- Flight is holding at this airport.
      if hold>=0 and airport==dest then
        _queue[#_queue+1]={name,hold}
      end
    end
    
    -- Sort queue w.r.t holding time in ascending order.
    local function compare(a,b)
      return a[2] > b[2]
    end
    table.sort(_queue, compare)
    
    -- Transfer queue to airport queue.
    RAT.ATC.airport[airport].queue={}
    for k,v in ipairs(_queue) do
      table.insert(RAT.ATC.airport[airport].queue, v[1])
    end
    
    --fvh
    --for k,v in ipairs(RAT.ATC.airport[airport].queue) do
      --print(string.format("queue #%02i flight \"%s\" holding %d seconds",k, v, RAT.ATC.flight[v].holding))
    --end
    
  end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
