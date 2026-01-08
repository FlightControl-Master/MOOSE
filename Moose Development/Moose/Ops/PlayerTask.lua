--- **Ops** - PlayerTask (mission) for Players.
--
-- ## Main Features:
--
--    * Simplifies defining and executing Player tasks
--    * FSM events when a mission is added, done, successful or failed, replanned
--    * Ready to use SRS and localization
--    * Mission locations can be smoked, flared, illuminated and marked on the map
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [GitHub](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/PlayerTask).
--
-- ===
--
-- ### Author: **Applevangelist**
-- ### Special thanks to: Streakeagle
--
-- ===
-- @module Ops.PlayerTask
-- @image OPS_PlayerTask.jpg
-- @date Last Update Dec 2025


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
-- @field #table conditionSuccess
-- @field #table conditionFailure
-- @field Ops.PlayerTask#PLAYERTASKCONTROLLER TaskController
-- @field #number timestamp
-- @field #number lastsmoketime
-- @field #number coalition
-- @field #string Freetext
-- @field #string FreetextTTS
-- @field #string TaskSubType
-- @field #table NextTaskSuccess
-- @field #table NextTaskFailure
-- @field #string FinalState
-- @field #string TypeName
-- @field #number PreviousCount
-- @field #boolean CanSmoke
-- @field #boolean ShowThreatDetails
-- @field #boolean PersistMe 
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
  Freetext           =   nil,
  FreetextTTS        =   nil,
  TaskSubType        =   nil,
  NextTaskSuccess    =   {},
  NextTaskFailure    =   {},
  FinalState         =   "none",
  PreviousCount      =   0,
  CanSmoke           =   true,
  ShowThreatDetails  =   true,
  PersistMe          =   false,
  }

--- PLAYERTASK class version.
-- @field #string version
PLAYERTASK.version="0.1.31"

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
-- @param #string TTSType TTS friendly task type name
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

  if type(Repeat) == "boolean" and Repeat == true and type(Times) == "number" and Times > 1 then
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

  self.PreviousCount = self.Target:CountTargets()

  self:T(self.lid.."Created.")

  -- FMS start state is PLANNED.
  self:SetStartState("Planned")

  -- PLANNED --> REQUESTED --> EXECUTING --> DONE
  self:AddTransition("*",            "Planned",          "Planned")   -- Task is in planning stage.
  self:AddTransition("*",            "Requested",        "Requested")   -- Task clients have been requested to join.
  self:AddTransition("*",            "ClientAdded",      "*")  -- Client has been added to the task
  self:AddTransition("*",            "ClientRemoved",    "*")  -- Client has been removed from the task
  self:AddTransition("*",            "Executing",        "Executing")   -- First client is executing the Task.
  self:AddTransition("*",            "Progress",         "*")   -- Task target count reduced - progress
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
  -- @param #boolean Silent If true, suppress message output on cancel.

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

--- Constructor that automatically determines the task type based on the target.
-- @param #PLAYERTASK self
-- @param Ops.Target#TARGET Target Target for this task
-- @param #boolean Repeat Repeat this task if true (default = false)
-- @param #number Times Repeat on failure this many times if Repeat is true (default = 1)
-- @param #string TTSType TTS friendly task type name
-- @return #PLAYERTASK self
function PLAYERTASK:NewFromTarget(Target, Repeat, Times, TTSType)
    return PLAYERTASK:New(self:_GetTaskTypeForTarget(Target), Target, Repeat, Times, TTSType)
end

--- [Internal] Determines AUFTRAG type based on the target characteristics.
-- @param #PLAYERTASK self
-- @param Ops.Target#TARGET Target Target for this task
-- @return #string AUFTRAG.Type 
function PLAYERTASK:_GetTaskTypeForTarget(Target)

    local group = nil      --Wrapper.Group#GROUP
    local auftrag = nil

    if Target:IsInstanceOf("GROUP") then
        group = Target --Target is already a group.
    elseif Target:IsInstanceOf("SET_GROUP") then
        group = Target:GetFirst()
    elseif Target:IsInstanceOf("UNIT") then
        group = Target:GetGroup()
    elseif Target:IsInstanceOf("SET_UNIT") then
        group = Target:GetFirst():GetGroup()
    elseif Target:IsInstanceOf("AIRBASE") then

        auftrag = AUFTRAG.Type.BOMBRUNWAY

    elseif Target:IsInstanceOf("STATIC")
            or Target:IsInstanceOf("SET_STATIC")
            or Target:IsInstanceOf("SCENERY")
            or Target:IsInstanceOf("SET_SCENERY") then

        auftrag = AUFTRAG.Type.BOMBING

    elseif Target:IsInstanceOf("OPSZONE")
            or Target:IsInstanceOf("SET_OPSZONE") then
        auftrag = AUFTRAG.Type.CAPTUREZONE
    end

    if group then

        local category = group:GetCategory()
        local attribute = group:GetAttribute()

        if (category == Group.Category.AIRPLANE or category == Group.Category.HELICOPTER)
                and group:InAir() then

            auftrag = AUFTRAG.Type.INTERCEPT

        elseif category == Group.Category.GROUND or category == Group.Category.TRAIN then

            if attribute == GROUP.Attribute.GROUND_SAM
                    or attribute == GROUP.Attribute.GROUND_EWR then

                auftrag = AUFTRAG.Type.SEAD

            elseif attribute == GROUP.Attribute.GROUND_AAA
                    or attribute == GROUP.Attribute.GROUND_APC
                    or attribute == GROUP.Attribute.GROUND_IFV
                    or attribute == GROUP.Attribute.GROUND_TRUCK
                    or attribute == GROUP.Attribute.GROUND_TRAIN then

                auftrag = AUFTRAG.Type.BAI

            elseif attribute == GROUP.Attribute.GROUND_INFANTRY
                    or attribute == GROUP.Attribute.GROUND_ARTILLERY
                    or attribute == GROUP.Attribute.GROUND_TANK then

                auftrag = AUFTRAG.Type.CAS

            else

                auftrag = AUFTRAG.Type.BAI

            end

        elseif category == Group.Category.SHIP then

            auftrag = AUFTRAG.Type.ANTISHIP

        else
            self:T(self.lid .. "ERROR: Unknown Group category!")
        end
    end

    return auftrag

end


--- [Internal] Check OpsZone capture success condition.
-- @param #PLAYERTASK self
-- @param Ops.OpsZone#OPSZONE OpsZone The OpsZone target object.
-- @param #string CaptureSquadGroupNamePrefix The prefix of the group name that needs to capture the zone.
-- @param #number Coalition The coalition that needs to capture the zone.
-- @param #boolean CheckClientInZone Check if any of the clients are in zone.
-- @return #PLAYERTASK self
function PLAYERTASK:_CheckCaptureOpsZoneSuccess(OpsZone, CaptureSquadGroupNamePrefix, Coalition, CheckClientInZone)
    local isClientInZone = true
    if CheckClientInZone then
        isClientInZone = false
        for _, client in ipairs(self:GetClientObjects()) do
            local clientCoord = client:GetCoordinate()
            if OpsZone.zone:IsCoordinateInZone(clientCoord) then
                isClientInZone = true
                break
            end
        end
    end

    local isCaptureGroupInZone = false
    OpsZone:GetScannedGroupSet():ForEachGroup(function(group)
        if string.find(group:GetName(), CaptureSquadGroupNamePrefix) then
            isCaptureGroupInZone = true
        end
    end)

    return OpsZone:GetOwner() == Coalition and isClientInZone and isCaptureGroupInZone
end

--- [User] Override this function in order to implement custom logic if a player can join a task or not.
-- @param #PLAYERTASK self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #boolean Outcome True if player can join the task, false if not
function PLAYERTASK:CanJoinTask(Group, Client)
    return true
end

--- [User] Set this task for persistance, if persistance is enabled on the PLAYERTASKCONTROLLER instance.
-- @param #PLAYERTASK self
-- @return #PLAYERTASK self 
function PLAYERTASK:EnablePersistance()
  self.PersistMe = true
  return self
end

--- [Internal] Add a PLAYERTASKCONTROLLER for this task
-- @param #PLAYERTASK self
-- 
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

--- [User] Get the Ops.Target#TARGET object for this task
-- @param #PLAYERTASK self
-- @return Ops.Target#TARGET Target
function PLAYERTASK:GetTarget()
  self:T(self.lid.."GetTarget")
  return self.Target
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

--- [USER] Query if a task has free text description.
-- @param #PLAYERTASK self
-- @return #PLAYERTASK self
function PLAYERTASK:HasFreetext()
  self:T(self.lid.."HasFreetext")
  return self.Freetext ~= nil and true or false
end

--- [USER] Query if a task has free text TTS description.
-- @param #PLAYERTASK self
-- @return #PLAYERTASK self
function PLAYERTASK:HasFreetextTTS()
  self:T(self.lid.."HasFreetextTTS")
  return self.FreetextTTS ~= nil and true or false
end

--- [USER] Set a task sub type description to this task.
-- @param #PLAYERTASK self
-- @param #string Type
-- @return #PLAYERTASK self
function PLAYERTASK:SetSubType(Type)
  self:T(self.lid.."AddSubType")
  self.TaskSubType = Type
  return self
end

--- [USER] Set if a task can have a smoke marker.
-- @param #PLAYERTASK self
-- @param #boolean OnOff If true (default) it can be smoke, false if not.
-- @return #PLAYERTASK self
function PLAYERTASK:SetCanSmoke(OnOff)
  self:T(self.lid.."AddSSetCanSmokeubType")
  self.CanSmoke = OnOff
  return self
end

--- [USER] Set if a task can show threat details.
-- @param #PLAYERTASK self
-- @param #boolean OnOff If true (default) it can be shown, false if not.
-- @return #PLAYERTASK self
function PLAYERTASK:SetShowThreatDetails(OnOff)
  self:T(self.lid.."SetShowThreatDetails")
  self.ShowThreatDetails = OnOff
  return self
end

--- [USER] Get task sub type description from this task.
-- @param #PLAYERTASK self
-- @return #string Type or nil
function PLAYERTASK:GetSubType()
  self:T(self.lid.."GetSubType")
  return self.TaskSubType
end

--- [USER] Get the free text description from this task.
-- @param #PLAYERTASK self
-- @return #string Text
function PLAYERTASK:GetFreetext()
  self:T(self.lid.."GetFreetext")
  return self.Freetext  or self.FreetextTTS or "No Details"
end

--- [USER] Add a free text description for TTS to this task.
-- @param #PLAYERTASK self
-- @param #string TextTTS
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
  return self.FreetextTTS  or self.Freetext or "No Details"
end

--- [USER] Add a short free text description for the menu entry of this task.
-- @param #PLAYERTASK self
-- @param #string Text
-- @return #PLAYERTASK self
function PLAYERTASK:SetMenuName(Text)
  self:T(self.lid.."SetMenuName")
  self.Target.name = Text
  return self
end

--- [USER] Adds task success condition for dead STATIC, SET_STATIC, SCENERY or SET_SCENERY target object.
-- @return #PLAYERTASK self
-- @usage
-- -- We can use either STATIC, SET_STATIC, SCENERY or SET_SCENERY as target objects.
-- local mytask = PLAYERTASK:NewFromTarget(static, true, 50, "Destroy the target")
-- mytask:SetMenuName("Destroy Power Plant")
-- mytask:AddFreetext("Locate and destroy the power plant near Olenya.")
-- mytask:AddStaticObjectSuccessCondition()
--
-- playerTaskManager:AddPlayerTaskToQueue(mytask)
function PLAYERTASK:AddStaticObjectSuccessCondition()
    local task = self
    -- TODO Check if the killer is one of the task clients
    task:AddConditionSuccess(
            function(target)
                if target == nil then return false end

                local isDead = false
                if target:IsInstanceOf("STATIC")
                or target:IsInstanceOf("SCENERY")
                or target:IsInstanceOf("SET_SCENERY") then
                    isDead = (not target) or target:GetLife() < 1 or target:GetLife() < 0.2* target:GetLife0()
                elseif target:IsInstanceOf("SET_STATIC") then
                    local deadCount = 0
                    target:ForEachStatic(function(static)
                        if static:GetLife() < 1 or static:GetLife() < 0.2* static:GetLife0() then
                            deadCount = deadCount + 1
                        end
                    end)

                    if deadCount == target:Count() then
                        isDead = true
                    end
                end

                return isDead
            end, task:GetTarget()
    )

    -- TODO Check if the killer is one of the task clients
    --task:AddConditionFailure(
    --        function()
    --
    --        end)
    return self
end

--- [USER] Adds task success condition for AUFTRAG.Type.CAPTUREZONE for OpsZone or OpsZone set target object.
--- At least one of the task clients and one capture group need to be inside the zone in order for the capture to be successful.
-- @param #PLAYERTASK self
-- @param #SET_BASE CaptureSquadGroupNamePrefix The prefix of the group name that needs to capture the zone.
-- @param #number Coalition The coalition that needs to capture the zone.
-- @param #boolean CheckClientInZone If true, a CLIENT assigned to this task also needs to be in the zone for the task to be successful.
-- @return #PLAYERTASK self
-- @usage
-- -- We can use either STATIC, SET_STATIC, SCENERY or SET_SCENERY as target objects.
-- local opsZone = OPSZONE:New(zone, coalition.side.RED)
--
-- ...
--
-- -- We can use either OPSZONE or SET_OPSZONE.
-- local mytask = PLAYERTASK:NewFromTarget(opsZone, true, 50, "Capture the zone")
-- mytask:SetMenuName("Capture the ops zone")
-- mytask:AddFreetext("Transport capture squad to the ops zone.")
--
-- -- We set CaptureSquadGroupNamePrefix the group name prefix as set in the ME or the spawn of the group that need to be present at the OpsZone like a capture squad,
-- -- and set the capturing Coalition in order to trigger a successful task.
-- mytask:AddOpsZoneCaptureSuccessCondition("capture-squad", coalition.side.BLUE, false)
--
-- playerTaskManager:AddPlayerTaskToQueue(mytask)
function PLAYERTASK:AddOpsZoneCaptureSuccessCondition(CaptureSquadGroupNamePrefix, Coalition, CheckClientInZone)
    local task = self
    task:AddConditionSuccess(
            function(target)
                if target:IsInstanceOf("OPSZONE") then
                    return task:_CheckCaptureOpsZoneSuccess(target, CaptureSquadGroupNamePrefix, Coalition, CheckClientInZone or true)
                elseif target:IsInstanceOf("SET_OPSZONE") then
                    local successes = 0
                    local isClientInZone = false
                    target:ForEachZone(function(opszone)
                        if task:_CheckCaptureOpsZoneSuccess(opszone, CaptureSquadGroupNamePrefix, Coalition, CheckClientInZone or true) then
                            successes = successes + 1
                        end

                        for _, client in ipairs(task:GetClientObjects()) do
                            local clientCoord = client:GetCoordinate()
                            if opszone.zone:IsCoordinateInZone(clientCoord) then
                                isClientInZone = true
                                break
                            end
                        end
                    end)
                    return successes == target:Count() and isClientInZone
                end

                return false
            end, task:GetTarget()
    )
    return self
