--- **Wrapper** - Dynamic Cargo create from the F8 menu.
--
-- ## Main Features:
--
--    * Convenient access to DCS API functions
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_Demos/tree/master/Wrapper/Storage).
--
-- ===
--
-- ### Author: **Applevangelist**
--
-- ===
-- @module Wrapper.DynamicCargo
-- @image Wrapper_Storage.png


--- DYNAMICCARGO class.
-- @type DYNAMICCARGO
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field Wrapper.Storage#STORAGE warehouse The STORAGE object.
-- @field #string version.
-- @field #string CargoState.
-- @field #table DCS#Vec3 LastPosition.
-- @field #number Interval Check Interval. 20 secs default.
-- @field #boolean testing
-- @field Core.Timer#TIMER timer Timmer to run intervals
-- @field #string Owner The playername who has created, loaded or unloaded this cargo. Depends on state.
-- @extends Wrapper.Positionable#POSITIONABLE

--- *The capitalist cannot store labour-power in warehouses after he has bought it, as he may do with the raw material.* -- Karl Marx
--
-- ===
--
-- # The DYNAMICCARGO Concept
--
-- The DYNAMICCARGO class offers an easy-to-use wrapper interface to all DCS API functions of DCS dynamically spawned cargo crates.
-- We named the class DYNAMICCARGO, because the name WAREHOUSE is already taken by another MOOSE class..
--
-- # Constructor
--
-- @field #DYNAMICCARGO
DYNAMICCARGO = {
  ClassName          = "DYNAMICCARGO",
  verbose            = 0,
  testing            = false,
  Interval           = 10,
  
}

--- Liquid types.
-- @type DYNAMICCARGO.Liquid
-- @field #number JETFUEL Jet fuel (0).
-- @field #number GASOLINE Aviation gasoline (1).
-- @field #number MW50 MW50 (2).
-- @field #number DIESEL Diesel (3).
DYNAMICCARGO.Liquid = {
  JETFUEL = 0,
  GASOLINE = 1,
  MW50 = 2,
  DIESEL = 3,
}

--- Liquid Names for the static cargo resource table.
-- @type DYNAMICCARGO.LiquidName
-- @field #number JETFUEL "jet_fuel".
-- @field #number GASOLINE "gasoline".
-- @field #number MW50 "methanol_mixture".
-- @field #number DIESEL "diesel".
DYNAMICCARGO.LiquidName = {
   GASOLINE = "gasoline",
   DIESEL =    "diesel",
   MW50 =  "methanol_mixture",
   JETFUEL = "jet_fuel",  
}

--- Storage types.
-- @type DYNAMICCARGO.Type
-- @field #number WEAPONS weapons.
-- @field #number LIQUIDS liquids. Also see #list<#DYNAMICCARGO.Liquid> for types of liquids.
-- @field #number AIRCRAFT aircraft.
DYNAMICCARGO.Type = {
  WEAPONS = "weapons",
  LIQUIDS = "liquids",
  AIRCRAFT = "aircrafts",
}

--- State types
-- @type DYNAMICCARGO.State
-- @field #string NEW
-- @field #string LOADED
-- @field #string UNLOADED
-- @field #string REMOVED
DYNAMICCARGO.State = {
  NEW = "NEW",
  LOADED = "LOADED",
  UNLOADED = "UNLOADED",
  REMOVED = "REMOVED",
}

--- Helo types possible.
-- @type DYNAMICCARGO.AircraftTypes
DYNAMICCARGO.AircraftTypes = {
  ["CH-47Fbl1"] = "CH-47Fbl1",
}

--- Helo types possible.
-- @type DYNAMICCARGO.AircraftDimensions
DYNAMICCARGO.AircraftDimensions = {
  -- CH-47 model start coordinate is quite exactly in the middle of the model, so half values here
  ["CH-47Fbl1"] = {
    ["width"] = 4,
    ["height"] = 6,
    ["length"] = 11,
    ["ropelength"] = 30,
  },
}

