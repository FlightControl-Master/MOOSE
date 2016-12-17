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

--- Utilities static class.
-- @type UTILS
UTILS = {}


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

UTILS.MpsToKnots = function(mps)
  return mps*3600/1852
end

UTILS.MpsToKmph = function(mps)
  return mps*3.6
end

UTILS.KnotsToMps = function(knots)
  return knots*1852/3600
end

UTILS.KmphToMps = function(kmph)
  return kmph/3.6
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
    if acc <= 0 then  -- no decimal place.
      secFrmtStr = '%02d'
    else
      local width = 3 + acc  -- 01.310 - that's a width of 6, for example.
      secFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
    end

    return string.format('%02d', latDeg) .. ' ' .. string.format('%02d', latMin) .. '\' ' .. string.format(secFrmtStr, latSec) .. '"' .. latHemi .. '   '
           .. string.format('%02d', lonDeg) .. ' ' .. string.format('%02d', lonMin) .. '\' ' .. string.format(secFrmtStr, lonSec) .. '"' .. lonHemi

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

    return string.format('%02d', latDeg) .. ' ' .. string.format(minFrmtStr, latMin) .. '\'' .. latHemi .. '   '
     .. string.format('%02d', lonDeg) .. ' ' .. string.format(minFrmtStr, lonMin) .. '\'' .. lonHemi

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
