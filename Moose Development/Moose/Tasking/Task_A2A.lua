--- **Tasking** - The TASK_A2A models tasks for players in Air to Air engagements.
-- 
-- ![Banner Image](..\Presentations\TASK_A2A\Dia1.JPG)
-- 
-- 
-- # 1) @{Task_A2A#TASK_A2A} class, extends @{Task#TASK}
-- 
-- The @{#TASK_A2A} class defines Air To Air tasks for a @{Set} of Target Units, 
-- based on the tasking capabilities defined in @{Task#TASK}.
-- The TASK_A2A is implemented using a @{Statemachine#FSM_TASK}, and has the following statuses:
-- 
--   * **None**: Start of the process
--   * **Planned**: The A2A task is planned.
--   * **Assigned**: The A2A task is assigned to a @{Group#GROUP}.
--   * **Success**: The A2A task is successfully completed.
--   * **Failed**: The A2A task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
-- 
-- # 1.1) Set the scoring of achievements in an A2A attack.
-- 
-- Scoring or penalties can be given in the following circumstances:
-- 
--   * @{#TASK_A2A.SetScoreOnDestroy}(): Set a score when a target in scope of the A2A attack, has been destroyed.
--   * @{#TASK_A2A.SetScoreOnSuccess}(): Set a score when all the targets in scope of the A2A attack, have been destroyed.
--   * @{#TASK_A2A.SetPenaltyOnFailed}(): Set a penalty when the A2A attack has failed.
-- 
-- # 2) @{Task_A2A#TASK_INTERCEPT} class, extends @{Task_A2A#TASK_A2A}
-- 
-- The TASK_A2A_INTERCEPT class defines an INTERCEPT task for a @{Set} of Target Units.
-- 
-- ====
--
-- # **API CHANGE HISTORY**
--
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
--
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
--
-- Hereby the change log:
--
-- ===
--
-- # **AUTHORS and CONTRIBUTIONS**
--
-- ### Contributions:
--
--
--        
-- ### Authors:
--
--   * **FlightControl**: Concept, Design & Programming.
--   
-- @module Task_A2A

do -- TASK_A2A

  --- The TASK_A2A class
  -- @type TASK_A2A
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK
  TASK_A2A = {
    ClassName = "TASK_A2A",
  }
  
  --- Instantiates a new TASK_A2A.
  -- @param #TASK_A2A self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP SetAttack The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Set#SET_UNIT UnitSetTargets
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
    

    Fsm:AddProcess   ( "Planned", "Accept", ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "RouteToRendezVous", Rejected = "Reject" }  )
    
    Fsm:AddTransition( "Assigned", "RouteToRendezVous", "RoutingToRendezVous" )
    Fsm:AddProcess   ( "RoutingToRendezVous", "RouteToRendezVousPoint", ACT_ROUTE_POINT:New(), { Arrived = "ArriveAtRendezVous" } )
    Fsm:AddProcess   ( "RoutingToRendezVous", "RouteToRendezVousZone", ACT_ROUTE_ZONE:New(), { Arrived = "ArriveAtRendezVous" } )
    
    Fsm:AddTransition( { "Arrived", "RoutingToRendezVous" }, "ArriveAtRendezVous", "ArrivedAtRendezVous" )
    
    Fsm:AddTransition( { "ArrivedAtRendezVous", "HoldingAtRendezVous" }, "Engage", "Engaging" )
    Fsm:AddTransition( { "ArrivedAtRendezVous", "HoldingAtRendezVous" }, "HoldAtRendezVous", "HoldingAtRendezVous" )
     
    Fsm:AddProcess   ( "Engaging", "Account", ACT_ACCOUNT_DEADS:New( self.TargetSetUnit, self.TaskType ), { Accounted = "Success" } )
    Fsm:AddTransition( "Engaging", "RouteToTarget", "Engaging" )
    Fsm:AddProcess( "Engaging", "RouteToTargetZone", ACT_ROUTE_ZONE:New(), {} )
    Fsm:AddProcess( "Engaging", "RouteToTargetPoint", ACT_ROUTE_POINT:New(), {} )
    Fsm:AddTransition( "Engaging", "RouteToTargets", "Engaging" )
    
    Fsm:AddTransition( "Accounted", "DestroyedAll", "Accounted" )
    Fsm:AddTransition( "Accounted", "Success", "Success" )
    Fsm:AddTransition( "Rejected", "Reject", "Aborted" )
    Fsm:AddTransition( "Failed", "Fail", "Failed" )
    
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2A#TASK_A2A Task
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
    -- @param Tasking.Task#TASK_A2A Task
    function Fsm:OnAfterArriveAtRendezVous( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      self:__Engage( 0.1 )      
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_A2A Task
    function Fsm:onafterEngage( TaskUnit, Task )
      self:E( { self } )
      self:__Account( 0.1 )
      self:__RouteToTarget(0.1 )
      self:__RouteToTargets( -10 )
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2A#TASK_A2A Task
    function Fsm:onafterRouteToTarget( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      if Task:GetTargetZone( TaskUnit ) then
        self:__RouteToTargetZone( 0.1 )
      else
        local TargetUnit = Task.TargetSetUnit:GetFirst() -- Wrapper.Unit#UNIT
        if TargetUnit then
          local Coordinate = TargetUnit:GetCoordinate()
          self:T( { TargetCoordinate = Coordinate, Coordinate:GetX(), Coordinate:GetAlt(), Coordinate:GetZ() } )
          Task:SetTargetCoordinate( TargetUnit:GetCoordinate(), TaskUnit )
        end
        self:__RouteToTargetPoint( 0.1 )
      end
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_A2A#TASK_A2A Task
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
  
    TargetCoordinate:SetModeA2A()
  
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

  --- Set a score when a target in scope of the A2A attack, has been destroyed .
  -- @param #TASK_A2A self
  -- @param #string Text The text to display to the player, when the target has been destroyed.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A
  function TASK_A2A:SetScoreOnDestroy( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "Account", Text, Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2A attack, have been destroyed.
  -- @param #TASK_A2A self
  -- @param #string Text The text to display to the player, when all targets hav been destroyed.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A
  function TASK_A2A:SetScoreOnSuccess( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", Text, Score )
    
    return self
  end

  --- Set a penalty when the A2A attack has failed.
  -- @param #TASK_A2A self
  -- @param #string Text The text to display to the player, when the A2A attack has failed.
  -- @param #number Penalty The penalty in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_A2A
  function TASK_A2A:SetPenaltyOnFailed( Text, Penalty, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", Text, Penalty )
    
    return self
  end

  
end 


do -- TASK_A2A_INTERCEPT

  --- The TASK_A2A_INTERCEPT class
  -- @type TASK_A2A_INTERCEPT
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK
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
  -- @return #TASK_A2A_INTERCEPT self
  function TASK_A2A_INTERCEPT:New( Mission, SetGroup, TaskName, TargetSetUnit, TaskBriefing )
    local self = BASE:Inherit( self, TASK_A2A:New( Mission, SetGroup, TaskName, TargetSetUnit, "INTERCEPT", TaskBriefing ) ) -- #TASK_A2A_INTERCEPT
    self:F()
    
    Mission:AddTask( self )
    
    --TODO: Add BR, Altitude, type of planes...
    
    self:SetBriefing( 
      TaskBriefing or 
      "Intercept incoming intruders.\n"
    )

    local TargetCoordinate = TargetSetUnit:GetFirst():GetCoordinate()
    TargetCoordinate:SetModeA2A()
    self:SetInfo( "Coordinates", TargetCoordinate )

    self:SetInfo( "ThreatLevel", "[" .. string.rep(  "■", TargetSetUnit:CalculateThreatLevelA2G() ) .. "]" )
    local DetectedItemsCount = TargetSetUnit:Count()
    local DetectedItemsTypes = TargetSetUnit:GetTypeNames()
    self:SetInfo( "Targets", string.format( "%d of %s", DetectedItemsCount, DetectedItemsTypes ) ) 
    
    return self
  end 

end


do -- TASK_A2A_ENGAGE

  --- The TASK_A2A_ENGAGE class
  -- @type TASK_A2A_ENGAGE
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK
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
    
    --TODO: Add BR, Altitude, type of planes...
    
    self:SetBriefing( 
      TaskBriefing or 
      "Bogeys are nearby! Those players who are near to the intruders are requested to ENGAGE!\n"
    )

    local TargetCoordinate = TargetSetUnit:GetFirst():GetCoordinate()
    TargetCoordinate:SetModeA2A()
    self:SetInfo( "Coordinates", TargetCoordinate )

    self:SetInfo( "ThreatLevel", "[" .. string.rep(  "■", TargetSetUnit:CalculateThreatLevelA2G() ) .. "]" )
    local DetectedItemsCount = TargetSetUnit:Count()
    local DetectedItemsTypes = TargetSetUnit:GetTypeNames()
    self:SetInfo( "Targets", string.format( "%d of %s", DetectedItemsCount, DetectedItemsTypes ) ) 
    
    return self
  end 

end

