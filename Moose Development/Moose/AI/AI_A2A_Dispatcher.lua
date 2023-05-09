--- **AI** - Manages the process of an automatic A2A defense system based on an EWR network targets and coordinating CAP and GCI.
--
-- ===
--
-- Features:
--
--    * Setup quickly an A2A defense system for a coalition.
--    * Setup (CAP) Control Air Patrols at defined zones to enhance your A2A defenses.
--    * Setup (GCI) Ground Control Intercept at defined airbases to enhance your A2A defenses.
--    * Define and use an EWR (Early Warning Radar) network.
--    * Define squadrons at airbases.
--    * Enable airbases for A2A defenses.
--    * Add different plane types to different squadrons.
--    * Add multiple squadrons to different airbases.
--    * Define different ranges to engage upon intruders.
--    * Establish an automatic in air refuel process for CAP using refuel tankers.
--    * Setup default settings for all squadrons and A2A defenses.
--    * Setup specific settings for specific squadrons.
--    * Quickly setup an A2A defense system using @{#AI_A2A_GCICAP}.
--    * Setup a more advanced defense system using @{#AI_A2A_DISPATCHER}.
--
-- ===
--
-- ## Missions:
--
-- [AID-A2A - AI A2A Dispatching](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/AID%20-%20AI%20Dispatching/AID-A2A%20-%20AI%20A2A%20Dispatching)
--
-- ===
--
-- ## YouTube Channel:
--
-- [DCS WORLD - MOOSE - A2A GCICAP - Build an automatic A2A Defense System](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl0S4KMNUUJpaUs6zZHjLKNx)
--
-- ===
--
-- # QUICK START GUIDE
--
-- There are basically two classes available to model an A2A defense system.
--
-- AI\_A2A\_DISPATCHER is the main A2A defense class that models the A2A defense system.
-- AI\_A2A\_GCICAP derives or inherits from AI\_A2A\_DISPATCHER and is a more **noob** user friendly class, but is less flexible.
--
-- Before you start using the AI\_A2A\_DISPATCHER or AI\_A2A\_GCICAP ask yourself the following questions.
--
-- ## 0. Do I need AI\_A2A\_DISPATCHER or do I need AI\_A2A\_GCICAP?
--
-- AI\_A2A\_GCICAP, automates a lot of the below questions using the mission editor and requires minimal lua scripting.
-- But the AI\_A2A\_GCICAP provides less flexibility and a lot of options are defaulted.
-- With AI\_A2A\_DISPATCHER you can setup a much more **fine grained** A2A defense mechanism, but some more (easy) lua scripting is required.
--
-- ## 1. Which Coalition am I modeling an A2A defense system for? blue or red?
--
-- One AI\_A2A\_DISPATCHER object can create a defense system for **one coalition**, which is blue or red.
-- If you want to create a **mutual defense system**, for both blue and red, then you need to create **two** AI\_A2A\_DISPATCHER **objects**,
-- each governing their defense system.
--
--
-- ## 2. Which type of EWR will I setup? Grouping based per AREA, per TYPE or per UNIT? (Later others will follow).
--
-- The MOOSE framework leverages the @{Functional.Detection} classes to perform the EWR detection.
-- Several types of @{Functional.Detection} classes exist, and the most common characteristics of these classes is that they:
--
--    * Perform detections from multiple FACs as one co-operating entity.
--    * Communicate with a Head Quarters, which consolidates each detection.
--    * Groups detections based on a method (per area, per type or per unit).
--    * Communicates detections.
--
-- ## 3. Which EWR units will be used as part of the detection system? Only Ground or also Airborne?
--
-- Typically EWR networks are setup using 55G6 EWR, 1L13 EWR, Hawk sr and Patriot str ground based radar units.
-- These radars have different ranges and 55G6 EWR and 1L13 EWR radars are Eastern Bloc units (eg Russia, Ukraine, Georgia) while the Hawk and Patriot radars are Western (eg US).
-- Additionally, ANY other radar capable unit can be part of the EWR network! Also AWACS airborne units, planes, helicopters can help to detect targets, as long as they have radar.
-- The position of these units is very important as they need to provide enough coverage
-- to pick up enemy aircraft as they approach so that CAP and GCI flights can be tasked to intercept them.
--
-- ## 4. Is a border required?
--
-- Is this a cold war or a hot war situation? In case of a cold war situation, a border can be set that will only trigger defenses
-- if the border is crossed by enemy units.
--
-- ## 5. What maximum range needs to be checked to allow defenses to engage any attacker?
--
-- A good functioning defense will have a "maximum range" evaluated to the enemy when CAP will be engaged or GCI will be spawned.
--
-- ## 6. Which Airbases, Carrier Ships, FARPs will take part in the defense system for the Coalition?
--
-- Carefully plan which airbases will take part in the coalition. Color each airbase in the color of the coalition.
--
-- ## 7. Which Squadrons will I create and which name will I give each Squadron?
--
-- The defense system works with Squadrons. Each Squadron must be given a unique name, that forms the **key** to the defense system.
-- Several options and activities can be set per Squadron.
--
-- ## 8. Where will the Squadrons be located? On Airbases? On Carrier Ships? On FARPs?
--
-- Squadrons are placed as the "home base" on an airfield, carrier or farp.
-- Carefully plan where each Squadron will be located as part of the defense system.
--
-- ## 9. Which plane models will I assign for each Squadron? Do I need one plane model or more plane models per squadron?
--
-- Per Squadron, one or multiple plane models can be allocated as **Templates**.
-- These are late activated groups with one airplane or helicopter that start with a specific name, called the **template prefix**.
-- The A2A defense system will select from the given templates a random template to spawn a new plane (group).
--
-- ## 10. Which payloads, skills and skins will these plane models have?
--
-- Per Squadron, even if you have one plane model, you can still allocate multiple templates of one plane model,
-- each having different payloads, skills and skins.
-- The A2A defense system will select from the given templates a random template to spawn a new plane (group).
--
-- ## 11. For each Squadron, which will perform CAP?
--
-- Per Squadron, evaluate which Squadrons will perform CAP.
-- Not all Squadrons need to perform CAP.
--
-- ## 12. For each Squadron doing CAP, in which ZONE(s) will the CAP be performed?
--
-- Per CAP, evaluate **where** the CAP will be performed, in other words, define the **zone**.
-- Near the border or a bit further away?
--
-- ## 13. For each Squadron doing CAP, which zone types will I create?
--
-- Per CAP zone, evaluate whether you want:
--
--    * simple trigger zones
--    * polygon zones
--    * moving zones
--
-- Depending on the type of zone selected, a different @{Core.Zone} object needs to be created from a ZONE_ class.
--
-- ## 14. For each Squadron doing CAP, what are the time intervals and CAP amounts to be performed?
--
-- For each CAP:
--
--    * **How many** CAP you want to have airborne at the same time?
--    * **How frequent** you want the defense mechanism to check whether to start a new CAP?
--
-- ## 15. For each Squadron, which will perform GCI?
--
-- For each Squadron, evaluate which Squadrons will perform GCI?
-- Not all Squadrons need to perform GCI.
--
-- ## 16. For each Squadron, which takeoff method will I use?
--
-- For each Squadron, evaluate which takeoff method will be used:
--
--    * Straight from the air
--    * From the runway
--    * From a parking spot with running engines
--    * From a parking spot with cold engines
--
-- **The default takeoff method is straight in the air.**
--
-- ## 17. For each Squadron, which landing method will I use?
--
-- For each Squadron, evaluate which landing method will be used:
--
--    * Despawn near the airbase when returning
--    * Despawn after landing on the runway
--    * Despawn after engine shutdown after landing
--
-- **The default landing method is despawn when near the airbase when returning.**
--
-- ## 18. For each Squadron, which overhead will I use?
--
-- For each Squadron, depending on the airplane type (modern, old) and payload, which overhead is required to provide any defense?
-- In other words, if **X** attacker airplanes are detected, how many **Y** defense airplanes need to be spawned per squadron?
-- The **Y** is dependent on the type of airplane (era), payload, fuel levels, skills etc.
-- The overhead is a **factor** that will calculate dynamically how many **Y** defenses will be required based on **X** attackers detected.
--
-- **The default overhead is 1. A value greater than 1, like 1.5 will increase the overhead with 50%, a value smaller than 1, like 0.5 will decrease the overhead with 50%.**
--
-- ## 19. For each Squadron, which grouping will I use?
--
-- When multiple targets are detected, how will defense airplanes be grouped when multiple defense airplanes are spawned for multiple attackers?
-- Per one, two, three, four?
--
-- **The default grouping is 1. That means, that each spawned defender will act individually.**
--
-- ===
--
-- ### Authors: **FlightControl** rework of GCICAP + introduction of new concepts (squadrons).
-- ### Authors: **Stonehouse**, **SNAFU** in terms of the advice, documentation, and the original GCICAP script.
--
-- @module AI.AI_A2A_Dispatcher
-- @image AI_Air_To_Air_Dispatching.JPG

do -- AI_A2A_DISPATCHER

  --- AI_A2A_DISPATCHER class.
  -- @type AI_A2A_DISPATCHER
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER

  --- Create an automatic air defence system for a coalition.
  --
  -- ===
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia3.JPG)
  --
  -- It includes automatic spawning of Combat Air Patrol aircraft (CAP) and Ground Controlled Intercept aircraft (GCI) in response to enemy air movements that are detected by a ground based radar network.
  -- CAP flights will take off and proceed to designated CAP zones where they will remain on station until the ground radars direct them to intercept detected enemy aircraft or they run short of fuel and must return to base (RTB). When a CAP flight leaves their zone to perform an interception or return to base a new CAP flight will spawn to take their place.
  -- If all CAP flights are engaged or RTB then additional GCI interceptors will scramble to intercept unengaged enemy aircraft under ground radar control.
  -- With a little time and with a little work it provides the mission designer with a convincing and completely automatic air defence system.
  -- In short it is a plug in very flexible and configurable air defence module for DCS World.
  --
  -- Note that in order to create a two way A2A defense system, two AI\_A2A\_DISPATCHER defense system may need to be created, for each coalition one.
  -- This is a good implementation, because maybe in the future, more coalitions may become available in DCS world.
  --
  -- ===
  --
  -- # USAGE GUIDE
  --
  -- ## 1. AI\_A2A\_DISPATCHER constructor:
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_1.JPG)
  --
  --
  -- The @{#AI_A2A_DISPATCHER.New}() method creates a new AI\_A2A\_DISPATCHER instance.
  --
  -- ### 1.1. Define the **EWR network**:
  --
  -- As part of the AI\_A2A\_DISPATCHER :New() constructor, an EWR network must be given as the first parameter.
  -- An EWR network, or, Early Warning Radar network, is used to early detect potential airborne targets and to understand the position of patrolling targets of the enemy.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia5.JPG)
  --
  -- Typically EWR networks are setup using 55G6 EWR, 1L13 EWR, Hawk sr and Patriot str ground based radar units.
  -- These radars have different ranges and 55G6 EWR and 1L13 EWR radars are Eastern Bloc units (eg Russia, Ukraine, Georgia) while the Hawk and Patriot radars are Western (eg US).
  -- Additionally, ANY other radar capable unit can be part of the EWR network! Also AWACS airborne units, planes, helicopters can help to detect targets, as long as they have radar.
  -- The position of these units is very important as they need to provide enough coverage
  -- to pick up enemy aircraft as they approach so that CAP and GCI flights can be tasked to intercept them.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia7.JPG)
  --
  -- Additionally in a hot war situation where the border is no longer respected the placement of radars has a big effect on how fast the war escalates.
  -- For example if they are a long way forward and can detect enemy planes on the ground and taking off
  -- they will start to vector CAP and GCI flights to attack them straight away which will immediately draw a response from the other coalition.
  -- Having the radars further back will mean a slower escalation because fewer targets will be detected and
  -- therefore less CAP and GCI flights will spawn and this will tend to make just the border area active rather than a melee over the whole map.
  -- It all depends on what the desired effect is.
  --
  -- EWR networks are **dynamically constructed**, that is, they form part of the @{Functional.Detection#DETECTION_BASE} object that is given as the input parameter of the AI\_A2A\_DISPATCHER class.
  -- By defining in a **smart way the names or name prefixes of the groups** with EWR capable units, these groups will be **automatically added or deleted** from the EWR network,
  -- increasing or decreasing the radar coverage of the Early Warning System.
  --
  -- See the following example to setup an EWR network containing EWR stations and AWACS.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_2.JPG)
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_3.JPG)
  --
  --     -- Define a SET_GROUP object that builds a collection of groups that define the EWR network.
  --     -- Here we build the network with all the groups that have a name starting with DF CCCP AWACS and DF CCCP EWR.
  --     DetectionSetGroup = SET_GROUP:New()
  --     DetectionSetGroup:FilterPrefixes( { "DF CCCP AWACS", "DF CCCP EWR" } )
  --     DetectionSetGroup:FilterStart()
  --
  --     -- Setup the detection and group targets to a 30km range!
  --     Detection = DETECTION_AREAS:New( DetectionSetGroup, 30000 )
  --
  --     -- Setup the A2A dispatcher, and initialize it.
  --     A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  -- The above example creates a SET_GROUP instance, and stores this in the variable (object) **DetectionSetGroup**.
  -- **DetectionSetGroup** is then being configured to filter all active groups with a group name starting with **DF CCCP AWACS** or **DF CCCP EWR** to be included in the Set.
  -- **DetectionSetGroup** is then being ordered to start the dynamic filtering. Note that any destroy or new spawn of a group with the above names will be removed or added to the Set.
  --
  -- Then a new Detection object is created from the class DETECTION_AREAS. A grouping radius of 30000 is chosen, which is 30km.
  -- The **Detection** object is then passed to the @{#AI_A2A_DISPATCHER.New}() method to indicate the EWR network configuration and setup the A2A defense detection mechanism.
  --
  -- You could build a **mutual defense system** like this:
  --
  --     A2ADispatcher_Red = AI_A2A_DISPATCHER:New( EWR_Red )
  --     A2ADispatcher_Blue = AI_A2A_DISPATCHER:New( EWR_Blue )
  --
  -- ### 1.2. Define the detected **target grouping radius**:
  --
  -- The target grouping radius is a property of the Detection object, that was passed to the AI\_A2A\_DISPATCHER object, but can be changed.
  -- The grouping radius should not be too small, but also depends on the types of planes and the era of the simulation.
  -- Fast planes like in the 80s, need a larger radius than WWII planes.
  -- Typically I suggest to use 30000 for new generation planes and 10000 for older era aircraft.
  --
  -- Note that detected targets are constantly re-grouped, that is, when certain detected aircraft are moving further than the group radius, then these aircraft will become a separate
  -- group being detected. This may result in additional GCI being started by the dispatcher! So don't make this value too small!
  --
  -- ## 3. Set the **Engage Radius**:
  --
  -- Define the **Engage Radius** to **engage any target by airborne friendlies**,
  -- which are executing **cap** or **returning** from an intercept mission.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia10.JPG)
  --
  -- If there is a target area detected and reported,
  -- then any friendlies that are airborne near this target area,
  -- will be commanded to (re-)engage that target when available (if no other tasks were commanded).
  --
  -- For example, if **50000** or **50km** is given as a value, then any friendly that is airborne within **50km** from the detected target,
  -- will be considered to receive the command to engage that target area.
  --
  -- You need to evaluate the value of this parameter carefully:
  --
  --   * If too small, more intercept missions may be triggered upon detected target areas.
  --   * If too large, any airborne cap may not be able to reach the detected target area in time, because it is too far.
  --
  -- The **default** Engage Radius is defined as **100000** or **100km**.
  -- Use the method @{#AI_A2A_DISPATCHER.SetEngageRadius}() to set a specific Engage Radius.
  -- **The Engage Radius is defined for ALL squadrons which are operational.**
  --
  -- Demonstration Mission: [AID-019 - AI_A2A - Engage Range Test](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/release-2-2-pre/AID%20-%20AI%20Dispatching/AID-019%20-%20AI_A2A%20-%20Engage%20Range%20Test)
  --
  -- In this example an Engage Radius is set to various values.
  --
  --     -- Set 50km as the radius to engage any target by airborne friendlies.
  --     A2ADispatcher:SetEngageRadius( 50000 )
  --
  --     -- Set 100km as the radius to engage any target by airborne friendlies.
  --     A2ADispatcher:SetEngageRadius() -- 100000 is the default value.
  --
  --
  -- ## 4. Set the **Ground Controlled Intercept Radius** or **Gci radius**:
  --
  -- When targets are detected that are still really far off, you don't want the AI_A2A_DISPATCHER to launch intercepts just yet.
  -- You want it to wait until a certain Gci range is reached, which is the **distance of the closest airbase to target**
  -- being **smaller** than the **Ground Controlled Intercept radius** or **Gci radius**.
  --
  -- The **default** Gci radius is defined as **200000** or **200km**. Override the default Gci radius when the era of the warfare is early, or,
  -- when you don't want to let the AI_A2A_DISPATCHER react immediately when a certain border or area is not being crossed.
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetGciRadius}() to set a specific controlled ground intercept radius.
  -- **The Ground Controlled Intercept radius is defined for ALL squadrons which are operational.**
  --
  -- Demonstration Mission: [AID-013 - AI_A2A - Intercept Test](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/release-2-2-pre/AID%20-%20AI%20Dispatching/AID-013%20-%20AI_A2A%20-%20Intercept%20Test)
  --
  -- In these examples, the Gci Radius is set to various values:
  --
  --     -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --     A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --     -- Set 100km as the radius to ground control intercept detected targets from the nearest airbase.
  --     A2ADispatcher:SetGciRadius( 100000 )
  --
  --     -- Set 200km as the radius to ground control intercept.
  --     A2ADispatcher:SetGciRadius() -- 200000 is the default value.
  --
  -- ## 5. Set the **borders**:
  --
  -- According to the tactical and strategic design of the mission broadly decide the shape and extent of red and blue territories.
  -- They should be laid out such that a border area is created between the two coalitions.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia4.JPG)
  --
  -- **Define a border area to simulate a cold war scenario.**
  -- Use the method @{#AI_A2A_DISPATCHER.SetBorderZone}() to create a border zone for the dispatcher.
  --
  -- A **cold war** is one where CAP aircraft patrol their territory but will not attack enemy aircraft or launch GCI aircraft unless enemy aircraft enter their territory. In other words the EWR may detect an enemy aircraft but will only send aircraft to attack it if it crosses the border.
  -- A **hot war** is one where CAP aircraft will intercept any detected enemy aircraft and GCI aircraft will launch against detected enemy aircraft without regard for territory. In other words if the ground radar can detect the enemy aircraft then it will send CAP and GCI aircraft to attack it.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia9.JPG)
  --
  -- If it's a cold war then the **borders of red and blue territory** need to be defined using a @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE}.
  -- If a hot war is chosen then **no borders** actually need to be defined using the helicopter units other than
  -- it makes it easier sometimes for the mission maker to envisage where the red and blue territories roughly are.
  -- In a hot war the borders are effectively defined by the ground based radar coverage of a coalition.
  --
  -- Demonstration Mission: [AID-009 - AI_A2A - Border Test](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/release-2-2-pre/AID%20-%20AI%20Dispatching/AID-009 - AI_A2A - Border Test)
  --
  -- In this example a border is set for the CCCP A2A dispatcher:
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_4.JPG)
  --
  --     -- Setup the A2A dispatcher, and initialize it.
  --     A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --     -- Setup the border.
  --     -- Initialize the dispatcher, setting up a border zone. This is a polygon,
  --     -- which takes the waypoints of a late activated group with the name CCCP Border as the boundaries of the border area.
  --     -- Any enemy crossing this border will be engaged.
  --
  --     CCCPBorderZone = ZONE_POLYGON:New( "CCCP Border", GROUP:FindByName( "CCCP Border" ) )
  --     A2ADispatcher:SetBorderZone( CCCPBorderZone )
  --
  -- ## 6. Squadrons:
  --
  -- The AI\_A2A\_DISPATCHER works with **Squadrons**, that need to be defined using the different methods available.
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetSquadron}() to **setup a new squadron** active at an airfield,
  -- while defining which plane types are being used by the squadron and how many resources are available.
  --
  -- Squadrons:
  --
  --   * Have name (string) that is the identifier or key of the squadron.
  --   * Have specific plane types.
  --   * Are located at one airbase.
  --   * Optionally have a limited set of resources. The default is that squadrons have **unlimited resources**.
  --
  -- The name of the squadron given acts as the **squadron key** in the AI\_A2A\_DISPATCHER:Squadron...() methods.
  --
  -- Additionally, squadrons have specific configuration options to:
  --
  --   * Control how new aircraft are taking off from the airfield (in the air, cold, hot, at the runway).
  --   * Control how returning aircraft are landing at the airfield (in the air near the airbase, after landing, after engine shutdown).
  --   * Control the **grouping** of new aircraft spawned at the airfield. If there is more than one aircraft to be spawned, these may be grouped.
  --   * Control the **overhead** or defensive strength of the squadron. Depending on the types of planes and amount of resources, the mission designer can choose to increase or reduce the amount of planes spawned.
  --
  -- For performance and bug workaround reasons within DCS, squadrons have different methods to spawn new aircraft or land returning or damaged aircraft.
  --
  -- This example defines a couple of squadrons. Note the templates defined within the Mission Editor.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_5.JPG)
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_6.JPG)
  --
  --      -- Setup the squadrons.
  --      A2ADispatcher:SetSquadron( "Mineralnye", AIRBASE.Caucasus.Mineralnye_Vody, { "SQ CCCP SU-27" }, 20 )
  --      A2ADispatcher:SetSquadron( "Maykop", AIRBASE.Caucasus.Maykop_Khanskaya, { "SQ CCCP MIG-31" }, 20 )
  --      A2ADispatcher:SetSquadron( "Mozdok", AIRBASE.Caucasus.Mozdok, { "SQ CCCP MIG-31" }, 20 )
  --      A2ADispatcher:SetSquadron( "Sochi", AIRBASE.Caucasus.Sochi_Adler, { "SQ CCCP SU-27" }, 20 )
  --      A2ADispatcher:SetSquadron( "Novo", AIRBASE.Caucasus.Novorossiysk, { "SQ CCCP SU-27" }, 20 )
  --
  -- ### 6.1. Set squadron take-off methods
  --
  -- Use the various SetSquadronTakeoff... methods to control how squadrons are taking-off from the airfield:
  --
  --   * @{#AI_A2A_DISPATCHER.SetSquadronTakeoff}() is the generic configuration method to control takeoff from the air, hot, cold or from the runway. See the method for further details.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronTakeoffInAir}() will spawn new aircraft from the squadron directly in the air.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronTakeoffFromParkingCold}() will spawn new aircraft in without running engines at a parking spot at the airfield.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronTakeoffFromParkingHot}() will spawn new aircraft in with running engines at a parking spot at the airfield.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronTakeoffFromRunway}() will spawn new aircraft at the runway at the airfield.
  --
  -- **The default take-off method is to spawn new aircraft directly in the air.**
  --
  -- Use these methods to fine-tune for specific airfields that are known to create bottlenecks, or have reduced airbase efficiency.
  -- The more and the longer aircraft need to taxi at an airfield, the more risk there is that:
  --
  --   * aircraft will stop waiting for each other or for a landing aircraft before takeoff.
  --   * aircraft may get into a "dead-lock" situation, where two aircraft are blocking each other.
  --   * aircraft may collide at the airbase.
  --   * aircraft may be awaiting the landing of a plane currently in the air, but never lands ...
  --
  -- Currently within the DCS engine, the airfield traffic coordination is erroneous and contains a lot of bugs.
  -- If you experience while testing problems with aircraft take-off or landing, please use one of the above methods as a solution to workaround these issues!
  --
  -- This example sets the default takeoff method to be from the runway.
  -- And for a couple of squadrons overrides this default method.
  --
  --      -- Setup the Takeoff methods
  --
  --      -- The default takeoff
  --      A2ADispatcher:SetDefaultTakeOffFromRunway()
  --
  --      -- The individual takeoff per squadron
  --      A2ADispatcher:SetSquadronTakeoff( "Mineralnye", AI_A2A_DISPATCHER.Takeoff.Air )
  --      A2ADispatcher:SetSquadronTakeoffInAir( "Sochi" )
  --      A2ADispatcher:SetSquadronTakeoffFromRunway( "Mozdok" )
  --      A2ADispatcher:SetSquadronTakeoffFromParkingCold( "Maykop" )
  --      A2ADispatcher:SetSquadronTakeoffFromParkingHot( "Novo" )
  --
  --
  -- ### 6.1. Set Squadron takeoff altitude when spawning new aircraft in the air.
  --
  -- In the case of the @{#AI_A2A_DISPATCHER.SetSquadronTakeoffInAir}() there is also an other parameter that can be applied.
  -- That is modifying or setting the **altitude** from where planes spawn in the air.
  -- Use the method @{#AI_A2A_DISPATCHER.SetSquadronTakeoffInAirAltitude}() to set the altitude for a specific squadron.
  -- The default takeoff altitude can be modified or set using the method @{#AI_A2A_DISPATCHER.SetSquadronTakeoffInAirAltitude}().
  -- As part of the method @{#AI_A2A_DISPATCHER.SetSquadronTakeoffInAir}() a parameter can be specified to set the takeoff altitude.
  -- If this parameter is not specified, then the default altitude will be used for the squadron.
  --
  -- ### 6.2. Set squadron landing methods
  --
  -- In analogy with takeoff, the landing methods are to control how squadrons land at the airfield:
  --
  --   * @{#AI_A2A_DISPATCHER.SetSquadronLanding}() is the generic configuration method to control landing, namely despawn the aircraft near the airfield in the air, right after landing, or at engine shutdown.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronLandingNearAirbase}() will despawn the returning aircraft in the air when near the airfield.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronLandingAtRunway}() will despawn the returning aircraft directly after landing at the runway.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronLandingAtEngineShutdown}() will despawn the returning aircraft when the aircraft has returned to its parking spot and has turned off its engines.
  --
  -- You can use these methods to minimize the airbase coordination overhead and to increase the airbase efficiency.
  -- When there are lots of aircraft returning for landing, at the same airbase, the takeoff process will be halted, which can cause a complete failure of the
  -- A2A defense system, as no new CAP or GCI planes can takeoff.
  -- Note that the method @{#AI_A2A_DISPATCHER.SetSquadronLandingNearAirbase}() will only work for returning aircraft, not for damaged or out of fuel aircraft.
  -- Damaged or out-of-fuel aircraft are returning to the nearest friendly airbase and will land, and are out of control from ground control.
  --
  -- This example defines the default landing method to be at the runway.
  -- And for a couple of squadrons overrides this default method.
  --
  --      -- Setup the Landing methods
  --
  --      -- The default landing method
  --      A2ADispatcher:SetDefaultLandingAtRunway()
  --
  --      -- The individual landing per squadron
  --      A2ADispatcher:SetSquadronLandingAtRunway( "Mineralnye" )
  --      A2ADispatcher:SetSquadronLandingNearAirbase( "Sochi" )
  --      A2ADispatcher:SetSquadronLandingAtEngineShutdown( "Mozdok" )
  --      A2ADispatcher:SetSquadronLandingNearAirbase( "Maykop" )
  --      A2ADispatcher:SetSquadronLanding( "Novo", AI_A2A_DISPATCHER.Landing.AtRunway )
  --
  --
  -- ### 6.3. Set squadron grouping
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetSquadronGrouping}() to set the grouping of CAP or GCI flights that will take-off when spawned.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia12.JPG)
  --
  -- In the case of GCI, the @{#AI_A2A_DISPATCHER.SetSquadronGrouping}() method has additional behavior. When there aren't enough CAP flights airborne, a GCI will be initiated for the remaining
  -- targets to be engaged. Depending on the grouping parameter, the spawned flights for GCI are grouped into this setting.
  -- For example with a group setting of 2, if 3 targets are detected and cannot be engaged by CAP or any airborne flight,
  -- a GCI needs to be started, the GCI flights will be grouped as follows: Group 1 of 2 flights and Group 2 of one flight!
  --
  -- Even more ... If one target has been detected, and the overhead is 1.5, grouping is 1, then two groups of planes will be spawned, with one unit each!
  --
  -- The **grouping value is set for a Squadron**, and can be **dynamically adjusted** during mission execution, so to adjust the defense flights grouping when the tactical situation changes.
  --
  -- ### 6.4. Overhead and Balance the effectiveness of the air defenses in case of GCI.
  --
  -- The effectiveness can be set with the **overhead parameter**. This is a number that is used to calculate the amount of Units that dispatching command will allocate to GCI in surplus of detected amount of units.
  -- The **default value** of the overhead parameter is 1.0, which means **equal balance**.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia11.JPG)
  --
  -- However, depending on the (type of) aircraft (strength and payload) in the squadron and the amount of resources available, this parameter can be changed.
  --
  -- The @{#AI_A2A_DISPATCHER.SetSquadronOverhead}() method can be used to tweak the defense strength,
  -- taking into account the plane types of the squadron.
  --
  -- For example, a MIG-31 with full long-distance A2A missiles payload, may still be less effective than a F-15C with short missiles...
  -- So in this case, one may want to use the @{#AI_A2A_DISPATCHER.SetOverhead}() method to allocate more defending planes as the amount of detected attacking planes.
  -- The overhead must be given as a decimal value with 1 as the neutral value, which means that overhead values:
  --
  --   * Higher than 1.0, for example 1.5, will increase the defense unit amounts. For 4 planes detected, 6 planes will be spawned.
  --   * Lower than 1, for example 0.75, will decrease the defense unit amounts. For 4 planes detected, only 3 planes will be spawned.
  --
  -- The amount of defending units is calculated by multiplying the amount of detected attacking planes as part of the detected group
  -- multiplied by the Overhead and rounded up to the smallest integer.
  --
  -- For example ... If one target has been detected, and the overhead is 1.5, grouping is 1, then two groups of planes will be spawned, with one unit each!
  --
  -- The **overhead value is set for a Squadron**, and can be **dynamically adjusted** during mission execution, so to adjust the defense overhead when the tactical situation changes.
  --
  -- ## 6.5. Squadron fuel threshold.
  --
  -- When an airplane gets **out of fuel** to a certain %, which is by default **15% (0.15)**, there are two possible actions that can be taken:
  --  - The defender will go RTB, and will be replaced with a new defender if possible.
  --  - The defender will refuel at a tanker, if a tanker has been specified for the squadron.
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetSquadronFuelThreshold}() to set the **squadron fuel threshold** of spawned airplanes for all squadrons.
  --
  -- ## 7. Setup a squadron for CAP
  --
  -- ### 7.1. Set the CAP zones
  --
  -- CAP zones are patrol areas where Combat Air Patrol (CAP) flights loiter until they either return to base due to low fuel or are assigned an interception task by ground control.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia6.JPG)
  --
  --   * As the CAP flights wander around within the zone waiting to be tasked, these zones need to be large enough that the aircraft are not constantly turning
  --   but do not have to be big and numerous enough to completely cover a border.
  --
  --   * CAP zones can be of any type, and are derived from the @{Core.Zone#ZONE_BASE} class. Zones can be @{Core.Zone#ZONE}, @{Core.Zone#ZONE_POLYGON}, @{Core.Zone#ZONE_UNIT}, @{Core.Zone#ZONE_GROUP}, etc.
  --   This allows to setup **static, moving and/or complex zones** wherein aircraft will perform the CAP.
  --
  --   * Typically 20000-50000 metres width is used and they are spaced so that aircraft in the zone waiting for tasks don't have to far to travel to protect their coalitions important targets.
  --   These targets are chosen as part of the mission design and might be an important airfield or town etc.
  --   Zone size is also determined somewhat by territory size, plane types
  --   (eg WW2 aircraft might mean smaller zones or more zones because they are slower and take longer to intercept enemy aircraft).
  --
  --   * In a **cold war** it is important to make sure a CAP zone doesn't intrude into enemy territory as otherwise CAP flights will likely cross borders
  --   and spark a full scale conflict which will escalate rapidly.
  --
  --   * CAP flights do not need to be in the CAP zone before they are "on station" and ready for tasking.
  --
  --   * Typically if a CAP flight is tasked and therefore leaves their zone empty while they go off and intercept their target another CAP flight will spawn to take their place.
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia7.JPG)
  --
  -- The following example illustrates how CAP zones are coded:
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_8.JPG)
  --
  --      -- CAP Squadron execution.
  --      CAPZoneEast = ZONE_POLYGON:New( "CAP Zone East", GROUP:FindByName( "CAP Zone East" ) )
  --      A2ADispatcher:SetSquadronCap( "Mineralnye", CAPZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --      A2ADispatcher:SetSquadronCapInterval( "Mineralnye", 2, 30, 60, 1 )
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_7.JPG)
  --
  --      CAPZoneWest = ZONE_POLYGON:New( "CAP Zone West", GROUP:FindByName( "CAP Zone West" ) )
  --      A2ADispatcher:SetSquadronCap( "Sochi", CAPZoneWest, 4000, 8000, 600, 800, 800, 1200, "BARO" )
  --      A2ADispatcher:SetSquadronCapInterval( "Sochi", 2, 30, 120, 1 )
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_9.JPG)
  --
  --      CAPZoneMiddle = ZONE:New( "CAP Zone Middle")
  --      A2ADispatcher:SetSquadronCap( "Maykop", CAPZoneMiddle, 4000, 8000, 600, 800, 800, 1200, "RADIO" )
  --      A2ADispatcher:SetSquadronCapInterval( "Sochi", 2, 30, 120, 1 )
  --
  -- Note the different @{Core.Zone} MOOSE classes being used to create zones of different types. Please click the @{Core.Zone} link for more information about the different zone types.
  -- Zones can be circles, can be setup in the mission editor using trigger zones, but can also be setup in the mission editor as polygons and in this case GROUP objects are being used!
  --
  -- ## 7.2. Set the squadron to execute CAP:
  --
  -- The method @{#AI_A2A_DISPATCHER.SetSquadronCap}() defines a CAP execution for a squadron.
  --
  -- Setting-up a CAP zone also requires specific parameters:
  --
  --   * The minimum and maximum altitude
  --   * The minimum speed and maximum patrol speed
  --   * The minimum and maximum engage speed
  --   * The type of altitude measurement
  --
  -- These define how the squadron will perform the CAP while patrolling. Different terrain types requires different types of CAP.
  --
  -- The @{#AI_A2A_DISPATCHER.SetSquadronCapInterval}() method specifies **how much** and **when** CAP flights will takeoff.
  --
  -- It is recommended not to overload the air defense with CAP flights, as these will decrease the performance of the overall system.
  --
  -- For example, the following setup will create a CAP for squadron "Sochi":
  --
  --      A2ADispatcher:SetSquadronCap( "Sochi", CAPZoneWest, 4000, 8000, 600, 800, 800, 1200, "BARO" )
  --      A2ADispatcher:SetSquadronCapInterval( "Sochi", 2, 30, 120, 1 )
  --
  -- ## 7.3. Squadron tanker to refuel when executing CAP and defender is out of fuel.
  --
  -- Instead of sending CAP to RTB when out of fuel, you can let CAP refuel in mid air using a tanker.
  -- This greatly increases the efficiency of your CAP operations.
  --
  -- In the mission editor, setup a group with task Refuelling. A tanker unit of the correct coalition will be automatically selected.
  -- Then, use the method @{#AI_A2A_DISPATCHER.SetDefaultTanker}() to set the default tanker for the refuelling.
  -- You can also specify a specific tanker for refuelling for a squadron  by using the method @{#AI_A2A_DISPATCHER.SetSquadronTanker}().
  --
  -- When the tanker specified is alive and in the air, the tanker will be used for refuelling.
  --
  -- For example, the following setup will create a CAP for squadron "Gelend" with a refuel task for the squadron:
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_10.JPG)
  --
  --      -- Define the CAP
  --      A2ADispatcher:SetSquadron( "Gelend", AIRBASE.Caucasus.Gelendzhik, { "SQ CCCP SU-30" }, 20 )
  --      A2ADispatcher:SetSquadronCap( "Gelend", ZONE:New( "PatrolZoneGelend" ), 4000, 8000, 600, 800, 1000, 1300 )
  --      A2ADispatcher:SetSquadronCapInterval( "Gelend", 2, 30, 600, 1 )
  --      A2ADispatcher:SetSquadronGci( "Gelend", 900, 1200 )
  --
  --      -- Setup the Refuelling for squadron "Gelend", at tanker (group) "TankerGelend" when the fuel in the tank of the CAP defenders is less than 80%.
  --      A2ADispatcher:SetSquadronFuelThreshold( "Gelend", 0.8 )
  --      A2ADispatcher:SetSquadronTanker( "Gelend", "TankerGelend" )
  --
  -- ## 7.4 Set up race track pattern
  --
  -- By default, flights patrol randomly within the CAP zone. It is also possible to let them fly a race track pattern using the
  -- @{#AI_A2A_DISPATCHER.SetDefaultCapRacetrack}(*LeglengthMin*, *LeglengthMax*, *HeadingMin*, *HeadingMax*, *DurationMin*, *DurationMax*) or
  -- @{#AI_A2A_DISPATCHER.SetSquadronCapRacetrack}(*SquadronName*, *LeglengthMin*, *LeglengthMax*, *HeadingMin*, *HeadingMax*, *DurationMin*, *DurationMax*) functions.
  -- The first function enables this for all squadrons, the latter only for specific squadrons. For example,
  --
  --      -- Enable race track pattern for CAP squadron "Mineralnye".
  --      A2ADispatcher:SetSquadronCapRacetrack("Mineralnye", 10000, 20000, 90, 180, 10*60, 20*60)
  --
  -- In this case the squadron "Mineralnye" will a race track pattern at a random point in the CAP zone. The leg length will be randomly selected between 10,000 and 20,000 meters. The heading
  -- of the race track will randomly selected between 90 (West to East) and 180 (North to South) degrees.
  -- After a random duration between 10 and 20 minutes, the flight will get a new random orbit location.
  --
  -- Note that all parameters except the squadron name are optional. If not specified, default values are taken. Speed and altitude are taken from the CAP command used earlier on, e.g.
  --
  --      A2ADispatcher:SetSquadronCap( "Mineralnye", CAPZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --
  -- Also note that the center of the race track pattern is chosen randomly within the patrol zone and can be close the the boarder of the zone. Hence, it cannot be guaranteed that the
  -- whole pattern lies within the patrol zone.
  --
  -- ## 8. Setup a squadron for GCI:
  --
  -- The method @{#AI_A2A_DISPATCHER.SetSquadronGci}() defines a GCI execution for a squadron.
  --
  -- Setting-up a GCI readiness also requires specific parameters:
  --
  --   * The minimum speed and maximum patrol speed
  --
  -- Essentially this controls how many flights of GCI aircraft can be active at any time.
  -- Note allowing large numbers of active GCI flights can adversely impact mission performance on low or medium specification hosts/servers.
  -- GCI needs to be setup at strategic airbases. Too far will mean that the aircraft need to fly a long way to reach the intruders,
  -- too short will mean that the intruders may have already passed the ideal interception point!
  --
  -- For example, the following setup will create a GCI for squadron "Sochi":
  --
  --      A2ADispatcher:SetSquadronGci( "Mozdok", 900, 1200 )
  --
  -- ## 9. Other configuration options
  --
  -- ### 9.1. Set a tactical display panel:
  --
  -- Every 30 seconds, a tactical display panel can be shown that illustrates what the status is of the different groups controlled by AI\_A2A\_DISPATCHER.
  -- Use the method @{#AI_A2A_DISPATCHER.SetTacticalDisplay}() to switch on the tactical display panel. The default will not show this panel.
  -- Note that there may be some performance impact if this panel is shown.
  --
  -- ## 10. Defaults settings.
  --
  -- This provides a good overview of the different parameters that are setup or hardcoded by default.
  -- For some default settings, a method is available that allows you to tweak the defaults.
  --
  -- ## 10.1. Default takeoff method.
  --
  -- The default **takeoff method** is set to **in the air**, which means that new spawned airplanes will be spawned directly in the air above the airbase by default.
  --
  -- **The default takeoff method can be set for ALL squadrons that don't have an individual takeoff method configured.**
  --
  --   * @{#AI_A2A_DISPATCHER.SetDefaultTakeoff}() is the generic configuration method to control takeoff by default from the air, hot, cold or from the runway. See the method for further details.
  --   * @{#AI_A2A_DISPATCHER.SetDefaultTakeoffInAir}() will spawn by default new aircraft from the squadron directly in the air.
  --   * @{#AI_A2A_DISPATCHER.SetDefaultTakeoffFromParkingCold}() will spawn by default new aircraft in without running engines at a parking spot at the airfield.
  --   * @{#AI_A2A_DISPATCHER.SetDefaultTakeoffFromParkingHot}() will spawn by default new aircraft in with running engines at a parking spot at the airfield.
  --   * @{#AI_A2A_DISPATCHER.SetDefaultTakeoffFromRunway}() will spawn by default new aircraft at the runway at the airfield.
  --
  -- ## 10.2. Default landing method.
  --
  -- The default **landing method** is set to **near the airbase**, which means that returning airplanes will be despawned directly in the air by default.
  --
  -- The default landing method can be set for ALL squadrons that don't have an individual landing method configured.
  --
  --   * @{#AI_A2A_DISPATCHER.SetDefaultLanding}() is the generic configuration method to control by default landing, namely despawn the aircraft near the airfield in the air, right after landing, or at engine shutdown.
  --   * @{#AI_A2A_DISPATCHER.SetDefaultLandingNearAirbase}() will despawn by default the returning aircraft in the air when near the airfield.
  --   * @{#AI_A2A_DISPATCHER.SetDefaultLandingAtRunway}() will despawn by default the returning aircraft directly after landing at the runway.
  --   * @{#AI_A2A_DISPATCHER.SetDefaultLandingAtEngineShutdown}() will despawn by default the returning aircraft when the aircraft has returned to its parking spot and has turned off its engines.
  --
  -- ## 10.3. Default overhead.
  --
  -- The default **overhead** is set to **1**. That essentially means that there isn't any overhead set by default.
  --
  -- The default overhead value can be set for ALL squadrons that don't have an individual overhead value configured.
  --
  -- Use the @{#AI_A2A_DISPATCHER.SetDefaultOverhead}() method can be used to set the default overhead or defense strength for ALL squadrons.
  --
  -- ## 10.4. Default grouping.
  --
  -- The default **grouping** is set to **one airplane**. That essentially means that there won't be any grouping applied by default.
  --
  -- The default grouping value can be set for ALL squadrons that don't have an individual grouping value configured.
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetDefaultGrouping}() to set the **default grouping** of spawned airplanes for all squadrons.
  --
  -- ## 10.5. Default RTB fuel threshold.
  --
  -- When an airplane gets **out of fuel** to a certain %, which is **15% (0.15)**, it will go RTB, and will be replaced with a new airplane when applicable.
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetDefaultFuelThreshold}() to set the **default fuel threshold** of spawned airplanes for all squadrons.
  --
  -- ## 10.6. Default RTB damage threshold.
  --
  -- When an airplane is **damaged** to a certain %, which is **40% (0.40)**, it will go RTB, and will be replaced with a new airplane when applicable.
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetDefaultDamageThreshold}() to set the **default damage threshold** of spawned airplanes for all squadrons.
  --
  -- ## 10.7. Default settings for CAP.
  --
  -- ### 10.7.1. Default CAP Time Interval.
  --
  -- CAP is time driven, and will evaluate in random time intervals if a new CAP needs to be spawned.
  -- The **default CAP time interval** is between **180** and **600** seconds.
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetDefaultCapTimeInterval}() to set the **default CAP time interval** of spawned airplanes for all squadrons.
  -- Note that you can still change the CAP limit and CAP time intervals for each CAP individually using the @{#AI_A2A_DISPATCHER.SetSquadronCapTimeInterval}() method.
  --
  -- ### 10.7.2. Default CAP limit.
  --
  -- Multiple CAP can be airborne at the same time for one squadron, which is controlled by the **CAP limit**.
  -- The **default CAP limit** is 1 CAP per squadron to be airborne at the same time.
  -- Note that the default CAP limit is used when a Squadron CAP is defined, and cannot be changed afterwards.
  -- So, ensure that you set the default CAP limit **before** you spawn the Squadron CAP.
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetDefaultCapTimeInterval}() to set the **default CAP time interval** of spawned airplanes for all squadrons.
  -- Note that you can still change the CAP limit and CAP time intervals for each CAP individually using the @{#AI_A2A_DISPATCHER.SetSquadronCapTimeInterval}() method.
  --
  -- ## 10.7.3. Default tanker for refuelling when executing CAP.
  --
  -- Instead of sending CAP to RTB when out of fuel, you can let CAP refuel in mid air using a tanker.
  -- This greatly increases the efficiency of your CAP operations.
  --
  -- In the mission editor, setup a group with task Refuelling. A tanker unit of the correct coalition will be automatically selected.
  -- Then, use the method @{#AI_A2A_DISPATCHER.SetDefaultTanker}() to set the tanker for the dispatcher.
  -- Use the method @{#AI_A2A_DISPATCHER.SetDefaultFuelThreshold}() to set the % left in the defender airplane tanks when a refuel action is needed.
  --
  -- When the tanker specified is alive and in the air, the tanker will be used for refuelling.
  --
  -- For example, the following setup will set the default refuel tanker to "Tanker":
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_DISPATCHER-ME_11.JPG)
  --
  --      -- Define the CAP
  --      A2ADispatcher:SetSquadron( "Sochi", AIRBASE.Caucasus.Sochi_Adler, { "SQ CCCP SU-34" }, 20 )
  --      A2ADispatcher:SetSquadronCap( "Sochi", ZONE:New( "PatrolZone" ), 4000, 8000, 600, 800, 1000, 1300 )
  --      A2ADispatcher:SetSquadronCapInterval("Sochi", 2, 30, 600, 1 )
  --      A2ADispatcher:SetSquadronGci( "Sochi", 900, 1200 )
  --
  --      -- Set the default tanker for refuelling to "Tanker", when the default fuel threshold has reached 90% fuel left.
  --      A2ADispatcher:SetDefaultFuelThreshold( 0.9 )
  --      A2ADispatcher:SetDefaultTanker( "Tanker" )
  --
  -- ## 10.8. Default settings for GCI.
  --
  -- ## 10.8.1. Optimal intercept point calculation.
  --
  -- When intruders are detected, the intrusion path of the attackers can be monitored by the EWR.
  -- Although defender planes might be on standby at the airbase, it can still take some time to get the defenses up in the air if there aren't any defenses airborne.
  -- This time can easily take 2 to 3 minutes, and even then the defenders still need to fly towards the target, which takes also time.
  --
  -- Therefore, an optimal **intercept point** is calculated which takes a couple of parameters:
  --
  --   * The average bearing of the intruders for an amount of seconds.
  --   * The average speed of the intruders for an amount of seconds.
  --   * An assumed time it takes to get planes operational at the airbase.
  --
  -- The **intercept point** will determine:
  --
  --   * If there are any friendlies close to engage the target. These can be defenders performing CAP or defenders in RTB.
  --   * The optimal airbase from where defenders will takeoff for GCI.
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetIntercept}() to modify the assumed intercept delay time to calculate a valid interception.
  --
  -- ## 10.8.2. Default Disengage Radius.
  --
  -- The radius to **disengage any target** when the **distance** of the defender to the **home base** is larger than the specified meters.
  -- The default Disengage Radius is **300km** (300000 meters). Note that the Disengage Radius is applicable to ALL squadrons!
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetDisengageRadius}() to modify the default Disengage Radius to another distance setting.
  --
  -- ## 11. Airbase capture:
  --
  -- Different squadrons can be located at one airbase.
  -- If the airbase gets captured, that is, when there is an enemy unit near the airbase, and there aren't anymore friendlies at the airbase, the airbase will change coalition ownership.
  -- As a result, the GCI and CAP will stop!
  -- However, the squadron will still stay alive. Any airplane that is airborne will continue its operations until all airborne airplanes
  -- of the squadron will be destroyed. This to keep consistency of air operations not to confuse the players.
  --
  -- ## 12. Q & A:
  --
  -- ### 12.1. Which countries will be selected for each coalition?
  --
  -- Which countries are assigned to a coalition influences which units are available to the coalition.
  -- For example because the mission calls for a EWR radar on the blue side the Ukraine might be chosen as a blue country
  -- so that the 55G6 EWR radar unit is available to blue.
  -- Some countries assign different tasking to aircraft, for example Germany assigns the CAP task to F-4E Phantoms but the USA does not.
  -- Therefore if F4s are wanted as a coalition's CAP or GCI aircraft Germany will need to be assigned to that coalition.
  --
  -- ### 12.2. Country, type, load out, skill and skins for CAP and GCI aircraft?
  --
  --   * Note these can be from any countries within the coalition but must be an aircraft with one of the main tasks being "CAP".
  --   * Obviously skins which are selected must be available to all players that join the mission otherwise they will see a default skin.
  --   * Load outs should be appropriate to a CAP mission eg perhaps drop tanks for CAP flights and extra missiles for GCI flights.
  --   * These decisions will eventually lead to template aircraft units being placed as late activation units that the script will use as templates for spawning CAP and GCI flights. Up to 4 different aircraft configurations can be chosen for each coalition. The spawned aircraft will inherit the characteristics of the template aircraft.
  --   * The selected aircraft type must be able to perform the CAP tasking for the chosen country.
  --
  --
  -- @field #AI_A2A_DISPATCHER
  AI_A2A_DISPATCHER = {
    ClassName = "AI_A2A_DISPATCHER",
    Detection = nil,
  }

  --- Squadron data structure.
  -- @type AI_A2A_DISPATCHER.Squadron
  -- @field #string Name Name of the squadron.
  -- @field #number ResourceCount Number of resources.
  -- @field #string AirbaseName Name of the home airbase.
  -- @field Wrapper.Airbase#AIRBASE Airbase The home airbase of the squadron.
  -- @field #boolean Captured If true, airbase of the squadron was captured.
  -- @field #table Resources Flight group resources Resources[TemplateID][GroupName] = SpawnGroup.
  -- @field #boolean Uncontrolled If true, flight groups are spawned uncontrolled and later activated.
  -- @field #table Gci GCI.
  -- @field #number Overhead Squadron overhead.
  -- @field #number Grouping Squadron flight group size.
  -- @field #number Takeoff Takeoff type.
  -- @field #number TakeoffAltitude Altitude in meters for spawn in air.
  -- @field #number Landing Landing type.
  -- @field #number FuelThreshold Fuel threshold [0,1] for RTB.
  -- @field #string TankerName Name of the refuelling tanker.
  -- @field #table Table of template group names of the squadron.
  -- @field #table Spawn Table of spawns Core.Spawn#SPAWN.
  -- @field #table TemplatePrefixes
  -- @field #boolean Racetrack If true, CAP flights will perform a racetrack pattern rather than randomly patrolling the zone.
  -- @field #number RacetrackLengthMin Min Length of race track in meters. Default 10,000 m.
  -- @field #number RacetrackLengthMax Max Length of race track in meters. Default 15,000 m.
  -- @field #number RacetrackHeadingMin Min heading of race track in degrees. Default 0 deg, i.e. from South to North.
  -- @field #number RacetrackHeadingMax Max heading of race track in degrees. Default 180 deg, i.e. from North to South.
  -- @field #number RacetrackDurationMin Min duration in seconds before the CAP flight changes its orbit position. Default never.
  -- @field #number RacetrackDurationMax Max duration in seconds before the CAP flight changes its orbit position. Default never.

  --- Enumerator for spawns at airbases
  -- @type AI_A2A_DISPATCHER.Takeoff
  -- @extends Wrapper.Group#GROUP.Takeoff
  
  ---
  -- @field #AI_A2A_DISPATCHER.Takeoff Takeoff
  AI_A2A_DISPATCHER.Takeoff = GROUP.Takeoff

  --- Defines Landing type/location.
  -- @field Landing
  AI_A2A_DISPATCHER.Landing = {
    NearAirbase = 1,
    AtRunway = 2,
    AtEngineShutdown = 3,
  }

  --- AI_A2A_DISPATCHER constructor.
  -- This is defining the A2A DISPATCHER for one coalition.
  -- The Dispatcher works with a @{Functional.Detection#DETECTION_BASE} object that is taking of the detection of targets using the EWR units.
  -- The Detection object is polymorphic, depending on the type of detection object chosen, the detection will work differently.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The DETECTION object that will detects targets using the the Early Warning Radar network.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --     -- Setup the Detection, using DETECTION_AREAS.
  --     -- First define the SET of GROUPs that are defining the EWR network.
  --     -- Here with prefixes DF CCCP AWACS, DF CCCP EWR.
  --     DetectionSetGroup = SET_GROUP:New()
  --     DetectionSetGroup:FilterPrefixes( { "DF CCCP AWACS", "DF CCCP EWR" } )
  --     DetectionSetGroup:FilterStart()
  --
  --     -- Define the DETECTION_AREAS, using the DetectionSetGroup, with a 30km grouping radius.
  --     Detection = DETECTION_AREAS:New( DetectionSetGroup, 30000 )
  --
  --     -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --     A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  function AI_A2A_DISPATCHER:New( Detection )

    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( nil, Detection ) ) -- #AI_A2A_DISPATCHER

    self.Detection = Detection -- Functional.Detection#DETECTION_AREAS

    -- This table models the DefenderSquadron templates.
    self.DefenderSquadrons = {} -- The Defender Squadrons.
    self.DefenderSpawns = {}
    self.DefenderTasks = {} -- The Defenders Tasks.
    self.DefenderDefault = {} -- The Defender Default Settings over all Squadrons.

    self.SetSendPlayerMessages = false --#boolean Flash messages to player
    
    -- TODO: Check detection through radar.
    self.Detection:FilterCategories( { Unit.Category.AIRPLANE, Unit.Category.HELICOPTER } )
    -- self.Detection:InitDetectRadar( true )
    self.Detection:SetRefreshTimeInterval( 30 )

    self:SetEngageRadius()
    self:SetGciRadius()
    self:SetIntercept( 300 ) -- A default intercept delay time of 300 seconds.
    self:SetDisengageRadius( 300000 ) -- The default Disengage Radius is 300 km.

    self:SetDefaultTakeoff( AI_A2A_DISPATCHER.Takeoff.Air )
    self:SetDefaultTakeoffInAirAltitude( 500 ) -- Default takeoff is 500 meters above the ground.
    self:SetDefaultLanding( AI_A2A_DISPATCHER.Landing.NearAirbase )
    self:SetDefaultOverhead( 1 )
    self:SetDefaultGrouping( 1 )
    self:SetDefaultFuelThreshold( 0.15, 0 ) -- 15% of fuel remaining in the tank will trigger the airplane to return to base or refuel.
    self:SetDefaultDamageThreshold( 0.4 ) -- When 40% of damage, go RTB.
    self:SetDefaultCapTimeInterval( 180, 600 ) -- Between 180 and 600 seconds.
    self:SetDefaultCapLimit( 1 ) -- Maximum one CAP per squadron.

    self:AddTransition( "Started", "Assign", "Started" )

    --- OnAfter Transition Handler for Event Assign.
    -- @function [parent=#AI_A2A_DISPATCHER] OnAfterAssign
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @param Tasking.Task_A2A#AI_A2A Task
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param #string PlayerName

    self:AddTransition( "*", "CAP", "*" )

    --- CAP Handler OnBefore for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] OnBeforeCAP
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean

    --- CAP Handler OnAfter for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] OnAfterCAP
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To

    --- CAP Trigger for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] CAP
    -- @param #AI_A2A_DISPATCHER self

    --- CAP Asynchronous Trigger for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] __CAP
    -- @param #AI_A2A_DISPATCHER self
    -- @param #number Delay

    self:AddTransition( "*", "GCI", "*" )

    --- GCI Handler OnBefore for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] OnBeforeGCI
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean

    --- GCI Handler OnAfter for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] OnAfterGCI
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detected item.
    -- @param #number DefendersMissing Number of missing defenders.
    -- @param #table DefenderFriendlies Friendly defenders.

    --- GCI Trigger for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] GCI
    -- @param #AI_A2A_DISPATCHER self
    -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detected item.
    -- @param #number DefendersMissing Number of missing defenders.
    -- @param #table DefenderFriendlies Friendly defenders.

    --- GCI Asynchronous Trigger for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] __GCI
    -- @param #AI_A2A_DISPATCHER self
    -- @param #number Delay
    -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detected item.
    -- @param #number DefendersMissing Number of missing defenders.
    -- @param #table DefenderFriendlies Friendly defenders.

    self:AddTransition( "*", "ENGAGE", "*" )

    --- ENGAGE Handler OnBefore for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] OnBeforeENGAGE
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detected item.
    -- @param #table Defenders Defenders table.
    -- @return #boolean

    --- ENGAGE Handler OnAfter for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] OnAfterENGAGE
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detected item.
    -- @param #table Defenders Defenders table.

    --- ENGAGE Trigger for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] ENGAGE
    -- @param #AI_A2A_DISPATCHER self
    -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detected item.
    -- @param #table Defenders Defenders table.

    --- ENGAGE Asynchronous Trigger for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] __ENGAGE
    -- @param #AI_A2A_DISPATCHER self
    -- @param #number Delay
    -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detected item.
    -- @param #table Defenders Defenders table.

    -- Subscribe to the CRASH event so that when planes are shot
    -- by a Unit from the dispatcher, they will be removed from the detection...
    -- This will avoid the detection to still "know" the shot unit until the next detection.
    -- Otherwise, a new intercept or engage may happen for an already shot plane!

    self:HandleEvent( EVENTS.Crash, self.OnEventCrashOrDead )
    self:HandleEvent( EVENTS.Dead, self.OnEventCrashOrDead )
    -- self:HandleEvent( EVENTS.RemoveUnit, self.OnEventCrashOrDead )

    self:HandleEvent( EVENTS.Land )
    self:HandleEvent( EVENTS.EngineShutdown )

    -- Handle the situation where the airbases are captured.
    self:HandleEvent( EVENTS.BaseCaptured )

    self:SetTacticalDisplay( false )

    self.DefenderCAPIndex = 0

    self:__Start( 5 )

    return self
  end

  --- On after "Start" event.
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:onafterStart( From, Event, To )

    self:GetParent( self, AI_A2A_DISPATCHER ).onafterStart( self, From, Event, To )

    -- Spawn the resources.
    for SquadronName, _DefenderSquadron in pairs( self.DefenderSquadrons ) do
      local DefenderSquadron = _DefenderSquadron -- #AI_A2A_DISPATCHER.Squadron
      DefenderSquadron.Resources = {}
      if DefenderSquadron.ResourceCount then
        for Resource = 1, DefenderSquadron.ResourceCount do
          self:ParkDefender( DefenderSquadron )
        end
      end
    end
  end

  --- Park defender.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #AI_A2A_DISPATCHER.Squadron DefenderSquadron The squadron.
  function AI_A2A_DISPATCHER:ParkDefender( DefenderSquadron )

    local TemplateID = math.random( 1, #DefenderSquadron.Spawn )

    local Spawn = DefenderSquadron.Spawn[TemplateID] -- Core.Spawn#SPAWN

    Spawn:InitGrouping( 1 )

    local SpawnGroup

    if self:IsSquadronVisible( DefenderSquadron.Name ) then

      local Grouping = DefenderSquadron.Grouping or self.DefenderDefault.Grouping

      Grouping = 1

      Spawn:InitGrouping( Grouping )

      SpawnGroup = Spawn:SpawnAtAirbase( DefenderSquadron.Airbase, SPAWN.Takeoff.Cold )

      local GroupName = SpawnGroup:GetName()

      DefenderSquadron.Resources = DefenderSquadron.Resources or {}

      DefenderSquadron.Resources[TemplateID] = DefenderSquadron.Resources[TemplateID] or {}
      DefenderSquadron.Resources[TemplateID][GroupName] = {}
      DefenderSquadron.Resources[TemplateID][GroupName] = SpawnGroup

      self.uncontrolled = self.uncontrolled or {}
      self.uncontrolled[DefenderSquadron.Name] = self.uncontrolled[DefenderSquadron.Name] or {}

      table.insert( self.uncontrolled[DefenderSquadron.Name], { group = SpawnGroup, name = GroupName, grouping = Grouping } )
    end

  end

  --- Event base captured.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_A2A_DISPATCHER:OnEventBaseCaptured( EventData )

    local AirbaseName = EventData.PlaceName -- The name of the airbase that was captured.

    self:I( "Captured " .. AirbaseName )

    -- Now search for all squadrons located at the airbase, and sanitize them.
    for SquadronName, Squadron in pairs( self.DefenderSquadrons ) do
      if Squadron.AirbaseName == AirbaseName then
        Squadron.ResourceCount = -999 -- The base has been captured, and the resources are eliminated. No more spawning.
        Squadron.Captured = true
        self:I( "Squadron " .. SquadronName .. " captured." )
      end
    end
  end

  --- Event dead or crash.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_A2A_DISPATCHER:OnEventCrashOrDead( EventData )
    self.Detection:ForgetDetectedUnit( EventData.IniUnitName )
  end

  --- Event land.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_A2A_DISPATCHER:OnEventLand( EventData )
    self:F( "Landed" )
    local DefenderUnit = EventData.IniUnit
    local Defender = EventData.IniGroup
    local Squadron = self:GetSquadronFromDefender( Defender )
    if Squadron then
      self:F( { SquadronName = Squadron.Name } )
      local LandingMethod = self:GetSquadronLanding( Squadron.Name )
      if LandingMethod == AI_A2A_DISPATCHER.Landing.AtRunway then
        local DefenderSize = Defender:GetSize()
        if DefenderSize == 1 then
          self:RemoveDefenderFromSquadron( Squadron, Defender )
        end
        DefenderUnit:Destroy()
        self:ParkDefender( Squadron )
        return
      end
      if DefenderUnit:GetLife() ~= DefenderUnit:GetLife0() then
        -- Damaged units cannot be repaired anymore.
        DefenderUnit:Destroy()
        return
      end
    end
  end

  --- Event engine shutdown.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_A2A_DISPATCHER:OnEventEngineShutdown( EventData )
    local DefenderUnit = EventData.IniUnit
    local Defender = EventData.IniGroup
    local Squadron = self:GetSquadronFromDefender( Defender )
    if Squadron then
      self:F( { SquadronName = Squadron.Name } )
      local LandingMethod = self:GetSquadronLanding( Squadron.Name )
      if LandingMethod == AI_A2A_DISPATCHER.Landing.AtEngineShutdown and not DefenderUnit:InAir() then
        local DefenderSize = Defender:GetSize()
        if DefenderSize == 1 then
          self:RemoveDefenderFromSquadron( Squadron, Defender )
        end
        DefenderUnit:Destroy()
        self:ParkDefender( Squadron )
      end
    end
  end

  --- Define the radius to engage any target by airborne friendlies, which are executing cap or returning from an intercept mission.
  -- If there is a target area detected and reported, then any friendlies that are airborne near this target area,
  -- will be commanded to (re-)engage that target when available (if no other tasks were commanded).
  --
  -- For example, if 100000 is given as a value, then any friendly that is airborne within 100km from the detected target,
  -- will be considered to receive the command to engage that target area.
  --
  -- You need to evaluate the value of this parameter carefully:
  --
  --   * If too small, more intercept missions may be triggered upon detected target areas.
  --   * If too large, any airborne cap may not be able to reach the detected target area in time, because it is too far.
  --
  -- **Use the method @{#AI_A2A_DISPATCHER.SetEngageRadius}() to modify the default Engage Radius for ALL squadrons.**
  --
  -- Demonstration Mission: [AID-019 - AI_A2A - Engage Range Test](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/release-2-2-pre/AID%20-%20AI%20Dispatching/AID-019%20-%20AI_A2A%20-%20Engage%20Range%20Test)
  --
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number EngageRadius (Optional, Default = 100000) The radius to report friendlies near the target.
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  --
  --   -- Set 50km as the radius to engage any target by airborne friendlies.
  --   A2ADispatcher:SetEngageRadius( 50000 )
  --
  --   -- Set 100km as the radius to engage any target by airborne friendlies.
  --   A2ADispatcher:SetEngageRadius() -- 100000 is the default value.
  --
  function AI_A2A_DISPATCHER:SetEngageRadius( EngageRadius )

    self.Detection:SetFriendliesRange( EngageRadius or 100000 )

    return self
  end

  --- Define the radius to disengage any target when the distance to the home base is larger than the specified meters.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number DisengageRadius (Optional, Default = 300000) The radius in meters to disengage a target when too far from the home base.
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  --
  --   -- Set 50km as the Disengage Radius.
  --   A2ADispatcher:SetDisengageRadius( 50000 )
  --
  --   -- Set 100km as the Disengage Radius.
  --   A2ADispatcher:SetDisengageRadius() -- 300000 is the default value.
  --
  function AI_A2A_DISPATCHER:SetDisengageRadius( DisengageRadius )

    self.DisengageRadius = DisengageRadius or 300000

    return self
  end

  --- Define the radius to check if a target can be engaged by an ground controlled intercept.
  -- When targets are detected that are still really far off, you don't want the AI_A2A_DISPATCHER to launch intercepts just yet.
  -- You want it to wait until a certain Gci range is reached, which is the **distance of the closest airbase to target**
  -- being **smaller** than the **Ground Controlled Intercept radius** or **Gci radius**.
  --
  -- The **default** Gci radius is defined as **200000** or **200km**. Override the default Gci radius when the era of the warfare is early, or,
  -- when you don't want to let the AI_A2A_DISPATCHER react immediately when a certain border or area is not being crossed.
  --
  -- Use the method @{#AI_A2A_DISPATCHER.SetGciRadius}() to set a specific controlled ground intercept radius.
  -- **The Ground Controlled Intercept radius is defined for ALL squadrons which are operational.**
  --
  -- Demonstration Mission: [AID-013 - AI_A2A - Intercept Test](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/release-2-2-pre/AID%20-%20AI%20Dispatching/AID-013%20-%20AI_A2A%20-%20Intercept%20Test)
  --
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number GciRadius (Optional, Default = 200000) The radius to ground control intercept detected targets from the nearest airbase.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Set 100km as the radius to ground control intercept detected targets from the nearest airbase.
  --   A2ADispatcher:SetGciRadius( 100000 )
  --
  --   -- Set 200km as the radius to ground control intercept.
  --   A2ADispatcher:SetGciRadius() -- 200000 is the default value.
  --
  function AI_A2A_DISPATCHER:SetGciRadius( GciRadius )

    self.GciRadius = GciRadius or 200000

    return self
  end

  --- Define a border area to simulate a **cold war** scenario.
  -- A **cold war** is one where CAP aircraft patrol their territory but will not attack enemy aircraft or launch GCI aircraft unless enemy aircraft enter their territory. In other words the EWR may detect an enemy aircraft but will only send aircraft to attack it if it crosses the border.
  -- A **hot war** is one where CAP aircraft will intercept any detected enemy aircraft and GCI aircraft will launch against detected enemy aircraft without regard for territory. In other words if the ground radar can detect the enemy aircraft then it will send CAP and GCI aircraft to attack it.
  -- If it's a cold war then the **borders of red and blue territory** need to be defined using a @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE}. This method needs to be used for this.
  -- If a hot war is chosen then **no borders** actually need to be defined using the helicopter units other than it makes it easier sometimes for the mission maker to envisage where the red and blue territories roughly are. In a hot war the borders are effectively defined by the ground based radar coverage of a coalition. Set the noborders parameter to 1
  -- @param #AI_A2A_DISPATCHER self
  -- @param Core.Zone#ZONE_BASE BorderZone An object derived from ZONE_BASE, or a list of objects derived from ZONE_BASE.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Set one ZONE_POLYGON object as the border for the A2A dispatcher.
  --   local BorderZone = ZONE_POLYGON( "CCCP Border", GROUP:FindByName( "CCCP Border" ) ) -- The GROUP object is a late activate helicopter unit.
  --   A2ADispatcher:SetBorderZone( BorderZone )
  --
  -- or
  --
  --   -- Set two ZONE_POLYGON objects as the border for the A2A dispatcher.
  --   local BorderZone1 = ZONE_POLYGON( "CCCP Border1", GROUP:FindByName( "CCCP Border1" ) ) -- The GROUP object is a late activate helicopter unit.
  --   local BorderZone2 = ZONE_POLYGON( "CCCP Border2", GROUP:FindByName( "CCCP Border2" ) ) -- The GROUP object is a late activate helicopter unit.
  --   A2ADispatcher:SetBorderZone( { BorderZone1, BorderZone2 } )
  --
  --
  function AI_A2A_DISPATCHER:SetBorderZone( BorderZone )

    self.Detection:SetAcceptZones( BorderZone )

    return self
  end

  --- Display a tactical report every 30 seconds about which aircraft are:
  --   * Patrolling
  --   * Engaging
  --   * Returning
  --   * Damaged
  --   * Out of Fuel
  --   * ...
  -- @param #AI_A2A_DISPATCHER self
  -- @param #boolean TacticalDisplay Provide a value of **true** to display every 30 seconds a tactical overview.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Now Setup the Tactical Display for debug mode.
  --   A2ADispatcher:SetTacticalDisplay( true )
  --
  function AI_A2A_DISPATCHER:SetTacticalDisplay( TacticalDisplay )

    self.TacticalDisplay = TacticalDisplay

    return self
  end

  --- Set the default damage threshold when defenders will RTB.
  -- The default damage threshold is by default set to 40%, which means that when the airplane is 40% damaged, it will go RTB.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number DamageThreshold A decimal number between 0 and 1, that expresses the % of the damage threshold before going RTB.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Now Setup the default damage threshold.
  --   A2ADispatcher:SetDefaultDamageThreshold( 0.90 ) -- Go RTB when the airplane 90% damaged.
  --
  function AI_A2A_DISPATCHER:SetDefaultDamageThreshold( DamageThreshold )

    self.DefenderDefault.DamageThreshold = DamageThreshold

    return self
  end

  --- Set the default CAP time interval for squadrons, which will be used to determine a random CAP timing.
  -- The default CAP time interval is between 180 and 600 seconds.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number CapMinSeconds The minimum amount of seconds for the random time interval.
  -- @param #number CapMaxSeconds The maximum amount of seconds for the random time interval.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Now Setup the default CAP time interval.
  --   A2ADispatcher:SetDefaultCapTimeInterval( 300, 1200 ) -- Between 300 and 1200 seconds.
  --
  function AI_A2A_DISPATCHER:SetDefaultCapTimeInterval( CapMinSeconds, CapMaxSeconds )

    self.DefenderDefault.CapMinSeconds = CapMinSeconds
    self.DefenderDefault.CapMaxSeconds = CapMaxSeconds

    return self
  end

  --- Set the default CAP limit for squadrons, which will be used to determine how many CAP can be airborne at the same time for the squadron.
  -- The default CAP limit is 1 CAP, which means one CAP group being spawned.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number CapLimit The maximum amount of CAP that can be airborne at the same time for the squadron.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Now Setup the default CAP limit.
  --   A2ADispatcher:SetDefaultCapLimit( 2 ) -- Maximum 2 CAP per squadron.
  --
  function AI_A2A_DISPATCHER:SetDefaultCapLimit( CapLimit )

    self.DefenderDefault.CapLimit = CapLimit

    return self
  end

  --- Set intercept.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number InterceptDelay Delay in seconds before intercept.
  -- @return #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:SetIntercept( InterceptDelay )

    self.DefenderDefault.InterceptDelay = InterceptDelay

    local Detection = self.Detection -- Functional.Detection#DETECTION_AREAS
    Detection:SetIntercept( true, InterceptDelay )

    return self
  end

  --- Calculates which AI friendlies are nearby the area
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return #table A list of the friendlies nearby.
  function AI_A2A_DISPATCHER:GetAIFriendliesNearBy( DetectedItem )

    local FriendliesNearBy = self.Detection:GetFriendliesDistance( DetectedItem )

    return FriendliesNearBy
  end

  --- Return the defender tasks table.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #table Defender tasks as table.
  function AI_A2A_DISPATCHER:GetDefenderTasks()
    return self.DefenderTasks or {}
  end

  --- Get defender task.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Wrapper.Group#GROUP Defender The defender group.
  -- @return #table Defender task.
  function AI_A2A_DISPATCHER:GetDefenderTask( Defender )
    return self.DefenderTasks[Defender]
  end

  --- Get defender task FSM.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Wrapper.Group#GROUP Defender The defender group.
  -- @return Core.Fsm#FSM The FSM.
  function AI_A2A_DISPATCHER:GetDefenderTaskFsm( Defender )
    return self:GetDefenderTask( Defender ).Fsm
  end

  --- Get target of defender.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Wrapper.Group#GROUP Defender The defender group.
  -- @return Target
  function AI_A2A_DISPATCHER:GetDefenderTaskTarget( Defender )
    return self:GetDefenderTask( Defender ).Target
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param Wrapper.Group#GROUP Defender The defender group.
  -- @return #string Squadron name of the defender task.
  function AI_A2A_DISPATCHER:GetDefenderTaskSquadronName( Defender )
    return self:GetDefenderTask( Defender ).SquadronName
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param Wrapper.Group#GROUP Defender The defender group.
  function AI_A2A_DISPATCHER:ClearDefenderTask( Defender )
    if Defender and Defender:IsAlive() and self.DefenderTasks[Defender] then
      local Target = self.DefenderTasks[Defender].Target
      local Message = "Clearing (" .. self.DefenderTasks[Defender].Type .. ") "
      Message = Message .. Defender:GetName()
      if Target then
        Message = Message .. (Target and (" from " .. Target.Index .. " [" .. Target.Set:Count() .. "]")) or ""
      end
      self:F( { Target = Message } )
    end
    self.DefenderTasks[Defender] = nil
    return self
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param Wrapper.Group#GROUP Defender The defender group.
  function AI_A2A_DISPATCHER:ClearDefenderTaskTarget( Defender )

    local DefenderTask = self:GetDefenderTask( Defender )

    if Defender and Defender:IsAlive() and DefenderTask then
      local Target = DefenderTask.Target
      local Message = "Clearing (" .. DefenderTask.Type .. ") "
      Message = Message .. Defender:GetName()
      if Target then
        Message = Message .. ((Target and (" from " .. Target.Index .. " [" .. Target.Set:Count() .. "]")) or "")
      end
      self:F( { Target = Message } )
    end
    if Defender and DefenderTask and DefenderTask.Target then
      DefenderTask.Target = nil
    end
    --    if Defender and DefenderTask then
    --      if DefenderTask.Fsm:Is( "Fuel" )
    --      or DefenderTask.Fsm:Is( "LostControl")
    --      or DefenderTask.Fsm:Is( "Damaged" ) then
    --        self:ClearDefenderTask( Defender )
    --      end
    --    end
    return self
  end

  --- Set defender task.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName Name of the squadron.
  -- @param Wrapper.Group#GROUP Defender The defender group.
  -- @param #table Type Type of the defender task
  -- @param Core.Fsm#FSM Fsm The defender task FSM.
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem Target The defender detected item.
  -- @return #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:SetDefenderTask( SquadronName, Defender, Type, Fsm, Target )

    self:F( { SquadronName = SquadronName, Defender = Defender:GetName(), Type = Type, Target = Target } )

    self.DefenderTasks[Defender] = self.DefenderTasks[Defender] or {}
    self.DefenderTasks[Defender].Type = Type
    self.DefenderTasks[Defender].Fsm = Fsm
    self.DefenderTasks[Defender].SquadronName = SquadronName

    if Target then
      self:SetDefenderTaskTarget( Defender, Target )
    end
    return self
  end

  --- Set defender task target.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Wrapper.Group#GROUP Defender The defender group.
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection The detection object.
  -- @return #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:SetDefenderTaskTarget( Defender, AttackerDetection )

    local Message = "(" .. self.DefenderTasks[Defender].Type .. ") "
    Message = Message .. Defender:GetName()
    Message = Message .. ((AttackerDetection and (" target " .. AttackerDetection.Index .. " [" .. AttackerDetection.Set:Count() .. "]")) or "")
    self:F( { AttackerDetection = Message } )
    if AttackerDetection then
      self.DefenderTasks[Defender].Target = AttackerDetection
    end
    return self
  end

  --- This is the main method to define Squadrons programmatically.
  -- Squadrons:
  --
  --   * Have a **name or key** that is the identifier or key of the squadron.
  --   * Have **specific plane types** defined by **templates**.
  --   * Are **located at one specific airbase**. Multiple squadrons can be located at one airbase through.
  --   * Optionally have a limited set of **resources**. The default is that squadrons have unlimited resources.
  --
  -- The name of the squadron given acts as the **squadron key** in the AI\_A2A\_DISPATCHER:Squadron...() methods.
  --
  -- Additionally, squadrons have specific configuration options to:
  --
  --   * Control how new aircraft are **taking off** from the airfield (in the air, cold, hot, at the runway).
  --   * Control how returning aircraft are **landing** at the airfield (in the air near the airbase, after landing, after engine shutdown).
  --   * Control the **grouping** of new aircraft spawned at the airfield. If there is more than one aircraft to be spawned, these may be grouped.
  --   * Control the **overhead** or defensive strength of the squadron. Depending on the types of planes and amount of resources, the mission designer can choose to increase or reduce the amount of planes spawned.
  --
  -- For performance and bug workaround reasons within DCS, squadrons have different methods to spawn new aircraft or land returning or damaged aircraft.
  --
  -- @param #AI_A2A_DISPATCHER self
  --
  -- @param #string SquadronName A string (text) that defines the squadron identifier or the key of the Squadron.
  -- It can be any name, for example `"104th Squadron"` or `"SQ SQUADRON1"`, whatever.
  -- As long as you remember that this name becomes the identifier of your squadron you have defined.
  -- You need to use this name in other methods too!
  --
  -- @param #string AirbaseName The airbase name where you want to have the squadron located.
  -- You need to specify here EXACTLY the name of the airbase as you see it in the mission editor.
  -- Examples are `"Batumi"` or `"Tbilisi-Lochini"`.
  -- EXACTLY the airbase name, between quotes `""`.
  -- To ease the airbase naming when using the LDT editor and IntelliSense, the @{Wrapper.Airbase#AIRBASE} class contains enumerations of the airbases of each map.
  --
  --    * Caucasus: @{Wrapper.Airbase#AIRBASE.Caucaus}
  --    * Nevada or NTTR: @{Wrapper.Airbase#AIRBASE.Nevada}
  --    * Normandy: @{Wrapper.Airbase#AIRBASE.Normandy}
  --
  -- @param #string TemplatePrefixes A string or an array of strings specifying the **prefix names of the templates** (not going to explain what is templates here again).
  -- Examples are `{ "104th", "105th" }` or `"104th"` or `"Template 1"` or `"BLUE PLANES"`.
  -- Just remember that your template (groups late activated) need to start with the prefix you have specified in your code.
  -- If you have only one prefix name for a squadron, you don't need to use the `{ }`, otherwise you need to use the brackets.
  --
  -- @param #number ResourceCount (optional) A number that specifies how many resources are in stock of the squadron. If not specified, the squadron will have infinite resources available.
  -- @return #AI_A2A_DISPATCHER self
  --
  -- @usage
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  -- @usage
  --   -- This will create squadron "Squadron1" at "Batumi" airbase, and will use plane types "SQ1" and has 40 planes in stock...
  --   A2ADispatcher:SetSquadron( "Squadron1", "Batumi", "SQ1", 40 )
  --
  -- @usage
  --   -- This will create squadron "Sq 1" at "Batumi" airbase, and will use plane types "Mig-29" and "Su-27" and has 20 planes in stock...
  --   -- Note that in this implementation, the A2A dispatcher will select a random plane type when a new plane (group) needs to be spawned for defenses.
  --   -- Note the usage of the {} for the airplane templates list.
  --   A2ADispatcher:SetSquadron( "Sq 1", "Batumi", { "Mig-29", "Su-27" }, 40 )
  --
  -- @usage
  --   -- This will create 2 squadrons "104th" and "23th" at "Batumi" airbase, and will use plane types "Mig-29" and "Su-27" respectively and each squadron has 10 planes in stock...
  --   A2ADispatcher:SetSquadron( "104th", "Batumi", "Mig-29", 10 )
  --   A2ADispatcher:SetSquadron( "23th", "Batumi", "Su-27", 10 )
  --
  -- @usage
  --   -- This is an example like the previous, but now with infinite resources.
  --   -- The ResourceCount parameter is not given in the SetSquadron method.
  --   A2ADispatcher:SetSquadron( "104th", "Batumi", "Mig-29" )
  --   A2ADispatcher:SetSquadron( "23th", "Batumi", "Su-27" )
  --
  function AI_A2A_DISPATCHER:SetSquadron( SquadronName, AirbaseName, TemplatePrefixes, ResourceCount )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}

    local DefenderSquadron = self.DefenderSquadrons[SquadronName] -- #AI_A2A_DISPATCHER.Squadron

    DefenderSquadron.Name = SquadronName
    DefenderSquadron.Airbase = AIRBASE:FindByName( AirbaseName )
    DefenderSquadron.AirbaseName = DefenderSquadron.Airbase:GetName()
    if not DefenderSquadron.Airbase then
      error( "Cannot find airbase with name:" .. AirbaseName )
    end

    DefenderSquadron.Spawn = {}
    if type( TemplatePrefixes ) == "string" then
      local SpawnTemplate = TemplatePrefixes
      self.DefenderSpawns[SpawnTemplate] = self.DefenderSpawns[SpawnTemplate] or SPAWN:New( SpawnTemplate ) -- :InitCleanUp( 180 )
      DefenderSquadron.Spawn[1] = self.DefenderSpawns[SpawnTemplate]
    else
      for TemplateID, SpawnTemplate in pairs( TemplatePrefixes ) do
        self.DefenderSpawns[SpawnTemplate] = self.DefenderSpawns[SpawnTemplate] or SPAWN:New( SpawnTemplate ) -- :InitCleanUp( 180 )
        DefenderSquadron.Spawn[#DefenderSquadron.Spawn + 1] = self.DefenderSpawns[SpawnTemplate]
      end
    end
    DefenderSquadron.ResourceCount = ResourceCount
    DefenderSquadron.TemplatePrefixes = TemplatePrefixes
    DefenderSquadron.Captured = false -- Not captured. This flag will be set to true, when the airbase where the squadron is located, is captured.

    self:SetSquadronLanguage( SquadronName, "EN" ) -- Squadrons speak English by default.

    self:F( { Squadron = { SquadronName, AirbaseName, TemplatePrefixes, ResourceCount } } )

    return self
  end

  --- Get an item from the Squadron table.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName Name of the squadron.
  -- @return #AI_A2A_DISPATCHER.Squadron Defender squadron table.
  function AI_A2A_DISPATCHER:GetSquadron( SquadronName )
    local DefenderSquadron = self.DefenderSquadrons[SquadronName]

    if not DefenderSquadron then
      error( "Unknown Squadron:" .. SquadronName )
    end

    return DefenderSquadron
  end
  
  --- Get a resource count from a specific squadron
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string Squadron Name of the squadron.
  -- @return #number Number of airframes available or nil if the squadron does not exist
  function AI_A2A_DISPATCHER:QuerySquadron(Squadron)
    local Squadron = self:GetSquadron(Squadron)
    if Squadron.ResourceCount then
      self:T2(string.format("%s = %s",Squadron.Name,Squadron.ResourceCount))
      return Squadron.ResourceCount
    end
    self:F({Squadron = Squadron.Name,SquadronResourceCount = Squadron.ResourceCount})
    return nil
  end

  --- [DEPRECATED - Might create problems launching planes] Set the Squadron visible before startup of the dispatcher.
  -- All planes will be spawned as uncontrolled on the parking spot.
  -- They will lock the parking spot.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --   -- Set the Squadron visible before startup of dispatcher.
  --   A2ADispatcher:SetSquadronVisible( "Mineralnye" )
  --
  function AI_A2A_DISPATCHER:SetSquadronVisible( SquadronName )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}

    local DefenderSquadron = self:GetSquadron( SquadronName ) -- #AI_A2A_DISPATCHER.Squadron

    DefenderSquadron.Uncontrolled = true

    -- For now, grouping is forced to 1 due to other parts of the class which would not work well with grouping>1.
    DefenderSquadron.Grouping = 1

    -- Get free parking for fighter aircraft.
    local nfreeparking = DefenderSquadron.Airbase:GetFreeParkingSpotsNumber( AIRBASE.TerminalType.FighterAircraft, true )

    -- Take number of free parking spots if no resource count was specified.
    DefenderSquadron.ResourceCount = DefenderSquadron.ResourceCount or nfreeparking

    -- Check that resource count is not larger than free parking spots.
    DefenderSquadron.ResourceCount = math.min( DefenderSquadron.ResourceCount, nfreeparking )

    -- Set uncontrolled spawning option.
    for SpawnTemplate, _DefenderSpawn in pairs( self.DefenderSpawns ) do
      local DefenderSpawn = _DefenderSpawn -- Core.Spawn#SPAWN
      DefenderSpawn:InitUnControlled( true )
    end

  end

  --- Check if the Squadron is visible before startup of the dispatcher.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #boolean true if visible.
  -- @usage
  --
  --   -- Set the Squadron visible before startup of dispatcher.
  --   local IsVisible = A2ADispatcher:IsSquadronVisible( "Mineralnye" )
  --
  function AI_A2A_DISPATCHER:IsSquadronVisible( SquadronName )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}

    local DefenderSquadron = self:GetSquadron( SquadronName ) -- #AI_A2A_DISPATCHER.Squadron

    if DefenderSquadron then
      return DefenderSquadron.Uncontrolled == true
    end

    return nil

  end

  --- Set a CAP for a Squadron.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed The maximum speed at which the engage can be executed.
  -- @param DCS#Altitude EngageFloorAltitude The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude The highest altitude in meters where to execute the engagement.
  -- @param #number EngageAltType The altitude type to engage, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @param Core.Zone#ZONE_BASE Zone The @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the CAP will be executed.
  -- @param #number PatrolMinSpeed The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed The maximum speed at which the cap can be executed.
  -- @param #number PatrolFloorAltitude The minimum altitude at which the cap can be executed.
  -- @param #number PatrolCeilingAltitude the maximum altitude at which the cap can be executed.
  -- @param #number PatrolAltType The altitude type to patrol, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  --
  --   -- CAP Squadron execution.
  --   CAPZoneEast = ZONE_POLYGON:New( "CAP Zone East", GROUP:FindByName( "CAP Zone East" ) )
  --   -- Setup a CAP, engaging between 800 and 900 km/h, altitude 30 (above the sea), radio altitude measurement,
  --   -- patrolling speed between 500 and 600 km/h, altitude between 4000 and 10000 meters, barometric altitude measurement.
  --   A2ADispatcher:SetSquadronCapV2( "Mineralnye", 800, 900, 30, 30, "RADIO", CAPZoneEast, 500, 600, 4000, 10000, "BARO" )
  --   A2ADispatcher:SetSquadronCapInterval( "Mineralnye", 2, 30, 60, 1 )
  --
  --   CAPZoneWest = ZONE_POLYGON:New( "CAP Zone West", GROUP:FindByName( "CAP Zone West" ) )
  --   -- Setup a CAP, engaging between 800 and 1200 km/h, altitude between 4000 and 10000 meters, radio altitude measurement,
  --   -- patrolling speed between 600 and 800 km/h, altitude between 4000 and 8000, barometric altitude measurement.
  --   A2ADispatcher:SetSquadronCapV2( "Sochi", 800, 1200, 2000, 3000, "RADIO", CAPZoneWest, 600, 800, 4000, 8000, "BARO" )
  --   A2ADispatcher:SetSquadronCapInterval( "Sochi", 2, 30, 120, 1 )
  --
  --   CAPZoneMiddle = ZONE:New( "CAP Zone Middle")
  --   -- Setup a CAP, engaging between 800 and 1200 km/h, altitude between 5000 and 8000 meters, barometric altitude measurement,
  --   -- patrolling speed between 600 and 800 km/h, altitude between 4000 and 8000, radio altitude.
  --   A2ADispatcher:SetSquadronCapV2( "Maykop", 800, 1200, 5000, 8000, "BARO", CAPZoneMiddle, 600, 800, 4000, 8000, "RADIO" )
  --   A2ADispatcher:SetSquadronCapInterval( "Maykop", 2, 30, 120, 1 )
  --
  function AI_A2A_DISPATCHER:SetSquadronCap2( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType, Zone, PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}

    local DefenderSquadron = self:GetSquadron( SquadronName )

    local Cap = self.DefenderSquadrons[SquadronName].Cap
    Cap.Name = SquadronName
    Cap.EngageMinSpeed = EngageMinSpeed
    Cap.EngageMaxSpeed = EngageMaxSpeed
    Cap.EngageFloorAltitude = EngageFloorAltitude
    Cap.EngageCeilingAltitude = EngageCeilingAltitude
    Cap.Zone = Zone
    Cap.PatrolMinSpeed = PatrolMinSpeed
    Cap.PatrolMaxSpeed = PatrolMaxSpeed
    Cap.PatrolFloorAltitude = PatrolFloorAltitude
    Cap.PatrolCeilingAltitude = PatrolCeilingAltitude
    Cap.PatrolAltType = PatrolAltType
    Cap.EngageAltType = EngageAltType

    self:SetSquadronCapInterval( SquadronName, self.DefenderDefault.CapLimit, self.DefenderDefault.CapMinSeconds, self.DefenderDefault.CapMaxSeconds, 1 )

    self:I( { CAP = { SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, Zone, PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType, EngageAltType } } )

    -- Add the CAP to the EWR network.

    local RecceSet = self.Detection:GetDetectionSet()
    RecceSet:FilterPrefixes( DefenderSquadron.TemplatePrefixes )
    RecceSet:FilterStart()

    self.Detection:SetFriendlyPrefixes( DefenderSquadron.TemplatePrefixes )

    return self
  end

  --- Set a CAP for a Squadron.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the CAP will be executed.
  -- @param #number PatrolFloorAltitude The minimum altitude at which the cap can be executed.
  -- @param #number PatrolCeilingAltitude the maximum altitude at which the cap can be executed.
  -- @param #number PatrolMinSpeed The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed The maximum speed at which the cap can be executed.
  -- @param #number EngageMinSpeed The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed The maximum speed at which the engage can be executed.
  -- @param #number AltType The altitude type, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  --
  --   -- CAP Squadron execution.
  --   CAPZoneEast = ZONE_POLYGON:New( "CAP Zone East", GROUP:FindByName( "CAP Zone East" ) )
  --   A2ADispatcher:SetSquadronCap( "Mineralnye", CAPZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --   A2ADispatcher:SetSquadronCapInterval( "Mineralnye", 2, 30, 60, 1 )
  --
  --   CAPZoneWest = ZONE_POLYGON:New( "CAP Zone West", GROUP:FindByName( "CAP Zone West" ) )
  --   A2ADispatcher:SetSquadronCap( "Sochi", CAPZoneWest, 4000, 8000, 600, 800, 800, 1200, "BARO" )
  --   A2ADispatcher:SetSquadronCapInterval( "Sochi", 2, 30, 120, 1 )
  --
  --   CAPZoneMiddle = ZONE:New( "CAP Zone Middle")
  --   A2ADispatcher:SetSquadronCap( "Maykop", CAPZoneMiddle, 4000, 8000, 600, 800, 800, 1200, "RADIO" )
  --   A2ADispatcher:SetSquadronCapInterval( "Sochi", 2, 30, 120, 1 )
  --
  function AI_A2A_DISPATCHER:SetSquadronCap( SquadronName, Zone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, AltType )

    return self:SetSquadronCap2( SquadronName, EngageMinSpeed, EngageMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, AltType, Zone, PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, AltType )
  end

  --- Set the squadron CAP parameters.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number CapLimit (optional) The maximum amount of CAP groups to be spawned. Note that a CAP is a group, so can consist out of 1 to 4 airplanes. The default is 1 CAP group.
  -- @param #number LowInterval (optional) The minimum time boundary in seconds when a new CAP will be spawned. The default is 180 seconds.
  -- @param #number HighInterval (optional) The maximum time boundary in seconds when a new CAP will be spawned. The default is 600 seconds.
  -- @param #number Probability Is not in use, you can skip this parameter.
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  --
  --   -- CAP Squadron execution.
  --   CAPZoneEast = ZONE_POLYGON:New( "CAP Zone East", GROUP:FindByName( "CAP Zone East" ) )
  --   A2ADispatcher:SetSquadronCap( "Mineralnye", CAPZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --   A2ADispatcher:SetSquadronCapInterval( "Mineralnye", 2, 30, 60, 1 )
  --
  --   CAPZoneWest = ZONE_POLYGON:New( "CAP Zone West", GROUP:FindByName( "CAP Zone West" ) )
  --   A2ADispatcher:SetSquadronCap( "Sochi", CAPZoneWest, 4000, 8000, 600, 800, 800, 1200, "BARO" )
  --   A2ADispatcher:SetSquadronCapInterval( "Sochi", 2, 30, 120, 1 )
  --
  --   CAPZoneMiddle = ZONE:New( "CAP Zone Middle")
  --   A2ADispatcher:SetSquadronCap( "Maykop", CAPZoneMiddle, 4000, 8000, 600, 800, 800, 1200, "RADIO" )
  --   A2ADispatcher:SetSquadronCapInterval( "Sochi", 2, 30, 120, 1 )
  --
  function AI_A2A_DISPATCHER:SetSquadronCapInterval( SquadronName, CapLimit, LowInterval, HighInterval, Probability )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}

    local DefenderSquadron = self:GetSquadron( SquadronName )

    local Cap = self.DefenderSquadrons[SquadronName].Cap
    if Cap then
      Cap.LowInterval = LowInterval or 180
      Cap.HighInterval = HighInterval or 600
      Cap.Probability = Probability or 1
      Cap.CapLimit = CapLimit or 1
      Cap.Scheduler = Cap.Scheduler or SCHEDULER:New( self )
      local Scheduler = Cap.Scheduler -- Core.Scheduler#SCHEDULER
      local ScheduleID = Cap.ScheduleID
      local Variance = (Cap.HighInterval - Cap.LowInterval) / 2
      local Repeat = Cap.LowInterval + Variance
      local Randomization = Variance / Repeat
      local Start = math.random( 1, Cap.HighInterval )

      if ScheduleID then
        Scheduler:Stop( ScheduleID )
      end

      Cap.ScheduleID = Scheduler:Schedule( self, self.SchedulerCAP, { SquadronName }, Start, Repeat, Randomization )
    else
      error( "This squadron does not exist:" .. SquadronName )
    end

  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:GetCAPDelay( SquadronName )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}

    local DefenderSquadron = self:GetSquadron( SquadronName )

    local Cap = self.DefenderSquadrons[SquadronName].Cap
    if Cap then
      return math.random( Cap.LowInterval, Cap.HighInterval )
    else
      error( "This squadron does not exist:" .. SquadronName )
    end
  end

  --- Check if squadron can do CAP.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #AI_A2A_DISPATCHER.Squadron DefenderSquadron
  function AI_A2A_DISPATCHER:CanCAP( SquadronName )
    self:F( { SquadronName = SquadronName } )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}

    local DefenderSquadron = self:GetSquadron( SquadronName )

    if DefenderSquadron.Captured == false then -- We can only spawn new CAP if the base has not been captured.

      if (not DefenderSquadron.ResourceCount) or (DefenderSquadron.ResourceCount and DefenderSquadron.ResourceCount > 0) then -- And, if there are sufficient resources.

        local Cap = DefenderSquadron.Cap
        if Cap then
          local CapCount = self:CountCapAirborne( SquadronName )
          self:F( { CapCount = CapCount } )
          if CapCount < Cap.CapLimit then
            local Probability = math.random()
            if Probability <= Cap.Probability then
              return DefenderSquadron
            end
          end
        end
      end
    end
    return nil
  end

  --- Set race track pattern as default when any squadron is performing CAP.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number LeglengthMin Min length of the race track leg in meters. Default 10,000 m.
  -- @param #number LeglengthMax Max length of the race track leg in meters. Default 15,000 m.
  -- @param #number HeadingMin Min heading of the race track in degrees. Default 0 deg, i.e. counter clockwise from South to North.
  -- @param #number HeadingMax Max heading of the race track in degrees. Default 180 deg, i.e. counter clockwise from North to South.
  -- @param #number DurationMin (Optional) Min duration in seconds before switching the orbit position. Default is keep same orbit until RTB or engage.
  -- @param #number DurationMax (Optional) Max duration in seconds before switching the orbit position. Default is keep same orbit until RTB or engage.
  -- @param #table CapCoordinates Table of coordinates of first race track point. Second point is determined by leg length and heading.
  -- @return #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:SetDefaultCapRacetrack( LeglengthMin, LeglengthMax, HeadingMin, HeadingMax, DurationMin, DurationMax, CapCoordinates )

    self.DefenderDefault.Racetrack = true
    self.DefenderDefault.RacetrackLengthMin = LeglengthMin
    self.DefenderDefault.RacetrackLengthMax = LeglengthMax
    self.DefenderDefault.RacetrackHeadingMin = HeadingMin
    self.DefenderDefault.RacetrackHeadingMax = HeadingMax
    self.DefenderDefault.RacetrackDurationMin = DurationMin
    self.DefenderDefault.RacetrackDurationMax = DurationMax
    self.DefenderDefault.RacetrackCoordinates = CapCoordinates

    return self
  end

  --- Set race track pattern when squadron is performing CAP.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName Name of the squadron.
  -- @param #number LeglengthMin Min length of the race track leg in meters. Default 10,000 m.
  -- @param #number LeglengthMax Max length of the race track leg in meters. Default 15,000 m.
  -- @param #number HeadingMin Min heading of the race track in degrees. Default 0 deg, i.e. from South to North.
  -- @param #number HeadingMax Max heading of the race track in degrees. Default 180 deg, i.e. from North to South.
  -- @param #number DurationMin (Optional) Min duration in seconds before switching the orbit position. Default is keep same orbit until RTB or engage.
  -- @param #number DurationMax (Optional) Max duration in seconds before switching the orbit position. Default is keep same orbit until RTB or engage.
  -- @param #table CapCoordinates Table of coordinates of first race track point. Second point is determined by leg length and heading.
  -- @return #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:SetSquadronCapRacetrack( SquadronName, LeglengthMin, LeglengthMax, HeadingMin, HeadingMax, DurationMin, DurationMax, CapCoordinates )

    local DefenderSquadron = self:GetSquadron( SquadronName )

    if DefenderSquadron then
      DefenderSquadron.Racetrack = true
      DefenderSquadron.RacetrackLengthMin = LeglengthMin
      DefenderSquadron.RacetrackLengthMax = LeglengthMax
      DefenderSquadron.RacetrackHeadingMin = HeadingMin
      DefenderSquadron.RacetrackHeadingMax = HeadingMax
      DefenderSquadron.RacetrackDurationMin = DurationMin
      DefenderSquadron.RacetrackDurationMax = DurationMax
      DefenderSquadron.RacetrackCoordinates = CapCoordinates
    end

    return self
  end

  --- Check if squadron can do GCI.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #table DefenderSquadron
  function AI_A2A_DISPATCHER:CanGCI( SquadronName )
    self:F( { SquadronName = SquadronName } )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}
    self.DefenderSquadrons[SquadronName].Gci = self.DefenderSquadrons[SquadronName].Gci or {}

    local DefenderSquadron = self:GetSquadron( SquadronName )

    if DefenderSquadron.Captured == false then -- We can only spawn new CAP if the base has not been captured.

      if (not DefenderSquadron.ResourceCount) or (DefenderSquadron.ResourceCount and DefenderSquadron.ResourceCount > 0) then -- And, if there are sufficient resources.
        local Gci = DefenderSquadron.Gci
        if Gci then
          return DefenderSquadron
        end
      end
    end
    return nil
  end

  --- Set squadron GCI.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed The minimum speed [km/h] at which the GCI can be executed.
  -- @param #number EngageMaxSpeed The maximum speed [km/h] at which the GCI can be executed.
  -- @param DCS#Altitude EngageFloorAltitude The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude The highest altitude in meters where to execute the engagement.
  -- @param DCS#AltitudeType EngageAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to "RADIO".
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  --
  --   -- GCI Squadron execution.
  --   A2ADispatcher:SetSquadronGci2( "Mozdok", 900, 1200, 5000, 5000, "BARO" )
  --   A2ADispatcher:SetSquadronGci2( "Novo", 900, 2100, 30, 30, "RADIO" )
  --   A2ADispatcher:SetSquadronGci2( "Maykop", 900, 1200, 100, 300, "RADIO" )
  --
  function AI_A2A_DISPATCHER:SetSquadronGci2( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}
    self.DefenderSquadrons[SquadronName].Gci = self.DefenderSquadrons[SquadronName].Gci or {}

    local Intercept = self.DefenderSquadrons[SquadronName].Gci
    Intercept.Name = SquadronName
    Intercept.EngageMinSpeed = EngageMinSpeed
    Intercept.EngageMaxSpeed = EngageMaxSpeed
    Intercept.EngageFloorAltitude = EngageFloorAltitude
    Intercept.EngageCeilingAltitude = EngageCeilingAltitude
    Intercept.EngageAltType = EngageAltType

    self:I( { GCI = { SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType } } )
  end

  --- Set squadron GCI.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed The minimum speed [km/h] at which the GCI can be executed.
  -- @param #number EngageMaxSpeed The maximum speed [km/h] at which the GCI can be executed.
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  --
  --   -- GCI Squadron execution.
  --   A2ADispatcher:SetSquadronGci( "Mozdok", 900, 1200 )
  --   A2ADispatcher:SetSquadronGci( "Novo", 900, 2100 )
  --   A2ADispatcher:SetSquadronGci( "Maykop", 900, 1200 )
  --
  function AI_A2A_DISPATCHER:SetSquadronGci( SquadronName, EngageMinSpeed, EngageMaxSpeed )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}
    self.DefenderSquadrons[SquadronName].Gci = self.DefenderSquadrons[SquadronName].Gci or {}

    local Intercept = self.DefenderSquadrons[SquadronName].Gci
    Intercept.Name = SquadronName
    Intercept.EngageMinSpeed = EngageMinSpeed
    Intercept.EngageMaxSpeed = EngageMaxSpeed

    self:F( { GCI = { SquadronName, EngageMinSpeed, EngageMaxSpeed } } )
  end

  --- Defines the default amount of extra planes that will take-off as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number Overhead The % of Units that dispatching command will allocate to intercept in surplus of detected amount of units.
  -- @return #AI_A2A_DISPATCHER
  -- The default overhead is 1, so equal balance. The @{#AI_A2A_DISPATCHER.SetOverhead}() method can be used to tweak the defense strength,
  -- taking into account the plane types of the squadron. For example, a MIG-31 with full long-distance A2A missiles payload, may still be less effective than a F-15C with short missiles...
  -- So in this case, one may want to use the Overhead method to allocate more defending planes as the amount of detected attacking planes.
  -- The overhead must be given as a decimal value with 1 as the neutral value, which means that Overhead values:
  --
  --   * Higher than 1, will increase the defense unit amounts.
  --   * Lower than 1, will decrease the defense unit amounts.
  --
  -- The amount of defending units is calculated by multiplying the amount of detected attacking planes as part of the detected group
  -- multiplied by the Overhead and rounded up to the smallest integer.
  --
  -- The Overhead value set for a Squadron, can be programmatically adjusted (by using this SetOverhead method), to adjust the defense overhead during mission execution.
  --
  -- See example below.
  --
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- An overhead of 1,5 with 1 planes detected, will allocate 2 planes ( 1 * 1,5 ) = 1,5 => rounded up gives 2.
  --   -- An overhead of 1,5 with 2 planes detected, will allocate 3 planes ( 2 * 1,5 ) = 3 =>  rounded up gives 3.
  --   -- An overhead of 1,5 with 3 planes detected, will allocate 5 planes ( 3 * 1,5 ) = 4,5 => rounded up gives 5 planes.
  --   -- An overhead of 1,5 with 4 planes detected, will allocate 6 planes ( 4 * 1,5 ) = 6  => rounded up gives 6 planes.
  --
  --   A2ADispatcher:SetDefaultOverhead( 1.5 )
  --
  function AI_A2A_DISPATCHER:SetDefaultOverhead( Overhead )

    self.DefenderDefault.Overhead = Overhead

    return self
  end

  --- Defines the amount of extra planes that will take-off as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Overhead The % of Units that dispatching command will allocate to intercept in surplus of detected amount of units.
  -- @return #AI_A2A_DISPATCHER self
  -- The default overhead is 1, so equal balance. The @{#AI_A2A_DISPATCHER.SetOverhead}() method can be used to tweak the defense strength,
  -- taking into account the plane types of the squadron. For example, a MIG-31 with full long-distance A2A missiles payload, may still be less effective than a F-15C with short missiles...
  -- So in this case, one may want to use the Overhead method to allocate more defending planes as the amount of detected attacking planes.
  -- The overhead must be given as a decimal value with 1 as the neutral value, which means that Overhead values:
  --
  --   * Higher than 1, will increase the defense unit amounts.
  --   * Lower than 1, will decrease the defense unit amounts.
  --
  -- The amount of defending units is calculated by multiplying the amount of detected attacking planes as part of the detected group
  -- multiplied by the Overhead and rounded up to the smallest integer.
  --
  -- The Overhead value set for a Squadron, can be programmatically adjusted (by using this SetOverhead method), to adjust the defense overhead during mission execution.
  --
  -- See example below.
  --
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- An overhead of 1,5 with 1 planes detected, will allocate 2 planes ( 1 * 1,5 ) = 1,5 => rounded up gives 2.
  --   -- An overhead of 1,5 with 2 planes detected, will allocate 3 planes ( 2 * 1,5 ) = 3 =>  rounded up gives 3.
  --   -- An overhead of 1,5 with 3 planes detected, will allocate 5 planes ( 3 * 1,5 ) = 4,5 => rounded up gives 5 planes.
  --   -- An overhead of 1,5 with 4 planes detected, will allocate 6 planes ( 4 * 1,5 ) = 6  => rounded up gives 6 planes.
  --
  --   A2ADispatcher:SetSquadronOverhead( "SquadronName", 1.5 )
  --
  function AI_A2A_DISPATCHER:SetSquadronOverhead( SquadronName, Overhead )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Overhead = Overhead

    return self
  end

  --- Sets the default grouping of new airplanes spawned.
  -- Grouping will trigger how new airplanes will be grouped if more than one airplane is spawned for defense.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number Grouping The level of grouping that will be applied of the CAP or GCI defenders.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Set a grouping by default per 2 airplanes.
  --   A2ADispatcher:SetDefaultGrouping( 2 )
  --
  function AI_A2A_DISPATCHER:SetDefaultGrouping( Grouping )

    self.DefenderDefault.Grouping = Grouping

    return self
  end

  --- Sets the grouping of new airplanes spawned.
  -- Grouping will trigger how new airplanes will be grouped if more than one airplane is spawned for defense.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Grouping The level of grouping that will be applied of the CAP or GCI defenders.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Set a grouping per 2 airplanes.
  --   A2ADispatcher:SetSquadronGrouping( "SquadronName", 2 )
  --
  function AI_A2A_DISPATCHER:SetSquadronGrouping( SquadronName, Grouping )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Grouping = Grouping

    return self
  end

  --- Defines the default method at which new flights will spawn and take-off as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights by default take-off in the air.
  --   A2ADispatcher:SetDefaultTakeoff( AI_A2A_Dispatcher.Takeoff.Air )
  --
  --   -- Let new flights by default take-off from the runway.
  --   A2ADispatcher:SetDefaultTakeoff( AI_A2A_Dispatcher.Takeoff.Runway )
  --
  --   -- Let new flights by default take-off from the airbase hot.
  --   A2ADispatcher:SetDefaultTakeoff( AI_A2A_Dispatcher.Takeoff.Hot )
  --
  --   -- Let new flights by default take-off from the airbase cold.
  --   A2ADispatcher:SetDefaultTakeoff( AI_A2A_Dispatcher.Takeoff.Cold )
  --
  function AI_A2A_DISPATCHER:SetDefaultTakeoff( Takeoff )

    self.DefenderDefault.Takeoff = Takeoff

    return self
  end

  --- Defines the method at which new flights will spawn and take-off as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights take-off in the air.
  --   A2ADispatcher:SetSquadronTakeoff( "SquadronName", AI_A2A_Dispatcher.Takeoff.Air )
  --
  --   -- Let new flights take-off from the runway.
  --   A2ADispatcher:SetSquadronTakeoff( "SquadronName", AI_A2A_Dispatcher.Takeoff.Runway )
  --
  --   -- Let new flights take-off from the airbase hot.
  --   A2ADispatcher:SetSquadronTakeoff( "SquadronName", AI_A2A_Dispatcher.Takeoff.Hot )
  --
  --   -- Let new flights take-off from the airbase cold.
  --   A2ADispatcher:SetSquadronTakeoff( "SquadronName", AI_A2A_Dispatcher.Takeoff.Cold )
  --
  function AI_A2A_DISPATCHER:SetSquadronTakeoff( SquadronName, Takeoff )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Takeoff = Takeoff

    return self
  end

  --- Gets the default method at which new flights will spawn and take-off as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights by default take-off in the air.
  --   local TakeoffMethod = A2ADispatcher:GetDefaultTakeoff()
  --   if TakeOffMethod == , AI_A2A_Dispatcher.Takeoff.InAir then
  --     ...
  --   end
  --
  function AI_A2A_DISPATCHER:GetDefaultTakeoff()

    return self.DefenderDefault.Takeoff
  end

  --- Gets the method at which new flights will spawn and take-off as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights take-off in the air.
  --   local TakeoffMethod = A2ADispatcher:GetSquadronTakeoff( "SquadronName" )
  --   if TakeOffMethod == , AI_A2A_Dispatcher.Takeoff.InAir then
  --     ...
  --   end
  --
  function AI_A2A_DISPATCHER:GetSquadronTakeoff( SquadronName )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    return DefenderSquadron.Takeoff or self.DefenderDefault.Takeoff
  end

  --- Sets flights to default take-off in the air, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights by default take-off in the air.
  --   A2ADispatcher:SetDefaultTakeoffInAir()
  --
  function AI_A2A_DISPATCHER:SetDefaultTakeoffInAir()

    self:SetDefaultTakeoff( AI_A2A_DISPATCHER.Takeoff.Air )

    return self
  end

  --- Set flashing player messages on or off
  -- @param #AI_A2A_DISPATCHER self
  -- @param #boolean onoff Set messages on (true) or off (false)
  function AI_A2A_DISPATCHER:SetSendMessages( onoff )
      self.SetSendPlayerMessages = onoff
  end

  --- Sets flights to take-off in the air, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number TakeoffAltitude (optional) The altitude in meters above the ground. If not given, the default takeoff altitude will be used.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights take-off in the air.
  --   A2ADispatcher:SetSquadronTakeoffInAir( "SquadronName" )
  --
  function AI_A2A_DISPATCHER:SetSquadronTakeoffInAir( SquadronName, TakeoffAltitude )

    self:SetSquadronTakeoff( SquadronName, AI_A2A_DISPATCHER.Takeoff.Air )

    if TakeoffAltitude then
      self:SetSquadronTakeoffInAirAltitude( SquadronName, TakeoffAltitude )
    end

    return self
  end

  --- Sets flights by default to take-off from the runway, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights by default take-off from the runway.
  --   A2ADispatcher:SetDefaultTakeoffFromRunway()
  --
  function AI_A2A_DISPATCHER:SetDefaultTakeoffFromRunway()

    self:SetDefaultTakeoff( AI_A2A_DISPATCHER.Takeoff.Runway )

    return self
  end

  --- Sets flights to take-off from the runway, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights take-off from the runway.
  --   A2ADispatcher:SetSquadronTakeoffFromRunway( "SquadronName" )
  --
  function AI_A2A_DISPATCHER:SetSquadronTakeoffFromRunway( SquadronName )

    self:SetSquadronTakeoff( SquadronName, AI_A2A_DISPATCHER.Takeoff.Runway )

    return self
  end

  --- Sets flights by default to take-off from the airbase at a hot location, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights by default take-off at a hot parking spot.
  --   A2ADispatcher:SetDefaultTakeoffFromParkingHot()
  --
  function AI_A2A_DISPATCHER:SetDefaultTakeoffFromParkingHot()

    self:SetDefaultTakeoff( AI_A2A_DISPATCHER.Takeoff.Hot )

    return self
  end

  --- Sets flights to take-off from the airbase at a hot location, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights take-off in the air.
  --   A2ADispatcher:SetSquadronTakeoffFromParkingHot( "SquadronName" )
  --
  function AI_A2A_DISPATCHER:SetSquadronTakeoffFromParkingHot( SquadronName )

    self:SetSquadronTakeoff( SquadronName, AI_A2A_DISPATCHER.Takeoff.Hot )

    return self
  end

  --- Sets flights to by default take-off from the airbase at a cold location, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights take-off from a cold parking spot.
  --   A2ADispatcher:SetDefaultTakeoffFromParkingCold()
  --
  function AI_A2A_DISPATCHER:SetDefaultTakeoffFromParkingCold()

    self:SetDefaultTakeoff( AI_A2A_DISPATCHER.Takeoff.Cold )

    return self
  end

  --- Sets flights to take-off from the airbase at a cold location, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights take-off from a cold parking spot.
  --   A2ADispatcher:SetSquadronTakeoffFromParkingCold( "SquadronName" )
  --
  function AI_A2A_DISPATCHER:SetSquadronTakeoffFromParkingCold( SquadronName )

    self:SetSquadronTakeoff( SquadronName, AI_A2A_DISPATCHER.Takeoff.Cold )

    return self
  end

  --- Defines the default altitude where airplanes will spawn in the air and take-off as part of the defense system, when the take-off in the air method has been selected.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number TakeoffAltitude The altitude in meters above the ground.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Set the default takeoff altitude when taking off in the air.
  --   A2ADispatcher:SetDefaultTakeoffInAirAltitude( 2000 )  -- This makes planes start at 2000 meters above the ground.
  --
  function AI_A2A_DISPATCHER:SetDefaultTakeoffInAirAltitude( TakeoffAltitude )

    self.DefenderDefault.TakeoffAltitude = TakeoffAltitude

    return self
  end

  --- Defines the default altitude where airplanes will spawn in the air and take-off as part of the defense system, when the take-off in the air method has been selected.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number TakeoffAltitude The altitude in meters above the ground.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Set the default takeoff altitude when taking off in the air.
  --   A2ADispatcher:SetSquadronTakeoffInAirAltitude( "SquadronName", 2000 ) -- This makes planes start at 2000 meters above the ground.
  --
  function AI_A2A_DISPATCHER:SetSquadronTakeoffInAirAltitude( SquadronName, TakeoffAltitude )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.TakeoffAltitude = TakeoffAltitude

    return self
  end

  --- Defines the default method at which flights will land and despawn as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights by default despawn near the airbase when returning.
  --   A2ADispatcher:SetDefaultLanding( AI_A2A_Dispatcher.Landing.NearAirbase )
  --
  --   -- Let new flights by default despawn after landing land at the runway.
  --   A2ADispatcher:SetDefaultLanding( AI_A2A_Dispatcher.Landing.AtRunway )
  --
  --   -- Let new flights by default despawn after landing and parking, and after engine shutdown.
  --   A2ADispatcher:SetDefaultLanding( AI_A2A_Dispatcher.Landing.AtEngineShutdown )
  --
  function AI_A2A_DISPATCHER:SetDefaultLanding( Landing )

    self.DefenderDefault.Landing = Landing

    return self
  end

  --- Defines the method at which flights will land and despawn as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights despawn near the airbase when returning.
  --   A2ADispatcher:SetSquadronLanding( "SquadronName", AI_A2A_Dispatcher.Landing.NearAirbase )
  --
  --   -- Let new flights despawn after landing land at the runway.
  --   A2ADispatcher:SetSquadronLanding( "SquadronName", AI_A2A_Dispatcher.Landing.AtRunway )
  --
  --   -- Let new flights despawn after landing and parking, and after engine shutdown.
  --   A2ADispatcher:SetSquadronLanding( "SquadronName", AI_A2A_Dispatcher.Landing.AtEngineShutdown )
  --
  function AI_A2A_DISPATCHER:SetSquadronLanding( SquadronName, Landing )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Landing = Landing

    return self
  end

  --- Gets the default method at which flights will land and despawn as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights by default despawn near the airbase when returning.
  --   local LandingMethod = A2ADispatcher:GetDefaultLanding( AI_A2A_Dispatcher.Landing.NearAirbase )
  --   if LandingMethod == AI_A2A_Dispatcher.Landing.NearAirbase then
  --    ...
  --   end
  --
  function AI_A2A_DISPATCHER:GetDefaultLanding()

    return self.DefenderDefault.Landing
  end

  --- Gets the method at which flights will land and despawn as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let new flights despawn near the airbase when returning.
  --   local LandingMethod = A2ADispatcher:GetSquadronLanding( "SquadronName", AI_A2A_Dispatcher.Landing.NearAirbase )
  --   if LandingMethod == AI_A2A_Dispatcher.Landing.NearAirbase then
  --    ...
  --   end
  --
  function AI_A2A_DISPATCHER:GetSquadronLanding( SquadronName )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    return DefenderSquadron.Landing or self.DefenderDefault.Landing
  end

  --- Sets flights by default to land and despawn near the airbase in the air, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let flights by default to land near the airbase and despawn.
  --   A2ADispatcher:SetDefaultLandingNearAirbase()
  --
  function AI_A2A_DISPATCHER:SetDefaultLandingNearAirbase()

    self:SetDefaultLanding( AI_A2A_DISPATCHER.Landing.NearAirbase )

    return self
  end

  --- Sets flights to land and despawn near the airbase in the air, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let flights to land near the airbase and despawn.
  --   A2ADispatcher:SetSquadronLandingNearAirbase( "SquadronName" )
  --
  function AI_A2A_DISPATCHER:SetSquadronLandingNearAirbase( SquadronName )

    self:SetSquadronLanding( SquadronName, AI_A2A_DISPATCHER.Landing.NearAirbase )

    return self
  end

  --- Sets flights by default to land and despawn at the runway, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let flights by default land at the runway and despawn.
  --   A2ADispatcher:SetDefaultLandingAtRunway()
  --
  function AI_A2A_DISPATCHER:SetDefaultLandingAtRunway()

    self:SetDefaultLanding( AI_A2A_DISPATCHER.Landing.AtRunway )

    return self
  end

  --- Sets flights to land and despawn at the runway, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let flights land at the runway and despawn.
  --   A2ADispatcher:SetSquadronLandingAtRunway( "SquadronName" )
  --
  function AI_A2A_DISPATCHER:SetSquadronLandingAtRunway( SquadronName )

    self:SetSquadronLanding( SquadronName, AI_A2A_DISPATCHER.Landing.AtRunway )

    return self
  end

  --- Sets flights by default to land and despawn at engine shutdown, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let flights by default land and despawn at engine shutdown.
  --   A2ADispatcher:SetDefaultLandingAtEngineShutdown()
  --
  function AI_A2A_DISPATCHER:SetDefaultLandingAtEngineShutdown()

    self:SetDefaultLanding( AI_A2A_DISPATCHER.Landing.AtEngineShutdown )

    return self
  end

  --- Sets flights to land and despawn at engine shutdown, as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage:
  --
  --   local A2ADispatcher = AI_A2A_DISPATCHER:New( ... )
  --
  --   -- Let flights land and despawn at engine shutdown.
  --   A2ADispatcher:SetSquadronLandingAtEngineShutdown( "SquadronName" )
  --
  function AI_A2A_DISPATCHER:SetSquadronLandingAtEngineShutdown( SquadronName )

    self:SetSquadronLanding( SquadronName, AI_A2A_DISPATCHER.Landing.AtEngineShutdown )

    return self
  end

  --- Set the default fuel threshold when defenders will RTB or Refuel in the air.
  -- The fuel threshold is by default set to 15%, which means that an airplane will stay in the air until 15% of its fuel has been consumed.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number FuelThreshold A decimal number between 0 and 1, that expresses the % of the threshold of fuel remaining in the tank when the plane will go RTB or Refuel.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Now Setup the default fuel threshold.
  --   A2ADispatcher:SetDefaultFuelThreshold( 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --
  function AI_A2A_DISPATCHER:SetDefaultFuelThreshold( FuelThreshold )

    self.DefenderDefault.FuelThreshold = FuelThreshold

    return self
  end

  --- Set the fuel threshold for the squadron when defenders will RTB or Refuel in the air.
  -- The fuel threshold is by default set to 15%, which means that an airplane will stay in the air until 15% of its fuel has been consumed.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number FuelThreshold A decimal number between 0 and 1, that expresses the % of the threshold of fuel remaining in the tank when the plane will go RTB or Refuel.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Now Setup the default fuel threshold.
  --   A2ADispatcher:SetSquadronFuelThreshold( "SquadronName", 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --
  function AI_A2A_DISPATCHER:SetSquadronFuelThreshold( SquadronName, FuelThreshold )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.FuelThreshold = FuelThreshold

    return self
  end

  --- Set the default tanker where defenders will Refuel in the air.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string TankerName A string defining the group name of the Tanker as defined within the Mission Editor.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Now Setup the default fuel threshold.
  --   A2ADispatcher:SetDefaultFuelThreshold( 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --
  --   -- Now Setup the default tanker.
  --   A2ADispatcher:SetDefaultTanker( "Tanker" ) -- The group name of the tanker is "Tanker" in the Mission Editor.
  --
  function AI_A2A_DISPATCHER:SetDefaultTanker( TankerName )

    self.DefenderDefault.TankerName = TankerName

    return self
  end

  --- Set the squadron tanker where defenders will Refuel in the air.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #string TankerName A string defining the group name of the Tanker as defined within the Mission Editor.
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Now Setup the squadron fuel threshold.
  --   A2ADispatcher:SetSquadronFuelThreshold( "SquadronName", 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --
  --   -- Now Setup the squadron tanker.
  --   A2ADispatcher:SetSquadronTanker( "SquadronName", "Tanker" ) -- The group name of the tanker is "Tanker" in the Mission Editor.
  --
  function AI_A2A_DISPATCHER:SetSquadronTanker( SquadronName, TankerName )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.TankerName = TankerName

    return self
  end

  --- Set the squadron language.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #string Language A string defining the language to be embedded within the miz file.
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  --
  --   -- Now Setup the A2A dispatcher, and initialize it using the Detection object.
  --   A2ADispatcher = AI_A2A_DISPATCHER:New( Detection )
  --
  --   -- Set for English.
  --   A2ADispatcher:SetSquadronLanguage( "SquadronName", "EN" ) -- This squadron speaks English.
  --
  --   -- Set for Russian.
  --   A2ADispatcher:SetSquadronLanguage( "SquadronName", "RU" ) -- This squadron speaks Russian.
  function AI_A2A_DISPATCHER:SetSquadronLanguage( SquadronName, Language )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Language = Language

    if DefenderSquadron.RadioQueue then
      DefenderSquadron.RadioQueue:SetLanguage( Language )
    end

    return self
  end

  --- Set the frequency of communication and the mode of communication for voice overs.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number RadioFrequency The frequency of communication.
  -- @param #number RadioModulation The modulation of communication.
  -- @param #number RadioPower The power in Watts of communication.
  function AI_A2A_DISPATCHER:SetSquadronRadioFrequency( SquadronName, RadioFrequency, RadioModulation, RadioPower )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.RadioFrequency = RadioFrequency
    DefenderSquadron.RadioModulation = RadioModulation or radio.modulation.AM
    DefenderSquadron.RadioPower = RadioPower or 100

    if DefenderSquadron.RadioQueue then
      DefenderSquadron.RadioQueue:Stop()
    end

    DefenderSquadron.RadioQueue = nil

    DefenderSquadron.RadioQueue = RADIOSPEECH:New( DefenderSquadron.RadioFrequency, DefenderSquadron.RadioModulation )
    DefenderSquadron.RadioQueue.power = DefenderSquadron.RadioPower
    DefenderSquadron.RadioQueue:Start( 0.5 )

    DefenderSquadron.RadioQueue:SetLanguage( DefenderSquadron.Language )
  end

  --- Add defender to squadron. Resource count will get smaller.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #AI_A2A_DISPATCHER.Squadron Squadron The squadron.
  -- @param Wrapper.Group#GROUP Defender The defender group.
  -- @param #number Size Size of the group.
  function AI_A2A_DISPATCHER:AddDefenderToSquadron( Squadron, Defender, Size )
    self.Defenders = self.Defenders or {}
    local DefenderName = Defender:GetName()
    self.Defenders[DefenderName] = Squadron
    if Squadron.ResourceCount then
      Squadron.ResourceCount = Squadron.ResourceCount - Size
    end
    self:F( { DefenderName = DefenderName, SquadronResourceCount = Squadron.ResourceCount } )
  end

  --- Remove defender from squadron. Resource count will increase.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #AI_A2A_DISPATCHER.Squadron Squadron The squadron.
  -- @param Wrapper.Group#GROUP Defender The defender group.
  function AI_A2A_DISPATCHER:RemoveDefenderFromSquadron( Squadron, Defender )
    self.Defenders = self.Defenders or {}
    local DefenderName = Defender:GetName()
    if Squadron.ResourceCount then
      Squadron.ResourceCount = Squadron.ResourceCount + Defender:GetSize()
    end
    self.Defenders[DefenderName] = nil
    self:F( { DefenderName = DefenderName, SquadronResourceCount = Squadron.ResourceCount } )
  end

  --- Get squadron from defender.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Wrapper.Group#GROUP Defender The defender group.
  -- @return #AI_A2A_DISPATCHER.Squadron Squadron The squadron.
  function AI_A2A_DISPATCHER:GetSquadronFromDefender( Defender )
    self.Defenders = self.Defenders or {}
    if Defender ~= nil then
      local DefenderName = Defender:GetName()
      self:F( { DefenderName = DefenderName } )
      return self.Defenders[DefenderName]
    else
      return nil
    end
  end

  --- Creates an SWEEP task when there are targets for it.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Core.Set#SET_UNIT TargetSetUnit: The target set of units.
  function AI_A2A_DISPATCHER:EvaluateSWEEP( DetectedItem )
    self:F( { DetectedItem.ItemID } )

    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone

    if DetectedItem.IsDetected == false then

      -- Here we're doing something advanced... We're copying the DetectedSet.
      local TargetSetUnit = SET_UNIT:New()
      TargetSetUnit:SetDatabase( DetectedSet )
      TargetSetUnit:FilterOnce() -- Filter but don't do any events!!! Elements are added manually upon each detection.

      return TargetSetUnit
    end

    return nil
  end

  --- Count number of airborne CAP flights.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName Name of the squadron.
  -- @return #number Number of defender CAP groups.
  function AI_A2A_DISPATCHER:CountCapAirborne( SquadronName )

    local CapCount = 0

    local DefenderSquadron = self.DefenderSquadrons[SquadronName]
    if DefenderSquadron then
      for AIGroup, DefenderTask in pairs( self:GetDefenderTasks() ) do
        if DefenderTask.SquadronName == SquadronName then
          if DefenderTask.Type == "CAP" then
            if AIGroup and AIGroup:IsAlive() then
              -- Check if the CAP is patrolling or engaging. If not, this is not a valid CAP, even if it is alive!
              -- The CAP could be damaged, lost control, or out of fuel!
              -- env.info("FF fsm state "..tostring(DefenderTask.Fsm:GetState()))
              if DefenderTask.Fsm:Is( "Patrolling" ) or DefenderTask.Fsm:Is( "Engaging" ) or DefenderTask.Fsm:Is( "Refuelling" ) or DefenderTask.Fsm:Is( "Started" ) then
                -- env.info("FF capcount "..CapCount)
                CapCount = CapCount + 1
              end
            end
          end
        end
      end
    end

    return CapCount
  end

  --- Count number of engaging defender groups.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detection object.
  -- @return #number Number of defender groups engaging.
  function AI_A2A_DISPATCHER:CountDefendersEngaged( AttackerDetection )

    -- First, count the active AIGroups Units, targeting the DetectedSet
    local DefenderCount = 0

    local DetectedSet = AttackerDetection.Set
    -- DetectedSet:Flush()

    local DefenderTasks = self:GetDefenderTasks()

    for DefenderGroup, DefenderTask in pairs( DefenderTasks ) do
      local Defender = DefenderGroup -- Wrapper.Group#GROUP
      local DefenderTaskTarget = DefenderTask.Target -- Functional.Detection#DETECTION_BASE.DetectedItem
      local DefenderSquadronName = DefenderTask.SquadronName

      if DefenderTaskTarget and DefenderTaskTarget.Index == AttackerDetection.Index then
        local Squadron = self:GetSquadron( DefenderSquadronName )
        local SquadronOverhead = Squadron.Overhead or self.DefenderDefault.Overhead

        local DefenderSize = Defender:GetInitialSize()
        if DefenderSize then
          DefenderCount = DefenderCount + DefenderSize / SquadronOverhead
          self:F( "Defender Group Name: " .. Defender:GetName() .. ", Size: " .. DefenderSize )
        else
          DefenderCount = 0
        end
      end
    end

    self:F( { DefenderCount = DefenderCount } )

    return DefenderCount
  end

  --- Count defenders to be engaged if number of attackers larger than number of defenders.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detected item.
  -- @param #number DefenderCount Number of defenders.
  -- @return #table Table of friendly groups.
  function AI_A2A_DISPATCHER:CountDefendersToBeEngaged( AttackerDetection, DefenderCount )

    local Friendlies = nil

    local AttackerSet = AttackerDetection.Set
    local AttackerCount = AttackerSet:Count()

    local DefenderFriendlies = self:GetAIFriendliesNearBy( AttackerDetection )

    for FriendlyDistance, AIFriendly in UTILS.spairs( DefenderFriendlies or {} ) do
      -- We only allow to ENGAGE targets as long as the Units on both sides are balanced.
      if AttackerCount > DefenderCount then
    --self:I("***** AI_A2A_DISPATCHER:CountDefendersToBeEngaged() *****\nThis is supposed to be a UNIT:")
    if AIFriendly then
      local classname = AIFriendly.ClassName or "No Class Name"
      local unitname = AIFriendly.IdentifiableName or "No Unit Name"
      --self:I("Class Name: " .. classname)
      --self:I("Unit Name: " .. unitname)
      --self:I({AIFriendly})
    end
    local Friendly = nil
    if AIFriendly and AIFriendly:IsAlive() then
      --self:I("AIFriendly alive, getting GROUP")
      Friendly = AIFriendly:GetGroup() -- Wrapper.Group#GROUP
    end
    
        if Friendly and Friendly:IsAlive() then
          -- Ok, so we have a friendly near the potential target.
          -- Now we need to check if the AIGroup has a Task.
          local DefenderTask = self:GetDefenderTask( Friendly )
          if DefenderTask then
            -- The Task should be CAP or GCI
            if DefenderTask.Type == "CAP" or DefenderTask.Type == "GCI" then
              -- If there is no target, then add the AIGroup to the ResultAIGroups for Engagement to the AttackerSet
              if DefenderTask.Target == nil then
                if DefenderTask.Fsm:Is( "Returning" ) or DefenderTask.Fsm:Is( "Patrolling" ) then
                  Friendlies = Friendlies or {}
                  Friendlies[Friendly] = Friendly
                  DefenderCount = DefenderCount + Friendly:GetSize()
                  self:F( { Friendly = Friendly:GetName(), FriendlyDistance = FriendlyDistance } )
                end
              end
            end
          end
        end
      else
        break
      end
    end

    return Friendlies
  end

  --- Activate resource.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #AI_A2A_DISPATCHER.Squadron DefenderSquadron The defender squadron.
  -- @param #number DefendersNeeded Number of defenders needed. Default 4.
  -- @return Wrapper.Group#GROUP The defender group.
  -- @return #boolean Grouping.
  function AI_A2A_DISPATCHER:ResourceActivate( DefenderSquadron, DefendersNeeded )

    local SquadronName = DefenderSquadron.Name

    DefendersNeeded = DefendersNeeded or 4

    local DefenderGrouping = DefenderSquadron.Grouping or self.DefenderDefault.Grouping

    DefenderGrouping = (DefenderGrouping < DefendersNeeded) and DefenderGrouping or DefendersNeeded

    -- env.info(string.format("FF resource activate: Squadron=%s grouping=%d needed=%d visible=%s", SquadronName, DefenderGrouping, DefendersNeeded, tostring(self:IsSquadronVisible( SquadronName ))))

    if self:IsSquadronVisible( SquadronName ) then

      local n = #self.uncontrolled[SquadronName]

      if n > 0 then
        -- Random number 1,...n
        local id = math.random( n )

        -- Pick a random defender group.
        local Defender = self.uncontrolled[SquadronName][id].group -- Wrapper.Group#GROUP

        -- Start uncontrolled group.
        Defender:StartUncontrolled()

        -- Get grouping.
        DefenderGrouping = self.uncontrolled[SquadronName][id].grouping

        -- Add defender to squadron.
        self:AddDefenderToSquadron( DefenderSquadron, Defender, DefenderGrouping )

        -- Remove defender from uncontrolled table.
        table.remove( self.uncontrolled[SquadronName], id )

        return Defender, DefenderGrouping
      else
        return nil, 0
      end

      -- Here we CAP the new planes.
      -- The Resources table is filled in advance.
      local TemplateID = math.random( 1, #DefenderSquadron.Spawn ) -- Choose the template.

      --[[
      -- We determine the grouping based on the parameters set.
      self:F( { DefenderGrouping = DefenderGrouping } )

      -- New we will form the group to spawn in.
      -- We search for the first free resource matching the template.
      local DefenderUnitIndex = 1
      local DefenderCAPTemplate = nil
      local DefenderName = nil
      for GroupName, DefenderGroup in pairs( DefenderSquadron.Resources[TemplateID] or {} ) do
        self:F( { GroupName = GroupName } )
        local DefenderTemplate = _DATABASE:GetGroupTemplate( GroupName )
        if DefenderUnitIndex == 1 then
          DefenderCAPTemplate = UTILS.DeepCopy( DefenderTemplate )
          self.DefenderCAPIndex = self.DefenderCAPIndex + 1
          DefenderCAPTemplate.name = SquadronName .. "#" .. self.DefenderCAPIndex .. "#" .. GroupName
          DefenderName = DefenderCAPTemplate.name
        else
          -- Add the unit in the template to the DefenderCAPTemplate.
          local DefenderUnitTemplate = DefenderTemplate.units[1]
          DefenderCAPTemplate.units[DefenderUnitIndex] = DefenderUnitTemplate
        end
        DefenderUnitIndex = DefenderUnitIndex + 1
        DefenderSquadron.Resources[TemplateID][GroupName] = nil
        if DefenderUnitIndex > DefenderGrouping then
          break
        end

      end

      if DefenderCAPTemplate then
        local TakeoffMethod = self:GetSquadronTakeoff( SquadronName )
        local SpawnGroup = GROUP:Register( DefenderName )
        DefenderCAPTemplate.lateActivation = nil
        DefenderCAPTemplate.uncontrolled = nil
        local Takeoff = self:GetSquadronTakeoff( SquadronName )
        DefenderCAPTemplate.route.points[1].type   = GROUPTEMPLATE.Takeoff[Takeoff][1] -- type
        DefenderCAPTemplate.route.points[1].action = GROUPTEMPLATE.Takeoff[Takeoff][2] -- action
        local Defender = _DATABASE:Spawn( DefenderCAPTemplate )

        self:AddDefenderToSquadron( DefenderSquadron, Defender, DefenderGrouping )
        return Defender, DefenderGrouping
      end
      ]]

    else

      ----------------------------
      --- Squadron not visible ---
      ----------------------------

      local Spawn = DefenderSquadron.Spawn[math.random( 1, #DefenderSquadron.Spawn )] -- Core.Spawn#SPAWN

      if DefenderGrouping then
        Spawn:InitGrouping( DefenderGrouping )
      else
        Spawn:InitGrouping()
      end

      local TakeoffMethod = self:GetSquadronTakeoff( SquadronName )

      local Defender = Spawn:SpawnAtAirbase( DefenderSquadron.Airbase, TakeoffMethod, DefenderSquadron.TakeoffAltitude or self.DefenderDefault.TakeoffAltitude ) -- Wrapper.Group#GROUP

      self:AddDefenderToSquadron( DefenderSquadron, Defender, DefenderGrouping )

      return Defender, DefenderGrouping
    end

    return nil, nil
  end

  --- On after "CAP" event.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string SquadronName Name of the squadron.
  function AI_A2A_DISPATCHER:onafterCAP( From, Event, To, SquadronName )

    self:F( { SquadronName = SquadronName } )
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {}
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}

    local DefenderSquadron = self:CanCAP( SquadronName )

    if DefenderSquadron then

      local Cap = DefenderSquadron.Cap

      if Cap then

        local DefenderCAP, DefenderGrouping = self:ResourceActivate( DefenderSquadron )

        if DefenderCAP then

          local AI_A2A_Fsm = AI_A2A_CAP:New2( DefenderCAP, Cap.EngageMinSpeed, Cap.EngageMaxSpeed, Cap.EngageFloorAltitude, Cap.EngageCeilingAltitude, Cap.EngageAltType, Cap.Zone, Cap.PatrolMinSpeed, Cap.PatrolMaxSpeed, Cap.PatrolFloorAltitude, Cap.PatrolCeilingAltitude, Cap.PatrolAltType )
          AI_A2A_Fsm:SetDispatcher( self )
          AI_A2A_Fsm:SetHomeAirbase( DefenderSquadron.Airbase )
          AI_A2A_Fsm:SetFuelThreshold( DefenderSquadron.FuelThreshold or self.DefenderDefault.FuelThreshold, 60 )
          AI_A2A_Fsm:SetDamageThreshold( self.DefenderDefault.DamageThreshold )
          AI_A2A_Fsm:SetDisengageRadius( self.DisengageRadius )
          AI_A2A_Fsm:SetTanker( DefenderSquadron.TankerName or self.DefenderDefault.TankerName )
          if DefenderSquadron.Racetrack or self.DefenderDefault.Racetrack then
            AI_A2A_Fsm:SetRaceTrackPattern( DefenderSquadron.RacetrackLengthMin or self.DefenderDefault.RacetrackLengthMin,
                                            DefenderSquadron.RacetrackLengthMax or self.DefenderDefault.RacetrackLengthMax,
                                            DefenderSquadron.RacetrackHeadingMin or self.DefenderDefault.RacetrackHeadingMin,
                                            DefenderSquadron.RacetrackHeadingMax or self.DefenderDefault.RacetrackHeadingMax,
                                            DefenderSquadron.RacetrackDurationMin or self.DefenderDefault.RacetrackDurationMin,
                                            DefenderSquadron.RacetrackDurationMax or self.DefenderDefault.RacetrackDurationMax,
                                            DefenderSquadron.RacetrackCoordinates or self.DefenderDefault.RacetrackCoordinates )
          end
          AI_A2A_Fsm:Start()

          self:SetDefenderTask( SquadronName, DefenderCAP, "CAP", AI_A2A_Fsm )

          function AI_A2A_Fsm:onafterTakeoff( DefenderGroup, From, Event, To )
            -- Issue GetCallsign() returns nil, see https://github.com/FlightControl-Master/MOOSE/issues/1228
            if DefenderGroup and DefenderGroup:IsAlive() then
              self:F( { "CAP Takeoff", DefenderGroup:GetName() } )
              -- self:GetParent(self).onafterBirth( self, Defender, From, Event, To )

              local DefenderName = DefenderGroup:GetCallsign()
              local Dispatcher = AI_A2A_Fsm:GetDispatcher() -- #AI_A2A_DISPATCHER
              local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )

              if Squadron then
                if self.SetSendPlayerMessages then
                  Dispatcher:MessageToPlayers( Squadron,  DefenderName .. " Wheels up.", DefenderGroup )
                end
                AI_A2A_Fsm:__Patrol( 2 ) -- Start Patrolling
              end
            end
          end

          function AI_A2A_Fsm:onafterPatrolRoute( DefenderGroup, From, Event, To )
            if DefenderGroup and DefenderGroup:IsAlive() then
              self:F( { "CAP PatrolRoute", DefenderGroup:GetName() } )
              self:GetParent( self ).onafterPatrolRoute( self, DefenderGroup, From, Event, To )

              local DefenderName = DefenderGroup:GetCallsign()
              local Dispatcher = self:GetDispatcher() -- #AI_A2A_DISPATCHER
              local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
              if Squadron and self.SetSendPlayerMessages then       
                  Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", patrolling.", DefenderGroup )
              end

              Dispatcher:ClearDefenderTaskTarget( DefenderGroup )
            end
          end

          function AI_A2A_Fsm:onafterRTB( DefenderGroup, From, Event, To )
            if DefenderGroup and DefenderGroup:IsAlive() then
              self:F( { "CAP RTB", DefenderGroup:GetName() } )

              self:GetParent( self ).onafterRTB( self, DefenderGroup, From, Event, To )

              local DefenderName = DefenderGroup:GetCallsign()
              local Dispatcher = self:GetDispatcher() -- #AI_A2A_DISPATCHER
              local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
              if Squadron and self.SetSendPlayerMessages then
                Dispatcher:MessageToPlayers( Squadron,  DefenderName .. " returning to base.", DefenderGroup )
              end
              Dispatcher:ClearDefenderTaskTarget( DefenderGroup )
            end
          end

          --- @param #AI_A2A_DISPATCHER self
          function AI_A2A_Fsm:onafterHome( Defender, From, Event, To, Action )
            if Defender and Defender:IsAlive() then
              self:F( { "CAP Home", Defender:GetName() } )
              self:GetParent( self ).onafterHome( self, Defender, From, Event, To )

              local Dispatcher = self:GetDispatcher() -- #AI_A2A_DISPATCHER
              local Squadron = Dispatcher:GetSquadronFromDefender( Defender )

              if Action and Action == "Destroy" then
                Dispatcher:RemoveDefenderFromSquadron( Squadron, Defender )
                Defender:Destroy()
              end

              if Dispatcher:GetSquadronLanding( Squadron.Name ) == AI_A2A_DISPATCHER.Landing.NearAirbase then
                Dispatcher:RemoveDefenderFromSquadron( Squadron, Defender )
                Defender:Destroy()
                Dispatcher:ParkDefender( Squadron )
              end
            end
          end
        end
      end
    end

  end

  --- On after "ENGAGE" event.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detected item.
  -- @param #table Defenders Defenders table.
  function AI_A2A_DISPATCHER:onafterENGAGE( From, Event, To, AttackerDetection, Defenders )
    self:F( "ENGAGING Detection ID=" .. tostring( AttackerDetection.ID ) )

    if Defenders then

      for DefenderID, Defender in pairs( Defenders ) do

        local Fsm = self:GetDefenderTaskFsm( Defender )

        Fsm:EngageRoute( AttackerDetection.Set ) -- Engage on the TargetSetUnit

        self:SetDefenderTaskTarget( Defender, AttackerDetection )

      end

    end
  end

  --- On after "GCI" event.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem AttackerDetection Detected item.
  -- @param #number DefendersMissing Number of missing defenders.
  -- @param #table DefenderFriendlies Friendly defenders.
  function AI_A2A_DISPATCHER:onafterGCI( From, Event, To, AttackerDetection, DefendersMissing, DefenderFriendlies )

    self:F( "GCI Detection ID=" .. tostring( AttackerDetection.ID ) )

    self:F( { From, Event, To, AttackerDetection.Index, DefendersMissing, DefenderFriendlies } )

    local AttackerSet = AttackerDetection.Set
    local AttackerUnit = AttackerSet:GetFirst()

    if AttackerUnit and AttackerUnit:IsAlive() then
      local AttackerCount = AttackerSet:Count()
      local DefenderCount = 0

      for DefenderID, DefenderGroup in pairs( DefenderFriendlies or {} ) do

        local Fsm = self:GetDefenderTaskFsm( DefenderGroup )
        Fsm:__EngageRoute( 0.1, AttackerSet ) -- Engage on the TargetSetUnit

        self:SetDefenderTaskTarget( DefenderGroup, AttackerDetection )

        DefenderCount = DefenderCount + DefenderGroup:GetSize()
      end

      self:F( { DefenderCount = DefenderCount, DefendersMissing = DefendersMissing } )
      DefenderCount = DefendersMissing

      local ClosestDistance = 0
      local ClosestDefenderSquadronName = nil

      local BreakLoop = false

      while (DefenderCount > 0 and not BreakLoop) do

        self:F( { DefenderSquadrons = self.DefenderSquadrons } )

        for SquadronName, DefenderSquadron in pairs( self.DefenderSquadrons or {} ) do

          self:F( { GCI = DefenderSquadron.Gci } )

          for InterceptID, Intercept in pairs( DefenderSquadron.Gci or {} ) do

            self:F( { DefenderSquadron } )
            local SpawnCoord = DefenderSquadron.Airbase:GetCoordinate() -- Core.Point#COORDINATE
            local AttackerCoord = AttackerUnit:GetCoordinate()
            local InterceptCoord = AttackerDetection.InterceptCoord
            self:F( { InterceptCoord = InterceptCoord } )
            if InterceptCoord then
              local InterceptDistance = SpawnCoord:Get2DDistance( InterceptCoord )
              local AirbaseDistance = SpawnCoord:Get2DDistance( AttackerCoord )
              self:F( { InterceptDistance = InterceptDistance, AirbaseDistance = AirbaseDistance, InterceptCoord = InterceptCoord } )

              if ClosestDistance == 0 or InterceptDistance < ClosestDistance then

                -- Only intercept if the distance to target is smaller or equal to the GciRadius limit.
                if AirbaseDistance <= self.GciRadius then
                  ClosestDistance = InterceptDistance
                  ClosestDefenderSquadronName = SquadronName
                end
              end
            end
          end
        end

        if ClosestDefenderSquadronName then

          local DefenderSquadron = self:CanGCI( ClosestDefenderSquadronName )

          if DefenderSquadron then

            local Gci = self.DefenderSquadrons[ClosestDefenderSquadronName].Gci

            if Gci then

              local DefenderOverhead = DefenderSquadron.Overhead or self.DefenderDefault.Overhead
              local DefenderGrouping = DefenderSquadron.Grouping or self.DefenderDefault.Grouping
              local DefendersNeeded = math.ceil( DefenderCount * DefenderOverhead )

              self:F( { Overhead = DefenderOverhead, SquadronOverhead = DefenderSquadron.Overhead, DefaultOverhead = self.DefenderDefault.Overhead } )
              self:F( { Grouping = DefenderGrouping, SquadronGrouping = DefenderSquadron.Grouping, DefaultGrouping = self.DefenderDefault.Grouping } )
              self:F( { DefendersCount = DefenderCount, DefendersNeeded = DefendersNeeded } )

              -- DefenderSquadron.ResourceCount can have the value nil, which expresses unlimited resources.
              -- DefendersNeeded cannot exceed DefenderSquadron.ResourceCount!
              if DefenderSquadron.ResourceCount and DefendersNeeded > DefenderSquadron.ResourceCount then
                DefendersNeeded = DefenderSquadron.ResourceCount
                BreakLoop = true
              end

              while (DefendersNeeded > 0) do

                local DefenderGCI, DefenderGrouping = self:ResourceActivate( DefenderSquadron, DefendersNeeded )

                DefendersNeeded = DefendersNeeded - DefenderGrouping

                if DefenderGCI then

                  DefenderCount = DefenderCount - DefenderGrouping / DefenderOverhead

                  local Fsm = AI_A2A_GCI:New2( DefenderGCI, Gci.EngageMinSpeed, Gci.EngageMaxSpeed, Gci.EngageFloorAltitude, Gci.EngageCeilingAltitude, Gci.EngageAltType )
                  Fsm:SetDispatcher( self )
                  Fsm:SetHomeAirbase( DefenderSquadron.Airbase )
                  Fsm:SetFuelThreshold( DefenderSquadron.FuelThreshold or self.DefenderDefault.FuelThreshold, 60 )
                  Fsm:SetDamageThreshold( self.DefenderDefault.DamageThreshold )
                  Fsm:SetDisengageRadius( self.DisengageRadius )
                  Fsm:Start()

                  self:SetDefenderTask( ClosestDefenderSquadronName, DefenderGCI, "GCI", Fsm, AttackerDetection )

                  function Fsm:onafterTakeoff( DefenderGroup, From, Event, To )
                    self:F( { "GCI Birth", DefenderGroup:GetName() } )
                    -- self:GetParent(self).onafterBirth( self, Defender, From, Event, To )

                    local DefenderName = DefenderGroup:GetCallsign()
                    local Dispatcher = Fsm:GetDispatcher() -- #AI_A2A_DISPATCHER
                    local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
                    local DefenderTarget = Dispatcher:GetDefenderTaskTarget( DefenderGroup )

                    if DefenderTarget then
                      if Squadron.Language == "EN" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. " wheels up.", DefenderGroup )
                      elseif Squadron.Language == "RU" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. " колёса вверх.", DefenderGroup )
                      end
                      -- Fsm:__Engage( 2, DefenderTarget.Set ) -- Engage on the TargetSetUnit
                      Fsm:EngageRoute( DefenderTarget.Set ) -- Engage on the TargetSetUnit
                    end
                  end

                  function Fsm:onafterEngageRoute( DefenderGroup, From, Event, To, AttackSetUnit )
                    self:F( { "GCI Route", DefenderGroup:GetName() } )

                    local DefenderName = DefenderGroup:GetCallsign()
                    local Dispatcher = Fsm:GetDispatcher() -- #AI_A2A_DISPATCHER
                    local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )

                    if Squadron and AttackSetUnit:Count() > 0 then
                      local FirstUnit = AttackSetUnit:GetFirst()
                      local Coordinate = FirstUnit:GetCoordinate() -- Core.Point#COORDINATE

                      if Squadron.Language == "EN" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", intercepting bogeys at " .. Coordinate:ToStringA2A( DefenderGroup, nil, Squadron.Language ), DefenderGroup )
                      elseif Squadron.Language == "RU" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", перехватывая боги в " .. Coordinate:ToStringA2A( DefenderGroup, nil, Squadron.Language ), DefenderGroup )
                      elseif Squadron.Language == "DE" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", Eindringlinge abfangen bei" .. Coordinate:ToStringA2A( DefenderGroup, nil, Squadron.Language ), DefenderGroup )
                      end
                    end
                    self:GetParent( Fsm ).onafterEngageRoute( self, DefenderGroup, From, Event, To, AttackSetUnit )
                  end

                  function Fsm:onafterEngage( DefenderGroup, From, Event, To, AttackSetUnit )
                    self:F( { "GCI Engage", DefenderGroup:GetName() } )

                    local DefenderName = DefenderGroup:GetCallsign()
                    local Dispatcher = Fsm:GetDispatcher() -- #AI_A2A_DISPATCHER
                    local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )

                    if Squadron and AttackSetUnit:Count() > 0 then
                      local FirstUnit = AttackSetUnit:GetFirst()
                      local Coordinate = FirstUnit:GetCoordinate() -- Core.Point#COORDINATE

                      if Squadron.Language == "EN" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", engaging bogeys at " .. Coordinate:ToStringA2A( DefenderGroup, nil, Squadron.Language ), DefenderGroup )
                      elseif Squadron.Language == "RU" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", задействуя боги в " .. Coordinate:ToStringA2A( DefenderGroup, nil, Squadron.Language ), DefenderGroup )
                      end
                    end
                    self:GetParent( Fsm ).onafterEngage( self, DefenderGroup, From, Event, To, AttackSetUnit )
                  end

                  function Fsm:onafterRTB( DefenderGroup, From, Event, To )
                    self:F( { "GCI RTB", DefenderGroup:GetName() } )
                    self:GetParent( self ).onafterRTB( self, DefenderGroup, From, Event, To )

                    local DefenderName = DefenderGroup:GetCallsign()
                    local Dispatcher = self:GetDispatcher() -- #AI_A2A_DISPATCHER
                    local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )

                    if Squadron then
                      if Squadron.Language == "EN" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. " returning to base.", DefenderGroup )
                      elseif Squadron.Language == "RU" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", возвращение на базу.", DefenderGroup )
                      end
                    end
                    Dispatcher:ClearDefenderTaskTarget( DefenderGroup )
                  end

                  --- @param #AI_A2A_DISPATCHER self
                  function Fsm:onafterLostControl( Defender, From, Event, To )
                    self:F( { "GCI LostControl", Defender:GetName() } )
                    self:GetParent( self ).onafterHome( self, Defender, From, Event, To )

                    local Dispatcher = Fsm:GetDispatcher() -- #AI_A2A_DISPATCHER
                    local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
                    if Defender:IsAboveRunway() then
                      Dispatcher:RemoveDefenderFromSquadron( Squadron, Defender )
                      Defender:Destroy()
                    end
                  end

                  --- @param #AI_A2A_DISPATCHER self
                  function Fsm:onafterHome( DefenderGroup, From, Event, To, Action )
                    self:F( { "GCI Home", DefenderGroup:GetName() } )
                    self:GetParent( self ).onafterHome( self, DefenderGroup, From, Event, To )

                    local DefenderName = DefenderGroup:GetCallsign()
                    local Dispatcher = self:GetDispatcher() -- #AI_A2A_DISPATCHER
                    local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )

                      if Squadron.Language == "EN" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. " landing at base.", DefenderGroup )
                      elseif Squadron.Language == "RU" and self.SetSendPlayerMessages then
                        Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", посадка на базу.", DefenderGroup )
                      end

                    if Action and Action == "Destroy" then
                      Dispatcher:RemoveDefenderFromSquadron( Squadron, DefenderGroup )
                      DefenderGroup:Destroy()
                    end

                    if Dispatcher:GetSquadronLanding( Squadron.Name ) == AI_A2A_DISPATCHER.Landing.NearAirbase then
                      Dispatcher:RemoveDefenderFromSquadron( Squadron, DefenderGroup )
                      DefenderGroup:Destroy()
                      Dispatcher:ParkDefender( Squadron )
                    end
                  end

                end -- if DefenderGCI then
              end -- while ( DefendersNeeded > 0 ) do
            end
          else
            -- No more resources, try something else.
            -- Subject for a later enhancement to try to depart from another squadron and disable this one.
            BreakLoop = true
            break
          end
        else
          -- There isn't any closest airbase anymore, break the loop.
          break
        end
      end -- if DefenderSquadron then
    end -- if AttackerUnit
  end

  --- Creates an ENGAGE task when there are human friendlies airborne near the targets.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.
  -- @return Core.Set#SET_UNIT TargetSetUnit: The target set of units or nil.
  function AI_A2A_DISPATCHER:EvaluateENGAGE( DetectedItem )
    self:F( { DetectedItem.ItemID } )

    -- First, count the active AIGroups Units, targeting the DetectedSet
    local DefenderCount = self:CountDefendersEngaged( DetectedItem )
    local DefenderGroups = self:CountDefendersToBeEngaged( DetectedItem, DefenderCount )

    self:F( { DefenderCount = DefenderCount } )

    -- Only allow ENGAGE when:
    -- 1. There are friendly units near the detected attackers.
    -- 2. There is sufficient fuel
    -- 3. There is sufficient ammo
    -- 4. The plane is not damaged
    if DefenderGroups and DetectedItem.IsDetected == true then
      return DefenderGroups
    end

    return nil
  end

  --- Creates an GCI task when there are targets for it.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.
  -- @return Core.Set#SET_UNIT TargetSetUnit: The target set of units or nil if there are no targets to be set.
  -- @return #table Table of friendly groups.
  function AI_A2A_DISPATCHER:EvaluateGCI( DetectedItem )
    self:F( { DetectedItem.ItemID } )

    local AttackerSet = DetectedItem.Set
    local AttackerCount = AttackerSet:Count()

    -- First, count the active AIGroups Units, targeting the DetectedSet
    local DefenderCount = self:CountDefendersEngaged( DetectedItem )
    local DefendersMissing = AttackerCount - DefenderCount
    self:F( { AttackerCount = AttackerCount, DefenderCount = DefenderCount, DefendersMissing = DefendersMissing } )

    local Friendlies = self:CountDefendersToBeEngaged( DetectedItem, DefenderCount )

    if DetectedItem.IsDetected == true then

      return DefendersMissing, Friendlies
    end

    return nil, nil
  end

  --- Assigns A2G AI Tasks in relation to the detected items.
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:Order( DetectedItem )

    local detection = self.Detection -- Functional.Detection#DETECTION_AREAS

    local ShortestDistance = 999999999

    -- Get coordinate (or nil).
    local AttackCoordinate = detection:GetDetectedItemCoordinate( DetectedItem )

    -- Issue https://github.com/FlightControl-Master/MOOSE/issues/1232
    if AttackCoordinate then

      for DefenderSquadronName, DefenderSquadron in pairs( self.DefenderSquadrons ) do

        self:T( { DefenderSquadron = DefenderSquadron.Name } )

        local Airbase = DefenderSquadron.Airbase
        local AirbaseCoordinate = Airbase:GetCoordinate()

        local EvaluateDistance = AttackCoordinate:Get2DDistance( AirbaseCoordinate )

        if EvaluateDistance <= ShortestDistance then
          ShortestDistance = EvaluateDistance
        end
      end

    end

    return ShortestDistance
  end

  --- Shows the tactical display.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Functional.Detection#DETECTION_BASE} derived object.
  function AI_A2A_DISPATCHER:ShowTacticalDisplay( Detection )

    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}

    local TaskReport = REPORT:New()

    local Report = REPORT:New( "Tactical Overview:" )

    local DefenderGroupCount = 0

    -- Now that all obsolete tasks are removed, loop through the detected targets.
    -- for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
    for DetectedItemID, DetectedItem in UTILS.spairs( Detection:GetDetectedItems(), function( t, a, b )
      return self:Order( t[a] ) < self:Order( t[b] )
    end ) do

      local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
      local DetectedCount = DetectedSet:Count()
      local DetectedZone = DetectedItem.Zone

      self:F( { "Target ID", DetectedItem.ItemID } )
      DetectedSet:Flush( self )

      local DetectedID = DetectedItem.ID
      local DetectionIndex = DetectedItem.Index
      local DetectedItemChanged = DetectedItem.Changed

      -- Show tactical situation
      Report:Add( string.format( "\n- Target %s (%s): (#%d) %s", DetectedItem.ItemID, DetectedItem.Index, DetectedItem.Set:Count(), DetectedItem.Set:GetObjectNames() ) )
      for Defender, DefenderTask in pairs( self:GetDefenderTasks() ) do
        local Defender = Defender -- Wrapper.Group#GROUP
        if DefenderTask.Target and DefenderTask.Target.Index == DetectedItem.Index then
          if Defender and Defender:IsAlive() then
            DefenderGroupCount = DefenderGroupCount + 1
            local Fuel = Defender:GetFuelMin() * 100
            local Damage = Defender:GetLife() / Defender:GetLife0() * 100
            Report:Add( string.format( " - %s*%d/%d (%s - %s): (#%d) F: %3d, D:%3d - %s",
                                       Defender:GetName(),
                                       Defender:GetSize(),
                                       Defender:GetInitialSize(),
                                       DefenderTask.Type,
                                       DefenderTask.Fsm:GetState(),
                                       Defender:GetSize(),
                                       Fuel,
                                       Damage,
                                       Defender:HasTask() == true and "Executing" or "Idle" ) )
          end
        end
      end
    end

    Report:Add( "\n- No Targets:" )
    local TaskCount = 0
    for Defender, DefenderTask in pairs( self:GetDefenderTasks() ) do
      TaskCount = TaskCount + 1
      local Defender = Defender -- Wrapper.Group#GROUP
      if not DefenderTask.Target then
        if Defender:IsAlive() then
          local DefenderHasTask = Defender:HasTask()
          local Fuel = Defender:GetFuelMin() * 100
          local Damage = Defender:GetLife() / Defender:GetLife0() * 100
          DefenderGroupCount = DefenderGroupCount + 1
          Report:Add( string.format( " - %s*%d/%d (%s - %s): (#%d) F: %3d, D:%3d - %s",
                                     Defender:GetName(),
                                     Defender:GetSize(),
                                     Defender:GetInitialSize(),
                                     DefenderTask.Type,
                                     DefenderTask.Fsm:GetState(),
                                     Defender:GetSize(),
                                     Fuel,
                                     Damage,
                                     Defender:HasTask() == true and "Executing" or "Idle" ) )
        end
      end
    end
    Report:Add( string.format( "\n- %d Tasks - %d Defender Groups", TaskCount, DefenderGroupCount ) )

    self:F( Report:Text( "\n" ) )
    trigger.action.outText( Report:Text( "\n" ), 25 )

    return true

  end

  --- Assigns A2A AI Tasks in relation to the detected items.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Functional.Detection#DETECTION_BASE} derived object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function AI_A2A_DISPATCHER:ProcessDetected( Detection )

    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}

    local TaskReport = REPORT:New()

    for AIGroup, DefenderTask in pairs( self:GetDefenderTasks() ) do
      local AIGroup = AIGroup -- Wrapper.Group#GROUP
      if not AIGroup:IsAlive() then
        local DefenderTaskFsm = self:GetDefenderTaskFsm( AIGroup )
        self:F( { Defender = AIGroup:GetName(), DefenderState = DefenderTaskFsm:GetState() } )
        if not DefenderTaskFsm:Is( "Started" ) then
          self:ClearDefenderTask( AIGroup )
        end
      else
        if DefenderTask.Target then
          local AttackerItem = Detection:GetDetectedItemByIndex( DefenderTask.Target.Index )
          if not AttackerItem then
            self:F( { "Removing obsolete Target:", DefenderTask.Target.Index } )
            self:ClearDefenderTaskTarget( AIGroup )
          else
            if DefenderTask.Target.Set then
              local AttackerCount = DefenderTask.Target.Set:Count()
              if AttackerCount == 0 then
                self:F( { "All Targets destroyed in Target, removing:", DefenderTask.Target.Index } )
                self:ClearDefenderTaskTarget( AIGroup )
              end
            end
          end
        end
      end
    end

    local Report = REPORT:New( "Tactical Overviews" )

    local DefenderGroupCount = 0

    -- Now that all obsolete tasks are removed, loop through the detected targets.
    -- Closest detected targets to be considered first!
    -- for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
    for DetectedItemID, DetectedItem in UTILS.spairs( Detection:GetDetectedItems(), function( t, a, b )
      return self:Order( t[a] ) < self:Order( t[b] )
    end ) do

      local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
      local DetectedCount = DetectedSet:Count()
      local DetectedZone = DetectedItem.Zone

      self:F( { "Target ID", DetectedItem.ItemID } )
      DetectedSet:Flush( self )

      local DetectedID = DetectedItem.ID
      local DetectionIndex = DetectedItem.Index
      local DetectedItemChanged = DetectedItem.Changed

      do
        local Friendlies = self:EvaluateENGAGE( DetectedItem ) -- Returns a SetUnit if there are targets to be GCIed...
        if Friendlies then
          self:F( { AIGroups = Friendlies } )
          self:ENGAGE( DetectedItem, Friendlies )
        end
      end

      do
        local DefendersMissing, Friendlies = self:EvaluateGCI( DetectedItem )
        if DefendersMissing and DefendersMissing > 0 then
          self:F( { DefendersMissing = DefendersMissing } )
          self:GCI( DetectedItem, DefendersMissing, Friendlies )
        end
      end
    end

    if self.TacticalDisplay then
      self:ShowTacticalDisplay( Detection )
    end

    return true
  end

