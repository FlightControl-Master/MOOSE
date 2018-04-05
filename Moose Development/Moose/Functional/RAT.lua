-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- **Functional** - (R2.2) - Create random airtraffic in your missions.
-- 
-- ===
-- 
-- ![Banner Image](..\Presentations\RAT\RAT.png)
-- 
-- ===
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
--  The RAT class creates an entry in the F10 radio menu which allows to
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
-- ===
-- 
-- # Demo Missions
--
-- ### [RAT Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/Release/RAT%20-%20Random%20Air%20Traffic)
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ===
-- 
-- # YouTube Channel
-- 
-- ### [DCS WORLD - MOOSE - RAT - Random Air Traffic](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl0u4Zxywtg-mx_ov4vi68CO)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: **Sven van de Velde ([FlightControl](https://forums.eagle.ru/member.php?u=89536))**
-- 
-- ===
-- @module Rat

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- RAT class
-- @type RAT
-- @field #string ClassName Name of the Class.
-- @field #boolean Debug Turn debug messages on or off.
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
-- @field #number takeoff Takeoff type. 0=coldorhot.
-- @field #number landing Landing type. Determines if we actually land at an airport or treat it as zone.
-- @field #number mindist Min distance from departure to destination in meters. Default 5 km.
-- @field #number maxdist Max distance from departure to destination in meters. Default 5000 km.
-- @field #table airports_map All airports available on current map (Caucasus, Nevada, Normandy, ...).
-- @field #table airports All airports of friedly coalitions.
-- @field #boolean random_departure By default a random friendly airport is chosen as departure.
-- @field #boolean random_destination By default a random friendly airport is chosen as destination.
-- @field #table departure_ports Array containing the names of the destination airports or zones.
-- @field #table destination_ports Array containing the names of the destination airports or zones.
-- @field #number Ndestination_Airports Number of destination airports set via SetDestination().
-- @field #number Ndestination_Zones Number of destination zones set via SetDestination().
-- @field #number Ndeparture_Airports Number of departure airports set via SetDeparture().
-- @field #number Ndeparture_Zones Number of departure zones set via SetDeparture.
-- @field #table excluded_ports Array containing the names of explicitly excluded airports.
-- @field #boolean destinationzone Destination is a zone and not an airport.
-- @field #table return_zones Array containing the names of the return zones.
-- @field #boolean returnzone Zone where aircraft will fly to before returning to their departure airport.
-- @field Core.Zone#ZONE departure_Azone Zone containing the departure airports.
-- @field Core.Zone#ZONE destination_Azone Zone containing the destination airports.
-- @field #boolean addfriendlydepartures Add all friendly airports to departures.
-- @field #boolean addfriendlydestinations Add all friendly airports to destinations.
-- @field #table ratcraft Array with the spawned RAT aircraft.
-- @field #number Tinactive Time in seconds after which inactive units will be destroyed. Default is 300 seconds.
-- @field #boolean reportstatus Aircraft report status.
-- @field #number statusinterval Intervall between status checks (and reports if enabled).
-- @field #boolean placemarkers Place markers of waypoints on F10 map.
-- @field #number FLcruise Cruise altitude of aircraft. Default FL200 for planes and F005 for helos.
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
-- @field #boolean respawn_after_crash Aircraft will be respawned after a crash, e.g. when they get shot down.
-- @field #boolean respawn_inair Aircraft are allowed to spawned in air if they cannot be respawned on ground because there is not free parking spot. Default is true.
-- @field #number respawn_delay Delay in seconds until a repawn happens.
-- @field #table markerids Array with marker IDs.
-- @field #table waypointdescriptions Table with strings for waypoint descriptions of markers.
-- @field #table waypointstatus Table with strings of waypoint status.
-- @field #string livery Livery of the aircraft set by user.
-- @field #string skill Skill of AI.
-- @field #boolean ATCswitch Enable/disable ATC if set to true/false.
-- @field #string parking_id String with a special parking ID for the aircraft.
-- @field #boolean radio If true/false disables radio messages from the RAT groups.
-- @field #number frequency Radio frequency used by the RAT groups.
-- @field #string modulation Ratio modulation. Either "FM" or "AM".
-- @field #boolean uncontrolled If true aircraft are spawned in uncontrolled state and will only sit on their parking spots. They can later be activated.
-- @field #boolean invisible If true aircraft are set to invisible for other AI forces.
-- @field #boolean immortal If true, aircraft are spawned as immortal.
-- @field #boolean activate_uncontrolled If true, uncontrolled are activated randomly after certain time intervals.
-- @field #number activate_delay Delay in seconds before first uncontrolled group is activated. Default is 5 seconds.
-- @field #number activate_delta Time interval in seconds between activation of uncontrolled groups. Default is 5 seconds.
-- @field #number activate_frand Randomization factor of time interval (activate_delta) between activating uncontrolled groups. Default is 0.
-- @field #number activate_max Maximum number of uncontrolled aircraft, which will be activated at the same time. Default is 1.
-- @field #string onboardnum Sets the onboard number prefix. Same as setting "TAIL #" in the mission editor.
-- @field #number onboardnum0 (Optional) Starting value of the automatically appended numbering of aircraft within a flight. Default is 1.
-- @field #boolean checkonrunway Aircraft are checked if they were accidentally spawned on the runway. Default is true.
-- @field #boolean checkontop Aircraft are checked if they were accidentally spawned on top of another unit. Default is true.
-- @field #number rbug_maxretry Number of respawn retries (on ground) at other airports if a group gets accidentally spawned on the runway. Default is 3.
-- @field #boolean useparkingdb Parking spots are added to data base once an aircraft has used it. These spots can later be used by other aircraft. Default is true.
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
  Debug=false,              -- Turn debug messages on or off.
  templategroup=nil,        -- Template group for the RAT aircraft.
  alias=nil,                -- Alias for spawned group.
  spawninitialized=false,   -- If RAT:Spawn() was already called this is set to true to prevent users to call it again.
  spawndelay=5,             -- Delay time in seconds before first spawning happens.
  spawninterval=5,          -- Interval between spawning units/groups. Note that we add a randomization of 50%.
  coalition = nil,          -- Coalition of spawn group template.
  country = nil,            -- Country of the group template.
  category = nil,           -- Category of aircarft: "plane" or "heli".
  friendly = "same",        -- Possible departure/destination airport: same=spawn+neutral, spawnonly=spawn, blue=blue+neutral, blueonly=blue, red=red+neutral, redonly=red, neutral.
  ctable = {},              -- Table with the valid coalitons from choice self.friendly.
  aircraft = {},            -- Table which holds the basic aircraft properties (speed, range, ...).
  Vcruisemax=nil,           -- Max cruise speed in set by user.
  Vclimb=1500,              -- Default climb rate in ft/min.
  AlphaDescent=3.6,         -- Default angle of descenti in degrees. A value of 3.6 follows the 3:1 rule of 3 miles of travel and 1000 ft descent.
  roe = "hold",             -- ROE of spawned groups, default is weapon hold (this is a peaceful class for civil aircraft or ferry missions). Possible: "hold", "return", "free".
  rot = "noreaction",       -- ROT of spawned groups, default is no reaction. Possible: "noreaction", "passive", "evade".
  takeoff = 0,              -- Takeoff type. 0=coldorhot.
  landing = 9,              -- Landing type. 9=landing.
  mindist = 5000,           -- Min distance from departure to destination in meters. Default 5 km.
  maxdist = 5000000,        -- Max distance from departure to destination in meters. Default 5000 km.
  airports_map={},          -- All airports available on current map (Caucasus, Nevada, Normandy, ...).
  airports={},              -- All airports of friedly coalitions.
  random_departure=true,    -- By default a random friendly airport is chosen as departure.
  random_destination=true,  -- By default a random friendly airport is chosen as destination.
  departure_ports={},       -- Array containing the names of the departure airports or zones.
  destination_ports={},     -- Array containing the names of the destination airports or zones.
  Ndestination_Airports=0,  -- Number of destination airports set via SetDestination().
  Ndestination_Zones=0,     -- Number of destination zones set via SetDestination().
  Ndeparture_Airports=0,    -- Number of departure airports set via SetDeparture().
  Ndeparture_Zones=0,       -- Number of departure zones set via SetDeparture.
  destinationzone=false,    -- Destination is a zone and not an airport.
  return_zones={},          -- Array containing the names of return zones.
  returnzone=false,         -- Aircraft will fly to a zone and back.
  excluded_ports={},        -- Array containing the names of explicitly excluded airports.
  departure_Azone=nil,      -- Zone containing the departure airports.
  destination_Azone=nil,    -- Zone containing the destination airports.
  addfriendlydepartures=false,   -- Add all friendly airports to departures.
  addfriendlydestinations=false, -- Add all friendly airports to destinations.
  ratcraft={},              -- Array with the spawned RAT aircraft.
  Tinactive=600,            -- Time in seconds after which inactive units will be destroyed. Default is 600 seconds.
  reportstatus=false,       -- Aircraft report status.
  statusinterval=30,        -- Intervall between status checks (and reports if enabled).
  placemarkers=false,       -- Place markers of waypoints on F10 map.
  FLcruise=nil,             -- Cruise altitude of aircraft. Default FL200 for planes and F005 for helos.
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
  respawn_after_crash=true, -- Aircraft will be respawned after a crash.
  respawn_inair=true,        -- Aircraft are spawned in air if there is no free parking spot on the ground.
  respawn_delay=nil,        -- Delay in seconds until repawn happens after landing.
  markerids={},             -- Array with marker IDs.
  waypointdescriptions={},  -- Array with descriptions for waypoint markers.
  waypointstatus={},        -- Array with status info on waypoints.
  livery=nil,               -- Livery of the aircraft.
  skill="High",             -- Skill of AI.
  ATCswitch=true,           -- Enable ATC.
  parking_id=nil,           -- Specific parking ID when aircraft are spawned at airports.
  radio=nil,                -- If true/false disables radio messages from the RAT groups.
  frequency=nil,            -- Radio frequency used by the RAT groups.
  modulation=nil,           -- Ratio modulation. Either "FM" or "AM".
  actype=nil,               -- Aircraft type set by user. Changes the type of the template group.
  uncontrolled=false,       -- Spawn uncontrolled aircraft.
  invisible=false,          -- Spawn aircraft as invisible.
  immortal=false,           -- Spawn aircraft as indestructible.
  activate_uncontrolled=false, -- Activate uncontrolled aircraft (randomly). 
  activate_delay=5,         -- Delay in seconds before first uncontrolled group is activated.
  activate_delta=5,         -- Time interval in seconds between activation of uncontrolled groups.
  activate_frand=0,         -- Randomization factor of time interval (activate_delta) between activating uncontrolled groups.
  activate_max=1,           -- Max number of uncontrolle aircraft, which will be activated at a time. 
  onboardnum=nil,           -- Tail number.
  onboardnum0=1,            -- (Optional) Starting value of the automatically appended numbering of aircraft within a flight. Default is one.
  rbug_maxretry=3,          -- Number of respawn retries (on ground) at other airports if a group gets accidentally spawned on the runway.
  checkonrunway=true,       -- Check whether aircraft have been spawned on the runway.
  checkontop=true,          -- Check whether aircraft have been spawned on top of another unit.
  useparkingdb=true,        -- Put known parking spots into a data base.
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
  -- Spawn states.
  Uncontrolled="Uncontrolled",
  Spawned="Spawned",
  -- Event states.
  EventBirthAir="Born in air",
  EventBirth="Ready and starting engines",
  EventEngineStartAir="On journey", -- Started engines (in air)
  EventEngineStart="Started engines and taxiing",
  EventTakeoff="Airborne after take-off",
  EventLand="Landed and taxiing",
  EventEngineShutdown="Engines off",
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

--- RAT ATC.
-- @list ATC
RAT.ATC={
  init=false,
  flight={},
  airport={},
  unregistered=-1,
  onfinal=-100,
  Nclearance=2,
  delay=240,
  messages=true,
}

--- Running number of placed markers on the F10 map.
-- @field #number markerid
RAT.markerid=0

--- Main F10 menu.
-- @field #string MenuF10
RAT.MenuF10=nil

--- RAT parking spots data base.
-- @list parking
RAT.parking={}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
RAT.id="RAT | "

