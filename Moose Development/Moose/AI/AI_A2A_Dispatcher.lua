--- **AI** - The AI_A2A_DISPATCHER creates and manages AI_A2A tasks based on detected targets.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====
-- 
-- @module AI_A2A_Dispatcher

BASE:TraceClass("AI_A2A_DISPATCHER")

do -- AI_A2A_DISPATCHER

  --- AI_A2A_DISPATCHER class.
  -- @type AI_A2A_DISPATCHER
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER

  --- # AI_A2A_DISPATCHER class, extends @{Tasking#DETECTION_MANAGER}
  -- 
  -- The @{#AI_A2A_DISPATCHER} class is designed to create an automatic air defence system for a coalition. 
  -- It includes automatic spawning of Combat Air Patrol aircraft (CAP) and Ground Controlled Intercept aircraft (GCI) in response to enemy air movements that are detected by a ground based radar network. 
  -- CAP flights will take off and proceed to designated CAP zones where they will remain on station until the ground radars direct them to intercept detected enemy aircraft or they run short of fuel and must return to base (RTB). When a CAP flight leaves their zone to perform an interception or return to base a new CAP flight will spawn to take their place.
  -- If all CAP flights are engaged or RTB then additional GCI interceptors will scramble to intercept unengaged enemy aircraft under ground radar control.
  -- With a little time and with a little work it provides the mission designer with a convincing and completely automatic air defence system. 
  -- In short it is a plug in very flexible and configurable air defence module for DCS World.
  -- 
  -- Note that in order to create a two way A2A defense system, two AI_A2A_DISPATCHER defense system may need to be created, for each coalition one.
  -- This is a good implementation, because maybe in the future, more coalitions may become available in DCS world.
  -- 
  -- ## AI_A2A_DISPATCHER constructor:
  -- 
  -- The @{#AI_A2A_DISPATCHER.New}() method creates a new AI_A2A_DISPATCHER instance.
  -- There are two parameters required, a @{Set#SET_GROUP} that defines the groups within the EWR network, and a radius in meters, that will be used to group detected targets.
  -- 
  -- ## Which countries will be selected for each coalition?
  -- 
  -- Which countries are assigned to a coalition influences which units are available to the coalition. 
  -- For example because the mission calls for a EWR radar on the blue side the Ukraine might be chosen as a blue country 
  -- so that the 55G6 EWR radar unit is available to blue.  
  -- Some countries assign different tasking to aircraft, for example Germany assigns the CAP task to F-4E Phantoms but the USA does not.  
  -- Therefore if F4s are wanted as a coalition’s CAP or GCI aircraft Germany will need to be assigned to that coalition. 
  -- 
  -- ## Area of red and blue territories?
  -- 
  -- According to the tactical and strategic design of the mission broadly decide the shape and extent of red and blue territories. 
  -- They should be laid out such that a border area is created between the two coalitions.
  -- 
  -- See more below regarding borders.
  -- 
  -- ## Is it a hot or cold war?
  -- 
  -- Define a border area to simulate a **cold war** scenario and use the method @{#AI_A2A_DISPATCHER.InitBorderZone}() to create a border zone for the dispatcher.
  -- 
  -- A **cold war** is one where CAP aircraft patrol their territory but will not attack enemy aircraft or launch GCI aircraft unless enemy aircraft enter their territory. In other words the EWR may detect an enemy aircraft but will only send aircraft to attack it if it crosses the border.
  -- A **hot war** is one where CAP aircraft will intercept any detected enemy aircraft and GCI aircraft will launch against detected enemy aircraft without regard for territory. In other words if the ground radar can detect the enemy aircraft then it will send CAP and GCI aircraft to attack it.
  -- If it’s a cold war then the **borders of red and blue territory** need to be defined using a @{zone} object derived from @{Zone#ZONE_BASE}.
  -- If a hot war is chosen then **no borders** actually need to be defined using the helicopter units other than it makes it easier sometimes for the mission maker to envisage where the red and blue territories roughly are. In a hot war the borders are effectively defined by the ground based radar coverage of a coalition. Set the noborders parameter to 1
  -- 
  -- ## Which squadrons act at which airfields within their territory?
  -- 
  -- **Squadrons** operate at defined airfields, have specific plane types and have limited resources.
  -- 
  -- Use the method @{#AI_A2A_DISPATCHER.SetSquadron}() to setup a new squadron active at an airfield, while defining which plane types are being used by the squadron and how many resources are available.
  -- Note that squadrons have specific settings that need to be specified using the Squadron... methods.
  -- The name of the squadron given acts as the **squadron key** in the AI_A2A_DISPATCHER:Squadron...() methods.
  -- 
  -- ## How are EWR networks defined?
  -- 
  -- Typically EWR networks are setup using 55G6 EWR, 1L13 EWR, Hawk sr and Patriot str ground based radar units. 
  -- These radars have different ranges and 55G6 EWR and 1L13 EWR radars are Eastern Bloc units (eg Russia, Ukraine, Georgia) while the Hawk and Patriot radars are Western (eg US).
  -- Additionally, ANY other radar capable unit can be part of the EWR network! Also AWACS airborne units, planes, helicopters can help to detect targets, as long as they have radar.
  -- The position of these units is very important as they need to provide enough coverage 
  -- to pick up enemy aircraft as they approach so that CAP and GCI flights can be tasked to intercept them. 
  -- Additionally in a hot war situation where the border is no longer respected the placement of radars has a big effect on how fast the war escalates. 
  -- For example if they are a long way forward and can detect enemy planes on the ground and taking off 
  -- they will start to vector CAP and GCI flights to attack them straight away which will immediately draw a response from the other coalition. 
  -- Having the radars further back will mean a slower escalation because fewer targets will be detected and 
  -- therefore less CAP and GCI flights will spawn and this will tend to make just the border area active rather than a melee over the whole map. 
  -- It all depends on what the desired effect is. 
  -- 
  -- EWR networks are dynamically constructed, that is, they form part of the @{Set#SET_GROUP} object that is given as the input parameter of the AI_A2A_DISPATCHER class.
  -- By defining in a smart way the names or name prefixes of the groups of EWR capable units, these units will be automatically added or deleted from the EWR network, 
  -- increasing or decreasing the radar coverage of the Early Warning System.
  -- 
  -- ## How many CAP zones will be required and where will they be located?
  -- 
  --   * CAP zones are patrol areas where Combat Air Patrol (CAP) flights loiter until they either return to base due to low fuel or are assigned an interception task by ground control.
  --   
  --   * As the CAP flights wander around within the zone waiting to be tasked these zones need to be large enough that the aircraft are not constantly turning 
  --   but do not have to be big and numerous enough to completely cover a border.
  --   
  --   * CAP zones can be of any type, and are derived from the @{Zone#ZONE_BASE} class. Zones can be @{Zone#ZONE}, @{Zone#ZONE_POLYGON}, @{Zone#ZONE_UNIT}, @{Zone#GROUP}, etc.
  --   This allows to setup static, moveable or complex zones wherein aircraft will perform the CAP.
  --   
  --   * Typically 20000-50000 metres radius is used and they are spaced so that aircraft in the zone waiting for tasks don’t have to far to travel to protect their coalitions important targets. 
  --   These targets are chosen as part of the mission design and might be an important airfield or town etc. 
  --   Zone size is also determined somewhat by territory size, plane types (eg WW2 aircraft might mean smaller zones or more zones because they are slower and take longer to intercept enemy aircraft)
  --   
  --   * In a cold war it is important to make sure a CAP zone doesn’t intrude into enemy territory as otherwise CAP flights will likely cross borders 
  --   and spark a full scale conflict which will escalate rapidly.
  --   
  --   * CAP flights must travel to a CAP zone before they are “on station” and ready for tasking. 
  --   Therefore if their airfield is in their CAP zone they are on station immediately. 
  --   You might not do this though if having the airfield in the CAP zone allows it to be attacked easily so might position the CAP zone closer 
  --   to the border and accept the period of time a CAP flight will be unavailable for tasking while they travel to their zone.
  --   
  --   * Typically if a CAP flight is tasked and therefore leaves their zone empty while they go off and intercept their target another CAP flight will spawn to take their place.
  --   
  -- CAP zones need to be setup per squadron. The method @{#AI_A2A_DISPATCHER.SetSquadronCap() defines a CAP zone for a squadron.
  -- Setting-up a CAP zone also requires specific parameters, like the minimum and maximum altitude, minimum speed and maximum speed and the altitude type that define how the
  -- squadron will perform the CAP while partrolling. Different terrain types requires different types of CAP. 
  --  
  -- ## How many aircraft will CAP or GCI and how will they be grouped?
  -- 
  -- Choices are 1, 2, 3 or 4 when CAP flights spawn. Use the method @{#AI_A2A_DISPATCHER.SetSquadronGrouping}() to set the amount of CAP flights that will take-off when spawned.
  -- In the case of GCI, the @{#AI_A2A_DISPATCHER.SetSquadronGrouping}() method has additional behaviour. When there aren't enough CAP flights airborne, a GCI will be initiated for the remaining
  -- targets to be engaged. Depending on the grouping parameter, the spawned flights for GCI are grouped into this setting.   
  -- For example with a group setting of 2, if 3 targets are detected and cannot be engaged by CAP or any airborne flight, 
  -- a GCI needs to be started, the GCI flights will be grouped as follows: Group 1 of 2 flights and Group 2 of one flight!
  -- 
  -- The **grouping value is set for a Squadron**, and can be **dynamically adjusted** during mission execution, so to adjust the defense flights grouping when the tactical situation changes.
  -- 
  -- ## How to balance or setup effective air defenses in case of GCI?
  -- 
  -- Overhead The %-tage of Units that dispatching command will allocate to intercept in surplus of detected amount of units.
  -- The default overhead is 1, so equal balance. The @{#AI_A2A_DISPATCHER.SetOverhead}() method can be used to tweak the defense strength,
  -- taking into account the plane types of the squadron. For example, a MIG-31 with full long-distance A2A missiles payload, may still be less effective than a F-15C with short missiles...
  -- 
  -- So in this case, one may want to use the @{#AI_A2A_DISPATCHER.SetOverhead}() method to allocate more defending planes as the amount of detected attacking planes.
  -- The overhead must be given as a decimal value with 1 as the neutral value, which means that overhead values: 
  -- 
  --   * Higher than 1, will increase the defense unit amounts.
  --   * Lower than 1, will decrease the defense unit amounts.
  -- 
  -- The amount of defending units is calculated by multiplying the amount of detected attacking planes as part of the detected group 
  -- multiplied by the Overhead and rounded up to the smallest integer. 
  -- 
  -- The **overhead value is set for a Squadron**, and can be **dynamically adjusted** during mission execution, so to adjust the defense overhead when the tactical situation changes.
  -- 
  -- ## Number of spawned and active GCI interceptor flights for each coalition?
  -- 
  -- Essentially this controls how many flights of GCI aircraft can be active at any time.
  -- Note allowing large numbers of active GCI flights can adversely impact mission performance on low or medium specification hosts/servers.
  -- 
  -- # Country, type, load out, skill and skins for CAP and GCI aircraft?
  -- 
  --   * Note these can be from any countries within the coalition but must be an aircraft with one of the main tasks being “CAP”.
  --   * Obviously skins which are selected must be available to all players that join the mission otherwise they will see a default skin.
  --   * Load outs should be appropriate to a CAP mission eg perhaps drop tanks for CAP flights and extra missiles for GCI flights. 
  --   * These decisions will eventually lead to template aircraft units being placed as late activation units that the script will use as templates for spawning CAP and GCI flights. Up to 4 different aircraft configurations can be chosen for each coalition. The spawned aircraft will inherit the characteristics of the template aircraft.
  --   * The selected aircraft type must be able to perform the CAP tasking for the chosen country. 
  -- 
  -- 
  -- @field #AI_A2A_DISPATCHER
  AI_A2A_DISPATCHER = {
    ClassName = "AI_A2A_DISPATCHER",
    Mission = nil,
    Detection = nil,
    Tasks = {},
    SweepZones = {},
  }
  
  
  --- AI_A2A_DISPATCHER constructor.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string The Squadron Name. This name is used to control the squadron settings in the A2A dispatcher, and also in communication to human players.
  -- @param Core.Set#SET_GROUP DetectionSetGroup The @{Set} of group objects that will setup the Early Warning Radar network.
  -- @param #number GroupingRadius The radius in meters wherein detected planes are being grouped as one target area. 
  -- For airplanes, 6000 (6km) is recommended, and is also the default value of this parameter.
  -- @return #AI_A2A_DISPATCHER self
  -- @usage
  --   
  --   -- Set a new AI A2A Dispatcher object, based on an EWR network with a 6 km grouping radius.
  --   
  -- 
  function AI_A2A_DISPATCHER:New( DetectionSetGroup, GroupingRadius )

    local Detection = DETECTION_AREAS:New( DetectionSetGroup, GroupingRadius )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( nil, Detection ) ) -- #AI_A2A_DISPATCHER
    
    self.Detection = Detection -- Functional.Detection#DETECTION_AREAS
    
    -- This table models the DefenderSquadron templates.
    self.DefenderSquadrons = {} -- The Defender Squadrons.
    self.DefenderSpawns = {}
    self.DefenderTasks = {} -- The Defenders Tasks.
    
    -- TODO: Check detection through radar.
    self.Detection:FilterCategories( Unit.Category.AIRPLANE, Unit.Category.HELICOPTER )
    --self.Detection:InitDetectRadar( true )
    self.Detection:SetDetectionInterval( 30 )
    
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
    
    self:AddTransition( "*", "INTERCEPT", "*" )

    --- INTERCEPT Handler OnBefore for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] OnBeforeINTERCEPT
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- INTERCEPT Handler OnAfter for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] OnAfterINTERCEPT
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- INTERCEPT Trigger for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] INTERCEPT
    -- @param #AI_A2A_DISPATCHER self
    
    --- INTERCEPT Asynchronous Trigger for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] __INTERCEPT
    -- @param #AI_A2A_DISPATCHER self
    -- @param #number Delay
    
    self:AddTransition( "*", "ENGAGE", "*" )
        
    --- ENGAGE Handler OnBefore for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] OnBeforeENGAGE
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- ENGAGE Handler OnAfter for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] OnAfterENGAGE
    -- @param #AI_A2A_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- ENGAGE Trigger for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] ENGAGE
    -- @param #AI_A2A_DISPATCHER self
    
    --- ENGAGE Asynchronous Trigger for AI_A2A_DISPATCHER
    -- @function [parent=#AI_A2A_DISPATCHER] __ENGAGE
    -- @param #AI_A2A_DISPATCHER self
    -- @param #number Delay
    
    
    -- Subscribe to the CRASH event so that when planes are shot
    -- by a Unit from the dispatcher, they will be removed from the detection...
    -- This will avoid the detection to still "know" the shot unit until the next detection.
    -- Otherwise, a new intercept or engage may happen for an already shot plane!
    
    self:HandleEvent( EVENTS.Crash, self.OnEventCrashOrDead )
    self:HandleEvent( EVENTS.Dead, self.OnEventCrashOrDead )
    
    self:__Start( 5 )
    
    return self
  end

  --- @param #AI_A2A_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_A2A_DISPATCHER:OnEventCrashOrDead( EventData )
    self.Detection:ForgetDetectedUnit( EventData.IniUnitName )  
  end

  --- Define the radius to engage any target by airborne friendlies, which are executing cap or returning from an intercept mission.
  -- So, if there is a target area detected and reported, 
  -- then any friendlies that are airborne near this target area, 
  -- will be commanded to (re-)engage that target when available (if no other tasks were commanded).
  -- For example, if 100000 is given as a value, then any friendly that is airborne within 100km from the detected target, 
  -- will be considered to receive the command to engage that target area.
  -- You need to evaluate the value of this parameter carefully.
  -- If too small, more intercept missions may be triggered upon detected target areas.
  -- If too large, any airborne cap may not be able to reach the detected target area in time, because it is too far.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #number FriendliesRadius The radius to report friendlies near the target.
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  -- 
  --   -- Set 100km as the radius to engage any target by airborne friendlies.
  --   Dispatcher:InitDetectionFriendiesRadius( 100000 )
  --   
  function AI_A2A_DISPATCHER:InitEngageRadius( FriendliesRadius )

    self.Detection:SetFriendliesRange( FriendliesRadius )
  
    return self
  end
  
  --- Define a border area to simulate a **cold war** scenario.
  -- A **cold war** is one where CAP aircraft patrol their territory but will not attack enemy aircraft or launch GCI aircraft unless enemy aircraft enter their territory. In other words the EWR may detect an enemy aircraft but will only send aircraft to attack it if it crosses the border.
  -- A **hot war** is one where CAP aircraft will intercept any detected enemy aircraft and GCI aircraft will launch against detected enemy aircraft without regard for territory. In other words if the ground radar can detect the enemy aircraft then it will send CAP and GCI aircraft to attack it.
  -- If it’s a cold war then the **borders of red and blue territory** need to be defined using a @{zone} object derived from @{Zone#ZONE_BASE}. This method needs to be used for this.
  -- If a hot war is chosen then **no borders** actually need to be defined using the helicopter units other than it makes it easier sometimes for the mission maker to envisage where the red and blue territories roughly are. In a hot war the borders are effectively defined by the ground based radar coverage of a coalition. Set the noborders parameter to 1
  -- @param #AI_A2A_DISPATCHER self
  -- @param Core.Zone#ZONE_BASE BorderZone An object derived from ZONE_BASE, that defines a zone between
  -- @return #AI_A2A_DISPATCHER
  -- @usage
  -- 
  --   -- Set a polygon zone as the border for the A2A dispatcher.
  --   local BorderZone = ZONE_POLYGON( "CCCP Border", GROUP:FindByName( "CCCP Border" ) ) -- The GROUP object is a late activate helicopter unit.
  --   Dispatcher:InitBorderZone( BorderZone )
  --   
  function AI_A2A_DISPATCHER:InitBorderZone( BorderZone )

    self.Detection:SetAcceptZones( BorderZone )

    return self
  end

  --- Calculates which AI friendlies are nearby the area
  -- @param #AI_A2A_DISPATCHER self
  -- @param DetectedItem
  -- @return #number, Core.CommandCenter#REPORT
  function AI_A2A_DISPATCHER:GetAIFriendliesNearBy( DetectedItem )
  
    local FriendliesNearBy = self.Detection:GetFriendliesNearBy( DetectedItem )
    
    return FriendliesNearBy
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:GetDefenderTasks()
    return self.DefenderTasks or {}
  end
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:GetDefenderTask( AIGroup )
    return self.DefenderTasks[AIGroup]
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:GetDefenderTaskFsm( AIGroup )
    return self:GetDefenderTask( AIGroup ).Fsm
  end
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:GetDefenderTaskTarget( AIGroup )
    return self:GetDefenderTask( AIGroup ).Target
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:ClearDefenderTask( AIGroup )
    if AIGroup:IsAlive() and self.DefenderTasks[AIGroup] then
      local Target = self.DefenderTasks[AIGroup].Target
      local Message = "Clearing (" .. self.DefenderTasks[AIGroup].Type .. ") " 
      Message = Message .. AIGroup:GetName() 
      if Target then
        Message = Message .. ( Target and ( " from " .. Target.Index .. " [" .. Target.Set:Count() .. "]" ) ) or ""
      end
      self:F( { Target = Message } )
    end
    self.DefenderTasks[AIGroup] = nil
    return self
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:ClearDefenderTaskTarget( AIGroup )
    
    local DefenderTask = self:GetDefenderTask( AIGroup )
    
    if AIGroup:IsAlive() and DefenderTask then
      local Target = DefenderTask.Target
      local Message = "Clearing (" .. DefenderTask.Type .. ") " 
      Message = Message .. AIGroup:GetName() 
      if Target then
        Message = Message .. ( Target and ( " from " .. Target.Index .. " [" .. Target.Set:Count() .. "]" ) ) or ""
      end
      self:F( { Target = Message } )
    end
    if AIGroup and DefenderTask and DefenderTask.Target then
      DefenderTask.Target = nil
    end
    if AIGroup and DefenderTask then
      if DefenderTask.Fsm:Is( "Fuel" ) 
      or DefenderTask.Fsm:Is( "LostControl") 
      or DefenderTask.Fsm:Is( "Damaged" ) then
        self:ClearDefenderTask( AIGroup )
      end
    end
    return self
  end

  
  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:SetDefenderTask( AIGroup, Type, Fsm, Target )
    self.DefenderTasks[AIGroup] = self.DefenderTasks[AIGroup] or {}
    self.DefenderTasks[AIGroup].Type = Type
    self.DefenderTasks[AIGroup].Fsm = Fsm

    if Target then
      self:SetDefenderTaskTarget( AIGroup, Target )
    end
    return self
  end
  
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param Wrapper.Group#GROUP AIGroup
  function AI_A2A_DISPATCHER:SetDefenderTaskTarget( AIGroup, Target )
    
    local Message = "(" .. self.DefenderTasks[AIGroup].Type .. ") " 
    Message = Message .. AIGroup:GetName() 
    Message = Message .. ( Target and ( " target " .. Target.Index .. " [" .. Target.Set:Count() .. "]" ) ) or ""
    self:F( { Target = Message } )
    if Target then
      AIGroup:MessageToAll( Message, 1200 )
      self.DefenderTasks[AIGroup].Target = Target
    end
    return self
  end


  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @return #AI_A2A_DISPATCHER
  function AI_A2A_DISPATCHER:SetSquadron( SquadronName, AirbaseName, SpawnTemplates, Resources )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 

    local DefenderSquadron = self.DefenderSquadrons[SquadronName]
    
    self:E( { AirbaseName = AirbaseName } )
    DefenderSquadron.Airbase = AIRBASE:FindByName( AirbaseName )
    self:E( { Airbase = DefenderSquadron.Airbase } )
    self:E( { AirbaseObject = DefenderSquadron.Airbase:GetDCSObject() } )
    
    DefenderSquadron.Spawn = {}
    if type( SpawnTemplates ) == "string" then
      local SpawnTemplate = SpawnTemplates
      self.DefenderSpawns[SpawnTemplate] = self.DefenderSpawns[SpawnTemplate] or SPAWN:New( SpawnTemplate )
      DefenderSquadron.Spawn[1] = self.DefenderSpawns[SpawnTemplate]
    else
      for TemplateID, SpawnTemplate in pairs( SpawnTemplates ) do
        self.DefenderSpawns[SpawnTemplate] = self.DefenderSpawns[SpawnTemplate] or SPAWN:New( SpawnTemplate )
        DefenderSquadron.Spawn[#DefenderSquadron.Spawn+1] = self.DefenderSpawns[SpawnTemplate]
      end
    end
    DefenderSquadron.Resources = Resources
    
    self:SetSquadronOverhead( SquadronName, 1 )

    return self
  end
  
  --- Get an item from the Squadron table.
  -- @param #AI_A2A_DISPATCHER self
  -- @return #table
  function AI_A2A_DISPATCHER:GetSquadron( SquadronName )
    local DefenderSquadron = self.DefenderSquadrons[SquadronName]
    
    if not DefenderSquadron then
      error( "Unknown Squadron:" .. SquadronName )
    end
    
    return DefenderSquadron
  end

  
  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Zone} object derived from @{Zone#ZONE_BASE} that defines the zone wherein the CAP will be executed.
  -- @param #number FloorAltitude The minimum altitude at which the cap can be executed.
  -- @param #number CeilingAltitude the maximum altitude at which the cap can be executed.
  -- @param #number MinSpeed The minimum speed at which the cap can be executed.
  -- @param #number MaxSpeed The maximum speed at which the cap can be executed.
  -- @param #number AltType The altitude type, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_A2A_DISPATCHER
  function AI_A2A_DISPATCHER:SetSquadronCap( SquadronName, Zone, FloorAltitude, CeilingAltitude, MinSpeed, MaxSpeed, AltType )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}
    
    local DefenderSquadron = self:GetSquadron( SquadronName )

    local Cap = self.DefenderSquadrons[SquadronName].Cap
    Cap.Name = SquadronName
    Cap.Zone = Zone
    Cap.FloorAltitude = FloorAltitude
    Cap.CeilingAltitude = CeilingAltitude
    Cap.MinSpeed = MinSpeed
    Cap.MaxSpeed = MaxSpeed
    Cap.AltType = AltType

    self:SetSquadronCapInterval( SquadronName, 2, 180, 600, 1 )
    
    return self
  end
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #AI_A2A_DISPATCHER
  function AI_A2A_DISPATCHER:SetSquadronCapInterval( SquadronName, CapLimit, LowInterval, HighInterval, Probability )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}

    local DefenderSquadron = self:GetSquadron( SquadronName )

    local Cap = self.DefenderSquadrons[SquadronName].Cap
    if Cap then
      Cap.LowInterval = LowInterval
      Cap.HighInterval = HighInterval
      Cap.Probability = Probability
      Cap.CapLimit = CapLimit
      Cap.Scheduler = Cap.Scheduler or SCHEDULER:New( self ) 
      local Scheduler = Cap.Scheduler -- Core.Scheduler#SCHEDULER
      local Variance = ( HighInterval - LowInterval ) / 2
      local Median = LowInterval + Variance
      local Randomization = Variance / Median
      Scheduler:Schedule(self, self.SchedulerCAP, { SquadronName }, Median, Median, Randomization )
    else
      error( "This squadron does not exist:" .. SquadronName )
    end

  end
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #AI_A2A_DISPATCHER
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

  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  function AI_A2A_DISPATCHER:CanCAP( SquadronName )
    self:F({SquadronName = SquadronName})
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}

    local DefenderSquadron = self:GetSquadron( SquadronName )

    local Cap = DefenderSquadron.Cap
    if Cap then
      local CapCount = self:CountCapAirborne( SquadronName )
      if CapCount < Cap.CapLimit then
        local Probability = math.random()
        if Probability <= Cap.Probability then
          return true
        end
      end
      return false
    else
      error( "This squadron does not exist:" .. SquadronName )
    end
  end
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number MinSpeed The minimum speed at which the gci can be executed.
  -- @param #number MaxSpeed The maximum speed at which the gci can be executed.
  -- @return #AI_A2A_DISPATCHER
  function AI_A2A_DISPATCHER:SetSquadronGci( SquadronName, MinSpeed, MaxSpeed )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Intercept = self.DefenderSquadrons[SquadronName].Intercept or {}
    
    local Intercept = self.DefenderSquadrons[SquadronName].Intercept
    Intercept.Name = SquadronName
    Intercept.MinSpeed = MinSpeed
    Intercept.MaxSpeed = MaxSpeed
  end
  
  --- Defines the amount of extra planes that will take-off as part of the defense system.
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Overhead The %-tage of Units that dispatching command will allocate to intercept in surplus of detected amount of units.
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
  --   local Dispatcher = AI_A2A_DISPATCHER:New( ... )
  --   
  --   -- An overhead of 1,5 with 1 planes detected, will allocate 2 planes ( 1 * 1,5 ) = 1,5 => rounded up gives 2.
  --   -- An overhead of 1,5 with 2 planes detected, will allocate 3 planes ( 2 * 1,5 ) = 3 =>  rounded up gives 3.
  --   -- An overhead of 1,5 with 3 planes detected, will allocate 5 planes ( 3 * 1,5 ) = 4,5 => rounded up gives 5 planes.
  --   -- An overhead of 1,5 with 4 planes detected, will allocate 6 planes ( 4 * 1,5 ) = 6  => rounded up gives 6 planes.
  --   
  --   Dispatcher:SetSquadronOverhead( 1,5 )
  -- 
  -- 
  -- @return #AI_A2A_DISPATCHER
  function AI_A2A_DISPATCHER:SetSquadronOverhead( SquadronName, Overhead )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Overhead = Overhead
    
    return self
  end

  --- 
  -- @param #AI_A2A_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Grouping The level of grouping that will be applied of the CAP or GCI defenders. 
  -- @usage:
  -- 
  --   local Dispatcher = AI_A2A_DISPATCHER:New( ... )
  --   Dispatcher:SetSquadronGrouping( 2 )
  -- 
  -- 
  -- @return #AI_A2A_DISPATCHER
  function AI_A2A_DISPATCHER:SetSquadronGrouping( SquadronName, Grouping )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Grouping = Grouping
    
    return self
  end

  
  --- Creates an SWEEP task when there are targets for it.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
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

  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:CountCapAirborne( SquadronName )

    local CapCount = 0
    
    local DefenderSquadron = self.DefenderSquadrons[SquadronName]
    if DefenderSquadron then
      for AIGroup, DefenderTask in pairs( self:GetDefenderTasks() ) do
        if DefenderTask.Type == "CAP" then
          if AIGroup:IsAlive() then
            CapCount = CapCount + 1
          end
        end
      end
    end

    return CapCount
  end
  
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:CountDefendersEngaged( Target )

    -- First, count the active AIGroups Units, targetting the DetectedSet
    local AIUnitCount = 0
    
    local DefenderTasks = self:GetDefenderTasks()
    for AIGroup, DefenderTask in pairs( DefenderTasks ) do
      local AIGroup = AIGroup -- Wrapper.Group#GROUP
      local DefenderTask = self:GetDefenderTaskTarget( AIGroup )
      if DefenderTask and DefenderTask.Index == Target.Index then
        AIUnitCount = AIUnitCount + AIGroup:GetSize()
      end
    end

    return AIUnitCount
  end
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:CountDefendersToBeEngaged( DetectedItem, DefenderCount )
  
    local Friendlies = nil

    local DetectedSet = DetectedItem.Set
    local DetectedCount = DetectedSet:Count()

    local AIFriendlies = self:GetAIFriendliesNearBy( DetectedItem )
    
    for FriendlyDistance, AIFriendly in UTILS.spairs( AIFriendlies or {} ) do
      -- We only allow to ENGAGE targets as long as the Units on both sides are balanced.
      if DetectedCount > DefenderCount then 
        local Friendly = AIFriendly:GetGroup() -- Wrapper.Group#GROUP
        if Friendly and Friendly:IsAlive() then
          -- Ok, so we have a friendly near the potential target.
          -- Now we need to check if the AIGroup has a Task.
          self:F( { FriendlyName = Friendly:GetName() } )
          self:F( { FriendlyDistance = FriendlyDistance } )
          local DefenderTask = self:GetDefenderTask( Friendly )
          if DefenderTask then
            -- The Task should be CAP or INTERCEPT
            if DefenderTask.Type == "CAP" or DefenderTask.Type == "INTERCEPT" then
              -- If there is no target, then add the AIGroup to the ResultAIGroups for Engagement to the TargetSet
              if DefenderTask.Target == nil then
                Friendlies = Friendlies or {}
                Friendlies[Friendly] = Friendly
                DefenderCount = DefenderCount + Friendly:GetSize()
                self:F( { Friendly = Friendly:GetName() } )
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
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:onafterCAP( From, Event, To, SquadronName )
  
    self:F({SquadronName = SquadronName})
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}
    
    local DefenderSquadron = self:GetSquadron( SquadronName )
    local Cap = DefenderSquadron.Cap
    
    if Cap then
    
      if self:CanCAP( SquadronName ) then
        local Spawn = DefenderSquadron.Spawn[ math.random( 1, #DefenderSquadron.Spawn ) ]
        Spawn:InitGrouping( DefenderSquadron.Grouping )
        local AIGroup = Spawn:SpawnAtAirbase( DefenderSquadron.Airbase )
        self:F( { AIGroup = AIGroup:GetName() } )
  
        if AIGroup then
  
          local Fsm = AI_A2A_CAP:New( AIGroup, Cap.Zone, Cap.FloorAltitude, Cap.CeilingAltitude, Cap.MinSpeed, Cap.MaxSpeed, Cap.AltType )
          Fsm:SetDispatcher( self )
          Fsm:SetHomeAirbase( DefenderSquadron.Airbase )
          Fsm:Start()
          Fsm:__Patrol( 1 )
  
          self:SetDefenderTask( AIGroup, "CAP", Fsm )
        end
      end
    else
      error( "This squadron does not exist:" .. SquadronName )
    end
    
  end


  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:onafterENGAGE( From, Event, To, Target, AIGroups )
  
    if AIGroups then

      for AIGroupID, AIGroup in pairs( AIGroups ) do

        local Fsm = self:GetDefenderTaskFsm( AIGroup )
        Fsm:__Engage( 1, Target.Set ) -- Engage on the TargetSetUnit
        
        self:SetDefenderTaskTarget( AIGroup, Target )

        function Fsm:onafterRTB( AIGroup, From, Event, To )
          self:F({"CAP RTB"})
          self:GetParent(self).onafterRTB( self, AIGroup, From, Event, To )
          local Dispatcher = self:GetDispatcher() -- #AI_A2A_DISPATCHER
          local AIGroup = self:GetControllable()
          Dispatcher:ClearDefenderTaskTarget( AIGroup )
        end
      end
    end
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:onafterINTERCEPT( From, Event, To, Target, DefendersMissing, AIGroups )

    local ClosestDistance = 0
    local ClosestDefenderSquadronName = nil
    
    local AttackerCount = Target.Set:Count()
    local DefendersCount = 0

    for AIGroupID, AIGroup in pairs( AIGroups or {} ) do

      local Fsm = self:GetDefenderTaskFsm( AIGroup )
      Fsm:__Engage( 1, Target.Set ) -- Engage on the TargetSetUnit
      
      self:SetDefenderTaskTarget( AIGroup, Target )

      DefendersCount = DefendersCount + AIGroup:GetSize()
    end

    DefendersCount = DefendersMissing
    while( DefendersCount > 0 ) do
    
      for SquadronName, DefenderSquadron in pairs( self.DefenderSquadrons or {} ) do
        for InterceptID, Intercept in pairs( DefenderSquadron.Intercept or {} ) do
    
          local SpawnCoord = DefenderSquadron.Airbase:GetCoordinate() -- Core.Point#COORDINATE
          local TargetCoord = Target.Set:GetFirst():GetCoordinate()
          local Distance = SpawnCoord:Get2DDistance( TargetCoord )
    
          if ClosestDistance == 0 or Distance < ClosestDistance then
            ClosestDistance = Distance
            ClosestDefenderSquadronName = SquadronName
          end
        end
      end
      
      if ClosestDefenderSquadronName then
      
        local DefenderSquadron = self:GetSquadron( ClosestDefenderSquadronName )
        local DefenderOverhead = DefenderSquadron.Overhead
        local DefenderGrouping = DefenderSquadron.Grouping
        local DefendersNeeded = math.ceil( DefendersCount * DefenderOverhead )
        local Intercept = self.DefenderSquadrons[ClosestDefenderSquadronName].Intercept
      
        local Spawn = DefenderSquadron.Spawn[ math.random( 1, #DefenderSquadron.Spawn ) ]
        if DefenderGrouping then
          Spawn:InitGrouping( ( DefenderGrouping < DefendersNeeded ) and DefenderGrouping or DefendersNeeded )
        else
          Spawn:InitGrouping()
        end
        local AIGroup = Spawn:SpawnAtAirbase( DefenderSquadron.Airbase )
        self:F( { AIGroup = AIGroup:GetName() } )
  
        if AIGroup then

          DefendersCount = DefendersCount - AIGroup:GetSize()
          
          local Fsm = AI_A2A_INTERCEPT:New( AIGroup, Intercept.MinSpeed, Intercept.MaxSpeed )
          Fsm:SetDispatcher( self )
          Fsm:SetHomeAirbase( DefenderSquadron.Airbase )
          Fsm:Start()
          Fsm:__Engage( 1, Target.Set ) -- Engage on the TargetSetUnit

  
          self:SetDefenderTask( AIGroup, "INTERCEPT", Fsm, Target )
          
          
          function Fsm:onafterRTB( AIGroup, From, Event, To )
            self:F({"INTERCEPT RTB"})
            self:GetParent(self).onafterRTB( self, AIGroup, From, Event, To )
            
            local Dispatcher = self:GetDispatcher() -- #AI_A2A_DISPATCHER
            local AIGroup = self:GetControllable()
            Dispatcher:ClearDefenderTaskTarget( AIGroup )
          end
          
        end
      end
    end
  end



  --- Creates an ENGAGE task when there are human friendlies airborne near the targets.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function AI_A2A_DISPATCHER:EvaluateENGAGE( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    -- First, count the active AIGroups Units, targetting the DetectedSet
    local DefenderCount = self:CountDefendersEngaged( DetectedItem )
    local DefenderGroups = self:CountDefendersToBeEngaged( DetectedItem, DefenderCount )
    
    -- Only allow ENGAGE when:
    -- 1. There are friendly units near the detected attackers.
    -- 2. There is sufficient fuel
    -- 3. There is sufficient ammo
    -- 4. The plane is not damaged
    if DefenderGroups and DetectedItem.IsDetected == true then
      
      return DefenderGroups
    end
    
    return nil, nil
  end
  
  --- Creates an INTERCEPT task when there are targets for it.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function AI_A2A_DISPATCHER:EvaluateINTERCEPT( Target )
    self:F( { Target.ItemID } )
  
    local AttackerSet = Target.Set
    local AttackerCount = AttackerSet:Count()

    -- First, count the active AIGroups Units, targetting the DetectedSet
    local DefenderCount = self:CountDefendersEngaged( Target )
    local DefendersMissing = AttackerCount - DefenderCount

    local Friendlies = self:CountDefendersToBeEngaged( Target, DefenderCount )

    if Target.IsDetected == true then
      
      return DefendersMissing, Friendlies
    end
    
    return nil, nil
  end


  --- Assigns A2A AI Tasks in relation to the detected items.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Detection#DETECTION_BASE} derived object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function AI_A2A_DISPATCHER:ProcessDetected( Detection )
  
    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}
    
    local TaskReport = REPORT:New()

          
    for AIGroup, DefenderTask in pairs( self:GetDefenderTasks() ) do
      local AIGroup = AIGroup -- Wrapper.Group#GROUP
      if not AIGroup:IsAlive() then
        self:ClearDefenderTask( AIGroup )
      else
        if DefenderTask.Target then
          if DefenderTask.Target.Set then
            if DefenderTask.Target.Set:Count() == 0 then
              self:ClearDefenderTaskTarget( AIGroup )
            end
          end
        end
      end
    end

    -- Now that all obsolete tasks are removed, loop through the detected targets.
    for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
    
      local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
      local DetectedCount = DetectedSet:Count()
      local DetectedZone = DetectedItem.Zone

      self:F( { "Target ID", DetectedItem.ItemID } )
      DetectedSet:Flush()

      local DetectedID = DetectedItem.ID
      local DetectionIndex = DetectedItem.Index
      local DetectedItemChanged = DetectedItem.Changed
      
      do 
        local Friendlies = self:EvaluateENGAGE( DetectedItem ) -- Returns a SetUnit if there are targets to be INTERCEPTed...
        if Friendlies then
          self:F( { AIGroups = Friendlies } )
          self:ENGAGE( DetectedItem, Friendlies )
        end
      end

      do
        local DefendersMissing, Friendlies = self:EvaluateINTERCEPT( DetectedItem )
        if DefendersMissing then
          self:F( { DefendersMissing = DefendersMissing } )
          self:INTERCEPT( DetectedItem, DefendersMissing, Friendlies )
        end
      end
    end
    
    -- Show tactical situation
    for Defender, DefenderTask in pairs( self:GetDefenderTasks() ) do
      local Defender = Defender -- Wrapper.Group#GROUP
       local Message = string.format( "%s, %s", Defender:GetName(), DefenderTask.Type )
       if DefenderTask.Target then
        Message = Message .. " => " .. DefenderTask.Target.Index .. " : " .. DefenderTask.Target.Set:GetObjectNames()
       end
       self:F( { Tactical = Message } )
    end
    
    
    
    return true
  end

end

do

  --- Calculates which HUMAN friendlies are nearby the area
  -- @param #AI_A2A_DISPATCHER self
  -- @param DetectedItem
  -- @return #number, Core.CommandCenter#REPORT
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
        --self:E( { PlayerName = PlayerName, PlayerUnit = PlayerUnit } )
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

    --self:E( { PlayersCount = PlayersCount } )
    
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

  --- Calculates which friendlies are nearby the area
  -- @param #AI_A2A_DISPATCHER self
  -- @param DetectedItem
  -- @return #number, Core.CommandCenter#REPORT
  function AI_A2A_DISPATCHER:GetFriendliesNearBy( Target )
  
    local DetectedSet = Target.Set
    local FriendlyUnitsNearBy = self.Detection:GetFriendliesNearBy( Target )
    
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
          FriendlyTypes[FriendlyType] = FriendlyTypes[FriendlyType] and ( FriendlyTypes[FriendlyType] + 1 ) or 1
          if DetectedTreatLevel < FriendlyUnitThreatLevel + 2 then
          end
        end
      end
      
    end

    --self:E( { FriendliesCount = FriendliesCount } )
    
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

  ---
  -- @param AI_A2A_DISPATCHER
  -- @param #string SquadronName The squadron name.
  function AI_A2A_DISPATCHER:SchedulerCAP( SquadronName )
    self:CAP( SquadronName )
  end
  


end