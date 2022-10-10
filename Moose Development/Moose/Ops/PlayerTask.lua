--- **Ops** - PlayerTask (mission) for Players.
--
-- ## Main Features:
--
--    * Simplifies defining and executing Player tasks
--    * FSM events when a mission is added, done, successful or failed, replanned
--    * Ready to use SRS and localization
--    * Mission locations can be smoked, flared and marked on the map
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20PlayerTask).
--
-- ===
--
-- ### Author: **Applevangelist**
-- ### Special thanks to: Streakeagle
--
-- ===
-- @module Ops.PlayerTask
-- @image OPS_PlayerTask.jpg
-- @date Last Update September 2022


do
-------------------------------------------------------------------------------------------------------------------
-- PLAYERTASK
-- TODO: PLAYERTASK
-------------------------------------------------------------------------------------------------------------------

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
-- @field #number lastsmoketime
-- @field #number coalition
-- @field #string Freetext
-- @field #string FreetextTTS
-- @extends Core.Fsm#FSM


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
  lastsmoketime      =   0,
  Freetext           =    nil,
  FreetextTTS       =     nil,
  }
  
--- PLAYERTASK class version.
-- @field #string version
PLAYERTASK.version="0.1.5"

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
  self.timestamp = timer.getAbsTime()
  self.TTSType = TTSType or "close air support"
  self.lastsmoketime = 0
  
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
  self:AddTransition("*",            "Failed",           "Failed") -- Done or repeat --> PLANNED
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

--- [User] Set a coalition side for this task
-- @param #PLAYERTASK self
-- @param #number Coalition Coaltion side to add, e.g. coalition.side.BLUE
-- @return #PLAYERTASK self
function PLAYERTASK:SetCoalition(Coalition)
  self:T(self.lid.."SetCoalition")
  self.coalition = Coalition or coalition.side.BLUE
  return self
end

--- [User] Get the coalition side for this task
-- @param #PLAYERTASK self
-- @return #number Coalition Coaltion side, e.g. coalition.side.BLUE, or nil if not set
function PLAYERTASK:GetCoalition()
  self:T(self.lid.."GetCoalition")
  return self.coalition
end

--- [USER] Add a free text description to this task.
-- @param #PLAYERTASK self
-- @param #string Text
-- @return #PLAYERTASK self
function PLAYERTASK:AddFreetext(Text)
  self:T(self.lid.."AddFreetext")
  self.Freetext = Text
  return self
end

--- [USER] Get the free text description from this task.
-- @param #PLAYERTASK self
-- @return #string Text
function PLAYERTASK:GetFreetext()
  self:T(self.lid.."GetFreetext")
  return self.Freetext
end

--- [USER] Add a free text description for TTS to this task.
-- @param #PLAYERTASK self
-- @param #string Text
-- @return #PLAYERTASK self
function PLAYERTASK:AddFreetextTTS(TextTTS)
  self:T(self.lid.."AddFreetextTTS")
  self.FreetextTTS = TextTTS
  return self
end

--- [USER] Get the free text TTS description from this task.
-- @param #PLAYERTASK self
-- @return #string Text
function PLAYERTASK:GetFreetextTTS()
  self:T(self.lid.."GetFreetextTTS")
  return self.FreetextTTS
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

--- [User] Get client names assigned as table of #strings
-- @param #PLAYERTASK self
-- @return #table clients
-- @return #number clientcount
function PLAYERTASK:GetClients()
  self:T(self.lid.."GetClients")
  local clientlist = self.Clients:GetIDStackSorted() or {}
  local count = self.Clients:Count()
  return clientlist, count
end

--- [User] Get #CLIENT objects assigned as table
-- @param #PLAYERTASK self
-- @return #table clients
-- @return #number clientcount
function PLAYERTASK:GetClientObjects()
  self:T(self.lid.."GetClientObjects")
  local clientlist = self.Clients:GetDataTable() or {}
  local count = self.Clients:Count()
  return clientlist, count
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
-- @param #string Text (optional) Text to show on the marker
-- @param #number Coalition (optional) Coalition this marker is for. Default = All.
-- @param #boolean ReadOnly (optional) Make target marker read-only. Default = false.
-- @return #PLAYERTASK self
function PLAYERTASK:MarkTargetOnF10Map(Text,Coalition,ReadOnly)
  self:T(self.lid.."MarkTargetOnF10Map")
  if self.Target then
    local coordinate = self.Target:GetCoordinate()
    if coordinate then
      if self.TargetMarker then
        -- Marker exists, delete one first
        self.TargetMarker:Remove()
      end
      local text = Text or "Target of "..self.lid
      self.TargetMarker = MARKER:New(coordinate,"Target of "..self.lid)
      if ReadOnly then
        self.TargetMarker:ReadOnly()
      end
      if Coalition then
        self.TargetMarker:ToCoalition(Coalition)
      else
        self.TargetMarker:ToAll()
      end
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
  if not self.lastsmoketime then self.lastsmoketime = 0 end
  local TDiff = timer.getAbsTime() - self.lastsmoketime
  if self.Target and TDiff > 299 then
    local coordinate = self.Target:GetCoordinate()
    if coordinate then
      coordinate:Smoke(color)
      self.lastsmoketime = timer.getAbsTime()
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

--- [User] Illuminate Target Area
-- @param #PLAYERTASK self
-- @param #number Power Power of illumination bomb in Candela. Default 1000 cd.
-- @param #number Height Height above target used to release the bomb, default 150m.
-- @return #PLAYERTASK self
function PLAYERTASK:IlluminateTarget(Power,Height)
  self:T(self.lid.."IlluminateTarget")
  local Power = Power or 1000
  local Height = Height or 150
  if self.Target then
    local coordinate = self.Target:GetCoordinate()
    if coordinate then
	  local bcoord = COORDINATE:NewFromVec2( coordinate:GetVec2(), Height )
      bcoord:IlluminationBomb(Power)
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
  
    if failureCondition and status ~= "Failed" then
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
  self.timestamp = timer.getAbsTime()
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
  self.timestamp = timer.getAbsTime()
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
  self.timestamp = timer.getAbsTime()
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
  self.timestamp = timer.getAbsTime()
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
    local text = string.format("Player %s joined task %03d!",Client:GetPlayerName() or "Generic",self.PlayerTaskNr)
    self:I(self.lid..text)
  end
  self.timestamp = timer.getAbsTime()
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
  self.timestamp = timer.getAbsTime()
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
  self.timestamp = timer.getAbsTime()
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
  self.timestamp = timer.getAbsTime()
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
  self.timestamp = timer.getAbsTime()
  return self
end
-------------------------------------------------------------------------------------------------------------------
-- END PLAYERTASK
-------------------------------------------------------------------------------------------------------------------
end

do
-------------------------------------------------------------------------------------------------------------------
-- PLAYERTASKCONTROLLER
-- TODO: PLAYERTASKCONTROLLER
-- DONE Playername customized
-- DONE Coalition-level screen info to SET based
-- DONE Flash directions
-- DONE less rebuilds menu, Task info menu available after join
-- DONE Limit menu entries
-------------------------------------------------------------------------------------------------------------------

--- PLAYERTASKCONTROLLER class.
-- @type PLAYERTASKCONTROLLER
-- @field #string ClassName Name of the class.
-- @field #boolean verbose Switch verbosity.
-- @field #string lid Class id string for output to DCS log file.
-- @field Utilities.FiFo#FIFO TargetQueue
-- @field Utilities.FiFo#FIFO TaskQueue
-- @field Utilities.FiFo#FIFO TasksPerPlayer
-- @field Utilities.FiFo#FIFO PrecisionTasks
-- @field Core.Set#SET_CLIENT ClientSet
-- @field #string ClientFilter
-- @field #string Name
-- @field #string Type
-- @field #boolean UseGroupNames
-- @field #table PlayerMenu
-- @field #boolean usecluster
-- @field #number ClusterRadius
-- @field #string MenuName
-- @field #boolean NoScreenOutput
-- @field #number TargetRadius
-- @field #boolean UseWhiteList
-- @field #table WhiteList
-- @field #boolean UseBlackList
-- @field #table BlackList
-- @field Core.TextAndSound#TEXTANDSOUND gettext
-- @field #string locale
-- @field #boolean precisionbombing
-- @field Ops.FlightGroup#FLIGHTGROUP LasingDrone
-- @field Core.MarkerOps_BASE#MARKEROPS_BASE MarkerOps
-- @field #boolean taskinfomenu
-- @field #boolean MarkerReadOnly
-- @field #table FlashPlayer List of player who switched Flashing Direction Info on
-- @field #boolean AllowFlash Flashing directions for players allowed
-- @field #number menuitemlimit
-- @field #boolean activehasinfomenu
-- @field #number holdmenutime
-- @field #table customcallsigns
-- @field #boolean ShortCallsign
-- @field #boolean Keepnumber
-- @field #table CallsignTranslations
-- @field #table PlayerFlashMenu
-- @field #table PlayerJoinMenu
-- @field #table PlayerInfoMenu
-- @field #boolean noflaresmokemenu
-- @field #boolean TransmitOnlyWithPlayers
-- @field #boolean buddylasing
-- @field Ops.PlayerRecce#PLAYERRECCE PlayerRecce
-- @extends Core.Fsm#FSM