end

do

  --- Calculates which HUMAN friendlies are nearby the area.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.
  -- @return #number, Core.Report#REPORT The amount of friendlies and a text string explaining which friendlies of which type.
  function AI_A2A_DISPATCHER:GetPlayerFriendliesNearBy( DetectedItem )

    local DetectedSet = DetectedItem.Set
    local PlayersNearBy = self.Detection:GetPlayersNearBy( DetectedItem )

    local PlayerTypes = {}
    local PlayersCount = 0

    if PlayersNearBy then
      local DetectedTreatLevel = DetectedSet:CalculateThreatLevelA2G()
      for PlayerUnitName, PlayerUnitData in pairs( PlayersNearBy ) do
        local PlayerUnit = PlayerUnitData -- Wrapper.Unit#UNIT
        local PlayerName = PlayerUnit:GetPlayerName()
        -- self:F( { PlayerName = PlayerName, PlayerUnit = PlayerUnit } )
        if PlayerUnit:IsAirPlane() and PlayerName ~= nil then
          local FriendlyUnitThreatLevel = PlayerUnit:GetThreatLevel()
          PlayersCount = PlayersCount + 1
          local PlayerType = PlayerUnit:GetTypeName()
          PlayerTypes[PlayerName] = PlayerType
          if DetectedTreatLevel < FriendlyUnitThreatLevel + 2 then
          end
        end
      end

    end

    -- self:F( { PlayersCount = PlayersCount } )

    local PlayerTypesReport = REPORT:New()

    if PlayersCount > 0 then
      for PlayerName, PlayerType in pairs( PlayerTypes ) do
        PlayerTypesReport:Add( string.format( '"%s" in %s', PlayerName, PlayerType ) )
      end
    else
      PlayerTypesReport:Add( "-" )
    end

    return PlayersCount, PlayerTypesReport
  end

  --- Calculates which friendlies are nearby the area.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.
  -- @return #number, Core.Report#REPORT The amount of friendlies and a text string explaining which friendlies of which type.
  function AI_A2A_DISPATCHER:GetFriendliesNearBy( DetectedItem )

    local DetectedSet = DetectedItem.Set
    local FriendlyUnitsNearBy = self.Detection:GetFriendliesNearBy( DetectedItem )

    local FriendlyTypes = {}
    local FriendliesCount = 0

    if FriendlyUnitsNearBy then
      local DetectedTreatLevel = DetectedSet:CalculateThreatLevelA2G()
      for FriendlyUnitName, FriendlyUnitData in pairs( FriendlyUnitsNearBy ) do
        local FriendlyUnit = FriendlyUnitData -- Wrapper.Unit#UNIT
        if FriendlyUnit:IsAirPlane() then
          local FriendlyUnitThreatLevel = FriendlyUnit:GetThreatLevel()
          FriendliesCount = FriendliesCount + 1
          local FriendlyType = FriendlyUnit:GetTypeName()
          FriendlyTypes[FriendlyType] = FriendlyTypes[FriendlyType] and (FriendlyTypes[FriendlyType] + 1) or 1
          if DetectedTreatLevel < FriendlyUnitThreatLevel + 2 then
          end
        end
      end

    end

    -- self:F( { FriendliesCount = FriendliesCount } )

    local FriendlyTypesReport = REPORT:New()

    if FriendliesCount > 0 then
      for FriendlyType, FriendlyTypeCount in pairs( FriendlyTypes ) do
        FriendlyTypesReport:Add( string.format( "%d of %s", FriendlyTypeCount, FriendlyType ) )
      end
    else
      FriendlyTypesReport:Add( "-" )
    end

    return FriendliesCount, FriendlyTypesReport
  end

  --- Schedules a new CAP for the given SquadronName.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  function AI_A2A_DISPATCHER:SchedulerCAP( SquadronName )
    self:CAP( SquadronName )
  end
  
  --- Add resources to a Squadron
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string Squadron The squadron name.
  -- @param #number Amount Number of resources to add.
  function AI_A2A_DISPATCHER:AddToSquadron(Squadron,Amount)
    local Squadron = self:GetSquadron(Squadron)
    if Squadron.ResourceCount then
      Squadron.ResourceCount = Squadron.ResourceCount + Amount
    end
    self:T({Squadron = Squadron.Name,SquadronResourceCount = Squadron.ResourceCount})
  end
  
  --- Remove resources from a Squadron
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string Squadron The squadron name.
  -- @param #number Amount Number of resources to remove.
  function AI_A2A_DISPATCHER:RemoveFromSquadron(Squadron,Amount)
    local Squadron = self:GetSquadron(Squadron)
    if Squadron.ResourceCount then
      Squadron.ResourceCount = Squadron.ResourceCount - Amount
    end
    self:T({Squadron = Squadron.Name,SquadronResourceCount = Squadron.ResourceCount})
  end

