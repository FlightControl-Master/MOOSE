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
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_Demos/tree/master/Wrapper/Storage).
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
-- @field Core.Timer#TIMER SaverTimer The TIMER for autosave.
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
-- # Weapons Helper Enumerater
-- 
-- The currently available weapon items are available in the `ENUMS.Storage.weapons`, e.g. `ENUMS.Storage.weapons.bombs.Mk_82Y`.
-- 
-- # Persistence
-- 
-- The contents of the storage can be saved to and read from disk. For this to function, `io` and `lfs` need to be desanitized in `MissionScripting.lua`.
-- 
-- ## Save once
-- 
-- ### To save once, e.g. this is sufficient:
--    
--      -- Filenames created are the Filename given amended by "_Liquids", "_Aircraft" and "_Weapons" followed by a ".csv". Only Storage NOT set to unlimited will be saved.
--      local Path = "C:\\Users\\UserName\\Saved Games\\DCS\\Missions\\"
--      local Filename = "Batumi"
--      storage:SaveToFile(Path,Filename)
--    
-- ### Autosave
-- 
--      storage:StartAutoSave(Path,Filename,300,true) -- save every 300 secs/5 mins starting in 5 mins, load the existing storage - if any - first if the last parameter is **not** `false`.
-- 
-- ### Stop Autosave
-- 
--      storage:StopAutoSave() -- stop the scheduler.
--    
-- ### Load back with e.g.
-- 
--      -- Filenames searched for the Filename given amended by "_Liquids", "_Aircraft" and "_Weapons" followed by a ".csv". Only Storage NOT set to unlimited will be loaded.
--      local Path = "C:\\Users\\UserName\\Saved Games\\DCS\\Missions\\"
--      local Filename = "Batumi"
--      storage:LoadFromFile(Path,Filename)
--    
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

--- Liquid Names for the static cargo resource table.
-- @type STORAGE.LiquidName
-- @field #number JETFUEL "jet_fuel".
-- @field #number GASOLINE "gasoline".
-- @field #number MW50 "methanol_mixture".
-- @field #number DIESEL "diesel".
STORAGE.LiquidName = {
   GASOLINE = "gasoline",
   DIESEL =    "diesel",
   MW50 =  "methanol_mixture",
   JETFUEL = "jet_fuel",  
}

--- Storage types.
-- @type STORAGE.Type
-- @field #number WEAPONS weapons.
-- @field #number LIQUIDS liquids. Also see #list<#STORAGE.Liquid> for types of liquids.
-- @field #number AIRCRAFT aircraft.
STORAGE.Type = {
  WEAPONS = "weapons",
  LIQUIDS = "liquids",
  AIRCRAFT = "aircrafts",
}

--- STORAGE class version.
-- @field #string version
STORAGE.version="0.1.4"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- DONE: Persistence

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new STORAGE object from the DCS airbase object.
-- @param #STORAGE self
-- @param #string AirbaseName Name of the airbase.
-- @return #STORAGE self
function STORAGE:New(AirbaseName)

  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New()) -- #STORAGE

  self.airbase=Airbase.getByName(AirbaseName)

  if Airbase.getWarehouse then
    self.warehouse=self.airbase:getWarehouse()
  end

  self.lid = string.format("STORAGE %s", AirbaseName)

  return self
end

--- Create a new STORAGE object from an DCS static cargo object.
-- @param #STORAGE self
-- @param #string StaticCargoName Unit name of the static.
-- @return #STORAGE self
function STORAGE:NewFromStaticCargo(StaticCargoName)

  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New()) -- #STORAGE

  self.airbase=StaticObject.getByName(StaticCargoName)

  if Airbase.getWarehouse then
    self.warehouse=Warehouse.getCargoAsWarehouse(self.airbase)
  end

  self.lid = string.format("STORAGE %s", StaticCargoName)

  return self
end

