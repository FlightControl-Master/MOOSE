--- **Wrapper** - Dynamic Cargo create from the F8 menu.
--
-- ## Main Features:
--
--    * Convenient access to Ground Crew created cargo items.
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_Demos/tree/master/).
--
-- ===
--
-- ### Author: **Applevangelist**; additional checks **Chesster**
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
-- @field #number Interval Check interval. 5 secs default.
-- @field #boolean testing
-- @field Core.Timer#TIMER timer Compatibility field; updates are handled by one class-wide scheduler.
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
  Interval           = 5,
  C130AttachDistance = 10,
  C130DetachDistance = 14,
  C130AirborneAGL = 8,
  C130LandedAGL = 0.5,
  C130StabilityEpsilon = 0.05,
  C130RequireAirborne = true,
  C130OwnerResolveMove2D = 10,
  C130OwnerResolveNear2D = 4,
  C130OwnerResolveMax3D = 250,
  
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
  ["Mi-8MTV2"] = "Mi-8MTV2",
  ["Mi-8MT"] = "Mi-8MT",
  ["UH-1H"] = "UH-1H",
  ["Mi-24P"] = "Mi-24P",
  ["UH-60L"] = "UH-60L",
  ["UH-60L_DAP"] = "UH-60L_DAP",
  ["C-130J-30"] = "C-130J-30",
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
  ["Mi-8MTV2"] = {
    ["width"] = 6,
    ["height"] = 6,
    ["length"] = 15,
    ["ropelength"] = 30,
  },
  ["Mi-8MT"] = {
    ["width"] = 6,
    ["height"] = 6,
    ["length"] = 15,
    ["ropelength"] = 30,
  },
  ["UH-1H"] = {
    ["width"] = 4,
    ["height"] = 4,
    ["length"] = 9,
    ["ropelength"] = 25,
  },
  ["Mi-24P"] = {
    ["width"] = 4,
    ["height"] = 5,
    ["length"] = 11,
    ["ropelength"] = 25,
  },
  ["UH-60L"] = {
    ["width"] = 4,
    ["height"] = 5,
    ["length"] = 10,
    ["ropelength"] = 25,
  },
  ["UH-60L_DAP"] = {
    ["width"] = 4,
    ["height"] = 5,
    ["length"] = 10,
    ["ropelength"] = 25,
  },
  ["C-130J-30"] = {
    ["width"] = 4,
    ["height"] = 12,
    ["length"] = 35,
    ["ropelength"] = 0,
    ["attach"] = 10,
    ["detach"] = 14,
  },
}

--- DYNAMICCARGO class version.
-- @field #string version
DYNAMICCARGO.version="0.1.0"
DYNAMICCARGO._TrackedCargo = DYNAMICCARGO._TrackedCargo or {}
DYNAMICCARGO._GlobalTimer = DYNAMICCARGO._GlobalTimer or nil
DYNAMICCARGO._GlobalTimerInterval = DYNAMICCARGO._GlobalTimerInterval or nil

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- DONE: Added Mi-8 type and dimensions

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
  self._spawnVec3 = self.LastPosition and self.LastPosition:GetVec3() or nil
  
  self.CargoState = DYNAMICCARGO.State.NEW
  self._attached = false
  self._detached = false
  self._wasAirborne = false
  self._landAglConfirm = nil
  self._ownerResolved = false
  self._carrierUnitName = nil
  self._carrierGroupName = nil
  self._carrierTypeName = nil
  
  self.Interval = DYNAMICCARGO.Interval or 10
  
  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
    local warehouse = STORAGE:NewFromDynamicCargo(CargoName)
    self.warehouse = warehouse
  end
  
  self.lid = string.format("DYNAMICCARGO %s", CargoName)
  
  self.Owner = string.match(CargoName,"^(.+)|%d%d:%d%d|PKG%d+") or "None"

  -- Keep a compatibility field, while updates are driven by one class-wide scheduler.
  self.timer = nil
  DYNAMICCARGO._TrackCargo(self)
  
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
  local DCSStatic = StaticObject.getByName( self.StaticName ) or Unit.getByName( self.StaticName ) 
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
  if self.CargoState and self.CargoState == DYNAMICCARGO.State.UNLOADED then
    return true
  else
    return false
  end
