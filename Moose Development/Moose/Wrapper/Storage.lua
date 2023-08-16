--- **Wrapper** - Warehouse storage of DCS airbases.
--
-- ## Main Features:
--
--    * Convenient access to DCS API functions
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Wrapper%20-%20Storage).
--
-- ===
--
-- ### Author: **funkyfranky**
--
-- ===
-- @module Wrapper.Storage
-- @image Wrapper_Storage.png


--- STORAGE class.
-- @type STORAGE
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field DCS#Warehouse warehouse The DCS warehouse object.
-- @field DCS#Airbase airbase The DCS airbase object.
-- @extends Core.Base#BASE

--- *The capitalist cannot store labour-power in warehouses after he has bought it, as he may do with the raw material.* -- Karl Marx
--
-- ===
--
-- # The STORAGE Concept
-- 
-- The STORAGE class offers an easy-to-use wrapper interface to all DCS API functions of DCS warehouses. We named the class STORAGE, because the name WAREHOUSE is already taken by another MOOSE class.
-- 
-- This class allows you to add and remove items to a DCS warehouse, such as aircraft, weapons and liquids.
-- 
-- # Constructor
-- 
-- A DCS warehouse is associated with an airbase. Therefore, to get the storage, you need to pass the airbase name as parameter:
-- 
--     -- Create a STORAGE instance of the Batumi warehouse  
--     local storage=STORAGE:New("Batumi")
-- 
--
-- @field #STORAGE
STORAGE = {
  ClassName          = "STORAGE",
  verbose            =     0,
}

--- Liquid types.
-- @type STORAGE.Liquid
-- @field #number JETFUEL Jet fuel.
-- @field #number GASOLINE Aviation gasoline.
-- @field #number MW50 MW50.
-- @field #number DIESEL Diesel.
STORAGE.Liquid = {
  JETFUEL = 0,
  GASOLINE = 1,
  MW50 = 2,
  DIESEL = 3,
}

--- STORAGE class version.
-- @field #string version
STORAGE.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- TODO: Persistence

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new STORAGE object from the DCS weapon object.
-- @param #STORAGE self
-- @param #string AirbaseName Name of the airbase.
-- @return #STORAGE self
function STORAGE:New(AirbaseName)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, BASE:New()) -- #STORAGE

  self.airbase=Airbase.getByName(AirbaseName)

  self.warehouse=self.airbase:getWarehouse()


  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User API Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set verbosity level.
-- @param #STORAGE self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #STORAGE self
function STORAGE:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end


--- Adds the passed amount of a given item to the warehouse.
-- @param #STORAGE self
-- @param #string Name Name of the item to add.
-- @param #number Amount Amount of items to add.
-- @return #STORAGE self
function STORAGE:AddItem(Name, Amount)

  self:T(self.lid..string.format("Adding %d items of %s", Amount, Name))

  self.warehouse:addItem(Name, Amount)

  return self
end


--- Sets the specified amount of a given item to the warehouse.
-- @param #STORAGE self
-- @param #string Name Name of the item.
-- @param #number Amount Amount of items.
-- @return #STORAGE self
function STORAGE:SetItem(Name, Amount)

  self:T(self.lid..string.format("Setting item %s to N=%d", Name, Amount))

  self.warehouse:setItem(Name, Amount)

  return self
end

--- Gets the amount of a given item currently present the warehouse.
-- @param #STORAGE self
-- @param #string Name Name of the item.
-- @return #number Amount of items.
function STORAGE:GetItemAmount(Name)

  local N=self.warehouse:getItemCount(Name)

  return N
end



--- Removes the amount of the passed item from the warehouse.
-- @param #STORAGE self
-- @param #string Name Name of the item.
-- @param #number Amount Amount of items.
-- @return #STORAGE self
function STORAGE:RemoveItem(Name, Amount)

  self:T(self.lid..string.format("Removing N=%d of item %s", Amount, Name))

  self.warehouse:removeItem(Name, Amount)

  return self
end




--- Adds the passed amount of a given liquid to the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid.
-- @param #number Amount Amount of liquid to add.
-- @return #STORAGE self
function STORAGE:AddLiquid(Type, Amount)

  self:T(self.lid..string.format("Adding %d liquids of %s", Amount, Type))

  self.warehouse:addLiquid(Name, Amount)

  return self
end


--- Sets the specified amount of a given liquid to the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid.
-- @param #number Amount Amount of liquid.
-- @return #STORAGE self
function STORAGE:SetLiquid(Type, Amount)

  self:T(self.lid..string.format("Setting liquid %s to N=%d", Type, Amount))

  self.warehouse:setLiquid(Type, Amount)

  return self
end

--- Removes the amount of the passed liquid from the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid.
-- @param #number Amount Amount of liquid to remove.
-- @return #STORAGE self
function STORAGE:RemoveLiquid(Type, Amount)

  self:T(self.lid..string.format("Removing N=%d of liquid %s", Amount, Type))

  self.warehouse:removeLiquid(Type, Amount)

  return self
end

--- Gets the amount of a given liquid currently present the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid.
-- @return #number Amount of liquid.
function STORAGE:GetLiquidAmount(Type)

  local N=self.warehouse:getLiquidAmount(Type)

  return N
end


--- Returns a full itemized list of everything currently in a warehouse. If a category is set to unlimited then the table will be returned empty.
-- @param #STORAGE self
-- @param #string Item Name of item as #string or type of liquid as #number.
-- @return #table Table of aircraft. Table is emtpy `{}` if number of aircraft is set to be unlimited.
-- @return #table Table of liquids. Table is emtpy `{}` if number of liquids is set to be unlimited.
-- @return #table Table of weapons. Table is emtpy `{}` if number of liquids is set to be unlimited.
function STORAGE:GetInventory(Item)

  local inventory=self.warehouse:getInventory(Item)
  
  return inventory.aircraft, inventory.liquids, inventory.weapon
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
