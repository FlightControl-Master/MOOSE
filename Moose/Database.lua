--- Administers the Initial Sets of the Mission Templates as defined within the Mission Editor.
-- Administers the Spawning of new Groups within the DCSRTE and administers these new Groups within the DATABASE object(s).
-- @module Database
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Menu" )
Include.File( "Group" )
Include.File( "Event" )

--- The DATABASE class
-- @type DATABASE
-- @extends Base#BASE
DATABASE = {
  ClassName = "DATABASE",
  Units = {},
  Groups = {},
  NavPoints = {},
  Statics = {},
  Players = {},
  ActivePlayers = {},
  ClientsByName = {},
  ClientsByID = {},
}

local _DATABASECoalition =
  {
    [1] = "Red",
    [2] = "Blue",
  }

local _DATABASECategory =
  {
    [Unit.Category.AIRPLANE] = "Plane",
    [Unit.Category.HELICOPTER] = "Helicopter",
    [Unit.Category.GROUND_UNIT] = "Vehicle",
    [Unit.Category.SHIP] = "Ship",
    [Unit.Category.STRUCTURE] = "Structure",
  }


--- Creates a new DATABASE Object to administer the Groups defined and alive within the DCSRTE.
-- @return DATABASE
-- @usage
-- -- Define a new DATABASE Object. This DBObject will contain a reference to all Group and Unit Templates defined within the ME and the DCSRTE.
-- DBObject = DATABASE:New()
function DATABASE:New()

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )

  self.Navpoints = {}
  self.Units = {}
  --Build routines.db.units and self.Navpoints
  for coa_name, coa_data in pairs(env.mission.coalition) do

    if (coa_name == 'red' or coa_name == 'blue') and type(coa_data) == 'table' then
      self.Units[coa_name] = {}

      ----------------------------------------------
      -- build nav points DB
      self.Navpoints[coa_name] = {}
      if coa_data.nav_points then --navpoints
        for nav_ind, nav_data in pairs(coa_data.nav_points) do

          if type(nav_data) == 'table' then
            self.Navpoints[coa_name][nav_ind] = routines.utils.deepCopy(nav_data)

            self.Navpoints[coa_name][nav_ind]['name'] = nav_data.callsignStr  -- name is a little bit more self-explanatory.
            self.Navpoints[coa_name][nav_ind]['point'] = {}  -- point is used by SSE, support it.
            self.Navpoints[coa_name][nav_ind]['point']['x'] = nav_data.x
            self.Navpoints[coa_name][nav_ind]['point']['y'] = 0
            self.Navpoints[coa_name][nav_ind]['point']['z'] = nav_data.y
          end
      end
      end
      -------------------------------------------------
      if coa_data.country then --there is a country table
        for cntry_id, cntry_data in pairs(coa_data.country) do

          local countryName = string.lower(cntry_data.name)
          self.Units[coa_name][countryName] = {}
          self.Units[coa_name][countryName]["countryId"] = cntry_data.id

          if type(cntry_data) == 'table' then  --just making sure

            for obj_type_name, obj_type_data in pairs(cntry_data) do

              if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then --should be an unncessary check

                local category = obj_type_name

                if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then  --there's a group!

                  self.Units[coa_name][countryName][category] = {}

                  for group_num, GroupTemplate in pairs(obj_type_data.group) do

                    if GroupTemplate and GroupTemplate.units and type(GroupTemplate.units) == 'table' then  --making sure again- this is a valid group
                      self:_RegisterGroup( GroupTemplate )
                    end --if GroupTemplate and GroupTemplate.units then
                  end --for group_num, GroupTemplate in pairs(obj_type_data.group) do
                end --if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then
              end --if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then
          end --for obj_type_name, obj_type_data in pairs(cntry_data) do
          end --if type(cntry_data) == 'table' then
      end --for cntry_id, cntry_data in pairs(coa_data.country) do
      end --if coa_data.country then --there is a country table
    end --if coa_name == 'red' or coa_name == 'blue' and type(coa_data) == 'table' then
  end --for coa_name, coa_data in pairs(mission.coalition) do

  return self
