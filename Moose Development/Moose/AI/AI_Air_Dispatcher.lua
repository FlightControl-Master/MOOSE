--- **AI** - Intermediary class that realized the common methods for the A2G and A2A dispatchers.
-- 
-- ===
-- 
-- Features:
-- 
--    * Common methods for A2G and A2A dispatchers.
-- 
-- ===
-- 
-- ### Author: **FlightControl** rework of GCICAP + introduction of new concepts (squadrons).
-- 
-- @module AI.AI_Air_Dispatcher
-- @image AI_Air_To_Ground_Dispatching.JPG



do -- AI_AIR_DISPATCHER

  --- AI_AIR_DISPATCHER class.
  -- @type AI_AIR_DISPATCHER
  -- @extends Tasking.DetectionManager#DETECTION_MANAGER

  --- Intermediary class that realized the common methods for the A2G and A2A dispatchers.
  -- 
  -- ===
  -- 
  -- @field #AI_AIR_DISPATCHER
  AI_AIR_DISPATCHER = {
    ClassName = "AI_AIR_DISPATCHER",
    Detection = nil,
  }

  --- Definition of a Squadron.
  -- @type AI_AIR_DISPATCHER.Squadron
  -- @field #string Name The Squadron name.
  -- @field Wrapper.Airbase#AIRBASE Airbase The home airbase.
  -- @field #string AirbaseName The name of the home airbase.
  -- @field Core.Spawn#SPAWN Spawn The spawning object.
  -- @field #number ResourceCount The number of resources available.
  -- @field #list<#string> TemplatePrefixes The list of template prefixes.
  -- @field #boolean Captured true if the squadron is captured. 
  -- @field #number Overhead The overhead for the squadron. 


  --- List of defense coordinates.
  -- @type AI_AIR_DISPATCHER.DefenseCoordinates
  -- @map <#string,Core.Point#COORDINATE> A list of all defense coordinates mapped per defense coordinate name.

  --- Enumerator for spawns at airbases
  -- @type AI_AIR_DISPATCHER.Takeoff
  -- @extends Wrapper.Group#GROUP.Takeoff
  
  --- @field #AI_AIR_DISPATCHER.Takeoff Takeoff
  AI_AIR_DISPATCHER.Takeoff = GROUP.Takeoff
  
  --- Defnes Landing location.
  -- @field Landing
  AI_AIR_DISPATCHER.Landing = {
    NearAirbase = 1,
    AtRunway = 2,
    AtEngineShutdown = 3,
  }
  
  --- A defense queue item description
  -- @type AI_AIR_DISPATCHER.DefenseQueueItem
  -- @field Squadron
  -- @field #AI_AIR_DISPATCHER.Squadron DefenderSquadron The squadron in the queue.
  -- @field DefendersNeeded
  -- @field Defense
  -- @field DefenseTaskType
  -- @field Functional.Detection#DETECTION_BASE AttackerDetection
  -- @field DefenderGrouping
  -- @field #string SquadronName The name of the squadron.
  
  --- Queue of planned defenses to be launched.
  -- This queue exists because defenses must be launched on FARPS, or in the air, or on an airbase, or on carriers.
  -- And some of these platforms have very limited amount of "launching" platforms.
  -- Therefore, this queue concept is introduced that queues each defender request.
  -- Depending on the location of the launching site, the queued defenders will be launched at varying time intervals.
  -- This guarantees that launched defenders are also directly existing ...
  -- @type AI_AIR_DISPATCHER.DefenseQueue
  -- @list<#AI_AIR_DISPATCHER.DefenseQueueItem> DefenseQueueItem A list of all defenses being queued ...
  
  --- @field #AI_AIR_DISPATCHER.DefenseQueue DefenseQueue
  AI_AIR_DISPATCHER.DefenseQueue = {}
  
  
  
  
  --- AI_AIR_DISPATCHER constructor.
  -- @param #AI_AIR_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The DETECTION object that will detects targets using the the Early Warning Radar network.
  -- @return #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:New( Detection )

    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( nil, Detection ) ) -- #AI_AIR_DISPATCHER
    
    self.Detection = Detection -- Functional.Detection#DETECTION_AREAS
    
    -- This table models the DefenderSquadron templates.
    self.DefenderSquadrons = {} -- The Defender Squadrons.
    self.DefenderSpawns = {}
    self.DefenderTasks = {} -- The Defenders Tasks.
    self.DefenderDefault = {} -- The Defender Default Settings over all Squadrons.
    
    self:SetDefenseRadius()
    self:SetIntercept( 300 )  -- A default intercept delay time of 300 seconds.
    
    self:SetDefaultTakeoff( AI_AIR_DISPATCHER.Takeoff.Air )
    self:SetDefaultTakeoffInAirAltitude( 500 ) -- Default takeoff is 500 meters above the ground.
    self:SetDefaultLanding( AI_AIR_DISPATCHER.Landing.NearAirbase )
    self:SetDefaultEngageRadius( 150000 )

    self:SetDefaultOverhead( 1 )
    self:SetDefaultGrouping( 1 )

    self:SetDefaultFuelThreshold( 0.15, 0 ) -- 15% of fuel remaining in the tank will trigger the airplane to return to base or refuel.
    self:SetDefaultDamageThreshold( 0.4 ) -- When 40% of damage, go RTB.
    self:SetDefaultPatrolTimeInterval( 180, 600 ) -- Between 180 and 600 seconds.
    self:SetDefaultPatrolLimit( 1 ) -- Maximum one Patrol per squadron.
    
    
    self:AddTransition( "Started", "Assign", "Started" )
    
    --- OnAfter Transition Handler for Event Assign.
    -- @function [parent=#AI_AIR_DISPATCHER] OnAfterAssign
    -- @param #AI_AIR_DISPATCHER self
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @param Tasking.Task_A2G#AI_A2G Task
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param #string PlayerName
    
    self:AddTransition( "*", "Patrol", "*" )

    --- Patrol Handler OnBefore for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] OnBeforePatrol
    -- @param #AI_AIR_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Patrol Handler OnAfter for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] OnAfterPatrol
    -- @param #AI_AIR_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Patrol Trigger for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] Patrol
    -- @param #AI_AIR_DISPATCHER self
    
    --- Patrol Asynchronous Trigger for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] __Patrol
    -- @param #AI_AIR_DISPATCHER self
    -- @param #number Delay
    
    self:AddTransition( "*", "Defend", "*" )

    --- Defend Handler OnBefore for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] OnBeforeDefend
    -- @param #AI_AIR_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Defend Handler OnAfter for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] OnAfterDefend
    -- @param #AI_AIR_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Defend Trigger for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] Defend
    -- @param #AI_AIR_DISPATCHER self
    
    --- Defend Asynchronous Trigger for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] __Defend
    -- @param #AI_AIR_DISPATCHER self
    -- @param #number Delay
    
    self:AddTransition( "*", "Engage", "*" )
        
    --- Engage Handler OnBefore for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] OnBeforeEngage
    -- @param #AI_AIR_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- Engage Handler OnAfter for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] OnAfterEngage
    -- @param #AI_AIR_DISPATCHER self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- Engage Trigger for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] Engage
    -- @param #AI_AIR_DISPATCHER self
    
    --- Engage Asynchronous Trigger for AI_AIR_DISPATCHER
    -- @function [parent=#AI_AIR_DISPATCHER] __Engage
    -- @param #AI_AIR_DISPATCHER self
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
    
    self.TakeoffScheduleID = self:ScheduleRepeat( 10, 10, 0, nil, self.ResourceTakeoff, self )
    
    self:__Start( 5 )
    
    return self
  end


  --- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:onafterStart( From, Event, To )

    self:GetParent( self ).onafterStart( self, From, Event, To )

    -- Spawn the resources.
    for SquadronName, DefenderSquadron in pairs( self.DefenderSquadrons ) do
      DefenderSquadron.Resource = {}
      for Resource = 1, DefenderSquadron.ResourceCount or 0 do
        self:ResourcePark( DefenderSquadron )
      end
    end
  end
  

  --- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:ResourcePark( DefenderSquadron )
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


  --- @param #AI_AIR_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_AIR_DISPATCHER:OnEventBaseCaptured( EventData )

    local AirbaseName = EventData.PlaceName -- The name of the airbase that was captured.
    
    self:I( "Captured " .. AirbaseName )
    
    -- Now search for all squadrons located at the airbase, and sanatize them.
    for SquadronName, Squadron in pairs( self.DefenderSquadrons ) do
      if Squadron.AirbaseName == AirbaseName then
        Squadron.ResourceCount = -999 -- The base has been captured, and the resources are eliminated. No more spawning.
        Squadron.Captured = true
        self:I( "Squadron " .. SquadronName .. " captured." )
      end
    end
  end

  --- @param #AI_AIR_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_AIR_DISPATCHER:OnEventCrashOrDead( EventData )
    self.Detection:ForgetDetectedUnit( EventData.IniUnitName ) 
  end

  --- @param #AI_AIR_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_AIR_DISPATCHER:OnEventLand( EventData )
    self:F( "Landed" )
    local DefenderUnit = EventData.IniUnit
    local Defender = EventData.IniGroup
    local Squadron = self:GetSquadronFromDefender( Defender )
    if Squadron then
      self:F( { SquadronName = Squadron.Name } )
      local LandingMethod = self:GetSquadronLanding( Squadron.Name )
      
      if LandingMethod == AI_AIR_DISPATCHER.Landing.AtRunway then
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
  
  --- @param #AI_AIR_DISPATCHER self
  -- @param Core.Event#EVENTDATA EventData
  function AI_AIR_DISPATCHER:OnEventEngineShutdown( EventData )
    local DefenderUnit = EventData.IniUnit
    local Defender = EventData.IniGroup
    local Squadron = self:GetSquadronFromDefender( Defender )
    if Squadron then
      self:F( { SquadronName = Squadron.Name } )
      local LandingMethod = self:GetSquadronLanding( Squadron.Name )
      if LandingMethod == AI_AIR_DISPATCHER.Landing.AtEngineShutdown and
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

  
  --- Define the defense radius to check if a target can be engaged by a squadron group.
  -- When targets are detected that are still really far off, you don't want the dispatcher to launch defenders, as they might need to travel too far.
  -- You want it to wait until a certain defend radius is reached, which is calculated as:
  --   1. the **distance of the closest airbase to target**, being smaller than the **Defend Radius**.
  --   2. the **distance to any defense reference point**.
  -- 
  -- The **default** defense radius is defined as **400000** or **40km**. Override the default defense radius when the era of the warfare is early, or, 
  -- when you don't want to let the AI_AIR_DISPATCHER react immediately when a certain border or area is not being crossed.
  -- 
  -- Use the method @{#AI_AIR_DISPATCHER.SetDefendRadius}() to set a specific defend radius for all squadrons,
  -- **the Defense Radius is defined for ALL squadrons which are operational.**
  -- 
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number DefenseRadius (Optional, Default = 200000) The defense radius to engage detected targets from the nearest capable and available squadron airbase.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection ) 
  --   
  --   -- Set 100km as the radius to defend from detected targets from the nearest airbase.
  --   A2GDispatcher:SetDefendRadius( 100000 )
  --   
  --   -- Set 200km as the radius to defend.
  --   A2GDispatcher:SetDefendRadius() -- 200000 is the default value.
  --   
  function AI_AIR_DISPATCHER:SetDefenseRadius( DefenseRadius )

    self.DefenseRadius = DefenseRadius or 100000
    
    self.Detection:SetAcceptRange( self.DefenseRadius ) 
  
    return self
  end
  

  
  
  --- Define a border area to simulate a **cold war** scenario.
  -- A **cold war** is one where Patrol aircraft patrol their territory but will not attack enemy aircraft or launch GCI aircraft unless enemy aircraft enter their territory. In other words the EWR may detect an enemy aircraft but will only send aircraft to attack it if it crosses the border.
  -- A **hot war** is one where Patrol aircraft will intercept any detected enemy aircraft and GCI aircraft will launch against detected enemy aircraft without regard for territory. In other words if the ground radar can detect the enemy aircraft then it will send Patrol and GCI aircraft to attack it.
  -- If it's a cold war then the **borders of red and blue territory** need to be defined using a @{zone} object derived from @{Core.Zone#ZONE_BASE}. This method needs to be used for this.
  -- If a hot war is chosen then **no borders** actually need to be defined using the helicopter units other than it makes it easier sometimes for the mission maker to envisage where the red and blue territories roughly are. In a hot war the borders are effectively defined by the ground based radar coverage of a coalition. Set the noborders parameter to 1
  -- @param #AI_AIR_DISPATCHER self
  -- @param Core.Zone#ZONE_BASE BorderZone An object derived from ZONE_BASE, or a list of objects derived from ZONE_BASE.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
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
  --   
  function AI_AIR_DISPATCHER:SetBorderZone( BorderZone )

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
  -- @param #AI_AIR_DISPATCHER self
  -- @param #boolean TacticalDisplay Provide a value of **true** to display every 30 seconds a tactical overview.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the Tactical Display for debug mode.
  --   A2GDispatcher:SetTacticalDisplay( true )
  --   
  function AI_AIR_DISPATCHER:SetTacticalDisplay( TacticalDisplay )
    
    self.TacticalDisplay = TacticalDisplay
    
    return self
  end  


  --- Set the default damage treshold when defenders will RTB.
  -- The default damage treshold is by default set to 40%, which means that when the airplane is 40% damaged, it will go RTB.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number DamageThreshold A decimal number between 0 and 1, that expresses the %-tage of the damage treshold before going RTB.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default damage treshold.
  --   A2GDispatcher:SetDefaultDamageThreshold( 0.90 ) -- Go RTB when the airplane 90% damaged.
  --   
  function AI_AIR_DISPATCHER:SetDefaultDamageThreshold( DamageThreshold )
    
    self.DefenderDefault.DamageThreshold = DamageThreshold
    
    return self
  end  


  --- Set the default Patrol time interval for squadrons, which will be used to determine a random Patrol timing.
  -- The default Patrol time interval is between 180 and 600 seconds.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number PatrolMinSeconds The minimum amount of seconds for the random time interval.
  -- @param #number PatrolMaxSeconds The maximum amount of seconds for the random time interval.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default Patrol time interval.
  --   A2GDispatcher:SetDefaultPatrolTimeInterval( 300, 1200 ) -- Between 300 and 1200 seconds.
  --   
  function AI_AIR_DISPATCHER:SetDefaultPatrolTimeInterval( PatrolMinSeconds, PatrolMaxSeconds )
    
    self.DefenderDefault.PatrolMinSeconds = PatrolMinSeconds
    self.DefenderDefault.PatrolMaxSeconds = PatrolMaxSeconds
    
    return self
  end


  --- Set the default Patrol limit for squadrons, which will be used to determine how many Patrol can be airborne at the same time for the squadron.
  -- The default Patrol limit is 1 Patrol, which means one Patrol group being spawned.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number PatrolLimit The maximum amount of Patrol that can be airborne at the same time for the squadron.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default Patrol limit.
  --   A2GDispatcher:SetDefaultPatrolLimit( 2 ) -- Maximum 2 Patrol per squadron.
  --   
  function AI_AIR_DISPATCHER:SetDefaultPatrolLimit( PatrolLimit )
    
    self.DefenderDefault.PatrolLimit = PatrolLimit
    
    return self
  end  


  --- Set the default engage limit for squadrons, which will be used to determine how many air units will engage at the same time with the enemy.
  -- The default eatrol limit is 1, which means one patrol group maximum per squadron.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number EngageLimit The maximum engages that can be done at the same time per squadron.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default Patrol limit.
  --   A2GDispatcher:SetDefaultEngageLimit( 2 ) -- Maximum 2 engagements with the enemy per squadron.
  --   
  function AI_AIR_DISPATCHER:SetDefaultEngageLimit( EngageLimit )
    
    self.DefenderDefault.EngageLimit = EngageLimit
    
    return self
  end  



  function AI_AIR_DISPATCHER:SetIntercept( InterceptDelay )
    
    self.DefenderDefault.InterceptDelay = InterceptDelay
    
    local Detection = self.Detection -- Functional.Detection#DETECTION_AREAS
    Detection:SetIntercept( true, InterceptDelay )
    
    return self
  end  


  --- Calculates which defender friendlies are nearby the area, to help protect the area.
  -- @param #AI_AIR_DISPATCHER self
  -- @param DetectedItem
  -- @return #table A list of the defender friendlies nearby, sorted by distance.
  function AI_AIR_DISPATCHER:GetDefenderFriendliesNearBy( DetectedItem )
  
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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:GetDefenderTasks()
    return self.DefenderTasks or {}
  end
  
  ---
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:GetDefenderTask( Defender )
    return self.DefenderTasks[Defender]
  end

  ---
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:GetDefenderTaskFsm( Defender )
    return self:GetDefenderTask( Defender ).Fsm
  end
  
  ---
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:GetDefenderTaskTarget( Defender )
    return self:GetDefenderTask( Defender ).Target
  end
  
  ---
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:GetDefenderTaskSquadronName( Defender )
    return self:GetDefenderTask( Defender ).SquadronName
  end

  ---
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:ClearDefenderTask( Defender )
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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:ClearDefenderTaskTarget( Defender )
    
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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:SetDefenderTask( SquadronName, Defender, Type, Fsm, Target, Size )
  
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
  -- @param #AI_AIR_DISPATCHER self
  -- @param Wrapper.Group#GROUP AIGroup
  function AI_AIR_DISPATCHER:SetDefenderTaskTarget( Defender, AttackerDetection )
    
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
  -- @param #AI_AIR_DISPATCHER self
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
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
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
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetSquadron( SquadronName, AirbaseName, TemplatePrefixes, ResourceCount )
  
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
  -- @param #AI_AIR_DISPATCHER self
  -- @return #table
  function AI_AIR_DISPATCHER:GetSquadron( SquadronName )

    local DefenderSquadron = self.DefenderSquadrons[SquadronName]
    
    if not DefenderSquadron then
      error( "Unknown Squadron:" .. SquadronName )
    end
    
    return DefenderSquadron
  end

  
  --- Set the Squadron visible before startup of the dispatcher.
  -- All planes will be spawned as uncontrolled on the parking spot.
  -- They will lock the parking spot.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Set the Squadron visible before startup of dispatcher.
  --        A2GDispatcher:SetSquadronVisible( "Mineralnye" )
  --        
  -- TODO: disabling because of bug in queueing.       
--  function AI_AIR_DISPATCHER:SetSquadronVisible( SquadronName )
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
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #bool true if visible.
  -- @usage
  -- 
  --        -- Set the Squadron visible before startup of dispatcher.
  --        local IsVisible = A2GDispatcher:IsSquadronVisible( "Mineralnye" )
  --        
  function AI_AIR_DISPATCHER:IsSquadronVisible( SquadronName )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    
    local DefenderSquadron = self:GetSquadron( SquadronName )

    if DefenderSquadron then
      return DefenderSquadron.Uncontrolled == true
    end
    
    return nil
    
  end

  --- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number TakeoffInterval  Only Takeoff new units each specified interval in seconds in 10 seconds steps.
  -- @usage
  -- 
  --        -- Set the Squadron Takeoff interval every 60 seconds for squadron "SQ50", which is good for a FARP cold start.
  --        A2GDispatcher:SetSquadronTakeoffInterval( "SQ50", 60 )
  --        
  function AI_AIR_DISPATCHER:SetSquadronTakeoffInterval( SquadronName, TakeoffInterval )

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
  --   - @{#AI_AIR_DISPATCHER:SetSquadronSeadPatrolInterval} for SEAD tasks.
  --   - @{#AI_AIR_DISPATCHER:SetSquadronSeadPatrolInterval} for CAS tasks.
  --   - @{#AI_AIR_DISPATCHER:SetSquadronSeadPatrolInterval} for BAI tasks.
  --   
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number PatrolLimit (optional) The maximum amount of Patrol groups to be spawned. Note that a Patrol is a group, so can consist out of 1 to 4 airplanes. The default is 1 Patrol group.
  -- @param #number LowInterval (optional) The minimum time boundary in seconds when a new Patrol will be spawned. The default is 180 seconds.
  -- @param #number HighInterval (optional) The maximum time boundary in seconds when a new Patrol will be spawned. The default is 600 seconds.
  -- @param #number Probability Is not in use, you can skip this parameter.
  -- @param #string DefenseTaskType Should contain "SEAD", "CAS" or "BAI".
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronSeadPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        A2GDispatcher:SetSquadronPatrolInterval( "Mineralnye", 2, 30, 60, 1, "SEAD" )
  -- 
  function AI_AIR_DISPATCHER:SetSquadronPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability, DefenseTaskType )
  
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
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number PatrolLimit (optional) The maximum amount of Patrol groups to be spawned. Note that a Patrol is a group, so can consist out of 1 to 4 airplanes. The default is 1 Patrol group.
  -- @param #number LowInterval (optional) The minimum time boundary in seconds when a new Patrol will be spawned. The default is 180 seconds.
  -- @param #number HighInterval (optional) The maximum time boundary in seconds when a new Patrol will be spawned. The default is 600 seconds.
  -- @param #number Probability Is not in use, you can skip this parameter.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronSeadPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        A2GDispatcher:SetSquadronSeadPatrolInterval( "Mineralnye", 2, 30, 60, 1 )
  -- 
  function AI_AIR_DISPATCHER:SetSquadronSeadPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability )

    self:SetSquadronPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability, "SEAD" )  

  end
  
  
  --- Set the squadron Patrol parameters for CAS tasks.  
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number PatrolLimit (optional) The maximum amount of Patrol groups to be spawned. Note that a Patrol is a group, so can consist out of 1 to 4 airplanes. The default is 1 Patrol group.
  -- @param #number LowInterval (optional) The minimum time boundary in seconds when a new Patrol will be spawned. The default is 180 seconds.
  -- @param #number HighInterval (optional) The maximum time boundary in seconds when a new Patrol will be spawned. The default is 600 seconds.
  -- @param #number Probability Is not in use, you can skip this parameter.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronCasPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        A2GDispatcher:SetSquadronCasPatrolInterval( "Mineralnye", 2, 30, 60, 1 )
  -- 
  function AI_AIR_DISPATCHER:SetSquadronCasPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability )

    self:SetSquadronPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability, "CAS" )  

  end
  
  
  --- Set the squadron Patrol parameters for BAI tasks.  
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number PatrolLimit (optional) The maximum amount of Patrol groups to be spawned. Note that a Patrol is a group, so can consist out of 1 to 4 airplanes. The default is 1 Patrol group.
  -- @param #number LowInterval (optional) The minimum time boundary in seconds when a new Patrol will be spawned. The default is 180 seconds.
  -- @param #number HighInterval (optional) The maximum time boundary in seconds when a new Patrol will be spawned. The default is 600 seconds.
  -- @param #number Probability Is not in use, you can skip this parameter.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronBaiPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        A2GDispatcher:SetSquadronBaiPatrolInterval( "Mineralnye", 2, 30, 60, 1 )
  -- 
  function AI_AIR_DISPATCHER:SetSquadronBaiPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability )

    self:SetSquadronPatrolInterval( SquadronName, PatrolLimit, LowInterval, HighInterval, Probability, "BAI" )  

  end
  
  
  ---
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:GetPatrolDelay( SquadronName )
  
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
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #table DefenderSquadron
  function AI_AIR_DISPATCHER:CanPatrol( SquadronName, DefenseTaskType )
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
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @return #table DefenderSquadron
  function AI_AIR_DISPATCHER:CanDefend( SquadronName, DefenseTaskType )
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
  --   - @{#AI_AIR_DISPATCHER:SetSquadronSeadEngageLimit} for SEAD tasks.
  --   - @{#AI_AIR_DISPATCHER:SetSquadronSeadEngageLimit} for CAS tasks.
  --   - @{#AI_AIR_DISPATCHER:SetSquadronSeadEngageLimit} for BAI tasks.
  --   
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageLimit The maximum amount of groups to engage with the enemy for this squadron.
  -- @param #string DefenseTaskType Should contain "SEAD", "CAS" or "BAI".
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronEngageLimit( "Mineralnye", 2, "SEAD" ) -- Engage maximum 2 groups with the enemy for SEAD defense.
  -- 
  function AI_AIR_DISPATCHER:SetSquadronEngageLimit( SquadronName, EngageLimit, DefenseTaskType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    local Defense = DefenderSquadron[DefenseTaskType]
    if Defense then
      Defense.EngageLimit = EngageLimit or 1
    else
      error( "This squadron does not exist:" .. SquadronName )
    end

  end



  
  ---
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the SEAD task can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the SEAD task can be executed.
  -- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
  -- @usage 
  -- 
  --        -- SEAD Squadron execution.
  --        A2GDispatcher:SetSquadronSead( "Mozdok", 900, 1200 )
  --        A2GDispatcher:SetSquadronSead( "Novo", 900, 2100 )
  --        A2GDispatcher:SetSquadronSead( "Maykop", 900, 1200 )
  -- 
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetSquadronSead( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.SEAD = DefenderSquadron.SEAD or {}
    
    local Sead = DefenderSquadron.SEAD
    Sead.Name = SquadronName
    Sead.EngageMinSpeed = EngageMinSpeed
    Sead.EngageMaxSpeed = EngageMaxSpeed
    Sead.EngageFloorAltitude = EngageFloorAltitude or 500
    Sead.EngageCeilingAltitude = EngageCeilingAltitude or 1000
    Sead.Defend = true
    
    self:F( { Sead = Sead } )
  end

  --- Set the squadron SEAD engage limit.  
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageLimit The maximum amount of groups to engage with the enemy for this squadron.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronSeadEngageLimit( "Mineralnye", 2 ) -- Engage maximum 2 groups with the enemy for SEAD defense.
  -- 
  function AI_AIR_DISPATCHER:SetSquadronSeadEngageLimit( SquadronName, EngageLimit )

    self:SetSquadronEngageLimit( SquadronName, EngageLimit, "SEAD" )  

  end


  

  --- Set a Sead patrol for a Squadron.
  -- The Sead patrol will start a patrol of the aircraft at a specified zone, and will engage when commanded.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the Patrol will be executed.
  -- @param #number FloorAltitude (optional, default = 1000m ) The minimum altitude at which the cap can be executed.
  -- @param #number CeilingAltitude (optional, default = 1500m ) The maximum altitude at which the cap can be executed.
  -- @param #number PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the cap can be executed.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the engage can be executed.
  -- @param #number AltType The altitude type, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Sead Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronSeadPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        
  function AI_AIR_DISPATCHER:SetSquadronSeadPatrol( SquadronName, Zone, FloorAltitude, CeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, AltType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.SEAD = DefenderSquadron.SEAD or {}
    
    local SeadPatrol = DefenderSquadron.SEAD
    SeadPatrol.Name = SquadronName
    SeadPatrol.Zone = Zone
    SeadPatrol.PatrolFloorAltitude = FloorAltitude
    SeadPatrol.PatrolCeilingAltitude = CeilingAltitude
    SeadPatrol.EngageFloorAltitude = FloorAltitude
    SeadPatrol.EngageCeilingAltitude = CeilingAltitude
    SeadPatrol.PatrolMinSpeed = PatrolMinSpeed
    SeadPatrol.PatrolMaxSpeed = PatrolMaxSpeed
    SeadPatrol.EngageMinSpeed = EngageMinSpeed
    SeadPatrol.EngageMaxSpeed = EngageMaxSpeed
    SeadPatrol.AltType = AltType
    SeadPatrol.Patrol = true

    self:SetSquadronPatrolInterval( SquadronName, self.DefenderDefault.PatrolLimit, self.DefenderDefault.PatrolMinSeconds, self.DefenderDefault.PatrolMaxSeconds, 1, "SEAD" )
    
    self:F( { Sead = SeadPatrol } )
  end
  

  ---
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the CAS task can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the CAS task can be executed.
  -- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
  -- @usage 
  -- 
  --        -- CAS Squadron execution.
  --        A2GDispatcher:SetSquadronCas( "Mozdok", 900, 1200 )
  --        A2GDispatcher:SetSquadronCas( "Novo", 900, 2100 )
  --        A2GDispatcher:SetSquadronCas( "Maykop", 900, 1200 )
  -- 
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetSquadronCas( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.CAS = DefenderSquadron.CAS or {}
    
    local Cas = DefenderSquadron.CAS
    Cas.Name = SquadronName
    Cas.EngageMinSpeed = EngageMinSpeed
    Cas.EngageMaxSpeed = EngageMaxSpeed
    Cas.EngageFloorAltitude = EngageFloorAltitude or 500
    Cas.EngageCeilingAltitude = EngageCeilingAltitude or 1000
    Cas.Defend = true
    
    self:F( { Cas = Cas } )
  end


  --- Set the squadron CAS engage limit.  
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageLimit The maximum amount of groups to engage with the enemy for this squadron.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronCasEngageLimit( "Mineralnye", 2 ) -- Engage maximum 2 groups with the enemy for CAS defense.
  -- 
  function AI_AIR_DISPATCHER:SetSquadronCasEngageLimit( SquadronName, EngageLimit )

    self:SetSquadronEngageLimit( SquadronName, EngageLimit, "CAS" )  

  end


  
  
  --- Set a Cas patrol for a Squadron.
  -- The Cas patrol will start a patrol of the aircraft at a specified zone, and will engage when commanded.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the Patrol will be executed.
  -- @param #number FloorAltitude (optional, default = 1000m ) The minimum altitude at which the cap can be executed.
  -- @param #number CeilingAltitude (optional, default = 1500m ) The maximum altitude at which the cap can be executed.
  -- @param #number PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the cap can be executed.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the engage can be executed.
  -- @param #number AltType The altitude type, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Cas Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronCasPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        
  function AI_AIR_DISPATCHER:SetSquadronCasPatrol( SquadronName, Zone, FloorAltitude, CeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, AltType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.CAS = DefenderSquadron.CAS or {}
    
    local CasPatrol = DefenderSquadron.CAS
    CasPatrol.Name = SquadronName
    CasPatrol.Zone = Zone
    CasPatrol.PatrolFloorAltitude = FloorAltitude
    CasPatrol.PatrolCeilingAltitude = CeilingAltitude
    CasPatrol.EngageFloorAltitude = FloorAltitude
    CasPatrol.EngageCeilingAltitude = CeilingAltitude
    CasPatrol.PatrolMinSpeed = PatrolMinSpeed
    CasPatrol.PatrolMaxSpeed = PatrolMaxSpeed
    CasPatrol.EngageMinSpeed = EngageMinSpeed
    CasPatrol.EngageMaxSpeed = EngageMaxSpeed
    CasPatrol.AltType = AltType
    CasPatrol.Patrol = true

    self:SetSquadronPatrolInterval( SquadronName, self.DefenderDefault.PatrolLimit, self.DefenderDefault.PatrolMinSeconds, self.DefenderDefault.PatrolMaxSeconds, 1, "CAS" )
    
    self:F( { Cas = CasPatrol } )
  end
  

  ---
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the BAI task can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the BAI task can be executed.
  -- @param DCS#Altitude EngageFloorAltitude (optional, default = 1000m ) The lowest altitude in meters where to execute the engagement.
  -- @param DCS#Altitude EngageCeilingAltitude (optional, default = 1500m ) The highest altitude in meters where to execute the engagement.
  -- @usage 
  -- 
  --        -- BAI Squadron execution.
  --        A2GDispatcher:SetSquadronBai( "Mozdok", 900, 1200 )
  --        A2GDispatcher:SetSquadronBai( "Novo", 900, 2100 )
  --        A2GDispatcher:SetSquadronBai( "Maykop", 900, 1200 )
  -- 
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetSquadronBai( SquadronName, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.BAI = DefenderSquadron.BAI or {}
    
    local Bai = DefenderSquadron.BAI
    Bai.Name = SquadronName
    Bai.EngageMinSpeed = EngageMinSpeed
    Bai.EngageMaxSpeed = EngageMaxSpeed
    Bai.EngageFloorAltitude = EngageFloorAltitude or 500
    Bai.EngageCeilingAltitude = EngageCeilingAltitude or 1000
    Bai.Defend = true
    
    self:F( { Bai = Bai } )
  end


  --- Set the squadron BAI engage limit.  
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param #number EngageLimit The maximum amount of groups to engage with the enemy for this squadron.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronBaiEngageLimit( "Mineralnye", 2 ) -- Engage maximum 2 groups with the enemy for BAI defense.
  -- 
  function AI_AIR_DISPATCHER:SetSquadronBaiEngageLimit( SquadronName, EngageLimit )

    self:SetSquadronEngageLimit( SquadronName, EngageLimit, "BAI" )  

  end
  
  
  --- Set a Bai patrol for a Squadron.
  -- The Bai patrol will start a patrol of the aircraft at a specified zone, and will engage when commanded.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  -- @param Core.Zone#ZONE_BASE Zone The @{Zone} object derived from @{Core.Zone#ZONE_BASE} that defines the zone wherein the Patrol will be executed.
  -- @param #number FloorAltitude (optional, default = 1000m ) The minimum altitude at which the cap can be executed.
  -- @param #number CeilingAltitude (optional, default = 1500m ) The maximum altitude at which the cap can be executed.
  -- @param #number PatrolMinSpeed (optional, default = 50% of max speed) The minimum speed at which the cap can be executed.
  -- @param #number PatrolMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the cap can be executed.
  -- @param #number EngageMinSpeed (optional, default = 50% of max speed) The minimum speed at which the engage can be executed.
  -- @param #number EngageMaxSpeed (optional, default = 75% of max speed) The maximum speed at which the engage can be executed.
  -- @param #number AltType The altitude type, which is a string "BARO" defining Barometric or "RADIO" defining radio controlled altitude.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --        -- Bai Patrol Squadron execution.
  --        PatrolZoneEast = ZONE_POLYGON:New( "Patrol Zone East", GROUP:FindByName( "Patrol Zone East" ) )
  --        A2GDispatcher:SetSquadronBaiPatrol( "Mineralnye", PatrolZoneEast, 4000, 10000, 500, 600, 800, 900 )
  --        
  function AI_AIR_DISPATCHER:SetSquadronBaiPatrol( SquadronName, Zone, FloorAltitude, CeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, EngageMinSpeed, EngageMaxSpeed, AltType )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )

    DefenderSquadron.BAI = DefenderSquadron.BAI or {}
    
    local BaiPatrol = DefenderSquadron.BAI
    BaiPatrol.Name = SquadronName
    BaiPatrol.Zone = Zone
    BaiPatrol.PatrolFloorAltitude = FloorAltitude
    BaiPatrol.PatrolCeilingAltitude = CeilingAltitude
    BaiPatrol.EngageFloorAltitude = FloorAltitude
    BaiPatrol.EngageCeilingAltitude = CeilingAltitude
    BaiPatrol.PatrolMinSpeed = PatrolMinSpeed
    BaiPatrol.PatrolMaxSpeed = PatrolMaxSpeed
    BaiPatrol.EngageMinSpeed = EngageMinSpeed
    BaiPatrol.EngageMaxSpeed = EngageMaxSpeed
    BaiPatrol.AltType = AltType
    BaiPatrol.Patrol = true

    self:SetSquadronPatrolInterval( SquadronName, self.DefenderDefault.PatrolLimit, self.DefenderDefault.PatrolMinSeconds, self.DefenderDefault.PatrolMaxSeconds, 1, "BAI" )
    
    self:F( { Bai = BaiPatrol } )
  end
  

  --- Defines the default amount of extra planes that will take-off as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number Overhead The %-tage of Units that dispatching command will allocate to intercept in surplus of detected amount of units.
  -- The default overhead is 1, so equal balance. The @{#AI_AIR_DISPATCHER.SetOverhead}() method can be used to tweak the defense strength,
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
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- An overhead of 1,5 with 1 planes detected, will allocate 2 planes ( 1 * 1,5 ) = 1,5 => rounded up gives 2.
  --   -- An overhead of 1,5 with 2 planes detected, will allocate 3 planes ( 2 * 1,5 ) = 3 =>  rounded up gives 3.
  --   -- An overhead of 1,5 with 3 planes detected, will allocate 5 planes ( 3 * 1,5 ) = 4,5 => rounded up gives 5 planes.
  --   -- An overhead of 1,5 with 4 planes detected, will allocate 6 planes ( 4 * 1,5 ) = 6  => rounded up gives 6 planes.
  --   
  --   A2GDispatcher:SetDefaultOverhead( 1.5 )
  -- 
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetDefaultOverhead( Overhead )

    self.DefenderDefault.Overhead = Overhead
    
    return self
  end


  --- Defines the amount of extra planes that will take-off as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Overhead The %-tage of Units that dispatching command will allocate to intercept in surplus of detected amount of units.
  -- The default overhead is 1, so equal balance. The @{#AI_AIR_DISPATCHER.SetOverhead}() method can be used to tweak the defense strength,
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
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- An overhead of 1,5 with 1 planes detected, will allocate 2 planes ( 1 * 1,5 ) = 1,5 => rounded up gives 2.
  --   -- An overhead of 1,5 with 2 planes detected, will allocate 3 planes ( 2 * 1,5 ) = 3 =>  rounded up gives 3.
  --   -- An overhead of 1,5 with 3 planes detected, will allocate 5 planes ( 3 * 1,5 ) = 4,5 => rounded up gives 5 planes.
  --   -- An overhead of 1,5 with 4 planes detected, will allocate 6 planes ( 4 * 1,5 ) = 6  => rounded up gives 6 planes.
  --   
  --   A2GDispatcher:SetSquadronOverhead( "SquadronName", 1.5 )
  -- 
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetSquadronOverhead( SquadronName, Overhead )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Overhead = Overhead
    
    return self
  end


  --- Gets the overhead of planes as part of the defense system, in comparison with the attackers.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #number The %-tage of Units that dispatching command will allocate to intercept in surplus of detected amount of units.
  -- The default overhead is 1, so equal balance. The @{#AI_AIR_DISPATCHER.SetOverhead}() method can be used to tweak the defense strength,
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
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- An overhead of 1,5 with 1 planes detected, will allocate 2 planes ( 1 * 1,5 ) = 1,5 => rounded up gives 2.
  --   -- An overhead of 1,5 with 2 planes detected, will allocate 3 planes ( 2 * 1,5 ) = 3 =>  rounded up gives 3.
  --   -- An overhead of 1,5 with 3 planes detected, will allocate 5 planes ( 3 * 1,5 ) = 4,5 => rounded up gives 5 planes.
  --   -- An overhead of 1,5 with 4 planes detected, will allocate 6 planes ( 4 * 1,5 ) = 6  => rounded up gives 6 planes.
  --   
  --   local SquadronOverhead = A2GDispatcher:GetSquadronOverhead( "SquadronName" )
  -- 
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:GetSquadronOverhead( SquadronName )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    return DefenderSquadron.Overhead or self.DefenderDefault.Overhead
  end


  --- Sets the default grouping of new airplanes spawned.
  -- Grouping will trigger how new airplanes will be grouped if more than one airplane is spawned for defense.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number Grouping The level of grouping that will be applied of the Patrol or GCI defenders. 
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Set a grouping by default per 2 airplanes.
  --   A2GDispatcher:SetDefaultGrouping( 2 )
  -- 
  -- 
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetDefaultGrouping( Grouping )
  
    self.DefenderDefault.Grouping = Grouping
    
    return self
  end


  --- Sets the grouping of new airplanes spawned.
  -- Grouping will trigger how new airplanes will be grouped if more than one airplane is spawned for defense.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Grouping The level of grouping that will be applied of the Patrol or GCI defenders. 
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Set a grouping per 2 airplanes.
  --   A2GDispatcher:SetSquadronGrouping( "SquadronName", 2 )
  -- 
  -- 
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetSquadronGrouping( SquadronName, Grouping )
  
    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Grouping = Grouping
    
    return self
  end


  --- Defines the default method at which new flights will spawn and take-off as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default take-off in the air.
  --   A2GDispatcher:SetDefaultTakeoff( AI_A2G_Dispatcher.Takeoff.Air )
  --   
  --   -- Let new flights by default take-off from the runway.
  --   A2GDispatcher:SetDefaultTakeoff( AI_A2G_Dispatcher.Takeoff.Runway )
  --   
  --   -- Let new flights by default take-off from the airbase hot.
  --   A2GDispatcher:SetDefaultTakeoff( AI_A2G_Dispatcher.Takeoff.Hot )
  -- 
  --   -- Let new flights by default take-off from the airbase cold.
  --   A2GDispatcher:SetDefaultTakeoff( AI_A2G_Dispatcher.Takeoff.Cold )
  -- 
  -- 
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetDefaultTakeoff( Takeoff )

    self.DefenderDefault.Takeoff = Takeoff
    
    return self
  end

  --- Defines the method at which new flights will spawn and take-off as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights take-off in the air.
  --   A2GDispatcher:SetSquadronTakeoff( "SquadronName", AI_A2G_Dispatcher.Takeoff.Air )
  --   
  --   -- Let new flights take-off from the runway.
  --   A2GDispatcher:SetSquadronTakeoff( "SquadronName", AI_A2G_Dispatcher.Takeoff.Runway )
  --   
  --   -- Let new flights take-off from the airbase hot.
  --   A2GDispatcher:SetSquadronTakeoff( "SquadronName", AI_A2G_Dispatcher.Takeoff.Hot )
  -- 
  --   -- Let new flights take-off from the airbase cold.
  --   A2GDispatcher:SetSquadronTakeoff( "SquadronName", AI_A2G_Dispatcher.Takeoff.Cold )
  -- 
  -- 
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetSquadronTakeoff( SquadronName, Takeoff )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Takeoff = Takeoff
    
    return self
  end
  

  --- Gets the default method at which new flights will spawn and take-off as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @return #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default take-off in the air.
  --   local TakeoffMethod = A2GDispatcher:GetDefaultTakeoff()
  --   if TakeOffMethod == , AI_A2G_Dispatcher.Takeoff.InAir then
  --     ...
  --   end
  --   
  function AI_AIR_DISPATCHER:GetDefaultTakeoff( )

    return self.DefenderDefault.Takeoff
  end
  
  --- Gets the method at which new flights will spawn and take-off as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #number Takeoff From the airbase hot, from the airbase cold, in the air, from the runway.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights take-off in the air.
  --   local TakeoffMethod = A2GDispatcher:GetSquadronTakeoff( "SquadronName" )
  --   if TakeOffMethod == , AI_A2G_Dispatcher.Takeoff.InAir then
  --     ...
  --   end
  --   
  function AI_AIR_DISPATCHER:GetSquadronTakeoff( SquadronName )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    return DefenderSquadron.Takeoff or self.DefenderDefault.Takeoff
  end
  

  --- Sets flights to default take-off in the air, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default take-off in the air.
  --   A2GDispatcher:SetDefaultTakeoffInAir()
  --   
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetDefaultTakeoffInAir()

    self:SetDefaultTakeoff( AI_AIR_DISPATCHER.Takeoff.Air )
    
    return self
  end

  
  --- Sets flights to take-off in the air, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number TakeoffAltitude (optional) The altitude in meters above the ground. If not given, the default takeoff altitude will be used.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights take-off in the air.
  --   A2GDispatcher:SetSquadronTakeoffInAir( "SquadronName" )
  --   
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetSquadronTakeoffInAir( SquadronName, TakeoffAltitude )

    self:SetSquadronTakeoff( SquadronName, AI_AIR_DISPATCHER.Takeoff.Air )
    
    if TakeoffAltitude then
      self:SetSquadronTakeoffInAirAltitude( SquadronName, TakeoffAltitude )
    end
    
    return self
  end


  --- Sets flights by default to take-off from the runway, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default take-off from the runway.
  --   A2GDispatcher:SetDefaultTakeoffFromRunway()
  --   
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetDefaultTakeoffFromRunway()

    self:SetDefaultTakeoff( AI_AIR_DISPATCHER.Takeoff.Runway )
    
    return self
  end

  
  --- Sets flights to take-off from the runway, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights take-off from the runway.
  --   A2GDispatcher:SetSquadronTakeoffFromRunway( "SquadronName" )
  --   
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetSquadronTakeoffFromRunway( SquadronName )

    self:SetSquadronTakeoff( SquadronName, AI_AIR_DISPATCHER.Takeoff.Runway )
    
    return self
  end
  

  --- Sets flights by default to take-off from the airbase at a hot location, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default take-off at a hot parking spot.
  --   A2GDispatcher:SetDefaultTakeoffFromParkingHot()
  --   
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetDefaultTakeoffFromParkingHot()

    self:SetDefaultTakeoff( AI_AIR_DISPATCHER.Takeoff.Hot )
    
    return self
  end

  --- Sets flights to take-off from the airbase at a hot location, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights take-off in the air.
  --   A2GDispatcher:SetSquadronTakeoffFromParkingHot( "SquadronName" )
  --   
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetSquadronTakeoffFromParkingHot( SquadronName )

    self:SetSquadronTakeoff( SquadronName, AI_AIR_DISPATCHER.Takeoff.Hot )
    
    return self
  end
  
  
  --- Sets flights to by default take-off from the airbase at a cold location, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights take-off from a cold parking spot.
  --   A2GDispatcher:SetDefaultTakeoffFromParkingCold()
  --   
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetDefaultTakeoffFromParkingCold()

    self:SetDefaultTakeoff( AI_AIR_DISPATCHER.Takeoff.Cold )
    
    return self
  end
  

  --- Sets flights to take-off from the airbase at a cold location, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights take-off from a cold parking spot.
  --   A2GDispatcher:SetSquadronTakeoffFromParkingCold( "SquadronName" )
  --   
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetSquadronTakeoffFromParkingCold( SquadronName )

    self:SetSquadronTakeoff( SquadronName, AI_AIR_DISPATCHER.Takeoff.Cold )
    
    return self
  end
  

  --- Defines the default altitude where airplanes will spawn in the air and take-off as part of the defense system, when the take-off in the air method has been selected.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number TakeoffAltitude The altitude in meters above the ground.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Set the default takeoff altitude when taking off in the air.
  --   A2GDispatcher:SetDefaultTakeoffInAirAltitude( 2000 )  -- This makes planes start at 2000 meters above the ground.
  -- 
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetDefaultTakeoffInAirAltitude( TakeoffAltitude )

    self.DefenderDefault.TakeoffAltitude = TakeoffAltitude
    
    return self
  end

  --- Defines the default altitude where airplanes will spawn in the air and take-off as part of the defense system, when the take-off in the air method has been selected.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number TakeoffAltitude The altitude in meters above the ground.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Set the default takeoff altitude when taking off in the air.
  --   A2GDispatcher:SetSquadronTakeoffInAirAltitude( "SquadronName", 2000 ) -- This makes planes start at 2000 meters above the ground.
  --   
  -- @return #AI_AIR_DISPATCHER
  -- 
  function AI_AIR_DISPATCHER:SetSquadronTakeoffInAirAltitude( SquadronName, TakeoffAltitude )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.TakeoffAltitude = TakeoffAltitude
    
    return self
  end
  

  --- Defines the default method at which flights will land and despawn as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
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
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetDefaultLanding( Landing )

    self.DefenderDefault.Landing = Landing
    
    return self
  end
  

  --- Defines the method at which flights will land and despawn as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
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
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetSquadronLanding( SquadronName, Landing )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.Landing = Landing
    
    return self
  end
  

  --- Gets the default method at which flights will land and despawn as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @return #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights by default despawn near the airbase when returning.
  --   local LandingMethod = A2GDispatcher:GetDefaultLanding( AI_A2G_Dispatcher.Landing.NearAirbase )
  --   if LandingMethod == AI_A2G_Dispatcher.Landing.NearAirbase then
  --    ...
  --   end
  -- 
  function AI_AIR_DISPATCHER:GetDefaultLanding()

    return self.DefenderDefault.Landing
  end
  

  --- Gets the method at which flights will land and despawn as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @return #number Landing The landing method which can be NearAirbase, AtRunway, AtEngineShutdown
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let new flights despawn near the airbase when returning.
  --   local LandingMethod = A2GDispatcher:GetSquadronLanding( "SquadronName", AI_A2G_Dispatcher.Landing.NearAirbase )
  --   if LandingMethod == AI_A2G_Dispatcher.Landing.NearAirbase then
  --    ...
  --   end
  -- 
  function AI_AIR_DISPATCHER:GetSquadronLanding( SquadronName )

    local DefenderSquadron = self:GetSquadron( SquadronName )
    return DefenderSquadron.Landing or self.DefenderDefault.Landing
  end
  

  --- Sets flights by default to land and despawn near the airbase in the air, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let flights by default to land near the airbase and despawn.
  --   A2GDispatcher:SetDefaultLandingNearAirbase()
  --   
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetDefaultLandingNearAirbase()

    self:SetDefaultLanding( AI_AIR_DISPATCHER.Landing.NearAirbase )
    
    return self
  end
  

  --- Sets flights to land and despawn near the airbase in the air, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let flights to land near the airbase and despawn.
  --   A2GDispatcher:SetSquadronLandingNearAirbase( "SquadronName" )
  --   
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetSquadronLandingNearAirbase( SquadronName )

    self:SetSquadronLanding( SquadronName, AI_AIR_DISPATCHER.Landing.NearAirbase )
    
    return self
  end
  

  --- Sets flights by default to land and despawn at the runway, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let flights by default land at the runway and despawn.
  --   A2GDispatcher:SetDefaultLandingAtRunway()
  --   
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetDefaultLandingAtRunway()

    self:SetDefaultLanding( AI_AIR_DISPATCHER.Landing.AtRunway )
    
    return self
  end
  

  --- Sets flights to land and despawn at the runway, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let flights land at the runway and despawn.
  --   A2GDispatcher:SetSquadronLandingAtRunway( "SquadronName" )
  --   
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetSquadronLandingAtRunway( SquadronName )

    self:SetSquadronLanding( SquadronName, AI_AIR_DISPATCHER.Landing.AtRunway )
    
    return self
  end
  

  --- Sets flights by default to land and despawn at engine shutdown, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let flights by default land and despawn at engine shutdown.
  --   A2GDispatcher:SetDefaultLandingAtEngineShutdown()
  --   
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetDefaultLandingAtEngineShutdown()

    self:SetDefaultLanding( AI_AIR_DISPATCHER.Landing.AtEngineShutdown )
    
    return self
  end
  

  --- Sets flights to land and despawn at engine shutdown, as part of the defense system.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @usage:
  -- 
  --   local A2GDispatcher = AI_AIR_DISPATCHER:New( ... )
  --   
  --   -- Let flights land and despawn at engine shutdown.
  --   A2GDispatcher:SetSquadronLandingAtEngineShutdown( "SquadronName" )
  --   
  -- @return #AI_AIR_DISPATCHER
  function AI_AIR_DISPATCHER:SetSquadronLandingAtEngineShutdown( SquadronName )

    self:SetSquadronLanding( SquadronName, AI_AIR_DISPATCHER.Landing.AtEngineShutdown )
    
    return self
  end
  
  --- Set the default fuel treshold when defenders will RTB or Refuel in the air.
  -- The fuel treshold is by default set to 15%, which means that an airplane will stay in the air until 15% of its fuel has been consumed.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #number FuelThreshold A decimal number between 0 and 1, that expresses the %-tage of the treshold of fuel remaining in the tank when the plane will go RTB or Refuel.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default fuel treshold.
  --   A2GDispatcher:SetDefaultFuelThreshold( 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --   
  function AI_AIR_DISPATCHER:SetDefaultFuelThreshold( FuelThreshold )
    
    self.DefenderDefault.FuelThreshold = FuelThreshold
    
    return self
  end  


  --- Set the fuel treshold for the squadron when defenders will RTB or Refuel in the air.
  -- The fuel treshold is by default set to 15%, which means that an airplane will stay in the air until 15% of its fuel has been consumed.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #number FuelThreshold A decimal number between 0 and 1, that expresses the %-tage of the treshold of fuel remaining in the tank when the plane will go RTB or Refuel.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default fuel treshold.
  --   A2GDispatcher:SetSquadronRefuelThreshold( "SquadronName", 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --   
  function AI_AIR_DISPATCHER:SetSquadronFuelThreshold( SquadronName, FuelThreshold )
    
    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.FuelThreshold = FuelThreshold
    
    return self
  end  

  --- Set the default tanker where defenders will Refuel in the air.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string TankerName A string defining the group name of the Tanker as defined within the Mission Editor.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the default fuel treshold.
  --   A2GDispatcher:SetDefaultFuelThreshold( 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --   
  --   -- Now Setup the default tanker.
  --   A2GDispatcher:SetDefaultTanker( "Tanker" ) -- The group name of the tanker is "Tanker" in the Mission Editor.
  function AI_AIR_DISPATCHER:SetDefaultTanker( TankerName )
    
    self.DefenderDefault.TankerName = TankerName
    
    return self
  end  


  --- Set the squadron tanker where defenders will Refuel in the air.
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The name of the squadron.
  -- @param #string TankerName A string defining the group name of the Tanker as defined within the Mission Editor.
  -- @return #AI_AIR_DISPATCHER
  -- @usage
  -- 
  --   -- Now Setup the A2G dispatcher, and initialize it using the Detection object.
  --   A2GDispatcher = AI_AIR_DISPATCHER:New( Detection )  
  --   
  --   -- Now Setup the squadron fuel treshold.
  --   A2GDispatcher:SetSquadronRefuelThreshold( "SquadronName", 0.30 ) -- Go RTB when only 30% of fuel remaining in the tank.
  --   
  --   -- Now Setup the squadron tanker.
  --   A2GDispatcher:SetSquadronTanker( "SquadronName", "Tanker" ) -- The group name of the tanker is "Tanker" in the Mission Editor.
  function AI_AIR_DISPATCHER:SetSquadronTanker( SquadronName, TankerName )
    
    local DefenderSquadron = self:GetSquadron( SquadronName )
    DefenderSquadron.TankerName = TankerName
    
    return self
  end  




  --- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:AddDefenderToSquadron( Squadron, Defender, Size )
    self.Defenders = self.Defenders or {}
    local DefenderName = Defender:GetName()
    self.Defenders[ DefenderName ] = Squadron
    if Squadron.ResourceCount then
      Squadron.ResourceCount = Squadron.ResourceCount - Size
    end
    self:F( { DefenderName = DefenderName, SquadronResourceCount = Squadron.ResourceCount } )
  end

  --- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:RemoveDefenderFromSquadron( Squadron, Defender )
    self.Defenders = self.Defenders or {}
    local DefenderName = Defender:GetName()
    if Squadron.ResourceCount then
      Squadron.ResourceCount = Squadron.ResourceCount + Defender:GetSize()
    end
    self.Defenders[ DefenderName ] = nil
    self:F( { DefenderName = DefenderName, SquadronResourceCount = Squadron.ResourceCount } )
  end
  
  function AI_AIR_DISPATCHER:GetSquadronFromDefender( Defender )
    self.Defenders = self.Defenders or {}
    local DefenderName = Defender:GetName()
    self:F( { DefenderName = DefenderName } )
    return self.Defenders[ DefenderName ] 
  end

  
  ---
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:CountPatrolAirborne( SquadronName, DefenseTaskType )

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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:CountDefendersEngaged( AttackerDetection, AttackerCount )

    -- First, count the active AIGroups Units, targetting the DetectedSet
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
      local QueueItem = QueueItem -- #AI_AIR_DISPATCHER.DefenseQueueItem
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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:CountDefenders( AttackerDetection, DefenderCount, DefenderTaskType )
  
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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:ResourceActivate( DefenderSquadron, DefendersNeeded )
  
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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:onafterPatrol( From, Event, To, SquadronName, DefenseTaskType )
  
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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:ResourceQueue( Patrol, DefenderSquadron, DefendersNeeded, Defense, DefenseTaskType, AttackerDetection, SquadronName )

  self:F( { DefenderSquadron, DefendersNeeded, Defense, DefenseTaskType, AttackerDetection, SquadronName } )

    local DefenseQueueItem = {} -- #AI_AIR_DISPATCHER.DefenderQueueItem


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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:ResourceTakeoff()

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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:ResourcePatrol( DefenderSquadron, DefendersNeeded, Patrol, DefenseTaskType, AttackerDetection, SquadronName )


    self:F({DefenderSquadron=DefenderSquadron})
    self:F({DefendersNeeded=DefendersNeeded})
    self:F({Patrol=Patrol})
    self:F({DefenseTaskType=DefenseTaskType})
    self:F({AttackerDetection=AttackerDetection})
    self:F({SquadronName=SquadronName})
    
    local DefenderGroup, DefenderGrouping = self:ResourceActivate( DefenderSquadron, DefendersNeeded )    

    if DefenderGroup then

      local AI_A2G_PATROL = { SEAD = AI_A2G_SEAD, BAI = AI_A2G_BAI, CAS = AI_A2G_CAS }
      
      local Fsm = AI_A2G_PATROL[DefenseTaskType]:New( DefenderGroup, Patrol.EngageMinSpeed, Patrol.EngageMaxSpeed, Patrol.EngageFloorAltitude, Patrol.EngageCeilingAltitude, Patrol.Zone, Patrol.PatrolFloorAltitude, Patrol.PatrolCeilingAltitude, Patrol.PatrolMinSpeed, Patrol.PatrolMaxSpeed, Patrol.AltType )
      Fsm:SetDispatcher( self )
      Fsm:SetHomeAirbase( DefenderSquadron.Airbase )
      Fsm:SetFuelThreshold( DefenderSquadron.FuelThreshold or self.DefenderDefault.FuelThreshold, 60 )
      Fsm:SetDamageThreshold( self.DefenderDefault.DamageThreshold )
      Fsm:SetDisengageRadius( self.DisengageRadius )
      Fsm:SetTanker( DefenderSquadron.TankerName or self.DefenderDefault.TankerName )
      Fsm:Start()

      self:SetDefenderTask( SquadronName, DefenderGroup, DefenseTaskType, Fsm, nil, DefenderGrouping )
      
      function Fsm:onafterTakeoff( Defender, From, Event, To )
        self:F({"Defender Birth", Defender:GetName()})
        --self:GetParent(self).onafterBirth( self, Defender, From, Event, To )
        
        local DefenderName = Defender:GetName()
        local Dispatcher = Fsm:GetDispatcher() -- #AI_AIR_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
        
        if Squadron then
          Dispatcher:MessageToPlayers( "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " airborne." )
          Fsm:Patrol() -- Engage on the TargetSetUnit
        end
      end

      function Fsm:onafterRTB( Defender, From, Event, To )
        self:F({"Defender RTB", Defender:GetName()})
        self:GetParent(self).onafterRTB( self, Defender, From, Event, To )
        
        local DefenderName = Defender:GetName()
        local Dispatcher = self:GetDispatcher() -- #AI_AIR_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
        Dispatcher:MessageToPlayers( "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " returning." )

        Dispatcher:ClearDefenderTaskTarget( Defender )
      end

      --- @param #AI_AIR_DISPATCHER self
      function Fsm:onafterLostControl( Defender, From, Event, To )
        self:F({"Defender LostControl", Defender:GetName()})
        self:GetParent(self).onafterHome( self, Defender, From, Event, To )
        
        local DefenderName = Defender:GetName()
        local Dispatcher = Fsm:GetDispatcher() -- #AI_AIR_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
        Dispatcher:MessageToPlayers( "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " lost control." )
        if Defender:IsAboveRunway() then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, Defender )
          Defender:Destroy()
        end
      end
      
      --- @param #AI_AIR_DISPATCHER self
      function Fsm:onafterHome( Defender, From, Event, To, Action )
        self:F({"Defender Home", Defender:GetName()})
        self:GetParent(self).onafterHome( self, Defender, From, Event, To )
        
        local DefenderName = Defender:GetName()
        local Dispatcher = self:GetDispatcher() -- #AI_AIR_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
        Dispatcher:MessageToPlayers( "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " landing." )

        if Action and Action == "Destroy" then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, Defender )
          Defender:Destroy()
        end

        if Dispatcher:GetSquadronLanding( Squadron.Name ) == AI_AIR_DISPATCHER.Landing.NearAirbase then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, Defender )
          Defender:Destroy()
          Dispatcher:ResourcePark( Squadron, Defender )
        end
      end
    end

  end
  
  
  ---
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:ResourceEngage( DefenderSquadron, DefendersNeeded, Defense, DefenseTaskType, AttackerDetection, SquadronName )
    
    self:F({DefenderSquadron=DefenderSquadron})
    self:F({DefendersNeeded=DefendersNeeded})
    self:F({Defense=Defense})
    self:F({DefenseTaskType=DefenseTaskType})
    self:F({AttackerDetection=AttackerDetection})
    self:F({SquadronName=SquadronName})
    
    local DefenderGroup, DefenderGrouping = self:ResourceActivate( DefenderSquadron, DefendersNeeded )    

    if DefenderGroup then

      local AI_A2G = { SEAD = AI_A2G_SEAD, BAI = AI_A2G_BAI, CAS = AI_A2G_CAS }

      local Fsm = AI_A2G[DefenseTaskType]:New( DefenderGroup, Defense.EngageMinSpeed, Defense.EngageMaxSpeed, Defense.EngageFloorAltitude, Defense.EngageCeilingAltitude ) -- AI.AI_A2G_ENGAGE
      Fsm:SetDispatcher( self )
      Fsm:SetHomeAirbase( DefenderSquadron.Airbase )
      Fsm:SetFuelThreshold( DefenderSquadron.FuelThreshold or self.DefenderDefault.FuelThreshold, 60 )
      Fsm:SetDamageThreshold( self.DefenderDefault.DamageThreshold )
      Fsm:SetDisengageRadius( self.DisengageRadius )
      Fsm:Start()

      self:SetDefenderTask( SquadronName, DefenderGroup, DefenseTaskType, Fsm, AttackerDetection, DefenderGrouping )
      
      function Fsm:onafterTakeoff( Defender, From, Event, To )
        self:F({"Defender Birth", Defender:GetName()})
        --self:GetParent(self).onafterBirth( self, Defender, From, Event, To )
        
        local DefenderName = Defender:GetName()
        local Dispatcher = Fsm:GetDispatcher() -- #AI_AIR_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
        local DefenderTarget = Dispatcher:GetDefenderTaskTarget( Defender )
        
        self:F( { DefenderTarget = DefenderTarget } )
        
        if DefenderTarget then
          Dispatcher:MessageToPlayers( "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " airborne." )
          Fsm:EngageRoute( DefenderTarget.Set ) -- Engage on the TargetSetUnit
        end
      end

      function Fsm:OnAfterEngageRoute( Defender, From, Event, To, AttackSetUnit )
        self:F({"Engage Route", Defender:GetName()})
        --self:GetParent(self).onafterBirth( self, Defender, From, Event, To )
        
        local DefenderName = Defender:GetName()
        local Dispatcher = Fsm:GetDispatcher() -- #AI_AIR_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
        local FirstUnit = AttackSetUnit:GetFirst()
        local Coordinate = FirstUnit:GetCoordinate() -- Core.Point#COORDINATE

        Dispatcher:MessageToPlayers( "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " on route, bearing " .. Coordinate:ToString( Defender ) )
      end

      function Fsm:OnAfterEngage( Defender, From, Event, To, AttackSetUnit )
        self:F({"Engage Route", Defender:GetName()})
        --self:GetParent(self).onafterBirth( self, Defender, From, Event, To )
        
        local DefenderName = Defender:GetName()
        local Dispatcher = Fsm:GetDispatcher() -- #AI_AIR_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
        local FirstUnit = AttackSetUnit:GetFirst()
        local Coordinate = FirstUnit:GetCoordinate()

        Dispatcher:MessageToPlayers( "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " engaging target, bearing " .. Coordinate:ToString( Defender ) )
      end

      function Fsm:onafterRTB( Defender, From, Event, To )
        self:F({"Defender RTB", Defender:GetName()})
        
        local DefenderName = Defender:GetName()
        local Dispatcher = self:GetDispatcher() -- #AI_AIR_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
        Dispatcher:MessageToPlayers( "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " RTB." )

        self:GetParent(self).onafterRTB( self, Defender, From, Event, To )

        Dispatcher:ClearDefenderTaskTarget( Defender )
      end

      --- @param #AI_AIR_DISPATCHER self
      function Fsm:onafterLostControl( Defender, From, Event, To )
        self:F({"Defender LostControl", Defender:GetName()})
        self:GetParent(self).onafterHome( self, Defender, From, Event, To )
        
        local DefenderName = Defender:GetName()
        local Dispatcher = Fsm:GetDispatcher() -- #AI_AIR_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
        Dispatcher:MessageToPlayers( "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " lost control." )

        if Defender:IsAboveRunway() then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, Defender )
          Defender:Destroy()
        end
      end
      
      --- @param #AI_AIR_DISPATCHER self
      function Fsm:onafterHome( Defender, From, Event, To, Action )
        self:F({"Defender Home", Defender:GetName()})
        self:GetParent(self).onafterHome( self, Defender, From, Event, To )
        
        local DefenderName = Defender:GetName()
        local Dispatcher = self:GetDispatcher() -- #AI_AIR_DISPATCHER
        local Squadron = Dispatcher:GetSquadronFromDefender( Defender )
        Dispatcher:MessageToPlayers( "Squadron " .. Squadron.Name .. ", " .. DefenderName .. " landing." )

        if Action and Action == "Destroy" then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, Defender )
          Defender:Destroy()
        end

        if Dispatcher:GetSquadronLanding( Squadron.Name ) == AI_AIR_DISPATCHER.Landing.NearAirbase then
          Dispatcher:RemoveDefenderFromSquadron( Squadron, Defender )
          Defender:Destroy()
          Dispatcher:ResourcePark( Squadron, Defender )
        end
      end
    end
  end

  ---
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:onafterEngage( From, Event, To, AttackerDetection, Defenders )
  
    if Defenders then

      for DefenderID, Defender in pairs( Defenders or {} ) do

        local Fsm = self:GetDefenderTaskFsm( Defender )
        Fsm:Engage( AttackerDetection.Set ) -- Engage on the TargetSetUnit
        
        self:SetDefenderTaskTarget( Defender, AttackerDetection )

      end
    end
  end

  ---
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:HasDefenseLine( DefenseCoordinate, DetectedItem )

    local AttackCoordinate = self.Detection:GetDetectedItemCoordinate( DetectedItem )
    local EvaluateDistance = AttackCoordinate:Get2DDistance( DefenseCoordinate )

    -- Now check if this coordinate is not in a danger zone, meaning, that the attack line is not crossing other coordinates.
    -- (y1 – y2)x + (x2 – x1)y + (x1y2 – x2y1) = 0
    
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
  -- @param #AI_AIR_DISPATCHER self
  function AI_AIR_DISPATCHER:onafterDefend( From, Event, To, DetectedItem, DefendersTotal, DefendersEngaged, DefendersMissing, DefenderFriendlies, DefenseTaskType )

    self:F( { From, Event, To, DetectedItem.Index, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing, DefenderFriendlies = DefenderFriendlies } )

    DetectedItem.Type = DefenseTaskType -- This is set to report the task type in the status panel.

    local AttackerSet = DetectedItem.Set
    local AttackerUnit = AttackerSet:GetFirst()
    
    if AttackerUnit and AttackerUnit:IsAlive() then
      local AttackerCount = AttackerSet:Count()
      local DefenderCount = 0
  
      for DefenderID, DefenderGroup in pairs( DefenderFriendlies or {} ) do

        -- Here we check if the defenders have a defense line to the attackers.
        -- If the attackers are behind enemy lines or too close to an other defense line; then don´t engage.
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
      local ClosestDefenderSquadronName = nil
      
      local BreakLoop = false
      
      while( DefenderCount > 0 and not BreakLoop ) do
      
        self:F( { DefenderSquadrons = self.DefenderSquadrons } )

        for SquadronName, DefenderSquadron in pairs( self.DefenderSquadrons or {} ) do
        
          if DefenderSquadron[DefenseTaskType] then

            local AirbaseCoordinate = DefenderSquadron.Airbase:GetCoordinate() -- Core.Point#COORDINATE
            local AttackerCoord = AttackerUnit:GetCoordinate()
            local InterceptCoord = DetectedItem.InterceptCoord
            self:F( { InterceptCoord = InterceptCoord } )
            if InterceptCoord then
              local InterceptDistance = AirbaseCoordinate:Get2DDistance( InterceptCoord )
              local AirbaseDistance = AirbaseCoordinate:Get2DDistance( AttackerCoord )
              self:F( { InterceptDistance = InterceptDistance, AirbaseDistance = AirbaseDistance, InterceptCoord = InterceptCoord } )
              
              if ClosestDistance == 0 or InterceptDistance < ClosestDistance then
                
                -- Only intercept if the distance to target is smaller or equal to the GciRadius limit.
                if AirbaseDistance <= self.DefenseRadius then
                
                  -- Check if there is a defense line...
                  local HasDefenseLine = self:HasDefenseLine( AirbaseCoordinate, DetectedItem )
                  if HasDefenseLine == true then
                    ClosestDistance = InterceptDistance
                    ClosestDefenderSquadronName = SquadronName
                  end
                end
              end
            end
          end
        end
        
        if ClosestDefenderSquadronName then
        
          local DefenderSquadron, Defense = self:CanDefend( ClosestDefenderSquadronName, DefenseTaskType )
          
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
                self:ResourceQueue( false, DefenderSquadron, DefendersNeeded, Defense, DefenseTaskType, DetectedItem, ClosestDefenderSquadronName )
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
  -- @param #AI_AIR_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.
  -- @return Core.Set#SET_UNIT The set of units of the targets to be engaged.
  -- @return #nil If there are no targets to be set.
  function AI_AIR_DISPATCHER:Evaluate_SEAD( DetectedItem )
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
    
    return nil, nil, nil
  end


  --- Creates an CAS task.
  -- @param #AI_AIR_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.
  -- @return Core.Set#SET_UNIT The set of units of the targets to be engaged.
  -- @return #nil If there are no targets to be set.
  function AI_AIR_DISPATCHER:Evaluate_CAS( DetectedItem )
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
    
    return nil, nil, nil
  end


  --- Evaluates an BAI task.
  -- @param #AI_AIR_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem The detected item.
  -- @return Core.Set#SET_UNIT The set of units of the targets to be engaged.
  -- @return #nil If there are no targets to be set.
  function AI_AIR_DISPATCHER:Evaluate_BAI( DetectedItem )
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
    
    return nil, nil, nil
  end




  --- Assigns A2G AI Tasks in relation to the detected items.
  -- @param #AI_AIR_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Functional.Detection#DETECTION_BASE} derived object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function AI_AIR_DISPATCHER:ProcessDetected( Detection )
  
    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}
    
    local TaskReport = REPORT:New()

          
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
        if DefenderTask.Target then
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

    local Report = REPORT:New( "\nTactical Overview" )

    local DefenderGroupCount = 0

    local DefendersTotal = 0

    -- Now that all obsolete tasks are removed, loop through the detected targets.
    for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
    
      local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
      local DetectedCount = DetectedSet:Count()
      local DetectedZone = DetectedItem.Zone

      self:F( { "Target ID", DetectedItem.ItemID } )
      DetectedSet:Flush( self )

      local DetectedID = DetectedItem.ID
      local DetectionIndex = DetectedItem.Index
      local DetectedItemChanged = DetectedItem.Changed
      
      local AttackCoordinate = self.Detection:GetDetectedItemCoordinate( DetectedItem )
      
      -- Calculate if for this DetectedItem if a defense needs to be initiated.
      -- This calculation is based on the distance between the defense point and the attackers, and the defensiveness parameter.
      -- The attackers closest to the defense coordinates will be handled first, or course!
      
      local EngageCoordinate = nil
      
      for DefenseCoordinateName, DefenseCoordinate in pairs( self.DefenseCoordinates ) do
        local DefenseCoordinate = DefenseCoordinate -- Core.Point#COORDINATE

        local EvaluateDistance = AttackCoordinate:Get2DDistance( DefenseCoordinate )
        
        if EvaluateDistance <= self.DefenseRadius then
        
          local DistanceProbability = ( self.DefenseRadius / EvaluateDistance * self.DefenseReactivity )
          local DefenseProbability = math.random()
          
          self:F( { DistanceProbability = DistanceProbability, DefenseProbability = DefenseProbability } )
          
          if DefenseProbability <= DistanceProbability / ( 300 / 30 ) then
            EngageCoordinate = DefenseCoordinate
            break
          end
        end
      end
      
      if EngageCoordinate then
        do 
          local DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies = self:Evaluate_SEAD( DetectedItem ) -- Returns a SET_UNIT with the SEAD targets to be engaged...
          if DefendersMissing and DefendersMissing > 0 then
            self:F( { DefendersTotal = DefendersTotal, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing } )
            self:Defend( DetectedItem, DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies, "SEAD", EngageCoordinate )
          end
        end
  
        do 
          local DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies = self:Evaluate_CAS( DetectedItem ) -- Returns a SET_UNIT with the CAS targets to be engaged...
          if DefendersMissing and DefendersMissing > 0 then
            self:F( { DefendersTotal = DefendersTotal, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing } )
            self:Defend( DetectedItem, DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies, "CAS", EngageCoordinate )
          end
        end
  
        do 
          local DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies = self:Evaluate_BAI( DetectedItem ) -- Returns a SET_UNIT with the CAS targets to be engaged...
          if DefendersMissing and DefendersMissing > 0 then
            self:F( { DefendersTotal = DefendersTotal, DefendersEngaged = DefendersEngaged, DefendersMissing = DefendersMissing } )
            self:Defend( DetectedItem, DefendersTotal, DefendersEngaged, DefendersMissing, Friendlies, "BAI", EngageCoordinate )
          end
        end
      end

--      do
--        local DefendersMissing, Friendlies = self:Evaluate_CAS( DetectedItem )
--        if DefendersMissing and DefendersMissing > 0 then
--          self:F( { DefendersMissing = DefendersMissing } )
--          self:CAS( DetectedItem, DefendersMissing, Friendlies )
--        end
--      end

      if self.TacticalDisplay then      
        -- Show tactical situation
        local ThreatLevel = DetectedItem.Set:CalculateThreatLevelA2G()
        Report:Add( string.format( " - %1s%s ( %4s ): ( #%d - %4s ) %s" , ( DetectedItem.IsDetected == true ) and "!" or " ", DetectedItem.ItemID, DetectedItem.Index, DetectedItem.Set:Count(), DetectedItem.Type or " --- ", string.rep(  "■", ThreatLevel ) ) )
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
        local DefenseQueueItem = DefenseQueueItem -- #AI_AIR_DISPATCHER.DefenseQueueItem
        Report:Add( string.format( "   - %s - %s", DefenseQueueItem.SquadronName, DefenseQueueItem.DefenderSquadron.TakeoffTime, DefenseQueueItem.DefenderSquadron.TakeoffInterval) )
        
      end
      
      Report:Add( string.format( "\n - Squadron Resources: ", #self.DefenseQueue ) )
      for DefenderSquadronName, DefenderSquadron in pairs( self.DefenderSquadrons ) do
        Report:Add( string.format( "   - %s - %d", DefenderSquadronName, DefenderSquadron.ResourceCount and DefenderSquadron.ResourceCount or "n/a" ) )
      end
  
      self:F( Report:Text( "\n" ) )
      trigger.action.outText( Report:Text( "\n" ), 25 )
    end
    
    return true
  end

end

do

  --- Calculates which HUMAN friendlies are nearby the area.
  -- @param #AI_AIR_DISPATCHER self
  -- @param DetectedItem The detected item.
  -- @return #number, Core.Report#REPORT The amount of friendlies and a text string explaining which friendlies of which type.
  function AI_AIR_DISPATCHER:GetPlayerFriendliesNearBy( DetectedItem )
  
    local DetectedSet = DetectedItem.Set
    local PlayersNearBy = self.Detection:GetPlayersNearBy( DetectedItem )
    
    local PlayerTypes = {}
    local PlayersCount = 0

    if PlayersNearBy then
      local DetectedTreatLevel = DetectedSet:CalculateThreatLevelA2G()
      for PlayerUnitName, PlayerUnitData in pairs( PlayersNearBy ) do
        local PlayerUnit = PlayerUnitData -- Wrapper.Unit#UNIT
        local PlayerName = PlayerUnit:GetPlayerName()
        --self:F( { PlayerName = PlayerName, PlayerUnit = PlayerUnit } )
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
  -- @param #AI_AIR_DISPATCHER self
  -- @param DetectedItem The detected item.
  -- @return #number, Core.Report#REPORT The amount of friendlies and a text string explaining which friendlies of which type.
  function AI_AIR_DISPATCHER:GetFriendliesNearBy( DetectedItem )
  
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
          FriendlyTypes[FriendlyType] = FriendlyTypes[FriendlyType] and ( FriendlyTypes[FriendlyType] + 1 ) or 1
          if DetectedTreatLevel < FriendlyUnitThreatLevel + 2 then
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
  -- @param #AI_AIR_DISPATCHER self
  -- @param #string SquadronName The squadron name.
  function AI_AIR_DISPATCHER:SchedulerPatrol( SquadronName )
    local PatrolTaskTypes = { "SEAD", "CAS", "BAI" }
    local PatrolTaskType = PatrolTaskTypes[math.random(1,3)]
    self:Patrol( SquadronName, PatrolTaskType )    
  end

end


