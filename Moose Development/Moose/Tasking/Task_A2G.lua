--- **Tasking** - The TASK_A2G models tasks for players in Air to Ground engagements.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
--   
-- @module Tasking.Task_A2G
-- @image MOOSE.JPG

do -- TASK_A2G

  --- The TASK_A2G class
  -- @type TASK_A2G
  -- @field Core.Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- The TASK_A2G class defines Air To Ground tasks for a @{Set} of Target Units, 
  -- based on the tasking capabilities defined in @{Tasking.Task#TASK}.
  -- The TASK_A2G is implemented using a @{Core.Fsm#FSM_TASK}, and has the following statuses:
  -- 
  --   * **None**: Start of the process
  --   * **Planned**: The A2G task is planned.
  --   * **Assigned**: The A2G task is assigned to a @{Wrapper.Group#GROUP}.
  --   * **Success**: The A2G task is successfully completed.
  --   * **Failed**: The A2G task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
  -- 
  -- ## 1) Set the scoring of achievements in an A2G attack.
  -- 
  -- Scoring or penalties can be given in the following circumstances:
  -- 
  --   * @{#TASK_A2G.SetScoreOnDestroy}(): Set a score when a target in scope of the A2G attack, has been destroyed.
  --   * @{#TASK_A2G.SetScoreOnSuccess}(): Set a score when all the targets in scope of the A2G attack, have been destroyed.
  --   * @{#TASK_A2G.SetPenaltyOnFailed}(): Set a penalty when the A2G attack has failed.
  -- 
  -- @field #TASK_A2G
  TASK_A2G = {
    ClassName = "TASK_A2G",
  }
  
  --- Instantiates a new TASK_A2G.
  -- @param #TASK_A2G self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_UNIT UnitSetTargets
  -- @param #number TargetDistance The distance to Target when the Player is considered to have "arrived" at the engagement range.
  -- @param Core.Zone#ZONE_BASE TargetZone The target zone, if known.
  -- If the TargetZone parameter is specified, the player will be routed to the center of the zone where all the targets are assumed to be.
  -- @return #TASK_A2G self
  function TASK_A2G:New( Mission, SetGroup, TaskName, TargetSetUnit, TaskType, TaskBriefing )
    local self = BASE:Inherit( self, TASK:New( Mission, SetGroup, TaskName, TaskType, TaskBriefing ) ) -- Tasking.Task#TASK_A2G
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
    
    --Fsm:AddTransition( "Accounted", "DestroyedAll", "Accounted" )
    --Fsm:AddTransition( "Accounted", "Success", "Success" )
    Fsm:AddTransition( "Rejected", "Reject", "Aborted" )
    Fsm:AddTransition( "Failed", "Fail", "Failed" )
    


    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2G#TASK_A2G Task
    function Fsm:onafterAssigned( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.RendezVousSetUnit
      
      self:RouteToRendezVous()
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2G#TASK_A2G Task
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
    -- @param Tasking.Task#TASK_A2G Task
    function Fsm:OnAfterArriveAtRendezVous( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      self:__Engage( 0.1 )      
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_A2G Task
    function Fsm:onafterEngage( TaskUnit, Task )
      self:F( { self } )
      self:__Account( 0.1 )
      self:__RouteToTarget(0.1 )
      self:__RouteToTargets( -10 )
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2G#TASK_A2G Task
    function Fsm:onafterRouteToTarget( TaskUnit, Task )
      self:F( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      if Task:GetTargetZone( TaskUnit ) then
        self:__RouteToTargetZone( 0.1 )
      else
        local TargetUnit = Task.TargetSetUnit:GetFirst() -- Wrapper.Unit#UNIT
        if TargetUnit then
          local Coordinate = TargetUnit:GetPointVec3()
          self:T( { TargetCoordinate = Coordinate, Coordinate:GetX(), Coordinate:GetY(), Coordinate:GetZ() } )
          Task:SetTargetCoordinate( Coordinate, TaskUnit )
        end
        self:__RouteToTargetPoint( 0.1 )
      end
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2G#TASK_A2G Task
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

  --- @param #TASK_A2G self
  -- @param Core.Set#SET_UNIT TargetSetUnit The set of targets.
  function TASK_A2G:SetTargetSetUnit( TargetSetUnit )
  
    self.TargetSetUnit = TargetSetUnit
  end
   

  
  --- @param #TASK_A2G self
  function TASK_A2G:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.TargetSetUnit:GetUnitTypesText() .. " )"
  end

  --- @param #TASK_A2G self
  -- @param Core.Point#COORDINATE RendezVousCoordinate The Coordinate object referencing to the 2D point where the RendezVous point is located on the map.
  -- @param #number RendezVousRange The RendezVousRange that defines when the player is considered to have arrived at the RendezVous point.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_A2G:SetRendezVousCoordinate( RendezVousCoordinate, RendezVousRange, TaskUnit  )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )
  
    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteRendezVous:SetCoordinate( RendezVousCoordinate )
    ActRouteRendezVous:SetRange( RendezVousRange )
  end
  
  --- @param #TASK_A2G self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Point#COORDINATE The Coordinate object referencing to the 2D point where the RendezVous point is located on the map.
  -- @return #number The RendezVousRange that defines when the player is considered to have arrived at the RendezVous point.
  function TASK_A2G:GetRendezVousCoordinate( TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    return ActRouteRendezVous:GetCoordinate(), ActRouteRendezVous:GetRange()
  end
  
  
  
  --- @param #TASK_A2G self
  -- @param Core.Zone#ZONE_BASE RendezVousZone The Zone object where the RendezVous is located on the map.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_A2G:SetRendezVousZone( RendezVousZone, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteRendezVous:SetZone( RendezVousZone )
  end

  --- @param #TASK_A2G self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Zone#ZONE_BASE The Zone object where the RendezVous is located on the map.
  function TASK_A2G:GetRendezVousZone( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteRendezVous:GetZone()
  end
  
  --- @param #TASK_A2G self
  -- @param Core.Point#COORDINATE TargetCoordinate The Coordinate object where the Target is located on the map.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_A2G:SetTargetCoordinate( TargetCoordinate, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteTarget:SetCoordinate( TargetCoordinate )
  end
   

  --- @param #TASK_A2G self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Point#COORDINATE The Coordinate object where the Target is located on the map.
  function TASK_A2G:GetTargetCoordinate( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    return ActRouteTarget:GetCoordinate()
  end


  --- @param #TASK_A2G self
  -- @param Core.Zone#ZONE_BASE TargetZone The Zone object where the Target is located on the map.
  -- @param Wrapper.Unit#UNIT TaskUnit
  function TASK_A2G:SetTargetZone( TargetZone, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteTarget:SetZone( TargetZone )
  end
   

  --- @param #TASK_A2G self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Zone#ZONE_BASE The Zone object where the Target is located on the map.
  function TASK_A2G:GetTargetZone( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteTarget:GetZone()
  end

  function TASK_A2G:SetGoalTotal()
  
    self.GoalTotal = self.TargetSetUnit:Count()
  end

  function TASK_A2G:GetGoalTotal()
  
    return self.GoalTotal
  end
  
  --- Return the relative distance to the target vicinity from the player, in order to sort the targets in the reports per distance from the threats.
  -- @param #TASK_A2G self
  function TASK_A2G:ReportOrder( ReportGroup ) 
	self:UpdateTaskInfo( self.DetectedItem )
  
    local Coordinate = self.TaskInfo:GetData( "Coordinate" )
    local Distance = ReportGroup:GetCoordinate():Get2DDistance( Coordinate )
    
    return Distance
  end
  
  
  --- This method checks every 10 seconds if the goal has been reached of the task.
  -- @param #TASK_A2G self
  function TASK_A2G:onafterGoal( TaskUnit, From, Event, To )
    local TargetSetUnit = self.TargetSetUnit -- Core.Set#SET_UNIT
    
    if TargetSetUnit:Count() == 0 then
      self:Success()
    end
    
    self:__Goal( -10 )
  end

  --- @param #TASK_A2G self
  function TASK_A2G:UpdateTaskInfo( DetectedItem )
  
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
      self.TaskInfo:AddQFEAtCoordinate( TargetCoordinate, 30, "MOD" )
      self.TaskInfo:AddTemperatureAtCoordinate( TargetCoordinate, 31, "MD" )
      self.TaskInfo:AddWindAtCoordinate( TargetCoordinate, 32, "MD" )
    end
    
  end
  
  --- This function is called from the @{Tasking.CommandCenter#COMMANDCENTER} to determine the method of automatic task selection.
  -- @param #TASK_A2G self
  -- @param #number AutoAssignMethod The method to be applied to the task.
  -- @param Tasking.CommandCenter#COMMANDCENTER CommandCenter The command center.
  -- @param Wrapper.Group#GROUP TaskGroup The player group.
  function TASK_A2G:GetAutoAssignPriority( AutoAssignMethod, CommandCenter, TaskGroup )
  
    if     AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Random then
      return math.random( 1, 9 )
    elseif AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Distance then
      local Coordinate = self.TaskInfo:GetData( "Coordinate" )
      local Distance = Coordinate:Get2DDistance( CommandCenter:GetPositionable():GetCoordinate() )
      self:F({Distance=Distance})
      return math.floor( Distance )
    elseif AutoAssignMethod == COMMANDCENTER.AutoAssignMethods.Priority then
      return 1
    end

    return 0
  end

end 


do -- TASK_A2G_SEAD

  --- The TASK_A2G_SEAD class
  -- @type TASK_A2G_SEAD
  -- @field Core.Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- Defines an Suppression or Extermination of Air Defenses task for a human player to be executed.
  -- These tasks are important to be executed as they will help to achieve air superiority at the vicinity.
  -- 
  -- The TASK_A2G_SEAD is used by the @{Tasking.Task_A2G_Dispatcher#TASK_A2G_DISPATCHER} to automatically create SEAD tasks 
  -- based on detected enemy ground targets.
  -- 
  -- @field #TASK_A2G_SEAD
  TASK_A2G_SEAD = {
    ClassName = "TASK_A2G_SEAD",
  }
  
  --- Instantiates a new TASK_A2G_SEAD.
  -- @param #TASK_A2G_SEAD self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_UNIT TargetSetUnit 
  -- @param #string TaskBriefing The briefing of the task.
  -- @return #TASK_A2G_SEAD self
  function TASK_A2G_SEAD:New( Mission, SetGroup, TaskName, TargetSetUnit, TaskBriefing)
    local self = BASE:Inherit( self, TASK_A2G:New( Mission, SetGroup, TaskName, TargetSetUnit, "SEAD", TaskBriefing ) ) -- #TASK_A2G_SEAD
    self:F()
    
    Mission:AddTask( self )
    
    self:SetBriefing( 
      TaskBriefing or 
      "Execute a Suppression of Enemy Air Defenses." 
    )

    return self
  end 

  --- Set a score when a target in scope of the A2G attack, has been destroyed .
  -- @param #TASK_A2G_SEAD self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points to be granted when task process has been achieved.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G_SEAD
  function TASK_A2G_SEAD:SetScoreOnProgress( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "AccountForPlayer", "Player " .. PlayerName .. " has SEADed a target.", Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2G attack, have been destroyed.
  -- @param #TASK_A2G_SEAD self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G_SEAD
  function TASK_A2G_SEAD:SetScoreOnSuccess( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", "All radar emitting targets have been successfully SEADed!", Score )
    
    return self
  end

  --- Set a penalty when the A2G attack has failed.
  -- @param #TASK_A2G_SEAD self
  -- @param #string PlayerName The name of the player.
  -- @param #number Penalty The penalty in points, must be a negative value!
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G_SEAD
  function TASK_A2G_SEAD:SetScoreOnFail( PlayerName, Penalty, TaskUnit )
    self:F( { PlayerName, Penalty, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", "The SEADing has failed!", Penalty )
    
    return self
  end


end

do -- TASK_A2G_BAI

  --- The TASK_A2G_BAI class
  -- @type TASK_A2G_BAI
  -- @field Core.Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- Defines a Battlefield Air Interdiction task for a human player to be executed.
  -- These tasks are more strategic in nature and are most of the time further away from friendly forces.
  -- BAI tasks can also be used to express the abscence of friendly forces near the vicinity.
  -- 
  -- The TASK_A2G_BAI is used by the @{Tasking.Task_A2G_Dispatcher#TASK_A2G_DISPATCHER} to automatically create BAI tasks 
  -- based on detected enemy ground targets.
  -- 
  -- @field #TASK_A2G_BAI
  TASK_A2G_BAI = {
    ClassName = "TASK_A2G_BAI",
  }
  
  --- Instantiates a new TASK_A2G_BAI.
  -- @param #TASK_A2G_BAI self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_UNIT TargetSetUnit 
  -- @param #string TaskBriefing The briefing of the task.
  -- @return #TASK_A2G_BAI self
  function TASK_A2G_BAI:New( Mission, SetGroup, TaskName, TargetSetUnit, TaskBriefing )
    local self = BASE:Inherit( self, TASK_A2G:New( Mission, SetGroup, TaskName, TargetSetUnit, "BAI", TaskBriefing ) ) -- #TASK_A2G_BAI
    self:F()
    
    Mission:AddTask( self )
    
    self:SetBriefing( 
      TaskBriefing or 
      "Execute a Battlefield Air Interdiction of a group of enemy targets."
    )
    
    return self
  end

  --- Set a score when a target in scope of the A2G attack, has been destroyed .
  -- @param #TASK_A2G_BAI self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points to be granted when task process has been achieved.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G_BAI
  function TASK_A2G_BAI:SetScoreOnProgress( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "AccountForPlayer", "Player " .. PlayerName .. " has destroyed a target in Battlefield Air Interdiction (BAI).", Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2G attack, have been destroyed.
  -- @param #TASK_A2G_BAI self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G_BAI
  function TASK_A2G_BAI:SetScoreOnSuccess( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", "All targets have been successfully destroyed! The Battlefield Air Interdiction (BAI) is a success!", Score )
    
    return self
  end

  --- Set a penalty when the A2G attack has failed.
  -- @param #TASK_A2G_BAI self
  -- @param #string PlayerName The name of the player.
  -- @param #number Penalty The penalty in points, must be a negative value!
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G_BAI
  function TASK_A2G_BAI:SetScoreOnFail( PlayerName, Penalty, TaskUnit )
    self:F( { PlayerName, Penalty, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", "The Battlefield Air Interdiction (BAI) has failed!", Penalty )
    
    return self
  end

end




do -- TASK_A2G_CAS

  --- The TASK_A2G_CAS class
  -- @type TASK_A2G_CAS
  -- @field Core.Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- Defines an Close Air Support task for a human player to be executed.
  -- Friendly forces will be in the vicinity within 6km from the enemy.
  -- 
  -- The TASK_A2G_CAS is used by the @{Tasking.Task_A2G_Dispatcher#TASK_A2G_DISPATCHER} to automatically create CAS tasks 
  -- based on detected enemy ground targets.
  -- 
  -- @field #TASK_A2G_CAS
  TASK_A2G_CAS = {
    ClassName = "TASK_A2G_CAS",
  }
  
  --- Instantiates a new TASK_A2G_CAS.
  -- @param #TASK_A2G_CAS self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Core.Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_UNIT TargetSetUnit 
  -- @param #string TaskBriefing The briefing of the task.
  -- @return #TASK_A2G_CAS self
  function TASK_A2G_CAS:New( Mission, SetGroup, TaskName, TargetSetUnit, TaskBriefing )
    local self = BASE:Inherit( self, TASK_A2G:New( Mission, SetGroup, TaskName, TargetSetUnit, "CAS", TaskBriefing ) ) -- #TASK_A2G_CAS
    self:F()
    
    Mission:AddTask( self )
    
    self:SetBriefing( 
      TaskBriefing or 
      "Execute a Close Air Support for a group of enemy targets. " ..
      "Beware of friendlies at the vicinity! "
    )

    
    return self
  end 
  

  --- Set a score when a target in scope of the A2G attack, has been destroyed .
  -- @param #TASK_A2G_CAS self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points to be granted when task process has been achieved.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G_CAS
  function TASK_A2G_CAS:SetScoreOnProgress( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "AccountForPlayer", "Player " .. PlayerName .. " has destroyed a target in Close Air Support (CAS).", Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2G attack, have been destroyed.
  -- @param #TASK_A2G_CAS self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G_CAS
  function TASK_A2G_CAS:SetScoreOnSuccess( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", "All targets have been successfully destroyed! The Close Air Support (CAS) was a success!", Score )
    
    return self
  end

  --- Set a penalty when the A2G attack has failed.
  -- @param #TASK_A2G_CAS self
  -- @param #string PlayerName The name of the player.
  -- @param #number Penalty The penalty in points, must be a negative value!
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G_CAS
  function TASK_A2G_CAS:SetScoreOnFail( PlayerName, Penalty, TaskUnit )
    self:F( { PlayerName, Penalty, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", "The Close Air Support (CAS) has failed!", Penalty )
    
    return self
  end


end