--- RAT version.
-- @list version
RAT.version={
  version = "2.2.1",
  print = true,
}


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
--DONE: Add function to include all airports to selected destinations/departures.
--DONE: Find way to respawn aircraft at same position where the last was despawned for commute and journey.
--TODO: Check that same alias is not given twice. Need to store previous ones and compare.

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
  BASE:F({groupname=groupname, alias=alias})

  -- Inherit SPAWN class.
  self=BASE:Inherit(self, SPAWN:NewWithAlias(groupname, alias)) -- #RAT

  -- Version info.
  if RAT.version.print then
    env.info(RAT.id.."Version "..RAT.version.version)
    RAT.version.print=false
  end

  -- Welcome message.
  self:F(RAT.id.."Creating new RAT object from template: "..groupname)
  
  -- Set alias.
  alias=alias or groupname
  
  -- Alias of groupname.
  self.alias=alias
  
  -- Get template group defined in the mission editor.
  local DCSgroup=Group.getByName(groupname)
  
  -- Check the group actually exists.
  if DCSgroup==nil then
    self:E(RAT.id.."ERROR: Group with name "..groupname.." does not exist in the mission editor!")
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
    self:E("ERROR: Spawn function should only be called once per RAT object! Exiting and returning nil.")
    return nil
  else
    self.spawninitialized=true
  end

  -- Number of aircraft to spawn. Default is one.
  self.ngroups=naircraft or 1
  
  -- Init RAT ATC if not already done.
  if self.ATCswitch and not RAT.ATC.init then
    self:_ATCInit(self.airports_map)
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
  
  -- Add all friendly airports to possible departures/destinations
  if self.addfriendlydepartures then
    self:_AddFriendlyAirports(self.departure_ports)
  end
  if self.addfriendlydestinations then
    self:_AddFriendlyAirports(self.destination_ports)
  end  
  
  -- Setting and possibly correction min/max/cruise flight levels.
  if self.FLcruise==nil then
    -- Default flight level (ASL).
    if self.category==RAT.cat.plane then
      -- For planes: FL200 = 20000 ft = 6096 m.
      self.FLcruise=200*RAT.unit.FL2m
    else
      -- For helos: FL005 = 500 ft = 152 m.
      self.FLcruise=005*RAT.unit.FL2m
    end
  end
  
  -- Run consistency checks.
  self:_CheckConsistency()

  -- Settings info
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Spawning %i aircraft from template %s of type %s.\n", self.ngroups, self.SpawnTemplatePrefix, self.aircraft.type)
  text=text..string.format("Alias: %s\n", self.alias)
  text=text..string.format("Category: %s\n", self.category)
  text=text..string.format("Friendly coalitions: %s\n", self.friendly)
  text=text..string.format("Number of airports on map  : %i\n", #self.airports_map)
  text=text..string.format("Number of friendly airports: %i\n", #self.airports)
  text=text..string.format("Totally random departure: %s\n", tostring(self.random_departure))
  if not self.random_departure then
    text=text..string.format("Number of departure airports: %d\n", self.Ndeparture_Airports)
    text=text..string.format("Number of departure zones   : %d\n", self.Ndeparture_Zones)
  end
  text=text..string.format("Totally random destination: %s\n", tostring(self.random_destination))
  if not self.random_destination then
    text=text..string.format("Number of destination airports: %d\n", self.Ndestination_Airports)
    text=text..string.format("Number of destination zones   : %d\n", self.Ndestination_Zones)
  end
  text=text..string.format("Min dist to destination: %4.1f\n", self.mindist)
  text=text..string.format("Max dist to destination: %4.1f\n", self.maxdist)
  text=text..string.format("Takeoff type: %i\n", self.takeoff)
  text=text..string.format("Landing type: %i\n", self.landing)
  text=text..string.format("Commute: %s\n", tostring(self.commute))
  text=text..string.format("Journey: %s\n", tostring(self.continuejourney))
  text=text..string.format("Destination Zone: %s\n", tostring(self.destinationzone))
  text=text..string.format("Return Zone: %s\n", tostring(self.returnzone))
  text=text..string.format("Spawn delay: %4.1f\n", self.spawndelay)
  text=text..string.format("Spawn interval: %4.1f\n", self.spawninterval)
  text=text..string.format("Respawn delay: %s\n", tostring(self.respawn_delay))  
  text=text..string.format("Respawn off: %s\n", tostring(self.norespawn))
  text=text..string.format("Respawn after landing: %s\n", tostring(self.respawn_at_landing))
  text=text..string.format("Respawn after take-off: %s\n", tostring(self.respawn_after_takeoff))
  text=text..string.format("Respawn after crash: %s\n", tostring(self.respawn_after_crash))
  text=text..string.format("Respawn in air: %s\n", tostring(self.respawn_inair))
  text=text..string.format("ROE: %s\n", tostring(self.roe))
  text=text..string.format("ROT: %s\n", tostring(self.rot))
  text=text..string.format("Immortal: %s\n", tostring(self.immortal))
  text=text..string.format("Invisible: %s\n", tostring(self.invisible))
  text=text..string.format("Vclimb: %4.1f\n", self.Vclimb)
  text=text..string.format("AlphaDescent: %4.2f\n", self.AlphaDescent)
  text=text..string.format("Vcruisemax: %s\n", tostring(self.Vcruisemax))
  text=text..string.format("FLcruise =  %6.1f km = FL%3.0f\n", self.FLcruise/1000, self.FLcruise/RAT.unit.FL2m)
  text=text..string.format("FLuser: %s\n", tostring(self.Fluser))
  text=text..string.format("FLminuser: %s\n", tostring(self.FLminuser))
  text=text..string.format("FLmaxuser: %s\n", tostring(self.FLmaxuser))
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
  text=text..string.format("Tail # prefix    : %s\n", tostring(self.onboardnum))
  text=text..string.format("Check on runway: %s\n", tostring(self.checkonrunway))
  text=text..string.format("Check on top: %s\n", tostring(self.checkontop))
  text=text..string.format("Max respawn attempts: %s\n", tostring(self.rbug_maxretry))
  text=text..string.format("Parking DB: %s\n", tostring(self.useparkingdb))
  text=text..string.format("Uncontrolled: %s\n", tostring(self.uncontrolled))
  if self.uncontrolled and self.activate_uncontrolled then
    text=text..string.format("Uncontrolled max  : %4.1f\n", self.activate_max)
    text=text..string.format("Uncontrolled delay: %4.1f\n", self.activate_delay)
    text=text..string.format("Uncontrolled delta: %4.1f\n", self.activate_delta)
    text=text..string.format("Uncontrolled frand: %4.1f\n", self.activate_frand)
  end
  if self.livery then
    text=text..string.format("Available liveries:\n")
    for _,livery in pairs(self.livery) do
      text=text..string.format("- %s\n", livery)
    end
  end
  text=text..string.format("******************************************************\n")
  self:T(RAT.id..text)
  
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
    
  -- Status check and report scheduler.
  SCHEDULER:New(nil, self.Status, {self}, Tstart+1, self.statusinterval)
  
  -- Handle events.
  self:HandleEvent(EVENTS.Birth,          self._OnBirth)
  self:HandleEvent(EVENTS.EngineStartup,  self._OnEngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self._OnTakeoff)
  self:HandleEvent(EVENTS.Land,           self._OnLand)
  self:HandleEvent(EVENTS.EngineShutdown, self._OnEngineShutdown)
  self:HandleEvent(EVENTS.Dead,           self._OnDeadOrCrash)
  self:HandleEvent(EVENTS.Crash,          self._OnDeadOrCrash)
  self:HandleEvent(EVENTS.Hit,            self._OnHit)

  -- No groups should be spawned.
  if self.ngroups==0 then
    return nil
  end
  
  -- Start scheduled spawning.
  SCHEDULER:New(nil, self._SpawnWithRoute, {self}, Tstart, dt, 0.0, Tstop)
  
  -- Start scheduled activation of uncontrolled groups.
  if self.uncontrolled and self.activate_uncontrolled then
    SCHEDULER:New(nil, self._ActivateUncontrolled, {self}, self.activate_delay, self.activate_delta, self.activate_frand)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function checks consistency of user input and automatically adjusts parameters if necessary.
-- @param #RAT self
function RAT:_CheckConsistency()
  self:F2()

  -- User has used SetDeparture()
  if not self.random_departure then
  
    -- Count departure airports and zones.
    for _,name in pairs(self.departure_ports) do
      if self:_AirportExists(name) then
        self.Ndeparture_Airports=self.Ndeparture_Airports+1
      elseif self:_ZoneExists(name) then
        self.Ndeparture_Zones=self.Ndeparture_Zones+1
      end
    end
  
    -- What can go wrong?
    -- Only zones but not takeoff air == > Enable takeoff air.
    if self.Ndeparture_Zones>0 and self.takeoff~=RAT.wp.air then
      self.takeoff=RAT.wp.air
      self:E(RAT.id.."ERROR: At least one zone defined as departure and takeoff is NOT set to air. Enabling air start!")
    end
    -- No airport and no zone specified.
    if self.Ndeparture_Airports==0 and self.Ndeparture_Zone==0 then
      self.random_departure=true
      local text="No airports or zones found given in SetDeparture(). Enabling random departure airports!"
      self:E(RAT.id.."ERROR: "..text)
      MESSAGE:New(text, 30):ToAll()
    end
  end

  -- User has used SetDestination()
  if not self.random_destination then
  
    -- Count destination airports and zones.
    for _,name in pairs(self.destination_ports) do
      if self:_AirportExists(name) then
        self.Ndestination_Airports=self.Ndestination_Airports+1
      elseif self:_ZoneExists(name) then
        self.Ndestination_Zones=self.Ndestination_Zones+1
      end
    end  
  
    -- One zone specified as destination ==> Enable destination zone.
    -- This does not apply to return zone because the destination is the zone and not the final destination which can be an airport. 
    if self.Ndestination_Zones>0 and self.landing~=RAT.wp.air and not self.returnzone then
      self.landing=RAT.wp.air
      self.destinationzone=true
      self:E(RAT.id.."ERROR: At least one zone defined as destination and landing is NOT set to air. Enabling destination zone!")
    end
    -- No specified airport and no zone found at all.
    if self.Ndestination_Airports==0 and self.Ndestination_Zones==0 then
      self.random_destination=true
      local text="No airports or zones found given in SetDestination(). Enabling random destination airports!"
      self:E(RAT.id.."ERROR: "..text)
      MESSAGE:New(text, 30):ToAll()
    end
  end  
    
  -- Destination zone and return zone should not be used together.
  if self.destinationzone and self.returnzone then
    self:E(RAT.id.."ERROR: Destination zone _and_ return to zone not possible! Disabling return to zone.")
    self.returnzone=false
  end
  -- If returning to a zone, we set the landing type to "air" if takeoff is in air. 
  -- Because if we start in air we want to end in air. But default landing is ground.
  if self.returnzone and self.takeoff==RAT.wp.air then
    self.landing=RAT.wp.air
  end
    
  -- Ensure that neither FLmin nor FLmax are above the aircrafts service ceiling.
  if self.FLminuser then
    self.FLminuser=math.min(self.FLminuser, self.aircraft.ceiling)
  end
  if self.FLmaxuser then
    self.FLmaxuser=math.min(self.FLmaxuser, self.aircraft.ceiling)
  end
  if self.FLcruise then
    self.FLcruise=math.min(self.FLcruise, self.aircraft.ceiling)
  end
  
  -- FL min > FL max case ==> spaw values
  if self.FLminuser and self.FLmaxuser then
    if self.FLminuser > self.FLmaxuser then
      local min=self.FLminuser
      local max=self.FLmaxuser
      self.FLminuser=max
      self.FLmaxuser=min    
    end
  end
    
  -- Cruise alt < FL min
  if self.FLminuser and self.FLcruise<self.FLminuser then
    -- Here we have two possibilities.
    -- 1) Set cruise alt to min FL, i.e. shift cruise alt up.
    -- 2) Set min FL to cruise alt, i.e. shift min FL down.
    self.FLcruise=self.FLminuser
  end
  
  -- Cruise alt > FL max
  if self.FLmaxuser and self.FLcruise>self.FLmaxuser then
    self.FLcruise=self.FLmaxuser
  end
  
  -- Uncontrolled aircraft must start with engines off.
  if self.uncontrolled then
    -- SOLVED: Strangly, it does not work with RAT.wp.cold only with RAT.wp.hot!
    -- Figured out why. SPAWN:SpawnWithIndex is overwriting some values. Now it should work with cold as expected!
    self.takeoff=RAT.wp.cold
  end
end

--- Set the friendly coalitions from which the airports can be used as departure and destination.
-- @param #RAT self
-- @param #string friendly "same"=own coalition+neutral (default), "sameonly"=own coalition only, "neutral"=all neutral airports.
-- Default is "same", so aircraft will use airports of the coalition their spawn template has plus all neutral airports.
-- @usage yak:SetCoalition("neutral") will spawn aircraft randomly on all neutral airports.
-- @usage yak:SetCoalition("sameonly") will spawn aircraft randomly on airports belonging to the same coalition only as the template.
function RAT:SetCoalition(friendly)
  self:F2(friendly)
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
  self:F2(color)
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
  self:F2(id)
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
  self:F2(type)
  
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
-- @param #string departurenames Name or table of names of departure airports or zones.
-- @usage RAT:SetDeparture("Sochi-Adler") will spawn RAT objects at Sochi-Adler airport.
-- @usage RAT:SetDeparture({"Sochi-Adler", "Gudauta"}) will spawn RAT aircraft radomly at Sochi-Adler or Gudauta airport.
-- @usage RAT:SetDeparture({"Zone A", "Gudauta"}) will spawn RAT aircraft in air randomly within Zone A, which has to be defined in the mission editor, or within a zone around Gudauta airport. Note that this also requires RAT:takeoff("air") to be set.
function RAT:SetDeparture(departurenames)
  self:F2(departurenames)

  -- Random departure is deactivated now that user specified departure ports.
  self.random_departure=false
  
  -- Convert input to table.
  local names
  if type(departurenames)=="table" then
    names=departurenames   
  elseif type(departurenames)=="string" then
    names={departurenames}
  else
    -- error message
    self:E(RAT.id.."ERROR: Input parameter must be a string or a table in SetDeparture()!")
  end
  
  -- Put names into arrays.
  for _,name in pairs(names) do
  
    if self:_AirportExists(name) then
      -- If an airport with this name exists, we put it in the ports array.
      table.insert(self.departure_ports, name)
    elseif self:_ZoneExists(name) then
      -- If it is not an airport, we assume it is a zone.
      table.insert(self.departure_ports, name)
     else
      self:E(RAT.id.."ERROR: No departure airport or zone found with name "..name)
    end
    
  end
  
end

--- Set name of destination airports or zones for the AI aircraft.
-- @param #RAT self
-- @param #string destinationnames Name of the destination airport or table of destination airports.
-- @usage RAT:SetDestination("Krymsk") makes all aircraft of this RAT oject fly to Krymsk airport.
function RAT:SetDestination(destinationnames)
  self:F2(destinationnames)

  -- Random departure is deactivated now that user specified departure ports.
  self.random_destination=false
  
  -- Convert input to table
  local names
  if type(destinationnames)=="table" then
    names=destinationnames
  elseif type(destinationnames)=="string" then
    names={destinationnames}
  else
    -- Error message.
    self:E(RAT.id.."ERROR: Input parameter must be a string or a table in SetDestination()!")
  end
  
  -- Put names into arrays.
  for _,name in pairs(names) do
  
    if self:_AirportExists(name) then
      -- If an airport with this name exists, we put it in the ports array.
      table.insert(self.destination_ports, name)
    elseif self:_ZoneExists(name) then
      -- If it is not an airport, we assume it is a zone.
      table.insert(self.destination_ports, name)
    else
      self:E(RAT.id.."ERROR: No destination airport or zone found with name "..name)
    end
    
  end

end

--- Destinations are treated as zones. Aircraft will not land but rather be despawned when they reach a random point in the zone.
-- @param #RAT self
function RAT:DestinationZone()
  self:F2()
  
  -- Destination is a zone. Needs special care.
  self.destinationzone=true
  
  -- Landing type is "air" because we don't actually land at the airport.
  self.landing=RAT.wp.air
end

--- Aircraft will fly to a random point within a zone and then return to its departure airport or zone.
-- @param #RAT self
function RAT:ReturnZone()
  self:F2()
  -- Destination is a zone. Needs special care.
  self.returnzone=true
end


--- Include all airports which lie in a zone as possible destinations.
-- @param #RAT self
-- @param Core.Zone#ZONE zone Zone in which the departure airports lie. Has to be a MOOSE zone.
function RAT:SetDestinationsFromZone(zone)
  self:F2(zone)

  -- Random departure is deactivated now that user specified departure ports.
  self.random_destination=false
  
  -- Set zone.
  self.destination_Azone=zone
end

--- Include all airports which lie in a zone as possible destinations.
-- @param #RAT self
-- @param Core.Zone#ZONE zone Zone in which the destination airports lie. Has to be a MOOSE zone.
function RAT:SetDeparturesFromZone(zone)
  self:F2(zone)
  
  -- Random departure is deactivated now that user specified departure ports.
  self.random_departure=false

  -- Set zone.
  self.departure_Azone=zone
end

--- Add all friendly airports to the list of possible departures.
-- @param #RAT self
function RAT:AddFriendlyAirportsToDepartures()
  self:F2()
  self.addfriendlydepartures=true
end

--- Add all friendly airports to the list of possible destinations
-- @param #RAT self
function RAT:AddFriendlyAirportsToDestinations()
  self:F2()
  self.addfriendlydestinations=true
end

--- Airports, FARPs and ships explicitly excluded as departures and destinations.
-- @param #RAT self
-- @param #string ports Name or table of names of excluded airports.
function RAT:ExcludedAirports(ports)
  self:F2(ports)
  if type(ports)=="string" then
    self.excluded_ports={ports}
  else
    self.excluded_ports=ports
  end
end

--- Set skill of AI aircraft. Default is "High". 
-- @param #RAT self
-- @param #string skill Skill, options are "Average", "Good", "High", "Excellent" and "Random". Parameter is case insensitive.
function RAT:SetAISkill(skill)
  self:F2(skill)
  if skill:lower()=="average" then
    self.skill="Average"
  elseif skill:lower()=="good" then
    self.skill="Good"
  elseif skill:lower()=="excellent" then
    self.skill="Excellent"
  elseif skill:lower()=="random" then
    self.skill="Random"
  else
    self.skill="High"
  end
end

--- Set livery of aircraft. If more than one livery is specified in a table, the actually used one is chosen randomly from the selection.
-- @param #RAT self
-- @param #table skins Name of livery or table of names of liveries.
function RAT:Livery(skins)
  self:F2(skins)
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
  self:F2(actype)
  self.actype=actype
end

--- Aircraft will continue their journey from their destination. This means they are respawned at their destination and get a new random destination.
-- @param #RAT self
function RAT:ContinueJourney()
  self:F2()
  self.continuejourney=true
  self.commute=false
end

--- Aircraft will commute between their departure and destination airports or zones.
-- @param #RAT self
function RAT:Commute()
  self:F2()
  self.commute=true
  self.continuejourney=false
end

--- Set the delay before first group is spawned. 
-- @param #RAT self
-- @param #number delay Delay in seconds. Default is 5 seconds. Minimum delay is 0.5 seconds.
function RAT:SetSpawnDelay(delay)
  self:F2(delay)
  delay=delay or 5
  self.spawndelay=math.max(0.5, delay)
end

--- Set the interval between spawnings of the template group.
-- @param #RAT self
-- @param #number interval Interval in seconds. Default is 5 seconds. Minimum is 0.5 seconds.
function RAT:SetSpawnInterval(interval)
  self:F2(interval)
  interval=interval or 5
  self.spawninterval=math.max(0.5, interval)
end

--- Make aircraft respawn the moment they land rather than at engine shut down.
-- @param #RAT self
-- @param #number delay (Optional) Delay in seconds until respawn happens after landing. Default is 180 seconds. Minimum is 0.5 seconds.
function RAT:RespawnAfterLanding(delay)
  self:F2(delay)
  delay = delay or 180
  self.respawn_at_landing=true
  delay=math.max(0.5, delay)
  self.respawn_delay=delay
end

--- Sets the delay between despawning and respawning aircraft.
-- @param #RAT self
-- @param #number delay Delay in seconds until respawn happens. Default is 1 second. Minimum is 1 second.
function RAT:SetRespawnDelay(delay)
  self:F2(delay)
  delay = delay or 1
  delay=math.max(1.0, delay)
  self.respawn_delay=delay
end

--- Aircraft will not get respawned when they finished their route.
-- @param #RAT self
function RAT:NoRespawn()
  self:F2()
  self.norespawn=true
end

--- Number of tries to respawn an aircraft in case it has accitentally been spawned on runway.
-- @param #RAT self
-- @param #number n Number of retries. Default is 3.
function RAT:SetMaxRespawnTriedWhenSpawnedOnRunway(n)
  self:F2(n)
  n=n or 3
  self.rbug_maxretry=n
end

--- Aircraft will be respawned directly after take-off.
-- @param #RAT self
function RAT:RespawnAfterTakeoff()
  self:F2()
  self.respawn_after_takeoff=true
end

--- Aircraft will be respawned after they crashed or get shot down. This is the default behavior.
-- @param #RAT self
function RAT:RespawnAfterCrashON()
  self:F2()
  self.respawn_after_crash=true
end

--- Aircraft will not be respawned after they crashed or get shot down.
-- @param #RAT self
function RAT:RespawnAfterCrashOFF()
  self:F2()
  self.respawn_after_crash=false
end

--- If aircraft cannot be spawned on parking spots, it is allowed to spawn them in air above the same airport. Note that this is also the default behavior.
-- @param #RAT self
function RAT:RespawnInAirAllowed()
  self:F2()
  self.respawn_inair=true
end

--- If aircraft cannot be spawned on parking spots, it is NOT allowed to spawn them in air. This has only impact if aircraft are supposed to be spawned on the ground (and not in a zone).
-- @param #RAT self
function RAT:RespawnInAirNotAllowed()
  self:F2()
  self.respawn_inair=false
end

--- Check if aircraft have accidentally been spawned on the runway. If so they will be removed immediatly.
-- @param #RAT self
-- @param #booblen switch If true, check is performed. If false, this check is omitted.
function RAT:CheckOnRunway(switch)
  self:F2(switch)
  if switch==nil then
    switch=true
  end
  self.checkonrunway=switch
end

--- Check if aircraft have accidentally been spawned on top of each other. If yes, they will be removed immediately.
-- @param #RAT self
-- @param #booblen switch If true, check is performed. If false, this check is omitted.
function RAT:CheckOnTop(switch)
  self:F2(switch)
  if switch==nil then
    switch=true
  end
  self.checkontop=switch
end

--- Put parking spot coordinates in a data base for future use of aircraft.
-- @param #RAT self
-- @param #booblen switch If true, parking spots are memorized. This is also the default setting.
function RAT:ParkingSpotDB(switch)
  self:F2(switch)
  if switch==nil then
    switch=true
  end
  self.useparkingdb=switch
end

--- Set parking id of aircraft.
-- @param #RAT self
-- @param #string id Parking ID of the aircraft.
function RAT:SetParkingID(id)
  self:F2(id)
  self.parking_id=id
  self:T(RAT.id.."Setting parking ID to "..self.parking_id)
end

--- Enable Radio. Overrules the ME setting.
-- @param #RAT self
function RAT:RadioON()
  self:F2()
  self.radio=true
end

--- Disable Radio. Overrules the ME setting.
-- @param #RAT self
function RAT:RadioOFF()
  self:F2()
  self.radio=false
end

