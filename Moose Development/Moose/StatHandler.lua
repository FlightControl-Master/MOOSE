--- Provides a logging of statistics in a running DCS Mission.
-- @script eStatHandler




--Handler table
local eStatHandler = {}
local _StatRunID

--Neccessary tables for string instead of integers
SETCoalition = 
{
	[1] = "red",
	[2] = "blue",
}

SETGroupCat = 
{
	[1] = "AIRPLANE",
	[2] = "HELICOPTER",
	[3] = "GROUND",
	[4] = "SHIP",
	[5] = "STRUCTURE",
}

SETWeaponCatName = 
{
   [0] = "SHELL",
   [1] = "MISSILE",
   [2] = "ROCKET",
   [3] = "BOMB",
 }
 
 wEvent = {
   "S_EVENT_SHOT",
   "S_EVENT_HIT",
   "S_EVENT_TAKEOFF",
   "S_EVENT_LAND",
   "S_EVENT_CRASH",
   "S_EVENT_EJECTION",
   "S_EVENT_REFUELING",
   "S_EVENT_DEAD",
   "S_EVENT_PILOT_DEAD",
   "S_EVENT_BASE_CAPTURED",
   "S_EVENT_MISSION_START",
   "S_EVENT_MISSION_END",
   "S_EVENT_TOOK_CONTROL",
   "S_EVENT_REFUELING_STOP",
   "S_EVENT_BIRTH",
   "S_EVENT_HUMAN_FAILURE",
   "S_EVENT_ENGINE_STARTUP",
   "S_EVENT_ENGINE_SHUTDOWN",
   "S_EVENT_PLAYER_ENTER_UNIT",
   "S_EVENT_PLAYER_LEAVE_UNIT",
   "S_EVENT_PLAYER_COMMENT",
   "S_EVENT_SHOOTING_START",
   "S_EVENT_SHOOTING_END",
   "S_EVENT_MAX",
 }
 
statEventsTable = {}


function SecondsToClock(sSeconds)
local nSeconds = sSeconds
	if nSeconds == 0 then
		--return nil;
		return "00:00:00";
	else
		nHours = string.format("%02.f", math.floor(nSeconds/3600));
		nMins = string.format("%02.f", math.floor(nSeconds/60 - (nHours*60)));
		nSecs = string.format("%02.f", math.floor(nSeconds - nHours*3600 - nMins *60));
		return nHours..":"..nMins..":"..nSecs
	end
end


