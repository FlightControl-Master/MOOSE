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
  function TASK_SEAD:New( Mission, SetGroup, TaskName, TargetSetUnit, TargetDistance )
    local self = BASE:Inherit( self, TASK:New( Mission, SetGroup, TaskName, "SEAD" ) ) -- Tasking.Task#TASK_SEAD
    self:F()
  
    self.TargetSetUnit = TargetSetUnit
    self.TargetDistance = TargetDistance

    Mission:AddTask( self )
    
    local Fsm = self:GetUnitProcess()
    

    Fsm:AddProcess   ( "Planned",                   "Accept",         ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "Route", Rejected = "Reject" }  )
    Fsm:AddTransition( "Assigned",                  "Route",          "Routing" )
    Fsm:AddProcess   ( "Routing",                   "RouteToPoint",   ACT_ROUTE_POINT:New( self.TargetPointVec2, self.TargetDistance ), { Arrived = "Arrive" } )
    Fsm:AddProcess   ( "Routing",                   "RouteToZone",    ACT_ROUTE_ZONE:New( self.TargetZone ), { Arrived = "Arrive" } )
    Fsm:AddTransition( "Rejected",                  "Reject",         "Aborted" )
    Fsm:AddTransition( "Arrived",                   "Arrive",         "Accounting" ) 
    Fsm:AddProcess   ( "Accounting",                "Account",        ACT_ACCOUNT_DEADS:New( self.TargetSetUnit, "SEAD" ), { Accounted = "Success" } )
    Fsm:AddProcess   ( "Accounting",                "Smoke",          ACT_ASSIST_SMOKE_TARGETS_ZONE:New( self.TargetSetUnit, self.TargetZone ) )
    Fsm:AddTransition( "Accounting",                "CheckRange",     "Accounting" )
    Fsm:AddTransition( "Accounting",                "InRange",        "Accounting" )
    Fsm:AddTransition( "Accounting",                "NotInRange",     "Assigned" )
    Fsm:AddTransition( "Accounting",                "Success",        "Success" )
    Fsm:AddTransition( "Failed",                    "Fail",           "Failed" )
    
    
    --- Test 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task#TASK_SEAD Task
    function Fsm:onenterRouting( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      -- Determine the first Unit from the self.TargetSetUnit
      
      local TargetUnit = Task.TargetSetUnit:GetFirst() -- Wrapper.Unit#UNIT
      if TargetUnit then
        self:E( { TargetZone = Task.TargetZone } )
        if Task.TargetZone then
          self:__RouteToZone( 0.1 )
        else
          local TargetPointVec2 = TargetUnit:GetPointVec2()
          local RoutePointProcess = self:GetProcess( "Routing", "RouteToPoint" )
          RoutePointProcess:SetTargetPointVec2( TargetPointVec2 )
          self:__RouteToPoint( 0.1 )
        end
      end        
    end
    
    function Fsm:onenterAccounting( TaskUnit, Task )
      self:E( { self } )
      self:Account()
      self:Smoke()
      self:__CheckRange( -5 )
    end
    
    --- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    function Fsm:onafterCheckRange( TaskUnit, Task )
      self:E( "CheckRange" )
      local TargetUnit = Task.TargetSetUnit:GetFirst() -- Wrapper.Unit#UNIT
      if TargetUnit then
        local PointVec2 = TargetUnit:GetPointVec2()
        local Distance = PointVec2:Get2DDistance( TaskUnit:GetPointVec2() )
        if Distance > Task.TargetDistance then
          self:NotInRange()
        else
          self:InRange()
        end
      end
    end  
    
    function Fsm:onafterNotInRange( TaskUnit )
      self:E( "Not In Range" )
      -- Stop accounting etc. and go back to routing.
      local FsmAccount = self:GetProcess( "Accounting", "Account" )
      local FsmSmoke = self:GetProcess( "Accounting", "Smoke" )
      FsmAccount:Stop() -- Stop the Accounting
      FsmSmoke:Stop() -- Stop the Smoking
      self:__Route( 1 )
    end

    function Fsm:onafterInRange( TaskUnit )
      self:E( "In Range" )
      self:__CheckRange( -5 )
    end
    
    return self
 
  end
  
  --- @param #TASK_SEAD self
  function TASK_SEAD:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.TargetSetUnit:GetUnitTypesText() .. " )"
  end

  --- @param #TASK_SEAD self
  function TASK_SEAD:SetTargetZone( TargetZone )
    self.TargetZone = TargetZone
  end
  
end 
