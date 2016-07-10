--- @module Task_CAS

--- The TASK_CAS class
-- @type TASK_CAS
-- @extends Task#TASK_BASE
TASK_CAS = {
  ClassName = "TASK_CAS",
}

--- Instantiates a new TASK_CAS.
-- @param #TASK_CAS self
-- @param Mission#MISSION Mission
-- @param Set#SET_UNIT UnitSetTargets
-- @param Zone#ZONE_BASE TargetZone
-- @return #TASK_CAS self
function TASK_CAS:New( Mission, TargetSetUnit, TargetZone )
  local self = BASE:Inherit( self, TASK_BASE:New( Mission, "CAS Attack", "CAS", "A2G" ) )
  self:F()

  self.TargetSetUnit = TargetSetUnit
  self.TargetZone = TargetZone

  _EVENTDISPATCHER:OnBirth( self._EventAssignUnit, self )
  _EVENTDISPATCHER:OnPlayerEnterUnit(self._EventAssignUnit, self )
  _EVENTDISPATCHER:OnPlayerLeaveUnit(self._EventUnAssignUnit, self )
  _EVENTDISPATCHER:OnCrash(self._EventUnAssignUnit, self )
  _EVENTDISPATCHER:OnDead(self._EventUnAssignUnit, self )
  _EVENTDISPATCHER:OnPilotDead(self._EventUnAssignUnit, self )

  return self
end

--- Assign the @{Task} to a @{Unit}.
-- @param #TASK_CAS self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_CAS self
function TASK_CAS:AssignToUnit( TaskUnit )
  self:F( TaskUnit:GetName() )

  local ProcessAssign = self:AddProcess( TaskUnit, PROCESS_ASSIGN:New( self, TaskUnit, self.TaskBriefing ) )
  local ProcessRoute = self:AddProcess( TaskUnit, PROCESS_ROUTE:New( self, TaskUnit, self.TargetZone ) )
  local ProcessSEAD = self:AddProcess( TaskUnit, PROCESS_SEAD:New( self, TaskUnit, self.TargetSetUnit ) )
  
  local Process = self:AddStateMachine( TaskUnit, STATEMACHINE_TASK:New( self, {
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
        Assign = {  onstateparent = 'Planned',          oneventparent = 'Next',        fsm = ProcessAssign.Fsm,         event = 'Menu',      returnevents = { 'Next', 'Reject' } },
        Route = {   onstateparent = 'Assigned',         oneventparent = 'Next',         fsm = ProcessRoute.Fsm,         event = 'Route'       },
        Sead = {    onstateparent = 'Assigned',         oneventparent = 'Next',         fsm = ProcessSEAD.Fsm,          event = 'Await',      returnevents = { 'Next' } }
      }
    } ) )
  
  ProcessRoute:AddScore( "Failed", "failed to destroy a ground unit", -100 )
  ProcessSEAD:AddScore( "Destroy", "destroyed a ground unit", 25 )
  ProcessSEAD:AddScore( "Failed", "failed to destroy a ground unit", -100 )
  
  Process:Next()

  return self
end

--- StateMachine callback function for a TASK
-- @param #TASK_CAS self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function TASK_CAS:OnNext( Fsm, Event, From, To, Event )

  self:SetState( self, "State", To )

end

--- @param #TASK_CAS self
function TASK_CAS:_Schedule()
  self:F2()

  self.TaskScheduler = SCHEDULER:New( self, _Scheduler, {}, 15, 15 )
  return self
end


--- @param #TASK_CAS self
function TASK_CAS._Scheduler()
  self:F2()

  return true
end




