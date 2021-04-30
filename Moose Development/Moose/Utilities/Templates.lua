--- **Utils** Templates
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

--- Pattern steps.
-- @type TEMPLATE.Ground
-- @param #string InfantryAK
TEMPLATE.Ground={
  InfantryAK="Infantry AK",
  ParatrooperAKS74="Paratrooper AKS-74",
  ParatrooperRPG16="Paratrooper RPG-16",
  SoldierWWIIUS="soldier_wwii_us",
  InfantryM248="Infantry M249",
  SoldierM4="Soldier M4",
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start/Stop Profiler
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get template for ground units.
-- @param #string TypeName Type name of the unit(s) in the groups. See `TEMPLATE.Ground`.
-- @param #string GroupName Name of the spawned group. **Must be unique!**
-- @param #number CountryID Country ID. Default `country.id.USA`. Coalition is automatically determined by the one the country belongs to.
-- @param DCS#Vec3 Vec3 Position of the group.
-- @param #number Nunits Number of units. Default 1.
-- @param #number Radius Spawn radius for additonal units in meters. Default 50 m.
-- @return #table Template Template table.
function TEMPLATE.GetGround(TypeName, GroupName, CountryID, Vec3, Nunits, Radius)

  local template=UTILS.DeepCopy(TEMPLATE.GenericGround)
  
  template.name=GroupName or "Ground-1"
  
  -- These are additional entries required by the MOOSE _DATABASE:Spawn() function.
  template.CountryID=country.id.USA
  template.CoalitionID=coalition.getCountryCoalition(template.CountryID)
  template.CategoryID=Unit.Category.GROUND_UNIT
  
  template.units[1].type=TypeName or "Infantry AK"
  template.units[1].name=GroupName.."-1"
  
  if Vec3 then
    TEMPLATE.SetPositionFromVec3(template, Vec3)
  end

  return template
end

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