end


--- Instantiate new Groups within the DCSRTE.
-- This method expects EXACTLY the same structure as a structure within the ME, and needs 2 additional fields defined:
-- SpawnCountryID, SpawnCategoryID
-- This method is used by the SPAWN class.
function DATABASE:Spawn( SpawnTemplate )

  self:T( { SpawnTemplate.SpawnCountryID, SpawnTemplate.SpawnCategoryID, SpawnTemplate.name } )

  -- Copy the spawn variables of the template in temporary storage, nullify, and restore the spawn variables.
  local SpawnCoalitionID = SpawnTemplate.SpawnCoalitionID
  local SpawnCountryID = SpawnTemplate.SpawnCountryID
  local SpawnCategoryID = SpawnTemplate.SpawnCategoryID

  -- Nullify
  SpawnTemplate.SpawnCoalitionID = nil
  SpawnTemplate.SpawnCountryID = nil
  SpawnTemplate.SpawnCategoryID = nil

  self:_RegisterGroup( SpawnTemplate )
  coalition.addGroup( SpawnCountryID, SpawnCategoryID, SpawnTemplate )

  -- Restore
  SpawnTemplate.SpawnCoalitionID = SpawnCoalitionID
  SpawnTemplate.SpawnCountryID = SpawnCountryID
  SpawnTemplate.SpawnCategoryID = SpawnCategoryID


  local SpawnGroup = GROUP:New( Group.getByName( SpawnTemplate.name ) )
  return SpawnGroup
end


--- Set a status to a Group within the Database, this to check crossing events for example.
function DATABASE:SetStatusGroup( GroupName, Status )
  self:F( Status )

  self.Groups[GroupName].Status = Status
end


--- Get a status to a Group within the Database, this to check crossing events for example.
function DATABASE:GetStatusGroup( GroupName )
  self:F( Status )

  if self.Groups[GroupName] then
    return self.Groups[GroupName].Status
  else
    return ""
  end
end

--- Registers new Group Templates within the DATABASE Object.
function DATABASE:_RegisterGroup( GroupTemplate )

  local GroupTemplateName = env.getValueDictByKey(GroupTemplate.name)

  if not self.Groups[GroupTemplateName] then
    self.Groups[GroupTemplateName] = {}
    self.Groups[GroupTemplateName].Status = nil
  end
  self.Groups[GroupTemplateName].GroupName = GroupTemplateName
  self.Groups[GroupTemplateName].Template = GroupTemplate
  self.Groups[GroupTemplateName].groupId = GroupTemplate.groupId
  self.Groups[GroupTemplateName].UnitCount = #GroupTemplate.units
  self.Groups[GroupTemplateName].Units = GroupTemplate.units

  self:T( { "Group", self.Groups[GroupTemplateName].GroupName, self.Groups[GroupTemplateName].UnitCount } )

  for unit_num, UnitTemplate in pairs(GroupTemplate.units) do

    local UnitTemplateName = env.getValueDictByKey(UnitTemplate.name)
    self.Units[UnitTemplateName] = {}
    self.Units[UnitTemplateName].UnitName = UnitTemplateName
    self.Units[UnitTemplateName].Template = UnitTemplate
    self.Units[UnitTemplateName].GroupName = GroupTemplateName
    self.Units[UnitTemplateName].GroupTemplate = GroupTemplate
    self.Units[UnitTemplateName].GroupId = GroupTemplate.groupId
    if UnitTemplate.skill and (UnitTemplate.skill == "Client" or UnitTemplate.skill == "Player") then
      self.ClientsByName[UnitTemplateName] = UnitTemplate
      self.ClientsByID[UnitTemplate.unitId] = UnitTemplate
    end
    self:T( { "Unit", self.Units[UnitTemplateName].UnitName } )
  end
end

_Database = DATABASE:New() -- Database#DATABASE


