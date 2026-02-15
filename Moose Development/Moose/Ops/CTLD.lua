--- **Ops** - Combat Troops & Logistics Department.
--
-- ===
-- 
-- **CTLD** - MOOSE based Helicopter CTLD Operations.
-- 
-- ===
-- 
-- ## Missions:
--
-- ### [CTLD - Combat Troop & Logistics Deployment](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/CTLD)
-- 
-- ===
-- 
-- **Main Features:**
--
--    * MOOSE-based Helicopter CTLD Operations for Players.
--
-- ===
--
-- ### Author: **Applevangelist** (Moose Version), ***Ciribob*** (original), Thanks to: Shadowze, Cammel (testing), bbirchnz (additional code!!)
-- ### Repack addition for crates: **Raiden**
-- ### Additional cool features: **Lekaa**
-- 
-- @module Ops.CTLD
-- @image OPS_CTLD.jpg

-- Last Update Jan 2026


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO CTLD_CARGO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

do 

------------------------------------------------------
--- **CTLD_CARGO** class, extends Core.Base#BASE
-- @type CTLD_CARGO
-- @field #string ClassName Class name.
-- @field #number ID ID of this cargo.
-- @field #string Name Name for menu.
-- @field #string DisplayName Display name for menu/messages.
-- @field #table Templates Table of #POSITIONABLE objects.
-- @field #string CargoType Enumerator of Type.
-- @field #boolean HasBeenMoved Flag for moving.
-- @field #boolean LoadDirectly Flag for direct loading.
-- @field #number CratesNeeded Crates needed to build.
-- @field Wrapper.Positionable#POSITIONABLE Positionable Representation of cargo in the mission.
-- @field #boolean HasBeenDropped True if dropped from heli.
-- @field #number PerCrateMass Mass in kg.
-- @field #number Stock Number of builds available, -1 for unlimited.
-- @field #string Subcategory Sub-category name.
-- @field #boolean DontShowInMenu Show this item in menu or not.
-- @field Core.Zone#ZONE Location Location (if set) where to get this cargo item.
-- @field #table ResourceMap Resource Map information table if it has been set for static cargo items.
-- @field #string StaticShape Individual shape if set.
-- @field #string StaticType Individual type if set.
-- @field #string StaticCategory Individual static category if set.
-- @field #list<#string> TypeNames Table of unit types able to pick this cargo up.
-- @field #number Stock0 Initial stock, if any given.
-- @extends Core.Base#BASE

---
-- @field #CTLD_CARGO CTLD_CARGO
CTLD_CARGO = {
  ClassName = "CTLD_CARGO",
  ID = 0,
  Name = "none",
  DisplayName = "none",
  Templates = {},
  CargoType = "none",
  HasBeenMoved = false,
  LoadDirectly = false,
  CratesNeeded = 0,
  Positionable = nil,
  HasBeenDropped = false,
  PerCrateMass = 0,
  Stock = nil,
  Stock0 = nil,
  Mark = nil,
  DontShowInMenu = false,
  Location = nil,
  }
  
  --- Define cargo types.
  -- @type CTLD_CARGO.Enum
  -- @field #string VEHICLE
  -- @field #string TROOPS
  -- @field #string FOB
  -- @field #string CRATE
  -- @field #string REPAIR
  -- @field #string ENGINEERS
  -- @field #string STATIC
  -- @field #string GCLOADABLE
  CTLD_CARGO.Enum = {
    VEHICLE = "Vehicle", -- #string vehicles
    TROOPS = "Troops", -- #string troops
    FOB = "FOB", -- #string FOB
    CRATE = "Crate", -- #string crate
    REPAIR = "Repair", -- #string repair
    ENGINEERS = "Engineers", -- #string engineers
    STATIC = "Static", -- #string statics
    GCLOADABLE = "GC_Loadable", -- #string dynamiccargo
  }
  
  --- Function to create new CTLD_CARGO object.
  -- @param #CTLD_CARGO self
  -- @param #number ID ID of this #CTLD_CARGO
  -- @param #string Name Name for menu.
  -- @param #table Templates Table of #POSITIONABLE objects.
  -- @param #CTLD_CARGO.Enum Sorte Enumerator of Type.
  -- @param #boolean HasBeenMoved Flag for moving.
  -- @param #boolean LoadDirectly Flag for direct loading.
  -- @param #number CratesNeeded Crates needed to build.
  -- @param Wrapper.Positionable#POSITIONABLE Positionable Representation of cargo in the mission.
  -- @param #boolean Dropped Cargo/Troops have been unloaded from a chopper.
  -- @param #number PerCrateMass Mass in kg
  -- @param #number Stock Number of builds available, nil for unlimited
  -- @param #string Subcategory Name of subcategory, handy if using > 10 types to load.
  -- @param #boolean DontShowInMenu Show this item in menu or not (default: false == show it).
  -- @param Core.Zone#ZONE Location (optional) Where the cargo is available (one location only).
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:New(ID, Name, Templates, Sorte, HasBeenMoved, LoadDirectly, CratesNeeded, Positionable, Dropped, PerCrateMass, Stock, Subcategory, DontShowInMenu, Location)
    -- Inherit everything from BASE class.
    local self=BASE:Inherit(self, BASE:New()) -- #CTLD_CARGO
    self:T({ID, Name, Templates, Sorte, HasBeenMoved, LoadDirectly, CratesNeeded, Positionable, Dropped})
    self.ID = ID or math.random(100000,1000000)
    self.Name = Name or "none" -- #string
    self.DisplayName = Name or "none" -- #string
    self.Templates = Templates or {} -- #table
    self.CargoType = Sorte or "type" -- #CTLD_CARGO.Enum
    self.HasBeenMoved = HasBeenMoved or false -- #boolean
    self.LoadDirectly = LoadDirectly or false -- #boolean
    self.CratesNeeded = CratesNeeded or 0 -- #number
    self.Positionable = Positionable or nil -- Wrapper.Positionable#POSITIONABLE
    self.HasBeenDropped = Dropped or false --#boolean
    self.PerCrateMass = PerCrateMass or 0 -- #number
    self.Stock = Stock or nil --#number
    self.Stock0 = Stock or nil --#number 
    self.Mark = nil
    self.Subcategory = Subcategory or "Other"
    self.DontShowInMenu = DontShowInMenu or false
    self.ResourceMap = nil
    self.StaticType = "container_cargo" -- "container_cargo"
    if self:IsStatic() then
      self.StaticType = self.Templates
    end
    self.StaticShape = nil
    self.TypeNames = nil
    self.StaticCategory = "Cargos"
    if type(Location) == "string" then
      Location = ZONE:New(Location)
    end
    self.Location = Location
    self.NoMoveToZone = false
    return self
  end
  
  --- Add specific static type and shape to this CARGO.
  -- @param #CTLD_CARGO self
  -- @param #string TypeName
  -- @param #string ShapeName
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:SetStaticTypeAndShape(Category,TypeName,ShapeName)
    self.StaticCategory = Category or "Cargos"
    self.StaticType = TypeName or "container_cargo"
    self.StaticShape = ShapeName
    return self
  end
  
  --- Get the specific static type and shape from this CARGO if set.
  -- @param #CTLD_CARGO self
  -- @return #string Category
  -- @return #string TypeName
  -- @return #string ShapeName
  function CTLD_CARGO:GetStaticTypeAndShape()
    return self.StaticCategory, self.StaticType, self.StaticShape
  end
  
  --- Add specific unit types to this CARGO (restrict what types can pick this up).
  -- @param #CTLD_CARGO self
  -- @param #string UnitTypes Unit type name, can also be a #list<#string> table of unit type names.
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:AddUnitTypeName(UnitTypes)
    if not self.TypeNames then self.TypeNames = {} end
    if type(UnitTypes) ~= "table" then UnitTypes = {UnitTypes} end
    for _,_singletype in pairs(UnitTypes or {}) do
      self.TypeNames[_singletype]=_singletype
    end
    return self
  end
  
  --- Check if a specific unit can carry this CARGO (restrict what types can pick this up).
  -- @param #CTLD_CARGO self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD_CARGO:UnitCanCarry(Unit)
    if not Unit then return false end
    if self.TypeNames == nil then return true end
    local typename = Unit:GetTypeName() or "none"
    if self.TypeNames[typename] then
      return true
    else
      return false
    end
  end
  
  --- Add Resource Map information table
  -- @param #CTLD_CARGO self
  -- @param #table ResourceMap
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:SetStaticResourceMap(ResourceMap)
    self.ResourceMap = ResourceMap
    return self
  end
  
  --- Get Resource Map information table
  -- @param #CTLD_CARGO self
  -- @return #table ResourceMap
  function CTLD_CARGO:GetStaticResourceMap()
    return self.ResourceMap
  end
  
  --- Query Location.
  -- @param #CTLD_CARGO self
  -- @return Core.Zone#ZONE location or `nil` if not set
  function CTLD_CARGO:GetLocation()
    return self.Location
  end
  
  --- Query ID.
  -- @param #CTLD_CARGO self
  -- @return #number ID
  function CTLD_CARGO:GetID()
    return self.ID
  end
  
  --- Query Subcategory
  -- @param #CTLD_CARGO self
  -- @return #string SubCategory
  function CTLD_CARGO:GetSubCat()
    return self.Subcategory
  end
  
  --- Query Mass.
  -- @param #CTLD_CARGO self
  -- @return #number Mass in kg
  function CTLD_CARGO:GetMass()
    return self.PerCrateMass
  end  
  
  --- Query Name.
  -- @param #CTLD_CARGO self
  -- @return #string Name
  function CTLD_CARGO:GetName()
    return self.Name
  end

  --- Set display name.
  -- @param #CTLD_CARGO self
  -- @param #string DisplayName Display label used in menus/messages (optional).
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:SetDisplayName(DisplayName)
    if type(DisplayName) == "string" and DisplayName ~= "" then
      self.DisplayName = DisplayName
    else
      self.DisplayName = self.Name
    end
    return self
  end

  --- Query display name.
  -- @param #CTLD_CARGO self
  -- @return #string Display name, or Name if not set
  function CTLD_CARGO:GetDisplayName()
    return self.DisplayName or self.Name
  end
  
  --- Query Templates.
  -- @param #CTLD_CARGO self
  -- @return #table Templates
  function CTLD_CARGO:GetTemplates()
    return self.Templates
  end
  
  --- Query has moved.
  -- @param #CTLD_CARGO self
  -- @return #boolean Has moved
  function CTLD_CARGO:HasMoved()
    return self.HasBeenMoved
  end
  
  --- Query was dropped.
  -- @param #CTLD_CARGO self
  -- @param #boolean hercOnly If true, only treat Herc drops as 'dropped'.
  -- @return #boolean Has been dropped.
  function CTLD_CARGO:WasDropped(hercOnly)
    if hercOnly then
      return self.HasBeenDropped and self.IsHercDrop==true
    end
    return self.HasBeenDropped
  end
  
  --- Query directly loadable.
  -- @param #CTLD_CARGO self
  -- @return #boolean loadable
  function CTLD_CARGO:CanLoadDirectly()
    return self.LoadDirectly
  end
  
  --- Query number of crates or troopsize.
  -- @param #CTLD_CARGO self
  -- @return #number Crates or size of troops.
  function CTLD_CARGO:GetCratesNeeded()
    return self.CratesNeeded
  end
  
  --- Query type.
  -- @param #CTLD_CARGO self
  -- @return #CTLD_CARGO.Enum Type
  function CTLD_CARGO:GetType()
    return self.CargoType
  end
  
  --- Query type.
  -- @param #CTLD_CARGO self
  -- @return Wrapper.Positionable#POSITIONABLE Positionable
  function CTLD_CARGO:GetPositionable()
    return self.Positionable
  end
  
  --- Set HasMoved.
  -- @param #CTLD_CARGO self
  -- @param #boolean moved
  function CTLD_CARGO:SetHasMoved(moved)
    self.HasBeenMoved = moved or false
  end
  
   --- Query if cargo has been loaded.
  -- @param #CTLD_CARGO self
  -- @param #boolean loaded
  function CTLD_CARGO:Isloaded()
    if self.HasBeenMoved and not self:WasDropped() then
      return true
    else
     return false
    end 
  end
  
  --- Set WasDropped.
  -- @param #CTLD_CARGO self
  -- @param #boolean dropped
  -- @param #boolean isHercDrop set when _GetCrates is used by the herc
  function CTLD_CARGO:SetWasDropped(dropped, isHercDrop)
    self.HasBeenDropped = dropped or false
    self.IsHercDrop = isHercDrop or false
  end
  
  --- Get Stock.
  -- @param #CTLD_CARGO self
  -- @return #number Stock or -1 if unlimited.
  function CTLD_CARGO:GetStock()
    if self.Stock then
      return self.Stock
    else
      return -1
    end
  end
  
  --- Get Stock0.
  -- @param #CTLD_CARGO self
  -- @return #number Stock0 or -1 if unlimited.
  function CTLD_CARGO:GetStock0()
    if self.Stock0 then
      return self.Stock0
    else
      return -1
    end
  end
  
    --- Get relative Stock.
  -- @param #CTLD_CARGO self
  -- @return #number Stock Percentage like 75, or -1 if unlimited.
  function CTLD_CARGO:GetRelativeStock()
    if self.Stock and self.Stock0 then
      return math.floor((self.Stock/self.Stock0)*100)
    else
      return -1
    end
  end
  
  --- Add Stock.
  -- @param #CTLD_CARGO self
  -- @param #number Number to add, none if nil.
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:AddStock(Number)
    if self.Stock then -- Stock nil?
      local number = Number or 1
      self.Stock = self.Stock + number
    end
    return self
  end
  
  --- Remove Stock.
  -- @param #CTLD_CARGO self
  -- @param #number Number to reduce, none if nil.
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:RemoveStock(Number)
    if self.Stock then -- Stock nil?
      local number = Number or 1
      self.Stock = self.Stock - number
      if self.Stock < 0 then self.Stock = 0 end
    end
    return self
  end
  
  --- Set Stock.
  -- @param #CTLD_CARGO self
  -- @param #number Number to set, nil means unlimited.
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:SetStock(Number)
    self.Stock = Number
    return self
  end
  
  --- Query crate type for REPAIR
  -- @param #CTLD_CARGO self
  -- @param #boolean 
  function CTLD_CARGO:IsRepair()
   if self.CargoType == "Repair" then
    return true
   else
    return false
   end
  end
  
  --- Query crate type for STATIC
  -- @param #CTLD_CARGO self
  -- @return #boolean 
  function CTLD_CARGO:IsStatic()
   if self.CargoType == "Static" then
    return true
   else
    return false
   end
  end
  
  --- Add mark
  -- @param #CTLD_CARGO self
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:AddMark(Mark)
    self.Mark = Mark
    return self
  end
  
  --- Get mark
  -- @param #CTLD_CARGO self
  -- @return #string Mark
  function CTLD_CARGO:GetMark(Mark)
    return self.Mark
  end
  
  --- Wipe mark
  -- @param #CTLD_CARGO self
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:WipeMark()
    self.Mark = nil
    return self
  end
  
  --- Get overall mass of a cargo object, i.e. crates needed x mass per crate
  -- @param #CTLD_CARGO self
  -- @return #number mass
  function CTLD_CARGO:GetNetMass()
    return self.CratesNeeded * self.PerCrateMass
  end
   
end

do

------------------------------------------------------
--- **CTLD_ENGINEERING** class, extends Core.Base#BASE
-- @type CTLD_ENGINEERING
-- @field #string ClassName
-- @field #string lid
-- @field #string Name
-- @field Wrapper.Group#GROUP Group
-- @field Wrapper.Unit#UNIT Unit
-- @field Wrapper.Group#GROUP HeliGroup
-- @field Wrapper.Unit#UNIT HeliUnit
-- @field #string State
-- @extends Core.Base#BASE

---
-- @field #CTLD_ENGINEERING CTLD_ENGINEERING
CTLD_ENGINEERING = {
  ClassName = "CTLD_ENGINEERING",
  lid = "",
  Name = "none",
  Group = nil,
  Unit = nil,
  --C_Ops = nil,
  HeliGroup = nil,
  HeliUnit = nil,
  State = "",
  }
  
  --- CTLD_ENGINEERING class version.
  -- @field #string version
  CTLD_ENGINEERING.Version = "0.0.3"
  
  --- Create a new instance.
  -- @param #CTLD_ENGINEERING self
  -- @param #string Name
  -- @param #string GroupName Name of Engineering #GROUP object
  -- @param Wrapper.Group#GROUP HeliGroup HeliGroup
  -- @param Wrapper.Unit#UNIT HeliUnit HeliUnit
  -- @return #CTLD_ENGINEERING self 
  function CTLD_ENGINEERING:New(Name, GroupName, HeliGroup, HeliUnit)
  
      -- Inherit everything from BASE class.
    local self=BASE:Inherit(self, BASE:New()) -- #CTLD_ENGINEERING
    
   --BASE:I({Name, GroupName})
    
    self.Name = Name or "Engineer Squad" -- #string
    self.Group = GROUP:FindByName(GroupName) -- Wrapper.Group#GROUP
    self.Unit = self.Group:GetUnit(1) -- Wrapper.Unit#UNIT
    self.HeliGroup = HeliGroup -- Wrapper.Group#GROUP
    self.HeliUnit = HeliUnit -- Wrapper.Unit#UNIT
    self.currwpt = nil -- Core.Point#COORDINATE
    self.lid = string.format("%s (%s) | ",self.Name, self.Version)
      -- Start State.
    self.State = "Stopped"
    self.marktimer = 300 -- wait this many secs before trying a crate again
    self:Start()
    local parent = self:GetParent(self)
    return self
  end
  
  --- (Internal) Set the status
  -- @param #CTLD_ENGINEERING self
  -- @param #string State
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:SetStatus(State)
    self.State = State
    return self
  end
  
  --- (Internal) Get the status
  -- @param #CTLD_ENGINEERING self
  -- @return #string State
  function CTLD_ENGINEERING:GetStatus()
    return self.State
  end
  
  --- (Internal) Check the status
  -- @param #CTLD_ENGINEERING self
  -- @param #string State
  -- @return #boolean Outcome
  function CTLD_ENGINEERING:IsStatus(State)
    return self.State == State
  end
  
  --- (Internal) Check the negative status
  -- @param #CTLD_ENGINEERING self
  -- @param #string State
  -- @return #boolean Outcome
  function CTLD_ENGINEERING:IsNotStatus(State)
    return self.State ~= State
  end
  
  --- (Internal) Set start status.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Start()
    self:T(self.lid.."Start")
    self:SetStatus("Running")
    return self
  end
  
  --- (Internal) Set stop status.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Stop()
    self:T(self.lid.."Stop")
    self:SetStatus("Stopped")
    return self
  end
  
  --- (Internal) Set build status.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Build()
    self:T(self.lid.."Build")
    self:SetStatus("Building")
    return self
  end
  
  --- (Internal) Set done status.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Done()
    self:T(self.lid.."Done")
    local grp = self.Group -- Wrapper.Group#GROUP
    grp:RelocateGroundRandomInRadius(7,100,false,false,"Diamond")
    self:SetStatus("Running")
    return self
  end
  
  --- (Internal) Search for crates in reach.
  -- @param #CTLD_ENGINEERING self
  -- @param #table crates Table of found crate Ops.CTLD#CTLD_CARGO objects.
  -- @param #number number Number of crates found.
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Search(crates,number)
    self:T(self.lid.."Search")
    self:SetStatus("Searching")
    -- find crates close by
    --local COps = self.C_Ops -- Ops.CTLD#CTLD
    local dist = self.distance -- #number
    local group = self.Group -- Wrapper.Group#GROUP
    --local crates,number = COps:_FindCratesNearby(group,nil, dist) -- #table
    local ctable = {}
    local ind = 0
    if number > 0 then
      -- get set of dropped only
      for _,_cargo in pairs (crates) do
       local cgotype = _cargo:GetType()
       if _cargo:WasDropped() and cgotype ~= CTLD_CARGO.Enum.STATIC then
        local ok = false
        local chalk = _cargo:GetMark()
        if chalk == nil then
          ok = true
        else
         -- have we tried this cargo recently?
         local tag = chalk.tag or "none"
         local timestamp = chalk.timestamp or 0
         -- enough time gone?
         local gone = timer.getAbsTime() - timestamp
         if gone >= self.marktimer then
            ok = true
            _cargo:WipeMark()
         end -- end time check
        end -- end chalk
        if ok then
          local chalk = {}
          chalk.tag = "Engineers"
          chalk.timestamp = timer.getAbsTime()
          _cargo:AddMark(chalk)
          ind = ind + 1
          table.insert(ctable,ind,_cargo)
        end     
       end -- end dropped
      end -- end for
    end -- end number
    
    if ind > 0 then
      local crate = ctable[1] -- Ops.CTLD#CTLD_CARGO
      local static = crate:GetPositionable() -- Wrapper.Static#STATIC
      local crate_pos = static:GetCoordinate() -- Core.Point#COORDINATE
      local gpos = group:GetCoord() -- Core.Point#COORDINATE
      -- see how far we are from the crate
      local distance = self:_GetDistance(gpos,crate_pos)
      self:T(string.format("%s Distance to crate: %d", self.lid, distance))
      -- move there
      if distance > 30 and distance ~= -1 and self:IsStatus("Searching") then
        group:RouteGroundTo(crate_pos,15,"Line abreast",1)
        self.currwpt = crate_pos -- Core.Point#COORDINATE
        self:Move()
      elseif distance <= 30 and distance ~= -1 then
        -- arrived
        self:Arrive()
      end
    else
      self:T(self.lid.."No crates in reach!")
    end
    return self
  end
  
  --- (Internal) Move towards crates in reach.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Move()
    self:T(self.lid.."Move")
    self:SetStatus("Moving")
    -- check if we arrived on target
    --local COps = self.C_Ops -- Ops.CTLD#CTLD
    local group = self.Group -- Wrapper.Group#GROUP
    local tgtpos = self.currwpt -- Core.Point#COORDINATE
    local gpos = group:GetCoord() -- Core.Point#COORDINATE
    -- see how far we are from the crate
    local distance = self:_GetDistance(gpos,tgtpos)
    self:T(string.format("%s Distance remaining: %d", self.lid, distance))
    if distance <= 30 and distance ~= -1 then
        -- arrived
        self:Arrive()
    end
    return self
  end
  
  --- (Internal) Arrived at crates in reach. Stop group.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Arrive()
    self:T(self.lid.."Arrive")
    self:SetStatus("Arrived")
    self.currwpt = nil
    local Grp = self.Group -- Wrapper.Group#GROUP
    Grp:RouteStop()
    return self
  end
  
  --- (Internal) Return distance in meters between two coordinates.
  -- @param #CTLD_ENGINEERING self
  -- @param Core.Point#COORDINATE _point1 Coordinate one
  -- @param Core.Point#COORDINATE _point2 Coordinate two
  -- @return #number Distance in meters or -1
  function CTLD_ENGINEERING:_GetDistance(_point1, _point2)
    self:T(self.lid .. " _GetDistance")
    if _point1 and _point2 then
      local distance1 = _point1:Get2DDistance(_point2)
      local distance2 = _point1:DistanceFromPointVec2(_point2)
      if distance1 and type(distance1) == "number" then
        return distance1
      elseif distance2 and type(distance2) == "number" then
        return distance2
      else
        self:E("*****Cannot calculate distance!")
        self:E({_point1,_point2})
        return -1
      end
    else
      self:E("******Cannot calculate distance!")
      self:E({_point1,_point2})
      return -1
    end
  end

end

do
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO CTLD
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------
--- **CTLD** class, extends Core.Base#BASE, Core.Fsm#FSM
-- @type CTLD
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number coalition Coalition side number, e.g. `coalition.side.RED`.
-- @field #boolean debug
-- @extends Core.Fsm#FSM

--- *Combat Troop & Logistics Deployment (CTLD): Everyone wants to be a POG, until there\'s POG stuff to be done.* (Mil Saying)
--
-- ===
--
-- ![Banner Image](../Images/OPS_CTLD.jpg)
--
-- # CTLD Concept
-- 
--  * MOOSE-based CTLD for Players.
--  * Object oriented refactoring of Ciribob\'s fantastic CTLD script.
--  * No need for extra MIST loading. 
--  * Additional events to tailor your mission.
--  * ANY late activated group can serve as cargo, either as troops, crates, which have to be build on-location, or static like ammo chests.
--  * Option to persist (save&load) your dropped troops, crates and vehicles.
--  * Weight checks on loaded cargo.
-- 
-- ## 0. Prerequisites
-- 
-- You need to load an .ogg soundfile for the pilot\'s beacons into the mission, e.g. "beacon.ogg", use a once trigger, "sound to country" for that.
-- Create the late-activated troops, vehicles, that will make up your deployable forces.
-- 
-- Example sound files are here: [Moose Sound](https://github.com/FlightControl-Master/MOOSE_SOUND/tree/master/CTLD%20CSAR)
-- 
-- ## 1. Basic Setup
-- 
-- ## 1.1 Create and start a CTLD instance
-- 
-- A basic setup example is the following:
--        
--        -- Instantiate and start a CTLD for the blue side, using helicopter groups named "Helicargo" and alias "Lufttransportbrigade I"
--        local my_ctld = CTLD:New(coalition.side.BLUE,{"Helicargo"},"Lufttransportbrigade I")
--        my_ctld:__Start(5)
--
-- ## 1.2 Add cargo types available
--        
-- Add *generic* cargo types that you need for your missions, here infantry units, vehicles and a FOB. These need to be late-activated Wrapper.Group#GROUP objects:
--        
--        -- add infantry unit called "Anti-Tank Small" using template "ATS", of type TROOP with size 3
--        -- infantry units will be loaded directly from LOAD zones into the heli (matching number of free seats needed)
--        my_ctld:AddTroopsCargo("Anti-Tank Small",{"ATS"},CTLD_CARGO.Enum.TROOPS,3)
--        -- if you want to add weight to your Heli, troops can have a weight in kg **per person**. Currently no max weight checked. Fly carefully.
--        my_ctld:AddTroopsCargo("Anti-Tank Small",{"ATS"},CTLD_CARGO.Enum.TROOPS,3,80)
--        
--        -- add infantry unit called "Anti-Air" using templates "AA" and "AA2", of type TROOP with size 4. No weight. We only have 2 in stock:
--        my_ctld:AddTroopsCargo("Anti-Air",{"AA","AA2"},CTLD_CARGO.Enum.TROOPS,4,nil,2)
--        
--        -- add an engineers unit called "Wrenches" using template "Engineers", of type ENGINEERS with size 2. Engineers can be loaded, dropped,
--        -- and extracted like troops. However, they will seek to build and/or repair crates found in a given radius. Handy if you can\'t stay
--        -- to build or repair or under fire.
--        my_ctld:AddTroopsCargo("Wrenches",{"Engineers"},CTLD_CARGO.Enum.ENGINEERS,4)
--        my_ctld.EngineerSearch = 2000 -- teams will search for crates in this radius.
--        
--        -- add vehicle called "Humvee" using template "Humvee", of type VEHICLE, size 2, i.e. needs two crates to be build
--        -- vehicles and FOB will be spawned as crates in a LOAD zone first. Once transported to DROP zones, they can be build into the objects
--        my_ctld:AddCratesCargo("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,2)
--        -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
--        my_ctld:AddCratesCargo("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,2,2775)
--        -- if you want to limit your stock, add a number (here: 10) as parameter after weight. No parameter / nil means unlimited stock.
--        my_ctld:AddCratesCargo("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,2,2775,10)
--        -- additionally, you can limit **where** the stock is available (one location only!) - this one is available in a zone called "Vehicle Store".
--        my_ctld:AddCratesCargo("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,2,2775,10,nil,nil,"Vehicle Store")
--        -- Tip: if you want the spawned/built group NOT to move to a MOVE zone, replace AddCratesCargo with AddCratesCargoNoMove (same parameters).
--        
--        -- add infantry unit called "Forward Ops Base" using template "FOB", of type FOB, size 4, i.e. needs four crates to be build:
--        my_ctld:AddCratesCargo("Forward Ops Base",{"FOB"},CTLD_CARGO.Enum.FOB,4)
--
--        -- Add **unit** instead of **crates** called "Humvee" for the C-130J-30 Manage Units menu, using template "Humvee", of type VEHICLE
--        -- units are spawned directly behind the aircraft in a LOAD zone, without crates or building
--        my_ctld:AddUnits("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE)
--        
--        -- add crates to repair FOB or VEHICLE type units - the 2nd parameter needs to match the template you want to repair,
--        -- e.g. the "Humvee" here refers back to the "Humvee" crates cargo added above (same template!)
--        my_ctld:AddCratesRepair("Humvee Repair","Humvee",CTLD_CARGO.Enum.REPAIR,1)
--        my_ctld.repairtime = 300 -- takes 300 seconds to repair something
-- 
--        -- add static cargo objects, e.g ammo chests - the name needs to refer to a STATIC object in the mission editor, 
--        -- here: it\'s the UNIT name (not the GROUP name!), the second parameter is the weight in kg.
--        my_ctld:AddStaticsCargo("Ammunition",500)
--        
-- ## 1.3 Add logistics zones
--  
--  Add (normal, round!)  zones for loading troops and crates and dropping, building crates
--  
--        -- Add a zone of type LOAD to our setup. Players can load any troops and crates here as defined in 1.2 above.
--        -- "Loadzone" is the name of the zone from the ME. Players can load, if they are inside the zone.
--        -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
--        my_ctld:AddCTLDZone("Loadzone",CTLD.CargoZoneType.LOAD,SMOKECOLOR.Blue,true,true)
--        
--        -- Add a zone of type DROP. Players can drop crates here.
--        -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
--        -- NOTE: Troops can be unloaded anywhere, also when hovering in parameters.
--        my_ctld:AddCTLDZone("Dropzone",CTLD.CargoZoneType.DROP,SMOKECOLOR.Red,true,true)
--        
--        -- Add two zones of type MOVE. Dropped troops and vehicles will move to the nearest one. See options.
--        -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
--        my_ctld:AddCTLDZone("Movezone",CTLD.CargoZoneType.MOVE,SMOKECOLOR.Orange,false,false)
--        
--        my_ctld:AddCTLDZone("Movezone2",CTLD.CargoZoneType.MOVE,SMOKECOLOR.White,true,true)
--        
--        -- Add a zone of type SHIP to our setup. Players can load troops and crates from this ship
--        -- "Tarawa" is the unitname (callsign) of the ship from the ME. Players can load, if they are inside the zone.
--        -- The ship is 240 meters long and 20 meters wide.
--        -- Note that you need to adjust the max hover height to deck height plus 5 meters or so for loading to work.
--        -- When the ship is moving, avoid forcing hoverload.
--        my_ctld:AddCTLDZone("Tarawa",CTLD.CargoZoneType.SHIP,SMOKECOLOR.Blue,true,true,240,20)
-- 
-- ## 2. Options
-- 
-- The following options are available (with their defaults). Only set the ones you want changed:
--
--          my_ctld.useprefix = true -- (DO NOT SWITCH THIS OFF UNLESS YOU KNOW WHAT YOU ARE DOING!) Adjust **before** starting CTLD. If set to false, *all* choppers of the coalition side will be enabled for CTLD.
--          my_ctld.CrateDistance = 35 -- List and Load crates in this radius only.
--          my_ctld.UnitDistance = 90 -- List units in this radius only. This will only be used for the C-130J-30 and the option my_ctld.UseC130LoadAndUnload = true.
--          my_ctld.maxUnitsNearby = 3 -- Max units allowed to be spawned using Get units function for the C-130J-30. It will exclude what's inside the C-130J-30.
--          my_ctld.PackDistance = 35 -- Pack crates in this radius only
--          my_ctld.dropcratesanywhere = false -- Option to allow crates to be dropped anywhere.
--          my_ctld.dropAsCargoCrate = false -- Hercules only: Parachuted herc cargo is not unpacked automatically but placed as crate to be unpacked. Needs a cargo with the same name defined like the cargo that was dropped.
--          my_ctld.maximumHoverHeight = 15 -- Hover max this high to load in meters.
--          my_ctld.minimumHoverHeight = 4 -- Hover min this low to load in meters.
--          my_ctld.forcehoverload = true -- Crates (not: troops) can **only** be loaded while hovering.
--          my_ctld.hoverautoloading = true -- Crates in CrateDistance in a LOAD zone will be loaded automatically if space allows.
--          my_ctld.smokedistance = 2000 -- Smoke or flares can be request for zones this far away (in meters).
--          my_ctld.movetroopstowpzone = true -- Troops and vehicles will move to the nearest MOVE zone...
--          my_ctld.movetroopsdistance = 5000 -- .. but only if this far away (in meters)
--          my_ctld.suppressmessages = false -- Set to true if you want to script your own messages.
--          my_ctld.repairtime = 300 -- Number of seconds it takes to repair a unit.
--          my_ctld.buildtime = 300 -- Number of seconds it takes to build a unit. Set to zero or nil to build instantly.
--          my_ctld.cratecountry = country.id.GERMANY -- ID of crates. Will default to country.id.RUSSIA for RED coalition setups.
--          my_ctld.allowcratepickupagain = true  -- allow re-pickup crates that were dropped.
--          my_ctld.enableslingload = false -- allow cargos to be slingloaded - might not work for all cargo types
--          my_ctld.pilotmustopendoors = false -- force opening of doors
--          my_ctld.SmokeColor = SMOKECOLOR.Red -- default color to use when dropping smoke from heli 
--          my_ctld.FlareColor = FLARECOLOR.Red -- color to use when flaring from heli
--          my_ctld.basetype = "container_cargo" -- default shape of the cargo container
--          my_ctld.C130basetype = "cds_crate" -- default shape for the C-130J-30 of the cargo container
--          my_ctld.droppedbeacontimeout = 600 -- dropped beacon lasts 10 minutes
--          my_ctld.usesubcats = false -- use sub-category names for crates, adds an extra menu layer in "Get Crates", useful if you have > 10 crate types.
--          my_ctld.placeCratesAhead = false -- place crates straight ahead of the helicopter, in a random way. If true, crates are more neatly sorted.
--          my_ctld.nobuildinloadzones = true -- forbid players to build stuff in LOAD zones if set to `true`
--          my_ctld.movecratesbeforebuild = true -- crates must be moved once before they can be build. Set to false for direct builds.
--          my_ctld.surfacetypes = {land.SurfaceType.LAND,land.SurfaceType.ROAD,land.SurfaceType.RUNWAY,land.SurfaceType.SHALLOW_WATER} -- surfaces for loading back objects.
--          my_ctld.nobuildmenu = false -- if set to true effectively enforces to have engineers build/repair stuff for you.
--          my_ctld.RadioSound = "beacon.ogg" -- -- this sound will be hearable if you tune in the beacon frequency. Add the sound file to your miz.
--          my_ctld.RadioSoundFC3 = "beacon.ogg" -- this sound will be hearable by FC3 users (actually all UHF radios); change to something like "beaconsilent.ogg" and add the sound file to your miz if you don't want to annoy FC3 pilots.
--          my_ctld.enableChinookGCLoading = true -- this will effectively suppress the crate load and drop for CTLD_CARGO.Enum.STATIC types for CTLD for the Chinook
--          my_ctld.TroopUnloadDistGround = 5 -- If hovering, spawn dropped troops this far away in meters from the helo
--          my_ctld.TroopUnloadDistHover = 1.5 -- If grounded, spawn dropped troops this far away in meters from the helo
--          my_ctld.TroopUnloadDistGroundHerc = 25 -- On the ground, unload troops this far behind the Hercules
--          my_ctld.TroopUnloadDistGroundHook = 15 -- On the ground, unload troops this far behind the Chinook
--          my_ctld.TroopUnloadDistHoverHook = 5 -- When hovering, unload troops this far behind the Chinook
--          my_ctld.showstockinmenuitems = false -- When set to true, the menu lines will also show the remaining items in stock (that is, if you set any), downside is that the menu for all will be build every 30 seconds anew.
--          my_ctld.onestepmenu = false -- When set to true, the menu will create Drop and build, Get and load, Pack and remove, Pack and load, Pack. it will be a 1 step solution.
--          my_ctld.VehicleMoveFormation = AI.Task.VehicleFormation.VEE -- When a group moves to a MOVE zone, then it takes this formation. Can be a table of formations, which are then randomly chosen. Defaults to "Vee".
--          my_ctld.validateAndRepositionUnits = false -- Uses Disposition and other logic to find better ground positions for ground units avoiding trees, water, roads, runways, map scenery, statics and other units in the area. (Default is false)
--          my_ctld.loadSavedCrates = true -- Load back crates (STATIC) from the save file. Useful for mission restart cleanup. (Default is true)
--          my_ctld.UseC130LoadAndUnload = false -- When set to true, forces the C-130 player to use the C-130J built system to load the cargo onboard and to unload. (Default is false)
--
-- ## 2.1 CH-47 Chinook support
-- 
-- The Chinook comes with the option to use the ground crew menu to load and unload cargo into the Helicopter itself for better immersion. As well, it can sling-load cargo from ground. The cargo you can actually **create**
-- from this menu is limited to contain items from the airbase or FARP's resources warehouse and can take a number of shapes (static shapes in the category of cargo) independent of their contents. If you unload this
-- kind of cargo with the ground crew, the contents will be "absorbed" into the airbase or FARP you landed at, and the cargo static will be removed after ca 2 mins. 
-- 
-- ## 2.1.1 Moose CTLD created crate cargo
-- 
-- Given the correct shape, Moose created cargo can theoretically be either loaded with the ground crew or via the F10 CTLD menu. **It is strongly stated to avoid using shapes with 
-- CTLD which can be Ground Crew loaded.**
-- Static shapes loadable *into* the Chinook and thus to **be avoided for CTLD** are at the time of writing:
-- 
--      * Ammo box (type "ammo_crate")
--      * M117 bomb crate (type name "m117_cargo")
--      * Dual shell fuel barrels (type name "barrels")
--      * UH-1H net (type name "uh1h_cargo")
--      * C-130J-30 (type name "cds_crate")
--      * C-130J-30 (type name "cds_barrels")
--      * Small container (type name "iso_container_small") -- 4 of these will fit inside the C-130J-30
--      * Big container (type name "iso_container") -- 2 of these will fit inside the C-130J-30
--      
-- All other kinds of cargo can be sling-loaded.
--      
-- ## 2.1.2 Recommended settings
--          
--          my_ctld.onestepmenu = true -- This will enable Get and load, drop and build, etc. All will be done in one step. works for every module except the C-130J-30 with my_ctld.UseC130LoadAndUnload = true
--          my_ctld.C130basetype = "cds_crate" -- This can be changed to other cargo. This is only for the C-130J-30
--          my_ctld.basetype = "container_cargo" -- **DO NOT** change this to a base type which could also be loaded by F8/GC to avoid logic problems!
--          my_ctld.forcehoverload = false -- no hover autoload, leads to cargo complications with ground crew created cargo items
--          my_ctld.pilotmustopendoors = true -- crew must open back loading door 50% (horizontal) or more - watch out for NOT adding a back door gunner!
--          my_ctld.enableslingload = true -- will set cargo items as sling-loadable.
--          my_ctld.enableChinookGCLoading = true -- this will effectively suppress the crate load and drop for CTLD_CARGO.Enum.STATIC types for CTLD for the Chinook.
--          my_ctld.movecratesbeforebuild = true -- leave as is at the pain of building crate still **inside** of the Hook.
--          my_ctld.nobuildinloadzones = true -- don't build where you load.
--          my_ctld.ChinookTroopCircleRadius = 5 -- Radius for troops dropping in a nice circle. Adjust to your planned squad size for the Chinook.
--          
-- ## 2.2 User functions
-- 
-- ### 2.2.1 Adjust or add chopper unit-type capabilities
--  
-- Use this function to adjust what a heli type can or cannot do:
-- 
--        -- E.g. update unit capabilities for testing. Please stay realistic in your mission design.
--        -- Make a Gazelle into a heavy truck, this type can load both crates and troops and eight of each type, up to 4000 kgs:
--        my_ctld:SetUnitCapabilities("SA342L", true, true, 8, 8, 12, 4000)
--        
--        -- Default unit type capabilities are e.g. (list might be incomplete) 
--        ["SA342Mistral"] = {type="SA342Mistral", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 12, cargoweightlimit = 400},
--        ["SA342L"] = {type="SA342L", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 12, cargoweightlimit = 400},
--        ["SA342M"] = {type="SA342M", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 12, cargoweightlimit = 400},
--        ["SA342Minigun"] = {type="SA342Minigun", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 12, cargoweightlimit = 400},
--        ["UH-1H"] = {type="UH-1H", crates=true, troops=true, cratelimit = 1, trooplimit = 8, length = 15, cargoweightlimit = 700},
--        ["Mi-8MT"] = {type="Mi-8MT", crates=true, troops=true, cratelimit = 2, trooplimit = 12, length = 15, cargoweightlimit = 3000},
--        ["Mi-8MTV2"] = {type="Mi-8MTV2", crates=true, troops=true, cratelimit = 2, trooplimit = 12, length = 15, cargoweightlimit = 3000},
--        ["Ka-50"] = {type="Ka-50", crates=false, troops=false, cratelimit = 0, trooplimit = 0, length = 15, cargoweightlimit = 0},
--        ["Mi-24P"] = {type="Mi-24P", crates=true, troops=true, cratelimit = 2, trooplimit = 8, length = 18, cargoweightlimit = 700},
--        ["Mi-24V"] = {type="Mi-24V", crates=true, troops=true, cratelimit = 2, trooplimit = 8, length = 18, cargoweightlimit = 700},
--        ["Hercules"] = {type="Hercules", crates=true, troops=true, cratelimit = 7, trooplimit = 64, length = 25, cargoweightlimit = 19000},
--        ["C-130J-30"] = {type="C-130J-30", crates=true, troops=true, cratelimit = 7, trooplimit = 64, length = 35, cargoweightlimit = 21500},
--        ["UH-60L"] = {type="UH-60L", crates=true, troops=true, cratelimit = 2, trooplimit = 20, length = 16, cargoweightlimit = 3500},
--        ["AH-64D_BLK_II"] = {type="AH-64D_BLK_II", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 17, cargoweightlimit = 200}, 
--        ["MH-60R"] = {type="MH-60R", crates=true, troops=true, cratelimit = 2, trooplimit = 20, length = 16, cargoweightlimit = 3500}, -- 4t cargo, 20 (unsec) seats
--        ["SH-60B"] = {type="SH-60B", crates=true, troops=true, cratelimit = 2, trooplimit = 20, length = 16, cargoweightlimit = 3500}, -- 4t cargo, 20 (unsec) seats
--        ["Bronco-OV-10A"] = {type="Bronco-OV-10A", crates= false, troops=true, cratelimit = 0, trooplimit = 5, length = 13, cargoweightlimit = 1450},
--        ["OH-6A"] = {type="OH-6A", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 7, cargoweightlimit = 550},
--        ["OH58D"] = {type="OH58D", crates=false, troops=false, cratelimit = 0, trooplimit = 0, length = 14, cargoweightlimit = 400},
--        ["CH-47Fbl1"] = {type="CH-47Fbl1", crates=true, troops=true, cratelimit = 4, trooplimit = 31, length = 20, cargoweightlimit = 8000},
--        
-- ### 2.2.2 Activate and deactivate zones
-- 
-- Activate a zone:
-- 
--        -- Activate zone called Name of type #CTLD.CargoZoneType ZoneType:
--        my_ctld:ActivateZone(Name,CTLD.CargoZoneType.MOVE)
-- 
-- Deactivate a zone:
-- 
--        -- Deactivate zone called Name of type #CTLD.CargoZoneType ZoneType:
--        my_ctld:DeactivateZone(Name,CTLD.CargoZoneType.DROP)
-- 
-- ## 2.2.3 Limit and manage available resources
--  
--  When adding generic cargo types, you can effectively limit how many units can be dropped/build by the players, e.g.
--  
--              -- if you want to limit your stock, add a number (here: 10) as parameter after weight. No parameter / nil means unlimited stock.
--              my_ctld:AddCratesCargo("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,2,2775,10)
--  
--  You can manually add or remove the available stock like so:
--            
--              -- Crates
--              my_ctld:AddStockCrates("Humvee", 2)
--              my_ctld:RemoveStockCrates("Humvee", 2)
--              
--              -- Troops
--              my_ctld:AddStockTroops("Anti-Air", 2)
--              my_ctld:RemoveStockTroops("Anti-Air", 2)
--              
--              -- Units for the C-130J-30
--              my_ctld:AddStockUnits("Vulcan", 2)
--              my_ctld:RemoveStockUnits("Vulcan", 2)
--  
--  Notes:
--  Troops dropped back into a LOAD zone will effectively be added to the stock. Crates lost in e.g. a heli crash are just that - lost.
--  
-- ## 2.2.4 Create own SET_GROUP to manage CTLD Pilot groups
-- 
--              -- Parameter: Set The SET_GROUP object created by the mission designer/user to represent the CTLD pilot groups.
--              -- Needs to be set before starting the CTLD instance.
--              local myset = SET_GROUP:New():FilterPrefixes("Helikopter"):FilterCoalitions("red"):FilterStart()
--              my_ctld:SetOwnSetPilotGroups(myset)
-- 
-- ## 3. Events
--
--  The class comes with a number of FSM-based events that missions designers can use to shape their mission.
--  These are:
-- 
-- ## 3.1 OnAfterTroopsPickedUp
-- 
--   This function is called when a player has loaded Troops:
--
--        function my_ctld:OnAfterTroopsPickedUp(From, Event, To, Group, Unit, Cargo)
--          ... your code here ...
--        end
-- 
-- ## 3.2 OnAfterCratesPickedUp
-- 
--    This function is called when a player has picked up crates:
--
--        function my_ctld:OnAfterCratesPickedUp(From, Event, To, Group, Unit, Cargo)
--          ... your code here ...
--        end
--  
-- ## 3.3 OnAfterTroopsDeployed
--  
--    This function is called when a player has deployed troops into the field:
--
--        function my_ctld:OnAfterTroopsDeployed(From, Event, To, Group, Unit, Troops)
--          ... your code here ...
--        end
--        
-- ## 3.4 OnAfterTroopsExtracted
--  
--    This function is called when a player has re-boarded already deployed troops from the field:
--
--        function my_ctld:OnAfterTroopsExtracted(From, Event, To, Group, Unit, Troops, Troopname)
--          ... your code here ...
--        end
--  
-- ## 3.5 OnAfterCratesDropped
--  
--    This function is called when a player has deployed crates:
--
--        function my_ctld:OnAfterCratesDropped(From, Event, To, Group, Unit, Cargotable)
--          ... your code here ...
--        end
--
-- ## 3.5 A OnAfterGetCrates
--  
--    This function is called after a player has spawned crates via the "Get" menu (but not when using "Get and Load"):
--
--        function my_ctld:OnAfterGetCrates(From, Event, To, Group, Unit, Cargotable)
--          ... your code here ...
--        end
--
-- ## 3.5 b OnAfterRemoveCratesNearby
--  
--    This function is called after a player has removed things nearby via CTLD “Remove … nearby”.
--    It can be triggered from:
--      - Removing crates (“Remove crates nearby” menu)
--      - Removing C-130 managed unit-groups (“Remove units nearby”)
--
--        function my_ctld:OnAfterRemoveCratesNearby(From, Event, To, Group, Unit, Cargotable)
--          ... your code here ...
--        end
--
-- ## 3.6 A OnAfterHelicopterLost
--  
--    This function is called when a player has left the helicopter or crashed/died:
--
--        function my_ctld:OnAfterHelicopterLost(From, Event, To, Unitname, Cargotable)
--          ... your code here ...
--        end  
--  
-- ## 3.6 B OnAfterCratesBuild, OnAfterCratesRepaired
--  
--    This function is called when a player has built a vehicle or FOB:
--
--        function my_ctld:OnAfterCratesBuild(From, Event, To, Group, Unit, Vehicle)
--          ... your code here ...
--        end
--        
--        function my_ctld:OnAfterCratesRepaired(From, Event, To, Group, Unit, Vehicle)
--          ... your code here ...
--        end
--
-- ## 3.6 C OnAfterUnitsSpawn
--
--   This function is called when a player spawns units using the Get Unit menu, only available for the C-130J-30 when my_ctld.UseC130LoadAndUnload = true
--
--        function my_ctld:OnAfterUnitsSpawn(From, Event, To, Group, Unit, Units)
--          -- Units is a table of Wrapper.Group#GROUP objects that were spawned
--        end
 --
-- ## 3.7 A simple SCORING example:
--  
--    To award player with points, using the SCORING Class (SCORING: my_Scoring, CTLD: CTLD_Cargotransport)
--
--        my_scoring = SCORING:New("Combat Transport")
--
--        function CTLD_Cargotransport:OnAfterCratesDropped(From, Event, To, Group, Unit, Cargotable)
--            local points = 10
--            if Unit then
--              local PlayerName = Unit:GetPlayerName()
--              my_scoring:_AddPlayerFromUnit( Unit )
--              my_scoring:AddGoalScore(Unit, "CTLD", string.format("Pilot %s has been awarded %d points for transporting cargo crates!", PlayerName, points), points)
--            end
--        end
--        
--        function CTLD_Cargotransport:OnAfterCratesBuild(From, Event, To, Group, Unit, Vehicle)
--          local points = 5
--          if Unit then
  --          local PlayerName = Unit:GetPlayerName()
  --          my_scoring:_AddPlayerFromUnit( Unit )
  --          my_scoring:AddGoalScore(Unit, "CTLD", string.format("Pilot %s has been awarded %d points for the construction of Units!", PlayerName, points), points)
--          end
--         end
--  
-- ## 4. F10 Menu structure
-- 
-- CTLD management menu is under the F10 top menu and called "CTLD"
-- 
-- ## 4.1 Manage Crates
-- 
-- Use this entry to get, load, list nearby, drop, build and repair crates. Also see options.
-- 
-- ## 4.2 Manage Troops
-- 
-- Use this entry to load, drop and extract troops. NOTE - with extract you can only load troops from the field that were deployed prior. 
-- Currently limited to CTLD_CARGO troops, which are built from **one** template. Also, this will heal/complete your units as they are respawned.
-- 
-- ## 4.3 List boarded cargo
-- 
-- Lists what you have loaded. Shows load capabilities for number of crates and number of seats for troops.
-- 
-- ## 4.4 Smoke & Flare zones nearby or drop smoke, beacon or flare from Heli
-- 
-- Does what it says.
-- 
-- ## 4.5 List active zone beacons
-- 
-- Lists active radio beacons for all zones, where zones are both active and have a beacon. @see `CTLD:AddCTLDZone()`
-- 
-- ## 4.6 Show hover parameters
-- 
-- Lists hover parameters and indicates if these are currently fulfilled. Also @see options on hover heights.
-- 
-- ## 4.7 List Inventory
-- 
-- Lists inventory of available units to drop or build.
-- 
-- ## 5. Support for fixed wings
-- 
-- Basic support for the Hercules mod By Anubis has been build into CTLD, as well as Bronco and Mosquito - that is you can load/drop/build the same way and for the same objects as 
-- the helicopters (main method). 
-- To cover objects and troops which can be loaded from the ground crew Rearm/Refuel menu (F8), you need to use @{#CTLD_HERCULES.New}() and link
-- this object to your CTLD setup (alternative method). In this case, do **not** use the `Hercules_Cargo.lua` or `Hercules_Cargo_CTLD.lua` which are part of the mod 
-- in your mission!
-- 
-- ### 5.1 Create an own CTLD instance and allow the usage of the Hercules mod (main method)
-- 
--
--              local my_ctld = CTLD:New(coalition.side.BLUE,{"Helicargo", "Hercules"},"Lufttransportbrigade I") -- This is only needed for the Hercules mod and not the C-130J-30
-- 
-- Enable these options for Hercules support:
--  
--              my_ctld.enableFixedWing = true -- false by default.
--              my_ctld.FixedMinAngels = 155 -- for troop/cargo drop via chute in meters, ca 470 ft
--              my_ctld.FixedMaxAngels = 2000 -- for troop/cargo drop via chute in meters, ca 6000 ft
--              my_ctld.FixedMaxSpeed = 77 -- 77mps or 270kph or 150kn
-- 
-- Hint: you can **only** airdrop from the Hercules if you are "in parameters", i.e. at or below `FixedMaxSpeed` and in the AGL range between
-- `FixedMinAngels` and `FixedMaxAngels`!
-- 
-- Also, the following options need to be set to `true`:
-- 
--              my_ctld.useprefix = true -- this is true by default and MUST BE ON. 
-- 
-- ### 5.2 Integrate Hercules ground crew (F8 Menu) loadable objects (alternative method, use either the above OR this method, NOT both!) -- Only needed for the Hercules mod!
-- 
-- Taking another approach, integrate to your CTLD instance like so, where `my_ctld` is a previously created CTLD instance:
--            
--            my_ctld.enableFixedWing = false -- avoid dual loading via CTLD F10 and F8 ground crew
--            local herccargo = CTLD_HERCULES:New("blue", "Hercules Test", my_ctld)
--            
-- You also need: 
-- 
-- * A template called "Infantry" for 10 Paratroopers (as set via herccargo.infantrytemplate).   
-- * Depending on what you are loading with the help of the ground crew, there are 42 more templates for the various vehicles that are loadable.   
-- 
-- There's a **quick check output in the `dcs.log`** which tells you what's there and what not.
-- E.g.:   
-- 
--            ...Checking template for APC BTR-82A Air [24998lb] (BTR-82A) ... MISSING)   
--            ...Checking template for ART 2S9 NONA Skid [19030lb] (SAU 2-C9) ... MISSING)   
--            ...Checking template for EWR SBORKA Air [21624lb] (Dog Ear radar) ... MISSING)   
--            ...Checking template for Transport Tigr Air [15900lb] (Tigr_233036) ... OK)   
--
-- Expected template names are the ones in the rounded brackets.
--
-- ### 5.2.1 Hints
-- 
-- The script works on the EVENTS.Shot trigger, which is used by the mod when you **drop cargo from the Hercules while flying**. Unloading on the ground does
-- not achieve anything here. If you just want to unload on the ground, use the normal Moose CTLD (see 5.1).
-- 
-- DO NOT use the "splash damage" script together with this method! Your cargo will explode on the ground!
-- 
-- There are two ways of airdropping: 
--   
-- 1) Very low and very slow (>5m and <10m AGL) - here you can drop stuff which has "Skid" at the end of the cargo name (loaded via F8 Ground Crew menu)   
-- 2) Higher up and slow (>100m AGL) - here you can drop paratroopers and cargo which has "Air" at the end of the cargo name (loaded via F8 Ground Crew menu)   
-- 
-- Standard transport capabilities as per the real Hercules are:
-- 
--               ["Hercules"] = {type="Hercules", crates=true, troops=true, cratelimit = 7, trooplimit = 64}, -- 19t cargo, 64 paratroopers
--  
-- ### 5.3 Don't automatically unpack dropped cargo but drop as CTLD_CARGO
-- 
-- Cargo can be defined to be automatically dropped as crates.
--              my_ctld.dropAsCargoCrate = true -- default is false
--
-- The idea is to have those crates behave like brought in with a helo, so any unpack restrictions apply.
-- To enable those cargo drops, the cargo types must be added manually in the CTLD configuration. So when the above defined template for "Vulcan" should be used
-- as CTLD_Cargo, the following line has to be added. NoCrates, PerCrateMass, Stock, SubCategory can be configured freely.
--              my_ctld:AddCratesCargo("Vulcan",      {"Vulcan"}, CTLD_CARGO.Enum.VEHICLE, 6, 2000, nil, "SAM/AAA")
--
-- So if the Vulcan in the example now needs six crates to complete, you have to bring two Hercs with three Vulcan crates each and drop them very close together...
--
--  ### 5.4 C-130J-30 support
--
--  The C130-J-30 will work only by setting up
--
--              my_ctld.enableFixedWing = true -- false by default.
--
--              -- The rest below is default values but can be changed to something else.
--
--              my_ctld.C130basetype = "cds_crate" -- this is default.
--              my_ctld.FixedMinAngels = 155 -- for troop/cargo drop via chute in meters, ca 470 ft
--              my_ctld.FixedMaxAngels = 2000 -- for troop/cargo drop via chute in meters, ca 6000 ft
--              my_ctld.FixedMaxSpeed = 77 -- 77mps or 270kph or 150kn
--
--
--  You can also enable my_ctld.UseC130LoadAndUnload and set it to true, false is default, this means you will not be able to get and load items but rather "Get" only.
--  Those crates will be then placed at the back of the C-130J-30 and you'll have to use the built in loading system to load those crates.
--  With that option enabled, you'll even get a new menu called Manage Units where you can get real units instead of crates. Those units is not limited to what fits inside
--  the C-130J-30, but rather by what you add.
--
--  Example: 
--
--             my_ctld:AddUnits("Humvee",{"CTLD_CARGO_HMMWV"},CTLD_CARGO.Enum.VEHICLE,10, "ANTI TANK")
--             my_ctld:AddUnits("Mephisto",{"CTLD_CARGO_Mephisto"},CTLD_CARGO.Enum.VEHICLE,10, "ANTI TANK")
--             my_ctld:AddUnits("Vulcan",{"CTLD_CARGO_Vulcan"}, CTLD_CARGO.Enum.VEHICLE, 10, "SAM/AAA")
--             my_ctld:AddUnits("Avenger",{"CTLD_CARGO_Avenger"}, CTLD_CARGO.Enum.VEHICLE, 10, "SAM/AAA")
--             my_ctld:AddUnits("Humvee scout",{"CTLD_CARGO_Scout"}, CTLD_CARGO.Enum.VEHICLE, 10, "Support")
--             my_ctld:AddUnits("FV-107 Scimitar",{"CTLD_CARGO_Scimitar"}, CTLD_CARGO.Enum.VEHICLE, 10, "Support")
--             my_ctld:AddUnits("FV-101 Scorpion",{"CTLD_CARGO_Scorpion"}, CTLD_CARGO.Enum.VEHICLE, 10, "Support")
--
--             With the example above, we have my_ctld.usesubcats = true, which enables sub menus for categories. like the Anti tank units and support units, etc.
--             the 10 before that is how many we shall have in stock. Once that stock amount is reached, those items will not be available anymore.
--
--
-- ## 6. Save and load back units - persistence
-- 
-- You can save and later load back units dropped or build to make your mission persistent.
-- For this to work, you need to de-sanitize **io** and **lfs** in your MissionScripting.lua, which is located in your DCS installation folder under Scripts.
-- There is a risk involved in doing that; if you do not know what that means, this is possibly not for you.
--
--
-- 
-- Use the following options to manage your saves:
-- 
--              my_ctld.enableLoadSave = true -- allow auto-saving and loading of files
--              my_ctld.saveinterval = 600 -- save every 10 minutes
--              my_ctld.filename = "missionsave.csv" -- example filename
--              my_ctld.filepath = "C:\\Users\\myname\\Saved Games\\DCS\Missions\\MyMission" -- example path
--              my_ctld.eventoninject = true -- fire OnAfterCratesBuild and OnAfterTroopsDeployed events when loading (uses Inject functions)
--              my_ctld.useprecisecoordloads = true -- Instead if slightly varying the group position, try to maintain it as is
--  
--  Then use an initial load at the beginning of your mission:
--  
--            my_ctld:__Load(10)
--            
-- **Caveat:**
-- If you use units built by multiple templates, they will effectively double on loading. Dropped crates are not saved. Current stock is not saved.
-- 
-- ## 7. Complex example - Build a complete FARP from a CTLD crate drop
-- 
-- Prerequisites - you need to add a cargo of type FOB to your CTLD instance, for simplification reasons we call it FOB:
-- 
--            my_ctld:AddCratesCargo("FARP",{"FOB"},CTLD_CARGO.Enum.FOB,2)
--            
-- The following code will build a FARP at the coordinate the FOB was dropped and built (the UTILS function used below **does not** need a template for the statics):
--            
--          -- FARP Radio. First one has 130AM name London, next 131 name Dallas, and so forth. 
--          local FARPFreq = 129
--          local FARPName = 1  --numbers 1..10
-- 
--          local FARPClearnames = {
--            [1]="London",
--            [2]="Dallas",
--            [3]="Paris",
--            [4]="Moscow",
--            [5]="Berlin",
--            [6]="Rome",
--            [7]="Madrid",
--            [8]="Warsaw",
--            [9]="Dublin",
--            [10]="Perth",
--            }
-- 
--          function BuildAFARP(Coordinate)
--            local coord = Coordinate  --Core.Point#COORDINATE
--
--            local FarpNameNumber = ((FARPName-1)%10)+1 -- make sure 11 becomes 1 etc
--            local FName = FARPClearnames[FarpNameNumber] -- get clear name
--  
--            FARPFreq = FARPFreq + 1
--            FARPName = FARPName + 1
--  
--            FName = FName .. " FAT COW "..tostring(FARPFreq).."AM" -- make name unique
--  
--            -- Get a Zone for loading 
--            local ZoneSpawn = ZONE_RADIUS:New("FARP "..FName,Coordinate:GetVec2(),150,false)
--  
--            -- Spawn a FARP with our little helper and fill it up with resources (10t fuel each type, 10 pieces of each known equipment)
--            UTILS.SpawnFARPAndFunctionalStatics(FName,Coordinate,ENUMS.FARPType.INVISIBLE,my_ctld.coalition,country.id.USA,FarpNameNumber,FARPFreq,radio.modulation.AM,nil,nil,nil,10,10)
-- 
--            -- add a loadzone to CTLD
--            my_ctld:AddCTLDZone("FARP "..FName,CTLD.CargoZoneType.LOAD,SMOKECOLOR.Blue,true,true)
--            local m  = MESSAGE:New(string.format("FARP %s in operation!",FName),15,"CTLD"):ToBlue() 
--          end
--
--          function my_ctld:OnAfterCratesBuild(From,Event,To,Group,Unit,Vehicle)
--            local name = Vehicle:GetName()
--            if string.find(name,"FOB",1,true) then
--              local Coord = Vehicle:GetCoordinate()
--              Vehicle:Destroy(false)
--              BuildAFARP(Coord) 
--            end
--          end
-- 
-- ## 8. Transport crates and troops with CA (Combined Arms) trucks
-- 
-- You can optionally also allow CTLD with CA trucks and other vehicles:
-- 
--          -- Create a SET_CLIENT to capture CA vehicles steered by players
--          local truckers = SET_CLIENT:New():HandleCASlots():FilterCoalitions("blue"):FilterPrefixes("Truck"):FilterStart()
--          -- Allow CA transport
--          my_ctld:AllowCATransport(true,truckers)
--          -- Set truck capability by typename
--          my_ctld:SetUnitCapabilities("M 818", true, true, 2, 12, 9, 4500)
--          -- Alternatively set truck capability with a UNIT object
--          local GazTruck = UNIT:FindByName("GazTruck-1-1")
--          my_ctld:SetUnitCapabilities(GazTruck, true, true, 2, 12, 9, 4500)
-- 
--
-- @field #CTLD
CTLD = {
  ClassName       = "CTLD",
  verbose         = 0,
  lid             = "",
  coalition       = 1,
  coalitiontxt    = "blue",
  PilotGroups = {}, -- #GROUP_SET of heli pilots
  CtldUnits = {},   -- Table of helicopter #GROUPs
  FreeVHFFrequencies = {}, -- Table of VHF
  FreeUHFFrequencies = {}, -- Table of UHF
  FreeFMFrequencies = {}, -- Table of FM
  CargoCounter = 0,
  Cargo_Troops = {}, -- generic troops objects
  Cargo_Crates = {}, -- generic crate objects
  Loaded_Cargo = {}, -- cargo aboard units
  Spawned_Crates = {}, -- Holds objects for crates spawned generally
  Spawned_Cargo = {}, -- Binds together spawned_crates and their CTLD_CARGO objects
  CrateDistance = 35, -- list crates in this radius
  PackDistance = 35,  -- pack crates in this radius
  debug = false,
  wpZones = {},
  dropOffZones = {},
  pickupZones  = {},
  DynamicCargo = {},
  ChinookTroopCircleRadius = 5,
  TroopUnloadDistGround = 5,
  TroopUnloadDistGroundHerc = 25,
  TroopUnloadDistGroundHook = 15,
  TroopUnloadDistHoverHook = 5,
  TroopUnloadDistHover = 1.5,
  UserSetGroup = nil,
  LoadedGroupsTable = {},
  keeploadtable = true,
  allowCATransport = false,
  VehicleMoveFormation = AI.Task.VehicleFormation.VEE,
}

------------------------------
-- DONE: Zone Checks
-- DONE: TEST Hover load and unload
-- DONE: Crate unload
-- DONE: Hover (auto-)load
-- DONE: (More) Housekeeping
-- DONE: Troops running to WP Zone
-- DONE: Zone Radio Beacons
-- DONE: Stats Running
-- DONE: Added support for Hercules
-- TODO: Possibly - either/or loading crates and troops
-- DONE: Make inject respect existing cargo types
-- DONE: Drop beacons or flares/smoke
-- DONE: Add statics as cargo
-- DONE: List cargo in stock
-- DONE: Limit of troops, crates buildable?
-- DONE: Allow saving of Troops & Vehicles
-- DONE: Adding re-packing dropped units
------------------------------

--- Radio Beacons
-- @type CTLD.ZoneBeacon
-- @field #string name -- Name of zone for the coordinate
-- @field #number frequency -- in mHz
-- @field #number modulation -- i.e.CTLD.RadioModulation.FM or CTLD.RadioModulation.AM

--- Radio Modulation
-- @type CTLD.RadioModulation
-- @field #number AM
-- @field #number FM
CTLD.RadioModulation = {
  AM = 0,
  FM = 1,
}

--- Loaded Cargo
-- @type CTLD.LoadedCargo
-- @field #number Troopsloaded
-- @field #number Cratesloaded
-- @field #table Cargo Table of #CTLD_CARGO objects

--- Zone Info.
-- @type CTLD.CargoZone
-- @field #string name Name of Zone.
-- @field #string color Smoke color for zone, e.g. SMOKECOLOR.Red.
-- @field #boolean active Active or not.
-- @field #string type Type of zone, i.e. load,drop,move,ship
-- @field #boolean hasbeacon Create and run radio beacons if active.
-- @field #table fmbeacon Beacon info as #CTLD.ZoneBeacon
-- @field #table uhfbeacon Beacon info as #CTLD.ZoneBeacon
-- @field #table vhfbeacon Beacon info as #CTLD.ZoneBeacon
-- @field #number shiplength For ships - length of ship
-- @field #number shipwidth For ships - width of ship
-- @field #number timestamp For dropped beacons - time this was created

--- Zone Type Info.
-- @type CTLD.CargoZoneType
CTLD.CargoZoneType = {
  LOAD = "load",
  DROP = "drop",
  MOVE = "move",
  SHIP = "ship",
  BEACON = "beacon",
}

--- Buildable table info.
-- @type CTLD.Buildable
-- @field #string Name Name of the object.
-- @field #number Required Required crates.
-- @field #number Found Found crates.
-- @field #table Template Template names for this build.
-- @field #boolean CanBuild Is buildable or not.
-- @field #CTLD_CARGO.Enum Type Type enumerator (for moves).

--- Unit capabilities.
-- @type CTLD.UnitTypeCapabilities
-- @field #string type Unit type.
-- @field #boolean crates Can transport crate.
-- @field #boolean troops Can transport troops.
-- @field #number cratelimit Number of crates transportable.
-- @field #number trooplimit Number of troop units transportable.
-- @field #number cargoweightlimit Max loadable kgs of cargo.
CTLD.UnitTypeCapabilities = {
    ["SA342Mistral"] = {type="SA342Mistral", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 12, cargoweightlimit = 400},
    ["SA342L"] = {type="SA342L", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 12, cargoweightlimit = 400},
    ["SA342M"] = {type="SA342M", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 12, cargoweightlimit = 400},
    ["SA342Minigun"] = {type="SA342Minigun", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 12, cargoweightlimit = 400},
    ["UH-1H"] = {type="UH-1H", crates=true, troops=true, cratelimit = 1, trooplimit = 8, length = 15, cargoweightlimit = 700},
    ["Mi-8MTV2"] = {type="Mi-8MTV2", crates=true, troops=true, cratelimit = 2, trooplimit = 12, length = 15, cargoweightlimit = 3000},
    ["Mi-8MT"] = {type="Mi-8MT", crates=true, troops=true, cratelimit = 2, trooplimit = 12, length = 15, cargoweightlimit = 3000},
    ["Ka-50"] = {type="Ka-50", crates=false, troops=false, cratelimit = 0, trooplimit = 0, length = 15, cargoweightlimit = 0},
    ["Ka-50_3"] = {type="Ka-50_3", crates=false, troops=false, cratelimit = 0, trooplimit = 0, length = 15, cargoweightlimit = 0},
    ["Mi-24P"] = {type="Mi-24P", crates=true, troops=true, cratelimit = 2, trooplimit = 8, length = 18, cargoweightlimit = 700},
    ["Mi-24V"] = {type="Mi-24V", crates=true, troops=true, cratelimit = 2, trooplimit = 8, length = 18, cargoweightlimit = 700},
    ["Hercules"] = {type="Hercules", crates=true, troops=true, cratelimit = 7, trooplimit = 64, length = 25, cargoweightlimit = 19000}, -- 19t cargo, 64 paratroopers.
    ["C-130J-30"] = {type="C-130J-30", crates=true, troops=true, cratelimit = 7, trooplimit = 64, length = 35, cargoweightlimit = 21500}, -- 19t cargo, 64 paratroopers. 
    --Actually it's longer, but the center coord is off-center of the model.
    ["UH-60L"] = {type="UH-60L", crates=true, troops=true, cratelimit = 2, trooplimit = 20, length = 16, cargoweightlimit = 3500}, -- 4t cargo, 20 (unsec) seats
    ["UH-60L_DAP"] = {type="UH-60L_DAP", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 16, cargoweightlimit = 500}, -- UH-60L DAP is an attack helo but can do limited CSAR and CTLD
    ["MH-60R"] = {type="MH-60R", crates=true, troops=true, cratelimit = 2, trooplimit = 20, length = 16, cargoweightlimit = 3500}, -- 4t cargo, 20 (unsec) seats
    ["SH-60B"] = {type="SH-60B", crates=true, troops=true, cratelimit = 2, trooplimit = 20, length = 16, cargoweightlimit = 3500}, -- 4t cargo, 20 (unsec) seats
    ["AH-64D_BLK_II"] = {type="AH-64D_BLK_II", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 17, cargoweightlimit = 200}, -- 2 ppl **outside** the helo
    ["Bronco-OV-10A"] = {type="Bronco-OV-10A", crates= false, troops=true, cratelimit = 0, trooplimit = 5, length = 13, cargoweightlimit = 1450},
    ["AH-6J"] = {type="AH-6J", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 7, cargoweightlimit = 550},
    ["MH-6J"] = {type="MH-6J", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 7, cargoweightlimit = 550},
    ["OH-6A"] = {type="OH-6A", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 7, cargoweightlimit = 550},
    ["OH58D"] = {type="OH58D", crates=false, troops=false, cratelimit = 0, trooplimit = 0, length = 14, cargoweightlimit = 400},
    ["CH-47Fbl1"] = {type="CH-47Fbl1", crates=true, troops=true, cratelimit = 4, trooplimit = 31, length = 20, cargoweightlimit = 10800},
    ["MosquitoFBMkVI"] = {type="MosquitoFBMkVI", crates= true, troops=false, cratelimit = 2, trooplimit = 0, length = 13, cargoweightlimit = 1800},
    ["M 818"] = {type="M 818", crates= true, troops=true, cratelimit = 4, trooplimit = 12, length = 9, cargoweightlimit = 4500},
}

--- Allowed Fixed Wing Types
-- @type CTLD.FixedWingTypes
CTLD.FixedWingTypes = {
  ["Hercules"] = "Hercules",
  ["Bronco"] = "Bronco",
  ["Mosquito"] = "Mosquito",
  ["C-130J-30"] = "C-130J-30",
}

--- CTLD class version.
-- @field #string version
CTLD.version="1.3.43"

--- Instantiate a new CTLD.
-- @param #CTLD self
-- @param #string Coalition Coalition of this CTLD. I.e. coalition.side.BLUE or coalition.side.RED or coalition.side.NEUTRAL
-- @param #table Prefixes Table of pilot prefixes.
-- @param #string Alias Alias of this CTLD for logging.
-- @return #CTLD self
function CTLD:New(Coalition, Prefixes, Alias)
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #CTLD
  
  BASE:T({Coalition, Prefixes, Alias})
  
  --set Coalition
  if Coalition and type(Coalition)=="string" then
    if Coalition=="blue" then
      self.coalition=coalition.side.BLUE
      self.coalitiontxt = Coalition
    elseif Coalition=="red" then
      self.coalition=coalition.side.RED
      self.coalitiontxt = Coalition
    elseif Coalition=="neutral" then
      self.coalition=coalition.side.NEUTRAL
      self.coalitiontxt = Coalition
    else
      self:E("ERROR: Unknown coalition in CTLD!")
    end
  else
    self.coalition = Coalition
    self.coalitiontxt = string.lower(UTILS.GetCoalitionName(self.coalition))
  end
  
  -- Set alias.
  if Alias then
    self.alias=tostring(Alias)
  else
    self.alias="UNHCR"  
    if self.coalition then
      if self.coalition==coalition.side.RED then
        self.alias="Red CTLD"
      elseif self.coalition==coalition.side.BLUE then
        self.alias="Blue CTLD"
      end
    end
  end
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event        -->      To State
  self:AddTransition("Stopped",       "Start",               "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",              "*")           -- CTLD status update.
  self:AddTransition("*",             "TroopsPickedUp",      "*")           -- CTLD pickup  event. 
  self:AddTransition("*",             "TroopsExtracted",     "*")           -- CTLD extract  event. 
  self:AddTransition("*",             "CratesPickedUp",      "*")           -- CTLD pickup  event.  
  self:AddTransition("*",             "TroopsDeployed",      "*")           -- CTLD deploy  event. 
  self:AddTransition("*",             "TroopsRTB",           "*")           -- CTLD deploy  event.   
  self:AddTransition("*",             "CratesDropped",       "*")           -- CTLD deploy  event.
  self:AddTransition("*",             "GetCrates",           "*")           -- CTLD getcrates event.
  self:AddTransition("*",             "CratesBuild",         "*")           -- CTLD build  event.
  self:AddTransition("*",             "UnitsSpawn",          "*")           -- CTLD Unit spawned.
  self:AddTransition("*",             "CratesRepaired",      "*")           -- CTLD repair  event.
  self:AddTransition("*",             "CratesBuildStarted",  "*")           -- CTLD build  event.
  self:AddTransition("*",             "CratesRepairStarted", "*")           -- CTLD repair  event.
  self:AddTransition("*",             "CratesPacked",        "*")           -- CTLD repack  event.
  self:AddTransition("*",             "HelicopterLost",      "*")           -- CTLD lost  event.
  self:AddTransition("*",             "RemoveCratesNearby",  "*")           -- CTLD players remove crates or units nearby.
  self:AddTransition("*",             "Load",                "*")           -- CTLD load  event.
  self:AddTransition("*",             "Loaded",              "*")           -- CTLD load  event.   
  self:AddTransition("*",             "Save",                "*")           -- CTLD save  event.      
  self:AddTransition("*",             "Stop",                "Stopped")     -- Stop FSM.
  
  -- tables
  self.PilotGroups ={}
  self.CtldUnits = {}
  
  -- Beacons
  self.FreeVHFFrequencies = {}
  self.FreeUHFFrequencies = {}
  self.FreeFMFrequencies = {}
  self.UsedVHFFrequencies = {}
  self.UsedUHFFrequencies = {}
  self.UsedFMFrequencies = {}
  
  -- radio beacons
  self.RadioSound = "beacon.ogg"
  self.RadioSoundFC3 = "beacon.ogg"
  self.RadioPath = "l10n/DEFAULT/"
  
  -- zones stuff
  self.pickupZones  = {}
  self.dropOffZones = {}
  self.wpZones = {}
  self.shipZones = {}
  self.droppedBeacons = {}
  self.droppedbeaconref = {}
  self.droppedbeacontimeout = 600
  self.useprecisecoordloads = true
  
  -- Cargo
  self.Cargo_Crates = {}
  self.Cargo_Troops = {}
  self.Cargo_Statics = {}
  self.Loaded_Cargo = {}
  self.Spawned_Crates = {}
  self.Spawned_Cargo = {}
  self.MenusDone = {}
  self.DroppedTroops = {}
  self.DroppedCrates = {}
  self.CargoCounter = 0
  self.CrateCounter = 0
  self.TroopCounter = 0
  
  -- added engineering
  self.Engineers = 0 -- #number use as counter
  self.EngineersInField = {} -- #table holds #CTLD_ENGINEERING objects
  self.EngineerSearch = 2000 -- #number search distance for crates to build or repair
  self.nobuildmenu = false -- enfore engineer build only?
  
  -- setup
  self.CrateDistance = 35 -- list/load crates in this radius (meters)
  self.UnitDistance = 90 -- Units in this radius for the C-130J-30 to check for nearby units (meters)
  self.maxUnitsNearby = 3 -- Max units allowed to be build if the amount of the default 3 is exceeded when looking what's nearby
  self.PackDistance = 35 -- pack objects in this radius
  self.ExtractFactor = 3.33 -- factor for troops extraction, i.e. CrateDistance * Extractfactor
  self.prefixes = Prefixes or {"Cargoheli"}
  self.useprefix = true
  
  self.maximumHoverHeight = 15
  self.minimumHoverHeight = 4
  self.forcehoverload = true
  self.hoverautoloading = true
  self.dropcratesanywhere = false -- #1570
  self.dropAsCargoCrate = false -- Parachuted herc cargo is not unpacked automatically but placed as crate to be unpacked

  self.smokedistance = 2000
  self.movetroopstowpzone = true
  self.movetroopsdistance = 5000
  self.returntroopstobase = true -- if set to false, troops would stay after deployment inside a load zone.
  self.troopdropzoneradius = 100
  self.buildPairSeparation = 25
  self.loadSavedCrates = true
  self.VehicleMoveFormation = AI.Task.VehicleFormation.VEE
  
  -- added support Hercules Mod
  self.enableHercules = false -- deprecated
  self.enableFixedWing = false
  self.FixedMinAngels = 165 -- for troop/cargo drop via chute
  self.FixedMaxAngels = 2000 -- for troop/cargo drop via chute
  self.FixedMaxSpeed = 77 -- 280 kph or 150kn eq 77 mps

  self.validateAndRepositionUnits = false -- 280 kph or 150kn eq 77 mps

  -- message suppression
  self.suppressmessages = false
  
  -- time to repairor build a unit/group
  self.repairtime = 300
  self.buildtime = 300
  
  -- place spawned crates in front of aircraft
  self.placeCratesAhead = false
  
  -- country of crates spawned
  self.cratecountry = country.id.GERMANY
  
  -- for opening doors
  self.pilotmustopendoors = false
  
  if self.coalition == coalition.side.RED then
     self.cratecountry = country.id.RUSSIA
  end
  
  -- load and save dropped TROOPS
  self.enableLoadSave = false
  self.filepath = nil
  self.saveinterval = 600
  self.eventoninject = true
  self.keeploadtable = true
  self.LoadedGroupsTable = {}
  
  -- sub categories
  self.usesubcats = false
  self.subcats = {}
  self.subcatsTroop = {}
  self.showstockinmenuitems = false
  self.maxCrateMenuQuantity = 5
  self.onestepmenu = false
  
  -- disallow building in loadzones
  self.nobuildinloadzones = true
  self.movecratesbeforebuild = true
  self.surfacetypes = {land.SurfaceType.LAND,land.SurfaceType.ROAD,land.SurfaceType.RUNWAY,land.SurfaceType.SHALLOW_WATER}
  
  -- Chinook
  self.enableChinookGCLoading = true
  self.ChinookTroopCircleRadius = 5
  
  -- User SET_GROUP
  self.UserSetGroup = nil
  
  local AliaS = string.gsub(self.alias," ","_")
  self.filename = string.format("CTLD_%s_Persist.csv",AliaS)
  
  -- allow re-pickup crates
  self.allowcratepickupagain = true
  
  -- slingload
  self.enableslingload = false
  self.basetype = "container_cargo" -- shape of the container

  self.C130basetype = "cds_crate" -- shape of the C-130J-30 container

  -- use C-130J-30 load and unload method, false by default.
  self.UseC130LoadAndUnload = false
  
  -- Smokes and Flares
  self.SmokeColor = SMOKECOLOR.Red
  self.FlareColor = FLARECOLOR.Red
  
  for i=1,100 do
    math.random()
  end
  
  -- CA Transport
  self.allowCATransport = false -- #boolean
  self.CATransportSet = nil -- Core.Set#SET_CLIENT
  
  self:_GenerateVHFrequencies()
  self:_GenerateUHFrequencies()
  self:_GenerateFMFrequencies()
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------
  
  --- Triggers the FSM event "Start". Starts the CTLD. Initializes parameters and starts event handlers.
  -- @function [parent=#CTLD] Start
  -- @param #CTLD self

  --- Triggers the FSM event "Start" after a delay. Starts the CTLD. Initializes parameters and starts event handlers.
  -- @function [parent=#CTLD] __Start
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the CTLD and all its event handlers.
  -- @function [parent=#CTLD] Stop
  -- @param #CTLD self

  --- Triggers the FSM event "Stop" after a delay. Stops the CTLD and all its event handlers.
  -- @function [parent=#CTLD] __Stop
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#CTLD] Status
  -- @param #CTLD self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#CTLD] __Status
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.
  
  --- Triggers the FSM event "Load".
  -- @function [parent=#CTLD] Load
  -- @param #CTLD self

  --- Triggers the FSM event "Load" after a delay.
  -- @function [parent=#CTLD] __Load
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.
  
  --- Triggers the FSM event "Save".
  -- @function [parent=#CTLD] Load
  -- @param #CTLD self

  --- Triggers the FSM event "Save" after a delay.
  -- @function [parent=#CTLD] __Save
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.
  
  --- FSM Function OnBeforeTroopsPickedUp.
  -- @function [parent=#CTLD] OnBeforeTroopsPickedUp
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo troops.
  -- @return #CTLD self
  
  --- FSM Function OnBeforeTroopsExtracted.
  -- @function [parent=#CTLD] OnBeforeTroopsExtracted
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops extracted.
  -- @param #string Troopname Name of the extracted group.
  -- @return #CTLD self
    
  --- FSM Function OnBeforeCratesPickedUp.
  -- @function [parent=#CTLD] OnBeforeCratesPickedUp
  -- @param #CTLD self
  -- @param #string From State .
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate. Can be a Wrapper.DynamicCargo#DYNAMICCARGO object, if ground crew loaded!
  -- @return #CTLD self
  
   --- FSM Function OnBeforeTroopsDeployed.
  -- @function [parent=#CTLD] OnBeforeTroopsDeployed
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops Troops #GROUP Object.
  -- @return #CTLD self
  
  --- FSM Function OnBeforeCratesDropped.
  -- @function [parent=#CTLD] OnBeforeCratesDropped
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects dropped. Can be a Wrapper.DynamicCargo#DYNAMICCARGO object, if ground crew unloaded!
  -- @return #CTLD self
  
  --- FSM Function OnBeforeCratesBuild.
  -- @function [parent=#CTLD] OnBeforeCratesBuild
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB build.
  -- @return #CTLD self

  --- FSM Function OnBeforeCratesRepaired.
  -- @function [parent=#CTLD] OnBeforeCratesRepaired
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB repaired.
  -- @return #CTLD self
        
  --- FSM Function OnBeforeCratesPacked.
  -- @function [parent=#CTLD] OnBeforeCratesPacked
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate that was repacked.
  -- @return #CTLD self
    
  --- FSM Function OnBeforeTroopsRTB.
  -- @function [parent=#CTLD] OnBeforeTroopsRTB
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #string ZoneName Name of the Zone where the Troops have been RTB'd.
  -- @param Core.Zone#ZONE_Radius ZoneObject of the Zone where the Troops have been RTB'd.
  
  --- FSM Function OnAfterTroopsPickedUp.
  -- @function [parent=#CTLD] OnAfterTroopsPickedUp
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo troops.
  -- @return #CTLD self
  
  --- FSM Function OnAfterTroopsExtracted.
  -- @function [parent=#CTLD] OnAfterTroopsExtracted
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops extracted.
  -- @param #string Troopname Name of the extracted group.
  -- @return #CTLD self
    
  --- FSM Function OnAfterCratesPickedUp.
  -- @function [parent=#CTLD] OnAfterCratesPickedUp
  -- @param #CTLD self
  -- @param #string From State .
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO cargo crates. Can be a Wrapper.DynamicCargo#DYNAMICCARGO objects, if ground crew loaded!
  -- @return #CTLD self
  
   --- FSM Function OnAfterTroopsDeployed.
  -- @function [parent=#CTLD] OnAfterTroopsDeployed
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops Troops #GROUP Object.
  -- @return #CTLD self
  
  --- FSM Function OnAfterCratesDropped.
  -- @function [parent=#CTLD] OnAfterCratesDropped
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects dropped. Can be a Wrapper.DynamicCargo#DYNAMICCARGO object, if ground crew unloaded!
  -- @return #CTLD self
  
  --- FSM Function OnAfterGetCrates.
  -- @function [parent=#CTLD] OnAfterGetCrates
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects spawned via "Get".
  -- @return #CTLD self

  --- FSM Function OnAfterRemoveCratesNearby.
  -- @function [parent=#CTLD] OnAfterRemoveCratesNearby
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects removed nearby.
  -- @return #CTLD self

  --- FSM Function OnAfterCratesBuild.
  -- @function [parent=#CTLD] OnAfterCratesBuild
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB build.
  -- @return #CTLD self

  --- FSM Function OnAfterCratesBuildStarted. Info event that a build has been started.
  -- @function [parent=#CTLD] OnAfterCratesBuildStarted
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param CargoName The name of the cargo being built.
  -- @return #CTLD self

  --- FSM Function OnAfterCratesRepairStarted. Info event that a repair has been started.
  -- @function [parent=#CTLD] OnAfterCratesRepairStarted
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @return #CTLD self

  --- FSM Function OnBeforeCratesBuildStarted. Info event that a build has been started.
  -- @function [parent=#CTLD] OnBeforeCratesBuildStarted
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @return #CTLD self

  --- FSM Function OnBeforeCratesRepairStarted. Info event that a repair has been started.
  -- @function [parent=#CTLD] OnBeforeCratesRepairStarted
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @return #CTLD self

  --- FSM Function OnAfterCratesRepaired.
  -- @function [parent=#CTLD] OnAfterCratesRepaired
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB repaired.
  -- @return #CTLD self
  
  --- FSM Function OnAfterCratesPacked.
  -- @function [parent=#CTLD] OnAfterCratesPacked
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate that was repacked.
  -- @return #CTLD self
    
  --- FSM Function OnAfterTroopsRTB.
  -- @function [parent=#CTLD] OnAfterTroopsRTB
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
        
  --- FSM Function OnBeforeHelicopterLost.
  -- @function [parent=#CTLD] OnBeforeHelicopterLost
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param #string Unitname The name of the unit lost.
  -- @param #table LostCargo Table of #CTLD_CARGO object which were aboard the helicopter/transportplane lost. Can be an empty table!

  --- FSM Function OnAfterHelicopterLost.
  -- @function [parent=#CTLD] OnAfterHelicopterLost
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param #string Unitname The name of the unit lost.
  -- @param #table LostCargo Table of #CTLD_CARGO object which were aboard the helicopter/transportplane lost. Can be an empty table!
  
  --- FSM Function OnAfterLoad.
  -- @function [parent=#CTLD] OnAfterLoad
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is located. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for loading. Default is "CTLD_<alias>_Persist.csv".
  
  --- FSM Function OnAfterLoaded.
  -- @function [parent=#CTLD] OnAfterLoaded
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #table LoadedGroups Table of loaded groups, each entry is a table with three values: Group, TimeStamp and CargoType.
  
  --- FSM Function OnAfterSave.
  -- @function [parent=#CTLD] OnAfterSave
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is saved. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for saving. Default is "CTLD_<alias>_Persist.csv".
  
  return self
end

------------------------------------------------------------------- 
-- Helper and User Functions
------------------------------------------------------------------- 

--- (Internal) Function to get capabilities of a chopper
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit The unit
-- @return #table Capabilities Table of caps
function CTLD:_GetUnitCapabilities(Unit)
  self:T(self.lid .. " _GetUnitCapabilities")
  local _unit = Unit -- Wrapper.Unit#UNIT
  local unittype = _unit:GetTypeName()
  local capabilities = self.UnitTypeCapabilities[unittype] -- #CTLD.UnitTypeCapabilities
  if not capabilities or capabilities == {} then
    -- e.g. ["Ka-50"] = {type="Ka-50", crates=false, troops=false, cratelimit = 0, trooplimit = 0},
    capabilities = {}
    capabilities.troops = false
    capabilities.crates = false
    capabilities.cratelimit = 0
    capabilities.trooplimit = 0
    capabilities.type = "generic"
    capabilities.length = 20
    capabilities.cargoweightlimit = 0
  end
  return capabilities
end

--- (Internal) Resolve cargo label for menus/messages.
-- @param #CTLD self
-- @param #CTLD_CARGO Cargo Cargo object or cargo name.
-- @return #string Cargo label
function CTLD:_GetCargoDisplayName(Cargo)
  if type(Cargo) == "table" then
    if Cargo.GetDisplayName then
      local dname = Cargo:GetDisplayName()
      if type(dname) == "string" and dname ~= "" then
        return dname
      end
    end
    if Cargo.GetName then
      local name = Cargo:GetName()
      if type(name) == "string" and name ~= "" then
        return name
      end
    end
    if type(Cargo.Name) == "string" and Cargo.Name ~= "" then
      return Cargo.Name
    end
    return "Unknown"
  end
  if type(Cargo) == "string" and Cargo ~= "" then
    return Cargo
  end
  return "Unknown"
end

--- (User) Function to allow transport via Combined Arms Trucks.
-- @param #CTLD self
-- @param #boolean OnOff Switch on (true) or off (false).
-- @param Core.Set#SET_CLIENT ClientSet The CA handling client set for ground transport.
-- @return #CTLD self
function CTLD:AllowCATransport(OnOff,ClientSet)
  self.allowCATransport = OnOff -- #boolean
  self.CATransportSet = ClientSet -- Core.Set#SET_CLIENT
  return self
end

--- (Internal) Function to generate valid UHF Frequencies
-- @param #CTLD self
function CTLD:_GenerateUHFrequencies()
  self:T(self.lid .. " _GenerateUHFrequencies")
    self.FreeUHFFrequencies = {}
    self.FreeUHFFrequencies = UTILS.GenerateUHFrequencies(243,320)    
    return self
end

--- (Internal) Function to generate valid FM Frequencies
-- @param #CTLD self
function CTLD:_GenerateFMFrequencies()
  self:T(self.lid .. " _GenerateFMrequencies")
    self.FreeFMFrequencies = {}
    self.FreeFMFrequencies = UTILS.GenerateFMFrequencies()
    return self
end

--- (Internal) Populate table with available VHF beacon frequencies.
-- @param #CTLD self
function CTLD:_GenerateVHFrequencies()
  self:T(self.lid .. " _GenerateVHFrequencies")
  self.FreeVHFFrequencies = {}
  self.UsedVHFFrequencies = {}
  self.FreeVHFFrequencies = UTILS.GenerateVHFrequencies()
  return self
end

--- (User) Set drop zone radius for troop drops in meters. Minimum distance is 25m for security reasons.
-- @param #CTLD self
-- @param #number Radius The radius to use.
function CTLD:SetTroopDropZoneRadius(Radius)
  self:T(self.lid .. " SetTroopDropZoneRadius")
  local tradius = Radius or 100
  if tradius < 25 then tradius = 25 end
  self.troopdropzoneradius = tradius
  return self
end

--- (User) Add a PLAYERTASK - FSM events will check success
-- @param #CTLD self
-- @param Ops.PlayerTask#PLAYERTASK PlayerTask
-- @return #CTLD self
function CTLD:AddPlayerTask(PlayerTask)
  self:T(self.lid .. " AddPlayerTask")
  if not self.PlayerTaskQueue then
    self.PlayerTaskQueue = FIFO:New()
  end
  self.PlayerTaskQueue:Push(PlayerTask,PlayerTask.PlayerTaskNr)
  return self
end

--- (Internal) Event handler function
-- @param #CTLD self
-- @param Core.Event#EVENTDATA EventData
function CTLD:_EventHandler(EventData)
  self:T(string.format("%s Event = %d",self.lid, EventData.id))
  local event = EventData -- Core.Event#EVENTDATA
  if event.id == EVENTS.PlayerEnterAircraft or event.id == EVENTS.PlayerEnterUnit then
    local _coalition = event.IniCoalition
    if _coalition ~= self.coalition then
        return --ignore!
    end
    local unitname = event.IniUnitName or "none"
    self.MenusDone[unitname] = nil
    -- check is Helicopter
    local _unit = event.IniUnit
    local _group = event.IniGroup
    self.C130JUnits = self.C130JUnits or {}
    local utype =_unit:GetTypeName()
    if self.C130JTypes and self.C130JTypes[utype] then
      self.C130JUnits[unitname] = true
    elseif utype == "C-130J-30" then
      self.C130JUnits[unitname] = true
    else
      self.C130JUnits[unitname] = false
    end
    if _unit:IsHelicopter() or _group:IsHelicopter() then
      local unitname = event.IniUnitName or "none"
      self.Loaded_Cargo[unitname] = nil
      self:_RefreshF10Menus()
    end
    -- Herc support
    if self:IsFixedWing(_unit) and self.enableFixedWing then
      local unitname = event.IniUnitName or "none"
      self.Loaded_Cargo[unitname] = nil
      self:_RefreshF10Menus()
    end
    -- CA support
    if _unit:IsGround() and self.allowCATransport then
      local unitname = event.IniUnitName or "none"
      self.Loaded_Cargo[unitname] = nil
      self:_RefreshF10Menus()
    end
    return
  elseif event.id == EVENTS.Land or event.id == EVENTS.Takeoff then
    local unitname = event.IniUnitName
    if self.CtldUnits[unitname] then
      local _group = event.IniGroup
      local _unit = event.IniUnit
      self:_RefreshLoadCratesMenu(_group, _unit)
    if self:IsFixedWing(_unit) and self.enableFixedWing then
      self:_RefreshDropCratesMenu(_group, _unit)
    end
    end
  elseif event.id == EVENTS.PlayerLeaveUnit or event.id == EVENTS.UnitLost then
    -- remove from pilot table
    local unitname = event.IniUnitName or "none"
    if self.CtldUnits[unitname] then
        local lostcargo = UTILS.DeepCopy(self.Loaded_Cargo[unitname] or {})
        self:__HelicopterLost(1,unitname,lostcargo)    
    end
    self.CtldUnits[unitname] = nil
    self.Loaded_Cargo[unitname] = nil
    self.MenusDone[unitname] = nil
    if self.C130JUnits then self.C130JUnits[unitname]=nil end
  --elseif event.id == EVENTS.NewDynamicCargo and event.IniObjectCategory == 6 and string.match(event.IniUnitName,".+|%d%d:%d%d|PKG%d+") then
  elseif event.id == EVENTS.NewDynamicCargo then
    self:T(self.lid.."GC New Event "..event.IniDynamicCargoName)
    ---------------
    -- New dynamic cargo system Handling NEW
    --------------
    self.DynamicCargo[event.IniDynamicCargoName] = event.IniDynamicCargo
    ---------------
    -- End new dynamic cargo system Handling
    --------------
  elseif event.id == EVENTS.DynamicCargoLoaded then
    self:T(self.lid.."GC Loaded Event "..event.IniDynamicCargoName)
    ---------------
    -- New dynamic cargo system Handling LOADING
    --------------
    local dcargo = event.IniDynamicCargo -- Wrapper.DynamicCargo#DYNAMICCARGO
    -- get client/unit object
    local client = CLIENT:FindByPlayerName(dcargo.Owner)
    if client and client:IsAlive() then
      -- add to unit load list
      local unitname = client:GetName() or "none"
      local loaded = {}
      if self.Loaded_Cargo[unitname] then
        loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
      else
        loaded = {} -- #CTLD.LoadedCargo
        loaded.Troopsloaded = 0
        loaded.Cratesloaded = 0
        loaded.Cargo = {}
      end
      loaded.Cratesloaded = loaded.Cratesloaded+1
      table.insert(loaded.Cargo,dcargo)
      self.Loaded_Cargo[unitname] = nil
      self.Loaded_Cargo[unitname] = loaded
      local Group = client:GetGroup()
      self:_SendMessage(string.format("Crate %s loaded by ground crew!",event.IniDynamicCargoName), 10, false, Group)
      self:__CratesPickedUp(1, Group, client, dcargo)
      self:_RefreshCrateQuantityMenus(Group, client, nil)
    end
    ---------------
    -- End new dynamic cargo system Handling
    --------------
  elseif event.id == EVENTS.DynamicCargoUnloaded then
    self:T(self.lid.."GC Unload Event "..event.IniDynamicCargoName)
    ---------------
    -- New dynamic cargo system Handling UNLOADING
    --------------
    local dcargo = event.IniDynamicCargo -- Wrapper.DynamicCargo#DYNAMICCARGO
    -- get client/unit object
    local client = CLIENT:FindByPlayerName(dcargo.Owner)
    if client and client:IsAlive() then
      -- add to unit load list
      local unitname = client:GetName() or "none"
      local loaded = {}
      if self.Loaded_Cargo[unitname] then
        loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
        loaded.Cratesloaded = loaded.Cratesloaded - 1
        if loaded.Cratesloaded < 0  then loaded.Cratesloaded = 0 end
        -- TODO zap cargo from list
        local Loaded = {}
        for _,_item in pairs (loaded.Cargo or {}) do
          self:T(self.lid.."UNLOAD checking: ".._item:GetName())
          self:T(self.lid.."UNLOAD state: ".. tostring(_item:WasDropped()))
          if _item and _item:GetType() == CTLD_CARGO.Enum.GCLOADABLE and event.IniDynamicCargoName and event.IniDynamicCargoName ~= _item:GetName() and not _item:WasDropped() then
            table.insert(Loaded,_item)
          else
            table.insert(Loaded,_item)
          end 
        end
        loaded.Cargo = nil
        loaded.Cargo = Loaded
        self.Loaded_Cargo[unitname] = nil
        self.Loaded_Cargo[unitname] = loaded
      else
        loaded = {} -- #CTLD.LoadedCargo
        loaded.Troopsloaded = 0
        loaded.Cratesloaded = 0
        loaded.Cargo = {}
        self.Loaded_Cargo[unitname] = loaded
      end
      local Group = client:GetGroup()
      self:_SendMessage(string.format("Crate %s unloaded by ground crew!",event.IniDynamicCargoName), 10, false, Group) 
      self:__CratesDropped(1,Group,client,{dcargo})
      self:_RefreshCrateQuantityMenus(Group, client, nil)
    end
    ---------------
    -- End new dynamic cargo system Handling
    --------------
  elseif event.id == EVENTS.DynamicCargoRemoved then
    self:T(self.lid.."GC Remove Event "..event.IniDynamicCargoName)
    ---------------
    -- New dynamic cargo system Handling REMOVE
    --------------
    self.DynamicCargo[event.IniDynamicCargoName] = nil
    ---------------
    -- End new dynamic cargo system Handling
    --------------
  end
  return self
end

--- (Internal) Function to check if a unit is a C-130J
-- @param #CTLD self
function CTLD:IsC130J(Unit)
  if not Unit then return false end
  if not self.UseC130LoadAndUnload then return false end
  self.C130JUnits = self.C130JUnits or {}
  local unitname = Unit:GetName() or "none"
  return self.C130JUnits[unitname] == true
end

--- (Internal) Function to message a group.
-- @param #CTLD self
-- @param #string Text The text to display.
-- @param #number Time Number of seconds to display the message.
-- @param #boolean Clearscreen Clear screen or not.
-- @param Wrapper.Group#GROUP Group The group receiving the message.
function CTLD:_SendMessage(Text, Time, Clearscreen, Group)
  self:T(self.lid .. " _SendMessage")
  if not self.suppressmessages then
    local m = MESSAGE:New(Text,Time,"CTLD",Clearscreen):ToGroup(Group)
  end 
  return self
end

--- (Internal) Find a troops CTLD_CARGO object in stock
-- @param #CTLD self
-- @param #string Name of the object
-- @return #CTLD_CARGO Cargo object, nil if it cannot be found
function CTLD:_FindTroopsCargoObject(Name)
  self:T(self.lid .. " _FindTroopsCargoObject")
  local cargo = nil
  for _,_cargo in pairs(self.Cargo_Troops)do
    local cargo = _cargo -- #CTLD_CARGO
    if cargo.Name == Name then
      return cargo
    end
  end
  return nil
end

--- (Internal) Find a crates CTLD_CARGO object in stock
-- @param #CTLD self
-- @param #string Name of the object
-- @return #CTLD_CARGO Cargo object, nil if it cannot be found
function CTLD:_FindCratesCargoObject(Name)
  self:T(self.lid .. " _FindCratesCargoObject")
  local cargo = nil
  for _,_cargo in pairs(self.Cargo_Crates)do
    local cargo = _cargo -- #CTLD_CARGO
    if cargo.Name == Name then
      return cargo
    end
  end
  for _,_cargo in pairs(self.Cargo_Statics)do
    local cargo = _cargo -- #CTLD_CARGO
    if cargo.Name == Name then
      return cargo
    end
  end
  return nil
end

--- (User) Add a new fixed wing type to the list of allowed types.
-- @param #CTLD self
-- @param #string typename The typename to add. Can be handed as Wrapper.Unit#UNIT object. Do NOT forget to `myctld:SetUnitCapabilities()` for this type!
-- @return #CTLD self
function CTLD:AddAllowedFixedWingType(typename)
  if type(typename) == "string" then
    self.FixedWingTypes[typename] = typename
  elseif typename and typename.ClassName and typename:IsInstanceOf("UNIT") then
    local TypeName = typename:GetTypeName() or "none"
    self.FixedWingTypes[TypeName] = TypeName
  else
    self:E(self.lid.."No valid typename or no UNIT handed!")
  end
  return self
end

--- (User) Pre-load troops into a helo, e.g. for airstart. Unit **must** be alive in-game, i.e. player has taken the slot!
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit The unit to load into, can be handed as Wrapper.Client#CLIENT object
-- @param #string Troopname The name of the Troops to be loaded. Must be created prior in the CTLD setup!
-- @return #CTLD self
-- @usage
--          local client = UNIT:FindByName("Helo-1-1")
--          if client and client:IsAlive() then
--            myctld:PreloadTroops(client,"Infantry")
--          end
function CTLD:PreloadTroops(Unit,Troopname)
  self:T(self.lid .. " PreloadTroops")
  local name = Troopname or "Unknown"
  if Unit and Unit:IsAlive() then
    local cargo = self:_FindTroopsCargoObject(name)
    local group = Unit:GetGroup()
    if cargo then
      self:_LoadTroops(group,Unit,cargo,true)
    else
      self:E(self.lid.." Troops preload - Cargo Object "..name.." not found!")
    end
  end
  return self
end

--- (Internal) Pre-load crates into a helo. Do not use standalone!
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group The group to load into, can be handed as Wrapper.Client#CLIENT object
-- @param Wrapper.Unit#UNIT Unit The unit to load into, can be handed as Wrapper.Client#CLIENT object
-- @param #CTLD_CARGO Cargo The Cargo crate object to load
-- @param #number NumberOfCrates (Optional) Number of crates to be loaded. Default - all necessary to build this object. Might overload the helo!
-- @return #CTLD self
function CTLD:_PreloadCrates(Group, Unit, Cargo, NumberOfCrates)
    -- load crate into heli
  local group = Group -- Wrapper.Group#GROUP
  local unit = Unit -- Wrapper.Unit#UNIT
  local unitname = unit:GetName()
  -- see if this heli can load crates
  local unittype = unit:GetTypeName()
  local capabilities = self:_GetUnitCapabilities(Unit) -- #CTLD.UnitTypeCapabilities
  local cancrates = capabilities.crates -- #boolean
  local cratelimit = capabilities.cratelimit -- #number
  if not cancrates then
    self:_SendMessage("Sorry this chopper cannot carry crates!", 10, false, Group) 
    return self
  else
    -- have we loaded stuff already?
    local numberonboard = 0
    local massonboard = 0
    local loaded = {}
    if self.Loaded_Cargo[unitname] then
      loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
      numberonboard = loaded.Cratesloaded or 0
      massonboard = self:_GetUnitCargoMass(Unit)
    else
      loaded = {} -- #CTLD.LoadedCargo
      loaded.Troopsloaded = 0
      loaded.Cratesloaded = 0
      loaded.Cargo = {}
    end
    local crate = Cargo -- #CTLD_CARGO
    local numbercrates = NumberOfCrates or crate:GetCratesNeeded()
    for i=1,numbercrates do
      loaded.Cratesloaded = loaded.Cratesloaded + 1
      crate:SetHasMoved(true)
      crate:SetWasDropped(false)
      table.insert(loaded.Cargo, crate)
      crate.Positionable = nil
      self:_SendMessage(string.format("Crate ID %d for %s loaded!",crate:GetID(),crate:GetName()), 10, false, Group)
      --self:__CratesPickedUp(1, Group, Unit, crate)
      self.Loaded_Cargo[unitname] = loaded
      self:_UpdateUnitCargoMass(Unit)
    end 
  end
  return self
end

--- (User) Pre-load crates into a helo, e.g. for airstart. Unit **must** be alive in-game, i.e. player has taken the slot!
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit The unit to load into, can be handed as Wrapper.Client#CLIENT object
-- @param #string Cratesname The name of the cargo to be loaded. Must be created prior in the CTLD setup!
-- @param #number NumberOfCrates (Optional) Number of crates to be loaded. Default - all necessary to build this object. Might overload the helo!
-- @return #CTLD self
-- @usage
--          local client = UNIT:FindByName("Helo-1-1")
--          if client and client:IsAlive() then
--            myctld:PreloadCrates(client,"Humvee")
--          end
function CTLD:PreloadCrates(Unit,Cratesname,NumberOfCrates)
  self:T(self.lid .. " PreloadCrates")
  local name = Cratesname or "Unknown"
  if Unit and Unit:IsAlive() then
    local cargo = self:_FindCratesCargoObject(name)
    local group = Unit:GetGroup()
    if cargo then
      self:_PreloadCrates(group,Unit,cargo,NumberOfCrates)
    else
      self:E(self.lid.." Crates preload - Cargo Object "..name.." not found!")
    end
  end
  return self
end

--- (Internal) Function to load troops into a heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD_CARGO Cargotype
-- @param #boolean Inject
function CTLD:_LoadTroops(Group, Unit, Cargotype, Inject)
  self:T(self.lid .. " _LoadTroops")
  -- check if we have stock
  local instock = Cargotype:GetStock()
  local cgoname = Cargotype:GetName()
  local cgotype = Cargotype:GetType()
  local cgonetmass = Cargotype:GetNetMass()
  local maxloadable = self:_GetMaxLoadableMass(Unit)
  if type(instock) == "number" and tonumber(instock) <= 0 and tonumber(instock) ~= -1 and not Inject then
    -- nothing left over
    self:_SendMessage(string.format("Sorry, all %s are gone!", cgoname), 10, false, Group)
    return self
  end
  -- landed or hovering over load zone?
  local grounded = not self:IsUnitInAir(Unit)
  local hoverload = self:CanHoverLoad(Unit)
  -- check if we are in LOAD zone
  local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
  if not inzone then
    inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.SHIP)
  end
  if not Inject then
    if not inzone then
      self:_SendMessage("You are not close enough to a logistics zone!", 10, false, Group)
      if not self.debug then return self end
    elseif not grounded and not hoverload then
      self:_SendMessage("You need to land or hover in position to load!", 10, false, Group)
      if not self.debug then return self end
    elseif self.pilotmustopendoors and not  UTILS.IsLoadingDoorOpen(Unit:GetName()) then
      self:_SendMessage("You need to open the door(s) to load troops!", 10, false, Group)
      if not self.debug then return self end  
    end
  end
  -- load troops into heli
  local group = Group -- Wrapper.Group#GROUP
  local unit = Unit -- Wrapper.Unit#UNIT
  local unitname = unit:GetName()
  local cargotype = Cargotype -- #CTLD_CARGO
  local cratename = cargotype:GetName() -- #string
  -- see if this heli can load troops
  local unittype = unit:GetTypeName()
  local capabilities = self:_GetUnitCapabilities(Unit)
  local cantroops = capabilities.troops -- #boolean
  local trooplimit = capabilities.trooplimit -- #number
  local troopsize = cargotype:GetCratesNeeded() -- #number
  -- have we loaded stuff already?
  local numberonboard = 0
  local loaded = {}
  if self.Loaded_Cargo[unitname] then
    loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
    numberonboard = loaded.Troopsloaded or 0
  else
    loaded = {} -- #CTLD.LoadedCargo
    loaded.Troopsloaded = 0
    loaded.Cratesloaded = 0
    loaded.Cargo = {}
  end
  if troopsize + numberonboard > trooplimit then
    self:_SendMessage("Sorry, we\'re crammed already!", 10, false, Group)
    return
  elseif maxloadable < cgonetmass then
    self:_SendMessage("Sorry, that\'s too heavy to load!", 10, false, Group)
    return
  else
    self.CargoCounter = self.CargoCounter + 1
    local loadcargotype = CTLD_CARGO:New(self.CargoCounter, Cargotype.Name, Cargotype.Templates, cgotype, true, true, Cargotype.CratesNeeded,nil,nil,Cargotype.PerCrateMass)
    self:T({cargotype=loadcargotype})
    loaded.Troopsloaded = loaded.Troopsloaded + troopsize
    table.insert(loaded.Cargo,loadcargotype)
    self.Loaded_Cargo[unitname] = loaded
    self:_SendMessage(string.format("%s boarded!", cgoname), 10, false, Group)
    self:_RefreshDropTroopsMenu(Group,Unit)
    self:__TroopsPickedUp(1,Group, Unit, Cargotype)
    self:_UpdateUnitCargoMass(Unit)
    Cargotype:RemoveStock()
    self:_RefreshTroopQuantityMenus(Group, Unit, Cargotype)
  end
  return self
end

function CTLD:_FindRepairNearby(Group, Unit, Repairtype)
    self:T(self.lid .. " _FindRepairNearby")
    --self:T({Group:GetName(),Unit:GetName(),Repairtype})
    local unitcoord = Unit:GetCoordinate()
    
    -- find nearest group of deployed groups
    local nearestGroup = nil
    local nearestGroupIndex = -1
    local nearestDistance = 10000
    for k,v in pairs(self.DroppedTroops) do
      local distance = self:_GetDistance(v:GetCoordinate(),unitcoord)
      local unit = v:GetUnit(1) -- Wrapper.Unit#UNIT
      local desc = unit:GetDesc() or nil
      if distance < nearestDistance and distance ~= -1 and not desc.attributes.Infantry then
        nearestGroup = v
        nearestGroupIndex = k
        nearestDistance = distance
      end
    end
    
    --self:T("Distance: ".. nearestDistance)
    
    -- found one and matching distance?  
    if nearestGroup == nil or nearestDistance > self.EngineerSearch then
      self:_SendMessage("No unit close enough to repair!", 10, false, Group)
      return nil, nil
    end
    
    local groupname = nearestGroup:GetName()
    
    -- helper to find matching template
    local function matchstring(String,Table)
      local match = false
      String = string.gsub(String,"-"," ")
      if type(Table) == "table" then       
        for _,_name in pairs (Table) do
          _name = string.gsub(_name,"-"," ")
          if string.find(String,_name) then
            match = true
            break
          end
        end
      else
        if type(String) == "string" then
          Table = string.gsub(Table,"-"," ")
          if string.find(String,Table) then match = true end
        end
      end 
      return match
    end
    
    -- walk through generics and find matching type
    local Cargotype = nil
    for k,v in pairs(self.Cargo_Crates) do
      --self:T({groupname,v.Templates,Repairtype})
      if matchstring(groupname,v.Templates) and matchstring(groupname,Repairtype) then
        Cargotype = v -- #CTLD_CARGO
        break
      end
    end

    if Cargotype == nil then
      return nil, nil
    else
      --self:T({groupname,Cargotype})
      return nearestGroup, Cargotype
    end
    
end

--- (Internal) Function to repair an object.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #table Crates Table of #CTLD_CARGO objects near the unit.
-- @param #CTLD.Buildable Build Table build object.
-- @param #number Number Number of objects in Crates (found) to limit search.
-- @param #boolean Engineering If true it is an Engineering repair.
function CTLD:_RepairObjectFromCrates(Group,Unit,Crates,Build,Number,Engineering)
  self:T(self.lid .. " _RepairObjectFromCrates") 
  local build = Build -- -- #CTLD.Buildable
  local Repairtype = build.Template -- #string
  local NearestGroup, CargoType = self:_FindRepairNearby(Group,Unit,Repairtype) -- Wrapper.Group#GROUP, #CTLD_CARGO
  if NearestGroup ~= nil then
    if self.repairtime < 2 then self.repairtime = 30 end -- noob catch
    if not Engineering then
      self:_SendMessage(string.format("Repair started using %s taking %d secs", build.Name, self.repairtime), 10, false, Group)
    end
    -- now we can build ....
    local name = CargoType:GetName()
    local required = CargoType:GetCratesNeeded()
    local template = CargoType:GetTemplates()
    local ctype = CargoType:GetType()
    local object = {} -- #CTLD.Buildable
    object.Name = CargoType:GetName()
    object.Required = required
    object.Found = required
    object.Template = template
    object.CanBuild = true
    object.Type = ctype -- #CTLD_CARGO.Enum
    self:_CleanUpCrates(Crates,Build,Number)
    local desttimer = TIMER:New(function() NearestGroup:Destroy(false) end, self)
    desttimer:Start(self.repairtime - 1)
    local buildtimer = TIMER:New(self._BuildObjectFromCrates,self,Group,Unit,object,true,NearestGroup:GetCoordinate())
    buildtimer:Start(self.repairtime)
    self:__CratesRepairStarted(1,Group,Unit)
  else
    if not Engineering then
      self:_SendMessage("Can't repair this unit with " .. build.Name, 10, false, Group)
    else
      self:T("Can't repair this unit with " .. build.Name)
    end
  end
  return self
end

  --- (Internal) Function to extract (load from the field) troops into a heli.
  -- @param #CTLD self
  -- @param Wrapper.Group#GROUP Group
  -- @param Wrapper.Unit#UNIT Unit
  function CTLD:_ExtractTroops(Group, Unit) -- #1574 thanks to @bbirchnz!
    self:T(self.lid .. " _ExtractTroops")
    -- landed or hovering over load zone?
    local grounded = not self:IsUnitInAir(Unit)
    local hoverload = self:IsCorrectHover(Unit) -- correct call now for extracting troops while hovering
    local hassecondaries = false
    
    if not grounded and not hoverload then
      self:_SendMessage("You need to land or hover in position to load!", 10, false, Group)
      if not self.debug then return self end
    end
    if self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
      self:_SendMessage("You need to open the door(s) to extract troops!", 10, false, Group)
      if not self.debug then return self end 
    end
    -- load troops into heli
    local unit = Unit -- Wrapper.Unit#UNIT
    local unitname = unit:GetName()
    -- see if this heli can load troops
    local unittype = unit:GetTypeName()
    local capabilities = self:_GetUnitCapabilities(Unit)
    local cantroops = capabilities.troops -- #boolean
    local trooplimit = capabilities.trooplimit -- #number
    local unitcoord = unit:GetCoordinate()
    
    -- find nearest group of deployed troops
    local nearestGroup = nil
    local nearestGroupIndex = -1
    local nearestDistance = 10000000
    local maxdistance = 0
    local nearestList = {}
    local distancekeys = {}
    local extractdistance = self.CrateDistance * self.ExtractFactor
    for k,v in pairs(self.DroppedTroops) do
      local distance = self:_GetDistance(v:GetCoordinate(),unitcoord)
      local TNow = timer.getTime()
      local vtime = v.ExtractTime or TNow-310
      if distance <= extractdistance and distance ~= -1 and (TNow - vtime > 300) then
        nearestGroup = v
        nearestGroupIndex = k
        nearestDistance = distance
        if math.floor(distance) > maxdistance then maxdistance = math.floor(distance) end
        if nearestList[math.floor(distance)] then 
          distance = maxdistance+1
          maxdistance = distance 
        end
        table.insert(nearestList, math.floor(distance), v)
        distancekeys[#distancekeys+1] = math.floor(distance)
        --self:I(string.format("Adding group %s distance %dm",nearestGroup:GetName(),distance))
      end
    end
    
    if nearestGroup == nil or nearestDistance > extractdistance then
      self:_SendMessage("No units close enough to extract!", 10, false, Group)
      return self
    end
    
    -- sort reference keys
    table.sort(distancekeys)
    
    local secondarygroups = {}
    
    for i=1,#distancekeys do
      local nearestGroup = nearestList[distancekeys[i]] -- Wrapper.Group#GROUP
          -- find matching cargo type
      local groupType = string.match(nearestGroup:GetName(), "(.+)-(.+)$")
      local Cargotype = nil
      for k,v in pairs(self.Cargo_Troops) do
        local comparison = ""
        if type(v.Templates) == "string" then comparison = v.Templates else comparison = v.Templates[1] end
        if comparison == groupType then
          Cargotype = v
          break
        end
      end
      if Cargotype == nil then
        self:_SendMessage("Can't onboard " .. groupType, 10, false, Group)
      else
      
        local troopsize = Cargotype:GetCratesNeeded() -- #number
        -- have we loaded stuff already?
        local numberonboard = 0
        local loaded = {}
        if self.Loaded_Cargo[unitname] then
          loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
          numberonboard = loaded.Troopsloaded or 0
        else
          loaded = {} -- #CTLD.LoadedCargo
          loaded.Troopsloaded = 0
          loaded.Cratesloaded = 0
          loaded.Cargo = {}
        end
        if troopsize + numberonboard > trooplimit then
          self:_SendMessage("Sorry, we\'re crammed already!", 10, false, Group)
          nearestGroup.ExtractTime = 0
          --return self
        else
          self.CargoCounter = self.CargoCounter + 1
          nearestGroup.ExtractTime = timer.getTime()
          local loadcargotype = CTLD_CARGO:New(self.CargoCounter, Cargotype.Name, Cargotype.Templates, Cargotype.CargoType, true, true, Cargotype.CratesNeeded,nil,nil,Cargotype.PerCrateMass)
          self:T({cargotype=loadcargotype})
          local running = math.floor(nearestDistance / 4)+20 -- time run to helo plus boarding
          loaded.Troopsloaded = loaded.Troopsloaded + troopsize
          table.insert(loaded.Cargo,loadcargotype)
          self.Loaded_Cargo[unitname] = loaded
          self:ScheduleOnce(running, self._SendMessage, self, string.format("%s boarded!", Cargotype.Name), 10, false, Group)
          self:_SendMessage(string.format("%s boarding!", Cargotype.Name), 10, false, Group)
          self:_RefreshDropTroopsMenu(Group,Unit)
          self:_UpdateUnitCargoMass(Unit)
          local groupname = nearestGroup:GetName()
          self:__TroopsExtracted(running,Group, Unit, nearestGroup, groupname)
          local coord = Unit:GetCoordinate() or Group:GetCoordinate() -- Core.Point#COORDINATE
          local Point
          if coord then
            local heading = unit:GetHeading() or 0
            local Angle = math.floor((heading+160)%360)
            Point = coord:Translate(8,Angle):GetVec2()
            if Point then
              nearestGroup:RouteToVec2(Point,5)
            end
          end
          -- clean up:
          hassecondaries = false
          if type(Cargotype.Templates) == "table" and Cargotype.Templates[2] then
            for _,_key in pairs (Cargotype.Templates) do
              table.insert(secondarygroups,_key)
              hassecondaries = true
            end
          end
          local destroytimer = math.random(10,20)
          --self:I("Destroying Group "..nearestGroup:GetName().." in "..destroytimer.." seconds!")
          nearestGroup:Destroy(false,destroytimer)
        end
      end
    end
    -- clean up secondary groups
    if hassecondaries == true then
      for _,_name in pairs(secondarygroups) do
        for _,_group in pairs(nearestList) do
          if _group and _group:IsAlive() then
            local groupname = string.match(_group:GetName(), "(.+)-(.+)$")
            if _name == groupname then
              _group:Destroy(false,15)
            end
          end
        end
      end
    end
    self:CleanDroppedTroops()
    return self
  end

--- (Internal) Function to load multiple troop sets at once.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD_CARGO Cargo
-- @param #number quantity Number of troop sets to load.
-- @return #CTLD self
function CTLD:_LoadTroopsQuantity(Group, Unit, Cargo, quantity)
  local n = math.max(1, tonumber(quantity) or 1)

  -- landed or hovering over load zone?
  local grounded = not self:IsUnitInAir(Unit)
  local hoverload = self:CanHoverLoad(Unit)

  -- check if we are in LOAD zone
  local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
  if not inzone then
    inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.SHIP)
  end

  if not inzone then
    self:_SendMessage("You are not close enough to a logistics zone!", 10, false, Group)
    if not self.debug then return self end
  elseif not grounded and not hoverload then
    self:_SendMessage("You need to land or hover in position to load!", 10, false, Group)
    if not self.debug then return self end
  elseif self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
    self:_SendMessage("You need to open the door(s) to load troops!", 10, false, Group)
    if not self.debug then return self end  
  end

  local prevSuppress = self.suppressmessages
  self.suppressmessages = true
  for i = 1, n do
    timer.scheduleFunction(function() self:_LoadTroops(Group, Unit, Cargo) end, {}, timer.getTime() + 0.2 * i)
  end
  timer.scheduleFunction(function()
    self.suppressmessages = prevSuppress
    local dname = Cargo:GetName()
    self:_SendMessage(string.format("Loaded %d %s.", n, dname), 10, false, Group)
  end, {}, timer.getTime() + 0.2 * n + 0.05)
  return self
end

--- (Internal) Function to add quantity submenu entries for troops.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param Core.Menu#MENU_GROUP parentMenu
-- @param #CTLD_CARGO cargoObj
-- @return #CTLD self
function CTLD:_AddTroopQuantityMenus(Group, Unit, parentMenu, cargoObj)
  local stock = cargoObj:GetStock()
  local maxQuantity = self.maxCrateMenuQuantity or 1
  if type(stock) == "number" and stock >= 0 and stock < maxQuantity then maxQuantity = stock end
  maxQuantity = math.floor(maxQuantity)
  if maxQuantity < 1 then maxQuantity = 1 end
  local caps = self:_GetUnitCapabilities(Unit)
  local trooplimit = caps and caps.trooplimit or 0
  local troopsize = cargoObj:GetCratesNeeded() or 1
  if troopsize < 1 then troopsize = 1 end
  local ld = self.Loaded_Cargo and self.Loaded_Cargo[Unit:GetName()] or nil
  local onboard = (ld and type(ld.Troopsloaded) == "number") and ld.Troopsloaded or 0
  if trooplimit > 0 then
    local space = trooplimit - onboard
    if space < troopsize then
      local msg = "Troop limit reached"
      if type(stock) == "number" and stock == 0 then msg = "Out of stock" end
      MENU_GROUP_COMMAND:New(Group, msg, parentMenu, function() end)
      return self
    end
    local capacitySets = math.floor(space / troopsize)
    if capacitySets < maxQuantity then maxQuantity = capacitySets end
  end
  for quantity = 1, maxQuantity do
    if quantity == 1 then
      MENU_GROUP_COMMAND:New(Group, tostring(quantity), parentMenu, self._LoadTroops, self, Group, Unit, cargoObj)
    else
      MENU_GROUP_COMMAND:New(Group, tostring(quantity), parentMenu, self._LoadTroopsQuantity, self, Group, Unit, cargoObj, quantity)
    end
  end
  return self
end

--- (Internal) Function to request N*crates for a cargo type.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD_CARGO cargoObj
-- @param #number quantity Number of cargo sets to request.
-- @return #CTLD self
function CTLD:_GetCrateQuantity(Group, Unit, cargoObj, quantity)
  local needed = cargoObj and cargoObj:GetCratesNeeded() or 1
  local count = math.max(1, tonumber(quantity) or 1)
  local total = needed * count
  self:_GetCrates(Group, Unit, cargoObj, total, false, false)
  return self
end

--- (Internal) Function to add quantity submenu entries for crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param Core.Menu#MENU_GROUP parentMenu
-- @param #CTLD_CARGO cargoObj
-- @param #table stockSummary Optional pooled stock summary.
-- @return #CTLD self
function CTLD:_AddCrateQuantityMenus(Group, Unit, parentMenu, cargoObj, stockSummary)
  self:T("_AddCrateQuantityMenus "..cargoObj.Name)
  local needed = cargoObj:GetCratesNeeded() or 1
  local stockEntry = self:_GetCrateStockEntry(cargoObj, stockSummary)
  local stock = nil
  if stockEntry and type(stockEntry.Stock) == "number" then
    stock = stockEntry.Stock
  else
    stock = cargoObj:GetStock()
  end
  self:T("_AddCrateQuantityMenus "..cargoObj.Name.." Stock: "..tostring(stock))
  local maxQuantity = self.maxCrateMenuQuantity or 1
  local availableSets = nil
  if type(stock) == "number" and stock >= 0 then
    availableSets = math.floor(stock)
    if availableSets <= 0 then
      MENU_GROUP_COMMAND:New(Group, "Out of stock", parentMenu, function() end)
      return self
    end
    if availableSets < maxQuantity then
      maxQuantity = availableSets
    end
  end
  maxQuantity = math.floor(maxQuantity)
  self:T("_AddCrateQuantityMenus maxQuantity "..maxQuantity)
  if maxQuantity < 1 then
    return self
  end
  local capacitySets = nil
  local capacityCrates = nil
  if Unit then
    local capabilities = self:_GetUnitCapabilities(Unit)
    local capacity = capabilities and capabilities.cratelimit or 0
    if capacity > 0 then
      local loadedData = nil
      if self.Loaded_Cargo then
        loadedData = self.Loaded_Cargo[Unit:GetName()]
      end
      local loadedCount = 0
      if loadedData and type(loadedData.Cratesloaded) == "number" then
        loadedCount = loadedData.Cratesloaded
      end
      local space = capacity - loadedCount
      if space < 0 then
        space = 0
      end
      capacityCrates = space
      local perSet = needed > 0 and needed or 1
      capacitySets = math.floor(space / perSet)
    end
  end
  local allowLoad = true
  if type(capacitySets) == "number" then
    if capacitySets >= 1 then
      if capacitySets < maxQuantity then
        maxQuantity = capacitySets
      end
    else
      allowLoad = false
      maxQuantity = 1
    end
  end
  self:T("_AddCrateQuantityMenus maxQuantity "..maxQuantity.." allowLoad "..tostring(allowLoad))
  local maxMassSets = nil
  local maxMassCrates = nil
  if Unit then
    local maxload = self:_GetMaxLoadableMass(Unit)
    local perCrateMass = (cargoObj.GetMass and cargoObj:GetMass()) or cargoObj.PerCrateMass or 0
    local setMass = perCrateMass * (needed > 0 and needed or 1)
    if type(maxload) == "number" and maxload > 0 and setMass > 0 then
      maxMassSets = math.floor(maxload / setMass)
      if maxMassSets < 1 then
        maxQuantity = 1
        allowLoad = false
      elseif maxMassSets < maxQuantity then
        maxQuantity = maxMassSets
      end
    end
    if type(maxload)=="number"and maxload>0 and perCrateMass>0 then
      maxMassCrates=math.floor(maxload/perCrateMass)
    end
  end
    self:T("_AddCrateQuantityMenus maxQuantity "..maxQuantity.." allowLoad "..tostring(allowLoad))
  if maxQuantity < 1 then
    return self
  end

  if maxQuantity == 1 then
    self:T("_AddCrateQuantityMenus maxQuantity "..maxQuantity.." Menu for MaxQ=1 ".."parentMenu.MenuText = "..parentMenu.MenuText)
    --parentMenu.MenuText
    MENU_GROUP_COMMAND:New(Group, "Get", parentMenu, self._GetCrateQuantity, self, Group, Unit, cargoObj, 1)
    local canLoad = (allowLoad and (not capacitySets or capacitySets >= 1) and (not maxMassSets or maxMassSets >= 1))
    local isHerc = self:IsC130J(Unit)
    local isHook = self:IsHook(Unit)
    local cgotype = cargoObj:GetType() or nil
    local suppressGetAndLoad = (self.enableChinookGCLoading == true) and isHook and (cgotype == CTLD_CARGO.Enum.STATIC)
    local canPartiallyLoad=((not capacityCrates or capacityCrates>=1)and(not maxMassCrates or maxMassCrates>=1))
    if canLoad and not isHerc and not suppressGetAndLoad then
      MENU_GROUP_COMMAND:New(Group, "Get and Load", parentMenu, self._GetAndLoad, self, Group, Unit, cargoObj, 1)
    else
      local msg
      if not isHerc and not suppressGetAndLoad then
        if maxMassSets and (not capacitySets or capacitySets >= 1) and maxMassSets < 1 then
          msg = "Weight limit reached"
        else
          msg = "Crate limit reached"
        end
        MENU_GROUP_COMMAND:New(Group, msg, parentMenu, self._SendMessage, self, msg, 10, false, Group)

        if canPartiallyLoad and (cgotype ~= CTLD_CARGO.Enum.STATIC) and (not suppressGetAndLoad) then
          MENU_GROUP_COMMAND:New(Group, "Partially load", parentMenu, self._GetAndLoad, self, Group, Unit, cargoObj, 1,true)
        end
      end
    end
   
    return self
  end

  for quantity = 1, maxQuantity do
    self:T("_AddCrateQuantityMenus maxQuantity "..maxQuantity.." Menu for MaxQ>1")
    local label = tostring(quantity)
    self:T("_AddCrateQuantityMenus Label "..label)
    local qMenu = MENU_GROUP:New(Group, label, parentMenu)
    MENU_GROUP_COMMAND:New(Group, "Get", qMenu, self._GetCrateQuantity, self, Group, Unit, cargoObj, quantity)
    local canLoad = (allowLoad and (not capacitySets or capacitySets >= quantity) and (not maxMassSets or maxMassSets >= quantity))
    local isHerc = self:IsC130J(Unit)
    local isHook = self:IsHook(Unit)
    local cgotype = cargoObj:GetType() or nil
    local suppressGetAndLoad = (self.enableChinookGCLoading == true) and isHook and (cgotype == CTLD_CARGO.Enum.STATIC)
    local canPartiallyLoad=((not capacityCrates or capacityCrates>=1)and(not maxMassCrates or maxMassCrates>=1))
    if canLoad and not isHerc and not suppressGetAndLoad  then
      MENU_GROUP_COMMAND:New(Group, "Get and Load", qMenu, self._GetAndLoad, self, Group, Unit, cargoObj, quantity)
    else
      local msg
      if not isHerc and not suppressGetAndLoad then
        if maxMassSets and (not capacitySets or capacitySets >= quantity) and maxMassSets < quantity then
          msg = "Weight limit reached"
        else
          msg = "Crate limit reached"
        end
        MENU_GROUP_COMMAND:New(Group, msg, qMenu, self._SendMessage, self, msg, 10, false, Group)
        if canPartiallyLoad and (cgotype ~= CTLD_CARGO.Enum.STATIC) and (not suppressGetAndLoad) then
          MENU_GROUP_COMMAND:New(Group, "Partially load", qMenu, self._GetAndLoad, self, Group, Unit, cargoObj, quantity, true)
        end
      end
    end
  end
  return self
end

--- User overrideable function to determine if a unit can get crates.
  -- @param #CTLD self
  -- @param Wrapper.Group#GROUP Group
  -- @param Wrapper.Unit#UNIT Unit
  -- @param #table Config Configuration entry for the unit.
  -- @param #number quantity Number of crate sets requested.
  -- @param #boolean quiet If true, do not send messages to the user.
  function CTLD:CanGetUnits(Group, Unit, Config, quantity, quiet)
    return true
  end

--- (Internal) Spawn a “Get units” entry for a C-130J-30 at load zone.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #string Name Name of the configured unit entry.
-- @return #CTLD self
function CTLD:_C130GetUnits(Group, Unit, Name)
  self:T(self.lid .. " _C130GetUnits")
  if not Group or not Unit then return self end
  local cfg = nil
  for _,entry in ipairs(self.C130GetUnits or {}) do
    if entry.Name == Name then
      cfg = entry
      break
    end
  end
  if not cfg then
    self:_SendMessage("No unit configuration found for "..tostring(Name),10,false,Group)
    return self
  end
  local stock = cfg.Stock
  if type(stock) == "number" and stock ~= -1 and stock <= 0 then
    self:_SendMessage(string.format("Sorry, all %s are gone!",cfg.Name or "units"),10,false,Group)
    return self
  end
  local inzone = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
  if not inzone then
    self:_SendMessage("You are not close enough to a logistics zone!",10,false,Group)
    return self
  end
  if not self:CanGetUnits(Group, Unit, cfg, 1, false) then
    return self
  end

  local coord = Unit:GetCoordinate() or Group:GetCoordinate()
  local capabilities = self:_GetUnitCapabilities(Unit)
  local innerDist = (capabilities.length and capabilities.length/2) or 15
  local maxUnitsNearby = self.maxUnitsNearby or 3
  local searchRadius = self.UnitDistance or 90
  local checkZone = ZONE_RADIUS:New("CTLD_C130UnitsZone",coord:GetVec2(),searchRadius,false)
  local nearGroups = SET_GROUP:New():FilterCoalitions("blue"):FilterZones({checkZone}):FilterOnce()
  local nearbyCount = 0
  for _,gr in pairs(nearGroups.Set) do
    local gc = gr:GetCoordinate()
    if gc then
      local dist = coord:Get2DDistance(gc)
      if dist > innerDist then
        for _,ucfg in pairs(self.C130GetUnits or {}) do
          local templ = ucfg.Templates or {}
          if type(templ) == "string" then
            templ = {templ}
          end
          local matched = false
          for _,tName in pairs(templ) do
            if string.match(gr:GetName(),tName) then
              nearbyCount = nearbyCount + 1
              matched = true
              break
            end
          end
          if matched or nearbyCount >= maxUnitsNearby then break end
        end
      end
    end
    if nearbyCount >= maxUnitsNearby then break end
  end
  if nearbyCount >= maxUnitsNearby then
    self:_SendMessage(string.format("You already have %d units nearby!",maxUnitsNearby),10,false,Group)
    return self
  end

  local temptable = cfg.Templates or {}
  if type(temptable) == "string" then
    temptable = {temptable}
  end
  local length = (capabilities.length + 5) or 30
  local heading = (Unit:GetHeading() + 180) % 360
  local canmove = cfg.CanMove ~= false
  local spawnedUnits = {}
  local idx = 1
  for _,_template in pairs(temptable) do
    local cratedistance = (idx-1)*2.5 + length
    local spawncoord = coord:Translate(cratedistance,heading)
    local randomcoord = spawncoord:GetVec2()
    self.TroopCounter = self.TroopCounter + 1
    local tc = self.TroopCounter
    local alias = string.format("%s-%d",_template,math.random(1,100000))
    if canmove then
      SPAWN:NewWithAlias(_template,alias)
        :InitRandomizeUnits(true,10,2)
        :InitValidateAndRepositionGroundUnits(self.validateAndRepositionUnits)
        :InitDelayOff()
        :OnSpawnGroup(function(grp,TimeStamp)
          grp.spawntime = TimeStamp or timer.getTime()
          self.DroppedTroops[tc] = grp
          table.insert(spawnedUnits,grp)
          self:__UnitsSpawn(1,Group,Unit,spawnedUnits)
        end)
        :SpawnFromVec2(randomcoord)
    else
      SPAWN:NewWithAlias(_template,alias)
        :InitRandomizeUnits(true,10,2)
        :InitDelayOff()
        :InitValidateAndRepositionGroundUnits(self.validateAndRepositionUnits)
        :OnSpawnGroup(function(grp,TimeStamp)
          grp.spawntime = TimeStamp or timer.getTime()
          self.DroppedTroops[tc] = grp
          table.insert(spawnedUnits,grp)
          self:__UnitsSpawn(1,Group,Unit,spawnedUnits)
        end)
        :SpawnFromVec2(randomcoord)
    end
    idx = idx + 1
  end
  if type(stock) == "number" and stock ~= -1 then
    cfg.Stock = stock - 1
  end
  self:_SendMessage(string.format("%s have been deployed near you!",cfg.Name or "selection"),10,false,Group)
  
  return self
end

--- (User) Hook to allow mission-specific crate restrictions.
-- Override this in your mission to perform custom checks (e.g. warehouse stock) before crates spawn.
-- Return `true` to allow the request, or `false` to block it. When blocked, `_GetCrates` exits silently.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group Requesting player group.
-- @param Wrapper.Unit#UNIT Unit Requesting unit.
-- @param #CTLD_CARGO Cargo Cargo type being requested.
-- @param #number number Number of crates requested (raw quantity, not sets).
-- @param #boolean drop Drop-mode request flag.
-- @param #boolean pack Pack-mode request flag.
-- @param #boolean quiet Quiet flag from menu call.
-- @param #boolean suppressGetEvent If true, `_GetCrates` will not emit the `GetCrates` event.
-- @return #boolean Allow crate spawning.
function CTLD:CanGetCrates(Group, Unit, Cargo, number, drop, pack, quiet, suppressGetEvent)
  return true
end

--- (Internal) Function to spawn crates in front of the heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD_CARGO Cargo
-- @param #number number Number of crates to generate (for dropping)
-- @param #boolean drop If true we\'re dropping from heli rather than loading.
-- @param #boolean pack If true we\'re packing crates from a template rather than loading or dropping
function CTLD:_GetCrates(Group, Unit, Cargo, number, drop, pack, quiet, suppressGetEvent)
  self:T(self.lid .. " _GetCrates")

  -- check if we have stock
  local perSet = Cargo:GetCratesNeeded() or 1
  if perSet < 1 then perSet = 1 end
  local requestNumber = tonumber(number)
  if requestNumber then
    requestNumber = math.floor(requestNumber)
    if requestNumber < 1 then requestNumber = perSet end
  else
    requestNumber = perSet
  end
  local requestedSets = math.floor((requestNumber + perSet - 1) / perSet)
  if requestedSets < 1 then requestedSets = 1 end
  if not drop and not pack then
    local cgoname = self:_GetCargoDisplayName(Cargo)
    local instock = Cargo:GetStock()
    if type(instock) == "number" and tonumber(instock) <= 0 and tonumber(instock) ~= -1 then
      -- nothing left over
      self:_SendMessage(string.format("Sorry, we ran out of %s", cgoname), 10, false, Group)
      return false
    end
  end

  -- check if we are in LOAD zone
  local inzone = false 
  local drop = drop or false
  local suppressGetEvent = suppressGetEvent or false
  local ship = nil
  local width = 20
  local distance = nil
  local zone = nil
  if not drop and not pack then 
    inzone = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
    if not inzone then
---@diagnostic disable-next-line: cast-local-type
      inzone, ship, zone, distance, width  = self:IsUnitInZone(Unit,CTLD.CargoZoneType.SHIP)
    end
  elseif drop and not pack then
    if self.dropcratesanywhere then -- #1570
      inzone = true
    else
      inzone = self:IsUnitInZone(Unit,CTLD.CargoZoneType.DROP)
    end
  elseif pack and not drop then
    inzone = true
  end
  
  if not inzone then
    self:_SendMessage("You are not close enough to a logistics zone!", 10, false, Group)
    if not self.debug then return self end
  end
  
  -- Check cargo location if available
  local location = Cargo:GetLocation()
  if location then
    local unitcoord = Unit:GetCoordinate() or Group:GetCoordinate()
    if unitcoord then
      if not location:IsCoordinateInZone(unitcoord) then
        -- no we're not at the right spot
        self:_SendMessage("The requested cargo is not available in this zone!", 10, false, Group)
        if not self.debug then return false end
      end
    end
  end
  
  -- avoid crate spam
  local capabilities = self:_GetUnitCapabilities(Unit) -- #CTLD.UnitTypeCapabilities
  local canloadcratesno = capabilities.cratelimit
  local loaddist = self.CrateDistance or 35
  local nearcrates, numbernearby = self:_FindCratesNearby(Group,Unit,loaddist,true,true,true) -- to ignore what's inside
  if numbernearby >= canloadcratesno and not drop then
    self:_SendMessage("There are enough crates nearby already! Take care of those first!", 10, false, Group)
    return false
  end

  if not drop and not self:CanGetCrates(Group, Unit, Cargo, requestNumber, drop, pack, quiet, suppressGetEvent) then
    return false
  end
  -- spawn crates in front of helicopter
  local IsHerc = self:IsFixedWing(Unit) -- Herc, Bronco and Hook load from behind
  local IsHook = self:IsHook(Unit) -- Herc, Bronco and Hook load from behind
  local IsTruck = Unit:IsGround()
  local cargotype = Cargo -- Ops.CTLD#CTLD_CARGO
  local number = requestNumber --#number
  local cratesneeded = cargotype:GetCratesNeeded() --#number
  local cratename = cargotype:GetName()
  local cratedisplayname = self:_GetCargoDisplayName(cargotype)
  local cratetemplate = "Container"-- #string
  local cgotype = cargotype:GetType()
  local cgomass = cargotype:GetMass()
  local isstatic = false
  if cgotype == CTLD_CARGO.Enum.STATIC then
    cratetemplate = cargotype:GetTemplates()
    isstatic = true
  end

  -- get position and heading of heli
  local position = Unit:GetCoordinate()
  local heading = Unit:GetHeading() + 1
  local height = Unit:GetHeight()
  local droppedcargo = {}
  local obtainedcargo = {}
  local cratedistance = 0
  local rheading = 0
  local angleOffNose = 0
  local addon = 0
  if IsHerc or IsHook or IsTruck then 
    -- spawn behind the Herc
    addon = 180
  end
  heading = (heading+addon)%360
  local row = 1
  local column = 1
  local initialdist = IsHerc and 16 or (capabilities.length+2) -- initial spacing of the first crates
  local startpos = position:Translate(initialdist,heading)
  if self.placeCratesAhead == true then
    cratedistance = initialdist
  end

  -- loop crates needed
  local cratecoord = nil -- Core.Point#COORDINATE
  for i=1,number do
    local cratealias = string.format("%s-%s-%d", cratename, cratetemplate, math.random(1,100000))
    if not self.placeCratesAhead or drop == true then
      cratedistance = (i-1)*2.5 + capabilities.length
      if cratedistance > self.CrateDistance then cratedistance = self.CrateDistance end
      -- altered heading logic
      -- DONE: right standard deviation?
      if self:IsUnitInAir(Unit) and self:IsFixedWing(Unit) then
        rheading = math.random(20,60)
      else
        rheading = UTILS.RandomGaussian(0, 30, -90, 90, 100)
      end
      rheading=math.fmod((heading+rheading),360)
      cratecoord = position:Translate(cratedistance,rheading)
    else
      cratedistance = (row-1)*6
      rheading = 90
      row = row+1
      cratecoord = startpos:Translate(cratedistance,rheading)
      if row > 4 then
        row = 1
        startpos:Translate(6,heading,nil,true)
      end
    end
    
    --local cratevec2 = cratecoord:GetVec2()
    self.CrateCounter = self.CrateCounter + 1
    local CCat, CType, CShape = Cargo:GetStaticTypeAndShape()
    local basetype = CType or self.basetype or "container_cargo"
    CCat = CCat or "Cargos"
    if not isstatic and self:IsC130J(Unit) then
      if Cargo.C130TypeName then
        basetype = Cargo.C130TypeName
      elseif self.C130basetype and (not CType or CType == self.basetype) then
        basetype = self.C130basetype
      end
    end
    if type(ship) == "string" then
      self:T("Spawning on ship "..ship)
      local Ship = UNIT:FindByName(ship)
      local shipcoord = Ship:GetCoordinate()
      local unitcoord = Unit:GetCoordinate()
      local dist = shipcoord:Get2DDistance(unitcoord)
      dist = dist - (20 + math.random(1,10))
      local width = width / 2
      local Offy = math.random(-width,width)
      local spawnstatic = SPAWNSTATIC:NewFromType(basetype,CCat,self.cratecountry)
      :InitCargoMass(cgomass)
      :InitCargo(self.enableslingload)
      :InitLinkToUnit(Ship,dist,Offy,0)
      if CShape then
        spawnstatic:InitShape(CShape)
      end 
      if isstatic then
        local map=cargotype:GetStaticResourceMap()
        spawnstatic.TemplateStaticUnit.resourcePayload = map
      end
      self.Spawned_Crates[self.CrateCounter] = spawnstatic:Spawn(270,cratealias)
    else   
      local spawnstatic = SPAWNSTATIC:NewFromType(basetype,CCat,self.cratecountry)
        :InitCoordinate(cratecoord)
        :InitCargoMass(cgomass)
        :InitCargo(self.enableslingload)
      if CShape then
        spawnstatic:InitShape(CShape)
      end 
      if isstatic then
        local map=cargotype:GetStaticResourceMap()
        spawnstatic.TemplateStaticUnit.resourcePayload = map
      end
      self.Spawned_Crates[self.CrateCounter] = spawnstatic:Spawn(270,cratealias)
    end
    local templ = cargotype:GetTemplates()
    local sorte = cargotype:GetType()
    local subcat = cargotype.Subcategory
    self.CargoCounter = self.CargoCounter + 1
    local realcargo = nil
    if drop then
                --CTLD_CARGO:New(ID, Name, Templates, Sorte, HasBeenMoved, LoadDirectly, CratesNeeded, Positionable, Dropped, PerCrateMass, Stock, Subcategory)
      realcargo = CTLD_CARGO:New(self.CargoCounter,cratename,templ,sorte,true,false,cratesneeded,self.Spawned_Crates[self.CrateCounter],true,cargotype.PerCrateMass,nil,subcat) -- #CTLD_CARGO
      realcargo:SetDisplayName(cargotype:GetDisplayName())
      local map=cargotype:GetStaticResourceMap()
      realcargo:SetStaticResourceMap(map)
      local CCat3, CType3, CShape3 = cargotype:GetStaticTypeAndShape()
      realcargo:SetStaticTypeAndShape(CCat3,CType3,CShape3)
      if cargotype.TypeNames then
        realcargo.TypeNames = UTILS.DeepCopy(cargotype.TypeNames)
      end
      table.insert(droppedcargo,realcargo)
    else
      realcargo = CTLD_CARGO:New(self.CargoCounter,cratename,templ,sorte,false,false,cratesneeded,self.Spawned_Crates[self.CrateCounter],false,cargotype.PerCrateMass,nil,subcat)
      realcargo:SetDisplayName(cargotype:GetDisplayName())
      local map=cargotype:GetStaticResourceMap()
      realcargo:SetStaticResourceMap(map) 
      if cargotype.TypeNames then
        realcargo.TypeNames = UTILS.DeepCopy(cargotype.TypeNames)
      end
      if self.UseC130LoadAndUnload and self:IsC130J(Unit) then
        realcargo:SetWasDropped(true,true) -- we mark here that the crates was dropped even though we just got them because of the herc.
      end
    end
    if not drop and not pack then
      table.insert(obtainedcargo, realcargo)
    end
    local CCat4, CType4, CShape4 = cargotype:GetStaticTypeAndShape()
    realcargo:SetStaticTypeAndShape(CCat4,CType4,CShape4)
    table.insert(self.Spawned_Cargo, realcargo)
  end

  if not (drop or pack) then
    Cargo:RemoveStock(requestedSets)
    self:_RefreshCrateQuantityMenus(Group, Unit, Cargo)
  end
  local text = string.format("%d crates for %s have been positioned near you!",number,cratedisplayname)
  if drop then
    text = string.format("%d crates for %s have been dropped!",number,cratedisplayname)
    self:__CratesDropped(1, Group, Unit, droppedcargo)
  else
    if not quiet then
      self:_SendMessage(text, 10, false, Group)
    end
    if not pack and not suppressGetEvent and #obtainedcargo > 0 then
      self:__GetCrates(1, Group, Unit, obtainedcargo)
    end
  end
  self:_RefreshLoadCratesMenu(Group, Unit)
  return true
end


--- (Internal) Inject crates and static cargo objects.
-- @param #CTLD self
-- @param Core.Zone#ZONE Zone Zone to spawn in.
-- @param #CTLD_CARGO Cargo The cargo type to spawn.
-- @param #boolean RandomCoord Randomize coordinate.
-- @param #boolean FromLoad Create only **one** crate per cargo type, as we are re-creating dropped crates that CTLD has saved prior.
-- @return #CTLD self
function CTLD:InjectStatics(Zone, Cargo, RandomCoord, FromLoad)
  self:T(self.lid .. " InjectStatics")
  local cratecoord = Zone:GetCoordinate()
  if RandomCoord then
    cratecoord = Zone:GetRandomCoordinate(5,20)
  end
  local surface = cratecoord:GetSurfaceType()
  if surface == land.SurfaceType.WATER then
    return self
  end
  local cargotype = Cargo -- #CTLD_CARGO
  --local number = 1
  local cratesneeded = cargotype:GetCratesNeeded() --#number
  local cratetemplate = "Container"-- #string
  local cratename = cargotype:GetName()
  local cgotype = cargotype:GetType()
  local cgomass = cargotype:GetMass()
  local cratenumber = cargotype:GetCratesNeeded() or 1
  if FromLoad == true then cratenumber=1 end
  for i=1,cratenumber do
    local cratealias = string.format("%s-%s-%d", cratename, cratetemplate, math.random(1,100000))
    local isstatic = false
    if cgotype == CTLD_CARGO.Enum.STATIC then
      cratetemplate = cargotype:GetTemplates()
      isstatic = true
    end
    local CCat,CType,CShape = cargotype:GetStaticTypeAndShape()
    local basetype = CType or self.basetype or "container_cargo"
    CCat = CCat or "Cargos"
    if isstatic then
      basetype = cratetemplate
    end
    self.CrateCounter = self.CrateCounter + 1
    local spawnstatic = SPAWNSTATIC:NewFromType(basetype,CCat,self.cratecountry)
      :InitCargoMass(cgomass)
      :InitCargo(self.enableslingload)
      :InitCoordinate(cratecoord)
    if CShape then
      spawnstatic:InitShape(CShape)
    end
    if isstatic then
      local map = cargotype:GetStaticResourceMap()
      spawnstatic.TemplateStaticUnit.resourcePayload = map
    end
    self.Spawned_Crates[self.CrateCounter] = spawnstatic:Spawn(270,cratealias)
    local templ = cargotype:GetTemplates()
    local sorte = cargotype:GetType()
    cargotype.Positionable = self.Spawned_Crates[self.CrateCounter]
    table.insert(self.Spawned_Cargo, cargotype)
  end
  return self
end

--- (User) Inject static cargo objects.
-- @param #CTLD self
-- @param Core.Zone#ZONE Zone Zone to spawn in. Will be a somewhat random coordinate.
-- @param #string Template Unit(!) name of the static cargo object to be used as template.
-- @param #number Mass Mass of the static in kg.
-- @return #CTLD self
function CTLD:InjectStaticFromTemplate(Zone, Template, Mass)
  self:T(self.lid .. " InjectStaticFromTemplate")
  local cargotype = self:GetStaticsCargoFromTemplate(Template,Mass) -- #CTLD_CARGO
  self:InjectStatics(Zone,cargotype,true,true)
  return self
end

--- (Internal) Function to find and list nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_ListCratesNearby( _group, _unit)
  self:T(self.lid .. " _ListCratesNearby")
  local finddist = self.CrateDistance or 35
  local crates,number,loadedbygc,indexgc = self:_FindCratesNearby(_group,_unit, finddist,true,true,true) -- #table
  if number > 0 or indexgc > 0 then
    local text = REPORT:New("Crates Found Nearby:")
    text:Add("------------------------------------------------------------")
    for _,_entry in pairs (crates) do
      local entry = _entry -- #CTLD_CARGO
      local name = entry:GetName() --#string
      local dropped = entry:WasDropped()
      if dropped then
        text:Add(string.format("Dropped crate for %s, %dkg",name, entry.PerCrateMass))
      else
        text:Add(string.format("Crate for %s, %dkg",name, entry.PerCrateMass))
      end
    end
    if text:GetCount() == 1 then
    text:Add("        N O N E")
    end
    text:Add("------------------------------------------------------------")
    if indexgc > 0 then
      text:Add("Probably ground crew loadable (F8)")
      for _,_entry in pairs (loadedbygc) do
        local entry = _entry -- #CTLD_CARGO
        local name = entry:GetName() --#string
        local dropped = entry:WasDropped()
        if dropped then
          text:Add(string.format("Dropped crate for %s, %dkg",name, entry.PerCrateMass))
        else
          text:Add(string.format("Crate for %s, %dkg",name, entry.PerCrateMass))
        end
      end
    end
    self:_SendMessage(text:Text(), 30, true, _group) 
  else
    self:_SendMessage(string.format("No (loadable) crates within %d meters!",finddist), 10, false, _group) 
  end
  return self
end

--- (Internal) Function to find and remove nearby C-130 managed units.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_C130RemoveUnitsNearby(_group,_unit)
  self:T(self.lid .. " _C130RemoveUnitsNearby")
  if not _group or not _unit then return self end
  local location = _group:GetCoordinate()
  if not location then return self end
  local capabilities = self:_GetUnitCapabilities(_unit)
  local innerDist = (capabilities.length and capabilities.length/2) or 15
  local finddist = self.PackDistance or (self.CrateDistance or 35)
  local zone = ZONE_RADIUS:New("CTLD_C130RemoveZone",location:GetVec2(),finddist,false)
  local nearestGroups = SET_GROUP:New():FilterCoalitions("blue"):FilterZones({zone}):FilterOnce()
  local removedAny = false
  local removedTable = {}
  for _, gr in pairs(nearestGroups.Set) do
    local gc = gr:GetCoordinate()
    if gc then
      local dist = location:Get2DDistance(gc)
      if dist > innerDist then
        local didRemoveThis = false
        for _, cfg in pairs(self.C130GetUnits or {}) do
          local templ = cfg.Templates or {}
          if type(templ) == "string" then
            templ = {templ}
          end
          for _, tName in pairs(templ) do
            if string.match(gr:GetName(),tName) then
              local cname = cfg.Name or "Unit"
              table.insert(removedTable, { groupName = gr:GetName(), name = cname, template = tName, coordinate = gr:GetCoordinate() })
              gr:Destroy(false)
              self:_SendMessage(cname.." have been removed",10,false,_group)
              removedAny = true
              didRemoveThis = true
              break
            end
          end
          if didRemoveThis then break end
        end
      end
    end
  end
  if not removedAny then
    self:_SendMessage("Nothing to remove at this distance pilot!",10,false,_group)
  else
    -- Trigger FSM event for removed units (C-130 managed groups).
    self:__RemoveCratesNearby(1, _group, _unit, removedTable)
  end
  return self
end

--- (Internal) Function to find and Remove nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_RemoveCratesNearby(_group, _unit)
  self:T(self.lid.." _RemoveCratesNearby")
  local finddist=self.CrateDistance or 35
  local crates,number=self:_FindCratesNearby(_group,_unit,finddist,true,true,true)
  if number>0 then
    local removedIDs={}
    local text=REPORT:New("Removing Crates Found Nearby:")
    text:Add("------------------------------------------------------------")
    for _,_entry in pairs(crates)do
      local entry=_entry
      local name=entry:GetName()or"none"
      text:Add(string.format("Crate for %s, %dkg removed",name,entry.PerCrateMass))
      local pos = entry:GetPositionable()
      if pos then
        -- Store removal position before destroying so callbacks can use it.
        entry.coordinate = pos:GetCoordinate()
        pos:Destroy(false)
      end
      table.insert(removedIDs,entry:GetID())
    end
    if text:GetCount()==1 then
      text:Add("        N O N E")
    end
    text:Add("------------------------------------------------------------")
    self:_SendMessage(text:Text(),30,true,_group)
    local done = {}
    for _, e in pairs(crates) do
    local n = e:GetName() or "none"
    if not done[n] then
        local object = self:_FindCratesCargoObject(n)
        if object then self:_RefreshCrateQuantityMenus(_group, _unit, object) end
        done[n] = true
    end
    end
    self:_RefreshLoadCratesMenu(_group,_unit)

    -- Trigger FSM event for removed crates.
    self:__RemoveCratesNearby(1, _group, _unit, crates)
  else
    self:_SendMessage(string.format("No (loadable) crates within %d meters!",finddist),10,false,_group)
  end
  return self
end

--- (Internal) Return distance in meters between two coordinates.
-- @param #CTLD self
-- @param Core.Point#COORDINATE _point1 Coordinate one
-- @param Core.Point#COORDINATE _point2 Coordinate two
-- @return #number Distance in meters
function CTLD:_GetDistance(_point1, _point2)
  self:T(self.lid .. " _GetDistance")
  if _point1 and _point2 then
    local distance1 = _point1:Get2DDistance(_point2)
    local distance2 = _point1:DistanceFromPointVec2(_point2)
    if distance1 and type(distance1) == "number" then
      return distance1
    elseif distance2 and type(distance2) == "number" then
      return distance2
    else
      self:E("*****Cannot calculate distance!")
      self:E({_point1,_point2})
      return -1
    end
  else
    self:E("******Cannot calculate distance!")
    self:E({_point1,_point2})
    return -1
  end
end

--- (Internal) Function to find and return nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP _group Group
-- @param Wrapper.Unit#UNIT _unit Unit
-- @param #number _dist Distance
-- @param #boolean _ignoreweight Find everything in range, ignore loadable weight
-- @param #boolean ignoretype Find everything in range, ignore loadable type name
-- @return #table Crates Table of crates
-- @return #number Number Number of crates found
-- @return #table CratesGC Table of crates possibly loaded by GC
-- @return #number NumberGC Number of crates possibly loaded by GC
function CTLD:_FindCratesNearby( _group, _unit, _dist, _ignoreweight, ignoretype, ignoreHercInner)
  self:T(self.lid .. " _FindCratesNearby")
  local finddist = _dist
  local location = _group:GetCoordinate()
  local existingcrates = self.Spawned_Cargo -- #table
  -- cycle
  local index = 0
  local indexg = 0
  local found = {}
  local LoadedbyGC = {}
  local loadedmass = 0
  local unittype = "none"
  local capabilities = {}
  --local maxmass = 2000
  local maxloadable = 2000
  local IsHook = self:IsHook(_unit)
  if not _ignoreweight then
    maxloadable = self:_GetMaxLoadableMass(_unit)
  end
  self:T(self.lid .. " Max loadable mass: " .. maxloadable)
  for _,_cargoobject in pairs (existingcrates) do
    local cargo = _cargoobject -- #CTLD_CARGO
    local static = cargo:GetPositionable() -- Wrapper.Static#STATIC -- crates
    local weight = cargo:GetMass() -- weight in kgs of this cargo
    local staticid = cargo:GetID()
    self:T(self.lid .. " Found cargo mass: " .. weight)
    if static and static:IsAlive() then --or cargoalive) then
      local restricthooktononstatics = self.enableChinookGCLoading and IsHook
      self:T(self.lid .. " restricthooktononstatics: " .. tostring(restricthooktononstatics))
      local cargoisstatic = cargo:GetType() == CTLD_CARGO.Enum.STATIC and true or false
      self:T(self.lid .. " Cargo is static: " .. tostring(cargoisstatic))
      local restricted = cargoisstatic and restricthooktononstatics
      self:T(self.lid .. " Loading restricted: " .. tostring(restricted))
      local staticpos = static:GetCoordinate() --or dcsunitpos
      local cando = cargo:UnitCanCarry(_unit)
      if ignoretype == true then cando = true restricted = false end
      self:T(self.lid .. " Unit can carry: " .. tostring(cando))
      --- Testing
      local distance=self:_GetDistance(location,staticpos)
      local hercInnerBlocked=false
      if self.UseC130LoadAndUnload and ignoreHercInner and _unit and self:IsC130J(_unit) then
      local capabilities=self:_GetUnitCapabilities(_unit) -- #CTLD.UnitTypeCapabilities
      local innerDist= capabilities.length and (capabilities.length/2) or 4
      if distance<innerDist then
      hercInnerBlocked=true
      end
      end
      self:T(self.lid..string.format("Dist %dm/%dm | weight %dkg | maxloadable %dkg",distance,finddist,weight,maxloadable))
      if distance<=finddist and(weight<=maxloadable or _ignoreweight)and restricted==false and cando==true and not hercInnerBlocked then
        index = index + 1
        table.insert(found, staticid, cargo)
        maxloadable = maxloadable - weight
      end
      
    end
  end
  return found, index, LoadedbyGC, indexg
end

--- (Internal) Function to get and load nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_LoadCratesNearby(Group, Unit)
  self:T(self.lid .. " _LoadCratesNearby")
    -- load crates into heli
  local group = Group -- Wrapper.Group#GROUP
  local unit = Unit  -- Wrapper.Unit#UNIT
  local unitname = unit:GetName()
    -- see if this heli can load crates
  local unittype = unit:GetTypeName()
  local capabilities = self:_GetUnitCapabilities(Unit) -- #CTLD.UnitTypeCapabilities
  local cancrates = capabilities.crates -- #boolean
  local cratelimit = capabilities.cratelimit -- #number
  local grounded = not self:IsUnitInAir(Unit)
  local canhoverload = self:CanHoverLoad(Unit)

  -- Door check
  if self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
    self:_SendMessage("You need to open the door(s) to load cargo!", 10, false, Group)
    if not self.debug then return self end
  end
  --- cases -------------------------------
  -- Chopper can\'t do crates - bark & return
  -- Chopper can do crates -
  -- --> hover if forcedhover or bark and return
  -- --> hover or land if not forcedhover
  -----------------------------------------
  if not cancrates then
    self:_SendMessage("Sorry this chopper cannot carry crates!", 10, false, Group)
  elseif self.forcehoverload and not canhoverload then
    self:_SendMessage("Hover over the crates to pick them up!", 10, false, Group)
  elseif not grounded and not canhoverload then
    self:_SendMessage("Land or hover over the crates to pick them up!", 10, false, Group)
  else
    -- have we loaded stuff already?
    local numberonboard = 0
    local loaded        = {}
    if self.Loaded_Cargo[unitname] then
      loaded         = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
      numberonboard  = loaded.Cratesloaded or 0
    else
      loaded = {}
      loaded.Troopsloaded = 0
      loaded.Cratesloaded = 0
      loaded.Cargo = {}
    end

    -- get nearby crates
    local finddist           = self.CrateDistance or 35
    local nearcrates, number = self:_FindCratesNearby(Group,Unit,finddist,false,false)
    self:T(self.lid .. " Crates found: " .. number)

    if number == 0 and self.hoverautoloading then
      return self
    elseif number == 0 then
      self:_SendMessage("Sorry, no loadable crates nearby or max cargo weight reached!", 10, false, Group)
      return self
    elseif numberonboard == cratelimit then
      self:_SendMessage("Sorry, we are fully loaded!", 10, false, Group)
      return self
    else
      local capacity = cratelimit - numberonboard
      local crateidsloaded = {}
      local crateMap = {}

      for _, cObj in pairs(nearcrates) do
        if not cObj:HasMoved() or self.allowcratepickupagain then
          local cName = cObj:GetName() or "Unknown"
          crateMap[cName] = crateMap[cName] or {}
          table.insert(crateMap[cName], cObj)
        end
      end
      for cName, crateList in pairs(crateMap) do
        if capacity <= 0 then break end

        table.sort(crateList, function(a, b) return a:GetID() > b:GetID() end)
        local needed = crateList[1]:GetCratesNeeded() or 1
        local totalFound = #crateList
        local loadedHere = 0

        while loaded.Cratesloaded < cratelimit and loadedHere < totalFound do
          loadedHere = loadedHere + 1
          local crate = crateList[loadedHere]
          if crate and crate.Positionable then
            loaded.Cratesloaded = loaded.Cratesloaded + 1
            crate:SetHasMoved(true)
            crate:SetWasDropped(false)
            table.insert(loaded.Cargo, crate)
            table.insert(crateidsloaded, crate:GetID())
            -- destroy crate
            crate:GetPositionable():Destroy(false)
            crate.Positionable = nil
          else
            loadedHere = loadedHere - 1
            break
          end
        end

        capacity = cratelimit - loaded.Cratesloaded
        if loadedHere > 0 then
          local fullSets = math.floor(loadedHere / needed)
          local leftover = loadedHere % needed

          if needed > 1 then
            if fullSets > 0 and leftover == 0 then
              self:_SendMessage(string.format("Loaded %d %s.", fullSets, cName), 10, false, Group)
            elseif fullSets > 0 and leftover > 0 then
              self:_SendMessage(string.format("Loaded %d %s(s), with %d leftover crate(s).", fullSets, cName, leftover), 10, false, Group)
            else
              self:_SendMessage(string.format("Loaded only %d/%d crate(s) of %s.", loadedHere, needed, cName), 15, false, Group)
            end
          else
            self:_SendMessage(string.format("Loaded %d %s(s).", loadedHere, cName), 10, false, Group)
          end
        end
      end
      self.Loaded_Cargo[unitname] = loaded
      self:_UpdateUnitCargoMass(Unit)
      self:_RefreshDropCratesMenu(Group, Unit)
      self:_RefreshLoadCratesMenu(Group, Unit)
      -- clean up real world crates
      self:_CleanupTrackedCrates(crateidsloaded)
      self:__CratesPickedUp(1, Group, Unit, loaded.Cargo)
      self:_RefreshCrateQuantityMenus(Group, Unit, nil)
    end
  end
  return self
end


--- (Internal) Function to clean up tracked cargo crates
-- @param #CTLD self
-- @param #list crateIdsToRemove Table of IDs
-- @return self
function CTLD:_CleanupTrackedCrates(crateIdsToRemove)
  local existingcrates = self.Spawned_Cargo -- #table
  local newexcrates = {}
  for _,_crate in pairs(existingcrates) do
    local excrate = _crate -- #CTLD_CARGO
    local ID = excrate:GetID()
    local keep = true
    for _,_ID in pairs(crateIdsToRemove) do
      if ID == _ID then
        keep = false
      end
    end
    -- remove destroyed crates here too
    local static = _crate:GetPositionable() -- Wrapper.Static#STATIC -- crates
    if not static or not static:IsAlive() then
      keep = false
    end
    if keep then
      table.insert(newexcrates,_crate)
    end
  end
  self.Spawned_Cargo = nil
  self.Spawned_Cargo = newexcrates
  return self
end

--- (Internal) Function to get current loaded mass
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit
-- @return #number mass in kgs
function CTLD:_GetUnitCargoMass(Unit) 
  self:T(self.lid .. " _GetUnitCargoMass")
  if not Unit then return 0 end
  local unitname = Unit:GetName()
  local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
  local loadedmass = 0 -- #number
  if self.Loaded_Cargo[unitname] then
    local cargotable = loadedcargo.Cargo or {} -- #table
    for _,_cargo in pairs(cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) and not cargo:WasDropped() then
        loadedmass = loadedmass + (cargo.PerCrateMass * cargo:GetCratesNeeded())
      end
      if type ~= CTLD_CARGO.Enum.TROOPS and type ~=  CTLD_CARGO.Enum.ENGINEERS and type ~= CTLD_CARGO.Enum.GCLOADABLE and not cargo:WasDropped() then
        loadedmass = loadedmass + cargo.PerCrateMass
      end
      if type == CTLD_CARGO.Enum.GCLOADABLE then
        local mass = cargo:GetCargoWeight()
        loadedmass = loadedmass+mass
      end
    end
  end
  return loadedmass
end

--- (Internal) Function to calculate max loadable mass left over.
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit
-- @return #number maxloadable Max loadable mass in kg
function CTLD:_GetMaxLoadableMass(Unit)
  self:T(self.lid .. " _GetMaxLoadableMass")
  if not Unit then return 0 end
  local loadable = 0
  local loadedmass = self:_GetUnitCargoMass(Unit)
  local capabilities = self:_GetUnitCapabilities(Unit) -- #CTLD.UnitTypeCapabilities
  local maxmass = capabilities.cargoweightlimit or 2000 -- max 2 tons
  loadable = maxmass - loadedmass
  return loadable
end

--- (Internal) Function to calculate and set Unit internal cargo mass
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit
function CTLD:_UpdateUnitCargoMass(Unit)
  self:T(self.lid .. " _UpdateUnitCargoMass")
  local calculatedMass = self:_GetUnitCargoMass(Unit)
  Unit:SetUnitInternalCargo(calculatedMass)
  return self
end

--- (Internal) Function to list loaded cargo.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_ListCargo(Group, Unit)
  self:T(self.lid .. " _ListCargo")
  local unitname = Unit:GetName()
  local unittype = Unit:GetTypeName()
  local capabilities = self:_GetUnitCapabilities(Unit) -- #CTLD.UnitTypeCapabilities
  local trooplimit = capabilities.trooplimit -- #boolean
  local cratelimit = capabilities.cratelimit -- #number
  local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
  local loadedmass = self:_GetUnitCargoMass(Unit) -- #number
  local maxloadable = self:_GetMaxLoadableMass(Unit)
  local finddist = self.CrateDistance or 35
  local hercInnerCrates = nil
  local hercInnerCount = 0
  if self:IsC130J(Unit) or self:IsHook(Unit) then
  local innerDist = (capabilities.length and capabilities.length/2) or 15
  local innerCrates,innerCount = self:_FindCratesNearby(Group,Unit,innerDist,true,true)
  hercInnerCrates = innerCrates
  hercInnerCount = innerCount or 0
  end

  --local _,_,loadedgc,loadedno = self:_FindCratesNearby(Group,Unit,finddist,true)

  if self.Loaded_Cargo[unitname] or hercInnerCount > 0 then
    local no_troops = loadedcargo.Troopsloaded or 0
    local no_crates = loadedcargo.Cratesloaded or 0
    local cargotable = loadedcargo.Cargo or {} -- #table
    local report = REPORT:New("Transport Checkout Sheet")
    report:Add("------------------------------------------------------------")
    report:Add(string.format("Troops: %d(%d), Crates: %d(%d)",no_troops,trooplimit,no_crates,cratelimit))
    report:Add("------------------------------------------------------------")
    report:Add("        -- TROOPS --")
    for _,_cargo in pairs(cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) and (not cargo:WasDropped() or self.allowcratepickupagain) then
        report:Add(string.format("Troop: %s size %d", cargo:GetName(), cargo:GetCratesNeeded()))
      end
    end
    if report:GetCount() == 4 then
      report:Add("        N O N E")
    end
    report:Add("------------------------------------------------------------")
    report:Add("       -- CRATES --")
    local cratecount = 0
    local accumCrates = {}
    for _,_cargo in pairs(cargotable or {}) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type ~= CTLD_CARGO.Enum.TROOPS and type ~= CTLD_CARGO.Enum.ENGINEERS and type ~= CTLD_CARGO.Enum.GCLOADABLE) and (not cargo:WasDropped() or self.allowcratepickupagain) then
        local cName = cargo:GetName()
        local needed = cargo:GetCratesNeeded() or 1
        accumCrates[cName] = accumCrates[cName] or {count=0, needed=needed}
        accumCrates[cName].count = accumCrates[cName].count + 1
      end
      if type == CTLD_CARGO.Enum.GCLOADABLE and not cargo:WasDropped() then
        report:Add(string.format("GC loaded Crate: %s size 1", cargo:GetName()))
        cratecount = cratecount + 1
      end
    end
    for cName, data in pairs(accumCrates) do
      cratecount = cratecount + data.count
      report:Add(string.format("Crate: %s %d/%d", cName, data.count, data.needed))
    end
    if cratecount == 0 then
      report:Add("        N O N E")
    end
    if hercInnerCount > 0 then
    local hercMass = 0
      for _,_cargo in pairs(hercInnerCrates or {}) do
        local cargo = _cargo
        local type = cargo:GetType()
        if type ~= CTLD_CARGO.Enum.TROOPS and type ~= CTLD_CARGO.Enum.ENGINEERS then
          report:Add(string.format("Crate: %s size 1",cargo:GetName()))
      hercMass = hercMass + cargo:GetMass()
        end
      end
    loadedmass = loadedmass + hercMass
    end
    --[[
    if loadedno > 0 then
      report:Add("------------------------------------------------------------")
      report:Add("       -- CRATES loaded via Ground Crew --")
      for _,_cargo in pairs(loadedgc or {}) do
        local cargo = _cargo -- #CTLD_CARGO
        local type = cargo:GetType() -- #CTLD_CARGO.Enum
        if (type ~= CTLD_CARGO.Enum.TROOPS and type ~= CTLD_CARGO.Enum.ENGINEERS) then
          report:Add(string.format("Crate: %s size 1",cargo:GetName()))
          loadedmass = loadedmass + cargo:GetMass()
        end
      end
    end
    --]]
    report:Add("------------------------------------------------------------")
    report:Add("Total Mass: ".. loadedmass .. " kg. Loadable: "..maxloadable.." kg.")
    local text = report:Text()
    self:_SendMessage(text, 30, true, Group)
  else
    self:_SendMessage(string.format("Nothing loaded!\nTroop limit: %d | Crate limit %d | Weight limit %d kgs", trooplimit, cratelimit, maxloadable), 10, false, Group)
  end
  return self
end
--- (Internal) Function to list loaded cargo.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_ListInventory(Group, Unit)
  self:T(self.lid .. " _ListInventory")
  local unitname = Unit:GetName()
  local unittype = Unit:GetTypeName()
  local cgotypes = self.Cargo_Crates
  local trptypes = self.Cargo_Troops
  local stctypes = self.Cargo_Statics
  
  local function countcargo(cgotable)
    local counter = 0
    for _,_cgo in pairs(cgotable) do
      counter = counter + 1
    end
    return counter
  end
  
  local crateno = countcargo(cgotypes)
  local troopno = countcargo(trptypes)
  local staticno = countcargo(stctypes)
  
  if (crateno > 0 or troopno > 0 or staticno > 0) then

    local report = REPORT:New("Inventory Sheet")
    report:Add("------------------------------------------------------------")
    report:Add(string.format("Troops: %d, Cratetypes: %d",troopno,crateno+staticno))
    report:Add("------------------------------------------------------------")
    report:Add("        -- TROOPS --")
    for _,_cargo in pairs(trptypes) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) and not cargo:WasDropped() then
        local stockn = cargo:GetStock()
        local stock = "none"
        if stockn == -1 then 
          stock = "unlimited"
        elseif stockn > 0 then
          stock = tostring(stockn)
        end
        report:Add(string.format("Unit: %s | Soldiers: %d | Stock: %s",cargo:GetName(),cargo:GetCratesNeeded(),stock))
      end
    end
    if report:GetCount() == 4 then
      report:Add("        N O N E")
    end
    report:Add("------------------------------------------------------------")
    report:Add("       -- CRATES --")
    local cratecount = 0
    for _,_cargo in pairs(cgotypes) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type ~= CTLD_CARGO.Enum.TROOPS and type ~= CTLD_CARGO.Enum.ENGINEERS) and not cargo:WasDropped() then
        local stockn = cargo:GetStock()
        local stock = "none"
        if stockn == -1 then 
          stock = "unlimited"
        elseif stockn > 0 then
          stock = tostring(stockn)
        end
        report:Add(string.format("Type: %s | Crates per Set: %d | Stock: %s",cargo:GetName(),cargo:GetCratesNeeded(),stock))
        cratecount = cratecount + 1
      end
    end
    -- Statics
    for _,_cargo in pairs(stctypes) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type == CTLD_CARGO.Enum.STATIC) and not cargo:WasDropped() then
        local stockn = cargo:GetStock()
        local stock = "none"
        if stockn == -1 then 
          stock = "unlimited"
        elseif stockn > 0 then
          stock = tostring(stockn)
        end
        report:Add(string.format("Type: %s | Stock: %s",cargo:GetName(),stock))
        cratecount = cratecount + 1
      end
    end
    if cratecount == 0 then
      report:Add("        N O N E")
    end
    local text = report:Text()
    self:_SendMessage(text, 30, true, Group) 
  else
    self:_SendMessage(string.format("Nothing in stock!"), 10, false, Group) 
  end
  return self
end

--- (Internal) Function to check if a unit is an allowed fixed wing.
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit
-- @return #boolean Outcome
function CTLD:IsFixedWing(Unit)
  local typename = Unit:GetTypeName() or "none"  
  for _,_name in pairs(self.FixedWingTypes or {}) do
    if _name and (typename==_name or string.find(typename,_name,1,true))then
      return true
    end
  end
  return false
end

--- (Internal) Function to check if a unit is a CH-47
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit
-- @return #boolean Outcome
function CTLD:IsHook(Unit)
    if not Unit then return false end
    local typeName = Unit:GetTypeName()
    if not typeName then return false end
    if string.find(typeName, "CH.47") then
        return true
    else
        return false
    end
end

--- (Internal) Function to set troops positions of a template to a nice circle
-- @param #CTLD self
-- @param Core.Point#COORDINATE Coordinate Start coordinate to use
-- @param #number Radius Radius to be used
-- @param #number Heading Heading starting with
-- @param #string Template The group template name
-- @return #table Positions The positions table
function CTLD:_GetUnitPositions(Coordinate,Radius,Heading,Template)
  local Positions = {}
  local template = _DATABASE:GetGroupTemplate(Template)
  --UTILS.PrintTableToLog(template)
  local numbertroops = #template.units
  local slightshift = math.abs(math.random(1,500)/100)
  local newcenter = Coordinate:Translate(Radius+slightshift,((Heading+270+math.random(1,10))%360))
  for i=1,360,math.floor(360/numbertroops) do
    local phead = ((Heading+270+i)%360)
    local post = newcenter:Translate(Radius,phead)
    local pos1 = post:GetVec2()
    local p1t = {
    x = pos1.x,
    y = pos1.y,
    heading = phead,
    }
    table.insert(Positions,p1t)
  end
  --UTILS.PrintTableToLog(Positions)
  return Positions
end

--- (Internal) Function to unload troops from heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
function CTLD:_UnloadTroops(Group, Unit)
  self:T(self.lid .. " _UnloadTroops")
  -- check if we are in LOAD zone
  local droppingatbase = false
  local canunload = true
  if self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
    self:_SendMessage("You need to open the door(s) to unload troops!", 10, false, Group)
    if not self.debug then return self end 
  end
  local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
  if not inzone then
    inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.SHIP)
  end
  if inzone then
    droppingatbase = self.returntroopstobase
  end
  -- check for hover unload
  local hoverunload = self:IsCorrectHover(Unit) --if true we\'re hovering in parameters
  local IsHerc = self:IsFixedWing(Unit)
  local IsHook = self:IsHook(Unit) 
  if IsHerc and (not IsHook) then
    -- no hover but airdrop here
    hoverunload = self:IsCorrectFlightParameters(Unit)
  end
  -- check if we\'re landed
  local grounded = not self:IsUnitInAir(Unit)
  -- Get what we have loaded
  local unitname = Unit:GetName()
  if self.Loaded_Cargo[unitname] and (grounded or hoverunload) then
    if not droppingatbase or self.debug then
      local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
      -- looking for troops
      local cargotable = loadedcargo.Cargo
      local deployedTroopsByName = {}
      local deployedEngineersByName = {}
      for _,_cargo in pairs (cargotable) do
        local cargo = _cargo -- #CTLD_CARGO
        local type = cargo:GetType() -- #CTLD_CARGO.Enum
        if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) and not cargo:WasDropped() then
          -- unload troops
          local name = cargo:GetName() or "none"
          local temptable = cargo:GetTemplates() or {}
          local position = Group:GetCoordinate()
          local zoneradius = self.troopdropzoneradius or 100 -- drop zone radius
          local factor = 1
          if IsHerc then
            factor = cargo:GetCratesNeeded() or 1 -- spread a bit more if airdropping
            zoneradius = Unit:GetVelocityMPS() or 100
          end
          local zone = ZONE_GROUP:New(string.format("Unload zone-%s",unitname),Group,zoneradius*factor)
          local randomcoord = zone:GetRandomCoordinate(10,30*factor) --:GetVec2()
          local heading = Group:GetHeading() or 0
          -- Spawn troops left from us, closer when hovering, further off when landed
          if hoverunload or grounded then
            randomcoord = Group:GetCoordinate()
            -- slightly left from us           
            local Angle = (heading+270)%360
            if IsHerc or IsHook then Angle = (heading+180)%360 end
            local offset = hoverunload and self.TroopUnloadDistHover or self.TroopUnloadDistGround
            if IsHerc then offset = self.TroopUnloadDistGroundHerc or 25 end
            if IsHook then  
              offset = self.TroopUnloadDistGroundHook or 15 
              if hoverunload and self.TroopUnloadDistHoverHook then
                offset = self.TroopUnloadDistHoverHook or 5
              end
            end
            randomcoord:Translate(offset,Angle,nil,true)
          end
          local tempcount = 0
          local ishook = self:IsHook(Unit)
          if ishook then tempcount = self.ChinookTroopCircleRadius or 5 end -- 10m circle for the Chinook
          for _,_template in pairs(temptable) do
            self.TroopCounter = self.TroopCounter + 1
            tempcount = tempcount+1
            local alias = string.format("%s-%d", _template, math.random(1,100000))
            local rad = 2.5+(tempcount*2)
            local Positions = self:_GetUnitPositions(randomcoord,rad,heading,_template)
            self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
              :InitDelayOff()
              :InitSetUnitAbsolutePositions(Positions)
              :InitValidateAndRepositionGroundUnits(self.validateAndRepositionUnits)
              :OnSpawnGroup(function(grp) grp.spawntime = timer.getTime() end)
              :SpawnFromVec2(randomcoord:GetVec2())
            self:__TroopsDeployed(1, Group, Unit, self.DroppedTroops[self.TroopCounter],type)
          end -- template loop
          cargo:SetWasDropped(true)
          -- engineering group?
          if type == CTLD_CARGO.Enum.ENGINEERS then
            self.Engineers = self.Engineers + 1
            local grpname = self.DroppedTroops[self.TroopCounter]:GetName()
            self.EngineersInField[self.Engineers] = CTLD_ENGINEERING:New(name, grpname)
            deployedEngineersByName[name] = (deployedEngineersByName[name] or 0) + 1
          else
            deployedTroopsByName[name] = (deployedTroopsByName[name] or 0) + 1
          end
        end -- if type end
      end  -- cargotable loop
      local parts = {}
      for nName,nCount in pairs(deployedTroopsByName) do
        parts[#parts + 1] = tostring(nCount).."x Troops "..nName
      end
      for nName,nCount in pairs(deployedEngineersByName) do
        parts[#parts + 1] = tostring(nCount).."x Engineers "..nName
      end
      if #parts > 0 then
        self:_SendMessage("Dropped "..table.concat(parts, ", ").." into action!", 10, false, Group)
      end
    else -- droppingatbase
        self:_SendMessage("Troops have returned to base!", 10, false, Group) 
        self:__TroopsRTB(1, Group, Unit, zonename, zone)
    end
    -- cleanup load list
    local    loaded = {} -- #CTLD.LoadedCargo
    loaded.Troopsloaded = 0
    loaded.Cratesloaded = 0
    loaded.Cargo = {}
    local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
    local cargotable = loadedcargo.Cargo or {}
    for _,_cargo in pairs (cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      local dropped = cargo:WasDropped()
      if type ~= CTLD_CARGO.Enum.TROOPS and type ~= CTLD_CARGO.Enum.ENGINEERS and not dropped then
        table.insert(loaded.Cargo,_cargo)
        loaded.Cratesloaded = loaded.Cratesloaded + 1
      else
        -- add troops back to stock
        if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) and droppingatbase then
          -- find right generic type
          local name = cargo:GetName()
          local gentroops = self.Cargo_Troops
          for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
            if _troop.Name == name then
              local stock = _troop:GetStock()
              -- avoid making unlimited stock limited
              if stock and tonumber(stock) >= 0 then
                _troop:AddStock()
                self:_RefreshTroopQuantityMenus(Group, Unit, _troop)
              end
            end
          end
        end
      end
    end
    self.Loaded_Cargo[unitname] = nil
    self.Loaded_Cargo[unitname] = loaded
    self:_RefreshDropTroopsMenu(Group,Unit)
    self:_UpdateUnitCargoMass(Unit)
    self:_RefreshTroopQuantityMenus(Group, Unit, nil)
  else
   if IsHerc then
    self:_SendMessage("Nothing loaded or not within airdrop parameters!", 10, false, Group) 
   else
    self:_SendMessage("Nothing loaded or not hovering within parameters!", 10, false, Group) 
   end
  end
  return self
end

--- (Internal) Function to unload crates from heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
function CTLD:_UnloadCrates(Group, Unit)
    self:T(self.lid .. " _UnloadCrates")
    
    if not self.dropcratesanywhere then -- #1570
      local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.DROP)
      if not inzone then
        self:_SendMessage("You are not close enough to a drop zone!", 10, false, Group) 
        if not self.debug then 
          return self 
        end
      end
    end
    if self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
      self:_SendMessage("You need to open the door(s) to drop cargo!", 10, false, Group)
      if not self.debug then return self end 
    end
    local hoverunload = self:IsCorrectHover(Unit)
    local IsHerc = self:IsFixedWing(Unit)
    local IsHook = self:IsHook(Unit)
    if IsHerc and (not IsHook) then
      hoverunload = self:IsCorrectFlightParameters(Unit)
    end
    local grounded = not self:IsUnitInAir(Unit)
    local unitname = Unit:GetName()
    if self.Loaded_Cargo[unitname] and (grounded or hoverunload) then
      local loadedcargo = self.Loaded_Cargo[unitname] or {}
      local cargotable = loadedcargo.Cargo
      local droppedCount = {}
      local neededMap = {}
      for _,_cargo in pairs (cargotable) do
        local cargo = _cargo
        local type = cargo:GetType()
        if type ~= CTLD_CARGO.Enum.TROOPS and type ~= CTLD_CARGO.Enum.ENGINEERS and type ~= CTLD_CARGO.Enum.GCLOADABLE and (not cargo:WasDropped() or self.allowcratepickupagain) then
          self:_GetCrates(Group, Unit, cargo, 1, true)
          cargo:SetWasDropped(true)
          cargo:SetHasMoved(true)
          local cname = cargo:GetName() or "Unknown"
          droppedCount[cname] = (droppedCount[cname] or 0) + 1
          if not neededMap[cname] then
            neededMap[cname] = cargo:GetCratesNeeded() or 1
          end
        end
      end
      for cname,count in pairs(droppedCount) do
        local needed = neededMap[cname] or 1
        if needed > 1 then
          local full = math.floor(count/needed)
          local left = count % needed
          if full > 0 and left == 0 then
            self:_SendMessage(string.format("Dropped %d %s.",full,cname),10,false,Group)
          elseif full > 0 and left > 0 then
            self:_SendMessage(string.format("Dropped %d %s(s), with %d leftover crate(s).",full,cname,left),10,false,Group)
          else
            self:_SendMessage(string.format("Dropped %d/%d crate(s) of %s.",count,needed,cname),15,false,Group)
          end
        else
          self:_SendMessage(string.format("Dropped %d %s(s).",count,cname),10,false,Group)
        end
      end
      local loaded = {}
      loaded.Troopsloaded = 0
      loaded.Cratesloaded = 0
      loaded.Cargo = {}
      for _,_cargo in pairs (cargotable) do
        local cargo = _cargo
        local type = cargo:GetType()
        local size = cargo:GetCratesNeeded()
        if type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS then
          table.insert(loaded.Cargo,_cargo)
          loaded.Troopsloaded = loaded.Troopsloaded + size
        end
        if type == CTLD_CARGO.Enum.GCLOADABLE and not cargo:WasDropped() then
          table.insert(loaded.Cargo,_cargo)
          loaded.Cratesloaded = loaded.Cratesloaded + size
        end
      end
      self.Loaded_Cargo[unitname] = nil
      self.Loaded_Cargo[unitname] = loaded
      
      self:_UpdateUnitCargoMass(Unit)
      self:_RefreshDropCratesMenu(Group,Unit)
      self:_RefreshCrateQuantityMenus(Group, Unit, nil)
    else
      if IsHerc then
          self:_SendMessage("Nothing loaded or not within airdrop parameters!", 10, false, Group) 
      else
          self:_SendMessage("Nothing loaded or not hovering within parameters!", 10, false, Group) 
       end
    end
    return self
  end

--- (User) Hook to allow mission-specific build restrictions.
-- Override this in your mission to perform custom checks (e.g. warehouse/credits rules) before crates are built.
-- Return `true` to allow the build, or `false` to block it. When blocked, `_BuildCrates` exits silently.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group Requesting player group.
-- @param Wrapper.Unit#UNIT Unit Requesting unit.
-- @param #table crates Table of nearby crate cargo objects returned by `_FindCratesNearby`.
-- @param #number number Number of nearby crates.
-- @param #boolean Engineering If true build is by an engineering team.
-- @param #boolean MultiDrop If true and not engineering or FOB, vary position a bit.
-- @return #boolean Allow building.
function CTLD:CanBuildCrates(Group, Unit, crates, number, Engineering, MultiDrop)
  return true
end

--- (Internal) Function to build nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #boolean Engineering If true build is by an engineering team.
-- @param #boolean MultiDrop If true and not engineering or FOB, vary position a bit.
function CTLD:_BuildCrates(Group, Unit,Engineering,MultiDrop)
  self:T(self.lid .. " _BuildCrates")
  -- avoid users trying to build from flying Hercs
  if self:IsFixedWing(Unit) and self.enableFixedWing and not Engineering then
    local speed = Unit:GetVelocityKMH()
    if speed > 1 then
      self:_SendMessage("You need to land / stop to build something, Pilot!", 10, false, Group) 
      return self
    end
  end
  if not Engineering and self.nobuildinloadzones then
    -- are we in a load zone?
    local inloadzone = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
    if inloadzone then
      self:_SendMessage("You cannot build in a loading area, Pilot!", 10, false, Group) 
      return self
    end
  end
  -- get nearby crates
  local baseDist = self.CrateDistance or 35
  local finddist=baseDist
  --if Engineering and self.EngineerSearch and self.EngineerSearch>baseDist then 
    if Engineering and self.EngineerSearch and self.EngineerSearch>baseDist then -- this make also helicopter to be able to crates that are further away due to herc airdrop
      finddist=self.EngineerSearch
  end
  local crates,number = self:_FindCratesNearby(Group,Unit,finddist,true,true,not Engineering) -- #table
  local buildables = {}
  local foundbuilds = false
  local canbuild = false

  if not self:CanBuildCrates(Group, Unit, crates, number, Engineering, MultiDrop) then
    return self
  end

  if number > 0 then
    -- get dropped crates
    for _,_crate in pairs(crates) do
      local Crate = _crate -- #CTLD_CARGO
      if (Crate:WasDropped() or not self.movecratesbeforebuild) and not Crate:IsRepair() and not Crate:IsStatic() then
        -- we can build these - maybe
        local name = Crate:GetName()
        local required = Crate:GetCratesNeeded()
        local template = Crate:GetTemplates()
        local ctype = Crate:GetType()
        local ccoord = Crate:GetPositionable():GetCoordinate() -- Core.Point#COORDINATE
        local distToUnit=Unit and ccoord:Get2DDistance(Unit:GetCoordinate())or 0
        local isHercDrop=Crate:WasDropped(true)
        if not isHercDrop and distToUnit>baseDist then
      elseif self.UseC130LoadAndUnload and self:IsC130J(Unit) and distToUnit<15 then
        -- self:_SendMessage("Please unload crates from the C-130 before building!",10,false,Group)
        -- return self
      elseif self.UseC130LoadAndUnload and self:IsHook(Unit) and distToUnit<5 then
        -- self:_SendMessage("Please unload crates from the CH-47 before building!",10,false,Group)
        -- return self
      elseif self.UseC130LoadAndUnload and (Unit:GetTypeName()=="Mi-8MTV2" or Unit:GetTypeName()=="Mi-8MT") and distToUnit<8 then
      else
        --local testmarker = ccoord:MarkToAll("Crate found",true,"Build Position")
        if not buildables[name] then
          local object = {} -- #CTLD.Buildable
          object.Name = name
          object.Required = required
          object.Found = 1
          object.Template = template
          object.CanBuild = false
          object.Type = ctype -- #CTLD_CARGO.Enum
          object.Coord = ccoord:GetVec2()
          buildables[name] = object
          foundbuilds = true
        else
         buildables[name].Found = buildables[name].Found + 1
         foundbuilds = true
        end
        if buildables[name].Found >= buildables[name].Required then 
           buildables[name].CanBuild = true
           canbuild = true
        end
        self:T({buildables = buildables})
      end  
      end -- end dropped
    end -- end crate loop
    -- ok let\'s list what we have
    local report = REPORT:New("Checklist Buildable Crates")
    report:Add("------------------------------------------------------------")
    for _,_build in pairs(buildables) do
      local build = _build -- Object table from above
      local name = build.Name
      local needed = build.Required
      local found = build.Found
      local txtok = "NO"
      if build.CanBuild then 
        txtok = "YES" 
      end
      local text = string.format("Type: %s | Required %d | Found %d | Can Build %s", name, needed, found, txtok)
      report:Add(text)
    end -- end list buildables
    if not foundbuilds then 
      report:Add("     --- None found! ---")
      if self.movecratesbeforebuild then
        report:Add("*** Crates need to be moved before building!")
      end
    end
    report:Add("------------------------------------------------------------")
    local text = report:Text()
    if not Engineering then
      self:_SendMessage(text, 30, true, Group) 
    else
      self:T(text)
    end
    -- let\'s get going
    if canbuild then
      local notified=false
      -- loop again
      for _,_build in pairs(buildables) do
        local build = _build -- #CTLD.Buildable
        if build.CanBuild then
          local required = build.Required or 1
          if required < 1 then required = 1 end
          local full = math.floor((build.Found or 0)/required)
          if full < 1 then full = 1 end

          local sep  = self.buildPairSeparation or 25
          local hdg  = (Unit:GetHeading()+180)%360
          local lat  = (hdg+90)%360
          local base = Unit:GetCoordinate():Translate(20,hdg)

          if full == 1 then
            local cratesNow, numberNow = self:_FindCratesNearby(Group,Unit, finddist,true,true, not Engineering)
            self:_CleanUpCrates(cratesNow,build,numberNow)
            self:_RefreshLoadCratesMenu(Group,Unit)
            if self.buildtime and self.buildtime > 0 then
              local buildtimer = TIMER:New(self._BuildObjectFromCrates,self,Group,Unit,build,false,Group:GetCoordinate(),MultiDrop)
              buildtimer:Start(self.buildtime)
              if not notified then
                self:_SendMessage(string.format("Build started, ready in %d seconds!",self.buildtime),15,false,Group)
                notified=true
              end
              self:__CratesBuildStarted(1,Group,Unit,build.Name)
            else
              self:_BuildObjectFromCrates(Group,Unit,build,false,nil,MultiDrop)
            end
          else
            local start = -((full-1)*sep)/2
            for n=1,full do
              local cratesNow, numberNow = self:_FindCratesNearby(Group,Unit, finddist,true,true, not Engineering)
              self:_CleanUpCrates(cratesNow,build,numberNow)
              self:_RefreshLoadCratesMenu(Group,Unit)
              local off   = start + (n-1)*sep
              local coord = base:Translate(off,lat):GetVec2()
              local b = { Name=build.Name, Required=build.Required, Template=build.Template, CanBuild=true, Type=build.Type, Coord=coord }
              if self.buildtime and self.buildtime > 0 then
                local buildtimer = TIMER:New(self._BuildObjectFromCrates,self,Group,Unit,b,false,Group:GetCoordinate(),MultiDrop)
                buildtimer:Start(self.buildtime)
                if not notified then
                  self:_SendMessage(string.format("Build started, ready in %d seconds!",self.buildtime),15,false,Group)
                  notified=true
                end
                self:__CratesBuildStarted(1,Group,Unit,build.Name)
              else
                self:_BuildObjectFromCrates(Group,Unit,b,false,nil,MultiDrop)
              end
            end
          end
        end
      end
    end

  else
    if not Engineering then self:_SendMessage(string.format("No crates within %d meters!",finddist), 10, false, Group) end
  end -- number > 0
  return self
end

--- (Internal) Function to repair nearby vehicles / FOBs
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit

function CTLD:_PackCratesNearby(Group, Unit)
  self:T(self.lid .. " _PackCratesNearby")
  -----------------------------------------
  -- search for nearest group to player
  -- determine if group is packable
  -- generate crates and destroy group
  -----------------------------------------

  -- get nearby vehicles
  local location = Group:GetCoordinate() -- get coordinate of group using function
  local nearestGroups = SET_GROUP:New():FilterCoalitions("blue"):FilterZones({ZONE_RADIUS:New("TempZone", location:GetVec2(), self.PackDistance, false)}):FilterOnce()

  local packedAny = false

  -- determine if group is packable
  for _, _Group in pairs(nearestGroups.Set) do -- convert #SET_GROUP to a list of Wrapper.Group#GROUP
    local didPackThisGroup = false
    for _, _Template in pairs(_DATABASE.Templates.Groups) do -- iterate through the database of templates
      if string.match(_Group:GetName(), _Template.GroupName) then -- check if the Wrapper.Group#GROUP near the player is in the list of templates by name
        for _, _entry in pairs(self.Cargo_Crates) do -- iterate through #CTLD_CARGO
          if _entry.Templates[1] == _Template.GroupName then -- check if the #CTLD_CARGO matches the template name
            _Group:Destroy()
            self:_GetCrates(Group, Unit, _entry, nil, false, true) -- spawn the appropriate crates near the player
            self:_RefreshLoadCratesMenu(Group,Unit) -- call the refresher to show the crates in the menu
            self:__CratesPacked(1,Group,Unit,_entry)
            packedAny = true
            didPackThisGroup = true
            break
          end
        end
      end
      if didPackThisGroup then break end
    end
  end

  if not packedAny then
    self:_SendMessage("Nothing to pack at this distance pilot!",10,false,Group)
    return false
  end

  return true
end

--- (Internal) Function to repair nearby vehicles / FOBs
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #boolean Engineering If true, this is an engineering role
function CTLD:_RepairCrates(Group, Unit, Engineering)
  self:T(self.lid .. " _RepairCrates")
  -- get nearby crates
  local finddist = self.CrateDistance or 35
  local crates,number = self:_FindCratesNearby(Group,Unit,finddist,true,true) -- #table
  local buildables = {}
  local foundbuilds = false
  local canbuild = false
  if number > 0 then
    -- get dropped crates
    for _,_crate in pairs(crates) do
      local Crate = _crate -- #CTLD_CARGO
      if Crate:WasDropped() and Crate:IsRepair() and not Crate:IsStatic() then
        -- we can build these - maybe
        local name = Crate:GetName()
        local required = Crate:GetCratesNeeded()
        local template = Crate:GetTemplates()
        local ctype = Crate:GetType()
        if not buildables[name] then
          local object = {} -- #CTLD.Buildable
          object.Name = name
          object.Required = required
          object.Found = 1
          object.Template = template
          object.CanBuild = false
          object.Type = ctype -- #CTLD_CARGO.Enum
          buildables[name] = object
          foundbuilds = true
        else
         buildables[name].Found = buildables[name].Found + 1
         foundbuilds = true
        end
        if buildables[name].Found >= buildables[name].Required then 
           buildables[name].CanBuild = true
           canbuild = true
        end
        self:T({repair = buildables})
      end -- end dropped
    end -- end crate loop
    -- ok let\'s list what we have
    local report = REPORT:New("Checklist Repairs")
    report:Add("------------------------------------------------------------")
    for _,_build in pairs(buildables) do
      local build = _build -- Object table from above
      local name = build.Name
      local needed = build.Required
      local found = build.Found
      local txtok = "NO"
      if build.CanBuild then 
        txtok = "YES" 
      end
      local text = string.format("Type: %s | Required %d | Found %d | Can Repair %s", name, needed, found, txtok)
      report:Add(text)
    end -- end list buildables
    if not foundbuilds then report:Add("     --- None Found ---") end
    report:Add("------------------------------------------------------------")
    local text = report:Text()
    if not Engineering then
      self:_SendMessage(text, 30, true, Group) 
    else
      self:T(text)
    end
    -- let\'s get going
    if canbuild then
      -- loop again
      for _,_build in pairs(buildables) do
        local build = _build -- #CTLD.Buildable
        if build.CanBuild then
          self:_RepairObjectFromCrates(Group,Unit,crates,build,number,Engineering)
        end
      end
    end
  else
    if not Engineering then self:_SendMessage(string.format("No crates within %d meters!",finddist), 10, false, Group) end 
  end -- number > 0
  return self
end

--- (Internal) Function to actually SPAWN buildables in the mission.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Group#UNIT Unit
-- @param #CTLD.Buildable Build
-- @param #boolean Repair If true this is a repair and not a new build
-- @param Core.Point#COORDINATE RepairLocation Location for repair (e.g. where the destroyed unit was)
-- @param #boolean MultiDrop if true and not a repair, vary location a bit if not a FOB
function CTLD:_BuildObjectFromCrates(Group,Unit,Build,Repair,RepairLocation,MultiDrop)
  self:T(self.lid .. " _BuildObjectFromCrates")
  -- Spawn-a-crate-content
  if Group and Group:IsAlive() or (RepairLocation and not Repair) then
    --local position = Unit:GetCoordinate() or Group:GetCoordinate()
    --local unitname = Unit:GetName() or Group:GetName() or "Unknown"
    local name = Build.Name
    local ctype = Build.Type -- #CTLD_CARGO.Enum
    local canmove = false
    if ctype == CTLD_CARGO.Enum.VEHICLE then canmove = true end
    if ctype == CTLD_CARGO.Enum.STATIC then 
      return self 
    end
    local temptable = Build.Template or {}
    if type(temptable) == "string" then 
      temptable = {temptable}
    end
    local zone = nil -- Core.Zone#ZONE_RADIUS
    if RepairLocation and not Repair then
      -- timed build
      zone = ZONE_RADIUS:New(string.format("Build zone-%d",math.random(1,10000)),RepairLocation:GetVec2(),100)
    else
      zone = ZONE_GROUP:New(string.format("Unload zone-%d",math.random(1,10000)),Group,100)
    end
    --local randomcoord = zone:GetRandomCoordinate(35):GetVec2()
    local randomcoord = Build.Coord or zone:GetRandomCoordinate(35):GetVec2()
    if MultiDrop and (not Repair) and canmove then
      -- coordinate may be the same, avoid
      local randomcoord = zone:GetRandomCoordinate(35):GetVec2()
    end
    if Repair then
      randomcoord = RepairLocation:GetVec2()
    end
    for _,_template in pairs(temptable) do
      self.TroopCounter = self.TroopCounter + 1
      local alias = string.format("%s-%d", _template, math.random(1,100000))
      if canmove then
        self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
          --:InitRandomizeUnits(true,20,2)
          :InitDelayOff()
          :InitValidateAndRepositionGroundUnits(self.validateAndRepositionUnits)
          :OnSpawnGroup(function(grp) grp.spawntime = timer.getTime() end)
          :SpawnFromVec2(randomcoord)
      else -- don't random position of e.g. SAM units build as FOB
        self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
          :InitDelayOff()
          :InitValidateAndRepositionGroundUnits(self.validateAndRepositionUnits)
          :OnSpawnGroup(function(grp) grp.spawntime = timer.getTime() end)
          :SpawnFromVec2(randomcoord)
      end
      if Repair then
        self:__CratesRepaired(1,Group,Unit,self.DroppedTroops[self.TroopCounter])
      else
        self:__CratesBuild(1,Group,Unit,self.DroppedTroops[self.TroopCounter])
      end
    end -- template loop
  else
    self:T(self.lid.."Group KIA while building!")
  end
  return self
end

--- (Internal) Function to get a vehicle formation for a moving group
-- @param #CTLD self
-- @return #string Formation
function CTLD:_GetVehicleFormation()
  local VehicleMoveFormation = self.VehicleMoveFormation or AI.Task.VehicleFormation.VEE
  if type(self.VehicleMoveFormation)=="table" then
    VehicleMoveFormation = self.VehicleMoveFormation[math.random(1,#self.VehicleMoveFormation)]
  end
  return VehicleMoveFormation
end

--- (Internal) Function to move group to WP zone.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group The Group to move.
function CTLD:_MoveGroupToZone(Group)
  self:T(self.lid .. " _MoveGroupToZone")
  local groupname = Group:GetName() or "none"
  local groupcoord = Group:GetCoordinate()
  -- Get closest zone of type
  local outcome, name, zone, distance  = self:IsUnitInZone(Group,CTLD.CargoZoneType.MOVE)
  self:T({canmove=outcome, name=name, zone=zone, dist=distance,max=self.movetroopsdistance})
  if (distance <= self.movetroopsdistance) and outcome == true and zone~= nil then
    -- yes, we can ;)
    local groupname = Group:GetName()
    local zonecoord = zone:GetRandomCoordinate(20,125) -- Core.Point#COORDINATE
    local formation = self:_GetVehicleFormation()
    --local coordinate = zonecoord:GetVec2()
    Group:SetAIOn()
    Group:OptionAlarmStateAuto()
    Group:OptionDisperseOnAttack(30)
    Group:OptionROEOpenFire()
    Group:RouteGroundTo(zonecoord,25,formation)
    end
  return self
end

--- (Internal) Housekeeping - Cleanup crates when build
-- @param #CTLD self
-- @param #table Crates Table of #CTLD_CARGO objects near the unit.
-- @param #CTLD.Buildable Build Table build object.
-- @param #number Number Number of objects in Crates (found) to limit search.
function CTLD:_CleanUpCrates(Crates,Build,Number)
  self:T(self.lid .. " _CleanUpCrates")
  -- clean up real world crates
  local build = Build -- #CTLD.Buildable
  local existingcrates = self.Spawned_Cargo -- #table of exising crates
  local newexcrates = {}
  -- get right number of crates to destroy
  local numberdest = Build.Required
  local nametype = Build.Name
  local found = 0
  local rounds = Number
  local destIDs = {}
  
  -- loop and find matching IDs in the set
  for _,_crate in pairs(Crates) do
    local nowcrate = _crate -- #CTLD_CARGO
    local name = nowcrate:GetName()
    local thisID = nowcrate:GetID()
    if name == nametype then -- matching crate type
      table.insert(destIDs,thisID)
      found = found + 1
      local pos = nowcrate:GetPositionable()
      if pos then pos:Destroy(false) end
      nowcrate.Positionable = nil
      nowcrate.HasBeenDropped = false
    end
    if found == numberdest then break end -- got enough
  end
  -- loop and remove from real world representation
  self:_CleanupTrackedCrates(destIDs)
  return self
end

--- (Internal) Helper - Drop **all** loaded crates nearby and build them.
-- @param Wrapper.Group#GROUP Group The calling group
-- @param Wrapper.Unit#UNIT  Unit  The calling unit
function CTLD:_DropAndBuild(Group,Unit)
    if self.nobuildinloadzones then
      if self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD) then
        self:_SendMessage("You cannot build in a loading area, Pilot!",10,false,Group)
        return self
      end
    end
    self:_UnloadCrates(Group,Unit)
    timer.scheduleFunction(function() self:_BuildCrates(Group,Unit,false,true) end,{},timer.getTime()+1)
  end
  
  --- (Internal) Helper - Drop a **single** crate set and build it.
-- @param Wrapper.Group#GROUP Group     The calling group
-- @param Wrapper.Unit#UNIT  Unit       The calling unit
-- @param number             setIndex   Index of the crate-set to drop
  function CTLD:_DropSingleAndBuild(Group,Unit,setIndex)
    if self.nobuildinloadzones then
      if self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD) then
        self:_SendMessage("You cannot build in a loading area, Pilot!",10,false,Group)
        return self
      end
    end
    self:_UnloadSingleCrateSet(Group,Unit,setIndex)
    timer.scheduleFunction(function() self:_BuildCrates(Group,Unit,false) end,{},timer.getTime()+1)
  end

--- (Internal) Helper - Pack crates near the unit and load them.
-- @param Wrapper.Group#GROUP Group  The calling group
-- @param Wrapper.Unit#UNIT  Unit    The calling unit
function CTLD:_PackAndLoad(Group,Unit)
    if self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
      self:_SendMessage("You need to open the door(s) to load cargo!",10,false,Group)
      return self
    end
    if not self:_PackCratesNearby(Group,Unit) then
        return self
      end
    timer.scheduleFunction(function() self:_LoadCratesNearby(Group,Unit) end,{},timer.getTime()+1)
    return self
  end

--- (Internal) Helper - Pack crates near the unit and then remove them.
-- @param Wrapper.Group#GROUP Group  The calling group
-- @param Wrapper.Unit#UNIT  Unit    The calling unit
function CTLD:_PackAndRemove(Group,Unit)
    if not self:_PackCratesNearby(Group,Unit) then
        return self
      end
        timer.scheduleFunction(function() self:_RemoveCratesNearby(Group,Unit) end,{},timer.getTime()+1)
    return self
end

--- (Internal) Helper - get and load in one step
-- @param Wrapper.Group#GROUP Group  The calling group
-- @param Wrapper.Unit#UNIT  Unit    The calling unit
-- @param #CTLD_CARGO cargoObj
-- @param #number quantity
function CTLD:_GetAndLoad(Group, Unit, cargoObj, quantity, LoadAnyWay)
  if self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
    self:_SendMessage("You need to open the door(s) to load cargo!", 10, false, Group)
    return self
  end
  local needed = cargoObj and cargoObj:GetCratesNeeded() or 1
  local count = math.max(1, tonumber(quantity) or 1)
  local capacitySets = nil
  local cap = self:_GetUnitCapabilities(Unit)
  local limit = cap and cap.cratelimit or 0
  if limit > 0 then
    local ld = self.Loaded_Cargo and self.Loaded_Cargo[Unit:GetName()] or nil
    local loaded = (ld and type(ld.Cratesloaded) == "number") and ld.Cratesloaded or 0
    local space = limit - loaded
    if space < 0 then space = 0 end
    local perSet = needed > 0 and needed or 1
    capacitySets = math.floor(space / perSet)
    if capacitySets < 1 and not LoadAnyWay then
      self:_SendMessage("No capacity to load more now!", 10, false, Group)
      return self
    end
    if capacitySets < 1 and LoadAnyWay then
      count = 1
    elseif count > capacitySets then
      count = capacitySets
    end
  end
  local inzone = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
  if not inzone then
    local ship = nil
    local width = 20
    local distance = nil
    local zone = nil
    inzone, ship, zone, distance, width  = self:IsUnitInZone(Unit,CTLD.CargoZoneType.SHIP)
  end
  if not inzone then
    self:_SendMessage("You are not close enough to a logistics zone!", 10, false, Group)
    return self
  end
  local total = needed * count
  local ok = self:_GetCrates(Group, Unit, cargoObj, total, false, false, true, true)
  if ok then
    local uname = Unit:GetName()
    self._batchCrateLoad = self._batchCrateLoad or {}
    self._batchCrateLoad[uname] = { remaining = count, group = Group, cname = cargoObj.Name, loaded = 0, partials = 0 }
    local details = (LoadAnyWay == true)
    for i = 1, count do
      timer.scheduleFunction(function() self:_LoadSingleCrateSet(Group, Unit, cargoObj.Name, details) end, {}, timer.getTime() + 0.2 * i)
    end
  end
  return self
end

-- @param Wrapper.Group#GROUP Group The player’s group that triggered the action
-- @param Wrapper.Unit#UNIT  Unit The unit performing the pack-and-load  
function CTLD:_GetAllAndLoad(Group,Unit)
    if self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
        self:_SendMessage("You need to open the door(s) to load cargo!",10,false,Group)
        return self
    end

    timer.scheduleFunction(function() self:_LoadCratesNearby(Group,Unit) end,{},timer.getTime()+1)
end
--- (Internal) Function to get crate stock table entry.
-- @param #CTLD self
-- @param #CTLD_CARGO cargoObj Cargo object.
-- @param #table stockSummary Stock summary table.
-- @return #table Stock entry or nil.
function CTLD:_GetCrateStockEntry(cargoObj, stockSummary)
  if not cargoObj or not stockSummary then
    return nil
  end
  local name = cargoObj:GetName()
  if not name then
    return nil
  end
  return stockSummary[name]
end

--- (Internal) Function to format crate stock suffix for menu text.
-- @param #CTLD self
-- @param #CTLD_CARGO cargoObj Cargo object.
-- @param #table stockSummary Stock summary table.
-- @return #string Formatted suffix like "[3]" or "[3/10]" or nil.
function CTLD:_FormatCrateStockSuffix(cargoObj, stockSummary)
  if not cargoObj then
    return nil
  end
  local stockEntry = self:_GetCrateStockEntry(cargoObj, stockSummary)
  local available = nil
  if stockEntry and type(stockEntry.Stock) == "number" then
    available = stockEntry.Stock
  end
  if type(available) ~= "number" then
    local direct = cargoObj:GetStock()
    if type(direct) == "number" then
      available = direct
    end
  end
  if type(available) ~= "number" or available < 0 then
    return nil
  end
  local rounded = math.floor(available + 0.5)
  local total = nil
  if stockEntry and type(stockEntry.Stock0) == "number" and stockEntry.Stock0 >= 0 then
    total = math.floor(stockEntry.Stock0 + 0.5)
  elseif stockEntry and type(stockEntry.Sum) == "number" and stockEntry.Sum >= 0 then
    total = math.floor(stockEntry.Sum + 0.5)
  end
  if type(total) ~= "number" then
    local baseTotal = cargoObj.GetStock0 and cargoObj:GetStock0() or nil
    if type(baseTotal) == "number" and baseTotal >= 0 then
      total = math.floor(baseTotal + 0.5)
    end
  end
  if type(total) == "number" and total > 0 and total ~= rounded then
    return string.format("[%d/%d]", rounded, total)
  else
    return string.format("[%d]", rounded)
  end
end

--- (Internal) Function to refresh quantity submenus for crates for a single player group.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD_CARGO CargoObj Optional; if given and stock < maxCrateMenuQuantity, do global rebuild.
-- @return #CTLD self
function CTLD:_RefreshCrateQuantityMenus(Group, Unit, CargoObj)
  if not Group and Unit then Group = Unit:GetGroup() end
  if Group and Unit then
    local uname = Unit:GetName() or "none"
    self._qtySnap = self._qtySnap or {}
    self._qtySnap[uname] = self._qtySnap[uname] or {}
    if Group.CTLD_CrateMenus then
      local present = {}
      for item,_ in pairs(Group.CTLD_CrateMenus) do present["C:"..tostring(item)] = true end
      for key,_ in pairs(self._qtySnap[uname]) do
        if string.sub(key,1,2)=="C:" and not present[key] then
          self._qtySnap[uname][key] = nil
        end
      end
      local stockSummary = self.showstockinmenuitems and self:_CountStockPlusInHeloPlusAliveGroups(false) or nil
      for item, menu in pairs(Group.CTLD_CrateMenus) do
        menu:RemoveSubMenus()
        local obj = self:_FindCratesCargoObject(item)
        if obj then self:_AddCrateQuantityMenus(Group, Unit, menu, obj, stockSummary) end
      end
    end
  end
  if CargoObj and Group and Unit then
    local uname = Unit:GetName() or "none"
    local cap = (self:_GetUnitCapabilities(Unit).cratelimit or 0)
    local loaded = (self.Loaded_Cargo[uname] and self.Loaded_Cargo[uname].Cratesloaded) or 0
    local avail = math.max(0, cap - loaded)
    local per = CargoObj:GetCratesNeeded() or 1
    if per < 1 then per = 1 end
    local unitAvail = math.max(0, math.min(self.maxCrateMenuQuantity or 1, math.floor(avail/per)))
    local s = CargoObj:GetStock()
    self._qtySnap = self._qtySnap or {}
    self._qtySnap[uname] = self._qtySnap[uname] or {}
    local k = "C:"..(CargoObj:GetName() or "none")
    local snap = tostring(type(s)=="number" and s or -1)..":"..tostring(unitAvail)
    if self._qtySnap[uname][k] ~= snap then
      self._qtySnap[uname][k] = snap
      if type(s)=="number" and s>=0 and s<unitAvail then
        self:_RefreshQuantityMenusForGroup(Group, Unit)
      end
    end
  end
  return self
end

--- (Internal) Function to refresh quantity submenus for troops for a single player group.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD_CARGO CargoObj Optional; if given and stock < maxCrateMenuQuantity, do global rebuild.
-- @return #CTLD self
function CTLD:_RefreshTroopQuantityMenus(Group, Unit, CargoObj)
  if not Group and Unit then Group = Unit:GetGroup() end
  if Group and Unit then
    local uname = Unit:GetName() or "none"
    self._qtySnap = self._qtySnap or {}
    self._qtySnap[uname] = self._qtySnap[uname] or {}
    if Group.CTLD_TroopMenus then
      local present = {}
      for item,_ in pairs(Group.CTLD_TroopMenus) do present["T:"..tostring(item)] = true end
      for key,_ in pairs(self._qtySnap[uname]) do
        if string.sub(key,1,2)=="T:" and not present[key] then
          self._qtySnap[uname][key] = nil
        end
      end
      for item, menu in pairs(Group.CTLD_TroopMenus) do
        menu:RemoveSubMenus()
        local obj = self:_FindTroopsCargoObject(item)
        if obj then self:_AddTroopQuantityMenus(Group, Unit, menu, obj) end
      end
    end
  end
  if CargoObj and Group and Unit then
    local uname = Unit:GetName() or "none"
    local cap = (self:_GetUnitCapabilities(Unit).trooplimit or 0)
    local loaded = (self.Loaded_Cargo[uname] and self.Loaded_Cargo[uname].Troopsloaded) or 0
    local avail = math.max(0, cap - loaded)
    local per = CargoObj:GetCratesNeeded() or 1
    if per < 1 then per = 1 end
    local unitAvail = math.max(0, math.min(self.maxCrateMenuQuantity or 1, math.floor(avail/per)))
    local s = CargoObj:GetStock()
    self._qtySnap = self._qtySnap or {}
    self._qtySnap[uname] = self._qtySnap[uname] or {}
    local k = "T:"..(CargoObj:GetName() or "none")
    local snap = tostring(type(s)=="number" and s or -1)..":"..tostring(unitAvail)
    if self._qtySnap[uname][k] ~= snap then
      self._qtySnap[uname][k] = snap
      if type(s)=="number" and s>=0 and s<unitAvail then
        self:_RefreshQuantityMenusForGroup(Group, Unit)
      end
    end
  end
  return self
end

--- (Internal) Function to refresh quantity submenus for Troops and Crates.
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD self
-- @return #CTLD self
function CTLD:_RefreshQuantityMenusForGroup(_group, _unit)
  if _group and _unit then
    local stockSummary = self.showstockinmenuitems and self:_CountStockPlusInHeloPlusAliveGroups(false) or nil
    if _group.CTLD_CrateMenus then
      for item, menu in pairs(_group.CTLD_CrateMenus) do
        if menu and menu.RemoveSubMenus then
          menu:RemoveSubMenus()
          local obj = self:_FindCratesCargoObject(item)
          if obj then self:_AddCrateQuantityMenus(_group, _unit, menu, obj, stockSummary) end
        end
      end
    end
    if _group.CTLD_TroopMenus then
      for item, menu in pairs(_group.CTLD_TroopMenus) do
        if menu and menu.RemoveSubMenus then
          menu:RemoveSubMenus()
          local obj = self:_FindTroopsCargoObject(item)
          if obj then self:_AddTroopQuantityMenus(_group, _unit, menu, obj) end
        end
      end
    end
    return self
  end

    self._qtySnap=self._qtySnap or {}
    for uname,_ in pairs(self._qtySnap) do
      if not (self.CtldUnits and self.CtldUnits[uname]) then
        self._qtySnap[uname]=nil
      end
    end

    for name,_ in pairs(self.CtldUnits or {}) do
    local u = UNIT:FindByName(name) or CLIENT:FindByName(name)
    if u and u:IsAlive() then
      local g = u:GetGroup()
      if g then
        local caps = self:_GetUnitCapabilities(u)
        local needCrate, needTroop = false, false

        if g.CTLD_CrateMenus then
          local cap = caps.cratelimit or 0
          for item,_ in pairs(g.CTLD_CrateMenus) do
            local obj = self:_FindCratesCargoObject(item)
            if obj then
              local per = obj:GetCratesNeeded() or 1
              if per < 1 then per = 1 end
              local uname = u:GetName() or "none"
              local cap = caps.cratelimit or 0
              local loaded = (self.Loaded_Cargo[uname] and self.Loaded_Cargo[uname].Cratesloaded) or 0
              local avail = math.max(0, cap - loaded)
              local unitAvail = math.max(0, math.min(self.maxCrateMenuQuantity or 1, math.floor(avail/per)))
              local s = obj:GetStock()
              if type(s)=="number" and s>=0 and s<unitAvail then needCrate = true break end
            end
          end
        end

        if g.CTLD_TroopMenus then
          local cap = caps.trooplimit or 0
          for item,_ in pairs(g.CTLD_TroopMenus) do
            local obj = self:_FindTroopsCargoObject(item)
            if obj then
              local per = obj:GetCratesNeeded() or 1
              if per < 1 then per = 1 end
              local uname = u:GetName() or "none"
              local cap = caps.trooplimit or 0
              local loaded = (self.Loaded_Cargo[uname] and self.Loaded_Cargo[uname].Troopsloaded) or 0
              local avail = math.max(0, cap - loaded)
              local unitAvail = math.max(0, math.min(self.maxCrateMenuQuantity or 1, math.floor(avail/per)))
              local s = obj:GetStock()
              if type(s)=="number" and s>=0 and s<unitAvail then needTroop = true break end
            end
          end
        end

        if needCrate or needTroop then
          local stockSummary = self.showstockinmenuitems and self:_CountStockPlusInHeloPlusAliveGroups(false) or nil
          if needCrate and g.CTLD_CrateMenus then
            for item,menu in pairs(g.CTLD_CrateMenus) do
              if menu and menu.RemoveSubMenus then
                menu:RemoveSubMenus()
                local obj = self:_FindCratesCargoObject(item)
                if obj then self:_AddCrateQuantityMenus(g, u, menu, obj, stockSummary) end
              end
            end
          end
          if needTroop and g.CTLD_TroopMenus then
            for item,menu in pairs(g.CTLD_TroopMenus) do
              if menu and menu.RemoveSubMenus then
                menu:RemoveSubMenus()
                local obj = self:_FindTroopsCargoObject(item)
                if obj then self:_AddTroopQuantityMenus(g, u, menu, obj) end
              end
            end
          end
        end
      end
    end
  end
  return self
end
--- (Internal) Housekeeping - Function to refresh F10 menus.
-- @param #CTLD self
-- @return #CTLD self
function CTLD:_RefreshF10Menus()
    self:T(self.lid .. " _RefreshF10Menus")
    self.onestepmenu = self.onestepmenu or false -- hybrid toggle (default = false)
  
    -- 1) Gather all the pilot groups from our Set
    local PlayerSet   = self.PilotGroups
    local PlayerTable = PlayerSet:GetSetObjects()
  
    -- 2) Rebuild the self.CtldUnits table
    local _UnitList = {}
    for _, groupObj in pairs(PlayerTable) do
      local firstUnit = groupObj:GetFirstUnitAlive()
      if firstUnit then
        if firstUnit:IsPlayer() then
          if firstUnit:IsHelicopter() or (self.enableFixedWing and self:IsFixedWing(firstUnit)) then
            local _unit = firstUnit:GetName()
            _UnitList[_unit] = _unit
          end
        end
      end
    end
    
    -- 3) CA Units
    if self.allowCATransport and self.CATransportSet then
      for _,_clientobj in pairs(self.CATransportSet.Set) do
        local client = _clientobj -- Wrapper.Client#CLIENT
        if client:IsGround() then
          local cname = client:GetName()
          self:T(self.lid.."Adding: "..cname)
          _UnitList[cname] = cname
        end
      end
    end
    
    self.CtldUnits = _UnitList
  
    -- subcats?
    if self.usesubcats then
     for _id,_cargo in pairs(self.Cargo_Crates) do
      local entry = _cargo -- #CTLD_CARGO
      if not self.subcats[entry.Subcategory] then
        self.subcats[entry.Subcategory] = entry.Subcategory
      end
     end
     for _id,_cargo in pairs(self.Cargo_Statics) do
      local entry = _cargo -- #CTLD_CARGO
      if not self.subcats[entry.Subcategory] then
        self.subcats[entry.Subcategory] = entry.Subcategory
      end
     end
     for _id,_cargo in pairs(self.Cargo_Troops) do
      local entry = _cargo -- #CTLD_CARGO
      if not self.subcatsTroop[entry.Subcategory] then
        self.subcatsTroop[entry.Subcategory] = entry.Subcategory
      end
     end
    end
  
    local menucount = 0
    local menus = {}
    for _, _unitName in pairs(self.CtldUnits) do
      if (not self.MenusDone[_unitName]) or (self.showstockinmenuitems == true) then
        self:T(self.lid.."Menu not done yet for ".._unitName)
        local firstBuild = not self.MenusDone[_unitName]
        local _unit  = UNIT:FindByName(_unitName)
        if not _unit and self.allowCATransport then
          _unit = CLIENT:FindByName(_unitName)
        end
        if _unit and _unit:IsAlive() then
          local _group = _unit:GetGroup()
          if _group then
            self:T(self.lid.."Unit and Group exist")
            local capabilities = self:_GetUnitCapabilities(_unit)
            local cantroops  = capabilities.troops
            local cancrates  = capabilities.crates
            local unittype   = _unit:GetTypeName()
            local isHook     = self:IsHook(_unit)
            local nohookswitch = true
            --local nohookswitch = not (isHook and self.enableChinookGCLoading)
            -- Clear old topmenu if it existed
            if _group.CTLDTopmenu then
              _group.CTLDTopmenu:Remove()
              _group.CTLDTopmenu = nil
            end
            local toptroops = nil
            local topcrates = nil
            local topmenu = MENU_GROUP:New(_group, "CTLD", nil)
            _group.CTLDTopmenu = topmenu
  
            if cantroops then
              local toptroops  = MENU_GROUP:New(_group, "Manage Troops", topmenu)
              local troopsmenu = MENU_GROUP:New(_group, "Load troops", toptroops)
              _group.MyTopTroopsMenu = toptroops
              
              _group.CTLD_TroopMenus = {}
              if self.usesubcats then
                local subcatmenus = {}
                local subcatcount = 0
                local onlycat = nil
                for catName, _ in pairs(self.subcatsTroop) do
                  subcatcount = subcatcount + 1
                  onlycat = catName
                end
                local useTroopSubcats = subcatcount > 1 or (subcatcount == 1 and onlycat ~= "Other")
                if useTroopSubcats then
                  for catName, _ in pairs(self.subcatsTroop) do
                    subcatmenus[catName] = MENU_GROUP:New(_group, catName, troopsmenu)
                  end
                end
                for _, cargoObj in pairs(self.Cargo_Troops) do
                  if not cargoObj.DontShowInMenu then
                    local menutext = self:_GetCargoDisplayName(cargoObj)
                    local parent = troopsmenu
                    if useTroopSubcats and cargoObj.Subcategory and subcatmenus[cargoObj.Subcategory] then
                      parent = subcatmenus[cargoObj.Subcategory]
                    end
                    local mSet = MENU_GROUP:New(_group, menutext, parent)
                    _group.CTLD_TroopMenus[cargoObj.Name] = mSet
                    self:_AddTroopQuantityMenus(_group,_unit,mSet,cargoObj)
                  end
                end
              else
                for _, cargoObj in pairs(self.Cargo_Troops) do
                  if not cargoObj.DontShowInMenu then
                    local menutext = self:_GetCargoDisplayName(cargoObj)
                    local mSet = MENU_GROUP:New(_group, menutext, troopsmenu)
                    _group.CTLD_TroopMenus[cargoObj.Name] = mSet
                    self:_AddTroopQuantityMenus(_group,_unit,mSet,cargoObj)
                  end
                end
              end
              local dropTroopsMenu=MENU_GROUP:New(_group,"Drop Troops",toptroops):Refresh()
              MENU_GROUP_COMMAND:New(_group,"Drop ALL troops",dropTroopsMenu,self._UnloadTroops,self,_group,_unit):Refresh()
              MENU_GROUP_COMMAND:New(_group,"Extract troops",toptroops,self._ExtractTroops,self,_group,_unit):Refresh()
              local uName=_unit:GetName()
              local loadedData=self.Loaded_Cargo[uName]
              if loadedData and loadedData.Cargo then
                for i,cargoObj in ipairs(loadedData.Cargo) do
                  if cargoObj and (cargoObj:GetType()==CTLD_CARGO.Enum.TROOPS or cargoObj:GetType()==CTLD_CARGO.Enum.ENGINEERS) and not cargoObj:WasDropped() then
                      local name=self:_GetCargoDisplayName(cargoObj)
                    local needed=cargoObj:GetCratesNeeded() or 1
                    local cID=cargoObj:GetID()
                    local line=string.format("Drop: %s",name,needed,cID)
                    MENU_GROUP_COMMAND:New(_group,line,dropTroopsMenu,self._UnloadSingleTroopByID,self,_group,_unit,cID):Refresh()
                  end
                end
              end
            end
            if cancrates then
              local topcrates  = MENU_GROUP:New(_group, "Manage Crates", topmenu)
              _group.MyTopCratesMenu = topcrates
  
              -- Build the “Get Crates” sub-menu items
              local cratesmenu = MENU_GROUP:New(_group,"Get Crates",topcrates)
  
              if self.onestepmenu then
                _group.CTLD_CrateMenus = {}

                local crateStockSummary = nil
                if self.showstockinmenuitems then
                  crateStockSummary = self:_CountStockPlusInHeloPlusAliveGroups(false)
                end

                local function addCrateMenuEntry(cargoObj,parentMenu,subcatmenus)
                  if cargoObj.DontShowInMenu then
                    return
                  end

                  local isStaticCargo = false
                  if (cargoObj.GetType and cargoObj:GetType() == CTLD_CARGO.Enum.STATIC) or cargoObj.CargoType == CTLD_CARGO.Enum.STATIC then
                    isStaticCargo = true
                  end

                  -- Only restrict CTLD menu visibility by unit type for STATIC cargo.
                  -- Crates/troops should remain visible "as-is" like before.
                  if isStaticCargo and cargoObj.UnitCanCarry and not cargoObj:UnitCanCarry(_unit) then
                    return
                  end

                  -- If sub-categories are enabled, create the sub-menu only when we actually add something to it.
                  local parent = parentMenu
                  if subcatmenus and cargoObj.Subcategory then
                    parent = subcatmenus[cargoObj.Subcategory]
                    if not parent then
                      parent = MENU_GROUP:New(_group, cargoObj.Subcategory, cratesmenu)
                      subcatmenus[cargoObj.Subcategory] = parent
                    end
                  end

                  local needed = cargoObj:GetCratesNeeded() or 1

                  local txt
                  local cargoLabel = self:_GetCargoDisplayName(cargoObj)
                  if needed > 1 then
                    txt = string.format("%d crate%s %s (%dkg)",needed,needed==1 and "" or "s",cargoLabel,cargoObj.PerCrateMass or 0)
                  else
                    txt = string.format("%s (%dkg)",cargoLabel,cargoObj.PerCrateMass or 0)
                  end
                  if cargoObj.Location then txt = txt.."[R]" end
                  if self.showstockinmenuitems then
                    local suffix = self:_FormatCrateStockSuffix(cargoObj,crateStockSummary)
                    if suffix then txt = txt..suffix end
                  end
                  local mSet = MENU_GROUP:New(_group,txt,parent)
                  _group.CTLD_CrateMenus[cargoObj.Name] = mSet
                  self:_AddCrateQuantityMenus(_group,_unit,mSet,cargoObj,crateStockSummary)
                end

                if self.usesubcats then
                  local subcatmenus = {}
    
    
   
                  for _,cargoObj in pairs(self.Cargo_Crates) do
                    addCrateMenuEntry(cargoObj,cratesmenu,subcatmenus)
                  end
                  for _,cargoObj in pairs(self.Cargo_Statics) do
                    addCrateMenuEntry(cargoObj,cratesmenu,subcatmenus)
                  end
                else
                  for _,cargoObj in pairs(self.Cargo_Crates) do
                    addCrateMenuEntry(cargoObj,cratesmenu)
                  end
                  for _,cargoObj in pairs(self.Cargo_Statics) do
                    addCrateMenuEntry(cargoObj,cratesmenu)
                  end
                end
              else
                if self.usesubcats == true then
                  local subcatmenus = {}
                  local function getSubcatMenu(catName)
                    if not catName then return cratesmenu end
                    if not subcatmenus[catName] then
                      subcatmenus[catName] = MENU_GROUP:New(_group, catName, cratesmenu)
                    end
                    return subcatmenus[catName]
                  end
                  for _, cargoObj in pairs(self.Cargo_Crates) do
                    if not cargoObj.DontShowInMenu then
                      local needed = cargoObj:GetCratesNeeded() or 1
                      local txt
                      local cargoLabel = self:_GetCargoDisplayName(cargoObj)
                      if needed > 1 then
                        txt = string.format("%d crate%s %s (%dkg)",needed,needed==1 and "" or "s",cargoLabel,cargoObj.PerCrateMass or 0)
                      else
                        txt = string.format("%s (%dkg)",cargoLabel,cargoObj.PerCrateMass or 0)
                      end
                      if cargoObj.Location then txt = txt.."[R]" end
                      local stock = cargoObj:GetStock()
                      if stock >= 0 and self.showstockinmenuitems then txt = txt.."["..stock.."]" end
                      MENU_GROUP_COMMAND:New(_group, txt, getSubcatMenu(cargoObj.Subcategory), self._GetCrates, self, _group, _unit, cargoObj)
                    end
                  end
                  for _, cargoObj in pairs(self.Cargo_Statics) do
                    if (not cargoObj.DontShowInMenu) and (not cargoObj.UnitCanCarry or cargoObj:UnitCanCarry(_unit)) then
                      local needed = cargoObj:GetCratesNeeded() or 1
                      local txt
                      local cargoLabel = self:_GetCargoDisplayName(cargoObj)
                      if needed > 1 then
                        txt = string.format("%d crate%s %s (%dkg)",needed,needed==1 and "" or "s",cargoLabel,cargoObj.PerCrateMass or 0)
                      else
                        txt = string.format("%s (%dkg)",cargoLabel,cargoObj.PerCrateMass or 0)
                      end
                      if cargoObj.Location then txt = txt.."[R]" end
                      local stock = cargoObj:GetStock()
                      if stock >= 0 and self.showstockinmenuitems then txt = txt.."["..stock.."]" end
                      MENU_GROUP_COMMAND:New(_group, txt, getSubcatMenu(cargoObj.Subcategory), self._GetCrates, self, _group, _unit, cargoObj)
                    end
                  end
                else
                  for _, cargoObj in pairs(self.Cargo_Crates) do
                    if not cargoObj.DontShowInMenu then
                      local needed = cargoObj:GetCratesNeeded() or 1
                      local txt
                      local cargoLabel = self:_GetCargoDisplayName(cargoObj)
                      if needed > 1 then
                        txt = string.format("%d crate%s %s (%dkg)",needed,needed==1 and "" or "s",cargoLabel,cargoObj.PerCrateMass or 0)
                      else
                        txt = string.format("%s (%dkg)",cargoLabel,cargoObj.PerCrateMass or 0)
                      end
                      if cargoObj.Location then txt = txt.."[R]" end
                      local stock = cargoObj:GetStock()
                      if stock >= 0 and self.showstockinmenuitems then txt = txt.."["..stock.."]" end
                      MENU_GROUP_COMMAND:New(_group, txt, cratesmenu, self._GetCrates, self, _group, _unit, cargoObj)
                    end
                  end
                  for _, cargoObj in pairs(self.Cargo_Statics) do
                    if (not cargoObj.DontShowInMenu) and (not cargoObj.UnitCanCarry or cargoObj:UnitCanCarry(_unit)) then
                      local needed = cargoObj:GetCratesNeeded() or 1
                      local txt
                      local cargoLabel = self:_GetCargoDisplayName(cargoObj)
                      if needed > 1 then
                        txt = string.format("%d crate%s %s (%dkg)",needed,needed==1 and "" or "s",cargoLabel,cargoObj.PerCrateMass or 0)
                      else
                        txt = string.format("%s (%dkg)",cargoLabel,cargoObj.PerCrateMass or 0)
                      end
                      if cargoObj.Location then txt = txt.."[R]" end
                      local stock = cargoObj:GetStock()
                      if stock >= 0 and self.showstockinmenuitems then txt = txt.."["..stock.."]" end
                      MENU_GROUP_COMMAND:New(_group, txt, cratesmenu, self._GetCrates, self, _group, _unit, cargoObj)
                    end
                  end
                end
              end
  
              local loadCratesMenu=MENU_GROUP:New(_group,"Load Crates",topcrates)
              _group.MyLoadCratesMenu=loadCratesMenu
              MENU_GROUP_COMMAND:New(_group,"Load ALL",loadCratesMenu,self._LoadCratesNearby,self,_group,_unit)
              MENU_GROUP_COMMAND:New(_group,"Show loadable crates",loadCratesMenu,self._RefreshLoadCratesMenu,self,_group,_unit)
  
              local dropCratesMenu = MENU_GROUP:New(_group,"Drop Crates",topcrates)
              topcrates.DropCratesMenu = dropCratesMenu
  
              if not self.nobuildmenu then
                MENU_GROUP_COMMAND:New(_group, "Build crates", topcrates, self._BuildCrates, self, _group, _unit)
                MENU_GROUP_COMMAND:New(_group, "Repair", topcrates, self._RepairCrates, self, _group, _unit):Refresh()
              end
  
              local removecratesmenu = MENU_GROUP:New(_group, "Remove crates", topcrates)
              MENU_GROUP_COMMAND:New(_group, "Remove crates nearby", removecratesmenu, self._RemoveCratesNearby, self, _group, _unit)
  
              if self.onestepmenu then
                local mPack=MENU_GROUP:New(_group,"Pack crates",topcrates)
                MENU_GROUP_COMMAND:New(_group,"Pack",mPack,self._PackCratesNearby,self,_group,_unit)
                MENU_GROUP_COMMAND:New(_group,"Pack and Load",mPack,self._PackAndLoad,self,_group,_unit)
                MENU_GROUP_COMMAND:New(_group,"Pack and Remove",mPack,self._PackAndRemove,self,_group,_unit)
                MENU_GROUP_COMMAND:New(_group, "List crates nearby", topcrates, self._ListCratesNearby, self, _group, _unit)
              else
                MENU_GROUP_COMMAND:New(_group, "Pack crates", topcrates, self._PackCratesNearby, self, _group, _unit)
                MENU_GROUP_COMMAND:New(_group, "List crates nearby", topcrates, self._ListCratesNearby, self, _group, _unit)
              end
  
              local uName = _unit:GetName()
              local loadedData = self.Loaded_Cargo[uName]
              if loadedData and loadedData.Cargo then
                local cargoByName = {}
                for _, cgo in pairs(loadedData.Cargo) do
                  if cgo and (not cgo:WasDropped()) then
                    local cname   = cgo:GetName()
                    local cneeded = cgo:GetCratesNeeded()
                    local cdisplay = self:_GetCargoDisplayName(cgo)
                    cargoByName[cname] = cargoByName[cname] or { count=0, needed=cneeded, display=cdisplay }
                    cargoByName[cname].count = cargoByName[cname].count + 1
                  end
                end
                for name, info in pairs(cargoByName) do
                  local line = string.format("Drop %s (%d/%d)", info.display or name, info.count, info.needed)
                  MENU_GROUP_COMMAND:New(_group, line, dropCratesMenu, self._UnloadSingleCrateSet, self, _group, _unit, name)
                end
              end
            end
            if self:IsC130J(_unit) then
              local topunits    = MENU_GROUP:New(_group,"Manage Units",topmenu)
              local getunits    = MENU_GROUP:New(_group,"Get Units",topunits)
              MENU_GROUP_COMMAND:New(_group,"Remove units nearby",topunits,self._C130RemoveUnitsNearby,self,_group,_unit)

              local unitentries = self.C130GetUnits or {}
              local unittype    = _unit:GetTypeName() or "none"
              local subcatmenus = self.usesubcats and {} or nil

              for _,cargoObj in ipairs(unitentries) do
                local ok = true
                if cargoObj.UnitTypes then
                  ok = false
                  if type(cargoObj.UnitTypes) == "string" then
                    if unittype == cargoObj.UnitTypes then ok = true end
                  else
                    for _,ut in pairs(cargoObj.UnitTypes) do
                      if unittype == ut then ok = true break end
                    end
                  end
                end
                if ok and (not cargoObj.Stock or cargoObj.Stock == -1 or cargoObj.Stock > 0) then
                  local parent = getunits
                  if self.usesubcats == true and cargoObj.SubCategory then
                    local sub = subcatmenus[cargoObj.SubCategory]
                    if not sub then
                      sub = MENU_GROUP:New(_group,cargoObj.SubCategory,getunits)
                      subcatmenus[cargoObj.SubCategory] = sub
                    end
                    parent = sub
                  end
                  local menutext = self:_GetCargoDisplayName(cargoObj)
                  if type(cargoObj.Stock) == "number" and cargoObj.Stock >= 0 and self.showstockinmenuitems then
                    menutext = menutext.."["..cargoObj.Stock.."]"
                  end
                  MENU_GROUP_COMMAND:New(_group,menutext,parent,self._C130GetUnits,self,_group,_unit,cargoObj.Name)
                end
              end
            end

            -----------------------------------------------------
            -- Misc sub‐menus
            -----------------------------------------------------
            MENU_GROUP_COMMAND:New(_group, "List boarded cargo", topmenu, self._ListCargo, self, _group, _unit)
            MENU_GROUP_COMMAND:New(_group, "Inventory", topmenu, self._ListInventory, self, _group, _unit)
            MENU_GROUP_COMMAND:New(_group, "List active zone beacons", topmenu, self._ListRadioBeacons, self, _group, _unit)
  
            local smoketopmenu = MENU_GROUP:New(_group, "Smokes, Flares, Beacons", topmenu)
            MENU_GROUP_COMMAND:New(_group, "Smoke zones nearby", smoketopmenu, self.SmokeZoneNearBy, self, _unit, false)
            local smokeself = MENU_GROUP:New(_group, "Drop smoke now", smoketopmenu)
            MENU_GROUP_COMMAND:New(_group, "Red smoke", smokeself, self.SmokePositionNow, self, _unit, false, SMOKECOLOR.Red)
            MENU_GROUP_COMMAND:New(_group, "Blue smoke", smokeself, self.SmokePositionNow, self, _unit, false, SMOKECOLOR.Blue)
            MENU_GROUP_COMMAND:New(_group, "Green smoke", smokeself, self.SmokePositionNow, self, _unit, false, SMOKECOLOR.Green)
            MENU_GROUP_COMMAND:New(_group, "Orange smoke", smokeself, self.SmokePositionNow, self, _unit, false, SMOKECOLOR.Orange)
            MENU_GROUP_COMMAND:New(_group, "White smoke", smokeself, self.SmokePositionNow, self, _unit, false, SMOKECOLOR.White)
  
            MENU_GROUP_COMMAND:New(_group, "Flare zones nearby", smoketopmenu, self.SmokeZoneNearBy, self, _unit, true)
            MENU_GROUP_COMMAND:New(_group, "Fire flare now", smoketopmenu, self.SmokePositionNow, self, _unit, true)
            MENU_GROUP_COMMAND:New(_group, "Drop beacon now", smoketopmenu, self.DropBeaconNow, self, _unit):Refresh()
  
            if self:IsFixedWing(_unit) then
              MENU_GROUP_COMMAND:New(_group, "Show flight parameters", topmenu, self._ShowFlightParams, self, _group, _unit):Refresh()
            else
              MENU_GROUP_COMMAND:New(_group, "Show hover parameters", topmenu, self._ShowHoverParams, self, _group, _unit):Refresh()
            end
  
            -- Mark we built the menu
            self.MenusDone[_unitName] = true
            self:_RefreshLoadCratesMenu(_group,_unit)
            self:_RefreshDropCratesMenu(_group,_unit)
            if firstBuild then menucount=menucount+1 end
            if firstBuild and not self.showstockinmenuitems then self:_RefreshQuantityMenusForGroup(_group,_unit) end
          end -- if _group
        end -- if _unit
      else
        self:T(self.lid .. " Menus already done for this group!")
      end
    end -- for all pilot units
    return self
  end
  
--- (Internal) Function to refresh the menu for load crates. Triggered from land/getcrate/pack and more
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group The calling group.
-- @param Wrapper.Unit#UNIT Unit The calling unit.
-- @return #CTLD self
function CTLD:_RefreshLoadCratesMenu(Group,Unit)
    if not Group.MyLoadCratesMenu then return end
    Group.MyLoadCratesMenu:RemoveSubMenus()
    if self:IsC130J(Unit) then
      MENU_GROUP_COMMAND:New(Group,"Use C-130 Load system",Group.MyLoadCratesMenu,function() end)
      return
    end
    local d=self.CrateDistance or 35
    local nearby,n=self:_FindCratesNearby(Group,Unit,d,true,true)
    if n==0 then
      MENU_GROUP_COMMAND:New(Group,"No crates found! Rescan?",Group.MyLoadCratesMenu,function() self:_RefreshLoadCratesMenu(Group,Unit) end)
      return
    end
    MENU_GROUP_COMMAND:New(Group,"Load ALL",Group.MyLoadCratesMenu,self._LoadCratesNearby,self,Group,Unit)
  
    local cargoByName={}
    for _,crate in pairs(nearby) do
      local name=crate:GetName()
      cargoByName[name]=cargoByName[name] or{}
      table.insert(cargoByName[name],crate)
    end
  
    local lineIndex=1
    for cName,list in pairs(cargoByName) do
      local needed=list[1]:GetCratesNeeded() or 1
      table.sort(list,function(a,b)return a:GetID()<b:GetID() end)
      local i=1
      while i<=#list do
        local left=#list-i+1
        local label
        if left>=needed then
          label=string.format("%d. Load %s",lineIndex,cName)
          i=i+needed
        else
          label=string.format("%d. Load %s (%d/%d)",lineIndex,cName,left,needed)
          i=#list+1
        end
        MENU_GROUP_COMMAND:New(Group,label,Group.MyLoadCratesMenu,self._LoadSingleCrateSet,self,Group,Unit,cName)
        lineIndex=lineIndex+1
      end
    end
  end
  

---
-- Loads exactly `CratesNeeded` crates for one cargoName in range.
-- If "Ammo Truck" needs 2 crates, we pick up 2 if available.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #string cargoName The cargo name, e.g. "Ammo Truck"
function CTLD:_LoadSingleCrateSet(Group, Unit, cargoName, details)
  self:T(self.lid .. " _LoadSingleCrateSet cargoName=" .. (cargoName or "nil"))

  -- 1) Must be landed or hovering
  local grounded = not self:IsUnitInAir(Unit)
  local hover    = self:CanHoverLoad(Unit)
  if not grounded and not hover then
    self:_SendMessage("You must land or hover to load crates!", 10, false, Group)
    return self
  end

  -- 2) Check door if required
  if self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
    self:_SendMessage("You need to open the door(s) to load cargo!", 10, false, Group)
    return self
  end

  -- 3) Find crates with `cargoName` in range
  local finddist = self.CrateDistance or 35
  local cratesNearby, number = self:_FindCratesNearby(Group, Unit, finddist, false, false)
  if number == 0 then
    self:_SendMessage("No crates found in range!", 10, false, Group)
    return self
  end

  local matchingCrates = {}
  local needed = nil
  for _, crateObj in pairs(cratesNearby) do
    if crateObj:GetName() == cargoName then
      needed = needed or crateObj:GetCratesNeeded()
      table.insert(matchingCrates, crateObj)
    end
  end
  if not needed then
    self:_SendMessage(string.format("No \"%s\" crates found in range!", cargoName), 10, false, Group)
    return self
  end

  local found = #matchingCrates
  local batch = self._batchCrateLoad and self._batchCrateLoad[Unit:GetName()] or nil
  local prevSuppress = self.suppressmessages
  if batch and (not details) and batch.cname == cargoName then self.suppressmessages = true end

  -- 4) Check capacity
  local unitName = Unit:GetName()
  local loadedData = self.Loaded_Cargo[unitName] or { Troopsloaded=0, Cratesloaded=0, Cargo={} }
  local capabilities = self:_GetUnitCapabilities(Unit)
  local capacity = capabilities.cratelimit or 0
  if loadedData.Cratesloaded >= capacity then
    self:_SendMessage("No more capacity to load crates!", 10, false, Group)
    self.suppressmessages = prevSuppress
    return self
  end

  -- decide how many we can actually load
  local spaceLeft = capacity - loadedData.Cratesloaded
  local toLoad = math.min(found, needed, spaceLeft)
  if toLoad < 1 then
    self:_SendMessage("Cannot load crates: either none found or no capacity left.", 10, false, Group)
    self.suppressmessages = prevSuppress
    return self
  end

  -- 5) Load exactly `toLoad` crates
  local crateIDsLoaded = {}
  for i = 1, toLoad do
    local crate = matchingCrates[i]
    crate:SetHasMoved(true)
    crate:SetWasDropped(false)
    table.insert(loadedData.Cargo, crate)
    loadedData.Cratesloaded = loadedData.Cratesloaded + 1
    local stObj = crate:GetPositionable()
    if stObj and stObj:IsAlive() then
      stObj:Destroy(false)
    end
    table.insert(crateIDsLoaded, crate:GetID())
  end
  self.Loaded_Cargo[unitName] = loadedData
  self:_UpdateUnitCargoMass(Unit)

  -- 6) Remove them from self.Spawned_Cargo
  local newSpawned = {}
  for _, cObj in ipairs(self.Spawned_Cargo) do
    local keep = true
    for i=1, toLoad do
      if matchingCrates[i] and cObj:GetID() == matchingCrates[i]:GetID() then
        keep = false
        break
      end
    end
    if keep then
      table.insert(newSpawned, cObj)
    end
  end
  self.Spawned_Cargo = newSpawned

  -- 7) Show final message, including a special note if capacity is now reached
  local loadedHere = toLoad
  if details or (not batch) then
    if loadedHere < needed and loadedData.Cratesloaded >= capacity then
      self:_SendMessage(string.format("Loaded only %d/%d crate(s) of %s. Cargo limit is now reached!", loadedHere, needed, cargoName), 10, false, Group)
    else
      local fullSets = math.floor(loadedHere / needed)
      local leftover = loadedHere % needed
      if needed > 1 then
        if fullSets > 0 and leftover == 0 then
          self:_SendMessage(string.format("Loaded %d %s.", fullSets, cargoName), 10, false, Group)
        elseif fullSets > 0 and leftover > 0 then
          self:_SendMessage(string.format("Loaded %d %s(s), with %d leftover crate(s).", fullSets, cargoName, leftover), 10, false, Group)
        else
          self:_SendMessage(string.format("Loaded only %d/%d crate(s) of %s.", loadedHere, needed, cargoName), 15, false, Group)
        end
      else
        self:_SendMessage(string.format("Loaded %d %s(s).", loadedHere, cargoName), 10, false, Group)
      end
    end
  end

  self:_RefreshLoadCratesMenu(Group, Unit)
  self:_RefreshDropCratesMenu(Group, Unit)
  self:_RefreshCrateQuantityMenus(Group, Unit, self:_FindCratesCargoObject(cargoName))

  if batch and batch.cname == cargoName then
    local setsLoaded = math.floor((loadedHere or 0) / (needed or 1))
    batch.loaded = (batch.loaded or 0) + (setsLoaded or 0)
    if loadedHere < (needed or 1) then batch.partials = (batch.partials or 0) + 1 end
    batch.remaining = (batch.remaining or 1) - 1
    if batch.remaining <= 0 then
      self.suppressmessages = prevSuppress
    if not details then
      local txt = string.format("Loaded %d %s.", batch.loaded, cargoName)
      if batch.partials and batch.partials > 0 then
        txt = txt .. " Some sets could not be fully loaded."
      end
      self:_SendMessage(txt, 10, false, batch.group)
    end
      self._batchCrateLoad[Unit:GetName()] = nil
    else
      self.suppressmessages = prevSuppress
    end
  end
  return self
end


--- (Internal) Function to unload a single crate
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group The calling group.
-- @param Wrapper.Unit#UNIT Unit The calling unit.
-- @param #string setIndex The name of the crate to unload
-- @return #CTLD self
function CTLD:_UnloadSingleCrateSet(Group, Unit, setIndex)
  self:T(self.lid .. " _UnloadSingleCrateSet")

  -- Check if we are in a drop zone (unless we drop anywhere)
  if not self.dropcratesanywhere then
    local inzone, zoneName, zone, distance = self:IsUnitInZone(Unit, CTLD.CargoZoneType.DROP)
    if not inzone then
      self:_SendMessage("You are not close enough to a drop zone!", 10, false, Group)
      if not self.debug then 
        return self 
      end
    end
  end

  -- Check if doors must be open
  if self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
    self:_SendMessage("You need to open the door(s) to drop cargo!", 10, false, Group)
    if not self.debug then return self end
  end

  -- Check if the crate grouping data is available
  local unitName = Unit:GetName()
  if not self.CrateGroupList or not self.CrateGroupList[unitName] then
    self:_SendMessage("No crate groups found for this unit!", 10, false, Group)
    if not self.debug then return self end
    return self
  end

  -- Find the selected chunk/set by index
  local chunk = self.CrateGroupList[unitName][setIndex]
  if not chunk then
    self:_SendMessage("No crate set found or index invalid!", 10, false, Group)
    if not self.debug then return self end
    return self
  end

  -- Check if the chunk is empty
  if #chunk == 0 then
    self:_SendMessage("No crate found in that set!", 10, false, Group)
    if not self.debug then return self end
    return self
  end

  -- Check hover/airdrop/landed logic
  local grounded = not self:IsUnitInAir(Unit)
  local hoverunload = self:IsCorrectHover(Unit)
  local isHerc = self:IsFixedWing(Unit)
  local isHook = self:IsHook(Unit)
  if isHerc and not isHook then
    hoverunload = self:IsCorrectFlightParameters(Unit)
  end
  if not grounded and not hoverunload then
    if isHerc then
      self:_SendMessage("Nothing loaded or not within airdrop parameters!", 10, false, Group)
    else
      self:_SendMessage("Nothing loaded or not hovering within parameters!", 10, false, Group)
    end
    if not self.debug then return self end
    return self
  end

  -- Get the first crate from this set
  local crateObj = chunk[1]
  if not crateObj then
    self:_SendMessage("No crate found in that set!", 10, false, Group)
    if not self.debug then return self end
    return self
  end

  -- Perform the actual "drop" spawn
  local needed = crateObj:GetCratesNeeded() or 1
  self:_GetCrates(Group, Unit, crateObj, #chunk, true)

  -- Mark all crates in the chunk as dropped
  for _, cObj in ipairs(chunk) do
    cObj:SetWasDropped(true)
    cObj:SetHasMoved(true)
  end
local cname  = crateObj:GetName() or "Unknown"
local count  = #chunk
if needed > 1 then
if count == needed then
    self:_SendMessage(string.format("Dropped %d %s.", 1, cname), 10, false, Group)
else
    self:_SendMessage(string.format("Dropped %d/%d crate(s) of %s.", count, needed, cname), 15, false, Group)
end
else
self:_SendMessage(string.format("Dropped %d %s(s).", count, cname), 10, false, Group)
end
  -- Rebuild the cargo list to remove the dropped crates
  local loadedData = self.Loaded_Cargo[unitName]
  if loadedData and loadedData.Cargo then
    local newList = {}
    local newCratesCount = 0
    for _, cObj in ipairs(loadedData.Cargo) do
      if not cObj:WasDropped() then
        table.insert(newList, cObj)
        local ct = cObj:GetType()
        if ct ~= CTLD_CARGO.Enum.TROOPS and ct ~= CTLD_CARGO.Enum.ENGINEERS then
          newCratesCount = newCratesCount + 1
        end
      end
    end
    loadedData.Cargo = newList
    loadedData.Cratesloaded = newCratesCount
    self.Loaded_Cargo[unitName] = loadedData
  end

  -- Update cargo mass, refresh menu
  self:_UpdateUnitCargoMass(Unit)
  self:_RefreshDropCratesMenu(Group, Unit)
  self:_RefreshLoadCratesMenu(Group, Unit)
  self:_RefreshCrateQuantityMenus(Group, Unit, nil)
  return self
end

--- (Internal) Function to refresh the menu for a single unit after crates dropped.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group The calling group.
-- @param Wrapper.Unit#UNIT Unit The calling unit.
-- @return #CTLD self
function CTLD:_RefreshDropCratesMenu(Group, Unit)

    if not Group.CTLDTopmenu then return end
    local topCrates = Group.MyTopCratesMenu
    if not topCrates then return end
    if topCrates.DropCratesMenu then
      topCrates.DropCratesMenu:RemoveSubMenus()
    else
      topCrates.DropCratesMenu = MENU_GROUP:New(Group, "Drop Crates", topCrates)
    end
  
    local dropCratesMenu = topCrates.DropCratesMenu
    local loadedData = self.Loaded_Cargo[Unit:GetName()]
    if not loadedData or not loadedData.Cargo then
      MENU_GROUP_COMMAND:New(Group,"No crates to drop!",dropCratesMenu,function() end)
      return
    end
  
    local cargoByName={}
    local dropableCrates=0
    for _,cObj in ipairs(loadedData.Cargo) do
      if cObj and not cObj:WasDropped() then
        local cType=cObj:GetType()
        if cType~=CTLD_CARGO.Enum.TROOPS and cType~=CTLD_CARGO.Enum.ENGINEERS and cType~=CTLD_CARGO.Enum.GCLOADABLE then
          local name=cObj:GetName()or"Unknown"
          cargoByName[name]=cargoByName[name]or{}
          table.insert(cargoByName[name],cObj)
          dropableCrates=dropableCrates+1
        end
      end
    end
  
    if dropableCrates==0 then
      MENU_GROUP_COMMAND:New(Group,"No crates to drop!",dropCratesMenu,function() end)
      return
    end
  
    ----------------------------------------------------------------------
    -- DEFAULT (“classic”) versus ONE-STEP behaviour
    ----------------------------------------------------------------------
    if not self.onestepmenu then
      --------------------------------------------------------------------
      -- classic menu
      --------------------------------------------------------------------
      MENU_GROUP_COMMAND:New(Group,"Drop ALL crates",dropCratesMenu,self._UnloadCrates,self,Group,Unit)
  
      self.CrateGroupList=self.CrateGroupList or{}
      self.CrateGroupList[Unit:GetName()]={}
  
      local lineIndex=1
      for cName,list in pairs(cargoByName) do
        local needed=list[1]:GetCratesNeeded() or 1
        table.sort(list,function(a,b)return a:GetID()<b:GetID()end)
        local i=1
        local sets=math.floor(#list/(needed>0 and needed or 1))
        if sets>0 then
          local parentLabel=string.format("%d. %s (%d SET)",lineIndex,cName,sets)
          local parentMenu=MENU_GROUP:New(Group,parentLabel,dropCratesMenu)
          for s=1,sets do
            local chunk={}
            for n=i,i+needed-1 do table.insert(chunk,list[n]) end
            table.insert(self.CrateGroupList[Unit:GetName()],chunk)
            i=i+needed
          end
          if sets==1 then
            MENU_GROUP_COMMAND:New(Group,"Drop",parentMenu,function(selfArg,GroupArg,UnitArg,cNameArg,neededArg,qty)
              local uName=UnitArg:GetName()
              for k=1,qty do
                local lst=selfArg.CrateGroupList and selfArg.CrateGroupList[uName]
                if not lst then break end
                local idx=nil
                for j=1,#lst do
                  local ch=lst[j]
                  local first=ch and ch[1]
                  if first and (not first:WasDropped()) and first:GetName()==cNameArg and #ch>=neededArg then idx=j break end
                end
                if not idx then break end
                selfArg:_UnloadSingleCrateSet(GroupArg,UnitArg,idx)
              end
            end,self,Group,Unit,cName,needed,1)
          else
            for q=1,sets do
              local qm=MENU_GROUP:New(Group,string.format("Drop %d Set%s",q,q>1 and "s" or ""),parentMenu)
              MENU_GROUP_COMMAND:New(Group,"Drop",qm,function(selfArg,GroupArg,UnitArg,cNameArg,neededArg,qty)
                local uName=UnitArg:GetName()
                for k=1,qty do
                  local lst=selfArg.CrateGroupList and selfArg.CrateGroupList[uName]
                  if not lst then break end
                  local idx=nil
                  for j=1,#lst do
                    local ch=lst[j]
                    local first=ch and ch[1]
                    if first and (not first:WasDropped()) and first:GetName()==cNameArg and #ch>=neededArg then idx=j break end
                  end
                  if not idx then break end
                  selfArg:_UnloadSingleCrateSet(GroupArg,UnitArg,idx)
                end
              end,self,Group,Unit,cName,needed,q)
            end
          end
          lineIndex=lineIndex+1
        end
        if i<=#list then
          local left=#list-i+1
          local chunk={}
          for n=i,#list do table.insert(chunk,list[n]) end
          table.insert(self.CrateGroupList[Unit:GetName()],chunk)
          local setIndex=#self.CrateGroupList[Unit:GetName()]
          local label=string.format("%d. %s %d/%d",lineIndex,cName,left,needed)
          MENU_GROUP_COMMAND:New(Group,label,dropCratesMenu,self._UnloadSingleCrateSet,self,Group,Unit,setIndex)
          lineIndex=lineIndex+1
        end
      end
  
    else
      --------------------------------------------------------------------
      -- one-step (enhanced) menu
      --------------------------------------------------------------------
      local mAll=MENU_GROUP:New(Group,"Drop ALL crates",dropCratesMenu)
      MENU_GROUP_COMMAND:New(Group,"Drop",mAll,self._UnloadCrates,self,Group,Unit)
      if not ( self:IsUnitInAir(Unit) and self:IsFixedWing(Unit) ) then
        MENU_GROUP_COMMAND:New(Group,"Drop and build",mAll,self._DropAndBuild,self,Group,Unit)
      end

      self.CrateGroupList=self.CrateGroupList or{}
      self.CrateGroupList[Unit:GetName()]={}
  
      local lineIndex=1
      for cName,list in pairs(cargoByName) do
        local needed=list[1]:GetCratesNeeded() or 1
        table.sort(list,function(a,b)return a:GetID()<b:GetID()end)
        local i=1
        local sets=math.floor(#list/(needed>0 and needed or 1))
        if sets>0 then
          local parentLabel=string.format("%d. %s (%d SET)",lineIndex,cName,sets)
          local parentMenu=MENU_GROUP:New(Group,parentLabel,dropCratesMenu)
          for s=1,sets do
            local chunk={}
            for n=i,i+needed-1 do table.insert(chunk,list[n]) end
            table.insert(self.CrateGroupList[Unit:GetName()],chunk)
            i=i+needed
          end
          if sets==1 then
            MENU_GROUP_COMMAND:New(Group,"Drop",parentMenu,function(selfArg,GroupArg,UnitArg,cNameArg,neededArg,qty)
              local uName=UnitArg:GetName()
              for k=1,qty do
                local lst=selfArg.CrateGroupList and selfArg.CrateGroupList[uName]
                if not lst then break end
                local idx=nil
                for j=1,#lst do
                  local ch=lst[j]
                  local first=ch and ch[1]
                  if first and (not first:WasDropped()) and first:GetName()==cNameArg and #ch>=neededArg then idx=j break end
                end
                if not idx then break end
                selfArg:_UnloadSingleCrateSet(GroupArg,UnitArg,idx)
              end
            end,self,Group,Unit,cName,needed,1)
            if not ( self:IsUnitInAir(Unit) and self:IsFixedWing(Unit) ) then
              MENU_GROUP_COMMAND:New(Group,"Drop and build",parentMenu,function(selfArg,GroupArg,UnitArg,cNameArg,neededArg,qty)
                local uName=UnitArg:GetName()
                for k=1,qty do
                  local lst=selfArg.CrateGroupList and selfArg.CrateGroupList[uName]
                  if not lst then break end
                  local idx=nil
                  for j=1,#lst do
                    local ch=lst[j]
                    local first=ch and ch[1]
                    if first and (not first:WasDropped()) and first:GetName()==cNameArg and #ch>=neededArg then idx=j break end
                  end
                  if not idx then break end
                  selfArg:_UnloadSingleCrateSet(GroupArg,UnitArg,idx)
                end
                selfArg:_BuildCrates(GroupArg,UnitArg)
              end,self,Group,Unit,cName,needed,1)
            end
          else
            for q=1,sets do
              local qm=MENU_GROUP:New(Group,string.format("Drop %d Set%s",q,q>1 and "s" or ""),parentMenu)
              MENU_GROUP_COMMAND:New(Group,"Drop",qm,function(selfArg,GroupArg,UnitArg,cNameArg,neededArg,qty)
                local uName=UnitArg:GetName()
                for k=1,qty do
                  local lst=selfArg.CrateGroupList and selfArg.CrateGroupList[uName]
                  if not lst then break end
                  local idx=nil
                  for j=1,#lst do
                    local ch=lst[j]
                    local first=ch and ch[1]
                    if first and (not first:WasDropped()) and first:GetName()==cNameArg and #ch>=neededArg then idx=j break end
                  end
                  if not idx then break end
                  selfArg:_UnloadSingleCrateSet(GroupArg,UnitArg,idx)
                end
              end,self,Group,Unit,cName,needed,q)
              if not ( self:IsUnitInAir(Unit) and self:IsFixedWing(Unit) ) then
                MENU_GROUP_COMMAND:New(Group,"Drop and build",qm,function(selfArg,GroupArg,UnitArg,cNameArg,neededArg,qty)
                  local uName=UnitArg:GetName()
                  for k=1,qty do
                    local lst=selfArg.CrateGroupList and selfArg.CrateGroupList[uName]
                    if not lst then break end
                    local idx=nil
                    for j=1,#lst do
                      local ch=lst[j]
                      local first=ch and ch[1]
                      if first and (not first:WasDropped()) and first:GetName()==cNameArg and #ch>=neededArg then idx=j break end
                    end
                    if not idx then break end
                    selfArg:_UnloadSingleCrateSet(GroupArg,UnitArg,idx)
                  end
                  selfArg:_BuildCrates(GroupArg,UnitArg)
                end,self,Group,Unit,cName,needed,q)
              end
            end
          end
          lineIndex=lineIndex+1
        end
        if i<=#list then
          local left=#list-i+1
          local chunk={}
          for n=i,#list do table.insert(chunk,list[n]) end
          table.insert(self.CrateGroupList[Unit:GetName()],chunk)
          local setIndex=#self.CrateGroupList[Unit:GetName()]
          local label=string.format("%d. %s %d/%d",lineIndex,cName,left,needed)
          MENU_GROUP_COMMAND:New(Group,label,dropCratesMenu,self._UnloadSingleCrateSet,self,Group,Unit,setIndex)
          lineIndex=lineIndex+1
        end
      end
    end
  end


--- (Internal) Function to unload a single Troop group by ID.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group The calling group.
-- @param Wrapper.Unit#UNIT Unit The calling unit.
-- @param #number chunkID the Cargo ID
-- @return #CTLD self
function CTLD:_UnloadSingleTroopByID(Group, Unit, chunkID, qty)
  self:T(self.lid .. " _UnloadSingleTroopByID chunkID=" .. tostring(chunkID))

  qty = qty or 1

  local droppingatbase = false
  local inzone, zonename, zone, distance = self:IsUnitInZone(Unit, CTLD.CargoZoneType.LOAD)
  if not inzone then
    inzone, zonename, zone, distance = self:IsUnitInZone(Unit, CTLD.CargoZoneType.SHIP)
  end
  if inzone then
    droppingatbase = self.returntroopstobase
  end

  if self.pilotmustopendoors and not UTILS.IsLoadingDoorOpen(Unit:GetName()) then
    self:_SendMessage("You need to open the door(s) to unload troops!", 10, false, Group)
    if not self.debug then return self end 
  end

  local hoverunload = self:IsCorrectHover(Unit)
  local isHerc = self:IsFixedWing(Unit)
  local isHook = self:IsHook(Unit)
  if isHerc and not isHook then
    hoverunload = self:IsCorrectFlightParameters(Unit)
  end
  local grounded = not self:IsUnitInAir(Unit)
  local unitName = Unit:GetName()

  if self.Loaded_Cargo[unitName] and (grounded or hoverunload) then
    if not droppingatbase or self.debug then
      if not self.TroopsIDToChunk or not self.TroopsIDToChunk[chunkID] then
        self:_SendMessage(string.format("No troop cargo chunk found for ID %d!", chunkID), 10, false, Group)
        if not self.debug then return self end
        return self
      end

      local chunk = self.TroopsIDToChunk[chunkID]
      if not chunk or #chunk == 0 then
        self:_SendMessage(string.format("Troop chunk is empty for ID %d!", chunkID), 10, false, Group)
        if not self.debug then return self end
        return self
      end

      local deployedTroopsByName = {}
      local deployedEngineersByName = {}

      -- Drop the FIRST cargo in that chunk
      for n = 1, qty do
        local foundCargo = chunk[1]
        if not foundCargo then break end

        local cType = foundCargo:GetType()
        local name  = foundCargo:GetName() or "none"
        local tmpl  = foundCargo:GetTemplates() or {}
        local zoneradius = self.troopdropzoneradius or 100
        local factor = 1
        if isHerc then
          factor = foundCargo:GetCratesNeeded() or 1
          zoneradius = Unit:GetVelocityMPS() or 100
        end
        local zone = ZONE_GROUP:New(string.format("Unload zone-%s", unitName), Group, zoneradius * factor)
        local randomcoord = zone:GetRandomCoordinate(10, 30 * factor)
        local heading = Group:GetHeading() or 0

        if grounded or hoverunload then
          randomcoord = Group:GetCoordinate()
          local Angle = (heading + 270) % 360
          if isHerc or isHook then
            Angle = (heading + 180) % 360
          end
          local offset = hoverunload and self.TroopUnloadDistHover or self.TroopUnloadDistGround
          if isHerc then
            offset = self.TroopUnloadDistGroundHerc or 25
          end
          if isHook then
            offset = self.TroopUnloadDistGroundHook or 15
            if hoverunload and self.TroopUnloadDistHoverHook then
              offset = self.TroopUnloadDistHoverHook or 5
            end
          end
          randomcoord:Translate(offset, Angle, nil, true)
        end

        local tempcount = 0
        if isHook then
          tempcount = self.ChinookTroopCircleRadius or 5
        end
        for _, _template in pairs(tmpl) do
          self.TroopCounter = self.TroopCounter + 1
          tempcount = tempcount + 1
          local alias = string.format("%s-%d", _template, math.random(1,100000))
          local rad   = 2.5 + (tempcount * 2)
          local Positions = self:_GetUnitPositions(randomcoord, rad, heading, _template)
          self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template, alias)
            :InitDelayOff()
            :InitSetUnitAbsolutePositions(Positions)
            :InitValidateAndRepositionGroundUnits(self.validateAndRepositionUnits)
            :OnSpawnGroup(function(grp) grp.spawntime = timer.getTime() end)
            :SpawnFromVec2(randomcoord:GetVec2())
          self:__TroopsDeployed(1, Group, Unit, self.DroppedTroops[self.TroopCounter], cType)
        end
        
        foundCargo:SetWasDropped(true)
        if cType == CTLD_CARGO.Enum.ENGINEERS then
          self.Engineers = self.Engineers + 1
            local grpname = self.DroppedTroops[self.TroopCounter]:GetName()
          self.EngineersInField[self.Engineers] = CTLD_ENGINEERING:New(name, grpname)
          deployedEngineersByName[name] = (deployedEngineersByName[name] or 0) + 1
        else
          deployedTroopsByName[name] = (deployedTroopsByName[name] or 0) + 1
        end

        table.remove(chunk, 1)
        if #chunk == 0 then
          self.TroopsIDToChunk[chunkID] = nil
          break
        end
      end

      local parts = {}
      for nName,nCount in pairs(deployedTroopsByName) do
        parts[#parts + 1] = tostring(nCount).."x Troops "..nName
      end
      for nName,nCount in pairs(deployedEngineersByName) do
        parts[#parts + 1] = tostring(nCount).."x Engineers "..nName
      end
      if #parts > 0 then
        self:_SendMessage("Dropped "..table.concat(parts, ", ").." into action!", 10, false, Group)
      end
    else
      -- Return to base logic, remove ONLY the first cargo
      self:_SendMessage("Troops have returned to base!", 10, false, Group)
      self:__TroopsRTB(1, Group, Unit, zonename, zone)

      if self.TroopsIDToChunk and self.TroopsIDToChunk[chunkID] then
        local chunk = self.TroopsIDToChunk[chunkID]
        for n = 1, qty do
          if #chunk == 0 then break end
          local firstObj = chunk[1]
          local cName = firstObj:GetName()
          local gentroops = self.Cargo_Troops
          for _id, _troop in pairs(gentroops) do
            if _troop.Name == cName then
              local st = _troop:GetStock()
              if st and tonumber(st) >= 0 then
                _troop:AddStock()
                self:_RefreshTroopQuantityMenus(Group, Unit, _troop)
              end
            end
          end
          firstObj:SetWasDropped(true)
          table.remove(chunk, 1)
        end
        if #chunk == 0 then
          self.TroopsIDToChunk[chunkID] = nil
        end
      end
    end

    local cargoList = self.Loaded_Cargo[unitName].Cargo
    for i = #cargoList, 1, -1 do
      if cargoList[i]:WasDropped() then
        table.remove(cargoList, i)
      end
    end
    local troopsLoaded = 0
    local cratesLoaded = 0
    for _, cargo in ipairs(cargoList) do
      local cT = cargo:GetType()
      if cT == CTLD_CARGO.Enum.TROOPS or cT == CTLD_CARGO.Enum.ENGINEERS then
        troopsLoaded = troopsLoaded + 1
      else
        cratesLoaded = cratesLoaded + 1
      end
    end
    self.Loaded_Cargo[unitName].Troopsloaded = troopsLoaded
    self.Loaded_Cargo[unitName].Cratesloaded = cratesLoaded
    self:_RefreshDropTroopsMenu(Group, Unit)
    self:_RefreshTroopQuantityMenus(Group, Unit, nil)
  else
    local isHerc = self:IsFixedWing(Unit)
    if isHerc then
      self:_SendMessage("Nothing loaded or not within airdrop parameters!", 10, false, Group)
    else
      self:_SendMessage("Nothing loaded or not hovering within parameters!", 10, false, Group)
    end
  end
  return self
end

--- (Internal) Function to refresh menu for troops on drop for a specific unit
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group The requesting group.
-- @param Wrapper.Unit#UNIT Unit The requesting unit.
-- @return #CTLD self
function CTLD:_RefreshDropTroopsMenu(Group, Unit)
  local theGroup = Group
  local theUnit  = Unit
  if not theGroup.CTLDTopmenu then return end
  local topTroops = theGroup.MyTopTroopsMenu
  if not topTroops then return end
  local dropTroopsMenu = topTroops.DropTroopsMenu
  if dropTroopsMenu then
    dropTroopsMenu:RemoveSubMenus()
  else
    dropTroopsMenu = MENU_GROUP:New(theGroup, "Drop Troops", topTroops)
    topTroops.DropTroopsMenu = dropTroopsMenu
  end
  MENU_GROUP_COMMAND:New(theGroup, "Drop ALL troops", dropTroopsMenu, self._UnloadTroops, self, theGroup, theUnit)

  local loadedData = self.Loaded_Cargo[theUnit:GetName()]
  if not loadedData or not loadedData.Cargo then return end

  -- Gather troop cargo by name
  local troopsByName = {}
  for _, cargoObj in ipairs(loadedData.Cargo) do
    if cargoObj
       and (cargoObj:GetType() == CTLD_CARGO.Enum.TROOPS or cargoObj:GetType() == CTLD_CARGO.Enum.ENGINEERS)
       and not cargoObj:WasDropped()
    then
      local name = cargoObj:GetName() or "Unknown"
      troopsByName[name] = troopsByName[name] or {}
      table.insert(troopsByName[name], cargoObj)
    end
  end

  self.TroopsIDToChunk = self.TroopsIDToChunk or {}

  for tName, objList in pairs(troopsByName) do
    table.sort(objList, function(a,b) return a:GetID() < b:GetID() end)
    local count = #objList
    if count > 0 then
      local chunkID = objList[1]:GetID()
      self.TroopsIDToChunk[chunkID] = objList

      local label = string.format("Drop %s (%d)", tName, count)
      if count == 1 then
        MENU_GROUP_COMMAND:New(theGroup, label, dropTroopsMenu, self._UnloadSingleTroopByID, self, theGroup, theUnit, chunkID, 1)
      else
        local parentMenu = MENU_GROUP:New(theGroup, label, dropTroopsMenu)
        for q = 1, count do
          MENU_GROUP_COMMAND:New(theGroup, string.format("Drop (%d) %s", q, tName), parentMenu, self._UnloadSingleTroopByID, self, theGroup, theUnit, chunkID, q)
        end
      end
    end
  end
end
--- [Internal] Function to check if a template exists in the mission.
-- @param #CTLD self
-- @param #table temptable Table of string names
-- @return #boolean outcome
function CTLD:_CheckTemplates(temptable)
  self:T(self.lid .. " _CheckTemplates")
  local outcome = true
  if type(temptable) ~= "table" then
    temptable = {temptable}
  end
  for _,_name in pairs(temptable) do
    if not _DATABASE.Templates.Groups[_name] then
      outcome = false
      self:E(self.lid .. "ERROR: Template name " .. _name ..  " is missing!")
    end
  end
  return outcome
end

--- User function - Add *generic* troop type loadable as cargo. This type will load directly into the heli without crates.
-- @param #CTLD self
-- @param #string Name Unique name of this type of troop. E.g. "Anti-Air Small".
-- @param #table Templates Table of #string names of late activated Wrapper.Group#GROUP making up this troop.
-- @param #CTLD_CARGO.Enum Type Type of cargo, here TROOPS - these will move to a nearby destination zone when dropped/build.
-- @param #number NoTroops Size of the group in number of Units across combined templates (for loading).
-- @param #number PerTroopMass Mass in kg of each soldier
-- @param #number Stock Number of groups in stock. Nil for unlimited.
-- @param #string SubCategory Name of sub-category (optional).
function CTLD:AddTroopsCargo(Name,Templates,Type,NoTroops,PerTroopMass,Stock,SubCategory) 
  self:T(self.lid .. " AddTroopsCargo")
  self:T({Name,Templates,Type,NoTroops,PerTroopMass,Stock})
  if not self:_CheckTemplates(Templates) then
    self:E(self.lid .. "Troops Cargo for " .. Name .. " has missing template(s)!" )
    return self
  end
  self.CargoCounter = self.CargoCounter + 1
  -- Troops are directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,Templates,Type,false,true,NoTroops,nil,nil,PerTroopMass,Stock, SubCategory)
  table.insert(self.Cargo_Troops,cargo)
  if SubCategory and self.usesubcats ~= true then self.usesubcats=true end
  return self
end

--- User function - Add *generic* unit-type entry for the C-130J-30 Manage Units menu. This type will spawn units that can move.
-- @param #CTLD self
-- @param #string Name Unique name of this type of unit. E.g. "Humvee".
-- @param #table Templates Table of #string names of late activated Wrapper.Group#GROUP used to spawn this unit.
-- @param #CTLD_CARGO.Enum Type Type of unit. I.e. VEHICLE or FOB. VEHICLE will move when spawned, FOB stays put.
-- @param #number Stock Number of units in stock. Nil or -1 for unlimited.
-- @param #string SubCategory Name of sub-category (optional), used for sub-menus when self.usesubcats == true.
-- @param #string UnitTypes Unit type names (optional). If set, only these unit types can use this entry, e.g. "C-130J-30" or {"C-130J-30"}.
-- @return #CTLD self
function CTLD:AddUnits(Name,Templates,Type,Stock,SubCategory,UnitTypes)
  self:T(self.lid .. " AddUnits")
  if not self:_CheckTemplates(Templates) then
    self:E(self.lid .. "Units for " .. Name .. " has missing template(s)!")
    return self
  end
  self.C130GetUnits = self.C130GetUnits or {}
  local entry = {}
  entry.Name = Name
  entry.Templates = Templates
  entry.Type = Type
  entry.Stock = Stock or nil
  entry.Stock0 = Stock or nil
  entry.SubCategory = SubCategory or "Other"
  entry.UnitTypes = UnitTypes
  entry.CanMove = true
  table.insert(self.C130GetUnits,entry)
  return self
end

--- User function - Add *generic* unit-type entry for the C-130J-30 Manage Units menu. This type will spawn units that stay in place.
-- @param #CTLD self
-- @param #string Name Unique name of this type of unit. E.g. "Humvee".
-- @param #table Templates Table of #string names of late activated Wrapper.Group#GROUP used to spawn this unit.
-- @param #CTLD_CARGO.Enum Type Type of unit. I.e. VEHICLE or FOB. VEHICLE will be treated as non-moving here, FOB stays put.
-- @param #number Stock Number of units in stock. Nil or -1 for unlimited.
-- @param #string SubCategory Name of sub-category (optional), used for sub-menus when self.usesubcats == true.
-- @param #string UnitTypes Unit type names (optional). If set, only these unit types can use this entry, e.g. "C-130J-30" or {"C-130J-30"}.
-- @return #CTLD self
function CTLD:AddUnitsNoMove(Name,Templates,Type,Stock,SubCategory,UnitTypes)
  self:T(self.lid .. " AddUnitsNoMove")
  if not self:_CheckTemplates(Templates) then
    self:E(self.lid .. "UnitsNoMove for " .. Name .. " has missing template(s)!")
    return self
  end
  self.C130GetUnits = self.C130GetUnits or {}
  local entry = {}
  entry.Name = Name
  entry.Templates = Templates
  entry.Type = Type
  entry.Stock = Stock
  entry.Stock0 = Stock
  entry.SubCategory = SubCategory or "Other"
  entry.UnitTypes = UnitTypes
  entry.CanMove = false
  table.insert(self.C130GetUnits,entry)
  return self
end

--- User function - Add *generic* crate-type loadable as cargo. This type will create crates that need to be loaded, moved, dropped and built.
-- @param #CTLD self
-- @param #string Name Unique name of this type of cargo. E.g. "Humvee".
-- @param #table Templates Table of #string names of late activated Wrapper.Group#GROUP building this cargo.
-- @param #CTLD_CARGO.Enum Type Type of cargo. I.e. VEHICLE or FOB. VEHICLE will move to destination zones when dropped/build, FOB stays put.
-- @param #number NoCrates Number of crates needed to build this cargo.
-- @param #number PerCrateMass Mass in kg of each crate
-- @param #number Stock Number of buildable groups in stock. Nil for unlimited.
-- @param #string SubCategory Name of sub-category (optional).
-- @param #boolean DontShowInMenu (optional) If set to "true" this won't show up in the menu.
-- @param Core.Zone#ZONE Location (optional) If set, the cargo item is **only** available here. Can be a #ZONE object or the name of a zone as #string.
-- @param #string UnitTypes Unit type names (optional). If set, only these unit types can pick up the cargo, e.g. "UH-1H" or {"UH-1H","OH58D"}.
-- @param #string Category Static category name (optional). If set, spawn cargo crate with an alternate category type, e.g. "Cargos".
-- @param #string TypeName Static type name (optional). If set, spawn cargo crate with an alternate type shape, e.g. "iso_container".
-- @param #string ShapeName Static shape name (optional). If set, spawn cargo crate with an alternate type sub-shape, e.g. "iso_container_cargo".
-- @param #string TypeName Static type name (optional). If set, it will overwride even though TypeName is passed. this is only for the C-130J-30. Can be used with other TypeName for other modules.
-- @return #CTLD self
function CTLD:AddCratesCargo(Name,Templates,Type,NoCrates,PerCrateMass,Stock,SubCategory,DontShowInMenu,Location,UnitTypes,Category,TypeName,ShapeName,C130TypeName)
  self:T(self.lid .. " AddCratesCargo")
  if not self:_CheckTemplates(Templates) then
    self:E(self.lid .. "Crates Cargo for " .. Name .. " has missing template(s)!" )
    return self
  end
  self.CargoCounter = self.CargoCounter + 1
  -- Crates are not directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,Templates,Type,false,false,NoCrates,nil,nil,PerCrateMass,Stock,SubCategory,DontShowInMenu,Location)
  if UnitTypes then
    cargo:AddUnitTypeName(UnitTypes)
  end
  cargo:SetStaticTypeAndShape("Cargos",self.basetype)
  if TypeName then
    cargo:SetStaticTypeAndShape(Category,TypeName,ShapeName)
  end
  cargo.C130TypeName = C130TypeName
  table.insert(self.Cargo_Crates,cargo)
  if SubCategory and self.usesubcats ~= true then self.usesubcats=true end
  return self
end

--- Identical to AddCratesCargo, but registers the cargo so the spawned/built group does not move to MOVE zones.
--- User function - Add *generic* crate-type loadable as cargo. This type will create crates that need to be loaded, moved, dropped and built.
-- @param #CTLD self
-- @param #string Name Unique name of this type of cargo. E.g. "Humvee".
-- @param #table Templates Table of #string names of late activated Wrapper.Group#GROUP building this cargo.
-- @param #CTLD_CARGO.Enum Type Type of cargo. I.e. VEHICLE or FOB. VEHICLE will move to destination zones when dropped/build, FOB stays put.
-- @param #number NoCrates Number of crates needed to build this cargo.
-- @param #number PerCrateMass Mass in kg of each crate
-- @param #number Stock Number of buildable groups in stock. Nil for unlimited.
-- @param #string SubCategory Name of sub-category (optional).
-- @param #boolean DontShowInMenu (optional) If set to "true" this won't show up in the menu.
-- @param Core.Zone#ZONE Location (optional) If set, the cargo item is **only** available here. Can be a #ZONE object or the name of a zone as #string.
-- @param #string UnitTypes Unit type names (optional). If set, only these unit types can pick up the cargo, e.g. "UH-1H" or {"UH-1H","OH58D"}.
-- @param #string Category Static category name (optional). If set, spawn cargo crate with an alternate category type, e.g. "Cargos".
-- @param #string TypeName Static type name (optional). If set, spawn cargo crate with an alternate type shape, e.g. "iso_container".
-- @param #string ShapeName Static shape name (optional). If set, spawn cargo crate with an alternate type sub-shape, e.g. "iso_container_cargo".
-- @param #string TypeName Static type name (optional). If set, it will overwride even though TypeName is passed. this is only for the C-130J-30. Can be used with other TypeName for other modules.
-- @return #CTLD self
function CTLD:AddCratesCargoNoMove(Name,Templates,Type,NoCrates,PerCrateMass,Stock,SubCategory,DontShowInMenu,Location,UnitTypes,Category,TypeName,ShapeName,C130TypeName)
  self:T(self.lid .. " AddCratesCargoNoMove")
  if not self:_CheckTemplates(Templates) then
    self:E(self.lid .. "Crates Cargo for " .. Name .. " has missing template(s)!" )
    return self
  end
  self.CargoCounter = self.CargoCounter + 1
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,Templates,Type,false,false,NoCrates,nil,nil,PerCrateMass,Stock,SubCategory,DontShowInMenu,Location)
  cargo.NoMoveToZone = true
  if UnitTypes then
    cargo:AddUnitTypeName(UnitTypes)
  end
  cargo:SetStaticTypeAndShape("Cargos",self.basetype)
  if TypeName then
    cargo:SetStaticTypeAndShape(Category,TypeName,ShapeName)
  end
  cargo.C130TypeName = C130TypeName
  table.insert(self.Cargo_Crates,cargo)
  self.templateToCargoName = self.templateToCargoName or {}
  if type(Templates)=="table" then
    for _,t in pairs(Templates) do self.templateToCargoName[t] = Name end
  else
  self.templateToCargoName[Templates] = Name
  end
  self.nomovetozone_names = self.nomovetozone_names or {}
  self.nomovetozone_names[Name] = true
  if SubCategory and self.usesubcats ~= true then self.usesubcats=true end
  return self
end

--- User function - Add *generic* static-type loadable as cargo. This type will create cargo that needs to be loaded, moved and dropped.
-- @param #CTLD self
-- @param #string Name Unique name of this type of cargo as set in the mission editor (note: UNIT name!), e.g. "Ammunition-1".
-- @param #number Mass Mass in kg of each static in kg, e.g. 100.
-- @param #number Stock Number of groups in stock. Nil for unlimited.
-- @param #string SubCategory Name of sub-category (optional).
-- @param #boolean DontShowInMenu (optional) If set to "true" this won't show up in the menu.
-- @param Core.Zone#ZONE Location (optional) If set, the cargo item is **only** available here. Can be a #ZONE object or the name of a zone as #string.
-- @param #string UnitTypes Unit type names (optional). If set, only these unit types can pick up the cargo, e.g. "UH-1H" or {"UH-1H","OH58D"}.
-- @param #string DisplayName Display name shown in menus/messages (optional). Falls back to `Name`.
-- @return #CTLD_CARGO CargoObject
function CTLD:AddStaticsCargo(Name,Mass,Stock,SubCategory,DontShowInMenu,Location,UnitTypes,DisplayName)
  self:T(self.lid .. " AddStaticsCargo")
  self.CargoCounter = self.CargoCounter + 1
  local type = CTLD_CARGO.Enum.STATIC
  local template = STATIC:FindByName(Name,true):GetTypeName()
  local unittemplate = _DATABASE:GetStaticUnitTemplate(Name)
  local ResourceMap = nil
  if unittemplate and unittemplate.resourcePayload then
    ResourceMap = UTILS.DeepCopy(unittemplate.resourcePayload)
  end
  -- Crates are not directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,template,type,false,false,1,nil,nil,Mass,Stock,SubCategory,DontShowInMenu,Location)
  if UnitTypes then
    cargo:AddUnitTypeName(UnitTypes)
  end
  cargo:SetDisplayName(DisplayName or Name)
  cargo:SetStaticResourceMap(ResourceMap)
  table.insert(self.Cargo_Statics,cargo)
  if SubCategory and self.usesubcats ~= true then self.usesubcats=true end
  return cargo
end

--- User function - Add *generic* static-type loadable as cargo from a static **type name**.
-- This variant does **not** require a matching mission-editor static template.
-- @param #CTLD self
-- @param #string Name Unique cargo identifier for this type.
-- @param #string TypeName Static type name to spawn, e.g. "ammo_cargo", "iso_container_small".
-- @param #number Mass Mass in kg of each static in kg, e.g. 100.
-- @param #number Stock Number of groups in stock. Nil for unlimited.
-- @param #string SubCategory Name of sub-category (optional).
-- @param #boolean DontShowInMenu (optional) If set to "true" this won't show up in the menu.
-- @param Core.Zone#ZONE Location (optional) If set, the cargo item is **only** available here. Can be a #ZONE object or the name of a zone as #string.
-- @param #string UnitTypes Unit type names (optional). If set, only these unit types can pick up the cargo, e.g. "UH-1H" or {"UH-1H","OH58D"}.
-- @param #string Category Static category name (optional). Default is "Cargos".
-- @param #string ShapeName Static shape name (optional). If set, force a specific shape, e.g. "iso_container_small_cargo".
-- @param #table ResourceMap Resource map payload (optional) for static cargo.
-- @param #string DisplayName Display name shown in menus/messages (optional). Falls back to `Name`.
-- @return #CTLD_CARGO CargoObject
function CTLD:AddStaticsCargoFromType(Name,TypeName,Mass,Stock,SubCategory,DontShowInMenu,Location,UnitTypes,Category,ShapeName,ResourceMap,DisplayName)
  self:T(self.lid .. " AddStaticsCargoFromType")
  self.CargoCounter = self.CargoCounter + 1
  local type = CTLD_CARGO.Enum.STATIC
  local template = TypeName or self.basetype or "container_cargo"
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,template,type,false,false,1,nil,nil,Mass,Stock,SubCategory,DontShowInMenu,Location)
  if UnitTypes then
    cargo:AddUnitTypeName(UnitTypes)
  end
  cargo:SetStaticTypeAndShape(Category or "Cargos", template, ShapeName)
  cargo:SetDisplayName(DisplayName or Name)
  if ResourceMap then
    ResourceMap = UTILS.DeepCopy(ResourceMap)
  end
  cargo:SetStaticResourceMap(ResourceMap)
  table.insert(self.Cargo_Statics,cargo)
  if SubCategory and self.usesubcats ~= true then self.usesubcats=true end
  return cargo
end

--- User function - Get a *generic* static-type loadable as #CTLD_CARGO object.
-- @param #CTLD self
-- @param #string Name Unique Unit(!) name of this type of cargo as set in the mission editor (not: GROUP name!), e.g. "Ammunition-1".
-- @param #number Mass Mass in kg of each static in kg, e.g. 100.
-- @param #string DisplayName Display name shown in menus/messages (optional). Falls back to `Name`.
-- @return #CTLD_CARGO Cargo object
function CTLD:GetStaticsCargoFromTemplate(Name,Mass,DisplayName)
  self:T(self.lid .. " GetStaticsCargoFromTemplate")
  self.CargoCounter = self.CargoCounter + 1
  local type = CTLD_CARGO.Enum.STATIC
  local template = STATIC:FindByName(Name,true):GetTypeName()
  local unittemplate = _DATABASE:GetStaticUnitTemplate(Name)
  local ResourceMap = nil
  if unittemplate and unittemplate.resourcePayload then
    ResourceMap = UTILS.DeepCopy(unittemplate.resourcePayload)
  end
  -- Crates are not directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,template,type,false,false,1,nil,nil,Mass,1)
  cargo:SetDisplayName(DisplayName or Name)
  cargo:SetStaticResourceMap(ResourceMap)
  --table.insert(self.Cargo_Statics,cargo)
  return cargo
end

--- User function - Get a *generic* static-type loadable cargo from a static **type name**.
-- @param #CTLD self
-- @param #string Name Unique name of this type of cargo.
-- @param #string TypeName Static type name, e.g. "ammo_cargo", "iso_container_small".
-- @param #number Mass Mass in kg of each static in kg, e.g. 100.
-- @param #string Category Static category name (optional). Default is "Cargos".
-- @param #string ShapeName Static shape name (optional).
-- @param #table ResourceMap Resource map payload (optional) for static cargo.
-- @param #string DisplayName Display name shown in menus/messages (optional). Falls back to `Name`.
-- @return #CTLD_CARGO Cargo object
function CTLD:GetStaticsCargoFromType(Name,TypeName,Mass,Category,ShapeName,ResourceMap,DisplayName)
  self:T(self.lid .. " GetStaticsCargoFromType")
  self.CargoCounter = self.CargoCounter + 1
  local type = CTLD_CARGO.Enum.STATIC
  local template = TypeName or self.basetype or "container_cargo"
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,template,type,false,false,1,nil,nil,Mass,1)
  cargo:SetStaticTypeAndShape(Category or "Cargos", template, ShapeName)
  cargo:SetDisplayName(DisplayName or Name)
  if ResourceMap then
    ResourceMap = UTILS.DeepCopy(ResourceMap)
  end
  cargo:SetStaticResourceMap(ResourceMap)
  return cargo
end

--- User function - Add *generic* repair crates loadable as cargo. This type will create crates that need to be loaded, moved, dropped and built.
-- @param #CTLD self
-- @param #string Name Unique name of this type of cargo. E.g. "Humvee".
-- @param #string Template Template of VEHICLE or FOB cargo that this can repair. MUST be the same as given in `AddCratesCargo(..)`!
-- @param #CTLD_CARGO.Enum Type Type of cargo, here REPAIR.
-- @param #number NoCrates Number of crates needed to build this cargo.
-- @param #number PerCrateMass Mass in kg of each crate
-- @param #number Stock Number of groups in stock. Nil for unlimited.
-- @param #string SubCategory Name of the sub-category (optional).
-- @param #boolean DontShowInMenu (optional) If set to "true" this won't show up in the menu.
-- @param Core.Zone#ZONE Location (optional) If set, the cargo item is **only** available here. Can be a #ZONE object or the name of a zone as #string.
-- @param #string UnitTypes Unit type names (optional). If set, only these unit types can pick up the cargo, e.g. "UH-1H" or {"UH-1H","OH58D"}
-- @param #string Category Static category name (optional). If set, spawn cargo crate with an alternate category type, e.g. "Cargos".
-- @param #string TypeName Static type name (optional). If set, spawn cargo crate with an alternate type shape, e.g. "iso_container".
-- @param #string ShapeName Static shape name (optional). If set, spawn cargo crate with an alternate type sub-shape, e.g. "iso_container_cargo".
-- @return #CTLD self
function CTLD:AddCratesRepair(Name,Template,Type,NoCrates, PerCrateMass,Stock,SubCategory,DontShowInMenu,Location,UnitTypes,Category,TypeName,ShapeName)
  self:T(self.lid .. " AddCratesRepair")
  if not self:_CheckTemplates(Template) then
    self:E(self.lid .. "Repair Cargo for " .. Name .. " has a missing template!" )
    return self
  end
  self.CargoCounter = self.CargoCounter + 1
  -- Crates are not directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,Template,Type,false,false,NoCrates,nil,nil,PerCrateMass,Stock,SubCategory,DontShowInMenu,Location)
  if UnitTypes then
    cargo:AddUnitTypeName(UnitTypes)
  end
  cargo:SetStaticTypeAndShape("cargos",self.basetype)
  if TypeName then
    cargo:SetStaticTypeAndShape(Category,TypeName,ShapeName)
  end
  table.insert(self.Cargo_Crates,cargo)
  return self
end

--- User function - Add a #CTLD.CargoZoneType zone for this CTLD instance.
-- @param #CTLD self
-- @param #CTLD.CargoZone Zone Zone #CTLD.CargoZone describing the zone.
function CTLD:AddZone(Zone)
  self:T(self.lid .. " AddZone")
  local zone = Zone -- #CTLD.CargoZone
  if zone.type == CTLD.CargoZoneType.LOAD then
    table.insert(self.pickupZones,zone)
  elseif zone.type == CTLD.CargoZoneType.DROP then
    table.insert(self.dropOffZones,zone)
  elseif zone.type == CTLD.CargoZoneType.SHIP then
    table.insert(self.shipZones,zone)
  elseif zone.type == CTLD.CargoZoneType.BEACON then
    table.insert(self.droppedBeacons,zone)   
  else
    table.insert(self.wpZones,zone)
  end
  return self
end

--- User function - Activate Name #CTLD.CargoZone.Type ZoneType for this CTLD instance.
-- @param #CTLD self
-- @param #string Name Name of the zone to change in the ME.
-- @param #CTLD.CargoZoneType ZoneType Type of zone this belongs to.
-- @param #boolean NewState (Optional) Set to true to activate, false to switch off.
function CTLD:ActivateZone(Name,ZoneType,NewState)
  self:T(self.lid .. " ActivateZone")
  local newstate = true
  -- set optional in case we\'re deactivating
  if NewState ~= nil then
    newstate = NewState
  end  
  
  -- get correct table
  local table = {}
  if ZoneType == CTLD.CargoZoneType.LOAD then
    table = self.pickupZones
  elseif ZoneType == CTLD.CargoZoneType.DROP then
    table = self.dropOffZones
  elseif ZoneType == CTLD.CargoZoneType.SHIP then
    table = self.shipZones
  elseif ZoneType == CTLD.CargoZoneType.BEACON then
    table = self.droppedBeacons
  else
    table = self.wpZones
  end
  -- loop table
  for _,_zone in pairs(table) do
    local thiszone = _zone --#CTLD.CargoZone
    if thiszone.name == Name then
      thiszone.active = newstate
      break
    end
  end
  return self
end


--- User function - Deactivate Name #CTLD.CargoZoneType ZoneType for this CTLD instance.
-- @param #CTLD self
-- @param #string Name Name of the zone to change in the ME.
-- @param #CTLD.CargoZoneType ZoneType Type of zone this belongs to.
function CTLD:DeactivateZone(Name,ZoneType)
  self:T(self.lid .. " DeactivateZone")
  self:ActivateZone(Name,ZoneType,false)
  return self
end

--- (Internal) Function to obtain a valid FM frequency.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @return #CTLD.ZoneBeacon Beacon Beacon table.
function CTLD:_GetFMBeacon(Name)
  self:T(self.lid .. " _GetFMBeacon")
  local beacon = {} -- #CTLD.ZoneBeacon  
  if #self.FreeFMFrequencies <= 1 then
      self.FreeFMFrequencies = self.UsedFMFrequencies
      self.UsedFMFrequencies = {}
  end 
  --random
  local FM = table.remove(self.FreeFMFrequencies, math.random(#self.FreeFMFrequencies))
  table.insert(self.UsedFMFrequencies, FM)  
  beacon.name = Name
  beacon.frequency = FM / 1000000
  beacon.modulation = CTLD.RadioModulation.FM
  return beacon
end

--- (Internal) Function to obtain a valid UHF frequency.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @return #CTLD.ZoneBeacon Beacon Beacon table.
function CTLD:_GetUHFBeacon(Name)
  self:T(self.lid .. " _GetUHFBeacon")
  local beacon = {} -- #CTLD.ZoneBeacon  
  if #self.FreeUHFFrequencies <= 1 then
      self.FreeUHFFrequencies = self.UsedUHFFrequencies
      self.UsedUHFFrequencies = {}
  end 
  --random
  local UHF = table.remove(self.FreeUHFFrequencies, math.random(#self.FreeUHFFrequencies))
  table.insert(self.UsedUHFFrequencies, UHF)
  beacon.name = Name
  beacon.frequency = UHF / 1000000
  beacon.modulation = CTLD.RadioModulation.AM

  return beacon
end

--- (Internal) Function to obtain a valid VHF frequency.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @return #CTLD.ZoneBeacon Beacon Beacon table.
function CTLD:_GetVHFBeacon(Name)
  self:T(self.lid .. " _GetVHFBeacon")
  local beacon = {} -- #CTLD.ZoneBeacon
  if #self.FreeVHFFrequencies <= 3 then
      self.FreeVHFFrequencies = self.UsedVHFFrequencies
      self.UsedVHFFrequencies = {}
  end
  --get random
  local VHF = table.remove(self.FreeVHFFrequencies, math.random(#self.FreeVHFFrequencies))
  table.insert(self.UsedVHFFrequencies, VHF)
  beacon.name = Name
  beacon.frequency = VHF / 1000000
  beacon.modulation = CTLD.RadioModulation.FM
  return beacon
end


--- User function - Creates and adds a #CTLD.CargoZone zone for this CTLD instance.
--  Zones of type LOAD: Players load crates and troops here.  
--  Zones of type DROP: Players can drop crates here. Note that troops can be unloaded anywhere.  
--  Zone of type MOVE: Dropped troops and vehicles will start moving to the nearest zone of this type (also see options).  
-- @param #CTLD self
-- @param #string Name Name of this zone, as in Mission Editor.
-- @param #string Type Type of this zone, #CTLD.CargoZoneType
-- @param #number Color Smoke/Flare color e.g. #SMOKECOLOR.Red
-- @param #string Active Is this zone currently active?
-- @param #string HasBeacon Does this zone have a beacon if it is active?
-- @param #number Shiplength Length of Ship for shipzones
-- @param #number Shipwidth Width of Ship for shipzones
-- @return #CTLD self
function CTLD:AddCTLDZone(Name, Type, Color, Active, HasBeacon, Shiplength, Shipwidth)
  self:T(self.lid .. " AddCTLDZone")
  
  local zone = ZONE:FindByName(Name)
  if not zone and  Type ~= CTLD.CargoZoneType.SHIP then
    self:E(self.lid.."**** Zone does not exist: "..Name)
    return self
  end
  
  if Type == CTLD.CargoZoneType.SHIP then
  local Ship = UNIT:FindByName(Name)
  if not Ship then
      self:E(self.lid.."**** Ship does not exist: "..Name)
    return self
  end
  end

  local exists = true
  local ctldzone = self:GetCTLDZone(Name, Type) -- #CTLD.CargoZone
  if not ctldzone then
    exists = false
    ctldzone = {}
  end

  ctldzone.active = Active or false
  ctldzone.color = Color or SMOKECOLOR.Red
  ctldzone.name = Name or "NONE"
  ctldzone.type = Type or CTLD.CargoZoneType.MOVE -- #CTLD.CargoZoneType
  ctldzone.hasbeacon = HasBeacon or false
  
  if Type == CTLD.CargoZoneType.BEACON then
    self.droppedbeaconref[ctldzone.name] = zone:GetCoordinate()
    ctldzone.timestamp = timer.getTime()
  end
     
  if HasBeacon then
    ctldzone.fmbeacon = self:_GetFMBeacon(Name)
    ctldzone.uhfbeacon = self:_GetUHFBeacon(Name)
    ctldzone.vhfbeacon = self:_GetVHFBeacon(Name)
  else
    ctldzone.fmbeacon = nil
    ctldzone.uhfbeacon = nil
    ctldzone.vhfbeacon = nil
  end
  
  if Type == CTLD.CargoZoneType.SHIP then
   ctldzone.shiplength = Shiplength or 100
   ctldzone.shipwidth = Shipwidth or 10
  end

  if not exists then
    self:AddZone(ctldzone)
  end
  return self
end


--- User function - find #CTLD.CargoZone zone by name.
-- @param #CTLD self
-- @param #string Name Name of this zone.
-- @param #string Type Type of this zone, #CTLD.CargoZoneType
-- @return #CTLD.CargoZone self
function CTLD:GetCTLDZone(Name, Type)

  if Type == CTLD.CargoZoneType.LOAD then
    for _, z in pairs(self.pickupZones) do
        if z.name == Name then
            return z
        end
    end
  elseif Type == CTLD.CargoZoneType.DROP then
    for _, z in pairs(self.dropOffZones) do
        if z.name == Name then
            return z
        end
    end
  elseif Type == CTLD.CargoZoneType.SHIP then
    for _, z in pairs(self.shipZones) do
        if z.name == Name then
            return z
        end
    end
  elseif Type == CTLD.CargoZoneType.BEACON then
    for _, z in pairs(self.droppedBeacons) do
        if z.name == Name then
            return z
        end
    end
  else
    for _, z in pairs(self.wpZones) do
        if z.name == Name then
            return z
        end
    end
  end

  return nil
end

--- User function - Creates and adds a #CTLD.CargoZone zone for this CTLD instance from an Airbase or FARP name.
--  Zones of type LOAD: Players load crates and troops here.  
--  Zones of type DROP: Players can drop crates here. Note that troops can be unloaded anywhere.  
--  Zone of type MOVE: Dropped troops and vehicles will start moving to the nearest zone of this type (also see options).  
-- @param #CTLD self
-- @param #string AirbaseName Name of the Airbase, can be e.g. AIRBASE.Caucasus.Beslan or "Beslan". For FARPs, this will be the UNIT name.
-- @param #string Type Type of this zone, #CTLD.CargoZoneType
-- @param #number Color Smoke/Flare color e.g. #SMOKECOLOR.Red
-- @param #string Active Is this zone currently active?
-- @param #string HasBeacon Does this zone have a beacon if it is active?
-- @return #CTLD self
function CTLD:AddCTLDZoneFromAirbase(AirbaseName, Type, Color, Active, HasBeacon)
  self:T(self.lid .. " AddCTLDZoneFromAirbase")
  local AFB = AIRBASE:FindByName(AirbaseName)
  local name = AFB:GetZone():GetName()
  self:T(self.lid .. "AFB " .. AirbaseName .. " ZoneName " .. name)
  self:AddCTLDZone(name, Type, Color, Active, HasBeacon)
  return self
end

--- (Internal) Function to create a dropped beacon
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:DropBeaconNow(Unit)
  self:T(self.lid .. " DropBeaconNow")
  
  local ctldzone = {} -- #CTLD.CargoZone
  ctldzone.active = true
  ctldzone.color = math.random(0,4) -- random color
  ctldzone.name = "Beacon " .. math.random(1,10000)
  ctldzone.type = CTLD.CargoZoneType.BEACON -- #CTLD.CargoZoneType
  ctldzone.hasbeacon = true
   
  ctldzone.fmbeacon = self:_GetFMBeacon(ctldzone.name)
  ctldzone.uhfbeacon = self:_GetUHFBeacon(ctldzone.name)
  ctldzone.vhfbeacon = self:_GetVHFBeacon(ctldzone.name)
  ctldzone.timestamp = timer.getTime()
  
  self.droppedbeaconref[ctldzone.name] = Unit:GetCoordinate()
  
  self:AddZone(ctldzone)
  
  local FMbeacon = ctldzone.fmbeacon -- #CTLD.ZoneBeacon
  local VHFbeacon = ctldzone.vhfbeacon -- #CTLD.ZoneBeacon
  local UHFbeacon = ctldzone.uhfbeacon -- #CTLD.ZoneBeacon
  local Name = ctldzone.name
  local FM = FMbeacon.frequency  -- MHz
  local VHF = VHFbeacon.frequency * 1000 -- KHz
  local UHF = UHFbeacon.frequency  -- MHz
  local text = string.format("Dropped %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ", Name, FM, VHF, UHF)
  
  self:_SendMessage(text,15,false,Unit:GetGroup())
  
  return self
end

--- (Internal) Housekeeping dropped beacons.
-- @param #CTLD self
-- @return #CTLD self
function CTLD:CheckDroppedBeacons()
  self:T(self.lid .. " CheckDroppedBeacons")
  
  -- check for timeout
  local timeout = self.droppedbeacontimeout or 600
  local livebeacontable = {}
  
  for _,_beacon in pairs (self.droppedBeacons) do
    local beacon = _beacon -- #CTLD.CargoZone
    if not beacon.timestamp then beacon.timestamp = timer.getTime() + timeout end
    local T0 = beacon.timestamp 
    if timer.getTime() - T0 > timeout then
      local name = beacon.name
      self.droppedbeaconref[name] = nil
      _beacon = nil
    else
      table.insert(livebeacontable,beacon)
    end
  end
  
  self.droppedBeacons = nil
  self.droppedBeacons = livebeacontable
  
  return self
end

--- (Internal) Function to show list of radio beacons
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
function CTLD:_ListRadioBeacons(Group, Unit)
  self:T(self.lid .. " _ListRadioBeacons")
  local report = REPORT:New("Active Zone Beacons")
  report:Add("------------------------------------------------------------")
  local zones = {[1] = self.pickupZones, [2] = self.wpZones, [3] = self.dropOffZones, [4] = self.shipZones, [5] = self.droppedBeacons}
  for i=1,5 do
    for index,cargozone in pairs(zones[i]) do
      -- Get Beacon object from zone
      local czone = cargozone -- #CTLD.CargoZone
      if czone.active and czone.hasbeacon then
        local FMbeacon = czone.fmbeacon -- #CTLD.ZoneBeacon
        local VHFbeacon = czone.vhfbeacon -- #CTLD.ZoneBeacon
        local UHFbeacon = czone.uhfbeacon -- #CTLD.ZoneBeacon
        local Name = czone.name
        local FM = FMbeacon.frequency  -- MHz
        local VHF = VHFbeacon.frequency * 1000 -- KHz
        local UHF = UHFbeacon.frequency  -- MHz
        report:AddIndent(string.format(" %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ", Name, FM, VHF, UHF),"|")
      end
    end
  end
  if report:GetCount() == 1 then
    report:Add("        N O N E")
  end
  report:Add("------------------------------------------------------------")
  self:_SendMessage(report:Text(), 30, true, Group) 
  return self
end

--- (Internal) Add radio beacon to zone. Runs 30 secs.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @param #string Sound Name of soundfile.
-- @param #number Mhz Frequency in Mhz.
-- @param #number Modulation Modulation AM or FM.
-- @param #boolean IsShip If true zone is a ship.
-- @param #boolean IsDropped If true, this isn't a zone but a dropped beacon
function CTLD:_AddRadioBeacon(Name, Sound, Mhz, Modulation, IsShip, IsDropped)
  self:T(self.lid .. " _AddRadioBeacon")
  local Zone = nil
  if IsShip then
    Zone = UNIT:FindByName(Name)
  elseif IsDropped then
    Zone = self.droppedbeaconref[Name]
  else
    Zone = ZONE:FindByName(Name)
    if not Zone then
      Zone = AIRBASE:FindByName(Name):GetZone()
    end
  end
  local Sound = Sound or "beacon.ogg"
  if Zone then
  if IsDropped then
    local ZoneCoord = Zone
    local ZoneVec3 = ZoneCoord:GetVec3() or {x=0,y=0,z=0}
    local Frequency = Mhz * 1000000 -- Freq in Hertz
    local Sound =  self.RadioPath..Sound
    trigger.action.radioTransmission(Sound, ZoneVec3, Modulation, false, Frequency, 1000, Name..math.random(1,10000)) -- Beacon in MP only runs for 30secs straight
    self:T2(string.format("Beacon added | Name = %s | Sound = %s | Vec3 = %d %d %d | Freq = %f | Modulation = %d (0=AM/1=FM)",Name,Sound,ZoneVec3.x,ZoneVec3.y,ZoneVec3.z,Mhz,Modulation))
  else
    local ZoneCoord = Zone:GetCoordinate()
    local ZoneVec3 = ZoneCoord:GetVec3() or {x=0,y=0,z=0}
    local Frequency = Mhz * 1000000 -- Freq in Hert
    local Sound =  self.RadioPath..Sound
    trigger.action.radioTransmission(Sound, ZoneVec3, Modulation, false, Frequency, 1000, Name..math.random(1,10000)) -- Beacon in MP only runs for 30secs straightt
    self:T2(string.format("Beacon added | Name = %s | Sound = %s | Vec3 = {x=%d, y=%d, z=%d} | Freq = %f | Modulation = %d (0=AM/1=FM)",Name,Sound,ZoneVec3.x,ZoneVec3.y,ZoneVec3.z,Mhz,Modulation))
    end
  else
  self:E(self.lid.."***** _AddRadioBeacon: Zone does not exist: "..Name)
  end
  return self
end

--- Set folder path where the CTLD sound files are located **within you mission (miz) file**.
-- The default path is "l10n/DEFAULT/" but sound files simply copied there will be removed by DCS the next time you save the mission.
-- However, if you create a new folder inside the miz file, which contains the sounds, it will not be deleted and can be used.
-- @param #CTLD self
-- @param #string FolderPath The path to the sound files, e.g. "CTLD_Soundfiles/".
-- @return #CTLD self
function CTLD:SetSoundfilesFolder( FolderPath )
  self:T(self.lid .. " SetSoundfilesFolder")
  -- Check that it ends with /
  if FolderPath then
      local lastchar = string.sub( FolderPath, -1 )
      if lastchar ~= "/" then
          FolderPath = FolderPath .. "/"
      end
  end

  -- Folderpath.
  self.RadioPath = FolderPath

  -- Info message.
  self:I( self.lid .. string.format( "Setting sound files folder to: %s", self.RadioPath ) )

  return self
end

--- (Internal) Function to refresh radio beacons
-- @param #CTLD self
function CTLD:_RefreshRadioBeacons()
  self:T(self.lid .. " _RefreshRadioBeacons")

  local zones = {[1] = self.pickupZones, [2] = self.wpZones, [3] = self.dropOffZones, [4] = self.shipZones, [5] = self.droppedBeacons}
  for i=1,5 do
    local IsShip = false
    if i == 4 then IsShip = true end
    local IsDropped = false
    if i == 5 then IsDropped = true end
    for index,cargozone in pairs(zones[i]) do
      -- Get Beacon object from zone
      local czone = cargozone -- #CTLD.CargoZone
      local Sound = self.RadioSound
      local Silent = self.RadioSoundFC3 or self.RadioSound
      if czone.active and czone.hasbeacon then
        local FMbeacon = czone.fmbeacon -- #CTLD.ZoneBeacon
        local VHFbeacon = czone.vhfbeacon -- #CTLD.ZoneBeacon
        local UHFbeacon = czone.uhfbeacon -- #CTLD.ZoneBeacon
        local Name = czone.name
        local FM = FMbeacon.frequency  -- MHz
        local VHF = VHFbeacon.frequency -- KHz
        local UHF = UHFbeacon.frequency  -- MHz   
        self:_AddRadioBeacon(Name,Sound,FM, CTLD.RadioModulation.FM, IsShip, IsDropped)
        self:_AddRadioBeacon(Name,Sound,VHF,CTLD.RadioModulation.AM, IsShip, IsDropped)
        self:_AddRadioBeacon(Name,Silent,UHF,CTLD.RadioModulation.AM, IsShip, IsDropped)
      end
    end
  end
  return self
end

--- (Internal) Function to see if a unit is in a specific zone type.
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit Unit
-- @param #CTLD.CargoZoneType Zonetype Zonetype
-- @return #boolean Outcome Is in zone or not
-- @return #string name Closest zone name
-- @return Core.Zone#ZONE zone Closest Core.Zone#ZONE object
-- @return #number distance Distance to closest zone
-- @return #number width Radius of zone or width of ship
function CTLD:IsUnitInZone(Unit,Zonetype)
  self:T(self.lid .. " IsUnitInZone")
  self:T(Zonetype)
  local unitname = Unit:GetName()
  local zonetable = {}
  local outcome = false
  if Zonetype == CTLD.CargoZoneType.LOAD then
    zonetable = self.pickupZones -- #table
  elseif Zonetype == CTLD.CargoZoneType.DROP then
    zonetable = self.dropOffZones -- #table
  elseif Zonetype == CTLD.CargoZoneType.SHIP then
    zonetable = self.shipZones -- #table
  else 
   zonetable = self.wpZones -- #table
  end
  --- now see if we\'re in
  local zonecoord = nil
  local colorret = nil
  local maxdist = 1000000 -- 100km
  local zoneret = nil
  local zonewret = nil
  local zonenameret = nil
  local unitcoord = Unit:GetCoordinate()
  local unitVec2 = unitcoord:GetVec2()
  for _,_cargozone in pairs(zonetable) do
    local czone = _cargozone -- #CTLD.CargoZone
    local zonename = czone.name
    local active = czone.active
    local color = czone.color
    local zone = nil
    local zoneradius = 100
    local zonewidth = 20
    if Zonetype == CTLD.CargoZoneType.SHIP then
      self:T("Checking Type Ship: "..zonename)
      local ZoneUNIT = UNIT:FindByName(zonename)
      if not ZoneUNIT then return false end
      zonecoord = ZoneUNIT:GetCoordinate()
      zoneradius = czone.shiplength
      zonewidth = czone.shipwidth
      zone = ZONE_UNIT:New( ZoneUNIT:GetName(), ZoneUNIT, zoneradius/2)
    elseif ZONE:FindByName(zonename) then
      zone = ZONE:FindByName(zonename)
      self:T("Checking Zone: "..zonename)
      zonecoord = zone:GetCoordinate()
      --zoneradius = 1500
      zonewidth = zoneradius
    elseif AIRBASE:FindByName(zonename) then
      zone = AIRBASE:FindByName(zonename):GetZone()
      self:T("Checking Zone: "..zonename)
      zonecoord = zone:GetCoordinate()
      zoneradius = 2000
      zonewidth = zoneradius
    end
    local distance = self:_GetDistance(zonecoord,unitcoord)
    self:T("Distance Zone: "..distance)
    self:T("Zone Active: "..tostring(active))
    if (zone:IsVec2InZone(unitVec2) or Zonetype == CTLD.CargoZoneType.MOVE) and active == true and distance < maxdist then 
      outcome = true
      maxdist = distance
      zoneret = zone 
      zonenameret = zonename
      zonewret = zonewidth
      colorret = color 
    end
  end
  if Zonetype == CTLD.CargoZoneType.SHIP then
    return outcome, zonenameret, zoneret, maxdist, zonewret
  else
    return outcome, zonenameret, zoneret, maxdist
  end
end

--- User function - Drop a smoke or flare at current location.
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit The Unit.
-- @param #boolean Flare If true, flare instead.
-- @param #number SmokeColor Color enumerator for smoke, e.g. SMOKECOLOR.Red
function CTLD:SmokePositionNow(Unit, Flare, SmokeColor)
  self:T(self.lid .. " SmokePositionNow")
  local Smokecolor = self.SmokeColor or SMOKECOLOR.Red
  if SmokeColor then 
    Smokecolor = SmokeColor
  end
  local FlareColor = self.FlareColor or FLARECOLOR.Red
  -- table of #CTLD.CargoZone table
  local unitcoord = Unit:GetCoordinate() -- Core.Point#COORDINATE
  local Group = Unit:GetGroup()
  if Flare then
    unitcoord:Flare(FlareColor, 90)
  else
    local height = unitcoord:GetLandHeight() + 2
    unitcoord.y = height
    unitcoord:Smoke(Smokecolor)
  end
  return self
end

--- User function - Start smoke/flare in a zone close to the Unit.
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit The Unit.
-- @param #boolean Flare If true, flare instead.
function CTLD:SmokeZoneNearBy(Unit, Flare)
  self:T(self.lid .. " SmokeZoneNearBy")
  -- table of #CTLD.CargoZone table
  local unitcoord = Unit:GetCoordinate()
  local Group = Unit:GetGroup()
  local smokedistance = self.smokedistance
  local smoked = false
  local zones = {[1] = self.pickupZones, [2] = self.wpZones, [3] = self.dropOffZones, [4] = self.shipZones}
  for i=1,4 do
    for index,cargozone in pairs(zones[i]) do
      local CZone = cargozone --#CTLD.CargoZone
      local zonename = CZone.name
      local zone = nil -- Core.Zone#ZONE_RADIUS
      local airbasezone = false
      if i == 4 then
        zone = UNIT:FindByName(zonename)
      else
        zone = ZONE:FindByName(zonename)
        if not zone then
          zone = AIRBASE:FindByName(zonename):GetZone()
          airbasezone = true
        end
      end
      local zonecoord = zone:GetCoordinate()
      -- Avoid smoke/flares on runways
      if (i==1 or 1==3) and airbasezone==true and zone:IsInstanceOf("ZONE_BASE") then
        zonecoord = zone:GetRandomCoordinate(inner,outer,{land.SurfaceType.LAND})
      end
    if zonecoord then
      local active = CZone.active
      local color = CZone.color
      local distance = self:_GetDistance(zonecoord,unitcoord)
      if distance < smokedistance and active then
        -- smoke zone since we\'re nearby
        if not Flare then 
          zonecoord:Smoke(color or SMOKECOLOR.White)
        else
          if color == SMOKECOLOR.Blue then color = FLARECOLOR.White end
          zonecoord:Flare(color or FLARECOLOR.White)
        end
        local txt = "smoking"
        if Flare then txt = "flaring" end
        self:_SendMessage(string.format("Roger, %s zone %s!",txt, zonename), 10, false, Group)
        smoked = true
      end
     end
    end
  end
  if not smoked then
    local distance = UTILS.MetersToNM(self.smokedistance)
    self:_SendMessage(string.format("Negative, need to be closer than %dnm to a zone!",distance), 10, false, Group)
  end
    return self 
end

  --- User - Function to add/adjust unittype capabilities.
  -- @param #CTLD self
  -- @param #string Unittype The unittype to adjust. If passed as Wrapper.Unit#UNIT, it will search for the unit in the mission.
  -- @param #boolean Cancrates Unit can load crates. Default false.
  -- @param #boolean Cantroops Unit can load troops. Default false.
  -- @param #number Cratelimit Unit can carry number of crates. Default 0.
  -- @param #number Trooplimit Unit can carry number of troops. Default 0.
  -- @param #number Length Unit lenght (in metres) for the load radius. Default 20.
  -- @param #number Maxcargoweight Maxmimum weight in kgs this helo can carry. Default 500.
  function CTLD:SetUnitCapabilities(Unittype, Cancrates, Cantroops, Cratelimit, Trooplimit, Length, Maxcargoweight)
    self:T(self.lid .. " UnitCapabilities")
    local unittype =  nil
    local unit = nil
    if type(Unittype) == "string" then
      unittype = Unittype
    elseif type(Unittype) == "table" and Unittype.ClassName and Unittype:IsInstanceOf("UNIT") then
      unittype = Unittype:GetTypeName()
    else
      return self
    end
    local length = 20
    local maxcargo = 500
    local existingcaps = self.UnitTypeCapabilities[unittype] -- #CTLD.UnitTypeCapabilities
    if existingcaps then
      length = existingcaps.length or 20
      maxcargo = existingcaps.cargoweightlimit or 500
    end
    -- set capabilities
    local capabilities = {} -- #CTLD.UnitTypeCapabilities
    capabilities.type = unittype
    capabilities.crates = Cancrates or false
    capabilities.troops = Cantroops or false
    capabilities.cratelimit = Cratelimit or  0
    capabilities.trooplimit = Trooplimit or 0
    capabilities.length = Length or length
    capabilities.cargoweightlimit = Maxcargoweight or maxcargo
    self.UnitTypeCapabilities[unittype] = capabilities
    return self
  end
  
  --- User - Function to add onw SET_GROUP Set-up for pilot filtering and assignment.
  -- Needs to be set before starting the CTLD instance.
  -- @param #CTLD self
  -- @param Core.Set#SET_GROUP Set The SET_GROUP object created by the mission designer/user to represent the CTLD pilot groups.
  -- @return #CTLD self 
  function CTLD:SetOwnSetPilotGroups(Set)
    self.UserSetGroup = Set
    return self
  end
  
  --- [Deprecated] - Function to add/adjust unittype capabilities. Has been replaced with `SetUnitCapabilities()` - pls use the new one going forward!
  -- @param #CTLD self
  -- @param #string Unittype The unittype to adjust. If passed as Wrapper.Unit#UNIT, it will search for the unit in the mission.
  -- @param #boolean Cancrates Unit can load crates. Default false.
  -- @param #boolean Cantroops Unit can load troops. Default false.
  -- @param #number Cratelimit Unit can carry number of crates. Default 0.
  -- @param #number Trooplimit Unit can carry number of troops. Default 0.
  -- @param #number Length Unit lenght (in metres) for the load radius. Default 20.
  -- @param #number Maxcargoweight Maxmimum weight in kgs this helo can carry. Default 500.
  function CTLD:UnitCapabilities(Unittype, Cancrates, Cantroops, Cratelimit, Trooplimit, Length, Maxcargoweight)
    self:I(self.lid.."This function been replaced with `SetUnitCapabilities()` - pls use the new one going forward!")
    self:SetUnitCapabilities(Unittype, Cancrates, Cantroops, Cratelimit, Trooplimit, Length, Maxcargoweight)
    return self
  end
  
  
  --- (Internal) Check if a unit is hovering *in parameters*.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:IsCorrectHover(Unit)
    self:T(self.lid .. " IsCorrectHover")
    if self:IsFixedWing(Unit) then return false end -- FW cannot hover
    local outcome = false
    -- see if we are in air and within parameters.
    if self:IsUnitInAir(Unit) then
      -- get speed and height
      local uspeed = Unit:GetVelocityMPS()
      local uheight = Unit:GetHeight()
      local ucoord = Unit:GetCoordinate()
      if not ucoord then
        return false
      end
      local gheight = ucoord:GetLandHeight()
      local aheight = uheight - gheight -- height above ground
      local maxh = self.maximumHoverHeight -- 15
      local minh =  self.minimumHoverHeight -- 5
      local mspeed = 2 -- 2 m/s
      if (uspeed <= mspeed) and (aheight <= maxh) and (aheight >= minh)  then 
        -- yep within parameters
        outcome = true
      end
    end
    return outcome
  end
  
    --- (Internal) Check if a Hercules is flying *in parameters* for air drops.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:IsCorrectFlightParameters(Unit)
    self:T(self.lid .. " IsCorrectFlightParameters")
    local outcome = false
    -- see if we are in air and within parameters.
    if self:IsUnitInAir(Unit) then
      -- get speed and height
      local uspeed = Unit:GetVelocityMPS()
      local uheight = Unit:GetHeight()
      local ucoord = Unit:GetCoordinate()
      if not ucoord then
        return false
      end
      local gheight = ucoord:GetLandHeight()
      local aheight = uheight - gheight -- height above ground
      local minh = self.FixedMinAngels-- 1500m
      local maxh =  self.FixedMaxAngels -- 5000m
      local maxspeed =  self.FixedMaxSpeed -- 77 mps
      -- DONE: TEST - Speed test for Herc, should not be above 280kph/150kn
      local kmspeed = uspeed * 3.6
      local knspeed = kmspeed / 1.86
      self:T(string.format("%s Unit parameters: at %dm AGL with %dmps | %dkph | %dkn",self.lid,aheight,uspeed,kmspeed,knspeed))
      if (aheight <= maxh) and (aheight >= minh) and (uspeed <= maxspeed) then 
        -- yep within parameters
        outcome = true
      end
    end
    return outcome
  end
  
  --- (Internal) List if a unit is hovering *in parameters*.
  -- @param #CTLD self
  -- @param Wrapper.Group#GROUP Group
  -- @param Wrapper.Unit#UNIT Unit
  function CTLD:_ShowHoverParams(Group,Unit)
    local inhover = self:IsCorrectHover(Unit)
    local htxt = "true"
    if not inhover then htxt = "false" end
    local text = ""
    if _SETTINGS:IsMetric() then
      text = string.format("Hover parameters (autoload/drop):\n - Min height %dm \n - Max height %dm \n - Max speed 2mps \n - In parameter: %s", self.minimumHoverHeight, self.maximumHoverHeight, htxt)
    else
      local minheight = UTILS.MetersToFeet(self.minimumHoverHeight)
      local maxheight = UTILS.MetersToFeet(self.maximumHoverHeight)
      text = string.format("Hover parameters (autoload/drop):\n - Min height %dft \n - Max height %dft \n - Max speed 6ftps \n - In parameter: %s", minheight, maxheight, htxt)
    end
    self:_SendMessage(text, 10, false, Group)
    return self
  end
  
    --- (Internal) List if a Herc unit is flying *in parameters*.
  -- @param #CTLD self
  -- @param Wrapper.Group#GROUP Group
  -- @param Wrapper.Unit#UNIT Unit
  function CTLD:_ShowFlightParams(Group,Unit)
    local inhover = self:IsCorrectFlightParameters(Unit)
    local htxt = "true"
    if not inhover then htxt = "false" end
    local text = ""
    if _SETTINGS:IsImperial() then
      local minheight = UTILS.MetersToFeet(self.FixedMinAngels)
      local maxheight = UTILS.MetersToFeet(self.FixedMaxAngels)
      text = string.format("Flight parameters (airdrop):\n - Min height %dft \n - Max height %dft \n - In parameter: %s", minheight, maxheight, htxt)
    else
      local minheight = self.FixedMinAngels
      local maxheight = self.FixedMaxAngels
      text = string.format("Flight parameters (airdrop):\n - Min height %dm \n - Max height %dm \n - In parameter: %s", minheight, maxheight, htxt)
    end
    self:_SendMessage(text, 10, false, Group)
    return self
  end
    
  --- (Internal) Check if a unit is in a load zone and is hovering in parameters.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:CanHoverLoad(Unit)
    self:T(self.lid .. " CanHoverLoad")
    if self:IsFixedWing(Unit) then return false end
    local outcome = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD) and self:IsCorrectHover(Unit)
    if not outcome then
      outcome = self:IsUnitInZone(Unit,CTLD.CargoZoneType.SHIP) --and self:IsCorrectHover(Unit)
    end
    return outcome
  end
  
  --- (Internal) Check if a unit is above ground.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:IsUnitInAir(Unit)
    -- get speed and height
    local minheight = self.minimumHoverHeight
    if self.enableFixedWing and self:IsFixedWing(Unit) then
      minheight = 5.1 -- herc is 5m AGL on the ground
    end
    local uheight = Unit:GetHeight()
    local ucoord = Unit:GetCoordinate()
    if not ucoord then
      return false
    end
    local gheight = ucoord:GetLandHeight()
    local aheight = uheight - gheight -- height above ground
    if aheight >= minheight then
      return true
    else
      return false
    end
  end
  
  --- (Internal) Autoload if we can do crates, have capacity free and are in a load zone.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #CTLD self
  function CTLD:AutoHoverLoad(Unit)
    self:T(self.lid .. " AutoHoverLoad")
    -- get capabilities and current load
    local unittype = Unit:GetTypeName()
    local unitname = Unit:GetName()
    local Group = Unit:GetGroup()
    local capabilities = self:_GetUnitCapabilities(Unit) -- #CTLD.UnitTypeCapabilities
    local cancrates = capabilities.crates -- #boolean
    local cratelimit = capabilities.cratelimit -- #number
    if cancrates then
      -- get load
      local numberonboard = 0
      local loaded = {}
      if self.Loaded_Cargo[unitname] then
        loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
        numberonboard = loaded.Cratesloaded or 0
      end
      local load = cratelimit - numberonboard
      local canload = self:CanHoverLoad(Unit)
      if canload and load > 0 then
        self:_LoadCratesNearby(Group,Unit)
      end
    end
    return self
  end
  
  --- (Internal) Run through all pilots and see if we autoload.
  -- @param #CTLD self
  -- @return #CTLD self
  function CTLD:CheckAutoHoverload()
    if self.hoverautoloading then
      for _,_pilot in pairs (self.CtldUnits) do
        local Unit = UNIT:FindByName(_pilot)
        if self:CanHoverLoad(Unit) then self:AutoHoverLoad(Unit) end
      end
    end
    return self
  end
  
  --- (Internal) Run through DroppedTroops and capture alive units
  -- @param #CTLD self
  -- @return #CTLD self
  function CTLD:CleanDroppedTroops()
    -- Troops
    local troops = self.DroppedTroops
    local newtable = {}
    for _index, _group in pairs (troops) do
      self:T({_group.ClassName})
      if _group and _group.ClassName == "GROUP" then
        if _group:IsAlive() then
          newtable[_index] = _group
        end
      end
    end
    self.DroppedTroops = newtable
    -- Engineers
    local engineers = self.EngineersInField
    local engtable = {}
    for _index, _group in pairs (engineers) do
      self:T({_group.ClassName})
      if _group and _group:IsNotStatus("Stopped") then
        engtable[_index] = _group
      end
    end
    self.EngineersInField = engtable
    return self
  end
  
  --- User - Count both the stock and groups in the field for available cargo types. Counts only limited cargo items and only troops and vehicle/FOB crates!
  -- @param #CTLD self
  -- @param #boolean Restock If true, restock the cargo and troop items.
  -- @param #number Threshold Percentage below which to restock, used in conjunction with Restock (must be true). Defaults to 75 (percent).
  -- @return #table Table A table of contents with numbers.
  -- @usage
  --      The index is the unique cargo name.
  --      Each entry in the returned table contains a table with the following entries:
  --      
  --      {
  --          Stock0 -- number of original stock when the cargo entry was created.
  --          Stock -- number of currently available stock.
  --          StockR -- relative number of available stock, e.g. 75 (percent).
  --          Infield -- number of groups alive in the field of this kind.
  --          Inhelo -- number of troops/crates in any helo alive. Can be with decimals < 1 if e.g. you have cargo that need 4 crates, but you have 2 loaded.
  --          Sum -- sum is stock + infield + inhelo.
  --          GenericCargo -- this filed holds the generic CTLD_CARGO object which drives the available stock. Only populated if Restock is true.
  --        }
  function CTLD:_CountStockPlusInHeloPlusAliveGroups(Restock,Threshold)
    local Troopstable = {}
    for _id, _cargo in pairs(self.Cargo_Crates) do
      local generic = _cargo
      local genname = generic:GetName()
      if generic and generic:GetStock0() > 0 and not Troopstable[genname] then 
        Troopstable[genname] = {
          Stock0 = generic:GetStock0(),
          Stock = generic:GetStock(),
          StockR = generic:GetRelativeStock(),
          Infield = 0,
          Inhelo = 0,
          CratesInfield = 0,
          Sum = generic:GetStock(),
        }
        if Restock == true then
          Troopstable[genname].GenericCargo = generic
        end
      end
    end
    for _id,_unit in pairs(self.C130GetUnits or {}) do
      local genname = _unit.Name
      local stock0  = _unit.Stock0 or 0
      if stock0 > 0 and not Troopstable[genname] then
        local stock = _unit.Stock or 0
        local rel   = stock0 > 0 and math.floor((stock/stock0)*100) or 100
        Troopstable[genname] = {
          Stock0 = stock0,
          Stock = stock,
          StockR = rel,
          Infield = 0,
          Inhelo = 0,
          CratesInfield = 0,
          Sum = stock,
        }
      end
    end
    for _id, _cargo in pairs(self.Cargo_Troops) do
      local generic = _cargo
      local genname = generic:GetName()
      if generic and generic:GetStock0() > 0 and not Troopstable[genname] then        
        Troopstable[genname] = {
          Stock0 = generic:GetStock0(),
          Stock = generic:GetStock(),
          StockR = generic:GetRelativeStock(),
          Infield = 0,
          Inhelo = 0,
          CratesInfield = 0,
          Sum = generic:GetStock(),
        }
        if Restock == true then
          Troopstable[genname].GenericCargo = generic
        end
      end
    end
    for _index, _group in pairs(self.DroppedTroops) do
      if _group and _group:IsAlive() then
        self:T("Looking at " .. _group:GetName() .. " in the field")
        local generic = self:GetGenericCargoObjectFromGroupName(_group:GetName())
        if generic then 
          local genname = generic:GetName()
          self:T("Found Generic " .. genname .. " in the field. Adding.")
          if generic:GetStock0() > 0 then
            Troopstable[genname].Infield = Troopstable[genname].Infield + 1
            Troopstable[genname].Sum = Troopstable[genname].Infield + Troopstable[genname].Stock + Troopstable[genname].Inhelo
          end
        else
          local gname = _group:GetName()
          local uName = nil
          for _,cfg in pairs(self.C130GetUnits or {}) do
            local templ = cfg.Templates or {}
            if type(templ) == "string" then
              templ = {templ}
            end
            for _,tName in pairs(templ) do
              if string.find(gname,tName,1,true) then
                uName = cfg.Name
                break
              end
            end
            if uName then break end
          end
          if uName and Troopstable[uName] then
            self:T("Found C-130 unit " .. uName .. " in the field. Adding.")
            Troopstable[uName].Infield = Troopstable[uName].Infield + 1
            Troopstable[uName].Sum = Troopstable[uName].Infield + Troopstable[uName].Stock + Troopstable[uName].Inhelo
          else
            self:E(self.lid .. "Group without Cargo Generic: " .. _group:GetName())
          end
        end
      end
    end
    for _unitname, _loaded in pairs(self.Loaded_Cargo) do
      local _unit = UNIT:FindByName(_unitname)
      if _unit and _unit:IsAlive() then
        local unitname = _unit:GetName()
        local loadedcargo = self.Loaded_Cargo[unitname].Cargo or {}
        for _, _cgo in pairs(loadedcargo) do
          local cargo = _cgo
          local type = cargo.CargoType
          local gname = cargo:GetName()
          local gcargo = self:_FindCratesCargoObject(gname) or self:_FindTroopsCargoObject(gname)
          self:T("Looking at " .. gname .. " in the helo - type = "..tostring(type))
          if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS or type == CTLD_CARGO.Enum.VEHICLE or type == CTLD_CARGO.Enum.FOB) then
            if gcargo and gcargo:GetStock0() > 0 then
              self:T("Adding " .. gname .. " in the helo - type = "..tostring(type))
              if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) then
                Troopstable[gname].Inhelo = Troopstable[gname].Inhelo + 1
              end
              if (type == CTLD_CARGO.Enum.VEHICLE or type == CTLD_CARGO.Enum.FOB) then
                local counting = gcargo.CratesNeeded
                local added = 1
                if counting > 1 then
                  added = added / counting
                end
                Troopstable[gname].Inhelo = Troopstable[gname].Inhelo + added
              end
              Troopstable[gname].Sum = Troopstable[gname].Infield + Troopstable[gname].Stock + Troopstable[gname].Inhelo + Troopstable[gname].CratesInfield
            end
          end
        end
      end
    end 
    if self.Spawned_Cargo then
      -- First pass: just add fractional amounts for each crate on the ground
      for i = #self.Spawned_Cargo, 1, -1 do
        local cargo = self.Spawned_Cargo[i]
        if cargo and cargo:GetPositionable() and cargo:GetPositionable():IsAlive() then
          local genname = cargo:GetName()
          local gcargo  = self:_FindCratesCargoObject(genname)
          if Troopstable[genname] and gcargo and gcargo:GetStock0() > 0 then
            local needed = gcargo.CratesNeeded or 1
            local added  = 1
            if needed > 1 then
              added = added / needed
            end
            Troopstable[genname].CratesInfield = Troopstable[genname].CratesInfield + added
            Troopstable[genname].Sum = Troopstable[genname].Infield + Troopstable[genname].Stock
                                     + Troopstable[genname].Inhelo + Troopstable[genname].CratesInfield
          end
        end
      end
      for i = #self.Spawned_Cargo, 1, -1 do
        local cargo = self.Spawned_Cargo[i]
        if cargo and cargo:GetPositionable() and cargo:GetPositionable():IsAlive() then
          local genname = cargo:GetName()
          if Troopstable[genname] then
            if Troopstable[genname].Inhelo == 0 and Troopstable[genname].CratesInfield < 1 then
              Troopstable[genname].CratesInfield = 0
              Troopstable[genname].Sum = Troopstable[genname].Stock
              cargo:GetPositionable():Destroy(false)
              table.remove(self.Spawned_Cargo, i)
              local leftover = Troopstable[genname].Stock0 - (Troopstable[genname].Infield + Troopstable[genname].Inhelo + Troopstable[genname].CratesInfield)
              if leftover < Troopstable[genname].Stock then
                Troopstable[genname].Stock = leftover
              end
              Troopstable[genname].Sum = Troopstable[genname].Stock + Troopstable[genname].Infield + Troopstable[genname].Inhelo + Troopstable[genname].CratesInfield
            end
          end
        end
      end
    end
      if Restock == true then
        local threshold = Threshold or 75
        for _name,_data in pairs(Troopstable) do
          if _data.StockR and _data.StockR < threshold then
            if _data.GenericCargo then
              _data.GenericCargo:SetStock(_data.Stock0) -- refill to start level
            end
          end
        end
      end
    return Troopstable
  end
  
--- User - function to add stock of a certain units type
-- @param #CTLD self
-- @param #string Name Name as defined in the generic unit entry.
-- @param #number Number Number of units/groups to add.
-- @return #CTLD self
function CTLD:AddStockUnits(Name, Number)
  local name = Name or "none"
  local number = Number or 1
  local units = self.C130GetUnits or {}
  for _id,_unit in pairs(units) do
    if _unit.Name == name then
      local stock = _unit.Stock
      if stock == nil or stock == -1 then
        _unit.Stock = -1
      else
        _unit.Stock = stock + number
      end
      break
    end
  end
  return self
end

--- User - function to set the stock of a certain units type
-- @param #CTLD self
-- @param #string Name Name as defined in the generic unit entry.
-- @param #number Number Number of units/groups to be available. Nil or -1 equals unlimited
-- @return #CTLD self
function CTLD:SetStockUnits(Name, Number)
  local name = Name or "none"
  local number = Number
  local units = self.C130GetUnits or {}
  for _id,_unit in pairs(units) do
    if _unit.Name == name then
      if number == nil or number == -1 then
        _unit.Stock = -1
      else
        _unit.Stock = number
      end
      break
    end
  end
  return self
end

  --- User - function to get a table of units in stock (C-130 "Get units")
  -- @param #CTLD self
  -- @return #table Table Table of Stock, indexed by unit type name
  function CTLD:GetStockUnits()
    local Stock = {}
    local units = self.C130GetUnits or {}
    for _id,_unit in pairs(units) do
        Stock[_unit.Name] = _unit.Stock or -1
    end
    return Stock
  end


  --- User - function to add stock of a certain troops type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:AddStockTroops(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    -- find right generic type
    local gentroops = self.Cargo_Troops
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:AddStock(number)
        self:_RefreshTroopQuantityMenus(nil, nil, _troop)
        break
      end
    end
    return self
  end
  
  --- User - function to add stock of a certain crates type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:AddStockCrates(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    -- find right generic type
    local gentroops = self.Cargo_Crates
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:AddStock(number)
        self:_RefreshCrateQuantityMenus(nil, nil, _troop)
        break
      end
    end
    return self
  end
  
  --- User - function to add stock of a certain crates type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:AddStockStatics(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    -- find right generic type
    local gentroops = self.Cargo_Statics
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:AddStock(number)
        self:_RefreshQuantityMenusForGroup()
        break
      end
    end
    return self
  end
  
  --- User - function to set the stock of a certain crates type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to be available. Nil equals unlimited
  -- @return #CTLD self
  function CTLD:SetStockCrates(Name, Number)
    local name = Name or "none"
    local number = Number
    -- find right generic type
    local gentroops = self.Cargo_Crates
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:SetStock(number)
        self:_RefreshCrateQuantityMenus(nil, nil, _troop)
        break
      end
    end
    return self
  end
  
  --- User - function to set the stock of a certain troops type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to be available. Nil equals unlimited
  -- @return #CTLD self
  function CTLD:SetStockTroops(Name, Number)
    local name = Name or "none"
    local number = Number
    -- find right generic type
    local gentroops = self.Cargo_Troops
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:SetStock(number)
        self:_RefreshTroopQuantityMenus(nil, nil, _troop)
        break
      end
    end
    return self
  end
  
  --- User - function to set the stock of a certain statics type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to be available. Nil equals unlimited
  -- @return #CTLD self
  function CTLD:SetStockStatics(Name, Number)
    local name = Name or "none"
    local number = Number
    -- find right generic type
    local gentroops = self.Cargo_Statics
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:SetStock(number)
        self:_RefreshQuantityMenusForGroup()
        break
      end
    end
    return self
  end
  
  --- User - function to get a table of crates in stock
  -- @param #CTLD self
  -- @return #table Table Table of Stock, indexed by cargo type name
  function CTLD:GetStockCrates()
    local Stock = {}
    local gentroops = self.Cargo_Crates
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      Stock[_troop.Name] = _troop.Stock or -1
      --table.insert(Stock,_troop.Name,_troop.Stock or -1)
    end
    return Stock
  end  
  
  --- User - function to get a table of troops in stock
  -- @param #CTLD self
  -- @return #table Table Table of Stock, indexed by cargo type name
  function CTLD:GetStockTroops()
    local Stock = {}
    local gentroops = self.Cargo_Troops
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      Stock[_troop.Name] = _troop.Stock or -1
      --table.insert(Stock,_troop.Name,_troop.Stock or -1)
    end
    return Stock
  end
  
  --- User - Query the cargo loaded from a specific unit
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit The (client) unit to query.
  -- @return #number Troopsloaded
  -- @return #number Cratesloaded
  -- @return #table Cargo Table of #CTLD_CARGO objects
  function CTLD:GetLoadedCargo(Unit)
    local Troops = 0
    local Crates = 0
    local Cargo = {}
    if Unit and Unit:IsAlive() then
      local name = Unit:GetName()
      if self.Loaded_Cargo[name] then
        Troops = self.Loaded_Cargo[name].Troopsloaded or 0
        Crates = self.Loaded_Cargo[name].Cratesloaded or 0
        Cargo = self.Loaded_Cargo[name].Cargo or {}
      end
    end
    return Troops, Crates, Cargo
  end
  
  --- User - function to get a table of statics cargo in stock
  -- @param #CTLD self
  -- @return #table Table Table of Stock, indexed by cargo type name
  function CTLD:GetStockStatics()
    local Stock = {}
    local gentroops = self.Cargo_Statics
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      Stock[_troop.Name] = _troop.Stock or -1
      -- table.insert(Stock,_troop.Name,_troop.Stock or -1)
    end
    return Stock
  end
  
  --- User - function to remove stock of a certain troops type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:RemoveStockTroops(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    -- find right generic type
    local gentroops = self.Cargo_Troops
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:RemoveStock(number)
        self:_RefreshTroopQuantityMenus(nil, nil, _troop)
      end
    end
    return self
  end
  
  --- User - function to remove stock of a certain crates type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:RemoveStockCrates(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    -- find right generic type
    local gentroops = self.Cargo_Crates
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:RemoveStock(number)
        self:_RefreshQuantityMenusForGroup()
      end
    end
    return self
  end
  
  --- User - function to remove stock of a certain statics type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:RemoveStockStatics(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    -- find right generic type
    local gentroops = self.Cargo_Statics
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:RemoveStock(number)
        self:_RefreshQuantityMenusForGroup()
      end
    end
    return self
  end

  --- User - function to remove stock of a certain Units
  -- @param #CTLD self
  -- @param #string Name Name as defined in the AddUnits.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:RemoveStockUnits(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    local units = self.C130GetUnits or {}
    for _id,_unit in pairs(units) do
      if _unit.Name == name then
        local stock = _unit.Stock
        if stock == nil or stock == -1 then
          _unit.Stock = -1
        else
          _unit.Stock = stock - number
          if _unit.Stock < 0 then
            _unit.Stock = 0
          end
        end
        break
      end
    end
    return self
  end
  
  --- (User) Get a generic #CTLD_CARGO entry from a group name, works for Troops and Vehicles, FOB, i.e. everything that is spawned as a GROUP object.
  -- @param #CTLD self
  -- @param #string GroupName The name to use for the search
  -- @return #CTLD_CARGO The cargo object or nil if not found
  function CTLD:GetGenericCargoObjectFromGroupName(GroupName)
    local Cargotype = nil
    local template = GroupName
    if string.find(template,"#") then
      template = string.gsub(GroupName,"#(%d+)$","")
    end   
    template = string.gsub(template,"-(%d+)$","")
    for k,v in pairs(self.Cargo_Troops) do
    local comparison = ""
    if type(v.Templates) == "string" then comparison = v.Templates else comparison = v.Templates[1] end
      if comparison == template then
        Cargotype = v
        break
      end
    end
    if not Cargotype then
      for k,v in pairs(self.Cargo_Crates) do -- #number, #CTLD_CARGO
      local comparison = ""
      if type(v.Templates) == "string" then comparison = v.Templates else comparison = v.Templates[1] end
        if comparison == template and v.CargoType ~= CTLD_CARGO.Enum.REPAIR then
          Cargotype = v
          break
        end
      end
    end
    return Cargotype
  end
  
  --- (Internal) Check on engineering teams
  -- @param #CTLD self
  -- @return #CTLD self
  function CTLD:_CheckEngineers()
    self:T(self.lid.." CheckEngineers")
    local engtable = self.EngineersInField
    for _ind,_engineers in pairs (engtable) do
      local engineers = _engineers -- #CTLD_ENGINEERING
      local wrenches = engineers.Group -- Wrapper.Group#GROUP
      self:T(_engineers.lid .. _engineers:GetStatus())
      if wrenches and wrenches:IsAlive() then
        if engineers:IsStatus("Running") or engineers:IsStatus("Searching") then
          local crates,number = self:_FindCratesNearby(wrenches,nil, self.EngineerSearch,true,true) -- #table
          engineers:Search(crates,number)
        elseif engineers:IsStatus("Moving") then
          engineers:Move()
        elseif engineers:IsStatus("Arrived") then
          engineers:Build()
          local unit = wrenches:GetUnit(1)
          self:_BuildCrates(wrenches,unit,true)
          self:_RepairCrates(wrenches,unit,true)
          engineers:Done()
        end
      else
        engineers:Stop()
      end
    end
    return self
  end
  
  --- (User) Pre-populate troops in the field.
  -- @param #CTLD self
  -- @param Core.Zone#ZONE Zone The zone where to drop the troops.
  -- @param Ops.CTLD#CTLD_CARGO Cargo The #CTLD_CARGO object to spawn.
  -- @param #table Surfacetypes (Optional) Table of surface types. Can also be a single surface type. We will try max 1000 times to find the right type!
  -- @param #boolean PreciseLocation (Optional) Don't try to get a random position in the zone but use the dead center. Caution not to stack up stuff on another!
  -- @param #string Structure (Optional) String object describing the current structure of the injected group; mainly for load/save to keep current state setup.
  -- @param #number TimeStamp (Optional) Timestamp used internally on re-loading from disk.
  -- @return #CTLD self
  -- @usage Use this function to pre-populate the field with Troops or Engineers at a random coordinate in a zone:
  --            -- create a matching #CTLD_CARGO type
  --            local InjectTroopsType = CTLD_CARGO:New(nil,"Infantry",{"Inf12"},CTLD_CARGO.Enum.TROOPS,true,true,12,nil,false,80)
  --            -- get a #ZONE object
  --            local dropzone = ZONE:New("InjectZone") -- Core.Zone#ZONE
  --            -- and go:
  --            my_ctld:InjectTroops(dropzone,InjectTroopsType,{land.SurfaceType.LAND})
  function CTLD:InjectTroops(Zone,Cargo,Surfacetypes,PreciseLocation,Structure,TimeStamp)
    self:T(self.lid.." InjectTroops")
    local cargo = Cargo -- #CTLD_CARGO
    
    local function IsTroopsMatch(cargo)
      local match = false
      local cgotbl = self.Cargo_Troops
      local name = cargo:GetName()
      local CargoObject
      local CargoName
      for _,_cgo in pairs (cgotbl) do
        local cname = _cgo:GetName()
        if name == cname then
          match = true
          CargoObject = _cgo
          CargoName = cname
          break
        end
      end
      return match, CargoObject, CargoName
    end
    
    local function Cruncher(group,typename,anzahl)
      local units = group:GetUnits()
      local reduced = 0
      for _,_unit in pairs (units) do
        local typo = _unit:GetTypeName()
        if typename == typo then
          _unit:Destroy(false)
          reduced = reduced + 1
          if reduced == anzahl then break end
        end
      end
    end
    
    local function PostSpawn(args)
      local group = args[1]
      local structure = args[2]
      if structure then
  
        local loadedstructure = {}
        local strcset = UTILS.Split(structure,";")
        for _,_data in pairs(strcset) do
          local datasplit = UTILS.Split(_data,"==")
          loadedstructure[datasplit[1]] = tonumber(datasplit[2])
        end
  
        local originalstructure = UTILS.GetCountPerTypeName(group)
  
        for _name,_number in pairs(originalstructure) do
          local loadednumber = 0
          if loadedstructure[_name] then
            loadednumber = loadedstructure[_name]
          end
          local reduce = false
          if loadednumber < _number then reduce = true end
          
          if reduce then
            Cruncher(group,_name,_number-loadednumber)  
          end
                    
        end
     end
    end
    
    local match,CargoObject,CargoName = IsTroopsMatch(cargo)
    
    if not match then
      self.CargoCounter = self.CargoCounter + 1
      cargo.ID = self.CargoCounter
      --cargo.Stock = 1
      table.insert(self.Cargo_Troops,cargo)
    end
    
    if match and CargoObject then
      local stock = CargoObject:GetStock()
      if stock ~= -1 and stock ~= nil and stock == 0 then
       -- stock empty
       self:T(self.lid.."Stock of "..CargoName.." is empty. Cannot inject.")
       return
      else
        CargoObject:RemoveStock(1)
      end
    end
    
    local type = cargo:GetType() -- #CTLD_CARGO.Enum
    if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) then
      -- unload 
      local name = cargo:GetName() or "none"
      local temptable = cargo:GetTemplates() or {}
      local factor = 1.5
      local zone = Zone
      local randomcoord = zone:GetRandomCoordinate(10,30*factor,Surfacetypes):GetVec2()
      if PreciseLocation then
        randomcoord = zone:GetCoordinate():GetVec2()
      end
      local randompositions = not PreciseLocation
      for _,_template in pairs(temptable) do
        self.TroopCounter = self.TroopCounter + 1
        local alias = string.format("%s-%d", _template, math.random(1,100000))
        self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
          :InitRandomizeUnits(randompositions,20,2)
          :InitValidateAndRepositionGroundUnits(self.validateAndRepositionUnits)
          :InitDelayOff()
          :OnSpawnGroup(function(grp,TimeStamp) grp.spawntime = TimeStamp or timer.getTime() end,TimeStamp)
          :SpawnFromVec2(randomcoord)
        if self.movetroopstowpzone and type ~= CTLD_CARGO.Enum.ENGINEERS then
          self:_MoveGroupToZone(self.DroppedTroops[self.TroopCounter])
        end
      end -- template loop
      cargo:SetWasDropped(true)
      -- engineering group?
      if type == CTLD_CARGO.Enum.ENGINEERS then
        self.Engineers = self.Engineers + 1
        local grpname = self.DroppedTroops[self.TroopCounter]:GetName()
        self.EngineersInField[self.Engineers] = CTLD_ENGINEERING:New(name, grpname)
      end
      
      if Structure then
        BASE:ScheduleOnce(0.5,PostSpawn,{self.DroppedTroops[self.TroopCounter],Structure})
      end
      
      if self.keeploadtable and TimeStamp ~= nil then
        self:T2("Inserting: "..cargo.CargoType)
        local cargotype = type
        table.insert(self.LoadedGroupsTable,{Group=self.DroppedTroops[self.TroopCounter], TimeStamp=TimeStamp, CargoType=cargotype, CargoName=name})
      end
      
      if self.eventoninject then
         self:__TroopsDeployed(1,nil,nil,self.DroppedTroops[self.TroopCounter],type)
      end
    end -- if type end
    return self
  end
  
  --- (User) Pre-populate vehicles in the field.
  -- @param #CTLD self
  -- @param Core.Zone#ZONE Zone The zone where to drop the troops.
  -- @param Ops.CTLD#CTLD_CARGO Cargo The #CTLD_CARGO object to spawn.
  -- @param #table Surfacetypes (Optional) Table of surface types. Can also be a single surface type. We will try max 1000 times to find the right type!
  -- @param #boolean PreciseLocation (Optional) Don't try to get a random position in the zone but use the dead center. Caution not to stack up stuff on another!
  -- @param #string Structure (Optional) String object describing the current structure of the injected group; mainly for load/save to keep current state setup.
  -- @param #number TimeStamp (Optional) Timestamp used internally on re-loading from disk.
  -- @return #CTLD self
  -- @usage Use this function to pre-populate the field with Vehicles or FOB at a random coordinate in a zone:
  --            -- create a matching #CTLD_CARGO type
  --            local InjectVehicleType = CTLD_CARGO:New(nil,"Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,true,true,1,nil,false,1000)
  --            -- get a #ZONE object
  --            local dropzone = ZONE:New("InjectZone") -- Core.Zone#ZONE
  --            -- and go:
  --            my_ctld:InjectVehicles(dropzone,InjectVehicleType)
  function CTLD:InjectVehicles(Zone,Cargo,Surfacetypes,PreciseLocation,Structure,TimeStamp)
    self:T(self.lid.." InjectVehicles")
    local cargo = Cargo -- #CTLD_CARGO
    
    local function IsVehicMatch(cargo)
      local match = false
      local cgotbl = self.Cargo_Crates
      local name = cargo:GetName()
      local CargoObject
      local CargoName
      for _,_cgo in pairs (cgotbl) do
        local cname = _cgo:GetName()
        if name == cname then
          match = true
          CargoObject = _cgo
          CargoName = cname
          break
        end
      end
      return match,CargoObject,CargoName
    end
    
    local function Cruncher(group,typename,anzahl)
      local units = group:GetUnits()
      local reduced = 0
      for _,_unit in pairs (units) do
        local typo = _unit:GetTypeName()
        if typename == typo then
          _unit:Destroy(false)
          reduced = reduced + 1
          if reduced == anzahl then break end
        end
      end
    end
    
    local function PostSpawn(args)
      local group = args[1]
      local structure = args[2]
      if structure then
  
        local loadedstructure = {}
        local strcset = UTILS.Split(structure,";")
        for _,_data in pairs(strcset) do
          local datasplit = UTILS.Split(_data,"==")
          loadedstructure[datasplit[1]] = tonumber(datasplit[2])
        end
  
        local originalstructure = UTILS.GetCountPerTypeName(group)
  
        for _name,_number in pairs(originalstructure) do
          local loadednumber = 0
          if loadedstructure[_name] then
            loadednumber = loadedstructure[_name]
          end
          local reduce = false
          if loadednumber < _number then reduce = true end
          
          if reduce then
            Cruncher(group,_name,_number-loadednumber)  
          end
                    
        end
     end
    end
    
    local match,CargoObject,CargoName = IsVehicMatch(cargo)
    
    if not match then
      self.CargoCounter = self.CargoCounter + 1
      cargo.ID = self.CargoCounter
      --cargo.Stock = 1
      table.insert(self.Cargo_Crates,cargo)
    end
    
    if match and CargoObject then
      local stock = CargoObject:GetStock()
      if stock ~= -1 and stock ~= nil and stock == 0 then
       -- stock empty
       self:T(self.lid.."Stock of "..CargoName.." is empty. Cannot inject.")
       return
      else
        CargoObject:RemoveStock(1)
      end
    end
    
    local type = cargo:GetType() -- #CTLD_CARGO.Enum
    if (type == CTLD_CARGO.Enum.VEHICLE or type == CTLD_CARGO.Enum.FOB) then
      -- unload 
      local name = cargo:GetName() or "none"
      local temptable = cargo:GetTemplates() or {}
      local factor = 1.5
      local zone = Zone
      local randomcoord = zone:GetRandomCoordinate(10,30*factor,Surfacetypes):GetVec2()
      if PreciseLocation then
        randomcoord = zone:GetCoordinate():GetVec2()
      end
      cargo:SetWasDropped(true)
      local canmove = false
      if type == CTLD_CARGO.Enum.VEHICLE then canmove = true end
      for _,_template in pairs(temptable) do
        self.TroopCounter = self.TroopCounter + 1
        local alias = string.format("%s-%d", _template, math.random(1,100000))
        if canmove then
          self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
            :InitRandomizeUnits(true,20,2)
            :InitValidateAndRepositionGroundUnits(self.validateAndRepositionUnits)
            :InitDelayOff()
            :OnSpawnGroup(function(grp,TimeStamp) grp.spawntime = TimeStamp or timer.getTime() end,TimeStamp)
            :SpawnFromVec2(randomcoord)
        else -- don't random position of e.g. SAM units build as FOB
          self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
            :InitDelayOff()
            :InitValidateAndRepositionGroundUnits(self.validateAndRepositionUnits)
            :OnSpawnGroup(function(grp,TimeStamp) grp.spawntime = TimeStamp or timer.getTime() end,TimeStamp)
            :SpawnFromVec2(randomcoord)
        end
        
        if Structure then
          BASE:ScheduleOnce(0.5,PostSpawn,{self.DroppedTroops[self.TroopCounter],Structure})
        end
        
        if self.keeploadtable and TimeStamp ~= nil then
          self:T2("Inserting: "..cargo.CargoType)
          local cargotype = type
          table.insert(self.LoadedGroupsTable,{Group=self.DroppedTroops[self.TroopCounter], TimeStamp=TimeStamp, CargoType=cargotype, CargoName=name})
        end
        
        if self.eventoninject then
          self:__CratesBuild(1,nil,nil,self.DroppedTroops[self.TroopCounter])
        end
      end -- end loop
    end -- if type end
    return self
  end
  
------------------------------------------------------------------- 
-- TODO FSM functions
------------------------------------------------------------------- 

  --- (Internal) FSM Function onafterStart.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onafterStart(From, Event, To)
    self:T({From, Event, To})
    self:I(self.lid .. "Started ("..self.version..")")
    if self.enableHercules then self.enableFixedWing = true end
    if self.UserSetGroup then
      self.PilotGroups  = self.UserSetGroup
    elseif self.useprefix or self.enableFixedWing then
      local prefix = self.prefixes
      if self.enableFixedWing then
        self.PilotGroups = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterPrefixes(prefix):FilterStart()
      else
        self.PilotGroups = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterPrefixes(prefix):FilterCategories("helicopter"):FilterStart()
      end
    else
      self.PilotGroups = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterCategories("helicopter"):FilterStart()
    end
    -- Events
    self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
    self:HandleEvent(EVENTS.PlayerEnterUnit, self._EventHandler)
    self:HandleEvent(EVENTS.PlayerLeaveUnit, self._EventHandler)
    self:HandleEvent(EVENTS.UnitLost, self._EventHandler)  
    --self:HandleEvent(EVENTS.Birth, self._EventHandler)
    self:HandleEvent(EVENTS.NewDynamicCargo, self._EventHandler)
    self:HandleEvent(EVENTS.DynamicCargoLoaded, self._EventHandler)  
    self:HandleEvent(EVENTS.DynamicCargoUnloaded, self._EventHandler)  
    self:HandleEvent(EVENTS.DynamicCargoRemoved, self._EventHandler)     
    self:HandleEvent(EVENTS.Land, self._EventHandler)
    self:HandleEvent(EVENTS.Takeoff, self._EventHandler)
    self:__Status(-5)
    
    -- AutoSave
    if self.enableLoadSave then
      local interval = self.saveinterval
      local filename = self.filename
      local filepath = self.filepath
      self:__Save(interval,filepath,filename)
    end
    
    if type(self.VehicleMoveFormation) == "table" then
      local Formations = {}
      for _,_formation in pairs(self.VehicleMoveFormation) do
        table.insert(Formations,_formation)
      end
      self.VehicleMoveFormation = nil
      self.VehicleMoveFormation = Formations
    end
  
    return self
  end

  --- (Internal) FSM Function onbeforeStatus.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onbeforeStatus(From, Event, To)
    self:T({From, Event, To})
    self:CleanDroppedTroops()
    self:_RefreshF10Menus()
    self:CheckDroppedBeacons()
    self:_RefreshRadioBeacons()
    self:CheckAutoHoverload()
    self:_CheckEngineers()
    return self
  end
  
  --- (Internal) FSM Function onafterStatus.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onafterStatus(From, Event, To)
    self:T({From, Event, To})
     -- gather some stats
    -- pilots
    local pilots = 0
    for _,_pilot in pairs (self.CtldUnits) do   
     pilots = pilots + 1
    end
     
    -- spawned cargo boxes curr in field
    local boxes = 0
    for _,_pilot in pairs (self.Spawned_Cargo) do
     boxes = boxes + 1
    end
    
    local cc =  self.CargoCounter
    local tc = self.TroopCounter
    
    if self.debug or self.verbose > 0 then 
      local text = string.format("%s Pilots %d | Live Crates %d |\nCargo Counter %d | Troop Counter %d", self.lid, pilots, boxes, cc, tc)
      local m = MESSAGE:New(text,10,"CTLD"):ToAll()
      if self.verbose > 0 then
        self:I(self.lid.."Cargo and Troops in Stock:")
        for _,_troop in pairs (self.Cargo_Crates) do
          local name = _troop:GetName()
          local stock = _troop:GetStock()
          self:I(string.format("-- %s \t\t\t %d", name, stock))
        end
        for _,_troop in pairs (self.Cargo_Statics) do
          local name = _troop:GetName()
          local stock = _troop:GetStock()
          self:I(string.format("-- %s \t\t\t %d", name, stock))
        end
        for _,_troop in pairs (self.Cargo_Troops) do
          local name = _troop:GetName()
          local stock = _troop:GetStock()
          self:I(string.format("-- %s \t\t %d", name, stock))
        end
      end
    end
    self:__Status(-30)
    return self
  end
  
  --- (Internal) FSM Function onafterStop.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onafterStop(From, Event, To)
    self:T({From, Event, To})
    self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
    self:UnHandleEvent(EVENTS.PlayerEnterUnit)
    self:UnHandleEvent(EVENTS.PlayerLeaveUnit)
    self:UnHandleEvent(EVENTS.UnitLost)  
    self:UnHandleEvent(EVENTS.Shot) 
    return self
  end
  
  --- (Internal) FSM Function onbeforeTroopsPickedUp.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate.
  -- @return #CTLD self
  function CTLD:onbeforeTroopsPickedUp(From, Event, To, Group, Unit, Cargo)
    self:T({From, Event, To})
    return self
  end
  
    --- (Internal) FSM Function onbeforeCratesPickedUp.
  -- @param #CTLD self
  -- @param #string From State .
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate. Can be a Wrapper.DynamicCargo#DYNAMICCARGO object, if ground crew loaded!
  -- @return #CTLD self
  function CTLD:onbeforeCratesPickedUp(From, Event, To, Group, Unit, Cargo)
    self:T({From, Event, To})
    return self
  end
  
  --- (Internal) FSM Function onbeforeTroopsExtracted.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops Troops #GROUP Object.
  -- @param #string Groupname Name of the extracted #GROUP.
  -- @return #CTLD self
  function CTLD:onbeforeTroopsExtracted(From, Event, To, Group, Unit, Troops, Groupname)
    self:T({From, Event, To})
    if Unit and Unit:IsPlayer() and self.PlayerTaskQueue then
      local playername = Unit:GetPlayerName()
      --local dropcoord = Troops:GetCoordinate() or COORDINATE:New(0,0,0)
      --local dropvec2 = dropcoord:GetVec2()
      self.PlayerTaskQueue:ForEach(
        function (Task)
          local task = Task -- Ops.PlayerTask#PLAYERTASK
          local subtype = task:GetSubType()
          -- right subtype?
          if Event == subtype and not task:IsDone() then
            local targetzone = task.Target:GetObject() -- Core.Zone#ZONE should be a zone in this case ....
            self:T2({Name=Groupname,Property=task:GetProperty("ExtractName")})
            if task:GetProperty("ExtractName") then
              local okaygroup = string.find(Groupname,task:GetProperty("ExtractName"),1,true)
              if targetzone and targetzone.ClassName and string.match(targetzone.ClassName,"ZONE") and okaygroup then
                if task.Clients:HasUniqueID(playername) then
                  -- success
                  task:__Success(-1)
                end
              end
            else
              self:T({Text="'ExtractName' Property not set",Name=Groupname,Property=task.Type})
            end
          end
        end
      )
    end
    return self
  end
    
    
  --- (Internal) FSM Function onbeforeTroopsDeployed.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops Troops #GROUP Object.
  -- @return #CTLD self
  function CTLD:onbeforeTroopsDeployed(From, Event, To, Group, Unit, Troops)
    self:T({From, Event, To})
    if Unit and Unit:IsPlayer() and self.PlayerTaskQueue then
      local playername = Unit:GetPlayerName()
      local dropcoord = Troops:GetCoordinate() or COORDINATE:New(0,0,0)
      local dropvec2 = dropcoord:GetVec2()
      self.PlayerTaskQueue:ForEach(
        function (Task)
          local task = Task -- Ops.PlayerTask#PLAYERTASK
          local subtype = task:GetSubType()
          -- right subtype?
          if Event == subtype and not task:IsDone() then
            local targetzone = task.Target:GetObject() -- Core.Zone#ZONE should be a zone in this case ....
            if targetzone and targetzone.ClassName and string.match(targetzone.ClassName,"ZONE") and targetzone:IsVec2InZone(dropvec2) then
              if task.Clients:HasUniqueID(playername) then
                -- success
                task:__Success(-1)
              end
            end
          end
        end
      )
    end
    return self
  end
  
  --- (Internal) FSM Function onafterTroopsDeployed.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops Troops #GROUP Object.
  -- @param #CTLD.CargoZoneType Type Type of Cargo deployed
  -- @return #CTLD self
  function CTLD:onafterTroopsDeployed(From, Event, To, Group, Unit, Troops, Type)
    self:T({From, Event, To})
    if self.movetroopstowpzone and Type ~= CTLD_CARGO.Enum.ENGINEERS then
      self:_MoveGroupToZone(Troops)
      if not Group or not Unit then self:_RefreshQuantityMenusForGroup() end
    end
    return self
  end
  
  --- (Internal) FSM Function onbeforeCratesDropped.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects dropped. Can be a Wrapper.DynamicCargo#DYNAMICCARGO object, if ground crew unloaded!
  -- @return #CTLD self
  function CTLD:onbeforeCratesDropped(From, Event, To, Group, Unit, Cargotable)
    self:T({From, Event, To})
    if Unit and Unit:IsPlayer() and self.PlayerTaskQueue then
      local playername = Unit:GetPlayerName()
      for _,_cargo in pairs(Cargotable) do
        local Vehicle = _cargo.Positionable
        if Vehicle then
          local dropcoord = Vehicle:GetCoordinate() or COORDINATE:New(0,0,0)
          local dropvec2 = dropcoord:GetVec2()
          self.PlayerTaskQueue:ForEach(
            function (Task)
              local task = Task -- Ops.PlayerTask#PLAYERTASK
              local subtype = task:GetSubType()
              -- right subtype?
              if Event == subtype and not task:IsDone() then
                local targetzone = task.Target:GetObject() -- Core.Zone#ZONE should be a zone in this case ....
                if targetzone and targetzone.ClassName and string.match(targetzone.ClassName,"ZONE") and targetzone:IsVec2InZone(dropvec2) then
                  if task.Clients:HasUniqueID(playername) then
                    -- success
                    task:__Success(-1)
                  end
                end
              end
            end
          )
        end
      end
    end
    return self
  end
  
  --- (Internal) FSM Function OnAfterGetCrates.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects spawned via "Get".
  -- @return #CTLD self
  function CTLD:OnAfterGetCrates(From, Event, To, Group, Unit, Cargotable)
    self:T({From, Event, To})
    return self
  end

  --- (Internal) FSM Function OnAfterRemoveCratesNearby.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects spawned via "Get".
  -- @return #CTLD self
  function CTLD:OnAfterRemoveCratesNearby(From, Event, To, Group, Unit, Cargotable)
    self:T({From, Event, To})
    return self
  end
  
  --- (Internal) FSM Function onbeforeCratesBuild.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB build.
  -- @return #CTLD self
  function CTLD:onbeforeCratesBuild(From, Event, To, Group, Unit, Vehicle)
    self:T({From, Event, To})
    if Unit and Unit:IsPlayer() and self.PlayerTaskQueue then
      local playername = Unit:GetPlayerName()
      local dropcoord = Vehicle:GetCoordinate() or COORDINATE:New(0,0,0)
      local dropvec2 = dropcoord:GetVec2()
      self.PlayerTaskQueue:ForEach(
        function (Task)
          local task = Task -- Ops.PlayerTask#PLAYERTASK
          local subtype = task:GetSubType()
          -- right subtype?
          if Event == subtype and not task:IsDone() then
            local targetzone = task.Target:GetObject() -- Core.Zone#ZONE should be a zone in this case ....
            if targetzone and targetzone.ClassName and string.match(targetzone.ClassName,"ZONE") and targetzone:IsVec2InZone(dropvec2) then
              if task.Clients:HasUniqueID(playername) then
                -- success
                task:__Success(-1)
              end
            end
          end
        end
      )
    end
    return self
  end

  --- (Internal) FSM Function onafterCratesBuild.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB build.
  -- @return #CTLD self
  function CTLD:onafterCratesBuild(From, Event, To, Group, Unit, Vehicle)
    self:T({From, Event, To})
    if self.movetroopstowpzone and Vehicle then
      local cg = self:GetGenericCargoObjectFromGroupName(Vehicle:GetName())
      if not (cg and (cg.NoMoveToZone or (self.nomovetozone_names and self.nomovetozone_names[cg:GetName()]))) then
        self:_MoveGroupToZone(Vehicle)
      end
    end
    if not Group or not Unit then self:_RefreshQuantityMenusForGroup() end
    return self
  end
  
  --- (Internal) FSM Function onbeforeTroopsRTB.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #string ZoneName Name of the Zone where the Troops have been RTB'd.
  -- @param Core.Zone#ZONE_Radius ZoneObject of the Zone where the Troops have been RTB'd.
  -- @return #CTLD self
  function CTLD:onbeforeTroopsRTB(From, Event, To, Group, Unit, ZoneName, ZoneObject)
    self:T({From, Event, To})
    return self
  end
  
  --- On before "Save" event. Checks if io and lfs are available.
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is saved. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for saving. Default is "CTLD_<alias>_Persist.csv".
  function CTLD:onbeforeSave(From, Event, To, path, filename)
    self:T({From, Event, To, path, filename})
    if not self.enableLoadSave then
      return self
    end
    -- Thanks to @FunkyFranky 
    -- Check io module is available.
    if not io then
      self:E(self.lid.."ERROR: io not desanitized. Can't save current state.")
      return false
    end
  
    -- Check default path.
    if path==nil and not lfs then
      self:E(self.lid.."WARNING: lfs not desanitized. State will be saved in DCS installation root directory rather than your \"Saved Games\\DCS\" folder.")
    end
  
    return true
  end
  
  --- On after "Save" event. Player data is saved to file.
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path Path where the file is saved. If nil, file is saved in the DCS root installation directory or your "Saved Games" folder if lfs was desanitized.
  -- @param #string filename (Optional) File name for saving. Default is Default is "CTLD_<alias>_Persist.csv".
  function CTLD:onafterSave(From, Event, To, path, filename)
    self:T({From, Event, To, path, filename})
    -- Thanks to @FunkyFranky 
    if not self.enableLoadSave then
      return self
    end
    --- Function that saves data to file
    local function _savefile(filename, data)
      local f = assert(io.open(filename, "wb"))
      f:write(data)
      f:close()
    end
  
    -- Set path or default.
    if lfs then
      path=self.filepath or lfs.writedir()
    end
    
    -- Set file name.
    filename=filename or self.filename
  
    -- Set path.
    if path~=nil then
      filename=path.."\\"..filename
    end
    
    local grouptable = self.DroppedTroops -- #table
    local cgovehic = self.Cargo_Crates
    local cgotable = self.Cargo_Troops
    local stcstable = self.Spawned_Cargo
    
    local statics = nil
    local statics = {}
    self:T(self.lid.."Building Statics Table for Saving")
    for _,_cargo in pairs (stcstable) do     
      local cargo = _cargo -- #CTLD_CARGO
      local object = cargo:GetPositionable() -- Wrapper.Static#STATIC
      if object and object:IsAlive() and (cargo:WasDropped() or not cargo:HasMoved()) then
        statics[#statics+1] = cargo
      end
    end
    
    -- find matching cargo
    local function FindCargoType(name,table)
      -- name matching a template in the table
      local match = false
      local cargo = nil
      name = string.gsub(name,"-"," ")
      for _ind,_cargo in pairs (table) do
        local thiscargo = _cargo -- #CTLD_CARGO
        local template = thiscargo:GetTemplates()
        if type(template) == "string" then
          template = { template }
        end
        for _,_name in pairs (template) do
          _name = string.gsub(_name,"-"," ")
          if string.find(name,_name) and _cargo:GetType() ~= CTLD_CARGO.Enum.REPAIR then
            match = true
            cargo = thiscargo
          end
        end
        if match then break end
      end
      return match, cargo
    end
    
      
    --local data = "LoadedData = {\n"
    local data = "Group,x,y,z,CargoName,CargoTemplates,CargoType,CratesNeeded,CrateMass,Structure,StaticCategory,StaticType,StaticShape,SpawnTime\n"
    local n = 0
    for _,_grp in pairs(grouptable) do
      local group = _grp -- Wrapper.Group#GROUP
      if group and group:IsAlive() then
        -- get template name
        local name = group:GetName()
        local template = name
        
        if string.find(template,"#") then
          template = string.gsub(name,"#(%d+)$","")
        end
        
        local template = string.gsub(name,"-(%d+)$","")
        
        local match, cargo = FindCargoType(template,cgotable)
        if not match then
          match, cargo = FindCargoType(template,cgovehic)
        end
        if match then
          n = n + 1
          local cargo = cargo -- #CTLD_CARGO
          local cgoname = cargo.Name
          local cgotemp = cargo.Templates
          local cgotype = cargo.CargoType
          local cgoneed = cargo.CratesNeeded
          local cgomass = cargo.PerCrateMass
          local scat,stype,sshape = cargo:GetStaticTypeAndShape()
          local structure = UTILS.GetCountPerTypeName(group)
          local strucdata =  ""
          for typen,anzahl in pairs (structure) do
            strucdata = strucdata .. typen .. "=="..anzahl..";"
          end
          local spawntime = group.spawntime or timer.getTime()+n
          
          if type(cgotemp) == "table" then       
            local templates = "{"
            for _,_tmpl in pairs(cgotemp) do
              templates = templates .. _tmpl .. ";"
            end
            templates = templates .. "}"
            cgotemp = templates
          end
          
          local location = group:GetVec3()
          local txt = string.format("%s,%d,%d,%d,%s,%s,%s,%d,%d,%s,%s,%s,%s,%f\n"
              ,template,location.x,location.y,location.z,cgoname,cgotemp,cgotype,cgoneed,cgomass,strucdata,scat,stype,sshape or "none",spawntime)             
          data = data .. txt
        end
      end
    end
    
    for _,_cgo in pairs(statics) do
      local object = _cgo -- #CTLD_CARGO
      local cgoname = object.Name
      local cgotemp = object.Templates
      
      if type(cgotemp) == "table" then       
        local templates = "{"
        for _,_tmpl in pairs(cgotemp) do
          templates = templates .. _tmpl .. ";"
        end
        templates = templates .. "}"
        cgotemp = templates
      end
      
      local cgotype = object.CargoType
      local cgoneed = object.CratesNeeded
      local cgomass = object.PerCrateMass
      local crateobj = object.Positionable
      local location = crateobj:GetVec3()
      local scat,stype,sshape = object:GetStaticTypeAndShape()
      local txt = string.format("%s,%d,%d,%d,%s,%s,%s,%d,%d,'none',%s,%s,%s\n"
          ,"STATIC",location.x,location.y,location.z,cgoname,cgotemp,cgotype,cgoneed,cgomass,scat,stype,sshape or "none")
      data = data .. txt
    end
    
    _savefile(filename, data)
     
    -- AutoSave
    if self.enableLoadSave then
      local interval = self.saveinterval
      local filename = self.filename
      local filepath = self.filepath
      self:__Save(interval,filepath,filename)
    end
    return self
  end

  --- On before "Load" event. Checks if io and lfs and the file are available.
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is located. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for loading. Default is "CTLD_<alias>_Persist.csv".
  function CTLD:onbeforeLoad(From, Event, To, path, filename)
    self:T({From, Event, To, path, filename})
    if not self.enableLoadSave then
      return self
    end
    --- Function that check if a file exists.
    local function _fileexists(name)
       local f=io.open(name,"r")
       if f~=nil then
        io.close(f)
        return true
      else
        return false
      end
    end
    
    -- Set file name and path
    filename=filename or self.filename
    path = path or self.filepath
    
    -- Check io module is available.
    if not io then
      self:E(self.lid.."WARNING: io not desanitized. Cannot load file.")
      return false
    end
  
    -- Check default path.
    if path==nil and not lfs then
      self:E(self.lid.."WARNING: lfs not desanitized. State will be saved in DCS installation root directory rather than your \"Saved Games\\DCS\" folder.")
    end
  
    -- Set path or default.
    if lfs then
      path=path or lfs.writedir()
    end
  
    -- Set path.
    if path~=nil then
      filename=path.."\\"..filename
    end
  
    -- Check if file exists.
    local exists=_fileexists(filename)
  
    if exists then
      return true
    else
      self:E(self.lid..string.format("WARNING: State file %s might not exist.", filename))
      return false
      --return self
    end
  
  end

  --- On after "Load" event. Loads dropped units from file.
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is located. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for loading. Default is "CTLD_<alias>_Persist.csv".
  function CTLD:onafterLoad(From, Event, To, path, filename)
    self:T({From, Event, To, path, filename})
    if not self.enableLoadSave then
      return self
    end
    --- Function that loads data from a file.
    local function _loadfile(filename)
      local f=assert(io.open(filename, "rb"))
      local data=f:read("*all")
      f:close()
      return data
    end
    
    -- Set file name and path
    filename=filename or self.filename
    path = path or self.filepath
    
    -- Set path or default.
    if lfs then
      path=path or lfs.writedir()
    end
  
    -- Set path.
    if path~=nil then
      filename=path.."\\"..filename
    end
  
    -- Info message.
    local text=string.format("Loading CTLD state from file %s", filename)
    MESSAGE:New(text,10):ToAllIf(self.Debug)
    self:I(self.lid..text)
    
    local file=assert(io.open(filename, "rb"))
    
    local loadeddata = {}
    for line in file:lines() do
        loadeddata[#loadeddata+1] = line
    end
    file:close()
    
    -- remove header
    table.remove(loadeddata, 1)
    local n=0
    for _id,_entry in pairs (loadeddata) do
      local dataset = UTILS.Split(_entry,",")     
      -- 1=Group,2=x,3=y,4=z,5=CargoName,6=CargoTemplates,7=CargoType,8=CratesNeeded,9=CrateMass,10=Structure,11=StaticCategory,12=StaticType,13=StaticShape,14=Timestamp
      local groupname = dataset[1]
      local vec2 = {}
      vec2.x = tonumber(dataset[2])
      vec2.y = tonumber(dataset[4])
      local cargoname = dataset[5]
      local cargotemplates = dataset[6]
      local cargotype = dataset[7]
      local size = tonumber(dataset[8])
      local mass = tonumber(dataset[9])
      local StaticCategory = dataset[11]
      local StaticType = dataset[12]
      local StaticShape = dataset[13]
      n=n+1
      local timestamp = tonumber(dataset[14]) or (timer.getTime()+n)
      self:T2("TimeStamp = "..timestamp)
      if type(groupname) == "string" and groupname ~= "STATIC" then
        cargotemplates = string.gsub(cargotemplates,"{","")
        cargotemplates = string.gsub(cargotemplates,"}","")
        cargotemplates = UTILS.Split(cargotemplates,";")
        local structure = nil
        if dataset[10] and dataset[10] ~= "none" then
          structure = dataset[10]
          structure = string.gsub(structure,",","")
        end
        -- inject at Vec2
        local dropzone = ZONE_RADIUS:New("DropZone",vec2,20)
        if cargotype == CTLD_CARGO.Enum.VEHICLE or cargotype == CTLD_CARGO.Enum.FOB then
          local injectvehicle = CTLD_CARGO:New(nil,cargoname,cargotemplates,cargotype,true,true,size,nil,true,mass)
          injectvehicle:SetStaticTypeAndShape(StaticCategory,StaticType,StaticShape)      
          self:InjectVehicles(dropzone,injectvehicle,self.surfacetypes,self.useprecisecoordloads,structure,timestamp)
          if self.C130GetUnits then
            for _,_unit in pairs(self.C130GetUnits) do
              if _unit.Name == cargoname then
                if type(_unit.Stock) == "number" and _unit.Stock ~= -1 then
                  _unit.Stock0 = _unit.Stock0 or _unit.Stock
                  _unit.Stock = math.max(0,(_unit.Stock or 0)-1)
                end
                break
              end
            end
          end
        elseif cargotype == CTLD_CARGO.Enum.TROOPS or cargotype == CTLD_CARGO.Enum.ENGINEERS then
          local injecttroops = CTLD_CARGO:New(nil,cargoname,cargotemplates,cargotype,true,true,size,nil,true,mass)      
          self:InjectTroops(dropzone,injecttroops,self.surfacetypes,self.useprecisecoordloads,structure,timestamp)
        end
       elseif self.loadSavedCrates and (type(groupname) == "string" and groupname == "STATIC") or cargotype == CTLD_CARGO.Enum.REPAIR then
        local dropzone = ZONE_RADIUS:New("DropZone",vec2,20)
        local injectstatic = nil
        if cargotype == CTLD_CARGO.Enum.VEHICLE or cargotype == CTLD_CARGO.Enum.FOB then
          cargotemplates = string.gsub(cargotemplates,"{","")
          cargotemplates = string.gsub(cargotemplates,"}","")
          cargotemplates = UTILS.Split(cargotemplates,";")
          injectstatic = CTLD_CARGO:New(nil,cargoname,cargotemplates,cargotype,true,true,size,nil,true,mass) 
          injectstatic:SetStaticTypeAndShape(StaticCategory,StaticType,StaticShape)     
        elseif cargotype == CTLD_CARGO.Enum.STATIC or cargotype == CTLD_CARGO.Enum.REPAIR then
          injectstatic = CTLD_CARGO:New(nil,cargoname,cargotemplates,cargotype,true,true,size,nil,true,mass)
          injectstatic:SetStaticTypeAndShape(StaticCategory,StaticType,StaticShape)
          local unittemplate = _DATABASE:GetStaticUnitTemplate(cargoname)
          local ResourceMap = nil
          if unittemplate and unittemplate.resourcePayload then
            ResourceMap = UTILS.DeepCopy(unittemplate.resourcePayload)
          end
          injectstatic:SetStaticResourceMap(ResourceMap) 
        end
        if injectstatic then
          self:InjectStatics(dropzone,injectstatic,false,true)
        end
      end    
    end
    if self.keeploadtable then -- keeploadtables
      self:__Loaded(1,self.LoadedGroupsTable)
    end
    return self
  end
end -- end do

do 
--- **Hercules Cargo AIR Drop Events** by Anubis Yinepu
-- Moose CTLD OO refactoring by Applevangelist
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO CTLD_HERCULES
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- This script will only work for the Herculus mod by Anubis, and only for **Air Dropping** cargo from the Hercules. 
-- It *DOES NOT* work with the purchaseable Hercules module from ED.
-- Use the standard Moose CTLD if you want to unload on the ground.
-- Payloads carried by pylons 11, 12 and 13 need to be declared in the Herculus_Loadout.lua file
-- Except for Ammo pallets, this script will spawn whatever payload gets launched from pylons 11, 12 and 13
-- Pylons 11, 12 and 13 are moveable within the Hercules cargobay area
-- Ammo pallets can only be jettisoned from these pylons with no benefit to DCS world
-- To benefit DCS world, Ammo pallets need to be off/on loaded using DCS arming and refueling window
-- Cargo_Container_Enclosed = true: Cargo enclosed in container with parachute, need to be dropped from 100m (300ft) or more, except when parked on ground
-- Cargo_Container_Enclosed = false: Open cargo with no parachute, need to be dropped from 10m (30ft) or less

------------------------------------------------------
--- **CTLD_HERCULES** class, extends Core.Base#BASE
-- @type CTLD_HERCULES
-- @field #string ClassName
-- @field #string lid
-- @field #string Name
-- @field #string Version
-- @extends Core.Base#BASE
CTLD_HERCULES = {
  ClassName = "CTLD_HERCULES",
  lid = "",
  Name = "",
  Version = "0.0.3",
}

--- Define cargo types.
-- @type CTLD_HERCULES.Types
-- @field #table Type Name of cargo type, container (boolean) in container or not.
CTLD_HERCULES.Types = {
  ["ATGM M1045 HMMWV TOW Air [7183lb]"] = {['name'] = "M1045 HMMWV TOW", ['container'] = true},
  ["ATGM M1045 HMMWV TOW Skid [7073lb]"] = {['name'] = "M1045 HMMWV TOW", ['container'] = false},
  ["APC M1043 HMMWV Armament Air [7023lb]"] = {['name'] = "M1043 HMMWV Armament", ['container'] = true},
  ["APC M1043 HMMWV Armament Skid [6912lb]"] = {['name'] = "M1043 HMMWV Armament", ['container'] = false},
  ["SAM Avenger M1097 Air [7200lb]"] = {['name'] = "M1097 Avenger", ['container'] = true},
  ["SAM Avenger M1097 Skid [7090lb]"] = {['name'] = "M1097 Avenger", ['container'] = false},
  ["APC Cobra Air [10912lb]"] = {['name'] = "Cobra", ['container'] = true},
  ["APC Cobra Skid [10802lb]"] = {['name'] = "Cobra", ['container'] = false},
  ["APC M113 Air [21624lb]"] = {['name'] = "M-113", ['container'] = true},
  ["APC M113 Skid [21494lb]"] = {['name'] = "M-113", ['container'] = false},
  ["Tanker M978 HEMTT [34000lb]"] = {['name'] = "M978 HEMTT Tanker", ['container'] = false},
  ["HEMTT TFFT [34400lb]"] = {['name'] = "HEMTT TFFT", ['container'] = false},
  ["SPG M1128 Stryker MGS [33036lb]"] = {['name'] = "M1128 Stryker MGS", ['container'] = false},
  ["AAA Vulcan M163 Air [21666lb]"] = {['name'] = "Vulcan", ['container'] = true},
  ["AAA Vulcan M163 Skid [21577lb]"] = {['name'] = "Vulcan", ['container'] = false},
  ["APC M1126 Stryker ICV [29542lb]"] = {['name'] = "M1126 Stryker ICV", ['container'] = false},
  ["ATGM M1134 Stryker [30337lb]"] = {['name'] = "M1134 Stryker ATGM", ['container'] = false},
  ["APC LAV-25 Air [22520lb]"] = {['name'] = "LAV-25", ['container'] = true},
  ["APC LAV-25 Skid [22514lb]"] = {['name'] = "LAV-25", ['container'] = false},
  ["M1025 HMMWV Air [6160lb]"] = {['name'] = "Hummer", ['container'] = true},
  ["M1025 HMMWV Skid [6050lb]"] = {['name'] = "Hummer", ['container'] = false},
  ["IFV M2A2 Bradley [34720lb]"] = {['name'] = "M-2 Bradley", ['container'] = false},
  ["IFV MCV-80 [34720lb]"] = {['name'] = "MCV-80", ['container'] = false},
  ["IFV BMP-1 [23232lb]"] = {['name'] = "BMP-1", ['container'] = false},
  ["IFV BMP-2 [25168lb]"] = {['name'] = "BMP-2", ['container'] = false},
  ["IFV BMP-3 [32912lb]"] = {['name'] = "BMP-3", ['container'] = false},
  ["ARV BRDM-2 Air [12320lb]"] = {['name'] = "BRDM-2", ['container'] = true},
  ["ARV BRDM-2 Skid [12210lb]"] = {['name'] = "BRDM-2", ['container'] = false},
  ["APC BTR-80 Air [23936lb]"] = {['name'] = "BTR-80", ['container'] = true},
  ["APC BTR-80 Skid [23826lb]"] = {['name'] = "BTR-80", ['container'] = false},
  ["APC BTR-82A Air [24998lb]"] = {['name'] = "BTR-82A", ['container'] = true},
  ["APC BTR-82A Skid [24888lb]"] = {['name'] = "BTR-82A", ['container'] = false},
  ["SAM ROLAND ADS [34720lb]"] = {['name'] = "Roland Radar", ['container'] = false},
  ["SAM ROLAND LN [34720b]"] = {['name'] = "Roland ADS", ['container'] = false},
  ["SAM SA-13 STRELA [21624lb]"] = {['name'] = "Strela-10M3", ['container'] = false},
  ["AAA ZSU-23-4 Shilka [32912lb]"] = {['name'] = "ZSU-23-4 Shilka", ['container'] = false},
  ["SAM SA-19 Tunguska 2S6 [34720lb]"] = {['name'] = "2S6 Tunguska", ['container'] = false},
  ["Transport UAZ-469 Air [3747lb]"] = {['name'] = "UAZ-469", ['container'] = true},
  ["Transport UAZ-469 Skid [3630lb]"] = {['name'] = "UAZ-469", ['container'] = false},
  ["AAA GEPARD [34720lb]"] = {['name'] = "Gepard", ['container'] = false},
  ["SAM CHAPARRAL Air [21624lb]"] = {['name'] = "M48 Chaparral", ['container'] = true},
  ["SAM CHAPARRAL Skid [21516lb]"] = {['name'] = "M48 Chaparral", ['container'] = false},
  ["SAM LINEBACKER [34720lb]"] = {['name'] = "M6 Linebacker", ['container'] = false},
  ["Transport URAL-375 [14815lb]"] = {['name'] = "Ural-375", ['container'] = false},
  ["Transport M818 [16000lb]"] = {['name'] = "M 818", ['container'] = false},
  ["IFV MARDER [34720lb]"] = {['name'] = "Marder", ['container'] = false},
  ["Transport Tigr Air [15900lb]"] = {['name'] = "Tigr_233036", ['container'] = true},
  ["Transport Tigr Skid [15730lb]"] = {['name'] = "Tigr_233036", ['container'] = false},
  ["IFV TPZ FUCH [33440lb]"] = {['name'] = "TPZ", ['container'] = false},
  ["IFV BMD-1 Air [18040lb]"] = {['name'] = "BMD-1", ['container'] = true},
  ["IFV BMD-1 Skid [17930lb]"] = {['name'] = "BMD-1", ['container'] = false},
  ["IFV BTR-D Air [18040lb]"] = {['name'] = "BTR_D", ['container'] = true},
  ["IFV BTR-D Skid [17930lb]"] = {['name'] = "BTR_D", ['container'] = false},
  ["EWR SBORKA Air [21624lb]"] = {['name'] = "Dog Ear radar", ['container'] = true},
  ["EWR SBORKA Skid [21624lb]"] = {['name'] = "Dog Ear radar", ['container'] = false},
  ["ART 2S9 NONA Air [19140lb]"] = {['name'] = "SAU 2-C9", ['container'] = true},
  ["ART 2S9 NONA Skid [19030lb]"] = {['name'] = "SAU 2-C9", ['container'] = false},
  ["ART GVOZDIKA [34720lb]"] = {['name'] = "SAU Gvozdika", ['container'] = false},
  ["APC MTLB Air [26400lb]"] = {['name'] = "MTLB", ['container'] = true},
  ["APC MTLB Skid [26290lb]"] = {['name'] = "MTLB", ['container'] = false},
}

--- Cargo Object
-- @type CTLD_HERCULES.CargoObject
-- @field #number Cargo_Drop_Direction
-- @field #table Cargo_Contents
-- @field #string Cargo_Type_name
-- @field #boolean Container_Enclosed
-- @field #boolean ParatrooperGroupSpawn
-- @field #number Cargo_Country
-- @field #boolean offload_cargo
-- @field #boolean all_cargo_survive_to_the_ground
-- @field #boolean all_cargo_gets_destroyed
-- @field #boolean destroy_cargo_dropped_without_parachute
-- @field Core.Timer#TIMER scheduleFunctionID

--- [User] Instantiate a new object
-- @param #CTLD_HERCULES self
-- @param #string Coalition Coalition side, "red", "blue" or "neutral"
-- @param #string Alias Name of this instance
-- @param Ops.CTLD#CTLD CtldObject CTLD instance to link into
-- @return #CTLD_HERCULES self
-- @usage
-- Integrate to your CTLD instance like so, where `my_ctld` is a previously created CTLD instance:
--            
--            my_ctld.enableFixedWing = false -- avoid dual loading via CTLD F10 and F8 ground crew
--            local herccargo = CTLD_HERCULES:New("blue", "Hercules Test", my_ctld)
--            
-- You also need: 
-- * A template called "Infantry" for 10 Paratroopers (as set via herccargo.infantrytemplate). 
-- * Depending on what you are loading with the help of the ground crew, there are 42 more templates for the various vehicles that are loadable. 
-- There's a **quick check output in the `dcs.log`** which tells you what's there and what not.
-- E.g.:
--            ...Checking template for APC BTR-82A Air [24998lb] (BTR-82A) ... MISSING)
--            ...Checking template for ART 2S9 NONA Skid [19030lb] (SAU 2-C9) ... MISSING)
--            ...Checking template for EWR SBORKA Air [21624lb] (Dog Ear radar) ... MISSING)
--            ...Checking template for Transport Tigr Air [15900lb] (Tigr_233036) ... OK)
--            
-- Expected template names are the ones in the rounded brackets.
-- 
-- ### HINTS
-- 
-- The script works on the EVENTS.Shot trigger, which is used by the mod when you **drop cargo from the Hercules while flying**. Unloading on the ground does
-- not achieve anything here. If you just want to unload on the ground, use the normal Moose CTLD.
-- **Do not use** the **splash damage** script together with this, your cargo will just explode when reaching the ground!
-- 
-- ### Airdrops
-- 
-- There are two ways of airdropping:   
-- 1) Very low and very slow (>5m and <10m AGL) - here you can drop stuff which has "Skid" at the end of the cargo name (loaded via F8 Ground Crew menu)
-- 2) Higher up and slow (>100m AGL) - here you can drop paratroopers and cargo which has "Air" at the end of the cargo name (loaded via F8 Ground Crew menu)
-- 
-- ### General
-- 
-- Use either this method to integrate the Hercules **or** the one from the "normal" CTLD. Never both!
function CTLD_HERCULES:New(Coalition, Alias, CtldObject)
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #CTLD_HERCULES
  
  --set Coalition
  if Coalition and type(Coalition)=="string" then
    if Coalition=="blue" then
      self.coalition=coalition.side.BLUE
      self.coalitiontxt = Coalition
    elseif Coalition=="red" then
      self.coalition=coalition.side.RED
      self.coalitiontxt = Coalition
    elseif Coalition=="neutral" then
      self.coalition=coalition.side.NEUTRAL
      self.coalitiontxt = Coalition
    else
      self:E("ERROR: Unknown coalition in CTLD!")
    end
  else
    self.coalition = Coalition
    self.coalitiontxt = string.lower(UTILS.GetCoalitionName(self.coalition))
  end
  
  -- Set alias.
  if Alias then
    self.alias=tostring(Alias)
  else
    self.alias="UNHCR"  
    if self.coalition then
      if self.coalition==coalition.side.RED then
        self.alias="Red CTLD Hercules"
      elseif self.coalition==coalition.side.BLUE then
        self.alias="Blue CTLD Hercules"
      end
    end
  end
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.alias, self.coalitiontxt)
  
  self.infantrytemplate = "Infantry" -- template for a group of 10 paratroopers
  self.CTLD = CtldObject -- Ops.CTLD#CTLD
  
  self.verbose = true
  
  self.j = 0
  self.carrierGroups = {}
  self.Cargo = {}
  self.ParatrooperCount = {}
  
  self.ObjectTracker = {}
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")

  self:HandleEvent(EVENTS.Shot, self._HandleShot)
  
  self:I(self.lid .. "Started")
  
  self:CheckTemplates()
    
  return self
end

--- [Internal] Function to check availability of templates
-- @param #CTLD_HERCULES self
-- @return #CTLD_HERCULES self 
function CTLD_HERCULES:CheckTemplates()
  self:T(self.lid .. 'CheckTemplates')
  -- inject Paratroopers
  self.Types["Paratroopers 10"] = {
    name = self.infantrytemplate,
    container = false,
    available = false,
  }
  local missing = {}
  local nomissing = 0
  local found = {}
  local nofound = 0
  
  -- list of groundcrew loadables
  for _index,_tab in pairs (self.Types) do
    local outcometxt = "MISSING"
    if _DATABASE.Templates.Groups[_tab.name] then
      outcometxt = "OK"
      self.Types[_index].available= true
      found[_tab.name] = true
    else
      self.Types[_index].available = false
      missing[_tab.name] = true
    end
    if self.verbose then
      self:I(string.format(self.lid .. "Checking template for %s (%s) ... %s", _index,_tab.name,outcometxt))
    end
  end
  for _,_name in pairs(found) do
    nofound = nofound + 1
  end
  for _,_name in pairs(missing) do
    nomissing = nomissing + 1
  end
  self:I(string.format(self.lid .. "Template Check Summary: Found %d, Missing %d, Total %d",nofound,nomissing,nofound+nomissing))
  return self
end

--- [Internal] Function to spawn a soldier group of 10 units
-- @param #CTLD_HERCULES self
-- @param Wrapper.Group#GROUP Cargo_Drop_initiator
-- @param Core.Point#COORDINATE Cargo_Drop_Position
-- @param #string Cargo_Type_name
-- @param #number CargoHeading
-- @param #number Cargo_Country
-- @param #number GroupSpacing
-- @return #CTLD_HERCULES self 
function CTLD_HERCULES:Soldier_SpawnGroup(Cargo_Drop_initiator,Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country, GroupSpacing)
  --- TODO: Rework into Moose Spawns
  self:T(self.lid .. 'Soldier_SpawnGroup')
  self:T(Cargo_Drop_Position)
   -- create a matching #CTLD_CARGO type
   local InjectTroopsType = CTLD_CARGO:New(nil,self.infantrytemplate,{self.infantrytemplate},CTLD_CARGO.Enum.TROOPS,true,true,10,nil,false,80)
   -- get a #ZONE object
   local position = Cargo_Drop_Position:GetVec2()
   local dropzone = ZONE_RADIUS:New("Infantry " .. math.random(1,10000),position,100)
   -- and go:
   self.CTLD:InjectTroops(dropzone,InjectTroopsType)
  return self
end

--- [Internal] Function to spawn a group
-- @param #CTLD_HERCULES self
-- @param Wrapper.Group#GROUP Cargo_Drop_initiator
-- @param Core.Point#COORDINATE Cargo_Drop_Position
-- @param #string Cargo_Type_name
-- @param #number CargoHeading
-- @param #number Cargo_Country
-- @return #CTLD_HERCULES self 
function CTLD_HERCULES:Cargo_SpawnGroup(Cargo_Drop_initiator,Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country)
  --- TODO: Rework into Moose Spawns
  self:T(self.lid .. "Cargo_SpawnGroup")
  self:T(Cargo_Type_name)   
  if Cargo_Type_name ~= 'Container red 1' then
   -- create a matching #CTLD_CARGO type
   local InjectVehicleType = CTLD_CARGO:New(nil,Cargo_Type_name,{Cargo_Type_name},CTLD_CARGO.Enum.VEHICLE,true,true,1,nil,false,1000)
   -- get a #ZONE object
   local position = Cargo_Drop_Position:GetVec2()
   local dropzone = ZONE_RADIUS:New("Vehicle " .. math.random(1,10000),position,100)
   -- and go:
   self.CTLD:InjectVehicles(dropzone,InjectVehicleType)
  end
  return self
end

--- [Internal] Function to spawn static cargo
-- @param #CTLD_HERCULES self
-- @param Wrapper.Group#GROUP Cargo_Drop_initiator
-- @param Core.Point#COORDINATE Cargo_Drop_Position
-- @param #string Cargo_Type_name
-- @param #number CargoHeading
-- @param #boolean dead
-- @param #number Cargo_Country
-- @return #CTLD_HERCULES self
function CTLD_HERCULES:Cargo_SpawnStatic(Cargo_Drop_initiator,Cargo_Drop_Position, Cargo_Type_name, CargoHeading, dead, Cargo_Country)
  --- TODO: Rework into Moose Static Spawns
  self:T(self.lid .. "Cargo_SpawnStatic")
  self:T("Static " .. Cargo_Type_name .. " Dead " .. tostring(dead))
  local position = Cargo_Drop_Position:GetVec2()
  local Zone = ZONE_RADIUS:New("Cargo Static " .. math.random(1,10000),position,100)
  if not dead then
    local injectstatic = CTLD_CARGO:New(nil,"Cargo Static Group "..math.random(1,10000),"iso_container",CTLD_CARGO.Enum.STATIC,true,false,1,nil,true,4500,1) 
    self.CTLD:InjectStatics(Zone,injectstatic,true,true)
  end
  return self
end

--- [Internal] Function to spawn cargo by type at position
-- @param #CTLD_HERCULES self
-- @param #string Cargo_Type_name
-- @param Core.Point#COORDINATE Cargo_Drop_Position
-- @return #CTLD_HERCULES self
function CTLD_HERCULES:Cargo_SpawnDroppedAsCargo(_name, _pos)
  local theCargo = self.CTLD:_FindCratesCargoObject(_name) -- #CTLD_CARGO
  if theCargo then
    self.CTLD.CrateCounter = self.CTLD.CrateCounter + 1
    local CCat, CType, CShape = theCargo:GetStaticTypeAndShape()
    local basetype = CType or self.CTLD.basetype or "container_cargo"
    CCat = CCat or "Cargos"
    local theStatic = SPAWNSTATIC:NewFromType(basetype,CCat,self.cratecountry)    
    :InitCargoMass(theCargo.PerCrateMass)
    :InitCargo(self.CTLD.enableslingload)
    :InitCoordinate(_pos)
    if CShape then
      theStatic:InitShape(CShape)
    end
    theStatic:Spawn(270,_name .. "-Container-".. math.random(1,100000))
  
    self.CTLD.Spawned_Crates[self.CTLD.CrateCounter] = theStatic
    local newCargo = CTLD_CARGO:New(self.CTLD.CargoCounter, theCargo.Name, theCargo.Templates, theCargo.CargoType, true, false, theCargo.CratesNeeded, self.CTLD.Spawned_Crates[self.CTLD.CrateCounter], true, theCargo.PerCrateMass, nil, theCargo.Subcategory)
    local map=theCargo:GetStaticResourceMap()
    newCargo:SetStaticResourceMap(map)
    table.insert(self.CTLD.Spawned_Cargo, newCargo)

    newCargo:SetWasDropped(true)
    newCargo:SetHasMoved(true)
  end
  return self
end

--- [Internal] Spawn cargo objects
-- @param #CTLD_HERCULES self
-- @param Wrapper.Group#GROUP Cargo_Drop_initiator
-- @param #number Cargo_Drop_Direction
-- @param Core.Point#COORDINATE Cargo_Content_position
-- @param #string Cargo_Type_name
-- @param #boolean Cargo_over_water
-- @param #boolean Container_Enclosed
-- @param #boolean ParatrooperGroupSpawn
-- @param #boolean offload_cargo
-- @param #boolean all_cargo_survive_to_the_ground
-- @param #boolean all_cargo_gets_destroyed
-- @param #boolean destroy_cargo_dropped_without_parachute
-- @param #number Cargo_Country
-- @return #CTLD_HERCULES self
function CTLD_HERCULES:Cargo_SpawnObjects(Cargo_Drop_initiator,Cargo_Drop_Direction, Cargo_Content_position, Cargo_Type_name, Cargo_over_water, Container_Enclosed, ParatrooperGroupSpawn, offload_cargo, all_cargo_survive_to_the_ground, all_cargo_gets_destroyed, destroy_cargo_dropped_without_parachute, Cargo_Country)
  self:T(self.lid .. 'Cargo_SpawnObjects')
  
  local CargoHeading = self.CargoHeading
  
  if offload_cargo == true or ParatrooperGroupSpawn == true then  
    if ParatrooperGroupSpawn == true then
      self:Soldier_SpawnGroup(Cargo_Drop_initiator,Cargo_Content_position, Cargo_Type_name, CargoHeading, Cargo_Country, 10)
    else
      self:Cargo_SpawnGroup(Cargo_Drop_initiator,Cargo_Content_position, Cargo_Type_name, CargoHeading, Cargo_Country)
    end
  else
    if all_cargo_gets_destroyed == true or Cargo_over_water == true then

    else
      if all_cargo_survive_to_the_ground == true then
        if ParatrooperGroupSpawn == true then
          self:Cargo_SpawnStatic(Cargo_Drop_initiator,Cargo_Content_position, Cargo_Type_name, CargoHeading, true, Cargo_Country)
        else
          self:Cargo_SpawnGroup(Cargo_Drop_initiator,Cargo_Content_position, Cargo_Type_name, CargoHeading, Cargo_Country)
        end
        if Container_Enclosed == true then
          if ParatrooperGroupSpawn == false then
            self:Cargo_SpawnStatic(Cargo_Drop_initiator,Cargo_Content_position, "Hercules_Container_Parachute_Static", CargoHeading, false, Cargo_Country)
          end
        end
      end
      if destroy_cargo_dropped_without_parachute == true then
        if Container_Enclosed == true then
          if ParatrooperGroupSpawn == true then
            self:Soldier_SpawnGroup(Cargo_Drop_initiator,Cargo_Content_position, Cargo_Type_name, CargoHeading, Cargo_Country, 0)
          else
            if self.CTLD.dropAsCargoCrate then
              self:Cargo_SpawnDroppedAsCargo(Cargo_Type_name, Cargo_Content_position)
            else
              self:Cargo_SpawnGroup(Cargo_Drop_initiator,Cargo_Content_position, Cargo_Type_name, CargoHeading, Cargo_Country)
              self:Cargo_SpawnStatic(Cargo_Drop_initiator,Cargo_Content_position, "Hercules_Container_Parachute_Static", CargoHeading, false, Cargo_Country)
            end
          end
        else
          self:Cargo_SpawnStatic(Cargo_Drop_initiator,Cargo_Content_position, Cargo_Type_name, CargoHeading, true, Cargo_Country)
        end
      end
    end
  end
  return self
end

--- [Internal] Function to calculate object height
-- @param #CTLD_HERCULES self
-- @param Wrapper.Group#GROUP group The group for which to calculate the height
-- @return #number height over ground
function CTLD_HERCULES:Calculate_Object_Height_AGL(group)
  self:T(self.lid .. "Calculate_Object_Height_AGL")
  if group.ClassName and group.ClassName == "GROUP" then
    local gcoord = group:GetCoordinate()
    local height = group:GetHeight()
    local lheight = gcoord:GetLandHeight()
    self:T(self.lid .. "Height " .. height - lheight)
    return height - lheight
  else
    -- DCS object
    if group:isExist() then
      local dcsposition = group:getPosition().p
      local dcsvec2 = {x = dcsposition.x, y = dcsposition.z} -- Vec2
      local height = math.floor(group:getPosition().p.y - land.getHeight(dcsvec2))
      self.ObjectTracker[group.id_] = dcsposition --  Vec3
      self:T(self.lid .. "Height " .. height)
      return height
    else
      return 0
    end
  end
end

--- [Internal] Function to check surface type
-- @param #CTLD_HERCULES self
-- @param Wrapper.Group#GROUP group The group for which to calculate the height
-- @return #number height over ground
function CTLD_HERCULES:Check_SurfaceType(object)
  self:T(self.lid .. "Check_SurfaceType")
   -- LAND,--1 SHALLOW_WATER,--2 WATER,--3 ROAD,--4 RUNWAY--5
  if object:isExist() then
   return land.getSurfaceType({x = object:getPosition().p.x, y = object:getPosition().p.z})
  else
   return 1
  end
end

--- [Internal] Function to track cargo objects
-- @param #CTLD_HERCULES self
-- @param #CTLD_HERCULES.CargoObject cargo
-- @param Wrapper.Group#GROUP initiator
-- @return #number height over ground
function CTLD_HERCULES:Cargo_Track(cargo, initiator)
  self:T(self.lid .. "Cargo_Track")
  local Cargo_Drop_initiator = initiator
  if cargo.Cargo_Contents ~= nil then
    if self:Calculate_Object_Height_AGL(cargo.Cargo_Contents) < 10 then --pallet less than 5m above ground before spawning
      if self:Check_SurfaceType(cargo.Cargo_Contents) == 2 or self:Check_SurfaceType(cargo.Cargo_Contents) == 3 then
        cargo.Cargo_over_water = true--pallets gets destroyed in water
      end
      local dcsvec3 = self.ObjectTracker[cargo.Cargo_Contents.id_] or initiator:GetVec3() -- last known position
      self:T("SPAWNPOSITION: ")
      self:T({dcsvec3})
      local Vec2 = {
         x=dcsvec3.x,
         y=dcsvec3.z,
      }
      local vec3 = COORDINATE:NewFromVec2(Vec2)
      self.ObjectTracker[cargo.Cargo_Contents.id_] =  nil
      self:Cargo_SpawnObjects(Cargo_Drop_initiator,cargo.Cargo_Drop_Direction, vec3, cargo.Cargo_Type_name, cargo.Cargo_over_water, cargo.Container_Enclosed, cargo.ParatrooperGroupSpawn, cargo.offload_cargo, cargo.all_cargo_survive_to_the_ground, cargo.all_cargo_gets_destroyed, cargo.destroy_cargo_dropped_without_parachute, cargo.Cargo_Country)
      if cargo.Cargo_Contents:isExist() then
       cargo.Cargo_Contents:destroy()--remove pallet+parachute before hitting ground and replace with Cargo_SpawnContents
      end
      --timer.removeFunction(cargo.scheduleFunctionID)
      cargo.scheduleFunctionID:Stop()
      cargo = {}
    end
  end
  return self
end

--- [Internal] Function to calc north correction
-- @param #CTLD_HERCULES self
-- @param Core.Point#POINT_Vec3 point Position Vec3
-- @return #number north correction
function CTLD_HERCULES:Calculate_Cargo_Drop_initiator_NorthCorrection(point)
  self:T(self.lid .. "Calculate_Cargo_Drop_initiator_NorthCorrection")
  if not point.z then --Vec2; convert to Vec3
    point.z = point.y
    point.y = 0
  end
  local lat, lon = coord.LOtoLL(point)
  local north_posit = coord.LLtoLO(lat + 1, lon)
  return math.atan2(north_posit.z - point.z, north_posit.x - point.x)
end

--- [Internal] Function to calc initiator heading
-- @param #CTLD_HERCULES self
-- @param Wrapper.Group#GROUP Cargo_Drop_initiator
-- @return #number north corrected heading
function CTLD_HERCULES:Calculate_Cargo_Drop_initiator_Heading(Cargo_Drop_initiator)
  self:T(self.lid .. "Calculate_Cargo_Drop_initiator_Heading") 
  local Heading = Cargo_Drop_initiator:GetHeading()
  Heading = Heading + self:Calculate_Cargo_Drop_initiator_NorthCorrection(Cargo_Drop_initiator:GetVec3())
  if Heading < 0 then
    Heading = Heading + (2 * math.pi)-- put heading in range of 0 to 2*pi
  end
  return Heading + 0.06 -- rad
end

--- [Internal] Function to initialize dropped cargo
-- @param #CTLD_HERCULES self
-- @param Wrapper.Group#GROUP Initiator
-- @param #table Cargo_Contents Table 'weapon' from event data
-- @param #string Cargo_Type_name Name of this cargo
-- @param #boolean Container_Enclosed Is container?
-- @param #boolean SoldierGroup Is soldier group?
-- @param #boolean ParatrooperGroupSpawnInit Is paratroopers?
-- @return #CTLD_HERCULES self
function CTLD_HERCULES:Cargo_Initialize(Initiator, Cargo_Contents, Cargo_Type_name, Container_Enclosed, SoldierGroup, ParatrooperGroupSpawnInit)
  self:T(self.lid .. "Cargo_Initialize") 
    local Cargo_Drop_initiator = Initiator:GetName()
    if Cargo_Drop_initiator ~= nil then
      if ParatrooperGroupSpawnInit == true then
         self:T("Paratrooper Drop")
         -- Paratroopers
        if not self.ParatrooperCount[Cargo_Drop_initiator] then
         self.ParatrooperCount[Cargo_Drop_initiator] = 1
        else
         self.ParatrooperCount[Cargo_Drop_initiator] = self.ParatrooperCount[Cargo_Drop_initiator] + 1
        end
        
        local Paratroopers = self.ParatrooperCount[Cargo_Drop_initiator]
        
        self:T("Paratrooper Drop Number " .. self.ParatrooperCount[Cargo_Drop_initiator])
        
        local SpawnParas = false
        
        if math.fmod(Paratroopers,10) == 0 then
          SpawnParas = true
        end
        
        self.j = self.j + 1
        self.Cargo[self.j] = {}
        self.Cargo[self.j].Cargo_Drop_Direction = self:Calculate_Cargo_Drop_initiator_Heading(Initiator)
        self.Cargo[self.j].Cargo_Contents = Cargo_Contents
        self.Cargo[self.j].Cargo_Type_name = Cargo_Type_name
        self.Cargo[self.j].Container_Enclosed = Container_Enclosed
        self.Cargo[self.j].ParatrooperGroupSpawn = SpawnParas
        self.Cargo[self.j].Cargo_Country = Initiator:GetCountry()

        if self:Calculate_Object_Height_AGL(Initiator) < 5.0 then --aircraft on ground
          self.Cargo[self.j].offload_cargo = true
        elseif self:Calculate_Object_Height_AGL(Initiator) < 10.0 then --aircraft less than 10m above ground
          self.Cargo[self.j].all_cargo_survive_to_the_ground = true
        elseif self:Calculate_Object_Height_AGL(Initiator) < 100.0 then --aircraft more than 10m but less than 100m above ground
          self.Cargo[self.j].all_cargo_gets_destroyed = true
        else
         self.Cargo[self.j].all_cargo_gets_destroyed = false  
        end

        local timer = TIMER:New(self.Cargo_Track,self,self.Cargo[self.j],Initiator)
        self.Cargo[self.j].scheduleFunctionID  = timer
        timer:Start(1,1,600)  
        
      else
       -- no paras
        self.j = self.j + 1
        self.Cargo[self.j] = {}
        self.Cargo[self.j].Cargo_Drop_Direction = self:Calculate_Cargo_Drop_initiator_Heading(Initiator)
        self.Cargo[self.j].Cargo_Contents = Cargo_Contents
        self.Cargo[self.j].Cargo_Type_name = Cargo_Type_name
        self.Cargo[self.j].Container_Enclosed = Container_Enclosed
        self.Cargo[self.j].ParatrooperGroupSpawn = false
        self.Cargo[self.j].Cargo_Country = Initiator:GetCountry()

        if self:Calculate_Object_Height_AGL(Initiator) < 5.0 then--aircraft on ground
          self.Cargo[self.j].offload_cargo = true
        elseif self:Calculate_Object_Height_AGL(Initiator) < 10.0 then--aircraft less than 10m above ground
          self.Cargo[self.j].all_cargo_survive_to_the_ground = true
        elseif self:Calculate_Object_Height_AGL(Initiator) < 100.0 then--aircraft more than 10m but less than 100m above ground
          self.Cargo[self.j].all_cargo_gets_destroyed = true
        else
          self.Cargo[self.j].destroy_cargo_dropped_without_parachute = true --aircraft more than 100m above ground
        end
        
        local timer = TIMER:New(self.Cargo_Track,self,self.Cargo[self.j],Initiator)
        self.Cargo[self.j].scheduleFunctionID  = timer
        timer:Start(1,1,600)
      end
    end
  return self 
end

--- [Internal] Function to change cargotype per group (Wrench)
-- @param #CTLD_HERCULES self
-- @param #number key Carrier key id
-- @param #string cargoType Type of cargo
-- @param #number cargoNum Number of cargo objects
-- @return #CTLD_HERCULES self
function CTLD_HERCULES:SetType(key,cargoType,cargoNum)
  self:T(self.lid .. "SetType") 
  self.carrierGroups[key]['cargoType'] = cargoType
  self.carrierGroups[key]['cargoNum'] = cargoNum
  return self
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EventHandlers
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [Internal] Function to capture SHOT event
-- @param #CTLD_HERCULES self
-- @param Core.Event#EVENTDATA Cargo_Drop_Event The event data
-- @return #CTLD_HERCULES self
function CTLD_HERCULES:_HandleShot(Cargo_Drop_Event)
  self:T(self.lid .. "Shot Event ID:" .. Cargo_Drop_Event.id) 
  if Cargo_Drop_Event.id == EVENTS.Shot then
    
    local GT_Name = ""
    local SoldierGroup = false
    local ParatrooperGroupSpawnInit = false
    
    local GT_DisplayName = Weapon.getDesc(Cargo_Drop_Event.weapon).typeName:sub(15, -1)--Remove "weapons.bombs." from string
    self:T(string.format("%sCargo_Drop_Event: %s", self.lid, Weapon.getDesc(Cargo_Drop_Event.weapon).typeName))
 
    if (GT_DisplayName == "Squad 30 x Soldier [7950lb]") then
      self:Cargo_Initialize(Cargo_Drop_Event.IniGroup, Cargo_Drop_Event.weapon, "Soldier M4 GRG", false, true, true)
    end
 
    if self.Types[GT_DisplayName] then
      local GT_Name = self.Types[GT_DisplayName]['name']
    local Cargo_Container_Enclosed = self.Types[GT_DisplayName]['container']
        self:Cargo_Initialize(Cargo_Drop_Event.IniGroup, Cargo_Drop_Event.weapon, GT_Name, Cargo_Container_Enclosed)
      end
  end
  return self
end

--- [Internal] Function to capture BIRTH event
-- @param #CTLD_HERCULES self
-- @param Core.Event#EVENTDATA event The event data
-- @return #CTLD_HERCULES self
function CTLD_HERCULES:_HandleBirth(event)
  -- not sure what this is needed for? I think this for setting generic crates "content" setting.
  self:T(self.lid .. "Birth Event ID:" .. event.id)
  return self
end

end

-------------------------------------------------------------------
-- End Ops.CTLD.lua
-------------------------------------------------------------------
