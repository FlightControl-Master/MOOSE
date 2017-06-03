--- **Tasking** - The AI_A2A_DISPATCHER creates and manages AI_A2A tasks based on detected targets.
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
  -- The @{#AI_A2A_DISPATCHER} class implements the dynamic dispatching of tasks upon groups of detected units determined a @{Set} of EWR installation groups.
  -- The EWR will detect units, will group them, and will dispatch AI_A2A tasks to groups. Depending on the type of target detected, different tasks will be dispatched.
  -- Find a summary below describing for which situation a task type is created:
  -- 
  --   * **INTERCEPT**: Is created when the target is known, is detected and within a danger zone, and there is no friendly airborne in range.
  --   * **SWEEP**: Is created when the target is unknown, was detected and the last position is only known, and within a danger zone, and there is no friendly airborne in range.
  --   * **CAP**: Is created during the mission. Targets are patrolling the zones outlined.
  --   * **ENGAGE Task**: Is created when the target is known, is detected and within a danger zone, and there is a friendly airborne patrolling and in range, that will receive this task.
  --   
  -- Other task types will follow...
  -- 
  -- # AI_A2A_DISPATCHER constructor:
  -- --------------------------------------
  -- The @{#AI_A2A_DISPATCHER.New}() method creates a new AI_A2A_DISPATCHER instance.
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
  -- @param Functional.Spawn#SPAWN SpawnA2A The SPAWN object to create groups that will receive the dispatched A2A Tasks. These spawn objects MUST contain all AI units.
  -- @param Functional.Detection#DETECTION_BASE Detection The detection results that are used to dynamically assign new tasks.
  -- @return #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:New( Detection )
  
    -- Inherits from DETECTION_MANAGER
    local self = BASE:Inherit( self, DETECTION_MANAGER:New( nil, Detection ) ) -- #AI_A2A_DISPATCHER
    
    self.Detection = Detection
    
    -- This table models the DefenderSquadron templates.
    self.DefenderSquadrons = self.DefenderSquadrons or {} -- The Defender Squadrons.    
    self.DefenderTasks = self.DefenderTasks or {} -- The Defenders Tasks.
    
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
    
    
    
    self:__Start( 5 )
    
    return self
  end
  
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:onafterCAP( From, Event, To, SquadronName )
  
    self:F({SquadronName = SquadronName})
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}
    
    local DefenderSquadron = self.DefenderSquadrons[SquadronName]
    local Cap = DefenderSquadron.Cap
    
    if Cap then
    
      if self:CanCAP( SquadronName ) then
        local Spawn = DefenderSquadron.Spawn[ math.random( 1, #DefenderSquadron.Spawn ) ]
        local AIGroup = Spawn:SpawnAtAirbase( DefenderSquadron.Airbase )
        self:F( { AIGroup = AIGroup:GetName() } )
  
        if AIGroup then
  
          local Fsm = AI_A2A_CAP:New( AIGroup, Cap.Zone, Cap.FloorAltitude, Cap.CeilingAltitude, Cap.MinSpeed, Cap.MaxSpeed, Cap.AltType )
          Fsm:SetDispatcher( self )
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
    self.DefenderTasks[AIGroup] = nil
    return self
  end

  
  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:SetDefenderTask( AIGroup, Type, Fsm, Target )
    self.DefenderTasks[AIGroup] = self.DefenderTasks[AIGroup] or {}
    self.DefenderTasks[AIGroup].Type = Type
    self.DefenderTasks[AIGroup].Fsm = Fsm
    
    self:SetDefenderTaskTarget( AIGroup, Target )
    return self
  end
  
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  -- @param Wrapper.Group#GROUP AIGroup
  function AI_A2A_DISPATCHER:SetDefenderTaskTarget( AIGroup, Target )

    if Target then
      AIGroup:MessageToAll( AIGroup:GetName().. " target " .. Target.Index, 300 )
      self.DefenderTasks[AIGroup].Target = Target
    end
    return self
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:onafterENGAGE( From, Event, To, Target, AIGroups )
  
    self:F( { AIGroups = AIGroups } )

    if AIGroups then

      for AIGroupID, AIGroup in pairs( AIGroups ) do

        local Fsm = self:GetDefenderTaskFsm( AIGroup )
        Fsm:__Engage( 1, Target.Set ) -- Engage on the TargetSetUnit
        
        self:SetDefenderTaskTarget( AIGroup, Target )
      end
    end
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:onafterINTERCEPT( From, Event, To, Target, DefendersMissing )

    local ClosestDistance = 0
    local ClosestDefenderSquadronName = nil
    
    local AttackerCount = Target.Set:Count()
    local DefendersCount = 0

    while( DefendersCount < DefendersMissing ) do

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
      
        local DefenderSquadron = self.DefenderSquadrons[ClosestDefenderSquadronName]
        local Intercept = self.DefenderSquadrons[ClosestDefenderSquadronName].Intercept
      
        local Spawn = DefenderSquadron.Spawn[ math.random( 1, #DefenderSquadron.Spawn ) ]
        local AIGroup = Spawn:SpawnAtAirbase( DefenderSquadron.Airbase )
        self:F( { AIGroup = AIGroup:GetName() } )
  
        if AIGroup then
        
          DefendersCount = DefendersCount + AIGroup:GetSize()
  
          local Fsm = AI_A2A_INTERCEPT:New( AIGroup, Intercept.MinSpeed, Intercept.MaxSpeed )
          Fsm:SetDispatcher( self )
          Fsm:__Engage( 1, Target.Set ) -- Engage on the TargetSetUnit

  
          self:SetDefenderTask( AIGroup, "INTERCEPT", Fsm, Target )
          
          function Fsm:onafterRTB()
            local Dispatcher = self:GetDispatcher() -- #AI_A2A_DISPATCHER
            local AIGroup = self:GetControllable()
            AIGroup:MessageToAll( AIGroup:GetName().. " cleared " .. Dispatcher.DefenderTasks[AIGroup].Target.Index, 300 )
            Dispatcher:ClearDefenderTask( AIGroup )
          end
          
        end
      end
    end
  end


  ---
  -- @param #AI_A2A_DISPATCHER self
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
      DefenderSquadron.Spawn[1] = SPAWN:New( SpawnTemplate )
    else
      for TemplateID, SpawnTemplate in pairs( SpawnTemplates ) do
        DefenderSquadron.Spawn[#DefenderSquadron.Spawn+1] = SPAWN:New( SpawnTemplate )
      end
    end
    DefenderSquadron.Resources = Resources
  end

  
  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:SetCAP( SquadronName, Zone, FloorAltitude, CeilingAltitude, MinSpeed, MaxSpeed, AltType )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}
    
    local DefenderSquadron = self.DefenderSquadrons[SquadronName]

    local Cap = self.DefenderSquadrons[SquadronName].Cap
    Cap.Name = SquadronName
    Cap.Zone = Zone
    Cap.FloorAltitude = FloorAltitude
    Cap.CeilingAltitude = CeilingAltitude
    Cap.MinSpeed = MinSpeed
    Cap.MaxSpeed = MaxSpeed
    Cap.AltType = AltType

    self:SetCAPInterval( SquadronName, 2, 180, 600, 1 )
    
  end
  
  ---
  -- @param AI_A2A_DISPATCHER
  function AI_A2A_DISPATCHER:SchedulerCAP( SquadronName )
    self:CAP( SquadronName )
  end
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:SetCAPInterval( SquadronName, CapLimit, LowInterval, HighInterval, Probability )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}

    local DefenderSquadron = self.DefenderSquadrons[SquadronName]

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
  function AI_A2A_DISPATCHER:GetCAPDelay( SquadronName )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}

    local DefenderSquadron = self.DefenderSquadrons[SquadronName]

    local Cap = self.DefenderSquadrons[SquadronName].Cap
    if Cap then
      return math.random( Cap.LowInterval, Cap.HighInterval )
    else
      error( "This squadron does not exist:" .. SquadronName )
    end
  end

  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:CanCAP( SquadronName )
    self:F({SquadronName = SquadronName})
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Cap = self.DefenderSquadrons[SquadronName].Cap or {}

    local DefenderSquadron = self.DefenderSquadrons[SquadronName]

    local Cap = DefenderSquadron.Cap
    if Cap then
      self:E( { Cap = Cap } )
      local CapCount = self:CountCapAirborne( SquadronName )
      self:F( { CapCount = CapCount, CapLimit = Cap.CapLimit } )
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
  function AI_A2A_DISPATCHER:SetINTERCEPT( SquadronName, MinSpeed, MaxSpeed )
  
    self.DefenderSquadrons[SquadronName] = self.DefenderSquadrons[SquadronName] or {} 
    self.DefenderSquadrons[SquadronName].Intercept = self.DefenderSquadrons[SquadronName].Intercept or {}
    
    local Intercept = self.DefenderSquadrons[SquadronName].Intercept
    Intercept.Name = SquadronName
    Intercept.MinSpeed = MinSpeed
    Intercept.MaxSpeed = MaxSpeed
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
    
    for AIGroup, DefenderTask in pairs( self:GetDefenderTasks() ) do
      local AIGroup = AIGroup -- Wrapper.Group#GROUP
      if self:GetDefenderTaskTarget( AIGroup ) == Target then
        if AIGroup:IsAlive() then
          AIUnitCount = AIUnitCount + AIGroup:GetSize()
        end
      end
    end

    return AIUnitCount
  end
  
  ---
  -- @param #AI_A2A_DISPATCHER self
  function AI_A2A_DISPATCHER:CountDefendersToBeEngaged( DetectedItem, DefenderCount )
  
    local ResultAIGroups = nil

    local DetectedSet = DetectedItem.Set
    local DetectedCount = DetectedSet:Count()

    local AIFriendlies = self:GetAIFriendliesNearBy( DetectedItem )
    
    for AIName, AIFriendly in pairs( AIFriendlies or {} ) do
      -- We only allow to ENGAGE targets as long as the Units on both sides are balanced.
      if DetectedCount > DefenderCount then 
        local AIGroup = AIFriendly:GetGroup() -- Wrapper.Group#GROUP
        self:F( { AIFriendly = AIGroup } )
        if AIGroup and AIGroup:IsAlive() then
          -- Ok, so we have a friendly near the potential target.
          -- Now we need to check if the AIGroup has a Task.
          local DefenderTask = self:GetDefenderTask( AIGroup )
          self:F( {AIGroupTask = DefenderTask } )
          if DefenderTask then
            -- The Task should be CAP or INTERCEPT
            self:F( { Type = DefenderTask.Type } )
            if DefenderTask.Type == "CAP" or DefenderTask.Type == "INTERCEPT" then
              -- If there is no target, then add the AIGroup to the ResultAIGroups for Engagement to the TargetSet
              self:F( { Target = DefenderTask.Target } )
              if DefenderTask.Target == nil then
                ResultAIGroups = ResultAIGroups or {}
                ResultAIGroups[AIGroup] = AIGroup
                DefenderCount = DefenderCount + AIGroup:GetSize()
              end
            end
          end 
        end
      else
        break
      end
    end

    return ResultAIGroups
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

    if Target.IsDetected == true then
      
      return DefendersMissing
    end
    
    return nil, nil
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

  --- Calculates which AI friendlies are nearby the area
  -- @param #AI_A2A_DISPATCHER self
  -- @param DetectedItem
  -- @return #number, Core.CommandCenter#REPORT
  function AI_A2A_DISPATCHER:GetAIFriendliesNearBy( DetectedItem )
  
    local FriendliesNearBy = self.Detection:GetFriendliesNearBy( DetectedItem )
    
    return FriendliesNearBy
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

          

    -- Now that all obsolete tasks are removed, loop through the detected targets.
    for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
    
      local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
      local DetectedCount = DetectedSet:Count()
      local DetectedZone = DetectedItem.Zone

      self:F( { "Targets in DetectedItem", DetectedItem.ItemID, DetectedSet:Count() } )

      for AIGroup, DefenderTask in pairs( self:GetDefenderTasks() ) do
        local AIGroup = AIGroup -- Wrapper.Group#GROUP
        if not AIGroup:IsAlive() then
          self:ClearDefenderTask( AIGroup )            
        end
      end

      local DetectedID = DetectedItem.ID
      local A2A_Index = DetectedItem.Index
      local DetectedItemChanged = DetectedItem.Changed
      
      do 
        local AIGroups = self:EvaluateENGAGE( DetectedItem ) -- Returns a SetUnit if there are targets to be INTERCEPTed...
        self:F( { AIGroups = AIGroups } )
        if AIGroups then
          self:ENGAGE( DetectedItem, AIGroups )
        end
      end

      do
        local DefendersMissing = self:EvaluateINTERCEPT( DetectedItem )
        self:F( { DefendersMissing = DefendersMissing } )
        if DefendersMissing then
          self:INTERCEPT( DetectedItem, DefendersMissing )
        end
      end
    end
    
    return true
  end

end
