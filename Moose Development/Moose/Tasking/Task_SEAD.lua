--- This module contains the TASK_SEAD classes.
-- 
-- 1) @{#TASK_SEAD} class, extends @{Task#TASK}
-- =================================================
-- The @{#TASK_SEAD} class defines a SEAD task for a @{Set} of Target Units, located at a Target Zone, 
-- based on the tasking capabilities defined in @{Task#TASK}.
-- The TASK_SEAD is implemented using a @{Statemachine#FSM_TASK}, and has the following statuses:
-- 
--   * **None**: Start of the process
--   * **Planned**: The SEAD task is planned. Upon Planned, the sub-process @{Process_Fsm.Assign#ACT_ASSIGN_ACCEPT} is started to accept the task.
--   * **Assigned**: The SEAD task is assigned to a @{Group#GROUP}. Upon Assigned, the sub-process @{Process_Fsm.Route#ACT_ROUTE} is started to route the active Units in the Group to the attack zone.
--   * **Success**: The SEAD task is successfully completed. Upon Success, the sub-process @{Process_SEAD#PROCESS_SEAD} is started to follow-up successful SEADing of the targets assigned in the task.
--   * **Failed**: The SEAD task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
-- 
-- ===
-- 
-- ### Authors: FlightControl - Design and Programming
-- 
-- @module Task_SEAD



do -- TASK_SEAD

  --- The TASK_SEAD class
  -- @type TASK_SEAD
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Tasking.Task#TASK
  TASK_SEAD = {
    ClassName = "TASK_SEAD",
  }
  
  --- Instantiates a new TASK_SEAD.
  -- @param #TASK_SEAD self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Set#SET_UNIT UnitSetTargets
  -- @param #number TargetDistance The distance to Target when the Player is considered to have "arrived" at the engagement range.
  -- @param Core.Zone#ZONE_BASE TargetZone The target zone, if known.
  -- If the TargetZone parameter is specified, the player will be routed to the center of the zone where all the targets are assumed to be.
  -- @return #TASK_SEAD self
  function TASK_SEAD:New( Mission, SetGroup, TaskName, TargetSetUnit )
    local self = BASE:Inherit( self, TASK:New( Mission, SetGroup, TaskName, "SEAD" ) ) -- Tasking.Task#TASK_SEAD
    self:F()
  
    self.TargetSetUnit = TargetSetUnit

    Mission:AddTask( self )
    
    local Fsm = self:GetUnitProcess()
    

    Fsm:AddProcess   ( "Planned",                   "Accept",         ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "RouteToRendezVous", Rejected = "Reject" }  )
    
    Fsm:AddTransition( "Assigned",                  "RouteToRendezVous",          "RoutingToRendezVous" )
    Fsm:AddProcess   ( "RoutingToRendezVous",       "RouteToRendezVousPoint",   ACT_ROUTE_POINT:New(), { Arrived = "ArriveAtRendezVous" } )
    Fsm:AddProcess   ( "RoutingToRendezVous",       "RouteToRendezVousZone",    ACT_ROUTE_ZONE:New(), { Arrived = "ArriveAtRendezVous" } )
    
    Fsm:AddTransition( { "Arrived", "RoutingToRendezVous" },                   "ArriveAtRendezVous",         "ArrivedAtRendezVous" )
    
    Fsm:AddTransition( { "ArrivedAtRendezVous", "HoldingAtRendezVous" },    "Engage",         "Engaging" )
    Fsm:AddTransition( { "ArrivedAtRendezVous", "HoldingAtRendezVous" },    "HoldAtRendezVous",         "HoldingAtRendezVous" )
     
    Fsm:AddProcess   ( "Engaging",                  "Account",        ACT_ACCOUNT_DEADS:New( self.TargetSetUnit, "SEAD" ), { Accounted = "Success" } )
    --Fsm:AddProcess   ( "Accounting",                "Smoke",          ACT_ASSIST_SMOKE_TARGETS_ZONE:New( self.TargetSetUnit, self.TargetZone ) )
    Fsm:AddTransition( "Engaging", "RouteToTarget", "Engaging" )
    Fsm:AddProcess( "Engaging", "RouteToTargetZone", ACT_ROUTE_ZONE:New(), {} )
    Fsm:AddProcess( "Engaging", "RouteToTargetPoint", ACT_ROUTE_POINT:New(), {} )
    Fsm:AddTransition( "Engaging", "RouteToTargets", "Engaging" )
    
    Fsm:AddTransition( "Accounted",                "DestroyedAll",        "Accounted" )
    Fsm:AddTransition( "Rejected",                  "Reject",         "Aborted" )
    Fsm:AddTransition( "Failed",                    "Fail",           "Failed" )
    
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_SEAD#TASK_SEAD Task
    function Fsm:onafterRouteToRendezVous( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.RendezVousSetUnit
      
      if Task:GetRendezVousZone() then
        self:__RouteToRendezVousZone( 0.1 )
      else
        if Task:GetRendezVousPointVec2() then
          self:__RouteToRendezVousPoint( 0.1 )
        else
          self:__ArriveAtRendezVous( 0.1 )
        end
      end
    end

    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_SEAD Task
    function Fsm:OnAfterArriveAtRendezVous( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      self:__Engage( 0.1 )      
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_SEAD Task
    function Fsm:onafterEngage( TaskUnit, Task )
      self:E( { self } )
      self:__Account( 0.1 )
      self:__RouteToTarget(0.1 )
      self:__RouteToTargets( -10 )
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_SEAD#TASK_SEAD Task
    function Fsm:onafterRouteToTarget( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      if Task:GetTargetZone() then
        self:__RouteToTargetZone( 0.1 )
      else
        if Task:GetTargetPointVec2() then
          local TargetUnit = Task.TargetSetUnit:GetFirst() -- Wrapper.Unit#UNIT
          if TargetUnit then
            Task:SetTargetPointVec2( TargetUnit:GetPointVec2() )
          end
          self:__RouteToTargetPoint( 0.1 )
        end
      end
    end
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_SEAD#TASK_SEAD Task
    function Fsm:onafterRouteToTargets( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      local TargetUnit = Task.TargetSetUnit:GetFirst() -- Wrapper.Unit#UNIT
      if TargetUnit then
        Task:SetTargetPointVec2( TargetUnit:GetPointVec2() )
      end
    end
    
    return self
 
  end
  
  --- @param #TASK_SEAD self
  function TASK_SEAD:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.TargetSetUnit:GetUnitTypesText() .. " )"
  end

  --- @param #TASK_SEAD self
  -- @param Core.Point#POINT_VEC2 RendezVousPointVec2 The PointVec2 object referencing to the 2D point where the RendezVous point is located on the map.
  -- @param #number RendezVousRange The RendezVousRange that defines when the player is considered to have arrived at the RendezVous point.
  function TASK_SEAD:SetRendezVousPointVec2( RendezVousPointVec2, RendezVousRange )
  
    local ProcessUnit = self:GetUnitProcess()
  
    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteRendezVous:SetPointVec2( RendezVousPointVec2 )
    ActRouteRendezVous:SetRange( RendezVousRange )
  end
  
  --- @param #TASK_SEAD self
  -- @return Core.Point#POINT_VEC2 The PointVec2 object referencing to the 2D point where the RendezVous point is located on the map.
  -- @return #number The RendezVousRange that defines when the player is considered to have arrived at the RendezVous point.
  function TASK_SEAD:GetRendezVousPointVec2()
  
    local ProcessUnit = self:GetUnitProcess()

    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    return ActRouteRendezVous:GetPointVec2(), ActRouteRendezVous:GetRange()
  end
  
  
  
  --- @param #TASK_SEAD self
  -- @param Core.Zone#ZONE_BASE RendezVousZone The Zone object where the RendezVous is located on the map.
  function TASK_SEAD:SetRendezVousZone( RendezVousZone )
  
    local ProcessUnit = self:GetUnitProcess()

    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteRendezVous:SetZone( RendezVousZone )
  end

  --- @param #TASK_SEAD self
  -- @return Core.Zone#ZONE_BASE The Zone object where the RendezVous is located on the map.
  function TASK_SEAD:GetRendezVousZone()

    local ProcessUnit = self:GetUnitProcess()

    local ActRouteRendezVous = ProcessUnit:GetProcess( "RoutingToRendezVous", "RouteToRendezVousZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteRendezVous:GetZone()
  end
  
  --- @param #TASK_SEAD self
  -- @param Core.Point#POINT_VEC2 TargetPointVec2 The PointVec2 object where the Target is located on the map.
  function TASK_SEAD:SetTargetPointVec2( TargetPointVec2 )
  
    local ProcessUnit = self:GetUnitProcess()

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteTarget:SetPointVec2( TargetPointVec2 )
  end
   

  --- @param #TASK_SEAD self
  -- @return Core.Point#POINT_VEC2 The PointVec2 object where the Target is located on the map.
  function TASK_SEAD:GetTargetPointVec2()

    local ProcessUnit = self:GetUnitProcess()

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    return ActRouteTarget:GetPointVec2()
  end


  --- @param #TASK_SEAD self
  -- @param Core.Zone#ZONE_BASE TargetZone The Zone object where the Target is located on the map.
  function TASK_SEAD:SetTargetZone( TargetZone )
  
    local ProcessUnit = self:GetUnitProcess()

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteTarget:SetZone( TargetZone )
  end
   

  --- @param #TASK_SEAD self
  -- @return Core.Zone#ZONE_BASE The Zone object where the Target is located on the map.
  function TASK_SEAD:GetTargetZone()
    local ProcessUnit = self:GetUnitProcess()

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteTarget:GetZone()
  end
  
end 
