env.info( 'Moose Embedded' ) 
--- Various routines
-- @module routines
-- @author Flightcontrol

--Include.File( "Trace" )
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

	local s = string.format('%03d', az) .. ' for ' .. dist

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
		timer.scheduleFunction(routines.main, {}, timer.getTime() + 2)  --reschedule first in case of Lua error
		----------------------------------------------------------------------------------------------------------
		--area to add new stuff in

		routines.do_scheduled_functions()
	end -- end of routines.main

	timer.scheduleFunction(routines.main, {}, timer.getTime() + 2)

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
	
	--- Schedule a function
	-- @param #function f
	-- @param #table parameters
	-- @param #Time t
	-- @param #Time rep seconds
	-- @param #Time st
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
--trace.f()

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

--trace.r( "", "", { CurrentZoneID } )
	return CurrentZoneID
end



function routines.IsUnitInZones( TransportUnit, LandingZones )
--trace.f("", "routines.IsUnitInZones" )

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
			--trace.i( "routines", "TransportZone:" .. TransportZoneResult )
		else
			--trace.i( "routines", "TransportZone:nil logic" )
		end
		return TransportZoneResult
	else
		--trace.i( "routines", "TransportZone:nil hard" )
		return nil
	end
end

function routines.IsUnitNearZonesRadius( TransportUnit, LandingZones, ZoneRadius )
--trace.f("", "routines.IsUnitInZones" )

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
          if  ((( TransportUnitPos.x - TransportZonePos.x)^2 + (TransportUnitPos.z - TransportZonePos.z)^2)^0.5 <= ZoneRadius ) then
            TransportZoneResult = LandingZoneID
            break
          end
        end
      end
    else
      TransportZone = trigger.misc.getZone( LandingZones )
      TransportZonePos = {radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z}
      if  ((( TransportUnitPos.x - TransportZonePos.x)^2 + (TransportUnitPos.z - TransportZonePos.z)^2)^0.5 <= ZoneRadius ) then
        TransportZoneResult = 1
      end
    end
    if TransportZoneResult then
      --trace.i( "routines", "TransportZone:" .. TransportZoneResult )
    else
      --trace.i( "routines", "TransportZone:nil logic" )
    end
    return TransportZoneResult
  else
    --trace.i( "routines", "TransportZone:nil hard" )
    return nil
  end
end


function routines.IsStaticInZones( TransportStatic, LandingZones )
--trace.f()

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

--trace.r( "", "", { TransportZoneResult } )
    return TransportZoneResult
end


function routines.IsUnitInRadius( CargoUnit, ReferencePosition, Radius )
--trace.f()

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
--trace.f()

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
--trace.f()

  if  type( Variable ) == "string" then
    if Variable == "" then
      error( "routines.ValidateString: error: " .. VariableName .. " must be filled out!" )
      Valid = false
    end
  else
    error( "routines.ValidateString: error: " .. VariableName .. " is not a string." )
    Valid = false
  end

--trace.r( "", "", { Valid } )
  return Valid
end

function routines.ValidateNumber( Variable, VariableName, Valid )
--trace.f()

  if  type( Variable ) == "number" then
  else
    error( "routines.ValidateNumber: error: " .. VariableName .. " is not a number." )
    Valid = false
  end

--trace.r( "", "", { Valid } )
  return Valid

end

function routines.ValidateGroup( Variable, VariableName, Valid )
--trace.f()

	if Variable == nil then
		error( "routines.ValidateGroup: error: " .. VariableName .. " is a nil value!" )
		Valid = false
	end

--trace.r( "", "", { Valid } )
	return Valid
end

function routines.ValidateZone( LandingZones, VariableName, Valid )
--trace.f()

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

--trace.r( "", "", { Valid } )
	return Valid
end

function routines.ValidateEnumeration( Variable, VariableName, Enum, Valid )
--trace.f()

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

--trace.r( "", "", { Valid } )
  return Valid
end

function routines.getGroupRoute(groupIdent, task)   -- same as getGroupPoints but returns speed and formation type along with vec2 of point}
		-- refactor to search by groupId and allow groupId and groupName as inputs
	local gpId = groupIdent
	if type(groupIdent) == 'string' and not tonumber(groupIdent) then
		gpId = _DATABASE.Templates.Groups[groupIdent].groupId
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
--trace.f( "routines" )

	local UnitPoint = CheckUnit:getPoint()
	local UnitPosition = { x = UnitPoint.x, y = UnitPoint.z }
	local UnitHeight = UnitPoint.y

	local LandHeight = land.getHeight( UnitPosition )

	--env.info(( 'CarrierHeight: LandHeight = ' .. LandHeight .. ' CarrierHeight = ' .. CarrierHeight ))

	--trace.f( "routines", "Unit Height = " .. UnitHeight - LandHeight )
	
	return UnitHeight - LandHeight

end



Su34Status = { status = {} }
boardMsgRed = { statusMsg = "" }
boardMsgAll = { timeMsg = "" }
SpawnSettings = {}
Su34MenuPath = {}
Su34Menus = 0


function Su34AttackCarlVinson(groupName)
--trace.menu("", "Su34AttackCarlVinson")
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
--trace.f("","Su34AttackWest")
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
--trace.menu("","Su34AttackNorth")
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
--trace.menu("","Su34Orbit")
	local groupSu34 = Group.getByName( groupName )
	local controllerSu34 = groupSu34:getController()
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
	controllerSu34:pushTask( {id = 'ControlledTask', params = { task = { id = 'Orbit', params = { pattern = AI.Task.OrbitPattern.RACE_TRACK } }, stopCondition = { duration = 600 } } } )
	Su34Status.status[groupName] = 4
	MessageToRed( string.format('%s: ',groupName) .. 'In orbit and awaiting further instructions. ', 10, 'RedStatus' .. groupName )
end

function Su34TakeOff(groupName)
--trace.menu("","Su34TakeOff")
	local groupSu34 = Group.getByName( groupName )
	local controllerSu34 = groupSu34:getController()
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE )
	Su34Status.status[groupName] = 8
	MessageToRed( string.format('%s: ',groupName) .. 'Take-Off. ', 10, 'RedStatus' .. groupName )
end

function Su34Hold(groupName)
--trace.menu("","Su34Hold")
	local groupSu34 = Group.getByName( groupName )
	local controllerSu34 = groupSu34:getController()
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
	controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE )
	Su34Status.status[groupName] = 5
	MessageToRed( string.format('%s: ',groupName) .. 'Holding Weapons. ', 10, 'RedStatus' .. groupName )
end

function Su34RTB(groupName)
--trace.menu("","Su34RTB")
	Su34Status.status[groupName] = 6
	MessageToRed( string.format('%s: ',groupName) .. 'Return to Krasnodar. ', 10, 'RedStatus' .. groupName )
end

function Su34Destroyed(groupName)
--trace.menu("","Su34Destroyed")
	Su34Status.status[groupName] = 7
	MessageToRed( string.format('%s: ',groupName) .. 'Destroyed. ', 30, 'RedStatus' .. groupName )
end

function GroupAlive( groupName )
--trace.menu("","GroupAlive")
	local groupTest = Group.getByName( groupName )

	local groupExists = false

	if groupTest then
		groupExists = groupTest:isExist()
	end

	--trace.r( "", "", { groupExists } )
	return groupExists
end

function Su34IsDead()
--trace.f()

end

function Su34OverviewStatus()
--trace.menu("","Su34OverviewStatus")
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
--trace.f()
	Su34OverviewStatus()
	MessageToRed( boardMsgRed.statusMsg, 15, 'RedStatus' )
end

function MusicReset( flg )
--trace.f()
	trigger.action.setUserFlag(95,flg)
end

function PlaneActivate(groupNameFormat, flg)
--trace.f()
	local groupName = groupNameFormat .. string.format("#%03d", trigger.misc.getUserFlag(flg))
	--trigger.action.outText(groupName,10)
	trigger.action.activateGroup(Group.getByName(groupName))
end

function Su34Menu(groupName)
--trace.f()

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
--trace.f("Spawn")
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
--trace.f()
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
--trace.f()
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
--trace.f()

	if CarrierGroup ~= nil then
		MessageToGroup( CarrierGroup, CarrierMessage, 30, 'Carrier/' .. CarrierGroup:getName() )
	end

end

function MessageToGroup( MsgGroup, MsgText, MsgTime, MsgName )
--trace.f()

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
--trace.f()

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
--trace.f()

	MESSAGE:New( MsgText, "Message", MsgTime, MsgName ):ToCoalition( coalition.side.RED ):ToCoalition( coalition.side.BLUE )
end

function MessageToRed( MsgText, MsgTime, MsgName )
--trace.f()

	MESSAGE:New( MsgText, "To Red Coalition", MsgTime, MsgName ):ToCoalition( coalition.side.RED )
end

function MessageToBlue( MsgText, MsgTime, MsgName )
--trace.f()

	MESSAGE:New( MsgText, "To Blue Coalition", MsgTime, MsgName ):ToCoalition( coalition.side.RED )
end

function getCarrierHeight( CarrierGroup )
--trace.f()

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
--trace.f()

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
--trace.f()

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
--trace.f()

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
--trace.f()

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
--trace.f()

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
--trace.scheduled("", "MusicScheduler")

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

--- BASE classes.
-- 
-- @{#BASE} class
-- ==============
-- The @{#BASE} class is the super class for most of the classes defined within MOOSE.
-- 
-- It handles:
-- 
--   * The construction and inheritance of child classes.
--   * The tracing of objects during mission execution within the DCS.log file (under saved games folder).
-- 
-- Note: Normally you would not use the BASE class unless you are extending the MOOSE framework with new classes.
-- 
-- BASE Trace functionality
-- ========================
-- The BASE class contains trace methods to trace progress within a mission execution of a certain object.
-- Note that these trace methods are inherited by each MOOSE class interiting BASE.
-- As such, each object created from derived class from BASE can use the tracing functions to trace its execution.
-- 
-- Trace a function call
-- ---------------------
-- There are basically 3 types of tracing methods available within BASE:
-- 
--   * @{#BASE.F}: Trace the beginning of a function and its given parameters.
--   * @{#BASE.T}: Trace further logic within a function giving optional variables or parameters.
--   * @{#BASE.E}: Trace an execption within a function giving optional variables or parameters. An exception will always be traced.
-- 
-- Tracing levels
-- --------------
-- There are 3 tracing levels within MOOSE.  
-- These tracing levels were defined to avoid bulks of tracing to be generated by lots of objects.
-- 
-- As such, the F and T methods have additional variants to trace level 2 and 3 respectively:
--
--   * @{#BASE.F2}: Trace the beginning of a function and its given parameters with tracing level 2.
--   * @{#BASE.F3}: Trace the beginning of a function and its given parameters with tracing level 3.
--   * @{#BASE.T2}: Trace further logic within a function giving optional variables or parameters with tracing level 2.
--   * @{#BASE.T3}: Trace further logic within a function giving optional variables or parameters with tracing level 3.
-- 
-- BASE Inheritance support
-- ========================
-- The following methods are available to support inheritance:
-- 
--   * @{#BASE.Inherit}: Inherits from a class.
--   * @{#BASE.Inherited}: Returns the parent class from the class.
-- 
-- Future
-- ======
-- Further methods may be added to BASE whenever there is a need to make "overall" functions available within MOOSE.
-- 
-- ====
-- 
-- @module Base
-- @author FlightControl

Include.File( "Routines" )

local _TraceOn = true
local _TraceLevel = 1
local _TraceClass = {
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
	--MENU_CLIENT = true,
	--MENU_CLIENT_COMMAND = true,
	--ESCORT = true,
	}
local _TraceClassMethod = {}

--- The BASE Class
-- @type BASE
-- @field ClassName The name of the class.
-- @field ClassID The ID number of the class.
BASE = {
  ClassName = "BASE",
  ClassID = 0,
  Events = {}
}

--- The Formation Class
-- @type FORMATION
-- @field Cone A cone formation.
FORMATION = {
  Cone = "Cone" 
}



--- The base constructor. This is the top top class of all classed defined within the MOOSE.
-- Any new class needs to be derived from this class for proper inheritance.
-- @param #BASE self
-- @return #BASE The new instance of the BASE class.
-- @usage
-- function TASK:New()
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
-- @param #BASE self
-- @param Child is the Child class that inherits.
-- @param #BASE Parent is the Parent class that the Child inherits from.
-- @return #BASE Child
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
-- @param #BASE self
-- @param #BASE Child is the Child class from which the Parent class needs to be retrieved.
-- @return #BASE
function BASE:Inherited( Child )
	local Parent = getmetatable( Child )
--	env.info('Inherited class of ' .. Child.ClassName .. ' is ' .. Parent.ClassName )
	return Parent
end

--- Get the ClassName + ClassID of the class instance.
-- The ClassName + ClassID is formatted as '%s#%09d'. 
-- @param #BASE self
-- @return #string The ClassName + ClassID of the class instance.
function BASE:GetClassNameAndID()
  return string.format( '%s#%09d', self:GetClassName(), self:GetClassID() )
end

--- Get the ClassName of the class instance.
-- @param #BASE self
-- @return #string The ClassName of the class instance.
function BASE:GetClassName()
  return self.ClassName
end

--- Get the ClassID of the class instance.
-- @param #BASE self
-- @return #string The ClassID of the class instance.
function BASE:GetClassID()
  return self.ClassID
end

--- Set a new listener for the class.
-- @param self
-- @param DCSTypes#Event Event
-- @param #function EventFunction
-- @return #BASE
function BASE:AddEvent( Event, EventFunction )
	self:F( Event )

	self.Events[#self.Events+1] = {}
	self.Events[#self.Events].Event = Event
	self.Events[#self.Events].EventFunction = EventFunction
	self.Events[#self.Events].EventEnabled = false

	return self
end

--- Returns the event dispatcher
-- @param #BASE self
-- @return Event#EVENT
function BASE:Event()

  return _EVENTDISPATCHER
end





--- Enable the event listeners for the class.
-- @param #BASE self
-- @return #BASE
function BASE:EnableEvents()
	self:F( #self.Events )

	for EventID, Event in pairs( self.Events ) do
		Event.Self = self
		Event.EventEnabled = true
	end
	self.Events.Handler = world.addEventHandler( self )

	return self
end


--- Disable the event listeners for the class.
-- @param #BASE self
-- @return #BASE
function BASE:DisableEvents()
	self:F()
  
	world.removeEventHandler( self )
	for EventID, Event in pairs( self.Events ) do
		Event.Self = nil
		Event.EventEnabled = false
	end

	return self
end


local BaseEventCodes = {
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

--- Creation of a Birth Event.
-- @param #BASE self
-- @param DCSTypes#Time EventTime The time stamp of the event.
-- @param DCSObject#Object Initiator The initiating object of the event.
-- @param #string IniUnitName The initiating unit name.
-- @param place
-- @param subplace
function BASE:CreateEventBirth( EventTime, Initiator, IniUnitName, place, subplace )
	self:F( { EventTime, Initiator, IniUnitName, place, subplace } )

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

--- Creation of a Crash Event.
-- @param #BASE self
-- @param DCSTypes#Time EventTime The time stamp of the event.
-- @param DCSObject#Object Initiator The initiating object of the event.
function BASE:CreateEventCrash( EventTime, Initiator )
	self:F( { EventTime, Initiator } )

	local Event = {
		id = world.event.S_EVENT_CRASH,
		time = EventTime,
		initiator = Initiator,
		}

	world.onEvent( Event )
end

-- TODO: Complete DCSTypes#Event structure.                       
--- The main event handling function... This function captures all events generated for the class.
-- @param #BASE self
-- @param DCSTypes#Event event
function BASE:onEvent(event)
  --self:F( { BaseEventCodes[event.id], event } )

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
						--self:T( { BaseEventCodes[event.id], event } )
						--EventObject.EventFunction( self, event )
					end
				end
			end
		end
	end
end

-- Trace section

-- Log a trace (only shown when trace is on)
-- TODO: Make trace function using variable parameters.

--- Set trace level
-- @param #BASE self
-- @param #number Level
function BASE:TraceLevel( Level )
  _TraceLevel = Level
  self:E( "Tracing level " .. Level )
end

--- Set tracing for a class
-- @param #BASE self
-- @param #string Class
function BASE:TraceClass( Class )
  _TraceClass[Class] = true
  _TraceClassMethod[Class] = {}
  self:E( "Tracing class " .. Class )
end

--- Set tracing for a specific method of  class
-- @param #BASE self
-- @param #string Class
-- @param #string Method
function BASE:TraceClassMethod( Class, Method )
  if not _TraceClassMethod[Class] then
    _TraceClassMethod[Class] = {}
    _TraceClassMethod[Class].Method = {}
  end
  _TraceClassMethod[Class].Method[Method] = true
  self:E( "Tracing method " .. Method .. " of class " .. Class )
end

--- Trace a function call. Must be at the beginning of the function logic.
-- @param #BASE self
-- @param Arguments A #table or any field.
function BASE:F( Arguments )

  if _TraceOn and ( _TraceClass[self.ClassName] or _TraceClassMethod[self.ClassName] ) then

    local DebugInfoCurrent = debug.getinfo( 2, "nl" )
    local DebugInfoFrom = debug.getinfo( 3, "l" )
    
    local Function = "function"
    if DebugInfoCurrent.name then
      Function = DebugInfoCurrent.name
    end
    
    if _TraceClass[self.ClassName] or _TraceClassMethod[self.ClassName].Method[Function] then
      local LineCurrent = DebugInfoCurrent.currentline
      local LineFrom = 0
      if DebugInfoFrom then
        LineFrom = DebugInfoFrom.currentline
      end
      env.info( string.format( "%6d(%6d)/%1s:%20s%05d.%s(%s)" , LineCurrent, LineFrom, "F", self.ClassName, self.ClassID, Function, routines.utils.oneLineSerialize( Arguments ) ) )
    end
  end
end

--- Trace a function call level 2. Must be at the beginning of the function logic.
-- @param #BASE self
-- @param Arguments A #table or any field.
function BASE:F2( Arguments )

  if _TraceLevel >= 2 then
    self:F( Arguments )
  end
  
end

--- Trace a function call level 3. Must be at the beginning of the function logic.
-- @param #BASE self
-- @param Arguments A #table or any field.
function BASE:F3( Arguments )

  if _TraceLevel >= 3 then
    self:F( Arguments )
  end
  
end

--- Trace a function logic. Can be anywhere within the function logic.
-- @param #BASE self
-- @param Arguments A #table or any field.
function BASE:T( Arguments )

	if _TraceOn and ( _TraceClass[self.ClassName] or _TraceClassMethod[self.ClassName] ) then

		local DebugInfoCurrent = debug.getinfo( 2, "nl" )
		local DebugInfoFrom = debug.getinfo( 3, "l" )
		
		local Function = "function"
		if DebugInfoCurrent.name then
			Function = DebugInfoCurrent.name
		end

    if _TraceClass[self.ClassName] or _TraceClassMethod[self.ClassName].Method[Function] then
  		local LineCurrent = DebugInfoCurrent.currentline
  		local LineFrom = 0
  		if DebugInfoFrom then
  		  LineFrom = DebugInfoFrom.currentline
  	  end
  		env.info( string.format( "%6d(%6d)/%1s:%20s%05d.%s" , LineCurrent, LineFrom, "T", self.ClassName, self.ClassID, routines.utils.oneLineSerialize( Arguments ) ) )
    end
	end
end

--- Trace a function logic level 2. Can be anywhere within the function logic.
-- @param #BASE self
-- @param Arguments A #table or any field.
function BASE:T2( Arguments )

  if _TraceLevel >= 2 then
    self:T( Arguments )
  end
  
end

--- Trace a function logic level 3. Can be anywhere within the function logic.
-- @param #BASE self
-- @param Arguments A #table or any field.
function BASE:T3( Arguments )

  if _TraceLevel >= 3 then
    self:T( Arguments )
  end
  
end

--- Log an exception which will be traced always. Can be anywhere within the function logic.
-- @param #BASE self
-- @param Arguments A #table or any field.
function BASE:E( Arguments )

	local DebugInfoCurrent = debug.getinfo( 2, "nl" )
	local DebugInfoFrom = debug.getinfo( 3, "l" )
	
	local Function = "function"
	if DebugInfoCurrent.name then
		Function = DebugInfoCurrent.name
	end

	local LineCurrent = DebugInfoCurrent.currentline
	local LineFrom = DebugInfoFrom.currentline

	env.info( string.format( "%6d(%6d)/%1s:%20s%05d.%s(%s)" , LineCurrent, LineFrom, "E", self.ClassName, self.ClassID, Function, routines.utils.oneLineSerialize( Arguments ) ) )
end



--- The EVENT class models an efficient event handling process between other classes and its units, weapons.
-- @module Event
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )

--- The EVENT structure
-- @type EVENT
-- @field #EVENT.Events Events
EVENT = {
  ClassName = "EVENT",
  ClassID = 0,
}

local _EVENTCODES = {
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

--- The Event structure
-- @type EVENTDATA
-- @field id
-- @field initiator
-- @field target
-- @field weapon
-- @field IniDCSUnit
-- @field IniDCSUnitName
-- @field IniDCSGroup
-- @field IniDCSGroupName
-- @field TgtDCSUnit
-- @field TgtDCSUnitName
-- @field TgtDCSGroup
-- @field TgtDCSGroupName
-- @field Weapon
-- @field WeaponName
-- @field WeaponTgtDCSUnit

--- The Events structure
-- @type EVENT.Events
-- @field #number IniUnit

function EVENT:New()
  local self = BASE:Inherit( self, BASE:New() )
  self:F()
  self.EventHandler = world.addEventHandler( self )
  return self
end

function EVENT:EventText( EventID )

  local EventText = _EVENTCODES[EventID]
  
  return EventText
end


--- Initializes the Events structure for the event
-- @param #EVENT self
-- @param DCSWorld#world.event EventID
-- @param #string EventClass
-- @return #EVENT.Events
function EVENT:Init( EventID, EventClass )
  self:F3( { _EVENTCODES[EventID], EventClass } )
  if not self.Events[EventID] then
    self.Events[EventID] = {}
  end
  if not self.Events[EventID][EventClass] then
     self.Events[EventID][EventClass] = {}
  end
  return self.Events[EventID][EventClass]
end


--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @param #function OnEventFunction
-- @return #EVENT
function EVENT:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, OnEventFunction )
  self:F2( EventTemplate.name )

  for EventUnitID, EventUnit in pairs( EventTemplate.units ) do
    OnEventFunction( self, EventUnit.name, EventFunction, EventSelf )
  end
  return self
end

--- Set a new listener for an S_EVENT_X event independent from a unit or a weapon.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @param EventID
-- @return #EVENT
function EVENT:OnEventGeneric( EventFunction, EventSelf, EventID )
  self:F2( { EventID } )

  local Event = self:Init( EventID, EventSelf:GetClassNameAndID() )
  Event.EventFunction = EventFunction
  Event.EventSelf = EventSelf
  return self
end


--- Set a new listener for an S_EVENT_X event
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @param EventID
-- @return #EVENT
function EVENT:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, EventID )
  self:F2( EventDCSUnitName )

  local Event = self:Init( EventID, EventSelf:GetClassNameAndID() )
  if not Event.IniUnit then
    Event.IniUnit = {}
  end
  Event.IniUnit[EventDCSUnitName] = {}
  Event.IniUnit[EventDCSUnitName].EventFunction = EventFunction
  Event.IniUnit[EventDCSUnitName].EventSelf = EventSelf
  return self
end


--- Create an OnBirth event handler for a group
-- @param #EVENT self
-- @param Group#GROUP EventGroup
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnBirthForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate.name )

  self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnBirthForUnit )
  
  return self
end

--- Set a new listener for an S_EVENT_BIRTH event, and registers the unit born.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf
-- @return #EVENT
function EVENT:OnBirth( EventFunction, EventSelf )
  self:F()
  
  self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_BIRTH )
  
  return self
end

--- Set a new listener for an S_EVENT_BIRTH event.
-- @param #EVENT self
-- @param #string EventDCSUnitName The id of the unit for the event to be handled.
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf
-- @return #EVENT
function EVENT:OnBirthForUnit( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )
  
  self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_BIRTH )
  
  return self
end

--- Create an OnCrash event handler for a group
-- @param #EVENT self
-- @param Group#GROUP EventGroup
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnCrashForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate.name )

  self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnCrashForUnit )

  return self
end

--- Set a new listener for an S_EVENT_CRASH event.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf
-- @return #EVENT
function EVENT:OnCrash( EventFunction, EventSelf )
  self:F()
  
  self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_CRASH )
  
  return self 
end

--- Set a new listener for an S_EVENT_CRASH event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnCrashForUnit( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )
  
  self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_CRASH )

  return self
end

--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param Group#GROUP EventGroup
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnDeadForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate.name )
  
  self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnDeadForUnit )

  return self
end

--- Set a new listener for an S_EVENT_DEAD event.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf
-- @return #EVENT
function EVENT:OnDead( EventFunction, EventSelf )
  self:F()
  
  self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_DEAD )
  
  return self
end


--- Set a new listener for an S_EVENT_DEAD event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnDeadForUnit( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_DEAD )
  
  return self
end

--- Set a new listener for an S_EVENT_PILOT_DEAD event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnPilotDeadForUnit( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_PILOT_DEAD )

  return self
end

--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnLandForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate.name )

  self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnLandForUnit )
  
  return self
end

--- Set a new listener for an S_EVENT_LAND event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnLandForUnit( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_LAND )

  return self
end

--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnTakeOffForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate.name )

  self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnTakeOffForUnit )

  return self
end

--- Set a new listener for an S_EVENT_TAKEOFF event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnTakeOffForUnit( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_TAKEOFF )

  return self
end

--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnEngineShutDownForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate.name )

  self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnEngineShutDownForUnit )
  
  return self
end

--- Set a new listener for an S_EVENT_ENGINE_SHUTDOWN event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnEngineShutDownForUnit( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_ENGINE_SHUTDOWN )
  
  return self
end

--- Set a new listener for an S_EVENT_ENGINE_STARTUP event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnEngineStartUpForUnit( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_ENGINE_STARTUP )
  
  return self
end

--- Set a new listener for an S_EVENT_SHOT event.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnShot( EventFunction, EventSelf )
  self:F()

  self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_SHOT )
  
  return self
end

--- Set a new listener for an S_EVENT_SHOT event for a unit.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnShotForUnit( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_SHOT )
  
  return self
end

--- Set a new listener for an S_EVENT_HIT event.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnHit( EventFunction, EventSelf )
  self:F()

  self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_HIT )
  
  return self
end

--- Set a new listener for an S_EVENT_HIT event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnHitForUnit( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_HIT )
  
  return self
end

--- Set a new listener for an S_EVENT_PLAYER_ENTER_UNIT event.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnPlayerEnterUnit( EventFunction, EventSelf )
  self:F()

  self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_PLAYER_ENTER_UNIT )
  
  return self
end

--- Set a new listener for an S_EVENT_PLAYER_LEAVE_UNIT event.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnPlayerLeaveUnit( EventFunction, EventSelf )
  self:F()

  self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_PLAYER_LEAVE_UNIT )
  
  return self
end



function EVENT:onEvent( Event )
  self:F( { _EVENTCODES[Event.id], Event } )

  if self and self.Events and self.Events[Event.id] then
    if Event.initiator and Event.initiator:getCategory() == Object.Category.UNIT then
      Event.IniDCSUnit = Event.initiator
      Event.IniDCSGroup = Event.IniDCSUnit:getGroup()
      Event.IniDCSUnitName = Event.IniDCSUnit:getName()
      Event.IniDCSGroupName = ""
      if Event.IniDCSGroup and Event.IniDCSGroup:isExist() then
        Event.IniDCSGroupName = Event.IniDCSGroup:getName()
      end
    end
    if Event.target then
      if Event.target and Event.target:getCategory() == Object.Category.UNIT then
        Event.TgtDCSUnit = Event.target
        Event.TgtDCSGroup = Event.TgtDCSUnit:getGroup()
        Event.TgtDCSUnitName = Event.TgtDCSUnit:getName()
        Event.TgtDCSGroupName = ""
        if Event.TgtDCSGroup and Event.TgtDCSGroup:isExist() then
          Event.TgtDCSGroupName = Event.TgtDCSGroup:getName()
        end
      end
    end
    if Event.weapon then
      Event.Weapon = Event.weapon
      Event.WeaponName = Event.Weapon:getTypeName()
      --Event.WeaponTgtDCSUnit = Event.Weapon:getTarget()
    end
    self:E( { _EVENTCODES[Event.id], Event } )
    for ClassName, EventData in pairs( self.Events[Event.id] ) do
      if Event.IniDCSUnitName and EventData.IniUnit and EventData.IniUnit[Event.IniDCSUnitName] then 
        self:T2( { "Calling event function for class ", ClassName, " unit ", Event.IniDCSUnitName } )
        EventData.IniUnit[Event.IniDCSUnitName].EventFunction( EventData.IniUnit[Event.IniDCSUnitName].EventSelf, Event )
      else
        if Event.IniDCSUnit and not EventData.IniUnit then
          self:T2( { "Calling event function for class ", ClassName } )
          EventData.EventFunction( EventData.EventSelf, Event )
        end
      end
    end
  end
end

--- Encapsulation of DCS World Menu system in a set of MENU classes.
-- @module Menu

Include.File( "Routines" )
Include.File( "Base" )

--- The MENU class
-- @type MENU
-- @extends Base#BASE
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

--- The COMMANDMENU class
-- @type COMMANDMENU
-- @extends Menu#MENU
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

--- The SUBMENU class
-- @type SUBMENU
-- @extends Menu#MENU
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

-- This local variable is used to cache the menus registered under clients.
-- Menus don't dissapear when clients are destroyed and restarted.
-- So every menu for a client created must be tracked so that program logic accidentally does not create
-- the same menus twice during initialization logic.
-- These menu classes are handling this logic with this variable.
local _MENUCLIENTS = {}

--- The MENU_CLIENT class
-- @type MENU_CLIENT
-- @extends Menu#MENU
MENU_CLIENT = {
  ClassName = "MENU_CLIENT"
}

--- Creates a new menu item for a group
-- @param self
-- @param Client#CLIENT MenuClient The Client owning the menu.
-- @param #string MenuText The text for the menu.
-- @param #table ParentMenu The parent menu.
-- @return #MENU_CLIENT self
function MENU_CLIENT:New( MenuClient, MenuText, ParentMenu )

	-- Arrange meta tables
	local MenuParentPath = {}
	if ParentMenu ~= nil then
	  MenuParentPath = ParentMenu.MenuPath
	end

	local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )
	self:F( { MenuClient, MenuText, ParentMenu } )

  self.MenuClient = MenuClient
  self.MenuClientGroupID = MenuClient:GetClientGroupID()
  self.MenuParentPath = MenuParentPath
  self.MenuText = MenuText
  self.ParentMenu = ParentMenu
  
  self.Menus = {}

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  self:T( { MenuClient:GetClientGroupName(), MenuPath[table.concat(MenuParentPath)], MenuParentPath, MenuText } )

  local MenuPathID = table.concat(MenuParentPath) .. "/" .. MenuText
  if MenuPath[MenuPathID] then
    missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), MenuPath[MenuPathID] )
  end

	self.MenuPath = missionCommands.addSubMenuForGroup( self.MenuClient:GetClientGroupID(), MenuText, MenuParentPath )
	MenuPath[MenuPathID] = self.MenuPath

  self:T( { MenuClient:GetClientGroupName(), self.MenuPath } )

  if ParentMenu and ParentMenu.Menus then
    ParentMenu.Menus[self.MenuPath] = self
  end
	return self
end

--- Removes the sub menus recursively of this MENU_CLIENT.
-- @param #MENU_CLIENT self
-- @return #MENU_CLIENT self
function MENU_CLIENT:RemoveSubMenus()
  self:F( self.MenuPath )

  for MenuID, Menu in pairs( self.Menus ) do
    Menu:Remove()
  end

end

--- Removes the sub menus recursively of this MENU_CLIENT.
-- @param #MENU_CLIENT self
-- @return #MENU_CLIENT self
function MENU_CLIENT:Remove()
  self:F( self.MenuPath )

  self:RemoveSubMenus()

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  if MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] then
    MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] = nil
  end
  
  missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), self.MenuPath )
  self.ParentMenu.Menus[self.MenuPath] = nil
  return nil
end


--- The MENU_CLIENT_COMMAND class
-- @type MENU_CLIENT_COMMAND
-- @extends Menu#MENU
MENU_CLIENT_COMMAND = {
  ClassName = "MENU_CLIENT_COMMAND"
}

--- Creates a new radio command item for a group
-- @param self
-- @param Client#CLIENT MenuClient The Client owning the menu.
-- @param MenuText The text for the menu.
-- @param ParentMenu The parent menu.
-- @param CommandMenuFunction A function that is called when the menu key is pressed.
-- @param CommandMenuArgument An argument for the function.
-- @return Menu#MENU_CLIENT_COMMAND self
function MENU_CLIENT_COMMAND:New( MenuClient, MenuText, ParentMenu, CommandMenuFunction, CommandMenuArgument )

	-- Arrange meta tables
	
	local MenuParentPath = {}
	if ParentMenu ~= nil then
		MenuParentPath = ParentMenu.MenuPath
	end

	local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )
	
  self.MenuClient = MenuClient
  self.MenuClientGroupID = MenuClient:GetClientGroupID()
  self.MenuParentPath = MenuParentPath
  self.MenuText = MenuText
  self.ParentMenu = ParentMenu

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  self:T( { MenuClient:GetClientGroupName(), MenuPath[table.concat(MenuParentPath)], MenuParentPath, MenuText, CommandMenuFunction, CommandMenuArgument } )

  local MenuPathID = table.concat(MenuParentPath) .. "/" .. MenuText
  if MenuPath[MenuPathID] then
    missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), MenuPath[MenuPathID] )
  end
  
	self.MenuPath = missionCommands.addCommandForGroup( self.MenuClient:GetClientGroupID(), MenuText, MenuParentPath, CommandMenuFunction, CommandMenuArgument )
  MenuPath[MenuPathID] = self.MenuPath
 
	self.CommandMenuFunction = CommandMenuFunction
	self.CommandMenuArgument = CommandMenuArgument
	
	ParentMenu.Menus[self.MenuPath] = self
	
	return self
end

function MENU_CLIENT_COMMAND:Remove()
  self:F( self.MenuPath )

  if not _MENUCLIENTS[self.MenuClientGroupID] then
    _MENUCLIENTS[self.MenuClientGroupID] = {}
  end
  
  local MenuPath = _MENUCLIENTS[self.MenuClientGroupID]

  if MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] then
    MenuPath[table.concat(self.MenuParentPath) .. "/" .. self.MenuText] = nil
  end
  
  missionCommands.removeItemForGroup( self.MenuClient:GetClientGroupID(), self.MenuPath )
  self.ParentMenu.Menus[self.MenuPath] = nil
  return nil
end


--- The MENU_COALITION class
-- @type MENU_COALITION
-- @extends Menu#MENU
MENU_COALITION = {
  ClassName = "MENU_COALITION"
}

--- Creates a new coalition menu item
-- @param #MENU_COALITION self
-- @param DCSCoalition#coalition.side MenuCoalition The coalition owning the menu.
-- @param #string MenuText The text for the menu.
-- @param #table ParentMenu The parent menu.
-- @return #MENU_COALITION self
function MENU_COALITION:New( MenuCoalition, MenuText, ParentMenu )

  -- Arrange meta tables
  local MenuParentPath = {}
  if ParentMenu ~= nil then
    MenuParentPath = ParentMenu.MenuPath
  end

  local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )
  self:F( { MenuCoalition, MenuText, ParentMenu } )

  self.MenuCoalition = MenuCoalition
  self.MenuParentPath = MenuParentPath
  self.MenuText = MenuText
  self.ParentMenu = ParentMenu
  
  self.Menus = {}

  self:T( { MenuParentPath, MenuText } )

  self.MenuPath = missionCommands.addSubMenuForCoalition( self.MenuCoalition, MenuText, MenuParentPath )

  self:T( { self.MenuPath } )

  if ParentMenu and ParentMenu.Menus then
    ParentMenu.Menus[self.MenuPath] = self
  end
  return self
end

--- Removes the sub menus recursively of this MENU_COALITION.
-- @param #MENU_COALITION self
-- @return #MENU_COALITION self
function MENU_COALITION:RemoveSubMenus()
  self:F( self.MenuPath )

  for MenuID, Menu in pairs( self.Menus ) do
    Menu:Remove()
  end

end

--- Removes the sub menus recursively of this MENU_COALITION.
-- @param #MENU_COALITION self
-- @return #MENU_COALITION self
function MENU_COALITION:Remove()
  self:F( self.MenuPath )

  self:RemoveSubMenus()
  missionCommands.removeItemForCoalition( self.MenuCoalition, self.MenuPath )
  self.ParentMenu.Menus[self.MenuPath] = nil

  return nil
end


--- The MENU_COALITION_COMMAND class
-- @type MENU_COALITION_COMMAND
-- @extends Menu#MENU
MENU_COALITION_COMMAND = {
  ClassName = "MENU_COALITION_COMMAND"
}

--- Creates a new radio command item for a group
-- @param #MENU_COALITION_COMMAND self
-- @param DCSCoalition#coalition.side MenuCoalition The coalition owning the menu.
-- @param MenuText The text for the menu.
-- @param ParentMenu The parent menu.
-- @param CommandMenuFunction A function that is called when the menu key is pressed.
-- @param CommandMenuArgument An argument for the function.
-- @return #MENU_COALITION_COMMAND self
function MENU_COALITION_COMMAND:New( MenuCoalition, MenuText, ParentMenu, CommandMenuFunction, CommandMenuArgument )

  -- Arrange meta tables
  
  local MenuParentPath = {}
  if ParentMenu ~= nil then
    MenuParentPath = ParentMenu.MenuPath
  end

  local self = BASE:Inherit( self, MENU:New( MenuText, MenuParentPath ) )
  
  self.MenuCoalition = MenuCoalition
  self.MenuParentPath = MenuParentPath
  self.MenuText = MenuText
  self.ParentMenu = ParentMenu

  self:T( { MenuParentPath, MenuText, CommandMenuFunction, CommandMenuArgument } )

  self.MenuPath = missionCommands.addCommandForCoalition( self.MenuCoalition, MenuText, MenuParentPath, CommandMenuFunction, CommandMenuArgument )
 
  self.CommandMenuFunction = CommandMenuFunction
  self.CommandMenuArgument = CommandMenuArgument
  
  ParentMenu.Menus[self.MenuPath] = self
  
  return self
end

--- Removes a radio command item for a coalition
-- @param #MENU_COALITION_COMMAND self
-- @return #MENU_COALITION_COMMAND self
function MENU_COALITION_COMMAND:Remove()
  self:F( self.MenuPath )

  missionCommands.removeItemForCoalition( self.MenuCoalition, self.MenuPath )
  self.ParentMenu.Menus[self.MenuPath] = nil
  return nil
end
--- A GROUP class abstraction of a DCSGroup class. 
-- The GROUP class will take an abstraction of the DCSGroup class, providing more methods that can be done with a GROUP.
-- @module Group

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )
Include.File( "Unit" )

--- The GROUP class
-- @type GROUP
-- @extends Base#BASE
-- @field DCSGroup#Group DCSGroup The DCS group class.
-- @field #string GroupName The name of the group.
-- @field #number GroupID the ID of the group.
-- @field #table Controller The controller of the group.
GROUP = {
	ClassName = "GROUP",
	GroupName = "",
	GroupID = 0,
	Controller = nil,
	DCSGroup = nil,
	WayPointFunctions = {},
	}
	
--- A DCSGroup
-- @type DCSGroup
-- @field id_ The ID of the group in DCS

--- The GROUPS structure contains references to all the created GROUP instances.
local GROUPS = {}
	
--- Create a new GROUP from a DCSGroup
-- @param #GROUP self
-- @param DCSGroup#Group DCSGroup The DCS Group
-- @return #GROUP self
function GROUP:New( DCSGroup )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( DCSGroup )

	self.DCSGroup = DCSGroup
	if self.DCSGroup and self.DCSGroup:isExist() then
  	self.GroupName = DCSGroup:getName()
  	self.GroupID = DCSGroup:getID()
  	self.Controller = DCSGroup:getController()
  else
    self:E( { "DCSGroup is nil or does not exist, cannot initialize GROUP!", self.DCSGroup } )
  end
  
  GROUPS[self.GroupID] = self

	return self
end

--- Create a new GROUP from an existing group name.
-- @param #GROUP self
-- @param GroupName The name of the DCS Group.
-- @return #GROUP self
function GROUP:NewFromName( GroupName )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( GroupName )

	self.DCSGroup = Group.getByName( GroupName )
	if self.DCSGroup then
		self.GroupName = self.DCSGroup:getName()
		self.GroupID = self.DCSGroup:getID()
    self.Controller = self.DCSGroup:getController()
	end

  GROUPS[self.GroupID] = self

	return self
end

--- Create a new GROUP from an existing DCSUnit in the mission.
-- @param #GROUP self
-- @param DCSUnit The DCSUnit.
-- @return #GROUP self
function GROUP:NewFromDCSUnit( DCSUnit )
  local self = BASE:Inherit( self, BASE:New() )
	self:F( DCSUnit )

  self.DCSGroup = DCSUnit:getGroup()
  if self.DCSGroup then
    self.GroupName = self.DCSGroup:getName()
    self.GroupID = self.DCSGroup:getID()
    self.Controller = self.DCSGroup:getController()
  end

  GROUPS[self.GroupID] = self

  return self
end

--- Returns the name of the Group.
-- @param #GROUP self
-- @return #string GroupName
function GROUP:GetName()

  local GroupName = self.DCSGroup:getName()

  return GroupName
end



--- Retrieve the group mission and allow to place function hooks within the mission waypoint plan.
-- Use the method @{Group#GROUP:WayPointFunction} to define the hook functions for specific waypoints.
-- Use the method @{Group@GROUP:WayPointExecute) to start the execution of the new mission plan.
-- Note that when WayPointInitialize is called, the Mission of the group is RESTARTED!
-- @param #GROUP self
-- @param #number WayPoint
-- @return #GROUP
function GROUP:WayPointInitialize()

  self.WayPoints = self:GetTaskRoute()
  
  return self
end


--- Registers a waypoint function that will be executed when the group moves over the WayPoint.
-- @param #GROUP self
-- @param #number WayPoint The waypoint number. Note that the start waypoint on the route is WayPoint 1!
-- @param #number WayPointIndex When defining multiple WayPoint functions for one WayPoint, use WayPointIndex to set the sequence of actions.
-- @param #function WayPointFunction The waypoint function to be called when the group moves over the waypoint. The waypoint function takes variable parameters.
-- @return #GROUP
function GROUP:WayPointFunction( WayPoint, WayPointIndex, WayPointFunction, ... )
  self:F( { WayPoint, WayPointIndex, WayPointFunction } )
  
  table.insert( self.WayPoints[WayPoint].task.params.tasks, WayPointIndex )
  self.WayPoints[WayPoint].task.params.tasks[WayPointIndex] = self:TaskFunction( WayPoint, WayPointIndex, WayPointFunction, arg )
  return self
end


function GROUP:TaskFunction( WayPoint, WayPointIndex, FunctionString, FunctionArguments )

  local DCSTask
  
  local DCSScript = {}
  DCSScript[#DCSScript+1] = "local MissionGroup = GROUP.FindGroup( ... ) "

  if FunctionArguments.n > 0 then
    DCSScript[#DCSScript+1] = FunctionString .. "( MissionGroup, " .. table.concat( FunctionArguments, "," ) .. ")"
  else
    DCSScript[#DCSScript+1] = FunctionString .. "( MissionGroup )"
  end  
  
  DCSTask = self:TaskWrappedAction( 
    self:CommandDoScript(
      table.concat( DCSScript )
    ), WayPointIndex
  )
  
  self:T( DCSTask )
  
  return DCSTask

end



--- Executes the WayPoint plan.
-- The function gets a WayPoint parameter, that you can use to restart the mission at a specific WayPoint.
-- Note that when the WayPoint parameter is used, the new start mission waypoint of the group will be 1!
-- @param #GROUP self
-- @param #number WayPoint The WayPoint from where to execute the mission.
-- @param #WaitTime The amount seconds to wait before initiating the mission.
-- @return #GROUP
function GROUP:WayPointExecute( WayPoint, WaitTime )

  if not WayPoint then
    WayPoint = 1
  end
  
  -- When starting the mission from a certain point, the TaskPoints need to be deleted before the given WayPoint.
  for TaskPointID = 1, WayPoint - 1 do
    table.remove( self.WayPoints, 1 )
  end

  self:T( self.WayPoints )
  
  self:SetTask( self:TaskRoute( self.WayPoints ), WaitTime )

  return self
end



--- Gets the DCSGroup of the GROUP.
-- @param #GROUP self
-- @return DCSGroup#Group The DCSGroup.
function GROUP:GetDCSGroup()
	self:F( { self.GroupName } )
	self.DCSGroup = Group.getByName( self.GroupName )
	return self.DCSGroup
end

--- Gets the DCS Unit of the GROUP.
-- @param #GROUP self
-- @param #number UnitNumber The unit index to be returned from the GROUP.
-- @return #Unit The DCS Unit.
function GROUP:GetDCSUnit( UnitNumber )
	self:F( { self.GroupName, UnitNumber } )
	return self.DCSGroup:getUnit( UnitNumber )

end

--- Gets the DCSUnits of the GROUP.
-- @param #GROUP self
-- @return #table The DCSUnits.
function GROUP:GetDCSUnits()
  self:F( { self.GroupName } )
  return self.DCSGroup:getUnits()

end

--- Activates a GROUP.
-- @param #GROUP self
function GROUP:Activate()
	self:F( { self.GroupName } )
	trigger.action.activateGroup( self:GetDCSGroup() )
	return self:GetDCSGroup()
end

--- Gets the ID of the GROUP.
-- @param #GROUP self
-- @return #number The ID of the GROUP.
function GROUP:GetID()
	self:F( self.GroupName )
  
  return self.GroupID
end

--- Gets the name of the GROUP.
-- @param #GROUP self
-- @return #string The name of the GROUP.
function GROUP:GetName()
	self:F( self.GroupName )
	
	return self.GroupName
end

--- Gets the type name of the group.
-- @param #GROUP self
-- @return #string The type name of the group.
function GROUP:GetTypeName()
  self:F( self.GroupName )
  
  return self.DCSGroup:getUnit(1):getTypeName()
end

--- Gets the callsign of the fist unit of the group.
-- @param #GROUP self
-- @return #string The callsign of the first unit of the group.
function GROUP:GetCallsign()
  self:F( self.GroupName )
  
  return self.DCSGroup:getUnit(1):getCallsign()
end

--- Gets the current Point of the GROUP in VEC3 format.
-- @return #Vec3 Current x,y and z position of the group.
function GROUP:GetPointVec2()
	self:F( self.GroupName )
	
	local GroupPoint = self:GetUnit(1):GetPointVec2()
	self:T( GroupPoint )
	return GroupPoint
end

--- Gets the current Point of the GROUP in VEC2 format.
-- @return #Vec2 Current x and y position of the group in the 2D plane.
function GROUP:GetPointVec2()
	self:F( self.GroupName )
  
  local GroupPoint = self:GetUnit(1):GetPointVec2()
  self:T( GroupPoint )
  return GroupPoint
end

--- Gets the current Point of the GROUP in VEC3 format.
-- @return #Vec3 Current Vec3 position of the group.
function GROUP:GetPositionVec3()
	self:F( self.GroupName )
  
  local GroupPoint = self:GetUnit(1):GetPositionVec3()
  self:T( GroupPoint )
  return GroupPoint
end

--- Destroy a GROUP
-- Note that this destroy method also raises a destroy event at run-time.
-- So all event listeners will catch the destroy event of this GROUP.
-- @param #GROUP self
function GROUP:Destroy()
	self:F( self.GroupName )
	
	for Index, UnitData in pairs( self.DCSGroup:getUnits() ) do
		self:CreateEventCrash( timer.getTime(), UnitData )
	end
	
	self.DCSGroup:destroy()
	self.DCSGroup = nil
end

--- Gets the DCS Unit.
-- @param #GROUP self
-- @param #number UnitNumber The number of the Unit to be returned.
-- @return Unit#UNIT The DCS Unit.
function GROUP:GetUnit( UnitNumber )
	self:F( { self.GroupName, UnitNumber } )
	return UNIT:New( self.DCSGroup:getUnit( UnitNumber ) )
end

--- Returns the category name of the group.
-- @param #GROUP self
-- @return #string Category name = Helicopter, Airplane, Ground Unit, Ship
function GROUP:GetCategoryName()
  self:F( self.GroupName )

  local CategoryNames = {
    [Group.Category.AIRPLANE] = "Airplane",
    [Group.Category.HELICOPTER] = "Helicopter",
    [Group.Category.GROUND] = "Ground Unit",
    [Group.Category.SHIP] = "Ship",  
  }
  
  return CategoryNames[self.DCSGroup:getCategory()]
end

-- Is Functions

--- Returns if the group is of an air category.
-- If the group is a helicopter or a plane, then this method will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean Air category evaluation result.
function GROUP:IsAir()
	self:F()
	
	local IsAirResult = self.DCSGroup:getCategory() == Group.Category.AIRPLANE or self.DCSGroup:getCategory() == Group.Category.HELICOPTER

	self:T( IsAirResult )
	return IsAirResult
end

--- Returns if the group is alive.
-- When the group exists at run-time, this method will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean Alive result.
function GROUP:IsAlive()
	self:F()
	
	local IsAliveResult = self.DCSGroup and self.DCSGroup:isExist()

	self:T( IsAliveResult )
	return IsAliveResult
end

--- Returns if the GROUP is a Helicopter.
-- @param #GROUP self
-- @return #boolean true if GROUP are Helicopters.
function GROUP:IsHelicopter()
  self:F2()
  
  local GroupCategory = self.DCSGroup:getCategory()
  self:T2( GroupCategory )
  
  return GroupCategory == Group.Category.HELICOPTER
end

--- Returns if the GROUP are AirPlanes.
-- @param #GROUP self
-- @return #boolean true if GROUP are AirPlanes.
function GROUP:IsAirPlane()
  self:F2()
  
  local GroupCategory = self.DCSGroup:getCategory()
  self:T2( GroupCategory )
  
  return GroupCategory == Group.Category.AIRPLANE
end

--- Returns if the GROUP are Ground troops.
-- @param #GROUP self
-- @return #boolean true if GROUP are Ground troops.
function GROUP:IsGround()
  self:F2()
  
  local GroupCategory = self.DCSGroup:getCategory()
  self:T2( GroupCategory )
  
  return GroupCategory == Group.Category.GROUND
end

--- Returns if the GROUP are Ships.
-- @param #GROUP self
-- @return #boolean true if GROUP are Ships.
function GROUP:IsShip()
  self:F2()
  
  local GroupCategory = self.DCSGroup:getCategory()
  self:T2( GroupCategory )
  
  return GroupCategory == Group.Category.SHIP
end

--- Returns if all units of the group are on the ground or landed.
-- If all units of this group are on the ground, this function will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean All units on the ground result.
function GROUP:AllOnGround()
	self:F()

	local AllOnGroundResult = true

	for Index, UnitData in pairs( self.DCSGroup:getUnits() ) do
		if UnitData:inAir() then
			AllOnGroundResult = false
		end
	end
	
	self:T( AllOnGroundResult )
	return AllOnGroundResult
end

--- Returns the current maximum velocity of the group.
-- Each unit within the group gets evaluated, and the maximum velocity (= the unit which is going the fastest) is returned.
-- @param #GROUP self
-- @return #number Maximum velocity found.
function GROUP:GetMaxVelocity()
	self:F()

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

--- Returns the current minimum height of the group.
-- Each unit within the group gets evaluated, and the minimum height (= the unit which is the lowest elevated) is returned.
-- @param #GROUP self
-- @return #number Minimum height found.
function GROUP:GetMinHeight()
	self:F()

end

--- Returns the current maximum height of the group.
-- Each unit within the group gets evaluated, and the maximum height (= the unit which is the highest elevated) is returned.
-- @param #GROUP self
-- @return #number Maximum height found.
function GROUP:GetMaxHeight()
	self:F()

end

-- Tasks

--- Popping current Task from the group.
-- @param #GROUP self
-- @return Group#GROUP self
function GROUP:PopCurrentTask()
	self:F()

  local Controller = self:_GetController()
  
  Controller:popTask()

  return self
end

--- Pushing Task on the queue from the group.
-- @param #GROUP self
-- @return Group#GROUP self
function GROUP:PushTask( DCSTask, WaitTime )
	self:F()

  local Controller = self:_GetController()
  
  -- When a group SPAWNs, it takes about a second to get the group in the simulator. Setting tasks to unspawned groups provides unexpected results.
  -- Therefore we schedule the functions to set the mission and options for the Group.
  -- Controller:pushTask( DCSTask )

  if not WaitTime then
    Controller:pushTask( DCSTask )
  else
    routines.scheduleFunction( Controller.pushTask, { Controller, DCSTask }, timer.getTime() + WaitTime )
  end

  return self
end

--- Clearing the Task Queue and Setting the Task on the queue from the group.
-- @param #GROUP self
-- @return Group#GROUP self
function GROUP:SetTask( DCSTask, WaitTime )
  self:F( { DCSTask } )

  local Controller = self:_GetController()
  
  -- When a group SPAWNs, it takes about a second to get the group in the simulator. Setting tasks to unspawned groups provides unexpected results.
  -- Therefore we schedule the functions to set the mission and options for the Group.
  -- Controller.setTask( Controller, DCSTask )

  if not WaitTime then
    WaitTime = 1
  end
  routines.scheduleFunction( Controller.setTask, { Controller, DCSTask }, timer.getTime() + WaitTime )
  
  return self
end


--- Return a condition section for a controlled task
-- @param #GROUP self
-- @param #Time time
-- @param #string userFlag 
-- @param #boolean userFlagValue 
-- @param #string condition
-- @param #Time duration 
-- @param #number lastWayPoint 
-- return DCSTask#Task
function GROUP:TaskCondition( time, userFlag, userFlagValue, condition, duration, lastWayPoint )
	self:F( { time, userFlag, userFlagValue, condition, duration, lastWayPoint } )
  
  local DCSStopCondition = {}
  DCSStopCondition.time = time
  DCSStopCondition.userFlag = userFlag
  DCSStopCondition.userFlagValue = userFlagValue
  DCSStopCondition.condition = condition
  DCSStopCondition.duration = duration
  DCSStopCondition.lastWayPoint = lastWayPoint
  
  self:T( { DCSStopCondition } )
  return DCSStopCondition 
end

--- Return a Controlled Task taking a Task and a TaskCondition
-- @param #GROUP self
-- @param DCSTask#Task DCSTask
-- @param #DCSStopCondition DCSStopCondition
-- @return DCSTask#Task
function GROUP:TaskControlled( DCSTask, DCSStopCondition )
	self:F( { DCSTask, DCSStopCondition } )

  local DCSTaskControlled
  
  DCSTaskControlled = { 
    id = 'ControlledTask', 
    params = { 
      task = DCSTask, 
      stopCondition = DCSStopCondition 
    } 
  }
  
  self:T( { DCSTaskControlled } )
  return DCSTaskControlled
end

--- Return a Combo Task taking an array of Tasks
-- @param #GROUP self
-- @param #list<DCSTask#Task> DCSTasks
-- @return DCSTask#Task
function GROUP:TaskCombo( DCSTasks )
  self:F( { DCSTasks } )

  local DCSTaskCombo
  
  DCSTaskCombo = { 
    id = 'ComboTask', 
    params = { 
      tasks = DCSTasks
    } 
  }
  
  self:T( { DCSTaskCombo } )
  return DCSTaskCombo
end

--- Return a WrappedAction Task taking a Command 
-- @param #GROUP self
-- @param DCSCommand#Command DCSCommand
-- @return DCSTask#Task
function GROUP:TaskWrappedAction( DCSCommand, Index )
  self:F( { DCSCommand } )

  local DCSTaskWrappedAction
  
  DCSTaskWrappedAction = { 
    id = "WrappedAction",
    enabled = true,
    number = Index,
    auto = false,
    params = {
      action = DCSCommand,
    },
  }

  self:T( { DCSTaskWrappedAction } )
  return DCSTaskWrappedAction
end

--- Executes a command action
-- @param #GROUP self
-- @param DCSCommand#Command DCSCommand
-- @return #GROUP self
function GROUP:SetCommand( DCSCommand )
  self:F( DCSCommand )
  
  local Controller = self:_GetController()
  
  Controller:setCommand( DCSCommand )

  return self
end

--- Perform a switch waypoint command
-- @param #GROUP self
-- @param #number FromWayPoint
-- @param #number ToWayPoint
-- @return DCSTask#Task
function GROUP:CommandSwitchWayPoint( FromWayPoint, ToWayPoint, Index )
  self:F( { FromWayPoint, ToWayPoint, Index } )
  
  local CommandSwitchWayPoint = {
    id = 'SwitchWaypoint', 
    params = { 
      fromWaypointIndex = FromWayPoint,  
      goToWaypointIndex = ToWayPoint, 
    },
  }
  
  self:T( { CommandSwitchWayPoint } )
  return CommandSwitchWayPoint
end
  

--- Orbit at a specified position at a specified alititude during a specified duration with a specified speed.
-- @param #GROUP self
-- @param #Vec2 Point The point to hold the position.
-- @param #number Altitude The altitude to hold the position.
-- @param #number Speed The speed flying when holding the position.
-- @return #GROUP self
function GROUP:TaskOrbitCircleAtVec2( Point, Altitude, Speed )
	self:F( { self.GroupName, Point, Altitude, Speed } )

--  pattern = enum AI.Task.OribtPattern,
--    point = Vec2,
--    point2 = Vec2,
--    speed = Distance,
--    altitude = Distance
    
  local LandHeight = land.getHeight( Point )
  
  self:T( { LandHeight } )

  local DCSTask = { id = 'Orbit', 
                   params = { pattern = AI.Task.OrbitPattern.CIRCLE, 
                              point = Point, 
                              speed = Speed, 
                              altitude = Altitude + LandHeight
                            } 
                 } 

  
--  local AITask = { id = 'ControlledTask', 
--                   params = { task = { id = 'Orbit', 
--                                       params = { pattern = AI.Task.OrbitPattern.CIRCLE, 
--                                                  point = Point, 
--                                                  speed = Speed, 
--                                                  altitude = Altitude + LandHeight
--                                                } 
--                                     }, 
--                              stopCondition = { duration = Duration 
--                                              } 
--                            } 
--                 }
--               )
               
  return DCSTask
end

--- Orbit at the current position of the first unit of the group at a specified alititude
-- @param #GROUP self
-- @param #number Altitude The altitude to hold the position.
-- @param #number Speed The speed flying when holding the position.
-- @return #GROUP self
function GROUP:TaskOrbitCircle( Altitude, Speed )
	self:F( { self.GroupName, Altitude, Speed } )

  local GroupPoint = self:GetPointVec2()
  
  return self:TaskOrbitCircleAtVec2( GroupPoint, Altitude, Speed )
end



--- Hold position at the current position of the first unit of the group.
-- @param #GROUP self
-- @param #number Duration The maximum duration in seconds to hold the position.
-- @return #GROUP self
function GROUP:TaskHoldPosition()
	self:F( { self.GroupName } )

  return self:TaskOrbitCircle( 30, 10 )
end


--- Land the group at a Vec2Point.
-- @param #GROUP self
-- @param #Vec2 Point The point where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @return #GROUP self
function GROUP:TaskLandAtVec2( Point, Duration )
	self:F( { self.GroupName, Point, Duration } )

  local DCSTask
  
	if Duration and Duration > 0 then
		DCSTask = { id = 'Land', params = { point = Point, durationFlag = true, duration = Duration } }
	else
		DCSTask = { id = 'Land', params = { point = Point, durationFlag = false } }
	end

  self:T( DCSTask )
	return DCSTask
end

--- Land the group at a @{Zone#ZONE).
-- @param #GROUP self
-- @param Zone#ZONE Zone The zone where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @return #GROUP self
function GROUP:TaskLandAtZone( Zone, Duration, RandomPoint )
  self:F( { self.GroupName, Zone, Duration, RandomPoint } )

  local Point
  if RandomPoint then
    Point = Zone:GetRandomPointVec2()
  else
    Point = Zone:GetPointVec2()
  end
  
  local DCSTask = self:TaskLandAtVec2( Point, Duration )

  self:T( DCSTask )
  return DCSTask
end


--- Attack the Unit.
-- @param #GROUP self
-- @param Unit#UNIT The unit.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskAttackUnit( AttackUnit )
	self:F( { self.GroupName, AttackUnit } )

--  AttackUnit = { 
--    id = 'AttackUnit', 
--    params = { 
--      unitId = Unit.ID, 
--      weaponType = number, 
--      expend = enum AI.Task.WeaponExpend
--      attackQty = number, 
--      direction = Azimuth, 
--      attackQtyLimit = boolean, 
--      groupAttack = boolean, 
--    } 
--  }
  
  local DCSTask    
  DCSTask = { id = 'AttackUnit', 
              params = { unitId = AttackUnit:GetID(), 
                         expend = AI.Task.WeaponExpend.TWO,
                         groupAttack = true, 
                       }, 
            }, 
  
  self:T( { DCSTask } )
  return DCSTask
end

--- Attack a Group.
-- @param #GROUP self
-- @param Group#GROUP AttackGroup The Group to be attacked.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskAttackGroup( AttackGroup )
  self:F( { self.GroupName, AttackGroup } )

--  AttackGroup = { 
--   id = 'AttackGroup', 
--   params = { 
--     groupId = Group.ID,
--     weaponType = number,
--     expend = enum AI.Task.WeaponExpend,
--     attackQty = number,
--     directionEnabled = boolean,
--     direction = Azimuth,
--     altitudeEnabled = boolean,
--     altitude = Distance,
--     attackQtyLimit = boolean,
--   } 
-- }  

  local DCSTask    
  DCSTask = { id = 'AttackGroup', 
              params = { groupId = AttackGroup:GetID(), 
                         expend = AI.Task.WeaponExpend.TWO,
                       }, 
            }, 
  
  self:T( { DCSTask } )
  return DCSTask
end

--- Fires at a VEC2 point.
-- @param #GROUP self
-- @param DCSTypes#Vec2 The point to fire at.
-- @param DCSTypes#Distance Radius The radius of the zone to deploy the fire at.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskFireAtPoint( PointVec2, Radius )
  self:F( { self.GroupName, PointVec2, Radius } )

-- FireAtPoint = { 
--   id = 'FireAtPoint', 
--   params = { 
--     point = Vec2,
--     radius = Distance, 
--   } 
-- }
   
  local DCSTask    
  DCSTask = { id = 'FireAtPoint', 
              params = { point = PointVec2, 
                         radius = Radius, 
                       } 
            } 
  
  self:T( { DCSTask } )
  return DCSTask
end



--- Move the group to a Vec2 Point, wait for a defined duration and embark a group.
-- @param #GROUP self
-- @param #Vec2 Point The point where to wait.
-- @param #number Duration The duration in seconds to wait.
-- @param #GROUP EmbarkingGroup The group to be embarked.
-- @return DCSTask#Task The DCS task structure
function GROUP:TaskEmbarkingAtVec2( Point, Duration, EmbarkingGroup )
	self:F( { self.GroupName, Point, Duration, EmbarkingGroup.DCSGroup } )

	local DCSTask 
	DCSTask =  { id = 'Embarking', 
	             params = { x = Point.x, 
    	                    y = Point.y, 
    		  							  duration = Duration, 
    			  						  groupsForEmbarking = { EmbarkingGroup.GroupID },
    				  					  durationFlag = true,
    					  				  distributionFlag = false,
    						  			  distribution = {},
    						  			} 
    				 }
	
	self:T( { DCSTask } )
	return DCSTask
end

--- Move to a defined Vec2 Point, and embark to a group when arrived within a defined Radius.
-- @param #GROUP self
-- @param #Vec2 Point The point where to wait.
-- @param #number Radius The radius of the embarking zone around the Point.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskEmbarkToTransportAtVec2( Point, Radius )
	self:F( { self.GroupName, Point, Radius } )

  local DCSTask --DCSTask#Task
	DCSTask = { id = 'EmbarkToTransport', 
	            params = { x = Point.x, 
				  	             y = Point.y, 
		    							   zoneRadius = Radius,
						           } 
						} 

  self:T( { DCSTask } )
	return DCSTask
end

--- Return a Misson task from a mission template.
-- @param #GROUP self
-- @param #table TaskMission A table containing the mission task.
-- @return DCSTask#Task 
function GROUP:TaskMission( TaskMission )
	self:F( Points )
  
  local DCSTask
  DCSTask = { id = 'Mission', params = { TaskMission, }, }
  
  self:T( { DCSTask } )
  return DCSTask
end

--- Return a Misson task to follow a given route defined by Points.
-- @param #GROUP self
-- @param #table Points A table of route points.
-- @return DCSTask#Task 
function GROUP:TaskRoute( Points )
  self:F( Points )
  
  local DCSTask
  DCSTask = { id = 'Mission', params = { route = { points = Points, }, }, }
  
  self:T( { DCSTask } )
  return DCSTask
end

--- Make the group to fly to a given point and hover.
-- @param #GROUP self
-- @param #Vec3 Point The destination point.
-- @param #number Speed The speed to travel.
-- @return #GROUP self
function GROUP:TaskRouteToVec3( Point, Speed )
  self:F( { Point, Speed } )

  local GroupPoint = self:GetUnit( 1 ):GetPositionVec3()
  
  local PointFrom = {}
  PointFrom.x = GroupPoint.x
  PointFrom.y = GroupPoint.z
  PointFrom.alt = GroupPoint.y
  PointFrom.alt_type = "BARO"
  PointFrom.type = "Turning Point"
  PointFrom.action = "Turning Point"
  PointFrom.speed = Speed  
  PointFrom.speed_locked = true
  PointFrom.properties = {
        ["vnav"] = 1,
        ["scale"] = 0,
        ["angle"] = 0,
        ["vangle"] = 0,
        ["steer"] = 2,
  }
  

  local PointTo = {}
  PointTo.x = Point.x
  PointTo.y = Point.z
  PointTo.alt = Point.y  
  PointTo.alt_type = "BARO"
  PointTo.type = "Turning Point"
  PointTo.action = "Fly Over Point"
  PointTo.speed = Speed
  PointTo.speed_locked = true
  PointTo.properties = {
        ["vnav"] = 1,
        ["scale"] = 0,
        ["angle"] = 0,
        ["vangle"] = 0,
        ["steer"] = 2,
  }

  
  local Points = { PointFrom, PointTo }
  
  self:T( Points )
  
  self:Route( Points )

  return self
end



--- Make the group to follow a given route.
-- @param #GROUP self
-- @param #table GoPoints A table of Route Points.
-- @return #GROUP self 
function GROUP:Route( GoPoints )
	self:F( GoPoints )

	local Points = routines.utils.deepCopy( GoPoints )
	local MissionTask = { id = 'Mission', params = { route = { points = Points, }, }, }
	
	--self.Controller.setTask( self.Controller, MissionTask )

	routines.scheduleFunction( self.Controller.setTask, { self.Controller, MissionTask}, timer.getTime() + 1 )
	
	return self
end



--- Route the group to a given zone.
-- The group final destination point can be randomized.
-- A speed can be given in km/h.
-- A given formation can be given.
-- @param #GROUP self
-- @param Zone#ZONE Zone The zone where to route to.
-- @param #boolean Randomize Defines whether to target point gets randomized within the Zone.
-- @param #number Speed The speed.
-- @param Base#FORMATION Formation The formation string.
function GROUP:TaskRouteToZone( Zone, Randomize, Speed, Formation )
	self:F( Zone )
	
	local GroupPoint = self:GetPointVec2()
	
	local PointFrom = {}
	PointFrom.x = GroupPoint.x
	PointFrom.y = GroupPoint.y
	PointFrom.type = "Turning Point"
	PointFrom.action = "Cone"
	PointFrom.speed = 20 / 1.6
	

	local PointTo = {}
	local ZonePoint 
	
	if Randomize then
		ZonePoint = Zone:GetRandomPointVec2()
	else
		ZonePoint = Zone:GetPointVec2()
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

-- Commands

--- Do Script command
-- @param #GROUP self
-- @param #string DoScript
-- @return #DCSCommand
function GROUP:CommandDoScript( DoScript )

  local DCSDoScript = {
    id = "Script",
    params = {
      command = DoScript,
    },
  }

  self:T( DCSDoScript )
  return DCSDoScript
end


--- Return the mission template of the group.
-- @param #GROUP self
-- @return #table The MissionTemplate
function GROUP:GetTaskMission()
  self:F( self.GroupName )

  return routines.utils.deepCopy( _DATABASE.Templates.Groups[self.GroupName].Template )
end

--- Return the mission route of the group.
-- @param #GROUP self
-- @return #table The mission route defined by points.
function GROUP:GetTaskRoute()
  self:F( self.GroupName )

  return routines.utils.deepCopy( _DATABASE.Templates.Groups[self.GroupName].Template.route.points )
end

--- Return the route of a group by using the @{Database#DATABASE} class.
-- @param #GROUP self
-- @param #number Begin The route point from where the copy will start. The base route point is 0.
-- @param #number End The route point where the copy will end. The End point is the last point - the End point. The last point has base 0.
-- @param #boolean Randomize Randomization of the route, when true.
-- @param #number Radius When randomization is on, the randomization is within the radius. 
function GROUP:CopyRoute( Begin, End, Randomize, Radius )
	self:F( { Begin, End } )

	local Points = {}
	
	-- Could be a Spawned Group
	local GroupName = string.match( self:GetName(), ".*#" )
	if GroupName then
		GroupName = GroupName:sub( 1, -2 )
	else
		GroupName = self:GetName()
	end
	
	self:T( { GroupName } )
	
	local Template = _DATABASE.Templates.Groups[GroupName].Template
	
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

--- Get the controller for the GROUP.
-- @function _GetController
-- @param #GROUP self
-- @return Controller#Controller
function GROUP:_GetController()

	return self.DCSGroup:getController()

end

function GROUP:GetDetectedTargets()

  return self:_GetController():getDetectedTargets()
  
end

function GROUP:IsTargetDetected( DCSObject )

  local TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity
        = self:_GetController().isTargetDetected( self:_GetController(), DCSObject, 
                                                  Controller.Detection.VISUAL,
                                                  Controller.Detection.OPTIC,
                                                  Controller.Detection.RADAR,
                                                  Controller.Detection.IRST,
                                                  Controller.Detection.RWR,
                                                  Controller.Detection.DLINK
                                                )

  return TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity

end

-- Options

--- Can the GROUP hold their weapons?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEHoldFirePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() or self:IsGround() or self:IsShip() then
    return true
  end
  
  return false
end

--- Holding weapons.
-- @param Group#GROUP self
-- @return Group#GROUP self
function GROUP:OptionROEHoldFire()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
  elseif self:IsGround() then
    Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD )
  elseif self:IsShip() then
    Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.WEAPON_HOLD )
  end
  
  return self
end

--- Can the GROUP attack returning on enemy fire?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEReturnFirePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() or self:IsGround() or self:IsShip() then
    return true
  end
  
  return false
end

--- Return fire.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROEReturnFire()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.RETURN_FIRE )
  elseif self:IsGround() then
    Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.RETURN_FIRE )
  elseif self:IsShip() then
    Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.RETURN_FIRE )
  end
   
  return self
end

--- Can the GROUP attack designated targets?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEOpenFirePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() or self:IsGround() or self:IsShip() then
    return true
  end
  
  return false
end

--- Openfire.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROEOpenFire()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE )
  elseif self:IsGround() then
    Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE )
  elseif self:IsShip() then
    Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.OPEN_FIRE )
  end

  return self
end

--- Can the GROUP attack targets of opportunity?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEWeaponFreePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() then
    return true
  end
  
  return false
end

--- Weapon free.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROEWeaponFree()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE )
  end
  
  return self
end

--- Can the GROUP ignore enemy fire?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTNoReactionPossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() then
    return true
  end
  
  return false
end


--- No evasion on enemy threats.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTNoReaction()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.NO_REACTION )
  end
  
  return self
end

--- Can the GROUP evade using passive defenses?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTPassiveDefensePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() then
    return true
  end
  
  return false
end

--- Evasion passive defense.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTPassiveDefense()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.PASSIVE_DEFENCE )
  end
  
  return self
end

--- Can the GROUP evade on enemy fire?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTEvadeFirePossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() then
    return true
  end
  
  return false
end


--- Evade on fire.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTEvadeFire()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
  end
  
  return self
end

--- Can the GROUP evade on fire using vertical manoeuvres?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTVerticalPossible()
  self:F( { self.GroupName } )
  
  if self:IsAir() then
    return true
  end
  
  return false
end


--- Evade on fire using vertical manoeuvres.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTVertical()
	self:F( { self.GroupName } )

  local Controller = self:_GetController()
  
  if self:IsAir() then
    Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE )
  end
  
  return self
end

-- Message APIs

--- Returns a message for a coalition or a client.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
-- @return Message#MESSAGE
function GROUP:Message( Message, Duration )
  self:F( { Message, Duration } )
  
  return MESSAGE:New( Message, self:GetCallsign() .. " (" .. self:GetTypeName() .. ")", Duration, self:GetClassNameAndID() )
end

--- Send a message to all coalitions.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
function GROUP:MessageToAll( Message, Duration )
  self:F( { Message, Duration } )
  
  self:Message( Message, Duration ):ToAll()
end

--- Send a message to the red coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
function GROUP:MessageToRed( Message, Duration )
  self:F( { Message, Duration } )
  
  self:Message( Message, Duration ):ToRed()
end

--- Send a message to the blue coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
function GROUP:MessageToBlue( Message, Duration )
  self:F( { Message, Duration } )
  
  self:Message( Message, Duration ):ToBlue()
end

--- Send a message to a client.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
-- @param Client#CLIENT Client The client object receiving the message.
function GROUP:MessageToClient( Message, Duration, Client )
  self:F( { Message, Duration } )
  
  self:Message( Message, Duration ):ToClient( Client )
end




--- Find the created GROUP using the DCSGroup ID. If a GROUP was created with the DCSGroupID, the the GROUP instance will be returned.
-- Otherwise nil will be returned.
-- @param DCSGroup#Group Group
-- @return #GROUP
function GROUP.FindGroup( DCSGroup )

  local self = GROUPS[DCSGroup:getID()] -- Group#GROUP
  self:T( self:GetClassNameAndID() )
  return self

end


--- UNIT Classes
-- @module Unit

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

--- The UNIT class
-- @type UNIT
-- @Extends Base#BASE
-- @field #UNIT.FlareColor FlareColor
-- @field #UNIT.SmokeColor SmokeColor
UNIT = {
	ClassName="UNIT",
	CategoryName = { 
    [Unit.Category.AIRPLANE]      = "Airplane",
    [Unit.Category.HELICOPTER]    = "Helicoper",
    [Unit.Category.GROUND_UNIT]   = "Ground Unit",
    [Unit.Category.SHIP]          = "Ship",
    [Unit.Category.STRUCTURE]     = "Structure",
    },
  FlareColor = {
    Green = trigger.flareColor.Green,
    Red = trigger.flareColor.Red,
    White = trigger.flareColor.White,
    Yellow = trigger.flareColor.Yellow
    },
  SmokeColor = {
    Green = trigger.smokeColor.Green,
    Red = trigger.smokeColor.Red,
    White = trigger.smokeColor.White,
    Orange = trigger.smokeColor.Orange,
    Blue = trigger.smokeColor.Blue
    },
	}

--- FlareColor
-- @type UNIT.FlareColor
-- @field Green
-- @field Red
-- @field White
-- @field Yellow

--- SmokeColor
-- @type UNIT.SmokeColor
-- @field Green
-- @field Red
-- @field White
-- @field Orange
-- @field Blue
	

--- Create a new UNIT from DCSUnit.
-- @param #UNIT self
-- @param DCSUnit#Unit DCSUnit
-- @return Unit#UNIT
function UNIT:New( DCSUnit )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( DCSUnit )

	self.DCSUnit = DCSUnit
	if DCSUnit then
  	self.UnitName = DCSUnit:getName()
  	self.UnitID = DCSUnit:getID()
  end

	return self
end

function UNIT:IsAlive()
	self:F( self.UnitName )
	
	return ( self.DCSUnit and self.DCSUnit:isExist() )
end


function UNIT:GetDCSUnit()
	self:F( self.DCSUnit )
	
	return self.DCSUnit
end

function UNIT:GetID()
	self:F( self.UnitID )
	
	return self.UnitID
end


function UNIT:GetName()
	self:F( self.UnitName )
	
	return self.UnitName
end

function UNIT:GetPlayerName()
  self:F( self.UnitName )
  
  local DCSUnit = Unit.getByName( self.UnitName )
  
  local PlayerName = DCSUnit:getPlayerName()
  if PlayerName == nil then
    PlayerName = ""
  end
  
  return PlayerName
end
function UNIT:GetTypeName()
	self:F( self.UnitName )
	
	return self.DCSUnit:getTypeName()
end

function UNIT:GetPrefix()
	self:F( self.UnitName )
	
	local UnitPrefix = string.match( self.UnitName, ".*#" ):sub( 1, -2 )
	self:T( UnitPrefix )

	return UnitPrefix
end


function UNIT:GetCallSign()
	self:F( self.UnitName )
	
	return self.DCSUnit:getCallsign()
end


function UNIT:GetPointVec2()
	self:F( self.UnitName )
	
	local UnitPos = self.DCSUnit:getPosition().p
	
	local UnitPoint = {}
	UnitPoint.x = UnitPos.x
	UnitPoint.y = UnitPos.z

	self:T( UnitPoint )
	return UnitPoint
end


function UNIT:GetPositionVec3()
	self:F( self.UnitName )
	
	local UnitPos = self.DCSUnit:getPosition().p

	self:T( UnitPos )
	return UnitPos
end

function UNIT:OtherUnitInRadius( AwaitUnit, Radius )
	self:F( { self.UnitName, AwaitUnit.UnitName, Radius } )

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

function UNIT:GetCategoryName()
  return self.CategoryName[ self.DCSUnit:getDesc().category ]
end

--- Signal a flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:Flare( FlareColor )
  self:F()
  trigger.action.signalFlare( self:GetPositionVec3(), FlareColor , 0 )
end

--- Signal a white flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareWhite()
  self:F()
  trigger.action.signalFlare( self:GetPositionVec3(), trigger.flareColor.White , 0 )
end

--- Signal a yellow flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareYellow()
  self:F()
  trigger.action.signalFlare( self:GetPositionVec3(), trigger.flareColor.Yellow , 0 )
end

--- Signal a green flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareGreen()
  self:F()
  trigger.action.signalFlare( self:GetPositionVec3(), trigger.flareColor.Green , 0 )
end

--- Signal a red flare at the position of the UNIT.
-- @param #UNIT self
function UNIT:FlareRed()
  self:F()
  trigger.action.signalFlare( self:GetPositionVec3(), trigger.flareColor.Red, 0 )
end

--- Smoke the UNIT.
-- @param #UNIT self
function UNIT:Smoke( SmokeColor )
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), SmokeColor )
end

--- Smoke the UNIT Green.
-- @param #UNIT self
function UNIT:SmokeGreen()
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), trigger.smokeColor.Green )
end

--- Smoke the UNIT Red.
-- @param #UNIT self
function UNIT:SmokeRed()
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), trigger.smokeColor.Red )
end

--- Smoke the UNIT White.
-- @param #UNIT self
function UNIT:SmokeWhite()
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), trigger.smokeColor.White )
end

--- Smoke the UNIT Orange.
-- @param #UNIT self
function UNIT:SmokeOrange()
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), trigger.smokeColor.Orange )
end

--- Smoke the UNIT Blue.
-- @param #UNIT self
function UNIT:SmokeBlue()
  self:F()
  trigger.action.smoke( self:GetPositionVec3(), trigger.smokeColor.Blue )
end

-- Is methods

--- Returns if the unit is of an air category.
-- If the unit is a helicopter or a plane, then this method will return true, otherwise false.
-- @param #UNIT self
-- @return #boolean Air category evaluation result.
function UNIT:IsAir()
  self:F()
  
  local UnitDescriptor = self.DCSUnit:getDesc()
  self:T( { UnitDescriptor.category, Unit.Category.AIRPLANE, Unit.Category.HELICOPTER } )
  
  local IsAirResult = ( UnitDescriptor.category == Unit.Category.AIRPLANE ) or ( UnitDescriptor.category == Unit.Category.HELICOPTER )

  self:T( IsAirResult )
  return IsAirResult
end

--- ZONE Classes
-- @module Zone

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

--- The ZONE class
-- @type ZONE
-- @Extends Base#BASE
ZONE = {
	ClassName="ZONE",
	}
	
function ZONE:New( ZoneName )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( ZoneName )

	local Zone = trigger.misc.getZone( ZoneName )
	
	if not Zone then
		error( "Zone " .. ZoneName .. " does not exist." )
		return nil
	end
	
	self.Zone = Zone
	self.ZoneName = ZoneName
	
	return self
end

function ZONE:GetPointVec2()
	self:F( self.ZoneName )

	local Zone = trigger.misc.getZone( self.ZoneName )
	local Point = { x = Zone.point.x, y = Zone.point.z }

	self:T( { Zone, Point } )
	
	return Point	
end

function ZONE:GetPointVec3( Height )
  self:F( self.ZoneName )

  local Zone = trigger.misc.getZone( self.ZoneName )
  local Point = { x = Zone.point.x, y = land.getHeight( self:GetPointVec2() ) + Height, z = Zone.point.z }

  self:T( { Zone, Point } )
  
  return Point  
end

function ZONE:GetRandomPointVec2()
	self:F( self.ZoneName )

	local Point = {}

	local Zone = trigger.misc.getZone( self.ZoneName )
	
	local angle = math.random() * math.pi*2;
	Point.x = Zone.point.x + math.cos( angle ) * math.random() * Zone.radius;
	Point.y = Zone.point.z + math.sin( angle ) * math.random() * Zone.radius;
	
	self:T( { Zone, Point } )
	
	return Point
end

function ZONE:GetRadius()
	self:F( self.ZoneName )

	local Zone = trigger.misc.getZone( self.ZoneName )

	self:T( { Zone } )

	return Zone.radius
end

--- The CLIENT models client units in multi player missions.
-- 
-- @{#CLIENT} class
-- ================
-- Clients are those **Units** defined within the Mission Editor that have the skillset defined as __Client__ or __Player__.
-- Note that clients are NOT the same as Units, they are NOT necessarily alive.
-- 
-- Clients are being used by the @{MISSION} class to follow players and register their successes.
-- 
-- CLIENT construction methods:
-- ============================ 
-- Create a new CLIENT object with the @{#CLIENT.New} method:
-- 
--   * @{#CLIENT.New}: Creates a new CLIENT object taking the name of the **DCSUnit** that is a client as defined within the mission editor.
--  
-- @module Client
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Cargo" )
Include.File( "Message" )


--- The CLIENT class
-- @type CLIENT
-- @extends Base#BASE
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


--- Use this method to register new Clients within a mission.
-- @param #CLIENT self
-- @param #string ClientName Name of the DCS **Unit** as defined within the Mission Editor.
-- @param #string ClientBriefing Text that describes the briefing of the mission when a Player logs into the Client.
-- @return #CLIENT
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
	self:F( ClientName, ClientBriefing )

  self.ClientName = ClientName
	self:AddBriefing( ClientBriefing )
	self.MessageSwitch = true
	
	return self
end

--- Transport defines that the Client is a Transport. Transports show cargo.
-- @param #CLIENT self
-- @return #CLIENT
function CLIENT:Transport()
  self:F()

  self.ClientTransport = true
  return self
end

--- AddBriefing adds a briefing to a CLIENT when a player joins a mission.
-- @param #CLIENT self
-- @param #string ClientBriefing is the text defining the Mission briefing.
-- @return #CLIENT
function CLIENT:AddBriefing( ClientBriefing )
  self:F()
  self.ClientBriefing = ClientBriefing
  return self
end


--- Resets a CLIENT.
-- @param #CLIENT self
-- @param #string ClientName Name of the Group as defined within the Mission Editor. The Group must have a Unit with the type Client.
function CLIENT:Reset( ClientName )
	self:F()
	self._Menus = {}
end

--- Checks for a client alive event and calls a function on a continuous basis.
-- @param #CLIENT self
-- @param #function CallBack Function.
-- @return #CLIENT
function CLIENT:Alive( CallBack, ... )
  self:F()
  
  self.ClientAlive2 = false
  self.ClientCallBack = CallBack
  self.ClientParameters = arg
  self.AliveCheckScheduler = routines.scheduleFunction( self._AliveCheckScheduler, { self }, timer.getTime() + 1, 5 )

  return self
end

-- Is Functions

--- Checks if the CLIENT is a multi-seated UNIT.
-- @param #CLIENT self
-- @return #boolean true if multi-seated.
function CLIENT:IsMultiSeated()
  self:F( self.ClientName )

  local ClientMultiSeatedTypes = { 
    ["Mi-8MT"]  = "Mi-8MT", 
    ["UH-1H"]   = "UH-1H", 
    ["P-51B"]   = "P-51B" 
  }
  
  if self:IsAlive() then
    local ClientTypeName = self:GetClientGroupUnit():GetTypeName()
    if ClientMultiSeatedTypes[ClientTypeName] then
      return true
    end
  end
  
  return false
end

--- Checks if client is alive and returns true or false.
-- @param #CLIENT self
-- @returns #boolean Returns true if client is alive.
function CLIENT:IsAlive()
  self:F( self.ClientName )
  
  local ClientUnit = Unit.getByName( self.ClientName )
  
  if ClientUnit and ClientUnit:isExist() then
    self:T("true")
    return true
  end
  
  self:T( "false" )
  return false
end


--- @param #CLIENT self
function CLIENT:_AliveCheckScheduler()
  self:F( { self.ClientName, self.ClientAlive2 } )

  if self:IsAlive() then
    if self.ClientAlive2 == false then
      self:T("Calling Callback function")
      self.ClientCallBack( self, unpack( self.ClientParameters ) )
      self.ClientAlive2 = true
    end
  else
    if self.ClientAlive2 == true then
      self.ClientAlive2 = false
    end
  end
end

--- Return the DCSGroup of a Client.
-- This function is modified to deal with a couple of bugs in DCS 1.5.3
-- @param #CLIENT self
-- @return DCSGroup#Group
function CLIENT:GetDCSGroup()
  self:F3()

--  local ClientData = Group.getByName( self.ClientName )
--	if ClientData and ClientData:isExist() then
--		self:T( self.ClientName .. " : group found!" )
--		return ClientData
--	else
--		return nil
--	end
  
  local ClientUnit = Unit.getByName( self.ClientName )

	local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ) }
	for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
		self:T3( { "CoalitionData:", CoalitionData } )
		for UnitId, UnitData in pairs( CoalitionData ) do
			self:T3( { "UnitData:", UnitData } )
			if UnitData and UnitData:isExist() then

        --self:E(self.ClientName)
        if ClientUnit then
  				local ClientGroup = ClientUnit:getGroup()
  				if ClientGroup then
  					self:T3( "ClientGroup = " .. self.ClientName )
  					if ClientGroup:isExist() and UnitData:getGroup():isExist() then 
  						if ClientGroup:getID() == UnitData:getGroup():getID() then
  							self:T3( "Normal logic" )
  							self:T3( self.ClientName .. " : group found!" )
                self.ClientGroupID = ClientGroup:getID()
  							self.ClientGroupName = ClientGroup:getName()
  							return ClientGroup
  						end
  					else
  						-- Now we need to resolve the bugs in DCS 1.5 ...
  						-- Consult the database for the units of the Client Group. (ClientGroup:getUnits() returns nil)
  						self:T3( "Bug 1.5 logic" )
  						local ClientGroupTemplate = _DATABASE.Templates.Units[self.ClientName].GroupTemplate
  						self.ClientGroupID = ClientGroupTemplate.groupId
  						self.ClientGroupName = _DATABASE.Templates.Units[self.ClientName].GroupName
  						self:T3( self.ClientName .. " : group found in bug 1.5 resolvement logic!" )
  						return ClientGroup
  					end
  --				else
  --					error( "Client " .. self.ClientName .. " not found!" )
  				end
  			else
  			  --self:E( { "Client not found!", self.ClientName } )
  		  end
			end
		end
	end

	-- For non player clients
	if ClientUnit then
  	local ClientGroup = ClientUnit:getGroup()
  	if ClientGroup then
  		self:T3( "ClientGroup = " .. self.ClientName )
  		if ClientGroup:isExist() then 
  			self:T3( "Normal logic" )
  			self:T3( self.ClientName .. " : group found!" )
  			return ClientGroup
  		end
  	end
  end
	
	self.ClientGroupID = nil
	self.ClientGroupUnit = nil
	
	return nil
end 


-- TODO: Check DCSTypes#Group.ID
--- Get the group ID of the client.
-- @param #CLIENT self
-- @return DCSTypes#Group.ID
function CLIENT:GetClientGroupID()

  local ClientGroup = self:GetDCSGroup()

  --self:E( self.ClientGroupID ) -- Determined in GetDCSGroup()
	return self.ClientGroupID
end


--- Get the name of the group of the client.
-- @param #CLIENT self
-- @return #string
function CLIENT:GetClientGroupName()

  local ClientGroup = self:GetDCSGroup()

  self:T( self.ClientGroupName ) -- Determined in GetDCSGroup()
	return self.ClientGroupName
end

--- Returns the UNIT of the CLIENT.
-- @param #CLIENT self
-- @return Unit#UNIT
function CLIENT:GetClientGroupUnit()
	self:F2()

	local ClientDCSUnit = Unit.getByName( self.ClientName )

  self:T( self.ClientDCSUnit )
	if ClientDCSUnit and ClientDCSUnit:isExist() then
		local ClientUnit = _DATABASE.Units[ self.ClientName ]
		self:T2( ClientUnit )
		return ClientUnit
	end
end

--- Returns the DCSUnit of the CLIENT.
-- @param #CLIENT self
-- @return DCSTypes#Unit
function CLIENT:GetClientGroupDCSUnit()
	self:F2()

  local ClientDCSUnit = Unit.getByName( self.ClientName )
  
  if ClientDCSUnit and ClientDCSUnit:isExist() then
    self:T2( ClientDCSUnit )
    return ClientDCSUnit
  end
end

-- TODO what is this??? check. possible double function.
function CLIENT:GetUnit()
	self:F()
	
	return UNIT:New( self:GetClientGroupDCSUnit() )
end

--- Returns the position of the CLIENT in @{DCSTypes#Vec2} format..
-- @param #CLIENT self
-- @return DCSTypes#Vec2
function CLIENT:GetPointVec2()
	self:F()

  local ClientGroupUnit = self:GetClientGroupDCSUnit()
  
  if ClientGroupUnit then
    if ClientGroupUnit:isExist() then
      local PointVec3 = ClientGroupUnit:getPoint() --DCSTypes#Vec3
      local PointVec2 = {} --DCSTypes#Vec2
      PointVec2.x = PointVec3.x
      PointVec2.y = PointVec3.z
      self:T( { PointVec2 } )
      return PointVec2
    end
  end
  
  return nil
end 

function CLIENT:GetPositionVec3()
  self:F( self.ClientName )
  
  local DCSUnit = Unit.getByName( self.ClientName )
  local UnitPos = DCSUnit:getPosition().p

  self:T( UnitPos )
  return UnitPos
end

function CLIENT:GetID()
  self:F( self.ClientName )

  local DCSUnit = Unit.getByName( self.ClientName )
  local UnitID = DCSUnit:getID()
  
  self:T( UnitID )
  return UnitID
end

function CLIENT:GetName()
  self:F( self.ClientName )
  
  self:T( self.ClientName )
  return self.ClientName
end

function CLIENT:GetTypeName()
  self:F( self.ClientName )

  local DCSUnit = Unit.getByName( self.ClientName )
  local TypeName = DCSUnit:getTypeName()
  
  self:T( TypeName )
  return TypeName
end



--- Returns the position of the CLIENT in @{DCSTypes#Vec3} format.
-- @param #CLIENT self
-- @return DCSTypes#Vec3
function CLIENT:ClientPosition()
	self:F()

	local ClientGroupUnit = self:GetClientGroupDCSUnit()
	
	if ClientGroupUnit then
		if ClientGroupUnit:isExist() then
			return ClientGroupUnit:getPosition()
		end
	end
	
	return nil
end 

--- Returns the altitude of the CLIENT.
-- @param #CLIENT self
-- @return DCSTypes#Distance
function CLIENT:GetAltitude()
	self:F()

  local ClientGroupUnit = self:GetClientGroupDCSUnit()
  
  if ClientGroupUnit then
    if ClientGroupUnit:isExist() then
      local PointVec3 = ClientGroupUnit:getPoint() --DCSTypes#Vec3
      return PointVec3.y
    end
  end
  
  return nil
end 


--- Evaluates if the CLIENT is a transport.
-- @param #CLIENT self
-- @return #boolean true is a transport.
function CLIENT:IsTransport()
	self:F()
	return self.ClientTransport
end

--- Shows the @{Cargo#CARGO} contained within the CLIENT to the player as a message.
-- The @{Cargo#CARGO} is shown using the @{Message#MESSAGE} distribution system.
-- @param #CLIENT self
function CLIENT:ShowCargo()
	self:F()

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

-- TODO (1) I urgently need to revise this.
--- A local function called by the DCS World Menu system to switch off messages.
function CLIENT.SwitchMessages( PrmTable )
	PrmTable[1].MessageSwitch = PrmTable[2]
end

--- The main message driver for the CLIENT.
-- This function displays various messages to the Player logged into the CLIENT through the DCS World Messaging system.
-- @param #CLIENT self
-- @param #string Message is the text describing the message.
-- @param #number MessageDuration is the duration in seconds that the Message should be displayed.
-- @param #string MessageId is a text identifying the Message in the MessageQueue. The Message system overwrites Messages with the same MessageId
-- @param #string MessageCategory is the category of the message (the title).
-- @param #number MessageInterval is the interval in seconds between the display of the @{Message#MESSAGE} when the CLIENT is in the air.
function CLIENT:Message( Message, MessageDuration, MessageId, MessageCategory, MessageInterval )
	self:F()

	if not self.MenuMessages then
		if self:GetClientGroupID() then
			self.MenuMessages = MENU_CLIENT:New( self, 'Messages' )
			self.MenuRouteMessageOn = MENU_CLIENT_COMMAND:New( self, 'Messages On', self.MenuMessages, CLIENT.SwitchMessages, { self, true } )
			self.MenuRouteMessageOff = MENU_CLIENT_COMMAND:New( self,'Messages Off', self.MenuMessages, CLIENT.SwitchMessages, { self, false } )
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
--- Manage sets of units and groups. 
-- 
-- @{#Database} class
-- ==================
-- Mission designers can use the DATABASE class to build sets of units belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Unit types
--  * Starting with certain prefix strings.
--  
-- This list will grow over time. Planned developments are to include filters and iterators.
-- Additional filters will be added around @{Zone#ZONEs}, Radiuses, Active players, ...
-- More iterators will be implemented in the near future ...
--
-- Administers the Initial Sets of the Mission Templates as defined within the Mission Editor.
-- 
-- DATABASE construction methods:
-- =================================
-- Create a new DATABASE object with the @{#DATABASE.New} method:
-- 
--    * @{#DATABASE.New}: Creates a new DATABASE object.
--   
-- 
-- DATABASE filter criteria: 
-- =========================
-- You can set filter criteria to define the set of units within the database.
-- Filter criteria are defined by:
-- 
--    * @{#DATABASE.FilterCoalitions}: Builds the DATABASE with the units belonging to the coalition(s).
--    * @{#DATABASE.FilterCategories}: Builds the DATABASE with the units belonging to the category(ies).
--    * @{#DATABASE.FilterTypes}: Builds the DATABASE with the units belonging to the unit type(s).
--    * @{#DATABASE.FilterCountries}: Builds the DATABASE with the units belonging to the country(ies).
--    * @{#DATABASE.FilterUnitPrefixes}: Builds the DATABASE with the units starting with the same prefix string(s).
--   
-- Once the filter criteria have been set for the DATABASE, you can start filtering using:
-- 
--   * @{#DATABASE.FilterStart}: Starts the filtering of the units within the database.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#DATABASE.FilterGroupPrefixes}: Builds the DATABASE with the groups of the units starting with the same prefix string(s).
--    * @{#DATABASE.FilterZones}: Builds the DATABASE with the units within a @{Zone#ZONE}.
-- 
-- 
-- DATABASE iterators:
-- ===================
-- Once the filters have been defined and the DATABASE has been built, you can iterate the database with the available iterator methods.
-- The iterator methods will walk the DATABASE set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the DATABASE:
-- 
--   * @{#DATABASE.ForEachAliveUnit}: Calls a function for each alive unit it finds within the DATABASE.
--   
-- Planned iterators methods in development are (so these are not yet available):
-- 
--   * @{#DATABASE.ForEachUnit}: Calls a function for each unit contained within the DATABASE.
--   * @{#DATABASE.ForEachGroup}: Calls a function for each group contained within the DATABASE.
--   * @{#DATABASE.ForEachUnitInZone}: Calls a function for each unit within a certain zone contained within the DATABASE.
-- 
-- ====
-- @module Database
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Menu" )
Include.File( "Group" )
Include.File( "Unit" )
Include.File( "Event" )
Include.File( "Client" )

--- DATABASE class
-- @type DATABASE
-- @extends Base#BASE
DATABASE = {
  ClassName = "DATABASE",
  Templates = {
    Units = {},
    Groups = {},
    ClientsByName = {},
    ClientsByID = {},
  },
  DCSUnits = {},
  DCSUnitsAlive = {},
  DCSGroups = {},
  DCSGroupsAlive = {},
  Units = {},
  UnitsAlive = {},
  Groups = {},
  GroupsAlive = {},
  NavPoints = {},
  Statics = {},
  Players = {},
  PlayersAlive = {},
  Clients = {},
  ClientsAlive = {},
  Filter = {
    Coalitions = nil,
    Categories = nil,
    Types = nil,
    Countries = nil,
    UnitPrefixes = nil,
    GroupPrefixes = nil,
  },
  FilterMeta = {
    Coalitions = {
      red = coalition.side.RED,
      blue = coalition.side.BLUE,
      neutral = coalition.side.NEUTRAL,
    },
    Categories = {
      plane = Unit.Category.AIRPLANE,
      helicopter = Unit.Category.HELICOPTER,
      ground = Unit.Category.GROUND_UNIT,
      ship = Unit.Category.SHIP,
      structure = Unit.Category.STRUCTURE,
    },
  },
}

local _DATABASECoalition =
  {
    [1] = "Red",
    [2] = "Blue",
  }

local _DATABASECategory =
  {
    [Unit.Category.AIRPLANE] = "Plane",
    [Unit.Category.HELICOPTER] = "Helicopter",
    [Unit.Category.GROUND_UNIT] = "Vehicle",
    [Unit.Category.SHIP] = "Ship",
    [Unit.Category.STRUCTURE] = "Structure",
  }


--- Creates a new DATABASE object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #DATABASE self
-- @return #DATABASE
-- @usage
-- -- Define a new DATABASE Object. This DBObject will contain a reference to all Group and Unit Templates defined within the ME and the DCSRTE.
-- DBObject = DATABASE:New()
function DATABASE:New()

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  _EVENTDISPATCHER:OnBirth( self._EventOnBirth, self )
  _EVENTDISPATCHER:OnDead( self._EventOnDeadOrCrash, self )
  _EVENTDISPATCHER:OnCrash( self._EventOnDeadOrCrash, self )
  
  
  -- Add database with registered clients and already alive players
  
  -- Follow alive players and clients
  _EVENTDISPATCHER:OnPlayerEnterUnit( self._EventOnPlayerEnterUnit, self )
  _EVENTDISPATCHER:OnPlayerLeaveUnit( self._EventOnPlayerLeaveUnit, self )
  
  
  return self
end

--- Builds a set of units of coalitons.
-- Possible current coalitions are red, blue and neutral.
-- @param #DATABASE self
-- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
-- @return #DATABASE self
function DATABASE:FilterCoalitions( Coalitions )
  if not self.Filter.Coalitions then
    self.Filter.Coalitions = {}
  end
  if type( Coalitions ) ~= "table" then
    Coalitions = { Coalitions }
  end
  for CoalitionID, Coalition in pairs( Coalitions ) do
    self.Filter.Coalitions[Coalition] = Coalition
  end
  return self
end

--- Builds a set of units out of categories.
-- Possible current categories are plane, helicopter, ground, ship.
-- @param #DATABASE self
-- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship".
-- @return #DATABASE self
function DATABASE:FilterCategories( Categories )
  if not self.Filter.Categories then
    self.Filter.Categories = {}
  end
  if type( Categories ) ~= "table" then
    Categories = { Categories }
  end
  for CategoryID, Category in pairs( Categories ) do
    self.Filter.Categories[Category] = Category
  end
  return self
end

--- Builds a set of units of defined unit types.
-- Possible current types are those types known within DCS world.
-- @param #DATABASE self
-- @param #string Types Can take those type strings known within DCS world.
-- @return #DATABASE self
function DATABASE:FilterTypes( Types )
  if not self.Filter.Types then
    self.Filter.Types = {}
  end
  if type( Types ) ~= "table" then
    Types = { Types }
  end
  for TypeID, Type in pairs( Types ) do
    self.Filter.Types[Type] = Type
  end
  return self
end

--- Builds a set of units of defined countries.
-- Possible current countries are those known within DCS world.
-- @param #DATABASE self
-- @param #string Countries Can take those country strings known within DCS world.
-- @return #DATABASE self
function DATABASE:FilterCountries( Countries )
  if not self.Filter.Countries then
    self.Filter.Countries = {}
  end
  if type( Countries ) ~= "table" then
    Countries = { Countries }
  end
  for CountryID, Country in pairs( Countries ) do
    self.Filter.Countries[Country] = Country
  end
  return self
end

--- Builds a set of units of defined unit prefixes.
-- All the units starting with the given prefixes will be included within the set.
-- @param #DATABASE self
-- @param #string Prefixes The prefix of which the unit name starts with.
-- @return #DATABASE self
function DATABASE:FilterUnitPrefixes( Prefixes )
  if not self.Filter.UnitPrefixes then
    self.Filter.UnitPrefixes = {}
  end
  if type( Prefixes ) ~= "table" then
    Prefixes = { Prefixes }
  end
  for PrefixID, Prefix in pairs( Prefixes ) do
    self.Filter.UnitPrefixes[Prefix] = Prefix
  end
  return self
end

--- Builds a set of units of defined group prefixes.
-- All the units starting with the given group prefixes will be included within the set.
-- @param #DATABASE self
-- @param #string Prefixes The prefix of which the group name where the unit belongs to starts with.
-- @return #DATABASE self
function DATABASE:FilterGroupPrefixes( Prefixes )
  if not self.Filter.GroupPrefixes then
    self.Filter.GroupPrefixes = {}
  end
  if type( Prefixes ) ~= "table" then
    Prefixes = { Prefixes }
  end
  for PrefixID, Prefix in pairs( Prefixes ) do
    self.Filter.GroupPrefixes[Prefix] = Prefix
  end
  return self
end

--- Starts the filtering.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:FilterStart()

  if _DATABASE then
    -- OK, we have a _DATABASE
    -- Now use the different filters to build the set.
    -- We first take ALL of the Units of the _DATABASE.
    
    self:E( { "Adding Database Datapoints with filters" } )
    for DCSUnitName, DCSUnit in pairs( _DATABASE.DCSUnits ) do

      if self:_IsIncludeDCSUnit( DCSUnit ) then

        self:E( { "Adding Unit:", DCSUnitName } )
        self.DCSUnits[DCSUnitName] = _DATABASE.DCSUnits[DCSUnitName]
        self.Units[DCSUnitName] = _DATABASE.Units[DCSUnitName]
        
        if _DATABASE.DCSUnitsAlive[DCSUnitName] then
          self.DCSUnitsAlive[DCSUnitName] = _DATABASE.DCSUnitsAlive[DCSUnitName]
          self.UnitsAlive[DCSUnitName] = _DATABASE.UnitsAlive[DCSUnitName]
        end
        
      end
    end
    
    for DCSGroupName, DCSGroup in pairs( _DATABASE.DCSGroups ) do
      
      --if self:_IsIncludeDCSGroup( DCSGroup ) then
      self:E( { "Adding Group:", DCSGroupName } )
      self.DCSGroups[DCSGroupName] = _DATABASE.DCSGroups[DCSGroupName]
      self.Groups[DCSGroupName] = _DATABASE.Groups[DCSGroupName]
      --end
      
      if _DATABASE.DCSGroupsAlive[DCSGroupName] then
        self.DCSGroupsAlive[DCSGroupName] = _DATABASE.DCSGroupsAlive[DCSGroupName]
        self.GroupsAlive[DCSGroupName] = _DATABASE.GroupsAlive[DCSGroupName]
      end
    end

    for DCSUnitName, Client in pairs( _DATABASE.Clients ) do
      self:E( { "Adding Client for Unit:", DCSUnitName } )
      self.Clients[DCSUnitName] = _DATABASE.Clients[DCSUnitName]
    end
    
  else
    self:E( "There is a structural error in MOOSE. No _DATABASE has been defined! Cannot build this custom DATABASE." )
  end
  
  return self
end


--- Instantiate new Groups within the DCSRTE.
-- This method expects EXACTLY the same structure as a structure within the ME, and needs 2 additional fields defined:
-- SpawnCountryID, SpawnCategoryID
-- This method is used by the SPAWN class.
-- @param #DATABASE self
-- @param #table SpawnTemplate
-- @return #DATABASE self
function DATABASE:Spawn( SpawnTemplate )
  self:F( SpawnTemplate.name )

  self:T( { SpawnTemplate.SpawnCountryID, SpawnTemplate.SpawnCategoryID } )

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
  self:F( Status )

  self.Templates.Groups[GroupName].Status = Status
end


--- Get a status to a Group within the Database, this to check crossing events for example.
function DATABASE:GetStatusGroup( GroupName )
  self:F( Status )

  if self.Templates.Groups[GroupName] then
    return self.Templates.Groups[GroupName].Status
  else
    return ""
  end
end

--- Private method that registers new Group Templates within the DATABASE Object.
-- @param #DATABASE self
-- @param #table GroupTemplate
-- @return #DATABASE self
function DATABASE:_RegisterGroup( GroupTemplate )

  local GroupTemplateName = env.getValueDictByKey(GroupTemplate.name)

  if not self.Templates.Groups[GroupTemplateName] then
    self.Templates.Groups[GroupTemplateName] = {}
    self.Templates.Groups[GroupTemplateName].Status = nil
  end
  
  -- Delete the spans from the route, it is not needed and takes memory.
  if GroupTemplate.route and GroupTemplate.route.spans then 
    GroupTemplate.route.spans = nil
  end
  
  self.Templates.Groups[GroupTemplateName].GroupName = GroupTemplateName
  self.Templates.Groups[GroupTemplateName].Template = GroupTemplate
  self.Templates.Groups[GroupTemplateName].groupId = GroupTemplate.groupId
  self.Templates.Groups[GroupTemplateName].UnitCount = #GroupTemplate.units
  self.Templates.Groups[GroupTemplateName].Units = GroupTemplate.units

  self:T( { "Group", self.Templates.Groups[GroupTemplateName].GroupName, self.Templates.Groups[GroupTemplateName].UnitCount } )

  for unit_num, UnitTemplate in pairs( GroupTemplate.units ) do

    local UnitTemplateName = env.getValueDictByKey(UnitTemplate.name)
    self.Templates.Units[UnitTemplateName] = {}
    self.Templates.Units[UnitTemplateName].UnitName = UnitTemplateName
    self.Templates.Units[UnitTemplateName].Template = UnitTemplate
    self.Templates.Units[UnitTemplateName].GroupName = GroupTemplateName
    self.Templates.Units[UnitTemplateName].GroupTemplate = GroupTemplate
    self.Templates.Units[UnitTemplateName].GroupId = GroupTemplate.groupId
    self:E( {"skill",UnitTemplate.skill})
    if UnitTemplate.skill and (UnitTemplate.skill == "Client" or UnitTemplate.skill == "Player") then
      self.Templates.ClientsByName[UnitTemplateName] = UnitTemplate
      self.Templates.ClientsByID[UnitTemplate.unitId] = UnitTemplate
    end
    self:E( { "Unit", self.Templates.Units[UnitTemplateName].UnitName } )
  end
end

--- Private method that registers all alive players in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterPlayers()

  local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for UnitId, UnitData in pairs( CoalitionData ) do
      self:T3( { "UnitData:", UnitData } )
      if UnitData and UnitData:isExist() then
        local UnitName = UnitData:getName()
        if not self.PlayersAlive[UnitName] then
          self:E( { "Add player for unit:", UnitName, UnitData:getPlayerName() } )
          self.PlayersAlive[UnitName] = UnitData:getPlayerName()
        end
      end
    end
  end
  
  return self
end

--- Private method that registers all datapoints within in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterDatabase()

  local CoalitionsData = { AlivePlayersRed = coalition.getGroups( coalition.side.RED ), AlivePlayersBlue = coalition.getGroups( coalition.side.BLUE ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for DCSGroupId, DCSGroup in pairs( CoalitionData ) do

      if DCSGroup:isExist() then
        local DCSGroupName = DCSGroup:getName()
  
        self:E( { "Register Group:", DCSGroup, DCSGroupName } )
        self.DCSGroups[DCSGroupName] = DCSGroup
        self.Groups[DCSGroupName] = GROUP:New( DCSGroup )
  
        if self:_IsAliveDCSGroup(DCSGroup) then
          self:E( { "Register Alive Group:", DCSGroup, DCSGroupName } )
          self.DCSGroupsAlive[DCSGroupName] = DCSGroup
          self.GroupsAlive[DCSGroupName] = self.Groups[DCSGroupName]  
        end
  
        for DCSUnitId, DCSUnit in pairs( DCSGroup:getUnits() ) do
  
          local DCSUnitName = DCSUnit:getName()
          self:E( { "Register Unit:", DCSUnit, DCSUnitName } )
  
          self.DCSUnits[DCSUnitName] = DCSUnit
          self.Units[DCSUnitName] = UNIT:New( DCSUnit )
  
          if self:_IsAliveDCSUnit(DCSUnit) then
            self:E( { "Register Alive Unit:", DCSUnit, DCSUnitName } )
            self.DCSUnitsAlive[DCSUnitName] = DCSUnit
            self.UnitsAlive[DCSUnitName] = self.Units[DCSUnitName]  
          end
        end
      else
        self:E( "Group does not exist: " .. DCSGroup )
      end
      
      for ClientName, ClientTemplate in pairs( self.Templates.ClientsByName ) do
        self.Clients[ClientName] = CLIENT:New( ClientName )
      end
    end
  end
  
  return self
end


--- Events

--- Handles the OnBirth event for the alive units set.
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnBirth( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self:_IsIncludeDCSUnit( Event.IniDCSUnit ) then
      self.DCSUnits[Event.IniDCSUnitName] = Event.IniDCSUnit 
      self.DCSUnitsAlive[Event.IniDCSUnitName] = Event.IniDCSUnit
      self.Units[Event.IniDCSUnitName] = UNIT:New( Event.IniDCSUnit )
      
      --if not self.DCSGroups[Event.IniDCSGroupName] then
      --  self.DCSGroups[Event.IniDCSGroupName] = Event.IniDCSGroupName
      --  self.DCSGroupsAlive[Event.IniDCSGroupName] = Event.IniDCSGroupName
      --  self.Groups[Event.IniDCSGroupName] = GROUP:New( Event.IniDCSGroup )
      --end
      self:_EventOnPlayerEnterUnit( Event )
    end
  end
end

--- Handles the OnDead or OnCrash event for alive units set.
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnDeadOrCrash( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self.DCSUnitsAlive[Event.IniDCSUnitName] then
      self.DCSUnits[Event.IniDCSUnitName] = nil 
      self.DCSUnitsAlive[Event.IniDCSUnitName] = nil
    end
  end
end

--- Handles the OnPlayerEnterUnit event to fill the active players table (with the unit filter applied).
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnPlayerEnterUnit( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self:_IsIncludeDCSUnit( Event.IniDCSUnit ) then
      if not self.PlayersAlive[Event.IniDCSUnitName] then
        self:E( { "Add player for unit:", Event.IniDCSUnitName, Event.IniDCSUnit:getPlayerName() } )
        self.PlayersAlive[Event.IniDCSUnitName] = Event.IniDCSUnit:getPlayerName()
        self.ClientsAlive[Event.IniDCSUnitName] = _DATABASE.Clients[ Event.IniDCSUnitName ]
      end
    end
  end
end

--- Handles the OnPlayerLeaveUnit event to clean the active players table.
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnPlayerLeaveUnit( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self:_IsIncludeDCSUnit( Event.IniDCSUnit ) then
      if self.PlayersAlive[Event.IniDCSUnitName] then
        self:E( { "Cleaning player for unit:", Event.IniDCSUnitName, Event.IniDCSUnit:getPlayerName() } )
        self.PlayersAlive[Event.IniDCSUnitName] = nil
        self.ClientsAlive[Event.IniDCSUnitName] = nil
      end
    end
  end
end

--- Iterators

--- Interate the DATABASE and call an interator function for the given set, providing the Object for each element within the set and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database.
-- @return #DATABASE self
function DATABASE:ForEach( IteratorFunction, arg, Set )
  self:F( arg )
  
  local function CoRoutine()
    local Count = 0
    for ObjectID, Object in pairs( Set ) do
        self:T2( Object )
        IteratorFunction( Object, unpack( arg ) )
        Count = Count + 1
        if Count % 10 == 0 then
          coroutine.yield( false )
        end    
    end
    return true
  end
  
  local co = coroutine.create( CoRoutine )
  
  local function Schedule()
  
    local status, res = coroutine.resume( co )
    self:T( { status, res } )
    
    if status == false then
      error( res )
    end
    if res == false then
      return true -- resume next time the loop
    end
    
    return false
  end

  local Scheduler = SCHEDULER:New( self, Schedule, {}, 0.001, 0.001, 0 )
  
  return self
end


--- Interate the DATABASE and call an interator function for each **alive** unit, providing the Unit and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive unit in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachDCSUnitAlive( IteratorFunction, ... )
  self:F( arg )
  
  self:ForEach( IteratorFunction, arg, self.DCSUnitsAlive )

  return self
end

--- Interate the DATABASE and call an interator function for each **alive** player, providing the Unit of the player and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachPlayer( IteratorFunction, ... )
  self:F( arg )
  
  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
  
  return self
end


--- Interate the DATABASE and call an interator function for each client, providing the Client to the function and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database. The function needs to accept a CLIENT parameter.
-- @return #DATABASE self
function DATABASE:ForEachClient( IteratorFunction, ... )
  self:F( arg )
  
  self:ForEach( IteratorFunction, arg, self.Clients )

  return self
end


function DATABASE:ScanEnvironment()
  self:F()

  self.Navpoints = {}
  self.Units = {}
  --Build routines.db.units and self.Navpoints
  for coa_name, coa_data in pairs(env.mission.coalition) do

    if (coa_name == 'red' or coa_name == 'blue') and type(coa_data) == 'table' then
      --self.Units[coa_name] = {}

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
          --self.Units[coa_name][countryName] = {}
          --self.Units[coa_name][countryName]["countryId"] = cntry_data.id

          if type(cntry_data) == 'table' then  --just making sure

            for obj_type_name, obj_type_data in pairs(cntry_data) do

              if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then --should be an unncessary check

                local category = obj_type_name

                if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then  --there's a group!

                  --self.Units[coa_name][countryName][category] = {}

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

  self:_RegisterDatabase()
  self:_RegisterPlayers()

  return self
end


---
-- @param #DATABASE self
-- @param DCSUnit#Unit DCSUnit
-- @return #DATABASE self
function DATABASE:_IsIncludeDCSUnit( DCSUnit )
  self:F( DCSUnit )
  local DCSUnitInclude = true

  if self.Filter.Coalitions then
    local DCSUnitCoalition = false
    for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
      self:T( { "Coalition:", DCSUnit:getCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
      if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == DCSUnit:getCoalition() then
        DCSUnitCoalition = true
      end
    end
    DCSUnitInclude = DCSUnitInclude and DCSUnitCoalition
  end
  
  if self.Filter.Categories then
    local DCSUnitCategory = false
    for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
      self:T( { "Category:", DCSUnit:getDesc().category, self.FilterMeta.Categories[CategoryName], CategoryName } )
      if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == DCSUnit:getDesc().category then
        DCSUnitCategory = true
      end
    end
    DCSUnitInclude = DCSUnitInclude and DCSUnitCategory
  end
  
  if self.Filter.Types then
    local DCSUnitType = false
    for TypeID, TypeName in pairs( self.Filter.Types ) do
      self:T( { "Type:", DCSUnit:getTypeName(), TypeName } )
      if TypeName == DCSUnit:getTypeName() then
        DCSUnitType = true
      end
    end
    DCSUnitInclude = DCSUnitInclude and DCSUnitType
  end
  
  if self.Filter.Countries then
    local DCSUnitCountry = false
    for CountryID, CountryName in pairs( self.Filter.Countries ) do
      self:T( { "Country:", DCSUnit:getCountry(), CountryName } )
      if country.id[CountryName] == DCSUnit:getCountry() then
        DCSUnitCountry = true
      end
    end
    DCSUnitInclude = DCSUnitInclude and DCSUnitCountry
  end

  if self.Filter.UnitPrefixes then
    local DCSUnitPrefix = false
    for UnitPrefixId, UnitPrefix in pairs( self.Filter.UnitPrefixes ) do
      self:T( { "Unit Prefix:", string.find( DCSUnit:getName(), UnitPrefix, 1 ), UnitPrefix } )
      if string.find( DCSUnit:getName(), UnitPrefix, 1 ) then
        DCSUnitPrefix = true
      end
    end
    DCSUnitInclude = DCSUnitInclude and DCSUnitPrefix
  end

  self:T( DCSUnitInclude )
  return DCSUnitInclude
end

---
-- @param #DATABASE self
-- @param DCSUnit#Unit DCSUnit
-- @return #DATABASE self
function DATABASE:_IsAliveDCSUnit( DCSUnit )
  self:F( DCSUnit )
  local DCSUnitAlive = false
  if DCSUnit and DCSUnit:isExist() and DCSUnit:isActive() then
    if self.DCSUnits[DCSUnit:getName()] then
      DCSUnitAlive = true
    end
  end
  self:T( DCSUnitAlive )
  return DCSUnitAlive
end

---
-- @param #DATABASE self
-- @param DCSGroup#Group DCSGroup
-- @return #DATABASE self
function DATABASE:_IsAliveDCSGroup( DCSGroup )
  self:F( DCSGroup )
  local DCSGroupAlive = false
  if DCSGroup and DCSGroup:isExist() then
    if self.DCSGroups[DCSGroup:getName()] then
      DCSGroupAlive = true
    end
  end
  self:T( DCSGroupAlive )
  return DCSGroupAlive
end


--- Traces the current database contents in the log ... (for debug reasons).
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:TraceDatabase()
  self:F()
  
  self:T( { "DCSUnits:", self.DCSUnits } )
  self:T( { "DCSUnitsAlive:", self.DCSUnitsAlive } )
end


--- The main include file for the MOOSE system.

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Database" )
Include.File( "Event" )

-- The order of the declarations is important here. Don't touch it.

--- Declare the event dispatcher based on the EVENT class
_EVENTDISPATCHER = EVENT:New() -- #EVENT

--- Declare the main database object, which is used internally by the MOOSE classes.
_DATABASE = DATABASE:New():ScanEnvironment() -- Database#DATABASE

--- Models time events calling event handing functions.
-- @module Scheduler
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Cargo" )
Include.File( "Message" )


--- The SCHEDULER class
-- @type SCHEDULER
-- @extends Base#BASE
SCHEDULER = {
  ClassName = "SCHEDULER",
}


--- SCHEDULER constructor.
-- @param #SCHEDULER self
-- @param #table TimeEventObject
-- @param #function TimeEventFunction
-- @param #table TimeEventFunctionArguments
-- @param #number StartSeconds
-- @param #number RepeatSecondsInterval
-- @param #number RandomizationFactor
-- @param #number StopSeconds
-- @return #SCHEDULER
function SCHEDULER:New( TimeEventObject, TimeEventFunction, TimeEventFunctionArguments, StartSeconds, RepeatSecondsInterval, RandomizationFactor, StopSeconds )
  local self = BASE:Inherit( self, BASE:New() )
  self:F( { TimeEventObject, TimeEventFunction, TimeEventFunctionArguments, StartSeconds, RepeatSecondsInterval, RandomizationFactor, StopSeconds } )

  self.TimeEventObject = TimeEventObject
  self.TimeEventFunction = TimeEventFunction
  self.TimeEventFunctionArguments = TimeEventFunctionArguments
  self.StartSeconds = StartSeconds

  if RepeatSecondsInterval then
    self.RepeatSecondsInterval = RepeatSecondsInterval
  else
    self.RepeatSecondsInterval = 0
  end

  if RandomizationFactor then
    self.RandomizationFactor = RandomizationFactor
  else
    self.RandomizationFactor = 0
  end

  if StopSeconds then
    self.StopSeconds = StopSeconds
  end
  
  self.Repeat = false

  self.StartTime = timer.getTime()
  
  self:Start()

  return self
end

function SCHEDULER:Scheduler()
  self:F( self.TimeEventFunctionArguments )
  
  local ErrorHandler = function( errmsg )

    env.info( "Error in SCHEDULER function:" .. errmsg )
    env.info( debug.traceback() )

    return errmsg
  end

  local Status, Result  
  if self.TimeEventObject then
    Status, Result = xpcall( function() return self.TimeEventFunction( self.TimeEventObject, unpack( self.TimeEventFunctionArguments ) ) end, ErrorHandler )
  else
    Status, Result = xpcall( function() return self.TimeEventFunction( unpack( self.TimeEventFunctionArguments ) ) end, ErrorHandler )
  end
  
  self:T( { Status, Result } )
  
  if Status and Status == true and Result and Result == true then
    if self.Repeat and ( not self.StopSeconds or ( self.StopSeconds and timer.getTime() <= self.StartTime + self.StopSeconds ) ) then
      timer.scheduleFunction(
        self.Scheduler,
        self,
        timer.getTime() + self.RepeatSecondsInterval + math.random( - ( self.RandomizationFactor * self.RepeatSecondsInterval / 2 ), ( self.RandomizationFactor * self.RepeatSecondsInterval  / 2 ) ) + 0.01
      )
    end
  end

end

function SCHEDULER:Start()
  self:F( self.TimeEventObject )
  
  self.Repeat = true
  timer.scheduleFunction( self.Scheduler, self, timer.getTime() + self.StartSeconds + .01 )
  
  return self
end

function SCHEDULER:Stop()
  self:F( self.TimeEventObject )
  
  self.Repeat = false
end






--- Scoring system for MOOSE.
-- This scoring class calculates the hits and kills that players make within a simulation session.
-- Scoring is calculated using a defined algorithm.
-- With a small change in MissionScripting.lua, the scoring can also be logged in a CSV file, that can then be uploaded
-- to a database or a BI tool to publish the scoring results to the player community.
-- @module Scoring
-- @author FlightControl


Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Menu" )
Include.File( "Group" )
Include.File( "Event" )


--- The Scoring class
-- @type SCORING
-- @field Players A collection of the current players that have joined the game.
-- @extends Base#BASE
SCORING = {
  ClassName = "SCORING",
  ClassID = 0,
  Players = {},
}

local _SCORINGCoalition =
  {
    [1] = "Red",
    [2] = "Blue",
  }

local _SCORINGCategory =
  {
    [Unit.Category.AIRPLANE] = "Plane",
    [Unit.Category.HELICOPTER] = "Helicopter",
    [Unit.Category.GROUND_UNIT] = "Vehicle",
    [Unit.Category.SHIP] = "Ship",
    [Unit.Category.STRUCTURE] = "Structure",
  }

--- Creates a new SCORING object to administer the scoring achieved by players.
-- @param #SCORING self
-- @param #string GameName The name of the game. This name is also logged in the CSV score file.
-- @return #SCORING self
-- @usage
-- -- Define a new scoring object for the mission Gori Valley.
-- ScoringObject = SCORING:New( "Gori Valley" )
function SCORING:New( GameName )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  if GameName then 
    self.GameName = GameName
  else
    error( "A game name must be given to register the scoring results" )
  end
  
  
  _EVENTDISPATCHER:OnDead( self._EventOnDeadOrCrash, self )
  _EVENTDISPATCHER:OnCrash( self._EventOnDeadOrCrash, self )
  _EVENTDISPATCHER:OnHit( self._EventOnHit, self )

  self.SchedulerId = routines.scheduleFunction( SCORING._FollowPlayersScheduled, { self }, 0, 5 )

  self:ScoreMenu()

  return self
  
end

--- Creates a score radio menu. Can be accessed using Radio -> F10.
-- @param #SCORING self
-- @return #SCORING self
function SCORING:ScoreMenu()
  self.Menu = SUBMENU:New( 'Scoring' )
  self.AllScoresMenu = COMMANDMENU:New( 'Score All Active Players', self.Menu, SCORING.ReportScoreAll, self )
  --- = COMMANDMENU:New('Your Current Score', ReportScore, SCORING.ReportScorePlayer, self )
  return self
end

--- Follows new players entering Clients within the DCSRTE.
-- TODO: Need to see if i can catch this also with an event. It will eliminate the schedule ...
function SCORING:_FollowPlayersScheduled()
  self:F3( "_FollowPlayersScheduled" )

  local ClientUnit = 0
  local CoalitionsData = { AlivePlayersRed = coalition.getPlayers(coalition.side.RED), AlivePlayersBlue = coalition.getPlayers(coalition.side.BLUE) }
  local unitId
  local unitData
  local AlivePlayerUnits = {}

  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    self:T3( { "_FollowPlayersScheduled", CoalitionData } )
    for UnitId, UnitData in pairs( CoalitionData ) do
      self:_AddPlayerFromUnit( UnitData )
    end
  end
end


--- Track  DEAD or CRASH events for the scoring.
-- @param #SCORING self
-- @param Event#EVENTDATA Event
function SCORING:_EventOnDeadOrCrash( Event )
  self:F( { Event } )

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

  if Event.IniDCSUnit then

    TargetUnit = Event.IniDCSUnit
    TargetUnitName = Event.IniDCSUnitName
    TargetGroup = Event.IniDCSGroup
    TargetGroupName = Event.IniDCSGroupName
    TargetPlayerName = TargetUnit:getPlayerName()

    TargetCoalition = TargetUnit:getCoalition()
    --TargetCategory = TargetUnit:getCategory()
    TargetCategory = TargetUnit:getDesc().category  -- Workaround
    TargetType = TargetUnit:getTypeName()

    TargetUnitCoalition = _SCORINGCoalition[TargetCoalition]
    TargetUnitCategory = _SCORINGCategory[TargetCategory]
    TargetUnitType = TargetType

    self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType } )
  end

  for PlayerName, PlayerData in pairs( self.Players ) do
    if PlayerData then -- This should normally not happen, but i'll test it anyway.
      self:T( "Something got killed" )

      -- Some variables
      local InitUnitName = PlayerData.UnitName
      local InitUnitType = PlayerData.UnitType
      local InitCoalition = PlayerData.UnitCoalition
      local InitCategory = PlayerData.UnitCategory
      local InitUnitCoalition = _SCORINGCoalition[InitCoalition]
      local InitUnitCategory = _SCORINGCategory[InitCategory]

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
          PlayerData.Penalty = PlayerData.Penalty + 25
          PlayerData.Kill[TargetCategory][TargetType].Penalty = PlayerData.Kill[TargetCategory][TargetType].Penalty + 25
          PlayerData.Kill[TargetCategory][TargetType].PenaltyKill = PlayerData.Kill[TargetCategory][TargetType].PenaltyKill + 1
          MESSAGE:New( "Player '" .. PlayerName .. "' killed a friendly " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " ..
            PlayerData.Kill[TargetCategory][TargetType].PenaltyKill .. " times. Penalty: -" .. PlayerData.Kill[TargetCategory][TargetType].Penalty ..
            ".  Score Total:" .. PlayerData.Score - PlayerData.Penalty,
            "", 5, "/PENALTY" .. PlayerName .. "/" .. InitUnitName ):ToAll()
          self:ScoreCSV( PlayerName, "KILL_PENALTY", 1, -125, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
        else
          PlayerData.Score = PlayerData.Score + 10
          PlayerData.Kill[TargetCategory][TargetType].Score = PlayerData.Kill[TargetCategory][TargetType].Score + 10
          PlayerData.Kill[TargetCategory][TargetType].ScoreKill = PlayerData.Kill[TargetCategory][TargetType].ScoreKill + 1
          MESSAGE:New( "Player '" .. PlayerName .. "' killed an enemy " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " ..
            PlayerData.Kill[TargetCategory][TargetType].ScoreKill .. " times. Score: " .. PlayerData.Kill[TargetCategory][TargetType].Score ..
            ".  Score Total:" .. PlayerData.Score - PlayerData.Penalty,
            "", 5, "/SCORE" .. PlayerName .. "/" .. InitUnitName ):ToAll()
          self:ScoreCSV( PlayerName, "KILL_SCORE", 1, 10, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
        end
        end
      end
    end
  end
end



--- Add a new player entering a Unit.
function SCORING:_AddPlayerFromUnit( UnitData )
  self:F( UnitData )

  if UnitData and UnitData:isExist() then
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

      -- for CategoryID, CategoryName in pairs( SCORINGCategory ) do
      -- self.Players[PlayerName].Hit[CategoryID] = {}
      -- self.Players[PlayerName].Kill[CategoryID] = {}
      -- end
      self.Players[PlayerName].HitPlayers = {}
      self.Players[PlayerName].HitUnits = {}
      self.Players[PlayerName].Score = 0
      self.Players[PlayerName].Penalty = 0
      self.Players[PlayerName].PenaltyCoalition = 0
      self.Players[PlayerName].PenaltyWarning = 0
    end

    if not self.Players[PlayerName].UnitCoalition then
      self.Players[PlayerName].UnitCoalition = UnitCoalition
    else
      if self.Players[PlayerName].UnitCoalition ~= UnitCoalition then
        self.Players[PlayerName].Penalty = self.Players[PlayerName].Penalty + 50
        self.Players[PlayerName].PenaltyCoalition = self.Players[PlayerName].PenaltyCoalition + 1
        MESSAGE:New( "Player '" .. PlayerName .. "' changed coalition from " .. _SCORINGCoalition[self.Players[PlayerName].UnitCoalition] .. " to " .. _SCORINGCoalition[UnitCoalition] ..
          "(changed " .. self.Players[PlayerName].PenaltyCoalition .. " times the coalition). 50 Penalty points added.",
          "",
          2,
          "/PENALTYCOALITION" .. PlayerName
        ):ToAll()
        self:ScoreCSV( PlayerName, "COALITION_PENALTY",  1, -50, self.Players[PlayerName].UnitName, _SCORINGCoalition[self.Players[PlayerName].UnitCoalition], _SCORINGCategory[self.Players[PlayerName].UnitCategory], self.Players[PlayerName].UnitType,
          UnitName, _SCORINGCoalition[UnitCoalition], _SCORINGCategory[UnitCategory], UnitData:getTypeName() )
      end
    end
    self.Players[PlayerName].UnitName = UnitName
    self.Players[PlayerName].UnitCoalition = UnitCoalition
    self.Players[PlayerName].UnitCategory = UnitCategory
    self.Players[PlayerName].UnitType = UnitTypeName

    if self.Players[PlayerName].Penalty > 100 then
      if self.Players[PlayerName].PenaltyWarning < 1 then
        MESSAGE:New( "Player '" .. PlayerName .. "': WARNING! If you continue to commit FRATRICIDE and have a PENALTY score higher than 150, you will be COURT MARTIALED and DISMISSED from this mission! \nYour total penalty is: " .. self.Players[PlayerName].Penalty,
          "",
          30,
          "/PENALTYCOALITION" .. PlayerName
        ):ToAll()
        self.Players[PlayerName].PenaltyWarning = self.Players[PlayerName].PenaltyWarning + 1
      end
    end

    if self.Players[PlayerName].Penalty > 150 then
      ClientGroup = GROUP:NewFromDCSUnit( UnitData )
      ClientGroup:Destroy()
      MESSAGE:New( "Player '" .. PlayerName .. "' committed FRATRICIDE, he will be COURT MARTIALED and is DISMISSED from this mission!",
        "",
        10,
        "/PENALTYCOALITION" .. PlayerName
      ):ToAll()
    end

  end
end


--- Registers Scores the players completing a Mission Task.
function SCORING:_AddMissionTaskScore( PlayerUnit, MissionName, Score )
  self:F( { PlayerUnit, MissionName, Score } )

  local PlayerName = PlayerUnit:getPlayerName()

  if not self.Players[PlayerName].Mission[MissionName] then
    self.Players[PlayerName].Mission[MissionName] = {}
    self.Players[PlayerName].Mission[MissionName].ScoreTask = 0
    self.Players[PlayerName].Mission[MissionName].ScoreMission = 0
  end

  self:T( PlayerName )
  self:T( self.Players[PlayerName].Mission[MissionName] )

  self.Players[PlayerName].Score = self.Players[PlayerName].Score + Score
  self.Players[PlayerName].Mission[MissionName].ScoreTask = self.Players[PlayerName].Mission[MissionName].ScoreTask + Score

  MESSAGE:New( "Player '" .. PlayerName .. "' has finished another Task in Mission '" .. MissionName .. "'. " ..
    Score .. " Score points added.",
    "", 20, "/SCORETASK" .. PlayerName ):ToAll()

  self:ScoreCSV( PlayerName, "TASK_" .. MissionName:gsub( ' ', '_' ), 1, Score, PlayerUnit:getName() )
end


--- Registers Mission Scores for possible multiple players that contributed in the Mission.
function SCORING:_AddMissionScore( MissionName, Score )
  self:F( { MissionName, Score } )

  for PlayerName, PlayerData in pairs( self.Players ) do

    if PlayerData.Mission[MissionName] then
      PlayerData.Score = PlayerData.Score + Score
      PlayerData.Mission[MissionName].ScoreMission = PlayerData.Mission[MissionName].ScoreMission + Score
      MESSAGE:New( "Player '" .. PlayerName .. "' has finished Mission '" .. MissionName .. "'. " ..
        Score .. " Score points added.",
        "", 20, "/SCOREMISSION" .. PlayerName ):ToAll()
      self:ScoreCSV( PlayerName, "MISSION_" .. MissionName:gsub( ' ', '_' ), 1, Score )
    end
  end
end

--- Handles the OnHit event for the scoring.
-- @param #SCORING self
-- @param Event#EVENTDATA Event
function SCORING:_EventOnHit( Event )
  self:F( { Event } )

  local InitUnit = nil
  local InitUnitName = ""
  local InitGroup = nil
  local InitGroupName = ""
  local InitPlayerName = nil

  local InitCoalition = nil
  local InitCategory = nil
  local InitType = nil
  local InitUnitCoalition = nil
  local InitUnitCategory = nil
  local InitUnitType = nil

  local TargetUnit = nil
  local TargetUnitName = ""
  local TargetGroup = nil
  local TargetGroupName = ""
  local TargetPlayerName = ""

  local TargetCoalition = nil
  local TargetCategory = nil
  local TargetType = nil
  local TargetUnitCoalition = nil
  local TargetUnitCategory = nil
  local TargetUnitType = nil

  if Event.IniDCSUnit then

    InitUnit = Event.IniDCSUnit
    InitUnitName = Event.IniDCSUnitName
    InitGroup = Event.IniDCSGroup
    InitGroupName = Event.IniDCSGroupName
    InitPlayerName = InitUnit:getPlayerName()

    InitCoalition = InitUnit:getCoalition()
    --TODO: Workaround Client DCS Bug
    --InitCategory = InitUnit:getCategory()
    InitCategory = InitUnit:getDesc().category
    InitType = InitUnit:getTypeName()

    InitUnitCoalition = _SCORINGCoalition[InitCoalition]
    InitUnitCategory = _SCORINGCategory[InitCategory]
    InitUnitType = InitType

    self:T( { InitUnitName, InitGroupName, InitPlayerName, InitCoalition, InitCategory, InitType , InitUnitCoalition, InitUnitCategory, InitUnitType } )
  end


  if Event.TgtDCSUnit then

    TargetUnit = Event.TgtDCSUnit
    TargetUnitName = Event.TgtDCSUnitName
    TargetGroup = Event.TgtDCSGroup
    TargetGroupName = Event.TgtDCSGroupName
    TargetPlayerName = TargetUnit:getPlayerName()

    TargetCoalition = TargetUnit:getCoalition()
    --TODO: Workaround Client DCS Bug
    --TargetCategory = TargetUnit:getCategory()
    TargetCategory = TargetUnit:getDesc().category
    TargetType = TargetUnit:getTypeName()

    TargetUnitCoalition = _SCORINGCoalition[TargetCoalition]
    TargetUnitCategory = _SCORINGCategory[TargetCategory]
    TargetUnitType = TargetType

    self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType, TargetUnitCoalition, TargetUnitCategory, TargetUnitType } )
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
        self.Players[InitPlayerName].Penalty = self.Players[InitPlayerName].Penalty + 10
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty + 10
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit + 1
        MESSAGE:New( "Player '" .. InitPlayerName .. "' hit a friendly " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " ..
          self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit .. " times. Penalty: -" .. self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty ..
          ".  Score Total:" .. self.Players[InitPlayerName].Score - self.Players[InitPlayerName].Penalty,
          "",
          2,
          "/PENALTY" .. InitPlayerName .. "/" .. InitUnitName
        ):ToAll()
        self:ScoreCSV( InitPlayerName, "HIT_PENALTY", 1, -25, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
      else
        self.Players[InitPlayerName].Score = self.Players[InitPlayerName].Score + 10
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score + 1
        self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit + 1
        MESSAGE:New( "Player '" .. InitPlayerName .. "' hit a target " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " ..
          self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit .. " times. Score: " .. self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score ..
          ".  Score Total:" .. self.Players[InitPlayerName].Score - self.Players[InitPlayerName].Penalty,
          "",
          2,
          "/SCORE" .. InitPlayerName .. "/" .. InitUnitName
        ):ToAll()
        self:ScoreCSV( InitPlayerName, "HIT_SCORE", 1, 1, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
      end
    end
    end
  elseif InitPlayerName == nil then -- It is an AI hitting a player???

  end
end


function SCORING:ReportScoreAll()

  env.info( "Hello World " )

  local ScoreMessage = ""
  local PlayerMessage = ""

  self:T( "Score Report" )

  for PlayerName, PlayerData in pairs( self.Players ) do
    if PlayerData then -- This should normally not happen, but i'll test it anyway.
      self:T( "Score Player: " .. PlayerName )

      -- Some variables
      local InitUnitCoalition = _SCORINGCoalition[PlayerData.UnitCoalition]
      local InitUnitCategory = _SCORINGCategory[PlayerData.UnitCategory]
      local InitUnitType = PlayerData.UnitType
      local InitUnitName = PlayerData.UnitName

      local PlayerScore = 0
      local PlayerPenalty = 0

      ScoreMessage = ":\n"

      local ScoreMessageHits = ""

      for CategoryID, CategoryName in pairs( _SCORINGCategory ) do
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
      for CategoryID, CategoryName in pairs( _SCORINGCategory ) do
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


function SCORING:ReportScorePlayer()

  env.info( "Hello World " )

  local ScoreMessage = ""
  local PlayerMessage = ""

  self:T( "Score Report" )

  for PlayerName, PlayerData in pairs( self.Players ) do
    if PlayerData then -- This should normally not happen, but i'll test it anyway.
      self:T( "Score Player: " .. PlayerName )

      -- Some variables
      local InitUnitCoalition = _SCORINGCoalition[PlayerData.UnitCoalition]
      local InitUnitCategory = _SCORINGCategory[PlayerData.UnitCategory]
      local InitUnitType = PlayerData.UnitType
      local InitUnitName = PlayerData.UnitName

      local PlayerScore = 0
      local PlayerPenalty = 0

      ScoreMessage = ""

      local ScoreMessageHits = ""

      for CategoryID, CategoryName in pairs( _SCORINGCategory ) do
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
      for CategoryID, CategoryName in pairs( _SCORINGCategory ) do
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


function SCORING:SecondsToClock(sSeconds)
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

--- Opens a score CSV file to log the scores.
-- @param #SCORING self
-- @param #string ScoringCSV
-- @return #SCORING self
-- @usage
-- -- Open a new CSV file to log the scores of the game Gori Valley. Let the name of the CSV file begin with "Player Scores".
-- ScoringObject = SCORING:New( "Gori Valley" )
-- ScoringObject:OpenCSV( "Player Scores" )
function SCORING:OpenCSV( ScoringCSV )
  self:F( ScoringCSV )
  
  if lfs and io and os then
    if ScoringCSV then
      self.ScoringCSV = ScoringCSV
      local fdir = lfs.writedir() .. [[Logs\]] .. self.ScoringCSV .. " " .. os.date( "%Y-%m-%d %H-%M-%S" ) .. ".csv"

      self.CSVFile, self.err = io.open( fdir, "w+" )
      if not self.CSVFile then
        error( "Error: Cannot open CSV file in " .. lfs.writedir() )
      end

      self.CSVFile:write( '"GameName","RunTime","Time","PlayerName","ScoreType","PlayerUnitCoaltion","PlayerUnitCategory","PlayerUnitType","PlayerUnitName","TargetUnitCoalition","TargetUnitCategory","TargetUnitType","TargetUnitName","Times","Score"\n' )
  
      self.RunTime = os.date("%y-%m-%d_%H-%M-%S")
    else
      error( "A string containing the CSV file name must be given." )
    end
  else
    self:E( "The MissionScripting.lua file has not been changed to allow lfs, io and os modules to be used..." )
  end
  return self
end


--- Registers a score for a player.
-- @param #SCORING self
-- @param #string PlayerName The name of the player.
-- @param #string ScoreType The type of the score.
-- @param #string ScoreTimes The amount of scores achieved.
-- @param #string ScoreAmount The score given.
-- @param #string PlayerUnitName The unit name of the player.
-- @param #string PlayerUnitCoalition The coalition of the player unit.
-- @param #string PlayerUnitCategory The category of the player unit.
-- @param #string PlayerUnitType The type of the player unit.
-- @param #string TargetUnitName The name of the target unit.
-- @param #string TargetUnitCoalition The coalition of the target unit.
-- @param #string TargetUnitCategory The category of the target unit.
-- @param #string TargetUnitType The type of the target unit.
-- @return #SCORING self
function SCORING:ScoreCSV( PlayerName, ScoreType, ScoreTimes, ScoreAmount, PlayerUnitName, PlayerUnitCoalition, PlayerUnitCategory, PlayerUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
  --write statistic information to file
  local ScoreTime = self:SecondsToClock( timer.getTime() )
  PlayerName = PlayerName:gsub( '"', '_' )

  if PlayerUnitName and PlayerUnitName ~= '' then
    local PlayerUnit = Unit.getByName( PlayerUnitName )

    if PlayerUnit then
      if not PlayerUnitCategory then
        --PlayerUnitCategory = SCORINGCategory[PlayerUnit:getCategory()]
        PlayerUnitCategory = _SCORINGCategory[PlayerUnit:getDesc().category]
      end

      if not PlayerUnitCoalition then
        PlayerUnitCoalition = _SCORINGCoalition[PlayerUnit:getCoalition()]
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

  if lfs and io and os then
    self.CSVFile:write(
      '"' .. self.GameName        .. '"' .. ',' ..
      '"' .. self.RunTime         .. '"' .. ',' ..
      ''  .. ScoreTime            .. ''  .. ',' ..
      '"' .. PlayerName           .. '"' .. ',' ..
      '"' .. ScoreType            .. '"' .. ',' ..
      '"' .. PlayerUnitCoalition  .. '"' .. ',' ..
      '"' .. PlayerUnitCategory   .. '"' .. ',' ..
      '"' .. PlayerUnitType       .. '"' .. ',' ..
      '"' .. PlayerUnitName       .. '"' .. ',' ..
      '"' .. TargetUnitCoalition  .. '"' .. ',' ..
      '"' .. TargetUnitCategory   .. '"' .. ',' ..
      '"' .. TargetUnitType       .. '"' .. ',' ..
      '"' .. TargetUnitName       .. '"' .. ',' ..
      ''  .. ScoreTimes           .. ''  .. ',' ..
      ''  .. ScoreAmount
    )

    self.CSVFile:write( "\n" )
  end
end


function SCORING:CloseCSV()
  if lfs and io and os then
    self.CSVFile:close()
  end
end

--- CARGO Classes
-- @module CARGO

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

--- Creates a new zone where cargo can be collected or deployed.
-- The zone functionality is useful to smoke or indicate routes for cargo pickups or deployments.
-- Provide the zone name as declared in the mission file into the CargoZoneName in the :New method.
-- An optional parameter is the CargoHostName, which is a Group declared with Late Activation switched on in the mission file.
-- The CargoHostName is the "host" of the cargo zone:
-- 
-- * It will smoke the zone position when a client is approaching the zone.
-- * Depending on the cargo type, it will assist in the delivery of the cargo by driving to and from the client.
-- 
-- @param #CARGO_ZONE self
-- @param #string CargoZoneName The name of the zone as declared within the mission editor.
-- @param #string CargoHostName The name of the Group "hosting" the zone. The Group MUST NOT be a static, and must be a "mobile" unit. 
function CARGO_ZONE:New( CargoZoneName, CargoHostName ) local self = BASE:Inherit( self, ZONE:New( CargoZoneName ) )
	self:F( { CargoZoneName, CargoHostName } )

	self.CargoZoneName = CargoZoneName
	self.SignalHeight = 2
	--self.CargoZone = trigger.misc.getZone( CargoZoneName )
	

	if CargoHostName then
		self.CargoHostName = CargoHostName
	end

	self:T( self.CargoZoneName )
	
	return self
end

function CARGO_ZONE:Spawn()
	self:F( self.CargoHostName )

  if self.CargoHostName then -- Only spawn a host in the zone when there is one given as a parameter in the New function.
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
  end

	return self
end

function CARGO_ZONE:GetHostUnit()
	self:F( self )

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
	self:F()

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
	self:F()

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
		
			local ZonePointVec3 = self:GetPointVec3( self.SignalHeight ) -- Get the zone position + the landheight + 2 meters
	  
			if self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.SMOKE.ID then

				trigger.action.smoke( ZonePointVec3, self.SignalColor.TRIGGERCOLOR  )
				Signalled = true

			elseif self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.FLARE.ID then
				trigger.action.signalFlare( ZonePointVec3, self.SignalColor.TRIGGERCOLOR, 0 )
				Signalled = false

			end
		end
	end
	
	return Signalled

end

function CARGO_ZONE:WhiteSmoke( SignalHeight )
	self:F()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.WHITE
	
	if SignalHeight then
	 self.SignalHeight = SignalHeight
	end

	return self
end

function CARGO_ZONE:BlueSmoke( SignalHeight )
	self:F()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.BLUE

  if SignalHeight then
   self.SignalHeight = SignalHeight
  end

	return self
end

function CARGO_ZONE:RedSmoke( SignalHeight )
	self:F()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.RED

  if SignalHeight then
   self.SignalHeight = SignalHeight
  end

	return self
end

function CARGO_ZONE:OrangeSmoke( SignalHeight )
	self:F()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.ORANGE

  if SignalHeight then
   self.SignalHeight = SignalHeight
  end

	return self
end

function CARGO_ZONE:GreenSmoke( SignalHeight )
	self:F()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.GREEN

  if SignalHeight then
   self.SignalHeight = SignalHeight
  end

	return self
end


function CARGO_ZONE:WhiteFlare( SignalHeight )
	self:F()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.WHITE

  if SignalHeight then
   self.SignalHeight = SignalHeight
  end

	return self
end

function CARGO_ZONE:RedFlare( SignalHeight )
	self:F()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.RED

  if SignalHeight then
   self.SignalHeight = SignalHeight
  end

	return self
end

function CARGO_ZONE:GreenFlare( SignalHeight )
	self:F()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.GREEN

  if SignalHeight then
   self.SignalHeight = SignalHeight
  end

	return self
end

function CARGO_ZONE:YellowFlare( SignalHeight )
	self:F()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.YELLOW

  if SignalHeight then
   self.SignalHeight = SignalHeight
  end

	return self
end


function CARGO_ZONE:GetCargoHostUnit()
	self:F( self )

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
	self:F()

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
	self:F( { CargoType, CargoName, CargoWeight } )


	self.CargoType = CargoType
	self.CargoName = CargoName
    self.CargoWeight = CargoWeight

	self:StatusNone()
	
	return self
end

function CARGO:Spawn( Client )
	self:F()

	return self

end

function CARGO:IsNear( Client, LandingZone )
	self:F()

	local Near = true
	
	return Near
	
end


function CARGO:IsLoadingToClient()
	self:F()

	if self:IsStatusLoading() then
		return self.CargoClient
	end
	
	return nil

end


function CARGO:IsLoadedInClient()
	self:F()

	if self:IsStatusLoaded() then
		return self.CargoClient
	end
	
	return nil

end


function CARGO:UnLoad( Client, TargetZoneName )
	self:F()

	self:StatusUnLoaded()

	return self
end

function CARGO:OnBoard( Client, LandingZone )
	self:F()
  
	local Valid = true
  
	self.CargoClient = Client
	local ClientUnit = Client:GetClientGroupDCSUnit()

	return Valid
end

function CARGO:OnBoarded( Client, LandingZone )
	self:F()

	local OnBoarded = true
  
	return OnBoarded
end

function CARGO:Load( Client )
	self:F()

	self:StatusLoaded( Client )

	return self
end

function CARGO:IsLandingRequired()
	self:F()
	return true
end

function CARGO:IsSlingLoad()
	self:F()
	return false
end


function CARGO:StatusNone()
	self:F()

	self.CargoClient = nil
	self.CargoStatus = CARGO.STATUS.NONE
	
	return self
end

function CARGO:StatusLoading( Client )
	self:F()

	self.CargoClient = Client
	self.CargoStatus = CARGO.STATUS.LOADING
	self:T( "Cargo " .. self.CargoName .. " loading to Client: " .. self.CargoClient:GetClientGroupName() )
	
	return self
end

function CARGO:StatusLoaded( Client )
	self:F()

	self.CargoClient = Client
	self.CargoStatus = CARGO.STATUS.LOADED
	self:T( "Cargo " .. self.CargoName .. " loaded in Client: " .. self.CargoClient:GetClientGroupName() )
	
	return self
end

function CARGO:StatusUnLoaded()
	self:F()

	self.CargoClient = nil
	self.CargoStatus = CARGO.STATUS.UNLOADED
	
	return self
end


function CARGO:IsStatusNone()
	self:F()

	return self.CargoStatus == CARGO.STATUS.NONE
end

function CARGO:IsStatusLoading()
	self:F()

	return self.CargoStatus == CARGO.STATUS.LOADING
end

function CARGO:IsStatusLoaded()
	self:F()

	return self.CargoStatus == CARGO.STATUS.LOADED
end

function CARGO:IsStatusUnLoaded()
	self:F()

	return self.CargoStatus == CARGO.STATUS.UNLOADED
end


CARGO_GROUP = {
	ClassName = "CARGO_GROUP"
}


function CARGO_GROUP:New( CargoType, CargoName, CargoWeight, CargoGroupTemplate, CargoZone ) 	local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )
	self:F( { CargoType, CargoName, CargoWeight, CargoGroupTemplate, CargoZone } )

	self.CargoSpawn = SPAWN:NewWithAlias( CargoGroupTemplate, CargoName )
	self.CargoZone = CargoZone

	CARGOS[self.CargoName] = self

	return self

end

function CARGO_GROUP:Spawn( Client )
	self:F( { Client } )

	local SpawnCargo = true
	
	if self:IsStatusNone() then
		local CargoGroup = Group.getByName( self.CargoName )
		if CargoGroup and CargoGroup:isExist() then
			SpawnCargo = false
		end
		
	elseif self:IsStatusLoading() then
	
		local Client = self:IsLoadingToClient()
		if Client and Client:GetDCSGroup() then
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
			local ClientGroup = Client:GetDCSGroup()
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
			self:T( self.CargoZone )
			self.CargoGroupName = self.CargoSpawn:SpawnInZone( self.CargoZone, true, 1 ):GetName()
		end
		self:StatusNone()	
	end
	
	self:T( { self.CargoGroupName, CARGOS[self.CargoName].CargoGroupName } )

	return self
end

function CARGO_GROUP:IsNear( Client, LandingZone )
	self:F()

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
	self:F()
  
	local Valid = true
  
	local ClientUnit = Client:GetClientGroupDCSUnit()
	
	local CarrierPos = ClientUnit:getPoint()
	local CarrierPosMove = ClientUnit:getPoint()
	local CarrierPosOnBoard = ClientUnit:getPoint()
	
	local CargoGroup = Group.getByName( self.CargoGroupName )

	local CargoUnit = CargoGroup:getUnit(1)
	local CargoPos = CargoUnit:getPoint()
	
	self.CargoInAir = CargoUnit:inAir()
	
	self:T( self.CargoInAir )

  -- Only move the group to the carrier when the cargo is not in the air 
  -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
  if not self.CargoInAir then    
	
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
  end
	
	self:StatusLoading( Client )
     
	return Valid
  
end


function CARGO_GROUP:OnBoarded( Client, LandingZone )
	self:F()

	local OnBoarded = false
  
  local CargoGroup = Group.getByName( self.CargoGroupName )

	if not self.CargoInAir then
  	if routines.IsPartOfGroupInRadius( CargoGroup, Client:ClientPosition(), 25 ) then
  		CargoGroup:destroy()
  		self:StatusLoaded( Client )
  		OnBoarded = true
  	end
  else
    CargoGroup:destroy()
    self:StatusLoaded( Client )
    OnBoarded = true
  end

	return OnBoarded
end


function CARGO_GROUP:UnLoad( Client, TargetZoneName )
	self:F()

	self:T( 'self.CargoName = ' .. self.CargoName ) 

	local CargoGroup = self.CargoSpawn:SpawnFromUnit( Client:GetClientGroupUnit(), 60, 30 )

	self.CargoGroupName = CargoGroup:GetName()
	self:T( 'self.CargoGroupName = ' .. self.CargoGroupName ) 
	
	CargoGroup:TaskRouteToZone( ZONE:New( TargetZoneName ), true )
	
	self:StatusUnLoaded()

	return self
end


CARGO_PACKAGE = {
	ClassName = "CARGO_PACKAGE"
}


function CARGO_PACKAGE:New( CargoType, CargoName, CargoWeight, CargoClient ) local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )
	self:F( { CargoType, CargoName, CargoWeight, CargoClient } )

	self.CargoClient = CargoClient
	
	CARGOS[self.CargoName] = self

	return self

end


function CARGO_PACKAGE:Spawn( Client )
	self:F( { self, Client } )

	-- this needs to be checked thoroughly

	local CargoClientGroup = self.CargoClient:GetDCSGroup()
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
		if CargoClientLoaded and CargoClientLoaded:GetDCSGroup() then
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
	self:F()

	local Near = false

	if self.CargoClient and self.CargoClient:GetDCSGroup() then
		self:T( self.CargoClient.ClientName )
		self:T( 'Client Exists.' )

		if routines.IsUnitInRadius( self.CargoClient:GetClientGroupDCSUnit(), Client:ClientPosition(), 150 ) then
			Near = true
		end
	end
	
	return Near
	
end


function CARGO_PACKAGE:OnBoard( Client, LandingZone, OnBoardSide )
	self:F()
  
	local Valid = true
  
	local ClientUnit = Client:GetClientGroupDCSUnit()
	
	local CarrierPos = ClientUnit:getPoint()
	local CarrierPosMove = ClientUnit:getPoint()
	local CarrierPosOnBoard = ClientUnit:getPoint()
	local CarrierPosMoveAway = ClientUnit:getPoint()
	
	local CargoHostGroup = self.CargoClient:GetDCSGroup()
	local CargoHostName = self.CargoClient:GetDCSGroup():getName()

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
	self:F()

	local OnBoarded = false
  
	if self.CargoClient and self.CargoClient:GetDCSGroup() then
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
	self:F()

	self:T( 'self.CargoName = ' .. self.CargoName ) 
	--self:T( 'self.CargoHostName = ' .. self.CargoHostName ) 
	
	--self.CargoSpawn:FromCarrier( Client:GetDCSGroup(), TargetZoneName, self.CargoHostName )
	self:StatusUnLoaded()

	return Cargo
end


CARGO_SLINGLOAD = {
	ClassName = "CARGO_SLINGLOAD"
}


function CARGO_SLINGLOAD:New( CargoType, CargoName, CargoWeight, CargoZone, CargoHostName, CargoCountryID )
	local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )
	self:F( { CargoType, CargoName, CargoWeight, CargoZone, CargoHostName, CargoCountryID } )

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
	self:F()
	return false
end


function CARGO_SLINGLOAD:IsSlingLoad()
	self:F()
	return true
end


function CARGO_SLINGLOAD:Spawn( Client )
	self:F( { self, Client } )

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
	self:F()

	local Near = false

	return Near
end


function CARGO_SLINGLOAD:IsInLandingZone( Client, LandingZone )
	self:F()

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
	self:F()
  
	local Valid = true
  
     
	return Valid
end


function CARGO_SLINGLOAD:OnBoarded( Client, LandingZone )
	self:F()

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
	self:F()

	self:T( 'self.CargoName = ' .. self.CargoName ) 
	self:T( 'self.CargoGroupName = ' .. self.CargoGroupName ) 
	
	self:StatusUnLoaded()

	return Cargo
end
--- Message System to display Messages for Clients and Coalitions or All.
-- Messages are grouped on the display panel per Category to improve readability for the players.
-- Messages are shown on the display panel for an amount of seconds, and will then disappear.
-- Messages are identified by an ID. The messages with the same ID belonging to the same category will be overwritten if they were still being displayed on the display panel.
-- Messages are created with MESSAGE:@{New}().
-- Messages are sent to Clients with MESSAGE:@{ToClient}().
-- Messages are sent to Coalitions with MESSAGE:@{ToCoalition}().
-- Messages are sent to All Players with MESSAGE:@{ToAll}().
-- @module Message

Include.File( "Base" )

--- The MESSAGE class
-- @type MESSAGE
MESSAGE = {
	ClassName = "MESSAGE", 
	MessageCategory = 0,
	MessageID = 0,
}


--- Creates a new MESSAGE object. Note that these MESSAGE objects are not yet displayed on the display panel. You must use the functions @{ToClient} or @{ToCoalition} or @{ToAll} to send these Messages to the respective recipients.
-- @param self
-- @param #string MessageText is the text of the Message.
-- @param #string MessageCategory is a string expressing the Category of the Message. Messages are grouped on the display panel per Category to improve readability.
-- @param #number MessageDuration is a number in seconds of how long the MESSAGE should be shown on the display panel.
-- @param #string MessageID is a string expressing the ID of the Message.
-- @return #MESSAGE
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
	local self = BASE:Inherit( self, BASE:New() )
	self:F( { MessageText, MessageCategory, MessageDuration, MessageID } )

  -- When no messagecategory is given, we don't show it as a title...	
	if MessageCategory and MessageCategory ~= "" then
    self.MessageCategory = MessageCategory .. ": "
  else
    self.MessageCategory = ""
  end

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
-- @param #MESSAGE self
-- @param Client#CLIENT Client is the Group of the Client.
-- @return #MESSAGE
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
	self:F( Client )

	if Client and Client:GetClientGroupID() then

		local ClientGroupID = Client:GetClientGroupID()
		self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
		trigger.action.outTextForGroup( ClientGroupID, self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration )
	end
	
	return self
end

--- Sends a MESSAGE to the Blue coalition.
-- @param #MESSAGE self 
-- @return #MESSAGE
-- @usage
-- -- Send a message created with the @{New} method to the BLUE coalition.
-- MessageBLUE = MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToBlue()
-- or
-- MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToBlue()
-- or
-- MessageBLUE = MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageBLUE:ToBlue()
function MESSAGE:ToBlue()
	self:F()

	self:ToCoalition( coalition.side.BLUE )
	
	return self
end

--- Sends a MESSAGE to the Red Coalition. 
-- @param #MESSAGE self
-- @return #MESSAGE
-- @usage
-- -- Send a message created with the @{New} method to the RED coalition.
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToRed()
-- or
-- MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToRed()
-- or
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageRED:ToRed()
function MESSAGE:ToRed( )
	self:F()

	self:ToCoalition( coalition.side.RED )
	
	return self
end

--- Sends a MESSAGE to a Coalition. 
-- @param #MESSAGE self
-- @param CoalitionSide needs to be filled out by the defined structure of the standard scripting engine @{coalition.side}. 
-- @return #MESSAGE
-- @usage
-- -- Send a message created with the @{New} method to the RED coalition.
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToCoalition( coalition.side.RED )
-- or
-- MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToCoalition( coalition.side.RED )
-- or
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageRED:ToCoalition( coalition.side.RED )
function MESSAGE:ToCoalition( CoalitionSide )
	self:F( CoalitionSide )

	if CoalitionSide then
		self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
		trigger.action.outTextForCoalition( CoalitionSide, self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration )
	end
	
	return self
end

--- Sends a MESSAGE to all players. 
-- @param #MESSAGE self
-- @return #MESSAGE
-- @usage
-- -- Send a message created to all players.
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" ):ToAll()
-- or
-- MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" ):ToAll()
-- or
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" )
-- MessageAll:ToAll()
function MESSAGE:ToAll()
	self:F()

	self:ToCoalition( coalition.side.RED )
	self:ToCoalition( coalition.side.BLUE )

	return self
end



--- The MESSAGEQUEUE class
-- @type MESSAGEQUEUE
MESSAGEQUEUE = {
	ClientGroups = {},
	CoalitionSides = {}
}

function MESSAGEQUEUE:New( RefreshInterval )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( { RefreshInterval } )
	
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
-- @module STAGE
-- @author Flightcontrol

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )

--- The STAGE class
-- @type
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
	self:F()
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
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGEBRIEF:Execute( Mission, Client, Task )
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )
	self:F()
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
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGESTART:Execute( Mission, Client, Task )
	self:F()
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )
	if Task.TaskBriefing then
		Client:Message( Task.TaskBriefing, 30,  Mission.Name .. "/Stage", "Command" )
	else
		Client:Message( 'Task ' .. Task.TaskNumber .. '.', 30, Mission.Name .. "/Stage", "Command" )
	end
	self.StageStartTime = timer.getTime()
	return Valid 
end

function STAGESTART:Validate( Mission, Client, Task )
	self:F()
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
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGE_CARGO_LOAD:Execute( Mission, Client, Task )
	self:F()
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
	self:F()
	local Valid = STAGE:Validate( Mission, Client, Task )

	return 1
end


STAGE_CARGO_INIT = {
  ClassName = "STAGE_CARGO_INIT"
}

function STAGE_CARGO_INIT:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGE_CARGO_INIT:Execute( Mission, Client, Task )
	self:F()
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
	self:F()
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
	self:F()
	self.StageType = 'CLIENT'
	self.MessageSwitch = true
	return self
end


--- Execute the routing.
-- @param #STAGEROUTE self
-- @param Mission#MISSION Mission
-- @param Client#CLIENT Client
-- @param Task#TASK Task
function STAGEROUTE:Execute( Mission, Client, Task )
	self:F()
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )

	local RouteMessage = "Fly to: "
	self:T( Task.LandingZones )
	for LandingZoneID, LandingZoneName in pairs( Task.LandingZones.LandingZoneNames ) do
		RouteMessage = RouteMessage .. "\n     " .. LandingZoneName .. ' at ' .. routines.getBRStringZone( { zone = LandingZoneName, ref = Client:GetClientGroupDCSUnit():getPoint(), true, true } ) .. ' km.'
	end
	
	if Client:IsMultiSeated() then
    Client:Message( RouteMessage, self.MSG.TIME, Mission.Name .. "/StageRoute", "Co-Pilot", 20 )
	else
    Client:Message( RouteMessage, self.MSG.TIME, Mission.Name .. "/StageRoute", "Command", 20 )
  end	
	

	if Mission.MissionReportFlash and Client:IsTransport() then
		Client:ShowCargo()
	end

	return Valid
end

function STAGEROUTE:Validate( Mission, Client, Task )
	self:F()
	local Valid = STAGE:Validate( Mission, Client, Task )
	
	-- check if the Client is in the landing zone
	self:T( Task.LandingZones.LandingZoneNames )
	Task.CurrentLandingZoneName = routines.IsUnitNearZonesRadius( Client:GetClientGroupDCSUnit(), Task.LandingZones.LandingZoneNames, 500 )
	
	if  Task.CurrentLandingZoneName then

		Task.CurrentLandingZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName].CargoZone
		Task.CurrentCargoZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName]

		if Task.CurrentCargoZone then 
			if not Task.Signalled then
				Task.Signalled = Task.CurrentCargoZone:Signal() 
			end
		end

    self:T( 1 )
		return 1
	end
  
  self:T( 0 )
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
	self:F()
	self.StageType = 'CLIENT'
	return self
end

--- Execute the landing coordination.
-- @param #STAGELANDING self
-- @param Mission#MISSION Mission
-- @param Client#CLIENT Client
-- @param Task#TASK Task
function STAGELANDING:Execute( Mission, Client, Task )
	self:F()
 
  if Client:IsMultiSeated() then
  	Client:Message( "We have arrived at the landing zone.", self.MSG.TIME, Mission.Name .. "/StageArrived", "Co-Pilot", 10 )
  else
    Client:Message( "You have arrived at the landing zone.", self.MSG.TIME, Mission.Name .. "/StageArrived", "Command", 10 )
  end

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

    local Host = "Command"
    if Task.HostUnitName then
      Host = Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")"
    else
      if Client:IsMultiSeated() then
        Host = "Co-Pilot"
      end
    end
		
		Client:Message( HostMessage, self.MSG.TIME, Mission.Name .. "/STAGELANDING.EXEC." .. Host, Host, 10 )
		
	end
end

function STAGELANDING:Validate( Mission, Client, Task )
	self:F()
  
	Task.CurrentLandingZoneName = routines.IsUnitNearZonesRadius( Client:GetClientGroupDCSUnit(), Task.LandingZones.LandingZoneNames, 500 )
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
    self:T( -1 )
		return -1
	end
  
	
	local DCSUnitVelocityVec3 = Client:GetClientGroupDCSUnit():getVelocity()
	local DCSUnitVelocity = ( DCSUnitVelocityVec3.x ^2 + DCSUnitVelocityVec3.y ^2 + DCSUnitVelocityVec3.z ^2 ) ^ 0.5
	
	local DCSUnitPointVec3 = Client:GetClientGroupDCSUnit():getPoint()
	local LandHeight = land.getHeight( { x = DCSUnitPointVec3.x, y = DCSUnitPointVec3.z } ) 
  local DCSUnitHeight = DCSUnitPointVec3.y - LandHeight
	
  self:T( { Task.IsLandingRequired, Client:GetClientGroupDCSUnit():inAir() } )
  if Task.IsLandingRequired and not Client:GetClientGroupDCSUnit():inAir() then
    self:T( 1 )
    Task.IsInAirTestRequired = true
    return 1
  end
  
	self:T( { DCSUnitVelocity, DCSUnitHeight, LandHeight, Task.CurrentCargoZone.SignalHeight } )
	if Task.IsLandingRequired and DCSUnitVelocity <= 0.05 and DCSUnitHeight <= Task.CurrentCargoZone.SignalHeight then
    self:T( 1 )
    Task.IsInAirTestRequired = false
    return 1
	end

  self:T( 0 )
	return 0
end

STAGELANDED = {
  ClassName = "STAGELANDED",
  MSG = { ID = "Land", TIME = 10 },
  Name = "Landed",
  MenusAdded = false
}

function STAGELANDED:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGELANDED:Execute( Mission, Client, Task )
	self:F()

	if Task.IsLandingRequired then

	  local Host = "Command"
	  if Task.HostUnitName then
	    Host = Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")"
  	else
      if Client:IsMultiSeated() then
        Host = "Co-Pilot"
      end
    end

    Client:Message( 'You have landed within the landing zone. Use the radio menu (F10) to ' .. Task.TEXT[1]  .. ' the ' .. Task.CargoType .. '.', 
                    self.MSG.TIME,  Mission.Name .. "/STAGELANDED.EXEC" .. Host, Host )

  	if not self.MenusAdded then
			Task.Cargo = nil
			Task:RemoveCargoMenus( Client )
			Task:AddCargoMenus( Client, CARGOS, 250 )
		end
	end
end



function STAGELANDED:Validate( Mission, Client, Task )
	self:F()

	if not routines.IsUnitNearZonesRadius( Client:GetClientGroupDCSUnit(), Task.CurrentLandingZoneName, 500 ) then
	    self:T( "Client is not anymore in the landing zone, go back to stage Route, and remove cargo menus." )
		Task.Signalled = false 
		Task:RemoveCargoMenus( Client )
    self:T( -2 )
		return -2
	end

  local DCSUnitVelocityVec3 = Client:GetClientGroupDCSUnit():getVelocity()
  local DCSUnitVelocity = ( DCSUnitVelocityVec3.x ^2 + DCSUnitVelocityVec3.y ^2 + DCSUnitVelocityVec3.z ^2 ) ^ 0.5
  
  local DCSUnitPointVec3 = Client:GetClientGroupDCSUnit():getPoint()
  local LandHeight = land.getHeight( { x = DCSUnitPointVec3.x, y = DCSUnitPointVec3.z } ) 
  local DCSUnitHeight = DCSUnitPointVec3.y - LandHeight
  
  self:T( { Task.IsLandingRequired, Client:GetClientGroupDCSUnit():inAir() } )
  if Task.IsLandingRequired and Task.IsInAirTestRequired == true and Client:GetClientGroupDCSUnit():inAir() then
    self:T( "Client went back in the air. Go back to stage Landing." )
    self:T( -1 )
    return -1
  end
  
  self:T( { DCSUnitVelocity, DCSUnitHeight, LandHeight, Task.CurrentCargoZone.SignalHeight } )
  if Task.IsLandingRequired and Task.IsInAirTestRequired == false and DCSUnitVelocity >= 2 and DCSUnitHeight >= Task.CurrentCargoZone.SignalHeight then
    self:T( "It seems the Client went back in the air and over the boundary limits. Go back to stage Landing." )
    self:T( -1 )
    return -1
  end
  
    -- Wait until cargo is selected from the menu.
	if Task.IsLandingRequired then 
		if not Task.Cargo then
		  self:T( 0 )
			return 0
		end
	end

  self:T( 1 )
	return 1
end

STAGEUNLOAD = {
  ClassName = "STAGEUNLOAD",
  MSG = { ID = "Unload", TIME = 10 },
  Name = "Unload"
}

function STAGEUNLOAD:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

--- Coordinate UnLoading
-- @param #STAGEUNLOAD self
-- @param Mission#MISSION Mission
-- @param Client#CLIENT Client
-- @param Task#TASK Task
function STAGEUNLOAD:Execute( Mission, Client, Task )
	self:F()
	
	if Client:IsMultiSeated() then
  	Client:Message( 'The ' .. Task.CargoType .. ' are being ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
                    self.MSG.TIME,  Mission.Name .. "/StageUnLoad", "Co-Pilot" )
  else
    Client:Message( 'You are unloading the ' .. Task.CargoType .. ' ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
                    self.MSG.TIME,  Mission.Name .. "/StageUnLoad", "Command" )
  end
	Task:RemoveCargoMenus( Client )
end

function STAGEUNLOAD:Executing( Mission, Client, Task )
	self:F()
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

--- Validate UnLoading
-- @param #STAGEUNLOAD self
-- @param Mission#MISSION Mission
-- @param Client#CLIENT Client
-- @param Task#TASK Task
function STAGEUNLOAD:Validate( Mission, Client, Task )
	self:F()
	env.info( 'STAGEUNLOAD:Validate()' )
  
  if routines.IsUnitNearZonesRadius( Client:GetClientGroupDCSUnit(), Task.CurrentLandingZoneName, 500 ) then
  else
    Task.ExecuteStage = _TransportExecuteStage.FAILED
    Task:RemoveCargoMenus( Client )
    if Client:IsMultiSeated() then
      Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
  	                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Co-Pilot" )
  	else
      Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
                    _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Command" )
  	end
    return 1
  end
  
  if not Client:GetClientGroupDCSUnit():inAir() then
  else
    Task.ExecuteStage = _TransportExecuteStage.FAILED
    Task:RemoveCargoMenus( Client )
    if Client:IsMultiSeated() then
      Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
  	                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Co-Pilot" )
	  else
      Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
                    _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Command" )
	  end
    return 1
  end
  
  if  Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
    if Client:IsMultiSeated() then
      Client:Message( 'The ' .. Task.CargoType .. ' have been sucessfully ' .. Task.TEXT[3] .. '  within the landing zone.', _TransportStageMsgTime.DONE,  Mission.Name .. "/Stage", "Co-Pilot" )
    else
      Client:Message( 'The ' .. Task.CargoType .. ' have been sucessfully ' .. Task.TEXT[3] .. '  within the landing zone.', _TransportStageMsgTime.DONE,  Mission.Name .. "/Stage", "Command" )
    end
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
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGELOAD:Execute( Mission, Client, Task )
	self:F()
	
	if not Task.IsSlingLoad then
 
    local Host = "Command"
    if Task.HostUnitName then
      Host = Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")"
    else
      if Client:IsMultiSeated() then
        Host = "Co-Pilot"
      end
    end

		Client:Message( 'The ' .. Task.CargoType .. ' are being ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
						_TransportStageMsgTime.EXECUTING,  Mission.Name .. "/STAGELOAD.EXEC." .. Host, Host )

		-- Route the cargo to the Carrier
		
		Task.Cargo:OnBoard( Client, Task.CurrentCargoZone, Task.OnBoardSide )
		Task.ExecuteStage = _TransportExecuteStage.EXECUTING
	else
		Task.ExecuteStage = _TransportExecuteStage.EXECUTING
	end
end

function STAGELOAD:Executing( Mission, Client, Task )
	self:F()

	-- If the Cargo is ready to be loaded, load it into the Client.

  local Host = "Command"
  if Task.HostUnitName then
    Host = Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")"
  else
    if Client:IsMultiSeated() then
      Host = "Co-Pilot"
    end
  end
		
	if not Task.IsSlingLoad then
		self:T( Task.Cargo.CargoName)
		
		if Task.Cargo:OnBoarded( Client, Task.CurrentCargoZone ) then

			-- Load the Cargo onto the Client
			Task.Cargo:Load( Client )
		
			-- Message to the pilot that cargo has been loaded.
			Client:Message( "The cargo " .. Task.Cargo.CargoName .. " has been loaded in our helicopter.", 
							20, Mission.Name .. "/STAGELANDING.LOADING1."  .. Host, Host )
			Task.ExecuteStage = _TransportExecuteStage.SUCCESS
			
			Client:ShowCargo()
		end
	else
		Client:Message( "Hook the " .. Task.CargoNames .. " onto the helicopter " .. Task.TEXT[3] .. " within the landing zone.", 
						_TransportStageMsgTime.EXECUTING,  Mission.Name .. "/STAGELOAD.LOADING.1."  .. Host, Host , 10 )
		for CargoID, Cargo in pairs( CARGOS ) do
			self:T( "Cargo.CargoName = " .. Cargo.CargoName )
			
			if Cargo:IsSlingLoad() then
				local CargoStatic = StaticObject.getByName( Cargo.CargoStaticName )
				if CargoStatic then
					self:T( "Cargo is found in the DCS simulator.")
					local CargoStaticPosition = CargoStatic:getPosition().p
					self:T( "Cargo Position x = " .. CargoStaticPosition.x .. ", y = " ..  CargoStaticPosition.y .. ", z = " ..  CargoStaticPosition.z )
					local CargoStaticHeight = routines.GetUnitHeight( CargoStatic )
					if CargoStaticHeight > 5 then
						self:T( "Cargo is airborne.")
						Cargo:StatusLoaded()
						Task.Cargo = Cargo
						Client:Message( 'The Cargo has been successfully hooked onto the helicopter and is now being sling loaded. Fly outside the landing zone.', 
										self.MSG.TIME,  Mission.Name .. "/STAGELANDING.LOADING.2."  .. Host, Host  )
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
	self:F()

	self:T( "Task.CurrentLandingZoneName = " .. Task.CurrentLandingZoneName )

  local Host = "Command"
  if Task.HostUnitName then
    Host = Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")"
  else
    if Client:IsMultiSeated() then
      Host = "Co-Pilot"
    end
  end

 	if not Task.IsSlingLoad then
		if not routines.IsUnitNearZonesRadius( Client:GetClientGroupDCSUnit(), Task.CurrentLandingZoneName, 500 ) then
			Task:RemoveCargoMenus( Client )
			Task.ExecuteStage = _TransportExecuteStage.FAILED
			Task.CargoName = nil 
			Client:Message( "The " .. Task.CargoType .. " loading has been aborted. You flew outside the pick-up zone while loading. ", 
							self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.1." .. Host, Host )
      self:T( -1 )
			return -1
		end

    local DCSUnitVelocityVec3 = Client:GetClientGroupDCSUnit():getVelocity()
    local DCSUnitVelocity = ( DCSUnitVelocityVec3.x ^2 + DCSUnitVelocityVec3.y ^2 + DCSUnitVelocityVec3.z ^2 ) ^ 0.5
    
    local DCSUnitPointVec3 = Client:GetClientGroupDCSUnit():getPoint()
    local LandHeight = land.getHeight( { x = DCSUnitPointVec3.x, y = DCSUnitPointVec3.z } ) 
    local DCSUnitHeight = DCSUnitPointVec3.y - LandHeight
    
    self:T( { Task.IsLandingRequired, Client:GetClientGroupDCSUnit():inAir() } )
    if Task.IsLandingRequired and Task.IsInAirTestRequired == true and Client:GetClientGroupDCSUnit():inAir() then
      Task:RemoveCargoMenus( Client )
      Task.ExecuteStage = _TransportExecuteStage.FAILED
      Task.CargoName = nil 
      Client:Message( "The " .. Task.CargoType .. " loading has been aborted. Re-start the " .. Task.TEXT[3] .. " process. Don't fly outside the pick-up zone.", 
              self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.1." .. Host, Host )
      self:T( -1 )
      return -1
    end
    
    self:T( { DCSUnitVelocity, DCSUnitHeight, LandHeight, Task.CurrentCargoZone.SignalHeight } )
    if Task.IsLandingRequired and Task.IsInAirTestRequired == false and DCSUnitVelocity >= 2 and DCSUnitHeight >= Task.CurrentCargoZone.SignalHeight then
      Task:RemoveCargoMenus( Client )
      Task.ExecuteStage = _TransportExecuteStage.FAILED
      Task.CargoName = nil 
      Client:Message( "The " .. Task.CargoType .. " loading has been aborted. Re-start the " .. Task.TEXT[3] .. " process. Don't fly outside the pick-up zone.", 
              self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.1." .. Host, Host )
      self:T( -1 )
      return -1
    end

		if Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
			Task:RemoveCargoMenus( Client )
			Client:Message( "Good Job. The " .. Task.CargoType .. " has been sucessfully " .. Task.TEXT[3] .. " within the landing zone.", 
							self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.3." .. Host, Host )
			Task.MissionTask:AddGoalCompletion( Task.MissionTask.GoalVerb, Task.CargoName, 1 )
      self:T( 1 )
			return 1
		end

	else
		if Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
			CargoStatic = StaticObject.getByName( Task.Cargo.CargoStaticName )
			if CargoStatic and not routines.IsStaticInZones( CargoStatic, Task.CurrentLandingZoneName ) then
				Client:Message( "Good Job. The " .. Task.CargoType .. " has been sucessfully " .. Task.TEXT[3] .. " and flown outside of the landing zone.", 
								self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.4." .. Host, Host )
				Task.MissionTask:AddGoalCompletion( Task.MissionTask.GoalVerb, Task.Cargo.CargoName, 1 )
        self:T( 1 )
				return 1
			end
		end
	
	end
  
 
  self:T( 0 )
	return 0
end


STAGEDONE = {
  ClassName = "STAGEDONE",
  MSG = { ID = "Done", TIME = 10 },
  Name = "Done"
}

function STAGEDONE:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'AI'
	return self
end

function STAGEDONE:Execute( Mission, Client, Task )
	self:F()

end

function STAGEDONE:Validate( Mission, Client, Task )
	self:F()

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
	self:F()
	self.StageType = 'CLIENT'
	return self
end


--- Execute Arrival
-- @param #STAGEARRIVE self
-- @param Mission#MISSION Mission
-- @param Client#CLIENT Client
-- @param Task#TASK Task
function STAGEARRIVE:Execute( Mission, Client, Task )
	self:F()
 
  if Client:IsMultiSeated() then
    Client:Message( 'We have arrived at ' .. Task.CurrentLandingZoneName .. ".", self.MSG.TIME,  Mission.Name .. "/Stage", "Co-Pilot" )
  else
    Client:Message( 'We have arrived at ' .. Task.CurrentLandingZoneName .. ".", self.MSG.TIME,  Mission.Name .. "/Stage", "Command" )
  end  

end

function STAGEARRIVE:Validate( Mission, Client, Task )
	self:F()
  
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
	self:F()
	self.StageType = 'AI'
	return self
end

--function STAGEGROUPSDESTROYED:Execute( Mission, Client, Task )
-- 
--	Client:Message( 'Task: Still ' .. DestroyGroupSize .. " of " .. Task.DestroyGroupCount .. " " .. Task.DestroyGroupType .. " to be destroyed!", self.MSG.TIME,  Mission.Name .. "/Stage" )
--
--end

function STAGEGROUPSDESTROYED:Validate( Mission, Client, Task )
	self:F()
 
	if Task.MissionTask:IsGoalReached() then
		return 1
	else
		return 0
	end
end

function STAGEGROUPSDESTROYED:Execute( Mission, Client, Task )
	self:F()
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
	self:F2()

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
	self:F2()

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
	self:F2()
	self.TaskDone = true
end

--- Returns if a TASK is done.
-- @return bool
function TASK:IsDone()
	self:F2( self.TaskDone )
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
	self:F2( self.TaskFailed )
	return self.TaskFailed
end

function TASK:Reset( Mission, Client )
	self:F2()
	self.ExecuteStage = _TransportExecuteStage.NONE
end

--- Returns the Goals of a TASK
-- @return @table Goals
function TASK:GetGoals()
	return self.GoalTasks
end

--- Returns if a TASK has Goal(s).
-- @param #TASK self
-- @param #string GoalVerb is the name of the Goal of the TASK.
-- @return bool
function TASK:Goal( GoalVerb )
	self:F2( { GoalVerb } )
	if not GoalVerb then
		GoalVerb = self.GoalVerb
	end
	self:T2( {self.GoalTasks[GoalVerb] } )
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
	self:F2( { GoalTotal, GoalVerb } )
	
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
	self:F2( { GoalVerb } )
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
	self:F2()
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
	self:F2( { GoalCountIncrease, GoalVerb } )
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
	self:F2()
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
	self:F2()
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
function TASK:IsGoalReached()
  self:F2()

	local GoalReached = true

	for GoalVerb, Goals in pairs( self.GoalTasks ) do
		self:T2( { "GoalVerb", GoalVerb } )
		if self:Goal( GoalVerb ) then
			local GoalToDo = self:GetGoalTotal( GoalVerb ) - self:GetGoalCount( GoalVerb )
			self:T2( "GoalToDo = " .. GoalToDo )
			if GoalToDo <= 0 then
			else
				GoalReached = false
				break
			end
		else
			break
		end
	end
	
	self:T( { GoalReached, self.GoalTasks } )
	return GoalReached
end

--- Adds an Additional Goal for the TASK to be achieved.
-- @param string GoalVerb is the name of the Goal of the TASK.
-- @param string GoalTask is a text describing the Goal of the TASK to be achieved.
-- @param number GoalIncrease is a number by which the Goal achievement is increasing.
function TASK:AddGoalCompletion( GoalVerb, GoalTask, GoalIncrease )
	self:F2( { GoalVerb, GoalTask, GoalIncrease } )

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
	self:F2( { GoalVerb } )
	
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
--- A GOHOMETASK orchestrates the travel back to the home base, which is a specific zone defined within the ME.
-- @module GOHOMETASK

Include.File("Task")

--- The GOHOMETASK class
-- @type
GOHOMETASK = {
  ClassName = "GOHOMETASK",
}

--- Creates a new GOHOMETASK.
-- @param table{string,...}|string LandingZones Table of Landing Zone names where Home(s) are located.
-- @return GOHOMETASK
function GOHOMETASK:New( LandingZones )
  local self = BASE:Inherit( self, TASK:New() )
	self:F( { LandingZones } )
  local Valid = true
  
  Valid = routines.ValidateZone( LandingZones, "LandingZones", Valid )
    
  if  Valid then
    self.Name = 'Fly Home'
    self.TaskBriefing = "Task: Fly back to your home base. Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to your home base."
	if type( LandingZones ) == "table" then
		self.LandingZones = LandingZones
	else
		self.LandingZones = { LandingZones }
	end
    self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGEARRIVE:New(), STAGEDONE:New() }
		self.SetStage( self, 1 )
  end
  
  return self
end
--- A DESTROYBASETASK will monitor the destruction of Groups and Units. This is a BASE class, other classes are derived from this class.
-- @module DESTROYBASETASK
-- @see DESTROYGROUPSTASK
-- @see DESTROYUNITTYPESTASK
-- @see DESTROY_RADARS_TASK

Include.File("Task")

--- The DESTROYBASETASK class
-- @type DESTROYBASETASK
DESTROYBASETASK = {
  ClassName = "DESTROYBASETASK",
  Destroyed = 0,
  GoalVerb = "Destroy",
  DestroyPercentage = 100,
}

--- Creates a new DESTROYBASETASK.
-- @param #DESTROYBASETASK self
-- @param #string DestroyGroupType Text describing the group to be destroyed. f.e. "Radar Installations", "Ships", "Vehicles", "Command Centers".
-- @param #string DestroyUnitType Text describing the unit types to be destroyed. f.e. "SA-6", "Row Boats", "Tanks", "Tents".
-- @param #list<#string> DestroyGroupPrefixes Table of Prefixes of the Groups to be destroyed before task is completed.
-- @param #number DestroyPercentage defines the %-tage that needs to be destroyed to achieve mission success. eg. If in the Group there are 10 units, then a value of 75 would require 8 units to be destroyed from the Group to complete the @{TASK}.
-- @return DESTROYBASETASK
function DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupPrefixes, DestroyPercentage )
	local self = BASE:Inherit( self, TASK:New() )
	self:F()
	
	self.Name = 'Destroy'
	self.Destroyed = 0
	self.DestroyGroupPrefixes = DestroyGroupPrefixes
	self.DestroyGroupType = DestroyGroupType
	self.DestroyUnitType = DestroyUnitType
	if DestroyPercentage then
  	self.DestroyPercentage = DestroyPercentage
  end
	self.TaskBriefing = "Task: Destroy " .. DestroyGroupType .. "."
    self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEGROUPSDESTROYED:New(), STAGEDONE:New() }
	self.SetStage( self, 1 )

	return self
end

--- Handle the S_EVENT_DEAD events to validate the destruction of units for the task monitoring.
-- @param #DESTROYBASETASK self
-- @param Event#EVENTDATA Event structure of MOOSE.
function DESTROYBASETASK:EventDead( Event )
	self:F( { Event } )
	
	if Event.IniDCSUnit then
		local DestroyUnit = Event.IniDCSUnit
		local DestroyUnitName = Event.IniDCSUnitName
		local DestroyGroup = Event.IniDCSGroup
		local DestroyGroupName = Event.IniDCSGroupName

    --TODO: I need to fix here if 2 groups in the mission have a similar name with GroupPrefix equal, then i should differentiate for which group the goal was reached!
    --I may need to test if for the goalverb that group goal was reached or something. Need to think about it a bit more ...
		local UnitsDestroyed = 0
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
	self:F()

	return 0
end
--- DESTROYGROUPSTASK
-- @module DESTROYGROUPSTASK

Include.File("DestroyBaseTask")

--- The DESTROYGROUPSTASK class
-- @type
DESTROYGROUPSTASK = {
  ClassName = "DESTROYGROUPSTASK",
  GoalVerb = "Destroy Groups",
}

--- Creates a new DESTROYGROUPSTASK.
-- @param #DESTROYGROUPSTASK self
-- @param #string DestroyGroupType 	String describing the group to be destroyed.
-- @param #string DestroyUnitType 	String describing the unit to be destroyed.
-- @param #list<#string> DestroyGroupNames 	Table of string containing the name of the groups to be destroyed before task is completed.
-- @param #number DestroyPercentage defines the %-tage that needs to be destroyed to achieve mission success. eg. If in the Group there are 10 units, then a value of 75 would require 8 units to be destroyed from the Group to complete the @{TASK}.
---@return DESTROYGROUPSTASK
function DESTROYGROUPSTASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyPercentage )
	local self = BASE:Inherit( self, DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyPercentage ) )
	self:F()
  
	self.Name = 'Destroy Groups'
	self.GoalVerb = "Destroy " .. DestroyGroupType
	
  _EVENTDISPATCHER:OnDead( self.EventDead , self )
  _EVENTDISPATCHER:OnCrash( self.EventDead , self )

	return self
end

--- Report Goal Progress.
-- @param #DESTROYGROUPSTASK self
-- @param DCSGroup#Group DestroyGroup Group structure describing the group to be evaluated.
-- @param DCSUnit#Unit DestroyUnit Unit structure describing the Unit to be evaluated.
-- @return #number The DestroyCount reflecting the amount of units destroyed within the group.
function DESTROYGROUPSTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
	self:F( { DestroyGroup, DestroyUnit, self.DestroyPercentage } )
	
	local DestroyGroupSize = DestroyGroup:getSize() - 1 -- When a DEAD event occurs, the getSize is still one larger than the destroyed unit.
	local DestroyGroupInitialSize = DestroyGroup:getInitialSize()
	self:T( { DestroyGroupSize, DestroyGroupInitialSize - ( DestroyGroupInitialSize * self.DestroyPercentage / 100 ) } )

	local DestroyCount = 0
	if DestroyGroup then
		if DestroyGroupSize <= DestroyGroupInitialSize - ( DestroyGroupInitialSize * self.DestroyPercentage / 100 ) then
			DestroyCount = 1
		end
	else
		DestroyCount = 1
	end
	
	self:T( DestroyCount )
	
	return DestroyCount
end
--- Task class to destroy radar installations.
-- @module DESTROYRADARSTASK 

Include.File("DestroyBaseTask")

--- The DESTROYRADARS class
-- @type
DESTROYRADARSTASK = {
  ClassName = "DESTROYRADARSTASK",
  GoalVerb = "Destroy Radars"
}

--- Creates a new DESTROYRADARSTASK.
-- @param table{string,...} DestroyGroupNames 	Table of string containing the group names of which the radars are be destroyed.
-- @return DESTROYRADARSTASK
function DESTROYRADARSTASK:New( DestroyGroupNames )
	local self = BASE:Inherit( self, DESTROYGROUPSTASK:New( 'radar installations', 'radars', DestroyGroupNames ) )
	self:F()

	self.Name = 'Destroy Radars'

  _EVENTDISPATCHER:OnDead( self.EventDead , self )

	return self
end

--- Report Goal Progress.
-- @param 	Group DestroyGroup 		Group structure describing the group to be evaluated.
-- @param 	Unit DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYRADARSTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
	self:F( { DestroyGroup, DestroyUnit } )

	local DestroyCount = 0
	if DestroyUnit and DestroyUnit:hasSensors( Unit.SensorType.RADAR, Unit.RadarType.AS ) then
		if DestroyUnit and DestroyUnit:getLife() <= 1.0 then
			self:T( 'Destroyed a radar' )
			DestroyCount = 1
		end
	end
	return DestroyCount
end
--- Set TASK to destroy certain unit types.
-- @module DESTROYUNITTYPESTASK

Include.File("DestroyBaseTask")

--- The DESTROYUNITTYPESTASK class
-- @type
DESTROYUNITTYPESTASK = {
  ClassName = "DESTROYUNITTYPESTASK",
	GoalVerb = "Destroy",
}

--- Creates a new DESTROYUNITTYPESTASK.
-- @param string DestroyGroupType 		String describing the group to be destroyed. f.e. "Radar Installations", "Fleet", "Batallion", "Command Centers".
-- @param string DestroyUnitType 		String describing the unit to be destroyed. f.e. "radars", "ships", "tanks", "centers".
-- @param table{string,...} DestroyGroupNames 	Table of string containing the group names of which the radars are be destroyed.
-- @param string DestroyUnitTypes	 	Table of string containing the type names of the units to achieve mission success.
-- @return DESTROYUNITTYPESTASK
function DESTROYUNITTYPESTASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyUnitTypes )
	local self = BASE:Inherit( self, DESTROYBASETASK:New( DestroyGroupType, DestroyUnitType, DestroyGroupNames ) )
	self:F( { DestroyGroupType, DestroyUnitType, DestroyGroupNames, DestroyUnitTypes } )
  	
	if type(DestroyUnitTypes) == 'table' then
		self.DestroyUnitTypes = DestroyUnitTypes
	else
		self.DestroyUnitTypes = { DestroyUnitTypes }
	end
	
	self.Name = 'Destroy Unit Types'
	self.GoalVerb = "Destroy " .. DestroyGroupType

  _EVENTDISPATCHER:OnDead( self.EventDead , self )

	return self
end

--- Report Goal Progress.
-- @param 	Group DestroyGroup 		Group structure describing the group to be evaluated.
-- @param 	Unit DestroyUnit 		Unit structure describing the Unit to be evaluated.
function DESTROYUNITTYPESTASK:ReportGoalProgress( DestroyGroup, DestroyUnit )
	self:F( { DestroyGroup, DestroyUnit } )

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
-- @module PICKUPTASK
-- @parent TASK

Include.File("Task")
Include.File("Cargo")

--- The PICKUPTASK class
-- @type
PICKUPTASK = {
  ClassName = "PICKUPTASK",
  TEXT = { "Pick-Up", "picked-up", "loaded" },
  GoalVerb = "Pick-Up"
}

--- Creates a new PICKUPTASK.
-- @param table{string,...}|string LandingZones Table of Zone names where Cargo is to be loaded.
-- @param CARGO_TYPE CargoType Type of the Cargo. The type must be of the following Enumeration:..
-- @param number OnBoardSide Reflects from which side the cargo Group will be on-boarded on the Carrier.
function PICKUPTASK:New( CargoType, OnBoardSide )
    local self = BASE:Inherit( self, TASK:New() )
	self:F()

    -- self holds the inherited instance of the PICKUPTASK Class to the BASE class.

    local Valid = true
  
    if  Valid then
		self.Name = 'Pickup Cargo'
		self.TaskBriefing = "Task: Fly to the indicated landing zones and pickup " .. CargoType .. ". Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the pickup zone."
		self.CargoType = CargoType
		self.GoalVerb = CargoType .. " " .. self.GoalVerb
		self.OnBoardSide = OnBoardSide
		self.IsLandingRequired = true -- required to decide whether the client needs to land or not
		self.IsSlingLoad = false -- Indicates whether the cargo is a sling load cargo
		self.Stages = { STAGE_CARGO_INIT:New(), STAGE_CARGO_LOAD:New(), STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGELANDING:New(), STAGELANDED:New(), STAGELOAD:New(), STAGEDONE:New() }
		self.SetStage( self, 1 )
	end
  
  return self
end

function PICKUPTASK:FromZone( LandingZone )
	self:F()

	self.LandingZones.LandingZoneNames[LandingZone.CargoZoneName] = LandingZone.CargoZoneName
	self.LandingZones.LandingZones[LandingZone.CargoZoneName] = LandingZone
	
	return self
end

function PICKUPTASK:InitCargo( InitCargos )
	self:F( { InitCargos } )

	if type( InitCargos ) == "table" then
		self.Cargos.InitCargos = InitCargos
	else
		self.Cargos.InitCargos = { InitCargos }
	end

	return self
end

function PICKUPTASK:LoadCargo( LoadCargos )
	self:F( { LoadCargos } )

	if type( LoadCargos ) == "table" then
		self.Cargos.LoadCargos = LoadCargos
	else
		self.Cargos.LoadCargos = { LoadCargos }
	end

	return self
end

function PICKUPTASK:AddCargoMenus( Client, Cargos, TransportRadius )
	self:F()
  
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
	self:F()

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
	self:F()

	local TaskHasFailed = self.TaskFailed
	return TaskHasFailed
end

--- A DEPLOYTASK orchestrates the deployment of CARGO within a specific landing zone.
-- @module DEPLOYTASK

Include.File( "Task" )

--- A DeployTask
-- @type DEPLOYTASK
DEPLOYTASK = {
  ClassName = "DEPLOYTASK",
  TEXT = { "Deploy", "deployed", "unloaded" },
  GoalVerb = "Deployment"
}


--- Creates a new DEPLOYTASK object, which models the sequence of STAGEs to unload a cargo.
-- @function [parent=#DEPLOYTASK] New
-- @param #string CargoType Type of the Cargo.
-- @return #DEPLOYTASK The created DeployTask
function DEPLOYTASK:New( CargoType )
	local self = BASE:Inherit( self, TASK:New() )
	self:F()

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
	self:F()

	self.LandingZones.LandingZoneNames[LandingZone.CargoZoneName] = LandingZone.CargoZoneName
	self.LandingZones.LandingZones[LandingZone.CargoZoneName] = LandingZone
	
	return self
end


function DEPLOYTASK:InitCargo( InitCargos )
	self:F( { InitCargos } )

	if type( InitCargos ) == "table" then
		self.Cargos.InitCargos = InitCargos
	else
		self.Cargos.InitCargos = { InitCargos }
	end

	return self
end


function DEPLOYTASK:LoadCargo( LoadCargos )
	self:F( { LoadCargos } )

	if type( LoadCargos ) == "table" then
		self.Cargos.LoadCargos = LoadCargos
	else
		self.Cargos.LoadCargos = { LoadCargos }
	end

	return self
end


--- When the cargo is unloaded, it will move to the target zone name.
-- @param string TargetZoneName Name of the Zone to where the Cargo should move after unloading.
function DEPLOYTASK:SetCargoTargetZoneName( TargetZoneName )
	self:F()
  
  local Valid = true
  
  Valid = routines.ValidateString( TargetZoneName, "TargetZoneName", Valid )
  
  if Valid then
    self.TargetZoneName = TargetZoneName
  end
  
  return Valid
  
end

function DEPLOYTASK:AddCargoMenus( Client, Cargos, TransportRadius )
	self:F()

	local ClientGroupID = Client:GetClientGroupID()
	
	self:T( ClientGroupID )
	
	for CargoID, Cargo in pairs( Cargos ) do

		self:T( { Cargo.ClassName, Cargo.CargoName, Cargo.CargoType, Cargo.CargoWeight } )
		
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
				self:T( 'Added DeployMenu ' .. self.TEXT[1] )
			end
			
			if Client._Menus[Cargo.CargoType].DeploySubMenus == nil then
				Client._Menus[Cargo.CargoType].DeploySubMenus = {}
			end
			
			if Client._Menus[Cargo.CargoType].DeployMenu == nil then
				self:T( 'deploymenu is nil' )
			end

			Client._Menus[Cargo.CargoType].DeploySubMenus[ #Client._Menus[Cargo.CargoType].DeploySubMenus + 1 ] = missionCommands.addCommandForGroup(
				ClientGroupID, 
				Cargo.CargoName .. " ( " .. Cargo.CargoWeight .. "kg )",
				Client._Menus[Cargo.CargoType].DeployMenu, 
				self.MenuAction,
				{ ReferenceTask = self, CargoTask = Cargo }
			)
			self:T( 'Added DeploySubMenu ' .. Cargo.CargoType .. ":" .. Cargo.CargoName .. " ( " .. Cargo.CargoWeight .. "kg )" )
		end
	end

end

function DEPLOYTASK:RemoveCargoMenus( Client )
	self:F()

	local ClientGroupID = Client:GetClientGroupID()
	self:T( ClientGroupID )

	for MenuID, MenuData in pairs( Client._Menus ) do
		if MenuData.DeploySubMenus ~= nil then
			for SubMenuID, SubMenuData in pairs( MenuData.DeploySubMenus ) do
				missionCommands.removeItemForGroup( ClientGroupID, SubMenuData )
				self:T( "Removed DeploySubMenu " )
				SubMenuData = nil
			end
		end
		if MenuData.DeployMenu then
			missionCommands.removeItemForGroup( ClientGroupID, MenuData.DeployMenu )
			self:T( "Removed DeployMenu " )
			MenuData.DeployMenu = nil
		end
	end

end
--- A NOTASK is a dummy activity... But it will show a Mission Briefing...
-- @module NOTASK

Include.File("Task")

--- The NOTASK class
-- @type
NOTASK = {
  ClassName = "NOTASK",
}

--- Creates a new NOTASK.
function NOTASK:New()
  local self = BASE:Inherit( self, TASK:New() )
	self:F()
  
  local Valid = true

  if  Valid then
    self.Name = 'Nothing'
    self.TaskBriefing = "Task: Execute your mission."
    self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEDONE:New() }
	self.SetStage( self, 1 )
  end
  
  return self
end
--- A ROUTETASK orchestrates the travel to a specific zone defined within the ME.
-- @module ROUTETASK

--- The ROUTETASK class
-- @type
ROUTETASK = {
  ClassName = "ROUTETASK",
  GoalVerb = "Route",
}

--- Creates a new ROUTETASK.
-- @param table{sring,...}|string LandingZones Table of Zone Names where the target is located.
-- @param string TaskBriefing (optional) Defines a text describing the briefing of the task.
-- @return ROUTETASK
function ROUTETASK:New( LandingZones, TaskBriefing )
  local self = BASE:Inherit( self, TASK:New() )
	self:F( { LandingZones, TaskBriefing } )

  local Valid = true
  
  Valid = routines.ValidateZone( LandingZones, "LandingZones", Valid )
    
  if  Valid then
    self.Name = 'Route To Zone'
	if TaskBriefing then
		self.TaskBriefing = TaskBriefing .. " Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the target objective."
	else
		self.TaskBriefing = "Task: Fly to specified zone(s). Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the target objective."
	end
	if type( LandingZones ) == "table" then
		self.LandingZones = LandingZones
	else
		self.LandingZones = { LandingZones }
	end
    self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGEARRIVE:New(), STAGEDONE:New() }
	self.SetStage( self, 1 )
  end
  
  return self
end

--- A MISSION is the main owner of a Mission orchestration within MOOSE	. The Mission framework orchestrates @{CLIENT}s, @{TASK}s, @{STAGE}s etc.
-- A @{CLIENT} needs to be registered within the @{MISSION} through the function @{AddClient}. A @{TASK} needs to be registered within the @{MISSION} through the function @{AddTask}.
-- @module MISSION

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Client" )
Include.File( "Task" )

--- The MISSION class
-- @type
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
	self:F()
	
	return self
end

--- This is the main MISSION declaration method. Each Mission is like the master or a Mission orchestration between, Clients, Tasks, Stages etc.
-- @param string MissionName is the name of the mission. This name will be used to reference the status of each mission by the players.
-- @param string MissionPriority is a string indicating the "priority" of the Mission. f.e. "Primary", "Secondary" or "First", "Second". It is free format and up to the Mission designer to choose. There are no rules behind this field.
-- @param string MissionBriefing is a string indicating the mission briefing to be shown when a player joins a @{CLIENT}.
-- @param string MissionCoalition is a string indicating the coalition or party to which this mission belongs to. It is free format and can be chosen freely by the mission designer. Note that this field is not to be confused with the coalition concept of the ME. Examples of a Mission Coalition could be "NATO", "CCCP", "Intruders", "Terrorists"...
-- @return MISSION
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
-- @return bool
function MISSION:IsCompleted()
	self:F()
	return self.MissionStatus == "ACCOMPLISHED"
end

--- Set a Mission to completed.
function MISSION:Completed()
	self:F()
	self.MissionStatus = "ACCOMPLISHED"
	self:StatusToClients()
end

--- Returns if a Mission is ongoing.
-- treturn bool
function MISSION:IsOngoing()
	self:F()
	return self.MissionStatus == "ONGOING"
end

--- Set a Mission to ongoing.
function MISSION:Ongoing()
	self:F()
	self.MissionStatus = "ONGOING"
	--self:StatusToClients()
end

--- Returns if a Mission is pending.
-- treturn bool
function MISSION:IsPending()
	self:F()
	return self.MissionStatus == "PENDING"
end

--- Set a Mission to pending.
function MISSION:Pending()
	self:F()
	self.MissionStatus = "PENDING"
	self:StatusToClients()
end

--- Returns if a Mission has failed.
-- treturn bool
function MISSION:IsFailed() 
	self:F()
	return self.MissionStatus == "FAILED"
end

--- Set a Mission to failed.
function MISSION:Failed()
	self:F()
	self.MissionStatus = "FAILED"
	self:StatusToClients()
end

--- Send the status of the MISSION to all Clients.
function MISSION:StatusToClients()
	self:F()
	if self.MissionReportFlash then
		for ClientID, Client in pairs( self._Clients ) do
			Client:Message( self.MissionCoalition .. ' "' .. self.Name .. '": ' .. self.MissionStatus .. '! ( ' .. self.MissionPriority .. ' mission ) ', 10,  self.Name .. '/Status', "Mission Command: Mission Status")
		end
	end
end

--- Handles the reporting. After certain time intervals, a MISSION report MESSAGE will be shown to All Players.
function MISSION:ReportTrigger()
	self:F()

	if self.MissionReportShow == true then
		self.MissionReportShow = false
		return true
	else
		if self.MissionReportFlash == true then
			if timer.getTime() >= self.MissionReportTrigger then
				self.MissionReportTrigger = timer.getTime() + self.MissionTimeInterval
				return true
			else
				return false
			end
		else
			return false 
		end
	end
end

--- Report the status of all MISSIONs to all active Clients.
function MISSION:ReportToAll()
	self:F()

	local AlivePlayers = ''
	for ClientID, Client in pairs( self._Clients ) do
		if  Client:GetDCSGroup() then
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
-- @param function GoalFunction is the function defined by the mission designer to evaluate whether a certain goal has been reached after a @{TASK} finishes within the @{MISSION}. A GoalFunction must accept 2 parameters: Mission, Client, which contains the current MISSION object and the current CLIENT object respectively.
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
	self:F()
	self.GoalFunction = GoalFunction 
end

--- Show the briefing of the MISSION to the CLIENT.
-- @param CLIENT Client to show briefing to.
-- @return CLIENT
function MISSION:ShowBriefing( Client )
	self:F( { Client.ClientName } )

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
-- @param CLIENT Client is the @{CLIENT} object. The object must have been instantiated with @{CLIENT:New}.
-- @return CLIENT
-- @usage
-- Add a number of Client objects to the Mission.
-- 	Mission:AddClient( CLIENT:New( 'US UH-1H*HOT-Deploy Troops 1', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'US UH-1H*RAMP-Deploy Troops 3', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'US UH-1H*HOT-Deploy Troops 2', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'US UH-1H*RAMP-Deploy Troops 4', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
function MISSION:AddClient( Client )
	self:F( { Client } )

	local Valid = true
 
	if Valid then
		self._Clients[Client.ClientName] = Client
	end

	return Client
end

--- Find a @{CLIENT} object within the @{MISSION} by its ClientName.
-- @param CLIENT ClientName is a string defining the Client Group as defined within the ME.
-- @return CLIENT
-- @usage
-- -- Seach for Client "Bomber" within the Mission.
-- local BomberClient = Mission:FindClient( "Bomber" )
function MISSION:FindClient( ClientName )
	self:F( { self._Clients[ClientName] } )
	return self._Clients[ClientName]
end


--- Register a @{TASK} to be completed within the @{MISSION}. Note that there can be multiple @{TASK}s registered to be completed. Each TASK can be set a certain Goal. The MISSION will not be completed until all Goals are reached.
-- @param TASK Task is the @{TASK} object. The object must have been instantiated with @{TASK:New} or any of its inherited @{TASK}s.
-- @param number TaskNumber is the sequence number of the TASK within the MISSION. This number does have to be chronological.
-- @return TASK
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
	self:F()

	self._Tasks[TaskNumber] = Task
	self._Tasks[TaskNumber]:EnableEvents()
	self._Tasks[TaskNumber].ID = TaskNumber

	return Task
 end

--- Get the TASK idenified by the TaskNumber from the Mission. This function is useful in GoalFunctions.
-- @param number TaskNumber is the number of the @{TASK} within the @{MISSION}.
-- @return TASK
-- @usage
-- -- Get Task 2 from the Mission.
-- Task2 = Mission:GetTask( 2 )

function MISSION:GetTask( TaskNumber )
	self:F()

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
-- @return {TASK,...} Structure of TASKS with the @{TASK} number as the key.
-- @usage
-- -- Get Tasks from the Mission.
-- Tasks = Mission:GetTasks()
-- env.info( "Task 2 Completion = " .. Tasks[2]:GetGoalPercentage() .. "%" )
function MISSION:GetTasks()
	self:F()

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

	-- loop through the missions in the TransportTasks
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
	
		if not Mission:IsCompleted() then
		
			-- This flag will monitor if for this mission, there are clients alive. If this flag is still false at the end of the loop, the mission status will be set to Pending (if not Failed or Completed).
			local ClientsAlive = false
			
			for ClientID, Client in pairs( Mission._Clients ) do
			
				if Client:GetDCSGroup() then

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
								if MISSIONSCHEDULER.Scoring then
								  MISSIONSCHEDULER.Scoring:_AddMissionTaskScore( Client:GetClientGroupDCSUnit(), Mission.Name, 25 )
								end

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
						if MISSIONSCHEDULER.Scoring then
						  MISSIONSCHEDULER.Scoring:_AddMissionScore( Mission.Name, 100 )
						end
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
end

--- Start the MISSIONSCHEDULER.
function MISSIONSCHEDULER.Start()
  if MISSIONSCHEDULER ~= nil then
    MISSIONSCHEDULER.SchedulerId = routines.scheduleFunction( MISSIONSCHEDULER.Scheduler, { }, 0, 2 )
  end
end

--- Stop the MISSIONSCHEDULER.
function MISSIONSCHEDULER.Stop()
	if MISSIONSCHEDULER.SchedulerId then
		routines.removeFunction(MISSIONSCHEDULER.SchedulerId)
		MISSIONSCHEDULER.SchedulerId = nil
	end
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
	MISSIONSCHEDULER.Missions[Mission.Name] = Mission
	MISSIONSCHEDULER.MissionCount = MISSIONSCHEDULER.MissionCount + 1
	-- Add an overall AI Client for the AI tasks... This AI Client will facilitate the Events in the background for each Task. 
	--MissionAdd:AddClient( CLIENT:New( 'AI' ) )
	
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
	MISSIONSCHEDULER.Missions[MissionName] = nil
	MISSIONSCHEDULER.MissionCount = MISSIONSCHEDULER.MissionCount - 1
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
	return MISSIONSCHEDULER.Missions[MissionName]
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsShow( )
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = true
		Mission.MissionReportFlash = false 
	end
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsFlash( TimeInterval )
	local Count = 0
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = false 
		Mission.MissionReportFlash = true
		Mission.MissionReportTrigger = timer.getTime() + Count * TimeInterval
		Mission.MissionTimeInterval = MISSIONSCHEDULER.MissionCount * TimeInterval 
		env.info( "TimeInterval = "  .. Mission.MissionTimeInterval )
		Count = Count + 1
	end
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsHide( Prm )
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = false
		Mission.MissionReportFlash = false
	end
end

--- Enables a MENU option in the communications menu under F10 to control the status of the active missions.
-- This function should be called only once when starting the MISSIONSCHEDULER.
function MISSIONSCHEDULER.ReportMenu()
	local ReportMenu = SUBMENU:New( 'Status' )
	local ReportMenuShow = COMMANDMENU:New( 'Show Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsShow, 0 )
	local ReportMenuFlash = COMMANDMENU:New('Flash Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsFlash, 120 )
	local ReportMenuHide = COMMANDMENU:New( 'Hide Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsHide, 0 )
end

--- Show the remaining mission time.
function MISSIONSCHEDULER:TimeShow()
	self.TimeIntervalCount = self.TimeIntervalCount + 1
	if self.TimeIntervalCount >= self.TimeTriggerShow then
		local TimeMsg = string.format("%00d", ( self.TimeSeconds / 60 ) - ( timer.getTime() / 60 )) .. ' minutes left until mission reload.'
		MESSAGE:New( TimeMsg, "Mission time", self.TimeShow, '/TimeMsg' ):ToAll()
		self.TimeIntervalCount = 0
	end
end

function MISSIONSCHEDULER:Time( TimeSeconds, TimeIntervalShow, TimeShow )

	self.TimeIntervalCount = 0
	self.TimeSeconds = TimeSeconds
	self.TimeIntervalShow = TimeIntervalShow
	self.TimeShow = TimeShow
end

--- Adds a mission scoring to the game.
function MISSIONSCHEDULER:Scoring( Scoring )

  self.Scoring = Scoring
end

--- The CLEANUP class keeps an area clean of crashing or colliding airplanes. It also prevents airplanes from firing within this area.
-- @module CleanUp
-- @author Flightcontrol

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )

--- The CLEANUP class.
-- @type CLEANUP
-- @extends Base#BASE
CLEANUP = {
	ClassName = "CLEANUP",
	ZoneNames = {},
	TimeInterval = 300,
	CleanUpList = {},
}

--- Creates the main object which is handling the cleaning of the debris within the given Zone Names.
-- @param #CLEANUP self
-- @param #table ZoneNames Is a table of zone names where the debris should be cleaned. Also a single string can be passed with one zone name.
-- @param #number TimeInterval The interval in seconds when the clean activity takes place. The default is 300 seconds, thus every 5 minutes.
-- @return #CLEANUP
-- @usage
--  -- Clean these Zones.
-- CleanUpAirports = CLEANUP:New( { 'CLEAN Tbilisi', 'CLEAN Kutaisi' }, 150 )
-- or
-- CleanUpTbilisi = CLEANUP:New( 'CLEAN Tbilisi', 150 )
-- CleanUpKutaisi = CLEANUP:New( 'CLEAN Kutaisi', 600 )
function CLEANUP:New( ZoneNames, TimeInterval )	local self = BASE:Inherit( self, BASE:New() )
	self:F( { ZoneNames, TimeInterval } )
	
	if type( ZoneNames ) == 'table' then
		self.ZoneNames = ZoneNames
	else
		self.ZoneNames = { ZoneNames }
	end
	if TimeInterval then
		self.TimeInterval = TimeInterval
	end
	
	_EVENTDISPATCHER:OnBirth( self._OnEventBirth, self )
	
	self.CleanUpScheduler = routines.scheduleFunction( self._CleanUpScheduler, { self }, timer.getTime() + 1, TimeInterval )
	
	return self
end


--- Destroys a group from the simulator, but checks first if it is still existing!
-- @param #CLEANUP self
-- @param DCSGroup#Group GroupObject The object to be destroyed.
-- @param #string CleanUpGroupName The groupname...
function CLEANUP:_DestroyGroup( GroupObject, CleanUpGroupName )
	self:F( { GroupObject, CleanUpGroupName } )

	if GroupObject then -- and GroupObject:isExist() then
		--MESSAGE:New( "Destroy Group " .. CleanUpGroupName, CleanUpGroupName, 1, CleanUpGroupName ):ToAll()
		trigger.action.deactivateGroup(GroupObject)
		self:T( { "GroupObject Destroyed", GroupObject } )
	end
end

--- Destroys a @{DCSUnit#Unit} from the simulator, but checks first if it is still existing!
-- @param #CLEANUP self
-- @param DCSUnit#Unit CleanUpUnit The object to be destroyed.
-- @param #string CleanUpUnitName The Unit name ...
function CLEANUP:_DestroyUnit( CleanUpUnit, CleanUpUnitName )
	self:F( { CleanUpUnit, CleanUpUnitName } )

	if CleanUpUnit then
		--MESSAGE:New( "Destroy " .. CleanUpUnitName, CleanUpUnitName, 1, CleanUpUnitName ):ToAll()
		local CleanUpGroup = Unit.getGroup(CleanUpUnit)
    -- TODO Client bug in 1.5.3
		if CleanUpGroup and CleanUpGroup:isExist() then
			local CleanUpGroupUnits = CleanUpGroup:getUnits()
			if #CleanUpGroupUnits == 1 then
				local CleanUpGroupName = CleanUpGroup:getName()
				--self:CreateEventCrash( timer.getTime(), CleanUpUnit )
				CleanUpGroup:destroy()
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

-- TODO check DCSTypes#Weapon
--- Destroys a missile from the simulator, but checks first if it is still existing!
-- @param #CLEANUP self
-- @param DCSTypes#Weapon MissileObject
function CLEANUP:_DestroyMissile( MissileObject )
	self:F( { MissileObject } )

	if MissileObject and MissileObject:isExist() then
		MissileObject:destroy()
		self:T( "MissileObject Destroyed")
	end
end

function CLEANUP:_OnEventBirth( Event )
  self:F( { Event } )
  
  self.CleanUpList[Event.IniDCSUnitName] = {}
  self.CleanUpList[Event.IniDCSUnitName].CleanUpUnit = Event.IniDCSUnit
  self.CleanUpList[Event.IniDCSUnitName].CleanUpGroup = Event.IniDCSGroup
  self.CleanUpList[Event.IniDCSUnitName].CleanUpGroupName = Event.IniDCSGroupName
  self.CleanUpList[Event.IniDCSUnitName].CleanUpUnitName = Event.IniDCSUnitName

  _EVENTDISPATCHER:OnEngineShutDownForUnit( Event.IniDCSUnitName, self._EventAddForCleanUp, self )
  _EVENTDISPATCHER:OnEngineStartUpForUnit( Event.IniDCSUnitName, self._EventAddForCleanUp, self )
  _EVENTDISPATCHER:OnHitForUnit( Event.IniDCSUnitName, self._EventAddForCleanUp, self )
  _EVENTDISPATCHER:OnPilotDeadForUnit( Event.IniDCSUnitName, self._EventCrash, self )
  _EVENTDISPATCHER:OnDeadForUnit( Event.IniDCSUnitName, self._EventCrash,  self )
  _EVENTDISPATCHER:OnCrashForUnit( Event.IniDCSUnitName, self._EventCrash,  self )
  _EVENTDISPATCHER:OnShotForUnit( Event.IniDCSUnitName, self._EventShot, self )

  --self:AddEvent( world.event.S_EVENT_ENGINE_SHUTDOWN, self._EventAddForCleanUp )
  --self:AddEvent( world.event.S_EVENT_ENGINE_STARTUP, self._EventAddForCleanUp )
--  self:AddEvent( world.event.S_EVENT_HIT, self._EventAddForCleanUp ) -- , self._EventHitCleanUp )
--  self:AddEvent( world.event.S_EVENT_CRASH, self._EventCrash ) -- , self._EventHitCleanUp )
--  --self:AddEvent( world.event.S_EVENT_DEAD, self._EventCrash )
--  self:AddEvent( world.event.S_EVENT_SHOT, self._EventShot )
--  
--  self:EnableEvents()


end

--- Detects if a crash event occurs.
-- Crashed units go into a CleanUpList for removal.
-- @param #CLEANUP self
-- @param DCSTypes#Event event
function CLEANUP:_EventCrash( Event )
	self:F( { Event } )

  --TODO: This stuff is not working due to a DCS bug. Burning units cannot be destroyed.
	--MESSAGE:New( "Crash ", "Crash", 10, "Crash" ):ToAll()
	-- self:T("before getGroup")
	-- local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired 
	-- self:T("after getGroup")
	-- _grp:destroy()
	-- self:T("after deactivateGroup")
	-- event.initiator:destroy()

  self.CleanUpList[Event.IniDCSUnitName] = {}
  self.CleanUpList[Event.IniDCSUnitName].CleanUpUnit = Event.IniDCSUnit
  self.CleanUpList[Event.IniDCSUnitName].CleanUpGroup = Event.IniDCSGroup
  self.CleanUpList[Event.IniDCSUnitName].CleanUpGroupName = Event.IniDCSGroupName
  self.CleanUpList[Event.IniDCSUnitName].CleanUpUnitName = Event.IniDCSUnitName
  
end

--- Detects if a unit shoots a missile.
-- If this occurs within one of the zones, then the weapon used must be destroyed.
-- @param #CLEANUP self
-- @param DCSTypes#Event event
function CLEANUP:_EventShot( Event )
	self:F( { Event } )

	-- Test if the missile was fired within one of the CLEANUP.ZoneNames.
	local CurrentLandingZoneID = 0
	CurrentLandingZoneID  = routines.IsUnitInZones( Event.IniDCSUnit, self.ZoneNames )
	if  ( CurrentLandingZoneID ) then
		-- Okay, the missile was fired within the CLEANUP.ZoneNames, destroy the fired weapon.
		--_SEADmissile:destroy()
		routines.scheduleFunction( CLEANUP._DestroyMissile, { self, Event.Weapon }, timer.getTime() + 0.1)
	end
end


--- Detects if the Unit has an S_EVENT_HIT within the given ZoneNames. If this is the case, destroy the unit.
-- @param #CLEANUP self
-- @param DCSTypes#Event event
function CLEANUP:_EventHitCleanUp( Event )
	self:F( { Event } )

	if Event.IniDCSUnit then
		if routines.IsUnitInZones( Event.IniDCSUnit, self.ZoneNames ) ~= nil then
			self:T( { "Life: ", Event.IniDCSUnitName, ' = ',  Event.IniDCSUnit:getLife(), "/", Event.IniDCSUnit:getLife0() } )
			if Event.IniDCSUnit:getLife() < Event.IniDCSUnit:getLife0() then
				self:T( "CleanUp: Destroy: " .. Event.IniDCSUnitName )
				routines.scheduleFunction( CLEANUP._DestroyUnit, { self, Event.IniDCSUnit }, timer.getTime() + 0.1)
			end
		end
	end

	if Event.TgtDCSUnit then
		if routines.IsUnitInZones( Event.TgtDCSUnit, self.ZoneNames ) ~= nil then
			self:T( { "Life: ", Event.TgtDCSUnitName, ' = ', Event.TgtDCSUnit:getLife(), "/", Event.TgtDCSUnit:getLife0() } )
			if Event.TgtDCSUnit:getLife() < Event.TgtDCSUnit:getLife0() then
				self:T( "CleanUp: Destroy: " .. Event.TgtDCSUnitName )
				routines.scheduleFunction( CLEANUP._DestroyUnit, { self, Event.TgtDCSUnit }, timer.getTime() + 0.1 )
			end
		end
	end
end

--- Add the @{DCSUnit#Unit} to the CleanUpList for CleanUp.
function CLEANUP:_AddForCleanUp( CleanUpUnit, CleanUpUnitName )
	self:F( { CleanUpUnit, CleanUpUnitName } )

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
-- @param #CLEANUP self
-- @param DCSTypes#Event event
function CLEANUP:_EventAddForCleanUp( Event )

	if Event.IniDCSUnit then
		if self.CleanUpList[Event.IniDCSUnitName] == nil then
			if routines.IsUnitInZones( Event.IniDCSUnit, self.ZoneNames ) ~= nil then
				self:_AddForCleanUp( Event.IniDCSUnit, Event.IniDCSUnitName )
			end
		end
	end

	if Event.TgtDCSUnit then
		if self.CleanUpList[Event.TgtDCSUnitName] == nil then
			if routines.IsUnitInZones( Event.TgtDCSUnit, self.ZoneNames ) ~= nil then
				self:_AddForCleanUp( Event.TgtDCSUnit, Event.TgtDCSUnitName )
			end
		end
	end
	
end

local CleanUpSurfaceTypeText = {
   "LAND",
   "SHALLOW_WATER",
   "WATER",
   "ROAD",
   "RUNWAY"
 }

--- At the defined time interval, CleanUp the Groups within the CleanUpList.
-- @param #CLEANUP self
function CLEANUP:_CleanUpScheduler()
	self:F( { "CleanUp Scheduler" } )

  local CleanUpCount = 0
	for CleanUpUnitName, UnitData in pairs( self.CleanUpList ) do
	  CleanUpCount = CleanUpCount + 1
	
		self:T( { CleanUpUnitName, UnitData } )
		local CleanUpUnit = Unit.getByName(UnitData.CleanUpUnitName)
		local CleanUpGroupName = UnitData.CleanUpGroupName
		local CleanUpUnitName = UnitData.CleanUpUnitName
		if CleanUpUnit then
			self:T( { "CleanUp Scheduler", "Checking:", CleanUpUnitName } )
			if _DATABASE:GetStatusGroup( CleanUpGroupName ) ~= "ReSpawn" then
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
	self:T(CleanUpCount)
end

--- Dynamic spawning of groups (and units).
-- 
-- @{#SPAWN} class
-- ===============
-- The @{#SPAWN} class allows to spawn dynamically new groups, based on pre-defined initialization settings, modifying the behaviour when groups are spawned.
-- For each group to be spawned, within the mission editor, a group has to be created with the "late activation flag" set. We call this group the *"Spawn Template"* of the SPAWN object.
-- A reference to this Spawn Template needs to be provided when constructing the SPAWN object, by indicating the name of the group within the mission editor in the constructor methods.
-- 
-- Within the SPAWN object, there is an internal index that keeps track of which group from the internal group list was spawned. 
-- When new groups get spawned by using the SPAWN functions (see below), it will be validated whether the Limits (@{#SPAWN.Limit}) of the SPAWN object are not reached.
-- When all is valid, a new group will be created by the spawning methods, and the internal index will be increased with 1.
-- 
-- Regarding the name of new spawned groups, a _SpawnPrefix_ will be assigned for each new group created. 
-- If you want to have the Spawn Template name to be used as the _SpawnPrefix_ name, use the @{#SPAWN.New} constructor.
-- However, when the @{#SPAWN.NewWithAlias} constructor was used, the Alias name will define the _SpawnPrefix_ name.
-- Groups will follow the following naming structure when spawned at run-time:
-- 
--   1. Spawned groups will have the name _SpawnPrefix_#ggg, where ggg is a counter from 0 to 999.
--   2. Spawned units will have the name _SpawnPrefix_#ggg-uu, where uu is a counter from 0 to 99 for each new spawned unit belonging to the group.
-- 
-- Some additional notes that need to be remembered:
-- 
--   * Templates are actually groups defined within the mission editor, with the flag "Late Activation" set. As such, these groups are never used within the mission, but are used by the @{#SPAWN} module.
--   * It is important to defined BEFORE you spawn new groups, a proper initialization of the SPAWN instance is done with the options you want to use.
--   * When designing a mission, NEVER name groups using a "#" within the name of the group Spawn Template(s), or the SPAWN module logic won't work anymore.
--   
-- SPAWN construction methods:
-- =========================== 
-- Create a new SPAWN object with the @{#SPAWN.New} or the @{#SPAWN.NewWithAlias} methods:
-- 
--   * @{#SPAWN.New}: Creates a new SPAWN object taking the name of the group that functions as the Template.
--
-- It is important to understand how the SPAWN class works internally. The SPAWN object created will contain internally a list of groups that will be spawned and that are already spawned.
-- The initialization functions will modify this list of groups so that when a group gets spawned, ALL information is already prepared when spawning. This is done for performance reasons.
-- So in principle, the group list will contain all parameters and configurations after initialization, and when groups get actually spawned, this spawning can be done quickly and efficient.
--
-- SPAWN initialization methods: 
-- =============================
-- A spawn object will behave differently based on the usage of initialization methods:  
-- 
--   * @{#SPAWN.Limit}: Limits the amount of groups that can be alive at the same time and that can be dynamically spawned.
--   * @{#SPAWN.RandomizeRoute}: Randomize the routes of spawned groups.
--   * @{#SPAWN.RandomizeTemplate}: Randomize the group templates so that when a new group is spawned, a random group template is selected from one of the templates defined. 
--   * @{#SPAWN.Uncontrolled}: Spawn plane groups uncontrolled.
--   * @{#SPAWN.Array}: Make groups visible before they are actually activated, and order these groups like a batallion in an array.
--   * @{#SPAWN.InitRepeat}: Re-spawn groups when they land at the home base. Similar functions are @{#SPAWN.InitRepeatOnLanding} and @{#SPAWN.InitRepeatOnEngineShutDown}.
-- 
-- SPAWN spawning methods:
-- =======================
-- Groups can be spawned at different times and methods:
-- 
--   * @{#SPAWN.Spawn}: Spawn one new group based on the last spawned index.
--   * @{#SPAWN.ReSpawn}: Re-spawn a group based on a given index.
--   * @{#SPAWN.SpawnScheduled}: Spawn groups at scheduled but randomized intervals. You can use @{#SPAWN.SpawnScheduleStart} and @{#SPAWN.SpawnScheduleStop} to start and stop the schedule respectively.
--   * @{#SPAWN.SpawnFromUnit}: Spawn a new group taking the position of a @{UNIT}.
--   * @{#SPAWN.SpawnInZone}: Spawn a new group in a @{ZONE}.
-- 
-- Note that @{#SPAWN.Spawn} and @{#SPAWN.ReSpawn} return a @{GROUP#GROUP.New} object, that contains a reference to the DCSGroup object. 
-- You can use the @{GROUP} object to do further actions with the DCSGroup.
--  
-- SPAWN object cleaning:
-- =========================
-- Sometimes, it will occur during a mission run-time, that ground or especially air objects get damaged, and will while being damged stop their activities, while remaining alive.
-- In such cases, the SPAWN object will just sit there and wait until that group gets destroyed, but most of the time it won't, 
-- and it may occur that no new groups are or can be spawned as limits are reached.
-- To prevent this, a @{#SPAWN.CleanUp} initialization method has been defined that will silently monitor the status of each spawned group.
-- Once a group has a velocity = 0, and has been waiting for a defined interval, that group will be cleaned or removed from run-time. 
-- There is a catch however :-) If a damaged group has returned to an airbase within the coalition, that group will not be considered as "lost"... 
-- In such a case, when the inactive group is cleaned, a new group will Re-spawned automatically. 
-- This models AI that has succesfully returned to their airbase, to restart their combat activities.
-- Check the @{#SPAWN.CleanUp} for further info.
-- 
-- ====
-- @module Spawn
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Database" )
Include.File( "Group" )
Include.File( "Zone" )
Include.File( "Event" )
Include.File( "Scheduler" )

--- SPAWN Class
-- @type SPAWN
-- @extends Base#BASE
-- @field ClassName
-- @field #string SpawnTemplatePrefix
-- @field #string SpawnAliasPrefix
SPAWN = {
  ClassName = "SPAWN",
  SpawnTemplatePrefix = nil,
  SpawnAliasPrefix = nil,
}



--- Creates the main object to spawn a GROUP defined in the DCS ME.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix is the name of the Group in the ME that defines the Template.  Each new group will have the name starting with SpawnTemplatePrefix.
-- @return #SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' )
-- @usage local Plane = SPAWN:New( "Plane" ) -- Creates a new local variable that can initiate new planes with the name "Plane#ddd" using the template "Plane" as defined within the ME.
function SPAWN:New( SpawnTemplatePrefix )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( { SpawnTemplatePrefix } )
  
	local TemplateGroup = Group.getByName( SpawnTemplatePrefix )
	if TemplateGroup then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
		self.SpawnIndex = 0
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnIsScheduled = false												-- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.Repeat = false													-- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false													-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
		self.SpawnMaxUnitsAlive = 0												-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
		self.SpawnMaxGroups = 0														-- The maximum amount of groups that can be spawned.
		self.SpawnRandomize = false													-- Sets the randomization flag of new Spawned units to false.
		self.SpawnVisible = false													-- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end

	return self
end

--- Creates a new SPAWN instance to create new groups based on the defined template and using a new alias for each new group.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix is the name of the Group in the ME that defines the Template.
-- @param #string SpawnAliasPrefix is the name that will be given to the Group at runtime.
-- @return #SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- Spawn_BE_KA50 = SPAWN:NewWithAlias( 'BE KA-50@RAMP-Ground Defense', 'Helicopter Attacking a City' )
-- @usage local PlaneWithAlias = SPAWN:NewWithAlias( "Plane", "Bomber" ) -- Creates a new local variable that can instantiate new planes with the name "Bomber#ddd" using the template "Plane" as defined within the ME.
function SPAWN:NewWithAlias( SpawnTemplatePrefix, SpawnAliasPrefix )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( { SpawnTemplatePrefix, SpawnAliasPrefix } )
  
	local TemplateGroup = Group.getByName( SpawnTemplatePrefix )
	if TemplateGroup then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
		self.SpawnAliasPrefix = SpawnAliasPrefix
		self.SpawnIndex = 0
		self.SpawnCount = 0															-- The internal counter of the amount of spawning the has happened since SpawnStart.
		self.AliveUnits = 0															-- Contains the counter how many units are currently alive
		self.SpawnIsScheduled = false												-- Reflects if the spawning for this SpawnTemplatePrefix is going to be scheduled or not.
		self.SpawnTemplate = self._GetTemplate( self, SpawnTemplatePrefix )					-- Contains the template structure for a Group Spawn from the Mission Editor. Note that this group must have lateActivation always on!!!
		self.Repeat = false													-- Don't repeat the group from Take-Off till Landing and back Take-Off by ReSpawning.
		self.UnControlled = false													-- When working in UnControlled mode, all planes are Spawned in UnControlled mode before the scheduler starts.
		self.SpawnMaxUnitsAlive = 0												-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
		self.SpawnMaxGroups = 0														-- The maximum amount of groups that can be spawned.
		self.SpawnRandomize = false													-- Sets the randomization flag of new Spawned units to false.
		self.SpawnVisible = false													-- Flag that indicates if all the Groups of the SpawnGroup need to be visible when Spawned.

		self.SpawnGroups = {}														-- Array containing the descriptions of each Group to be Spawned.
	else
		error( "SPAWN:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end
	
	return self
end


--- Limits the Maximum amount of Units that can be alive at the same time, and the maximum amount of groups that can be spawned.
-- Note that this method is exceptionally important to balance the performance of the mission. Depending on the machine etc, a mission can only process a maximum amount of units.
-- If the time interval must be short, but there should not be more Units or Groups alive than a maximum amount of units, then this function should be used...
-- When a @{#SPAWN.New} is executed and the limit of the amount of units alive is reached, then no new spawn will happen of the group, until some of these units of the spawn object will be destroyed.
-- @param #SPAWN self
-- @param #number SpawnMaxUnitsAlive The maximum amount of units that can be alive at runtime.    
-- @param #number SpawnMaxGroups The maximum amount of groups that can be spawned. When the limit is reached, then no more actual spawns will happen of the group. 
-- This parameter is useful to define a maximum amount of airplanes, ground troops, helicopters, ships etc within a supply area. 
-- This parameter accepts the value 0, which defines that there are no maximum group limits, but there are limits on the maximum of units that can be alive at the same time.
-- @return #SPAWN self
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- -- This helicopter group consists of one Unit. So, this group will SPAWN maximum 2 groups simultaneously within the DCSRTE.
-- -- There will be maximum 24 groups spawned during the whole mission lifetime. 
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):Limit( 2, 24 )
function SPAWN:Limit( SpawnMaxUnitsAlive, SpawnMaxGroups )
	self:F( { self.SpawnTemplatePrefix, SpawnMaxUnitsAlive, SpawnMaxGroups } )

	self.SpawnMaxUnitsAlive = SpawnMaxUnitsAlive				-- The maximum amount of groups that can be alive of SpawnTemplatePrefix at the same time.
	self.SpawnMaxGroups = SpawnMaxGroups						-- The maximum amount of groups that can be spawned.
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:_InitializeSpawnGroups( SpawnGroupID )
	end

	return self
end


--- Randomizes the defined route of the SpawnTemplatePrefix group in the ME. This is very useful to define extra variation of the behaviour of groups.
-- @param #SPAWN self
-- @param #number SpawnStartPoint is the waypoint where the randomization begins. 
-- Note that the StartPoint = 0 equaling the point where the group is spawned.
-- @param #number SpawnEndPoint is the waypoint where the randomization ends counting backwards. 
-- This parameter is useful to avoid randomization to end at a waypoint earlier than the last waypoint on the route.
-- @param #number SpawnRadius is the radius in meters in which the randomization of the new waypoints, with the original waypoint of the original template located in the middle ...
-- @return #SPAWN
-- @usage
-- -- NATO helicopters engaging in the battle field. 
-- -- The KA-50 has waypoints Start point ( =0 or SP ), 1, 2, 3, 4, End point (= 5 or DP). 
-- -- Waypoints 2 and 3 will only be randomized. The others will remain on their original position with each new spawn of the helicopter.
-- -- The randomization of waypoint 2 and 3 will take place within a radius of 2000 meters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):RandomizeRoute( 2, 2, 2000 )
function SPAWN:RandomizeRoute( SpawnStartPoint, SpawnEndPoint, SpawnRadius )
	self:F( { self.SpawnTemplatePrefix, SpawnStartPoint, SpawnEndPoint, SpawnRadius } )

	self.SpawnRandomizeRoute = true
	self.SpawnRandomizeRouteStartPoint = SpawnStartPoint
	self.SpawnRandomizeRouteEndPoint = SpawnEndPoint
	self.SpawnRandomizeRouteRadius = SpawnRadius

	for GroupID = 1, self.SpawnMaxGroups do
		self:_RandomizeRoute( GroupID )
	end
	
	return self
end


--- This function is rather complicated to understand. But I'll try to explain.
-- This function becomes useful when you need to spawn groups with random templates of groups defined within the mission editor, 
-- but they will all follow the same Template route and have the same prefix name.
-- In other words, this method randomizes between a defined set of groups the template to be used for each new spawn of a group.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefixTable A table with the names of the groups defined within the mission editor, from which one will be choosen when a new group will be spawned. 
-- @return #SPAWN
-- @usage
-- -- NATO Tank Platoons invading Gori.
-- -- Choose between 13 different 'US Tank Platoon' configurations for each new SPAWN the Group to be spawned for the 
-- -- 'US Tank Platoon Left', 'US Tank Platoon Middle' and 'US Tank Platoon Right' SpawnTemplatePrefixes.
-- -- Each new SPAWN will randomize the route, with a defined time interval of 200 seconds with 40% time variation (randomization) and 
-- -- with a limit set of maximum 12 Units alive simulteneously  and 150 Groups to be spawned during the whole mission.
-- Spawn_US_Platoon = { 'US Tank Platoon 1', 'US Tank Platoon 2', 'US Tank Platoon 3', 'US Tank Platoon 4', 'US Tank Platoon 5', 
--                      'US Tank Platoon 6', 'US Tank Platoon 7', 'US Tank Platoon 8', 'US Tank Platoon 9', 'US Tank Platoon 10', 
--                      'US Tank Platoon 11', 'US Tank Platoon 12', 'US Tank Platoon 13' }
-- Spawn_US_Platoon_Left = SPAWN:New( 'US Tank Platoon Left' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Middle = SPAWN:New( 'US Tank Platoon Middle' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
-- Spawn_US_Platoon_Right = SPAWN:New( 'US Tank Platoon Right' ):Limit( 12, 150 ):Schedule( 200, 0.4 ):RandomizeTemplate( Spawn_US_Platoon ):RandomizeRoute( 3, 3, 2000 )
function SPAWN:RandomizeTemplate( SpawnTemplatePrefixTable )
	self:F( { self.SpawnTemplatePrefix, SpawnTemplatePrefixTable } )

	self.SpawnTemplatePrefixTable = SpawnTemplatePrefixTable
	self.SpawnRandomizeTemplate = true

	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self:_RandomizeTemplate( SpawnGroupID )
	end
	
	return self
end





--- For planes and helicopters, when these groups go home and land on their home airbases and farps, they normally would taxi to the parking spot, shut-down their engines and wait forever until the Group is removed by the runtime environment.
-- This function is used to re-spawn automatically (so no extra call is needed anymore) the same group after it has landed. 
-- This will enable a spawned group to be re-spawned after it lands, until it is destroyed...
-- Note: When the group is respawned, it will re-spawn from the original airbase where it took off. 
-- So ensure that the routes for groups that respawn, always return to the original airbase, or players may get confused ...
-- @param #SPAWN self
-- @return #SPAWN self
-- @usage
-- -- RU Su-34 - AI Ship Attack
-- -- Re-SPAWN the Group(s) after each landing and Engine Shut-Down automatically. 
-- SpawnRU_SU34 = SPAWN:New( 'TF1 RU Su-34 Krymsk@AI - Attack Ships' ):Schedule( 2, 3, 1800, 0.4 ):SpawnUncontrolled():RandomizeRoute( 1, 1, 3000 ):RepeatOnEngineShutDown()
function SPAWN:InitRepeat()
	self:F( { self.SpawnTemplatePrefix, self.SpawnIndex } )

	self.Repeat = true
	self.RepeatOnEngineShutDown = false
	self.RepeatOnLanding = true

	return self
end

--- Respawn group after landing.
-- @param #SPAWN self
-- @return #SPAWN self
function SPAWN:InitRepeatOnLanding()
	self:F( { self.SpawnTemplatePrefix } )

	self:InitRepeat()
	self.RepeatOnEngineShutDown = false
	self.RepeatOnLanding = true
	
	return self
end


--- Respawn after landing when its engines have shut down.
-- @param #SPAWN self
-- @return #SPAWN self
function SPAWN:InitRepeatOnEngineShutDown()
	self:F( { self.SpawnTemplatePrefix } )

	self:InitRepeat()
	self.RepeatOnEngineShutDown = true
	self.RepeatOnLanding = false
	
	return self
end


--- CleanUp groups when they are still alive, but inactive.
-- When groups are still alive and have become inactive due to damage and are unable to contribute anything, then this group will be removed at defined intervals in seconds.
-- @param #SPAWN self
-- @param #string SpawnCleanUpInterval The interval to check for inactive groups within seconds.
-- @return #SPAWN self
-- @usage Spawn_Helicopter:CleanUp( 20 )  -- CleanUp the spawning of the helicopters every 20 seconds when they become inactive.
function SPAWN:CleanUp( SpawnCleanUpInterval )
	self:F( { self.SpawnTemplatePrefix, SpawnCleanUpInterval } )

	self.SpawnCleanUpInterval = SpawnCleanUpInterval
	self.SpawnCleanUpTimeStamps = {}
	--self.CleanUpFunction = routines.scheduleFunction( self._SpawnCleanUpScheduler, { self }, timer.getTime() + 1, SpawnCleanUpInterval )
	self.CleanUpScheduler = SCHEDULER:New( self, self._SpawnCleanUpScheduler, {}, 1, SpawnCleanUpInterval, 0.2 )
	return self
end



--- Makes the groups visible before start (like a batallion).
-- The method will take the position of the group as the first position in the array.
-- @param #SPAWN self
-- @param #number SpawnAngle         The angle in degrees how the groups and each unit of the group will be positioned.
-- @param #number SpawnWidth		     The amount of Groups that will be positioned on the X axis.
-- @param #number SpawnDeltaX        The space between each Group on the X-axis.
-- @param #number SpawnDeltaY		     The space between each Group on the Y-axis.
-- @return #SPAWN self
-- @usage
-- -- Define an array of Groups.
-- Spawn_BE_Ground = SPAWN:New( 'BE Ground' ):Limit( 2, 24 ):Visible( 90, "Diamond", 10, 100, 50 )
function SPAWN:Array( SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY )
	self:F( { self.SpawnTemplatePrefix, SpawnAngle, SpawnWidth, SpawnDeltaX, SpawnDeltaY } )

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

    _EVENTDISPATCHER:OnBirthForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnBirth, self )
    _EVENTDISPATCHER:OnCrashForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnDeadOrCrash, self )
    _EVENTDISPATCHER:OnDeadForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnDeadOrCrash, self )

    if self.Repeat then
      _EVENTDISPATCHER:OnTakeOffForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnTakeOff, self )
      _EVENTDISPATCHER:OnLandForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnLand, self )
    end
    if self.RepeatOnEngineShutDown then
      _EVENTDISPATCHER:OnEngineShutDownForTemplate( self.SpawnGroups[SpawnGroupID].SpawnTemplate, self._OnEngineShutDown, self )
    end
		
		self.SpawnGroups[SpawnGroupID].Group = _DATABASE:Spawn( self.SpawnGroups[SpawnGroupID].SpawnTemplate )

		SpawnX = SpawnXIndex * SpawnDeltaX
		SpawnY = SpawnYIndex * SpawnDeltaY
	end
	
	return self
end



--- Will spawn a group based on the internal index.
-- Note: Uses @{DATABASE} module defined in MOOSE.
-- @param #SPAWN self
-- @return Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:Spawn()
	self:F( { self.SpawnTemplatePrefix, self.SpawnIndex } )

	return self:SpawnWithIndex( self.SpawnIndex + 1 )
end

--- Will re-spawn a group based on a given index.
-- Note: Uses @{DATABASE} module defined in MOOSE.
-- @param #SPAWN self
-- @param #string SpawnIndex The index of the group to be spawned.
-- @return Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:ReSpawn( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex } )
	
	if not SpawnIndex then
		SpawnIndex = 1
	end

-- TODO: This logic makes DCS crash and i don't know why (yet).
	local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
	if SpawnGroup then
    local SpawnDCSGroup = SpawnGroup:GetDCSGroup()
  	if SpawnDCSGroup then
      SpawnGroup:Destroy()
  	end
  end

	return self:SpawnWithIndex( SpawnIndex )
end

--- Will spawn a group with a specified index number.
-- Uses @{DATABASE} global object defined in MOOSE.
-- @param #SPAWN self
-- @return Group#GROUP The group that was spawned. You can use this group for further actions.
function SPAWN:SpawnWithIndex( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnMaxGroups } )
	
	if self:_GetSpawnIndex( SpawnIndex ) then
		
		if self.SpawnGroups[self.SpawnIndex].Visible then
			self.SpawnGroups[self.SpawnIndex].Group:Activate()
		else
			self:T( self.SpawnGroups[self.SpawnIndex].SpawnTemplate )
      _EVENTDISPATCHER:OnBirthForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnBirth, self )
      _EVENTDISPATCHER:OnCrashForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnDeadOrCrash, self )
      _EVENTDISPATCHER:OnDeadForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnDeadOrCrash, self )

      if self.Repeat then
        _EVENTDISPATCHER:OnTakeOffForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnTakeOff, self )
        _EVENTDISPATCHER:OnLandForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnLand, self )
      end
      if self.RepeatOnEngineShutDown then
        _EVENTDISPATCHER:OnEngineShutDownForTemplate( self.SpawnGroups[self.SpawnIndex].SpawnTemplate, self._OnEngineShutDown, self )
      end
      
      self:T( self.SpawnGroups[self.SpawnIndex].SpawnTemplate )

			self.SpawnGroups[self.SpawnIndex].Group = _DATABASE:Spawn( self.SpawnGroups[self.SpawnIndex].SpawnTemplate )
			
			-- If there is a SpawnFunction hook defined, call it.
			if self.SpawnFunctionHook then
			  self.SpawnFunctionHook( self.SpawnGroups[self.SpawnIndex].Group, unpack( self.SpawnFunctionArguments ) )
			end
			-- TODO: Need to fix this by putting an "R" in the name of the group when the group repeats.
			--if self.Repeat then
			--	_DATABASE:SetStatusGroup( SpawnTemplate.name, "ReSpawn" )
			--end
		end
		
		self.SpawnGroups[self.SpawnIndex].Spawned = true
		return self.SpawnGroups[self.SpawnIndex].Group
	else
		--self:E( { self.SpawnTemplatePrefix, "No more Groups to Spawn:", SpawnIndex, self.SpawnMaxGroups } )
	end

	return nil
end

--- Spawns new groups at varying time intervals.
-- This is useful if you want to have continuity within your missions of certain (AI) groups to be present (alive) within your missions.
-- @param #SPAWN self
-- @param #number SpawnTime The time interval defined in seconds between each new spawn of new groups.
-- @param #number SpawnTimeVariation The variation to be applied on the defined time interval between each new spawn.
-- The variation is a number between 0 and 1, representing the %-tage of variation to be applied on the time interval.
-- @return #SPAWN self
-- @usage
-- -- NATO helicopters engaging in the battle field.
-- -- The time interval is set to SPAWN new helicopters between each 600 seconds, with a time variation of 50%.
-- -- The time variation in this case will be between 450 seconds and 750 seconds. 
-- -- This is calculated as follows: 
-- --      Low limit:   600 * ( 1 - 0.5 / 2 ) = 450 
-- --      High limit:  600 * ( 1 + 0.5 / 2 ) = 750
-- -- Between these two values, a random amount of seconds will be choosen for each new spawn of the helicopters.
-- Spawn_BE_KA50 = SPAWN:New( 'BE KA-50@RAMP-Ground Defense' ):Schedule( 600, 0.5 )
function SPAWN:SpawnScheduled( SpawnTime, SpawnTimeVariation )
	self:F( { SpawnTime, SpawnTimeVariation } )

	if SpawnTime ~= nil and SpawnTimeVariation ~= nil then
    self.SpawnScheduler = SCHEDULER:New( self, self._Scheduler, {}, 1, SpawnTime, SpawnTimeVariation )
	end

	return self
end

--- Will re-start the spawning scheduler.
-- Note: This function is only required to be called when the schedule was stopped.
function SPAWN:SpawnScheduleStart()
  self:F( { self.SpawnTemplatePrefix } )

  self.SpawnScheduler:Start()
end

--- Will stop the scheduled spawning scheduler.
function SPAWN:SpawnScheduleStop()
  self:F( { self.SpawnTemplatePrefix } )
  
  self.SpawnScheduler:Stop()
end


--- Allows to place a CallFunction hook when a new group spawns.
-- The provided function will be called when a new group is spawned, including its given parameters.
-- The first parameter of the SpawnFunction is the @{Group#GROUP} that was spawned.
-- @param #SPAWN self
-- @param #function SpawnFunctionHook The function to be called when a group spawns.
-- @param SpawnFunctionArguments A random amount of arguments to be provided to the function when the group spawns.
-- @return #SPAWN
function SPAWN:SpawnFunction( SpawnFunctionHook, ... )
  self:F( SpawnFunction )

  self.SpawnFunctionHook = SpawnFunctionHook
  self.SpawnFunctionArguments = {}
  if arg then
    self.SpawnFunctionArguments = arg
  end  

  return self
end




--- Will spawn a group from a hosting unit. This function is mostly advisable to be used if you want to simulate spawning from air units, like helicopters, which are dropping infantry into a defined Landing Zone.
-- Note that each point in the route assigned to the spawning group is reset to the point of the spawn.
-- You can use the returned group to further define the route to be followed.
-- @param #SPAWN self
-- @param Unit#UNIT HostUnit The air or ground unit dropping or unloading the group.
-- @param #number OuterRadius The outer radius in meters where the new group will be spawned.
-- @param #number InnerRadius The inner radius in meters where the new group will NOT be spawned.
-- @param #number SpawnIndex (Optional) The index which group to spawn within the given zone.
-- @return Group#GROUP that was spawned.
-- @return #nil Nothing was spawned.
function SPAWN:SpawnFromUnit( HostUnit, OuterRadius, InnerRadius, SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, HostUnit, OuterRadius, InnerRadius, SpawnIndex } )

  if HostUnit and HostUnit:IsAlive() then -- and HostUnit:getUnit(1):inAir() == false then

    if SpawnIndex then
    else
      SpawnIndex = self.SpawnIndex + 1
    end
    
    if self:_GetSpawnIndex( SpawnIndex ) then
      
      local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
    
      if SpawnTemplate then

        local UnitPoint = HostUnit:GetPointVec2()
        
        self:T( { "Current point of ", self.SpawnTemplatePrefix, UnitPoint } )
        
        --for PointID, Point in pairs( SpawnTemplate.route.points ) do
          --Point.x = UnitPoint.x
          --Point.y = UnitPoint.y
          --Point.alt = nil
          --Point.alt_type = nil
        --end
        
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
            local CirclePos = routines.getRandPointInCircle( UnitPoint, OuterRadius, InnerRadius )
            SpawnTemplate.units[UnitID].x = CirclePos.x
            SpawnTemplate.units[UnitID].y = CirclePos.y
          end
          self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
        end
        
        local SpawnPos = routines.getRandPointInCircle( UnitPoint, OuterRadius, InnerRadius )
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

--- Will spawn a Group within a given @{Zone#ZONE}.
-- Once the group is spawned within the zone, it will continue on its route.
-- The first waypoint (where the group is spawned) is replaced with the zone coordinates.
-- @param #SPAWN self
-- @param Zone#ZONE Zone The zone where the group is to be spawned.
-- @param #number ZoneRandomize (Optional) Set to true if you want to randomize the starting point in the zone.
-- @param #number SpawnIndex (Optional) The index which group to spawn within the given zone.
-- @return Group#GROUP that was spawned.
-- @return #nil when nothing was spawned.
function SPAWN:SpawnInZone( Zone, ZoneRandomize, SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, Zone, ZoneRandomize, SpawnIndex } )
  
  if Zone then
    
    if SpawnIndex then
    else
      SpawnIndex = self.SpawnIndex + 1
    end
    
    if self:_GetSpawnIndex( SpawnIndex ) then

      local SpawnTemplate = self.SpawnGroups[self.SpawnIndex].SpawnTemplate
      
      if SpawnTemplate then
    
        local ZonePoint 
        
        if ZoneRandomize == true then
          ZonePoint = Zone:GetRandomPointVec2()
        else
          ZonePoint = Zone:GetPointVec2()
        end

        SpawnTemplate.route.points[1].x = ZonePoint.x
        SpawnTemplate.route.points[1].y = ZonePoint.y
        
        -- Apply SpawnFormation
        for UnitID = 1, #SpawnTemplate.units do
          local ZonePointUnit = Zone:GetRandomPointVec2()
          SpawnTemplate.units[UnitID].x = ZonePointUnit.x
          SpawnTemplate.units[UnitID].y = ZonePointUnit.y
          self:T( 'SpawnTemplate.units['..UnitID..'].x = ' .. SpawnTemplate.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. SpawnTemplate.units[UnitID].y )
        end
       
        return self:SpawnWithIndex( self.SpawnIndex )
      end
    end
  end
  
  return nil
end




--- Will spawn a plane group in uncontrolled mode... 
-- This will be similar to the uncontrolled flag setting in the ME.
-- @return #SPAWN self
function SPAWN:UnControlled()
	self:F( { self.SpawnTemplatePrefix } )
	
	self.SpawnUnControlled = true
	
	for SpawnGroupID = 1, self.SpawnMaxGroups do
		self.SpawnGroups[SpawnGroupID].UnControlled = true
	end
	
	return self
end



--- Will return the SpawnGroupName either with with a specific count number or without any count.
-- @param #SPAWN self
-- @param #number SpawnIndex Is the number of the Group that is to be spawned.
-- @return #string SpawnGroupName
function SPAWN:SpawnGroupName( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex } )

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

--- Find the first alive group.
-- @param #SPAWN self
-- @param #number SpawnCursor A number holding the index from where to find the first group from.
-- @return Group#GROUP, #number The group found, the new index where the group was found.
-- @return #nil, #nil When no group is found, #nil is returned.
function SPAWN:GetFirstAliveGroup( SpawnCursor )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnCursor } )

  for SpawnIndex = 1, self.SpawnCount do
    local SpawnGroup = self:GetGroupFromIndex( SpawnIndex )
    if SpawnGroup and SpawnGroup:IsAlive() then
      SpawnCursor = SpawnIndex
      return SpawnGroup, SpawnCursor
    end
  end
  
  return nil, nil
end


--- Find the next alive group.
-- @param #SPAWN self
-- @param #number SpawnCursor A number holding the last found previous index.
-- @return Group#GROUP, #number The group found, the new index where the group was found.
-- @return #nil, #nil When no group is found, #nil is returned.
function SPAWN:GetNextAliveGroup( SpawnCursor )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnCursor } )

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

--- Find the last alive group during runtime.
function SPAWN:GetLastAliveGroup()
	self:F( { self.SpawnTemplatePrefixself.SpawnAliasPrefix } )

  self.SpawnIndex = self:_GetLastIndex()
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



--- Get the group from an index.
-- Returns the group from the SpawnGroups list.
-- If no index is given, it will return the first group in the list.
-- @param #SPAWN self
-- @param #number SpawnIndex The index of the group to return.
-- @return Group#GROUP
function SPAWN:GetGroupFromIndex( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnIndex } )
	
	if not SpawnIndex then
    SpawnIndex = 1
	end
	
	if self.SpawnGroups and self.SpawnGroups[SpawnIndex] then
		local SpawnGroup = self.SpawnGroups[SpawnIndex].Group
		return SpawnGroup
	else
    return nil
	end
end

--- Get the group index from a DCSUnit.
-- The method will search for a #-mark, and will return the index behind the #-mark of the DCSUnit.
-- It will return nil of no prefix was found.
-- @param #SPAWN self
-- @param DCSUnit The DCS unit to be searched.
-- @return #string The prefix
-- @return #nil Nothing found
function SPAWN:_GetGroupIndexFromDCSUnit( DCSUnit )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )

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

--- Return the prefix of a DCSUnit.
-- The method will search for a #-mark, and will return the text before the #-mark.
-- It will return nil of no prefix was found.
-- @param #SPAWN self
-- @param DCSUnit The DCS unit to be searched.
-- @return #string The prefix
-- @return #nil Nothing found
function SPAWN:_GetPrefixFromDCSUnit( DCSUnit )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )

	if DCSUnit and DCSUnit:getName() then
		local SpawnPrefix = string.match( DCSUnit:getName(), ".*#" )
		if SpawnPrefix then
			SpawnPrefix = SpawnPrefix:sub( 1, -2 )
		end
		self:T( SpawnPrefix )
		return SpawnPrefix
	end
	
	return nil
end

--- Return the group within the SpawnGroups collection with input a DCSUnit.
function SPAWN:_GetGroupFromDCSUnit( DCSUnit )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, DCSUnit } )
	
	if DCSUnit then
		local SpawnPrefix = self:_GetPrefixFromDCSUnit( DCSUnit )
		
		if self.SpawnTemplatePrefix == SpawnPrefix or ( self.SpawnAliasPrefix and self.SpawnAliasPrefix == SpawnPrefix ) then
			local SpawnGroupIndex = self:_GetGroupIndexFromDCSUnit( DCSUnit )
			local SpawnGroup = self.SpawnGroups[SpawnGroupIndex].Group
			self:T( SpawnGroup )
			return SpawnGroup
		end
	end

	return nil
end


--- Get the index from a given group.
-- The function will search the name of the group for a #, and will return the number behind the #-mark.
function SPAWN:GetSpawnIndexFromGroup( SpawnGroup )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnGroup } )
	
	local IndexString = string.match( SpawnGroup:GetName(), "#.*$" ):sub( 2 )
	local Index = tonumber( IndexString )
	
	self:T( IndexString, Index )
	return Index
	
end

--- Return the last maximum index that can be used.
function SPAWN:_GetLastIndex()
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )

	return self.SpawnMaxGroups
end

--- Initalize the SpawnGroups collection.
function SPAWN:_InitializeSpawnGroups( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnIndex } )

	if not self.SpawnGroups[SpawnIndex] then
		self.SpawnGroups[SpawnIndex] = {}
		self.SpawnGroups[SpawnIndex].Visible = false
		self.SpawnGroups[SpawnIndex].Spawned = false
		self.SpawnGroups[SpawnIndex].UnControlled = false
		self.SpawnGroups[SpawnIndex].SpawnTime = 0
		
		self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix = self.SpawnTemplatePrefix
		self.SpawnGroups[SpawnIndex].SpawnTemplate = self:_Prepare( self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix, SpawnIndex )
	end
	
	self:_RandomizeTemplate( SpawnIndex )
	self:_RandomizeRoute( SpawnIndex )
	--self:_TranslateRotate( SpawnIndex )
	
	return self.SpawnGroups[SpawnIndex]
end



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
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnPrefix } )
	
	local TemplateGroup = Group.getByName( SpawnPrefix )
	
	if TemplateGroup then
		local TemplateUnits = TemplateGroup:getUnits()
		return TemplateUnits[1]:getCountry()
	else
		return nil
	end
end

--- Gets the Group Template from the ME environment definition.
-- This method used the @{DATABASE} object, which contains ALL initial and new spawned object in MOOSE.
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix
-- @return @SPAWN self
function SPAWN:_GetTemplate( SpawnTemplatePrefix )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix, SpawnTemplatePrefix } )

	local SpawnTemplate = nil

	SpawnTemplate = routines.utils.deepCopy( _DATABASE.Templates.Groups[SpawnTemplatePrefix].Template )
	
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
-- @param #SPAWN self
-- @param #string SpawnTemplatePrefix
-- @param #number SpawnIndex
-- @return #SPAWN self
function SPAWN:_Prepare( SpawnTemplatePrefix, SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, self.SpawnAliasPrefix } )
	
	local SpawnTemplate = self:_GetTemplate( SpawnTemplatePrefix )
	SpawnTemplate.name = self:SpawnGroupName( SpawnIndex )
	
	SpawnTemplate.groupId = nil
	SpawnTemplate.lateActivation = false

	if SpawnTemplate.SpawnCategoryID == Group.Category.GROUND then
	  self:T( "For ground units, visible needs to be false..." )
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

--- Private method randomizing the routes.
-- @param #SPAWN self
-- @param #number SpawnIndex The index of the group to be spawned.
-- @return #SPAWN
function SPAWN:_RandomizeRoute( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnRandomizeRoute, self.SpawnRandomizeRouteStartPoint, self.SpawnRandomizeRouteEndPoint, self.SpawnRandomizeRouteRadius } )

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

--- Private method that randomizes the template of the group.
-- @param #SPAWN self
-- @param #number SpawnIndex
-- @return #SPAWN self
function SPAWN:_RandomizeTemplate( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex } )

  if self.SpawnRandomizeTemplate then
    self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix = self.SpawnTemplatePrefixTable[ math.random( 1, #self.SpawnTemplatePrefixTable ) ]
    self.SpawnGroups[SpawnIndex].SpawnTemplate = self:_Prepare( self.SpawnGroups[SpawnIndex].SpawnTemplatePrefix, SpawnIndex )
    self.SpawnGroups[SpawnIndex].SpawnTemplate.route = routines.utils.deepCopy( self.SpawnTemplate.route )
    self.SpawnGroups[SpawnIndex].SpawnTemplate.x = self.SpawnTemplate.x
    self.SpawnGroups[SpawnIndex].SpawnTemplate.y = self.SpawnTemplate.y
    self.SpawnGroups[SpawnIndex].SpawnTemplate.start_time = self.SpawnTemplate.start_time
    for UnitID = 1, #self.SpawnGroups[SpawnIndex].SpawnTemplate.units do
      self.SpawnGroups[SpawnIndex].SpawnTemplate.units[UnitID].heading = self.SpawnTemplate.units[1].heading
    end
  end
  
  self:_RandomizeRoute( SpawnIndex )
  
  return self
end

function SPAWN:_TranslateRotate( SpawnIndex, SpawnRootX, SpawnRootY, SpawnX, SpawnY, SpawnAngle )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex, SpawnRootX, SpawnRootY, SpawnX, SpawnY, SpawnAngle } )
  
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
    self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].heading = self.SpawnGroups[SpawnIndex].SpawnTemplate.units[u].heading + math.rad( SpawnAngle )
  end
  
  return self
end

--- Get the next index of the groups to be spawned. This function is complicated, as it is used at several spaces.
function SPAWN:_GetSpawnIndex( SpawnIndex )
	self:F( { self.SpawnTemplatePrefix, SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxUnitsAlive, self.AliveUnits, #self.SpawnTemplate.units } )

  
  if ( self.SpawnMaxGroups == 0 ) or ( SpawnIndex <= self.SpawnMaxGroups ) then
    if ( self.SpawnMaxUnitsAlive == 0 ) or ( self.AliveUnits < self.SpawnMaxUnitsAlive * #self.SpawnTemplate.units ) or self.UnControlled then
      if SpawnIndex and SpawnIndex >= self.SpawnCount + 1 then
        self.SpawnCount = self.SpawnCount + 1
        SpawnIndex = self.SpawnCount
      end
      self.SpawnIndex = SpawnIndex
      if not self.SpawnGroups[self.SpawnIndex] then
        self:_InitializeSpawnGroups( self.SpawnIndex )
      end
    else
      return nil
    end
  else
    return nil
  end
  
  return self.SpawnIndex
end


-- TODO Need to delete this... _DATABASE does this now ...
function SPAWN:_OnBirth( event )

	if timer.getTime0() < timer.getAbsTime() then -- dont need to add units spawned in at the start of the mission if mist is loaded in init line
		if event.initiator and event.initiator:getName() then
			local EventPrefix = self:_GetPrefixFromDCSUnit( event.initiator )
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
-- @todo Need to delete this... _DATABASE does this now ...
function SPAWN:_OnDeadOrCrash( event )
  self:F( self.SpawnTemplatePrefix,  event )

	if event.initiator and event.initiator:getName() then
		local EventPrefix = self:_GetPrefixFromDCSUnit( event.initiator )
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

--- Will detect AIR Units taking off... When the event takes place, the spawned Group is registered as airborne...
-- This is needed to ensure that Re-SPAWNing only is done for landed AIR Groups.
-- @todo Need to test for AIR Groups only...
function SPAWN:_OnTakeOff( event )
  self:F( self.SpawnTemplatePrefix,  event )

	if event.initiator and event.initiator:getName() then
		local SpawnGroup = self:_GetGroupFromDCSUnit( event.initiator )
		if SpawnGroup then
			self:T( { "TakeOff event: " .. event.initiator:getName(), event } )
			self:T( "self.Landed = false" )
			self.Landed = false
		end
	end
end

--- Will detect AIR Units landing... When the event takes place, the spawned Group is registered as landed.
-- This is needed to ensure that Re-SPAWNing is only done for landed AIR Groups.
-- @todo Need to test for AIR Groups only...
function SPAWN:_OnLand( event )
  self:F( self.SpawnTemplatePrefix,  event )

  local SpawnUnit = event.initiator
	if SpawnUnit and SpawnUnit:isExist() and Object.getCategory(SpawnUnit) == Object.Category.UNIT then
		local SpawnGroup = self:_GetGroupFromDCSUnit( SpawnUnit )
		if SpawnGroup then
			self:T( { "Landed event:" .. SpawnUnit:getName(), event } )
			self.Landed = true
			self:T( "self.Landed = true" )
			if self.Landed and self.RepeatOnLanding then
				local SpawnGroupIndex = self:GetSpawnIndexFromGroup( SpawnGroup )
				self:T( { "Landed:", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
				self:ReSpawn( SpawnGroupIndex )
			end
		end
	end
end

--- Will detect AIR Units shutting down their engines ...
-- When the event takes place, and the method @{RepeatOnEngineShutDown} was called, the spawned Group will Re-SPAWN.
-- But only when the Unit was registered to have landed.
-- @param #SPAWN self
-- @see _OnTakeOff
-- @see _OnLand
-- @todo Need to test for AIR Groups only...
function SPAWN:_OnEngineShutDown( event )
  self:F( self.SpawnTemplatePrefix,  event )

  local SpawnUnit = event.initiator
  if SpawnUnit and SpawnUnit:isExist() and Object.getCategory(SpawnUnit) == Object.Category.UNIT then
		local SpawnGroup = self:_GetGroupFromDCSUnit( SpawnUnit )
		if SpawnGroup then
			self:T( { "EngineShutDown event: " .. SpawnUnit:getName(), event } )
			if self.Landed and self.RepeatOnEngineShutDown then
				local SpawnGroupIndex = self:GetSpawnIndexFromGroup( SpawnGroup )
				self:T( { "EngineShutDown: ", "ReSpawn:", SpawnGroup:GetName(), SpawnGroupIndex } )
				self:ReSpawn( SpawnGroupIndex )
			end
		end
	end
end

--- This function is called automatically by the Spawning scheduler.
-- It is the internal worker method SPAWNing new Groups on the defined time intervals.
function SPAWN:_Scheduler()
	self:F( { "_Scheduler", self.SpawnTemplatePrefix, self.SpawnAliasPrefix, self.SpawnIndex, self.SpawnMaxGroups, self.SpawnMaxUnitsAlive } )
	
	-- Validate if there are still groups left in the batch...
	self:Spawn()
	
	return true
end

function SPAWN:_SpawnCleanUpScheduler()
	self:F( { "CleanUp Scheduler:", self.SpawnTemplatePrefix } )

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
	
	return true -- Repeat
	
end
--- Limit the simultaneous movement of Groups within a running Mission.
-- This module is defined to improve the performance in missions, and to bring additional realism for GROUND vehicles.
-- Performance: If in a DCSRTE there are a lot of moving GROUND units, then in a multi player mission, this WILL create lag if
-- the main DCS execution core of your CPU is fully utilized. So, this class will limit the amount of simultaneous moving GROUND units
-- on defined intervals (currently every minute).
-- @module MOVEMENT

Include.File( "Routines" )

--- the MOVEMENT class
-- @type
MOVEMENT = {
	ClassName = "MOVEMENT",
}

--- Creates the main object which is handling the GROUND forces movement.
-- @param table{string,...}|string MovePrefixes is a table of the Prefixes (names) of the GROUND Groups that need to be controlled by the MOVEMENT Object.
-- @param number MoveMaximum is a number that defines the maximum amount of GROUND Units to be moving during one minute.
-- @return MOVEMENT
-- @usage
-- -- Limit the amount of simultaneous moving units on the ground to prevent lag.
-- Movement_US_Platoons = MOVEMENT:New( { 'US Tank Platoon Left', 'US Tank Platoon Middle', 'US Tank Platoon Right', 'US CH-47D Troops' }, 15 )

function MOVEMENT:New( MovePrefixes, MoveMaximum )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( { MovePrefixes, MoveMaximum } )
  
	if type( MovePrefixes ) == 'table' then
		self.MovePrefixes = MovePrefixes
	else
		self.MovePrefixes = { MovePrefixes }
	end
	self.MoveCount = 0															-- The internal counter of the amount of Moveing the has happened since MoveStart.
	self.MoveMaximum = MoveMaximum												-- Contains the Maximum amount of units that are allowed to move...
	self.AliveUnits = 0														-- Contains the counter how many units are currently alive
	self.MoveUnits = {}														-- Reflects if the Moving for this MovePrefixes is going to be scheduled or not.
	
	_EVENTDISPATCHER:OnBirth( self.OnBirth, self )
	
--	self:AddEvent( world.event.S_EVENT_BIRTH, self.OnBirth )
--	
--	self:EnableEvents()
	
	self:ScheduleStart()

	return self
end

--- Call this function to start the MOVEMENT scheduling.
function MOVEMENT:ScheduleStart()
	self:F()
	self.MoveFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, 120 )
end

--- Call this function to stop the MOVEMENT scheduling.
-- @todo need to implement it ... Forgot.
function MOVEMENT:ScheduleStop()
	self:F()

end

--- Captures the birth events when new Units were spawned.
-- @todo This method should become obsolete. The new @{DATABASE} class will handle the collection administration.
function MOVEMENT:OnBirth( Event )
	self:F( { Event } )

	if timer.getTime0() < timer.getAbsTime() then -- dont need to add units spawned in at the start of the mission if mist is loaded in init line
		if Event.IniDCSUnit then
			self:T( "Birth object : " .. Event.IniDCSUnitName )
			if Event.IniDCSGroup and Event.IniDCSGroup:isExist() then
				for MovePrefixID, MovePrefix in pairs( self.MovePrefixes ) do
					if string.find( Event.IniDCSUnitName, MovePrefix, 1, true ) then
						self.AliveUnits = self.AliveUnits + 1
						self.MoveUnits[Event.IniDCSUnitName] = Event.IniDCSGroupName
						self:T( self.AliveUnits )
					end
				end
			end
		end
		_EVENTDISPATCHER:OnCrashForUnit( Event.IniDCSUnitName, self.OnDeadOrCrash, self )
    _EVENTDISPATCHER:OnDeadForUnit( Event.IniDCSUnitName, self.OnDeadOrCrash, self )
	end

end

--- Captures the Dead or Crash events when Units crash or are destroyed.
-- @todo This method should become obsolete. The new @{DATABASE} class will handle the collection administration.
function MOVEMENT:OnDeadOrCrash( Event )
	self:F( { Event } )

	if Event.IniDCSUnit then
		self:T( "Dead object : " .. Event.IniDCSUnitName )
		for MovePrefixID, MovePrefix in pairs( self.MovePrefixes ) do
			if string.find( Event.IniDCSUnitName, MovePrefix, 1, true ) then
				self.AliveUnits = self.AliveUnits - 1
				self.MoveUnits[Event.IniDCSUnitName] = nil
				self:T( self.AliveUnits )
			end
		end
	end
end

--- This function is called automatically by the MOVEMENT scheduler. A new function is scheduled when MoveScheduled is true.
function MOVEMENT:_Scheduler()
	self:F( { self.MovePrefixes, self.MoveMaximum, self.AliveUnits, self.MovementGroups } )
	
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
-- @module Sead
-- @author to be searched on the forum
-- @author (co) Flightcontrol (Modified and enriched with functionality)

Include.File( "Routines" )
Include.File( "Event" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )

--- The SEAD class
-- @type SEAD
-- @extends Base#BASE
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
-- @param table{string,...}|string SEADGroupPrefixes which is a table of Prefixes of the SA Groups in the DCSRTE on which evasive actions need to be taken.
-- @return SEAD
-- @usage
-- -- CCCP SEAD Defenses
-- -- Defends the Russian SA installations from SEAD attacks.
-- SEAD_RU_SAM_Defenses = SEAD:New( { 'RU SA-6 Kub', 'RU SA-6 Defenses', 'RU MI-26 Troops', 'RU Attack Gori' } )
function SEAD:New( SEADGroupPrefixes )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( SEADGroupPrefixes )	
	if type( SEADGroupPrefixes ) == 'table' then
		for SEADGroupPrefixID, SEADGroupPrefix in pairs( SEADGroupPrefixes ) do
			self.SEADGroupPrefixes[SEADGroupPrefix] = SEADGroupPrefix
		end
	else
		self.SEADGroupNames[SEADGroupPrefixes] = SEADGroupPrefixes
	end
	_EVENTDISPATCHER:OnShot( self.EventShot, self )
	
	return self
end

--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see SEAD
function SEAD:EventShot( Event )
	self:F( { Event } )

	local SEADUnit = Event.IniDCSUnit
	local SEADUnitName = Event.IniDCSUnitName
	local SEADWeapon = Event.Weapon -- Identify the weapon fired						
	local SEADWeaponName = Event.WeaponName	-- return weapon type
	--trigger.action.outText( string.format("Alerte, depart missile " ..string.format(SEADWeaponName)), 20) --debug message
	-- Start of the 2nd loop
	self:T( "Missile Launched = " .. SEADWeaponName )
	if SEADWeaponName == "KH-58" or SEADWeaponName == "KH-25MPU" or SEADWeaponName == "AGM-88" or SEADWeaponName == "KH-31A" or SEADWeaponName == "KH-31P" then -- Check if the missile is a SEAD
		local _evade = math.random (1,100) -- random number for chance of evading action
		local _targetMim = Event.Weapon:getTarget() -- Identify target
		local _targetMimname = Unit.getName(_targetMim)
		local _targetMimgroup = Unit.getGroup(Weapon.getTarget(SEADWeapon))
		local _targetMimgroupName = _targetMimgroup:getName()
		local _targetMimcont= _targetMimgroup:getController()
		local _targetskill =  _DATABASE.Templates.Units[_targetMimname].Template.skill
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
--- Taking the lead of AI escorting your flight.
-- 
-- @{#ESCORT} class
-- ================
-- The @{#ESCORT} class allows you to interact with escorting AI on your flight and take the lead.
-- Each escorting group can be commanded with a whole set of radio commands (radio menu in your flight, and then F10).
--
-- The radio commands will vary according the category of the group. The richest set of commands are with Helicopters and AirPlanes.
-- Ships and Ground troops will have a more limited set, but they can provide support through the bombing of targets designated by the other escorts.
--
-- RADIO MENUs that can be created:
-- ================================
-- Find a summary below of the current available commands:
--
-- Navigation ...:
-- ---------------
-- Escort group navigation functions:
--
--   * **"Join-Up and Follow at x meters":** The escort group fill follow you at about x meters, and they will follow you.
--   * **"Flare":** Provides menu commands to let the escort group shoot a flare in the air in a color.
--   * **"Smoke":** Provides menu commands to let the escort group smoke the air in a color. Note that smoking is only available for ground and naval troops.
--
-- Hold position ...:
-- ------------------
-- Escort group navigation functions:
--
--   * **"At current location":** Stops the escort group and they will hover 30 meters above the ground at the position they stopped.
--   * **"At client location":** Stops the escort group and they will hover 30 meters above the ground at the position they stopped.
--
-- Report targets ...:
-- -------------------
-- Report targets will make the escort group to report any target that it identifies within a 8km range. Any detected target can be attacked using the 4. Attack nearby targets function. (see below).
--
--   * **"Report now":** Will report the current detected targets.
--   * **"Report targets on":** Will make the escort group to report detected targets and will fill the "Attack nearby targets" menu list.
--   * **"Report targets off":** Will stop detecting targets.
--
-- Scan targets ...:
-- -----------------
-- Menu items to pop-up the escort group for target scanning. After scanning, the escort group will resume with the mission or defined task.
--
--   * **"Scan targets 30 seconds":** Scan 30 seconds for targets.
--   * **"Scan targets 60 seconds":** Scan 60 seconds for targets.
--
-- Attack targets ...:
-- ------------------- 
-- This menu item will list all detected targets within a 15km range. Depending on the level of detection (known/unknown) and visuality, the targets type will also be listed.
--
-- Request assistance from ...:
-- ----------------------------
-- This menu item will list all detected targets within a 15km range, as with the menu item **Attack Targets**.
-- This menu item allows to request attack support from other escorts supporting the current client group.
-- eg. the function allows a player to request support from the Ship escort to attack a target identified by the Plane escort with its Tomahawk missiles.
-- eg. the function allows a player to request support from other Planes escorting to bomb the unit with illumination missiles or bombs, so that the main plane escort can attack the area.
--
-- ROE ...:
-- -------- 
-- Sets the Rules of Engagement (ROE) of the escort group when in flight.
--
--   * **"Hold Fire":** The escort group will hold fire.
--   * **"Return Fire":** The escort group will return fire.
--   * **"Open Fire":** The escort group will open fire on designated targets.
--   * **"Weapon Free":** The escort group will engage with any target.
--
-- Evasion ...:
-- ------------
-- Will define the evasion techniques that the escort group will perform during flight or combat.
--
--   * **"Fight until death":** The escort group will have no reaction to threats.
--   * **"Use flares, chaff and jammers":** The escort group will use passive defense using flares and jammers. No evasive manoeuvres are executed.
--   * **"Evade enemy fire":** The rescort group will evade enemy fire before firing.
--   * **"Go below radar and evade fire":** The escort group will perform evasive vertical manoeuvres.
--
-- Resume Mission ...:
-- -------------------
-- Escort groups can have their own mission. This menu item will allow the escort group to resume their Mission from a given waypoint.
-- Note that this is really fantastic, as you now have the dynamic of taking control of the escort groups, and allowing them to resume their path or mission.
--
-- ESCORT construction methods.
-- ============================
-- Create a new SPAWN object with the @{#ESCORT.New} method:
--
--  * @{#ESCORT.New}: Creates a new ESCORT object from a @{Group#GROUP} for a @{Client#CLIENT}, with an optional briefing text.
--
-- ESCORT initialization methods.
-- ==============================
-- The following menus are created within the RADIO MENU of an active unit hosted by a player:
--
-- * @{#ESCORT.MenuFollowAt}: Creates a menu to make the escort follow the client.
-- * @{#ESCORT.MenuHoldAtEscortPosition}: Creates a menu to hold the escort at its current position.
-- * @{#ESCORT.MenuHoldAtLeaderPosition}: Creates a menu to hold the escort at the client position.
-- * @{#ESCORT.MenuScanForTargets}: Creates a menu so that the escort scans targets.
-- * @{#ESCORT.MenuFlare}: Creates a menu to disperse flares.
-- * @{#ESCORT.MenuSmoke}: Creates a menu to disparse smoke.
-- * @{#ESCORT.MenuReportTargets}: Creates a menu so that the escort reports targets.
-- * @{#ESCORT.MenuReportPosition}: Creates a menu so that the escort reports its current position from bullseye.
-- * @{#ESCORT.MenuAssistedAttack: Creates a menu so that the escort supportes assisted attack from other escorts with the client.
-- * @{#ESCORT.MenuROE: Creates a menu structure to set the rules of engagement of the escort.
-- * @{#ESCORT.MenuEvasion: Creates a menu structure to set the evasion techniques when the escort is under threat.
-- * @{#ESCORT.MenuResumeMission}: Creates a menu structure so that the escort can resume from a waypoint.
-- 
-- @module Escort
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Database" )
Include.File( "Group" )
Include.File( "Zone" )

--- 
-- @type ESCORT
-- @extends Base#BASE
-- @field Client#CLIENT EscortClient
-- @field Group#GROUP EscortGroup
-- @field #string EscortName
-- @field #ESCORT.MODE EscortMode The mode the escort is in.
-- @field #number FollowScheduler The id of the _FollowScheduler function.
-- @field #boolean ReportTargets If true, nearby targets are reported.
-- @Field DCSTypes#AI.Option.Air.val.ROE OptionROE Which ROE is set to the EscortGroup.
-- @field DCSTypes#AI.Option.Air.val.REACTION_ON_THREAT OptionReactionOnThreat Which REACTION_ON_THREAT is set to the EscortGroup.
-- @field Menu#MENU_CLIENT EscortMenuResumeMission
ESCORT = {
  ClassName = "ESCORT",
  EscortName = nil, -- The Escort Name
  EscortClient = nil,
  EscortGroup = nil,
  EscortMode = nil,
  MODE = {
    FOLLOW = 1,
    MISSION = 2,
  },
  Targets = {}, -- The identified targets
  FollowScheduler = nil,
  ReportTargets = true,
  OptionROE = AI.Option.Air.val.ROE.OPEN_FIRE,
  OptionReactionOnThreat = AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION,
  TaskPoints = {}
}

--- ESCORT.Mode class
-- @type ESCORT.MODE
-- @field #number FOLLOW
-- @field #number MISSION

--- MENUPARAM type
-- @type MENUPARAM
-- @field #ESCORT ParamSelf
-- @field #Distance ParamDistance
-- @field #function ParamFunction
-- @field #string ParamMessage

--- ESCORT class constructor for an AI group
-- @param #ESCORT self
-- @param Client#CLIENT EscortClient The client escorted by the EscortGroup.
-- @param Group#GROUP EscortGroup The group AI escorting the EscortClient.
-- @param #string EscortName Name of the escort.
-- @return #ESCORT self
function ESCORT:New( EscortClient, EscortGroup, EscortName, EscortBriefing )
  local self = BASE:Inherit( self, BASE:New() )
  self:F( { EscortClient, EscortGroup, EscortName } )

  self.EscortClient = EscortClient -- Client#CLIENT
  self.EscortGroup = EscortGroup -- Group#GROUP
  self.EscortName = EscortName
  self.EscortBriefing = EscortBriefing

  self:T( EscortGroup:GetClassNameAndID() )

  -- Set EscortGroup known at EscortClient.
  if not self.EscortClient._EscortGroups then
    self.EscortClient._EscortGroups = {}
  end

  if not self.EscortClient._EscortGroups[EscortGroup:GetName()] then
    self.EscortClient._EscortGroups[EscortGroup:GetName()] = {}
    self.EscortClient._EscortGroups[EscortGroup:GetName()].EscortGroup = self.EscortGroup
    self.EscortClient._EscortGroups[EscortGroup:GetName()].EscortName = self.EscortName
    self.EscortClient._EscortGroups[EscortGroup:GetName()].Targets = {}
    self.EscortMode = ESCORT.MODE.FOLLOW
  end


  self.EscortMenu = MENU_CLIENT:New( self.EscortClient, self.EscortName )

  self.EscortGroup:WayPointInitialize(1)

  self.EscortGroup:OptionROTVertical()
  self.EscortGroup:OptionROEOpenFire()

  EscortGroup:MessageToClient( EscortGroup:GetCategoryName() .. " '" .. EscortName .. "' (" .. EscortGroup:GetCallsign() .. ") reporting! " ..
    "We're escorting your flight. " ..
    "Use the Radio Menu and F10 and use the options under + " .. EscortName .. "\n",
    60, EscortClient
  )

  return self
end


--- Defines the default menus
-- @param #ESCORT self
-- @return #ESCORT
function ESCORT:Menus()
  self:F()

  self:MenuFollowAt( 100 )
  self:MenuFollowAt( 200 )
  self:MenuFollowAt( 300 )
  self:MenuFollowAt( 400 )

  self:MenuScanForTargets( 100, 60 )

  self:MenuHoldAtEscortPosition( 30 )
  self:MenuHoldAtLeaderPosition( 30 )

  self:MenuFlare()
  self:MenuSmoke()

  self:MenuReportTargets( 60 )
  self:MenuAssistedAttack()
  self:MenuROE()
  self:MenuEvasion()
  self:MenuResumeMission()

  return self
end



--- Defines a menu slot to let the escort Join and Follow you at a certain distance.
-- This menu will appear under **Navigation**.
-- @param #ESCORT self
-- @param DCSTypes#Distance Distance The distance in meters that the escort needs to follow the client.
-- @return #ESCORT
function ESCORT:MenuFollowAt( Distance )
  self:F(Distance)

  if self.EscortGroup:IsAir() then
    if not self.EscortMenuReportNavigation then
      self.EscortMenuReportNavigation = MENU_CLIENT:New( self.EscortClient, "Navigation", self.EscortMenu )
    end

    if not self.EscortMenuJoinUpAndFollow then
      self.EscortMenuJoinUpAndFollow = {}
    end

    self.EscortMenuJoinUpAndFollow[#self.EscortMenuJoinUpAndFollow+1] = MENU_CLIENT_COMMAND:New( self.EscortClient, "Join-Up and Follow at " .. Distance, self.EscortMenuReportNavigation, ESCORT._JoinUpAndFollow, { ParamSelf = self, ParamDistance = Distance } )

    self.EscortMode = ESCORT.MODE.FOLLOW
  end

  return self
end

--- Defines a menu slot to let the escort hold at their current position and stay low with a specified height during a specified time in seconds.
-- This menu will appear under **Hold position**.
-- @param #ESCORT self
-- @param DCSTypes#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCSTypes#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #ESCORT
-- TODO: Implement Seconds parameter. Challenge is to first develop the "continue from last activity" function.
function ESCORT:MenuHoldAtEscortPosition( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then

    if not self.EscortMenuHold then
      self.EscortMenuHold = MENU_CLIENT:New( self.EscortClient, "Hold position", self.EscortMenu )
    end

    if not Height then
      Height = 30
    end

    if not Seconds then
      Seconds = 0
    end

    local MenuText = ""
    if not MenuTextFormat then
      if Seconds == 0 then
        MenuText = string.format( "Hold at %d meter", Height )
      else
        MenuText = string.format( "Hold at %d meter for %d seconds", Height, Seconds )
      end
    else
      if Seconds == 0 then
        MenuText = string.format( MenuTextFormat, Height )
      else
        MenuText = string.format( MenuTextFormat, Height, Seconds )
      end
    end

    if not self.EscortMenuHoldPosition then
      self.EscortMenuHoldPosition = {}
    end

    self.EscortMenuHoldPosition[#self.EscortMenuHoldPosition+1] = MENU_CLIENT_COMMAND
      :New(
        self.EscortClient,
        MenuText,
        self.EscortMenuHold,
        ESCORT._HoldPosition,
        { ParamSelf = self,
          ParamOrbitGroup = self.EscortGroup,
          ParamHeight = Height,
          ParamSeconds = Seconds
        }
      )
  end

  return self
end


--- Defines a menu slot to let the escort hold at the client position and stay low with a specified height during a specified time in seconds.
-- This menu will appear under **Navigation**.
-- @param #ESCORT self
-- @param DCSTypes#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCSTypes#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain one or two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #ESCORT
-- TODO: Implement Seconds parameter. Challenge is to first develop the "continue from last activity" function.
function ESCORT:MenuHoldAtLeaderPosition( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then

    if not self.EscortMenuHold then
      self.EscortMenuHold = MENU_CLIENT:New( self.EscortClient, "Hold position", self.EscortMenu )
    end

    if not Height then
      Height = 30
    end

    if not Seconds then
      Seconds = 0
    end

    local MenuText = ""
    if not MenuTextFormat then
      if Seconds == 0 then
        MenuText = string.format( "Rejoin and hold at %d meter", Height )
      else
        MenuText = string.format( "Rejoin and hold at %d meter for %d seconds", Height, Seconds )
      end
    else
      if Seconds == 0 then
        MenuText = string.format( MenuTextFormat, Height )
      else
        MenuText = string.format( MenuTextFormat, Height, Seconds )
      end
    end

    if not self.EscortMenuHoldAtLeaderPosition then
      self.EscortMenuHoldAtLeaderPosition = {}
    end

    self.EscortMenuHoldAtLeaderPosition[#self.EscortMenuHoldAtLeaderPosition+1] = MENU_CLIENT_COMMAND
      :New(
        self.EscortClient,
        MenuText,
        self.EscortMenuHold,
        ESCORT._HoldPosition,
        { ParamSelf = self,
          ParamOrbitGroup = self.EscortClient,
          ParamHeight = Height,
          ParamSeconds = Seconds
        }
      )
  end

  return self
end

--- Defines a menu slot to let the escort scan for targets at a certain height for a certain time in seconds.
-- This menu will appear under **Scan targets**.
-- @param #ESCORT self
-- @param DCSTypes#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCSTypes#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain one or two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #ESCORT
function ESCORT:MenuScanForTargets( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then
    if not self.EscortMenuScan then
      self.EscortMenuScan = MENU_CLIENT:New( self.EscortClient, "Scan for targets", self.EscortMenu )
    end

    if not Height then
      Height = 100
    end

    if not Seconds then
      Seconds = 30
    end

    local MenuText = ""
    if not MenuTextFormat then
      if Seconds == 0 then
        MenuText = string.format( "At %d meter", Height )
      else
        MenuText = string.format( "At %d meter for %d seconds", Height, Seconds )
      end
    else
      if Seconds == 0 then
        MenuText = string.format( MenuTextFormat, Height )
      else
        MenuText = string.format( MenuTextFormat, Height, Seconds )
      end
    end

    if not self.EscortMenuScanForTargets then
      self.EscortMenuScanForTargets = {}
    end

    self.EscortMenuScanForTargets[#self.EscortMenuScanForTargets+1] = MENU_CLIENT_COMMAND
      :New(
        self.EscortClient,
        MenuText,
        self.EscortMenuScan,
        ESCORT._ScanTargets,
        { ParamSelf = self,
          ParamScanDuration = 30
        }
      )
  end

  return self
end



--- Defines a menu slot to let the escort disperse a flare in a certain color.
-- This menu will appear under **Navigation**.
-- The flare will be fired from the first unit in the group.
-- @param #ESCORT self
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. If no text is given, the default text will be displayed.
-- @return #ESCORT
function ESCORT:MenuFlare( MenuTextFormat )
  self:F()

  if not self.EscortMenuReportNavigation then
    self.EscortMenuReportNavigation = MENU_CLIENT:New( self.EscortClient, "Navigation", self.EscortMenu )
  end

  local MenuText = ""
  if not MenuTextFormat then
    MenuText = "Flare"
  else
    MenuText = MenuTextFormat
  end

  if not self.EscortMenuFlare then
    self.EscortMenuFlare = MENU_CLIENT:New( self.EscortClient, MenuText, self.EscortMenuReportNavigation, ESCORT._Flare, { ParamSelf = self } )
    self.EscortMenuFlareGreen  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release green flare",  self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.Green,  ParamMessage = "Released a green flare!"   } )
    self.EscortMenuFlareRed    = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release red flare",    self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.Red,    ParamMessage = "Released a red flare!"     } )
    self.EscortMenuFlareWhite  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release white flare",  self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.White,  ParamMessage = "Released a white flare!"   } )
    self.EscortMenuFlareYellow = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release yellow flare", self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.Yellow, ParamMessage = "Released a yellow flare!"  } )
  end

  return self
end

--- Defines a menu slot to let the escort disperse a smoke in a certain color.
-- This menu will appear under **Navigation**.
-- Note that smoke menu options will only be displayed for ships and ground units. Not for air units.
-- The smoke will be fired from the first unit in the group.
-- @param #ESCORT self
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. If no text is given, the default text will be displayed.
-- @return #ESCORT
function ESCORT:MenuSmoke( MenuTextFormat )
  self:F()

  if not self.EscortGroup:IsAir() then
    if not self.EscortMenuReportNavigation then
      self.EscortMenuReportNavigation = MENU_CLIENT:New( self.EscortClient, "Navigation", self.EscortMenu )
    end

    local MenuText = ""
    if not MenuTextFormat then
      MenuText = "Smoke"
    else
      MenuText = MenuTextFormat
    end

    if not self.EscortMenuSmoke then
      self.EscortMenuSmoke = MENU_CLIENT:New( self.EscortClient, "Smoke", self.EscortMenuReportNavigation, ESCORT._Smoke, { ParamSelf = self } )
      self.EscortMenuSmokeGreen  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release green smoke",  self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Green,  ParamMessage = "Releasing green smoke!"   } )
      self.EscortMenuSmokeRed    = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release red smoke",    self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Red,    ParamMessage = "Releasing red smoke!"     } )
      self.EscortMenuSmokeWhite  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release white smoke",  self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.White,  ParamMessage = "Releasing white smoke!"   } )
      self.EscortMenuSmokeOrange = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release orange smoke", self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Orange, ParamMessage = "Releasing orange smoke!"  } )
      self.EscortMenuSmokeBlue   = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release blue smoke",   self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Blue,   ParamMessage = "Releasing blue smoke!"   } )
    end
  end

  return self
end

--- Defines a menu slot to let the escort report their current detected targets with a specified time interval in seconds.
-- This menu will appear under **Report targets**.
-- Note that if a report targets menu is not specified, no targets will be detected by the escort, and the attack and assisted attack menus will not be displayed.
-- @param #ESCORT self
-- @param DCSTypes#Time Seconds Optional parameter that lets the escort report their current detected targets after specified time interval in seconds. The default time is 30 seconds.
-- @return #ESCORT
function ESCORT:MenuReportTargets( Seconds )
  self:F( { Seconds } )

  if not self.EscortMenuReportNearbyTargets then
    self.EscortMenuReportNearbyTargets = MENU_CLIENT:New( self.EscortClient, "Report targets", self.EscortMenu )
  end

  if not Seconds then
    Seconds = 30
  end

  -- Report Targets
  self.EscortMenuReportNearbyTargetsNow = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets now!", self.EscortMenuReportNearbyTargets, ESCORT._ReportNearbyTargetsNow, { ParamSelf = self } )
  self.EscortMenuReportNearbyTargetsOn = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets on", self.EscortMenuReportNearbyTargets, ESCORT._SwitchReportNearbyTargets, { ParamSelf = self, ParamReportTargets = true } )
  self.EscortMenuReportNearbyTargetsOff = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets off", self.EscortMenuReportNearbyTargets, ESCORT._SwitchReportNearbyTargets, { ParamSelf = self, ParamReportTargets = false, } )

  -- Attack Targets
  self.EscortMenuAttackNearbyTargets = MENU_CLIENT:New( self.EscortClient, "Attack targets", self.EscortMenu )


  self.ReportTargetsScheduler = routines.scheduleFunction( self._ReportTargetsScheduler, { self }, timer.getTime() + 1, Seconds )

  return self
end

--- Defines a menu slot to let the escort attack its detected targets using assisted attack from another escort joined also with the client.
-- This menu will appear under **Request assistance from**.
-- Note that this method needs to be preceded with the method MenuReportTargets.
-- @param #ESCORT self
-- @return #ESCORT
function ESCORT:MenuAssistedAttack()
  self:F()

  -- Request assistance from other escorts.
  -- This is very useful to let f.e. an escorting ship attack a target detected by an escorting plane...
  self.EscortMenuTargetAssistance = MENU_CLIENT:New( self.EscortClient, "Request assistance from", self.EscortMenu )

  return self
end

--- Defines a menu to let the escort set its rules of engagement.
-- All rules of engagement will appear under the menu **ROE**.
-- @param #ESCORT self
-- @return #ESCORT
function ESCORT:MenuROE( MenuTextFormat )
  self:F( MenuTextFormat )

  if not self.EscortMenuROE then
    -- Rules of Engagement
    self.EscortMenuROE = MENU_CLIENT:New( self.EscortClient, "ROE", self.EscortMenu )
    if self.EscortGroup:OptionROEHoldFirePossible() then
      self.EscortMenuROEHoldFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Hold Fire", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROEHoldFire(), ParamMessage = "Holding weapons!" } )
    end
    if self.EscortGroup:OptionROEReturnFirePossible() then
      self.EscortMenuROEReturnFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Return Fire", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROEReturnFire(), ParamMessage = "Returning fire!" } )
    end
    if self.EscortGroup:OptionROEOpenFirePossible() then
      self.EscortMenuROEOpenFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Open Fire", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROEOpenFire(), ParamMessage = "Opening fire on designated targets!!" } )
    end
    if self.EscortGroup:OptionROEWeaponFreePossible() then
      self.EscortMenuROEWeaponFree = MENU_CLIENT_COMMAND:New( self.EscortClient, "Weapon Free", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROEWeaponFree(), ParamMessage = "Opening fire on targets of opportunity!" } )
    end
  end

  return self
end


--- Defines a menu to let the escort set its evasion when under threat.
-- All rules of engagement will appear under the menu **Evasion**.
-- @param #ESCORT self
-- @return #ESCORT
function ESCORT:MenuEvasion( MenuTextFormat )
  self:F( MenuTextFormat )

  if self.EscortGroup:IsAir() then
    if not self.EscortMenuEvasion then
      -- Reaction to Threats
      self.EscortMenuEvasion = MENU_CLIENT:New( self.EscortClient, "Evasion", self.EscortMenu )
      if self.EscortGroup:OptionROTNoReactionPossible() then
        self.EscortMenuEvasionNoReaction = MENU_CLIENT_COMMAND:New( self.EscortClient, "Fight until death", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROTNoReaction(), ParamMessage = "Fighting until death!" } )
      end
      if self.EscortGroup:OptionROTPassiveDefensePossible() then
        self.EscortMenuEvasionPassiveDefense = MENU_CLIENT_COMMAND:New( self.EscortClient, "Use flares, chaff and jammers", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROTPassiveDefense(), ParamMessage = "Defending using jammers, chaff and flares!" } )
      end
      if self.EscortGroup:OptionROTEvadeFirePossible() then
        self.EscortMenuEvasionEvadeFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Evade enemy fire", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROTEvadeFire(), ParamMessage = "Evading on enemy fire!" } )
      end
      if self.EscortGroup:OptionROTVerticalPossible() then
        self.EscortMenuOptionEvasionVertical = MENU_CLIENT_COMMAND:New( self.EscortClient, "Go below radar and evade fire", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROTVertical(), ParamMessage = "Evading on enemy fire with vertical manoeuvres!" } )
      end
    end
  end

  return self
end

--- Defines a menu to let the escort resume its mission from a waypoint on its route.
-- All rules of engagement will appear under the menu **Resume mission from**.
-- @param #ESCORT self
-- @return #ESCORT
function ESCORT:MenuResumeMission()
  self:F()

  if not self.EscortMenuResumeMission then
    -- Mission Resume Menu Root
    self.EscortMenuResumeMission = MENU_CLIENT:New( self.EscortClient, "Resume mission from", self.EscortMenu )
  end

  return self
end


--- @param #MENUPARAM MenuParam
function ESCORT._HoldPosition( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local OrbitGroup = MenuParam.ParamOrbitGroup -- Group#GROUP
  local OrbitUnit = OrbitGroup:GetUnit(1) -- Unit#UNIT
  local OrbitHeight = MenuParam.ParamHeight
  local OrbitSeconds = MenuParam.ParamSeconds -- Not implemented yet

  routines.removeFunction( self.FollowScheduler )

  local PointFrom = {}
  local GroupPoint = EscortGroup:GetUnit(1):GetPositionVec3()
  PointFrom = {}
  PointFrom.x = GroupPoint.x
  PointFrom.y = GroupPoint.z
  PointFrom.speed = 250
  PointFrom.type = AI.Task.WaypointType.TURNING_POINT
  PointFrom.alt = GroupPoint.y
  PointFrom.alt_type = AI.Task.AltitudeType.BARO

  local OrbitPoint = OrbitUnit:GetPointVec2()
  local PointTo = {}
  PointTo.x = OrbitPoint.x
  PointTo.y = OrbitPoint.y
  PointTo.speed = 250
  PointTo.type = AI.Task.WaypointType.TURNING_POINT
  PointTo.alt = OrbitHeight
  PointTo.alt_type = AI.Task.AltitudeType.BARO
  PointTo.task = EscortGroup:TaskOrbitCircleAtVec2( OrbitPoint, OrbitHeight, 0 )

  local Points = { PointFrom, PointTo }

  EscortGroup:OptionROEHoldFire()
  EscortGroup:OptionROTPassiveDefense()

  EscortGroup:SetTask( EscortGroup:TaskRoute( Points ) )
  EscortGroup:MessageToClient( "Orbiting at location.", 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._JoinUpAndFollow( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  self.Distance = MenuParam.ParamDistance

  self:JoinUpAndFollow( EscortGroup, EscortClient, self.Distance )
end

--- JoinsUp and Follows a CLIENT.
-- @param Escort#ESCORT self
-- @param Group#GROUP EscortGroup
-- @param Client#CLIENT EscortClient
-- @param DCSTypes#Distance Distance
function ESCORT:JoinUpAndFollow( EscortGroup, EscortClient, Distance )
  self:F( { EscortGroup, EscortClient, Distance } )

  if self.FollowScheduler then
    routines.removeFunction( self.FollowScheduler )
  end

  EscortGroup:OptionROEHoldFire()
  EscortGroup:OptionROTPassiveDefense()

  self.EscortMode = ESCORT.MODE.FOLLOW

  self.CT1 = 0
  self.GT1 = 0
  self.FollowScheduler = routines.scheduleFunction( self._FollowScheduler, { self, Distance }, timer.getTime() + 1, .5 )
  EscortGroup:MessageToClient( "Rejoining and Following at " .. Distance .. "!", 30, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._Flare( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local Color = MenuParam.ParamColor
  local Message = MenuParam.ParamMessage

  EscortGroup:GetUnit(1):Flare( Color )
  EscortGroup:MessageToClient( Message, 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._Smoke( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local Color = MenuParam.ParamColor
  local Message = MenuParam.ParamMessage

  EscortGroup:GetUnit(1):Smoke( Color )
  EscortGroup:MessageToClient( Message, 10, EscortClient )
end


--- @param #MENUPARAM MenuParam
function ESCORT._ReportNearbyTargetsNow( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  self:_ReportTargetsScheduler()

end

function ESCORT._SwitchReportNearbyTargets( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  self.ReportTargets = MenuParam.ParamReportTargets

  if self.ReportTargets then
    if not self.ReportTargetsScheduler then
      self.ReportTargetsScheduler = routines.scheduleFunction( self._ReportTargetsScheduler, { self }, timer.getTime() + 1, 30 )
    end
  else
    routines.removeFunction( self.ReportTargetsScheduler )
    self.ReportTargetsScheduler = nil
  end
end

--- @param #MENUPARAM MenuParam
function ESCORT._ScanTargets( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local ScanDuration = MenuParam.ParamScanDuration

  if self.FollowScheduler then
    routines.removeFunction( self.FollowScheduler )
  end

  self:T( { "FollowScheduler after removefunction: ", self.FollowScheduler } )

  if EscortGroup:IsHelicopter() then
    routines.scheduleFunction( EscortGroup.PushTask,
      { EscortGroup,
        EscortGroup:TaskControlled(
          EscortGroup:TaskOrbitCircle( 200, 20 ),
          EscortGroup:TaskCondition( nil, nil, nil, nil, ScanDuration, nil )
        )
      },
      timer.getTime() + 1
    )
  elseif EscortGroup:IsAirPlane() then
    routines.scheduleFunction( EscortGroup.PushTask,
      { EscortGroup,
        EscortGroup:TaskControlled(
          EscortGroup:TaskOrbitCircle( 1000, 500 ),
          EscortGroup:TaskCondition( nil, nil, nil, nil, ScanDuration, nil )
        )
      },
      timer.getTime() + 1
    )
  end

  EscortGroup:MessageToClient( "Scanning targets for " .. ScanDuration .. " seconds.", ScanDuration, EscortClient )

  if self.EscortMode == ESCORT.MODE.FOLLOW then
    self.FollowScheduler = routines.scheduleFunction( self._FollowScheduler, { self, Distance }, timer.getTime() + ScanDuration, 1 )
  end

end

function _Resume( EscortGroup )
  env.info( '_Resume' )

  local Escort = EscortGroup.Escort -- #ESCORT
  env.info( "EscortMode = "  .. Escort.EscortMode )
  if Escort.EscortMode == ESCORT.MODE.FOLLOW then
    Escort:JoinUpAndFollow( EscortGroup, Escort.EscortClient, Escort.Distance )
  end

end

--- @param #MENUPARAM MenuParam
function ESCORT._AttackTarget( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  local AttackUnit = MenuParam.ParamUnit -- Unit#UNIT

  if self.FollowScheduler then
    routines.removeFunction( self.FollowScheduler )
  end

  self:T( AttackUnit )

  if EscortGroup:IsAir() then
    EscortGroup:OptionROEOpenFire()
    EscortGroup:OptionROTPassiveDefense()
    EscortGroup.Escort = self -- Need to do this trick to get the reference for the escort in the _Resume function.
    routines.scheduleFunction(
      EscortGroup.PushTask,
      { EscortGroup,
        EscortGroup:TaskCombo(
          { EscortGroup:TaskAttackUnit( AttackUnit ),
            EscortGroup:TaskFunction( 1, 2, "_Resume", {"''"} )
          }
        )
      }, timer.getTime() + 10
    )
  else
    routines.scheduleFunction(
      EscortGroup.PushTask,
      { EscortGroup,
        EscortGroup:TaskCombo(
          { EscortGroup:TaskFireAtPoint( AttackUnit:GetPointVec2(), 50 )
          }
        )
      }, timer.getTime() + 10
    )
  end
  EscortGroup:MessageToClient( "Engaging Designated Unit!", 10, EscortClient )


end

--- @param #MENUPARAM MenuParam
function ESCORT._AssistTarget( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  local EscortGroupAttack = MenuParam.ParamEscortGroup
  local AttackUnit = MenuParam.ParamUnit -- Unit#UNIT

  if self.FollowScheduler then
    routines.removeFunction( self.FollowScheduler )
  end


  self:T( AttackUnit )

  if EscortGroupAttack:IsAir() then
    EscortGroupAttack:OptionROEOpenFire()
    EscortGroupAttack:OptionROTVertical()
    routines.scheduleFunction(
      EscortGroupAttack.PushTask,
      { EscortGroupAttack,
        EscortGroupAttack:TaskCombo(
          { EscortGroupAttack:TaskAttackUnit( AttackUnit ),
            EscortGroupAttack:TaskOrbitCircle( 500, 350 )
          }
        )
      }, timer.getTime() + 10
    )
  else
    routines.scheduleFunction(
      EscortGroupAttack.PushTask,
      { EscortGroupAttack,
        EscortGroupAttack:TaskCombo(
          { EscortGroupAttack:TaskFireAtPoint( AttackUnit:GetPointVec2(), 50 )
          }
        )
      }, timer.getTime() + 10
    )
  end
  EscortGroupAttack:MessageToClient( "Assisting with the destroying the enemy unit!", 10, EscortClient )

end

--- @param #MENUPARAM MenuParam
function ESCORT._ROE( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local EscortROEFunction = MenuParam.ParamFunction
  local EscortROEMessage = MenuParam.ParamMessage

  pcall( function() EscortROEFunction() end )
  EscortGroup:MessageToClient( EscortROEMessage, 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._ROT( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local EscortROTFunction = MenuParam.ParamFunction
  local EscortROTMessage = MenuParam.ParamMessage

  pcall( function() EscortROTFunction() end )
  EscortGroup:MessageToClient( EscortROTMessage, 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._ResumeMission( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local WayPoint = MenuParam.ParamWayPoint

  routines.removeFunction( self.FollowScheduler )
  self.FollowScheduler = nil

  local WayPoints = EscortGroup:GetTaskRoute()
  self:T( WayPoint, WayPoints )

  for WayPointIgnore = 1, WayPoint do
    table.remove( WayPoints, 1 )
  end

  routines.scheduleFunction( EscortGroup.SetTask, {EscortGroup, EscortGroup:TaskRoute( WayPoints ) }, timer.getTime() + 1 )

  EscortGroup:MessageToClient( "Resuming mission from waypoint " .. WayPoint .. ".", 10, EscortClient )
end

--- Registers the waypoints
-- @param #ESCORT self
-- @return #table
function ESCORT:RegisterRoute()
  self:F()

  local EscortGroup = self.EscortGroup -- Group#GROUP

  local TaskPoints = EscortGroup:GetTaskRoute()

  self:T( TaskPoints )

  return TaskPoints
end

--- @param Escort#ESCORT self
function ESCORT:_FollowScheduler( FollowDistance )
  self:F( { FollowDistance })

  if self.EscortGroup:IsAlive() and self.EscortClient:IsAlive() then

    local ClientUnit = self.EscortClient:GetClientGroupUnit()
    local GroupUnit = self.EscortGroup:GetUnit( 1 )

    if self.CT1 == 0 and self.GT1 == 0 then
      self.CV1 = ClientUnit:GetPositionVec3()
      self.CT1 = timer.getTime()
      self.GV1 = GroupUnit:GetPositionVec3()
      self.GT1 = timer.getTime()
    else
      local CT1 = self.CT1
      local CT2 = timer.getTime()
      local CV1 = self.CV1
      local CV2 = ClientUnit:GetPositionVec3()
      self.CT1 = CT2
      self.CV1 = CV2

      local CD = ( ( CV2.x - CV1.x )^2 + ( CV2.y - CV1.y )^2 + ( CV2.z - CV1.z )^2 ) ^ 0.5
      local CT = CT2 - CT1

      local CS = ( 3600 / CT ) * ( CD / 1000 )

      self:T2( { "Client:", CS, CD, CT, CV2, CV1, CT2, CT1 } )

      local GT1 = self.GT1
      local GT2 = timer.getTime()
      local GV1 = self.GV1
      local GV2 = GroupUnit:GetPositionVec3()
      self.GT1 = GT2
      self.GV1 = GV2

      local GD = ( ( GV2.x - GV1.x )^2 + ( GV2.y - GV1.y )^2 + ( GV2.z - GV1.z )^2 ) ^ 0.5
      local GT = GT2 - GT1

      local GS = ( 3600 / GT ) * ( GD / 1000 )

      self:T2( { "Group:", GS, GD, GT, GV2, GV1, GT2, GT1 } )

      -- Calculate the group direction vector
      local GV = { x = GV2.x - CV2.x, y = GV2.y - CV2.y, z = GV2.z - CV2.z }

      -- Calculate GH2, GH2 with the same height as CV2.
      local GH2 = { x = GV2.x, y = CV2.y, z = GV2.z }

      -- Calculate the angle of GV to the orthonormal plane
      local alpha = math.atan2( GV.z, GV.x )

      -- Now we calculate the intersecting vector between the circle around CV2 with radius FollowDistance and GH2.
      -- From the GeoGebra model: CVI = (x(CV2) + FollowDistance cos(alpha), y(GH2) + FollowDistance sin(alpha), z(CV2))
      local CVI = { x = CV2.x + FollowDistance * math.cos(alpha),
        y = GH2.y,
        z = CV2.z + FollowDistance * math.sin(alpha),
      }

      -- Calculate the direction vector DV of the escort group. We use CVI as the base and CV2 as the direction.
      local DV = { x = CV2.x - CVI.x, y = CV2.y - CVI.y, z = CV2.z - CVI.z }

      -- We now calculate the unary direction vector DVu, so that we can multiply DVu with the speed, which is expressed in meters / s.
      -- We need to calculate this vector to predict the point the escort group needs to fly to according its speed.
      -- The distance of the destination point should be far enough not to have the aircraft starting to swipe left to right...
      local DVu = { x = DV.x / FollowDistance, y = DV.y / FollowDistance, z = DV.z / FollowDistance }

      -- Now we can calculate the group destination vector GDV.
      local GDV = { x = DVu.x * CS * 8 + CVI.x, y = CVI.y, z = DVu.z * CS * 8 + CVI.z }
      self:T2( { "CV2:", CV2 } )
      self:T2( { "CVI:", CVI } )
      self:T2( { "GDV:", GDV } )

      -- Measure distance between client and group
      local CatchUpDistance = ( ( GDV.x - GV2.x )^2 + ( GDV.y - GV2.y )^2 + ( GDV.z - GV2.z )^2 ) ^ 0.5

      -- The calculation of the Speed would simulate that the group would take 30 seconds to overcome
      -- the requested Distance).
      local Time = 10
      local CatchUpSpeed = ( CatchUpDistance - ( CS * 8.4 ) ) / Time

      local Speed = CS + CatchUpSpeed
      if Speed < 0 then
        Speed = 0
      end

      self:T( { "Client Speed, Escort Speed, Speed, FlyDistance, Time:", CS, GS, Speed, Distance, Time } )

      -- Now route the escort to the desired point with the desired speed.
      self.EscortGroup:TaskRouteToVec3( GDV, Speed / 3.6 ) -- DCS models speed in Mps (Miles per second)
    end
  else
    routines.removeFunction( self.FollowScheduler )
  end

end


--- Report Targets Scheduler.
-- @param #ESCORT self
function ESCORT:_ReportTargetsScheduler()
  self:F( self.EscortGroup:GetName() )

  if self.EscortGroup:IsAlive() and self.EscortClient:IsAlive() then
    local EscortGroupName = self.EscortGroup:GetName()
    local EscortTargets = self.EscortGroup:GetDetectedTargets()

    local ClientEscortTargets = self.EscortClient._EscortGroups[EscortGroupName].Targets

    local EscortTargetMessages = ""
    for EscortTargetID, EscortTarget in pairs( EscortTargets ) do
      local EscortObject = EscortTarget.object
      self:T( EscortObject )
      if EscortObject and EscortObject:isExist() and EscortObject.id_ < 50000000 then

        local EscortTargetUnit = UNIT:New( EscortObject )
        local EscortTargetUnitName = EscortTargetUnit:GetName()



        --          local EscortTargetIsDetected,
        --                EscortTargetIsVisible,
        --                EscortTargetLastTime,
        --                EscortTargetKnowType,
        --                EscortTargetKnowDistance,
        --                EscortTargetLastPos,
        --                EscortTargetLastVelocity
        --                = self.EscortGroup:IsTargetDetected( EscortObject )
        --
        --          self:T( { EscortTargetIsDetected,
        --                EscortTargetIsVisible,
        --                EscortTargetLastTime,
        --                EscortTargetKnowType,
        --                EscortTargetKnowDistance,
        --                EscortTargetLastPos,
        --                EscortTargetLastVelocity } )


        local EscortTargetUnitPositionVec3 = EscortTargetUnit:GetPositionVec3()
        local EscortPositionVec3 = self.EscortGroup:GetPositionVec3()
        local Distance = ( ( EscortTargetUnitPositionVec3.x - EscortPositionVec3.x )^2 +
          ( EscortTargetUnitPositionVec3.y - EscortPositionVec3.y )^2 +
          ( EscortTargetUnitPositionVec3.z - EscortPositionVec3.z )^2
          ) ^ 0.5 / 1000

        self:T( { self.EscortGroup:GetName(), EscortTargetUnit:GetName(), Distance, EscortTarget } )

        if Distance <= 15 then

          if not ClientEscortTargets[EscortTargetUnitName] then
            ClientEscortTargets[EscortTargetUnitName] = {}
          end
          ClientEscortTargets[EscortTargetUnitName].AttackUnit = EscortTargetUnit
          ClientEscortTargets[EscortTargetUnitName].visible = EscortTarget.visible
          ClientEscortTargets[EscortTargetUnitName].type = EscortTarget.type
          ClientEscortTargets[EscortTargetUnitName].distance = EscortTarget.distance
        else
          if ClientEscortTargets[EscortTargetUnitName] then
            ClientEscortTargets[EscortTargetUnitName] = nil
          end
        end
      end
    end

    self:T( { "Sorting Targets Table:", ClientEscortTargets } )
    table.sort( ClientEscortTargets, function( a, b ) return a.Distance < b.Distance end )
    self:T( { "Sorted Targets Table:", ClientEscortTargets } )

    -- Remove the sub menus of the Attack menu of the Escort for the EscortGroup.
    self.EscortMenuAttackNearbyTargets:RemoveSubMenus()

    if self.EscortMenuTargetAssistance then
      self.EscortMenuTargetAssistance:RemoveSubMenus()
    end

    --for MenuIndex = 1, #self.EscortMenuAttackTargets do
    --  self:T( { "Remove Menu:", self.EscortMenuAttackTargets[MenuIndex] } )
    --  self.EscortMenuAttackTargets[MenuIndex] = self.EscortMenuAttackTargets[MenuIndex]:Remove()
    --end


    if ClientEscortTargets then
      for ClientEscortTargetUnitName, ClientEscortTargetData in pairs( ClientEscortTargets ) do

        for ClientEscortGroupName, EscortGroupData in pairs( self.EscortClient._EscortGroups ) do

          if ClientEscortTargetData and ClientEscortTargetData.AttackUnit:IsAlive() then

            local EscortTargetMessage = ""
            local EscortTargetCategoryName = ClientEscortTargetData.AttackUnit:GetCategoryName()
            local EscortTargetCategoryType = ClientEscortTargetData.AttackUnit:GetTypeName()
            if ClientEscortTargetData.type then
              EscortTargetMessage = EscortTargetMessage .. EscortTargetCategoryName .. " (" .. EscortTargetCategoryType .. ") at "
            else
              EscortTargetMessage = EscortTargetMessage .. "Unknown target at "
            end

            local EscortTargetUnitPositionVec3 = ClientEscortTargetData.AttackUnit:GetPositionVec3()
            local EscortPositionVec3 = self.EscortGroup:GetPositionVec3()
            local Distance = ( ( EscortTargetUnitPositionVec3.x - EscortPositionVec3.x )^2 +
              ( EscortTargetUnitPositionVec3.y - EscortPositionVec3.y )^2 +
              ( EscortTargetUnitPositionVec3.z - EscortPositionVec3.z )^2
              ) ^ 0.5 / 1000

            self:T( { self.EscortGroup:GetName(), ClientEscortTargetData.AttackUnit:GetName(), Distance, ClientEscortTargetData.AttackUnit } )
            if ClientEscortTargetData.visible == false then
              EscortTargetMessage = EscortTargetMessage .. string.format( "%.2f", Distance ) .. " estimated km"
            else
              EscortTargetMessage = EscortTargetMessage .. string.format( "%.2f", Distance ) .. " km"
            end

            if ClientEscortTargetData.visible then
              EscortTargetMessage = EscortTargetMessage .. ", visual"
            end

            if ClientEscortGroupName == EscortGroupName then

              MENU_CLIENT_COMMAND:New( self.EscortClient,
                EscortTargetMessage,
                self.EscortMenuAttackNearbyTargets,
                ESCORT._AttackTarget,
                { ParamSelf = self,
                  ParamUnit = ClientEscortTargetData.AttackUnit
                }
              )
              EscortTargetMessages = EscortTargetMessages .. "\n - " .. EscortTargetMessage
            else
              if self.EscortMenuTargetAssistance then
                local MenuTargetAssistance = MENU_CLIENT:New( self.EscortClient, EscortGroupData.EscortName, self.EscortMenuTargetAssistance )
                MENU_CLIENT_COMMAND:New( self.EscortClient,
                  EscortTargetMessage,
                  MenuTargetAssistance,
                  ESCORT._AssistTarget,
                  { ParamSelf = self,
                    ParamEscortGroup = EscortGroupData.EscortGroup,
                    ParamUnit = ClientEscortTargetData.AttackUnit
                  }
                )
              end
            end
          else
            ClientEscortTargetData = nil
          end
        end
      end

      if EscortTargetMessages ~= "" and self.ReportTargets == true then
        self.EscortGroup:MessageToClient( "Detected targets within 15 km range:" .. EscortTargetMessages:gsub("\n$",""), 20, self.EscortClient )
      else
        self.EscortGroup:MessageToClient( "No targets detected!", 20, self.EscortClient )
      end
    end

    if self.EscortMenuResumeMission then
      self.EscortMenuResumeMission:RemoveSubMenus()

      --    if self.EscortMenuResumeWayPoints then
      --      for MenuIndex = 1, #self.EscortMenuResumeWayPoints do
      --        self:T( { "Remove Menu:", self.EscortMenuResumeWayPoints[MenuIndex] } )
      --        self.EscortMenuResumeWayPoints[MenuIndex] = self.EscortMenuResumeWayPoints[MenuIndex]:Remove()
      --      end
      --    end

      local TaskPoints = self:RegisterRoute()
      for WayPointID, WayPoint in pairs( TaskPoints ) do
        local EscortPositionVec3 = self.EscortGroup:GetPositionVec3()
        local Distance = ( ( WayPoint.x - EscortPositionVec3.x )^2 +
          ( WayPoint.y - EscortPositionVec3.z )^2
          ) ^ 0.5 / 1000
        MENU_CLIENT_COMMAND:New( self.EscortClient, "Waypoint " .. WayPointID .. " at " .. string.format( "%.2f", Distance ).. "km", self.EscortMenuResumeMission, ESCORT._ResumeMission, { ParamSelf = self, ParamWayPoint = WayPointID } )
      end
    end

  else
    routines.removeFunction( self.ReportTargetsScheduler )
    self.ReportTargetsScheduler = nil
  end
end
--- Provides missile training functions.
--
-- @{#MISSILETRAINER} class
-- ========================
-- The @{#MISSILETRAINER} class uses the DCS world messaging system to be alerted of any missiles fired, and when a missile would hit your aircraft,
-- the class will destroy the missile within a certain range, to avoid damage to your aircraft.
-- It suports the following functionality:
--
--  * Track the missiles fired at you and other players, providing bearing and range information of the missiles towards the airplanes.
--  * Provide alerts of missile launches, including detailed information of the units launching, including bearing, range …
--  * Provide alerts when a missile would have killed your aircraft.
--  * Provide alerts when the missile self destructs.
--  * Enable / Disable and Configure the Missile Trainer using the various menu options.
--  
--  When running a mission where MISSILETRAINER is used, the following radio menu structure ( 'Radio Menu' -> 'Other (F10)' -> 'MissileTrainer' ) options are available for the players:
--  
--  * **Messages**: Menu to configure all messages.
--     * **Messages On**: Show all messages.
--     * **Messages Off**: Disable all messages.
--  * **Tracking**: Menu to configure missile tracking messages.
--     * **To All**: Shows missile tracking messages to all players.
--     * **To Target**: Shows missile tracking messages only to the player where the missile is targetted at.
--     * **Tracking On**: Show missile tracking messages.
--     * **Tracking Off**: Disable missile tracking messages.
--     * **Frequency Increase**: Increases the missile tracking message frequency with one second.
--     * **Frequency Decrease**: Decreases the missile tracking message frequency with one second.
--  * **Alerts**: Menu to configure alert messages.
--     * **To All**: Shows alert messages to all players.
--     * **To Target**: Shows alert messages only to the player where the missile is (was) targetted at.
--     * **Hits On**: Show missile hit alert messages.
--     * **Hits Off**: Disable missile hit alert messages.
--     * **Launches On**: Show missile launch messages.
--     * **Launches Off**: Disable missile launch messages.
--  * **Details**: Menu to configure message details.
--     * **Range On**: Shows range information when a missile is fired to a target.
--     * **Range Off**: Disable range information when a missile is fired to a target.
--     * **Bearing On**: Shows bearing information when a missile is fired to a target.
--     * **Bearing Off**: Disable bearing information when a missile is fired to a target.
--  * **Distance**: Menu to configure the distance when a missile needs to be destroyed when near to a player, during tracking. This will improve/influence hit calculation accuracy, but has the risk of damaging the aircraft when the missile reaches the aircraft before the distance is measured. 
--     * **50 meter**: Destroys the missile when the distance to the aircraft is below or equal to 50 meter.
--     * **100 meter**: Destroys the missile when the distance to the aircraft is below or equal to 100 meter.
--     * **150 meter**: Destroys the missile when the distance to the aircraft is below or equal to 150 meter.
--     * **200 meter**: Destroys the missile when the distance to the aircraft is below or equal to 200 meter.
--   
--
-- MISSILETRAINER construction methods:
-- ====================================
-- Create a new MISSILETRAINER object with the @{#MISSILETRAINER.New} method:
--
--   * @{#MISSILETRAINER.New}: Creates a new MISSILETRAINER object taking the maximum distance to your aircraft to evaluate when a missile needs to be destroyed.
--
-- MISSILETRAINER will collect each unit declared in the mission with a skill level "Client" and "Player", and will monitor the missiles shot at those.
--
-- MISSILETRAINER initialization methods:
-- ======================================
-- A MISSILETRAINER object will behave differently based on the usage of initialization methods:
--
--  * @{#MISSILETRAINER.InitMessagesOnOff}: Sets by default the display of any message to be ON or OFF.
--  * @{#MISSILETRAINER.InitTrackingToAll}: Sets by default the missile tracking report for all players or only for those missiles targetted to you.
--  * @{#MISSILETRAINER.InitTrackingOnOff}: Sets by default the display of missile tracking report to be ON or OFF.
--  * @{#MISSILETRAINER.InitTrackingFrequency}: Increases, decreases the missile tracking message display frequency with the provided time interval in seconds.
--  * @{#MISSILETRAINER.InitAlertsToAll}: Sets by default the display of alerts to be shown to all players or only to you.
--  * @{#MISSILETRAINER.InitAlertsHitsOnOff}: Sets by default the display of hit alerts ON or OFF.
--  * @{#MISSILETRAINER.InitAlertsLaunchesOnOff}: Sets by default the display of launch alerts ON or OFF.
--  * @{#MISSILETRAINER.InitRangeOnOff}: Sets by default the display of range information of missiles ON of OFF.
--  * @{#MISSILETRAINER.InitBearingOnOff}: Sets by default the display of bearing information of missiles ON of OFF.
--  * @{#MISSILETRAINER.InitMenusOnOff}: Allows to configure the options through the radio menu.
--
-- @module MissileTrainer
-- @author FlightControl


Include.File( "Client" )
Include.File( "Scheduler" )

--- The MISSILETRAINER class
-- @type MISSILETRAINER
-- @extends Base#BASE
MISSILETRAINER = {
  ClassName = "MISSILETRAINER",
}

--- Creates the main object which is handling missile tracking.
-- When a missile is fired a SCHEDULER is set off that follows the missile. When near a certain a client player, the missile will be destroyed.
-- @param #MISSILETRAINER self
-- @param #number Distance The distance in meters when a tracked missile needs to be destroyed when close to a player.
-- @param #string Briefing (Optional) Will show a text to the players when starting their mission. Can be used for briefing purposes. 
-- @return #MISSILETRAINER
function MISSILETRAINER:New( Distance, Briefing )
  local self = BASE:Inherit( self, BASE:New() )
  self:F( Distance )

  if Briefing then
    self.Briefing = Briefing
  end

  self.Schedulers = {}
  self.SchedulerID = 0

  self.MessageInterval = 2
  self.MessageLastTime = timer.getTime()

  self.Distance = Distance / 1000

  _EVENTDISPATCHER:OnShot( self._EventShot, self )

  self.DB = DATABASE:New():FilterStart()
  self.DBClients = self.DB.Clients
  self.DBUnits = self.DB.Units

  for ClientID, Client in pairs( self.DBClients ) do

    local function _Alive( Client )

      if self.Briefing then
        Client:Message( self.Briefing, 15, "HELLO WORLD", "Trainer" )
      end

      if self.MenusOnOff == true then
        Client:Message( "Use the 'Radio Menu' -> 'Other (F10)' -> 'Missile Trainer' menu options to change the Missile Trainer settings (for all players).", 15, "MENU", "Trainer" )
  
        Client.MainMenu = MENU_CLIENT:New( Client, "Missile Trainer", nil ) -- Menu#MENU_CLIENT
  
        Client.MenuMessages = MENU_CLIENT:New( Client, "Messages", Client.MainMenu )
        Client.MenuOn = MENU_CLIENT_COMMAND:New( Client, "Messages On", Client.MenuMessages, self._MenuMessages, { MenuSelf = self, MessagesOnOff = true } )
        Client.MenuOff = MENU_CLIENT_COMMAND:New( Client, "Messages Off", Client.MenuMessages, self._MenuMessages, { MenuSelf = self, MessagesOnOff = false } )
  
        Client.MenuTracking = MENU_CLIENT:New( Client, "Tracking", Client.MainMenu )
        Client.MenuTrackingToAll = MENU_CLIENT_COMMAND:New( Client, "To All", Client.MenuTracking, self._MenuMessages, { MenuSelf = self, TrackingToAll = true } )
        Client.MenuTrackingToTarget = MENU_CLIENT_COMMAND:New( Client, "To Target", Client.MenuTracking, self._MenuMessages, { MenuSelf = self, TrackingToAll = false } )
        Client.MenuTrackOn = MENU_CLIENT_COMMAND:New( Client, "Tracking On", Client.MenuTracking, self._MenuMessages, { MenuSelf = self, TrackingOnOff = true } )
        Client.MenuTrackOff = MENU_CLIENT_COMMAND:New( Client, "Tracking Off", Client.MenuTracking, self._MenuMessages, { MenuSelf = self, TrackingOnOff = false } )
        Client.MenuTrackIncrease = MENU_CLIENT_COMMAND:New( Client, "Frequency Increase", Client.MenuTracking, self._MenuMessages, { MenuSelf = self, TrackingFrequency = -1 } )
        Client.MenuTrackDecrease = MENU_CLIENT_COMMAND:New( Client, "Frequency Decrease", Client.MenuTracking, self._MenuMessages, { MenuSelf = self, TrackingFrequency = 1 } )
  
        Client.MenuAlerts = MENU_CLIENT:New( Client, "Alerts", Client.MainMenu )
        Client.MenuAlertsToAll = MENU_CLIENT_COMMAND:New( Client, "To All", Client.MenuAlerts, self._MenuMessages, { MenuSelf = self, AlertsToAll = true } )
        Client.MenuAlertsToTarget = MENU_CLIENT_COMMAND:New( Client, "To Target", Client.MenuAlerts, self._MenuMessages, { MenuSelf = self, AlertsToAll = false } )
        Client.MenuHitsOn = MENU_CLIENT_COMMAND:New( Client, "Hits On", Client.MenuAlerts, self._MenuMessages, { MenuSelf = self, AlertsHitsOnOff = true } )
        Client.MenuHitsOff = MENU_CLIENT_COMMAND:New( Client, "Hits Off", Client.MenuAlerts, self._MenuMessages, { MenuSelf = self, AlertsHitsOnOff = false } )
        Client.MenuLaunchesOn = MENU_CLIENT_COMMAND:New( Client, "Launches On", Client.MenuAlerts, self._MenuMessages, { MenuSelf = self, AlertsLaunchesOnOff = true } )
        Client.MenuLaunchesOff = MENU_CLIENT_COMMAND:New( Client, "Launches Off", Client.MenuAlerts, self._MenuMessages, { MenuSelf = self, AlertsLaunchesOnOff = false } )
  
        Client.MenuDetails = MENU_CLIENT:New( Client, "Details", Client.MainMenu )
        Client.MenuDetailsDistanceOn = MENU_CLIENT_COMMAND:New( Client, "Range On", Client.MenuDetails, self._MenuMessages, { MenuSelf = self, DetailsRangeOnOff = true } )
        Client.MenuDetailsDistanceOff = MENU_CLIENT_COMMAND:New( Client, "Range Off", Client.MenuDetails, self._MenuMessages, { MenuSelf = self, DetailsRangeOnOff = false } )
        Client.MenuDetailsBearingOn = MENU_CLIENT_COMMAND:New( Client, "Bearing On", Client.MenuDetails, self._MenuMessages, { MenuSelf = self, DetailsBearingOnOff = true } )
        Client.MenuDetailsBearingOff = MENU_CLIENT_COMMAND:New( Client, "Bearing Off", Client.MenuDetails, self._MenuMessages, { MenuSelf = self, DetailsBearingOnOff = false } )
  
        Client.MenuDistance = MENU_CLIENT:New( Client, "Set distance to plane", Client.MainMenu )
        Client.MenuDistance50 = MENU_CLIENT_COMMAND:New( Client, "50 meter", Client.MenuDistance, self._MenuMessages, { MenuSelf = self, Distance = 50 / 1000 } )
        Client.MenuDistance100 = MENU_CLIENT_COMMAND:New( Client, "100 meter", Client.MenuDistance, self._MenuMessages, { MenuSelf = self, Distance = 100 / 1000 } )
        Client.MenuDistance150 = MENU_CLIENT_COMMAND:New( Client, "150 meter", Client.MenuDistance, self._MenuMessages, { MenuSelf = self, Distance = 150 / 1000 } )
        Client.MenuDistance200 = MENU_CLIENT_COMMAND:New( Client, "200 meter", Client.MenuDistance, self._MenuMessages, { MenuSelf = self, Distance = 200 / 1000 } )
      else
        if Client.MainMenu then
          Client.MainMenu:Remove()
        end
      end


      local ClientID = Client:GetID()
      self:T( ClientID )
      if not self.TrackingMissiles[ClientID] then
        self.TrackingMissiles[ClientID] = {}
      end
      self.TrackingMissiles[ClientID].Client = Client
      if not self.TrackingMissiles[ClientID].MissileData then
        self.TrackingMissiles[ClientID].MissileData = {}
      end
    end

    Client:Alive( _Alive )

  end
  
--  	self.DB:ForEachClient(
--  	 --- @param Client#CLIENT Client
--  	 function( Client )
--  
--        ... actions ...
--        
--  	 end
--  	)

  self.MessagesOnOff = true

  self.TrackingToAll = false
  self.TrackingOnOff = true
  self.TrackingFrequency = 3

  self.AlertsToAll = true
  self.AlertsHitsOnOff = true
  self.AlertsLaunchesOnOff = true

  self.DetailsRangeOnOff = true
  self.DetailsBearingOnOff = true
  
  self.MenusOnOff = true

  self.TrackingMissiles = {}

  self.TrackingScheduler = SCHEDULER:New( self, self._TrackMissiles, {}, 0.5, 0.05, 0 )

  return self
end

-- Initialization methods.


--- Sets by default the display of any message to be ON or OFF.
-- @param #MISSILETRAINER self
-- @param #boolean MessagesOnOff true or false
-- @return #MISSILETRAINER self
function MISSILETRAINER:InitMessagesOnOff( MessagesOnOff )
  self:F( MessagesOnOff )

  self.MessagesOnOff = MessagesOnOff
  if self.MessagesOnOff == true then
    MESSAGE:New( "Messages ON", "Menu", 15, "ID" ):ToAll()
  else
    MESSAGE:New( "Messages OFF", "Menu", 15, "ID" ):ToAll()
  end

  return self
end

--- Sets by default the missile tracking report for all players or only for those missiles targetted to you.
-- @param #MISSILETRAINER self
-- @param #boolean TrackingToAll true or false
-- @return #MISSILETRAINER self
function MISSILETRAINER:InitTrackingToAll( TrackingToAll )
  self:F( TrackingToAll )

  self.TrackingToAll = TrackingToAll
  if self.TrackingToAll == true then
    MESSAGE:New( "Missile tracking to all players ON", "Menu", 15, "ID" ):ToAll()
  else
    MESSAGE:New( "Missile tracking to all players OFF", "Menu", 15, "ID" ):ToAll()
  end

  return self
end

--- Sets by default the display of missile tracking report to be ON or OFF.
-- @param #MISSILETRAINER self
-- @param #boolean TrackingOnOff true or false
-- @return #MISSILETRAINER self
function MISSILETRAINER:InitTrackingOnOff( TrackingOnOff )
  self:F( TrackingOnOff )

  self.TrackingOnOff = TrackingOnOff
  if self.TrackingOnOff == true then
    MESSAGE:New( "Missile tracking ON", "Menu", 15, "ID" ):ToAll()
  else
    MESSAGE:New( "Missile tracking OFF", "Menu", 15, "ID" ):ToAll()
  end

  return self
end

--- Increases, decreases the missile tracking message display frequency with the provided time interval in seconds.
-- The default frequency is a 3 second interval, so the Tracking Frequency parameter specifies the increase or decrease from the default 3 seconds or the last frequency update.
-- @param #MISSILETRAINER self
-- @param #number TrackingFrequency Provide a negative or positive value in seconds to incraese or decrease the display frequency. 
-- @return #MISSILETRAINER self
function MISSILETRAINER:InitTrackingFrequency( TrackingFrequency )
  self:F( TrackingFrequency )

  self.TrackingFrequency = self.TrackingFrequency + TrackingFrequency
  if self.TrackingFrequency < 0.5 then
    self.TrackingFrequency = 0.5
  end
  if self.TrackingFrequency then
    MESSAGE:New( "Missile tracking frequency is " .. self.TrackingFrequency .. " seconds.", "Menu", 15, "ID" ):ToAll()
  end

  return self
end

--- Sets by default the display of alerts to be shown to all players or only to you.
-- @param #MISSILETRAINER self
-- @param #boolean AlertsToAll true or false
-- @return #MISSILETRAINER self
function MISSILETRAINER:InitAlertsToAll( AlertsToAll )
  self:F( AlertsToAll )

  self.AlertsToAll = AlertsToAll
  if self.AlertsToAll == true then
    MESSAGE:New( "Alerts to all players ON", "Menu", 15, "ID" ):ToAll()
  else
    MESSAGE:New( "Alerts to all players OFF", "Menu", 15, "ID" ):ToAll()
  end

  return self
end

--- Sets by default the display of hit alerts ON or OFF.
-- @param #MISSILETRAINER self
-- @param #boolean AlertsHitsOnOff true or false
-- @return #MISSILETRAINER self
function MISSILETRAINER:InitAlertsHitsOnOff( AlertsHitsOnOff )
  self:F( AlertsHitsOnOff )

  self.AlertsHitsOnOff = AlertsHitsOnOff
  if self.AlertsHitsOnOff == true then
    MESSAGE:New( "Alerts Hits ON", "Menu", 15, "ID" ):ToAll()
  else
    MESSAGE:New( "Alerts Hits OFF", "Menu", 15, "ID" ):ToAll()
  end

  return self
end

--- Sets by default the display of launch alerts ON or OFF.
-- @param #MISSILETRAINER self
-- @param #boolean AlertsLaunchesOnOff true or false
-- @return #MISSILETRAINER self
function MISSILETRAINER:InitAlertsLaunchesOnOff( AlertsLaunchesOnOff )
  self:F( AlertsLaunchesOnOff )

  self.AlertsLaunchesOnOff = AlertsLaunchesOnOff
  if self.AlertsLaunchesOnOff == true then
    MESSAGE:New( "Alerts Launches ON", "Menu", 15, "ID" ):ToAll()
  else
    MESSAGE:New( "Alerts Launches OFF", "Menu", 15, "ID" ):ToAll()
  end

  return self
end

--- Sets by default the display of range information of missiles ON of OFF.
-- @param #MISSILETRAINER self
-- @param #boolean DetailsRangeOnOff true or false
-- @return #MISSILETRAINER self
function MISSILETRAINER:InitRangeOnOff( DetailsRangeOnOff )
  self:F( DetailsRangeOnOff )

  self.DetailsRangeOnOff = DetailsRangeOnOff
  if self.DetailsRangeOnOff == true then
    MESSAGE:New( "Range display ON", "Menu", 15, "ID" ):ToAll()
  else
    MESSAGE:New( "Range display OFF", "Menu", 15, "ID" ):ToAll()
  end

  return self
end

--- Sets by default the display of bearing information of missiles ON of OFF.
-- @param #MISSILETRAINER self
-- @param #boolean DetailsBearingOnOff true or false
-- @return #MISSILETRAINER self
function MISSILETRAINER:InitBearingOnOff( DetailsBearingOnOff )
  self:F( DetailsBearingOnOff )

  self.DetailsBearingOnOff = DetailsBearingOnOff
  if self.DetailsBearingOnOff == true then
    MESSAGE:New( "Bearing display OFF", "Menu", 15, "ID" ):ToAll()
  else
    MESSAGE:New( "Bearing display OFF", "Menu", 15, "ID" ):ToAll()
  end

  return self
end

--- Enables / Disables the menus.
-- @param #MISSILETRAINER self
-- @param #boolean MenusOnOff true or false
-- @return #MISSILETRAINER self
function MISSILETRAINER:InitMenusOnOff( MenusOnOff )
  self:F( MenusOnOff )

  self.MenusOnOff = MenusOnOff
  if self.MenusOnOff == true then
    MESSAGE:New( "Menus are ENABLED (only when a player rejoins a slot)", "Menu", 15, "ID" ):ToAll()
  else
    MESSAGE:New( "Menus are DISABLED", "Menu", 15, "ID" ):ToAll()
  end

  return self
end


-- Menu functions

function MISSILETRAINER._MenuMessages( MenuParameters )

  local self = MenuParameters.MenuSelf

  if MenuParameters.MessagesOnOff ~= nil then
    self:InitMessagesOnOff( MenuParameters.MessagesOnOff )
  end

  if MenuParameters.TrackingToAll ~= nil then
    self:InitTrackingToAll( MenuParameters.TrackingToAll )
  end

  if MenuParameters.TrackingOnOff ~= nil then
    self:InitTrackingOnOff( MenuParameters.TrackingOnOff )
  end

  if MenuParameters.TrackingFrequency ~= nil then
    self:InitTrackingFrequency( MenuParameters.TrackingFrequency )
  end

  if MenuParameters.AlertsToAll ~= nil then
    self:InitAlertsToAll( MenuParameters.AlertsToAll )
  end

  if MenuParameters.AlertsHitsOnOff ~= nil then
    self:InitAlertsHitsOnOff( MenuParameters.AlertsHitsOnOff )
  end

  if MenuParameters.AlertsLaunchesOnOff ~= nil then
    self:InitAlertsLaunchesOnOff( MenuParameters.AlertsLaunchesOnOff )
  end

  if MenuParameters.DetailsRangeOnOff ~= nil then
    self:InitRangeOnOff( MenuParameters.DetailsRangeOnOff )
  end

  if MenuParameters.DetailsBearingOnOff ~= nil then
    self:InitBearingOnOff( MenuParameters.DetailsBearingOnOff )
  end

  if MenuParameters.Distance ~= nil then
    self.Distance = MenuParameters.Distance
    MESSAGE:New( "Hit detection distance set to " .. self.Distance .. " meters", "Menu", 15, "ID" ):ToAll()
  end

end

--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @param #MISSILETRAINER self
-- @param Event#EVENTDATA Event
function MISSILETRAINER:_EventShot( Event )
  self:F( { Event } )

  local TrainerSourceDCSUnit = Event.IniDCSUnit
  local TrainerSourceDCSUnitName = Event.IniDCSUnitName
  local TrainerWeapon = Event.Weapon -- Identify the weapon fired
  local TrainerWeaponName = Event.WeaponName	-- return weapon type

  self:T( "Missile Launched = " .. TrainerWeaponName )

  local TrainerTargetDCSUnit = TrainerWeapon:getTarget() -- Identify target
  local TrainerTargetDCSUnitName = Unit.getName( TrainerTargetDCSUnit )
  local TrainerTargetSkill =  _DATABASE.Templates.Units[TrainerTargetDCSUnitName].Template.skill

  self:T(TrainerTargetDCSUnitName )

  local Client = self.DBClients[TrainerTargetDCSUnitName]
  if Client then

    local TrainerSourceUnit = UNIT:New(TrainerSourceDCSUnit)
    local TrainerTargetUnit = UNIT:New(TrainerTargetDCSUnit)

    if self.MessagesOnOff == true and self.AlertsLaunchesOnOff == true then

      local Message = MESSAGE:New(
        string.format( "%s launched a %s",
          TrainerSourceUnit:GetTypeName(),
          TrainerWeaponName
        ) .. self:_AddRange( Client, TrainerWeapon ) .. self:_AddBearing( Client, TrainerWeapon ),"Launch Alert", 5, "ID" )

      if self.AlertsToAll then
        Message:ToAll()
      else
        Message:ToClient( Client )
      end
    end

    local ClientID = Client:GetID()
    local MissileData = {}
    MissileData.TrainerSourceUnit = TrainerSourceUnit
    MissileData.TrainerWeapon = TrainerWeapon
    MissileData.TrainerTargetUnit = TrainerTargetUnit
    MissileData.TrainerWeaponTypeName = TrainerWeapon:getTypeName()
    MissileData.TrainerWeaponLaunched = true
    table.insert( self.TrackingMissiles[ClientID].MissileData, MissileData )
    --self:T( self.TrackingMissiles )
  end
end

function MISSILETRAINER:_AddRange( Client, TrainerWeapon )

  local RangeText = ""

  if self.DetailsRangeOnOff then

    local PositionMissile = TrainerWeapon:getPoint()
    local PositionTarget = Client:GetPositionVec3()

    local Range = ( ( PositionMissile.x - PositionTarget.x )^2 +
      ( PositionMissile.y - PositionTarget.y )^2 +
      ( PositionMissile.z - PositionTarget.z )^2
      ) ^ 0.5 / 1000

    RangeText = string.format( ", at %4.2fkm", Range )
  end

  return RangeText
end

function MISSILETRAINER:_AddBearing( Client, TrainerWeapon )

  local BearingText = ""

  if self.DetailsBearingOnOff then

    local PositionMissile = TrainerWeapon:getPoint()
    local PositionTarget = Client:GetPositionVec3()

    self:T2( { PositionTarget, PositionMissile })

    local DirectionVector = { x = PositionMissile.x - PositionTarget.x, y = PositionMissile.y - PositionTarget.y, z = PositionMissile.z - PositionTarget.z }
    local DirectionRadians = math.atan2( DirectionVector.z, DirectionVector.x )
    --DirectionRadians = DirectionRadians + routines.getNorthCorrection( PositionTarget )
    if DirectionRadians < 0 then
      DirectionRadians = DirectionRadians + 2 * math.pi
    end
    local DirectionDegrees = DirectionRadians * 180 / math.pi

    BearingText = string.format( ", %d degrees", DirectionDegrees )
  end

  return BearingText
end


function MISSILETRAINER:_TrackMissiles()
  self:F2()


  local ShowMessages = false
  if self.MessagesOnOff and self.MessageLastTime + self.TrackingFrequency <= timer.getTime() then
    self.MessageLastTime = timer.getTime()
    ShowMessages = true
  end

  -- ALERTS PART
  
  -- Loop for all Player Clients to check the alerts and deletion of missiles.
  for ClientDataID, ClientData in pairs( self.TrackingMissiles ) do

    local Client = ClientData.Client
    self:T2( { Client:GetName() } )

    for MissileDataID, MissileData in pairs( ClientData.MissileData ) do
      self:T3( MissileDataID )

      local TrainerSourceUnit = MissileData.TrainerSourceUnit
      local TrainerWeapon = MissileData.TrainerWeapon
      local TrainerTargetUnit = MissileData.TrainerTargetUnit
      local TrainerWeaponTypeName = MissileData.TrainerWeaponTypeName
      local TrainerWeaponLaunched = MissileData.TrainerWeaponLaunched
  
      if Client and Client:IsAlive() and TrainerSourceUnit and TrainerSourceUnit:IsAlive() and TrainerWeapon and TrainerWeapon:isExist() and TrainerTargetUnit and TrainerTargetUnit:IsAlive() then
        local PositionMissile = TrainerWeapon:getPosition().p
        local PositionTarget = Client:GetPositionVec3()
  
        local Distance = ( ( PositionMissile.x - PositionTarget.x )^2 +
          ( PositionMissile.y - PositionTarget.y )^2 +
          ( PositionMissile.z - PositionTarget.z )^2
          ) ^ 0.5 / 1000
  
        if Distance <= self.Distance then
          -- Hit alert
          TrainerWeapon:destroy()
          if self.MessagesOnOff == true and self.AlertsHitsOnOff == true then
  
            self:T( "killed" )
  
            local Message = MESSAGE:New(
              string.format( "%s launched by %s killed %s",
                TrainerWeapon:getTypeName(),
                TrainerSourceUnit:GetTypeName(),
                TrainerTargetUnit:GetPlayerName()
              ),"Hit Alert", 15, "ID" )
  
            if self.AlertsToAll == true then
              Message:ToAll()
            else
              Message:ToClient( Client )
            end
  
            MissileData = nil
            table.remove( ClientData.MissileData, MissileDataID )
            self:T(ClientData.MissileData)
          end
        end
      else
        if not ( TrainerWeapon and TrainerWeapon:isExist() ) then
          if self.MessagesOnOff == true and self.AlertsLaunchesOnOff == true then
            -- Weapon does not exist anymore. Delete from Table
            local Message = MESSAGE:New(
              string.format( "%s launched by %s self destructed!",
                TrainerWeaponTypeName,
                TrainerSourceUnit:GetTypeName()
              ),"Tracking", 5, "ID" )
  
            if self.AlertsToAll == true then
              Message:ToAll()
            else
              Message:ToClient( Client )
            end
          end
          MissileData = nil
          table.remove( ClientData.MissileData, MissileDataID )
          self:T( ClientData.MissileData )
        end
      end
    end
  end

  if ShowMessages == true and self.MessagesOnOff == true and self.TrackingOnOff == true then -- Only do this when tracking information needs to be displayed.

    -- TRACKING PART
  
    -- For the current client, the missile range and bearing details are displayed To the Player Client.
    -- For the other clients, the missile range and bearing details are displayed To the other Player Clients.
    -- To achieve this, a cross loop is done for each Player Client <-> Other Player Client missile information. 
  
    -- Main Player Client loop
    for ClientDataID, ClientData in pairs( self.TrackingMissiles ) do
  
      local Client = ClientData.Client
      self:T2( { Client:GetName() } )
  
  
      ClientData.MessageToClient = ""
      ClientData.MessageToAll = ""
  
      -- Other Players Client loop
      for TrackingDataID, TrackingData in pairs( self.TrackingMissiles ) do
  
        for MissileDataID, MissileData in pairs( TrackingData.MissileData ) do
          self:T3( MissileDataID )
  
          local TrainerSourceUnit = MissileData.TrainerSourceUnit
          local TrainerWeapon = MissileData.TrainerWeapon
          local TrainerTargetUnit = MissileData.TrainerTargetUnit
          local TrainerWeaponTypeName = MissileData.TrainerWeaponTypeName
          local TrainerWeaponLaunched = MissileData.TrainerWeaponLaunched
  
          if Client and Client:IsAlive() and TrainerSourceUnit and TrainerSourceUnit:IsAlive() and TrainerWeapon and TrainerWeapon:isExist() and TrainerTargetUnit and TrainerTargetUnit:IsAlive() then
  
            if ShowMessages == true then
              local TrackingTo
              TrackingTo = string.format( "  -> %s",
                TrainerWeaponTypeName
              )
  
              if ClientDataID == TrackingDataID then
                if ClientData.MessageToClient == "" then
                  ClientData.MessageToClient = "Missiles to You:\n"
                end
                ClientData.MessageToClient = ClientData.MessageToClient .. TrackingTo .. self:_AddRange( ClientData.Client, TrainerWeapon ) .. self:_AddBearing( ClientData.Client, TrainerWeapon ) .. "\n"
              else
                if self.TrackingToAll == true then
                  if ClientData.MessageToAll == "" then
                    ClientData.MessageToAll = "Missiles to other Players:\n"
                  end
                  ClientData.MessageToAll = ClientData.MessageToAll .. TrackingTo .. self:_AddRange( ClientData.Client, TrainerWeapon ) .. self:_AddBearing( ClientData.Client, TrainerWeapon ) .. " ( " .. TrainerTargetUnit:GetPlayerName()  ..   " )\n"
                end
              end
            end
          end
        end
      end
  
      -- Once the Player Client and the Other Player Client tracking messages are prepared, show them.
      if ClientData.MessageToClient ~= "" or ClientData.MessageToAll ~= "" then
        local Message = MESSAGE:New( ClientData.MessageToClient .. ClientData.MessageToAll, "Tracking", 1, "ID" ):ToClient( Client )
      end
    end
  end

  return true
end
