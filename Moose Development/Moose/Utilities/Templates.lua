--- **Utilities** - Templates.
-- 
-- DCS unit templates
-- 
-- @module Utilities.Templates
-- @image MOOSE.JPG

--- TEMPLATE class.
-- @type TEMPLATE
-- @field #string ClassName Name of the class.

--- *Templates*
--
-- ===
--
-- ![Banner Image](..\Presentations\Utilities\PROFILER_Main.jpg)
--
-- Get DCS templates from thin air.
-- 
-- # Ground Units
-- 
-- Ground units.
-- 
-- # Naval Units
-- 
-- Ships are not implemented yet.
-- 
-- # Aircraft
-- 
-- ## Airplanes
-- 
-- Airplanes are not implemented yet.
-- 
-- ## Helicopters
-- 
-- Helicopters are not implemented yet.
-- 
-- @field #TEMPLATE
TEMPLATE = {
  ClassName      = "TEMPLATE",
  Ground         = {},
  Naval          = {},
  Airplane       = {},
  Helicopter     = {},
}

--- Ground unit type names.
-- @type TEMPLATE.TypeGround
-- @param #string InfantryAK
TEMPLATE.TypeGround={
  InfantryAK="Infantry AK",
  ParatrooperAKS74="Paratrooper AKS-74",
  ParatrooperRPG16="Paratrooper RPG-16",
  SoldierWWIIUS="soldier_wwii_us",
  InfantryM248="Infantry M249",
  SoldierM4="Soldier M4",
}

--- Naval unit type names.
-- @type TEMPLATE.TypeNaval
-- @param #string Ticonderoga
TEMPLATE.TypeNaval={
  Ticonderoga="TICONDEROG",
}

--- Rotary wing unit type names.
-- @type TEMPLATE.TypeAirplane
-- @param #string A10C
TEMPLATE.TypeAirplane={
  A10C="A-10C",
}

