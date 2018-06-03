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
-- @module Tasking.TaskZoneCapture
-- @image MOOSE.JPG

do -- TASK_ZONE_GOAL

  --- The TASK_ZONE_GOAL class
  -- @type TASK_ZONE_GOAL
  -- @field Core.ZoneGoal#ZONE_GOAL ZoneGoal
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
  -- @param Core.ZoneGoal#ZONE_GOAL ZoneGoal
  -- @return #TASK_ZONE_GOAL self
  function TASK_ZONE_GOAL:New( Mission, SetGroup, TaskName, ZoneGoal, TaskType, TaskBriefing )
    local self = BASE:Inherit( self, TASK:New( Mission, SetGroup, TaskName, TaskType, TaskBriefing ) ) -- #TASK_ZONE_GOAL
    self:F()
  
    self.ZoneGoal = ZoneGoal
    self.TaskType = TaskType
    
    local Fsm = self:GetUnitProcess()
    

    Fsm:AddProcess   ( "Planned", "Accept", ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "StartMonitoring", Rejected = "Reject" }  )
    
    Fsm:AddTransition( "Assigned", "StartMonitoring", "Monitoring" )
    Fsm:AddTransition( "Monitoring", "Monitor", "Monitoring", {} )
    Fsm:AddTransition( "Monitoring", "RouteTo", "Monitoring" )
    Fsm:AddProcess( "Monitoring", "RouteToZone", ACT_ROUTE_ZONE:New(), {} )
    
    --Fsm:AddTransition( "Accounted", "DestroyedAll", "Accounted" )
    --Fsm:AddTransition( "Accounted", "Success", "Success" )
    Fsm:AddTransition( "Rejected", "Reject", "Aborted" )
    Fsm:AddTransition( "Failed", "Fail", "Failed" )
    
    self:SetTargetZone( self.ZoneGoal:GetZone() )
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_ZONE_GOAL Task
    function Fsm:onafterStartMonitoring( TaskUnit, Task )
      self:F( { self } )
      self:__Monitor( 0.1 )
      self:__RouteTo( 0.1 )
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
        self:__RouteTo( 0.1 )
      end
    end

    return self
 
  end

  --- @param #TASK_ZONE_GOAL self
  -- @param Core.ZoneGoal#ZONE_GOAL ZoneGoal The ZoneGoal Engine.
  function TASK_ZONE_GOAL:SetProtect( ZoneGoal )
  
    self.ZoneGoal = ZoneGoal -- Core.ZoneGoal#ZONE_GOAL
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


do -- TASK_ZONE_CAPTURE

  --- The TASK_ZONE_CAPTURE class
  -- @type TASK_ZONE_CAPTURE
  -- @field Core.ZoneGoalCoalition#ZONE_GOAL_COALITION ZoneGoal
  -- @extends #TASK_ZONE_GOAL

  --- # TASK_ZONE_CAPTURE class, extends @{Tasking.TaskZoneGoal#TASK_ZONE_GOAL}
  -- 
  -- The TASK_ZONE_CAPTURE class defines an Suppression or Extermination of Air Defenses task for a human player to be executed.
  -- These tasks are important to be executed as they will help to achieve air superiority at the vicinity.
  -- 
  -- The TASK_ZONE_CAPTURE is used by the @{Tasking.Task_A2G_Dispatcher#TASK_A2G_DISPATCHER} to automatically create SEAD tasks 
  -- based on detected enemy ground targets.
  -- 
  -- @field #TASK_ZONE_CAPTURE
  TASK_ZONE_CAPTURE = {
    ClassName = "TASK_ZONE_CAPTURE",
  }
  

  --- Instantiates a new TASK_ZONE_CAPTURE.
  -- @param #TASK_ZONE_CAPTURE self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.ZoneGoalCoalition#ZONE_GOAL_COALITION ZoneGoalCoalition
  -- @param #string TaskBriefing The briefing of the task.
  -- @return #TASK_ZONE_CAPTURE self
  function TASK_ZONE_CAPTURE:New( Mission, SetGroup, TaskName, ZoneGoalCoalition, TaskBriefing)
    local self = BASE:Inherit( self, TASK_ZONE_GOAL:New( Mission, SetGroup, TaskName, ZoneGoalCoalition, "CAPTURE", TaskBriefing ) ) -- #TASK_ZONE_CAPTURE
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
    
    self:UpdateTaskInfo()

    return self
  end 


  --- Instantiates a new TASK_ZONE_CAPTURE.
  -- @param #TASK_ZONE_CAPTURE self
  function TASK_ZONE_CAPTURE:UpdateTaskInfo() 


    local ZoneCoordinate = self.ZoneGoal:GetZone():GetCoordinate() 
    self.TaskInfo:AddCoordinate( ZoneCoordinate, 0, "SOD" )
    self.TaskInfo:AddText( "Zone Name", self.ZoneGoal:GetZoneName(), 10, "MOD" )
    self.TaskInfo:AddText( "Zone Coalition", self.ZoneGoal:GetCoalitionName(), 11, "MOD" )
  end
    

  function TASK_ZONE_CAPTURE:ReportOrder( ReportGroup ) 
    local Coordinate = self:GetData( "Coordinate" )
    --local Coordinate = self.TaskInfo.Coordinates.TaskInfoText
    local Distance = ReportGroup:GetCoordinate():Get2DDistance( Coordinate )
    
    return Distance
  end
  
  
  --- @param #TASK_ZONE_CAPTURE self
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_ZONE_CAPTURE:OnAfterGoal( From, Event, To, PlayerUnit, PlayerName )
  
    self:F( { PlayerUnit = PlayerUnit } )
    
    if self.ZoneGoal then
      if self.ZoneGoal.Goal:IsAchieved() then
        self:Success()
        local TotalContributions = self.ZoneGoal.Goal:GetTotalContributions()
        local PlayerContributions = self.ZoneGoal.Goal:GetPlayerContributions()
        self:F( { TotalContributions = TotalContributions, PlayerContributions = PlayerContributions } )
        for PlayerName, PlayerContribution in pairs( PlayerContributions ) do
           local Scoring = self:GetScoring()
           if Scoring then
             Scoring:_AddMissionGoalScore( self.Mission, PlayerName, "Zone " .. self.ZoneGoal:GetZoneName() .." captured", PlayerContribution * 200 / TotalContributions )
           end
        end
      end
    end
    
    self:__Goal( -10, PlayerUnit, PlayerName )
  end

end