--- Create a new STORAGE object from a Wrapper.DynamicCargo#DYNAMICCARGO object.
-- @param #STORAGE self
-- @param #string DynamicCargoName Unit name of the dynamic cargo.
-- @return #STORAGE self
function STORAGE:NewFromDynamicCargo(DynamicCargoName)

  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New()) -- #STORAGE

  self.airbase=Unit.getByName(DynamicCargoName) or StaticObject.getByName(DynamicCargoName)

  if Airbase.getWarehouse then
    self.warehouse=Warehouse.getCargoAsWarehouse(self.airbase)
  end

  self.lid = string.format("STORAGE %s", DynamicCargoName)

  return self
end


--- Airbases only - Find a STORAGE in the **_DATABASE** using the name associated airbase.
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
  if self.verbose > 1 then
    BASE:TraceOn()
    BASE:TraceClass("STORAGE")
  end
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
-- @return #boolean If `true` the given type is unlimited or `false` otherwise.
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
    unlimited=unlimited or n > 2^29 or n==N

    -- Add item back.
    if not unlimited then
      self:AddAmount(Type, 1)
    end

    -- Debug info.
    self:T(self.lid..string.format("Type=%s: unlimited=%s (N=%d n=%d)", tostring(Type), tostring(unlimited), N, n))
  end

  return unlimited
end

--- Returns whether a given type of aircraft, liquid, weapon is set to be limited.
-- @param #STORAGE self
-- @param #number Type Type of liquid or name of aircraft, weapon or equipment.
-- @return #boolean If `true` the given type is limited or `false` otherwise.
function STORAGE:IsLimited(Type)

  local limited=not self:IsUnlimited(Type)

  return limited
end

--- Returns whether aircraft are unlimited.
-- @param #STORAGE self
-- @return #boolean If `true` aircraft are unlimited or `false` otherwise.
function STORAGE:IsUnlimitedAircraft()

  -- We test with a specific type but if it is unlimited, than all aircraft are.
  local unlimited=self:IsUnlimited("A-10C")

  return unlimited
end

--- Returns whether liquids are unlimited.
-- @param #STORAGE self
-- @return #boolean If `true` liquids are unlimited or `false` otherwise.
function STORAGE:IsUnlimitedLiquids()

  -- We test with a specific type but if it is unlimited, than all are.
  local unlimited=self:IsUnlimited(STORAGE.Liquid.DIESEL)

  return unlimited
end

--- Returns whether weapons and equipment are unlimited.
-- @param #STORAGE self
-- @return #boolean If `true` weapons and equipment are unlimited or `false` otherwise.
function STORAGE:IsUnlimitedWeapons()

  -- We test with a specific type but if it is unlimited, than all are.
  local unlimited=self:IsUnlimited(ENUMS.Storage.weapons.bombs.Mk_82)

  return unlimited
end

--- Returns whether aircraft are limited.
-- @param #STORAGE self
-- @return #boolean If `true` aircraft are limited or `false` otherwise.
function STORAGE:IsLimitedAircraft()

  -- We test with a specific type but if it is limited, than all are.
  local limited=self:IsLimited("A-10C")

  return limited
end

--- Returns whether liquids are limited.
-- @param #STORAGE self
-- @return #boolean If `true` liquids are limited or `false` otherwise.
function STORAGE:IsLimitedLiquids()

  -- We test with a specific type but if it is limited, than all are.
  local limited=self:IsLimited(STORAGE.Liquid.DIESEL)

  return limited
end

--- Returns whether weapons and equipment are limited.
-- @param #STORAGE self
-- @return #boolean If `true` liquids are limited or `false` otherwise.
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