end

--- Returns true if the cargo has been removed.
-- @param #DYNAMICCARGO self
-- @return #boolean Outcome
function DYNAMICCARGO:IsRemoved()
  if self.CargoState and self.CargoState == DYNAMICCARGO.State.REMOVED then
    return true
  else
    return false
  end
end

--- Returns true if this cargo is attached to a detected carrier.
-- @param #DYNAMICCARGO self
-- @return #boolean Outcome
function DYNAMICCARGO:IsAttached()
  return self._attached == true
end

--- Returns true if this cargo was detached from a detected carrier.
-- @param #DYNAMICCARGO self
-- @return #boolean Outcome
function DYNAMICCARGO:IsDetached()
  return self._detached == true
end

--- Returns true if this cargo has seen airborne transport in this cycle.
-- @param #DYNAMICCARGO self
-- @return #boolean Outcome
function DYNAMICCARGO:WasAirborneTransport()
  return self._wasAirborne == true
end

--- Returns true if this cargo has reached landed stable confirmation.
-- @param #DYNAMICCARGO self
-- @return #boolean Outcome
function DYNAMICCARGO:IsLandedStable()
  return self.CargoState == DYNAMICCARGO.State.UNLOADED and self._detached == true
end

--- Returns last known carrier unit name.
-- @param #DYNAMICCARGO self
-- @return #string Unit name
function DYNAMICCARGO:GetCarrierUnitName()
  return self._carrierUnitName
end

--- Returns last known carrier type name.
-- @param #DYNAMICCARGO self
-- @return #string Type name
function DYNAMICCARGO:GetCarrierTypeName()
  return self._carrierTypeName
end

--- Returns last known carrier group name.
-- @param #DYNAMICCARGO self
-- @return #string Group name
function DYNAMICCARGO:GetCarrierGroupName()
  return self._carrierGroupName
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

--- [Internal] Check whether an aircraft typename is a C-130J for special handling.
-- @param #DYNAMICCARGO self
-- @param #string TypeName
-- @return #boolean Outcome
function DYNAMICCARGO:_IsC130Type(TypeName)
  return TypeName == "C-130J-30"
end

--- [Internal] Safe AGL calculation helper.
-- @param #DYNAMICCARGO self
-- @param Core.Point#COORDINATE Coord
-- @return #number AGL in meters
function DYNAMICCARGO:_GetAGL(Coord)
  if not Coord then return -1 end
  return (Coord.y or 0) - Coord:GetLandHeight()
end

--- [Internal] Resolve player name for a client.
-- @param #DYNAMICCARGO self
-- @param Wrapper.Client#CLIENT Client
-- @return #string Player name
function DYNAMICCARGO:_GetPlayerNameForClient(Client)
  if not Client then return self.Owner or "None" end
  return Client:GetPlayerName() or _DATABASE:_FindPlayerNameByUnitName(Client:GetName()) or self.Owner or "None"
end

--- [Internal] Store current carrier identity fields.
-- @param #DYNAMICCARGO self
-- @param Wrapper.Client#CLIENT Client
-- @param #string PlayerName
-- @return #DYNAMICCARGO self
function DYNAMICCARGO:_SetCarrierFromClient(Client, PlayerName)
  if not Client then return self end
  self._carrierUnitName = Client:GetName() or self._carrierUnitName
  self._carrierTypeName = Client:GetTypeName() or self._carrierTypeName
  local grp = Client:GetGroup()
  if grp then
    self._carrierGroupName = grp:GetName() or self._carrierGroupName
  end
  self.Owner = PlayerName or self:_GetPlayerNameForClient(Client)
  return self
