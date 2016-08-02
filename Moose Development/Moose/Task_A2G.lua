--- This module contains the TASK_A2G classes.
-- 
-- 1) @{#TASK_A2G} class, extends @{Task#TASK_BASE}
-- =================================================
-- The @{#TASK_A2G} class defines a CAS or BAI task of a @{Set} of Target Units, 
-- located at a Target Zone, based on the tasking capabilities defined in @{Task#TASK_BASE}.
-- The TASK_A2G is implemented using a @{Statemachine#STATEMACHINE_TASK}, and has the following statuses:
-- 
--   * **None**: Start of the process
--   * **Planned**: The SEAD task is planned. Upon Planned, the sub-process @{Process_Assign#PROCESS_ASSIGN_ACCEPT} is started to accept the task.
--   * **Assigned**: The SEAD task is assigned to a @{Group#GROUP}. Upon Assigned, the sub-process @{Process_Route#PROCESS_ROUTE} is started to route the active Units in the Group to the attack zone.
--   * **Success**: The SEAD task is successfully completed. Upon Success, the sub-process @{Process_SEAD#PROCESS_SEAD} is started to follow-up successful SEADing of the targets assigned in the task.
--   * **Failed**: The SEAD task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
-- 
-- ===
-- 
-- ### Authors: FlightControl - Design and Programming
-- 
-- @module Task_A2G


do -- TASK_A2G

  --- The TASK_A2G class
  -- @type TASK_A2G
  -- @extends Task#TASK_BASE
  TASK_A2G = {
    ClassName = "TASK_A2G",
  }
  
  --- Instantiates a new TASK_A2G.
  -- @param #TASK_A2G self
  -- @param Mission#MISSION Mission
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param #string TaskType BAI or CAS
  -- @param Set#SET_UNIT UnitSetTargets
  -- @param Zone#ZONE_BASE TargetZone
  -- @return #TASK_A2G self
  function TASK_A2G:New( Mission, SetGroup, TaskName, TaskType, TargetSetUnit, TargetZone, FACUnit )
    local self = BASE:Inherit( self, TASK_BASE:New( Mission, SetGroup, TaskName, TaskType, "A2G" ) )
    self:F()
  
    self.TargetSetUnit = TargetSetUnit
    self.TargetZone = TargetZone
    self.FACUnit = FACUnit

    _EVENTDISPATCHER:OnPlayerLeaveUnit( self._EventPlayerLeaveUnit, self )
    _EVENTDISPATCHER:OnDead( self._EventDead, self )
    _EVENTDISPATCHER:OnCrash( self._EventDead, self )
    _EVENTDISPATCHER:OnPilotDead( self._EventDead, self )

    return self
  end
  
  --- Removes a TASK_A2G.
  -- @param #TASK_A2G self
  -- @return #nil
  function TASK_A2G:CleanUp()

    self:GetParent( self ):CleanUp()
    
    return nil
  end
  
  
  --- Assign the @{Task} to a @{Unit}.
  -- @param #TASK_A2G self
  -- @param Unit#UNIT TaskUnit
  -- @return #TASK_A2G self
  function TASK_A2G:AssignToUnit( TaskUnit )
    self:F( TaskUnit:GetName() )
  
    local ProcessAssign = self:AddProcess( TaskUnit, PROCESS_ASSIGN_ACCEPT:New( self, TaskUnit, self.TaskBriefing ) )
    local ProcessRoute = self:AddProcess( TaskUnit, PROCESS_ROUTE:New( self, TaskUnit, self.TargetZone ) )
    local ProcessDestroy = self:AddProcess( TaskUnit, PROCESS_DESTROY:New( self, self.TaskType, TaskUnit, self.TargetSetUnit ) )
    local ProcessSmoke = self:AddProcess( TaskUnit, PROCESS_SMOKE_TARGETS:New( self, TaskUnit, self.TargetSetUnit, self.TargetZone ) )
    local ProcessJTAC = self:AddProcess( TaskUnit, PROCESS_JTAC:New( self, TaskUnit, self.TargetSetUnit, self.FACUnit ) )
    
    local Process = self:AddStateMachine( TaskUnit, STATEMACHINE_TASK:New( self, TaskUnit, {
        initial = 'None',
        events = {
          { name = 'Next',   from = 'None',           to = 'Planned' },
          { name = 'Next',    from = 'Planned',       to = 'Assigned' },
          { name = 'Reject',  from = 'Planned',       to = 'Rejected' }, 
          { name = 'Next',    from = 'Assigned',      to = 'Success' },
          { name = 'Fail',    from = 'Assigned',      to = 'Failed' }, 
          { name = 'Fail',    from = 'Arrived',       to = 'Failed' }     
        },
        callbacks = {
          onNext = self.OnNext,
          onRemove = self.OnRemove,
        },
        subs = {
          Assign = {  onstateparent = 'Planned',          oneventparent = 'Next',         fsm = ProcessAssign.Fsm,        event = 'Start',      returnevents = { 'Next', 'Reject' } },
          Route = {   onstateparent = 'Assigned',         oneventparent = 'Next',         fsm = ProcessRoute.Fsm,         event = 'Start'       },
          Destroy = { onstateparent = 'Assigned',         oneventparent = 'Next',         fsm = ProcessDestroy.Fsm,       event = 'Start',      returnevents = { 'Next' } },
          Smoke = {   onstateparent = 'Assigned',         oneventparent = 'Next',         fsm = ProcessSmoke.Fsm,         event = 'Start',      },
          JTAC = {    onstateparent = 'Assigned',         oneventparent = 'Next',         fsm = ProcessJTAC.Fsm,          event = 'Start',      },
        }
      } ) )
    
    ProcessRoute:AddScore( "Failed", "failed to destroy a ground unit", -100 )
    ProcessDestroy:AddScore( "Destroy", "destroyed a ground unit", 25 )
    ProcessDestroy:AddScore( "Failed", "failed to destroy a ground unit", -100 )
    
    Process:Next()
  
    return self
  end
  
  --- StateMachine callback function for a TASK
  -- @param #TASK_A2G self
  -- @param StateMachine#STATEMACHINE_TASK Fsm
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Event#EVENTDATA Event
  function TASK_A2G:OnNext( Fsm, Event, From, To, Event )
  
    self:SetState( self, "State", To )
  
  end
  
    --- @param #TASK_A2G self
  function TASK_A2G:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.TargetSetUnit:GetUnitTypesText() .. " )"
  end
  
  
  --- @param #TASK_A2G self
  function TASK_A2G:_Schedule()
    self:F2()
  
    self.TaskScheduler = SCHEDULER:New( self, _Scheduler, {}, 15, 15 )
    return self
  end
  
  
  --- @param #TASK_A2G self
  function TASK_A2G._Scheduler()
    self:F2()
  
    return true
  end
  
end