--- DYNAMICCARGO class version.
-- @field #string version
DYNAMICCARGO.version="0.0.5"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new DYNAMICCARGO object from the DCS static cargo object.
-- @param #DYNAMICCARGO self
-- @param #string CargoName Name of the Cargo.
-- @return #DYNAMICCARGO self
function DYNAMICCARGO:Register(CargoName)

  -- Inherit everything from a BASE class.
  local self=BASE:Inherit(self, POSITIONABLE:New(CargoName)) -- #DYNAMICCARGO
    
  self.StaticName = CargoName
  
  self.LastPosition = self:GetCoordinate()
  
  self.CargoState = DYNAMICCARGO.State.NEW
  
  self.Interval = DYNAMICCARGO.Interval or 10
  
  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local warehouse = STORAGE:NewFromDynamicCargo(CargoName)
    self.warehouse = warehouse
  end
  
  self.lid = string.format("DYNAMICCARGO %s", CargoName)
  
  self.Owner = string.match(CargoName,"^(.+)|%d%d:%d%d|PKG%d+") or "None"
  
  self.timer = TIMER:New(DYNAMICCARGO._UpdatePosition,self)
  self.timer:Start(self.Interval,self.Interval)
  
  if not _DYNAMICCARGO_HELOS then
      _DYNAMICCARGO_HELOS = SET_CLIENT:New():FilterAlive():FilterFunction(DYNAMICCARGO._FilterHeloTypes):FilterStart()
  end
  
  if self.testing then
    BASE:TraceOn()
    BASE:TraceClass("DYNAMICCARGO")
  end
  
  return self
end

--- Get DCS object.
-- @param #DYNAMICCARGO self
-- @return DCS static object
function DYNAMICCARGO:GetDCSObject()
  local DCSStatic = Unit.getByName( self.StaticName ) 
  if DCSStatic then
    return DCSStatic
  end
  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User API Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get last known owner name of this DYNAMICCARGO
-- @param #DYNAMICCARGO self
-- @return #string Owner
function DYNAMICCARGO:GetLastOwner()
  return self.Owner
end

--- Returns true if the cargo is new and has never been loaded into a Helo.
-- @param #DYNAMICCARGO self
-- @return #boolean Outcome
function DYNAMICCARGO:IsNew()
  if self.CargoState and self.CargoState == DYNAMICCARGO.State.NEW then
    return true
  else
    return false
  end
end

--- Returns true if the cargo been loaded into a Helo.
-- @param #DYNAMICCARGO self
-- @return #boolean Outcome
function DYNAMICCARGO:IsLoaded()
  if self.CargoState and self.CargoState == DYNAMICCARGO.State.LOADED then
    return true
  else
    return false
  end
end

--- Returns true if the cargo has been unloaded from a Helo.
-- @param #DYNAMICCARGO self
-- @return #boolean Outcome
function DYNAMICCARGO:IsUnloaded()
  if self.CargoState and self.CargoState == DYNAMICCARGO.State.REMOVED then
    return true
  else
    return false
  end
end

--- Returns true if the cargo has been removed.
-- @param #DYNAMICCARGO self
-- @return #boolean Outcome
function DYNAMICCARGO:IsRemoved()
  if self.CargoState and self.CargoState == DYNAMICCARGO.State.UNLOADED then
    return true
  else
    return false
  end
end

--- [CTLD] Get number of crates this DYNAMICCARGO consists of. Always one.
-- @param #DYNAMICCARGO self
-- @return #number crate number, always one
function DYNAMICCARGO:GetCratesNeeded()
  return 1
end

--- [CTLD] Get this DYNAMICCARGO drop state. True if DYNAMICCARGO.State.UNLOADED
-- @param #DYNAMICCARGO self
-- @return #boolean Dropped
function DYNAMICCARGO:WasDropped()
  return self.CargoState == DYNAMICCARGO.State.UNLOADED and true or false
end

--- [CTLD] Get CTLD_CARGO.Enum type of this DYNAMICCARGO
-- @param #DYNAMICCARGO self
-- @return #string Type, only one at the moment is CTLD_CARGO.Enum.GCLOADABLE
function DYNAMICCARGO:GetType()
  return CTLD_CARGO.Enum.GCLOADABLE
end


--- Find last known position of this DYNAMICCARGO
-- @param #DYNAMICCARGO self
-- @return DCS#Vec3 Position in 3D space
function DYNAMICCARGO:GetLastPosition()
  return self.LastPosition
end

--- Find current state of this DYNAMICCARGO
-- @param #DYNAMICCARGO self
-- @return string The current state
function DYNAMICCARGO:GetState()
  return self.CargoState
end

--- Find a DYNAMICCARGO in the **_DATABASE** using the name associated with it.
-- @param #DYNAMICCARGO self
-- @param #string Name The dynamic cargo name
-- @return #DYNAMICCARGO self
function DYNAMICCARGO:FindByName( Name )
  local storage = _DATABASE:FindDynamicCargo( Name )
  return storage
end

