--- The TASK Classes define major end-to-end activities within a MISSION. The TASK Class is the Master Class to orchestrate these activities. From this class, many concrete TASK classes are inherited.
-- @module TASK

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Stage" )

--- The TASK class
-- @type TASK
-- @extends Base#BASE
TASK = {

	-- Defines the different signal types with a Task.
	SIGNAL = {
		COLOR = { 
			RED = { ID = 1, COLOR = trigger.smokeColor.Red, TEXT = "A red" },
			GREEN = { ID = 2, COLOR = trigger.smokeColor.Green, TEXT = "A green" }, 
			BLUE = { ID = 3, COLOR = trigger.smokeColor.Blue, TEXT = "A blue" },
			WHITE = { ID = 4, COLOR = trigger.smokeColor.White, TEXT = "A white" }, 
			ORANGE = { ID = 5, COLOR = trigger.smokeColor.Orange, TEXT = "An orange" } 
		},
		TYPE = {
			SMOKE = { ID = 1, TEXT = "smoke" },
			FLARE = { ID = 2, TEXT = "flare" }
		}
	},
	ClassName = "TASK",
	Mission = {}, -- Owning mission of the Task
	Name = '',
	Stages = {},
	Stage = {},
	Cargos = {
		InitCargos = {},
		LoadCargos = {}
	},
	LandingZones = {
		LandingZoneNames = {},
		LandingZones = {}
	},
	ActiveStage = 0,
	TaskDone = false,
	TaskFailed = false,
	GoalTasks = {}
}

--- Instantiates a new TASK Base. Should never be used. Interface Class.
-- @return TASK
function TASK:New()
  local self = BASE:Inherit( self, BASE:New() )
	self:F()
  
  -- assign Task default values during construction
  self.TaskBriefing = "Task: No Task."
  self.Time = timer.getTime()
  self.ExecuteStage = _TransportExecuteStage.NONE

  return self
end

function TASK:SetStage( StageSequenceIncrement )
	self:F( { StageSequenceIncrement } )

	local Valid = false
	if StageSequenceIncrement ~= 0 then
		self.ActiveStage = self.ActiveStage + StageSequenceIncrement
		if 1 <= self.ActiveStage and self.ActiveStage <= #self.Stages then
			self.Stage = self.Stages[self.ActiveStage]
			self:T( { self.Stage.Name } )
			self.Frequency = self.Stage.Frequency
			Valid = true
		else
			Valid = false
			env.info( "TASK:SetStage() self.ActiveStage is smaller or larger than self.Stages array. self.ActiveStage = " .. self.ActiveStage )
		end
	end
	self.Time = timer.getTime()
	return Valid
end

function TASK:Init()
	self:F()
	self.ActiveStage = 0
	self:SetStage(1)
	self.TaskDone = false
	self.TaskFailed = false
end


--- Get progress of a TASK.
-- @return string GoalsText
function TASK:GetGoalProgress()
	self:F()

	local GoalsText = ""
	for GoalVerb, GoalVerbData in pairs( self.GoalTasks ) do
		local Goals = self:GetGoalCompletion( GoalVerb )
		if Goals and Goals ~= "" then 
			Goals = '(' .. Goals .. ')' 
		else
			Goals = '( - )'
		end
		GoalsText = GoalsText .. GoalVerb .. ': ' .. self:GetGoalCount(GoalVerb) .. ' goals ' .. Goals .. ' of ' .. self:GetGoalTotal(GoalVerb) .. ' goals completed (' .. self:GetGoalPercentage(GoalVerb) .. '%); '
	end
	
	if GoalsText == "" then
		GoalsText = "( - )"
	end
	
	return GoalsText
end