function eStatHandler:onEvent(e)
    local InitID_ = ""
	local InitName = ""
    local WorldEvent = wEvent[e.id]
    local InitCoa = ""
    local InitGroupCat = ""
    local InitType = ""
    local InitPlayer = ""
    local eWeaponCat = ""
    local eWeaponName = ""
    local TargID_ = ""
	local TargName = ""
    local TargType = ""
    local TargPlayer = ""
    local TargCoa = ""
    local TargGroupCat = ""

	if e.initiator and Object.getCategory(e.initiator) == Object.Category.UNIT then
	--Initiator variables
		local InitGroup = e.initiator:getGroup()
		InitID_ = e.initiator.id_
		if e.initiator:getName() then
			InitName = e.initiator:getName()
		end
		if InitGroup:getCoalition() then
			InitCoa = SETCoalition[InitGroup:getCoalition()]
		end
		if InitGroup:getCategory() then
			InitGroupCat = SETGroupCat[InitGroup:getCategory() + 1]
		end
        InitType = e.initiator:getTypeName()
		
		--Get initiator player name or AI if NIL
		if e.initiator:getPlayerName() == nil then
			InitPlayer = "AI"
		else
			InitPlayer = e.initiator:getPlayerName()
		end
	else
		if e.initiator then
			local InitGroup = e.initiator:getGroup()
			InitID_ = e.initiator.id_
			if e.initiator:getName() then
				InitName = e.initiator:getName()
			end
			InitCoa = SETCoalition[InitGroup:getCoalition()]
			InitGroupCat = SETGroupCat[InitGroup:getCategory() + 1]
			InitType = e.initiator:getTypeName()
			
			--Get initiator player name or AI if NIL
			if e.initiator:getPlayerName() == nil then
				InitPlayer = "AI"
			else
				InitPlayer = e.initiator:getPlayerName()
			end
		end
    end

	--Weapon variables	
	if e.weapon == nil then
		eWeaponCat = ""
		eWeaponName = ""
	else
		local eWeaponDesc = e.weapon:getDesc()
		eWeaponCat = SETWeaponCatName[eWeaponDesc.category]
		eWeaponName = eWeaponDesc.displayName
	end
	
	--Target variables	
	if e.target == nil then
	    TargID_ = ""
		TargName = ""
		TargType = ""
		TargPlayer = ""
		TargCoa = ""
        TargGroupCat = ""
	elseif Object.getCategory(e.target) == Object.Category.UNIT then
	    local TargGroup = e.target:getGroup()
	    TargID_ = e.target.id_
		if e.target:getName() then
			TargName = e.target:getName()
		end
		TargType = e.target:getTypeName()
		TargCoa = SETCoalition[TargGroup:getCoalition()]
		TargGroupCat = SETGroupCat[TargGroup:getCategory() + 1]
		
		--Get target player name or AI if NIL
		if not e.target:getPlayerName() then
			TargPlayer = "AI"
		else
			TargPlayer = e.target:getPlayerName()
		end
	else
		TargType = e.target:getTypeName()
		TargID_ = ""
		TargName = ""
		TargPlayer = ""
		TargCoa = ""
        TargGroupCat = ""
	end
	
	--write events to table
	statEventsTable[#statEventsTable + 1] = 
			{
				[1] = _StatRunID,
				[2] = SecondsToClock(timer.getTime()),
				[3] = WorldEvent,
				[4] = InitID_,
				[5] = InitName,
				[6] = InitCoa,
				[7] = InitGroupCat,
				[8] = InitType,
				[9] = InitPlayer,
				[10] = eWeaponCat,
				[11] = eWeaponName,
				[12] = TargID_,
				[13] = TargName,
				[14] = TargCoa,
				[15] = TargGroupCat,
				[16] = TargType,
				[17] = TargPlayer,
			}
	env.info( 'Event: ' .. _StatRunID .. '~ ' .. SecondsToClock(timer.getTime()) .. '~ ' .. WorldEvent .. '~ ' .. InitID_ .. '~ ' .. InitName .. '~ ' .. InitCoa .. '~ ' .. InitGroupCat .. '~ ' .. InitType .. '~ ' .. InitPlayer ..
	           '~ ' .. eWeaponCat .. '~ ' .. eWeaponName .. '~ ' .. TargID_ .. '~ ' .. TargName .. '~ ' .. TargCoa .. '~ ' .. TargGroupCat .. '~ ' .. TargType .. '~ ' .. TargPlayer )
end




do 

	local StatFile,err
	

	function StatOpen()
		local fdir = lfs.writedir() .. [[Logs\]] .. "Events_" .. os.date( "%Y-%m-%d_%H-%M-%S" ) .. ".csv"
		StatFile,err = io.open(fdir,"w+")
		if not StatFile then
			local errmsg = 'Error: No Logs folder found in the User\\Saved Games\\DCS\\Logs directory...' .. 'Save_stat . sample: C:\\Users\\youname\\Saved Games\\DCS\\Logs' 
			trigger.action.outText(errmsg, 10)
			return print(err)
		end
		StatFile:write("RunID~Time~Event~Initiator ID~Initiator Name~Initiator Coalition~Initiator Group Category~Initiator Type~Initiator Player~Weapon Category~Weapon Name~Target ID~Target Name~Target Coalition~Target Group Category~Target Type~Target Player\n")
		
		_StatRunID = os.date("%y-%m-%d_%H-%M-%S")
		routines.scheduleFunction( StatSave, { }, timer.getTime() + 1, 1)
	end

	function StatSave()
		--write statistic information to file
		for Index, eDetails in ipairs(statEventsTable) do
			for eInfoName, eInfoData in ipairs(eDetails) do
					StatFile:write(eInfoData.."~")
			end
			StatFile:write("\n")
		end
		statEventsTable = {}
	end
	
	function StatClose()
		StatFile:close()
	end

end

world.addEventHandler(eStatHandler)
StatOpen()

