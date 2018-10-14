--- This module contains derived utilities taken from the MIST framework, 
-- which are excellent tools to be reused in an OO environment!.
-- 
-- ### Authors: 
-- 
--   * Grimes : Design & Programming of the MIST framework.
--   
-- ### Contributions:
-- 
--   * FlightControl : Rework to OO framework 
-- 
-- @module Utils
-- @image MOOSE.JPG


--- @type SMOKECOLOR
-- @field Green
-- @field Red
-- @field White
-- @field Orange
-- @field Blue
 
SMOKECOLOR = trigger.smokeColor -- #SMOKECOLOR

--- @type FLARECOLOR
-- @field Green
-- @field Red
-- @field White
-- @field Yellow

FLARECOLOR = trigger.flareColor -- #FLARECOLOR

--- Big smoke preset enum.
-- @type BIGSMOKEPRESET
BIGSMOKEPRESET = {
  SmallSmokeAndFire=0,
  MediumSmokeAndFire=1,
  LargeSmokeAndFire=2,
  HugeSmokeAndFire=3,
  SmallSmoke=4,
  MediumSmoke=5,
  LargeSmoke=6,
  HugeSmoke=7,
}

--- Utilities static class.
-- @type UTILS
UTILS = {
  _MarkID = 1
}

--- Function to infer instance of an object
--
-- ### Examples:
--
--    * UTILS.IsInstanceOf( 'some text', 'string' ) will return true
--    * UTILS.IsInstanceOf( some_function, 'function' ) will return true
--    * UTILS.IsInstanceOf( 10, 'number' ) will return true
--    * UTILS.IsInstanceOf( false, 'boolean' ) will return true
--    * UTILS.IsInstanceOf( nil, 'nil' ) will return true
--
--    * UTILS.IsInstanceOf( ZONE:New( 'some zone', ZONE ) will return true
--    * UTILS.IsInstanceOf( ZONE:New( 'some zone', 'ZONE' ) will return true
--    * UTILS.IsInstanceOf( ZONE:New( 'some zone', 'zone' ) will return true
--    * UTILS.IsInstanceOf( ZONE:New( 'some zone', 'BASE' ) will return true
--
--    * UTILS.IsInstanceOf( ZONE:New( 'some zone', 'GROUP' ) will return false
--
--
-- @param object is the object to be evaluated
-- @param className is the name of the class to evaluate (can be either a string or a Moose class)
-- @return #boolean
UTILS.IsInstanceOf = function( object, className )
  -- Is className NOT a string ?
  if not type( className ) == 'string' then
  
    -- Is className a Moose class ?
    if type( className ) == 'table' and className.IsInstanceOf ~= nil then
    
      -- Get the name of the Moose class as a string
      className = className.ClassName
      
    -- className is neither a string nor a Moose class, throw an error
    else
    
      -- I'm not sure if this should take advantage of MOOSE logging function, or throw an error for pcall
      local err_str = 'className parameter should be a string; parameter received: '..type( className )
      return false
      -- error( err_str )
      
    end
  end
  
  -- Is the object a Moose class instance ?
  if type( object ) == 'table' and object.IsInstanceOf ~= nil then
  
    -- Use the IsInstanceOf method of the BASE class
    return object:IsInstanceOf( className )
  else
  
    -- If the object is not an instance of a Moose class, evaluate against lua basic data types
    local basicDataTypes = { 'string', 'number', 'function', 'boolean', 'nil', 'table' }
    for _, basicDataType in ipairs( basicDataTypes ) do
      if className == basicDataType then
        return type( object ) == basicDataType
      end
    end
  end
  
  -- Check failed
  return false
end


--from http://lua-users.org/wiki/CopyTable
UTILS.DeepCopy = function(object)
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
UTILS.OneLineSerialize = function( tbl )  -- serialization of a table all on a single line, no comments, made to replace old get_table_string function

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
          --  tbl_str[#tbl_str + 1] = "__index"
          --  tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
          else

            val_str[#val_str + 1] = _Serialize(val)
            val_str[#val_str + 1] = ','   --I think this is right, I just added it
            tbl_str[#tbl_str + 1] = table.concat(ind_str)
            tbl_str[#tbl_str + 1] = table.concat(val_str)
          end
        elseif type(val) == 'function' then
          tbl_str[#tbl_str + 1] = "f() " .. tostring(ind)
          tbl_str[#tbl_str + 1] = ','   --I think this is right, I just added it
        else
          env.info('unable to serialize value type ' .. routines.utils.basicSerialize(type(val)) .. ' at index ' .. tostring(ind))
          env.info( debug.traceback() )
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
UTILS.BasicSerialize = function(s)
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


UTILS.ToDegree = function(angle)
  return angle*180/math.pi
end

UTILS.ToRadian = function(angle)
  return angle*math.pi/180
end

UTILS.MetersToNM = function(meters)
  return meters/1852
end

UTILS.MetersToFeet = function(meters)
  return meters/0.3048
end

UTILS.NMToMeters = function(NM)
  return NM*1852
end

UTILS.FeetToMeters = function(feet)
  return feet*0.3048
end

UTILS.KnotsToKmph = function(knots)
  return knots* 1.852
end

UTILS.KmphToMps = function( kmph )
  return kmph / 3.6
end

UTILS.MpsToKmph = function( mps )
  return mps * 3.6
end

UTILS.MiphToMps = function( miph )
  return miph * 0.44704
end

UTILS.MpsToMiph = function( mps )
  return mps / 0.44704
end

UTILS.MpsToKnots = function( mps )
  return mps * 3600 / 1852
end

UTILS.KnotsToMps = function( knots )
  return knots * 1852 / 3600
end

UTILS.CelciusToFarenheit = function( Celcius )
  return Celcius * 9/5 + 32 
end



--[[acc:
in DM: decimal point of minutes.
In DMS: decimal point of seconds.
position after the decimal of the least significant digit:
So:
42.32 - acc of 2.
]]
UTILS.tostringLL = function( lat, lon, acc, DMS)

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
    local latSec = UTILS.Round((oldLatMin - latMin)*60, acc)

    local oldLonMin = lonMin
    lonMin = math.floor(lonMin)
    local lonSec = UTILS.Round((oldLonMin - lonMin)*60, acc)

    if latSec == 60 then
      latSec = 0
      latMin = latMin + 1
    end

    if lonSec == 60 then
      lonSec = 0
      lonMin = lonMin + 1
    end

    local secFrmtStr -- create the formatting string for the seconds place
    secFrmtStr = '%02d'
--    if acc <= 0 then  -- no decimal place.
--      secFrmtStr = '%02d'
--    else
--      local width = 3 + acc  -- 01.310 - that's a width of 6, for example.
--      secFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
--    end

    return string.format('%03d', latDeg) .. ' ' .. string.format('%02d', latMin) .. '\' ' .. string.format(secFrmtStr, latSec) .. '"' .. latHemi .. '   '
           .. string.format('%03d', lonDeg) .. ' ' .. string.format('%02d', lonMin) .. '\' ' .. string.format(secFrmtStr, lonSec) .. '"' .. lonHemi

  else  -- degrees, decimal minutes.
    latMin = UTILS.Round(latMin, acc)
    lonMin = UTILS.Round(lonMin, acc)

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

    return string.format('%03d', latDeg) .. ' ' .. string.format(minFrmtStr, latMin) .. '\'' .. latHemi .. '   '
     .. string.format('%03d', lonDeg) .. ' ' .. string.format(minFrmtStr, lonMin) .. '\'' .. lonHemi

  end
end

-- acc- the accuracy of each easting/northing.  0, 1, 2, 3, 4, or 5.
UTILS.tostringMGRS = function(MGRS, acc) --R2.1
  if acc == 0 then
    return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph
  else
    return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph .. ' ' .. string.format('%0' .. acc .. 'd', UTILS.Round(MGRS.Easting/(10^(5-acc)), 0))
           .. ' ' .. string.format('%0' .. acc .. 'd', UTILS.Round(MGRS.Northing/(10^(5-acc)), 0))
  end
end


--- From http://lua-users.org/wiki/SimpleRound
-- use negative idp for rounding ahead of decimal place, positive for rounding after decimal place
function UTILS.Round( num, idp )
  local mult = 10 ^ ( idp or 0 )
  return math.floor( num * mult + 0.5 ) / mult
end

-- porting in Slmod's dostring
function UTILS.DoString( s )
  local f, err = loadstring( s )
  if f then
    return true, f()
  else
    return false, err
  end
end

-- Here is a customized version of pairs, which I called spairs because it iterates over the table in a sorted order.
function UTILS.spairs( t, order )
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

-- get a new mark ID for markings
function UTILS.GetMarkID()

  UTILS._MarkID = UTILS._MarkID + 1
  return UTILS._MarkID

end


-- Test if a Vec2 is in a radius of another Vec2
function UTILS.IsInRadius( InVec2, Vec2, Radius )

  local InRadius = ( ( InVec2.x - Vec2.x ) ^2 + ( InVec2.y - Vec2.y ) ^2 ) ^ 0.5 <= Radius

  return InRadius
end

-- Test if a Vec3 is in the sphere of another Vec3
function UTILS.IsInSphere( InVec3, Vec3, Radius )

  local InSphere = ( ( InVec3.x - Vec3.x ) ^2 + ( InVec3.y - Vec3.y ) ^2 + ( InVec3.z - Vec3.z ) ^2 ) ^ 0.5 <= Radius

  return InSphere
end

-- Beaufort scale: returns Beaufort number and wind description as a function of wind speed in m/s.
function UTILS.BeaufortScale(speed)
  local bn=nil
  local bd=nil
  if speed<0.51 then
    bn=0
    bd="Calm"
  elseif speed<2.06 then
    bn=1
    bd="Light Air"
  elseif speed<3.60 then
    bn=2
    bd="Light Breeze"
  elseif speed<5.66 then
    bn=3
    bd="Gentle Breeze"
  elseif speed<8.23 then
    bn=4
    bd="Moderate Breeze"
  elseif speed<11.32 then
    bn=5
    bd="Fresh Breeze"
  elseif speed<14.40 then
    bn=6
    bd="Strong Breeze"
  elseif speed<17.49 then
    bn=7
    bd="Moderate Gale"
  elseif speed<21.09 then
    bn=8
    bd="Fresh Gale"
  elseif speed<24.69 then
    bn=9
    bd="Strong Gale"
  elseif speed<28.81 then
    bn=10
    bd="Storm"
  elseif speed<32.92 then
    bn=11
    bd="Violent Storm"
  else
    bn=12
    bd="Hurricane"
  end
  return bn,bd
end

--- Split string at seperators. C.f. http://stackoverflow.com/questions/1426954/split-string-in-lua
-- @param #string str Sting to split.
-- @param #string sep Speparator for split.
-- @return #table Split text.
function UTILS.Split(str, sep)
  local result = {}
  local regex = ("([^%s]+)"):format(sep)
  for each in str:gmatch(regex) do
    table.insert(result, each)
  end
  return result
end

--- Convert time in seconds to hours, minutes and seconds.
-- @param #number seconds Time in seconds, e.g. from timer.getAbsTime() function.
-- @return #string Time in format Hours:Minutes:Seconds+Days (HH:MM:SS+D).
function UTILS.SecondsToClock(seconds)
  
  -- Nil check.
  if seconds==nil then
    return nil
  end
  
  -- Seconds
  local seconds = tonumber(seconds)
  
  -- Seconds of this day.
  local _seconds=seconds%(60*60*24)

  if seconds <= 0 then
    return nil
  else
    local hours = string.format("%02.f", math.floor(_seconds/3600))
    local mins  = string.format("%02.f", math.floor(_seconds/60 - (hours*60)))
    local secs  = string.format("%02.f", math.floor(_seconds - hours*3600 - mins *60))
    local days  = string.format("%d", seconds/(60*60*24))
    return hours..":"..mins..":"..secs.."+"..days
  end
end

--- Convert clock time from hours, minutes and seconds to seconds.
-- @param #string clock String of clock time. E.g., "06:12:35" or "5:1:30+1". Format is (H)H:(M)M:((S)S)(+D) H=Hours, M=Minutes, S=Seconds, D=Days.
-- @param #number Seconds. Corresponds to what you cet from timer.getAbsTime() function.
function UTILS.ClockToSeconds(clock)
  
  -- Nil check.
  if clock==nil then
    return nil
  end
  
  -- Seconds init.
  local seconds=0
  
  -- Split additional days.
  local dsplit=UTILS.split(clock, "+")
  
  -- Convert days to seconds.
  if #dsplit>1 then
    seconds=seconds+tonumber(dsplit[2])*60*60*24
  end

  -- Split hours, minutes, seconds    
  local tsplit=UTILS.Split(dsplit[1], ":")

  -- Get time in seconds
  local i=1
  for _,time in ipairs(tsplit) do
    if i==1 then
      -- Hours
      seconds=seconds+tonumber(time)*60*60
    elseif i==2 then
      -- Minutes
      seconds=seconds+tonumber(time)*60
    elseif i==3 then
      -- Seconds
      seconds=seconds+tonumber(time)
    end
    i=i+1
  end
  
  return seconds
end

--- Display clock and mission time on screen as a message to all.
-- @param #number duration Duration in seconds how long the time is displayed. Default is 5 seconds.
function UTILS.DisplayMissionTime(duration)
  duration=duration or 5
  local Tnow=timer.getAbsTime()
  local mission_time=Tnow-timer.getTime0()
  local mission_time_minutes=mission_time/60
  local mission_time_seconds=mission_time%60
  local local_time=UTILS.SecondsToClock(Tnow)  
  local text=string.format("Time: %s - %02d:%02d", local_time, mission_time_minutes, mission_time_seconds)
  MESSAGE:New(text, duration):ToAll()
end


--- Generate a Gaussian pseudo-random number.
-- @param #number x0 Expectation value of distribution.
-- @param #number sigma (Optional) Standard deviation. Default 10.
-- @param #number xmin (Optional) Lower cut-off value.
-- @param #number xmax (Optional) Upper cut-off value.
-- @param #number imax (Optional) Max number of tries to get a value between xmin and xmax (if specified). Default 100.
-- @return #number Gaussian random number.
function UTILS.RandomGaussian(x0, sigma, xmin, xmax, imax)

  -- Standard deviation. Default 10 if not given.
  sigma=sigma or 10
  
  -- Max attempts.
  imax=imax or 100
    
  local r
  local gotit=false
  local i=0
  while not gotit do
  
    -- Uniform numbers in [0,1). We need two.
    local x1=math.random()
    local x2=math.random()
  
    -- Transform to Gaussian exp(-(x-x0)²/(2*sigma²).
    r = math.sqrt(-2*sigma*sigma * math.log(x1)) * math.cos(2*math.pi * x2) + x0
    
    i=i+1
    if (r>=xmin and r<=xmax) or i>imax then
      gotit=true
    end
  end
  
  return r
end

--- Randomize a value by a certain amount.
-- @param #number value The value which should be randomized
-- @param #number fac Randomization factor.
-- @param #number lower (Optional) Lower limit of the returned value.
-- @param #number upper (Optional) Upper limit of the returned value.
-- @return #number Randomized value.
-- @usage UTILS.Randomize(100, 0.1) returns a value between 90 and 110, i.e. a plus/minus ten percent variation.
-- @usage UTILS.Randomize(100, 0.5, nil, 120) returns a value between 50 and 120, i.e. a plus/minus fivty percent variation with upper bound 120.
function UTILS.Randomize(value, fac, lower, upper)
  local min
  if lower then
    min=math.max(value-value*fac, lower)
  else
    min=value-value*fac
  end
  local max
  if upper then
    max=math.min(value+value*fac, upper)
  else
    max=value+value*fac
  end
  
  local r=math.random(min, max)
  
  return r
end

--- Calculate the [dot product](https://en.wikipedia.org/wiki/Dot_product) of two vectors. The result is a number.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @param DCS#Vec3 b Vector in 3D with x, y, z components.
-- @return #number Scalar product of the two vectors a*b.
function UTILS.VecDot(a, b)
  return a.x*b.x + a.y*b.y + a.z*b.z
end

--- Calculate the [euclidean norm](https://en.wikipedia.org/wiki/Euclidean_distance) (length) of a 3D vector.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @return #number Norm of the vector.
function UTILS.VecNorm(a)
  return math.sqrt(UTILS.VecDot(a, a))
end

--- Calculate the [cross product](https://en.wikipedia.org/wiki/Cross_product) of two 3D vectors. The result is a 3D vector.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @param DCS#Vec3 b Vector in 3D with x, y, z components.
-- @return DCS#Vec3 Vector
function UTILS.VecCross(a, b)
  return {x=a.y*b.z - a.z*b.y, y=a.z*b.x - a.x*b.z, z=a.x*b.y - a.y*b.x}
end