--- Set radio frequency.
-- @param #RAT self
-- @param #number frequency Radio frequency.
function RAT:RadioFrequency(frequency)
  self:F2(frequency)
  self.frequency=frequency
end

--- Spawn aircraft in uncontrolled state. Aircraft will only sit at their parking spots. They can be activated randomly by the RAT:ActivateUncontrolled() function.
-- @param #RAT self
function RAT:Uncontrolled()
  self:F2()
  self.uncontrolled=true
end

--- Aircraft are invisible. 
-- @param #RAT self
function RAT:Invisible()
  self:F2()
  self.invisible=true
end

--- Aircraft are immortal. 
-- @param #RAT self
function RAT:Immortal()
  self:F2()
  self.immortal=true
end

--- Activate uncontrolled aircraft. 
-- @param #RAT self
-- @param #number maxactivated Maximal numnber of activated aircraft. Absolute maximum will be the number of spawned groups. Default is 1.
-- @param #number delay Time delay in seconds before (first) aircraft is activated. Default is 1 second.
-- @param #number delta Time difference in seconds before next aircraft is activated. Default is 1 second.
-- @param #number frand Factor [0,...,1] for randomization of time difference between aircraft activations. Default is 0, i.e. no randomization.
function RAT:ActivateUncontrolled(maxactivated, delay, delta, frand)
  self:F2({max=maxactivated, delay=delay, delta=delta, rand=frand})

  self.activate_uncontrolled=true
  self.activate_max=maxactivated or 1
  self.activate_delay=delay or 1
  self.activate_delta=delta or 1
  self.activate_frand=frand or 0
  
  -- Ensure min delay is one second.
  self.activate_delay=math.max(self.activate_delay,1)
  
  -- Ensure min delta is one second.
  self.activate_delta=math.max(self.activate_delta,0)
  
  -- Ensure frand is in [0,...,1]
  self.activate_frand=math.max(self.activate_frand,0)
  self.activate_frand=math.min(self.activate_frand,1)
end

--- Set radio modulation. Default is AM.
-- @param #RAT self
-- @param #string modulation Either "FM" or "AM". If no value is given, modulation is set to AM.
function RAT:RadioModulation(modulation)
  self:F2(modulation)
  if modulation=="AM" then
    self.modulation=radio.modulation.AM
  elseif modulation=="FM" then
    self.modulation=radio.modulation.FM
  else
    self.modulation=radio.modulation.AM
  end
end

--- Set the time after which inactive groups will be destroyed. 
-- @param #RAT self
-- @param #number time Time in seconds. Default is 600 seconds = 10 minutes. Minimum is 60 seconds.
function RAT:TimeDestroyInactive(time)
  self:F2(time)
  time=time or self.Tinactive
  time=math.max(time, 60)
  self.Tinactive=time
end

--- Set the maximum cruise speed of the aircraft.
-- @param #RAT self
-- @param #number speed Speed in km/h.
function RAT:SetMaxCruiseSpeed(speed)
  self:F2(speed)
  -- Convert to m/s.
  self.Vcruisemax=speed/3.6
end

--- Set the climb rate. This automatically sets the climb angle.
-- @param #RAT self
-- @param #number rate Climb rate in ft/min. Default is 1500 ft/min. Minimum is 100 ft/min. Maximum is 15,000 ft/min.
function RAT:SetClimbRate(rate)
  self:F2(rate)
  rate=rate or self.Vclimb
  rate=math.max(rate, 100)
  rate=math.min(rate, 15000)
  self.Vclimb=rate
end

--- Set the angle of descent. Default is 3.6 degrees, which corresponds to 3000 ft descent after one mile of travel.
-- @param #RAT self
-- @param #number angle Angle of descent in degrees. Minimum is 0.5 deg. Maximum 50 deg.
function RAT:SetDescentAngle(angle)
  self:F2(angle)
  angle=angle or self.AlphaDescent
  angle=math.max(angle, 0.5)
  angle=math.min(angle, 50)
  self.AlphaDescent=angle
end

--- Set rules of engagement (ROE). Default is weapon hold. This is a peaceful class.
-- @param #RAT self
-- @param #string roe "hold" = weapon hold, "return" = return fire, "free" = weapons free.
function RAT:SetROE(roe)
  self:F2(roe)
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
  self:F2(rot)
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
  self:F2(name)
  self.SubMenuName=tostring(name)
end

--- Enable ATC, which manages the landing queue for RAT aircraft if they arrive simultaniously at the same airport.
-- @param #RAT self
-- @param #boolean switch Enable ATC (true) or Disable ATC (false). No argument means ATC enabled. 
function RAT:EnableATC(switch)
  self:F2(switch)
  if switch==nil then
    switch=true
  end
  self.ATCswitch=switch
end

--- Turn messages from ATC on or off. Default is on. This setting effects all RAT objects and groups!
-- @param #RAT self
-- @param #boolean switch Enable (true) or disable (false) messages from ATC. 
function RAT:ATC_Messages(switch)
  self:F2(switch)
  if switch==nil then
    switch=true
  end
  RAT.ATC.messages=switch
end

--- Max number of planes that get landing clearance of the RAT ATC. This setting effects all RAT objects and groups! 
-- @param #RAT self
-- @param #number n Number of aircraft that are allowed to land simultaniously. Default is 2.
function RAT:ATC_Clearance(n)
  self:F2(n)
  RAT.ATC.Nclearance=n or 2
end

--- Delay between granting landing clearance for simultanious landings. This setting effects all RAT objects and groups! 
-- @param #RAT self
-- @param #number time Delay time when the next aircraft will get landing clearance event if the previous one did not land yet. Default is 240 sec.
function RAT:ATC_Delay(time)
  self:F2(time)
  RAT.ATC.delay=time or 240
end

--- Set minimum distance between departure and destination. Default is 5 km.
-- Minimum distance should not be smaller than maybe ~500 meters to ensure that departure and destination are different.
-- @param #RAT self
-- @param #number dist Distance in km.
function RAT:SetMinDistance(dist)
  self:F2(dist)
  -- Distance in meters. Absolute minimum is 500 m.
  self.mindist=math.max(500, dist*1000)
end

--- Set maximum distance between departure and destination. Default is 5000 km but aircarft range is also taken into account automatically.
-- @param #RAT self
-- @param #number dist Distance in km.
function RAT:SetMaxDistance(dist)
  self:F2(dist)
  -- Distance in meters.
  self.maxdist=dist*1000
end

--- Turn debug messages on or off. Default is off.
-- @param #RAT self
-- @param #boolean switch Turn debug on=true or off=false. No argument means on.
function RAT:_Debug(switch)
  self:F2(switch)
  if switch==nil then
    switch=true
  end
  self.Debug=switch
end

--- Enable debug mode. More output in dcs.log file and onscreen messages to all.
-- @param #RAT self
function RAT:Debugmode()
  self:F2()
  self.Debug=true
end

--- Aircraft report status update messages along the route.
-- @param #RAT self
-- @param #boolean switch Swtich reports on (true) or off (false). No argument is on.
function RAT:StatusReports(switch)
  self:F2(switch)
  if switch==nil then
    switch=true
  end
  self.reportstatus=switch
end

--- Place markers of waypoints on the F10 map. Default is off.
-- @param #RAT self
-- @param #boolean switch true=yes, false=no.
function RAT:PlaceMarkers(switch)
  self:F2(switch)
  if switch==nil then
    switch=true
  end
  self.placemarkers=switch
end

--- Set flight level. Setting this value will overrule all other logic. Aircraft will try to fly at this height regardless.
-- @param #RAT self
-- @param #number FL Fight Level in hundrets of feet. E.g. FL200 = 20000 ft ASL.
function RAT:SetFL(FL)
  self:F2(FL)
  FL=FL or self.FLcruise
  FL=math.max(FL,0)
  self.FLuser=FL*RAT.unit.FL2m
end

--- Set max flight level. Setting this value will overrule all other logic. Aircraft will try to fly at less than this FL regardless.
-- @param #RAT self
-- @param #number FL Maximum Fight Level in hundrets of feet.
function RAT:SetFLmax(FL)
  self:F2(FL)
  self.FLmaxuser=FL*RAT.unit.FL2m
end

--- Set max cruising altitude above sea level.
-- @param #RAT self
-- @param #number alt Altitude ASL in meters.
function RAT:SetMaxCruiseAltitude(alt)
  self:F2(alt)
  self.FLmaxuser=alt
end

--- Set min flight level. Setting this value will overrule all other logic. Aircraft will try to fly at higher than this FL regardless.
-- @param #RAT self
-- @param #number FL Maximum Fight Level in hundrets of feet.
function RAT:SetFLmin(FL)
  self:F2(FL)
  self.FLminuser=FL*RAT.unit.FL2m
end

--- Set min cruising altitude above sea level.
-- @param #RAT self
-- @param #number alt Altitude ASL in meters.
function RAT:SetMinCruiseAltitude(alt)
  self:F2(alt)
  self.FLminuser=alt
end

--- Set flight level of cruising part. This is still be checked for consitancy with selected route and prone to radomization.
-- Default is FL200 for planes and FL005 for helicopters.
-- @param #RAT self
-- @param #number FL Flight level in hundrets of feet. E.g. FL200 = 20000 ft ASL.
function RAT:SetFLcruise(FL)
  self:F2(FL)
  self.FLcruise=FL*RAT.unit.FL2m
end

--- Set cruising altitude. This is still be checked for consitancy with selected route and prone to radomization.
-- @param #RAT self
-- @param #number alt Cruising altitude ASL in meters.
function RAT:SetCruiseAltitude(alt)
  self:F2(alt)
  self.FLcruise=alt
end

