--- This module contains derived utilities taken from the MIST framework, as well as a lot of added helpers from the MOOSE community.
--
-- ### Authors:
--
--   * Grimes : Design & Programming of the MIST framework.
--
-- ### Contributions:
--
--   * FlightControl : Rework to OO framework.
--   * And many more
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
  SmallSmokeAndFire=1,
  MediumSmokeAndFire=2,
  LargeSmokeAndFire=3,
  HugeSmokeAndFire=4,
  SmallSmoke=5,
  MediumSmoke=6,
  LargeSmoke=7,
  HugeSmoke=8,
}

--- DCS map as returned by env.mission.theatre.
-- @type DCSMAP
-- @field #string Caucasus Caucasus map.
-- @field #string Normandy Normandy map.
-- @field #string NTTR Nevada Test and Training Range map.
-- @field #string PersianGulf Persian Gulf map.
-- @field #string TheChannel The Channel map.
-- @field #string Syria Syria map.
-- @field #string MarianaIslands Mariana Islands map.
DCSMAP = {
  Caucasus="Caucasus",
  NTTR="Nevada",
  Normandy="Normandy",
  PersianGulf="PersianGulf",
  TheChannel="TheChannel",
  Syria="Syria",
  MarianaIslands="MarianaIslands"
}


--- See [DCS_enum_callsigns](https://wiki.hoggitworld.com/view/DCS_enum_callsigns)
-- @type CALLSIGN
CALLSIGN={
  -- Aircraft
  Aircraft={
    Enfield=1,
    Springfield=2,
    Uzi=3,
    Colt=4,
    Dodge=5,
    Ford=6,
    Chevy=7,
    Pontiac=8,
    -- A-10A or A-10C
    Hawg=9,
    Boar=10,
    Pig=11,
    Tusk=12,
  },
  -- AWACS
  AWACS={
    Overlord=1,
    Magic=2,
    Wizard=3,
    Focus=4,
    Darkstar=5,
  },
  -- Tanker
  Tanker={
    Texaco=1,
    Arco=2,
    Shell=3,
  },
  -- JTAC
  JTAC={
    Axeman=1,
    Darknight=2,
    Warrior=3,
    Pointer=4,
    Eyeball=5,
    Moonbeam=6,
    Whiplash=7,
    Finger=8,
    Pinpoint=9,
    Ferret=10,
    Shaba=11,
    Playboy=12,
    Hammer=13,
    Jaguar=14,
    Deathstar=15,
    Anvil=16,
    Firefly=17,
    Mantis=18,
    Badger=19,
  },
  -- FARP
  FARP={
    London=1,
    Dallas=2,
    Paris=3,
    Moscow=4,
    Berlin=5,
    Rome=6,
    Madrid=7,
    Warsaw=8,
    Dublin=9,
    Perth=10,
  },
  F16={
    Viper=9,
    Venom=10,
    Lobo=11,
    Cowboy=12,
    Python=13,
    Rattler=14,
    Panther=15,
    Wolf=16,
    Weasel=17,
    Wild=18,
    Ninja=19,
    Jedi=20,
  },
  F18={
    Hornet=9,
    Squid=10,
    Ragin=11,
    Roman=12,
    Sting=13,
    Jury=14,
    Jokey=15,
    Ram=16,
    Hawk=17,
    Devil=18,
    Check=19,
    Snake=20,
  },
  F15E={
    Dude=9,
    Thud=10,
    Gunny=11,
    Trek=12,
    Sniper=13,
    Sled=14,
    Best=15,
    Jazz=16,
    Rage=17,
    Tahoe=18,
  },
  B1B={
    Bone=9,
    Dark=10,
    Vader=11
  },
  B52={
    Buff=9,
    Dump=10,
    Kenworth=11,
  },
  TransportAircraft={
    Heavy=9,
    Trash=10,
    Cargo=11,
    Ascot=12,
  },
} --#CALLSIGN

--- Utilities static class.
-- @type UTILS
-- @field #number _MarkID Marker index counter. Running number when marker is added.
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


--- Deep copy a table. See http://lua-users.org/wiki/CopyTable
-- @param #table object The input table.
-- @return #table Copy of the input table.
UTILS.DeepCopy = function(object)

  local lookup_table = {}

  -- Copy function.
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


--- Porting in Slmod's serialize_slmod2.
-- @param #table tbl Input table.
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

UTILS.KiloMetersToNM = function(kilometers)
  return kilometers/1852*1000
end

UTILS.MetersToSM = function(meters)
  return meters/1609.34
end

UTILS.KiloMetersToSM = function(kilometers)
  return kilometers/1609.34*1000
end

UTILS.MetersToFeet = function(meters)
  return meters/0.3048
end

UTILS.KiloMetersToFeet = function(kilometers)
  return kilometers/0.3048*1000
end

UTILS.NMToMeters = function(NM)
  return NM*1852
end

UTILS.NMToKiloMeters = function(NM)
  return NM*1852/1000
end

UTILS.FeetToMeters = function(feet)
  return feet*0.3048
end

UTILS.KnotsToKmph = function(knots)
  return knots * 1.852
end

UTILS.KmphToKnots = function(knots)
  return knots / 1.852
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

--- Convert meters per second to miles per hour.
-- @param #number mps Speed in m/s.
-- @return #number Speed in miles per hour.
UTILS.MpsToMiph = function( mps )
  return mps / 0.44704
end

--- Convert meters per second to knots.
-- @param #number mps Speed in m/s.
-- @return #number Speed in knots.
UTILS.MpsToKnots = function( mps )
  return mps * 1.94384 --3600 / 1852
end

--- Convert knots to meters per second.
-- @param #number knots Speed in knots.
-- @return #number Speed in m/s.
UTILS.KnotsToMps = function( knots )
  if type(knots) == "number" then
    return knots / 1.94384 --* 1852 / 3600
  else
   return 0
  end
end

--- Convert temperature from Celsius to Fahrenheit.
-- @param #number Celcius Temperature in degrees Celsius.
-- @return #number Temperature in degrees Fahrenheit.
UTILS.CelsiusToFahrenheit = function( Celcius )
  return Celcius * 9/5 + 32
end

--- Convert pressure from hecto Pascal (hPa) to inches of mercury (inHg).
-- @param #number hPa Pressure in hPa.
-- @return #number Pressure in inHg.
UTILS.hPa2inHg = function( hPa )
  return hPa * 0.0295299830714
end

--- Convert knots to alitude corrected KIAS, e.g. for tankers.
-- @param #number knots Speed in knots.
-- @param #number altitude Altitude in feet
-- @return #number Corrected KIAS
UTILS.KnotsToAltKIAS = function( knots, altitude )
  return (knots * 0.018 * (altitude / 1000)) + knots
end

--- Convert pressure from hecto Pascal (hPa) to millimeters of mercury (mmHg).
-- @param #number hPa Pressure in hPa.
-- @return #number Pressure in mmHg.
UTILS.hPa2mmHg = function( hPa )
  return hPa * 0.7500615613030
end

--- Convert kilo gramms (kg) to pounds (lbs).
-- @param #number kg Mass in kg.
-- @return #number Mass in lbs.
UTILS.kg2lbs = function( kg )
  return kg * 2.20462
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
    if acc <= 0 then  -- no decimal place.
      secFrmtStr = '%02d'
    else
      local width = 3 + acc  -- 01.310 - that's a width of 6, for example. Acc is limited to 2 for DMS!
      secFrmtStr = '%0' .. width .. '.' .. acc .. 'f'
    end

    -- 024° 23' 12"N or 024° 23' 12.03"N
    return string.format('%03d°', latDeg)..string.format('%02d', latMin)..'\''..string.format(secFrmtStr, latSec)..'"'..latHemi..' '
        .. string.format('%03d°', lonDeg)..string.format('%02d', lonMin)..'\''..string.format(secFrmtStr, lonSec)..'"'..lonHemi

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

    -- 024 23'N or 024 23.123'N
    return string.format('%03d°', latDeg) .. ' ' .. string.format(minFrmtStr, latMin) .. '\'' .. latHemi .. '   '
        .. string.format('%03d°', lonDeg) .. ' ' .. string.format(minFrmtStr, lonMin) .. '\'' .. lonHemi

  end
end

-- acc- the accuracy of each easting/northing.  0, 1, 2, 3, 4, or 5.
UTILS.tostringMGRS = function(MGRS, acc) --R2.1

  if acc == 0 then
    return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph
  else

    -- Test if Easting/Northing have less than 4 digits.
    --MGRS.Easting=123    -- should be 00123
    --MGRS.Northing=5432  -- should be 05432

    -- Truncate rather than round MGRS grid!
    local Easting=tostring(MGRS.Easting)
    local Northing=tostring(MGRS.Northing)

    -- Count number of missing digits. Easting/Northing should have 5 digits. However, it is passed as a number. Therefore, any leading zeros would not be displayed by lua.
    local nE=5-string.len(Easting)
    local nN=5-string.len(Northing)

    -- Get leading zeros (if any).
    for i=1,nE do Easting="0"..Easting end
    for i=1,nN do Northing="0"..Northing end

    -- Return MGRS string.
    return string.format("%s %s %s %s", MGRS.UTMZone, MGRS.MGRSDigraph, string.sub(Easting, 1, acc), string.sub(Northing, 1, acc))
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


-- Here is a customized version of pairs, which I called kpairs because it iterates over the table in a sorted order, based on a function that will determine the keys as reference first.
function UTILS.kpairs( t, getkey, order )
    -- collect the keys
    local keys = {}
    local keyso = {}
    for k, o in pairs(t) do keys[#keys+1] = k keyso[#keyso+1] = getkey( o ) end

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
            return keyso[i], t[keys[i]]
        end
    end
end

-- Here is a customized version of pairs, which I called rpairs because it iterates over the table in a random order.
function UTILS.rpairs( t )
    -- collect the keys

    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    local random = {}
    local j = #keys
    for i = 1, j do
      local k = math.random( 1, #keys )
      random[i] = keys[k]
      table.remove( keys, k )
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if random[i] then
            return random[i], t[random[i]]
        end
    end
end

-- get a new mark ID for markings
function UTILS.GetMarkID()

  UTILS._MarkID = UTILS._MarkID + 1
  return UTILS._MarkID

end

--- Remove an object (marker, circle, arrow, text, quad, ...) on the F10 map.
-- @param #number MarkID Unique ID of the object.
-- @param #number Delay (Optional) Delay in seconds before the mark is removed.
function UTILS.RemoveMark(MarkID, Delay)
  if Delay and Delay>0 then
    TIMER:New(UTILS.RemoveMark, MarkID):Start(Delay)
  else
    trigger.action.removeMark(MarkID)
  end
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

--- Beaufort scale: returns Beaufort number and wind description as a function of wind speed in m/s.
-- @param #number speed Wind speed in m/s.
-- @return #number Beaufort number.
-- @return #string Beauford wind description.
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

--- Get a table of all characters in a string.
-- @param #string str Sting.
-- @return #table Individual characters.
function UTILS.GetCharacters(str)

  local chars={}

  for i=1,#str do
    local c=str:sub(i,i)
    table.insert(chars, c)
  end

  return chars
end

--- Convert time in seconds to hours, minutes and seconds.
-- @param #number seconds Time in seconds, e.g. from timer.getAbsTime() function.
-- @param #boolean short (Optional) If true, use short output, i.e. (HH:)MM:SS without day.
-- @return #string Time in format Hours:Minutes:Seconds+Days (HH:MM:SS+D).
function UTILS.SecondsToClock(seconds, short)

  -- Nil check.
  if seconds==nil then
    return nil
  end

  -- Seconds
  local seconds = tonumber(seconds)

  -- Seconds of this day.
  local _seconds=seconds%(60*60*24)

  if seconds<0 then
    return nil
  else
    local hours = string.format("%02.f", math.floor(_seconds/3600))
    local mins  = string.format("%02.f", math.floor(_seconds/60 - (hours*60)))
    local secs  = string.format("%02.f", math.floor(_seconds - hours*3600 - mins *60))
    local days  = string.format("%d", seconds/(60*60*24))
    local clock=hours..":"..mins..":"..secs.."+"..days
    if short then
      if hours=="00" then
        --clock=mins..":"..secs
        clock=hours..":"..mins..":"..secs
      else
        clock=hours..":"..mins..":"..secs
      end
    end
    return clock
  end
end

--- Seconds of today.
-- @return #number Seconds passed since last midnight.
function UTILS.SecondsOfToday()

    -- Time in seconds.
    local time=timer.getAbsTime()

    -- Short format without days since mission start.
    local clock=UTILS.SecondsToClock(time, true)

    -- Time is now the seconds passed since last midnight.
    return UTILS.ClockToSeconds(clock)
end

--- Cound seconds until next midnight.
-- @return #number Seconds to midnight.
function UTILS.SecondsToMidnight()
  return 24*60*60-UTILS.SecondsOfToday()
end

--- Convert clock time from hours, minutes and seconds to seconds.
-- @param #string clock String of clock time. E.g., "06:12:35" or "5:1:30+1". Format is (H)H:(M)M:((S)S)(+D) H=Hours, M=Minutes, S=Seconds, D=Days.
-- @return #number Seconds. Corresponds to what you cet from timer.getAbsTime() function.
function UTILS.ClockToSeconds(clock)

  -- Nil check.
  if clock==nil then
    return nil
  end

  -- Seconds init.
  local seconds=0

  -- Split additional days.
  local dsplit=UTILS.Split(clock, "+")

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

--- Replace illegal characters [<>|/?*:\\] in a string.
-- @param #string Text Input text.
-- @param #string ReplaceBy Replace illegal characters by this character or string. Default underscore "_".
-- @return #string The input text with illegal chars replaced.
function UTILS.ReplaceIllegalCharacters(Text, ReplaceBy)
  ReplaceBy=ReplaceBy or "_"
  local text=Text:gsub("[<>|/?*:\\]", ReplaceBy)
  return text
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

    -- Transform to Gaussian exp(-(x-x0)°/(2*sigma°).
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

--- Calculate the [dot product](https://en.wikipedia.org/wiki/Dot_product) of two 2D vectors. The result is a number.
-- @param DCS#Vec2 a Vector in 2D with x, y components.
-- @param DCS#Vec2 b Vector in 2D with x, y components.
-- @return #number Scalar product of the two vectors a*b.
function UTILS.Vec2Dot(a, b)
  return a.x*b.x + a.y*b.y
end


--- Calculate the [euclidean norm](https://en.wikipedia.org/wiki/Euclidean_distance) (length) of a 3D vector.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @return #number Norm of the vector.
function UTILS.VecNorm(a)
  return math.sqrt(UTILS.VecDot(a, a))
end

--- Calculate the [euclidean norm](https://en.wikipedia.org/wiki/Euclidean_distance) (length) of a 2D vector.
-- @param DCS#Vec2 a Vector in 2D with x, y components.
-- @return #number Norm of the vector.
function UTILS.Vec2Norm(a)
  return math.sqrt(UTILS.Vec2Dot(a, a))
end

--- Calculate the distance between two 2D vectors.
-- @param DCS#Vec2 a Vector in 3D with x, y components.
-- @param DCS#Vec2 b Vector in 3D with x, y components.
-- @return #number Distance between the vectors.
function UTILS.VecDist2D(a, b)

  local c={x=b.x-a.x, y=b.y-a.y}

  local d=math.sqrt(c.x*c.x+c.y*c.y)

  return d
end


--- Calculate the distance between two 3D vectors.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @param DCS#Vec3 b Vector in 3D with x, y, z components.
-- @return #number Distance between the vectors.
function UTILS.VecDist3D(a, b)

  local c={x=b.x-a.x, y=b.y-a.y, z=b.z-a.z}

  local d=math.sqrt(UTILS.VecDot(c, c))

  return d
end

--- Calculate the [cross product](https://en.wikipedia.org/wiki/Cross_product) of two 3D vectors. The result is a 3D vector.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @param DCS#Vec3 b Vector in 3D with x, y, z components.
-- @return DCS#Vec3 Vector
function UTILS.VecCross(a, b)
  return {x=a.y*b.z - a.z*b.y, y=a.z*b.x - a.x*b.z, z=a.x*b.y - a.y*b.x}
end

--- Calculate the difference between two 3D vectors by substracting the x,y,z components from each other.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @param DCS#Vec3 b Vector in 3D with x, y, z components.
-- @return DCS#Vec3 Vector c=a-b with c(i)=a(i)-b(i), i=x,y,z.
function UTILS.VecSubstract(a, b)
  return {x=a.x-b.x, y=a.y-b.y, z=a.z-b.z}
end

--- Calculate the difference between two 2D vectors by substracting the x,y components from each other.
-- @param DCS#Vec2 a Vector in 2D with x, y components.
-- @param DCS#Vec2 b Vector in 2D with x, y components.
-- @return DCS#Vec2 Vector c=a-b with c(i)=a(i)-b(i), i=x,y.
function UTILS.Vec2Substract(a, b)
  return {x=a.x-b.x, y=a.y-b.y}
end

--- Calculate the total vector of two 3D vectors by adding the x,y,z components of each other.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @param DCS#Vec3 b Vector in 3D with x, y, z components.
-- @return DCS#Vec3 Vector c=a+b with c(i)=a(i)+b(i), i=x,y,z.
function UTILS.VecAdd(a, b)
  return {x=a.x+b.x, y=a.y+b.y, z=a.z+b.z}
end

--- Calculate the total vector of two 2D vectors by adding the x,y components of each other.
-- @param DCS#Vec2 a Vector in 2D with x, y components.
-- @param DCS#Vec2 b Vector in 2D with x, y components.
-- @return DCS#Vec2 Vector c=a+b with c(i)=a(i)+b(i), i=x,y.
function UTILS.Vec2Add(a, b)
  return {x=a.x+b.x, y=a.y+b.y}
end

--- Calculate the angle between two 3D vectors.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @param DCS#Vec3 b Vector in 3D with x, y, z components.
-- @return #number Angle alpha between and b in degrees. alpha=acos(a*b)/(|a||b|), (* denotes the dot product).
function UTILS.VecAngle(a, b)

  local cosalpha=UTILS.VecDot(a,b)/(UTILS.VecNorm(a)*UTILS.VecNorm(b))

  local alpha=0
  if cosalpha>=0.9999999999 then  --acos(1) is not defined.
    alpha=0
  elseif cosalpha<=-0.999999999 then --acos(-1) is not defined.
    alpha=math.pi
  else
    alpha=math.acos(cosalpha)
  end

  return math.deg(alpha)
end

--- Calculate "heading" of a 3D vector in the X-Z plane.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @return #number Heading in degrees in [0,360).
function UTILS.VecHdg(a)
  local h=math.deg(math.atan2(a.z, a.x))
  if h<0 then
    h=h+360
  end
  return h
end

--- Calculate "heading" of a 2D vector in the X-Y plane.
-- @param DCS#Vec2 a Vector in "D with x, y components.
-- @return #number Heading in degrees in [0,360).
function UTILS.Vec2Hdg(a)
  local h=math.deg(math.atan2(a.y, a.x))
  if h<0 then
    h=h+360
  end
  return h
end

--- Calculate the difference between two "heading", i.e. angles in [0,360) deg.
-- @param #number h1 Heading one.
-- @param #number h2 Heading two.
-- @return #number Heading difference in degrees.
function UTILS.HdgDiff(h1, h2)

  -- Angle in rad.
  local alpha= math.rad(tonumber(h1))
  local beta = math.rad(tonumber(h2))

  -- Runway vector.
  local v1={x=math.cos(alpha), y=0, z=math.sin(alpha)}
  local v2={x=math.cos(beta),  y=0, z=math.sin(beta)}

  local delta=UTILS.VecAngle(v1, v2)

  return math.abs(delta)
end


--- Translate 3D vector in the 2D (x,z) plane. y-component (usually altitude) unchanged.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @param #number distance The distance to translate.
-- @param #number angle Rotation angle in degrees.
-- @return DCS#Vec3 Vector rotated in the (x,z) plane.
function UTILS.VecTranslate(a, distance, angle)

  local SX = a.x
  local SY = a.z
  local Radians=math.rad(angle or 0)
  local TX=distance*math.cos(Radians)+SX
  local TY=distance*math.sin(Radians)+SY

  return {x=TX, y=a.y, z=TY}
end

--- Translate 2D vector in the 2D (x,z) plane.
-- @param DCS#Vec2 a Vector in 2D with x, y components.
-- @param #number distance The distance to translate.
-- @param #number angle Rotation angle in degrees.
-- @return DCS#Vec2 Translated vector.
function UTILS.Vec2Translate(a, distance, angle)

  local SX = a.x
  local SY = a.y
  local Radians=math.rad(angle or 0)
  local TX=distance*math.cos(Radians)+SX
  local TY=distance*math.sin(Radians)+SY

  return {x=TX, y=TY}
end

--- Rotate 3D vector in the 2D (x,z) plane. y-component (usually altitude) unchanged.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @param #number angle Rotation angle in degrees.
-- @return DCS#Vec3 Vector rotated in the (x,z) plane.
function UTILS.Rotate2D(a, angle)

  local phi=math.rad(angle)

  local x=a.z
  local y=a.x

  local Z=x*math.cos(phi)-y*math.sin(phi)
  local X=x*math.sin(phi)+y*math.cos(phi)
  local Y=a.y

  local A={x=X, y=Y, z=Z}

  return A
end

--- Rotate 2D vector in the 2D (x,z) plane.
-- @param DCS#Vec2 a Vector in 2D with x, y components.
-- @param #number angle Rotation angle in degrees.
-- @return DCS#Vec2 Vector rotated in the (x,y) plane.
function UTILS.Vec2Rotate2D(a, angle)

  local phi=math.rad(angle)

  local x=a.x
  local y=a.y

  local X=x*math.cos(phi)-y*math.sin(phi)
  local Y=x*math.sin(phi)+y*math.cos(phi)

  local A={x=X, y=Y}

  return A
end


--- Converts a TACAN Channel/Mode couple into a frequency in Hz.
-- @param #number TACANChannel The TACAN channel, i.e. the 10 in "10X".
-- @param #string TACANMode The TACAN mode, i.e. the "X" in "10X".
-- @return #number Frequency in Hz or #nil if parameters are invalid.
function UTILS.TACANToFrequency(TACANChannel, TACANMode)

  if type(TACANChannel) ~= "number" then
    return nil -- error in arguments
  end
  if TACANMode ~= "X" and TACANMode ~= "Y" then
    return nil -- error in arguments
  end

-- This code is largely based on ED's code, in DCS World\Scripts\World\Radio\BeaconTypes.lua, line 137.
-- I have no idea what it does but it seems to work
  local A = 1151 -- 'X', channel >= 64
  local B = 64   -- channel >= 64

  if TACANChannel < 64 then
    B = 1
  end

  if TACANMode == 'Y' then
    A = 1025
    if TACANChannel < 64 then
      A = 1088
    end
  else -- 'X'
    if TACANChannel < 64 then
      A = 962
    end
  end

  return (A + TACANChannel - B) * 1000000
end


--- Returns the DCS map/theatre as optained by env.mission.theatre
-- @return #string DCS map name.
function UTILS.GetDCSMap()
  return env.mission.theatre
end

--- Returns the mission date. This is the date the mission **started**.
-- @return #string Mission date in yyyy/mm/dd format.
-- @return #number The year anno domini.
-- @return #number The month.
-- @return #number The day.
function UTILS.GetDCSMissionDate()
  local year=tostring(env.mission.date.Year)
  local month=tostring(env.mission.date.Month)
  local day=tostring(env.mission.date.Day)
  return string.format("%s/%s/%s", year, month, day), tonumber(year), tonumber(month), tonumber(day)
end

--- Returns the day of the mission.
-- @param #number Time (Optional) Abs. time in seconds. Default now, i.e. the value return from timer.getAbsTime().
-- @return #number Day of the mission. Mission starts on day 0.
function UTILS.GetMissionDay(Time)

  Time=Time or timer.getAbsTime()

  local clock=UTILS.SecondsToClock(Time, false)

  local x=tonumber(UTILS.Split(clock, "+")[2])

  return x
end

--- Returns the current day of the year of the mission.
-- @param #number Time (Optional) Abs. time in seconds. Default now, i.e. the value return from timer.getAbsTime().
-- @return #number Current day of year of the mission. For example, January 1st returns 0, January 2nd returns 1 etc.
function UTILS.GetMissionDayOfYear(Time)

  local Date, Year, Month, Day=UTILS.GetDCSMissionDate()

  local d=UTILS.GetMissionDay(Time)

  return UTILS.GetDayOfYear(Year, Month, Day)+d

end

--- Returns the magnetic declination of the map.
-- Returned values for the current maps are:
--
-- * Caucasus +6 (East), year ~ 2011
-- * NTTR +12 (East), year ~ 2011
-- * Normandy -10 (West), year ~ 1944
-- * Persian Gulf +2 (East), year ~ 2011
-- * The Cannel Map -10 (West)
-- * Syria +5 (East)
-- * Mariana Islands +2 (East)
-- @param #string map (Optional) Map for which the declination is returned. Default is from env.mission.theatre
-- @return #number Declination in degrees.
function UTILS.GetMagneticDeclination(map)

  -- Map.
  map=map or UTILS.GetDCSMap()

  local declination=0
  if map==DCSMAP.Caucasus then
    declination=6
  elseif map==DCSMAP.NTTR then
    declination=12
  elseif map==DCSMAP.Normandy then
    declination=-10
  elseif map==DCSMAP.PersianGulf then
    declination=2
  elseif map==DCSMAP.TheChannel then
    declination=-10
  elseif map==DCSMAP.Syria then
    declination=5
  elseif map==DCSMAP.MarianaIslands then
    declination=2
  else
    declination=0
  end

  return declination
end

--- Checks if a file exists or not. This requires **io** to be desanitized.
-- @param #string file File that should be checked.
-- @return #boolean True if the file exists, false if the file does not exist or nil if the io module is not available and the check could not be performed.
function UTILS.FileExists(file)
  if io then
    local f=io.open(file, "r")
    if f~=nil then
      io.close(f)
      return true
    else
      return false
    end
  else
    return nil
  end
end

--- Checks the current memory usage collectgarbage("count"). Info is printed to the DCS log file. Time stamp is the current mission runtime.
-- @param #boolean output If true, print to DCS log file.
-- @return #number Memory usage in kByte.
function UTILS.CheckMemory(output)
  local time=timer.getTime()
  local clock=UTILS.SecondsToClock(time)
  local mem=collectgarbage("count")
  if output then
    env.info(string.format("T=%s  Memory usage %d kByte = %.2f MByte", clock, mem, mem/1024))
  end
  return mem
end


--- Get the coalition name from its numerical ID, e.g. coaliton.side.RED.
-- @param #number Coalition The coalition ID.
-- @return #string The coalition name, i.e. "Neutral", "Red" or "Blue" (or "Unknown").
function UTILS.GetCoalitionName(Coalition)

  if Coalition then
    if Coalition==coalition.side.BLUE then
      return "Blue"
    elseif Coalition==coalition.side.RED then
      return "Red"
    elseif Coalition==coalition.side.NEUTRAL then
      return "Neutral"
    else
      return "Unknown"
    end
  else
    return "Unknown"
  end

end

--- Get the modulation name from its numerical value.
-- @param #number Modulation The modulation enumerator number. Can be either 0 or 1.
-- @return #string The modulation name, i.e. "AM"=0 or "FM"=1. Anything else will return "Unknown".
function UTILS.GetModulationName(Modulation)

  if Modulation then
    if Modulation==0  then
      return "AM"
    elseif Modulation==1  then
      return "FM"
    else
      return "Unknown"
    end
  else
    return "Unknown"
  end

end

--- Get the callsign name from its enumerator value
-- @param #number Callsign The enumerator callsign.
-- @return #string The callsign name or "Ghostrider".
function UTILS.GetCallsignName(Callsign)

  for name, value in pairs(CALLSIGN.Aircraft) do
    if value==Callsign then
      return name
    end
  end

  for name, value in pairs(CALLSIGN.AWACS) do
    if value==Callsign then
      return name
    end
  end

  for name, value in pairs(CALLSIGN.JTAC) do
    if value==Callsign then
      return name
    end
  end

  for name, value in pairs(CALLSIGN.Tanker) do
    if value==Callsign then
      return name
    end
  end

  return "Ghostrider"
end

--- Get the time difference between GMT and local time.
-- @return #number Local time difference in hours compared to GMT. E.g. Dubai is GMT+4 ==> +4 is returned.
function UTILS.GMTToLocalTimeDifference()

  local theatre=UTILS.GetDCSMap()

  if theatre==DCSMAP.Caucasus then
    return 4   -- Caucasus UTC+4 hours
  elseif theatre==DCSMAP.PersianGulf then
    return 4   -- Abu Dhabi UTC+4 hours
  elseif theatre==DCSMAP.NTTR then
    return -8  -- Las Vegas UTC-8 hours
  elseif theatre==DCSMAP.Normandy then
    return 0   -- Calais UTC+1 hour
  elseif theatre==DCSMAP.TheChannel then
    return 2   -- This map currently needs +2
  elseif theatre==DCSMAP.Syria then
    return 3   -- Damascus is UTC+3 hours
  elseif theatre==DCSMAP.MarianaIslands then
    return 10  -- Guam is UTC+10 hours.
  else
    BASE:E(string.format("ERROR: Unknown Map %s in UTILS.GMTToLocal function. Returning 0", tostring(theatre)))
    return 0
  end

end


--- Get the day of the year. Counting starts on 1st of January.
-- @param #number Year The year.
-- @param #number Month The month.
-- @param #number Day The day.
-- @return #number The day of the year.
function UTILS.GetDayOfYear(Year, Month, Day)

  local floor = math.floor

   local n1 = floor(275 * Month / 9)
   local n2 = floor((Month + 9) / 12)
   local n3 = (1 + floor((Year - 4 * floor(Year / 4) + 2) / 3))

   return n1 - (n2 * n3) + Day - 30
end

--- Get sunrise or sun set of a specific day of the year at a specific location.
-- @param #number DayOfYear The day of the year.
-- @param #number Latitude Latitude.
-- @param #number Longitude Longitude.
-- @param #boolean Rising If true, calc sun rise, or sun set otherwise.
-- @param #number Tlocal Local time offset in hours. E.g. +4 for a location which has GMT+4.
-- @return #number Sun rise/set in seconds of the day.
function UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, Rising, Tlocal)

  -- Defaults
  local zenith=90.83
  local latitude=Latitude
  local longitude=Longitude
  local rising=Rising
  local n=DayOfYear
  Tlocal=Tlocal or 0


  -- Short cuts.
  local rad = math.rad
  local deg = math.deg
  local floor = math.floor
  local frac = function(n) return n - floor(n) end
  local cos = function(d) return math.cos(rad(d)) end
  local acos = function(d) return deg(math.acos(d)) end
  local sin = function(d) return math.sin(rad(d)) end
  local asin = function(d) return deg(math.asin(d)) end
  local tan = function(d) return math.tan(rad(d)) end
  local atan = function(d) return deg(math.atan(d)) end

  local function fit_into_range(val, min, max)
     local range = max - min
     local count
     if val < min then
        count = floor((min - val) / range) + 1
        return val + count * range
     elseif val >= max then
        count = floor((val - max) / range) + 1
        return val - count * range
     else
        return val
     end
  end

   -- Convert the longitude to hour value and calculate an approximate time
   local lng_hour = longitude / 15

   local t
   if rising then -- Rising time is desired
      t = n + ((6 - lng_hour) / 24)
   else -- Setting time is desired
      t = n + ((18 - lng_hour) / 24)
   end

   -- Calculate the Sun's mean anomaly
   local M = (0.9856 * t) - 3.289

   -- Calculate the Sun's true longitude
   local L = fit_into_range(M + (1.916 * sin(M)) + (0.020 * sin(2 * M)) + 282.634, 0, 360)

   -- Calculate the Sun's right ascension
   local RA = fit_into_range(atan(0.91764 * tan(L)), 0, 360)

   -- Right ascension value needs to be in the same quadrant as L
   local Lquadrant  = floor(L / 90) * 90
   local RAquadrant = floor(RA / 90) * 90
   RA = RA + Lquadrant - RAquadrant

   -- Right ascension value needs to be converted into hours
   RA = RA / 15

   -- Calculate the Sun's declination
   local sinDec = 0.39782 * sin(L)
   local cosDec = cos(asin(sinDec))

   -- Calculate the Sun's local hour angle
   local cosH = (cos(zenith) - (sinDec * sin(latitude))) / (cosDec * cos(latitude))

   if rising and cosH > 1 then
      return "N/R" -- The sun never rises on this location on the specified date
   elseif cosH < -1 then
      return "N/S" -- The sun never sets on this location on the specified date
   end

   -- Finish calculating H and convert into hours
   local H
   if rising then
      H = 360 - acos(cosH)
   else
      H = acos(cosH)
   end
   H = H / 15

   -- Calculate local mean time of rising/setting
   local T = H + RA - (0.06571 * t) - 6.622

   -- Adjust back to UTC
   local UT = fit_into_range(T - lng_hour +Tlocal, 0, 24)

   return floor(UT)*60*60+frac(UT)*60*60--+Tlocal*60*60
 end

--- Get sun rise of a specific day of the year at a specific location.
-- @param #number Day Day of the year.
-- @param #number Month Month of the year.
-- @param #number Year Year.
-- @param #number Latitude Latitude.
-- @param #number Longitude Longitude.
-- @param #boolean Rising If true, calc sun rise, or sun set otherwise.
-- @param #number Tlocal Local time offset in hours. E.g. +4 for a location which has GMT+4. Default 0.
-- @return #number Sun rise in seconds of the day.
function UTILS.GetSunrise(Day, Month, Year, Latitude, Longitude, Tlocal)

  local DayOfYear=UTILS.GetDayOfYear(Year, Month, Day)

  return UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, true, Tlocal)
end

--- Get sun set of a specific day of the year at a specific location.
-- @param #number Day Day of the year.
-- @param #number Month Month of the year.
-- @param #number Year Year.
-- @param #number Latitude Latitude.
-- @param #number Longitude Longitude.
-- @param #boolean Rising If true, calc sun rise, or sun set otherwise.
-- @param #number Tlocal Local time offset in hours. E.g. +4 for a location which has GMT+4. Default 0.
-- @return #number Sun rise in seconds of the day.
function UTILS.GetSunset(Day, Month, Year, Latitude, Longitude, Tlocal)

  local DayOfYear=UTILS.GetDayOfYear(Year, Month, Day)

  return UTILS.GetSunRiseAndSet(DayOfYear, Latitude, Longitude, false, Tlocal)
end

--- Get OS time. Needs os to be desanitized!
-- @return #number Os time in seconds.
function UTILS.GetOSTime()
  if os then
    return os.clock()
  end

  return nil
end

--- Shuffle a table accoring to Fisher Yeates algorithm
--@param #table t Table to be shuffled.
--@return #table Shuffled table.
function UTILS.ShuffleTable(t)
  if t == nil or type(t) ~= "table" then
    BASE:I("Error in ShuffleTable: Missing or wrong type of Argument")
    return
  end
  math.random()
  math.random()
  math.random()
  local TempTable = {}
  for i = 1, #t do
    local r = math.random(1,#t)
    TempTable[i] = t[r]
    table.remove(t,r)
  end
  return TempTable
end

--- Get a random element of a table.
--@param #table t Table.
--@param #boolean replace If `true`, the drawn element is replaced, i.e. not deleted.
--@return #number Table element.
function UTILS.GetRandomTableElement(t, replace)

  if t == nil or type(t) ~= "table" then
    BASE:I("Error in ShuffleTable: Missing or wrong type of Argument")
    return
  end
  
  math.random()
  math.random()
  math.random()
  
  local r=math.random(#t)
  
  local element=t[r]
  
  if not replace then
    table.remove(t, r)
  end
  
  return element
end

--- (Helicopter) Check if one loading door is open.
--@param #string unit_name Unit name to be checked
--@return #boolean Outcome - true if a (loading door) is open, false if not, nil if none exists.
function UTILS.IsLoadingDoorOpen( unit_name )

  local ret_val = false
  local unit = Unit.getByName(unit_name)
  if unit ~= nil then
      local type_name = unit:getTypeName()

      if type_name == "Mi-8MT" and unit:getDrawArgumentValue(38) == 1 or unit:getDrawArgumentValue(86) == 1 or unit:getDrawArgumentValue(250) < 0 then
          BASE:T(unit_name .. " Cargo doors are open or cargo door not present")
          ret_val =  true
      end

      if type_name == "Mi-24P" and unit:getDrawArgumentValue(38) == 1 or unit:getDrawArgumentValue(86) == 1 then
          BASE:T(unit_name .. " a side door is open")
          ret_val =  true
      end

      if type_name == "UH-1H" and unit:getDrawArgumentValue(43) == 1 or unit:getDrawArgumentValue(44) == 1 then
          BASE:T(unit_name .. " a side door is open ")
          ret_val =  true
      end

      if string.find(type_name, "SA342" ) and unit:getDrawArgumentValue(34) == 1 or unit:getDrawArgumentValue(38) == 1 then
          BASE:T(unit_name .. " front door(s) are open")
          ret_val =  true
      end

      if string.find(type_name, "Hercules") and unit:getDrawArgumentValue(1215) == 1 and unit:getDrawArgumentValue(1216) == 1 then
          BASE:T(unit_name .. " rear doors are open")
          ret_val =  true
      end

      if string.find(type_name, "Hercules") and (unit:getDrawArgumentValue(1220) == 1 or unit:getDrawArgumentValue(1221) == 1) then
          BASE:T(unit_name .. " para doors are open")
          ret_val =  true
      end

      if string.find(type_name, "Hercules") and unit:getDrawArgumentValue(1217) == 1 then
          BASE:T(unit_name .. " side door is open")
          ret_val =  true
      end

      if string.find(type_name, "Bell-47") then -- bell aint got no doors so always ready to load injured soldiers
          BASE:T(unit_name .. " door is open")
          ret_val =  true
      end
      
      if string.find(type_name, "UH-60L") and (unit:getDrawArgumentValue(401) == 1) or (unit:getDrawArgumentValue(402) == 1) then
          BASE:T(unit_name .. " cargo door is open")
          ret_val =  true
      end

      if string.find(type_name, "UH-60L" ) and unit:getDrawArgumentValue(38) == 1 or unit:getDrawArgumentValue(400) == 1 then
          BASE:T(unit_name .. " front door(s) are open")
          ret_val =  true
      end
      
      if string.find(type_name, "AH-64D") then
         BASE:T(unit_name .. " front door(s) are open")
         ret_val =  true -- no doors on this one ;)
      end
      
      if ret_val == false then
          BASE:T(unit_name .. " all doors are closed")
      end
      
      return ret_val

  end -- nil

  return nil
end

--- Function to generate valid FM frequencies in mHz for radio beacons (FM).
-- @return #table Table of frequencies.
function UTILS.GenerateFMFrequencies()
    local FreeFMFrequencies = {}
    for _first = 3, 7 do
        for _second = 0, 5 do
            for _third = 0, 9 do
                local _frequency = ((100 * _first) + (10 * _second) + _third) * 100000 --extra 0 because we didnt bother with 4th digit
                table.insert(FreeFMFrequencies, _frequency)
            end
        end
    end
    return FreeFMFrequencies
end

--- Function to generate valid VHF frequencies in kHz for radio beacons (FM).
-- @return #table VHFrequencies
function UTILS.GenerateVHFrequencies()

  -- known and sorted map-wise NDBs in kHz
  local _skipFrequencies = {
  214,274,291.5,295,297.5,
  300.5,304,307,309.5,311,312,312.5,316,
  320,324,328,329,330,332,336,337,
  342,343,348,351,352,353,358,
  363,365,368,372.5,374,
  380,381,384,385,389,395,396,
  414,420,430,432,435,440,450,455,462,470,485,
  507,515,520,525,528,540,550,560,570,577,580,
  602,625,641,662,670,680,682,690,
  705,720,722,730,735,740,745,750,770,795,
  822,830,862,866,
  905,907,920,935,942,950,995,
  1000,1025,1030,1050,1065,1116,1175,1182,1210
  }

  local FreeVHFFrequencies = {}

    -- first range
  local _start = 200000
  while _start < 400000 do

      -- skip existing NDB frequencies#
      local _found = false
      for _, value in pairs(_skipFrequencies) do
          if value * 1000 == _start then
              _found = true
              break
          end
      end
      if _found == false then
          table.insert(FreeVHFFrequencies, _start)
      end
       _start = _start + 10000
  end

   -- second range
  _start = 400000
  while _start < 850000 do
       -- skip existing NDB frequencies
      local _found = false
      for _, value in pairs(_skipFrequencies) do
          if value * 1000 == _start then
              _found = true
              break
          end
      end
      if _found == false then
          table.insert(FreeVHFFrequencies, _start)
      end
      _start = _start + 10000
  end

  -- third range
  _start = 850000
  while _start <= 999000 do -- adjusted for Gazelle
      -- skip existing NDB frequencies
      local _found = false
      for _, value in pairs(_skipFrequencies) do
          if value * 1000 == _start then
              _found = true
              break
          end
      end
      if _found == false then
          table.insert(FreeVHFFrequencies, _start)
      end
       _start = _start + 50000
  end

  return FreeVHFFrequencies
end

--- Function to generate valid UHF Frequencies in mHz (AM).
-- @return #table UHF Frequencies
function UTILS.GenerateUHFrequencies()

    local FreeUHFFrequencies = {}
    local _start = 220000000

    while _start < 399000000 do
        table.insert(FreeUHFFrequencies, _start)
        _start = _start + 500000
    end

    return FreeUHFFrequencies
end

--- Function to generate valid laser codes for JTAC.
-- @return #table Laser Codes.
function UTILS.GenerateLaserCodes()
    local jtacGeneratedLaserCodes = {}

    -- helper function
    local function ContainsDigit(_number, _numberToFind)
      local _thisNumber = _number
      local _thisDigit = 0
      while _thisNumber ~= 0 do
          _thisDigit = _thisNumber % 10
          _thisNumber = math.floor(_thisNumber / 10)
          if _thisDigit == _numberToFind then
              return true
          end
      end
      return false
    end

    -- generate list of laser codes
    local _code = 1111
    local _count = 1
    while _code < 1777 and _count < 30 do
        while true do
           _code = _code + 1
            if not ContainsDigit(_code, 8)
                    and not ContainsDigit(_code, 9)
                    and not ContainsDigit(_code, 0) then
                table.insert(jtacGeneratedLaserCodes, _code)
                break
            end
        end
        _count = _count + 1
    end
    return jtacGeneratedLaserCodes
end

--- Function to save an object to a file
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file. Existing file will be overwritten.
-- @param #table Data The LUA data structure to save. This will be e.g. a table of text lines with an \\n at the end of each line.
-- @return #boolean outcome True if saving is possible, else false.
function UTILS.SaveToFile(Path,Filename,Data)
  -- Thanks to @FunkyFranky 
  -- Check io module is available.
  if not io then
    BASE:E("ERROR: io not desanitized. Can't save current file.")
    return false
  end
  
  -- Check default path.
  if Path==nil and not lfs then
    BASE:E("WARNING: lfs not desanitized. File will be saved in DCS installation root directory rather than your \"Saved Games\\DCS\" folder.")
  end
  
  -- Set path or default.
  local path = nil
  if lfs then
    path=Path or lfs.writedir()
  end
  
  -- Set file name.
  local filename=Filename
  if path~=nil then
    filename=path.."\\"..filename
  end
  
  -- write
  local f = assert(io.open(filename, "wb"))
  f:write(Data)
  f:close()
  return true
end

--- Function to save an object to a file
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @return #boolean outcome True if reading is possible and successful, else false.
-- @return #table data The data read from the filesystem (table of lines of text). Each line is one single #string!
function UTILS.LoadFromFile(Path,Filename)
  -- Thanks to @FunkyFranky    
  -- Check io module is available.
  if not io then
    BASE:E("ERROR: io not desanitized. Can't save current state.")
    return false
  end
  
  -- Check default path.
  if Path==nil and not lfs then
    BASE:E("WARNING: lfs not desanitized. Loading will look into your DCS installation root directory rather than your \"Saved Games\\DCS\" folder.")
  end
  
  -- Set path or default.
  local path = nil
  if lfs then
    path=Path or lfs.writedir()
  end
  
  -- Set file name.
  local filename=Filename
  if path~=nil then
    filename=path.."\\"..filename
  end
  
  -- Check if file exists.
  local exists=UTILS.CheckFileExists(Path,Filename)
  if not exists then
    BASE:E(string.format("ERROR: File %s does not exist!",filename))
    return false
  end
    
  -- read
  local file=assert(io.open(filename, "rb"))
  local loadeddata = {}
  for line in file:lines() do
      loadeddata[#loadeddata+1] = line
  end
  file:close()
  return true, loadeddata
end

--- Function to check if a file exists.
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @return #boolean outcome True if reading is possible, else false.
function UTILS.CheckFileExists(Path,Filename)
  -- Thanks to @FunkyFranky
  -- Function that check if a file exists.
  local function _fileexists(name)
     local f=io.open(name,"r")
     if f~=nil then
      io.close(f)
      return true
    else
      return false
    end
  end
     
  -- Check io module is available.
  if not io then
    BASE:E("ERROR: io not desanitized. Can't save current state.")
    return false
  end
  
  -- Check default path.
  if Path==nil and not lfs then
    BASE:E("WARNING: lfs not desanitized. Loading will look into your DCS installation root directory rather than your \"Saved Games\\DCS\" folder.")
  end
  
  -- Set path or default.
  local path = nil
  if lfs then
    path=Path or lfs.writedir()
  end
  
  -- Set file name.
  local filename=Filename
  if path~=nil then
    filename=path.."\\"..filename
  end
  
  -- Check if file exists.
  local exists=_fileexists(filename)
  if not exists then
    BASE:E(string.format("ERROR: File %s does not exist!",filename))
    return false
  else
    return true
  end
end

--- Function to save the state of a list of groups found by name
-- @param #table List Table of strings with groupnames
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @return #boolean outcome True if saving is successful, else false.
-- @usage
-- We will go through the list and find the corresponding group and save the current group size (0 when dead).
-- These groups are supposed to be put on the map in the ME and have *not* moved (e.g. stationary SAM sites). 
-- Position is still saved for your usage.
-- The idea is to reduce the number of units when reloading the data again to restart the saved mission.
-- The data will be a simple comma separated list of groupname and size, with one header line.
function UTILS.SaveStationaryListOfGroups(List,Path,Filename)
  local filename = Filename or "StateListofGroups"
  local data = "--Save Stationary List of Groups: "..Filename .."\n"
  for _,_group in pairs (List) do
    local group = GROUP:FindByName(_group) -- Wrapper.Group#GROUP
    if group and group:IsAlive() then
      local units = group:CountAliveUnits()
      local position = group:GetVec3()
      data = string.format("%s%s,%d,%d,%d,%d\n",data,_group,units,position.x,position.y,position.z)
    else
      data = string.format("%s%s,0,0,0,0\n",data,_group)
    end
  end
  -- save the data
  local outcome = UTILS.SaveToFile(Path,Filename,data)
  return outcome
end

--- Function to save the state of a set of Wrapper.Group#GROUP objects.
-- @param Core.Set#SET_BASE Set of objects to save
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @return #boolean outcome True if saving is successful, else false.
-- @usage
-- We will go through the set and find the corresponding group and save the current group size and current position.
-- The idea is to respawn the groups **spawned during an earlier run of the mission** at the given location and reduce 
-- the number of units in the group when reloading the data again to restart the saved mission. Note that *dead* groups 
-- cannot be covered with this.
-- **Note** Do NOT use dashes or hashes in group template names (-,#)!
-- The data will be a simple comma separated list of groupname and size, with one header line.
-- The current task/waypoint/etc cannot be restored. 
function UTILS.SaveSetOfGroups(Set,Path,Filename)
  local filename = Filename or "SetOfGroups"
  local data = "--Save SET of groups: "..Filename .."\n"
  local List = Set:GetSetObjects()
  for _,_group in pairs (List) do
    local group = _group -- Wrapper.Group#GROUP
    if group and group:IsAlive() then
      local name = group:GetName()
      local template = string.gsub(name,"-(.+)$","")
      if string.find(template,"#") then
       template = string.gsub(name,"#(%d+)$","")
      end 
      local units = group:CountAliveUnits()
      local position = group:GetVec3()
      data = string.format("%s%s,%s,%d,%d,%d,%d\n",data,name,template,units,position.x,position.y,position.z)
    end
  end
  -- save the data
  local outcome = UTILS.SaveToFile(Path,Filename,data)
  return outcome
end

--- Function to save the state of a set of Wrapper.Static#STATIC objects.
-- @param Core.Set#SET_BASE Set of objects to save
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @return #boolean outcome True if saving is successful, else false.
-- @usage
-- We will go through the set and find the corresponding static and save the current name and postion when alive.
-- The data will be a simple comma separated list of name and state etc, with one header line.
function UTILS.SaveSetOfStatics(Set,Path,Filename)
  local filename = Filename or "SetOfStatics"
  local data = "--Save SET of statics: "..Filename .."\n"
  local List = Set:GetSetObjects()
  for _,_group in pairs (List) do
    local group = _group -- Wrapper.Static#STATIC
    if group and group:IsAlive() then
      local name = group:GetName()
      local position = group:GetVec3()
      data = string.format("%s%s,%d,%d,%d\n",data,name,position.x,position.y,position.z)
    end
  end
  -- save the data
  local outcome = UTILS.SaveToFile(Path,Filename,data)
  return outcome
end

--- Function to save the state of a list of statics found by name
-- @param #table List Table of strings with statics names
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @return #boolean outcome True if saving is successful, else false.
-- @usage
-- We will go through the list and find the corresponding static and save the current alive state as 1 (0 when dead).
-- Position is saved for your usage. **Note** this works on UNIT-name level.
-- The idea is to reduce the number of units when reloading the data again to restart the saved mission.
-- The data will be a simple comma separated list of name and state etc, with one header line.
function UTILS.SaveStationaryListOfStatics(List,Path,Filename)
  local filename = Filename or "StateListofStatics"
  local data = "--Save Stationary List of Statics: "..Filename .."\n"
  for _,_group in pairs (List) do
    local group = STATIC:FindByName(_group,false) -- Wrapper.Static#STATIC
    if group and group:IsAlive() then
      local position = group:GetVec3()
      data = string.format("%s%s,1,%d,%d,%d\n",data,_group,position.x,position.y,position.z)
    else
      data = string.format("%s%s,0,0,0,0\n",data,_group)
    end
  end
  -- save the data
  local outcome = UTILS.SaveToFile(Path,Filename,data)
  return outcome
end

--- Load back a stationary list of groups from file.
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @param #boolean Reduce If false, existing loaded groups will not be reduced to fit the saved number.
-- @return #table Table of data objects (tables) containing groupname, coordinate and group object. Returns nil when file cannot be read.
function UTILS.LoadStationaryListOfGroups(Path,Filename,Reduce)
  local reduce = true
  if Reduce == false then reduce = false end
  local filename = Filename or "StateListofGroups"
  local datatable = {}
  if UTILS.CheckFileExists(Path,filename) then
    local outcome,loadeddata = UTILS.LoadFromFile(Path,Filename)
    -- remove header
    table.remove(loadeddata, 1)
    for _id,_entry in pairs (loadeddata) do
      local dataset = UTILS.Split(_entry,",")
      -- groupname,units,position.x,position.y,position.z
      local groupname = dataset[1]
      local size = tonumber(dataset[2])
      local posx = tonumber(dataset[3])
      local posy = tonumber(dataset[4])
      local posz = tonumber(dataset[5])
      local coordinate = COORDINATE:NewFromVec3({x=posx, y=posy, z=posz})
      local data = { groupname=groupname, size=size, coordinate=coordinate, group=GROUP:FindByName(groupname) }
      if reduce then
        local actualgroup = GROUP:FindByName(groupname)
        if actualgroup and actualgroup:IsAlive() and actualgroup:CountAliveUnits() > size then
          local reduction = actualgroup:CountAliveUnits() - size
          BASE:I("Reducing groupsize by ".. reduction .. " units!")
          -- reduce existing group
          local units = actualgroup:GetUnits()
          local units2 = UTILS.ShuffleTable(units) -- randomize table
          for i=1,reduction do
            units2[i]:Destroy(false)
          end
        end
      end
      table.insert(datatable,data)
    end 
  else
    return nil
  end
  return datatable
end

--- Load back a SET of groups from file.
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @param #boolean Spawn If set to false, do not re-spawn the groups loaded in location and reduce to size.
-- @return Core.Set#SET_GROUP Set of GROUP objects. 
-- Returns nil when file cannot be read. Returns a table of data entries if Spawn is false: `{ groupname=groupname, size=size, coordinate=coordinate }`
function UTILS.LoadSetOfGroups(Path,Filename,Spawn)
  local spawn = true
  if Spawn == false then spawn = false end
  BASE:I("Spawn = "..tostring(spawn))
  local filename = Filename or "SetOfGroups"
  local setdata = SET_GROUP:New()
  local datatable = {}
  if UTILS.CheckFileExists(Path,filename) then
    local outcome,loadeddata = UTILS.LoadFromFile(Path,Filename)
    -- remove header
    table.remove(loadeddata, 1)
    for _id,_entry in pairs (loadeddata) do
      local dataset = UTILS.Split(_entry,",")
      -- groupname,template,units,position.x,position.y,position.z
      local groupname = dataset[1]
      local template = dataset[2]
      local size = tonumber(dataset[3])
      local posx = tonumber(dataset[4])
      local posy = tonumber(dataset[5])
      local posz = tonumber(dataset[6])
      local coordinate = COORDINATE:NewFromVec3({x=posx, y=posy, z=posz})
      local group=nil
      local data = { groupname=groupname, size=size, coordinate=coordinate }
      table.insert(datatable,data)
      if spawn then
        local group = SPAWN:New(groupname)
          :InitDelayOff()
          :OnSpawnGroup(
            function(spwndgrp)
              setdata:AddObject(spwndgrp)
              local actualsize = spwndgrp:CountAliveUnits()
              if actualsize > size then
                local reduction = actualsize-size
                -- reduce existing group
                local units = spwndgrp:GetUnits()
                local units2 = UTILS.ShuffleTable(units) -- randomize table
                for i=1,reduction do
                  units2[i]:Destroy(false)
                end
              end
            end
          )
          :SpawnFromCoordinate(coordinate)
      end
    end 
  else
    return nil
  end
  if spawn then
    return setdata
  else
   return datatable
  end
end

--- Load back a SET of statics from file.
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @return Core.Set#SET_STATIC Set SET_STATIC containing the static objects.
function UTILS.LoadSetOfStatics(Path,Filename)
  local filename = Filename or "SetOfStatics"
  local datatable = SET_STATIC:New()
  if UTILS.CheckFileExists(Path,filename) then
    local outcome,loadeddata = UTILS.LoadFromFile(Path,Filename)
    -- remove header
    table.remove(loadeddata, 1)
    for _id,_entry in pairs (loadeddata) do
      local dataset = UTILS.Split(_entry,",")
      -- staticname,position.x,position.y,position.z
      local staticname = dataset[1]
      local posx = tonumber(dataset[2])
      local posy = tonumber(dataset[3])
      local posz = tonumber(dataset[4])
      local coordinate = COORDINATE:NewFromVec3({x=posx, y=posy, z=posz})
      datatable:AddObject(STATIC:FindByName(staticname,false))
    end 
  else
    return nil
  end
  return datatable
end

--- Load back a stationary list of statics from file.
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @param #boolean Reduce If false, do not destroy the units with size=0.
-- @return #table Table of data objects (tables) containing staticname, size (0=dead else 1), coordinate and the static object. 
-- Returns nil when file cannot be read.
function UTILS.LoadStationaryListOfStatics(Path,Filename,Reduce)
  local reduce = true
  if Reduce == false then reduce = false end
  local filename = Filename or "StateListofStatics"
  local datatable = {}
  if UTILS.CheckFileExists(Path,filename) then
    local outcome,loadeddata = UTILS.LoadFromFile(Path,Filename)
    -- remove header
    table.remove(loadeddata, 1)
    for _id,_entry in pairs (loadeddata) do
      local dataset = UTILS.Split(_entry,",")
      -- staticname,units(1/0),position.x,position.y,position.z)
      local staticname = dataset[1]
      local size = tonumber(dataset[2])
      local posx = tonumber(dataset[3])
      local posy = tonumber(dataset[4])
      local posz = tonumber(dataset[5])
      local coordinate = COORDINATE:NewFromVec3({x=posx, y=posy, z=posz})
      local data = { staticname=staticname, size=size, coordinate=coordinate, static=STATIC:FindByName(staticname,false) }
      table.insert(datatable,data)
      if size==0 and reduce then
        local static = STATIC:FindByName(staticname,false)
        if static then
          static:Destroy(false)
        end
      end
    end 
  else
    return nil
  end
  return datatable
end