end

--- [USER] Adds task success condition for AUFTRAG.Type.RECON when a client is at a certain LOS distance from the target.
-- @param #PLAYERTASK self
-- @param #number MinDistance (Optional) Minimum distance in meters from client to target in LOS for success condition. (Default 5 NM)
-- @return #PLAYERTASK self
-- @usage
-- -- target can be any object that has a `GetCoordinate()` function like STATIC, GROUP, ZONE...
-- local mytask = PLAYERTASK:New(AUFTRAG.Type.RECON, ZONE:New("WF Zone"), true, 50, "Deep Earth")
-- mytask:SetMenuName("Recon weapon factory")
-- mytask:AddFreetext("Locate and investigate underground weapons factory near Kovdor.")
--
-- -- We set the MinDistance (optional) in meters for the client to be in LOS from the target in order to trigger a successful task.
-- mytask:AddReconSuccessCondition(10000) -- 10 km (default is 5 NM if not set)
--
-- playerTaskManager:AddPlayerTaskToQueue(mytask)
function PLAYERTASK:AddReconSuccessCondition(MinDistance)
    local task = self
    task:AddConditionSuccess(
            function(target)
                local targetLocation = target:GetCoordinate()
                local minD = MinDistance or UTILS.NMToMeters(5)
                for _, client in ipairs(task:GetClientObjects()) do
                    local clientCoord = client:GetCoordinate()
                    local distance = clientCoord:Get2DDistance(targetLocation)
                    local isLos = land.isVisible(clientCoord:GetVec3(), targetLocation:GetVec3())

                    if distance < minD and isLos then
                        return true
                    end
                end
                return false
            end, task:GetTarget())

    return self
end

--- [USER] Adds a time limit for the task to be completed.
-- @param #PLAYERTASK self
-- @param #number TimeLimit Time limit in seconds for the task to be completed. (Default 0 = no time limit)
-- @return #PLAYERTASK self
-- @usage
-- local mytask = PLAYERTASK:New(AUFTRAG.Type.RECON, ZONE:New("WF Zone"), true, 50, "Deep Earth")
-- mytask:SetMenuName("Recon weapon factory")
-- mytask:AddFreetext("Locate and investigate underground weapons factory near Kovdor.")
-- mytask:AddReconSuccessCondition(10000) -- 10 km
--
-- -- We set the TimeLimit to 10 minutes (600 seconds) from the moment the task is started, once the time has passed and the task is not yet successful it will trigger a failure.
-- mytask:AddTimeLimitFailureCondition(600)
--
-- playerTaskManager:AddPlayerTaskToQueue(mytask)
function PLAYERTASK:AddTimeLimitFailureCondition(TimeLimit)
    local task = self
    TimeLimit = TimeLimit or 0
    task.StartTime = -1
    task:AddConditionFailure(
            function()
                if task.StartTime == -1 then
                    task.StartTime = timer.getTime()
                end
                return TimeLimit > 0 and timer.getTime() - task.StartTime > TimeLimit
            end)
    return self
end

--- [USER] Add a task to be assigned to same clients when task was a success.
-- @param #PLAYERTASK self
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @return #PLAYERTASK self
function PLAYERTASK:AddNextTaskAfterSuccess(Task)
  self:T(self.lid.."AddNextTaskAfterSuccess")
  table.insert(self.NextTaskSuccess,Task)
  return self
end

--- [USER] Add a task to be assigned to same clients when task was a failure.
-- @param #PLAYERTASK self
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @return #PLAYERTASK self
function PLAYERTASK:AddNextTaskAfterFailure(Task)
  self:T(self.lid.."AddNextTaskAfterFailure")
  table.insert(self.NextTaskFailure,Task)
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

--- [User] Check if task is NOT done
-- @param #PLAYERTASK self
-- @return #boolean done
function PLAYERTASK:IsNotDone()
  self:T(self.lid.."IsNotDone?")
  local IsNotDone = not self:IsDone()
  return IsNotDone
end

--- [User] Check if PLAYERTASK has clients assigned to it.
-- @param #PLAYERTASK self
-- @return #boolean hasclients
function PLAYERTASK:HasClients()
  self:T(self.lid.."HasClients?")
  local hasclients = self:CountClients() > 0 and true or false
  return hasclients
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
  if self.TaskController and self.TaskController.Scoring then
    self.TaskController.Scoring:_AddPlayerFromUnit(Client)
  end
  return self
end

--- [User] Remove a client from this task
-- @param #PLAYERTASK self
-- @param Wrapper.Client#CLIENT Client
-- @param #string Name Name of the client
-- @return #PLAYERTASK self
function PLAYERTASK:RemoveClient(Client,Name)
  self:T(self.lid.."RemoveClient")
  local name = Name or Client:GetPlayerName()
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
      local text = Text or ("Target of "..self.lid)
      self.TargetMarker = MARKER:New(coordinate,text)
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
    local coordinate = self.Target:GetAverageCoordinate()
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
    local coordinate = self.Target:GetAverageCoordinate()
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
    local coordinate = self.Target:GetAverageCoordinate()
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
  
  if status == "Stopped" then return self end
  
  -- update marker in case target is moving
  if self.TargetMarker then
    local coordinate = self.Target:GetCoordinate() 
    self.TargetMarker:UpdateCoordinate(coordinate,0.5) 
  end
  
  -- Check Target status
  local targetdead = false
  
  if self.Type ~= AUFTRAG.Type.CTLD and self.Type ~= AUFTRAG.Type.CSAR then
    if self.Target:IsDead() or self.Target:IsDestroyed() or self.Target:CountTargets() == 0 then
      targetdead = true
      self:__Success(-2)
      status = "Success"
      return self
    end
  end
  
  local clientsalive = false  
    
  if status == "Executing" then    
    -- Check Clients alive
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
  end 
  
  -- Continue if we are not done
  if status ~= "Done" and status ~= "Stopped" then 
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
    
    if status ~= "Failed" and status ~= "Success" then
      -- Partial Success?
      local targetcount = self.Target:CountTargets()
      if targetcount < self.PreviousCount then
        -- Progress
        self:__Progress(-2,targetcount)
        self.PreviousCount = targetcount
      end
    end
    
    if self.verbose then
      self:I(self.lid.."Target dead: "..tostring(targetdead).." | Clients alive: " .. tostring(clientsalive))
    end
  
    self:__Status(-20)
  elseif status ~= "Stopped" then
    self:__Stop(-1)
  end
  
  return self
end

