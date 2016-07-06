--- @module Task_SEAD

--- The TASK_SEAD class
-- @type TASK_SEAD
-- @extends Task#TASK_BASE
TASK_SEAD = {
  ClassName = "TASK_SEAD",
}

--- Instantiates a new TASK_SEAD. Should never be used. Interface Class.
-- @param #TASK_SEAD self
-- @param Set#SET_UNIT UnitSetTargets
-- @return #TASK_SEAD self
function TASK_SEAD:New( TargetSetUnit, TargetZone )
  local self = BASE:Inherit( self, BASE:New() )
  self:F()

  self.TargetSetUnit= TargetSetUnit
  self.TargetZone = TargetZone

  return self
end

--- Assign the @{Task} to a @{Unit}.
-- @param #TASK_SEAD self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_SEAD self
function TASK_SEAD:AssignToUnit( TaskUnit )

  local ProcessRoute = self:AddProcess( TaskUnit, PROCESS_ROUTE:New( self, TaskUnit, self.TargetZone ) )
  local ProcessSEAD = self:AddProcess( TaskUnit, PROCESS_SEAD:New( self, TaskUnit, self.TargetUnitSet ) )
  
  local Process = self:AddStateMachine( TaskUnit, STATEMACHINE:New( {
      initial = 'None',
      events = {
        { name = 'Start',   from = 'None',          to = 'Assigned' },
        { name = 'Next',    from = 'Unassigned',    to = 'Assigned' },
        { name = 'Next',    from = 'Assigned',      to = 'Success' },
        { name = 'Fail',    from = 'Assigned',      to = 'Failed' }, 
        { name = 'Fail',    from = 'Arrived',       to = 'Failed' }     
      },
      subs = {
        Route = {   onstateparent = 'Assigned',         oneventparent = 'Start',        fsm = ProcessRoute.Fsm,         event = 'Route'       },
        Sead = {    onstateparent = 'Assigned',         oneventparent = 'Next',         fsm = ProcessSEAD.Fsm,          event = 'Await',      returnevents = { 'Next' } }
      }
    } ) )
  
  ---Task_Client_Sead:AddScore( "Destroy", "Destroyed RADAR", 25 )
  ---Task_Client_Sead:AddScore( "Success", "Destroyed all radars!!!", 100 )
  
  Process:Start()

  return self
end

--- @param #TASK_SEAD self
function TASK_SEAD:_Schedule()
  self:F2()

  self.TaskScheduler = SCHEDULER:New( self, _Scheduler, {}, 15, 15 )
  return self
end


--- @param #TASK_SEAD self
function TASK_SEAD._Scheduler()
  self:F2()

  return true
end