--- Rotary wing unit type names.
-- @type TEMPLATE.TypeHelicopter
-- @param #string AH1W
TEMPLATE.TypeHelicopter={
  AH1W="AH-1W",
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Ground Template
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get template for ground units.
-- @param #string TypeName Type name of the unit(s) in the groups. See `TEMPLATE.Ground`.
-- @param #string GroupName Name of the spawned group. **Must be unique!**
-- @param #number CountryID Country ID. Default `country.id.USA`. Coalition is automatically determined by the one the country belongs to.
-- @param DCS#Vec3 Vec3 Position of the group and the first unit.
-- @param #number Nunits Number of units. Default 1.
-- @param #number Radius Spawn radius for additonal units in meters. Default 50 m.
-- @return #table Template Template table.
function TEMPLATE.GetGround(TypeName, GroupName, CountryID, Vec3, Nunits, Radius)

  -- Defaults.
  TypeName=TypeName or TEMPLATE.TypeGround.SoldierM4
  GroupName=GroupName or "Ground-1"
  CountryID=CountryID or country.id.USA
  Vec3=Vec3 or {x=0, y=0, z=0}
  Nunits=Nunits or 1
  Radius=Radius or 50


  -- Get generic template.
  local template=UTILS.DeepCopy(TEMPLATE.GenericGround)

  -- Set group name.
  template.name=GroupName
  
  -- These are additional entries required by the MOOSE _DATABASE:Spawn() function.
  template.CountryID=CountryID
  template.CoalitionID=coalition.getCountryCoalition(template.CountryID)
  template.CategoryID=Unit.Category.GROUND_UNIT
  
  -- Set first unit.
  template.units[1].type=TypeName
  template.units[1].name=GroupName.."-1"  
  
  if Vec3 then
    TEMPLATE.SetPositionFromVec3(template, Vec3)
  end
  
  TEMPLATE.SetUnits(template, Nunits, COORDINATE:NewFromVec3(Vec3), Radius)

  return template
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Naval Template
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get template for ground units.
-- @param #string TypeName Type name of the unit(s) in the groups. See `TEMPLATE.Ground`.
-- @param #string GroupName Name of the spawned group. **Must be unique!**
-- @param #number CountryID Country ID. Default `country.id.USA`. Coalition is automatically determined by the one the country belongs to.
-- @param DCS#Vec3 Vec3 Position of the group and the first unit.
-- @param #number Nunits Number of units. Default 1.
-- @param #number Radius Spawn radius for additonal units in meters. Default 500 m.
-- @return #table Template Template table.
function TEMPLATE.GetNaval(TypeName, GroupName, CountryID, Vec3, Nunits, Radius)

  -- Defaults.
  TypeName=TypeName or TEMPLATE.TypeNaval.Ticonderoga
  GroupName=GroupName or "Naval-1"
  CountryID=CountryID or country.id.USA
  Vec3=Vec3 or {x=0, y=0, z=0}
  Nunits=Nunits or 1
  Radius=Radius or 500


  -- Get generic template.
  local template=UTILS.DeepCopy(TEMPLATE.GenericNaval)

  -- Set group name.
  template.name=GroupName
  
  -- These are additional entries required by the MOOSE _DATABASE:Spawn() function.
  template.CountryID=CountryID
  template.CoalitionID=coalition.getCountryCoalition(template.CountryID)
  template.CategoryID=Unit.Category.SHIP
  
  -- Set first unit.
  template.units[1].type=TypeName
  template.units[1].name=GroupName.."-1"  
  
  if Vec3 then
    TEMPLATE.SetPositionFromVec3(template, Vec3)
  end
  
  TEMPLATE.SetUnits(template, Nunits, COORDINATE:NewFromVec3(Vec3), Radius)

  return template
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Aircraft Template
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get template for fixed wing units.
-- @param #string TypeName Type name of the unit(s) in the groups. See `TEMPLATE.Ground`.
-- @param #string GroupName Name of the spawned group. **Must be unique!**
-- @param #number CountryID Country ID. Default `country.id.USA`. Coalition is automatically determined by the one the country belongs to.
-- @param DCS#Vec3 Vec3 Position of the group and the first unit.
-- @param #number Nunits Number of units. Default 1.
-- @param #number Radius Spawn radius for additonal units in meters. Default 500 m.
-- @return #table Template Template table.
function TEMPLATE.GetAirplane(TypeName, GroupName, CountryID, Vec3, Nunits, Radius)

  -- Defaults.
  TypeName=TypeName or TEMPLATE.TypeAirplane.A10C
  GroupName=GroupName or "Airplane-1"
  CountryID=CountryID or country.id.USA
  Vec3=Vec3 or {x=0, y=1000, z=0}
  Nunits=Nunits or 1
  Radius=Radius or 100

  local template=TEMPLATE._GetAircraft(true, TypeName, GroupName, CountryID, Vec3, Nunits, Radius)

  return template
end

--- Get template for fixed wing units.
-- @param #string TypeName Type name of the unit(s) in the groups. See `TEMPLATE.Ground`.
-- @param #string GroupName Name of the spawned group. **Must be unique!**
-- @param #number CountryID Country ID. Default `country.id.USA`. Coalition is automatically determined by the one the country belongs to.
-- @param DCS#Vec3 Vec3 Position of the group and the first unit.
-- @param #number Nunits Number of units. Default 1.
-- @param #number Radius Spawn radius for additonal units in meters. Default 500 m.
-- @return #table Template Template table.
function TEMPLATE.GetHelicopter(TypeName, GroupName, CountryID, Vec3, Nunits, Radius)

  -- Defaults.
  TypeName=TypeName or TEMPLATE.TypeHelicopter.AH1W
  GroupName=GroupName or "Helicopter-1"
  CountryID=CountryID or country.id.USA
  Vec3=Vec3 or {x=0, y=500, z=0}
  Nunits=Nunits or 1
  Radius=Radius or 100

  -- Limit unis to 4.
  Nunits=math.min(Nunits, 4)

  local template=TEMPLATE._GetAircraft(false, TypeName, GroupName, CountryID, Vec3, Nunits, Radius)

  return template
end


--- Get template for aircraft units.
-- @param #boolean Airplane If true, this is a fixed wing. Else, rotary wing.
-- @param #string TypeName Type name of the unit(s) in the groups. See `TEMPLATE.Ground`.
-- @param #string GroupName Name of the spawned group. **Must be unique!**
-- @param #number CountryID Country ID. Default `country.id.USA`. Coalition is automatically determined by the one the country belongs to.
-- @param DCS#Vec3 Vec3 Position of the group and the first unit.
-- @param #number Nunits Number of units. Default 1.
-- @param #number Radius Spawn radius for additonal units in meters. Default 500 m.
-- @return #table Template Template table.
function TEMPLATE._GetAircraft(Airplane, TypeName, GroupName, CountryID, Vec3, Nunits, Radius)

  -- Defaults.
  TypeName=TypeName
  GroupName=GroupName or "Aircraft-1"
  CountryID=CountryID or country.id.USA
  Vec3=Vec3 or {x=0, y=0, z=0}
  Nunits=Nunits or 1
  Radius=Radius or 100

  -- Get generic template.
  local template=UTILS.DeepCopy(TEMPLATE.GenericAircraft)

  -- Set group name.
  template.name=GroupName
  
  -- These are additional entries required by the MOOSE _DATABASE:Spawn() function.
  template.CountryID=CountryID
  template.CoalitionID=coalition.getCountryCoalition(template.CountryID)
  if Airplane then
    template.CategoryID=Unit.Category.AIRPLANE
  else
    template.CategoryID=Unit.Category.HELICOPTER
  end
  
  -- Set first unit.
  template.units[1].type=TypeName
  template.units[1].name=GroupName.."-1"  
  
  -- Set position.
  if Vec3 then
    TEMPLATE.SetPositionFromVec3(template, Vec3)
  end
  
  -- Set number of units.
  TEMPLATE.SetUnits(template, Nunits, COORDINATE:NewFromVec3(Vec3), Radius)

  return template
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the position of the template.
-- @param #table Template The template to be modified.
-- @param DCS#Vec2 Vec2 2D Position vector with x and y components of the group.
function TEMPLATE.SetPositionFromVec2(Template, Vec2)

  Template.x=Vec2.x
  Template.y=Vec2.y
  
  for _,unit in pairs(Template.units) do
    unit.x=Vec2.x
    unit.y=Vec2.y
  end
  
  Template.route.points[1].x=Vec2.x
  Template.route.points[1].y=Vec2.y
  Template.route.points[1].alt=0 --TODO: Use land height.
 
end

--- Set the position of the template.
-- @param #table Template The template to be modified.
-- @param DCS#Vec3 Vec3 Position vector of the group.
function TEMPLATE.SetPositionFromVec3(Template, Vec3)

  local Vec2={x=Vec3.x, y=Vec3.z}
  
  TEMPLATE.SetPositionFromVec2(Template, Vec2)
  
end

--- Set the position of the template.
-- @param #table Template The template to be modified.
-- @param #number N Total number of units in the group. 
-- @param Core.Point#COORDINATE Coordinate Position of the first unit.
-- @param #number Radius Radius in meters to randomly place the additional units.
function TEMPLATE.SetUnits(Template, N, Coordinate, Radius)

  local units=Template.units
  
  local unit1=units[1]
  
  local Vec3=Coordinate:GetVec3()
  
  unit1.x=Vec3.x
  unit1.y=Vec3.z
  unit1.alt=Vec3.y
  
  for i=2,N do  
    units[i]=UTILS.DeepCopy(unit1)
  end
  
  for i=1,N do
    local unit=units[i]
    unit.name=string.format("%s-%d", Template.name, i)
    if i>1 then
      local vec2=Coordinate:GetRandomCoordinateInRadius(Radius, 5):GetVec2()
      unit.x=vec2.x
      unit.y=vec2.y
      unit.alt=unit1.alt
    end
  end

end

--- Set the position of the template.
-- @param #table Template The template to be modified.
-- @param Wrapper.Airbase#AIRBASE AirBase The airbase where the aircraft are spawned.
-- @param #table ParkingSpots List of parking spot IDs. Every unit needs one!
-- @param #boolean EngineOn If true, aircraft are spawned hot.
function TEMPLATE.SetAirbase(Template, AirBase, ParkingSpots, EngineOn)

  -- Airbase ID.
  local AirbaseID=AirBase:GetID()

  -- Spawn point.
  local point=Template.route.points[1]
    
  -- Set ID.
  if AirBase:IsAirdrome() then
    point.airdromeId=AirbaseID
  else
    point.helipadId=AirbaseID
    point.linkUnit=AirbaseID
  end
  
  if EngineOn then
    point.action=COORDINATE.WaypointAction.FromParkingAreaHot
    point.type=COORDINATE.WaypointType.TakeOffParkingHot
  else
    point.action=COORDINATE.WaypointAction.FromParkingArea
    point.type=COORDINATE.WaypointType.TakeOffParking
  end
  
  for i,unit in ipairs(Template.units) do
    unit.parking_id=ParkingSpots[i]
  end
  
end

--- Add a waypoint.
-- @param #table Template The template to be modified.
-- @param #table Waypoint Waypoint table.
function TEMPLATE.AddWaypoint(Template, Waypoint)

  table.insert(Template.route.points, Waypoint)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Generic Ground Template
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

TEMPLATE.GenericGround=
{
  ["visible"] = false,
  ["tasks"] = {}, -- end of ["tasks"]
  ["uncontrollable"] = false,
  ["task"] = "Ground Nothing",
  ["route"] = 
  {
      ["spans"] = {}, -- end of ["spans"]
      ["points"] = 
      {
          [1] = 
          {
              ["alt"] = 0,
              ["type"] = "Turning Point",
              ["ETA"] = 0,
              ["alt_type"] = "BARO",
              ["formation_template"] = "",
              ["y"] = 0,
              ["x"] = 0,
              ["ETA_locked"] = true,
              ["speed"] = 0,
              ["action"] = "Off Road",
              ["task"] = 
              {
                  ["id"] = "ComboTask",
                  ["params"] = 
                  {
                      ["tasks"] = 
                      {
                      }, -- end of ["tasks"]
                  }, -- end of ["params"]
              }, -- end of ["task"]
              ["speed_locked"] = true,
          }, -- end of [1]
      }, -- end of ["points"]
  }, -- end of ["route"]
  ["groupId"] = nil,
  ["hidden"] = false,
  ["units"] = 
  {
      [1] = 
      {
          ["transportable"] = 
          {
              ["randomTransportable"] = false,
          }, -- end of ["transportable"]
          ["skill"] = "Average",
          ["type"] = "Infantry AK",
          ["unitId"] = nil,
          ["y"] = 0,
          ["x"] = 0,
          ["name"] = "Infantry AK-47 Rus",
          ["heading"] = 0,
          ["playerCanDrive"] = false,
      }, -- end of [1]
  }, -- end of ["units"]
  ["y"] = 0,
  ["x"] = 0,
  ["name"] = "Infantry AK-47 Rus",
  ["start_time"] = 0,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Generic Ship Template
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

TEMPLATE.GenericNaval=
{
  ["visible"] = false,
  ["tasks"] = {}, -- end of ["tasks"]
  ["uncontrollable"] = false,
  ["route"] = 
  {
      ["points"] = 
      {
          [1] = 
          {
              ["alt"] = 0,
              ["type"] = "Turning Point",
              ["ETA"] = 0,
              ["alt_type"] = "BARO",
              ["formation_template"] = "",
              ["y"] = 0,
              ["x"] = 0,
              ["ETA_locked"] = true,
              ["speed"] = 0,
              ["action"] = "Turning Point",
              ["task"] = 
              {
                  ["id"] = "ComboTask",
                  ["params"] = 
                  {
                      ["tasks"] = 
                      {
                      }, -- end of ["tasks"]
                  }, -- end of ["params"]
              }, -- end of ["task"]
              ["speed_locked"] = true,
          }, -- end of [1]
      }, -- end of ["points"]
  }, -- end of ["route"]
  ["groupId"] = nil,
  ["hidden"] = false,
  ["units"] = 
  {
      [1] = 
      {
          ["transportable"] = 
          {
              ["randomTransportable"] = false,
          }, -- end of ["transportable"]
          ["skill"] = "Average",
          ["type"] = "TICONDEROG",
          ["unitId"] = nil,
          ["y"] = 0,
          ["x"] = 0,
          ["name"] = "Naval-1-1",
          ["heading"] = 0,
          ["modulation"] = 0,
          ["frequency"] = 127500000,
      }, -- end of [1]
  }, -- end of ["units"]
  ["y"] = 0,
  ["x"] = 0,
  ["name"] = "Naval-1",
  ["start_time"] = 0,
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Generic Aircraft Template
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

TEMPLATE.GenericAircraft=
{
  ["groupId"] = nil,
  ["name"] = "Rotary-1",
  ["uncontrolled"] = false,
  ["hidden"] = false,
  ["task"] = "Nothing",
  ["y"] = 0,
  ["x"] = 0,
  ["start_time"] = 0,
  ["communication"] = true,   
  ["radioSet"] = false,
  ["frequency"] = 127.5,
  ["modulation"] = 0,  
  ["taskSelected"] = true,  
  ["tasks"] = {}, -- end of ["tasks"]
  ["route"] = 
  {
      ["points"] = 
      {
          [1] = 
          {
              ["y"] = 0,
              ["x"] = 0,
              ["alt"] = 1000,
              ["alt_type"] = "BARO",              
              ["action"] = "Turning Point",
              ["type"] = "Turning Point",              
              ["airdromeId"] = nil,
              ["task"] = 
              {
                  ["id"] = "ComboTask",
                  ["params"] = 
                  {
                      ["tasks"] = {}, -- end of ["tasks"]
                  }, -- end of ["params"]
              }, -- end of ["task"]
              ["ETA"] = 0,
              ["ETA_locked"] = true,
              ["speed"] = 100,
              ["speed_locked"] = true,              
              ["formation_template"] = "",
          }, -- end of [1]
      }, -- end of ["points"]
  }, -- end of ["route"]
  ["units"] = 
  {
      [1] = 
      {
          ["name"] = "Rotary-1-1",
          ["unitId"] = nil,    
          ["type"] = "AH-1W",
          ["onboard_num"] = "050",
          ["livery_id"] = "USA X Black",
          ["skill"] = "High",
          ["ropeLength"] = 15,
          ["speed"] = 0,
          ["x"] = 0,
          ["y"] = 0,
          ["alt"] = 10,
          ["alt_type"] = "BARO",          
          ["heading"] = 0,
          ["psi"] = 0,
          ["parking"] = nil,
          ["parking_id"] = nil,
          ["payload"] = 
          {
              ["pylons"] = {}, -- end of ["pylons"]
              ["fuel"] = "1250.0",
              ["flare"] = 30,
              ["chaff"] = 30,
              ["gun"] = 100,
          }, -- end of ["payload"]
          ["callsign"] = 
          {
              [1] = 2,
              [2] = 1,
              [3] = 1,
              ["name"] = "Springfield11",
          }, -- end of ["callsign"]
      }, -- end of [1]
  }, -- end of ["units"]
}
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