--- Save the contents of a STORAGE to files in CSV format. Filenames created are the Filename given amended by "_Liquids", "_Aircraft" and "_Weapons" followed by a ".csv". Requires io and lfs to be desanitized to be working.
-- @param #STORAGE self
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The base name of the files. Existing files will be overwritten.
-- @return #STORAGE self
function STORAGE:SaveToFile(Path,Filename)

    if not io then
      BASE:E("ERROR: io not desanitized. Can't save the files.")
      return false
    end
  
    -- Check default path.
    if Path==nil and not lfs then
      BASE:E("WARNING: lfs not desanitized. File will be saved in DCS installation root directory rather than your given path.")
    end
    
    local ac, lq, wp = self:GetInventory()
    local DataAircraft = ""
    local DataLiquids = ""
    local DataWeapons = ""
    
    if #lq > 0 then
      DataLiquids = DataLiquids .."Liquids in Storage:\n"
      for key,amount in pairs(lq) do
        DataLiquids = DataLiquids..tostring(key).."="..tostring(amount).."\n"
      end
      --self:I(DataLiquids)
      UTILS.SaveToFile(Path,Filename.."_Liquids.csv",DataLiquids)
      if self.verbose and self.verbose > 0 then
        self:I(self.lid.."Saving Liquids to "..tostring(Path).."\\"..tostring(Filename).."_Liquids.csv")
      end
    end
    
    if UTILS.TableLength(ac) > 0 then
      DataAircraft = DataAircraft .."Aircraft in Storage:\n"
      for key,amount in pairs(ac) do
        DataAircraft = DataAircraft..tostring(key).."="..tostring(amount).."\n"
      end
      --self:I(DataAircraft)
      UTILS.SaveToFile(Path,Filename.."_Aircraft.csv",DataAircraft)
      if self.verbose and self.verbose > 0 then
        self:I(self.lid.."Saving Aircraft to "..tostring(Path).."\\"..tostring(Filename).."_Aircraft.csv")
      end
    end
    
    if UTILS.TableLength(wp) > 0 then
      DataWeapons = DataWeapons .."Weapons and Materiel in Storage:\n"
      for key,amount in pairs(wp) do
        DataWeapons = DataWeapons..tostring(key).."="..tostring(amount).."\n"
      end
      -- Gazelle table keys
      for key,amount in pairs(ENUMS.Storage.weapons.Gazelle) do
        amount = self:GetItemAmount(ENUMS.Storage.weapons.Gazelle[key])
        DataWeapons = DataWeapons.."ENUMS.Storage.weapons.Gazelle."..tostring(key).."="..tostring(amount).."\n"
      end
      -- CH47
      for key,amount in pairs(ENUMS.Storage.weapons.CH47) do
        amount = self:GetItemAmount(ENUMS.Storage.weapons.CH47[key])
        DataWeapons = DataWeapons.."ENUMS.Storage.weapons.CH47."..tostring(key).."="..tostring(amount).."\n"
      end
      -- UH1H
      for key,amount in pairs(ENUMS.Storage.weapons.UH1H) do
        amount = self:GetItemAmount(ENUMS.Storage.weapons.UH1H[key])
        DataWeapons = DataWeapons.."ENUMS.Storage.weapons.UH1H."..tostring(key).."="..tostring(amount).."\n"
      end
      -- OH58D
      for key,amount in pairs(ENUMS.Storage.weapons.OH58) do
        amount = self:GetItemAmount(ENUMS.Storage.weapons.OH58[key])
        DataWeapons = DataWeapons.."ENUMS.Storage.weapons.OH58."..tostring(key).."="..tostring(amount).."\n"
      end
      -- AH64D
      for key,amount in pairs(ENUMS.Storage.weapons.AH64D) do
        amount = self:GetItemAmount(ENUMS.Storage.weapons.AH64D[key])
        DataWeapons = DataWeapons.."ENUMS.Storage.weapons.AH64D."..tostring(key).."="..tostring(amount).."\n"
      end
      --self:I(DataAircraft)
       UTILS.SaveToFile(Path,Filename.."_Weapons.csv",DataWeapons)
       if self.verbose and self.verbose > 0 then
         self:I(self.lid.."Saving Weapons to "..tostring(Path).."\\"..tostring(Filename).."_Weapons.csv")
       end
    end

  return self
end

