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
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Wrapper/Storage).
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
-- The STORAGE class offers an easy-to-use wrapper interface to all DCS API functions of DCS warehouses. 
-- We named the class STORAGE, because the name WAREHOUSE is already taken by another MOOSE class.
-- 
-- This class allows you to add and remove items to a DCS warehouse, such as aircraft, liquids, weapons and other equipment.
-- 
-- # Constructor
-- 
-- A DCS warehouse is associated with an airbase. Therefore, a `STORAGE` instance is automatically created, once an airbase is registered and added to the MOOSE database.
-- 
-- You can get the `STORAGE` object from the 
-- 
--     -- Create a STORAGE instance of the Batumi warehouse  
--     local storage=STORAGE:FindByName("Batumi")
-- 
-- An other way to get the `STORAGE` object is to retrieve it from the AIRBASE function `AIRBASE:GetStorage()`
-- 
--     -- Get storage instance of Batumi airbase
--     local Batumi=AIRBASE:FindByName("Batumi")
--     local storage=Batumi:GetStorage()
-- 
-- # Aircraft, Weapons and Equipment
-- 
-- ## Adding Items
-- 
-- To add aircraft, weapons and/or othe equipment, you can use the @{#STORAGE.AddItem}() function
-- 
--     storage:AddItem("A-10C", 3)
--     storage:AddItem("weapons.missiles.AIM_120C", 10)
--     
-- This will add three A-10Cs and ten AIM-120C missiles to the warehouse inventory.
-- 
-- ## Setting Items
-- 
-- You can also explicitly set, how many items are in the inventory with the @{#STORAGE.SetItem}() function.
-- 
-- ## Removing Items
-- 
-- Items can be removed from the inventory with the @{#STORAGE.RemoveItem}() function.
-- 
-- ## Getting Amount
-- 
-- The number of items currently in the inventory can be obtained with the @{#STORAGE.GetItemAmount}() function
-- 
--     local N=storage:GetItemAmount("A-10C")
--     env.info(string.format("We currently have %d A-10Cs available", N))
-- 
-- # Liquids
-- 
-- Liquids can be added and removed by slightly different functions as described below. Currently there are four types of liquids
-- 
-- * Jet fuel `STORAGE.Liquid.JETFUEL`
-- * Aircraft gasoline `STORAGE.Liquid.GASOLINE`
-- * MW 50 `STORAGE.Liquid.MW50`
-- * Diesel `STORAGE.Liquid.DIESEL`
-- 
-- ## Adding Liquids
-- 
-- To add a certain type of liquid, you can use the @{#STORAGE.AddItem}(Type, Amount) function
-- 
--     storage:AddLiquid(STORAGE.Liquid.JETFUEL, 10000)
--     storage:AddLiquid(STORAGE.Liquid.DIESEL, 20000)
-- 
-- This will add 10,000 kg of jet fuel and 20,000 kg of diesel to the inventory.
-- 
-- ## Setting Liquids
-- 
-- You can also explicitly set the amount of liquid with the @{#STORAGE.SetLiquid}(Type, Amount) function.
-- 
-- ## Removing Liquids
-- 
-- Liquids can be removed with @{#STORAGE.RemoveLiquid}(Type, Amount) function.
-- 
-- ## Getting Amount
-- 
-- The current amount of a certain liquid can be obtained with the @{#STORAGE.GetLiquidAmount}(Type) function
-- 
--     local N=storage:GetLiquidAmount(STORAGE.Liquid.DIESEL)
--     env.info(string.format("We currently have %d kg of Diesel available", N))
--     
-- 
-- # Inventory
-- 
-- The current inventory of the warehouse can be obtained with the @{#STORAGE.GetInventory}() function. This returns three tables with the aircraft, liquids and weapons:
-- 
--     local aircraft, liquids, weapons=storage:GetInventory()
--     
--     UTILS.PrintTableToLog(aircraft)
--     UTILS.PrintTableToLog(liquids)
--     UTILS.PrintTableToLog(weapons)
--
-- @field #STORAGE
STORAGE = {
  ClassName          = "STORAGE",
  verbose            =     0,
}

--- Liquid types.
-- @type STORAGE.Liquid
-- @field #number JETFUEL Jet fuel (0).
-- @field #number GASOLINE Aviation gasoline (1).
-- @field #number MW50 MW50 (2).
-- @field #number DIESEL Diesel (3).
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

  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New()) -- #STORAGE

  self.airbase=Airbase.getByName(AirbaseName)

  self.warehouse=self.airbase:getWarehouse()

  self.lid = string.format("STORAGE %s", AirbaseName)

  return self
end


--- Find a STORAGE in the **_DATABASE** using the name associated airbase.
-- @param #STORAGE self
-- @param #string AirbaseName The Airbase Name.
-- @return #STORAGE self
function STORAGE:FindByName( AirbaseName )
  local storage = _DATABASE:FindStorage( AirbaseName )
  return storage
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

  self:T(self.lid..string.format("Adding %d items of %s", Amount, UTILS.OneLineSerialize(Name)))

  self.warehouse:addItem(Name, Amount)

  return self
end


--- Sets the specified amount of a given item to the warehouse.
-- @param #STORAGE self
-- @param #string Name Name of the item.
-- @param #number Amount Amount of items.
-- @return #STORAGE self
function STORAGE:SetItem(Name, Amount)

  self:T(self.lid..string.format("Setting item %s to N=%d", UTILS.OneLineSerialize(Name), Amount))

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

  self:T(self.lid..string.format("Adding %d liquids of %s", Amount, self:GetLiquidName(Type)))

  self.warehouse:addLiquid(Type, Amount)

  return self
end


--- Sets the specified amount of a given liquid to the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid.
-- @param #number Amount Amount of liquid.
-- @return #STORAGE self
function STORAGE:SetLiquid(Type, Amount)

  self:T(self.lid..string.format("Setting liquid %s to N=%d", self:GetLiquidName(Type), Amount))

  self.warehouse:setLiquidAmount(Type, Amount)

  return self
end

--- Removes the amount of the given liquid type from the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid.
-- @param #number Amount Amount of liquid in kg to be removed.
-- @return #STORAGE self
function STORAGE:RemoveLiquid(Type, Amount)

  self:T(self.lid..string.format("Removing N=%d of liquid %s", Amount, self:GetLiquidName(Type)))

  self.warehouse:removeLiquid(Type, Amount)

  return self
end

--- Gets the amount of a given liquid currently present the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid.
-- @return #number Amount of liquid in kg.
function STORAGE:GetLiquidAmount(Type)

  local N=self.warehouse:getLiquidAmount(Type)

  return N
end

--- Returns the name of the liquid from its numeric type.
-- @param #STORAGE self
-- @param #number Type Type of liquid.
-- @return #string Name of the liquid.
function STORAGE:GetLiquidName(Type)

  local name="Unknown"
  
  if Type==STORAGE.Liquid.JETFUEL then
    name = "Jet fuel"
  elseif Type==STORAGE.Liquid.GASOLINE then
    name = "Aircraft gasoline"
  elseif Type==STORAGE.Liquid.MW50 then
    name = "MW 50"
  elseif Type==STORAGE.Liquid.DIESEL then
    name = "Diesel"
  else
    self:E(self.lid..string.format("ERROR: Unknown liquid type %s", tostring(Type)))
  end

  return name
end

--- Adds the amount of a given type of aircraft, liquid, weapon currently present the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid or name of aircraft, weapon or equipment.
-- @param #number Amount Amount of given type to add. Liquids in kg.
-- @return #STORAGE self
function STORAGE:AddAmount(Type, Amount)

  if type(Type)=="number" then
    self:AddLiquid(Type, Amount)
  else
    self:AddItem(Type, Amount)
  end

  return self
end

--- Removes the amount of a given type of aircraft, liquid, weapon from the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid or name of aircraft, weapon or equipment.
-- @param #number Amount Amount of given type to remove. Liquids in kg.
-- @return #STORAGE self
function STORAGE:RemoveAmount(Type, Amount)

  if type(Type)=="number" then
    self:RemoveLiquid(Type, Amount)
  else
    self:RemoveItem(Type, Amount)
  end

  return self
end

--- Sets the amount of a given type of aircraft, liquid, weapon currently present the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid or name of aircraft, weapon or equipment.
-- @param #number Amount of given type. Liquids in kg.
-- @return #STORAGE self
function STORAGE:SetAmount(Type, Amount)

  if type(Type)=="number" then
    self:SetLiquid(Type, Amount)
  else
    self:SetItem(Type, Amount)
  end

  return self
end


--- Gets the amount of a given type of aircraft, liquid, weapon currently present the warehouse.
-- @param #STORAGE self
-- @param #number Type Type of liquid or name of aircraft, weapon or equipment.
-- @return #number Amount of given type. Liquids in kg.
function STORAGE:GetAmount(Type)

  local N=0
  if type(Type)=="number" then
    N=self:GetLiquidAmount(Type)
  else
    N=self:GetItemAmount(Type)
  end

  return N
end

--- Returns whether a given type of aircraft, liquid, weapon is set to be unlimited.
-- @param #STORAGE self
-- @param #string Type Name of aircraft, weapon or equipment or type of liquid (as `#number`).
-- @return #boolen If `true` the given type is unlimited or `false` otherwise.
function STORAGE:IsUnlimited(Type)

  -- Get current amount of type.
  local N=self:GetAmount(Type)
  
  local unlimited=false
  
  if N>0 then
  
    -- Remove one item.
    self:RemoveAmount(Type, 1)
    
    -- Get amount.
    local n=self:GetAmount(Type)
    
    -- If amount did not change, it is unlimited.
    unlimited=n==N
    
    -- Add item back.
    if not unlimited then
      self:AddAmount(Type, 1)
    end
    
    -- Debug info.
    self:I(self.lid..string.format("Type=%s: unlimited=%s (N=%d n=%d)", tostring(Type), tostring(unlimited), N, n))
  end

  return unlimited
end

--- Returns whether a given type of aircraft, liquid, weapon is set to be limited.
-- @param #STORAGE self
-- @param #number Type Type of liquid or name of aircraft, weapon or equipment.
-- @return #boolen If `true` the given type is limited or `false` otherwise.
function STORAGE:IsLimited(Type)

  local limited=not self:IsUnlimited(Type)

  return limited
end

--- Returns whether aircraft are unlimited.
-- @param #STORAGE self
-- @return #boolen If `true` aircraft are unlimited or `false` otherwise.
function STORAGE:IsUnlimitedAircraft()

  -- We test with a specific type but if it is unlimited, than all aircraft are.
  local unlimited=self:IsUnlimited("A-10C")

  return unlimited
end

--- Returns whether liquids are unlimited.
-- @param #STORAGE self
-- @return #boolen If `true` liquids are unlimited or `false` otherwise.
function STORAGE:IsUnlimitedLiquids()

  -- We test with a specific type but if it is unlimited, than all are.
  local unlimited=self:IsUnlimited(STORAGE.Liquid.DIESEL)

  return unlimited
end

--- Returns whether weapons and equipment are unlimited.
-- @param #STORAGE self
-- @return #boolen If `true` weapons and equipment are unlimited or `false` otherwise.
function STORAGE:IsUnlimitedWeapons()

  -- We test with a specific type but if it is unlimited, than all are.
  local unlimited=self:IsUnlimited(ENUMS.Storage.weapons.bombs.Mk_82)

  return unlimited
end

--- Returns whether aircraft are limited.
-- @param #STORAGE self
-- @return #boolen If `true` aircraft are limited or `false` otherwise.
function STORAGE:IsLimitedAircraft()

  -- We test with a specific type but if it is limited, than all are.
  local limited=self:IsLimited("A-10C")

  return limited
end

--- Returns whether liquids are limited.
-- @param #STORAGE self
-- @return #boolen If `true` liquids are limited or `false` otherwise.
function STORAGE:IsLimitedLiquids()

  -- We test with a specific type but if it is limited, than all are.
  local limited=self:IsLimited(STORAGE.Liquid.DIESEL)

  return limited
end

--- Returns whether weapons and equipment are limited.
-- @param #STORAGE self
-- @return #boolen If `true` liquids are limited or `false` otherwise.
function STORAGE:IsLimitedWeapons()

  -- We test with a specific type but if it is limited, than all are.
  local limited=self:IsLimited(ENUMS.Storage.weapons.bombs.Mk_82)

  return limited
end

--- Returns a full itemized list of everything currently in a warehouse. If a category is set to unlimited then the table will be returned empty.
-- @param #STORAGE self
-- @param #string Item Name of item as #string or type of liquid as #number.
-- @return #table Table of aircraft. Table is emtpy `{}` if number of aircraft is set to be unlimited.
-- @return #table Table of liquids. Table is emtpy `{}` if number of liquids is set to be unlimited.
-- @return #table Table of weapons and other equipment. Table is emtpy `{}` if number of liquids is set to be unlimited.
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
