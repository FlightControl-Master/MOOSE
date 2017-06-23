--- **Tasking** - The TASK_A2G models tasks for players in Air to Ground engagements.
-- 
-- ![Banner Image](..\Presentations\TASK_A2G\Dia1.JPG)
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====
--   
-- @module Task_A2G

do -- TASK_A2G

  --- The TASK_A2G class
  -- @type TASK_A2G
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- # TASK_A2G class, extends @{Task#TASK}
  -- 
  -- The TASK_A2G class defines Air To Ground tasks for a @{Set} of Target Units, 
  -- based on the tasking capabilities defined in @{Task#TASK}.
  -- The TASK_A2G is implemented using a @{Fsm#FSM_TASK}, and has the following statuses:
  -- 
  --   * **None**: Start of the process
  --   * **Planned**: The A2G task is planned.
  --   * **Assigned**: The A2G task is assigned to a @{Group#GROUP}.
  --   * **Success**: The A2G task is successfully completed.
  --   * **Failed**: The A2G task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
  -- 
  -- ## Set the scoring of achievements in an A2G attack.
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
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Set#SET_UNIT UnitSetTargets
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
    

    Fsm:AddProcess   ( "Planned", "Accept", ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "RouteToRendezVous", Rejected = "Reject" }  )
    
    Fsm:AddTransition( "Assigned", "RouteToRendezVous", "RoutingToRendezVous" )
    Fsm:AddProcess   ( "RoutingToRendezVous", "RouteToRendezVousPoint", ACT_ROUTE_POINT:New(), { Arrived = "ArriveAtRendezVous" } )
    Fsm:AddProcess   ( "RoutingToRendezVous", "RouteToRendezVousZone", ACT_ROUTE_ZONE:New(), { Arrived = "ArriveAtRendezVous" } )
    
    Fsm:AddTransition( { "Arrived", "RoutingToRendezVous" }, "ArriveAtRendezVous", "ArrivedAtRendezVous" )
    
    Fsm:AddTransition( { "ArrivedAtRendezVous", "HoldingAtRendezVous" }, "Engage", "Engaging" )
    Fsm:AddTransition( { "ArrivedAtRendezVous", "HoldingAtRendezVous" }, "HoldAtRendezVous", "HoldingAtRendezVous" )
     
    Fsm:AddProcess   ( "Engaging", "Account", ACT_ACCOUNT_DEADS:New( self.TargetSetUnit, self.TaskType ), {} )
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
    function Fsm:onafterRouteToRendezVous( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
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
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      self:__Engage( 0.1 )      
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_A2G Task
    function Fsm:onafterEngage( TaskUnit, Task )
      self:E( { self } )
      self:__Account( 0.1 )
      self:__RouteToTarget(0.1 )
      self:__RouteToTargets( -10 )
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2G#TASK_A2G Task
    function Fsm:onafterRouteToTarget( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      if Task:GetTargetZone( TaskUnit ) then
        self:__RouteToTargetZone( 0.1 )
      else
        local TargetUnit = Task.TargetSetUnit:GetFirst() -- Wrapper.Unit#UNIT
        if TargetUnit then
          local Coordinate = TargetUnit:GetCoordinate()
          self:T( { TargetCoordinate = Coordinate, Coordinate:GetX(), Coordinate:GetY(), Coordinate:GetZ() } )
          Task:SetTargetCoordinate( TargetUnit:GetCoordinate(), TaskUnit )
        end
        self:__RouteToTargetPoint( 0.1 )
      end
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2G#TASK_A2G Task
    function Fsm:onafterRouteToTargets( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      local TargetUnit = Task.TargetSetUnit:GetFirst() -- Wrapper.Unit#UNIT
      if TargetUnit then
        Task:SetTargetCoordinate( TargetUnit:GetCoordinate(), TaskUnit )
      end
      self:__RouteToTargets( -10 )
    end
    
    return self
 
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

  --- Set a score when a target in scope of the A2G attack, has been destroyed .
  -- @param #TASK_A2G self
  -- @param #string Text The text to display to the player, when the target has been destroyed.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G
  function TASK_A2G:SetScoreOnDestroy( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "Account", Text, Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2G attack, have been destroyed.
  -- @param #TASK_A2G self
  -- @param #string Text The text to display to the player, when all targets hav been destroyed.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G
  function TASK_A2G:SetScoreOnSuccess( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", Text, Score )
    
    return self
  end

  --- Set a penalty when the A2G attack has failed.
  -- @param #TASK_A2G self
  -- @param #string Text The text to display to the player, when the A2G attack has failed.
  -- @param #number Penalty The penalty in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2G
  function TASK_A2G:SetPenaltyOnFailed( Text, Penalty, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", Text, Penalty )
    
    return self
  end

  
end 


do -- TASK_A2G_SEAD

  --- The TASK_A2G_SEAD class
  -- @type TASK_A2G_SEAD
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- # TASK_A2G_SEAD class, extends @{Task_A2G#TASK_A2G}
  -- 
  -- The TASK_A2G_SEAD class defines an Suppression or Extermination of Air Defenses task for a human player to be executed.
  -- These tasks are important to be executed as they will help to achieve air superiority at the vicinity.
  -- 
  -- The TASK_A2G_SEAD is used by the @{Task_A2G_Dispatcher#TASK_A2G_DISPATCHER} to automatically create SEAD tasks 
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
  function TASK_A2G_SEAD:New( Mission, SetGroup, TaskName, TargetSetUnit, TaskBriefing )
    local self = BASE:Inherit( self, TASK_A2G:New( Mission, SetGroup, TaskName, TargetSetUnit, "SEAD", TaskBriefing ) ) -- #TASK_A2G_SEAD
    self:F()
    
    Mission:AddTask( self )
    
    self:SetBriefing( 
      TaskBriefing or 
      "Execute a Suppression of Enemy Air Defenses.\n"
    )

    local TargetCoordinate = TargetSetUnit:GetFirst():GetCoordinate()
    self:SetInfo( "Coordinates", TargetCoordinate )

    self:SetInfo( "Threat", "[" .. string.rep(  "■", TargetSetUnit:CalculateThreatLevelA2G() ) .. "]" )
    local DetectedItemsCount = TargetSetUnit:Count()
    local DetectedItemsTypes = TargetSetUnit:GetTypeNames()
    self:SetInfo( "Targets", string.format( "%d of %s", DetectedItemsCount, DetectedItemsTypes ) ) 

    return self
  end 

  --- @param #TASK_A2G_SEAD self
  function TASK_A2G_SEAD:onafterGoal( TaskUnit, From, Event, To )
    local TargetSetUnit = self.TargetSetUnit -- Core.Set#SET_UNIT
    
    if TargetSetUnit:Count() == 0 then
      self:Success()
    end
    
    self:__Goal( -10 )
  end

end

do -- TASK_A2G_BAI

  --- The TASK_A2G_BAI class
  -- @type TASK_A2G_BAI
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- # TASK_A2G_BAI class, extends @{Task_A2G#TASK_A2G}
  -- 
  -- The TASK_A2G_BAI class defines an Battlefield Air Interdiction task for a human player to be executed.
  -- These tasks are more strategic in nature and are most of the time further away from friendly forces.
  -- BAI tasks can also be used to express the abscence of friendly forces near the vicinity.
  -- 
  -- The TASK_A2G_BAI is used by the @{Task_A2G_Dispatcher#TASK_A2G_DISPATCHER} to automatically create BAI tasks 
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
      "Execute a Battlefield Air Interdiction of a group of enemy targets.\n"
    )

    local TargetCoordinate = TargetSetUnit:GetFirst():GetCoordinate()
    self:SetInfo( "Coordinates", TargetCoordinate )

    self:SetInfo( "Threat", "[" .. string.rep(  "■", TargetSetUnit:CalculateThreatLevelA2G() ) .. "]" )
    local DetectedItemsCount = TargetSetUnit:Count()
    local DetectedItemsTypes = TargetSetUnit:GetTypeNames()
    self:SetInfo( "Targets", string.format( "%d of %s", DetectedItemsCount, DetectedItemsTypes ) ) 

    return self
  end 

  --- @param #TASK_A2G_BAI self
  function TASK_A2G_BAI:onafterGoal( TaskUnit, From, Event, To )
    local TargetSetUnit = self.TargetSetUnit -- Core.Set#SET_UNIT
    
    if TargetSetUnit:Count() == 0 then
      self:Success()
    end
    
    self:__Goal( -10 )
  end

end

do -- TASK_A2G_CAS

  --- The TASK_A2G_CAS class
  -- @type TASK_A2G_CAS
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK

  --- # TASK_A2G_CAS class, extends @{Task_A2G#TASK_A2G}
  -- 
  -- The TASK_A2G_CAS class defines an Close Air Support task for a human player to be executed.
  -- Friendly forces will be in the vicinity within 6km from the enemy.
  -- 
  -- The TASK_A2G_CAS is used by the @{Task_A2G_Dispatcher#TASK_A2G_DISPATCHER} to automatically create CAS tasks 
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
      "Execute a Close Air Support for a group of enemy targets.\n" ..
      "Beware of friendlies at the vicinity!\n"
    )

    local TargetCoordinate = TargetSetUnit:GetFirst():GetCoordinate()
    self:SetInfo( "Coordinates", TargetCoordinate )

    self:SetInfo( "Threat", "[" .. string.rep(  "■", TargetSetUnit:CalculateThreatLevelA2G() ) .. "]" )
    local DetectedItemsCount = TargetSetUnit:Count()
    local DetectedItemsTypes = TargetSetUnit:GetTypeNames()
    self:SetInfo( "Targets", string.format( "%d of %s", DetectedItemsCount, DetectedItemsTypes ) ) 

    return self
  end 

  --- @param #TASK_A2G_CAS self
  function TASK_A2G_CAS:onafterGoal( TaskUnit, From, Event, To )
    local TargetSetUnit = self.TargetSetUnit -- Core.Set#SET_UNIT
    
    if TargetSetUnit:Count() == 0 then
      self:Success()
    end
    
    self:__Goal( -10 )
  end

end
