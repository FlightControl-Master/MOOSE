--- **Utilities** - Various routines.
-- @module Utilities.Routines
-- @image MOOSE.JPG
env.setErrorMessageBoxEnabled( false )

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

routines.utils.round = function( number, decimals )
  local power = 10 ^ decimals
  return math.floor( number * power ) / power
end

-- from http://lua-users.org/wiki/CopyTable
routines.utils.deepCopy = function( object )
  local lookup_table = {}
  local function _copy( object )
    if type( object ) ~= "table" then
      return object
    elseif lookup_table[object] then
      return lookup_table[object]
    end
    local new_table = {}
    lookup_table[object] = new_table
    for index, value in pairs( object ) do
      new_table[_copy( index )] = _copy( value )
    end
    return setmetatable( new_table, getmetatable( object ) )
  end
  local objectreturn = _copy( object )
  return objectreturn
end

-- porting in Slmod's serialize_slmod2
routines.utils.oneLineSerialize = function( tbl ) -- serialization of a table all on a single line, no comments, made to replace old get_table_string function

  lookup_table = {}

  local function _Serialize( tbl )

    if type( tbl ) == 'table' then -- function only works for tables!

      if lookup_table[tbl] then
        return lookup_table[object]
      end

      local tbl_str = {}

      lookup_table[tbl] = tbl_str

      tbl_str[#tbl_str + 1] = '{'

      for ind, val in pairs( tbl ) do -- serialize its fields
        local ind_str = {}
        if type( ind ) == "number" then
          ind_str[#ind_str + 1] = '['
          ind_str[#ind_str + 1] = tostring( ind )
          ind_str[#ind_str + 1] = ']='
        else -- must be a string
          ind_str[#ind_str + 1] = '['
          ind_str[#ind_str + 1] = routines.utils.basicSerialize( ind )
          ind_str[#ind_str + 1] = ']='
        end

        local val_str = {}
        if ((type( val ) == 'number') or (type( val ) == 'boolean')) then
          val_str[#val_str + 1] = tostring( val )
          val_str[#val_str + 1] = ','
          tbl_str[#tbl_str + 1] = table.concat( ind_str )
          tbl_str[#tbl_str + 1] = table.concat( val_str )
        elseif type( val ) == 'string' then
          val_str[#val_str + 1] = routines.utils.basicSerialize( val )
          val_str[#val_str + 1] = ','
          tbl_str[#tbl_str + 1] = table.concat( ind_str )
          tbl_str[#tbl_str + 1] = table.concat( val_str )
        elseif type( val ) == 'nil' then -- won't ever happen, right?
          val_str[#val_str + 1] = 'nil,'
          tbl_str[#tbl_str + 1] = table.concat( ind_str )
          tbl_str[#tbl_str + 1] = table.concat( val_str )
        elseif type( val ) == 'table' then
          if ind == "__index" then
            --	tbl_str[#tbl_str + 1] = "__index"
            --	tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
          else

            val_str[#val_str + 1] = _Serialize( val )
            val_str[#val_str + 1] = ',' -- I think this is right, I just added it
            tbl_str[#tbl_str + 1] = table.concat( ind_str )
            tbl_str[#tbl_str + 1] = table.concat( val_str )
          end
        elseif type( val ) == 'function' then
          --	tbl_str[#tbl_str + 1] = "function " .. tostring(ind)
          --	tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
        else
          --					env.info('unable to serialize value type ' .. routines.utils.basicSerialize(type(val)) .. ' at index ' .. tostring(ind))
          --					env.info( debug.traceback() )
        end

      end
      tbl_str[#tbl_str + 1] = '}'
      return table.concat( tbl_str )
    else
      if type( tbl ) == 'string' then
        return tbl
      else
        return tostring( tbl )
      end
    end
  end

  local objectreturn = _Serialize( tbl )
  return objectreturn
end

-- porting in Slmod's "safestring" basic serialize
routines.utils.basicSerialize = function( s )
  if s == nil then
    return "\"\""
  else
    if ((type( s ) == 'number') or (type( s ) == 'boolean') or (type( s ) == 'function') or (type( s ) == 'table') or (type( s ) == 'userdata')) then
      return tostring( s )
    elseif type( s ) == 'string' then
      s = string.format( '%s', s:gsub( "%%", "%%%%" ) )
      return s
    end
  end
end

routines.utils.toDegree = function( angle )
  return angle * 180 / math.pi
end

routines.utils.toRadian = function( angle )
  return angle * math.pi / 180
end

routines.utils.metersToNM = function( meters )
  return meters / 1852
end

routines.utils.metersToFeet = function( meters )
  return meters / 0.3048
end

routines.utils.NMToMeters = function( NM )
  return NM * 1852
end

routines.utils.feetToMeters = function( feet )
  return feet * 0.3048
end

routines.utils.mpsToKnots = function( mps )
  return mps * 3600 / 1852
end

routines.utils.mpsToKmph = function( mps )
  return mps * 3.6
end

routines.utils.knotsToMps = function( knots )
  return knots * 1852 / 3600
end

routines.utils.kmphToMps = function( kmph )
  return kmph / 3.6
end

function routines.utils.makeVec2( Vec3 )
  if Vec3.z then
    return { x = Vec3.x, y = Vec3.z }
  else
    return { x = Vec3.x, y = Vec3.y } -- it was actually already vec2.
  end
end

function routines.utils.makeVec3( Vec2, y )
  if not Vec2.z then
    if not y then
      y = 0
    end
    return { x = Vec2.x, y = y, z = Vec2.y }
  else
    return { x = Vec2.x, y = Vec2.y, z = Vec2.z } -- it was already Vec3, actually.
  end
end

function routines.utils.makeVec3GL( Vec2, offset )
  local adj = offset or 0

  if not Vec2.z then
    return { x = Vec2.x, y = (land.getHeight( Vec2 ) + adj), z = Vec2.y }
  else
    return { x = Vec2.x, y = (land.getHeight( { x = Vec2.x, y = Vec2.z } ) + adj), z = Vec2.z }
  end
end

routines.utils.zoneToVec3 = function( zone )
  local new = {}
  if type( zone ) == 'table' and zone.point then
    new.x = zone.point.x
    new.y = zone.point.y
    new.z = zone.point.z
    return new
  elseif type( zone ) == 'string' then
    zone = trigger.misc.getZone( zone )
    if zone then
      new.x = zone.point.x
      new.y = zone.point.y
      new.z = zone.point.z
      return new
    end
  end
end

-- gets heading-error corrected direction from point along vector vec.
function routines.utils.getDir( vec, point )
  local dir = math.atan2( vec.z, vec.x )
  dir = dir + routines.getNorthCorrection( point )
  if dir < 0 then
    dir = dir + 2 * math.pi -- put dir in range of 0 to 2*pi
  end
  return dir
end

-- gets distance in meters between two points (2 dimensional)
function routines.utils.get2DDist( point1, point2 )
  point1 = routines.utils.makeVec3( point1 )
  point2 = routines.utils.makeVec3( point2 )
  return routines.vec.mag( { x = point1.x - point2.x, y = 0, z = point1.z - point2.z } )
end

-- gets distance in meters between two points (3 dimensional)
function routines.utils.get3DDist( point1, point2 )
  return routines.vec.mag( { x = point1.x - point2.x, y = point1.y - point2.y, z = point1.z - point2.z } )
end

-- 3D Vector manipulation
routines.vec = {}

routines.vec.add = function( vec1, vec2 )
  return { x = vec1.x + vec2.x, y = vec1.y + vec2.y, z = vec1.z + vec2.z }
end

routines.vec.sub = function( vec1, vec2 )
  return { x = vec1.x - vec2.x, y = vec1.y - vec2.y, z = vec1.z - vec2.z }
end

routines.vec.scalarMult = function( vec, mult )
  return { x = vec.x * mult, y = vec.y * mult, z = vec.z * mult }
end

routines.vec.scalar_mult = routines.vec.scalarMult

routines.vec.dp = function( vec1, vec2 )
  return vec1.x * vec2.x + vec1.y * vec2.y + vec1.z * vec2.z
end

routines.vec.cp = function( vec1, vec2 )
  return { x = vec1.y * vec2.z - vec1.z * vec2.y, y = vec1.z * vec2.x - vec1.x * vec2.z, z = vec1.x * vec2.y - vec1.y * vec2.x }
end

routines.vec.mag = function( vec )
  return (vec.x ^ 2 + vec.y ^ 2 + vec.z ^ 2) ^ 0.5
end

routines.vec.getUnitVec = function( vec )
  local mag = routines.vec.mag( vec )
  return { x = vec.x / mag, y = vec.y / mag, z = vec.z / mag }
end

routines.vec.rotateVec2 = function( vec2, theta )
  return { x = vec2.x * math.cos( theta ) - vec2.y * math.sin( theta ), y = vec2.x * math.sin( theta ) + vec2.y * math.cos( theta ) }
end
---------------------------------------------------------------------------------------------------------------------------

-- acc- the accuracy of each easting/northing.  0, 1, 2, 3, 4, or 5.
routines.tostringMGRS = function( MGRS, acc )
  if acc == 0 then
    return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph
  else
    return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph .. ' ' .. string.format( '%0' .. acc .. 'd', routines.utils.round( MGRS.Easting / (10 ^ (5 - acc)), 0 ) ) .. ' ' .. string.format( '%0' .. acc .. 'd', routines.utils.round( MGRS.Northing / (10 ^ (5 - acc)), 0 ) )
  end
end

--[[acc:
in DM: decimal point of minutes.
In DMS: decimal point of seconds.
position after the decimal of the least significant digit:
So:
42.32 - acc of 2.
]]
routines.tostringLL = function( lat, lon, acc, DMS )

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

  lat = math.abs( lat )
  lon = math.abs( lon )

  local latDeg = math.floor( lat )
  local latMin = (lat - latDeg) * 60

  local lonDeg = math.floor( lon )
  local lonMin = (lon - lonDeg) * 60

  if DMS then -- degrees, minutes, and seconds.
    local oldLatMin = latMin
    latMin = math.floor( latMin )
    local latSec = routines.utils.round( (oldLatMin - latMin) * 60, acc )

    local oldLonMin = lonMin
    lonMin = math.floor( lonMin )
    local lonSec = routines.utils.round( (oldLonMin - lonMin) * 60, acc )

    if latSec == 60 then
      latSec = 0
      latMin = latMin + 1
    end

    if lonSec == 60 then
      lonSec = 0
      lonMin = lonMin + 1
    end

    local secFrmtStr -- create the formatting string for the seconds place
    if acc <= 0 then -- no decimal place.
      secFrmtStr = '%02d'
    else
      local width = 3 + acc -- 01.310 - that's a width of 6, for example.
      secFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
    end

    return string.format( '%02d', latDeg ) .. ' ' .. string.format( '%02d', latMin ) .. '\' ' .. string.format( secFrmtStr, latSec ) .. '"' .. latHemi .. '   ' .. string.format( '%02d', lonDeg ) .. ' ' .. string.format( '%02d', lonMin ) .. '\' ' .. string.format( secFrmtStr, lonSec ) .. '"' .. lonHemi

  else -- degrees, decimal minutes.
    latMin = routines.utils.round( latMin, acc )
    lonMin = routines.utils.round( lonMin, acc )

    if latMin == 60 then
      latMin = 0
      latDeg = latDeg + 1
    end

    if lonMin == 60 then
      lonMin = 0
      lonDeg = lonDeg + 1
    end

    local minFrmtStr -- create the formatting string for the minutes place
    if acc <= 0 then -- no decimal place.
      minFrmtStr = '%02d'
    else
      local width = 3 + acc -- 01.310 - that's a width of 6, for example.
      minFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
    end

    return string.format( '%02d', latDeg ) .. ' ' .. string.format( minFrmtStr, latMin ) .. '\'' .. latHemi .. '   ' .. string.format( '%02d', lonDeg ) .. ' ' .. string.format( minFrmtStr, lonMin ) .. '\'' .. lonHemi

  end
end

--[[ required: az - radian
     required: dist - meters
	 optional: alt - meters (set to false or nil if you don't want to use it).
	 optional: metric - set true to get dist and alt in km and m.
	 precision will always be nearest degree and NM or km.]]
routines.tostringBR = function( az, dist, alt, metric )
  az = routines.utils.round( routines.utils.toDegree( az ), 0 )

  if metric then
    dist = routines.utils.round( dist / 1000, 2 )
  else
    dist = routines.utils.round( routines.utils.metersToNM( dist ), 2 )
  end

  local s = string.format( '%03d', az ) .. ' for ' .. dist

  if alt then
    if metric then
      s = s .. ' at ' .. routines.utils.round( alt, 0 )
    else
      s = s .. ' at ' .. routines.utils.round( routines.utils.metersToFeet( alt ), 0 )
    end
  end
  return s
end

routines.getNorthCorrection = function( point ) -- gets the correction needed for true north
  if not point.z then -- Vec2; convert to Vec3
    point.z = point.y
    point.y = 0
  end
  local lat, lon = coord.LOtoLL( point )
  local north_posit = coord.LLtoLO( lat + 1, lon )
  return math.atan2( north_posit.z - point.z, north_posit.x - point.x )
end

do
  local idNum = 0

  -- Simplified event handler
  routines.addEventHandler = function( f ) -- id is optional!
    local handler = {}
    idNum = idNum + 1
    handler.id = idNum
    handler.f = f
    handler.onEvent = function( self, event )
      self.f( event )
    end
    world.addEventHandler( handler )
  end

  routines.removeEventHandler = function( id )
    for key, handler in pairs( world.eventHandlers ) do
      if handler.id and handler.id == id then
        world.eventHandlers[key] = nil
        return true
      end
    end
    return false
  end
end

-- need to return a Vec3 or Vec2?
function routines.getRandPointInCircle( point, radius, innerRadius )
  local theta = 2 * math.pi * math.random()
  local rad = math.random() + math.random()
  if rad > 1 then
    rad = 2 - rad
  end

  local radMult
  if innerRadius and innerRadius <= radius then
    radMult = (radius - innerRadius) * rad + innerRadius
  else
    radMult = radius * rad
  end

  if not point.z then -- might as well work with vec2/3
    point.z = point.y
  end

  local rndCoord
  if radius > 0 then
    rndCoord = { x = math.cos( theta ) * radMult + point.x, y = math.sin( theta ) * radMult + point.z }
  else
    rndCoord = { x = point.x, y = point.z }
  end
  return rndCoord
end

routines.goRoute = function( group, path )
  local misTask = { id = 'Mission', params = { route = { points = routines.utils.deepCopy( path ) } } }
  if type( group ) == 'string' then
    group = Group.getByName( group )
  end
  local groupCon = group:getController()
  if groupCon then
    groupCon:setTask( misTask )
    return true
  end

  Controller.setTask( groupCon, misTask )
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
	fakeZone.point = {x = pos.x, y = pos.y, z = pos.z}
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
routines.getMGRSString = function( vars )
  local units = vars.units
  local acc = vars.acc or 5
  local avgPos = routines.getAvgPos( units )
  if avgPos then
    return routines.tostringMGRS( coord.LLtoMGRS( coord.LOtoLL( avgPos ) ), acc )
  end
end

--[[ vars for routines.getLLString
vars.units - table of unit names (NOT unitNameTable- maybe this should change).
vars.acc - integer, number of numbers after decimal place
vars.DMS - if true, output in degrees, minutes, seconds.  Otherwise, output in degrees, minutes.


]]
routines.getLLString = function( vars )
  local units = vars.units
  local acc = vars.acc or 3
  local DMS = vars.DMS
  local avgPos = routines.getAvgPos( units )
  if avgPos then
    local lat, lon = coord.LOtoLL( avgPos )
    return routines.tostringLL( lat, lon, acc, DMS )
  end
end

--[[
vars.zone - table of a zone name.
vars.ref -  vec3 ref point, maybe overload for vec2 as well?
vars.alt - boolean, if used, includes altitude in string
vars.metric - boolean, gives distance in km instead of NM.
]]
routines.getBRStringZone = function( vars )
  local zone = trigger.misc.getZone( vars.zone )
  local ref = routines.utils.makeVec3( vars.ref, 0 ) -- turn it into Vec3 if it is not already.
  local alt = vars.alt
  local metric = vars.metric
  if zone then
    local vec = { x = zone.point.x - ref.x, y = zone.point.y - ref.y, z = zone.point.z - ref.z }
    local dir = routines.utils.getDir( vec, ref )
    local dist = routines.utils.get2DDist( zone.point, ref )
    if alt then
      alt = zone.y
    end
    return routines.tostringBR( dir, dist, alt, metric )
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
routines.getBRString = function( vars )
  local units = vars.units
  local ref = routines.utils.makeVec3( vars.ref, 0 ) -- turn it into Vec3 if it is not already.
  local alt = vars.alt
  local metric = vars.metric
  local avgPos = routines.getAvgPos( units )
  if avgPos then
    local vec = { x = avgPos.x - ref.x, y = avgPos.y - ref.y, z = avgPos.z - ref.z }
    local dir = routines.utils.getDir( vec, ref )
    local dist = routines.utils.get2DDist( avgPos, ref )
    if alt then
      alt = avgPos.y
    end
    return routines.tostringBR( dir, dist, alt, metric )
  end
end

-- Returns the Vec3 coordinates of the average position of the concentration of units most in the heading direction.
--[[ vars for routines.getLeadingPos:
vars.units - table of unit names
vars.heading - direction
vars.radius - number
vars.headingDegrees - boolean, switches heading to degrees
]]
routines.getLeadingPos = function( vars )
  local units = vars.units
  local heading = vars.heading
  local radius = vars.radius
  if vars.headingDegrees then
    heading = routines.utils.toRadian( vars.headingDegrees )
  end

  local unitPosTbl = {}
  for i = 1, #units do
    local unit = Unit.getByName( units[i] )
    if unit and unit:isExist() then
      unitPosTbl[#unitPosTbl + 1] = unit:getPosition().p
    end
  end
  if #unitPosTbl > 0 then -- one more more units found.
    -- first, find the unit most in the heading direction
    local maxPos = -math.huge

    local maxPosInd -- maxPos - the furthest in direction defined by heading; maxPosInd =
    for i = 1, #unitPosTbl do
      local rotatedVec2 = routines.vec.rotateVec2( routines.utils.makeVec2( unitPosTbl[i] ), heading )
      if (not maxPos) or maxPos < rotatedVec2.x then
        maxPos = rotatedVec2.x
        maxPosInd = i
      end
    end

    -- now, get all the units around this unit...
    local avgPos
    if radius then
      local maxUnitPos = unitPosTbl[maxPosInd]
      local avgx, avgy, avgz, totNum = 0, 0, 0, 0
      for i = 1, #unitPosTbl do
        if routines.utils.get2DDist( maxUnitPos, unitPosTbl[i] ) <= radius then
          avgx = avgx + unitPosTbl[i].x
          avgy = avgy + unitPosTbl[i].y
          avgz = avgz + unitPosTbl[i].z
          totNum = totNum + 1
        end
      end
      avgPos = { x = avgx / totNum, y = avgy / totNum, z = avgz / totNum }
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
routines.getLeadingMGRSString = function( vars )
  local pos = routines.getLeadingPos( vars )
  if pos then
    local acc = vars.acc or 5
    return routines.tostringMGRS( coord.LLtoMGRS( coord.LOtoLL( pos ) ), acc )
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
routines.getLeadingLLString = function( vars )
  local pos = routines.getLeadingPos( vars )
  if pos then
    local acc = vars.acc or 3
    local DMS = vars.DMS
    local lat, lon = coord.LOtoLL( pos )
    return routines.tostringLL( lat, lon, acc, DMS )
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
routines.getLeadingBRString = function( vars )
  local pos = routines.getLeadingPos( vars )
  if pos then
    local ref = vars.ref
    local alt = vars.alt
    local metric = vars.metric

    local vec = { x = pos.x - ref.x, y = pos.y - ref.y, z = pos.z - ref.z }
    local dir = routines.utils.getDir( vec, ref )
    local dist = routines.utils.get2DDist( pos, ref )
    if alt then
      alt = pos.y
    end
    return routines.tostringBR( dir, dist, alt, metric )
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
routines.msgMGRS = function( vars )
  local units = vars.units
  local acc = vars.acc
  local text = vars.text
  local displayTime = vars.displayTime
  local msgFor = vars.msgFor

  local s = routines.getMGRSString { units = units, acc = acc }
  local newText
  if string.find( text, '%%s' ) then -- look for %s
    newText = string.format( text, s ) -- insert the coordinates into the message
  else -- else, just append to the end.
    newText = text .. s
  end

  routines.message.add { text = newText, displayTime = displayTime, msgFor = msgFor }
end

--[[ vars for routines.msgLL
vars.units - table of unit names (NOT unitNameTable- maybe this should change) (Yes).
vars.acc - integer, number of numbers after decimal place
vars.DMS - if true, output in degrees, minutes, seconds.  Otherwise, output in degrees, minutes.
vars.text - text in the message
vars.displayTime - self explanatory
vars.msgFor - scope
]]
routines.msgLL = function( vars )
  local units = vars.units -- technically, I don't really need to do this, but it helps readability.
  local acc = vars.acc
  local DMS = vars.DMS
  local text = vars.text
  local displayTime = vars.displayTime
  local msgFor = vars.msgFor

  local s = routines.getLLString { units = units, acc = acc, DMS = DMS }
  local newText
  if string.find( text, '%%s' ) then -- look for %s
    newText = string.format( text, s ) -- insert the coordinates into the message
  else -- else, just append to the end.
    newText = text .. s
  end

  routines.message.add { text = newText, displayTime = displayTime, msgFor = msgFor }

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
routines.msgBR = function( vars )
  local units = vars.units -- technically, I don't really need to do this, but it helps readability.
  local ref = vars.ref -- vec2/vec3 will be handled in routines.getBRString
  local alt = vars.alt
  local metric = vars.metric
  local text = vars.text
  local displayTime = vars.displayTime
  local msgFor = vars.msgFor

  local s = routines.getBRString { units = units, ref = ref, alt = alt, metric = metric }
  local newText
  if string.find( text, '%%s' ) then -- look for %s
    newText = string.format( text, s ) -- insert the coordinates into the message
  else -- else, just append to the end.
    newText = text .. s
  end

  routines.message.add { text = newText, displayTime = displayTime, msgFor = msgFor }

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
routines.msgBullseye = function( vars )
  if string.lower( vars.ref ) == 'red' then
    vars.ref = routines.DBs.missionData.bullseye.red
    routines.msgBR( vars )
  elseif string.lower( vars.ref ) == 'blue' then
    vars.ref = routines.DBs.missionData.bullseye.blue
    routines.msgBR( vars )
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

routines.msgBRA = function( vars )
  if Unit.getByName( vars.ref ) then
    vars.ref = Unit.getByName( vars.ref ):getPosition().p
    if not vars.alt then
      vars.alt = true
    end
    routines.msgBR( vars )
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
routines.msgLeadingMGRS = function( vars )
  local units = vars.units -- technically, I don't really need to do this, but it helps readability.
  local heading = vars.heading
  local radius = vars.radius
  local headingDegrees = vars.headingDegrees
  local acc = vars.acc
  local text = vars.text
  local displayTime = vars.displayTime
  local msgFor = vars.msgFor

  local s = routines.getLeadingMGRSString { units = units, heading = heading, radius = radius, headingDegrees = headingDegrees, acc = acc }
  local newText
  if string.find( text, '%%s' ) then -- look for %s
    newText = string.format( text, s ) -- insert the coordinates into the message
  else -- else, just append to the end.
    newText = text .. s
  end

  routines.message.add { text = newText, displayTime = displayTime, msgFor = msgFor }
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
routines.msgLeadingLL = function( vars )
  local units = vars.units -- technically, I don't really need to do this, but it helps readability.
  local heading = vars.heading
  local radius = vars.radius
  local headingDegrees = vars.headingDegrees
  local acc = vars.acc
  local DMS = vars.DMS
  local text = vars.text
  local displayTime = vars.displayTime
  local msgFor = vars.msgFor

  local s = routines.getLeadingLLString { units = units, heading = heading, radius = radius, headingDegrees = headingDegrees, acc = acc, DMS = DMS }
  local newText
  if string.find( text, '%%s' ) then -- look for %s
    newText = string.format( text, s ) -- insert the coordinates into the message
  else -- else, just append to the end.
    newText = text .. s
  end

  routines.message.add { text = newText, displayTime = displayTime, msgFor = msgFor }
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
routines.msgLeadingBR = function( vars )
  local units = vars.units -- technically, I don't really need to do this, but it helps readability.
  local heading = vars.heading
  local radius = vars.radius
  local headingDegrees = vars.headingDegrees
  local metric = vars.metric
  local alt = vars.alt
  local ref = vars.ref -- vec2/vec3 will be handled in routines.getBRString
  local text = vars.text
  local displayTime = vars.displayTime
  local msgFor = vars.msgFor

  local s = routines.getLeadingBRString { units = units, heading = heading, radius = radius, headingDegrees = headingDegrees, metric = metric, alt = alt, ref = ref }
  local newText
  if string.find( text, '%%s' ) then -- look for %s
    newText = string.format( text, s ) -- insert the coordinates into the message
  else -- else, just append to the end.
    newText = text .. s
  end

  routines.message.add { text = newText, displayTime = displayTime, msgFor = msgFor }
end

function spairs( t, order )
  -- collect the keys
  local keys = {}
  for k in pairs( t ) do
    keys[#keys + 1] = k
  end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
    table.sort( keys, function( a, b )
      return order( t, a, b )
    end )
  else
    table.sort( keys )
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
  -- trace.f()

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

  -- trace.r( "", "", { CurrentZoneID } )
  return CurrentZoneID
end

function routines.IsUnitInZones( TransportUnit, LandingZones )
  -- trace.f("", "routines.IsUnitInZones" )

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
          TransportZonePos = { radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z }
          if (((TransportUnitPos.x - TransportZonePos.x) ^ 2 + (TransportUnitPos.z - TransportZonePos.z) ^ 2) ^ 0.5 <= TransportZonePos.radius) then
            TransportZoneResult = LandingZoneID
            break
          end
        end
      end
    else
      TransportZone = trigger.misc.getZone( LandingZones )
      TransportZonePos = { radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z }
      if (((TransportUnitPos.x - TransportZonePos.x) ^ 2 + (TransportUnitPos.z - TransportZonePos.z) ^ 2) ^ 0.5 <= TransportZonePos.radius) then
        TransportZoneResult = 1
      end
    end
    if TransportZoneResult then
      -- trace.i( "routines", "TransportZone:" .. TransportZoneResult )
    else
      -- trace.i( "routines", "TransportZone:nil logic" )
    end
    return TransportZoneResult
  else
    -- trace.i( "routines", "TransportZone:nil hard" )
    return nil
  end
end

function routines.IsUnitNearZonesRadius( TransportUnit, LandingZones, ZoneRadius )
  -- trace.f("", "routines.IsUnitInZones" )

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
          TransportZonePos = { radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z }
          if (((TransportUnitPos.x - TransportZonePos.x) ^ 2 + (TransportUnitPos.z - TransportZonePos.z) ^ 2) ^ 0.5 <= ZoneRadius) then
            TransportZoneResult = LandingZoneID
            break
          end
        end
      end
    else
      TransportZone = trigger.misc.getZone( LandingZones )
      TransportZonePos = { radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z }
      if (((TransportUnitPos.x - TransportZonePos.x) ^ 2 + (TransportUnitPos.z - TransportZonePos.z) ^ 2) ^ 0.5 <= ZoneRadius) then
        TransportZoneResult = 1
      end
    end
    if TransportZoneResult then
      -- trace.i( "routines", "TransportZone:" .. TransportZoneResult )
    else
      -- trace.i( "routines", "TransportZone:nil logic" )
    end
    return TransportZoneResult
  else
    -- trace.i( "routines", "TransportZone:nil hard" )
    return nil
  end
end

function routines.IsStaticInZones( TransportStatic, LandingZones )
  -- trace.f()

  local TransportZoneResult = nil
  local TransportZonePos = nil
  local TransportZone = nil

  -- fill-up some local variables to support further calculations to determine location of units within the zone.
  local TransportStaticPos = TransportStatic:getPosition().p
  if type( LandingZones ) == "table" then
    for LandingZoneID, LandingZoneName in pairs( LandingZones ) do
      TransportZone = trigger.misc.getZone( LandingZoneName )
      if TransportZone then
        TransportZonePos = { radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z }
        if (((TransportStaticPos.x - TransportZonePos.x) ^ 2 + (TransportStaticPos.z - TransportZonePos.z) ^ 2) ^ 0.5 <= TransportZonePos.radius) then
          TransportZoneResult = LandingZoneID
          break
        end
      end
    end
  else
    TransportZone = trigger.misc.getZone( LandingZones )
    TransportZonePos = { radius = TransportZone.radius, x = TransportZone.point.x, y = TransportZone.point.y, z = TransportZone.point.z }
    if (((TransportStaticPos.x - TransportZonePos.x) ^ 2 + (TransportStaticPos.z - TransportZonePos.z) ^ 2) ^ 0.5 <= TransportZonePos.radius) then
      TransportZoneResult = 1
    end
  end

  -- trace.r( "", "", { TransportZoneResult } )
  return TransportZoneResult
end

function routines.IsUnitInRadius( CargoUnit, ReferencePosition, Radius )
  -- trace.f()

  local Valid = true

  -- fill-up some local variables to support further calculations to determine location of units within the zone.
  local CargoPos = CargoUnit:getPosition().p
  local ReferenceP = ReferencePosition.p

  if (((CargoPos.x - ReferenceP.x) ^ 2 + (CargoPos.z - ReferenceP.z) ^ 2) ^ 0.5 <= Radius) then
  else
    Valid = false
  end

  return Valid
end

function routines.IsPartOfGroupInRadius( CargoGroup, ReferencePosition, Radius )
  -- trace.f()

  local Valid = true

  Valid = routines.ValidateGroup( CargoGroup, "CargoGroup", Valid )

  -- fill-up some local variables to support further calculations to determine location of units within the zone
  local CargoUnits = CargoGroup:getUnits()
  for CargoUnitId, CargoUnit in pairs( CargoUnits ) do
    local CargoUnitPos = CargoUnit:getPosition().p
    --    env.info( 'routines.IsPartOfGroupInRadius: CargoUnitPos.x = ' .. CargoUnitPos.x .. ' CargoUnitPos.z = ' .. CargoUnitPos.z )
    local ReferenceP = ReferencePosition.p
    --    env.info( 'routines.IsPartOfGroupInRadius: ReferenceGroupPos.x = ' .. ReferenceGroupPos.x .. ' ReferenceGroupPos.z = ' .. ReferenceGroupPos.z )

    if (((CargoUnitPos.x - ReferenceP.x) ^ 2 + (CargoUnitPos.z - ReferenceP.z) ^ 2) ^ 0.5 <= Radius) then
    else
      Valid = false
      break
    end
  end

  return Valid
end

function routines.ValidateString( Variable, VariableName, Valid )
  -- trace.f()

  if type( Variable ) == "string" then
    if Variable == "" then
      error( "routines.ValidateString: error: " .. VariableName .. " must be filled out!" )
      Valid = false
    end
  else
    error( "routines.ValidateString: error: " .. VariableName .. " is not a string." )
    Valid = false
  end

  -- trace.r( "", "", { Valid } )
  return Valid
end

function routines.ValidateNumber( Variable, VariableName, Valid )
  -- trace.f()

  if type( Variable ) == "number" then
  else
    error( "routines.ValidateNumber: error: " .. VariableName .. " is not a number." )
    Valid = false
  end

  -- trace.r( "", "", { Valid } )
  return Valid
end

function routines.ValidateGroup( Variable, VariableName, Valid )
  -- trace.f()

  if Variable == nil then
    error( "routines.ValidateGroup: error: " .. VariableName .. " is a nil value!" )
    Valid = false
  end

  -- trace.r( "", "", { Valid } )
  return Valid
end

function routines.ValidateZone( LandingZones, VariableName, Valid )
  -- trace.f()

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

  -- trace.r( "", "", { Valid } )
  return Valid
end

function routines.ValidateEnumeration( Variable, VariableName, Enum, Valid )
  -- trace.f()

  local ValidVariable = false

  for EnumId, EnumData in pairs( Enum ) do
    if Variable == EnumData then
      ValidVariable = true
      break
    end
  end

  if ValidVariable then
  else
    error( 'TransportValidateEnum: " .. VariableName .. " is not a valid type.' .. Variable )
    Valid = false
  end

  -- trace.r( "", "", { Valid } )
  return Valid
end

function routines.getGroupRoute( groupIdent, task ) -- same as getGroupPoints but returns speed and formation type along with vec2 of point}
  -- refactor to search by groupId and allow groupId and groupName as inputs
  local gpId = groupIdent
  if type( groupIdent ) == 'string' and not tonumber( groupIdent ) then
    gpId = _DATABASE.Templates.Groups[groupIdent].groupId
  end

  for coa_name, coa_data in pairs( env.mission.coalition ) do
    if (coa_name == 'red' or coa_name == 'blue') and type( coa_data ) == 'table' then
      if coa_data.country then -- there is a country table
        for cntry_id, cntry_data in pairs( coa_data.country ) do
          for obj_type_name, obj_type_data in pairs( cntry_data ) do
            if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" then -- only these types have points						
              if ((type( obj_type_data ) == 'table') and obj_type_data.group and (type( obj_type_data.group ) == 'table') and (#obj_type_data.group > 0)) then -- there's a group!				
                for group_num, group_data in pairs( obj_type_data.group ) do
                  if group_data and group_data.groupId == gpId then -- this is the group we are looking for
                    if group_data.route and group_data.route.points and #group_data.route.points > 0 then
                      local points = {}

                      for point_num, point in pairs( group_data.route.points ) do
                        local routeData = {}
                        if env.mission.version > 7 then
                          routeData.name = env.getValueDictByKey( point.name )
                        else
                          routeData.name = point.name
                        end
                        if not point.point then
                          routeData.x = point.x
                          routeData.y = point.y
                        else
                          routeData.point = point.point -- it's possible that the ME could move to the point = Vec2 notation.
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
                  end -- if group_data and group_data.name and group_data.name == 'groupname'
                end -- for group_num, group_data in pairs(obj_type_data.group) do		
              end -- if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then	
            end -- if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then
          end -- for obj_type_name, obj_type_data in pairs(cntry_data) do
        end -- for cntry_id, cntry_data in pairs(coa_data.country) do
      end -- if coa_data.country then --there is a country table
    end -- if coa_name == 'red' or coa_name == 'blue' and type(coa_data) == 'table' then	
  end -- for coa_name, coa_data in pairs(mission.coalition) do
end

routines.ground.patrolRoute = function( vars )

  local tempRoute = {}
  local useRoute = {}
  local gpData = vars.gpData
  if type( gpData ) == 'string' then
    gpData = Group.getByName( gpData )
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
      tempRoute = routines.getGroupRoute( useGroupRoute )
    end
  else
    useRoute = vars.route
    local posStart = routines.getLeadPos( gpData )
    useRoute[1] = routines.ground.buildWP( posStart, useRoute[1].action, useRoute[1].speed )
    routeProvided = true
  end

  local overRideSpeed = vars.speed or 'default'
  local pType = vars.pType
  local offRoadForm = vars.offRoadForm or 'default'
  local onRoadForm = vars.onRoadForm or 'default'

  if routeProvided == false and #tempRoute > 0 then
    local posStart = routines.getLeadPos( gpData )

    useRoute[#useRoute + 1] = routines.ground.buildWP( posStart, offRoadForm, overRideSpeed )
    for i = 1, #tempRoute do
      local tempForm = tempRoute[i].action
      local tempSpeed = tempRoute[i].speed

      if offRoadForm == 'default' then
        tempForm = tempRoute[i].action
      end
      if onRoadForm == 'default' then
        onRoadForm = 'On Road'
      end
      if (string.lower( tempRoute[i].action ) == 'on road' or string.lower( tempRoute[i].action ) == 'onroad' or string.lower( tempRoute[i].action ) == 'on_road') then
        tempForm = onRoadForm
      else
        tempForm = offRoadForm
      end

      if type( overRideSpeed ) == 'number' then
        tempSpeed = overRideSpeed
      end

      useRoute[#useRoute + 1] = routines.ground.buildWP( tempRoute[i], tempForm, tempSpeed )
    end

    if pType and string.lower( pType ) == 'doubleback' then
      local curRoute = routines.utils.deepCopy( useRoute )
      for i = #curRoute, 2, -1 do
        useRoute[#useRoute + 1] = routines.ground.buildWP( curRoute[i], curRoute[i].action, curRoute[i].speed )
      end
    end

    useRoute[1].action = useRoute[#useRoute].action -- make it so the first WP matches the last WP
  end

  local cTask3 = {}
  local newPatrol = {}
  newPatrol.route = useRoute
  newPatrol.gpData = gpData:getName()
  cTask3[#cTask3 + 1] = 'routines.ground.patrolRoute('
  cTask3[#cTask3 + 1] = routines.utils.oneLineSerialize( newPatrol )
  cTask3[#cTask3 + 1] = ')'
  cTask3 = table.concat( cTask3 )
  local tempTask = { id = 'WrappedAction', params = { action = { id = 'Script', params = { command = cTask3 } } } }

  useRoute[#useRoute].task = tempTask
  routines.goRoute( gpData, useRoute )
end

routines.ground.patrol = function( gpData, pType, form, speed )
  local vars = {}

  if type( gpData ) == 'table' and gpData:getName() then
    gpData = gpData:getName()
  end

  vars.useGroupRoute = gpData
  vars.gpData = gpData
  vars.pType = pType
  vars.offRoadForm = form
  vars.speed = speed

  routines.ground.patrolRoute( vars )
end

function routines.GetUnitHeight( CheckUnit )
  -- trace.f( "routines" )

  local UnitPoint = CheckUnit:getPoint()
  local UnitPosition = { x = UnitPoint.x, y = UnitPoint.z }
  local UnitHeight = UnitPoint.y

  local LandHeight = land.getHeight( UnitPosition )

  -- env.info(( 'CarrierHeight: LandHeight = ' .. LandHeight .. ' CarrierHeight = ' .. CarrierHeight ))

  -- trace.f( "routines", "Unit Height = " .. UnitHeight - LandHeight )

  return UnitHeight - LandHeight
end

Su34Status = { status = {} }
boardMsgRed = { statusMsg = "" }
boardMsgAll = { timeMsg = "" }
SpawnSettings = {}
Su34MenuPath = {}
Su34Menus = 0

function Su34AttackCarlVinson( groupName )
  -- trace.menu("", "Su34AttackCarlVinson")
  local groupSu34 = Group.getByName( groupName )
  local controllerSu34 = groupSu34.getController( groupSu34 )
  local groupCarlVinson = Group.getByName( "US Carl Vinson #001" )
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE )
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
  if groupCarlVinson ~= nil then
    controllerSu34.pushTask( controllerSu34, { id = 'AttackGroup', params = { groupId = groupCarlVinson:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = true } } )
  end
  Su34Status.status[groupName] = 1
  MessageToRed( string.format( '%s: ', groupName ) .. 'Attacking carrier Carl Vinson. ', 10, 'RedStatus' .. groupName )
end

function Su34AttackWest( groupName )
  -- trace.f("","Su34AttackWest")
  local groupSu34 = Group.getByName( groupName )
  local controllerSu34 = groupSu34.getController( groupSu34 )
  local groupShipWest1 = Group.getByName( "US Ship West #001" )
  local groupShipWest2 = Group.getByName( "US Ship West #002" )
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE )
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
  if groupShipWest1 ~= nil then
    controllerSu34.pushTask( controllerSu34, { id = 'AttackGroup', params = { groupId = groupShipWest1:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = true } } )
  end
  if groupShipWest2 ~= nil then
    controllerSu34.pushTask( controllerSu34, { id = 'AttackGroup', params = { groupId = groupShipWest2:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = true } } )
  end
  Su34Status.status[groupName] = 2
  MessageToRed( string.format( '%s: ', groupName ) .. 'Attacking invading ships in the west. ', 10, 'RedStatus' .. groupName )
end

function Su34AttackNorth( groupName )
  -- trace.menu("","Su34AttackNorth")
  local groupSu34 = Group.getByName( groupName )
  local controllerSu34 = groupSu34.getController( groupSu34 )
  local groupShipNorth1 = Group.getByName( "US Ship North #001" )
  local groupShipNorth2 = Group.getByName( "US Ship North #002" )
  local groupShipNorth3 = Group.getByName( "US Ship North #003" )
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE )
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
  if groupShipNorth1 ~= nil then
    controllerSu34.pushTask( controllerSu34, { id = 'AttackGroup', params = { groupId = groupShipNorth1:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = false } } )
  end
  if groupShipNorth2 ~= nil then
    controllerSu34.pushTask( controllerSu34, { id = 'AttackGroup', params = { groupId = groupShipNorth2:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = false } } )
  end
  if groupShipNorth3 ~= nil then
    controllerSu34.pushTask( controllerSu34, { id = 'AttackGroup', params = { groupId = groupShipNorth3:getID(), expend = AI.Task.WeaponExpend.ALL, attackQtyLimit = false } } )
  end
  Su34Status.status[groupName] = 3
  MessageToRed( string.format( '%s: ', groupName ) .. 'Attacking invading ships in the north. ', 10, 'RedStatus' .. groupName )
end

function Su34Orbit( groupName )
  -- trace.menu("","Su34Orbit")
  local groupSu34 = Group.getByName( groupName )
  local controllerSu34 = groupSu34:getController()
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
  controllerSu34:pushTask( { id = 'ControlledTask', params = { task = { id = 'Orbit', params = { pattern = AI.Task.OrbitPattern.RACE_TRACK } }, stopCondition = { duration = 600 } } } )
  Su34Status.status[groupName] = 4
  MessageToRed( string.format( '%s: ', groupName ) .. 'In orbit and awaiting further instructions. ', 10, 'RedStatus' .. groupName )
end

function Su34TakeOff( groupName )
  -- trace.menu("","Su34TakeOff")
  local groupSu34 = Group.getByName( groupName )
  local controllerSu34 = groupSu34:getController()
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE )
  Su34Status.status[groupName] = 8
  MessageToRed( string.format( '%s: ', groupName ) .. 'Take-Off. ', 10, 'RedStatus' .. groupName )
end

function Su34Hold( groupName )
  -- trace.menu("","Su34Hold")
  local groupSu34 = Group.getByName( groupName )
  local controllerSu34 = groupSu34:getController()
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
  controllerSu34.setOption( controllerSu34, AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE )
  Su34Status.status[groupName] = 5
  MessageToRed( string.format( '%s: ', groupName ) .. 'Holding Weapons. ', 10, 'RedStatus' .. groupName )
end

function Su34RTB( groupName )
  -- trace.menu("","Su34RTB")
  Su34Status.status[groupName] = 6
  MessageToRed( string.format( '%s: ', groupName ) .. 'Return to Krasnodar. ', 10, 'RedStatus' .. groupName )
end

function Su34Destroyed( groupName )
  -- trace.menu("","Su34Destroyed")
  Su34Status.status[groupName] = 7
  MessageToRed( string.format( '%s: ', groupName ) .. 'Destroyed. ', 30, 'RedStatus' .. groupName )
end

function GroupAlive( groupName )
  -- trace.menu("","GroupAlive")
  local groupTest = Group.getByName( groupName )

  local groupExists = false

  if groupTest then
    groupExists = groupTest:isExist()
  end

  -- trace.r( "", "", { groupExists } )
  return groupExists
end

function Su34IsDead()
  -- trace.f()

end

function Su34OverviewStatus()
  -- trace.menu("","Su34OverviewStatus")
  local msg = ""
  local currentStatus = 0
  local Exists = false

  for groupName, currentStatus in pairs( Su34Status.status ) do

    env.info( ('Su34 Overview Status: GroupName = ' .. groupName) )
    Alive = GroupAlive( groupName )

    if Alive then
      if currentStatus == 1 then
        msg = msg .. string.format( "%s: ", groupName )
        msg = msg .. "Attacking carrier Carl Vinson. "
      elseif currentStatus == 2 then
        msg = msg .. string.format( "%s: ", groupName )
        msg = msg .. "Attacking supporting ships in the west. "
      elseif currentStatus == 3 then
        msg = msg .. string.format( "%s: ", groupName )
        msg = msg .. "Attacking invading ships in the north. "
      elseif currentStatus == 4 then
        msg = msg .. string.format( "%s: ", groupName )
        msg = msg .. "In orbit and awaiting further instructions. "
      elseif currentStatus == 5 then
        msg = msg .. string.format( "%s: ", groupName )
        msg = msg .. "Holding Weapons. "
      elseif currentStatus == 6 then
        msg = msg .. string.format( "%s: ", groupName )
        msg = msg .. "Return to Krasnodar. "
      elseif currentStatus == 7 then
        msg = msg .. string.format( "%s: ", groupName )
        msg = msg .. "Destroyed. "
      elseif currentStatus == 8 then
        msg = msg .. string.format( "%s: ", groupName )
        msg = msg .. "Take-Off. "
      end
    else
      if currentStatus == 7 then
        msg = msg .. string.format( "%s: ", groupName )
        msg = msg .. "Destroyed. "
      else
        Su34Destroyed( groupName )
      end
    end
  end

  boardMsgRed.statusMsg = msg
end

function UpdateBoardMsg()
  -- trace.f()
  Su34OverviewStatus()
  MessageToRed( boardMsgRed.statusMsg, 15, 'RedStatus' )
end

function MusicReset( flg )
  -- trace.f()
  trigger.action.setUserFlag( 95, flg )
end

function PlaneActivate( groupNameFormat, flg )
  -- trace.f()
  local groupName = groupNameFormat .. string.format( "#%03d", trigger.misc.getUserFlag( flg ) )
  -- trigger.action.outText(groupName,10)
  trigger.action.activateGroup( Group.getByName( groupName ) )
end

function Su34Menu( groupName )
  -- trace.f()

  -- env.info(( 'Su34Menu(' .. groupName .. ')' ))
  local groupSu34 = Group.getByName( groupName )

  if Su34Status.status[groupName] == 1 or Su34Status.status[groupName] == 2 or Su34Status.status[groupName] == 3 or Su34Status.status[groupName] == 4 or Su34Status.status[groupName] == 5 then
    if Su34MenuPath[groupName] == nil then
      if planeMenuPath == nil then
        planeMenuPath = missionCommands.addSubMenuForCoalition( coalition.side.RED, "SU-34 anti-ship flights", nil )
      end
      Su34MenuPath[groupName] = missionCommands.addSubMenuForCoalition( coalition.side.RED, "Flight " .. groupName, planeMenuPath )

      missionCommands.addCommandForCoalition( coalition.side.RED, "Attack carrier Carl Vinson", Su34MenuPath[groupName], Su34AttackCarlVinson, groupName )

      missionCommands.addCommandForCoalition( coalition.side.RED, "Attack ships in the west", Su34MenuPath[groupName], Su34AttackWest, groupName )

      missionCommands.addCommandForCoalition( coalition.side.RED, "Attack ships in the north", Su34MenuPath[groupName], Su34AttackNorth, groupName )

      missionCommands.addCommandForCoalition( coalition.side.RED, "Hold position and await instructions", Su34MenuPath[groupName], Su34Orbit, groupName )

      missionCommands.addCommandForCoalition( coalition.side.RED, "Report status", Su34MenuPath[groupName], Su34OverviewStatus )
    end
  else
    if Su34MenuPath[groupName] then
      missionCommands.removeItemForCoalition( coalition.side.RED, Su34MenuPath[groupName] )
    end
  end
end

--- Obsolete function, but kept to rework in framework.

function ChooseInfantry( TeleportPrefixTable, TeleportMax )
  -- trace.f("Spawn")
  -- env.info(( 'ChooseInfantry: ' ))

  TeleportPrefixTableCount = #TeleportPrefixTable
  TeleportPrefixTableIndex = math.random( 1, TeleportPrefixTableCount )

  -- env.info(( 'ChooseInfantry: TeleportPrefixTableIndex = ' .. TeleportPrefixTableIndex .. ' TeleportPrefixTableCount = ' .. TeleportPrefixTableCount  .. ' TeleportMax = ' .. TeleportMax ))

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
    -- env.info(( 'ChooseInfantry: Loop 1 - TeleportPrefix = ' .. TeleportPrefix .. ' Index = ' .. Index ))
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
      -- env.info(( 'ChooseInfantry: Loop 2 - TeleportPrefix = ' .. TeleportPrefix .. ' Index = ' .. Index ))
    end
  end

  local TeleportGroupName = ''
  if TeleportFound == true then
    TeleportGroupName = TeleportPrefix .. string.format( "#%03d", SpawnSettings[TeleportPrefix]['SpawnCount'] )
  else
    TeleportGroupName = ''
  end

  -- env.info(('ChooseInfantry: TeleportGroupName = ' .. TeleportGroupName ))
  -- env.info(('ChooseInfantry: return'))

  return TeleportGroupName
end

SpawnedInfantry = 0

function LandCarrier( CarrierGroup, LandingZonePrefix )
  -- trace.f()
  -- env.info(( 'LandCarrier: ' ))
  -- env.info(( 'LandCarrier: CarrierGroup = ' .. CarrierGroup:getName() ))
  -- env.info(( 'LandCarrier: LandingZone = ' .. LandingZonePrefix ))

  local controllerGroup = CarrierGroup:getController()

  local LandingZone = trigger.misc.getZone( LandingZonePrefix )
  local LandingZonePos = {}
  LandingZonePos.x = LandingZone.point.x + math.random( LandingZone.radius * -1, LandingZone.radius )
  LandingZonePos.y = LandingZone.point.z + math.random( LandingZone.radius * -1, LandingZone.radius )

  controllerGroup:pushTask( { id = 'Land', params = { point = LandingZonePos, durationFlag = true, duration = 10 } } )

  -- env.info(( 'LandCarrier: end' ))
end

EscortCount = 0
function EscortCarrier( CarrierGroup, EscortPrefix, EscortLastWayPoint, EscortEngagementDistanceMax, EscortTargetTypes )
  -- trace.f()
  -- env.info(( 'EscortCarrier: ' ))
  -- env.info(( 'EscortCarrier: CarrierGroup = ' .. CarrierGroup:getName() ))
  -- env.info(( 'EscortCarrier: EscortPrefix = ' .. EscortPrefix ))

  local CarrierName = CarrierGroup:getName()

  local EscortMission = {}
  local CarrierMission = {}

  local EscortMission = SpawnMissionGroup( EscortPrefix )
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

    EscortMission.route.points[1].task = {
      id = "ComboTask",
      params = {
        tasks = {
          [1] = {
            enabled = true,
            auto = false,
            id = "Escort",
            number = 1,
            params = {
              lastWptIndexFlagChangedManually = false,
              groupId = CarrierGroup:getID(),
              lastWptIndex = nil,
              lastWptIndexFlag = false,
              engagementDistMax = EscortEngagementDistanceMax,
              targetTypes = EscortTargetTypes,
              pos = { y = 20, x = 20, z = 0 } -- end of ["pos"]
            } -- end of ["params"]
          } -- end of [1]
        } -- end of ["tasks"]
      } -- end of ["params"]
    } -- end of ["task"]

    SpawnGroupAdd( EscortPrefix, EscortMission )

  end
end

function SendMessageToCarrier( CarrierGroup, CarrierMessage )
  -- trace.f()

  if CarrierGroup ~= nil then
    MessageToGroup( CarrierGroup, CarrierMessage, 30, 'Carrier/' .. CarrierGroup:getName() )
  end

end

function MessageToGroup( MsgGroup, MsgText, MsgTime, MsgName )
  -- trace.f()

  if type( MsgGroup ) == 'string' then
    -- env.info( 'MessageToGroup: Converted MsgGroup string "' .. MsgGroup .. '" into a Group structure.' )
    MsgGroup = Group.getByName( MsgGroup )
  end

  if MsgGroup ~= nil then
    local MsgTable = {}
    MsgTable.text = MsgText
    MsgTable.displayTime = MsgTime
    MsgTable.msgFor = { units = { MsgGroup:getUnits()[1]:getName() } }
    MsgTable.name = MsgName
    -- routines.message.add( MsgTable )
    -- env.info(('MessageToGroup: Message sent to ' .. MsgGroup:getUnits()[1]:getName() .. ' -> ' .. MsgText ))
  end
end

function MessageToUnit( UnitName, MsgText, MsgTime, MsgName )
  -- trace.f()

  if UnitName ~= nil then
    local MsgTable = {}
    MsgTable.text = MsgText
    MsgTable.displayTime = MsgTime
    MsgTable.msgFor = { units = { UnitName } }
    MsgTable.name = MsgName
    -- routines.message.add( MsgTable )
  end
end

function MessageToAll( MsgText, MsgTime, MsgName )
  -- trace.f()

  MESSAGE:New( MsgText, MsgTime, "Message" ):ToCoalition( coalition.side.RED ):ToCoalition( coalition.side.BLUE )
end

function MessageToRed( MsgText, MsgTime, MsgName )
  -- trace.f()

  MESSAGE:New( MsgText, MsgTime, "To Red Coalition" ):ToCoalition( coalition.side.RED )
end

function MessageToBlue( MsgText, MsgTime, MsgName )
  -- trace.f()

  MESSAGE:New( MsgText, MsgTime, "To Blue Coalition" ):ToCoalition( coalition.side.BLUE )
end

function getCarrierHeight( CarrierGroup )
  -- trace.f()

  if CarrierGroup ~= nil then
    if table.getn( CarrierGroup:getUnits() ) == 1 then
      local CarrierUnit = CarrierGroup:getUnits()[1]
      local CurrentPoint = CarrierUnit:getPoint()

      local CurrentPosition = { x = CurrentPoint.x, y = CurrentPoint.z }
      local CarrierHeight = CurrentPoint.y

      local LandHeight = land.getHeight( CurrentPosition )

      -- env.info(( 'CarrierHeight: LandHeight = ' .. LandHeight .. ' CarrierHeight = ' .. CarrierHeight ))

      return CarrierHeight - LandHeight
    else
      return 999999
    end
  else
    return 999999
  end
end

function GetUnitHeight( CheckUnit )
  -- trace.f()

  local UnitPoint = CheckUnit:getPoint()
  local UnitPosition = { x = CurrentPoint.x, y = CurrentPoint.z }
  local UnitHeight = CurrentPoint.y

  local LandHeight = land.getHeight( CurrentPosition )

  -- env.info(( 'CarrierHeight: LandHeight = ' .. LandHeight .. ' CarrierHeight = ' .. CarrierHeight ))

  return UnitHeight - LandHeight
end

_MusicTable = {}
_MusicTable.Files = {}
_MusicTable.Queue = {}
_MusicTable.FileCnt = 0

function MusicRegister( SndRef, SndFile, SndTime )
  -- trace.f()

  env.info( ('MusicRegister: SndRef = ' .. SndRef) )
  env.info( ('MusicRegister: SndFile = ' .. SndFile) )
  env.info( ('MusicRegister: SndTime = ' .. SndTime) )

  _MusicTable.FileCnt = _MusicTable.FileCnt + 1

  _MusicTable.Files[_MusicTable.FileCnt] = {}
  _MusicTable.Files[_MusicTable.FileCnt].Ref = SndRef
  _MusicTable.Files[_MusicTable.FileCnt].File = SndFile
  _MusicTable.Files[_MusicTable.FileCnt].Time = SndTime

  if not _MusicTable.Function then
    _MusicTable.Function = routines.scheduleFunction( MusicScheduler, {}, timer.getTime() + 10, 10 )
  end
end

function MusicToPlayer( SndRef, PlayerName, SndContinue )
  -- trace.f()

  -- env.info(( 'MusicToPlayer: SndRef = ' .. SndRef  ))

  local PlayerUnits = AlivePlayerUnits()
  for PlayerUnitIdx, PlayerUnit in pairs( PlayerUnits ) do
    local PlayerUnitName = PlayerUnit:getPlayerName()
    -- env.info(( 'MusicToPlayer: PlayerUnitName = ' .. PlayerUnitName  ))
    if PlayerName == PlayerUnitName then
      PlayerGroup = PlayerUnit:getGroup()
      if PlayerGroup then
        -- env.info(( 'MusicToPlayer: PlayerGroup = ' .. PlayerGroup:getName() ))
        MusicToGroup( SndRef, PlayerGroup, SndContinue )
      end
      break
    end
  end

  -- env.info(( 'MusicToPlayer: end'  ))
end

function MusicToGroup( SndRef, SndGroup, SndContinue )
  -- trace.f()

  -- env.info(( 'MusicToGroup: SndRef = ' .. SndRef  ))

  if SndGroup ~= nil then
    if _MusicTable and _MusicTable.FileCnt > 0 then
      if SndGroup:isExist() then
        if MusicCanStart( SndGroup:getUnit( 1 ):getPlayerName() ) then
          -- env.info(( 'MusicToGroup: OK for Sound.'  ))
          local SndIdx = 0
          if SndRef == '' then
            -- env.info(( 'MusicToGroup: SndRef as empty. Queueing at random.'  ))
            SndIdx = math.random( 1, _MusicTable.FileCnt )
          else
            for SndIdx = 1, _MusicTable.FileCnt do
              if _MusicTable.Files[SndIdx].Ref == SndRef then
                break
              end
            end
          end
          -- env.info(( 'MusicToGroup: SndIdx =  ' .. SndIdx ))
          -- env.info(( 'MusicToGroup: Queueing Music ' .. _MusicTable.Files[SndIdx].File .. ' for Group ' ..  SndGroup:getID() ))
          trigger.action.outSoundForGroup( SndGroup:getID(), _MusicTable.Files[SndIdx].File )
          MessageToGroup( SndGroup, 'Playing ' .. _MusicTable.Files[SndIdx].File, 15, 'Music-' .. SndGroup:getUnit( 1 ):getPlayerName() )

          local SndQueueRef = SndGroup:getUnit( 1 ):getPlayerName()
          if _MusicTable.Queue[SndQueueRef] == nil then
            _MusicTable.Queue[SndQueueRef] = {}
          end
          _MusicTable.Queue[SndQueueRef].Start = timer.getTime()
          _MusicTable.Queue[SndQueueRef].PlayerName = SndGroup:getUnit( 1 ):getPlayerName()
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

function MusicCanStart( PlayerName )
  -- trace.f()

  -- env.info(( 'MusicCanStart:' ))

  local MusicOut = false

  if _MusicTable['Queue'] ~= nil and _MusicTable.FileCnt > 0 then
    -- env.info(( 'MusicCanStart: PlayerName = ' .. PlayerName ))
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
      -- env.info(( 'MusicCanStart: MusicStart = ' .. MusicStart ))
      -- env.info(( 'MusicCanStart: MusicTime = ' .. MusicTime ))
      -- env.info(( 'MusicCanStart: timer.getTime() = ' .. timer.getTime() ))

      if MusicStart + MusicTime <= timer.getTime() then
        MusicOut = true
      end
    else
      MusicOut = true
    end
  end

  if MusicOut then
    -- env.info(( 'MusicCanStart: true' ))
  else
    -- env.info(( 'MusicCanStart: false' ))
  end

  return MusicOut
end

function MusicScheduler()
  -- trace.scheduled("", "MusicScheduler")

  -- env.info(( 'MusicScheduler:' ))
  if _MusicTable['Queue'] ~= nil and _MusicTable.FileCnt > 0 then
    -- env.info(( 'MusicScheduler: Walking Sound Queue.'))
    for SndQueueIdx, SndQueue in pairs( _MusicTable.Queue ) do
      if SndQueue.Continue then
        if MusicCanStart( SndQueue.PlayerName ) then
          -- env.info(('MusicScheduler: MusicToGroup'))
          MusicToPlayer( '', SndQueue.PlayerName, true )
        end
      end
    end
  end
end

env.info( ('Init: Scripts Loaded v1.1') )
