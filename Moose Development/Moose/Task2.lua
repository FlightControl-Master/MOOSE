--- @module TASK2

--- The TASK2 class
-- @type TASK2
-- @field Scheduler#SCHEDULER TaskScheduler
-- @extends Base#BASE
TASK2 = {
  ClassName = "TASK",
  TaskScheduler = nil,
  NextEvent = nil,
}

--- Instantiates a new TASK Base. Should never be used. Interface Class.
-- @return #TASK2 self
function TASK2:New( Client )
  local self = BASE:Inherit( self, BASE:New() )
  self:F()

  self.Client = Client
  
  return self
end

--- @param #TASK2 self
function TASK2:Schedule()

  self.TaskScheduler = SCHEDULER:New( self.Fsm, self.Fsm.Assign, { self, self.Client }, 1)
end

--- @param #TASK2 self
function TASK2:NextEvent( NextEvent, ... )
  self:E( NextEvent )

  self.TaskScheduler = SCHEDULER:New( self.Fsm, NextEvent, { self, self.Client, unpack( arg ) }, 1 )
end


