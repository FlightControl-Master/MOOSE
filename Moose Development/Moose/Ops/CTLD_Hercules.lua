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
