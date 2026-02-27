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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- END CTLD_CARGO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- END CTLD_ENGINEERING
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