--- Load the contents of a STORAGE from files. Filenames searched for are the Filename given amended by "_Liquids", "_Aircraft" and "_Weapons" followed by a ".csv". Requires io and lfs to be desanitized to be working.
-- @param #STORAGE self
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @return #STORAGE self
function STORAGE:LoadFromFile(Path,Filename)
 
 if not io then
      BASE:E("ERROR: io not desanitized. Can't read the files.")
    return false
  end
  
  -- Check default path.
  if Path==nil and not lfs then
    BASE:E("WARNING: lfs not desanitized. File will be read from DCS installation root directory rather than your give path.")
  end
  
  --Liquids
  if self:IsLimitedLiquids() then
    local Ok,Liquids = UTILS.LoadFromFile(Path,Filename.."_Liquids.csv")
    if Ok then
       if self.verbose and self.verbose > 0 then
         self:I(self.lid.."Loading Liquids from "..tostring(Path).."\\"..tostring(Filename).."_Liquids.csv")
       end
      for _id,_line in pairs(Liquids) do
        if string.find(_line,"Storage") == nil then
            local tbl=UTILS.Split(_line,"=")
            local lqno = tonumber(tbl[1])
            local lqam = tonumber(tbl[2])
            self:SetLiquid(lqno,lqam)
        end
      end
    else
        self:E("File for Liquids could not be found: "..tostring(Path).."\\"..tostring(Filename"_Liquids.csv"))
    end
  end
  
  --Aircraft
  if self:IsLimitedAircraft() then
    local Ok,Aircraft = UTILS.LoadFromFile(Path,Filename.."_Aircraft.csv")
    if Ok then
       if self.verbose and self.verbose > 0 then
         self:I(self.lid.."Loading Aircraft from "..tostring(Path).."\\"..tostring(Filename).."_Aircraft.csv")
       end
      for _id,_line in pairs(Aircraft) do
        if string.find(_line,"Storage") == nil then
            local tbl=UTILS.Split(_line,"=")
            local acname = tbl[1]
            local acnumber = tonumber(tbl[2])
            self:SetAmount(acname,acnumber)
        end
      end
    else
        self:E("File for Aircraft could not be found: "..tostring(Path).."\\"..tostring(Filename"_Aircraft.csv"))
    end
  end
  
  --Weapons
  if self:IsLimitedWeapons() then
    local Ok,Weapons = UTILS.LoadFromFile(Path,Filename.."_Weapons.csv")
    if Ok then
       if self.verbose and self.verbose > 0 then
         self:I(self.lid.."Loading _eapons from "..tostring(Path).."\\"..tostring(Filename).."_Weapons.csv")
       end
      for _id,_line in pairs(Weapons) do
        if string.find(_line,"Storage") == nil then
            local tbl=UTILS.Split(_line,"=")
            local wpname = tbl[1]
            local wpnumber = tonumber(tbl[2])
            self:SetAmount(wpname,wpnumber)
        end
      end
    else
        self:E("File for Weapons could not be found: "..tostring(Path).."\\"..tostring(Filename"_Weapons.csv"))
    end
  end
   
  return self
end

--- Start a STORAGE autosave process.
-- @param #STORAGE self
-- @param #string Path The path to use. Use double backslashes \\\\ on Windows filesystems.
-- @param #string Filename The name of the file.
-- @param #number Interval The interval, start after this many seconds and repeat every interval seconds. Defaults to 300.
-- @param #boolean LoadOnce If LoadOnce is true or nil, we try to load saved storage first.
-- @return #STORAGE self
function STORAGE:StartAutoSave(Path,Filename,Interval,LoadOnce)
  if LoadOnce ~= false then
    self:LoadFromFile(Path,Filename)
  end
  local interval = Interval or 300
  self.SaverTimer = TIMER:New(STORAGE.SaveToFile,self,Path,Filename)
  self.SaverTimer:Start(interval,interval)
  return self
end

--- Stop a running STORAGE autosave process.
-- @param #STORAGE self
-- @return #STORAGE self
function STORAGE:StopAutoSave()
  if self.SaverTimer and self.SaverTimer:IsRunning() then
    self.SaverTimer:Stop()
    self.SaverTimer = nil
  end
  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