--- Set onboard number prefix. Same as setting "TAIL #" in the mission editor. Note that if you dont use this function, the values defined in the template group of the ME are taken.
-- @param #RAT self
-- @param #string tailnumprefix String of the tail number prefix. If flight consists of more than one aircraft, two digits are appended automatically, i.e. <tailnumprefix>001, <tailnumprefix>002, ... 
-- @param #number zero (Optional) Starting value of the automatically appended numbering of aircraft within a flight. Default is 0.
function RAT:SetOnboardNum(tailnumprefix, zero)
  self:F2({tailnumprefix=tailnumprefix, zero=zero})
  self.onboardnum=tailnumprefix
  if zero ~= nil then
    self.onboardnum0=zero
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Initialize basic parameters of the aircraft based on its (template) group in the mission editor.
-- @param #RAT self
-- @param Dcs.DCSWrapper.Group#Group DCSgroup Group of the aircraft in the mission editor.
function RAT:_InitAircraft(DCSgroup)
  self:F2(DCSgroup)

  local DCSunit=DCSgroup:getUnit(1)
  local DCSdesc=DCSunit:getDesc()
  local DCScategory=DCSgroup:getCategory()
  local DCStype=DCSunit:getTypeName()
 
  -- set category
  if DCScategory==Group.Category.AIRPLANE then
    self.category=RAT.cat.plane
  elseif DCScategory==Group.Category.HELICOPTER then
    self.category=RAT.cat.heli
  else
    self.category="other"
    self:E(RAT.id.."ERROR: Group of RAT is neither airplane nor helicopter!")
  end
  
  -- Get type of aircraft.
  self.aircraft.type=DCStype
  
  -- inital fuel in %
  self.aircraft.fuel=DCSunit:getFuel()

  -- operational range in NM converted to m
  self.aircraft.Rmax = DCSdesc.range*RAT.unit.nm2m
  
  -- effective range taking fuel into accound and a 5% reserve
  self.aircraft.Reff = self.aircraft.Rmax*self.aircraft.fuel*0.95
  
  -- max airspeed from group
  self.aircraft.Vmax = DCSdesc.speedMax
      
  -- max climb speed in m/s
  self.aircraft.Vymax=DCSdesc.VyMax
    
  -- service ceiling in meters
  self.aircraft.ceiling=DCSdesc.Hmax
  
  -- Store all descriptors.
  --self.aircraft.descriptors=DCSdesc
  
  -- aircraft dimensions
  self.aircraft.length=DCSdesc.box.max.x
  self.aircraft.height=DCSdesc.box.max.y
  self.aircraft.width=DCSdesc.box.max.z
  self.aircraft.box=math.max(self.aircraft.length,self.aircraft.width)
  
  -- info message
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Aircraft parameters:\n")
  text=text..string.format("Template group  =  %s\n",       self.SpawnTemplatePrefix)
  text=text..string.format("Alias           =  %s\n",       self.alias)
  text=text..string.format("Category        =  %s\n",       self.category)
  text=text..string.format("Type            =  %s\n",       self.aircraft.type)
  text=text..string.format("Length (x)      = %6.1f m\n",   self.aircraft.length)
  text=text..string.format("Width  (z)      = %6.1f m\n",   self.aircraft.width)
  text=text..string.format("Height (y)      = %6.1f m\n",   self.aircraft.height)
  text=text..string.format("Max air speed   = %6.1f m/s\n", self.aircraft.Vmax)
  text=text..string.format("Max climb speed = %6.1f m/s\n", self.aircraft.Vymax)
  text=text..string.format("Initial Fuel    = %6.1f\n",     self.aircraft.fuel*100)
  text=text..string.format("Max range       = %6.1f km\n",  self.aircraft.Rmax/1000)
  text=text..string.format("Eff range       = %6.1f km (with 95 percent initial fuel amount)\n",  self.aircraft.Reff/1000)
  text=text..string.format("Ceiling         = %6.1f km = FL%3.0f\n", self.aircraft.ceiling/1000, self.aircraft.ceiling/RAT.unit.FL2m)
  text=text..string.format("******************************************************\n")
  self:T(RAT.id..text)

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
-- @param #number _landing Landing type id.
-- @param #string _livery Livery to use for this group.
-- @param #table _waypoint First waypoint to be used (for continue journey, commute, etc).
-- @param Core.Point#COORDINATE _lastpos (Optional) Position where the aircraft will be spawned.
-- @param #number _nrespawn Number of already performed respawn attempts (e.g. spawning on runway bug).
-- @return #number Spawn index.
function RAT:_SpawnWithRoute(_departure, _destination, _takeoff, _landing, _livery, _waypoint, _lastpos, _nrespawn)
  self:F({rat=RAT.id, departure=_departure, destination=_destination, takeoff=_takeoff, landing=_landing, livery=_livery, waypoint=_waypoint, lastpos=_lastpos, nrespawn=_nrespawn})

  -- Set takeoff type.
  local takeoff=self.takeoff
  local landing=self.landing
    
  -- Overrule takeoff/landing by what comes in.
  if _takeoff then
    takeoff=_takeoff
  end
  if _landing then
    landing=_landing
  end
  
  -- Random choice between cold and hot.
  if takeoff==RAT.wp.coldorhot then
    local temp={RAT.wp.cold, RAT.wp.hot}
    takeoff=temp[math.random(2)]
  end
    
  -- Number of respawn attempts after spawning on runway.
  local nrespawn=0
  if _nrespawn then
    nrespawn=_nrespawn
  end
  
  -- Set flight plan.
  local departure, destination, waypoints, WPholding, WPfinal = self:_SetRoute(takeoff, landing, _departure, _destination, _waypoint)
  
  -- Return nil if we could not find a departure destination or waypoints
  if not (departure and destination and waypoints) then
    return nil
  end

  -- Find parking spot in RAT parking DB. Category 4 should be airports and farps. Ships would be caterory 1.
  local _spawnpos=_lastpos
  if self.useparkingdb and (takeoff==RAT.wp.cold or takeoff==RAT.wp.hot) and departure:GetCategory()==4 and  _spawnpos==nil then
    _spawnpos=self:_FindParkingSpot(departure)
  end
  
  -- Set (another) livery.
  local livery
  if _livery then
    -- Take livery from previous flight (continue journey).
    livery=_livery
  elseif self.livery then
    -- Choose random livery.
    livery=self.livery[math.random(#self.livery)]
    local text=string.format("Chosen livery for group %s: %s", self:_AnticipatedGroupName(), livery)
    self:T(RAT.id..text)
  else
    livery=nil
  end
  
  -- Modify the spawn template to follow the flight plan.
  self:_ModifySpawnTemplate(waypoints, livery, _spawnpos)
  
  -- Actually spawn the group.
  local group=self:SpawnWithIndex(self.SpawnIndex) -- Wrapper.Group#GROUP
  
  -- Increase counter of alive groups (also uncontrolled ones).
  self.alive=self.alive+1
  self:T(RAT.id..string.format("Alive groups counter now = %d.",self.alive))
  
  -- ATC is monitoring this flight (if it is supposed to land).
  if self.ATCswitch and landing==RAT.wp.landing then
    if self.returnzone then
      self:_ATCAddFlight(group:GetName(), departure:GetName())
    else
      self:_ATCAddFlight(group:GetName(), destination:GetName())
    end
  end
  
  -- Place markers of waypoints on F10 map.
  if self.placemarkers then
    self:_PlaceMarkers(waypoints, self.SpawnIndex)
  end
  
  -- Set group to be invisible.
  if self.invisible then
    self:_CommandInvisible(group, true)
  end
  
  -- Set group to be immortal.
  if self.immortal then
    self:_CommandImmortal(group, true)
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
  self.ratcraft[self.SpawnIndex]["airborne"]=group:InAir()
  self.ratcraft[self.SpawnIndex]["nunits"]=group:GetInitialSize()
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
  
  -- Each aircraft gets its own takeoff type.
  self.ratcraft[self.SpawnIndex].takeoff=takeoff
  self.ratcraft[self.SpawnIndex].landing=landing
  self.ratcraft[self.SpawnIndex].wpholding=WPholding
  self.ratcraft[self.SpawnIndex].wpfinal=WPfinal
  
  -- Aircraft is active or spawned in uncontrolled state.
  self.ratcraft[self.SpawnIndex].active=not self.uncontrolled
  
  -- Set status to spawned. This will be overwritten in birth event.
  self.ratcraft[self.SpawnIndex]["status"]=RAT.status.Spawned
  
  -- Livery
  self.ratcraft[self.SpawnIndex].livery=livery
  
  -- If this switch is set to true, the aircraft will be despawned the next time the status function is called.
  self.ratcraft[self.SpawnIndex].despawnme=false
  
  -- Number of preformed spawn attempts for this group.
  self.ratcraft[self.SpawnIndex].nrespawn=nrespawn
  
  -- If we start at a parking position, we memorize the parking spot position for future use (DCS bug).
  -- TODO: Check for ships and FARPS.
  if self.useparkingdb and (takeoff==RAT.wp.cold or takeoff==RAT.wp.hot) and departure:GetCategory()==4 then
    self:_AddParkingSpot(departure, group)
  end
 
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
    MENU_MISSION_COMMAND:New("Place markers",  self.Menu[self.SubMenuName].groups[self.SpawnIndex], self._PlaceMarkers, self, waypoints, self.SpawnIndex)
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
  self:T(RAT.id.."ATC: User flag value (landing) for "..name.." set to "..flagvalue)
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
  local takeoff=self.ratcraft[index].takeoff
  local landing=self.ratcraft[index].landing
  local livery=self.ratcraft[index].livery
  local lastwp=self.ratcraft[index].waypoints[#self.ratcraft[index].waypoints]
  local lastpos=group:GetCoordinate()
  
  local _departure=nil
  local _destination=nil
  local _takeoff=nil
  local _landing=nil
  local _livery=nil
  local _lastwp=nil
  local _lastpos=nil
 
  if self.continuejourney then
  
    -- We continue our journey from the old departure airport.
    _departure=destination:GetName()
    
    -- Use the same livery for next aircraft.
    _livery=livery
    
    -- Last known position of the aircraft, which should be the sparking spot location.
    -- Note: we have to check that it was supposed to land and not respawned directly after landing or after takeoff.
    -- TODO: Need to think if continuejourney with respawn_after_takeoff actually makes sense.
    if landing==RAT.wp.landing and lastpos and not (self.respawn_at_landing or self.respawn_after_takeoff) then
      -- Check that we have an airport or FARP but not a ship (which would be categroy 1).
      if destination:GetCategory()==4 then
        _lastpos=lastpos
      end
    end
    
    if self.destinationzone then
      
      -- Case: X --> Zone --> Zone --> Zone
      _takeoff=RAT.wp.air
      _landing=RAT.wp.air
    
    elseif self.returnzone then
    
      -- Case: X --> Zone --> X,  X --> Zone --> X
      -- We flew to a zone and back. Takeoff type does not change.
      _takeoff=self.takeoff

      -- If we took of in air we also want to land "in air".
      if self.takeoff==RAT.wp.air then
        _landing=RAT.wp.air
      else
        _landing=RAT.wp.landing
      end
      
      -- Departure stays the same. (The destination is the zone here.)
      _departure=departure:GetName()
      
    else
      
      -- Default case. Takeoff and landing type does not change.
      _takeoff=self.takeoff
      _landing=self.landing
    
    end
    
  elseif self.commute then
  
    -- We commute between departure and destination.
    _departure=destination:GetName()
    _destination=departure:GetName()
    
    -- Use the same livery for next aircraft.
    _livery=livery
    
    -- Last known position of the aircraft, which should be the sparking spot location.
    -- Note: we have to check that it was supposed to land and not respawned directly after landing or after takeoff.
    -- TODO: Need to think if commute with respawn_after_takeoff actually makes sense.
    if landing==RAT.wp.landing and lastpos and not (self.respawn_at_landing or self.respawn_after_takeoff) then
      -- Check that we have landed on an airport or FARP but not a ship (which would be categroy 1).
      if destination:GetCategory()==4 then
        _lastpos=lastpos
      end    
    end
    
    -- Handle takeoff type.
    if self.destinationzone then
      -- self.takeoff is either RAT.wp.air or RAT.wp.cold
      -- self.landing is RAT.wp.Air
    
      if self.takeoff==RAT.wp.air then
      
        -- Case: Zone <--> Zone (both have takeoff air)
        _takeoff=RAT.wp.air  -- = self.takeoff (because we just checked)
        _landing=RAT.wp.air  -- = self.landing (because destinationzone)
        
      else
      
        -- Case: Airport <--> Zone
        if takeoff==RAT.wp.air then
          -- Last takeoff was air so we are at the airport now, takeoff is from ground.
          _takeoff=self.takeoff   -- must be either hot/cold/runway/hotcold
          _landing=RAT.wp.air     -- must be air = self.landing (because destinationzone)
        else
          -- Last takeoff was on ground so we are at a zone now ==> takeoff in air, landing at airport.
          _takeoff=RAT.wp.air
          _landing=RAT.wp.landing
        end
        
      end
      
    elseif self.returnzone then
    
      -- We flew to a zone and back. No need to swap departure and destination.
      _departure=departure:GetName()
      _destination=destination:GetName()
      
      -- Takeoff and landing should also not change.
      _takeoff=self.takeoff
      _landing=self.landing
      
    end   
    
  end
  
  -- Take the last waypoint as initial waypoint for next plane.
  if _takeoff==RAT.wp.air and (self.continuejourney or self.commute) then
    _lastwp=lastwp
  end
  
  -- Debug
  self:T2({departure=_departure, destination=_destination, takeoff=_takeoff, landing=_landing, livery=_livery, lastwp=_lastwp})
      
  -- Spawn new group.
  local arg={}
  arg.self=self
  arg.departure=_departure
  arg.destination=_destination
  arg.takeoff=_takeoff
  arg.landing=_landing
  arg.livery=_livery
  arg.lastwp=_lastwp
  arg.lastpos=_lastpos
  SCHEDULER:New(nil, self._SpawnWithRouteTimer, {arg}, self.respawn_delay or 1)
  
end

--- Delayed spawn function called by scheduler.
-- @param #RAT self
-- @param #table arg Parameters: arg.self, arg.departure, arg.destination, arg.takeoff, arg.landing, arg.livery, arg.lastwp, arg.lastpos
function RAT._SpawnWithRouteTimer(arg)
  RAT._SpawnWithRoute(arg.self, arg.departure, arg.destination, arg.takeoff, arg.landing, arg.livery, arg.lastwp, arg.lastpos)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the route of the AI plane. Due to DCS landing bug, this has to be done before the unit is spawned.
-- @param #RAT self
-- @param #number takeoff Takeoff type. Could also be air start.
-- @param #number landing Landing type. Could also be a destination in air.
-- @param Wrapper.Airport#AIRBASE _departure (Optional) Departure airbase.
-- @param Wrapper.Airport#AIRBASE _destination (Optional) Destination airbase.
-- @param #table _waypoint Initial waypoint.
-- @return Wrapper.Airport#AIRBASE Departure airbase.
-- @return Wrapper.Airport#AIRBASE Destination airbase.
-- @return #table Table of flight plan waypoints.
-- @return #nil If no valid departure or destination airport could be found.
function RAT:_SetRoute(takeoff, landing, _departure, _destination, _waypoint)
    
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
  
  -- Expected cruise level (peak of Gaussian distribution)
  local FLcruise_expect=self.FLcruise
  
 
  -- DEPARTURE AIRPORT  
  -- Departure airport or zone.
  local departure=nil
  if _departure then
    if self:_AirportExists(_departure) then
      -- Check if new departure is an airport.
      departure=AIRBASE:FindByName(_departure)
      -- If we spawn in air, we convert departure to a zone.
      if takeoff == RAT.wp.air then
        departure=departure:GetZone()
      end
    elseif self:_ZoneExists(_departure) then
      -- If it's not an airport, check whether it's a zone.
      departure=ZONE:New(_departure)
    else
      local text=string.format("ERROR! Specified departure airport %s does not exist for %s.", _departure, self.alias)
      self:E(RAT.id..text)
    end    
    
  else
    departure=self:_PickDeparture(takeoff)
  end
   
  -- Return nil if no departure could be found.
  if not departure then
    local text=string.format("ERROR! No valid departure airport could be found for %s.", self.alias)
    self:E(RAT.id..text)
    return nil
  end

  -- Coordinates of departure point.
  local Pdeparture
  if takeoff==RAT.wp.air then
    if _waypoint then
      -- Use coordinates of previous flight (commute or journey).
      Pdeparture=COORDINATE:New(_waypoint.x, _waypoint.alt, _waypoint.y)
    else
      -- For an air start, we take a random point within the spawn zone.
      local vec2=departure:GetRandomVec2()
      Pdeparture=COORDINATE:NewFromVec2(vec2)
      end 
  else
    Pdeparture=departure:GetCoordinate()
  end
  
  -- Height ASL of departure point.
  local H_departure
  if takeoff==RAT.wp.air then
    -- Absolute minimum AGL
    local Hmin
    if self.category==RAT.cat.plane then
      Hmin=1000
    else
      Hmin=50
    end
    -- Departure altitude is 70% of default cruise with 30% variation and limited to 1000 m AGL (50 m for helos). 
    H_departure=self:_Randomize(FLcruise_expect*0.7, 0.3, Pdeparture.y+Hmin, FLcruise_expect)
    if self.FLminuser then
      H_departure=math.max(H_departure,self.FLminuser)
    end
    -- Use alt of last flight.
    if _waypoint then
      H_departure=_waypoint.alt
    end
  else
    H_departure=Pdeparture.y
  end
  
  -- Adjust min distance between departure and destination for user set min flight level.
  local mindist=self.mindist
  if self.FLminuser then
  
    -- We can conly consider the symmetric case, because no destination selected yet.
    local hclimb=self.FLminuser-H_departure
    local hdescent=self.FLminuser-H_departure
    
    -- Minimum distance for l
    local Dclimb, Ddescent, Dtot=self:_MinDistance(AlphaClimb, AlphaDescent, hclimb, hdescent)
    
    if takeoff==RAT.wp.air and landing==RAT.wpair then
      mindist=0         -- Takeoff and landing are in air. No mindist required.
    elseif takeoff==RAT.wp.air then
      mindist=Ddescent  -- Takeoff in air. Need only space to descent.
    elseif landing==RAT.wp.air then
      mindist=Dclimb    -- Landing "in air". Need only space to climb.
    else
      mindist=Dtot      -- Takeoff and landing on ground. Need both space to climb and descent.
    end
    
    -- Mindist is at least self.mindist.
    mindist=math.max(self.mindist, mindist)
    
    local text=string.format("Adjusting min distance to %d km (for given min FL%03d)", mindist/1000, self.FLminuser/RAT.unit.FL2m)
    self:T(RAT.id..text)
  end
  
  -- DESTINATION AIRPORT
  local destination=nil
  if _destination then
  
    if self:_AirportExists(_destination) then
    
      destination=AIRBASE:FindByName(_destination)
      if landing==RAT.wp.air or self.returnzone then
        destination=destination:GetZone()
      end
      
    elseif self:_ZoneExists(_destination) then
      destination=ZONE:New(_destination)
    else
      local text=string.format("ERROR: Specified destination airport/zone %s does not exist for %s!", _destination, self.alias)
      self:E(RAT.id.."ERROR: "..text)
    end
    
  else

    -- This handles the case where we have a journey and the first flight is done, i.e. _departure is set.
    -- If a user specified more than two destination airport explicitly, then we will stick to this.
    -- Otherwise, the route is random from now on.
    local random=self.random_destination
    if self.continuejourney and _departure and #self.destination_ports<3 then
      random=true
    end
    
    -- In case of a returnzone the destination (i.e. return point) is always a zone.
    local mylanding=landing
    local acrange=self.aircraft.Reff
    if self.returnzone then
      mylanding=RAT.wp.air
      acrange=self.aircraft.Reff/2  -- Aircraft needs to go to zone and back home.
    end
    
    -- Pick a destination airport.
    destination=self:_PickDestination(departure, Pdeparture, mindist, math.min(acrange, self.maxdist), random, mylanding)
  end
    
  -- Return nil if no departure could be found.
  if not destination then
    local text=string.format("No valid destination airport could be found for %s!", self.alias)
    MESSAGE:New(text, 60):ToAll()
    self:E(RAT.id.."ERROR: "..text)
    return nil
  end
  
  -- Check that departure and destination are not the same. Should not happen due to mindist.
  if destination:GetName()==departure:GetName() then
    local text=string.format("%s: Destination and departure are identical. Airport/zone %s.", self.alias, destination:GetName())
    MESSAGE:New(text, 30):ToAll()
    self:E(RAT.id.."ERROR: "..text)
  end
  
  -- Get a random point inside zone return zone.
  local Preturn
  local destination_returnzone
  if self.returnzone then
    -- Get a random point inside zone return zone.
    local vec2=destination:GetRandomVec2()
    Preturn=COORDINATE:NewFromVec2(vec2)
    -- Returnzone becomes destination.
    destination_returnzone=destination
    -- Set departure to destination.
    destination=departure
  end
  
  -- Get destination coordinate. Either in a zone or exactly at the airport.
  local Pdestination
  if landing==RAT.wp.air then
    local vec2=destination:GetRandomVec2()
    Pdestination=COORDINATE:NewFromVec2(vec2)
  else
    Pdestination=destination:GetCoordinate()
  end
  
  -- Height ASL of destination airport/zone.
  local H_destination=Pdestination.y
    
  -- DESCENT/HOLDING POINT
  -- Get a random point between 5 and 10 km away from the destination.
  local Rhmin=8000
  local Rhmax=20000
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
  
  -- This is the actual height ASL of the holding point we want to fly to
  local Hh_holding=H_holding+h_holding
  
  -- When we dont land, we set the holding altitude to the departure or cruise alt.
  -- This is used in the calculations.
  if landing==RAT.wp.air then
    Hh_holding=H_departure
  end
    
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
  
  -- Max height in case of air start, i.e. if we only would descent to holding point for the given distance.
  if takeoff==RAT.wp.air then
    local H_departure_max
    if landing==RAT.wp.air then
      H_departure_max = H_departure  -- If we fly to a zone, there is no descent necessary.
    else
      H_departure_max = d_total * math.tan(AlphaDescent) + Hh_holding
    end
    H_departure=math.min(H_departure, H_departure_max)
  end
  
  --------------------------------------------
  
  -- Height difference between departure and destination.
  local deltaH=math.abs(H_departure-Hh_holding)
  
  -- Slope between departure and destination.
  local phi = math.atan(deltaH/d_total)
  
  -- Adjusted climb/descent angles.
  local phi_climb
  local phi_descent
  if (H_departure > Hh_holding) then
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
  if (H_departure > Hh_holding) then
    h_max=math.min(h_max1, h_max2)
  else
    h_max=math.max(h_max1, h_max2)
  end
  
  -- Max flight level aircraft can reach for given angles and distance.
  local FLmax = h_max+H_departure
      
  --CRUISE  
  -- Min cruise alt is just above holding point at destination or departure height, whatever is larger.
  local FLmin=math.max(H_departure, Hh_holding)
   
  -- For helicopters we take cruise alt between 50 to 1000 meters above ground. Default cruise alt is ~150 m.
  if self.category==RAT.cat.heli then  
    FLmin=math.max(H_departure, H_destination)+50
    FLmax=math.max(H_departure, H_destination)+1000
  end
  
  -- Ensure that FLmax not above its service ceiling.
  FLmax=math.min(FLmax, self.aircraft.ceiling)
  
  -- Overrule setting if user specified min/max flight level explicitly.
  if self.FLminuser then
    FLmin=math.max(self.FLminuser, FLmin)  -- Still take care that we dont fly too high.
  end
  if self.FLmaxuser then
    FLmax=math.min(self.FLmaxuser, FLmax)  -- Still take care that we dont fly too low.
  end
  
  -- If the route is very short we set FLmin a bit lower than FLmax.
  if FLmin>FLmax then
    FLmin=FLmax
  end
  
  -- Expected cruise altitude - peak of gaussian distribution.
  if FLcruise_expect<FLmin then
    FLcruise_expect=FLmin
  end
  if FLcruise_expect>FLmax then
    FLcruise_expect=FLmax
  end
    
  -- Set cruise altitude. Selected from Gaussian distribution but limited to FLmin and FLmax.
  local FLcruise=self:_Random_Gaussian(FLcruise_expect, math.abs(FLmax-FLmin)/4, FLmin, FLmax)
    
  -- Overrule setting if user specified a flight level explicitly.
  if self.FLuser then
    FLcruise=self.FLuser
    -- Still cruise alt should be with parameters!
    FLcruise=math.max(FLcruise, FLmin)
    FLcruise=math.min(FLcruise, FLmax)
  end

  -- Climb and descent heights.
  local h_climb   = FLcruise - H_departure
  local h_descent = FLcruise - Hh_holding
  
  -- Distances.
  local d_climb   = h_climb/math.tan(AlphaClimb)
  local d_descent = h_descent/math.tan(AlphaDescent)
  local d_cruise  = d_total-d_climb-d_descent  
  
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
  if self.Debug then
    -- Max heights and distances if we would travel at FLmax.
    local h_climb_max   = FLmax - H_departure
    local h_descent_max = FLmax - Hh_holding
    local d_climb_max   = h_climb_max/math.tan(AlphaClimb) 
    local d_descent_max = h_descent_max/math.tan(AlphaDescent)
    local d_cruise_max  = d_total-d_climb_max-d_descent_max
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
    text=text..string.format("h_climb_max   = %6.1f m\n",  h_climb_max)
    text=text..string.format("h_descent_max = %6.1f m\n",  h_descent_max)
  end
  text=text..string.format("******************************************************\n")
  self:T2(RAT.id..text)
  
  -- Ensure that cruise distance is positve. Can be slightly negative in special cases. And we don't want to turn back.
  if d_cruise<0 then
    d_cruise=100
  end

  -- Waypoints and coordinates
  local wp={}
  local c={}
  local wpholding=nil
  local wpfinal=nil
  
  -- Departure/Take-off
  c[#c+1]=Pdeparture
  wp[#wp+1]=self:_Waypoint(#wp+1, "Departure", takeoff, c[#wp+1], VxClimb, H_departure, departure)
  self.waypointdescriptions[#wp]="Departure"
  self.waypointstatus[#wp]=RAT.status.Departure
  
  -- Climb
  if takeoff==RAT.wp.air then
  
    -- Air start.
    if d_climb < 5000 or d_cruise < 5000 then
      -- We omit the climb phase completely and add it to the cruise part.
      d_cruise=d_cruise+d_climb
    else      
      -- Only one waypoint at the end of climb = begin of cruise.
      c[#c+1]=c[#c]:Translate(d_climb, heading)
            
      wp[#wp+1]=self:_Waypoint(#wp+1, "Begin of Cruise", RAT.wp.cruise, c[#wp+1], VxCruise, FLcruise)
      self.waypointdescriptions[#wp]="Begin of Cruise"
      self.waypointstatus[#wp]=RAT.status.Cruise
    end
    
  else
  
    -- Ground start.
    c[#c+1]=c[#c]:Translate(d_climb/2, heading)
    c[#c+1]=c[#c]:Translate(d_climb/2, heading)
    
    wp[#wp+1]=self:_Waypoint(#wp+1, "Climb", RAT.wp.climb,  c[#wp+1], VxClimb, H_departure+(FLcruise-H_departure)/2)
    self.waypointdescriptions[#wp]="Climb"
    self.waypointstatus[#wp]=RAT.status.Climb
    
    wp[#wp+1]=self:_Waypoint(#wp+1, "Begin of Cruise", RAT.wp.cruise, c[#wp+1], VxCruise, FLcruise)
    self.waypointdescriptions[#wp]="Begin of Cruise"
    self.waypointstatus[#wp]=RAT.status.Cruise
 
  end
  
  -- Cruise
  
  -- First add the little bit from begin of cruise to the return point.
  if self.returnzone then    
    c[#c+1]=Preturn    
    wp[#wp+1]=self:_Waypoint(#wp+1, "Return Zone", RAT.wp.cruise, c[#wp+1], VxCruise, FLcruise)
    self.waypointdescriptions[#wp]="Return Zone"
    self.waypointstatus[#wp]=RAT.status.Uturn
  end
  
  if landing==RAT.wp.air then
  
    -- Next waypoint is already the final destination.
    c[#c+1]=Pdestination
    wp[#wp+1]=self:_Waypoint(#wp+1, "Final Destination", RAT.wp.finalwp, c[#wp+1], VxCruise,  FLcruise)
    self.waypointdescriptions[#wp]="Final Destination"
    self.waypointstatus[#wp]=RAT.status.Destination
  
  elseif self.returnzone then
  
    -- The little bit back to end of cruise.  
    c[#c+1]=c[#c]:Translate(d_cruise/2, heading-180)    
    wp[#wp+1]=self:_Waypoint(#wp+1, "End of Cruise", RAT.wp.cruise, c[#wp+1], VxCruise,  FLcruise)
    self.waypointdescriptions[#wp]="End of Cruise"
    self.waypointstatus[#wp]=RAT.status.Descent
    
  else
  
    c[#c+1]=c[#c]:Translate(d_cruise, heading)
    wp[#wp+1]=self:_Waypoint(#wp+1, "End of Cruise", RAT.wp.cruise, c[#wp+1], VxCruise,  FLcruise)
    self.waypointdescriptions[#wp]="End of Cruise"
    self.waypointstatus[#wp]=RAT.status.Descent
    
  end
  
  -- Descent (only if we acually want to land)
  if landing==RAT.wp.landing then
    if self.returnzone then
      c[#c+1]=c[#c]:Translate(d_descent/2, heading-180)
      wp[#wp+1]=self:_Waypoint(#wp+1, "Descent", RAT.wp.descent, c[#wp+1], VxDescent, FLcruise-(FLcruise-(h_holding+H_holding))/2)
      self.waypointdescriptions[#wp]="Descent"
      self.waypointstatus[#wp]=RAT.status.DescentHolding
    else
      c[#c+1]=c[#c]:Translate(d_descent/2, heading)
      wp[#wp+1]=self:_Waypoint(#wp+1, "Descent", RAT.wp.descent, c[#wp+1], VxDescent, FLcruise-(FLcruise-(h_holding+H_holding))/2)
      self.waypointdescriptions[#wp]="Descent"
      self.waypointstatus[#wp]=RAT.status.DescentHolding
    end
  end
  
  -- Holding and final destination.
  if landing==RAT.wp.landing then

    -- Holding point
    c[#c+1]=Pholding  
    wp[#wp+1]=self:_Waypoint(#wp+1, "Holding Point", RAT.wp.holding, c[#wp+1], VxHolding, H_holding+h_holding)
    self.waypointdescriptions[#wp]="Holding Point"
    self.waypointstatus[#wp]=RAT.status.Holding
    wpholding=#wp

    -- Final destination.
    c[#c+1]=Pdestination    
    wp[#wp+1]=self:_Waypoint(#wp+1, "Final Destination", landing, c[#wp+1], VxFinal, H_destination, destination)
    self.waypointdescriptions[#wp]="Final Destination"
    self.waypointstatus[#wp]=RAT.status.Destination
    
  end
  
  -- Final Waypoint
  wpfinal=#wp
  
  -- Fill table with waypoints.
  local waypoints={}
  for _,p in ipairs(wp) do
    table.insert(waypoints, p)
  end
      
  -- Some info on the route.
  self:_Routeinfo(waypoints, "Waypoint info in set_route:")
  
  -- Return departure, destination and waypoints.
  if self.returnzone then
    -- We return the actual zone here because returning the departure leads to problems with commute.
    return departure, destination_returnzone, waypoints, wpholding, wpfinal    
  else
    return departure, destination, waypoints, wpholding, wpfinal
  end
  
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
 
  if self.random_departure then
  
    -- Airports of friendly coalitions.
    for _,airport in pairs(self.airports) do
    
      local name=airport:GetName()
      if not self:_Excluded(name) then
        if takeoff==RAT.wp.air then
          table.insert(departures, airport:GetZone())  -- insert zone object.
        else
          table.insert(departures, airport)            -- insert airport object.
        end
      end
      
    end
    
  else
 
    -- Destination airports or zones specified by user.
    for _,name in pairs(self.departure_ports) do
              
      local dep=nil
      if self:_AirportExists(name) then
        if takeoff==RAT.wp.air then
          dep=AIRBASE:FindByName(name):GetZone()
        else
          dep=AIRBASE:FindByName(name)
        end
      elseif self:_ZoneExists(name) then
        if takeoff==RAT.wp.air then
          dep=ZONE:New(name)
        else
          self:E(RAT.id..string.format("ERROR! Takeoff is not in air. Cannot use %s as departure.", name))
        end
      else
        self:E(RAT.id..string.format("ERROR: No airport or zone found with name %s.", name))
      end
      
      -- Add to departures table.
      if dep then
        table.insert(departures, dep)
      end
        
    end 
   
  end
  
    -- Info message.
  self:T(RAT.id..string.format("Number of possible departures for %s= %d", self.alias, #departures))
  
  -- Select departure airport or zone.
  local departure=departures[math.random(#departures)]
  
  local text
  if departure and departure:GetName() then
    if takeoff==RAT.wp.air then
      text=string.format("%s: Chosen departure zone: %s", self.alias, departure:GetName())
    else
      text=string.format("%s: Chosen departure airport: %s (ID %d)", self.alias, departure:GetName(), departure:GetID())
    end
    --MESSAGE:New(text, 30):ToAllIf(self.Debug)
    self:T(RAT.id..text)
  else
    self:E(RAT.id..string.format("ERROR! No departure airport or zone found for %s.", self.alias))
    departure=nil
  end
  
  return departure
end

--- Pick destination airport or zone depending on departure position.
-- @param #RAT self
-- @param Wrapper.Airbase#AIRBASE departure Departure airport or zone.
-- @param Core.Point#COORDINATE q Coordinate of the departure point.
-- @param #number minrange Minimum range to q in meters.
-- @param #number maxrange Maximum range to q in meters.
-- @param #boolean random Destination is randomly selected from friendly airport (true) or from destinations specified by user input (false).
-- @param #number landing Number indicating whether we land at a destination airport or fly to a zone object.
-- @return Wrapper.Airbase#AIRBASE destination Destination airport or zone.
function RAT:_PickDestination(departure, q, minrange, maxrange, random, landing)

  -- Min/max range to destination.
  minrange=minrange or self.mindist
  maxrange=maxrange or self.maxdist

  -- All possible destinations.
  local destinations={}
  
  if random then
  
    -- Airports of friendly coalitions.
    for _,airport in pairs(self.airports) do
      local name=airport:GetName()
      if self:_IsFriendly(name) and not self:_Excluded(name) and name~=departure:GetName() then
      
        -- Distance from departure to possible destination
        local distance=q:Get2DDistance(airport:GetCoordinate())
        
        -- Check if distance form departure to destination is within min/max range.
        if distance>=minrange and distance<=maxrange then
          if landing==RAT.wp.air then
            table.insert(destinations, airport:GetZone())  -- insert zone object.
          else
            table.insert(destinations, airport)            -- insert airport object.
          end
        end
      end
    end
    
  else
 
    -- Destination airports or zones specified by user.
    for _,name in pairs(self.destination_ports) do
        
      -- Make sure departure and destination are not identical.
      if name ~= departure:GetName() then

        local dest=nil
        if self:_AirportExists(name) then
          if landing==RAT.wp.air then
            dest=AIRBASE:FindByName(name):GetZone()
          else
            dest=AIRBASE:FindByName(name)
          end
        elseif self:_ZoneExists(name) then
          if landing==RAT.wp.air then
            dest=ZONE:New(name)
          else
            self:E(RAT.id..string.format("ERROR! Landing is not in air. Cannot use zone %s as destination!", name))
          end
        else
          self:E(RAT.id..string.format("ERROR! No airport or zone found with name %s", name))
        end
        
        if dest then
          -- Distance from departure to possible destination
          local distance=q:Get2DDistance(dest:GetCoordinate())
            
          -- Add as possible destination if zone is within range.
          if distance>=minrange and distance<=maxrange then
            table.insert(destinations, dest)
          else
            local text=string.format("Destination %s is ouside range. Distance = %5.1f km, min = %5.1f km, max = %5.1f km.", name, distance, minrange, maxrange)
            self:T(RAT.id..text)
          end
        end
        
      end
    end 
  end
  
  -- Info message.
  self:T(RAT.id..string.format("Number of possible destinations = %s.", #destinations))
  
  if #destinations > 0 then
    --- Compare distance of destination airports.
    -- @param Core.Point#COORDINATE a Coordinate of point a.
    -- @param Core.Point#COORDINATE b Coordinate of point b.
    -- @return #list Table sorted by distance.
    local function compare(a,b)
      local qa=q:Get2DDistance(a:GetCoordinate())
      local qb=q:Get2DDistance(b:GetCoordinate())
      return qa < qb
    end
    table.sort(destinations, compare)
  else
    destinations=nil
  end
  
  
  -- Randomly select one possible destination.
  local destination
  if destinations and #destinations>0 then
  
    -- Random selection.
    destination=destinations[math.random(#destinations)] -- Wrapper.Airbase#AIRBASE
  
    -- Debug message.
    local text
    if landing==RAT.wp.air then
      text=string.format("%s: Chosen destination zone: %s.", self.alias, destination:GetName())
    else
      text=string.format("%s Chosen destination airport: %s (ID %d).", self.alias, destination:GetName(), destination:GetID())
    end
    self:T(RAT.id..text)
    --MESSAGE:New(text, 30):ToAllIf(self.Debug)
    
  else
    self:E(RAT.id.."ERROR! No destination airport or zone found.")
    destination=nil
  end
  
  -- Return the chosen destination.
  return destination  
  
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
      
      local text="MOOSE: Airport ID = ".._myab:GetID().." and Name = ".._myab:GetName()..", Category = ".._myab:GetCategory()..", TypeName = ".._myab:GetTypeName()
      self:T(RAT.id..text)
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
    local text="ERROR! No possible departure/destination airports found."
    MESSAGE:New(text, 30):ToAll()
    self:E(RAT.id..text)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Report status of RAT groups.
-- @param #RAT self
-- @param #boolean message (Optional) Send message with report to all if true.
-- @param #number forID (Optional) Send message only for this ID.
function RAT:Status(message, forID)

  -- Optional arguments.
  if message==nil then
    message=false
  end  
  if forID==nil then
    forID=false
  end
  
  -- Current time.
  local Tnow=timer.getTime()
    
  -- Loop over all ratcraft.  
  for spawnindex,ratcraft in ipairs(self.ratcraft) do
  
    -- Get group.
    local group=ratcraft.group  --Wrapper.Group#GROUP
    
    if group and group:IsAlive() then
            
      -- Gather some information.
      local prefix=self:_GetPrefixFromGroup(group)
      local life=self:_GetLife(group)
      local fuel=group:GetFuel()*100.0
      local airborne=group:InAir()
      local coords=group:GetCoordinate()
      local alt=coords.y
      --local vel=group:GetVelocityKMH()
      local departure=ratcraft.departure:GetName()
      local destination=ratcraft.destination:GetName()
      local type=self.aircraft.type
      local status=ratcraft.status
      local active=ratcraft.active
      local Nunits=ratcraft.nunits -- group:GetSize()
      local N0units=group:GetInitialSize()
             
      -- Monitor time and distance on ground.
      local Tg=0
      local Dg=0
      local dTlast=0
      local stationary=false --lets assume, we did move
      if airborne then
        -- Aircraft is airborne.
        ratcraft["Tground"]=nil
        ratcraft["Pground"]=nil
        ratcraft["Tlastcheck"]=nil
      else
        --Aircraft is on ground.
        if ratcraft["Tground"] then
          -- Aircraft was already on ground. Calculate total time on ground.
          Tg=Tnow-ratcraft["Tground"]
          
          -- Distance on ground since last check.
          Dg=coords:Get2DDistance(ratcraft["Pground"])
          
          -- Time interval since last check.
          dTlast=Tnow-ratcraft["Tlastcheck"]
          
          -- If more than Tinactive seconds passed since last check ==> check how much we moved meanwhile.
          if dTlast > self.Tinactive then
                  
            -- If aircraft did not move more than 50 m since last check, we call it stationary and despawn it.
            -- Aircraft which are spawned uncontrolled or starting their engines are not counted. 
            if Dg<50 and active and status~=RAT.status.EventBirth then
            --if Dg<50 and active then
              stationary=true
            end
            
             -- Set the current time to know when the next check is necessary.
            ratcraft["Tlastcheck"]=Tnow
            ratcraft["Pground"]=coords
          end
          
        else
          -- First time we see that the aircraft is on ground. Initialize the times and position.
          ratcraft["Tground"]=Tnow
          ratcraft["Tlastcheck"]=Tnow
          ratcraft["Pground"]=coords
        end
      end
      
      -- Monitor travelled distance since last check.
      local Pn=coords
      local Dtravel=Pn:Get2DDistance(ratcraft["Pnow"])
      ratcraft["Pnow"]=Pn
      
      -- Add up the travelled distance.
      ratcraft["Distance"]=ratcraft["Distance"]+Dtravel
      
      -- Distance remaining to destination.
      local Ddestination=Pn:Get2DDistance(ratcraft.destination:GetCoordinate())
   
      -- Status report.
      if (forID and spawnindex==forID) or (not forID) then
        local text=string.format("ID %i of flight %s", spawnindex, prefix)
        if N0units>1 then
          text=text..string.format(" (%d/%d)\n", Nunits, N0units)
        else
          text=text.."\n"
        end
        if self.commute then
          text=text..string.format("%s commuting between %s and %s\n", type, departure, destination)
        elseif self.continuejourney then
          text=text..string.format("%s travelling from %s to %s (and continueing form there)\n", type, departure, destination)
        else
          text=text..string.format("%s travelling from %s to %s\n", type, departure, destination)
        end
        text=text..string.format("Status: %s", status)
        if airborne then
          text=text.." [airborne]\n"
        else
          text=text.." [on ground]\n"
        end
        text=text..string.format("Fuel = %3.0f %%\n", fuel)
        text=text..string.format("Life  = %3.0f %%\n", life)
        text=text..string.format("FL%03d = %i m ASL\n", alt/RAT.unit.FL2m, alt)
        --text=text..string.format("Speed = %i km/h\n", vel)
        text=text..string.format("Distance travelled        = %6.1f km\n", ratcraft["Distance"]/1000)
        text=text..string.format("Distance to destination = %6.1f km", Ddestination/1000)
        if not airborne then
          text=text..string.format("\nTime on ground  = %6.0f seconds\n", Tg)
          text=text..string.format("Position change = %8.1f m since %3.0f seconds.", Dg, dTlast)
        end
        self:T2(RAT.id..text)
        if message then
          MESSAGE:New(text, 20):ToAll()
        end
      end
      
      -- Despawn groups if they are on ground and don't move or are damaged.
      if not airborne then
      
        -- Despawn unit if it did not move more then 50 m in the last 180 seconds.
        if stationary then
          local text=string.format("Group %s is despawned after being %d seconds inaktive on ground.", self.alias, dTlast)
          self:T(RAT.id..text)
          self:_Despawn(group)
        end
        -- Despawn group if life is < 10% and distance travelled < 100 m.
        if life<10 and Dtravel<100 then
          local text=string.format("Damaged group %s is despawned. Life = %3.0f", self.alias, life)
          self:T(RAT.id..text)
          self:_Despawn(group)
        end
      end
      
      -- Despawn groups after they have reached their destination zones.
      if ratcraft.despawnme then
        local text=string.format("Flight %s will be despawned NOW!", self.alias)
        self:T(RAT.id..text)
        -- Despawn old group.
        if (not self.norespawn) and (not self.respawn_after_takeoff) then  
          self:_Respawn(group)
        end
        self:_Despawn(group)
      end

    else
      -- Group does not exist.
      local text=string.format("Group does not exist in loop ratcraft status.")
      self:T2(RAT.id..text)
    end
       
  end
  
  if (message and not forID) then
    local text=string.format("Alive groups of %s: %d", self.alias, self.alive)
    self:T(RAT.id..text)
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
      self:T2(RAT.id.."ERROR! Unit does not exist in RAT_Getlife(). Returning zero.")
    end
  else
    self:T2(RAT.id.."ERROR! Group does not exist in RAT_Getlife(). Returning zero.")
  end
  return life
end

--- Set status of group.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group.
-- @param #string status Status of group.
function RAT:_SetStatus(group, status)

  if group and group:IsAlive() then

    -- Get index from groupname.
    local index=self:GetSpawnIndexFromGroup(group)
    
    if self.ratcraft[index] then
    
      -- Set new status.
      self.ratcraft[index].status=status
      
      -- No status update message for "first waypoint", "holding"
      local no1 = status==RAT.status.Departure
      local no2 = status==RAT.status.EventBirthAir
      local no3 = status==RAT.status.Holding
      
      local text=string.format("Flight %s: %s.", group:GetName(), status)
      self:T(RAT.id..text)
      
      if (not (no1 or no2 or no3)) then
        MESSAGE:New(text, 10):ToAllIf(self.reportstatus)
      end
      
    end
    
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function is executed when a unit is spawned.
-- @param #RAT self
-- @param Core.Event#EVENTDATA EventData
function RAT:_OnBirth(EventData)
  self:F3(EventData)
  self:T3(RAT.id.."Captured event birth!")

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
    
        local text="Event: Group "..SpawnGroup:GetName().." was born."
        self:T(RAT.id..text)
        
        -- Set status.
        local status="unknown in birth"
        if SpawnGroup:InAir() then
          status=RAT.status.EventBirthAir
        elseif self.uncontrolled then
          status=RAT.status.Uncontrolled
        else
          status=RAT.status.EventBirth
        end
        self:_SetStatus(SpawnGroup, status)
               
        -- Get some info ablout this flight. 
        local i=self:GetSpawnIndexFromGroup(SpawnGroup)
        local _departure=self.ratcraft[i].departure:GetName()
        local _destination=self.ratcraft[i].destination:GetName()
        local _nrespawn=self.ratcraft[i].nrespawn
        local _takeoff=self.ratcraft[i].takeoff
        local _landing=self.ratcraft[i].landing
        local _livery=self.ratcraft[i].livery
        
        -- Check if aircraft group was accidentally spawned on the runway.
        -- This can happen due to no parking slots available and other DCS bugs.
        local onrunway=false
        if _takeoff ~= RAT.wp.runway and self.checkonrunway then
          for _,unit in pairs(SpawnGroup:GetUnits()) do
            local _onrunway=self:_CheckOnRunway(unit, _departure)
            if _onrunway then
              onrunway=true
            end
          end
        end     
        
        -- Workaround if group was spawned on runway.
        if onrunway then
             
          -- Error message.
          local text=string.format("ERROR: RAT group of %s was spawned on runway (DCS bug). Group #%d will be despawned immediately!", self.alias, i)
          MESSAGE:New(text,30):ToAllIf(self.Debug)
          self:T(RAT.id..text)
          if self.Debug then
            SpawnGroup:FlareRed()
          end
                   
          -- Despawn the group.
          self:_Despawn(SpawnGroup)
          
          -- Try to respawn the group if there is at least another airport or random airport selection is used.
          if (self.Ndeparture_Airports>=2 or self.random_departure) and _nrespawn<self.rbug_maxretry then
            -- Increase counter.
            _nrespawn=_nrespawn+1
          
            -- This creates a completely new group, i.e. livery etc from earlier flights (continuejourney, commute) is not taken over.
            text=string.format("Try spawning new aircraft of group %s at another location. Attempt %d of max %d.", self.alias,_nrespawn,self.rbug_maxretry)
            MESSAGE:New(text,10):ToAllIf(self.Debug)
            self:T(RAT.id..text)
            
            -- Spawn new group.
            self:_SpawnWithRoute(nil, nil, nil, nil, nil, nil, nil, _nrespawn)
          else
            -- This will respawn the same fight (maybe with a different route) but already in the air.
            -- Note: Uncontrolled aircraft are not respawned in air.  
            if self.respawn_inair and not self.uncontrolled then
              text=string.format("Spawning new aircraft of group %s in air since no parking slot is available at %s.", self.alias, _departure)
              MESSAGE:New(text,10):ToAll()
              self:T(RAT.id..text)
            
              -- Spawn new group at this airport but already in air.
              self:_SpawnWithRoute(_departure, _destination, RAT.wp.air, _landing, _livery)
            end
          end  
        end -- end of workaround
        
        -- Check if any unit of the group was spawned on top of another unit in the MOOSE data base.
        local ontop=false
        if self.checkontop then
          ontop=self:_CheckOnTop(SpawnGroup)
        end
        
        if ontop then
          local text=string.format("ERROR: RAT group of %s was spawned on top of another unit. Group #%d will be despawned immediately!", self.alias, i)
          MESSAGE:New(text,30):ToAllIf(self.Debug)
          self:T(RAT.id..text)
          if self.Debug then
            SpawnGroup:FlareYellow()
          end
          -- Despawn group.
          self:_Despawn(SpawnGroup)
        end
        
      end
    end
  else
    self:T2(RAT.id.."ERROR: Group does not exist in RAT:_OnBirth().")
  end
end


--- Function is executed when a unit starts its engines.
-- @param #RAT self
-- @param Core.Event#EVENTDATA EventData
function RAT:_OnEngineStartup(EventData)
  self:F3(EventData)
  self:T3(RAT.id.."Captured event EngineStartup!")

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        local text="Event: Group "..SpawnGroup:GetName().." started engines."
        self:T(RAT.id..text)
    
        -- Set status.
        local status
        if SpawnGroup:InAir() then
          status=RAT.status.EventEngineStartAir
        else
          status=RAT.status.EventEngineStart
        end
        self:_SetStatus(SpawnGroup, status)
      end
    end
    
  else
    self:T2(RAT.id.."ERROR: Group does not exist in RAT:_EngineStartup().")
  end
end

--- Function is executed when a unit takes off.
-- @param #RAT self
-- @param Core.Event#EVENTDATA EventData
function RAT:_OnTakeoff(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        local text="Event: Group "..SpawnGroup:GetName().." is airborne."
        self:T(RAT.id..text)
    
        -- Set status.
        local status=RAT.status.EventTakeoff
        self:_SetStatus(SpawnGroup, status)
        
        if self.respawn_after_takeoff then
          text="Event: Group "..SpawnGroup:GetName().." will be respawned."
          self:T(RAT.id..text)
        
          -- Respawn group. We respawn with no parameters from the old flight.
          self:_SpawnWithRoute(nil, nil, nil, nil, nil, nil, nil, nil)
          --self:_Respawn(SpawnGroup)
        end
        
      end
    end
    
  else
    self:T2(RAT.id.."ERROR: Group does not exist in RAT:_OnTakeoff().")
  end
end

--- Function is executed when a unit lands.
-- @param #RAT self
-- @param Core.Event#EVENTDATA EventData
function RAT:_OnLand(EventData)

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        local text="Event: Group "..SpawnGroup:GetName().." landed."
        self:T(RAT.id..text)
    
        -- Set status.
        local status=RAT.status.EventLand
        self:_SetStatus(SpawnGroup, status)

        -- ATC plane landed. Take it out of the queue and set runway to free.
        if self.ATCswitch then
          RAT:_ATCFlightLanded(SpawnGroup:GetName())
        end        
        
        if self.respawn_at_landing and not self.norespawn then
          text="Event: Group "..SpawnGroup:GetName().." will be respawned."
          self:T(RAT.id..text)
        
          -- Respawn group.
          self:_Respawn(SpawnGroup)
        end
        
      end
    end
    
  else
    self:T2(RAT.id.."ERROR: Group does not exist in RAT:_OnLand().")
  end
end

--- Function is executed when a unit shuts down its engines.
-- @param #RAT self
function RAT:_OnEngineShutdown(EventData)
  self:F3(EventData)
  self:T3(RAT.id.."Captured event EngineShutdown!")

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        -- Despawn group only if it on the ground.
        if not SpawnGroup:InAir() then
        
          local text="Event: Group "..SpawnGroup:GetName().." shut down its engines."
          self:T(RAT.id..text)
      
          -- Set status.
          local status=RAT.status.EventEngineShutdown
          self:_SetStatus(SpawnGroup, status)
          
          if not self.respawn_at_landing and not self.norespawn then
            text="Event: Group "..SpawnGroup:GetName().." will be respawned."
            self:T(RAT.id..text)
          
            -- Respawn group.
            self:_Respawn(SpawnGroup)
          end
                   
          -- Despawn group.
          text="Event: Group "..SpawnGroup:GetName().." will be destroyed now."
          self:T(RAT.id..text)
          self:_Despawn(SpawnGroup)

        end
      end
    end
    
  else
    self:T2(RAT.id.."ERROR: Group does not exist in RAT:_OnEngineShutdown().")
  end
end

--- Function is executed when a unit is hit.
-- @param #RAT self
-- @param Core.Event#EVENTDATA EventData
function RAT:_OnHit(EventData)
  self:F3(EventData)
  self:T(RAT.id..string.format("Captured event Hit by %s! Initiator %s. Target %s", self.alias, tostring(EventData.IniUnitName), tostring(EventData.TgtUnitName)))
  
  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
      
        -- Debug info.
        self:T(RAT.id..string.format("Event: Group %s was hit. Unit %s.", SpawnGroup:GetName(), EventData.IniUnitName))
        
      end
    end
  end
end

--- Function is executed when a unit is dead or crashes.
-- @param #RAT self
-- @param Core.Event#EVENTDATA EventData
function RAT:_OnDeadOrCrash(EventData)
  self:F3(EventData)
  self:T3(RAT.id.."Captured event DeadOrCrash!")
    
  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
      
        -- Decrease group alive counter.
        self.alive=self.alive-1
        
        -- Debug info.
        local text=string.format("Event: Group %s crashed or died. Alive counter = %d.", SpawnGroup:GetName(), self.alive) 
        self:T(RAT.id..text)
  
        -- Split crash and dead events.
        if EventData.id == world.event.S_EVENT_CRASH  then
          
          -- Call crash event. This handles when a group crashed or 
          self:_OnCrash(EventData)
  
        elseif EventData.id == world.event.S_EVENT_DEAD  then
  
          -- Call dead event.
          self:_OnDead(EventData)
  
        end
      end
    end
  end
end

--- Function is executed when a unit is dead.
-- @param #RAT self
-- @param Core.Event#EVENTDATA EventData
function RAT:_OnDead(EventData)
  self:F3(EventData)
  self:T3(RAT.id.."Captured event Dead!")
  
  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then
  
    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
  
        local text=string.format("Event: Group %s died. Unit %s.", SpawnGroup:GetName(), EventData.IniUnitName) 
        self:T(RAT.id..text)
    
        -- Set status.
        local status=RAT.status.EventDead
        self:_SetStatus(SpawnGroup, status)
        
      end
    end

  else
    self:T2(RAT.id.."ERROR: Group does not exist in RAT:_OnDead().")
  end
end

--- Function is executed when a unit crashes.
-- @param #RAT self
-- @param Core.Event#EVENTDATA EventData
function RAT:_OnCrash(EventData)
  self:F3(EventData)
  self:T3(RAT.id.."Captured event Crash!")

  local SpawnGroup = EventData.IniGroup --Wrapper.Group#GROUP
  
  if SpawnGroup then

    -- Get the template name of the group. This can be nil if this was not a spawned group.
    local EventPrefix = self:_GetPrefixFromGroup(SpawnGroup)
    
    if EventPrefix then
    
      -- Check that the template name actually belongs to this object.
      if EventPrefix == self.alias then
          
        -- Update number of alive units in the group.
        local _i=self:GetSpawnIndexFromGroup(SpawnGroup)
        self.ratcraft[_i].nunits=self.ratcraft[_i].nunits-1
        local _n=self.ratcraft[_i].nunits
        local _n0=SpawnGroup:GetInitialSize()
       
        -- Debug info. 
        local text=string.format("Event: Group %s crashed. Unit %s. Units still alive %d of %d.", SpawnGroup:GetName(), EventData.IniUnitName, _n, _n0)
        self:T(RAT.id..text)
       
        -- Set status.
        local status=RAT.status.EventCrash
        self:_SetStatus(SpawnGroup, status)
        
        -- Respawn group if all units are dead.
        if _n==0 and self.respawn_after_crash and not self.norespawn then
          local text=string.format("No units left of group %s. Group will be respawned now.", SpawnGroup:GetName())
          self:T(RAT.id..text)
          -- Respawn group.
          self:_Respawn(SpawnGroup)
        end

        --TODO: Maybe spawn some people at the crash site and send a distress call.
        --      And define them as cargo which can be rescued.
      end
    end
    
  else
    if self.Debug then
      self:E(RAT.id.."ERROR: Group does not exist in RAT:_OnCrash().")
    end
  end
end

--- Despawn unit. Unit gets destoyed and group is set to nil.
-- Index of ratcraft array is taken from spawned group name.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group to be despawned.
function RAT:_Despawn(group)

  if group ~= nil then
  
    -- Get spawnindex of group.
    local index=self:GetSpawnIndexFromGroup(group)
    
    if index ~= nil then
    
      self.ratcraft[index].group=nil
      self.ratcraft[index]["status"]="Dead"
      
      --TODO: Maybe here could be some more arrays deleted?      
      --TODO: Somehow this causes issues.
      --[[
      --self.ratcraft[index]["group"]=group
      self.ratcraft[index]["destination"]=nil
      self.ratcraft[index]["departure"]=nil
      self.ratcraft[index]["waypoints"]=nil
      self.ratcraft[index]["airborne"]=nil
      self.ratcraft[index]["Tground"]=nil
      self.ratcraft[index]["Pground"]=nil
      self.ratcraft[index]["Tlastcheck"]=nil
      self.ratcraft[index]["P0"]=nil
      self.ratcraft[index]["Pnow"]=nil
      self.ratcraft[index]["Distance"]=nil
      self.ratcraft[index].takeoff=nil
      self.ratcraft[index].landing=nil
      self.ratcraft[index].wpholding=nil
      self.ratcraft[index].wpfinal=nil
      self.ratcraft[index].active=false
      self.ratcraft[index]["status"]=nil
      self.ratcraft[index].livery=nil
      self.ratcraft[index].despawnme=nil
      self.ratcraft[index].nrespawn=nil
      ]]
      -- Remove ratcraft table entry.
      --table.remove(self.ratcraft, index)
      
      
      -- This will destroy the DCS group and create a single DEAD event.
      self:_Destroy(group)

      -- Remove submenu for this group.
      if self.f10menu and self.SubMenuName ~= nil then
        self.Menu[self.SubMenuName]["groups"][index]:Remove()
      end
      
    end
  end
end

--- Destroys the RAT DCS group and all of its DCS units.
-- Note that this raises a DEAD event at run-time.
-- So all event listeners will catch the DEAD event of this DCS group.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group The RAT group to be destroyed.
function RAT:_Destroy(group)
  self:F2(group)

  local DCSGroup = group:GetDCSObject() -- Dcs.DCSGroup#Group

  if DCSGroup and DCSGroup:isExist() then
  
    --local DCSUnit = DCSGroup:getUnit(1) -- Dcs.DCSUnit#Unit
    --if DCSUnit then
    --  self:_CreateEventDead(timer.getTime(), DCSUnit)
    --end
    
    -- Cread one single Dead event and delete units from database.
    local triggerdead=true
    for _,DCSUnit in pairs(DCSGroup:getUnits()) do
    
      -- Dead event.
      if DCSUnit then
        if triggerdead then
          self:_CreateEventDead(timer.getTime(), DCSUnit)
          triggerdead=false
        end
      
        -- Delete from data base.
        _DATABASE:DeleteUnit(DCSUnit:getName())
      end
    end
    
    -- Destroy DCS group.
    DCSGroup:destroy()
    DCSGroup = nil
  end

  return nil
end

--- Create a Dead event.
-- @param #RAT self
-- @param Dcs.DCSTypes#Time EventTime The time stamp of the event.
-- @param Dcs.DCSWrapper.Object#Object Initiator The initiating object of the event.
function RAT:_CreateEventDead(EventTime, Initiator)
  self:F( { EventTime, Initiator } )

  local Event = {
    id = world.event.S_EVENT_DEAD,
    time = EventTime,
    initiator = Initiator,
    }

  world.onEvent( Event )
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a waypoint that can be used with the Route command.
-- @param #RAT self
-- @param #number index Running index of waypoints. Starts with 1 which is normally departure/spawn waypoint.
-- @param #string description Descrition of Waypoint.
-- @param #number Type Type of waypoint.
-- @param Core.Point#COORDINATE Coord 3D coordinate of the waypoint.
-- @param #number Speed Speed in m/s.
-- @param #number Altitude Altitude in m.
-- @param Wrapper.Airbase#AIRBASE Airport Airport of object to spawn.
-- @return #table Waypoints for DCS task route or spawn template.
function RAT:_Waypoint(index, description, Type, Coord, Speed, Altitude, Airport)

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
    _Altitude = 10
    _alttype="RADIO"
  elseif Type==RAT.wp.hot then
    -- take-off with engine on 
    _Type="TakeOffParkingHot"
    _Action="From Parking Area Hot"
    _Altitude = 10
    _alttype="RADIO"
  elseif Type==RAT.wp.runway then
    -- take-off from runway
    _Type="TakeOff"
    _Action="From Parking Area"
    _Altitude = 10
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
    _Action="Turning Point"
    --_Action="Fly Over Point"
    _alttype="BARO"
  elseif Type==RAT.wp.landing then
    _Type="Land"
    _Action="Landing"
    _Altitude = 10
    _alttype="RADIO"
  elseif Type==RAT.wp.finalwp then
    _Type="Turning Point"
    --_Action="Fly Over Point"
    _Action="Turning Point"
    _alttype="BARO"
  else
    self:E(RAT.id.."ERROR: Unknown waypoint type in RAT:Waypoint() function!")
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
  self:T2(RAT.id..text)
    
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
  -- waypoint description
  RoutePoint.name=description
  
  if (Airport~=nil) and (Type~=RAT.wp.air) then
    local AirbaseID = Airport:GetID()
    local AirbaseCategory = Airport:GetDesc().category
    if AirbaseCategory == Airbase.Category.SHIP then
      RoutePoint.linkUnit = AirbaseID
      RoutePoint.helipadId = AirbaseID
      --self:T(RAT.id.."WP: Ship id = "..AirbaseID)
    elseif AirbaseCategory == Airbase.Category.HELIPAD then
      RoutePoint.linkUnit = AirbaseID
      RoutePoint.helipadId = AirbaseID
      --self:T(RAT.id.."WP: Helipad id = "..AirbaseID)
    elseif AirbaseCategory == Airbase.Category.AIRDROME then
      RoutePoint.airdromeId = AirbaseID
      --self:T(RAT.id.."WP: Airdrome id = "..AirbaseID)
    else
      --self:E(RAT.id.."Unknown Airport categoryin _Waypoint()!")
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
    text=text..string.format("Distance from WP %i-->%i = %6.1f km. Heading = %03d :  %s - %s\n", i-1, i, d/1000, heading, self.waypointdescriptions[i], self.waypointdescriptions[i+1])
  end
  text=text..string.format("Total distance = %6.1f km\n", total/1000)
  text=text..string.format("******************************************************\n")
  
  -- Debug info.
  self:T2(RAT.id..text)
  
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
    -- Set stop condition for holding. Either flag=1 or after max. X min holding.
    local userflagname=string.format("%s#%03d", self.alias, self.SpawnIndex+1)
    local maxholdingduration=60*120
    DCSTask.params.stopCondition={userFlag=userflagname, userFlagValue=1, duration=maxholdingduration}
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
  local landing=rat.ratcraft[sdx].landing
  local WPholding=rat.ratcraft[sdx].wpholding
  local WPfinal=rat.ratcraft[sdx].wpfinal
  
  
  -- For messages
  local text
  
  -- Info on passing waypoint.
  text=string.format("Flight %s passing waypoint #%d %s.", group:GetName(), wp, rat.waypointdescriptions[wp])
  BASE.T(rat, RAT.id..text)
    
  -- New status.
  local status=rat.waypointstatus[wp]
  rat:_SetStatus(group, status)
    
  if wp==WPholding then
  
    -- Aircraft arrived at holding point
    text=string.format("Flight %s to %s ATC: Holding and awaiting landing clearance.", group:GetName(), destination)
    MESSAGE:New(text, 10):ToAllIf(rat.reportstatus)
     
    -- Register aircraft at ATC.
    if rat.ATCswitch then
      if rat.f10menu then
        MENU_MISSION_COMMAND:New("Clear for landing", rat.Menu[rat.SubMenuName].groups[sdx], rat.ClearForLanding, rat, group:GetName())
      end
      rat._ATCRegisterFlight(rat, group:GetName(), Tnow)
    end
  end
  
  if wp==WPfinal then
    text=string.format("Flight %s arrived at final destination %s.", group:GetName(), destination)
    MESSAGE:New(text, 10):ToAllIf(rat.reportstatus)
    BASE.T(rat, RAT.id..text)
  
    if landing==RAT.wp.air then
      text=string.format("Activating despawn switch for flight %s! Group will be detroyed soon.", group:GetName())
      MESSAGE:New(text, 10):ToAllIf(rat.Debug)
      BASE.T(rat, RAT.id..text)
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

  return DCSTask
end

--- Anticipated group name from alias and spawn index.
-- @param #RAT self
-- @param #number index Spawnindex of group if given or self.SpawnIndex+1 by default.  
-- @return #string Name the group will get after it is spawned.
function RAT:_AnticipatedGroupName(index)
  local index=index or self.SpawnIndex+1
  return string.format("%s#%03d", self.alias, index)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Randomly activates an uncontrolled aircraft.
-- @param #RAT self
function RAT:_ActivateUncontrolled()
  self:F()
  
  -- Spawn indices of uncontrolled inactive aircraft. 
  local idx={}
  local rat={}
  
  -- Number of active aircraft.
  local nactive=0
  
  -- Loop over RAT groups and count the active ones.
  for spawnindex,ratcraft in pairs(self.ratcraft) do
  
    local group=ratcraft.group --Wrapper.Group#GROUP
    
    if group and group:IsAlive() then
  
      local text=string.format("Uncontrolled: Group = %s (spawnindex = %d), active = %s.", ratcraft.group:GetName(), spawnindex, tostring(ratcraft.active))
      self:T2(RAT.id..text)

      if ratcraft.active then
        nactive=nactive+1
      else
        table.insert(idx, spawnindex)
      end
    
    end
  end
  
  -- Debug message.
  local text=string.format("Uncontrolled: Ninactive = %d,  Nactive = %d (of max %d).", #idx, nactive, self.activate_max)
  self:T(RAT.id..text)
  
  if #idx>0 and nactive<self.activate_max then
  
    -- Randomly pick on group, which is activated.
    local index=idx[math.random(#idx)]
    
    -- Get corresponding group.
    local group=self.ratcraft[index].group --Wrapper.Group#GROUP
    
    -- Start aircraft.
    self:_CommandStartUncontrolled(group)
  end

end

--- Start uncontrolled aircraft group.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group to be activated.
function RAT:_CommandStartUncontrolled(group)
  self:F(group)

  -- Start command.
  local StartCommand = {id = 'Start', params = {}}
  
  -- Debug message
  local text=string.format("Uncontrolled: Activating group %s.", group:GetName())
  self:T(RAT.id..text)
  
  -- Activate group.
  group:SetCommand(StartCommand)
  
  -- Spawn index.
  local index=self:GetSpawnIndexFromGroup(group)
  
  -- Set status to active.
  self.ratcraft[index].active=true
  
  -- Set status to "Ready and Starting Engines".
  self:_SetStatus(group, RAT.status.EventBirth)
end

--- Set RAT group to (in-)visible for other AI forces.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group to be set (in)visible.
-- @param #boolean switch If true, the group is invisible. If false the group will be visible.
function RAT:_CommandInvisible(group,switch)

  -- Command structure for setting groups to invisible.  
  local SetInvisible = {id = 'SetInvisible', params = {value = switch}}
  
  -- Execute command.
  group:SetCommand(SetInvisible)
end

--- Set RAT group to be (im-)mortal.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Group to be set (im-)mortal.
-- @param #boolean switch True enables immortality, false disables it.
function RAT:_CommandImmortal(group, switch)

  -- Command structure for setting groups to invisible.  
  local SetInvisible = {id = 'SetImmortal', params = {value = switch}}
  
  -- Execute command.
  group:SetCommand(SetInvisible)
end

--- Adds a parking spot at an airport when it has been used by a spawned RAT aircraft to the RAT parking data base.
-- This is mainly to circumvent (not perfectly) the DCS parking spot bug.
-- @param #RAT self
-- @param Wrapper.Airbase#AIRBASE airbase Airbase at which we add a parking spot.
-- @param Wrapper.Group#GROUP group Group to check for parking positions.
function RAT:_AddParkingSpot(airbase, group)

  -- Name of the airport.
  local airport=airbase:GetName()
  
  -- Radius of the parking spot in meters.
  local spotradius=15
    
  -- Init array for this airport if it does not exist.
  if not RAT.parking[airport] then
    RAT.parking[airport]={}
  end
  
  -- Debug info.
  self:T(RAT.id..string.format("Searching parking spot at airport %s. Number of currently known = %d.", airport, #RAT.parking[airport]))
    
  -- Loop over all units in the group.
  for _,_unit in pairs(group:GetUnits()) do

    -- Check if unit is on the runway.
    local onrunway=self:_CheckOnRunway(_unit, airport)

    if not onrunway then
      
      -- Coordinate of unit.    
      local coord=_unit:GetCoordinate()

      -- Loop over all known spots.
      local gotit=false    
      for _,_spot in pairs(RAT.parking[airport]) do
        local _spot=_spot -- Core.Point#COORDINATE
        local _dist=_spot:Get2DDistance(coord)
        
        -- Check if this spot is already known.
        if _dist < spotradius then
          gotit=true
          break
        end
      end
      
      -- Add spot spot if it not known already.
      if not gotit then
        table.insert(RAT.parking[airport], coord)
        -- Place marker for debugging.
        if self.Debug then
          coord:MarkToAll(string.format("%s parking spot #%d", airport, #RAT.parking[airport]))
        end
      end
    end
  end
end

--- Seach an unoccupied parking spot at a specific airport in the RAT parking data base.
-- @param #RAT self
-- @param Wrapper.Airbase#AIRBASE airbase The airbase where we want to find a parking position.
-- @return Core.Point#COORDINATE Coordinate of the parking spot.
function RAT:_FindParkingSpot(airbase)

  -- Get airport name.
  local airport=airbase:GetName()
  
  self:T(RAT.id..string.format("Checking spawn position DB for airport %s.", airport))

  if RAT.parking[airport] then
   self:T(RAT.id..string.format("Number of parking spots in DB for %s: %d", airport, #RAT.parking[airport]))
    
    local parkingspot --Core.Point#COORDINATE
  
    -- Loop over all known parking spots
    for _i,spawnplace in pairs(RAT.parking[airport]) do
    
      -- Loop over ALL units present.
      local occupied=false
      for _,unit in pairs(_DATABASE.UNITS) do
        local unit=unit --Wrapper.Unit#UNIT
        if unit then
          local _upos=unit:GetCoordinate() --Core.Point#COORDINATE
          if _upos then
            local _dist=_upos:Get2DDistance(spawnplace)
            
            -- We need two times the size of the aircraft to be "safe" and not spawn on top of each other.
            local safe=_dist > self.aircraft.box*2
            -- Or (if possible) even better to take our and the other object's size (plus 10% safety margin)
            local size=self:_GetObjectSize(unit)
            if size then
              safe=_dist > (self.aircraft.box+size)*1.1
            end
            self:T2(RAT.id..string.format("RAT aircraft size = %.1f m, other object size = %.1f m", self.aircraft.box, size or 0))
            if not safe then
              occupied=true
            end
            self:T2(RAT.id..string.format("Unit %s to parking spot %d: distance = %.1f m (occupied = %s).", unit:GetName(), _i, _dist, tostring(safe)))
          end
        end
      end
      
      if occupied then
        self:T(RAT.id..string.format("Parking spot #%d occupied at %s.", _i, airport))
      else
        parkingspot=spawnplace
        self:T(RAT.id..string.format("Found free parking spot in DB at airport %s.", airport))
        break
      end
      
    end
    
    return parkingspot
  else
    self:T2(RAT.id..string.format("No parking position in DB yet for %s.", airport))  
  end
  
  self:T(RAT.id..string.format("No free parking position found in DB at airport %s.", airport))  
  return nil
end

--- Get aircraft dimensions length, width, height.
-- @param #RAT self
-- @param Wrapper.Unit#UNIT unit The unit which is we want the size of.
-- @return #number Size, i.e. max(length,width) of unit.
function RAT:_GetObjectSize(unit)
  local DCSunit=unit:GetDCSObject()
  if DCSunit then
    local DCSdesc=DCSunit:getDesc()
    -- dimensions
    local length=DCSdesc.box.max.x
    local height=DCSdesc.box.max.y
    local width=DCSdesc.box.max.z
    return math.max(length,width)
  end
  return nil
end

--- Find aircraft that have accidentally been spawned on top of each other.
-- @param #RAT self
-- @param Wrapper.Group#GROUP group Units of this group will be checked.
-- @return #boolean True if group was destroyed because it was on top of another unit. False if otherwise.
function RAT:_CheckOnTop(group)

  -- Minimum allowed distance between two units
  local distmin=5
  
  for i,uniti in pairs(group:GetUnits()) do
    local uniti=uniti --Wrapper.Unit#UNIT
    
    if uniti then
    
      local namei=uniti:GetName()
      
      for j,unitj in pairs(_DATABASE.UNITS) do
      
        if unitj then
          local unitj=unitj --Wrapper.Unit#UNIT
          local namej=unitj:GetName()
          
          if namei ~= namej then
          
            local DCSuniti=uniti:GetDCSObject()
            local DCSunitj=unitj:GetDCSObject()
            
            if DCSuniti and DCSuniti:isExist() and DCSunitj and DCSunitj:isExist() then
            
              -- Distance between units.
              local _dist=uniti:GetCoordinate():Get2DDistance(unitj:GetCoordinate())
              
              -- Check for min distance.
              if _dist < distmin then
                if not uniti:InAir() and not unitj:InAir() then
                  --uniti:Destroy()
                  --self:_CreateEventDead(timer.getTime(), uniti)
                  --unitj:Destroy()
                  --self:_CreateEventDead(timer.getTime(), unitj)
                  return true
                end
              end
              
            end -- if DCSunit exists
          end -- if namei==namej then  
        end --if unitj then
      end -- for j, unitj  
    end -- if uniti then
  end -- for i,uniti in
  
  return false
end

--- Function to check whether an aircraft is on the runway.
-- @param #RAT self
-- @param Wrapper.Unit#UNIT unit The unit to be checked.
-- @param #string airport The name of the airport we want to check.
-- @return #boolean True if aircraft is on the runway and on the ground.
function RAT:_CheckOnRunway(unit, airport)

  -- We use the tabulated points in the ATC_GROUND classes to find out if the group is on the runway.
  -- Note that land.SurfaceType.RUNWAY also is true for the parking areas etc. Hence, not useful.
  -- This is useful to check if an aircraft was accidentally spawned on the runway due to missing parking spots.
  --BASE:E(ATC_GROUND_CAUCASUS.Airbases[AIRBASE.Caucasus.Batumi].PointsRunways)
  
  -- Table holding the points around the runway.
  local pointsrwy={}
  
  -- Loop over all airports on Caucaus map.
  for id,name in pairs(AIRBASE.Caucasus) do
    if name==airport then
      --pointsrwy=ATC_GROUND_CAUCASUS.Airbases[AIRBASE.Caucasus.Batumi].PointsRunways
      pointsrwy=ATC_GROUND_CAUCASUS.Airbases[name].PointsRunways
      self:T2({name=name, points=pointsrwy})
    end
  end
  -- Loop over all airports on NTTR map.
  for id,name in pairs(AIRBASE.Nevada) do
    if name==airport then
      pointsrwy=ATC_GROUND_NEVADA.Airbases[name].PointsRunways
      self:T2({name=name, points=pointsrwy})
    end
  end
  -- Loop over all airports on Normandy map.
  for id,name in pairs(AIRBASE.Normandy) do
    if name==airport then
      pointsrwy=ATC_GROUND_NORMANDY.Airbases[name].PointsRunways
      self:T2({name=name, points=pointsrwy})
    end
  end
  
  -- Assume we are not on the runway.
  local onrunway=false
  
  -- Loop over all runways. Some airports have more than one.
  for PointsRunwayID, PointsRunway in pairs(pointsrwy) do
    -- Create zone around runway.
    local runway = ZONE_POLYGON_BASE:New("Runway "..PointsRunwayID, PointsRunway)

    -- Check if unit is in on the runway.
    if runway:IsVec3InZone(unit:GetVec3()) then
      onrunway=true
    end
  end
  
  -- Check that aircraft is on ground.
  onrunway=onrunway and unit:InAir()==false
  
  -- Debug
  self:T(RAT.id..string.format("Check on runway of %s airport for unit %s = %s", airport, unit:GetName(),tostring(onrunway)))
  
  return onrunway
end


--- Calculate minimum distance between departure and destination for given minimum flight level and climb/decent rates.
-- @param #RAT self
-- @param #number alpha Angle of climb [rad].
-- @param #number beta Angle of descent [rad].
-- @param #number ha Height difference between departure and cruise altiude. 
-- @param #number hb Height difference between cruise altitude and destination.
-- @return #number d1 Minimum distance for climb phase to reach cruise altitude.
-- @return #number d2 Minimum distance for descent phase to reach destination height.
-- @return #number dtot Minimum total distance to climb and descent.
function RAT:_MinDistance(alpha, beta, ha, hb)
  local d1=ha/math.tan(alpha)
  local d2=hb/math.tan(beta)
  return d1, d2, d1+d2
end


--- Add names of all friendly airports to possible departure or destination airports if they are not already in the list. 
-- @param #RAT self
-- @param #table ports List of departure or destination airports/zones that will be added.
function RAT:_AddFriendlyAirports(ports)
  for _,airport in pairs(self.airports) do
    if not self:_NameInList(ports, airport:GetName()) then
      table.insert(ports, airport:GetName())
    end
  end
end

--- Check if a name/string is in a list or not.
-- @param #RAT self
-- @param #table liste List of names to be checked.
-- @param #string name Name to be checked for.
function RAT:_NameInList(liste, name)
  for _,item in pairs(liste) do
    if item==name then
      return true
    end
  end
  return false
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
  self:T(RAT.id.."Setting ROE to "..roe.." for group "..group:GetName())
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
  self:T(RAT.id.."Setting ROT to "..rot.." for group "..group:GetName())
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
    self:E(RAT.id.."ERROR: Unknown friendly coalition in _SetCoalitionTable(). Defaulting to NEUTRAL.")
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

---Determine the heading for an aircraft to be entered in the route template.
--@param #RAT self
--@param #number course The course between two points in degrees.
--@return #number heading Heading in rad.
function RAT:_Heading(course)
  local h
  if course<=180 then
    h=math.rad(course)
  else
    h=-math.rad(360-course)
  end
  return h 
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
  if self.Debug then
    local text=string.format("Random: value = %6.2f, fac = %4.2f, min = %6.2f, max = %6.2f, r = %6.2f", value, fac, min, max, r)
    self:T3(RAT.id..text)
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
-- @param #number index Spawn index of group.
function RAT:_PlaceMarkers(waypoints, index)
  for i=1,#waypoints do
    self:_SetMarker(self.waypointdescriptions[i], waypoints[i], index)
    if self.Debug then
      local text=string.format("Marker at waypoint #%d: %s for flight #%d", i, self.waypointdescriptions[i], index)
      self:T2(RAT.id..text)
    end
  end
end


--- Set a marker visible for all on the F10 map.
-- @param #RAT self
-- @param #string text Info text displayed at maker.
-- @param #table wp Position of marker coming in as waypoint, i.e. has x, y and alt components.
-- @param #number index Spawn index of group. 
function RAT:_SetMarker(text, wp, index)
  RAT.markerid=RAT.markerid+1
  self.markerids[#self.markerids+1]=RAT.markerid
  if self.Debug then
    local text2=string.format("%s: placing marker with ID %d and text %s", self.alias, RAT.markerid, text)
    self:T2(RAT.id..text2)
  end
  -- Convert to coordinate.
  local vec={x=wp.x, y=wp.alt, z=wp.y}
  local flight=self:GetGroupFromIndex(index):GetName()
  -- Place maker visible for all on the F10 map.
  local text1=string.format("%s:\n%s", flight, text)
  trigger.action.markToAll(RAT.markerid, text1, vec, false, "")
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
-- @param #string livery (Optional) Livery of the aircraft. All members of a flight will get the same livery.
-- @param Core.Point#COORDINATE spawnplace (Optional) Place where spawning should happen. If not present, first waypoint is taken.
function RAT:_ModifySpawnTemplate(waypoints, livery, spawnplace)
  self:F2({waypoints=waypoints, livery=livery, spawnplace=spawnplace})

  -- The 3D vector of the first waypoint, i.e. where we actually spawn the template group.
  local PointVec3 = {x=waypoints[1].x, y=waypoints[1].alt, z=waypoints[1].y}
  if spawnplace then
    PointVec3 = spawnplace:GetVec3()
    self:T({spawnplace=PointVec3})
  end
  
  -- Heading from first to seconds waypoints to align units in case of air start.
  local course  = self:_Course(waypoints[1], waypoints[2])
  local heading = self:_Heading(course)

  if self:_GetSpawnIndex(self.SpawnIndex+1) then
  
    local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
  
    if SpawnTemplate then
      self:T(SpawnTemplate)
      
      -- Spawn aircraft in uncontrolled state.
      if self.uncontrolled then
        -- This is used in the SPAWN:SpawnWithIndex() function. Some values are overwritten there!
        self.SpawnUnControlled=true
      end
        
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
        
        if self.Debug then
          local unitspawn=COORDINATE:New(TX,PointVec3.y,TY)
          unitspawn:MarkToAll(string.format("Spawnplace unit #%d", UnitID))
        end
        SpawnTemplate.units[UnitID].heading = heading
        SpawnTemplate.units[UnitID].psi = -heading
        
        -- Set livery (will be the same for all units of the group).
        if livery then
          SpawnTemplate.units[UnitID].livery_id = livery
        end
        
        -- Set type of aircraft.
        if self.actype then
          SpawnTemplate.units[UnitID]["type"] = self.actype
        end
        
        -- Set AI skill.
        SpawnTemplate.units[UnitID]["skill"] = self.skill
        
        -- Onboard number.
        if self.onboardnum then
          SpawnTemplate.units[UnitID]["onboard_num"] = string.format("%s%d%02d", self.onboardnum, (self.SpawnIndex-1)%10, (self.onboardnum0-1)+UnitID)
        end
        
        -- Modify coaltion and country of template.
        SpawnTemplate.CoalitionID=self.coalition
        if self.country then
          SpawnTemplate.CountryID=self.country
        end
        
        -- Parking spot.
        UnitTemplate.parking = nil
        UnitTemplate.parking_id = self.parking_id
        --self:T(RAT.id.."Parking ID "..tostring(self.parking_id))
        
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
      
      -- Debug output.
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
    local text
    text="Starting RAT ATC.\nSimultanious = "..RAT.ATC.Nclearance.."\n".."Delay        = "..RAT.ATC.delay
	  self:T(RAT.id..text)
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
  self:T(string.format("%sATC %s: Adding flight %s with destination %s.", RAT.id, dest, name, dest))
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
  self:T(RAT.id.."Flight ".. name.." registered at ATC for landing clearance.")
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
      local text=string.format("ATC %s: Flight %s is holding for %i:%02d. %s.", dest, name, hold/60, hold%60, busy)
      self:T(RAT.id..text)
      
    elseif hold==RAT.ATC.onfinal then
    
      -- Aircarft is on final approach for landing.
      local Tfinal=Tnow-RAT.ATC.flight[name].Tonfinal
      
      local text=string.format("ATC %s: Flight %s is on final. Waiting %i:%02d for landing event.", dest, name, Tfinal/60, Tfinal%60)
      self:T(RAT.id..text)
      
    elseif hold==RAT.ATC.unregistered then
    
      -- Aircraft has not arrived at holding point.
      --self:T(string.format("ATC %s: Flight %s is not registered yet (hold %d).", dest, name, hold))
      
    else
      self:E(RAT.id.."ERROR: Unknown holding time in RAT:_ATCStatus().")
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
        local text=string.format("ATC %s: Flight %s runway is busy. You are #%d of %d in landing queue. Your holding time is %i:%02d.", name, flight,qID, nqueue, RAT.ATC.flight[flight].holding/60, RAT.ATC.flight[flight].holding%60)
        self:T(RAT.id..text)
        
      else
      
        local text=string.format("ATC %s: Flight %s was cleared for landing. Your holding time was %i:%02d.", name, flight, RAT.ATC.flight[flight].holding/60, RAT.ATC.flight[flight].holding%60)
        self:T(RAT.id..text)
      
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
  BASE:T( RAT.id..text1)
  MESSAGE:New(text2, 10):ToAllIf(RAT.ATC.messages)
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
    BASE:T(RAT.id..text1)
    BASE:T(RAT.id..text2)
    BASE:T(RAT.id..text3)
    MESSAGE:New(text4, 10):ToAllIf(RAT.ATC.messages)
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- RATMANAGER class
-- @type RATMANAGER
-- @field #string ClassName Name of the Class.
-- @field #boolean Debug If true, be more verbose on output in DCS.log file.
-- @field #table rat Array holding RAT objects etc.
-- @field #string name Name (alias) of RAT object.
-- @field #table alive Number of currently alive groups.
-- @field #table min Minimum number of RAT groups alive.
-- @field #number nrat Number of RAT objects.
-- @field #number ntot Total number of active RAT groups.
-- @field #number Tcheck Time interval between checking of alive groups.
-- @field Core.Scheduler#SCHEDULER manager Scheduler managing the RAT objects.
-- @field #number managerid Managing scheduler id.
-- @extends Core.Base#BASE

---# RATMANAGER class, extends @{Base#BASE}
-- The RATMANAGER class manages spawning of multiple RAT objects in a very simple way. It is created by the  @{#RATMANAGER.New}() contructor. 
-- RAT objects with different "tasks" can be defined as usual. However, they **must not** be spawned via the @{#RAT.Spawn}() function.
-- 
-- Instead, these objects can be added to the manager via the @{#RATMANAGER.Add}(ratobject, min) function, where the first parameter "ratobject" is the @{#RAT} object, while the second parameter "min" defines the
-- minimum number of RAT aircraft of that object, which are alive at all time.
-- 
-- The @{#RATMANAGER} must be started by the @{#RATMANAGER.Start}(startime) function, where the optional argument "startime" specifies the delay time in seconds after which the manager is started and the spawning beginns.
-- If desired, the @{#RATMANAGER} can be stopped by the @{#RATMANAGER.Stop}(stoptime) function. The parameter "stoptime" specifies the time delay in seconds after which the manager stops.
-- When this happens, no new aircraft will be spawned and the population will eventually decrease to zero.
-- 
-- ## Example
-- In this example, three different @{#RAT} objects are created (but not spawned manually). The @{#RATMANAGER} takes care that at least five aircraft of each type are alive and that the total number of aircraft
-- spawned is 25. The @{#RATMANAGER} is started after 30 seconds and stopped after two hours.
-- 
--     local a10c=RAT:New("RAT_A10C", "A-10C managed")
--     a10c:SetDeparture({"Batumi"})
--     
--     local f15c=RAT:New("RAT_F15C", "F15C managed")
--     f15c:SetDeparture({"Sochi-Adler"})
--     f15c:DestinationZone()
--     f15c:SetDestination({"Zone C"})
--     
--     local av8b=RAT:New("RAT_AV8B", "AV8B managed")
--     av8b:SetDeparture({"Zone C"})
--     av8b:SetTakeoff("air")
--     av8b:DestinationZone()
--     av8b:SetDestination({"Zone A"})
--     
--     local manager=RATMANAGER:New(25)
--     manager:Add(a10c, 5)
--     manager:Add(f15c, 5)
--     manager:Add(av8b, 5)
--     manager:Start(30)
--     manager:Stop(7200)
--
-- @field #RATMANAGER
RATMANAGER={
  ClassName="RATMANAGER",
  Debug=false,
  rat={},
  name={},
  alive={},
  min={},
  nrat=0,
  ntot=nil,
  Tcheck=30,
  manager=nil,
  managerid=nil,
}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
RATMANAGER.id="RATMANAGER | "

--- Creates a new RATMANAGER object.
-- @param #RATMANAGER self
-- @param #number ntot Total number of RAT flights.
-- @return #RATMANAGER RATMANAGER object
function RATMANAGER:New(ntot)

  -- Inherit BASE.
  local self=BASE:Inherit(self, BASE:New()) -- #RATMANAGER
  
  -- Total number of RAT groups.
  self.ntot=ntot or 1
  
  -- Debug info
  self:E(RATMANAGER.id..string.format("Creating manager for %d groups.", ntot))
  
  return self
end


--- Adds a RAT object to the RAT manager. Parameter min specifies the limit how many RAT groups are at least alive.
-- @param #RATMANAGER self
-- @param #RAT ratobject RAT object to be managed.
-- @param #number min Minimum number of groups for this RAT object. Default is 1.
function RATMANAGER:Add(ratobject,min)

  --Automatic respawning is disabled.
  ratobject.norespawn=true
  ratobject.f10menu=false
  
  -- Increase RAT object counter.
  self.nrat=self.nrat+1
  
  self.rat[self.nrat]=ratobject
  self.alive[self.nrat]=0
  self.name[self.nrat]=ratobject.alias
  self.min[self.nrat]=min or 1
  
  -- Debug info.
  self:T(RATMANAGER.id..string.format("Adding ratobject %s with min flights = %d", self.name[self.nrat],self.min[self.nrat]))
  
  -- Call spawn to initialize RAT parameters.
  ratobject:Spawn(0)
end

--- Starts the RAT manager and spawns the initial random number RAT groups for each RAT object.
-- @param #RATMANAGER self
-- @param #number delay Time delay in seconds after which the RAT manager is started. Default is 5 seconds.
function RATMANAGER:Start(delay)

  -- Time delay.
  local delay=delay or 5

  -- Info text.
  local text=string.format(RATMANAGER.id.."RAT manager will be started in %d seconds.\n", delay)
  text=text..string.format("Managed groups:\n")
  for i=1,self.nrat do
    text=text..string.format("- %s with min groups %d\n", self.name[i], self.min[i])
  end
  text=text..string.format("Number of constantly alive groups %d", self.ntot)
  self:E(text)

  -- Start scheduler.
  SCHEDULER:New(nil, self._Start, {self}, delay)
end

--- Instantly starts the RAT manager and spawns the initial random number RAT groups for each RAT object.
-- @param #RATMANAGER self
function RATMANAGER:_Start()

  -- Ensure that ntot is at least sum of min RAT groups.
  local n=0
  for i=1,self.nrat do
    n=n+self.min[i]
  end
  self.ntot=math.max(self.ntot, n)

  -- Get randum number of new RAT groups.
  local N=self:_RollDice(self.nrat, self.ntot, self.min, self.alive)
  
  -- Loop over all RAT objects and spawn groups.
  for i=1,self.nrat do
    for j=1,N[i] do
      self.rat[i]:_SpawnWithRoute()
    end
    -- Start activation scheduler for uncontrolled aircraft.
    if self.rat[i].uncontrolled and self.rat[i].activate_uncontrolled then
      SCHEDULER:New(nil, self.rat[i]._ActivateUncontrolled, {self.rat[i]}, self.rat[i].activate_delay, self.rat[i].activate_delta, self.rat[i].activate_frand)
    end
  end
  
  -- Start manager scheduler.
  self.manager, self.managerid = SCHEDULER:New(nil, self._Manage, {self}, 5, self.Tcheck) --Core.Scheduler#SCHEDULER
  
  -- Info
  local text=string.format(RATMANAGER.id.."Starting RAT manager with scheduler ID %s.", self.managerid)
  self:E(text)
  
end

--- Stops the RAT manager.
-- @param #RATMANAGER self
-- @param #number delay Delay in seconds before the manager is stopped. Default is 1 second.
function RATMANAGER:Stop(delay)
  delay=delay or 1
  self:E(string.format(RATMANAGER.id.."Manager will be stopped in %d seconds.", delay))
  SCHEDULER:New(nil, self._Stop, {self}, delay)
end

--- Instantly stops the RAT manager by terminating its scheduler.
-- @param #RATMANAGER self
function RATMANAGER:_Stop()
  self:E(string.format(RATMANAGER.id.."Stopping manager with scheduler ID %s.", self.managerid))
  self.manager:Stop(self.managerid)
end

--- Sets the time interval between checks of alive RAT groups. Default is 30 seconds.
-- @param #RATMANAGER self
-- @param #number dt Time interval in seconds.
function RATMANAGER:SetTcheck(dt)
  self.Tcheck=dt or 30
end

--- Manager function. Calculating the number of current groups and respawning new groups if necessary.
-- @param #RATMANAGER self
function RATMANAGER:_Manage()

  -- Count total number of groups.
  local ntot=self:_Count()
  
  -- Debug info.
  if self.Debug then
    local text=string.format("Number of alive groups %d. New groups to be spawned %d.", ntot, self.ntot-ntot)
    self:T(RATMANAGER.id..text)
  end
  
  -- Get number of necessary spawns.
  local N=self:_RollDice(self.nrat, self.ntot, self.min, self.alive)
  
  -- Loop over all RAT objects and spawn new groups if necessary.
  for i=1,self.nrat do
    for j=1,N[i] do
      self.rat[i]:_SpawnWithRoute()
    end
  end
end

--- Counts the number of alive RAT objects.
-- @param #RATMANAGER self
function RATMANAGER:_Count()

  -- Init total counter.
  local ntotal=0
  
  -- Loop over all RAT objects.
  for i=1,self.nrat do
    local n=0
    
    local ratobject=self.rat[i] --#RAT
    
    -- Loop over the RAT groups of this object.
    for spawnindex,ratcraft in pairs(ratobject.ratcraft) do
      local group=ratcraft.group --Wrapper.Group#GROUP
      if group and group:IsAlive() then
        n=n+1
      end
    end
    
    -- Alive groups of this RAT object.
    self.alive[i]=n
    
    -- Grand total.
    ntotal=ntotal+n
    
    -- Debug output.
    if self.Debug then
      local text=string.format("Number of alive groups of %s = %d", self.name[i], n)
      self:T(RATMANAGER.id..text)
    end
  end
  
  -- Return grand total.
  return ntotal
end

--- Rolls the dice for the number of necessary spawns.
-- @param #RATMANAGER self
-- @param #number nrat Number of RAT objects.
-- @param #number ntot Total number of RAT flights.
-- @param #table min Minimum number of groups for each RAT object.
-- @param #table alive Number of alive groups of each RAT object.
function RATMANAGER:_RollDice(nrat,ntot,min,alive)
  
  -- Calculate sum.
  local function sum(A,index)
    local summe=0
    for _,i in ipairs(index) do
      summe=summe+A[i]
    end
    return summe
  end  
  
  -- Table of number of groups.
  local N={}
  local M={}
  local P={}
  for i=1,nrat do
    N[#N+1]=0
    M[#M+1]=math.max(alive[i], min[i])
    P[#P+1]=math.max(min[i]-alive[i],0)
  end
  
  -- Min/max group arrays.
  local mini={}
  local maxi={}
  
  -- Arrays.
  local rattab={}
  for i=1,nrat do
    table.insert(rattab,i)
  end
  local done={}
  
  -- Number of new groups to be added.
  local nnew=ntot
  for i=1,nrat do
    nnew=nnew-alive[i]
  end
  
  for i=1,nrat-1 do
    
    -- Random entry from .
    local r=math.random(#rattab)
    -- Get value
    local j=rattab[r]
    
    table.remove(rattab, r)
    table.insert(done,j)
    
    -- Sum up the number of already distributed groups.
    local sN=sum(N, done)
    -- Sum up the minimum number of yet to be distributed groups. 
    local sP=sum(P, rattab)
    
    -- Max number that can be distributed for this object.
    maxi[j]=nnew-sN-sP
    
    -- Min number that should be distributed for this object
    mini[j]=P[j]
    
    -- Random number of new groups for this RAT object.
    if maxi[j] >= mini[j] then
      N[j]=math.random(mini[j], maxi[j])
    else
      N[j]=0
    end
    
    -- Debug info
    self:T3(string.format("RATMANAGER: i=%d, alive=%d, min=%d, mini=%d, maxi=%d, add=%d, sumN=%d, sumP=%d", j, alive[j], min[j], mini[j], maxi[j], N[j],sN, sP))
    
  end
  
  -- Last RAT object, number of groups is determined from number of already distributed groups and nnew.
  local j=rattab[1]
  N[j]=nnew-sum(N, done)
  mini[j]=nnew-sum(N, done)
  maxi[j]=nnew-sum(N, done)
  table.remove(rattab, 1)
  table.insert(done,j)
  
  -- Debug info
  if self.Debug then
    local text=RATMANAGER.id.."\n"
    for i=1,nrat do
      text=text..string.format("%s: i=%d, alive=%d, min=%d, mini=%d, maxi=%d, add=%d\n", self.name[i], i, alive[i], min[i], mini[i], maxi[i], N[i])
    end
    text=text..string.format("Total # of groups to add = %d", sum(N, done))
    self:T2(text)
  end
  
  -- Return number of groups to be spawned.
  return N
end

