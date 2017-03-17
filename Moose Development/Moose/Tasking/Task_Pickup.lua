--- This module contains the TASK_PICKUP classes.
-- 
-- 1) @{#TASK_PICKUP} class, extends @{Task#TASK}
-- ===================================================
-- The @{#TASK_PICKUP} class defines a pickup task of a @{Set} of @{CARGO} objects defined within the mission. 
-- based on the tasking capabilities defined in @{Task#TASK}.
-- The TASK_PICKUP is implemented using a @{Statemachine#FSM_TASK}, and has the following statuses:
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
-- @module Task_PICKUP


do -- TASK_PICKUP

  --- The TASK_PICKUP class
  -- @type TASK_PICKUP
  -- @extends Tasking.Task#TASK
  TASK_PICKUP = {
    ClassName = "TASK_PICKUP",
  }
  
  --- Instantiates a new TASK_PICKUP.
  -- @param #TASK_PICKUP self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP AssignedSetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param #string TaskType BAI or CAS
  -- @param Set#SET_UNIT UnitSetTargets
  -- @param Core.Zone#ZONE_BASE TargetZone
  -- @return #TASK_PICKUP self
  function TASK_PICKUP:New( Mission, AssignedSetGroup, TaskName, TaskType )
    local self = BASE:Inherit( self, TASK:New( Mission, AssignedSetGroup, TaskName, TaskType, "PICKUP" ) )
    self:F()
  
    return self
  end
  
  --- Removes a TASK_PICKUP.
  -- @param #TASK_PICKUP self
  -- @return #nil
  function TASK_PICKUP:CleanUp()

    self:GetParent( self ):CleanUp()
    
    return nil
  end
  
  
  --- Assign the @{Task} to a @{Unit}.
  -- @param #TASK_PICKUP self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_PICKUP self
  function TASK_PICKUP:AssignToUnit( TaskUnit )
    self:F( TaskUnit:GetName() )
  
    local ProcessAssign = self:AddProcess( TaskUnit, ACT_ASSIGN_ACCEPT:New( self, TaskUnit, self.TaskBriefing ) )
    local ProcessPickup = self:AddProcess( TaskUnit, PROCESS_PICKUP:New( self, self.TaskType, TaskUnit ) )
    
    local Process = self:AddStateMachine( TaskUnit, FSM_TASK:New( self, TaskUnit, {
        initial = 'None',
        events = {
          { name = 'Next',   from = 'None',           to = 'Planned' },
          { name = 'Next',    from = 'Planned',       to = 'Assigned' },
          { name = 'Next',    from = 'Assigned',      to = 'Success' },
          { name = 'Fail',    from = 'Assigned',      to = 'Failed' }, 
        },
        callbacks = {
          onNext = self.OnNext,
        },
        subs = {
          Assign      = { onstateparent = 'Planned',          oneventparent = 'Next',         fsm = ProcessAssign.Fsm,        event = 'Start',      returnevents = { 'Next', 'Reject' } },
          Pickup      = { onstateparent = 'Assigned',         oneventparent = 'Next',         fsm = ProcessDestroy.Fsm,       event = 'Start',      returnevents = { 'Next' } },
        }
      } ) )
    
    ProcessRoute:AddScore( "Failed", "failed to destroy a ground unit", -100 )
    ProcessDestroy:AddScore( "Pickup", "Picked-Up a Cargo", 25 )
    ProcessDestroy:AddScore( "Failed", "failed to destroy a ground unit", -100 )
    
    Process:Next()
  
    return self
  end
  
  --- StateMachine callback function for a TASK
  -- @param #TASK_PICKUP self
  -- @param Core.Fsm#FSM_TASK Fsm
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Event#EVENTDATA Event
  function TASK_PICKUP:OnNext( Fsm, From, Event, To, Event )
  
    self:SetState( self, "State", To )
  
  end
  
    --- @param #TASK_PICKUP self
  function TASK_PICKUP:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.TargetSetUnit:GetUnitTypesText() .. " )"
  end
  
  
  --- @param #TASK_PICKUP self
  function TASK_PICKUP:_Schedule()
    self:F2()
  
    self.TaskScheduler = SCHEDULER:New( self, _Scheduler, {}, 15, 15 )
    return self
  end
  
  
  --- @param #TASK_PICKUP self
  function TASK_PICKUP._Scheduler()
    self:F2()
  
    return true
  end
  
end



