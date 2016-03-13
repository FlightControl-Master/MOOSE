--- Tracing functions...
-- @module trace
-- @author Flightcontrol

trace = {}
trace.names = {}
trace.classes = {}
trace.scheduledfunction = ""

trace.names.all = false
trace.names.New = false
trace.names.Inherit = false
--trace.names.ClientGroup = true
trace.names.Scheduler = false
trace.names.ToCoalition = false
trace.names.ToClient = false
trace.names.do_scheduled_functions = false
trace.names.main = false 
trace.names.Meta = false 
trace.names.mistdisplayV3 = false 
trace.names.f = false 
trace.names.Spawn = false
trace.names.SpawnTrack = false
trace.names.SpawnGroupAdd = false
trace.names.SpawnInfantry = false
trace.names.SpawnPrepare = false
trace.names.SpawnInit = false
trace.names.SpawnInitSchedule = false
trace.names.SpawnFromCarrier = false
trace.names.SpawnGroup = false
trace.names.SpawnMissionGroup = false
trace.names.SpawnScheduled = false
trace.names.SpawnInZone = false
trace.names.Spawn = false
trace.names.ShowCargo = false 
trace.names.AddCargo = false
trace.names.RemoveCargo = false 
trace.names.MenuAction = false
trace.names.DeploySA6TroopsGoal = false
trace.names.AddEvent = false
trace.names.onEvent = false
trace.names.EventShot = false
trace.names.EventDead = false
trace.names.EventFunction = false
trace.names.ShowGoalProgress = false
trace.names.ReportGoalProgress = false
trace.names.ProgressTrigger = false
trace.names.IsGoalReached = false
trace.names.Validate = false
trace.names.Execute = false
trace.names.EnableEvents = false
trace.names.DisableEvents = false
trace.names.IsCompleted = false
trace.names.GetGoalCount = false
trace.names.GetGoalTotal = false
trace.names.SetGoalTotal = false
trace.names.GetGoalPercentage = false
trace.names.deepCopy = false
trace.names._Scheduler = false
trace.names._GetTemplate = false
trace.names.FollowPlayers = false
trace.names.AddPlayerFromUnit = false
trace.names.FromCarrier = false
trace.names.OnDeadOrCrash = false

trace.classes.CLEANUP = false
trace.cache = {}

trace.tracefunction = function( functionname )

	if functionname then
		if trace.names[functionname] then
			return true
		else
			return false
		end
	else
		return false
	end

end

trace.f = function(object, parameters)

	local info = debug.getinfo( 2, "nl" )
	if trace.names.all or trace.tracefunction( info.name ) or trace.classes[object] then

		local objecttrace = ""
		if object then
			objecttrace = object
		end
		trace.nametrace = ""
		if info.name then
			trace.nametrace = info.name
		end
		local parameterstrace = "()"
		if parameters then
			parameterstrace = "( " .. routines.utils.oneLineSerialize( parameters ) .. " )"
		end
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "F", objecttrace, "function " .. trace.nametrace .. parameterstrace ) )
	end

end

trace.scheduled = function(object, func, parameters)

	local info = debug.getinfo( 2, "l" )
	if trace.names.all or trace.tracefunction( func ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		trace.nametrace = ""
		if func then
			trace.nametrace = func
		end
		trace.scheduledfunction = trace.nametrace
		local parameterstrace = "()"
		if parameters then
			parameterstrace = "( " .. routines.utils.oneLineSerialize( parameters ) .. " )"
		end
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "S", objecttrace, "function " .. trace.nametrace .. parameterstrace ) )
	end

end

trace.s = function(object, parameters)

	local info = debug.getinfo( 3, "nl" )
	if trace.names.all or trace.tracefunction( info.name ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		trace.nametrace = ""
		if info.name then
			trace.nametrace = info.name
		end
		trace.scheduledfunction = trace.nametrace
		local parameterstrace = "()"
		if parameters then
			parameterstrace = "( " .. routines.utils.oneLineSerialize( parameters ) .. " )"
		end
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "S", objecttrace, "scheduled " .. trace.nametrace .. parameterstrace ) )
	end

end

trace.si = function(object, variable)

	local info = debug.getinfo( 3, "nl" )
	if info.name ~= trace.nametrace then
		trace.nametrace = info.name
	end
	if trace.names.all or trace.tracefunction( trace.nametrace ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		local variabletrace = ""
		if variable then
			variabletrace = "( " .. routines.utils.oneLineSerialize( variable ) .. " )"
		end
		
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "S", objecttrace, trace.nametrace .. variabletrace) )
	end

end


trace.l = function(object, func, variable)

	local info = debug.getinfo( 2, "l" )
	if trace.names.all or trace.tracefunction( func ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		trace.nametrace = ""
		if func then
			trace.nametrace = func
		end
		local variabletrace = ""
		if variable then
			variabletrace = "( " .. routines.utils.oneLineSerialize( variable ) .. " )"
		end
		
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "L", objecttrace, trace.nametrace .. variabletrace) )
	end

end

trace.menu = function(object, func)

	if trace.names.all then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		trace.nametrace = ""
		if func then
			trace.nametrace = func
		end
		env.info( string.format( "%6d/%1s:%20s.%s" , 0, "M", objecttrace, trace.nametrace .. "()" ) )
	end

end

trace.r = function(object, step, variable)

	local info = debug.getinfo( 2, "nl" )
	if info.name ~= trace.nametrace then
		trace.nametrace = info.name
	end
	if trace.names.all or trace.tracefunction( trace.nametrace ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		local steptrace = ""
		if step then
			steptrace = "< " .. step .. " >"
		end
		local variabletrace = ""
		if variable then
			variabletrace = "( " .. routines.utils.oneLineSerialize( variable ) .. " )"
		end
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "R", objecttrace, "return " .. trace.nametrace .. variabletrace ) )
	end

end

trace.e = function(object)

	local info = debug.getinfo( 2, "nl" )
	if info.name ~= trace.nametrace then
		trace.nametrace = info.name
	end
	if trace.names.all or trace.tracefunction( trace.nametrace ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "E", objecttrace, "end " .. trace.nametrace ) )
	end

end

trace.i = function(object, variable)

	local info = debug.getinfo( 2, "nl" )
	trace.nametrace = info.name
	if trace.nametrace == nil then
		trace.nametrace = "function"
	end
	if trace.names.all or trace.tracefunction( trace.nametrace ) or trace.classes[ object ] then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		local variabletrace = ""
		if variable then
			variabletrace = "( " .. routines.utils.oneLineSerialize( variable ) .. " )"
		end
		
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "I", objecttrace, trace.nametrace .. variabletrace) )
	end

end

trace.x = function( object, variable )

	local info = debug.getinfo( 2, "nl" )
	trace.nametrace = info.name
	local objecttrace = ""
	if object then
		objecttrace = object
	end
	local variabletrace = ""
	if variable then
		variabletrace = "( " .. routines.utils.oneLineSerialize( variable ) .. " )"
	end
	
	env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "I", objecttrace, trace.nametrace .. variabletrace) )

end
--- Various routines
-- @module routines
-- @author Flightcontrol

Include.File( "Trace" )
--Include.File( "Message" )


env.setErrorMessageBoxEnabled(false)

--- Extract of MIST functions.
-- @author Grimes

routines = {}


-- don't change these
routines.majorVersion = 3
routines.minorVersion = 3
routines.build = 22

-----------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
-- Utils- conversion, Lua utils, etc.
routines.utils = {}

--from http://lua-users.org/wiki/CopyTable
routines.utils.deepCopy = function(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	local objectreturn = _copy(object)
	return objectreturn
end


-- porting in Slmod's serialize_slmod2
routines.utils.oneLineSerialize = function(tbl)  -- serialization of a table all on a single line, no comments, made to replace old get_table_string function

	lookup_table = {}
	
	local function _Serialize( tbl )

		if type(tbl) == 'table' then --function only works for tables!
		
			if lookup_table[tbl] then
				return lookup_table[object]
			end

			local tbl_str = {}
			
			lookup_table[tbl] = tbl_str
			
			tbl_str[#tbl_str + 1] = '{'

			for ind,val in pairs(tbl) do -- serialize its fields
				local ind_str = {}
				if type(ind) == "number" then
					ind_str[#ind_str + 1] = '['
					ind_str[#ind_str + 1] = tostring(ind)
					ind_str[#ind_str + 1] = ']='
				else --must be a string
					ind_str[#ind_str + 1] = '['
					ind_str[#ind_str + 1] = routines.utils.basicSerialize(ind)
					ind_str[#ind_str + 1] = ']='
				end

				local val_str = {}
				if ((type(val) == 'number') or (type(val) == 'boolean')) then
					val_str[#val_str + 1] = tostring(val)
					val_str[#val_str + 1] = ','
					tbl_str[#tbl_str + 1] = table.concat(ind_str)
					tbl_str[#tbl_str + 1] = table.concat(val_str)
			elseif type(val) == 'string' then
					val_str[#val_str + 1] = routines.utils.basicSerialize(val)
					val_str[#val_str + 1] = ','
					tbl_str[#tbl_str + 1] = table.concat(ind_str)
					tbl_str[#tbl_str + 1] = table.concat(val_str)
				elseif type(val) == 'nil' then -- won't ever happen, right?
					val_str[#val_str + 1] = 'nil,'
					tbl_str[#tbl_str + 1] = table.concat(ind_str)
					tbl_str[#tbl_str + 1] = table.concat(val_str)
				elseif type(val) == 'table' then
					if ind == "__index" then
					--	tbl_str[#tbl_str + 1] = "__index"
					--	tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
					else

						val_str[#val_str + 1] = _Serialize(val)
						val_str[#val_str + 1] = ','   --I think this is right, I just added it
						tbl_str[#tbl_str + 1] = table.concat(ind_str)
						tbl_str[#tbl_str + 1] = table.concat(val_str)
					end
				elseif type(val) == 'function' then
				--	tbl_str[#tbl_str + 1] = "function " .. tostring(ind)
				--	tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
				else
--					env.info('unable to serialize value type ' .. routines.utils.basicSerialize(type(val)) .. ' at index ' .. tostring(ind))
--					env.info( debug.traceback() )
				end
	
			end
			tbl_str[#tbl_str + 1] = '}'
			return table.concat(tbl_str)
		else
			return tostring(tbl)
		end
	end
	
	local objectreturn = _Serialize(tbl)
	return objectreturn
end

--porting in Slmod's "safestring" basic serialize
routines.utils.basicSerialize = function(s)
	if s == nil then
		return "\"\""
	else
		if ((type(s) == 'number') or (type(s) == 'boolean') or (type(s) == 'function') or (type(s) == 'table') or (type(s) == 'userdata') ) then
			return tostring(s)
		elseif type(s) == 'string' then
			s = string.format('%q', s)
			return s
		end
	end
end


routines.utils.toDegree = function(angle)
	return angle*180/math.pi
end

routines.utils.toRadian = function(angle)
	return angle*math.pi/180
end

routines.utils.metersToNM = function(meters)
	return meters/1852
end

routines.utils.metersToFeet = function(meters)
	return meters/0.3048
end

routines.utils.NMToMeters = function(NM)
	return NM*1852
end

routines.utils.feetToMeters = function(feet)
	return feet*0.3048
end

routines.utils.mpsToKnots = function(mps)
	return mps*3600/1852
end

routines.utils.mpsToKmph = function(mps)
	return mps*3.6
end

routines.utils.knotsToMps = function(knots)
	return knots*1852/3600
end

routines.utils.kmphToMps = function(kmph)
	return kmph/3.6
end

function routines.utils.makeVec2(Vec3)
	if Vec3.z then
		return {x = Vec3.x, y = Vec3.z}
	else
		return {x = Vec3.x, y = Vec3.y}  -- it was actually already vec2.
	end
end

function routines.utils.makeVec3(Vec2, y)
	if not Vec2.z then
		if not y then
			y = 0
		end
		return {x = Vec2.x, y = y, z = Vec2.y}
	else
		return {x = Vec2.x, y = Vec2.y, z = Vec2.z}  -- it was already Vec3, actually.
	end
end

function routines.utils.makeVec3GL(Vec2, offset)
	local adj = offset or 0

	if not Vec2.z then
		return {x = Vec2.x, y = (land.getHeight(Vec2) + adj), z = Vec2.y}
	else
		return {x = Vec2.x, y = (land.getHeight({x = Vec2.x, y = Vec2.z}) + adj), z = Vec2.z}
	end
end

routines.utils.zoneToVec3 = function(zone)
	local new = {}
	if type(zone) == 'table' and zone.point then
		new.x = zone.point.x
		new.y = zone.point.y
		new.z = zone.point.z
		return new
	elseif type(zone) == 'string' then
		zone = trigger.misc.getZone(zone)
		if zone then
			new.x = zone.point.x
			new.y = zone.point.y
			new.z = zone.point.z
			return new
		end
	end
end

-- gets heading-error corrected direction from point along vector vec.
function routines.utils.getDir(vec, point)
	local dir = math.atan2(vec.z, vec.x)
	dir = dir + routines.getNorthCorrection(point)
	if dir < 0 then
		dir = dir + 2*math.pi  -- put dir in range of 0 to 2*pi
	end
	return dir
end

-- gets distance in meters between two points (2 dimensional)
function routines.utils.get2DDist(point1, point2)
	point1 = routines.utils.makeVec3(point1)
	point2 = routines.utils.makeVec3(point2)
	return routines.vec.mag({x = point1.x - point2.x, y = 0, z = point1.z - point2.z})
end

-- gets distance in meters between two points (3 dimensional)
function routines.utils.get3DDist(point1, point2)
	return routines.vec.mag({x = point1.x - point2.x, y = point1.y - point2.y, z = point1.z - point2.z})
end



-- From http://lua-users.org/wiki/SimpleRound
-- use negative idp for rounding ahead of decimal place, positive for rounding after decimal place
routines.utils.round = function(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- porting in Slmod's dostring
routines.utils.dostring = function(s)
	local f, err = loadstring(s)
	if f then
		return true, f()
	else
		return false, err
	end
end


--3D Vector manipulation
routines.vec = {}

routines.vec.add = function(vec1, vec2)
	return {x = vec1.x + vec2.x, y = vec1.y + vec2.y, z = vec1.z + vec2.z}
end

routines.vec.sub = function(vec1, vec2)
	return {x = vec1.x - vec2.x, y = vec1.y - vec2.y, z = vec1.z - vec2.z}
end

routines.vec.scalarMult = function(vec, mult)
	return {x = vec.x*mult, y = vec.y*mult, z = vec.z*mult}
end

routines.vec.scalar_mult = routines.vec.scalarMult

routines.vec.dp = function(vec1, vec2)
	return vec1.x*vec2.x + vec1.y*vec2.y + vec1.z*vec2.z
end

routines.vec.cp = function(vec1, vec2)
	return { x = vec1.y*vec2.z - vec1.z*vec2.y, y = vec1.z*vec2.x - vec1.x*vec2.z, z = vec1.x*vec2.y - vec1.y*vec2.x}
end

routines.vec.mag = function(vec)
	return (vec.x^2 + vec.y^2 + vec.z^2)^0.5
end

routines.vec.getUnitVec = function(vec)
	local mag = routines.vec.mag(vec)
	return { x = vec.x/mag, y = vec.y/mag, z = vec.z/mag }
end

routines.vec.rotateVec2 = function(vec2, theta)
	return { x = vec2.x*math.cos(theta) - vec2.y*math.sin(theta), y = vec2.x*math.sin(theta) + vec2.y*math.cos(theta)}
end
---------------------------------------------------------------------------------------------------------------------------




-- acc- the accuracy of each easting/northing.  0, 1, 2, 3, 4, or 5.
routines.tostringMGRS = function(MGRS, acc)
	if acc == 0 then
		return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph
	else
		return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph .. ' ' .. string.format('%0' .. acc .. 'd', routines.utils.round(MGRS.Easting/(10^(5-acc)), 0))
		       .. ' ' .. string.format('%0' .. acc .. 'd', routines.utils.round(MGRS.Northing/(10^(5-acc)), 0))
	end
end

--[[acc:
in DM: decimal point of minutes.
In DMS: decimal point of seconds.
position after the decimal of the least significant digit:
So:
42.32 - acc of 2.
]]
routines.tostringLL = function(lat, lon, acc, DMS)

	local latHemi, lonHemi
	if lat > 0 then
		latHemi = 'N'
	else
		latHemi = 'S'
	end

	if lon > 0 then
		lonHemi = 'E'
	else
		lonHemi = 'W'
	end

	lat = math.abs(lat)
	lon = math.abs(lon)

	local latDeg = math.floor(lat)
	local latMin = (lat - latDeg)*60

	local lonDeg = math.floor(lon)
	local lonMin = (lon - lonDeg)*60

	if DMS then  -- degrees, minutes, and seconds.
		local oldLatMin = latMin
		latMin = math.floor(latMin)
		local latSec = routines.utils.round((oldLatMin - latMin)*60, acc)

		local oldLonMin = lonMin
		lonMin = math.floor(lonMin)
		local lonSec = routines.utils.round((oldLonMin - lonMin)*60, acc)

		if latSec == 60 then
			latSec = 0
			latMin = latMin + 1
		end

		if lonSec == 60 then
			lonSec = 0
			lonMin = lonMin + 1
		end

		local secFrmtStr -- create the formatting string for the seconds place
		if acc <= 0 then  -- no decimal place.
			secFrmtStr = '%02d'
		else
			local width = 3 + acc  -- 01.310 - that's a width of 6, for example.
			secFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
		end

		return string.format('%02d', latDeg) .. ' ' .. string.format('%02d', latMin) .. '\' ' .. string.format(secFrmtStr, latSec) .. '"' .. latHemi .. '   '
		       .. string.format('%02d', lonDeg) .. ' ' .. string.format('%02d', lonMin) .. '\' ' .. string.format(secFrmtStr, lonSec) .. '"' .. lonHemi

	else  -- degrees, decimal minutes.
		latMin = routines.utils.round(latMin, acc)
		lonMin = routines.utils.round(lonMin, acc)

		if latMin == 60 then
			latMin = 0
			latDeg = latDeg + 1
		end

		if lonMin == 60 then
			lonMin = 0
			lonDeg = lonDeg + 1
		end

		local minFrmtStr -- create the formatting string for the minutes place
		if acc <= 0 then  -- no decimal place.
			minFrmtStr = '%02d'
		else
			local width = 3 + acc  -- 01.310 - that's a width of 6, for example.
			minFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
		end

		return string.format('%02d', latDeg) .. ' ' .. string.format(minFrmtStr, latMin) .. '\'' .. latHemi .. '   '
	   .. string.format('%02d', lonDeg) .. ' ' .. string.format(minFrmtStr, lonMin) .. '\'' .. lonHemi

	end
end

--[[ required: az - radian
     required: dist - meters
	 optional: alt - meters (set to false or nil if you don't want to use it).
	 optional: metric - set true to get dist and alt in km and m.
	 precision will always be nearest degree and NM or km.]]
routines.tostringBR = function(az, dist, alt, metric)
	az = routines.utils.round(routines.utils.toDegree(az), 0)

	if metric then
		dist = routines.utils.round(dist/1000, 2)
	else
		dist = routines.utils.round(routines.utils.metersToNM(dist), 2)
	end

	local s = string.format('%03d°', az) .. ' for ' .. dist

	if alt then
		if metric then
			s = s .. ' at ' .. routines.utils.round(alt, 0)
		else
			s = s .. ' at ' .. routines.utils.round(routines.utils.metersToFeet(alt), 0)
		end
	end
	return s
end

routines.getNorthCorrection = function(point)  --gets the correction needed for true north
	if not point.z then --Vec2; convert to Vec3
		point.z = point.y
		point.y = 0
	end
	local lat, lon = coord.LOtoLL(point)
	local north_posit = coord.LLtoLO(lat + 1, lon)
	return math.atan2(north_posit.z - point.z, north_posit.x - point.x)
end


-- the main area
do
	-- THE MAIN FUNCTION --   Accessed 100 times/sec.
	routines.main = function()
		timer.scheduleFunction(routines.main, {}, timer.getTime() + 0.1)  --reschedule first in case of Lua error
		----------------------------------------------------------------------------------------------------------
		--area to add new stuff in

		routines.do_scheduled_functions()
	end -- end of routines.main

	timer.scheduleFunction(routines.main, {}, timer.getTime() + 0.1)

end


do
	local Tasks = {}
	local task_id = 0
	--[[ routines.scheduleFunction:
	int id = routines.schedule_task(f function, vars table, t number, rep number, st number)
	id - integer id of this function task
	f - function to run
	vars - table of vars for that function
	t - time to run function
	rep - time between repetitions of this function (OPTIONAL)
	st - time when repetitions of this function will stop automatically (OPTIONAL)
	]]
	routines.scheduleFunction = function(f, vars, t, rep, st)
	--verify correct types
		assert(type(f) == 'function', 'variable 1, expected function, got ' .. type(f))
		assert(type(vars) == 'table' or vars == nil, 'variable 2, expected table or nil, got ' .. type(f))
		assert(type(t) == 'number', 'variable 3, expected number, got ' .. type(t))
		assert(type(rep) == 'number' or rep == nil, 'variable 4, expected number or nil, got ' .. type(rep))
		assert(type(st) == 'number' or st == nil, 'variable 5, expected number or nil, got ' .. type(st))
		if not vars then
			vars = {}
		end
		task_id = task_id + 1
		table.insert(Tasks, {f = f, vars = vars, t = t, rep = rep, st = st, id = task_id})
		return task_id
	end

	-- removes a scheduled function based on the function's id.  returns true if successful, false if not successful.
	routines.removeFunction = function(id)
		local i = 1
		while i <= #Tasks do
			if Tasks[i].id == id then
				table.remove(Tasks, i)
			else
				i = i + 1
			end
		end
	end

	routines.errhandler = function(errmsg)

		env.info( "Error in scheduled function:" .. errmsg )
		env.info( debug.traceback() )

		return errmsg
	end

	--------------------------------------------------------------------------------------------------------------------
	-- not intended for users to use this function.
	routines.do_scheduled_functions = function()
		local i = 1
		while i <= #Tasks do
			if not Tasks[i].rep then -- not a repeated process
				if Tasks[i].t <= timer.getTime() then
					local Task = Tasks[i] -- local reference
					--env.info("do_scheduled_functions:call function " .. i )
					table.remove(Tasks, i)
					local err, errmsg = xpcall(function() Task.f( unpack(Task.vars, 1, table.maxn(Task.vars))) end, routines.errhandler )
					if not err then
						--env.info('routines.scheduleFunction, error in scheduled function: ' .. errmsg)
					end
					--Task.f(unpack(Task.vars, 1, table.maxn(Task.vars)))  -- do the task, do not increment i
				else
					i = i + 1
				end
			else
				if Tasks[i].st and Tasks[i].st <= timer.getTime() then   --if a stoptime was specified, and the stop time exceeded
					--env.info("do_scheduled_functions:remove repeated")
					table.remove(Tasks, i) -- stop time exceeded, do not execute, do not increment i
				elseif Tasks[i].t <= timer.getTime() then
					local Task = Tasks[i] -- local reference
					Task.t = timer.getTime() + Task.rep  --schedule next run
					--env.info("do_scheduled_functions:call function " .. i )
					local err, errmsg = xpcall(function() Task.f( unpack(Task.vars, 1, table.maxn(Task.vars))) end, routines.errhandler )
					if not err then
						--env.info('routines.scheduleFunction, error in scheduled function: ' .. errmsg)
					end
					--Tasks[i].f(unpack(Tasks[i].vars, 1, table.maxn(Tasks[i].vars)))  -- do the task
					i = i + 1
				else
					i = i + 1
				end
			end
		end

	end

end

do
	local idNum = 0

	--Simplified event handler
	routines.addEventHandler = function(f) --id is optional!
		local handler = {}
		idNum = idNum + 1
		handler.id = idNum
		handler.f = f
		handler.onEvent = function(self, event)
			self.f(event)
		end
		world.addEventHandler(handler)
	end

	routines.removeEventHandler = function(id)
		for key, handler in pairs(world.eventHandlers) do
			if handler.id and handler.id == id then
				world.eventHandlers[key] = nil
				return true
			end
		end
		return false
	end
end

-- need to return a Vec3 or Vec2?
function routines.getRandPointInCircle(point, radius, innerRadius)
	local theta = 2*math.pi*math.random()
	local rad = math.random() + math.random()
	if rad > 1 then
		rad = 2 - rad
	end

	local radMult
	if innerRadius and innerRadius <= radius then
		radMult = (radius - innerRadius)*rad + innerRadius
	else
		radMult = radius*rad
	end

	if not point.z then --might as well work with vec2/3
		point.z = point.y
	end

	local rndCoord
	if radius > 0 then
		rndCoord = {x = math.cos(theta)*radMult + point.x, y = math.sin(theta)*radMult + point.z}
	else
		rndCoord = {x = point.x, y = point.z}
	end
	return rndCoord
end

routines.goRoute = function(group, path)
	local misTask = {
		id = 'Mission',
		params = {
			route = {
				points = routines.utils.deepCopy(path),
			},
		},
	}
	if type(group) == 'string' then
		group = Group.getByName(group)
	end
	local groupCon = group:getController()
	if groupCon then
		groupCon:setTask(misTask)
		return true
	end

	Controller.setTask(groupCon, misTask)
	return false
end


-- Useful atomic functions from mist, ported.

routines.ground = {}
routines.fixedWing = {}
routines.heli = {}

routines.ground.buildWP = function(point, overRideForm, overRideSpeed)

	local wp = {}
	wp.x = point.x

	if point.z then
		wp.y = point.z
	else
		wp.y = point.y
	end
	local form, speed

	if point.speed and not overRideSpeed then
		wp.speed = point.speed
	elseif type(overRideSpeed) == 'number' then
		wp.speed = overRideSpeed
	else
		wp.speed = routines.utils.kmphToMps(20)
	end

	if point.form and not overRideForm then
		form = point.form
	else
		form = overRideForm
	end

	if not form then
		wp.action = 'Cone'
	else
		form = string.lower(form)
		if form == 'off_road' or form == 'off road' then
			wp.action = 'Off Road'
		elseif form == 'on_road' or form == 'on road' then
			wp.action = 'On Road'
		elseif form == 'rank' or form == 'line_abrest' or form == 'line abrest' or form == 'lineabrest'then
			wp.action = 'Rank'
		elseif form == 'cone' then
			wp.action = 'Cone'
		elseif form == 'diamond' then
			wp.action = 'Diamond'
		elseif form == 'vee' then
			wp.action = 'Vee'
		elseif form == 'echelon_left' or form == 'echelon left' or form == 'echelonl' then
			wp.action = 'EchelonL'
		elseif form == 'echelon_right' or form == 'echelon right' or form == 'echelonr' then
			wp.action = 'EchelonR'
		else
			wp.action = 'Cone' -- if nothing matched
		end
	end

	wp.type = 'Turning Point'

	return wp

end

routines.fixedWing.buildWP = function(point, WPtype, speed, alt, altType)

	local wp = {}
	wp.x = point.x

	if point.z then
		wp.y = point.z
	else
		wp.y = point.y
	end

	if alt and type(alt) == 'number' then
		wp.alt = alt
	else
		wp.alt = 2000
	end

	if altType then
		altType = string.lower(altType)
		if altType == 'radio' or 'agl' then
			wp.alt_type = 'RADIO'
		elseif altType == 'baro' or 'asl' then
			wp.alt_type = 'BARO'
		end
	else
		wp.alt_type = 'RADIO'
	end

	if point.speed then
		speed = point.speed
	end

	if point.type then
		WPtype = point.type
	end

	if not speed then
		wp.speed = routines.utils.kmphToMps(500)
	else
		wp.speed = speed
	end

	if not WPtype then
		wp.action =  'Turning Point'
	else
		WPtype = string.lower(WPtype)
		if WPtype == 'flyover' or WPtype == 'fly over' or WPtype == 'fly_over' then
			wp.action =  'Fly Over Point'
		elseif WPtype == 'turningpoint' or WPtype == 'turning point' or WPtype == 'turning_point' then
			wp.action =  'Turning Point'
		else
			wp.action = 'Turning Point'
		end
	end

	wp.type = 'Turning Point'
	return wp
end

routines.heli.buildWP = function(point, WPtype, speed, alt, altType)

	local wp = {}
	wp.x = point.x

	if point.z then
		wp.y = point.z
	else
		wp.y = point.y
	end

	if alt and type(alt) == 'number' then
		wp.alt = alt
	else
		wp.alt = 500
	end

	if altType then
		altType = string.lower(altType)
		if altType == 'radio' or 'agl' then
			wp.alt_type = 'RADIO'
		elseif altType == 'baro' or 'asl' then
			wp.alt_type = 'BARO'
		end
	else
		wp.alt_type = 'RADIO'
	end

	if point.speed then
		speed = point.speed
	end

	if point.type then
		WPtype = point.type
	end

	if not speed then
		wp.speed = routines.utils.kmphToMps(200)
	else
		wp.speed = speed
	end

	if not WPtype then
		wp.action =  'Turning Point'
	else
		WPtype = string.lower(WPtype)
		if WPtype == 'flyover' or WPtype == 'fly over' or WPtype == 'fly_over' then
			wp.action =  'Fly Over Point'
		elseif WPtype == 'turningpoint' or WPtype == 'turning point' or WPtype == 'turning_point' then
			wp.action = 'Turning Point'
		else
			wp.action =  'Turning Point'
		end
	end

	wp.type = 'Turning Point'
	return wp
end

routines.groupToRandomPoint = function(vars)
	local group = vars.group --Required
	local point = vars.point --required
	local radius = vars.radius or 0
	local innerRadius = vars.innerRadius
	local form = vars.form or 'Cone'
	local heading = vars.heading or math.random()*2*math.pi
	local headingDegrees = vars.headingDegrees
	local speed = vars.speed or routines.utils.kmphToMps(20)


	local useRoads
	if not vars.disableRoads then
		useRoads = true
	else
		useRoads = false
	end

	local path = {}

	if headingDegrees then
		heading = headingDegrees*math.pi/180
	end

	if heading >= 2*math.pi then
		heading = heading - 2*math.pi
	end

	local rndCoord = routines.getRandPointInCircle(point, radius, innerRadius)

	local offset = {}
	local posStart = routines.getLeadPos(group)

	offset.x = routines.utils.round(math.sin(heading - (math.pi/2)) * 50 + rndCoord.x, 3)
	offset.z = routines.utils.round(math.cos(heading + (math.pi/2)) * 50 + rndCoord.y, 3)
	path[#path + 1] = routines.ground.buildWP(posStart, form, speed)


	if useRoads == true and ((point.x - posStart.x)^2 + (point.z - posStart.z)^2)^0.5 > radius * 1.3 then
		path[#path + 1] = routines.ground.buildWP({['x'] = posStart.x + 11, ['z'] = posStart.z + 11}, 'off_road', speed)
		path[#path + 1] = routines.ground.buildWP(posStart, 'on_road', speed)
		path[#path + 1] = routines.ground.buildWP(offset, 'on_road', speed)
	else
		path[#path + 1] = routines.ground.buildWP({['x'] = posStart.x + 25, ['z'] = posStart.z + 25}, form, speed)
	end

	path[#path + 1] = routines.ground.buildWP(offset, form, speed)
	path[#path + 1] = routines.ground.buildWP(rndCoord, form, speed)

	routines.goRoute(group, path)

	return
end

routines.groupRandomDistSelf = function(gpData, dist, form, heading, speed)
	local pos = routines.getLeadPos(gpData)
	local fakeZone = {}
	fakeZone.radius = dist or math.random(300, 1000)
	fakeZone.point = {x = pos.x, y, pos.y, z = pos.z}
	routines.groupToRandomZone(gpData, fakeZone, form, heading, speed)

	return
end

routines.groupToRandomZone = function(gpData, zone, form, heading, speed)
	if type(gpData) == 'string' then
		gpData = Group.getByName(gpData)
	end

	if type(zone) == 'string' then
		zone = trigger.misc.getZone(zone)
	elseif type(zone) == 'table' and not zone.radius then
		zone = trigger.misc.getZone(zone[math.random(1, #zone)])
	end

	if speed then
		speed = routines.utils.kmphToMps(speed)
	end

	local vars = {}
	vars.group = gpData
	vars.radius = zone.radius
	vars.form = form
	vars.headingDegrees = heading
	vars.speed = speed
	vars.point = routines.utils.zoneToVec3(zone)

	routines.groupToRandomPoint(vars)

	return
end

routines.isTerrainValid = function(coord, terrainTypes) -- vec2/3 and enum or table of acceptable terrain types
	if coord.z then
		coord.y = coord.z
	end
	local typeConverted = {}

	if type(terrainTypes) == 'string' then -- if its a string it does this check
		for constId, constData in pairs(land.SurfaceType) do
			if string.lower(constId) == string.lower(terrainTypes) or string.lower(constData) == string.lower(terrainTypes) then
				table.insert(typeConverted, constId)
			end
		end
	elseif type(terrainTypes) == 'table' then -- if its a table it does this check
		for typeId, typeData in pairs(terrainTypes) do
			for constId, constData in pairs(land.SurfaceType) do
				if string.lower(constId) == string.lower(typeData) or string.lower(constData) == string.lower(typeId) then
					table.insert(typeConverted, constId)
				end
			end
		end
	end
	for validIndex, validData in pairs(typeConverted) do
		if land.getSurfaceType(coord) == land.SurfaceType[validData] then
			return true
		end
	end
	return false
end

routines.groupToPoint = function(gpData, point, form, heading, speed, useRoads)
	if type(point) == 'string' then
		point = trigger.misc.getZone(point)
	end
	if speed then
		speed = routines.utils.kmphToMps(speed)
	end

	local vars = {}
	vars.group = gpData
	vars.form = form
	vars.headingDegrees = heading
	vars.speed = speed
	vars.disableRoads = useRoads
	vars.point = routines.utils.zoneToVec3(point)
	routines.groupToRandomPoint(vars)

	return
end


routines.getLeadPos = function(group)
	if type(group) == 'string' then -- group name
		group = Group.getByName(group)
	end

	local units = group:getUnits()

	local leader = units[1]
	if not leader then  -- SHOULD be good, but if there is a bug, this code future-proofs it then.
		local lowestInd = math.huge
		for ind, unit in pairs(units) do
			if ind < lowestInd then
				lowestInd = ind
				leader = unit
			end
		end
	end
	if leader and Unit.isExist(leader) then  -- maybe a little too paranoid now...
		return leader:getPosition().p
	end
end

--[[ vars for routines.getMGRSString:
vars.units - table of unit names (NOT unitNameTable- maybe this should change).
vars.acc - integer between 0 and 5, inclusive
]]
routines.getMGRSString = function(vars)
	local units = vars.units
	local acc = vars.acc or 5
	local avgPos = routines.getAvgPos(units)
	if avgPos then
		return routines.tostringMGRS(coord.LLtoMGRS(coord.LOtoLL(avgPos)), acc)
	end
end

--[[ vars for routines.getLLString
vars.units - table of unit names (NOT unitNameTable- maybe this should change).
vars.acc - integer, number of numbers after decimal place
vars.DMS - if true, output in degrees, minutes, seconds.  Otherwise, output in degrees, minutes.


]]
routines.getLLString = function(vars)
	local units = vars.units
	local acc = vars.acc or 3
	local DMS = vars.DMS
	local avgPos = routines.getAvgPos(units)
	if avgPos then
		local lat, lon = coord.LOtoLL(avgPos)
		return routines.tostringLL(lat, lon, acc, DMS)
	end
end

--[[
vars.zone - table of a zone name.
vars.ref -  vec3 ref point, maybe overload for vec2 as well?
vars.alt - boolean, if used, includes altitude in string
vars.metric - boolean, gives distance in km instead of NM.
]]
routines.getBRStringZone = function(vars)
	local zone = trigger.misc.getZone( vars.zone )
	local ref = routines.utils.makeVec3(vars.ref, 0)  -- turn it into Vec3 if it is not already.
	local alt = vars.alt
	local metric = vars.metric
	if zone then
		local vec = {x = zone.point.x - ref.x, y = zone.point.y - ref.y, z = zone.point.z - ref.z}
		local dir = routines.utils.getDir(vec, ref)
		local dist = routines.utils.get2DDist(zone.point, ref)
		if alt then
			alt = zone.y
		end
		return routines.tostringBR(dir, dist, alt, metric)
	else
		env.info( 'routines.getBRStringZone: error: zone is nil' )
	end
end

--[[
vars.units- table of unit names (NOT unitNameTable- maybe this should change).
vars.ref -  vec3 ref point, maybe overload for vec2 as well?
vars.alt - boolean, if used, includes altitude in string
vars.metric - boolean, gives distance in km instead of NM.
]]
routines.getBRString = function(vars)
	local units = vars.units
	local ref = routines.utils.makeVec3(vars.ref, 0)  -- turn it into Vec3 if it is not already.
	local alt = vars.alt
	local metric = vars.metric
	local avgPos = routines.getAvgPos(units)
	if avgPos then
		local vec = {x = avgPos.x - ref.x, y = avgPos.y - ref.y, z = avgPos.z - ref.z}
		local dir = routines.utils.getDir(vec, ref)
		local dist = routines.utils.get2DDist(avgPos, ref)
		if alt then
			alt = avgPos.y
		end
		return routines.tostringBR(dir, dist, alt, metric)
	end
end


-- Returns the Vec3 coordinates of the average position of the concentration of units most in the heading direction.
--[[ vars for routines.getLeadingPos:
vars.units - table of unit names
vars.heading - direction
vars.radius - number
vars.headingDegrees - boolean, switches heading to degrees
]]
routines.getLeadingPos = function(vars)
	local units = vars.units
	local heading = vars.heading
	local radius = vars.radius
	if vars.headingDegrees then
		heading = routines.utils.toRadian(vars.headingDegrees)
	end

	local unitPosTbl = {}
	for i = 1, #units do
		local unit = Unit.getByName(units[i])
		if unit and unit:isExist() then
			unitPosTbl[#unitPosTbl + 1] = unit:getPosition().p
		end
	end
	if #unitPosTbl > 0 then  -- one more more units found.
		-- first, find the unit most in the heading direction
		local maxPos = -math.huge

		local maxPosInd  -- maxPos - the furthest in direction defined by heading; maxPosInd =
		for i = 1, #unitPosTbl do
			local rotatedVec2 = routines.vec.rotateVec2(routines.utils.makeVec2(unitPosTbl[i]), heading)
			if (not maxPos) or maxPos < rotatedVec2.x then
				maxPos = rotatedVec2.x
				maxPosInd = i
			end
		end

		--now, get all the units around this unit...
		local avgPos
		if radius then
			local maxUnitPos = unitPosTbl[maxPosInd]
			local avgx, avgy, avgz, totNum = 0, 0, 0, 0
			for i = 1, #unitPosTbl do
				if routines.utils.get2DDist(maxUnitPos, unitPosTbl[i]) <= radius then
					avgx = avgx + unitPosTbl[i].x
					avgy = avgy + unitPosTbl[i].y
					avgz = avgz + unitPosTbl[i].z
					totNum = totNum + 1
				end
			end
			avgPos = { x = avgx/totNum, y = avgy/totNum, z = avgz/totNum}
		else
			avgPos = unitPosTbl[maxPosInd]
		end

		return avgPos
	end
end


--[[ vars for routines.getLeadingMGRSString:
vars.units - table of unit names
vars.heading - direction
vars.radius - number
vars.headingDegrees - boolean, switches heading to degrees
vars.acc - number, 0 to 5.
]]
routines.getLeadingMGRSString = function(vars)
	local pos = routines.getLeadingPos(vars)
	if pos then
		local acc = vars.acc or 5
		return routines.tostringMGRS(coord.LLtoMGRS(coord.LOtoLL(pos)), acc)
	end
end

--[[ vars for routines.getLeadingLLString:
vars.units - table of unit names
vars.heading - direction, number
vars.radius - number
vars.headingDegrees - boolean, switches heading to degrees
vars.acc - number of digits after decimal point (can be negative)
vars.DMS -  boolean, true if you want DMS.
]]
routines.getLeadingLLString = function(vars)
	local pos = routines.getLeadingPos(vars)
	if pos then
		local acc = vars.acc or 3
		local DMS = vars.DMS
		local lat, lon = coord.LOtoLL(pos)
		return routines.tostringLL(lat, lon, acc, DMS)
	end
end



--[[ vars for routines.getLeadingBRString:
vars.units - table of unit names
vars.heading - direction, number
vars.radius - number
vars.headingDegrees - boolean, switches heading to degrees
vars.metric - boolean, if true, use km instead of NM.
vars.alt - boolean, if true, include altitude.
vars.ref - vec3/vec2 reference point.
]]
routines.getLeadingBRString = function(vars)
	local pos = routines.getLeadingPos(vars)
	if pos then
		local ref = vars.ref
		local alt = vars.alt
		local metric = vars.metric

		local vec = {x = pos.x - ref.x, y = pos.y - ref.y, z = pos.z - ref.z}
		local dir = routines.utils.getDir(vec, ref)
		local dist = routines.utils.get2DDist(pos, ref)
		if alt then
			alt = pos.y
		end
		return routines.tostringBR(dir, dist, alt, metric)
	end
end

--[[ vars for routines.message.add
	vars.text = 'Hello World'
	vars.displayTime = 20
	vars.msgFor = {coa = {'red'}, countries = {'Ukraine', 'Georgia'}, unitTypes = {'A-10C'}}

]]

--[[ vars for routines.msgMGRS
vars.units - table of unit names (NOT unitNameTable- maybe this should change).
vars.acc - integer between 0 and 5, inclusive
vars.text - text in the message
vars.displayTime - self explanatory
vars.msgFor - scope
]]
routines.msgMGRS = function(vars)
	local units = vars.units
	local acc = vars.acc
	local text = vars.text
	local displayTime = vars.displayTime
	local msgFor = vars.msgFor

	local s = routines.getMGRSString{units = units, acc = acc}
	local newText
	if string.find(text, '%%s') then  -- look for %s
		newText = string.format(text, s)  -- insert the coordinates into the message
	else  -- else, just append to the end.
		newText = text .. s
	end

	routines.message.add{
		text = newText,
		displayTime = displayTime,
		msgFor = msgFor
	}
end

--[[ vars for routines.msgLL
vars.units - table of unit names (NOT unitNameTable- maybe this should change) (Yes).
vars.acc - integer, number of numbers after decimal place
vars.DMS - if true, output in degrees, minutes, seconds.  Otherwise, output in degrees, minutes.
vars.text - text in the message
vars.displayTime - self explanatory
vars.msgFor - scope
]]
routines.msgLL = function(vars)
	local units = vars.units  -- technically, I don't really need to do this, but it helps readability.
	local acc = vars.acc
	local DMS = vars.DMS
	local text = vars.text
	local displayTime = vars.displayTime
	local msgFor = vars.msgFor

	local s = routines.getLLString{units = units, acc = acc, DMS = DMS}
	local newText
	if string.find(text, '%%s') then  -- look for %s
		newText = string.format(text, s)  -- insert the coordinates into the message
	else  -- else, just append to the end.
		newText = text .. s
	end

	routines.message.add{
		text = newText,
		displayTime = displayTime,
		msgFor = msgFor
	}

end


--[[
vars.units- table of unit names (NOT unitNameTable- maybe this should change).
vars.ref -  vec3 ref point, maybe overload for vec2 as well?
vars.alt - boolean, if used, includes altitude in string
vars.metric - boolean, gives distance in km instead of NM.
vars.text - text of the message
vars.displayTime
vars.msgFor - scope
]]
routines.msgBR = function(vars)
	local units = vars.units  -- technically, I don't really need to do this, but it helps readability.
	local ref = vars.ref -- vec2/vec3 will be handled in routines.getBRString
	local alt = vars.alt
	local metric = vars.metric
	local text = vars.text
	local displayTime = vars.displayTime
	local msgFor = vars.msgFor

	local s = routines.getBRString{units = units, ref = ref, alt = alt, metric = metric}
	local newText
	if string.find(text, '%%s') then  -- look for %s
		newText = string.format(text, s)  -- insert the coordinates into the message
	else  -- else, just append to the end.
		newText = text .. s
	end

	routines.message.add{
		text = newText,
		displayTime = displayTime,
		msgFor = msgFor
	}

end


--------------------------------------------------------------------------------------------
-- basically, just sub-types of routines.msgBR... saves folks the work of getting the ref point.
--[[
vars.units- table of unit names (NOT unitNameTable- maybe this should change).
vars.ref -  string red, blue
vars.alt - boolean, if used, includes altitude in string
vars.metric - boolean, gives distance in km instead of NM.
vars.text - text of the message
vars.displayTime
vars.msgFor - scope
]]
routines.msgBullseye = function(vars)
	if string.lower(vars.ref) == 'red' then
		vars.ref = routines.DBs.missionData.bullseye.red
		routines.msgBR(vars)
	elseif string.lower(vars.ref) == 'blue' then
		vars.ref = routines.DBs.missionData.bullseye.blue
		routines.msgBR(vars)
	end
end

--[[
vars.units- table of unit names (NOT unitNameTable- maybe this should change).
vars.ref -  unit name of reference point
vars.alt - boolean, if used, includes altitude in string
vars.metric - boolean, gives distance in km instead of NM.
vars.text - text of the message
vars.displayTime
vars.msgFor - scope
]]

routines.msgBRA = function(vars)
	if Unit.getByName(vars.ref) then
		vars.ref = Unit.getByName(vars.ref):getPosition().p
		if not vars.alt then
			vars.alt = true
		end
		routines.msgBR(vars)
	end
end
--------------------------------------------------------------------------------------------

--[[ vars for routines.msgLeadingMGRS:
vars.units - table of unit names
vars.heading - direction
vars.radius - number
vars.headingDegrees - boolean, switches heading to degrees (optional)
vars.acc - number, 0 to 5.
vars.text - text of the message
vars.displayTime
vars.msgFor - scope
]]
routines.msgLeadingMGRS = function(vars)
	local units = vars.units  -- technically, I don't really need to do this, but it helps readability.
	local heading = vars.heading
	local radius = vars.radius
	local headingDegrees = vars.headingDegrees
	local acc = vars.acc
	local text = vars.text
	local displayTime = vars.displayTime
	local msgFor = vars.msgFor

	local s = routines.getLeadingMGRSString{units = units, heading = heading, radius = radius, headingDegrees = headingDegrees, acc = acc}
	local newText
	if string.find(text, '%%s') then  -- look for %s
		newText = string.format(text, s)  -- insert the coordinates into the message
	else  -- else, just append to the end.
		newText = text .. s
	end

	routines.message.add{
		text = newText,
		displayTime = displayTime,
		msgFor = msgFor
	}


end
--[[ vars for routines.msgLeadingLL:
vars.units - table of unit names
vars.heading - direction, number
vars.radius - number
vars.headingDegrees - boolean, switches heading to degrees (optional)
vars.acc - number of digits after decimal point (can be negative)
vars.DMS -  boolean, true if you want DMS. (optional)
vars.text - text of the message
vars.displayTime
vars.msgFor - scope
]]
routines.msgLeadingLL = function(vars)
	local units = vars.units  -- technically, I don't really need to do this, but it helps readability.
	local heading = vars.heading
	local radius = vars.radius
	local headingDegrees = vars.headingDegrees
	local acc = vars.acc
	local DMS = vars.DMS
	local text = vars.text
	local displayTime = vars.displayTime
	local msgFor = vars.msgFor

	local s = routines.getLeadingLLString{units = units, heading = heading, radius = radius, headingDegrees = headingDegrees, acc = acc, DMS = DMS}
	local newText
	if string.find(text, '%%s') then  -- look for %s
		newText = string.format(text, s)  -- insert the coordinates into the message
	else  -- else, just append to the end.
		newText = text .. s
	end

	routines.message.add{
		text = newText,
		displayTime = displayTime,
		msgFor = msgFor
	}

end

--[[
vars.units - table of unit names
vars.heading - direction, number
vars.radius - number
vars.headingDegrees - boolean, switches heading to degrees  (optional)
vars.metric - boolean, if true, use km instead of NM. (optional)
vars.alt - boolean, if true, include altitude. (optional)
vars.ref - vec3/vec2 reference point.
vars.text - text of the message
vars.displayTime
vars.msgFor - scope
]]
routines.msgLeadingBR = function(vars)
	local units = vars.units  -- technically, I don't really need to do this, but it helps readability.
	local heading = vars.heading
	local radius = vars.radius
	local headingDegrees = vars.headingDegrees
	local metric = vars.metric
	local alt = vars.alt
	local ref = vars.ref -- vec2/vec3 will be handled in routines.getBRString
	local text = vars.text
	local displayTime = vars.displayTime
	local msgFor = vars.msgFor

	local s = routines.getLeadingBRString{units = units, heading = heading, radius = radius, headingDegrees = headingDegrees, metric = metric, alt = alt, ref = ref}
	local newText
	if string.find(text, '%%s') then  -- look for %s
		newText = string.format(text, s)  -- insert the coordinates into the message
	else  -- else, just append to the end.
		newText = text .. s
	end

	routines.message.add{
		text = newText,
		displayTime = displayTime,
		msgFor = msgFor
	}
end


function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end


function routines.IsPartOfGroupInZones( CargoGroup, LandingZones )
trace.f()

	local CurrentZoneID = nil

	if CargoGroup then
		local CargoUnits = CargoGroup:getUnits()
		for CargoUnitID, CargoUnit in pairs( CargoUnits ) do
			if CargoUnit and CargoUnit:getLife() >= 1.0 then
				CurrentZoneID = routines.IsUnitInZones( CargoUnit, LandingZones )
				if CurrentZoneID then
					break
				end
			end
		end
	end

trace.r( "", "", { CurrentZoneID } )
	return CurrentZoneID
end



function routines.IsUnitInZones( TransportUnit, LandingZones )
trace.f("", "routines.IsUnitInZones" )

    local TransportZoneResult = nil
	local TransportZonePos = nil
	local TransportZone = nil

    -- fill-up some local variables to support further calculations to determine location of units within the zone.
	if TransportUnit then
		local TransportUnitPos = TransportUnit:getPosition().p
		if type( LandingZones ) == "table" then
			for LandingZoneID, LandingZoneName in pairs( LandingZones ) do
				TransportZone = trigger.misc.getZone( LandingZoneName )
				if TransportZone then
					TransportZonePos = {radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z}
					if  ((( TransportUnitPos.x - TransportZonePos.x)^2 + (TransportUnitPos.z - TransportZonePos.z)^2)^0.5 <= TransportZonePos.radius) then
						TransportZoneResult = LandingZoneID
						break
					end
				end
			end
		else
			TransportZone = trigger.misc.getZone( LandingZones )
			TransportZonePos = {radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z}
			if  ((( TransportUnitPos.x - TransportZonePos.x)^2 + (TransportUnitPos.z - TransportZonePos.z)^2)^0.5 <= TransportZonePos.radius) then
				TransportZoneResult = 1
			end
		end
		if TransportZoneResult then
			trace.i( "routines", "TransportZone:" .. TransportZoneResult )
		else
			trace.i( "routines", "TransportZone:nil logic" )
		end
		return TransportZoneResult
	else
		trace.i( "routines", "TransportZone:nil hard" )
		return nil
	end
end

function routines.IsStaticInZones( TransportStatic, LandingZones )
trace.f()

    local TransportZoneResult = nil
	local TransportZonePos = nil
	local TransportZone = nil

    -- fill-up some local variables to support further calculations to determine location of units within the zone.
    local TransportStaticPos = TransportStatic:getPosition().p
	if type( LandingZones ) == "table" then
		for LandingZoneID, LandingZoneName in pairs( LandingZones ) do
			TransportZone = trigger.misc.getZone( LandingZoneName )
			if TransportZone then
				TransportZonePos = {radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z}
				if  ((( TransportStaticPos.x - TransportZonePos.x)^2 + (TransportStaticPos.z - TransportZonePos.z)^2)^0.5 <= TransportZonePos.radius) then
					TransportZoneResult = LandingZoneID
					break
				end
			end
		end
	else
		TransportZone = trigger.misc.getZone( LandingZones )
		TransportZonePos = {radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z}
		if  ((( TransportStaticPos.x - TransportZonePos.x)^2 + (TransportStaticPos.z - TransportZonePos.z)^2)^0.5 <= TransportZonePos.radius) then
			TransportZoneResult = 1
		end
	end

trace.r( "", "", { TransportZoneResult } )
    return TransportZoneResult
end


function routines.IsUnitInRadius( CargoUnit, ReferencePosition, Radius )
trace.f()

  local Valid = true

  -- fill-up some local variables to support further calculations to determine location of units within the zone.
  local CargoPos = CargoUnit:getPosition().p
  local ReferenceP = ReferencePosition.p

  if  (((CargoPos.x - ReferenceP.x)^2 + (CargoPos.z - ReferenceP.z)^2)^0.5 <= Radius) then
  else
    Valid = false
  end

  return Valid
end

function routines.IsPartOfGroupInRadius( CargoGroup, ReferencePosition, Radius )
trace.f()

  local Valid = true

  Valid = routines.ValidateGroup( CargoGroup, "CargoGroup", Valid )

  -- fill-up some local variables to support further calculations to determine location of units within the zone
  local CargoUnits = CargoGroup:getUnits()
  for CargoUnitId, CargoUnit in pairs( CargoUnits ) do
    local CargoUnitPos = CargoUnit:getPosition().p
--    env.info( 'routines.IsPartOfGroupInRadius: CargoUnitPos.x = ' .. CargoUnitPos.x .. ' CargoUnitPos.z = ' .. CargoUnitPos.z )
    local ReferenceP = ReferencePosition.p
--    env.info( 'routines.IsPartOfGroupInRadius: ReferenceGroupPos.x = ' .. ReferenceGroupPos.x .. ' ReferenceGroupPos.z = ' .. ReferenceGroupPos.z )

    if  ((( CargoUnitPos.x - ReferenceP.x)^2 + (CargoUnitPos.z - ReferenceP.z)^2)^0.5 <= Radius) then
    else
      Valid = false
      break
    end
  end

  return Valid
end


function routines.ValidateString( Variable, VariableName, Valid )
trace.f()

  if  type( Variable ) == "string" then
    if Variable == "" then
      error( "routines.ValidateString: error: " .. VariableName .. " must be filled out!" )
      Valid = false
    end
  else
    error( "routines.ValidateString: error: " .. VariableName .. " is not a string." )
    Valid = false
  end

trace.r( "", "", { Valid } )
  return Valid
end

function routines.ValidateNumber( Variable, VariableName, Valid )
trace.f()

  if  type( Variable ) == "number" then
  else
    error( "routines.ValidateNumber: error: " .. VariableName .. " is not a number." )
    Valid = false
  end

trace.r( "", "", { Valid } )
  return Valid

end

function routines.ValidateGroup( Variable, VariableName, Valid )
trace.f()

	if Variable == nil then
		error( "routines.ValidateGroup: error: " .. VariableName .. " is a nil value!" )
		Valid = false
	end

trace.r( "", "", { Valid } )
	return Valid
end

function routines.ValidateZone( LandingZones, VariableName, Valid )
trace.f()

	if LandingZones == nil then
		error( "routines.ValidateGroup: error: " .. VariableName .. " is a nil value!" )
		Valid = false
	end

	if type( LandingZones ) == "table" then
		for LandingZoneID, LandingZoneName in pairs( LandingZones ) do
			if trigger.misc.getZone( LandingZoneName ) == nil then
				error( "routines.ValidateGroup: error: Zone " .. LandingZoneName .. " does not exist!" )
				Valid = false
				break
			end
		end
	else
		if trigger.misc.getZone( LandingZones ) == nil then
			error( "routines.ValidateGroup: error: Zone " .. LandingZones .. " does not exist!" )
			Valid = false
		end
	end

trace.r( "", "", { Valid } )
	return Valid
end

function routines.ValidateEnumeration( Variable, VariableName, Enum, Valid )
trace.f()

  local ValidVariable = false

  for EnumId, EnumData in pairs( Enum ) do
    if Variable == EnumData then
      ValidVariable = true
      break
    end
  end

  if  ValidVariable then
  else
    error( 'TransportValidateEnum: " .. VariableName .. " is not a valid type.' .. Variable )
    Valid = false
  end

trace.r( "", "", { Valid } )
  return Valid
end

function routines.getGroupRoute(groupIdent, task)   -- same as getGroupPoints but returns speed and formation type along with vec2 of point}
		-- refactor to search by groupId and allow groupId and groupName as inputs
	local gpId = groupIdent
	if type(groupIdent) == 'string' and not tonumber(groupIdent) then
		gpId = _Database.Groups[groupIdent].groupId
	end
	
	for coa_name, coa_data in pairs(env.mission.coalition) do
		if (coa_name == 'red' or coa_name == 'blue') and type(coa_data) == 'table' then			
			if coa_data.country then --there is a country table
				for cntry_id, cntry_data in pairs(coa_data.country) do
					for obj_type_name, obj_type_data in pairs(cntry_data) do
						if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" then	-- only these types have points						
							if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then  --there's a group!				
								for group_num, group_data in pairs(obj_type_data.group) do		
									if group_data and group_data.groupId == gpId  then -- this is the group we are looking for
										if group_data.route and group_data.route.points and #group_data.route.points > 0 then
											local points = {}
											
											for point_num, point in pairs(group_data.route.points) do
												local routeData = {}
												if not point.point then
													routeData.x = point.x
													routeData.y = point.y
												else
													routeData.point = point.point  --it's possible that the ME could move to the point = Vec2 notation.
												end
												routeData.form = point.action
												routeData.speed = point.speed
												routeData.alt = point.alt
												routeData.alt_type = point.alt_type
												routeData.airdromeId = point.airdromeId
												routeData.helipadId = point.helipadId
												routeData.type = point.type
												routeData.action = point.action
												if task then
													routeData.task = point.task
												end
												points[point_num] = routeData
											end
											
											return points
										end
										return
									end  --if group_data and group_data.name and group_data.name == 'groupname'
								end --for group_num, group_data in pairs(obj_type_data.group) do		
							end --if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then	
						end --if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then
					end --for obj_type_name, obj_type_data in pairs(cntry_data) do
				end --for cntry_id, cntry_data in pairs(coa_data.country) do
			end --if coa_data.country then --there is a country table
		end --if coa_name == 'red' or coa_name == 'blue' and type(coa_data) == 'table' then	
	end --for coa_name, coa_data in pairs(mission.coalition) do
end
routines.ground.patrolRoute = function(vars)
	
	
	local tempRoute = {}
	local useRoute = {}
	local gpData = vars.gpData
	if type(gpData) == 'string' then
		gpData = Group.getByName(gpData)
	end
	
	local useGroupRoute 
	if not vars.useGroupRoute then
		useGroupRoute = vars.gpData
	else
		useGroupRoute = vars.useGroupRoute
	end
	local routeProvided = false
	if not vars.route then
		if useGroupRoute then
			tempRoute = routines.getGroupRoute(useGroupRoute)
		end
	else
		useRoute = vars.route
		local posStart = routines.getLeadPos(gpData)
		useRoute[1] = routines.ground.buildWP(posStart, useRoute[1].action, useRoute[1].speed)
		routeProvided = true
	end
	
	
	local overRideSpeed = vars.speed or 'default'
	local pType = vars.pType 
	local offRoadForm = vars.offRoadForm or 'default'
	local onRoadForm = vars.onRoadForm or 'default'
		
	if routeProvided == false and #tempRoute > 0 then
		local posStart = routines.getLeadPos(gpData)
		
		
		useRoute[#useRoute + 1] = routines.ground.buildWP(posStart, offRoadForm, overRideSpeed)
		for i = 1, #tempRoute do
			local tempForm = tempRoute[i].action
			local tempSpeed = tempRoute[i].speed
			
			if offRoadForm == 'default' then
				tempForm = tempRoute[i].action
			end
			if onRoadForm == 'default' then
				onRoadForm = 'On Road'
			end
			if (string.lower(tempRoute[i].action) == 'on road' or  string.lower(tempRoute[i].action) == 'onroad' or string.lower(tempRoute[i].action) == 'on_road') then
				tempForm = onRoadForm
			else
				tempForm = offRoadForm
			end
			
			if type(overRideSpeed) == 'number' then
				tempSpeed = overRideSpeed
			end
			
			
			useRoute[#useRoute + 1] = routines.ground.buildWP(tempRoute[i], tempForm, tempSpeed)
		end
			
		if pType and string.lower(pType) == 'doubleback' then
			local curRoute = routines.utils.deepCopy(useRoute)
			for i = #curRoute, 2, -1 do
				useRoute[#useRoute + 1] = routines.ground.buildWP(curRoute[i], curRoute[i].action, curRoute[i].speed)
			end
		end
		
		useRoute[1].action = useRoute[#useRoute].action -- make it so the first WP matches the last WP
	end
	
	local cTask3 = {}
	local newPatrol = {}
	newPatrol.route = useRoute
	newPatrol.gpData = gpData:getName()
	cTask3[#cTask3 + 1] = 'routines.ground.patrolRoute('
	cTask3[#cTask3 + 1] = routines.utils.oneLineSerialize(newPatrol)
	cTask3[#cTask3 + 1] = ')'
	cTask3 = table.concat(cTask3)
	local tempTask = {
		id = 'WrappedAction', 
		params = { 
			action = {
				id = 'Script',
				params = {
					command = cTask3, 
					
				},
			},
		},
	}

		
	useRoute[#useRoute].task = tempTask
	routines.goRoute(gpData, useRoute)
	
	return
end

routines.ground.patrol = function(gpData, pType, form, speed)
	local vars = {}
	
	if type(gpData) == 'table' and gpData:getName() then
		gpData = gpData:getName()
	end
	
	vars.useGroupRoute = gpData
	vars.gpData = gpData
	vars.pType = pType
	vars.offRoadForm = form
	vars.speed = speed
	
	routines.ground.patrolRoute(vars)

	return
end

function routines.GetUnitHeight( CheckUnit )
trace.f( "routines" )

	local UnitPoint = CheckUnit:getPoint()
	local UnitPosition = { x = UnitPoint.x, y = UnitPoint.z }
	local UnitHeight = UnitPoint.y

	local LandHeight = land.getHeight( UnitPosition )

	--env.info(( 'CarrierHeight: LandHeight = ' .. LandHeight .. ' CarrierHeight = ' .. CarrierHeight ))

	trace.f( "routines", "Unit Height = " .. UnitHeight - LandHeight )
	
	return UnitHeight - LandHeight

end



Su34Status = { status = {} }
boardMsgRed = { statusMsg = "" }
boardMsgAll = { timeMsg = "" }
SpawnSettings = {}
Su34MenuPath = {}
Su34Menus = 0


function Su34AttackCarlVinson(groupName)
trace.menu("", "Su34AttackCarlVinson")
	local groupSu34 = Group.getByName( groupName )
	local controllerSu34 = groupSu34.getController(groupSu34)
	local groupCarlVinson = Group.getByName("US Carl Vinson #001")
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE )
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
	if groupCarlVinson ~= nil then
		controllerSu34.pushTask(controllerSu34,{id = 'AttackGroup', params = { groupId = groupCarlVinson:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = true}})
	end
	Su34Status.status[groupName] = 1
	MessageToRed( string.format('%s: ',groupName) .. 'Attacking carrier Carl Vinson. ', 10, 'RedStatus' .. groupName )
end

function Su34AttackWest(groupName)
trace.f("","Su34AttackWest")
	local groupSu34 = Group.getByName( groupName )
	local controllerSu34 = groupSu34.getController(groupSu34)
	local groupShipWest1 = Group.getByName("US Ship West #001")
	local groupShipWest2 = Group.getByName("US Ship West #002")
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE )
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
	if groupShipWest1 ~= nil then
		controllerSu34.pushTask(controllerSu34,{id = 'AttackGroup', params = { groupId = groupShipWest1:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = true}})
	end
	if groupShipWest2 ~= nil then
		controllerSu34.pushTask(controllerSu34,{id = 'AttackGroup', params = { groupId = groupShipWest2:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = true}})
	end
	Su34Status.status[groupName] = 2
	MessageToRed( string.format('%s: ',groupName) .. 'Attacking invading ships in the west. ', 10, 'RedStatus' .. groupName )
end

function Su34AttackNorth(groupName)
trace.menu("","Su34AttackNorth")
	local groupSu34 = Group.getByName( groupName )
	local controllerSu34 = groupSu34.getController(groupSu34)
	local groupShipNorth1 = Group.getByName("US Ship North #001")
	local groupShipNorth2 = Group.getByName("US Ship North #002")
	local groupShipNorth3 = Group.getByName("US Ship North #003")
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE )
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
	if groupShipNorth1 ~= nil then
		controllerSu34.pushTask(controllerSu34,{id = 'AttackGroup', params = { groupId = groupShipNorth1:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = false}})
	end
	if groupShipNorth2 ~= nil then
		controllerSu34.pushTask(controllerSu34,{id = 'AttackGroup', params = { groupId = groupShipNorth2:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = false}})
	end
	if groupShipNorth3 ~= nil then
		controllerSu34.pushTask(controllerSu34,{id = 'AttackGroup', params = { groupId = groupShipNorth3:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = false}})
	end
	Su34Status.status[groupName] = 3
	MessageToRed( string.format('%s: ',groupName) .. 'Attacking invading ships in the north. ', 10, 'RedStatus' .. groupName )
end

function Su34Orbit(groupName)
trace.menu("","Su34Orbit")
	local groupSu34 = Group.getByName( groupName )
	local controllerSu34 = groupSu34:getController()
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
	controllerSu34:pushTask( {id = 'ControlledTask', params = { task = { id = 'Orbit', params = { pattern = AI.Task.OrbitPattern.RACE_TRACK } }, stopCondition = { duration = 600 } } } )
	Su34Status.status[groupName] = 4
	MessageToRed( string.format('%s: ',groupName) .. 'In orbit and awaiting further instructions. ', 10, 'RedStatus' .. groupName )
end

function Su34TakeOff(groupName)
trace.menu("","Su34TakeOff")
	local groupSu34 = Group.getByName( groupName )
	local controllerSu34 = groupSu34:getController()
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE )
	Su34Status.status[groupName] = 8
	MessageToRed( string.format('%s: ',groupName) .. 'Take-Off. ', 10, 'RedStatus' .. groupName )
end

function Su34Hold(groupName)
trace.menu("","Su34Hold")
	local groupSu34 = Group.getByName( groupName )
	local controllerSu34 = groupSu34:getController()
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE )
	Su34Status.status[groupName] = 5
	MessageToRed( string.format('%s: ',groupName) .. 'Holding Weapons. ', 10, 'RedStatus' .. groupName )
end

function Su34RTB(groupName)
trace.menu("","Su34RTB")
	Su34Status.status[groupName] = 6
	MessageToRed( string.format('%s: ',groupName) .. 'Return to Krasnodar. ', 10, 'RedStatus' .. groupName )
end

function Su34Destroyed(groupName)
trace.menu("","Su34Destroyed")
	Su34Status.status[groupName] = 7
	MessageToRed( string.format('%s: ',groupName) .. 'Destroyed. ', 30, 'RedStatus' .. groupName )
end

function GroupAlive( groupName )
trace.menu("","GroupAlive")
	local groupTest = Group.getByName( groupName )

	local groupExists = false

	if groupTest then
		groupExists = groupTest:isExist()
	end

	trace.r( "", "", { groupExists } )
	return groupExists
end

function Su34IsDead()
trace.f()

end

function Su34OverviewStatus()
trace.menu("","Su34OverviewStatus")
	local msg = ""
	local currentStatus = 0
	local Exists = false

	for groupName, currentStatus in pairs(Su34Status.status) do

		env.info(('Su34 Overview Status: GroupName = ' .. groupName ))
		Alive = GroupAlive( groupName )

		if Alive then
			if currentStatus == 1 then
				msg = msg .. string.format("%s: ",groupName)
				msg = msg .. "Attacking carrier Carl Vinson. "
			elseif currentStatus == 2 then
				msg = msg .. string.format("%s: ",groupName)
				msg = msg .. "Attacking supporting ships in the west. "
			elseif currentStatus == 3 then
				msg = msg .. string.format("%s: ",groupName)
				msg = msg .. "Attacking invading ships in the north. "
			elseif currentStatus == 4 then
				msg = msg .. string.format("%s: ",groupName)
				msg = msg .. "In orbit and awaiting further instructions. "
			elseif currentStatus == 5 then
				msg = msg .. string.format("%s: ",groupName)
				msg = msg .. "Holding Weapons. "
			elseif currentStatus == 6 then
				msg = msg .. string.format("%s: ",groupName)
				msg = msg .. "Return to Krasnodar. "
			elseif currentStatus == 7 then
				msg = msg .. string.format("%s: ",groupName)
				msg = msg .. "Destroyed. "
			elseif currentStatus == 8 then
				msg = msg .. string.format("%s: ",groupName)
				msg = msg .. "Take-Off. "
			end
		else
			if currentStatus == 7 then
				msg = msg .. string.format("%s: ",groupName)
				msg = msg .. "Destroyed. "
			else
				Su34Destroyed(groupName)
			end
		end
	end

	boardMsgRed.statusMsg = msg
end


function UpdateBoardMsg()
trace.f()
	Su34OverviewStatus()
	MessageToRed( boardMsgRed.statusMsg, 15, 'RedStatus' )
end

function MusicReset( flg )
trace.f()
	trigger.action.setUserFlag(95,flg)
end

function PlaneActivate(groupNameFormat, flg)
trace.f()
	local groupName = groupNameFormat .. string.format("#%03d", trigger.misc.getUserFlag(flg))
	--trigger.action.outText(groupName,10)
	trigger.action.activateGroup(Group.getByName(groupName))
end

function Su34Menu(groupName)
trace.f()

	--env.info(( 'Su34Menu(' .. groupName .. ')' ))
	local groupSu34 = Group.getByName( groupName )

	if Su34Status.status[groupName] == 1 or
	   Su34Status.status[groupName] == 2 or
	   Su34Status.status[groupName] == 3 or
	   Su34Status.status[groupName] == 4 or
	   Su34Status.status[groupName] == 5 then
		if Su34MenuPath[groupName] == nil then
			if planeMenuPath == nil then
				planeMenuPath = missionCommands.addSubMenuForCoalition(
					coalition.side.RED,
					"SU-34 anti-ship flights",
					nil
				)
			end
			Su34MenuPath[groupName] = missionCommands.addSubMenuForCoalition(
				coalition.side.RED,
				"Flight " .. groupName,
				planeMenuPath
			)

			missionCommands.addCommandForCoalition(
				coalition.side.RED,
				"Attack carrier Carl Vinson",
				Su34MenuPath[groupName],
				Su34AttackCarlVinson,
				groupName
			)

			missionCommands.addCommandForCoalition(
				coalition.side.RED,
				"Attack ships in the west",
				Su34MenuPath[groupName],
				Su34AttackWest,
				groupName
			)

			missionCommands.addCommandForCoalition(
				coalition.side.RED,
				"Attack ships in the north",
				Su34MenuPath[groupName],
				Su34AttackNorth,
				groupName
			)

			missionCommands.addCommandForCoalition(
				coalition.side.RED,
				"Hold position and await instructions",
				Su34MenuPath[groupName],
				Su34Orbit,
				groupName
			)

			missionCommands.addCommandForCoalition(
				coalition.side.RED,
				"Report status",
				Su34MenuPath[groupName],
				Su34OverviewStatus
			)
		end
	else
		if Su34MenuPath[groupName] then
			missionCommands.removeItemForCoalition(coalition.side.RED, Su34MenuPath[groupName])
		end
	end
end

--- Obsolete function, but kept to rework in framework.

function ChooseInfantry ( TeleportPrefixTable, TeleportMax )
trace.f("Spawn")
	--env.info(( 'ChooseInfantry: ' ))

	TeleportPrefixTableCount = #TeleportPrefixTable
	TeleportPrefixTableIndex = math.random( 1, TeleportPrefixTableCount )

	--env.info(( 'ChooseInfantry: TeleportPrefixTableIndex = ' .. TeleportPrefixTableIndex .. ' TeleportPrefixTableCount = ' .. TeleportPrefixTableCount  .. ' TeleportMax = ' .. TeleportMax ))

	local TeleportFound = false
	local TeleportLoop = true
	local Index = TeleportPrefixTableIndex
	local TeleportPrefix = ''

	while TeleportLoop do
		TeleportPrefix = TeleportPrefixTable[Index]
		if SpawnSettings[TeleportPrefix] then
			if SpawnSettings[TeleportPrefix]['SpawnCount'] - 1 < TeleportMax then
				SpawnSettings[TeleportPrefix]['SpawnCount'] = SpawnSettings[TeleportPrefix]['SpawnCount'] + 1
				TeleportFound = true
			else
				TeleportFound = false
			end
		else
			SpawnSettings[TeleportPrefix] = {}
			SpawnSettings[TeleportPrefix]['SpawnCount'] = 0
			TeleportFound = true
		end
		if TeleportFound then
			TeleportLoop = false
		else
			if Index < TeleportPrefixTableCount then
				Index = Index + 1
			else
				TeleportLoop = false
			end
		end
		--env.info(( 'ChooseInfantry: Loop 1 - TeleportPrefix = ' .. TeleportPrefix .. ' Index = ' .. Index ))
	end

	if TeleportFound == false then
		TeleportLoop = true
		Index = 1
		while TeleportLoop do
			TeleportPrefix = TeleportPrefixTable[Index]
			if SpawnSettings[TeleportPrefix] then
				if SpawnSettings[TeleportPrefix]['SpawnCount'] - 1 < TeleportMax then
					SpawnSettings[TeleportPrefix]['SpawnCount'] = SpawnSettings[TeleportPrefix]['SpawnCount'] + 1
					TeleportFound = true
				else
					TeleportFound = false
				end
			else
				SpawnSettings[TeleportPrefix] = {}
				SpawnSettings[TeleportPrefix]['SpawnCount'] = 0
				TeleportFound = true
			end
			if TeleportFound then
				TeleportLoop = false
			else
				if Index < TeleportPrefixTableIndex then
					Index = Index + 1
				else
					TeleportLoop = false
				end
			end
		--env.info(( 'ChooseInfantry: Loop 2 - TeleportPrefix = ' .. TeleportPrefix .. ' Index = ' .. Index ))
		end
	end

	local TeleportGroupName = ''
	if TeleportFound == true then
		TeleportGroupName = TeleportPrefix .. string.format("#%03d", SpawnSettings[TeleportPrefix]['SpawnCount'] )
	else
		TeleportGroupName = ''
	end

	--env.info(('ChooseInfantry: TeleportGroupName = ' .. TeleportGroupName ))
	--env.info(('ChooseInfantry: return'))

	return TeleportGroupName
end

SpawnedInfantry = 0

function LandCarrier ( CarrierGroup, LandingZonePrefix )
trace.f()
	--env.info(( 'LandCarrier: ' ))
	--env.info(( 'LandCarrier: CarrierGroup = ' .. CarrierGroup:getName() ))
	--env.info(( 'LandCarrier: LandingZone = ' .. LandingZonePrefix ))

	local controllerGroup = CarrierGroup:getController()

	local LandingZone = trigger.misc.getZone(LandingZonePrefix)
	local LandingZonePos = {}
	LandingZonePos.x = LandingZone.point.x + math.random(LandingZone.radius * -1, LandingZone.radius)
	LandingZonePos.y = LandingZone.point.z + math.random(LandingZone.radius * -1, LandingZone.radius)

	controllerGroup:pushTask( { id = 'Land', params = { point = LandingZonePos, durationFlag = true, duration = 10 } } )

	--env.info(( 'LandCarrier: end' ))
end

EscortCount = 0
function EscortCarrier ( CarrierGroup, EscortPrefix, EscortLastWayPoint, EscortEngagementDistanceMax, EscortTargetTypes )
trace.f()
	--env.info(( 'EscortCarrier: ' ))
	--env.info(( 'EscortCarrier: CarrierGroup = ' .. CarrierGroup:getName() ))
	--env.info(( 'EscortCarrier: EscortPrefix = ' .. EscortPrefix ))

	local CarrierName = CarrierGroup:getName()

	local EscortMission = {}
	local CarrierMission = {}

	local EscortMission =  SpawnMissionGroup( EscortPrefix )
	local CarrierMission = SpawnMissionGroup( CarrierGroup:getName() )

	if EscortMission ~= nil and CarrierMission ~= nil then

		EscortCount = EscortCount + 1
		EscortMissionName = string.format( EscortPrefix .. '#Escort %s', CarrierName )
		EscortMission.name = EscortMissionName
		EscortMission.groupId = nil
		EscortMission.lateActivation = false
		EscortMission.taskSelected = false

		local EscortUnits = #EscortMission.units
		for u = 1, EscortUnits do
			EscortMission.units[u].name = string.format( EscortPrefix .. '#Escort %s %02d', CarrierName, u )
			EscortMission.units[u].unitId = nil
		end


		EscortMission.route.points[1].task =  { id = "ComboTask",
                                                params =
                                                {
                                                    tasks =
                                                    {
                                                        [1] =
                                                        {
                                                            enabled = true,
                                                            auto = false,
                                                            id = "Escort",
                                                            number = 1,
                                                            params =
                                                            {
                                                                lastWptIndexFlagChangedManually = false,
                                                                groupId = CarrierGroup:getID(),
                                                                lastWptIndex = nil,
                                                                lastWptIndexFlag = false,
																engagementDistMax = EscortEngagementDistanceMax,
																targetTypes = EscortTargetTypes,
                                                                pos =
                                                                {
                                                                    y = 20,
                                                                    x = 20,
                                                                    z = 0,
                                                                } -- end of ["pos"]
                                                            } -- end of ["params"]
                                                        } -- end of [1]
                                                    } -- end of ["tasks"]
                                                } -- end of ["params"]
                                            } -- end of ["task"]

		SpawnGroupAdd( EscortPrefix, EscortMission )

	end
end

function SendMessageToCarrier( CarrierGroup, CarrierMessage )
trace.f()

	if CarrierGroup ~= nil then
		MessageToGroup( CarrierGroup, CarrierMessage, 30, 'Carrier/' .. CarrierGroup:getName() )
	end

end

function MessageToGroup( MsgGroup, MsgText, MsgTime, MsgName )
trace.f()

	if type(MsgGroup) == 'string' then
		--env.info( 'MessageToGroup: Converted MsgGroup string "' .. MsgGroup .. '" into a Group structure.' )
		MsgGroup = Group.getByName( MsgGroup )
	end

	if MsgGroup ~= nil then
		local MsgTable = {}
		MsgTable.text = MsgText
		MsgTable.displayTime = MsgTime
		MsgTable.msgFor = { units = { MsgGroup:getUnits()[1]:getName() } }
		MsgTable.name = MsgName
		--routines.message.add( MsgTable )
		--env.info(('MessageToGroup: Message sent to ' .. MsgGroup:getUnits()[1]:getName() .. ' -> ' .. MsgText ))
	end
end

function MessageToUnit( UnitName, MsgText, MsgTime, MsgName )
trace.f()

	if UnitName ~= nil then
		local MsgTable = {}
		MsgTable.text = MsgText
		MsgTable.displayTime = MsgTime
		MsgTable.msgFor = { units = { UnitName } }
		MsgTable.name = MsgName
		--routines.message.add( MsgTable )
	end
end

function MessageToAll( MsgText, MsgTime, MsgName )
trace.f()

	MESSAGE:New( MsgText, "Message", MsgTime, MsgName ):ToCoalition( coalition.side.RED ):ToCoalition( coalition.side.BLUE )
end

function MessageToRed( MsgText, MsgTime, MsgName )
trace.f()

	MESSAGE:New( MsgText, "To Red Coalition", MsgTime, MsgName ):ToCoalition( coalition.side.RED )
end

function MessageToBlue( MsgText, MsgTime, MsgName )
trace.f()

	MESSAGE:New( MsgText, "To Blue Coalition", MsgTime, MsgName ):ToCoalition( coalition.side.RED )
end

function getCarrierHeight( CarrierGroup )
trace.f()

	if CarrierGroup ~= nil then
		if table.getn(CarrierGroup:getUnits()) == 1 then
			local CarrierUnit = CarrierGroup:getUnits()[1]
			local CurrentPoint = CarrierUnit:getPoint()

			local CurrentPosition = { x = CurrentPoint.x, y = CurrentPoint.z }
			local CarrierHeight = CurrentPoint.y

			local LandHeight = land.getHeight( CurrentPosition )

			--env.info(( 'CarrierHeight: LandHeight = ' .. LandHeight .. ' CarrierHeight = ' .. CarrierHeight ))

			return CarrierHeight - LandHeight
		else
			return 999999
		end
	else
		return 999999
	end

end

function GetUnitHeight( CheckUnit )
trace.f()

	local UnitPoint = CheckUnit:getPoint()
	local UnitPosition = { x = CurrentPoint.x, y = CurrentPoint.z }
	local UnitHeight = CurrentPoint.y

	local LandHeight = land.getHeight( CurrentPosition )

	--env.info(( 'CarrierHeight: LandHeight = ' .. LandHeight .. ' CarrierHeight = ' .. CarrierHeight ))

	return UnitHeight - LandHeight

end


_MusicTable = {}
_MusicTable.Files = {}
_MusicTable.Queue = {}
_MusicTable.FileCnt = 0


function MusicRegister( SndRef, SndFile, SndTime )
trace.f()

	env.info(( 'MusicRegister: SndRef = ' .. SndRef ))
	env.info(( 'MusicRegister: SndFile = ' .. SndFile ))
	env.info(( 'MusicRegister: SndTime = ' .. SndTime ))


	_MusicTable.FileCnt = _MusicTable.FileCnt + 1

	_MusicTable.Files[_MusicTable.FileCnt] = {}
	_MusicTable.Files[_MusicTable.FileCnt].Ref = SndRef
	_MusicTable.Files[_MusicTable.FileCnt].File = SndFile
	_MusicTable.Files[_MusicTable.FileCnt].Time = SndTime

	if not _MusicTable.Function then
		_MusicTable.Function = routines.scheduleFunction( MusicScheduler, { }, timer.getTime() + 10, 10)
	end

end

function MusicToPlayer( SndRef, PlayerName, SndContinue )
trace.f()

	--env.info(( 'MusicToPlayer: SndRef = ' .. SndRef  ))

	local PlayerUnits = AlivePlayerUnits()
	for PlayerUnitIdx, PlayerUnit in pairs(PlayerUnits) do
		local PlayerUnitName = PlayerUnit:getPlayerName()
		--env.info(( 'MusicToPlayer: PlayerUnitName = ' .. PlayerUnitName  ))
		if PlayerName == PlayerUnitName then
			PlayerGroup = PlayerUnit:getGroup()
			if PlayerGroup then
				--env.info(( 'MusicToPlayer: PlayerGroup = ' .. PlayerGroup:getName() ))
				MusicToGroup( SndRef, PlayerGroup, SndContinue )
			end
			break
		end
	end

	--env.info(( 'MusicToPlayer: end'  ))

end

function MusicToGroup( SndRef, SndGroup, SndContinue )
trace.f()

	--env.info(( 'MusicToGroup: SndRef = ' .. SndRef  ))

	if SndGroup ~= nil then
		if _MusicTable and _MusicTable.FileCnt > 0 then
			if SndGroup:isExist() then
				if MusicCanStart(SndGroup:getUnit(1):getPlayerName()) then
					--env.info(( 'MusicToGroup: OK for Sound.'  ))
					local SndIdx = 0
					if SndRef == '' then
						--env.info(( 'MusicToGroup: SndRef as empty. Queueing at random.'  ))
						SndIdx = math.random( 1, _MusicTable.FileCnt )
					else
						for SndIdx = 1, _MusicTable.FileCnt do
							if _MusicTable.Files[SndIdx].Ref == SndRef then
								break
							end
						end
					end
					--env.info(( 'MusicToGroup: SndIdx =  ' .. SndIdx ))
					--env.info(( 'MusicToGroup: Queueing Music ' .. _MusicTable.Files[SndIdx].File .. ' for Group ' ..  SndGroup:getID() ))
					trigger.action.outSoundForGroup( SndGroup:getID(), _MusicTable.Files[SndIdx].File )
					MessageToGroup( SndGroup, 'Playing ' .. _MusicTable.Files[SndIdx].File, 15, 'Music-' .. SndGroup:getUnit(1):getPlayerName() )

					local SndQueueRef = SndGroup:getUnit(1):getPlayerName()
					if _MusicTable.Queue[SndQueueRef] == nil then
						_MusicTable.Queue[SndQueueRef] = {}
					end
					_MusicTable.Queue[SndQueueRef].Start = timer.getTime()
					_MusicTable.Queue[SndQueueRef].PlayerName = SndGroup:getUnit(1):getPlayerName()
					_MusicTable.Queue[SndQueueRef].Group = SndGroup
					_MusicTable.Queue[SndQueueRef].ID = SndGroup:getID()
					_MusicTable.Queue[SndQueueRef].Ref = SndIdx
					_MusicTable.Queue[SndQueueRef].Continue = SndContinue
					_MusicTable.Queue[SndQueueRef].Type = Group
				end
			end
		end
	end
end

function MusicCanStart(PlayerName)
trace.f()

	--env.info(( 'MusicCanStart:' ))

	local MusicOut = false

	if _MusicTable['Queue'] ~= nil and _MusicTable.FileCnt > 0  then
		--env.info(( 'MusicCanStart: PlayerName = ' .. PlayerName ))
		local PlayerFound = false
		local MusicStart = 0
		local MusicTime = 0
		for SndQueueIdx, SndQueue in pairs( _MusicTable.Queue ) do
			if SndQueue.PlayerName == PlayerName then
				PlayerFound = true
				MusicStart = SndQueue.Start
				MusicTime = _MusicTable.Files[SndQueue.Ref].Time
				break
			end
		end
		if PlayerFound then
			--env.info(( 'MusicCanStart: MusicStart = ' .. MusicStart ))
			--env.info(( 'MusicCanStart: MusicTime = ' .. MusicTime ))
			--env.info(( 'MusicCanStart: timer.getTime() = ' .. timer.getTime() ))

			if MusicStart + MusicTime <= timer.getTime() then
				MusicOut = true
			end
		else
			MusicOut = true
		end
	end

	if MusicOut then
		--env.info(( 'MusicCanStart: true' ))
	else
		--env.info(( 'MusicCanStart: false' ))
	end

	return MusicOut
end

function MusicScheduler()
trace.scheduled("", "MusicScheduler")

	--env.info(( 'MusicScheduler:' ))
	if _MusicTable['Queue'] ~= nil and _MusicTable.FileCnt > 0  then
		--env.info(( 'MusicScheduler: Walking Sound Queue.'))
		for SndQueueIdx, SndQueue in pairs( _MusicTable.Queue ) do
			if SndQueue.Continue then
				if MusicCanStart(SndQueue.PlayerName) then
					--env.info(('MusicScheduler: MusicToGroup'))
					MusicToPlayer( '', SndQueue.PlayerName, true )
				end
			end
		end
	end

end


env.info(( 'Init: Scripts Loaded v1.1' ))

--- BASE The base class for all the classes defined within MOOSE.
-- @classmod BASE
-- @author Flightcontrol

Include.File( "Routines" )

_TraceOn = true
_TraceClass = {
	--DATABASE = true,
	--SEAD = true,
	--DESTROYBASETASK = true,
	--MOVEMENT = true,
	--SPAWN = true,
	--STAGE = true,
	--ZONE = true,
	--GROUP = true,
	--UNIT = true,
	--CLIENT = true,
	--CARGO = true,
	--CARGO_GROUP = true,
	--CARGO_PACKAGE = true,
	--CARGO_SLINGLOAD = true,
	--CARGO_ZONE = true,
	--CLEANUP = true,
	}

BASE = {

  ClassName = "BASE",
  ClassID = 0,
  Events = {}
}

--- The base constructor. This is the top top class of all classed defined within the MOOSE.
-- Any new class needs to be derived from this class for proper inheritance.
-- @treturn BASE
-- @usage
-- function TASK:New()
-- trace.f(self.ClassName)
--
--     local self = BASE:Inherit( self, BASE:New() )
-- 
--     -- assign Task default values during construction
--     self.TaskBriefing = "Task: No Task."
--     self.Time = timer.getTime()
--     self.ExecuteStage = _TransportExecuteStage.NONE
-- 
--     return self
-- end
-- @todo need to investigate if the deepCopy is really needed... Don't think so.

function BASE:New()
	local Child = routines.utils.deepCopy( self )
	local Parent = {}
	setmetatable( Child, Parent )
	Child.__index = Child
	self.ClassID = self.ClassID + 1
	Child.ClassID = self.ClassID
	--Child.AddEvent( Child, S_EVENT_BIRTH, Child.EventBirth )
	return Child
end

--- This is the worker method to inherit from a parent class.
-- @param Child is the Child class that inherits.
-- @param Parent is the Parent class that the Child inherits from.
-- @return Child
function BASE:Inherit( Child, Parent )
	local Child = routines.utils.deepCopy( Child )
	local Parent = routines.utils.deepCopy( Parent )
	if Child ~= nil then
		setmetatable( Child, Parent )
		Child.__index = Child
	end
	--Child.ClassName = Child.ClassName .. '.' .. Child.ClassID
	self:T( 'Inherited from ' .. Parent.ClassName ) 
	return Child
end

--- This is the worker method to retrieve the Parent class.
-- @tparam BASE Child is the Child class from which the Parent class needs to be retrieved.
-- @treturn Parent
function BASE:Inherited( Child )
	local Parent = getmetatable( Child )
--	env.info('Inherited class of ' .. Child.ClassName .. ' is ' .. Parent.ClassName )
	return Parent
end

function BASE:AddEvent( Event, EventFunction )
trace.f( self.ClassName, Event )

	self.Events[#self.Events+1] = {}
	self.Events[#self.Events].Event = Event
	self.Events[#self.Events].EventFunction = EventFunction
	self.Events[#self.Events].EventEnabled = false

	return self
end


function BASE:EnableEvents()
trace.f( self.ClassName )

	trace.i( self.ClassName, #self.Events )
	for EventID, Event in pairs( self.Events ) do
		Event.Self = self
		Event.EventEnabled = true
	end
	--env.info( 'EnableEvent Table Task = ' .. tostring(self) )
	self.Events.Handler = world.addEventHandler( self )

	return self
end

function BASE:DisableEvents()
trace.f( self.ClassName )

	world.removeEventHandler( self )
	for EventID, Event in pairs( self.Events ) do
		Event.Self = nil
		Event.EventEnabled = false
	end

	return self
end


BaseEventCodes = {
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
 
--onEvent( {[1]="S_EVENT_BIRTH",[2]={["subPlace"]=5,["time"]=0,["initiator"]={["id_"]=16884480,},["place"]={["id_"]=5000040,},["id"]=15,["IniUnitName"]="US F-15C@RAMP-Air Support Mountains#001-01",},}
-- Event = {
--   id = enum world.event,
--   time = Time,
--   initiator = Unit,
--   target = Unit,
--   place = Unit,
--   subPlace = enum world.BirthPlace,
--   weapon = Weapon
-- }


function BASE:CreateEventBirth( EventTime, Initiator, IniUnitName, place, subplace )
trace.f( self.ClassName, { EventTime, Initiator, IniUnitName, place, subplace } )

	local Event = {
		id = world.event.S_EVENT_BIRTH,
		time = EventTime,
		initiator = Initiator,
		IniUnitName = IniUnitName,
		place = place,
		subplace = subplace
		}

	world.onEvent( Event )
end

function BASE:CreateEventCrash( EventTime, Initiator )
trace.f( self.ClassName, { EventTime, Initiator } )

	local Event = {
		id = world.event.S_EVENT_CRASH,
		time = EventTime,
		initiator = Initiator,
		}

	world.onEvent( Event )
end
												
function BASE:onEvent(event)
--trace.f(self.ClassName, event )

	--env.info( 'onEvent Table self = ' .. tostring(self) )
	if self then
		for EventID, EventObject in pairs( self.Events ) do
			if EventObject.EventEnabled then
				--env.info( 'onEvent Table EventObject.Self = ' .. tostring(EventObject.Self) )
				--env.info( 'onEvent event.id = ' .. tostring(event.id) )
				--env.info( 'onEvent EventObject.Event = ' .. tostring(EventObject.Event) )
				if event.id == EventObject.Event then
					if self == EventObject.Self then
						if event.initiator and event.initiator:isExist() then
							event.IniUnitName = event.initiator:getName()
						end
						if event.target and event.target:isExist() then
							event.TgtUnitName = event.target:getName()
						end
						trace.i( self.ClassName, { BaseEventCodes[event.id], event } )
						EventObject.EventFunction( self, event )
					end
				end
			end
		end
	end

end

-- Trace section

-- Log a trace (only shown when trace is on)
function BASE:T( Arguments )

	if _TraceOn and _TraceClass[self.ClassName] then

		local DebugInfoCurrent = debug.getinfo( 2, "nl" )
		local DebugInfoFrom = debug.getinfo( 3, "l" )
		
		local Function = "function"
		if DebugInfoCurrent.name then
			Function = DebugInfoCurrent.name
		end

		local LineCurrent = DebugInfoCurrent.currentline
		local LineFrom = DebugInfoFrom.currentline
	
		env.info( string.format( "%6d\(%6d\)/%1s:%20s%05d.%s\(%s\)" , LineCurrent, LineFrom, "T", self.ClassName, self.ClassID, Function, routines.utils.oneLineSerialize( Arguments ) ) )
	end
end


-- Log an exception
function BASE:E( Arguments )

	local DebugInfoCurrent = debug.getinfo( 2, "nl" )
	local DebugInfoFrom = debug.getinfo( 3, "l" )
	
	local Function = "function"
	if DebugInfoCurrent.name then
		Function = DebugInfoCurrent.name
	end

	local LineCurrent = DebugInfoCurrent.currentline
	local LineFrom = DebugInfoFrom.currentline

	env.info( string.format( "%6d\(%6d\)/%1s:%20s%05d.%s\(%s\)" , LineCurrent, LineFrom, "E", self.ClassName, self.ClassID, Function, routines.utils.oneLineSerialize( Arguments ) ) )
end
--- Encapsulation of DCS World Menu system in a set of MENU classes.
-- @classmod MENU

Include.File( "Routines" )
Include.File( "Base" )


MENU = {
  ClassName = "MENU",
  MenuPath = nil,
  MenuText = "",
  MenuParentPath = nil
}

---
function MENU:New( MenuText, MenuParentPath )

	-- Arrange meta tables
	local Child = BASE:Inherit( self, BASE:New() )

	Child.MenuPath = nil 
	Child.MenuText = MenuText
	Child.MenuParentPath = MenuParentPath
	return Child
end

COMMANDMENU = {
  ClassName = "COMMANDMENU",
  CommandMenuFunction = nil,
  CommandMenuArgument = nil
}

function COMMANDMENU:New( MenuText, ParentMenu, CommandMenuFunction, CommandMenuArgument )

	-- Arrange meta tables
	
	local MenuParentPath = nil
	if ParentMenu ~= nil then
		MenuParentPath = ParentMenu.MenuPath
	end

	local Child = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )

	Child.MenuPath = missionCommands.addCommand( MenuText, MenuParentPath, CommandMenuFunction, CommandMenuArgument )
	Child.CommandMenuFunction = CommandMenuFunction
	Child.CommandMenuArgument = CommandMenuArgument
	return Child
end

---

SUBMENU = {
  ClassName = "SUBMENU"
}

function SUBMENU:New( MenuText, ParentMenu )

	-- Arrange meta tables
	local MenuParentPath = nil
	if ParentMenu ~= nil then
		MenuParentPath = ParentMenu.MenuPath
	end

	local Child = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )

	Child.MenuPath = missionCommands.addSubMenu( MenuText, MenuParentPath )
	return Child
end

MENU_SUB_GROUP = {
  ClassName = "MENU_SUB_GROUP"
}

function MENU_SUB_GROUP:New( GroupID, MenuText, ParentMenu )

	-- Arrange meta tables
	local MenuParentPath = nil
	if ParentMenu ~= nil then
		MenuParentPath = ParentMenu.MenuPath
	end

	local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )

	self.MenuPath = missionCommands.addSubMenuForGroup( GroupID, MenuText, MenuParentPath )
	return self
end

MENU_COMMAND_GROUP = {
  ClassName = "MENU_COMMAND_GROUP"
}

function MENU_COMMAND_GROUP:New( GroupID, MenuText, ParentMenu, CommandMenuFunction, CommandMenuArgument )

	-- Arrange meta tables
	
	local MenuParentPath = nil
	if ParentMenu ~= nil then
		MenuParentPath = ParentMenu.MenuPath
	end

	local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )

	self.MenuPath = missionCommands.addCommandForGroup( GroupID, MenuText, MenuParentPath, CommandMenuFunction, CommandMenuArgument )
	self.CommandMenuFunction = CommandMenuFunction
	self.CommandMenuArgument = CommandMenuArgument
	return self
end
--- GROUP Classes
-- @classmod GROUP

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )
Include.File( "Unit" )

GROUPS = {}


GROUP = {
	ClassName="GROUP",
	}
	
function GROUP:New( DCSGroup )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( DCSGroup:getName() )

	self.DCSGroup = DCSGroup
	self.GroupName = DCSGroup:getName()
	self.GroupID = DCSGroup:getID()
	self.Controller = DCSGroup:getController()

	return self
end


function GROUP:NewFromName( GroupName )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( GroupName )

	self.DCSGroup = Group.getByName( GroupName )
	if self.DCSGroup then
		self.GroupName = self.DCSGroup:getName()
		self.GroupID = self.DCSGroup:getID()
	end

	return self
end

function GROUP:GetDCSGroup()
	self:T( { self.GroupName } )
	self.DCSGroup = Group.getByName( self.GroupName )
	return self.DCSGroup
end

function GROUP:GetDCSUnit( UnitNumber )
	self:T( { self.GroupName, UnitNumber } )
	return self.DCSGroup:getUnit( UnitNumber )

end

function GROUP:Activate()
	self:T( { self.GroupName } )
	trigger.action.activateGroup( self:GetDCSGroup() )
	return self:GetDCSGroup()
end

function GROUP:GetName()
	self:T( self.GroupName )
	
	return self.GroupName
end

function GROUP:GetPoint()
	self:T( self.GroupName )
	
	local GroupPoint = self:GetUnit(1):GetPoint()
	self:T( GroupPoint )
	return GroupPoint
end


function GROUP:Destroy()
	self:T( self.GroupName )
	
	for Index, UnitData in pairs( self.DCSGroup:getUnits() ) do
		self:CreateEventCrash( timer.getTime(), UnitData )
	end
	
	self.DCSGroup:destroy()
end




function GROUP:GetUnit( UnitNumber )
	self:T( { self.GroupName, UnitNumber } )
	return UNIT:New( self.DCSGroup:getUnit( UnitNumber ) )
end


function GROUP:IsAir()
self:T()
	
	local IsAirResult = self.DCSGroup:getCategory() == Group.Category.AIRPLANE or self.DCSGroup:getCategory() == Group.Category.HELICOPTER

	self:T( IsAirResult )
	return IsAirResult
end

function GROUP:IsAlive()
self:T()
	
	local IsAliveResult = self.DCSGroup and self.DCSGroup:isExist()

	self:T( IsAliveResult )
	return IsAliveResult
end


function GROUP:AllOnGround()
self:T()

	local AllOnGroundResult = true

	for Index, UnitData in pairs( self.DCSGroup:getUnits() ) do
		if UnitData:inAir() then
			AllOnGroundResult = false
		end
	end
	
	self:T( AllOnGroundResult )
	return AllOnGroundResult
end


function GROUP:GetMaxVelocity()
self:T()

	local MaxVelocity = 0
	
	for Index, UnitData in pairs( self.DCSGroup:getUnits() ) do

		local Velocity = UnitData:getVelocity()
		local VelocityTotal = math.abs( Velocity.x ) + math.abs( Velocity.y ) + math.abs( Velocity.z )

		if VelocityTotal < MaxVelocity then
			MaxVelocity = VelocityTotal
		end 
	end
	
	return MaxVelocity
end


function GROUP:GetHeight()
self:T()


end


function GROUP:Land( Point, Duration )
trace.f( self.ClassName, { self.GroupName, Point, Duration } )

	local Controller = self:_GetController()
	
	if Duration and Duration > 0 then
		Controller:pushTask( { id = 'Land', params = { point = Point, durationFlag = true, duration = Duration } } )
	else
		Controller:pushTask( { id = 'Land', params = { point = Point, durationFlag = false } } )
	end

	return self
end


function GROUP:Embarking( Point, Duration, EmbarkingGroup )
trace.f( self.ClassName, { self.GroupName, Point, Duration, EmbarkingGroup.DCSGroup } )

	local Controller = self:_GetController()
	
	trace.i( self.ClassName, EmbarkingGroup.GroupID )
	trace.i( self.ClassName, EmbarkingGroup.DCSGroup:getID() )
	trace.i( self.ClassName, EmbarkingGroup.DCSGroup.id )
	
	Controller:pushTask( { id = 'Embarking', 
	                       params = { x = Point.x, 
	                                  y = Point.y, 
									  duration = Duration, 
									  groupsForEmbarking = { EmbarkingGroup.GroupID },
									  durationFlag = true,
									  distributionFlag = false,
									  distribution = {},
									} 
						  } 
						)
	
	return self
end


function GROUP:EmbarkToTransport( Point, Radius )
trace.f( self.ClassName, { self.GroupName, Point, Radius } )

	local Controller = self:_GetController()
	
	Controller:pushTask( { id = 'EmbarkToTransport', 
	                       params = { x = Point.x, 
						              y = Point.y, 
									  zoneRadius = Radius,
									} 
						  } 
						)

	return self
end

function GROUP:Route( GoPoints )
self:T( GoPoints )

	local Points = routines.utils.deepCopy( GoPoints )
	local MissionTask = { id = 'Mission', params = { route = { points = Points, }, }, }
	
	--self.Controller.setTask( self.Controller, MissionTask )

	routines.scheduleFunction( self.Controller.setTask, { self.Controller, MissionTask}, timer.getTime() + 1 )
	
	return self
end

function GROUP:RouteToZone( Zone, Randomize, Speed, Formation )
	self:T( Zone )
	
	local GroupPoint = self:GetPoint()
	
	local PointFrom = {}
	PointFrom.x = GroupPoint.x
	PointFrom.y = GroupPoint.y
	PointFrom.type = "Turning Point"
	PointFrom.action = "Cone"
	PointFrom.speed = 20 / 1.6
	

	local PointTo = {}
	local ZonePoint 
	
	if Randomize then
		ZonePoint = Zone:GetRandomPoint()
	else
		ZonePoint = Zone:GetPoint()
	end

	PointTo.x = ZonePoint.x
	PointTo.y = ZonePoint.y
	PointTo.type = "Turning Point"
	
	if Formation then
		PointTo.action = Formation
	else
		PointTo.action = "Cone"
	end
	
	if Speed then
		PointTo.speed = Speed
	else
		PointTo.speed = 20 / 1.6
	end
	
	local Points = { PointFrom, PointTo }
	
	self:T( Points )
	
	self:Route( Points )
	
	return self
end

function GROUP:CopyRoute( Begin, End, Randomize, Radius )
self:T( { Begin, End } )

	local Points = {}
	
	-- Could be a Spawned Group
	local GroupName = string.match( self:GetName(), ".*#" )
	if GroupName then
		GroupName = GroupName:sub( 1, -2 )
	else
		GroupName = self:GetName()
	end
	
	self:T( { GroupName } )
	
	local Template = _Database.Groups[GroupName].Template
	
	if Template then
		if not Begin then
			Begin = 0
		end
		if not End then
			End = 0
		end
	
		for TPointID = Begin + 1, #Template.route.points - End do
			if Template.route.points[TPointID] then
				Points[#Points+1] = routines.utils.deepCopy( Template.route.points[TPointID] )
				if Randomize then
					if not Radius then
						Radius = 500
					end
					Points[#Points].x = Points[#Points].x + math.random( Radius * -1, Radius )
					Points[#Points].y = Points[#Points].y + math.random( Radius * -1, Radius )
				end	
			end
		end
		return Points
	end
	
	return nil
end


function GROUP:_GetController()

	return self.DCSGroup:getController()

end
--- UNIT Classes
-- @classmod UNIT

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

UNITS = {}


UNIT = {
	ClassName="UNIT",
	}
	
function UNIT:New( DCSUnit )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( DCSUnit:getName() )

	self.DCSUnit = DCSUnit
	self.UnitName = DCSUnit:getName()
	self.UnitID = DCSUnit:getID()

	return self
end

function UNIT:IsAlive()
	self:T( self.UnitName )
	
	return ( self.DCSUnit and self.DCSUnit:isExist() )
end


function UNIT:GetName()
	self:T( self.UnitName )
	
	return self.UnitName
end

function UNIT:GetTypeName()
	self:T( self.UnitName )
	
	return self.DCSUnit:getTypeName()
end

function UNIT:GetPrefix()
	self:T( self.UnitName )
	
	local UnitPrefix = string.match( self.UnitName, ".*#" ):sub( 1, -2 )
	self:T( UnitPrefix )

	return UnitPrefix
end


function UNIT:GetCallSign()
	self:T( self.UnitName )
	
	return self.DCSUnit:getCallsign()
end


function UNIT:GetPoint()
	self:T( self.UnitName )
	
	local UnitPos = self.DCSUnit:getPosition().p
	
	local UnitPoint = {}
	UnitPoint.x = UnitPos.x
	UnitPoint.y = UnitPos.z

	self:T( UnitPoint )
	return UnitPoint
end


function UNIT:GetPositionVec3()
	self:T( self.UnitName )
	
	local UnitPos = self.DCSUnit:getPosition().p

	self:T( UnitPos )
	return UnitPos
end

function UNIT:OtherUnitInRadius( AwaitUnit, Radius )
	self:T( { self.UnitName, AwaitUnit.UnitName, Radius } )

	local UnitPos = self:GetPositionVec3()
	local AwaitUnitPos = AwaitUnit:GetPositionVec3()

	if  (((UnitPos.x - AwaitUnitPos.x)^2 + (UnitPos.z - AwaitUnitPos.z)^2)^0.5 <= Radius) then
		self:T( "true" )
		return true
	else
		self:T( "false" )
		return false
	end

	self:T( "false" )
	return false
end

--- ZONE Classes
-- @classmod ZONE

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

ZONES = {}


ZONE = {
	ClassName="ZONE",
	}
	
function ZONE:New( ZoneName )
trace.f( self.ClassName, ZoneName )

	local self = BASE:Inherit( self, BASE:New() )

	local Zone = trigger.misc.getZone( ZoneName )
	
	if not Zone then
		error( "Zone " .. ZoneName .. " does not exist." )
		return nil
	end
	
	self.Zone = Zone
	self.ZoneName = ZoneName
	
	return self
end

function ZONE:GetPoint()
	self:T( self.ZoneName )

	local Zone = trigger.misc.getZone( self.ZoneName )
	local Point = { x = Zone.point.x, y = Zone.point.z }

	self:T( { Zone, Point } )
	
	return Point	
end

function ZONE:GetRandomPoint()
trace.f( self.ClassName, self.ZoneName )

	local Point = {}

	local Zone = trigger.misc.getZone( self.ZoneName )

	Point.x = Zone.point.x + math.random( Zone.radius * -1, Zone.radius )
	Point.y = Zone.point.z + math.random( Zone.radius * -1, Zone.radius )
	
	trace.i( self.ClassName, { Zone } )
	trace.i( self.ClassName, { Point } )
	
	return Point
end

function ZONE:GetRadius()
trace.f( self.ClassName, self.ZoneName )

	local Zone = trigger.misc.getZone( self.ZoneName )

	trace.i( self.ClassName, { Zone } )

	return Zone.radius
end

--- Administers the Initial Sets of the Mission Templates as defined within the Mission Editor.
-- Administers the Spawning of new Groups within the DCSRTE and administers these new Groups within the DATABASE object(s).
-- @classmod DATABASE

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Menu" )
Include.File( "Group" )

DATABASE = {
	ClassName = "DATABASE",
	Units = {},
	Groups = {},
	NavPoints = {},
	Statics = {},
	Players = {},
	ActivePlayers = {},
	ClientsByName = {},
	ClientsByID = {},
}

DATABASECoalition = 
{
	[1] = "Red",
	[2] = "Blue",
}

DATABASECategory = 
{
	[Unit.Category.AIRPLANE] = "Plane",
	[Unit.Category.HELICOPTER] = "Helicopter",
	[Unit.Category.GROUND_UNIT] = "Vehicle",
	[Unit.Category.SHIP] = "Ship",
	[Unit.Category.STRUCTURE] = "Structure",	
}


--- Creates a new DATABASE Object to administer the Groups defined and alive within the DCSRTE.
-- @treturn DATABASE
-- @usage
-- -- Define a new DATABASE Object. This DBObject will contain a reference to all Group and Unit Templates defined within the ME and the DCSRTE.
-- DBObject = DATABASE:New()
function DATABASE:New()

	-- Inherits from BASE
	local self = BASE:Inherit( self, BASE:New() )
  
	self.Navpoints = {}
	self.Units = {}
	 --Build routines.db.units and self.Navpoints
	for coa_name, coa_data in pairs(env.mission.coalition) do

		if (coa_name == 'red' or coa_name == 'blue') and type(coa_data) == 'table' then
			self.Units[coa_name] = {}
			
			----------------------------------------------
			-- build nav points DB
			self.Navpoints[coa_name] = {}
			if coa_data.nav_points then --navpoints
				for nav_ind, nav_data in pairs(coa_data.nav_points) do
					
					if type(nav_data) == 'table' then
						self.Navpoints[coa_name][nav_ind] = routines.utils.deepCopy(nav_data)

						self.Navpoints[coa_name][nav_ind]['name'] = nav_data.callsignStr  -- name is a little bit more self-explanatory.
						self.Navpoints[coa_name][nav_ind]['point'] = {}  -- point is used by SSE, support it.
						self.Navpoints[coa_name][nav_ind]['point']['x'] = nav_data.x
						self.Navpoints[coa_name][nav_ind]['point']['y'] = 0
						self.Navpoints[coa_name][nav_ind]['point']['z'] = nav_data.y
					end
				end
			end
			-------------------------------------------------		
			if coa_data.country then --there is a country table
				for cntry_id, cntry_data in pairs(coa_data.country) do
					
					local countryName = string.lower(cntry_data.name)
					self.Units[coa_name][countryName] = {}
					self.Units[coa_name][countryName]["countryId"] = cntry_data.id

					if type(cntry_data) == 'table' then  --just making sure
					
						for obj_type_name, obj_type_data in pairs(cntry_data) do
						
							if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then --should be an unncessary check 
								
								local category = obj_type_name
								
								if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then  --there's a group!
								
									self.Units[coa_name][countryName][category] = {}
									
									for group_num, GroupTemplate in pairs(obj_type_data.group) do
										
										if GroupTemplate and GroupTemplate.units and type(GroupTemplate.units) == 'table' then  --making sure again- this is a valid group
											self:_RegisterGroup( GroupTemplate )
										end --if GroupTemplate and GroupTemplate.units then
									end --for group_num, GroupTemplate in pairs(obj_type_data.group) do
								end --if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then
							end --if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then
						end --for obj_type_name, obj_type_data in pairs(cntry_data) do
					end --if type(cntry_data) == 'table' then
				end --for cntry_id, cntry_data in pairs(coa_data.country) do
			end --if coa_data.country then --there is a country table
		end --if coa_name == 'red' or coa_name == 'blue' and type(coa_data) == 'table' then
	end --for coa_name, coa_data in pairs(mission.coalition) do

	--self:AddEvent( world.event.S_EVENT_BIRTH, self.OnBirth )
	self:AddEvent( world.event.S_EVENT_DEAD, self.OnDeadOrCrash )
	self:AddEvent( world.event.S_EVENT_CRASH, self.OnDeadOrCrash )
	
	self:AddEvent( world.event.S_EVENT_HIT, self.OnHit)

	self:EnableEvents()

	self.SchedulerId = routines.scheduleFunction( DATABASE._FollowPlayers, { self }, 0, 5 )
	
	self:ScoreMenu()
	
	
	return self
end


--- Instantiate new Groups within the DCSRTE.
-- This method expects EXACTLY the same structure as a structure within the ME, and needs 2 additional fields defined:
-- SpawnCountryID, SpawnCategoryID
-- This method is used by the SPAWN class.
function DATABASE:Spawn( SpawnTemplate )

	self:T( { SpawnTemplate.SpawnCountryID, SpawnTemplate.SpawnCategoryID, SpawnTemplate.name } )
	
	-- Copy the spawn variables of the template in temporary storage, nullify, and restore the spawn variables.
	local SpawnCoalitionID = SpawnTemplate.SpawnCoalitionID
	local SpawnCountryID = SpawnTemplate.SpawnCountryID
	local SpawnCategoryID = SpawnTemplate.SpawnCategoryID
	
	-- Nullify
	SpawnTemplate.SpawnCoalitionID = nil
	SpawnTemplate.SpawnCountryID = nil
	SpawnTemplate.SpawnCategoryID = nil
	
	self:_RegisterGroup( SpawnTemplate )
	coalition.addGroup( SpawnCountryID, SpawnCategoryID, SpawnTemplate )

	-- Restore
	SpawnTemplate.SpawnCoalitionID = SpawnCoalitionID
	SpawnTemplate.SpawnCountryID = SpawnCountryID
	SpawnTemplate.SpawnCategoryID = SpawnCategoryID

	
	local SpawnGroup = GROUP:New( Group.getByName( SpawnTemplate.name ) )
	return SpawnGroup
end


--- Set a status to a Group within the Database, this to check crossing events for example.
function DATABASE:SetStatusGroup( GroupName, Status )
	self:T( Status )

	self.Groups[GroupName].Status = Status
end


--- Get a status to a Group within the Database, this to check crossing events for example.
function DATABASE:GetStatusGroup( GroupName )
	self:T( Status )

	if self.Groups[GroupName] then
		return self.Groups[GroupName].Status
	else
		return ""
	end
end


--- Private
-- @section Private


--- Registers new Group Templates within the DATABASE Object.
function DATABASE:_RegisterGroup( GroupTemplate )

	local GroupTemplateName = env.getValueDictByKey(GroupTemplate.name)

	if not self.Groups[GroupTemplateName] then
		self.Groups[GroupTemplateName] = {}
		self.Groups[GroupTemplateName].Status = nil
	end
	self.Groups[GroupTemplateName].GroupName = GroupTemplateName
	self.Groups[GroupTemplateName].Template = GroupTemplate
	self.Groups[GroupTemplateName].groupId = GroupTemplate.groupId
	self.Groups[GroupTemplateName].UnitCount = #GroupTemplate.units
	self.Groups[GroupTemplateName].Units = GroupTemplate.units
	
	self:T( { "Group", self.Groups[GroupTemplateName].GroupName, self.Groups[GroupTemplateName].UnitCount } )
						
	for unit_num, UnitTemplate in pairs(GroupTemplate.units) do
	
		local UnitTemplateName = env.getValueDictByKey(UnitTemplate.name)
		self.Units[UnitTemplateName] = {}
		self.Units[UnitTemplateName].UnitName = UnitTemplateName
		self.Units[UnitTemplateName].Template = UnitTemplate
		self.Units[UnitTemplateName].GroupName = GroupTemplateName
		self.Units[UnitTemplateName].GroupTemplate = GroupTemplate
		self.Units[UnitTemplateName].GroupId = GroupTemplate.groupId
		if UnitTemplate.skill and (UnitTemplate.skill == "Client" or UnitTemplate.skill == "Player") then
			self.ClientsByName[UnitTemplateName] = UnitTemplate
			self.ClientsByID[UnitTemplate.unitId] = UnitTemplate
		end
		self:T( { "Unit", self.Units[UnitTemplateName].UnitName } )
	end 
end


--- Events
-- @section Events


--- Track DCSRTE DEAD or CRASH events for the internal scoring.
function DATABASE:OnDeadOrCrash( event )
	--self:T( { event } )

	local TargetUnit = nil
	local TargetGroup = nil
	local TargetUnitName = ""
	local TargetGroupName = ""
	local TargetPlayerName = ""
	local TargetCoalition = nil
	local TargetCategory = nil
	local TargetType = nil
	local TargetUnitCoalition = nil
	local TargetUnitCategory = nil
	local TargetUnitType = nil

	if event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT then
	
		TargetUnit = event.initiator
		TargetGroup = Unit.getGroup( TargetUnit )
		TargetUnitDesc = TargetUnit:getDesc()
		
		TargetUnitName = TargetUnit:getName()
		if TargetGroup and TargetGroup:isExist() then
			TargetGroupName = TargetGroup:getName()
		end
		TargetPlayerName = TargetUnit:getPlayerName()

		TargetCoalition = TargetUnit:getCoalition()
		--TargetCategory = TargetUnit:getCategory()
		TargetCategory = TargetUnitDesc.category  -- Workaround
		TargetType = TargetUnit:getTypeName()

		TargetUnitCoalition = DATABASECoalition[TargetCoalition]
		TargetUnitCategory = DATABASECategory[TargetCategory]
		TargetUnitType = TargetType

		--self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType } )
	end

	for PlayerName, PlayerData in pairs( self.Players ) do
		if PlayerData then -- This should normally not happen, but i'll test it anyway.
			self:T( "Something got killed" )

			-- Some variables
			local InitUnitName = PlayerData.UnitName
			local InitUnitType = PlayerData.UnitType
			local InitCoalition = PlayerData.UnitCoalition
			local InitCategory = PlayerData.UnitCategory
			local InitUnitCoalition = DATABASECoalition[InitCoalition]
			local InitUnitCategory = DATABASECategory[InitCategory]
			
			self:T( { InitUnitName, InitUnitType, InitUnitCoalition, InitCoalition, InitUnitCategory, InitCategory } )

			-- What is he hitting?
			if TargetCategory then
				if PlayerData and PlayerData.Hit and PlayerData.Hit[TargetCategory] and PlayerData.Hit[TargetCategory][TargetUnitName] then -- Was there a hit for this unit for this player before registered???
					if not PlayerData.Kill[TargetCategory] then
						PlayerData.Kill[TargetCategory] = {}
					end
					if not PlayerData.Kill[TargetCategory][TargetType] then 
						PlayerData.Kill[TargetCategory][TargetType] = {}
						PlayerData.Kill[TargetCategory][TargetType].Score = 0
						PlayerData.Kill[TargetCategory][TargetType].ScoreKill = 0
						PlayerData.Kill[TargetCategory][TargetType].Penalty = 0
						PlayerData.Kill[TargetCategory][TargetType].PenaltyKill = 0
					end

					if InitCoalition == TargetCoalition then
						PlayerData.Kill[TargetCategory][TargetType].Penalty = PlayerData.Kill[TargetCategory][TargetType].Penalty + 25						
						PlayerData.Kill[TargetCategory][TargetType].PenaltyKill = PlayerData.Kill[TargetCategory][TargetType].PenaltyKill + 1
						MESSAGE:New( "Player '" .. PlayerName .. "' killed a friendly " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " .. 
									PlayerData.Kill[TargetCategory][TargetType].PenaltyKill .. " times. Penalty: -" .. PlayerData.Kill[TargetCategory][TargetType].Penalty, 
									"Game Status: Penalty", 20, "/PENALTY" .. PlayerName .. "/" .. InitUnitName ):ToAll()
						self:ScoreAdd( PlayerName, "KILL_PENALTY", 1, -125, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
					else
						PlayerData.Kill[TargetCategory][TargetType].Score = PlayerData.Kill[TargetCategory][TargetType].Score + 10						
						PlayerData.Kill[TargetCategory][TargetType].ScoreKill = PlayerData.Kill[TargetCategory][TargetType].ScoreKill + 1
						MESSAGE:New( "Player '" .. PlayerName .. "' killed an enemy " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " .. 
									  PlayerData.Kill[TargetCategory][TargetType].ScoreKill .. " times. Score: " .. PlayerData.Kill[TargetCategory][TargetType].Score, 
									  "Game Status: Score", 20, "/SCORE" .. PlayerName .. "/" .. InitUnitName ):ToAll()
						self:ScoreAdd( PlayerName, "KILL_SCORE", 1, 10, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
					end
				end
			end
		end
	end
end


--- Scheduled
-- @section Scheduled


--- Follows new players entering Clients within the DCSRTE.
function DATABASE:_FollowPlayers()
	self:T( "_FollowPlayers" )

	local ClientUnit = 0
	local CoalitionsData = { AlivePlayersRed = coalition.getPlayers(coalition.side.RED), AlivePlayersBlue = coalition.getPlayers(coalition.side.BLUE) }
	local unitId
	local unitData
	local AlivePlayerUnits = {}
	
	for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
		self:T( { "_FollowPlayers", CoalitionData } )
		for UnitId, UnitData in pairs( CoalitionData ) do
			self:_AddPlayerFromUnit( UnitData )
		end
	end
end


--- Private
-- @section Private


--- Add a new player entering a Unit.
function DATABASE:_AddPlayerFromUnit( UnitData )
	self:T( UnitData )

	if UnitData:isExist() then
		local UnitName = UnitData:getName()
		local PlayerName = UnitData:getPlayerName()
		local UnitDesc = UnitData:getDesc()
		local UnitCategory = UnitDesc.category
		local UnitCoalition = UnitData:getCoalition()
		local UnitTypeName = UnitData:getTypeName()

		self:T( { PlayerName, UnitName, UnitCategory, UnitCoalition, UnitTypeName } )

		if self.Players[PlayerName] == nil then -- I believe this is the place where a Player gets a life in a mission when he enters a unit ...
			self.Players[PlayerName] = {}
			self.Players[PlayerName].Hit = {}
			self.Players[PlayerName].Kill = {}
			self.Players[PlayerName].Mission = {}
			
			-- for CategoryID, CategoryName in pairs( DATABASECategory ) do
				-- self.Players[PlayerName].Hit[CategoryID] = {}
				-- self.Players[PlayerName].Kill[CategoryID] = {}
			-- end
			self.Players[PlayerName].HitPlayers = {}
			self.Players[PlayerName].HitUnits = {}
			self.Players[PlayerName].Penalty = 0
			self.Players[PlayerName].PenaltyCoalition = 0
		end

		if not self.Players[PlayerName].UnitCoalition then
			self.Players[PlayerName].UnitCoalition = UnitCoalition
		else
			if self.Players[PlayerName].UnitCoalition ~= UnitCoalition then
				self.Players[PlayerName].Penalty = self.Players[PlayerName].Penalty + 50						
				self.Players[PlayerName].PenaltyCoalition = self.Players[PlayerName].PenaltyCoalition + 1
				MESSAGE:New( "Player '" .. PlayerName .. "' changed coalition from " .. DATABASECoalition[self.Players[PlayerName].UnitCoalition] .. " to " .. DATABASECoalition[UnitCoalition] ..  
							  "(changed " .. self.Players[PlayerName].PenaltyCoalition .. " times the coalition). 50 Penalty points added.", 
							  "Game Status: Penalty", 20, "/PENALTYCOALITION" .. PlayerName ):ToAll()
				self:ScoreAdd( PlayerName, "COALITION_PENALTY",  1, -50, self.Players[PlayerName].UnitName, DATABASECoalition[self.Players[PlayerName].UnitCoalition], DATABASECategory[self.Players[PlayerName].UnitCategory], self.Players[PlayerName].UnitType,  
							   UnitName, DATABASECoalition[UnitCoalition], DATABASECategory[UnitCategory], UnitData:getTypeName() )
			end
		end
		self.Players[PlayerName].UnitName = UnitName
		self.Players[PlayerName].UnitCoalition = UnitCoalition
		self.Players[PlayerName].UnitCategory = UnitCategory
		self.Players[PlayerName].UnitType = UnitTypeName
	end

end


--- Registers Scores the players completing a Mission Task.
function DATABASE:_AddMissionTaskScore( PlayerUnit, MissionName, Score )
	self:T( { PlayerUnit, MissionName, Score } )

	local PlayerName = PlayerUnit:getPlayerName()
	
	if not self.Players[PlayerName].Mission[MissionName] then
		self.Players[PlayerName].Mission[MissionName] = {}
		self.Players[PlayerName].Mission[MissionName].ScoreTask = 0
		self.Players[PlayerName].Mission[MissionName].ScoreMission = 0
	end
	
	self:T( PlayerName )
	self:T( self.Players[PlayerName].Mission[MissionName] )

	self.Players[PlayerName].Mission[MissionName].ScoreTask = self.Players[PlayerName].Mission[MissionName].ScoreTask + Score

	MESSAGE:New( "Player '" .. PlayerName .. "' has finished another Task in Mission '" .. MissionName .. "'. " ..  
				  Score .. " Score points added.", 
				  "Game Status: Task Completion", 20, "/SCORETASK" .. PlayerName ):ToAll()
	
	_Database:ScoreAdd( PlayerName, "TASK_" .. MissionName:gsub( ' ', '_' ), 1, Score, PlayerUnit:getName() )
end


--- Registers Mission Scores for possible multiple players that contributed in the Mission.
function DATABASE:_AddMissionScore( MissionName, Score )
	self:T( { PlayerUnit, MissionName, Score } )

	for PlayerName, PlayerData in pairs( self.Players ) do
	
		if PlayerData.Mission[MissionName] then
			PlayerData.Mission[MissionName].ScoreMission = PlayerData.Mission[MissionName].ScoreMission + Score
			MESSAGE:New( "Player '" .. PlayerName .. "' has finished Mission '" .. MissionName .. "'. " ..  
						  Score .. " Score points added.", 
						  "Game Status: Mission Completion", 20, "/SCOREMISSION" .. PlayerName ):ToAll()
			_Database:ScoreAdd( PlayerName, "MISSION_" .. MissionName:gsub( ' ', '_' ), 1, Score )
		end
	end
end


--- Events
-- @section Events


function DATABASE:OnHit( event )
	self:T( { event } )

	local InitUnit = nil
	local InitUnitName = ""
	local InitGroupName = ""
	local InitPlayerName = "dummy"

	local InitCoalition = nil
	local InitCategory = nil
	local InitType = nil
	local InitUnitCoalition = nil
	local InitUnitCategory = nil
	local InitUnitType = nil

	local TargetUnit = nil
	local TargetUnitName = ""
	local TargetGroupName = ""
	local TargetPlayerName = ""

	local TargetCoalition = nil
	local TargetCategory = nil
	local TargetType = nil
	local TargetUnitCoalition = nil
	local TargetUnitCategory = nil
	local TargetUnitType = nil

	if event.initiator and event.initiator:getName() then
	
		if event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT then
		
			InitUnit = event.initiator
			InitGroup = Unit.getGroup( InitUnit )
			InitUnitDesc = InitUnit:getDesc()
			
			InitUnitName = InitUnit:getName()
			if InitGroup and InitGroup:isExist() then 
				InitGroupName = InitGroup:getName()
			end
			InitPlayerName = InitUnit:getPlayerName()
			
			InitCoalition = InitUnit:getCoalition()
			--InitCategory = InitUnit:getCategory()
			InitCategory = InitUnitDesc.category  -- Workaround
			InitType = InitUnit:getTypeName()

			InitUnitCoalition = DATABASECoalition[InitCoalition]
			InitUnitCategory = DATABASECategory[InitCategory]
			InitUnitType = InitType
			
			self:T( { InitUnitName, InitGroupName, InitPlayerName, InitCoalition, InitCategory, InitType , InitUnitCoalition, InitUnitCategory, InitUnitType } )
			self:T( { InitUnitDesc } )
		end

			
		if event.target and Object.getCategory(event.target) == Object.Category.UNIT then
		
			TargetUnit = event.target
			TargetGroup = Unit.getGroup( TargetUnit )
			TargetUnitDesc = TargetUnit:getDesc()
			
			TargetUnitName = TargetUnit:getName()
			if TargetGroup and TargetGroup:isExist() then 
				TargetGroupName = TargetGroup:getName() 
			end
			TargetPlayerName = TargetUnit:getPlayerName()

			TargetCoalition = TargetUnit:getCoalition()
			--TargetCategory = TargetUnit:getCategory()
			TargetCategory = TargetUnitDesc.category  -- Workaround
			TargetType = TargetUnit:getTypeName()

			TargetUnitCoalition = DATABASECoalition[TargetCoalition]
			TargetUnitCategory = DATABASECategory[TargetCategory]
			TargetUnitType = TargetType
			
			self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType, TargetUnitCoalition, TargetUnitCategory, TargetUnitType } )
			self:T( { TargetUnitDesc } )
		end
		
		if InitPlayerName ~= nil then -- It is a player that is hitting something
			self:_AddPlayerFromUnit( InitUnit )
			if self.Players[InitPlayerName] then -- This should normally not happen, but i'll test it anyway.
				if TargetPlayerName ~= nil then -- It is a player hitting another player ...
					self:_AddPlayerFromUnit( TargetUnit )
					self.Players[InitPlayerName].HitPlayers = self.Players[InitPlayerName].HitPlayers + 1
				end
				
				self:T( "Hitting Something" )
				-- What is he hitting?
				if TargetCategory then
					if not self.Players[InitPlayerName].Hit[TargetCategory] then
						self.Players[InitPlayerName].Hit[TargetCategory] = {}
					end
					if not self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName] then
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName] = {}
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score = 0
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty = 0
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit = 0
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit = 0
					end
					local Score = 0
					if InitCoalition == TargetCoalition then
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty + 10						
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit + 1
						MESSAGE:New( "Player '" .. InitPlayerName .. "' hit a friendly " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " .. 
						              self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit .. " times. Penalty: -" .. self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty, 
									  "Game Status: Penalty", 20, "/PENALTY" .. InitPlayerName .. "/" .. InitUnitName ):ToAll()
						self:ScoreAdd( InitPlayerName, "HIT_PENALTY", 1, -25, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
					else
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score + 1						
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit + 1
						MESSAGE:New( "Player '" .. InitPlayerName .. "' hit a target " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " .. 
						              self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit .. " times. Score: " .. self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score, 
									  "Game Status: Score", 20, "/SCORE" .. InitPlayerName .. "/" .. InitUnitName ):ToAll()
						self:ScoreAdd( InitPlayerName, "HIT_SCORE", 1, 1, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
					end
				end
			end
		elseif InitPlayerName == nil then -- It is an AI hitting a player???
				
		end
	end
end


function DATABASE:ReportScoreAll()

env.info( "Hello World " )

	local ScoreMessage = ""
	local PlayerMessage = ""
	
	self:T( "Score Report" )

	for PlayerName, PlayerData in pairs( self.Players ) do
		if PlayerData then -- This should normally not happen, but i'll test it anyway.
			self:T( "Score Player: " .. PlayerName )

			-- Some variables
			local InitUnitCoalition = DATABASECoalition[PlayerData.UnitCoalition]
			local InitUnitCategory = DATABASECategory[PlayerData.UnitCategory]
			local InitUnitType = PlayerData.UnitType
			local InitUnitName = PlayerData.UnitName
			
			local PlayerScore = 0
			local PlayerPenalty = 0
			
			ScoreMessage = ":\n"
			
			local ScoreMessageHits = ""

			for CategoryID, CategoryName in pairs( DATABASECategory ) do
				self:T( CategoryName )
				if PlayerData.Hit[CategoryID] then
					local Score = 0
					local ScoreHit = 0
					local Penalty = 0
					local PenaltyHit = 0
					self:T( "Hit scores exist for player " .. PlayerName )
					for UnitName, UnitData in pairs( PlayerData.Hit[CategoryID] ) do
						Score = Score + UnitData.Score
						ScoreHit = ScoreHit + UnitData.ScoreHit
						Penalty = Penalty + UnitData.Penalty
						PenaltyHit = UnitData.PenaltyHit
					end
					local ScoreMessageHit = string.format( "%s:%d  ", CategoryName, Score - Penalty )
					self:T( ScoreMessageHit )
					ScoreMessageHits = ScoreMessageHits .. ScoreMessageHit
					PlayerScore = PlayerScore + Score
					PlayerPenalty = PlayerPenalty + Penalty
				else
					--ScoreMessageHits = ScoreMessageHits .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
				end
			end
			if ScoreMessageHits ~= "" then
				ScoreMessage = ScoreMessage .. "  Hits: " .. ScoreMessageHits .. "\n"
			end
	
			local ScoreMessageKills = ""
			for CategoryID, CategoryName in pairs( DATABASECategory ) do
				self:T( "Kill scores exist for player " .. PlayerName )
				if PlayerData.Kill[CategoryID] then
					local Score = 0
					local ScoreKill = 0
					local Penalty = 0
					local PenaltyKill = 0
					
					for UnitName, UnitData in pairs( PlayerData.Kill[CategoryID] ) do
						Score = Score + UnitData.Score
						ScoreKill = ScoreKill + UnitData.ScoreKill
						Penalty = Penalty + UnitData.Penalty
						PenaltyKill = PenaltyKill + UnitData.PenaltyKill
					end
					
					local ScoreMessageKill = string.format( "  %s:%d  ", CategoryName, Score - Penalty )
					self:T( ScoreMessageKill )
					ScoreMessageKills = ScoreMessageKills .. ScoreMessageKill

					PlayerScore = PlayerScore + Score
					PlayerPenalty = PlayerPenalty + Penalty
				else
					--ScoreMessageKills = ScoreMessageKills .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
				end
			end
			if ScoreMessageKills ~= "" then
				ScoreMessage = ScoreMessage .. "  Kills: " .. ScoreMessageKills .. "\n"
			end
			
			local ScoreMessageCoalitionChangePenalties = ""
			if PlayerData.PenaltyCoalition ~= 0 then
				ScoreMessageCoalitionChangePenalties = ScoreMessageCoalitionChangePenalties .. string.format( " -%d (%d changed)", PlayerData.Penalty, PlayerData.PenaltyCoalition )
				PlayerPenalty = PlayerPenalty + PlayerData.Penalty
			end
			if ScoreMessageCoalitionChangePenalties ~= "" then
				ScoreMessage = ScoreMessage .. "  Coalition Penalties: " .. ScoreMessageCoalitionChangePenalties .. "\n"
			end

			local ScoreMessageMission = ""
			local ScoreMission = 0
			local ScoreTask = 0
			for MissionName, MissionData in pairs( PlayerData.Mission ) do
				ScoreMission = ScoreMission + MissionData.ScoreMission
				ScoreTask = ScoreTask + MissionData.ScoreTask
				ScoreMessageMission = ScoreMessageMission .. "'" .. MissionName .. "'; " 
			end
			PlayerScore = PlayerScore + ScoreMission + ScoreTask

			if ScoreMessageMission ~= "" then
				ScoreMessage = ScoreMessage .. "  Tasks: " .. ScoreTask .. " Mission: " .. ScoreMission .. " ( " .. ScoreMessageMission .. ")\n"
			end
			
			PlayerMessage = PlayerMessage .. string.format( "Player '%s' Score:%d (%d Score -%d Penalties)%s", PlayerName, PlayerScore - PlayerPenalty, PlayerScore, PlayerPenalty, ScoreMessage )
		end
	end
	MESSAGE:New( PlayerMessage, "Player Scores", 30, "AllPlayerScores"):ToAll()
end


function DATABASE:ReportScorePlayer()

env.info( "Hello World " )

	local ScoreMessage = ""
	local PlayerMessage = ""
	
	self:T( "Score Report" )

	for PlayerName, PlayerData in pairs( self.Players ) do
		if PlayerData then -- This should normally not happen, but i'll test it anyway.
			self:T( "Score Player: " .. PlayerName )

			-- Some variables
			local InitUnitCoalition = DATABASECoalition[PlayerData.UnitCoalition]
			local InitUnitCategory = DATABASECategory[PlayerData.UnitCategory]
			local InitUnitType = PlayerData.UnitType
			local InitUnitName = PlayerData.UnitName
			
			local PlayerScore = 0
			local PlayerPenalty = 0
			
			ScoreMessage = ""
			
			local ScoreMessageHits = ""

			for CategoryID, CategoryName in pairs( DATABASECategory ) do
				self:T( CategoryName )
				if PlayerData.Hit[CategoryID] then
					local Score = 0
					local ScoreHit = 0
					local Penalty = 0
					local PenaltyHit = 0
					self:T( "Hit scores exist for player " .. PlayerName )
					for UnitName, UnitData in pairs( PlayerData.Hit[CategoryID] ) do
						Score = Score + UnitData.Score
						ScoreHit = ScoreHit + UnitData.ScoreHit
						Penalty = Penalty + UnitData.Penalty
						PenaltyHit = UnitData.PenaltyHit
					end
					local ScoreMessageHit = string.format( "\n    %s = %d score(%d;-%d) hits(#%d;#-%d)", CategoryName, Score - Penalty, Score, Penalty, ScoreHit,  PenaltyHit )
					self:T( ScoreMessageHit )
					ScoreMessageHits = ScoreMessageHits .. ScoreMessageHit
					PlayerScore = PlayerScore + Score
					PlayerPenalty = PlayerPenalty + Penalty
				else
					--ScoreMessageHits = ScoreMessageHits .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
				end
			end
			if ScoreMessageHits ~= "" then
				ScoreMessage = ScoreMessage .. "\n  Hits: " .. ScoreMessageHits .. " "
			end
	
			local ScoreMessageKills = ""
			for CategoryID, CategoryName in pairs( DATABASECategory ) do
				self:T( "Kill scores exist for player " .. PlayerName )
				if PlayerData.Kill[CategoryID] then
					local Score = 0
					local ScoreKill = 0
					local Penalty = 0
					local PenaltyKill = 0
					
					for UnitName, UnitData in pairs( PlayerData.Kill[CategoryID] ) do
						Score = Score + UnitData.Score
						ScoreKill = ScoreKill + UnitData.ScoreKill
						Penalty = Penalty + UnitData.Penalty
						PenaltyKill = PenaltyKill + UnitData.PenaltyKill
					end
					
					local ScoreMessageKill = string.format( "\n    %s = %d score(%d;-%d) hits(#%d;#-%d)", CategoryName, Score - Penalty, Score, Penalty, ScoreKill, PenaltyKill )
					self:T( ScoreMessageKill )
					ScoreMessageKills = ScoreMessageKills .. ScoreMessageKill

					PlayerScore = PlayerScore + Score
					PlayerPenalty = PlayerPenalty + Penalty
				else
					--ScoreMessageKills = ScoreMessageKills .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
				end
			end
			if ScoreMessageKills ~= "" then
				ScoreMessage = ScoreMessage .. "\n  Kills: " .. ScoreMessageKills .. " "
			end
			
			local ScoreMessageCoalitionChangePenalties = ""
			if PlayerData.PenaltyCoalition ~= 0 then
				ScoreMessageCoalitionChangePenalties = ScoreMessageCoalitionChangePenalties .. string.format( " -%d (%d changed)", PlayerData.Penalty, PlayerData.PenaltyCoalition )
				PlayerPenalty = PlayerPenalty + PlayerData.Penalty
			end
			if ScoreMessageCoalitionChangePenalties ~= "" then
				ScoreMessage = ScoreMessage .. "\n  Coalition: " .. ScoreMessageCoalitionChangePenalties .. " "
			end

			local ScoreMessageMission = ""
			local ScoreMission = 0
			local ScoreTask = 0
			for MissionName, MissionData in pairs( PlayerData.Mission ) do
				ScoreMission = ScoreMission + MissionData.ScoreMission
				ScoreTask = ScoreTask + MissionData.ScoreTask
				ScoreMessageMission = ScoreMessageMission .. "'" .. MissionName .. "'; " 
			end
			PlayerScore = PlayerScore + ScoreMission + ScoreTask

			if ScoreMessageMission ~= "" then
				ScoreMessage = ScoreMessage .. "\n  Tasks: " .. ScoreTask .. " Mission: " .. ScoreMission .. " ( " .. ScoreMessageMission .. ") "
			end
			
			PlayerMessage = PlayerMessage .. string.format( "Player '%s' Score = %d ( %d Score, -%d Penalties ):%s", PlayerName, PlayerScore - PlayerPenalty, PlayerScore, PlayerPenalty, ScoreMessage )
		end
	end
	MESSAGE:New( PlayerMessage, "Player Scores", 30, "AllPlayerScores"):ToAll()

end


function DATABASE:ScoreMenu()
	local ReportScore = SUBMENU:New( 'Scoring' )
	local ReportAllScores = COMMANDMENU:New( 'Score All Active Players', ReportScore, DATABASE.ReportScoreAll, self )
	local ReportPlayerScores = COMMANDMENU:New('Your Current Score', ReportScore, DATABASE.ReportScorePlayer, self )
end




-- File Logic for tracking the scores

function DATABASE:SecondsToClock(sSeconds)
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


function DATABASE:ScoreOpen()
	if lfs then
		local fdir = lfs.writedir() .. [[Logs\]] .. "Player_Scores_" .. os.date( "%Y-%m-%d_%H-%M-%S" ) .. ".csv"
		self.StatFile, self.err = io.open(fdir,"w+")
		if not self.StatFile then
			error( "Error: Cannot open 'Player Scores.csv' file in " .. lfs.writedir() )
		end
		self.StatFile:write( '"RunID";"Time";"PlayerName";"ScoreType";"PlayerUnitCoaltion";"PlayerUnitCategory";"PlayerUnitType";"PlayerUnitName";"TargetUnitCoalition";"TargetUnitCategory";"TargetUnitType";"TargetUnitName";"Times";"Score"\n' )
		
		self.RunID = os.date("%y-%m-%d_%H-%M-%S")
	end
end


function DATABASE:ScoreAdd( PlayerName, ScoreType, ScoreTimes, ScoreAmount, PlayerUnitName, PlayerUnitCoalition, PlayerUnitCategory, PlayerUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
	--write statistic information to file
	local ScoreTime = self:SecondsToClock(timer.getTime())
	PlayerName = PlayerName:gsub( '"', '_' )

	if PlayerUnitName and PlayerUnitName ~= '' then
		local PlayerUnit = Unit.getByName( PlayerUnitName )
		
		if PlayerUnit then
			if not PlayerUnitCategory then
				--PlayerUnitCategory = DATABASECategory[PlayerUnit:getCategory()]
				PlayerUnitCategory = DATABASECategory[PlayerUnit:getDesc().category]
			end
			
			if not PlayerUnitCoalition then
				PlayerUnitCoalition = DATABASECoalition[PlayerUnit:getCoalition()]
			end
			
			if not PlayerUnitType then
				PlayerUnitType = PlayerUnit:getTypeName()
			end
		else
			PlayerUnitName = ''
			PlayerUnitCategory = ''
			PlayerUnitCoalition = ''
			PlayerUnitType = ''
		end
	else
		PlayerUnitName = ''
		PlayerUnitCategory = ''
		PlayerUnitCoalition = ''
		PlayerUnitType = ''
	end
			
	if not TargetUnitCoalition then
		TargetUnitCoalition = ''
	end
	
	if not TargetUnitCategory then
		TargetUnitCategory = ''
	end
	
	if not TargetUnitType then
		TargetUnitType = ''
	end
		
	if not TargetUnitName then
		TargetUnitName = ''
	end

	if lfs then
		self.StatFile:write( '"' .. self.RunID .. '";' .. ScoreTime .. ';"' .. PlayerName .. '";"' .. ScoreType .. '";"' .. 
									PlayerUnitCoalition .. '";"' .. PlayerUnitCategory .. '";"' .. PlayerUnitType .. '";"' .. PlayerUnitName .. '";"' .. 
									TargetUnitCoalition .. '";"' .. TargetUnitCategory .. '";"' .. TargetUnitType .. '";"' .. TargetUnitName .. '";' .. 
									ScoreTimes .. ';' .. ScoreAmount )
		self.StatFile:write( "\n" )
	end
end

	
function LogClose()
	if lfs then
		self.StatFile:close()
	end
end

_Database = DATABASE:New()
_Database:ScoreOpen()

--- CARGO Classes
-- @classmod CARGO

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

--- Clients are those Groups defined within the Mission Editor that have the skillset defined as "Client" or "Player".
-- These clients are defined within the Mission Orchestration Framework (MOF)

CARGOS = {}


CARGO_ZONE = {
	ClassName="CARGO_ZONE",
	CargoZoneName = '',
	CargoHostUnitName = '',
	SIGNAL = {
		TYPE = {
			SMOKE = { ID = 1, TEXT = "smoke" },
			FLARE = { ID = 2, TEXT = "flare" }
		},
		COLOR = {	
			GREEN = { ID = 1, TRIGGERCOLOR = trigger.smokeColor.Green, TEXT = "A green" },
			RED = { ID = 2, TRIGGERCOLOR = trigger.smokeColor.Red, TEXT = "A red" },
			WHITE = { ID = 3, TRIGGERCOLOR = trigger.smokeColor.White, TEXT = "A white" },
			ORANGE = { ID = 4, TRIGGERCOLOR = trigger.smokeColor.Orange, TEXT = "An orange" },
			BLUE = { ID = 5, TRIGGERCOLOR = trigger.smokeColor.Blue, TEXT = "A blue" },
			YELLOW = { ID = 6, TRIGGERCOLOR = trigger.flareColor.Yellow, TEXT = "A yellow" }
		}
	}
}

function CARGO_ZONE:New( CargoZoneName, CargoHostName ) local self = BASE:Inherit( self, BASE:New() )
self:T( { CargoZoneName, CargoHostName } )

	self.CargoZoneName = CargoZoneName
	self.CargoZone = trigger.misc.getZone( CargoZoneName )
	

	if CargoHostName then
		self.CargoHostName = CargoHostName
	end

	self:T( self.CargoZone )
	
	return self
end

function CARGO_ZONE:Spawn()
	self:T( self.CargoHostName )

	if self.CargoHostSpawn then
		local CargoHostGroup = self.CargoHostSpawn:GetGroupFromIndex()
		if CargoHostGroup and CargoHostGroup:IsAlive() then
		else
			self.CargoHostSpawn:ReSpawn( 1 )
		end
	else
		self:T( "Initialize CargoHostSpawn" )
		self.CargoHostSpawn = SPAWN:New( self.CargoHostName ):Limit( 1, 1 )
		self.CargoHostSpawn:ReSpawn( 1 )
	end

	return self
end

function CARGO_ZONE:GetHostUnit()
	self:T( self )

	if self.CargoHostName then
		
		-- A Host has been given, signal the host
		local CargoHostGroup = self.CargoHostSpawn:GetGroupFromIndex()
		local CargoHostUnit
		if CargoHostGroup and CargoHostGroup:IsAlive() then
			CargoHostUnit = CargoHostGroup:GetUnit(1)
		else
			CargoHostUnit = StaticObject.getByName( self.CargoHostName )
		end
		
		return CargoHostUnit
	end
	
	return nil
end

function CARGO_ZONE:ReportCargosToClient( Client, CargoType )
self:T()

	local SignalUnit = self:GetHostUnit()

	if SignalUnit then
		
		local SignalUnitTypeName = SignalUnit:getTypeName()
		
		local HostMessage = ""

		local IsCargo = false
		for CargoID, Cargo in pairs( CARGOS ) do
			if Cargo.CargoType == Task.CargoType then
				if Cargo:IsStatusNone() then
					HostMessage = HostMessage .. " - " .. Cargo.CargoName .. " - " .. Cargo.CargoType .. " (" .. Cargo.Weight .. "kg)" .. "\n"
					IsCargo = true
				end
			end
		end
		
		if not IsCargo then
			HostMessage = "No Cargo Available."
		end

		Client:Message( HostMessage, 20, Mission.Name .. "/StageHosts." .. SignalUnitTypeName, SignalUnitTypeName .. ": Reporting Cargo", 10 )
	end
end

function CARGO_ZONE:Signal()
self:T()

	local Signalled = false

	if self.SignalType then
	
		if self.CargoHostName then
			
			-- A Host has been given, signal the host
			
			local SignalUnit = self:GetHostUnit()
			
			if SignalUnit then
			
				self:T( 'Signalling Unit' )
				local SignalVehiclePos = SignalUnit:GetPositionVec3()
				SignalVehiclePos.y = SignalVehiclePos.y + 2

				if self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.SMOKE.ID then

					trigger.action.smoke( SignalVehiclePos, self.SignalColor.TRIGGERCOLOR )
					Signalled = true

				elseif self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.FLARE.ID then

					trigger.action.signalFlare( SignalVehiclePos, self.SignalColor.TRIGGERCOLOR , 0 )
					Signalled = false

				end
			end
			
		else
		
			local CurrentPosition = { x = self.CargoZone.point.x, y = self.CargoZone.point.z }
			self.CargoZone.point.y = land.getHeight( CurrentPosition ) + 2
	  
			if self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.SMOKE.ID then

				trigger.action.smoke( self.CargoZone.point, self.SignalColor.TRIGGERCOLOR  )
				Signalled = true

			elseif self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.FLARE.ID then
				trigger.action.signalFlare( self.CargoZone.point, self.SignalColor.TRIGGERCOLOR, 0 )
				Signalled = false

			end
		end
	end
	
	return Signalled

end

function CARGO_ZONE:WhiteSmoke()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.WHITE

	return self
end

function CARGO_ZONE:BlueSmoke()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.BLUE

	return self
end

function CARGO_ZONE:RedSmoke()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.RED

	return self
end

function CARGO_ZONE:OrangeSmoke()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.ORANGE

	return self
end

function CARGO_ZONE:GreenSmoke()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.GREEN

	return self
end


function CARGO_ZONE:WhiteFlare()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.WHITE

	return self
end

function CARGO_ZONE:RedFlare()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.RED

	return self
end

function CARGO_ZONE:GreenFlare()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.GREEN

	return self
end

function CARGO_ZONE:YellowFlare()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.YELLOW

	return self
end


function CARGO_ZONE:GetCargoHostUnit()
	self:T( self )

	if self.CargoHostSpawn then 
		local CargoHostGroup = self.CargoHostSpawn:GetGroupFromIndex(1)
		if CargoHostGroup and CargoHostGroup:IsAlive() then
			local CargoHostUnit = CargoHostGroup:GetUnit(1)
			if CargoHostUnit and CargoHostUnit:IsAlive() then
				return CargoHostUnit
			end
		end
	end

	return nil
end

function CARGO_ZONE:GetCargoZoneName()
self:T()

	return self.CargoZoneName
end

CARGO = {
	ClassName = "CARGO",
	STATUS = {
		NONE = 0,
		LOADED = 1,
		UNLOADED = 2,
		LOADING = 3
	},
	CargoClient = nil
}

--- Add Cargo to the mission... Cargo functionality needs to be reworked a bit, so this is still under construction. I need to make a CARGO Class...
function CARGO:New( CargoType, CargoName, CargoWeight ) local self = BASE:Inherit( self, BASE:New() )
self:T( { CargoType, CargoName, CargoWeight } )


	self.CargoType = CargoType
	self.CargoName = CargoName
    self.CargoWeight = CargoWeight

	self:StatusNone()
	
	return self
end

function CARGO:Spawn( Client )
	self:T()

	return self

end

function CARGO:IsNear( Client, LandingZone )
self:T()

	local Near = true
	
	return Near
	
end


function CARGO:IsLoadingToClient()
self:T()

	if self:IsStatusLoading() then
		return self.CargoClient
	end
	
	return nil

end


function CARGO:IsLoadedInClient()
self:T()

	if self:IsStatusLoaded() then
		return self.CargoClient
	end
	
	return nil

end


function CARGO:UnLoad( Client, TargetZoneName )
self:T()

	self:StatusUnLoaded()

	return self
end

function CARGO:OnBoard( Client, LandingZone )
self:T()
  
	local Valid = true
  
	self.CargoClient = Client
	local ClientUnit = Client:GetClientGroupDCSUnit()

	return Valid
end

function CARGO:OnBoarded( Client, LandingZone )
self:T()

	local OnBoarded = true
  
	return OnBoarded
end

function CARGO:Load( Client )
self:T()

	self:StatusLoaded( Client )

	return self
end

function CARGO:IsLandingRequired()
self:T()
	return true
end

function CARGO:IsSlingLoad()
self:T()
	return false
end


function CARGO:StatusNone()
self:T()

	self.CargoClient = nil
	self.CargoStatus = CARGO.STATUS.NONE
	
	return self
end

function CARGO:StatusLoading( Client )
self:T()

	self.CargoClient = Client
	self.CargoStatus = CARGO.STATUS.LOADING
	self:T( "Cargo " .. self.CargoName .. " loading to Client: " .. self.CargoClient:GetClientGroupName() )
	
	return self
end

function CARGO:StatusLoaded( Client )
self:T()

	self.CargoClient = Client
	self.CargoStatus = CARGO.STATUS.LOADED
	self:T( "Cargo " .. self.CargoName .. " loaded in Client: " .. self.CargoClient:GetClientGroupName() )
	
	return self
end

function CARGO:StatusUnLoaded()
self:T()

	self.CargoClient = nil
	self.CargoStatus = CARGO.STATUS.UNLOADED
	
	return self
end


function CARGO:IsStatusNone()
self:T()

	return self.CargoStatus == CARGO.STATUS.NONE
end

function CARGO:IsStatusLoading()
self:T()

	return self.CargoStatus == CARGO.STATUS.LOADING
end

function CARGO:IsStatusLoaded()
self:T()

	return self.CargoStatus == CARGO.STATUS.LOADED
end

function CARGO:IsStatusUnLoaded()
self:T()

	return self.CargoStatus == CARGO.STATUS.UNLOADED
end


CARGO_GROUP = {
	ClassName = "CARGO_GROUP"
}


function CARGO_GROUP:New( CargoType, CargoName, CargoWeight, CargoGroupTemplate, CargoZone ) 	local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )
	self:T( { CargoType, CargoName, CargoWeight, CargoGroupTemplate, CargoZone } )

	self.CargoSpawn = SPAWN:NewWithAlias( CargoGroupTemplate, CargoName )
	self.CargoZone = CargoZone

	CARGOS[self.CargoName] = self

	return self

end

function CARGO_GROUP:Spawn( Client )
	self:T( { Client } )

	local SpawnCargo = true
	
	if self:IsStatusNone() then
		local CargoGroup = Group.getByName( self.CargoName )
		if CargoGroup and CargoGroup:isExist() then
			SpawnCargo = false
		end
		
	elseif self:IsStatusLoading() then
	
		local Client = self:IsLoadingToClient()
		if Client and Client:ClientGroup() then
			SpawnCargo = false
		else
			local CargoGroup = Group.getByName( self.CargoName	 )
			if CargoGroup and CargoGroup:isExist() then
				SpawnCargo = false
			end
		end
	
	elseif self:IsStatusLoaded()  then
	
		local ClientLoaded = self:IsLoadedInClient()
		-- Now test if another Client is alive (not this one), and it has the CARGO, then this cargo does not need to be initialized and spawned.
		if ClientLoaded and ClientLoaded ~= Client then
			local ClientGroup = Client:ClientGroup()
			if ClientLoaded:GetClientGroupDCSUnit() and ClientLoaded:GetClientGroupDCSUnit():isExist() then
				SpawnCargo = false
			else
				self:StatusNone()
			end
		else
			-- Same Client, but now in initialize, so set back the status to None.
			self:StatusNone()
		end
		
	elseif self:IsStatusUnLoaded() then
	
		SpawnCargo = false
		
	end
	
	if SpawnCargo then 
		if self.CargoZone:GetCargoHostUnit() then
			--- ReSpawn the Cargo from the CargoHost
			self.CargoGroupName = self.CargoSpawn:SpawnFromUnit( self.CargoZone:GetCargoHostUnit(), 60, 30, 1 ):GetName()
		else
			--- ReSpawn the Cargo in the CargoZone without a host ...
			self.CargoGroupName = self.CargoSpawn:SpawnInZone( self.CargoZone, 1 ):GetName()
		end
		self:StatusNone()	
	end
	
	self:T( { self.CargoGroupName, CARGOS[self.CargoName].CargoGroupName } )

	return self
end

function CARGO_GROUP:IsNear( Client, LandingZone )
self:T()

	local Near = false

	if self.CargoGroupName then 
		local CargoGroup = Group.getByName( self.CargoGroupName )
		if routines.IsPartOfGroupInRadius( CargoGroup, Client:ClientPosition(), 250 ) then
			Near = true
		end
	end
	
	return Near
	
end


function CARGO_GROUP:OnBoard( Client, LandingZone, OnBoardSide )
self:T()
  
	local Valid = true
  
	local ClientUnit = Client:GetClientGroupDCSUnit()
	
	local CarrierPos = ClientUnit:getPoint()
	local CarrierPosMove = ClientUnit:getPoint()
	local CarrierPosOnBoard = ClientUnit:getPoint()
	
	local CargoGroup = Group.getByName( self.CargoGroupName )

	local CargoUnits = CargoGroup:getUnits()
	local CargoPos = CargoUnits[1]:getPoint()

	
	local Points = {}
	
	self:T( 'CargoPos x = ' .. CargoPos.x .. " z = " .. CargoPos.z )
	self:T( 'CarrierPosMove x = ' .. CarrierPosMove.x .. " z = " .. CarrierPosMove.z )
	
	Points[#Points+1] = routines.ground.buildWP( CargoPos, "Cone", 10 )

	self:T( 'Points[1] x = ' .. Points[1].x .. " y = " .. Points[1].y )
	
	if OnBoardSide == nil then
		OnBoardSide = CLIENT.ONBOARDSIDE.NONE
	end
	
	if OnBoardSide == CLIENT.ONBOARDSIDE.LEFT then
	
		self:T( "TransportCargoOnBoard: Onboarding LEFT" )
		CarrierPosMove.z = CarrierPosMove.z - 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z - 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.RIGHT then
		
		self:T( "TransportCargoOnBoard: Onboarding RIGHT" )
		CarrierPosMove.z = CarrierPosMove.z + 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z + 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.BACK then
		
		self:T( "TransportCargoOnBoard: Onboarding BACK" )
		CarrierPosMove.x = CarrierPosMove.x - 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x - 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.FRONT then
		
		self:T( "TransportCargoOnBoard: Onboarding FRONT" )
		CarrierPosMove.x = CarrierPosMove.x + 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x + 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.NONE then
		
		self:T( "TransportCargoOnBoard: Onboarding CENTRAL" )
		Points[#Points+1] = routines.ground.buildWP( CarrierPos, "Cone", 10 )
	
	end
	self:T( "TransportCargoOnBoard: Routing " .. self.CargoGroupName )

	routines.scheduleFunction( routines.goRoute, { self.CargoGroupName, Points}, timer.getTime() + 4 )
	
	self:StatusLoading( Client )
     
	return Valid
  
end


function CARGO_GROUP:OnBoarded( Client, LandingZone )
self:T()

	local OnBoarded = false
  
	local CargoGroup = Group.getByName( self.CargoGroupName )
	if routines.IsPartOfGroupInRadius( CargoGroup, Client:ClientPosition(), 25 ) then
		CargoGroup:destroy()
		self:StatusLoaded( Client )
		OnBoarded = true
	end

	return OnBoarded
end


function CARGO_GROUP:UnLoad( Client, TargetZoneName )
self:T()

	self:T( 'self.CargoName = ' .. self.CargoName ) 

	local CargoGroup = self.CargoSpawn:SpawnFromUnit( Client:GetClientGroupUnit(), 60, 30 )

	self.CargoGroupName = CargoGroup:GetName()
	self:T( 'self.CargoGroupName = ' .. self.CargoGroupName ) 
	
	CargoGroup:RouteToZone( ZONE:New( TargetZoneName ), true )
	
	self:StatusUnLoaded()

	return self
end


CARGO_PACKAGE = {
	ClassName = "CARGO_PACKAGE"
}


function CARGO_PACKAGE:New( CargoType, CargoName, CargoWeight, CargoClient ) local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )

	self:T( { CargoType, CargoName, CargoWeight, CargoClient } )

	self.CargoClient = CargoClient
	
	CARGOS[self.CargoName] = self

	return self

end


function CARGO_PACKAGE:Spawn( Client )
	self:T( { self, Client } )

	-- this needs to be checked thoroughly

	local CargoClientGroup = self.CargoClient:ClientGroup()
	if not CargoClientGroup then
		if not self.CargoClientSpawn then
			self.CargoClientSpawn = SPAWN:New( self.CargoClient:GetClientGroupName() ):Limit( 1, 1 )
		end
		self.CargoClientSpawn:ReSpawn( 1 )	
	end

	local SpawnCargo = true
	
	if self:IsStatusNone() then
	
	elseif self:IsStatusLoading() or self:IsStatusLoaded() then

		local CargoClientLoaded = self:IsLoadedInClient()
		if CargoClientLoaded and CargoClientLoaded:ClientGroup() then
			SpawnCargo = false
		end
	
	elseif self:IsStatusUnLoaded() then
	
		SpawnCargo = false
	
	else

	end

	if SpawnCargo then
		self:StatusLoaded( self.CargoClient )
	end

	return self
end


function CARGO_PACKAGE:IsNear( Client, LandingZone )
self:T()

	local Near = false

	if self.CargoClient and self.CargoClient:ClientGroup() then
		self:T( self.CargoClient.ClientName )
		self:T( 'Client Exists.' )

		if routines.IsUnitInRadius( self.CargoClient:GetClientGroupDCSUnit(), Client:ClientPosition(), 150 ) then
			Near = true
		end
	end
	
	return Near
	
end


function CARGO_PACKAGE:OnBoard( Client, LandingZone, OnBoardSide )
self:T()
  
	local Valid = true
  
	local ClientUnit = Client:GetClientGroupDCSUnit()
	
	local CarrierPos = ClientUnit:getPoint()
	local CarrierPosMove = ClientUnit:getPoint()
	local CarrierPosOnBoard = ClientUnit:getPoint()
	local CarrierPosMoveAway = ClientUnit:getPoint()
	
	local CargoHostGroup = self.CargoClient:ClientGroup()
	local CargoHostName = self.CargoClient:ClientGroup():getName()

	local CargoHostUnits = CargoHostGroup:getUnits()
	local CargoPos = CargoHostUnits[1]:getPoint()

	local Points = {}
	
	self:T( 'CargoPos x = ' .. CargoPos.x .. " z = " .. CargoPos.z )
	self:T( 'CarrierPosMove x = ' .. CarrierPosMove.x .. " z = " .. CarrierPosMove.z )
	
	Points[#Points+1] = routines.ground.buildWP( CargoPos, "Cone", 10 )

	self:T( 'Points[1] x = ' .. Points[1].x .. " y = " .. Points[1].y )
	
	if OnBoardSide == nil then
		OnBoardSide = CLIENT.ONBOARDSIDE.NONE
	end
	
	if OnBoardSide == CLIENT.ONBOARDSIDE.LEFT then
	
		self:T( "TransportCargoOnBoard: Onboarding LEFT" )
		CarrierPosMove.z = CarrierPosMove.z - 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z - 5
		CarrierPosMoveAway.z = CarrierPosMoveAway.z - 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.RIGHT then
		
		self:T( "TransportCargoOnBoard: Onboarding RIGHT" )
		CarrierPosMove.z = CarrierPosMove.z + 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z + 5
		CarrierPosMoveAway.z = CarrierPosMoveAway.z + 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )	
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.BACK then
		
		self:T( "TransportCargoOnBoard: Onboarding BACK" )
		CarrierPosMove.x = CarrierPosMove.x - 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x - 5
		CarrierPosMoveAway.x = CarrierPosMoveAway.x - 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )

	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.FRONT then
		
		self:T( "TransportCargoOnBoard: Onboarding FRONT" )
		CarrierPosMove.x = CarrierPosMove.x + 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x + 5
		CarrierPosMoveAway.x = CarrierPosMoveAway.x + 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )

	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.NONE then
		
		self:T( "TransportCargoOnBoard: Onboarding FRONT" )
		CarrierPosMove.x = CarrierPosMove.x + 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x + 5
		CarrierPosMoveAway.x = CarrierPosMoveAway.x + 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )
	
	end
	self:T( "Routing " .. CargoHostName )

	routines.scheduleFunction( routines.goRoute, { CargoHostName, Points}, timer.getTime() + 4 )
     
	return Valid
  
end


function CARGO_PACKAGE:OnBoarded( Client, LandingZone )
self:T()

	local OnBoarded = false
  
	if self.CargoClient and self.CargoClient:ClientGroup() then
		if routines.IsUnitInRadius( self.CargoClient:GetClientGroupDCSUnit(), self.CargoClient:ClientPosition(), 10 ) then
			
			-- Switch Cargo from self.CargoClient to Client ... Each cargo can have only one client. So assigning the new client for the cargo is enough.
			self:StatusLoaded( Client )
			
			-- All done, onboarded the Cargo to the new Client.
			OnBoarded = true
		end
	end

	return OnBoarded
end


function CARGO_PACKAGE:UnLoad( Client, TargetZoneName )
self:T()

	self:T( 'self.CargoName = ' .. self.CargoName ) 
	--self:T( 'self.CargoHostName = ' .. self.CargoHostName ) 
	
	--self.CargoSpawn:FromCarrier( Client:ClientGroup(), TargetZoneName, self.CargoHostName )
	self:StatusUnLoaded()

	return Cargo
end


CARGO_SLINGLOAD = {
	ClassName = "CARGO_SLINGLOAD"
}


function CARGO_SLINGLOAD:New( CargoType, CargoName, CargoWeight, CargoZone, CargoHostName, CargoCountryID )
	local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )

	self:T( { CargoType, CargoName, CargoWeight, CargoZone, CargoHostName, CargoCountryID } )

	self.CargoHostName = CargoHostName

	-- Cargo will be initialized around the CargoZone position.
	self.CargoZone = CargoZone
	
	self.CargoCount = 0
	self.CargoStaticName = string.format( "%s#%03d", self.CargoName, self.CargoCount )

	-- The country ID needs to be correctly set.
	self.CargoCountryID = CargoCountryID

	CARGOS[self.CargoName] = self

	return self

end


function CARGO_SLINGLOAD:IsLandingRequired()
self:T()
	return false
end


function CARGO_SLINGLOAD:IsSlingLoad()
self:T()
	return true
end


function CARGO_SLINGLOAD:Spawn( Client )
	self:T( { self, Client } )

	local Zone = trigger.misc.getZone( self.CargoZone )

	local ZonePos = {}
	ZonePos.x = Zone.point.x + math.random( Zone.radius / 2 * -1, Zone.radius / 2 )
	ZonePos.y = Zone.point.z + math.random( Zone.radius / 2 * -1, Zone.radius / 2 )
	
	self:T( "Cargo Location = " .. ZonePos.x .. ", " .. ZonePos.y )

	--[[
	-- This does not work in 1.5.2.
	CargoStatic = StaticObject.getByName( self.CargoName )
	if CargoStatic then
		CargoStatic:destroy()
	end
	--]]
	
	CargoStatic = StaticObject.getByName( self.CargoStaticName )

	if CargoStatic and CargoStatic:isExist() then
		CargoStatic:destroy()
	end

	-- I need to make every time a new cargo due to bugs in 1.5.2.
	
		self.CargoCount = self.CargoCount + 1
		self.CargoStaticName = string.format( "%s#%03d", self.CargoName, self.CargoCount )

		local CargoTemplate = {
				["category"] = "Cargo",
				["shape_name"] = "ab-212_cargo",
				["type"] = "Cargo1",
				["x"] = ZonePos.x,
				["y"] = ZonePos.y,
				["mass"] = self.CargoWeight,
				["name"] =  self.CargoStaticName,
				["canCargo"] = true,
				["heading"] = 0,
			}
			
		coalition.addStaticObject( self.CargoCountryID, CargoTemplate )
		
--	end

	return self
end


function CARGO_SLINGLOAD:IsNear( Client, LandingZone )
self:T()

	local Near = false

	return Near
end


function CARGO_SLINGLOAD:IsInLandingZone( Client, LandingZone )
self:T()

	local Near = false

	local CargoStaticUnit = StaticObject.getByName( self.CargoName )
	if CargoStaticUnit then 
		if routines.IsStaticInZones( CargoStaticUnit, LandingZone ) then
			Near = true
		end
	end
	
	return Near
end


function CARGO_SLINGLOAD:OnBoard( Client, LandingZone, OnBoardSide )
self:T()
  
	local Valid = true
  
     
	return Valid
end


function CARGO_SLINGLOAD:OnBoarded( Client, LandingZone )
self:T()

	local OnBoarded = false
  
	local CargoStaticUnit = StaticObject.getByName( self.CargoName )
	if CargoStaticUnit then 
		if not routines.IsStaticInZones( CargoStaticUnit, LandingZone ) then
			OnBoarded = true
		end
	end

	return OnBoarded
end


function CARGO_SLINGLOAD:UnLoad( Client, TargetZoneName )
self:T()

	self:T( 'self.CargoName = ' .. self.CargoName ) 
	self:T( 'self.CargoGroupName = ' .. self.CargoGroupName ) 
	
	self:StatusUnLoaded()

	return Cargo
end
--- CLIENT Classes
-- @classmod CLIENT

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Cargo" )
Include.File( "Message" )

--- Clients are those Groups defined within the Mission Editor that have the skillset defined as "Client" or "Player".
-- These clients are defined within the Mission Orchestration Framework (MOF)

CLIENT = {
	ONBOARDSIDE = {
		NONE = 0,
		LEFT = 1,
		RIGHT = 2,
		BACK = 3,
		FRONT = 4
	},
	ClassName = "CLIENT",
	ClientName = nil,
	ClientAlive = false,
	ClientTransport = false,
	ClientBriefingShown = false,
	_Menus = {},
	_Tasks = {},
	Messages = { 
	}
}


--- Use this method to register new Clients within the MOF.
-- @tparam string ClientName Name of the Group as defined within the Mission Editor. The Group must have a Unit with the type Client.
-- @tparam string ClientBriefing Text that describes the briefing of the mission when a Player logs into the Client.
-- @treturn CLIENT
-- @usage
-- -- Create new Clients.
--	local Mission = MISSIONSCHEDULER.AddMission( 'Russia Transport Troops SA-6', 'Operational', 'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 'Russia' )
--	Mission:AddGoal( DeploySA6TroopsGoal )
--
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*HOT-Deploy Troops 1' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*RAMP-Deploy Troops 3' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*HOT-Deploy Troops 2' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*RAMP-Deploy Troops 4' ):Transport() )

function CLIENT:New( ClientName, ClientBriefing )
	local self = BASE:Inherit( self, BASE:New() )
	self:T()

	self.ClientName = ClientName
	self:AddBriefing( ClientBriefing )
	self.MessageSwitch = true
	
	return self
end

--- Resets a CLIENT.
-- @tparam string ClientName Name of the Group as defined within the Mission Editor. The Group must have a Unit with the type Client.
function CLIENT:Reset( ClientName )
self:T()
	self._Menus = {}
end

--- ClientGroup returns the Group of a Client.
-- This function is modified to deal with a couple of bugs in DCS 1.5.3
-- @treturn Group
function CLIENT:ClientGroup()
--self:T()

--  local ClientData = Group.getByName( self.ClientName )
--	if ClientData and ClientData:isExist() then
--		self:T( self.ClientName .. " : group found!" )
--		return ClientData
--	else
--		return nil
--	end

	local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ) }
	for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
		--self:T( { "CoalitionData:", CoalitionData } )
		for UnitId, UnitData in pairs( CoalitionData ) do
			--self:T( { "UnitData:", UnitData } )
			if UnitData and UnitData:isExist() then

				local ClientGroup = Group.getByName( self.ClientName )
				if ClientGroup then
					self:T( "ClientGroup = " .. self.ClientName )
					if ClientGroup:isExist() then 
						if ClientGroup:getID() == UnitData:getGroup():getID() then
							self:T( "Normal logic" )
							self:T( self.ClientName .. " : group found!" )
							return ClientGroup
						end
					else
						-- Now we need to resolve the bugs in DCS 1.5 ...
						-- Consult the database for the units of the Client Group. (ClientGroup:getUnits() returns nil)
						self:T( "Bug 1.5 logic" )
						local ClientUnits = _Database.Groups[self.ClientName].Units
						self:T( { ClientUnits[1].name, env.getValueDictByKey(ClientUnits[1].name) } )
						for ClientUnitID, ClientUnitData in pairs( ClientUnits ) do
							self:T( { tonumber(UnitData:getID()), ClientUnitData.unitId } )
							if tonumber(UnitData:getID()) == ClientUnitData.unitId then
								local ClientGroupTemplate = _Database.Groups[self.ClientName].Template
								self.ClientGroupID = ClientGroupTemplate.groupId
								self.ClientGroupUnit = UnitData
								self:T( self.ClientName .. " : group found in bug 1.5 resolvement logic!" )
								return ClientGroup
							end
						end
					end
--				else
--					error( "Client " .. self.ClientName .. " not found!" )
				end
			end
		end
	end

	-- For non player clients
	local ClientGroup = Group.getByName( self.ClientName )
	if ClientGroup then
		self:T( "ClientGroup = " .. self.ClientName )
		if ClientGroup:isExist() then 
			self:T( "Normal logic" )
			self:T( self.ClientName .. " : group found!" )
			return ClientGroup
		end
	end
	
	self.ClientGroupID = nil
	self.ClientGroupUnit = nil
	
	return nil
end 


function CLIENT:GetClientGroupID()
self:T()

	ClientGroup = self:ClientGroup()
	
	if ClientGroup then
		if ClientGroup:isExist() then
			return ClientGroup:getID()
		else
			return self.ClientGroupID
		end
	end
	
	return nil
end


function CLIENT:GetClientGroupName()
self:T()

	ClientGroup = self:ClientGroup()
	
	if ClientGroup then
		if ClientGroup:isExist() then
			self:T( ClientGroup:getName() )
			return ClientGroup:getName()
		else
			self:T( self.ClientName )
			return self.ClientName
		end
	end
	
	return nil
end

--- Returns the Unit of the @{CLIENT}.
-- @treturn Unit
function CLIENT:GetClientGroupUnit()
self:T()

	local ClientGroup = self:ClientGroup()
	
	if ClientGroup then
		if ClientGroup:isExist() then
			return UNIT:New( ClientGroup:getUnit(1) )
		else
			return UNIT:New( self.ClientGroupUnit )
		end
	end
	
	return nil
end

--- Returns the DCSUnit of the @{CLIENT}.
-- @treturn DCSUnit
function CLIENT:GetClientGroupDCSUnit()
self:T()

	local ClientGroup = self:ClientGroup()
	
	if ClientGroup then
		if ClientGroup:isExist() then
			return ClientGroup:getUnits()[1]
		else
			return self.ClientGroupUnit
		end
	end
	
	return nil
end

function CLIENT:GetUnit()
	self:T()
	
	return UNIT:New( self:GetClientGroupDCSUnit() )
end


--- Returns the Position of the @{CLIENT}.
-- @treturn Position
function CLIENT:ClientPosition()
--self:T()

	ClientGroupUnit = self:GetClientGroupDCSUnit()
	
	if ClientGroupUnit then
		if ClientGroupUnit:isExist() then
			return ClientGroupUnit:getPosition()
		end
	end
	
	return nil
end 

--- Transport defines that the Client is a Transport.
-- @treturn CLIENT
function CLIENT:Transport()
self:T()

	self.ClientTransport = true
	return self
end

--- AddBriefing adds a briefing to a Client when a Player joins a Mission.
-- @tparam string ClientBriefing is the text defining the Mission briefing.
-- @treturn CLIENT
function CLIENT:AddBriefing( ClientBriefing )
self:T()
	self.ClientBriefing = ClientBriefing
	return self
end

--- IsTransport returns if a Client is a transport.
-- @treturn bool
function CLIENT:IsTransport()
self:T()
	return self.ClientTransport
end

--- ShowCargo shows the @{CARGO} within the CLIENT to the Player.
-- The @{CARGO} is shown throught the MESSAGE system of DCS World.
function CLIENT:ShowCargo()
self:T()

	local CargoMsg = ""
  
	for CargoName, Cargo in pairs( CARGOS ) do
		if self == Cargo:IsLoadedInClient() then
			CargoMsg = CargoMsg .. Cargo.CargoName .. " Type:" ..  Cargo.CargoType .. " Weight: " .. Cargo.CargoWeight .. "\n"
		end
	end
  
	if CargoMsg == "" then
		CargoMsg = "empty"
	end
  
	self:Message( CargoMsg, 15, self.ClientName .. "/Cargo", "Co-Pilot: Cargo Status", 30 )

end

--- SwitchMessages is a local function called by the DCS World Menu system to switch off messages.
function CLIENT.SwitchMessages( PrmTable )
	PrmTable[1].MessageSwitch = PrmTable[2]
end

--- Message is the key Message driver for the CLIENT class.
-- This function displays various messages to the Player logged into the CLIENT through the DCS World Messaging system.
-- @tparam string Message is the text describing the message.
-- @tparam number MessageDuration is the duration in seconds that the Message should be displayed.
-- @tparam string MessageId is a text identifying the Message in the MessageQueue. The Message system overwrites Messages with the same MessageId
-- @tparam string MessageCategory is the category of the message (the title).
-- @tparam number MessageInterval is the interval in seconds between the display of the Message when the CLIENT is in the air.
function CLIENT:Message( Message, MessageDuration, MessageId, MessageCategory, MessageInterval )
self:T()

	if not self.MenuMessages then
		if self:GetClientGroupID() then
			self.MenuMessages = MENU_SUB_GROUP:New( self:GetClientGroupID(), 'Messages' )
			self.MenuRouteMessageOn = MENU_COMMAND_GROUP:New( self:GetClientGroupID(), 'Messages On', self.MenuMessages, CLIENT.SwitchMessages, { self, true } )
			self.MenuRouteMessageOff = MENU_COMMAND_GROUP:New( self:GetClientGroupID(),'Messages Off', self.MenuMessages, CLIENT.SwitchMessages, { self, false } )
		end
	end

	if self.MessageSwitch == true then
		if MessageCategory == nil then
			MessageCategory = "Messages"
		end
		if self.Messages[MessageId] == nil then
			self.Messages[MessageId] = {}
			self.Messages[MessageId].MessageId = MessageId
			self.Messages[MessageId].MessageTime = timer.getTime()
			self.Messages[MessageId].MessageDuration = MessageDuration
			if MessageInterval == nil then
				self.Messages[MessageId].MessageInterval = 600
			else
				self.Messages[MessageId].MessageInterval = MessageInterval
			end
			MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
		else
			if self:GetClientGroupDCSUnit() and not self:GetClientGroupDCSUnit():inAir() then
				if timer.getTime() - self.Messages[MessageId].MessageTime >= self.Messages[MessageId].MessageDuration + 10 then
					MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
					self.Messages[MessageId].MessageTime = timer.getTime()
				end
			else
				if timer.getTime() - self.Messages[MessageId].MessageTime  >= self.Messages[MessageId].MessageDuration + self.Messages[MessageId].MessageInterval then
					MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
					self.Messages[MessageId].MessageTime = timer.getTime()
				end
			end
		end
	end
end
--- Message System to display Messages for Clients and Coalitions or All.
-- Messages are grouped on the display panel per Category to improve readability for the players.
-- Messages are shown on the display panel for an amount of seconds, and will then disappear.
-- Messages are identified by an ID. The messages with the same ID belonging to the same category will be overwritten if they were still being displayed on the display panel.
-- Messages are created with MESSAGE:@{New}().
-- Messages are sent to Clients with MESSAGE:@{ToClient}().
-- Messages are sent to Coalitions with MESSAGE:@{ToCoalition}().
-- Messages are sent to All Players with MESSAGE:@{ToAll}().
-- @classmod MESSAGE

Include.File( "Trace" )
Include.File( "Base" )


MESSAGE = {
	ClassName = "MESSAGE", 
	MessageCategory = 0,
	MessageID = 0,
}


--- Creates a new MESSAGE object. Note that these MESSAGE objects are not yet displayed on the display panel. You must use the functions @{ToClient} or @{ToCoalition} or @{ToAll} to send these Messages to the respective recipients.
-- @tparam string MessageText is the text of the Message.
-- @tparam string MessageCategory is a string expressing the Category of the Message. Messages are grouped on the display panel per Category to improve readability.
-- @tparam number MessageDuration is a number in seconds of how long the MESSAGE should be shown on the display panel.
-- @tparam string MessageID is a string expressing the ID of the Message.
-- @treturn MESSAGE
-- @usage
-- -- Create a series of new Messages.
-- -- MessageAll is meant to be sent to all players, for 25 seconds, and is classified as "Score".
-- -- MessageRED is meant to be sent to the RED players only, for 10 seconds, and is classified as "End of Mission", with ID "Win".
-- -- MessageClient1 is meant to be sent to a Client, for 25 seconds, and is classified as "Score", with ID "Score".
-- -- MessageClient1 is meant to be sent to a Client, for 25 seconds, and is classified as "Score", with ID "Score".
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" )
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageClient1 = MESSAGE:New( "Congratulations, you've just hit a target", "Score", 25, "Score" )
-- MessageClient2 = MESSAGE:New( "Congratulations, you've just killed a target", "Score", 25, "Score" )
function MESSAGE:New( MessageText, MessageCategory, MessageDuration, MessageID )
trace.f(self.ClassName, { MessageText, MessageCategory, MessageDuration, MessageID } )

	local self = BASE:Inherit( self, BASE:New() )
	
	self.MessageCategory = MessageCategory
	self.MessageDuration = MessageDuration
	self.MessageID = MessageID
	self.MessageTime = timer.getTime()
	self.MessageText = MessageText
	
	self.MessageSent = false
	self.MessageGroup = false
	self.MessageCoalition = false

	return self
end

--- Sends a MESSAGE to a Client Group. Note that the Group needs to be defined within the ME with the skillset "Client" or "Player".
-- @tparam CLIENT Client is the Group of the Client.
-- @treturn MESSAGE
-- @usage
-- -- Send the 2 messages created with the @{New} method to the Client Group.
-- -- Note that the Message of MessageClient2 is overwriting the Message of MessageClient1.
-- ClientGroup = Group.getByName( "ClientGroup" )
--
-- MessageClient1 = MESSAGE:New( "Congratulations, you've just hit a target", "Score", 25, "Score" ):ToClient( ClientGroup )
-- MessageClient2 = MESSAGE:New( "Congratulations, you've just killed a target", "Score", 25, "Score" ):ToClient( ClientGroup )
-- or
-- MESSAGE:New( "Congratulations, you've just hit a target", "Score", 25, "Score" ):ToClient( ClientGroup )
-- MESSAGE:New( "Congratulations, you've just killed a target", "Score", 25, "Score" ):ToClient( ClientGroup )
-- or
-- MessageClient1 = MESSAGE:New( "Congratulations, you've just hit a target", "Score", 25, "Score" )
-- MessageClient2 = MESSAGE:New( "Congratulations, you've just killed a target", "Score", 25, "Score" )
-- MessageClient1:ToClient( ClientGroup )
-- MessageClient2:ToClient( ClientGroup )
function MESSAGE:ToClient( Client )
trace.f(self.ClassName )

	if Client and Client:GetClientGroupID() then

		local ClientGroupID = Client:GetClientGroupID()
		trace.i( self.ClassName, self.MessageCategory .. '\n' .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
		trigger.action.outTextForGroup( ClientGroupID, self.MessageCategory .. '\n' .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration )
	end
	
	return self
end

--- Sends a MESSAGE to the Blue coalition. 
-- @treturn MESSAGE
-- @usage
-- -- Send a message created with the @{New} method to the BLUE coalition.
-- MessageBLUE = MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToBlue()
-- or
-- MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToBlue()
-- or
-- MessageBLUE = MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageBLUE:ToBlue()
function MESSAGE:ToBlue()
trace.f(self.ClassName )

	self:ToCoalition( coalition.side.BLUE )
	
	return self
end

--- Sends a MESSAGE to the Red Coalition. 
-- @treturn MESSAGE
-- @usage
-- -- Send a message created with the @{New} method to the RED coalition.
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToRed()
-- or
-- MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToRed()
-- or
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageRED:ToRed()
function MESSAGE:ToRed( )
trace.f(self.ClassName )

	self:ToCoalition( coalition.side.RED )
	
	return self
end

--- Sends a MESSAGE to a Coalition. 
-- @param CoalitionSide needs to be filled out by the defined structure of the standard scripting engine @{coalition.side}. 
-- @treturn MESSAGE
-- @usage
-- -- Send a message created with the @{New} method to the RED coalition.
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToCoalition( coalition.side.RED )
-- or
-- MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToCoalition( coalition.side.RED )
-- or
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageRED:ToCoalition( coalition.side.RED )
function MESSAGE:ToCoalition( CoalitionSide )
trace.f(self.ClassName )

	if CoalitionSide then
		trace.i(self.ClassName, self.MessageCategory .. '\n' .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
		trigger.action.outTextForCoalition( CoalitionSide, self.MessageCategory .. '\n' .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration )
	end
	
	return self
end

--- Sends a MESSAGE to all players. 
-- @treturn MESSAGE
-- @usage
-- -- Send a message created to all players.
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" ):ToAll()
-- or
-- MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" ):ToAll()
-- or
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" )
-- MessageAll:ToAll()
function MESSAGE:ToAll()
trace.f(self.ClassName )

	self:ToCoalition( coalition.side.RED )
	self:ToCoalition( coalition.side.BLUE )

	return self
end



--- MESSAGEQUEUE
-- @type MESSAGEQUEUE

MESSAGEQUEUE = {
	ClientGroups = {},
	CoalitionSides = {}
}

function MESSAGEQUEUE:New( RefreshInterval )
trace.f( self.ClassName, { RefreshInterval } )

	local self = BASE:Inherit( self, BASE:New() )
	
	self.RefreshInterval = RefreshInterval

	self.DisplayFunction = routines.scheduleFunction( self._DisplayMessages, { self }, 0, RefreshInterval )

	return self
end

--- This function is called automatically by the MESSAGEQUEUE scheduler.
function MESSAGEQUEUE:_DisplayMessages()

	-- First we display all messages that a coalition needs to receive... Also those who are not in a client (CA module clients...).
	for CoalitionSideID, CoalitionSideData in pairs( self.CoalitionSides ) do
		for MessageID, MessageData in pairs( CoalitionSideData.Messages ) do
			if MessageData.MessageSent == false then
				--trigger.action.outTextForCoalition( CoalitionSideID, MessageData.MessageCategory .. '\n' .. MessageData.MessageText:gsub("\n$",""):gsub("\n$",""), MessageData.MessageDuration )
				MessageData.MessageSent = true
			end
			local MessageTimeLeft = ( MessageData.MessageTime + MessageData.MessageDuration ) - timer.getTime()
			if MessageTimeLeft <= 0 then
				MessageData = nil
			end
		end
	end

	-- Then we send the messages for each individual client, but also to be included are those Coalition messages for the Clients who belong to a coalition.
	-- Because the Client messages will overwrite the Coalition messages (for that Client).
	for ClientGroupName, ClientGroupData in pairs( self.ClientGroups ) do
		for MessageID, MessageData in pairs( ClientGroupData.Messages ) do
			if MessageData.MessageGroup == false then
				trigger.action.outTextForGroup( Group.getByName(ClientGroupName):getID(), MessageData.MessageCategory .. '\n' .. MessageData.MessageText:gsub("\n$",""):gsub("\n$",""), MessageData.MessageDuration )
				MessageData.MessageGroup = true
			end
			local MessageTimeLeft = ( MessageData.MessageTime + MessageData.MessageDuration ) - timer.getTime()
			if MessageTimeLeft <= 0 then
				MessageData = nil
			end
		end
		
		-- Now check if the Client also has messages that belong to the Coalition of the Client...
		for CoalitionSideID, CoalitionSideData in pairs( self.CoalitionSides ) do
			for MessageID, MessageData in pairs( CoalitionSideData.Messages ) do
				local CoalitionGroup = Group.getByName( ClientGroupName )
				if CoalitionGroup and CoalitionGroup:getCoalition() == CoalitionSideID then 
					if MessageData.MessageCoalition == false then
						trigger.action.outTextForGroup( Group.getByName(ClientGroupName):getID(), MessageData.MessageCategory .. '\n' .. MessageData.MessageText:gsub("\n$",""):gsub("\n$",""), MessageData.MessageDuration )
						MessageData.MessageCoalition = true
					end
				end
				local MessageTimeLeft = ( MessageData.MessageTime + MessageData.MessageDuration ) - timer.getTime()
				if MessageTimeLeft <= 0 then
					MessageData = nil
				end
			end
		end
	end
end

--- The _MessageQueue object is created when the MESSAGE class module is loaded.
--_MessageQueue = MESSAGEQUEUE:New( 0.5 )

--- Stages within a @{TASK} within a @{MISSION}. All of the STAGE functionality is considered internally administered and not to be used by any Mission designer.
-- @classmod STAGE
-- @author Flightcontrol

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )


STAGE = {
  ClassName = "STAGE",
  MSG = { ID = "None", TIME = 10 },
  FREQUENCY = { NONE = 0, ONCE = 1, REPEAT = -1 },
  
  Name = "NoStage",
  StageType = '',
  WaitTime = 1,
  Frequency = 1,
  MessageCount = 0,
  MessageInterval = 15,
  MessageShown = {},
  MessageShow = false,
  MessageFlash = false
}


function STAGE:New()
	local self = BASE:Inherit( self, BASE:New() )
	self:T()
	return self
end

function STAGE:Execute( Mission, Client, Task )

	local Valid = true
  
	return Valid
end

function STAGE:Executing( Mission, Client, Task )

end

function STAGE:Validate( Mission, Client, Task )
  local Valid = true

  return Valid
end


STAGEBRIEF = {
	ClassName = "BRIEF",
	MSG = { ID = "Brief", TIME = 1 },
	Name = "Brief",
	StageBriefingTime = 0,
	StageBriefingDuration = 1
}

function STAGEBRIEF:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'CLIENT'
	return self
end

function STAGEBRIEF:Execute( Mission, Client, Task )
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )
	self:T()
	Mission:ShowBriefing( Client )
	self.StageBriefingTime = timer.getTime()
	return Valid 
end

function STAGEBRIEF:Validate( Mission, Client, Task )
	local Valid = STAGE:Validate( Mission, Client, Task )
	self:T()

	if timer.getTime() - self.StageBriefingTime <= self.StageBriefingDuration then
		return 0
	else
		self.StageBriefingTime = timer.getTime()
		return 1
	end
  
end


STAGESTART = {
  ClassName = "START",
  MSG = { ID = "Start", TIME = 1 },
  Name = "Start",
  StageStartTime = 0,
  StageStartDuration = 1
}

function STAGESTART:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'CLIENT'
	return self
end

function STAGESTART:Execute( Mission, Client, Task )
self:T()
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )
	if Task.TaskBriefing then
		Client:Message( Task.TaskBriefing, 30,  Mission.Name .. "/Stage", "Mission Command: Tasking" )
	else
		Client:Message( 'Task ' .. Task.TaskNumber .. '.', 30, Mission.Name .. "/Stage", "Mission Command: Tasking" )
	end
	self.StageStartTime = timer.getTime()
	return Valid 
end

function STAGESTART:Validate( Mission, Client, Task )
self:T()
	local Valid = STAGE:Validate( Mission, Client, Task )

	if timer.getTime() - self.StageStartTime <= self.StageStartDuration then
		return 0
	else
		self.StageStartTime = timer.getTime()
		return 1
	end
  
	return 1
  
end

STAGE_CARGO_LOAD = {
  ClassName = "STAGE_CARGO_LOAD"
}

function STAGE_CARGO_LOAD:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'CLIENT'
	return self
end

function STAGE_CARGO_LOAD:Execute( Mission, Client, Task )
self:T()
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )

	for LoadCargoID, LoadCargo in pairs( Task.Cargos.LoadCargos ) do
		LoadCargo:Load( Client )
	end

	if Mission.MissionReportFlash and Client:IsTransport() then
		Client:ShowCargo()
	end

	return Valid
end

function STAGE_CARGO_LOAD:Validate( Mission, Client, Task )
self:T()
	local Valid = STAGE:Validate( Mission, Client, Task )

	return 1
end


STAGE_CARGO_INIT = {
  ClassName = "STAGE_CARGO_INIT"
}

function STAGE_CARGO_INIT:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'CLIENT'
	return self
end

function STAGE_CARGO_INIT:Execute( Mission, Client, Task )
self:T()
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )

	for InitLandingZoneID, InitLandingZone in pairs( Task.LandingZones.LandingZones ) do
		self:T( InitLandingZone )
		InitLandingZone:Spawn()
	end
	

	self:T( Task.Cargos.InitCargos )
	for InitCargoID, InitCargoData in pairs( Task.Cargos.InitCargos ) do
		self:T( { InitCargoData } )
		InitCargoData:Spawn( Client )
	end
	
	return Valid
end


function STAGE_CARGO_INIT:Validate( Mission, Client, Task )
self:T()
	local Valid = STAGE:Validate( Mission, Client, Task )

	return 1
end



STAGEROUTE = {
  ClassName = "STAGEROUTE",
  MSG = { ID = "Route", TIME = 5 },
  Frequency = STAGE.FREQUENCY.REPEAT,
  Name = "Route"
}

function STAGEROUTE:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'CLIENT'
	self.MessageSwitch = true
	return self
end


function STAGEROUTE:Execute( Mission, Client, Task )
self:T()
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )

	local RouteMessage = "Fly to "
	self:T( Task.LandingZones )
	for LandingZoneID, LandingZoneName in pairs( Task.LandingZones.LandingZoneNames ) do
		RouteMessage = RouteMessage .. LandingZoneName .. ' at ' .. routines.getBRStringZone( { zone = LandingZoneName, ref = Client:GetClientGroupDCSUnit():getPoint(), true, true } ) .. ' km. '
	end
	Client:Message( RouteMessage, self.MSG.TIME, Mission.Name .. "/StageRoute", "Co-Pilot: Route", 20 )

	if Mission.MissionReportFlash and Client:IsTransport() then
		Client:ShowCargo()
	end

	return Valid
end

function STAGEROUTE:Validate( Mission, Client, Task )
self:T()
	local Valid = STAGE:Validate( Mission, Client, Task )
	
	-- check if the Client is in the landing zone
	self:T( Task.LandingZones.LandingZoneNames )
	Task.CurrentLandingZoneName = routines.IsUnitInZones( Client:GetClientGroupDCSUnit(), Task.LandingZones.LandingZoneNames )
	
	if  Task.CurrentLandingZoneName then

		Task.CurrentLandingZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName].CargoZone
		Task.CurrentCargoZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName]

		if Task.CurrentCargoZone then 
			if not Task.Signalled then
				Task.Signalled = Task.CurrentCargoZone:Signal() 
			end
		end

		return 1
	end
  
	return 0
end



STAGELANDING = {
  ClassName = "STAGELANDING",
  MSG = { ID = "Landing", TIME = 10 },
  Name = "Landing",
  Signalled = false
}

function STAGELANDING:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'CLIENT'
	return self
end

function STAGELANDING:Execute( Mission, Client, Task )
self:T()
 
	Client:Message( "We have arrived at the landing zone.", self.MSG.TIME, Mission.Name .. "/StageArrived", "Co-Pilot: Arrived", 10 )

 	Task.HostUnit = Task.CurrentCargoZone:GetHostUnit()
	
	self:T( { Task.HostUnit } )

	if Task.HostUnit then
	
		Task.HostUnitName = Task.HostUnit:GetPrefix()
		Task.HostUnitTypeName = Task.HostUnit:GetTypeName()
		
		local HostMessage = ""
		Task.CargoNames = ""

		local IsFirst = true
		
		for CargoID, Cargo in pairs( CARGOS ) do
			if Cargo.CargoType == Task.CargoType then

				if Cargo:IsLandingRequired() then
					self:T( "Task for cargo " .. Cargo.CargoType .. " requires landing.")
					Task.IsLandingRequired = true
				end
				
				if Cargo:IsSlingLoad() then
					self:T( "Task for cargo " .. Cargo.CargoType .. " is a slingload.")
					Task.IsSlingLoad = true
				end

				if IsFirst then
					IsFirst = false
					Task.CargoNames = Task.CargoNames  .. Cargo.CargoName .. "( " .. Cargo.CargoWeight .. " )"
				else
					Task.CargoNames = Task.CargoNames  .. "; " .. Cargo.CargoName .. "( " .. Cargo.CargoWeight .. " )"
				end
			end
		end
		
		if Task.IsLandingRequired then
			HostMessage = "Land the helicopter to " .. Task.TEXT[1] .. " " .. Task.CargoNames .. "."
		else
			HostMessage = "Use the Radio menu and F6 to find the cargo, then fly or land near the cargo and " .. Task.TEXT[1] .. " " .. Task.CargoNames .. "."
		end
		
		Client:Message( HostMessage, self.MSG.TIME, Mission.Name .. "/STAGELANDING.EXEC." .. Task.HostUnitName, Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")" .. ":", 10 )
		
	end
end

function STAGELANDING:Validate( Mission, Client, Task )
self:T()
  
	Task.CurrentLandingZoneName = routines.IsUnitInZones( Client:GetClientGroupDCSUnit(), Task.LandingZones.LandingZoneNames )
	if Task.CurrentLandingZoneName then
	
		-- Client is in de landing zone.
		self:T( Task.CurrentLandingZoneName )
		
		Task.CurrentLandingZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName].CargoZone
		Task.CurrentCargoZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName]

		if Task.CurrentCargoZone then 
			if not Task.Signalled then
				Task.Signalled = Task.CurrentCargoZone:Signal() 
			end
		end
	else
		if Task.CurrentLandingZone then
			Task.CurrentLandingZone = nil
		end
		if Task.CurrentCargoZone then
			Task.CurrentCargoZone = nil
		end
		Task.Signalled = false 
		Task:RemoveCargoMenus( Client )
		return -1
	end
  
	if Task.IsLandingRequired and Client:GetClientGroupDCSUnit():inAir() then
		return 0
	end
  
	return 1
end

STAGELANDED = {
  ClassName = "STAGELANDED",
  MSG = { ID = "Land", TIME = 10 },
  Name = "Landed",
  MenusAdded = false
}

function STAGELANDED:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'CLIENT'
	return self
end

function STAGELANDED:Execute( Mission, Client, Task )
self:T()

	if Task.IsLandingRequired then
		Client:Message( 'We have landed within the landing zone. Use the radio menu (F10) to ' .. Task.TEXT[1]  .. ' the ' .. Task.CargoType .. '.', 
		                self.MSG.TIME,  Mission.Name .. "/STAGELANDED.EXEC." .. Task.HostUnitName, Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")" .. ":" )
		if not self.MenusAdded then
			Task.Cargo = nil
			Task:RemoveCargoMenus( Client )
			Task:AddCargoMenus( Client, CARGOS, 250 )
		end
	end
end



function STAGELANDED:Validate( Mission, Client, Task )
self:T()

	if not routines.IsUnitInZones( Client:GetClientGroupDCSUnit(), Task.CurrentLandingZoneName ) then
	    self:T( "Client is not anymore in the landing zone, go back to stage Route, and remove cargo menus." )
		Task.Signalled = false 
		Task:RemoveCargoMenus( Client )
		return -2
	end
  
	if Task.IsLandingRequired and Client:GetClientGroupDCSUnit():inAir() then
		self:T( "Client went back in the air. Go back to stage Landing." )
		Task.Signalled = false 
		return -1
	end
  
    -- Wait until cargo is selected from the menu.
	if Task.IsLandingRequired then 
		if not Task.Cargo then
			return 0
		end
	end
  
	return 1
end

STAGEUNLOAD = {
  ClassName = "STAGEUNLOAD",
  MSG = { ID = "Unload", TIME = 10 },
  Name = "Unload"
}

function STAGEUNLOAD:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'CLIENT'
	return self
end

function STAGEUNLOAD:Execute( Mission, Client, Task )
self:T()
	Client:Message( 'The ' .. Task.CargoType .. ' are being ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
                    self.MSG.TIME,  Mission.Name .. "/StageUnLoad", "Co-Pilot: Unload" )
	Task:RemoveCargoMenus( Client )
end

function STAGEUNLOAD:Executing( Mission, Client, Task )
self:T()
	env.info( 'STAGEUNLOAD:Executing() Task.Cargo.CargoName = ' .. Task.Cargo.CargoName )
	
	local TargetZoneName
	
	if Task.TargetZoneName then
		TargetZoneName = Task.TargetZoneName
	else
		TargetZoneName = Task.CurrentLandingZoneName
	end
	
	if Task.Cargo:UnLoad( Client, TargetZoneName ) then
		Task.ExecuteStage = _TransportExecuteStage.SUCCESS
		if Mission.MissionReportFlash then
			Client:ShowCargo()
		end
	end
end

function STAGEUNLOAD:Validate( Mission, Client, Task )
self:T()
	env.info( 'STAGEUNLOAD:Validate()' )
  
  if routines.IsUnitInZones( Client:GetClientGroupDCSUnit(), Task.CurrentLandingZoneName ) then
  else
    Task.ExecuteStage = _TransportExecuteStage.FAILED
	Task:RemoveCargoMenus( Client )
    Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
	                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Co-Pilot: Unload" )
    return 1
  end
  
  if not Client:GetClientGroupDCSUnit():inAir() then
  else
    Task.ExecuteStage = _TransportExecuteStage.FAILED
	Task:RemoveCargoMenus( Client )
    Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
	                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Co-Pilot: Unload" )
    return 1
  end
  
  if  Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
    Client:Message( 'The ' .. Task.CargoType .. ' have been sucessfully ' .. Task.TEXT[3] .. '  within the landing zone.', _TransportStageMsgTime.DONE,  Mission.Name .. "/Stage", "Co-Pilot: Unload" )
	Task:RemoveCargoMenus( Client )
	Task.MissionTask:AddGoalCompletion( Task.MissionTask.GoalVerb, Task.CargoName, 1 ) -- We set the cargo as one more goal completed in the mission.
    return 1
  end
  
  return 1
end

STAGELOAD = {
  ClassName = "STAGELOAD",
  MSG = { ID = "Load", TIME = 10 },
  Name = "Load"
}

function STAGELOAD:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'CLIENT'
	return self
end

function STAGELOAD:Execute( Mission, Client, Task )
self:T()
	
	if not Task.IsSlingLoad then
		Client:Message( 'The ' .. Task.CargoType .. ' are being ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
						_TransportStageMsgTime.EXECUTING,  Mission.Name .. "/STAGELOAD.EXEC." .. Task.HostUnitName, Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")" .. ":" )

		-- Route the cargo to the Carrier
		Task.Cargo:OnBoard( Client, Task.CurrentCargoZone, Task.OnBoardSide )
		Task.ExecuteStage = _TransportExecuteStage.EXECUTING
	else
		Task.ExecuteStage = _TransportExecuteStage.EXECUTING
	end
end

function STAGELOAD:Executing( Mission, Client, Task )
self:T()

	-- If the Cargo is ready to be loaded, load it into the Client.

		
	if not Task.IsSlingLoad then
		trace.i(self.ClassName, Task.Cargo.CargoName)
		
		if Task.Cargo:OnBoarded( Client, Task.CurrentCargoZone ) then

			-- Load the Cargo onto the Client
			Task.Cargo:Load( Client )
		
			-- Message to the pilot that cargo has been loaded.
			Client:Message( "The cargo " .. Task.Cargo.CargoName .. " has been loaded in our helicopter.", 
							20, Mission.Name .. "/STAGELANDING.LOADING1." .. Task.HostUnitName, Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")" .. ":" )
			Task.ExecuteStage = _TransportExecuteStage.SUCCESS
			
			Client:ShowCargo()
		end
	else
		Client:Message( "Hook the " .. Task.CargoNames .. " onto the helicopter " .. Task.TEXT[3] .. " within the landing zone.", 
						_TransportStageMsgTime.EXECUTING,  Mission.Name .. "/STAGELOAD.LOADING.1." .. Task.HostUnitName, Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")" .. ":", 10 )
		for CargoID, Cargo in pairs( CARGOS ) do
			self:T( "Cargo.CargoName = " .. Cargo.CargoName )
			
			if Cargo:IsSlingLoad() then
				local CargoStatic = StaticObject.getByName( Cargo.CargoStaticName )
				if CargoStatic then
					trace.i(self.ClassName, "Cargo is found in the DCS simulator.")
					local CargoStaticPosition = CargoStatic:getPosition().p
					trace.i(self.ClassName, "Cargo Position x = " .. CargoStaticPosition.x .. ", y = " ..  CargoStaticPosition.y .. ", z = " ..  CargoStaticPosition.z )
					local CargoStaticHeight = routines.GetUnitHeight( CargoStatic )
					if CargoStaticHeight > 5 then
						trace.i(self.ClassName, "Cargo is airborne.")
						Cargo:StatusLoaded()
						Task.Cargo = Cargo
						Client:Message( 'The Cargo has been successfully hooked onto the helicopter and is now being sling loaded. Fly outside the landing zone.', 
										self.MSG.TIME,  Mission.Name .. "/STAGELANDING.LOADING.2." .. Task.HostUnitName, Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")" .. ":" )
						Task.ExecuteStage = _TransportExecuteStage.SUCCESS
						break
					end
				else
					self:T( "Cargo not found in the DCS simulator." )
				end
			end
		end
	end
  
end

function STAGELOAD:Validate( Mission, Client, Task )
self:T()

	self:T( "Task.CurrentLandingZoneName = " .. Task.CurrentLandingZoneName )

 	if not Task.IsSlingLoad then
		if not routines.IsUnitInZones( Client:GetClientGroupDCSUnit(), Task.CurrentLandingZoneName ) then
			Task:RemoveCargoMenus( Client )
			Task.ExecuteStage = _TransportExecuteStage.FAILED
			Task.CargoName = nil 
			Client:Message( "The " .. Task.CargoType .. " loading has been aborted. You flew outside the pick-up zone while loading. ", 
							self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.1." .. Task.HostUnitName, Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")" .. ":" )
			return -1
		end

		if not Client:GetClientGroupDCSUnit():inAir() then
		else
			-- The carrier is back in the air, undo the loading process.
			Task:RemoveCargoMenus( Client )
			Task.ExecuteStage = _TransportExecuteStage.NONE
			Task.CargoName = nil
			Client:Message( "The " .. Task.CargoType .. " loading has been aborted. Re-start the " .. Task.TEXT[3] .. " process. Don't fly outside the pick-up zone.", 
							self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.2." .. Task.HostUnitName, Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")" .. ":" )
			return -1
		end

		if Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
			Task:RemoveCargoMenus( Client )
			Client:Message( "Good Job. The " .. Task.CargoType .. " has been sucessfully " .. Task.TEXT[3] .. " within the landing zone.", 
							self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.3." .. Task.HostUnitName, Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")" .. ":" )
			Task.MissionTask:AddGoalCompletion( Task.MissionTask.GoalVerb, Task.CargoName, 1 )
			return 1
		end

	else
		if Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
			CargoStatic = StaticObject.getByName( Task.Cargo.CargoStaticName )
			if CargoStatic and not routines.IsStaticInZones( CargoStatic, Task.CurrentLandingZoneName ) then
				Client:Message( "Good Job. The " .. Task.CargoType .. " has been sucessfully " .. Task.TEXT[3] .. " and flown outside of the landing zone.", 
								self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.4." .. Task.HostUnitName, Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")" .. ":" )
				Task.MissionTask:AddGoalCompletion( Task.MissionTask.GoalVerb, Task.Cargo.CargoName, 1 )
				return 1
			end
		end
	
	end
  
 
	return 0
end


STAGEDONE = {
  ClassName = "STAGEDONE",
  MSG = { ID = "Done", TIME = 10 },
  Name = "Done"
}

function STAGEDONE:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'AI'
	return self
end

function STAGEDONE:Execute( Mission, Client, Task )
self:T()

end

function STAGEDONE:Validate( Mission, Client, Task )
self:T()

	Task:Done()
  
	return 0
end

STAGEARRIVE = {
  ClassName = "STAGEARRIVE",
  MSG = { ID = "Arrive", TIME = 10 },
  Name = "Arrive"
}

function STAGEARRIVE:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'CLIENT'
	return self
end

function STAGEARRIVE:Execute( Mission, Client, Task )
self:T()
 
  Client:Message( 'We have arrived at ' .. Task.CurrentLandingZoneName .. ".", self.MSG.TIME,  Mission.Name .. "/Stage", "Co-Pilot: Arrived" )

  end

function STAGEARRIVE:Validate( Mission, Client, Task )
self:T()
  
  Task.CurrentLandingZoneID  = routines.IsUnitInZones( Client:GetClientGroupDCSUnit(), Task.LandingZones )
  if  ( Task.CurrentLandingZoneID ) then
  else
    return -1
  end
  
  return 1
end

STAGEGROUPSDESTROYED = {
  ClassName = "STAGEGROUPSDESTROYED",
  DestroyGroupSize = -1,
  Frequency = STAGE.FREQUENCY.REPEAT,
  MSG = { ID = "DestroyGroup", TIME = 10 },
  Name = "GroupsDestroyed"
}

function STAGEGROUPSDESTROYED:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:T()
	self.StageType = 'AI'
	return self
end

--function STAGEGROUPSDESTROYED:Execute( Mission, Client, Task )
-- 
--	Client:Message( 'Task: Still ' .. DestroyGroupSize .. " of " .. Task.DestroyGroupCount .. " " .. Task.DestroyGroupType .. " to be destroyed!", self.MSG.TIME,  Mission.Name .. "/Stage" )
--
--end

function STAGEGROUPSDESTROYED:Validate( Mission, Client, Task )
self:T()
 
	if Task.MissionTask:IsGoalReached() then
		return 1
	else
		return 0
	end
end

function STAGEGROUPSDESTROYED:Execute( Mission, Client, Task )
self:T()
	self:T( { Task.ClassName, Task.Destroyed } )
	--env.info( 'Event Table Task = ' .. tostring(Task) )

end













--[[
  _TransportStage: Defines the different stages of which of transport missions can be in. This table is internal and is used to control the sequence of messages, actions and flow.
  
  - _TransportStage.START
  - _TransportStage.ROUTE
  - _TransportStage.LAND
  - _TransportStage.EXECUTE
  - _TransportStage.DONE
  - _TransportStage.REMOVE
--]]
_TransportStage = { 
  HOLD = "HOLD",
  START = "START", 
  ROUTE = "ROUTE", 
  LANDING = "LANDING",
  LANDED = "LANDED",
  EXECUTING = "EXECUTING",
  LOAD = "LOAD",
  UNLOAD = "UNLOAD",
  DONE = "DONE", 
  NEXT = "NEXT"
}

_TransportStageMsgTime = { 
  HOLD = 10,
  START = 60, 
  ROUTE = 5, 
  LANDING = 10,
  LANDED = 30,
  EXECUTING = 30,
  LOAD = 30,
  UNLOAD = 30,
  DONE = 30, 
  NEXT = 0
}

_TransportStageTime = { 
  HOLD = 10,
  START = 5, 
  ROUTE = 5, 
  LANDING = 1,
  LANDED = 1,
  EXECUTING = 5,
  LOAD = 5,
  UNLOAD = 5,
  DONE = 1, 
  NEXT = 0
}

_TransportStageAction = { 
  REPEAT = -1,
  NONE = 0,
  ONCE = 1
}
--- The TASK Classes define major end-to-end activities within a MISSION. The TASK Class is the Master Class to orchestrate these activities. From this class, many concrete TASK classes are inherited.
-- @classmod TASK

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Stage" )

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
-- @treturn TASK
function TASK:New()
trace.f(self.ClassName)

  local self = BASE:Inherit( self, BASE:New() )

  -- assign Task default values during construction
  self.TaskBriefing = "Task: No Task."
  self.Time = timer.getTime()
  self.ExecuteStage = _TransportExecuteStage.NONE

  return self
end

function TASK:SetStage( StageSequenceIncrement )
trace.f(self.ClassName, { StageSequenceIncrement } )

	local Valid = false
	if StageSequenceIncrement ~= 0 then
		self.ActiveStage = self.ActiveStage + StageSequenceIncrement
		if 1 <= self.ActiveStage and self.ActiveStage <= #self.Stages then
			self.Stage = self.Stages[self.ActiveStage]
			trace.i( self.ClassName, { self.Stage.Name } )
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
trace.f(self.ClassName)
	self.ActiveStage = 0
	self:SetStage(1)
	self.TaskDone = false
	self.TaskFailed = false
end


--- Get progress of a TASK.
-- @treturn string GoalsText
function TASK:GetGoalProgress()
trace.f(self.ClassName)

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
-- @tparam MISSION 	Mission 		Group structure describing the Mission.
-- @tparam CLIENT	Client	 		Group structure describing the Client.
function TASK:ShowGoalProgress( Mission, Client )
trace.f(self.ClassName)

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
trace.f(self.ClassName)
	self.TaskDone = true
end

--- Returns if a TASK is done.
-- @treturn bool
function TASK:IsDone()
	trace.i( self.ClassName, self.TaskDone )
	return self.TaskDone
end

--- Sets a TASK to status failed.
function TASK:Failed()
trace.f(self.ClassName)
	self.TaskFailed = true
end

--- Returns if a TASk has failed.
-- @return bool
function TASK:IsFailed()
	trace.i( self.ClassName, self.TaskFailed )
	return self.TaskFailed
end

function TASK:Reset( Mission, Client )
trace.f(self.ClassName)
	self.ExecuteStage = _TransportExecuteStage.NONE
end

--- Returns the Goals of a TASK
-- @treturn @table Goals
function TASK:GetGoals()
	return self.GoalTasks
end

--- Returns if a TASK has Goal(s).
-- @tparam ?string GoalVerb is the name of the Goal of the TASK.
-- @treturn bool
function TASK:Goal( GoalVerb )
trace.f(self.ClassName)
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
-- @tparam number GoalTotal is the number of times the GoalVerb needs to be achieved.
-- @tparam ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
function TASK:SetGoalTotal( GoalTotal, GoalVerb )
trace.f(self.ClassName, { GoalTotal, GoalVerb } )
	
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
-- @tparam ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
function TASK:GetGoalTotal( GoalVerb )
trace.f(self.ClassName)
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
-- @tparam number GoalCount is the total number of Goals achieved within the TASK.
-- @tparam ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
-- @treturn TASK
function TASK:SetGoalCount( GoalCount, GoalVerb )
trace.f(self.ClassName)
	if not GoalVerb then
		GoalVerb = self.GoalVerb
	end
	if self:Goal( GoalVerb) then
		self.GoalTasks[GoalVerb].GoalCount = GoalCount
	end
	return self
end

--- Increments the total of Goals currently achieved within the TASK of the GoalVerb, with the given GoalCountIncrease.
-- @tparam number GoalCountIncrease is the number of new Goals achieved within the TASK.
-- @tparam ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
-- @treturn TASK
function TASK:IncreaseGoalCount( GoalCountIncrease, GoalVerb )
trace.f(self.ClassName)
	if not GoalVerb then
		GoalVerb = self.GoalVerb
	end
	if self:Goal( GoalVerb) then
		self.GoalTasks[GoalVerb].GoalCount = self.GoalTasks[GoalVerb].GoalCount + GoalCountIncrease
	end
	return self
end

--- Gets the total of Goals currently achieved within the TASK of the GoalVerb.
-- @tparam ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
-- @treturn TASK
function TASK:GetGoalCount( GoalVerb )
trace.f(self.ClassName)
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
-- @tparam ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
-- @treturn TASK
function TASK:GetGoalPercentage( GoalVerb )
trace.f(self.ClassName)
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
-- @treturn bool
function TASK:IsGoalReached( )

	local GoalReached = true

	for GoalVerb, Goals in pairs( self.GoalTasks ) do
		trace.i( self.ClassName, { "GoalVerb", GoalVerb } )
		if self:Goal( GoalVerb ) then
			local GoalToDo = self:GetGoalTotal( GoalVerb ) - self:GetGoalCount( GoalVerb )
			trace.i( self.ClassName, "GoalToDo = " .. GoalToDo )
			if GoalToDo <= 0 then
			else
				GoalReached = false
				break
			end
		else
			break
		end
	end
	
	trace.i( self.ClassName, GoalReached )
	return GoalReached
end

--- Adds an Additional Goal for the TASK to be achieved.
-- @tparam string GoalVerb is the name of the Goal of the TASK.
-- @tparam string GoalTask is a text describing the Goal of the TASK to be achieved.
-- @tparam number GoalIncrease is a number by which the Goal achievement is increasing.
function TASK:AddGoalCompletion( GoalVerb, GoalTask, GoalIncrease )
trace.f( self.ClassName, { GoalVerb, GoalTask, GoalIncrease } )

	if self:Goal( GoalVerb ) then
		self.GoalTasks[GoalVerb].Goals[#self.GoalTasks[GoalVerb].Goals+1] = GoalTask
		self.GoalTasks[GoalVerb].GoalCount = self.GoalTasks[GoalVerb].GoalCount + GoalIncrease
	end
	return self
end

--- Returns if the additional Goal for the TASK was completed.
-- @tparam ?string GoalVerb is the name of the Goal of the TASK. If the GoalVerb is not given, then the default TASK Goals will be used.
-- @treturn string Goals
function TASK:GetGoalCompletion( GoalVerb )
trace.f( self.ClassName, { GoalVerb } )
	
	if self:Goal( GoalVerb ) then
		local Goals = ""
		for GoalID, GoalName in pairs( self.GoalTasks[GoalVerb].Goals ) do Goals = Goals .. GoalName .. " + " end
		return Goals:gsub(" + $", ""), self.GoalTasks[GoalVerb].GoalCount
	end
end

function TASK.MenuAction( Parameter )
trace.menu("TASK","MenuAction")
  trace.l( "TASK", "MenuAction" )
  Parameter.ReferenceTask.ExecuteStage = _TransportExecuteStage.EXECUTING
  Parameter.ReferenceTask.Cargo = Parameter.CargoTask
end

function TASK:StageExecute()
trace.f(self.ClassName)

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
trace.f(self.ClassName)
  
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
-- @tparam table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @tparam number SignalHeight Altitude that the Signal should be fired...
function TASK:AddSmokeRed( SignalUnitNames, SignalHeight )
trace.f(self.ClassName)
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.SMOKE, TASK.SIGNAL.COLOR.RED, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, a GREEN SMOKE will be fired by an optional SignalUnitNames.
-- @tparam table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @tparam number SignalHeight Altitude that the Signal should be fired...
function TASK:AddSmokeGreen( SignalUnitNames, SignalHeight )
trace.f(self.ClassName)
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.SMOKE, TASK.SIGNAL.COLOR.GREEN, SignalHeight )
end
        
--- When the CLIENT is approaching the landing zone, a BLUE SMOKE will be fired by an optional SignalUnitNames.
-- @tparam table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @tparam number SignalHeight Altitude that the Signal should be fired...
function TASK:AddSmokeBlue( SignalUnitNames, SignalHeight )
trace.f(self.ClassName)
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.SMOKE, TASK.SIGNAL.COLOR.BLUE, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, a WHITE SMOKE will be fired by an optional SignalUnitNames.
-- @tparam table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @tparam number SignalHeight Altitude that the Signal should be fired...
function TASK:AddSmokeWhite( SignalUnitNames, SignalHeight )
trace.f(self.ClassName)
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.SMOKE, TASK.SIGNAL.COLOR.WHITE, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, an ORANGE SMOKE will be fired by an optional SignalUnitNames.
-- @tparam table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @tparam number SignalHeight Altitude that the Signal should be fired...
function TASK:AddSmokeOrange( SignalUnitNames, SignalHeight )
trace.f(self.ClassName)
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.SMOKE, TASK.SIGNAL.COLOR.ORANGE, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, a RED FLARE will be fired by an optional SignalUnitNames.
-- @tparam table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @tparam number SignalHeight Altitude that the Signal should be fired...
function TASK:AddFlareRed( SignalUnitNames, SignalHeight )
trace.f(self.ClassName)
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.FLARE, TASK.SIGNAL.COLOR.RED, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, a GREEN FLARE will be fired by an optional SignalUnitNames.
-- @tparam table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @tparam number SignalHeight Altitude that the Signal should be fired...
function TASK:AddFlareGreen( SignalUnitNames, SignalHeight )
trace.f(self.ClassName)
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.FLARE, TASK.SIGNAL.COLOR.GREEN, SignalHeight )
end
        
--- When the CLIENT is approaching the landing zone, a BLUE FLARE will be fired by an optional SignalUnitNames.
-- @tparam table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @tparam number SignalHeight Altitude that the Signal should be fired...
function TASK:AddFlareBlue( SignalUnitNames, SignalHeight )
trace.f(self.ClassName)
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.FLARE, TASK.SIGNAL.COLOR.BLUE, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, a WHITE FLARE will be fired by an optional SignalUnitNames.
-- @tparam table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @tparam number SignalHeight Altitude that the Signal should be fired...
function TASK:AddFlareWhite( SignalUnitNames, SignalHeight )
trace.f(self.ClassName)
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.FLARE, TASK.SIGNAL.COLOR.WHITE, SignalHeight )
end

--- When the CLIENT is approaching the landing zone, an ORANGE FLARE will be fired by an optional SignalUnitNames.
-- @tparam table|string SignalUnitNames Name of the Group that will fire the signal. If this parameter is NIL, the signal will be fired from the center of the landing zone.
-- @tparam number SignalHeight Altitude that the Signal should be fired...
function TASK:AddFlareOrange( SignalUnitNames, SignalHeight )
trace.f(self.ClassName)
  self:AddSignal( SignalUnitNames, TASK.SIGNAL.TYPE.FLARE, TASK.SIGNAL.COLOR.ORANGE, SignalHeight )
end
--- A GOHOMETASK orchestrates the travel back to the home base, which is a specific zone defined within the ME.
-- @classmod GOHOMETASK

Include.File("Task")

GOHOMETASK = {
  ClassName = "GOHOMETASK",
}

--- Creates a new GOHOMETASK.
-- @tparam table{string,...}|string LandingZones Table of Landing Zone names where Home(s) are located.
-- @treturn GOHOMETASK
function GOHOMETASK:New( LandingZones )
trace.f(self.ClassName)

  -- Child holds the inherited instance of the PICKUPTASK Class to the BASE class.
  local Child = BASE:Inherit( self, TASK:New() )

  local Valid = true
  
  Valid = routines.ValidateZone( LandingZones, "LandingZones", Valid )
    
  if  Valid then
    Child.Name = 'Fly Home'
    Child.TaskBriefing = "Task: Fly back to your home base. Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to your home base."
	if type( LandingZones ) == "table" then
		Child.LandingZones = LandingZones
	else
		Child.LandingZones = { LandingZones }
	end
    Child.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGEARRIVE:New(), STAGEDONE:New() }
		Child.SetStage( Child, 1 )
  end
  
  return Child
end
--- A DESTROYBASETASK will monitor the destruction of Groups and Units. This is a BASE class, other classes are derived from this class.
-- @classmod DESTROYBASETASK
-- @see DESTROYGROUPSTASK
-- @see DESTROYUNITTYPESTASK
-- @see DESTROY_RADARS_TASK

Include.File("Task")

DESTROYBASETASK = {
  ClassName = "DESTROYBASETASK",
  Destroyed = 0,
  GoalVerb = "Destroy",
  DestroyPercentage = 100,
}

--- Creates a new DESTROYBASETASK.
-- @tparam string DestroyGroupType Text describing the group to be destroyed. f.e. "Radar Installations", "Ships", "Vehicles", "Command Centers".
-- @tparam string DestroyUnitType Text describing the unit types to be destroyed. f.e. "SA-6", "Row Boats", "Tanks", "Tents".
-- @tparam table{string,...} DestroyGroupPrefixes Table of Prefixes of the Groups to be destroyed before task is completed.
-- @tparam ?number DestroyPercentage defines the %-tage that needs to be destroyed to achieve mission success. eg. If in the Group there are 10 units, then a value of 75 would require 8 units to be destroyed from the Group to complete the @{TASK}.
-- @treturn DESTROYBASETASK
function DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupPrefixes, DestroyPercentage )
	local self = BASE:Inherit( self, TASK:New() )
	self:T()
	
	self.Name = 'Destroy'
	self.Destroyed = 0
	self.DestroyGroupPrefixes = DestroyGroupPrefixes
	self.DestroyGroupType = DestroyGroupType
	self.DestroyUnitType = DestroyUnitType
	self.TaskBriefing = "Task: Destroy " .. DestroyGroupType .. "."
    self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEGROUPSDESTROYED:New(), STAGEDONE:New() }
	self.SetStage( self, 1 )

	--self.AddEvent( self, world.event.S_EVENT_DEAD, self.EventDead )

	--env.info( 'New Table self = ' .. tostring(self) )
	--env.info( 'New Table self = ' .. tostring(self) )
	
	return self
end

--- Handle the S_EVENT_DEAD events to validate the destruction of units for the task monitoring.
-- @param 	event 		Event structure of DCS world.
function DESTROYBASETASK:EventDead( event )
	self:T( { 'EventDead', event } )
	
	if event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT then
		local DestroyUnit = event.initiator
		local DestroyUnitName = DestroyUnit:getName()
		local DestroyGroup = Unit.getGroup( DestroyUnit )
		local DestroyGroupName = ""
		if DestroyGroup and DestroyGroup:isExist() then
			local DestroyGroupName = DestroyGroup:getName()
		end
		local UnitsDestroyed = 0
		self:T( DestroyGroupName )
		self:T( DestroyUnitName )
		for DestroyGroupPrefixID, DestroyGroupPrefix in pairs( self.DestroyGroupPrefixes ) do
			self:T( DestroyGroupPrefix )
			if string.find( DestroyGroupName, DestroyGroupPrefix, 1, true ) then
				self:T( BASE:Inherited(self).ClassName )
				UnitsDestroyed = self:ReportGoalProgress( DestroyGroup, DestroyUnit )
				self:T( UnitsDestroyed )
			end
		end
		
		self:T( { UnitsDestroyed } )
		self:IncreaseGoalCount( UnitsDestroyed, self.GoalVerb )
	end
end

--- Validate task completeness of DESTROYBASETASK.
-- @param 	DestroyGroup 		Group structure describing the group to be evaluated.
-- @param 	DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYBASETASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
self:T()

	return 0
end
--- DESTROYGROUPSTASK
-- @classmod DESTROYGROUPSTASK

Include.File("DestroyBaseTask")

--- To monitor and score the destruction of Groups in the DCSRTE.
DESTROYGROUPSTASK = {
  ClassName = "DESTROYGROUPSTASK",
  GoalVerb = "Destroy Groups",
}

--- Creates a new DESTROYGROUPSTASK.
-- @tparam 	string DestroyGroupType 	String describing the group to be destroyed.
-- @tparam 	string DestroyUnitType 	String describing the unit to be destroyed.
-- @tparam 	table{string,...} DestroyGroupNames 	Table of string containing the name of the groups to be destroyed before task is completed.
-- @tparam ?number DestroyPercentage defines the %-tage that needs to be destroyed to achieve mission success. eg. If in the Group there are 10 units, then a value of 75 would require 8 units to be destroyed from the Group to complete the @{TASK}.
---@treturn DESTROYGROUPSTASK
function DESTROYGROUPSTASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyPercentage )
trace.f(self.ClassName)

	-- Inheritance
	local Child = BASE:Inherit( self, DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyPercentage ) )

	Child.Name = 'Destroy Groups'
	Child.GoalVerb = "Destroy " .. DestroyGroupType
	
	Child.AddEvent( Child, world.event.S_EVENT_DEAD, Child.EventDead )
	Child.AddEvent( Child, world.event.S_EVENT_CRASH, Child.EventDead )
	--Child.AddEvent( Child, world.event.S_EVENT_PILOT_DEAD, Child.EventDead )

	return Child
end

--- Report Goal Progress.
-- @tparam 	Group DestroyGroup 		Group structure describing the group to be evaluated.
-- @tparam 	Unit DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYGROUPSTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
trace.f(self.ClassName)
	trace.i( self.ClassName, DestroyGroup:getSize() )

	local DestroyCount = 0
	if DestroyGroup then
		if ( ( DestroyGroup:getInitialSize() * self.DestroyPercentage ) / 100 ) - DestroyGroup:getSize() <= 0 then
			DestroyCount = 1
--[[ 		else
			if DestroyGroup:getSize() == 1 then
				if DestroyUnit and DestroyUnit:getLife() <= 1.0 then
					DestroyCount = 1
				end
			end
 ]]		end
	else
		DestroyCount = 1
	end
	
	return DestroyCount
end
--- Task class to destroy radar installations.
-- @classmod DESTROYRADARSTASK 

Include.File("DestroyBaseTask")

DESTROYRADARSTASK = {
  ClassName = "DESTROYRADARSTASK",
  GoalVerb = "Destroy Radars"
}

--- Creates a new DESTROYRADARSTASK.
-- @tparam table{string,...} DestroyGroupNames 	Table of string containing the group names of which the radars are be destroyed.
-- @treturn DESTROYRADARSTASK
function DESTROYRADARSTASK:New( DestroyGroupNames )
trace.f(self.ClassName)

	-- Inheritance
	local Child = BASE:Inherit( self, DESTROYGROUPSTASK:New( 'radar installations', 'radars', DestroyGroupNames ) )

	Child.Name = 'Destroy Radars'

	
	Child.AddEvent( Child, world.event.S_EVENT_DEAD, Child.EventDead )

	return Child
end

--- Report Goal Progress.
-- @tparam 	Group DestroyGroup 		Group structure describing the group to be evaluated.
-- @tparam 	Unit DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYRADARSTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
trace.f(self.ClassName)

	local DestroyCount = 0
	if DestroyUnit and DestroyUnit:hasSensors( Unit.SensorType.RADAR, Unit.RadarType.AS ) then
		if DestroyUnit and DestroyUnit:getLife() <= 1.0 then
			trace.i( self.ClassName, 'Destroyed a radar' )
			DestroyCount = 1
		end
	end
	return DestroyCount
end
--- Set TASK to destroy certain unit types.
-- @classmod DESTROYUNITTYPESTASK

Include.File("DestroyBaseTask")

DESTROYUNITTYPESTASK = {
  ClassName = "DESTROYUNITTYPESTASK",
	GoalVerb = "Destroy",
}

--- Creates a new DESTROYUNITTYPESTASK.
-- @tparam string DestroyGroupType 		String describing the group to be destroyed. f.e. "Radar Installations", "Fleet", "Batallion", "Command Centers".
-- @tparam string DestroyUnitType 		String describing the unit to be destroyed. f.e. "radars", "ships", "tanks", "centers".
-- @tparam table{string,...} DestroyGroupNames 	Table of string containing the group names of which the radars are be destroyed.
-- @tparam string DestroyUnitTypes	 	Table of string containing the type names of the units to achieve mission success.
-- @treturn DESTROYUNITTYPESTASK
function DESTROYUNITTYPESTASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyUnitTypes )
trace.f(self.ClassName)

	-- Inheritance
	local Child = BASE:Inherit( self, DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames ) )
	
	if type(DestroyUnitTypes) == 'table' then
		Child.DestroyUnitTypes = DestroyUnitTypes
	else
		Child.DestroyUnitTypes = { DestroyUnitTypes }
	end
	
	Child.Name = 'Destroy Unit Types'
	Child.GoalVerb = "Destroy " .. DestroyGroupType

	--env.info( 'New Types Child = ' .. tostring(Child) )
	--env.info( 'New Types self = ' .. tostring(self) )

	Child.AddEvent( Child, world.event.S_EVENT_DEAD, Child.EventDead )

	return Child
end

--- Report Goal Progress.
-- @tparam 	Group DestroyGroup 		Group structure describing the group to be evaluated.
-- @tparam 	Unit DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYUNITTYPESTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
trace.f(self.ClassName)

	local DestroyCount = 0
	for UnitTypeID, UnitType in pairs( self.DestroyUnitTypes ) do
		if DestroyUnit and DestroyUnit:getTypeName() == UnitType then
			if DestroyUnit and DestroyUnit:getLife() <= 1.0 then
				DestroyCount = DestroyCount + 1
			end
		end
	end
	return DestroyCount
end
--- A PICKUPTASK orchestrates the loading of CARGO at a specific landing zone.
-- @classmod PICKUPTASK
-- @parent TASK

Include.File("Task")
Include.File("Cargo")

PICKUPTASK = {
  ClassName = "PICKUPTASK",
  TEXT = { "Pick-Up", "picked-up", "loaded" },
  GoalVerb = "Pick-Up"
}

--- Creates a new PICKUPTASK.
-- @tparam table{string,...}|string LandingZones Table of Zone names where Cargo is to be loaded.
-- @tparam CARGO_TYPE CargoType Type of the Cargo. The type must be of the following Enumeration:..
-- @tparam number OnBoardSide Reflects from which side the cargo Group will be on-boarded on the Carrier.
function PICKUPTASK:New( CargoType, OnBoardSide )
    local self = BASE:Inherit( self, TASK:New() )
	self:T()

    -- self holds the inherited instance of the PICKUPTASK Class to the BASE class.

    local Valid = true
  
    if  Valid then
		self.Name = 'Pickup Cargo'
		self.TaskBriefing = "Task: Fly to the indicated landing zones and pickup " .. CargoType .. ". Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the pickup zone."
		self.CargoType = CargoType
		self.GoalVerb = CargoType .. " " .. self.GoalVerb
		self.OnBoardSide = OnBoardSide
		self.IsLandingRequired = false -- required to decide whether the client needs to land or not
		self.IsSlingLoad = false -- Indicates whether the cargo is a sling load cargo
		self.Stages = { STAGE_CARGO_INIT:New(), STAGE_CARGO_LOAD:New(), STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGELANDING:New(), STAGELANDED:New(), STAGELOAD:New(), STAGEDONE:New() }
		self.SetStage( self, 1 )
	end
  
  return self
end

function PICKUPTASK:FromZone( LandingZone )
self:T()

	self.LandingZones.LandingZoneNames[LandingZone.CargoZoneName] = LandingZone.CargoZoneName
	self.LandingZones.LandingZones[LandingZone.CargoZoneName] = LandingZone
	
	return self
end

function PICKUPTASK:InitCargo( InitCargos )
self:T( { InitCargos } )

	if type( InitCargos ) == "table" then
		self.Cargos.InitCargos = InitCargos
	else
		self.Cargos.InitCargos = { InitCargos }
	end

	return self
end

function PICKUPTASK:LoadCargo( LoadCargos )
self:T( { LoadCargos } )

	if type( LoadCargos ) == "table" then
		self.Cargos.LoadCargos = LoadCargos
	else
		self.Cargos.LoadCargos = { LoadCargos }
	end

	return self
end

function PICKUPTASK:AddCargoMenus( Client, Cargos, TransportRadius )
self:T()
  
	for CargoID, Cargo in pairs( Cargos ) do

		self:T( { Cargo.ClassName, Cargo.CargoName, Cargo.CargoType, Cargo:IsStatusNone(), Cargo:IsStatusLoaded(), Cargo:IsStatusLoading(), Cargo:IsStatusUnLoaded() } )
		
		-- If the Cargo has no status, allow the menu option.
		if Cargo:IsStatusNone() or ( Cargo:IsStatusLoading() and Client == Cargo:IsLoadingToClient() ) then
		
			local MenuAdd = false
			if Cargo:IsNear( Client, self.CurrentCargoZone ) then
				MenuAdd = true
			end
			
			if MenuAdd then
				if Client._Menus[Cargo.CargoType] == nil then
					Client._Menus[Cargo.CargoType] = {}
				end
				
				if not Client._Menus[Cargo.CargoType].PickupMenu then
					Client._Menus[Cargo.CargoType].PickupMenu = missionCommands.addSubMenuForGroup(
						Client:GetClientGroupID(), 
						self.TEXT[1] .. " " .. Cargo.CargoType, 
						nil
					)
					self:T( 'Added PickupMenu: ' .. self.TEXT[1] .. " " .. Cargo.CargoType )
				end

				if Client._Menus[Cargo.CargoType].PickupSubMenus == nil then
					Client._Menus[Cargo.CargoType].PickupSubMenus = {}
				end

				Client._Menus[Cargo.CargoType].PickupSubMenus[ #Client._Menus[Cargo.CargoType].PickupSubMenus + 1 ] = missionCommands.addCommandForGroup(
					Client:GetClientGroupID(), 
					Cargo.CargoName .. " ( " .. Cargo.CargoWeight .. "kg )",
					Client._Menus[Cargo.CargoType].PickupMenu, 
					self.MenuAction,
					{ ReferenceTask = self, CargoTask = Cargo }
				)
				self:T( 'Added PickupSubMenu' .. Cargo.CargoType .. ":" .. Cargo.CargoName .. " ( " .. Cargo.CargoWeight .. "kg )" )
			end
		end
	end
	
end

function PICKUPTASK:RemoveCargoMenus( Client )
self:T()

	for MenuID, MenuData in pairs( Client._Menus ) do
		for SubMenuID, SubMenuData in pairs( MenuData.PickupSubMenus ) do
			missionCommands.removeItemForGroup( Client:GetClientGroupID(), SubMenuData )
			self:T( "Removed PickupSubMenu " )
			SubMenuData = nil
		end
		if MenuData.PickupMenu then
			missionCommands.removeItemForGroup( Client:GetClientGroupID(), MenuData.PickupMenu )
			self:T( "Removed PickupMenu " )
			MenuData.PickupMenu = nil
		end
	end
	
	for CargoID, Cargo in pairs( CARGOS ) do
		self:T( { Cargo.ClassName, Cargo.CargoName, Cargo.CargoType, Cargo:IsStatusNone(), Cargo:IsStatusLoaded(), Cargo:IsStatusLoading(), Cargo:IsStatusUnLoaded() } )
		if Cargo:IsStatusLoading() and Client == Cargo:IsLoadingToClient() then
			Cargo:StatusNone()
		end
	end
		
end



function PICKUPTASK:HasFailed( ClientDead )
self:T()

	local TaskHasFailed = self.TaskFailed
	return TaskHasFailed
end

--- A DEPLOYTASK orchestrates the deployment of CARGO within a specific landing zone.
-- @classmod DEPLOYTASK

Include.File( "Task" )

DEPLOYTASK = {
  ClassName = "DEPLOYTASK",
  TEXT = { "Deploy", "deployed", "unloaded" },
  GoalVerb = "Deployment"
}


--- Creates a new DEPLOYTASK object, which models the sequence of STAGEs to unload a cargo.
-- @tparam table{string,...}|string LandingZones Table or name of the zone(s) where Cargo is to be unloaded.
-- @tparam CARGO_TYPE CargoType Type of the Cargo.
function DEPLOYTASK:New( CargoType )
	local self = BASE:Inherit( self, TASK:New() )
	self:T()

	local Valid = true
  
    if Valid then
		self.Name = 'Deploy Cargo'
		self.TaskBriefing = "Fly to one of the indicated landing zones and deploy " .. CargoType .. ". Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the deployment zone."
		self.CargoType = CargoType
		self.GoalVerb = CargoType .. " " .. self.GoalVerb
		self.Stages = { STAGE_CARGO_INIT:New(), STAGE_CARGO_LOAD:New(), STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGELANDING:New(), STAGELANDED:New(), STAGEUNLOAD:New(), STAGEDONE:New() }
		self.SetStage( self, 1 )
	end
  
	return self
end

function DEPLOYTASK:ToZone( LandingZone )
self:T()

	self.LandingZones.LandingZoneNames[LandingZone.CargoZoneName] = LandingZone.CargoZoneName
	self.LandingZones.LandingZones[LandingZone.CargoZoneName] = LandingZone
	
	return self
end


function DEPLOYTASK:InitCargo( InitCargos )
self:T( { InitCargos } )

	if type( InitCargos ) == "table" then
		self.Cargos.InitCargos = InitCargos
	else
		self.Cargos.InitCargos = { InitCargos }
	end

	return self
end


function DEPLOYTASK:LoadCargo( LoadCargos )
self:T( { LoadCargos } )

	if type( LoadCargos ) == "table" then
		self.Cargos.LoadCargos = LoadCargos
	else
		self.Cargos.LoadCargos = { LoadCargos }
	end

	return self
end


--- When the cargo is unloaded, it will move to the target zone name.
-- @tparam string TargetZoneName Name of the Zone to where the Cargo should move after unloading.
function DEPLOYTASK:SetCargoTargetZoneName( TargetZoneName )
self:T()
  
  local Valid = true
  
  Valid = routines.ValidateString( TargetZoneName, "TargetZoneName", Valid )
  
  if Valid then
    self.TargetZoneName = TargetZoneName
  end
  
  return Valid
  
end

function DEPLOYTASK:AddCargoMenus( Client, Cargos, TransportRadius )
self:T()

	local ClientGroupID = Client:GetClientGroupID()
	
	trace.i( self.ClassName, ClientGroupID )
	
	for CargoID, Cargo in pairs( Cargos ) do

		trace.i( self.ClassName, { Cargo.ClassName, Cargo.CargoName, Cargo.CargoType, Cargo.CargoWeight } )
		
		if Cargo:IsStatusLoaded() and Client == Cargo:IsLoadedInClient() then

			if Client._Menus[Cargo.CargoType] == nil then
				Client._Menus[Cargo.CargoType] = {}
			end
			
			if not Client._Menus[Cargo.CargoType].DeployMenu then
				Client._Menus[Cargo.CargoType].DeployMenu = missionCommands.addSubMenuForGroup(
					ClientGroupID, 
					self.TEXT[1] .. " " .. Cargo.CargoType, 
					nil
				)
				trace.i( self.ClassName, 'Added DeployMenu ' .. self.TEXT[1] )
			end
			
			if Client._Menus[Cargo.CargoType].DeploySubMenus == nil then
				Client._Menus[Cargo.CargoType].DeploySubMenus = {}
			end
			
			if Client._Menus[Cargo.CargoType].DeployMenu == nil then
				trace.i( self.ClassName, 'deploymenu is nil' )
			end

			Client._Menus[Cargo.CargoType].DeploySubMenus[ #Client._Menus[Cargo.CargoType].DeploySubMenus + 1 ] = missionCommands.addCommandForGroup(
				ClientGroupID, 
				Cargo.CargoName .. " ( " .. Cargo.CargoWeight .. "kg )",
				Client._Menus[Cargo.CargoType].DeployMenu, 
				self.MenuAction,
				{ ReferenceTask = self, CargoTask = Cargo }
			)
			trace.i( self.ClassName, 'Added DeploySubMenu ' .. Cargo.CargoType .. ":" .. Cargo.CargoName .. " ( " .. Cargo.CargoWeight .. "kg )" )
		end
	end

end

function DEPLOYTASK:RemoveCargoMenus( Client )
self:T()

	local ClientGroupID = Client:GetClientGroupID()
	trace.i( self.ClassName, ClientGroupID )

	for MenuID, MenuData in pairs( Client._Menus ) do
		if MenuData.DeploySubMenus ~= nil then
			for SubMenuID, SubMenuData in pairs( MenuData.DeploySubMenus ) do
				missionCommands.removeItemForGroup( ClientGroupID, SubMenuData )
				trace.i( self.ClassName, "Removed DeploySubMenu " )
				SubMenuData = nil
			end
		end
		if MenuData.DeployMenu then
			missionCommands.removeItemForGroup( ClientGroupID, MenuData.DeployMenu )
			trace.i( self.ClassName, "Removed DeployMenu " )
			MenuData.DeployMenu = nil
		end
	end

end
--- A NOTASK is a dummy activity... But it will show a Mission Briefing...
-- @classmod NOTASK

Include.File("Task")

--- Modeling a sequence of STAGEs to do nothing, but wait for the mission goal.
NOTASK = {
  ClassName = "NOTASK",
}

--- Creates a new NOTASK.
function NOTASK:New()
trace.f(self.ClassName)

  -- Child holds the inherited instance of the PICKUPTASK Class to the BASE class.
  local Child = BASE:Inherit( self, TASK:New() )

  local Valid = true

  if  Valid then
    Child.Name = 'Nothing'
    Child.TaskBriefing = "Task: Execute your mission."
    Child.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEDONE:New() }
	Child.SetStage( Child, 1 )
  end
  
  return Child
end
--- A ROUTETASK orchestrates the travel to a specific zone defined within the ME.
-- @classmod ROUTETASK

--- Modeling a sequence of STAGEs to fly back to the home base specified by an Arrival Zone.
ROUTETASK = {
  ClassName = "ROUTETASK",
  GoalVerb = "Route",
}

--- Creates a new ROUTETASK.
-- @tparam table{sring,...}|string LandingZones Table of Zone Names where the target is located.
-- @tparam string TaskBriefing (optional) Defines a text describing the briefing of the task.
-- @treturn ROUTETASK
function ROUTETASK:New( LandingZones, TaskBriefing )
trace.f(self.ClassName, { LandingZones, TaskBriefing } )

  -- Child holds the inherited instance of the PICKUPTASK Class to the BASE class.
  local Child = BASE:Inherit( self, TASK:New() )

  local Valid = true
  
  Valid = routines.ValidateZone( LandingZones, "LandingZones", Valid )
    
  if  Valid then
    Child.Name = 'Route To Zone'
	if TaskBriefing then
		Child.TaskBriefing = TaskBriefing .. " Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the target objective."
	else
		Child.TaskBriefing = "Task: Fly to specified zone(s). Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the target objective."
	end
	if type( LandingZones ) == "table" then
		Child.LandingZones = LandingZones
	else
		Child.LandingZones = { LandingZones }
	end
    Child.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGEARRIVE:New(), STAGEDONE:New() }
	Child.SetStage( Child, 1 )
  end
  
  return Child
end

--- A MISSION is the main owner of a Mission orchestration within MOOSE	. The Mission framework orchestrates @{CLIENT}s, @{TASK}s, @{STAGE}s etc.
-- A @{CLIENT} needs to be registered within the @{MISSION} through the function @{AddClient}. A @{TASK} needs to be registered within the @{MISSION} through the function @{AddTask}.
-- @classmod MISSION

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Client" )
Include.File( "Task" )


MISSION = {
	ClassName = "MISSION",
	Name = "",
	MissionStatus = "PENDING",
	_Clients = {},
	_Tasks = {},
	_ActiveTasks = {},
	GoalFunction = nil,
	MissionReportTrigger = 0,
	MissionProgressTrigger = 0,
	MissionReportShow = false,
	MissionReportFlash = false,
	MissionTimeInterval = 0,
	MissionCoalition = "",
	SUCCESS = 1,
	FAILED = 2,
	REPEAT = 3,
	_GoalTasks = {}
}


function MISSION:Meta()

	local self = BASE:Inherit( self, BASE:New() )
	self:T()
	
	return self
end

--- This is the main MISSION declaration method. Each Mission is like the master or a Mission orchestration between, Clients, Tasks, Stages etc.
-- @tparam string MissionName is the name of the mission. This name will be used to reference the status of each mission by the players.
-- @tparam string MissionPriority is a string indicating the "priority" of the Mission. f.e. "Primary", "Secondary" or "First", "Second". It is free format and up to the Mission designer to choose. There are no rules behind this field.
-- @tparam string MissionBriefing is a string indicating the mission briefing to be shown when a player joins a @{CLIENT}.
-- @tparam string MissionCoalition is a string indicating the coalition or party to which this mission belongs to. It is free format and can be chosen freely by the mission designer. Note that this field is not to be confused with the coalition concept of the ME. Examples of a Mission Coalition could be "NATO", "CCCP", "Intruders", "Terrorists"...
-- @treturn MISSION
-- @usage 
-- -- Declare a few missions.
-- local Mission = MISSIONSCHEDULER.AddMission( 'Russia Transport Troops SA-6', 'Operational', 'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 'Russia' )
-- local Mission = MISSIONSCHEDULER.AddMission( 'Patriots', 'Primary', 'Our intelligence reports that 3 Patriot SAM defense batteries are located near Ruisi, Kvarhiti and Gori.', 'Russia'  )
-- local Mission = MISSIONSCHEDULER.AddMission( 'Package Delivery', 'Operational', 'In order to be in full control of the situation, we need you to deliver a very important package at a secret location. Fly undetected through the NATO defenses and deliver the secret package. The secret agent is located at waypoint 4.', 'Russia'  )
-- local Mission = MISSIONSCHEDULER.AddMission( 'Rescue General', 'Tactical', 'Our intelligence has received a remote signal behind Gori. We believe it is a very important Russian General that was captured by Georgia. Go out there and rescue him! Ensure you stay out of the battle zone, keep south. Waypoint 4 is the location of our Russian General.', 'Russia'  )
-- local Mission = MISSIONSCHEDULER.AddMission( 'NATO Transport Troops', 'Operational', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.', 'NATO' )
-- local Mission = MISSIONSCHEDULER.AddMission( 'SA-6 SAMs', 'Primary', 'Our intelligence reports that 3 SA-6 SAM defense batteries are located near Didmukha, Khetagurov and Berula. Eliminate the Russian SAMs.', 'NATO'  )
-- local Mission = MISSIONSCHEDULER.AddMission( 'NATO Sling Load', 'Operational', 'Fly to the cargo pickup zone at Dzegvi or Kaspi, and sling the cargo to Soganlug airbase.', 'NATO' )
-- local Mission = MISSIONSCHEDULER.AddMission( 'Rescue secret agent', 'Tactical', 'In order to be in full control of the situation, we need you to rescue a secret agent from the woods behind enemy lines. Avoid the Russian defenses and rescue the agent. Keep south until Khasuri, and keep your eyes open for any SAM presence. The agent is located at waypoint 4 on your kneeboard.', 'NATO'  )
function MISSION:New( MissionName, MissionPriority, MissionBriefing, MissionCoalition )

	self = MISSION:Meta()
	self:T({ MissionName, MissionPriority, MissionBriefing, MissionCoalition })
  
	local Valid = true
  
	Valid = routines.ValidateString( MissionName, "MissionName", Valid )
	Valid = routines.ValidateString( MissionPriority, "MissionPriority", Valid )
	Valid = routines.ValidateString( MissionBriefing, "MissionBriefing", Valid )
	Valid = routines.ValidateString( MissionCoalition, "MissionCoalition", Valid )
  
	if Valid then
		self.Name = MissionName
		self.MissionPriority = MissionPriority
		self.MissionBriefing = MissionBriefing
		self.MissionCoalition = MissionCoalition
	end

	return self
end

--- Returns if a Mission has completed.
-- @treturn bool
function MISSION:IsCompleted()
	self:T()
	return self.MissionStatus == "ACCOMPLISHED"
end

--- Set a Mission to completed.
function MISSION:Completed()
	self:T()
	self.MissionStatus = "ACCOMPLISHED"
	self:StatusToClients()
end

--- Returns if a Mission is ongoing.
-- treturn bool
function MISSION:IsOngoing()
	self:T()
	return self.MissionStatus == "ONGOING"
end

--- Set a Mission to ongoing.
function MISSION:Ongoing()
	self:T()
	self.MissionStatus = "ONGOING"
	--self:StatusToClients()
end

--- Returns if a Mission is pending.
-- treturn bool
function MISSION:IsPending()
	self:T()
	return self.MissionStatus == "PENDING"
end

--- Set a Mission to pending.
function MISSION:Pending()
	self:T()
	self.MissionStatus = "PENDING"
	self:StatusToClients()
end

--- Returns if a Mission has failed.
-- treturn bool
function MISSION:IsFailed() 
	self:T()
	return self.MissionStatus == "FAILED"
end

--- Set a Mission to failed.
function MISSION:Failed()
	self:T()
	self.MissionStatus = "FAILED"
	self:StatusToClients()
end

--- Send the status of the MISSION to all Clients.
function MISSION:StatusToClients()
	self:T()
	if self.MissionReportFlash then
		for ClientID, Client in pairs( self._Clients ) do
			Client:Message( self.MissionCoalition .. ' "' .. self.Name .. '": ' .. self.MissionStatus .. '! ( ' .. self.MissionPriority .. ' mission ) ', 10,  self.Name .. '/Status', "Mission Command: Mission Status")
		end
	end
end

--- Handles the reporting. After certain time intervals, a MISSION report MESSAGE will be shown to All Players.
function MISSION:ReportTrigger()
	self:T()

	if self.MissionReportShow == true then
		self.MissionReportShow = false
trace.r( "MISSION", "1", { true } )
		return true
	else
		if self.MissionReportFlash == true then
			if timer.getTime() >= self.MissionReportTrigger then
				self.MissionReportTrigger = timer.getTime() + self.MissionTimeInterval
trace.r( "MISSION", "2", { true } )
				return true
			else
trace.r( "MISSION", "3", { false } )
				return false
			end
		else
trace.r( "MISSION", "4", { false } )
			return false 
		end
	end
trace.e()
end

--- Report the status of all MISSIONs to all active Clients.
function MISSION:ReportToAll()
	self:T()

	local AlivePlayers = ''
	for ClientID, Client in pairs( self._Clients ) do
		if  Client:ClientGroup() then
			if Client:GetClientGroupDCSUnit() then
				if Client:GetClientGroupDCSUnit():getLife() > 0.0 then
					if AlivePlayers == '' then
						AlivePlayers = ' Players: ' .. Client:GetClientGroupDCSUnit():getPlayerName()
					else
						AlivePlayers = AlivePlayers .. ' / ' .. Client:GetClientGroupDCSUnit():getPlayerName()
					end
				end
			end
		end
	end
	local Tasks = self:GetTasks()
	local TaskText = ""
	for TaskID, TaskData in pairs( Tasks ) do
		TaskText = TaskText .. "         - Task " .. TaskID .. ": " .. TaskData.Name .. ": " .. TaskData:GetGoalProgress() .. "\n"
	end
	MESSAGE:New( self.MissionCoalition .. ' "' .. self.Name .. '": ' .. self.MissionStatus .. ' ( ' .. self.MissionPriority .. ' mission )' .. AlivePlayers .. "\n" .. TaskText:gsub("\n$",""), "Mission Command: Mission Report", 10,  self.Name .. '/Status'):ToAll()
end


--- Add a goal function to a MISSION. Goal functions are called when a @{TASK} within a mission has been completed.
-- @tparam function GoalFunction is the function defined by the mission designer to evaluate whether a certain goal has been reached after a @{TASK} finishes within the @{MISSION}. A GoalFunction must accept 2 parameters: Mission, Client, which contains the current MISSION object and the current CLIENT object respectively.
-- @usage
--  PatriotActivation = { 
--		{ "US SAM Patriot Zerti", false },
--		{ "US SAM Patriot Zegduleti", false },
--		{ "US SAM Patriot Gvleti", false }
--	}
--
--	function DeployPatriotTroopsGoal( Mission, Client )
--
--
--		-- Check if the cargo is all deployed for mission success.
--		for CargoID, CargoData in pairs( Mission._Cargos ) do
--			if Group.getByName( CargoData.CargoGroupName ) then
--				CargoGroup = Group.getByName( CargoData.CargoGroupName )
--				if CargoGroup then
--					-- Check if the cargo is ready to activate
--					CurrentLandingZoneID = routines.IsUnitInZones( CargoGroup:getUnits()[1], Mission:GetTask( 2 ).LandingZones ) -- The second task is the Deploytask to measure mission success upon
--					if CurrentLandingZoneID then
--						if PatriotActivation[CurrentLandingZoneID][2] == false then
--							-- Now check if this is a new Mission Task to be completed...
--							trigger.action.setGroupAIOn( Group.getByName( PatriotActivation[CurrentLandingZoneID][1] ) )
--							PatriotActivation[CurrentLandingZoneID][2] = true
--							MessageToBlue( "Mission Command: Message to all airborne units! The " .. PatriotActivation[CurrentLandingZoneID][1] .. " is armed. Our air defenses are now stronger.", 60, "BLUE/PatriotDefense" )
--							MessageToRed( "Mission Command: Our satellite systems are detecting additional NATO air defenses. To all airborne units: Take care!!!", 60, "RED/PatriotDefense" )
--							Mission:GetTask( 2 ):AddGoalCompletion( "Patriots activated", PatriotActivation[CurrentLandingZoneID][1], 1 ) -- Register Patriot activation as part of mission goal.
--						end
--					end
--				end
--			end
--		end
--	end
--
--	local Mission = MISSIONSCHEDULER.AddMission( 'NATO Transport Troops', 'Operational', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.', 'NATO' )
--	Mission:AddGoalFunction( DeployPatriotTroopsGoal )
function MISSION:AddGoalFunction( GoalFunction )
	self:T()
	self.GoalFunction = GoalFunction 
end

--- Show the briefing of the MISSION to the CLIENT.
-- @tparam CLIENT Client to show briefing to.
-- @treturn CLIENT
function MISSION:ShowBriefing( Client )
	self:T( { Client.ClientName } )

	if not Client.ClientBriefingShown then
		Client.ClientBriefingShown = true
		local Briefing = self.MissionBriefing 
		if Client.ClientBriefing then
			Briefing = Briefing .. "\n" .. Client.ClientBriefing
		end
		Briefing = Briefing .. "\n (Press [LEFT ALT]+[B] to view the graphical documentation.)"
		Client:Message( Briefing, 30,  self.Name .. '/MissionBriefing', "Command: Mission Briefing" )
	end

	return Client
end

--- Register a new @{CLIENT} to participate within the mission.
-- @tparam CLIENT Client is the @{CLIENT} object. The object must have been instantiated with @{CLIENT:New}.
-- @treturn CLIENT
-- @usage
-- Add a number of Client objects to the Mission.
-- 	Mission:AddClient( CLIENT:New( 'US UH-1H*HOT-Deploy Troops 1', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'US UH-1H*RAMP-Deploy Troops 3', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'US UH-1H*HOT-Deploy Troops 2', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'US UH-1H*RAMP-Deploy Troops 4', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
function MISSION:AddClient( Client )
	self:T( { Client } )

	local Valid = true
 
	if Valid then
		self._Clients[Client.ClientName] = Client
	end

trace.r( self.ClassName, "" )
	return Client
end

--- Find a @{CLIENT} object within the @{MISSION} by its ClientName.
-- @tparam CLIENT ClientName is a string defining the Client Group as defined within the ME.
-- @treturn CLIENT
-- @usage
-- -- Seach for Client "Bomber" within the Mission.
-- local BomberClient = Mission:FindClient( "Bomber" )
function MISSION:FindClient( ClientName )
	self:T( { self._Clients[ClientName] } )
	return self._Clients[ClientName]
end


--- Register a @{TASK} to be completed within the @{MISSION}. Note that there can be multiple @{TASK}s registered to be completed. Each TASK can be set a certain Goal. The MISSION will not be completed until all Goals are reached.
-- @tparam TASK Task is the @{TASK} object. The object must have been instantiated with @{TASK:New} or any of its inherited @{TASK}s.
-- @tparam number TaskNumber is the sequence number of the TASK within the MISSION. This number does have to be chronological.
-- @treturn TASK
-- @usage
-- -- Define a few tasks for the Mission.
--	PickupZones = { "NATO Gold Pickup Zone", "NATO Titan Pickup Zone" }
--	PickupSignalUnits = { "NATO Gold Coordination Center", "NATO Titan Coordination Center" }
--
--	-- Assign the Pickup Task
--	local PickupTask = PICKUPTASK:New( PickupZones, CARGO_TYPE.ENGINEERS, CLIENT.ONBOARDSIDE.LEFT )
--	PickupTask:AddSmokeBlue( PickupSignalUnits  )
--	PickupTask:SetGoalTotal( 3 )
--	Mission:AddTask( PickupTask, 1 )
--
--	-- Assign the Deploy Task
--	local PatriotActivationZones = { "US Patriot Battery 1 Activation", "US Patriot Battery 2 Activation", "US Patriot Battery 3 Activation" }
--	local PatriotActivationZonesSmokeUnits = { "US SAM Patriot - Battery 1 Control", "US SAM Patriot - Battery 2 Control", "US SAM Patriot - Battery 3 Control" }
--	local DeployTask = DEPLOYTASK:New( PatriotActivationZones, CARGO_TYPE.ENGINEERS )
--	--DeployTask:SetCargoTargetZoneName( 'US Troops Attack ' .. math.random(2) )
--	DeployTask:AddSmokeBlue( PatriotActivationZonesSmokeUnits )
--	DeployTask:SetGoalTotal( 3 )
--	DeployTask:SetGoalTotal( 3, "Patriots activated" )
--	Mission:AddTask( DeployTask, 2 )
	
function MISSION:AddTask( Task, TaskNumber )
	self:T()

	self._Tasks[TaskNumber] = Task
	self._Tasks[TaskNumber]:EnableEvents()
	self._Tasks[TaskNumber].ID = TaskNumber

	return Task
 end

--- Get the TASK idenified by the TaskNumber from the Mission. This function is useful in GoalFunctions.
-- @tparam number TaskNumber is the number of the @{TASK} within the @{MISSION}.
-- @treturn TASK
-- @usage
-- -- Get Task 2 from the Mission.
-- Task2 = Mission:GetTask( 2 )

function MISSION:GetTask( TaskNumber )
	self:T()

	local Valid = true

	local Task = nil

	if type(TaskNumber) ~= "number" then
		Valid = false
	end

	if Valid then
		Task = self._Tasks[TaskNumber]
	end

	return Task
end

--- Get all the TASKs from the Mission. This function is useful in GoalFunctions.
-- @treturn {TASK,...} Structure of TASKS with the @{TASK} number as the key.
-- @usage
-- -- Get Tasks from the Mission.
-- Tasks = Mission:GetTasks()
-- env.info( "Task 2 Completion = " .. Tasks[2]:GetGoalPercentage() .. "%" )
function MISSION:GetTasks()
	self:T()

	return self._Tasks
end
 

--[[
  _TransportExecuteStage: Defines the different stages of Transport unload/load execution. This table is internal and is used to control the validity of Transport load/unload timing.
  
  - _TransportExecuteStage.EXECUTING
  - _TransportExecuteStage.SUCCESS
  - _TransportExecuteStage.FAILED
  
--]]
_TransportExecuteStage = { 
  NONE = 0,
  EXECUTING = 1, 
  SUCCESS = 2, 
  FAILED = 3
}


--- The MISSIONSCHEDULER is an OBJECT and is the main scheduler of ALL active MISSIONs registered within this scheduler. It's workings are considered internal and is automatically created when the Mission.lua file is included.
-- @type MISSIONSCHEDULER

MISSIONSCHEDULER = {
  Missions = {},
  MissionCount = 0,
  TimeIntervalCount = 0,
  TimeIntervalShow = 150,
  TimeSeconds = 14400,
  TimeShow = 5
}

--- This is the main MISSIONSCHEDULER Scheduler function. It is considered internal and is automatically created when the Mission.lua file is included.
function MISSIONSCHEDULER.Scheduler()
trace.scheduled("MISSIONSCHEDULER","Scheduler")

	-- loop through the missions in the TransportTasks
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
	
		trace.i( "MISSIONSCHEDULER", MissionName )
		
		if not Mission:IsCompleted() then
		
			-- This flag will monitor if for this mission, there are clients alive. If this flag is still false at the end of the loop, the mission status will be set to Pending (if not Failed or Completed).
			local ClientsAlive = false
			
			for ClientID, Client in pairs( Mission._Clients ) do
			
				trace.i( "MISSIONSCHEDULER", "Client: " .. Client.ClientName )

				if Client:ClientGroup() then

					-- There is at least one Client that is alive... So the Mission status is set to Ongoing.
					ClientsAlive = true 
					
					-- If this Client was not registered as Alive before:
					-- 1. We register the Client as Alive.
					-- 2. We initialize the Client Tasks and make a link to the original Mission Task.
					-- 3. We initialize the Cargos.
					-- 4. We flag the Mission as Ongoing.
					if not Client.ClientAlive then
						Client.ClientAlive = true
						Client.ClientBriefingShown = false
						for TaskNumber, Task in pairs( Mission._Tasks ) do
							-- Note that this a deepCopy. Each client must have their own Tasks with own Stages!!!
							Client._Tasks[TaskNumber] = routines.utils.deepCopy( Mission._Tasks[TaskNumber] )
							-- Each MissionTask must point to the original Mission.
							Client._Tasks[TaskNumber].MissionTask = Mission._Tasks[TaskNumber]
							Client._Tasks[TaskNumber].Cargos = Mission._Tasks[TaskNumber].Cargos
							Client._Tasks[TaskNumber].LandingZones = Mission._Tasks[TaskNumber].LandingZones
						end

						Mission:Ongoing()				
					end
					

					-- For each Client, check for each Task the state and evolve the mission.
					-- This flag will indicate if the Task of the Client is Complete.
					TaskComplete = false

					for TaskNumber, Task in pairs( Client._Tasks ) do

						if not Task.Stage then
							Task:SetStage( 1 )
						end

						
						local TransportTime = timer.getTime()
				
						if not Task:IsDone() then

							if Task:Goal() then
								Task:ShowGoalProgress( Mission, Client )
							end
							
							--env.info( 'Scheduler: Mission = ' .. Mission.Name .. ' / Client = ' .. Client.ClientName .. ' / Task = ' .. Task.Name .. ' / Stage = ' .. Task.ActiveStage .. ' - ' .. Task.Stage.Name .. ' - ' .. Task.Stage.StageType )
							
							-- Action
							if Task:StageExecute() then
								Task.Stage:Execute( Mission, Client, Task )
							end
						  
							-- Wait until execution is finished            
							if  Task.ExecuteStage == _TransportExecuteStage.EXECUTING then
								Task.Stage:Executing( Mission, Client, Task )
							end
						  
							-- Validate completion or reverse to earlier stage
							if Task.Time + Task.Stage.WaitTime <= TransportTime then
								Task:SetStage( Task.Stage:Validate( Mission, Client, Task ) )
							end
							 
							if Task:IsDone() then
								trace.i( "MISSIONSCHEDULER", "Task " .. Task.Name .. " is Done." )
								--env.info( 'Scheduler: Mission '.. Mission.Name .. ' Task ' .. Task.Name .. ' Stage ' .. Task.Stage.Name .. ' done. TaskComplete = ' .. string.format ( "%s", TaskComplete and "true" or "false" ) )
								TaskComplete = true -- when a task is not yet completed, a mission cannot be completed
								
							else
								-- break only if this task is not yet done, so that future task are not yet activated.
								TaskComplete = false -- when a task is not yet completed, a mission cannot be completed
								--env.info( 'Scheduler: Mission "'.. Mission.Name .. '" Task "' .. Task.Name .. '" Stage "' .. Task.Stage.Name .. '" break. TaskComplete = ' .. string.format ( "%s", TaskComplete and "true" or "false" ) )
								break
							end

							if TaskComplete then

								if Mission.GoalFunction ~= nil then
									Mission.GoalFunction( Mission, Client )
								end
								_Database:_AddMissionTaskScore( Client:GetClientGroupDCSUnit(), Mission.Name, 25 )

--								if not Mission:IsCompleted() then
--								end
							end
						end
					end
					
					local MissionComplete = true
					for TaskNumber, Task in pairs( Mission._Tasks ) do
						if Task:Goal() then
--							Task:ShowGoalProgress( Mission, Client )
							if Task:IsGoalReached() then
							else
								MissionComplete = false
							end
						else
							MissionComplete = false -- If there is no goal, the mission should never be ended. The goal status will be set somewhere else.
						end
					end

					if MissionComplete then
						Mission:Completed()
						_Database:_AddMissionScore( Mission.Name, 100 ) 
					else
						if TaskComplete then
							-- Reset for new tasking of active client
							Client.ClientAlive = false -- Reset the client tasks.
						end
					end
					

				else
					if Client.ClientAlive then
						env.info( 'Scheduler: Client "' .. Client.ClientName .. '" is inactive.' )
						Client.ClientAlive = false
						
						-- This is tricky. If we sanitize Client._Tasks before sanitizing Client._Tasks[TaskNumber].MissionTask, then the original MissionTask will be sanitized, and will be lost within the garbage collector.
						-- So first sanitize Client._Tasks[TaskNumber].MissionTask, after that, sanitize only the whole _Tasks structure...
						--Client._Tasks[TaskNumber].MissionTask = nil
						--Client._Tasks = nil
					end
				end
			end

			-- If all Clients of this Mission are not activated, then the Mission status needs to be put back into Pending status.
			-- But only if the Mission was Ongoing. In case the Mission is Completed or Failed, the Mission status may not be changed. In these cases, this will be the last run of this Mission in the Scheduler.
			if ClientsAlive == false then
				if Mission:IsOngoing() then
					-- Mission status back to pending...
					Mission:Pending()
				end
			end
		end
		
		Mission:StatusToClients()
		
		if Mission:ReportTrigger() then
			Mission:ReportToAll()
		end
		
	end

trace.e()
end

--- Start the MISSIONSCHEDULER.
function MISSIONSCHEDULER.Start()
trace.f("MISSIONSCHEDULER")
  if MISSIONSCHEDULER ~= nil then
    MISSIONSCHEDULER.SchedulerId = routines.scheduleFunction( MISSIONSCHEDULER.Scheduler, { }, 0, 2 )
  end
trace.e()
end

--- Stop the MISSIONSCHEDULER.
function MISSIONSCHEDULER.Stop()
trace.f("MISSIONSCHEDULER")
	if MISSIONSCHEDULER.SchedulerId then
		routines.removeFunction(MISSIONSCHEDULER.SchedulerId)
		MISSIONSCHEDULER.SchedulerId = nil
	end
trace.e()
end

--- This is the main MISSION declaration method. Each Mission is like the master or a Mission orchestration between, Clients, Tasks, Stages etc.
-- @param Mission is the MISSION object instantiated by @{MISSION:New}.
-- @return MISSION
-- @usage 
-- -- Declare a mission.
-- Mission = MISSION:New( 'Russia Transport Troops SA-6', 
--                        'Operational', 
--                        'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 
--                        'Russia' )
-- MISSIONSCHEDULER:AddMission( Mission )
function MISSIONSCHEDULER.AddMission( Mission )
trace.f("MISSIONSCHEDULER")
	MISSIONSCHEDULER.Missions[Mission.Name] = Mission
	MISSIONSCHEDULER.MissionCount = MISSIONSCHEDULER.MissionCount + 1
	-- Add an overall AI Client for the AI tasks... This AI Client will facilitate the Events in the background for each Task. 
	--MissionAdd:AddClient( CLIENT:New( 'AI' ) )
	
trace.r( "MISSIONSCHEDULER", "" )
	return Mission
end

--- Remove a MISSION from the MISSIONSCHEDULER.
-- @param MissionName is the name of the MISSION given at declaration using @{AddMission}.
-- @usage
-- -- Declare a mission.
-- Mission = MISSION:New( 'Russia Transport Troops SA-6', 
--                        'Operational', 
--                        'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 
--                        'Russia' )
-- MISSIONSCHEDULER:AddMission( Mission )
--
-- -- Now remove the Mission.
-- MISSIONSCHEDULER:RemoveMission( 'Russia Transport Troops SA-6' )
function MISSIONSCHEDULER.RemoveMission( MissionName )
trace.f("MISSIONSCHEDULER")
	MISSIONSCHEDULER.Missions[MissionName] = nil
	MISSIONSCHEDULER.MissionCount = MISSIONSCHEDULER.MissionCount - 1
trace.e()
end

--- Find a MISSION within the MISSIONSCHEDULER.
-- @param MissionName is the name of the MISSION given at declaration using @{AddMission}.
-- @return MISSION
-- @usage
-- -- Declare a mission.
-- Mission = MISSION:New( 'Russia Transport Troops SA-6', 
--                        'Operational', 
--                        'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 
--                        'Russia' )
-- MISSIONSCHEDULER:AddMission( Mission )
--
-- -- Now find the Mission.
-- MissionFind = MISSIONSCHEDULER:FindMission( 'Russia Transport Troops SA-6' )
function MISSIONSCHEDULER.FindMission( MissionName )
trace.f("MISSIONSCHEDULER")
trace.r( "MISSIONSCHEDULER", "" )
	return MISSIONSCHEDULER.Missions[MissionName]
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsShow( )
trace.menu("MISSIONSCHEDULER","ReportMissionsShow")
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = true
		Mission.MissionReportFlash = false 
	end
trace.e()
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsFlash( TimeInterval )
trace.menu("MISSIONSCHEDULER","ReportMissionsFlash")
	local Count = 0
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = false 
		Mission.MissionReportFlash = true
		Mission.MissionReportTrigger = timer.getTime() + Count * TimeInterval
		Mission.MissionTimeInterval = MISSIONSCHEDULER.MissionCount * TimeInterval 
		env.info( "TimeInterval = "  .. Mission.MissionTimeInterval )
		Count = Count + 1
	end
trace.e()
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsHide( Prm )
trace.menu("MISSIONSCHEDULER","ReportMissionsHide")
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = false
		Mission.MissionReportFlash = false
	end
trace.e()
end

--- Enables a MENU option in the communications menu under F10 to control the status of the active missions.
-- This function should be called only once when starting the MISSIONSCHEDULER.
function MISSIONSCHEDULER.ReportMenu()
trace.f("MISSIONSCHEDULER")
	local ReportMenu = SUBMENU:New( 'Status' )
	local ReportMenuShow = COMMANDMENU:New( 'Show Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsShow, 0 )
	local ReportMenuFlash = COMMANDMENU:New('Flash Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsFlash, 120 )
	local ReportMenuHide = COMMANDMENU:New( 'Hide Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsHide, 0 )
trace.e()
end

--- Show the remaining mission time.
function MISSIONSCHEDULER:TimeShow()
trace.f("MISSIONSCHEDULER")
	self.TimeIntervalCount = self.TimeIntervalCount + 1
	if self.TimeIntervalCount >= self.TimeTriggerShow then
		local TimeMsg = string.format("%00d", ( self.TimeSeconds / 60 ) - ( timer.getTime() / 60 )) .. ' minutes left until mission reload.'
		MESSAGE:New( TimeMsg, "Mission time", self.TimeShow, '/TimeMsg' ):ToAll()
		self.TimeIntervalCount = 0
	end
trace.e()
end

function MISSIONSCHEDULER:Time( TimeSeconds, TimeIntervalShow, TimeShow )
trace.f("MISSIONSCHEDULER")

	self.TimeIntervalCount = 0
	self.TimeSeconds = TimeSeconds
	self.TimeIntervalShow = TimeIntervalShow
	self.TimeShow = TimeShow
trace.e()
end

--- CLEANUP Classes
-- @classmod CLEANUP
-- @author Flightcontrol

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )

CLEANUP = {
	ClassName = "CLEANUP",
	ZoneNames = {},
	TimeInterval = 300,
	CleanUpList = {},
}

--- Creates the main object which is handling the cleaning of the debris within the given Zone Names.
-- @tparam table{string,...}|string ZoneNames which is a table of zone names where the debris should be cleaned. Also a single string can be passed with one zone name.
-- @tparam ?number TimeInterval is the interval in seconds when the clean activity takes place. The default is 300 seconds, thus every 5 minutes.
-- @treturn CLEANUP
-- @usage
-- -- Clean these Zones.
-- CleanUpAirports = CLEANUP:New( { 'CLEAN Tbilisi', 'CLEAN Kutaisi' }, 150 )
-- or
-- CleanUpTbilisi = CLEANUP:New( 'CLEAN Tbilisi', 150 )
-- CleanUpKutaisi = CLEANUP:New( 'CLEAN Kutaisi', 600 )
function CLEANUP:New( ZoneNames, TimeInterval )	local self = BASE:Inherit( self, BASE:New() )
	self:T( { ZoneNames, TimeInterval } )
	
	if type( ZoneNames ) == 'table' then
		self.ZoneNames = ZoneNames
	else
		self.ZoneNames = { ZoneNames }
	end
	if TimeInterval then
		self.TimeInterval = TimeInterval
	end
	
	self:AddEvent( world.event.S_EVENT_ENGINE_SHUTDOWN, self._EventAddForCleanUp )
	self:AddEvent( world.event.S_EVENT_ENGINE_STARTUP, self._EventAddForCleanUp )
	self:AddEvent( world.event.S_EVENT_HIT, self._EventAddForCleanUp ) -- , self._EventHitCleanUp )
	self:AddEvent( world.event.S_EVENT_CRASH, self._EventCrash ) -- , self._EventHitCleanUp )
	--self:AddEvent( world.event.S_EVENT_DEAD, self._EventCrash )
	self:AddEvent( world.event.S_EVENT_SHOT, self._EventShot )
	
	self:EnableEvents()

	self.CleanUpFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, TimeInterval )
	
	return self
end


--- Destroys a group from the simulator, but checks first if it is still existing!
-- @see CLEANUP
function CLEANUP:_DestroyGroup( GroupObject, CleanUpGroupName )
	self:T( { GroupObject, CleanUpGroupName } )

	if GroupObject then -- and GroupObject:isExist() then
		MESSAGE:New( "Destroy Group " .. CleanUpGroupName, CleanUpGroupName, 1, CleanUpGroupName ):ToAll()
		trigger.action.deactivateGroup(GroupObject)
		self:T( { "GroupObject Destroyed", GroupObject } )
	end
end

--- Destroys a unit from the simulator, but checks first if it is still existing!
-- @see CLEANUP
function CLEANUP:_DestroyUnit( CleanUpUnit, CleanUpUnitName )
	self:T( { CleanUpUnit, CleanUpUnitName } )

	if CleanUpUnit then
		MESSAGE:New( "Destroy " .. CleanUpUnitName, CleanUpUnitName, 1, CleanUpUnitName ):ToAll()
		local CleanUpGroup = Unit.getGroup(CleanUpUnit)
		if CleanUpGroup then
			local CleanUpGroupUnits = CleanUpGroup:getUnits()
			if #CleanUpGroupUnits == 1 then
				local CleanUpGroupName = CleanUpGroup:getName()
				local Event = {["initiator"]=CleanUpUnit,["id"]=8}
				world.onEvent(Event)
				trigger.action.deactivateGroup(CleanUpGroup)
				self:T( { "Destroyed Group:", CleanUpGroupName } )
			else
				CleanUpUnit:destroy()
				self:T( { "Destroyed Unit:", CleanUpUnitName } )
			end
			self.CleanUpList[CleanUpUnitName] = nil -- Cleaning from the list
			CleanUpUnit = nil
		end
	end
end

--- Destroys a missile from the simulator, but checks first if it is still existing!
-- @see CLEANUP
function CLEANUP:_DestroyMissile( MissileObject )
	self:T( { MissileObject } )

	if MissileObject and MissileObject:isExist() then
		MissileObject:destroy()
		self:T( "MissileObject Destroyed")
	end
end

--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see CLEANUP
function CLEANUP:_EventCrash( event )
	self:T( { event } )

	--MESSAGE:New( "Crash ", "Crash", 10, "Crash" ):ToAll()
	-- self:T("before getGroup")
	-- local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired 
	-- self:T("after getGroup")
	-- _grp:destroy()
	-- self:T("after deactivateGroup")
	-- event.initiator:destroy()

	local CleanUpUnit = event.initiator -- the Unit
	local CleanUpUnitName = CleanUpUnit:getName() -- return the name of the Unit
	local CleanUpGroup = Unit.getGroup(CleanUpUnit)-- Identify the Group 
	local CleanUpGroupName = CleanUpGroup:getName() -- return the name of the Group

	self.CleanUpList[CleanUpUnitName] = {}
	self.CleanUpList[CleanUpUnitName].CleanUpUnit = CleanUpUnit
	self.CleanUpList[CleanUpUnitName].CleanUpGroup = CleanUpGroup
	self.CleanUpList[CleanUpUnitName].CleanUpGroupName = CleanUpGroupName
	self.CleanUpList[CleanUpUnitName].CleanUpUnitName = CleanUpUnitName

	

end
--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see CLEANUP
function CLEANUP:_EventShot( event )
	self:T( { event } )

	local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired 
	local _groupname = _grp:getName() -- return the name of the group
	local _unittable = {event.initiator:getName()} -- return the name of the units in the group
	local _SEADmissile = event.weapon -- Identify the weapon fired					
	--local _SEADmissileName = _SEADmissile:getTypeName()	-- return weapon type
	--trigger.action.outText( string.format("Alerte, depart missile " ..string.format(_SEADmissileName)), 20) --debug message
	-- Start of the 2nd loop
	--self:T( "Missile Launched = " .. _SEADmissileName )
	
	-- Test if the missile was fired within one of the CLEANUP.ZoneNames.
	local CurrentLandingZoneID = 0
	CurrentLandingZoneID  = routines.IsUnitInZones( event.initiator, self.ZoneNames )
	if  ( CurrentLandingZoneID ) then
		-- Okay, the missile was fired within the CLEANUP.ZoneNames, destroy the fired weapon.
		--_SEADmissile:destroy()
		routines.scheduleFunction( CLEANUP._DestroyMissile, {self, _SEADmissile}, timer.getTime() + 0.1)
	end
end


--- Detects if the Unit has an S_EVENT_HIT within the given ZoneNames. If this is the case, destroy the unit.
function CLEANUP:_EventHitCleanUp( event )
	self:T( { event } )

	local CleanUpUnit = event.initiator -- the Unit
	if CleanUpUnit and CleanUpUnit:isExist() and Object.getCategory(CleanUpUnit) == Object.Category.UNIT then
		local CleanUpUnitName = event.initiator:getName() -- return the name of the Unit
		local CleanUpGroup = Unit.getGroup(event.initiator)-- Identify the Group 
		local CleanUpGroupName = CleanUpGroup:getName() -- return the name of the Group
		
		if routines.IsUnitInZones( CleanUpUnit, self.ZoneNames ) ~= nil then
			self:T( "Life: " .. CleanUpUnitName .. ' = ' .. CleanUpUnit:getLife() .. "/" .. CleanUpUnit:getLife0() )
			if CleanUpUnit:getLife() < CleanUpUnit:getLife0() then
				self:T( "CleanUp: Destroy: " .. CleanUpUnitName )
				routines.scheduleFunction( CLEANUP._DestroyUnit, {self, CleanUpUnit}, timer.getTime() + 0.1)
			end
		end
	end

	local CleanUpTgtUnit = event.target -- the target Unit
	if CleanUpTgtUnit and CleanUpTgtUnit:isExist() and Object.getCategory(CleanUpTgtUnit) == Object.Category.UNIT then
		local CleanUpTgtUnitName = event.target:getName() -- return the name of the target Unit
		local CleanUpTgtGroup = Unit.getGroup(event.target)-- Identify the target Group 
		local CleanUpTgtGroupName = CleanUpTgtGroup:getName() -- return the name of the target Group
		
		
		if routines.IsUnitInZones( CleanUpTgtUnit, self.ZoneNames ) ~= nil then
			self:T( "Life: " .. CleanUpTgtUnitName .. ' = ' .. CleanUpTgtUnit:getLife() .. "/" .. CleanUpTgtUnit:getLife0() )
			if CleanUpTgtUnit:getLife() < CleanUpTgtUnit:getLife0() then
				self:T( "CleanUp: Destroy: " .. CleanUpTgtUnitName )
				routines.scheduleFunction( CLEANUP._DestroyUnit, {self, CleanUpTgtUnit}, timer.getTime() + 0.1)
			end
		end
	end
	
end

function CLEANUP:_AddForCleanUp( CleanUpUnit, CleanUpUnitName )
	self:T( { CleanUpUnit, CleanUpUnitName } )

	self.CleanUpList[CleanUpUnitName] = {}
	self.CleanUpList[CleanUpUnitName].CleanUpUnit = CleanUpUnit
	self.CleanUpList[CleanUpUnitName].CleanUpUnitName = CleanUpUnitName
	self.CleanUpList[CleanUpUnitName].CleanUpGroup = Unit.getGroup(CleanUpUnit)
	self.CleanUpList[CleanUpUnitName].CleanUpGroupName = Unit.getGroup(CleanUpUnit):getName()
	self.CleanUpList[CleanUpUnitName].CleanUpTime = timer.getTime()
	self.CleanUpList[CleanUpUnitName].CleanUpMoved = false

	self:T( { "CleanUp: Add to CleanUpList: ", Unit.getGroup(CleanUpUnit):getName(), CleanUpUnitName } )
	
end

--- Detects if the Unit has an S_EVENT_ENGINE_SHUTDOWN or an S_EVENT_HIT within the given ZoneNames. If this is the case, add the Group to the CLEANUP List.
function CLEANUP:_EventAddForCleanUp( event )

	local CleanUpUnit = event.initiator -- the Unit
	if CleanUpUnit and Object.getCategory(CleanUpUnit) == Object.Category.UNIT then
		local CleanUpUnitName = CleanUpUnit:getName() -- return the name of the Unit
		if self.CleanUpList[CleanUpUnitName] == nil then
			if routines.IsUnitInZones( CleanUpUnit, self.ZoneNames ) ~= nil then
				self:_AddForCleanUp( CleanUpUnit, CleanUpUnitName )
			end
		end
	end

	local CleanUpTgtUnit = event.target -- the target Unit
	if CleanUpTgtUnit and Object.getCategory(CleanUpTgtUnit) == Object.Category.UNIT then
		local CleanUpTgtUnitName = CleanUpTgtUnit:getName() -- return the name of the target Unit
		if self.CleanUpList[CleanUpTgtUnitName] == nil then
			if routines.IsUnitInZones( CleanUpTgtUnit, self.ZoneNames ) ~= nil then
				self:_AddForCleanUp( CleanUpTgtUnit, CleanUpTgtUnitName )
			end
		end
	end
	
end

CleanUpSurfaceTypeText = {
   "LAND",
   "SHALLOW_WATER",
   "WATER",
   "ROAD",
   "RUNWAY"
 }

--- At the defined time interval, CleanUp the Groups within the CleanUpList.
function CLEANUP:_Scheduler()
	self:T( "CleanUp Scheduler" )

	for CleanUpUnitName, UnitData in pairs( self.CleanUpList ) do
	
		self:T( { CleanUpUnitName, UnitData } )
		local CleanUpGroup = Group.getByName(UnitData.CleanUpGroupName)
		local CleanUpUnit = Unit.getByName(UnitData.CleanUpUnitName)
		local CleanUpGroupName = UnitData.CleanUpGroupName
		local CleanUpUnitName = UnitData.CleanUpUnitName
		if CleanUpUnit then
			self:T( { "CleanUp Scheduler", "Checking:", CleanUpUnitName } )
			if _Database:GetStatusGroup( CleanUpGroupName ) ~= "ReSpawn" then
				local CleanUpUnitVec3 = CleanUpUnit:getPoint()
				--self:T( CleanUpUnitVec3 )
				local CleanUpUnitVec2 = {}
				CleanUpUnitVec2.x = CleanUpUnitVec3.x
				CleanUpUnitVec2.y = CleanUpUnitVec3.z
				--self:T( CleanUpUnitVec2 )
				local CleanUpSurfaceType = land.getSurfaceType(CleanUpUnitVec2)
				--self:T( CleanUpSurfaceType )
				--MESSAGE:New( "Surface " .. CleanUpUnitName .. " = " .. CleanUpSurfaceTypeText[CleanUpSurfaceType], CleanUpUnitName, 10, CleanUpUnitName ):ToAll()
				
				if CleanUpUnit and CleanUpUnit:getLife() <= CleanUpUnit:getLife0() * 0.95 then
					if CleanUpSurfaceType == land.SurfaceType.RUNWAY then
						if CleanUpUnit:inAir() then
							local CleanUpLandHeight = land.getHeight(CleanUpUnitVec2)
							local CleanUpUnitHeight = CleanUpUnitVec3.y - CleanUpLandHeight
							self:T( { "CleanUp Scheduler", "Height = " .. CleanUpUnitHeight } )
							if CleanUpUnitHeight < 30 then
								self:T( { "CleanUp Scheduler", "Destroy " .. CleanUpUnitName .. " because below safe height and damaged." } )
								self:_DestroyUnit(CleanUpUnit, CleanUpUnitName)
							end
						else
							self:T( { "CleanUp Scheduler", "Destroy " .. CleanUpUnitName .. " because on runway and damaged." } )
							self:_DestroyUnit(CleanUpUnit, CleanUpUnitName)
						end
					end
				end
				-- Clean Units which are waiting for a very long time in the CleanUpZone.
				if CleanUpUnit then
					local CleanUpUnitVelocity = CleanUpUnit:getVelocity()
					local CleanUpUnitVelocityTotal = math.abs(CleanUpUnitVelocity.x) + math.abs(CleanUpUnitVelocity.y) + math.abs(CleanUpUnitVelocity.z)
					if CleanUpUnitVelocityTotal < 1 then
						if UnitData.CleanUpMoved then
							if UnitData.CleanUpTime + 180 <= timer.getTime() then
								self:T( { "CleanUp Scheduler", "Destroy due to not moving anymore " .. CleanUpUnitName } )
								self:_DestroyUnit(CleanUpUnit, CleanUpUnitName)
							end
						end
					else
						UnitData.CleanUpTime = timer.getTime()
						UnitData.CleanUpMoved = true
						--MESSAGE:New( "Moved " .. CleanUpUnitName, CleanUpUnitName, 10, CleanUpUnitName ):ToAll()
					end
				end
				
			else
				-- Do nothing ...
				self.CleanUpList[CleanUpUnitName] = nil -- Not anymore in the DCSRTE
			end
		else
			self:T( "CleanUp: Group " .. CleanUpUnitName .. " cannot be found in DCS RTE, removing ..." )
			self.CleanUpList[CleanUpUnitName] = nil -- Not anymore in the DCSRTE
		end
	end
end

--- Dynamic spawning of Groups and Units.
-- @classmod SPAWN
-- @author Flightcontrol

MOOSE_Version = "0.1.1.1"

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Database" )
Include.File( "Group" )
Include.File( "Zone" )


SPAWN = {
	ClassName = "SPAWN",
}

--- Public 
-- @section Public

--- Creates the main object to spawn a Group defined in the DCS ME.
-- Spawned Groups and Units will follow the following naming convention within the DCS World run-time environment:
--       Groups will have the name SpawnTemplatePrefix#ggg, where ggg is a counter from 0 to 999 for each new spawned Group.
--       Units will have the name SpawnTemplatePrefix#ggg-uu, where uu is a counter from 0 to 99 for each new spawned Unit belonging to that Group.
-- @tparam string SpawnTemplatePrefix is the name of the Group in the ME that defines the Template. That Group must have the flag "Late Activation" set. Note that this SpawnTemplatePrefix name should not contain any # character.
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' )
function SPAWN:New( SpawnTemplatePrefix )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( { SpawnTemplatePrefix } )
  
	local TemplateGroup = Group.getByName( SpawnTemplatePrefix )
	if TemplateGroup then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
		self.SpawnIndex = 0
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnIsScheduled = false												-- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.SpawnRepeat = false													-- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false													-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
		self.SpawnMaxGroupsAlive = 0												-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
		self.SpawnMaxGroups = 0														-- The maximum amount of groups that can be spawned.
		self.SpawnRandomize = false													-- Sets the randomization flag of new Spawned units to false.
		self.SpawnVisible = false													-- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end
	
	self.AddEvent( self, world.event.S_EVENT_BIRTH, self.OnBirth )
	self.AddEvent( self, world.event.S_EVENT_DEAD, self.OnDeadOrCrash )
	self.AddEvent( self, world.event.S_EVENT_CRASH, self.OnDeadOrCrash )
	
	self.EnableEvents( self )

	return self
end

--- Creates the main object to spawn a Group defined in the DCS ME.
-- Spawned Groups and Units will follow the following naming convention within the DCS World run-time environment:
--       Groups will have the name SpawnTemplatePrefix#ggg, where ggg is a counter from 0 to 999 for each new spawned Group.
--       Units will have the name SpawnTemplatePrefix#ggg-uu, where uu is a counter from 0 to 99 for each new spawned Unit belonging to that Group.
-- @tparam string SpawnTemplatePrefix is the name of the Group in the ME that defines the Template. That Group must have the flag "Late Activation" set. Note that this SpawnTemplatePrefix name should not contain any # character.
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' )
function SPAWN:NewWithAlias( SpawnTemplatePrefix, SpawnAliasPrefix )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( { SpawnTemplatePrefix, SpawnAliasPrefix } )
  
	local TemplateGroup = Group.getByName( SpawnTemplatePrefix )
	if TemplateGroup then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
		self.SpawnAliasPrefix = SpawnAliasPrefix
		self.SpawnIndex = 0
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnIsScheduled = false												-- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.SpawnRepeat = false													-- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false													-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
		self.SpawnMaxGroupsAlive = 0												-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
		self.SpawnMaxGroups = 0														-- The maximum amount of groups that can be spawned.
		self.SpawnRandomize = false													-- Sets the randomization flag of new Spawned units to false.
		self.SpawnVisible = false													-- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end
	
	self.AddEvent( self, world.event.S_EVENT_BIRTH, self.OnBirth )
	self.AddEvent( self, world.event.S_EVENT_DEAD, self.OnDeadOrCrash )
	self.AddEvent( self, world.event.S_EVENT_CRASH, self.OnDeadOrCrash )
	
	self.EnableEvents( self )

	return self
end


function SPAWN:Limit( SpawnMaxGroupsAlive, SpawnMaxGroups )
	self:T( { self.SpawnTemplatePrefix, SpawnMaxGroupsAlive, SpawnMaxGroups } )

	self.SpawnMaxGroupsAlive = SpawnMaxGroupsAlive				-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
	self.SpawnMaxGroups = SpawnMaxGroups						-- The maximum amount of groups that can be spawned.
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:InitializeSpawnGroups( SpawnGroupID )
	end

	return self
end


--- Randomizes a defined route of the Template Group in the ME when the Group is Spawned. This is very useful to define extra variation in the DCS World run-time environment of the behaviour of Groups like Ground Units, Ships, Planes, Helicopters.
-- @tparam number SpawnStartPoint is the waypoint where the randomization begins. Note that the StartPoint = 0 equals the point where the Group is Spawned. This parameter is useful to avoid randomization to start from the first waypoint, but a bit further down the route...
-- @tparam number SpawnEndPoint is the waypoint where the randomization ends. this parameter is useful to avoid randomization to end at a waypoint earlier than the last waypoint on the route.
-- @tparam number SpawnRadius is the radius in meters, that defines the concentric circle in which the randomization of the new waypoint will take place, with the original waypoint located in the middle...
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field. 
-- -- The KA-50 has waypoints SP, 1, 2, 3, 4, DP. 
-- -- Waypoints 2 and 3 will only be randomized. The others will remain on their original position with each new ${SPAWN} of the helicopter.
-- -- The randomization of waypoint 2 and 3 will take place within a diameter of 4000 meters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):RandomizeRoute( 2, 2, 2000 )
 
function SPAWN:RandomizeRoute( SpawnStartPoint, SpawnEndPoint, SpawnRadius )
	self:T( { self.SpawnTemplatePrefix, SpawnStartPoint, SpawnEndPoint, SpawnRadius } )

	self.SpawnRandomizeRoute = true
	self.SpawnRandomizeRouteStartPoint = SpawnStartPoint
	self.SpawnRandomizeRouteEndPoint = SpawnEndPoint
	self.SpawnRandomizeRouteRadius = SpawnRadius

	for GroupID = 1, self.SpawnMaxGroups do
		self:_RandomizeRoute( GroupID )
	end
	
	return self
end

function SPAWN:_RandomizeRoute( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnRandomizeRoute, self.SpawnRandomizeRouteStartPoint, self.SpawnRandomizeRouteEndPoint, self.SpawnRandomizeRouteRadius } )

	if self.SpawnRandomizeRoute then
		local SpawnTemplate = self.SpawnGroups[SpawnIndex].SpawnTemplate
		local RouteCount = #SpawnTemplate.route.points
		
		for t = self.SpawnRandomizeRouteStartPoint + 1, ( RouteCount - self.SpawnRandomizeRouteEndPoint ) do
			SpawnTemplate.route.points[t].x = SpawnTemplate.route.points[t].x + math.random( self.SpawnRandomizeRouteRadius * -1, self.SpawnRandomizeRouteRadius )
			SpawnTemplate.route.points[t].y = SpawnTemplate.route.points[t].y + math.random( self.SpawnRandomizeRouteRadius * -1, self.SpawnRandomizeRouteRadius )
			-- TODO: manage altitude for airborne units ...
			SpawnTemplate.route.points[t].alt = nil
			--SpawnGroup.route.points[t].alt_type = nil
			self:T( 'SpawnTemplate.route.points[' .. t .. '].x = ' .. SpawnTemplate.route.points[t].x .. ', SpawnTemplate.route.points[' .. t .. '].y = ' .. SpawnTemplate.route.points[t].y )
		end
	end
	
	return self
end

--- This function is rather complicated to understand. But I'll try to explain...
-- This function becomes useful when you need to SPAWN random types of Groups defined within the ME, but they all need to follow the same Template route and have the same SpawnTemplatePrefix name, then this method becomes very useful.
-- @tparam table{string,...} SpawnTemplatePrefixTable is a table with the names of the Groups defined within the ME (with late activatio on), from which on a new SPAWN of SpawnTemplatePrefix (the main Group name), a NEW Group will be choosen as the Group to be SPAWNed.
-- In other words, this method randomizes between a defined set of Groups the Group to be SPAWNed for each new SPAWN.
-- @treturn SPAWN
-- @usage
-- -- NATO Tank Platoons invading Gori.
-- -- Choose between 13 different 'US Tank Platoon' configurations for each new SPAWN the Group to be SPAWNed for the 
-- -- 'US Tank Platoon Left', 'US Tank Platoon Middle' and 'US Tank Platoon Right' SpawnTemplatePrefixes.
-- -- Each new SPAWN will randomize the route, with a defined time interval of 200 seconds with 40% time variation (randomization) and 
-- -- with a limit set of maximum 12 Units alive simulteneously  and 150 Groups to be SPAWNed during the whole mission.
-- Spawn_US_Platoon = { 'US Tank Platoon 1', 'US Tank Platoon 2', 'US Tank Platoon 3', 'US Tank Platoon 4', 'US Tank Platoon 5', 
--                      'US Tank Platoon 6', 'US Tank Platoon 7', 'US Tank Platoon 8', 'US Tank Platoon 9', 'US Tank Platoon 10', 
--                      'US Tank Platoon 11', 'US Tank Platoon 12', 'US Tank Platoon 13' }
-- Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )

function SPAWN:RandomizeTemplate( SpawnTemplatePrefixTable )
	self:T( { self.SpawnTemplatePrefix, SpawnTemplatePrefixTable } )

	self.SpawnTemplatePrefixTable = SpawnTemplatePrefixTable
	self.SpawnRandomizeTemplate = true

	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:_RandomizeTemplate( SpawnGroupID )
	end
	
	return self
end


function SPAWN:_RandomizeTemplate( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex } )

	if self.SpawnRandomizeTemplate then
		self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix = self.SpawnTemplatePrefixTable[ math.random( 1, #self.SpawnTemplatePrefixTable ) ]
		self.SpawnGroups[SpawnIndex].SpawnTemplate = self:_Prepare( self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix, SpawnIndex )
		self.SpawnGroups[SpawnIndex].SpawnTemplate.route = routines.utils.deepCopy( self.SpawnTemplate.route )
		self.SpawnGroups[SpawnIndex].SpawnTemplate.x = self.SpawnTemplate.x
		self.SpawnGroups[SpawnIndex].SpawnTemplate.y = self.SpawnTemplate.y
	end
	
	return self
end




--- When a Group got SPAWNed, it has a life within the DCSRTE. For planes and helicopters, when these Units go home and land on their home airbases and farps, they normally would taxi to the parking spot, shut-down their engines and wait forever until the Group is removed by the DCSRTE.
-- This function is used to Re-Spawn automatically (so no extra call is needed anymore) the same Group after it landed. This will enable a SPAWNed group to be Re-SPAWNed after it lands, until it is destroyed...
-- Note: When the Group is respawned, it will @{ReSpawn} at the original airbase where it took off. So ensure that the paths for Groups that ReSpawn, always return to the original airbase.
-- @treturn SPAWN
-- @usage
-- -- RU Su-34 - AI Ship Attack
-- -- Re-SPAWN the Group(s) after each landing and Engine Shut-Down automatically. 
-- SpawnRU_SU34 = SPAWN:New( 'TF1 RU Su-34 Krymsk@AI - Attack Ships' ):Schedule( 2, 3, 1800, 0.4 ):SpawnUncontrolled():RandomizeRoute( 1, 1, 3000 ):RepeatOnEngineShutDown()

function SPAWN:Repeat()
	self:T( { self.SpawnTemplatePrefix } )

	self.SpawnRepeat = true
	self.RepeatOnEngineShutDown = false
	self.RepeatOnLanding = true

	self:AddEvent( world.event.S_EVENT_LAND, self.OnLand )
	self:AddEvent( world.event.S_EVENT_TAKEOFF, self.OnTakeOff )
	self:AddEvent( world.event.S_EVENT_ENGINE_SHUTDOWN, self.OnEngineShutDown )
	self:EnableEvents()

	return self
end

--- Same as the @{Repeat) method.
-- @treturn SPAWN
-- @see Repeat

function SPAWN:RepeatOnLanding()
	self:T( { self.SpawnTemplatePrefix } )

	self:Repeat()
	self.RepeatOnEngineShutDown = false
	self.RepeatOnLanding = true
	
	return self
end

--- Same as the @{Repeat) method, but now the Group will respawn after its engines have shut down.
-- @treturn SPAWN
-- @see Repeat

function SPAWN:RepeatOnEngineShutDown()
	self:T( { self.SpawnTemplatePrefix } )

	self:Repeat()
	self.RepeatOnEngineShutDown = true
	self.RepeatOnLanding = false
	
	return self
end

function SPAWN:CleanUp( SpawnCleanUpInterval )
	self:T( { self.SpawnTemplatePrefix, SpawnCleanUpInterval } )

	self.SpawnCleanUpInterval = SpawnCleanUpInterval
	self.SpawnCleanUpTimeStamps = {}
	self.CleanUpFunction = routines.scheduleFunction( self._SpawnCleanUpScheduler, { self }, timer.getTime() + 1, 60 )
	
	return self
end



--- Makes the Groups visible before start (like a batallion).
-- @tparam number SpawnZone 		A @{ZONE} where the group will be positioned. The X and Y coordinates of the zone define the start position.
-- @tparam number SpawnAngle 		The angle in degrees how the Groups and each Unit of the Group will be positioned.
-- @tparam number SpawnFormation    The formation of the Units within the Group.
-- @tparam number SpawnWidth		The amount of Groups that will be positioned on the X axis.
-- @tparam number SpawnDeltaX       The space between each Group on the X-axis.
-- @tparam number SpawnDeltaY		The space between each Group on the Y-axis.
-- @treturn SPAWN
-- @usage
-- -- Define an array of Groups within Zone "Start".
-- Spawn_BE_Ground = SPAWN:New( 'BE Ground' ):Limit( 2, 24 ):Visible( ZONE:New( "Start" ), 90, "Diamond", 10, 100, 50 )

function SPAWN:SpawnArray( SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY )
	self:T( { self.SpawnTemplatePrefix, SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY } )

	self.SpawnVisible = true									-- When the first Spawn executes, all the Groups need to be made visible before start.
	
	local SpawnX = 0
	local SpawnY = 0
	local SpawnXIndex = 0
	local SpawnYIndex = 0
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:T( { SpawnX, SpawnY, SpawnXIndex, SpawnYIndex } )

		self.SpawnGroups[SpawnGroupID].Visible = true
		self.SpawnGroups[SpawnGroupID].Spawned = false
		
		SpawnXIndex = SpawnXIndex + 1
		if SpawnWidth and SpawnWidth ~= 0 then
			if SpawnXIndex >= SpawnWidth then
				SpawnXIndex = 0
				SpawnYIndex = SpawnYIndex + 1
			end
		end

		local SpawnRootX = self.SpawnGroups[SpawnGroupID].SpawnTemplate.x
		local SpawnRootY = self.SpawnGroups[SpawnGroupID].SpawnTemplate.y
		
		self:_TranslateRotate( SpawnGroupID, SpawnRootX, SpawnRootY, SpawnX, SpawnY, SpawnAngle )
		
		self.SpawnGroups[SpawnGroupID].SpawnTemplate.lateActivation = true
		self.SpawnGroups[SpawnGroupID].SpawnTemplate.visible = true
		
		self.SpawnGroups[SpawnGroupID].Visible = true
		self.SpawnGroups[SpawnGroupID].Group = _Database:Spawn( self.SpawnGroups[SpawnGroupID].SpawnTemplate )

		SpawnX = SpawnXIndex * SpawnDeltaX
		SpawnY = SpawnYIndex * SpawnDeltaY
	end
	
	return self
end

function SPAWN:_TranslateRotate( SpawnIndex, SpawnRootX, SpawnRootY, SpawnX, SpawnY, SpawnAngle )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex, SpawnRootX, SpawnRootY, SpawnX, SpawnY, SpawnAngle } )
	
	-- Translate
	local TranslatedX = SpawnX
	local TranslatedY = SpawnY
	
	-- Rotate
	-- From Wikipedia: https://en.wikipedia.org/wiki/Rotation_matrix#Common_rotations
	-- x' = x \cos \theta - y \sin \theta\
	-- y' = x \sin \theta + y \cos \theta\ 
	local RotatedX = - TranslatedX * math.cos( math.rad( SpawnAngle ) )
					 + TranslatedY * math.sin( math.rad( SpawnAngle ) )
	local RotatedY =   TranslatedX * math.sin( math.rad( SpawnAngle ) )
					 + TranslatedY * math.cos( math.rad( SpawnAngle ) )
	
	-- Assign
	self.SpawnGroups[SpawnIndex].SpawnTemplate.x = SpawnRootX - RotatedX
	self.SpawnGroups[SpawnIndex].SpawnTemplate.y = SpawnRootY + RotatedY

					 
	local SpawnUnitCount = table.getn( self.SpawnGroups[SpawnIndex].SpawnTemplate.units )
	for u = 1, SpawnUnitCount do
		
		-- Translate
		local TranslatedX = SpawnX 
		local TranslatedY = SpawnY - 10 * ( u - 1 )
		
		-- Rotate
		local RotatedX = - TranslatedX * math.cos( math.rad( SpawnAngle ) ) 
						 + TranslatedY * math.sin( math.rad( SpawnAngle ) )
		local RotatedY =   TranslatedX * math.sin( math.rad( SpawnAngle ) )
						 + TranslatedY * math.cos( math.rad( SpawnAngle ) )
		
		-- Assign
		self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].x = SpawnRootX - RotatedX
		self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].y = SpawnRootY + RotatedY
		self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].heading = math.rad( SpawnAngle )
	end
	
	return self
end

function SPAWN:GetSpawnIndex( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxGroupsAlive, self.AliveUnits, #self.SpawnTemplate.units } )

	
	if ( self.SpawnMaxGroups == 0 ) or ( SpawnIndex <= self.SpawnMaxGroups ) then
		if ( self.SpawnMaxGroupsAlive == 0 ) or ( self.AliveUnits < self.SpawnMaxGroupsAlive * #self.SpawnTemplate.units ) or self.UnControlled then
			if SpawnIndex and SpawnIndex >= self.SpawnCount + 1 then
				self.SpawnCount = self.SpawnCount + 1
				SpawnIndex = self.SpawnCount
			end
			self.SpawnIndex = SpawnIndex
			if not self.SpawnGroups[self.SpawnIndex] then
				self:InitializeSpawnGroups( self.SpawnIndex )
			end
		else
			return nil
		end
	else
		return nil
	end
	
	return self.SpawnIndex
end


--- Will SPAWN a Group whenever you want to do this.
-- Note that the configuration with the above functions will apply when calling this method: Maxima, Randomization of routes, Scheduler, ...
-- Uses @{DATABASE} global object defined in MOOSE.
-- @treturn SPAWN
function SPAWN:Spawn()
	self:T( { self.SpawnTemplatePrefix, self.SpawnIndex } )

	return self:SpawnWithIndex( self.SpawnIndex + 1 )
end

--- Will Re-SPAWN a Group based on a given GroupName. The GroupName must be a group that is already alive within the DCSRTE and should have a Group Template defined in the ME (with Late Activation flag on).
-- Note that the configuration with the above functions will apply when calling this method: Maxima, Randomization of routes, Scheduler, ...
-- @tparam string SpawnGroupName 
-- @treturn SPAWN
-- Uses _Database global object defined in MOOSE.
function SPAWN:ReSpawn( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex } )
	
	if not SpawnIndex then
		SpawnIndex = 1
	end

	--local SpawnGroup = self:GetGroupFromIndex( SpawnIndex ):GetDCSGroup()
	--if SpawnGroup then
		--DCSGroup:destroy()
	--end
	
	return self:SpawnWithIndex( SpawnIndex )
end

--- Will SPAWN a Group with a specified index number whenever you want to do this.
-- Note that the configuration with the above functions will apply when calling this method: Maxima, Randomization of routes, Scheduler, ...
-- Uses @{DATABASE} global object defined in MOOSE.
-- @treturn GROUP The @{GROUP} that was spawned. You can use this group for further actions.
function SPAWN:SpawnWithIndex( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnMaxGroups } )
	
	if self:GetSpawnIndex( SpawnIndex ) then
		
		if self.SpawnGroups[self.SpawnIndex].Visible then
			self.SpawnGroups[self.SpawnIndex].Group:Activate()
		else
			self:T( self.SpawnGroups[self.SpawnIndex].SpawnTemplate )
			self.SpawnGroups[self.SpawnIndex].Group = _Database:Spawn( self.SpawnGroups[self.SpawnIndex].SpawnTemplate )
			--if self.SpawnRepeat then
			--	_Database:SetStatusGroup( SpawnTemplate.name, "ReSpawn" )
			--end
		end
		
		self.SpawnGroups[self.SpawnIndex].Spawned = true
		return self.SpawnGroups[self.SpawnIndex].Group
	else
		env.info( "No more Groups to Spawn" )
	end

	return nil
end

--- SPAWNs a new Group within varying time intervals. This is useful if you want to have continuity within your missions of certain (AI) Groups to be present (alive) within your missions.
-- @tparam number SpawnTime is the time interval defined in seconds between each new SPAWN of new Groups.
-- @tparam number SpawnTimeVariation is the variation to be applied on the defined time interval between each new SPAWN. The variation is defined as a value between 0 and 1, which expresses the %-tage of variation to be applied as the low and high time interval boundaries. Between these boundaries a new time interval will be applied. See usage.
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- -- The time interval is set to SPAWN new helicopters between each 600 seconds, with a time variation of 50%.
-- -- The time variation in this case will be between 450 seconds and 750 seconds. 
-- -- This is calculated as follows: 
-- --      Low limit:   600 * ( 1 - 0.5 / 2 ) = 450 
-- --      High limit:  600 * ( 1 + 0.5 / 2 ) = 750
-- -- Between these two values, a random amount of seconds will be choosen for each new SPAWN of the helicopters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):Schedule( 600, 0.5 )

function SPAWN:SpawnScheduled( SpawnTime, SpawnTimeVariation )
	self:T( { SpawnTime, SpawnTimeVariation } )

	self.SpawnCurrentTimer = 0									-- The internal timer counter to trigger a scheduled spawning of SpawnTemplatePrefix.
	self.SpawnSetTimer = 0										-- The internal timer value when a scheduled spawning of SpawnTemplatePrefix occurs.
	self.AliveFactor = 1									--
	self.SpawnLowTimer = 0
	self.SpawnHighTimer = 0
	
	if SpawnTime ~= nil and SpawnTimeVariation ~= nil then
		self.SpawnLowTimer = SpawnTime - SpawnTime / 2 * SpawnTimeVariation
		self.SpawnHighTimer = SpawnTime + SpawnTime / 2 * SpawnTimeVariation
		self:ScheduleStart()
	end

	self:T( { self.SpawnLowTimer, self.SpawnHighTimer } )
	
	return self
end

--- Will start the SPAWNing timers.
-- This function is called automatically when @{Schedule} is called.
function SPAWN:ScheduleStart()
	self:T( { self.SpawnTemplatePrefix } )

	--local ClientUnit = #AlivePlayerUnits()
	
	self.AliveFactor = 10 -- ( 10 - ClientUnit  ) / 10
	
	if self.SpawnIsScheduled == false then
		self.SpawnIsScheduled = true
		self.SpawnInit = true
		self.SpawnSetTimer = math.random( self.SpawnLowTimer * self.AliveFactor / 10 , self.SpawnHighTimer * self.AliveFactor  / 10 )
		
		self.SpawnFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, 1 )
	end
end

--- Will stop the scheduled SPAWNing activity.
function SPAWN:ScheduleStop()
	self:T( { self.SpawnTemplatePrefix } )
	
	self.SpawnIsScheduled = false
end

--- Limits the Maximum amount of Units to be alive, and the maximum amount of Groups to be SPAWNed within the DCS World run-time environment.
-- Note that this method is exceptionally important to balance the amount of Units alive within the DCSRTE and the performance of the mission. Depending on the machine etc, a mission can only process a maximum amount of units.
-- If the time interval must be short, but there should not be more Units or Groups alive than a maximum amount of units, then this function should be used...
-- @tparam number SpawnMaxGroupsAlive is the Maximum amount of Units to be alive. When there are more Units alive in the DCSRTE of SpawnTemplatePrefix, then no new SPAWN will happen of the Group, until some of these Units will be destroyed.
-- @tparam number SpawnMaxGroups is the Maximum amount of Groups that can be SPAWNed from SpawnTemplatePrefix. When there are more Groups alive in the DCSRTE of SpawnTemplatePrefix, then no more SPAWNs will happen of the Group. This parameter is useful to define a maximum amount of airplanes, ground troops, helicopters, ships etc within a supply area. 
--        This parameter accepts the value 0, which expresses no Group count limits.
-- @treturn SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- -- This helicopter group consists of one Unit. So, this group will SPAWN maximum 2 groups simultaneously within the DCSRTE.
-- -- There will be maximum 24 groups SPAWNed during the whole mission lifetime. 
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):Limit( 2, 24 )



--- Will SPAWN a Group whenever you want to do this, but for AIR Groups only to be applied, and will SPAWN the Group in Uncontrolled mode... This will be similar to the Uncontrolled flag setting in the ME.
-- @treturn SPAWN
function SPAWN:UnControlled()
	self:T( { self.SpawnTemplatePrefix } )
	
	self.SpawnUnControlled = true
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self.SpawnGroups[SpawnGroupID].UnControlled = true
	end
	
	return self
end


--- Will SPAWN a Group from a Hosting @{UNIT}. This function is mostly advisable to be used if you want to simulate SPAWNing from air units, like helicopters, which are dropping infantry into a defined Landing Zone.
-- Note that each point in the route assigned to the spawning @{GROUP} is reset to the Point of the spawn.
-- You can use the returned @{GROUP} to further define the route to be followed.
-- @tparam UNIT HostUnit is the AIR unit or GROUND unit dropping or unloading the Spawn group.
-- @treturn GROUP Spawned.
-- @treturn nil when nothing was spawned.
function SPAWN:SpawnFromUnit( HostUnit, OuterRadius, InnerRadius, SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, HostUnit, SpawnFormation, SpawnIndex } )

	if HostUnit and HostUnit:IsAlive() then -- and HostUnit:getUnit(1):inAir() == false then

		if SpawnIndex then
		else
			SpawnIndex = self.SpawnIndex + 1
		end
		
		if self:GetSpawnIndex( SpawnIndex ) then
			
			local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
		
			if SpawnTemplate then

				local UnitPoint = HostUnit:GetPoint()
				--for PointID, Point in pairs( SpawnTemplate.route.points ) do
					--Point.x = UnitPoint.x
					--Point.y = UnitPoint.y
					--Point.alt = nil
					--Point.alt_type = nil
				--end
				
				SpawnTemplate.route.points = nil
				SpawnTemplate.route.points = {}
				SpawnTemplate.route.points[1] = {}
				SpawnTemplate.route.points[1].x = UnitPoint.x
				SpawnTemplate.route.points[1].y = UnitPoint.y

				if not InnerRadius then
					InnerRadius = 10
				end
				
				if not OuterRadius then
					OuterRadius = 50
				end
				
				-- Apply SpawnFormation
				for UnitID = 1, #SpawnTemplate.units do
					if InnerRadius == 0 then
						SpawnTemplate.units[UnitID].x = UnitPoint.x
						SpawnTemplate.units[UnitID].y = UnitPoint.y
					else
						local CirclePos = routines.getRandPointInCircle( UnitPoint, InnerRadius+1, InnerRadius )
						SpawnTemplate.units[UnitID].x = CirclePos.x
						SpawnTemplate.units[UnitID].y = CirclePos.y
					end
					self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
				end
				
				local SpawnPos = routines.getRandPointInCircle( UnitPoint, InnerRadius+1, InnerRadius )
				local Point = {}
				Point.type = "Turning Point"
				Point.x = SpawnPos.x
				Point.y = SpawnPos.y
				Point.action = "Cone"
				Point.speed = 5
				
				table.insert( SpawnTemplate.route.points, 2, Point )
				
				return self:SpawnWithIndex( self.SpawnIndex )
			end
		end
	end
	
	return nil
end

--- Will spawn a Group within a given @{ZONE}.
-- @tparam ZONE The @{ZONE} where the Group is to be SPAWNed.
-- @treturn GROUP that was spawned.
-- @treturn nil when nothing as spawned.
function SPAWN:SpawnInZone( Zone, SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, Zone, SpawnIndex } )
	
	if Zone then
		
		if SpawnIndex then
		else
			SpawnIndex = self.SpawnIndex + 1
		end
		
		if self:GetSpawnIndex( SpawnIndex ) then

			local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
			
			if SpawnTemplate then
		
				local ZonePoint = Zone:GetPoint()

				SpawnTemplate.route.points = nil
				SpawnTemplate.route.points = {}
				SpawnTemplate.route.points[1] = {}
				SpawnTemplate.route.points[1].x = ZonePoint.x
				SpawnTemplate.route.points[1].y = ZonePoint.y
				
				-- Apply SpawnFormation
				for UnitID = 1, #SpawnTemplate.units do
					SpawnTemplate.units[UnitID].x = ZonePoint.x
					SpawnTemplate.units[UnitID].y = ZonePoint.y
					self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
				end
				
				local SpawnPos = Zone:GetRandomPoint()
				local Point = {}
				Point.type = "Turning Point"
				Point.x = SpawnPos.x
				Point.y = SpawnPos.y
				Point.action = "Cone"
				Point.speed = 5
				
				table.insert( SpawnTemplate.route.points, 2, Point )
				
				return self:SpawnWithIndex( self.SpawnIndex )
			end
		end
	end
	
	return nil
end


--- Will return the SpawnGroupName either with with a specific count number or without any count.
-- @tparam number SpawnIndex is the number of the Group that is to be SPAWNed.
-- @treturn string SpawnGroupName
function SPAWN:SpawnGroupName( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, SpawnIndex } )

	local SpawnPrefix = self.SpawnTemplatePrefix
	if self.SpawnAliasPrefix then
		SpawnPrefix = self.SpawnAliasPrefix
	end

	if SpawnIndex then
		local SpawnName = string.format( '%s#%03d', SpawnPrefix, SpawnIndex )
		self:T( SpawnName )
		return SpawnName
	else
		self:T( SpawnPrefix )
		return SpawnPrefix
	end
	
end

function SPAWN:GetGroupFromIndex( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnIndex } )
	
	if SpawnIndex then
		local SpawnGroup = self.SpawnGroups[SpawnIndex].Group
		return SpawnGroup
	else
		local SpawnGroup = self.SpawnGroups[1].Group
		return SpawnGroup
	end
end

function SPAWN:GetGroupIndexFromDCSUnit( DCSUnit )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )

	if DCSUnit and DCSUnit:getName() then
		local IndexString = string.match( DCSUnit:getName(), "#.*-" ):sub( 2, -2 )
		self:T( IndexString )
		
		if IndexString then
			local Index = tonumber( IndexString )
			self:T( { "Index:", IndexString, Index } )
			return Index
		end
	end
	
	return nil
end

function SPAWN:GetPrefixFromDCSUnit( DCSUnit )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )

	if DCSUnit and DCSUnit:getName() then
		local SpawnPrefix = string.match( DCSUnit:getName(), ".*#" )
		if SpawnPrefix then
			SpawnPrefix = SpawnPrefix:sub( 1, -2 )
		else
			self:E( { "This name does not contain a #", DCSUnit:getName() } )
		end
		self:T( SpawnPrefix )
		return SpawnPrefix
	end
	
	return nil
end

function SPAWN:GetGroupFromDCSUnit( DCSUnit )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )
	
	if DCSUnit then
		local SpawnPrefix = self:GetPrefixFromDCSUnit( DCSUnit )
		
		if self.SpawnTemplatePrefix == SpawnPrefix or ( self.SpawnAliasPrefix and self.SpawnAliasPrefix == SpawnPrefix ) then
			local SpawnGroupIndex = self:GetGroupIndexFromDCSUnit( DCSUnit )
			local SpawnGroup = self.SpawnGroups[SpawnGroupIndex].Group
			self:T( SpawnGroup )
			return SpawnGroup
		end
	end

	return nil
end


--TODO: Rename to GetGroupIndexFromGroup
function SPAWN:GetGroupIndexFromGroup( SpawnGroup )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnGroup } )
	
	local IndexString = string.match( SpawnGroup:GetName(), "#.*$" ):sub( 2 )
	local Index = tonumber( IndexString )
	
	self:T( IndexString, Index )
	return Index
	
end

function SPAWN:GetLastIndex()
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )

	return self.SpawnMaxGroups
end


function SPAWN:InitializeSpawnGroups( SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnIndex } )

	if not self.SpawnGroups[SpawnIndex] then
		self.SpawnGroups[SpawnIndex] = {}
		self.SpawnGroups[SpawnIndex].Visible = false
		self.SpawnGroups[SpawnIndex].Spawned = false
		self.SpawnGroups[SpawnIndex].UnControlled = false
		self.SpawnGroups[SpawnIndex].Spawned = false
		self.SpawnGroups[SpawnIndex].SpawnTime = 0
		
		self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix = self.SpawnTemplatePrefix
		self.SpawnGroups[SpawnIndex].SpawnTemplate = self:_Prepare( self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix, SpawnIndex )
	end
	
	self:_RandomizeTemplate( SpawnIndex )
	self:_RandomizeRoute( SpawnIndex )
	--self:_TranslateRotate( SpawnIndex )
	
	return self.SpawnGroups[SpawnIndex]
end



function SPAWN:GetFirstAliveGroup( SpawnCursor )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnCursor } )

	for SpawnIndex = 1, self.SpawnCount do
		local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
		if SpawnGroup and SpawnGroup:IsAlive() then
			SpawnCursor = SpawnIndex
			return SpawnGroup, SpawnCursor
		end
	end
	
	return nil, nil
end

function SPAWN:GetNextAliveGroup( SpawnCursor )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnCursor } )

	SpawnCursor = SpawnCursor + 1
	for SpawnIndex = SpawnCursor, self.SpawnCount do
		local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
		if SpawnGroup and SpawnGroup:IsAlive() then
			SpawnCursor = SpawnIndex
			return SpawnGroup, SpawnCursor
		end
	end
	
	return nil, nil
end

function SPAWN:GetLastAliveGroup()
	self:T( { self.SpawnTemplatePrefixself.SpawnAliasPrefix } )

	self.SpawnIndex = self:GetLastIndex()
	for SpawnIndex = self.SpawnIndex, 1, -1 do
		local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
		if SpawnGroup and SpawnGroup:IsAlive() then
			self.SpawnIndex = SpawnIndex
			return SpawnGroup
		end
	end

	self.SpawnIndex = nil
	return nil
end



--- Private
-- @section

--- Gets the CategoryID of the Group with the given SpawnPrefix
function SPAWN:_GetGroupCategoryID( SpawnPrefix )
	local TemplateGroup = Group.getByName( SpawnPrefix )
	
	if TemplateGroup then
		return TemplateGroup:getCategory()
	else
		return nil
	end
end

--- Gets the CoalitionID of the Group with the given SpawnPrefix
function SPAWN:_GetGroupCoalitionID( SpawnPrefix )
	local TemplateGroup = Group.getByName( SpawnPrefix )
	
	if TemplateGroup then
		return TemplateGroup:getCoalition()
	else
		return nil
	end
end

--- Gets the CountryID of the Group with the given SpawnPrefix
function SPAWN:_GetGroupCountryID( SpawnPrefix )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnPrefix } )
	
	local TemplateGroup = Group.getByName( SpawnPrefix )
	
	if TemplateGroup then
		local TemplateUnits = TemplateGroup:getUnits()
		return TemplateUnits[1]:getCountry()
	else
		return nil
	end
end

--- Gets the Group Template from the ME environment definition.
-- This method used the @{DATABASE} object, which contains ALL initial and new SPAWNed object in MOOSE.
function SPAWN:_GetTemplate( SpawnTemplatePrefix )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnTemplatePrefix } )

	local SpawnTemplate = nil

	SpawnTemplate = routines.utils.deepCopy( _Database.Groups[SpawnTemplatePrefix].Template )
	
	if SpawnTemplate == nil then
		error( 'No Template returned for SpawnTemplatePrefix = ' .. SpawnTemplatePrefix )
	end

	SpawnTemplate.SpawnCoalitionID = self:_GetGroupCoalitionID( SpawnTemplatePrefix )
	SpawnTemplate.SpawnCategoryID = self:_GetGroupCategoryID( SpawnTemplatePrefix )
	SpawnTemplate.SpawnCountryID = self:_GetGroupCountryID( SpawnTemplatePrefix )
	
	self:T( { SpawnTemplate } )
	return SpawnTemplate
end

--- Prepares the new Group Template.
function SPAWN:_Prepare( SpawnTemplatePrefix, SpawnIndex )
	self:T( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )
	
	local SpawnTemplate = self:_GetTemplate( SpawnTemplatePrefix )
	SpawnTemplate.name = self:SpawnGroupName( SpawnIndex )
	
	SpawnTemplate.groupId = nil
	SpawnTemplate.lateActivation = false

	if SpawnTemplate.SpawnCategoryID == Group.Category.GROUND then
		SpawnTemplate.visible = false
	end
	
	if SpawnTemplate.SpawnCategoryID == Group.Category.HELICOPTER or SpawnTemplate.SpawnCategoryID == Group.Category.AIRPLANE then
		SpawnTemplate.uncontrolled = false
	end

	for UnitID = 1, #SpawnTemplate.units do
		SpawnTemplate.units[UnitID].name = string.format( SpawnTemplate.name .. '-%02d', UnitID )
		SpawnTemplate.units[UnitID].unitId = nil
		SpawnTemplate.units[UnitID].x = SpawnTemplate.route.points[1].x
		SpawnTemplate.units[UnitID].y = SpawnTemplate.route.points[1].y 
	end
	
	self:T( { "Template:", SpawnTemplate } )
	return SpawnTemplate
		
end

--- Events
-- @section Events

--- Obscolete
-- @todo Need to delete this... _Database does this now ...
function SPAWN:OnBirth( event )

	if timer.getTime0() < timer.getAbsTime() then -- dont need to add units spawned in at the start of the mission if mist is loaded in init line
		if event.initiator and event.initiator:getName() then
			local EventPrefix = self:GetPrefixFromDCSUnit( event.initiator )
			if EventPrefix == self.SpawnTemplatePrefix or ( self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix ) then
				self:T( { "Birth event: " .. event.initiator:getName(), event } )
				--MessageToAll( "Mission command: unit " .. SpawnTemplatePrefix .. " spawned." , 5,  EventPrefix .. '/Event')
				self.AliveUnits = self.AliveUnits + 1
				self:T( "Alive Units: " .. self.AliveUnits )
			end
		end
	end

end

--- Obscolete
-- @todo Need to delete this... _Database does this now ...
function SPAWN:OnDeadOrCrash( event )


	if event.initiator and event.initiator:getName() then
		local EventPrefix = self:GetPrefixFromDCSUnit( event.initiator )
		if EventPrefix == self.SpawnTemplatePrefix or ( self.SpawnAliasPrefix and EventPrefix == self.SpawnAliasPrefix ) then
			self:T( { "Dead event: " .. event.initiator:getName(), event } )
--					local DestroyedUnit = Unit.getByName( EventPrefix )
--					if DestroyedUnit and DestroyedUnit.getLife() <= 1.0 then
				--MessageToAll( "Mission command: unit " .. SpawnTemplatePrefix .. " crashed." , 5,  EventPrefix .. '/Event')
				self.AliveUnits = self.AliveUnits - 1
				self:T( "Alive Units: " .. self.AliveUnits )
--					end
		end
	end
end

--- Will detect AIR Units taking off... When the event takes place, the SPAWNed Group is registered as airborne...
-- This is needed to ensure that Re-SPAWNing only is done for landed AIR Groups.
-- @todo Need to test for AIR Groups only...
function SPAWN:OnTakeOff( event )

	if event.initiator and event.initiator:getName() then
		local SpawnGroup = self:GetGroupFromDCSUnit( event.initiator )
		if SpawnGroup then
			self:T( { "TakeOff event: " .. event.initiator:getName(), event } )
			self:T( "self.Landed = false" )
			self.Landed = false
		end
	end
end

--- Will detect AIR Units landing... When the event takes place, the SPAWNed Group is registered as landed.
-- This is needed to ensure that Re-SPAWNing is only done for landed AIR Groups.
-- @todo Need to test for AIR Groups only...
function SPAWN:OnLand( event )

	if event.initiator and event.initiator:getName() then
		local SpawnGroup = self:GetGroupFromDCSUnit( event.initiator )
		if SpawnGroup then
			self:T( { "Landed event:" .. event.initiator:getName(), event } )
			self.Landed = true
			self:T( "self.Landed = true" )
			if self.Landed and self.RepeatOnLanding then
				local SpawnGroupIndex = self:GetGroupIndexFromGroup( SpawnGroup )
				self:T( { "Landed:", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
				self:ReSpawn( SpawnGroupIndex )
			end
		end
	end
end

--- Will detect AIR Units shutting down their engines ...
-- When the event takes place, and the method @{RepeatOnEngineShutDown} was called, the SPAWNed Group will Re-SPAWN.
-- But only when the Unit was registered to have landed.
-- @see OnTakeOff
-- @see OnLand
-- @todo Need to test for AIR Groups only...
function SPAWN:OnEngineShutDown( event )

	if event.initiator and event.initiator:getName() then
		local SpawnGroup = self:GetGroupFromDCSUnit( event.initiator )
		if SpawnGroup then
			self:T( { "EngineShutDown event: " .. event.initiator:getName(), event } )
			if self.Landed and self.RepeatOnEngineShutDown then
				local SpawnGroupIndex = self:GetGroupIndexFromGroup( SpawnGroup )
				self:T( { "EngineShutDown: ", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
				self:ReSpawn( SpawnGroupIndex )
			end
		end
	end
end

--- Scheduled
-- @section Scheduled

--- This function is called automatically by the Spawning scheduler.
-- It is the internal worker method SPAWNing new Groups on the defined time intervals.
function SPAWN:_Scheduler()
self:T( { "_Scheduler", self.SpawnTemplatePrefix, self.SpawnAliasPrefix, self.SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxGroupsAlive } )
	
	if self.SpawnInit or self.SpawnCurrentTimer == self.SpawnSetTimer then
		-- Validate if there are still groups left in the batch...
		self:Spawn()
		self.SpawnInit = false
		if self.SpawnIsScheduled == true then
			--local ClientUnit = #AlivePlayerUnits()
			self.AliveFactor = 1 -- ( 10 - ClientUnit  ) / 10
			self.SpawnCurrentTimer = 0
			self.SpawnSetTimer = math.random( self.SpawnLowTimer * self.AliveFactor , self.SpawnHighTimer * self.AliveFactor )
		end
	else
		self.SpawnCurrentTimer = self.SpawnCurrentTimer + 1
	end
end

function SPAWN:_SpawnCleanUpScheduler()
	self:T( { "CleanUp Scheduler:", self.SpawnTemplatePrefix } )

	local SpawnCursor
	local SpawnGroup, SpawnCursor = self:GetFirstAliveGroup( SpawnCursor )
	
	self:T( { "CleanUp Scheduler:", SpawnGroup } )

	while SpawnGroup do
		
		if SpawnGroup:AllOnGround() and SpawnGroup:GetMaxVelocity() < 1 then
			if not self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] then
				self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] = timer.getTime()
			else
				if self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] + self.SpawnCleanUpInterval < timer.getTime() then
					self:T( { "CleanUp Scheduler:", "Cleaning:", SpawnGroup } )
					SpawnGroup:Destroy()
				end
			end
		else
			self.SpawnCleanUpTimeStamps[SpawnGroup:GetName()] = nil
		end
		
		SpawnGroup, SpawnCursor = self:GetNextAliveGroup( SpawnCursor )
		
		self:T( { "CleanUp Scheduler:", SpawnGroup } )
		
	end
	
end


--- Limit the simultaneous movement of Groups within a running Mission.
-- This module is defined to improve the performance in missions, and to bring additional realism for GROUND vehicles.
-- Performance: If in a DCSRTE there are a lot of moving GROUND units, then in a multi player mission, this WILL create lag if
-- the main DCS execution core of your CPU is fully utilized. So, this class will limit the amount of simultaneous moving GROUND units
-- on defined intervals (currently every minute).
-- @classmod MOVEMENT

Include.File( "Routines" )

MOVEMENT = {
	ClassName = "MOVEMENT",
}

--- Creates the main object which is handling the GROUND forces movement.
-- @tparam table{string,...}|string MovePrefixes is a table of the Prefixes (names) of the GROUND Groups that need to be controlled by the MOVEMENT Object.
-- @tparam number MoveMaximum is a number that defines the maximum amount of GROUND Units to be moving during one minute.
-- @treturn MOVEMENT
-- @usage
-- -- Limit the amount of simultaneous moving units on the ground to prevent lag.
-- Movement_US_Platoons = MOVEMENT:New( { 'US Tank Platoon Left', 'US Tank Platoon Middle', 'US Tank Platoon Right', 'US CH-47D Troops' }, 15 )

function MOVEMENT:New( MovePrefixes, MoveMaximum )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( { MovePrefixes, MoveMaximum } )
  
	if type( MovePrefixes ) == 'table' then
		self.MovePrefixes = MovePrefixes
	else
		self.MovePrefixes = { MovePrefixes }
	end
	self.MoveCount = 0															-- The internal counter of the amount of Moveing the has happened since MoveStart.
	self.MoveMaximum = MoveMaximum												-- Contains the Maximum amount of units that are allowed to move...
	self.AliveUnits = 0														-- Contains the counter how many units are currently alive
	self.MoveUnits = {}														-- Reflects if the Moving for this MovePrefixes is going to be scheduled or not.
	
	self.AddEvent( self, world.event.S_EVENT_BIRTH, self.OnBirth )
	self.AddEvent( self, world.event.S_EVENT_DEAD, self.OnDeadOrCrash )
	self.AddEvent( self, world.event.S_EVENT_CRASH, self.OnDeadOrCrash )
	
	self.EnableEvents( self )
	
	self.ScheduleStart( self )

	return self
end

--- Call this function to start the MOVEMENT scheduling.
function MOVEMENT:ScheduleStart()
self:T()
	self.MoveFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, 120 )
end

--- Call this function to stop the MOVEMENT scheduling.
-- @todo need to implement it ... Forgot.
function MOVEMENT:ScheduleStop()
self:T()

end

--- Captures the birth events when new Units were spawned.
-- @todo This method should become obsolete. The new @{DATABASE} class will handle the collection administration.
function MOVEMENT:OnBirth( event )
self:T( { event } )

	if timer.getTime0() < timer.getAbsTime() then -- dont need to add units spawned in at the start of the mission if mist is loaded in init line
		if event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT then
			local MovementUnit = event.initiator
			local MovementUnitName = MovementUnit:getName()
			self:T( "Birth object : " .. MovementUnitName )
			local MovementGroup = MovementUnit:getGroup()
			if MovementGroup and MovementGroup:isExist() then
				local MovementGroupName = MovementGroup:getName()
				for MovePrefixID, MovePrefix in pairs( self.MovePrefixes ) do
					if string.find( MovementUnitName, MovePrefix, 1, true ) then
						self.AliveUnits = self.AliveUnits + 1
						self.MoveUnits[MovementUnitName] = MovementGroupName
						self:T( self.AliveUnits )
					end
				end
			end
		end
	end

end

--- Captures the Dead or Crash events when Units crash or are destroyed.
-- @todo This method should become obsolete. The new @{DATABASE} class will handle the collection administration.
function MOVEMENT:OnDeadOrCrash( event )
self:T( { event } )

	if event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT then
		local MovementUnit = event.initiator
		local MovementUnitName = MovementUnit:getName()
		self:T( "Dead object : " .. MovementUnitName )
		for MovePrefixID, MovePrefix in pairs( self.MovePrefixes ) do
			if string.find( MovementUnitName, MovePrefix, 1, true ) then
				self.AliveUnits = self.AliveUnits - 1
				self.MoveUnits[MovementUnitName] = nil
				self:T( self.AliveUnits )
			end
		end
	end
end

--- This function is called automatically by the MOVEMENT scheduler. A new function is scheduled when MoveScheduled is true.
function MOVEMENT:_Scheduler()
self:T( { self.MovePrefixes, self.MoveMaximum, self.AliveUnits, self.MovementGroups } )
	
	if self.AliveUnits > 0 then
		local MoveProbability = ( self.MoveMaximum * 100 ) / self.AliveUnits
		self:T( 'Move Probability = ' .. MoveProbability )
		
		for MovementUnitName, MovementGroupName in pairs( self.MoveUnits ) do
			local MovementGroup = Group.getByName( MovementGroupName )
			if MovementGroup and MovementGroup:isExist() then
				local MoveOrStop = math.random( 1, 100 )
				self:T( 'MoveOrStop = ' .. MoveOrStop )
				if MoveOrStop <= MoveProbability then
					self:T( 'Group continues moving = ' .. MovementGroupName )
					trigger.action.groupContinueMoving( MovementGroup )
				else
					self:T( 'Group stops moving = ' .. MovementGroupName )
					trigger.action.groupStopMoving( MovementGroup )
				end
			else
				self.MoveUnits[MovementUnitName] = nil
			end
		end
	end
end
--- Provides defensive behaviour to a set of SAM sites within a running Mission.
-- @classmod SEAD
-- @author to be searched on the forum
-- @author (co) Flightcontrol (Modified and enriched with functionality)

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )

SEAD = {
	ClassName = "SEAD", 
	TargetSkill = {
		Average   = { Evade = 50, DelayOff = { 10, 25 }, DelayOn = { 10, 30 } } ,
		Good      = { Evade = 30, DelayOff = { 8, 20 }, DelayOn = { 20, 40 } } ,
		High      = { Evade = 15, DelayOff = { 5, 17 }, DelayOn = { 30, 50 } } ,
		Excellent = { Evade = 10, DelayOff = { 3, 10 }, DelayOn = { 30, 60 } } 
	}, 
	SEADGroupPrefixes = {} 
}

--- Creates the main object which is handling defensive actions for SA sites or moving SA vehicles.
-- When an anti radiation missile is fired (KH-58, KH-31P, KH-31A, KH-25MPU, HARM missiles), the SA will shut down their radars and will take evasive actions...
-- Chances are big that the missile will miss.
-- @tparam table{string,...}|string SEADGroupPrefixes which is a table of Prefixes of the SA Groups in the DCSRTE on which evasive actions need to be taken.
-- @treturn SEAD
-- @usage
-- -- CCCP SEAD Defenses
-- -- Defends the Russian SA installations from SEAD attacks.
-- SEAD_RU_SAM_Defenses = SEAD:New( { 'RU SA-6 Kub', 'RU SA-6 Defenses', 'RU MI-26 Troops', 'RU Attack Gori' } )
function SEAD:New( SEADGroupPrefixes )
	local self = BASE:Inherit( self, BASE:New() )
	self:T( SEADGroupPrefixes )	
	if type( SEADGroupPrefixes ) == 'table' then
		for SEADGroupPrefixID, SEADGroupPrefix in pairs( SEADGroupPrefixes ) do
			self.SEADGroupPrefixes[SEADGroupPrefix] = SEADGroupPrefix
		end
	else
		self.SEADGroupNames[SEADGroupPrefixes] = SEADGroupPrefixes
	end
	self.AddEvent( self, world.event.S_EVENT_SHOT, self.EventShot )
	self.EnableEvents( self )
	
	return self
end

--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see SEAD
function SEAD:EventShot( event )
self:T( { event } )

	local SEADUnit = event.initiator
	local SEADUnitName = SEADUnit:getName()
	local SEADWeapon = event.weapon -- Identify the weapon fired						
	local SEADWeaponName = SEADWeapon:getTypeName()	-- return weapon type
	--trigger.action.outText( string.format("Alerte, depart missile " ..string.format(SEADWeaponName)), 20) --debug message
	-- Start of the 2nd loop
	self:T( "Missile Launched = " .. SEADWeaponName )
	if SEADWeaponName == "KH-58" or SEADWeaponName == "KH-25MPU" or SEADWeaponName == "AGM-88" or SEADWeaponName == "KH-31A" or SEADWeaponName == "KH-31P" then -- Check if the missile is a SEAD
		local _evade = math.random (1,100) -- random number for chance of evading action
		local _targetMim = Weapon.getTarget(SEADWeapon) -- Identify target
		local _targetMimname = Unit.getName(_targetMim)
		local _targetMimgroup = Unit.getGroup(Weapon.getTarget(SEADWeapon))
		local _targetMimgroupName = _targetMimgroup:getName()
		local _targetMimcont= _targetMimgroup:getController()
		local _targetskill =  _Database.Units[_targetMimname].Template.skill
		self:T( self.SEADGroupPrefixes )
		self:T( _targetMimgroupName )
		local SEADGroupFound = false
		for SEADGroupPrefixID, SEADGroupPrefix in pairs( self.SEADGroupPrefixes ) do
			if string.find( _targetMimgroupName, SEADGroupPrefix, 1, true ) then
				SEADGroupFound = true
				self:T( 'Group Found' )
				break
			end
		end		
		if SEADGroupFound == true then
			if _targetskill == "Random" then -- when skill is random, choose a skill
				local Skills = { "Average", "Good", "High", "Excellent" }
				_targetskill = Skills[ math.random(1,4) ]
			end
			self:T( _targetskill ) -- debug message for skill check
			if self.TargetSkill[_targetskill] then
				if (_evade > self.TargetSkill[_targetskill].Evade) then
					self:T( string.format("Evading, target skill  " ..string.format(_targetskill)) ) --debug message
					local _targetMim = Weapon.getTarget(SEADWeapon)
					local _targetMimname = Unit.getName(_targetMim)
					local _targetMimgroup = Unit.getGroup(Weapon.getTarget(SEADWeapon))
					local _targetMimcont= _targetMimgroup:getController()
					routines.groupRandomDistSelf(_targetMimgroup,300,'Diamond',250,20) -- move randomly
					local SuppressedGroups1 = {} -- unit suppressed radar off for a random time
					local function SuppressionEnd1(id)
						id.ctrl:setOption(AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.GREEN)
						SuppressedGroups1[id.groupName] = nil
					end
					local id = {
					groupName = _targetMimgroup,
					ctrl = _targetMimcont
					}
					local delay1 = math.random(self.TargetSkill[_targetskill].DelayOff[1], self.TargetSkill[_targetskill].DelayOff[2])
					if SuppressedGroups1[id.groupName] == nil then
						SuppressedGroups1[id.groupName] = {
							SuppressionEndTime1 = timer.getTime() + delay1,
							SuppressionEndN1 = SuppressionEndCounter1	--Store instance of SuppressionEnd() scheduled function
						}	
						Controller.setOption(_targetMimcont, AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.GREEN)
						timer.scheduleFunction(SuppressionEnd1, id, SuppressedGroups1[id.groupName].SuppressionEndTime1)	--Schedule the SuppressionEnd() function
						--trigger.action.outText( string.format("Radar Off " ..string.format(delay1)), 20)
					end
					
					local SuppressedGroups = {}
					local function SuppressionEnd(id)
						id.ctrl:setOption(AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.RED)
						SuppressedGroups[id.groupName] = nil
					end
					local id = {
						groupName = _targetMimgroup,
						ctrl = _targetMimcont
					}
					local delay = math.random(self.TargetSkill[_targetskill].DelayOn[1], self.TargetSkill[_targetskill].DelayOn[2])
					if SuppressedGroups[id.groupName] == nil then
						SuppressedGroups[id.groupName] = {
							SuppressionEndTime = timer.getTime() + delay,
							SuppressionEndN = SuppressionEndCounter	--Store instance of SuppressionEnd() scheduled function
						}
						timer.scheduleFunction(SuppressionEnd, id, SuppressedGroups[id.groupName].SuppressionEndTime)	--Schedule the SuppressionEnd() function
						--trigger.action.outText( string.format("Radar On " ..string.format(delay)), 20)
					end
				end
			end
		end
	end
end
