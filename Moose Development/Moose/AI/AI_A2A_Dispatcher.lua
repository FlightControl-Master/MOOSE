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
    
    
    
    
    self:__Start( 5 )
    
    return self
  end
  
  function AI_A2A_DISPATCHER:onafterCAP()
    for CAPName, CAP in pairs( self.AI_A2A["CAP"] ) do
      local AIGroup = CAP.Spawn:Spawn()
      self:F( { AIGroup = AIGroup:GetName() } )
      if AIGroup then
        CAP.Fsm = CAP.Fsm or {}
        CAP.Fsm[AIGroup] = AI_A2A_CAP:New( AIGroup, CAP.Zone, CAP.FloorAltitude, CAP.CeilingAltitude, CAP.MinSpeed, CAP.MaxSpeed, CAP.AltType )
        CAP.Fsm[AIGroup]:__Patrol( 2 )
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
  
  function AI_A2A_DISPATCHER:SetINTERCEPT( INTERCEPTName, INTERCEPTSpawn, CAPZone, CAPFloorAltitude, CAPCeilingAltitude, CAPMinSpeed, CAPMaxSpeed, CAPAltType )
  
    self.AI_A2A["INTERCEPT"] = self.AI_A2A["INTERCEPT"] or {} 
    self.AI_A2A["INTERCEPT"][INTERCEPTName] = self.AI_A2A["INTERCEPT"][INTERCEPTName] or {}
    
    local INTERCEPT = self.AI_A2A["INTERCEPT"][INTERCEPTName]
    INTERCEPT.Name = INTERCEPTName
    INTERCEPT.Spawn = INTERCEPTSpawn
    INTERCEPT.Zone = CAPZone
    INTERCEPT.FloorAltitude = CAPFloorAltitude
    INTERCEPT.CeilingAltitude = CAPCeilingAltitude
    INTERCEPT.MinSpeed = CAPMinSpeed
    INTERCEPT.MaxSpeed = CAPMaxSpeed
    INTERCEPT.AltType = CAPAltType
  end
  
  --- Creates an INTERCEPT task when there are targets for it.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function AI_A2A_DISPATCHER:EvaluateINTERCEPT( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone

    -- Check if there is at least one UNIT in the DetectedSet is visible.
    
    if DetectedItem.IsDetected == true then

      -- Here we're doing something advanced... We're copying the DetectedSet.
      local TargetSetUnit = SET_UNIT:New()
      TargetSetUnit:SetDatabase( DetectedSet )
      TargetSetUnit:FilterOnce() -- Filter but don't do any events!!! Elements are added manually upon each detection.
    
      return TargetSetUnit
    end
    
    return nil
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

  
  --- Creates an ENGAGE task when there are human friendlies airborne near the targets.
  -- @param #AI_A2A_DISPATCHER self
  -- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
  -- @return Set#SET_UNIT TargetSetUnit: The target set of units.
  -- @return #nil If there are no targets to be set.
  function AI_A2A_DISPATCHER:EvaluateENGAGE( DetectedItem )
    self:F( { DetectedItem.ItemID } )
  
    local ResultEngage = false
    local ResultAIGroup = nil
    local ResultCAPName = nil
  
    local DetectedSet = DetectedItem.Set
    local DetectedZone = DetectedItem.Zone

    for CAPName, CAP in pairs( self.AI_A2A["CAP"] ) do
      for AIGroup, Fsm in pairs( CAP.Fsm ) do
        self:F( { CAP = CAPName } )
        self:F( { CAPFsm = CAP.Fsm } )
        self:F( { AIGroup = tostring( AIGroup ), AIGroup:GetName() } )
        local CAPFsm = CAP.Fsm[AIGroup]
        if CAPFsm then
          self:F( { CAPState = CAPFsm:GetState() } )
          if CAPFsm:Is( "Patrolling" ) then
            ResultEngage = true
            ResultAIGroup = AIGroup
            ResultCAPName = CAPName
          end
        end
        break
      end
    end

    
    -- Only allow ENGAGE when there are Players near the zone, and when the Area has detected items since the last run in a 60 seconds time zone.
    if ResultEngage == true and DetectedItem.IsDetected == true then
      
      self:E("ENGAGE")
      return DetectedSet, ResultCAPName, ResultAIGroup
    end
    
    return nil
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
  function AI_A2A_DISPATCHER:EvaluateRemoveTask( Mission, Task, Detection, DetectedItem, DetectedItemIndex, DetectedItemChanged )
    
    if Task then

      if Task:IsStatePlanned() then
        local TaskName = Task:GetName()
        local TaskType = TaskName:match( "(%u+)%.%d+" )
        
        self:T2( { TaskType = TaskType } )
        
        local Remove = false
        
        local IsPlayers = Detection:IsPlayersNearBy( DetectedItem )
        if TaskType == "ENGAGE" then
          if IsPlayers == false then
            Remove = true
          end
        end
        
        if TaskType == "INTERCEPT" then
          if IsPlayers == true then
            Remove = true
          end
          if DetectedItem.IsDetected == false then
            Remove = true
          end
        end
        
        if TaskType == "SWEEP" then
          if DetectedItem.IsDetected == true then
            Remove = true
          end
        end

        local DetectedSet = DetectedItem.Set -- Core.Set#SET_UNIT
        --DetectedSet:Flush()
        --self:E( { DetectedSetCount = DetectedSet:Count() } )
        if DetectedSet:Count() == 0 then
          Remove = true
        end
         
        if DetectedItemChanged == true or Remove then
          --self:E( "Removing Tasking: " .. Task:GetTaskName() )
          Mission:RemoveTask( Task )
          self.Tasks[DetectedItemIndex] = nil
        end
      end
    end
    
    return Task
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
      --self:E( { "Targets in DetectedItem", DetectedItem.ItemID, DetectedSet:Count(), tostring( DetectedItem ) } )
      --DetectedSet:Flush()
      
      local DetectedID = DetectedItem.ID
      local AI_A2A_Index = DetectedItem.Index
      local DetectedItemChanged = DetectedItem.Changed
      
--      local AI_A2A_Process = self.AI_A2A_Processes[AI_A2A_Index]
--      AI_A2A_Process = self:EvaluateRemoveTask( AI_A2A_Process, Detection, DetectedItem, AI_A2A_Index, DetectedItemChanged ) -- Task will be removed if it is planned and changed.

      -- Evaluate A2A_Action
      if DetectedCount > 0 then
        local TargetSetUnit, CAPName, AIGroup = self:EvaluateENGAGE( DetectedItem ) -- Returns a SetUnit if there are targets to be INTERCEPTed...
        if TargetSetUnit then
          local CAP = self.AI_A2A["CAP"][CAPName]
          CAP.Fsm[AIGroup]:__Engage( 1, TargetSetUnit )
        end
      end
    end
    
    return true
  end

end