--- [Internal] On after progress call
-- @param #PLAYERTASK self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number TargetCount
-- @return #PLAYERTASK self
function PLAYERTASK:onafterProgress(From, Event, To, TargetCount)
  self:T({From, Event, To})
  if self.TaskController then
    if self.TaskController.Scoring then
      local clients,count = self:GetClientObjects()
      if count > 0 then
        for _,_client in pairs(clients) do
          self.TaskController.Scoring:AddGoalScore(_client,self.Type,nil,10) 
        end
      end
    end
    self.TaskController:__TaskProgress(-1,self,TargetCount) 
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
    self:T(self.lid..text)
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
-- @param #boolean Silent
-- @return #PLAYERTASK self
function PLAYERTASK:onafterCancel(From, Event, To, Silent)
  self:T({From, Event, To})
  if self.TaskController then
    self.TaskController:__TaskCancelled(-1,self, Silent)
  end
  self.timestamp = timer.getAbsTime()
  self.FinalState = "Cancelled"
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
  if self.TaskController and self.TaskController.Scoring then
    local clients,count = self:GetClientObjects()
    if count > 0 then
      for _,_client in pairs(clients) do
        local auftrag = self:GetSubType()
        self.TaskController.Scoring:AddGoalScore(_client,self.Type,nil,self.TaskController.Scores[self.Type]) 
      end
    end
  end 
  self.timestamp = timer.getAbsTime()
  self.FinalState = "Success"
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
    self.FinalState = "Failed"
    if self.TaskController then
      self.TaskController:__TaskFailed(-1,self)
    end
    self:__Done(-1.5)
  end
  if self.TaskController.Scoring then
    local clients,count = self:GetClientObjects()
    if count > 0 then
      for _,_client in pairs(clients) do
        local auftrag = self:GetSubType()
        self.TaskController.Scoring:AddGoalScore(_client,self.Type,nil,-self.TaskController.Scores[self.Type]) 
      end
    end
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
-- DONE Integrated basic CTLD tasks
-- DONE Integrate basic CSAR tasks
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
-- @field Core.Set#SET_CLIENT ActiveClientSet
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
-- @field Core.MarkerOps_Base#MARKEROPS_BASE MarkerOps
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
-- @field #boolean illumenu
-- @field #boolean TransmitOnlyWithPlayers
-- @field #boolean buddylasing
-- @field Ops.PlayerRecce#PLAYERRECCE PlayerRecce
-- @field #number Coalition
-- @field Core.Menu#MENU_MISSION MenuParent
-- @field #boolean ShowMagnetic Also show magnetic angles
-- @field #boolean InfoHasCoordinate
-- @field #boolean InfoHasLLDDM
-- @field #table PlayerMenuTag
-- @field #boolean UseTypeNames
-- @field Functional.Scoring#SCORING Scoring
-- @field Core.ClientMenu#CLIENTMENUMANAGER JoinTaskMenuTemplate
-- @field Core.ClientMenu#CLIENTMENU JoinMenu
-- @field Core.ClientMenu#CLIENTMENU JoinTopMenu
-- @field Core.ClientMenu#CLIENTMENU JoinInfoMenu
-- @field Core.ClientMenu#CLIENTMENUMANAGER ActiveTaskMenuTemplate
-- @field Core.ClientMenu#CLIENTMENU ActiveTopMenu
-- @field Core.ClientMenu#CLIENTMENU ActiveInfoMenu
-- @field Core.ClientMenu#CLIENTMENU MenuNoTask
-- @field #boolean InformationMenu Show Radio Info Menu
-- @field #number TaskInfoDuration How long to show the briefing info on the screen
-- @field #table TaskPersistance Table for persistance data
-- @field #boolean TaskPersistanceSwitch Switch for persisting tasks
-- @field #string TaskPersistancePath File path for persisting tasks
-- @field #string TaskPersistanceFilename File name for persisting tasks
-- @field #table TasksPersistable List of persistable tasks
-- @field #number SceneryExplosivesAmount Kgs of TNT to explode scenery on task persistance loading
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
-- For the latter task type, also have a look at the @{Ops.AWACS#AWACS} class which allows for more complex scenarios.
-- One task at a time can be joined by the player from the F10 menu. A task can be joined by multiple players. Once joined, task information is available via the F10 menu, the task location
-- can be marked on the map and for A2G/S targets, the target can be marked with smoke and flares.
-- 
-- For the mission designer, tasks can be auto-created by means of detection with the integrated @{Ops.Intel#INTEL} class setup, or be manually added to the task queue.
-- 
-- ## 2 Task Types
-- 
-- Targets can be of types GROUP, SET\_GROUP, UNIT, SET\_UNIT, STATIC, SET\_STATIC, SET\_SCENERY, AIRBASE, ZONE or COORDINATE. The system will auto-create tasks for players from these targets.
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
--  * CTLD - Combat transport and logistics deployment
--  * CSAR - Combat search and rescue
--  * RECON - Identify targets
--  * CAPTUREZONE - Capture an Ops.OpsZone#OPSZONE
--  * Any #string name can be passed as Auftrag type, but then you need to make sure to define a success condition, and possibly also add the task type to the standard scoring list: `PLAYERTASKCONTROLLER.Scores["yournamehere"]=100`
--  
-- ## 3 Task repetition
--  
-- On failure, tasks will be replanned by default for a maximum of 5 times.
-- 
-- ## 3.1 Pre-configured success conditions
-- 
-- Pre-configured success conditions for #PLAYERTASK tasks are available as follows:
-- 
-- `mytask:AddStaticObjectSuccessCondition()` -- success if static object is at least 80% dead
-- 
-- `mytask:AddOpsZoneCaptureSuccessCondition(CaptureSquadGroupNamePrefix,Coalition)`  -- success if a squad of the given (partial) name and coalition captures the OpsZone
-- 
-- `mytask:AddReconSuccessCondition(MinDistance)`  -- success if object is in line-of-sight with the given min distance in NM
-- 
-- `mytask:AddTimeLimitSuccessCondition(TimeLimit)` -- failure if the task is not completed within the time limit in seconds given
-- 
-- ## 3.2 Task chaining
-- 
-- You can create chains of tasks, which will depend on success or failure of the previous task with the following commands:
-- 
-- `mytask:AddNextTaskAfterSuccess(FollowUpTask)` and  
-- 
-- `mytask:AddNextTaskAfterFailure(FollowUpTask)`
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
--            local hereSRSPath = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio"
--            local hereSRSPort = 5002
--            -- local hereSRSGoogle = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio\\yourkey.json"
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
--                MENUILLU = "Illuminate",
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
--                BRIEFING = "Briefing",
--                TARGETLOCATION ="Target location",
--                COORDINATE = "Coordinate",
--                INFANTRY = "Infantry",
--                TECHNICAL = "Technical",
--                ARTILLERY = "Artillery",
--                TANKS = "Tanks",
--                AIRDEFENSE = "Airdefense",
--                SAM = "SAM",
--                GROUP = "Group",
--                ELEVATION = "\nTarget Elevation: %s %s",
--                METER = "meter",
--                FEET = "feet",
--                INTERCEPTCOURSE = "Intercept course",
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
--              function taskmanager:OnAfterTaskCancelled(From, Event, To, Task, Silent)
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
-- ## 9 Single Task Persistence for mission designer added tasks
-- 
-- The class can persist the state of single tasks of type BOMBING, PRECISIONBOMBING, ARTY and SEAD, i.e. tasks which have a GROUND(!) GROUP, UNIT, STATIC or SCENERY as target.
-- This requires the task to have a unique(!) menu name set, a TARGET which already exists on the map at mission start(!), and a flag that this task is actually to be persisted.
-- Also, you need to desanitize the mission scripting environment, i.e. "lfs" and "io" must be available so we can write to disk.
-- 
--            -- First, we need to enable on the PLAYERTASKCONTROLLER itself
--            taskmanager:EnableTaskPersistance([[C:\Users\myname\Saved Games\DCS\Missions\MyMisionFolder\]],"Mission Tasks.csv") -- Path and Filename
--            
--            -- Then, we can design a task marking mission progress that we want to persist
--            local RussianRadios = SET_STATIC:New():FilterPrefixes("Comms Tower Russia"):FilterOnce()
--            
--            local RadioTask = PLAYERTASK:New(AUFTRAG.Type.BOMBING,RussianRadios,true,5,"Bombing")
--            RadioTask:SetMenuName("Neutralize Comms Towers") -- UNIQUE menu name so we can find the task later!
--            RadioTask:AddFreetext("Find and neutralize the two communication towers near NB70 East of Fulda on Streufelsberg!")
--            RadioTask:AddFreetextTTS("Find and neutralize the two communication towers naer N;B;7;zero; East of Fulda on Streufelsberg!")
--            RadioTask:EnablePersistance() -- Enable persistence for this task
--            
--            taskmanager:AddPlayerTaskToQueue(RadioTask,true,false)
--                       
-- ## 10 Discussion
--
-- If you have questions or suggestions, please visit the [MOOSE Discord](https://discord.gg/AeYAkHP) #ops-playertask channel.  
-- 
--                          
-- @field #PLAYERTASKCONTROLLER
PLAYERTASKCONTROLLER = {
  ClassName          = "PLAYERTASKCONTROLLER",
  verbose            =   false,
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
  PlayerMenuTag      =   {},
  noflaresmokemenu   =   false,
  illumenu           =   false,
  TransmitOnlyWithPlayers = true,
  buddylasing        = false,
  PlayerRecce        = nil,
  Coalition          = nil,
  MenuParent         = nil,
  ShowMagnetic       = true,
  InfoHasLLDDM       = false,
  InfoHasCoordinate  = false,
  UseTypeNames       = false,
  Scoring            = nil,
  MenuNoTask         = nil,
  InformationMenu    = false,
  TaskInfoDuration   = 30,
  TaskPersistance    = {},
  TaskPersistanceSwitch = false,
  TaskPersistancePath = nil,
  TaskPersistanceFilename = nil,
  TasksPersistable = {},
  SceneryExplosivesAmount = 300,
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
AUFTRAG.Type.CSAR = "Combat Rescue"
AUFTRAG.Type.CONQUER = "Conquer"

---
-- @type Scores
PLAYERTASKCONTROLLER.Scores = {
  [AUFTRAG.Type.PRECISIONBOMBING] = 100,
  [AUFTRAG.Type.CTLD] = 100,
  [AUFTRAG.Type.CSAR] = 100,
  [AUFTRAG.Type.INTERCEPT] = 100,
  [AUFTRAG.Type.ANTISHIP] = 100,
  [AUFTRAG.Type.CAS] = 100,
  [AUFTRAG.Type.BAI] = 100,
  [AUFTRAG.Type.SEAD] = 100,
  [AUFTRAG.Type.BOMBING] = 100,
  [AUFTRAG.Type.BOMBRUNWAY] = 100,
  [AUFTRAG.Type.CONQUER] = 100,
  [AUFTRAG.Type.RECON] = 100,
  [AUFTRAG.Type.ESCORT] = 100,
  [AUFTRAG.Type.CAP] = 100,
  [AUFTRAG.Type.CAPTUREZONE] = 100,
}

---
-- @type TasksPersistable
PLAYERTASKCONTROLLER.TasksPersistable = {
  [AUFTRAG.Type.PRECISIONBOMBING] = true,
  [AUFTRAG.Type.BOMBING] = true,
  [AUFTRAG.Type.ARTY] = true,
  [AUFTRAG.Type.SEAD] = true,
}

---
-- @type PersistenceData
-- @field #number ID
-- @field #string Name
-- @field #string Type
-- @field #number InitialTargets
-- @field #number Targetsleft
-- @field #boolean updated
 
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
    NOTHREATTEXT = "%s\nNo target information available.",
    ELEVATION = "\nTarget Elevation: %s %s",
    METER = "meter",
    FEET = "feet",
    THREATTEXTTTS = "%s, %s. Target information for %s. Threat level %s. Targets left %d. Target location %s.",
    NOTHREATTEXTTTS = "%s, %s. No target information available.",
    MARKTASK = "%s, %s, copy, task %03d location marked on map!",
    SMOKETASK = "%s, %s, copy, task %03d location smoked!",
    NOSMOKETASK = "%s, %s, negative, task %03d location cannot be smoked!",
    FLARETASK = "%s, %s, copy, task %03d location illuminated!",
    ABORTTASK = "All stations, %s, %s has aborted %s task %03d!",
    UNKNOWN = "Unknown",
    MENUTASKING = " Tasking ",
    MENUACTIVE = "Active Task",
    MENUINFO = "Info",
    MENUMARK = "Mark on map",
    MENUSMOKE = "Smoke",
    MENUFLARE = "Flare",
    MENUILLU = "Illuminate",
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
    BRIEFING = "Briefing",
    TARGETLOCATION ="Target location",
    COORDINATE = "Coordinate",
    INFANTRY = "Infantry",
    TECHNICAL = "Technical",
    ARTILLERY = "Artillery",
    TANKS = "Tanks",
    AIRDEFENSE = "Airdefense",
    SAM = "SAM",
    GROUP = "Group",
    UNARMEDSHIP = "Merchant",
    LIGHTARMEDSHIP = "Light Boat",
    CORVETTE = "Corvette",
    FRIGATE = "Frigate",
    CRUISER = "Cruiser",
    DESTROYER = "Destroyer",
    CARRIER = "Aircraft Carrier",
    RADIOS = "Radios",
    INTERCEPTCOURSE = "Intercept course",
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
    NOTHREATTEXT = "%s\nKeine Zielinformation verfügbar.",
    ELEVATION = "\nZiel Höhe: %s %s",
    METER = "Meter",
    FEET = "Fuss",
    THREATTEXTTTS = "%s, %s. Zielinformation zu %s. Gefahrstufe %s. Ziele %d. Zielposition %s.",
    NOTHREATTEXTTTS = "%s, %s. Keine Zielinformation verfügbar.",
    MARKTASK = "%s, %s, verstanden, Zielposition %03d auf der Karte markiert!",
    SMOKETASK = "%s, %s, verstanden, Zielposition %03d mit Rauch markiert!",
    NOSMOKETASK = "%s, %s, negativ, Zielposition %03d kann nicht markiert werden!",
    FLARETASK = "%s, %s, verstanden, Zielposition %03d beleuchtet!",
    ABORTTASK = "%s, an alle, %s hat Auftrag %s %03d abgebrochen!",
    UNKNOWN = "Unbekannt",
    MENUTASKING = " Aufträge ",
    MENUACTIVE = "Aktiver Auftrag",
    MENUINFO = "Information",
    MENUMARK = "Kartenmarkierung",
    MENUSMOKE = "Rauchgranate",
    MENUFLARE = "Leuchtgranate",
    MENUILLU = "Feldbeleuchtung",
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
    BRIEFING = "Briefing",
    TARGETLOCATION ="Zielposition",
    COORDINATE = "Koordinate",
    INFANTRY = "Infantrie",
    TECHNICAL = "Technische",
    ARTILLERY = "Artillerie",
    TANKS = "Panzer",
    AIRDEFENSE = "Flak",
    SAM = "Luftabwehr",
    GROUP = "Einheit",
    UNARMEDSHIP = "Handelsschiff",
    LIGHTARMEDSHIP = "Tender",
    CORVETTE = "Korvette",
    FRIGATE = "Fregatte",
    CRUISER = "Kreuzer",
    DESTROYER = "Zerstörer",
    CARRIER = "Flugzeugträger",
    RADIOS = "Frequenzen",
    INTERCEPTCOURSE = "Abfangkurs",
  },
}
  
--- PLAYERTASK class version.
-- @field #string version
PLAYERTASKCONTROLLER.version="0.1.73"

--- Create and run a new TASKCONTROLLER instance.
-- @param #PLAYERTASKCONTROLLER self
-- @param #string Name Name of this controller
-- @param #number Coalition of this controller, e.g. coalition.side.BLUE
-- @param #string Type Type of the tasks controlled, defaults to PLAYERTASKCONTROLLER.Type.A2G
-- @param #string ClientFilter (optional) Additional prefix filter for the SET_CLIENT. Can be handed as @{Core.Set#SET_CLIENT} also.
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
  
  self.ClientFilter = ClientFilter --or ""
  
  self.TargetQueue = FIFO:New() -- Utilities.FiFo#FIFO
  self.TaskQueue = FIFO:New() -- Utilities.FiFo#FIFO
  self.TasksPerPlayer = FIFO:New() -- Utilities.FiFo#FIFO
  self.PrecisionTasks = FIFO:New() -- Utilities.FiFo#FIFO
  self.LasingDroneSet = SET_OPSGROUP:New() -- Core.Set#SET_OPSGROUP
  --self.PlayerMenu = {} -- #table
  self.FlashPlayer = {} -- #table
  self.AllowFlash = false
  self.lasttaskcount = 0
  
  self.taskinfomenu = false
  self.activehasinfomenu = false
  self.MenuName = nil
  self.menuitemlimit = 6
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
  self.illumenu = false
  
  self.ShowMagnetic = true
  
  self.UseTypeNames = false
  
  self.InformationMenu = false
  
  self.TaskInfoDuration = 30
  
  self.IsClientSet = false
  
  if ClientFilter and type(ClientFilter) == "table" and ClientFilter.ClassName and ClientFilter.ClassName == "SET_CLIENT" then
    -- we have a predefined SET_CLIENT
    self.ClientSet = ClientFilter
    self.IsClientSet = true
  end
   
  if ClientFilter and not self.IsClientSet then
    self.ClientSet = SET_CLIENT:New():FilterCoalitions(string.lower(self.CoalitionName)):FilterActive(true):FilterPrefixes(ClientFilter):FilterStart()
  elseif not self.IsClientSet then
    self.ClientSet = SET_CLIENT:New():FilterCoalitions(string.lower(self.CoalitionName)):FilterActive(true):FilterStart()
  end
  
  self.ActiveClientSet = SET_CLIENT:New()
  
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
  self:AddTransition("*",            "TaskProgress",          "*")
  self:AddTransition("*",            "TaskTargetSmoked",      "*")
  self:AddTransition("*",            "TaskTargetFlared",      "*")
  self:AddTransition("*",            "TaskTargetIlluminated", "*")
  self:AddTransition("*",            "TaskRepeatOnFailed",    "*")
  self:AddTransition("*",            "PlayerJoinedTask",      "*")
  self:AddTransition("*",            "PlayerAbortedTask",      "*")
  self:AddTransition("*",            "Stop",                  "Stopped")
  
  self:__Start(2)
  local starttime = math.random(10,15)
  self:__Status(starttime)
  
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
  -- @param #boolean Silent If true suppress message output.
   
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
  
  --- On After "TaskProgress" event. Task target count has been reduced.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskProgress
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task The current Task.
  -- @param #number TargetCount Targets left over
   
  --- On After "TaskRepeatOnFailed" event. Task has failed and will be repeated.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskRepeatOnFailed
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task
  
  --- On After "TaskTargetSmoked" event. Task smoked.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskTargetSmoked
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task
  
  --- On After "TaskTargetFlared" event. Task flared.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskTargetFlared
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task
  
  --- On After "TaskTargetIlluminated" event. Task illuminated.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterTaskTargetIlluminated
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.PlayerTask#PLAYERTASK Task
  
    --- On After "PlayerJoinedTask" event. Player joined a task.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterPlayerJoinedTask
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#GROUP Group The player group object
  -- @param Wrapper.Client#CLIENT Client The player client object
  -- @param Ops.PlayerTask#PLAYERTASK Task
  
    --- On After "PlayerAbortedTask" event. Player aborted a task.
  -- @function [parent=#PLAYERTASKCONTROLLER] OnAfterPlayerAbortedTask
  -- @param #PLAYERTASKCONTROLLER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#GROUP Group The player group object
  -- @param Wrapper.Client#CLIENT Client The player client object
  -- @param Ops.PlayerTask#PLAYERTASK Task
  
end

--- [User] Enable Task persistance (for specific gound target tasks)
-- @param #PLAYERTASKCONTROLLER self
-- @param #string Path Path where to save the task data
-- @param #string Filename File name under which to save the task data
-- @param #number KgsOfTNT (Optional) Explosives kgs used to remove scenery for persistence, defaults to 300
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:EnableTaskPersistance(Path,Filename,KgsOfTNT)
  self.TaskPersistanceSwitch = true
  self.TaskPersistancePath = Path
  self.TaskPersistanceFilename = Filename
  self.SceneryExplosivesAmount = KgsOfTNT or 300
  return self
end

--- [User] Disable Task persistance (for specific gound target tasks)
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:DisableTaskPersistance()
  self.TaskPersistanceSwitch = false
  self.TaskPersistancePath = nil
  self.TaskPersistanceFilename = nil
  return self
end

--- [User] Set or create a SCORING object for this taskcontroller
-- @param #PLAYERTASKCONTROLLER self
-- @param Functional.Scoring#SCORING Scoring (optional) the Scoring object
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:EnableScoring(Scoring)
  self.Scoring = Scoring or SCORING:New(self.Name)
  return self
end

--- [User] Remove the SCORING object from this taskcontroller
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:DisableScoring()
  self.Scoring = nil
  return self
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

--- [User] Show target menu entries of type names for GROUND targets (off by default!), e.g. "Tank Group..."
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetEnableUseTypeNames()
  self:T(self.lid.."SetEnableUseTypeNames")
  self.UseTypeNames = true
  return self
end

--- [User] Do not show target menu entries of type names for GROUND targets
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetDisableUseTypeNames()
  self:T(self.lid.."SetDisableUseTypeNames")
  self.UseTypeNames = false
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

--- [User] Set to show a menu entry to retrieve the radio frequencies used.
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean OnOff Set to `true` to switch on and `false` to switch off. Default is OFF.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetShowRadioInfoMenu(OnOff)
  self:T(self.lid.."SetAllowRadioInfoMenu")
  self.InformationMenu = OnOff
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

--- [User] Show menu entries to illuminate targets. Needs smoke/flare enabled.
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetEnableIlluminateTask()
  self:T(self.lid.."SetEnableSmokeFlareTask")
  self.illumenu = true
  return self
end

--- [User] Do not show menu entries to illuminate targets.
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetDisableIlluminateTask()
  self:T(self.lid.."SetDisableIlluminateTask")
  self.illumenu = false
  return self
end

--- [User] Show info text on screen with a coordinate info in any case (OFF by default)
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean OnOff Switch on = true or off = false
-- @param #boolean LLDDM Show LLDDM = true or LLDMS = false
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetInfoShowsCoordinate(OnOff,LLDDM)
  self:T(self.lid.."SetInfoShowsCoordinate")
  self.InfoHasCoordinate = OnOff
  self.InfoHasLLDDM = LLDDM
  return self
end

--- [User] Set callsign options for TTS output. See @{Wrapper.Group#GROUP.GetCustomCallSign}() on how to set customized callsigns.
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean ShortCallsign If true, only call out the major flight number
-- @param #boolean Keepnumber If true, keep the **customized callsign** in the #GROUP name for players as-is, no amendments or numbers.
-- @param #table CallsignTranslations (optional) Table to translate between DCS standard callsigns and bespoke ones. Does not apply if using customized
-- callsigns from playername or group name.
-- @param #func CallsignCustomFunc (Optional) For player names only(!). If given, this function will return the callsign. Needs to take the groupname and the playername as first two arguments.
-- @param #arg ... (Optional) Comma separated arguments to add to the custom function call after groupname and playername.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetCallSignOptions(ShortCallsign,Keepnumber,CallsignTranslations,CallsignCustomFunc,...)
  if not ShortCallsign or ShortCallsign == false then
   self.ShortCallsign = false
  else
   self.ShortCallsign = true
  end
  self.Keepnumber = Keepnumber or false
  self.CallsignTranslations = CallsignTranslations
  self.CallsignCustomFunc = CallsignCustomFunc
  self.CallsignCustomArgs = arg or {}
  return self  
end

--- [Internal] Get text for text-to-speech.
-- Numbers are spaced out, e.g. "Heading 180" becomes "Heading 1 8 0 ".
-- @param #PLAYERTASKCONTROLLER self
-- @param #string text Original text.
-- @return #string Spoken text.
function PLAYERTASKCONTROLLER:_GetTextForSpeech(text)
 self:T(self.lid.."_GetTextForSpeech")
  -- Space out numbers.
  text=string.gsub(text,"%d","%1 ")
  -- get rid of leading or trailing spaces
  text=string.gsub(text,"^%s*","")
  text=string.gsub(text,"%s*$","")
  text=string.gsub(text,"  "," ")
  
  return text
end

--- [User] Set repetition options for tasks.
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

--- [User] Set how long the briefing is shown on screen.
-- @param #PLAYERTASKCONTROLLER self
-- @param #number Seconds Duration in seconds. Defaults to 30 seconds.
-- @return #PLAYERTASKCONTROLLER self 
function PLAYERTASKCONTROLLER:SetBriefingDuration(Seconds)
  self:T(self.lid.."SetBriefingDuration")
  self.TaskInfoDuration = Seconds or 30
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
      if Client ~= nil and Client:IsActive() then
        local m = MESSAGE:New(Text,seconds,"Tasking"):ToClient(Client)
      end
    end
  )
  return self
end

--- [User] Allow precision laser-guided bombing on statics and "high-value" ground units (MBT etc)
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup The FlightGroup (e.g. drone) to be used for lasing (one unit in one group only).
-- Can optionally be handed as Ops.ArmyGroup#ARMYGROUP - **Note** might not find an LOS spot or get lost on the way. Cannot island-hop.
-- @param #number LaserCode The lasercode to be used. Defaults to 1688.
-- @param Core.Point#COORDINATE HoldingPoint (Optional) Point where the drone should initially circle. If not set, defaults to BullsEye of the coalition.
-- @param #number Alt (Optional) Altitude in feet. Only applies if using a FLIGHTGROUP object! Defaults to 10000.
-- @param #number Speed (Optional) Speed in knots. Only applies if using a FLIGHTGROUP object! Defaults to 120.
-- @param #number MaxTravelDist (Optional) Max distance to travel to traget. Only applies if using a FLIGHTGROUP object! Defaults to 100 NM.
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
function PLAYERTASKCONTROLLER:EnablePrecisionBombing(FlightGroup,LaserCode,HoldingPoint,Alt,Speed,MaxTravelDist)
  self:T(self.lid.."EnablePrecisionBombing")
  
  if not self.LasingDroneSet then 
    self.LasingDroneSet = SET_OPSGROUP:New()
  end
  
  local LasingDrone -- Ops.FlightGroup#FLIGHTGROUP FlightGroup
  
  if FlightGroup then
    if FlightGroup.ClassName and (FlightGroup.ClassName == "FLIGHTGROUP" or FlightGroup.ClassName == "ARMYGROUP")then
      -- ok we have a FG
      LasingDrone = FlightGroup -- Ops.FlightGroup#FLIGHTGROUP FlightGroup
      
      self.precisionbombing = true

      LasingDrone.playertask = {}
      LasingDrone.playertask.id = 0
      LasingDrone.playertask.busy = false
      LasingDrone.playertask.lasercode = LaserCode or 1688     
      LasingDrone:SetLaser(LasingDrone.playertask.lasercode)
      LasingDrone.playertask.template = LasingDrone:_GetTemplate(true)
      LasingDrone.playertask.alt = Alt or 10000
      LasingDrone.playertask.speed = Speed or 120
      LasingDrone.playertask.maxtravel = UTILS.NMToMeters(MaxTravelDist or 50)
      
      -- let it orbit the BullsEye if FG
      if LasingDrone:IsFlightgroup() then
        --settings.IsFlightgroup = true
        local BullsCoordinate = COORDINATE:NewFromVec3( coalition.getMainRefPoint( self.Coalition ))
        if HoldingPoint then BullsCoordinate = HoldingPoint end
        local Orbit = AUFTRAG:NewORBIT_CIRCLE(BullsCoordinate,Alt,Speed)
        Orbit:SetMissionAltitude(Alt)
        LasingDrone:AddMission(Orbit)
      elseif LasingDrone:IsArmygroup() then
        --settings.IsArmygroup = true
        local BullsCoordinate = COORDINATE:NewFromVec3( coalition.getMainRefPoint( self.Coalition ))
        if HoldingPoint then BullsCoordinate = HoldingPoint end
        local Orbit = AUFTRAG:NewONGUARD(BullsCoordinate)
        LasingDrone:AddMission(Orbit)
      end
      
      self.LasingDroneSet:AddObject(FlightGroup)
      
    elseif FlightGroup.ClassName and (FlightGroup.ClassName == "SET_OPSGROUP") then --SET_OPSGROUP
      FlightGroup:ForEachGroup(
        function(group)
          self:EnablePrecisionBombing(group,LaserCode,HoldingPoint,Alt,Speed,MaxTravelDist)
        end  
      )
    else
      self:E(self.lid.."No OPSGROUP/SET_OPSGROUP object passed or object is not alive!")
    end
  else
    self.autolase = nil
    self.precisionbombing = false
  end
  return self
end

--- [User] Convenience function - add done or ground allowing precision laser-guided bombing on statics and "high-value" ground units (MBT etc)
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup The FlightGroup (e.g. drone) to be used for lasing (one unit in one group only).
-- Can optionally be handed as Ops.ArmyGroup#ARMYGROUP - **Note** might not find an LOS spot or get lost on the way. Cannot island-hop.
-- @param #number LaserCode The lasercode to be used. Defaults to 1688.
-- @param Core.Point#COORDINATE HoldingPoint (Optional) Point where the drone should initially circle. If not set, defaults to BullsEye of the coalition.
-- @param #number Alt (Optional) Altitude in feet. Only applies if using a FLIGHTGROUP object! Defaults to 10000.
-- @param #number Speed (Optional) Speed in knots. Only applies if using a FLIGHTGROUP object! Defaults to 120.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddPrecisionBombingOpsGroup(FlightGroup,LaserCode,HoldingPoint, Alt, Speed)
  self:EnablePrecisionBombing(FlightGroup,LaserCode,HoldingPoint,Alt,Speed)
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
-- @usage
-- Enable the function like so:
--          mycontroller:EnableMarkerOps("TASK")
-- Then as a player in a client slot, you can add a map marker on the F10 map. Next edit the text
-- in the marker to make it identifiable, e.g
-- 
-- TASK Name=Tanks Sochi, Text=Destroy tank group located near Sochi!
-- 
-- Where **TASK** is the tag that tells the controller this mark is a target location (must).
-- **Name=** ended by a comma **,** tells the controller the supposed menu entry name (optional). No extra spaces! End with a comma!
-- **Text=** tells the controller the supposed free text task description (optional, only taken if **Name=** is present first). No extra spaces!
function PLAYERTASKCONTROLLER:EnableMarkerOps(Tag)
  self:T(self.lid.."EnableMarkerOps")
   
  local tag = Tag or "TASK"
  local MarkerOps = MARKEROPS_BASE:New(tag,{"Name","Text"},true)
  
  local function Handler(Keywords,Coord,Text)
    if self.verbose then
      local m = MESSAGE:New(string.format("Target added from marker at: %s", Coord:ToStringA2G(nil, nil, self.ShowMagnetic)),15,"INFO"):ToAll()
      local m = MESSAGE:New(string.format("Text: %s", Text),15,"INFO"):ToAll()
    end
    local menuname = string.match(Text,"Name=(.+),")
    local freetext = string.match(Text,"Text=(.+)")
    if menuname then
      Coord.menuname = menuname
      if freetext then
       Coord.freetext = freetext
      end
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
    if playergroup ~= nil then
      ttsplayername = playergroup:GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
      local newplayername = self:_GetTextForSpeech(ttsplayername)
      self.customcallsigns[playername] = newplayername
      ttsplayername = newplayername
    end
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
  self.menuitemlimit = ItemLimit+1 or 6
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
  --self:T(self.lid.."_EventHandler: "..EventData.IniPlayerName)
  if EventData.id == EVENTS.UnitLost or EventData.id == EVENTS.PlayerLeaveUnit or EventData.id == EVENTS.Ejection or EventData.id == EVENTS.Crash or EventData.id == EVENTS.PilotDead then
    if EventData.IniPlayerName then
      self:T(self.lid.."Event for player: "..EventData.IniPlayerName)
      --if self.PlayerMenu[EventData.IniPlayerName] then
        --self.PlayerMenu[EventData.IniPlayerName]:Remove()
        --self.PlayerMenu[EventData.IniPlayerName] = nil
      --end
        local text = ""
        if self.TasksPerPlayer:HasUniqueID(EventData.IniPlayerName) then
          local task = self.TasksPerPlayer:PullByID(EventData.IniPlayerName) -- Ops.PlayerTask#PLAYERTASK
          local Client = _DATABASE:FindClient( EventData.IniPlayerName )
          if Client then
            task:RemoveClient(Client)
            --text = "Task aborted!"
            text = self.gettext:GetEntry("TASKABORT",self.locale)
            self.ActiveTaskMenuTemplate:ResetMenu(Client)
            self.JoinTaskMenuTemplate:ResetMenu(Client)
          else
            task:RemoveClient(nil,EventData.IniPlayerName)
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
    if EventData.IniPlayerName and EventData.IniGroup then
      --if self.IsClientSet and self.ClientSet:IsNotInSet(CLIENT:FindByName(EventData.IniUnitName)) then
      if self.IsClientSet and (not self.ClientSet:IsIncludeObject(CLIENT:FindByName(EventData.IniUnitName))) then
        self:T(self.lid.."Client not in SET: "..EventData.IniPlayerName)
        return self
      end
      self:T(self.lid.."Event for player: "..EventData.IniPlayerName)
      
      if self.UseSRS then
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
          playername = EventData.IniGroup:GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
        end
        playername = self:_GetTextForSpeech(playername)
        --local text = string.format("%s, %s, switch to %s for task assignment!",EventData.IniPlayerName,self.MenuName or self.Name,freqtext)
        local text = string.format(switchtext,playername,self.MenuName or self.Name,freqtext)
        self.SRSQueue:NewTransmission(text,nil,self.SRS,timer.getAbsTime()+60,2,{EventData.IniGroup},text,30,self.BCFrequency,self.BCModulation)
      end
      if EventData.IniPlayerName then
        --self.PlayerMenu[EventData.IniPlayerName] = nil
        local player = _DATABASE:FindClient( EventData.IniUnitName )
        self:_SwitchMenuForClient(player,"Info")
      end
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
-- @param Ops.PlayerTask#PLAYERTASK Task The task to be cancelled.
-- @param #boolean Silent If true suppress message output.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:CancelTask(Task,Silent)
  self:T(self.lid.."CancelTask")
  Task:__Cancel(-1,Silent)
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

--- [User] Switch showing additional magnetic angles
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean OnOff If true, set to on (default), if nil or false, set to off
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SwitchMagenticAngles(OnOff)
  self:T(self.lid.."SwitchMagenticAngles")
  if OnOff then
    self.ShowMagnetic = true
  else
   self.ShowMagnetic = false
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
  
  --self:I({tasktypes})
  
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
    local name = task.Target:GetName()
    --self:I(name)
    if not task:IsDone() then
      --self:I(name)
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
  local object = self.TargetQueue:Pull() -- Wrapper.Positionable#POSITIONABLE
  local target = TARGET:New(object)
  if object.menuname then
    target.menuname = object.menuname
    if object.freetext then
      target.freetext = object.freetext
    end
  end
  
  if object:IsInstanceOf("UNIT") or object:IsInstanceOf("GROUP") then
  
    if self.UseTypeNames and object:IsGround() then
      --   * Threat level  0: Unit is unarmed.
      --   * Threat level  1: Unit is infantry.
      --   * Threat level  2: Unit is an infantry vehicle.
      --   * Threat level  3: Unit is ground artillery.
      --   * Threat level  4: Unit is a tank.
      --   * Threat level  5: Unit is a modern tank or ifv with ATGM.
      --   * Threat level  6: Unit is a AAA.
      --   * Threat level  7: Unit is a SAM or manpad, IR guided.
      --   * Threat level  8: Unit is a Short Range SAM, radar guided.
      --   * Threat level  9: Unit is a Medium Range SAM, radar guided.
      --   * Threat level 10: Unit is a Long Range SAM, radar guided.
      local threat = object:GetThreatLevel()
      local typekey = "INFANTRY"
      if threat == 0 or threat == 2 then
        typekey = "TECHNICAL"
      elseif threat == 3 then
        typekey = "ARTILLERY" 
      elseif threat == 4 or  threat == 5 then
        typekey = "TANKS"
      elseif threat == 6 or threat == 7 then
        typekey = "AIRDEFENSE"
      elseif threat >= 8 then
        typekey = "SAM"
      end
      local typename = self.gettext:GetEntry(typekey,self.locale)
      local gname = self.gettext:GetEntry("GROUP",self.locale)
      target.TypeName = string.format("%s %s",typename,gname)
      --self:T(self.lid.."Target TypeName = "..target.TypeName)
    end
    
    if self.UseTypeNames and object:IsShip() then
      local threat = object:GetThreatLevel()
      local typekey = "UNARMEDSHIP"
      if threat == 1 then
        typekey = "LIGHTARMEDSHIP"
      elseif threat == 2 then
        typekey = "CORVETTE" 
      elseif threat == 3 or  threat == 4 then
        typekey = "FRIGATE"
      elseif threat == 5 or threat == 6 then
        typekey = "CRUISER"
      elseif threat == 7 or threat == 8 then
        typekey = "DESTROYER"
      elseif threat >= 9 then
        typekey = "CARRIER"
      end
      local typename = self.gettext:GetEntry(typekey,self.locale)
      target.TypeName = typename
      --self:T(self.lid.."Target TypeName = "..target.TypeName)
    end
  
  end
  
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
      local clients=task:GetClientObjects()
      for _,client in pairs(clients) do
        self:_RemoveMenuEntriesForTask(task,client)
        --self:_SwitchMenuForClient(client,"Info")
      end
      for _,client in pairs(clients) do
       -- self:_RemoveMenuEntriesForTask(Task,client)
        self:_SwitchMenuForClient(client,"Info",5)
      end
      -- Follow-up tasks?
      local nexttasks = {}
      if task.FinalState == "Success" then
        nexttasks = task.NextTaskSuccess
      elseif task.FinalState == "Failed" then
       nexttasks = task.NextTaskFailure
      end
      local clientlist, count = task:GetClientObjects()
      if count > 0 then
        for _,_client in pairs(clientlist) do
          local client = _client --Wrapper.Client#CLIENT
          local group = client:GetGroup()
          for _,task in pairs(nexttasks) do  
            self:_JoinTask(task,true,group,client)
          end
        end
      end
      local TNow = timer.getAbsTime()
      if TNow - task.timestamp > 5 then
        self:_RemoveMenuEntriesForTask(task)
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
 self:T(self.lid.."_CheckPrecisionTasks")
 self:T({count=self.PrecisionTasks:Count(),enabled=self.precisionbombing})
 if self.PrecisionTasks:Count() > 0 and self.precisionbombing then
   
   -- alive checks
   self.LasingDroneSet:ForEachGroup(  
   function(LasingDrone)
     if not LasingDrone or LasingDrone:IsDead() then
      -- we need a new drone
      self:E(self.lid.."Lasing drone is dead ... creating a new one!")
      if LasingDrone then
        LasingDrone:_Respawn(1,nil,true)
      else
        --[[
        -- DONE: Handle ArmyGroup
        if LasingDrone:IsFlightgroup() then
          local FG = FLIGHTGROUP:New(LasingDroneTemplate)
          FG:Activate()
          self:EnablePrecisionBombing(FG,self.LaserCode or 1688)
        else
          local FG = ARMYGROUP:New(LasingDroneTemplate)
          FG:Activate()
          self:EnablePrecisionBombing(FG,self.LaserCode or 1688)
        end -- if LasingDroneIsFlightgroup
        --]]
      end -- if LasingDrone
     end -- if not LasingDrone
    end -- function
    )
  
  local function SelectDrone(coord)
    local selected = nil
    local mindist = math.huge
    local dist = math.huge
    self.LasingDroneSet:ForEachGroup(
      function(grp)
        if grp.playertask and (not grp.playertask.busy) then
          local gc = grp:GetCoordinate()
          if coord and gc then
            dist = coord:Get2DDistance(gc)
          end
          if dist < mindist then
            selected = grp
            mindist = dist
          end
        end
      end
    )
    return selected
  end
  
  local task = self.PrecisionTasks:Pull() -- Ops.PlayerTask#PLAYERTASK
  local taskpt = task.Target:GetCoordinate() 
    
  local SelectedDrone = SelectDrone(taskpt) -- Ops.OpsGroup#OPSGROUP
    
  -- do we have a lasing unit assignable?
  if SelectedDrone and SelectedDrone:IsAlive() then
    if SelectedDrone.playertask and (not SelectedDrone.playertask.busy) then
      -- not busy, get a task
      self:T(self.lid.."Sending lasing unit to target")
      local isassigned = self:_FindLasingDroneForTaskID(task.PlayerTaskNr)
      -- distance check
      local startpoint = SelectedDrone:GetCoordinate()
      local endpoint = task.Target:GetCoordinate()      
      local dist = math.huge
      if startpoint and endpoint then
        dist = startpoint:Get2DDistance(endpoint)
      end
      if dist <= SelectedDrone.playertask.maxtravel and (not isassigned) then
        SelectedDrone.playertask.id = task.PlayerTaskNr
        SelectedDrone.playertask.busy = true
        SelectedDrone.playertask.inreach = false
        SelectedDrone.playertask.reachmessage = false
        -- move the drone to target
        if SelectedDrone:IsFlightgroup() then
          SelectedDrone:CancelAllMissions()
          local auftrag = AUFTRAG:NewORBIT_CIRCLE(task.Target:GetCoordinate(),SelectedDrone.playertask.alt,SelectedDrone.playertask.speed)
          SelectedDrone:AddMission(auftrag)   
        elseif SelectedDrone:IsArmygroup() then
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
            SelectedDrone:CancelAllMissions()
            -- yeah we got one
            local auftrag = AUFTRAG:NewARMOREDGUARD(finalpos,"Off road")
            SelectedDrone:AddMission(auftrag)
          else
            -- could not find LOS position!
            self:E("***Could not find LOS position to post ArmyGroup for lasing!")
            SelectedDrone.playertask.id = 0
            SelectedDrone.playertask.busy = false
            SelectedDrone.playertask.inreach = false
            SelectedDrone.playertask.reachmessage = false
          end
        end
      else
        self:T(self.lid.."Lasing unit too far from target")
      end
      
    end
  end
  
  self.PrecisionTasks:Push(task,task.PlayerTaskNr)
  
  
    local function DronesWithTask(SelectedDrone)
    -- handle drones with a task
    if SelectedDrone.playertask and SelectedDrone.playertask.busy then
      -- drone is busy, set up laser when over target
      local task = self.PrecisionTasks:ReadByID(SelectedDrone.playertask.id) -- Ops.PlayerTask#PLAYERTASK
      self:T("Looking at Task: "..task.PlayerTaskNr.." Type: "..task.Type.." State: "..task:GetState())
      if (not task) or task:GetState() == "Done" or task:GetState() == "Stopped" then
        -- we're done here
        local task = self.PrecisionTasks:PullByID(SelectedDrone.playertask.id) -- Ops.PlayerTask#PLAYERTASK
        self:_CheckTaskQueue()
        task = nil
        if SelectedDrone:IsLasing() then
          SelectedDrone:__LaserOff(-1)
        end
        SelectedDrone.playertask.busy = false
        SelectedDrone.playertask.inreach = false
        SelectedDrone.playertask.id = 0
        SelectedDrone.playertask.reachmessage = false
        self:T(self.lid.."Laser Off")
      else
        -- not done yet
        self:T(self.lid.."Not done yet")
        local dcoord = SelectedDrone:GetCoordinate()
        local tcoord = task.Target:GetCoordinate()
        tcoord.y = tcoord.y + 2 
        local dist = dcoord:Get2DDistance(tcoord)
        self:T(self.lid.."Dist "..dist)
        -- close enough?
        if dist < 3000 and not SelectedDrone:IsLasing() then
          self:T(self.lid.."Laser On")
          SelectedDrone:__LaserOn(-1,tcoord)
          SelectedDrone.playertask.inreach = true
          if not SelectedDrone.playertask.reachmessage then
            --local textmark = self.gettext:GetEntry("FLARETASK",self.locale)
            SelectedDrone.playertask.reachmessage = true
            local clients = task:GetClients()
            local text = ""
            for _,playername in pairs(clients) do
              local pointertext = self.gettext:GetEntry("POINTEROVERTARGET",self.locale)
              local ttsplayername = playername
              if self.customcallsigns[playername] then
                ttsplayername = self.customcallsigns[playername]
              end --
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
                end --
              end --
            end --
            if self.UseSRS then
              self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
            end --
          end --
        end --
      end -- end else
    end -- end handle drones with a task
   end -- end function
   
   self.LasingDroneSet:ForEachGroup(DronesWithTask)
  
 end --
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
      -- observe Tags coming from MarkerOps
      if Target.menuname then
        enemysetg.menuname = Target.menuname
        if Target.freetext then
          enemysetg.freetext = Target.freetext
        end
      end
      self:AddTarget(enemysetg)
    end
    if counts > 0 then
      -- observe Tags coming from MarkerOps
      if Target.menuname then
        enemysets.menuname = Target.menuname
        if Target.freetext then
          enemysets.freetext = Target.freetext
        end
      end
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
  
  -- observe Tags coming from MarkerOps
  if Target.menuname then
    task:SetMenuName(Target.menuname)
    if Target.freetext then
      task:AddFreetext(Target.freetext)
    end
  end
  
  task.coalition = self.Coalition
  task.TypeName = Target.TypeName
  
  if type == AUFTRAG.Type.BOMBRUNWAY then
    -- task to handle event shot
    task:HandleEvent(EVENTS.Shot)
    function task:OnEventShot(EventData)
      local data = EventData -- Core.Event#EVENTDATA EventData
      local wcat = Object.getCategory(data.Weapon) -- cat 2 or 3
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
  self:__TaskAdded(10,task)
  
  return self
end

--- [User] Add a PLAYERTASK object to the list of (open) tasks
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.PlayerTask#PLAYERTASK PlayerTask
-- @param #boolean Silent If true, make no "has new task" announcement
-- @param #boolean TaskFilter If true, apply the white/black-list task filters here, also
-- @return #PLAYERTASKCONTROLLER self
-- @usage
-- Example to create a PLAYERTASK of type CTLD and give Players 10 minutes to complete:
-- 
--        local newtask = PLAYERTASK:New(AUFTRAG.Type.CTLD,ZONE:Find("Unloading"),false,0,"Combat Transport")
--        newtask.Time0 = timer.getAbsTime()    -- inject a timestamp for T0
--        newtask:AddFreetext("Transport crates to the drop zone and build a vehicle in the next 10 minutes!")
--        
--        -- add a condition for failure - fail after 10 minutes
--        newtask:AddConditionFailure(
--          function()
--            local Time = timer.getAbsTime()
--            if Time - newtask.Time0 > 600 then
--              return true
--            end 
--            return false
--          end
--          )  
--          
--        taskmanager:AddPlayerTaskToQueue(PlayerTask)     
function PLAYERTASKCONTROLLER:AddPlayerTaskToQueue(PlayerTask,Silent,TaskFilter)
  self:T(self.lid.."AddPlayerTaskToQueue")
  if PlayerTask and PlayerTask.ClassName and PlayerTask.ClassName == "PLAYERTASK" then
    if TaskFilter then  
      if self.UseWhiteList and (not self:_CheckTaskTypeAllowed(PlayerTask.Type)) then
          return self
      end      
      if self.UseBlackList and self:_CheckTaskTypeDisallowed(PlayerTask.Type) then
          return self
      end
    end
    PlayerTask:_SetController(self)
    PlayerTask:SetCoalition(self.Coalition)
    self.TaskQueue:Push(PlayerTask)
    --if not Silent then
      self:__TaskAdded(10,PlayerTask,Silent)
    --end
  else
    self:E(self.lid.."***** NO valid PAYERTASK object sent!")
  end
  return self
end

--- [User] Override this function in order to implement custom logic if a player can join a task or not.
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #boolean Outcome True if player can join the task, false if not
function PLAYERTASKCONTROLLER:CanJoinTask(Task, Group, Client)
    return true
end

--- [Internal] Join a player to a task
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @param #boolean Force Assign task even if client already has one
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_JoinTask(Task, Force, Group, Client)
  self:T({Force, Group, Client})
  self:T(self.lid.."_JoinTask")

  if not self:CanJoinTask(Task, Group, Client) then
    return self
  end

  if not Task:CanJoinTask(Group, Client) then
    return self
  end

  local force = false
  if type(Force) == "boolean" then
    force = Force
  end
  local playername, ttsplayername = self:_GetPlayerName(Client)
  if self.TasksPerPlayer:HasUniqueID(playername) and not force then
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
    --self:I(string.format("Task %s | TaskType %s | Number %s | Type %s",self.MenuName or self.Name, Task.TTSType, tonumber(Task.PlayerTaskNr),type(Task.PlayerTaskNr)))
    local text = string.format(joined,ttsplayername, self.MenuName or self.Name, Task.TTSType, Task.PlayerTaskNr)
    self:T(self.lid..text)
    if not self.NoScreenOutput then
      self:_SendMessageToClients(text)
      --local m=MESSAGE:New(text,"10","Tasking"):ToAll()
    end
    if self.UseSRS then
      self:T(self.lid..text)
      self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
    end
    self.TasksPerPlayer:Push(Task,playername)
    self:__PlayerJoinedTask(1, Group, Client, Task)
    -- clear menu
    self:_SwitchMenuForClient(Client,"Active",1)
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

function PLAYERTASKCONTROLLER:_ShowRadioInfo(Group, Client)
  self:T(self.lid.."_ShowRadioInfo")
  local playername, ttsplayername = self:_GetPlayerName(Client)
  
  if self.UseSRS then
    local frequency = self.Frequency
    local freqtext = ""
    if type(frequency) == "table" then
      freqtext = self.gettext:GetEntry("FREQUENCIES",self.locale)
      freqtext = freqtext..table.concat(frequency,", ")      
    else
      local freqt = self.gettext:GetEntry("FREQUENCY",self.locale)
      freqtext = string.format(freqt,frequency)
    end
    
    local switchtext = self.gettext:GetEntry("BROADCAST",self.locale)

    playername = ttsplayername or self:_GetTextForSpeech(playername)
    --local text = string.format("%s, %s, switch to %s for task assignment!",EventData.IniPlayerName,self.MenuName or self.Name,freqtext)
    local text = string.format(switchtext,playername,self.MenuName or self.Name,freqtext)
    self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2,{Group},text,30,self.BCFrequency,self.BCModulation)
  end
  
  return self
end

--- Calculate group future position after given seconds.
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP group The group to calculate for.
-- @param #number seconds Time interval in seconds. Default is `self.prediction`.
-- @return Core.Point#COORDINATE Calculated future position of the cluster.
function PLAYERTASKCONTROLLER:_CalcGroupFuturePosition(group, seconds)

  -- Get current position of the cluster.
  local p=group:GetCoordinate()

  -- Velocity vector in m/s.
  local v=group:GetVelocityVec3()

  -- Time in seconds.
  local t=seconds or self.prediction

  -- Extrapolated vec3.
  local Vec3={x=p.x+v.x*t, y=p.y+v.y*t, z=p.z+v.z*t}

  -- Future position.
  local futureposition=COORDINATE:NewFromVec3(Vec3)

  -- Create an arrow pointing in the direction of the movement.
  if self.verbose == true then
    local markerID = group:GetProperty("PLAYERTASK_ARROW")
    if markerID then
      COORDINATE:RemoveMark(markerID)
    end
    markerID = p:ArrowToAll(futureposition, self.coalition, {1,0,0}, 1, {1,1,0}, 0.5, 2, true, "Position Calc")
    group:SetProperty("PLAYERTASK_ARROW",markerID)
  end

  return futureposition
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
        local Coordinate = task.Target:GetCoordinate() -- Core.Point#COORDINATE
        local CoordText = ""
        if self.Type ~= PLAYERTASKCONTROLLER.Type.A2A and task.Type~=AUFTRAG.Type.INTERCEPT then
          CoordText = Coordinate:ToStringA2G(_client, nil, self.ShowMagnetic)
          local targettxt = self.gettext:GetEntry("TARGET",self.locale)
          local text = targettxt..": "..CoordText
          local m = MESSAGE:New(text,10,"Tasking"):ToClient(_client)
        else
          CoordText = Coordinate:ToStringA2A(_client, nil, self.ShowMagnetic)
          local targettxt = self.gettext:GetEntry("TARGET",self.locale)
          local text = targettxt..": "..CoordText
          -- calc intercept position
          local name=task.Target:GetName()
          local group = GROUP:FindByName(name)
          local clientcoord = _client:GetCoordinate()
          if group and clientcoord and group:IsAlive() and task.Type==AUFTRAG.Type.INTERCEPT then
            local speed = math.max(UTILS.KnotsToMps(350) or _client:GetVelocityMPS())
            local dist = Coordinate:Get3DDistance(clientcoord)
            local iTime = math.floor(dist/speed)+5
            if iTime < 10 then iTime = 10 
            elseif iTime > 600 then iTime = 600 end 
            local npos = self:_CalcGroupFuturePosition(group,iTime)
            local BR = npos:ToStringBearing(clientcoord,nil,self.ShowMagnetic,0 )
            local Intercepttext = self.gettext:GetEntry("INTERCEPTCOURSE",self.locale)
            text = text .. "\n"..Intercepttext.." "..BR
          end
          local m = MESSAGE:New(text,10,"Tasking"):ToClient(_client)
        end
      end
    end
  end
  return self
end

--- [Internal] Find matching drone for precision bombing task, if any is assigned.
-- @param #PLAYERTASKCONTROLLER self
-- @param #number ID Task ID to look for
-- @return Ops.OpsGroup#OPSGROUP Drone
function PLAYERTASKCONTROLLER:_FindLasingDroneForTaskID(ID)
  local drone = nil
  self.LasingDroneSet:ForEachGroup(
    function(grp)
      if grp and grp:IsAlive() and grp.playertask and grp.playertask.id and grp.playertask.id == ID then
        drone = grp
      end
    end
  )
  return drone
end

--- [Internal] Show active task info
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.PlayerTask#PLAYERTASK Task
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_ActiveTaskInfo(Task, Group, Client)
  self:T(self.lid.."_ActiveTaskInfo")
  local playername, ttsplayername = self:_GetPlayerName(Client)
  local text = ""
  local textTTS = ""
  local task = nil
  if type(Task) ~= "string" then
    task = Task
  end
  if self.TasksPerPlayer:HasUniqueID(playername) or task then
    -- NODO: Show multiple?
    -- Details
    local task = task or self.TasksPerPlayer:ReadByID(playername) -- Ops.PlayerTask#PLAYERTASK
    local tname = self.gettext:GetEntry("TASKNAME",self.locale)
    local ttsname = self.gettext:GetEntry("TASKNAMETTS",self.locale)
    local taskname = string.format(tname,task.Type,task.PlayerTaskNr)
    local ttstaskname = string.format(ttsname,task.TTSType,task.PlayerTaskNr)
    local Coordinate = task.Target:GetCoordinate() or COORDINATE:New(0,0,0) -- Core.Point#COORDINATE
    local Elevation = Coordinate:GetLandHeight() or 0 -- meters
    local CoordText = ""
    local CoordTextLLDM = nil
    local ShowThreatInfo = task.ShowThreatDetails
    local LasingDrone = self:_FindLasingDroneForTaskID(task.PlayerTaskNr)
    if self.Type ~= PLAYERTASKCONTROLLER.Type.A2A and task.Type~=AUFTRAG.Type.INTERCEPT then
      CoordText = Coordinate:ToStringA2G(Client,nil,self.ShowMagnetic)
    else
      CoordText = Coordinate:ToStringA2A(Client,nil,self.ShowMagnetic)
    end
    --self:I("CoordText = "..CoordText)
    -- Threat Level
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
    -- Targetno and Threat
    local targets = task.Target:CountTargets() or 0
    local clientlist, clientcount = task:GetClients()
    local ThreatGraph = "[" .. string.rep(  "■", ThreatLevel ) .. string.rep(  "□", 10 - ThreatLevel ) .. "]: "..ThreatLevel
    local ThreatLocaleText = self.gettext:GetEntry("THREATTEXT",self.locale)
    if ShowThreatInfo == true then
      text = string.format(ThreatLocaleText, taskname, ThreatGraph, targets, CoordText)
    else
      ThreatLocaleText = self.gettext:GetEntry("NOTHREATTEXT",self.locale)
      text = string.format(ThreatLocaleText, taskname)
    end
    local settings = _DATABASE:GetPlayerSettings(playername) or _SETTINGS -- Core.Settings#SETTINGS
    local elevationmeasure = self.gettext:GetEntry("FEET",self.locale)
    if settings:IsMetric() then
      elevationmeasure = self.gettext:GetEntry("METER",self.locale)
      --Elevation = math.floor(UTILS.MetersToFeet(Elevation))
    else
      Elevation = math.floor(UTILS.MetersToFeet(Elevation))
    end
    -- ELEVATION = "\nTarget Elevation: %s %s",
    if task.Type ~= AUFTRAG.Type.INTERCEPT then
      local elev = self.gettext:GetEntry("ELEVATION",self.locale)
      text = text .. string.format(elev,tostring(math.floor(Elevation)),elevationmeasure)
    end
    -- Prec bombing
    if task.Type == AUFTRAG.Type.PRECISIONBOMBING and self.precisionbombing then
      if LasingDrone and LasingDrone.playertask then
        local yes = self.gettext:GetEntry("YES",self.locale)
        local no = self.gettext:GetEntry("NO",self.locale)
        local inreach = LasingDrone.playertask.inreach == true and yes or no
        local islasing = LasingDrone:IsLasing() == true and yes or no
        local prectext = self.gettext:GetEntry("POINTERTARGETREPORT",self.locale)
        prectext = string.format(prectext,inreach,islasing)
        text = text .. prectext.." ("..LasingDrone.playertask.lasercode..")"
      end
    end
    -- Buddylasing
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
          local callsign = player:GetGroup():GetCustomCallSign(self.ShortCallsign,self.Keepnumber,self.CallsignTranslations,self.CallsignCustomFunc,self.CallsignCustomArgs)
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
    -- Transport
   elseif task.Type == AUFTRAG.Type.CTLD or task.Type == AUFTRAG.Type.CSAR then
   --                THREATTEXT = "%s\nThreat: %s\nTargets left: %d\nCoord: %s",
   --                THREATTEXTTTS = "%s, %s. Target information for %s. Threat level %s. Targets left %d. Target location %s.",
    text = taskname
    textTTS = taskname
    local detail = task:GetFreetext()
    local detailTTS = task:GetFreetextTTS()
    local brieftxt = self.gettext:GetEntry("BRIEFING",self.locale)
    local locatxt = self.gettext:GetEntry("TARGETLOCATION",self.locale)
    text = text .. string.format("\n%s: %s\n%s %s",brieftxt,detail,locatxt,CoordText)
    --text = text .. "\nBriefing: "..detail.."\nTarget location "..CoordText
    --textTTS = textTTS .. "; Briefing: "..detailTTS.."\nTarget location "..CoordText
    textTTS = textTTS .. string.format("; %s: %s; %s %s",brieftxt,detailTTS,locatxt,CoordText)
   end
   
   -- Pilots
    local clienttxt = self.gettext:GetEntry("PILOTS",self.locale)
    if clientcount > 0 then
      for _,_name in pairs(clientlist) do
        if self.customcallsigns[_name] then
          _name = self.customcallsigns[_name]
          _name = string.gsub(_name, "(%d) ","%1") 
        end
        clienttxt = clienttxt .. _name .. ", "
      end
      clienttxt=string.gsub(clienttxt,", $",".")
    else
      local keine = self.gettext:GetEntry("NONE",self.locale)
      clienttxt = clienttxt .. keine
    end  
    text = text .. clienttxt
    textTTS = textTTS .. clienttxt
    -- Task Report
    if self.InfoHasCoordinate then
      if self.InfoHasLLDDM then
        CoordTextLLDM = Coordinate:ToStringLLDDM()
      else
        CoordTextLLDM = Coordinate:ToStringLLDMS()
      end
      -- TARGETLOCATION
      local locatxt = self.gettext:GetEntry("COORDINATE",self.locale)
      text = string.format("%s\n%s: %s",text,locatxt,CoordTextLLDM)
    end
    if task:HasFreetext() and not ( task.Type == AUFTRAG.Type.CTLD or task.Type == AUFTRAG.Type.CSAR) then
      local brieftxt = self.gettext:GetEntry("BRIEFING",self.locale)
      text = text .. string.format("\n%s: ",brieftxt)..task:GetFreetext()
    end

    if self.UseSRS then
      if string.find(CoordText," BR, ") then
        CoordText = string.gsub(CoordText," BR, "," Bee, Arr; ")
      end
      if self.ShowMagnetic then
        text=string.gsub(text,"°M|","° magnetic; ")
      end
      if string.find(CoordText,"MGRS") then
        local Text = string.gsub(CoordText,"MGRS ","")
        Text = string.gsub(Text,"%s+","")
        Text = string.gsub(Text,"([%a%d])","%1;") -- "0 5 1 "
        Text = string.gsub(Text,"0","zero")
        Text = string.gsub(Text,"9","niner")
        CoordText = "MGRS;"..Text
        if self.PathToGoogleKey then
          --CoordText = string.format("<say-as interpret-as=\'characters\'>%s</say-as>",CoordText)
          --doesn't seem to work any longer
        end
        --self:I(self.lid.." | ".. CoordText)
      end
      local ttstext
      local ThreatLocaleTextTTS = self.gettext:GetEntry("THREATTEXTTTS",self.locale)
      --                THREATTEXT = "%s\nThreat: %s\nTargets left: %d\nCoord: %s",
      --                THREATTEXTTTS = "%s, %s. Target information for %s. Threat level %s. Targets left %d. Target location %s.",
      if ShowThreatInfo == true then
        ttstext = string.format(ThreatLocaleTextTTS,ttsplayername,self.MenuName or self.Name,ttstaskname,ThreatLevelText, targets, CoordText)
      else
       ThreatLocaleTextTTS = self.gettext:GetEntry("NOTHREATTEXTTTS",self.locale)
       ttstext = string.format(ThreatLocaleTextTTS,ttsplayername,self.MenuName or self.Name)
      end
      
      -- POINTERTARGETLASINGTTS = ". Pointer over target and lasing."
      
      if task.Type == AUFTRAG.Type.PRECISIONBOMBING and self.precisionbombing then
        if LasingDrone and  LasingDrone.playertask.inreach and LasingDrone:IsLasing() then
          local lasingtext = self.gettext:GetEntry("POINTERTARGETLASINGTTS",self.locale)
          ttstext = ttstext .. lasingtext
        end
      elseif task.Type == AUFTRAG.Type.CTLD or task.Type == AUFTRAG.Type.CSAR then
       ttstext = textTTS
       if string.find(ttstext," BR, ") then
        CoordText = string.gsub(ttstext," BR, "," Bee, Arr, ")
       end
      elseif task:HasFreetext() then
      
        -- add tts freetext
        local brieftxt = self.gettext:GetEntry("BRIEFING",self.locale)
        ttstext = ttstext .. string.format("; %s: ",brieftxt)..task:GetFreetextTTS()
      end
      --self:I("**** TTS Text ****\n"..ttstext.."\n*****")
      self.SRSQueue:NewTransmission(ttstext,nil,self.SRS,nil,2)
    end  
  else
    text = self.gettext:GetEntry("NOACTIVETASK",self.locale)
  end
  if not self.NoScreenOutput then
    local m=MESSAGE:New(text,self.TaskInfoDuration or 30,"Tasking"):ToClient(Client)
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
    if task.CanSmoke == true then
      task:SmokeTarget()
      local textmark = self.gettext:GetEntry("SMOKETASK",self.locale)
      text = string.format(textmark, ttsplayername, self.MenuName or self.Name, task.PlayerTaskNr)
      self:T(self.lid..text)
      --local m=MESSAGE:New(text,"10","Tasking"):ToAll()
      if self.UseSRS then
        self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
      end
      self:__TaskTargetSmoked(5,task)
    else
      local textmark = self.gettext:GetEntry("NOSMOKETASK",self.locale)
      text = string.format(textmark, ttsplayername, self.MenuName or self.Name, task.PlayerTaskNr)
      self:T(self.lid..text)
      --local m=MESSAGE:New(text,"10","Tasking"):ToAll()
      if self.UseSRS then
        self.SRSQueue:NewTransmission(text,nil,self.SRS,nil,2)
      end
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
    self:__TaskTargetFlared(5,task)
  else
    text = self.gettext:GetEntry("NOACTIVETASK",self.locale)
  end
  if not self.NoScreenOutput then
    local m=MESSAGE:New(text,15,"Tasking"):ToClient(Client)
  end
  return self
end

--- [Internal] Illuminate task location
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_IlluminateTask(Group, Client)
  self:T(self.lid.."_IlluminateTask")
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
    self:__TaskTargetIlluminated(5,task)
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
  self:T(self.lid.."_AbortTask")
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
    self:__PlayerAbortedTask(1,Group, Client,task)
  else
    text = self.gettext:GetEntry("NOACTIVETASK",self.locale)
  end
  if not self.NoScreenOutput then
    local m=MESSAGE:New(text,15,"Tasking"):ToClient(Client)
  end
  self:_SwitchMenuForClient(Client,"Info",1)
  return self
end


-- TODO - New Menu Manager
--- [Internal] _UpdateJoinMenuTemplate
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_UpdateJoinMenuTemplate()
  self:T("_UpdateJoinMenuTemplate")
  if self.TaskQueue:Count() > 0 then
    local taskpertype = self:_GetTasksPerType()
    local JoinMenu = self.JoinMenu -- Core.ClientMenu#CLIENTMENU
    --self:I(JoinMenu.UUID)
    local controller = self.JoinTaskMenuTemplate -- Core.ClientMenu#CLIENTMENUMANAGER
    local actcontroller = self.ActiveTaskMenuTemplate -- Core.ClientMenu#CLIENTMENUMANAGER
    local actinfomenu = self.ActiveInfoMenu
    --local entrynumbers = {}
    --local existingentries = {}
    
    if self.TaskQueue:Count() == 0 and self.MenuNoTask == nil then
      local menunotasks = self.gettext:GetEntry("MENUNOTASKS",self.locale)  
      self.MenuNoTask = controller:NewEntry(menunotasks,self.JoinMenu)
      controller:AddEntry(self.MenuNoTask)
    end
    
    if self.TaskQueue:Count() > 0 and self.MenuNoTask ~= nil then
      controller:DeleteGenericEntry(self.MenuNoTask)
      controller:DeleteF10Entry(self.MenuNoTask)
      self.MenuNoTask = nil
    end
    
    local maxn = self.menuitemlimit
    -- Generate task type menu items
    for _type,_ in pairs(taskpertype) do
      local found = controller:FindEntriesByText(_type)
      --self:I({found})
      if #found == 0 then
        local newentry = controller:NewEntry(_type,JoinMenu)
        controller:AddEntry(newentry)
        if self.JoinInfoMenu then
          local newentry = controller:NewEntry(_type,self.JoinInfoMenu)
          controller:AddEntry(newentry)
        end
        if actinfomenu then
          local newentry = actcontroller:NewEntry(_type,self.ActiveInfoMenu)
          actcontroller:AddEntry(newentry)
        end
      end
    end
    
    local typelist = self:_GetAvailableTaskTypes()
    -- Slot in Tasks
    for _tasktype,_data in pairs(typelist) do
      self:T("**** Building for TaskType: ".._tasktype)
      --local tasks = taskpertype[_tasktype] or {}
      for _,_task in pairs(taskpertype[_tasktype]) do
        _task = _task -- Ops.PlayerTask#PLAYERTASK
        self:T("**** Building for Task: ".._task.Target:GetName())
        if _task.InMenu then
          self:T("**** Task already in Menu ".._task.Target:GetName())
        else
          local menutaskno = self.gettext:GetEntry("MENUTASKNO",self.locale)
          --local text = string.format("%s %03d [%d%s",menutaskno,_task.PlayerTaskNr,pilotcount,newtext)
          local text = string.format("%s %03d",menutaskno,_task.PlayerTaskNr)
          if self.UseGroupNames then
            local name = _task.Target:GetName()
            if name ~= "Unknown" then
              --text = string.format("%s (%03d) [%d%s",name,_task.PlayerTaskNr,pilotcount,newtext)
              text = string.format("%s (%03d)",name,_task.PlayerTaskNr)
            end
          end
          local parenttable, number = controller:FindEntriesByText(_tasktype,JoinMenu)
          if number > 0 then
            local Parent = parenttable[1]
            local matches, count = controller:FindEntriesByParent(Parent)
            self:T("***** Join Menu ".._tasktype.. " # of entries: "..count)
            if count < self.menuitemlimit then
              local taskentry = controller:NewEntry(text,Parent,self._JoinTask,self,_task,"false")
              controller:AddEntry(taskentry)
              _task.InMenu = true
              if not _task.UUIDS then _task.UUIDS = {} end
              table.insert(_task.UUIDS,taskentry.UUID)
            end
          end
          if self.JoinInfoMenu then
            local parenttable, number = controller:FindEntriesByText(_tasktype,self.JoinInfoMenu)
            if number > 0 then
              local Parent = parenttable[1]
              local matches, count = controller:FindEntriesByParent(Parent)
              self:T("***** Join Info Menu ".._tasktype.. " # of entries: "..count)
              if count < self.menuitemlimit then
                local taskentry = controller:NewEntry(text,Parent,self._ActiveTaskInfo,self,_task)
                controller:AddEntry(taskentry)
                _task.InMenu = true
                if not _task.UUIDS then _task.UUIDS = {} end
                table.insert(_task.UUIDS,taskentry.UUID)
              end
            end      
          end
          if actinfomenu then
            local parenttable, number = actcontroller:FindEntriesByText(_tasktype,self.ActiveInfoMenu)
            if number > 0 then
              local Parent = parenttable[1]
              local matches, count = actcontroller:FindEntriesByParent(Parent)
              self:T("***** Active Info Menu ".._tasktype.. " # of entries: "..count)
                if count < self.menuitemlimit then
                local taskentry = actcontroller:NewEntry(text,Parent,self._ActiveTaskInfo,self,_task)
                actcontroller:AddEntry(taskentry)
                _task.InMenu = true
                if not _task.AUUIDS then _task.AUUIDS = {} end
                table.insert(_task.AUUIDS,taskentry.UUID)
              end
            end      
          end
        end
      end
    end  
  end
  return self
end

--- [Internal] _RemoveMenuEntriesForTask
-- @param #PLAYERTASKCONTROLLER self
-- @param #PLAYERTASK Task
-- @param Wrapper.Client#CLIENT Client
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_RemoveMenuEntriesForTask(Task,Client)
  self:T("_RemoveMenuEntriesForTask")
  --self:I("Task name: "..Task.Target:GetName())
  --self:I("Client: "..Client:GetPlayerName())
  if Task then
    if Task.UUIDS and self.JoinTaskMenuTemplate then
      --self:I("***** JoinTaskMenuTemplate")
      --UTILS.PrintTableToLog(Task.UUIDS)
      local controller = self.JoinTaskMenuTemplate
      for _,_uuid in pairs(Task.UUIDS) do
        local Entry = controller:FindEntryByUUID(_uuid)
        if Entry then
          controller:DeleteF10Entry(Entry,Client)
          controller:DeleteGenericEntry(Entry)
          --UTILS.PrintTableToLog(controller.menutree)
        end
      end
    end

    if Task.AUUIDS and self.ActiveTaskMenuTemplate then
      --self:I("***** ActiveTaskMenuTemplate")
      --UTILS.PrintTableToLog(Task.AUUIDS)
      for _,_uuid in pairs(Task.AUUIDS) do
        local controller = self.ActiveTaskMenuTemplate
        local Entry = controller:FindEntryByUUID(_uuid)
        if Entry then
          controller:DeleteF10Entry(Entry,Client)
          controller:DeleteGenericEntry(Entry)
          --UTILS.PrintTableToLog(controller.menutree)
        end
      end
    end
    
    Task.UUIDS = nil
    Task.AUUIDS = nil
  end
  return self
end

--- [Internal] _CreateJoinMenuTemplate
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_CreateJoinMenuTemplate()
  self:T("_CreateActiveTaskMenuTemplate")
  
  local menujoin = self.gettext:GetEntry("MENUJOIN",self.locale)
  local menunotasks = self.gettext:GetEntry("MENUNOTASKS",self.locale)  
  local flashtext = self.gettext:GetEntry("FLASHMENU",self.locale)
 
  local JoinTaskMenuTemplate = CLIENTMENUMANAGER:New(self.ClientSet,"JoinTask")
  
  if not self.JoinTopMenu then
   local taskings = self.gettext:GetEntry("MENUTASKING",self.locale)
   local longname = self.Name..taskings..self.Type
   local menuname = self.MenuName or longname
   self.JoinTopMenu = JoinTaskMenuTemplate:NewEntry(menuname,self.MenuParent)
  end
  
  if self.AllowFlash then
    JoinTaskMenuTemplate:NewEntry(flashtext,self.JoinTopMenu,self._SwitchFlashing,self)
  end
  
  self.JoinMenu = JoinTaskMenuTemplate:NewEntry(menujoin,self.JoinTopMenu)
  
  if self.taskinfomenu then
    local menutaskinfo = self.gettext:GetEntry("MENUTASKINFO",self.locale)
    self.JoinInfoMenu = JoinTaskMenuTemplate:NewEntry(menutaskinfo,self.JoinTopMenu)
  end
  
  if self.TaskQueue:Count() == 0 and self.MenuNoTask == nil then
    self.MenuNoTask = JoinTaskMenuTemplate:NewEntry(menunotasks,self.JoinMenu)
  end
  
  if self.TaskQueue:Count() > 0 and self.MenuNoTask ~= nil then
    JoinTaskMenuTemplate:DeleteGenericEntry(self.MenuNoTask)
    self.MenuNoTask = nil
  end
  
  if self.InformationMenu then
    local radioinfo = self.gettext:GetEntry("RADIOS",self.locale)
    JoinTaskMenuTemplate:NewEntry(radioinfo,self.JoinTopMenu,self._ShowRadioInfo,self)
  end
  
  self.JoinTaskMenuTemplate = JoinTaskMenuTemplate
  
  return self
end

--- [Internal] _CreateActiveTaskMenuTemplate
-- @param #PLAYERTASKCONTROLLER self
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_CreateActiveTaskMenuTemplate()
  self:T("_CreateActiveTaskMenuTemplate")
  
  local menuactive = self.gettext:GetEntry("MENUACTIVE",self.locale)
  local menuinfo = self.gettext:GetEntry("MENUINFO",self.locale)
  local menumark = self.gettext:GetEntry("MENUMARK",self.locale)
  local menusmoke = self.gettext:GetEntry("MENUSMOKE",self.locale)
  local menuflare = self.gettext:GetEntry("MENUFLARE",self.locale)
  local menuillu = self.gettext:GetEntry("MENUILLU",self.locale)
  local menuabort = self.gettext:GetEntry("MENUABORT",self.locale)
  
  local ActiveTaskMenuTemplate = CLIENTMENUMANAGER:New(self.ActiveClientSet,"ActiveTask")
  
  if not self.ActiveTopMenu then
   local taskings = self.gettext:GetEntry("MENUTASKING",self.locale)
   local longname = self.Name..taskings..self.Type
   local menuname = self.MenuName or longname
   self.ActiveTopMenu = ActiveTaskMenuTemplate:NewEntry(menuname,self.MenuParent)
  end
  
  if self.AllowFlash then
    local flashtext = self.gettext:GetEntry("FLASHMENU",self.locale)
    ActiveTaskMenuTemplate:NewEntry(flashtext,self.ActiveTopMenu,self._SwitchFlashing,self)
  end
  
  local active = ActiveTaskMenuTemplate:NewEntry(menuactive,self.ActiveTopMenu)
  ActiveTaskMenuTemplate:NewEntry(menuinfo,active,self._ActiveTaskInfo,self,"NONE")
  ActiveTaskMenuTemplate:NewEntry(menumark,active,self._MarkTask,self)
  
  if self.Type ~= PLAYERTASKCONTROLLER.Type.A2A and self.noflaresmokemenu ~= true then
    ActiveTaskMenuTemplate:NewEntry(menusmoke,active,self._SmokeTask,self)
    ActiveTaskMenuTemplate:NewEntry(menuflare,active,self._FlareTask,self)
    
    if self.illumenu then
      ActiveTaskMenuTemplate:NewEntry(menuillu,active,self._IlluminateTask,self)
    end
    
  end
  
  ActiveTaskMenuTemplate:NewEntry(menuabort,active,self._AbortTask,self)
  self.ActiveTaskMenuTemplate = ActiveTaskMenuTemplate
  
  if self.taskinfomenu and self.activehasinfomenu then
    local menutaskinfo = self.gettext:GetEntry("MENUTASKINFO",self.locale)
    self.ActiveInfoMenu = ActiveTaskMenuTemplate:NewEntry(menutaskinfo,self.ActiveTopMenu)
  end
  
  return self
end

--- [Internal] _SwitchMenuForClient
-- @param #PLAYERTASKCONTROLLER self
-- @param Wrapper.Client#CLIENT Client The client
-- @param #string MenuType
-- @param #number Delay
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_SwitchMenuForClient(Client,MenuType,Delay)
  self:T(self.lid.."_SwitchMenuForClient")
  if Delay then
    self:ScheduleOnce(Delay,self._SwitchMenuForClient,self,Client,MenuType)
    return self
  end
  if MenuType == "Info" then
    self.ClientSet:AddClientsByName(Client:GetName())
    self.ActiveClientSet:Remove(Client:GetName(),true)
    self.ActiveTaskMenuTemplate:ResetMenu(Client)
    self.JoinTaskMenuTemplate:ResetMenu(Client)
    self.JoinTaskMenuTemplate:Propagate(Client)
  elseif MenuType == "Active" then
    self.ActiveClientSet:AddClientsByName(Client:GetName())
    self.ClientSet:Remove(Client:GetName(),true)
    self.ActiveTaskMenuTemplate:ResetMenu(Client)
    self.JoinTaskMenuTemplate:ResetMenu(Client)
    self.ActiveTaskMenuTemplate:Propagate(Client)
  else
    self:E(self.lid .."Unknown menu type in _SwitchMenuForClient:"..tostring(MenuType))
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
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add agent SET_GROUP to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Set#SET_GROUP RecceSet SET_GROUP of agents.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddAgentSet(RecceSet)
  self:T(self.lid.."AddAgentSet")
  if self.Intel then
    local Set = RecceSet:GetAliveSet()
    for _,_Recce in pairs(Set) do
      self.Intel:AddAgent(_Recce)
    end
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Set up detection of STATIC objects. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param #boolean OnOff Set to `true`for on and `false`for off.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SwitchDetectStatics(OnOff)
  self:T(self.lid.."SwitchDetectStatics")
  if self.Intel then
    self.Intel:SetDetectStatics(OnOff)
  else
    self:E(self.lid.."***** NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add an accept zone to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE AcceptZone Add a zone to the accept zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddAcceptZone(AcceptZone)
  self:T(self.lid.."AddAcceptZone")
  if self.Intel then
    self.Intel:AddAcceptZone(AcceptZone)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add an accept SET_ZONE to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Set#SET_ZONE AcceptZoneSet Add a SET_ZONE to the accept zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddAcceptZoneSet(AcceptZoneSet)
  self:T(self.lid.."AddAcceptZoneSet")
  if self.Intel then
    self.Intel.acceptzoneset:AddSet(AcceptZoneSet)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add a reject zone to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE RejectZone Add a zone to the reject zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddRejectZone(RejectZone)
  self:T(self.lid.."AddRejectZone")
  if self.Intel then
    self.Intel:AddRejectZone(RejectZone)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add a reject SET_ZONE to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Set#SET_ZONE  RejectZoneSet Add a zone to the reject zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddRejectZoneSet(RejectZoneSet)
  self:T(self.lid.."AddRejectZoneSet")
  if self.Intel then
    self.Intel.rejectzoneset:AddSet(RejectZoneSet)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add a conflict zone to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE ConflictZone Add a zone to the conflict zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddConflictZone(ConflictZone)
  self:T(self.lid.."AddConflictZone")
  if self.Intel then
    self.Intel:AddConflictZone(ConflictZone)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add a conflict SET_ZONE to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Set#SET_ZONE ConflictZoneSet Add a zone to the conflict zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddConflictZoneSet(ConflictZoneSet)
  self:T(self.lid.."AddConflictZoneSet")
  if self.Intel then
    self.Intel.conflictzoneset:AddSet(ConflictZoneSet)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Remove an accept zone from INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE AcceptZone Remove this zone from the accept zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:RemoveAcceptZone(AcceptZone)
  self:T(self.lid.."RemoveAcceptZone")
  if self.Intel then
    self.Intel:RemoveAcceptZone(AcceptZone)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Remove a reject zone from INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE RejectZone Remove this zone from the reject zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:RemoveRejectZone(RejectZone)
  self:T(self.lid.."RemoveRejectZone")
  if self.Intel then
    self.Intel:RemoveRejectZone(RejectZone)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Remove a conflict zone from INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE ConflictZone Remove this zone from the conflict zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:RemoveConflictZone(ConflictZone)
  self:T(self.lid.."RemoveConflictZone")
  if self.Intel then
    self.Intel:RemoveConflictZone(ConflictZone)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add an corridor zone to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE CorridorZone Add a zone to the corridor zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddCorridorZone(CorridorZone)
  self:T(self.lid.."AddCorridorZone")
  if self.Intel then
    self.Intel:AddCorridorZone(CorridorZone)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Add an corridor SET_ZONE to INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Set#SET_ZONE CorridorZoneSet Add a SET_ZONE to the corridor zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:AddCorridorZoneSet(CorridorZoneSet)
  self:T(self.lid.."AddCorridorZoneSet")
  if self.Intel then
    self.Intel.corridorzoneset:AddSet(CorridorZoneSet)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- [User] Remove an corridor zone from INTEL detection. You need to set up detection with @{#PLAYERTASKCONTROLLER.SetupIntel}() **before** using this.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Zone#ZONE CorridorZone Remove this zone from the corridor zone set.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:RemoveCorridorZone(CorridorZone)
  self:T(self.lid.."RemoveCorridorZone")
  if self.Intel then
    self.Intel:RemoveCorridorZone(CorridorZone)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- Function to set corridor zone floor and ceiling in FEET.
-- @param #PLAYERTASKCONTROLLER self
-- @param #number Floor Floor altitude ASL in feet.
-- @param #number Ceiling Ceiling altitude ASL in feet.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetCorridorZoneFloorAndCeiling(Floor,Ceiling)
  if self.Intel then
    self.Intel:SetCorridorLimitsFeet(Floor,Ceiling)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
  end
  return self
end

--- Function to set corridor zone floor and ceiling in METERS.
-- @param #PLAYERTASKCONTROLLER self
-- @param #number Floor Floor altitude ASL in meters.
-- @param #number Ceiling Ceiling altitude ASL in meters.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetCorridorZoneFloorAndCeilingMeters(Floor,Ceiling)
  if self.Intel then
    self.Intel:SetCorridorLimits(Floor,Ceiling)
  else
    self:E(self.lid.."*****NO detection has been set up (yet)!")
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

--- [User] Set the top menu to be a sub-menu of another MENU entry.
-- @param #PLAYERTASKCONTROLLER self
-- @param Core.Menu#MENU_MISSION Menu
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetParentMenu(Menu)
 self:T(self.lid.."SetParentMenu")
 --self.MenuParent = Menu
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
    local cluster = Cluster -- Ops.Intel#INTEL.Cluster
    local type = cluster.ctype
    self:T({type,self.Type})
    if (type == INTEL.Ctype.AIRCRAFT and self.Type == PLAYERTASKCONTROLLER.Type.A2A) or (type == INTEL.Ctype.NAVAL and (self.Type == PLAYERTASKCONTROLLER.Type.A2S or self.Type == PLAYERTASKCONTROLLER.Type.A2GS)) then
      self:T("A2A or A2S")
      local contacts = cluster.Contacts -- #table of GROUP
      local targetset = SET_GROUP:New()
      for _,_object in pairs(contacts) do
        local contact = _object -- Ops.Intel#INTEL.Contact
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
          local contact = _object -- Ops.Intel#INTEL.Contact
          self:T("Adding group: "..contact.groupname)
          targetset:AddGroup(contact.group,true)
        end
      elseif type == INTEL.Ctype.STRUCTURE then
        targetset = SET_STATIC:New()
        for _,_object in pairs(contacts) do
          local contact = _object -- Ops.Intel#INTEL.Contact
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
    local contact = Contact -- Ops.Intel#INTEL.Contact
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

--- [User] Set SRS TTS details - see @{Sound.SRS} for details.`SetSRS()` will try to use as many attributes configured with @{Sound.SRS#MSRS.LoadConfigFile}() as possible.
-- @param #PLAYERTASKCONTROLLER self
-- @param #number Frequency Frequency to be used. Can also be given as a table of multiple frequencies, e.g. 271 or {127,251}. There needs to be exactly the same number of modulations!
-- @param #number Modulation Modulation to be used. Can also be given as a table of multiple modulations, e.g. radio.modulation.AM or {radio.modulation.FM,radio.modulation.AM}. There needs to be exactly the same number of frequencies!
-- @param #string PathToSRS Defaults to "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio"
-- @param #string Gender (Optional) Defaults to "male"
-- @param #string Culture (Optional) Defaults to "en-US"
-- @param #number Port (Optional) Defaults to 5002
-- @param #string Voice (Optional) Use a specifc voice with the @{Sound.SRS#SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system. Can also be Google voice types, if you are using Google TTS.
-- @param #number Volume (Optional) Volume - between 0.0 (silent) and 1.0 (loudest)
-- @param #string PathToGoogleKey (Optional) Path to your google key if you want to use google TTS; if you use a config file for MSRS, hand in nil here.
-- @param #string AccessKey (Optional) Your Google API access key. This is necessary if DCS-gRPC is used as backend; if you use a config file for MSRS, hand in nil here.
-- @param Core.Point#COORDINATE Coordinate Coordinate from which the controller radio is sending
-- @param #string Backend (Optional) MSRS Backend to be used, can be MSRS.Backend.SRSEXE or MSRS.Backend.GRPC; if you use a config file for MSRS, hand in nil here.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:SetSRS(Frequency,Modulation,PathToSRS,Gender,Culture,Port,Voice,Volume,PathToGoogleKey,AccessKey,Coordinate,Backend)
  self:T(self.lid.."SetSRS")
  self.PathToSRS = PathToSRS or MSRS.path or "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio" --
  self.Gender = Gender or MSRS.gender or "male" --
  self.Culture = Culture or MSRS.culture or "en-US" --
  self.Port = Port or MSRS.port or 5002 --
  self.Voice = Voice or MSRS.voice
  self.PathToGoogleKey = PathToGoogleKey --
  self.AccessKey = AccessKey
  self.Volume = Volume or 1.0 --
  self.UseSRS = true
  self.Frequency = Frequency or {127,251} --
  self.BCFrequency = self.Frequency
  self.Modulation = Modulation or {radio.modulation.FM,radio.modulation.AM} --
  self.BCModulation = self.Modulation
  -- set up SRS 
  self.SRS=MSRS:New(self.PathToSRS,self.Frequency,self.Modulation,Backend)
  self.SRS:SetCoalition(self.Coalition)
  self.SRS:SetLabel(self.MenuName or self.Name)
  self.SRS:SetGender(self.Gender)
  self.SRS:SetCulture(self.Culture)
  self.SRS:SetPort(self.Port)
  self.SRS:SetVolume(self.Volume)
  if self.PathToGoogleKey then
    --self.SRS:SetGoogle(self.PathToGoogleKey)
    self.SRS:SetProviderOptionsGoogle(self.PathToGoogleKey,self.AccessKey)
    self.SRS:SetProvider(MSRS.Provider.GOOGLE)
  end
   -- Pre-configured Google?
  if (not PathToGoogleKey) and self.SRS:GetProvider() == MSRS.Provider.GOOGLE then
    self.PathToGoogleKey = MSRS.poptions.gcloud.credentials
    self.Voice = Voice or MSRS.poptions.gcloud.voice
    self.AccessKey = AccessKey or MSRS.poptions.gcloud.key
  end
  if Coordinate then
    self.SRS:SetCoordinate(Coordinate)
  end
  self.SRS:SetVoice(self.Voice)
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


---
-- @param #PLAYERTASKCONTROLLER self
-- @param Ops.PlayerTask#PLASERTASK Task
-- @param #number TargetsLeft
function PLAYERTASKCONTROLLER:_UpdateTargetsAlive(Task,TargetsLeft)
  self:T(self.lid.."_UpdateTargetsAlive")
  local delta = Task.Target:CountTargets() - TargetsLeft
  if delta > 0 then
    self:T("Delta targets to be removed: "..delta)
    local count = 0
    local targets = Task.Target:GetObjects()
    for _,_object in pairs(targets or {}) do
      if _object and _object.ClassName and (_object:IsInstanceOf("GROUP") or _object:IsInstanceOf("UNIT") or _object:IsInstanceOf("STATIC") or _object:IsInstanceOf("SCENERY")) then
        if count < delta then
          count = count + 1
          if not _object:IsInstanceOf("SCENERY") then
            _object:Destroy(true)
          else
            _object:Explode(self.SceneryExplosivesAmount)
          end
        end
      end
    end
  end
  return self
end

---
-- @param #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_LoadTasksPersisted()
  self:T(self.lid.."_LoadTasksPersisted")
  
  local function MatchTask(Type,Name)
    local foundtask
    self.TaskQueue:ForEach(
      function(_task)
        local task = _task -- #PLAYERTASK
        if task.Type == Type and task.Target.name and task.Target.name  == Name then
          foundtask = task
        end
      end
    )
    return foundtask
  end
  
  if lfs and io then
    local ok,data = UTILS.LoadFromFile(self.TaskPersistancePath,self.TaskPersistanceFilename)
    if ok == true then
      table.remove(data, 1)
      for _,_entry in pairs(data) do
        -- "--ID;;Name;;InitialTargets;;Targetsleft;;Type\n"
        local dataset = UTILS.Split(_entry,";;")
        local Taskdata = {} -- #PersistenceData
        Taskdata.ID = tonumber(dataset[1])
        Taskdata.Name = tostring(dataset[2])
        Taskdata.InitialTargets = tonumber(dataset[3])
        Taskdata.Targetsleft = tonumber(dataset[4])
        Taskdata.Type = tostring(dataset[5])
        Taskdata.Task = MatchTask(Taskdata.Type,Taskdata.Name)
        if Taskdata.Task == nil then
          self:E(self.lid.."No actual task found for "..Taskdata.Name)
        else
          self:T(self.lid.."Task loaded and match found for "..Taskdata.Name)
        end
        Taskdata.updated = Taskdata.InitialTargets == Taskdata.Targetsleft and true or false
        if Taskdata.Task and Taskdata.updated == false then
          self:_UpdateTargetsAlive(Taskdata.Task,Taskdata.Targetsleft)
          Taskdata.updated = true
        end
        self.TaskPersistance[Taskdata.ID] = Taskdata
      end
    end
  end
  return self
end

--- [User] Clear persisted data on disk.
-- @param #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:ClearPersistedData()
  if lfs and io then
    local text = "-- Data Cleared\n"
    UTILS.SaveToFile(self.TaskPersistancePath,self.TaskPersistanceFilename,text)
  end
  return self
end

---
-- @param #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:_SaveTasksPersisted()
  if lfs and io then
    local text = "--ID;;Name;;InitialTargets;;Targetsleft;;Type\n"
    for _,_data in pairs(self.TaskPersistance) do
      local data = _data -- #PersistenceData
      data.Targetsleft = data.Task.Target:CountTargets() -- recount
      if data.Task and data.Task:IsDone() then data.Targetsleft = 0 end
      local tasktext = string.format("%d;;%s;;%d;;%d;;%s\n",data.ID,data.Name,data.InitialTargets,data.Targetsleft,data.Type)
      text = text..tasktext
    end
    UTILS.SaveToFile(self.TaskPersistancePath,self.TaskPersistanceFilename,text)
  end
  return self
end

---
-- @param #PLAYERTASKCONTROLLER self
-- @param #PLAYERTASK Task
function PLAYERTASKCONTROLLER:_AddPersistenceData(Task)
  local Taskdata = {} -- #PersistenceData
  if not self.TaskPersistance[Task.PlayerTaskNr] then
    Taskdata.ID = Task.PlayerTaskNr
    Taskdata.Name = Task.Target.name or "none"
    Taskdata.InitialTargets = Task.Target:CountTargets()
    Taskdata.Targetsleft = Taskdata.InitialTargets
    Taskdata.Type = Task.Type
    Taskdata.updated = true
    Taskdata.Task = Task
    self.TaskPersistance[Task.PlayerTaskNr] = Taskdata
  end
  return self
end

-------------------------------------------------------------------------------------------------------------------
-- FSM Functions PLAYERTASKCONTROLLER
-- TODO: FSM Functions PLAYERTASKCONTROLLER
-------------------------------------------------------------------------------------------------------------------

--- [Internal] On after start call
-- @param #PLAYERTASKCONTROLLER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterStart(From, Event, To)
  self:T({From, Event, To})
  self:T(self.lid.."onafterStart")
  self:_CreateJoinMenuTemplate()
  self:_CreateActiveTaskMenuTemplate()
  -- Player Events
  self:HandleEvent(EVENTS.PlayerLeaveUnit, self._EventHandler)
  self:HandleEvent(EVENTS.Ejection, self._EventHandler)
  self:HandleEvent(EVENTS.Crash, self._EventHandler)
  self:HandleEvent(EVENTS.PilotDead, self._EventHandler)
  self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
  self:HandleEvent(EVENTS.UnitLost, self._EventHandler)
  self:SetEventPriority(5)   
  -- Persistence
  if self.TaskPersistanceSwitch == true then
    self:ScheduleOnce(5,self._LoadTasksPersisted,self)
    --self:_LoadTasksPersisted()
  end       
  return self
end

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
    if taskcount < self.menuitemlimit then
      enforcedmenu = true
    end
  end
  
  self:_UpdateJoinMenuTemplate()
  
  if self.verbose then
    local text = string.format("%s | New Targets: %02d | Active Tasks: %02d | Active Players: %02d | Assigned Tasks: %02d",self.MenuName, targetcount,taskcount,playercount,assignedtasks)
    self:I(text)
  end
  
    -- Persistence
  if self.TaskPersistanceSwitch == true then
    self:_SaveTasksPersisted()
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
-- @param #boolean Silent If true, suppress message output on cancel.
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterTaskCancelled(From, Event, To, Task, Silent)
  self:T({From, Event, To})
  self:T(self.lid.."TaskCancelled")
  if Silent ~= true then
    local canceltxt = self.gettext:GetEntry("TASKCANCELLED",self.locale)
    local canceltxttts = self.gettext:GetEntry("TASKCANCELLEDTTS",self.locale)
    local taskname = string.format(canceltxt, Task.PlayerTaskNr, tostring(Task.Type))

    if self.NoScreenOutput ~= true then
      self:_SendMessageToClients(taskname,15)
      --local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
    end
    
    if self.UseSRS then
      taskname = string.format(canceltxttts, self.MenuName or self.Name, Task.PlayerTaskNr, tostring(Task.TTSType))
      self.SRSQueue:NewTransmission(taskname,nil,self.SRS,nil,2)
    end
    
  end
  local clients=Task:GetClientObjects()
  for _,client in pairs(clients) do
    self:_RemoveMenuEntriesForTask(Task,client)
    --self:_SwitchMenuForClient(client,"Info")
  end
  for _,client in pairs(clients) do
    --self:_RemoveMenuEntriesForTask(Task,client)
    self:_SwitchMenuForClient(client,"Info",5)
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
    self:_RemoveMenuEntriesForTask(Task,client)
    --self:_SwitchMenuForClient(client,"Info")
  end
  for _,client in pairs(clients) do
   -- self:_RemoveMenuEntriesForTask(Task,client)
    self:_SwitchMenuForClient(client,"Info",5)
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
  local clients=Task:GetClientObjects()
  for _,client in pairs(clients) do
    self:_RemoveMenuEntriesForTask(Task,client)
    --self:_SwitchMenuForClient(client,"Info")
  end
  for _,client in pairs(clients) do
   -- self:_RemoveMenuEntriesForTask(Task,client)
    self:_SwitchMenuForClient(client,"Info",5)
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
-- @param #boolean Silent
-- @return #PLAYERTASKCONTROLLER self
function PLAYERTASKCONTROLLER:onafterTaskAdded(From, Event, To, Task, Silent)
  self:T({From, Event, To})
  self:T(self.lid.."TaskAdded")
  local addtxt = self.gettext:GetEntry("TASKADDED",self.locale)
  local taskname = string.format(addtxt, self.MenuName or self.Name, tostring(Task.Type))
  if not Silent then
    if not self.NoScreenOutput then
      self:_SendMessageToClients(taskname,15)
      --local m = MESSAGE:New(taskname,15,"Tasking"):ToCoalition(self.Coalition)
    end
    if self.UseSRS then
      taskname = string.format(addtxt, self.MenuName or self.Name, tostring(Task.TTSType))
      self.SRSQueue:NewTransmission(taskname,nil,self.SRS,nil,2)
    end
  end
  self:T(self.lid..string.format("Pers = %s | Type = %s | TypePers = %s | TaskFlag = %s",tostring(self.TaskPersistanceSwitch),tostring(Task.Type),tostring(self.TasksPersistable[Task.Type]),tostring(Task.PersistMe)))
  if self.TaskPersistanceSwitch == true and self.TasksPersistable[Task.Type] == true and Task.PersistMe == true then
    self:_AddPersistenceData(Task)
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
