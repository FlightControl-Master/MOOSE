--- **Tasking** - The TASK_A2A models tasks for players in Air to Air engagements.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
--   
-- @module Tasking.Task_A2A
-- @image MOOSE.JPG

do -- TASK_A2A

  --- The TASK_A2A class
  -- @type TASK_A2A
  -- @field Core.Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- Defines Air To Air tasks for a @{Set} of Target Units, 
  -- based on the tasking capabilities defined in @{Tasking.Task#TASK}.
  -- The TASK_A2A is implemented using a @{Core.Fsm#FSM_TASK}, and has the following statuses:
  -- 
  --   * **None**: Start of the process
  --   * **Planned**: The A2A task is planned.
  --   * **Assigned**: The A2A task is assigned to a @{Wrapper.Group#GROUP}.
  --   * **Success**: The A2A task is successfully completed.
  --   * **Failed**: The A2A task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
  -- 
  -- # 1) Set the scoring of achievements in an A2A attack.
  -- 
  -- Scoring or penalties can be given in the following circumstances:
  -- 
  --   * @{#TASK_A2A.SetScoreOnDestroy}(): Set a score when a target in scope of the A2A attack, has been destroyed.
  --   * @{#TASK_A2A.SetScoreOnSuccess}(): Set a score when all the targets in scope of the A2A attack, have been destroyed.
  --   * @{#TASK_A2A.SetPenaltyOnFailed}(): Set a penalty when the A2A attack has failed.
  -- 
  -- @field #TASK_A2A
  TASK_A2A = {
    ClassName = "TASK_A2A",
  }
  
  --- Instantiates a new TASK_A2A.
  -- @param #TASK_A2A self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetAttack The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_UNIT UnitSetTargets
  -- @param #number TargetDistance The distance to Target when the Player is considered to have "arrived" at the engagement range.
  -- @param Core.Zone#ZONE_BASE TargetZone The target zone, if known.
  -- If the TargetZone parameter is specified, the player will be routed to the center of the zone where all the targets are assumed to be.
  -- @return #TASK_A2A self
  function TASK_A2A:New( Mission, SetAttack, TaskName, TargetSetUnit, TaskType, TaskBriefing )
    local self = BASE:Inherit( self, TASK:New( Mission, SetAttack, TaskName, TaskType, TaskBriefing ) ) -- Tasking.Task#TASK_A2A
    self:F()
  
    self.TargetSetUnit = TargetSetUnit
    self.TaskType = TaskType

    local Fsm = self:GetUnitProcess()
    

    Fsm:AddTransition( "Assigned", "RouteToRendezVous", "RoutingToRendezVous" )
    Fsm:AddProcess   ( "RoutingToRendezVous", "RouteToRendezVousPoint", ACT_ROUTE_POINT:New(), { Arrived = "ArriveAtRendezVous" } )
    Fsm:AddProcess   ( "RoutingToRendezVous", "RouteToRendezVousZone", ACT_ROUTE_ZONE:New(), { Arrived = "ArriveAtRendezVous" } )
    
    Fsm:AddTransition( { "Arrived", "RoutingToRendezVous" }, "ArriveAtRendezVous", "ArrivedAtRendezVous" )
    
    Fsm:AddTransition( { "ArrivedAtRendezVous", "HoldingAtRendezVous" }, "Engage", "Engaging" )
    Fsm:AddTransition( { "ArrivedAtRendezVous", "HoldingAtRendezVous" }, "HoldAtRendezVous", "HoldingAtRendezVous" )
     
    Fsm:AddProcess   ( "Engaging", "Account", ACT_ACCOUNT_DEADS:New(), {} )
    Fsm:AddTransition( "Engaging", "RouteToTarget", "Engaging" )
    Fsm:AddProcess( "Engaging", "RouteToTargetZone", ACT_ROUTE_ZONE:New(), {} )
    Fsm:AddProcess( "Engaging", "RouteToTargetPoint", ACT_ROUTE_POINT:New(), {} )
    Fsm:AddTransition( "Engaging", "RouteToTargets", "Engaging" )
    
--    Fsm:AddTransition( "Accounted", "DestroyedAll", "Accounted" )
--    Fsm:AddTransition( "Accounted", "Success", "Success" )
    Fsm:AddTransition( "Rejected", "Reject", "Aborted" )
    Fsm:AddTransition( "Failed", "Fail", "Failed" )
    

    ---- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param #TASK_CARGO Task
    function Fsm:OnLeaveAssigned( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      self:SelectAction()
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2A#TASK_A2A Task
    function Fsm:onafterRouteToRendezVous( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.RendezVousSetUnit
      
      if Task:GetRendezVousZone( TaskUnit ) then
        self:__RouteToRendezVousZone( 0.1 )
      else
        if Task:GetRendezVousCoordinate( TaskUnit ) then
          self:__RouteToRendezVousPoint( 0.1 )
        else
          self:__ArriveAtRendezVous( 0.1 )
        end
      end
    end

    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_A2A Task
    function Fsm:OnAfterArriveAtRendezVous( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      self:__Engage( 0.1 )      
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_A2A Task
    function Fsm:onafterEngage( TaskUnit, Task )
      self:F( { self } )
      self:__Account( 0.1 )
      self:__RouteToTarget(0.1 )
      self:__RouteToTargets( -10 )
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2A#TASK_A2A Task
    function Fsm:onafterRouteToTarget( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      if Task:GetTargetZone( TaskUnit ) then
        self:__RouteToTargetZone( 0.1 )
      else
        local TargetUnit = Task.TargetSetUnit:GetFirst() -- Wrapper.Unit#UNIT
        if TargetUnit then
          local Coordinate = TargetUnit:GetPointVec3()
          self:T( { TargetCoordinate = Coordinate, Coordinate:GetX(), Coordinate:GetAlt(), Coordinate:GetZ() } )
          Task:SetTargetCoordinate( Coordinate, TaskUnit )
        end
        self:__RouteToTargetPoint( 0.1 )
      end
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2A#TASK_A2A Task
    function Fsm:onafterRouteToTargets( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      local TargetUnit = Task.TargetSetUnit:GetFirst() -- Wrapper.Unit#UNIT
      if TargetUnit then
        Task:SetTargetCoordinate( TargetUnit:GetCoordinate(), TaskUnit )
      end
      self:__RouteToTargets( -10 )
    end
    
    return self
 
  end
  
  --- @param #TASK_A2A self
  -- @param Core.Set#SET_UNIT TargetSetUnit The set of targets.
  function TASK_A2A:SetTargetSetUnit( TargetSetUnit )
  
    self.TargetSetUnit = TargetSetUnit
  end
   

  
  --- @param #TASK_A2A self
  function TASK_A2A:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.TargetSetUnit:GetUnitTypesText() .. " )"
  end

  --- @param #TASK_A2A self
  -- @param Core.Point#COORDINATE RendezVousCoordinate The Coordinate object referencing to the 2D point where the RendezVous point is located on the map.
  -- @param #number RendezVousRange The RendezVousRange that defines when the player is considered to have arrived at the RendezVous point.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_A2A:SetRendezVousCoordinate( RendezVousCoordinate, RendezVousRange, TaskUnit  )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )
  
    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteRendezVous:SetCoordinate( RendezVousCoordinate )
    ActRouteRendezVous:SetRange( RendezVousRange )
  end
  
  --- @param #TASK_A2A self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Point#COORDINATE The Coordinate object referencing to the 2D point where the RendezVous point is located on the map.
  -- @return #number The RendezVousRange that defines when the player is considered to have arrived at the RendezVous point.
  function TASK_A2A:GetRendezVousCoordinate( TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    return ActRouteRendezVous:GetCoordinate(), ActRouteRendezVous:GetRange()
  end
  
  
  
  --- @param #TASK_A2A self
  -- @param Core.Zone#ZONE_BASE RendezVousZone The Zone object where the RendezVous is located on the map.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_A2A:SetRendezVousZone( RendezVousZone, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteRendezVous:SetZone( RendezVousZone )
  end

  --- @param #TASK_A2A self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Zone#ZONE_BASE The Zone object where the RendezVous is located on the map.
  function TASK_A2A:GetRendezVousZone( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteRendezVous:GetZone()
  end
  
  --- @param #TASK_A2A self
  -- @param Core.Point#COORDINATE TargetCoordinate The Coordinate object where the Target is located on the map.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_A2A:SetTargetCoordinate( TargetCoordinate, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteTarget:SetCoordinate( TargetCoordinate )
  end
   

  --- @param #TASK_A2A self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Point#COORDINATE The Coordinate object where the Target is located on the map.
  function TASK_A2A:GetTargetCoordinate( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    return ActRouteTarget:GetCoordinate()
  end


  --- @param #TASK_A2A self
  -- @param Core.Zone#ZONE_BASE TargetZone The Zone object where the Target is located on the map.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_A2A:SetTargetZone( TargetZone, Altitude, Heading, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteTarget:SetZone( TargetZone, Altitude, Heading )
  end
   

  --- @param #TASK_A2A self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Zone#ZONE_BASE The Zone object where the Target is located on the map.
  function TASK_A2A:GetTargetZone( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteTarget:GetZone()
  end

  function TASK_A2A:SetGoalTotal()
  
    self.GoalTotal = self.TargetSetUnit:Count()
  end

  function TASK_A2A:GetGoalTotal()
  
    return self.GoalTotal
  end

  --- Return the relative distance to the target vicinity from the player, in order to sort the targets in the reports per distance from the threats.
  -- @param #TASK_A2A self
  function TASK_A2A:ReportOrder( ReportGroup )
	self:UpdateTaskInfo( self.DetectedItem )
  
    local Coordinate = self.TaskInfo:GetData( "Coordinate" )
    local Distance = ReportGroup:GetCoordinate():Get2DDistance( Coordinate )
    
    return Distance
  end
  
  
  --- This method checks every 10 seconds if the goal has been reached of the task.
  -- @param #TASK_A2A self
  function TASK_A2A:onafterGoal( TaskUnit, From, Event, To )
    local TargetSetUnit = self.TargetSetUnit -- Core.Set#SET_UNIT
    
    if TargetSetUnit:Count() == 0 then
      self:Success()
    end
    
    self:__Goal( -10 )
  end


  --- @param #TASK_A2A self
  function TASK_A2A:UpdateTaskInfo( DetectedItem )

    if self:IsStatePlanned() or self:IsStateAssigned() then
      local TargetCoordinate = DetectedItem and self.Detection:GetDetectedItemCoordinate( DetectedItem ) or self.TargetSetUnit:GetFirst():GetCoordinate() 
      self.TaskInfo:AddTaskName( 0, "MSOD" )
      self.TaskInfo:AddCoordinate( TargetCoordinate, 1, "SOD" )

      local ThreatLevel, ThreatText
      if DetectedItem then
        ThreatLevel, ThreatText = self.Detection:GetDetectedItemThreatLevel( DetectedItem )
      else
        ThreatLevel, ThreatText = self.TargetSetUnit:CalculateThreatLevelA2G()
      end
      self.TaskInfo:AddThreat( ThreatText, ThreatLevel, 10, "MOD", true )

      if self.Detection then
        local DetectedItemsCount = self.TargetSetUnit:Count()
        local ReportTypes = REPORT:New()
        local TargetTypes = {}
        for TargetUnitName, TargetUnit in pairs( self.TargetSetUnit:GetSet() ) do
          local TargetType = self.Detection:GetDetectedUnitTypeName( TargetUnit )
          if not TargetTypes[TargetType] then
            TargetTypes[TargetType] = TargetType
            ReportTypes:Add( TargetType )
          end
        end
        self.TaskInfo:AddTargetCount( DetectedItemsCount, 11, "O", true )
        self.TaskInfo:AddTargets( DetectedItemsCount, ReportTypes:Text( ", " ), 20, "D", true ) 
      else
        local DetectedItemsCount = self.TargetSetUnit:Count()
        local DetectedItemsTypes = self.TargetSetUnit:GetTypeNames()
        self.TaskInfo:AddTargetCount( DetectedItemsCount, 11, "O", true )
        self.TaskInfo:AddTargets( DetectedItemsCount, DetectedItemsTypes, 20, "D", true ) 
      end
    end
  end

  --- This function is called from the @{Tasking.CommandCenter#COMMANDCENTER} to determine the method of automatic task selection.
  -- @param #TASK_A2A self
  -- @param #number AutoAssignMethod The method to be applied to the task.
  -- @param Tasking.CommandCenter#COMMANDCENTER CommandCenter The command center.
  -- @param Wrapper.Group#GROUP TaskGroup The player group.
  function TASK_A2A:GetAutoAssignPriority( AutoAssignMethod, CommandCenter, TaskGroup )
  
    if     AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Random then
      return math.random( 1, 9 )
    elseif AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Distance then
      local Coordinate = self.TaskInfo:GetData( "Coordinate" )
      local Distance = Coordinate:Get2DDistance( CommandCenter:GetPositionable():GetCoordinate() )
      return math.floor( Distance )
    elseif AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Priority then
      return 1
    end

    return 0
  end

end 


do -- TASK_A2A_INTERCEPT

  --- The TASK_A2A_INTERCEPT class
  -- @type TASK_A2A_INTERCEPT
  -- @field Core.Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- Defines an intercept task for a human player to be executed.
  -- When enemy planes need to be intercepted by human players, use this task type to urgen the players to get out there!
  -- 
  -- The TASK_A2A_INTERCEPT is used by the @{Tasking.Task_A2A_Dispatcher#TASK_A2A_DISPATCHER} to automatically create intercept tasks 
  -- based on detected airborne enemy targets intruding friendly airspace.
  -- 
  -- The task is defined for a @{Tasking.Mission#MISSION}, where a friendly @{Core.Set#SET_GROUP} consisting of GROUPs with one human players each, is intercepting the targets.
  -- The task is given a name and a briefing, that is used in the menu structure and in the reporting.
  -- 
  -- @field #TASK_A2A_INTERCEPT
  TASK_A2A_INTERCEPT = {
    ClassName = "TASK_A2A_INTERCEPT",
  }



  --- Instantiates a new TASK_A2A_INTERCEPT.
  -- @param #TASK_A2A_INTERCEPT self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_UNIT TargetSetUnit 
  -- @param #string TaskBriefing The briefing of the task.
  -- @return #TASK_A2A_INTERCEPT
  function TASK_A2A_INTERCEPT:New( Mission, SetGroup, TaskName, TargetSetUnit, TaskBriefing )
    local self = BASE:Inherit( self, TASK_A2A:New( Mission, SetGroup, TaskName, TargetSetUnit, "INTERCEPT", TaskBriefing ) ) -- #TASK_A2A_INTERCEPT
    self:F()
    
    Mission:AddTask( self )
    
    self:SetBriefing( 
      TaskBriefing or 
      "Intercept incoming intruders.\n"
    )

    return self
  end
  
  --- Set a score when a target in scope of the A2A attack, has been destroyed .
  -- @param #TASK_A2A_INTERCEPT self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points to be granted when task process has been achieved.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A_INTERCEPT
  function TASK_A2A_INTERCEPT:SetScoreOnProgress( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "AccountForPlayer", "Player " .. PlayerName .. " has intercepted a target.", Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2A attack, have been destroyed.
  -- @param #TASK_A2A_INTERCEPT self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A_INTERCEPT
  function TASK_A2A_INTERCEPT:SetScoreOnSuccess( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", "All targets have been successfully intercepted!", Score )
    
    return self
  end

  --- Set a penalty when the A2A attack has failed.
  -- @param #TASK_A2A_INTERCEPT self
  -- @param #string PlayerName The name of the player.
  -- @param #number Penalty The penalty in points, must be a negative value!
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A_INTERCEPT
  function TASK_A2A_INTERCEPT:SetScoreOnFail( PlayerName, Penalty, TaskUnit )
    self:F( { PlayerName, Penalty, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", "The intercept has failed!", Penalty )
    
    return self
  end
  

end


do -- TASK_A2A_SWEEP

  --- The TASK_A2A_SWEEP class
  -- @type TASK_A2A_SWEEP
  -- @field Core.Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- Defines a sweep task for a human player to be executed.
  -- A sweep task needs to be given when targets were detected but somehow the detection was lost.
  -- Most likely, these enemy planes are hidden in the mountains or are flying under radar.
  -- These enemy planes need to be sweeped by human players, and use this task type to urge the players to get out there and find those enemy fighters.
  -- 
  -- The TASK_A2A_SWEEP is used by the @{Tasking.Task_A2A_Dispatcher#TASK_A2A_DISPATCHER} to automatically create sweep tasks 
  -- based on detected airborne enemy targets intruding friendly airspace, for which the detection has been lost for more than 60 seconds.
  -- 
  -- The task is defined for a @{Tasking.Mission#MISSION}, where a friendly @{Core.Set#SET_GROUP} consisting of GROUPs with one human players each, is sweeping the targets.
  -- The task is given a name and a briefing, that is used in the menu structure and in the reporting.
  -- 
  -- @field #TASK_A2A_SWEEP
  TASK_A2A_SWEEP = {
    ClassName = "TASK_A2A_SWEEP",
  }



  --- Instantiates a new TASK_A2A_SWEEP.
  -- @param #TASK_A2A_SWEEP self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_UNIT TargetSetUnit 
  -- @param #string TaskBriefing The briefing of the task.
  -- @return #TASK_A2A_SWEEP self
  function TASK_A2A_SWEEP:New( Mission, SetGroup, TaskName, TargetSetUnit, TaskBriefing )
    local self = BASE:Inherit( self, TASK_A2A:New( Mission, SetGroup, TaskName, TargetSetUnit, "SWEEP", TaskBriefing ) ) -- #TASK_A2A_SWEEP
    self:F()
    
    Mission:AddTask( self )
    
    self:SetBriefing( 
      TaskBriefing or 
      "Perform a fighter sweep. Incoming intruders were detected and could be hiding at the location.\n"
    )

    return self
  end 

  --- @param #TASK_A2A_SWEEP self
  function TASK_A2A_SWEEP:onafterGoal( TaskUnit, From, Event, To )
    local TargetSetUnit = self.TargetSetUnit -- Core.Set#SET_UNIT
    
    if TargetSetUnit:Count() == 0 then
      self:Success()
    end
    
    self:__Goal( -10 )
  end

  --- Set a score when a target in scope of the A2A attack, has been destroyed .
  -- @param #TASK_A2A_SWEEP self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points to be granted when task process has been achieved.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A_SWEEP
  function TASK_A2A_SWEEP:SetScoreOnProgress( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "AccountForPlayer", "Player " .. PlayerName .. " has sweeped a target.", Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2A attack, have been destroyed.
  -- @param #TASK_A2A_SWEEP self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A_SWEEP
  function TASK_A2A_SWEEP:SetScoreOnSuccess( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", "All targets have been successfully sweeped!", Score )
    
    return self
  end

  --- Set a penalty when the A2A attack has failed.
  -- @param #TASK_A2A_SWEEP self
  -- @param #string PlayerName The name of the player.
  -- @param #number Penalty The penalty in points, must be a negative value!
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A_SWEEP
  function TASK_A2A_SWEEP:SetScoreOnFail( PlayerName, Penalty, TaskUnit )
    self:F( { PlayerName, Penalty, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", "The sweep has failed!", Penalty )
    
    return self
  end

end


do -- TASK_A2A_ENGAGE

  --- The TASK_A2A_ENGAGE class
  -- @type TASK_A2A_ENGAGE
  -- @field Core.Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- Defines an engage task for a human player to be executed.
  -- When enemy planes are close to human players, use this task type is used urge the players to get out there!
  -- 
  -- The TASK_A2A_ENGAGE is used by the @{Tasking.Task_A2A_Dispatcher#TASK_A2A_DISPATCHER} to automatically create engage tasks 
  -- based on detected airborne enemy targets intruding friendly airspace.
  -- 
  -- The task is defined for a @{Tasking.Mission#MISSION}, where a friendly @{Core.Set#SET_GROUP} consisting of GROUPs with one human players each, is engaging the targets.
  -- The task is given a name and a briefing, that is used in the menu structure and in the reporting.
  -- 
  -- @field #TASK_A2A_ENGAGE
  TASK_A2A_ENGAGE = {
    ClassName = "TASK_A2A_ENGAGE",
  }



  --- Instantiates a new TASK_A2A_ENGAGE.
  -- @param #TASK_A2A_ENGAGE self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_UNIT TargetSetUnit 
  -- @param #string TaskBriefing The briefing of the task.
  -- @return #TASK_A2A_ENGAGE self
  function TASK_A2A_ENGAGE:New( Mission, SetGroup, TaskName, TargetSetUnit, TaskBriefing )
    local self = BASE:Inherit( self, TASK_A2A:New( Mission, SetGroup, TaskName, TargetSetUnit, "ENGAGE", TaskBriefing ) ) -- #TASK_A2A_ENGAGE
    self:F()
    
    Mission:AddTask( self )
    
    self:SetBriefing( 
      TaskBriefing or 
      "Bogeys are nearby! Players close by are ordered to ENGAGE the intruders!\n"
    )

    return self
  end 
  
  --- Set a score when a target in scope of the A2A attack, has been destroyed .
  -- @param #TASK_A2A_ENGAGE self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points to be granted when task process has been achieved.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A_ENGAGE
  function TASK_A2A_ENGAGE:SetScoreOnProgress( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "AccountForPlayer", "Player " .. PlayerName .. " has engaged and destroyed a target.", Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2A attack, have been destroyed.
  -- @param #TASK_A2A_ENGAGE self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A_ENGAGE
  function TASK_A2A_ENGAGE:SetScoreOnSuccess( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", "All targets have been successfully engaged!", Score )
    
    return self
  end

  --- Set a penalty when the A2A attack has failed.
  -- @param #TASK_A2A_ENGAGE self
  -- @param #string PlayerName The name of the player.
  -- @param #number Penalty The penalty in points, must be a negative value!
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A_ENGAGE
  function TASK_A2A_ENGAGE:SetScoreOnFail( PlayerName, Penalty, TaskUnit )
    self:F( { PlayerName, Penalty, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", "The target engagement has failed!", Penalty )
    
    return self
  end

end