--- Show progress of a TASK.
-- @param MISSION 	Mission 		Group structure describing the Mission.
-- @param CLIENT	Client	 		Group structure describing the Client.
function TASK:ShowGoalProgress( Mission, Client )
	self:F()

	local GoalsText = ""
	for GoalVerb, GoalVerbData in pairs( self.GoalTasks ) do
		if Mission:IsCompleted() then
		else
			local Goals = self:GetGoalCompletion( GoalVerb )
			if Goals and Goals ~= "" then 
			else
				Goals = "-"
			end
			GoalsText = GoalsText .. self:GetGoalProgress()
		end
	end
	
	if Mission.MissionReportFlash or Mission.MissionReportShow then
		Client:Message( GoalsText, 10,  "/TASKPROGRESS" .. self.ClassName, "Mission Command: Task Status", 30 )
	end
end

--- Sets a TASK to status Done.
function TASK:Done()
	self:F()
	self.TaskDone = true
end

--- Returns if a TASK is done.
-- @return bool
function TASK:IsDone()
	self:F( self.TaskDone )
	return self.TaskDone
end

--- Sets a TASK to status failed.
function TASK:Failed()
	self:F()
	self.TaskFailed = true
end

--- Returns if a TASk has failed.
-- @return bool
function TASK:IsFailed()
	self:F( self.TaskFailed )
	return self.TaskFailed
end

function TASK:Reset( Mission, Client )
	self:F()
	self.ExecuteStage = _TransportExecuteStage.NONE
end

--- Returns the Goals of a TASK
-- @return @table Goals
function TASK:GetGoals()
	return self.GoalTasks
end

--- Returns if a TASK has Goal(s).
-- @param ?string GoalVerb is the name of the Goal of the TASK.
-- @return bool
function TASK:Goal( GoalVerb )
	self:F()
	if not GoalVerb then
		GoalVerb = self.GoalVerb
	end
	if self.GoalTasks[GoalVerb] and self.GoalTasks[GoalVerb].GoalTotal > 0 then
		return true
	else
		return false
	end
end

--- Sets the total Goals to be achieved of the Goal Name
-- @param number GoalTotal is the number of times the GoalVerb needs to be achieved.
-- @param ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
function TASK:SetGoalTotal( GoalTotal, GoalVerb )
	self:F( { GoalTotal, GoalVerb } )
	
	if not GoalVerb then
		GoalVerb = self.GoalVerb
	end
	self.GoalTasks[GoalVerb] = {}
	self.GoalTasks[GoalVerb].Goals = {}
	self.GoalTasks[GoalVerb].GoalTotal = GoalTotal
	self.GoalTasks[GoalVerb].GoalCount = 0
	return self
end

--- Gets the total of Goals to be achieved within the TASK of the GoalVerb.
-- @param ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
function TASK:GetGoalTotal( GoalVerb )
	self:F()
	if not GoalVerb then
		GoalVerb = self.GoalVerb
	end
	if self:Goal( GoalVerb ) then
		return self.GoalTasks[GoalVerb].GoalTotal
	else
		return 0
	end
end

--- Sets the total of Goals currently achieved within the TASK of the GoalVerb.
-- @param number GoalCount is the total number of Goals achieved within the TASK.
-- @param ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
-- @return TASK
function TASK:SetGoalCount( GoalCount, GoalVerb )
	self:F()
	if not GoalVerb then
		GoalVerb = self.GoalVerb
	end
	if self:Goal( GoalVerb) then
		self.GoalTasks[GoalVerb].GoalCount = GoalCount
	end
	return self
end

--- Increments the total of Goals currently achieved within the TASK of the GoalVerb, with the given GoalCountIncrease.
-- @param number GoalCountIncrease is the number of new Goals achieved within the TASK.
-- @param ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
-- @return TASK
function TASK:IncreaseGoalCount( GoalCountIncrease, GoalVerb )
	self:F()
	if not GoalVerb then
		GoalVerb = self.GoalVerb
	end
	if self:Goal( GoalVerb) then
		self.GoalTasks[GoalVerb].GoalCount = self.GoalTasks[GoalVerb].GoalCount + GoalCountIncrease
	end
	return self
