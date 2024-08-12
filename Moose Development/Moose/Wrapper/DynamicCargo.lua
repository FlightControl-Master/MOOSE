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
  testing            = true,
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
  ["CH-47Fbl1"] = {
    ["width"] = 8,
    ["height"] = 6,
    ["length"] = 22,
    ["ropelength"] = 30,
  },
}

--- DYNAMICCARGO class version.
-- @field #string version
DYNAMICCARGO.version="0.0.1"

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

  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, POSITIONABLE:New(CargoName)) -- #DYNAMICCARGO
    
  self.StaticName = CargoName
  
  self.LastPosition = self:GetCoordinate()
  
  self.CargoState = DYNAMICCARGO.State.NEW
  
  self.Interval = 10
  
  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local warehouse = STORAGE:NewFromDynamicCargo(CargoName)
    self.warehouse = warehouse
  end
  
  self.lid = string.format("DYNAMICCARGO %s", CargoName)
  
  self:ScheduleOnce(self.Interval,DYNAMICCARGO._UpdatePosition,self)
  
  if not _DYNAMICCARGO_HELOS then
      _DYNAMICCARGO_HELOS = SET_CLIENT:New():FilterAlive():FilterFunction(DYNAMICCARGO._FilterHeloTypes):FilterStart()
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

--- [Internal] Update internal states.
-- @param #DYNAMICCARGO self
-- @return #DYNAMICCARGO self
function DYNAMICCARGO:_UpdatePosition()
  self:T(self.lid.." _UpdatePositionAndState")
  if self:IsAlive() then
    local pos = self:GetCoordinate()
    if self.testing then
      self:I(string.format("Cargo position: x=%d, y=%d, z=%d",pos.x,pos.y,pos.z))
      self:I(string.format("Last position: x=%d, y=%d, z=%d",self.LastPosition.x,self.LastPosition.y,self.LastPosition.z))
    end
    if UTILS.Round(UTILS.VecDist3D(pos,self.LastPosition),2) > 0.5 then
    -- moved
      if self.CargoState == DYNAMICCARGO.State.NEW then
        self:I(self.lid.." moved! NEW -> LOADED")
        self.CargoState = DYNAMICCARGO.State.LOADED
        _DATABASE:CreateEventDynamicCargoLoaded(self)
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
        if count > 0 and (agl > 0 or self.testing) then
          self:T(self.lid.." Possible alive helos: "..count or -1)
          if agl ~= 0 or self.testing then
            isunloaded = false
            local set = _DYNAMICCARGO_HELOS:GetAliveSet()
            for _,_helo in pairs (set or {}) do
              local helo = _helo -- Wrapper.Client#CLIENT
              self:I(self.lid.." Checking: "..helo:GetPlayerName())
              local hpos = helo:GetCoordinate()
              hpos:MarkToAll("Helo position",true,"helo")
              pos:MarkToAll("Cargo position",true,"cargo")
              local typename = helo:GetTypeName()
              if hpos then
                local dimensions = DYNAMICCARGO.AircraftDimensions[typename]
                if dimensions then
                  hpos:SmokeOrange()
                  local delta2D = hpos:Get2DDistance(pos)
                  local delta3D = hpos:Get3DDistance(pos)
                  if self.testing then
                    self:I(string.format("Cargo relative position: 2D %dm | 3D %dm",delta2D,delta3D))
                    self:I(string.format("Helo dimension: length %dm | width %dm | rope %dm",dimensions.length,dimensions.width,dimensions.ropelength))
                  end
                  if delta2D > dimensions.length or delta2D > dimensions.width or delta3D > dimensions.ropelength then
                    isunloaded = true
                  end
                end
              end
            end        
          end
          if isunloaded then
            self:I(self.lid.." moved! LOADED -> UNLOADED")
            self.CargoState = DYNAMICCARGO.State.UNLOADED
            _DATABASE:CreateEventDynamicCargoUnloaded(self)
          end
        end
      end
      self.LastPosition = pos
    end
    -- come back laters
    self:ScheduleOnce(self.Interval,DYNAMICCARGO._UpdatePosition,self)
  else
    -- we are dead
    self:I(self.lid.." dead! " ..self.CargoState.."-> REMOVED")
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
