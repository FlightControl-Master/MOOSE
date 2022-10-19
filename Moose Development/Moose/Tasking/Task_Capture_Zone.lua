--- **Tasking** - The TASK_Protect models tasks for players to protect or capture specific zones.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: MillerTime
-- 
-- ===
--   
-- @module Tasking.Task_Capture_Zone
-- @image MOOSE.JPG

do -- TASK_ZONE_GOAL

  --- The TASK_ZONE_GOAL class
  -- @type TASK_ZONE_GOAL
  -- @field Functional.ZoneGoal#ZONE_GOAL ZoneGoal
  -- @extends Tasking.Task#TASK

  --- # TASK_ZONE_GOAL class, extends @{Tasking.Task#TASK}
  -- 
  -- The TASK_ZONE_GOAL class defines the task to protect or capture a protection zone. 
  -- The TASK_ZONE_GOAL is implemented using a @{Core.Fsm#FSM_TASK}, and has the following statuses:
  -- 
  --   * **None**: Start of the process
  --   * **Planned**: The A2G task is planned.
  --   * **Assigned**: The A2G task is assigned to a @{Wrapper.Group#GROUP}.
  --   * **Success**: The A2G task is successfully completed.
  --   * **Failed**: The A2G task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
  -- 
  -- ## Set the scoring of achievements in an A2G attack.
  -- 
  -- Scoring or penalties can be given in the following circumstances:
  -- 
  --   * @{#TASK_ZONE_GOAL.SetScoreOnDestroy}(): Set a score when a target in scope of the A2G attack, has been destroyed.
  --   * @{#TASK_ZONE_GOAL.SetScoreOnSuccess}(): Set a score when all the targets in scope of the A2G attack, have been destroyed.
  --   * @{#TASK_ZONE_GOAL.SetPenaltyOnFailed}(): Set a penalty when the A2G attack has failed.
  -- 
  -- @field #TASK_ZONE_GOAL
  TASK_ZONE_GOAL = {
    ClassName = "TASK_ZONE_GOAL",
  }
  
  --- Instantiates a new TASK_ZONE_GOAL.
  -- @param #TASK_ZONE_GOAL self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Functional.ZoneGoalCoalition#ZONE_GOAL_COALITION ZoneGoal
  -- @return #TASK_ZONE_GOAL self
  function TASK_ZONE_GOAL:New( Mission, SetGroup, TaskName, ZoneGoal, TaskType, TaskBriefing )
    local self = BASE:Inherit( self, TASK:New( Mission, SetGroup, TaskName, TaskType, TaskBriefing ) ) -- #TASK_ZONE_GOAL
    self:F()
  
    self.ZoneGoal = ZoneGoal
    self.TaskType = TaskType
    
    local Fsm = self:GetUnitProcess()
    

    Fsm:AddTransition( "Assigned", "StartMonitoring", "Monitoring" )
    Fsm:AddTransition( "Monitoring", "Monitor", "Monitoring", {} )
    Fsm:AddProcess( "Monitoring", "RouteToZone", ACT_ROUTE_ZONE:New(), {} )
    
    Fsm:AddTransition( "Rejected", "Reject", "Aborted" )
    Fsm:AddTransition( "Failed", "Fail", "Failed" )
    
    self:SetTargetZone( self.ZoneGoal:GetZone() )

    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK Task
    function Fsm:OnAfterAssigned( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      self:__StartMonitoring( 0.1 )
      self:__RouteToZone( 0.1 )
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_ZONE_GOAL Task
    function Fsm:onafterStartMonitoring( TaskUnit, Task )
      self:F( { self } )
      self:__Monitor( 0.1 )
    end
    
    --- Monitor Loop
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_ZONE_GOAL Task
    function Fsm:onafterMonitor( TaskUnit, Task )
      self:F( { self } )
      self:__Monitor( 15 )
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2G#TASK_ZONE_GOAL Task
    function Fsm:onafterRouteTo( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      if Task:GetTargetZone( TaskUnit ) then
        self:__RouteToZone( 0.1 )
      end
    end

    return self
 
  end

  --- @param #TASK_ZONE_GOAL self
  -- @param Functional.ZoneGoal#ZONE_GOAL ZoneGoal The ZoneGoal Engine.
  function TASK_ZONE_GOAL:SetProtect( ZoneGoal )
  
    self.ZoneGoal = ZoneGoal -- Functional.ZoneGoal#ZONE_GOAL
  end
   

  
  --- @param #TASK_ZONE_GOAL self
  function TASK_ZONE_GOAL:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.ZoneGoal:GetZoneName() .. " )"
  end

  
  --- @param #TASK_ZONE_GOAL self
  -- @param Core.Zone#ZONE_BASE TargetZone The Zone object where the Target is located on the map.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_ZONE_GOAL:SetTargetZone( TargetZone, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteZone = ProcessUnit:GetProcess( "Monitoring", "RouteToZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteZone:SetZone( TargetZone )
  end
   

  --- @param #TASK_ZONE_GOAL self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Zone#ZONE_BASE The Zone object where the Target is located on the map.
  function TASK_ZONE_GOAL:GetTargetZone( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteZone = ProcessUnit:GetProcess( "Monitoring", "RouteToZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteZone:GetZone()
  end

  function TASK_ZONE_GOAL:SetGoalTotal( GoalTotal )
  
    self.GoalTotal = GoalTotal
  end

  function TASK_ZONE_GOAL:GetGoalTotal()
  
    return self.GoalTotal
  end

end 


do -- TASK_CAPTURE_ZONE

  --- The TASK_CAPTURE_ZONE class
  -- @type TASK_CAPTURE_ZONE
  -- @field Functional.ZoneGoalCoalition#ZONE_GOAL_COALITION ZoneGoal
  -- @extends #TASK_ZONE_GOAL

  --- # TASK_CAPTURE_ZONE class, extends @{Tasking.Task_Capture_Zone#TASK_ZONE_GOAL}
  -- 
  -- The TASK_CAPTURE_ZONE class defines an Suppression or Extermination of Air Defenses task for a human player to be executed.
  -- These tasks are important to be executed as they will help to achieve air superiority at the vicinity.
  -- 
  -- The TASK_CAPTURE_ZONE is used by the @{Tasking.Task_A2G_Dispatcher#TASK_A2G_DISPATCHER} to automatically create SEAD tasks 
  -- based on detected enemy ground targets.
  -- 
  -- @field #TASK_CAPTURE_ZONE
  TASK_CAPTURE_ZONE = {
    ClassName = "TASK_CAPTURE_ZONE",
  }
  

  --- Instantiates a new TASK_CAPTURE_ZONE.
  -- @param #TASK_CAPTURE_ZONE self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Functional.ZoneGoalCoalition#ZONE_GOAL_COALITION ZoneGoalCoalition
  -- @param #string TaskBriefing The briefing of the task.
  -- @return #TASK_CAPTURE_ZONE self
  function TASK_CAPTURE_ZONE:New( Mission, SetGroup, TaskName, ZoneGoalCoalition, TaskBriefing)
    local self = BASE:Inherit( self, TASK_ZONE_GOAL:New( Mission, SetGroup, TaskName, ZoneGoalCoalition, "CAPTURE", TaskBriefing ) ) -- #TASK_CAPTURE_ZONE
    self:F()
    
    Mission:AddTask( self )
    
    self.TaskCoalition = ZoneGoalCoalition:GetCoalition()
    self.TaskCoalitionName = ZoneGoalCoalition:GetCoalitionName()
    self.TaskZoneName = ZoneGoalCoalition:GetZoneName()
    
    ZoneGoalCoalition:MonitorDestroyedUnits()
    
    self:SetBriefing( 
      TaskBriefing or 
      "Capture Zone " .. self.TaskZoneName
    )
    
    self:UpdateTaskInfo( true )
    
    self:SetGoal( self.ZoneGoal.Goal )

    return self
  end 


  --- Instantiates a new TASK_CAPTURE_ZONE.
  -- @param #TASK_CAPTURE_ZONE self
  function TASK_CAPTURE_ZONE:UpdateTaskInfo( Persist ) 
  
    Persist = Persist or false
  
    local ZoneCoordinate = self.ZoneGoal:GetZone():GetCoordinate() 
    self.TaskInfo:AddTaskName( 0, "MSOD", Persist )
    self.TaskInfo:AddCoordinate( ZoneCoordinate, 1, "SOD", Persist )
--    self.TaskInfo:AddText( "Zone Name", self.ZoneGoal:GetZoneName(), 10, "MOD", Persist )
--    self.TaskInfo:AddText( "Zone Coalition", self.ZoneGoal:GetCoalitionName(), 11, "MOD", Persist )
    local SetUnit = self.ZoneGoal:GetScannedSetUnit()
    local ThreatLevel, ThreatText = SetUnit:CalculateThreatLevelA2G()
    local ThreatCount = SetUnit:Count()
    self.TaskInfo:AddThreat( ThreatText, ThreatLevel, 20, "MOD", Persist )
    self.TaskInfo:AddInfo( "Remaining Units", ThreatCount, 21, "MOD", Persist, true)
    
    if self.Dispatcher then
      local DefenseTaskCaptureDispatcher = self.Dispatcher:GetDefenseTaskCaptureDispatcher() -- Tasking.Task_Capture_Dispatcher#TASK_CAPTURE_DISPATCHER
      
      if DefenseTaskCaptureDispatcher then
        -- Loop through all zones of the player Defenses, and check which zone has an assigned task!
        -- The Zones collection contains a Task. This Task is checked if it is assigned.
        -- If Assigned, then this task will be the task that is the closest to the defense zone.
        for TaskName, CaptureZone in pairs( DefenseTaskCaptureDispatcher.Zones or {} ) do
          local Task = CaptureZone.Task -- Tasking.Task_Capture_Zone#TASK_CAPTURE_ZONE
          if Task  and Task:IsStateAssigned() then -- We also check assigned.
            -- Now we register the defense player zone information to the task report.
            self.TaskInfo:AddInfo( "Defense Player Zone", Task.ZoneGoal:GetName(), 30, "MOD", Persist ) 
            self.TaskInfo:AddCoordinate( Task.ZoneGoal:GetZone():GetCoordinate(), 31, "MOD", Persist, false, "Defense Player Coordinate" )
          end
        end
      end
      local DefenseAIA2GDispatcher = self.Dispatcher:GetDefenseAIA2GDispatcher() -- AI.AI_A2G_Dispatcher#AI_A2G_DISPATCHER
      
      if DefenseAIA2GDispatcher then
        -- Loop through all the tasks of the AI Defenses, and check which zone is involved in the defenses and is active!
        for Defender, Task in pairs( DefenseAIA2GDispatcher:GetDefenderTasks() or {} ) do
          local DetectedItem = DefenseAIA2GDispatcher:GetDefenderTaskTarget( Defender )
          if DetectedItem then
            local DetectedZone = DefenseAIA2GDispatcher.Detection:GetDetectedItemZone( DetectedItem )
            if DetectedZone then
              self.TaskInfo:AddInfo( "Defense AI Zone", DetectedZone:GetName(), 40, "MOD", Persist  )
              self.TaskInfo:AddCoordinate( DetectedZone:GetCoordinate(), 41, "MOD", Persist, false, "Defense AI Coordinate" )
            end
          end
        end
      end
    end
    
  end
    

  function TASK_CAPTURE_ZONE:ReportOrder( ReportGroup ) 

    local Coordinate = self.TaskInfo:GetCoordinate()
    local Distance = ReportGroup:GetCoordinate():Get2DDistance( Coordinate )
    
    return Distance
  end
  
  
  --- @param #TASK_CAPTURE_ZONE self
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_CAPTURE_ZONE:OnAfterGoal( From, Event, To, PlayerUnit, PlayerName )
  
    self:F( { PlayerUnit = PlayerUnit, Achieved = self.ZoneGoal.Goal:IsAchieved() } )
    
    if self.ZoneGoal then
      if self.ZoneGoal.Goal:IsAchieved() then
        local TotalContributions = self.ZoneGoal.Goal:GetTotalContributions()
        local PlayerContributions = self.ZoneGoal.Goal:GetPlayerContributions()
        self:F( { TotalContributions = TotalContributions, PlayerContributions = PlayerContributions } )
        for PlayerName, PlayerContribution in pairs( PlayerContributions ) do
           local Scoring = self:GetScoring()
           if Scoring then
             Scoring:_AddMissionGoalScore( self.Mission, PlayerName, "Zone " .. self.ZoneGoal:GetZoneName() .." captured", PlayerContribution * 200 / TotalContributions )
           end
        end
        self:Success()
      end
    end
    
    self:__Goal( -10, PlayerUnit, PlayerName )
  end

  --- This function is called from the @{Tasking.CommandCenter#COMMANDCENTER} to determine the method of automatic task selection.
  -- @param #TASK_CAPTURE_ZONE self
  -- @param #number AutoAssignMethod The method to be applied to the task.
  -- @param Tasking.CommandCenter#COMMANDCENTER CommandCenter The command center.
  -- @param Wrapper.Group#GROUP TaskGroup The player group.
  function TASK_CAPTURE_ZONE:GetAutoAssignPriority( AutoAssignMethod, CommandCenter, TaskGroup, AutoAssignReference )
  
    if     AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Random then
      return math.random( 1, 9 )
    elseif AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Distance then
      local Coordinate = self.TaskInfo:GetCoordinate()
      local Distance = Coordinate:Get2DDistance( CommandCenter:GetPositionable():GetCoordinate() )
      return math.floor( Distance )
    elseif AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Priority then
      return 1
    end

    return 0
  end

end