end

--- Gets the total of Goals currently achieved within the TASK of the GoalVerb.
-- @param ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
-- @return TASK
function TASK:GetGoalCount( GoalVerb )
	self:F()
	if not GoalVerb then
		GoalVerb = self.GoalVerb
	end
	if self:Goal( GoalVerb ) then
		return self.GoalTasks[GoalVerb].GoalCount
	else
		return 0
	end
end

--- Gets the percentage of Goals currently achieved within the TASK of the GoalVerb.
-- @param ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
-- @return TASK
function TASK:GetGoalPercentage( GoalVerb )
	self:F()
	if not GoalVerb then
		GoalVerb = self.GoalVerb
	end
	if self:Goal( GoalVerb ) then
		return math.floor( self:GetGoalCount( GoalVerb ) / self:GetGoalTotal( GoalVerb ) * 100 + .5 )
	else
		return 100
	end
end

--- Returns if all the Goals of the TASK were achieved.
-- @return bool
function TASK:IsGoalReached( )

	local GoalReached = true

	for GoalVerb, Goals in pairs( self.GoalTasks ) do
		self:T( { "GoalVerb", GoalVerb } )
		if self:Goal( GoalVerb ) then
			local GoalToDo = self:GetGoalTotal( GoalVerb ) - self:GetGoalCount( GoalVerb )
			self:T( "GoalToDo = " .. GoalToDo )
			if GoalToDo <= 0 then
			else
				GoalReached = false
				break
			end
		else
			break
		end
	end
	
	self:T( GoalReached )
	return GoalReached
end

--- Adds an Additional Goal for the TASK to be achieved.
-- @param string GoalVerb is the name of the Goal of the TASK.
-- @param string GoalTask is a text describing the Goal of the TASK to be achieved.
-- @param number GoalIncrease is a number by which the Goal achievement is increasing.
function TASK:AddGoalCompletion( GoalVerb, GoalTask, GoalIncrease )
	self:F( { GoalVerb, GoalTask, GoalIncrease } )

	if self:Goal( GoalVerb ) then
		self.GoalTasks[GoalVerb].Goals[#self.GoalTasks[GoalVerb].Goals+1] = GoalTask
		self.GoalTasks[GoalVerb].GoalCount = self.GoalTasks[GoalVerb].GoalCount + GoalIncrease
	end
	return self
end

--- Returns if the additional Goal for the TASK was completed.
-- @param ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
-- @return string Goals
function TASK:GetGoalCompletion( GoalVerb )
	self:F( { GoalVerb } )
	
	if self:Goal( GoalVerb ) then
		local Goals = ""
		for GoalID, GoalName in pairs( self.GoalTasks[GoalVerb].Goals ) do Goals = Goals .. GoalName .. " + " end
		return Goals:gsub(" + $", ""), self.GoalTasks[GoalVerb].GoalCount
	end
end

function TASK.MenuAction( Parameter )
  Parameter.ReferenceTask.ExecuteStage = _TransportExecuteStage.EXECUTING
  Parameter.ReferenceTask.Cargo = Parameter.CargoTask
end

function TASK:StageExecute()
	self:F()

  local Execute = false

  if      self.Frequency == STAGE.FREQUENCY.REPEAT then
    Execute = true
  elseif  self.Frequency == STAGE.FREQUENCY.NONE then
    Execute = false
  elseif  self.Frequency >= 0 then
    Execute = true
    self.Frequency = self.Frequency - 1
  end
  
  return Execute

end

--- Work function to set signal events within a TASK.
function TASK:AddSignal( SignalUnitNames, SignalType, SignalColor, SignalHeight )
	self:F()
  
	local Valid = true
	
	if Valid then
		if type( SignalUnitNames ) == "table" then
			self.LandingZoneSignalUnitNames = SignalUnitNames
		else
			self.LandingZoneSignalUnitNames = { SignalUnitNames }
		end
		self.LandingZoneSignalType = SignalType
		self.LandingZoneSignalColor = SignalColor
		self.Signalled = false 
		if SignalHeight ~= nil then
			self.LandingZoneSignalHeight = SignalHeight
		else
			self.LandingZoneSignalHeight = 0 
		end
	  
		if self.TaskBriefing then 
			self.TaskBriefing = self.TaskBriefing .. " " .. SignalColor.TEXT .. " " .. SignalType.TEXT .. " will be fired when entering the landing zone."
		end
	end
	
	return Valid
end

--- When the CLIENT is approaching the landing zone, a RED SMOKE will be fired by an optional SignalUnitNames.
-- @param table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @param number SignalHeight Altitude that the Signal should be fired...
function TASK:AddSmokeRed( SignalUnitNames, SignalHeight )
	self:F()
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.SMOKE, TASK.SIGNAL.COLOR.RED, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, a GREEN SMOKE will be fired by an optional SignalUnitNames.
-- @param table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @param number SignalHeight Altitude that the Signal should be fired...
function TASK:AddSmokeGreen( SignalUnitNames, SignalHeight )
	self:F()
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.SMOKE, TASK.SIGNAL.COLOR.GREEN, SignalHeight )
end
        