end

--- [Internal] Get scheduler interval for global dynamic cargo updates.
-- @return #number Interval in seconds
function DYNAMICCARGO._GetSchedulerInterval()
  return DYNAMICCARGO.Interval or 5
end

--- [Internal] Count currently tracked dynamic cargo objects.
-- @return #number Count
function DYNAMICCARGO._CountTracked()
  local n = 0
  for _,_ in pairs(DYNAMICCARGO._TrackedCargo or {}) do
    n = n + 1
  end
  return n
end

--- [Internal] Stop global scheduler when no tracked cargo remains.
function DYNAMICCARGO._StopGlobalSchedulerIfIdle()
  if DYNAMICCARGO._CountTracked() > 0 then
    return
  end
  if DYNAMICCARGO._GlobalTimer and DYNAMICCARGO._GlobalTimer:IsRunning() then
    DYNAMICCARGO._GlobalTimer:Stop()
  end
  DYNAMICCARGO._GlobalTimer = nil
  DYNAMICCARGO._GlobalTimerInterval = nil
end

--- [Internal] Ensure global scheduler is running for tracked cargo updates.
function DYNAMICCARGO._EnsureGlobalScheduler()
  local interval = DYNAMICCARGO._GetSchedulerInterval()
  if DYNAMICCARGO._GlobalTimer and DYNAMICCARGO._GlobalTimer:IsRunning() then
    if DYNAMICCARGO._GlobalTimerInterval == interval then
      return
    end
    DYNAMICCARGO._GlobalTimer:Stop()
    DYNAMICCARGO._GlobalTimer = nil
    DYNAMICCARGO._GlobalTimerInterval = nil
  end
  if DYNAMICCARGO._CountTracked() < 1 then
    return
  end
  DYNAMICCARGO._GlobalTimer = TIMER:New(DYNAMICCARGO._UpdateAllTracked)
  DYNAMICCARGO._GlobalTimer:Start(interval, interval)
  DYNAMICCARGO._GlobalTimerInterval = interval
end

--- [Internal] Add one dynamic cargo object to global tracking.
-- @param #DYNAMICCARGO Cargo
function DYNAMICCARGO._TrackCargo(Cargo)
  if not Cargo or not Cargo.StaticName then
    return
  end
  DYNAMICCARGO._TrackedCargo = DYNAMICCARGO._TrackedCargo or {}
  DYNAMICCARGO._TrackedCargo[Cargo.StaticName] = Cargo
  DYNAMICCARGO._EnsureGlobalScheduler()
end

--- [Internal] Remove one dynamic cargo object from global tracking.
-- @param #string CargoName
function DYNAMICCARGO._UntrackCargo(CargoName)
  if not CargoName or not DYNAMICCARGO._TrackedCargo then
    DYNAMICCARGO._StopGlobalSchedulerIfIdle()
    return
  end
  DYNAMICCARGO._TrackedCargo[CargoName] = nil
  DYNAMICCARGO._StopGlobalSchedulerIfIdle()
end

