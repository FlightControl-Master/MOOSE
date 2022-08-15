--- **Ops** - PlayerTask (mission) for Players.
--
-- ## Main Features:
--
--    * Simplifies defining and executing Player tasks
--    * FSM events when a mission is done, successful or failed
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/).
--
-- ===
--
-- ### Author: **Applevangelist**
--
-- ===
-- @module Ops.PlayerTask
-- @image OPS_PlayerTask.png


--- PLAYERTASK class.
-- @type PLAYERTASK
-- @field #string ClassName Name of the class.
-- @field #boolean verbose Switch verbosity.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number PlayerTaskNr (Globally unique) Number of the task.
-- @field Ops.Auftrag#AUFTRAG.Type Type The type of the task
-- @field Ops.Target#TARGET Target The target for this Task
-- @field Utilities.FiFo#FIFO Clients FiFo of Wrapper.Client#CLIENT planes executing this task
-- @field #boolean Repeat
-- @field #number repeats
-- @field #number RepeatNo
-- @field Wrapper.Marker#MARKER TargetMarker
-- @field #number SmokeColor
-- @field #number FlareColor
-- @field #table conditionSuccess   =   {},
-- @field #table conditionFailure   =   {},
-- @field Ops.PlayerTask#PLAYERTASKCONTROLLER TaskController
-- @field #number timestamp
--
-- @extends Core.Fsm#FSM

-------------------------------------------------------------------------------------------------------------------
-- PLAYERTASK
-- TODO: PLAYERTASK
-------------------------------------------------------------------------------------------------------------------

--- Global PlayerTaskNr counter
_PlayerTaskNr = 0

---
-- @field #PLAYERTASK
PLAYERTASK = {
  ClassName          = "PLAYERTASK",
  verbose            =   false,
  lid                =   nil,
  PlayerTaskNr       =   nil,
  Type               =   nil,
  TTSType            =   nil,
  Target             =   nil,
  Clients            =   nil,
  Repeat             =   false,
  repeats            =   0,
  RepeatNo           =   1,
  TargetMarker       =   nil,
  SmokeColor         =   nil,
  FlareColor         =   nil,
  conditionSuccess   =   {},
  conditionFailure   =   {},
  TaskController     =   nil,
  timestamp          =   0,
  }
  
--- PLAYERTASK class version.
-- @field #string version
PLAYERTASK.version="0.0.8"

--- Generic task condition.
-- @type PLAYERTASK.Condition
-- @field #function func Callback function to check for a condition. Should return a #boolean.
-- @field #table arg Optional arguments passed to the condition callback function.