--- When the CLIENT is approaching the landing zone, a BLUE SMOKE will be fired by an optional SignalUnitNames.
-- @param table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @param number SignalHeight Altitude that the Signal should be fired...
function TASK:AddSmokeBlue( SignalUnitNames, SignalHeight )
	self:F()
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.SMOKE, TASK.SIGNAL.COLOR.BLUE, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, a WHITE SMOKE will be fired by an optional SignalUnitNames.
-- @param table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @param number SignalHeight Altitude that the Signal should be fired...
function TASK:AddSmokeWhite( SignalUnitNames, SignalHeight )
	self:F()
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.SMOKE, TASK.SIGNAL.COLOR.WHITE, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, an ORANGE SMOKE will be fired by an optional SignalUnitNames.
-- @param table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @param number SignalHeight Altitude that the Signal should be fired...
function TASK:AddSmokeOrange( SignalUnitNames, SignalHeight )
	self:F()
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.SMOKE, TASK.SIGNAL.COLOR.ORANGE, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, a RED FLARE will be fired by an optional SignalUnitNames.
-- @param table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @param number SignalHeight Altitude that the Signal should be fired...
function TASK:AddFlareRed( SignalUnitNames, SignalHeight )
	self:F()
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.FLARE, TASK.SIGNAL.COLOR.RED, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, a GREEN FLARE will be fired by an optional SignalUnitNames.
-- @param table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @param number SignalHeight Altitude that the Signal should be fired...
function TASK:AddFlareGreen( SignalUnitNames, SignalHeight )
	self:F()
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.FLARE, TASK.SIGNAL.COLOR.GREEN, SignalHeight )
end
        
--- When the CLIENT is approaching the landing zone, a BLUE FLARE will be fired by an optional SignalUnitNames.
-- @param table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @param number SignalHeight Altitude that the Signal should be fired...
function TASK:AddFlareBlue( SignalUnitNames, SignalHeight )
	self:F()
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.FLARE, TASK.SIGNAL.COLOR.BLUE, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, a WHITE FLARE will be fired by an optional SignalUnitNames.
-- @param table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @param number SignalHeight Altitude that the Signal should be fired...
function TASK:AddFlareWhite( SignalUnitNames, SignalHeight )
	self:F()
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.FLARE, TASK.SIGNAL.COLOR.WHITE, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, an ORANGE FLARE will be fired by an optional SignalUnitNames.
-- @param table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @param number SignalHeight Altitude that the Signal should be fired...
function TASK:AddFlareOrange( SignalUnitNames, SignalHeight )
	self:F()
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.FLARE, TASK.SIGNAL.COLOR.ORANGE, SignalHeight )
end
