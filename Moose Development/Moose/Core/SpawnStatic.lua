--- **Functional** -- Spawn dynamically new @{Static}s in your missions.
--  
-- ![Banner Image](..\Presentations\SPAWNSTATIC\SPAWNSTATIC.JPG)
-- 
-- ====
-- 
-- # Demo Missions
-- 
-- ### [SPAWNSTATIC Demo Missions source code]()
-- 
-- ### [SPAWNSTATIC Demo Missions, only for beta testers]()
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [SPAWNSTATIC YouTube Channel]()
-- 
-- ====
-- 
-- # **API CHANGE HISTORY**
-- 
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
-- 
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
-- 
-- Hereby the change log:
-- 
-- ===
-- 
-- # **AUTHORS and CONTRIBUTIONS**
-- 
-- ### Contributions: 
-- 
-- ### Authors: 
-- 
--   * **FlightControl**: Design & Programming
-- 
-- @module SpawnStatic



--- SPAWNSTATIC Class
-- @type SPAWNSTATIC
-- @extends Core.Base#BASE


--- # SPAWNSTATIC class, extends @{Base#BASE}
-- 
-- The SPAWNSTATIC class allows to spawn dynamically new @{Static}s.
-- 
-- There are two modes how SPAWNSTATIC can spawn:
-- 
--   * Through creating a copy of an existing Template @{Static} as defined in the Mission Editor (ME).
--   * Through the provision of the type name of the Static.  
-- 
-- Spawned @{Static}s get **the same name** as the name of the Template Static, 
-- or gets the given name when a Static Type is used.  
-- Newly spawned @{Static}s will get the following naming structure at run-time:
-- 
--   * Spawned @{Static}s will have the name _StaticName_#_nnn_, where _StaticName_ is the name of the **Template Static**, 
--   and _nnn_ is a **counter from 0 to 99999**.
-- 
--   
-- ## SPAWNSTATIC construction methods
-- 
-- Create a new SPAWNSTATIC object with the @{#SPAWNSTATIC.NewFromStatic}() or the @{#SPAWNSTATIC.NewFromType}() methods:
-- 
--   * @{#SPAWNSTATIC.NewFromStatic}(): Creates a new SPAWNSTATIC object given a name that is used as the base of the naming of each spawned Static.
--   * @{#SPAWNSTATIC.NewFromType}(): Creates a new SPAWNSTATIC object given a type name and a name to be given when spawned.
--
-- ## SPAWNSTATIC **Init**ialization methods
-- 
-- A spawn object will behave differently based on the usage of **initialization** methods, which all start with the **Init** prefix:  
-- 
--   * @{#SPAWNSTATIC.InitRandomizePosition}(): Randomizes the position of @{Static}s that are spawned within a **radius band**, given an Outer and Inner radius, from the point that the spawn happens.
--   * @{#SPAWNSTATIC.InitRandomizeZones}(): Randomizes the spawning between a predefined list of @{Zone}s that are declared using this function. Each zone can be given a probability factor.
-- 
-- ## SPAWNSTATIC **Spawn** methods
-- 
-- Groups can be spawned at different times and methods:
-- 
--   * @{#SPAWNSTATIC.SpawnInZone}(): Spawn a new group in a @{Zone}.
--   * @{#SPAWNSTATIC.SpawnFromVec3}(): Spawn a new group from a Vec3 coordinate. (The group will can be spawned at a point in the air).
--   * @{#SPAWNSTATIC.SpawnFromVec2}(): Spawn a new group from a Vec2 coordinate. (The group will be spawned at land height ).
--   * @{#SPAWNSTATIC.SpawnFromStatic}(): Spawn a new group from a structure, taking the position of a @{Static}.
--   * @{#SPAWNSTATIC.SpawnFromUnit}(): Spawn a new group taking the position of a @{Unit}.
--  
-- @field #SPAWNSTATIC SPAWNSTATIC
-- 
SPAWNSTATIC = {
  ClassName = "SPAWNSTATIC",
}


--- @type SPAWNSTATIC.SpawnZoneTable
-- @list <Core.Zone#ZONE_BASE> SpawnZone


--- Creates the main object to spawn a @{Static} defined in the ME.
-- @param #SPAWNSTATIC self
-- @param #string SpawnTemplatePrefix is the name of the Group in the ME that defines the Template.  Each new group will have the name starting with SpawnTemplatePrefix.
-- @return #SPAWNSTATIC
function SPAWNSTATIC:NewFromStatic( SpawnTemplatePrefix, CountryID )
	local self = BASE:Inherit( self, BASE:New() ) -- #SPAWNSTATIC
	self:F( { SpawnTemplatePrefix } )
  
	local TemplateStatic = StaticObject.getByName( SpawnTemplatePrefix )
	if TemplateStatic then
		self.SpawnTemplatePrefix = SpawnTemplatePrefix
    self.CountryID = CountryID
		self.SpawnIndex = 0
	else
		error( "SPAWNSTATIC:New: There is no group declared in the mission editor with SpawnTemplatePrefix = '" .. SpawnTemplatePrefix .. "'" )
	end

  self:SetEventPriority( 5 )

	return self
end

--- Creates the main object to spawn a @{Static} based on a type name.
-- @param #SPAWNSTATIC self
-- @param #string SpawnTypeName is the name of the type.
-- @return #SPAWNSTATIC
function SPAWNSTATIC:NewFromType( SpawnTypeName, SpawnShapeName, SpawnCategory, CountryID )
  local self = BASE:Inherit( self, BASE:New() ) -- #SPAWNSTATIC
  self:F( { SpawnTypeName } )
  
  self.SpawnTypeName = SpawnTypeName
  self.CountryID = CountryID
  self.SpawnIndex = 0

  self:SetEventPriority( 5 )

  return self
end


--- Creates a new @{Static} from a POINT_VEC2.
-- @param #SPAWNSTATIC self
-- @param #string SpawnTypeName is the name of the type.
-- @return #SPAWNSTATIC
function SPAWNSTATIC:SpawnFromPointVec2( PointVec2, BaseName )
  self:F( { PointVec2, BaseName  } )
  
  local CountryName = _DATABASE.COUNTRY_NAME[self.CountryID]
  
  local StaticTemplate
  
  local Tire = {
      ["country"] = CountryName, 
      ["category"] = "Fortifications",
      ["canCargo"] = false,
      ["shape_name"] = "H-tyre_B_WF",
      ["type"] = "Black_Tyre_WF",
      --["unitId"] = Angle + 10000,
      ["y"] = Point.y,
      ["x"] = Point.x,
      ["name"] = string.format( "%s-Tire #%0d", self:GetName(), Angle ),
      ["heading"] = 0,
  } -- end of ["group"]

  local Group = coalition.addStaticObject( CountryID, Tire )

  return self
end


