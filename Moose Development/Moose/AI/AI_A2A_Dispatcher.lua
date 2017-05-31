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
    
    -- This table models the currently alive AI_A2A processes.
    self.AI_A2A = self.AI_A2A or {}
    
    -- These two tables model the AIGroups having an assignment and the Targets having an AIGroup.    
    self.A2A_Targets = self.A2A_Targets or {}
    self.A2A_Tasks = self.A2A_Tasks or {}
    
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
  
  
  function AI_A2A_DISPATCHER:onafterCAP()
  
    local A2AType = "CAP"

    for CAPName, CAP in pairs( self.AI_A2A[A2AType] or {} ) do

      local AIGroup = CAP.Spawn:Spawn()
      self:F( { AIGroup = AIGroup:GetName() } )

      if AIGroup then

        local Fsm = AI_A2A_CAP:New( AIGroup, CAP.Zone, CAP.FloorAltitude, CAP.CeilingAltitude, CAP.MinSpeed, CAP.MaxSpeed, CAP.AltType )
        Fsm:__Patrol( 1 )

        self.A2A_Tasks = self.A2A_Tasks or {}
        self.A2A_Tasks[AIGroup] = self.A2A_Tasks[AIGroup] or {}
        self.A2A_Tasks[AIGroup].Type = A2AType
        self.A2A_Tasks[AIGroup].Fsm = Fsm
      end
    end
  end

  function AI_A2A_DISPATCHER:onafterENGAGE( From, Event, To, TargetSetUnit, TargetReference, AIGroups )
  
    local A2AType = "CAP"

    self:F( { AIGroups = AIGroups } )

    if AIGroups then

      for AIGroupID, AIGroup in pairs( AIGroups ) do

        local Fsm = self.A2A_Tasks[AIGroup].Fsm
        Fsm:__Engage( 1, TargetSetUnit ) -- Engage on the TargetSetUnit

        self.A2A_Tasks[AIGroup].Target = TargetReference
  
        self.A2A_Targets[TargetReference] = self.A2A_Targets[TargetReference] or {}
        self.A2A_Targets[TargetReference].Set = TargetSetUnit
        self.A2A_Targets[TargetReference].Groups = self.A2A_Targets[TargetReference].Groups or {}
        local Groups = self.A2A_Targets[TargetReference].Groups
        local GroupName = AIGroup:GetName()
        Groups[GroupName] = AIGroup
      end
    end
  end


  function AI_A2A_DISPATCHER:onafterINTERCEPT( From, Event, To, TargetSetUnit, TargetReference, DefendersMissing )

    local A2AType = "INTERCEPT"
    
    local ClosestDistance = 0
    local ClosestINTERCEPTName = nil
    
    local AttackerCount = TargetSetUnit:Count()
    DefendersMissing = AttackerCount - DefendersMissing
    
    while( DefendersMissing < AttackerCount ) do

      for INTERCEPTName, INTERCEPT in pairs( self.AI_A2A[A2AType] or {} ) do
  
        local SpawnCoord = INTERCEPT.Spawn:GetCoordinate() -- Core.Point#COORDINATE
        local TargetCoord = TargetSetUnit:GetFirst():GetCoordinate()
        local Distance = SpawnCoord:Get2DDistance( TargetCoord )
  
        if ClosestDistance == 0 or Distance < ClosestDistance then
          ClosestDistance = Distance
          ClosestINTERCEPTName = INTERCEPTName
        end
      end
      
      if ClosestINTERCEPTName then
      
        local INTERCEPT = self.AI_A2A[A2AType][ClosestINTERCEPTName]
      
        local AIGroup = INTERCEPT.Spawn:Spawn()
        self:F( { AIGroup = AIGroup:GetName() } )
  
        if AIGroup then
        
          DefendersMissing = DefendersMissing + AIGroup:GetSize()
  
          local Fsm = AI_A2A_INTERCEPT:New( AIGroup )
          Fsm:__Engage( 1, TargetSetUnit ) -- Engage on the TargetSetUnit
  
          self.A2A_Tasks = self.A2A_Tasks or {}
          self.A2A_Tasks[AIGroup] = self.A2A_Tasks[AIGroup] or {}
          self.A2A_Tasks[AIGroup].Type = A2AType
          self.A2A_Tasks[AIGroup].Fsm = Fsm
          self.A2A_Tasks[AIGroup].Target = TargetReference
          
          self.A2A_Targets[TargetReference] = self.A2A_Targets[TargetReference] or {}
          self.A2A_Targets[TargetReference].Set = TargetSetUnit
          self.A2A_Targets[TargetReference].Groups = self.A2A_Targets[TargetReference].Groups or {}
          local Groups = self.A2A_Targets[TargetReference].Groups
          local GroupName = AIGroup:GetName()
          Groups[GroupName] = AIGroup
          
        end
      end
    end
  end


  
  function AI_A2A_DISPATCHER:SetCAP( CAPName, CAPSpawn, CAPZone, CAPFloorAltitude, CAPCeilingAltitude, CAPMinSpeed, CAPMaxSpeed, CAPAltType )
  
    self.AI_A2A["CAP"] = self.AI_A2A["CAP"] or {} 
    self.AI_A2A["CAP"][CAPName] = self.AI_A2A["CAP"][CAPName] or {}
    
    local CAP = self.AI_A2A["CAP"][CAPName]
    CAP.Name = CAPName
    CAP.Spawn = CAPSpawn -- Funtional.Spawn#SPAWN
    CAP.Zone = CAPZone
    CAP.FloorAltitude = CAPFloorAltitude
    CAP.CeilingAltitude = CAPCeilingAltitude
    CAP.MinSpeed = CAPMinSpeed
    CAP.MaxSpeed = CAPMaxSpeed
    CAP.AltType = CAPAltType
    
  end
  
  function AI_A2A_DISPATCHER:SetINTERCEPT( Name, Spawn, MinSpeed, MaxSpeed )
  
    self.AI_A2A["INTERCEPT"] = self.AI_A2A["INTERCEPT"] or {} 
    self.AI_A2A["INTERCEPT"][Name] = self.AI_A2A["INTERCEPT"][Name] or {}
    
    local INTERCEPT = self.AI_A2A["INTERCEPT"][Name]
    INTERCEPT.Name = Name
    INTERCEPT.Spawn = Spawn
    INTERCEPT.MinSpeed = MinSpeed
    INTERCEPT.MaxSpeed = MaxSpeed
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
  
  function AI_A2A_DISPATCHER:CountDefendersEngaged( DetectedItem )

    -- First, count the active AIGroups Units, targetting the DetectedSet
    local AIUnitCount = 0
    
    for AIGroupName, AIGroup in pairs( ( self.A2A_Targets[DetectedItem] and self.A2A_Targets[DetectedItem].Groups ) or {} ) do
      local AIGroup = AIGroup -- Wrapper.Group#GROUP
      if AIGroup:IsAlive() then
        AIUnitCount = AIUnitCount + AIGroup:GetSize()
      end 
    end

    return AIUnitCount
  end
  
  function AI_A2A_DISPATCHER:CountDefendersToBeEngaged( DetectedItem, DefenderCount )
  
    local ResultAIGroups = nil

    local DetectedSet = DetectedItem.Set
    local DetectedCount = DetectedSet:Count()

    local AIFriendlies = self:GetAIFriendliesNearBy( DetectedItem )
    
    for AIName, AIFriendly in pairs( AIFriendlies ) do
      -- We only allow to ENGAGE targets as long as the Units on both sides are balanced.
      if DetectedCount > DefenderCount then 
        local AIGroup = AIFriendly :GetGroup() -- Wrapper.Group#GROUP
        self:F( { AIFriendly = AIGroup } )
        if AIGroup:IsAlive() then
          -- Ok, so we have a friendly near the potential target.
          -- Now we need to check if the AIGroup has a Task.
          local AIGroupTask = self.A2A_Tasks[AIGroup]
          self:F({AIGroupTask = AIGroupTask})
          if AIGroupTask then
            -- The Task should be CAP
            self:F( { Type = AIGroupTask.Type } )
            if AIGroupTask.Type == "CAP" then
              -- If there is no target, then add the AIGroup to the ResultAIGroups for Engagement to the TargetSet
              self:F( { Target = AIGroupTask.Target } )
              if AIGroupTask.Target == nil then
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
  
    local DetectedSet = DetectedItem.Set

    -- First, count the active AIGroups Units, targetting the DetectedSet
    local DefenderCount = self:CountDefendersEngaged( DetectedItem )

    local DefenderGroups = self:CountDefendersToBeEngaged( DetectedItem, DefenderCount )
    
    -- Only allow ENGAGE when there are Players near the zone, and when the Area has detected items since the last run in a 60 seconds time zone.
    if DefenderGroups and DetectedItem.IsDetected == true then
      
      return DetectedSet, DefenderGroups
    end
    
    return nil, nil
  end
  
  --- Creates an INTERCEPT task when there are targets for it.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function AI_A2A_DISPATCHER:EvaluateINTERCEPT( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    local AttackerSet = DetectedItem.Set
    AttackerSet:Flush()
    local AttackerCount = AttackerSet:Count()

    -- First, count the active AIGroups Units, targetting the DetectedSet
    local DefenderCount = self:CountDefendersEngaged( DetectedItem )
    local DefendersMissing = AttackerCount - DefenderCount

    -- Only allow ENGAGE when there are Players near the zone, and when the Area has detected items since the last run in a 60 seconds time zone.
    if DetectedItem.IsDetected == true then
      
      return DetectedItem.Set, DefendersMissing
    end
    
    return nil, nil
  end


  

  --- Calculates which friendlies are nearby the area
  -- @param #AI_A2A_DISPATCHER self
  -- @param DetectedItem
  -- @return #number, Core.CommandCenter#REPORT
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


  --- Evaluates the removal of the Task from the Mission.
  -- Can only occur when the DetectedItem is Changed AND the state of the Task is "Planned".
  -- @param #AI_A2A_DISPATCHER self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Tasking.Task#TASK Task
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Detection#DETECTION_BASE} derived object.
  -- @param #boolean DetectedItemID
  -- @param #boolean DetectedItemChange
  -- @return Tasking.Task#TASK
  function AI_A2A_DISPATCHER:EvaluateRemoveTask( DetectedItem, A2A_Index )
    
    local A2A_Target = self.A2A_Targets[A2A_Index]

    if A2A_Target then 
      
      for AIGroupName, AIGroup in pairs( A2A_Target.Groups ) do
        local AIGroup = AIGroup -- Wrapper.Group#GROUP
        if not AIGroup:IsAlive() then
          self.A2A_Tasks[AIGroup] = nil
          self.A2A_Targets[A2A_Index].Groups[AIGroupName] = nil
        end
      end
       
      local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
      DetectedSet:Flush()
      self:E( { DetectedSetCount = DetectedSet:Count() } )
      if DetectedSet:Count() == 0 then
        self.A2A_Targets[A2A_Index] = nil
      end
    end

    return self.A2A_Targets[A2A_Index]
  end


  --- Assigns A2A AI Tasks in relation to the detected items.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE Detection The detection created by the @{Detection#DETECTION_BASE} derived object.
  -- @return #boolean Return true if you want the task assigning to continue... false will cancel the loop.
  function AI_A2A_DISPATCHER:ProcessDetected( Detection )
    self:E()
  
    local AreaMsg = {}
    local TaskMsg = {}
    local ChangeMsg = {}
    
    local TaskReport = REPORT:New()
      
--    -- Checking the Process queue for the dispatcher, and removing any obsolete task!
--    for AI_A2A_Index, AI_A2A_Process in pairs( self.AI_A2A_Processes ) do
--
--      local AI_A2A_Process = AI_A2A_Process
--      if AI_A2A_Process:IsStatePlanned() then
--        local DetectedItem = Detection:GetDetectedItem( AI_A2A_Index )
--        if not DetectedItem then
--          self.AI_A2A_Process[AI_A2A_Index] = nil
--        end
--      end
--    end

    -- Now that all obsolete tasks are removed, loop through the detected targets.
    for DetectedItemID, DetectedItem in pairs( Detection:GetDetectedItems() ) do
    
      local DetectedItem = DetectedItem -- Functional.Detection#DETECTION_BASE.DetectedItem
      local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
      local DetectedCount = DetectedSet:Count()
      local DetectedZone = DetectedItem.Zone
      self:E( { "Targets in DetectedItem", DetectedItem.ItemID, DetectedSet:Count() } )
      DetectedSet:Flush()
      
      local DetectedID = DetectedItem.ID
      local A2A_Index = DetectedItem.Index
      local DetectedItemChanged = DetectedItem.Changed
      
      self:E( { A2A_Index = A2A_Index } )
      
      
      local A2A_Target = self:EvaluateRemoveTask( DetectedItem, A2A_Index )
      self:E( { A2A_Index = A2A_Index, A2A_Target = A2A_Target } )
      DetectedSet:Flush()

      -- Evaluate A2A_Action
      if not A2A_Target then
        local TargetSetUnit, AIGroups = self:EvaluateENGAGE( DetectedItem ) -- Returns a SetUnit if there are targets to be INTERCEPTed...
        self:F( { AIGroups = AIGroups } )
        if TargetSetUnit then
          self:ENGAGE( TargetSetUnit, A2A_Index, AIGroups )
        else
          do
            local AttackerSet, DefendersMissing = self:EvaluateINTERCEPT( DetectedItem )
            self:F( { DefendersMissing = DefendersMissing } )
            AttackerSet:Flush()
            if AttackerSet then
              self:INTERCEPT( AttackerSet, A2A_Index, DefendersMissing )
            end
          end
        end
      end
    end
    
    return true
  end

end