--- Find the first(!) DYNAMICCARGO matching using patterns. Note that this is **a lot** slower than `:FindByName()`!
-- @param #DYNAMICCARGO self
-- @param #string Pattern The pattern to look for. Refer to [LUA patterns](http://www.easyuo.com/openeuo/wiki/index.php/Lua_Patterns_and_Captures_\(Regular_Expressions\)) for regular expressions in LUA.
-- @return #DYNAMICCARGO The DYNAMICCARGO.
-- @usage
--          -- Find a dynamic cargo with a partial dynamic cargo name
--          local grp = DYNAMICCARGO:FindByMatching( "Apple" )
--          -- will return e.g. a dynamic cargo named "Apple|08:00|PKG08"
--
--          -- using a pattern
--          local grp = DYNAMICCARGO:FindByMatching( ".%d.%d$" )
--          -- will return the first dynamic cargo found ending in "-1-1" to "-9-9", but not e.g. "-10-1"
function DYNAMICCARGO:FindByMatching( Pattern )
  local GroupFound = nil

  for name,static in pairs(_DATABASE.DYNAMICCARGO) do
    if string.match(name, Pattern ) then
      GroupFound = static
      break
    end
  end

  return GroupFound
end

--- Find all DYNAMICCARGO objects matching using patterns. Note that this is **a lot** slower than `:FindByName()`!
-- @param #DYNAMICCARGO self
-- @param #string Pattern The pattern to look for. Refer to [LUA patterns](http://www.easyuo.com/openeuo/wiki/index.php/Lua_Patterns_and_Captures_\(Regular_Expressions\)) for regular expressions in LUA.
-- @return #table Groups Table of matching #DYNAMICCARGO objects found
-- @usage
--          -- Find all dynamic cargo with a partial dynamic cargo name
--          local grptable = DYNAMICCARGO:FindAllByMatching( "Apple" )
--          -- will return all dynamic cargos with "Apple" in the name
--
--          -- using a pattern
--          local grp = DYNAMICCARGO:FindAllByMatching( ".%d.%d$" )
--          -- will return the all dynamic cargos found ending in "-1-1" to "-9-9", but not e.g. "-10-1" or "-1-10"
function DYNAMICCARGO:FindAllByMatching( Pattern )
  local GroupsFound = {}

  for name,static in pairs(_DATABASE.DYNAMICCARGO) do
    if string.match(name, Pattern ) then
      GroupsFound[#GroupsFound+1] = static
    end
  end

  return GroupsFound
end

--- Get the #STORAGE object from this dynamic cargo.
-- @param #DYNAMICCARGO self
-- @return Wrapper.Storage#STORAGE Storage The #STORAGE object
function DYNAMICCARGO:GetStorageObject()
  return self.warehouse
end

--- Get the weight in kgs from this dynamic cargo.
-- @param #DYNAMICCARGO self
-- @return #number Weight in kgs.
function DYNAMICCARGO:GetCargoWeight()
  local DCSObject = self:GetDCSObject()
  if DCSObject then
    local weight = DCSObject:getCargoWeight()
    return weight
  else
    return 0
  end
end

--- Get the cargo display name from this dynamic cargo.
-- @param #DYNAMICCARGO self
-- @return #string The display name
function DYNAMICCARGO:GetCargoDisplayName()
  local DCSObject = self:GetDCSObject()
  if DCSObject then
    local weight = DCSObject:getCargoDisplayName()
    return weight
  else
    return self.StaticName
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [Internal] _Get Possible Player Helo Nearby
-- @param #DYNAMICCARGO self
-- @param Core.Point#COORDINATE pos
-- @param #boolean loading If true measure distance for loading else for unloading
-- @return #boolean Success
-- @return Wrapper.Client#CLIENT Helo
-- @return #string PlayerName
function DYNAMICCARGO:_GetPossibleHeloNearby(pos,loading)
  local set = _DYNAMICCARGO_HELOS:GetAliveSet()
  local success = false
  local Helo = nil
  local Playername = nil
  for _,_helo in pairs (set or {}) do
    local helo = _helo -- Wrapper.Client#CLIENT
    local name = helo:GetPlayerName() or _DATABASE:_FindPlayerNameByUnitName(helo:GetName()) or "None"
    self:T(self.lid.." Checking: "..name)
    local hpos = helo:GetCoordinate()
    -- TODO Unloading via sling load?
    --local inair = hpos.y-hpos:GetLandHeight() > 4.5 and true or false -- Standard FARP is 4.5m
    local inair = helo:InAir()
    self:T(self.lid.." InAir: AGL/InAir: "..hpos.y-hpos:GetLandHeight().."/"..tostring(inair))
    local typename = helo:GetTypeName()
    if hpos and typename and inair == false then
      local dimensions = DYNAMICCARGO.AircraftDimensions[typename]
      if dimensions then
        local delta2D = hpos:Get2DDistance(pos)
        local delta3D = hpos:Get3DDistance(pos)
        if self.testing then
          self:T(string.format("Cargo relative position: 2D %dm | 3D %dm",delta2D,delta3D))
          self:T(string.format("Helo dimension: length %dm | width %dm | rope %dm",dimensions.length,dimensions.width,dimensions.ropelength))
        end
        if loading~=true and delta2D > dimensions.length or delta2D > dimensions.width or delta3D > dimensions.ropelength then
          success = true
          Helo = helo
          Playername = name
        end
        if loading == true and delta2D < dimensions.length or delta2D < dimensions.width or delta3D < dimensions.ropelength then
          success = true
          Helo = helo
          Playername = name
        end
      end
    end
  end
  return success,Helo,Playername
end

--- [Internal] Update internal states.
-- @param #DYNAMICCARGO self
-- @return #DYNAMICCARGO self
function DYNAMICCARGO:_UpdatePosition()
  self:T(self.lid.." _UpdatePositionAndState")
  if self:IsAlive() then
    local pos = self:GetCoordinate()
    if self.testing then
      self:T(string.format("Cargo position: x=%d, y=%d, z=%d",pos.x,pos.y,pos.z))
      self:T(string.format("Last position: x=%d, y=%d, z=%d",self.LastPosition.x,self.LastPosition.y,self.LastPosition.z))
    end
    if UTILS.Round(UTILS.VecDist3D(pos,self.LastPosition),2) > 0.5 then
      ---------------
      -- LOAD Cargo
      ---------------
      if self.CargoState == DYNAMICCARGO.State.NEW then
        local isloaded, client, playername = self:_GetPossibleHeloNearby(pos,true) 
        self:T(self.lid.." moved! NEW -> LOADED by "..tostring(playername))
        self.CargoState = DYNAMICCARGO.State.LOADED
        self.Owner = playername
        _DATABASE:CreateEventDynamicCargoLoaded(self)
      ---------------
      -- UNLOAD Cargo
      ---------------   
      elseif self.CargoState == DYNAMICCARGO.State.LOADED then
        -- TODO add checker if we are in flight somehow
        -- ensure not just the helo is moving
        local count = _DYNAMICCARGO_HELOS:CountAlive()
        -- Testing
        local landheight = pos:GetLandHeight()
        local agl = pos.y-landheight
        agl = UTILS.Round(agl,2)
        self:T(self.lid.." AGL: "..agl or -1)
        local isunloaded = true
        local client
        local playername = self.Owner
        if count > 0 and (agl > 0 or self.testing) then
          self:T(self.lid.." Possible alive helos: "..count or -1)
          if agl ~= 0 or self.testing then
            isunloaded, client, playername = self:_GetPossibleHeloNearby(pos,false)        
          end
          if isunloaded then
            self:T(self.lid.." moved! LOADED -> UNLOADED by "..tostring(playername))
            self.CargoState = DYNAMICCARGO.State.UNLOADED
            self.Owner = playername
            _DATABASE:CreateEventDynamicCargoUnloaded(self)
          end
        elseif count > 0 and agl == 0 then
          self:T(self.lid.." moved! LOADED -> UNLOADED by "..tostring(playername))
          self.CargoState = DYNAMICCARGO.State.UNLOADED
          self.Owner = playername
          _DATABASE:CreateEventDynamicCargoUnloaded(self)
        end
      end
      self.LastPosition = pos
    end
  else
    ---------------
    -- REMOVED Cargo
    --------------- 
    if self.timer and self.timer:IsRunning() then self.timer:Stop() end
    self:T(self.lid.." dead! " ..self.CargoState.."-> REMOVED")
    self.CargoState = DYNAMICCARGO.State.REMOVED
    _DATABASE:CreateEventDynamicCargoRemoved(self)
  end
  return self
end

--- [Internal] Track helos for loaded/unloaded decision making.
-- @param Wrapper.Client#CLIENT client
-- @return #boolean IsIn
function DYNAMICCARGO._FilterHeloTypes(client)
  if not client then return false end
  local typename = client:GetTypeName()
  local isinclude = DYNAMICCARGO.AircraftTypes[typename] ~= nil and true or false
  return isinclude
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
