--- **AI** - Create an automated A2G defense system with reconnaissance units, coordinating SEAD, BAI and CAS operations.
-- 
-- ===
-- 
-- Features:
-- 
--    * Setup quickly an A2G defense system for a coalition.
--    * Setup multiple defense zones to defend specific coordinates in your battlefield.
--    * Setup (SEAD) Suppression of Air Defense squadrons, to gain control in the air of enemy grounds.
--    * Setup (BAI) Battleground Air Interdiction squadrons to attack remote enemy ground units and targets.
--    * Setup (CAS) Controlled Air Support squadrons, to attack close by enemy ground units near friendly installations.
--    * Define and use a detection network controlled by recce.
--    * Define A2G defense squadrons at airbases, FARPs and carriers.
--    * Enable airbases for A2G defenses.
--    * Add different planes and helicopter templates to squadrons.
--    * Assign squadrons to execute a specific engagement type depending on threat level of the detected ground enemy unit composition.
--    * Add multiple squadrons to different airbases, FARPs or carriers.
--    * Define different ranges to engage upon.
--    * Establish an automatic in air refuel process for planes using refuel tankers.
--    * Setup default settings for all squadrons and A2G defenses.
--    * Setup specific settings for specific squadrons.
-- 
-- ===
-- 
-- ## Missions:
-- 
-- [AID-A2G - AI A2G Dispatching](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/AID%20-%20AI%20Dispatching/AID-A2G%20-%20AI%20A2G%20Dispatching)
-- 
-- ===
-- 
-- ## YouTube Channel:
-- 
-- [DCS WORLD - MOOSE - A2G DISPATCHER - Build an automatic A2G Defense System - Introduction](https://www.youtube.com/watch?v=zwSxWRAGVH8)
-- 
-- ===
-- 
-- # QUICK START GUIDE
-- 
-- The following class is available to model an A2G defense system.
-- 
-- AI_A2G_DISPATCHER is the main A2G defense class that models the A2G defense system.
-- 
-- Before you start using the AI_A2G_DISPATCHER, ask yourself the following questions:
-- 
-- 
-- ## 1. Which coalition am I modeling an A2G defense system for? Blue or red?
-- 
-- One AI_A2G_DISPATCHER object can create a defense system for **one coalition**, which is blue or red.
-- If you want to create a **mutual defense system**, for both blue and red, then you need to create **two** AI_A2G_DISPATCHER **objects**,
-- each governing their defense system for one coalition.
-- 
--      
-- ## 2. Which type of detection will I setup? Grouping based per AREA, per TYPE or per UNIT? (Later others will follow).
-- 
-- The MOOSE framework leverages the @{Functional.Detection} classes to perform the reconnaissance, detecting enemy units
-- and reporting them to the head quarters.
-- Several types of @{Functional.Detection} classes exist, and the most common characteristics of these classes is that they:
-- 
--    * Perform detections from multiple recce as one co-operating entity.
--    * Communicate with a @{Tasking.CommandCenter}, which consolidates each detection.
--    * Groups detections based on a method (per area, per type or per unit).
--    * Communicates detections.
-- 
-- 
-- ## 3. Which recce units can be used as part of the detection system? Only ground based, or also airborne?
-- 
-- Depending on the type of mission you want to achieve, different types of units can be engaged to perform ground enemy targets reconnaissance.
-- Ground recce (FAC) are very useful units to determine the position of enemy ground targets when they spread out over the battlefield at strategic positions.
-- Using their varying detection technology, and especially those ground units which have spotting technology, can be extremely effective at
-- detecting targets at great range. The terrain elevation characteristics are a big tool in making ground recce to be more effective.
-- Unfortunately, they lack sometimes the visibility to detect targets at greater range, or when scenery is preventing line of sight.
-- If you succeed to position recce at higher level terrain providing a broad and far overview of the lower terrain in the distance, then
-- the recce will be very effective at detecting approaching enemy targets. Therefore, always use the terrain very carefully!
-- 
-- Airborne recce (AFAC) are also very effective. The are capable of patrolling at a functional detection altitude,
-- having an overview of the whole battlefield. However, airborne recce can be vulnerable to air to ground attacks,
-- so you need air superiority to make them effective. 
-- Airborne recce will also have varying ground detection technology, which plays a big role in the effectiveness of the reconnaissance.
-- Certain helicopter or plane types have ground searching radars or advanced ground scanning technology, and are very effective
-- compared to air units having only visual detection capabilities.
-- For example, for the red coalition, the Mi-28N and the Su-34; and for the blue side, the reaper, are such effective airborne recce units.
-- 
-- Typically, don't want these recce units to engage with the enemy, you want to keep them at position. Therefore, it is a good practice
-- to set the ROE for these recce to hold weapons, and make them invisible from the enemy.
-- 
-- It is not possible to perform a recce function as a player (unit).
-- 
-- 
-- ## 4. How do the defenses decide **when and where to engage** on approaching enemy units?
-- 
-- The A2G dispatcher needs you to setup (various) defense coordinates, which are strategic positions in the battle field to be defended.
-- Any ground based enemy approaching within the proximity of such a defense point, may trigger for a defensive action by friendly air units.
-- 
-- There are 2 important parameters that play a role in the defensive decision making: defensiveness and reactivity.
-- 
-- The A2G dispatcher provides various parameters to setup the **defensiveness**, 
-- which models the decision **when** a defender will engage with the approaching enemy.
-- Defensiveness is calculated by a probability distribution model when to trigger a defense action, 
-- depending on the distance of the enemy unit from the defense coordinates, and a **defensiveness factor**. 
-- 
-- The other parameter considered for defensive action is **where the enemy is located**, thus the distance from a defense coordinate, 
-- which we call the **reactive distance**. By default, the reactive distance is set to 60km, but can be changed by the mission designer
-- using the available method explained further below.
-- The combination of the defensiveness and reactivity results in a model that, the closer the attacker is to the defense point, 
-- the higher the probability will be that a defense action will be launched!
-- 
-- 
-- ## 5. Are defense coordinates and defense reactivity the only parameters?
-- 
-- No, depending on the target type, and the threat level of the target, the probability of defense will be higher.
-- In other words, when a SAM-10 radar emitter is detected, its probability for defense will be much higher than when a BMP-1 vehicle is
-- detected, even when both enemies are at the same distance from a defense coordinate.
-- This will ensure optimal defenses, SEAD tasks will be launched much more quicker against engaging radar emitters, to ensure air superiority.
-- Approaching main battle tanks will be engaged much faster, than a group of approaching trucks.
-- 
-- 
-- ## 6. Which Squadrons will I create and which name will I give each Squadron?
-- 
-- The A2G defense system works with **Squadrons**. Each Squadron must be given a unique name, that forms the **key** to the squadron.
-- Several options and activities can be set per Squadron. A free format name can be given, but always ensure that the name is meaningful
-- for your mission, and remember that squadron names are used for communication to the players of your mission.
-- 
-- There are mainly 3 types of defenses: **SEAD**, **BAI**, and **CAS**.
-- 
-- Suppression of Air Defenses (SEAD) are effective against radar emitters.
-- Battleground Air Interdiction (BAI) tasks are launched when there are no friendlies around.
-- Close Air Support (CAS) is launched when the enemy is close near friendly units.
-- 
-- Depending on the defense type, different payloads will be needed. See further points on squadron definition.
-- 
-- 
-- ## 7. Where will the Squadrons be located? On Airbases? On Carriers? On FARPs?
-- 
-- Squadrons are placed at the **home base** on an **airfield**, **carrier** or **FARP**.
-- Carefully plan where each Squadron will be located as part of the defense system required for mission effective defenses.
-- If the home base of the squadron is too far from assumed enemy positions, then the defenses will be too late.
-- The home bases must be **behind** enemy lines, you want to prevent your home bases to be engaged by enemies!
-- Depending on the units applied for defenses, the home base can be further or closer to the enemies.
-- Any airbase, FARP, or carrier can act as the launching platform for A2G defenses.
-- Carefully plan which airbases will take part in the coalition. Color each airbase **in the color of the coalition**, using the mission editor,
-- or your air units will not return for landing at the airbase!
-- 
-- 
-- ## 8. Which helicopter or plane models will I assign for each Squadron? Do I need one plane model or more plane models per squadron?
-- 
-- Per Squadron, one or multiple helicopter or plane models can be allocated as **Templates**.
-- These are late activated groups with one airplane or helicopter that start with a specific name, called the **template prefix**.
-- The A2G defense system will select from the given templates a random template to spawn a new plane (group).
-- 
-- A squadron will perform specific task types (SEAD, BAI or CAS). So, squadrons will require specific templates for the
-- task types it will perform. A squadron executing SEAD defenses, will require a payload with long range anti-radar seeking missiles.
--  
--  
-- ## 9. Which payloads, skills and skins will these plane models have?
-- 
-- Per Squadron, even if you have one plane model, you can still allocate multiple templates of one plane model, 
-- each having different payloads, skills and skins. 
-- The A2G defense system will select from the given templates a random template to spawn a new plane (group).
-- 
-- 
-- ## 10. How do squadrons engage in a defensive action?
-- 
-- There are two ways how squadrons engage and execute your A2G defenses. 
-- Squadrons can start the defense directly from the airbase, FARP or carrier. When a squadron launches a defensive group, that group
-- will start directly from the airbase. The other way is to launch early on in the mission a patrolling mechanism.
-- Squadrons will launch air units to patrol in specific zone(s), so that when ground enemy targets are detected, that the airborne
-- A2G defenses can come immediately into action.
-- 
-- 
-- ## 11. For each Squadron doing a patrol, which zone types will I create?
-- 
-- Per zone, evaluate whether you want:
-- 
--    * simple trigger zones
--    * polygon zones
--    * moving zones
-- 
-- Depending on the type of zone selected, a different @{Core.Zone} object needs to be created from a ZONE_ class.
-- 
-- 
-- ## 12. Are moving defense coordinates possible?
-- 
-- Yes, different COORDINATE types are possible to be used.
-- The COORDINATE_UNIT will help you to specify a defense coordinate that is attached to a moving unit.
-- 
-- 
-- ## 13. How many defense coordinates do I need to create?
-- 
-- It depends, but the idea is to define only the necessary defense points that drive your mission.
-- If you define too many defense coordinates, the performance of your mission may decrease. For each defined defense coordinate,
-- all the possible enemies are evaluated. Note that each defense coordinate has a reach depending on the size of the associated defense radius.
-- The default defense radius is about 60km. Depending on the defense reactivity, defenses will be launched when the enemy is at a
-- closer distance from the defense coordinate than the defense radius.
-- 
-- 
-- ## 14. For each Squadron doing patrols, what are the time intervals and patrol amounts to be performed?
-- 
-- For each patrol:
-- 
--    * **How many** patrols you want to have airborne at the same time?
--    * **How frequent** you want the defense mechanism to check whether to start a new patrol?
-- 
-- Other considerations:
-- 
--    * **How far** is the patrol area from the engagement "hot zone". You want to ensure that the enemy is reached on time!
--    * **How safe** is the patrol area taking into account air superiority. Is it well defended, are there nearby A2A bases?
-- 
-- 
-- ## 15. For each Squadron, which takeoff method will I use?
-- 
-- For each Squadron, evaluate which takeoff method will be used:
-- 
--    * Straight from the air
--    * From the runway
--    * From a parking spot with running engines
--    * From a parking spot with cold engines
-- 
-- **The default takeoff method is straight in the air.**
-- This takeoff method is the most useful if you want to avoid airplane clutter at airbases, but it is the least realistic one.
-- 
-- 
-- ## 16. For each Squadron, which landing method will I use?
-- 
-- For each Squadron, evaluate which landing method will be used:
-- 
--    * Despawn near the airbase when returning
--    * Despawn after landing on the runway
--    * Despawn after engine shutdown after landing
--    
-- **The default landing method is to despawn when near the airbase when returning.**
-- This landing method is the most useful if you want to avoid aircraft clutter at airbases, but it is the least realistic one.
-- 
-- 
-- ## 19. For each Squadron, which **defense overhead** will I use?
-- 
-- For each Squadron, depending on the helicopter or airplane type (modern, old) and payload, which overhead is required to provide any defense?
-- 
-- In other words, if **X** enemy ground units are detected, how many **Y** defense helicopters or airplanes need to engage (per squadron)?
-- The **Y** is dependent on the type of aircraft (era), payload, fuel levels, skills etc.
-- But the most important factor is the payload, which is the amount of A2G weapons the defense can carry to attack the enemy ground units.
-- For example, a Ka-50 can carry 16 Vikhrs, this means that it potentially can destroy at least 8 ground units without a reload of ammunition.
-- That means, that one defender can destroy more enemy ground units.
-- Thus, the overhead is a **factor** that will calculate dynamically how many **Y** defenses will be required based on **X** attackers detected.
-- 
-- **The default overhead is 1. A smaller value than 1, like 0.25 will decrease the overhead to a 1 / 4 ratio, meaning, 
-- one defender for each 4 detected ground enemy units. **
-- 
-- 
-- ## 19. For each Squadron, which grouping will I use?
-- 
-- When multiple targets are detected, how will defenses be grouped when multiple defense air units are spawned for multiple enemy ground units?
-- Per one, two, three, four?
-- 
-- **The default grouping is 1. That means, that each spawned defender will act individually.**
-- But you can specify a number between 1 and 4, so that the defenders will act as a group.
-- 
-- ===
-- 
-- ### Author: **FlightControl** rework of GCICAP + introduction of new concepts (squadrons).
-- 
-- @module AI.AI_A2G_Dispatcher
-- @image AI_Air_To_Ground_Dispatching.JPG


do -- AI_A2G_DISPATCHER

  --- AI_A2G_DISPATCHER class.
  -- @type AI_A2G_DISPATCHER
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER

  --- Create an automated A2G defense system based on a detection network of reconnaissance vehicles and air units, coordinating SEAD, BAI and CAS operations.
  -- 
  -- ===
  -- 
  -- When your mission is in the need to take control of the AI to automate and setup a process of air to ground defenses, this is the module you need.
  -- The defense system work through the definition of defense coordinates, which are points in your friendly area within the battle field, that your mission need to have defended.
  -- Multiple defense coordinates can be setup. Defense coordinates can be strategic or tactical positions or references to strategic units or scenery.
  -- The A2G dispatcher will evaluate every x seconds the tactical situation around each defense coordinate. When a defense coordinate
  -- is under threat, it will communicate through the command center that defensive actions need to be taken and will launch groups of air units for defense.
  -- The level of threat to the defense coordinate varies upon the strength and types of the enemy units, the distance to the defense point, and the defensiveness parameters.
  -- Defensive actions are taken through probability, but the closer and the more threat the enemy poses to the defense coordinate, the faster it will be attacked by friendly A2G units.
  -- 
  -- Please study carefully the underlying explanations how to setup and use this module, as it has many features.
  -- It also requires a little study to ensure that you get a good understanding of the defense mechanisms, to ensure a strong
  -- defense for your missions.
  -- 
  -- ===
  -- 
  -- # USAGE GUIDE
  -- 
  -- 
  -- ## 1. AI\_A2G\_DISPATCHER constructor:
  -- 
  -- ![Banner Image](..\Presentations\AI_A2G_DISPATCHER\AI_A2G_DISPATCHER-ME_1.JPG)
  -- 
  -- 
  -- The @{#AI_A2G_DISPATCHER.New}() method creates a new AI_A2G_DISPATCHER instance.
  -- 
  -- 
  -- ### 1.1. Define the **reconnaissance network**:
  -- 
  -- As part of the AI_A2G_DISPATCHER :New() constructor, a reconnaissance network must be given as the first parameter.
  -- A reconnaissance network is provided by passing a @{Functional.Detection} object.
  -- The most effective reconnaissance for the A2G dispatcher would be to use the @{Functional.Detection#DETECTION_AREAS} object.
  -- 
  -- A reconnaissance network, is used to detect enemy ground targets, 
  -- potentially group them into areas, and to understand the position, level of threat of the enemy.
  -- 
  -- ![Banner Image](..\Presentations\AI_A2G_DISPATCHER\Dia5.JPG)
  -- 
  -- As explained in the introduction, depending on the type of mission you want to achieve, different types of units can be applied to detect ground enemy targets.
  -- Ground based units are very useful to act as a reconnaissance, but they lack sometimes the visibility to detect targets at greater range.
  -- Recce are very useful to acquire the position of enemy ground targets when spread out over the battlefield at strategic positions.
  -- Ground units also have varying detectors, and especially the ground units which have laser guiding missiles can be extremely effective at
  -- detecting targets at great range. The terrain elevation characteristics are a big tool in making ground recce to be more effective.
  -- If you succeed to position recce at higher level terrain providing a broad and far overview of the lower terrain in the distance, then
  -- the recce will be very effective at detecting approaching enemy targets. Therefore, always use the terrain very carefully!
  -- 
  -- Beside ground level units to use for reconnaissance, air units are also very effective. The are capable of patrolling at great speed
  -- covering a large terrain. However, airborne recce can be vulnerable to air to ground attacks, and you need air superiority to make then
  -- effective. Also the instruments available at the air units play a big role in the effectiveness of the reconnaissance.
  -- Air units which have ground detection capabilities will be much more effective than air units with only visual detection capabilities.
  -- For the red coalition, the Mi-28N and for the blue side, the reaper are such effective reconnaissance airborne units.
  -- 
  -- Reconnaissance networks are **dynamically constructed**, that is, they form part of the @{Functional.Detection} instance that is given as the first parameter to the A2G dispatcher.
  -- By defining in a **smart way the names or name prefixes of the reconnaissance groups**, these groups will be **automatically added or removed** to or from the reconnaissance network, 
  -- when these groups are spawned in or destroyed during the ongoing battle. 
  -- By spawning in dynamically additional recce, you can ensure that there is sufficient reconnaissance coverage so the defense mechanism is continuously
  -- alerted of new enemy ground targets.
  -- 
  -- The following is an example defense of a new reconnaissance network using a @{Functional.Detection#DETECTION_AREAS} object.
  -- 
  --        -- Define a SET_GROUP object that builds a collection of groups that define the recce network.
  --        -- Here we build the network with all the groups that have a name starting with CCCP Recce.
  --        DetectionSetGroup = SET_GROUP:New() -- Define a set of group objects, called DetectionSetGroup.
  -- 
  --        DetectionSetGroup:FilterPrefixes( { "CCCP Recce" } ) -- The DetectionSetGroup will search for groups that start with the name "CCCP Recce".
  -- 
  --        -- This command will start the dynamic filtering, so when groups spawn in or are destroyed,
  --        -- which have a group name starting with "CCCP Recce", then these will be automatically added or removed from the set.
  --        DetectionSetGroup:FilterStart()
  -- 
  --        -- This command defines the reconnaissance network.
  --        -- It will group any detected ground enemy targets within a radius of 1km.
  --        -- It uses the DetectionSetGroup, which defines the set of reconnaissance groups to detect for enemy ground targets.
  --        Detection = DETECTION_AREAS:New( DetectionSetGroup, 1000 )
  -- 
  --        -- Setup the A2G dispatcher, and initialize it.
  --        A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )
  -- 
  -- 
  -- The above example creates a SET_GROUP instance, and stores this in the variable (object) **DetectionSetGroup**.
  -- **DetectionSetGroup** is then being configured to filter all active groups with a group name starting with `"CCCP Recce"` to be included in the set.
  -- **DetectionSetGroup** is then calling `FilterStart()`, which is starting the dynamic filtering or inclusion of these groups.
  -- Note that any destroy or new spawn of a group having a name, starting with the above prefix, will be removed or added to the set.
  -- 
  -- Then a new detection object is created from the class `DETECTION_AREAS`. A grouping radius of 1000 meters (1km) is chosen.
  -- 
  -- The `Detection` object is then passed to the @{#AI_A2G_DISPATCHER.New}() method to indicate the reconnaissance network
  -- configuration and setup the A2G defense detection mechanism.
  -- 
  -- 
  -- ### 1.2. Setup the A2G dispatcher for both a red and blue coalition.
  -- 
  -- Following the above described procedure, you'll need to create for each coalition an separate detection network, and a separate A2G dispatcher.
  -- Ensure that while doing so, that you name the objects differently both for red and blue coalition.
  -- 
  -- For example like this for the red coalition:
  -- 
  --        DetectionRed = DETECTION_AREAS:New( DetectionSetGroupRed, 1000 )
  --        A2GDispatcherRed = AI_A2G_DISPATCHER:New( DetectionRed )
  --        
  -- And for the blue coalition:
  -- 
  --        DetectionBlue = DETECTION_AREAS:New( DetectionSetGroupBlue, 1000 )
  --        A2GDispatcherBlue = AI_A2G_DISPATCHER:New( DetectionBlue )
  -- 
  -- Note: Also the SET_GROUP objects should be created for each coalition separately, containing each red and blue recce respectively!
  -- 
  -- 
  -- ### 1.3. Define the enemy ground target **grouping radius**, in case you use DETECTION_AREAS:
  -- 
  -- The target grouping radius is a property of the DETECTION_AREAS class, that was passed to the AI_A2G_DISPATCHER:New() method
  -- but can be changed. The grouping radius should not be too small, but also depends on the types of ground forces and the way you want your mission to evolve.
  -- A large radius will mean large groups of enemy ground targets, while making smaller groups will result in a more fragmented defense system.
  -- Typically I suggest a grouping radius of 1km. This is the right balance to create efficient defenses.
  -- 
  -- Note that detected targets are constantly re-grouped, that is, when certain detected enemy ground units are moving further than the group radius
  -- then these units will become a separate area being detected. This may result in additional defenses being started by the dispatcher,
  -- so don't make this value too small! Again, about 1km, or 1000 meters, is recommended.
  -- 
  -- 
  -- ## 2. Setup (a) **Defense Coordinate(s)**.
  -- 
  -- As explained above, defense coordinates are the center of your defense operations.
  -- The more threat to the defense coordinate, the higher it is likely a defensive action will be launched.
  -- 
  -- Find below an example how to add defense coordinates:
  -- 
  --        -- Add defense coordinates.
  --        A2GDispatcher:AddDefenseCoordinate( "HQ", GROUP:FindByName( "HQ" ):GetCoordinate() )
  -- 
  -- In this example, the coordinate of a group called `"HQ"` is retrieved, using `:GetCoordinate()`
  -- This returns a COORDINATE object, pointing to the first unit within the GROUP object.
  -- 
  -- The method @{#AI_A2G_DISPATCHER.AddDefenseCoordinate}() adds a new defense coordinate to the `A2GDispatcher` object.
  -- The first parameter is the key of the defense coordinate, the second the coordinate itself.
  -- 
  -- Later, a COORDINATE_UNIT will be added to the framework, which can be used to assign "moving" coordinates to an A2G dispatcher.
  -- 
  -- **REMEMBER!**
  -- 
  --   - **Defense coordinates are the center of the A2G dispatcher defense system!**
  --   - **You can define more defense coordinates to defend a larger area.**
  --   - **Detected enemy ground targets are not immediately engaged, but are engaged with a reactivity or probability calculation!**
  -- 
  -- But, there is more to it ...
  -- 
  -- 
  -- ### 2.1. The **Defense Radius**.
  -- 
  -- The defense radius defines the maximum radius that a defense will be initiated around each defense coordinate.
  -- So even when there are targets further away than the defense radius, then these targets won't be engaged upon.
  -- By default, the defense radius is set to 100km (100.000 meters), but can be changed using the @{#AI_A2G_DISPATCHER.SetDefenseRadius}() method.
  -- Note that the defense radius influences the defense reactivity also! The larger the defense radius, the more reactive the defenses will be.
  -- 
  -- For example:
  -- 
  --        A2GDispatcher:SetDefenseRadius( 30000 )
  -- 
  -- This defines an A2G dispatcher which will engage on enemy ground targets within 30km radius around the defense coordinate.
  -- Note that the defense radius **applies to all defense coordinates** defined within the A2G dispatcher.
  -- 
  -- 
  -- ### 2.2. The **Defense Reactivity**.
  -- 
  -- There are three levels that can be configured to tweak the defense reactivity. As explained above, the threat to a defense coordinate is
  -- also determined by the distance of the enemy ground target to the defense coordinate.
  -- If you want to have a **low** defense reactivity, that is, the probability that an A2G defense will engage to the enemy ground target, then
  -- use the @{#AI_A2G_DISPATCHER.SetDefenseReactivityLow}() method. For medium and high reactivity, use the methods
  -- @{#AI_A2G_DISPATCHER.SetDefenseReactivityMedium}() and @{#AI_A2G_DISPATCHER.SetDefenseReactivityHigh}() respectively.
  -- 
  -- Note that the reactivity of defenses is always in relation to the Defense Radius! the shorter the distance,
  -- the less reactive the defenses will be in terms of distance to enemy ground targets!
  -- 
  -- For example:
  -- 
  --        A2GDispatcher:SetDefenseReactivityHigh()
  --        
  -- This defines an A2G dispatcher with high defense reactivity.
  -- 
  -- 
  -- ## 3. **Squadrons**.
  -- 
  -- The A2G dispatcher works with **Squadrons**, that need to be defined using the different methods available.
  -- 
  -- Use the method @{#AI_A2G_DISPATCHER.SetSquadron}() to **setup a new squadron** active at an airfield, FARP or carrier,
  -- while defining which helicopter or plane **templates** are being used by the squadron and how many **resources** are available.
  -- 
  -- **Multiple squadrons** can be defined within one A2G dispatcher, each having specific defense tasks and defense parameter settings!
  -- 
  -- Squadrons:
  -- 
  --   * Have name (string) that is the identifier or **key** of the squadron.
  --   * Have specific helicopter or plane **templates**.
  --   * Are located at **one** airbase, farp or carrier.
  --   * Optionally have a **limited set of resources**. The default is that squadrons have **unlimited resources**.
  -- 
  -- The name of the squadron given acts as the **squadron key** in all `A2GDispatcher:SetSquadron...()` or `A2GDispatcher:GetSquadron...()` methods.
  -- 
  -- Additionally, squadrons have specific configuration options to:
  -- 
  --   * Control how new helicopters or aircraft are taking off from the airfield, farp or carrier (in the air, cold, hot, at the runway).
  --   * Control how returning helicopters or aircraft are landing at the airfield, farp or carrier (in the air near the airbase, after landing, after engine shutdown).
  --   * Control the **grouping** of new helicopters or aircraft spawned at the airfield, farp or carrier. If there is more than one helicopter or aircraft to be spawned, these may be grouped.
  --   * Control the **overhead** or defensive strength of the squadron. Depending on the types of helicopters, planes, amount of resources and payload (weapon configuration) chosen,
  --     the mission designer can choose to increase or reduce the amount of planes spawned.
  -- 
  -- The method @{#AI_A2G_DISPATCHER.SetSquadron}() defines for you a new squadron. 
  -- The provided parameters are the squadron name, airbase name and a list of template prefixes, and a number that indicates the amount of resources.
  -- 
  -- For example, this defines 3 new squadrons:
  -- 
  --        A2GDispatcher:SetSquadron( "Maykop SEAD", AIRBASE.Caucasus.Maykop_Khanskaya, { "CCCP KA-50" }, 10 )
  --        A2GDispatcher:SetSquadron( "Maykop CAS", "CAS", { "CCCP KA-50" }, 10 )
  --        A2GDispatcher:SetSquadron( "Maykop BAI", "BAI", { "CCCP KA-50" }, 10 )
  -- 
  -- The latter 2 will depart from FARPs, which bare the name `"CAS"` and `"BAI"`.
  -- 
  -- 
  -- ### 3.1. Squadrons **Tasking**.
  -- 
  -- Squadrons can be commanded to execute 3 types of tasks, as explained above:
  -- 
  --   - SEAD: Suppression of Air Defenses, which are ground targets that have medium or long range radar emitters.
  --   - BAI : Battlefield Air Interdiction, which are targets further away from the front-line.
  --   - CAS : Close Air Support, when there are enemy ground targets close to friendly units.
  -- 
  -- You need to configure each squadron which task types you want it to perform. Read on ...
  -- 
  -- 
  -- ### 3.2. Squadrons enemy ground target **engagement types**.
  --   
  -- There are two ways how targets can be engaged: directly **on call** from the airfield, FARP or carrier, or through a **patrol**.
  -- 
  -- Patrols are extremely handy, as these will get your helicopters or airplanes airborne in advance. They will patrol in defined zones outlined,
  -- and will engage with the targets once commanded. If the patrol zone is close enough to the enemy ground targets, then the time required
  -- to engage is heavily minimized!
  -- 
  -- However; patrols come with a side effect: since your resources are airborne, they will be vulnerable to incoming air attacks from the enemy.
  -- 
  -- The mission designer needs to carefully balance the need for patrols or the need for engagement on call from the airfields.
  -- 
  -- 
  -- ### 3.3. Squadron **on call** engagement.
  -- 
  -- So to make squadrons engage targets from the airfields, use the following methods:
  -- 
  --   - For SEAD, use the @{#AI_A2G_DISPATCHER.SetSquadronSead}() method.
  --   - For BAI, use the @{#AI_A2G_DISPATCHER.SetSquadronBai}() method.
  --   - For CAS, use the @{#AI_A2G_DISPATCHER.SetSquadronCas}() method.
  -- 
  -- Note that for the tasks, specific helicopter or airplane templates are required to be used, which you can configure using your mission editor.
  -- Especially the payload (weapons configuration) is important to get right.
  -- 
  -- For example, the following will define for the squadrons different tasks:
  -- 
  --        A2GDispatcher:SetSquadron( "Maykop SEAD", AIRBASE.Caucasus.Maykop_Khanskaya, { "CCCP KA-50 SEAD" }, 10 )
  --        A2GDispatcher:SetSquadronSead( "Maykop SEAD", 120, 250 )
  --        
  --        A2GDispatcher:SetSquadron( "Maykop BAI", "BAI", { "CCCP KA-50 BAI" }, 10 )
  --        A2GDispatcher:SetSquadronBai( "Maykop BAI", 120, 250 )
  -- 
  --        A2GDispatcher:SetSquadron( "Maykop CAS", "CAS", { "CCCP KA-50 CAS" }, 10 )
  --        A2GDispatcher:SetSquadronCas( "Maykop CAS", 120, 250 )
  --        
  -- 
  -- ### 3.4. Squadron **on patrol engagement**.
  -- 
  -- Squadrons can be setup to patrol in the air near the engagement hot zone.
  -- When needed, the A2G defense units will be close to the battle area, and can engage quickly.
  -- 
  -- So to make squadrons engage targets from a patrol zone, use the following methods:
  -- 
  --   - For SEAD, use the @{#AI_A2G_DISPATCHER.SetSquadronSeadPatrol}() method.
  --   - For BAI, use the @{#AI_A2G_DISPATCHER.SetSquadronBaiPatrol}() method.
  --   - For CAS, use the @{#AI_A2G_DISPATCHER.SetSquadronCasPatrol}() method.
  -- 
  -- Because a patrol requires more parameters, the following methods must be used to fine-tune the patrols for each squadron.
  -- 
  --   - For SEAD, use the @{#AI_A2G_DISPATCHER.SetSquadronSeadPatrolInterval}() method.
  --   - For BAI, use the @{#AI_A2G_DISPATCHER.SetSquadronBaiPatrolInterval}() method.
  --   - For CAS, use the @{#AI_A2G_DISPATCHER.SetSquadronCasPatrolInterval}() method.
  -- 
  -- Here an example to setup patrols of various task types:
  -- 
  --        A2GDispatcher:SetSquadron( "Maykop SEAD", AIRBASE.Caucasus.Maykop_Khanskaya, { "CCCP KA-50 SEAD" }, 10 )
  --        A2GDispatcher:SetSquadronSeadPatrol( "Maykop SEAD", PatrolZone, 300, 500, 50, 80, 250, 300 )
  --        A2GDispatcher:SetSquadronPatrolInterval( "Maykop SEAD", 2, 30, 60, 1, "SEAD" )
  --        
  --        A2GDispatcher:SetSquadron( "Maykop BAI", "BAI", { "CCCP KA-50 BAI" }, 10 )
  --        A2GDispatcher:SetSquadronBaiPatrol( "Maykop BAI", PatrolZone, 800, 900, 50, 80, 250, 300 )
  --        A2GDispatcher:SetSquadronPatrolInterval( "Maykop BAI", 2, 30, 60, 1, "BAI" )
  -- 
  --        A2GDispatcher:SetSquadron( "Maykop CAS", "CAS", { "CCCP KA-50 CAS" }, 10 )
  --        A2GDispatcher:SetSquadronCasPatrol( "Maykop CAS", PatrolZone, 600, 700, 50, 80, 250, 300 )
  --        A2GDispatcher:SetSquadronPatrolInterval( "Maykop CAS", 2, 30, 60, 1, "CAS" )
  --        
  -- 
  -- ### 3.5. Set squadron takeoff methods
  -- 
  -- Use the various SetSquadronTakeoff... methods to control how squadrons are taking-off from the home airfield, FARP or ship.
  -- 
  --   * @{#AI_A2G_DISPATCHER.SetSquadronTakeoff}() is the generic configuration method to control takeoff from the air, hot, cold or from the runway. See the method for further details.
  --   * @{#AI_A2G_DISPATCHER.SetSquadronTakeoffInAir}() will spawn new aircraft from the squadron directly in the air.
  --   * @{#AI_A2G_DISPATCHER.SetSquadronTakeoffFromParkingCold}() will spawn new aircraft in without running engines at a parking spot at the airfield.
  --   * @{#AI_A2G_DISPATCHER.SetSquadronTakeoffFromParkingHot}() will spawn new aircraft in with running engines at a parking spot at the airfield.
  --   * @{#AI_A2G_DISPATCHER.SetSquadronTakeoffFromRunway}() will spawn new aircraft at the runway at the airfield.
  -- 
  -- **The default landing method is to spawn new aircraft directly in the air.**
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
  -- If you experience while testing problems with aircraft takeoff or landing, please use one of the above methods as a solution to workaround these issues!
  -- 
  -- This example sets the default takeoff method to be from the runway.
  -- And for a couple of squadrons overrides this default method.
  -- 
  --      -- Setup the takeoff methods
  -- 
  --      -- Set the default takeoff method
  --      A2GDispatcher:SetDefaultTakeoffFromRunway()
  -- 
  --      -- Set the individual squadrons takeoff method
  --      A2GDispatcher:SetSquadronTakeoff( "Mineralnye", AI_A2G_DISPATCHER.Takeoff.Air )
  --      A2GDispatcher:SetSquadronTakeoffInAir( "Sochi" )
  --      A2GDispatcher:SetSquadronTakeoffFromRunway( "Mozdok" )
  --      A2GDispatcher:SetSquadronTakeoffFromParkingCold( "Maykop" )
  --      A2GDispatcher:SetSquadronTakeoffFromParkingHot( "Novo" )
  -- 
  -- 
  -- ### 3.5.1. Set Squadron takeoff altitude when spawning new aircraft in the air.
  -- 
  -- In the case of the @{#AI_A2G_DISPATCHER.SetSquadronTakeoffInAir}() there is also an other parameter that can be applied.
  -- That is modifying or setting the **altitude** from where planes spawn in the air.
  -- Use the method @{#AI_A2G_DISPATCHER.SetSquadronTakeoffInAirAltitude}() to set the altitude for a specific squadron.
  -- The default takeoff altitude can be modified or set using the method @{#AI_A2G_DISPATCHER.SetSquadronTakeoffInAirAltitude}().
  -- As part of the method @{#AI_A2G_DISPATCHER.SetSquadronTakeoffInAir}() a parameter can be specified to set the takeoff altitude.
  -- If this parameter is not specified, then the default altitude will be used for the squadron.
  -- 
  -- 
  -- ### 3.5.2. Set Squadron takeoff interval.
  -- 
  -- The different types of available airfields have different amounts of available launching platforms:
  -- 
  --   - Airbases typically have a lot of platforms.
  --   - FARPs have 4 platforms.
  --   - Ships have 2 to 4 platforms.
  -- 
  -- Depending on the demand of requested takeoffs by the A2G dispatcher, an airfield can become overloaded. Too many aircraft need to be taken
  -- off at the same time, which will result in clutter as described above. In order to better control this behaviour, a takeoff scheduler is implemented,
  -- which can be used to control how many aircraft are ordered for takeoff between specific time intervals.
  -- The takeoff intervals can be specified per squadron, which make sense, as each squadron have a "home" airfield.
  -- 
  -- For this purpose, the method @{#AI_A2G_DISPATCHER.SetSquadronTakeoffInterval}() can be used to specify the takeoff intervals of
  -- aircraft groups per squadron to avoid cluttering of aircraft at airbases.
  -- This is especially useful for FARPs and ships. Each takeoff dispatch is queued by the dispatcher and when the interval time
  -- has been reached, a new group will be spawned or activated for takeoff.
  -- 
  -- The interval needs to be estimated, and depends on the time needed for the aircraft group to actually depart from the launch platform, and
  -- the way how the aircraft are starting up. Cold starts take the longest duration, hot starts a few seconds, and runway takeoff also a few seconds for FARPs and ships.
  -- 
  -- See the underlying example:
  -- 
  --      -- Imagine a squadron launched from a FARP, with a grouping of 4.
  --      -- Aircraft will cold start from the FARP, and thus, a maximum of 4 aircraft can be launched at the same time.
  --      -- Additionally, depending on the group composition of the aircraft, defending units will be ordered for takeoff together.
  --      -- It takes about 3 to 4 minutes for helicopters to takeoff from FARPs in cold start.
  --      A2GDispatcher:SetSquadronTakeoffInterval( "Mineralnye", 60 * 4 )
  -- 
  -- 
  -- ### 3.6. Set squadron landing methods
  -- 
  -- In analogy with takeoff, the landing methods are to control how squadrons land at the airfield:
  -- 
  --   * @{#AI_A2G_DISPATCHER.SetSquadronLanding}() is the generic configuration method to control landing, namely despawn the aircraft near the airfield in the air, right after landing, or at engine shutdown.
  --   * @{#AI_A2G_DISPATCHER.SetSquadronLandingNearAirbase}() will despawn the returning aircraft in the air when near the airfield.
  --   * @{#AI_A2G_DISPATCHER.SetSquadronLandingAtRunway}() will despawn the returning aircraft directly after landing at the runway.
  --   * @{#AI_A2G_DISPATCHER.SetSquadronLandingAtEngineShutdown}() will despawn the returning aircraft when the aircraft has returned to its parking spot and has turned off its engines.
  -- 
  -- You can use these methods to minimize the airbase coordination overhead and to increase the airbase efficiency.
  -- When there are lots of aircraft returning for landing, at the same airbase, the takeoff process will be halted, which can cause a complete failure of the
  -- A2G defense system, as no new SEAD, BAI or CAS planes can takeoff.
  -- Note that the method @{#AI_A2G_DISPATCHER.SetSquadronLandingNearAirbase}() will only work for returning aircraft, not for damaged or out of fuel aircraft.
  -- Damaged or out-of-fuel aircraft are returning to the nearest friendly airbase and will land, and are out of control from ground control.
  -- 
  -- This example defines the default landing method to be at the runway.
  -- And for a couple of squadrons overrides this default method.
  -- 
  --      -- Setup the Landing methods
  -- 
  --      -- The default landing method
  --      A2GDispatcher:SetDefaultLandingAtRunway()
  -- 
  --      -- The individual landing per squadron
  --      A2GDispatcher:SetSquadronLandingAtRunway( "Mineralnye" )
  --      A2GDispatcher:SetSquadronLandingNearAirbase( "Sochi" )
  --      A2GDispatcher:SetSquadronLandingAtEngineShutdown( "Mozdok" )
  --      A2GDispatcher:SetSquadronLandingNearAirbase( "Maykop" )
  --      A2GDispatcher:SetSquadronLanding( "Novo", AI_A2G_DISPATCHER.Landing.AtRunway )
  -- 
  -- 
  -- ### 3.7. Set squadron **grouping**.
  -- 
  -- Use the method @{#AI_A2G_DISPATCHER.SetSquadronGrouping}() to set the grouping of aircraft when spawned in.
  -- 
  -- ![Banner Image](..\Presentations\AI_A2G_DISPATCHER\Dia12.JPG)
  -- 
  -- In the case of **on call** engagement, the @{#AI_A2G_DISPATCHER.SetSquadronGrouping}() method has additional behaviour.
  -- When there aren't enough patrol flights airborne, a on call will be initiated for the remaining
  -- targets to be engaged. Depending on the grouping parameter, the spawned flights for on call aircraft are grouped into this setting.   
  -- For example with a group setting of 2, if 3 targets are detected and cannot be engaged by the available patrols or any airborne flight, 
  -- an additional on call flight needs to be started.
  -- 
  -- The **grouping value is set for a Squadron**, and can be **dynamically adjusted** during mission execution, so to adjust the defense flights grouping when the tactical situation changes.
  -- 
  -- ### 3.8. Set the squadron **overhead** to balance the effectiveness of the A2G defenses.
  -- 
  -- The effectiveness can be set with the **overhead parameter**. This is a number that is used to calculate the amount of Units that dispatching command will allocate to GCI in surplus of detected amount of units.
  -- The **default value** of the overhead parameter is 1.0, which means **equal balance**.
  -- 
  -- ![Banner Image](..\Presentations\AI_A2G_DISPATCHER\Dia11.JPG)
  -- 
  -- However, depending on the (type of) aircraft (strength and payload) in the squadron and the amount of resources available, this parameter can be changed.
  -- 
  -- The @{#AI_A2G_DISPATCHER.SetSquadronOverhead}() method can be used to tweak the defense strength,
  -- taking into account the plane types of the squadron. 
  -- 
  -- For example, a A-10C with full long-distance A2G missiles payload, may still be less effective than a Su-23 with short range A2G missiles...
  -- So in this case, one may want to use the @{#AI_A2G_DISPATCHER.SetOverhead}() method to allocate more defending planes as the amount of detected attacking ground units.
  -- The overhead must be given as a decimal value with 1 as the neutral value, which means that overhead values:
  -- 
  --   * Higher than 1.0, for example 1.5, will increase the defense unit amounts. For 4 attacking ground units detected, 6 aircraft will be spawned.
  --   * Lower than 1, for example 0.75, will decrease the defense unit amounts. For 4 attacking ground units detected, only 3 aircraft will be spawned.
  -- 
  -- The amount of defending units is calculated by multiplying the amount of detected attacking ground units as part of the detected group
  -- multiplied by the overhead parameter, and rounded up to the smallest integer.
  -- 
  -- Typically, for A2G defenses, values small than 1 will be used. Here are some good values for a couple of aircraft to support CAS operations:
  -- 
  --   - A-10C: 0.15
  --   - Su-34: 0.15
  --   - A-10A: 0.25
  --   - SU-25T: 0.10
  -- 
  -- So generically, the amount of missiles that an aircraft can take will determine its attacking effectiveness. The longer the range of the missiles,
  -- the less risk that the defender may be destroyed by the enemy, thus, the less aircraft needs to be activated in a defense.
  -- 
  -- The **overhead value is set for a Squadron**, and can be **dynamically adjusted** during mission execution, so to adjust the defense overhead when the tactical situation changes.
  --
  -- ### 3.8. Set the squadron **engage limit**.
  -- 
  -- To limit the amount of aircraft to defend against a large group of intruders, an **engage limit** can be defined per squadron.
  -- This limit will avoid an extensive amount of aircraft to engage with the enemy if the attacking ground forces are enormous.
  -- 
  -- Use the method @{#AI_A2G_DISPATCHER.SetSquadronEngageLimit}() to limit the amount of aircraft that will engage with the enemy, per squadron.
  --
  -- ## 4. Set the **fuel threshold**.
  -- 
  -- When an aircraft gets **out of fuel** with only a certain % of fuel left, which is **15% (0.15)** by default, there are two possible actions that can be taken:
  --  - The aircraft will go RTB, and will be replaced with a new aircraft if possible.
  --  - The aircraft will refuel at a tanker, if a tanker has been specified for the squadron.
  -- 
  -- Use the method @{#AI_A2G_DISPATCHER.SetSquadronFuelThreshold}() to set the **squadron fuel threshold** of the aircraft for all squadrons.
  -- 
  -- ## 6. Other configuration options
  -- 
  -- ### 6.1. Set a tactical display panel.
  -- 
  -- Every 30 seconds, a tactical display panel can be shown that illustrates what the status is of the different groups controlled by AI_A2G_DISPATCHER.
  -- Use the method @{#AI_A2G_DISPATCHER.SetTacticalDisplay}() to switch on the tactical display panel. The default will not show this panel.
  -- Note that there may be some performance impact if this panel is shown.
  -- 
  -- ## 10. Default settings.
  -- 
  -- Default settings configure the standard behaviour of the squadrons.
  -- This section a good overview of the different parameters that setup the behaviour of **ALL** the squadrons by default.
  -- Note that default behaviour can be tweaked, and thus, this will change the behaviour of all the squadrons.
  -- Unless there is a specific behaviour set for a specific squadron, the default configured behaviour will be followed.
  -- 
  -- ## 10.1. Default **takeoff** behaviour.
  -- 
  -- The default takeoff behaviour is set to **in the air**, which means that new spawned aircraft will be spawned directly in the air above the airbase by default.
  -- 
  -- **The default takeoff method can be set for ALL squadrons that don't have an individual takeoff method configured.**
  -- 
  --   * @{#AI_A2G_DISPATCHER.SetDefaultTakeoff}() is the generic configuration method to control takeoff by default from the air, hot, cold or from the runway. See the method for further details.
  --   * @{#AI_A2G_DISPATCHER.SetDefaultTakeoffInAir}() will spawn by default new aircraft from the squadron directly in the air.
  --   * @{#AI_A2G_DISPATCHER.SetDefaultTakeoffFromParkingCold}() will spawn by default new aircraft in without running engines at a parking spot at the airfield.
  --   * @{#AI_A2G_DISPATCHER.SetDefaultTakeoffFromParkingHot}() will spawn by default new aircraft in with running engines at a parking spot at the airfield.
  --   * @{#AI_A2G_DISPATCHER.SetDefaultTakeoffFromRunway}() will spawn by default new aircraft at the runway at the airfield.
  -- 
  -- ## 10.2. Default landing behaviour.
  -- 
  -- The default landing behaviour is set to **near the airbase**, which means that returning aircraft will be despawned directly in the air by default.
  -- 
  -- The default landing method can be set for ALL squadrons that don't have an individual landing method configured.
  -- 
  --   * @{#AI_A2G_DISPATCHER.SetDefaultLanding}() is the generic configuration method to control by default landing, namely despawn the aircraft near the airfield in the air, right after landing, or at engine shutdown.
  --   * @{#AI_A2G_DISPATCHER.SetDefaultLandingNearAirbase}() will despawn by default the returning aircraft in the air when near the airfield.
  --   * @{#AI_A2G_DISPATCHER.SetDefaultLandingAtRunway}() will despawn by default the returning aircraft directly after landing at the runway.
  --   * @{#AI_A2G_DISPATCHER.SetDefaultLandingAtEngineShutdown}() will despawn by default the returning aircraft when the aircraft has returned to its parking spot and has turned off its engines.
  -- 
  -- ## 10.3. Default **overhead**.
  -- 
  -- The default overhead is set to **0.25**. That essentially means that for each 4 ground enemies there will be 1 aircraft dispatched.
  -- 
  -- The default overhead value can be set for ALL squadrons that don't have an individual overhead value configured.
  --
  -- Use the @{#AI_A2G_DISPATCHER.SetDefaultOverhead}() method can be used to set the default overhead or defense strength for ALL squadrons.
  --
  -- ## 10.4. Default **grouping**.
  -- 
  -- The default grouping is set to **one aircraft**. That essentially means that there won't be any grouping applied by default.
  -- 
  -- The default grouping value can be set for ALL squadrons that don't have an individual grouping value configured.
  -- 
  -- Use the method @{#AI_A2G_DISPATCHER.SetDefaultGrouping}() to set the **default grouping** of spawned aircraft for all squadrons.
  -- 
  -- ## 10.5. Default RTB fuel threshold.
  -- 
  -- When an aircraft gets **out of fuel** with only a certain % of fuel left, which is **15% (0.15)** by default, it will go RTB, and will be replaced with a new aircraft when applicable.
  -- 
  -- Use the method @{#AI_A2G_DISPATCHER.SetDefaultFuelThreshold}() to set the **default fuel threshold** of spawned aircraft for all squadrons.
  -- 
  -- ## 10.6. Default RTB damage threshold.
  -- 
  -- When an aircraft is **damaged** to a certain %, which is **40% (0.40)** by default, it will go RTB, and will be replaced with a new aircraft when applicable.
  -- 
  -- Use the method @{#AI_A2G_DISPATCHER.SetDefaultDamageThreshold}() to set the **default damage threshold** of spawned aircraft for all squadrons.
  -- 
  -- ## 10.7. Default settings for **patrol**.
  -- 
  -- ### 10.7.1. Default **patrol time Interval**.
  -- 
  -- Patrol dispatching is time event driven, and will evaluate in random time intervals if a new patrol needs to be dispatched.
  -- 
  -- The default patrol time interval is between **180** and **600** seconds.
  -- 
  -- Use the method @{#AI_A2G_DISPATCHER.SetDefaultPatrolTimeInterval}() to set the **default patrol time interval** of dispatched aircraft for ALL squadrons.
  --   
  -- Note that you can still change the patrol limit and patrol time intervals for each patrol individually using 
  -- the @{#AI_A2G_DISPATCHER.SetSquadronPatrolTimeInterval}() method.
  -- 
  -- ### 10.7.2. Default **patrol limit**.
  -- 
  -- Multiple patrol can be airborne at the same time for one squadron, which is controlled by the **patrol limit**.
  -- The **default patrol limit** is 1 patrol per squadron to be airborne at the same time.
  -- Note that the default patrol limit is used when a squadron patrol is defined, and cannot be changed afterwards.
  -- So, ensure that you set the default patrol limit **before** you define or setup the squadron patrol.
  -- 
  -- Use the method @{#AI_A2G_DISPATCHER.SetDefaultPatrolTimeInterval}() to set the **default patrol time interval** of dispatched aircraft patrols for all squadrons.  
  -- Note that you can still change the patrol limit and patrol time intervals for each patrol individually using 
  -- the @{#AI_A2G_DISPATCHER.SetSquadronPatrolTimeInterval}() method.
  -- 
  -- ## 10.7.3. Default tanker for refuelling when executing SEAD, BAI and CAS operations.
  -- 
  -- Instead of sending SEAD, BAI and CAS aircraft to RTB when out of fuel, you can let SEAD, BAI and CAS aircraft refuel in mid air using a tanker.
  -- This greatly increases the efficiency of your SEAD, BAI and CAS operations.
  -- 
  -- In the mission editor, setup a group with task Refuelling. A tanker unit of the correct coalition will be automatically selected.
  -- Then, use the method @{#AI_A2G_DISPATCHER.SetDefaultTanker}() to set the tanker for the dispatcher.
  -- Use the method @{#AI_A2G_DISPATCHER.SetDefaultFuelThreshold}() to set the % left in the defender aircraft tanks when a refuel action is needed.
  -- 
  -- When the tanker specified is alive and in the air, the tanker will be used for refuelling.
  -- 
  -- For example, the following setup will set the default refuel tanker to "Tanker":
  -- 
  -- ![Banner Image](..\Presentations\AI_A2G_DISPATCHER\AI_A2G_DISPATCHER-ME_11.JPG)
  -- 
  --      -- Set the default tanker for refuelling to "Tanker", when the default fuel threshold has reached 90% fuel left.
  --      A2GDispatcher:SetDefaultFuelThreshold( 0.9 )
  --      A2GDispatcher:SetDefaultTanker( "Tanker" )
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
  -- Use the method @{#AI_A2G_DISPATCHER.SetIntercept}() to modify the assumed intercept delay time to calculate a valid interception.
  -- 
  -- ## 10.8.2. Default Disengage Radius.
  -- 
  -- The radius to **disengage any target** when the **distance** of the defender to the **home base** is larger than the specified meters.
  -- The default Disengage Radius is **300km** (300000 meters). Note that the Disengage Radius is applicable to ALL squadrons!
  --   
  -- Use the method @{#AI_A2G_DISPATCHER.SetDisengageRadius}() to modify the default Disengage Radius to another distance setting.
  -- 
  -- ## 11. Airbase capture:
  -- 
  -- Different squadrons can be located at one airbase.
  -- If the airbase gets captured, that is when there is an enemy unit near the airbase and there are no friendlies at the airbase, the airbase will change coalition ownership.
  -- As a result, further SEAD, BAI, and CAS operations from that airbase will stop.
  -- However, the squadron will still stay alive. Any aircraft that is airborne will continue its operations until all airborne aircraft
  -- of the squadron are destroyed. This is to keep consistency of air operations and avoid confusing players.
  -- 
  -- 
  -- 
  -- 
  -- @field #AI_A2G_DISPATCHER
  AI_A2G_DISPATCHER = {
    ClassName = "AI_A2G_DISPATCHER",
    Detection = nil,
  }

  --- Definition of a Squadron.
  -- @type AI_A2G_DISPATCHER.Squadron
  -- @field #string Name The Squadron name.
  -- @field Wrapper.Airbase#AIRBASE Airbase The home airbase.
  -- @field #string AirbaseName The name of the home airbase.
  -- @field Core.Spawn#SPAWN Spawn The spawning object.
  -- @field #number ResourceCount The number of resources available.
  -- @field #list<#string> TemplatePrefixes The list of template prefixes.
  -- @field #boolean Captured true if the squadron is captured.
  -- @field #number Overhead The overhead for the squadron.

  --- List of defense coordinates.
  -- @type AI_A2G_DISPATCHER.DefenseCoordinates
  -- @map <#string,Core.Point#COORDINATE> A list of all defense coordinates mapped per defense coordinate name.

  --- @field #AI_A2G_DISPATCHER.DefenseCoordinates DefenseCoordinates
  AI_A2G_DISPATCHER.DefenseCoordinates = {}

  --- Enumerator for spawns at airbases.
  -- @type AI_A2G_DISPATCHER.Takeoff
  -- @extends Wrapper.Group#GROUP.Takeoff
  
  --- @field #AI_A2G_DISPATCHER.Takeoff Takeoff
  AI_A2G_DISPATCHER.Takeoff = GROUP.Takeoff
  
  --- Defines Landing location.
  -- @field #AI_A2G_DISPATCHER.Landing
  AI_A2G_DISPATCHER.Landing = {
    NearAirbase = 1,
    AtRunway = 2,
    AtEngineShutdown = 3,
  }
  
  --- A defense queue item description.
  -- @type AI_A2G_DISPATCHER.DefenseQueueItem
  -- @field Squadron
  -- @field #AI_A2G_DISPATCHER.Squadron DefenderSquadron The squadron in the queue.
  -- @field DefendersNeeded
  -- @field Defense
  -- @field DefenseTaskType
  -- @field Functional.Detection#DETECTION_BASE AttackerDetection
  -- @field DefenderGrouping
  -- @field #string SquadronName The name of the squadron.
  
  --- Queue of planned defenses to be launched.
  -- This queue exists because defenses must be launched from FARPs, in the air, from airbases, or from carriers.
  -- And some of these platforms have very limited amount of "launching" platforms.
  -- Therefore, this queue concept is introduced that queues each defender request.
  -- Depending on the location of the launching site, the queued defenders will be launched at varying time intervals.
  -- This guarantees that launched defenders are also directly existing ...
  -- @type AI_A2G_DISPATCHER.DefenseQueue
  -- @list<#AI_A2G_DISPATCHER.DefenseQueueItem> DefenseQueueItem A list of all defenses being queued ...
  
  --- @field #AI_A2G_DISPATCHER.DefenseQueue DefenseQueue
  AI_A2G_DISPATCHER.DefenseQueue = {}
  
  --- Defense approach types.
  -- @type AI_A2G_DISPATCHER.DefenseApproach
  AI_A2G_DISPATCHER.DefenseApproach = {
    Random = 1,
    Distance = 2,
  }
  
  --- AI_A2G_DISPATCHER constructor.
  -- This is defining the A2G DISPATCHER for one coalition.
  -- The Dispatcher works with a @{Functional.Detection#DETECTION_BASE} object that is taking of the detection of targets using the EWR units.
  -- The Detection object is polymorphic, depending on the type of detection object chosen, the detection will work differently.
  -- @param #AI_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The DETECTION object that will detects targets using the the Early Warning Radar network.
  -- @return #AI_A2G_DISPATCHER self
  -- @usage
  --   
  --   -- Setup the Detection, using DETECTION_AREAS.
  --   -- First define the SET of GROUPs that are defining the EWR network.
  --   -- Here with prefixes DF CCCP AWACS, DF CCCP EWR.
  --   DetectionSetGroup = SET_GROUP:New()
  --   DetectionSetGroup:FilterPrefixes( { "DF CCCP AWACS", "DF CCCP EWR" } )
  --   DetectionSetGroup:FilterStart()
  --   
  --   -- Define the DETECTION_AREAS, using the DetectionSetGroup, with a 30km grouping radius.
  --   Detection = DETECTION_AREAS:New( DetectionSetGroup, 30000 )
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  --   
  -- 
  function AI_A2G_DISPATCHER:New( Detection )

    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( nil, Detection ) ) -- #AI_A2G_DISPATCHER
    
    self.Detection = Detection -- Functional.Detection#DETECTION_AREAS
    
    self.Detection:FilterCategories( Unit.Category.GROUND_UNIT )
    
    -- This table models the DefenderSquadron templates.
    self.DefenderSquadrons = {} -- The Defender Squadrons.
    self.DefenderSpawns = {}
    self.DefenderTasks = {} -- The Defenders Tasks.
    self.DefenderDefault = {} -- The Defender Default Settings over all Squadrons.
    
    -- TODO: Check detection through radar.
--    self.Detection:FilterCategories( { Unit.Category.GROUND } )
--    self.Detection:InitDetectRadar( false )
--    self.Detection:InitDetectVisual( true )
--    self.Detection:SetRefreshTimeInterval( 30 )
    
    self.SetSendPlayerMessages = false --flash messages to players
    
    self:SetDefenseRadius()
    self:SetDefenseLimit( nil )
    self:SetDefenseApproach( AI_A2G_DISPATCHER.DefenseApproach.Random )
    self:SetIntercept( 300 )  -- A default intercept delay time of 300 seconds.
    self:SetDisengageRadius( 300000 ) -- The default Disengage Radius is 300 km.
    
    self:SetDefaultTakeoff( AI_A2G_DISPATCHER.Takeoff.Air )
    self:SetDefaultTakeoffInAirAltitude( 500 ) -- Default takeoff is 500 meters above ground level (AGL).
    self:SetDefaultLanding( AI_A2G_DISPATCHER.Landing.NearAirbase )
    self:SetDefaultOverhead( 1 )
    self:SetDefaultGrouping( 1 )
    self:SetDefaultFuelThreshold( 0.15, 0 ) -- 15% of fuel remaining in the tank will trigger the aircraft to return to base or refuel.
    self:SetDefaultDamageThreshold( 0.4 ) -- When 40% of damage, go RTB.
    self:SetDefaultPatrolTimeInterval( 180, 600 ) -- Between 180 and 600 seconds.
    self:SetDefaultPatrolLimit( 1 ) -- Maximum one Patrol per squadron.
    
    
    self:AddTransition( "Started", "Assign", "Started" )
    
    --- OnAfter Transition Handler for Event Assign.
    -- @function [parent=#AI_A2G_DISPATCHER] OnAfterAssign
    -- @param #AI_A2G_DISPATCHER self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @param Tasking.Task_A2G#AI_A2G Task
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param #string PlayerName
    
    self:AddTransition( "*", "Patrol", "*" )

    --- Patrol Handler OnBefore for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] OnBeforePatrol
    -- @param #AI_A2G_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Patrol Handler OnAfter for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] OnAfterPatrol
    -- @param #AI_A2G_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Patrol Trigger for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] Patrol
    -- @param #AI_A2G_DISPATCHER self
    
    --- Patrol Asynchronous Trigger for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] __Patrol
    -- @param #AI_A2G_DISPATCHER self
    -- @param #number Delay
    
    self:AddTransition( "*", "Defend", "*" )

    --- Defend Handler OnBefore for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] OnBeforeDefend
    -- @param #AI_A2G_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Defend Handler OnAfter for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] OnAfterDefend
    -- @param #AI_A2G_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Defend Trigger for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] Defend
    -- @param #AI_A2G_DISPATCHER self
    
    --- Defend Asynchronous Trigger for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] __Defend
    -- @param #AI_A2G_DISPATCHER self
    -- @param #number Delay
    
    self:AddTransition( "*", "Engage", "*" )
        
    --- Engage Handler OnBefore for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] OnBeforeEngage
    -- @param #AI_A2G_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Engage Handler OnAfter for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] OnAfterEngage
    -- @param #AI_A2G_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Engage Trigger for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] Engage
    -- @param #AI_A2G_DISPATCHER self
    
    --- Engage Asynchronous Trigger for AI_A2G_DISPATCHER
    -- @function [parent=#AI_A2G_DISPATCHER] __Engage
    -- @param #AI_A2G_DISPATCHER self
    -- @param #number Delay
    
    
    -- Subscribe to the CRASH event so that when planes are shot
    -- by a Unit from the dispatcher, they will be removed from the detection...
    -- This will avoid the detection to still "know" the shot unit until the next detection.
    -- Otherwise, a new defense or engage may happen for an already shot plane!
    
    
    self:HandleEvent( EVENTS.Crash, self.OnEventCrashOrDead )
    self:HandleEvent( EVENTS.Dead, self.OnEventCrashOrDead )
    --self:HandleEvent( EVENTS.RemoveUnit, self.OnEventCrashOrDead )
    
    
    self:HandleEvent( EVENTS.Land )
    self:HandleEvent( EVENTS.EngineShutdown )
    
    -- Handle the situation where the airbases are captured.
    self:HandleEvent( EVENTS.BaseCaptured )
    
    self:SetTacticalDisplay( false )
    
    self.DefenderPatrolIndex = 0
    
    self:SetDefenseReactivityMedium()
    
    self.TakeoffScheduleID = self:ScheduleRepeat( 10, 10, 0, nil, self.ResourceTakeoff, self )
    
    self:__Start( 1 )    
    
    return self
  end


  --- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:onafterStart( From, Event, To )

    self:GetParent( self ).onafterStart( self, From, Event, To )

    -- Spawn the resources.
    for SquadronName, DefenderSquadron in pairs( self.DefenderSquadrons ) do
      DefenderSquadron.Resource = {}
      for Resource = 1, DefenderSquadron.ResourceCount or 0 do
        self:ResourcePark( DefenderSquadron )
      end
      self:I( "Parked resources for squadron " .. DefenderSquadron.Name )
    end
    
  end
  

  --- Locks the DefenseItem from being defended.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string DetectedItemIndex The index of the detected item.
  function AI_A2G_DISPATCHER:Lock( DetectedItemIndex )
    self:F( { DetectedItemIndex = DetectedItemIndex } )
    local DetectedItem = self.Detection:GetDetectedItemByIndex( DetectedItemIndex )
    if DetectedItem then
      self:F( { Locked = DetectedItem } )
      self.Detection:LockDetectedItem( DetectedItem )
    end
  end
  
  
  --- Unlocks the DefenseItem from being defended.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string DetectedItemIndex The index of the detected item.
  function AI_A2G_DISPATCHER:Unlock( DetectedItemIndex )
    self:F( { DetectedItemIndex = DetectedItemIndex } )
    self:F( { Index = self.Detection.DetectedItemsByIndex } )
    local DetectedItem = self.Detection:GetDetectedItemByIndex( DetectedItemIndex )
    if DetectedItem then
      self:F( { Unlocked = DetectedItem } )
      self.Detection:UnlockDetectedItem( DetectedItem )
    end
  end
  
  
  --- Sets maximum zones to be engaged at one time by defenders.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number DefenseLimit The maximum amount of detected items to be engaged at the same time.
  function AI_A2G_DISPATCHER:SetDefenseLimit( DefenseLimit )
    self:F( { DefenseLimit = DefenseLimit } )
    
    self.DefenseLimit = DefenseLimit
  end
  

  --- Sets the method of the tactical approach of the defenses.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number DefenseApproach Use the structure AI_A2G_DISPATCHER.DefenseApproach to set the defense approach.
  -- The default defense approach is AI_A2G_DISPATCHER.DefenseApproach.Random.
  function AI_A2G_DISPATCHER:SetDefenseApproach( DefenseApproach )
    self:F( { DefenseApproach = DefenseApproach } )
    
    self._DefenseApproach = DefenseApproach
  end
  

  --- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:ResourcePark( DefenderSquadron )
    local TemplateID = math.random( 1, #DefenderSquadron.Spawn )
    local Spawn = DefenderSquadron.Spawn[ TemplateID ] -- Core.Spawn#SPAWN
    Spawn:InitGrouping( 1 )
    local SpawnGroup
    if self:IsSquadronVisible( DefenderSquadron.Name ) then
      SpawnGroup = Spawn:SpawnAtAirbase( DefenderSquadron.Airbase, SPAWN.Takeoff.Cold )
      local GroupName = SpawnGroup:GetName()
      DefenderSquadron.Resources = DefenderSquadron.Resources or {}
      DefenderSquadron.Resources[TemplateID] = DefenderSquadron.Resources[TemplateID] or {}
      DefenderSquadron.Resources[TemplateID][GroupName] = {}
      DefenderSquadron.Resources[TemplateID][GroupName] = SpawnGroup
    end
  end


  --- @param #AI_A2G_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_A2G_DISPATCHER:OnEventBaseCaptured( EventData )

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


  --- @param #AI_A2G_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_A2G_DISPATCHER:OnEventCrashOrDead( EventData )
    self.Detection:ForgetDetectedUnit( EventData.IniUnitName ) 
  end


  --- @param #AI_A2G_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_A2G_DISPATCHER:OnEventLand( EventData )
    self:F( "Landed" )
    local DefenderUnit = EventData.IniUnit
    local Defender = EventData.IniGroup
    local Squadron = self:GetSquadronFromDefender( Defender )
    if Squadron then
      self:F( { SquadronName = Squadron.Name } )
      local LandingMethod = self:GetSquadronLanding( Squadron.Name )
      
      if LandingMethod == AI_A2G_DISPATCHER.Landing.AtRunway then
        local DefenderSize = Defender:GetSize()
        if DefenderSize == 1 then
          self:RemoveDefenderFromSquadron( Squadron, Defender )
        end
        DefenderUnit:Destroy()
        self:ResourcePark( Squadron, Defender )
        return
      end
      if DefenderUnit:GetLife() ~= DefenderUnit:GetLife0() then
        -- Damaged units cannot be repaired anymore.
        DefenderUnit:Destroy()
        return
      end
    end 
  end
  

  --- @param #AI_A2G_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_A2G_DISPATCHER:OnEventEngineShutdown( EventData )
    local DefenderUnit = EventData.IniUnit
    local Defender = EventData.IniGroup
    local Squadron = self:GetSquadronFromDefender( Defender )
    if Squadron then
      self:F( { SquadronName = Squadron.Name } )
      local LandingMethod = self:GetSquadronLanding( Squadron.Name )
      if LandingMethod == AI_A2G_DISPATCHER.Landing.AtEngineShutdown and
        not DefenderUnit:InAir() then
        local DefenderSize = Defender:GetSize()
        if DefenderSize == 1 then
          self:RemoveDefenderFromSquadron( Squadron, Defender )
        end
        DefenderUnit:Destroy()
        self:ResourcePark( Squadron, Defender )
      end
    end 
  end


  do -- Manage the defensive behaviour
  
    --- @param #AI_A2G_DISPATCHER self
    -- @param #string DefenseCoordinateName The name of the coordinate to be defended by A2G defenses.
    -- @param Core.Point#COORDINATE DefenseCoordinate The coordinate to be defended by A2G defenses.
    function AI_A2G_DISPATCHER:AddDefenseCoordinate( DefenseCoordinateName, DefenseCoordinate )
      self.DefenseCoordinates[DefenseCoordinateName] = DefenseCoordinate
    end
    

    --- @param #AI_A2G_DISPATCHER self
    function AI_A2G_DISPATCHER:SetDefenseReactivityLow()
      self.DefenseReactivity = 0.05
    end
    

    --- @param #AI_A2G_DISPATCHER self
    function AI_A2G_DISPATCHER:SetDefenseReactivityMedium()
      self.DefenseReactivity = 0.15
    end
    

    --- @param #AI_A2G_DISPATCHER self
    function AI_A2G_DISPATCHER:SetDefenseReactivityHigh()
      self.DefenseReactivity = 0.5
    end
  
  end
  

  --- Define the radius to disengage any target when the distance to the home base is larger than the specified meters.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number DisengageRadius (Optional, Default = 300000) The radius to disengage a target when too far from the home base.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Set 50km as the Disengage Radius.
  --   A2GDispatcher:SetDisengageRadius( 50000 )
  --   
  --   -- Set 100km as the Disengage Radius.
  --   A2GDispatcher:SetDisengageRadius() -- 300000 is the default value.
  --   
  function AI_A2G_DISPATCHER:SetDisengageRadius( DisengageRadius )

    self.DisengageRadius = DisengageRadius or 300000
  
    return self
  end
  
  
  --- Define the defense radius to check if a target can be engaged by a squadron group for SEAD, BAI, or CAS for defense.
  -- When targets are detected that are still really far off, you don't want the AI_A2G_DISPATCHER to launch defenders, as they might need to travel too far.
  -- You want it to wait until a certain defend radius is reached, which is calculated as:
  --   1. the **distance of the closest airbase to target**, being smaller than the **Defend Radius**.
  --   2. the **distance to any defense reference point**.
  -- 
  -- The **default** defense radius is defined as **400000** or **40km**. Override the default defense radius when the era of the warfare is early, or, 
  -- when you don't want to let the AI_A2G_DISPATCHER react immediately when a certain border or area is not being crossed.
  -- 
  -- Use the method @{#AI_A2G_DISPATCHER.SetDefendRadius}() to set a specific defend radius for all squadrons,
  -- **the Defense Radius is defined for ALL squadrons which are operational.**
  -- 
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number DefenseRadius (Optional, Default = 200000) The defense radius to engage detected targets from the nearest capable and available squadron airbase.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection ) 
  --   
  --   -- Set 100km as the radius to defend from detected targets from the nearest airbase.
  --   A2GDispatcher:SetDefendRadius( 100000 )
  --   
  --   -- Set 200km as the radius to defend.
  --   A2GDispatcher:SetDefendRadius() -- 200000 is the default value.
  --   
  function AI_A2G_DISPATCHER:SetDefenseRadius( DefenseRadius )

    self.DefenseRadius = DefenseRadius or 100000
    
    self.Detection:SetAcceptRange( self.DefenseRadius ) 
  
    return self
  end
  
  
  --- Define a border area to simulate a **cold war** scenario.
  -- A **cold war** is one where Patrol aircraft patrol their territory but will not attack enemy aircraft or launch GCI aircraft unless enemy aircraft enter their territory. In other words the EWR may detect an enemy aircraft but will only send aircraft to attack it if it crosses the border.
  -- A **hot war** is one where Patrol aircraft will intercept any detected enemy aircraft and GCI aircraft will launch against detected enemy aircraft without regard for territory. In other words if the ground radar can detect the enemy aircraft then it will send Patrol and GCI aircraft to attack it.
  -- If it's a cold war then the **borders of red and blue territory** need to be defined using a @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE}. This method needs to be used for this.
  -- If a hot war is chosen then **no borders** actually need to be defined using the helicopter units other than it makes it easier sometimes for the mission maker to envisage where the red and blue territories roughly are. In a hot war the borders are effectively defined by the ground based radar coverage of a coalition. Set the noborders parameter to 1
  -- @param #AI_A2G_DISPATCHER self
  -- @param Core.Zone#ZONE_BASE BorderZone An object derived from ZONE_BASE, or a list of objects derived from ZONE_BASE.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  --   -- Set one ZONE_POLYGON object as the border for the A2G dispatcher.
  --   local BorderZone = ZONE_POLYGON( "CCCP Border", GROUP:FindByName( "CCCP Border" ) ) -- The GROUP object is a late activate helicopter unit.
  --   A2GDispatcher:SetBorderZone( BorderZone )
  --   
  -- or
  --   
  --   -- Set two ZONE_POLYGON objects as the border for the A2G dispatcher.
  --   local BorderZone1 = ZONE_POLYGON( "CCCP Border1", GROUP:FindByName( "CCCP Border1" ) ) -- The GROUP object is a late activate helicopter unit.
  --   local BorderZone2 = ZONE_POLYGON( "CCCP Border2", GROUP:FindByName( "CCCP Border2" ) ) -- The GROUP object is a late activate helicopter unit.
  --   A2GDispatcher:SetBorderZone( { BorderZone1, BorderZone2 } )
  --   
  function AI_A2G_DISPATCHER:SetBorderZone( BorderZone )

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
  -- @param #AI_A2G_DISPATCHER self
  -- @param #boolean TacticalDisplay Provide a value of **true** to display every 30 seconds a tactical overview.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the Tactical Display for debug mode.
  --   A2GDispatcher:SetTacticalDisplay( true )
  --   
  function AI_A2G_DISPATCHER:SetTacticalDisplay( TacticalDisplay )
    
    self.TacticalDisplay = TacticalDisplay
    
    return self
  end  


  --- Set the default damage threshold when defenders will RTB.
  -- The default damage threshold is by default set to 40%, which means that when the aircraft is 40% damaged, it will go RTB.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number DamageThreshold A decimal number between 0 and 1, that expresses the % of damage when the aircraft will go RTB.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default damage threshold.
  --   A2GDispatcher:SetDefaultDamageThreshold( 0.90 ) -- Go RTB when the aircraft is 90% damaged.
  --   
  function AI_A2G_DISPATCHER:SetDefaultDamageThreshold( DamageThreshold )
    
    self.DefenderDefault.DamageThreshold = DamageThreshold
    
    return self
  end  


  --- Set the default Patrol time interval for squadrons, which will be used to determine a random Patrol timing.
  -- The default Patrol time interval is between 180 and 600 seconds.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number PatrolMinSeconds The minimum amount of seconds for the random time interval.
  -- @param #number PatrolMaxSeconds The maximum amount of seconds for the random time interval.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default Patrol time interval.
  --   A2GDispatcher:SetDefaultPatrolTimeInterval( 300, 1200 ) -- Between 300 and 1200 seconds.
  --   
  function AI_A2G_DISPATCHER:SetDefaultPatrolTimeInterval( PatrolMinSeconds, PatrolMaxSeconds )
    
    self.DefenderDefault.PatrolMinSeconds = PatrolMinSeconds
    self.DefenderDefault.PatrolMaxSeconds = PatrolMaxSeconds
    
    return self
  end


  --- Set the default Patrol limit for squadrons, which will be used to determine how many Patrol can be airborne at the same time for the squadron.
  -- The default Patrol limit is 1 Patrol, which means one Patrol group being spawned.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number PatrolLimit The maximum amount of Patrol that can be airborne at the same time for the squadron.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default Patrol limit.
  --   A2GDispatcher:SetDefaultPatrolLimit( 2 ) -- Maximum 2 Patrol per squadron.
  --   
  function AI_A2G_DISPATCHER:SetDefaultPatrolLimit( PatrolLimit )
    
    self.DefenderDefault.PatrolLimit = PatrolLimit
    
    return self
  end  


  --- Set the default engage limit for squadrons, which will be used to determine how many air units will engage at the same time with the enemy.
  -- The default eatrol limit is 1, which means one eatrol group maximum per squadron.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number EngageLimit The maximum engages that can be done at the same time per squadron.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default Patrol limit.
  --   A2GDispatcher:SetDefaultEngageLimit( 2 ) -- Maximum 2 engagements with the enemy per squadron.
  --   
  function AI_A2G_DISPATCHER:SetDefaultEngageLimit( EngageLimit )
    
    self.DefenderDefault.EngageLimit = EngageLimit
    
    return self
  end  


  function AI_A2G_DISPATCHER:SetIntercept( InterceptDelay )
    
    self.DefenderDefault.InterceptDelay = InterceptDelay
    
    local Detection = self.Detection -- Functional.Detection#DETECTION_AREAS
    Detection:SetIntercept( true, InterceptDelay )
    
    return self
  end  


  --- Calculates which defender friendlies are nearby the area, to help protect the area.
  -- @param #AI_A2G_DISPATCHER self
  -- @param DetectedItem
  -- @return #table A list of the defender friendlies nearby, sorted by distance.
  function AI_A2G_DISPATCHER:GetDefenderFriendliesNearBy( DetectedItem )
  
--    local DefenderFriendliesNearBy = self.Detection:GetFriendliesDistance( DetectedItem )

    local DefenderFriendliesNearBy = {}
    
    local DetectionCoordinate = self.Detection:GetDetectedItemCoordinate( DetectedItem )
    
    local ScanZone = ZONE_RADIUS:New( "ScanZone", DetectionCoordinate:GetVec2(), self.DefenseRadius )
    
    ScanZone:Scan( Object.Category.UNIT, { Unit.Category.AIRPLANE, Unit.Category.HELICOPTER } )
    
    local DefenderUnits = ScanZone:GetScannedUnits()
    
    for DefenderUnitID, DefenderUnit in pairs( DefenderUnits ) do
      local DefenderUnit = UNIT:FindByName( DefenderUnit:getName() )
      
      DefenderFriendliesNearBy[#DefenderFriendliesNearBy+1] = DefenderUnit
    end
    
    
    return DefenderFriendliesNearBy
  end


  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:GetDefenderTasks()
    return self.DefenderTasks or {}
  end
  

  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:GetDefenderTask( Defender )
    return self.DefenderTasks[Defender]
  end


  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:GetDefenderTaskFsm( Defender )
    return self:GetDefenderTask( Defender ).Fsm
  end
  
  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:GetDefenderTaskTarget( Defender )
    return self:GetDefenderTask( Defender ).Target
  end
  
  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:GetDefenderTaskSquadronName( Defender )
    return self:GetDefenderTask( Defender ).SquadronName
  end

  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:ClearDefenderTask( Defender )
    if Defender:IsAlive() and self.DefenderTasks[Defender] then
      local Target = self.DefenderTasks[Defender].Target
      local Message = "Clearing (" .. self.DefenderTasks[Defender].Type .. ") " 
      Message = Message .. Defender:GetName() 
      if Target then
        Message = Message .. ( Target and ( " from " .. Target.Index .. " [" .. Target.Set:Count() .. "]" ) ) or ""
      end
      self:F( { Target = Message } )
    end
    self.DefenderTasks[Defender] = nil
    return self
  end

  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:ClearDefenderTaskTarget( Defender )
    
    local DefenderTask = self:GetDefenderTask( Defender )
    
    if Defender:IsAlive() and DefenderTask then
      local Target = DefenderTask.Target
      local Message = "Clearing (" .. DefenderTask.Type .. ") " 
      Message = Message .. Defender:GetName() 
      if Target then
        Message = Message .. ( Target and ( " from " .. Target.Index .. " [" .. Target.Set:Count() .. "]" ) ) or ""
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

  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:SetDefenderTask( SquadronName, Defender, Type, Fsm, Target, Size )
  
    self:F( { SquadronName = SquadronName, Defender = Defender:GetName() } )
  
    self.DefenderTasks[Defender] = self.DefenderTasks[Defender] or {}
    self.DefenderTasks[Defender].Type = Type
    self.DefenderTasks[Defender].Fsm = Fsm
    self.DefenderTasks[Defender].SquadronName = SquadronName
    self.DefenderTasks[Defender].Size = Size

    if Target then
      self:SetDefenderTaskTarget( Defender, Target )
    end
    return self
  end
  
  
  ---
  -- @param #AI_A2G_DISPATCHER self
  -- @param Wrapper.Group#GROUP AIGroup
  function AI_A2G_DISPATCHER:SetDefenderTaskTarget( Defender, AttackerDetection )
    
    local Message = "(" .. self.DefenderTasks[Defender].Type .. ") " 
    Message = Message .. Defender:GetName() 
    Message = Message .. ( AttackerDetection and ( " target " .. AttackerDetection.Index .. " [" .. AttackerDetection.Set:Count() .. "]" ) ) or ""
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
  -- The name of the squadron given acts as the **squadron key** in the AI\_A2G\_DISPATCHER:Squadron...() methods.
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
  -- @param #AI_A2G_DISPATCHER self
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
  -- 
  -- @usage
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  -- @usage
  --   -- This will create squadron "Squadron1" at "Batumi" airbase, and will use plane types "SQ1" and has 40 planes in stock...  
  --   A2GDispatcher:SetSquadron( "Squadron1", "Batumi", "SQ1", 40 )
  --   
  -- @usage
  --   -- This will create squadron "Sq 1" at "Batumi" airbase, and will use plane types "Mig-29" and "Su-27" and has 20 planes in stock...
  --   -- Note that in this implementation, the A2G dispatcher will select a random plane type when a new plane (group) needs to be spawned for defenses.
  --   -- Note the usage of the {} for the airplane templates list.
  --   A2GDispatcher:SetSquadron( "Sq 1", "Batumi", { "Mig-29", "Su-27" }, 40 )
  --   
  -- @usage
  --   -- This will create 2 squadrons "104th" and "23th" at "Batumi" airbase, and will use plane types "Mig-29" and "Su-27" respectively and each squadron has 10 planes in stock...
  --   A2GDispatcher:SetSquadron( "104th", "Batumi", "Mig-29", 10 )
  --   A2GDispatcher:SetSquadron( "23th", "Batumi", "Su-27", 10 )
  --   
  -- @usage
  --   -- This is an example like the previous, but now with infinite resources.
  --   -- The ResourceCount parameter is not given in the SetSquadron method.
  --   A2GDispatcher:SetSquadron( "104th", "Batumi", "Mig-29" )
  --   A2GDispatcher:SetSquadron( "23th", "Batumi", "Su-27" )
  --   
  --   
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadron( SquadronName, AirbaseName, TemplatePrefixes, ResourceCount )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 

    local DefenderSquadron = self.DefenderSquadrons[SquadronName]
    
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
        DefenderSquadron.Spawn[#DefenderSquadron.Spawn+1] = self.DefenderSpawns[SpawnTemplate]
      end
    end
    DefenderSquadron.ResourceCount = ResourceCount
    DefenderSquadron.TemplatePrefixes = TemplatePrefixes
    DefenderSquadron.Captured = false -- Not captured. This flag will be set to true, when the airbase where the squadron is located, is captured.

    self:SetSquadronTakeoffInterval( SquadronName, 0 )
   
    self:F( { Squadron = {SquadronName, AirbaseName, TemplatePrefixes, ResourceCount } } )
    
    return self
  end
  

  --- Get an item from the Squadron table.
  -- @param #AI_A2G_DISPATCHER self
  -- @return #table
  function AI_A2G_DISPATCHER:GetSquadron( SquadronName )

    local DefenderSquadron = self.DefenderSquadrons[SquadronName]
    
    if not DefenderSquadron then
      error( "Unknown Squadron:" .. SquadronName )
    end
    
    return DefenderSquadron
  end

  --- Get a resource count from a specific squadron
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string Squadron Name of the squadron.
  -- @return #number Number of airframes available or nil if the squadron does not exist
  function AI_A2G_DISPATCHER:QuerySquadron(Squadron)
    local Squadron = self:GetSquadron(Squadron)
    if Squadron.ResourceCount then
      self:T2(string.format("%s = %s",Squadron.Name,Squadron.ResourceCount))
      return Squadron.ResourceCount
    end
    self:F({Squadron = Squadron.Name,SquadronResourceCount = Squadron.ResourceCount})
    return nil
  end
  
  --- Set the Squadron visible before startup of the dispatcher.
  -- All planes will be spawned as uncontrolled on the parking spot.
  -- They will lock the parking spot.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Set the Squadron visible before startup of dispatcher.
  --        A2GDispatcher:SetSquadronVisible( "Mineralnye" )
  --        
  -- TODO: disabling because of bug in queueing.       
--  function AI_A2G_DISPATCHER:SetSquadronVisible( SquadronName )
--  
--    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
--    
--    local DefenderSquadron = self:GetSquadron( SquadronName )
--    
--    DefenderSquadron.Uncontrolled = true
--    self:SetSquadronTakeoffFromParkingCold( SquadronName )
--    self:SetSquadronLandingAtEngineShutdown( SquadronName )
--
--    for SpawnTemplate, DefenderSpawn in pairs( self.DefenderSpawns ) do
--      DefenderSpawn:InitUnControlled()
--    end
--
--  end


  --- Check if the Squadron is visible before startup of the dispatcher.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #boolean true if visible.
  -- @usage
  -- 
  --        -- Set the Squadron visible before startup of dispatcher.
  --        local IsVisible = A2GDispatcher:IsSquadronVisible( "Mineralnye" )
  --        
  function AI_A2G_DISPATCHER:IsSquadronVisible( SquadronName )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    
    local DefenderSquadron = self:GetSquadron( SquadronName )

    if DefenderSquadron then
      return DefenderSquadron.Uncontrolled == true
    end
    
    return nil
    
  end

  
  --- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number TakeoffInterval  Only Takeoff new units each specified interval in seconds in 10 seconds steps.
  -- @usage
  -- 
  --        -- Set the Squadron Takeoff interval every 60 seconds for squadron "SQ50", which is good for a FARP cold start.
  --        A2GDispatcher:SetSquadronTakeoffInterval( "SQ50", 60 )
  --        
  function AI_A2G_DISPATCHER:SetSquadronTakeoffInterval( SquadronName, TakeoffInterval )

    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    
    local DefenderSquadron = self:GetSquadron( SquadronName )

    if DefenderSquadron then
      DefenderSquadron.TakeoffInterval = TakeoffInterval or 0
      DefenderSquadron.TakeoffTime = 0
    end
    
  end
  
  
  --- Set the squadron patrol parameters for a specific task type.  
  -- Mission designers should not use this method, instead use the below methods. This method is used by the below methods.
  -- 
  --   - @{#AI_A2G_DISPATCHER:SetSquadronSeadPatrolInterval} for SEAD tasks.
  --   - @{#AI_A2G_DISPATCHER:SetSquadronSeadPatrolInterval} for CAS tasks.
  --   - @{#AI_A2G_DISPATCHER:SetSquadronSeadPatrolInterval} for BAI tasks.
  --   
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number PatrolLimit (optional) The maximum amount of Patrol groups to be spawned. Note that each Patrol is a group, and can consist of 1 to 4 aircraft. The default is 1 Patrol group.
  -- @param #number LowInterval (optional) The minimum time boundary in seconds when a new Patrol will be spawned. The default is 180 seconds.
  -- @param #number HighInterval (optional) The maximum time boundary in seconds when a new Patrol will be spawned. The default is 600 seconds.
  -- @param #number Probability Is not in use, you can skip this parameter.
  -- @param #string DefenseTaskType Should contain "SEAD", "CAS" or "BAI".
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronSeadPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        A2GDispatcher:SetSquadronPatrolInterval( "Mineralnye", 2, 30, 60, 1, "SEAD" )
  -- 
  function AI_A2G_DISPATCHER:SetSquadronPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability, DefenseTaskType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    local Patrol = DefenderSquadron[DefenseTaskType]
    if Patrol then
      Patrol.LowInterval = LowInterval or 180
      Patrol.HighInterval = HighInterval or 600
      Patrol.Probability = Probability or 1
      Patrol.PatrolLimit = PatrolLimit or 1
      Patrol.Scheduler = Patrol.Scheduler or SCHEDULER:New( self ) 
      local Scheduler = Patrol.Scheduler -- Core.Scheduler#SCHEDULER
      local ScheduleID = Patrol.ScheduleID
      local Variance = ( Patrol.HighInterval - Patrol.LowInterval ) / 2
      local Repeat = Patrol.LowInterval + Variance
      local Randomization = Variance / Repeat
      local Start = math.random( 1, Patrol.HighInterval )
      
      if ScheduleID then
        Scheduler:Stop( ScheduleID )
      end
      
      Patrol.ScheduleID = Scheduler:Schedule( self, self.SchedulerPatrol, { SquadronName }, Start, Repeat, Randomization )
    else
      error( "This squadron does not exist:" .. SquadronName )
    end

  end


  --- Set the squadron Patrol parameters for SEAD tasks.  
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number PatrolLimit (optional) The maximum amount of Patrol groups to be spawned. Each Patrol group can consist of 1 to 4 aircraft. The default is 1 Patrol group.
  -- @param #number LowInterval (optional) The minimum time in seconds between new Patrols being spawned. The default is 180 seconds.
  -- @param #number HighInterval (optional) The maximum ttime in seconds between new Patrols being spawned. The default is 600 seconds.
  -- @param #number Probability Is not in use, you can skip this parameter.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronSeadPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        A2GDispatcher:SetSquadronSeadPatrolInterval( "Mineralnye", 2, 30, 60, 1 )
  -- 
  function AI_A2G_DISPATCHER:SetSquadronSeadPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability )

    self:SetSquadronPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability, "SEAD" )  

  end
  
  
  --- Set the squadron Patrol parameters for CAS tasks.  
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number PatrolLimit (optional) The maximum amount of Patrol groups to be spawned. Each Patrol group can consist of 1 to 4 aircraft. The default is 1 Patrol group.
  -- @param #number LowInterval (optional) The minimum time in seconds between new Patrols being spawned. The default is 180 seconds.
  -- @param #number HighInterval (optional) The maximum time in seconds between new Patrols being spawned. The default is 600 seconds.
  -- @param #number Probability Is not in use, you can skip this parameter.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronCasPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        A2GDispatcher:SetSquadronCasPatrolInterval( "Mineralnye", 2, 30, 60, 1 )
  -- 
  function AI_A2G_DISPATCHER:SetSquadronCasPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability )

    self:SetSquadronPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability, "CAS" )  

  end
  
  
  --- Set the squadron Patrol parameters for BAI tasks.  
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number PatrolLimit (optional) The maximum amount of Patrol groups to be spawned. Each Patrol group can consist of 1 to 4 aircraft. The default is 1 Patrol group.
  -- @param #number LowInterval (optional) The minimum time in seconds between new Patrols being spawned. The default is 180 seconds.
  -- @param #number HighInterval (optional) The maximum time in seconds between new Patrols being spawned. The default is 600 seconds.
  -- @param #number Probability Is not in use, you can skip this parameter.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronBaiPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        A2GDispatcher:SetSquadronBaiPatrolInterval( "Mineralnye", 2, 30, 60, 1 )
  -- 
  function AI_A2G_DISPATCHER:SetSquadronBaiPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability )

    self:SetSquadronPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability, "BAI" )  

  end
  
  
  ---
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:GetPatrolDelay( SquadronName )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Patrol = self.DefenderSquadrons[SquadronName].Patrol or {}

    local DefenderSquadron = self:GetSquadron( SquadronName )

    local Patrol = self.DefenderSquadrons[SquadronName].Patrol
    if Patrol then
      return math.random( Patrol.LowInterval, Patrol.HighInterval )
    else
      error( "This squadron does not exist:" .. SquadronName )
    end
  end


  ---
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #table DefenderSquadron
  function AI_A2G_DISPATCHER:CanPatrol( SquadronName, DefenseTaskType )
    self:F({SquadronName = SquadronName})
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    if DefenderSquadron.Captured == false then -- We can only spawn new Patrol if the base has not been captured.
    
      if ( not DefenderSquadron.ResourceCount ) or ( DefenderSquadron.ResourceCount and DefenderSquadron.ResourceCount > 0  ) then -- And, if there are sufficient resources.

        local Patrol = DefenderSquadron[DefenseTaskType]
        if Patrol and Patrol.Patrol == true then
          local PatrolCount = self:CountPatrolAirborne( SquadronName, DefenseTaskType )
          self:F( { PatrolCount = PatrolCount, PatrolLimit = Patrol.PatrolLimit, PatrolProbability = Patrol.Probability } )
          if PatrolCount < Patrol.PatrolLimit then
            local Probability = math.random()
            if Probability <= Patrol.Probability then
              return DefenderSquadron, Patrol
            end
          end
        else
          self:F( "No patrol for " .. SquadronName )
        end
      end
    end
    return nil
  end


  ---
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #table DefenderSquadron
  function AI_A2G_DISPATCHER:CanDefend( SquadronName, DefenseTaskType )
    self:F({SquadronName = SquadronName, DefenseTaskType})
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    if DefenderSquadron.Captured == false then -- We can only spawn new defense if the home airbase has not been captured.
    
      if ( not DefenderSquadron.ResourceCount ) or ( DefenderSquadron.ResourceCount and DefenderSquadron.ResourceCount > 0  ) then -- And, if there are sufficient resources.
        if DefenderSquadron[DefenseTaskType] and ( DefenderSquadron[DefenseTaskType].Defend == true ) then
          return DefenderSquadron, DefenderSquadron[DefenseTaskType]
        end
      end
    end
    return nil
  end


  --- Set the squadron engage limit for a specific task type.  
  -- Mission designers should not use this method, instead use the below methods. This method is used by the below methods.
  -- 
  --   - @{#AI_A2G_DISPATCHER:SetSquadronSeadEngageLimit} for SEAD tasks.
  --   - @{#AI_A2G_DISPATCHER:SetSquadronSeadEngageLimit} for CAS tasks.
  --   - @{#AI_A2G_DISPATCHER:SetSquadronSeadEngageLimit} for BAI tasks.
  --   
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageLimit The maximum amount of groups to engage with the enemy for this squadron.
  -- @param #string DefenseTaskType Should contain "SEAD", "CAS" or "BAI".
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronEngageLimit( "Mineralnye", 2, "SEAD" ) -- Engage maximum 2 groups with the enemy for SEAD defense.
  -- 
  function AI_A2G_DISPATCHER:SetSquadronEngageLimit( SquadronName, EngageLimit, DefenseTaskType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    local Defense = DefenderSquadron[DefenseTaskType]
    if Defense then
      Defense.EngageLimit = EngageLimit or 1
    else
      error( "This squadron does not exist:" .. SquadronName )
    end

  end


  --- Set a squadron to engage for suppression of air defenses, when a defense point is under attack.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the SEAD task can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the SEAD task can be executed.
  -- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
  -- @param #number EngageAltType The altitude type when engaging, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @usage 
  -- 
  --        -- SEAD Squadron execution.
  --        A2GDispatcher:SetSquadronSead( "Mozdok", 900, 1200, 4000, 5000, "BARO" )
  --        A2GDispatcher:SetSquadronSead( "Novo", 900, 2100, 6000, 9000, "BARO" )
  --        A2GDispatcher:SetSquadronSead( "Maykop", 900, 1200, 30, 100, "RADIO" )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronSead2( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.SEAD = DefenderSquadron.SEAD or {}
    
    local Sead = DefenderSquadron.SEAD
    Sead.Name = SquadronName
    Sead.EngageMinSpeed = EngageMinSpeed
    Sead.EngageMaxSpeed = EngageMaxSpeed
    Sead.EngageFloorAltitude = EngageFloorAltitude or 500
    Sead.EngageCeilingAltitude = EngageCeilingAltitude or 1000
    Sead.EngageAltType = EngageAltType
    Sead.Defend = true
    
    self:I( { SEAD = { SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType } } )
    
    return self
  end


  --- Set a squadron to engage for suppression of air defenses, when a defense point is under attack.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the SEAD task can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the SEAD task can be executed.
  -- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
  -- @usage 
  -- 
  --        -- SEAD Squadron execution.
  --        A2GDispatcher:SetSquadronSead( "Mozdok", 900, 1200, 4000, 5000 )
  --        A2GDispatcher:SetSquadronSead( "Novo", 900, 2100, 6000, 8000 )
  --        A2GDispatcher:SetSquadronSead( "Maykop", 900, 1200, 6000, 10000 )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronSead( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude )

    return self:SetSquadronSead2( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, "RADIO" )  
  end


  --- Set the squadron SEAD engage limit.  
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageLimit The maximum amount of groups to engage with the enemy for this squadron.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronSeadEngageLimit( "Mineralnye", 2 ) -- Engage maximum 2 groups with the enemy for SEAD defense.
  -- 
  function AI_A2G_DISPATCHER:SetSquadronSeadEngageLimit( SquadronName, EngageLimit )

    self:SetSquadronEngageLimit( SquadronName, EngageLimit, "SEAD" )  

  end
  

  --- Set a Sead patrol for a Squadron.
  -- The Sead patrol will start a patrol of the aircraft at a specified zone, and will engage when commanded.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the Patrol will be executed.
  -- @param #number PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the cap can be executed.
  -- @param #number PatrolFloorAltitude (optional, default = 1000m ) The minimum altitude at which the cap can be executed.
  -- @param #number PatrolCeilingAltitude (optional, default = 1500m ) The maximum altitude at which the cap can be executed.
  -- @param #number PatrolAltType The altitude type when patrolling, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the engage can be executed.
  -- @param #number EngageFloorAltitude (optional, default = 1000m ) The minimum altitude at which the engage can be executed.
  -- @param #number EngageCeilingAltitude (optional, default = 1500m ) The maximum altitude at which the engage can be executed.
  -- @param #number EngageAltType The altitude type when engaging, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Sead Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronSeadPatrol2( "Mineralnye", PatrolZoneEast, 500, 600, 4000, 10000, "BARO", 800, 900, 2000, 3000, "RADIO", )
  --        
  function AI_A2G_DISPATCHER:SetSquadronSeadPatrol2( SquadronName, Zone, PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.SEAD = DefenderSquadron.SEAD or {}
    
    local SeadPatrol = DefenderSquadron.SEAD
    SeadPatrol.Name = SquadronName
    SeadPatrol.Zone = Zone
    SeadPatrol.PatrolFloorAltitude = PatrolFloorAltitude
    SeadPatrol.PatrolCeilingAltitude = PatrolCeilingAltitude
    SeadPatrol.EngageFloorAltitude = EngageFloorAltitude
    SeadPatrol.EngageCeilingAltitude = EngageCeilingAltitude
    SeadPatrol.PatrolMinSpeed = PatrolMinSpeed
    SeadPatrol.PatrolMaxSpeed = PatrolMaxSpeed
    SeadPatrol.EngageMinSpeed = EngageMinSpeed
    SeadPatrol.EngageMaxSpeed = EngageMaxSpeed
    SeadPatrol.PatrolAltType = PatrolAltType
    SeadPatrol.EngageAltType = EngageAltType
    SeadPatrol.Patrol = true

    self:SetSquadronPatrolInterval( SquadronName, self.DefenderDefault.PatrolLimit, self.DefenderDefault.PatrolMinSeconds, self.DefenderDefault.PatrolMaxSeconds, 1, "SEAD" )
    
    self:I( { SEAD = { Zone:GetName(), PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType } } )
  end
  
  
  --- Set a Sead patrol for a Squadron.
  -- The Sead patrol will start a patrol of the aircraft at a specified zone, and will engage when commanded.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the Patrol will be executed.
  -- @param #number FloorAltitude (optional, default = 1000m ) The minimum altitude at which the cap can be executed.
  -- @param #number CeilingAltitude (optional, default = 1500m ) The maximum altitude at which the cap can be executed.
  -- @param #number PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the cap can be executed.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the engage can be executed.
  -- @param #number AltType The altitude type, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Sead Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronSeadPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        
  function AI_A2G_DISPATCHER:SetSquadronSeadPatrol( SquadronName, Zone, FloorAltitude, CeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, AltType )

    self:SetSquadronSeadPatrol2( SquadronName, Zone, PatrolMinSpeed, PatrolMaxSpeed, FloorAltitude, CeilingAltitude, AltType, EngageMinSpeed, EngageMaxSpeed, FloorAltitude, CeilingAltitude, AltType )
  
  end
 

  --- Set a squadron to engage for close air support, when a defense point is under attack.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the CAS task can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the CAS task can be executed.
  -- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
  -- @param #number EngageAltType The altitude type when engaging, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @usage 
  -- 
  --        -- CAS Squadron execution.
  --        A2GDispatcher:SetSquadronCas( "Mozdok", 900, 1200, 4000, 5000, "BARO" )
  --        A2GDispatcher:SetSquadronCas( "Novo", 900, 2100, 6000, 9000, "BARO" )
  --        A2GDispatcher:SetSquadronCas( "Maykop", 900, 1200, 30, 100, "RADIO" )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronCas2( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.CAS = DefenderSquadron.CAS or {}
    
    local Cas = DefenderSquadron.CAS
    Cas.Name = SquadronName
    Cas.EngageMinSpeed = EngageMinSpeed
    Cas.EngageMaxSpeed = EngageMaxSpeed
    Cas.EngageFloorAltitude = EngageFloorAltitude or 500
    Cas.EngageCeilingAltitude = EngageCeilingAltitude or 1000
    Cas.EngageAltType = EngageAltType
    Cas.Defend = true
    
    self:I( { CAS = { SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType } } )
    
    return self
  end


  --- Set a squadron to engage for close air support, when a defense point is under attack.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the CAS task can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the CAS task can be executed.
  -- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
  -- @usage 
  -- 
  --        -- CAS Squadron execution.
  --        A2GDispatcher:SetSquadronCas( "Mozdok", 900, 1200, 4000, 5000 )
  --        A2GDispatcher:SetSquadronCas( "Novo", 900, 2100, 6000, 8000 )
  --        A2GDispatcher:SetSquadronCas( "Maykop", 900, 1200, 6000, 10000 )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronCas( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude )

    return self:SetSquadronCas2( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, "RADIO" )  
  end


  --- Set the squadron CAS engage limit.  
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageLimit The maximum amount of groups to engage with the enemy for this squadron.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronCasEngageLimit( "Mineralnye", 2 ) -- Engage maximum 2 groups with the enemy for CAS defense.
  -- 
  function AI_A2G_DISPATCHER:SetSquadronCasEngageLimit( SquadronName, EngageLimit )

    self:SetSquadronEngageLimit( SquadronName, EngageLimit, "CAS" )  

  end


  --- Set a Cas patrol for a Squadron.
  -- The Cas patrol will start a patrol of the aircraft at a specified zone, and will engage when commanded.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the Patrol will be executed.
  -- @param #number PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the cap can be executed.
  -- @param #number PatrolFloorAltitude (optional, default = 1000m ) The minimum altitude at which the cap can be executed.
  -- @param #number PatrolCeilingAltitude (optional, default = 1500m ) The maximum altitude at which the cap can be executed.
  -- @param #number PatrolAltType The altitude type when patrolling, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the engage can be executed.
  -- @param #number EngageFloorAltitude (optional, default = 1000m ) The minimum altitude at which the engage can be executed.
  -- @param #number EngageCeilingAltitude (optional, default = 1500m ) The maximum altitude at which the engage can be executed.
  -- @param #number EngageAltType The altitude type when engaging, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Cas Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronCasPatrol2( "Mineralnye", PatrolZoneEast, 500, 600, 4000, 10000, "BARO", 800, 900, 2000, 3000, "RADIO", )
  --        
  function AI_A2G_DISPATCHER:SetSquadronCasPatrol2( SquadronName, Zone, PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.CAS = DefenderSquadron.CAS or {}
    
    local CasPatrol = DefenderSquadron.CAS
    CasPatrol.Name = SquadronName
    CasPatrol.Zone = Zone
    CasPatrol.PatrolFloorAltitude = PatrolFloorAltitude
    CasPatrol.PatrolCeilingAltitude = PatrolCeilingAltitude
    CasPatrol.EngageFloorAltitude = EngageFloorAltitude
    CasPatrol.EngageCeilingAltitude = EngageCeilingAltitude
    CasPatrol.PatrolMinSpeed = PatrolMinSpeed
    CasPatrol.PatrolMaxSpeed = PatrolMaxSpeed
    CasPatrol.EngageMinSpeed = EngageMinSpeed
    CasPatrol.EngageMaxSpeed = EngageMaxSpeed
    CasPatrol.PatrolAltType = PatrolAltType
    CasPatrol.EngageAltType = EngageAltType
    CasPatrol.Patrol = true

    self:SetSquadronPatrolInterval( SquadronName, self.DefenderDefault.PatrolLimit, self.DefenderDefault.PatrolMinSeconds, self.DefenderDefault.PatrolMaxSeconds, 1, "CAS" )
    
    self:I( { CAS = { Zone:GetName(), PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType } } )
  end
  
  
  --- Set a Cas patrol for a Squadron.
  -- The Cas patrol will start a patrol of the aircraft at a specified zone, and will engage when commanded.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the Patrol will be executed.
  -- @param #number FloorAltitude (optional, default = 1000m ) The minimum altitude at which the cap can be executed.
  -- @param #number CeilingAltitude (optional, default = 1500m ) The maximum altitude at which the cap can be executed.
  -- @param #number PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the cap can be executed.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the engage can be executed.
  -- @param #number AltType The altitude type, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Cas Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronCasPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        
  function AI_A2G_DISPATCHER:SetSquadronCasPatrol( SquadronName, Zone, FloorAltitude, CeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, AltType )

    self:SetSquadronCasPatrol2( SquadronName, Zone, PatrolMinSpeed, PatrolMaxSpeed, FloorAltitude, CeilingAltitude, AltType, EngageMinSpeed, EngageMaxSpeed, FloorAltitude, CeilingAltitude, AltType )
  
  end
  

  --- Set a squadron to engage for a battlefield area interdiction, when a defense point is under attack.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the BAI task can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the BAI task can be executed.
  -- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
  -- @param #number EngageAltType The altitude type when engaging, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @usage 
  -- 
  --        -- BAI Squadron execution.
  --        A2GDispatcher:SetSquadronBai( "Mozdok", 900, 1200, 4000, 5000, "BARO" )
  --        A2GDispatcher:SetSquadronBai( "Novo", 900, 2100, 6000, 9000, "BARO" )
  --        A2GDispatcher:SetSquadronBai( "Maykop", 900, 1200, 30, 100, "RADIO" )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronBai2( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.BAI = DefenderSquadron.BAI or {}
    
    local Bai = DefenderSquadron.BAI
    Bai.Name = SquadronName
    Bai.EngageMinSpeed = EngageMinSpeed
    Bai.EngageMaxSpeed = EngageMaxSpeed
    Bai.EngageFloorAltitude = EngageFloorAltitude or 500
    Bai.EngageCeilingAltitude = EngageCeilingAltitude or 1000
    Bai.EngageAltType = EngageAltType
    Bai.Defend = true
    
    self:I( { BAI = { SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType } } )
    
    return self
  end


  --- Set a squadron to engage for a battlefield area interdiction, when a defense point is under attack.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the BAI task can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the BAI task can be executed.
  -- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
  -- @usage 
  -- 
  --        -- BAI Squadron execution.
  --        A2GDispatcher:SetSquadronBai( "Mozdok", 900, 1200, 4000, 5000 )
  --        A2GDispatcher:SetSquadronBai( "Novo", 900, 2100, 6000, 8000 )
  --        A2GDispatcher:SetSquadronBai( "Maykop", 900, 1200, 6000, 10000 )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronBai( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude )

    return self:SetSquadronBai2( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, "RADIO" )  
  end


  --- Set the squadron BAI engage limit.  
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageLimit The maximum amount of groups to engage with the enemy for this squadron.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronBaiEngageLimit( "Mineralnye", 2 ) -- Engage maximum 2 groups with the enemy for BAI defense.
  -- 
  function AI_A2G_DISPATCHER:SetSquadronBaiEngageLimit( SquadronName, EngageLimit )

    self:SetSquadronEngageLimit( SquadronName, EngageLimit, "BAI" )  

  end
  

  --- Set a Bai patrol for a Squadron.
  -- The Bai patrol will start a patrol of the aircraft at a specified zone, and will engage when commanded.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the Patrol will be executed.
  -- @param #number PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the cap can be executed.
  -- @param #number PatrolFloorAltitude (optional, default = 1000m ) The minimum altitude at which the cap can be executed.
  -- @param #number PatrolCeilingAltitude (optional, default = 1500m ) The maximum altitude at which the cap can be executed.
  -- @param #number PatrolAltType The altitude type when patrolling, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the engage can be executed.
  -- @param #number EngageFloorAltitude (optional, default = 1000m ) The minimum altitude at which the engage can be executed.
  -- @param #number EngageCeilingAltitude (optional, default = 1500m ) The maximum altitude at which the engage can be executed.
  -- @param #number EngageAltType The altitude type when engaging, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Bai Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronBaiPatrol2( "Mineralnye", PatrolZoneEast, 500, 600, 4000, 10000, "BARO", 800, 900, 2000, 3000, "RADIO", )
  --        
  function AI_A2G_DISPATCHER:SetSquadronBaiPatrol2( SquadronName, Zone, PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.BAI = DefenderSquadron.BAI or {}
    
    local BaiPatrol = DefenderSquadron.BAI
    BaiPatrol.Name = SquadronName
    BaiPatrol.Zone = Zone
    BaiPatrol.PatrolFloorAltitude = PatrolFloorAltitude
    BaiPatrol.PatrolCeilingAltitude = PatrolCeilingAltitude
    BaiPatrol.EngageFloorAltitude = EngageFloorAltitude
    BaiPatrol.EngageCeilingAltitude = EngageCeilingAltitude
    BaiPatrol.PatrolMinSpeed = PatrolMinSpeed
    BaiPatrol.PatrolMaxSpeed = PatrolMaxSpeed
    BaiPatrol.EngageMinSpeed = EngageMinSpeed
    BaiPatrol.EngageMaxSpeed = EngageMaxSpeed
    BaiPatrol.PatrolAltType = PatrolAltType
    BaiPatrol.EngageAltType = EngageAltType
    BaiPatrol.Patrol = true

    self:SetSquadronPatrolInterval( SquadronName, self.DefenderDefault.PatrolLimit, self.DefenderDefault.PatrolMinSeconds, self.DefenderDefault.PatrolMaxSeconds, 1, "BAI" )
    
    self:I( { BAI = { Zone:GetName(), PatrolMinSpeed, PatrolMaxSpeed, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolAltType, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, EngageAltType } } )
  end
  

  --- Set a Bai patrol for a Squadron.
  -- The Bai patrol will start a patrol of the aircraft at a specified zone, and will engage when commanded.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Core.Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the Patrol will be executed.
  -- @param #number FloorAltitude (optional, default = 1000m ) The minimum altitude at which the cap can be executed.
  -- @param #number CeilingAltitude (optional, default = 1500m ) The maximum altitude at which the cap can be executed.
  -- @param #number PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the cap can be executed.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the engage can be executed.
  -- @param #number AltType The altitude type, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --        -- Bai Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronBaiPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        
  function AI_A2G_DISPATCHER:SetSquadronBaiPatrol( SquadronName, Zone, FloorAltitude, CeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, AltType )

    self:SetSquadronBaiPatrol2( SquadronName, Zone, PatrolMinSpeed, PatrolMaxSpeed, FloorAltitude, CeilingAltitude, AltType, EngageMinSpeed, EngageMaxSpeed, FloorAltitude, CeilingAltitude, AltType )
  
  end
  

  --- Defines the default amount of extra planes that will takeoff as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number Overhead The % of Units that dispatching command will allocate to intercept in surplus of detected amount of units.
  -- The default overhead is 1, so equal balance. The @{#AI_A2G_DISPATCHER.SetOverhead}() method can be used to tweak the defense strength,
  -- taking into account the plane types of the squadron. For example, a MIG-31 with full long-distance A2G missiles payload, may still be less effective than a F-15C with short missiles...
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
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- An overhead of 1,5 with 1 planes detected, will allocate 2 planes ( 1 * 1,5 ) = 1,5 => rounded up gives 2.
  --   -- An overhead of 1,5 with 2 planes detected, will allocate 3 planes ( 2 * 1,5 ) = 3 =>  rounded up gives 3.
  --   -- An overhead of 1,5 with 3 planes detected, will allocate 5 planes ( 3 * 1,5 ) = 4,5 => rounded up gives 5 planes.
  --   -- An overhead of 1,5 with 4 planes detected, will allocate 6 planes ( 4 * 1,5 ) = 6  => rounded up gives 6 planes.
  --   
  --   A2GDispatcher:SetDefaultOverhead( 1.5 )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetDefaultOverhead( Overhead )

    self.DefenderDefault.Overhead = Overhead
    
    return self
  end


  --- Defines the amount of extra planes that will takeoff as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Overhead The % of Units that dispatching command will allocate to intercept in surplus of detected amount of units.
  -- The default overhead is 1, so equal balance. The @{#AI_A2G_DISPATCHER.SetOverhead}() method can be used to tweak the defense strength,
  -- taking into account the plane types of the squadron. For example, a MIG-31 with full long-distance A2G missiles payload, may still be less effective than a F-15C with short missiles...
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
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- An overhead of 1,5 with 1 planes detected, will allocate 2 planes ( 1 * 1,5 ) = 1,5 => rounded up gives 2.
  --   -- An overhead of 1,5 with 2 planes detected, will allocate 3 planes ( 2 * 1,5 ) = 3 =>  rounded up gives 3.
  --   -- An overhead of 1,5 with 3 planes detected, will allocate 5 planes ( 3 * 1,5 ) = 4,5 => rounded up gives 5 planes.
  --   -- An overhead of 1,5 with 4 planes detected, will allocate 6 planes ( 4 * 1,5 ) = 6  => rounded up gives 6 planes.
  --   
  --   A2GDispatcher:SetSquadronOverhead( "SquadronName", 1.5 )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronOverhead( SquadronName, Overhead )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Overhead = Overhead
    
    return self
  end


  --- Gets the overhead of planes as part of the defense system, in comparison with the attackers.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #number The % of Units that dispatching command will allocate to intercept in surplus of detected amount of units.
  -- The default overhead is 1, so equal balance. The @{#AI_A2G_DISPATCHER.SetOverhead}() method can be used to tweak the defense strength,
  -- taking into account the plane types of the squadron. For example, a MIG-31 with full long-distance A2G missiles payload, may still be less effective than a F-15C with short missiles...
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
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- An overhead of 1,5 with 1 planes detected, will allocate 2 planes ( 1 * 1,5 ) = 1,5 => rounded up gives 2.
  --   -- An overhead of 1,5 with 2 planes detected, will allocate 3 planes ( 2 * 1,5 ) = 3 =>  rounded up gives 3.
  --   -- An overhead of 1,5 with 3 planes detected, will allocate 5 planes ( 3 * 1,5 ) = 4,5 => rounded up gives 5 planes.
  --   -- An overhead of 1,5 with 4 planes detected, will allocate 6 planes ( 4 * 1,5 ) = 6  => rounded up gives 6 planes.
  --   
  --   local SquadronOverhead = A2GDispatcher:GetSquadronOverhead( "SquadronName" )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:GetSquadronOverhead( SquadronName )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    return DefenderSquadron.Overhead or self.DefenderDefault.Overhead
  end


  --- Sets the default grouping of new aircraft spawned.
  -- Grouping will trigger how new aircraft will be grouped if more than one aircraft is spawned for defense.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number Grouping The level of grouping that will be applied for the Patrol.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Set a grouping by default per 2 aircraft.
  --   A2GDispatcher:SetDefaultGrouping( 2 )
  -- 
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetDefaultGrouping( Grouping )
  
    self.DefenderDefault.Grouping = Grouping
    
    return self
  end


  --- Sets the Squadron grouping of new aircraft spawned.
  -- Grouping will trigger how new aircraft will be grouped if more than one aircraft is spawned for defense.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Grouping The level of grouping that will be applied for a Patrol from the Squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Set a Squadron specific grouping per 2 aircraft.
  --   A2GDispatcher:SetSquadronGrouping( "SquadronName", 2 )
  -- 
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronGrouping( SquadronName, Grouping )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Grouping = Grouping
    
    return self
  end


  --- Sets the engage probability if the squadron will engage on a detected target.
  -- This can be configured per squadron, to ensure that each squadron as a specific defensive probability setting.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number EngageProbability The probability when the squadron will consider to engage the detected target. 
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Set an defense probability for squadron SquadronName of 50%.
  --   -- This will result that this squadron has 50% chance to engage on a detected target.
  --   A2GDispatcher:SetSquadronEngageProbability( "SquadronName", 0.5 )
  -- 
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronEngageProbability( SquadronName, EngageProbability )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.EngageProbability = EngageProbability
    
    return self
  end


  --- Defines the default method at which new flights will spawn and takeoff as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default takeoff in the air.
  --   A2GDispatcher:SetDefaultTakeoff( AI_A2G_Dispatcher.Takeoff.Air )
  --   
  --   -- Let new flights by default takeoff from the runway.
  --   A2GDispatcher:SetDefaultTakeoff( AI_A2G_Dispatcher.Takeoff.Runway )
  --   
  --   -- Let new flights by default takeoff from the airbase hot.
  --   A2GDispatcher:SetDefaultTakeoff( AI_A2G_Dispatcher.Takeoff.Hot )
  -- 
  --   -- Let new flights by default takeoff from the airbase cold.
  --   A2GDispatcher:SetDefaultTakeoff( AI_A2G_Dispatcher.Takeoff.Cold )
  -- 
  -- 
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetDefaultTakeoff( Takeoff )

    self.DefenderDefault.Takeoff = Takeoff
    
    return self
  end

  --- Defines the method at which new flights will spawn and takeoff as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights takeoff in the air.
  --   A2GDispatcher:SetSquadronTakeoff( "SquadronName", AI_A2G_Dispatcher.Takeoff.Air )
  --   
  --   -- Let new flights takeoff from the runway.
  --   A2GDispatcher:SetSquadronTakeoff( "SquadronName", AI_A2G_Dispatcher.Takeoff.Runway )
  --   
  --   -- Let new flights takeoff from the airbase hot.
  --   A2GDispatcher:SetSquadronTakeoff( "SquadronName", AI_A2G_Dispatcher.Takeoff.Hot )
  -- 
  --   -- Let new flights takeoff from the airbase cold.
  --   A2GDispatcher:SetSquadronTakeoff( "SquadronName", AI_A2G_Dispatcher.Takeoff.Cold )
  -- 
  -- 
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetSquadronTakeoff( SquadronName, Takeoff )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Takeoff = Takeoff
    
    return self
  end
  

  --- Gets the default method at which new flights will spawn and takeoff as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @return #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default takeoff in the air.
  --   local TakeoffMethod = A2GDispatcher:GetDefaultTakeoff()
  --   if TakeoffMethod == , AI_A2G_Dispatcher.Takeoff.InAir then
  --     ...
  --   end
  --   
  function AI_A2G_DISPATCHER:GetDefaultTakeoff( )

    return self.DefenderDefault.Takeoff
  end
  
  --- Gets the method at which new flights will spawn and takeoff as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights takeoff in the air.
  --   local TakeoffMethod = A2GDispatcher:GetSquadronTakeoff( "SquadronName" )
  --   if TakeoffMethod == , AI_A2G_Dispatcher.Takeoff.InAir then
  --     ...
  --   end
  --   
  function AI_A2G_DISPATCHER:GetSquadronTakeoff( SquadronName )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    return DefenderSquadron.Takeoff or self.DefenderDefault.Takeoff
  end
  

  --- Sets flights to default takeoff in the air, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default takeoff in the air.
  --   A2GDispatcher:SetDefaultTakeoffInAir()
  --   
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetDefaultTakeoffInAir()

    self:SetDefaultTakeoff( AI_A2G_DISPATCHER.Takeoff.Air )
    
    return self
  end

  
  --- Sets flights to takeoff in the air, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number TakeoffAltitude (optional) The altitude in meters above the ground. If not given, the default takeoff altitude will be used.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights takeoff in the air.
  --   A2GDispatcher:SetSquadronTakeoffInAir( "SquadronName" )
  --   
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetSquadronTakeoffInAir( SquadronName, TakeoffAltitude )

    self:SetSquadronTakeoff( SquadronName, AI_A2G_DISPATCHER.Takeoff.Air )
    
    if TakeoffAltitude then
      self:SetSquadronTakeoffInAirAltitude( SquadronName, TakeoffAltitude )
    end
    
    return self
  end


  --- Sets flights by default to takeoff from the runway, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default takeoff from the runway.
  --   A2GDispatcher:SetDefaultTakeoffFromRunway()
  --   
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetDefaultTakeoffFromRunway()

    self:SetDefaultTakeoff( AI_A2G_DISPATCHER.Takeoff.Runway )
    
    return self
  end

  
  --- Sets flights to takeoff from the runway, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights takeoff from the runway.
  --   A2GDispatcher:SetSquadronTakeoffFromRunway( "SquadronName" )
  --   
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetSquadronTakeoffFromRunway( SquadronName )

    self:SetSquadronTakeoff( SquadronName, AI_A2G_DISPATCHER.Takeoff.Runway )
    
    return self
  end
  

  --- Sets flights by default to takeoff from the airbase at a hot location, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default takeoff at a hot parking spot.
  --   A2GDispatcher:SetDefaultTakeoffFromParkingHot()
  --   
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetDefaultTakeoffFromParkingHot()

    self:SetDefaultTakeoff( AI_A2G_DISPATCHER.Takeoff.Hot )
    
    return self
  end

  --- Sets flights to takeoff from the airbase at a hot location, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights takeoff in the air.
  --   A2GDispatcher:SetSquadronTakeoffFromParkingHot( "SquadronName" )
  --   
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetSquadronTakeoffFromParkingHot( SquadronName )

    self:SetSquadronTakeoff( SquadronName, AI_A2G_DISPATCHER.Takeoff.Hot )
    
    return self
  end
  
  
  --- Sets flights to by default takeoff from the airbase at a cold location, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights takeoff from a cold parking spot.
  --   A2GDispatcher:SetDefaultTakeoffFromParkingCold()
  --   
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetDefaultTakeoffFromParkingCold()

    self:SetDefaultTakeoff( AI_A2G_DISPATCHER.Takeoff.Cold )
    
    return self
  end
  

  --- Sets flights to takeoff from the airbase at a cold location, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights takeoff from a cold parking spot.
  --   A2GDispatcher:SetSquadronTakeoffFromParkingCold( "SquadronName" )
  --   
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetSquadronTakeoffFromParkingCold( SquadronName )

    self:SetSquadronTakeoff( SquadronName, AI_A2G_DISPATCHER.Takeoff.Cold )
    
    return self
  end
  

  --- Defines the default altitude where aircraft will spawn in the air and takeoff as part of the defense system, when the takeoff in the air method has been selected.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number TakeoffAltitude The altitude in meters above ground level (AGL).
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Set the default takeoff altitude when taking off in the air.
  --   A2GDispatcher:SetDefaultTakeoffInAirAltitude( 2000 )  -- This makes planes start at 2000 meters above the ground.
  -- 
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetDefaultTakeoffInAirAltitude( TakeoffAltitude )

    self.DefenderDefault.TakeoffAltitude = TakeoffAltitude
    
    return self
  end

  --- Defines the default altitude where aircraft will spawn in the air and takeoff as part of the defense system, when the takeoff in the air method has been selected.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number TakeoffAltitude The altitude in meters above ground level (AGL).
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Set the default takeoff altitude when taking off in the air.
  --   A2GDispatcher:SetSquadronTakeoffInAirAltitude( "SquadronName", 2000 ) -- This makes aircraft start at 2000 meters above ground level (AGL).
  --   
  -- @return #AI_A2G_DISPATCHER
  -- 
  function AI_A2G_DISPATCHER:SetSquadronTakeoffInAirAltitude( SquadronName, TakeoffAltitude )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.TakeoffAltitude = TakeoffAltitude
    
    return self
  end
  

  --- Defines the default method at which flights will land and despawn as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default despawn near the airbase when returning.
  --   A2GDispatcher:SetDefaultLanding( AI_A2G_Dispatcher.Landing.NearAirbase )
  --   
  --   -- Let new flights by default despawn after landing land at the runway.
  --   A2GDispatcher:SetDefaultLanding( AI_A2G_Dispatcher.Landing.AtRunway )
  --   
  --   -- Let new flights by default despawn after landing and parking, and after engine shutdown.
  --   A2GDispatcher:SetDefaultLanding( AI_A2G_Dispatcher.Landing.AtEngineShutdown )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetDefaultLanding( Landing )

    self.DefenderDefault.Landing = Landing
    
    return self
  end
  

  --- Defines the method at which flights will land and despawn as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights despawn near the airbase when returning.
  --   A2GDispatcher:SetSquadronLanding( "SquadronName", AI_A2G_Dispatcher.Landing.NearAirbase )
  --   
  --   -- Let new flights despawn after landing land at the runway.
  --   A2GDispatcher:SetSquadronLanding( "SquadronName", AI_A2G_Dispatcher.Landing.AtRunway )
  --   
  --   -- Let new flights despawn after landing and parking, and after engine shutdown.
  --   A2GDispatcher:SetSquadronLanding( "SquadronName", AI_A2G_Dispatcher.Landing.AtEngineShutdown )
  -- 
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronLanding( SquadronName, Landing )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Landing = Landing
    
    return self
  end
  

  --- Gets the default method at which flights will land and despawn as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @return #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default despawn near the airbase when returning.
  --   local LandingMethod = A2GDispatcher:GetDefaultLanding()
  --   if LandingMethod == AI_A2G_Dispatcher.Landing.NearAirbase then
  --    ...
  --   end
  -- 
  function AI_A2G_DISPATCHER:GetDefaultLanding()

    return self.DefenderDefault.Landing
  end
  

  --- Gets the method at which flights will land and despawn as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let new flights despawn near the airbase when returning.
  --   local LandingMethod = A2GDispatcher:GetSquadronLanding( "SquadronName", AI_A2G_Dispatcher.Landing.NearAirbase )
  --   if LandingMethod == AI_A2G_Dispatcher.Landing.NearAirbase then
  --    ...
  --   end
  -- 
  function AI_A2G_DISPATCHER:GetSquadronLanding( SquadronName )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    return DefenderSquadron.Landing or self.DefenderDefault.Landing
  end
  

  --- Sets flights by default to land and despawn near the airbase in the air, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let flights by default to land near the airbase and despawn.
  --   A2GDispatcher:SetDefaultLandingNearAirbase()
  --   
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetDefaultLandingNearAirbase()

    self:SetDefaultLanding( AI_A2G_DISPATCHER.Landing.NearAirbase )
    
    return self
  end
  

  --- Sets flights to land and despawn near the airbase in the air, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let flights to land near the airbase and despawn.
  --   A2GDispatcher:SetSquadronLandingNearAirbase( "SquadronName" )
  --   
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronLandingNearAirbase( SquadronName )

    self:SetSquadronLanding( SquadronName, AI_A2G_DISPATCHER.Landing.NearAirbase )
    
    return self
  end
  

  --- Sets flights by default to land and despawn at the runway, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let flights by default land at the runway and despawn.
  --   A2GDispatcher:SetDefaultLandingAtRunway()
  --   
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetDefaultLandingAtRunway()

    self:SetDefaultLanding( AI_A2G_DISPATCHER.Landing.AtRunway )
    
    return self
  end
  

  --- Sets flights to land and despawn at the runway, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let flights land at the runway and despawn.
  --   A2GDispatcher:SetSquadronLandingAtRunway( "SquadronName" )
  --   
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronLandingAtRunway( SquadronName )

    self:SetSquadronLanding( SquadronName, AI_A2G_DISPATCHER.Landing.AtRunway )
    
    return self
  end
  

  --- Sets flights by default to land and despawn at engine shutdown, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let flights by default land and despawn at engine shutdown.
  --   A2GDispatcher:SetDefaultLandingAtEngineShutdown()
  --   
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetDefaultLandingAtEngineShutdown()

    self:SetDefaultLanding( AI_A2G_DISPATCHER.Landing.AtEngineShutdown )
    
    return self
  end
  

  --- Sets flights to land and despawn at engine shutdown, as part of the defense system.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_A2G_DISPATCHER:New( ... )
  --   
  --   -- Let flights land and despawn at engine shutdown.
  --   A2GDispatcher:SetSquadronLandingAtEngineShutdown( "SquadronName" )
  --   
  -- @return #AI_A2G_DISPATCHER
  function AI_A2G_DISPATCHER:SetSquadronLandingAtEngineShutdown( SquadronName )

    self:SetSquadronLanding( SquadronName, AI_A2G_DISPATCHER.Landing.AtEngineShutdown )
    
    return self
  end
  
  --- Set the default fuel threshold when defenders will RTB or Refuel in the air.
  -- The fuel threshold is by default set to 15%, which means that an aircraft will stay in the air until 15% of its fuel is remaining.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #number FuelThreshold A decimal number between 0 and 1, that expresses the % of the threshold of fuel remaining in the tank when the plane will go RTB or Refuel.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default fuel threshold.
  --   A2GDispatcher:SetDefaultFuelThreshold( 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --   
  function AI_A2G_DISPATCHER:SetDefaultFuelThreshold( FuelThreshold )
    
    self.DefenderDefault.FuelThreshold = FuelThreshold
    
    return self
  end  


  --- Set the fuel threshold for the squadron when defenders will RTB or Refuel in the air.
  -- The fuel threshold is by default set to 15%, which means that an aircraft will stay in the air until 15% of its fuel is remaining.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number FuelThreshold A decimal number between 0 and 1, that expresses the % of the threshold of fuel remaining in the tank when the plane will go RTB or Refuel.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default fuel threshold.
  --   A2GDispatcher:SetSquadronRefuelThreshold( "SquadronName", 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --   
  function AI_A2G_DISPATCHER:SetSquadronFuelThreshold( SquadronName, FuelThreshold )
    
    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.FuelThreshold = FuelThreshold
    
    return self
  end  

  --- Set the default tanker where defenders will Refuel in the air.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string TankerName A string defining the group name of the Tanker as defined within the Mission Editor.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default fuel threshold.
  --   A2GDispatcher:SetDefaultFuelThreshold( 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --   
  --   -- Now Setup the default tanker.
  --   A2GDispatcher:SetDefaultTanker( "Tanker" ) -- The group name of the tanker is "Tanker" in the Mission Editor.
  function AI_A2G_DISPATCHER:SetDefaultTanker( TankerName )
    
    self.DefenderDefault.TankerName = TankerName
    
    return self
  end  


  --- Set the squadron tanker where defenders will Refuel in the air.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #string TankerName A string defining the group name of the Tanker as defined within the Mission Editor.
  -- @return #AI_A2G_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_A2G_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the squadron fuel threshold.
  --   A2GDispatcher:SetSquadronRefuelThreshold( "SquadronName", 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --   
  --   -- Now Setup the squadron tanker.
  --   A2GDispatcher:SetSquadronTanker( "SquadronName", "Tanker" ) -- The group name of the tanker is "Tanker" in the Mission Editor.
  function AI_A2G_DISPATCHER:SetSquadronTanker( SquadronName, TankerName )
    
    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.TankerName = TankerName
    
    return self
  end  


  --- Set the frequency of communication and the mode of communication for voice overs.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number RadioFrequency The frequency of communication.
  -- @param #number RadioModulation The modulation of communication.
  -- @param #number RadioPower The power in Watts of communication.
  function AI_A2G_DISPATCHER:SetSquadronRadioFrequency( SquadronName, RadioFrequency, RadioModulation, RadioPower )
  
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


  --- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:AddDefenderToSquadron( Squadron, Defender, Size )
    self.Defenders = self.Defenders or {}
    local DefenderName = Defender:GetName()
    self.Defenders[ DefenderName ] = Squadron
    if Squadron.ResourceCount then
      Squadron.ResourceCount = Squadron.ResourceCount - Size
    end
    self:F( { DefenderName = DefenderName, SquadronResourceCount = Squadron.ResourceCount } )
  end

  --- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:RemoveDefenderFromSquadron( Squadron, Defender )
    self.Defenders = self.Defenders or {}
    local DefenderName = Defender:GetName()
    if Squadron.ResourceCount then
      Squadron.ResourceCount = Squadron.ResourceCount + Defender:GetSize()
    end
    self.Defenders[ DefenderName ] = nil
    self:F( { DefenderName = DefenderName, SquadronResourceCount = Squadron.ResourceCount } )
  end
  
  function AI_A2G_DISPATCHER:GetSquadronFromDefender( Defender )
    self.Defenders = self.Defenders or {}
    local DefenderName = Defender:GetName()
    self:F( { DefenderName = DefenderName } )
    return self.Defenders[ DefenderName ] 
  end

  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:CountPatrolAirborne( SquadronName, DefenseTaskType )

    local PatrolCount = 0
    
    local DefenderSquadron = self.DefenderSquadrons[SquadronName]
    if DefenderSquadron then
      for AIGroup, DefenderTask in pairs( self:GetDefenderTasks() ) do
        if DefenderTask.SquadronName == SquadronName then
          if DefenderTask.Type == DefenseTaskType then
            if AIGroup:IsAlive() then
              -- Check if the Patrol is patrolling or engaging. If not, this is not a valid Patrol, even if it is alive!
              -- The Patrol could be damaged, lost control, or out of fuel!
              if DefenderTask.Fsm:Is( "Patrolling" ) or DefenderTask.Fsm:Is( "Engaging" ) or DefenderTask.Fsm:Is( "Refuelling" )
                    or DefenderTask.Fsm:Is( "Started" ) then
                PatrolCount = PatrolCount + 1
              end
            end
          end
        end
      end
    end

    return PatrolCount
  end
  
  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:CountDefendersEngaged( AttackerDetection, AttackerCount )

    -- First, count the active AIGroups Units, targeting the DetectedSet
    local DefendersEngaged = 0
    local DefendersTotal = 0
    
    local AttackerSet = AttackerDetection.Set
    local DefendersMissing = AttackerCount
    --DetectedSet:Flush()
    
    local DefenderTasks = self:GetDefenderTasks()
    for DefenderGroup, DefenderTask in pairs( DefenderTasks ) do
      local Defender = DefenderGroup -- Wrapper.Group#GROUP
      local DefenderTaskTarget = DefenderTask.Target
      local DefenderSquadronName = DefenderTask.SquadronName
      local DefenderSize = DefenderTask.Size

      -- Count the total of defenders on the battlefield.
      --local DefenderSize = Defender:GetInitialSize()
      if DefenderTask.Target then
        --if DefenderTask.Fsm:Is( "Engaging" ) then
          self:F( "Defender Group Name: " .. Defender:GetName() .. ", Size: " .. DefenderSize )
          DefendersTotal = DefendersTotal + DefenderSize
          if DefenderTaskTarget and DefenderTaskTarget.Index == AttackerDetection.Index then
          
            local SquadronOverhead = self:GetSquadronOverhead( DefenderSquadronName )
            self:F( { SquadronOverhead = SquadronOverhead } )
            if DefenderSize then
              DefendersEngaged = DefendersEngaged + DefenderSize
              DefendersMissing = DefendersMissing - DefenderSize / SquadronOverhead
              self:F( "Defender Group Name: " .. Defender:GetName() .. ", Size: " .. DefenderSize )
            else
              DefendersEngaged = 0
            end
          end
        --end
      end

      
    end

    for QueueID, QueueItem in pairs( self.DefenseQueue ) do
      local QueueItem = QueueItem -- #AI_A2G_DISPATCHER.DefenseQueueItem
      if QueueItem.AttackerDetection and QueueItem.AttackerDetection.ItemID == AttackerDetection.ItemID then
        DefendersMissing = DefendersMissing - QueueItem.DefendersNeeded / QueueItem.DefenderSquadron.Overhead
        --DefendersEngaged = DefendersEngaged + QueueItem.DefenderGrouping
        self:F( { QueueItemName = QueueItem.Defense, QueueItem_ItemID = QueueItem.AttackerDetection.ItemID, DetectedItem = AttackerDetection.ItemID, DefendersMissing = DefendersMissing } )
      end
    end

    self:F( { DefenderCount = DefendersEngaged } )

    return DefendersTotal, DefendersEngaged, DefendersMissing
  end
  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:CountDefenders( AttackerDetection, DefenderCount, DefenderTaskType )
  
    local Friendlies = nil

    local AttackerSet = AttackerDetection.Set
    local AttackerCount = AttackerSet:Count()

    local DefenderFriendlies = self:GetDefenderFriendliesNearBy( AttackerDetection )
    
    for FriendlyDistance, DefenderFriendlyUnit in UTILS.spairs( DefenderFriendlies or {} ) do
      -- We only allow to engage targets as long as the units on both sides are balanced.
      if AttackerCount > DefenderCount then 
        local FriendlyGroup = DefenderFriendlyUnit:GetGroup() -- Wrapper.Group#GROUP
        if FriendlyGroup and FriendlyGroup:IsAlive() then
          -- Ok, so we have a friendly near the potential target.
          -- Now we need to check if the AIGroup has a Task.
          local DefenderTask = self:GetDefenderTask( FriendlyGroup )
          if DefenderTask then
            -- The Task should be of the same type.
            if DefenderTaskType == DefenderTask.Type then 
              -- If there is no target, then add the AIGroup to the ResultAIGroups for Engagement to the AttackerSet
              if DefenderTask.Target == nil then
                if DefenderTask.Fsm:Is( "Returning" )
                or DefenderTask.Fsm:Is( "Patrolling" ) then
                  Friendlies = Friendlies or {}
                  Friendlies[FriendlyGroup] = FriendlyGroup
                  DefenderCount = DefenderCount + FriendlyGroup:GetSize()
                  self:F( { Friendly = FriendlyGroup:GetName(), FriendlyDistance = FriendlyDistance } )
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


  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:ResourceActivate( DefenderSquadron, DefendersNeeded )
  
    local SquadronName = DefenderSquadron.Name
    DefendersNeeded = DefendersNeeded or 4
    local DefenderGrouping = DefenderSquadron.Grouping or self.DefenderDefault.Grouping
    DefenderGrouping = ( DefenderGrouping < DefendersNeeded ) and DefenderGrouping or DefendersNeeded
    
    if self:IsSquadronVisible( SquadronName ) then
    
      -- Here we Patrol the new planes.
      -- The Resources table is filled in advance.
      local TemplateID = math.random( 1, #DefenderSquadron.Spawn ) -- Choose the template.
  
      -- We determine the grouping based on the parameters set.
      self:F( { DefenderGrouping = DefenderGrouping } )
      
      -- New we will form the group to spawn in.
      -- We search for the first free resource matching the template.
      local DefenderUnitIndex = 1
      local DefenderPatrolTemplate = nil
      local DefenderName = nil
      for GroupName, DefenderGroup in pairs( DefenderSquadron.Resources[TemplateID] or {} ) do
        self:F( { GroupName = GroupName } )
        local DefenderTemplate = _DATABASE:GetGroupTemplate( GroupName )
        if DefenderUnitIndex == 1 then
          DefenderPatrolTemplate = UTILS.DeepCopy( DefenderTemplate )
          self.DefenderPatrolIndex = self.DefenderPatrolIndex + 1
          --DefenderPatrolTemplate.name = SquadronName .. "#" .. self.DefenderPatrolIndex .. "#" .. GroupName
          DefenderPatrolTemplate.name = GroupName
          DefenderName = DefenderPatrolTemplate.name
        else
          -- Add the unit in the template to the DefenderPatrolTemplate.
          local DefenderUnitTemplate = DefenderTemplate.units[1]
          DefenderPatrolTemplate.units[DefenderUnitIndex] = DefenderUnitTemplate
        end
        DefenderPatrolTemplate.units[DefenderUnitIndex].name = string.format( DefenderPatrolTemplate.name .. '-%02d', DefenderUnitIndex )
        DefenderPatrolTemplate.units[DefenderUnitIndex].unitId = nil
        DefenderUnitIndex = DefenderUnitIndex + 1
        DefenderSquadron.Resources[TemplateID][GroupName] = nil
        if DefenderUnitIndex > DefenderGrouping then
          break
        end
        
      end 
      
      if DefenderPatrolTemplate then
        local TakeoffMethod = self:GetSquadronTakeoff( SquadronName )
        local SpawnGroup = GROUP:Register( DefenderName )
        DefenderPatrolTemplate.lateActivation = nil
        DefenderPatrolTemplate.uncontrolled = nil
        local Takeoff = self:GetSquadronTakeoff( SquadronName )
        DefenderPatrolTemplate.route.points[1].type   = GROUPTEMPLATE.Takeoff[Takeoff][1] -- type
        DefenderPatrolTemplate.route.points[1].action = GROUPTEMPLATE.Takeoff[Takeoff][2] -- action
        local Defender = _DATABASE:Spawn( DefenderPatrolTemplate )
        self:AddDefenderToSquadron( DefenderSquadron, Defender, DefenderGrouping )
        Defender:Activate()
        return Defender, DefenderGrouping
      end
    else
      local Spawn = DefenderSquadron.Spawn[ math.random( 1, #DefenderSquadron.Spawn ) ] -- Core.Spawn#SPAWN
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
  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:onafterPatrol( From, Event, To, SquadronName, DefenseTaskType )
  
    local DefenderSquadron, Patrol = self:CanPatrol( SquadronName, DefenseTaskType )
    
    -- Determine if there are sufficient resources to form a complete group for patrol.
    if DefenderSquadron then    
      local DefendersNeeded
      local DefendersGrouping = ( DefenderSquadron.Grouping or self.DefenderDefault.Grouping )
      if DefenderSquadron.ResourceCount == nil then
        DefendersNeeded = DefendersGrouping
      else
        if DefenderSquadron.ResourceCount >= DefendersGrouping then
          DefendersNeeded = DefendersGrouping 
        else
          DefendersNeeded = DefenderSquadron.ResourceCount
        end
      end
      
      if Patrol then
        self:ResourceQueue( true, DefenderSquadron, DefendersNeeded, Patrol, DefenseTaskType, nil, SquadronName )
      end
    end
    
  end

  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:ResourceQueue( Patrol, DefenderSquadron, DefendersNeeded, Defense, DefenseTaskType, AttackerDetection, SquadronName )

  self:F( { DefenderSquadron, DefendersNeeded, Defense, DefenseTaskType, AttackerDetection, SquadronName } )

    local DefenseQueueItem = {} -- #AI_A2G_DISPATCHER.DefenderQueueItem


    DefenseQueueItem.Patrol = Patrol
    DefenseQueueItem.DefenderSquadron = DefenderSquadron
    DefenseQueueItem.DefendersNeeded = DefendersNeeded
    DefenseQueueItem.Defense = Defense
    DefenseQueueItem.DefenseTaskType = DefenseTaskType
    DefenseQueueItem.AttackerDetection = AttackerDetection
    DefenseQueueItem.SquadronName  = SquadronName
    
    table.insert( self.DefenseQueue, DefenseQueueItem )
    self:F( { QueueItems = #self.DefenseQueue } )

  end
  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:ResourceTakeoff()

    for DefenseQueueID, DefenseQueueItem in pairs( self.DefenseQueue ) do
      self:F( { DefenseQueueID } )
    end
  
    for SquadronName, Squadron in pairs( self.DefenderSquadrons ) do
      
      if #self.DefenseQueue > 0 then

        self:F( { SquadronName, Squadron.Name, Squadron.TakeoffTime, Squadron.TakeoffInterval, timer.getTime() } )
      
        local DefenseQueueItem = self.DefenseQueue[1]
        self:F( {DefenderSquadron=DefenseQueueItem.DefenderSquadron} )
        
        if DefenseQueueItem.SquadronName == SquadronName then

          if Squadron.TakeoffTime + Squadron.TakeoffInterval < timer.getTime() then
            Squadron.TakeoffTime = timer.getTime()
  
            if DefenseQueueItem.Patrol == true then
              self:ResourcePatrol( DefenseQueueItem.DefenderSquadron, DefenseQueueItem.DefendersNeeded, DefenseQueueItem.Defense, DefenseQueueItem.DefenseTaskType, DefenseQueueItem.AttackerDetection, DefenseQueueItem.SquadronName )
            else
              self:ResourceEngage( DefenseQueueItem.DefenderSquadron, DefenseQueueItem.DefendersNeeded, DefenseQueueItem.Defense, DefenseQueueItem.DefenseTaskType, DefenseQueueItem.AttackerDetection, DefenseQueueItem.SquadronName )
            end
            table.remove( self.DefenseQueue, 1 )
          end
        end
      end
      
    end
  
  end

  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:ResourcePatrol( DefenderSquadron, DefendersNeeded, Patrol, DefenseTaskType, AttackerDetection, SquadronName )


    self:F({DefenderSquadron=DefenderSquadron})
    self:F({DefendersNeeded=DefendersNeeded})
    self:F({Patrol=Patrol})
    self:F({DefenseTaskType=DefenseTaskType})
    self:F({AttackerDetection=AttackerDetection})
    self:F({SquadronName=SquadronName})
    
    local DefenderGroup, DefenderGrouping = self:ResourceActivate( DefenderSquadron, DefendersNeeded )    

    if DefenderGroup then

      local AI_A2G_PATROL = { SEAD = AI_A2G_SEAD, BAI = AI_A2G_BAI, CAS = AI_A2G_CAS }
      
      local AI_A2G_Fsm = AI_A2G_PATROL[DefenseTaskType]:New2( DefenderGroup, Patrol.EngageMinSpeed, Patrol.EngageMaxSpeed, Patrol.EngageFloorAltitude, Patrol.EngageCeilingAltitude, Patrol.EngageAltType, Patrol.Zone, Patrol.PatrolFloorAltitude, Patrol.PatrolCeilingAltitude, Patrol.PatrolMinSpeed, Patrol.PatrolMaxSpeed, Patrol.PatrolAltType )
      AI_A2G_Fsm:SetDispatcher( self )
      AI_A2G_Fsm:SetHomeAirbase( DefenderSquadron.Airbase )
      AI_A2G_Fsm:SetFuelThreshold( DefenderSquadron.FuelThreshold or self.DefenderDefault.FuelThreshold, 60 )
      AI_A2G_Fsm:SetDamageThreshold( self.DefenderDefault.DamageThreshold )
      AI_A2G_Fsm:SetDisengageRadius( self.DisengageRadius )
      AI_A2G_Fsm:SetTanker( DefenderSquadron.TankerName or self.DefenderDefault.TankerName )
      AI_A2G_Fsm:Start()

      self:SetDefenderTask( SquadronName, DefenderGroup, DefenseTaskType, AI_A2G_Fsm, nil, DefenderGrouping )
      
      function AI_A2G_Fsm:onafterTakeoff( DefenderGroup, From, Event, To )
        self:F({"Takeoff", DefenderGroup:GetName()})
        --self:GetParent(self).onafterBirth( self, Defender, From, Event, To )
        
        local DefenderName = DefenderGroup:GetCallsign() -- #string
        local Dispatcher = AI_A2G_Fsm:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        
        if Squadron then
          if self.SetSendPlayerMessages then
            Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", wheels up.", DefenderGroup )
          end
          AI_A2G_Fsm:Patrol() -- Engage on the TargetSetUnit
        end
      end

      function AI_A2G_Fsm:onafterPatrolRoute( DefenderGroup, From, Event, To )
        self:F({"PatrolRoute", DefenderGroup:GetName()})
        self:GetParent(self).onafterPatrolRoute( self, DefenderGroup, From, Event, To )
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = self:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        if Squadron and self.SetSendPlayerMessages then
          Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", patrolling.", DefenderGroup )
        end

        Dispatcher:ClearDefenderTaskTarget( DefenderGroup )
      end

      function AI_A2G_Fsm:onafterEngageRoute( DefenderGroup, From, Event, To, AttackSetUnit )
        self:F({"Engage Route", DefenderGroup:GetName()})
        
        self:GetParent(self).onafterEngageRoute( self, DefenderGroup, From, Event, To, AttackSetUnit )
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = AI_A2G_Fsm:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        
        if Squadron and AttackSetUnit:Count() > 0 then
          local FirstUnit = AttackSetUnit:GetFirst()
          local Coordinate = FirstUnit:GetCoordinate() -- Core.Point#COORDINATE
          if self.SetSendPlayerMessages then
            Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", moving on to ground target at " .. Coordinate:ToStringA2G( DefenderGroup ), DefenderGroup )
          end
        end
      end

      function AI_A2G_Fsm:OnAfterEngage( DefenderGroup, From, Event, To, AttackSetUnit )
        self:F({"Engage Route", DefenderGroup:GetName()})
        --self:GetParent(self).onafterBirth( self, Defender, From, Event, To )
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = AI_A2G_Fsm:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        local FirstUnit = AttackSetUnit:GetFirst()
        if FirstUnit then
          local Coordinate = FirstUnit:GetCoordinate()
          if self.SetSendPlayerMessages then
            Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", engaging ground target at " .. Coordinate:ToStringA2G( DefenderGroup ), DefenderGroup )
          end
        end
      end

      function AI_A2G_Fsm:onafterRTB( DefenderGroup, From, Event, To )
        self:F({"RTB", DefenderGroup:GetName()})
        self:GetParent(self).onafterRTB( self, DefenderGroup, From, Event, To )
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = self:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        if self.SetSendPlayerMessages then
          Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", returning to base.", DefenderGroup )
        end
        Dispatcher:ClearDefenderTaskTarget( DefenderGroup )
      end

      --- @param #AI_A2G_DISPATCHER self
      function AI_A2G_Fsm:onafterLostControl( DefenderGroup, From, Event, To )
        self:F({"LostControl", DefenderGroup:GetName()})
        self:GetParent(self).onafterHome( self, DefenderGroup, From, Event, To )
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = AI_A2G_Fsm:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        if self.SetSendPlayerMessages then
          Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", lost control." )
        end
        if DefenderGroup:IsAboveRunway() then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, DefenderGroup )
          DefenderGroup:Destroy()
        end
      end
      
      --- @param #AI_A2G_DISPATCHER self
      function AI_A2G_Fsm:onafterHome( DefenderGroup, From, Event, To, Action )
        self:F({"Home", DefenderGroup:GetName()})
        self:GetParent(self).onafterHome( self, DefenderGroup, From, Event, To )
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = self:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        if self.SetSendPlayerMessages then
          Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", landing at base.", DefenderGroup )
        end
        if Action and Action == "Destroy" then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, DefenderGroup )
          DefenderGroup:Destroy()
        end

        if Dispatcher:GetSquadronLanding( Squadron.Name ) == AI_A2G_DISPATCHER.Landing.NearAirbase then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, DefenderGroup )
          DefenderGroup:Destroy()
          Dispatcher:ResourcePark( Squadron, DefenderGroup )
        end
      end
    end

  end
  
  
  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:ResourceEngage( DefenderSquadron, DefendersNeeded, Defense, DefenseTaskType, AttackerDetection, SquadronName )
    
    self:F({DefenderSquadron=DefenderSquadron})
    self:F({DefendersNeeded=DefendersNeeded})
    self:F({Defense=Defense})
    self:F({DefenseTaskType=DefenseTaskType})
    self:F({AttackerDetection=AttackerDetection})
    self:F({SquadronName=SquadronName})
    
    local DefenderGroup, DefenderGrouping = self:ResourceActivate( DefenderSquadron, DefendersNeeded )    

    if DefenderGroup then

      local AI_A2G_ENGAGE = { SEAD = AI_A2G_SEAD, BAI = AI_A2G_BAI, CAS = AI_A2G_CAS }

      local AI_A2G_Fsm = AI_A2G_ENGAGE[DefenseTaskType]:New( DefenderGroup, Defense.EngageMinSpeed, Defense.EngageMaxSpeed, Defense.EngageFloorAltitude, Defense.EngageCeilingAltitude, Defense.EngageAltType ) -- AI.AI_AIR_ENGAGE
      AI_A2G_Fsm:SetDispatcher( self )
      AI_A2G_Fsm:SetHomeAirbase( DefenderSquadron.Airbase )
      AI_A2G_Fsm:SetFuelThreshold( DefenderSquadron.FuelThreshold or self.DefenderDefault.FuelThreshold, 60 )
      AI_A2G_Fsm:SetDamageThreshold( self.DefenderDefault.DamageThreshold )
      AI_A2G_Fsm:SetDisengageRadius( self.DisengageRadius )
      AI_A2G_Fsm:Start()

      self:SetDefenderTask( SquadronName, DefenderGroup, DefenseTaskType, AI_A2G_Fsm, AttackerDetection, DefenderGrouping )
      
      function AI_A2G_Fsm:onafterTakeoff( DefenderGroup, From, Event, To )
        self:F({"Defender Birth", DefenderGroup:GetName()})
        --self:GetParent(self).onafterBirth( self, Defender, From, Event, To )
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = AI_A2G_Fsm:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        local DefenderTarget = Dispatcher:GetDefenderTaskTarget( DefenderGroup )
        
        self:F( { DefenderTarget = DefenderTarget } )
        
        if DefenderTarget then
          if self.SetSendPlayerMessages then
            Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", wheels up.", DefenderGroup )
          end
          AI_A2G_Fsm:EngageRoute( DefenderTarget.Set ) -- Engage on the TargetSetUnit
        end
      end

      function AI_A2G_Fsm:onafterEngageRoute( DefenderGroup, From, Event, To, AttackSetUnit )
        self:F({"Engage Route", DefenderGroup:GetName()})
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = AI_A2G_Fsm:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        
        if Squadron then
          local FirstUnit = AttackSetUnit:GetFirst()
          local Coordinate = FirstUnit:GetCoordinate() -- Core.Point#COORDINATE
           if self.SetSendPlayerMessages then
            Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", on route to ground target at " .. Coordinate:ToStringA2G( DefenderGroup ), DefenderGroup )
           end
        end
        self:GetParent(self).onafterEngageRoute( self, DefenderGroup, From, Event, To, AttackSetUnit )
      end

      function AI_A2G_Fsm:OnAfterEngage( DefenderGroup, From, Event, To, AttackSetUnit )
        self:F({"Engage Route", DefenderGroup:GetName()})
        --self:GetParent(self).onafterBirth( self, Defender, From, Event, To )
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = AI_A2G_Fsm:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        local FirstUnit = AttackSetUnit:GetFirst()
        if FirstUnit then
          local Coordinate = FirstUnit:GetCoordinate()
          if self.SetSendPlayerMessages then
            Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", engaging ground target at " .. Coordinate:ToStringA2G( DefenderGroup ), DefenderGroup )
          end
        end
      end

      function AI_A2G_Fsm:onafterRTB( DefenderGroup, From, Event, To )
        self:F({"Defender RTB", DefenderGroup:GetName()})
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = self:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        if self.SetSendPlayerMessages then
          Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", returning to base.", DefenderGroup )
        end
        self:GetParent(self).onafterRTB( self, DefenderGroup, From, Event, To )

        Dispatcher:ClearDefenderTaskTarget( DefenderGroup )
      end

      --- @param #AI_A2G_DISPATCHER self
      function AI_A2G_Fsm:onafterLostControl( DefenderGroup, From, Event, To )
        self:F({"Defender LostControl", DefenderGroup:GetName()})
        self:GetParent(self).onafterHome( self, DefenderGroup, From, Event, To )
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = AI_A2G_Fsm:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        if self.SetSendPlayerMessages then
          Dispatcher:MessageToPlayers( Squadron,  "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " lost control." )
        end
        if DefenderGroup:IsAboveRunway() then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, DefenderGroup )
          DefenderGroup:Destroy()
        end
      end
      
      --- @param #AI_A2G_DISPATCHER self
      function AI_A2G_Fsm:onafterHome( DefenderGroup, From, Event, To, Action )
        self:F({"Defender Home", DefenderGroup:GetName()})
        self:GetParent(self).onafterHome( self, DefenderGroup, From, Event, To )
        
        local DefenderName = DefenderGroup:GetCallsign()
        local Dispatcher = self:GetDispatcher() -- #AI_A2G_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( DefenderGroup )
        if self.SetSendPlayerMessages then
          Dispatcher:MessageToPlayers( Squadron,  DefenderName .. ", landing at base.", DefenderGroup )
        end
        if Action and Action == "Destroy" then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, DefenderGroup )
          DefenderGroup:Destroy()
        end

        if Dispatcher:GetSquadronLanding( Squadron.Name ) == AI_A2G_DISPATCHER.Landing.NearAirbase then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, DefenderGroup )
          DefenderGroup:Destroy()
          Dispatcher:ResourcePark( Squadron, DefenderGroup )
        end
      end
    end
  end

  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:onafterEngage( From, Event, To, AttackerDetection, Defenders )
  
    if Defenders then

      for DefenderID, Defender in pairs( Defenders or {} ) do

        local Fsm = self:GetDefenderTaskFsm( Defender )
        Fsm:Engage( AttackerDetection.Set ) -- Engage on the TargetSetUnit
        
        self:SetDefenderTaskTarget( Defender, AttackerDetection )

      end
    end
  end

  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:HasDefenseLine( DefenseCoordinate, DetectedItem )

    local AttackCoordinate = self.Detection:GetDetectedItemCoordinate( DetectedItem )
    local EvaluateDistance = AttackCoordinate:Get2DDistance( DefenseCoordinate )

    -- Now check if this coordinate is not in a danger zone, meaning, that the attack line is not crossing other coordinates.
    -- (y1 - y2)x + (x2 - x1)y + (x1y2 - x2y1) = 0
    
    local c1 = DefenseCoordinate
    local c2 = AttackCoordinate
    
    local a = c1.z - c2.z -- Calculate a
    local b = c2.x - c1.x -- Calculate b
    local c = c1.x * c2.z - c2.x * c1.z -- calculate c
    
    local ok = true
    
    -- Now we check if each coordinate radius of about 30km of each attack is crossing a defense line. If yes, then this is not a good attack!
    for AttackItemID, CheckAttackItem in pairs( self.Detection:GetDetectedItems() ) do
    
      -- Only compare other detected coordinates.
      if AttackItemID ~= DetectedItem.ID then
    
        local CheckAttackCoordinate = self.Detection:GetDetectedItemCoordinate( CheckAttackItem )
        
        local x = CheckAttackCoordinate.x
        local y = CheckAttackCoordinate.z
        local r = 5000
        
        -- now we check if the coordinate is intersecting with the defense line.
        
        local IntersectDistance = ( math.abs( a * x + b * y + c ) ) / math.sqrt( a * a + b * b )
        self:F( { IntersectDistance = IntersectDistance, x = x, y = y } )
        
        local IntersectAttackDistance = CheckAttackCoordinate:Get2DDistance( DefenseCoordinate )
        
        self:F( { IntersectAttackDistance=IntersectAttackDistance, EvaluateDistance=EvaluateDistance } )
        
        -- If the distance of the attack coordinate is larger than the test radius; then the line intersects, and this is not a good coordinate.
        if IntersectDistance < r and IntersectAttackDistance < EvaluateDistance then
          ok = false
          break
        end
      end
    end
    
    return ok
  end

  ---
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:onafterDefend( From, Event, To, DetectedItem, DefendersTotal, DefendersEngaged, DefendersMissing, DefenderFriendlies, DefenseTaskType )

    self:F( { From, Event, To, DetectedItem.Index, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing, DefenderFriendlies = DefenderFriendlies } )

    DetectedItem.Type = DefenseTaskType -- This is set to report the task type in the status panel.

    local AttackerSet = DetectedItem.Set
    local AttackerUnit = AttackerSet:GetFirst()
    
    if AttackerUnit and AttackerUnit:IsAlive() then
      local AttackerCount = AttackerSet:Count()
      local DefenderCount = 0
  
      for DefenderID, DefenderGroup in pairs( DefenderFriendlies or {} ) do

        -- Here we check if the defenders have a defense line to the attackers.
        -- If the attackers are behind enemy lines or too close to an other defense line; then don't engage.
        local DefenseCoordinate = DefenderGroup:GetCoordinate()
        local HasDefenseLine = self:HasDefenseLine( DefenseCoordinate, DetectedItem )
  
        if HasDefenseLine == true then
          local SquadronName = self:GetDefenderTask( DefenderGroup ).SquadronName
          local SquadronOverhead = self:GetSquadronOverhead( SquadronName )
  
          local Fsm = self:GetDefenderTaskFsm( DefenderGroup )
          Fsm:EngageRoute( AttackerSet ) -- Engage on the TargetSetUnit
          
          self:SetDefenderTaskTarget( DefenderGroup, DetectedItem )
    
          local DefenderGroupSize = DefenderGroup:GetSize()
          DefendersMissing = DefendersMissing - DefenderGroupSize / SquadronOverhead
          DefendersTotal = DefendersTotal + DefenderGroupSize / SquadronOverhead
        end
        
        if DefendersMissing <= 0 then
          break
        end
      end
  
      self:F( { DefenderCount = DefenderCount, DefendersMissing = DefendersMissing } )
      DefenderCount = DefendersMissing
  
      local ClosestDistance = 0
      local EngageSquadronName = nil
      
      local BreakLoop = false
      
      while( DefenderCount > 0 and not BreakLoop ) do
      
        self:F( { DefenderSquadrons = self.DefenderSquadrons } )

        for SquadronName, DefenderSquadron in UTILS.rpairs( self.DefenderSquadrons or {} ) do
        
          if DefenderSquadron[DefenseTaskType] then

            local AirbaseCoordinate = DefenderSquadron.Airbase:GetCoordinate() -- Core.Point#COORDINATE
            local AttackerCoord = AttackerUnit:GetCoordinate()
            local InterceptCoord = DetectedItem.InterceptCoord
            self:F( { InterceptCoord = InterceptCoord } )
            if InterceptCoord then
              local InterceptDistance = AirbaseCoordinate:Get2DDistance( InterceptCoord )
              local AirbaseDistance = AirbaseCoordinate:Get2DDistance( AttackerCoord )
              self:F( { InterceptDistance = InterceptDistance, AirbaseDistance = AirbaseDistance, InterceptCoord = InterceptCoord } )
              
              -- Only intercept if the distance to target is smaller or equal to the GciRadius limit.
              if AirbaseDistance <= self.DefenseRadius then
              
                -- Check if there is a defense line...
                local HasDefenseLine = self:HasDefenseLine( AirbaseCoordinate, DetectedItem )
                if HasDefenseLine == true then
                  local EngageProbability = ( DefenderSquadron.EngageProbability or 1 )
                  local Probability = math.random()
                  if Probability < EngageProbability then
                    EngageSquadronName = SquadronName
                    break
                  end
                end
              end
            end
          end
        end
        
        if EngageSquadronName then
        
          local DefenderSquadron, Defense = self:CanDefend( EngageSquadronName, DefenseTaskType )
          
          if Defense then
  
              local DefenderOverhead = DefenderSquadron.Overhead or self.DefenderDefault.Overhead
              local DefenderGrouping = DefenderSquadron.Grouping or self.DefenderDefault.Grouping
              local DefendersNeeded = math.ceil( DefenderCount * DefenderOverhead )
              
              self:F( { Overhead = DefenderOverhead, SquadronOverhead = DefenderSquadron.Overhead , DefaultOverhead = self.DefenderDefault.Overhead } )
              self:F( { Grouping = DefenderGrouping, SquadronGrouping = DefenderSquadron.Grouping, DefaultGrouping = self.DefenderDefault.Grouping } )
              self:F( { DefendersCount = DefenderCount, DefendersNeeded = DefendersNeeded } )

              -- Validate that the maximum limit of Defenders has been reached.
              -- If yes, then cancel the engaging of more defenders.
              local DefendersLimit = DefenderSquadron.EngageLimit or self.DefenderDefault.EngageLimit
              if DefendersLimit then
                if DefendersTotal >= DefendersLimit then
                  DefendersNeeded = 0
                  BreakLoop = true
                else
                  -- If the total of amount of defenders + the defenders needed, is larger than the limit of defenders,
                  -- then the defenders needed is the difference between defenders total - defenders limit.
                  if DefendersTotal + DefendersNeeded > DefendersLimit then
                    DefendersNeeded =  DefendersLimit - DefendersTotal
                  end
                end
              end
              
              -- DefenderSquadron.ResourceCount can have the value nil, which expresses unlimited resources.
              -- DefendersNeeded cannot exceed DefenderSquadron.ResourceCount!
              if DefenderSquadron.ResourceCount and DefendersNeeded > DefenderSquadron.ResourceCount then
                DefendersNeeded = DefenderSquadron.ResourceCount
                BreakLoop = true
              end
              
              while ( DefendersNeeded > 0 ) do
                self:ResourceQueue( false, DefenderSquadron, DefendersNeeded, Defense, DefenseTaskType, DetectedItem, EngageSquadronName )
                DefendersNeeded = DefendersNeeded - DefenderGrouping
                DefenderCount = DefenderCount - DefenderGrouping / DefenderOverhead
              end  -- while ( DefendersNeeded > 0 ) do
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



  --- Creates an SEAD task when the targets have radars.
  -- @param #AI_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.
  -- @return Core.Set#SET_UNIT The set of units of the targets to be engaged.
  -- @return #nil If there are no targets to be set.
  function AI_A2G_DISPATCHER:Evaluate_SEAD( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    local AttackerSet = DetectedItem.Set -- Core.Set#SET_UNIT
    local AttackerCount = AttackerSet:HasSEAD() -- Is the AttackerSet a SEAD group, then the amount of radar emitters will be returned; that need to be attacked.
    
    if ( AttackerCount > 0 ) then
    
      -- First, count the active defenders, engaging the DetectedItem.
      local DefendersTotal, DefendersEngaged, DefendersMissing = self:CountDefendersEngaged( DetectedItem, AttackerCount )
      
      self:F( { AttackerCount = AttackerCount, DefendersTotal = DefendersTotal, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing } )
  
      local DefenderGroups = self:CountDefenders( DetectedItem, DefendersEngaged, "SEAD" )
      
      
  
      if DetectedItem.IsDetected == true then
        
        return DefendersTotal, DefendersEngaged, DefendersMissing, DefenderGroups
      end
    end
    
    return 0, 0, 0
  end


  --- Creates an CAS task.
  -- @param #AI_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.
  -- @return Core.Set#SET_UNIT The set of units of the targets to be engaged.
  -- @return #nil If there are no targets to be set.
  function AI_A2G_DISPATCHER:Evaluate_CAS( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    local AttackerSet = DetectedItem.Set -- Core.Set#SET_UNIT
    local AttackerCount = AttackerSet:Count()
    local AttackerRadarCount = AttackerSet:HasSEAD()
    local IsFriendliesNearBy = self.Detection:IsFriendliesNearBy( DetectedItem, Unit.Category.GROUND_UNIT )
    local IsCas = ( AttackerRadarCount == 0 ) and ( IsFriendliesNearBy == true ) -- Is the AttackerSet a CAS group?
    
    if IsCas == true then
    
      -- First, count the active defenders, engaging the DetectedItem.
      local DefendersTotal, DefendersEngaged, DefendersMissing = self:CountDefendersEngaged( DetectedItem, AttackerCount )
      
      self:F( { AttackerCount = AttackerCount, DefendersTotal = DefendersTotal, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing } )
  
      local DefenderGroups = self:CountDefenders( DetectedItem, DefendersEngaged, "CAS" )
  
      if DetectedItem.IsDetected == true then
        
        return DefendersTotal, DefendersEngaged, DefendersMissing, DefenderGroups
      end
    end
    
    return 0, 0, 0
  end


  --- Evaluates an BAI task.
  -- @param #AI_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.
  -- @return Core.Set#SET_UNIT The set of units of the targets to be engaged.
  -- @return #nil If there are no targets to be set.
  function AI_A2G_DISPATCHER:Evaluate_BAI( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    local AttackerSet = DetectedItem.Set -- Core.Set#SET_UNIT
    local AttackerCount = AttackerSet:Count()
    local AttackerRadarCount = AttackerSet:HasSEAD()
    local IsFriendliesNearBy = self.Detection:IsFriendliesNearBy( DetectedItem, Unit.Category.GROUND_UNIT )
    local IsBai = ( AttackerRadarCount == 0 ) and ( IsFriendliesNearBy == false ) -- Is the AttackerSet a BAI group?
    
    if IsBai == true then
    
      -- First, count the active defenders, engaging the DetectedItem.
      local DefendersTotal, DefendersEngaged, DefendersMissing = self:CountDefendersEngaged( DetectedItem, AttackerCount )
  
      self:F( { AttackerCount = AttackerCount, DefendersTotal = DefendersTotal, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing } )
  
      local DefenderGroups = self:CountDefenders( DetectedItem, DefendersEngaged, "BAI" )
  
      if DetectedItem.IsDetected == true then
        
        return DefendersTotal, DefendersEngaged, DefendersMissing, DefenderGroups
      end
    end
    
    return 0, 0, 0
  end


  --- Determine the distance as the keys of reference of the detected items.
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:Keys( DetectedItem )
  
    self:F( { DetectedItem = DetectedItem } )
  
    local AttackCoordinate = self.Detection:GetDetectedItemCoordinate( DetectedItem )
    
    local ShortestDistance = 999999999
  
    for DefenseCoordinateName, DefenseCoordinate in pairs( self.DefenseCoordinates ) do
      local DefenseCoordinate = DefenseCoordinate -- Core.Point#COORDINATE

      local EvaluateDistance = AttackCoordinate:Get2DDistance( DefenseCoordinate )
      
      if EvaluateDistance <= ShortestDistance then
        ShortestDistance = EvaluateDistance
      end
    end
    
    return ShortestDistance
  end


  --- Assigns A2G AI Tasks in relation to the detected items.
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:Order( DetectedItem )
    local AttackCoordinate = self.Detection:GetDetectedItemCoordinate( DetectedItem )
    
    local ShortestDistance = 999999999
  
    for DefenseCoordinateName, DefenseCoordinate in pairs( self.DefenseCoordinates ) do
      local DefenseCoordinate = DefenseCoordinate -- Core.Point#COORDINATE

      local EvaluateDistance = AttackCoordinate:Get2DDistance( DefenseCoordinate )
      
      if EvaluateDistance <= ShortestDistance then
        ShortestDistance = EvaluateDistance
      end
    end
    
    return ShortestDistance
  end
  

  --- Shows the tactical display.
  -- @param #AI_A2G_DISPATCHER self
  function AI_A2G_DISPATCHER:ShowTacticalDisplay( Detection )

    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}
    
    local TaskReport = REPORT:New()

    local DefenseTotal = 0

    local Report = REPORT:New( "\nTactical Overview" )

    local DefenderGroupCount = 0
    local DefendersTotal = 0

    -- Now that all obsolete tasks are removed, loop through the detected targets.
    --for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
    for DetectedItemID, DetectedItem in UTILS.spairs( Detection:GetDetectedItems(), function( t, a, b ) return self:Order(t[a]) <  self:Order(t[b]) end  ) do
    
      if not self.Detection:IsDetectedItemLocked( DetectedItem ) == true then
        local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
        local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
        local DetectedCount = DetectedSet:Count()
        local DetectedZone = DetectedItem.Zone
  
        self:F( { "Target ID", DetectedItem.ItemID } )
        
        self:F( { DefenseLimit = self.DefenseLimit, DefenseTotal = DefenseTotal } )
        DetectedSet:Flush( self )
  
        local DetectedID = DetectedItem.ID
        local DetectionIndex = DetectedItem.Index
        local DetectedItemChanged = DetectedItem.Changed
  
        -- Show tactical situation
        local ThreatLevel = DetectedItem.Set:CalculateThreatLevelA2G()
        Report:Add( string.format( " - %1s%s ( %04s ): ( #%02d - %-4s ) %s" , ( DetectedItem.IsDetected == true ) and "!" or " ", DetectedItem.ItemID, DetectedItem.Index, DetectedItem.Set:Count(), DetectedItem.Type or " --- ", string.rep(   "■",  ThreatLevel ) ) )
        for Defender, DefenderTask in pairs( self:GetDefenderTasks() ) do
          local Defender = Defender -- Wrapper.Group#GROUP
           if DefenderTask.Target and DefenderTask.Target.Index == DetectedItem.Index then
             if Defender:IsAlive() then
               DefenderGroupCount = DefenderGroupCount + 1
               local Fuel = Defender:GetFuelMin() * 100
               local Damage = Defender:GetLife() / Defender:GetLife0() * 100
               Report:Add( string.format( "   - %s ( %s - %s ): ( #%d ) F: %3d, D:%3d - %s", 
                                          Defender:GetName(), 
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
    end

    Report:Add( "\n - No Targets:")
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
          Report:Add( string.format( "   - %s ( %s - %s ): ( #%d ) F: %3d, D:%3d - %s", 
                                     Defender:GetName(), 
                                     DefenderTask.Type, 
                                     DefenderTask.Fsm:GetState(), 
                                     Defender:GetSize(),
                                     Fuel,
                                     Damage, 
                                     Defender:HasTask() == true and "Executing" or "Idle" ) )
        end
      end
    end
    Report:Add( string.format( "\n - %d Tasks - %d Defender Groups", TaskCount, DefenderGroupCount ) )

    Report:Add( string.format( "\n - %d Queued Aircraft Launches", #self.DefenseQueue ) )
    for DefenseQueueID, DefenseQueueItem in pairs( self.DefenseQueue ) do
      local DefenseQueueItem = DefenseQueueItem -- #AI_A2G_DISPATCHER.DefenseQueueItem
      Report:Add( string.format( "   - %s - %s", DefenseQueueItem.SquadronName, DefenseQueueItem.DefenderSquadron.TakeoffTime, DefenseQueueItem.DefenderSquadron.TakeoffInterval) )
      
    end
    
    Report:Add( string.format( "\n - Squadron Resources: ", #self.DefenseQueue ) )
    for DefenderSquadronName, DefenderSquadron in pairs( self.DefenderSquadrons ) do
      Report:Add( string.format( "   - %s - %s", DefenderSquadronName, DefenderSquadron.ResourceCount and tostring(DefenderSquadron.ResourceCount) or "n/a" ) )
    end

    self:F( Report:Text( "\n" ) )
    trigger.action.outText( Report:Text( "\n" ), 25 )
    
  end


  --- Assigns A2G AI Tasks in relation to the detected items.
  -- @param #AI_A2G_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Functional.Detection#DETECTION_BASE} derived object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function AI_A2G_DISPATCHER:ProcessDetected( Detection )
  
    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}
    
    local TaskReport = REPORT:New()

    local DefenseTotal = 0
          
    for DefenderGroup, DefenderTask in pairs( self:GetDefenderTasks() ) do
      local DefenderGroup = DefenderGroup -- Wrapper.Group#GROUP
      local DefenderTaskFsm = self:GetDefenderTaskFsm( DefenderGroup )
      --if DefenderTaskFsm:Is( "LostControl" ) then
      --  self:ClearDefenderTask( DefenderGroup )
      --end
      if not DefenderGroup:IsAlive() then
        self:F( { Defender = DefenderGroup:GetName(), DefenderState = DefenderTaskFsm:GetState() } )
        if not DefenderTaskFsm:Is( "Started" ) then
          self:ClearDefenderTask( DefenderGroup )
        end
      else
      -- TODO: prio 1, what is this index stuff again, simplify it.
        if DefenderTask.Target then
        self:F( { TargetIndex = DefenderTask.Target.Index } )
          local AttackerItem = Detection:GetDetectedItemByIndex( DefenderTask.Target.Index )
          if not AttackerItem then
            self:F( { "Removing obsolete Target:", DefenderTask.Target.Index } )
            self:ClearDefenderTaskTarget( DefenderGroup )
          else
            if DefenderTask.Target.Set then
              local TargetCount = DefenderTask.Target.Set:Count()
              if TargetCount == 0 then
                self:F( { "All Targets destroyed in Target, removing:", DefenderTask.Target.Index } )
                self:ClearDefenderTask( DefenderGroup )
              end
            end
          end
        end
      end
    end

--    for DefenderGroup, DefenderTask in pairs( self:GetDefenderTasks() ) do
--      DefenseTotal = DefenseTotal + 1
--    end
    
    local Report = REPORT:New( "\nTactical Overview" )

    local DefenderGroupCount = 0

    local DefendersTotal = 0

    -- Now that all obsolete tasks are removed, loop through the detected targets.
    --for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
    for DetectedDistance, DetectedItem in UTILS.kpairs( Detection:GetDetectedItems(), function( t ) return self:Keys( t ) end, function( t, a, b ) return self:Order(t[a]) <  self:Order(t[b]) end  ) do
    
      if not self.Detection:IsDetectedItemLocked( DetectedItem ) == true then
        local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
        local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
        local DetectedCount = DetectedSet:Count()
        local DetectedZone = DetectedItem.Zone
  
        self:F( { "Target ID", DetectedItem.ItemID } )
        
        self:F( { DefenseLimit = self.DefenseLimit, DefenseTotal = DefenseTotal } )
        DetectedSet:Flush( self )
  
        local DetectedID = DetectedItem.ID
        local DetectionIndex = DetectedItem.Index
        local DetectedItemChanged = DetectedItem.Changed
        
        local AttackCoordinate = self.Detection:GetDetectedItemCoordinate( DetectedItem )
        
        -- Calculate if for this DetectedItem if a defense needs to be initiated.
        -- This calculation is based on the distance between the defense point and the attackers, and the defensiveness parameter.
        -- The attackers closest to the defense coordinates will be handled first, or course!

        local EngageDefenses = nil        
          
        self:F( { DetectedDistance = DetectedDistance, DefenseRadius = self.DefenseRadius } )
        if DetectedDistance <= self.DefenseRadius then
        
          self:F( { DetectedApproach = self._DefenseApproach } )
          if self._DefenseApproach == AI_A2G_DISPATCHER.DefenseApproach.Distance then
            EngageDefenses = true
            self:F( { EngageDefenses = EngageDefenses } )
          end

          if self._DefenseApproach == AI_A2G_DISPATCHER.DefenseApproach.Random then
            local DistanceProbability = ( self.DefenseRadius / DetectedDistance * self.DefenseReactivity )
            local DefenseProbability = math.random()
  
            self:F( { DistanceProbability = DistanceProbability, DefenseProbability = DefenseProbability } )
  
            if DefenseProbability <= DistanceProbability / ( 300 / 30 ) then
              EngageDefenses = true
            end
          end
          
          
        end
        
        self:F( { EngageDefenses = EngageDefenses, DefenseLimit = self.DefenseLimit, DefenseTotal = DefenseTotal } )
        
        -- There needs to be an EngageCoordinate.
        -- If self.DefenseLimit is set (thus limit the amount of defenses to one zone), then only start a new defense if the maximum has not been reached.
        -- If self.DefenseLimit has not been set, there is an unlimited amount of zones to be defended.
        if ( EngageDefenses and ( self.DefenseLimit and DefenseTotal < self.DefenseLimit ) or not self.DefenseLimit ) then
          do 
            local DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies = self:Evaluate_SEAD( DetectedItem ) -- Returns a SET_UNIT with the SEAD targets to be engaged...
            if DefendersMissing > 0 then
              self:F( { DefendersTotal = DefendersTotal, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing } )
              self:Defend( DetectedItem, DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies, "SEAD" )
            end
          end
    
          do 
            local DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies = self:Evaluate_CAS( DetectedItem ) -- Returns a SET_UNIT with the CAS targets to be engaged...
            if DefendersMissing > 0 then
              self:F( { DefendersTotal = DefendersTotal, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing } )
              self:Defend( DetectedItem, DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies, "CAS" )
            end
          end
    
          do 
            local DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies = self:Evaluate_BAI( DetectedItem ) -- Returns a SET_UNIT with the CAS targets to be engaged...
            if DefendersMissing > 0 then
              self:F( { DefendersTotal = DefendersTotal, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing } )
              self:Defend( DetectedItem, DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies, "BAI" )
            end
          end
        end
        
        for Defender, DefenderTask in pairs( self:GetDefenderTasks() ) do
          local Defender = Defender -- Wrapper.Group#GROUP
          if DefenderTask.Target and DefenderTask.Target.Index == DetectedItem.Index then
            DefenseTotal = DefenseTotal + 1
          end
        end
        
        for DefenseQueueID, DefenseQueueItem in pairs( self.DefenseQueue ) do
          local DefenseQueueItem = DefenseQueueItem -- #AI_A2G_DISPATCHER.DefenseQueueItem
          if DefenseQueueItem.AttackerDetection and DefenseQueueItem.AttackerDetection.Index and DefenseQueueItem.AttackerDetection.Index == DetectedItem.Index then
            DefenseTotal = DefenseTotal + 1
          end
        end
  
        if self.TacticalDisplay then      
          -- Show tactical situation
          local ThreatLevel = DetectedItem.Set:CalculateThreatLevelA2G()
          Report:Add( string.format( " - %1s%s ( %4s ): ( #%d - %4s ) %s" , ( DetectedItem.IsDetected == true ) and "!" or " ", DetectedItem.ItemID, DetectedItem.Index, DetectedItem.Set:Count(), DetectedItem.Type or " --- ", string.rep(   "■", ThreatLevel ) ) )
          for Defender, DefenderTask in pairs( self:GetDefenderTasks() ) do
            local Defender = Defender -- Wrapper.Group#GROUP
             if DefenderTask.Target and DefenderTask.Target.Index == DetectedItem.Index then
               if Defender:IsAlive() then
                 DefenderGroupCount = DefenderGroupCount + 1
                 local Fuel = Defender:GetFuelMin() * 100
                 local Damage = Defender:GetLife() / Defender:GetLife0() * 100
                 Report:Add( string.format( "   - %s ( %s - %s ): ( #%d ) F: %3d, D:%3d - %s", 
                                            Defender:GetName(), 
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
      end
    end

    if self.TacticalDisplay then
      Report:Add( "\n - No Targets:")
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
            Report:Add( string.format( "   - %s ( %s - %s ): ( #%d ) F: %3d, D:%3d - %s", 
                                       Defender:GetName(), 
                                       DefenderTask.Type, 
                                       DefenderTask.Fsm:GetState(), 
                                       Defender:GetSize(),
                                       Fuel,
                                       Damage, 
                                       Defender:HasTask() == true and "Executing" or "Idle" ) )
          end
        end
      end
      Report:Add( string.format( "\n - %d Tasks - %d Defender Groups", TaskCount, DefenderGroupCount ) )

      Report:Add( string.format( "\n - %d Queued Aircraft Launches", #self.DefenseQueue ) )
      for DefenseQueueID, DefenseQueueItem in pairs( self.DefenseQueue ) do
        local DefenseQueueItem = DefenseQueueItem -- #AI_A2G_DISPATCHER.DefenseQueueItem
        Report:Add( string.format( "   - %s - %s", DefenseQueueItem.SquadronName, DefenseQueueItem.DefenderSquadron.TakeoffTime, DefenseQueueItem.DefenderSquadron.TakeoffInterval) )
        
      end

      Report:Add( string.format( "\n - Squadron Resources: ", #self.DefenseQueue ) )
      for DefenderSquadronName, DefenderSquadron in pairs( self.DefenderSquadrons ) do
        Report:Add( string.format( "   - %s - %s", DefenderSquadronName, DefenderSquadron.ResourceCount and tostring(DefenderSquadron.ResourceCount) or "n/a" ) )
      end
  
      self:F( Report:Text( "\n" ) )
      trigger.action.outText( Report:Text( "\n" ), 25 )
    end
    
    return true
  end

end

do

  --- Calculates which HUMAN friendlies are nearby the area.
  -- @param #AI_A2G_DISPATCHER self
  -- @param DetectedItem The detected item.
  -- @return #number, Core.Report#REPORT The amount of friendlies and a text string explaining which friendlies of which type.
  function AI_A2G_DISPATCHER:GetPlayerFriendliesNearBy( DetectedItem )
  
    local DetectedSet = DetectedItem.Set
    local PlayersNearBy = self.Detection:GetPlayersNearBy( DetectedItem )
    
    local PlayerTypes = {}
    local PlayersCount = 0

    if PlayersNearBy then
      local DetectedThreatLevel = DetectedSet:CalculateThreatLevelA2G()
      for PlayerUnitName, PlayerUnitData in pairs( PlayersNearBy ) do
        local PlayerUnit = PlayerUnitData -- Wrapper.Unit#UNIT
        local PlayerName = PlayerUnit:GetPlayerName()
        --self:F( { PlayerName = PlayerName, PlayerUnit = PlayerUnit } )
        if PlayerUnit:IsAirPlane() and PlayerName ~= nil then
          local FriendlyUnitThreatLevel = PlayerUnit:GetThreatLevel()
          PlayersCount = PlayersCount + 1
          local PlayerType = PlayerUnit:GetTypeName()
          PlayerTypes[PlayerName] = PlayerType
          if DetectedThreatLevel < FriendlyUnitThreatLevel + 2 then
          end
        end
      end
      
    end

    --self:F( { PlayersCount = PlayersCount } )
    
    local PlayerTypesReport = REPORT:New()
    
    if PlayersCount > 0 then
      for PlayerName, PlayerType in pairs( PlayerTypes ) do
        PlayerTypesReport:Add( string.format('"%s" in %s', PlayerName, PlayerType ) )
      end
    else
      PlayerTypesReport:Add( "-" )
    end
    
    
    return PlayersCount, PlayerTypesReport
  end

  --- Calculates which friendlies are nearby the area.
  -- @param #AI_A2G_DISPATCHER self
  -- @param DetectedItem The detected item.
  -- @return #number, Core.Report#REPORT The amount of friendlies and a text string explaining which friendlies of which type.
  function AI_A2G_DISPATCHER:GetFriendliesNearBy( DetectedItem )
  
    local DetectedSet = DetectedItem.Set
    local FriendlyUnitsNearBy = self.Detection:GetFriendliesNearBy( DetectedItem )
    
    local FriendlyTypes = {}
    local FriendliesCount = 0

    if FriendlyUnitsNearBy then
      local DetectedThreatLevel = DetectedSet:CalculateThreatLevelA2G()
      for FriendlyUnitName, FriendlyUnitData in pairs( FriendlyUnitsNearBy ) do
        local FriendlyUnit = FriendlyUnitData -- Wrapper.Unit#UNIT
        if FriendlyUnit:IsAirPlane() then
          local FriendlyUnitThreatLevel = FriendlyUnit:GetThreatLevel()
          FriendliesCount = FriendliesCount + 1
          local FriendlyType = FriendlyUnit:GetTypeName()
          FriendlyTypes[FriendlyType] = FriendlyTypes[FriendlyType] and ( FriendlyTypes[FriendlyType] + 1 ) or 1
          if DetectedThreatLevel < FriendlyUnitThreatLevel + 2 then
          end
        end
      end
      
    end

    --self:F( { FriendliesCount = FriendliesCount } )
    
    local FriendlyTypesReport = REPORT:New()
    
    if FriendliesCount > 0 then
      for FriendlyType, FriendlyTypeCount in pairs( FriendlyTypes ) do
        FriendlyTypesReport:Add( string.format("%d of %s", FriendlyTypeCount, FriendlyType ) )
      end
    else
      FriendlyTypesReport:Add( "-" )
    end
    
    
    return FriendliesCount, FriendlyTypesReport
  end

  --- Schedules a new Patrol for the given SquadronName.
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  function AI_A2G_DISPATCHER:SchedulerPatrol( SquadronName )
    local PatrolTaskTypes = { "SEAD", "CAS", "BAI" }
    local PatrolTaskType = PatrolTaskTypes[math.random(1,3)]
    self:Patrol( SquadronName, PatrolTaskType )    
  end
  
    --- Set flashing player messages on or off
  -- @param #AI_A2G_DISPATCHER self
  -- @param #boolean onoff Set messages on (true) or off (false)
  function AI_A2G_DISPATCHER:SetSendMessages( onoff )
      self.SetSendPlayerMessages = onoff
  end
end

  --- Add resources to a Squadron
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string Squadron The squadron name.
  -- @param #number Amount Number of resources to add.
  function AI_A2G_DISPATCHER:AddToSquadron(Squadron,Amount)
    local Squadron = self:GetSquadron(Squadron)
    if Squadron.ResourceCount then
      Squadron.ResourceCount = Squadron.ResourceCount + Amount
    end
    self:T({Squadron = Squadron.Name,SquadronResourceCount = Squadron.ResourceCount})
  end
  
  --- Remove resources from a Squadron
  -- @param #AI_A2G_DISPATCHER self
  -- @param #string Squadron The squadron name.
  -- @param #number Amount Number of resources to remove.
  function AI_A2G_DISPATCHER:RemoveFromSquadron(Squadron,Amount)
    local Squadron = self:GetSquadron(Squadron)
    if Squadron.ResourceCount then
      Squadron.ResourceCount = Squadron.ResourceCount - Amount
    end
    self:T({Squadron = Squadron.Name,SquadronResourceCount = Squadron.ResourceCount})
  end