---
--
-- *It is our attitude at the beginning of a difficult task which, more than anything else, which will affect its successful outcome.* (William James)
--
-- ===
-- 
-- # PLAYERTASKCONTROLLER 
-- 
--    * Simplifies defining, executing and controlling of Player tasks
--    * FSM events when a mission is added, done, successful or failed, replanned
--    * Ready to use SRS and localization
--    * Mission locations can be smoked, flared and marked on the map
-- 
-- ## 1 Overview
-- 
-- PLAYERTASKCONTROLLER is used to auto-create (optional) and control tasks for players. It can be set up as Air-to-Ground (A2G, main focus), Air-to-Ship (A2S) or Air-to-Air (A2A) controller.
-- For the latter task type, also have a look at the @{Ops.Awacs#AWACS} class which allows for more complex scenarios.
-- One task at a time can be joined by the player from the F10 menu. A task can be joined by multiple players. Once joined, task information is available via the F10 menu, the task location
-- can be marked on the map and for A2G/S targets, the target can be marked with smoke and flares.
-- 
-- For the mission designer, tasks can be auto-created by means of detection with the integrated @{Ops.Intel#INTEL} class setup, or be manually added to the task queue.
-- 
-- ## 2 Task Types
-- 
-- Targets can be of types GROUP, SET\_GROUP, UNIT, SET\_UNIT, STATIC, SET\_STATIC, AIRBASE, ZONE or COORDINATE. The system will auto-create tasks for players from these targets.
-- Tasks are created as @{Ops.PlayerTask#PLAYERTASK} objects, which leverage @{Ops.Target#TARGET} for the management of the actual target. The system creates these task types
-- from the target objects:  
-- 
--  * A2A - AUFTRAG.Type.INTERCEPT
--  * A2S - AUFTRAG.Type.ANTISHIP
--  * A2G - AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.SEAD, AUFTRAG.Type.BOMBING, AUFTRAG.Type.PRECISIONBOMBING, AUFTRAG.Type.BOMBRUNWAY
--  * A2GS - A2S and A2G combined
-- 
-- Task types are derived from @{Ops.Auftrag#AUFTRAG}:   
--  
--  * CAS - Close air support, created to attack ground units, where friendly ground units are around the location in a bespoke radius (default: 500m/1km diameter)
--  * BAI - Battlefield air interdiction, same as above, but no friendlies around
--  * SEAD - Same as CAS, but the enemy ground units field AAA, SAM or EWR units
--  * Bombing - Against static targets
--  * Precision Bombing - (if enabled) Laser-guided bombing, against **static targets** and **high-value (non-SAM) ground targets (MBTs etc)**
--  * Bomb Runway - Against Airbase runways (in effect, drop bombs over the runway)
--  * ZONE and COORDINATE - Targets will be scanned for GROUND or STATIC enemy units and tasks created from these
--  * Intercept - Any airborne targets, if the controller is of type "A2A"
--  * Anti-Ship - Any ship targets, if the controller is of type "A2S"
--  
-- ## 3 Task repetition
--  
-- On failure, tasks will be replanned by default for a maximum of 5 times.
-- 
-- ## 4 SETTINGS, SRS and language options (localization)
-- 
-- The system can optionally communicate to players via SRS. Also localization is available, both "en" and "de" has been build in already.
-- Player and global @{Core.Settings#SETTINGS} for coordinates will be observed.
--  
-- ## 5 Setup  
-- 
-- A basic setup is very simple:
-- 
--            -- Settings - we want players to have a settings menu, be on imperial measures, and get directions as BR
--            _SETTINGS:SetPlayerMenuOn()
--            _SETTINGS:SetImperial()
--            _SETTINGS:SetA2G_BR()
-- 
--            -- Set up the A2G task controller for the blue side named "82nd Airborne"
--            local taskmanager = PLAYERTASKCONTROLLER:New("82nd Airborne",coalition.side.BLUE,PLAYERTASKCONTROLLER.Type.A2G)
--            
--            -- set locale to English
--            taskmanager:SetLocale("en")
--            
--            -- Set up detection with grup names *containing* "Blue Recce", these will add targets to our controller via detection. Can be e.g. a drone.
--            taskmanager:SetupIntel("Blue Recce")
--            
--            -- Add a single Recce group name "Blue Humvee"
--            taskmanager:AddAgent(GROUP:FindByName("Blue Humvee"))
--            
--            -- Set the callsign for SRS and Menu name to be "Groundhog"
--            taskmanager:SetMenuName("Groundhog")
--            
--            -- Add accept- and reject-zones for detection
--            -- Accept zones are handy to limit e.g. the engagement to a certain zone. The example is a round, mission editor created zone named "AcceptZone"
--            taskmanager:AddAcceptZone(ZONE:New("AcceptZone"))
--            
--            -- Reject zones are handy to create borders. The example is a ZONE_POLYGON, created in the mission editor, late activated with waypoints, 
--            -- named "AcceptZone#ZONE_POLYGON"
--            taskmanager:AddRejectZone(ZONE:FindByName("RejectZone"))
--            
--            -- Set up using SRS for messaging
--            local hereSRSPath = "C:\\Program Files\\DCS-SimpleRadio-Standalone"
--            local hereSRSPort = 5002
--            -- local hereSRSGoogle = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\yourkey.json"
--            taskmanager:SetSRS({130,255},{radio.modulation.AM,radio.modulation.AM},hereSRSPath,"female","en-GB",hereSRSPort,"Microsoft Hazel Desktop",0.7,hereSRSGoogle)
--            
--            -- Controller will announce itself under these broadcast frequencies, handy to use cold-start frequencies here of your aircraft
--            taskmanager:SetSRSBroadcast({127.5,305},{radio.modulation.AM,radio.modulation.AM})
--            
--            -- Example: Manually add an AIRBASE as a target
--            taskmanager:AddTarget(AIRBASE:FindByName(AIRBASE.Caucasus.Senaki_Kolkhi))
--            
--            -- Example: Manually add a COORDINATE as a target
--            taskmanager:AddTarget(GROUP:FindByName("Scout Coordinate"):GetCoordinate())
--            
--            -- Set a whitelist for tasks, e.g. skip SEAD tasks
--            taskmanager:SetTaskWhiteList({AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING, AUFTRAG.Type.BOMBRUNWAY})
--            
--            -- Set target radius
--            taskmanager:SetTargetRadius(1000)
-- 
-- ## 6 Localization
-- 
-- Localization for English and German texts are build-in. Default setting is English. Change with @{#PLAYERTASKCONTROLLER.SetLocale}()
-- 
-- ### 6.1 Adding Localization
-- 
-- A list of fields to be defined follows below. **Note** that in some cases `string.format()` is used to format texts for screen and SRS. 
-- Hence, the `%d`, `%s` and `%f` special characters need to appear in the exact same amount and order of appearance in the localized text or it will create errors.
-- To add a localization, the following texts need to be translated and set in your mission script **before** @{#PLAYERTASKCONTROLLER.New}():   
-- 
--            PLAYERTASKCONTROLLER.Messages = {
--              EN = {
--                TASKABORT = "Task aborted!",
--                NOACTIVETASK = "No active task!",
--                FREQUENCIES = "frequencies ",
--                FREQUENCY = "frequency %.3f",
--                BROADCAST = "%s, %s, switch to %s for task assignment!",
--                CASTTS = "close air support",
--                SEADTTS = "suppress air defense",
--                BOMBTTS = "bombing",
--                PRECBOMBTTS = "precision bombing",
--                BAITTS = "battle field air interdiction",
--                ANTISHIPTTS = "anti-ship",
--                INTERCEPTTS = "intercept",
--                BOMBRUNWAYTTS = "bomb runway",
--                HAVEACTIVETASK = "You already have one active task! Complete it first!",
--                PILOTJOINEDTASK = "%s, %s. You have been assigned %s task %03d",
--                TASKNAME = "%s Task ID %03d",
--                TASKNAMETTS = "%s Task ID %03d",
--                THREATHIGH = "high",
--                THREATMEDIUM = "medium",
--                THREATLOW = "low",
--                THREATTEXT = "%s\nThreat: %s\nTargets left: %d\nCoord: %s",
--                THREATTEXTTTS = "%s, %s. Target information for %s. Threat level %s. Targets left %d. Target location %s.",
--                MARKTASK = "%s, %s, copy, task %03d location marked on map!",
--                SMOKETASK = "%s, %s, copy, task %03d location smoked!",
--                FLARETASK = "%s, %s, copy, task %03d location illuminated!",
--                ABORTTASK = "All stations, %s, %s has aborted %s task %03d!",
--                UNKNOWN = "Unknown",
--                MENUTASKING = " Tasking ",
--                MENUACTIVE = "Active Task",
--                MENUINFO = "Info",
--                MENUMARK = "Mark on map",
--                MENUSMOKE = "Smoke",
--                MENUFLARE = "Flare",
--                MENUABORT = "Abort",
--                MENUJOIN = "Join Task",
--                MENUTASKINFO = Task Info",
--                MENUTASKNO = "TaskNo",
--                MENUNOTASKS = "Currently no tasks available.",
--                TASKCANCELLED = "Task #%03d %s is cancelled!",
--                TASKCANCELLEDTTS = "%s, task %03d %s is cancelled!",
--                TASKSUCCESS = "Task #%03d %s completed successfully!",
--                TASKSUCCESSTTS = "%s, task %03d %s completed successfully!",
--                TASKFAILED = "Task #%03d %s was a failure!",
--                TASKFAILEDTTS = "%s, task %03d %s was a failure!",
--                TASKFAILEDREPLAN = "Task #%03d %s was a failure! Replanning!",
--                TASKFAILEDREPLANTTS = "%s, task %03d %s was a failure! Replanning!",
--                TASKADDED = "%s has a new task %s available!",
--                PILOTS = "\nPilot(s): ",
--                PILOTSTTS = ". Pilot(s): ",
--                YES = "Yes",
--                NO = "No",
--                NONE = "None",
--                POINTEROVERTARGET = "%s, %s, pointer in reach for task %03d, lasing!",
--                POINTERTARGETREPORT = "\nPointer in reach: %s\nLasing: %s",
--                RECCETARGETREPORT = "\nRecce %s in reach: %s\nLasing: %s",
--                POINTERTARGETLASINGTTS = ". Pointer in reach and lasing.",
--                TARGET = "Target",
--                FLASHON = "%s - Flashing directions is now ON!",
--                FLASHOFF = "%s - Flashing directions is now OFF!",
--                FLASHMENU = "Flash Directions Switch",
--              },
-- 
-- e.g.
-- 
--            taskmanager.Messages = {
--              FR = {
--                TASKABORT = "Tâche abandonnée!",
--                NOACTIVETASK = "Aucune tâche active!",
--                FREQUENCIES = "fréquences ",
--                FREQUENCY = "fréquence %.3f",
--                BROADCAST = "%s, %s, passer au %s pour l'attribution des tâches!",
--                ...
--                TASKADDED = "%s a créé une nouvelle tâche %s",
--                PILOTS = "\nPilote(s): ",
--                PILOTSTTS = ". Pilote(s): ",
--              },
--  
-- and then `taskmanager:SetLocale("fr")` **after** @{#PLAYERTASKCONTROLLER.New}() in your script.
-- 
-- If you just want to replace a **single text block** in the table, you can do this like so:
-- 
--            mycontroller.Messages.EN.NOACTIVETASK = "Choose a task first!"   
--            mycontroller.Messages.FR.YES = "Oui" 
-- 
-- ## 7 Events
--
--  The class comes with a number of FSM-based events that missions designers can use to shape their mission.
--  These are:
--  
-- ### 7.1 TaskAdded. 
--      
-- The event is triggered when a new task is added to the controller. Use @{#PLAYERTASKCONTROLLER.OnAfterTaskAdded}() to link into this event:
--      
--              function taskmanager:OnAfterTaskAdded(From, Event, To, Task)
--                ... your code here ...
--              end
-- 
-- ### 7.2 TaskDone. 
--      
-- The event is triggered when a task has ended. Use @{#PLAYERTASKCONTROLLER.OnAfterTaskDone}() to link into this event:
--      
--              function taskmanager:OnAfterTaskDone(From, Event, To, Task)
--                ... your code here ...
--              end
--          
-- ### 7.3 TaskCancelled. 
--      
-- The event is triggered when a task was cancelled manually. Use @{#PLAYERTASKCONTROLLER.OnAfterTaskCancelled}()` to link into this event:
--      
--              function taskmanager:OnAfterTaskCancelled(From, Event, To, Task)
--                ... your code here ...
--              end
--          
-- ### 7.4 TaskSuccess. 
--      
-- The event is triggered when a task completed successfully. Use @{#PLAYERTASKCONTROLLER.OnAfterTaskSuccess}() to link into this event:
--      
--              function taskmanager:OnAfterTaskSuccess(From, Event, To, Task)
--                ... your code here ...
--              end
--          
-- ### 7.5 TaskFailed. 
--      
-- The event is triggered when a task failed, no repeats. Use @{#PLAYERTASKCONTROLLER.OnAfterTaskFailed}() to link into this event:
--      
--              function taskmanager:OnAfterTaskFailed(From, Event, To, Task)
--                ... your code here ...
--              end
--          
-- ### 7.6 TaskRepeatOnFailed. 
--      
-- The event is triggered when a task failed and is re-planned for execution. Use @{#PLAYERTASKCONTROLLER.OnAfterRepeatOnFailed}() to link into this event:
--      
--              function taskmanager:OnAfterRepeatOnFailed(From, Event, To, Task)
--                ... your code here ...
--              end
-- 
-- ## 8 Using F10 map markers to create new targets
-- 
-- You can use F10 map markers to create new target points for player tasks.  
-- Enable this option with e.g., setting the tag to be used to "TARGET":
-- 
--            taskmanager:EnableMarkerOps("TARGET")
--            
-- Set a marker on the map and add the following text to create targets from it: "TARGET". This is effectively the same as adding a COORDINATE object as target.
-- The marker can be deleted any time.
--         
-- ## 9 Discussion
--
-- If you have questions or suggestions, please visit the [MOOSE Discord](https://discord.gg/AeYAkHP) #ops-playertask channel.  
-- 
--                          
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
  ClusterRadius      =   0.5,
  NoScreenOutput     =   false,
  TargetRadius       =   500,
  UseWhiteList       =   false,
  WhiteList          =   {},
  gettext            =   nil,
  locale             =   "en",
  precisionbombing   =   false,
  taskinfomenu       =   false,
  activehasinfomenu  =   false,
  MarkerReadOnly     =   false,
  customcallsigns    =   {},
  ShortCallsign      =   true,
  Keepnumber         =   false,
  CallsignTranslations = nil,
  PlayerFlashMenu    =   {},
  PlayerJoinMenu     =   {},
  PlayerInfoMenu     =   {},
  noflaresmokemenu   =   false,
  TransmitOnlyWithPlayers = true,
  buddylasing        = false,
  PlayerRecce         = nil,
  }

---
-- @type Type
-- @field #string A2A Air-to-Air Controller
-- @field #string A2G Air-to-Ground Controller
-- @field #string A2S Air-to-Ship Controller
-- @field #string A2GS Air-to-Ground-and-Ship Controller
PLAYERTASKCONTROLLER.Type = {
  A2A = "Air-To-Air",
  A2G = "Air-To-Ground",
  A2S = "Air-To-Sea",
  A2GS = "Air-To-Ground-Sea",
}

--- Define new AUFTRAG Types
AUFTRAG.Type.PRECISIONBOMBING = "Precision Bombing"
AUFTRAG.Type.CTLD = "Combat Transport"
AUFTRAG.Type.CSAR "Combat Rescue"
 
--- 
-- @type SeadAttributes
-- @field #number SAM GROUP.Attribute.GROUND_SAM 
-- @field #number AAA GROUP.Attribute.GROUND_AAA
-- @field #number EWR GROUP.Attribute.GROUND_EWR 
PLAYERTASKCONTROLLER.SeadAttributes = {
  SAM = GROUP.Attribute.GROUND_SAM,
  AAA = GROUP.Attribute.GROUND_AAA,
  EWR = GROUP.Attribute.GROUND_EWR,
}
 
---
-- @field Messages 
PLAYERTASKCONTROLLER.Messages = {
  EN = {
    TASKABORT = "Task aborted!",
    NOACTIVETASK = "No active task!",
    FREQUENCIES = "frequencies ",
    FREQUENCY = "frequency %.3f",
    BROADCAST = "%s, %s, switch to %s for task assignment!",
    CASTTS = "close air support",
    SEADTTS = "suppress air defense",
    BOMBTTS = "bombing",
    PRECBOMBTTS = "precision bombing",
    BAITTS = "battle field air interdiction",
    ANTISHIPTTS = "anti-ship",
    INTERCEPTTS = "intercept",
    BOMBRUNWAYTTS = "bomb runway",
    HAVEACTIVETASK = "You already have one active task! Complete it first!",
    PILOTJOINEDTASK = "%s, %s. You have been assigned %s task %03d",
    TASKNAME = "%s Task ID %03d",
    TASKNAMETTS = "%s Task ID %03d",
    THREATHIGH = "high",
    THREATMEDIUM = "medium",
    THREATLOW = "low",
    THREATTEXT = "%s\nThreat: %s\nTargets left: %d\nCoord: %s",
    THREATTEXTTTS = "%s, %s. Target information for %s. Threat level %s. Targets left %d. Target location %s.",
    MARKTASK = "%s, %s, copy, task %03d location marked on map!",
    SMOKETASK = "%s, %s, copy, task %03d location smoked!",
    FLARETASK = "%s, %s, copy, task %03d location illuminated!",
    ABORTTASK = "All stations, %s, %s has aborted %s task %03d!",
    UNKNOWN = "Unknown",
    MENUTASKING = " Tasking ",
    MENUACTIVE = "Active Task",
    MENUINFO = "Info",
    MENUMARK = "Mark on map",
    MENUSMOKE = "Smoke",
    MENUFLARE = "Flare",
    MENUABORT = "Abort",
    MENUJOIN = "Join Task",
    MENUTASKINFO = "Task Info",
    MENUTASKNO = "TaskNo",
    MENUNOTASKS = "Currently no tasks available.",
    TASKCANCELLED = "Task #%03d %s is cancelled!",
    TASKCANCELLEDTTS = "%s, task %03d %s is cancelled!",
    TASKSUCCESS = "Task #%03d %s completed successfully!",
    TASKSUCCESSTTS = "%s, task %03d %s completed successfully!",
    TASKFAILED = "Task #%03d %s was a failure!",
    TASKFAILEDTTS = "%s, task %03d %s was a failure!",
    TASKFAILEDREPLAN = "Task #%03d %s available for reassignment!",
    TASKFAILEDREPLANTTS = "%s, task %03d %s vailable for reassignment!",
    TASKADDED = "%s has a new %s task available!",
    PILOTS = "\nPilot(s): ",
    PILOTSTTS = ". Pilot(s): ",
    YES = "Yes",
    NO = "No",
    NONE = "None",
    POINTEROVERTARGET = "%s, %s, pointer in reach for task %03d, lasing!",
    POINTERTARGETREPORT = "\nPointer in reach: %s\nLasing: %s",
    RECCETARGETREPORT = "\nRecce %s in reach: %s\nLasing: %s",
    POINTERTARGETLASINGTTS = ". Pointer in reach and lasing.",
    TARGET = "Target",
    FLASHON = "%s - Flashing directions is now ON!",
    FLASHOFF = "%s - Flashing directions is now OFF!",
    FLASHMENU = "Flash Directions Switch",
  },
  DE = {
    TASKABORT = "Auftrag abgebrochen!",
    NOACTIVETASK = "Kein aktiver Auftrag!",
    FREQUENCIES = "Frequenzen ",
    FREQUENCY = "Frequenz %.3f",
    BROADCAST = "%s, %s, Radio %s für Aufgabenzuteilung!",
    CASTTS = "Nahbereichsunterstützung",
    SEADTTS = "Luftabwehr ausschalten",
    BOMBTTS = "Bombardieren",
    PRECBOMBTTS = "Präzisionsbombardieren",
    BAITTS = "Luftunterstützung",
    ANTISHIPTTS = "Anti-Schiff",
    INTERCEPTTS = "Abfangen",
    BOMBRUNWAYTTS = "Startbahn Bombardieren",
    HAVEACTIVETASK = "Du hast einen aktiven Auftrag! Beende ihn zuerst!",
    PILOTJOINEDTASK = "%s, %s hat Auftrag %s %03d angenommen",
    TASKNAME = "%s Auftrag ID %03d",
    TASKNAMETTS = "%s Auftrag ID %03d",
    THREATHIGH = "hoch",
    THREATMEDIUM = "mittel",
    THREATLOW = "niedrig",
    THREATTEXT = "%s\nGefahrstufe: %s\nZiele: %d\nKoord: %s",
    THREATTEXTTTS = "%s, %s. Zielinformation zu %s. Gefahrstufe %s. Ziele %d. Zielposition %s.",
    MARKTASK = "%s, %s, verstanden, Zielposition %03d auf der Karte markiert!",
    SMOKETASK = "%s, %s, verstanden, Zielposition %03d mit Rauch markiert!",
    FLARETASK = "%s, %s, verstanden, Zielposition %03d beleuchtet!",
    ABORTTASK = "%s, an alle, %s hat Auftrag %s %03d abgebrochen!",
    UNKNOWN = "Unbekannt",
    MENUTASKING = " Aufträge ",
    MENUACTIVE = "Aktiver Auftrag",
    MENUINFO = "Information",
    MENUMARK = "Kartenmarkierung",
    MENUSMOKE = "Rauchgranate",
    MENUFLARE = "Leuchtgranate",
    MENUABORT = "Abbrechen",
    MENUJOIN = "Auftrag annehmen",
    MENUTASKINFO = "Auftrag Briefing",
    MENUTASKNO = "AuftragsNr",
    MENUNOTASKS = "Momentan keine Aufträge verfügbar.",
    TASKCANCELLED = "Auftrag #%03d %s wurde beendet!",
    TASKCANCELLEDTTS = "%s, Auftrag %03d %s wurde beendet!",
    TASKSUCCESS = "Auftrag #%03d %s erfolgreich!",
    TASKSUCCESSTTS = "%s, Auftrag %03d %s erfolgreich!",
    TASKFAILED = "Auftrag #%03d %s gescheitert!",
    TASKFAILEDTTS = "%s, Auftrag %03d %s gescheitert!",
    TASKFAILEDREPLAN = "Auftrag #%03d %s gescheitert! Neuplanung!",
    TASKFAILEDREPLANTTS = "%s, Auftrag %03d %s gescheitert! Neuplanung!",
    TASKADDED = "%s hat einen neuen Auftrag %s erstellt!",
    PILOTS = "\nPilot(en): ",
    PILOTSTTS = ". Pilot(en): ",
    YES = "Ja",
    NO = "Nein",
    NONE = "Keine",
    POINTEROVERTARGET = "%s, %s, Marker im Zielbereich für %03d, Laser an!",
    POINTERTARGETREPORT = "\nMarker im Zielbereich: %s\nLaser an: %s",
    RECCETARGETREPORT = "\nSpäher % im Zielbereich: %s\nLasing: %s",
    POINTERTARGETLASINGTTS = ". Marker im Zielbereich, Laser is an.",
    TARGET = "Ziel",
    FLASHON = "%s - Richtungsangaben einblenden ist EIN!",
    FLASHOFF = "%s - Richtungsangaben einblenden ist AUS!",
    FLASHMENU = "Richtungsangaben Schalter",
  },
}
  
--- PLAYERTASK class version.
-- @field #string version
PLAYERTASKCONTROLLER.version="0.1.40"

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
  
  self.ClusterRadius = 0.5
  self.TargetRadius = 500
  
  self.ClientFilter = ClientFilter or ""
  
  self.TargetQueue = FIFO:New() -- Utilities.FiFo#FIFO
  self.TaskQueue = FIFO:New() -- Utilities.FiFo#FIFO
  self.TasksPerPlayer = FIFO:New() -- Utilities.FiFo#FIFO
  self.PrecisionTasks = FIFO:New() -- Utilities.FiFo#FIFO
  self.PlayerMenu = {} -- #table
  self.FlashPlayer = {} -- #table
  self.AllowFlash = false
  self.lasttaskcount = 0
  
  self.taskinfomenu = false
  self.activehasinfomenu = false
  self.MenuName = nil
  self.menuitemlimit = 5
  self.holdmenutime = 30
  
  self.MarkerReadOnly = false
  
  self.repeatonfailed = true
  self.repeattimes = 5
  self.UseGroupNames = true
  
  self.customcallsigns = {}
  self.ShortCallsign = true
  self.Keepnumber = false 
  self.CallsignTranslations = nil
  
  self.noflaresmokemenu = false
   
  if ClientFilter then
    self.ClientSet = SET_CLIENT:New():FilterCoalitions(string.lower(self.CoalitionName)):FilterActive(true):FilterPrefixes(ClientFilter):FilterStart()
  else
    self.ClientSet = SET_CLIENT:New():FilterCoalitions(string.lower(self.CoalitionName)):FilterActive(true):FilterStart()
  end
  
  self.lid=string.format("PlayerTaskController %s %s | ", self.Name, tostring(self.Type))
  
  self:_InitLocalization() 
  
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
  
  self:__Start(2)
  local starttime = math.random(5,10)
  self:__Status(starttime)
  
  -- Player leaves
  self:HandleEvent(EVENTS.PlayerLeaveUnit, self._EventHandler)
  self:HandleEvent(EVENTS.Ejection, self._EventHandler)
  self:HandleEvent(EVENTS.Crash, self._EventHandler)
  self:HandleEvent(EVENTS.PilotDead, self._EventHandler)
  self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
  
  self:I(self.lid..self.version.." Started.")
  
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

--- [Internal] Init localization
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_InitLocalization()
  self:T(self.lid.."_InitLocalization")
  self.gettext = TEXTANDSOUND:New("PLAYERTASKCONTROLLER","en") -- Core.TextAndSound#TEXTANDSOUND
  self.locale = "en"
  for locale,table in pairs(self.Messages) do
    local Locale = string.lower(tostring(locale))
    self:T("**** Adding locale: "..Locale)
    for ID,Text in pairs(table) do
      self:T(string.format('Adding ID %s',tostring(ID)))
      self.gettext:AddEntry(Locale,tostring(ID),Text)
    end
  end
  return self
end

--- [User] Set flash directions option for player (player based info)
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean OnOff Set to `true` to switch on and `false` to switch off. Default is OFF.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetAllowFlashDirection(OnOff)
  self:T(self.lid.."SetAllowFlashDirection")
  self.AllowFlash = OnOff
  return self
end

--- [User] Do not show menu entries to smoke or flare targets
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetDisableSmokeFlareTask()
  self:T(self.lid.."SetDisableSmokeFlareTask")
  self.noflaresmokemenu = true
  return self
end

--- [User] For SRS - Switch to only transmit if there are players on the server.
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean Switch If true, only send SRS if there are alive Players.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetTransmitOnlyWithPlayers(Switch)
  self.TransmitOnlyWithPlayers = Switch
  if self.SRSQueue then
    self.SRSQueue:SetTransmitOnlyWithPlayers(Switch)
  end
  return self
end

--- [User] Show menu entries to smoke or flare targets (on by default!)
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetEnableSmokeFlareTask()
  self:T(self.lid.."SetEnableSmokeFlareTask")
  self.noflaresmokemenu = false
  return self
end

--- [User] Set callsign options for TTS output. See @{Wrapper.Group#GROUP.GetCustomCallSign}() on how to set customized callsigns.
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean ShortCallsign If true, only call out the major flight number
-- @param #boolean Keepnumber If true, keep the **customized callsign** in the #GROUP name for players as-is, no amendments or numbers.
-- @param #table CallsignTranslations (optional) Table to translate between DCS standard callsigns and bespoke ones. Does not apply if using customized
-- callsigns from playername or group name.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetCallSignOptions(ShortCallsign,Keepnumber,CallsignTranslations)
  if not ShortCallsign or ShortCallsign == false then
   self.ShortCallsign = false
  else
   self.ShortCallsign = true
  end
  self.Keepnumber = Keepnumber or false
  self.CallsignTranslations = CallsignTranslations
  return self  
end

--- [Internal] Get text for text-to-speech.
-- Numbers are spaced out, e.g. "Heading 180" becomes "Heading 1 8 0 ".
-- @param #PLAYERTASKCONTROLLER self
-- @param #string text Original text.
-- @return #string Spoken text.
function PLAYERTASKCONTROLLER:_GetTextForSpeech(text)
  
  -- Space out numbers.
  text=string.gsub(text,"%d","%1 ")
  -- get rid of leading or trailing spaces
  text=string.gsub(text,"^%s*","")
  text=string.gsub(text,"%s*$","")
  
  return text
end

--- [User] Set repetition options for tasks
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean OnOff Set to `true` to switch on and `false` to switch off (defaults to true)
-- @param #number Repeats Number of repeats (defaults to 5)
-- @return #PLAYERTASKCONTROLLER self
-- @usage `taskmanager:SetTaskRepetition(true, 5)`
function PLAYERTASKCONTROLLER:SetTaskRepetition(OnOff, Repeats)
  self:T(self.lid.."SetTaskRepetition")
  if OnOff then
    self.repeatonfailed = true
    self.repeattimes = Repeats or 5
  else
    self.repeatonfailed = false
    self.repeattimes = Repeats or 5
  end
  return self
end

--- [Internal] Send message to SET_CLIENT of players
-- @param #PLAYERTASKCONTROLLER self
-- @param #string Text the text to be send
-- @param #number Seconds (optional) Seconds to show, default 10
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_SendMessageToClients(Text,Seconds)
  self:T(self.lid.."_SendMessageToClients")
  local seconds = Seconds or 10
  self.ClientSet:ForEachClient(
    function (Client)
      local m = MESSAGE:New(Text,seconds,"Tasking"):ToClient(Client)
    end
  )
  return self
end

--- [User] Allow precision laser-guided bombing on statics and "high-value" ground units (MBT etc)
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup The FlightGroup (e.g. drone) to be used for lasing (one unit in one group only).
-- Can optionally be handed as Ops.ArmyGroup#ARMYGROUP - **Note** might not find an LOS spot or get lost on the way. Cannot island-hop.
-- @param #number LaserCode The lasercode to be used. Defaults to 1688.
-- @return #PLAYERTASKCONTROLLER self
-- @usage
-- -- Set up precision bombing, FlightGroup as lasing unit
--        local FlightGroup = FLIGHTGROUP:New("LasingUnit")
--        FlightGroup:Activate()
--        taskmanager:EnablePrecisionBombing(FlightGroup,1688)
--
-- -- Alternatively, set up precision bombing, ArmyGroup as lasing unit
--        local ArmyGroup = ARMYGROUP:New("LasingUnit")
--        ArmyGroup:SetDefaultROE(ENUMS.ROE.WeaponHold)
--        ArmyGroup:SetDefaultInvisible(true)
--        ArmyGroup:Activate()
--        taskmanager:EnablePrecisionBombing(ArmyGroup,1688)
--
function PLAYERTASKCONTROLLER:EnablePrecisionBombing(FlightGroup,LaserCode)
  self:T(self.lid.."EnablePrecisionBombing")
  if FlightGroup then
    if FlightGroup.ClassName and (FlightGroup.ClassName == "FLIGHTGROUP" or FlightGroup.ClassName == "ARMYGROUP")then
      -- ok we have a FG
      self.LasingDrone = FlightGroup -- Ops.FlightGroup#FLIGHTGROUP FlightGroup
      self.LasingDrone.playertask = {}
      self.LasingDrone.playertask.busy = false
      self.LasingDrone.playertask.id = 0
      self.precisionbombing = true
      self.LasingDrone:SetLaser(LaserCode)
      self.LaserCode = LaserCode or 1688
      self.LasingDroneTemplate = self.LasingDrone:_GetTemplate(true)
      -- let it orbit the BullsEye if FG
      if self.LasingDrone:IsFlightgroup() then
        local BullsCoordinate = COORDINATE:NewFromVec3( coalition.getMainRefPoint( self.Coalition ))
        local Orbit = AUFTRAG:NewORBIT_CIRCLE(BullsCoordinate,10000,120)
        self.LasingDrone:AddMission(Orbit)
      end
    else
      self:E(self.lid.."No FLIGHTGROUP object passed or FLIGHTGROUP is not alive!")
    end
  else
    self.autolase = nil
    self.precisionbombing = false
  end
  return self
end


--- [User] Allow precision laser-guided bombing on statics and "high-value" ground units (MBT etc) with player units lasing.
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.PlayerRecce#PLAYERRECCE Recce (Optional) The PLAYERRECCE object governing the lasing players.
-- @return #PLAYERTASKCONTROLLER self 
function PLAYERTASKCONTROLLER:EnableBuddyLasing(Recce)
  self:T(self.lid.."EnableBuddyLasing")
  self.buddylasing = true
  self.PlayerRecce = Recce
  return self
end

--- [User] Allow precision laser-guided bombing on statics and "high-value" ground units (MBT etc) with player units lasing.
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:DisableBuddyLasing()
  self:T(self.lid.."DisableBuddyLasing")
  self.buddylasing = false
  return self
end

--- [User] Allow addition of targets with user F10 map markers.
-- @param #PLAYERTASKCONTROLLER self
-- @param #string Tag (Optional) The tagname to use to identify commands, defaults to "TASK"
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:EnableMarkerOps(Tag)
  self:T(self.lid.."EnableMarkerOps")
   
  local tag = Tag or "TASK"
  local MarkerOps = MARKEROPS_BASE:New(tag)
  
  local function Handler(Keywords,Coord,Text)
    if self.verbose then
      local m = MESSAGE:New(string.format("Target added from marker at: %s", Coord:ToStringLLDMS()),15,"INFO"):ToAll()
    end
    self:AddTarget(Coord)
  end
  
  -- Event functions
  function MarkerOps:OnAfterMarkAdded(From,Event,To,Text,Keywords,Coord)
    Handler(Keywords,Coord,Text)
  end
  
  function MarkerOps:OnAfterMarkChanged(From,Event,To,Text,Keywords,Coord)
    Handler(Keywords,Coord,Text)
  end
  
  self.MarkerOps = MarkerOps 
   
  return self
end

--- [Internal] Get player name
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Client#CLIENT Client
-- @return #string playername
-- @return #string ttsplayername
function PLAYERTASKCONTROLLER:_GetPlayerName(Client)
  self:T(self.lid.."_GetPlayerName")
  local playername = Client:GetPlayerName()
  local ttsplayername = nil
  if not self.customcallsigns[playername] then
    local playergroup = Client:GetGroup()
    ttsplayername = playergroup:GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations)
    local newplayername = self:_GetTextForSpeech(ttsplayername)
    self.customcallsigns[playername] = newplayername
    ttsplayername = newplayername
  else
    ttsplayername = self.customcallsigns[playername]
  end
  return playername, ttsplayername
end

--- [User] Disable precision laser-guided bombing on statics and "high-value" ground units (MBT etc)
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:DisablePrecisionBombing(FlightGroup,LaserCode)
  self:T(self.lid.."DisablePrecisionBombing")
  self.autolase = nil
  self.precisionbombing = false
  return self
end

--- [User] Enable extra menu to show task detail information before joining
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:EnableTaskInfoMenu()
  self:T(self.lid.."EnableTaskInfoMenu")
  self.taskinfomenu = true
  return self
end

--- [User] Disable extra menu to show task detail information before joining
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:DisableTaskInfoMenu()
  self:T(self.lid.."DisableTaskInfoMenu")
  self.taskinfomenu = false
  return self
end

--- [User] Set menu build fine-tuning options
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean InfoMenu If `true` this option will allow to show the Task Info-Menu also when a player has an active task. 
-- Since the menu isn't refreshed if a player holds an active task, the info in there might be stale.
-- @param #number ItemLimit Number of items per task type to show, default 5. 
-- @param #number HoldTime Minimum number of seconds between menu refreshes (called every 30 secs) if a player has **no active task**.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetMenuOptions(InfoMenu,ItemLimit,HoldTime)
  self:T(self.lid.."SetMenuOptions")
  self.activehasinfomenu = InfoMenu or false
  if self.activehasinfomenu then
    self:EnableTaskInfoMenu()
  end
  self.menuitemlimit = ItemLimit or 5
  self.holdmenutime = HoldTime or 30
  return self
end

--- [User] Forbid F10 markers to be deleted by pilots. Note: Marker will auto-delete when the undelying task is done.
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetMarkerReadOnly()
  self:T(self.lid.."SetMarkerReadOnly")
  self.MarkerReadOnly = true
  return self
end

--- [User] Allow F10 markers to be deleted by pilots. Note: Marker will auto-delete when the undelying task is done.
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetMarkerDeleteable()
  self:T(self.lid.."SetMarkerDeleteable")
  self.MarkerReadOnly = false
  return self
end

--- [Internal] Event handling
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
            --text = "Task aborted!"
            text = self.gettext:GetEntry("TASKABORT",self.locale)
          end
        else
          --text = "No active task!"
          text = self.gettext:GetEntry("NOACTIVETASK",self.locale)
        end
        self:T(self.lid..text) 
    end
  elseif EventData.id == EVENTS.PlayerEnterAircraft and EventData.IniCoalition == self.Coalition then
    if EventData.IniPlayerName and EventData.IniGroup and self.UseSRS then
      self:T(self.lid.."Event for player: "..EventData.IniPlayerName)
      local frequency = self.Frequency
      local freqtext = ""
      if type(frequency) == "table" then
        freqtext = self.gettext:GetEntry("FREQUENCIES",self.locale)
        freqtext = freqtext..table.concat(frequency,", ")      
      else
        local freqt = self.gettext:GetEntry("FREQUENCY",self.locale)
        freqtext = string.format(freqt,frequency)
      end
      local modulation = self.Modulation
      if type(modulation) == "table" then modulation = modulation[1] end
      modulation = UTILS.GetModulationName(modulation)
      local switchtext = self.gettext:GetEntry("BROADCAST",self.locale)
      
      local playername = EventData.IniPlayerName 
      if EventData.IniGroup then
        -- personalized flight name in player naming
        if self.customcallsigns[playername] then
          self.customcallsigns[playername] = nil
        end
        playername = EventData.IniGroup:GetCustomCallSign(self.ShortCallsign,self.Keepnumber)
      end
      playername = self:_GetTextForSpeech(playername)
      --local text = string.format("%s, %s, switch to %s for task assignment!",EventData.IniPlayerName,self.MenuName or self.Name,freqtext)
      local text = string.format(switchtext,playername,self.MenuName or self.Name,freqtext)
      self.SRSQueue:NewTransmission(text,nil,self.SRS,timer.getAbsTime()+60,2,{EventData.IniGroup},text,30,self.BCFrequency,self.BCModulation)
    end
  end
  return self
end

--- [User] Set locale for localization. Defaults to "en"
-- @param #PLAYERTASKCONTROLLER self
-- @param #string Locale The locale to use
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetLocale(Locale)
  self:T(self.lid.."SetLocale")
  self.locale = Locale or "en"
  return self
end

--- [User] Switch screen output.
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean OnOff. Switch screen output off (true) or on (false)
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SuppressScreenOutput(OnOff)
  self:T(self.lid.."SuppressScreenOutput")
  self.NoScreenOutput = OnOff or false
  return self
end

--- [User] Set target radius. Determines the zone radius to distinguish CAS from BAI tasks and to find enemies if the TARGET object is a COORDINATE.
-- @param #PLAYERTASKCONTROLLER self
-- @param #number Radius Radius to use in meters. Defaults to 500 meters.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetTargetRadius(Radius)
  self:T(self.lid.."SetTargetRadius")
  self.TargetRadius = Radius or 500
  return self
end

--- [User] Set the cluster radius if you want to use target clusters rather than single group detection. 
-- Note that for a controller type A2A target clustering is on by default. Also remember that the diameter of the resulting zone is double the radius.
-- @param #PLAYERTASKCONTROLLER self
-- @param #number Radius Target cluster radius in kilometers. Default is 0.5km.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetClusterRadius(Radius)
  self:T(self.lid.."SetClusterRadius")
  self.ClusterRadius = Radius or 0.5
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
    if not task:IsDone() then
      threattable[#threattable+1]={task=task,threat=threat}
    end
  end
  
  table.sort(threattable, function (k1, k2) return k1.threat > k2.threat end )
  
  for _id,_data in pairs(threattable) do
    local threat=_data.threat
    local task = _data.task -- Ops.PlayerTask#PLAYERTASK
    local type = task.Type
    if not task:IsDone() then
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
      local TNow = timer.getAbsTime()
      if TNow - task.timestamp > 10 then
        local task = self.TaskQueue:PullByID(_id) -- Ops.PlayerTask#PLAYERTASK
        task = nil
      end
    end
   end
 end  
 return self
end

--- [Internal] Check precision task queue
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_CheckPrecisionTasks()
 self:T(self.lid.."_CheckTaskQueue")
 if self.PrecisionTasks:Count() > 0 and self.precisionbombing then
   if not self.LasingDrone or self.LasingDrone:IsDead() then
    -- we need a new drone
    self:E(self.lid.."Lasing drone is dead ... creating a new one!")
    if self.LasingDrone then
      self.LasingDrone:_Respawn(1,nil,true)
    else
      -- TODO: Handle ArmyGroup
      local FG = FLIGHTGROUP:New(self.LasingDroneTemplate)
      FG:Activate()
      self:EnablePrecisionBombing(FG,self.LaserCode or 1688)
    end
    return self
   end
  -- do we have a lasing unit assigned?
  if self.LasingDrone and self.LasingDrone:IsAlive() then
    if self.LasingDrone.playertask and (not self.LasingDrone.playertask.busy) then
      -- not busy, get a task
      self:T(self.lid.."Sending lasing unit to target")
      local task = self.PrecisionTasks:Pull() -- Ops.PlayerTask#PLAYERTASK
      self.LasingDrone.playertask.id = task.PlayerTaskNr
      self.LasingDrone.playertask.busy = true
      self.LasingDrone.playertask.inreach = false
      self.LasingDrone.playertask.reachmessage = false
      -- move the drone to target
      if self.LasingDrone:IsFlightgroup() then
        local auftrag = AUFTRAG:NewORBIT_CIRCLE(task.Target:GetCoordinate(),10000,120)
        local currmission = self.LasingDrone:GetMissionCurrent()
        self.LasingDrone:AddMission(auftrag)
        currmission:__Cancel(-2)
      elseif self.LasingDrone:IsArmygroup() then
        local tgtcoord = task.Target:GetCoordinate()
        local tgtzone = ZONE_RADIUS:New("ArmyGroup-"..math.random(1,10000),tgtcoord:GetVec2(),3000)
        local finalpos=nil -- Core.Point#COORDINATE
        for i=1,50 do
          finalpos = tgtzone:GetRandomCoordinate(2500,0,{land.SurfaceType.LAND,land.SurfaceType.ROAD,land.SurfaceType.SHALLOW_WATER}) 
          if finalpos then
            if finalpos:IsLOS(tgtcoord,0) then
              break
            end
          end
        end
        if finalpos then
          -- yeah we got one
          local auftrag = AUFTRAG:NewARMOREDGUARD(finalpos,"Off road")
          local currmission = self.LasingDrone:GetMissionCurrent()
          self.LasingDrone:AddMission(auftrag)
          if currmission then currmission:__Cancel(-2) end
        else
          -- could not find LOS position!
          self:E("***Could not find LOS position to post ArmyGroup for lasing!")
          self.LasingDrone.playertask.id = 0
          self.LasingDrone.playertask.busy = false
          self.LasingDrone.playertask.inreach = false
          self.LasingDrone.playertask.reachmessage = false
        end
      end
      self.PrecisionTasks:Push(task,task.PlayerTaskNr)
    elseif self.LasingDrone.playertask and self.LasingDrone.playertask.busy then
      -- drone is busy, set up laser when over target
      local task = self.PrecisionTasks:ReadByID(self.LasingDrone.playertask.id) -- Ops.PlayerTask#PLAYERTASK
      self:T("Looking at Task: "..task.PlayerTaskNr.." Type: "..task.Type.." State: "..task:GetState())
      if (not task) or task:GetState() == "Done" or task:GetState() == "Stopped" then
        -- we're done here
        local task = self.PrecisionTasks:PullByID(self.LasingDrone.playertask.id) -- Ops.PlayerTask#PLAYERTASK
        self:_CheckTaskQueue()
        task = nil
        if self.LasingDrone:IsLasing() then
          self.LasingDrone:__LaserOff(-1)
        end
        self.LasingDrone.playertask.busy = false
        self.LasingDrone.playertask.inreach = false
        self.LasingDrone.playertask.id = 0
        self.LasingDrone.playertask.reachmessage = false
        self:T(self.lid.."Laser Off")
      else
        -- not done yet
        local dcoord = self.LasingDrone:GetCoordinate()
        local tcoord = task.Target:GetCoordinate()
        local dist = dcoord:Get2DDistance(tcoord)
        -- close enough?
        if dist < 3000 and not self.LasingDrone:IsLasing() then
          self:T(self.lid.."Laser On")
          self.LasingDrone:__LaserOn(-1,tcoord)
          self.LasingDrone.playertask.inreach = true
          if not self.LasingDrone.playertask.reachmessage then
            --local textmark = self.gettext:GetEntry("FLARETASK",self.locale)
            self.LasingDrone.playertask.reachmessage = true
            local clients = task:GetClients()
            local text = ""
            for _,playername in pairs(clients) do
              local pointertext = self.gettext:GetEntry("POINTEROVERTARGET",self.locale)
              local ttsplayername = playername
              if self.customcallsigns[playername] then
                ttsplayername = self.customcallsigns[playername]
              end
              --text = string.format("%s, %s, pointer over target for task %03d, lasing!", playername, self.MenuName or self.Name, task.PlayerTaskNr)
              text = string.format(pointertext, ttsplayername, self.MenuName or self.Name, task.PlayerTaskNr)
              if not self.NoScreenOutput then
                local client = nil
                self.ClientSet:ForEachClient(
                  function(Client)
                    if Client:GetPlayerName() == playername then client = Client end
                  end
                ) 
                if client then
                    local m = MESSAGE:New(text,15,"Tasking"):ToClient(client)
                end
              end
            end
            if self.UseSRS then
              self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
            end
          end
        end
      end
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
-- @param Wrapper.Positionable#POSITIONABLE Target The target GROUP, SET\_GROUP, UNIT, SET\_UNIT, STATIC, SET\_STATIC, AIRBASE, ZONE or COORDINATE.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddTarget(Target)
  self:T(self.lid.."AddTarget")
  self.TargetQueue:Push(Target)
  return self
end

--- [Internal] Check for allowed task type, if there is a (positive) whitelist
-- @param #PLAYERTASKCONTROLLER self
-- @param #string Type
-- @return #boolean Outcome
function PLAYERTASKCONTROLLER:_CheckTaskTypeAllowed(Type)
  self:T(self.lid.."_CheckTaskTypeAllowed")
  local Outcome = false
  if self.UseWhiteList then
    for _,_type in pairs(self.WhiteList) do
      if Type == _type then
        Outcome = true
        break
      end
    end
  else
    return true
  end
  return Outcome
end

--- [Internal] Check for allowed task type, if there is a (negative) blacklist
-- @param #PLAYERTASKCONTROLLER self
-- @param #string Type
-- @return #boolean Outcome
function PLAYERTASKCONTROLLER:_CheckTaskTypeDisallowed(Type)
  self:T(self.lid.."_CheckTaskTypeDisallowed")
  local Outcome = false
  if self.UseBlackList then
    for _,_type in pairs(self.BlackList) do
      if Type == _type then
        Outcome = true
        break
      end
    end
  else
    return true
  end
  return Outcome
end

--- [User] Set up a (positive) whitelist of allowed task types. Only these types will be generated.
-- @param #PLAYERTASKCONTROLLER self
-- @param #table WhiteList Table of task types that can be generated. Use to restrict available types.
-- @return #PLAYERTASKCONTROLLER self
-- @usage Currently, the following task types will be generated, if detection has been set up:
-- A2A - AUFTRAG.Type.INTERCEPT
-- A2S - AUFTRAG.Type.ANTISHIP
-- A2G - AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.SEAD, AUFTRAG.Type.BOMBING, AUFTRAG.Type.PRECISIONBOMBING, AUFTRAG.Type.BOMBRUNWAY
-- A2GS - A2G + A2S
-- If you don't want SEAD tasks generated, use as follows where "mycontroller" is your PLAYERTASKCONTROLLER object:
-- 
--            `mycontroller:SetTaskWhiteList({AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING, AUFTRAG.Type.BOMBRUNWAY})`
--            
function PLAYERTASKCONTROLLER:SetTaskWhiteList(WhiteList)
  self:T(self.lid.."SetTaskWhiteList")
  self.WhiteList = WhiteList
  self.UseWhiteList = true
  return self
end

--- [User] Set up a (negative) blacklist of forbidden task types. These types will **not** be generated.
-- @param #PLAYERTASKCONTROLLER self
-- @param #table BlackList Table of task types that cannot be generated. Use to restrict available types.
-- @return #PLAYERTASKCONTROLLER self
-- @usage Currently, the following task types will be generated, if detection has been set up:
-- A2A - AUFTRAG.Type.INTERCEPT
-- A2S - AUFTRAG.Type.ANTISHIP
-- A2G - AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.SEAD, AUFTRAG.Type.BOMBING, AUFTRAG.Type.PRECISIONBOMBING, AUFTRAG.Type.BOMBRUNWAY
-- A2GS - A2G + A2S
-- If you don't want SEAD tasks generated, use as follows where "mycontroller" is your PLAYERTASKCONTROLLER object:
-- 
--            `mycontroller:SetTaskBlackList({AUFTRAG.Type.SEAD})`
--            
function PLAYERTASKCONTROLLER:SetTaskBlackList(BlackList)
  self:T(self.lid.."SetTaskBlackList")
  self.BlackList = BlackList
  self.UseBlackList = true
  return self
end

--- [User] Change the list of attributes, which are considered on GROUP or SET\_GROUP level of a target to create SEAD player tasks.
-- @param #PLAYERTASKCONTROLLER self
-- @param #table Attributes Table of attribute types considered to lead to a SEAD type player task.
-- @return #PLAYERTASKCONTROLLER self
-- @usage
-- Default attribute types are: GROUP.Attribute.GROUND_SAM, GROUP.Attribute.GROUND_AAA, and GROUP.Attribute.GROUND_EWR.
-- If you want to e.g. exclude AAA, so target groups with this attribute are assigned CAS or BAI tasks, and not SEAD, use this function as follows:
--
--            `mycontroller:SetSEADAttributes({GROUP.Attribute.GROUND_SAM, GROUP.Attribute.GROUND_EWR})`
--
function PLAYERTASKCONTROLLER:SetSEADAttributes(Attributes)
  self:T(self.lid.."SetSEADAttributes")
  if type(Attributes) ~= "table" then
    Attributes = {Attributes}
  end
  self.SeadAttributes = Attributes
  return self
end

--- [Internal] Function the check against SeadAttributes
-- @param #PLAYERTASKCONTROLLER self
-- @param #string Attribute
-- @return #boolean IsSead
function PLAYERTASKCONTROLLER:_IsAttributeSead(Attribute)
  self:T(self.lid.."_IsAttributeSead?")
  local IsSead = false
  for _,_attribute in pairs(self.SeadAttributes) do
    if Attribute == _attribute then
      IsSead = true
      break
    end
  end
  return IsSead
end

--- [Internal] Add a task to the task queue
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.Target#TARGET Target
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_AddTask(Target)
  self:T(self.lid.."_AddTask")
  local cat = Target:GetCategory()
  local threat = Target:GetThreatLevelMax()
  local type = AUFTRAG.Type.CAS
  
  --local ttstype = "close air support"
  local ttstype = self.gettext:GetEntry("CASTTS",self.locale)
  
  if cat == TARGET.Category.GROUND then
    type = AUFTRAG.Type.CAS
    -- TODO: debug BAI, CAS, SEAD
    local targetobject = Target:GetObject() -- Wrapper.Positionable#POSITIONABLE
    if targetobject:IsInstanceOf("UNIT") then
      self:T("SEAD Check UNIT")
      if targetobject:HasSEAD() then
        type = AUFTRAG.Type.SEAD
        --ttstype = "suppress air defense"
        ttstype = self.gettext:GetEntry("SEADTTS",self.locale)
      end
    elseif targetobject:IsInstanceOf("GROUP") then
      self:T("SEAD Check GROUP")
      local attribute = targetobject:GetAttribute()
       if self:_IsAttributeSead(attribute) then
        type = AUFTRAG.Type.SEAD
        --ttstype = "suppress air defense"
        ttstype = self.gettext:GetEntry("SEADTTS",self.locale)
       end
    elseif targetobject:IsInstanceOf("SET_GROUP") then
      self:T("SEAD Check SET_GROUP")
      targetobject:ForEachGroup(
        function (group)
          local attribute = group:GetAttribute()
           if self:_IsAttributeSead(attribute) then
            type = AUFTRAG.Type.SEAD
            --ttstype = "suppress air defense"
            ttstype = self.gettext:GetEntry("SEADTTS",self.locale)
           end
        end
      )     
    elseif targetobject:IsInstanceOf("SET_UNIT") then
      self:T("SEAD Check SET_UNIT")
      targetobject:ForEachUnit(
        function (unit)
          if unit:HasSEAD() then
            type = AUFTRAG.Type.SEAD
            --ttstype = "suppress air defenses"
            ttstype = self.gettext:GetEntry("SEADTTS",self.locale)
          end
        end
      )
    elseif targetobject:IsInstanceOf("SET_STATIC") or targetobject:IsInstanceOf("STATIC") then
      self:T("(PRECISION-)BOMBING SET_STATIC or STATIC")
      if self.precisionbombing then
        type = AUFTRAG.Type.PRECISIONBOMBING
        ttstype = self.gettext:GetEntry("PRECBOMBTTS",self.locale)
      else
        type = AUFTRAG.Type.BOMBING
        ttstype = self.gettext:GetEntry("BOMBTTS",self.locale)
      end

    end
    -- if there are no friendlies nearby ~0.5km and task isn't SEAD, then it's BAI
    local targetcoord = Target:GetCoordinate()
    local targetvec2 = targetcoord:GetVec2()
    local targetzone = ZONE_RADIUS:New(self.Name,targetvec2,self.TargetRadius)
    local coalition = targetobject:GetCoalitionName() or "Blue"
    coalition = string.lower(coalition)
    self:T("Target coalition is "..tostring(coalition))
    local filtercoalition = "blue"
    if coalition == "blue" then filtercoalition = "red" end
    local friendlyset = SET_GROUP:New():FilterCategoryGround():FilterCoalitions(filtercoalition):FilterZones({targetzone}):FilterOnce()
    if friendlyset:Count() == 0 and type == AUFTRAG.Type.CAS then
      type = AUFTRAG.Type.BAI
      --ttstype = "battle field air interdiction"
      ttstype = self.gettext:GetEntry("BAITTS",self.locale)
    end
    -- see if we can do precision bombing
    if (type == AUFTRAG.Type.BAI or type == AUFTRAG.Type.CAS) and (self.precisionbombing or self.buddylasing) then
      -- threatlevel between 3 and 6 means, it's artillery, tank, modern tank or AAA
      if threat > 2 and threat < 7 then
        type = AUFTRAG.Type.PRECISIONBOMBING
        ttstype = self.gettext:GetEntry("PRECBOMBTTS",self.locale)
      end
    end
  elseif cat == TARGET.Category.NAVAL then
    type = AUFTRAG.Type.ANTISHIP
    --ttstype = "anti-ship"
    ttstype = self.gettext:GetEntry("ANTISHIPTTS",self.locale)
  elseif cat == TARGET.Category.AIRCRAFT then
    type = AUFTRAG.Type.INTERCEPT
    --ttstype = "intercept"
    ttstype = self.gettext:GetEntry("INTERCEPTTS",self.locale)
  elseif cat == TARGET.Category.AIRBASE then
    --TODO: Define Success Criteria, AB hit? Runway blocked, how to determine? change of coalition? Void of enemies?
    -- Current implementation - bombing in AFB zone (EVENTS.Shot)
    type = AUFTRAG.Type.BOMBRUNWAY
    -- ttstype = "bomb runway"
    ttstype = self.gettext:GetEntry("BOMBRUNWAYTTS",self.locale)
  elseif cat == TARGET.Category.COORDINATE or cat == TARGET.Category.ZONE then
    --TODO: Define Success Criteria, void of enemies?
    -- Current implementation - find SET of enemies in ZONE or 500m radius around coordinate, and assign as targets
    local zone = Target:GetObject()
    if cat == TARGET.Category.COORDINATE then
      zone = ZONE_RADIUS:New("TargetZone-"..math.random(1,10000),Target:GetVec2(),self.TargetRadius)
    end
    -- find some enemies around there...
    local enemies = self.CoalitionName == "Blue" and "red" or "blue"
    local enemysetg = SET_GROUP:New():FilterCoalitions(enemies):FilterCategoryGround():FilterActive(true):FilterZones({zone}):FilterOnce()
    local enemysets = SET_STATIC:New():FilterCoalitions(enemies):FilterZones({zone}):FilterOnce()
    local countg = enemysetg:Count()
    local counts = enemysets:Count()
    if countg > 0 then
      self:AddTarget(enemysetg)
    end
    if counts > 0 then
      self:AddTarget(enemysets)
    end
    return self
  end
  
  if self.UseWhiteList then
    if not self:_CheckTaskTypeAllowed(type) then
      return self
    end
  end
  
  if self.UseBlackList then
    if self:_CheckTaskTypeDisallowed(type) then
      return self
    end
  end
  
  local task = PLAYERTASK:New(type,Target,self.repeatonfailed,self.repeattimes,ttstype)
  
  task.coalition = self.Coalition
  
  if type == AUFTRAG.Type.BOMBRUNWAY then
    -- task to handle event shot
    task:HandleEvent(EVENTS.Shot)
    function task:OnEventShot(EventData)
      local data = EventData -- Core.Event#EVENTDATA EventData
      local wcat = data.Weapon:getCategory() -- cat 2 or 3
      local coord = data.IniUnit:GetCoordinate() or data.IniGroup:GetCoordinate()
      local vec2 = coord:GetVec2()  or {x=0, y=0}
      local coal = data.IniCoalition
      local afbzone = AIRBASE:FindByName(Target:GetName()):GetZone()
      local runways = AIRBASE:FindByName(Target:GetName()):GetRunways() or {}
      local inrunwayzone = false
      for _,_runway in pairs(runways) do
        local runway = _runway -- Wrapper.Airbase#AIRBASE.Runway
        if runway.zone:IsVec2InZone(vec2) then
          inrunwayzone = true
        end
      end
      local inzone = afbzone:IsVec2InZone(vec2)
      if coal == task.coalition and (wcat == 2 or wcat == 3) and (inrunwayzone or inzone) then
        -- bombing/rockets inside target AFB zone - well done!
        task:__Success(-20)
      end
    end
  end
  
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
  local playername, ttsplayername = self:_GetPlayerName(Client)
  if self.TasksPerPlayer:HasUniqueID(playername) then
    -- Player already has a task
    if not self.NoScreenOutput then
      local text = self.gettext:GetEntry("HAVEACTIVETASK",self.locale)
      local m=MESSAGE:New(text,"10","Tasking"):ToClient(Client)
    end
    return self
  end
  local taskstate = Task:GetState()
  if not Task:IsDone() then
    if taskstate ~= "Executing" then
      Task:__Requested(-1)
      Task:__Executing(-2)
    end
    Task:AddClient(Client)
    local joined = self.gettext:GetEntry("PILOTJOINEDTASK",self.locale)
    -- PILOTJOINEDTASK = "%s, %s. You have been assigned %s task %03d",
    local text = string.format(joined,ttsplayername, self.MenuName or self.Name, Task.TTSType, Task.PlayerTaskNr)
    self:T(self.lid..text)
    if not self.NoScreenOutput then
      self:_SendMessageToClients(text)
      --local m=MESSAGE:New(text,"10","Tasking"):ToAll()
    end
    if self.UseSRS then
      self:I(self.lid..text)
      self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
    end
    self.TasksPerPlayer:Push(Task,playername)
    -- clear menu
    self:_BuildMenus(Client,true)
  end
  if Task.Type == AUFTRAG.Type.PRECISIONBOMBING then
    if not self.PrecisionTasks:HasUniqueID(Task.PlayerTaskNr) then
      self.PrecisionTasks:Push(Task,Task.PlayerTaskNr)
    end
  end
  return self
end

--- [Internal] Switch flashing info for a client
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_SwitchFlashing(Group, Client)
  self:T(self.lid.."_SwitchFlashing")
  local playername, ttsplayername = self:_GetPlayerName(Client)
  if (not self.FlashPlayer[playername]) or (self.FlashPlayer[playername] == false) then
    -- Switch on
    self.FlashPlayer[playername] = Client
    local flashtext = self.gettext:GetEntry("FLASHON",self.locale)
    local text = string.format(flashtext,ttsplayername)
    local m = MESSAGE:New(text,10,"Tasking"):ToClient(Client)
  else
    -- Switch off
    self.FlashPlayer[playername] = false
    local flashtext = self.gettext:GetEntry("FLASHOFF",self.locale)
    local text = string.format(flashtext,ttsplayername)
    local m = MESSAGE:New(text,10,"Tasking"):ToClient(Client)
  end
  return self
end

--- [Internal] Flashing directional info for a client
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_FlashInfo()
  self:T(self.lid.."_FlashInfo")
  for _playername,_client in pairs(self.FlashPlayer) do
    if _client and _client:IsAlive() then
      if self.TasksPerPlayer:HasUniqueID(_playername) then
        local task = self.TasksPerPlayer:ReadByID(_playername) -- Ops.PlayerTask#PLAYERTASK
        local Coordinate = task.Target:GetCoordinate()
        local CoordText = ""
        if self.Type ~= PLAYERTASKCONTROLLER.Type.A2A then
          CoordText = Coordinate:ToStringA2G(_client)
        else
          CoordText = Coordinate:ToStringA2A(_client)
        end
        local targettxt = self.gettext:GetEntry("TARGET",self.locale)
        local text = "Target: "..CoordText
        local m = MESSAGE:New(text,10,"Tasking"):ToClient(_client)
      end
    end
  end
  return self
end

--- [Internal] Show active task info
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_ActiveTaskInfo(Group, Client, Task)
  self:T(self.lid.."_ActiveTaskInfo")
  local playername, ttsplayername = self:_GetPlayerName(Client)
  local text = ""
  if self.TasksPerPlayer:HasUniqueID(playername) or Task then
    -- TODO: Show multiple?
    local task = Task or self.TasksPerPlayer:ReadByID(playername) -- Ops.PlayerTask#PLAYERTASK
    local tname = self.gettext:GetEntry("TASKNAME",self.locale)
    local ttsname = self.gettext:GetEntry("TASKNAMETTS",self.locale)
    local taskname = string.format(tname,task.Type,task.PlayerTaskNr)
    local ttstaskname = string.format(ttsname,task.TTSType,task.PlayerTaskNr)
    local Coordinate = task.Target:GetCoordinate()
    local CoordText = ""
    if self.Type ~= PLAYERTASKCONTROLLER.Type.A2A then
      CoordText = Coordinate:ToStringA2G(Client)
    else
      CoordText = Coordinate:ToStringA2A(Client)
    end
    local ThreatLevel = task.Target:GetThreatLevelMax()
    --local ThreatLevelText = "high"
    local ThreatLevelText = self.gettext:GetEntry("THREATHIGH",self.locale)
    if ThreatLevel > 3 and ThreatLevel < 8 then
     --ThreatLevelText = "medium"
     ThreatLevelText = self.gettext:GetEntry("THREATMEDIUM",self.locale)
    elseif  ThreatLevel <= 3 then
     --ThreatLevelText = "low"
     ThreatLevelText = self.gettext:GetEntry("THREATLOW",self.locale)
    end
    local targets = task.Target:CountTargets() or 0
    local clientlist, clientcount = task:GetClients()
    local ThreatGraph = "[" .. string.rep(  "■", ThreatLevel ) .. string.rep(  "□", 10 - ThreatLevel ) .. "]: "..ThreatLevel
    local ThreatLocaleText = self.gettext:GetEntry("THREATTEXT",self.locale)
    text = string.format(ThreatLocaleText, taskname, ThreatGraph, targets, CoordText)
    if task.Type == AUFTRAG.Type.PRECISIONBOMBING and self.precisionbombing then
      if self.LasingDrone and self.LasingDrone.playertask then
        local yes = self.gettext:GetEntry("YES",self.locale)
        local no = self.gettext:GetEntry("NO",self.locale)
        local inreach = self.LasingDrone.playertask.inreach == true and yes or no
        local islasing = self.LasingDrone:IsLasing() == true and yes or no
        local prectext = self.gettext:GetEntry("POINTERTARGETREPORT",self.locale)
        prectext = string.format(prectext,inreach,islasing)
        text = text .. prectext
      end
    end
   if task.Type == AUFTRAG.Type.PRECISIONBOMBING and self.buddylasing then
    if self.PlayerRecce then
      local yes = self.gettext:GetEntry("YES",self.locale)
      local no = self.gettext:GetEntry("NO",self.locale)
      -- TODO make dist dependent on PlayerRecce Object
      local reachdist = 8000
      local inreach = false
      -- someone close enough?
      local pset = self.PlayerRecce.PlayerSet:GetAliveSet()
      for _,_player in pairs(pset) do
        local player = _player -- Wrapper.Client#CLIENT
        local pcoord = player:GetCoordinate()
        if pcoord:Get2DDistance(Coordinate) <= reachdist then
          inreach = true
          local callsign = player:GetGroup():GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations)
          local playername = player:GetPlayerName()
          local islasing = no
          if self.PlayerRecce.CanLase[player:GetTypeName()] and self.PlayerRecce.AutoLase[playername] then
            -- TODO - maybe compare Spot target
            islasing = yes
          end
          local inrtext = inreach == true and yes or no
          local prectext = self.gettext:GetEntry("RECCETARGETREPORT",self.locale)
          -- RECCETARGETREPORT = "\nSpäher % im Zielbereich: %s\nLasing: %s",
          prectext = string.format(prectext,callsign,inrtext,islasing)
          text = text .. prectext
        end
      end
    end
   end
    local clienttxt = self.gettext:GetEntry("PILOTS",self.locale)
    if clientcount > 0 then
      for _,_name in pairs(clientlist) do
        if self.customcallsigns[_name] then
          -- personalized flight name in player naming
          --_name = string.match(_name,"| ([%a]+)")
          _name = self.customcallsigns[_name] 
        end
        clienttxt = clienttxt .. _name .. ", "
      end
      clienttxt=string.gsub(clienttxt,", $",".")
    else
      local keine = self.gettext:GetEntry("NONE",self.locale)
      clienttxt = clienttxt .. keine
    end
    text = text .. clienttxt
    if self.UseSRS then
      if string.find(CoordText," BR, ") then
        CoordText = string.gsub(CoordText," BR, "," Bee, Arr, ")
      end
      local ThreatLocaleTextTTS = self.gettext:GetEntry("THREATTEXTTTS",self.locale)
      local ttstext = string.format(ThreatLocaleTextTTS,self.MenuName or self.Name,ttsplayername,ttstaskname,ThreatLevelText, targets, CoordText)
      -- POINTERTARGETLASINGTTS = ". Pointer over target and lasing."
      if task.Type == AUFTRAG.Type.PRECISIONBOMBING and self.precisionbombing then
        if self.LasingDrone.playertask.inreach and self.LasingDrone:IsLasing() then
          local lasingtext = self.gettext:GetEntry("POINTERTARGETLASINGTTS",self.locale)
          ttstext = ttstext .. lasingtext
        end
      end
      self.SRSQueue:NewTransmission(ttstext,nil,self.SRS,nil,2)
    end  
  else
    text = self.gettext:GetEntry("NOACTIVETASK",self.locale)
  end
  if not self.NoScreenOutput then
    local m=MESSAGE:New(text,15,"Tasking"):ToClient(Client)
  end
  return self
end

--- [Internal] Mark task on F10 map
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_MarkTask(Group, Client)
  self:T(self.lid.."_MarkTask")
  local playername, ttsplayername = self:_GetPlayerName(Client)
  local text = ""
  if self.TasksPerPlayer:HasUniqueID(playername) then
    local task = self.TasksPerPlayer:ReadByID(playername) -- Ops.PlayerTask#PLAYERTASK
    text = string.format("Task ID #%03d | Type: %s | Threat: %d",task.PlayerTaskNr,task.Type,task.Target:GetThreatLevelMax())
    task:MarkTargetOnF10Map(text,self.Coalition,self.MarkerReadOnly)
    local textmark = self.gettext:GetEntry("MARKTASK",self.locale)
    --text = string.format("%s, copy pilot %s, task %03d location marked on map!", self.MenuName or self.Name, playername, task.PlayerTaskNr)
    text = string.format(textmark, ttsplayername, self.MenuName or self.Name, task.PlayerTaskNr)
    self:T(self.lid..text)
    if self.UseSRS then
      self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
    end
  else
    text = self.gettext:GetEntry("NOACTIVETASK",self.locale)
  end
  if not self.NoScreenOutput then
    local m=MESSAGE:New(text,"10","Tasking"):ToClient(Client)
  end
  return self
end

--- [Internal] Smoke task location
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_SmokeTask(Group, Client)
  self:T(self.lid.."_SmokeTask")
  local playername, ttsplayername = self:_GetPlayerName(Client) 
  local text = ""
  if self.TasksPerPlayer:HasUniqueID(playername) then
    local task = self.TasksPerPlayer:ReadByID(playername) -- Ops.PlayerTask#PLAYERTASK
    task:SmokeTarget()
    local textmark = self.gettext:GetEntry("SMOKETASK",self.locale)
    text = string.format(textmark, ttsplayername, self.MenuName or self.Name, task.PlayerTaskNr)
    self:T(self.lid..text)
    --local m=MESSAGE:New(text,"10","Tasking"):ToAll()
    if self.UseSRS then
      self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
    end
  else
    text = self.gettext:GetEntry("NOACTIVETASK",self.locale)
  end
  if not self.NoScreenOutput then
    local m=MESSAGE:New(text,15,"Tasking"):ToClient(Client)
  end
  return self
end

--- [Internal] Flare task location
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_FlareTask(Group, Client)
  self:T(self.lid.."_FlareTask")
  local playername, ttsplayername = self:_GetPlayerName(Client)
  local text = ""
  if self.TasksPerPlayer:HasUniqueID(playername) then
    local task = self.TasksPerPlayer:ReadByID(playername) -- Ops.PlayerTask#PLAYERTASK
    task:FlareTarget()
    local textmark = self.gettext:GetEntry("FLARETASK",self.locale)
    text = string.format(textmark, ttsplayername, self.MenuName or self.Name, task.PlayerTaskNr)
    self:T(self.lid..text)
    --local m=MESSAGE:New(text,"10","Tasking"):ToAll()
    if self.UseSRS then
      self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
    end
  else
    text = self.gettext:GetEntry("NOACTIVETASK",self.locale)
  end
  if not self.NoScreenOutput then
    local m=MESSAGE:New(text,15,"Tasking"):ToClient(Client)
  end
  return self
end

--- [Internal] Abort Task
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_AbortTask(Group, Client)
  self:T(self.lid.."_FlareTask")
  local playername, ttsplayername = self:_GetPlayerName(Client)
  local text = ""
  if self.TasksPerPlayer:HasUniqueID(playername) then
    local task = self.TasksPerPlayer:PullByID(playername) -- Ops.PlayerTask#PLAYERTASK
    task:ClientAbort(Client)
    local textmark = self.gettext:GetEntry("ABORTTASK",self.locale)
    -- ABORTTASK = "%s, to all stations, %s has aborted %s task %03d!",
    text = string.format(textmark, self.MenuName or self.Name, ttsplayername, task.TTSType, task.PlayerTaskNr)
    self:T(self.lid..text)
    --local m=MESSAGE:New(text,"10","Tasking"):ToAll()
    if self.UseSRS then
      self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
    end
  else
    text = self.gettext:GetEntry("NOACTIVETASK",self.locale)
  end
  if not self.NoScreenOutput then
    local m=MESSAGE:New(text,15,"Tasking"):ToClient(Client)
  end
  self:_BuildMenus(Client,true)
  return self
end

--- [Internal] Build Task Info Menu
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP group
-- @param Wrapper.Client#CLIENT client
-- @param #string playername
-- @param Core.Menu#MENU_BASE topmenu
-- @param #table tasktypes
-- @param #table taskpertype
-- @return #table taskinfomenu
function PLAYERTASKCONTROLLER:_BuildTaskInfoMenu(group,client,playername,topmenu,tasktypes,taskpertype)
  self:T(self.lid.."_BuildTaskInfoMenu")
  local taskinfomenu = nil
  if self.taskinfomenu then
    local menutaskinfo = self.gettext:GetEntry("MENUTASKINFO",self.locale)
    local taskinfomenu = MENU_GROUP_DELAYED:New(group,menutaskinfo,topmenu) 
    local ittypes = {}
    local itaskmenu = {}
    
    for _tasktype,_data in pairs(tasktypes) do
      ittypes[_tasktype] = MENU_GROUP_DELAYED:New(group,_tasktype,taskinfomenu)
      local tasks =  taskpertype[_tasktype] or {}
      local n = 0
      for _,_task in pairs(tasks) do
        _task = _task -- Ops.PlayerTask#PLAYERTASK
        local pilotcount = _task:CountClients()
        local newtext = "]"
        local tnow = timer.getTime()
        -- marker for new tasks
        if tnow - _task.timestamp < 60 then
          newtext = "*]"
        end
        local menutaskno = self.gettext:GetEntry("MENUTASKNO",self.locale)
        local text = string.format("%s %03d [%d%s",menutaskno,_task.PlayerTaskNr,pilotcount,newtext)
        if self.UseGroupNames then
          local name = _task.Target:GetName()
          if name ~= "Unknown" then
            text = string.format("%s (%03d) [%d%s",name,_task.PlayerTaskNr,pilotcount,newtext)
          end
        end
        local taskentry = MENU_GROUP_COMMAND_DELAYED:New(group,text,ittypes[_tasktype],self._ActiveTaskInfo,self,group,client,_task)
        --taskentry:SetTag(playername)
        itaskmenu[#itaskmenu+1] = taskentry
        -- keep max items limit
        n = n + 1
        if n >= self.menuitemlimit then
          break
        end          
      end
    end
  end
  return taskinfomenu
end

--- [Internal] Build client menus
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Client#CLIENT Client (optional) build for this client name only
-- @param #boolean enforced
-- @param #boolean fromsuccess
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_BuildMenus(Client,enforced,fromsuccess)
  self:T(self.lid.."_BuildMenus")

  local clients = self.ClientSet:GetAliveSet()
  local joinorabort = false
  local timedbuild = false
  
  if Client then
    -- client + enforced -- join task or abort
    clients = {Client}
    enforced = true
    joinorabort = true
  end
  
  for _,_client in pairs(clients) do
    if _client then
      local client = _client -- Wrapper.Client#CLIENT
      local group = client:GetGroup()
      local unknown = self.gettext:GetEntry("UNKNOWN",self.locale)
      local playername = client:GetPlayerName() or unknown
      if group and client then
        ---
        -- TOPMENU
        ---
        local taskings = self.gettext:GetEntry("MENUTASKING",self.locale)
        local longname = self.Name..taskings..self.Type
        local menuname = self.MenuName or longname
        local playerhastask = false
        
        if self:_CheckPlayerHasTask(playername) and not fromsuccess then playerhastask = true end
        local topmenu = nil
        
        self:T("Playerhastask = "..tostring(playerhastask).." Enforced = "..tostring(enforced).." Join or Abort = "..tostring(joinorabort))
        
        -- Cases to rebuild menu
        -- 1) new player
        -- 2) player joined a task, joinorabort = true
        -- 3) player left a task, joinorabort = true
        -- 4) player has no task, but number of tasks changed, and last build > 30 secs ago
        if self.PlayerMenu[playername] then
          -- NOT a new player
          -- 2)+3) Join or abort?
          if joinorabort then
            self.PlayerMenu[playername]:RemoveSubMenus()
            self.PlayerMenu[playername]:SetTag(timer.getAbsTime())
            topmenu = self.PlayerMenu[playername]
          elseif (not playerhastask) or enforced then
            -- 4) last build > 30 secs?
            local T0 = timer.getAbsTime()
            local TDiff = T0-self.PlayerMenu[playername].MenuTag
            self:T("TDiff = "..string.format("%.2d",TDiff))
            if TDiff >= self.holdmenutime then
              self.PlayerMenu[playername]:RemoveSubMenus()
              self.PlayerMenu[playername]:SetTag(timer.getAbsTime())
              timedbuild = true
            end
            topmenu = self.PlayerMenu[playername]
          end
        else
          -- 1) new player#
          topmenu = MENU_GROUP_DELAYED:New(group,menuname,nil)
          self.PlayerMenu[playername] = topmenu
          self.PlayerMenu[playername]:SetTag(timer.getAbsTime())
        end
        
        ---
        -- ACTIVE TASK MENU
        ---
        if playerhastask and enforced then
          --self:T("Building Active Task Menus for "..playername)
          local menuactive = self.gettext:GetEntry("MENUACTIVE",self.locale)
          local menuinfo = self.gettext:GetEntry("MENUINFO",self.locale)
          local menumark = self.gettext:GetEntry("MENUMARK",self.locale)
          local menusmoke = self.gettext:GetEntry("MENUSMOKE",self.locale)
          local menuflare = self.gettext:GetEntry("MENUFLARE",self.locale)
          local menuabort = self.gettext:GetEntry("MENUABORT",self.locale)
          
          local active = MENU_GROUP_DELAYED:New(group,menuactive,topmenu)
          local info = MENU_GROUP_COMMAND_DELAYED:New(group,menuinfo,active,self._ActiveTaskInfo,self,group,client)
          local mark = MENU_GROUP_COMMAND_DELAYED:New(group,menumark,active,self._MarkTask,self,group,client)
          if self.Type ~= PLAYERTASKCONTROLLER.Type.A2A then
            if self.noflaresmokemenu ~= true then
              -- no smoking/flaring here if A2A or designer has set noflaresmokemenu to true
              local smoke = MENU_GROUP_COMMAND_DELAYED:New(group,menusmoke,active,self._SmokeTask,self,group,client)
              local flare = MENU_GROUP_COMMAND_DELAYED:New(group,menuflare,active,self._FlareTask,self,group,client)
            end
          end
          local abort = MENU_GROUP_COMMAND_DELAYED:New(group,menuabort,active,self._AbortTask,self,group,client)
          if self.activehasinfomenu and self.taskinfomenu then
            --self:T("Building Active-Info Menus for "..playername)
            local tasktypes = self:_GetAvailableTaskTypes()
            local taskpertype = self:_GetTasksPerType()
            if self.PlayerInfoMenu[playername] then
              self.PlayerInfoMenu[playername]:RemoveSubMenus()
            end
            self.PlayerInfoMenu[playername] = self:_BuildTaskInfoMenu(group,client,playername,topmenu,tasktypes,taskpertype)
          end
        elseif (self.TaskQueue:Count() > 0 and enforced) or (not playerhastask and (timedbuild or joinorabort)) then
          --self:T("Building Join Menus for "..playername)
        ---
        -- JOIN TASK MENU
        --- 
          local tasktypes = self:_GetAvailableTaskTypes()
          local taskpertype = self:_GetTasksPerType()
          local menujoin = self.gettext:GetEntry("MENUJOIN",self.locale)
          local joinmenu = MENU_GROUP_DELAYED:New(group,menujoin,topmenu)
          
          local ttypes = {}
          local taskmenu = {}
          for _tasktype,_data in pairs(tasktypes) do
            ttypes[_tasktype] = MENU_GROUP_DELAYED:New(group,_tasktype,joinmenu)
            local tasks =  taskpertype[_tasktype] or {}
            local n = 0
            for _,_task in pairs(tasks) do
              _task = _task -- Ops.PlayerTask#PLAYERTASK
              local pilotcount = _task:CountClients()
              local newtext = "]"
              local tnow = timer.getTime()
              -- marker for new tasks
              if tnow - _task.timestamp < 60 then
                newtext = "*]"
              end
              local menutaskno = self.gettext:GetEntry("MENUTASKNO",self.locale)
              local text = string.format("%s %03d [%d%s",menutaskno,_task.PlayerTaskNr,pilotcount,newtext)
              if self.UseGroupNames then
                local name = _task.Target:GetName()
                if name ~= "Unknown" then
                  text = string.format("%s (%03d) [%d%s",name,_task.PlayerTaskNr,pilotcount,newtext)
                end
              end
              local taskentry = MENU_GROUP_COMMAND_DELAYED:New(group,text,ttypes[_tasktype],self._JoinTask,self,group,client,_task)
              --taskentry:SetTag(playername)
              taskmenu[#taskmenu+1] = taskentry
              n = n + 1
              if n >= self.menuitemlimit then
                break
              end   
            end
          end
          if self.taskinfomenu then
            --self:T("Building Join-Info Menus for "..playername)
            if self.PlayerInfoMenu[playername] then
              self.PlayerInfoMenu[playername]:RemoveSubMenus()
            end
            self.PlayerInfoMenu[playername] = self:_BuildTaskInfoMenu(group,client,playername,topmenu,tasktypes,taskpertype)
          end
        elseif self.TaskQueue:Count() == 0 then
          -- no tasks (yet)
          local menunotasks = self.gettext:GetEntry("MENUNOTASKS",self.locale)
          local joinmenu = MENU_GROUP_DELAYED:New(group,menunotasks,topmenu)
        end
        ---
        -- REFRESH MENU
        ---
       if self.AllowFlash then
        local flashtext = self.gettext:GetEntry("FLASHMENU",self.locale)
        local flashmenu = MENU_GROUP_COMMAND_DELAYED:New(group,flashtext,self.PlayerMenu[playername],self._SwitchFlashing,self,group,client)
       end
       self.PlayerMenu[playername]:Set()
      end
    end
  end
  return self
end

--- [User] Add agent group to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Recce Group of agents. Can also be an @{Ops.OpsGroup#OPSGROUP} object.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddAgent(Recce)
  self:T(self.lid.."AddAgent")
  if self.Intel then
    self.Intel:AddAgent(Recce)
  else
    self:E(self.lid.."NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add accept zone to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE AcceptZone Add a zone to the accept zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddAcceptZone(AcceptZone)
  self:T(self.lid.."AddAcceptZone")
  if self.Intel then
    self.Intel:AddAcceptZone(AcceptZone)
  else
    self:E(self.lid.."NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add reject zone to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE RejectZone Add a zone to the reject zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddRejectZone(RejectZone)
  self:T(self.lid.."AddRejectZone")
  if self.Intel then
    self.Intel:AddRejectZone(RejectZone)
  else
    self:E(self.lid.."NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Remove accept zone from INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE AcceptZone Add a zone to the accept zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:RemoveAcceptZone(AcceptZone)
  self:T(self.lid.."RemoveAcceptZone")
  if self.Intel then
    self.Intel:RemoveAcceptZone(AcceptZone)
  else
    self:E(self.lid.."NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Remove reject zone from INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE RejectZone Add a zone to the reject zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:RemoveRejectZone(RejectZone)
  self:T(self.lid.."RemoveRejectZone")
  if self.Intel then
    self.Intel:RemoveRejectZone(RejectZone)
  else
    self:E(self.lid.."NO detection has been set up (yet)!")
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
  self:T(self.lid.."SetupIntel")
  self.RecceSet = SET_GROUP:New():FilterCoalitions(self.CoalitionName):FilterPrefixes(RecceName):FilterStart()
  self.Intel = INTEL:New(self.RecceSet,self.Coalition,self.Name.."-Intel")
  self.Intel:SetClusterAnalysis(true,false,false)
  self.Intel:SetClusterRadius(self.ClusterRadius or 0.5)
  self.Intel.statusupdate = 25
  self.Intel:SetAcceptZones()
  self.Intel:SetRejectZones()
  --if self.verbose then
    --self.Intel:SetDetectionTypes(true,true,false,true,true,true)
  --end
  if self.Type == PLAYERTASKCONTROLLER.Type.A2G or self.Type == PLAYERTASKCONTROLLER.Type.A2GS then
    self.Intel:SetDetectStatics(true)
  end
  self.Intel:__Start(2)
  
  local function NewCluster(Cluster)
    if not self.usecluster then return self end
    local cluster = Cluster -- Ops.Intelligence#INTEL.Cluster
    local type = cluster.ctype
    self:T({type,self.Type})
    if (type == INTEL.Ctype.AIRCRAFT and self.Type == PLAYERTASKCONTROLLER.Type.A2A) or (type == INTEL.Ctype.NAVAL and (self.Type == PLAYERTASKCONTROLLER.Type.A2S or self.Type == PLAYERTASKCONTROLLER.Type.A2GS)) then
      self:T("A2A or A2S")
      local contacts = cluster.Contacts -- #table of GROUP
      local targetset = SET_GROUP:New()
      for _,_object in pairs(contacts) do
        local contact = _object -- Ops.Intelligence#INTEL.Contact
        self:T("Adding group: "..contact.groupname)
        targetset:AddGroup(contact.group,true)
      end
      self:AddTarget(targetset)
    elseif (type == INTEL.Ctype.GROUND or type == INTEL.Ctype.STRUCTURE) and (self.Type == PLAYERTASKCONTROLLER.Type.A2G or self.Type == PLAYERTASKCONTROLLER.Type.A2GS) then
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
    if (type == INTEL.Ctype.AIRCRAFT and self.Type == PLAYERTASKCONTROLLER.Type.A2A) or (type == INTEL.Ctype.NAVAL and (self.Type == PLAYERTASKCONTROLLER.Type.A2S or self.Type == PLAYERTASKCONTROLLER.Type.A2GS)) then
      self:T("A2A or A2S")
      self:T("Adding group: "..contact.groupname)
      self:AddTarget(contact.group)
    elseif (type == INTEL.Ctype.GROUND or type == INTEL.Ctype.STRUCTURE) and (self.Type == PLAYERTASKCONTROLLER.Type.A2G or self.Type == PLAYERTASKCONTROLLER.Type.A2GS) then
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
-- @param #number Frequency Frequency to be used. Can also be given as a table of multiple frequencies, e.g. 271 or {127,251}. There needs to be exactly the same number of modulations!
-- @param #number Modulation Modulation to be used. Can also be given as a table of multiple modulations, e.g. radio.modulation.AM or {radio.modulation.FM,radio.modulation.AM}. There needs to be exactly the same number of frequencies!
-- @param #string PathToSRS Defaults to "C:\\Program Files\\DCS-SimpleRadio-Standalone"
-- @param #string Gender (Optional) Defaults to "male"
-- @param #string Culture (Optional) Defaults to "en-US"
-- @param #number Port (Optional) Defaults to 5002
-- @param #string Voice (Optional) Use a specifc voice with the @{Sound.SRS.SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system. Can also be Google voice types, if you are using Google TTS.
-- @param #number Volume (Optional) Volume - between 0.0 (silent) and 1.0 (loudest)
-- @param #string PathToGoogleKey (Optional) Path to your google key if you want to use google TTS
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetSRS(Frequency,Modulation,PathToSRS,Gender,Culture,Port,Voice,Volume,PathToGoogleKey)
  self:T(self.lid.."SetSRS")
  self.PathToSRS = PathToSRS or "C:\\Program Files\\DCS-SimpleRadio-Standalone" --
  self.Gender = Gender or "male" --
  self.Culture = Culture or "en-US" --
  self.Port = Port or 5002 --
  self.Voice = Voice --
  self.PathToGoogleKey = PathToGoogleKey --
  self.Volume = Volume or 1.0 --
  self.UseSRS = true
  self.Frequency = Frequency or {127,251} --
  self.BCFrequency = self.Frequency
  self.Modulation = Modulation or {radio.modulation.FM,radio.modulation.AM} --
  self.BCModulation = self.Modulation
  -- set up SRS 
  self.SRS=MSRS:New(self.PathToSRS,self.Frequency,self.Modulation,self.Volume)
  self.SRS:SetCoalition(self.Coalition)
  self.SRS:SetLabel(self.MenuName or self.Name)
  self.SRS:SetGender(self.Gender)
  self.SRS:SetCulture(self.Culture)
  self.SRS:SetPort(self.Port)
  self.SRS:SetVoice(self.Voice)
  if self.PathToGoogleKey then
    self.SRS:SetGoogle(self.PathToGoogleKey)
  end
  self.SRSQueue = MSRSQUEUE:New(self.MenuName or self.Name)
  self.SRSQueue:SetTransmitOnlyWithPlayers(self.TransmitOnlyWithPlayers)
  return self
end

--- [User] Set SRS Broadcast - for the announcement to joining players which SRS frequency, modulation to use. Use in case you want to set this differently to the standard SRS.
-- @param #PLAYERTASKCONTROLLER self
-- @param #number Frequency Frequency to be used. Can also be given as a table of multiple frequencies, e.g. 271 or {127,251}.  There needs to be exactly the same number of modulations!
-- @param #number Modulation Modulation to be used. Can also be given as a table of multiple modulations, e.g. radio.modulation.AM or {radio.modulation.FM,radio.modulation.AM}.  There needs to be exactly the same number of frequencies!
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
  self:T({From, Event, To})
  
  self:_CheckTargetQueue()
  self:_CheckTaskQueue()
  self:_CheckPrecisionTasks()
  if self.AllowFlash then
    self:_FlashInfo()
  end
  
  local targetcount = self.TargetQueue:Count()
  local taskcount = self.TaskQueue:Count()
  local playercount = self.ClientSet:CountAlive()
  local assignedtasks = self.TasksPerPlayer:Count()
  local enforcedmenu = false
  
  if taskcount ~= self.lasttaskcount then
    self.lasttaskcount = taskcount
    enforcedmenu = true
  end
  
  self:_BuildMenus(nil,enforcedmenu)
  
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
  local canceltxt = self.gettext:GetEntry("TASKCANCELLED",self.locale)
  local canceltxttts = self.gettext:GetEntry("TASKCANCELLEDTTS",self.locale)
  local taskname = string.format(canceltxt, Task.PlayerTaskNr, tostring(Task.Type))
  if not self.NoScreenOutput then
    self:_SendMessageToClients(taskname,15)
    --local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
  end
  if self.UseSRS then
    taskname = string.format(canceltxttts, self.MenuName or self.Name, Task.PlayerTaskNr, tostring(Task.TTSType))
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
  local succtxt = self.gettext:GetEntry("TASKSUCCESS",self.locale)
  local succtxttts = self.gettext:GetEntry("TASKSUCCESSTTS",self.locale)
  local taskname = string.format(succtxt, Task.PlayerTaskNr, tostring(Task.Type))
  if not self.NoScreenOutput then
    self:_SendMessageToClients(taskname,15)
    --local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
  end
  if self.UseSRS then
    taskname = string.format(succtxttts, self.MenuName or self.Name, Task.PlayerTaskNr, tostring(Task.TTSType))
    self.SRSQueue:NewTransmission(taskname,nil,self.SRS,nil,2)
  end
  local clients=Task:GetClientObjects()
  for _,client in pairs(clients) do
    self:_BuildMenus(client,true,true)
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
  local failtxt = self.gettext:GetEntry("TASKFAILED",self.locale)
  local failtxttts = self.gettext:GetEntry("TASKFAILEDTTS",self.locale)
  local taskname = string.format(failtxt, Task.PlayerTaskNr, tostring(Task.Type))
  if not self.NoScreenOutput then
    self:_SendMessageToClients(taskname,15)
    --local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
  end
  if self.UseSRS then
    taskname = string.format(failtxttts, self.MenuName or self.Name, Task.PlayerTaskNr, tostring(Task.TTSType))
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
  local repfailtxt = self.gettext:GetEntry("TASKFAILEDREPLAN",self.locale)
  local repfailtxttts = self.gettext:GetEntry("TASKFAILEDREPLANTTS",self.locale)
  local taskname = string.format(repfailtxt, Task.PlayerTaskNr, tostring(Task.Type))
  if not self.NoScreenOutput then
    self:_SendMessageToClients(taskname,15)
    --local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
  end
  if self.UseSRS then
    taskname = string.format(repfailtxttts, self.MenuName or self.Name, Task.PlayerTaskNr, tostring(Task.TTSType))
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
  local addtxt = self.gettext:GetEntry("TASKADDED",self.locale)
  local taskname = string.format(addtxt, self.MenuName or self.Name, tostring(Task.Type))
  if not self.NoScreenOutput then
    self:_SendMessageToClients(taskname,15)
    --local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
  end
  if self.UseSRS then
    taskname = string.format(addtxt, self.MenuName or self.Name, tostring(Task.TTSType))
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
  self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
  return self
end
-------
-- END PLAYERTASKCONTROLLER
----- 
end