--- [Internal] Update all tracked dynamic cargo objects in one scheduler tick.
function DYNAMICCARGO._UpdateAllTracked()
  local tracked = DYNAMICCARGO._TrackedCargo or {}
  local names = {}
  for name,_ in pairs(tracked) do
    names[#names + 1] = name
  end
  for _,name in ipairs(names) do
    local cargo = tracked[name]
    if cargo then
      cargo:_UpdatePosition()
    end
  end
  DYNAMICCARGO._StopGlobalSchedulerIfIdle()
end

--- [Internal] Find tracked client by unit name in current dynamic cargo helo set.
-- @param #DYNAMICCARGO self
-- @param #string UnitName
-- @return Wrapper.Client#CLIENT Client
function DYNAMICCARGO:_FindClientByUnitName(UnitName)
  if not UnitName or UnitName == "" or not _DYNAMICCARGO_HELOS then return nil end
  for _,_helo in pairs(_DYNAMICCARGO_HELOS:GetAliveSet() or {}) do
    local helo = _helo -- Wrapper.Client#CLIENT
    if helo and helo:IsAlive() and helo:GetName() == UnitName then
      return helo
    end
  end
  return nil
end

--- [Internal] Get best known carrier client from stored names/owner.
-- @param #DYNAMICCARGO self
-- @return Wrapper.Client#CLIENT Client
function DYNAMICCARGO:_GetKnownCarrierClient()
  local client = nil
  if self._carrierUnitName then
    client = self:_FindClientByUnitName(self._carrierUnitName)
  end
  if (not client) and self.Owner and self.Owner ~= "None" then
    local byPlayer = CLIENT:FindByPlayerName(self.Owner)
    if byPlayer and byPlayer:IsAlive() then
      client = byPlayer
    end
  end
  return client
end

--- [Internal] Find nearest live C-130 client.
-- @param #DYNAMICCARGO self
-- @param Core.Point#COORDINATE Pos
-- @param #number Max3D Maximum 3D distance
-- @return Wrapper.Client#CLIENT Client
-- @return #string PlayerName
-- @return #number Dist2D
-- @return #number Dist3D
function DYNAMICCARGO:_FindNearestC130(Pos, Max3D)
  if not Pos or not _DYNAMICCARGO_HELOS then return nil, nil, nil, nil end
  local bestClient = nil
  local bestName = nil
  local best2D = math.huge
  local best3D = math.huge
  local bestOwnerMatch = false
  local max3D = Max3D or DYNAMICCARGO.C130OwnerResolveMax3D
  local preferredOwner = self.Owner
  if preferredOwner == "" or preferredOwner == "None" then
    preferredOwner = nil
  end
  for _,_helo in pairs(_DYNAMICCARGO_HELOS:GetAliveSet() or {}) do
    local helo = _helo -- Wrapper.Client#CLIENT
    if helo and helo:IsAlive() then
      local typename = helo:GetTypeName()
      if self:_IsC130Type(typename) then
        local hpos = helo:GetCoordinate()
        if hpos then
          local d3 = hpos:Get3DDistance(Pos)
          if d3 <= max3D then
            local d2 = hpos:Get2DDistance(Pos)
            local pname = self:_GetPlayerNameForClient(helo)
            local ownerMatch = preferredOwner and pname and pname == preferredOwner or false
            if (ownerMatch and not bestOwnerMatch) or ((ownerMatch == bestOwnerMatch) and d3 < best3D) then
              bestClient = helo
              bestName = pname
              best2D = d2
              best3D = d3
              bestOwnerMatch = ownerMatch
            end
          end
        end
      end
    end
  end
  return bestClient, bestName, best2D, best3D
end

--- [Internal] Resolve/rebind owner to nearest valid C-130 after movement from spawn.
-- @param #DYNAMICCARGO self
-- @param Core.Point#COORDINATE Pos
-- @return Wrapper.Client#CLIENT Client
function DYNAMICCARGO:_ResolveC130Owner(Pos)
  if not Pos or not self._spawnVec3 then return nil end
  local moved2D = UTILS.VecDist2D(Pos, self._spawnVec3)
  if moved2D < (DYNAMICCARGO.C130OwnerResolveMove2D or 10) then
    return nil
  end
  local max3D = DYNAMICCARGO.C130OwnerResolveMax3D or 250
  local known = self:_GetKnownCarrierClient()
  if known and known:IsAlive() and self:_IsC130Type(known:GetTypeName()) then
    local kpos = known:GetCoordinate()
    if kpos and kpos:Get3DDistance(Pos) <= max3D then
      self:_SetCarrierFromClient(known)
      return known
    end
  end
  local nearest, playerName, d2 = self:_FindNearestC130(Pos, DYNAMICCARGO.C130OwnerResolveMax3D)
  if nearest and d2 and d2 <= (DYNAMICCARGO.C130OwnerResolveNear2D or 4) then
    self:_SetCarrierFromClient(nearest, playerName)
    self._ownerResolved = true
    self:T(self.lid.." C130 owner re-resolved to "..tostring(self._carrierUnitName).." / "..tostring(self.Owner))
    return nearest
  end
  return nil
end

--- [Internal] Determine whether to run C-130 transport-state handling for this cargo tick.
-- @param #DYNAMICCARGO self
-- @param Core.Point#COORDINATE Pos
-- @return #boolean Outcome
function DYNAMICCARGO:_ShouldUseC130State(Pos)
  if self:_IsC130Type(self._carrierTypeName) then
    return true
  end
  local known = self:_GetKnownCarrierClient()
  if known and self:_IsC130Type(known:GetTypeName()) then
    self:_SetCarrierFromClient(known)
    return true
  end
  if self._attached or self._detached or self._wasAirborne then
    return true
  end
  if self.CargoState == DYNAMICCARGO.State.NEW or self.CargoState == DYNAMICCARGO.State.UNLOADED then
    local nearest, _, d2 = self:_FindNearestC130(Pos, DYNAMICCARGO.C130AttachDistance + 50)
    if nearest and d2 and d2 <= (DYNAMICCARGO.C130AttachDistance + 5) then
      return true
    end
  end
  return false
end

--- [Internal] C-130-specific transport state update.
-- @param #DYNAMICCARGO self
-- @param Core.Point#COORDINATE Pos
-- @return #DYNAMICCARGO self
function DYNAMICCARGO:_UpdatePositionC130(Pos)
  local attachDist = DYNAMICCARGO.C130AttachDistance or 10
  local detachDist = DYNAMICCARGO.C130DetachDistance or 14
  local airborneAgl = DYNAMICCARGO.C130AirborneAGL or 8
  local landedAgl = DYNAMICCARGO.C130LandedAGL or 0.5
  local stableEps = DYNAMICCARGO.C130StabilityEpsilon or 0.05
  local requireAirborne = DYNAMICCARGO.C130RequireAirborne ~= false

  local cargoAgl = self:_GetAGL(Pos)
  local carrier = self:_GetKnownCarrierClient()
  if carrier and not self:_IsC130Type(carrier:GetTypeName()) then
    carrier = nil
  end
  if not carrier then
    carrier = self:_ResolveC130Owner(Pos)
  end

  -- Attach detection: grounded C-130 close to cargo.
  if (self.CargoState == DYNAMICCARGO.State.NEW or self.CargoState == DYNAMICCARGO.State.UNLOADED) and (not self._attached) then
    if not carrier then
      local nearest, pname, d2 = self:_FindNearestC130(Pos, DYNAMICCARGO.C130OwnerResolveMax3D)
      if nearest and d2 and d2 <= attachDist and not nearest:InAir() then
        carrier = nearest
        self:_SetCarrierFromClient(nearest, pname)
      end
    end
    if carrier and carrier:IsAlive() then
      local hpos = carrier:GetCoordinate()
      if hpos and (not carrier:InAir()) and hpos:Get2DDistance(Pos) <= attachDist then
        self._attached = true
        self._detached = false
        self._wasAirborne = false
        self._landAglConfirm = nil
        self:_SetCarrierFromClient(carrier)
        if self.CargoState ~= DYNAMICCARGO.State.LOADED then
          self.CargoState = DYNAMICCARGO.State.LOADED
          self:T(self.lid.." C130 attach: "..tostring(self.Owner))
          _DATABASE:CreateEventDynamicCargoLoaded(self)
        end
      end
    end
  end

  if self.CargoState == DYNAMICCARGO.State.LOADED then
    if not carrier then
      carrier = self:_ResolveC130Owner(Pos)
    end
    local carrierInAir = false
    local dist2D = math.huge
    local carrierAgl = -1
    if carrier and carrier:IsAlive() then
      local hpos = carrier:GetCoordinate()
      if hpos then
        dist2D = hpos:Get2DDistance(Pos)
        carrierAgl = self:_GetAGL(hpos)
      end
      carrierInAir = carrier:InAir()
      self:_SetCarrierFromClient(carrier)
    end

    if cargoAgl >= airborneAgl or carrierAgl >= airborneAgl then
      self._wasAirborne = true
    end

    -- Detach only when actually airborne and separated.
    if self._attached and carrierInAir and dist2D > detachDist then
      self._attached = false
      self._detached = true
      self._landAglConfirm = nil
      self:T(self.lid.." C130 detach at d2="..tostring(UTILS.Round(dist2D,2)))
    end

    -- Fallback detach if carrier reference is stale but cargo already transitioned airborne.
    if self._attached and (not carrier or not carrier:IsAlive()) and self._wasAirborne and cargoAgl <= airborneAgl then
      self._attached = false
      self._detached = true
      self._landAglConfirm = nil
      self:T(self.lid.." C130 detach fallback (carrier stale)")
    end

    local canUnload = self._detached and ((not requireAirborne) or self._wasAirborne)
    if canUnload then
      local moved3D = self.LastPosition and UTILS.VecDist3D(Pos, self.LastPosition) or math.huge
      local stable = moved3D <= stableEps
      if cargoAgl <= landedAgl and stable then
        if self._landAglConfirm then
          self.CargoState = DYNAMICCARGO.State.UNLOADED
          self:T(self.lid.." C130 landed-stable unload by "..tostring(self.Owner))
          _DATABASE:CreateEventDynamicCargoUnloaded(self)
        else
          self._landAglConfirm = true
        end
      else
        self._landAglConfirm = nil
      end
    end
  end

  return self
end

--- [Internal] _Get helo hovering intel
-- @param #DYNAMICCARGO self
-- @param Wrapper.Unit#UNIT Unit The Unit to test
-- @param #number ropelength Ropelength to test
-- @return #boolean Outcome
function DYNAMICCARGO:_HeloHovering(Unit,ropelength)
    local DCSUnit = Unit:GetDCSObject() --DCS#Unit
    local hovering = false
    local Height = 0
    if DCSUnit then
        local UnitInAir = DCSUnit:inAir()
        local UnitCategory = DCSUnit:getDesc().category       
        if UnitInAir == true and UnitCategory == 1 then
            local VelocityVec3 = DCSUnit:getVelocity()
            local Velocity = UTILS.VecNorm(VelocityVec3)
            local Coordinate = DCSUnit:getPoint()
            local LandHeight = land.getHeight({ x = Coordinate.x, y = Coordinate.z })
            Height = Coordinate.y - LandHeight
            if Velocity < 1 and Height <= ropelength and Height > 6 then -- hover lower than ropelength but higher than the normal FARP height.
                hovering = true
            end
        end
        return hovering, Height
    end
    return false
end

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
    -- TODO Check unloading via sling load?
    local typename = helo:GetTypeName()
    if not self:_IsC130Type(typename) then
      local dimensions = DYNAMICCARGO.AircraftDimensions[typename]
      if hpos and typename and dimensions then
        local hovering, height = self:_HeloHovering(helo,dimensions.ropelength)
        local helolanded = not helo:InAir()
        self:T(self.lid.." InAir: AGL/Hovering: "..hpos.y-hpos:GetLandHeight().."/"..tostring(hovering))
        local delta2D = hpos:Get2DDistance(pos)
        local delta3D = hpos:Get3DDistance(pos)
        if self.testing then
          self:T(string.format("Cargo relative position: 2D %dm | 3D %dm",delta2D,delta3D))
          self:T(string.format("Helo dimension: length %dm | width %dm | rope %dm",dimensions.length,dimensions.width,dimensions.ropelength))
          self:T(string.format("Helo hovering: %s at %dm",tostring(hovering),height))
        end
        -- unloading from ground
        if loading~=true and (delta2D > dimensions.length or delta2D > dimensions.width) and helolanded then  -- Theoretically the cargo could still be attached to the sling if landed next to the cargo. But once moved again it would go back into loaded state once lifted again.
          success = true
          Helo = helo
          Playername = name
        end
        -- unloading from hover/rope
        if loading~=true and delta3D > dimensions.ropelength then     
          success = true
          Helo = helo
          Playername = name
        end
        -- loading
        if loading == true and ((delta2D < dimensions.length and delta2D < dimensions.width and helolanded) or (delta3D == dimensions.ropelength and helo:InAir())) then -- Loaded via ground or sling                  
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
    local moved = UTILS.Round(UTILS.VecDist3D(pos,self.LastPosition),2) > 0.5
    if self:_ShouldUseC130State(pos) then
      self:_UpdatePositionC130(pos)
      self.LastPosition = pos
    elseif moved then      -- This checks if the cargo has moved more than 0.5m since last check. If so then the cargo is loaded
        ---------------
        -- LOAD Cargo
        ---------------
        if self.CargoState == DYNAMICCARGO.State.NEW or self.CargoState == DYNAMICCARGO.State.UNLOADED then
          local isloaded, client, playername = self:_GetPossibleHeloNearby(pos,true)
          if isloaded then
            self:T(self.lid.." moved! NEW -> LOADED by "..tostring(playername))
            self.CargoState = DYNAMICCARGO.State.LOADED
            self.Owner = playername
            if client then
              self:_SetCarrierFromClient(client, playername)
            end
            _DATABASE:CreateEventDynamicCargoLoaded(self)
          end
        end
        self.LastPosition = pos
      ---------------
      -- UNLOAD Cargo
      ---------------
      --  If the cargo is stationary then we need to end this condition here to check whether it is unloaded or still onboard or still hooked if anyone can hover that precisly
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
        if count > 0 then
          self:T(self.lid.." Possible alive helos: "..count or -1)
            isunloaded, client, playername = self:_GetPossibleHeloNearby(pos,false)
          if isunloaded then
            self:T(self.lid.." moved! LOADED -> UNLOADED by "..tostring(playername))
            self.CargoState = DYNAMICCARGO.State.UNLOADED
            self.Owner = playername
            if client then
              self:_SetCarrierFromClient(client, playername)
            end
            _DATABASE:CreateEventDynamicCargoUnloaded(self)
          end
        end
      end
  else
    ---------------
    -- REMOVED Cargo
    --------------- 
    if self.CargoState ~= DYNAMICCARGO.State.REMOVED then
      DYNAMICCARGO._UntrackCargo(self.StaticName)
      self.timer=nil
      self:T(self.lid.." dead! " ..self.CargoState.."-> REMOVED")
      self.CargoState = DYNAMICCARGO.State.REMOVED
      _DATABASE:CreateEventDynamicCargoRemoved(self)
    end
  end
  return self
end

--- [USER] Destroy a DYNAMICCARGO object.
-- @param #DYNAMICCARGO self
-- @param #boolean GenerateEvent Set to false to remove an item silently. Defaults to true.
-- @return #boolean Return Returns nil if the object could not be found, else returns true.
function DYNAMICCARGO:Destroy(GenerateEvent)
  local DCSObject = self:GetDCSObject()
  if DCSObject then
    local GenerateEvent = (GenerateEvent ~= nil and GenerateEvent == false) and false or true
    if GenerateEvent and GenerateEvent == true then
        self:CreateEventDead( timer.getTime(), DCSObject )
    end  
    DCSObject:destroy()
    self:_UpdatePosition()
    return true
  end
  return nil
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
