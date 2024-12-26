--- **Utilities** - Derived utilities taken from the MIST framework, added helpers from the MOOSE community.
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
-- @module Utilities.Utils
-- @image MOOSE.JPG

---
-- @type SMOKECOLOR
-- @field Green
-- @field Red
-- @field White
-- @field Orange
-- @field Blue

SMOKECOLOR = trigger.smokeColor -- #SMOKECOLOR

---
-- @type FLARECOLOR
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

--- DCS map as returned by `env.mission.theatre`.
-- @type DCSMAP
-- @field #string Caucasus Caucasus map.
-- @field #string Normandy Normandy map.
-- @field #string NTTR Nevada Test and Training Range map.
-- @field #string PersianGulf Persian Gulf map.
-- @field #string TheChannel The Channel map.
-- @field #string Syria Syria map.
-- @field #string MarianaIslands Mariana Islands map.
-- @field #string Falklands South Atlantic map.
-- @field #string Sinai Sinai map.
-- @field #string Kola Kola map.
-- @field #string Afghanistan Afghanistan map
-- @field #string Iraq Iraq map
DCSMAP = {
  Caucasus="Caucasus",
  NTTR="Nevada",
  Normandy="Normandy",
  PersianGulf="PersianGulf",
  TheChannel="TheChannel",
  Syria="Syria",
  MarianaIslands="MarianaIslands",
  Falklands="Falklands",
  Sinai="SinaiMap",
  Kola="Kola",
  Afghanistan="Afghanistan",
  Iraq="Iraq"
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
    Navy_One=4,
    Mauler=5,
    Bloodhound=6,
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
  AH64={
    Army_Air = 9,
    Apache = 10,
    Crow = 11,
    Sioux = 12,
    Gatling = 13,
    Gunslinger = 14,
    Hammerhead = 15,
    Bootleg = 16,
    Palehorse = 17,
    Carnivor = 18,
    Saber = 19,
  },
  Kiowa = {
    Anvil = 1,
    Azrael = 2,
    BamBam = 3,
    Blackjack = 4,
    Bootleg = 5,
    BurninStogie = 6,
    Chaos = 7,
    CrazyHorse = 8,
    Crusader = 9,
    Darkhorse = 10,
    Eagle = 11,
    Lighthorse = 12,
    Mustang = 13,
    Outcast = 14,
    Palehorse = 15,
    Pegasus = 16,
    Pistol = 17,
    Roughneck = 18,
    Saber = 19,
    Shamus = 20,
    Spur = 21,
    Stetson = 22,
    Wrath = 23,
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
  if type( className ) ~= 'string' then

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


--- Serialize a given table.
-- @param #table tbl Input table.
-- @return #string Table as a string.
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
          ind_str[#ind_str + 1] = UTILS.BasicSerialize(ind)
          ind_str[#ind_str + 1] = ']='
        end

        local val_str = {}
        if ((type(val) == 'number') or (type(val) == 'boolean')) then
          val_str[#val_str + 1] = tostring(val)
          val_str[#val_str + 1] = ','
          tbl_str[#tbl_str + 1] = table.concat(ind_str)
          tbl_str[#tbl_str + 1] = table.concat(val_str)
      elseif type(val) == 'string' then
          val_str[#val_str + 1] = UTILS.BasicSerialize(val)
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
          env.info('unable to serialize value type ' .. UTILS.BasicSerialize(type(val)) .. ' at index ' .. tostring(ind))
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

--- Serialize a table to a single line string.
-- @param #table tbl table to serialize.
-- @return #string string containing serialized table.
function UTILS._OneLineSerialize(tbl)

  if type(tbl) == 'table' then --function only works for tables!

    local tbl_str = {}

    tbl_str[#tbl_str + 1] = '{ '

    for ind,val in pairs(tbl) do -- serialize its fields
      if type(ind) == "number" then
        tbl_str[#tbl_str + 1] = '['
        tbl_str[#tbl_str + 1] = tostring(ind)
        tbl_str[#tbl_str + 1] = '] = '
      else --must be a string
        tbl_str[#tbl_str + 1] = '['
        tbl_str[#tbl_str + 1] = UTILS.BasicSerialize(ind)
        tbl_str[#tbl_str + 1] = '] = '
      end

      if ((type(val) == 'number') or (type(val) == 'boolean')) then
        tbl_str[#tbl_str + 1] = tostring(val)
        tbl_str[#tbl_str + 1] = ', '
      elseif type(val) == 'string' then
        tbl_str[#tbl_str + 1] = UTILS.BasicSerialize(val)
        tbl_str[#tbl_str + 1] = ', '
      elseif type(val) == 'nil' then -- won't ever happen, right?
        tbl_str[#tbl_str + 1] = 'nil, '
      elseif type(val) == 'table' then
        --tbl_str[#tbl_str + 1] = UTILS.TableShow(tbl,loc,indent,tableshow_tbls)
        --tbl_str[#tbl_str + 1] = ', '   --I think this is right, I just added it
      else
        --log:warn('Unable to serialize value type $1 at index $2', mist.utils.basicSerialize(type(val)), tostring(ind))
      end

    end

      tbl_str[#tbl_str + 1] = '}'
      return table.concat(tbl_str)
    else
      return  UTILS.BasicSerialize(tbl)
  end
end

--- Basic serialize (porting in Slmod's "safestring" basic serialize).
-- @param #string s Table to serialize.
UTILS.BasicSerialize = function(s)
  if s == nil then
    return "\"\""
  else
    if ((type(s) == 'number') or (type(s) == 'boolean') or (type(s) == 'function') or (type(s) == 'userdata') ) then
      return tostring(s)
    elseif type(s) == "table" then
      return UTILS._OneLineSerialize(s)
    elseif type(s) == 'string' then
      s = string.format('(%s)', s)
      return s
    end
  end
end

--- Counts the number of elements in a table.
-- @param #table T Table to count
-- @return #int Number of elements in the table
function UTILS.TableLength(T)
  local count = 0
  for _ in pairs(T or {}) do count = count + 1 end
  return count
end

--- Print a table to log in a nice format
-- @param #table table The table to print
-- @param #number indent Number of indents
-- @param #boolean noprint Don't log but return text
-- @return #string text Text created on the fly of the log output
function UTILS.PrintTableToLog(table, indent, noprint)
  local text = "\n"
  if not table or type(table) ~= "table" then
    env.warning("No table passed!")
    return nil
  end
  if not indent then indent = 0 end
  for k, v in pairs(table) do
    if string.find(k," ") then k='"'..k..'"'end
    if type(v) == "table" and UTILS.TableLength(v) > 0 then
      if not noprint then
        env.info(string.rep("  ", indent) .. tostring(k) .. " = {")
      end
      text = text ..string.rep("  ", indent) .. tostring(k) .. " = {\n"
      text = text .. tostring(UTILS.PrintTableToLog(v, indent + 1)).."\n"
      if not noprint then
        env.info(string.rep("  ", indent) .. "},")
      end
      text = text .. string.rep("  ", indent) .. "},\n"
    elseif type(v) == "function" then
    else
      local value
      if tostring(v) == "true" or tostring(v) == "false" or tonumber(v) ~= nil then
        value=v
      else
        value = '"'..tostring(v)..'"'
      end
      if not noprint then
        env.info(string.rep("  ", indent) .. tostring(k) .. " = " .. tostring(value)..",\n")
      end
      text = text .. string.rep("  ", indent) .. tostring(k) .. " = " .. tostring(value)..",\n"
    end
  end
  return text
end

--- Returns table in a easy readable string representation.
-- @param tbl table to show
-- @param loc
-- @param indent
-- @param tableshow_tbls
-- @return Human readable string representation of given table.
function UTILS.TableShow(tbl, loc, indent, tableshow_tbls)
  tableshow_tbls = tableshow_tbls or {} --create table of tables
  loc = loc or ""
  indent = indent or ""
  if type(tbl) == 'table' then --function only works for tables!
    tableshow_tbls[tbl] = loc

    local tbl_str = {}

    tbl_str[#tbl_str + 1] = indent .. '{\n'

    for ind,val in pairs(tbl) do -- serialize its fields
      if type(ind) == "number" then
        tbl_str[#tbl_str + 1] = indent
        tbl_str[#tbl_str + 1] = loc .. '['
        tbl_str[#tbl_str + 1] = tostring(ind)
        tbl_str[#tbl_str + 1] = '] = '
      else
        tbl_str[#tbl_str + 1] = indent
        tbl_str[#tbl_str + 1] = loc .. '['
        tbl_str[#tbl_str + 1] = UTILS.BasicSerialize(ind)
        tbl_str[#tbl_str + 1] = '] = '
      end

      if ((type(val) == 'number') or (type(val) == 'boolean')) then
        tbl_str[#tbl_str + 1] = tostring(val)
        tbl_str[#tbl_str + 1] = ',\n'
      elseif type(val) == 'string' then
        tbl_str[#tbl_str + 1] = UTILS.BasicSerialize(val)
        tbl_str[#tbl_str + 1] = ',\n'
      elseif type(val) == 'nil' then -- won't ever happen, right?
        tbl_str[#tbl_str + 1] = 'nil,\n'
      elseif type(val) == 'table' then
        if tableshow_tbls[val] then
          tbl_str[#tbl_str + 1] = tostring(val) .. ' already defined: ' .. tableshow_tbls[val] .. ',\n'
        else
          tableshow_tbls[val] = loc ..  '[' .. UTILS.BasicSerialize(ind) .. ']'
          tbl_str[#tbl_str + 1] = tostring(val) .. ' '
          tbl_str[#tbl_str + 1] = UTILS.TableShow(val, loc .. '[' .. UTILS.BasicSerialize(ind).. ']', indent .. '    ', tableshow_tbls)
          tbl_str[#tbl_str + 1] = ',\n'
        end
      elseif type(val) == 'function' then
        if debug and debug.getinfo then
          local fcnname = tostring(val)
          local info = debug.getinfo(val, "S")
          if info.what == "C" then
            tbl_str[#tbl_str + 1] = string.format('%q', fcnname .. ', C function') .. ',\n'
          else
            if (string.sub(info.source, 1, 2) == [[./]]) then
              tbl_str[#tbl_str + 1] = string.format('%q', fcnname .. ', defined in (' .. info.linedefined .. '-' .. info.lastlinedefined .. ')' .. info.source) ..',\n'
            else
              tbl_str[#tbl_str + 1] = string.format('%q', fcnname .. ', defined in (' .. info.linedefined .. '-' .. info.lastlinedefined .. ')') ..',\n'
            end
          end

        else
          tbl_str[#tbl_str + 1] = 'a function,\n'
        end
      else
        tbl_str[#tbl_str + 1] = 'unable to serialize value type ' .. UTILS.BasicSerialize(type(val)) .. ' at index ' .. tostring(ind)
      end
    end

    tbl_str[#tbl_str + 1] = indent .. '}'
    return table.concat(tbl_str)
  end
end

--- Dumps the global table _G.
-- This dumps the global table _G to a file in the DCS\Logs directory.
-- This function requires you to disable script sanitization in $DCS_ROOT\Scripts\MissionScripting.lua to access lfs and io libraries.
-- @param #string fname File name.
function UTILS.Gdump(fname)
  if lfs and io then

    local fdir = lfs.writedir() .. [[Logs\]] .. fname

    local f = io.open(fdir, 'w')

    f:write(UTILS.TableShow(_G))

    f:close()

    env.info(string.format('Wrote debug data to $1', fdir))
  else
    env.error("WARNING: lfs and/or io not de-sanitized - cannot dump _G!")
  end
end

--- Executes the given string.
-- borrowed from Slmod
-- @param #string s string containing LUA code.
-- @return #boolean `true` if successfully executed, `false` otherwise.
function UTILS.DoString(s)
  local f, err = loadstring(s)
  if f then
    return true, f()
  else
    return false, err
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

--- Convert indicated airspeed (IAS) to true airspeed (TAS) for a given altitude above main sea level.
-- The conversion is based on the approximation that TAS is ~2% higher than IAS with every 1000 ft altitude above sea level.
-- @param #number ias Indicated air speed in any unit (m/s, km/h, knots, ...)
-- @param #number altitude Altitude above main sea level in meters.
-- @param #number oatcorr (Optional) Outside air temperature correction factor. Default 0.017.
-- @return #number True airspeed in the same unit the IAS has been given.
UTILS.IasToTas = function( ias, altitude, oatcorr )
  oatcorr=oatcorr or 0.017
  local tas=ias + (ias * oatcorr * UTILS.MetersToFeet(altitude) / 1000)
  return tas
end

--- Convert true airspeed (TAS) to indicated airspeed (IAS) for a given altitude above main sea level.
-- The conversion is based on the approximation that TAS is ~2% higher than IAS with every 1000 ft altitude above sea level.
-- @param #number tas True air speed in any unit (m/s, km/h, knots, ...)
-- @param #number altitude Altitude above main sea level in meters.
-- @param #number oatcorr (Optional) Outside air temperature correction factor. Default 0.017.
-- @return #number Indicated airspeed in the same unit the TAS has been given.
UTILS.TasToIas = function( tas, altitude, oatcorr )
  oatcorr=oatcorr or 0.017
  local ias=tas/(1+oatcorr*UTILS.MetersToFeet(altitude)/1000)
  return ias
end


--- Convert knots to altitude corrected KIAS, e.g. for tankers.
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

--[[acc:
in DM: decimal point of minutes.
In DMS: decimal point of seconds.
position after the decimal of the least significant digit:
So:
42.32 - acc of 2.
]]
UTILS.tostringLLM2KData = function( lat, lon, acc)

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

  -- degrees, decimal minutes.
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
  return latHemi..string.format('%02d:', latDeg) .. string.format(minFrmtStr, latMin), lonHemi..string.format('%02d:', lonDeg) .. string.format(minFrmtStr, lonMin)

end

-- acc- the accuracy of each easting/northing.  0, 1, 2, 3, 4, or 5.
UTILS.tostringMGRS = function(MGRS, acc) --R2.1

  if acc <= 0 then
    return MGRS.UTMZone .. ' ' .. MGRS.MGRSDigraph
  else

    if acc > 5 then acc = 5 end

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

--- Porting in Slmod's dostring - execute a string as LUA code with error handling.
-- @param #string s The code as string to be executed
-- @return #boolean success If true, code was successfully executed, else false
-- @return #string Outcome Code outcome if successful or error string if not successful
function UTILS.DoString( s )
  local f, err = loadstring( s )
  if f then
    return true, f()
  else
    return false, err
  end
end

--- Here is a customized version of pairs, which I called spairs because it iterates over the table in a sorted order.
-- @param #table t The table
-- @param #string order (Optional) The sorting function
-- @return #string key The index key
-- @return #string value The value at the indexed key
-- @usage
--            for key,value in UTILS.spairs(mytable) do
--                -- your code here
--            end
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


--- Here is a customized version of pairs, which I called kpairs because it iterates over the table in a sorted order, based on a function that will determine the keys as reference first.
-- @param #table t The table
-- @param #string getkey The function to determine the keys for sorting
-- @param #string order (Optional) The sorting function itself
-- @return #string key The index key
-- @return #string value The value at the indexed key
-- @usage
--            for key,value in UTILS.kpairs(mytable, getkeyfunc) do
--                -- your code here
--            end
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

--- Here is a customized version of pairs, which I called rpairs because it iterates over the table in a random order.
-- @param #table t The table
-- @return #string key The index key
-- @return #string value The value at the indexed key
-- @usage
--            for key,value in UTILS.rpairs(mytable) do
--                -- your code here
--            end
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
    if MarkID then
      trigger.action.removeMark(MarkID)
    end
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

--- Split string at separators. C.f. [split-string-in-lua](http://stackoverflow.com/questions/1426954/split-string-in-lua).
-- @param #string str Sting to split.
-- @param #string sep Separator for split.
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
  local seconds = tonumber(seconds) or 0

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
-- @param DCS#Vec2 a Vector in 2D with x, y components.
-- @param DCS#Vec2 b Vector in 2D with x, y components.
-- @return #number Distance between the vectors.
function UTILS.VecDist2D(a, b)

  local d = math.huge

  if (not a) or (not b) then return d end

  local c={x=b.x-a.x, y=b.y-a.y}

  d=math.sqrt(c.x*c.x+c.y*c.y)

  return d
end


--- Calculate the distance between two 3D vectors.
-- @param DCS#Vec3 a Vector in 3D with x, y, z components.
-- @param DCS#Vec3 b Vector in 3D with x, y, z components.
-- @return #number Distance between the vectors.
function UTILS.VecDist3D(a, b)


  local d = math.huge

  if (not a) or (not b) then return d end

  local c={x=b.x-a.x, y=b.y-a.y, z=b.z-a.z}

  d=math.sqrt(UTILS.VecDot(c, c))

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

--- Substract is not a word, don't want to rename the original function because it's been around since forever
function UTILS.VecSubtract(a, b)
  return UTILS.VecSubstract(a, b)
end

--- Calculate the difference between two 2D vectors by substracting the x,y components from each other.
-- @param DCS#Vec2 a Vector in 2D with x, y components.
-- @param DCS#Vec2 b Vector in 2D with x, y components.
-- @return DCS#Vec2 Vector c=a-b with c(i)=a(i)-b(i), i=x,y.
function UTILS.Vec2Substract(a, b)
  return {x=a.x-b.x, y=a.y-b.y}
end

--- Substract is not a word, don't want to rename the original function because it's been around since forever
function UTILS.Vec2Subtract(a, b)
  return UTILS.Vec2Substract(a, b)
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
-- @param DCS#Vec2 a Vector in 2D with x, y components.
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

--- Returns the heading from one vec3 to another vec3.
-- @param DCS#Vec3 a From vec3.
-- @param DCS#Vec3 b To vec3.
-- @return #number Heading in degrees.
function UTILS.HdgTo(a, b)
  local dz=b.z-a.z
  local dx=b.x-a.x
  local heading=math.deg(math.atan2(dz, dx))
  if heading < 0 then
    heading = 360 + heading
  end
  return heading
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


--- Returns the DCS map/theatre as optained by `env.mission.theatre`.
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
-- * Falklands +12 (East) - note there's a LOT of deviation across the map, as we're closer to the South Pole
-- * Sinai +4.8 (East)
-- * Kola +15 (East) - note there is a lot of deviation across the map (-1° to +24°), as we are close to the North pole
-- * Afghanistan +3 (East) - actually +3.6 (NW) to +2.3 (SE)
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
  elseif map==DCSMAP.Falklands then
    declination=12
  elseif map==DCSMAP.Sinai then
    declination=4.8
  elseif map==DCSMAP.Kola then
    declination=15
  elseif map==DCSMAP.Afghanistan then
    declination=3
  elseif map==DCSMAP.Iraq then
    declination=4.4
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


--- Get the coalition name from its numerical ID, e.g. coalition.side.RED.
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

--- Get the enemy coalition for a given coalition.
-- @param #number Coalition The coalition ID.
-- @param #boolean Neutral Include neutral as enemy.
-- @return #table Enemy coalition table.
function UTILS.GetCoalitionEnemy(Coalition, Neutral)

  local Coalitions={}
  if Coalition then
    if Coalition==coalition.side.RED then
      Coalitions={coalition.side.BLUE}
    elseif Coalition==coalition.side.BLUE then
      Coalitions={coalition.side.RED}
    elseif Coalition==coalition.side.NEUTRAL then
      Coalitions={coalition.side.RED, coalition.side.BLUE}
    end
  end

  if Neutral then
    table.insert(Coalitions, coalition.side.NEUTRAL)
  end

  return Coalitions
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

--- Get the NATO reporting name of a unit type name
-- @param #number Typename The type name.
-- @return #string The Reporting name or "Bogey".
function UTILS.GetReportingName(Typename)

  local typename = string.lower(Typename)

  for name, value in pairs(ENUMS.ReportingName.NATO) do
    local svalue = string.lower(value)
    if string.find(typename,svalue,1,true) then
      return name
    end
  end

  return "Bogey"
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

  for name, value in pairs(CALLSIGN.B1B) do
    if value==Callsign then
      return name
    end
  end

  for name, value in pairs(CALLSIGN.B52) do
    if value==Callsign then
      return name
    end
  end

  for name, value in pairs(CALLSIGN.F15E) do
    if value==Callsign then
      return name
    end
  end

  for name, value in pairs(CALLSIGN.F16) do
    if value==Callsign then
      return name
    end
  end

  for name, value in pairs(CALLSIGN.F18) do
    if value==Callsign then
      return name
    end
  end

  for name, value in pairs(CALLSIGN.FARP) do
    if value==Callsign then
      return name
    end
  end

  for name, value in pairs(CALLSIGN.TransportAircraft) do
    if value==Callsign then
      return name
    end
  end
  
  for name, value in pairs(CALLSIGN.AH64) do
    if value==Callsign then
      return name
    end
  end
  
  for name, value in pairs(CALLSIGN.Kiowa) do
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
  elseif theatre==DCSMAP.Falklands then
    return -3  -- Fireland is UTC-3 hours.
  elseif theatre==DCSMAP.Sinai then
    return 2   -- Currently map is +2 but should be +3 (DCS bug?)
  elseif theatre==DCSMAP.Kola then
    return 3   -- Currently map is +2 but should be +3 (DCS bug?)
  elseif theatre==DCSMAP.Afghanistan then
    return 4.5   -- UTC +4:30
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
      return "N/S" -- The sun never rises on this location on the specified date
   elseif cosH < -1 then
      return "N/R" -- The sun never sets on this location on the specified date
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
    local ts = 0
    local t = os.date("*t")
    local s = t.sec
    local m = t.min * 60
    local h = t.hour * 3600
    ts = s+m+h
    return ts
  else
    return nil
  end
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

  local unit = Unit.getByName(unit_name)

  if unit ~= nil then
      local type_name = unit:getTypeName()
      BASE:T("TypeName = ".. type_name)

      if type_name == "Mi-8MT" and (unit:getDrawArgumentValue(38) == 1 or unit:getDrawArgumentValue(86) == 1 or unit:getDrawArgumentValue(250) < 0) then
          BASE:T(unit_name .. " Cargo doors are open or cargo door not present")
          return true
      end

      if type_name == "Mi-24P" and (unit:getDrawArgumentValue(38) == 1 or unit:getDrawArgumentValue(86) == 1) then
          BASE:T(unit_name .. " a side door is open")
          return true
      end

      if type_name == "UH-1H" and (unit:getDrawArgumentValue(43) == 1 or unit:getDrawArgumentValue(44) == 1) then
          BASE:T(unit_name .. " a side door is open ")
          return true
      end

      if string.find(type_name, "SA342" ) and (unit:getDrawArgumentValue(34) == 1) then
          BASE:T(unit_name .. " front door(s) are open or doors removed")
          return true
      end

      if string.find(type_name, "Hercules") and (unit:getDrawArgumentValue(1215) == 1 and unit:getDrawArgumentValue(1216) == 1) then
          BASE:T(unit_name .. " rear doors are open")
          return true
      end

      if string.find(type_name, "Hercules") and (unit:getDrawArgumentValue(1220) == 1 or unit:getDrawArgumentValue(1221) == 1) then
          BASE:T(unit_name .. " para doors are open")
          return true
      end

      if string.find(type_name, "Hercules") and (unit:getDrawArgumentValue(1217) == 1) then
          BASE:T(unit_name .. " side door is open")
          return true
      end

      if type_name == "Bell-47" then -- bell aint got no doors so always ready to load injured soldiers
          BASE:T(unit_name .. " door is open")
          return true
      end

      if type_name == "UH-60L" and (unit:getDrawArgumentValue(401) == 1 or unit:getDrawArgumentValue(402) == 1) then
          BASE:T(unit_name .. " cargo door is open")
          return true
      end

      if type_name ==  "UH-60L" and (unit:getDrawArgumentValue(38) > 0 or unit:getDrawArgumentValue(400) == 1 ) then
          BASE:T(unit_name .. " front door(s) are open")
          return true
      end

      if type_name == "AH-64D_BLK_II" then
         BASE:T(unit_name .. " front door(s) are open")
         return true -- no doors on this one ;)
      end

      if type_name == "Bronco-OV-10A" then
         BASE:T(unit_name .. " front door(s) are open")
         return true -- no doors on this one ;)
      end

      if type_name == "MH-60R" and (unit:getDrawArgumentValue(403) > 0 or unit:getDrawArgumentValue(403) == -1) then
        BASE:T(unit_name .. " cargo door is open")
        return true
      end

      if type_name == "OH58D" then
        BASE:T(unit_name .. " front door(s) are open")
        return true -- no doors on this one ;)
      end

      if type_name == "CH-47Fbl1" and (unit:getDrawArgumentValue(86) > 0.5) then
        BASE:T(unit_name .. " rear cargo door is open")
        return true
      end

      return false

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
  214,243,264,273,274,288,291.5,295,297.5,
  300.5,304,305,307,309.5,310,311,312,312.5,316,317,
  320,323,324,325,326,328,329,330,332,335,336,337,
  340,342,343,346,348,351,352,353,358,
  360,363,364,365,368,372.5,373,374,
  380,381,384,385,387,389,391,395,396,399,
  403,404,410,412,414,418,420,423,
  430,432,435,440,445,
  450,455,462,470,485,490,
  507,515,520,525,528,540,550,560,563,570,577,580,595,
  602,625,641,662,670,680,682,690,
  705,720,722,730,735,740,745,750,770,795,
  822,830,862,866,
  905,907,920,935,942,950,995,
  1000,1025,1030,1050,1065,1116,1175,1182,1210,1215
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

--- Function to generate valid UHF Frequencies in mHz (AM). Can be between 220 and 399 mHz. 243 is auto-excluded.
-- @param Start (Optional) Avoid frequencies between Start and End in mHz, e.g. 244
-- @param End (Optional) Avoid frequencies between Start and End in mHz, e.g. 320
-- @return #table UHF Frequencies
function UTILS.GenerateUHFrequencies(Start,End)

    local FreeUHFFrequencies = {}
    local _start = 220000000

    if not Start then
      while _start < 399000000 do
      if _start ~= 243000000 then
        table.insert(FreeUHFFrequencies, _start)
      end
          _start = _start + 500000
      end
    else
      local myend = End*1000000 or 399000000
      local mystart = Start*1000000 or 220000000

      while _start < 399000000 do
      if _start ~= 243000000 and (_start < mystart or _start > myend) then
        print(_start)
        table.insert(FreeUHFFrequencies, _start)
      end
          _start = _start + 500000
      end

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

--- Ensure the passed object is a table.
-- @param #table Object The object that should be a table.
-- @param #boolean ReturnNil If `true`, return `#nil` if `Object` is nil. Otherwise an empty table `{}` is returned.
-- @return #table The object that now certainly *is* a table.
function UTILS.EnsureTable(Object, ReturnNil)

  if Object then
    if type(Object)~="table" then
      Object={Object}
    end
  else
    if ReturnNil then
      return nil
    else
      Object={}
    end

  end

  return Object
end

--- Function to save an object to a file
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file. Existing file will be overwritten.
-- @param #string Data The data structure to save. This will be e.g. a string of text lines with an \\n at the end of each line.
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

--- Function to load an object from a file.
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
    BASE:I(string.format("ERROR: File %s does not exist!",filename))
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
    BASE:E("ERROR: io not desanitized.")
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

--- Function to obtain a table of typenames from the group given with the number of units of the same type in the group.
-- @param Wrapper.Group#GROUP Group The group to list
-- @return #table Table of typnames and typename counts, e.g. `{["KAMAZ Truck"]=3,["ATZ-5"]=1}`
function UTILS.GetCountPerTypeName(Group)
  local units = Group:GetUnits()
  local TypeNameTable = {}
  for _,_unt in pairs (units) do
    local unit = _unt -- Wrapper.Unit#UNIT
    local typen = unit:GetTypeName()
    if not TypeNameTable[typen] then
      TypeNameTable[typen] = 1
    else
      TypeNameTable[typen] = TypeNameTable[typen] + 1
    end
  end
  return TypeNameTable
end

--- Function to save the state of a list of groups found by name
-- @param #table List Table of strings with groupnames
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @param #boolean Structured Append the data with a list of typenames in the group plus their count.
-- @return #boolean outcome True if saving is successful, else false.
-- @usage
-- We will go through the list and find the corresponding group and save the current group size (0 when dead).
-- These groups are supposed to be put on the map in the ME and have *not* moved (e.g. stationary SAM sites).
-- Position is still saved for your usage.
-- The idea is to reduce the number of units when reloading the data again to restart the saved mission.
-- The data will be a simple comma separated list of groupname and size, with one header line.
function UTILS.SaveStationaryListOfGroups(List,Path,Filename,Structured)
  local filename = Filename or "StateListofGroups"
  local data = "--Save Stationary List of Groups: "..Filename .."\n"
  for _,_group in pairs (List) do
    local group = GROUP:FindByName(_group) -- Wrapper.Group#GROUP
    if group and group:IsAlive() then
      local units = group:CountAliveUnits()
      local position = group:GetVec3()
      if Structured then
        local structure = UTILS.GetCountPerTypeName(group)
        local strucdata =  ""
        for typen,anzahl in pairs (structure) do
          strucdata = strucdata .. typen .. "=="..anzahl..";"
        end
        data = string.format("%s%s,%d,%d,%d,%d,%s\n",data,_group,units,position.x,position.y,position.z,strucdata)
      else
        data = string.format("%s%s,%d,%d,%d,%d\n",data,_group,units,position.x,position.y,position.z)
      end
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
-- @param #boolean Structured Append the data with a list of typenames in the group plus their count.
-- @return #boolean outcome True if saving is successful, else false.
-- @usage
-- We will go through the set and find the corresponding group and save the current group size and current position.
-- The idea is to respawn the groups **spawned during an earlier run of the mission** at the given location and reduce
-- the number of units in the group when reloading the data again to restart the saved mission. Note that *dead* groups
-- cannot be covered with this.
-- **Note** Do NOT use dashes or hashes in group template names (-,#)!
-- The data will be a simple comma separated list of groupname and size, with one header line.
-- The current task/waypoint/etc cannot be restored.
function UTILS.SaveSetOfGroups(Set,Path,Filename,Structured)
  local filename = Filename or "SetOfGroups"
  local data = "--Save SET of groups: "..Filename .."\n"
  local List = Set:GetSetObjects()
  for _,_group in pairs (List) do
    local group = _group -- Wrapper.Group#GROUP
    if group and group:IsAlive() then
      local name = group:GetName()
      local template = string.gsub(name,"-(.+)$","")
      if string.find(name,"AID") then
        template = string.gsub(name,"(.AID.%d+$","")
      end
      if string.find(template,"#") then
       template = string.gsub(name,"#(%d+)$","")
      end
      local units = group:CountAliveUnits()
      local position = group:GetVec3()
      if Structured then
        local structure = UTILS.GetCountPerTypeName(group)
        local strucdata =  ""
        for typen,anzahl in pairs (structure) do
          strucdata = strucdata .. typen .. "=="..anzahl..";"
        end
        data = string.format("%s%s,%s,%d,%d,%d,%d,%s\n",data,name,template,units,position.x,position.y,position.z,strucdata)
      else
        data = string.format("%s%s,%s,%d,%d,%d,%d\n",data,name,template,units,position.x,position.y,position.z)
      end
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
-- @param #boolean Structured (Optional, needs Reduce = true) If true, and the data has been saved as structure before, remove the correct unit types as per the saved list.
-- @param #boolean Cinematic (Optional, needs Structured = true) If true, place a fire/smoke effect on the dead static position.
-- @param #number Effect (Optional for Cinematic) What effect to use. Defaults to a random effect. Smoke presets are: 1=small smoke and fire, 2=medium smoke and fire, 3=large smoke and fire, 4=huge smoke and fire, 5=small smoke, 6=medium smoke, 7=large smoke, 8=huge smoke.
-- @param #number Density (Optional for Cinematic) What smoke density to use, can be 0 to 1. Defaults to 0.5.
-- @return #table Table of data objects (tables) containing groupname, coordinate and group object. Returns nil when file cannot be read.
-- @return #table When using Cinematic: table of names of smoke and fire objects, so they can be extinguished with `COORDINATE.StopBigSmokeAndFire( name )`
function UTILS.LoadStationaryListOfGroups(Path,Filename,Reduce,Structured,Cinematic,Effect,Density)

  local fires = {}

  local function Smokers(name,coord,effect,density)
    local eff = math.random(8)
    if type(effect) == "number" then eff = effect end
    coord:BigSmokeAndFire(eff,density,name)
    table.insert(fires,name)
  end

  local function Cruncher(group,typename,anzahl)
    local units = group:GetUnits()
    local reduced = 0
    for _,_unit in pairs (units) do
      local typo = _unit:GetTypeName()
      if typename == typo then
        if Cinematic then
          local coordinate = _unit:GetCoordinate()
          local name = _unit:GetName()
          Smokers(name,coordinate,Effect,Density)
        end
        _unit:Destroy(false)
        reduced = reduced + 1
        if reduced == anzahl then break end
      end
    end
  end

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
      local structure = dataset[6]
      --BASE:I({structure})
      local coordinate = COORDINATE:NewFromVec3({x=posx, y=posy, z=posz})
      local data = { groupname=groupname, size=size, coordinate=coordinate, group=GROUP:FindByName(groupname) }
      if reduce then
        local actualgroup = GROUP:FindByName(groupname)
        if actualgroup and actualgroup:IsAlive() and actualgroup:CountAliveUnits() > size then
          if Structured and structure then
            --BASE:I("Reducing group structure!")
            local loadedstructure = {}
            local strcset = UTILS.Split(structure,";")
            for _,_data in pairs(strcset) do
              local datasplit = UTILS.Split(_data,"==")
              loadedstructure[datasplit[1]] = tonumber(datasplit[2])
            end
            --BASE:I({loadedstructure})
            local originalstructure = UTILS.GetCountPerTypeName(actualgroup)
            --BASE:I({originalstructure})
            for _name,_number in pairs(originalstructure) do
              local loadednumber = 0
              if loadedstructure[_name] then
                loadednumber = loadedstructure[_name]
              end
              local reduce = false
              if loadednumber < _number then reduce = true end

              --BASE:I(string.format("Looking at: %s | Original number: %d | Loaded number: %d | Reduce: %s",_name,_number,loadednumber,tostring(reduce)))

              if reduce then
                Cruncher(actualgroup,_name,_number-loadednumber)
              end

            end
          else
            local reduction = actualgroup:CountAliveUnits() - size
            --BASE:I("Reducing groupsize by ".. reduction .. " units!")
            -- reduce existing group
            local units = actualgroup:GetUnits()
            local units2 = UTILS.ShuffleTable(units) -- randomize table
            for i=1,reduction do
              units2[i]:Destroy(false)
            end
          end
        end
      end
      table.insert(datatable,data)
    end
  else
    return nil
  end
  return datatable,fires
end

--- Load back a SET of groups from file.
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @param #boolean Spawn If set to false, do not re-spawn the groups loaded in location and reduce to size.
-- @param #boolean Structured (Optional, needs Spawn=true)If true, and the data has been saved as structure before, remove the correct unit types as per the saved list.
-- @param #boolean Cinematic (Optional, needs Structured=true) If true, place a fire/smoke effect on the dead static position.
-- @param #number Effect (Optional for Cinematic) What effect to use. Defaults to a random effect. Smoke presets are: 1=small smoke and fire, 2=medium smoke and fire, 3=large smoke and fire, 4=huge smoke and fire, 5=small smoke, 6=medium smoke, 7=large smoke, 8=huge smoke.
-- @param #number Density (Optional for Cinematic) What smoke density to use, can be 0 to 1. Defaults to 0.5.
-- @return Core.Set#SET_GROUP Set of GROUP objects.
-- Returns nil when file cannot be read. Returns a table of data entries if Spawn is false: `{ groupname=groupname, size=size, coordinate=coordinate, template=template }`
-- @return #table When using Cinematic: table of names of smoke and fire objects, so they can be extinguished with `COORDINATE.StopBigSmokeAndFire( name )`
function UTILS.LoadSetOfGroups(Path,Filename,Spawn,Structured,Cinematic,Effect,Density)

  local fires = {}
  local usedtemplates = {}
  local spawn = true
  if Spawn == false then spawn = false end
  local filename = Filename or "SetOfGroups"
  local setdata = SET_GROUP:New()
  local datatable = {}

  local function Smokers(name,coord,effect,density)
    local eff = math.random(8)
    if type(effect) == "number" then eff = effect end
    coord:BigSmokeAndFire(eff,density,name)
    table.insert(fires,name)
  end

  local function Cruncher(group,typename,anzahl)
    local units = group:GetUnits()
    local reduced = 0
    for _,_unit in pairs (units) do
      local typo = _unit:GetTypeName()
      if typename == typo then
        if Cinematic then
          local coordinate = _unit:GetCoordinate()
          local name = _unit:GetName()
          Smokers(name,coordinate,Effect,Density)
        end
        _unit:Destroy(false)
        reduced = reduced + 1
        if reduced == anzahl then break end
      end
    end
  end

  local function PostSpawn(args)
    local spwndgrp = args[1]
    local size = args[2]
    local structure = args[3]

    setdata:AddObject(spwndgrp)
    local actualsize = spwndgrp:CountAliveUnits()
    if actualsize > size then
      if Structured and structure then

        local loadedstructure = {}
        local strcset = UTILS.Split(structure,";")
        for _,_data in pairs(strcset) do
          local datasplit = UTILS.Split(_data,"==")
          loadedstructure[datasplit[1]] = tonumber(datasplit[2])
        end

        local originalstructure = UTILS.GetCountPerTypeName(spwndgrp)

        for _name,_number in pairs(originalstructure) do
          local loadednumber = 0
          if loadedstructure[_name] then
            loadednumber = loadedstructure[_name]
          end
          local reduce = false
          if loadednumber < _number then reduce = true end

          if reduce then
            Cruncher(spwndgrp,_name,_number-loadednumber)
          end

        end
      else
        local reduction = actualsize-size
        -- reduce existing group
        local units = spwndgrp:GetUnits()
        local units2 = UTILS.ShuffleTable(units) -- randomize table
        for i=1,reduction do
          units2[i]:Destroy(false)
        end
      end
    end
  end

  local function MultiUse(Data)
    local template = Data.template
    if template and usedtemplates[template] and usedtemplates[template].used and usedtemplates[template].used > 1 then
      -- multispawn
      if not usedtemplates[template].done then
        local spwnd = 0
        local spawngrp = SPAWN:New(template)
        spawngrp:InitLimit(0,usedtemplates[template].used)
        for _,_entry in pairs(usedtemplates[template].data) do
          spwnd = spwnd + 1
          local sgrp=spawngrp:SpawnFromCoordinate(_entry.coordinate,spwnd)
          BASE:ScheduleOnce(0.5,PostSpawn,{sgrp,_entry.size,_entry.structure})
        end
        usedtemplates[template].done = true
      end
      return true
    else
      return false
    end
  end

  --BASE:I("Spawn = "..tostring(spawn))
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
      local structure = dataset[7]
      local coordinate = COORDINATE:NewFromVec3({x=posx, y=posy, z=posz})
      local group=nil
      if size > 0 then
        local data = { groupname=groupname, size=size, coordinate=coordinate, template=template, structure=structure }
        table.insert(datatable,data)
        if usedtemplates[template] then
          usedtemplates[template].used = usedtemplates[template].used + 1
          table.insert(usedtemplates[template].data,data)
        else
          usedtemplates[template] = {
              data = {},
              used = 1,
              done = false,
            }
          table.insert(usedtemplates[template].data,data)
        end
      end
    end
    for _id,_entry in pairs (datatable) do
      if spawn and not MultiUse(_entry) and _entry.size > 0 then
        local group = SPAWN:New(_entry.template)
        local sgrp=group:SpawnFromCoordinate(_entry.coordinate)
        BASE:ScheduleOnce(0.5,PostSpawn,{sgrp,_entry.size,_entry.structure})
      end
    end
  else
    return nil
  end
  if spawn then
    return setdata,fires
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
      local staticname = dataset[1]
      local StaticObject = STATIC:FindByName(staticname,false)
      if StaticObject then
        datatable:AddObject(StaticObject)
      end
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
-- @param #boolean Dead (Optional, needs Reduce = true) If Dead is true, re-spawn the dead object as dead and do not just delete it.
-- @param #boolean Cinematic (Optional, needs Dead = true) If true, place a fire/smoke effect on the dead static position.
-- @param #number Effect (Optional for Cinematic) What effect to use. Defaults to a random effect. Smoke presets are: 1=small smoke and fire, 2=medium smoke and fire, 3=large smoke and fire, 4=huge smoke and fire, 5=small smoke, 6=medium smoke, 7=large smoke, 8=huge smoke.
-- @param #number Density (Optional for Cinematic) What smoke density to use, can be 0 to 1. Defaults to 0.5.
-- @return #table Table of data objects (tables) containing staticname, size (0=dead else 1), coordinate and the static object. Dead objects will have coordinate points `{x=0,y=0,z=0}`
-- @return #table When using Cinematic: table of names of smoke and fire objects, so they can be extinguished with `COORDINATE.StopBigSmokeAndFire( name )`
-- Returns nil when file cannot be read.
function UTILS.LoadStationaryListOfStatics(Path,Filename,Reduce,Dead,Cinematic,Effect,Density)
  local fires = {}
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
          if Dead then
            local deadobject = SPAWNSTATIC:NewFromStatic(staticname,static:GetCountry())
            deadobject:InitDead(true)
            local heading = static:GetHeading()
            local coord = static:GetCoordinate()
            static:Destroy(false)
            deadobject:SpawnFromCoordinate(coord,heading,staticname)
            if Cinematic then
              local effect = math.random(8)
              if type(Effect) == "number" then
                effect = Effect
              end
              coord:BigSmokeAndFire(effect,Density,staticname)
              table.insert(fires,staticname)
            end
          else
            static:Destroy(false)
          end
        end
      end
    end
  else
    return nil
  end
  return datatable,fires
end

--- Heading Degrees (0-360) to Cardinal
-- @param #number Heading The heading
-- @return #string Cardinal, e.g. "NORTH"
function UTILS.BearingToCardinal(Heading)
  if     Heading >= 0   and Heading <= 22  then return "North"
    elseif Heading >= 23  and Heading <= 66  then return "North-East"
    elseif Heading >= 67  and Heading <= 101 then return "East"
    elseif Heading >= 102 and Heading <= 146 then return "South-East"
    elseif Heading >= 147 and Heading <= 201 then return "South"
    elseif Heading >= 202 and Heading <= 246 then return "South-West"
    elseif Heading >= 247 and Heading <= 291 then return "West"
    elseif Heading >= 292 and Heading <= 338 then return "North-West"
    elseif Heading >= 339 then return "North"
  end
end

--- Create a BRAA NATO call string BRAA between two GROUP objects
-- @param Wrapper.Group#GROUP FromGrp GROUP object
-- @param Wrapper.Group#GROUP ToGrp GROUP object
-- @return #string Formatted BRAA NATO call
function UTILS.ToStringBRAANATO(FromGrp,ToGrp)
  local BRAANATO = "Merged."
  local GroupNumber = ToGrp:GetSize()
  local GroupWords = "Singleton"
  if GroupNumber == 2 then GroupWords = "Two-Ship"
    elseif GroupNumber >= 3 then GroupWords = "Heavy"
  end
  local grpLeadUnit = ToGrp:GetUnit(1)
  local tgtCoord = grpLeadUnit:GetCoordinate()
  local currentCoord = FromGrp:GetCoordinate()
  local hdg = UTILS.Round(ToGrp:GetHeading()/100,1)*100
  local bearing = UTILS.Round(currentCoord:HeadingTo(tgtCoord),0)
  local rangeMetres = tgtCoord:Get2DDistance(currentCoord)
  local rangeNM = UTILS.Round( UTILS.MetersToNM(rangeMetres), 0)
  local aspect = tgtCoord:ToStringAspect(currentCoord)
  local alt = UTILS.Round(UTILS.MetersToFeet(grpLeadUnit:GetAltitude())/1000,0)--*1000
  local track = UTILS.BearingToCardinal(hdg)
  if rangeNM > 3 then
      if aspect == "" then
        BRAANATO = string.format("%s, BRA, %03d, %d miles, Angels %d, Track %s",GroupWords,bearing, rangeNM, alt, track)
      else
        BRAANATO = string.format("%s, BRAA, %03d, %d miles, Angels %d, %s, Track %s",GroupWords, bearing, rangeNM, alt, aspect, track)
      end
  end
  return BRAANATO
end

--- Check if an object is contained in a table.
-- @param #table Table The table.
-- @param #table Object The object to check.
-- @param #string Key (Optional) Key to check. By default, the object itself is checked.
-- @return #boolean Returns `true` if object is in table.
function UTILS.IsInTable(Table, Object, Key)

  for key, object in pairs(Table) do
    if Key then
      if Object[Key]==object[Key] then
        return true
      end
    else
      if object==Object then
        return true
      end
    end
  end

  return false
end

--- Check if any object of multiple given objects is contained in a table.
-- @param #table Table The table.
-- @param #table Objects The objects to check.
-- @param #string Key (Optional) Key to check.
-- @return #boolean Returns `true` if object is in table.
function UTILS.IsAnyInTable(Table, Objects, Key)

  for _,Object in pairs(UTILS.EnsureTable(Objects)) do

    for key, object in pairs(Table) do
      if Key then
        if Object[Key]==object[Key] then
          return true
        end
      else
        if object==Object then
          return true
        end
      end
    end

  end

  return false
end

--- Helper function to plot a racetrack on the F10 Map - curtesy of Buur.
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Altitude Altitude in feet
-- @param #number Speed Speed in knots
-- @param #number Heading Heading in degrees
-- @param #number Leg Leg in NM
-- @param #number Coalition Coalition side, e.g. coaltion.side.RED or coaltion.side.BLUE
-- @param #table Color Color of the line in RGB, e.g. {1,0,0} for red
-- @param #number Alpha Transparency factor, between 0.1 and 1
-- @param #number LineType Line type to be used, line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 1=Solid.
-- @param #boolean ReadOnly
function UTILS.PlotRacetrack(Coordinate, Altitude, Speed, Heading, Leg, Coalition, Color, Alpha, LineType, ReadOnly)
    local fix_coordinate = Coordinate
    local altitude = Altitude
    local speed = Speed or 350
    local heading = Heading or 270
    local leg_distance = Leg or 10

    local coalition = Coalition or -1
    local color = Color or {1,0,0}
    local alpha = Alpha or 1
    local lineType = LineType or 1


    speed = UTILS.IasToTas(speed, UTILS.FeetToMeters(altitude), oatcorr)

    local turn_radius = 0.0211 * speed -3.01

    local point_two = fix_coordinate:Translate(UTILS.NMToMeters(leg_distance), heading, true, false)
    local point_three = point_two:Translate(UTILS.NMToMeters(turn_radius)*2, heading - 90, true, false)
    local point_four = fix_coordinate:Translate(UTILS.NMToMeters(turn_radius)*2, heading - 90, true, false)
    local circle_center_fix_four = point_two:Translate(UTILS.NMToMeters(turn_radius), heading - 90, true, false)
    local circle_center_two_three = fix_coordinate:Translate(UTILS.NMToMeters(turn_radius), heading - 90, true, false)


    fix_coordinate:LineToAll(point_two, coalition, color, alpha, lineType)
    point_four:LineToAll(point_three, coalition, color, alpha, lineType)
    circle_center_fix_four:CircleToAll(UTILS.NMToMeters(turn_radius), coalition, color, alpha, nil, 0, lineType)--, ReadOnly, Text)
    circle_center_two_three:CircleToAll(UTILS.NMToMeters(turn_radius), coalition, color, alpha, nil, 0, lineType)--, ReadOnly, Text)

end

--- Get the current time in a "nice" format like 21:01:15
-- @return #string Returns string with the current time
function UTILS.TimeNow()
    return UTILS.SecondsToClock(timer.getAbsTime(), false, false)
end


--- Given 2 "nice" time string, returns the difference between the two in seconds
-- @param #string start_time Time string like "07:15:22"
-- @param #string end_time Time string like "08:11:27"
-- @return #number Seconds between start_time and end_time
function UTILS.TimeDifferenceInSeconds(start_time, end_time)
    return UTILS.ClockToSeconds(end_time) - UTILS.ClockToSeconds(start_time)
end

--- Check if the current time is later than time_string.
-- @param #string start_time Time string like "07:15:22"
-- @return #boolean True if later, False if before
function UTILS.TimeLaterThan(time_string)
    if timer.getAbsTime() > UTILS.ClockToSeconds(time_string) then
        return true
    end
    return false
end

--- Check if the current time is before time_string.
-- @param #string start_time Time string like "07:15:22"
-- @return #boolean False if later, True if before
function UTILS.TimeBefore(time_string)
    if timer.getAbsTime() < UTILS.ClockToSeconds(time_string) then
        return true
    end
    return false
end


--- Combines two time strings to give you a new time. For example "15:16:32" and "02:06:24" would return "17:22:56"
-- @param #string time_string_01 Time string like "07:15:22"
-- @param #string time_string_02 Time string like "08:11:27"
-- @return #string Result of the two time string combined
function UTILS.CombineTimeStrings(time_string_01, time_string_02)
    local hours1, minutes1, seconds1 = time_string_01:match("(%d+):(%d+):(%d+)")
    local hours2, minutes2, seconds2 = time_string_02:match("(%d+):(%d+):(%d+)")
    local total_seconds = tonumber(seconds1) + tonumber(seconds2) + tonumber(minutes1) * 60 + tonumber(minutes2) * 60 + tonumber(hours1) * 3600 + tonumber(hours2) * 3600

    total_seconds = total_seconds % (24 * 3600)
    if total_seconds < 0 then
        total_seconds = total_seconds + 24 * 3600
    end

    local hours = math.floor(total_seconds / 3600)
    total_seconds = total_seconds - hours * 3600
    local minutes = math.floor(total_seconds / 60)
    local seconds = total_seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end


--- Subtracts two time string to give you a new time. For example "15:16:32" and "02:06:24" would return "13:10:08"
-- @param #string time_string_01 Time string like "07:15:22"
-- @param #string time_string_02 Time string like "08:11:27"
-- @return #string Result of the two time string subtracted
function UTILS.SubtractTimeStrings(time_string_01, time_string_02)
    local hours1, minutes1, seconds1 = time_string_01:match("(%d+):(%d+):(%d+)")
    local hours2, minutes2, seconds2 = time_string_02:match("(%d+):(%d+):(%d+)")
    local total_seconds = tonumber(seconds1) - tonumber(seconds2) + tonumber(minutes1) * 60 - tonumber(minutes2) * 60 + tonumber(hours1) * 3600 - tonumber(hours2) * 3600

    total_seconds = total_seconds % (24 * 3600)
    if total_seconds < 0 then
        total_seconds = total_seconds + 24 * 3600
    end

    local hours = math.floor(total_seconds / 3600)
    total_seconds = total_seconds - hours * 3600
    local minutes = math.floor(total_seconds / 60)
    local seconds = total_seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

--- Checks if the current time is in between start_time and end_time
-- @param #string time_string_01 Time string like "07:15:22"
-- @param #string time_string_02 Time string like "08:11:27"
-- @return #boolean True if it is, False if it's not
function UTILS.TimeBetween(start_time, end_time)
    return UTILS.TimeLaterThan(start_time) and UTILS.TimeBefore(end_time)
end

--- Easy to read one line to roll the dice on something. 1% is very unlikely to happen, 99% is very likely to happen
-- @param #number chance (optional) Percentage chance you want something to happen. Defaults to a random number if not given
-- @return #boolean True if the dice roll was within the given percentage chance of happening
function UTILS.PercentageChance(chance)
    chance = chance or math.random(0, 100)
    chance = UTILS.Clamp(chance, 0, 100)
    local percentage = math.random(0, 100)
    if percentage < chance then
        return true
    end
    return false
end

--- Easy to read one liner to clamp a value
-- @param #number value Input value
-- @param #number min Minimal value that should be respected
-- @param #number max Maximal value that should be respected
-- @return #number Clamped value
function UTILS.Clamp(value, min, max)
    if value < min then value = min end
    if value > max then value = max end

    return value
end

--- Clamp an angle so that it's always between 0 and 360 while still being correct
-- @param #number value Input value
-- @return #number Clamped value
function UTILS.ClampAngle(value)
    if value > 360 then return value - 360 end
    if value < 0 then return value + 360 end
    return value
end

--- Remap an input to a new value in a given range. For example:
--- UTILS.RemapValue(20, 10, 30, 0, 200) would return 100
--- 20 is 50% between 10 and 30
--- 50% between 0 and 200 is 100
-- @param #number value Input value
-- @param #number old_min Min value to remap from
-- @param #number old_max Max value to remap from
-- @param #number new_min Min value to remap to
-- @param #number new_max Max value to remap to
-- @return #number Remapped value
function UTILS.RemapValue(value, old_min, old_max, new_min, new_max)
    new_min = new_min or 0
    new_max = new_max or 100

    local old_range = old_max - old_min
    local new_range = new_max - new_min
    local percentage = (value - old_min) / old_range
    return (new_range * percentage) + new_min
end

--- Given a triangle made out of 3 vector 2s, return a vec2 that is a random number in this triangle
-- @param DCS#Vec2 pt1 Min value to remap from
-- @param DCS#Vec2 pt2 Max value to remap from
-- @param DCS#Vec2 pt3 Max value to remap from
-- @return DCS#Vec2 Random point in triangle
function UTILS.RandomPointInTriangle(pt1, pt2, pt3)
    local pt = {math.random(), math.random()}
    table.sort(pt)
    local s = pt[1]
    local t = pt[2] - pt[1]
    local u = 1 - pt[2]

    return {x = s * pt1.x + t * pt2.x + u * pt3.x,
            y = s * pt1.y + t * pt2.y + u * pt3.y}
end

--- Checks if a given angle (heading) is between 2 other angles. Min and max have to be given in clockwise order For example:
--- UTILS.AngleBetween(350, 270, 15) would return True
--- UTILS.AngleBetween(22, 95, 20) would return False
-- @param #number angle Min value to remap from
-- @param #number min Max value to remap from
-- @param #number max Max value to remap from
-- @return #boolean 
function UTILS.AngleBetween(angle, min, max)
    angle = (360 + (angle % 360)) % 360
    min = (360 + min % 360) % 360
    max = (360 + max % 360) % 360

    if min < max then return min <= angle and angle <= max end
    return min <= angle or angle <= max
end

--- Easy to read one liner to write a JSON file. Everything in @data should be serializable
--- json.lua exists in the DCS install Scripts folder
-- @param #table data table to write
-- @param #string file_path File path
function UTILS.WriteJSON(data, file_path)
    package.path  = package.path ..  ";.\\Scripts\\?.lua"
    local JSON = require("json")
    local pretty_json_text = JSON:encode_pretty(data)
    local write_file = io.open(file_path, "w")
    write_file:write(pretty_json_text)
    write_file:close()
end

--- Easy to read one liner to read a JSON file.
--- json.lua exists in the DCS install Scripts folder
-- @param #string file_path File path
-- @return #table
function UTILS.ReadJSON(file_path)
    package.path  = package.path ..  ";.\\Scripts\\?.lua"
    local JSON = require("json")
    local read_file = io.open(file_path, "r")
    local contents = read_file:read( "*a" )
    io.close(read_file)
    return JSON:decode(contents)
end

--- Get the properties names and values of properties set up on a Zone in the Mission Editor.
--- This doesn't work for any zones created in MOOSE
-- @param #string zone_name Name of the zone as set up in the Mission Editor
-- @return #table with all the properties on a zone
function UTILS.GetZoneProperties(zone_name)
    local return_table = {}
    for _, zone in pairs(env.mission.triggers.zones) do
        if zone["name"] == zone_name then
            if table.length(zone["properties"]) > 0 then
                for _, property in pairs(zone["properties"]) do
                    return_table[property["key"]] = property["value"]
                end
              return return_table
            else
                BASE:I(string.format("%s doesn't have any properties", zone_name))
                return {}
            end
        end
    end
end

--- Rotates a point around another point with a given angle. Useful if you're loading in groups or
--- statics but you want to rotate them all as a collection. You can get the center point of everything
--- and then rotate all the positions of every object around this center point.
-- @param DCS#Vec2 point Point that you want to rotate
-- @param DCS#Vec2 pivot Pivot point of the rotation
-- @param #number angle How many degrees the point should be rotated
-- @return DCS#Vec2 Rotated point
function UTILS.RotatePointAroundPivot(point, pivot, angle)
    local radians = math.rad(angle)

    local x = point.x - pivot.x
    local y = point.y - pivot.y

    local rotated_x = x * math.cos(radians) - y * math.sin(radians)
    local rotatex_y = x * math.sin(radians) + y * math.cos(radians)

    local original_x = rotated_x + pivot.x
    local original_y = rotatex_y + pivot.y

    return { x = original_x, y = original_y }
end

--- Makes a string semi-unique by attaching a random number between 0 and 1 million to it
-- @param #string base String you want to unique-fy
-- @return #string Unique string
function UTILS.UniqueName(base)
    base = base or ""
    local ran = tostring(math.random(0, 1000000))

    if base == "" then
        return ran
    end
    return base .. "_" .. ran
end

--- Check if a string starts with something
-- @param #string str String to check
-- @param #string value
-- @return #boolean True if str starts with value
function string.startswith(str, value)
   return string.sub(str,1,string.len(value)) == value
end


--- Check if a string ends with something
-- @param #string str String to check
-- @param #string value
-- @return #boolean True if str ends with value
function string.endswith(str, value)
    return value == "" or str:sub(-#value) == value
end

--- Splits a string on a separator. For example:
--- string.split("hello_dcs_world", "-") would return {"hello", "dcs", "world"}
-- @param #string input String to split
-- @param #string separator What to split on
-- @return #table individual strings
function string.split(input, separator)
    local parts = {}
    for part in input:gmatch("[^" .. separator .. "]+") do
        table.insert(parts, part)
    end
    return parts
end


--- Checks if a string contains a substring. Easier to remember for Python people :)
--- string.split("hello_dcs_world", "-") would return {"hello", "dcs", "world"}
-- @param #string str
-- @param #string value
-- @return #boolean True if str contains value
function string.contains(str, value)
    return string.match(str, value)
end


--- Moves an object from one table to another
-- @param #table obj object to move
-- @param #table from_table table to move from
-- @param #table to_table table to move to
function table.move_object(obj, from_table, to_table)
    local index
    for i, v in pairs(from_table) do
        if v == obj then
            index = i
        end
    end

    if index then
        local moved = table.remove(from_table, index)
        table.insert_unique(to_table, moved)
    end
end

--- Given tbl is a indexed table ({"hello", "dcs", "world"}), checks if element exists in the table.
--- The table can be made up out of complex tables or values as well
-- @param #table tbl
-- @param #string element
-- @return #boolean True if tbl contains element
function table.contains(tbl, element)
    if element == nil or tbl == nil then return false end

    local index = 1
    while tbl[index] do
        if tbl[index] == element then
            return true
        end
        index = index + 1
    end
    return false
end

--- Checks if a table contains a specific key.
-- @param #table tbl Table to check
-- @param #string key Key to look for
-- @return #boolean True if tbl contains key
function table.contains_key(tbl, key)
    if tbl[key] ~= nil then return true else return false end
end

--- Inserts a unique element into a table.
-- @param #table tbl Table to insert into
-- @param #string element Element to insert
function table.insert_unique(tbl, element)
    if element == nil or tbl == nil then return end

    if not table.contains(tbl, element) then
        table.insert(tbl, element)
    end
end

--- Removes an element from a table by its value.
-- @param #table tbl Table to remove from
-- @param #string element Element to remove
function table.remove_by_value(tbl, element)
    local indices_to_remove = {}
    local index = 1
    for _, value in pairs(tbl) do
        if value == element then
            table.insert(indices_to_remove, index)
        end
        index = index + 1
    end

    for _, idx in pairs(indices_to_remove) do
        table.remove(tbl, idx)
    end
end

--- Removes an element from a table by its key.
-- @param #table table Table to remove from
-- @param #string key Key of the element to remove
-- @return #string Removed element
function table.remove_key(table, key)
    local element = table[key]
    table[key] = nil
    return element
end

--- Finds the index of an element in a table.
-- @param #table table Table to search
-- @param #string element Element to find
-- @return #number Index of the element, or nil if not found
function table.index_of(table, element)
    for i, v in ipairs(table) do
        if v == element then
            return i
        end
    end
    return nil
end

--- Counts the number of elements in a table.
-- @param #table T Table to count
-- @return #number Number of elements in the table
function table.length(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--- Slices a table between two indices, much like Python's my_list[2:-1]
-- @param #table tbl Table to slice
-- @param #number first Starting index
-- @param #number last Ending index
-- @return #table Sliced table
function table.slice(tbl, first, last)
  local sliced = {}
  local start = first or 1
  local stop = last or table.length(tbl)
  local count = 1

  for key, value in pairs(tbl) do
      if count >= start and count <= stop then
          sliced[key] = value
      end
      count = count + 1
  end

  return sliced
end

--- Counts the number of occurrences of a value in a table.
-- @param #table tbl Table to search
-- @param #string value Value to count
-- @return #number Number of occurrences of the value
function table.count_value(tbl, value)
    local count = 0
    for _, item in pairs(tbl) do
        if item == value then count = count + 1 end
    end
    return count
end

--- Add 2 table together, t2 gets added to t1
-- @param #table t1 First table
-- @param #table t2 Second table
-- @return #table Combined table
function table.combine(t1, t2)
    if t1 == nil and t2 == nil then
        BASE:E("Both tables were empty!")
    end

    if t1 == nil then return t2 end
    if t2 == nil then return t1 end
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

--- Merges two tables into one. If a key exists in both t1 and t2, the value of t1 with be overwritten by the value of t2
-- @param #table t1 First table
-- @param #table t2 Second table
-- @return #table Merged table
function table.merge(t1, t2)
    for k, v in pairs(t2) do
        if (type(v) == "table") and (type(t1[k] or false) == "table") then
            table.merge(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

--- Adds an item to the end of a table.
-- @param #table tbl Table to add to
-- @param #string item Item to add
function table.add(tbl, item)
    tbl[#tbl + 1] = item
end

--- Shuffles the elements of a table.
-- @param #table tbl Table to shuffle
-- @return #table Shuffled table
function table.shuffle(tbl)
    local new_table = {}
    for _, value in ipairs(tbl) do
        local pos = math.random(1, #new_table +1)
        table.insert(new_table, pos, value)
    end
    return new_table
end

--- Finds a key-value pair in a table.
-- @param #table tbl Table to search
-- @param #string key Key to find
-- @param #string value Value to find
-- @return #table Table containing the key-value pair, or nil if not found
function table.find_key_value_pair(tbl, key, value)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            local result = table.find_key_value_pair(v, key, value)
            if result ~= nil then
                return result
            end
        elseif k == key and v == value then
            return tbl
        end
    end
    return nil
end

--- Convert a decimal to octal
-- @param #number Number the number to convert
-- @return #number Octal
function UTILS.DecimalToOctal(Number)
  if Number < 8 then return Number end
  local number = tonumber(Number)
  local octal = ""
  local n=1
  while number > 7 do
    local number1 = number%8
    octal = string.format("%d",number1)..octal
    local number2 = math.abs(number/8)
    if number2 < 8 then
      octal = string.format("%d",number2)..octal
    end
    number = number2
    n=n+1
  end
  return tonumber(octal)
end

--- Convert an octal to decimal
-- @param #number Number the number to convert
-- @return #number Decimal
function UTILS.OctalToDecimal(Number)
  return tonumber(Number,8)
end


--- HexToRGBA
-- @param hex_string table
-- @return #table R, G, B, A
function UTILS.HexToRGBA(hex_string)
    local hexNumber = tonumber(string.sub(hex_string, 3), 16) -- convert the string to a number
    -- extract RGBA components
    local alpha = hexNumber % 256
    hexNumber = (hexNumber - alpha) / 256
    local blue = hexNumber % 256
    hexNumber = (hexNumber - blue) / 256
    local green = hexNumber % 256
    hexNumber = (hexNumber - green) / 256
    local red = hexNumber % 256

    return {R = red, G = green, B = blue, A = alpha}
end


--- Function to save the position of a set of #OPSGROUP (ARMYGROUP) objects.
-- @param Core.Set#SET_OPSGROUP Set of ops objects to save
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @param #boolean Structured Append the data with a list of typenames in the group plus their count.
-- @return #boolean outcome True if saving is successful, else false.
function UTILS.SaveSetOfOpsGroups(Set,Path,Filename,Structured)
  local filename = Filename or "SetOfGroups"
  local data = "--Save SET of groups: (name,legion,template,alttemplate,units,position.x,position.y,position.z,strucdata) "..Filename .."\n"
  local List = Set:GetSetObjects()
  for _,_group in pairs (List) do
    local group = _group:GetGroup() -- Wrapper.Group#GROUP
    if group and group:IsAlive() then
      local name = group:GetName()
      local template = string.gsub(name,"(.AID.%d+$","")
      if string.find(template,"#") then
       template = string.gsub(name,"#(%d+)$","")
      end
      local alttemplate = _group.templatename or "none"
      local legiono = _group.legion -- Ops.Legion#LEGION
      local legion = "none"
      if legiono and type(legiono) == "table" and legiono.ClassName then
        legion = legiono:GetName()
        local asset = legiono:GetAssetByName(name) -- Functional.Warehouse#WAREHOUSE.Assetitem
        alttemplate=asset.templatename
      end
      local units = group:CountAliveUnits()
      local position = group:GetVec3()
      if Structured then
        local structure = UTILS.GetCountPerTypeName(group)
        local strucdata =  ""
        for typen,anzahl in pairs (structure) do
          strucdata = strucdata .. typen .. "=="..anzahl..";"
        end
        data = string.format("%s%s,%s,%s,%s,%d,%d,%d,%d,%s\n",data,name,legion,template,alttemplate,units,position.x,position.y,position.z,strucdata)
      else
        data = string.format("%s%s,%s,%s,%s,%d,%d,%d,%d\n",data,name,legion,template,alttemplate,units,position.x,position.y,position.z)
      end
    end
  end
  -- save the data
  local outcome = UTILS.SaveToFile(Path,Filename,data)
  return outcome
end

--- Load back a #OPSGROUP (ARMYGROUP) data from file for use with @{Ops.Brigade#BRIGADE.LoadBackAssetInPosition}()
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @return #table Returns a table of data entries: `{ groupname=groupname, size=size, coordinate=coordinate, template=template, structure=structure, legion=legion, alttemplate=alttemplate }`
-- Returns nil when the file cannot be read.
function UTILS.LoadSetOfOpsGroups(Path,Filename)

  local filename = Filename or "SetOfGroups"
  local datatable = {}

  if UTILS.CheckFileExists(Path,filename) then
    local outcome,loadeddata = UTILS.LoadFromFile(Path,Filename)
    -- remove header
    table.remove(loadeddata, 1)
    for _id,_entry in pairs (loadeddata) do
      local dataset = UTILS.Split(_entry,",")
      -- 1name,2legion,3template,4alttemplate,5units,6position.x,7position.y,8position.z,9strucdata
      local groupname = dataset[1]
      local legion = dataset[2]
      local template = dataset[3]
      local alttemplate = dataset[4]
      local size = tonumber(dataset[5])
      local posx = tonumber(dataset[6])
      local posy = tonumber(dataset[7])
      local posz = tonumber(dataset[8])
      local structure = dataset[9]
      local coordinate = COORDINATE:NewFromVec3({x=posx, y=posy, z=posz})
      if size > 0 then
        local data = { groupname=groupname, size=size, coordinate=coordinate, template=template, structure=structure, legion=legion, alttemplate=alttemplate }
        table.insert(datatable,data)
      end
    end
  else
    return nil
  end

  return datatable
end

--- Get the clock position from a relative heading
-- @param #number refHdg The heading of the reference object (such as a Wrapper.UNIT) in 0-360
-- @param #number tgtHdg The absolute heading from the reference object to the target object/point in 0-360
-- @return #string text Text in clock heading such as "4 O'CLOCK"
-- @usage Display the range and clock distance of a BTR in relation to REAPER 1-1's heading:
--
--          myUnit = UNIT:FindByName( "REAPER 1-1" )
--          myTarget = GROUP:FindByName( "BTR-1" )
--
--          coordUnit = myUnit:GetCoordinate()
--          coordTarget = myTarget:GetCoordinate()
--
--          hdgUnit = myUnit:GetHeading()
--          hdgTarget = coordUnit:HeadingTo( coordTarget )
--          distTarget = coordUnit:Get3DDistance( coordTarget )
--
--          clockString = UTILS.ClockHeadingString( hdgUnit, hdgTarget )
--
--          -- Will show this message to REAPER 1-1 in-game: Contact BTR at 3 o'clock for 1134m!
--          MESSAGE:New("Contact BTR at " .. clockString .. " for " .. distTarget  .. "m!):ToUnit( myUnit )
function UTILS.ClockHeadingString(refHdg,tgtHdg)
    local relativeAngle = tgtHdg - refHdg
    if relativeAngle < 0 then
        relativeAngle = relativeAngle + 360
    end
    local clockPos = math.ceil((relativeAngle % 360) / 30)
    return clockPos.." o'clock"
end

--- Get a NATO abbreviated MGRS text for SRS use, optionally with prosody slow tag
-- @param #string Text The input string, e.g. "MGRS 4Q FJ 12345 67890"
-- @param #boolean Slow Optional - add slow tags
-- @return #string Output for (Slow) spelling in SRS TTS e.g. "MGRS;<prosody rate="slow">4;Quebec;Foxtrot;Juliett;1;2;3;4;5;6;7;8;niner;zero;</prosody>"
function UTILS.MGRSStringToSRSFriendly(Text,Slow)
    local Text = string.gsub(Text,"MGRS ","")
    Text = string.gsub(Text,"%s+","")
    Text = string.gsub(Text,"([%a%d])","%1;") -- "0;5;1;"
    Text = string.gsub(Text,"A","Alpha")
    Text = string.gsub(Text,"B","Bravo")
    Text = string.gsub(Text,"C","Charlie")
    Text = string.gsub(Text,"D","Delta")
    Text = string.gsub(Text,"E","Echo")
    Text = string.gsub(Text,"F","Foxtrot")
    Text = string.gsub(Text,"G","Golf")
    Text = string.gsub(Text,"H","Hotel")
    Text = string.gsub(Text,"I","India")
    Text = string.gsub(Text,"J","Juliett")
    Text = string.gsub(Text,"K","Kilo")
    Text = string.gsub(Text,"L","Lima")
    Text = string.gsub(Text,"M","Mike")
    Text = string.gsub(Text,"N","November")
    Text = string.gsub(Text,"O","Oscar")
    Text = string.gsub(Text,"P","Papa")
    Text = string.gsub(Text,"Q","Quebec")
    Text = string.gsub(Text,"R","Romeo")
    Text = string.gsub(Text,"S","Sierra")
    Text = string.gsub(Text,"T","Tango")
    Text = string.gsub(Text,"U","Uniform")
    Text = string.gsub(Text,"V","Victor")
    Text = string.gsub(Text,"W","Whiskey")
    Text = string.gsub(Text,"X","Xray")
    Text = string.gsub(Text,"Y","Yankee")
    Text = string.gsub(Text,"Z","Zulu")
    Text = string.gsub(Text,"0","zero")
    Text = string.gsub(Text,"9","niner")
    if Slow then
      Text = '<prosody rate="slow">'..Text..'</prosody>'
    end
    Text = "MGRS;"..Text
    return Text
end


--- Read csv file and convert it to a lua table.
-- The csv must have a header specifing the names of the columns. The column names are used as table keys.
-- @param #string filename File name including full path on local disk.
-- @return #table The table filled with data from the csv file.
function UTILS.ReadCSV(filename)

  if not UTILS.FileExists(filename) then  
    env.error("File does not exist")
    return nil  
  end
  
  --- Function that load data from a file.
  local function _loadfile( filename )
    local f = io.open( filename, "rb" )
    if f then
      local data = f:read( "*all" )
      f:close()
      return data
    else
      BASE:E(string.format( "WARNING: Could read data from file %s!", tostring( filename ) ) )
      return nil
    end
  end
  
  -- Load asset data from file.
  local data = _loadfile( filename )
  
  local lines=UTILS.Split(data, "\n" )
  
  -- Remove carriage returns from end of lines
  for _,line in pairs(lines) do
    line=string.gsub(line, "[\n\r]","")
  end
  
  local sep=";"
  
  local columns=UTILS.Split(lines[1], sep)

  -- Remove header line.
  table.remove(lines, 1)
  
  local csvdata={}  
  for i, line in pairs(lines) do
    line=string.gsub(line, "[\n\r]","")
  
    local row={}
    for j, value in pairs(UTILS.Split(line, sep)) do
    
      local key=string.gsub(columns[j], "[\n\r]","")
      row[key]=value    
    end
    table.insert(csvdata, row)
  
  end

  return csvdata
end

--- Seed the LCG random number generator.
-- @param #number seed Seed value. Default is a random number using math.random()
function UTILS.LCGRandomSeed(seed)
  UTILS.lcg = {
    seed = seed or math.random(1, 2^32 - 1),
    a = 1664525,
    c = 1013904223,
    m = 2^32
  }
end

--- Return a pseudo-random number using the LCG algorithm.
-- @return #number Random number between 0 and 1.
function UTILS.LCGRandom()
  if UTILS.lcg == nil then
    UTILS.LCGRandomSeed()
  end
  UTILS.lcg.seed = (UTILS.lcg.a * UTILS.lcg.seed + UTILS.lcg.c) % UTILS.lcg.m
  return UTILS.lcg.seed / UTILS.lcg.m
end

--- Spawns a new FARP of a defined type and coalition and functional statics (fuel depot, ammo storage, tent, windsock) around that FARP to make it operational.
-- Adds vehicles from template if given. Fills the FARP warehouse with liquids and known materiels.
-- References: [DCS Forum Topic](https://forum.dcs.world/topic/282989-farp-equipment-to-run-it)
-- @param #string Name Name of this FARP installation. Must be unique. 
-- @param Core.Point#COORDINATE Coordinate Where to spawn the FARP.
-- @param #string FARPType Type of FARP, can be one of the known types ENUMS.FARPType.FARP, ENUMS.FARPType.INVISIBLE, ENUMS.FARPType.HELIPADSINGLE, ENUMS.FARPType.PADSINGLE. Defaults to ENUMS.FARPType.FARP.
-- @param #number Coalition Coalition of this FARP, i.e. coalition.side.BLUE or coalition.side.RED, defaults to coalition.side.BLUE.
-- @param #number Country Country of this FARP, defaults to country.id.USA (blue) or country.id.RUSSIA (red).
-- @param #number CallSign Callsign of the FARP ATC, defaults to CALLSIGN.FARP.Berlin.
-- @param #number Frequency Frequency of the FARP ATC Radio, defaults to 127.5 (MHz).
-- @param #number Modulation Modulation of the FARP ATC Radio, defaults to radio.modulation.AM.
-- @param #number ADF ADF Beacon (FM) Frequency in KHz, e.g. 428. If not nil, creates an VHF/FM ADF Beacon for this FARP. Requires a sound called "beacon.ogg" to be in the mission (trigger "sound to" ...)
-- @param #number SpawnRadius Radius of the FARP, i.e. where the FARP objects will be placed in meters, not more than 150m away. Defaults to 100.
-- @param #string VehicleTemplate, template name for additional vehicles. Can be nil for no additional vehicles.
-- @param #number Liquids Tons of fuel to be added initially to the FARP. Defaults to 10 (tons). Set to 0 for no fill.
-- @param #number Equipment Number of equipment items per known item to be added initially to the FARP. Defaults to 10 (items). Set to 0 for no fill.
-- @return #list<Wrapper.Static#STATIC> Table of spawned objects and vehicle object (if given).
-- @return #string ADFBeaconName Name of the ADF beacon, to be able to remove/stop it later.
function UTILS.SpawnFARPAndFunctionalStatics(Name,Coordinate,FARPType,Coalition,Country,CallSign,Frequency,Modulation,ADF,SpawnRadius,VehicleTemplate,Liquids,Equipment)
  
  -- Set Defaults
  local farplocation = Coordinate
  local farptype = FARPType or ENUMS.FARPType.FARP
  local Coalition = Coalition or coalition.side.BLUE
  local callsign = CallSign or CALLSIGN.FARP.Berlin
  local freq = Frequency or 127.5
  local mod = Modulation or radio.modulation.AM
  local radius = SpawnRadius or 100
  if radius < 0 or radius > 150 then radius = 100 end
  local liquids = Liquids or 10
  liquids = liquids * 1000 -- tons to kg
  local equip = Equipment or 10
  local statictypes = ENUMS.FARPObjectTypeNamesAndShape[farptype] or {TypeName="FARP", ShapeName="FARPS"}
  local STypeName = statictypes.TypeName
  local SShapeName = statictypes.ShapeName
  local Country = Country or (Coalition == coalition.side.BLUE and country.id.USA or country.id.RUSSIA)
  local ReturnObjects = {}
  
  -- Spawn FARP
  local newfarp = SPAWNSTATIC:NewFromType(STypeName,"Heliports",Country) --  "Invisible FARP" "FARP"
  newfarp:InitShape(SShapeName) -- "invisiblefarp" "FARPS"
  newfarp:InitFARP(callsign,freq,mod)
  local spawnedfarp = newfarp:SpawnFromCoordinate(farplocation,0,Name)
  table.insert(ReturnObjects,spawnedfarp)
  -- Spawn Objects
  local FARPStaticObjectsNato = {
    ["FUEL"] = { TypeName = "FARP Fuel Depot", ShapeName = "GSM Rus", Category = "Fortifications"},
    ["AMMO"] = { TypeName = "FARP Ammo Dump Coating", ShapeName = "SetkaKP", Category = "Fortifications"},
    ["TENT"] = { TypeName = "FARP Tent", ShapeName = "PalatkaB", Category = "Fortifications"},
    ["WINDSOCK"]  = { TypeName = "Windsock", ShapeName = "H-Windsock_RW", Category = "Fortifications"},
  }
    
  local farpobcount = 0
  for _name,_object in pairs(FARPStaticObjectsNato) do
    local objloc = farplocation:Translate(radius,farpobcount*30)
    local heading = objloc:HeadingTo(farplocation)
    local newobject = SPAWNSTATIC:NewFromType(_object.TypeName,_object.Category,Country)
    newobject:InitShape(_object.ShapeName)
    newobject:InitHeading(heading)
    newobject:SpawnFromCoordinate(objloc,farpobcount*30,_name.." - "..Name)
    table.insert(ReturnObjects,newobject)
    farpobcount = farpobcount + 1
  end
  
  -- Vehicle if any
  if VehicleTemplate and type(VehicleTemplate) == "string" then
    local vcoordinate = farplocation:Translate(radius,farpobcount*30)
    local heading = vcoordinate:HeadingTo(farplocation)
    local vehicles = SPAWN:NewWithAlias(VehicleTemplate,"FARP Vehicles - "..Name)
    vehicles:InitGroupHeading(heading)
    vehicles:InitCountry(Country)
    vehicles:InitCoalition(Coalition)
    vehicles:InitDelayOff()
    local spawnedvehicle = vehicles:SpawnFromCoordinate(vcoordinate)
    table.insert(ReturnObjects,spawnedvehicle)
  end
  
  local newWH = STORAGE:New(Name)
  if liquids and liquids > 0 then
    -- Storage fill-up
    newWH:SetLiquid(STORAGE.Liquid.DIESEL,liquids) -- kgs to tons
    newWH:SetLiquid(STORAGE.Liquid.GASOLINE,liquids)
    newWH:SetLiquid(STORAGE.Liquid.JETFUEL,liquids)
    newWH:SetLiquid(STORAGE.Liquid.MW50,liquids)
  end
  
  if equip and equip > 0 then
    for cat,nitem in pairs(ENUMS.Storage.weapons) do
      for name,item in pairs(nitem) do
        newWH:SetItem(item,equip)
      end
    end
  end
  
  local ADFName
  if ADF and type(ADF) == "number" then
    local ADFFreq = ADF*1000 -- KHz to Hz
    local Sound =  "l10n/DEFAULT/beacon.ogg"
    local vec3 = farplocation:GetVec3()
    ADFName = Name .. " ADF "..tostring(ADF).."KHz"
    --BASE:I(string.format("Adding FARP Beacon %d KHz Name %s",ADF,ADFName))
    trigger.action.radioTransmission(Sound, vec3, 0, true, ADFFreq, 250, ADFName)
  end
  
  return ReturnObjects, ADFName
end

--- Converts a Vec2 to a Vec3.
-- @param vec the 2D vector
-- @param y optional new y axis (altitude) value. If omitted it's 0.
function UTILS.Vec2toVec3(vec,y) 
  if not vec.z then
    if vec.alt and not y then
      y = vec.alt
    elseif not y then
      y = 0
    end
    return {x = vec.x, y = y, z = vec.y}
  else
    return {x = vec.x, y = vec.y, z = vec.z}  -- it was already Vec3, actually.
  end
end

--- Get the correction needed for true north in radians
-- @param gPoint The map point vec2 or vec3
-- @return number correction
function UTILS.GetNorthCorrection(gPoint)  
  local point = UTILS.DeepCopy(gPoint)
  if not point.z then --Vec2; convert to Vec3
    point.z = point.y
    point.y = 0
  end
  local lat, lon = coord.LOtoLL(point)
  local north_posit = coord.LLtoLO(lat + 1, lon)
  return math.atan2(north_posit.z - point.z, north_posit.x - point.x)
end

--- Convert time in seconds to a DHMS table `{d = days, h = hours, m = minutes, s = seconds}`
-- @param timeInSec Time in Seconds
-- @return #table Table with DHMS data
function UTILS.GetDHMS(timeInSec)
  if timeInSec and type(timeInSec) == 'number' then
    local tbl = {d = 0, h = 0, m = 0, s = 0}
    if timeInSec > 86400 then
      while timeInSec > 86400 do
        tbl.d = tbl.d + 1
        timeInSec = timeInSec - 86400
      end
    end
    if timeInSec > 3600 then
      while timeInSec > 3600 do
        tbl.h = tbl.h + 1
        timeInSec = timeInSec - 3600
      end
    end
    if timeInSec > 60 then
      while timeInSec > 60 do
        tbl.m = tbl.m + 1
        timeInSec = timeInSec - 60
      end
    end
    tbl.s = timeInSec
    return tbl
  else
    BASE:E("No number handed!")
    return
  end
end

--- Returns heading-error corrected direction in radians.
-- True-north corrected direction from point along vector vec.
-- @param vec Vec3 Starting point
-- @param point Vec2 Direction
-- @return direction corrected direction from point.
function UTILS.GetDirectionRadians(vec, point)
  local dir = math.atan2(vec.z, vec.x)
  if point then
    dir = dir + UTILS.GetNorthCorrection(point)
  end
  if dir < 0 then
    dir = dir + 2 * math.pi -- put dir in range of 0 to 2*pi
  end
  return dir
end

--- Raycasting a point in polygon. Code from http://softsurfer.com/Archive/algorithm_0103/algorithm_0103.htm
-- @param point Vec2 or Vec3 to test
-- @param #table poly Polygon Table of Vec2/3 point forming the Polygon
-- @param #number maxalt Altitude limit (optional)
-- @param #boolean outcome 
function UTILS.IsPointInPolygon(point, poly, maxalt) 
  point = UTILS.Vec2toVec3(point)
  local px = point.x
  local pz = point.z
  local cn = 0
  local newpoly = UTILS.DeepCopy(poly)

  if not maxalt or (point.y <= maxalt) then
    local polysize = #newpoly
    newpoly[#newpoly + 1] = newpoly[1]

    newpoly[1] = UTILS.Vec2toVec3(newpoly[1])

    for k = 1, polysize do
      newpoly[k+1] = UTILS.Vec2toVec3(newpoly[k+1])
      if ((newpoly[k].z <= pz) and (newpoly[k+1].z > pz)) or ((newpoly[k].z > pz) and (newpoly[k+1].z <= pz)) then
        local vt = (pz - newpoly[k].z) / (newpoly[k+1].z - newpoly[k].z)
        if (px < newpoly[k].x + vt*(newpoly[k+1].x - newpoly[k].x)) then
          cn = cn + 1
        end
      end
    end

    return cn%2 == 1
  else
    return false
  end
end

--- Vector scalar multiplication.
-- @param vec Vec3 vector to multiply
-- @param #number mult scalar multiplicator
-- @return Vec3 new vector multiplied with the given scalar
function UTILS.ScalarMult(vec, mult)
  return {x = vec.x*mult, y = vec.y*mult, z = vec.z*mult}
end