--- Constructor
-- @param #PLAYERTASK self
-- @param Ops.Auftrag#AUFTRAG.Type Type Type of this task
-- @param Ops.Target#TARGET Target Target for this task
-- @param #boolean Repeat Repeat this task if true (default = false)
-- @param #number Times Repeat on failure this many times if Repeat is true (default = 1)
-- @return #PLAYERTASK self 
function PLAYERTASK:New(Type, Target, Repeat, Times, TTSType)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #PLAYERTASK
  
  self.Type = Type
  
  self.Repeat = false
  self.repeats = 0
  self.RepeatNo = 1
  self.Clients = FIFO:New() -- Utilities.FiFo#FIFO
  self.TargetMarker = nil -- Wrapper.Marker#MARKER
  self.SmokeColor = SMOKECOLOR.Red
  self.conditionSuccess = {}
  self.conditionFailure = {}
  self.TaskController = nil -- Ops.PlayerTask#PLAYERTASKCONTROLLER
  self.timestamp = timer.getTime()
  self.TTSType = TTSType or "close air support"
  
  if Repeat then
    self.Repeat = true
    self.RepeatNo = Times or 1
  end
  
  _PlayerTaskNr = _PlayerTaskNr + 1
  
  self.PlayerTaskNr = _PlayerTaskNr
  
  self.lid=string.format("PlayerTask #%d %s | ", self.PlayerTaskNr, tostring(self.Type))
  
  if Target and Target.ClassName and Target.ClassName == "TARGET" then
    self.Target = Target
  elseif Target and Target.ClassName then
    self.Target = TARGET:New(Target)
  else
    self:E(self.lid.."*** NO VALID TARGET!")
    return self
  end
  
  self:T(self.lid.."Created.")
  
  -- FMS start state is PLANNED.
  self:SetStartState("Planned")

  -- PLANNED --> REQUESTED --> EXECUTING --> DONE
  self:AddTransition("*",            "Planned",          "Planned")   -- Task is in planning stage. 
  self:AddTransition("*",            "Requested",        "Requested")   -- Task clients have been requested to join.
  self:AddTransition("*",            "ClientAdded",      "*")  -- Client has been added to the task
  self:AddTransition("*",            "ClientRemoved",    "*")  -- Client has been added to the task
  self:AddTransition("*",            "Executing",        "Executing")   -- First client is executing the Task.
  self:AddTransition("*",            "Done",             "Done")   -- All clients have reported that Task is done.
  self:AddTransition("*",            "Cancel",           "Done")   -- Command to cancel the Task.
  self:AddTransition("*",            "Success",          "Done")
  self:AddTransition("*",            "ClientAborted",    "*")
  self:AddTransition("*",            "Failed",           "*") -- Done or repeat --> PLANNED
  self:AddTransition("*",            "Status",           "*")
  self:AddTransition("*",            "Stop",             "Stopped")
  
  self:__Status(-5)
  return self
  
  ---
  -- Pseudo Functions
  ---
  
  --- On After "Planned" event. Task has been planned.
  -- @function [parent=#PLAYERTASK] OnAfterPlanned
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "Requested" event. Task has been Requested.
  -- @function [parent=#PLAYERTASK] OnAfterRequested
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
   
  --- On After "ClientAdded" event. Client has been added to the task.
  -- @function [parent=#PLAYERTASK] OnAfterClientAdded
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Client#CLIENT Client
   
  --- On After "ClientRemoved" event. Client has been removed from the task.
  -- @function [parent=#PLAYERTASK] OnAfterClientRemoved
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
   
  --- On After "Executing" event. Task is executed by the 1st client.
  -- @function [parent=#PLAYERTASK] OnAfterExecuting
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
   
  --- On After "Done" event. Task is done.
  -- @function [parent=#PLAYERTASK] OnAfterDone
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
   
  --- On After "Cancel" event. Task has been cancelled.
  -- @function [parent=#PLAYERTASK] OnAfterCancel
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
   
  --- On After "Planned" event. Task has been planned.
  -- @function [parent=#PLAYERTASK] OnAfterPilotPlanned
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
   
  --- On After "Success" event. Task has been a success.
  -- @function [parent=#PLAYERTASK] OnAfterSuccess
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
   
  --- On After "ClientAborted" event. A client has aborted the task.
  -- @function [parent=#PLAYERTASK] OnAfterClientAborted
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
   
  --- On After "Failed" event. Task has been a failure.
  -- @function [parent=#PLAYERTASK] OnAfterFailed
  -- @param #PLAYERTASK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
end

--- [Internal] Add a PLAYERTASKCONTROLLER for this task
-- @param #PLAYERTASK self
-- @param Ops.PlayerTask#PLAYERTASKCONTROLLER Controller
-- @return #PLAYERTASK self
function PLAYERTASK:_SetController(Controller)
  self:T(self.lid.."_SetController")
  self.TaskController = Controller
  return self
end

--- [User] Check if task is done
-- @param #PLAYERTASK self
-- @return #boolean done
function PLAYERTASK:IsDone()
  self:T(self.lid.."IsDone?")
  local IsDone = false
  local state = self:GetState()
  if state == "Done" or state == "Stopped" then
    IsDone = true
  end
  return IsDone
end

--- [User] Get clients assigned list as table
-- @param #PLAYERTASK self
-- @return #table clients
function PLAYERTASK:GetClients()
  self:T(self.lid.."GetClients")
  local clientlist = self.Clients:GetIDStackSorted() or {}
  return clientlist
end

--- [User] Count clients
-- @param #PLAYERTASK self
-- @return #number clientcount
function PLAYERTASK:CountClients()
  self:T(self.lid.."CountClients")
  return self.Clients:Count()
end

--- [User] Check if a player name is assigned to this task
-- @param #PLAYERTASK self
-- @param #string Name
-- @return #boolean HasName
function PLAYERTASK:HasPlayerName(Name)
  self:T(self.lid.."HasPlayerName?")
  return self.Clients:HasUniqueID(Name)
end

--- [User] Add a client to this task
-- @param #PLAYERTASK self
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASK self
function PLAYERTASK:AddClient(Client)
  self:T(self.lid.."AddClient")
  local name = Client:GetPlayerName()
  if not self.Clients:HasUniqueID(name) then
    self.Clients:Push(Client,name)
    self:__ClientAdded(-2,Client)
  end
  return self
end

--- [User] Remove a client from this task
-- @param #PLAYERTASK self
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASK self
function PLAYERTASK:RemoveClient(Client)
  self:T(self.lid.."RemoveClient")
  local name = Client:GetPlayerName()
  if self.Clients:HasUniqueID(name) then
    self.Clients:PullByID(name)
    if self.verbose then
      self.Clients:Flush()
    end
    self:__ClientRemoved(-2,Client)
    if self.Clients:Count() == 0 then
      self:__Failed(-1)
    end
  end
  return self
end

--- [User] Client has aborted task this task
-- @param #PLAYERTASK self
-- @param Wrapper.Client#CLIENT Client (optional)
-- @return #PLAYERTASK self
function PLAYERTASK:ClientAbort(Client)
  self:T(self.lid.."ClientAbort")
  if Client and Client:IsAlive() then
    self:RemoveClient(Client)
    self:__ClientAborted(-1,Client)
    return self
  else
    -- no client given, abort whole task if no one else is assigned
    if self.Clients:Count() == 0 then
      -- return to planned state if repeat    
      self:__Failed(-1)
    end
  end
  return self
end

--- [User] Create target mark on F10 map
-- @param #PLAYERTASK self
-- @return #PLAYERTASK self
function PLAYERTASK:MarkTargetOnF10Map()
  self:T(self.lid.."MarkTargetOnF10Map")
  if self.Target then
    local coordinate = self.Target:GetCoordinate()
    if coordinate then
      if self.TargetMarker then
        -- Marker exists, delete one first
        self.TargetMarker:Remove()
      end
      self.TargetMarker = MARKER:New(coordinate,"Target of "..self.lid)
      self.TargetMarker:ReadOnly()
      self.TargetMarker:ToAll()
    end
  end
  return self
end

--- [User] Smoke Target
-- @param #PLAYERTASK self
-- @param #number Color, defaults to SMOKECOLOR.Red
-- @return #PLAYERTASK self
function PLAYERTASK:SmokeTarget(Color)
  self:T(self.lid.."SmokeTarget")
  local color = Color or SMOKECOLOR.Red
  if self.Target then
    local coordinate = self.Target:GetCoordinate()
    if coordinate then
      coordinate:Smoke(color)
    end
  end
  return self
end

--- [User] Flare Target
-- @param #PLAYERTASK self
-- @param #number Color, defaults to FLARECOLOR.Red
-- @return #PLAYERTASK self
function PLAYERTASK:FlareTarget(Color)
  self:T(self.lid.."SmokeTarget")
  local color = Color or FLARECOLOR.Red
  if self.Target then
    local coordinate = self.Target:GetCoordinate()
    if coordinate then
      coordinate:Flare(color,0)
    end
  end
  return self
end

-- success / failure function addion courtesy @FunkyFranky.

--- [User] Add success condition.
-- @param #PLAYERTASK self
-- @param #function ConditionFunction If this function returns `true`, the mission is cancelled.
-- @param ... Condition function arguments if any.
-- @return #PLAYERTASK self
function PLAYERTASK:AddConditionSuccess(ConditionFunction, ...)

  local condition={} --#PLAYERTASK.Condition

  condition.func=ConditionFunction
  condition.arg={}
  if arg then
    condition.arg=arg
  end

  table.insert(self.conditionSuccess, condition)

  return self
end

--- [User] Add failure condition.
-- @param #PLAYERTASK self
-- @param #function ConditionFunction If this function returns `true`, the task is cancelled.
-- @param ... Condition function arguments if any.
-- @return #PLAYERTASK self
function PLAYERTASK:AddConditionFailure(ConditionFunction, ...)

  local condition={} --#PLAYERTASK.Condition

  condition.func=ConditionFunction
  condition.arg={}
  if arg then
    condition.arg=arg
  end

  table.insert(self.conditionFailure, condition)

  return self
end

--- [Internal] Check if any of the given conditions is true.
-- @param #PLAYERTASK self
-- @param #table Conditions Table of conditions.
-- @return #boolean If true, at least one condition is true.
function PLAYERTASK:_EvalConditionsAny(Conditions)

  -- Any stop condition must be true.
  for _,_condition in pairs(Conditions or {}) do
    local condition=_condition --#AUFTRAG.Condition

    -- Call function.
    local istrue=condition.func(unpack(condition.arg))

    -- Any true will return true.
    if istrue then
      return true
    end

  end

  -- No condition was true.
  return false
end

--- [Internal] On after status call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASK self
function PLAYERTASK:onafterStatus(From, Event, To)
  self:T({From, Event, To})
  self:T(self.lid.."onafterStatus")
  
  local status = self:GetState()
  
  -- Check Target status
  local targetdead = false
  if self.Target:IsDead() or self.Target:IsDestroyed() then
    targetdead = true
    self:__Success(-2)
    status = "Success"
    return self
  end
    
  if status == "Executing" then    
    -- Check Clients alive
    local clientsalive = false
    local ClientTable = self.Clients:GetDataTable()
    for _,_client in pairs(ClientTable) do
      local client = _client -- Wrapper.Client#CLIENT
      if client:IsAlive() then
        clientsalive=true -- one or more clients alive
      end
    end
    
    -- Failed?
    if status == "Executing" and (not clientsalive) and (not targetdead) then
      self:__Failed(-2)
      status = "Failed"
    end
    
    -- Any success condition true?
    local successCondition=self:_EvalConditionsAny(self.conditionSuccess)
  
    -- Any failure condition true?
    local failureCondition=self:_EvalConditionsAny(self.conditionFailure)
  
    if failureCondition then
      self:__Failed(-2)
      status = "Failed"
    elseif successCondition then
      self:__Success(-2)
      status = "Success"
    end
    
    if self.verbose then
      self:I(self.lid.."Target dead: "..tostring(targetdead).." | Clients alive: " .. tostring(clientsalive))
    end
  end
  
  -- Continue if we are not done
  if status ~= "Done" then
    self:__Status(-20)
  else
    self:__Stop(-1)
  end
  
  return self
end


--- [Internal] On after planned call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASK self
function PLAYERTASK:onafterPlanned(From, Event, To)
  self:T({From, Event, To})
  return self
end

--- [Internal] On after requested call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASK self
function PLAYERTASK:onafterRequested(From, Event, To)
  self:T({From, Event, To})
  return self
end

--- [Internal] On after executing call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASK self
function PLAYERTASK:onafterExecuting(From, Event, To)
  self:T({From, Event, To})
  return self
end

--- [Internal] On after status call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASK self
function PLAYERTASK:onafterStop(From, Event, To)
  self:T({From, Event, To})
  return self
end

--- [Internal] On after client added call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASK self
function PLAYERTASK:onafterClientAdded(From, Event, To, Client)
  self:T({From, Event, To})
  if Client and self.verbose then
    local text = string.format("Player %s joined task %d!",Client:GetPlayerName() or "Generic",self.PlayerTaskNr)
    self:I(self.lid..text)
  end
  return self
end

--- [Internal] On after done call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASK self
function PLAYERTASK:onafterDone(From, Event, To)
  self:T({From, Event, To})
  if self.TaskController then
    self.TaskController:__TaskDone(-1,self)
  end
  self:__Stop(-1)
  return self
end

--- [Internal] On after cancel call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASK self
function PLAYERTASK:onafterCancel(From, Event, To)
  self:T({From, Event, To})
  if self.TaskController then
    self.TaskController:__TaskCancelled(-1,self)
  end
  self:__Done(-1)
  return self
end

--- [Internal] On after success call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASK self
function PLAYERTASK:onafterSuccess(From, Event, To)
  self:T({From, Event, To})
  if self.TaskController then
    self.TaskController:__TaskSuccess(-1,self)
  end
  if self.TargetMarker then
    self.TargetMarker:Remove()
  end
  self:__Done(-1)
  return self
end

--- [Internal] On after failed call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASK self
function PLAYERTASK:onafterFailed(From, Event, To)
  self:T({From, Event, To})
  self.repeats = self.repeats + 1
  -- repeat on failed?
  if self.Repeat and (self.repeats <= self.RepeatNo) then
    if self.TaskController then
      self.TaskController:__TaskRepeatOnFailed(-1,self)
    end
    self:__Planned(-1)
    return self
  else
    if self.TargetMarker then
      self.TargetMarker:Remove()
    end
    if self.TaskController then
      self.TaskController:__TaskFailed(-1,self)
    end
    self:__Done(-1)
  end
  return self
end

-------------------------------------------------------------------------------------------------------------------
-- PLAYERTASKCONTROLLER
-- TODO: PLAYERTASKCONTROLLER
-------------------------------------------------------------------------------------------------------------------

--- PLAYERTASKCONTROLLER class.
-- @type PLAYERTASKCONTROLLER
-- @field #string ClassName Name of the class.
-- @field #boolean verbose Switch verbosity.
-- @field #string lid Class id string for output to DCS log file.
-- @field Utilities.FiFo#FIFO TargetQueue
-- @field Utilities.FiFo#FIFO TaskQueue
-- @field Utilities.FiFo#FIFO TasksPerPlayer
-- @field Core.Set#SET_CLIENT ClientSet
-- @field #string ClientFilter
-- @field #string Name
-- @field #string Type
-- @field #boolean UseGroupNames
-- @field #table PlayerMenu
-- @field #boolean usecluster
-- @field #number ClusterRadius
-- @field #string MenuName
-- 


---
-- @field #PLAYERTASKCONTROLLER
PLAYERTASKCONTROLLER = {
  ClassName          = "PLAYERTASKCONTROLLER",
  verbose            =   true,
  lid                =   nil,
  TargetQueue        =   nil,
  ClientSet          =   nil,
  UseGroupNames      =   true,
  PlayerMenu         =   {},
  usecluster         =   false,
  MenuName           =   nil,
  ClusterRadius      =   1250,
  }

---
-- @field Type
PLAYERTASKCONTROLLER.Type = {
  A2A = "Air-To-Air",
  A2G = "Air-To-Ground",
  A2S = "Air-To-Sea",
}
  
--- PLAYERTASK class version.
-- @field #string version
PLAYERTASKCONTROLLER.version="0.0.11"

--- Constructor
-- @param #PLAYERTASKCONTROLLER self
-- @param #string Name Name of this controller
-- @param #number Coalition of this controller, e.g. coalition.side.BLUE
-- @param #string Type Type of the tasks controlled, defaults to PLAYERTASKCONTROLLER.Type.A2G
-- @param #string ClientFilter (optional) Additional prefix filter for the SET_CLIENT
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:New(Name, Coalition, Type, ClientFilter)
  
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #PLAYERTASKCONTROLLER
  
  self.Name = Name or "CentCom"
  self.Coalition = Coalition or coalition.side.BLUE
  self.CoalitionName = UTILS.GetCoalitionName(Coalition)
  self.Type = Type or PLAYERTASKCONTROLLER.Type.A2G
  
  self.usecluster = false
  if self.Type == PLAYERTASKCONTROLLER.Type.A2A then
    self.usecluster = true
  end
  
  self.ClusterRadius = 1250
  
  self.ClientFilter = ClientFilter or ""
  
  self.TargetQueue = FIFO:New() -- Utilities.FiFo#FIFO
  self.TaskQueue = FIFO:New() -- Utilities.FiFo#FIFO
  self.TasksPerPlayer = FIFO:New() -- Utilities.FiFo#FIFO
  self.PlayerMenu = {} -- #table
  
  self.MenuName = nil
  
  self.repeatonfailed = true
  self.repeattimes = 5
  self.UseGroupNames = true
  
  if ClientFilter then
    self.ClientSet = SET_CLIENT:New():FilterCoalitions(string.lower(self.CoalitionName)):FilterActive(true):FilterPrefixes(ClientFilter):FilterStart()
  else
    self.ClientSet = SET_CLIENT:New():FilterCoalitions(string.lower(self.CoalitionName)):FilterActive(true):FilterStart()
  end
  
  self.lid=string.format("PlayerTaskController %s %s | ", self.Name, tostring(self.Type))
  
  -- FSM start state is STOPPED.
  self:SetStartState("Stopped")
  
  self:AddTransition("Stopped",      "Start",                 "Running")
  self:AddTransition("*",            "Status",                "*")
  self:AddTransition("*",            "TaskAdded",             "*")
  self:AddTransition("*",            "TaskDone",              "*")
  self:AddTransition("*",            "TaskCancelled",         "*")
  self:AddTransition("*",            "TaskSuccess",           "*")
  self:AddTransition("*",            "TaskFailed",            "*")
  self:AddTransition("*",            "TaskRepeatOnFailed",    "*")
  self:AddTransition("*",            "Stop",                  "Stopped")
  
  self:__Start(-1)
  self:__Status(-2)
  
  -- Player leaves
  self:HandleEvent(EVENTS.PlayerLeaveUnit, self._EventHandler)
  self:HandleEvent(EVENTS.Ejection, self._EventHandler)
  self:HandleEvent(EVENTS.Crash, self._EventHandler)
  self:HandleEvent(EVENTS.PilotDead, self._EventHandler)
  self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
  
  self:I(self.lid.."Started.")
  
  return self
  
  ---
  -- Pseudo Functions
  ---
  
  --- On After "TaskAdded" event. Task has been added.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskAdded
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task
  
   --- On After "TaskDone" event. Task is done.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskDone
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task
   
  --- On After "TaskCancelled" event. Task has been cancelled.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskCancelled
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task
   
  --- On After "TaskFailed" event. Task has failed.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskFailed
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task
   
  --- On After "TaskSuccess" event. Task has been a success.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskSuccess
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task
   
  --- On After "TaskRepeatOnFailed" event. Task has failed and will be repeated.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskRepeatOnFailed
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task
  
end

--- [internal] Event handling
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Event#EVENTDATA EventData
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_EventHandler(EventData)
  self:T(self.lid.."_EventHandler: "..EventData.id)
  if EventData.id == EVENTS.PlayerLeaveUnit or EventData.id == EVENTS.Ejection or EventData.id == EVENTS.Crash or EventData.id == EVENTS.PilotDead then
    if EventData.IniPlayerName then
      self:T(self.lid.."Event for player: "..EventData.IniPlayerName)
      if self.PlayerMenu[EventData.IniPlayerName] then
        self.PlayerMenu[EventData.IniPlayerName]:Remove()
        self.PlayerMenu[EventData.IniPlayerName] = nil
      end
        local text = ""
        if self.TasksPerPlayer:HasUniqueID(EventData.IniPlayerName) then
          local task = self.TasksPerPlayer:PullByID(EventData.IniPlayerName) -- Ops.PlayerTask#PLAYERTASK
          local Client = _DATABASE:FindClient( EventData.IniPlayerName )
          if Client then
            task:RemoveClient(Client)
            text = "Task aborted!"
          end
        else
          text = "No active task!"
        end
        self:T(self.lid..text) 
    end
  elseif EventData.id == EVENTS.PlayerEnterAircraft then
    if EventData.IniPlayerName and EventData.IniGroup and self.UseSRS then
      self:T(self.lid.."Event for player: "..EventData.IniPlayerName)
      local frequency = self.Frequency
      if type(frequency) == "table" then frequency = frequency[1] end
      local modulation = self.Modulation
      if type(modulation) == "table" then modulation = modulation[1] end
      modulation = UTILS.GetModulationName(modulation)
      local text = string.format("%s, %s, switch to frequency %.3f for task assignment!",EventData.IniPlayerName,self.MenuName or self.Name,frequency)
      --local m = MESSAGE:New(text,30,"Tasking",true):ToGroup(EventData.IniGroup)
      self.SRSQueue:NewTransmission(text,nil,self.SRS,timer.getAbsTime()+60,2,{EventData.IniGroup},text,30,self.BCFrequency,self.BCModulation)
    end
  end
  return self
end

function PLAYERTASKCONTROLLER:_DummyMenu(group)
  self:T(self.lid.."_DummyMenu")
  return self
end

--- [User] Set the cluster radius if you want to use target clusters rather than single group detection. 
-- Note that for a controller type A2A target clustering is on by default. Also remember that the diameter of the resulting zone is double the radius.
-- @param #PLAYERTASKCONTROLLER self
-- @param #number Radius Target cluster radius in meters. Default is 1250m or 0.67NM
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetClusterRadius(Radius)
  self:T(self.lid.."SetClusterRadius")
  self.ClusterRadius = Radius or 1250
  self.usecluster = true
  return self
end

--- [User] Manually cancel a specific task
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.PlayerTask#PLAYERTASK Task The task to be cancelled
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:CancelTask(Task)
  self:T(self.lid.."CancelTask")
  Task:__Cancel(-1)
  return self
end

--- [User] Switch usage of target names for menu entries on or off
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean OnOff If true, set to on (default), if nil or false, set to off
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SwitchUseGroupNames(OnOff)
  self:T(self.lid.."SwitchUseGroupNames")
  if OnOff then
    self.UseGroupNames = true
  else
   self.UseGroupNames = false
  end
  return self
end

--- [Internal] Get task types for the menu
-- @param #PLAYERTASKCONTROLLER self
-- @return #table TaskTypes
function PLAYERTASKCONTROLLER:_GetAvailableTaskTypes()
  self:T(self.lid.."_GetAvailableTaskTypes")
  local tasktypes = {}
  self.TaskQueue:ForEach(
    function (Task)
      local task = Task -- Ops.PlayerTask#PLAYERTASK
      local type = Task.Type
      tasktypes[type] = {}
    end
  )
  return tasktypes
end

--- [Internal] Get task per type for the menu
-- @param #PLAYERTASKCONTROLLER self
-- @return #table TasksPerTypes
function PLAYERTASKCONTROLLER:_GetTasksPerType()
  self:T(self.lid.."_GetTasksPerType")
  local tasktypes = self:_GetAvailableTaskTypes()
  
  self:T({tasktypes})
  
  -- Sort tasks per threat level first
  local datatable = self.TaskQueue:GetDataTable()
  local threattable = {}
  for _,_task in pairs(datatable) do
    local task = _task -- Ops.PlayerTask#PLAYERTASK
    local threat = task.Target:GetThreatLevelMax()
    threattable[#threattable+1]={task=task,threat=threat}
  end
  
  table.sort(threattable, function (k1, k2) return k1.threat > k2.threat end )
  

  for _id,_data in pairs(threattable) do
    local threat=_data.threat
    local task = _data.task -- Ops.PlayerTask#PLAYERTASK
    local type = task.Type
      if task:GetState() ~= "Executing" and not task:IsDone() then
        table.insert(tasktypes[type],task)
      end
  end
  
  return tasktypes
end

--- [Internal] Check target queue
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_CheckTargetQueue()
 self:T(self.lid.."_CheckTargetQueue")
 if self.TargetQueue:Count() > 0 then
  local object = self.TargetQueue:Pull()
  local target = TARGET:New(object)
  self:_AddTask(target)
 end  
 return self
end

--- [Internal] Check task queue
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_CheckTaskQueue()
 self:T(self.lid.."_CheckTaskQueue")
 if self.TaskQueue:Count() > 0 then
   -- remove done tasks
   local tasks = self.TaskQueue:GetIDStack()
   for _id,_entry in pairs(tasks) do
    local data = _entry.data -- Ops.PlayerTask#PLAYERTASK
    self:T("Looking at Task: "..data.PlayerTaskNr.." Type: "..data.Type.." State: "..data:GetState())
    if data:GetState() == "Done" or data:GetState() == "Stopped" then
      local task = self.TaskQueue:ReadByID(_id) -- Ops.PlayerTask#PLAYERTASK
      -- DONE: Remove clients from the task
      local clientsattask = task.Clients:GetIDStackSorted()
      for _,_id in pairs(clientsattask) do
        self:T("*****Removing player " .. _id)
        self.TasksPerPlayer:PullByID(_id)
      end
      local task = self.TaskQueue:PullByID(_id) -- Ops.PlayerTask#PLAYERTASK
      task = nil
    end
   end
 end  
 return self
end

--- [Internal] Check task queue for a specific player name
-- @param #PLAYERTASKCONTROLLER self
-- @return #boolean outcome
function PLAYERTASKCONTROLLER:_CheckPlayerHasTask(PlayerName)
  self:T(self.lid.."_CheckPlayerHasTask")
  return self.TasksPerPlayer:HasUniqueID(PlayerName)
end

--- [User] Add a target object to the target queue
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Positionable#POSITIONABLE Target The target GROUP, SET\_GROUP, UNIT, SET\_UNIT, STATIC, SET\_STATIC, AIRBASE or COORDINATE.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddTarget(Target)
  self:T(self.lid.."AddTarget")
  self.TargetQueue:Push(Target)
  return self
end

--- [Internal] Add a task to the task queue
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.Target#TARGET Target
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_AddTask(Target)
  self:T(self.lid.."_AddTask")
  local cat = Target:GetCategory()
  local type = AUFTRAG.Type.CAS
  local ttstype = "close air support"
  
  if cat == TARGET.Category.GROUND then
    type = AUFTRAG.Type.CAS
    -- TODO: debug BAI, CAS, SEAD
    local targetobject = Target:GetObject() -- Wrapper.Positionable#POSITIONABLE
    if targetobject:IsInstanceOf("UNIT") then
      self:T("SEAD Check UNIT")
      if targetobject:HasSEAD() then
        type = AUFTRAG.Type.SEAD
        ttstype = "suppress air defense"
      end
    elseif targetobject:IsInstanceOf("GROUP") then
      self:T("SEAD Check GROUP")
      local attribute = targetobject:GetAttribute()
      if attribute == GROUP.Attribute.GROUND_SAM or attribute == GROUP.Attribute.GROUND_AAA then
        type = AUFTRAG.Type.SEAD
        ttstype = "suppress air defense"
      end
    elseif targetobject:IsInstanceOf("SET_GROUP") then
      self:T("SEAD Check SET_GROUP")
      targetobject:ForEachGroup(
        function (group)
          local attribute = group:GetAttribute()
          if attribute == GROUP.Attribute.GROUND_SAM or attribute == GROUP.Attribute.GROUND_AAA then
            type = AUFTRAG.Type.SEAD
            ttstype = "suppress air defense"
          end
        end
      )     
    elseif targetobject:IsInstanceOf("SET_UNIT") then
      self:T("SEAD Check SET_UNIT")
      targetobject:ForEachUnit(
        function (unit)
          if unit:HasSEAD() then
            type = AUFTRAG.Type.SEAD
            ttstype = "suppress air defenses"
          end
        end
      )
    end
    -- if there are no friendlies nearby ~2km and task isn't SEAD, then it's BAI
    local targetcoord = Target:GetCoordinate()
    local targetvec2 = targetcoord:GetVec2()
    local targetzone = ZONE_RADIUS:New(self.Name,targetvec2,2000)
    local coalition = targetobject:GetCoalitionName() or "Blue"
    coalition = string.lower(coalition)
    self:T("Target coalition is "..tostring(coalition))
    local filtercoalition = "blue"
    if coalition == "blue" then filtercoalition = "red" end
    local friendlyset = SET_GROUP:New():FilterCategoryGround():FilterCoalitions(filtercoalition):FilterZones({targetzone}):FilterOnce()
    if friendlyset:Count() == 0 and type ~= AUFTRAG.Type.SEAD then
      type = AUFTRAG.Type.BAI
      ttstype = "battle field air interdiction"
    end
  elseif cat == TARGET.Category.NAVAL then
    type = AUFTRAG.Type.ANTISHIP
    ttstype = "anti-ship"
  elseif cat == TARGET.Category.AIRCRAFT then
    type = AUFTRAG.Type.INTERCEPT
    ttstype = "intercept"
  elseif cat == TARGET.Category.AIRBASE then
    --TODO: Define Success Criteria, AB hit? Runway blocked, how to determine? change of coalition?
    type = AUFTRAG.Type.BOMBRUNWAY
    ttstype = "bomb runway"
  elseif cat == TARGET.Category.COORDINATE or cat == TARGET.Category.ZONE then
    --TODO: Define Success Criteria, void of enemies?
    type = AUFTRAG.Type.BOMBING
    ttstype = "bombing"
  end
  
  local task = PLAYERTASK:New(type,Target,self.repeatonfailed,self.repeattimes,ttstype)
  task:_SetController(self)
  self.TaskQueue:Push(task)
  self:__TaskAdded(-1,task)
  return self
end

--- [Internal] Join a player to a task
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_JoinTask(Group, Client, Task)
  self:T(self.lid.."_JoinTask")
  local playername = Client:GetPlayerName()
  if self.TasksPerPlayer:HasUniqueID(playername) then
    -- Player already has a task
    local m=MESSAGE:New("You already have one active task! Complete it first!","10","Info"):ToGroup(Group)
    return self
  end
  Task:AddClient(Client)
  local taskstate = Task:GetState()
  --self:T(self.lid.."Taskstate = "..taskstate)
  if taskstate ~= "Executing"  and taskstate ~= "Done" then
    Task:__Requested(-1)
    Task:__Executing(-2)
    local text = string.format("Pilot %s joined task %d", playername, Task.PlayerTaskNr)
    self:T(self.lid..text)
    local m=MESSAGE:New(text,"10","Info"):ToAll()
    if self.UseSRS then
      self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
    end
    self.TasksPerPlayer:Push(Task,playername)
    -- clear menu
    self:_BuildMenus(Client)
    --[[
    if self.PlayerMenu[playername] then
      self.PlayerMenu[playername]:RemoveSubMenus()
    end
    --]]
  end
  return self
end

--- [Internal] Show active task info
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_ActiveTaskInfo(Group, Client)
  self:T(self.lid.."_ActiveTaskInfo")
  local playername = Client:GetPlayerName()
  local text = ""
  if self.TasksPerPlayer:HasUniqueID(playername) then
    -- TODO: Show multiple?
    local task = self.TasksPerPlayer:GetIDStack()
    local task = self.TasksPerPlayer:ReadByID(playername) -- Ops.PlayerTask#PLAYERTASK
    local taskname = string.format("%s Task ID %02d",task.Type,task.PlayerTaskNr)
    local Coordinate = task.Target:GetCoordinate()
    local CoordText = Coordinate:ToStringA2G(Client)
    local ThreatLevel = task.Target:GetThreatLevelMax()
    local targets = task.Target:CountTargets() or 0
    local clientlist = task:GetClients()
    local ThreatGraph = "[" .. string.rep(  "■", ThreatLevel ) .. string.rep(  "□", 10 - ThreatLevel ) .. "]: "..ThreatLevel
    text = string.format("%s\nThreat: %s\nTargets left: %d\nCoord: %s", taskname, ThreatGraph, targets, CoordText)
    local clienttxt = "\nPilot(s): "
    for _,_name in pairs(clientlist) do
      clienttxt = clienttxt .. _name .. ", "
    end
    clienttxt=string.gsub(clienttxt,", $",".")  
    text = text .. clienttxt  
  else
    text = "No active task!"
  end
  local m=MESSAGE:New(text,15,"Tasking"):ToGroup(Group)
  return self
end

--- [Internal] Mark task on F10 map
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_MarkTask(Group, Client)
  self:T(self.lid.."_ActiveTaskInfo")
  local playername = Client:GetPlayerName()
  local text = ""
  if self.TasksPerPlayer:HasUniqueID(playername) then
    local task = self.TasksPerPlayer:ReadByID(playername) -- Ops.PlayerTask#PLAYERTASK
    task:MarkTargetOnF10Map()
    text = "Task location marked!"
  else
    text = "No active task!"
  end
  local m=MESSAGE:New(text,15,"Info"):ToGroup(Group)
  return self
end

--- [Internal] Smoke task location
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_SmokeTask(Group, Client)
  self:T(self.lid.."_SmokeTask")
  local playername = Client:GetPlayerName()
  local text = ""
  if self.TasksPerPlayer:HasUniqueID(playername) then
    local task = self.TasksPerPlayer:ReadByID(playername) -- Ops.PlayerTask#PLAYERTASK
    task:SmokeTarget()
    text = "Task location smoked!"
  else
    text = "No active task!"
  end
  local m=MESSAGE:New(text,15,"Info"):ToGroup(Group)
  return self
end

--- [Internal] Flare task location
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_FlareTask(Group, Client)
  self:T(self.lid.."_FlareTask")
  local playername = Client:GetPlayerName()
  local text = ""
  if self.TasksPerPlayer:HasUniqueID(playername) then
    local task = self.TasksPerPlayer:ReadByID(playername) -- Ops.PlayerTask#PLAYERTASK
    task:FlareTarget()
    text = "Task location illuminated!"
  else
    text = "No active task!"
  end
  local m=MESSAGE:New(text,15,"Info"):ToGroup(Group)
  return self
end

--- [Internal] Abort Task
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_AbortTask(Group, Client)
  self:T(self.lid.."_FlareTask")
  local playername = Client:GetPlayerName()
  local text = ""
  if self.TasksPerPlayer:HasUniqueID(playername) then
    local task = self.TasksPerPlayer:PullByID(playername) -- Ops.PlayerTask#PLAYERTASK
    task:ClientAbort(Client)
    text = "Task aborted!"
  else
    text = "No active task!"
  end
  local m=MESSAGE:New(text,15,"Info"):ToGroup(Group)
  self:_BuildMenus(Client)
  return self
end

--- [Internal] Build client menus
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Client#CLIENT Client (optional) build for this client name only
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_BuildMenus(Client)
  self:T(self.lid.."_BuildMenus")
  local clients = self.ClientSet:GetAliveSet()
  if Client then
    clients = {Client}
  end
  for _,_client in pairs(clients) do
    if _client then
      local client = _client -- Wrapper.Client#CLIENT
      local group = client:GetGroup()
      local playername = client:GetPlayerName() or "Unknown"
      if group and client then
        ---
        -- TOPMENU
        --- 
        local menuname = self.MenuName or self.Name.." Tasking "..self.Type
        local topmenu = MENU_GROUP:New(group,menuname,nil)
        
        if self.PlayerMenu[playername] then
          self.PlayerMenu[playername]:RemoveSubMenus()
        else
          self.PlayerMenu[playername] = topmenu
        end
        
        ---
        -- ACTIVE TASK MENU
        ---
        if self:_CheckPlayerHasTask(playername) then
          local active = MENU_GROUP:New(group,"Active Task",topmenu)
          local info = MENU_GROUP_COMMAND:New(group,"Info",active,self._ActiveTaskInfo,self,group,client)
          local mark = MENU_GROUP_COMMAND:New(group,"Mark on map",active,self._MarkTask,self,group,client)
          if self.Type ~= PLAYERTASKCONTROLLER.Type.A2A then
            -- no smoking/flaring here if A2A
            local smoke = MENU_GROUP_COMMAND:New(group,"Smoke",active,self._SmokeTask,self,group,client)
            local flare = MENU_GROUP_COMMAND:New(group,"Flare",active,self._FlareTask,self,group,client)
          end
          local abort = MENU_GROUP_COMMAND:New(group,"Abort",active,self._AbortTask,self,group,client)
        elseif self.TaskQueue:Count() > 0 then
        ---
        -- JOIN TASK MENU
        --- 
          local tasktypes = self:_GetAvailableTaskTypes()
          local taskpertype = self:_GetTasksPerType()
          
          local joinmenu = MENU_GROUP:New(group,"Join Task",topmenu)
          
          local ttypes = {}
          local taskmenu = {}
          for _tasktype,_data in pairs(tasktypes) do
            ttypes[_tasktype] = MENU_GROUP:New(group,_tasktype,joinmenu)
            local tasks =  taskpertype[_tasktype] or {}
            for _,_task in pairs(tasks) do
              _task = _task -- Ops.PlayerTask#PLAYERTASK
              local pilotcount = _task:CountClients()
              local newtext = "]"
              local tnow = timer.getTime()
              -- marker for new tasks
              if tnow - _task.timestamp < 60 then
                newtext = "*]"
              end
              local text = string.format("TaskNo %03d [%d%s",_task.PlayerTaskNr,pilotcount,newtext)
              if self.UseGroupNames then
                local name = _task.Target:GetName()
                if name ~= "Unknown" then
                  text = string.format("%s (%03d) [%d%s",name,_task.PlayerTaskNr,pilotcount,newtext)
                end
              end
              if _task:GetState() == "Planned" or (not _task:HasPlayerName(playername)) then
                local taskentry = MENU_GROUP_COMMAND:New(group,text,ttypes[_tasktype],self._JoinTask,self,group,client,_task)
                taskentry:SetTag(playername)
                taskmenu[#taskmenu+1] = taskentry
              end          
            end
          end
        else
          -- no tasks (yet)
          local joinmenu = MENU_GROUP:New(group,"Currently no tasks available.",topmenu)
        end
        ---
        -- REFRESH MENU
        --- 
        self.PlayerMenu[playername]:Refresh()
      end
    end
  end
  return self
end

--- [User] Add agent group to INTEL detection
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Recce Group of agents. Can also be an @{Ops.OpsGroup#OPSGROUP} object.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddAgent(Recce)
  self:T(self.lid.."AddAgent: "..Recce:GetName())
  if self.Intel then
    self.Intel:AddAgent(Recce)
  end
  return self
end

--- [User] Add accept zone to INTEL detection
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE AcceptZone Add a zone to the accept zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddAcceptZone(AcceptZone)
  self:T(self.lid.."AddAcceptZone")
  if self.Intel then
    self.Intel:AddAcceptZone(AcceptZone)
  end
  return self
end

--- [User] Add reject zone to INTEL detection
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE RejectZone Add a zone to the reject zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddRejectZone(RejectZone)
  self:T(self.lid.."AddRejectZone")
  if self.Intel then
    self.Intel:AddRejectZone(RejectZone)
  end
  return self
end

--- [User] Remove accept zone from INTEL detection
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE AcceptZone Add a zone to the accept zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:RemoveAcceptZone(AcceptZone)
  self:T(self.lid.."RemoveAcceptZone")
  if self.Intel then
    self.Intel:RemoveAcceptZone(AcceptZone)
  end
  return self
end

--- [User] Remove reject zone from INTEL detection
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE RejectZone Add a zone to the reject zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:RemoveRejectZone(RejectZone)
  self:T(self.lid.."RemoveRejectZone")
  if self.Intel then
    self.Intel:RemoveRejectZone(RejectZone)
  end
  return self
end

--- [User] Set the top menu name to a custom string.
-- @param #PLAYERTASKCONTROLLER self
-- @param #string Name The name to use as the top menu designation.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetMenuName(Name)
 self:T(self.lid.."SetMenuName: "..Name)
 self.MenuName = Name
 return self
end

--- [User] Set up INTEL detection
-- @param #PLAYERTASKCONTROLLER self
-- @param #string RecceName This name will be used to build a detection group set. All groups with this string somewhere in their group name will be added as Recce.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetupIntel(RecceName)
  self:T(self.lid.."SetupIntel: "..RecceName)
  self.RecceSet = SET_GROUP:New():FilterCoalitions(self.CoalitionName):FilterPrefixes(RecceName):FilterStart()
  self.Intel = INTEL:New(self.RecceSet,self.Coalition,self.Name.."-Intel")
  self.Intel:SetClusterAnalysis(true,false,false)
  self.Intel:SetClusterRadius(self.ClusterRadius or 500)
  self.Intel.statusupdate = 25
  self.Intel:SetAcceptZones()
  self.Intel:SetRejectZones()
  --if self.verbose then
    --self.Intel:SetDetectionTypes(true,true,false,true,true,true)
  --end
  if self.Type == PLAYERTASKCONTROLLER.Type.A2G then
    self.Intel:SetDetectStatics(true)
  end
  self.Intel:__Start(2)
  
  local function NewCluster(Cluster)
    if not self.usecluster then return self end
    local cluster = Cluster -- Ops.Intelligence#INTEL.Cluster
    local type = cluster.ctype
    self:T({type,self.Type})
    if (type == INTEL.Ctype.AIRCRAFT and self.Type == PLAYERTASKCONTROLLER.Type.A2A) or (type == INTEL.Ctype.NAVAL and self.Type == PLAYERTASKCONTROLLER.Type.A2S) then
      self:T("A2A or A2S")
      local contacts = cluster.Contacts -- #table of GROUP
      local targetset = SET_GROUP:New()
      for _,_object in pairs(contacts) do
        local contact = _object -- Ops.Intelligence#INTEL.Contact
        self:T("Adding group: "..contact.groupname)
        targetset:AddGroup(contact.group,true)
      end
      self:AddTarget(targetset)
    elseif (type == INTEL.Ctype.GROUND or type == INTEL.Ctype.STRUCTURE) and self.Type == PLAYERTASKCONTROLLER.Type.A2G then
      self:T("A2G")
      local contacts = cluster.Contacts -- #table of GROUP or STATIC
      local targetset = nil -- Core.Set#SET_BASE
      if type == INTEL.Ctype.GROUND then
        targetset = SET_GROUP:New()
        for _,_object in pairs(contacts) do
          local contact = _object -- Ops.Intelligence#INTEL.Contact
          self:T("Adding group: "..contact.groupname)
          targetset:AddGroup(contact.group,true)
        end
      elseif type == INTEL.Ctype.STRUCTURE then
        targetset = SET_STATIC:New()
        for _,_object in pairs(contacts) do
          local contact = _object -- Ops.Intelligence#INTEL.Contact
          self:T("Adding static: "..contact.groupname)
          targetset:AddStatic(contact.group)
        end
      end
      if targetset then
        self:AddTarget(targetset)
      end
    end
  end
  
  local function NewContact(Contact)
    if self.usecluster then return self end
    local contact = Contact -- Ops.Intelligence#INTEL.Contact
    local type = contact.ctype
    self:T({type,self.Type})
    if (type == INTEL.Ctype.AIRCRAFT and self.Type == PLAYERTASKCONTROLLER.Type.A2A) or (type == INTEL.Ctype.NAVAL and self.Type == PLAYERTASKCONTROLLER.Type.A2S) then
      self:T("A2A or A2S")
      self:T("Adding group: "..contact.groupname)
      self:AddTarget(contact.group)
    elseif (type == INTEL.Ctype.GROUND or type == INTEL.Ctype.STRUCTURE) and self.Type == PLAYERTASKCONTROLLER.Type.A2G then
      self:T("A2G")
      self:T("Adding group: "..contact.groupname)
      self:AddTarget(contact.group)
    end
  end
  
  function self.Intel:OnAfterNewCluster(From,Event,To,Cluster)
    NewCluster(Cluster)
  end
  
  function self.Intel:OnAfterNewContact(From,Event,To,Contact)
    NewContact(Contact)
  end
  
  return self
end

--- [User] Set SRS TTS details - see @{Sound.SRS} for details
-- @param #PLAYERTASKCONTROLLER self
-- @param #number Frequency Frequency to be used. Can also be given as a table of multiple frequencies, e.g. 271 or {127,251}
-- @param #number Modulation Modulation to be used. Can also be given as a table of multiple modulations, e.g. radio.modulation.AM or {radio.modulation.FM,radio.modulation.AM}
-- @param #string PathToSRS Defaults to "C:\\Program Files\\DCS-SimpleRadio-Standalone"
-- @param #string Gender Defaults to "male"
-- @param #string Culture Defaults to "en-US"
-- @param #number Port Defaults to 5002
-- @param #string Voice (Optional) Use a specifc voice with the @{Sound.SRS.SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system. Can also be Google voice types, if you are using Google TTS.
-- @param #number Volume Volume - between 0.0 (silent) and 1.0 (loudest)
-- @param #string PathToGoogleKey Path to your google key if you want to use google TTS
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetSRS(Frequency,Modulation,PathToSRS,Gender,Culture,Port,Voice,Volume,PathToGoogleKey)
  self:T(self.lid.."SetSRS")
  self.PathToSRS = PathToSRS or "C:\\Program Files\\DCS-SimpleRadio-Standalone"
  self.Gender = Gender or "male"
  self.Culture = Culture or "en-US"
  self.Port = Port or 5002
  self.Voice = Voice 
  self.PathToGoogleKey = PathToGoogleKey
  self.Volume = Volume or 1.0
  self.UseSRS = true
  self.Frequency = Frequency or {127,251}
  self.BCFrequency = self.Frequency
  self.Modulation = Modulation or {radio.modulationFM,radio.modulation.AM}
  self.BCModulation = self.Modulation 
  self.SRS=MSRS:New(self.PathToSRS,self.Frequency,self.Modulation,self.Volume)
  self.SRS:SetCoalition(self.Coalition)
  self.SRS:SetLabel(self.MenuName or self.Name)
  if self.PathToGoogleKey then
    self.SRS:SetGoogle(self.PathToGoogleKey)
  end
  self.SRSQueue = MSRSQUEUE:New(self.MenuName or self.Name)
  return self
end

--- [User] Set SRS Broadcast - for the announcement to joining players which SRS frequency, modulation to use. Use in case you want to set this differently to the standard SRS.
-- @param #PLAYERTASKCONTROLLER self
-- @param #number Frequency Frequency to be used. Can also be given as a table of multiple frequencies, e.g. 271 or {127,251}
-- @param #number Modulation Modulation to be used. Can also be given as a table of multiple modulations, e.g. radio.modulation.AM or {radio.modulation.FM,radio.modulation.AM}
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetSRSBroadcast(Frequency,Modulation)
  self:T(self.lid.."SetSRSBroadcast")
  if self.SRS then
    self.BCFrequency = Frequency
    self.BCModulation = Modulation
  end
  return self
end

-------------------------------------------------------------------------------------------------------------------
-- FSM Functions PLAYERTASKCONTROLLER
-- TODO: FSM Functions PLAYERTASKCONTROLLER
-------------------------------------------------------------------------------------------------------------------

--- [Internal] On after Status call
-- @param #PLAYERTASKCONTROLLER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterStatus(From, Event, To)
  self:I({From, Event, To})
  self:_CheckTargetQueue()
  self:_CheckTaskQueue()
  self:_BuildMenus()
  
  local targetcount = self.TargetQueue:Count()
  local taskcount = self.TaskQueue:Count()
  local playercount = self.ClientSet:CountAlive()
  local assignedtasks = self.TasksPerPlayer:Count()
  
  if self.verbose then
    local text = string.format("New Targets: %02d | Active Tasks: %02d | Active Players: %02d | Assigned Tasks: %02d",targetcount,taskcount,playercount,assignedtasks)
    self:I(text)
  end
  
  if self:GetState() ~= "Stopped" then
    self:__Status(-30)
  end
  return self
end

--- [Internal] On after task done
-- @param #PLAYERTASKCONTROLLER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterTaskDone(From, Event, To, Task)
  self:T({From, Event, To})
  self:T(self.lid.."TaskDone")
  return self
end

--- [Internal] On after task cancelled
-- @param #PLAYERTASKCONTROLLER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterTaskCancelled(From, Event, To, Task)
  self:T({From, Event, To})
  self:T(self.lid.."TaskCancelled")
  local taskname = string.format("Task #%d %s is ancelled!", Task.PlayerTaskNr, tostring(Task.Type))
  local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
  if self.UseSRS then
    taskname = string.format("Task %d %s is cancelled!", Task.PlayerTaskNr, tostring(Task.TTSType))
    self.SRSQueue:NewTransmission(taskname,nil,self.SRS,nil,2)
  end
  return self
end

--- [Internal] On after task success
-- @param #PLAYERTASKCONTROLLER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterTaskSuccess(From, Event, To, Task)
  self:T({From, Event, To})
  self:T(self.lid.."TaskSuccess")
  local taskname = string.format("Task #%d %s completed successfully!", Task.PlayerTaskNr, tostring(Task.Type))
  local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
  if self.UseSRS then
    taskname = string.format("Task %d %s completed successfully!", Task.PlayerTaskNr, tostring(Task.TTSType))
    self.SRSQueue:NewTransmission(taskname,nil,self.SRS,nil,2)
  end
  return self
end

--- [Internal] On after task failed
-- @param #PLAYERTASKCONTROLLER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterTaskFailed(From, Event, To, Task)
  self:T({From, Event, To})
  self:T(self.lid.."TaskFailed")
  local taskname = string.format("Task #%d %s was a failure!", Task.PlayerTaskNr, tostring(Task.Type))
  local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
  if self.UseSRS then
    taskname = string.format("Task %d %s was a failure!", Task.PlayerTaskNr, tostring(Task.TTSType))
    self.SRSQueue:NewTransmission(taskname,nil,self.SRS,nil,2)
  end
  return self
end

--- [Internal] On after task failed, repeat planned
-- @param #PLAYERTASKCONTROLLER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterTaskRepeatOnFailed(From, Event, To, Task)
  self:T({From, Event, To})
  self:T(self.lid.."RepeatOnFailed")
  local taskname = string.format("Task #%d %s was a failure! Replanning!", Task.PlayerTaskNr, tostring(Task.Type))
  local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
  if self.UseSRS then
    taskname = string.format("Task %d %s was a failure! Replanning!", Task.PlayerTaskNr, tostring(Task.TTSType))
    self.SRSQueue:NewTransmission(taskname,nil,self.SRS,nil,2)
  end
  return self
end

--- [Internal] On after task added
-- @param #PLAYERTASKCONTROLLER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterTaskAdded(From, Event, To, Task)
  self:T({From, Event, To})
  self:T(self.lid.."TaskAdded")
  local taskname = string.format("%s has a new task %s", self.MenuName or self.Name, tostring(Task.Type))
  local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
  if self.UseSRS then
    taskname = string.format("%s has a new task %s", self.MenuName or self.Name, tostring(Task.TTSType))
    self.SRSQueue:NewTransmission(taskname,nil,self.SRS,nil,2)
  end
  return self
end

--- [Internal] On after Stop call
-- @param #PLAYERTASKCONTROLLER self
-- @param #string From
-- @param #string Event 
-- @param #string To
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterStop(From, Event, To)
  self:T({From, Event, To})
  self:T(self.lid.."Stopped.")
    -- Player leaves
  self:UnHandleEvent(EVENTS.PlayerLeaveUnit)
  self:UnHandleEvent(EVENTS.Ejection)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.PilotDead)
  return self
end