end

do

  --- @type AI_A2A_GCICAP
  -- @extends #AI_A2A_DISPATCHER

  --- Create an automatic air defence system for a coalition setting up GCI and CAP air defenses.
  -- The class derives from @{#AI_A2A_DISPATCHER} and thus, all the methods that are defined in the @{#AI_A2A_DISPATCHER} class, can be used also in AI\_A2A\_GCICAP.
  --
  -- ===
  --
  -- # Demo Missions
  --
  -- ### [Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/AID%20-%20AI%20Dispatching/AID-A2A%20-%20AI%20A2A%20Dispatching)
  --
  -- ===
  --
  -- # YouTube Channel
  --
  -- ### [DCS WORLD - MOOSE - A2A GCICAP - Build an automatic A2A Defense System](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl0S4KMNUUJpaUs6zZHjLKNx)
  --
  -- ===
  --
  -- ![Banner Image](..\Presentations\AI_A2A_DISPATCHER\Dia3.JPG)
  --
  -- AI\_A2A\_GCICAP includes automatic spawning of Combat Air Patrol aircraft (CAP) and Ground Controlled Intercept aircraft (GCI) in response to enemy
  -- air movements that are detected by an airborne or ground based radar network.
  --
  -- With a little time and with a little work it provides the mission designer with a convincing and completely automatic air defence system.
  --
  -- The AI_A2A_GCICAP provides a lightweight configuration method using the mission editor. Within a very short time, and with very little coding,
  -- the mission designer is able to configure a complete A2A defense system for a coalition using the DCS Mission Editor available functions.
  -- Using the DCS Mission Editor, you define borders of the coalition which are guarded by GCICAP,
  -- configure airbases to belong to the coalition, define squadrons flying certain types of planes or payloads per airbase, and define CAP zones.
  -- **Very little lua needs to be applied, a one liner**, which is fully explained below, which can be embedded
  -- right in a DO SCRIPT trigger action or in a larger DO SCRIPT FILE trigger action.
  --
  -- CAP flights will take off and proceed to designated CAP zones where they will remain on station until the ground radars direct them to intercept
  -- detected enemy aircraft or they run short of fuel and must return to base (RTB).
  --
  -- When a CAP flight leaves their zone to perform a GCI or return to base a new CAP flight will spawn to take its place.
  -- If all CAP flights are engaged or RTB then additional GCI interceptors will scramble to intercept unengaged enemy aircraft under ground radar control.
  --
  -- In short it is a plug in very flexible and configurable air defence module for DCS World.
  --
  -- ===
  --
  -- # The following actions need to be followed when using AI\_A2A\_GCICAP in your mission:
  --
  -- ## 1) Configure a working AI\_A2A\_GCICAP defense system for ONE coalition.
  --
  -- ### 1.1) Define which airbases are for which coalition.
  --
  -- ![Mission Editor Action](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_GCICAP-ME_1.JPG)
  --
  -- Color the airbases red or blue. You can do this by selecting the airbase on the map, and select the coalition blue or red.
  --
  -- ### 1.2) Place groups of units given a name starting with a **EWR prefix** of your choice to build your EWR network.
  --
  -- ![Mission Editor Action](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_GCICAP-ME_2.JPG)
  --
  -- **All EWR groups starting with the EWR prefix (text) will be included in the detection system.**
  --
  -- An EWR network, or, Early Warning Radar network, is used to early detect potential airborne targets and to understand the position of patrolling targets of the enemy.
  -- Typically EWR networks are setup using 55G6 EWR, 1L13 EWR, Hawk sr and Patriot str ground based radar units.
  -- These radars have different ranges and 55G6 EWR and 1L13 EWR radars are Eastern Bloc units (eg Russia, Ukraine, Georgia) while the Hawk and Patriot radars are Western (eg US).
  -- Additionally, ANY other radar capable unit can be part of the EWR network!
  -- Also AWACS airborne units, planes, helicopters can help to detect targets, as long as they have radar.
  -- The position of these units is very important as they need to provide enough coverage
  -- to pick up enemy aircraft as they approach so that CAP and GCI flights can be tasked to intercept them.
  --
  -- Additionally in a hot war situation where the border is no longer respected the placement of radars has a big effect on how fast the war escalates.
  -- For example if they are a long way forward and can detect enemy planes on the ground and taking off
  -- they will start to vector CAP and GCI flights to attack them straight away which will immediately draw a response from the other coalition.
  -- Having the radars further back will mean a slower escalation because fewer targets will be detected and
  -- therefore less CAP and GCI flights will spawn and this will tend to make just the border area active rather than a melee over the whole map.
  -- It all depends on what the desired effect is.
  --
  -- EWR networks are **dynamically maintained**. By defining in a **smart way the names or name prefixes of the groups** with EWR capable units, these groups will be **automatically added or deleted** from the EWR network,
  -- increasing or decreasing the radar coverage of the Early Warning System.
  --
  -- ### 1.3) Place Airplane or Helicopter Groups with late activation switched on above the airbases to define Squadrons.
  --
  -- ![Mission Editor Action](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_GCICAP-ME_3.JPG)
  --
  -- These are **templates**, with a given name starting with a **Template prefix** above each airbase that you wanna have a squadron.
  -- These **templates** need to be within 1.5km from the airbase center. They don't need to have a slot at the airplane, they can just be positioned above the airbase,
  -- without a route, and should only have ONE unit.
  --
  -- ![Mission Editor Action](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_GCICAP-ME_4.JPG)
  --
  -- **All airplane or helicopter groups that are starting with any of the chosen Template Prefixes will result in a squadron created at the airbase.**
  --
  -- ### 1.4) Place floating helicopters to create the CAP zones defined by its route points.
  --
  -- ![Mission Editor Action](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_GCICAP-ME_5.JPG)
  --
  -- **All airplane or helicopter groups that are starting with any of the chosen Template Prefixes will result in a squadron created at the airbase.**
  --
  -- The helicopter indicates the start of the CAP zone.
  -- The route points define the form of the CAP zone polygon.
  --
  -- ![Mission Editor Action](..\Presentations\AI_A2A_DISPATCHER\AI_A2A_GCICAP-ME_6.JPG)
  --
  -- **The place of the helicopter is important, as the airbase closest to the helicopter will be the airbase from where the CAP planes will take off for CAP.**
  --
  -- ## 2) There are a lot of defaults set, which can be further modified using the methods in @{#AI_A2A_DISPATCHER}:
  --
  -- ### 2.1) Planes are taking off in the air from the airbases.
  --
  -- This prevents airbases to get cluttered with airplanes taking off, it also reduces the risk of human players colliding with taxiing airplanes,
  -- resulting in the airbase to halt operations.
  --
  -- You can change the way how planes take off by using the inherited methods from AI\_A2A\_DISPATCHER:
  --
  --   * @{#AI_A2A_DISPATCHER.SetSquadronTakeoff}() is the generic configuration method to control takeoff from the air, hot, cold or from the runway. See the method for further details.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronTakeoffInAir}() will spawn new aircraft from the squadron directly in the air.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronTakeoffFromParkingCold}() will spawn new aircraft in without running engines at a parking spot at the airfield.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronTakeoffFromParkingHot}() will spawn new aircraft in with running engines at a parking spot at the airfield.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronTakeoffFromRunway}() will spawn new aircraft at the runway at the airfield.
  --
  -- Use these methods to fine-tune for specific airfields that are known to create bottlenecks, or have reduced airbase efficiency.
  -- The more and the longer aircraft need to taxi at an airfield, the more risk there is that:
  --
  --   * aircraft will stop waiting for each other or for a landing aircraft before takeoff.
  --   * aircraft may get into a "dead-lock" situation, where two aircraft are blocking each other.
  --   * aircraft may collide at the airbase.
  --   * aircraft may be awaiting the landing of a plane currently in the air, but never lands ...
  --
  -- Currently within the DCS engine, the airfield traffic coordination is erroneous and contains a lot of bugs.
  -- If you experience while testing problems with aircraft take-off or landing, please use one of the above methods as a solution to workaround these issues!
  --
  -- ### 2.2) Planes return near the airbase or will land if damaged.
  --
  -- When damaged airplanes return to the airbase, they will be routed and will disappear in the air when they are near the airbase.
  -- There are exceptions to this rule, airplanes that aren't "listening" anymore due to damage or out of fuel, will return to the airbase and land.
  --
  -- You can change the way how planes land by using the inherited methods from AI\_A2A\_DISPATCHER:
  --
  --   * @{#AI_A2A_DISPATCHER.SetSquadronLanding}() is the generic configuration method to control landing, namely despawn the aircraft near the airfield in the air, right after landing, or at engine shutdown.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronLandingNearAirbase}() will despawn the returning aircraft in the air when near the airfield.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronLandingAtRunway}() will despawn the returning aircraft directly after landing at the runway.
  --   * @{#AI_A2A_DISPATCHER.SetSquadronLandingAtEngineShutdown}() will despawn the returning aircraft when the aircraft has returned to its parking spot and has turned off its engines.
  --
  -- You can use these methods to minimize the airbase coordination overhead and to increase the airbase efficiency.
  -- When there are lots of aircraft returning for landing, at the same airbase, the takeoff process will be halted, which can cause a complete failure of the
  -- A2A defense system, as no new CAP or GCI planes can takeoff.
  -- Note that the method @{#AI_A2A_DISPATCHER.SetSquadronLandingNearAirbase}() will only work for returning aircraft, not for damaged or out of fuel aircraft.
  -- Damaged or out-of-fuel aircraft are returning to the nearest friendly airbase and will land, and are out of control from ground control.
  --
  -- ### 2.3) CAP operations setup for specific airbases, will be executed with the following parameters:
  --
  --   * The altitude will range between 6000 and 10000 meters.
  --   * The CAP speed will vary between 500 and 800 km/h.
  --   * The engage speed between 800 and 1200 km/h.
  --
  -- You can change or add a CAP zone by using the inherited methods from AI\_A2A\_DISPATCHER:
  --
  -- The method @{#AI_A2A_DISPATCHER.SetSquadronCap}() defines a CAP execution for a squadron.
  --
  -- Setting-up a CAP zone also requires specific parameters:
  --
  --   * The minimum and maximum altitude
  --   * The minimum speed and maximum patrol speed
  --   * The minimum and maximum engage speed
  --   * The type of altitude measurement
  --
  -- These define how the squadron will perform the CAP while patrolling. Different terrain types requires different types of CAP.
  --
  -- The @{#AI_A2A_DISPATCHER.SetSquadronCapInterval}() method specifies **how much** and **when** CAP flights will takeoff.
  --
  -- It is recommended not to overload the air defense with CAP flights, as these will decrease the performance of the overall system.
  --
  -- For example, the following setup will create a CAP for squadron "Sochi":
  --
  --    A2ADispatcher:SetSquadronCap( "Sochi", CAPZoneWest, 4000, 8000, 600, 800, 800, 1200, "BARO" )
  --    A2ADispatcher:SetSquadronCapInterval( "Sochi", 2, 30, 120, 1 )
  --
  -- ### 2.4) Each airbase will perform GCI when required, with the following parameters:
  --
  --   * The engage speed is between 800 and 1200 km/h.
  --
  -- You can change or add a GCI parameters by using the inherited methods from AI\_A2A\_DISPATCHER:
  --
  -- The method @{#AI_A2A_DISPATCHER.SetSquadronGci}() defines a GCI execution for a squadron.
  --
  -- Setting-up a GCI readiness also requires specific parameters:
  --
  --   * The minimum speed and maximum patrol speed
  --
  -- Essentially this controls how many flights of GCI aircraft can be active at any time.
  -- Note allowing large numbers of active GCI flights can adversely impact mission performance on low or medium specification hosts/servers.
  -- GCI needs to be setup at strategic airbases. Too far will mean that the aircraft need to fly a long way to reach the intruders,
  -- too short will mean that the intruders may have already passed the ideal interception point!
  --
  -- For example, the following setup will create a GCI for squadron "Sochi":
  --
  --    A2ADispatcher:SetSquadronGci( "Mozdok", 900, 1200 )
  --
  -- ### 2.5) Grouping or detected targets.
  --
  -- Detected targets are constantly re-grouped, that is, when certain detected aircraft are moving further than the group radius, then these aircraft will become a separate
  -- group being detected.
  --
  -- Targets will be grouped within a radius of 30km by default.
  --
  -- The radius indicates that detected targets need to be grouped within a radius of 30km.
  -- The grouping radius should not be too small, but also depends on the types of planes and the era of the simulation.
  -- Fast planes like in the 80s, need a larger radius than WWII planes.
  -- Typically I suggest to use 30000 for new generation planes and 10000 for older era aircraft.
  --
  -- ## 3) Additional notes:
  --
  -- In order to create a two way A2A defense system, **two AI\_A2A\_GCICAP defense systems must need to be created**, for each coalition one.
  -- Each defense system needs its own EWR network setup, airplane templates and CAP configurations.
  --
  -- This is a good implementation, because maybe in the future, more coalitions may become available in DCS world.
  --
  -- ## 4) Coding examples how to use the AI\_A2A\_GCICAP class:
  --
  -- ### 4.1) An easy setup:
  --
  --      -- Setup the AI_A2A_GCICAP dispatcher for one coalition, and initialize it.
  --      GCI_Red = AI_A2A_GCICAP:New( "EWR CCCP", "SQUADRON CCCP", "CAP CCCP", 2 )
  --   --
  -- The following parameters were given to the :New method of AI_A2A_GCICAP, and mean the following:
  --
  --    * `"EWR CCCP"`: Groups of the blue coalition are placed that define the EWR network. These groups start with the name `EWR CCCP`.
  --    * `"SQUADRON CCCP"`: Late activated Groups objects of the red coalition are placed above the relevant airbases that will contain these templates in the squadron.
  --      These late activated Groups start with the name `SQUADRON CCCP`. Each Group object contains only one Unit, and defines the weapon payload, skin and skill level.
  --    * `"CAP CCCP"`: CAP Zones are defined using floating, late activated Helicopter Group objects, where the route points define the route of the polygon of the CAP Zone.
  --      These Helicopter Group objects start with the name `CAP CCCP`, and will be the locations wherein CAP will be performed.
  --    * `2` Defines how many CAP airplanes are patrolling in each CAP zone defined simultaneously.
  --
  -- ### 4.2) A more advanced setup:
  --
  --      -- Setup the AI_A2A_GCICAP dispatcher for the blue coalition.
  --
  --      A2A_GCICAP_Blue = AI_A2A_GCICAP:New( { "BLUE EWR" }, { "104th", "105th", "106th" }, { "104th CAP" }, 4 )
  --
  -- The following parameters for the :New method have the following meaning:
  --
  --    * `{ "BLUE EWR" }`: An array of the group name prefixes of the groups of the blue coalition are placed that define the EWR network. These groups start with the name `BLUE EWR`.
  --    * `{ "104th", "105th", "106th" } `: An array of the group name prefixes of the Late activated Groups objects of the blue coalition are
  --      placed above the relevant airbases that will contain these templates in the squadron.
  --      These late activated Groups start with the name `104th` or `105th` or `106th`.
  --    * `{ "104th CAP" }`: An array of the names of the CAP zones are defined using floating, late activated helicopter group objects,
  --      where the route points define the route of the polygon of the CAP Zone.
  --      These Helicopter Group objects start with the name `104th CAP`, and will be the locations wherein CAP will be performed.
  --    * `4` Defines how many CAP airplanes are patrolling in each CAP zone defined simultaneously.
  --
  -- @field #AI_A2A_GCICAP
  AI_A2A_GCICAP = {
    ClassName = "AI_A2A_GCICAP",
    Detection = nil,
  }

  --- AI_A2A_GCICAP constructor.
  -- @param #AI_A2A_GCICAP self
  -- @param #string EWRPrefixes A list of prefixes that of groups that setup the Early Warning Radar network.
  -- @param #string TemplatePrefixes A list of template prefixes.
  -- @param #string CapPrefixes A list of CAP zone prefixes (polygon zones).
  -- @param #number CapLimit A number of how many CAP maximum will be spawned.
  -- @param #number GroupingRadius The radius in meters wherein detected planes are being grouped as one target area.
  -- For airplanes, 6000 (6km) is recommended, and is also the default value of this parameter.
  -- @param #number EngageRadius The radius in meters wherein detected airplanes will be engaged by airborne defenders without a task.
  -- @param #number GciRadius The radius in meters wherein detected airplanes will GCI.
  -- @param #number ResourceCount The amount of resources that will be allocated to each squadron.
  -- @return #AI_A2A_GCICAP
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object. Each squadron has unlimited resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The CAP Zone prefix is "CAP Zone".
  --   -- The CAP Limit is 2.
  --   A2ADispatcher = AI_A2A_GCICAP:New( { "DF CCCP" }, { "SQ CCCP" }, { "CAP Zone" }, 2 )
  --
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object. Each squadron has unlimited resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The CAP Zone prefix is "CAP Zone".
  --   -- The CAP Limit is 2.
  --   -- The Grouping Radius is set to 20000. Thus all planes within a 20km radius will be grouped as a group of targets.
  --   A2ADispatcher = AI_A2A_GCICAP:New( { "DF CCCP" }, { "SQ CCCP" }, { "CAP Zone" }, 2, 20000 )
  --
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object. Each squadron has unlimited resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The CAP Zone prefix is "CAP Zone".
  --   -- The CAP Limit is 2.
  --   -- The Grouping Radius is set to 20000. Thus all planes within a 20km radius will be grouped as a group of targets.
  --   -- The Engage Radius is set to 60000. Any defender without a task, and in healthy condition,
  --   -- will be considered a defense task if the target is within 60km from the defender.
  --   A2ADispatcher = AI_A2A_GCICAP:New( { "DF CCCP" }, { "SQ CCCP" }, { "CAP Zone" }, 2, 20000, 60000 )
  --
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object. Each squadron has unlimited resources.
  --   -- The EWR network group prefix is DF CCCP. All groups starting with DF CCCP will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The CAP Zone prefix is "CAP Zone".
  --   -- The CAP Limit is 2.
  --   -- The Grouping Radius is set to 20000. Thus all planes within a 20km radius will be grouped as a group of targets.
  --   -- The Engage Radius is set to 60000. Any defender without a task, and in healthy condition,
  --   -- will be considered a defense task if the target is within 60km from the defender.
  --   -- The GCI Radius is set to 150000. Any target detected within 150km will be considered for GCI engagement.
  --   A2ADispatcher = AI_A2A_GCICAP:New( { "DF CCCP" }, { "SQ CCCP" }, { "CAP Zone" }, 2, 20000, 60000, 150000 )
  --
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object. Each squadron has 30 resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The CAP Zone prefix is "CAP Zone".
  --   -- The CAP Limit is 2.
  --   -- The Grouping Radius is set to 20000. Thus all planes within a 20km radius will be grouped as a group of targets.
  --   -- The Engage Radius is set to 60000. Any defender without a task, and in healthy condition,
  --   -- will be considered a defense task if the target is within 60km from the defender.
  --   -- The GCI Radius is set to 150000. Any target detected within 150km will be considered for GCI engagement.
  --   -- The amount of resources for each squadron is set to 30. Thus about 30 resources are allocated to each squadron created.
  --
  --   A2ADispatcher = AI_A2A_GCICAP:New( { "DF CCCP" }, { "SQ CCCP" }, { "CAP Zone" }, 2, 20000, 60000, 150000, 30 )
  --
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object. Each squadron has 30 resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The CAP Zone prefix is nil. No CAP is created.
  --   -- The CAP Limit is nil.
  --   -- The Grouping Radius is nil. The default range of 6km radius will be grouped as a group of targets.
  --   -- The Engage Radius is set nil. The default Engage Radius will be used to consider a defender being assigned to a task.
  --   -- The GCI Radius is nil. Any target detected within the default GCI Radius will be considered for GCI engagement.
  --   -- The amount of resources for each squadron is set to 30. Thus about 30 resources are allocated to each squadron created.
  --
  --   A2ADispatcher = AI_A2A_GCICAP:New( { "DF CCCP" }, { "SQ CCCP" }, nil, nil, nil, nil, nil, 30 )
  --
  function AI_A2A_GCICAP:New( EWRPrefixes, TemplatePrefixes, CapPrefixes, CapLimit, GroupingRadius, EngageRadius, GciRadius, ResourceCount )

    local EWRSetGroup = SET_GROUP:New()
    EWRSetGroup:FilterPrefixes( EWRPrefixes )
    EWRSetGroup:FilterStart()

    local Detection = DETECTION_AREAS:New( EWRSetGroup, GroupingRadius or 30000 )

    local self = BASE:Inherit( self, AI_A2A_DISPATCHER:New( Detection ) ) -- #AI_A2A_GCICAP

    self:SetEngageRadius( EngageRadius )
    self:SetGciRadius( GciRadius )

    -- Determine the coalition of the EWRNetwork, this will be the coalition of the GCICAP.
    local EWRFirst = EWRSetGroup:GetFirst() -- Wrapper.Group#GROUP
    local EWRCoalition = EWRFirst:GetCoalition()

    -- Determine the airbases belonging to the coalition.
    local AirbaseNames = {} -- #list<#string>
    for AirbaseID, AirbaseData in pairs( _DATABASE.AIRBASES ) do
      local Airbase = AirbaseData -- Wrapper.Airbase#AIRBASE
      local AirbaseName = Airbase:GetName()
      if Airbase:GetCoalition() == EWRCoalition then
        table.insert( AirbaseNames, AirbaseName )
      end
    end

    self.Templates = SET_GROUP:New():FilterPrefixes( TemplatePrefixes ):FilterOnce()

    -- Setup squadrons

    self:I( { Airbases = AirbaseNames } )

    self:I( "Defining Templates for Airbases ..." )
    for AirbaseID, AirbaseName in pairs( AirbaseNames ) do
      local Airbase = _DATABASE:FindAirbase( AirbaseName ) -- Wrapper.Airbase#AIRBASE
      local AirbaseName = Airbase:GetName()
      local AirbaseCoord = Airbase:GetCoordinate()
      local AirbaseZone = ZONE_RADIUS:New( "Airbase", AirbaseCoord:GetVec2(), 3000 )
      local Templates = nil
      self:I( { Airbase = AirbaseName } )
      for TemplateID, Template in pairs( self.Templates:GetSet() ) do
        local Template = Template -- Wrapper.Group#GROUP
        local TemplateCoord = Template:GetCoordinate()
        if AirbaseZone:IsVec2InZone( TemplateCoord:GetVec2() ) then
          Templates = Templates or {}
          table.insert( Templates, Template:GetName() )
          self:I( { Template = Template:GetName() } )
        end
      end
      if Templates then
        self:SetSquadron( AirbaseName, AirbaseName, Templates, ResourceCount )
      end
    end

    -- Setup CAP.
    -- Find for each CAP the nearest airbase to the (start or center) of the zone.
    -- CAP will be launched from there.

    self.CAPTemplates = SET_GROUP:New()
    self.CAPTemplates:FilterPrefixes( CapPrefixes )
    self.CAPTemplates:FilterOnce()

    self:I( "Setting up CAP ..." )
    for CAPID, CAPTemplate in pairs( self.CAPTemplates:GetSet() ) do
      local CAPZone = ZONE_POLYGON:New( CAPTemplate:GetName(), CAPTemplate )
      -- Now find the closest airbase from the ZONE (start or center)
      local AirbaseDistance = 99999999
      local AirbaseClosest = nil -- Wrapper.Airbase#AIRBASE
      self:I( { CAPZoneGroup = CAPID } )
      for AirbaseID, AirbaseName in pairs( AirbaseNames ) do
        local Airbase = _DATABASE:FindAirbase( AirbaseName ) -- Wrapper.Airbase#AIRBASE
        local AirbaseName = Airbase:GetName()
        local AirbaseCoord = Airbase:GetCoordinate()
        local Squadron = self.DefenderSquadrons[AirbaseName]
        if Squadron then
          local Distance = AirbaseCoord:Get2DDistance( CAPZone:GetCoordinate() )
          self:I( { AirbaseDistance = Distance } )
          if Distance < AirbaseDistance then
            AirbaseDistance = Distance
            AirbaseClosest = Airbase
          end
        end
      end
      if AirbaseClosest then
        self:I( { CAPAirbase = AirbaseClosest:GetName() } )
        self:SetSquadronCap( AirbaseClosest:GetName(), CAPZone, 6000, 10000, 500, 800, 800, 1200, "RADIO" )
        self:SetSquadronCapInterval( AirbaseClosest:GetName(), CapLimit, 300, 600, 1 )
      end
    end

    -- Setup GCI.
    -- GCI is setup for all Squadrons.
    self:I( "Setting up GCI ..." )
    for AirbaseID, AirbaseName in pairs( AirbaseNames ) do
      local Airbase = _DATABASE:FindAirbase( AirbaseName ) -- Wrapper.Airbase#AIRBASE
      local AirbaseName = Airbase:GetName()
      local Squadron = self.DefenderSquadrons[AirbaseName]
      self:F( { Airbase = AirbaseName } )
      if Squadron then
        self:I( { GCIAirbase = AirbaseName } )
        self:SetSquadronGci( AirbaseName, 800, 1200 )
      end
    end

    self:__Start( 5 )

    self:HandleEvent( EVENTS.Crash, self.OnEventCrashOrDead )
    self:HandleEvent( EVENTS.Dead, self.OnEventCrashOrDead )
    -- self:HandleEvent( EVENTS.RemoveUnit, self.OnEventCrashOrDead )

    self:HandleEvent( EVENTS.Land )
    self:HandleEvent( EVENTS.EngineShutdown )

    return self
  end

  --- AI_A2A_GCICAP constructor with border.
  -- @param #AI_A2A_GCICAP self
  -- @param #string EWRPrefixes A list of prefixes that of groups that setup the Early Warning Radar network.
  -- @param #string TemplatePrefixes A list of template prefixes.
  -- @param #string BorderPrefix A Border Zone Prefix.
  -- @param #string CapPrefixes A list of CAP zone prefixes (polygon zones).
  -- @param #number CapLimit A number of how many CAP maximum will be spawned.
  -- @param #number GroupingRadius The radius in meters wherein detected planes are being grouped as one target area.
  -- For airplanes, 6000 (6km) is recommended, and is also the default value of this parameter.
  -- @param #number EngageRadius The radius in meters wherein detected airplanes will be engaged by airborne defenders without a task.
  -- @param #number GciRadius The radius in meters wherein detected airplanes will GCI.
  -- @param #number ResourceCount The amount of resources that will be allocated to each squadron.
  -- @return #AI_A2A_GCICAP
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object with a border. Each squadron has unlimited resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The CAP Zone prefix is "CAP Zone".
  --   -- The CAP Limit is 2.
  --
  --   A2ADispatcher = AI_A2A_GCICAP:NewWithBorder( { "DF CCCP" }, { "SQ CCCP" }, "Border", { "CAP Zone" }, 2 )
  --
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object with a border. Each squadron has unlimited resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The Border prefix is "Border". This will setup a border using the group defined within the mission editor with the name Border.
  --   -- The CAP Zone prefix is "CAP Zone".
  --   -- The CAP Limit is 2.
  --   -- The Grouping Radius is set to 20000. Thus all planes within a 20km radius will be grouped as a group of targets.
  --
  --   A2ADispatcher = AI_A2A_GCICAP:NewWithBorder( { "DF CCCP" }, { "SQ CCCP" }, "Border", { "CAP Zone" }, 2, 20000 )
  --
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object with a border. Each squadron has unlimited resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The Border prefix is "Border". This will setup a border using the group defined within the mission editor with the name Border.
  --   -- The CAP Zone prefix is "CAP Zone".
  --   -- The CAP Limit is 2.
  --   -- The Grouping Radius is set to 20000. Thus all planes within a 20km radius will be grouped as a group of targets.
  --   -- The Engage Radius is set to 60000. Any defender without a task, and in healthy condition,
  --   -- will be considered a defense task if the target is within 60km from the defender.
  --
  --   A2ADispatcher = AI_A2A_GCICAP:NewWithBorder( { "DF CCCP" }, { "SQ CCCP" }, "Border", { "CAP Zone" }, 2, 20000, 60000 )
  --
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object with a border. Each squadron has unlimited resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The Border prefix is "Border". This will setup a border using the group defined within the mission editor with the name Border.
  --   -- The CAP Zone prefix is "CAP Zone".
  --   -- The CAP Limit is 2.
  --   -- The Grouping Radius is set to 20000. Thus all planes within a 20km radius will be grouped as a group of targets.
  --   -- The Engage Radius is set to 60000. Any defender without a task, and in healthy condition,
  --   -- will be considered a defense task if the target is within 60km from the defender.
  --   -- The GCI Radius is set to 150000. Any target detected within 150km will be considered for GCI engagement.
  --
  --   A2ADispatcher = AI_A2A_GCICAP:NewWithBorder( { "DF CCCP" }, { "SQ CCCP" }, "Border", { "CAP Zone" }, 2, 20000, 60000, 150000 )
  --
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object with a border. Each squadron has 30 resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The Border prefix is "Border". This will setup a border using the group defined within the mission editor with the name Border.
  --   -- The CAP Zone prefix is "CAP Zone".
  --   -- The CAP Limit is 2.
  --   -- The Grouping Radius is set to 20000. Thus all planes within a 20km radius will be grouped as a group of targets.
  --   -- The Engage Radius is set to 60000. Any defender without a task, and in healthy condition,
  --   -- will be considered a defense task if the target is within 60km from the defender.
  --   -- The GCI Radius is set to 150000. Any target detected within 150km will be considered for GCI engagement.
  --   -- The amount of resources for each squadron is set to 30. Thus about 30 resources are allocated to each squadron created.
  --
  --   A2ADispatcher = AI_A2A_GCICAP:NewWithBorder( { "DF CCCP" }, { "SQ CCCP" }, "Border", { "CAP Zone" }, 2, 20000, 60000, 150000, 30 )
  --
  -- @usage
  --
  --   -- Setup a new GCICAP dispatcher object with a border. Each squadron has 30 resources.
  --   -- The EWR network group prefix is "DF CCCP". All groups starting with "DF CCCP" will be part of the EWR network.
  --   -- The Squadron Templates prefix is "SQ CCCP". All groups starting with "SQ CCCP" will be considered as airplane templates.
  --   -- The Border prefix is "Border". This will setup a border using the group defined within the mission editor with the name Border.
  --   -- The CAP Zone prefix is nil. No CAP is created.
  --   -- The CAP Limit is nil.
  --   -- The Grouping Radius is nil. The default range of 6km radius will be grouped as a group of targets.
  --   -- The Engage Radius is set nil. The default Engage Radius will be used to consider a defender being assigned to a task.
  --   -- The GCI Radius is nil. Any target detected within the default GCI Radius will be considered for GCI engagement.
  --   -- The amount of resources for each squadron is set to 30. Thus about 30 resources are allocated to each squadron created.
  --
  --   A2ADispatcher = AI_A2A_GCICAP:NewWithBorder( { "DF CCCP" }, { "SQ CCCP" }, "Border", nil, nil, nil, nil, nil, 30 )
  --
  function AI_A2A_GCICAP:NewWithBorder( EWRPrefixes, TemplatePrefixes, BorderPrefix, CapPrefixes, CapLimit, GroupingRadius, EngageRadius, GciRadius, ResourceCount )

    local self = AI_A2A_GCICAP:New( EWRPrefixes, TemplatePrefixes, CapPrefixes, CapLimit, GroupingRadius, EngageRadius, GciRadius, ResourceCount )

    if BorderPrefix then
      self:SetBorderZone( ZONE_POLYGON:New( BorderPrefix, GROUP:FindByName( BorderPrefix ) ) )
    end

    return self

  end
  
end
